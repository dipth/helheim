defmodule Altnation.Locale do
  import Plug.Conn

  def init(opts), do: nil

  def call(conn, _opts) do
    Gettext.put_locale(Altnation.Gettext, "da")
    conn
  end
end
