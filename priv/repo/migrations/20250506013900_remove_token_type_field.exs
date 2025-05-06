defmodule Raffley.Repo.Migrations.RemoveTokenTypeField do
  use Ecto.Migration

  def up do
    alter table(:tokens) do
      remove :token_type
    end
  end

  def down do
    alter table(:tokens) do
      add :token_type, :string, default: "survey"
    end
  end
end

