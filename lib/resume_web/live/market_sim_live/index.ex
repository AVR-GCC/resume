defmodule ResumeWeb.MarketSimLive.Index do
  use ResumeWeb, :live_view

  @strategies [:random, :momentum, :mean_reversion, :volitility_breakout, :external_sentiment]

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

    # strategy_weights = Map.from_keys(@strategies, 0)

    socket =
      socket
      |> assign(:traders, [])
      |> assign(:name, "")
      |> assign(:strategy, :random)
      |> assign(:strategies, @strategies)
      |> assign(:price_history, [100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100])
      |> assign(:price, 100)
      |> assign(:cash, 100)
      |> assign(:market, 1)
      |> assign(:external_sentiment, 0.5)
      |> assign(:volumes, volume)
      |> assign(:simulation_pid, nil)
      |> assign(:recent_trades, [])
      |> assign(:updated_holdings, [])

    {:ok, socket}
  end

  # External events

  def handle_info({:external_sentiment, external_sentiment}, socket) do
    socket =
      socket
      |> assign(:external_sentiment, external_sentiment)

    {:noreply, socket}
  end

  def handle_info({:price_history, pid}, socket) do
    send(pid, {:price_history, [socket.assigns.price | socket.assigns.price_history]})

    {:noreply, socket}
  end

  def handle_info({:trade, index, direction, price, amount, cash, holdings}, socket) do
    trade = %{direction: direction, price: price, amount: amount}
    old_recent_trades = socket.assigns.recent_trades
    recent_trades = List.replace_at(old_recent_trades, index, trade)

    holding = %{cash: cash, holdings: holdings}
    old_updated_holdings = socket.assigns.updated_holdings
    updated_holdings = List.replace_at(old_updated_holdings, index, holding)

    socket =
      socket
      |> assign(:recent_trades, recent_trades)
      |> assign(:updated_holdings, updated_holdings)

    {:noreply, socket}
  end

  def handle_info({:update_price, updated_price, display_order, _market}, socket) do
    socket =
      socket
      |> assign(:price, updated_price)
      |> assign(:volumes, display_order)

    {:noreply, socket}
  end

  def handle_info(:tick, socket) do
    new_price_history = [socket.assigns.price | socket.assigns.price_history]

    socket =
      socket
      |> assign(:price_history, new_price_history)

    {:noreply, socket}
  end

  # Internal events

  def handle_event("remove_trader", %{"index" => index_str}, socket) do
    index = String.to_integer(index_str)
    new_traders = List.delete_at(socket.assigns.traders, index)
    new_updated_holdings = List.delete_at(socket.assigns.updated_holdings, index)
    new_recent_trades = List.delete_at(socket.assigns.recent_trades, index)

    socket =
      socket
      |> assign(:traders, new_traders)
      |> assign(:updated_holdings, new_updated_holdings)
      |> assign(:recent_trades, new_recent_trades)

    {:noreply, socket}
  end

  def handle_event("add_trader", _values, socket) do
    strategy = socket.assigns.strategy
    # strategy_weights = Map.put(Map.from_keys(@strategies, 0), strategy, 1)
    traders = socket.assigns.traders
    new_traders = [strategy | traders]
    holding = %{cash: socket.assigns.cash, holdings: %{market: socket.assigns.market}}
    old_updated_holdings = socket.assigns.updated_holdings
    updated_holdings = [holding | old_updated_holdings]
    old_recent_trades = socket.assigns.recent_trades

    recent_trades = [
      %{price: socket.assigns.price, amount: 0, direction: :buy} | old_recent_trades
    ]

    socket =
      socket
      |> assign(:traders, new_traders)
      |> assign(:recent_trades, recent_trades)
      |> assign(:updated_holdings, updated_holdings)

    {:noreply, socket}
  end

  # def handle_event("change-weight", %{"strat" => strat, "direction" => direction}, socket) do
  #   old_strategy_weights = socket.assigns.strategy_weights
  #
  #   increment =
  #     if direction == "up" do
  #       1
  #     else
  #       -1
  #     end
  #
  #   strategy_weights =
  #     Map.update(
  #       old_strategy_weights,
  #       String.to_atom(strat),
  #       1,
  #       &if &1 == 0 and direction == "down" do
  #         0
  #       else
  #         &1 + increment
  #       end
  #     )
  #
  #   socket =
  #     socket
  #     |> assign(:strategy_weights, strategy_weights)
  #
  #   {:noreply, socket}
  # end

  def handle_event("toggle_simulation", _, socket) do
    case socket.assigns.simulation_pid do
      nil ->
        traders =
          socket.assigns.traders
          |> Enum.map(fn strat ->
            Map.from_keys(@strategies, 0)
            |> Map.put(strat, 1)
          end)
          |> Enum.with_index()
          |> Enum.map(fn {strat, index} ->
            %{cash: cash, holdings: %{market: asset}} =
              Enum.at(socket.assigns.updated_holdings, index)

            {strat, cash, asset}
          end)

        {:ok, pid} =
          Simulation.start_link(%{liveview_pid: self(), traders: traders})

        socket =
          socket
          |> assign(:simulation_pid, pid)

        {:noreply, socket}

      pid ->
        Process.unlink(pid)
        Process.exit(pid, :shutdown)

        socket =
          socket
          |> assign(:simulation_pid, nil)

        {:noreply, socket}
    end
  end

  def handle_event("strategy-selected", %{"strat" => strat, "cash" => raw_cash, "asset" => raw_asset}, socket) do
    strategy = strat |> String.downcase() |> String.replace(" ", "_") |> String.to_atom()
    {cash, asset} = case {Float.parse(raw_cash), Float.parse(raw_asset)} do
      {{cash, _}, {asset, _}} -> {cash, asset}
      {_, {asset, _}} -> {socket.assigns.cash, asset}
      {{cash, _}, _} -> {cash, socket.assigns.asset}
      _ -> {socket.assigns.cash, socket.assigns.asset}
    end
    socket =
      socket
      |> assign(:strategy, strategy)
      |> assign(:cash, cash)
      |> assign(:market, asset)

    {:noreply, socket}
  end

  # Display components

  def get_name(:momentum), do: "Momentum"
  def get_name(:mean_reversion), do: "Mean reversion"
  def get_name(:volitility_breakout), do: "Volitility breakout"
  def get_name(:external_sentiment), do: "External sentiment"
  def get_name(:random), do: "Random"

  def new_trader(assigns) do
    ~H"""
    <div class="h-7" />
    <div>
      <.form for={%{}} phx-change="strategy-selected">
        <.input
          type="select"
          label="Strategy"
          id="odrop"
          name="strat"
          options={Enum.map(@strategies, fn strat -> get_name(strat) end)}
          class="w-50 ml-1 bg-gray-600 text-indigo-300 font-medium px-4 py-2 rounded border border-gray-700 hover:bg-gray-500 hover:border-gray-600 focus:outline-none focus:border-indigo-500 focus:ring-2 focus:ring-indigo-500/20 transition-all duration-200 text-sm min-w-[120px] cursor-pointer"
          value={get_name(@strategy)}
        />
        <.input
          type="text"
          label="Cash"
          id="cash-input"
          name="cash"
          class="w-50 ml-6 bg-gray-600 text-indigo-300 font-medium px-4 py-2 rounded border border-gray-700 hover:bg-gray-500 hover:border-gray-600 focus:outline-none focus:border-indigo-500 focus:ring-2 focus:ring-indigo-500/20 transition-all duration-200 text-sm min-w-[120px] cursor-pointer"
          value={@cash}
        />
        <.input
          type="text"
          label="Asset"
          id="asset-input"
          name="asset"
          class="w-50 ml-5 bg-gray-600 text-indigo-300 font-medium px-4 py-2 rounded border border-gray-700 hover:bg-gray-500 hover:border-gray-600 focus:outline-none focus:border-indigo-500 focus:ring-2 focus:ring-indigo-500/20 transition-all duration-200 text-sm min-w-[120px] cursor-pointer"
          value={@market}
        />
      </.form>
    </div>
    <%!-- <.table id="traders" rows={@strategies}> --%>
    <%!--   <:col :let={strat}> --%>
    <%!--     <div>{get_name(strat)}</div> --%>
    <%!--   </:col> --%>
    <%!--   <:col :let={strat}> --%>
    <%!--     <div>{@strategy_weights[strat]}</div> --%>
    <%!--   </:col> --%>
    <%!--   <:col :let={strat}> --%>
    <%!--     <div class="flex flex-col cursor-pointer"> --%>
    <%!--       <.icon --%>
    <%!--         name="hero-arrow-up-mini" --%>
    <%!--         phx-click="change-weight" --%>
    <%!--         phx-value-direction="up" --%>
    <%!--         phx-value-strat={strat} --%>
    <%!--       /> --%>
    <%!--       <.icon --%>
    <%!--         name="hero-arrow-down-mini" --%>
    <%!--         phx-click="change-weight" --%>
    <%!--         phx-value-direction="down" --%>
    <%!--         phx-value-strat={strat} --%>
    <%!--       /> --%>
    <%!--     </div> --%>
    <%!--   </:col> --%>
    <%!-- </.table> --%>
    <div class="h-7" />
    <.button phx-click="add_trader">
      Add
    </.button>
    """
  end

  def traders_list(assigns) do
    ~H"""
    <div class="flex flex-col h-80 overflow-y-auto">
      <.table
        id="traders"
        rows={Enum.with_index(Enum.zip([@traders, @updated_holdings, @recent_trades]))}
      >
        <%!-- <:col :let={{trader, _}} :for={strat <- @strategies} label={get_name(strat)}> --%>
        <%!--   <div class="flex justify-center">{Map.get(trader, strat)}</div> --%>
        <%!-- </:col> --%>
        <:col :let={{{strat, _, _}, _}} label="Strategy">{get_name(strat)}</:col>
        <:col :let={{_, index}}>
          <.icon
            name="hero-trash-mini"
            class="cursor-pointer"
            phx-click="remove_trader"
            phx-value-index={index}
          />
        </:col>
        <:col :let={{{_, holdings, _}, _}} label="Total">
          {Float.round(
            get_in(holdings, [:holdings, :market]) * @price + get_in(holdings, [:cash]) + 0.0,
            2
          )}
        </:col>
        <:col :let={{{_, holdings, _}, _}} label="Cash">
          {get_in(holdings, [:cash])}
        </:col>
        <:col :let={{{_, holdings, _}, _}} label="Asset">
          {get_in(holdings, [:holdings, :market])}
        </:col>
        <:col :let={{{_, _, trades}, _}} label="Direction">
          <div :if={get_in(trades, [:direction]) == :buy}>
            <.icon name="hero-arrow-up" class="text-green-500" />
          </div>
          <div :if={get_in(trades, [:direction]) == :sell}>
            <.icon name="hero-arrow-down" class="text-red-500" />
          </div>
        </:col>
        <:col :let={{{_, _, trades}, _}} label="Price">
          {get_in(trades, [:price])}
        </:col>
        <:col :let={{{_, _, trades}, _}} label="Amount">
          {get_in(trades, [:amount])}
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

    color =
      if falling do
        "red"
      else
        "green"
      end

    normalize = fn val -> round(val * val_mul) end

    {top, bottom} =
      if falling do
        {normalize.(cur), normalize.(next)}
      else
        {normalize.(next), normalize.(cur)}
      end

    style =
      "width: 8px; background-color: #{color}; height: #{top - bottom}px; margin-bottom: #{bottom - normalize.(offset)}px; border-radius: 2px;"

    assigns =
      assigns
      |> assign(:style, style)
      |> assign(:lst, [next | rest])

    ~H"""
    <div style={@style} />
    <.candles {assigns} lst={@lst} />
    """
  end

  def price_history(assigns) do
    price_history =
      [assigns.price | assigns.price_history]
      |> Enum.take(100)

    {min, max} = Enum.min_max(price_history, fn -> {0, 1} end)

    assigns =
      assigns
      |> assign(:price_history, price_history)
      |> assign(:offset, min)
      |> assign(
        :variance,
        if max == min do
          1
        else
          max - min
        end
      )

    ~H"""
    <div class="flex-3 flex items-end h-[300px]">
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
    color =
      if buy_or_sell == :sell do
        "red"
      else
        "green"
      end

    base_top_style =
      "display: flex; justify-content: flex-end; font-size: 11px; height: 14px; width: 100%;"

    addition_top_style =
      if buy_or_sell != last do
        " border-top: 1px solid #cccccc"
      else
        ""
      end

    top_style = base_top_style <> addition_top_style
    style = "height: 14px; background-color: #{color}; width: #{scale * volume}%;"

    assigns =
      assigns
      |> assign(:style, style)
      |> assign(:price, price)
      |> assign(:lst, rest)
      |> assign(:last, buy_or_sell)
      |> assign(:top_style, top_style)

    ~H"""
    <div style={@top_style}>
      <div style={@style} />
      <div style="width: 35px; display: flex; justify-content: center; align-items: center;">
        {@price}
      </div>
    </div>
    <.volumes lst={@lst} scale={@scale} last={@last} />
    """
  end

  def order_book(assigns) do
    max_volume =
      assigns.volumes
      |> Enum.map(fn {_, volume, _} -> volume end)
      |> Enum.max()

    scale = if max_volume && max_volume > 0, do: 100 / max_volume, else: 1

    assigns =
      assigns
      |> assign(:scale, scale)
      |> assign(:last, :sell)

    ~H"""
    <div class="flex flex-col items-end h-[300px] w-full">
      <.volumes lst={@volumes} scale={@scale} last={@last} />
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <.page>
      <div class="flex justify-center h-max">
        <h1>Market Simulator</h1>
        <p class="flex items-center pl-5 text-xs">External Sentiment: {@external_sentiment}</p>
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
        <div class="flex-3 flex flex-col items-center p-5 m-2 border-neutral-50 border-2">
          <h2>History</h2>
          <.price_history {assigns} />
        </div>
        <div class="flex-1 flex flex-col items-center p-5 m-2 border-neutral-50 border-2">
          <h2>Order Book</h2>
          <.order_book {assigns} />
        </div>
      </div>
      <div class="flex justify-center w-full p-2">
        <.button
          phx-click="toggle_simulation"
          disabled={length(@traders) == 0}
        >
          {if @simulation_pid == nil do
            "Start"
          else
            "Stop"
          end}
        </.button>
      </div>
    </.page>
    """
  end
end
