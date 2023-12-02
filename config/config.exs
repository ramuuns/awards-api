# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :awardsapi,
  ecto_repos: [Awardsapi.Repo]

# Configures the endpoint
config :awardsapi, AwardsapiWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [json: AwardsapiWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Awardsapi.PubSub,
  live_view: [signing_salt: "LSMHkPnD"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :awardsapi,
  valid_currencies: MapSet.new(["JPY"]),
  currency_for_points: "JPY",
  basis_rate: 100

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
