defmodule Helheim.Scrubber do
  require HtmlSanitizeEx.Scrubber.Meta
  alias HtmlSanitizeEx.Scrubber.Meta

  Meta.remove_cdata_sections_before_scrub
  Meta.strip_comments

  Meta.allow_tag_with_uri_attributes   "a", ["href"], ["http", "https"]
  Meta.allow_tag_with_these_attributes "a", ["name", "title"]

  Meta.allow_tag_with_these_attributes "h1", []
  Meta.allow_tag_with_these_attributes "h2", []
  Meta.allow_tag_with_these_attributes "h3", []
  Meta.allow_tag_with_these_attributes "h4", []

  Meta.allow_tag_with_these_attributes "blockquote", []
  Meta.allow_tag_with_these_attributes "p", []

  Meta.allow_tag_with_these_attributes "strong", []
  Meta.allow_tag_with_these_attributes "em", []
  Meta.allow_tag_with_these_attributes "strike", []
  Meta.allow_tag_with_these_attributes "sup", []
  Meta.allow_tag_with_these_attributes "sub", []

  Meta.allow_tag_with_these_attributes "br", []

  def scrub({"img", attributes, _}) do
    attributes = scrub_attributes("img", attributes)
    attributes = attributes ++ [{"class", "img-fluid rounded mx-auto d-block"}]
    IO.inspect attributes
    {"img", attributes, []}
  end

  defp scrub_attributes("img", attributes) do
    Enum.map(attributes, fn(attr) -> scrub_attribute("img", attr) end)
    |> Enum.reject(&(is_nil(&1)))
  end

  def scrub_attribute("img", {"alt", alt}), do: {"alt", alt}
  def scrub_attribute("img", {"src", value}) do
    %{host: host, scheme: scheme} = URI.parse(value)
    %{host: asset_host} = URI.parse(Application.get_env(:arc, :asset_host))

    if String.downcase(host) == String.downcase(asset_host) && scheme == "https" do
      {"src", value}
    else
      nil
    end
  end

  Meta.allow_tag_with_these_attributes "ul", []
  Meta.allow_tag_with_these_attributes "ol", []
  Meta.allow_tag_with_these_attributes "li", []

  Meta.allow_tag_with_these_attributes "hr", []

  Meta.strip_everything_not_covered
end
