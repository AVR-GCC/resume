defmodule Ticker do
  use GenServer

  def start_link(liveview_pid) do
    GenServer.start_link(__MODULE__, liveview_pid)
  end

  def init(liveview_pid) do
    schedule_tick()
    {:ok, %{counter: 0, liveview_pid: liveview_pid}}
  end

  defp schedule_tick() do
    Process.send_after(self(), :tick, 5000)
  end

  def handle_info(:tick, %{liveview_pid: liveview_pid, counter: counter}) do
    send(liveview_pid, :tick)
    if (Integer.mod(counter, 5) == 0) do
      ExternalSentimentGetter.update_sentiment()
    end
    schedule_tick()
    {:noreply, %{liveview_pid: liveview_pid, counter: counter + 1}}
  end
end
