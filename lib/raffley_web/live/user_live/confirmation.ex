defmodule RaffleyWeb.UserLive.Confirmation do
  use RaffleyWeb, :live_view

  alias Raffley.Accounts
  alias RaffleyWeb.Layouts
  import RaffleyWeb.CoreComponents

  def render(assigns) do
    ~H"""
    <div class="min-h-[50vh] relative">
      <div class="absolute top-0 left-0 right-0 z-50">
        <Layouts.flash_group flash={@flash} />
      </div>
      <div class="flex items-center justify-center min-h-[90vh]">
        <div class="card w-96 bg-base-100 shadow-xl">
          <div class="card-body">
            <.header class="text-center">
              <%= if @user do %>
                Welcome <%= @user.email %>
              <% else %>
                Log in to Raffley
              <% end %>
            </.header>

          <.form
            :if={@user && !@user.confirmed_at}
            for={@form}
            id="confirmation_form"
            phx-submit="submit"
            action={~p"/users/log-in?_action=confirmed"}
            phx-trigger-action={@trigger_submit}
            class="space-y-4"
          >
            <input type="hidden" name="user[token]" value={@token} />
            <input type="hidden" name="user[return_to]" value={@return_to} />
            <div class="form-control w-full">
              <label class="label" for="confirmation_form_remember_me">
                <span class="label-text">Keep me logged in</span>
              </label>
              <input
                type="checkbox"
                name="user[remember_me]"
                id="confirmation_form_remember_me"
                class="checkbox checkbox-sm"
              />
            </div>
            <.button phx-disable-with="Confirming..." class="w-full btn-primary">
              Confirm my account
            </.button>
          </.form>

          <.form
            :if={@user && @user.confirmed_at}
            for={@form}
            id="login_form"
            phx-submit="submit"
            action={~p"/users/log-in"}
            phx-trigger-action={@trigger_submit}
            class="space-y-4"
          >
            <input type="hidden" name="user[token]" value={@token} />
            <input type="hidden" name="user[return_to]" value={@return_to} />
            <div class="form-control w-full">
              <label class="label" for="login_form_remember_me">
                <span class="label-text">Keep me logged in</span>
              </label>
              <input
                type="checkbox"
                name="user[remember_me]"
                id="login_form_remember_me"
                class="checkbox checkbox-sm"
              />
            </div>
            <.button phx-disable-with="Logging in..." class="w-full btn-primary">
              Log in
            </.button>
          </.form>

            <p :if={@user && !@user.confirmed_at} class="mt-4 text-sm text-base-content/70 text-center">
              Tip: If you prefer passwords, you can enable them in the user settings.
            </p>
          </div>
        </div>
      </div>
    </div>
    """
  end

   def mount(%{"token" => token}, _session, socket) do
    if user = Accounts.get_user_by_magic_link_token(token) do
      # Determine the return path based on user role
      return_path = get_return_path(user)
      
      # Create the form with the return path
      form_data = to_form(%{"return_to" => return_path})

      {:ok,
       socket
       |> assign(
         user: user,
         form: form_data,
         token: token,
         trigger_submit: false,
         return_to: return_path
       ), temporary_assigns: [form: nil]}
    else
      {:ok,
       socket
       |> put_flash(:error, "Magic link is invalid or it has expired.")
       |> push_navigate(to: ~p"/users/log-in")}
    end
  end

  def handle_event("submit", _params, socket) do
    {:noreply, assign(socket, trigger_submit: true)}
  end

  # Helper to get return path based on user role
  defp get_return_path(user) do
    cond do
      user.is_super_admin -> ~p"/admin/super"
      user.is_admin -> ~p"/admin/dashboard"
      true -> ~p"/users/settings"
    end
  end
end
