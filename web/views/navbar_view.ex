defmodule Helheim.NavbarView do
  use Helheim.Web, :view

  def count_badge(conn, %{notifications: true, unread_messages: true} = opts),
    do: count_badge(conn, opts, conn.assigns[:notifications_count] + conn.assigns[:unread_conversations_count])
  def count_badge(conn, %{notifications: true} = opts),
    do: count_badge(conn, opts, conn.assigns[:notifications_count])
  def count_badge(conn, %{unread_messages: true} = opts),
    do: count_badge(conn, opts, conn.assigns[:unread_conversations_count])
  def count_badge(conn, opts, 0), do: count_badge(conn, opts, "")
  def count_badge(_conn, opts, count) do
    css_class = String.trim("badge badge-pill badge-danger #{opts[:class]}")
    content_tag(:span, count, class: css_class)
  end
end
