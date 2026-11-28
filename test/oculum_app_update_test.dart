import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:oculum/services/oculum_app_update.dart';

void main() {
  const old = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
  const newer = 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
  String release({
    String commit = newer,
    String hash =
        'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
  }) => jsonEncode({
    'draft': false,
    'prerelease': false,
    'body':
        '<!-- OCULUM_DOWNLOADS: ${jsonEncode({
          '1': {
            'workflow': 'Build distribution',
            'commit': commit,
            'runId': 123,
            'artifacts': [
              for (final name in ['Oculum-Windows', 'Oculum-Test-Windows', 'Oculum-Android', 'Oculum-macOS', 'Oculum-Linux']) {'name': name, 'bytes': 100, 'sha256': 'sha256:$hash', 'url': 'https://github.com/Mich369/Oculum/releases/download/oculum-build-123/$name.zip'},
            ],
          },
        })} -->',
  });
  test(
    'Android updater keeps APK identity when the AAB download comes first',
    () async {
      final payload = jsonDecode(release()) as Map<String, dynamic>;
      final catalog =
          jsonDecode(
                (payload['body'] as String)
                    .split('<!-- OCULUM_DOWNLOADS:')
                    .last
                    .split(' -->')
                    .first,
              )
              as Map;
      final group = catalog['1'] as Map;
      (group['artifacts'] as List).insert(0, {
        'name': 'Oculum-Android-AAB',
        'bytes': 999,
        'sha256': 'sha256:${'d' * 64}',
        'url':
            'https://github.com/Mich369/Oculum/releases/download/oculum-build-123/Oculum-Android-AAB.zip',
      });
      payload['body'] = '<!-- OCULUM_DOWNLOADS:${jsonEncode(catalog)} -->';
      final client = MockClient(
        (request) async => http.Response(
          request.url.path.contains('/compare/')
              ? jsonEncode({'status': 'ahead'})
              : jsonEncode(payload),
          200,
        ),
      );
      addTearDown(client.close);
      final update = await oculumCheckAppUpdate(
        client,
        'Oculum-Android',
        currentCommit: old,
      );
      expect(update!.url, endsWith('/Oculum-Android.zip'));
      expect(update.bytes, 100);
      expect(update.commit, newer);
    },
  );
  test(
    'only a verified descendant is offered, and Test retains its edition',
    () async {
      final client = MockClient(
        (r) async => http.Response(
          r.url.path.contains('/compare/')
              ? jsonEncode({'status': 'ahead'})
              : release(),
          200,
        ),
      );
      final result = await oculumCheckAppUpdate(
        client,
        'Oculum-Test-Windows',
        currentCommit: old,
      );
      expect(result!.url, contains('Oculum-Test-Windows.zip'));
      expect(result.commit, newer);
      expect(result.sha256.length, 64);
    },
  );
  test(
    'incremental manifest and runtime must match the Windows edition',
    () async {
      const base =
          'https://github.com/Mich369/Oculum/releases/download/oculum-build-123';
      final releaseJson = jsonDecode(release()) as Map;
      final catalog =
          jsonDecode(
                (releaseJson['body'] as String)
                    .split('OCULUM_DOWNLOADS:')
                    .last
                    .split(' -->')
                    .first,
              )
              as Map;
      final group = catalog['1'] as Map;
      (group['artifacts'] as List).addAll([
        for (final edition in ['Oculum-Windows', 'Oculum-Test-Windows'])
          {
            'name': '$edition-Folder',
            'bytes': 100,
            'sha256': 'sha256:${'c' * 64}',
            'url': '$base/$edition-Folder.zip',
          },
      ]);
      group['incremental'] = [
        {
          'artifact': 'Oculum-Test-Windows',
          'edition': 'test',
          'bytes': 8,
          'sha256': 'sha256:${'d' * 64}',
          'url': '$base/Oculum-Test-Windows-Incrementale.json',
        },
      ];
      releaseJson['body'] = '<!-- OCULUM_DOWNLOADS:${jsonEncode(catalog)} -->';
      final client = MockClient(
        (request) async => http.Response(
          request.url.path.contains('/compare/')
              ? '{"status":"ahead"}'
              : jsonEncode(releaseJson),
          200,
        ),
      );
      addTearDown(client.close);
      final testUpdate = await oculumCheckAppUpdate(
        client,
        'Oculum-Test-Windows',
        currentCommit: old,
      );
      final normal = await oculumCheckAppUpdate(
        client,
        'Oculum-Windows',
        currentCommit: old,
      );
      expect(testUpdate!.incremental!.edition, 'test');
      expect(testUpdate.incremental!.bytes, 8);
      expect(
        testUpdate.incremental!.packageUrl,
        '$base/Oculum-Test-Windows-Folder.zip',
      );
      expect(normal!.incremental, isNull);
      (group['incremental'] as List).single['url'] =
          '$base/Oculum-Windows-Incrementale.json';
      releaseJson['body'] = '<!-- OCULUM_DOWNLOADS:${jsonEncode(catalog)} -->';
      final fallback = await oculumCheckAppUpdate(
        client,
        'Oculum-Test-Windows',
        currentCommit: old,
      );
      expect(fallback!.url, '$base/Oculum-Test-Windows.zip');
      expect(fallback.incremental, isNull);
    },
  );
  test(
    'historical index must belong to the installed commit and edition',
    () async {
      const filename = 'Oculum-Test-Windows-Incrementale.json';
      const url =
          'https://github.com/Mich369/Oculum/releases/download/oculum-build-20/$filename';
      var releaseCommit = old;
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/runs')) {
          expect(request.url.queryParameters['head_sha'], old);
          return http.Response(
            jsonEncode({
              'workflow_runs': [
                {
                  'id': 20,
                  'head_sha': old,
                  'head_branch': 'main',
                  'conclusion': 'success',
                },
              ],
            }),
            200,
          );
        }
        return http.Response(
          jsonEncode({
            'target_commitish': releaseCommit,
            'draft': false,
            'assets': [
              {
                'name': filename,
                'browser_download_url': url,
                'size': 42,
                'digest': 'sha256:${'e' * 64}',
                'state': 'uploaded',
              },
            ],
          }),
          200,
        );
      });
      addTearDown(client.close);
      expect(
        await oculumFindInstalledWindowsManifest(
          client,
          'test',
          currentCommit: old,
        ),
        (url: url, bytes: 42, sha256: 'e' * 64),
      );
      expect(
        await oculumFindInstalledWindowsManifest(
          client,
          'normal',
          currentCommit: old,
        ),
        isNull,
      );
      releaseCommit = newer;
      expect(
        await oculumFindInstalledWindowsManifest(
          client,
          'test',
          currentCommit: old,
        ),
        isNull,
      );
    },
  );
  for (final status in ['identical', 'behind', 'diverged']) {
    test('never replace when comparison is $status', () async {
      final client = MockClient(
        (r) async => http.Response(
          r.url.path.contains('/compare/')
              ? jsonEncode({'status': status})
              : release(),
          200,
        ),
      );
      expect(
        await oculumCheckAppUpdate(
          client,
          'Oculum-Windows',
          currentCommit: old,
        ),
        isNull,
      );
    });
  }
  test(
    'same published source still checks whether main has newer downloads',
    () async {
      var calls = 0;
      final client = MockClient((r) async {
        calls++;
        return http.Response(release(commit: old), 200);
      });
      expect(
        await oculumCheckAppUpdate(
          client,
          'Oculum-Windows',
          currentCommit: old,
        ),
        isNull,
      );
      expect(calls, 2);
    },
  );
  test(
    'does not report latest while main is ahead of published downloads',
    () async {
      const main = 'dddddddddddddddddddddddddddddddddddddddd';
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/branches/main')) {
          return http.Response(
            jsonEncode({
              'commit': {'sha': main},
            }),
            200,
          );
        }
        if (request.url.path.contains('/compare/')) {
          return http.Response(
            jsonEncode({
              'status': request.url.path.endsWith('$old...$main')
                  ? 'ahead'
                  : 'behind',
            }),
            200,
          );
        }
        return http.Response(release(), 200);
      });

      await expectLater(
        oculumCheckAppUpdate(client, 'Oculum-Windows', currentCommit: old),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('download verificati non sono ancora stati aggiornati'),
          ),
        ),
      );
    },
  );
  test('reject unknown identity and invalid hash', () async {
    final client = MockClient(
      (r) async => http.Response(
        r.url.path.contains('/compare/')
            ? jsonEncode({'status': 'ahead'})
            : release(hash: 'bad'),
        200,
      ),
    );
    expect(
      () => oculumCheckAppUpdate(client, 'Oculum-Windows', currentCommit: ''),
      throwsStateError,
    );
    expect(
      await oculumCheckAppUpdate(client, 'Oculum-Windows', currentCommit: old),
      isNull,
    );
  });
}
