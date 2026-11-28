import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'oculum_rl_release.dart';

const oculumRlMaxRuntimeBytes = 768 * 1024 * 1024;
const oculumRlMaxRuntimeFiles = 4000;
final _unsafe = RegExp(r'[<>:"|?*\\\x00-\x1f]');
final _reserved = RegExp(
  r'^(con|prn|aux|nul|com[1-9¹²³]|lpt[1-9¹²³])(?:\.|$)',
  caseSensitive: false,
);
final _sha = RegExp(r'^[a-f0-9]{64}$');

bool oculumRlRuntimePathIsValid(String path) {
  final lower = path.toLowerCase();
  return path.length <= 512 &&
      lower != '.oculum-rl-update.json' &&
      !lower.startsWith('.ack-') &&
      path
          .split('/')
          .every(
            (part) =>
                part.isNotEmpty &&
                part != '.' &&
                part != '..' &&
                !part.endsWith('.') &&
                !part.endsWith(' ') &&
                !_unsafe.hasMatch(part) &&
                !_reserved.hasMatch(part),
          );
}

class OculumRlRuntimeFile {
  const OculumRlRuntimeFile._(
    this.path,
    this.size,
    this.sha256,
    this.offset,
    this.length,
    this.method,
  );

  final String path;
  final int size;
  final String sha256;
  final int offset;
  final int length;
  final int method;
}

List<OculumRlRuntimeFile> readOculumRlUpdateIndex(
  String json,
  OculumRlRelease release,
  OculumRlEdition edition,
) {
  const invalid = FormatException('Indice di aggiornamento non valido');
  final decoded = jsonDecode(json);
  if (decoded is! Map ||
      decoded['schemaVersion'] != 1 ||
      decoded['version'] != release.version.toString() ||
      decoded['edition'] != edition.name ||
      decoded['archiveBytes'] != release.bytes ||
      decoded['archiveSha256'] != release.sha256 ||
      decoded['files'] is! List) {
    throw invalid;
  }
  final rows = decoded['files'] as List;
  if (rows.isEmpty || rows.length > oculumRlMaxRuntimeFiles) throw invalid;
  final files = <OculumRlRuntimeFile>[];
  final names = <String>{};
  final folders = <String>{};
  var total = 0;
  for (final row in rows) {
    if (row is! Map) throw invalid;
    final path = row['path'], size = row['size'], hash = row['sha256'];
    final offset = row['offset'],
        length = row['length'],
        method = row['method'];
    if (path is! String ||
        !oculumRlRuntimePathIsValid(path) ||
        size is! int ||
        size < 0 ||
        hash is! String ||
        !_sha.hasMatch(hash) ||
        offset is! int ||
        offset < 30 ||
        offset > release.bytes ||
        length is! int ||
        length < 0 ||
        length > release.bytes - offset ||
        method is! int ||
        (method != 0 && method != 8) ||
        (method == 0 && length != size) ||
        (method == 8 && length == 0)) {
      throw invalid;
    }
    total += size;
    final name = path.toLowerCase();
    if (total > oculumRlMaxRuntimeBytes || !names.add(name)) throw invalid;
    for (
      var slash = name.indexOf('/');
      slash >= 0;
      slash = name.indexOf('/', slash + 1)
    ) {
      folders.add(name.substring(0, slash));
    }
    files.add(OculumRlRuntimeFile._(path, size, hash, offset, length, method));
  }
  const required = ['flutter_windows.dll', 'data/icudtl.dat', 'data/app.so'];
  final other = edition == OculumRlEdition.test
      ? OculumRlEdition.normal
      : OculumRlEdition.test;
  if (names.any(folders.contains) ||
      names.contains(other.executable.toLowerCase()) ||
      ![edition.executable, ...required].every(
        (path) => files.any((file) => file.path == path && file.size > 0),
      )) {
    throw invalid;
  }
  final ranges = files.where((file) => file.length > 0).toList()
    ..sort((a, b) => a.offset.compareTo(b.offset));
  var end = 0;
  for (final file in ranges) {
    if (file.offset < end) throw invalid;
    end = file.offset + file.length;
  }
  return List.unmodifiable(files);
}

class OculumRlUpdatePlan {
  const OculumRlUpdatePlan._(this.files, this.reuse, this.downloadBytes);

