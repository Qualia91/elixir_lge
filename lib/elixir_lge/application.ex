defmodule ElixirLGE.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do

    {_, _, _, pid} = ElixirLGE.Window.start_link

    children = [
      # Starts a worker by calling: App.Worker.start_link(arg)
      {ElixirLGE.Boids, pid}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ElixirLGE.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
