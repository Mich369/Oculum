import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

import 'oculum_rl_release.dart';

bool get supportsOculumRlUpdates => Platform.isWindows;

const _ackVariable = 'OCULUM_RL_UPDATE_ACK';
const _ready = '.oculum-rl-update.json';
final _noncePattern = RegExp(r'^[0-9a-f]{24}$');

Future<Directory> _updateRoot(OculumRlEdition edition) async {
  final support = await getApplicationSupportDirectory();
  final root = await Directory('${support.path}/updates-v1/${edition.name}')
      .create(recursive: true);
  return Directory(await root.resolveSymbolicLinks());
}

bool _runtimeReady(Directory directory, OculumRlEdition edition) {
  const runtime = ['flutter_windows.dll', 'data/icudtl.dat', 'data/app.so'];
  final other = edition == OculumRlEdition.test
      ? OculumRlEdition.normal
      : OculumRlEdition.test;
  if (File('${directory.path}/${other.executable}').existsSync()) return false;
  return [edition.executable, ...runtime].every((name) {
    final path = '${directory.path}/$name';
    return FileSystemEntity.typeSync(path, followLinks: false) ==
            FileSystemEntityType.file &&
        File(path).lengthSync() > 0;
  });
}

bool _prepared(
  Directory directory,
  OculumRlVersion version,
  OculumRlEdition edition,
) {
  try {
    final receipt = jsonDecode(
      File('${directory.path}/$_ready').readAsStringSync(),
    );
    return receipt is Map &&
        receipt['version'] == '$version' &&
        receipt['edition'] == edition.name &&
        _runtimeReady(directory, edition);
  } on FormatException {
    return false;
  } on FileSystemException {
    return false;
  }
}

Future<OculumRlVersion?> findOculumRlUpdate(
  OculumRlVersion current,
  OculumRlEdition edition,
) async {
  if (!supportsOculumRlUpdates) return null;
  final root = await _updateRoot(edition);
  OculumRlVersion? staged;
  await for (final item in root.list(followLinks: false)) {
    if (item is! Directory) continue;
    final version = OculumRlVersion.parse(
      item.uri.pathSegments.where((s) => s.isNotEmpty).last,
    );
    if (version != null &&
        version.compareTo(current) > 0 &&
        (staged == null || version.compareTo(staged) > 0) &&
        _prepared(item, version, edition)) {
      staged = version;
    }
  }
  return staged;
}

Future<OculumRlVersion?> prepareOculumRlUpdate(
  OculumRlVersion current,
  OculumRlEdition edition,
) async {
  final staged = await findOculumRlUpdate(current, edition);
  if (staged != null || !supportsOculumRlUpdates) return staged;
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
  try {
    final request = await client.getUrl(Uri.parse(oculumRlReleaseApi));
    request.headers
      ..set(HttpHeaders.acceptHeader, 'application/vnd.github+json')
      ..set(HttpHeaders.userAgentHeader, 'Oculum-RL-Updater');
    final response = await request.close().timeout(const Duration(seconds: 12));
    if (response.statusCode != HttpStatus.ok)
      throw const HttpException('GitHub non disponibile');
    final body = await utf8.decoder
        .bind(response)
        .join()
        .timeout(const Duration(seconds: 15));
    final available = selectOculumRlRelease(
      body,
      current: current,
      edition: edition,
    );
    if (available == null) return null;
    await _install(client, await _updateRoot(edition), available, edition);
    return available.version;
  } finally {
    client.close(force: true);
  }
}

Future<HttpClientResponse> _download(HttpClient client, Uri uri) async {
  const hosts = {
    'github.com',
    'release-assets.githubusercontent.com',
    'objects.githubusercontent.com',
  };
  for (var redirect = 0; redirect < 4; redirect++) {
    if (uri.scheme != 'https' ||
        uri.userInfo.isNotEmpty ||
        !hosts.contains(uri.host)) {
      throw const HttpException('Origine del pacchetto non valida');
    }
    final request = await client.getUrl(uri);
    request.followRedirects = false;
    final response = await request.close().timeout(const Duration(seconds: 18));
    if (response.statusCode == HttpStatus.ok) return response;
    final location = response.headers.value(HttpHeaders.locationHeader);
    if (!response.isRedirect || location == null)
      throw const HttpException('Pacchetto non disponibile');
    await response.drain<void>().timeout(const Duration(seconds: 10));
    uri = uri.resolve(location);
  }
  throw const HttpException('Troppi reindirizzamenti');
}

