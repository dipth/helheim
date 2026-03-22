defmodule Helheim.Helpers.FormatHelpersTest do
  use ExUnit.Case, async: true

  alias Helheim.Helpers.FormatHelpers

  describe "truncate/2" do
    test "returns the original string when shorter than max_length" do
      assert FormatHelpers.truncate("Hi", 5) == "Hi"
    end

    test "returns the original string when exactly max_length" do
      assert FormatHelpers.truncate("Hello", 5) == "Hello"
    end

    test "truncates and appends '...' when longer than max_length" do
      assert FormatHelpers.truncate("Hello, World!", 8) == "Hello..."
    end

    test "handles max_length equal to omission length by returning only omission" do
      assert FormatHelpers.truncate("Hello, World!", 3) == "..."
    end

    test "handles empty string" do
      assert FormatHelpers.truncate("", 5) == ""
    end

    test "handles unicode characters correctly" do
      assert FormatHelpers.truncate("Hællo Wørld", 7) == "Hæll..."
    end
  end

  describe "truncate/3 with custom omission" do
    test "uses the provided omission string" do
      assert FormatHelpers.truncate("Hello, World!", 8, "…") == "Hello, …"
    end

    test "uses empty omission" do
      assert FormatHelpers.truncate("Hello, World!", 5, "") == "Hello"
    end
  end

  describe "human_size/1" do
    test "formats bytes below 1 KB" do
      assert FormatHelpers.human_size(0) == "0 Bytes"
      assert FormatHelpers.human_size(512) == "512 Bytes"
      assert FormatHelpers.human_size(1023) == "1023 Bytes"
    end

    test "formats kilobytes" do
      assert FormatHelpers.human_size(1024) == "1 KB"
      assert FormatHelpers.human_size(1536) == "1.5 KB"
    end

    test "formats megabytes" do
      assert FormatHelpers.human_size(1_048_576) == "1 MB"
      assert FormatHelpers.human_size(5_242_880) == "5 MB"
      assert FormatHelpers.human_size(26_214_400) == "25 MB"
    end

    test "formats gigabytes" do
      assert FormatHelpers.human_size(1_073_741_824) == "1 GB"
    end

    test "formats terabytes" do
      assert FormatHelpers.human_size(1_099_511_627_776) == "1 TB"
    end

    test "formats fractional values with up to 2 decimal places" do
      assert FormatHelpers.human_size(1_572_864) == "1.5 MB"
      assert FormatHelpers.human_size(2_684_354_560) == "2.5 GB"
    end
  end

  describe "as_currency/1" do
    test "formats with default options (USD)" do
      assert FormatHelpers.as_currency(25.0) == "$25.00"
    end

    test "formats zero" do
      assert FormatHelpers.as_currency(0.0) == "$0.00"
    end

    test "rounds to two decimal places" do
      assert FormatHelpers.as_currency(19.999) == "$20.00"
    end
  end

  describe "as_currency/2 with options" do
    test "formats with Danish kroner options" do
      result = FormatHelpers.as_currency(25.0, unit: "kr. ", separator: ",", delimiter: ".")
      assert result == "kr. 25,00"
    end

    test "formats large amounts with thousands delimiters" do
      result = FormatHelpers.as_currency(1234.56, unit: "$", separator: ".", delimiter: ",")
      assert result == "$1,234.56"
    end

    test "formats with custom unit" do
      assert FormatHelpers.as_currency(99.99, unit: "€") == "€99.99"
    end

    test "formats large amount with Danish options" do
      result = FormatHelpers.as_currency(12345.67, unit: "kr. ", separator: ",", delimiter: ".")
      assert result == "kr. 12.345,67"
    end
  end
end
