import Config
config :therons_erp, Oban, testing: :manual
config :therons_erp, token_signing_secret: "mX3jn0HNkCoVKy3YiiF4B1CxZMTGajAA"
config :ash, disable_async?: true

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :therons_erp, TheronsErp.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "therons_erp_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :therons_erp, TheronsErpWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "5/ErcOSYxQ6LmKEQqB9kqIz4THRNlx2RDEp+IlQMzH2tcQjk1CKLukgRUsCde+zn",
  server: false

# In test we don't send emails
config :therons_erp, TheronsErp.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

config :phoenix_test, :endpoint, TheronsErpWeb.Endpoint

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

config :ash, :policies, show_policy_breakdowns?: true
