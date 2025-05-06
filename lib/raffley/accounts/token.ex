defmodule Raffley.Token do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Raffley.Repo
  alias __MODULE__

  @token_expiry_hours 24

  schema "tokens" do
    field :country_issued_id, :string
    field :token, :string
    field :expiration, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(token, attrs) do
    token
    |> cast(attrs, [:country_issued_id, :token, :expiration])
    |> validate_required([:country_issued_id, :expiration])
    |> validate_length(:country_issued_id, is: 12)
    |> unique_constraint([:country_issued_id])
    |> validate_format(
      :country_issued_id,
      Regex.compile!(
        "^([0-9]{2})(0[1-9]|1[0-2])(0[1-9]|[12][0-9]|3[01])(0[1-9]|[1-9][0-9])([0-9]{4})$"
      )
    )
  end

  @doc """
  Generates a token for a survey participant.
  
  ## Parameters
  - country_issued_id: The 12-digit country issued ID
  
  ## Returns
  - `{:ok, token}` if successful
  - `{:error, changeset}` if there was an error
  """
  def generate_token(country_issued_id) do
    # Set expiration to 24 hours from now
    expiration = DateTime.add(DateTime.utc_now(), @token_expiry_hours, :hour)
    
    # Generate a secure token string
    token_string = generate_secure_token()
    
    %Token{}
    |> changeset(%{
      country_issued_id: country_issued_id,
      token: token_string,
      expiration: expiration
    })
    |> Repo.insert()
  end

  @doc """
  Verifies a token and returns its associated data.
  
  ## Parameters
  - token_string: The token string to verify
  
  ## Returns
  - `{:ok, token}` if token is valid and not expired
  - `{:error, :invalid}` if token doesn't exist
  - `{:error, :expired}` if token has expired
  """
  def verify_token(token_string) do
    now = DateTime.utc_now()
    
    case Repo.get_by(Token, token: token_string) do
      nil -> {:error, :invalid}
      token ->
        if DateTime.compare(token.expiration, now) == :gt do
          {:ok, token}
        else
          {:error, :expired}
        end
    end
  end


  @doc """
  Cleans up expired tokens from the database.
  
  ## Returns
  - `{:ok, count}` with the number of deleted tokens
  """
  def clean_expired_tokens do
    now = DateTime.utc_now()
    
    {count, _} =
      from(t in Token, where: t.expiration < ^now)
      |> Repo.delete_all()
    
    {:ok, count}
  end

  # Generates a secure random token string
  defp generate_secure_token do
    :crypto.strong_rand_bytes(32)
    |> Base.url_encode64(padding: false)
  end
end
