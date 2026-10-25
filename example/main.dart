// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_discord/otel_discord.dart';

/// Traces Discord calls with OpenTelemetry.
///
/// `otel_discord` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Discord call in
/// [tracedDiscord]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'discord-example');

  // Wraps a Discord REST API call (channels.createMessage, channels.getMessages, guilds.getMember, etc.) in a CLIENT span.
  final discordId = await tracedDiscord<String>(
    resource: 'Order',
    action: 'example',
    guildId: 'guild_8f3a2c',
    channelId: 'channel_8f3a2c',
    messageId: 'message_8f3a2c',
    apiVersion: '1',
    invoke: () async {
      // Make the Discord call here, then report what it returned.
      return 'discord_8f3a2c';
    },
  );
  OTelLog.info('tracedDiscord returned $discordId');

  // Wraps a Discord webhook POST in a PRODUCER span.
  final discordWebhookId = await tracedDiscordWebhook<String>(
    webhookId: 'webhook_8f3a2c',
    payloadSize: 512,
    invoke: () async {
      // Make the Discord call here, then report what it returned.
      return 'discord_8f3a2c';
    },
  );
  OTelLog.info('tracedDiscordWebhook returned $discordWebhookId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutDiscordInstrumentationAsync.
  await runWithoutDiscordInstrumentationAsync(
    () => tracedDiscord<String>(
      resource: 'Order',
      action: 'example',
      guildId: 'guild_8f3a2c',
      channelId: 'channel_8f3a2c',
      messageId: 'message_8f3a2c',
      apiVersion: '1',
      invoke: () async {
        return 'discord_8f3a2c';
      },
    ),
  );

  await OTel.shutdown();
}
