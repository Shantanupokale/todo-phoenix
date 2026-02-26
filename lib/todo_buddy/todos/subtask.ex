defmodule TodoBuddy.Todos.Subtask do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  @foreign_key_type Ecto.UUID

  schema "subtasks" do
    field :title, :string
    field :description, :string
    field :status, :string, default: "in-progress"
    belongs_to :todo, TodoBuddy.Todos.Todo, type: Ecto.UUID
    belongs_to :user, TodoBuddy.Accounts.User, type: Ecto.UUID
    timestamps(inserted_at: :created_at, updated_at: :updated_at)
  end

  def changeset(subtask, attrs) do
    subtask
    |> cast(attrs, [:title, :description, :status, :todo_id, :user_id])
    |> validate_required([:title, :todo_id, :user_id])
    |> validate_inclusion(:status, ~w(in-progress on-hold complete))
  end
end
