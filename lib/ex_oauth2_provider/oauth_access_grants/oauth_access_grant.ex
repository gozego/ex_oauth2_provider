defmodule ExOauth2Provider.OauthAccessGrants.OauthAccessGrant do
  @moduledoc false

  use Ecto.Schema
  alias ExOauth2Provider.Config
  alias ExOauth2Provider.OauthApplications.OauthApplication

  @timestamps_opts [type: :naive_datetime_usec]

  schema "oauth_access_grants" do
    belongs_to :resource_owner, Config.resource_owner_struct(), Config.resource_owner_opts()
    belongs_to :application, OauthApplication

    field :token,        :string,     null: false
    field :expires_in,   :integer,    null: false
    field :redirect_uri, :string,     null: false
    field :revoked_at,   :naive_datetime, usec: true
    field :scopes,       :string

    timestamps(updated_at: false)
  end
end
