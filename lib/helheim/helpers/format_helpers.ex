defmodule Helheim.Helpers.FormatHelpers do
  @moduledoc """
  Formatting utilities for strings and numbers, replacing the
  deprecated `crutches` library.
  """

  @byte_units [
    {1_099_511_627_776, "TB"},
    {1_073_741_824, "GB"},
    {1_048_576, "MB"},
    {1_024, "KB"}
  ]

  @doc """
  Truncates a string to the given maximum length, appending "..." if truncated.

  ## Examples

      iex> Helheim.Helpers.FormatHelpers.truncate("Hello, World!", 5)
      "He..."

      iex> Helheim.Helpers.FormatHelpers.truncate("Hi", 5)
      "Hi"

  """
  @spec truncate(String.t(), non_neg_integer(), String.t()) :: String.t()
  def truncate(string, max_length, omission \\ "...") do
    if String.length(string) > max_length do
      String.slice(string, 0, max_length - String.length(omission)) <> omission
    else
      string
    end
  end

  @doc """
  Formats a byte count into a human-readable file size string.

  ## Examples

      iex> Helheim.Helpers.FormatHelpers.human_size(1024)
      "1 KB"

      iex> Helheim.Helpers.FormatHelpers.human_size(1_048_576)
      "1 MB"

      iex> Helheim.Helpers.FormatHelpers.human_size(512)
      "512 Bytes"

  """
  @spec human_size(non_neg_integer()) :: String.t()
  def human_size(bytes) when is_integer(bytes) and bytes >= 0 do
    case Enum.find(@byte_units, fn {threshold, _} -> bytes >= threshold end) do
      {threshold, unit} ->
        value = Float.round(bytes / threshold, 2)

        if value == Float.round(value) do
          "#{trunc(value)} #{unit}"
        else
          "#{value} #{unit}"
        end

      nil ->
        "#{bytes} Bytes"
    end
  end

  @doc """
  Formats a number as a currency string.

  ## Options

    * `:unit` - currency symbol/prefix (default: "$")
    * `:separator` - decimal separator (default: ".")
    * `:delimiter` - thousands delimiter (default: ",")

  ## Examples

      iex> Helheim.Helpers.FormatHelpers.as_currency(25.0, unit: "kr. ", separator: ",", delimiter: ".")
      "kr. 25,00"

  """
  @spec as_currency(number(), keyword()) :: String.t()
  def as_currency(amount, opts \\ []) do
    unit = Keyword.get(opts, :unit, "$")
    separator = Keyword.get(opts, :separator, ".")
    delimiter = Keyword.get(opts, :delimiter, ",")

    formatted =
      amount
      |> :erlang.float_to_binary(decimals: 2)
      |> String.replace(".", separator)
      |> insert_delimiter(delimiter, separator)

    "#{unit}#{formatted}"
  end

  defp insert_delimiter(string, delimiter, separator) do
    [integer_part | decimal_parts] = String.split(string, separator)

    grouped =
      integer_part
      |> String.graphemes()
      |> Enum.reverse()
      |> Enum.chunk_every(3)
      |> Enum.map(&Enum.reverse/1)
      |> Enum.reverse()
      |> Enum.map_join(delimiter, &Enum.join/1)

    Enum.join([grouped | decimal_parts], separator)
  end
end
