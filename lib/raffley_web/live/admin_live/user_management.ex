defmodule RaffleyWeb.AdminLive.UserManagement do
  use RaffleyWeb, :live_view
  
  alias Raffley.Accounts
  alias Raffley.Accounts.User

  # Require super admin for this LiveView
  on_mount {RaffleyWeb.UserAuth, :require_super_admin}

  @impl true
  def mount(_params, _session, socket) do
    users = Accounts.list_users()
    
    socket = 
      socket
      |> assign(:page_title, "User Management")
      |> assign(:users, users)
      |> assign(:selected_user, nil)
      |> assign(:show_modal, false)
    
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _uri, socket) do
    user = Accounts.get_user!(id)
    changeset = Accounts.change_user_admin_status(user)
    
    socket = 
      socket
      |> assign(:selected_user, user)
      |> assign(:changeset, changeset)
      |> assign(:show_modal, true)
    
    {:noreply, socket}
  end
  
  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("close_modal", _, socket) do
    socket = 
      socket
      |> assign(:show_modal, false)
      |> push_patch(to: ~p"/admin/users")
    
    {:noreply, socket}
  end

  @impl true
  def handle_event("edit_user", %{"id" => id}, socket) do
    {:noreply, push_patch(socket, to: ~p"/admin/users/#{id}")}
  end

  @impl true
  def handle_event("save", %{"user" => user_params}, socket) do
    user = socket.assigns.selected_user
    current_scope = socket.assigns.current_scope
    
    if Accounts.can_modify_user_status?(current_scope, user) do
      case Accounts.update_user_admin_status(user, user_params) do
        {:ok, _updated_user} ->
          socket = 
            socket
            |> put_flash(:info, "User permissions updated successfully.")
            |> assign(:users, Accounts.list_users())
            |> assign(:show_modal, false)
            |> push_patch(to: ~p"/admin/users")
          
          {:noreply, socket}
          
        {:error, changeset} ->
          {:noreply, assign(socket, :changeset, changeset)}
      end
    else
      socket = 
        socket
        |> put_flash(:error, "You don't have permission to modify this user.")
        |> assign(:show_modal, false)
        |> push_patch(to: ~p"/admin/users")
      
      {:noreply, socket}
    end
  end
end

