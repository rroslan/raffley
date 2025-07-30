defmodule Raffley.Repo.Migrations.AddVendorFlagToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :is_vendor, :boolean, default: false, null: false
    end

    create index(:users, [:is_vendor])
    create index(:users, [:is_admin, :is_super_admin, :is_vendor])
  end
end
