import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

class OculumRealtimeService {
  OculumRealtimeService({
    required this.roomId,
    required this.playerName,
    required this.onEvent,
    required this.onPresenceChanged,
    required this.onStatusChanged,
    this.presenceDataProvider,
  }) : _presenceKey = 'presence_${DateTime.now().microsecondsSinceEpoch}';

  static bool supabaseAvailable = false;
  static String startupStatus = 'Supabase non inizializzato.';

  static const Set<String> supportedEvents = <String>{
    'hp_changed',
    'oculum_changed',
    'dice_roll',
    'party_log',
    'session_note',
    'session_notes_request',
    'session_notes_snapshot',
    'vtt_scene_request',
    'vtt_scene_shared',
    'vtt_asset_chunk',
    'vtt_token_patch',
    'vtt_door_patch',
    'vtt_ping',
    'sheet_ping',
    'sheet_sync_preview',
    'sheet_shared',
    'initiative_shared',
    'dungeon_shared',
    'friend_request',
    'friend_response',
    'role_update',
    'sheet_received_ack',
  };

  final String roomId;
  final String playerName;
  final void Function(String event, Map<String, dynamic> payload) onEvent;
  final void Function(List<Map<String, dynamic>> users) onPresenceChanged;
  final void Function(String status) onStatusChanged;
  final Map<String, dynamic> Function()? presenceDataProvider;

  final String _presenceKey;
  RealtimeChannel? _channel;
  bool _connected = false;
  bool _disposed = false;

  bool get isConnected => _connected && !_disposed && _channel != null;

  String get normalizedRoomId {
    final clean = roomId.trim().replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    if (clean.isEmpty) return 'test';
    return clean.length > 64 ? clean.substring(0, 64) : clean;
  }

  String get channelName => 'oculum_room_$normalizedRoomId';

  Future<void> connect() async {
    if (_disposed) return;

    if (!supabaseAvailable) {
      _safeStatus(startupStatus);
      return;
    }

    await disconnect(notify: false);

    try {
      final client = Supabase.instance.client;
      final channel = client.channel(
        channelName,
        opts: RealtimeChannelConfig(
          ack: true,
          self: true,
          key: _presenceKey,
          enabled: true,
        ),
      );

      _channel = channel;

      for (final eventName in supportedEvents) {
        channel.onBroadcast(
          event: eventName,
          callback: (payload) => _handleBroadcast(eventName, payload),
        );
      }

      channel.onPresenceSync((_) => _emitPresence());
      channel.onPresenceJoin((_) => _emitPresence());
      channel.onPresenceLeave((_) => _emitPresence());

      final subscribed = Completer<void>();
      channel.subscribe((status, error) {
        if (_disposed || _channel != channel) return;

        switch (status) {
          case RealtimeSubscribeStatus.subscribed:
            _connected = true;
            _safeStatus('Connesso a $channelName');
            unawaited(_trackPresence());
            if (!subscribed.isCompleted) subscribed.complete();
            break;
          case RealtimeSubscribeStatus.channelError:
            _connected = false;
            _safeStatus('Realtime errore canale: ${error ?? 'sconosciuto'}');
            if (!subscribed.isCompleted) {
              subscribed.completeError(error ?? 'Realtime channel error');
            }
            break;
          case RealtimeSubscribeStatus.closed:
            _connected = false;
            _safeStatus('Realtime disconnesso.');
            onPresenceChanged(const <Map<String, dynamic>>[]);
            if (!subscribed.isCompleted) {
              subscribed.completeError('Realtime closed');
            }
            break;
          case RealtimeSubscribeStatus.timedOut:
            _connected = false;
            _safeStatus('Realtime timeout.');
            if (!subscribed.isCompleted) {
              subscribed.completeError('Realtime timeout');
            }
            break;
        }
      });

      await subscribed.future.timeout(const Duration(seconds: 12));
    } catch (error) {
      _connected = false;
      _safeStatus('Realtime non connesso: $error');
      await disconnect(notify: false);
    }
  }

