defmodule BotArmyDiscordWebhookManager.WebhookConfig do
  @moduledoc """
  Webhook URL and channel routing configuration.

  URLs come from env vars (DISCORD_WEBHOOK_ALERTS, DISCORD_WEBHOOK_TAVERN).
  Bot-to-channel routing is compiled into the module — add a bot with one line.
  """

  @routing %{
    "dispatcher" => "alerts",
    "gtd" => "tavern",
    "synapse" => "tavern",
    "llm" => "tavern",
    "learning" => "tavern",
    "fitness" => "tavern",
    "chore" => "tavern",
    "job_applications" => "tavern"
  }
  @default_channel "tavern"
  @channels ["alerts", "tavern"]

  @doc "Returns the webhook URL for a given channel, or nil if not configured."
  def url_for_channel(channel) do
    System.get_env("DISCORD_WEBHOOK_#{String.upcase(channel)}")
  end

  @doc "Returns the default channel for a bot name."
  def channel_for_bot(bot_name) do
    Map.get(@routing, bot_name, @default_channel)
  end

  @doc "Raises at startup if any configured channel is missing a URL."
  def validate! do
    missing = Enum.filter(@channels, &is_nil(url_for_channel(&1)))

    unless Enum.empty?(missing) do
      raise "Missing Discord webhook URLs for channels: #{inspect(missing)}. " <>
              "Set DISCORD_WEBHOOK_ALERTS and DISCORD_WEBHOOK_TAVERN env vars."
    end

    :ok
  end
end
