defmodule SmileyscaretakerWeb.PageController do
  use SmileyscaretakerWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
