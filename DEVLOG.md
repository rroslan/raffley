# Database Reset and Admin User Creation

## Step 1: Reset Database
Run these commands in sequence:
```bash
# Drop the development database
mix ecto.drop

# Create a fresh database
mix ecto.create

# Run all migrations
mix ecto.migrate
```

## Step 2: Create Admin User
First, start an IEx session:
```bash
iex -S mix
```

Then run these commands in IEx:
```elixir
# Set up aliases
alias Raffley.Accounts
alias Raffley.Accounts.User
alias Raffley.Repo

# Create new user with admin rights
{:ok, user} = Accounts.register_user(%{email: "rroslan@gmail.com"})
{:ok, admin_user} = user |> User.admin_changeset(%{is_admin: true, is_super_admin: true}) |> Repo.update()

# Verify permissions (these should both return true)
admin_user.is_admin
admin_user.is_super_admin
```

## Prerequisites
- Ensure PostgreSQL Docker container (my-postgres) is running
- Check with: `docker ps | grep my-postgres`

## Verification
After creation, you can verify the user exists with correct permissions by:
1. Logging into the application
2. Checking access to `/admin/super/users` path
3. Or checking directly in PostgreSQL:
   ```sql
   SELECT email, is_admin, is_super_admin FROM users WHERE email = 'rroslan@gmail.com';
   ```

## PostgreSQL Database Verification

### Connect to PostgreSQL Container
```bash
# Connect to PostgreSQL inside container
docker exec -it my-postgres psql -U postgres
```

### Database Verification Commands
Once connected, run these commands to verify the database state:

```sql
-- List all databases (verify raffley_dev exists)
\l

-- Connect to raffley_dev
\c raffley_dev

-- List all tables
\dt

-- Check users table structure
\d users

-- Verify admin user
SELECT email, is_admin, is_super_admin, confirmed_at 
FROM users 
WHERE email = 'rroslan@gmail.com';
```

### Quick Database Checks
Single-line commands from terminal:

```bash
# Complete database verification in one command
docker exec -it my-postgres psql -U postgres -d postgres -c "
SELECT datname, pg_size_pretty(pg_database_size(datname)) as size 
FROM pg_database 
WHERE datname = 'raffley_dev';"

# Check if raffley_dev exists
docker exec -it my-postgres psql -U postgres -c "\l" | grep raffley_dev

# Check users table
docker exec -it my-postgres psql -U postgres -d raffley_dev -c "\dt"

# Check admin user
docker exec -it my-postgres psql -U postgres -d raffley_dev -c "SELECT email, is_admin, is_super_admin FROM users WHERE email = 'rroslan@gmail.com';"
```

### Exit PostgreSQL
To exit the PostgreSQL prompt:
- Type `\q` and press Enter
- Or press Ctrl+D

## Troubleshooting

### Common Issues
1. If database drop fails:
   - Check if any existing connections are open (e.g., psql, pgAdmin)
   - Try restarting the PostgreSQL container:
     ```bash
     docker restart my-postgres
     ```

2. If user creation fails in IEx:
   - Make sure migrations ran successfully
   - Check database connection with:
     ```elixir
     Raffley.Repo.all(Raffley.Accounts.User)
     ```

3. If PostgreSQL connection fails:
   - Verify container is running: `docker ps`
   - Check logs: `docker logs my-postgres`
   - Verify connection settings in `config/dev.exs`

### Database Access
You can directly access the database with:
```bash
docker exec -it my-postgres psql -U postgres -d raffley_dev
```

### Quick Reset
If you need to completely reset everything:
```bash
mix do ecto.drop, ecto.create, ecto.migrate
```

## Super Admin Management Rules

### Super Admin Status Modification

1. Web Interface Limitations (By Design)
   - Only super admins can modify user status
   - A super admin CANNOT modify their own status
   - A super admin CANNOT modify another super admin's status
   These limitations ensure system security and prevent accidental removal of all super admins.

2. IEx Direct Modification (Emergency/Setup Only)
   ```elixir
   # For emergency or initial setup only
   alias Raffley.Repo
   alias Raffley.Accounts.User
   
   # Method 1: Using admin_changeset (preferred)
   user = Repo.get_by(User, email: "user@example.com")
   {:ok, updated_user} = user 
   |> User.admin_changeset(%{is_super_admin: false}) 
   |> Repo.update()
   
   # Method 2: Using Accounts context (with authorization bypass)
   user = Repo.get_by(User, email: "user@example.com")
   {:ok, _} = Accounts.update_user_super_admin_status(user, false)
   ```

### When to Use Each Method

1. Web Interface (Normal Operations):
   - Adding new admin users
   - Removing admin status from regular users
   - Managing non-admin users
   - Any routine user management tasks

2. IEx Console (Special Cases):
   - Initial system setup
   - Emergency recovery when all super admins are locked out
   - Database migrations or system upgrades
   - Testing and development setup

### Best Practices
1. Always maintain at least two super admin accounts
2. Use web interface for routine operations
3. Document any IEx modifications in system logs
4. Regular backup of user roles and permissions
5. Test super admin access after system updates

