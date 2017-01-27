ExUnit.start

Ecto.Adapters.SQL.Sandbox.mode(Helheim.Repo, :manual)

Application.put_env(:wallaby, :base_url, Helheim.Endpoint.url)

{:ok, _} = Application.ensure_all_started(:ex_machina)
{:ok, _} = Application.ensure_all_started(:wallaby)
