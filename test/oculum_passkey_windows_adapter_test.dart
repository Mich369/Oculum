import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/services/oculum_platform_passkey_windows.dart';
import 'package:passkeys_platform_interface/passkeys_platform_interface.dart';
import 'package:passkeys_platform_interface/types/types.dart';

const rp = 'mich369.github.io';
const origin = 'https://$rp';
const challenge = 'c3ludGhldGljLWNoYWxsZW5nZS1wcm9iZQ';
const credential = 'b2N1bHVtLWZpeHR1cmU';

String encode(List<int> bytes) => base64Url.encode(bytes).replaceAll('=', '');

String clientData(
  String kind, {
  String responseOrigin = origin,
  String responseChallenge = challenge,
  bool crossOrigin = false,
}) => encode(
  utf8.encode(
    jsonEncode({
      'type': kind,
      'origin': responseOrigin,
      'challenge': responseChallenge,
      'crossOrigin': crossOrigin,
    }),
  ),
);

class _FakePlatform extends PasskeysPlatform {
  bool capable = true;
  String? error;
  String responseOrigin = origin;
  String responseChallenge = challenge;
  bool crossOrigin = false;
  bool uv = true;
  bool wrongId = false;
  int promptCount = 0;
  RegisterRequestType? registration;
  AuthenticateRequestType? authentication;
  Completer<void>? waitForPrompt;

  @override
  Future<void> cancelCurrentAuthenticatorOperation() async {}

  @override
  Future<AvailabilityTypeWindows> getAvailability() async =>
      AvailabilityTypeWindows(
        hasPasskeySupport: capable,
        isNative: true,
        isUserVerifyingPlatformAuthenticatorAvailable: capable,
      );

  @override
  Future<RegisterResponseType> register(RegisterRequestType request) async {
    registration = request;
    await _prompt();
    return RegisterResponseType(
      id: credential,
      rawId: wrongId ? 'b3RoZXI' : credential,
      clientDataJSON: clientData(
        'webauthn.create',
        responseOrigin: responseOrigin,
        responseChallenge: responseChallenge,
        crossOrigin: crossOrigin,
      ),
      attestationObject: 'YWJj',
      transports: ['internal'],
    );
  }

  @override
  Future<AuthenticateResponseType> authenticate(
    AuthenticateRequestType request,
  ) async {
    authentication = request;
    await _prompt();
    final authData = List.filled(37, 0)..[32] = uv ? 0x05 : 0x01;
    return AuthenticateResponseType(
      id: credential,
      rawId: wrongId ? 'b3RoZXI' : credential,
      clientDataJSON: clientData(
        'webauthn.get',
        responseOrigin: responseOrigin,
        responseChallenge: responseChallenge,
        crossOrigin: crossOrigin,
      ),
      authenticatorData: encode(authData),
      signature: 'c2lnbmF0dXJl',
      userHandle: 'dXNlcg',
    );
  }

  Future<void> _prompt() async {
    promptCount++;
    if (error != null) throw PlatformException(code: error!);
    await waitForPrompt?.future;
  }
}

Map<String, dynamic> _registration() => {
  'publicKey': {
    'rp': {'id': rp, 'name': 'Oculum'},
    'user': {'id': 'dXNlcg'},
    'challenge': challenge,
    'pubKeyCredParams': [
      {'alg': -7, 'type': 'public-key'},
    ],
    'excludeCredentials': [
      {'id': credential, 'type': 'public-key'},
    ],
    'authenticatorSelection': {
      'userVerification': 'discouraged',
      'residentKey': 'preferred',
    },
    'timeout': 60000,
  },
};

Map<String, dynamic> _authentication() => {
  'rpId': rp,
  'challenge': challenge,
  'userVerification': 'discouraged',
  'allowCredentials': [
    {
      'id': credential,
      'type': 'public-key',
      'transports': ['internal'],
    },
  ],
};

