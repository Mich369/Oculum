/// Explicit opt-in only; an absent flag never inspects paths or backends.
const oculumSmokeStorageFlag = '--oculum-smoke-data-dir';
const oculumSmokeStorageMarker = 'OCULUM_SMOKE_STORAGE_ROOT';
const oculumSmokeStorageMarkerContents = 'oculum-smoke-storage-v1\n';

class OculumSmokeStorageException implements Exception {
  const OculumSmokeStorageException(this.code);

  final String code;

  @override
  String toString() => 'OculumSmokeStorageException($code)';
}

String? oculumSmokeStorageRootArgument(List<String> arguments) {
  final matches = arguments
      .where((argument) => argument.startsWith(oculumSmokeStorageFlag))
      .toList(growable: false);
  if (matches.isEmpty) return null;
  if (matches.length != 1 ||
      !matches.single.startsWith('$oculumSmokeStorageFlag=')) {
    throw const OculumSmokeStorageException('invalid_argument');
  }
  final root = matches.single.substring(oculumSmokeStorageFlag.length + 1);
  if (root.isEmpty || root != root.trim()) {
    throw const OculumSmokeStorageException('invalid_root');
  }
  return root;
}
