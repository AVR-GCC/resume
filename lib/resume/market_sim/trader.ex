defmodule Trader do
  use GenServer

  def start_link(liveview_pid) do
    GenServer.start_link(__MODULE__, liveview_pid)
  end

  def init(liveview_pid) do
    update_price(liveview_pid)
    {:ok, liveview_pid}
  end

  def update_price(liveview_pid) do
    rand_num = :rand.uniform(40)
    delta = (rand_num - 20) / 100
    send(liveview_pid, {:update_price, delta})
    Process.send_after(self(), :update, 995)
  end

  def handle_info(:update, liveview_pid) do
    update_price(liveview_pid)
    {:noreply, liveview_pid}
  end
end
