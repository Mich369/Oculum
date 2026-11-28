import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:passkeys_platform_interface/passkeys_platform_interface.dart';
import 'package:passkeys_platform_interface/types/types.dart';
import 'package:passkeys_windows/passkeys_windows.dart';

const _relyingParty = 'mich369.github.io';
const _origin = 'https://$_relyingParty';
final _windowsApiAvailable = _hasWindowsWebAuthn();
final _windowsAdapter = OculumWindowsPasskeyAdapter(PasskeysWindows());

bool _hasWindowsWebAuthn() {
  if (!Platform.isWindows) return false;
  try {
    final webauthn = DynamicLibrary.open('webauthn.dll');
    return webauthn.lookupFunction<Uint32 Function(), int Function()>(
          'WebAuthNGetApiVersionNumber',
        )() >
        0;
  } on ArgumentError {
    return false;
  }
}

bool get isPasskeySupported => _windowsApiAvailable;

Future<Map<String, dynamic>?> createPasskey(
  Map<String, dynamic> options,
) async {
  if (!isPasskeySupported) {
    throw UnsupportedError('Passkey Windows non disponibile.');
  }
  return _windowsAdapter.createPasskey(options);
}

Future<Map<String, dynamic>?> getPasskey(Map<String, dynamic> options) async {
  if (!isPasskeySupported) {
    throw UnsupportedError('Passkey Windows non disponibile.');
  }
  return _windowsAdapter.getPasskey(options);
}

class OculumWindowsPasskeyAdapter {
  OculumWindowsPasskeyAdapter(this._platform);

  final PasskeysPlatform _platform;
  bool _busy = false;

  Future<Map<String, dynamic>?> createPasskey(
    Map<String, dynamic> options,
  ) async {
    final source = _options(options);
    final rp = _object(source['rp'], 'rp');
    _checkRelyingParty(rp['id']);
    final challenge = _encoded(source['challenge'], 'challenge');
    final user = _object(source['user'], 'user');
    final userId = _encoded(user['id'], 'user.id');
    if (_decode(userId).length > 64) {
      throw const FormatException('Identità passkey non valida.');
    }
    final selection = source['authenticatorSelection'];
    final request = RegisterRequestType.fromJson({
      ...source,
      'challenge': challenge,
      'rp': {...rp, 'name': _display(rp['name'])},
      'user': {
        ...user,
        'id': userId,
        'name': _display(user['name']),
        'displayName': _display(user['displayName'] ?? user['name']),
      },
      'authenticatorSelection': {
        if (selection != null) ..._object(selection, 'authenticatorSelection'),
        'residentKey': 'required',
        'requireResidentKey': true,
        'userVerification': 'required',
      },
    });
    return _prompt(() async {
      final result = await _platform.register(request);
      _verifyClientData(result.clientDataJSON, challenge, 'webauthn.create');
      _encoded(result.attestationObject, 'attestationObject');
      return _credential(result.toJson(), result.id, result.rawId);
    });
  }

  Future<Map<String, dynamic>?> getPasskey(Map<String, dynamic> options) async {
    final source = _options(options);
    _checkRelyingParty(source['rpId']);
    final challenge = _encoded(source['challenge'], 'challenge');
    final request = AuthenticateRequestType.fromJson(
      {...source, 'challenge': challenge, 'userVerification': 'required'},
      mediation: MediationType.Required,
      preferImmediatelyAvailableCredentials: false,
    );
    return _prompt(() async {
      final result = await _platform.authenticate(request);
      _verifyClientData(result.clientDataJSON, challenge, 'webauthn.get');
      final authData = _decode(
        _encoded(result.authenticatorData, 'authenticatorData'),
      );
      if (authData.length < 37 || (authData[32] & 0x04) == 0) {
        throw const FormatException('Verifica utente Windows Hello mancante.');
      }
      _encoded(result.signature, 'signature');
      return _credential(result.toJson(), result.id, result.rawId);
    });
  }

  Future<Map<String, dynamic>?> _prompt(
    Future<Map<String, dynamic>> Function() operation,
  ) async {
    if (_busy) throw StateError('È già in corso un’operazione Passkey.');
    _busy = true;
    try {
      final availability = await _platform.getAvailability();
      if (!availability.hasPasskeySupport) {
        throw UnsupportedError('Passkey Windows non disponibile.');
      }
      return await operation();
    } on PlatformException catch (error) {
      if (error.code == 'user-cancelled') return null;
      rethrow;
    } finally {
      _busy = false;
    }
  }
}

Map<String, dynamic> _options(Map<String, dynamic> source) {
  final nested = source['publicKey'];
  return nested == null ? source : _object(nested, 'publicKey');
}

Map<String, dynamic> _object(Object? value, String field) {
  if (value is! Map<String, dynamic>) {
    throw FormatException('Opzioni Passkey non valide per $field.');
  }
  return value;
}

String _display(Object? value) =>
    value is String && value.trim().isNotEmpty ? value : 'Oculum';

final _base64UrlCharacters = RegExp(r'^[A-Za-z0-9_-]+={0,2}$');
final _padding = RegExp(r'=+$');

List<int> _decode(String value) => base64Url.decode(base64Url.normalize(value));

String _encoded(Object? value, String field) {
  if (value is! String || !_base64UrlCharacters.hasMatch(value)) {
    throw FormatException('Dati Passkey non validi per $field.');
  }
  return base64Url.encode(_decode(value)).replaceFirst(_padding, '');
}

void _checkRelyingParty(Object? value) {
  if (value != _relyingParty) {
    throw const FormatException('Dominio Passkey inatteso.');
  }
}

void _verifyClientData(String encoded, String challenge, String type) {
  final decoded = jsonDecode(
    utf8.decode(_decode(_encoded(encoded, 'clientDataJSON'))),
  );
  if (decoded is! Map<String, dynamic> ||
      decoded['origin'] != _origin ||
      decoded['type'] != type ||
      decoded['crossOrigin'] == true ||
      _encoded(decoded['challenge'], 'challenge') != challenge) {
    throw const FormatException(
      'Risposta Passkey per un’origine o una richiesta inattesa.',
    );
  }
}

Map<String, dynamic> _credential(
  Map<String, dynamic> result,
  String id,
  String rawId,
) {
  if (_encoded(id, 'id') != _encoded(rawId, 'rawId')) {
    throw const FormatException('Identificativo Passkey incoerente.');
  }
  return result;
}
