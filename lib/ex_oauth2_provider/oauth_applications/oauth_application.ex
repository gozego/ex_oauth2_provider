defmodule ExOauth2Provider.OauthApplications.OauthApplication do
  @moduledoc false

  use Ecto.Schema
  require Logger

  alias ExOauth2Provider.Config

  # For Phoenix integrations
  if Code.ensure_loaded?(Phoenix.Param) do
    @derive {Phoenix.Param, key: :uid}
  end

  @timestamps_opts [type: :naive_datetime_usec]

  schema "oauth_applications" do
    if is_nil(Config.application_owner_struct()) do
      Logger.error("You need to set a resource_owner or application_owner in your config and recompile ex_oauth2_provider!")
    end

    belongs_to :owner, Config.application_owner_struct(), Config.application_owner_opts()

    field :name,         :string,     null: false
    field :uid,          :string,     null: false
    field :secret,       :string,     null: false
    field :redirect_uri, :string,     null: false
    field :scopes,       :string,     null: false, default: ""

    has_many :access_tokens, ExOauth2Provider.OauthAccessTokens.OauthAccessToken, foreign_key: :application_id

    timestamps()
  end
end
