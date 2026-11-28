import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:oculum/services/oculum_save_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OculumOwnCampaignLabel {
  const OculumOwnCampaignLabel({
    required this.ownerId,
    required this.campaignId,
    required this.campaignName,
  });

  final String ownerId;
  final String campaignId;
  final String campaignName;
}

class OculumOtherDeviceCampaign {
  const OculumOtherDeviceCampaign({
    required this.deviceId,
    required this.campaignId,
    required this.campaignName,
    required this.platform,
  });

  final String deviceId;
  final String campaignId;
  final String campaignName;
  final String platform;
}

class OculumSharedCampaign {
  const OculumSharedCampaign({
    required this.roomId,
    required this.roomCode,
    required this.ownerId,
    required this.ownerName,
    required this.campaignId,
    required this.campaignName,
  });

  final String roomId;
  final String roomCode;
  final String ownerId;
  final String ownerName;
  final String campaignId;
  final String campaignName;
}

class OculumOwnedCampaignShare {
  const OculumOwnedCampaignShare({
    required this.roomId,
    required this.campaignId,
  });

  final String roomId;
  final String campaignId;
}

class OculumCampaignDirectory {
  const OculumCampaignDirectory({
    this.otherDevices = const [],
    this.shared = const [],
    this.ownedShares = const [],
  });

  factory OculumCampaignDirectory.fromJson(Map<String, dynamic> json) {
    return OculumCampaignDirectory(
      otherDevices: List.unmodifiable([
        for (final row in _directoryRows(json, 'otherDevices'))
          OculumOtherDeviceCampaign(
            deviceId: _directoryField(row, 'deviceId'),
            campaignId: _directoryField(row, 'campaignId'),
            campaignName: _directoryField(row, 'campaignName'),
            platform: _directoryField(row, 'platform'),
          ),
      ]),
      shared: List.unmodifiable([
        for (final row in _directoryRows(json, 'shared'))
          OculumSharedCampaign(
            roomId: _directoryField(row, 'roomId'),
            roomCode: _directoryField(row, 'roomCode'),
            ownerId: _directoryField(row, 'ownerId'),
            ownerName: _directoryField(row, 'ownerName'),
            campaignId: _directoryField(row, 'campaignId'),
            campaignName: _directoryField(row, 'campaignName'),
          ),
      ]),
      ownedShares: List.unmodifiable([
        for (final row in _directoryRows(json, 'ownedShares'))
          OculumOwnedCampaignShare(
            roomId: _directoryField(row, 'roomId'),
            campaignId: _directoryField(row, 'campaignId'),
          ),
      ]),
    );
  }

  final List<OculumOtherDeviceCampaign> otherDevices;
  final List<OculumSharedCampaign> shared;
  final List<OculumOwnedCampaignShare> ownedShares;
}

List<Map<String, dynamic>> _directoryRows(
  Map<String, dynamic> json,
  String key,
) {
  final rows = json[key];
  if (rows is! List || rows.any((row) => row is! Map<String, dynamic>)) {
    throw FormatException('Invalid campaign directory $key');
  }
  return rows.cast<Map<String, dynamic>>();
}

String _directoryField(Map<String, dynamic> row, String name) {
  final value = row[name];
  if (value is! String || value.isEmpty) {
    throw FormatException('Invalid campaign directory $name');
  }
  return value;
}

class OculumCampaignDirectoryAccountChanged implements Exception {
  const OculumCampaignDirectoryAccountChanged();
}

abstract interface class OculumCampaignDirectoryBackend {
  String? get verifiedAccountId;
  Stream<String?> get accountChanges;
  Future<Object?> call(String function, Map<String, dynamic> params);
}

class _SupabaseCampaignDirectoryBackend
    implements OculumCampaignDirectoryBackend {
  const _SupabaseCampaignDirectoryBackend(this._client);

  final SupabaseClient _client;

  String? _verifiedId(User? user) {
    if (user == null ||
        user.isAnonymous ||
        user.emailConfirmedAt == null ||
        (user.email ?? '').trim().isEmpty) {
      return null;
    }
    return user.id;
  }

  @override
  String? get verifiedAccountId =>
      _verifiedId(_client.auth.currentSession?.user);

  @override
  Stream<String?> get accountChanges => _client.auth.onAuthStateChange.map(
    (event) => _verifiedId(event.session?.user),
  );

  @override
  Future<Object?> call(String function, Map<String, dynamic> params) async =>
      await _client.rpc(function, params: params);
}

String _createInstallationId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

final _installationIdPattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);
Future<String>? _cachedInstallationId;

Future<String> _persistentInstallationId() =>
    _cachedInstallationId ??= () async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final key = oculumProfiledStorageKey(
          'oculum.campaign_directory.installation_id.v1',
        );
        final saved = prefs.getString(key);
        if (saved != null && _installationIdPattern.hasMatch(saved)) {
          return saved;
        }
        final newId = _createInstallationId();
        if (!await prefs.setString(key, newId)) {
          throw StateError(
            'Campaign directory installation ID could not be saved',
          );
        }
        return newId;
      } catch (_) {
        _cachedInstallationId = null;
        rethrow;
      }
    }();

class OculumCampaignDirectoryService {
  OculumCampaignDirectoryService(SupabaseClient client)
    : this.withBackend(_SupabaseCampaignDirectoryBackend(client));

  OculumCampaignDirectoryService.withBackend(
    this._backend, {
    Future<String> Function()? installationId,
    Duration publishDelay = const Duration(milliseconds: 450),
  }) : _installationId = installationId ?? _persistentInstallationId,
       _publishDelay = publishDelay,
       _account = _backend.verifiedAccountId {
    _accountChanges = _backend.accountChanges.listen(
      _observeAccount,
      onError: (Object _, StackTrace _) => _observeAccount(null),
    );
  }

