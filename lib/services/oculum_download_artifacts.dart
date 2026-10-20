import 'dart:convert';
import 'package:http/http.dart' as http;

const oculumBuildDownloadsUrl =
    'https://github.com/Mich369/Oculum/releases/tag/oculum-downloads';

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
  final artifacts = <OculumDownloadArtifact>[];
  for (final group in catalog.values.whereType<Map>()) {
    final runId = int.tryParse('${group['runId']}');
    final commit = '${group['commit'] ?? ''}';
    if (runId == null ||
        runId <= 0 ||
        !RegExp(r'^[a-f0-9]{40}$').hasMatch(commit))
    {
      continue;
    }
    for (final artifact
        in (group['artifacts'] as List? ?? const []).whereType<Map>()) {
      final name = '${artifact['name'] ?? ''}';
      if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(name)) continue;
      final expectedUrl =
          'https://github.com/Mich369/Oculum/releases/download/oculum-build-$runId/$name.zip';
      if (artifact['url'] != expectedUrl) continue;
      artifacts.add(
        OculumDownloadArtifact(
          '$name · ${group['workflow']}',
          int.tryParse('${artifact['bytes']}') ?? 0,
          Uri.parse(expectedUrl),
        ),
      );
    }
  }
  artifacts.sort((a, b) => a.name.compareTo(b.name));
  return artifacts;
}
