defmodule TodoBuddyWeb.AuthController do
  use TodoBuddyWeb, :controller

  def callback(conn, %{"user_id" => user_id}) do
    conn
    |> put_session(:user_id, user_id)
    |> redirect(to: ~p"/dashboard")
  end

  def logout(conn, _params) do
    conn
    |> clear_session()
    |> redirect(to: ~p"/")
  end
end
