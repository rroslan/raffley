defmodule RaffleyWeb.TokenLive.Create do
  use RaffleyWeb, :live_view
  import RaffleyWeb.CoreComponents
  alias Raffley.Token

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, form: to_form(%{"token_id" => ""}))}
  end

  @impl true
  def handle_event("validate", %{"token_id" => token_id}, socket) do
    # More permissive validation during typing
    errors = cond do
      # Empty field - no error yet
      token_id == "" -> 
        []
      # Contains non-digit characters
      !String.match?(token_id, ~r/^\d+$/) -> 
        [token_id: {"must contain only digits", []}]
      # Exceeds 12 digits
      String.length(token_id) > 12 -> 
        [token_id: {"cannot exceed 12 digits", []}]
      # Otherwise, no error while typing
      true -> 
        []
    end

    form =
      %{"token_id" => token_id}
      |> to_form()
      |> Map.put(:errors, errors)

    # Don't set flash messages during validation
    {:noreply, assign(socket, form: form)}
  end

  @impl true
  def handle_event("save", %{"token_id" => token_id}, socket) do
    if String.match?(token_id, ~r/^\d{12}$/) do
      # Call the Token module to generate a token
      case Token.generate_token(token_id) do
        {:ok, token} ->
          # Format expiration time for display
          formatted_expiration = Calendar.strftime(token.expiration, "%Y-%m-%d %H:%M:%S UTC")
          
          {:noreply,
           socket
           |> put_flash(:info, "Token created successfully. Expires at: #{formatted_expiration}")
           |> assign(form: to_form(%{"token_id" => ""}))}
        
        {:error, changeset} ->
          error_message = get_changeset_error(changeset)
          
          {:noreply,
           socket
           |> put_flash(:error, "Failed to create token: #{error_message}")
           |> assign(form: put_errors_on_form(socket.assigns.form, changeset))}
      end
    else
      {:noreply,
       socket
       |> put_flash(:error, "Invalid token ID. Must be exactly 12 digits.")}
    end
  end
  
  # Extract the first error message from a changeset
  defp get_changeset_error(changeset) do
    changeset.errors
    |> Enum.map(fn {field, {message, _}} -> "#{field} #{message}" end)
    |> Enum.join(", ")
  end
  
  # Put changeset errors onto the form
  defp put_errors_on_form(form, %Ecto.Changeset{} = changeset) do
    errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
    
    Map.put(form, :errors, errors)
  end
end
