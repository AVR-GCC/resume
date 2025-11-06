defmodule ResumeWeb.MarketSimLive.Index do
  use ResumeWeb, :live_view

  @strategies ["momentum", "mean_reversion", "volitility_breakout", "external_sentiment"]

  def mount(_params, _session, socket) do
    strategy_weights = Map.from_keys(@strategies, 0)
    socket =
      socket
      |> assign(:strategy_weights, strategy_weights)
      |> assign(:traders, [])
      |> assign(:name, "")
      |> assign(:strategies, @strategies)
    {:ok, socket}
  end

  def handle_event("remove_trader", %{"index" => index_str}, socket) do
    index = String.to_integer(index_str)
    new_traders = List.delete_at(socket.assigns.traders, index)
    socket =
      socket
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
    socket =
      socket
      |> assign(:strategy_weights, strategy_weights)
    {:noreply, socket}
  end

  def get_name("momentum"), do: "Momentum"
  def get_name("mean_reversion"), do: "Mean reversion"
  def get_name("volitility_breakout"), do: "Volitility breakout"
  def get_name("external_sentiment"), do: "External sentiment"

    # </.page>
  def render(assigns) do
    ~H"""
      <div class="flex justify-center h-max">
        <h1>Market Simulator</h1>
      </div>

      <div class="flex p-2 z-10">
        <div class="flex flex-col items-center p-5 w-80 border-neutral-50 border-2">
          <h2 class="w-fit">Add Trader</h2>
          <.table id="traders" rows={@strategies}>
            <:col :let={strat}><div>{get_name(strat)}</div></:col>
            <:col :let={strat}><div>{@strategy_weights[strat]}</div></:col>
            <:col :let={strat}>
              <div class="flex flex-col cursor-pointer">
                <.icon name="hero-arrow-up-mini" phx-click="change-weight" phx-value-direction="up" phx-value-strat={strat} />
                <.icon name="hero-arrow-down-mini" phx-click="change-weight" phx-value-direction="down" phx-value-strat={strat}  />
              </div>
            </:col>
          </.table>
          <div class="h-7" />
          <.button phx-click="add_trader" disabled={Enum.all?(@strategy_weights, fn {_, val} -> val == 0 end)}>Add</.button>
        </div>
        <div class="flex flex-col items-center p-5 h-96 border-neutral-50 border-2">
          <h2>Traders</h2>
          <div class="flex flex-col">
            <.table id="traders" rows={Enum.with_index(@traders)}>
              <:col :for={strat <- @strategies} :let={{trader, _}} label={get_name(strat)}>
                <div class="flex justify-center">{Map.get(trader, strat)}</div>
              </:col>
              <:col :let={{_, index}}><.icon name="hero-trash-mini" class="cursor-pointer" phx-click="remove_trader" phx-value-index={index} /></:col>
            </.table>
          </div>
        </div>
      </div>
    """
  end
end
