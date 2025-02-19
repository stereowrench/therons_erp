defmodule TheronsErp.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      TheronsErp.Repo,
      {Oban,
       AshOban.config(
         Application.fetch_env!(:therons_erp, :ash_domains),
         Application.fetch_env!(:therons_erp, Oban)
       )},
      TheronsErpWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:therons_erp, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: TheronsErp.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: TheronsErp.Finch},
      # Start a worker by calling: TheronsErp.Worker.start_link(arg)
      # {TheronsErp.Worker, arg},
      # Start to serve requests, typically the last entry
      TheronsErpWeb.Endpoint,
      {AshAuthentication.Supervisor, [otp_app: :therons_erp]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TheronsErp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TheronsErpWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
