defmodule Helheim.Visibility do
  @visibilities ["private", "friends_only", "public"]
  def visibilities, do: @visibilities

  def human_visibility(visibility) do
    Gettext.dgettext(Helheim.Gettext, "visibilities", visibility)
  end

  def human_visibilities do
    Enum.map(visibilities(), fn visibility ->
      human_visibility visibility
    end)
  end

  def visibilities_with_human do
    Enum.zip(human_visibilities(), visibilities()) |> Enum.into(Map.new)
  end
end
