defmodule ElixirLGE.Gui do
  @behaviour :wx_object
  use Bitwise

  @title 'Gui'
  @size {800, 800}

  #######
  # API #
  #######
  def start_link(config) do
    :wx_object.start_link(__MODULE__, [], [])
  end

  #################################
  # :wx_object behavior callbacks #
  #################################
  def init(config) do
    wx = :wx.new(config)
    frame = :wxFrame.new(wx, :wx_const.wx_id_any, @title, [{:size, @size}])
    :wxWindow.connect(frame, :close_window)

    main_sizer = :wxBoxSizer.new(:wx_const.wx_vertical)

    # length_away_group_sqr: 0.005,
    # length_away_min_sqr: 0.001,
    # timestep: 0.033,
    # timestep_milli: 33,
    # anti_collide_scale: 0.5,
    # velocity_match_scale: 0.1,
    # perceived_center_scale: 0.1,
    # bound_scale: 1.9,

    create_slider_editor(frame, main_sizer, 10, 1, 1000, 100, :anti_collide_scale)
    create_slider_editor(frame, main_sizer, 10, 1, 1000, 100, :velocity_match_scale)
    create_slider_editor(frame, main_sizer, 10, 1, 1000, 100, :perceived_center_scale)
    create_slider_editor(frame, main_sizer, 10, 1, 1000, 100, :bound_scale)
    create_slider_editor(frame, main_sizer, 5, 1, 1000, 1000, :length_away_group_sqr)
    create_slider_editor(frame, main_sizer, 1, 1, 1000, 1000, :length_away_min_sqr)

    # timestamp
    # anti_collide_scale: 0.5,
    # velocity_match_scale: 0.1,
    # perceived_center_scale: 0.1,

    :wxWindow.setSizer(frame, main_sizer)
    :wxFrame.show(frame)

    {frame, %{}}
  end

  def code_change(_, _, state) do
    {:stop, :not_implemented, state}
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
    {:stop, :normal, state}
  end

  def handle_event({:wx, _, _, _, {:wxClose, :close_window}}, state) do
    {:stop, :normal, state}
  end

  def terminate(_reason, _state) do
    :timer.sleep(300)
  end

  def handle_slider_event({:wx, _, {:wx_ref, _, :wxSlider, []}, %{label: label, type: type, div: div}, {:wxCommand, :command_slider_updated, [], value, _}}, _) do
    ElixirLGE.Boids.update(type, value/div)
    :wxStaticText.setLabel(label, (value/div) |> Float.round(4) |> Float.to_string)
  end

  defp create_slider_editor(frame, main_sizer, start_val, min, max, div, type) do
    name = :wxStaticText.new(frame, :wx_const.wx_id_any, Atom.to_string(type))
    label = :wxStaticText.new(frame, :wx_const.wx_id_any, start_val/div |> Float.round(4) |> Float.to_string)
    slider = :wxSlider.new(frame, :wx_const.wx_id_any, start_val, min, max)

    :wxSlider.connect(slider, :command_slider_updated,
        [{:callback, &ElixirLGE.Gui.handle_slider_event/2},
         {:userData, %{label: label, type: type, div: div}}
        ])

    :wxSizer.add(main_sizer, name, [{:flag, :wx_const.wx_all ||| :wx_const.wx_expand}, {:border, 5}])
    :wxSizer.add(main_sizer, label, [{:flag, :wx_const.wx_all ||| :wx_const.wx_expand}, {:border, 5}])
    :wxSizer.add(main_sizer, slider, [{:flag, :wx_const.wx_all ||| :wx_const.wx_expand}, {:border, 5}])
  end
end
