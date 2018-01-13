defmodule Smileyscaretaker.Application do
  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    :syn.start()

    :syn.init()

    HTTPoison.start()

    # Define workers and child supervisors to be supervised
    children = [
      # Start the endpoint when the application starts
      supervisor(SmileyscaretakerWeb.Endpoint, []),
      supervisor(SmileysData.Repo, []),

      supervisor(SmileysData.State.UserActivitySupervisor, []),
      supervisor(SmileysData.State.RoomActivitySupervisor, []),
      supervisor(SmileysData.State.PostActivitySupervisor, []),
      worker(SmileysData.State.Timer.ActivityExpire, []),

      worker(Smileyscaretaker.Scheduler, []),
      worker(Smileyscaretaker.Automation.RegisteredBots, [%{}]),

      supervisor(SimpleStatEx.StatSupervisor, [])
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Smileyscaretaker.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    SmileyscaretakerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
