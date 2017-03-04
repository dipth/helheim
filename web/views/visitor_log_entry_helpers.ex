defmodule Helheim.VisitorLogEntryHelpers do
  import Phoenix.HTML.Tag

  def visitor_count_badge(thing, opts \\ []) do
    content_tag :span, class: "badge badge-default" do
      [
        content_tag(:i, "", class: "fa fa-fw fa-eye"),
        {:safe, [" "]},
        {:safe, ["#{thing.visitor_count}"]}
      ]
    end
  end
end
