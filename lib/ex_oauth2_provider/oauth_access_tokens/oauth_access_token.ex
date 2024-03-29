defmodule ExOauth2Provider.OauthAccessTokens.OauthAccessToken do
  @moduledoc false

  use Ecto.Schema
  alias ExOauth2Provider.Config
  alias ExOauth2Provider.OauthApplications.OauthApplication

  @timestamps_opts [type: :naive_datetime_usec]

  schema "oauth_access_tokens" do
    belongs_to :application, OauthApplication, on_replace: :nilify
    belongs_to :resource_owner, Config.resource_owner_struct(), Config.resource_owner_opts()

    field :token,         :string, null: false
    field :refresh_token, :string
    field :expires_in,    :integer
    field :revoked_at,    :naive_datetime_usec
    field :scopes,        :string
    field :previous_refresh_token, :string, null: false, default: ""

    timestamps()
  end
end
