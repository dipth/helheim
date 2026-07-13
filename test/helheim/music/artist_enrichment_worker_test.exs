defmodule Helheim.Music.ArtistEnrichmentWorkerTest do
  use Helheim.DataCase
  use Oban.Testing, repo: Helheim.Repo
  import Mock
  alias Helheim.Repo
  alias Helheim.Artist
  alias Helheim.Lastfm
  alias Helheim.Musicbrainz
  alias Helheim.Fanart
  alias Helheim.Deezer
  alias Helheim.Music.ArtistEnrichmentWorker

  @mb_artist {:ok, %{"country" => "DK", "area" => %{"name" => "Denmark", "iso-3166-1-codes" => ["DK"]}}}
  @fanart_images {:ok, %{
    thumb_url: "https://assets.fanart.tv/fanart/music/mbid/artistthumb/pic.jpg",
    preview_url: "https://assets.fanart.tv/preview/music/mbid/artistthumb/pic.jpg"
  }}
  @deezer_images {:ok, %{
    image_url_small: "https://e-cdns-images.dzcdn.net/56x56.jpg",
    image_url_medium: "https://e-cdns-images.dzcdn.net/250x250.jpg",
    image_url_large: "https://e-cdns-images.dzcdn.net/1000x1000.jpg"
  }}

  defp insert_unenriched_artist(attrs \\ []) do
    insert(:artist, Keyword.merge([
      name: "Iotunn", mbid: "artist-mbid", country_code: nil, country_name: nil,
      image_url_small: nil, image_url_medium: nil, image_url_large: nil,
      image_source: nil, enriched_at: nil
    ], attrs))
  end

  describe "perform/1 with a known mbid" do
    setup_with_mocks([
      {Musicbrainz.Client, [:passthrough], [artist: fn "artist-mbid" -> @mb_artist end]},
      {Fanart.Client, [:passthrough], [artist_images: fn "artist-mbid" -> @fanart_images end]}
    ]) do
      :ok
    end

    test "stores the country and fanart images and marks the artist enriched" do
      artist = insert_unenriched_artist()

      assert :ok = perform_job(ArtistEnrichmentWorker, %{artist_id: artist.id})

      artist = Repo.get(Artist, artist.id)
      assert artist.country_code == "DK"
      assert artist.country_name == "Denmark"
      assert artist.image_url_small =~ "/preview/"
      assert artist.image_url_large =~ "/fanart/"
      assert artist.image_source == "fanart"
      assert artist.enriched_at
    end

    test "falls back to deezer when fanart has no images" do
      artist = insert_unenriched_artist()

      with_mocks([
        {Fanart.Client, [:passthrough], [artist_images: fn _mbid -> {:error, :not_found} end]},
        {Deezer.Client, [:passthrough], [search_artist: fn "Iotunn" -> @deezer_images end]}
      ]) do
        assert :ok = perform_job(ArtistEnrichmentWorker, %{artist_id: artist.id})
      end

      artist = Repo.get(Artist, artist.id)
      assert artist.image_url_large =~ "1000x1000"
      assert artist.image_source == "deezer"
    end

    test "falls back to deezer when fanart is not configured" do
      artist = insert_unenriched_artist()

      with_mocks([
        {Fanart.Client, [:passthrough], [artist_images: fn _mbid -> {:error, :not_configured} end]},
        {Deezer.Client, [:passthrough], [search_artist: fn _name -> @deezer_images end]}
      ]) do
        assert :ok = perform_job(ArtistEnrichmentWorker, %{artist_id: artist.id})
      end

      assert Repo.get(Artist, artist.id).image_source == "deezer"
    end

    test "marks the artist enriched even when no image source has anything" do
      artist = insert_unenriched_artist()

      with_mocks([
        {Fanart.Client, [:passthrough], [artist_images: fn _mbid -> {:error, :not_found} end]},
        {Deezer.Client, [:passthrough], [search_artist: fn _name -> {:error, :not_found} end]}
      ]) do
        assert :ok = perform_job(ArtistEnrichmentWorker, %{artist_id: artist.id})
      end

      artist = Repo.get(Artist, artist.id)
      assert artist.image_url_small == nil
      assert artist.enriched_at
    end

    test "snoozes when an image source rate limits" do
      artist = insert_unenriched_artist()

      with_mock Fanart.Client, [:passthrough], [artist_images: fn _mbid -> {:error, :rate_limited} end] do
        assert {:snooze, 60} = perform_job(ArtistEnrichmentWorker, %{artist_id: artist.id})
      end

      refute Repo.get(Artist, artist.id).enriched_at
    end

    test "skips artists that are already enriched" do
      artist = insert_unenriched_artist(enriched_at: DateTime.utc_now())

      assert :ok = perform_job(ArtistEnrichmentWorker, %{artist_id: artist.id})
      assert not called Musicbrainz.Client.artist(:_)
    end
  end

  describe "perform/1 without a stored mbid" do
    setup do
      [artist: insert_unenriched_artist(mbid: nil)]
    end

    test "resolves the mbid via last.fm first", %{artist: artist} do
      with_mocks([
        {Lastfm.Client, [:passthrough], [artist_info: fn "Iotunn" -> {:ok, %{mbid: "artist-mbid", url: nil}} end]},
        {Musicbrainz.Client, [:passthrough], [artist: fn "artist-mbid" -> @mb_artist end]},
        {Fanart.Client, [:passthrough], [artist_images: fn "artist-mbid" -> @fanart_images end]}
      ]) do
        assert :ok = perform_job(ArtistEnrichmentWorker, %{artist_id: artist.id})
      end

      artist = Repo.get(Artist, artist.id)
      assert artist.mbid == "artist-mbid"
      assert artist.country_code == "DK"
    end

    test "falls back to a perfect-score exact musicbrainz search match", %{artist: artist} do
      with_mocks([
        {Lastfm.Client, [:passthrough], [artist_info: fn _name -> {:ok, %{mbid: nil, url: nil}} end]},
        {Musicbrainz.Client, [:passthrough], [
          search_artist: fn "Iotunn" -> {:ok, [%{"id" => "artist-mbid", "score" => 100, "name" => "IOTUNN"}]} end,
          artist: fn "artist-mbid" -> @mb_artist end
        ]},
        {Fanart.Client, [:passthrough], [artist_images: fn _mbid -> {:error, :not_found} end]},
        {Deezer.Client, [:passthrough], [search_artist: fn _name -> {:error, :not_found} end]}
      ]) do
        assert :ok = perform_job(ArtistEnrichmentWorker, %{artist_id: artist.id})
      end

      assert Repo.get(Artist, artist.id).mbid == "artist-mbid"
    end

    test "rejects search matches that are not exact", %{artist: artist} do
      with_mocks([
        {Lastfm.Client, [:passthrough], [artist_info: fn _name -> {:error, :not_found} end]},
        {Musicbrainz.Client, [:passthrough], [
          search_artist: fn _name -> {:ok, [%{"id" => "wrong-mbid", "score" => 90, "name" => "Iotunn Tribute Band"}]} end
        ]},
        {Deezer.Client, [:passthrough], [search_artist: fn _name -> {:error, :not_found} end]}
      ]) do
        assert :ok = perform_job(ArtistEnrichmentWorker, %{artist_id: artist.id})
      end

      artist = Repo.get(Artist, artist.id)
      assert artist.mbid == nil
      assert artist.country_code == nil
      assert artist.enriched_at
    end
  end
end
