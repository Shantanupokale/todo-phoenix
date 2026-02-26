defmodule TodoBuddyWeb.LoginLive do
  use TodoBuddyWeb, :live_view

  alias TodoBuddy.Accounts

  def mount(_params, session, socket) do
    if session["user_id"] do
      {:ok, push_navigate(socket, to: ~p"/dashboard")}
    else
      {:ok,
       assign(socket,
         email: "",
         password: "",
         loading: false,
         error: nil
       )}
    end
  end

  def handle_event("validate", %{"email" => email, "password" => password}, socket) do
    {:noreply, assign(socket, email: email, password: password, error: nil)}
  end

  def handle_event("login", %{"email" => email, "password" => password}, socket) do
    socket = assign(socket, loading: true)

    case Accounts.authenticate_user(email, password) do
      {:ok, user} ->
        {:noreply,
         socket
         |> assign(loading: false)
         |> redirect(to: ~p"/auth/callback?user_id=#{user.id}")}

      {:error, _reason} ->
        {:noreply,
         socket
         |> assign(loading: false, error: "Invalid credentials")}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-100 flex flex-col justify-center items-center px-6 font-sans">
      <div class="absolute top-6 left-6">
        <.link
          navigate={~p"/"}
          class="flex items-center gap-2 text-sm font-medium text-base-content/50 hover:text-base-content transition-colors"
        >
          <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M19 12H5" /><path d="M12 19l-7-7 7-7" />
          </svg>
          Back to Home
        </.link>
      </div>

      <div class="w-full max-w-sm">
        <div class="mb-8 text-center">
          <h1 class="text-3xl font-semibold italic tracking-tight mb-2">Welcome back</h1>
          <p class="text-base-content/50">Enter your credentials to access your account</p>
        </div>

        <form phx-submit="login" phx-change="validate" class="flex flex-col gap-4">
          <div class="space-y-1">
            <label class="text-sm font-medium">Email</label>
            <input
              type="email"
              name="email"
              placeholder="name@example.com"
              value={@email}
              class="w-full border border-base-300 bg-base-100 px-4 py-2.5 rounded-lg transition-all focus:outline-none focus:border-primary"
              required
            />
          </div>

          <div class="space-y-1">
            <label class="text-sm font-medium">Password</label>
            <input
              type="password"
              name="password"
              placeholder="••••••••"
              value={@password}
              class="w-full border border-base-300 bg-base-100 px-4 py-2.5 rounded-lg transition-all focus:outline-none focus:border-primary"
              required
            />
          </div>

          <div :if={@error} class="text-error text-sm font-medium">{@error}</div>

          <button
            type="submit"
            disabled={@loading}
            class="mt-2 w-full bg-black text-neutral-content font-medium py-3 rounded-lg hover:opacity-80 disabled:cursor-not-allowed transition"
          >
            {if @loading, do: "Signing in...", else: "Sign In"}
          </button>
        </form>

        <p class="mt-8 text-center text-sm text-base-content/50">
          Don't have an account?
          <.link navigate={~p"/register"} class="font-bold text-base-content hover:underline">
            Sign up
          </.link>
        </p>
      </div>
    </div>
    """
  end
end
