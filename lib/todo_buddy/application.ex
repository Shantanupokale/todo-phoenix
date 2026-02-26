defmodule TodoBuddy.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      TodoBuddyWeb.Telemetry,
      TodoBuddy.Repo,
      {DNSCluster, query: Application.get_env(:todo_buddy, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: TodoBuddy.PubSub},
      # Start a worker by calling: TodoBuddy.Worker.start_link(arg)
      # {TodoBuddy.Worker, arg},
      # Start to serve requests, typically the last entry
      TodoBuddyWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TodoBuddy.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TodoBuddyWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
