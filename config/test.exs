# use Mix.Config
import Config

database_url =
  System.get_env("DATABASE_URL_TEST") ||
    raise """
    environment variable DATABASE_URL_TEST is missing.
    For example: ecto://USER:PASS@HOST/DATABASE
    """

# Configure your database
config :banking_api, BankingApi.Repo,
  url: database_url,
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :banking_api, BankingApiWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn
config :argon2_elixir, t_cost: 1, m_cost: 8
