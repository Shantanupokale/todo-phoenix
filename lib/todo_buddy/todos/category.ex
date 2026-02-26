defmodule TodoBuddy.Todos.Category do
  use Ecto.Schema
  import Ecto.Changeset

  # categories uses int ID
  schema "categories" do
    field :name, :string
    field :display_name, :string
    has_many :todos, TodoBuddy.Todos.Todo
    timestamps(inserted_at: :created_at, updated_at: false)
  end

  def changeset(category, attrs) do
    category
    |> cast(attrs, [:name, :display_name])
    |> validate_required([:name, :display_name])
    |> unique_constraint(:name)
  end
end
