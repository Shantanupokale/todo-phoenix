defmodule TodoBuddyWeb.LandingLive do
  use TodoBuddyWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end
# # this is added from node-todo landing page
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-100 text-base-content font-sans flex flex-col relative overflow-hidden">
      <nav class="w-full max-w-6xl mx-auto px-6 py-8 flex justify-between items-center">
        <div class="flex items-center gap-2">
          <div class="w-9 h-9 bg-black text-neutral-content flex items-center justify-center rounded-md font-bold text-sm">
            TB
          </div>
          <span class="text-lg font-semibold tracking-tight">TodoBuddy</span>
        </div>
        <.link
          navigate={~p"/login"}
          class="text-sm font-medium border border-neutral px-5 py-2 rounded-md hover:bg-black hover:text-neutral-content transition"
        >
          Sign In
        </.link>
      </nav>

      <main class="flex-1 flex flex-col max-w-6xl mx-auto w-full px-6">
        <div class="flex flex-col md:flex-row items-center justify-between gap-12 mt-20">
          <div class="flex-1 text-left">
            <h1 class="text-5xl md:text-7xl font-semibold tracking-tight leading-[1.1]">
              Your all-in-one <br />
              <span class="italic font-medium">to-do platform</span>
            </h1>
            <p class="mt-8 text-base-content/60 max-w-xl text-lg leading-relaxed">
              Managing tasks is already challenging enough. Avoid further
              complications by ditching outdated To-Do apps.
            </p>
          </div>

          <div class="flex-1 w-full max-w-2xl">
            <div class="relative group">
              <img
                src="https://www.overflow.design/src/assets/img/nc/to-do-list.jpg"
                alt="To-do list illustration"
                class="w-full h-auto rounded-2xl transition-transform duration-500"
              />
            </div>
          </div>
        </div>

        <div class="mt-8 flex justify-center">
          <.link
            navigate={~p"/register"}
            class="inline-flex items-center gap-2 bg-black text-neutral-content px-10 py-4 rounded-md font-medium hover:bg-base-100 hover:text-base-content border border-transparent hover:border-neutral transition-all shadow-xl hover:shadow-2xl"
          >
            Start for free
            <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" viewBox="0 0 24 24" fill="currentColor">
              <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z" />
            </svg>
          </.link>
        </div>
      </main>

      <footer class="py-8 flex items-center justify-center gap-1.5 text-base-content/40 text-[11px] font-medium tracking-tight">
        <span>Made with</span>
        <svg xmlns="http://www.w3.org/2000/svg" class="w-2.5 h-2.5 fill-red-400 text-red-400" viewBox="0 0 24 24">
          <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z" />
        </svg>
        <span>by</span>
        <a
          href="https://github.com/Shantanupokale/node-todo-frontend"
          target="_blank"
          rel="noopener noreferrer"
          class="text-base-content hover:underline underline-offset-2"
        >
          shantanu
        </a>
      </footer>
    </div>
    """
  end
end
