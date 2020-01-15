use Mix.Config

# Configure your database
config :banking_api, BankingApi.Repo,
  username: "postgres",
  password: "hu+WyM2-x7n^pRMQ",
  database: "banking_hmg",
  hostname: "35.198.42.120",
  port: 5432,
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :banking_api, BankingApiWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn
config :bcrypt_elixir, :log_rounds, 4
