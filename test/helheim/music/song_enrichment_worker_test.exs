defmodule Helheim.Music.SongEnrichmentWorkerTest do
  use Helheim.DataCase
  use Oban.Testing, repo: Helheim.Repo
  import Mock
  alias Helheim.Repo
  alias Helheim.Artist
  alias Helheim.Song
  alias Helheim.SongTag
  alias Helheim.Tag
  alias Helheim.Lastfm
  alias Helheim.Musicbrainz
  alias Helheim.Music.ArtistEnrichmentWorker
  alias Helheim.Music.SongEnrichmentWorker

  @track_info {:ok, %{
    mbid: "track-mbid",
    artist_mbid: "artist-mbid",
    album_mbid: "album-mbid",
    album_name: "Master of Puppets",
    duration_seconds: 315,
    image_extralarge: "https://lastfm.freetls.fastly.net/i/u/300x300/abc.jpg",
    tags: ["thrash metal", "metal", "80s"],
    url: "https://www.last.fm/music/Metallica/_/Battery"
  }}

  defp insert_unenriched_song(attrs \\ []) do
    insert(:song, Keyword.merge([
      title: "Battery",
      artist_name: "Metallica",
      cover_image_url: "https://lastfm.freetls.fastly.net/i/u/300x300/abc.jpg",
      mbid: nil, artist_mbid: nil, album_mbid: nil, release_year: nil,
      duration_seconds: nil, cover_image_url_large: nil, enriched_at: nil
    ], attrs))
  end

  describe "perform/1" do
    setup_with_mocks([
      {Lastfm.Client, [:passthrough], [track_info: fn _artist, _title -> @track_info end]},
      {Musicbrainz.Client, [:passthrough], [
        recording: fn _mbid -> {:ok, %{"first-release-date" => "1986-03-03"}} end,
        release: fn _mbid -> {:ok, %{"release-group" => %{"first-release-date" => "1986"}}} end,
        search_recording: fn _artist, _title -> {:ok, [%{"first-release-date" => "1986-03-03"}]} end
      ]}
    ]) do
      :ok
    end

    test "enriches the song with mbids, duration, release year, tags, cover and artist" do
      song = insert_unenriched_song()

      assert :ok = perform_job(SongEnrichmentWorker, %{song_id: song.id})

      song = Repo.get(Song, song.id) |> Repo.preload(:tags)
      assert song.mbid == "track-mbid"
      assert song.artist_mbid == "artist-mbid"
      assert song.album_mbid == "album-mbid"
      assert song.duration_seconds == 315
      assert song.release_year == 1986
      assert song.cover_image_url_large == "https://lastfm.freetls.fastly.net/i/u/500x500/abc.jpg"
      assert song.enriched_at
      assert Enum.map(song.tags, & &1.name) |> Enum.sort() == ["80s", "metal", "thrash metal"]

      artist = Repo.get_by!(Artist, name: "Metallica")
      assert song.artist_id == artist.id
      assert artist.mbid == "artist-mbid"
      assert_enqueued worker: ArtistEnrichmentWorker, args: %{artist_id: artist.id}
    end

    test "does not clobber values the song already has" do
      song = insert_unenriched_song(mbid: "existing-mbid", album_name: "Existing Album", duration_seconds: 100)

      assert :ok = perform_job(SongEnrichmentWorker, %{song_id: song.id})

      song = Repo.get(Song, song.id)
      assert song.mbid == "existing-mbid"
      assert song.album_name == "Existing Album"
      assert song.duration_seconds == 100
    end

    test "skips songs that are already enriched" do
      song = insert_unenriched_song(enriched_at: DateTime.utc_now())

      assert :ok = perform_job(SongEnrichmentWorker, %{song_id: song.id})
      assert not called Lastfm.Client.track_info(:_, :_)
    end

    test "re-enriches when forced" do
      song = insert_unenriched_song(enriched_at: DateTime.utc_now())

      assert :ok = perform_job(SongEnrichmentWorker, %{song_id: song.id, force: true})
      assert called Lastfm.Client.track_info("Metallica", "Battery")
    end

    test "skips songs that no longer exist" do
      assert :ok = perform_job(SongEnrichmentWorker, %{song_id: 1_234_567})
    end

    test "reuses existing tags case-insensitively and replaces assignments idempotently" do
      existing_tag = insert(:tag, name: "Thrash Metal")
      song = insert_unenriched_song()

      assert :ok = perform_job(SongEnrichmentWorker, %{song_id: song.id})
      assert :ok = perform_job(SongEnrichmentWorker, %{song_id: song.id, force: true})

      song_tags = Repo.all(from st in SongTag, where: st.song_id == ^song.id)
      assert length(song_tags) == 3
      assert Repo.aggregate(from(t in Tag, where: fragment("lower(?)", t.name) == "thrash metal"), :count) == 1
      assert Enum.any?(song_tags, & &1.tag_id == existing_tag.id)
    end

    test "still enriches when last.fm does not know the track" do
      song = insert_unenriched_song(cover_image_url: nil)

      with_mock Lastfm.Client, [:passthrough], [
        track_info: fn _a, _t -> {:error, :not_found} end,
        artist_info: fn _name -> {:error, :not_found} end
      ] do
        assert :ok = perform_job(SongEnrichmentWorker, %{song_id: song.id})
      end

      song = Repo.get(Song, song.id)
      assert song.enriched_at
      assert song.release_year == 1986
    end

    test "keeps existing tags when the fresh lookup has none" do
      song = insert_unenriched_song()
      tag = insert(:tag, name: "prog metal")
      Repo.insert!(%SongTag{song_id: song.id, tag_id: tag.id, position: 1})

      with_mock Lastfm.Client, [:passthrough], [
        track_info: fn _a, _t ->
          {:ok, info} = @track_info
          {:ok, %{info | tags: []}}
        end,
        artist_info: fn _name -> {:error, :not_found} end
      ] do
        assert :ok = perform_job(SongEnrichmentWorker, %{song_id: song.id, force: true})
      end

      song = Repo.get(Song, song.id) |> Repo.preload(:tags)
      assert Enum.map(song.tags, & &1.name) == ["prog metal"]
    end

    test "snoozes instead of losing tags when the artist tag fallback is rate limited" do
      song = insert_unenriched_song()
      tag = insert(:tag, name: "prog metal")
      Repo.insert!(%SongTag{song_id: song.id, tag_id: tag.id, position: 1})

      with_mock Lastfm.Client, [:passthrough], [
        track_info: fn _a, _t ->
          {:ok, info} = @track_info
          {:ok, %{info | tags: []}}
        end,
        artist_info: fn _name -> {:error, :rate_limited} end
      ] do
        assert {:snooze, 60} = perform_job(SongEnrichmentWorker, %{song_id: song.id, force: true})
      end

      assert Repo.aggregate(from(st in SongTag, where: st.song_id == ^song.id), :count) == 1
    end

    test "settles a song whose final attempt still errors so it stops clogging the queue" do
      song = insert_unenriched_song()

      with_mock Lastfm.Client, [:passthrough], [
        track_info: fn _a, _t -> {:error, {:api_error, 16, "temporary"}} end
      ] do
        assert {:error, _} = perform_job(SongEnrichmentWorker, %{song_id: song.id}, attempt: 1)
        assert :ok = perform_job(SongEnrichmentWorker, %{song_id: song.id}, attempt: 5)
      end

      assert Repo.get(Song, song.id).enriched_at
    end

    test "falls back to the artist's tags when the track has none" do
      song = insert_unenriched_song()

      with_mock Lastfm.Client, [:passthrough], [
        track_info: fn _a, _t ->
          {:ok, info} = @track_info
          {:ok, %{info | tags: []}}
        end,
        artist_info: fn "Metallica" -> {:ok, %{mbid: nil, url: nil, tags: ["heavy metal", "thrash metal"]}} end
      ] do
        assert :ok = perform_job(SongEnrichmentWorker, %{song_id: song.id})
      end

      song = Repo.get(Song, song.id) |> Repo.preload(:tags)
      assert Enum.map(song.tags, & &1.name) |> Enum.sort() == ["heavy metal", "thrash metal"]
    end
  end

  describe "release year cascade" do
    setup_with_mocks([
      {Lastfm.Client, [:passthrough], [track_info: fn _artist, _title -> @track_info end]}
    ]) do
      :ok
    end

    test "falls back from a stale recording mbid to the release lookup" do
      song = insert_unenriched_song()

      with_mock Musicbrainz.Client, [:passthrough], [
        recording: fn _mbid -> {:error, :not_found} end,
        release: fn "album-mbid" -> {:ok, %{"release-group" => %{"first-release-date" => "1999-11-23"}}} end
      ] do
        assert :ok = perform_job(SongEnrichmentWorker, %{song_id: song.id})
      end

      assert Repo.get(Song, song.id).release_year == 1999
    end

    test "falls back to the recording search when both mbid lookups miss, taking the earliest year" do
      song = insert_unenriched_song()

      with_mock Musicbrainz.Client, [:passthrough], [
        recording: fn _mbid -> {:error, :not_found} end,
        release: fn _mbid -> {:error, :not_found} end,
        search_recording: fn "Metallica", "Battery" ->
          {:ok, [
            %{"first-release-date" => "2001-10-01"},
            %{"first-release-date" => "1986-03-03"},
            %{"title" => "no date on this one"}
          ]}
        end
      ] do
        assert :ok = perform_job(SongEnrichmentWorker, %{song_id: song.id})
      end

      assert Repo.get(Song, song.id).release_year == 1986
    end

    test "leaves the release year empty when nothing matches but still marks the song enriched" do
      song = insert_unenriched_song()

      with_mock Musicbrainz.Client, [:passthrough], [
        recording: fn _mbid -> {:error, :not_found} end,
        release: fn _mbid -> {:error, :not_found} end,
        search_recording: fn _a, _t -> {:ok, []} end
      ] do
        assert :ok = perform_job(SongEnrichmentWorker, %{song_id: song.id})
      end

      song = Repo.get(Song, song.id)
      assert song.release_year == nil
      assert song.enriched_at
    end

    test "snoozes when musicbrainz rate limits" do
      song = insert_unenriched_song()

      with_mock Musicbrainz.Client, [:passthrough], [recording: fn _mbid -> {:error, :rate_limited} end] do
        assert {:snooze, 60} = perform_job(SongEnrichmentWorker, %{song_id: song.id})
      end

      refute Repo.get(Song, song.id).enriched_at
    end
  end
end
