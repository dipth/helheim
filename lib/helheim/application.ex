defmodule Helheim.Application do
  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    # Define workers and child supervisors to be supervised
    children = [
      # Start the PubSub system
      {Phoenix.PubSub, name: Helheim.PubSub},
      # Start the Ecto repository
      Helheim.Repo,
      # Start the Telemetry
      HelheimWeb.Telemetry,
      # Start the endpoint when the application starts
      HelheimWeb.Endpoint,
      # Start the presence
      HelheimWeb.Presence,
      # Start your own worker by calling: Helheim.Worker.start_link(arg1, arg2, arg3)
      # worker(Helheim.Worker, [arg1, arg2, arg3]),
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Helheim.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    HelheimWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
