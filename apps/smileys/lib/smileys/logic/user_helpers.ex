defmodule Smileys.Logic.UserHelpers do
	def broadcast_warning(%{user_token: user_token}, msg) do
		SmileysWeb.Endpoint.broadcast("user:" <> user_token, "warning", %{msg: msg})	
	end

	def broadcast_warning(%{name: user_name}, msg) do
		SmileysWeb.Endpoint.broadcast("user:" <> user_name, "warning", %{msg: msg})
	end
end