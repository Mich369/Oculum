import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
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
      addTearDown(() async {
        try {
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
    },
    skip: !_runLive,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
