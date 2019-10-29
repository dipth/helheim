defmodule Helheim.AssertCalledPatternMatching do
  use ExUnit.CaseTemplate

  using do
    quote do
      defp assert_called_with_pattern(entity, method, matcher) do
        found = :meck.history(entity)
          |> Enum.filter(fn({_, {_, m, _}, _}) -> m == method end)
          |> Enum.any?(fn({_, {_, _, args}, _result}) ->
            try do
              matcher.(args)
              true
            rescue
              MatchError -> false
            end
          end)

        case found do
          true -> true
          false ->
            calls = received_calls(entity)
            raise ExUnit.AssertionError,
              message: "Expected call but did not receive it. Calls which were received:\n\n#{calls}"
        end
      end

      defp refute_called_with_pattern(entity, method, matcher) do
        assert_raise ExUnit.AssertionError, ~r/Expected call but did not receive it/, fn ->
          assert_called_with_pattern(entity, method, matcher)
        end
      end

      defp received_calls(entity) do
        entity
        |> :meck.history()
        |> Enum.with_index()
        |> Enum.map(fn {{_, {m, f, a}, ret}, i} ->
          "#{i}. #{m}.#{f}(#{a |> Enum.map(&Kernel.inspect/1) |> Enum.join(",")}) (returned #{inspect ret})"
        end)
        |> Enum.join("\n")
      end
    end
  end
end
