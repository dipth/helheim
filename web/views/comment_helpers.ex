defmodule Helheim.CommentHelpers do
  import Phoenix.HTML.Tag

  def comment_count_badge(commentable) do
    content_tag :span, class: "badge badge-default" do
      [
        content_tag(:i, "", class: "fa fa-fw fa-comment"),
        {:safe, [" "]},
        {:safe, ["#{commentable.comment_count}"]}
      ]
    end
  end
end
