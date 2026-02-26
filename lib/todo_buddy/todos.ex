defmodule TodoBuddy.Todos do
  import Ecto.Query
  alias TodoBuddy.Repo
  alias TodoBuddy.Todos.{Todo, Category, Subtask}

  # ── categories ------------------------------------

  def list_categories do
    Category
    |> order_by(asc: :display_name)
    |> Repo.all()
  end

  def create_category(attrs) do
    %Category{}
    |> Category.changeset(attrs)
    |> Repo.insert()
  end

  # ── todos ----------------------------------

  def list_todos(user_id, opts \\ %{}) do
    page = Map.get(opts, :page, 1)
    limit = Map.get(opts, :limit, 4)
    search = Map.get(opts, :search, "")
    bookmarked = Map.get(opts, :bookmarked, false)
    filter_status = Map.get(opts, :filter_status, "")
    offset = (page - 1) * limit

    base_query =
      from(t in Todo,
        where: t.user_id == ^user_id,
        left_join: c in Category,
        on: t.category_id == c.id,
        select: %{
          id: t.id,
          title: t.title,
          description: t.description,
          status: t.status,
          bookmarked: t.bookmarked,
          rating: t.rating,
          user_id: t.user_id,
          category_id: t.category_id,
          category_name: c.display_name,
          created_at: t.created_at,
          updated_at: t.updated_at
        },
        order_by: [desc: t.created_at]
      )

    query =
      base_query
      |> maybe_search(search)
      |> maybe_bookmarked(bookmarked)
      |> maybe_filter_status(filter_status)

    # count total using a simpler query
    count_query =
      from(t in Todo,
        where: t.user_id == ^user_id
      )

    count_query =
      count_query
      |> maybe_search_simple(search)
      |> maybe_bookmarked_simple(bookmarked)
      |> maybe_filter_status_simple(filter_status)

    total = Repo.aggregate(count_query, :count, :id)
    total_pages = max(ceil(total / limit), 1)

    todos =
      query
      |> limit(^limit)
      |> offset(^offset)
      |> Repo.all()

    %{
      todos: todos,
      pagination: %{
        total: total,
        page: page,
        limit: limit,
        total_pages: total_pages
      }
    }
  end

  defp maybe_search(query, ""), do: query

  defp maybe_search(query, search) do
    search_term = "%#{search}%"

    from([t, ...] in query,
      where: ilike(t.title, ^search_term) or ilike(t.description, ^search_term)
    )
  end

  defp maybe_bookmarked(query, false), do: query

  defp maybe_bookmarked(query, true) do
    from([t, ...] in query, where: t.bookmarked == true)
  end

  defp maybe_filter_status(query, ""), do: query

  defp maybe_filter_status(query, status) do
    from([t, ...] in query, where: t.status == ^status)
  end

  # simple versions for count query (no joins)
  defp maybe_search_simple(query, ""), do: query

  defp maybe_search_simple(query, search) do
    search_term = "%#{search}%"
    from(t in query, where: ilike(t.title, ^search_term) or ilike(t.description, ^search_term))
  end

  defp maybe_bookmarked_simple(query, false), do: query
  defp maybe_bookmarked_simple(query, true), do: from(t in query, where: t.bookmarked == true)

  defp maybe_filter_status_simple(query, ""), do: query
  defp maybe_filter_status_simple(query, status), do: from(t in query, where: t.status == ^status)

  def create_todo(attrs) do
    %Todo{}
    |> Todo.changeset(attrs)
    |> Repo.insert()
  end

  def get_todo!(id), do: Repo.get!(Todo, id)

  def update_todo(%Todo{} = todo, attrs) do
    todo
    |> Todo.changeset(attrs)
    |> Repo.update()
  end

  def update_todo_by_id(id, user_id, attrs) do
    case Repo.get_by(Todo, id: id, user_id: user_id) do
      nil -> {:error, :not_found}
      todo -> update_todo(todo, attrs)
    end
  end

  def delete_todo(id, user_id) do
    case Repo.get_by(Todo, id: id, user_id: user_id) do
      nil -> {:error, :not_found}
      todo -> Repo.delete(todo)
    end
  end

  def toggle_bookmark(id, user_id) do
    case Repo.get_by(Todo, id: id, user_id: user_id) do
      nil ->
        {:error, :not_found}

      todo ->
        todo
        |> Todo.changeset(%{bookmarked: !todo.bookmarked})
        |> Repo.update()
    end
  end

  def update_rating(id, user_id, rating) do
    case Repo.get_by(Todo, id: id, user_id: user_id) do
      nil ->
        {:error, :not_found}

      todo ->
        todo
        |> Todo.changeset(%{rating: rating})
        |> Repo.update()
    end
  end

  # ── subtasks ----------------------------
  def list_subtasks(todo_id, user_id) do
    Subtask
    |> where([s], s.todo_id == ^todo_id and s.user_id == ^user_id)
    |> order_by(asc: :created_at)
    |> Repo.all()
  end

  def create_subtask(attrs) do
    %Subtask{}
    |> Subtask.changeset(attrs)
    |> Repo.insert()
  end

  def update_subtask(id, user_id, attrs) do
    case Repo.get_by(Subtask, id: id, user_id: user_id) do
      nil ->
        {:error, :not_found}

      subtask ->
          subtask
          |> Subtask.changeset(attrs)
          |> Repo.update()
    end
  end

  def delete_subtask(id, user_id) do
    case Repo.get_by(Subtask, id: id, user_id: user_id) do
      nil -> {:error, :not_found}
      subtask -> Repo.delete(subtask)
    end
  end
end
