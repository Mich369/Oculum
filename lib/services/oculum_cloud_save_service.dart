import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String _pendingCloudPayloadKey = 'oculum.cloud_save.pending_payload';
const String _pendingCloudUserKey = 'oculum.cloud_save.pending_user';
const String _pendingCloudDeviceKey = 'oculum.cloud_save.pending_device';

class OculumCloudSaveService extends ChangeNotifier {
  OculumCloudSaveService._();

  static final OculumCloudSaveService instance = OculumCloudSaveService._();

  static const _cloudSavePrefsKey = 'oculum.cloud_save.last_status';
  static const _cloudSaveTable = 'oculum_cloud_saves';

  final ValueNotifier<String> statusNotifier = ValueNotifier('Offline');

  String get status => statusNotifier.value;

  Future<void> initialize() async {
    statusNotifier.value = 'Ready';
  }

  Future<Map<String, dynamic>?> fetchLatestSnapshot(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from(_cloudSaveTable)
          .select()
          .eq('user_id', userId)
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return response == null ? null : Map<String, dynamic>.from(response);
    } catch (_) {
      debugPrint('Cloud save fetch failed.');
      return null;
    }
  }

  Future<bool> queueLocalSaveForSync(
    String userId, {
    required Map<String, dynamic> payload,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pendingCloudUserKey, userId);
      await prefs.setString(_pendingCloudDeviceKey, 'flutter');
      await prefs.setString(_pendingCloudPayloadKey, jsonEncode(payload));
      statusNotifier.value = 'Saved on device';
      return true;
    } catch (_) {
      debugPrint('Cloud sync queue failed.');
      return false;
    }
  }

  Future<Map<String, dynamic>?> exportPendingSnapshotForUser(
    String userId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingPayload = prefs.getString(_pendingCloudPayloadKey);
      if (pendingPayload == null ||
          prefs.getString(_pendingCloudUserKey) != userId) {
        return null;
      }
      final payload = jsonDecode(pendingPayload);
      return buildSnapshotRecord(
        userId: userId,
        payload: Map<String, dynamic>.from(payload as Map),
        deviceOrigin: prefs.getString(_pendingCloudDeviceKey) ?? 'flutter',
      ).toJson();
    } catch (_) {
      debugPrint('Pending snapshot export failed.');
      return null;
    }
  }

  Future<bool> uploadSnapshot(
    String userId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final snapshot = buildSnapshotRecord(
        userId: userId,
        payload: payload,
        deviceOrigin: 'flutter',
      );
      await Supabase.instance.client.from(_cloudSaveTable).upsert(snapshot);
      statusNotifier.value = 'Saved to cloud';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cloudSavePrefsKey, statusNotifier.value);
      return true;
    } catch (_) {
      debugPrint('Cloud save upload failed.');
      statusNotifier.value = 'Sync failed';
      return false;
    }
  }

  Future<bool> downloadSnapshot(
    String userId,
    Map<String, dynamic> payload,
  ) async {
    final remote = await fetchLatestSnapshot(userId);
    if (remote == null) return false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'oculum.cloud_save.remote_snapshot',
      jsonEncode(remote),
    );
    statusNotifier.value = 'Downloaded from cloud';
    return true;
  }

  Future<void> clearCloudData(String userId) async {
    try {
      await Supabase.instance.client
          .from(_cloudSaveTable)
          .delete()
          .eq('user_id', userId);
      statusNotifier.value = 'Cloud data cleared';
    } catch (_) {
      debugPrint('Cloud data delete failed.');
    }
  }

  static CloudMigrationAction chooseMigrationAction({
    required bool hasLocalSave,
    required bool hasCloudSave,
  }) {
    if (!hasLocalSave) return CloudMigrationAction.none;
    if (!hasCloudSave) return CloudMigrationAction.uploadLocal;
    return CloudMigrationAction.askUser;
  }

  static CloudConflictResolution resolveConflict({
    required int localRevision,
    required int remoteRevision,
    required String localSignature,
    required String remoteSignature,
  }) {
    final sameContent = localSignature == remoteSignature;
    if (sameContent) {
      return CloudConflictResolution(
        action: CloudConflictAction.keepBoth,
        newId: 'copy-${DateTime.now().millisecondsSinceEpoch}',
        message: 'The two versions are identical; both are preserved.',
      );
    }
    return CloudConflictResolution(
      action: CloudConflictAction.keepBoth,
      newId: 'copy-${DateTime.now().millisecondsSinceEpoch}',
      message: 'both versions are kept because the conflict requires review.',
    );
  }

  static CloudSaveRecord buildSnapshotRecord({
    required String userId,
    required Map<String, dynamic> payload,
    required String deviceOrigin,
  }) {
    final revision = 1 + Random().nextInt(1000000);
    final timestamp = DateTime.now().toUtc().toIso8601String();
    final comparable = Map<String, dynamic>.from(payload)
      ..remove('savedAt')
      ..remove('saveRevision');
    final signature = '${jsonEncode(comparable).hashCode}:${comparable.length}';
    return CloudSaveRecord(
      id: '${userId}_$revision',
      userId: userId,
      revision: revision,
      contentSignature: signature,
      payload: payload,
      createdAt: timestamp,
      updatedAt: timestamp,
      deviceOrigin: deviceOrigin,
    );
  }
}

class CloudSaveRecord {
  const CloudSaveRecord({
    required this.id,
    required this.userId,
    required this.revision,
    required this.contentSignature,
    required this.payload,
    required this.createdAt,
    required this.updatedAt,
    required this.deviceOrigin,
  });

  final String id;
  final String userId;
  final int revision;
  final String contentSignature;
  final Map<String, dynamic> payload;
  final String createdAt;
  final String updatedAt;
  final String deviceOrigin;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'revision': revision,
      'content_signature': contentSignature,
      'payload': payload,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'device_origin': deviceOrigin,
    };
  }
}

enum CloudMigrationAction { none, uploadLocal, askUser }

enum CloudConflictAction { useLocal, useRemote, keepBoth }

class CloudConflictResolution {
  const CloudConflictResolution({
    required this.action,
    required this.newId,
    required this.message,
  });

  final CloudConflictAction action;
  final String? newId;
  final String message;
}