### Recovery Procedures
If all super admin access is lost:
1. Connect to IEx console
2. Create or modify a user to have super admin status
3. Log in through web interface with new super admin
4. Create additional super admin account as backup
5. Document the recovery in system logs

### ⚠️ IEx Power and Security

IEx provides unrestricted database access, which means it:
1. Can modify ANY user, including super admins
2. Bypasses ALL authorization checks
3. Can perform operations that are blocked in the web interface

IMPORTANT: Use IEx with caution because:
- It bypasses security checks
- Changes are immediate and irreversible
- No audit trail is automatically created
- Can potentially break application security rules

Example of IEx power:
```elixir
# In web interface: Cannot modify super admin
# In IEx: Can modify ANY user
alias Raffley.Repo
alias Raffley.Accounts.User

# Get super admin user
super_admin = Repo.get_by(User, email: "super@example.com")

# Can directly remove super admin status (CAREFUL!)
{:ok, updated_user} = super_admin 
  |> User.admin_changeset(%{is_super_admin: false}) 
  |> Repo.update()

# Can grant super admin to any user
regular_user = Repo.get_by(User, email: "user@example.com")
{:ok, new_super_admin} = regular_user 
  |> User.admin_changeset(%{is_super_admin: true}) 
  |> Repo.update()
```

Best Practices for IEx Use:
1. Only use for emergency situations
2. Document all changes made via IEx
3. Always verify changes in web interface after
4. Consider having a second super admin before making changes
5. Test changes in development before production

### 🛠️ IEx Command Examples for Super Admin Management

Here are specific commands for common super admin management tasks:

#### 1. List All Users with Admin Status
```elixir
# Set up aliases first
alias Raffley.Repo
alias Raffley.Accounts.User
import Ecto.Query

# List all users with their admin status
Repo.all(
  from u in User,
  select: {u.email, u.is_admin, u.is_super_admin}
)

# List only super admins
Repo.all(
  from u in User,
  where: u.is_super_admin == true,
  select: {u.email, u.is_admin, u.is_super_admin}
)
```

#### 2. Make a User Super Admin
```elixir
# Find user by email
user = Repo.get_by(User, email: "user@example.com")

# Method 1: Using admin_changeset (recommended)
{:ok, super_admin} = user 
  |> User.admin_changeset(%{is_super_admin: true, is_admin: true}) 
  |> Repo.update()

# Verify changes
super_admin.is_super_admin  # Should return true
super_admin.is_admin       # Should return true
```

#### 3. Remove Super Admin Status
```elixir
# Find super admin by email
super_admin = Repo.get_by(User, email: "super@example.com")

# Remove super admin status (keep admin status)
{:ok, updated_user} = super_admin 
  |> User.admin_changeset(%{is_super_admin: false, is_admin: true}) 
  |> Repo.update()

# Verify changes
updated_user.is_super_admin  # Should return false
updated_user.is_admin       # Should return true
```

#### 4. Emergency Super Admin Creation
```elixir
# Create new user and make them super admin in one go
alias Raffley.Accounts

# First create the user
{:ok, user} = Accounts.register_user(%{email: "emergency@example.com"})

# Then make them super admin
{:ok, super_admin} = user 
  |> User.admin_changeset(%{is_super_admin: true, is_admin: true}) 
  |> Repo.update()
```

#### 5. Verify User Status
```elixir
# Get user and check status
user = Repo.get_by(User, email: "user@example.com")

# Print all relevant fields
IO.puts """
User Status:
Email: #{user.email}
Admin: #{user.is_admin}
Super Admin: #{user.is_super_admin}
Confirmed: #{!is_nil(user.confirmed_at)}
"""
```

#### 6. Fix Locked Out System (No Super Admins)
```elixir
# First check if there are any super admins
super_admin_count = Repo.one(
  from u in User,
  where: u.is_super_admin == true,
  select: count(u.id)
)

if super_admin_count == 0 do
  # Create a new super admin
  {:ok, user} = Accounts.register_user(%{email: "new_super@example.com"})
  {:ok, super_admin} = user 
    |> User.admin_changeset(%{is_super_admin: true, is_admin: true}) 
    |> Repo.update()
  
  IO.puts "Created new super admin: #{super_admin.email}"
end
```

IMPORTANT: Always verify changes after making them:
1. Check the database directly
2. Try logging in through the web interface
3. Test super admin functionality
4. Create a backup super admin account

Remember: These commands bypass normal security checks. Use with caution!

#### 7. Fix Inconsistent User States
```elixir
# Find users with inconsistent admin states
# (super admins should always be admins too)
inconsistent_users = Repo.all(
  from u in User,
  where: u.is_super_admin == true and u.is_admin == false,
  select: {u.id, u.email, u.is_admin, u.is_super_admin}
)

# Fix any inconsistencies found
for {id, email, is_admin, is_super_admin} <- inconsistent_users do
  user = Repo.get!(User, id)
  {:ok, fixed_user} = user
    |> User.admin_changeset(%{is_admin: true})
    |> Repo.update()
    
  IO.puts """
  Fixed user state:
  Email: #{fixed_user.email}
  Previous state: admin=#{is_admin}, super_admin=#{is_super_admin}
  Current state: admin=#{fixed_user.is_admin}, super_admin=#{fixed_user.is_super_admin}
  """
end
```

