import 'dart:io';

/// Keeps Windows test runs green when an image viewer temporarily maps a
/// previous capture and the stable output filename cannot be overwritten.
File _writableOutputFile(File target) {
  final stamp = DateTime.now().microsecondsSinceEpoch;
  final filename = target.uri.pathSegments.last;
  final extension = filename.contains('.')
      ? filename.substring(filename.lastIndexOf('.'))
      : '';
  final stem = extension.isEmpty
      ? filename
      : filename.substring(0, filename.length - extension.length);
  final fallback = File(
    '${target.parent.path}${Platform.pathSeparator}'
    '$stem-$stamp$extension',
  );
  fallback.parent.createSync(recursive: true);
  return fallback;
}

void writeTestOutputBytes(File target, List<int> bytes) {
  try {
    target.writeAsBytesSync(bytes);
  } on FileSystemException {
    final fallback = _writableOutputFile(target);
    fallback.writeAsBytesSync(bytes);
  }
}

void writeTestOutputString(File target, String value) {
  try {
    target.writeAsStringSync(value);
  } on FileSystemException {
    final fallback = _writableOutputFile(target);
    fallback.writeAsStringSync(value);
  }
}
