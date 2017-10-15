defmodule Smileys.Application do
  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      supervisor(SmileysData.Repo, []),
      # Start the endpoint when the application starts
      supervisor(SmileysWeb.Endpoint, []),
      # Start your own worker by calling: Smileys.Worker.start_link(arg1, arg2, arg3)
      # worker(Smileys.Worker, [arg1, arg2, arg3]),
      supervisor(SmileysWeb.Presence, []),

      supervisor(SmileysSearch.Service.get(), [Keyword.new([
        {:host, Application.get_env(:giza_sphinxsearch, :host)},
        {:port, Application.get_env(:giza_sphinxsearch, :port)},
        {:sql_port, Application.get_env(:giza_sphinxsearch, :sql_port)}
      ])]),

      worker(Smileys.User.ActivityRegistry, [{:global, :user_activity_reg}]),
      worker(Smileys.Post.ActivityRegistry, [{:global, :post_activity_reg}]),
      worker(Smileys.Room.ActivityRegistry, [{:global, :room_activity_reg}])

      #worker(SmileysData.GraphRepo.get(), [Keyword.new([
      #  {:user,       Application.get_env(:smileys_graph, :user)}, 
      #  {:password,   Application.get_env(:smileys_graph, :password)}, 
      #  {:connection, Application.get_env(:smileys_graph, :connection)},
      #  {:timeout, 10000}])])
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Smileys.Supervisor]
    Supervisor.start_link(children, opts)
  end
 
  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    SmileysWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
