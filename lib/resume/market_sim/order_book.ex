defmodule OrderBook do
  use Agent

  # send(con_pid, {:order_fulfilled, con_price, amount})
  # send(liveview_pid, {:update_price, updated_price, display_order, market})
  # orders = %{
  #   sell: [{5, 101, 1}, {8, 102, 2}, {12, 104, 3}],
  #   buy: [{5, 99, 1}, {8, 98, 2}, {12, 96, 3}]
  # }

  def start_link(liveview_pid) do
    Agent.start_link(fn -> %{market: %{sell: [], buy: [], last_price: nil}, liveview_pid: liveview_pid} end, name: :order_book)
  end

  defp consume_orders(_, last_price, order, []), do: {order, [], last_price}
  defp consume_orders(compare, last_price, {amount, price, pid} = order, [{con_amount, con_price, con_pid} | rest] = orders) do
    if compare.(price, con_price) do
      if amount > con_amount do
        send(con_pid, {:order_fulfilled, con_price, con_amount})
        consume_orders(compare, con_price, {amount - con_amount, price, pid}, rest)
      else
        send(con_pid, {:order_fulfilled, con_price, amount})
        updated_orders = if con_amount == amount do rest else [{con_amount - amount, con_price, con_pid} | rest] end
        {:consumed, updated_orders, con_price}
      end
    else
      {order, orders, last_price}
    end
  end

  defp place_order(_, order, []), do: [order]
  defp place_order(compare, {_, price, _} = order, [{_, cur_price, _} = cur_order | rest] = orders) do
    if compare.(price, cur_price) do
      [cur_order | place_order(compare, order, rest)]
    else
      [order | orders]
    end
  end

  defp orders_to_display([p | rest], [], acc), do: [{p, acc} | orders_to_display(rest, [], 0)]
  defp orders_to_display([], _, _), do: []
  defp orders_to_display([_], _, _), do: []
  defp orders_to_display(
    [left_price, right_price | rest_prices] = prices,
    [{amount, price, _pid} | rest_orders] = orders,
    acc
  ) do
    in_bucket = (left_price < price && price <= right_price) || (left_price >= price && price > right_price)
    if (in_bucket) do
      orders_to_display(prices, rest_orders, acc + amount)
    else
      [{Enum.min([left_price, right_price]), acc} | orders_to_display([right_price | rest_prices], orders, 0)]
    end
  end

  defp get_orders_to_display(orders, price, increment, quantity) do
    sell_prices = Stream.iterate(price, &(&1 + increment))
      |> Enum.take(quantity + 1)
      |> orders_to_display(Map.get(orders, :sell, []), 0)
      |> Enum.reverse()
      |> Enum.map(fn {pr, amount} -> {pr, amount, :sell} end)
    buy_prices = Stream.iterate(price, &(&1 - increment))
      |> Enum.take(quantity + 1)
      |> orders_to_display(Map.get(orders, :buy, []), 0)
      |> Enum.map(fn {pr, amount} -> {pr, amount, :buy} end)

    Enum.concat(sell_prices, buy_prices)
  end

  defp get_final_price(market, new_price) do
    if new_price != nil do
      new_price
    else
      buy_price = elem(List.first(Map.get(market, :buy, [{nil, nil, nil}]), {nil, nil, nil}), 1)
      if buy_price != nil do
        buy_price
      else
       elem(List.first(Map.get(market, :sell, [{nil, nil, nil}]), {nil, nil, nil}), 1) 
      end
    end
  end

  def add_order(pid, market, buy_or_sell, amount, price) do
    {new_relevant_market, updated_price, liveview_pid} = Agent.get_and_update(:order_book, fn state ->
      relevant_market = Map.get(state, market, %{sell: [], buy: [], last_price: nil})
      {sell_or_buy, compare_consume, compare_insert} = if buy_or_sell == :buy do {:sell, &>=/2, &<=/2} else {:buy, &<=/2, &>=/2} end
      orders_to_consume = Map.get(relevant_market, sell_or_buy, [])
      {new_relevant_market, new_price} = case consume_orders(compare_consume, nil, {amount, price, pid}, orders_to_consume) do
        {:consumed, new_orders_to_consume, new_price} -> 
          new_relevant_market = relevant_market
            |> Map.update(sell_or_buy, [], fn _ -> new_orders_to_consume end)
            |> Map.update(:last_price, nil, fn _ -> new_price end) 
          {new_relevant_market, new_price}
        {final_order, new_orders_to_consume, new_price} -> 
          new_relevant_market = relevant_market
            |> Map.update(sell_or_buy, [], fn _ -> new_orders_to_consume end)
            |> Map.update(buy_or_sell, [], fn old_orders -> place_order(compare_insert, final_order, old_orders) end)
            |> Map.update(:last_price, nil, fn _ -> new_price end) 
          {new_relevant_market, new_price}
      end
      final_price = get_final_price(new_relevant_market, new_price)

      new_state = Map.update(state, market, %{sell: [], buy: [], last_price: nil}, fn _ -> new_relevant_market end)
      {{new_relevant_market, final_price, Map.get(state, :liveview_pid)}, new_state}
    end)
    display_order = get_orders_to_display(new_relevant_market, updated_price, 0.5, 10)
    arg = {:update_price, updated_price, display_order, market}
    send(liveview_pid, arg)
  end

  def get_state do
    Agent.get(:order_book, fn state -> state end)
  end

  def load_example do
    add_order("user_001", :market, :buy, 15, 100.50)
    add_order("user_012", :market, :buy, 30, 99.75)
    add_order("user_008", :market, :sell, 40, 101.50)
    add_order("user_018", :market, :buy, 20, 99.25)
    add_order("user_024", :market, :buy, 45, 98.75)
    add_order("user_030", :market, :buy, 60, 98.00)
    add_order("user_015", :market, :buy, 40, 99.50)
    add_order("user_027", :market, :buy, 25, 98.50)
    add_order("user_023", :market, :sell, 45, 102.75)
    add_order("user_026", :market, :sell, 30, 103.00)
    add_order("user_002", :market, :sell, 20, 101.00)
    add_order("user_005", :market, :sell, 30, 101.25)
    add_order("user_011", :market, :sell, 25, 101.75)
    add_order("user_007", :market, :buy, 50, 100.00)
    add_order("user_020", :market, :sell, 20, 102.50)
    add_order("user_029", :market, :sell, 55, 103.50)
    add_order("user_021", :market, :buy, 35, 99.00)
    add_order("user_014", :market, :sell, 35, 102.00)
    add_order("user_017", :market, :sell, 50, 102.25)
    add_order("user_003", :market, :buy, 25, 100.25)
  end
end
