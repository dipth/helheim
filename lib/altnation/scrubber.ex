defmodule Altnation.Scrubber do
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

  Meta.allow_tag_with_uri_attributes   "img", ["src"], ["https"]
  Meta.allow_tag_with_these_attributes "img", ["alt"]

  Meta.allow_tag_with_these_attributes "ul", []
  Meta.allow_tag_with_these_attributes "ol", []
  Meta.allow_tag_with_these_attributes "li", []

  Meta.allow_tag_with_these_attributes "hr", []

  Meta.strip_everything_not_covered
end
