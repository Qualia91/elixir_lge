
defmodule Vec2 do
  defstruct x: 0, y: 0
end

defmodule Boid do
  @enforce_keys [:boidId]
  defstruct [:boidId, pos: %Vec2{}, vel: %Vec2{}]
end

defmodule LoopState do
  @enforce_keys [:pid]
  defstruct [
    :pid,
    length_away_group_sqr: 0.005,
    length_away_min_sqr: 0.001,
    timestep: 0.033,
    timestep_milli: 33,
    anti_collide_scale: 0.5,
    velocity_match_scale: 0.1,
    perceived_center_scale: 0.1,
    bound_scale: 1.9,
    boids: []
  ]
end

defmodule ElixirLGE.Boids do
  use GenServer

  # Callbacks
  def start_link(pid) do
    GenServer.start_link(__MODULE__, pid, [])
  end

  @impl true
  def init(pid) do
    GenServer.cast(self(), :update)
    {:ok, %LoopState{boids: create_boids(100), pid: pid}}
  end

  @impl true
  def handle_call(:pop, _from, [head | tail]) do
    {:reply, head, tail}
  end

  @impl true
  def handle_cast(:update, loop_state) do
    updated_boids = update_boids(loop_state)
    send(loop_state.pid, %{data: updated_boids})
    Process.sleep(loop_state.timestep_milli)
    GenServer.cast(self(), :update)
    {:noreply, %{loop_state | boids: updated_boids}}
  end

  def create_boids(amount) do
    Enum.reduce(1..amount, [], fn i, acc -> [%Boid{boidId: i, pos: %Vec2{x: -1 + :rand.uniform() * 2, y: -1 + :rand.uniform() * 2}, vel: %Vec2{x: -1 + :rand.uniform() * 2, y: -1 + :rand.uniform() * 2}} | acc] end)
  end

  def update_boids(loop_state) do
    Enum.map(loop_state.boids, fn boid ->
      Task.async(fn ->
        update_pos(loop_state.timestep, asc(loop_state, boid)) |>
        pos_bound(loop_state.bound_scale) |>
        vel_bound
      end)
    end) |> Enum.map(&Task.await/1)
  end

  # def update_boids(loop_state) do
  #   Enum.map(loop_state.boids, fn boid ->
  #       update_pos(loop_state.timestep, asc(loop_state, boid)) |>
  #       pos_bound(loop_state.bound_scale) |>
  #       vel_bound
  #   end)
  # end

  def asc(loop_state, boid) do

    boid_update_obj = Enum.reduce(
      loop_state.boids,
      %{sumAlign: %Vec2{}, sumCoh: %Vec2{}, sumSep: %Vec2{}, sumBound: %Vec2{}, num: 0},
      fn next_boid, %{sumAlign: sumAlign, sumCoh: sumCoh, sumSep: sumSep, num: num} = upd_data ->

        # Check its not the current boid
        if next_boid.boidId == boid.boidId do

          %{upd_data | sumAlign: sumAlign, sumCoh: sumCoh, sumSep: sumSep}

        else

          update_wide_group(upd_data, boid, next_boid, sumAlign, sumCoh, num, loop_state.length_away_group_sqr) |>
          update_small_group(boid, next_boid, sumSep, loop_state.length_away_min_sqr, loop_state.anti_collide_scale)

        end

      end)

      if boid_update_obj.num > 0 do
        inv_size = 1/boid_update_obj.num
        updated_align_vec = vecMulti(vecSub(vecMulti(boid_update_obj.sumAlign, inv_size), boid.vel), loop_state.velocity_match_scale)
        updated_coh_vec = vecMulti(vecSub(vecMulti(boid_update_obj.sumCoh, inv_size), boid.pos), loop_state.perceived_center_scale)
        %{boid | vel: sum_list([updated_align_vec, updated_coh_vec, boid_update_obj.sumSep, boid.vel, boid_update_obj.sumBound])}
      else
        %{boid | vel: sum_list([boid_update_obj.sumSep, boid.vel, boid_update_obj.sumBound])}
      end


  end

  def vel_bound(boid) do
    vec_length = vecLengthSqr(boid.vel)
    cond do
      vec_length > 1 ->
        %{boid | vel: vecMulti(vecNormalise(boid.vel), 1)}
      vec_length < 0.5 ->
        %{boid | vel: vecMulti(vecNormalise(boid.vel), 0.5)}
      true ->
        boid
    end
  end

  def pos_bound(boid, bound_scale) do
    var = 0.9
    a = if boid.pos.x < -var do
      %Vec2{x: abs(boid.vel.x) * bound_scale, y: 0}
    else
      %Vec2{x: 0, y: 0}
    end
    b = if boid.pos.x > var do
      %Vec2{x: -abs(boid.vel.x) * bound_scale, y: 0}
    else
      %Vec2{x: 0, y: 0}
    end
    c = if boid.pos.y < -var do
      %Vec2{x: 0, y: abs(boid.vel.y) * bound_scale}
    else
      %Vec2{x: 0, y: 0}
    end
    d = if boid.pos.y > var do
      %Vec2{x: 0, y: -abs(boid.vel.y) * bound_scale}
    else
      %Vec2{x: 0, y: 0}
    end
    %{boid | vel: sum_list([boid.vel,a,b,c,d])}
  end

  def update_wide_group(upd_data, boid, next_boid, sumAlign, sumCoh, num, length_away_group_sqr) do
    if (vecLengthSqr(vecSub(boid.pos, next_boid.pos)) < length_away_group_sqr) do
      %{
        upd_data |
        sumAlign: vecAdd(sumAlign, next_boid.vel),
        sumCoh: vecAdd(sumCoh, next_boid.pos),
        num: num + 1
      }
    else
      upd_data
    end
  end

  def update_small_group(upd_data, boid, next_boid, sumSep, length_away_min_sqr, anti_collide_scale) do
    if (vecLengthSqr(vecSub(boid.pos, next_boid.pos)) < length_away_min_sqr) do
      %{
        upd_data |
        sumSep: vecMulti(vecSub(sumSep, vecSub(next_boid.pos, boid.pos)), anti_collide_scale),
      }
    else
      upd_data
    end
  end

  def update_pos(timestep, boid) do
    %{boid | pos: vecAdd(boid.pos, vecMulti(boid.vel, timestep))}
  end

  def sum_list(list) do
    Enum.reduce(list, &(vecAdd(&1, &2)))
  end

  def vecNormalise(vec) do
    vecMulti(vec, :math.sqrt(1/vecLengthSqr(vec)))
  end

  def vecLengthSqr(%Vec2{x: x, y: y}) do
    (x * x) + (y * y)
  end

  def vecAdd(%Vec2{x: x1, y: y1}, %Vec2{x: x2, y: y2}) do
    %Vec2{x: x1 + x2, y: y1 + y2}
  end

  def vecSub(%Vec2{x: x1, y: y1}, %Vec2{x: x2, y: y2}) do
    %Vec2{x: (x1 - x2), y: (y1 - y2)}
  end

  def vecMulti(%Vec2{x: x1, y: y1}, %Vec2{x: x2, y: y2}) do
    %Vec2{x: x1 * x2, y: y1 * y2}
  end

  def vecMulti(%Vec2{x: x1, y: y1}, number) do
    %Vec2{x: x1 * number, y: y1 * number}
  end

end
