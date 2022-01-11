defmodule ElixirLGE.Window do
  @behaviour :wx_object
  use Bitwise

  @title 'Elixir OpenGL'
  @size {800, 800}


  def boid_update(boids) do
    GenServer.cast(__MODULE__, %{data: boids})
  end

  #######
  # API #
  #######
  def start_link() do
    :wx_object.start_link({:local, __MODULE__}, __MODULE__, [], [])
  end

  #################################
  # :wx_object behavior callbacks #
  #################################
  def init(config) do
    wx = :wx.new(config)
    frame = :wxFrame.new(wx, :wx_const.wx_id_any, @title, [{:size, @size}])
    :wxWindow.connect(frame, :close_window)
    :wxFrame.show(frame)

    opts = [{:size, @size}]
    gl_attrib = [{:attribList, [:wx_const.wx_gl_rgba,
                                :wx_const.wx_gl_doublebuffer,
                                :wx_const.wx_gl_min_red, 8,
                                :wx_const.wx_gl_min_green, 8,
                                :wx_const.wx_gl_min_blue, 8,
                                :wx_const.wx_gl_depth_size, 24, 0]}]
    canvas = :wxGLCanvas.new(frame, opts ++ gl_attrib)

    :wxGLCanvas.connect(canvas, :size)
    :wxWindow.reparent(canvas, frame)
    :wxGLCanvas.setCurrent(canvas)
    setup_gl(canvas)

    # Periodically send a message to trigger a redraw of the scene
    timer = :timer.send_interval(20, self(), :update)

    {frame, %{canvas: canvas, timer: timer, boids: []}}
  end

  def code_change(_, _, state) do
    {:stop, :not_implemented, state}
  end


  def handle_cast(%{data: boids}, state) do
    {:noreply, %{state | boids: boids}}
  end

  def handle_cast(msg, state) do
    IO.puts "Cast:"
    IO.inspect msg
    {:noreply, state}
  end

  def handle_call(msg, _from, state) do
    IO.puts "Call:"
    IO.inspect msg
    {:reply, :ok, state}
  end

  def handle_info(:stop, state) do
    :timer.cancel(state.timer)
    :wxGLCanvas.destroy(state.canvas)
    {:stop, :normal, state}
  end

  def handle_info(:update, state) do
    :wx.batch(fn -> render(state) end)
    {:noreply, state}
  end

  def handle_info(msg, state) do
    IO.puts "Info:"
    IO.inspect msg
    {:noreply, state}
  end

  # Example input:
  # {:wx, -2006, {:wx_ref, 35, :wxFrame, []}, [], {:wxClose, :close_window}}
  def handle_event({:wx, _, _, _, {:wxClose, :close_window}}, state) do
    {:stop, :normal, state}
  end

  def handle_event({:wx, _, _, _, {:wxSize, :size, {width, height}, _}}, state) do
    if width != 0 and height != 0 do
      # resize_gl_scene(width, height)
    end
    {:noreply, state}
  end

  def terminate(_reason, state) do
    :wxGLCanvas.destroy(state.canvas)
    :timer.cancel(state.timer)
    :timer.sleep(300)
  end


  #####################
  # Private Functions #
  #####################
  defp setup_gl(win) do
    {w, h} = :wxWindow.getClientSize(win)
    # resize_gl_scene(w, h)
    :gl.shadeModel(:gl_const.gl_smooth)
    :gl.clearColor(0.1569, 0.1647, 0.2118, 1.0)
    :gl.clearDepth(1.0)
    :gl.enable(:gl_const.gl_depth_test)
    :gl.depthFunc(:gl_const.gl_lequal)
    :gl.hint(:gl_const.gl_perspective_correction_hint, :gl_const.gl_nicest)
    :gl.pointSize(2)
    :ok
  end

  # defp resize_gl_scene(width, height) do
  #   :gl.viewport(0, 0, width, height)
  #   :gl.matrixMode(:gl_const.gl_projection)
  #   :gl.loadIdentity()
  #   :glu.perspective(45.0, width / height, 0.1, 100.0)
  #   :gl.matrixMode(:gl_const.gl_modelview)
  #   :gl.loadIdentity()
  #   :ok
  # end

  defp draw(boids) do
    :gl.clear(Bitwise.bor(:gl_const.gl_color_buffer_bit, :gl_const.gl_depth_buffer_bit))
    :gl.loadIdentity()
    :gl.begin(:gl_const.gl_points)
    :gl.color4f(0.9725, 0.9725, 0.949, 1)
    Enum.each(boids, fn boid -> draw_boid(boid) end)
    :gl.end()
    :ok
  end

  defp draw_boid(boid) do
    :gl.vertex2f(boid.pos.x, boid.pos.y)
  end

  defp render(%{canvas: canvas, boids: boids} = _state) do
    draw(boids)
    :wxGLCanvas.swapBuffers(canvas)
    :ok
  end
end


# ElixirLGE.start_link
