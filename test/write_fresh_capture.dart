import 'dart:io';
import 'dart:typed_data';

/// Windows may keep a previously viewed PNG mapped. Preserve the fresh capture
/// under a unique name in the same artifact directory instead of losing it.
void writeFreshCapture(File file, Uint8List bytes) {
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
      'Fresh capture: ${fresh.path} (previous PNG mapped by Windows).',
    );
  }
}
