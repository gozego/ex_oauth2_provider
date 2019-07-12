use Mix.Config

config :ex_oauth2_provider, ExOauth2Provider,
  repo: ExOauth2Provider.Test.Repo,
  resource_owner: Dummy.User,
  default_scopes: ~w(public),
  optional_scopes: ~w(read write),
  password_auth: {ExOauth2Provider.Test.Auth, :auth},
  use_refresh_token: true,
  revoke_refresh_token_on_use: true,
  grant_flows: ~w(authorization_code client_credentials)

config :ex_oauth2_provider, ecto_repos: [ExOauth2Provider.Test.Repo]

config :ex_oauth2_provider, ExOauth2Provider.Test.Repo,
  migration_timestamps: [type: :naive_datetime_usec],
  adapter: Ecto.Adapters.Postgres,
  database: "ex_oauth2_provider_test",
  pool: Ecto.Adapters.SQL.Sandbox,
  priv: "priv/test",
  username: System.get_env("DATABASE_POSTGRESQL_USERNAME") || "postgres",
  password: System.get_env("DATABASE_POSTGRESQL_PASSWORD") || "postgres",
  hostname: "localhost"
