defmodule Helheim.Downloader do
  def download(url, path) do
    timeout = 300_000 # 5 minutes
    do_download = fn ->
      :ok = Path.dirname(path) |> File.mkdir_p()
      {:ok, file} = File.open(path, [:write])

      opts = [stream_to: self(), follow_redirect: true]
      {:ok, %HTTPoison.AsyncResponse{id: id}} = HTTPoison.get(url, [], opts)
      result =
        receive_data(file, %{
          received_bytes: 0,
          total_bytes: 0,
          id: id
        })

      :ok = File.close(file)

      result
    end

    do_download
    |> Task.async()
    |> Task.await(timeout) # blocking a potentially very long process!
  end

  defp receive_data(file, %{id: id} = state) do
    receive do
      %HTTPoison.AsyncStatus{code: code, id: id} ->
        case code do
          200 ->
            receive_data(file, %{state | id: id})

          404 ->
            {:error, "File not found"}

          _ ->
            {:error, "Received unexpected status code #{code}"}
        end

      %HTTPoison.AsyncHeaders{headers: headers} ->
        total_bytes =
          headers
          |> Enum.find(fn {name, _} -> name == "Content-Length" end)
          |> elem(1)
          |> String.to_integer()

        receive_data(file, %{state | total_bytes: total_bytes})

      %HTTPoison.AsyncChunk{chunk: chunk, id: ^id} ->
        IO.binwrite(file, chunk)
        new_state = %{state |
          received_bytes: state.received_bytes + byte_size(chunk)
        }

        receive_data(file, new_state)

      %HTTPoison.AsyncEnd{id: ^id} ->
        if state.total_bytes === state.received_bytes do
          {:ok, state.received_bytes}
        else
          {:error, "Expected to receive #{state.total_bytes} bytes but got #{state.received_bytes}"}
        end

      %HTTPoison.Error{id: ^id, reason: {:closed, :timeout}} ->
        {:error, "Receiving a response chunk timed out"}
    end
  end
end
