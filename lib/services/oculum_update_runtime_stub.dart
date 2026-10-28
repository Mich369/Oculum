Future<void> oculumVerifyUpdateArchive(
  String path, {
  required int expectedBytes,
  required String expectedSha256,
  void Function(int received, int total)? onProgress,
}) async => throw UnsupportedError('Desktop update verification unavailable');

Future<bool> oculumWriteUpdateStartupAck({
  required String cacheRoot,
  required String commit,
  required String edition,
  Map<String, String>? environment,
}) async => false;

Future<String?> oculumReadUpdateFailure({
  required String cacheRoot,
  required String edition,
  DateTime? now,
}) async => null;
