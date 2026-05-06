defmodule BotArmyDiscordWebhookManager.DiscordPoster do
  @moduledoc """
  Behaviour for posting to Discord webhooks.
  Production: BotArmyDiscordWebhookManager.DiscordPoster.Req
  Tests: DiscordPosterMock (via Mox)
  """

  @callback post(url :: String.t(), payload :: map()) :: {:ok, any()} | {:error, any()}
end

defmodule BotArmyDiscordWebhookManager.DiscordPoster.Req do
  @moduledoc "Real Discord webhook poster via Req HTTP."

  @behaviour BotArmyDiscordWebhookManager.DiscordPoster

  @impl true
  def post(url, payload) do
    case Req.post(url, json: payload) do
      {:ok, %{status: status}} when status in 200..299 -> {:ok, status}
      {:ok, %{status: status, body: body}} -> {:error, {status, body}}
      {:error, reason} -> {:error, reason}
    end
  end
end
