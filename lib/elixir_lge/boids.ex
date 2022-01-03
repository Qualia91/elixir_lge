defmodule ElixirLGE.Boids do
  use GenServer



  # Callbacks
  def start_link(pid) do
    GenServer.start_link(__MODULE__, pid, [])
  end

  @impl true
  @spec init(any) :: {:ok, %{pid: any, boids: list()}}
  def init(pid) do
    GenServer.cast(self(), :update)
    {:ok, %{boids: create_boids(100), pid: pid}}
  end

  @impl true
  def handle_call(:pop, _from, [head | tail]) do
    {:reply, head, tail}
  end

  @impl true
  def handle_cast(:update, %{boids: boids, pid: pid}) do
    updated_boids = update_boids(boids)
    send(pid, %{data: updated_boids})
    Process.sleep(1000)
    GenServer.cast(self(), :update)
    {:noreply, %{boids: updated_boids, pid: pid}}
  end

  def create_boids(amount) do
    Enum.reduce(1..amount, [], fn i, acc -> [%{index: i, x: -1 + :rand.uniform() * 2, y: -1 + :rand.uniform() * 2} | acc] end)
  end

  def update_boids(boids) do
    Enum.map(boids, fn boid -> asc(boids, boid) end)
  end

  def asc(boids, %{index: current_idx, x: current_x, y: current_y}) do

    # Enum.reduce(
    #   boids,
    #   %{index: current_idx, x: 0, y: 0},
    #   fn next_boid, boid_update ->

    #   end)

    %{index: current_idx, x: (current_x + 0.01), y: (current_y + 0.01)}

  end

end
