defmodule Helheim.ScrubberTest do
  use Helheim.DataCase

  describe "scrub/1" do
    test "allows setting alignment style for p-tags while stripping other styles" do
      input = "<p style=\"text-align: center;\">test</p>"
      assert HtmlSanitizeEx.Scrubber.scrub(input, Helheim.Scrubber) == input

      input = "<p style=\"text-align: right;\">test</p>"
      assert HtmlSanitizeEx.Scrubber.scrub(input, Helheim.Scrubber) == input

      input = "<p style=\"text-align: justify;\">test</p>"
      assert HtmlSanitizeEx.Scrubber.scrub(input, Helheim.Scrubber) == input

      input = "<p style=\"text-align: center; color: red;\">test</p>"
      assert HtmlSanitizeEx.Scrubber.scrub(input, Helheim.Scrubber) == "<p style=\"text-align: center;\">test</p>"

      input = "<p style=\"color: red;\">test</p>"
      assert HtmlSanitizeEx.Scrubber.scrub(input, Helheim.Scrubber) == "<p>test</p>"
    end

    test "scrubs the body of p-tags" do
      input = "<p><script>alert('foo')</script></p>"
      assert HtmlSanitizeEx.Scrubber.scrub(input, Helheim.Scrubber) == "<p>alert('foo')</p>"
    end
  end
end
