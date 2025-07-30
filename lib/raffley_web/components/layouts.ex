defmodule RaffleyWeb.Layouts do
  @moduledoc """
  This module holds different layouts used by your application.

  See the `layouts` directory for all templates available.
  The "root" layout is a skeleton rendered as part of the
  application router. The "app" layout is rendered as component
  in regular views and live views.
  """
  use RaffleyWeb, :html

  embed_templates "layouts/*"

  slot :inner_block
  attr :current_scope, :map
  attr :flash, :map

  def app(assigns) do
    ~H"""
    <header class="navbar-default">
      <div class="flex-1">
        <.link href="/" class="link-nav">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            width="20"
            height="20"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
            class="md:icon-large"
          >
            <path d="M13 2L3 14h9l-1 8 10-12h-9l1-8z" />
          </svg>
        </.link>
      </div>
      <div class="flex-none">
        <ul class="flex flex-row items-center space-x-2 sm:space-x-4">
          <%= if @current_scope do %>
            <%= if @current_scope.user.is_admin and not @current_scope.user.is_super_admin do %>
              <li class="hidden-mobile">
                <.link href={~p"/admin/dashboard"} class="btn-ghost-nav">
                  Admin
                </.link>
              </li>
            <% end %>

            <li>
              <div class="dropdown dropdown-end">
                <label tabindex="0" class="btn-ghost-nav">
                  <span class="hidden-mobile">{@current_scope.user.email}</span>
                  <.icon name="hero-bars-3" class="hidden-desktop icon-default" />
                </label>
                <ul
                  tabindex="0"
                  class="menu dropdown-content z-[1] p-0.5 shadow bg-base-100 rounded-box w-52 mt-1 text-sm"
                >
                  <%= if @current_scope.user.is_admin and not @current_scope.user.is_super_admin do %>
                    <li class="hidden-desktop">
                      <.link href={~p"/admin/dashboard"} class="py-1">Admin Dashboard</.link>
                    </li>
                  <% end %>
                  <li><.link href={~p"/users/settings"} class="py-1">Settings</.link></li>
                  <li>
                    <.link href={~p"/users/log-out"} method="delete" class="py-1">Log out</.link>
                  </li>
                </ul>
              </div>
            </li>
          <% else %>
            <li>
              <.link
                href={~p"/users/log-in"}
                class="btn btn-ghost btn-sm h-8 min-h-8 sm:h-10 sm:min-h-10"
              >
                Log in
              </.link>
            </li>
          <% end %>

          <li>
            <.theme_toggle />
          </li>
        </ul>
      </div>
    </header>

    <main class="px-2 py-16 sm:px-6 lg:px-8">
      <div class="mx-auto max-w-2xl space-y-4">
        <%= if assigns[:inner_content] do %>
          {@inner_content}
        <% else %>
          {render_slot(@inner_block)}
        <% end %>
      </div>
    </main>

    <.flash_group flash={@flash} />
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Hang in there while we get back on track")}
        <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full scale-90 sm:scale-100">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

      <button
        phx-click={JS.dispatch("phx:set-theme", detail: %{theme: "system"})}
        class="flex p-1 sm:p-1.5 cursor-pointer w-1/3"
      >
        <.icon name="hero-computer-desktop-micro" class="size-3 opacity-75 hover:opacity-100" />
      </button>

      <button
        phx-click={JS.dispatch("phx:set-theme", detail: %{theme: "light"})}
        class="flex p-1 sm:p-1.5 cursor-pointer w-1/3"
      >
        <.icon name="hero-sun-micro" class="size-3 opacity-75 hover:opacity-100" />
      </button>

      <button
        phx-click={JS.dispatch("phx:set-theme", detail: %{theme: "dark"})}
        class="flex p-1 sm:p-1.5 cursor-pointer w-1/3"
      >
        <.icon name="hero-moon-micro" class="size-3 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end

  slot :inner_block
  attr :current_scope, :map
  attr :flash, :map

  def admin(assigns) do
    ~H"""
    <header class="navbar-default">
      <div class="flex-1">
        <.link href="/" class="link-nav">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            width="20"
            height="20"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
            class="md:icon-large"
          >
            <path d="M13 2L3 14h9l-1 8 10-12h-9l1-8z" />
          </svg>
        </.link>
      </div>
      <div class="flex-none">
        <ul class="flex flex-row items-center space-x-2 sm:space-x-4">
          <%= if @current_scope do %>
            <%= if @current_scope.user.is_admin and not @current_scope.user.is_super_admin do %>
              <li class="hidden-mobile">
                <.link href={~p"/admin/dashboard"} class="btn-ghost-nav">
                  Admin
                </.link>
              </li>
            <% end %>

            <li>
              <div class="dropdown dropdown-end">
                <label tabindex="0" class="btn-ghost-nav">
                  <span class="hidden-mobile">{@current_scope.user.email}</span>
                  <.icon name="hero-bars-3" class="hidden-desktop icon-default" />
                </label>
                <ul
                  tabindex="0"
                  class="menu dropdown-content z-[1] p-0.5 shadow bg-base-100 rounded-box w-52 mt-1 text-sm"
                >
                  <%= if @current_scope.user.is_admin and not @current_scope.user.is_super_admin do %>
                    <li class="hidden-desktop">
                      <.link href={~p"/admin/dashboard"} class="py-1">Admin Dashboard</.link>
                    </li>
                  <% end %>
                  <li><.link href={~p"/users/settings"} class="py-1">Settings</.link></li>
                  <li>
                    <.link href={~p"/users/log-out"} method="delete" class="py-1">Log out</.link>
                  </li>
                </ul>
              </div>
            </li>
          <% else %>
            <li>
              <.link
                href={~p"/users/log-in"}
                class="btn btn-ghost btn-sm h-8 min-h-8 sm:h-10 sm:min-h-10"
              >
                Log in
              </.link>
            </li>
          <% end %>

          <li>
            <.theme_toggle />
          </li>
        </ul>
      </div>
    </header>

    <main class="px-2 py-4 sm:px-6 lg:px-8">
      <div class="mx-auto max-w-full lg:max-w-7xl">
        <%= if assigns[:inner_content] do %>
          {@inner_content}
        <% else %>
          {render_slot(@inner_block)}
        <% end %>
      </div>
    </main>

    <.flash_group flash={@flash} />
    """
  end
end
