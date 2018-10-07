defmodule HelheimWeb.Locale do
  def init(_opts), do: nil

  def call(conn, _opts) do
    Gettext.put_locale(HelheimWeb.Gettext, "da")
    conn
  end
end
