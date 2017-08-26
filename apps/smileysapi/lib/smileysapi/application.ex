defmodule Smileysapi.Application do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      supervisor(SmileysData.Repo, []),
      # Start the endpoint when the application starts
      supervisor(Smileysapi.Web.Endpoint, [])
      # Start your own worker by calling: Smileysapi.Worker.start_link(arg1, arg2, arg3)
      # worker(Smileysapi.Worker, [arg1, arg2, arg3]),
      #worker(SmileysData.GraphRepo.get(), [Keyword.new([
      #  {:user,       Application.get_env(:smileys_graph, :user)}, 
      #  {:password,   Application.get_env(:smileys_graph, :password)}, 
      #  {:connection, Application.get_env(:smileys_graph, :connection)},
      #  {:name, SmileysData.Graph}])])
    ]

    children_final = case Application.get_env(:smileys_features, :graph) do
      :on ->
        [worker(SmileysData.GraphRepo.get(), [Keyword.new([
          {:user,       Application.get_env(:smileys_graph, :user)}, 
          {:password,   Application.get_env(:smileys_graph, :password)}, 
          {:connection, Application.get_env(:smileys_graph, :connection)},
          {:name, SmileysData.Graph}])])|children]
       _ ->
        children
    end

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Smileysapi.Supervisor]
    Supervisor.start_link(children_final, opts)
  end
end
