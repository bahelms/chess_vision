import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :chess_vision, ChessVisionWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "YyY4oeWznCNIQ/CyMRyV80KY3QbGXTI6a/Krv6VpwUmGCOD46aaHft6Vwh8Sf9kI",
  server: false

# In test we don't send emails.
config :chess_vision, ChessVision.Mailer,
  adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
