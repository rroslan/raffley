# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Raffley.Repo.insert!(%Raffley.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Raffley.Accounts
alias Raffley.Accounts.User
alias Raffley.Repo

# Create users with different roles
users_data = [
  %{
    email: "superadmin@example.com",
    is_super_admin: true,
    is_admin: true,
    is_vendor: false
  },
  %{
    email: "admin@example.com",
    is_super_admin: false,
    is_admin: true,
    is_vendor: false
  },
  %{
    email: "vendor@example.com",
    is_super_admin: false,
    is_admin: false,
    is_vendor: true
  },
  %{
    email: "adminvendor@example.com",
    is_super_admin: false,
    is_admin: true,
    is_vendor: true
  },
  %{
    email: "user@example.com",
    is_super_admin: false,
    is_admin: false,
    is_vendor: false
  }
]

# Create each user
Enum.each(users_data, fn user_data ->
  case Repo.get_by(User, email: user_data.email) do
    nil ->
      # User doesn't exist, create it
      {:ok, user} = Accounts.register_user(%{"email" => user_data.email})

      # Update the user with the role flags
      user
      |> User.admin_changeset(%{
        is_admin: user_data.is_admin,
        is_super_admin: user_data.is_super_admin,
        is_vendor: user_data.is_vendor
      })
      |> Repo.update!()

      # Confirm the user (so they don't need to confirm via email)
      user
      |> User.confirm_changeset()
      |> Repo.update!()

      IO.puts("Created user: #{user_data.email}")

    existing_user ->
      IO.puts("User already exists: #{existing_user.email}")
  end
end)

IO.puts("\nSeed data loaded successfully!")
IO.puts("\nYou can now log in as:")
IO.puts("- superadmin@example.com (Super Admin)")
IO.puts("- admin@example.com (Admin)")
IO.puts("- vendor@example.com (Vendor)")
IO.puts("- adminvendor@example.com (Admin + Vendor)")
IO.puts("- user@example.com (Regular user)")
IO.puts("\nUse the 'Send Login Link' feature to get magic links for these users.")
