import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oculum/services/oculum_auth_service.dart';
import 'package:oculum/services/oculum_cloud_save_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPreferences.getInstance();
  });

  test('guest mode stays local and does not require cloud account', () async {
    final auth = OculumAuthService.instance;
    await auth.continueAsGuest();

    expect(auth.state.isGuest, isTrue);
    expect(auth.state.isAuthenticated, isFalse);
  });

  test(
    'cloud migration chooses upload when local save exists without cloud',
    () {
      expect(
        OculumCloudSaveService.chooseMigrationAction(
          hasLocalSave: true,
          hasCloudSave: false,
        ),
        CloudMigrationAction.uploadLocal,
      );
    },
  );

  test('conflicts are preserved as copies when devices differ', () {
    final result = OculumCloudSaveService.resolveConflict(
      localRevision: 1,
      remoteRevision: 2,
      localSignature: 'local',
      remoteSignature: 'remote',
    );

    expect(result.action, CloudConflictAction.keepBoth);
    expect(result.newId, isNotNull);
  });

  test('snapshot records include stable metadata', () {
    final record = OculumCloudSaveService.buildSnapshotRecord(
      userId: 'user-1',
      payload: {'name': 'A'},
      deviceOrigin: 'test',
    );

    expect(record.userId, 'user-1');
    expect(record.revision, greaterThan(0));
    expect(record.contentSignature, isNotEmpty);
    expect(record.payload['name'], 'A');
  });

  test('local save can be queued for later cloud sync', () async {
    final service = OculumCloudSaveService.instance;

    final queued = await service.queueLocalSaveForSync(
      'user-1',
      payload: {'name': 'A'},
    );

    expect(queued, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('oculum.cloud_save.pending_payload'), isNotNull);
  });

  test(
    'cloud queue riusa la codifica locale senza serializzare di nuovo',
    () async {
      final service = OculumCloudSaveService.instance;
      const encoded = '{ "name" : "A", "revision" : 7 }';

      final queued = await service.queueLocalSaveForSync(
        'user-encoded',
        payload: {'name': 'A', 'revision': 7},
        encodedPayload: encoded,
      );

      expect(queued, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('oculum.cloud_save.pending_payload'), encoded);
    },
  );

  test('pending snapshot export preserves the user id', () async {
    final service = OculumCloudSaveService.instance;
    await service.queueLocalSaveForSync('user-2', payload: {'name': 'B'});

    final exported = await service.exportPendingSnapshotForUser('user-2');

    expect(exported, isNotNull);
    expect(exported!['user_id'], 'user-2');
  });

  test('switching accounts preserves both pending saves', () async {
    final service = OculumCloudSaveService.instance;
    await service.queueLocalSaveForSync('first', payload: {'name': 'A'});
    await service.queueLocalSaveForSync('second', payload: {'name': 'B'});
    expect((await service.exportPendingSnapshotForUser('first'))!['payload'], {
      'name': 'A',
    });
    expect((await service.exportPendingSnapshotForUser('second'))!['payload'], {
      'name': 'B',
    });
    expect(await service.exportPendingSnapshotForUser('third'), isNull);
  });

  test('invalid payload cannot replace a pending save', () async {
    final service = OculumCloudSaveService.instance;
    await service.queueLocalSaveForSync('first', payload: {'name': 'A'});
    expect(await service.queueLocalSaveForSync('first', payload: {}), isFalse);
    expect(
      await service.queueLocalSaveForSync(
        'first',
        payload: {'name': 'A'},
        encodedPayload: '{"name":"B"}',
      ),
      isFalse,
    );
    expect((await service.exportPendingSnapshotForUser('first'))!['payload'], {
      'name': 'A',
    });
  });

  test('snapshot uses canonical SHA256 and freezes nested content', () {
    final payload = <String, dynamic>{
      'nested': {'b': 2, 'a': 1},
      'savedAt': 'old',
    };
    final first = OculumCloudSaveService.buildSnapshotRecord(
      userId: 'first',
      payload: payload,
      deviceOrigin: 'test',
    );
    final second = OculumCloudSaveService.buildSnapshotRecord(
      userId: 'first',
      payload: {
        'savedAt': 'new',
        'nested': {'a': 1, 'b': 2},
      },
      deviceOrigin: 'test',
    );
    expect(first.contentSignature, second.contentSignature);
    expect(first.contentSignature, matches(RegExp(r'^[a-f0-9]{64}$')));
    expect(first.id, isNot(second.id));
    (payload['nested'] as Map)['a'] = 99;
    expect((first.payload['nested'] as Map)['a'], 1);
  });
}
