import 'dart:convert';
import 'package:http/http.dart' as http;

const oculumBuildDownloadsUrl =
    'https://github.com/Mich369/Oculum/releases/tag/oculum-downloads';
const _requiredArtifactNames = <String>[
  'Oculum-macOS',
  'Oculum-Windows',
  'Oculum-Test-Windows',
  'Oculum-Linux',
  'Oculum-Android',
];

const _extraArtifactNames = <String>[
  'Oculum-Web',
  'Oculum-iOS-unsigned',
  'Oculum-UI-Catture',
  'Oculum-Windows-Folders',
  'Oculum-Windows-Folder',
  'Oculum-Test-Windows-Folder',
];

const oculumCumulativeUpdateLogUrl =
    'https://github.com/Mich369/Oculum/blob/main/docs/REGISTRO_AGGIORNAMENTI.md';

class OculumDownloadArtifact {
  const OculumDownloadArtifact(this.name, this.bytes, this.url);
  final String name;
  final int bytes;
  final Uri url;
}

/// Public metadata only: downloading happens on GitHub, never through Supabase.
Future<List<OculumDownloadArtifact>> oculumFetchDownloadArtifacts(
  http.Client client,
) async {
  const api =
      'https://api.github.com/repos/Mich369/Oculum/releases/tags/oculum-downloads';
  Future<Map<String, dynamic>> read(String url) async {
    final response = await client
        .get(
          Uri.parse(url),
          headers: const {'Accept': 'application/vnd.github+json'},
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 404) return <String, dynamic>{};
    if (response.statusCode != 200) {
      throw StateError(
        'Download metadata unavailable (${response.statusCode})',
      );
    }
    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }

  final release = await read(api);
  if (release['draft'] != false) return const [];
  final body = '${release['body'] ?? ''}';
  const marker = '<!-- OCULUM_DOWNLOADS:';
  if (!body.contains(marker)) return const [];
  final encoded = body.split(marker).last.split(' -->').first;
  final catalog = jsonDecode(encoded);
  if (catalog is! Map) return const [];
  final groups = catalog.values.whereType<Map>().where(
    (group) => group['workflow'] == 'Build distribution',
  );
  for (final group in groups) {
    final runId = int.tryParse('${group['runId']}');
    final commit = '${group['commit'] ?? ''}';
    if (runId == null ||
        runId <= 0 ||
        !RegExp(r'^[a-f0-9]{40}$').hasMatch(commit)) {
      continue;
    }
    final found = <String, OculumDownloadArtifact>{};
    for (final artifact
        in (group['artifacts'] as List? ?? const []).whereType<Map>()) {
      final name = '${artifact['name'] ?? ''}';
      if (!_requiredArtifactNames.contains(name) &&
          !_extraArtifactNames.contains(name)) {
        continue;
      }
      final expectedUrl =
          'https://github.com/Mich369/Oculum/releases/download/oculum-build-$runId/$name.zip';
      if (artifact['url'] != expectedUrl) continue;
      found[name] = OculumDownloadArtifact(
        name,
        int.tryParse('${artifact['bytes']}') ?? 0,
        Uri.parse(expectedUrl),
      );
    }
    if (_requiredArtifactNames.every(found.containsKey)) {
      return [
        for (final name in [..._requiredArtifactNames, ..._extraArtifactNames])
          if (found.containsKey(name)) found[name]!,
      ];
    }
  }

  // Do not expose a partial release while the publisher is still assembling
  // the complete cross-platform set.
  return const [];
}