Future<void> _install(
  HttpClient client,
  Directory root,
  OculumRlRelease release,
  OculumRlEdition edition,
) async {
  final stage = Directory(
    await (await root.createTemp('download-')).resolveSymbolicLinks(),
  );
  if (!stage.path.toLowerCase().startsWith(
    '${root.path}${Platform.pathSeparator}'.toLowerCase(),
  )) {
    throw StateError('Cartella di aggiornamento non valida');
  }
  try {
    final zip = File('${stage.path}/package.zip');
    final response = await _download(client, release.uri);
    final output = zip.openWrite();
    var received = 0;
    try {
      await for (final chunk in response.timeout(const Duration(seconds: 25))) {
        received += chunk.length;
        if (received > release.bytes)
          throw const FormatException('Pacchetto troppo grande');
        output.add(chunk);
      }
    } finally {
      await output.close();
    }
    if (received != release.bytes ||
        (await sha256.bind(zip.openRead()).first).toString() !=
            release.sha256) {
      throw const FormatException('SHA-256 del pacchetto non corrisponde');
    }
    final zipPath = zip.path;
    final payload = Directory('${stage.path}/runtime')..createSync();
    final destination = payload.path;
    await Isolate.run(
      () => extractOculumRlArchive(zipPath, destination, edition),
    );
    await File('$destination/$_ready').writeAsString(
      jsonEncode({
        'version': '${release.version}',
        'edition': edition.name,
        'sha256': release.sha256,
      }),
      flush: true,
    );
    final installPath = '${root.path}/${release.version}';
    try {
      await payload.rename(installPath);
    } on FileSystemException {
      if (!_prepared(Directory(installPath), release.version, edition)) rethrow;
    }
  } finally {
    await stage.delete(recursive: true);
  }
}

final _windowsIllegal = RegExp(r'[<>:"|?*\x00-\x1f]');
final _windowsReserved = RegExp(
  r'^(con|prn|aux|nul|com[1-9]|lpt[1-9])(?:\.|$)',
  caseSensitive: false,
);

void extractOculumRlArchive(
  String zip,
  String destination,
  OculumRlEdition edition,
) {
  final input = InputFileStream(zip);
  try {
    final archive = ZipDecoder().decodeStream(input);
    try {
      var total = 0;
      final names = <String>{};
      if (archive.length > 4000)
        throw const FormatException('Troppi file nel pacchetto');
      final entries = <(ArchiveFile, String)>[];
      for (final entry in archive) {
        final name = entry.name
            .replaceAll(r'\', '/')
            .replaceFirst(RegExp(r'/$'), '');
        final segments = name.split('/');
        if (entry.isSymbolicLink ||
            !names.add(name.toLowerCase()) ||
            segments.any(
              (part) =>
                  part.isEmpty ||
                  part == '.' ||
                  part == '..' ||
                  part.endsWith('.') ||
                  part.endsWith(' ') ||
                  _windowsIllegal.hasMatch(part) ||
                  _windowsReserved.hasMatch(part),
            )) {
          throw const FormatException('Percorso di archivio non valido');
        }
        total += entry.size;
        if (entry.size < 0 || total > 768 * 1024 * 1024) {
          throw const FormatException('Contenuto estratto troppo grande');
        }
        entries.add((entry, '$destination/$name'));
      }
      for (final (entry, target) in entries) {
        if (entry.isDirectory) {
          Directory(target).createSync(recursive: true);
        } else {
          File(target).parent.createSync(recursive: true);
          final writer = OutputFileStream(target);
          try {
            entry.writeContent(writer);
          } finally {
            writer.closeSync();
          }
          if (File(target).lengthSync() != entry.size)
            throw const FormatException('File incompleto');
        }
      }
      if (!_runtimeReady(Directory(destination), edition)) {
        throw const FormatException(
          'Runtime Windows incompleto o edizione errata',
        );
      }
    } finally {
      archive.clearSync();
    }
  } finally {
    input.closeSync();
  }
}

Future<bool> startOculumRlUpdate(
  OculumRlVersion version,
  OculumRlEdition edition,
) async {
  if (!supportsOculumRlUpdates) return false;
  final root = await _updateRoot(edition);
  final folder = Directory('${root.path}/$version');
  if (!_prepared(folder, version, edition)) return false;
  final exe = File('${folder.path}/${edition.executable}');
  if (exe.resolveSymbolicLinksSync().toLowerCase() ==
      Platform.resolvedExecutable.toLowerCase())
    return false;
  final random = Random.secure();
  final nonce = List.generate(
    12,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
  final ack = File('${folder.path}/.ack-$nonce');
  await Process.start(
    exe.path,
    const [],
    workingDirectory: folder.path,
    environment: {_ackVariable: nonce},
    mode: ProcessStartMode.detached,
  );
  for (var attempt = 0; attempt < 60; attempt++) {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (await ack.exists()) {
      await ack.delete();
      return true;
    }
  }
  return false;
}

void acknowledgeOculumRlUpdate() {
  if (!supportsOculumRlUpdates) return;
  final nonce = Platform.environment[_ackVariable];
  if (nonce == null || !_noncePattern.hasMatch(nonce)) return;
  final folder = File(Platform.resolvedExecutable).parent;
  if (!File('${folder.path}/$_ready').existsSync()) return;
  try {
    File('${folder.path}/.ack-$nonce').writeAsStringSync('ready', flush: true);
  } on FileSystemException {
    // The original process remains open if acknowledgement cannot be written.
  }
}

void exitForOculumRlUpdate() => exit(0);
