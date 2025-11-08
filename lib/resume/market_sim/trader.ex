defmodule Trader do
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init(%{liveview_pid: liveview_pid} = args) do
    update_price(liveview_pid)
    {:ok, args}
  end

  def update_price(liveview_pid) do
    rand_num = :rand.uniform(10)
    delta = (rand_num - 5) / 100
    send(liveview_pid, {:update_price, delta})
    milis = :rand.uniform(1500) + 500
    Process.send_after(self(), :update, milis)
  end

  def handle_info(:update, %{liveview_pid: liveview_pid} = args) do
    update_price(liveview_pid)
    {:noreply, args}
  end
end
