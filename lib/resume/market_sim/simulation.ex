defmodule Simulation do
  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts)
  end

  @impl true
  def init(args) do
    children = [
      # # Start the supervisor dynamically managing apps
      # {DynamicSupervisor, name: Livebook.AppSupervisor, strategy: :one_for_one},
      # # Process group for app deployers
      # %{id: Livebook.Apps.Deployer.PG, start: {:pg, :start_link, [Livebook.Apps.Deployer.PG]}},
      # # Node-local app deployer
      # Livebook.Apps.Deployer,
      # # Node-local app manager watcher
      # Livebook.Apps.ManagerWatcher
      {Ticker, args},
      {Trader, args}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
