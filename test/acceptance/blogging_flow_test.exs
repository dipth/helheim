defmodule Altnation.BloggingFlowTest do
  use Altnation.AcceptanceCase, async: true
  import Altnation.Factory

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
