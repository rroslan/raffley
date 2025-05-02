# For TODO and a record what was accomplished
* Using magic link to login, registration done through web, done through `iex -S mix` on VPS. Refer to README.md for more details.

## do db migration to add to users table is_super_admin and is_admin
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



