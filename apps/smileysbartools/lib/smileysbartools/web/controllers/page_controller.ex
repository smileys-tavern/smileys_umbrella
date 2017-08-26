defmodule Smileysbartools.Web.PageController do
  use Smileysbartools.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
