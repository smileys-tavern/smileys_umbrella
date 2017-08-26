defmodule SmileysWeb.Router do
  use SmileysWeb, :router
  use Coherence.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Coherence.Authentication.Session
  end

  pipeline :protected do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Coherence.Authentication.Session, protected: true
  end

  pipeline :browser_session do
    plug Guardian.Plug.VerifySession
    plug Guardian.Plug.LoadResource
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # COHERENCE
  scope "/" do
    pipe_through :browser
    coherence_routes()
  end


  scope "/" do
    pipe_through :protected
    coherence_routes :protected
    # get "/sessions/delete", Coherence.SessionController, :delete
  end
  # END COHERENCE

  scope "/", SmileysWeb do
    pipe_through [:browser, :browser_session]

    get "/", PageController, :index
    get "/u/:username", PageController, :profile

    get "/h/:room", PageController, :house

    get "/r/:room", PageController, :room
    get "/r/:room/view/:mode", PageController, :room

    get "/r/:room/comments/:hash/:title", PageController, :comments
    get "/r/:room/comments/:hash/:title/view/:mode", PageController, :comments
    get "/r/:room/comments/:hash/:title/focus/:focushash", PageController, :comments
    get "/r/:room/comments/:hash/", PageController, :comments
    get "/r/:room/comments/:hash/view/:mode", PageController, :comments
    get "/r/:room/comments/:hash/focus/:focushash", PageController, :comments

    get "/room/new", RoomEditController, :new
    post "/room/new", RoomEditController, :create
    get "/room/:roomname/edit", RoomEditController, :edit
    put "/room/:roomname/edit", RoomEditController, :update

    get "/room/:roomname/manage", RoomManageController, :manage
    get "/room/:roomname/manage/mods", RoomManageController, :manage_mods
    post "/room/:roomname/new", RoomManageController, :allowuser
    post "/room/:roomname/manage/mods/new", RoomManageController, :addmod
    get "/room/:roomname/removeuser/:username", RoomManageController, :removeuser
    get "/room/:roomname/removemod/:username", RoomManageController, :removemod

    get "/r/:room/newpost", RoomPostController, :new
    post "/r/:room/new", RoomPostController, :create
    get "/h/:room/newpost", RoomPostController, :new
    post "/h/:room/newpost", RoomPostController, :create

    post "/post/:hash/comment", PostController, :comment
    post "/mod/delete/comment/:hash", PostController, :mod_delete_comment
  end

  # Other scopes may use custom stacks.
  # scope "/api", SmileysWeb do
  #   pipe_through :api
  # end
end
