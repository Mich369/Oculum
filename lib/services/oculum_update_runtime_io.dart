import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:pointycastle/digests/sha256.dart';

/// Streams the file in a worker isolate: neither the archive nor its SHA-256
/// computation occupies the UI isolate or requires a whole-file allocation.
Future<void> oculumVerifyUpdateArchive(
  String path, {
  required int expectedBytes,
  required String expectedSha256,
  void Function(int received, int total)? onProgress,
}) async {
  final messages = ReceivePort();
  Isolate? worker;
  final result = Completer<void>();
  final subscription = messages.listen((message) {
    if (message is! Map || result.isCompleted) return;
    if (message['bytes'] is int) {
      onProgress?.call(message['bytes'] as int, expectedBytes);
    } else if (message['hash'] is String) {
      if (message['length'] == expectedBytes &&
          message['hash'] == expectedSha256.toLowerCase()) {
        result.complete();
      } else {
        result.completeError(StateError('Integrità del pacchetto non valida.'));
      }
    } else if (message.containsKey('error')) {
      result.completeError(StateError('Verifica del pacchetto non riuscita.'));
    }
  });
  try {
    worker = await Isolate.spawn(_hashUpdateFile, [path, messages.sendPort]);
    await result.future.timeout(const Duration(minutes: 10));
  } finally {
    worker?.kill(priority: Isolate.immediate);
    await subscription.cancel();
    messages.close();
  }
}

Future<void> _hashUpdateFile(List<Object> arguments) async {
  final reply = arguments[1] as SendPort;
  try {
    final digest = SHA256Digest();
    var received = 0;
    final clock = Stopwatch()..start();
    var lastProgress = -100;
    await for (final chunk in File(arguments[0] as String).openRead()) {
      final bytes = chunk is Uint8List ? chunk : Uint8List.fromList(chunk);
      digest.update(bytes, 0, bytes.length);
      received += bytes.length;
      if (clock.elapsedMilliseconds - lastProgress >= 100) {
        reply.send({'bytes': received});
        lastProgress = clock.elapsedMilliseconds;
      }
    }
    final hash = Uint8List(digest.digestSize);
    digest.doFinal(hash, 0);
    reply.send({
      'hash': hash.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(),
      'length': received,
    });
  } catch (_) {
    reply.send({'error': true});
  }
}

bool _editionIsValid(String edition) =>
    edition == 'normal' || edition == 'test';

Future<Directory?> _updateWork(String cacheRoot, String work) async {
  final root = await Directory(cacheRoot).resolveSymbolicLinks();
  final directory = Directory(work);
  if (!await directory.exists()) return null;
  final resolved = await directory.resolveSymbolicLinks();
  final parent = await directory.parent.resolveSymbolicLinks();
  final insensitive = Platform.isWindows;
  if ((insensitive ? parent.toLowerCase() : parent) !=
      (insensitive ? root.toLowerCase() : root)) {
    return null;
  }
  // A linked directory must never redirect an acknowledgement or status read.
  if (await FileSystemEntity.type(work, followLinks: false) !=
      FileSystemEntityType.directory) {
    return null;
  }
  if (!RegExp(
    r'^oculum-update-[0-9]+-[a-zA-Z0-9_-]+$',
  ).hasMatch(directory.uri.pathSegments.where((s) => s.isNotEmpty).last)) {
    return null;
  }
  return Directory(resolved);
}

Future<bool> oculumWriteUpdateStartupAck({
  required String cacheRoot,
  required String commit,
  required String edition,
  Map<String, String>? environment,
}) async {
  if (!Platform.isWindows ||
      !_editionIsValid(edition) ||
      !RegExp(r'^[a-f0-9]{40}$').hasMatch(commit)) {
    return false;
  }
  try {
    final env = environment ?? Platform.environment;
    final path = env['OCULUM_UPDATE_ACK_PATH'] ?? '';
    final token = env['OCULUM_UPDATE_ACK_TOKEN'] ?? '';
    if (!RegExp(r'^[a-fA-F0-9]{32}$').hasMatch(token)) return false;
    final ack = File(path);
    if (ack.uri.pathSegments.last != 'startup-ack.json') return false;
    final work = await _updateWork(cacheRoot, ack.parent.path);
    if (work == null ||
        await FileSystemEntity.type(path, followLinks: false) !=
            FileSystemEntityType.notFound) {
      return false;
    }
    // The helper also checks the compiled commit, edition, token and live PID.
    await ack.writeAsString(
      jsonEncode({'token': token, 'commit': commit, 'edition': edition}),
      flush: true,
    );
    return true;
  } catch (_) {
    // Optional update confirmation cannot block local startup or saves.
    return false;
  }
}

/// Reads only the latest attempt for this edition and returns safe player text.
/// Helper diagnostics stay on disk; local paths are never shown in the UI.
Future<String?> oculumReadUpdateFailure({
  required String cacheRoot,
  required String edition,
  DateTime? now,
}) async {
  if (!_editionIsValid(edition)) return null;
  try {
    final pointer = File('$cacheRoot/oculum-update-latest-$edition.json');
    if (!await pointer.exists() || await pointer.length() > 16384) return null;
    final latest = jsonDecode(await pointer.readAsString());
    if (latest is! Map || latest['edition'] != edition) return null;
    final work = await _updateWork(cacheRoot, '${latest['work']}');
    if (work == null) return null;
    final helper = File('${work.path}/update-status.json');
    final frontend = File('${work.path}/frontend-status.json');
    final hasHelperStatus = await helper.exists();
    final statusFile = hasHelperStatus ? helper : frontend;
    if (!await statusFile.exists() || await statusFile.length() > 65536) {
      return null;
    }
    final status = jsonDecode(
      (await statusFile.readAsString()).replaceFirst('\uFEFF', ''),
    );
    if (status is! Map || status['edition'] != edition) return null;
    if (!hasHelperStatus) {
      // The existing macOS/Linux helper records its outcome in these files.
      // A completed Python update must not later look like an interrupted
      // frontend handoff. Windows' richer JSON result always takes precedence.
      if (await File('${work.path}/error.txt').exists()) {
        return 'L’ultimo aggiornamento non è riuscito. I salvataggi sono conservati; puoi riprovare dal pulsante Aggiorna.';
      }
      final legacyResult = File('${work.path}/result.txt');
      if (await legacyResult.exists() &&
          await legacyResult.length() <= 1024 &&
          (await legacyResult.readAsString()).trim() == 'success') {
        return null;
      }
    }
    final state = '${status['state']}';
    if (state == 'success' || state == 'installer_opened') return null;
    final notice = switch (state) {
      'error' || 'frontend_error' =>
        'L’ultimo aggiornamento non è riuscito. I salvataggi sono conservati; puoi riprovare dal pulsante Aggiorna.',
      'unconfirmed' =>
        'L’avvio dell’ultimo aggiornamento non è stato confermato. Il backup è conservato; verifica la versione e riprova se necessario.',
      _ => null,
    };
    if (notice != null) return notice;
    final updated = DateTime.tryParse('${status['updatedAtUtc']}');
    if (updated != null &&
        (now ?? DateTime.now()).toUtc().difference(updated.toUtc()) >
            const Duration(minutes: 3)) {
      return 'L’ultimo aggiornamento è stato interrotto prima della conferma. Puoi riprovare dal pulsante Aggiorna.';
    }
  } catch (_) {
    // Corrupt or obsolete cache entries must not interrupt startup.
  }
  return null;
}
