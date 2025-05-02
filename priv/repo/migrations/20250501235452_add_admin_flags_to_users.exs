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
