defmodule Trader do
  use GenServer

  defstruct [:id, :strategy, :liveview_pid, :cash, :assets, :trades_count]

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init(args) do
    %{
      strategy: strategy,
      id: id,
      liveview_pid: liveview_pid,
      cash: cash,
      asset_holdings: asset_holdings
    } = args

    assets =
      asset_holdings
      |> Enum.map(fn {key, value} -> {key, %{position: 0.0, holding: value}} end)
      |> Enum.into(%{})

    state = %__MODULE__{
      id: id,
      strategy: strategy,
      liveview_pid: liveview_pid,
      cash: %{
        holding: cash,
        position: 0.0
      },
      assets: assets,
      trades_count: 0
    }

    schedule_decision()
    {:ok, state}
  end

  def handle_info({:order_fulfilled, :buy, asset, amount, price}, state) do
    update_asset = fn %{holding: holding, position: position} ->
      %{holding: holding + amount, position: position}
    end

    money = amount * price

    update_cash = fn %{holding: holding, position: position} ->
      %{holding: holding, position: position - money}
    end

    new_state =
      state
      |> Map.update!(:assets, fn assets ->
        Map.update(assets, asset, %{holding: 0, position: 0}, update_asset)
      end)
      |> Map.update!(:cash, update_cash)

    {:noreply, new_state}
  end

  def handle_info({:order_fulfilled, :sell, asset, amount, price}, state) do
    money = amount * price

    update_cash = fn %{holding: holding, position: position} ->
      %{holding: holding + money, position: position}
    end

    update_asset = fn %{holding: holding, position: position} ->
      %{holding: holding, position: position - amount}
    end

    new_state =
      state
      |> Map.update!(:assets, fn assets ->
        Map.update(assets, asset, %{holding: 0, position: 0}, update_asset)
      end)
      |> Map.update!(:cash, update_cash)

    {:noreply, new_state}
  end

  def handle_info(:make_decision, state) do
    new_state = make_decision(state)
    schedule_decision()
    {:noreply, new_state}
  end

  def schedule_decision() do
    milis = :rand.uniform(2500) + 500
    Process.send_after(self(), :make_decision, milis)
  end

  def make_decision(state) do
    asset = :market
    current_price = OrderBook.get_price(asset)
    %{position: _asset_position, holding: asset_holding} = state.assets |> get_in([asset])
    %{position: _cash_position, holding: cash_holding} = state.cash
    bullishness = get_sentiment(state.strategy, state.liveview_pid)
    is_buy = bullishness > 0.5

    intensity = abs(bullishness * 2 - 1)

    if intensity > 0.3 do
      updated_intensity = (intensity - 0.3) / 7

      total_holding =
        if is_buy do
          cash_holding / current_price
        else
          asset_holding
        end

      amount = Float.round(total_holding * updated_intensity, 2)

      price_param =
        if is_buy do
          1 + updated_intensity
        else
          1 - updated_intensity
        end

      price = Float.round(current_price * price_param, 2)

      if is_buy do
        buy(state, asset, amount, price)
      else
        sell(state, asset, amount, price)
      end
    else
      state
    end
  end

  def buy(state, asset, amount, price) do
    OrderBook.add_order(self(), asset, :buy, amount, price)
    send(state.liveview_pid, {:trade, state.id, :buy, price, amount})
    money = amount * price

    update_cash = fn %{holding: holding, position: position} ->
      %{holding: holding - money, position: position + money}
    end

    state |> Map.update!(:cash, update_cash)
  end

  def sell(state, asset, amount, price) do
    OrderBook.add_order(self(), asset, :sell, amount, price)
    send(state.liveview_pid, {:trade, state.id, :sell, price, amount})

    update_asset = fn %{holding: holding, position: position} ->
      %{holding: holding - amount, position: position + amount}
    end

    state
    |> Map.update!(:assets, fn assets ->
      Map.update(assets, asset, %{holding: 0, position: 0}, update_asset)
    end)
  end

  def get_sentiment(strategies, liveview_pid) do
    total_weight =
      strategies
      |> Map.values()
      |> Enum.sum()

    bullishness =
      strategies
      |> Enum.map(fn {key, val} ->
        if val > 0 do
          sentiment = strategy_sentiment(key, liveview_pid)
          val * IO.inspect(sentiment, label: key)
        else
          0
        end
      end)
      |> Enum.sum()

    bullishness / total_weight
  end

  defp get_price_history(liveview_pid) do
    send(liveview_pid, {:price_history, self()})

    receive do
      {:price_history, value} -> value
    end
  end

  defp sigmoid(x) do
    cond do
      x > 700 -> 1
      x < -700 -> 0
      true -> 1 / (1 + :math.exp(-x))
    end
  end

  def strategy_sentiment(:random, _liveview_pid) do
    :rand.uniform()
  end

  def strategy_sentiment(:momentum, liveview_pid) do
    price_history = get_price_history(liveview_pid)
    num_prices = length(price_history)

    if num_prices == 0 do
      0.5
    else
      index_to_compare = Enum.min([num_prices, 10])
      old_price = Enum.at(price_history, index_to_compare - 1)
      cur_price = List.first(price_history)
      min = Enum.min([cur_price, old_price])
      proportional_diff = (cur_price - old_price) / min
      sigmoid(proportional_diff * 100)
    end
  end

  def strategy_sentiment(:mean_reversion, liveview_pid) do
    price_history = get_price_history(liveview_pid)
    num_prices = length(price_history)
    use_index = Enum.min([num_prices, 20])

    avg =
      price_history
      |> Enum.take(use_index)
      |> Enum.sum()
      |> Kernel./(use_index)

    cur_price = List.first(price_history)
    proportional_diff = (avg - cur_price) / avg * (use_index / 0.2)
    sigmoid(proportional_diff)
  end

  def strategy_sentiment(:volitility_breakout, liveview_pid) do
    price_history = get_price_history(liveview_pid)
    num_prices = length(price_history)
    use_index = Enum.min([num_prices, 20])

    price_history
    |> Enum.take(use_index)

    avg =
      price_history
      |> Enum.take(use_index)
      |> Enum.sum()
      |> Kernel./(use_index)

    variance_sqrd =
      price_history
      |> Enum.map(&:math.pow(avg - &1, 2))
      |> Enum.sum()
      |> Kernel./(num_prices * 1000)

    output = Enum.random([-1, 1]) * variance_sqrd
    sigmoid(output)
  end

  def strategy_sentiment(:external_sentiment, _liveview_pid) do
    (ExternalSentimentGetter.get_sentiment() * 3 + :rand.uniform()) / 4
  end
end
