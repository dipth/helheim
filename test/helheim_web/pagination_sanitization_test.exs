defmodule HelheimWeb.PaginationSanitizationTest do
  use Helheim.DataCase
  alias HelheimWeb.PaginationSanitization

  describe "sanitized_page/1" do
    test "it returns 1 when passing nil" do
      assert PaginationSanitization.sanitized_page(nil) == 1
    end

    test "it returns 1 when passing an empty string" do
      assert PaginationSanitization.sanitized_page("") == 1
    end

    test "it converts the page to an integer" do
      assert PaginationSanitization.sanitized_page("100") == 100
    end

    test "it returns 1 when passing a negative integer as a string" do
      assert PaginationSanitization.sanitized_page("-1") == 1
    end

    test "it returns 1000 when passing an integer above 1000 as a string" do
      assert PaginationSanitization.sanitized_page("1001") == 1000
    end

    test "it returns 1 when passing zero as a string" do
      assert PaginationSanitization.sanitized_page("0") == 1
    end
  end
end
