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
  test('same source avoids even a comparison request', () async {
    var calls = 0;
    final client = MockClient((r) async {
      calls++;
      return http.Response(release(commit: old), 200);
    });
    expect(
      await oculumCheckAppUpdate(client, 'Oculum-Windows', currentCommit: old),
      isNull,
    );
    expect(calls, 1);
  });
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
