defmodule TodoBuddyWeb.Plugs.Auth do
  import Plug.Conn
  import Phoenix.Controller

  def init(opts), do: opts

  # it will act as authmiddleware.js
  def require_auth(conn, _opts) do
    if get_session(conn, :user_id) do
      conn
    else
      conn |> redirect(to: "/login") |> halt()
    end
  end

  # redirect away from login/register if already logged in
  def redirect_if_authenticated(conn, _opts) do
    if get_session(conn, :user_id) do
      conn |> redirect(to: "/dashboard") |> halt()
    else
      conn
    end
  end
end
