import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:oculum/services/oculum_auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _owner = OculumBackendUser(
  id: 'verified-owner',
  provider: 'google',
  hasVerifiedEmail: true,
);
const _guest = OculumBackendUser(
  id: 'anonymous-room-owner',
  provider: 'anonymous',
);
const _other = OculumBackendUser(
  id: 'other-owner',
  provider: 'email',
  hasVerifiedEmail: true,
);
const _credential = <String, dynamic>{
  'type': 'public-key',
  'id': 'local-fixture',
};

class _PasskeyBackend implements OculumAuthBackend, OculumPasskeyAuthBackend {
  final _events = StreamController<OculumBackendAuthEvent>.broadcast(
    sync: true,
  );
  OculumBackendUser? user;
  OculumBackendUser assertionUser = _owner;
  var authenticationStarts = 0;
  var registrationStarts = 0;
  var verifyCount = 0;
  var adoptionCount = 0;
  var enrollmentCount = 0;
  final verificationStarted = Completer<void>();
  Completer<void>? finishVerification;

  @override
  OculumBackendUser? get currentUser => user;

  @override
  Stream<OculumBackendAuthEvent> get events => _events.stream;

  @override
  bool get passkeysConfigured => true;

  void switchAccount(OculumBackendUser? next) {
    user = next;
    _events.add(
      OculumBackendAuthEvent(
        next == null
            ? OculumBackendAuthEventType.signedOut
            : OculumBackendAuthEventType.signedIn,
        user: next,
      ),
    );
  }

  void deliverEarlierAccountEvent(OculumBackendUser earlier) => _events.add(
    OculumBackendAuthEvent(OculumBackendAuthEventType.signedIn, user: earlier),
  );

  Future<void> close() => _events.close();

  @override
  Future<void> signOut() async => switchAccount(null);

  @override
  Future<bool> startOAuth(
    OculumAuthProvider provider, {
    required String? redirectTo,
  }) async => false;

  @override
  Future<OculumPasskeyChallenge> startPasskeyAuthentication() async {
    authenticationStarts++;
    return (id: 'authentication', options: {'fixture': 'login'});
  }

  @override
  Future<OculumPasskeyChallenge> startPasskeyRegistration() async {
    registrationStarts++;
    return (id: 'registration', options: {'fixture': 'register'});
  }

  @override
  Future<OculumVerifiedPasskeySession> verifyPasskeyAuthentication(
    String challengeId,
    Map<String, dynamic> credential,
  ) async {
    expect(challengeId, 'authentication');
    expect(credential, _credential);
    verifyCount++;
    verificationStarted.complete();
    await finishVerification?.future;
    return OculumVerifiedPasskeySession(
      user: assertionUser,
      adopt: () async {
        adoptionCount++;
        switchAccount(assertionUser);
      },
    );
  }

  @override
  Future<void> verifyPasskeyRegistration(
    String challengeId,
    Map<String, dynamic> credential,
  ) async {
    expect(challengeId, 'registration');
    expect(credential, _credential);
    enrollmentCount++;
  }
}

