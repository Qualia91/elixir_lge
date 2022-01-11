defmodule ElixirLGE.Entity.LoopState do
  @enforce_keys [:system_stream, :data_map, :timestep_milli, :list_of_systems]
  defstruct [
    :system_stream,
    :data_map,
    :timestep_milli,
    :entity_id,
    :list_of_systems,
    finished_systems: [],
    current_updates: %{}
  ]
end

defmodule ElixirLGE.Entity do
  use GenServer

  def update(type, val) do
    GenServer.cast(__MODULE__, {type, val})
  end

  # Callbacks
  def start_link([timestep_milli, system_stream, data_map, entity_id]) do
    GenServer.start_link(__MODULE__, [timestep_milli, system_stream, data_map, entity_id], name: entity_id)
  end

  @impl true
  def init([timestep_milli, system_stream, data_map, entity_id]) do
    list_of_systems = Enum.sort(List.flatten(create_system(system_stream, entity_id)))
    Process.send(self(), :update, [])
    {:ok, %ElixirLGE.Entity.LoopState{system_stream: system_stream, data_map: data_map, timestep_milli: timestep_milli, entity_id: entity_id, list_of_systems: list_of_systems}}
  end

  @impl true
  def handle_call(msg, _from, loop_state) do
    {:reply, :ok, loop_state}
  end

  @impl true
  def handle_cast({:system_finished, name, new_updates}, loop_state) do
    IO.inspect name, label: "system_finished"
    IO.inspect new_updates, label: "new_updates"
    updated_finished_systems = [name | loop_state.finished_systems]
    check_all_finished(updated_finished_systems, loop_state, new_updates)
  end
  def handle_cast(msg, loop_state) do
    {:noreply, loop_state}
  end

  @impl true
  def handle_info(:update, loop_state) do
    #Process.send_after(self(), :update, loop_state.timestep_milli)
    run(loop_state)
    {:noreply, %{loop_state | current_updates: %{}}}
  end
  def handle_info(msg, loop_state) do
    {:noreply, loop_state}
  end

  defp run(loop_state) do
    GenServer.cast(:gproc.where({:n, :l, {loop_state.entity_id, loop_state.system_stream.name}}), {:run_system, loop_state.data_map, %{}})
  end

  defp create_system(%{system: system, name: system_name, init_data: init_data, children: children}, entity_id) do
    IO.inspect system_name, label: "Name"
    system.start_link(entity_id, system_name, get_children_names(children), init_data)
    [system_name | (for child <- children, do: create_system(child, entity_id))]
  end

  defp get_children_names(children) do
    Enum.reduce(children, [], fn child, acc -> [child.name | acc] end)
  end

  defp check_all_finished(updated_finished_systems, loop_state, data_map) do

    updated_updates = Map.merge(loop_state.current_updates, data_map)

    if Enum.sort(updated_finished_systems) == loop_state.list_of_systems do

      {:noreply, %{loop_state | finished_systems: [], current_updates: %{}, data_map: merge_updates(updated_updates, loop_state.data_map)}}
    else
      {:noreply, %{loop_state | finished_systems: updated_finished_systems, current_updates: updated_updates}}
    end

  end

  defp merge_updates(updated_updates, data_map) do
    IO.inspect updated_updates, label: "UpdateLoopFinished"
    data_map
  end

end
