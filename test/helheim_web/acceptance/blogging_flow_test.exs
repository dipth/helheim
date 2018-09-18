defmodule HelheimWeb.BloggingFlowTest do
  use HelheimWeb.AcceptanceCase#, async: true

  defp your_blog_posts_link,  do: Query.link(gettext("Your Blog Posts"))
  defp title_field,           do: Query.text_field(gettext("Title"))
  defp save_blog_post_button, do: Query.button(gettext("Save Blog Post"))
  defp success_alert,         do: Query.css(".alert.alert-success")
  defp blog_post_link,        do: Query.link("Blog Title Test")

  setup [:create_and_sign_in_user]

  # TODO: Re-enable this test when the current wysiwyg editor has been replaced
  #       with one that doesn't break integration tests
  # test "users can create a new blog post", %{session: session} do
  #   session
  #   |> click(your_blog_posts_link())
  #   |> click(Query.link(gettext("New Blog Post")))
  #   |> fill_in(title_field(), with: "My Awesome Title")
  #   |> click(Query.css("#blog_post_body_ifr"))
  #   |> send_keys("This is my awesome text")
  #
  #   result = session
  #   |> click(save_blog_post_button())
  #   |> find(success_alert())
  #   |> Element.text
  #
  #   assert result =~ gettext("Blog post created successfully.")
  # end

  # TODO: Re-enable this test when the current wysiwyg editor has been replaced
  #       with one that doesn't break integration tests
  # test "users can edit their existing blog posts", %{session: session, user: user} do
  #   insert(:blog_post, user: user, title: "Blog Title Test")
  #
  #   session
  #   |> click(your_blog_posts_link())
  #   |> click(blog_post_link())
  #   |> click(Query.link(gettext("Edit")))
  #   |> fill_in(title_field(), with: "My Awesome Title")
  #
  #   result = session
  #   |> click(save_blog_post_button())
  #   |> find(success_alert())
  #   |> Element.text
  #
  #   assert result =~ gettext("Blog post updated successfully.")
  # end

  test "users can comment on blog posts", %{session: session} do
    blog_post = insert(:blog_post)

    session
    |> visit("/profiles/#{blog_post.user.id}/blog_posts/#{blog_post.id}")

    result = session
    |> fill_in(Query.text_field(gettext("Write new comment:")), with: "Super Duper Awesome Comment")
    |> click(Query.button(gettext("Post Comment")))
    |> find(success_alert())
    |> Element.text

    assert result =~ gettext("Comment created successfully")
    assert find(session, Query.text("Super Duper Awesome Comment"))
  end

  # TODO: Enable when wallaby / phoenixjs supports alert interaction
  # test "users can delete their existing blog posts", %{session: session, user: user} do
  #   blog_post = insert(:blog_post, user: user, title: "Blog Title Test")
  #
  #   session
  #   |> click(your_blog_posts_link())
  #   |> click(blog_post_link())
  #   |> click(Query.link(gettext("Delete")))
  #
  #   result = session
  #   |> find(success_alert())
  #   |> Element.text
  #
  #   assert result =~ gettext("Blog post deleted successfully.")
  # end
end
