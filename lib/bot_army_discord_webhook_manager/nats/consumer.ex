defmodule BotArmyDiscordWebhookManager.NATS.Consumer do
  @moduledoc """
  Subscribes to bridge.discord.message.send and routes to Discord webhooks.

  Payload format:
    {
      "payload": {
        "bot_name": "dispatcher",
        "channel": "alerts",      -- optional; falls back to routing table
        "content": "...",         -- required
        "username": "Dispatcher"  -- optional; shown as sender in Discord
      }
    }

  Fire-and-forget — no reply expected. Never crashes on bad payloads.
  """

  use GenServer
  require Logger

  alias BotArmyDiscordWebhookManager.{WebhookConfig, DiscordPoster}

  @reconnect_delay_ms 5000
  @version Mix.Project.config()[:version]

  @subjects [
    %{
      subject: "bridge.discord.message.send",
      type: :subscribe,
      description: "Post message to Discord channel via webhook"
    }
  ]

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    Logger.info("[Consumer] Starting Discord Webhook Manager consumer")
    poster = Keyword.get(opts, :discord_poster, DiscordPoster.Req)
    state = %{subscriptions: [], conn: nil, poster: poster}
    {:ok, state, {:continue, :connect}}
  end

  @impl true
  def handle_continue(:connect, state) do
    case GenServer.call(BotArmyRuntime.NATS.Connection, :get_connection, 5000) do
      {:ok, conn} ->
        BotArmyRuntime.NATS.Connection.subscribe_to_status()
        Logger.info("[Consumer] Connected to NATS, subscribing")

        subscriptions =
          ["bridge.discord.message.send"]
          |> Enum.map(fn subject ->
            case Gnat.sub(conn, self(), subject) do
              {:ok, sub} ->
                Logger.info("[Consumer] Subscribed to #{subject}")
                sub

              {:error, reason} ->
                Logger.error("[Consumer] Failed to subscribe to #{subject}: #{inspect(reason)}")
                nil
            end
          end)
          |> Enum.filter(&(not is_nil(&1)))

        BotArmyRuntime.Registry.register("discord_webhook_manager", @subjects, @version)

        {:noreply, %{state | subscriptions: subscriptions, conn: conn}}

      {:error, _reason} ->
        Logger.warning("[Consumer] NATS not ready, will retry")
        Process.send_after(self(), :connect_retry, @reconnect_delay_ms)
        {:noreply, state}
    end
  end

  @impl true
  def handle_info(:connect_retry, state) do
    {:noreply, state, {:continue, :connect}}
  end

  @impl true
  def handle_info({:msg, msg}, state) do
    BotArmyRuntime.Tracing.with_consumer_span(msg.topic, Map.get(msg, :headers), fn ->
      case msg.topic do
        "bridge.discord.message.send" -> handle_send(msg, state.poster)
        _ -> :ok
      end
    end)

    {:noreply, state}
  end

  @impl true
  def handle_info({:nats, :disconnected}, state) do
    Logger.warning("[Consumer] Disconnected from NATS, will reconnect")
    Process.send_after(self(), :connect_retry, @reconnect_delay_ms)
    {:noreply, %{state | subscriptions: [], conn: nil}}
  end

  @impl true
  def handle_info({:nats, :connected}, state) do
    {:noreply, state, {:continue, :connect}}
  end

  @impl true
  def handle_info(:reconnect, state) do
    {:noreply, state, {:continue, :connect}}
  end

  defp handle_send(msg, poster) do
    case Jason.decode(msg.body) do
      {:ok, envelope} ->
        payload = Map.get(envelope, "payload", %{})
        content = Map.get(payload, "content")

        if is_binary(content) and content != "" do
          bot_name = Map.get(payload, "bot_name", "")
          channel = Map.get(payload, "channel") || WebhookConfig.channel_for_bot(bot_name)
          username = Map.get(payload, "username", bot_name)

          case WebhookConfig.url_for_channel(channel) do
            nil ->
              Logger.error("[Consumer] No webhook URL for channel #{channel}, dropping")

            url ->
              discord_payload = %{"content" => content, "username" => username}

              case poster.post(url, discord_payload) do
                {:ok, _} ->
                  Logger.info("[Consumer] Posted to Discord ##{channel} for #{bot_name}")

                {:error, reason} ->
                  Logger.error(
                    "[Consumer] Failed to post to Discord ##{channel}: #{inspect(reason)}"
                  )
              end
          end
        else
          Logger.warning("[Consumer] Missing or empty content field, dropping")
        end

      {:error, reason} ->
        Logger.warning("[Consumer] Failed to decode message: #{inspect(reason)}")
    end
  end
end
