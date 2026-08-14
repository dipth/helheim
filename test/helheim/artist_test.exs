defmodule Helheim.ArtistTest do
  use Helheim.DataCase
  alias Helheim.Artist

  describe "with_records/1" do
    test "returns an empty list unchanged" do
      assert Artist.with_records([]) == []
    end

    test "attaches the artist record, matching the name case-insensitively" do
      artist = insert(:artist, name: "Metallica")

      assert [{"metallica", 3, found}] = Artist.with_records([{"metallica", 3}])
      assert found.id == artist.id
    end

    test "passes through names with no artist record" do
      assert Artist.with_records([{"Nobody", 1}]) == [{"Nobody", 1, nil}]
    end

    test "keeps the order of the aggregated rows" do
      insert(:artist, name: "Bathory")

      assert [{"Metallica", 5, nil}, {"Bathory", 2, %Artist{}}] =
               Artist.with_records([{"Metallica", 5}, {"Bathory", 2}])
    end
  end
end
