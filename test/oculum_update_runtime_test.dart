import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/services/oculum_update_runtime.dart';

void main() {
  late Directory cache;
  const commit = 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
  setUp(() async {
    cache = await Directory.systemTemp.createTemp('oculum updater test ');
  });
  tearDown(() async {
    await cache.delete(recursive: true);
  });

  test(
    'stream verification accepts the exact file and reports progress',
    () async {
      final archive = await File(
        '${cache.path}/release.zip',
      ).writeAsString('abc');
      final progress = <int>[];
      await oculumVerifyUpdateArchive(
        archive.path,
        expectedBytes: 3,
        expectedSha256:
            'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
        onProgress: (bytes, _) => progress.add(bytes),
      );
      expect(progress, contains(3));
    },
  );

  test('stream verification rejects altered contents and length', () async {
    final archive = await File(
      '${cache.path}/release.zip',
    ).writeAsString('abc');
    for (final expectedLength in [3, 4]) {
      await expectLater(
        oculumVerifyUpdateArchive(
          archive.path,
          expectedBytes: expectedLength,
          expectedSha256: '0' * 64,
        ),
        throwsStateError,
      );
    }
  });

  test(
    'startup acknowledgement is limited to a valid attempt in cache',
    () async {
      if (!Platform.isWindows) return;
      final work = await Directory(
        '${cache.path}/oculum-update-123-attempt',
      ).create();
      final path = '${work.path}/startup-ack.json';
      final environment = {
        'OCULUM_UPDATE_ACK_PATH': path,
        'OCULUM_UPDATE_ACK_TOKEN': 'a' * 32,
      };
      expect(
        await oculumWriteUpdateStartupAck(
          cacheRoot: cache.path,
          commit: commit,
          edition: 'test',
          environment: environment,
        ),
        isTrue,
      );
      expect(jsonDecode(await File(path).readAsString()), {
        'token': 'a' * 32,
        'commit': commit,
        'edition': 'test',
      });
      // Neither a duplicate ACK nor an environment path outside this cache is
      // allowed to overwrite another file during app startup.
      expect(
        await oculumWriteUpdateStartupAck(
          cacheRoot: cache.path,
          commit: commit,
          edition: 'test',
          environment: environment,
        ),
        isFalse,
      );
      expect(
        await oculumWriteUpdateStartupAck(
          cacheRoot: work.path,
          commit: commit,
          edition: 'normal',
          environment: environment,
        ),
        isFalse,
      );
    },
  );

  Future<void> writeStatus(String state, {String edition = 'normal'}) async {
    final work = await Directory(
      '${cache.path}/oculum-update-123-$edition',
    ).create();
    await File(
      '${cache.path}/oculum-update-latest-$edition.json',
    ).writeAsString(jsonEncode({'work': work.path, 'edition': edition}));
    await File('${work.path}/update-status.json').writeAsString(
      jsonEncode({
        'state': state,
        'edition': edition,
        'message': r'Private diagnostic C:\Users\player\Oculum',
        'updatedAtUtc': DateTime.now().toUtc().toIso8601String(),
      }),
    );
  }

  test(
    'startup failure text does not expose helper diagnostics or another edition',
    () async {
      await writeStatus('error', edition: 'test');
      expect(
        await oculumReadUpdateFailure(cacheRoot: cache.path, edition: 'normal'),
        isNull,
      );
      final notice = await oculumReadUpdateFailure(
        cacheRoot: cache.path,
        edition: 'test',
      );
      expect(notice, contains('non è riuscito'));
      expect(notice, isNot(contains('C:')));
      expect(notice, isNot(contains('player')));
    },
  );

  test('unconfirmed startup is reported while success stays silent', () async {
    await writeStatus('unconfirmed');
    expect(
      await oculumReadUpdateFailure(cacheRoot: cache.path, edition: 'normal'),
      contains('non è stato confermato'),
    );
    await writeStatus('success');
    expect(
      await oculumReadUpdateFailure(cacheRoot: cache.path, edition: 'normal'),
      isNull,
    );
  });

  Future<Directory> writeLegacyStatus({String edition = 'normal'}) async {
    final work = await Directory(
      '${cache.path}/oculum-update-123-$edition',
    ).create();
    await File(
      '${cache.path}/oculum-update-latest-$edition.json',
    ).writeAsString(jsonEncode({'work': work.path, 'edition': edition}));
    await File('${work.path}/frontend-status.json').writeAsString(
      jsonEncode({
        'state': 'handoff',
        'edition': edition,
        'updatedAtUtc': DateTime.now()
            .toUtc()
            .subtract(const Duration(minutes: 5))
            .toIso8601String(),
      }),
    );
    return work;
  }

  test(
    'legacy Python success stays silent after the frontend becomes stale',
    () async {
      final work = await writeLegacyStatus();
      await File('${work.path}/result.txt').writeAsString('success\n');
      expect(
        await oculumReadUpdateFailure(cacheRoot: cache.path, edition: 'normal'),
        isNull,
      );
    },
  );

  test(
    'legacy Python error is safe and isolated from the other edition',
    () async {
      final work = await writeLegacyStatus(edition: 'test');
      await File(
        '${work.path}/error.txt',
      ).writeAsString(r'Private diagnostic C:\Users\player\Oculum');
      expect(
        await oculumReadUpdateFailure(cacheRoot: cache.path, edition: 'normal'),
        isNull,
      );
      final notice = await oculumReadUpdateFailure(
        cacheRoot: cache.path,
        edition: 'test',
      );
      expect(notice, contains('non è riuscito'));
      expect(notice, isNot(contains('C:')));
      expect(notice, isNot(contains('player')));
    },
  );

  test(
    'helper JSON unconfirmed outcome takes precedence over legacy success',
    () async {
      final work = await writeLegacyStatus();
      await File('${work.path}/result.txt').writeAsString('success');
      await writeStatus('unconfirmed');
      expect(
        await oculumReadUpdateFailure(cacheRoot: cache.path, edition: 'normal'),
        contains('non è stato confermato'),
      );
    },
  );
}
