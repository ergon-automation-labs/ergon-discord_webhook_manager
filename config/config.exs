import Config

config :logger, :default_handler, level: :info

config :logger_json, :default_handler,
  formatter: {LoggerJSON.Formatters.DatadogAPM, %{}},
  metadata: :all
