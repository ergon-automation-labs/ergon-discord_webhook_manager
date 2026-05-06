defmodule BotArmyDiscordWebhookManager.WebhookConfigTest do
  use ExUnit.Case, async: true
  @moduletag :core

  alias BotArmyDiscordWebhookManager.WebhookConfig

  describe "channel_for_bot/1" do
    test "routes dispatcher to alerts" do
      assert WebhookConfig.channel_for_bot("dispatcher") == "alerts"
    end

    test "routes synapse to tavern" do
      assert WebhookConfig.channel_for_bot("synapse") == "tavern"
    end

    test "routes unknown bot to tavern default" do
      assert WebhookConfig.channel_for_bot("unknown_bot") == "tavern"
    end
  end

  describe "url_for_channel/1" do
    test "reads URL from env var" do
      System.put_env("DISCORD_WEBHOOK_TAVERN", "https://discord.com/api/webhooks/test")
      assert WebhookConfig.url_for_channel("tavern") == "https://discord.com/api/webhooks/test"
    end

    test "returns nil when env var not set" do
      System.delete_env("DISCORD_WEBHOOK_MISSING")
      assert WebhookConfig.url_for_channel("missing") == nil
    end
  end
end
