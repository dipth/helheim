defmodule Helheim.BlogPostTest do
  use Helheim.ModelCase

  alias Helheim.BlogPost

  @valid_attrs %{body: "some content", title: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = BlogPost.changeset(%BlogPost{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = BlogPost.changeset(%BlogPost{}, @invalid_attrs)
    refute changeset.valid?
  end
end
