defmodule Helheim.VisibilityHelpers do
  import Phoenix.HTML.Tag
  alias Helheim.Visibility

  def visibility_badge(%{visibility: "public"}), do: nil
  def visibility_badge(subject) do
    human = Visibility.human_visibility subject.visibility
    content_tag :span, class: "badge badge-primary" do
      [
        content_tag(:i, "", class: "fa fa-fw fa-lock"),
        {:safe, [" "]},
        {:safe, [human]}
      ]
    end
  end
end
