# use Mix.Config
import Config

# Configure your database
config :banking_api, BankingApi.Repo,
  username: System.get_env("PGUSER") || "postgres",
  password: System.get_env("PGPASSWORD") || "postgres",
  database: System.get_env("PGDATABASE") || "postgres",
  hostname: System.get_env("PGHOST") || "localhost",
  port: System.get_env("PGPORT") || 5432,
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :banking_api, BankingApiWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn
config :argon2_elixir, t_cost: 1, m_cost: 8
