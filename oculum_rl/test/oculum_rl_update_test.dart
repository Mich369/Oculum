import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum_rl/services/oculum_rl_release.dart';
import 'package:oculum_rl/services/oculum_rl_update_native.dart';

const releasePrefix = 'https://github.com/Mich369/Oculum/releases/download';

Map<String, Object> release(
  String tag, {
  bool draft = false,
  bool both = true,
  String host = releasePrefix,
}) => {
  'tag_name': tag,
  'draft': draft,
  'published_at': '2026-11-24T00:00:00Z',
  'assets': [
    for (final edition in OculumRlEdition.values)
      if (both || edition == OculumRlEdition.normal)
        {
          'name': edition.archive,
          'size': 500,
          'state': 'uploaded',
          'digest': 'sha256:${'a' * 64}',
          'browser_download_url': '$host/$tag/${edition.archive}',
        },
  ],
};

void main() {
  const current = OculumRlVersion(0, 4, 5);

  test(
    'selects a complete, newer RL release and the requested Windows edition',
    () {
      final json = jsonEncode([
        release('normal-app-v100.0.0'),
        release('oculum-rl-v0.5.0', both: false),
        release('oculum-rl-v0.9.0', draft: true),
        release('oculum-rl-v0.6.0', host: 'https://invalid.example/download'),
        release('oculum-rl-v0.4.10'),
        release('oculum-rl-v0.4.9'),
        release('oculum-rl-v0.4.4'),
      ]);
      for (final edition in OculumRlEdition.values) {
        final update = selectOculumRlRelease(
          json,
          current: current,
          edition: edition,
        );
        expect(update?.version.toString(), '0.4.10');
        expect(
          update?.uri.toString(),
          '$releasePrefix/oculum-rl-v0.4.10/${edition.archive}',
        );
        expect(update?.sha256, 'a' * 64);
      }
    },
  );

  test('an old release or an asset missing its hash cannot update', () {
    final corrupt = release('oculum-rl-v0.5.0');
    final entries = corrupt['assets']! as List<Map<String, Object>>;
    entries[0]['digest'] = '';
    final json = jsonEncode([release('oculum-rl-v0.4.5'), corrupt]);
    expect(
      selectOculumRlRelease(
        json,
        current: current,
        edition: OculumRlEdition.normal,
      ),
      isNull,
    );
  });

  test(
    'Windows runtime extracts from an archive with original paths',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'oculum-rl-update-test',
      );
      addTearDown(() => directory.delete(recursive: true));
      final zip = File('${directory.path}/game.zip');
      final archive = Archive();
      for (final name in [
        'Oculum RL.exe',
        'flutter_windows.dll',
        'data/icudtl.dat',
        'data/app.so',
      ]) {
        archive.addFile(ArchiveFile(name, 1, [42]));
      }
      await zip.writeAsBytes(ZipEncoder().encode(archive));
      final output = '${directory.path}/runtime';
      extractOculumRlArchive(zip.path, output, OculumRlEdition.normal);
      expect(File('$output/data/app.so').readAsBytesSync(), [42]);
      expect(
        () => extractOculumRlArchive(
          zip.path,
          '${directory.path}/test',
          OculumRlEdition.test,
        ),
        throwsFormatException,
      );
    },
  );

  test('paths outside the staging folder cannot be extracted', () async {
    final directory = await Directory.systemTemp.createTemp(
      'oculum-rl-update-path',
    );
    addTearDown(() => directory.delete(recursive: true));
    final zip = File('${directory.path}/game.zip');
    final archive = Archive()
      ..addFile(ArchiveFile('../outside.txt', 3, [1, 2, 3]));
    await zip.writeAsBytes(ZipEncoder().encode(archive));
    expect(
      () => extractOculumRlArchive(
        zip.path,
        '${directory.path}/runtime',
        OculumRlEdition.normal,
      ),
      throwsFormatException,
    );
    expect(File('${directory.path}/outside.txt').existsSync(), isFalse);
  });
}
