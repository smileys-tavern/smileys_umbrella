defmodule Smileysapi.Resolver.User do
  require Ecto.Query

  alias SmileysData.Query.User, as: QueryUser

  def one(%{name: name}, _info) do
  	user = QueryUser.by_name(name)

    {:ok, user}
  end
end