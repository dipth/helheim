defmodule Helheim.TimeHelpers do
  def lt(timestamp, format) do
    {:ok, string} = timestamp
      |> Calendar.DateTime.shift_zone!("Europe/Copenhagen")
      |> Timex.lformat(format, "da")
    string
  end
end
