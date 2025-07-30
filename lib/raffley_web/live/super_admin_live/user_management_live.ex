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
      # Add this
      |> assign(:sort_by, :email)
      # Add this
      |> assign(:sort_order, :asc)
      # Add this
      |> assign(:loading_user_id, nil)

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
        # Create a scope for the new user
        # Generate login URL with magic link
        login_url_fun = fn token ->
          url = ~p"/users/log-in/#{token}"
          url_string = RaffleyWeb.Endpoint.url() <> url
          url_string
        end

        Accounts.deliver_login_instructions(user, login_url_fun)

        alias Raffley.Accounts.User
        registration_changeset = User.email_changeset(%User{}, %{})

        # Get sorted users after registration
        sorted_users =
          sort_users(Accounts.list_users(), socket.assigns.sort_by, socket.assigns.sort_order)

        socket =
          socket
          |> assign(:users, sorted_users)
          |> assign(:registration_changeset, registration_changeset)
          |> assign(:registration_error, nil)
          |> assign(
            :registration_success,
            "User #{user.email} registered successfully. A login link has been sent to this email address."
          )

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

    new_order =
      if socket.assigns.sort_by == current_sort_by do
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
  def handle_event("toggle_vendor", %{"id" => id}, socket) do
    socket = assign(socket, :loading_user_id, id)
    user = Accounts.get_user!(id)
    # Toggle the current status
    new_status = !user.is_vendor

    IO.puts(
      "TOGGLE_VENDOR: User #{user.email} - Current is_vendor: #{user.is_vendor}, New: #{new_status}"
    )

    case Accounts.update_user_vendor_status(user, new_status) do
      {:ok, updated_user} ->
        IO.puts(
          "TOGGLE_VENDOR: Successfully updated user #{updated_user.email} - is_vendor now: #{updated_user.is_vendor}"
        )

        # Get fresh users data and apply current sorting
        fresh_users = Accounts.list_users()

        IO.puts(
          "TOGGLE_VENDOR: Fresh users loaded. Vendor count: #{Enum.count(fresh_users, & &1.is_vendor)}"
        )

        sorted_users = sort_users(fresh_users, socket.assigns.sort_by, socket.assigns.sort_order)

        {:noreply,
         socket
         |> put_flash(:info, "Vendor status updated successfully.")
         |> assign(:users, sorted_users)
         |> assign(:loading_user_id, nil)}

      {:error, changeset} ->
        IO.puts("TOGGLE_VENDOR: Failed to update - #{inspect(changeset.errors)}")

        {:noreply,
         socket
         |> put_flash(:error, "Failed to update vendor status: #{inspect(changeset.errors)}")
         |> assign(:loading_user_id, nil)}
    end
  end

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
            |> assign(
              :users,
              sort_users(Accounts.list_users(), socket.assigns.sort_by, socket.assigns.sort_order)
            )
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
            |> assign(
              :users,
              sort_users(Accounts.list_users(), socket.assigns.sort_by, socket.assigns.sort_order)
            )
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
    Enum.sort_by(
      users,
      fn user ->
        case sort_by do
          :email ->
            user.email

          :status ->
            # Calculate a score based on all roles
            # Super admin = 4, Admin = 2, Vendor = 1, User = 0
            # These can combine (e.g., Admin + Vendor = 3)
            score = 0
            score = if user.is_super_admin, do: score + 4, else: score
            score = if user.is_admin and not user.is_super_admin, do: score + 2, else: score
            score = if user.is_vendor, do: score + 1, else: score
            score
        end
      end,
      sort_order
    )
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-8">
      <div class="flex justify-between items-center">
        <h1 class="text-3xl font-bold">User Management</h1>
        <div class="flex gap-2 items-center">
          <span class="badge-vendor">Test Vendor Badge</span>
          <span class="badge-admin">Test Admin Badge</span>
          <span class="badge-super-admin">Test Super Badge</span>
        </div>
        <div class="stats shadow">
          <div class="stat">
            <div class="stat-title">Total Users</div>
            <div class="stat-value">{length(@users)}</div>
          </div>
        </div>
      </div>

      <div class="card bg-base-100 shadow-xl">
        <div class="card-body">
          <h2 class="card-title">Register New User</h2>

          <%= if @registration_success do %>
            <div class="alert alert-success">
              <.icon name="hero-check-circle" class="icon-default" />
              {@registration_success}
            </div>
          <% end %>

          <%= if @registration_error do %>
            <div class="alert alert-error">
              <.icon name="hero-exclamation-circle" class="icon-default" />
              {@registration_error}
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

      <div class="card bg-base-100 shadow-xl">
        <div class="card-body">
          <h2 class="card-title">User List</h2>

          <div class="overflow-x-auto">
            <%= if Enum.empty?(@users) do %>
              <div class="text-center py-8">
                <p class="text-muted">No users found</p>
              </div>
            <% else %>
              <table class="table table-zebra">
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
                            name={
                              if @sort_order == :asc, do: "hero-chevron-up", else: "hero-chevron-down"
                            }
                            class="icon-small"
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
                            name={
                              if @sort_order == :asc, do: "hero-chevron-up", else: "hero-chevron-down"
                            }
                            class="icon-small"
                          />
                        <% end %>
                      </button>
                    </th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  <%= for user <- @users do %>
                    <tr class="user-table-row">
                      <td>{user.email}</td>
                      <td>
                        <div class="flex flex-wrap gap-1">
                          <%= if user.is_super_admin do %>
                            <span class="badge-super-admin">Super Admin</span>
                          <% end %>
                          <%= if user.is_admin and not user.is_super_admin do %>
                            <span class="badge-admin">Admin</span>
                          <% end %>
                          <%= if user.is_vendor do %>
                            <span class="badge-vendor">Vendor</span>
                          <% end %>
                          <%= if not user.is_super_admin and not user.is_admin and not user.is_vendor do %>
                            <span class="badge-user">User</span>
                          <% end %>
                        </div>
                      </td>
                      <td>
                        <div class="user-actions">
                          <%= unless user.id == @current_scope.user.id do %>
                            <label class="label cursor-pointer gap-2">
                              <span class="label-text">Admin</span>
                              <div class="relative">
                                <input
                                  type="checkbox"
                                  class="toggle-admin"
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
                                  class="toggle-super-admin"
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

                            <label class="label cursor-pointer gap-2">
                              <span class="label-text">Vendor</span>
                              <div class="relative">
                                <input
                                  type="checkbox"
                                  class="toggle-vendor"
                                  checked={user.is_vendor}
                                  phx-click="toggle_vendor"
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
