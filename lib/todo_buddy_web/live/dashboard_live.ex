defmodule TodoBuddyWeb.DashboardLive do
  use TodoBuddyWeb, :live_view

  alias TodoBuddy.Todos
  alias TodoBuddy.Accounts

  @default_limit 4

  def mount(_params, session, socket) do
        user_id = session["user_id"]
        user = Accounts.get_user!(user_id)
        categories = Todos.list_categories()

        socket =
          socket
          |> assign(
            current_user: user,
            page: 1,
            limit: @default_limit,
            search: "",
            debounced_search: "",
            show_bookmarked: false,
            filter_status: "",
            editing_id: nil,
            edited_title: "",
            edited_description: "",
            new_title: "",
            new_description: "",
            new_category_id: "",
            categories: categories,
            show_category_modal: false,
            cat_name: "",
            cat_display_name: "",
            delete_modal_todo: nil,
            open_subtask_panels: MapSet.new(),
            subtasks: %{},
            adding_subtask_for: nil,
            new_subtask_title: "",
            user_menu_open: false
          )
          |> fetch_todos()

        {:ok, socket}

  end

  # data fetching ---------

  defp fetch_todos(socket) do
    result =
      Todos.list_todos(socket.assigns.current_user.id, %{
        page: socket.assigns.page,
        limit: socket.assigns.limit,
        search: socket.assigns.debounced_search,
        bookmarked: socket.assigns.show_bookmarked,
        filter_status: socket.assigns.filter_status
      })

    assign(socket,
      todos: result.todos,
      total_pages: result.pagination.total_pages
    )
  end

  # searcghing with debounce method
  def handle_event("search", %{"value" => search}, socket) do
    Process.send_after(self(), {:debounced_search, search}, 500)
    {:noreply, assign(socket, search: search)}
  end


  # filter and pagination

  def handle_event("filter_status", %{"status" => status}, socket) do
    {:noreply,
     socket
     |> assign(filter_status: status, page: 1)
     |> fetch_todos()}
  end

  def handle_event("toggle_bookmarked", _, socket) do
    {:noreply,
     socket
     |> assign(show_bookmarked: !socket.assigns.show_bookmarked, page: 1)
     |> fetch_todos()}
  end

  def handle_event("change_limit", %{"limit" => limit}, socket) do
    {:noreply,
     socket
     |> assign(limit: String.to_integer(limit), page: 1)
     |> fetch_todos()}
  end

  def handle_event("prev_page", _, socket) do
    page = max(socket.assigns.page - 1, 1)
    {:noreply, socket |> assign(page: page) |> fetch_todos()}
  end

  def handle_event("next_page", _, socket) do
    page = min(socket.assigns.page + 1, socket.assigns.total_pages)
    {:noreply, socket |> assign(page: page) |> fetch_todos()}
  end


  # create todo method
  def handle_event("update_todo_form", %{"todo" => todo_params}, socket) do
    socket =
      socket
      |> assign(
        new_title: todo_params["title"] || socket.assigns.new_title,
        new_description: todo_params["description"] || socket.assigns.new_description
      )

    case todo_params["category_id"] do
      "create-new" ->
        {:noreply, assign(socket, show_category_modal: true, new_category_id: "")}

      cat_id when is_binary(cat_id) ->
        {:noreply, assign(socket, new_category_id: cat_id)}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("update_todo_form", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("add_todo", _, socket) do
    %{new_title: title, new_description: desc, new_category_id: cat_id, current_user: user} =
      socket.assigns

    if String.trim(title) == "" or String.trim(desc) == "" do
      {:noreply, socket}
    else
      cat_id_val = if cat_id == "", do: nil, else: String.to_integer(cat_id)

      case Todos.create_todo(%{
             title: String.trim(title),
             description: String.trim(desc),
             user_id: user.id,
             category_id: cat_id_val
           }) do
        {:ok, _} ->
          {:noreply,
           socket
           |> assign(new_title: "", new_description: "", new_category_id: "")
           |> fetch_todos()}

       {:error, _} ->
           {:noreply, socket}
      end
    end
  end

  # create category

  def handle_event("update_category_form", %{"category" => cat_params}, socket) do
    {:noreply,
     assign(socket,
       cat_name: cat_params["name"] || "",
       cat_display_name: cat_params["display_name"] || ""
     )}
  end

  def handle_event("update_category_form", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("create_category", _, socket) do
    %{cat_name: name, cat_display_name: display_name} = socket.assigns

    if String.trim(name) == "" or String.trim(display_name) == "" do
      {:noreply, socket}
    else
      case Todos.create_category(%{
             name: String.trim(name),
             display_name: String.trim(display_name)
           }) do
        {:ok, category} ->
          {:noreply,
           assign(socket,
             categories: socket.assigns.categories ++ [category],
             new_category_id: to_string(category.id),
             show_category_modal: false,
             cat_name: "",
             cat_display_name: ""
           )}

        {:error, _} ->
            {:noreply, socket}
      end
    end
  end

  def handle_event("close_category_modal", _, socket) do
    {:noreply, assign(socket, show_category_modal: false)}
  end

  # delete todo

  def handle_event("open_delete_modal", %{"id" => id}, socket) do
    todo = Enum.find(socket.assigns.todos, &(to_string(&1.id) == id))
    {:noreply, assign(socket, delete_modal_todo: todo)}
  end

  def handle_event("close_delete_modal", _, socket) do
    {:noreply, assign(socket, delete_modal_todo: nil)}
  end

  def handle_event("confirm_delete", _, socket) do
    if todo = socket.assigns.delete_modal_todo do
      Todos.delete_todo(todo.id, socket.assigns.current_user.id)

      {:noreply,
       socket
       |> assign(delete_modal_todo: nil)
       |> fetch_todos()}
    else
      {:noreply, socket}
    end
  end

  # update status

  def handle_event("update_status", %{"id" => id, "status" => status}, socket) do
    case Todos.update_todo_by_id(id, socket.assigns.current_user.id, %{status: status}) do
      {:ok, _} ->
        {:noreply,
         socket
         |> fetch_todos()}

      _ ->
        {:noreply, socket}
    end
  end

  # edit todo
  def handle_event("start_edit", %{"id" => id}, socket) do
    todo = Enum.find(socket.assigns.todos, &(to_string(&1.id) == id))

    {:noreply,
     assign(socket,
       editing_id: id,
       edited_title: todo.title,
       edited_description: todo.description || ""
     )}
  end

  def handle_event("cancel_edit", _, socket) do
    {:noreply, assign(socket, editing_id: nil)}
  end

  def handle_event("update_edit_form", %{"edit" => edit_params}, socket) do
    {:noreply,
     assign(socket,
       edited_title: edit_params["title"] || socket.assigns.edited_title,
       edited_description: edit_params["description"] || socket.assigns.edited_description
     )}
  end

  def handle_event("update_edit_form", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("save_edit", _, socket) do
    %{editing_id: id, edited_title: title, edited_description: desc} = socket.assigns

    if String.trim(title) == "" do
      {:noreply, socket}
    else
      case Todos.update_todo_by_id(id, socket.assigns.current_user.id, %{
             title: String.trim(title),
             description: String.trim(desc)
           }) do
        {:ok, _} ->
          {:noreply,
           socket
           |> assign(editing_id: nil)
           |> fetch_todos()}

        _ ->
          {:noreply, socket}
      end
    end
  end

  # bookmark------

  def handle_event("toggle_bookmark", %{"id" => id}, socket) do
    case Todos.toggle_bookmark(id, socket.assigns.current_user.id) do
      {:ok, _} ->
        {:noreply,
         socket
         |> fetch_todos()}

      _ ->
        {:noreply, socket}
    end
  end

  # rating --------

  def handle_event("update_rating", %{"id" => id, "rating" => rating}, socket) do
    {rating_val, _} = Float.parse(rating)

    case Todos.update_rating(id, socket.assigns.current_user.id, rating_val) do
      {:ok, _} ->
        {:noreply,
         socket
         |> fetch_todos()}

      _ ->
        {:noreply, socket}
    end
  end

  # subtask method-----

  def handle_event("toggle_subtasks", %{"id" => id}, socket) do
    panels = socket.assigns.open_subtask_panels

    if MapSet.member?(panels, id) do
      {:noreply, assign(socket, open_subtask_panels: MapSet.delete(panels, id))}
    else
      subtasks = Todos.list_subtasks(id, socket.assigns.current_user.id)

      {:noreply,
       assign(socket,
         open_subtask_panels: MapSet.put(panels, id),
         subtasks: Map.put(socket.assigns.subtasks, id, subtasks)
       )}
    end
  end

  def handle_event("start_add_subtask", %{"todo-id" => todo_id}, socket) do
    {:noreply, assign(socket, adding_subtask_for: todo_id, new_subtask_title: "")}
  end

  def handle_event("cancel_add_subtask", _, socket) do
    {:noreply, assign(socket, adding_subtask_for: nil, new_subtask_title: "")}
  end

  def handle_event("update_subtask_form", %{"subtask" => %{"title" => title}}, socket) do
    {:noreply, assign(socket, new_subtask_title: title)}
  end

  def handle_event("update_subtask_form", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("add_subtask", %{"todo-id" => todo_id}, socket) do
    title = String.trim(socket.assigns.new_subtask_title)

    if title == "" do
      {:noreply, socket}
    else
      case Todos.create_subtask(%{
             title: title,
             description: "",
             todo_id: todo_id,
             user_id: socket.assigns.current_user.id
           }) do
        {:ok, _} ->
          subtasks = Todos.list_subtasks(todo_id, socket.assigns.current_user.id)

          {:noreply,
           assign(socket,
             subtasks: Map.put(socket.assigns.subtasks, todo_id, subtasks),
             adding_subtask_for: nil,
             new_subtask_title: ""
           )}

        {:error, _} ->
          {:noreply, socket}
      end
    end
  end

  def handle_event(
        "update_subtask_status",
        %{"id" => id, "status" => status, "todo-id" => todo_id},
        socket
      ) do
    subtask = Enum.find(socket.assigns.subtasks[todo_id] || [], &(to_string(&1.id) == id))

    if subtask do
      case Todos.update_subtask(id, socket.assigns.current_user.id, %{
             title: subtask.title,
             description: subtask.description || "",
             status: status
           }) do
        {:ok, _} ->
          subtasks = Todos.list_subtasks(todo_id, socket.assigns.current_user.id)

          {:noreply,
           socket
           |> assign(subtasks: Map.put(socket.assigns.subtasks, todo_id, subtasks))
           |> fetch_todos()}

        _ ->
          {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("toggle_subtask", %{"id" => id, "todo-id" => todo_id}, socket) do
    subtask = Enum.find(socket.assigns.subtasks[todo_id] || [], &(to_string(&1.id) == id))

    if subtask do
      new_status = if subtask.status == "complete", do: "in-progress", else: "complete"

      case Todos.update_subtask(id, socket.assigns.current_user.id, %{
             title: subtask.title,
             description: subtask.description || "",
             status: new_status
           }) do
        {:ok, _} ->
          subtasks = Todos.list_subtasks(todo_id, socket.assigns.current_user.id)

          {:noreply,
           socket
           |> assign(subtasks: Map.put(socket.assigns.subtasks, todo_id, subtasks))
           |> fetch_todos()}

        _ ->
          {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("delete_subtask", %{"id" => id, "todo-id" => todo_id}, socket) do
    case Todos.delete_subtask(id, socket.assigns.current_user.id) do
      {:ok, _} ->
        subtasks = Todos.list_subtasks(todo_id, socket.assigns.current_user.id)

        {:noreply, assign(socket, subtasks: Map.put(socket.assigns.subtasks, todo_id, subtasks))}

      _ ->
        {:noreply, socket}
    end
  end

  # user menu event handlers

  def handle_event("toggle_user_menu", _, socket) do
    {:noreply, assign(socket, user_menu_open: !socket.assigns.user_menu_open)}
  end

  def handle_event("logout", _, socket) do
    {:noreply, redirect(socket, to: ~p"/auth/logout")}
  end

  def handle_info({:debounced_search, search}, socket) do
    if search == socket.assigns.search do
      {:noreply,
       socket
       |> assign(debounced_search: search, page: 1)
       |> fetch_todos()}
    else
      {:noreply, socket}
    end
  end


  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-200 flex items-center justify-center p-4 md:p-12">
      <div class="bg-base-100 w-full max-w-5xl rounded-xl shadow-lg p-6 md:p-8 m-4">
        <%!-- Header --%>
        <div class="flex flex-row text-center gap-3 pb-5 justify-between">
          <div class="flex flex-row gap-3 items-center">
            <div class="w-9 h-9 bg-neutral text-neutral-content flex items-center justify-center rounded-md font-bold text-sm">
              TB
            </div>
            <span class="text-lg font-semibold tracking-tight">TodoBuddy</span>
          </div>

          <div class="relative inline-block text-left">
            <button
              phx-click="toggle_user_menu"
              class="flex items-center text-sm gap-2 px-2 py-1 bg-base-200 rounded-md hover:bg-base-300 transition"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="w-3 h-3" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" /><circle cx="12" cy="7" r="4" />
              </svg>
              {@current_user.username}
            </button>
            <div :if={@user_menu_open} class="absolute right-0 bg-error text-error-content border rounded shadow-md z-10">
              <button phx-click="logout" class="block w-full text-left p-1.5 text-sm">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                  <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" /><polyline points="16 17 21 12 16 7" /><line x1="21" y1="12" x2="9" y2="12" />
                </svg>
              </button>
            </div>
          </div>
        </div>

        <%!-- Todo Form --%>
        <form phx-change="update_todo_form" phx-submit="add_todo" class="flex flex-row gap-3 mb-2 max-h-10 flex-wrap">
          <input
            type="text"
            placeholder="Enter title"
            name="todo[title]"
            value={@new_title}
            class="px-4 py-1 rounded-lg border border-base-300 bg-base-100 text-sm focus:outline-none"
          />
          <textarea
            placeholder="Description"
            name="todo[description]"
            class="px-4 py-1 rounded-lg border border-base-300 bg-base-100 text-sm focus:outline-none"
          >{@new_description}</textarea>
          <select name="todo[category_id]" class="px-2 py-1 border rounded-md text-[11px] bg-neutral text-neutral-content">
            <option value="">Select Category</option>
            <option :for={cat <- @categories} value={cat.id} selected={to_string(cat.id) == @new_category_id}>
              {cat.display_name}
            </option>
            <option value="create-new">+ New Category</option>
          </select>
          <button type="submit" class="px-2 py-1 border rounded-md text-[11px] bg-neutral text-neutral-content hover:opacity-80 transition">
            Add Todo
          </button>
        </form>

        <%!-- Category Modal --%>
        <div :if={@show_category_modal} class="fixed inset-0 flex items-center justify-center z-50">
          <div class="absolute inset-0 bg-black/5" phx-click="close_category_modal"></div>
          <div class="relative bg-base-100 w-full max-w-md rounded-xl shadow-xl p-6 z-10">
            <h2 class="text-xl font-semibold mb-4">Create Category</h2>
            <form phx-change="update_category_form" phx-submit="create_category" class="mb-6 flex flex-col gap-3" id="cat-form">
              <input type="text" placeholder="Category name (slug)" name="category[name]" value={@cat_name} class="border border-base-300 px-3 py-2 rounded bg-base-100 focus:outline-none" />
              <input type="text" placeholder="Display name" name="category[display_name]" value={@cat_display_name} class="border border-base-300 px-3 py-2 rounded bg-base-100 focus:outline-none" />
            </form>
            <div class="flex justify-end gap-3">
              <button phx-click="close_category_modal" class="px-4 py-2 rounded-lg border border-base-300 hover:bg-base-200 transition">Cancel</button>
              <button type="submit" form="cat-form" class="px-4 py-2 rounded-lg bg-primary text-primary-content hover:opacity-80 transition">Create</button>
            </div>
          </div>
        </div>

        <%!-- Search  --%>
        <div class="flex items-center justify-between gap-4 mb-3 mt-4">
          <div class="flex-1">
            <input type="text" placeholder="Search todos..." value={@search} phx-keyup="search" name="value" class="px-3 py-2 border border-base-300 rounded-md text-sm bg-base-100 focus:outline-none" />
          </div>
        </div>

        <%!-- Status Filter + Bookmark + Record Controller --%>
        <div class="flex items-center justify-between mb-3 mt-2 flex-wrap gap-2">
          <div class="flex items-center gap-6 py-3">
            <label :for={opt <- status_options()} class={"flex items-center gap-2 cursor-pointer text-[11px] font-medium tracking-wide transition #{if @filter_status == opt.value, do: "text-base-content", else: "text-base-content/40 hover:text-base-content/80"}"}>
              <input type="radio" name="status_filter" value={opt.value} checked={@filter_status == opt.value} phx-click="filter_status" phx-value-status={opt.value} class="accent-primary w-3 h-3" />
              {opt.label}
            </label>
          </div>
          <div class="flex flex-row gap-4 items-center">
            <button phx-click="toggle_bookmarked" title="bookmark">
              <svg xmlns="http://www.w3.org/2000/svg" class="w-[18px] h-[18px]" viewBox="0 0 24 24" fill={if @show_bookmarked, do: "currentColor", else: "none"} stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M19 21l-7-5-7 5V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2z" />
              </svg>
            </button>
            <form phx-change="change_limit" id="limit-form">
              <select name="limit" class="px-2 py-1 border rounded-md text-[11px] bg-neutral text-neutral-content hover:opacity-80 transition">
                <option :for={v <- [4, 5, 8]} value={v} selected={@limit == v}>{v} records</option>
              </select>
            </form>
          </div>
        </div>

        <%!-- Content --%>
        <%= if length(@todos) == 0 do %>
          <div class="flex flex-col items-center justify-center py-20 text-base-content/40">
            <p class="text-lg font-semibold tracking-wide">No Todo Found</p>
            <p class="text-sm">Try adjusting your search or filters</p>
          </div>
        <% else %>

            <div class="space-y-4">
              <div :for={todo <- @todos} class="flex flex-col gap-1">
                <div class="flex items-center justify-between bg-base-200 p-3 rounded-lg gap-3">
                  <div class="flex items-center gap-3">
                    <input type="checkbox" class="mt-2 cursor-pointer checkbox checkbox-sm" />
                    <%= if @editing_id == to_string(todo.id) do %>
                      <form phx-change="update_edit_form" phx-submit="save_edit" class="gap-3 flex">
                        <div class="flex flex-col gap-3">
                          <input type="text" value={@edited_title} name="edit[title]" class="px-2 py-1 rounded border border-base-300 outline-none text-sm bg-base-100" />
                          <input type="text" value={@edited_description} name="edit[description]" class="px-2 py-1 rounded border border-base-300 outline-none text-xs bg-base-100" />
                        </div>
                        <div class="flex flex-col gap-4">
                          <button type="submit" class="px-2 py-1 text-sm bg-info text-info-content rounded hover:opacity-80 transition">Save</button>
                          <button type="button" phx-click="cancel_edit" class="px-3 py-1 text-sm border rounded">Cancel</button>
                        </div>
                      </form>
                    <% else %>
                      <div>
                        <span class={"text-lg #{if todo.status == "complete", do: "line-through text-base-content/40"}"}>{todo.title}</span>
                        <div class="text-base-content/40 text-xs">{todo.description}</div>
                        <div class="flex items-center gap-3 mt-2">
                          <.star_rating value={rating_float(todo.rating)} todo_id={todo.id} />
                          <span class="text-sm text-base-content/50">{format_rating(todo.rating)}</span>
                        </div>
                      </div>
                    <% end %>
                  </div>

                  <div class="flex items-center gap-3">
                    <span :if={todo.category_name} class="text-[11px] bg-info/20 text-info px-2 py-1 uppercase italic rounded">{todo.category_name}</span>
                    <form phx-change="update_status" phx-value-id={todo.id} id={"status-form-#{todo.id}"}>
                      <select name="status" class={"p-2 rounded-md border text-[11px] font-medium transition outline-none #{status_style(todo.status)}"}>
                        <option value="in-progress" selected={todo.status == "in-progress"}>IN-PROGRESS</option>
                        <option value="on-hold" selected={todo.status == "on-hold"}>ON-HOLD</option>
                        <option value="complete" selected={todo.status == "complete"}>COMPLETE</option>
                      </select>
                    </form>
                    <button phx-click="start_edit" phx-value-id={todo.id} class="text-base-content/60 hover:text-info transition">
                      <svg xmlns="http://www.w3.org/2000/svg" class="w-[18px] h-[18px]" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7" /><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z" /></svg>
                    </button>
                    <button phx-click="open_delete_modal" phx-value-id={todo.id} class="text-base-content/60 hover:text-error transition">
                      <svg xmlns="http://www.w3.org/2000/svg" class="w-[18px] h-[18px]" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6" /><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2" /></svg>
                    </button>
                    <button phx-click="toggle_bookmark" phx-value-id={todo.id}>
                      <svg xmlns="http://www.w3.org/2000/svg" class="w-[18px] h-[18px]" viewBox="0 0 24 24" fill={if todo.bookmarked, do: "red", else: "none"} stroke={if todo.bookmarked, do: "red", else: "currentColor"} stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z" />
                      </svg>
                    </button>
                    <button phx-click="toggle_subtasks" phx-value-id={todo.id} class={"p-1 rounded-full transition-colors #{if MapSet.member?(@open_subtask_panels, to_string(todo.id)), do: "bg-info/20 text-info", else: "text-base-content/50 hover:bg-base-300"}"} title="Subtasks">
                      <%= if MapSet.member?(@open_subtask_panels, to_string(todo.id)) do %>
                        <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="18 15 12 9 6 15" /></svg>
                      <% else %>
                        <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="8" y1="6" x2="21" y2="6" /><line x1="8" y1="12" x2="21" y2="12" /><line x1="8" y1="18" x2="21" y2="18" /><line x1="3" y1="6" x2="3.01" y2="6" /><line x1="3" y1="12" x2="3.01" y2="12" /><line x1="3" y1="18" x2="3.01" y2="18" /></svg>
                      <% end %>
                    </button>
                  </div>
                </div>

                <%!-- Subtask Panel --%>
                <div :if={MapSet.member?(@open_subtask_panels, to_string(todo.id))} class="mt-2 ml-8 border-l border-base-300 pl-4 py-2">
                  <div class="flex items-center justify-between mb-2">
                    <h4 class="text-[10px] font-bold text-base-content/40 uppercase">Subtasks</h4>
                    <button :if={@adding_subtask_for != to_string(todo.id)} phx-click="start_add_subtask" phx-value-todo-id={todo.id} class="text-info text-xs">+ Add Subtask</button>
                  </div>

                  <%= if (@subtasks[to_string(todo.id)] || []) == [] do %>
                    <p :if={@adding_subtask_for != to_string(todo.id)} class="text-xs text-base-content/40">No subtasks.</p>
                  <% else %>
                    <div class="flex flex-col gap-2">
                      <div :for={st <- @subtasks[to_string(todo.id)] || []} class="flex items-center justify-between bg-base-200 p-2 rounded gap-1 text-sm">
                        <div class="flex items-center gap-2">
                          <input type="checkbox" checked={st.status == "complete"} phx-click="toggle_subtask" phx-value-id={st.id} phx-value-todo-id={todo.id} class="cursor-pointer checkbox checkbox-xs" />
                          <div class="flex flex-col">
                            <span class={if st.status == "complete", do: "line-through text-base-content/40", else: "text-base-content/70"}>{st.title}</span>
                            <span :if={st.description && st.description != ""} class="text-[10px] text-base-content/40">{st.description}</span>
                          </div>
                        </div>
                        <div class="flex items-center gap-2">
                          <form phx-change="update_subtask_status" phx-value-id={st.id} phx-value-todo-id={todo.id} id={"subtask-status-#{st.id}"}>
                          <select name="status" class={"px-1 py-0.5 rounded text-[10px] border outline-none #{status_style(st.status)}"}>
                            <option value="in-progress" selected={st.status == "in-progress"}>IN-PROGRESS</option>
                            <option value="on-hold" selected={st.status == "on-hold"}>ON-HOLD</option>
                            <option value="complete" selected={st.status == "complete"}>COMPLETE</option>
                          </select>
                          </form>
                          <button phx-click="delete_subtask" phx-value-id={st.id} phx-value-todo-id={todo.id} class="text-error p-1">
                            <svg xmlns="http://www.w3.org/2000/svg" class="w-3.5 h-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6" /><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2" /></svg>
                          </button>
                        </div>
                      </div>
                    </div>
                  <% end %>

                  <form :if={@adding_subtask_for == to_string(todo.id)} phx-submit="add_subtask" phx-change="update_subtask_form" phx-value-todo-id={todo.id} class="flex gap-2 mt-2">
                    <input type="text" name="subtask[title]" placeholder="Add Subtask" value={@new_subtask_title} autofocus class="flex-1 text-sm px-2 py-1 rounded border border-base-300 bg-base-100 focus:outline-none" />
                    <button type="submit" class="text-[11px] bg-neutral text-neutral-content px-2 py-1 rounded">Add</button>
                    <button type="button" phx-click="cancel_add_subtask" class="text-[11px] text-base-content/50 border px-1 rounded">Cancel</button>
                  </form>
                </div>
              </div>
            </div>




        <% end %>

        <%!-- Pagination --%>
          <div class="flex items-center justify-center gap-4 mt-8">
          <button disabled={@page == 1} phx-click="prev_page" class="px-4 py-1.5 border rounded-md text-sm disabled:opacity-40 hover:bg-base-200 transition">Prev</button>
          <span class="text-sm text-base-content/60">
            Page <span class="font-medium">{if @total_pages == 0, do: 0, else: @page}</span> of <span class="font-medium">{@total_pages}</span>
          </span>
          <button disabled={@page >= @total_pages} phx-click="next_page" class="px-4 py-1.5 border rounded-md text-sm disabled:opacity-40 hover:bg-base-200 transition">Next</button>
        </div>

        <%!-- Delete Modal --%>
        <div :if={@delete_modal_todo} class="fixed inset-0 flex items-center justify-center z-50">
          <div class="absolute inset-0 bg-black/5" phx-click="close_delete_modal"></div>
          <div class="relative bg-base-100 w-full max-w-md rounded-xl shadow-xl p-6 z-10">
            <h2 class="text-xl font-semibold mb-4">Delete Todo</h2>
            <div class="mb-6 text-base-content/60">
              Are you sure you want to delete this todo
              <span class="font-semibold text-base-content">"{@delete_modal_todo.title}"</span>?
            </div>
            <div class="flex justify-end gap-3">
              <button phx-click="close_delete_modal" class="px-4 py-2 rounded-lg border border-base-300 hover:bg-base-200 transition">Cancel</button>
              <button phx-click="confirm_delete" class="px-4 py-2 rounded-lg bg-error text-error-content hover:opacity-80 transition">Yes, Delete</button>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # helper code
  defp status_options do
    [
      %{label: "ALL", value: ""},
      %{label: "COMPLETED", value: "complete"},
      %{label: "ON HOLD", value: "on-hold"},
      %{label: "IN PROGRESS", value: "in-progress"}
    ]
  end

  defp status_style("in-progress"), do: "bg-info/10 text-info border-info/20"
  defp status_style("on-hold"), do: "bg-warning/10 text-warning border-warning/20"
  defp status_style("complete"), do: "bg-success/10 text-success border-success/20"
  defp status_style(_), do: ""

  defp rating_float(nil), do: 0.0
  defp rating_float(%Decimal{} = d), do: Decimal.to_float(d)
  defp rating_float(r) when is_float(r), do: r
  defp rating_float(r) when is_integer(r), do: r * 1.0

  defp rating_float(r) when is_binary(r) do
    case Float.parse(r) do
      {f, _} -> f
      :error -> 0.0
    end
  end

  defp rating_float(_), do: 0.0

  defp format_rating(nil), do: "0.0"

  defp format_rating(%Decimal{} = d),
    do: :erlang.float_to_binary(Decimal.to_float(d), decimals: 1)

  defp format_rating(r), do: :erlang.float_to_binary(rating_float(r), decimals: 1)

  defp star_rating(assigns) do
    assigns = assign(assigns, stars: 1..5)

    ~H"""
    <div class="flex gap-1">
      <svg :for={star <- @stars} phx-click="update_rating" phx-value-id={@todo_id} phx-value-rating={star} class={"w-5 h-5 cursor-pointer transition-colors #{star_color(@value, star)}"} fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg">
        <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.286 3.946a1 1 0 00.95.69h4.15c.969 0 1.371 1.24.588 1.81l-3.36 2.44a1 1 0 00-.364 1.118l1.287 3.945c.3.922-.755 1.688-1.54 1.118l-3.36-2.44a1 1 0 00-1.176 0l-3.36 2.44c-.784.57-1.838-.196-1.539-1.118l1.287-3.945a1 1 0 00-.364-1.118L2.037 9.373c-.784-.57-.38-1.81.588-1.81h4.15a1 1 0 00.95-.69l1.286-3.946z" />
      </svg>
    </div>
    """
  end

  defp star_color(value, star) do
    cond do
      value >= star -> "text-yellow-400"
      value >= star - 0.5 -> "text-yellow-300"
      true -> "text-base-content/20"
    end
  end
end
