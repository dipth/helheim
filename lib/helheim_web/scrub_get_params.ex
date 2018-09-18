defmodule HelheimWeb.ScrubGetParams do
  def scrub_get_params(conn, _opts) do
     params = conn.params |> Enum.reduce(%{}, &scrub/2 )
     %{conn | params: params}
  end

  defp scrub({k, ""}, acc) do
    Map.put(acc, k, nil)
  end
  defp scrub({k, v}, acc) do
    Map.put(acc, k, v)
  end
end
