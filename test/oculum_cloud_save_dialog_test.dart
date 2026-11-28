import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:oculum/main.dart' show oculumCloudSaveForAccount;
import 'package:oculum/services/oculum_auth_service.dart';
import 'package:oculum/services/oculum_cloud_save_service.dart';
import 'package:oculum/services/oculum_cloud_save_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _account = 'account-owner';

class _AccountBackend implements OculumAuthBackend {
  final _events = StreamController<OculumBackendAuthEvent>.broadcast();
  OculumBackendUser? _user = const OculumBackendUser(
    id: _account,
    provider: 'google',
  );

  @override
  OculumBackendUser? get currentUser => _user;

  @override
  Stream<OculumBackendAuthEvent> get events => _events.stream;

  @override
  Future<void> signOut() async {
    _user = null;
    _events.add(
      const OculumBackendAuthEvent(OculumBackendAuthEventType.signedOut),
    );
  }

  @override
  Future<bool> startOAuth(
    OculumAuthProvider provider, {
    required String? redirectTo,
  }) async => false;
}

Future<void> _session(SupabaseClient client, String userId) =>
    client.auth.setInitialSession(
      jsonEncode({
        'access_token': 'test-session',
        'refresh_token': 'test-refresh',
        'token_type': 'bearer',
        'expires_in': 3600,
        'user': {
          'id': userId,
          'aud': 'authenticated',
          'created_at': '2026-10-19T00:00:00Z',
          'is_anonymous': false,
        },
      }),
    );

