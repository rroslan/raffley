# Development Log

## Authentication System
### Magic Link Authentication
* Using magic link to login - no password required
* Registration done through `iex -S mix` on VPS
* See README.md for detailed setup instructions

### Admin System Implementation
#### Database Changes (2025-05-02)
* Added admin flags to users table:
  ```elixir
  defmodule Raffley.Repo.Migrations.AddAdminFlagsToUsers do
    use Ecto.Migration

    def change do
      alter table(:users) do
        add :is_admin, :boolean, default: false, null: false
        add :is_super_admin, :boolean, default: false, null: false
      end

      create index(:users, [:is_admin])
      create index(:users, [:is_super_admin])
      create index(:users, [:is_admin, :is_super_admin])
    end
  end
  ```

#### User Schema Updates
* Updated User schema with admin flags:
  ```elixir
  schema "users" do
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :current_password, :string, virtual: true, redact: true
    field :confirmed_at, :utc_datetime
    field :authenticated_at, :utc_datetime, virtual: true
    field :is_admin, :boolean, default: false
    field :is_super_admin, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  def email_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email, :is_admin, :is_super_admin])
    |> validate_email(opts)
  end
  ```

### Admin User Setup
#### Local Development
1. Start IEx console:
   ```bash
   iex -S mix
   ```
2. Update user admin status:
   ```elixir
   alias Raffley.Repo
   alias Raffley.Accounts.User
   import Ecto.Changeset
   
   # Get user by email
   user = Repo.get_by(User, email: "user@example.com")
   
   # Update admin status
   changeset = change(user, %{is_admin: true, is_super_admin: true})
   Repo.update!(changeset)
   ```

#### Production (VPS)
1. Connect to remote console:
   ```bash
   cd /home/ubuntu/raffley/_build/prod/rel/raffley
   bin/raffley remote
   ```
2. Follow same steps as local development to update user status

#### Verify Changes (Development)
```sql
-- Connect to PostgreSQL
docker exec -it <container_name> psql -U <user> -d raffley_dev

-- Check user status
SELECT id, email, is_admin, is_super_admin 
FROM users 
WHERE email = 'user@example.com';
```

## Recent Updates

### Flash Message Handling (2025-05-03)
* Fixed flash message display in login and confirmation forms
* Added proper positioning with absolute positioning and z-index
* Integrated with DaisyUI styling for consistent look
* Improved HTML structure and component organization

### Form Handling Improvements
* Fixed form field access and validation
* Added proper CSRF protection
* Improved error message display
* Enhanced form accessibility with proper labels and ARIA attributes

### Testing
* All 98 tests passing
* Minor warnings for deprecated `push_redirect` usage (to be updated)
* Admin management functionality in progress
