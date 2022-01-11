
defmodule CSystem do
  @on_load :load_nifs

  def load_nifs do
    :erlang.load_nif('./dll/csystem', 0)
  end

  def run(_a, _b) do
    raise "NIF run/2 not implemented"
  end
end

defmodule ElixirLGE.System.LoopState do
  @enforce_keys [:entity_id, :system_name, :init_data]
  defstruct [
    :system_name,
    :entity_id,
    :init_data,
    children: []
  ]
end

defmodule ElixirLGE.System do
  use GenServer

  # Callbacks
  def start_link(entity_id, name, children, init_data) do
    GenServer.start_link(__MODULE__, [entity_id, name, children, init_data], name: {:via, :gproc, {:n, :l, {entity_id, name}}})
  end

  @impl true
  def init([entity_id, system_name, children, init_data]) do
    {:ok, %ElixirLGE.System.LoopState{entity_id: entity_id, system_name: system_name, children: children, init_data: init_data}}
  end

  @impl true
  def handle_call(msg, _from, loop_state) do
    {:reply, :ok, loop_state}
  end

  @impl true
  def handle_cast({:run_system, data_map, continuation_data}, loop_state) do
    IO.inspect loop_state, label: "System running"
    IO.inspect loop_state.init_data, label: "init_data"
    IO.inspect data_map, label: "data_map"
    IO.inspect continuation_data, label: "continuation_data"
    {ret_a, ret_b} = CSystem.run(1,2)
    GenServer.cast(loop_state.entity_id, {:system_finished, loop_state.system_name, %{system_data: ret_a}})
    for child <- loop_state.children, do: GenServer.cast(:gproc.where({:n, :l, {loop_state.entity_id, child}}), {:run_system, data_map, %{system_cont_data: ret_b}})
    {:noreply, loop_state}
  end
  def handle_cast(msg, loop_state) do
    {:noreply, loop_state}
  end

  @impl true
  def handle_info(msg, loop_state) do
    {:noreply, loop_state}
  end

end
