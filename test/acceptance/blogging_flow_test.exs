defmodule Helheim.BloggingFlowTest do
  use Helheim.AcceptanceCase, async: true
  import Helheim.Factory

  test "users can create a new blog post", %{session: session} do
    user = insert(:user)

    session
    |> visit("/sessions/new")
    |> fill_in(gettext("E-mail"), with: user.email)
    |> fill_in(gettext("Password"), with: "password")
    |> click_on(gettext("Sign In"))

    session
    |> click_link(gettext("Your Blog Posts"))
    |> click_link(gettext("New Blog Post"))
    |> fill_in(gettext("Title"), with: "My Awesome Title")
    |> execute_script("$('#blog_post_body_editor .ql-editor').html('This is my awesome text');")

    result = session
    |> click_on(gettext("Save Blog Post"))
    |> find(".alert.alert-success")
    |> text

    assert result =~ gettext("Blog post created successfully.")
  end

  test "users can edit their existing blog posts", %{session: session} do
    blog_post = insert(:blog_post, title: "Blog Title Test")
    user = blog_post.user

    session
    |> visit("/sessions/new")
    |> fill_in(gettext("E-mail"), with: user.email)
    |> fill_in(gettext("Password"), with: "password")
    |> click_on(gettext("Sign In"))

    session
    |> click_link(gettext("Blog Title Test"))
    |> click_link(gettext("Edit"))
    |> fill_in(gettext("Title"), with: "My Awesome Title")

    result = session
    |> click_on(gettext("Save Blog Post"))
    |> find(".alert.alert-success")
    |> text

    assert result =~ gettext("Blog post updated successfully.")
  end

  test "users can comment on blog posts", %{session: session} do
    blog_post = insert(:blog_post)
    user = insert(:user)
    sign_in session, user

    session
    |> visit("/profiles/#{blog_post.user.id}/blog_posts/#{blog_post.id}")

    result = session
    |> fill_in(gettext("Write new comment:"), with: "Super Duper Awesome Comment")
    |> click_on(gettext("Post Comment"))
    |> find(".alert.alert-success")
    |> text

    assert result =~ gettext("Comment created successfully")
    assert find(session, "p", text: "Super Duper Awesome Comment")
  end

  # TODO: Enable when wallaby / phoenixjs supports alert interaction
  # test "users can delete their existing blog posts", %{session: session} do
  #   blog_post = insert(:blog_post, title: "Blog Title Test")
  #   user = blog_post.user
  #
  #   session
  #   |> visit("/sessions/new")
  #   |> fill_in(gettext("E-mail"), with: user.email)
  #   |> fill_in(gettext("Password"), with: "password")
  #   |> click_on(gettext("Sign In"))
  #
  #   session
  #   |> click_link(gettext("Blog Title Test"))
  #   |> click_link(gettext("Delete"))
  #   |> take_screenshot
  #
  #   result = session
  #   |> find(".alert.alert-success")
  #   |> text
  #
  #   assert result =~ gettext("Blog post deleted successfully.")
  # end
end
