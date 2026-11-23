import 'package:flutter/foundation.dart';

import 'oculum_smoke_storage_policy.dart';
import 'oculum_smoke_storage_stub.dart'
    if (dart.library.io) 'oculum_smoke_storage_io.dart'
    as implementation;

export 'oculum_smoke_storage_policy.dart';

bool _oculumSmokeStorageActive = false;

/// A smoke process is local-only and keeps the normal/Test key namespace.
bool get oculumSmokeStorageActive => _oculumSmokeStorageActive;

/// Must run before the first preferences, auth, or application-directory read.
Future<void> configureOculumSmokeStorage(List<String> arguments) async {
  final root = oculumSmokeStorageRootArgument(arguments);
  if (root == null) return;
  if (_oculumSmokeStorageActive) {
    throw const OculumSmokeStorageException('already_configured');
  }
  await implementation.configureOculumSmokeStoragePlatform(root);
  _oculumSmokeStorageActive = true;
}

/// Metadata only: never pass key names, values, save contents, or auth tokens.
Future<void> recordOculumSmokeStatus(
  String phase,
  Map<String, Object?> metadata,
) async {
  if (!_oculumSmokeStorageActive) return;
  await implementation.recordOculumSmokeStatusPlatform(phase, metadata);
}

@visibleForTesting
void oculumSetSmokeStorageActiveForTesting(bool value) {
  _oculumSmokeStorageActive = value;
}
