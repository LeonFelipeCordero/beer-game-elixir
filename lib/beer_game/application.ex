defmodule BeerGame.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      BeerGame.Repo,
      # Start the Telemetry supervisor
      BeerGameWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: BeerGame.PubSub},
      # Start the Endpoint (http/https)
      BeerGameWeb.Endpoint,
      # Start a worker by calling: BeerGame.Worker.start_link(arg)
      # {BeerGame.Worker, arg}
      BeerGame.SateRunner,
      BeerGame.OrderRunner,
      BeerGame.FactoryRunner
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BeerGame.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    BeerGameWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
