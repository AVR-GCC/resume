defmodule ResumeWeb.MarketSimLive.Index do
  use ResumeWeb, :live_view

  @strategies ["momentum", "mean_reversion", "volitility_breakout", "external_sentiment"]

  def mount(_params, _session, socket) do
    volume = [
      {105.5, 0, :sell},
      {105.0, 0, :sell},
      {104.5, 0, :sell},
      {104.0, 0, :sell},
      {103.5, 0, :sell},
      {103.0, 0, :sell},
      {102.5, 0, :sell},
      {102.0, 0, :sell},
      {101.5, 0, :sell},
      {101.0, 0, :sell},
      {100.5, 0, :sell},
      {100.0, 0, :buy},
      {99.5, 0, :buy},
      {99.0, 0, :buy},
      {98.5, 0, :buy},
      {98.0, 0, :buy},
      {98.0, 0, :buy},
      {97.5, 0, :buy},
      {97.0, 0, :buy},
      {96.5, 0, :buy},
      {96.0, 0, :buy},
      {95.5, 0, :buy}
    ]
    strategy_weights = Map.from_keys(@strategies, 0)
    socket = socket
      |> assign(:strategy_weights, strategy_weights)
      |> assign(:traders, [])
      |> assign(:name, "")
      |> assign(:strategies, @strategies)
      |> assign(:price_history, [100])
      |> assign(:price, 100)
      |> assign(:volumes, volume)
      |> assign(:simulation_pid, nil)
      |> assign(:recent_trades, %{})
    {:ok, socket}
  end

  # External events

  def handle_info({:trade, index, direction, price, amount}, socket) do
    trade = %{direction: direction, price: price, amount: amount}
    old_recent_trades = socket.assigns.recent_trades
    recent_trades = Map.put(old_recent_trades, index, trade)
    socket = socket
      |> assign(:recent_trades, recent_trades)

    {:noreply, socket}
  end

  def handle_info({:update_price, updated_price, display_order, _market}, socket) do
    socket = socket
      |> assign(:price, updated_price)
      |> assign(:volumes, display_order)

    {:noreply, socket}
  end

  def handle_info(:tick, socket) do
    new_price_history = [socket.assigns.price | socket.assigns.price_history]

    socket = socket
      |> assign(:price_history, new_price_history)

    {:noreply, socket}
  end

  # Internal events

  def handle_event("remove_trader", %{"index" => index_str}, socket) do
    index = String.to_integer(index_str)
    new_traders = List.delete_at(socket.assigns.traders, index)
    socket = socket
      |> assign(:traders, new_traders)
    {:noreply, socket}
  end

  def handle_event("add_trader", _values, socket) do
    strategy_weights = socket.assigns.strategy_weights
    new_strategy_weights = Map.from_keys(@strategies, 0)
    new_traders = [strategy_weights | socket.assigns.traders]
    socket = socket
      |> assign(:traders, new_traders)
      |> assign(:strategy_weights, new_strategy_weights)
      |> assign(:name, "")
    {:noreply, socket}
  end

  def handle_event("change-weight", %{"strat" => strat, "direction" => direction}, socket) do
    old_strategy_weights = socket.assigns.strategy_weights
    increment = if direction == "up" do 1 else -1 end
    strategy_weights = Map.update(old_strategy_weights, strat, 1, &(if &1 == 0 and direction == "down" do 0 else &1 + increment end))
    socket = socket
      |> assign(:strategy_weights, strategy_weights)
    {:noreply, socket}
  end

  def handle_event("toggle_simulation", _, socket) do
    case socket.assigns.simulation_pid do
      nil ->
        {:ok, pid} = Simulation.start_link(%{liveview_pid: self(), traders: socket.assigns.traders})
        socket = socket
          |> assign(:simulation_pid, pid)
        {:noreply, socket}
      pid ->
        Process.unlink(pid)
        Process.exit(pid, :shutdown)
        socket = socket
          |> assign(:simulation_pid, nil)
        {:noreply, socket}
    end
  end

  # Display components

  def get_name("momentum"), do: "Momentum"
  def get_name("mean_reversion"), do: "Mean reversion"
  def get_name("volitility_breakout"), do: "Volitility breakout"
  def get_name("external_sentiment"), do: "External sentiment"

  def new_trader(assigns) do
    ~H"""
      <.table id="traders" rows={@strategies}>
        <:col :let={strat}><div>{get_name(strat)}</div></:col>
        <:col :let={strat}><div>{@strategy_weights[strat]}</div></:col>
        <:col :let={strat}>
          <div class="flex flex-col cursor-pointer">
            <.icon name="hero-arrow-up-mini" phx-click="change-weight" phx-value-direction="up" phx-value-strat={strat} />
            <.icon name="hero-arrow-down-mini" phx-click="change-weight" phx-value-direction="down" phx-value-strat={strat} />
          </div>
        </:col>
      </.table>
      <div class="h-7" />
      <.button phx-click="add_trader" disabled={Enum.all?(@strategy_weights, fn {_, val} -> val == 0 end)}>Add</.button>
    """
  end

  def traders_list(assigns) do
    ~H"""
    <div class="flex flex-col h-80 overflow-y-auto">
      <.table id="traders" rows={Enum.with_index(@traders)}>
        <:col :for={strat <- @strategies} :let={{trader, _}} label={get_name(strat)}>
          <div class="flex justify-center">{Map.get(trader, strat)}</div>
        </:col>
        <:col :let={{_, index}}>
          <.icon name="hero-trash-mini" class="cursor-pointer" phx-click="remove_trader" phx-value-index={index} />
        </:col>
        <:col :let={{_, index}} label="Direction">
          <div :if={Map.has_key?(@recent_trades, index)}>
            <div :if={get_in(@recent_trades, [index, :direction]) == :buy}>
              <.icon name="hero-arrow-up" class="text-green-500" />
            </div>
            <div :if={get_in(@recent_trades, [index, :direction]) == :sell}>
              <.icon name="hero-arrow-down" class="text-red-500" />
            </div>
          </div>
        </:col>
        <:col :let={{_, index}} label="Price">
          <div :if={Map.has_key?(@recent_trades, index)}>
            {get_in(@recent_trades, [index, :price])}
          </div>
        </:col>
        <:col :let={{_, index}} label="Amount">
          <div :if={Map.has_key?(@recent_trades, index)}>
            {get_in(@recent_trades, [index, :amount])}
          </div>
        </:col>
      </.table>
    </div>
    """
  end

  def candles(%{lst: []} = assigns), do: ~H""
  def candles(%{lst: [_]} = assigns), do: ~H""
  def candles(%{lst: [cur, next | rest], offset: offset, variance: variance} = assigns) do
    height = 300
    val_mul = height / variance
    falling = cur > next
    color = if falling do "red" else "green" end
    normalize = fn val -> round(val * val_mul) end
    {top, bottom} = if falling do {normalize.(cur), normalize.(next)} else {normalize.(next), normalize.(cur)} end
    style = "width: 8px; background-color: #{color}; height: #{top - bottom}px; margin-bottom: #{bottom - normalize.(offset)}px; border-radius: 2px;"
    assigns = assigns
      |> assign(:style, style)
      |> assign(:lst, [next | rest])
    ~H"""
    <div style={@style} />
    <.candles {assigns} lst={@lst} />
    """
  end

  def price_history(assigns) do
    price_history = [assigns.price | assigns.price_history]
      |> Enum.take(100)

    {min, max} = Enum.min_max(price_history, fn -> {0, 1} end)
    assigns = assigns
      |> assign(:price_history, price_history)
      |> assign(:offset, min)
      |> assign(:variance, if max == min do 1 else max - min end)

    ~H"""
    <div class="flex items-end h-[300px]">
      <div class="flex flex-col justify-between h-full mr-5">
        {:erlang.float_to_binary((@offset + @variance) / 1.0, decimals: 2)}
        <div>
          {:erlang.float_to_binary(@offset + 2 * @variance / 3, decimals: 2)}
        </div>
        <div>
          {:erlang.float_to_binary(@offset + @variance / 3, decimals: 2)}
        </div>
        <div>
          {:erlang.float_to_binary(@offset / 1.0, decimals: 2)}
        </div>
      </div>
      <div class="flex justify-end items-end w-[756px]">
        <.candles lst={Enum.reverse(@price_history)} offset={@offset} variance={@variance} />
      </div>
    </div>
    """
  end

  def volumes(%{lst: []} = assigns), do: ~H""
  def volumes(%{lst: [{price, volume, buy_or_sell} | rest], scale: scale, last: last} = assigns) do
    color = if buy_or_sell == :sell do "red" else "green" end
    base_top_style = "display: flex; justify-content: flex-end; font-size: 11px; height: 14px; width: 100%;"
    addition_top_style = if buy_or_sell != last do " border-top: 1px solid #cccccc" else "" end
    top_style = base_top_style <> addition_top_style
    style = "height: 14px; background-color: #{color}; width: #{scale * volume}px;"
    assigns = assigns
      |> assign(:style, style)
      |> assign(:price, price)
      |> assign(:lst, rest)
      |> assign(:last, buy_or_sell)
      |> assign(:top_style, top_style)
    ~H"""
    <div style={@top_style}>
      <div style={@style} />
      <div style="width: 35px; display: flex; justify-content: center; align-items: center;">{@price}</div>
    </div>
    <.volumes lst={@lst} scale={@scale} last={@last} />
    """
  end

  def order_book(assigns) do
    max_volume = assigns.volumes
      |> Enum.map(fn {_, volume, _} -> volume end)
      |> Enum.max()
    scale = if max_volume && max_volume > 0, do: 360 / max_volume, else: 1
    assigns = assigns
      |> assign(:scale, scale)
      |> assign(:last, :sell)
    ~H"""
    <div class="flex flex-col items-end h-[300px] w-[420px]">
      <.volumes lst={@volumes} scale={@scale} last={@last} />
    </div>
    """
  end

    # </.page>
  def render(assigns) do
    ~H"""
      <div class="flex justify-center h-max">
        <h1>Market Simulator</h1>
      </div>

      <div class="flex">
        <div class="flex-1 flex flex-col items-center m-2 p-5 border-neutral-50 border-2">
          <h2 class="w-fit">Add Trader</h2>
          <.new_trader {assigns} />
        </div>
        <div class="flex-3 flex flex-col items-center m-2 p-5 border-neutral-50 border-2">
          <h2>Traders</h2>
          <.traders_list {assigns} />
        </div>
      </div>
      <div class="flex">
        <div class="flex flex-col items-center p-5 m-2 border-neutral-50 border-2">
          <h2>History</h2>
          <.price_history {assigns} />
        </div>
        <div class="flex flex-col items-center p-5 m-2 border-neutral-50 border-2">
          <h2>Order Book</h2>
          <.order_book {assigns} />
        </div>
      </div>
      <div class="flex justify-center w-full p-2">
        <.button
            phx-click="toggle_simulation"
            disabled={length(@traders) == 0}
        >
          {if @simulation_pid == nil do "Start" else "Stop" end}
        </.button>
      </div>
    """
  end
end
