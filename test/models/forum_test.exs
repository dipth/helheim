defmodule Helheim.ForumTest do
  use Helheim.ModelCase
  alias Helheim.Repo
  alias Helheim.Forum

  @valid_attrs %{title: "Foo", description: "Bar"}

  describe "changeset/2" do
    test "it is valid with valid attrs" do
      changeset = Forum.changeset(%Forum{}, @valid_attrs)
      assert changeset.valid?
    end

    test "it requires a title" do
      changeset = Forum.changeset(%Forum{}, Map.delete(@valid_attrs, :title))
      refute changeset.valid?
    end

    test "it trims the title and description" do
      changeset = Forum.changeset(%Forum{}, Map.merge(@valid_attrs, %{title: "   Hello   ", description: "   World   "}))
      assert changeset.changes.title       == "Hello"
      assert changeset.changes.description == "World"
    end
  end

  describe "in_positional_order/1" do
    test "it returns categories in order of position from low to high" do
      insert(:forum, title: "Category 2", rank: 1)
      insert(:forum, title: "Category 3", rank: 2)
      insert(:forum, title: "Category 1", rank: 0)

      categories = Forum |> Forum.in_positional_order |> Repo.all
      titles     = Enum.map categories, fn(c) -> c.title end
      assert ["Category 1", "Category 2", "Category 3"] == titles
    end
  end
end