  final OculumCampaignDirectoryBackend _backend;
  final Future<String> Function() _installationId;
  final Duration _publishDelay;
  late final StreamSubscription<String?> _accountChanges;
  String? _account;
  int _accountGeneration = 0;
  bool _disposed = false;
  Timer? _publicationTimer;
  _DeviceCampaignPublication? _pending;
  String? _lastPublished;
  Future<void> _writes = Future.value();

  void _observeAccount(String? account) {
    if (_account == account) return;
    _account = account;
    _accountGeneration++;
    _lastPublished = null;
    _cancelPending();
  }

  void _cancelPending() {
    _publicationTimer?.cancel();
    _publicationTimer = null;
    final pending = _pending;
    _pending = null;
    pending?.result.completeError(
      const OculumCampaignDirectoryAccountChanged(),
    );
  }

  int _accountStamp(String accountId) {
    _observeAccount(_backend.verifiedAccountId);
    if (_disposed || _account == null || _account != accountId) {
      throw const OculumCampaignDirectoryAccountChanged();
    }
    return _accountGeneration;
  }

  void _requireAccount(String accountId, int generation) {
    if (_accountStamp(accountId) != generation) {
      throw const OculumCampaignDirectoryAccountChanged();
    }
  }

  Future<Object?> _rpc(
    String accountId,
    int generation,
    String name,
    Map<String, dynamic> parameters,
  ) async {
    _requireAccount(accountId, generation);
    final result = await _backend.call(name, {
      'p_expected_user_id': accountId,
      ...parameters,
    });
    _requireAccount(accountId, generation);
    return result;
  }

  Future<OculumCampaignDirectory> list({required String accountId}) async {
    final generation = _accountStamp(accountId);
    final deviceId = await _installationId();
    final result = await _rpc(
      accountId,
      generation,
      'oculum_list_campaign_directory',
      {'p_device_id': deviceId},
    );
    if (result is! Map<String, dynamic>) {
      throw const FormatException('Invalid campaign directory response');
    }
    return OculumCampaignDirectory.fromJson(result);
  }

  Future<void> replaceDeviceCampaigns({
    required String accountId,
    required String platform,
    required Iterable<OculumOwnCampaignLabel> campaigns,
    bool allowEmpty = false,
  }) async {
    final generation = _accountStamp(accountId);
    final labels = {
      for (final campaign in campaigns)
        if (campaign.ownerId == accountId)
          campaign.campaignId: campaign.campaignName,
    };
    if (labels.isEmpty && !allowEmpty) return;
    final keys = labels.keys.toList()..sort();
    final entries = [
      for (final id in keys) {'campaignId': id, 'campaignName': labels[id]!},
    ];
    final signature = jsonEncode([accountId, platform, entries]);
    final pending = _pending;
    if (pending != null && pending.signature == signature) {
      return pending.result.future;
    }
    // Keep the same completion while saves are coalesced. All waiting callers
    // observe the outcome of the latest snapshot published for this account.
    final next = _DeviceCampaignPublication(
      accountId,
      generation,
      platform,
      entries,
      signature,
      pending?.result ?? Completer<void>(),
    );
    _pending = next;
    _publicationTimer?.cancel();
    _publicationTimer = Timer(_publishDelay, _scheduleWrite);
    return next.result.future;
  }

  void _scheduleWrite() {
    final job = _pending!;
    _pending = null;
    _publicationTimer = null;
    _writes = _writes.then((_) async {
      try {
        _requireAccount(job.accountId, job.generation);
        if (_lastPublished != job.signature) {
          final device = await _installationId();
          await _rpc(
            job.accountId,
            job.generation,
            'oculum_replace_campaign_device_catalog',
            {
              'p_device_id': device,
              'p_platform': job.platform,
              'p_entries': job.entries,
            },
          );
          _lastPublished = job.signature;
        }
        job.result.complete();
      } catch (error, stackTrace) {
        job.result.completeError(error, stackTrace);
      }
    });
  }

  Future<void> setMasterDisplayName({
    required String accountId,
    required String displayName,
  }) async {
    await _rpc(
      accountId,
      _accountStamp(accountId),
      'oculum_set_campaign_master_label',
      {'p_display_name': displayName.trim()},
    );
  }

  Future<void> shareCampaign({
    required String accountId,
    required String roomId,
    required String campaignId,
    required String campaignName,
    required bool shared,
  }) async {
    await _rpc(
      accountId,
      _accountStamp(accountId),
      'oculum_set_campaign_sharing',
      {
        'p_room_id': roomId,
        'p_campaign_id': campaignId,
        'p_campaign_name': campaignName.trim(),
        'p_shared': shared,
      },
    );
  }

  Future<void> renameOwnedCampaignShare({
    required String accountId,
    required String campaignId,
    required String campaignName,
  }) async {
    await _rpc(
      accountId,
      _accountStamp(accountId),
      'oculum_rename_owned_campaign_shares',
      {'p_campaign_id': campaignId, 'p_campaign_name': campaignName.trim()},
    );
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _cancelPending();
    unawaited(_accountChanges.cancel());
  }
}

class _DeviceCampaignPublication {
  const _DeviceCampaignPublication(
    this.accountId,
    this.generation,
    this.platform,
    this.entries,
    this.signature,
    this.result,
  );

  final String accountId;
  final int generation;
  final String platform;
  final List<Map<String, String>> entries;
  final String signature;
  final Completer<void> result;
}