This example shows how to:
1. Find users with inconsistent admin states
2. Fix the inconsistencies automatically
3. Report the changes made
4. Ensure data integrity

IMPORTANT: Super admins should always have is_admin: true

### 📝 Quick Reference: Common IEx Commands

```elixir
# 1. Setup (Always run these first)
alias Raffley.Repo
alias Raffley.Accounts
alias Raffley.Accounts.User
import Ecto.Query

# 2. Quick User Checks
# Get user
user = Repo.get_by(User, email: "user@example.com")

# Check status
user.is_admin         # Check admin status
user.is_super_admin   # Check super admin status

# 3. Quick Status Changes
# Make super admin
user |> User.admin_changeset(%{is_super_admin: true, is_admin: true}) |> Repo.update()

# Remove super admin
user |> User.admin_changeset(%{is_super_admin: false}) |> Repo.update()

# 4. Quick User List
Repo.all(from u in User, select: {u.email, u.is_admin, u.is_super_admin})
```

💡 Tips:
- Always run the setup aliases first
- Check user status before making changes
- Verify changes after updating
- Use `|> IO.inspect()` to see results

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

### User Management System (2025-05-03)
#### Admin Interface Implementation
* Created dedicated admin dashboard at `/admin`
* Implemented super admin user management at `/admin/super/users`
* Added user registration through admin interface
* Integrated with magic link authentication system

#### Role-based Access Control
* Split admin routes into two scopes:
  - `/admin/*` for regular admin features
  - `/admin/super/*` for super admin features
* Implemented proper permission checks:
  ```elixir
  pipeline :require_admin do
    plug :require_authenticated_user
    plug :ensure_admin
  end

  pipeline :require_super_admin do
    plug :require_authenticated_user
    plug :ensure_super_admin
  end
  ```

#### User Management Features
* Direct checkbox toggles for admin statuses
* Visual indicators for user roles and confirmation status
* Proper permission checks for role modifications
* Responsive design with grid layout:
  - Side-by-side cards on desktop
  - Stacked cards on mobile
* Registration form with magic link delivery

#### Admin Dashboard
* Clear overview of available admin features
* Super admin access to user management
* Prepared structure for future admin features
* Proper navigation and routing setup

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
* Admin management functionality completed

### Authentication System Updates (2025-05-05)
#### Removed Password Fields
* Removed all password-related fields since we're using magic link authentication only
* Previously removed hashed_password from database
* Now removing virtual password fields from schema:
  ```elixir
  # Old schema (with password fields)
  schema "users" do
    field :email, :string
    field :password, :string, virtual: true, redact: true      # removed
    field :hashed_password, :string, redact: true              # removed (in DB)
    field :current_password, :string, virtual: true, redact: true  # removed
    field :confirmed_at, :utc_datetime
    field :authenticated_at, :utc_datetime, virtual: true
    field :is_admin, :boolean, default: false
    field :is_super_admin, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  # New schema (password-free)
  schema "users" do
    field :email, :string
    field :confirmed_at, :utc_datetime
    field :authenticated_at, :utc_datetime, virtual: true
    field :is_admin, :boolean, default: false
    field :is_super_admin, :boolean, default: false

    timestamps(type: :utc_datetime)
  end
  ```

This change:
* Removes all password-related fields (both database and virtual)
* Simplifies the schema to match our magic link authentication approach
* No new migration needed for virtual fields (don't affect database)

### User Management Mobile UI Updates (2025-05-04)
#### Mobile Layout Improvements
* Adjusted Status & Permissions column for better mobile display:
  - Compact badges and checkboxes on xs screens
  - Responsive text sizes
  - Better spacing and alignment
  - Progressive enhancement from xs to sm screens

#### Verification Checklist
1. Mobile Devices to Test:
   - Small phones (iPhone SE, Galaxy S8)
   - Regular phones (iPhone 14, Pixel)
   - Tablets (iPad, Galaxy Tab)
   - Desktop browsers

2. Check Points:
   - Email column truncation
   - Status badges alignment
   - Checkbox and label spacing
   - Text readability on small screens
   - Table horizontal scrolling
   - Form input and button sizes
   - Alert message spacing

3. Critical Areas:
   - Status & Permissions column layout
   - Admin/Super Admin checkbox alignment
   - Badge visibility and spacing
   - Text readability at all sizes

4. Known Breakpoints:
   ```css
   xs: very small phones
   sm: regular phones (640px)
   md: tablets (768px)
   lg: desktop (1024px)
   ```

#### Testing URLs
1. Admin Interface: `/admin`
2. User Management: `/admin/super/users`

Remember to test both portrait and landscape orientations on mobile devices.
