defmodule ElixirLGE.Boids do
  use GenServer

  # Callbacks

  def start_link(pid) do
    GenServer.start_link(__MODULE__, pid, [])
  end

  @impl true
  @spec init(any) :: {:ok, %{pid: any, x: 0, y: 0}}
  def init(pid) do
    GenServer.cast(self(), :update)
    {:ok, %{x: 0, y: 0, pid: pid}}
  end

  @impl true
  def handle_call(:pop, _from, [head | tail]) do
    {:reply, head, tail}
  end

  @impl true
  def handle_cast(:update, %{x: x, y: y, pid: pid}) do
    send(pid, %{x: x, y: y})
    Process.sleep(1000)
    GenServer.cast(self(), :update)
    {:noreply, %{x: (x + 0.01), y: (y + 0.01), pid: pid}}
  end
end
