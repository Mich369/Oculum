import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:oculum/services/oculum_download_artifacts.dart';

void main() {
  test(
    'public downloads only use trusted release assets without credentials',
    () async {
      const names = [
        'Oculum-macOS',
        'Oculum-Windows',
        'Oculum-Test-Windows',
        'Oculum-Linux',
        'Oculum-Android',
      ];
      final group = {
        'runId': 123,
        'commit': 'a' * 40,
        'workflow': 'Build distribution',
        'artifacts': [
          for (final name in names)
            {
              'name': name,
              'bytes': 200,
              'url':
                  'https://github.com/Mich369/Oculum/releases/download/oculum-build-123/$name.zip',
            },
          {
            'name': 'Oculum-iOS-unsigned',
            'bytes': 200,
            'url':
                'https://github.com/Mich369/Oculum/releases/download/oculum-build-123/Oculum-iOS-unsigned.zip',
          },
          for (final name in [
            'Oculum-Windows-Folder',
            'Oculum-Test-Windows-Folder',
          ])
            {
              'name': name,
              'bytes': 200,
              'url':
                  'https://github.com/Mich369/Oculum/releases/download/oculum-build-123/$name.zip',
            },
          {
            'name': 'Oculum-Android',
            'bytes': 200,
            'url': 'https://malicious.example/download',
          },
        ],
      };
      var calls = 0;
      final client = MockClient((request) async {
        calls++;
        expect(request.url.host, 'api.github.com');
        expect(request.headers.containsKey('authorization'), isFalse);
        return http.Response(
          jsonEncode({
            'draft': false,
            'body': '<!-- OCULUM_DOWNLOADS:${jsonEncode({'1': group})} -->',
          }),
          200,
        );
      });
      addTearDown(client.close);
      final result = await oculumFetchDownloadArtifacts(client);
      expect(calls, 1);
      expect(result, hasLength(8));
      expect(result.map((item) => item.name), [
        ...names,
        'Oculum-iOS-unsigned',
        'Oculum-Windows-Folder',
        'Oculum-Test-Windows-Folder',
      ]);
      expect(result.first.url.path, contains('/releases/download/'));
      expect(result.every((item) => item.bytes == 200), isTrue);
    },
  );

  test(
    'a partial publication stays in maintenance until all five platforms exist',
    () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'draft': false,
            'body':
                '<!-- OCULUM_DOWNLOADS:${jsonEncode({
                  '1': {
                    'runId': 123,
                    'commit': 'a' * 40,
                    'workflow': 'Build distribution',
                    'artifacts': [
                      {'name': 'Oculum-Windows', 'bytes': 200, 'url': 'https://github.com/Mich369/Oculum/releases/download/oculum-build-123/Oculum-Windows.zip'},
                    ],
                  },
                })} -->',
          }),
          200,
        ),
      );
      addTearDown(client.close);
      expect(await oculumFetchDownloadArtifacts(client), isEmpty);
    },
  );

  test('an API error is surfaced without returning a stale download', () async {
    final client = MockClient((_) async => http.Response('{}', 403));
    addTearDown(client.close);
    await expectLater(oculumFetchDownloadArtifacts(client), throwsStateError);
  });
}
