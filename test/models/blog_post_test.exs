defmodule Helheim.BlogPostTest do
  use Helheim.ModelCase

  alias Helheim.BlogPost

  @valid_attrs %{body: "some content", title: "some content"}

  describe "changeset/2" do
    test "is valid with valid attrs" do
      changeset = BlogPost.changeset(%BlogPost{}, @valid_attrs)
      assert changeset.valid?
    end

    test "requires a body" do
      changeset = BlogPost.changeset(%BlogPost{}, Map.delete(@valid_attrs, :body))
      refute changeset.valid?
    end

    test "requires a title" do
      changeset = BlogPost.changeset(%BlogPost{}, Map.delete(@valid_attrs, :title))
      refute changeset.valid?
    end

    test "trims the title" do
      changeset = BlogPost.changeset(%BlogPost{}, Map.merge(@valid_attrs, %{title: "   Foo   "}))
      assert changeset.changes.title  == "Foo"
    end

    test "sets the published_at to the current time when changing published to true" do
      changeset = BlogPost.changeset(%BlogPost{}, Map.merge(@valid_attrs, %{published: true}))
      {:ok, time_diff, _, _} = Calendar.DateTime.diff(changeset.changes.published_at, DateTime.utc_now)
      assert time_diff < 10
    end

    test "leaves published_at blank when not changing published to true" do
      changeset = BlogPost.changeset(%BlogPost{}, Map.delete(@valid_attrs, :published))
      refute changeset.changes[:published_at]
      changeset = BlogPost.changeset(%BlogPost{}, Map.merge(@valid_attrs, %{published: false}))
      refute changeset.changes[:published_at]
    end

    test "does not change the published_at value when re-publishing a blog post" do
      blog_post = insert(:blog_post, published: false, published_at: Timex.shift(Timex.now, days: -10))
      changeset = BlogPost.changeset(blog_post, Map.merge(@valid_attrs, %{published: true}))
      refute changeset.changes[:published_at]
    end
  end

  describe "newest/1" do
    test "orders a post with a more recent published_at date before one with an older published_at date" do
      blog_post1 = insert(:blog_post, published_at: Timex.shift(Timex.now, minutes: -1))
      blog_post2 = insert(:blog_post, published_at: Timex.shift(Timex.now, minutes: -2))
      blog_posts = BlogPost |> BlogPost.newest |> Repo.all
      ids        = Enum.map blog_posts, fn(c) -> c.id end
      assert [blog_post1.id, blog_post2.id] == ids
    end

    test "orders a post with a blank published_at date before one with a non-blank published_at date" do
      blog_post1 = insert(:blog_post, published_at: nil)
      blog_post2 = insert(:blog_post, published_at: Timex.shift(Timex.now, minutes: -1))
      blog_posts = BlogPost |> BlogPost.newest |> Repo.all
      ids        = Enum.map blog_posts, fn(c) -> c.id end
      assert [blog_post1.id, blog_post2.id] == ids
    end

    test "orders a recently inserted post with a blank published_at date before an older inserted one with a blank published_at date" do
      blog_post1 = insert(:blog_post, inserted_at: Timex.shift(Timex.now, minutes: -1), published_at: nil)
      blog_post2 = insert(:blog_post, inserted_at: Timex.shift(Timex.now, minutes: -2), published_at: nil)
      blog_posts = BlogPost |> BlogPost.newest |> Repo.all
      ids        = Enum.map blog_posts, fn(c) -> c.id end
      assert [blog_post1.id, blog_post2.id] == ids
    end
  end

  describe "published/1" do
    test "only returns published blog posts" do
      _blog_post1 = insert(:blog_post, published_at: DateTime.utc_now, published: false)
      blog_post2  = insert(:blog_post, published_at: DateTime.utc_now, published: true)
      blog_posts  = BlogPost |> BlogPost.published |> Repo.all
      ids         = Enum.map blog_posts, fn(c) -> c.id end
      assert [blog_post2.id] == ids
    end
  end

  describe "published_by_owner/1" do
    test "only returns published blog posts if owner and current_user is not the same" do
      user_1      = insert(:user)
      user_2      = insert(:user)
      _blog_post1 = insert(:blog_post, user: user_1, published_at: DateTime.utc_now, published: false)
      blog_post2  = insert(:blog_post, user: user_1, published_at: DateTime.utc_now, published: true)
      blog_posts  = BlogPost |> BlogPost.published_by_owner(user_1, user_2) |> Repo.all
      ids         = Enum.map blog_posts, fn(c) -> c.id end
      assert [blog_post2.id] == ids
    end

    test "returns unpublished blog posts if owner and current_user is not the same" do
      user_1      = insert(:user)
      blog_post1  = insert(:blog_post, user: user_1, published_at: DateTime.utc_now, published: false)
      blog_post2  = insert(:blog_post, user: user_1, published_at: DateTime.utc_now, published: true)
      blog_posts  = BlogPost |> BlogPost.published_by_owner(user_1, user_1) |> Repo.all
      ids         = Enum.map blog_posts, fn(c) -> c.id end
      assert [blog_post1.id, blog_post2.id] == ids
    end
  end
end
