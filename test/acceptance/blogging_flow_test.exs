defmodule Helheim.BloggingFlowTest do
  use Helheim.AcceptanceCase#, async: true

  setup [:create_and_sign_in_user]

  # TODO: Enable when wallaby supports interacting with TinyMCE
  # test "users can create a new blog post", %{session: session} do
  #   session
  #   |> click_link(gettext("Your Blog Posts"))
  #   |> click_link(gettext("New Blog Post"))
  #   |> fill_in(gettext("Title"), with: "My Awesome Title")
  #   |> execute_script("$('#tinymce').html('This is my awesome text');")
  #
  #   result = session
  #   |> click_on(gettext("Save Blog Post"))
  #   |> find(".alert.alert-success")
  #   |> text
  #
  #   assert result =~ gettext("Blog post created successfully.")
  # end

  # TODO: Enable when wallaby supports interacting with TinyMCE
  # test "users can edit their existing blog posts", %{session: session, user: user} do
  #   insert(:blog_post, user: user, title: "Blog Title Test")
  #
  #   session
  #   |> click_link(gettext("Your Blog Posts"))
  #   |> click_link("Blog Title Test")
  #   |> click_link(gettext("Edit"))
  #   |> fill_in(gettext("Title"), with: "My Awesome Title")
  #
  #   result = session
  #   |> click_on(gettext("Save Blog Post"))
  #   |> find(".alert.alert-success")
  #   |> text
  #
  #   assert result =~ gettext("Blog post updated successfully.")
  # end

  test "users can comment on blog posts", %{session: session} do
    blog_post = insert(:blog_post)

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
  # test "users can delete their existing blog posts", %{session: session, user: user} do
  #   blog_post = insert(:blog_post, user: user, title: "Blog Title Test")
  #
  #   session
  #   |> click_link(gettext("Your Blog Posts"))
  #   |> click_link("Blog Title Test")
  #   |> click_link(gettext("Delete"))
  #
  #   result = session
  #   |> find(".alert.alert-success")
  #   |> text
  #
  #   assert result =~ gettext("Blog post deleted successfully.")
  # end
end
