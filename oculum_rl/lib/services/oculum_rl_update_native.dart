import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

import 'oculum_rl_release.dart';
import 'oculum_rl_update_delta.dart';

bool get supportsOculumRlUpdates => Platform.isWindows;

const _ackVariable = 'OCULUM_RL_UPDATE_ACK';
const _ready = '.oculum-rl-update.json';
final _noncePattern = RegExp(r'^[0-9a-f]{24}$');

Future<Directory> _updateRoot(OculumRlEdition edition) async {
  var ancestor = File(Platform.resolvedExecutable).parent;
  for (var depth = 0; depth < 7; depth++) {
    if (File('${ancestor.path}/VERSIONE-ATTIVA.json').existsSync() &&
        File('${ancestor.path}/pubspec.yaml').existsSync()) {
      try {
        final portable = await Directory(
          '${ancestor.path}/build/updates-v1/${edition.name}',
        ).create(recursive: true);
        return Directory(await portable.resolveSymbolicLinks());
      } on FileSystemException {
        break;
      }
    }
    if (ancestor.path == ancestor.parent.path) break;
    ancestor = ancestor.parent;
  }
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
  OculumRlEdition edition, {
  void Function(OculumRlTransfer)? onTransfer,
}) async {
  if (!supportsOculumRlUpdates) return null;
  final staged = await findOculumRlUpdate(current, edition);
  final client = HttpClient()
    ..autoUncompress = false
    ..connectionTimeout = const Duration(seconds: 8);
  try {
    OculumRlRelease? available;
    try {
      final request = await client.getUrl(Uri.parse(oculumRlReleaseApi));
      request.headers
        ..set(HttpHeaders.acceptHeader, 'application/vnd.github+json')
        ..set(HttpHeaders.acceptEncodingHeader, 'identity')
        ..set(HttpHeaders.userAgentHeader, 'Oculum-RL-Updater');
      final response = await request.close().timeout(
        const Duration(seconds: 12),
      );
      if (response.statusCode != HttpStatus.ok) {
        throw const HttpException('GitHub non disponibile');
      }
      final body = await utf8.decoder
          .bind(response)
          .join()
          .timeout(const Duration(seconds: 15));
      available = selectOculumRlRelease(
        body,
        current: current,
        edition: edition,
      );
    } on Exception {
      if (staged != null) return staged;
      rethrow;
    }
    if (available == null ||
        (staged != null && staged.compareTo(available.version) >= 0)) {
      return staged;
    }

    final root = await _updateRoot(edition);
    final lock = await File('${root.path}/.install.lock')
        .open(mode: FileMode.append);
    try {
      await lock.lock(FileLock.exclusive);
      final alreadyPrepared = await findOculumRlUpdate(current, edition);
      if (alreadyPrepared != null &&
          alreadyPrepared.compareTo(available.version) >= 0) {
        return alreadyPrepared;
      }
      await stageOculumRlUpdate(
        root,
        available,
        edition,
        installed: File(Platform.resolvedExecutable).parent,
        fetch: (uri, {range}) =>
            fetchOculumRlUpdateAsset(client, uri, range: range),
        onTransfer: onTransfer,
      );
      return available.version;
    } finally {
      await lock.close();
    }
  } finally {
    client.close(force: true);
  }
}

Future<HttpClientResponse> fetchOculumRlUpdateAsset(
  HttpClient client,
  Uri uri, {
  (int first, int last)? range,
}) async {
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
    request.headers.set(HttpHeaders.acceptEncodingHeader, 'identity');
    if (range case (final first, final last)) {
      request.headers.set(HttpHeaders.rangeHeader, 'bytes=$first-$last');
    }
    final response = await request.close().timeout(const Duration(seconds: 18));
    if (response.statusCode == HttpStatus.ok ||
        (range != null && response.statusCode == HttpStatus.partialContent)) {
      return response;
    }
    final location = response.headers.value(HttpHeaders.locationHeader);
    if (!response.isRedirect || location == null)
      throw const HttpException('Pacchetto non disponibile');
    await response.drain<void>().timeout(const Duration(seconds: 10));
    uri = uri.resolve(location);
  }
  throw const HttpException('Troppi reindirizzamenti');
}

