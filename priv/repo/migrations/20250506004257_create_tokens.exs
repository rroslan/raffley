defmodule Raffley.Repo.Migrations.CreateTokens do
  use Ecto.Migration

  def change do
    create table(:tokens) do
      add :country_issued_id, :string
      add :token, :string, null: false
      add :token_type, :string, default: "user", null: false
      add :expiration, :utc_datetime, null: false

      timestamps()
    end

    # Add indices for efficient lookups
    create index(:tokens, [:token])
    create index(:tokens, [:country_issued_id])
    
    # Add constraint to ensure token_type is either "user" or "survey"
    create constraint(:tokens, :token_type_must_be_valid, check: "token_type IN ('user', 'survey')")
  end
end