class _CloudFixture {
  _CloudFixture() {
    client = SupabaseClient(
      'https://isolated-test.supabase.co',
      'public-test-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        requests.add(request);
        final filters = request.url.queryParameters;
        final matchOwner = filters['user_id']?.substring(3);
        Object? response;
        if (request.method == 'POST') {
          final row = jsonDecode(request.body) as Map<String, dynamic>;
          rows.add(row);
        } else if (filters['id'] != null) {
          final matchId = filters['id']!.substring(3);
          selected?.complete();
          await finishSelection?.future;
          response = rows
              .where((r) => r['id'] == matchId && r['user_id'] == matchOwner)
              .firstOrNull;
        } else {
          final filter = filters['device_origin']!;
          final names = filter
              .substring(filter.indexOf('(') + 1, filter.length - 1)
              .split(',')
              .map((name) => name.replaceAll('"', ''))
              .toSet();
          response = [
            for (final row in rows)
              if (row['user_id'] == matchOwner &&
                  names.contains(row['device_origin']) !=
                      filter.startsWith('not.'))
                {
                  'id': row['id'],
                  'updated_at': row['updated_at'],
                  'device_origin': row['device_origin'],
                },
          ];
        }
        return http.Response(
          jsonEncode(response),
          request.method == 'POST' ? 201 : 200,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    cloud = OculumCloudSaveService.forTesting(client);
  }

  late final SupabaseClient client;
  late final OculumCloudSaveService cloud;
  final requests = <http.Request>[];
  Completer<void>? selected;
  Completer<void>? finishSelection;
  final rows = [
    for (final (id, origin) in [
      ('old-pc', 'windows'),
      ('old-phone', 'android'),
      ('old-legacy', 'flutter'),
    ])
      <String, dynamic>{
        'id': id,
        'device_origin': origin,
        'updated_at': '2026-11-01T19:00:00Z',
        'user_id': _account,
        'payload': {'name': id},
      },
  ];

  Future<void> prepare() async {
    await _session(client, _account);
    addTearDown(client.dispose);
    addTearDown(cloud.dispose);
  }
}

Future<OculumAuthService> _initializeAuth(_AccountBackend backend) async {
  final auth = OculumAuthService.forTesting(
    backend: backend,
    connectivityCheck: () async => true,
  );
  await auth.initialize();
  addTearDown(backend._events.close);
  addTearDown(auth.dispose);
  return auth;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'known native origins are distinguished and flutter stays unknown',
    () async {
      final fixture = _CloudFixture();
      await fixture.prepare();
      for (final (folder, id) in [
        (OculumCloudSaveFolder.desktop, 'old-pc'),
        (OculumCloudSaveFolder.phone, 'old-phone'),
        (OculumCloudSaveFolder.older, 'old-legacy'),
      ]) {
        final copies = await fixture.cloud.listFolder(_account, folder);
        expect(copies.map((copy) => copy.id), [id]);
        final query = fixture.requests.last.url.queryParameters;
        expect(query['select'], 'id,updated_at,device_origin');
        expect(query['user_id'], 'eq.$_account');
      }
      expect(
        OculumCloudSaveFolder.forOrigin('ios'),
        OculumCloudSaveFolder.phone,
      );
      expect(OculumCloudSaveFolder.forOrigin('web'), OculumCloudSaveFolder.web);
      final seenRequests = fixture.requests.length;
      await expectLater(
        fixture.cloud.listFolder('other', OculumCloudSaveFolder.phone),
        throwsStateError,
      );
      expect(fixture.requests.length, seenRequests);
    },
  );

  test('an account switch invalidates a delayed payload response', () async {
    final fixture = _CloudFixture();
    await fixture.prepare();
    fixture.selected = Completer<void>();
    fixture.finishSelection = Completer<void>();
    final restoring = fixture.cloud.fetchSnapshotForRestore(
      _account,
      'old-phone',
    );
    final rejected = expectLater(restoring, throwsStateError);
    await fixture.selected!.future;
    await _session(fixture.client, 'other-account');
    fixture.finishSelection!.complete();
    await rejected;
  });

  test('cloud copies preserve only the authenticated account private data', () {
    final original = <String, dynamic>{
      'privateMasterMarkets': {'private': true},
      'personalMarketPending': {
        'own': {'requesterUserId': _account},
        'other': {'requesterUserId': 'other-account'},
        'private': {'requesterUserId': _account, 'privateMaster': true},
      },
      'campaigns': [
        {
          'sessionMaterialByMaster': {
            'account:$_account': {'own': true},
            'account:other-account': {'other': true},
          },
        },
      ],
    };
    final filtered = oculumCloudSaveForAccount(original, _account);
    expect(filtered.containsKey('privateMasterMarkets'), isFalse);
    expect((filtered['personalMarketPending'] as Map).keys, ['own']);
    final campaign = (filtered['campaigns'] as List).single as Map;
    expect(campaign['sessionMaterialByMaster'], {
      'account:$_account': {'own': true},
    });
    expect(original.containsKey('privateMasterMarkets'), isTrue);
    expect((original['personalMarketPending'] as Map).length, 3);
  });

  testWidgets(
    'selecting folders does not upload or restore without a choice',
    (tester) async {
      final fromWindows = defaultTargetPlatform == TargetPlatform.windows;
      final currentFolder = fromWindows ? 'PC' : 'Telefono';
      final otherFolder = fromWindows ? 'Telefono' : 'PC';
      final currentCopy = fromWindows ? 'old-pc' : 'old-phone';
      final otherCopy = fromWindows ? 'old-phone' : 'old-pc';
      late final _CloudFixture fixture;
      late final OculumAuthService auth;
      await tester.runAsync(() async {
        fixture = _CloudFixture();
        await fixture.prepare();
        auth = await _initializeAuth(_AccountBackend());
      });
      tester.view
        ..physicalSize = const Size(390, 844)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final applied = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => OculumCloudSavesDialog(
                    auth: auth,
                    cloud: fixture.cloud,
                    accountId: _account,
                    readLocalBackup: (_, stillAuthorized) async {
                      expect(stillAuthorized(), isTrue);
                      return {'name': 'new device copy'};
                    },
                    restoreLocalBackup: (payload, stillAuthorized) async {
                      expect(stillAuthorized(), isTrue);
                      applied.add(payload['name'] as String);
                      return true;
                    },
                  ),
                ),
                child: const Text('Apri copie'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Apri copie'));
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey(currentCopy)), findsOneWidget);
      expect(find.byKey(ValueKey(otherCopy)), findsNothing);
      expect(
        fixture.requests.every((request) => request.method == 'GET'),
        isTrue,
      );

      await tester.tap(find.text(otherFolder));
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey(currentCopy)), findsNothing);
      final otherRow = find.byKey(ValueKey(otherCopy));
      expect(otherRow, findsOneWidget);
      await tester.tap(otherRow);
      await tester.pumpAndSettle();
      expect(find.text('Ripristinare questa copia?'), findsOneWidget);
      expect(
        fixture.requests.any((r) => r.url.queryParameters['id'] != null),
        isFalse,
      );
      await tester.tap(find.text('Annulla'));
      await tester.pumpAndSettle();
      expect(applied, isEmpty);
      await tester.tap(otherRow);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ripristina su questo dispositivo'));
      await tester.pumpAndSettle();
      expect(applied, [otherCopy]);

      await tester.tap(find.text('Salva copia di questo dispositivo'));
      await tester.pumpAndSettle();
      expect(find.text('Copia salvata in $currentFolder.'), findsOneWidget);
      final posted = fixture.requests.singleWhere((r) => r.method == 'POST');
      final row = jsonDecode(posted.body) as Map;
      expect(row['device_origin'], fromWindows ? 'windows' : 'android');
      expect(row['user_id'], _account);
      expect(row['payload'], {'name': 'new device copy'});
      expect(fixture.rows.map((copy) => copy['id']), contains(otherCopy));
      await tester.pumpWidget(const SizedBox.shrink());
    },
    variant: const TargetPlatformVariant({
      TargetPlatform.windows,
      TargetPlatform.android,
    }),
  );
}
