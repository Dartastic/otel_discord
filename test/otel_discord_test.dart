// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_discord/otel_discord.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_discord-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('channels.createMessage records CLIENT span', () async {
    await tracedDiscord<String>(
      resource: 'channels',
      action: 'createMessage',
      guildId: 'g-1',
      channelId: 'c-1',
      apiVersion: 'v10',
      invoke: () async => 'msg-1',
    );
    final a = attrsOf(
      spans.findSpanByName('discord channels.createMessage')!,
    );
    expect(a['discord.resource'], 'channels');
    expect(a['discord.action'], 'createMessage');
    expect(a['discord.guild.id'], 'g-1');
    expect(a['discord.channel.id'], 'c-1');
    expect(a['discord.api.version'], 'v10');
  });

  test('webhook records PRODUCER span', () async {
    await tracedDiscordWebhook<String>(
      webhookId: 'wh-1',
      payloadSize: 100,
      invoke: () async => 'ok',
    );
    final span = spans.findSpanByName('discord webhook');
    expect(span!.kind, SpanKind.producer);
    final a = attrsOf(span);
    expect(a['messaging.system'], 'discord_webhook');
    expect(a['discord.webhook.id'], 'wh-1');
    expect(a['messaging.message.body.size'], 100);
  });

  test('suppression skips spans', () async {
    await runWithoutDiscordInstrumentationAsync(() async {
      await tracedDiscord<String>(
        resource: 'r',
        action: 'a',
        invoke: () async => 'ok',
      );
    });
    expect(spans.findSpansStartingWith('discord '), isEmpty);
  });
}
