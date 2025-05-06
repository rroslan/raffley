defmodule RaffleyWeb.AdminLive.DashboardLive do
  use RaffleyWeb, :live_view

  alias Raffley.Accounts

  @impl true
  def mount(_params, _session, socket) do
    socket = socket
    |> assign(:user_count, Accounts.count_users())
    |> assign(:page_title, "Admin Dashboard")

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-8">
      <h1 class="text-3xl font-bold">Admin Dashboard</h1>
      
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div class="card bg-base-100 shadow">
          <div class="card-body">
            <h2 class="card-title">Total Users</h2>
            <p class="text-4xl font-bold"><%= @user_count %></p>
          </div>
        </div>
        
        <div class="card bg-base-100 shadow">
          <div class="card-body">
            <h2 class="card-title">Your Role</h2>
            <p class="text-xl">Administrator</p>
          </div>
        </div>
      </div>

      <div class="card bg-base-100 shadow">
        <div class="card-body">
          <h2 class="card-title">Quick Actions</h2>
          <div class="space-y-4">
            <%= if @current_scope.user.is_super_admin do %>
              <.link
                navigate={~p"/admin/super/users"}
                class="btn btn-primary w-full"
              >
                Manage Users
              </.link>
              <.link
                navigate={~p"/admin/super"}
                class="btn btn-secondary w-full"
              >
                Super Admin Dashboard
              </.link>
            <% else %>
              <p class="text-base-content/70 italic">User management is restricted to super administrators.</p>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end
end

