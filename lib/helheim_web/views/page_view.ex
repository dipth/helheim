defmodule HelheimWeb.PageView do
  use HelheimWeb, :view

  @doc """
  Splits the recent listens into up to three columns of five, each paired with
  the class that hides it on screens too narrow to fit it: one column below md,
  two below lg, three from lg up. Fewer than 15 listens simply yields fewer
  columns, and `Enum.zip/2` drops the classes it no longer needs, so an empty
  column is never rendered.
  """
  def recent_listen_columns(listens) do
    listens
    |> Enum.chunk_every(5)
    |> Enum.zip(["", "hidden-sm-down", "hidden-md-down"])
  end
end
