defmodule TodoBuddy.Todos.Todo do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  @foreign_key_type Ecto.UUID

  schema "todos" do
    field :title, :string
    field :description, :string
    field :status, :string, default: "in-progress"
    field :bookmarked, :boolean, default: false
    field :rating, :decimal, default: Decimal.new("0")
    belongs_to :user, TodoBuddy.Accounts.User, type: Ecto.UUID
    belongs_to :category, TodoBuddy.Todos.Category, type: :integer
    has_many :subtasks, TodoBuddy.Todos.Subtask
    timestamps(inserted_at: :created_at, updated_at: :updated_at)
  end

  def changeset(todo, attrs) do
    todo
    |> cast(attrs, [:title, :description, :status, :bookmarked, :rating, :user_id, :category_id])
    |> validate_required([:title, :user_id])
    |> validate_inclusion(:status, ~w(in-progress on-hold complete))
  end
end