Future<OculumAuthService> _auth(
  _PasskeyBackend backend, {
  bool supported = true,
  OculumPasskeyPrompt? create,
  OculumPasskeyPrompt? get,
}) async {
  addTearDown(backend.close);
  final auth = OculumAuthService.forTesting(
    backend: backend,
    connectivityCheck: () async => true,
    passkeySupported: supported,
    createPasskey: create ?? (_) async => _credential,
    getPasskey: get ?? (_) async => _credential,
  );
  addTearDown(auth.dispose);
  await auth.initialize();
  return auth;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'passkey login installs a verified session only after the explicit prompt',
    () async {
      final backend = _PasskeyBackend();
      final auth = await _auth(
        backend,
        get: (options) async {
          expect(options['fixture'], 'login');
          expect(backend.currentUser, isNull);
          return _credential;
        },
      );
      expect(auth.showPasskeySignIn, isTrue);
      expect(auth.showPasskeyRegistration, isFalse);
      expect(await auth.signInWithPasskey(), isTrue);
      expect(backend.adoptionCount, 1);
      expect(auth.state.userId, _owner.id);
      expect(auth.showPasskeySignIn, isFalse);
      expect(auth.showPasskeyRegistration, isTrue);
    },
  );

  test(
    'cancel during pending verification never installs the returned session',
    () async {
      final backend = _PasskeyBackend()..finishVerification = Completer<void>();
      final auth = await _auth(backend);
      final pending = auth.signInWithPasskey();
      await backend.verificationStarted.future;
      auth.cancelPendingSignIn();
      backend.finishVerification!.complete();
      expect(await pending, isFalse);
      expect(backend.adoptionCount, 0);
      expect(auth.state.userId, isNull);
      expect(auth.state.errorMessage, contains('annullata'));
    },
  );

  test(
    'account switch during assertion verification preserves the new account',
    () async {
      final backend = _PasskeyBackend()..finishVerification = Completer<void>();
      final auth = await _auth(backend);
      final pending = auth.signInWithPasskey();
      await backend.verificationStarted.future;
      backend.switchAccount(_other);
      backend.finishVerification!.complete();
      expect(await pending, isFalse);
      await Future<void>.delayed(Duration.zero);
      expect(backend.adoptionCount, 0);
      expect(auth.state.userId, _other.id);
    },
  );

  test(
    'enrollment cannot follow a session switch while the device prompts',
    () async {
      final backend = _PasskeyBackend()..user = _owner;
      final credential = Completer<Map<String, dynamic>?>();
      final prompted = Completer<void>();
      final auth = await _auth(
        backend,
        create: (options) {
          expect(options['fixture'], 'register');
          prompted.complete();
          return credential.future;
        },
      );
      final pending = auth.registerPasskey();
      await prompted.future;
      backend.switchAccount(_other);
      credential.complete(_credential);
      expect(await pending, isFalse);
      await Future<void>.delayed(Duration.zero);
      expect(backend.enrollmentCount, 0);
      expect(auth.state.userId, _other.id);
    },
  );

  test(
    'a rapid switch away and back still invalidates the passkey action',
    () async {
      final backend = _PasskeyBackend()..user = _owner;
      final credential = Completer<Map<String, dynamic>?>();
      final prompted = Completer<void>();
      final auth = await _auth(
        backend,
        create: (_) {
          prompted.complete();
          return credential.future;
        },
      );
      final pending = auth.registerPasskey();
      await prompted.future;
      // A queued account event can arrive after the SDK has restored this
      // identity. It still invalidates the original platform prompt.
      backend.deliverEarlierAccountEvent(_other);
      credential.complete(_credential);
      expect(await pending, isFalse);
      expect(backend.enrollmentCount, 0);
      expect(auth.state.userId, _owner.id);
    },
  );

  test(
    'device cancellation keeps the registered account and its provider',
    () async {
      final backend = _PasskeyBackend()..user = _owner;
      final auth = await _auth(backend, create: (_) async => null);
      expect(await auth.registerPasskey(), isFalse);
      expect(auth.state.userId, _owner.id);
      expect(auth.state.provider, 'google');
      expect(backend.enrollmentCount, 0);
      expect(auth.state.errorMessage, contains('annullata'));
    },
  );

  test(
    'a registered user adds a passkey without replacing the account',
    () async {
      final backend = _PasskeyBackend()..user = _owner;
      final auth = await _auth(backend);
      expect(await auth.signInWithPasskey(), isFalse);
      expect(await auth.registerPasskey(), isTrue);
      expect(backend.enrollmentCount, 1);
      expect(backend.adoptionCount, 0);
      expect(auth.state.userId, _owner.id);
      expect(auth.state.message, contains('aggiunta'));
    },
  );

  test('protected online guest must first link the existing account', () async {
    final backend = _PasskeyBackend()..user = _guest;
    final auth = await _auth(backend);
    expect(await auth.signInWithPasskey(), isFalse);
    expect(await auth.registerPasskey(), isFalse);
    expect(backend.authenticationStarts, 0);
    expect(backend.registrationStarts, 0);
    expect(auth.state.userId, _guest.id);
  });

  test(
    'unsupported platform leaves password and provider session flows alone',
    () async {
      final backend = _PasskeyBackend();
      final auth = await _auth(backend, supported: false);
      expect(auth.passkeysAvailable, isFalse);
      expect(await auth.signInWithPasskey(), isFalse);
      expect(backend.authenticationStarts, 0);
    },
  );

  test('unverified response is rejected before session adoption', () async {
    final backend = _PasskeyBackend()
      ..assertionUser = const OculumBackendUser(
        id: 'unverified',
        provider: 'email',
      );
    final auth = await _auth(backend);
    expect(await auth.signInWithPasskey(), isFalse);
    expect(backend.adoptionCount, 0);
    expect(auth.state.userId, isNull);
  });

  test(
    'verification sends the assertion only to the configured HTTPS Auth endpoint',
    () async {
      final backend = SupabaseOculumAuthBackend(
        projectUrl: Uri.parse('https://fixture.supabase.co'),
        publishableKey: 'sb_publishable_fixture',
      );
      var calls = 0;
      await http.runWithClient(
        () async {
          await expectLater(
            backend.verifyPasskeyAuthentication(
              'challenge-fixture',
              _credential,
            ),
            throwsA(isA<AuthException>()),
          );
        },
        () => MockClient((request) async {
          calls++;
          expect(request.followRedirects, isFalse);
          expect(request.method, 'POST');
          expect(
            request.url.toString(),
            'https://fixture.supabase.co/auth/v1/passkeys/authentication/verify',
          );
          expect(request.headers['apikey'], 'sb_publishable_fixture');
          expect(jsonDecode(request.body), {
            'challenge_id': 'challenge-fixture',
            'credential': _credential,
          });
          return http.Response('{}', 400);
        }),
      );
      expect(calls, 1);
    },
  );
}
