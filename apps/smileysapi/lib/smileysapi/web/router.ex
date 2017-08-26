defmodule Smileysapi.Web.Router do
  use Smileysapi.Web, :router

  pipeline :browser do
  	plug :fetch_session
  	plug :protect_from_forgery
  	plug :put_secure_browser_headers
  end

  pipeline :browser_session do
  	plug :fetch_session
    plug Guardian.Plug.VerifySession
    plug Guardian.Plug.LoadResource
    plug Smileysapi.Web.Context
  end

  scope "/" do
    pipe_through [:browser_session]

    forward "/", Absinthe.Plug,
      schema: Smileysapi.Schema
  end
end