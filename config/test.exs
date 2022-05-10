import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :beer_game, BeerGame.Repo,
  username: "root",
  password: "",
  hostname: "localhost",
  database: "beer_game_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :beer_game, BeerGameWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "i499q4HBrRAZo2i4fPtYBor5nTr6ibcqM4gS1n3MCXdmjsESZ2oRWxwMjyb2h9yr",
  server: false

# In test we don't send emails.
config :beer_game, BeerGame.Mailer, adapter: Swoosh.Adapters.Test

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
