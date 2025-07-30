defmodule RaffleyWeb.AdminLive.DashboardLive do
  use RaffleyWeb, :live_view

  alias Raffley.Accounts

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Admin Dashboard")
      |> assign(:user_count, Accounts.count_users())
      |> assign(:show_register_form, false)
      |> assign(:email, "")
      |> assign(:is_admin, false)
      |> assign(:is_super_admin, false)
      |> assign(:is_vendor, false)

    {:ok, socket}
  end

  @impl true
  def handle_event("toggle_form", _params, socket) do
    {:noreply, assign(socket, :show_register_form, !socket.assigns.show_register_form)}
  end

  @impl true
  def handle_event("update_email", %{"value" => email}, socket) do
    {:noreply, assign(socket, :email, email)}
  end

  @impl true
  def handle_event("toggle_admin", _params, socket) do
    {:noreply, assign(socket, :is_admin, !socket.assigns.is_admin)}
  end

  @impl true
  def handle_event("toggle_super_admin", _params, socket) do
    {:noreply, assign(socket, :is_super_admin, !socket.assigns.is_super_admin)}
  end

  @impl true
  def handle_event("toggle_vendor", _params, socket) do
    {:noreply, assign(socket, :is_vendor, !socket.assigns.is_vendor)}
  end

  @impl true
  def handle_event("register_user", _params, socket) do
    user_params = %{
      "email" => socket.assigns.email,
      "is_admin" => socket.assigns.is_admin,
      "is_super_admin" => socket.assigns.is_super_admin,
      "is_vendor" => socket.assigns.is_vendor
    }

    case Accounts.register_user(user_params) do
      {:ok, user} ->
        # Send magic link
        login_url_fun = fn token ->
          RaffleyWeb.Endpoint.url() <> ~p"/users/log-in/#{token}"
        end

        Accounts.deliver_login_instructions(user, login_url_fun)

        socket =
          socket
          |> put_flash(:info, "User registered successfully. Login link sent to #{user.email}")
          |> assign(:show_register_form, false)
          |> assign(:email, "")
          |> assign(:is_admin, false)
          |> assign(:is_super_admin, false)
          |> assign(:is_vendor, false)
          |> assign(:user_count, Accounts.count_users())

        {:noreply, socket}

      {:error, changeset} ->
        error =
          changeset.errors
          |> Enum.map(fn {field, {msg, _}} -> "#{field} #{msg}" end)
          |> Enum.join(", ")

        {:noreply, put_flash(socket, :error, "Error: #{error}")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto">
      <h1 class="text-3xl font-bold mb-8">Admin Dashboard</h1>

      <div class="stats shadow mb-8">
        <div class="stat">
          <div class="stat-title">Total Users</div>
          <div class="stat-value">{@user_count}</div>
        </div>
      </div>

      <div class="card bg-base-100 shadow-xl">
        <div class="card-body">
          <div class="flex justify-between items-center mb-4">
            <h2 class="card-title">User Management</h2>
            <button phx-click="toggle_form" class="btn btn-primary btn-sm">
              {if @show_register_form, do: "Cancel", else: "Register User"}
            </button>
          </div>

          <%= if @show_register_form do %>
            <form phx-submit="register_user" class="space-y-4">
              <div>
                <label class="label">
                  <span class="label-text">Email</span>
                </label>
                <input
                  type="email"
                  phx-blur="update_email"
                  value={@email}
                  class="input input-bordered w-full"
                  required
                />
              </div>

              <div class="space-y-2">
                <label class="flex items-center gap-2 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={@is_vendor}
                    phx-click="toggle_vendor"
                    class="checkbox"
                  />
                  <span>Vendor</span>
                </label>

                <label class="flex items-center gap-2 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={@is_admin}
                    phx-click="toggle_admin"
                    class="checkbox"
                  />
                  <span>Administrator</span>
                </label>

                <%= if @current_scope.user.is_super_admin do %>
                  <label class="flex items-center gap-2 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={@is_super_admin}
                      phx-click="toggle_super_admin"
                      class="checkbox"
                    />
                    <span>Super Administrator</span>
                  </label>
                <% end %>
              </div>

              <button type="submit" class="btn btn-primary w-full">
                Register User
              </button>
            </form>
          <% else %>
            <div class="space-y-4">
              <%= if @current_scope.user.is_super_admin do %>
                <.link navigate={~p"/admin/super/users"} class="btn btn-outline w-full">
                  Manage All Users
                </.link>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
