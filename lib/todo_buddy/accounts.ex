defmodule TodoBuddy.Accounts do
  import Ecto.Query
  alias TodoBuddy.Repo
  alias TodoBuddy.Accounts.User

  # will replace this route  POST /api/users/register
  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  # will replace this route  POST /api/users/login
  def authenticate_user(email, password) do
    user = Repo.one(from u in User, where: u.email == ^email)
    cond do
      user && Bcrypt.verify_pass(password, user.password_hash) ->
        {:ok, user}
      user ->
        {:error, :invalid_credentials}
      true ->
        Bcrypt.no_user_verify()
        {:error, :invalid_credentials}
    end
  end

  def get_user!(id), do: Repo.get!(User, id)
end
