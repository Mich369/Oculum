bool get isPasskeySupported => false;

Future<Map<String, dynamic>?> createPasskey(
  Map<String, dynamic> options,
) async =>
    throw UnsupportedError('Passkey non disponibile su questa piattaforma.');

Future<Map<String, dynamic>?> getPasskey(Map<String, dynamic> options) async =>
    throw UnsupportedError('Passkey non disponibile su questa piattaforma.');
