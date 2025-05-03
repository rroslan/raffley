defmodule RaffleyWeb.AdminController do
  use RaffleyWeb, :controller

  def index(conn, _params) do
    if conn.assigns.current_scope.user.is_super_admin do
      redirect(conn, to: ~p"/admin/super/users")
    else
      render(conn, :index)
    end
  end

  def redirect_to_user_management(conn, _params) do
    redirect(conn, to: ~p"/admin/super/users")
  end
end
