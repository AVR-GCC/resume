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
      asset_holdings: asset_holdings,
    } = args
    assets = asset_holdings
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
    update_asset = fn %{holding: holding, position: position} -> %{holding: holding + amount, position: position} end
    money = amount * price
    update_cash = fn %{holding: holding, position: position} -> %{holding: holding, position: position - money} end
    new_state = state
      |> Map.update!(:assets, fn assets -> 
           Map.update(assets, asset, %{holding: 0, position: 0}, update_asset) 
         end)
      |> Map.update!(:cash, update_cash)
    {:noreply, new_state}
  end
  
  def handle_info({:order_fulfilled, :sell, asset, amount, price}, state) do
    money = amount * price
    update_cash = fn %{holding: holding, position: position} -> %{holding: holding + money, position: position} end
    update_asset = fn %{holding: holding, position: position} -> %{holding: holding, position: position - amount} end

    new_state = state
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
    money_in_asset = asset_holding * current_price
    portion_in_asset = money_in_asset / (money_in_asset + cash_holding)
    is_buy = :rand.uniform() > portion_in_asset
    price = Float.round(:rand.normal(current_price, current_price / 10), 2)
    amount = Float.round(:rand.uniform() * if is_buy do cash_holding / current_price else asset_holding end, 2)
    if is_buy do
      buy(state, asset, amount, price)
    else
      sell(state, asset, amount, price)
    end
  end

  def buy(state, asset, amount, price) do
    OrderBook.add_order(self(), asset, :buy, amount, price)
    send(state.liveview_pid, {:trade, state.id, :buy, price, amount})
    money = amount * price
    update_cash = fn %{holding: holding, position: position} -> %{holding: holding - money, position: position + money} end
    state |> Map.update!(:cash, update_cash)
  end

  def sell(state, asset, amount, price) do
    OrderBook.add_order(self(), asset, :sell, amount, price)
    send(state.liveview_pid, {:trade, state.id, :sell, price, amount})
    update_asset = fn %{holding: holding, position: position} -> %{holding: holding - amount, position: position + amount} end
    dbg(state.assets)
    state |> Map.update!(:assets, fn assets -> 
           Map.update(assets, asset, %{holding: 0, position: 0}, update_asset) 
         end)
  end
end
