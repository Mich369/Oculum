import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'oculum_sheet_transfer.dart';
import 'oculum_chunk_recovery.dart';
import 'oculum_room_activity.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

// Supabase owns senderTag and canonicalizes it to uppercase. Match only the
// same authenticated identity back to an existing packet reference; saved tags
// and the server-owned role, session and user fields remain unchanged.
Map<String, dynamic> oculumVerifiedPacketIdentity(
  Map<String, dynamic> payload,
) {
  final result = Map<String, dynamic>.from(payload);
  for (final key in const [
    'sourceTag',
    'targetTag',
    'ownerTag',
    'requesterTag',
    'receiverTag',
  ]) {
    if (oculumSameSheetIdentity(payload['senderTag'], payload[key])) {
      result['senderTag'] = payload[key];
      break;
    }
  }
  return result;
}

bool oculumSameSheetIdentity(dynamic left, dynamic right) {
  String canonical(dynamic value) =>
      '${value ?? ''}'.replaceAll(RegExp(r'\s+'), '').toUpperCase();
  final identity = canonical(left);
  return identity.isNotEmpty && identity == canonical(right);
}

class OculumRealtimeService {
  /// Keep presence and durable-event reconciliation responsive without
  /// continuously querying PostgREST when Realtime is already connected.
  static const Duration roomRefreshInterval = Duration(seconds: 15);
  static const Duration httpPollingInterval = Duration(seconds: 5);

  OculumRealtimeService({
    required this.roomId,
    required this.playerName,
    required this.onEvent,
    required this.onPresenceChanged,
    required this.onStatusChanged,
    this.presenceDataProvider,
    this.onConnected,
    this.onAccessRequested,
    this.onIdleWarning,
    this.onIdleClosed,
    this.httpPollingOnly = false,
    this.roomPassword = '',
    SupabaseClient? client,
  }) : _client = client,
       _presenceKey = _newSessionId();

  static String _newSessionId() {
    final random = Random.secure();
    return 'presence_${List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
  }

  static bool supabaseAvailable = false;
  static String startupStatus = 'Supabase non inizializzato.';

  static const Set<String> supportedEvents = <String>{
    'room_member_removed',
    'combat_attack',
    'initiative_control',
    'combat_defense',
    'combat_help',
    'combat_ack',
    'combat_scout',
    'pawn_snapshot',
    'pawn_command',
    'pawn_intercept_request',
    'pawn_intercept_result',
    'hp_changed',
    'oculum_changed',
    'dice_roll',
    'party_log',
    'damage_report',
    'session_note',
    'session_note_chunk',
    'session_notes_request',
    'session_notes_snapshot',
    'recipes_request',
    'recipes_snapshot',
    'monster_book_snapshot',
    'vtt_scene_request',
    'vtt_scene_shared',
    'vtt_asset_chunk',
    'vtt_token_patch',
    'vtt_door_patch',
    'vtt_ping',
    'sheet_ping',
    'sheet_sync_preview',
    'sheet_shared',
    'sheet_shared_chunk',
    'initiative_shared',
    'initiative_turn_adjusted',
    'dungeon_shared',
    'friend_request',
    'friend_response',
    'role_update',
    'permission_request',
    'permission_decision',
    'sheet_received_ack',
    'diary_knowledge',
    'diary_knowledge_ack',
    'item_gift',
    'item_gift_ack',
  };

  final String roomId;
  final String playerName;
  final String roomPassword;
  final void Function(String event, Map<String, dynamic> payload) onEvent;
  final void Function(List<Map<String, dynamic>> users) onPresenceChanged;
  final void Function(String status) onStatusChanged;
  final Map<String, dynamic> Function()? presenceDataProvider;
  final void Function()? onConnected;
  final Future<bool?> Function(String userId, String displayName)?
  onAccessRequested;
  final void Function(bool visible)? onIdleWarning;
  final VoidCallback? onIdleClosed;
  OculumRoomActivity _activity = OculumRoomActivity(DateTime.now());
  DateTime _localUserActivity = DateTime.now();
  bool _idleClosing = false;

  void recordUserActivity() {
    final warned = _activity.warningAt != null;
    _localUserActivity = DateTime.now();
    _activity.record(_localUserActivity);
    if (warned) onIdleWarning?.call(false);
    // Reuse the existing presence write; never send a packet per mouse move.
    if (isConnected &&
        (_lastPresenceWrite == null ||
            _localUserActivity.difference(_lastPresenceWrite!) >=
                roomRefreshInterval)) {
      unawaited(_trackPresence());
    }
  }

  /// Use the authenticated HTTPS event journal instead of a websocket.
  /// Automatic mode falls back to this transport when websocket setup fails.
  final bool httpPollingOnly;

  final String _presenceKey;
  final SupabaseClient? _client;
  RealtimeChannel? _channel;
  bool _connected = false;
  bool _pollingFallback = false;
  bool _connectionPublished = false;
  bool _disposed = false;
  Future<void>? _connecting;
  bool _awaitingApproval = false;
  bool _masterRoleUnavailable = false;
  bool _requiresUserAction = false;
  bool roomPasswordProtected = false;
  String? unavailableActiveSheetTag;
  String? _registeredIdentitySignature;
  Completer<void>? _approvalCancelled;
  int _generation = 0;
  final _sheetTransfers = OculumSheetTransferAssembler();
  final _sessionNoteTransfers = OculumSheetTransferAssembler();
  int _sheetTransferSequence = 0;
  Future<void> _sheetSendTail = Future<void>.value();
  int _initiativeRevision = 0;
  String? _secureRoomId;
  String? authenticatedRole;
  Timer? _roomHeartbeat;
  Timer? _fallbackPollingTimer;
  Future<void>? _roomRefresh;
  Future<void>? _presenceRead;
  DateTime? _lastPresenceWrite;
  String? _lastPresenceSignature;
  DateTime? _nextRoomRefresh;
  int _roomRefreshFailures = 0;
  final _accessDecisions = <String>{};
  final _reportedSheetConflicts = <String>{};
  Future<void> _incomingEvents = Future<void>.value();
  bool _presenceRegistered = false;
  final _deliveredEvents = <String>{};
  final _appliedAccessRevocations = <String>{};
  int _replaySequence = 0;
  int _initiativeRestoredGeneration = -1;
  final _replaySince = DateTime.now()
      .toUtc()
      .subtract(const Duration(minutes: 5))
      .toIso8601String();

