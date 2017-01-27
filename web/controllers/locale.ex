defmodule Helheim.Locale do
  def init(_opts), do: nil

  def call(conn, _opts) do
    Gettext.put_locale(Helheim.Gettext, "da")
    conn
  end
end
