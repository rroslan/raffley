defmodule RaffleyWeb.AdminLive.AdminLive do
  use RaffleyWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    user = socket.assigns.current_scope.user

    cond do
      # Super admins get redirected to super admin user management
      user.is_super_admin ->
        {:noreply,
         socket
         |> redirect(to: ~p"/admin/super/users")}

      # Regular admins get redirected to admin dashboard (or user management)
      user.is_admin ->
        {:noreply,
         socket
         |> redirect(to: ~p"/admin/dashboard")}

      # Non-admins get redirected to token creation form
      true ->
        {:noreply,
         socket
         |> redirect(to: ~p"/users/token/create")}
    end
  end
end
