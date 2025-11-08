defmodule Ticker do
  use GenServer

  def start_link(liveview_pid) do
    GenServer.start_link(__MODULE__, liveview_pid)
  end

  def init(liveview_pid) do
    schedule_tick()
    {:ok, liveview_pid}
  end

  defp schedule_tick() do
    Process.send_after(self(), :tick, 1000)
  end

  def handle_info(:tick, liveview_pid) do
    send(liveview_pid, :tick)
    schedule_tick()
    {:noreply, liveview_pid}
  end
end
