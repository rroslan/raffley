defmodule RaffleyWeb.UserLive.Login do
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
              Log in to Raffley
              <:subtitle>
                <%= if @current_scope do %>
                  You need to reauthenticate to perform sensitive actions on your account.
                <% end %>
              </:subtitle>
            </.header>

          <div :if={local_mail_adapter?()} class="alert alert-info">
            <.icon name="hero-information-circle" class="h-6 w-6 shrink-0" />
            <div>
              <p>You are running the local mail adapter.</p>
              <p>
                To see sent emails, visit <.link href="/dev/mailbox" class="underline">the mailbox page</.link>.
              </p>
            </div>
          </div>

          <.form
            for={@form}
            id="login_form_magic"
            action={~p"/users/log-in"}
            phx-submit="submit_magic"
            class="space-y-4"
          >
            <div class="form-control w-full">
              <label class="label" for="login_form_magic_email">
                <span class="label-text">Email</span>
              </label>
              <input
                type="email"
                name="user[email]"
                id="login_form_magic_email"
                value={@email}
                readonly={!!@current_scope}
                class={[
                  "input input-bordered w-full",
                  !!@current_scope && "bg-base-200"
                ]}
                autocomplete="username"
                required
                phx-mounted={JS.focus()}
              />
            </div>
            <.button phx-disable-with="Sending..." class="w-full btn-primary">
              Log in with email <span aria-hidden="true">→</span>
            </.button>
          </.form>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    email = 
      Phoenix.Flash.get(socket.assigns.flash, :email) ||
        get_in(socket.assigns, [:current_scope, Access.key(:user), Access.key(:email)])

    # Create a simple form without complex binding
    form = to_form(%{})

    {:ok, assign(socket, form: form, email: email || "", trigger_submit: false)}
  end

  def handle_event("submit_password", _params, socket) do
    {:noreply, assign(socket, :trigger_submit, true)}
  end

  def handle_event("submit_magic", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_login_instructions(
        user,
        &url(~p"/users/log-in/#{&1}")
      )
    end

    info =
      "If your email is in our system, you will receive instructions for logging in shortly."

    # Remove push_navigate to allow the controller redirect to take precedence
    {:noreply,
     socket
     |> put_flash(:info, info)}
  end

  defp local_mail_adapter? do
    Application.get_env(:raffley, Raffley.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
