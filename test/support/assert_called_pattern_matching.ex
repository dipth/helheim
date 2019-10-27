defmodule Helheim.AssertCalledPatternMatching do
  use ExUnit.CaseTemplate

  using do
    quote do
      defp assert_called_with_pattern(entity, method, matcher) do
        {_pid, {_entity, _method, args}, _result} = Enum.find(
          :meck.history(entity),
          fn({_, {_, m, _}, _}) -> m == method end
        )

        assert matcher.(args)
      rescue
        MatchError ->
          calls = entity
                |> :meck.history()
                |> Enum.with_index()
                |> Enum.map(fn {{_, {m, f, a}, ret}, i} ->
                  "#{i}. #{m}.#{f}(#{a |> Enum.map(&Kernel.inspect/1) |> Enum.join(",")}) (returned #{inspect ret})"
                end)
                |> Enum.join("\n")
          raise ExUnit.AssertionError,
            message: "Expected call but did not receive it. Calls which were received:\n\n#{calls}"
      end
    end
  end
end
