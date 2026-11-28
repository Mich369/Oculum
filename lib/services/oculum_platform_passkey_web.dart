import 'dart:js_interop';

@JS('oculumPasskeys.supported')
external bool _supported();

@JS('oculumPasskeys.create')
external JSPromise<JSAny?> _create(JSAny options);

@JS('oculumPasskeys.get')
external JSPromise<JSAny?> _get(JSAny options);

bool get isPasskeySupported {
  try {
    return _supported();
  } catch (_) {
    return false;
  }
}

Future<Map<String, dynamic>?> _read(JSPromise<JSAny?> response) async {
  final result = (await response.toDart)?.dartify();
  return result == null ? null : Map<String, dynamic>.from(result as Map);
}

Future<Map<String, dynamic>?> createPasskey(Map<String, dynamic> options) =>
    _read(_create(options.jsify()!));

Future<Map<String, dynamic>?> getPasskey(Map<String, dynamic> options) =>
    _read(_get(options.jsify()!));
