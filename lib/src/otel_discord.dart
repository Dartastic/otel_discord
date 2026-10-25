// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

import 'otel_discord_suppression.dart';

const _tracerName = 'dartastic_otel_libs_discord';

APITracer _tracer() => OTelAPI.tracerProvider().getTracer(_tracerName);

/// Wraps a Discord REST API call (channels.createMessage,
/// channels.getMessages, guilds.getMember, etc.) in a CLIENT span.
Future<T> tracedDiscord<T>({
  required String resource,
  required String action,
  required Future<T> Function() invoke,
  String? guildId,
  String? channelId,
  String? messageId,
  String? apiVersion,
}) async {
  if (discordInstrumentationSuppressed()) {
    return invoke();
  }
  final m = <String, Object>{
    'discord.resource': resource,
    'discord.action': action,
    'discord.operation': '$resource.$action',
  };
  if (guildId != null) m['discord.guild.id'] = guildId;
  if (channelId != null) m['discord.channel.id'] = channelId;
  if (messageId != null) m['discord.message.id'] = messageId;
  if (apiVersion != null) m['discord.api.version'] = apiVersion;

  final span = _tracer().startSpan(
    'discord $resource.$action',
    kind: SpanKind.client,
    attributes: OTelAPI.attributesFromMap(m),
  );
  try {
    return await invoke();
  } catch (e, st) {
    span.addAttributes(OTelAPI.attributes([
      OTelAPI.attributeString(
        ErrorAttributes.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}

/// Wraps a Discord webhook POST in a PRODUCER span.
Future<T> tracedDiscordWebhook<T>({
  required Future<T> Function() invoke,
  String? webhookId,
  int? payloadSize,
}) async {
  if (discordInstrumentationSuppressed()) {
    return invoke();
  }
  final m = <String, Object>{
    'messaging.system': 'discord_webhook',
    'messaging.operation': 'publish',
    'messaging.destination.name': webhookId ?? 'webhook',
  };
  if (webhookId != null) m['discord.webhook.id'] = webhookId;
  if (payloadSize != null) m['messaging.message.body.size'] = payloadSize;

  final span = _tracer().startSpan(
    'discord webhook',
    kind: SpanKind.producer,
    attributes: OTelAPI.attributesFromMap(m),
  );
  try {
    return await invoke();
  } catch (e, st) {
    span.addAttributes(OTelAPI.attributes([
      OTelAPI.attributeString(
        ErrorAttributes.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
