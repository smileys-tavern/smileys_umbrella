defmodule Smileyscaretaker.Application do
  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    :syn.start()

    :syn.init()

    # Define workers and child supervisors to be supervised
    children = [
      # Start the endpoint when the application starts
      supervisor(SmileyscaretakerWeb.Endpoint, []),
      supervisor(SmileysData.Repo, []),
      worker(Smileyscaretaker.Scheduler, []),
      worker(Smileyscaretaker.Automation.RegisteredBots, [%{}])
    ]

    if :syn.find_by_key(:user_activity_reg) == :undefined do
      SmileysData.State.User.ActivityRegistry.start_link({:via, :syn, :user_activity_reg})
    end

    if :syn.find_by_key(:post_activity_reg) == :undefined do
      SmileysData.State.Post.ActivityRegistry.start_link({:via, :syn, :post_activity_reg})
    end

    if :syn.find_by_key(:room_activity_reg) == :undefined do
      SmileysData.State.Room.ActivityRegistry.start_link({:via, :syn, :room_activity_reg})
    end

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