typedef OculumRlFetch = Future<HttpClientResponse> Function(
  Uri uri, {
  (int, int)? range,
});

Future<void> stageOculumRlUpdate(
  Directory stagingRoot,
  OculumRlRelease release,
  OculumRlEdition edition, {
  required Directory installed,
  required OculumRlFetch fetch,
  void Function(OculumRlTransfer)? onTransfer,
}) async {
  final root = Directory(await stagingRoot.resolveSymbolicLinks());
  final stage = Directory(
    await (await root.createTemp('download-')).resolveSymbolicLinks(),
  );
  final parent = stage.parent.path;
  if (Platform.isWindows
      ? parent.toLowerCase() != root.path.toLowerCase()
      : parent != root.path) {
    throw StateError('Cartella di aggiornamento non valida');
  }
  try {
    final payload = await Directory('${stage.path}/runtime').create();
    final destination = payload.path;
    if (release.index case final index?) {
      final response = await fetch(index.uri);
      final bytes = <int>[];
      await for (final chunk in response.timeout(const Duration(seconds: 15))) {
        if (bytes.length + chunk.length > index.bytes) {
          throw const FormatException('Indice di aggiornamento troppo grande');
        }
        bytes.addAll(chunk);
      }
      if (bytes.length != index.bytes ||
          sha256.convert(bytes).toString() != index.sha256) {
        throw const FormatException('SHA-256 dell’indice non corrisponde');
      }
      final files = readOculumRlUpdateIndex(
        utf8.decode(bytes),
        release,
        edition,
      );
      final plan = await planOculumRlUpdate(installed, files);
      onTransfer?.call(
        OculumRlTransfer(plan.downloadBytes, files: plan.changedFiles),
      );
      await writeOculumRlUpdateRuntime(
        installed,
        payload,
        plan,
        archiveBytes: release.bytes,
        requestRange: (first, last) => fetch(release.uri, range: (first, last)),
      );
      if (!_runtimeReady(payload, edition)) {
        throw const FormatException(
          'Runtime Windows incompleto o edizione errata',
        );
      }
    } else {
      onTransfer?.call(OculumRlTransfer(release.bytes));
      await _downloadFull(fetch, stage, payload, release, edition);
    }
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

Future<void> _downloadFull(
  OculumRlFetch fetch,
  Directory stage,
  Directory payload,
  OculumRlRelease release,
  OculumRlEdition edition,
) async {
  final zip = File('${stage.path}/package.zip');
  final response = await fetch(release.uri);
  final output = await zip.open(mode: FileMode.write);
  var received = 0;
  try {
    await for (final chunk in response.timeout(const Duration(seconds: 25))) {
      received += chunk.length;
      if (received > release.bytes) {
        throw const FormatException('Pacchetto troppo grande');
      }
      await output.writeFrom(chunk);
    }
  } finally {
    await output.close();
  }
  if (received != release.bytes ||
      (await sha256.bind(zip.openRead()).first).toString() != release.sha256) {
    throw const FormatException('SHA-256 del pacchetto non corrisponde');
  }
  final zipPath = zip.path;
  final destination = payload.path;
  await Isolate.run(
    () => extractOculumRlArchive(zipPath, destination, edition),
  );
}

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
      if (archive.length > oculumRlMaxRuntimeFiles)
        throw const FormatException('Troppi file nel pacchetto');
      final entries = <(ArchiveFile, String)>[];
      for (final entry in archive) {
        final name = entry.name
            .replaceAll(r'\', '/')
            .replaceFirst(RegExp(r'/$'), '');
        if (entry.isSymbolicLink ||
            !names.add(name.toLowerCase()) ||
            !oculumRlRuntimePathIsValid(name)) {
          throw const FormatException('Percorso di archivio non valido');
        }
        total += entry.size;
        if (entry.size < 0 || total > oculumRlMaxRuntimeBytes) {
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
