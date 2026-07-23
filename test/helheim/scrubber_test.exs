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

      input = "<p style=\"text-decoration: line-through;\">test</p>"
      assert HtmlSanitizeEx.Scrubber.scrub(input, Helheim.Scrubber) == input
    end

    test "scrubs the body of p-tags" do
      input = "<p><script>alert('foo')</script></p>"
      assert HtmlSanitizeEx.Scrubber.scrub(input, Helheim.Scrubber) == "<p>alert('foo')</p>"
    end

    test "allows setting alignment style for span-tags while stripping other styles" do
      input = "<span style=\"text-align: center;\">test</span>"
      assert HtmlSanitizeEx.Scrubber.scrub(input, Helheim.Scrubber) == input

      input = "<span style=\"text-align: right;\">test</span>"
      assert HtmlSanitizeEx.Scrubber.scrub(input, Helheim.Scrubber) == input

      input = "<span style=\"text-align: justify;\">test</span>"
      assert HtmlSanitizeEx.Scrubber.scrub(input, Helheim.Scrubber) == input

      input = "<span style=\"text-align: center; color: red;\">test</span>"
      assert HtmlSanitizeEx.Scrubber.scrub(input, Helheim.Scrubber) == "<span style=\"text-align: center;\">test</span>"

      input = "<span style=\"color: red;\">test</span>"
      assert HtmlSanitizeEx.Scrubber.scrub(input, Helheim.Scrubber) == "<span>test</span>"

      input = "<span style=\"text-decoration: line-through;\">test</span>"
      assert HtmlSanitizeEx.Scrubber.scrub(input, Helheim.Scrubber) == input
    end

    test "allows setting alignment style for heading-tags while stripping other styles" do
      input = "<h2 style=\"text-align: center;\">test</h2>"
      assert HtmlSanitizeEx.Scrubber.scrub(input, Helheim.Scrubber) == input

      input = "<h4 style=\"text-align: right;\">test</h4>"
      assert HtmlSanitizeEx.Scrubber.scrub(input, Helheim.Scrubber) == input

      input = "<h1 style=\"text-align: center; color: red;\">test</h1>"
      assert HtmlSanitizeEx.Scrubber.scrub(input, Helheim.Scrubber) == "<h1 style=\"text-align: center;\">test</h1>"

      input = "<h3 style=\"color: red;\">test</h3>"
      assert HtmlSanitizeEx.Scrubber.scrub(input, Helheim.Scrubber) == "<h3>test</h3>"
    end

    test "strips other attributes from heading-tags" do
      input = "<h2 class=\"huge\" id=\"anchor\" style=\"text-align: center;\">test</h2>"
      assert HtmlSanitizeEx.Scrubber.scrub(input, Helheim.Scrubber) == "<h2 style=\"text-align: center;\">test</h2>"
    end

    test "strips the src of img-tags whose src is not a valid absolute url" do
      input = "<img src=\"not-a-url\">"
      assert HtmlSanitizeEx.Scrubber.scrub(input, Helheim.Scrubber) == "<img class=\"img-fluid rounded mx-auto d-block\" />"
    end

    test "scrubs the body of span-tags" do
      input = "<span><script>alert('foo')</script></span>"
      assert HtmlSanitizeEx.Scrubber.scrub(input, Helheim.Scrubber) == "<span>alert('foo')</span>"
    end
  end
end
