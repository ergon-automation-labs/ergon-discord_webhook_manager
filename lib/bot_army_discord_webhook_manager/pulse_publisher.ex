defmodule BotArmyDiscordWebhookManager.PulsePublisher do
  @moduledoc """
  Periodic health publisher for Discord Webhook Manager.
  """

  use GenServer
  require Logger

  @health_interval_ms 30 * 1000
  @publish_interval_ms 30 * 60 * 1000
  @service_name "discord_webhook_manager"
  @envelope_source "bot_army_discord_webhook_manager"

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    Logger.info("[PulsePublisher] Starting Discord Webhook Manager pulse publisher")
    started_at = DateTime.utc_now() |> DateTime.truncate(:second)
    send(self(), :publish_health)
    send(self(), :publish_pulse)
    {:ok, %{started_at: started_at}}
  end

  @impl true
  def handle_info(:publish_health, state) do
    Task.start(fn -> publish_system_health(state) end)
    Process.send_after(self(), :publish_health, @health_interval_ms)
    {:noreply, state}
  end

  @impl true
  def handle_info(:publish_pulse, state) do
    Task.start(fn -> publish_pulse() end)
    Process.send_after(self(), :publish_pulse, @publish_interval_ms)
    {:noreply, state}
  end

  defp publish_pulse do
    signal = :nominal

    pulse = %{
      service: @service_name,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      health: signal,
      metrics: %{}
    }

    case BotArmyLibraryRuntime.NATS.Publisher.publish("bot.#{@service_name}.pulse", pulse) do
      {:ok, _} ->
        Logger.debug("[PulsePublisher] Published pulse")

      {:error, reason} ->
        Logger.warning("[PulsePublisher] Failed to publish pulse: #{inspect(reason)}")
    end
  end

  defp publish_system_health(%{started_at: started_at}) do
    tenant_id = System.get_env("BOT_ARMY_TENANT_ID") || BotArmyLibraryRuntime.Tenant.default_tenant_id()

    uptime_seconds =
      DateTime.diff(DateTime.utc_now() |> DateTime.truncate(:second), started_at, :second)

    case BotArmyLibraryRuntime.SynapseHealth.publish(
           source: @envelope_source,
           service: @service_name,
           tenant_id: tenant_id,
           health_signal: :nominal,
           uptime_seconds: max(uptime_seconds, 0)
         ) do
      {:ok, _} ->
        Logger.debug("[PulsePublisher] Published system.health")

      {:error, reason} ->
        Logger.warning("[PulsePublisher] Failed to publish system.health: #{inspect(reason)}")
    end
  end
end
