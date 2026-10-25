import 'dart:convert';
import 'package:http/http.dart' as http;

const oculumSourceCommit = String.fromEnvironment('OculumSourceCommit');

class OculumAppUpdate {
  const OculumAppUpdate({
    required this.commit,
    required this.url,
    required this.sha256,
    required this.bytes,
    required this.runId,
    this.changes = const [],
  });
  final String commit, url, sha256;
  final int bytes, runId;
  final List<String> changes;
}

Future<OculumAppUpdate?> oculumCheckAppUpdate(
  http.Client client,
  String artifact, {
  String currentCommit = oculumSourceCommit,
}) async {
  if (!RegExp(r'^[a-f0-9]{40}$').hasMatch(currentCommit)) {
    throw StateError(
      'Versione installata non identificabile: usa i download pubblici per questa prima installazione.',
    );
  }
  Future<Map> read(String path) async {
    final response = await client
        .get(
          Uri.parse('https://api.github.com/repos/Mich369/Oculum/$path'),
          headers: {'Accept': 'application/vnd.github+json'},
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw StateError(
        'Controllo aggiornamenti non disponibile (${response.statusCode}).',
      );
    }
    return jsonDecode(response.body) as Map;
  }

  final release = await read('releases/tags/oculum-downloads');
  if (release['draft'] != false || release['prerelease'] == true) return null;
  final body = '${release['body'] ?? ''}';
  const marker = '<!-- OCULUM_DOWNLOADS:';
  if (!body.contains(marker)) return null;
  final catalog = jsonDecode(body.split(marker).last.split(' -->').first);
  if (catalog is! Map) return null;
  final groups =
      catalog.values
          .whereType<Map>()
          .where((g) => g['workflow'] == 'Build distribution')
          .toList()
        ..sort(
          (a, b) => (int.tryParse('${b['runId']}') ?? 0).compareTo(
            int.tryParse('${a['runId']}') ?? 0,
          ),
        );
  var latestPublishedCommit = '';
  for (final group in groups) {
    final commit = '${group['commit']}';
    final run = int.tryParse('${group['runId']}') ?? 0;
    if (!RegExp(r'^[a-f0-9]{40}$').hasMatch(commit) || run <= 0) continue;
    latestPublishedCommit = commit;
    if (commit == currentCommit) break;
    final comparison = await read('compare/$currentCommit...$commit');
    // Branches that diverge or are older can never overwrite the installed app.
    if (comparison['status'] != 'ahead') break;
    final entries = (group['artifacts'] as List? ?? []).whereType<Map>();
    if (!const [
      'Oculum-Windows',
      'Oculum-Test-Windows',
      'Oculum-Android',
      'Oculum-macOS',
      'Oculum-Linux',
    ].every((name) => entries.any((e) => e['name'] == name))) {
      return null;
    }
    for (final entry in entries.where((e) => e['name'] == artifact)) {
      final url =
          'https://github.com/Mich369/Oculum/releases/download/oculum-build-$run/$artifact.zip';
      final hash = '${entry['sha256'] ?? ''}'.replaceFirst('sha256:', '');
      final bytes = int.tryParse('${entry['bytes']}') ?? 0;
      if (entry['url'] != url ||
          !RegExp(r'^[a-f0-9]{64}$').hasMatch(hash) ||
          bytes <= 0) {
        return null;
      }
      return OculumAppUpdate(
        commit: commit,
        url: url,
        sha256: hash,
        bytes: bytes,
        runId: run,
        changes: (group['changes'] as List? ?? [])
            .whereType<String>()
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .take(8)
            .toList(),
      );
    }
    break;
  }

  // A successful source push can be newer than the last fully published
  // cross-platform build. Do not tell the user they are up to date in that
  // gap; the page remains the fallback until verified artifacts are mirrored.
  final branch = await read('branches/main');
  final mainCommit = '${(branch['commit'] as Map?)?['sha'] ?? ''}';
  if (RegExp(r'^[a-f0-9]{40}$').hasMatch(mainCommit) &&
      mainCommit != currentCommit &&
      latestPublishedCommit != mainCommit) {
    final mainComparison = await read('compare/$currentCommit...$mainCommit');
    if (mainComparison['status'] == 'ahead') {
      throw StateError(
        'Esiste una build sorgente più recente (${mainCommit.substring(0, 7)}), ma i download verificati non sono ancora stati aggiornati. Riprova più tardi o usa la pagina Download.',
      );
    }
  }
  return null;
}
