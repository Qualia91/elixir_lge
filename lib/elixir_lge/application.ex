
defmodule ElixirLGE.SystemStream do
  @enforce_keys [:system, :name]
  defstruct [
    :name,
    :system,
    init_data: %{},
    children: []
  ]
end

defmodule VulkanRenderer do
  @on_load :load_nifs

  def load_nifs do
    :erlang.load_nif('./dll/vulkan_renderer', 0)
  end

  def create_renderer(_width, _height) do
    raise "NIF create_renderer/2 not implemented"
  end

  def run(_renderer, _device_index) do
    raise "NIF run/2 not implemented"
  end
end

defmodule ElixirLGE.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do

    # IO.inspect Test.add(1,2), label: "This was calculated in the dll"
    # {:ok, renderer} = VulkanRenderer.create_renderer(800, 600)
    # IO.inspect VulkanRenderer.run(renderer, 0), label: "Renderer Return Error Code: "

    {_, _, _, pid} = ElixirLGE.Window.start_link
    ElixirLGE.Gui.start_link([])

    system_stream = %ElixirLGE.SystemStream{
      name: :systemA,
      system: ElixirLGE.System,
      children: [
        %ElixirLGE.SystemStream{
          name: :systemB,
          system: ElixirLGE.System
        },
        %ElixirLGE.SystemStream{
          name: :systemC,
          system: ElixirLGE.System,
          children: [
            %ElixirLGE.SystemStream{
              name: :systemD,
              system: ElixirLGE.System
            },
            %ElixirLGE.SystemStream{
              name: :systemE,
              system: ElixirLGE.System
            }
          ]
        }
      ]
    }

    children = [
      # Starts a worker by calling: App.Worker.start_link(arg)
      {ElixirLGE.Boids, ElixirLGE.Window},
      %{id: :entity_1, start: {ElixirLGE.Entity, :start_link, [[20, system_stream, [], :entity_1]]}},
      %{id: :entity_2, start: {ElixirLGE.Entity, :start_link, [[20, system_stream, [], :entity_2]]}}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ElixirLGE.Supervisor]
    Supervisor.start_link(children, opts)
  end

end