  Future<void> disconnect({bool notify = true}) async {
    final channel = _channel;
    _channel = null;
    _connected = false;

    if (channel != null && supabaseAvailable) {
      try {
        await channel.untrack().timeout(const Duration(seconds: 3));
      } catch (_) {}

      try {
        await Supabase.instance.client
            .removeChannel(channel)
            .timeout(const Duration(seconds: 5));
      } catch (_) {}
    }

    if (!_disposed) {
      onPresenceChanged(const <Map<String, dynamic>>[]);
      if (notify) _safeStatus('Realtime disconnesso.');
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    await disconnect(notify: false);
  }

  Future<void> sendHpChanged({
    required int currentHp,
    required int maxHp,
    required int tempHp,
    required int shield,
  }) {
    return _send('hp_changed', <String, dynamic>{
      'playerName': _displayName,
      'currentHp': currentHp,
      'maxHp': maxHp,
      'tempHp': tempHp,
      'shield': shield,
      'sentAt': _nowIso(),
    });
  }

  Future<void> sendOculumChanged({
    required int currentOculum,
    required int maxOculum,
  }) {
    return _send('oculum_changed', <String, dynamic>{
      'playerName': _displayName,
      'currentOculum': currentOculum,
      'maxOculum': maxOculum,
      'sentAt': _nowIso(),
    });
  }

  Future<void> sendDiceRoll({
    required String label,
    required int roll,
    required int bonus,
    required int total,
  }) {
    return _send('dice_roll', <String, dynamic>{
      'playerName': _displayName,
      'label': label,
      'roll': roll,
      'bonus': bonus,
      'total': total,
      'sentAt': _nowIso(),
    });
  }

  Future<void> sendPartyLog(String message) {
    return _send('party_log', <String, dynamic>{
      'playerName': _displayName,
      'message': message,
      'sentAt': _nowIso(),
    });
  }

  Future<void> sendSessionNote({
    required Map<String, dynamic> note,
    required String campaignId,
    required String campaignName,
  }) {
    return _send('session_note', <String, dynamic>{
      ...note,
      'playerName': _displayName,
      'campaignId': campaignId,
      'campaignName': campaignName,
      'sentAt': '${note['createdAt'] ?? _nowIso()}',
    });
  }

  Future<void> requestSessionNotes({
    required String requesterTag,
    required String campaignId,
  }) {
    return _send('session_notes_request', <String, dynamic>{
      'playerName': _displayName,
      'requesterTag': requesterTag,
      'campaignId': campaignId,
      'sentAt': _nowIso(),
    });
  }

  Future<void> sendSessionNotesSnapshot({
    required List<Map<String, dynamic>> notes,
    required String targetTag,
    required String syncId,
    required int chunkIndex,
    required int chunkCount,
    required String campaignId,
    required String campaignName,
  }) {
    return _send('session_notes_snapshot', <String, dynamic>{
      'playerName': _displayName,
      'notes': notes,
      'targetTag': targetTag,
      'syncId': syncId,
      'chunkIndex': chunkIndex,
      'chunkCount': chunkCount,
      'campaignId': campaignId,
      'campaignName': campaignName,
      'sentAt': _nowIso(),
    });
  }

  Future<void> requestVttScene({required String requesterTag}) {
    return _send('vtt_scene_request', <String, dynamic>{
      'playerName': _displayName,
      'requesterTag': requesterTag,
      'sentAt': _nowIso(),
    });
  }

  Future<void> sendVttSceneSnapshot({
    required Map<String, dynamic> snapshot,
    required String campaignId,
    required String campaignName,
    required String assetId,
    required int assetChunkCount,
    String targetTag = '',
  }) {
    return _send('vtt_scene_shared', <String, dynamic>{
      'playerName': _displayName,
      'senderRole': 'master',
      'campaignId': campaignId,
      'campaignName': campaignName,
      'snapshot': snapshot,
      'assetId': assetId,
      'assetChunkCount': assetChunkCount,
      'targetTag': targetTag,
      'sentAt': _nowIso(),
    });
  }

  Future<void> sendVttAssetChunk({
    required String assetId,
    required int chunkIndex,
    required int chunkCount,
    required String data,
    String targetTag = '',
  }) {
    return _send('vtt_asset_chunk', <String, dynamic>{
      'playerName': _displayName,
      'senderRole': 'master',
      'assetId': assetId,
      'chunkIndex': chunkIndex,
      'chunkCount': chunkCount,
      'data': data,
      'targetTag': targetTag,
      'sentAt': _nowIso(),
    });
  }

  Future<void> sendVttTokenPatch({
    required String campaignId,
    required String sceneId,
    required String tokenId,
    required String senderRole,
    required String senderTag,
    required double x,
    required double y,
    required double movementUsedMeters,
  }) {
    return _send('vtt_token_patch', <String, dynamic>{
      'playerName': _displayName,
      'campaignId': campaignId,
      'sceneId': sceneId,
      'tokenId': tokenId,
      'senderRole': senderRole,
      'senderTag': senderTag,
      'x': x,
      'y': y,
      'movementUsedMeters': movementUsedMeters,
      'sentAt': _nowIso(),
    });
  }

  Future<void> sendVttDoorPatch({
    required String campaignId,
    required String sceneId,
    required String doorId,
    required String senderRole,
    required String senderTag,
    required bool open,
  }) {
    return _send('vtt_door_patch', <String, dynamic>{
      'playerName': _displayName,
      'campaignId': campaignId,
      'sceneId': sceneId,
      'doorId': doorId,
      'senderRole': senderRole,
      'senderTag': senderTag,
      'open': open,
      'sentAt': _nowIso(),
    });
  }

  Future<void> sendVttPing({
    required String campaignId,
    required String sceneId,
    required String pingId,
    required String senderRole,
    required String senderTag,
    required double x,
    required double y,
    required int colorArgb,
  }) {
    return _send('vtt_ping', <String, dynamic>{
      'playerName': _displayName,
      'campaignId': campaignId,
      'sceneId': sceneId,
      'pingId': pingId,
      'senderRole': senderRole,
      'senderTag': senderTag,
      'x': x,
      'y': y,
      'colorArgb': colorArgb,
      'sentAt': _nowIso(),
    });
  }

  Future<void> sendPing() {
    return _send('sheet_ping', <String, dynamic>{
      'playerName': _displayName,
      'message': 'ping',
      'sentAt': _nowIso(),
    });
  }

  Future<void> sendSheetSyncPreview(Map<String, dynamic> smallState) {
    return _send('sheet_sync_preview', <String, dynamic>{
      'playerName': _displayName,
      'smallState': smallState,
      'sentAt': _nowIso(),
    });
  }

  Future<void> sendInitiativeSnapshot({
    required Map<String, dynamic> snapshot,
    required String campaignId,
    required String campaignName,
    required bool closed,
  }) {
    return _send('initiative_shared', <String, dynamic>{
      'playerName': _displayName,
      'senderRole': 'master',
      'campaignId': campaignId,
      'campaignName': campaignName,
      'closed': closed,
      'snapshot': snapshot,
      'sentAt': _nowIso(),
    });
  }

  Future<void> sendDungeonShared(Map<String, dynamic> message) {
    return _send('dungeon_shared', <String, dynamic>{
      'playerName': _displayName,
      ...message,
      'sentAt': _nowIso(),
    });
  }

  Future<void> sendSharedSheet({
    required Map<String, dynamic> sheet,
    required String campaignId,
    required String campaignName,
    required String sheetId,
    required String sheetName,
    required String ownerTag,
    required String senderRole,
    required String targetAudience,
    required bool fromMaster,
    required bool masterParty,
    List<String> targetTags = const <String>[],
    String deliveryId = '',
  }) {
    return _send('sheet_shared', <String, dynamic>{
      'playerName': _displayName,
      'ownerTag': ownerTag,
      'campaignId': campaignId,
      'campaignName': campaignName,
      'sheetId': sheetId,
      'sheetName': sheetName,
      'senderRole': senderRole,
      'targetAudience': targetAudience,
      'targetTags': targetTags,
      'fromMaster': fromMaster,
      'masterParty': masterParty,
      'sheet': sheet,
      'deliveryId': deliveryId,
      'sentAt': _nowIso(),
    });
  }

  Future<bool> sendSharedSheetConfirmed({
    required Map<String, dynamic> sheet,
    required String campaignId,
    required String campaignName,
    required String sheetId,
    required String sheetName,
    required String ownerTag,
    required String senderRole,
    required String targetAudience,
    required bool fromMaster,
    required bool masterParty,
    List<String> targetTags = const <String>[],
    String deliveryId = '',
  }) {
    return _sendConfirmed('sheet_shared', <String, dynamic>{
      'playerName': _displayName,
      'ownerTag': ownerTag,
      'campaignId': campaignId,
      'campaignName': campaignName,
      'sheetId': sheetId,
      'sheetName': sheetName,
      'senderRole': senderRole,
      'targetAudience': targetAudience,
      'targetTags': targetTags,
      'fromMaster': fromMaster,
      'masterParty': masterParty,
      'sheet': sheet,
      'deliveryId': deliveryId,
      'sentAt': _nowIso(),
    });
  }

  Future<void> sendSheetReceivedAck({
    required String deliveryId,
    required String ownerTag,
    required String sheetId,
    required String sheetName,
    required String campaignId,
    required String campaignName,
    required String receiverRole,
    required String receiverTag,
  }) {
    return _send('sheet_received_ack', <String, dynamic>{
      'playerName': _displayName,
      'deliveryId': deliveryId,
      'ownerTag': ownerTag,
      'sheetId': sheetId,
      'sheetName': sheetName,
      'campaignId': campaignId,
      'campaignName': campaignName,
      'receiverRole': receiverRole,
      'receiverTag': receiverTag,
      'sentAt': _nowIso(),
    });
  }

  Future<void> sendFriendRequest({
    required String requestId,
    required String targetTag,
    required String requesterTag,
    required String requesterName,
  }) {
    return _send('friend_request', <String, dynamic>{
      'playerName': _displayName,
      'requestId': requestId,
      'targetTag': targetTag,
      'requesterTag': requesterTag,
      'requesterName': requesterName,
      'sentAt': _nowIso(),
    });
  }

  Future<void> sendFriendResponse({
    required String requestId,
    required String targetTag,
    required String responderTag,
    required String responderName,
    required String status,
  }) {
    return _send('friend_response', <String, dynamic>{
      'playerName': _displayName,
      'requestId': requestId,
      'targetTag': targetTag,
      'responderTag': responderTag,
      'responderName': responderName,
      'status': status,
      'sentAt': _nowIso(),
    });
  }

  Future<void> sendRoleUpdate({
    required String targetTag,
    required String targetName,
    required bool coMaster,
    required String campaignId,
    required String campaignName,
  }) {
    return _send('role_update', <String, dynamic>{
      'playerName': _displayName,
      'targetTag': targetTag,
      'targetName': targetName,
      'coMaster': coMaster,
      'campaignId': campaignId,
      'campaignName': campaignName,
      'sentAt': _nowIso(),
    });
  }

  Future<void> refreshPresence() => _trackPresence();

  Future<void> _send(String event, Map<String, dynamic> payload) async {
    await _sendConfirmed(event, payload);
  }

  Future<bool> _sendConfirmed(
    String event,
    Map<String, dynamic> payload,
  ) async {
    final channel = _channel;
    if (!isConnected || channel == null) {
      _safeStatus('Realtime non connesso.');
      return false;
    }

    try {
      await channel
          .sendBroadcastMessage(event: event, payload: payload)
          .timeout(const Duration(seconds: 6));
      return true;
    } catch (error) {
      _safeStatus('Invio realtime fallito: $error');
      return false;
    }
  }

  Future<void> _trackPresence() async {
    final channel = _channel;
    if (!isConnected || channel == null) return;

    try {
      final payload = <String, dynamic>{
        'playerName': _displayName,
        'roomId': normalizedRoomId,
        'joinedAt': _nowIso(),
      };

      final extra = presenceDataProvider?.call();
      if (extra != null) {
        payload.addAll(extra);
      }

      await channel.track(payload).timeout(const Duration(seconds: 6));
      _emitPresence();
    } catch (error) {
      _safeStatus('Presence non aggiornata: $error');
    }
  }

  void _handleBroadcast(String event, Map<String, dynamic> payload) {
    if (_disposed) return;

    final nestedPayload = payload['payload'];
    final normalized = nestedPayload is Map
        ? Map<String, dynamic>.from(nestedPayload)
        : Map<String, dynamic>.from(payload);

    onEvent(event, normalized);
  }

  void _emitPresence() {
    if (_disposed) return;

    final channel = _channel;
    if (channel == null) {
      onPresenceChanged(const <Map<String, dynamic>>[]);
      return;
    }

    final users = <Map<String, dynamic>>[];
    for (final state in channel.presenceState()) {
      for (final presence in state.presences) {
        users.add(<String, dynamic>{...presence.payload});
      }
    }
    onPresenceChanged(users);
  }

  void _safeStatus(String status) {
    if (_disposed) return;
    onStatusChanged(status);
  }

  String get _displayName {
    final clean = playerName.trim();
    return clean.isEmpty ? 'Oculum Player' : clean;
  }

  static String _nowIso() => DateTime.now().toIso8601String();
}
