defmodule Helheim.BlogPostTest do
  use Helheim.ModelCase
  alias Helheim.BlogPost
  alias Helheim.Repo

  @valid_attrs %{body: "some content", title: "some content", visibility: "public"}

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

    test "requires a visibility setting" do
      changeset = BlogPost.changeset(%BlogPost{}, Map.delete(@valid_attrs, :visibility))
      refute changeset.valid?
    end

    test "it only allows valid visibilities" do
      Enum.each(Helheim.Visibility.visibilities, fn(v) ->
        changeset = BlogPost.changeset(%BlogPost{}, Map.merge(@valid_attrs, %{visibility: v}))
        assert changeset.valid?
      end)

      changeset = BlogPost.changeset(%BlogPost{}, Map.merge(@valid_attrs, %{visibility: "invalid"}))
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

  describe "newest_for_frontpage/1" do
    test "always returns public blog posts" do
      viewer      = insert(:user)
      blog_post   = insert(:blog_post, visibility: "public")
      blog_posts  = BlogPost.newest_for_frontpage(viewer, 10) |> Repo.all
      assert Enum.find(blog_posts, fn(p) -> p.id == blog_post.id end)
    end

    test "returns friends_only blog posts if the viewer is the author of the blog post" do
      viewer      = insert(:user)
      blog_post   = insert(:blog_post, user: viewer, visibility: "friends_only")
      blog_posts  = BlogPost.newest_for_frontpage(viewer, 10) |> Repo.all
      assert Enum.find(blog_posts, fn(p) -> p.id == blog_post.id end)
    end

    test "returns friends_only blog posts if the viewer is friends with the author of the blog post" do
      viewer      = insert(:user)
      blog_post   = insert(:blog_post, visibility: "friends_only")
      _friendship = insert(:friendship, sender: viewer, recipient: blog_post.user)
      blog_posts  = BlogPost.newest_for_frontpage(viewer, 10) |> Repo.all
      assert Enum.find(blog_posts, fn(p) -> p.id == blog_post.id end)
    end

    test "does not return friends_only blog posts if the viewer is not the author of the blost post or friends with the author of the blog post" do
      viewer      = insert(:user)
      blog_post   = insert(:blog_post, visibility: "friends_only")
      blog_posts  = BlogPost.newest_for_frontpage(viewer, 10) |> Repo.all
      refute Enum.find(blog_posts, fn(p) -> p.id == blog_post.id end)
    end

    test "does not return friends_only blog posts if the viewer is only pending friends with the author of the blog post" do
      viewer      = insert(:user)
      blog_post   = insert(:blog_post, visibility: "friends_only")
      _friendship = insert(:friendship_request, sender: viewer, recipient: blog_post.user)
      blog_posts  = BlogPost.newest_for_frontpage(viewer, 10) |> Repo.all
      refute Enum.find(blog_posts, fn(p) -> p.id == blog_post.id end)
    end

    test "never returns private blog posts" do
      viewer      = insert(:user)
      blog_post   = insert(:blog_post, user: viewer, visibility: "private")
      blog_posts  = BlogPost.newest_for_frontpage(viewer, 10) |> Repo.all
      refute Enum.find(blog_posts, fn(p) -> p.id == blog_post.id end)
    end

    test "orders a post with a more recent published_at date before one with an older published_at date" do
      user       = insert(:user)
      blog_post1 = insert(:blog_post, published_at: Timex.shift(Timex.now, minutes: -1))
      blog_post2 = insert(:blog_post, published_at: Timex.shift(Timex.now, minutes: -2))
      blog_posts = BlogPost.newest_for_frontpage(user, 10) |> Repo.all
      ids        = Enum.map blog_posts, fn(c) -> c.id end
      assert [blog_post1.id, blog_post2.id] == ids
    end

    test "only includes the latest published blog post for each user" do
      user       = insert(:user)
      blog_post1 = insert(:blog_post, published_at: Timex.shift(Timex.now, minutes: -1), published: false)
      blog_post2 = insert(:blog_post, published_at: Timex.shift(Timex.now, minutes: -2), published: true, user: blog_post1.user)
      blog_post3 = insert(:blog_post, published_at: Timex.shift(Timex.now, minutes: -3), published: true, user: blog_post1.user)
      blog_post4 = insert(:blog_post, published_at: Timex.shift(Timex.now, minutes: -4), published: true)
      blog_posts = BlogPost.newest_for_frontpage(user, 10) |> Repo.all
      ids        = Enum.map blog_posts, fn(c) -> c.id end
      refute Enum.member?(ids, blog_post1.id)
      assert Enum.member?(ids, blog_post2.id)
      refute Enum.member?(ids, blog_post3.id)
      assert Enum.member?(ids, blog_post4.id)
    end

    test "only returns a maximun number of blog posts as specified" do
      insert_list(3, :blog_post, published: true)
      user       = insert(:user)
      blog_posts = BlogPost.newest_for_frontpage(user, 2) |> Repo.all
      assert length(blog_posts) == 2
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

  describe "visible_by/2" do
    test "always returns blog posts that are set to public" do
      user       = insert(:user)
      blog_post  = insert(:blog_post, visibility: "public")
      blog_posts = BlogPost |> BlogPost.visible_by(user) |> Repo.all
      ids        = Enum.map blog_posts, fn(c) -> c.id end
      assert [blog_post.id] == ids
    end

    test "always returns private blog posts if the user is the same as the user of the blog post" do
      user       = insert(:user)
      blog_post  = insert(:blog_post, user: user, visibility: "private")
      blog_posts = BlogPost |> BlogPost.visible_by(user) |> Repo.all
      ids        = Enum.map blog_posts, fn(c) -> c.id end
      assert [blog_post.id] == ids
    end

    test "always returns verified_only blog posts if the user is the same as the user of the blog post" do
      user       = insert(:user, verified_at: nil)
      blog_post  = insert(:blog_post, user: user, visibility: "verified_only")
      blog_posts = BlogPost |> BlogPost.visible_by(user) |> Repo.all
      ids        = Enum.map blog_posts, fn(c) -> c.id end
      assert [blog_post.id] == ids
    end

    test "always returns verified_only blog posts if the user is verified" do
      user = insert(:user, verified_at: Timex.now)
      blog_post  = insert(:blog_post, visibility: "verified_only")
      blog_posts = BlogPost |> BlogPost.visible_by(user) |> Repo.all
      ids        = Enum.map blog_posts, fn(c) -> c.id end
      assert [blog_post.id] == ids
    end

    test "always returns friends_only blog posts if the user is the same as the user of the blog post" do
      user       = insert(:user)
      blog_post  = insert(:blog_post, user: user, visibility: "friends_only")
      blog_posts = BlogPost |> BlogPost.visible_by(user) |> Repo.all
      ids        = Enum.map blog_posts, fn(c) -> c.id end
      assert [blog_post.id] == ids
    end

    test "never returns private blog posts if the user is not the same as the user of the blog post" do
      user       = insert(:user)
      _blog_post = insert(:blog_post, visibility: "private")
      blog_posts = BlogPost |> BlogPost.visible_by(user) |> Repo.all
      assert blog_posts == []
    end

    test "never returns verified_only blog posts if the user is not verified" do
      user = insert(:user, verified_at: nil)
      _blog_post  = insert(:blog_post, visibility: "verified_only")
      blog_posts = BlogPost |> BlogPost.visible_by(user) |> Repo.all
      assert blog_posts == []
    end

    test "never returns friends_only blog posts if the user is not friends with the user of the blog post" do
      user       = insert(:user)
      _blog_post = insert(:blog_post, visibility: "friends_only")
      blog_posts = BlogPost |> BlogPost.visible_by(user) |> Repo.all
      assert blog_posts == []
    end

    test "always returns friends_only blog posts if the user is befriended by the user of the blog post" do
      author      = insert(:user)
      user        = insert(:user)
      blog_post   = insert(:blog_post, user: author, visibility: "friends_only")
      _friendship = insert(:friendship, sender: author, recipient: user)
      blog_posts = BlogPost |> BlogPost.visible_by(user) |> Repo.all
      ids        = Enum.map blog_posts, fn(c) -> c.id end
      assert [blog_post.id] == ids
    end

    test "always returns friends_only blog posts if the user of the blog post is befriended by the user" do
      author      = insert(:user)
      user        = insert(:user)
      blog_post   = insert(:blog_post, user: author, visibility: "friends_only")
      _friendship = insert(:friendship, sender: user, recipient: author)
      blog_posts = BlogPost |> BlogPost.visible_by(user) |> Repo.all
      ids        = Enum.map blog_posts, fn(c) -> c.id end
      assert [blog_post.id] == ids
    end

    test "never returns friends_only blog posts if the user is pending friendship from the user of the blog post" do
      author      = insert(:user)
      user        = insert(:user)
      _blog_post  = insert(:blog_post, user: author, visibility: "friends_only")
      _friendship = insert(:friendship_request, sender: author, recipient: user)
      blog_posts = BlogPost |> BlogPost.visible_by(user) |> Repo.all
      assert blog_posts == []
    end

    test "never returns friends_only blog posts if the user of the blog post is pending friendship from the user" do
      author      = insert(:user)
      user        = insert(:user)
      _blog_post  = insert(:blog_post, user: author, visibility: "friends_only")
      _friendship = insert(:friendship_request, sender: user, recipient: author)
      blog_posts = BlogPost |> BlogPost.visible_by(user) |> Repo.all
      assert blog_posts == []
    end
  end

  describe "not_private/1" do
    test "returns public blog posts" do
      blog_post  = insert(:blog_post, visibility: "public")
      blog_posts = BlogPost |> BlogPost.not_private |> Repo.all
      assert Enum.find(blog_posts, fn(p) -> p.id == blog_post.id end)
    end

    test "returns friends_only blog posts" do
      blog_post  = insert(:blog_post, visibility: "friends_only")
      blog_posts = BlogPost |> BlogPost.not_private |> Repo.all
      assert Enum.find(blog_posts, fn(p) -> p.id == blog_post.id end)
    end

    test "does not return private blog posts" do
      blog_post  = insert(:blog_post, visibility: "private")
      blog_posts = BlogPost |> BlogPost.not_private |> Repo.all
      refute Enum.find(blog_posts, fn(p) -> p.id == blog_post.id end)
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

  describe "edited/1" do
    test "returns true if the blog post has been updated more than one minute after it was published" do
      now       = DateTime.utc_now
      later     = Timex.shift(Timex.now, seconds: 60)
      blog_post = insert(:blog_post, published_at: now, updated_at: later)
      assert BlogPost.edited?(blog_post)
    end

    test "returns false if the blog post has been updated less than one minute after it was published" do
      now       = DateTime.utc_now
      later     = Timex.shift(Timex.now, seconds: 59)
      blog_post = insert(:blog_post, published_at: now, updated_at: later)
      refute BlogPost.edited?(blog_post)
    end

    test "returns false if the blog post has not been published" do
      blog_post = insert(:blog_post, published_at: nil)
      refute BlogPost.edited?(blog_post)
    end
  end
end
