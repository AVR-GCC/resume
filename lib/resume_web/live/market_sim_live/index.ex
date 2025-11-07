defmodule ResumeWeb.MarketSimLive.Index do
  use ResumeWeb, :live_view

  @strategies ["momentum", "mean_reversion", "volitility_breakout", "external_sentiment"]

  def mount(_params, _session, socket) do
    price_history = [0.67, 0.68, 0.01, 0.18, 0.67, 0.32, 0.71, 0.82, 0.52, 1.0, 0.6, 0.81, 0.99, 0.57, 0.6, 0.24, 0.19, 0.1, 0.84, 0.11, 0.48, 0.83, 0.91, 0.51, 0.95, 0.95, 0.33, 0.01, 0.63, 0.87, 0.76, 0.16, 0.71, 0.67, 0.79, 0.69, 0.51, 0.35, 0.53, 0.43, 0.13, 0.69, 0.25, 0.11, 0.22, 0.62, 0.93, 0.18, 0.32, 0.18, 0.67, 0.68, 0.01, 0.18, 0.67, 0.32, 0.71, 0.82, 0.52, 1.0, 0.6, 0.81, 0.99, 0.57, 0.6, 0.24, 0.19, 0.1, 0.84, 0.11, 0.48, 0.83, 0.91, 0.51, 0.95, 0.95, 0.33, 0.01, 0.63, 0.87, 0.76, 0.16, 0.71, 0.67, 0.79, 0.69, 0.51, 0.35, 0.53, 0.43, 0.13, 0.69, 0.25, 0.11, 0.22, 0.62, 0.93, 0.18, 0.32, 0.18, 0.67, 0.68, 0.01, 0.18, 0.67, 0.32, 0.71, 0.82, 0.52, 1.0, 0.6, 0.81, 0.99, 0.57, 0.6, 0.24, 0.19, 0.1, 0.84, 0.11, 0.48, 0.83, 0.91, 0.51, 0.95, 0.95, 0.33, 0.01, 0.63, 0.87, 0.76, 0.16, 0.71, 0.67, 0.79, 0.69, 0.51, 0.35, 0.53, 0.43, 0.13, 0.69, 0.25, 0.11, 0.22, 0.62, 0.93, 0.18, 0.32, 0.18, 0.67, 0.68, 0.01, 0.18, 0.67, 0.32, 0.71, 0.82, 0.52, 1.0, 0.6, 0.81, 0.99, 0.57, 0.6, 0.24, 0.19, 0.1, 0.84, 0.11, 0.48, 0.83, 0.91, 0.51, 0.95, 0.95, 0.33, 0.01, 0.63, 0.87, 0.76, 0.16, 0.71, 0.67, 0.79, 0.69, 0.51, 0.35, 0.53, 0.43, 0.13, 0.69, 0.25, 0.11, 0.22, 0.62, 0.93, 0.18, 0.32, 0.18]
    strategy_weights = Map.from_keys(@strategies, 0)
    socket = socket
      |> assign(:strategy_weights, strategy_weights)
      |> assign(:traders, [])
      |> assign(:name, "")
      |> assign(:strategies, @strategies)
      |> assign(:price_history, price_history)
    {:ok, socket}
  end

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
    IO.inspect(new_traders)
    socket =
      socket
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
    <div class="flex flex-col h-96 overflow-y-auto">
      <.table id="traders" rows={Enum.with_index(@traders)}>
        <:col :for={strat <- @strategies} :let={{trader, _}} label={get_name(strat)}>
          <div class="flex justify-center">{Map.get(trader, strat)}</div>
        </:col>
        <:col :let={{_, index}}><.icon name="hero-trash-mini" class="cursor-pointer" phx-click="remove_trader" phx-value-index={index} /></:col>
      </.table>
    </div>
    """
  end

  def candles(%{lst: []} = assigns), do: ~H""
  def candles(%{lst: [_]} = assigns), do: ~H""
  def candles(%{lst: [cur, next | rest], offset: offset, variance: variance } = assigns) do
    height = 300
    val_mul = height / variance
    falling = cur > next
    color = if falling do "red" else "green" end
    {top, bottom} = if falling do {round(cur * val_mul), round(next * val_mul)} else {round(next * val_mul), round(cur * val_mul)} end
    style = "width: 8px; background-color: #{color}; height: #{top - bottom}px; margin-bottom: #{bottom - offset * val_mul}px; border-radius: 2px;"
    assigns = assigns
      |> assign(:style, style)
      |> assign(:lst, [next | rest])
    ~H"""
    <div style={@style} />
    <.candles {assigns} lst={@lst} />
    """
  end

  def price_history(assigns) do
    price_history = assigns.price_history
      |> Enum.take(100)

    {min, max} = Enum.min_max(price_history, fn -> {0, 1} end)
    assigns = assigns
      |> assign(:price_history, price_history)
      |> assign(:offset, min)
      |> assign(:variance, max - min)

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
      <div class="flex items-end w-[728px]">
        <.candles lst={@price_history} offset={@offset} variance={@variance} />
      </div>
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
      </div>
    """
  end
end
