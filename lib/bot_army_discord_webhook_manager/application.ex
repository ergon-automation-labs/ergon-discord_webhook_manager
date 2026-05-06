defmodule BotArmyDiscordWebhookManager.Application do
  @moduledoc """
  Discord Webhook Manager application supervisor.

  Bridges bridge.discord.message.send NATS messages to Discord webhook HTTP POSTs.
  No database — webhook URLs and routing are loaded from env/compiled config.
  """

  use Application

  @env Mix.env()

  @impl true
  def start(_type, _args) do
    validate_config!()

    children =
      []
      |> maybe_add_pulse_publisher()
      |> maybe_add_consumer()

    opts = [strategy: :one_for_one, name: BotArmyDiscordWebhookManager.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp validate_config! do
    if @env != :test do
      BotArmyDiscordWebhookManager.WebhookConfig.validate!()
    end
  end

  defp maybe_add_pulse_publisher(children) do
    if @env == :test do
      children
    else
      children ++ [{BotArmyDiscordWebhookManager.PulsePublisher, []}]
    end
  end

  defp maybe_add_consumer(children) do
    if @env == :test do
      children
    else
      children ++ [{BotArmyDiscordWebhookManager.NATS.Consumer, []}]
    end
  end
end
