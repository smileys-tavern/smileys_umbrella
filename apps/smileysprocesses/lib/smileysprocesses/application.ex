defmodule SmileysProcesses.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    :syn.start()

    :syn.init()

    HTTPoison.start()

    # List all child processes to be supervised
    children = [
      supervisor(SmileysData.Repo, []),

      supervisor(SmileysData.State.UserActivitySupervisor, []),
      supervisor(SmileysData.State.RoomActivitySupervisor, []),
      supervisor(SmileysData.State.PostActivitySupervisor, []),
      worker(SmileysData.State.Timer.ActivityExpire, []),

      worker(SmileysProcesses.Scheduler, []),
      worker(SmileysProcesses.Automation.RegisteredBots, [%{}]),

      supervisor(SimpleStatEx.StatSupervisor, [])
    ]

    opts = [strategy: :one_for_one, name: SmileysProcesses.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
