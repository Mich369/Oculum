import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:oculum/services/oculum_supabase_startup.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FixtureSessionStorage extends EmptyLocalStorage {
  _FixtureSessionStorage({this.failRead = false});

  final bool failRead;
  int initCalls = 0;
  int deleteCalls = 0;

  @override
  Future<void> initialize() async => initCalls++;

  @override
  Future<bool> hasAccessToken() async {
    if (failRead) throw PlatformException(code: 'fixture-storage-unavailable');
    return false;
  }

  @override
  Future<void> removePersistedSession() async => deleteCalls++;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'timed-out callers share the SDK operation until it really settles',
    () async {
      final startup = OculumSupabaseStartup();
      final sdkStarted = Completer<OculumBindSupabaseAuth>();
      final bindComplete = Completer<void>();
      var starts = 0;
      var binds = 0;
      var disposals = 0;
      var expired = 0;

      Future<bool> wait(Duration timeout) => startup.waitUntilReady(
        startSdk: () {
          starts++;
          return sdkStarted.future;
        },
        disposeIncompleteSdk: () async {
          disposals++;
        },
        timeout: timeout,
        onWaitExpired: () {
          expired++;
        },
      );

      expect(await wait(Duration.zero), isFalse);
      expect(await wait(Duration.zero), isFalse);
      expect(starts, 1);
      expect(disposals, 0);
      expect(expired, 2);

      final background = wait(const Duration(seconds: 2));
      sdkStarted.complete(() {
        binds++;
        return bindComplete.future;
      });
      expect(await wait(Duration.zero), isFalse);
      expect(binds, 1);
      expect(disposals, 0);
      bindComplete.complete();
      expect(await background, isTrue);
      expect(await wait(Duration.zero), isTrue);
      expect(starts, 1);
      expect(binds, 1);
    },
  );

  test(
    'a settled storage failure leaves SDK allocated and the retry disposes it',
    () async {
      SharedPreferences.setMockInitialValues({});
      final startup = OculumSupabaseStartup();
      final failingStorage = _FixtureSessionStorage(failRead: true);
      final recoveredStorage = _FixtureSessionStorage();
      final errors = <Object>[];
      var starts = 0;
      var binds = 0;
      var disposals = 0;
      var requests = 0;

      Future<bool> wait() => startup.waitUntilReady(
        startSdk: () async {
          starts++;
          await Supabase.initialize(
            url: 'https://supabase-fixture.invalid',
            publishableKey: 'fixture-key',
            httpClient: MockClient((_) async {
              requests++;
              throw StateError('This test does not use the network');
            }),
            authOptions: FlutterAuthClientOptions(
              localStorage: starts == 1 ? failingStorage : recoveredStorage,
              detectSessionInUri: false,
            ),
          );
          return () async {
            binds++;
          };
        },
        disposeIncompleteSdk: () async {
          disposals++;
          await Supabase.instance.dispose();
        },
        timeout: const Duration(seconds: 2),
        onError: errors.add,
      );

      addTearDown(() async {
        try {
          final sdk = Supabase.instance;
          if (sdk.isInitialized) await sdk.dispose();
        } on AssertionError {
          // No SDK remains to dispose.
        }
      });
      expect(await wait(), isFalse);
      expect(Supabase.instance.isInitialized, isTrue);
      expect(failingStorage.initCalls, 1);
      expect(recoveredStorage.initCalls, 0);
      expect(binds, 0);
      expect(errors.single, isA<PlatformException>());
      expect(await wait(), isTrue);
      expect(disposals, 1);
      expect(recoveredStorage.initCalls, 1);
      expect(binds, 1);
      expect(requests, 0);
      expect(failingStorage.deleteCalls + recoveredStorage.deleteCalls, 0);
    },
  );

  test(
    'retrying only the auth binding preserves the initialized SDK',
    () async {
      final startup = OculumSupabaseStartup();
      var starts = 0;
      var binds = 0;
      var disposals = 0;

      Future<bool> wait() => startup.waitUntilReady(
        startSdk: () async {
          starts++;
          return () async {
            binds++;
            if (binds == 1) throw StateError('Binding not ready');
          };
        },
        disposeIncompleteSdk: () async {
          disposals++;
        },
        timeout: const Duration(seconds: 2),
      );
      expect(await wait(), isFalse);
      expect(await wait(), isTrue);
      expect(starts, 1);
      expect(binds, 2);
      expect(disposals, 0);
    },
  );

  test(
    'a failed disposal blocks a restart until cleanup really succeeds',
    () async {
      final startup = OculumSupabaseStartup();
      var starts = 0;
      var disposals = 0;

      Future<bool> wait() => startup.waitUntilReady(
        startSdk: () async {
          starts++;
          if (starts == 1) throw StateError('Incomplete SDK');
          return () async {};
        },
        disposeIncompleteSdk: () async {
          disposals++;
          if (disposals == 1) throw StateError('Disposal incomplete');
        },
        timeout: const Duration(seconds: 2),
      );
      expect(await wait(), isFalse);
      expect(await wait(), isFalse);
      expect(starts, 1);
      expect(await wait(), isTrue);
      expect(starts, 2);
      expect(disposals, 2);
    },
  );
}
