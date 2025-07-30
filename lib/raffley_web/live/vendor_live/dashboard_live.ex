defmodule RaffleyWeb.VendorLive.DashboardLive do
  use RaffleyWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Vendor Dashboard")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-4">
      <div class="flex items-center justify-between mb-8">
        <h1 class="text-3xl font-bold">Vendor Dashboard</h1>
        <div class="stats shadow">
          <div class="stat">
            <div class="stat-title">Vendor Status</div>
            <div class="stat-value text-primary">Active</div>
          </div>
        </div>
      </div>

      <div class="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
        <div class="card bg-base-100 shadow">
          <div class="card-body">
            <h2 class="card-title">
              <.icon name="hero-shopping-bag" class="icon-large" /> Products
            </h2>
            <p class="text-muted">Manage your products and inventory</p>
            <div class="card-actions justify-end mt-4">
              <button class="btn btn-primary btn-sm" disabled>Coming Soon</button>
            </div>
          </div>
        </div>

        <div class="card bg-base-100 shadow">
          <div class="card-body">
            <h2 class="card-title">
              <.icon name="hero-chart-bar" class="icon-large" /> Analytics
            </h2>
            <p class="text-muted">View sales and performance metrics</p>
            <div class="card-actions justify-end mt-4">
              <button class="btn btn-primary btn-sm" disabled>Coming Soon</button>
            </div>
          </div>
        </div>

        <div class="card bg-base-100 shadow">
          <div class="card-body">
            <h2 class="card-title">
              <.icon name="hero-cog-6-tooth" class="icon-large" /> Settings
            </h2>
            <p class="text-muted">Configure your vendor preferences</p>
            <div class="card-actions justify-end mt-4">
              <button class="btn btn-primary btn-sm" disabled>Coming Soon</button>
            </div>
          </div>
        </div>
      </div>

      <div class="card bg-base-100 shadow-xl mt-8">
        <div class="card-body">
          <h2 class="card-title mb-4">Quick Stats</h2>
          <div class="stats stats-vertical lg:stats-horizontal shadow w-full">
            <div class="stat">
              <div class="stat-title">Total Products</div>
              <div class="stat-value">0</div>
              <div class="stat-desc">No products yet</div>
            </div>

            <div class="stat">
              <div class="stat-title">Total Sales</div>
              <div class="stat-value">$0</div>
              <div class="stat-desc">No sales yet</div>
            </div>

            <div class="stat">
              <div class="stat-title">Active Orders</div>
              <div class="stat-value">0</div>
              <div class="stat-desc">No active orders</div>
            </div>
          </div>
        </div>
      </div>

      <div class="card bg-base-100 shadow-xl mt-8">
        <div class="card-body">
          <h2 class="card-title mb-4">Recent Activity</h2>
          <div class="text-center py-8 opacity-70">
            <.icon name="hero-inbox" class="w-12 h-12 mx-auto mb-4 opacity-50" />
            <p>No recent activity to display</p>
            <p class="text-sm mt-2">Your vendor activity will appear here</p>
          </div>
        </div>
      </div>

      <div class="alert alert-info mt-8">
        <.icon name="hero-information-circle" class="icon-default shrink-0" />
        <div>
          <h3 class="font-bold">Welcome to the Vendor Dashboard!</h3>
          <p class="text-sm">
            This is your vendor control panel. More features will be added soon to help you manage your products, orders, and sales.
          </p>
        </div>
      </div>
    </div>
    """
  end
end
