defmodule Helheim.ForumCategoryTest do
  use Helheim.ModelCase
  alias Helheim.Repo
  alias Helheim.ForumCategory

  @valid_attrs %{title: "Foo", description: "Bar"}

  describe "changeset/2" do
    test "it is valid with valid attrs" do
      changeset = ForumCategory.changeset(%ForumCategory{}, @valid_attrs)
      assert changeset.valid?
    end

    test "it requires a title" do
      changeset = ForumCategory.changeset(%ForumCategory{}, Map.delete(@valid_attrs, :title))
      refute changeset.valid?
    end

    test "it trims the title and description" do
      changeset = ForumCategory.changeset(%ForumCategory{}, Map.merge(@valid_attrs, %{title: "   Hello   ", description: "   World   "}))
      assert changeset.changes.title       == "Hello"
      assert changeset.changes.description == "World"
    end
  end

  describe "in_positional_order/1" do
    test "it returns categories in order of position from low to high" do
      insert(:forum_category, title: "Category 2", rank: 1)
      insert(:forum_category, title: "Category 3", rank: 2)
      insert(:forum_category, title: "Category 1", rank: 0)

      categories = ForumCategory |> ForumCategory.in_positional_order |> Repo.all
      titles     = Enum.map categories, fn(c) -> c.title end
      assert ["Category 1", "Category 2", "Category 3"] == titles
    end
  end

  describe "with_forums/1" do
    test "it preloads forums in positional order" do
      category = insert(:forum_category)
      insert(:forum, forum_category: category, title: "Forum 2", rank: 1)
      insert(:forum, forum_category: category, title: "Forum 3", rank: 2)
      insert(:forum, forum_category: category, title: "Forum 1", rank: 0)
      insert(:forum, title: "Forum 4", rank: 1)

      category = ForumCategory |> ForumCategory.with_forums |> Repo.get!(category.id)
      titles   = Enum.map category.forums, fn(c) -> c.title end
      assert ["Forum 1", "Forum 2", "Forum 3"] == titles
    end
  end

  describe "with_forums_and_latest_topic/1" do
    test "it preloads forums in positional order" do
      category = insert(:forum_category)
      insert(:forum, forum_category: category, title: "Forum 2", rank: 1)
      insert(:forum, forum_category: category, title: "Forum 3", rank: 2)
      insert(:forum, forum_category: category, title: "Forum 1", rank: 0)
      insert(:forum, title: "Forum 4", rank: 1)
      category = ForumCategory |> ForumCategory.with_forums_and_latest_topic |> Repo.get!(category.id)
      titles   = Enum.map category.forums, fn(c) -> c.title end
      assert ["Forum 1", "Forum 2", "Forum 3"] == titles
    end

    test "it preloads the latest topic for each forum" do
      category = insert(:forum_category)
      forum = insert(:forum, forum_category: category)
      insert(:forum_topic, forum: forum, title: "Topic 1")
      insert(:forum_topic, forum: forum, title: "Topic 2")
      category = ForumCategory |> ForumCategory.with_forums_and_latest_topic |> Repo.get!(category.id)
      forum    = List.first(category.forums)
      titles   = Enum.map forum.forum_topics, fn(c) -> c.title end
      assert ["Topic 2"] == titles
    end
  end
end
