defmodule Smileys.Logic.PostScraper do
	
	alias SmileysData.QueryUser

	@max_actions 3

	def scan_for_actions(body) do
		actions = Regex.scan(regex_matcher(), body)

		process_actions(actions, {[], body}, 0)
	end

	defp process_actions([], acc, _) do
		acc
	end

	defp process_actions(_, acc, @max_actions) do
		acc
	end

	defp process_actions([[full_action_string, action_type, action_val]|tail], {acc, body}, amt_callouts) do
		case action_type do
			"u" ->
				process_actions(tail, {[patron_shout(action_val)|acc], body_modification(body, full_action_string, action_type)}, amt_callouts + 1)
			"s" ->
				process_actions(tail, {[smileys_shout(action_val)|acc], body_modification(body, full_action_string, action_type)}, amt_callouts + 1)
			_ ->
				process_actions(tail, [{:invalid_action, body}|acc], amt_callouts)
		end
	end

	defp process_actions([_|tail], acc, amt_callouts) do
		process_actions(tail, acc, amt_callouts)
	end

	defp patron_shout(user_name) do
		user = QueryUser.user_by_name(user_name)

		case user do
			nil ->
				:invalid_shout_value
			_ ->
				{:shout, user_name}
		end
	end

	defp smileys_shout(_smileys_proc) do
		:invalid_shout
	end

	defp body_modification(body, full_action_string, action_type) do
		html = Phoenix.View.render_to_string SmileysWeb.SharedView, "comment_action.html", %{:action_type => action_type, :action_string => full_action_string}

		Regex.replace(regex_matcher(), body, html)
	end

	defp regex_matcher() do
		~r/\/([a-z])\/([a-zA-Z0-9_]+)/
	end
end