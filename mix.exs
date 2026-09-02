defmodule BotArmyDiscordWebhookManager.MixProject do
  use Mix.Project

  def project do
    [
      app: :bot_army_discord_webhook_manager,
      version: "0.1.12",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: [
        discord_webhook_manager: [
          applications: [bot_army_discord_webhook_manager: :permanent]
        ]
      ],
      dialyzer: [
        ignore_warnings: ".dialyzer_ignore.exs"
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {BotArmyDiscordWebhookManager.Application, []}
    ]
  end

  defp deps do
    [
      {:bot_army_library_core, path: "../bot_army_library_core"},
      {:bot_army_library_runtime, path: "../bot_army_library_runtime", override: true},
      {:jason, "~> 1.4"},
      {:logger_json, "~> 5.1"},
      {:elixir_uuid, "~> 1.2"},
      {:req, "~> 0.3"},

      # Development/Test
      {:ex_doc, "~> 0.30", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:mox, "~> 1.0", only: :test},
      {:excoveralls, "~> 0.17", only: :test}
    ]
  end
end
