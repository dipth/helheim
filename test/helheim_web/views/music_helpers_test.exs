defmodule HelheimWeb.MusicHelpersTest do
  use ExUnit.Case, async: true
  import HelheimWeb.MusicHelpers

  describe "tag_label/1" do
    test "it upper cases the first letter of each word" do
      assert tag_label("thrash metal") == "Thrash Metal"
      assert tag_label("electronic body music") == "Electronic Body Music"
    end

    test "it treats a hyphen as a word boundary" do
      assert tag_label("post-punk") == "Post-Punk"
      assert tag_label("avant-garde metal") == "Avant-Garde Metal"
    end

    test "it treats an ampersand and a slash as word boundaries" do
      assert tag_label("r&b") == "R&B"
      assert tag_label("rock/pop") == "Rock/Pop"
    end

    test "it does not treat a digit as a word boundary" do
      assert tag_label("80s") == "80s"
      assert tag_label("00s pop") == "00s Pop"
    end

    test "it leaves an acronym someone typed properly alone" do
      assert tag_label("NWOBHM") == "NWOBHM"
      assert tag_label("EBM industrial") == "EBM Industrial"
    end

    test "it handles non-ascii letters" do
      assert tag_label("åndelig musik") == "Åndelig Musik"
    end

    test "it leaves an already labelled tag unchanged" do
      assert tag_label("Black Metal") == "Black Metal"
    end

    test "it passes nil through" do
      assert tag_label(nil) == nil
    end
  end
end
