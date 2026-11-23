import 'oculum_smoke_storage_policy.dart';

Future<void> recordOculumSmokeStatusPlatform(
  String phase,
  Map<String, Object?> metadata,
) async {}

Future<void> configureOculumSmokeStoragePlatform(String root) async {
  throw const OculumSmokeStorageException('unsupported_platform');
}
