defmodule Smileysapi.Resolver.User do
  require Ecto.Query

  def one(%{name: name}, _info) do
  	user = SmileysData.QueryUser.user_by_name(name)

    {:ok, user}
  end
end