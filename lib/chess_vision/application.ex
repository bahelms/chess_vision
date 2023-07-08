defmodule ChessVision.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      ChessVisionWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: ChessVision.PubSub},
      # Start Finch
      {Finch, name: ChessVision.Finch},
      # Start the Endpoint (http/https)
      ChessVisionWeb.Endpoint
      # Start a worker by calling: ChessVision.Worker.start_link(arg)
      # {ChessVision.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ChessVision.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ChessVisionWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
