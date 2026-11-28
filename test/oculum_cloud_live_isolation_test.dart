import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/services/oculum_cloud_save_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _runLive = bool.fromEnvironment('OculumLiveRealtimeTest');

void main() {
  test(
    'two protected guests cannot read or mutate each other cloud snapshots',
    () async {
      final first = SupabaseClient(
        oculumConfiguredSupabaseUrl,
        oculumConfiguredSupabasePublishableKey,
      );
      final second = SupabaseClient(
        oculumConfiguredSupabaseUrl,
        oculumConfiguredSupabasePublishableKey,
      );
      String? id;
      final folderIds = <String>[];
      addTearDown(() async {
        try {
          if (folderIds.isNotEmpty) {
            await first
                .from('oculum_cloud_saves')
                .delete()
                .inFilter('id', folderIds);
          }
          if (id != null) {
            await first.from('oculum_cloud_saves').delete().eq('id', id);
          }
          await first.auth.signOut(scope: SignOutScope.local);
          await second.auth.signOut(scope: SignOutScope.local);
        } finally {
          await first.dispose();
          await second.dispose();
        }
      });
      await first.auth.signInAnonymously();
      await second.auth.signInAnonymously();
      final owner = first.auth.currentUser!.id;
      expect(first.auth.currentUser!.isAnonymous, isTrue);
      expect(owner, isNot(second.auth.currentUser!.id));
      id = 'verification_${DateTime.now().microsecondsSinceEpoch}';
      await first.from('oculum_cloud_saves').insert({
        'id': id,
        'user_id': owner,
        'revision': 1,
        'content_signature': 'disposable-verification',
        'payload': {'name': 'Disposable security verification'},
      });
      expect(
        await first.from('oculum_cloud_saves').select('id').eq('id', id),
        hasLength(1),
      );
      expect(
        await second.from('oculum_cloud_saves').select('id').eq('id', id),
        isEmpty,
      );
      await expectLater(
        second.from('oculum_cloud_saves').insert({
          'id': '${id}_forged',
          'user_id': owner,
          'content_signature': 'forged',
          'payload': {'name': 'forged'},
        }),
        throwsA(isA<PostgrestException>()),
      );
      final updated = await second
          .from('oculum_cloud_saves')
          .update({
            'payload': {'name': 'forged'},
          })
          .eq('id', id)
          .select('id');
      expect(updated, isEmpty);
      final deleted = await second
          .from('oculum_cloud_saves')
          .delete()
          .eq('id', id)
          .select('id');
      expect(deleted, isEmpty);
      final original = await first
          .from('oculum_cloud_saves')
          .select('payload')
          .eq('id', id)
          .single();
      expect(original['payload'], {'name': 'Disposable security verification'});

      final cloud = OculumCloudSaveService.forTesting(first);
      addTearDown(cloud.dispose);
      for (final origin in ['windows', 'android']) {
        final snapshot = OculumCloudSaveService.buildSnapshotRecord(
          userId: owner,
          payload: {
            'schede': [
              {'name': 'Disposable $origin'},
            ],
          },
          deviceOrigin: origin,
        );
        folderIds.add(snapshot.id);
        await first.from('oculum_cloud_saves').insert(snapshot.toJson());
      }
      final desktop = await cloud.listFolder(
        owner,
        OculumCloudSaveFolder.desktop,
      );
      final phone = await cloud.listFolder(owner, OculumCloudSaveFolder.phone);
      final legacy = await cloud.listFolder(owner, OculumCloudSaveFolder.older);
      expect(desktop.single.id, folderIds[0]);
      expect(phone.single.id, folderIds[1]);
      expect(legacy.single.id, id);
      expect(await cloud.fetchSnapshotForRestore(owner, phone.single.id), {
        'schede': [
          {'name': 'Disposable android'},
        ],
      });
      expect(await cloud.fetchSnapshotForRestore(owner, desktop.single.id), {
        'schede': [
          {'name': 'Disposable windows'},
        ],
      });
    },
    skip: !_runLive,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
