defmodule RaffleyWeb.SuperAdminLive.SuperDashboardLive do
  use RaffleyWeb, :live_view

  alias Raffley.Accounts

  @impl true
  def mount(_params, _session, socket) do
    socket = socket
    |> assign(:user_count, Accounts.count_users())
    |> assign(:admin_count, Accounts.count_admin_users())
    |> assign(:super_admin_count, Accounts.count_super_admin_users())
    |> assign(:page_title, "Super Admin Dashboard")

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
      <h1 class="text-3xl font-bold">Super Admin Dashboard</h1>
      
      <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div class="card bg-base-100 shadow">
          <div class="card-body">
            <h2 class="card-title">Total Users</h2>
            <p class="text-4xl font-bold"><%= @user_count %></p>
          </div>
        </div>
        
        <div class="card bg-base-100 shadow">
          <div class="card-body">
            <h2 class="card-title">Admin Users</h2>
            <p class="text-4xl font-bold"><%= @admin_count %></p>
          </div>
        </div>
        
        <div class="card bg-base-100 shadow">
          <div class="card-body">
            <h2 class="card-title">Super Admin Users</h2>
            <p class="text-4xl font-bold"><%= @super_admin_count %></p>
          </div>
        </div>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div class="card bg-base-100 shadow">
          <div class="card-body">
            <h2 class="card-title">Quick Actions</h2>
            <div class="space-y-4">
              <.link
                navigate={~p"/admin/super/users"}
                class="btn btn-primary w-full"
              >
                Manage Users
              </.link>
            </div>
          </div>
        </div>

        <div class="card bg-base-100 shadow">
          <div class="card-body">
            <h2 class="card-title">System Status</h2>
            <div class="space-y-2">
              <p class="flex justify-between">
                <span>Environment:</span>
                <span class="font-semibold"><%= Application.get_env(:raffley, :environment) %></span>
              </p>
              <p class="flex justify-between">
                <span>Version:</span>
                <span class="font-semibold"><%= Application.spec(:raffley, :vsn) %></span>
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
