defmodule ElixirLGE.Gui do
  @behaviour :wx_object
  use Bitwise

  @title 'Gui'
  @size {800, 800}

  #######
  # API #
  #######
  def start_link() do
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

    label = :wxTextCtrl.new(frame, :wx_const.wx_id_any, [{:value, "0"}])

    :wxSizer.add(main_sizer, label, [{:flag, :wx_const.wx_all ||| :wx_const.wx_expand}, {:border, 5}])

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
    :timer.cancel(state.timer)
    {:stop, :normal, state}
  end

  def handle_event({:wx, _, _, _, {:wxClose, :close_window}}, state) do
    {:stop, :normal, state}
  end

  def terminate(_reason, state) do
    :timer.cancel(state.timer)
    :timer.sleep(300)
  end

end
