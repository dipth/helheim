defmodule Helheim.BlogPostView do
  use Helheim.Web, :view
  alias Helheim.BlogPost

  def edited_label(blog_post) do
    if BlogPost.edited?(blog_post) do
      content_tag :span, class: "badge badge-default" do
        [
          content_tag(:i, "", class: "fa fa-fw fa-pencil"),
          {:safe, [" "]},
          {:safe, [gettext("Edited")]}
        ]
      end
    end
  end
end
