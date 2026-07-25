defmodule HelheimWeb.MusicControllerTest do
  use HelheimWeb.ConnCase

  ##############################################################################
  # index/2
  describe "index/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it shows the site wide totals", %{conn: conn} do
      insert(:song, artist_name: "Metallica", listens_count: 3, upvotes_count: 2)

      conn = get conn, "/music"
      response = html_response(conn, 200)
      assert response =~ gettext("Helheim in numbers")
      assert response =~ gettext("Listeners")
    end

    test "it shows the top genres with a link to each genre", %{conn: conn} do
      tag = insert(:tag, name: "thrash metal")
      insert(:song_tag, song: insert(:song, listens_count: 4), tag: tag)

      conn = get conn, "/music"
      response = html_response(conn, 200)
      assert response =~ gettext("Genres")
      assert response =~ "Thrash Metal"
      assert response =~ "/music/genres/#{tag.id}"
    end

    test "it shows the decades with a link to each decade, in chronological order", %{conn: conn} do
      insert(:song, release_year: 1994, listens_count: 1)
      insert(:song, release_year: 1986, listens_count: 2)

      conn = get conn, "/music"
      response = html_response(conn, 200)
      assert response =~ gettext("Decades")
      assert response =~ "/music/decades/1980"
      assert response =~ "/music/decades/1990"

      [_before, after_eighties] = String.split(response, "/music/decades/1980", parts: 2)
      assert after_eighties =~ "/music/decades/1990"
    end

    test "it does not show songs without a release year among the decades", %{conn: conn} do
      insert(:song, release_year: nil, listens_count: 3)

      conn = get conn, "/music"
      assert html_response(conn, 200) =~ gettext("No songs with a known release year yet...")
    end

    test "it shows the top artists with their enriched details and a link to each artist", %{conn: conn} do
      insert(:song, artist_name: "Bathory", listens_count: 5)
      artist = insert(:artist, name: "Bathory", country_code: "SE", country_name: "Sweden")

      conn = get conn, "/music"
      response = html_response(conn, 200)
      assert response =~ gettext("Top artists")
      assert response =~ "Bathory"
      assert response =~ artist.image_url_medium
      assert response =~ "Sweden"
      assert response =~ "/music/artists/Bathory"
    end

    test "it shows the song charts that used to live on the front page", %{conn: conn} do
      insert(:song_listen, song: insert(:song, title: "Orion"))
      insert(:song_upvote, song: insert(:song, title: "Blackened"))

      conn = get conn, "/music"
      response = html_response(conn, 200)
      assert response =~ gettext("Top songs, past 24 hours")
      assert response =~ gettext("Top songs, past 7 days")
      assert response =~ gettext("Most upvoted songs, past 24 hours")
      assert response =~ gettext("Most upvoted songs, past 7 days")
      assert response =~ "Orion"
      assert response =~ "Blackened"
    end

    test "it does not show chart entries from ignored users", %{conn: conn, user: user} do
      ignoree = insert(:user)
      insert(:ignore, ignorer: user, ignoree: ignoree, enabled: true)
      insert(:song_listen, user: ignoree, song: insert(:song, title: "Orion"))

      conn = get conn, "/music"
      refute html_response(conn, 200) =~ "Orion"
    end
  end

  describe "index/2 when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      conn = get conn, "/music"
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end

  ##############################################################################
  # genre/2
  describe "genre/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it shows the songs whose primary tag is the genre, most listened first", %{conn: conn} do
      tag = insert(:tag, name: "thrash metal")
      insert(:song_tag, song: insert(:song, title: "Creeping Death", listens_count: 1), tag: tag)
      insert(:song_tag, song: insert(:song, title: "Battery", listens_count: 9), tag: tag)

      conn = get conn, "/music/genres/#{tag.id}"
      response = html_response(conn, 200)
      assert response =~ "Thrash Metal"
      assert response =~ "Creeping Death"

      [_before, after_battery] = String.split(response, "Battery", parts: 2)
      assert after_battery =~ "Creeping Death"
    end

    test "it does not show songs where the genre is only a secondary tag", %{conn: conn} do
      tag = insert(:tag, name: "live")
      insert(:song_tag, song: insert(:song, title: "Whiplash"), tag: tag, position: 2)

      conn = get conn, "/music/genres/#{tag.id}"
      refute html_response(conn, 200) =~ "Whiplash"
    end

    test "it shows a placeholder when the genre has no songs", %{conn: conn} do
      tag = insert(:tag)

      conn = get conn, "/music/genres/#{tag.id}"
      assert html_response(conn, 200) =~ gettext("No songs here yet...")
    end

    test "it caps the page number", %{conn: conn} do
      tag = insert(:tag)

      conn = get conn, "/music/genres/#{tag.id}?page=999"
      assert html_response(conn, 200)
    end

    test "it returns a 404 when the genre does not exist", %{conn: conn} do
      assert_error_sent :not_found, fn ->
        get conn, "/music/genres/1234567"
      end
    end
  end

  describe "genre/2 when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      conn = get conn, "/music/genres/#{insert(:tag).id}"
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end

  ##############################################################################
  # decade/2
  describe "decade/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it shows the songs released in the decade and no others", %{conn: conn} do
      insert(:song, title: "Master of Puppets", release_year: 1986)
      insert(:song, title: "Physical Graffiti", release_year: 1975)

      conn = get conn, "/music/decades/1980"
      response = html_response(conn, 200)
      assert response =~ "Master of Puppets"
      refute response =~ "Physical Graffiti"
    end

    test "it redirects a year inside the decade to the canonical decade url", %{conn: conn} do
      conn = get conn, "/music/decades/1986"
      assert redirected_to(conn) == "/music/decades/1980"
    end

    test "it caps the page number", %{conn: conn} do
      conn = get conn, "/music/decades/1980?page=999"
      assert html_response(conn, 200)
    end

    test "it returns a 404 when the decade is not a year", %{conn: conn} do
      conn = get conn, "/music/decades/eighties"
      assert html_response(conn, 404) =~ gettext("The page you requested does not exist.")
    end
  end

  describe "decade/2 when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      conn = get conn, "/music/decades/1980"
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end

  ##############################################################################
  # artist/2
  describe "artist/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it shows the artist's songs, matching the name case-insensitively", %{conn: conn} do
      insert(:song, title: "Creeping Death", artist_name: "Metallica")

      conn = get conn, "/music/artists/metallica"
      response = html_response(conn, 200)
      assert response =~ "Metallica"
      assert response =~ "Creeping Death"
    end

    test "it shows the enriched artist details when there is an artist record", %{conn: conn} do
      insert(:song, artist_name: "Bathory", listens_count: 7)
      artist = insert(:artist, name: "Bathory", country_code: "SE", country_name: "Sweden")

      conn = get conn, "/music/artists/Bathory"
      response = html_response(conn, 200)
      assert response =~ artist.image_url_medium
      assert response =~ "Sweden"
      assert response =~ "7"
    end

    test "it renders without enriched details when there is no artist record", %{conn: conn} do
      insert(:song, title: "Creeping Death", artist_name: "Metallica")

      conn = get conn, "/music/artists/Metallica"
      response = html_response(conn, 200)
      assert response =~ "music-artist-image-placeholder"
      assert response =~ "Creeping Death"
    end

    test "it handles an artist name containing a slash", %{conn: conn} do
      insert(:song, title: "Back in Black", artist_name: "AC/DC")

      conn = get conn, "/music/artists/AC/DC"
      response = html_response(conn, 200)
      assert response =~ "AC/DC"
      assert response =~ "Back in Black"
    end

    test "it renders for an artist record whose songs are all gone", %{conn: conn} do
      insert(:artist, name: "Bathory")

      conn = get conn, "/music/artists/Bathory"
      assert html_response(conn, 200) =~ gettext("No songs here yet...")
    end

    test "it caps the page number", %{conn: conn} do
      insert(:song, artist_name: "Metallica")

      conn = get conn, "/music/artists/Metallica?page=999"
      assert html_response(conn, 200)
    end

    test "it returns a 404 for an artist the site has never heard of", %{conn: conn} do
      conn = get conn, "/music/artists/Nobody%20At%20All"
      assert html_response(conn, 404) =~ gettext("The page you requested does not exist.")
    end
  end

  describe "artist/2 when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      insert(:song, artist_name: "Metallica")
      conn = get conn, "/music/artists/Metallica"
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end
end
