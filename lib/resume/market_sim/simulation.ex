defmodule Simulation do
  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts)
  end

  @impl true
  def init(%{liveview_pid: liveview_pid, traders: traders}) do
    trader_children = traders
      |> Enum.with_index()
      |> Enum.map(fn {strategy, index} -> %{
      id: {:trader, index},
      start: {
        Trader,
        :start_link,
          [%{
            strategy: strategy,
            id: index,
            liveview_pid: liveview_pid,
            cash: 100,
            asset_holdings: %{market: 1}
          }]
      }
    } end)
    children = [
      # # Start the supervisor dynamically managing apps
      # {DynamicSupervisor, name: Livebook.AppSupervisor, strategy: :one_for_one},
      # # Process group for app deployers
      # %{id: Livebook.Apps.Deployer.PG, start: {:pg, :start_link, [Livebook.Apps.Deployer.PG]}},
      # # Node-local app deployer
      # Livebook.Apps.Deployer,
      # # Node-local app manager watcher
      # Livebook.Apps.ManagerWatcher
      {
        ExternalSentimentGetter,
        %{
          url: "https://www.random.org/integers/?num=1&min=1&max=100&col=1&base=10&format=plain",
          sentiment: 0.5,
          liveview_pid: liveview_pid
        }
      },
      {OrderBook, liveview_pid},
      {Ticker, liveview_pid} | trader_children
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
