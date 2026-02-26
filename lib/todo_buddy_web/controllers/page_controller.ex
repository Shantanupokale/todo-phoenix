defmodule TodoBuddyWeb.PageController do
  use TodoBuddyWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
