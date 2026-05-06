Application.ensure_all_started(:mox)

ExUnit.configure(exclude: [:integration, :load, :nats_live])

ExUnit.start()

Mox.defmock(DiscordPosterMock, for: BotArmyDiscordWebhookManager.DiscordPoster)
