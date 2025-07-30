defmodule Raffley.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Raffley.Repo

  alias Raffley.Accounts.{User, UserToken, UserNotifier}

  ## Database getters

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("foo@example.com")
      %User{}

      iex> get_user_by_email("unknown@example.com")
      nil

  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  ## User registration

  @doc """
  Registers a user.

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(attrs) do
    %User{}
    |> User.email_changeset(attrs)
    |> Repo.insert()
  end

  ## Settings

  @doc """
  Checks whether the user is in sudo mode.

  The user is in sudo mode when the last authentication was done no further
  than 20 minutes ago. The limit can be given as second argument in minutes.
  """
  def sudo_mode?(user, minutes \\ -20)

  def sudo_mode?(%User{authenticated_at: ts}, minutes) when is_struct(ts, DateTime) do
    DateTime.after?(ts, DateTime.utc_now() |> DateTime.add(minutes, :minute))
  end

  def sudo_mode?(_user, _minutes), do: false

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.

  See `Raffley.Accounts.User.email_changeset/3` for a list of supported options.

  ## Examples

      iex> change_user_email(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_email(user, attrs \\ %{}, opts \\ []) do
    User.email_changeset(user, attrs, opts)
  end

  @doc """
  Updates the user email using the given token.

  If the token matches, the user email is updated and the token is deleted.
  """
  def update_user_email(user, token) do
    context = "change:#{user.email}"

    with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
         %UserToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(user_email_multi(user, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp user_email_multi(user, email, context) do
    changeset = User.email_changeset(user, %{email: email})

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, [context]))
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.

  If the token is valid `{user, token_inserted_at}` is returned, otherwise `nil` is returned.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Gets the user with the given magic link token.
  """
  def get_user_by_magic_link_token(token) do
    with {:ok, query} <- UserToken.verify_magic_link_token_query(token),
         {user, _token} <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  @doc """
  Logs the user in by magic link.

  There are two cases to consider:

  1. The user has already confirmed their email. They are logged in
     and the magic link is expired.

  2. The user has not confirmed their email.
     In this case, the user gets confirmed, logged in, and all tokens -
     including session ones - are expired.
  """
  def login_user_by_magic_link(token) do
    {:ok, query} = UserToken.verify_magic_link_token_query(token)

    case Repo.one(query) do
      {%User{confirmed_at: nil} = user, _token} ->
        user
        |> User.confirm_changeset()
        |> update_user_and_delete_all_tokens()

      {user, token} ->
        Repo.delete!(token)
        {:ok, user, []}

      nil ->
        {:error, :not_found}
    end
  end

  @doc ~S"""
  Delivers the update email instructions to the given user.

  ## Examples

      iex> deliver_user_update_email_instructions(user, current_email, &url(~p"/users/settings/confirm-email/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")

    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  @doc ~S"""
  Delivers the magic link login instructions to the given user.
  """
  def deliver_login_instructions(%User{} = user, magic_link_url_fun)
      when is_function(magic_link_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "login")
    Repo.insert!(user_token)
    UserNotifier.deliver_login_instructions(user, magic_link_url_fun.(encoded_token))
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_user_session_token(token) do
    Repo.delete_all(UserToken.by_token_and_context_query(token, "session"))
    :ok
  end

  ## Token helper

  defp update_user_and_delete_all_tokens(changeset) do
    %{data: %User{} = user} = changeset

    with {:ok, %{user: user, tokens_to_expire: expired_tokens}} <-
           Ecto.Multi.new()
           |> Ecto.Multi.update(:user, changeset)
           |> Ecto.Multi.all(:tokens_to_expire, UserToken.by_user_and_contexts_query(user, :all))
           |> Ecto.Multi.delete_all(:tokens, fn %{tokens_to_expire: tokens_to_expire} ->
             UserToken.delete_all_query(tokens_to_expire)
           end)
           |> Repo.transaction() do
      {:ok, user, expired_tokens}
    end
  end

  @doc """
  Returns the list of all users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    users = Repo.all(User)
    IO.puts("ACCOUNTS.list_users: Fetched #{length(users)} users")

    Enum.each(users, fn user ->
      IO.puts(
        "User: #{user.email} - is_vendor: #{user.is_vendor}, is_admin: #{user.is_admin}, is_super_admin: #{user.is_super_admin}"
      )
    end)

    users
  end

  @doc """
  Updates a user's admin status.

  ## Examples

      iex> update_user_admin_status(user, true)
      {:ok, %User{}}

      iex> update_user_admin_status(user, false)
      {:ok, %User{}}

  """
  def update_user_admin_status(%User{} = user, is_admin) do
    IO.puts(
      "ACCOUNTS: update_user_admin_status called - User ID: #{user.id}, Current is_admin: #{user.is_admin}"
    )

    IO.puts("ACCOUNTS: Setting is_admin to: #{is_admin} (#{typeof(is_admin)})")

    changeset = User.admin_changeset(user, %{is_admin: is_admin})

    # Log changeset information
    IO.puts("ACCOUNTS: Changeset valid? #{changeset.valid?}")

    if !changeset.valid? do
      IO.puts("ACCOUNTS: Changeset errors: #{inspect(changeset.errors)}")
    end

    # Log changes
    changes = Ecto.Changeset.get_change(changeset, :is_admin)
    IO.puts("ACCOUNTS: Changes to is_admin: #{inspect(changes)}")

    result = Repo.update(changeset)
    IO.puts("ACCOUNTS: Repo.update result: #{inspect(result)}")

    result
  end

  # Helper function to determine type for debugging
  defp typeof(term) do
    cond do
      is_binary(term) -> "string"
      is_boolean(term) -> "boolean"
      is_integer(term) -> "integer"
      is_float(term) -> "float"
      is_list(term) -> "list"
      is_map(term) -> "map"
      is_tuple(term) -> "tuple"
      is_atom(term) -> "atom"
      true -> "unknown"
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user's admin status.

  ## Examples

      iex> change_user_admin_status(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_admin_status(%User{} = user, attrs \\ %{}) do
    User.admin_changeset(user, attrs)
  end

  @doc """
  Updates a user's super admin status.

  This operation requires proper authorization through can_modify_user_status?/2.
  Only super admins can modify other users' super admin status, and they cannot
  modify other super admins.

  ## Examples

      iex> update_user_super_admin_status(acting_user, target_user, true)
      {:ok, %User{}}

      iex> update_user_super_admin_status(acting_user, target_user, false)
      {:error, :unauthorized}

  """
  def update_user_super_admin_status(acting_user, %User{} = target_user, is_super_admin) do
    IO.puts(
      "ACCOUNTS: update_user_super_admin_status called - User ID: #{target_user.id}, Current is_super_admin: #{target_user.is_super_admin}"
    )

    IO.puts("ACCOUNTS: Setting is_super_admin to: #{is_super_admin} (#{typeof(is_super_admin)})")

    if can_modify_user_status?(acting_user, target_user) do
      changeset = User.admin_changeset(target_user, %{is_super_admin: is_super_admin})

      # Log changeset information
      IO.puts("ACCOUNTS: Changeset valid? #{changeset.valid?}")

      if !changeset.valid? do
        IO.puts("ACCOUNTS: Changeset errors: #{inspect(changeset.errors)}")
      end

      # Log changes
      changes = Ecto.Changeset.get_change(changeset, :is_super_admin)
      IO.puts("ACCOUNTS: Changes to is_super_admin: #{inspect(changes)}")

      result = Repo.update(changeset)
      IO.puts("ACCOUNTS: Repo.update result: #{inspect(result)}")

      result
    else
      IO.puts("ACCOUNTS: Cannot modify user (ID: #{target_user.id}). Operation unauthorized.")
      {:error, :unauthorized}
    end
  end

  @doc """
  Updates a user's super admin status.

  This version of the function provides limited authorization that aligns with can_modify_user_status?/2:
  - Cannot modify super admin users in any way
  - Cannot modify super admin status without proper authorization (use the 3-arity version)
  - Returns {:error, :unauthorized} for any operation involving super admin users

  For full authorization controls, use update_user_super_admin_status/3 with an acting user.

  ## Examples

      iex> update_user_super_admin_status(super_admin_user, false)
      {:error, :unauthorized}

      iex> update_user_super_admin_status(super_admin_user, true)
      {:error, :unauthorized}

      iex> update_user_super_admin_status(regular_user, true)
      {:ok, %User{}}

  @deprecated "Use update_user_super_admin_status/3 instead for proper authorization"
  """
  def update_user_super_admin_status(%User{} = user, is_super_admin) do
    IO.puts(
      "ACCOUNTS: update_user_super_admin_status/2 called - User ID: #{user.id}, Current is_super_admin: #{user.is_super_admin}"
    )

    IO.puts("ACCOUNTS: Setting is_super_admin to: #{is_super_admin} (#{typeof(is_super_admin)})")

    # Get fresh user data to ensure we have the latest state
    fresh_user = Repo.get!(User, user.id)

    # Enforce authorization rules from can_modify_user_status?/2:
    # Enforce authorization rules from can_modify_user_status?/2:
    # Cannot modify super admin users at all (!target_user.is_super_admin)
    if fresh_user.is_super_admin do
      IO.puts(
        "ACCOUNTS: Cannot modify super admin user (ID: #{fresh_user.id}). Operation unauthorized."
      )

      {:error, :unauthorized}
    else
      changeset = User.admin_changeset(fresh_user, %{is_super_admin: is_super_admin})

      # Log changeset information
      IO.puts("ACCOUNTS: Changeset valid? #{changeset.valid?}")

      if !changeset.valid? do
        IO.puts("ACCOUNTS: Changeset errors: #{inspect(changeset.errors)}")
      end

      # Log changes
      changes = Ecto.Changeset.get_change(changeset, :is_super_admin)
      IO.puts("ACCOUNTS: Changes to is_super_admin: #{inspect(changes)}")

      result = Repo.update(changeset)
      IO.puts("ACCOUNTS: Repo.update result: #{inspect(result)}")

      result
    end
  end

  @doc """
  Updates a user's vendor status.

  ## Examples

      iex> update_user_vendor_status(user, true)
      {:ok, %User{}}

      iex> update_user_vendor_status(user, false)
      {:ok, %User{}}

  """
  def update_user_vendor_status(%User{} = user, is_vendor) do
    IO.puts(
      "ACCOUNTS: update_user_vendor_status called - User ID: #{user.id}, Current is_vendor: #{user.is_vendor}"
    )

    IO.puts("ACCOUNTS: Setting is_vendor to: #{is_vendor} (#{typeof(is_vendor)})")

    changeset = User.admin_changeset(user, %{is_vendor: is_vendor})

    # Log changeset information
    IO.puts("ACCOUNTS: Changeset valid? #{changeset.valid?}")

    if !changeset.valid? do
      IO.puts("ACCOUNTS: Changeset errors: #{inspect(changeset.errors)}")
    end

    # Log changes
    changes = Ecto.Changeset.get_change(changeset, :is_vendor)
    IO.puts("ACCOUNTS: Changes to is_vendor: #{inspect(changes)}")

    result = Repo.update(changeset)
    IO.puts("ACCOUNTS: Repo.update result: #{inspect(result)}")

    result
  end

  @doc """
  Checks whether the given acting user can modify the status of the target user.
  Determines if a user can modify another user's admin status.

  Only super admins can modify other users' admin status, and they cannot modify
  other super admin users.

  ## Examples

      iex> can_modify_user_status?(super_admin_user, regular_user)
      true

      iex> can_modify_user_status?(admin_user, regular_user)
      false

      iex> can_modify_user_status?(super_admin_user, other_super_admin)
      false

  """
  def can_modify_user_status?(%User{is_super_admin: true} = acting_user, %User{} = target_user) do
    # Super admins can modify any user except other super admins
    acting_user.id != target_user.id && !target_user.is_super_admin
  end

  def can_modify_user_status?(_acting_user, _target_user), do: false

  @doc """
  Returns the total count of users in the system.
  """
  def count_users do
    Repo.aggregate(User, :count)
  end

  @doc """
  Returns the count of admin users (including super admins).
  """
  def count_admins do
    User
    |> where([u], u.is_admin == true or u.is_super_admin == true)
    |> Repo.aggregate(:count)
  end

  @doc """
  Returns the count of vendor users.
  """
  def count_vendors do
    User
    |> where([u], u.is_vendor == true)
    |> Repo.aggregate(:count)
  end

  @doc """
  Returns the count of admin users (excluding super admins).
  """
  def count_admin_users do
    User
    |> where([u], u.is_admin == true and u.is_super_admin == false)
    |> Repo.aggregate(:count)
  end

  @doc """
  Returns the count of super admin users.
  """
  def count_super_admin_users do
    User
    |> where([u], u.is_super_admin == true)
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Counts the number of vendor users in the system.
  """
  def count_vendor_users do
    User
    |> where([u], u.is_vendor == true)
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Lists all vendor users.
  """
  def list_vendor_users do
    User
    |> where([u], u.is_vendor == true)
    |> order_by([u], asc: u.email)
    |> Repo.all()
  end
end
