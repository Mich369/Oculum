import 'dart:io';

/// Windows may keep a previously viewed artifact mapped. Preserve the fresh file
/// under a unique name in the same artifact directory instead of losing it.
void writeFreshCapture(File file, List<int> bytes) {
  try {
    file.writeAsBytesSync(bytes);
  } on FileSystemException catch (error) {
    if (error.osError?.errorCode != 1224) rethrow;
    final dot = file.path.lastIndexOf('.');
    final fresh = File(
      '${file.path.substring(0, dot)}-${DateTime.now().microsecondsSinceEpoch}${file.path.substring(dot)}',
    );
    fresh.writeAsBytesSync(bytes);
    stderr.writeln(
      'Fresh capture: ${fresh.path} (previous artifact mapped by Windows).',
    );
  }
}
