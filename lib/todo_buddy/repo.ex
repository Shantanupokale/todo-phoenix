defmodule TodoBuddy.Repo do
  use Ecto.Repo,
    otp_app: :todo_buddy,
    adapter: Ecto.Adapters.Postgres
end
