# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :banking_api,
  ecto_repos: [BankingApi.Repo],
  generators: [binary_id: true]

secret_key_base =
  System.get_env("SECRET_KEY_BASE") ||
    raise """
    (config.exs) environment variable SECRET_KEY_BASE is missing.
    You can generate one by calling: mix phx.gen.secret
    """

# Configures the endpoint
config :banking_api, BankingApiWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: secret_key_base,
  render_errors: [view: BankingApiWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: BankingApi.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"

# Configures Guardian
config :banking_api, BankingApi.Auth.Guardian,
  issuer: "banking_api",
  secret_key: secret_key_base,
  permissions: %{
    default: [:banking],
    admin: [:backoffice]
  }

config :banking_api, :phoenix_swagger,
  swagger_files: %{
    "priv/static/swagger.json" => [
      router: BankingApiWeb.Router
    ]
  }