void main() {
  test(
    'maps wrapped W3C registration and preserves a discoverable verified credential',
    () async {
      final fake = _FakePlatform();
      final result = await OculumWindowsPasskeyAdapter(
        fake,
      ).createPasskey(_registration());
      expect(fake.registration!.relyingParty.id, rp);
      expect(fake.registration!.user.id, 'dXNlcg');
      expect(fake.registration!.user.name, 'Oculum');
      expect(fake.registration!.challenge, challenge);
      expect(fake.registration!.timeout, 60000);
      expect(fake.registration!.pubKeyCredParams!.single.alg, -7);
      expect(fake.registration!.excludeCredentials.single.id, credential);
      expect(
        fake.registration!.authSelectionType!.userVerification,
        'required',
      );
      expect(fake.registration!.authSelectionType!.requireResidentKey, isTrue);
      expect(fake.registration!.authSelectionType!.residentKey, 'required');
      expect(result!['type'], 'public-key');
      expect(result['id'], credential);
      expect(result['response'], {
        'clientDataJSON': clientData('webauthn.create'),
        'attestationObject': 'YWJj',
        'transports': ['internal'],
      });
    },
  );

  test(
    'maps direct W3C assertion and asks for user verification with security key available',
    () async {
      final fake = _FakePlatform();
      final result = await OculumWindowsPasskeyAdapter(
        fake,
      ).getPasskey(_authentication());
      final request = fake.authentication!;
      expect(request.relyingPartyId, rp);
      expect(request.challenge, challenge);
      expect(request.userVerification, 'required');
      expect(request.preferImmediatelyAvailableCredentials, isFalse);
      expect(request.allowCredentials!.single.transports, ['internal']);
      expect(result!['response']['userHandle'], 'dXNlcg');
      expect(result['response']['signature'], 'c2lnbmF0dXJl');
    },
  );

  test(
    'rejects a foreign RP or malformed challenge before any native prompt',
    () async {
      final fake = _FakePlatform();
      final adapter = OculumWindowsPasskeyAdapter(fake);
      await expectLater(
        adapter.getPasskey({
          ..._authentication(),
          'rpId': 'mich369.github.io/Oculum',
        }),
        throwsFormatException,
      );
      final creation = _registration();
      (creation['publicKey'] as Map)['rp'] = {
        'id': 'other.example',
        'name': 'Other',
      };
      await expectLater(adapter.createPasskey(creation), throwsFormatException);
      await expectLater(
        adapter.getPasskey({..._authentication(), 'challenge': '/invalid+'}),
        throwsFormatException,
      );
      expect(fake.promptCount, 0);
    },
  );

  test('rejects inconsistent signed data, UV, or credential ID', () async {
    final fake = _FakePlatform()..responseOrigin = 'https://other.example';
    final adapter = OculumWindowsPasskeyAdapter(fake);
    await expectLater(
      adapter.createPasskey(_registration()),
      throwsFormatException,
    );
    fake.responseOrigin = origin;
    fake.responseChallenge = 'd3JvbmctY2hhbGxlbmdl';
    await expectLater(
      adapter.getPasskey(_authentication()),
      throwsFormatException,
    );
    fake.responseChallenge = challenge;
    fake.crossOrigin = true;
    await expectLater(
      adapter.getPasskey(_authentication()),
      throwsFormatException,
    );
    fake.crossOrigin = false;
    fake.uv = false;
    await expectLater(
      adapter.getPasskey(_authentication()),
      throwsFormatException,
    );
    fake.uv = true;
    fake.wrongId = true;
    await expectLater(
      adapter.createPasskey(_registration()),
      throwsFormatException,
    );
  });

  test(
    'only user cancellation returns null and retry remains available',
    () async {
      final fake = _FakePlatform()..error = 'user-cancelled';
      final adapter = OculumWindowsPasskeyAdapter(fake);
      expect(await adapter.getPasskey(_authentication()), isNull);
      fake.error = 'storage-full';
      await expectLater(
        adapter.createPasskey(_registration()),
        throwsA(isA<PlatformException>()),
      );
      fake.error = null;
      expect(await adapter.createPasskey(_registration()), isNotNull);
    },
  );

  test('availability and a single active operation guard native use', () async {
    final fake = _FakePlatform()..capable = false;
    final adapter = OculumWindowsPasskeyAdapter(fake);
    await expectLater(
      adapter.createPasskey(_registration()),
      throwsUnsupportedError,
    );
    expect(fake.promptCount, 0);
    final wait = Completer<void>();
    fake.capable = true;
    fake.waitForPrompt = wait;
    final pending = adapter.getPasskey(_authentication());
    await expectLater(adapter.createPasskey(_registration()), throwsStateError);
    wait.complete();
    expect(await pending, isNotNull);
    expect(fake.promptCount, 1);
  });
}