  bool get _transportActive =>
      _connected && !_disposed && (_channel != null || _pollingFallback);

  bool get isConnected => _transportActive && _presenceRegistered;
  bool get isConnecting => _connecting != null;
  bool get isAwaitingApproval => _awaitingApproval;
  bool get masterRoleUnavailable => _masterRoleUnavailable;
  bool get requiresUserAction => _requiresUserAction;

  String get normalizedRoomId {
    final clean = roomId.trim().replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    if (clean.isEmpty) return '';
    return clean.length > 64 ? clean.substring(0, 64) : clean;
  }

  String get channelName => _secureRoomId == null
      ? 'oculum_room_$normalizedRoomId'
      : 'oculum_secure_$_secureRoomId';

  Future<void> connect() {
    if (_disposed || isConnected) return Future<void>.value();
    return _connecting ??= _connect().whenComplete(() => _connecting = null);
  }

  Future<void> _connect() async {
    if (_disposed) return;
    if (normalizedRoomId.isEmpty) {
      _requiresUserAction = true;
      _safeStatus('Inserisci il codice stanza del Master.');
      return;
    }

    if (!supabaseAvailable) {
      _safeStatus(startupStatus);
      return;
    }

    final generation = _generation + 1;
    await disconnect(notify: false);
    if (_disposed || generation != _generation) return;
    _masterRoleUnavailable = false;
    _requiresUserAction = false;
    _secureRoomId = null;
    authenticatedRole = null;

    try {
      final client = _client ?? Supabase.instance.client;
      if (client.auth.currentSession == null) {
        await client.auth.signInAnonymously().timeout(
          const Duration(seconds: 20),
        );
      }
      if (_disposed || generation != _generation) return;
      final requestedRole = presenceDataProvider?.call()['role'];
      var membership = Map<String, dynamic>.from(
        await client.rpc(
              roomPassword.isEmpty
                  ? 'oculum_open_room'
                  : 'oculum_open_room_with_password',
              params: {
                'p_code': normalizedRoomId,
                'p_name': _displayName,
                'p_as_master': requestedRole == 'master',
                if (roomPassword.isNotEmpty) 'p_password': roomPassword,
              },
            )
            as Map,
      );
      if (_disposed || generation != _generation) return;
      _masterRoleUnavailable =
          requestedRole == 'master' && membership['role'] != 'master';
      roomPasswordProtected = membership['passwordProtected'] == true;
      final pendingRoomId = '${membership['roomId']}';
      final approvalCancelled = Completer<void>();
      _approvalCancelled = approvalCancelled;
      while (true) {
        if (_disposed || generation != _generation) return;
        if (membership['status'] == 'denied') {
          throw StateError('Il Master non ha autorizzato l’ingresso.');
        }
        if (membership['status'] == 'approved') break;
        _awaitingApproval = true;
        _safeStatus(
          _masterRoleUnavailable
              ? 'Questa stanza appartiene a un altro account. Ingresso come giocatore in attesa del Master. Per ospitare, crea una nuova stanza oppure accedi con l’account proprietario.'
              : 'Ingresso richiesto: in attesa della conferma del Master.',
        );
        await Future.any<void>([
          Future<void>.delayed(const Duration(seconds: 10)),
          approvalCancelled.future,
        ]);
        if (_disposed || generation != _generation) return;
        // Opening a room takes a write lock. Poll only our own membership
        // while pending, without repeatedly submitting the same request.
        final updated = await client
            .from('oculum_room_members')
            .select('role,status')
            .eq('room_id', pendingRoomId)
            .eq('user_id', client.auth.currentUser!.id)
            .maybeSingle()
            .timeout(const Duration(seconds: 20));
        if (updated == null) {
          throw StateError('Richiesta di ingresso non più disponibile.');
        }
        membership = {...membership, ...updated};
      }
      if (_disposed || generation != _generation) return;
      _awaitingApproval = false;
      _approvalCancelled = null;
      _secureRoomId = '${membership['roomId']}';
      authenticatedRole = '${membership['role']}';
      if (httpPollingOnly) {
        await _startHttpPollingFallback(
          'Il client usa la sincronizzazione HTTPS compatibile.',
        );
        return;
      }
      final channel = client.channel(
        channelName,
        opts: RealtimeChannelConfig(
          ack: true,
          self: true,
          key: _presenceKey,
          enabled: true,
          private: true,
        ),
      );

      _channel = channel;

      for (final eventName in supportedEvents) {
        channel.onBroadcast(
          event: eventName,
          callback: (payload) {
            if (_channel == channel) {
              _incomingEvents = _incomingEvents.then(
                (_) => _handleBroadcast(eventName, payload),
              );
            }
          },
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
            final wasConnected = _connected;
            _pollingFallback = false;
            _connected = true;
            _safeStatus('Connesso a $channelName');
            _presenceRegistered = false;
            unawaited(() async {
              await _trackPresence();
              if (_disposed || _channel != channel) return;
              if (!_presenceRegistered) {
                if (!subscribed.isCompleted) {
                  subscribed.completeError(
                    'Registrazione della sessione non riuscita.',
                  );
                }
                return;
              }
              if (!subscribed.isCompleted) subscribed.complete();
              if (!wasConnected) _notifyConnectedOnce();
            }());
            _roomHeartbeat?.cancel();
            _roomHeartbeat = Timer.periodic(
              roomRefreshInterval,
              (_) => unawaited(_trackPresence()),
            );
            break;
          case RealtimeSubscribeStatus.channelError:
            _connected = false;
            _presenceRegistered = false;
            _connectionPublished = false;
            _safeStatus('Realtime errore canale: ${error ?? 'sconosciuto'}');
            if (!subscribed.isCompleted) {
              subscribed.completeError(error ?? 'Realtime channel error');
            }
            break;
          case RealtimeSubscribeStatus.closed:
            _connected = false;
            _presenceRegistered = false;
            _connectionPublished = false;
            _safeStatus('Realtime disconnesso.');
            onPresenceChanged(const <Map<String, dynamic>>[]);
            if (!subscribed.isCompleted) {
              subscribed.completeError('Realtime closed');
            }
            break;
          case RealtimeSubscribeStatus.timedOut:
            _connected = false;
            _presenceRegistered = false;
            _connectionPublished = false;
            _safeStatus('Realtime timeout.');
            if (!subscribed.isCompleted) {
              subscribed.completeError('Realtime timeout');
            }
            break;
        }
      });

      await subscribed.future.timeout(const Duration(seconds: 12));
    } catch (error) {
      if (_disposed || generation != _generation) return;
      await disconnect(notify: false);
      if (_disposed) return;
      final client = _client ?? Supabase.instance.client;
      if (_secureRoomId != null &&
          authenticatedRole != null &&
          client.auth.currentSession != null) {
        await _startHttpPollingFallback(
          'WebSocket non disponibile; uso la sincronizzazione HTTPS: $error',
        );
      } else {
        _requiresUserAction =
            error is PostgrestException &&
            (error.code == '42501' || error.code == '22023');
        _safeStatus('Realtime non connesso: $error');
      }
    }
  }

  Future<bool> setRoomPassword(String password) async {
    if (!isConnected ||
        authenticatedRole != 'master' ||
        _secureRoomId == null) {
      return false;
    }
    try {
      await (_client ?? Supabase.instance.client)
          .rpc(
            'oculum_set_room_password',
            params: {'p_room': _secureRoomId, 'p_password': password},
          )
          .timeout(const Duration(seconds: 20));
      roomPasswordProtected = password.isNotEmpty;
      _safeStatus(
        password.isEmpty
            ? 'Password della stanza rimossa.'
            : 'Password della stanza aggiornata.',
      );
      return true;
    } catch (error) {
      _safeStatus('Password della stanza non aggiornata: $error');
      return false;
    }
  }

  Future<bool> decideRoomAccess(String userId, bool allowed) async {
    if (!isConnected || authenticatedRole != 'master') return false;
    try {
      await (_client ?? Supabase.instance.client)
          .rpc(
            'oculum_decide_room_member',
            params: {
              'p_room': _secureRoomId,
              'p_user': userId,
              'p_allow': allowed,
              'p_role': 'player',
            },
          )
          .timeout(const Duration(seconds: 20));
      return true;
    } catch (error) {
      _safeStatus('Richiesta di ingresso non aggiornata: $error');
      return false;
    }
  }

  Future<void> _reviewRoomAccess(
    String userId,
    String name,
    int generation,
  ) async {
    if (!_accessDecisions.add(userId)) return;
    try {
      final allowed = await onAccessRequested!(userId, name);
      if (_disposed || generation != _generation || allowed == null) return;
      await decideRoomAccess(userId, allowed);
    } catch (error) {
      if (!_disposed && generation == _generation) {
        _safeStatus('Richiesta di ingresso in attesa: $error');
      }
    } finally {
      _accessDecisions.remove(userId);
    }
  }

  Future<void> _startHttpPollingFallback(String status) async {
    if (_disposed || _secureRoomId == null || authenticatedRole == null) {
      return;
    }
    _fallbackPollingTimer?.cancel();
    _pollingFallback = true;
    _connected = true;
    _safeStatus(status);
    _fallbackPollingTimer = Timer.periodic(httpPollingInterval, (_) {
      unawaited(_trackPresence());
    });
    await _trackPresence();
  }

  Future<void> disconnect({bool notify = true}) async {
    _activity = OculumRoomActivity(DateTime.now());
    _localUserActivity = DateTime.now();
    _idleClosing = false;
    _generation++;
    _sheetSendTail = Future<void>.value();
    final approvalCancelled = _approvalCancelled;
    _approvalCancelled = null;
    _awaitingApproval = false;
    if (approvalCancelled != null && !approvalCancelled.isCompleted) {
      approvalCancelled.complete();
    }
    _roomHeartbeat?.cancel();
    _roomHeartbeat = null;
    _fallbackPollingTimer?.cancel();
    _fallbackPollingTimer = null;
    _pollingFallback = false;
    _presenceRegistered = false;
    _connectionPublished = false;
    _registeredIdentitySignature = null;
    unavailableActiveSheetTag = null;
    _lastPresenceWrite = null;
    _lastPresenceSignature = null;
    _nextRoomRefresh = null;
    _roomRefreshFailures = 0;
    _roomRefresh = null;
    _presenceRead = null;
    _sheetTransfers.clear();
    _sessionNoteTransfers.clear();
    final channel = _channel;
    _channel = null;
    _connected = false;

    if (channel != null && supabaseAvailable) {
      try {
        await channel.untrack().timeout(const Duration(seconds: 3));
      } catch (_) {}

      try {
        await (_client ?? Supabase.instance.client)
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
    int larvalBroodHp = 0,
    int larvalBroodMaxHp = 0,
  }) {
    return _send('hp_changed', <String, dynamic>{
      'playerName': _displayName,
      'currentHp': currentHp,
      'maxHp': maxHp,
      'tempHp': tempHp,
      'shield': shield,
      if (larvalBroodMaxHp > 0) ...{
        'larvalBroodHp': larvalBroodHp.clamp(0, larvalBroodMaxHp),
        'larvalBroodMaxHp': larvalBroodMaxHp,
      },
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

  Future<void> sendPawnEvent(String event, Map<String, dynamic> payload) {
    if (!event.startsWith('pawn_') || !supportedEvents.contains(event)) {
      throw ArgumentError('Evento Pawn non supportato');
    }
    return _send(event, {
      ...payload,
      'playerName': _displayName,
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

  Future<void> moderateRoomSheet(
    String sheetTag, {
    required String action,
  }) async {
    if (!isConnected ||
        _secureRoomId == null ||
        !{'master', 'coMaster'}.contains(authenticatedRole) ||
        !{'kick', 'ban', 'unban'}.contains(action)) {
      throw StateError('Solo Master e Co-Master possono moderare la stanza.');
    }
    await (_client ?? Supabase.instance.client)
        .rpc(
          'oculum_moderate_room_sheet',
          params: {
            'p_room': _secureRoomId,
            'p_session': _presenceKey,
            'p_sheet_tag': sheetTag,
            'p_action': action,
          },
        )
        .timeout(const Duration(seconds: 15));
  }

  Future<List<Map<String, dynamic>>> listRoomBans() async {
    if (!isConnected ||
        _secureRoomId == null ||
        !{'master', 'coMaster'}.contains(authenticatedRole)) {
      throw StateError('Solo Master e Co-Master possono gestire i ban.');
    }
    final result = await (_client ?? Supabase.instance.client)
        .rpc('oculum_list_room_bans', params: {'p_room': _secureRoomId})
        .timeout(const Duration(seconds: 15));
    return (result as List)
        .whereType<Map>()
        .map((value) => Map<String, dynamic>.from(value))
        .toList(growable: false);
  }

  Future<void> sendDamageReport({
    required int baseDamage,
    required int bonusDamage,
    required int totalDamage,
    required String damageType,
    required String formula,
  }) {
    return _send('damage_report', <String, dynamic>{
      'playerName': _displayName,
      'baseDamage': baseDamage,
      'bonusDamage': bonusDamage,
      'totalDamage': totalDamage,
      'damageType': damageType,
      'formula': formula,
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

  Future<void> sendRecipesRequest({
    required String requesterTag,
    required String campaignId,
  }) {
    return _send('recipes_request', <String, dynamic>{
      'playerName': _displayName,
      'requesterTag': requesterTag,
      'campaignId': campaignId,
      'sentAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> sendRecipesSnapshot({
    required List<Map<String, dynamic>> recipes,
    required String campaignId,
    required String campaignName,
    String targetTag = '',
  }) {
    return _send('recipes_snapshot', <String, dynamic>{
      'playerName': _displayName,
      'campaignId': campaignId,
      'campaignName': campaignName,
      'targetTag': targetTag,
      'recipes': recipes,
      'sentAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> requestVttScene({required String requesterTag}) {
    return _send('vtt_scene_request', <String, dynamic>{
      'playerName': _displayName,
      'requesterTag': requesterTag,
      'sentAt': _nowIso(),
    });
  }

  Future<bool> sendVttSceneSnapshot({
    required Map<String, dynamic> snapshot,
    required String campaignId,
    required String campaignName,
    required String assetId,
    required int assetChunkCount,
    String targetTag = '',
  }) {
    return _sendConfirmed('vtt_scene_shared', <String, dynamic>{
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

  Future<bool> sendVttAssetChunk({
    required String assetId,
    required int chunkIndex,
    required int chunkCount,
    required String data,
    String targetTag = '',
  }) {
    return _sendConfirmed('vtt_asset_chunk', <String, dynamic>{
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
      'sessionId': _presenceKey,
      'revision': ++_initiativeRevision,
      'playerName': _displayName,
      'senderRole': 'master',
      'campaignId': campaignId,
      'campaignName': campaignName,
      'closed': closed,
      'snapshot': snapshot,
      'sentAt': _nowIso(),
    });
  }

  Future<void> sendInitiativeTurnAdjusted({
    required String senderRole,
    required String campaignId,
    required String campaignName,
    required String sheetTag,
    required int turn,
    String encounterId = '',
    bool joinEncounter = false,
    bool leaveEncounter = false,
  }) {
    return _send('initiative_turn_adjusted', <String, dynamic>{
      'sessionId': _presenceKey,
      'playerName': _displayName,
      'senderRole': senderRole,
      'campaignId': campaignId,
      'campaignName': campaignName,
      'sheetTag': sheetTag,
      'turn': turn,
      if (encounterId.isNotEmpty) 'encounterId': encounterId,
      if (joinEncounter) 'joinEncounter': true,
      if (leaveEncounter) 'leaveEncounter': true,
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

  Future<void> sendMonsterBookSnapshot({
    required String campaignId,
    required String campaignName,
    required List<Map<String, dynamic>> entries,
    required List<String> removedIds,
  }) {
    return _send('monster_book_snapshot', <String, dynamic>{
      'playerName': _displayName,
      'senderRole': 'master',
      'fromMaster': true,
      'campaignId': campaignId,
      'campaignName': campaignName,
      'entries': entries,
      'removedIds': removedIds,
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
    return _queueSharedSheet(<String, dynamic>{
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
    }).then<void>((_) {});
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
    List<String> allowClearFields = const <String>[],
    String deliveryId = '',
  }) {
    return _queueSharedSheet(<String, dynamic>{
      'playerName': _displayName,
      'ownerTag': ownerTag,
      'campaignId': campaignId,
      'campaignName': campaignName,
      'sheetId': sheetId,
      'sheetName': sheetName,
      'senderRole': senderRole,
      'targetAudience': targetAudience,
      'targetTags': targetTags,
      if (allowClearFields.isNotEmpty) 'allowClearFields': allowClearFields,
      'fromMaster': fromMaster,
      'masterParty': masterParty,
      'sheet': sheet,
      'deliveryId': deliveryId,
      'sentAt': _nowIso(),
    });
  }

  // Keep a complete sheet's chunks together. Publishing a large Master party
  // used to open dozens of transfers simultaneously, exceeding the receiver's
  // bounded assembler and starving player deliveries on small databases.
  Future<bool> _queueSharedSheet(Map<String, dynamic> payload) {
    final generation = _generation;
    final operation = _sheetSendTail.then<bool>((_) async {
      if (!isConnected || generation != _generation) return false;
      return _sendConfirmed('sheet_shared', payload);
    });
    _sheetSendTail = operation.then<void>((_) {}, onError: (Object _) {});
    return operation;
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
    bool trusted = false,
    String senderTag = '',
    String senderRole = 'master',
    String scope = '',
  }) {
    return _send('role_update', <String, dynamic>{
      'playerName': _displayName,
      'targetTag': targetTag,
      'targetName': targetName,
      'coMaster': coMaster,
      'trusted': trusted,
      'senderTag': senderTag,
      'senderRole': senderRole,
      'scope': scope,
      'campaignId': campaignId,
      'campaignName': campaignName,
      'sentAt': _nowIso(),
    });
  }

  Future<void> refreshPresence() => _trackPresence();

  Future<void> revokeSheetEditor(String targetTag, {String? sheetTag}) async {
    if (!isConnected || _secureRoomId == null) return;
    await (_client ?? Supabase.instance.client).rpc(
      'oculum_revoke_sheet_editor',
      params: {
        'p_room': _secureRoomId,
        'p_target_tag': targetTag,
        'p_sheet_tag': sheetTag,
      },
    );
  }

  Future<bool> sendCombatEvent(String event, Map<String, dynamic> payload) {
    if (event != 'combat_attack' &&
        event != 'combat_defense' &&
        event != 'combat_help' &&
        event != 'combat_ack' &&
        event != 'combat_scout' &&
        event != 'corruption_apply' &&
        event != 'corruption_target' &&
        event != 'initiative_control') {
      throw ArgumentError('Evento combattimento non supportato');
    }
    return _sendConfirmed(event, {
      ...payload,
      'sessionId': _presenceKey,
      'playerName': _displayName,
    });
  }

  /// Send only a campaign discovery marker through the existing lightweight
  /// party-log route, avoiding a Monster Book or character-sheet snapshot.
  Future<bool> sendMonsterBookDiscovery(Map<String, dynamic> payload) {
    return _sendConfirmed('party_log', {
      ...payload,
      'monsterBookDiscovery': true,
      'sessionId': _presenceKey,
      'playerName': _displayName,
      'sentAt': _nowIso(),
    });
  }

  /// Reconcile only compact Monster Book discovery markers after presence
  /// changes. This deliberately reuses the existing party-log event channel.
  Future<bool> sendMonsterBookDiscoverySnapshot(Map<String, dynamic> payload) {
    return _sendConfirmed('party_log', {
      ...payload,
      'monsterBookDiscoverySnapshot': true,
      'sessionId': _presenceKey,
      'playerName': _displayName,
      'sentAt': _nowIso(),
    });
  }

  /// Synchronize only campaign merchant identities and shop metadata.
  /// Per-character offers, stock, and purchase counters stay local.
  Future<bool> sendMerchantRosterSnapshot(Map<String, dynamic> payload) {
    return _sendConfirmed('party_log', {
      ...payload,
      'merchantRosterSnapshot': true,
      'sessionId': _presenceKey,
      'playerName': _displayName,
      'sentAt': _nowIso(),
    });
  }

  Future<bool> sendPermissionEvent(String event, Map<String, dynamic> payload) {
    if (event != 'permission_request' && event != 'permission_decision') {
      throw ArgumentError('Evento autorizzazione non supportato');
    }
    return _sendConfirmed(event, {...payload, 'playerName': _displayName});
  }

  Future<bool> sendDiaryKnowledge(
    Map<String, dynamic> envelope, {
    bool acknowledgement = false,
  }) => _sendConfirmed(
    acknowledgement ? 'diary_knowledge_ack' : 'diary_knowledge',
    envelope,
  );

  Future<bool> sendItemGift(
    Map<String, dynamic> envelope, {
    bool acknowledgement = false,
  }) =>
      _sendConfirmed(acknowledgement ? 'item_gift_ack' : 'item_gift', envelope);

  Future<void> requestSharedSheets({String targetSheetTag = ''}) =>
      requestSharedSheetsConfirmed(
        targetSheetTag: targetSheetTag,
      ).then<void>((_) {});

  Future<bool> requestSharedSheetsConfirmed({String targetSheetTag = ''}) =>
      _sendConfirmed('sheet_ping', {
        'playerName': _displayName,
        'senderRole': presenceDataProvider?.call()['role'] ?? 'player',
        'requestSharedSheets': true,
        if (targetSheetTag.isNotEmpty) 'targetSheetTag': targetSheetTag,
        'sentAt': _nowIso(),
      });

  Future<void> _send(String event, Map<String, dynamic> payload) async {
    await _sendConfirmed(event, payload);
  }

  Future<bool> _sendConfirmed(
    String event,
    Map<String, dynamic> payload,
  ) async {
    final channel = _channel;
    final generation = _generation;
    if (!isConnected || (channel == null && !_pollingFallback)) {
      _safeStatus('Realtime non connesso.');
      return false;
    }

    try {
      if (event == 'sheet_shared' ||
          '${payload['senderTag'] ?? ''}'.isNotEmpty) {
        // A newly selected/created sheet must be registered before its first
        // share; await an in-flight refresh rather than racing its owner RPC.
        if (event == 'sheet_shared' ||
            !_presenceRegistered ||
            _registeredIdentitySignature != _currentIdentitySignature) {
          await _trackPresence();
        }
        // A refresh started before a sheet switch may have registered the
        // previous identity. Finish registering the current identity first.
        if (generation == _generation &&
            _registeredIdentitySignature != _currentIdentitySignature) {
          await _trackPresence();
        }
        if (!isConnected || generation != _generation || _channel != channel) {
          return false;
        }
        final unavailable = unavailableActiveSheetTag;
        if (unavailable != null &&
            (event == 'sheet_shared' &&
                    _normalizedTag(payload['sheetId']) == unavailable ||
                _normalizedTag(payload['senderTag']) == unavailable)) {
          _safeStatus(
            'La scheda selezionata non è associata a questo account nella stanza. Usa l’account originale oppure una copia con un nuovo tag.',
          );
          return false;
        }
      }
      if (event == 'session_note' || event == 'session_notes_snapshot') {
        final generation = _generation;
        final encoded = await compute(
          oculumEncodeSheetTransfer,
          <String, dynamic>{'event': event, 'sheet': payload},
        );
        if (_channel != channel || !isConnected || generation != _generation) {
          return false;
        }
        if (encoded.length > OculumSheetTransferAssembler.chunkSize) {
          final count =
              (encoded.length / OculumSheetTransferAssembler.chunkSize).ceil();
          if (count > OculumSheetTransferAssembler.maxChunks) {
            _safeStatus(
              'Appunti troppo grandi per il trasferimento: salvataggio locale conservato.',
            );
            return false;
          }
          final transferId =
              '${_presenceKey}_notes_${++_sheetTransferSequence}';
          for (var i = 0; i < count; i++) {
            if (generation != _generation ||
                _channel != channel ||
                !isConnected) {
              return false;
            }
            final start = i * OculumSheetTransferAssembler.chunkSize;
            final end = (start + OculumSheetTransferAssembler.chunkSize).clamp(
              0,
              encoded.length,
            );
            if (!await _sendConfirmed('session_note_chunk', {
              'transferId': transferId,
              'chunkIndex': i,
              'chunkCount': count,
              'data': encoded.substring(start, end),
            })) {
              return false;
            }
            await Future<void>.delayed(const Duration(milliseconds: 60));
          }
          return generation == _generation &&
              _channel == channel &&
              isConnected;
        }
      }
      if (event == 'sheet_shared') {
        final generation = _generation;
        final encoded = await compute(oculumEncodeSheetTransfer, payload);
        if (_channel != channel || !isConnected || generation != _generation) {
          return false;
        }
        if (encoded.length > OculumSheetTransferAssembler.chunkSize) {
          final count =
              (encoded.length / OculumSheetTransferAssembler.chunkSize).ceil();
          if (count > OculumSheetTransferAssembler.maxChunks) {
            _safeStatus(
              'Scheda troppo grande per il trasferimento realtime. Salvataggio locale conservato.',
            );
            return false;
          }
          final transferId = '${_presenceKey}_${++_sheetTransferSequence}';
          for (var i = 0; i < count; i++) {
            if (generation != _generation ||
                _channel != channel ||
                !isConnected) {
              return false;
            }
            final start = i * OculumSheetTransferAssembler.chunkSize;
            final end = (start + OculumSheetTransferAssembler.chunkSize).clamp(
              0,
              encoded.length,
            );
            if (!await _sendConfirmed('sheet_shared_chunk', {
              '_routing': {
                'sheetId': payload['sheetId'],
                'senderRole': payload['senderRole'],
                'targetAudience': payload['targetAudience'],
                'targetTags': payload['targetTags'] ?? const [],
              },
              'transferId': transferId,
              'chunkIndex': i,
              'chunkCount': count,
              'data': encoded.substring(start, end),
            })) {
              return false;
            }
            // Persisted chunks are idempotent by transferId + chunkIndex.
            // Pace large transfers to avoid bursting the authenticated RPC.
            if (i + 1 < count) {
              await Future<void>.delayed(const Duration(milliseconds: 60));
            }
          }
          return generation == _generation &&
              _channel == channel &&
              isConnected;
        }
      }
      final retryChunk = event == 'sheet_shared_chunk';
      final client = _client ?? Supabase.instance.client;
      final parameters = <String, dynamic>{
        'p_room': _secureRoomId,
        'p_session': _presenceKey,
        'p_event': event,
        'p_payload': payload,
      };
      Object? response;
      for (var attempt = 0; attempt < (retryChunk ? 2 : 1); attempt++) {
        try {
          response = attempt == 0
              ? await client
                    .rpc('oculum_emit_room_event', params: parameters)
                    .timeout(Duration(seconds: retryChunk ? 30 : 15))
              : await oculumRecoverSheetChunk(
                  restUrl: client.rest.url,
                  headers: {
                    ...client.rest.headers,
                    if (client.realtime.headers['apikey'] != null)
                      'apikey': client.realtime.headers['apikey']!,
                  },
                  accessToken: client.auth.currentSession?.accessToken ?? '',
                  parameters: parameters,
                );
          break;
        } on TimeoutException {
          if (!retryChunk ||
              attempt > 0 ||
              _channel != channel ||
              !isConnected) {
            rethrow;
          }
          // A timed-out RPC may already have committed. Retrying only sheet
          // chunks is safe: the receiver ignores the same transfer/index pair.
          _safeStatus('Blocco scheda lento: ritento la conferma una volta.');
        }
      }
      if (_channel != channel || !isConnected) return false;
      if (response is String && response.isNotEmpty) return true;
      _safeStatus('Invio realtime non confermato.');
      return false;
    } catch (error) {
      if (error is PostgrestException &&
          error.code == '42501' &&
          error.message.contains('Sender sheet belongs')) {
        _safeStatus(
          'La scheda selezionata appartiene a un altro account online. Seleziona una tua scheda oppure accedi con l’account originale.',
        );
      } else {
        _safeStatus('Invio realtime fallito: $error');
      }
      return false;
    }
  }

  Future<void> _trackPresence() {
    final generation = _generation;
    return _roomRefresh ??= _refreshRoom().whenComplete(() {
      if (_generation == generation) _roomRefresh = null;
    });
  }

  static String _normalizedTag(dynamic tag) =>
      '${tag ?? ''}'.replaceAll(RegExp(r'\s+'), '').toUpperCase();

  String get _currentIdentitySignature => _identitySignature(
    presenceDataProvider?.call() ?? const <String, dynamic>{},
  );

  String _identitySignature(Map<String, dynamic> presence) =>
      jsonEncode([presence['activeSheetTag'], presence['localSheetTags']]);

  Future<void> _refreshRoom() async {
    final channel = _channel;
    final generation = _generation;
    bool stale() =>
        _disposed || _generation != generation || _channel != channel;
    if (!_transportActive ||
        (channel == null && !_pollingFallback) ||
        (_nextRoomRefresh != null &&
            DateTime.now().isBefore(_nextRoomRefresh!))) {
      return;
    }

    try {
      final payload = <String, dynamic>{
        'playerName': _displayName,
        'userActivityAt': _localUserActivity.toUtc().toIso8601String(),
        'roomId': normalizedRoomId,
        'joinedAt': _nowIso(),
        'sessionId': _presenceKey,
      };

      final extra = presenceDataProvider?.call();
      if (extra != null) {
        payload.addAll(extra);
      }
      final identitySignature = _identitySignature(payload);

      final revocations =
          (payload.remove('revokedSheetAccess') as List? ?? const [])
              .whereType<Map>()
              .toList();
      final revocationKeys = {
        for (final entry in revocations)
          '${entry['sheetTag'] ?? '*'}:${entry['targetTag']}',
      };
      _appliedAccessRevocations.removeWhere(
        (key) => !revocationKeys.contains(key),
      );

      final client = _client ?? Supabase.instance.client;
      final signature = jsonEncode(
        Map<String, dynamic>.from(payload)..remove('joinedAt'),
      );
      if (!_presenceRegistered ||
          signature != _lastPresenceSignature ||
          _lastPresenceWrite == null ||
          DateTime.now().difference(_lastPresenceWrite!) >=
              const Duration(seconds: 15)) {
        await client
            .rpc(
              'oculum_touch_room_session',
              params: {
                'p_room': _secureRoomId,
                'p_session': _presenceKey,
                'p_presence': payload,
              },
            )
            .timeout(const Duration(seconds: 10));
        if (stale()) return;
        _lastPresenceWrite = DateTime.now();
        _lastPresenceSignature = signature;
        _registeredIdentitySignature = identitySignature;
      }
      _presenceRegistered = true;
      for (final entry in revocations) {
        final key = '${entry['sheetTag'] ?? '*'}:${entry['targetTag']}';
        if (_appliedAccessRevocations.contains(key)) continue;
        await revokeSheetEditor(
          '${entry['targetTag']}',
          sheetTag: entry['sheetTag'] as String?,
        );
        if (stale()) return;
        _appliedAccessRevocations.add(key);
      }
      // Resolve authoritative roles/campaign before replaying snapshots and
      // permissions. Otherwise the UI can reject an event, then mark it seen.
      await _emitPresence();
      if (stale()) return;
      await _replayEvents(client, channel);
      if (stale()) return;
      if (_initiativeRestoredGeneration != _generation &&
          await _restoreLatestInitiativeSnapshot(client, channel)) {
        _initiativeRestoredGeneration = generation;
      }
      if (stale()) return;
      if (_presenceRegistered) _notifyConnectedOnce();
      _roomRefreshFailures = 0;
      _nextRoomRefresh = null;
      if (authenticatedRole == 'master' && onAccessRequested != null) {
        final pending = await client
            .from('oculum_room_members')
            .select('user_id,display_name')
            .eq('room_id', _secureRoomId!)
            .eq('status', 'pending')
            .timeout(const Duration(seconds: 10));
        if (stale()) return;
        for (final request in pending) {
          final userId = '${request['user_id']}';
          // Waiting for the Master must not block sheet registration, ACKs,
          // initiative replay or the room heartbeat.
          unawaited(
            _reviewRoomAccess(userId, '${request['display_name']}', generation),
          );
        }
      }
    } catch (error) {
      if (stale()) return;
      _roomRefreshFailures = min(5, _roomRefreshFailures + 1);
      _nextRoomRefresh = DateTime.now().add(
        Duration(seconds: min(60, 3 * (1 << _roomRefreshFailures))),
      );
      _safeStatus('Presence non aggiornata: $error');
    }
  }

  void _notifyConnectedOnce() {
    if (_disposed ||
        !_connected ||
        !_presenceRegistered ||
        _connectionPublished) {
      return;
    }
    _connectionPublished = true;
    onConnected?.call();
  }

  Future<void> _handleBroadcast(
    String event,
    Map<String, dynamic> payload,
  ) async {
    if (_disposed || !isConnected) return;
    final header = payload['payload'] is Map
        ? payload['payload'] as Map
        : payload;
    final id = header['serverEventId'];
    if (id is! String || _deliveredEvents.contains(id)) return;
    final channel = _channel;
    try {
      final record = await (_client ?? Supabase.instance.client)
          .from('oculum_room_events')
          .select('event,payload,sequence')
          .eq('room_id', _secureRoomId!)
          .eq('id', id)
          .maybeSingle()
          .timeout(const Duration(seconds: 10));
      if (_disposed ||
          _channel != channel ||
          record == null ||
          record['event'] != event ||
          record['payload'] is! Map) {
        return;
      }
      if (!_deliveredEvents.add(id)) return;
      if (_deliveredEvents.length > 4000) {
        _deliveredEvents.remove(_deliveredEvents.first);
      }
      _deliverVerifiedEvent(event, {
        ...Map<String, dynamic>.from(record['payload'] as Map),
        'serverSequence': record['sequence'],
      });
    } catch (_) {
      _safeStatus(
        'Evento in attesa di riconnessione: salvataggio locale conservato.',
      );
    }
  }

  Future<void> _replayEvents(
    SupabaseClient client,
    RealtimeChannel? channel,
  ) async {
    final generation = _generation;
    final records = await client
        .from('oculum_room_events')
        .select('id,event,payload,sequence')
        .eq('room_id', _secureRoomId!)
        .neq('session_id', _presenceKey)
        .gt('sequence', _replaySequence)
        .gte('created_at', _replaySince)
        .order('sequence')
        .limit(200)
        .timeout(const Duration(seconds: 10));
    for (final record in records) {
      if (_disposed || _generation != generation || _channel != channel) return;
      final id = '${record['id']}';
      if (_deliveredEvents.add(id)) {
        if (_deliveredEvents.length > 4000) {
          _deliveredEvents.remove(_deliveredEvents.first);
        }
        final event = '${record['event']}';
        final payload = Map<String, dynamic>.from(record['payload'] as Map);
        payload['serverSequence'] = record['sequence'];
        if (event == 'initiative_shared') {
          payload['restoredSnapshot'] = true;
        }
        _deliverVerifiedEvent(event, payload);
      }
      if (_disposed || _generation != generation || _channel != channel) return;
      _replaySequence = (record['sequence'] as num).toInt();
    }
  }

  /// Event replay is intentionally short-lived so reconnecting clients do not
  /// replay old attacks, rolls, or chat. The current fight is different: it is
  /// durable shared state and must survive an app restart. Restore only the
  /// newest database-verified Master snapshot, never a client broadcast body.
  Future<bool> _restoreLatestInitiativeSnapshot(
    SupabaseClient client,
    RealtimeChannel? channel,
  ) async {
    final generation = _generation;
    try {
      final record = await client
          .from('oculum_room_events')
          .select('id,event,payload,sequence')
          .eq('room_id', _secureRoomId!)
          .eq('event', 'initiative_shared')
          .order('sequence', ascending: false)
          .limit(1)
          .maybeSingle()
          .timeout(const Duration(seconds: 10));
      if (_disposed || _generation != generation || _channel != channel) {
        return false;
      }
      if (record == null ||
          record['event'] != 'initiative_shared' ||
          record['payload'] is! Map) {
        return true;
      }
      final id = '${record['id']}';
      if (!_deliveredEvents.add(id)) return true;
      if (_deliveredEvents.length > 4000) {
        _deliveredEvents.remove(_deliveredEvents.first);
      }
      final payload = Map<String, dynamic>.from(record['payload'] as Map)
        ..['serverSequence'] = record['sequence']
        ..['restoredSnapshot'] = true;
      _deliverVerifiedEvent('initiative_shared', payload);
      return true;
    } catch (_) {
      // The realtime transport stays connected even if historical state cannot
      // be restored; the next heartbeat retries without discarding local data.
      if (_generation == generation) {
        _safeStatus('Turnistica condivisa in attesa di sincronizzazione.');
      }
      return false;
    }
  }

  void _deliverVerifiedEvent(String event, Map<String, dynamic> payload) {
    if (_disposed) return;

    // The database already supplied the verified body. Unwrapping a user
    // supplied nested `payload` here would discard authenticated sender fields.
    final normalized = oculumVerifiedPacketIdentity(payload);
    if (event == 'initiative_control' &&
        normalized['roomIdleClose'] == true &&
        normalized['senderRole'] == 'master') {
      final activity = DateTime.tryParse(
        '${normalized['lastActivityAt'] ?? ''}',
      );
      if (activity != null && !_localUserActivity.isAfter(activity)) {
        onIdleClosed?.call();
        unawaited(disconnect(notify: false));
      }
      return;
    }

    if (event == 'room_member_removed' &&
        normalized['targetUserId'] ==
            (_client ?? Supabase.instance.client).auth.currentUser?.id) {
      _safeStatus(
        normalized['action'] == 'ban'
            ? 'Sei stato bannato da questa stanza.'
            : 'Sei stato espulso da questa stanza.',
      );
      unawaited(disconnect(notify: false));
    }

    if (event == 'session_note_chunk') {
      final assembled = _sessionNoteTransfers.accept(
        normalized,
        DateTime.now(),
      );
      if (assembled != null &&
          const {
            'session_note',
            'session_notes_snapshot',
          }.contains(assembled['event']) &&
          assembled['sheet'] is Map) {
        onEvent(
          '${assembled['event']}',
          Map<String, dynamic>.from(assembled['sheet']),
        );
      }
      return;
    }
    if (event == 'sheet_shared_chunk') {
      final assembled = _sheetTransfers.accept(normalized, DateTime.now());
      if (assembled != null &&
          oculumSameSheetIdentity(
            assembled['sheetId'],
            normalized['authenticatedSheetId'],
          )) {
        onEvent('sheet_shared', {
          ...assembled,
          if (normalized['authenticatedRole'] == 'player') 'fromMaster': false,
          if (normalized['authenticatedRole'] == 'player') 'masterParty': false,
          for (final key in [
            'senderRole',
            'senderTag',
            'sessionId',
            'authenticatedUserId',
            'authenticatedRole',
            'serverSequence',
          ])
            key: normalized[key],
        });
      }
      return;
    }
    onEvent(event, normalized);
  }

  Future<void> _emitPresence() {
    final generation = _generation;
    return _presenceRead ??= _readPresence().whenComplete(() {
      if (_generation == generation) _presenceRead = null;
    });
  }

  Future<void> _readPresence() async {
    if (_disposed) return;

    final channel = _channel;
    final generation = _generation;
    if (channel == null && !_pollingFallback) {
      onPresenceChanged(const <Map<String, dynamic>>[]);
      return;
    }

    try {
      final data = await (_client ?? Supabase.instance.client)
          .rpc('oculum_room_presence', params: {'p_room': _secureRoomId})
          .timeout(const Duration(seconds: 10));
      if (_disposed || _generation != generation || _channel != channel) return;
      final users = (data as List)
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
      final own = users
          .where((row) => row['sessionId'] == _presenceKey)
          .firstOrNull;
      if (own != null) {
        authenticatedRole = '${own['role']}';
        final requested = _normalizedTag(
          presenceDataProvider?.call()['activeSheetTag'],
        );
        final accepted = (own['localSheetTags'] as List? ?? const [])
            .map(_normalizedTag)
            .toSet();
        final unavailable =
            _registeredIdentitySignature == _currentIdentitySignature &&
                authenticatedRole == 'player' &&
                requested.isNotEmpty &&
                !accepted.contains(requested)
            ? requested
            : null;
        if (unavailable != unavailableActiveSheetTag && unavailable != null) {
          _safeStatus(
            'La scheda selezionata non è associata a questo account nella stanza. Usa l’account originale oppure una copia con un nuovo tag.',
          );
        }
        unavailableActiveSheetTag = unavailable;
        if (unavailable != null && _reportedSheetConflicts.add(unavailable)) {
          unawaited(
            _sendConfirmed('permission_request', {
              'id': 'sheet_identity:${own['userId']}:$unavailable',
              'action': 'sheet_identity_conflict',
              'requestedSheetTag': unavailable,
              'requesterName': _displayName,
              'senderTag': '',
              'createdAt': _nowIso(),
            }).then((sent) {
              if (!sent) _reportedSheetConflicts.remove(unavailable);
            }),
          );
        }
      }
      onPresenceChanged(users);
      final hadWarning = _activity.warningAt != null;
      final now = DateTime.now();
      _activity.observe(users, now);
      if (hadWarning && _activity.warningAt == null) onIdleWarning?.call(false);
      if (authenticatedRole == 'master' && !_idleClosing) {
        if (_activity.shouldWarn(now)) {
          _activity.warn(now);
          onIdleWarning?.call(true);
        } else if (_activity.shouldClose(now)) {
          _idleClosing = true;
          unawaited(_closeIdleRoom(generation, channel));
        }
      }
    } catch (_) {
      // A failed poll must not replace known peers with an empty snapshot.
    }
  }

  void _safeStatus(String status) {
    if (_disposed) return;
    onStatusChanged(status);
  }

  bool staleActivityClose(int generation, RealtimeChannel? channel) =>
      _disposed ||
      _generation != generation ||
      _channel != channel ||
      _activity.warningAt == null;

  Future<void> _closeIdleRoom(int generation, RealtimeChannel? channel) async {
    // Finish the presence read before sending; sending may itself reconcile presence.
    await Future<void>.delayed(Duration.zero);
    if (staleActivityClose(generation, channel)) {
      _idleClosing = false;
      return;
    }
    final sent = await sendCombatEvent('initiative_control', {
      'roomIdleClose': true,
      'id': 'room-idle:${DateTime.now().microsecondsSinceEpoch}',
      'lastActivityAt': _activity.latestActivity.toUtc().toIso8601String(),
    });
    if (sent && !staleActivityClose(generation, channel)) {
      onIdleClosed?.call();
      await disconnect(notify: false);
    } else {
      _idleClosing = false;
    }
  }

  String get _displayName {
    final clean = playerName.trim();
    return clean.isEmpty ? 'Oculum Player' : clean;
  }

  static String _nowIso() => DateTime.now().toIso8601String();
}