  final List<OculumRlRuntimeFile> files;
  final Set<String> reuse;
  final int downloadBytes;
  int get changedFiles => files.length - reuse.length;
}

Future<bool> _matches(File source, OculumRlRuntimeFile entry) async {
  if (await source.length() != entry.size) return false;
  return (await sha256.bind(source.openRead()).first).toString() ==
      entry.sha256;
}

Future<File?> _installedFile(Directory root, String relative) async {
  final source = File('${root.path}/$relative');
  try {
    if (await FileSystemEntity.type(source.path, followLinks: false) !=
        FileSystemEntityType.file)
      return null;
    final resolved = (await source.resolveSymbolicLinks()).replaceAll(
      '\\',
      '/',
    );
    final expected = source.absolute.path.replaceAll('\\', '/');
    if (Platform.isWindows
        ? resolved.toLowerCase() != expected.toLowerCase()
        : resolved != expected) {
      return null;
    }
    return source;
  } on FileSystemException {
    return null;
  }
}

Future<OculumRlUpdatePlan> planOculumRlUpdate(
  Directory installed,
  List<OculumRlRuntimeFile> files,
) async {
  final root = Directory(await installed.resolveSymbolicLinks());
  final reuse = <String>{};
  var downloadBytes = 0;
  for (final entry in files) {
    final source = await _installedFile(root, entry.path);
    try {
      if (source != null && await _matches(source, entry)) {
        reuse.add(entry.path);
        continue;
      }
    } on FileSystemException {
      // A file unreadable in the installed runtime must be obtained anew.
    }
    downloadBytes += entry.length;
  }
  return OculumRlUpdatePlan._(files, Set.unmodifiable(reuse), downloadBytes);
}

Future<void> writeOculumRlUpdateRuntime(
  Directory installed,
  Directory destination,
  OculumRlUpdatePlan plan, {
  required int archiveBytes,
  required Future<HttpClientResponse> Function(int first, int last)
  requestRange,
}) async {
  final root = Directory(await installed.resolveSymbolicLinks());
  for (final entry in plan.files) {
    final output = File('${destination.path}/${entry.path}');
    await output.parent.create(recursive: true);
    if (plan.reuse.contains(entry.path)) {
      final source = await _installedFile(root, entry.path);
      if (source == null) {
        throw const FileSystemException(
          'Il runtime è cambiato durante la preparazione',
        );
      }
      await source.copy(output.path);
    } else {
      await _writeRange(entry, output, archiveBytes, requestRange);
    }
    if (!await _matches(output, entry)) {
      throw const FormatException(
        'SHA-256 del file di aggiornamento non corrisponde',
      );
    }
  }
}

Future<void> _writeRange(
  OculumRlRuntimeFile entry,
  File output,
  int archiveBytes,
  Future<HttpClientResponse> Function(int first, int last) requestRange,
) async {
  if (entry.length == 0) {
    await output.create();
    return;
  }
  final last = entry.offset + entry.length - 1;
  final response = await requestRange(entry.offset, last);
  if (response.statusCode != HttpStatus.partialContent ||
      response.headers.value(HttpHeaders.contentRangeHeader) !=
          'bytes ${entry.offset}-$last/$archiveBytes' ||
      (response.contentLength >= 0 && response.contentLength != entry.length) ||
      response.compressionState !=
          HttpClientResponseCompressionState.notCompressed) {
    // Do not consume the body if the server returns the full archive.
    throw const HttpException('Il download parziale non è disponibile');
  }
  var received = 0;
  final compressed = response.timeout(const Duration(seconds: 25)).map((chunk) {
    received += chunk.length;
    if (received > entry.length)
      throw const FormatException('Intervallo troppo grande');
    return chunk;
  });
  final Stream<List<int>> contents = entry.method == 0
      ? compressed
      : ZLibCodec(raw: true).decoder.bind(compressed);
  final writer = await output.open(mode: FileMode.write);
  var expanded = 0;
  try {
    await for (final chunk in contents) {
      expanded += chunk.length;
      if (expanded > entry.size)
        throw const FormatException('File troppo grande');
      await writer.writeFrom(chunk);
    }
  } finally {
    await writer.close();
  }
  if (received != entry.length || expanded != entry.size) {
    throw const FormatException('File di aggiornamento incompleto');
  }
}
