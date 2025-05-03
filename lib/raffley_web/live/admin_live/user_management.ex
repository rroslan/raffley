defmodule RaffleyWeb.AdminLive.UserManagement do
  use RaffleyWeb, :live_view
  
  alias Raffley.Accounts

  # Require super admin for this LiveView
  on_mount {RaffleyWeb.UserAuth, :ensure_super_admin}

  # Mount callback
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
        
        socket = 
          socket
          |> assign(:users, Accounts.list_users())
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

  @impl true
  def handle_event("toggle_admin", %{"id" => id, "status" => status}, socket) do
    user = Accounts.get_user!(id)
    current_user = socket.assigns.current_scope.user
    
    new_status = parse_boolean_status(status)
    
    if Accounts.can_modify_user_status?(current_user, user) do
      case Accounts.update_user_admin_status(user, new_status) do
        {:ok, _updated_user} ->
          socket = 
            socket
            |> put_flash(:info, "Admin status updated successfully.")
            |> assign(:users, Accounts.list_users())
          
          {:noreply, socket}
        {:error, _changeset} ->
          socket = put_flash(socket, :error, "Failed to update admin status.")
          {:noreply, socket}
      end
    else
      socket = put_flash(socket, :error, "You don't have permission to modify this user.")
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("toggle_super_admin", %{"id" => id, "status" => status}, socket) do
    user = Accounts.get_user!(id)
    current_user = socket.assigns.current_scope.user
    
    new_status = parse_boolean_status(status)
    
    if Accounts.can_modify_user_status?(current_user, user) do
      case Accounts.update_user_super_admin_status(user, new_status) do
        {:ok, _updated_user} ->
          socket = 
            socket
            |> put_flash(:info, "Super admin status updated successfully.")
            |> assign(:users, Accounts.list_users())
          
          {:noreply, socket}
        {:error, _changeset} ->
          socket = put_flash(socket, :error, "Failed to update super admin status.")
          {:noreply, socket}
      end
    else
      socket = put_flash(socket, :error, "You don't have permission to modify this user.")
      {:noreply, socket}
    end
  end

  # Helper functions
  defp parse_boolean_status(status) do
    case status do
      "true" -> true
      "false" -> false
      true -> true
      false -> false
      _ -> status == "true"
    end
  end

  defp error_message_from_changeset(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
    |> Enum.map(fn {key, errors} -> "#{key} #{Enum.join(errors, ", ")}" end)
    |> Enum.join("; ")
  end
end
