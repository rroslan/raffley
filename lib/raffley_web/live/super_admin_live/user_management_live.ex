defmodule RaffleyWeb.SuperAdminLive.UserManagementLive do
  use RaffleyWeb, :live_view
  
  alias Raffley.Accounts

  @impl true
  def mount(_params, _session, socket) do
    alias Raffley.Accounts.User
    registration_changeset = User.email_changeset(%User{}, %{})
    
    socket = 
      socket
      |> assign(:users, Accounts.list_users())
      |> assign(:registration_changeset, registration_changeset)
      |> assign(:registration_error, nil)
      |> assign(:registration_success, nil)
      |> assign(:sort_by, :email)  # Add this
      |> assign(:sort_order, :asc)  # Add this
      |> assign(:loading_user_id, nil)  # Add this
    
    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  # Group all handle_event callbacks together
  @impl true
  def handle_event("register_user", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        login_url_fun = fn token ->
          url = ~p"/users/log-in/#{token}"
          url_string = RaffleyWeb.Endpoint.url() <> url
          url_string
        end
        
        Accounts.deliver_login_instructions(user, login_url_fun)
        
        alias Raffley.Accounts.User
        registration_changeset = User.email_changeset(%User{}, %{})
        
        # Get sorted users after registration
        sorted_users = sort_users(Accounts.list_users(), socket.assigns.sort_by, socket.assigns.sort_order)
        
        socket = 
          socket
          |> assign(:users, sorted_users)
          |> assign(:registration_changeset, registration_changeset)
          |> assign(:registration_error, nil)
          |> assign(:registration_success, "User #{user.email} registered successfully. A login link has been sent to this email address.")
        
        {:noreply, socket}
      
      {:error, changeset} ->
        error_message = error_message_from_changeset(changeset)
        
        socket = 
          socket
          |> assign(:registration_changeset, changeset)
          |> assign(:registration_error, "Registration failed: #{error_message}")
          |> assign(:registration_success, nil)
        
        {:noreply, socket}
    end
  end

  # Add sorting event handler
  @impl true
  def handle_event("sort", %{"by" => sort_by}, socket) do
    current_sort_by = String.to_existing_atom(sort_by)
    current_sort_order = socket.assigns.sort_order
    
    new_order = if socket.assigns.sort_by == current_sort_by do
      case current_sort_order do
        :asc -> :desc
        :desc -> :asc
      end
    else
      :asc
    end

    sorted_users = sort_users(socket.assigns.users, current_sort_by, new_order)

    {:noreply,
     socket
     |> assign(sort_by: current_sort_by)
     |> assign(sort_order: new_order)
     |> assign(users: sorted_users)}
  end

  @impl true
  def handle_event("toggle_admin", %{"id" => id}, socket) do
    socket = assign(socket, :loading_user_id, id)
    user = Accounts.get_user!(id)
    current_user = socket.assigns.current_scope.user
    
    # Toggle the current status
    new_status = !user.is_admin
    
    if Accounts.can_modify_user_status?(current_user, user) do
      case Accounts.update_user_admin_status(user, new_status) do
        {:ok, _updated_user} ->
          socket = 
            socket
            |> put_flash(:info, "Admin status updated successfully.")
            |> assign(:users, sort_users(Accounts.list_users(), socket.assigns.sort_by, socket.assigns.sort_order))
            |> assign(:loading_user_id, nil)
          
          {:noreply, socket}
        {:error, _changeset} ->
          socket = 
            socket
            |> put_flash(:error, "Failed to update admin status.")
            |> assign(:loading_user_id, nil)
          {:noreply, socket}
      end
    else
      socket = 
        socket
        |> put_flash(:error, "You don't have permission to modify this user.")
        |> assign(:loading_user_id, nil)
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("toggle_super_admin", %{"id" => id}, socket) do
    socket = assign(socket, :loading_user_id, id)
    user = Accounts.get_user!(id)
    current_user = socket.assigns.current_scope.user
    
    # Toggle the current status
    new_status = !user.is_super_admin
    
    if Accounts.can_modify_user_status?(current_user, user) do
      case Accounts.update_user_super_admin_status(user, new_status) do
        {:ok, _updated_user} ->
          socket = 
            socket
            |> put_flash(:info, "Super admin status updated successfully.")
            |> assign(:users, sort_users(Accounts.list_users(), socket.assigns.sort_by, socket.assigns.sort_order))
            |> assign(:loading_user_id, nil)
          
          {:noreply, socket}
        {:error, _changeset} ->
          socket = 
            socket
            |> put_flash(:error, "Failed to update super admin status.")
            |> assign(:loading_user_id, nil)
          {:noreply, socket}
      end
    else
      socket = 
        socket
        |> put_flash(:error, "You don't have permission to modify this user.")
        |> assign(:loading_user_id, nil)
      {:noreply, socket}
    end
  end

  # Helper functions

  defp error_message_from_changeset(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
    |> Enum.map(fn {key, errors} -> "#{key} #{Enum.join(errors, ", ")}" end)
    |> Enum.join("; ")
  end

  # Add this function to sort users
  defp sort_users(users, sort_by, sort_order) do
    Enum.sort_by(users, fn user ->
      case sort_by do
        :email -> user.email
        :status ->
          cond do
            user.is_super_admin -> 2
            user.is_admin -> 1
            true -> 0
          end
      end
    end, sort_order)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-8">
      <div class="flex justify-between items-center">
        <h1 class="text-3xl font-bold">User Management</h1>
        <div class="stats shadow">
          <div class="stat">
            <div class="stat-title">Total Users</div>
            <div class="stat-value"><%= length(@users) %></div>
          </div>
        </div>
      </div>

      <div class="card bg-base-100 shadow">
        <div class="card-body">
          <h2 class="card-title">Register New User</h2>
          
          <%= if @registration_success do %>
            <div class="alert alert-success">
              <.icon name="hero-check-circle" class="h-5 w-5" />
              <%= @registration_success %>
            </div>
          <% end %>

          <%= if @registration_error do %>
            <div class="alert alert-error">
              <.icon name="hero-exclamation-circle" class="h-5 w-5" />
              <%= @registration_error %>
            </div>
          <% end %>

          <.form for={@registration_changeset} phx-submit="register_user" class="space-y-4">
            <div class="form-control w-full">
              <label class="label" for="user_email">
                <span class="label-text">Email</span>
              </label>
              <input
                type="email"
                name="user[email]"
                id="user_email"
                class="input input-bordered w-full"
                required
              />
            </div>
            <.button class="btn btn-primary w-full">Register User</.button>
          </.form>
        </div>
      </div>

      <div class="card bg-base-100 shadow">
        <div class="card-body">
          <h2 class="card-title">User List</h2>
          
          <div class="overflow-x-auto">
            <%= if Enum.empty?(@users) do %>
              <div class="text-center py-8">
                <.icon name="hero-users" class="h-12 w-12 mx-auto text-base-content/30" />
                <p class="mt-4 text-base-content/70">No users found</p>
              </div>
            <% else %>
              <table class="table">
                <thead>
                  <tr>
                    <th>
                      <button
                        phx-click="sort"
                        phx-value-by="email"
                        class="inline-flex items-center gap-1 hover:text-primary"
                      >
                        Email
                        <%= if @sort_by == :email do %>
                          <.icon
                            name={if @sort_order == :asc, do: "hero-chevron-up", else: "hero-chevron-down"}
                            class="h-4 w-4"
                          />
                        <% end %>
                      </button>
                    </th>
                    <th>
                      <button
                        phx-click="sort"
                        phx-value-by="status"
                        class="inline-flex items-center gap-1 hover:text-primary"
                      >
                        Status
                        <%= if @sort_by == :status do %>
                          <.icon
                            name={if @sort_order == :asc, do: "hero-chevron-up", else: "hero-chevron-down"}
                            class="h-4 w-4"
                          />
                        <% end %>
                      </button>
                    </th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  <%= for user <- @users do %>
                  <tr class="hover">
                    <td><%= user.email %></td>
                    <td>
                      <%= cond do %>
                        <% user.is_super_admin -> %>
                          <span class="badge badge-accent">Super Admin</span>
                        <% user.is_admin -> %>
                          <span class="badge badge-info">Admin</span>
                        <% true -> %>
                          <span class="badge">User</span>
                      <% end %>
                    </td>
                    <td>
                      <div class="flex flex-row gap-2">
                        <%= unless user.id == @current_scope.user.id do %>
                          <label class="label cursor-pointer gap-2">
                            <span class="label-text">Admin</span>
                            <div class="relative">
                              <input
                                type="checkbox"
                                class="toggle toggle-info"
                                checked={user.is_admin}
                                phx-click="toggle_admin"
                                phx-value-id={user.id}
                                disabled={@loading_user_id == user.id}
                              />
                              <%= if @loading_user_id == user.id do %>
                                <div class="absolute inset-0 flex items-center justify-center">
                                  <div class="loading loading-spinner loading-xs"></div>
                                </div>
                              <% end %>
                            </div>
                          </label>

                          <label class="label cursor-pointer gap-2">
                            <span class="label-text">Super</span>
                            <div class="relative">
                              <input
                                type="checkbox"
                                class="toggle toggle-accent"
                                checked={user.is_super_admin}
                                phx-click="toggle_super_admin"
                                phx-value-id={user.id}
                                disabled={@loading_user_id == user.id}
                              />
                              <%= if @loading_user_id == user.id do %>
                                <div class="absolute inset-0 flex items-center justify-center">
                                  <div class="loading loading-spinner loading-xs"></div>
                                </div>
                              <% end %>
                            </div>
                          </label>
                        <% end %>
                      </div>
                    </td>
                  </tr>
                <% end %>
                </tbody>
              </table>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
