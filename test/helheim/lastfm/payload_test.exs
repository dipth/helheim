defmodule Helheim.Lastfm.PayloadTest do
  use ExUnit.Case, async: true
  alias Helheim.Lastfm.Payload

  describe "image_url/2" do
    test "picks the url for the requested size" do
      images = [
        %{"size" => "medium", "#text" => "https://img/64.jpg"},
        %{"size" => "extralarge", "#text" => "https://img/300.jpg"}
      ]
      assert Payload.image_url(images, "extralarge") == "https://img/300.jpg"
    end

    test "treats blanks and the placeholder star as no image" do
      placeholder = "https://img/2a96cbd8b46e442fc41c2b86b821562f.png"
      assert Payload.image_url([%{"size" => "medium", "#text" => ""}], "medium") == nil
      assert Payload.image_url([%{"size" => "medium", "#text" => placeholder}], "medium") == nil
    end

    test "tolerates non-list and malformed payloads" do
      assert Payload.image_url("not a list", "medium") == nil
      assert Payload.image_url(nil, "medium") == nil
      assert Payload.image_url(["junk"], "medium") == nil
    end
  end

  describe "tag_names/1" do
    test "extracts names from a tag list" do
      assert Payload.tag_names(%{"tag" => [%{"name" => "metal"}, %{"name" => "80s"}]}) == ["metal", "80s"]
    end

    test "handles a bare single tag object" do
      assert Payload.tag_names(%{"tag" => %{"name" => "metal"}}) == ["metal"]
    end

    test "tolerates the API's inconsistent empty serializations" do
      assert Payload.tag_names(%{"tag" => []}) == []
      assert Payload.tag_names("") == []
      assert Payload.tag_names([]) == []
      assert Payload.tag_names(nil) == []
      assert Payload.tag_names(%{"tag" => ["junk", %{"name" => "metal"}]}) == ["metal"]
    end
  end
end
