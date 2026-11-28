import 'dart:convert';

const oculumRlVersion = String.fromEnvironment('OculumRlVersion');
const oculumRlRepository = 'Mich369/Oculum';
const oculumRlReleaseApi =
    'https://api.github.com/repos/$oculumRlRepository/releases?per_page=100';
const oculumRlMaxArchiveBytes = 512 * 1024 * 1024;
const oculumRlMaxIndexBytes = 2 * 1024 * 1024;

enum OculumRlEdition {
  normal('Windows', 'Oculum RL.exe', 'Oculum-RL-Windows.zip'),
  test('Windows Test', 'Oculum RL Test.exe', 'Oculum-RL-Windows-Test.zip');

  const OculumRlEdition(this.label, this.executable, this.archive);
  final String label;
  final String executable;
  final String archive;
  String get indexAssetName => archive.replaceFirst('.zip', '.index.json');
}

class OculumRlVersion implements Comparable<OculumRlVersion> {
  const OculumRlVersion(this.major, this.minor, this.patch);
  final int major, minor, patch;

  static final _pattern = RegExp(
    r'^(0|[1-9]\d{0,5})\.(0|[1-9]\d{0,5})\.(0|[1-9]\d{0,5})$',
  );

  static OculumRlVersion? parse(String text) {
    final match = _pattern.firstMatch(text);
    if (match == null || match.end != text.length) return null;
    return OculumRlVersion(
      int.parse(match[1]!),
      int.parse(match[2]!),
      int.parse(match[3]!),
    );
  }

  @override
  int compareTo(OculumRlVersion other) {
    final majorOrder = major.compareTo(other.major);
    if (majorOrder != 0) return majorOrder;
    final minorOrder = minor.compareTo(other.minor);
    return minorOrder == 0 ? patch.compareTo(other.patch) : minorOrder;
  }

  @override
  String toString() => '$major.$minor.$patch';
}

class OculumRlRelease {
  const OculumRlRelease(
    this.version,
    this.uri,
    this.bytes,
    this.sha256, {
    this.index,
  });
  final OculumRlVersion version;
  final Uri uri;
  final int bytes;
  final String sha256;
  final OculumRlAsset? index;
}

class OculumRlAsset {
  const OculumRlAsset(this.uri, this.bytes, this.sha256);

  final Uri uri;
  final int bytes;
  final String sha256;
}

class OculumRlTransfer {
  const OculumRlTransfer(this.bytes, {this.files});

  final int bytes;
  final int? files;
}

OculumRlAsset? _findAsset(List assets, String tag, String name, int maxBytes) {
  final url =
      'https://github.com/$oculumRlRepository/releases/download/$tag/$name';
  for (final asset in assets.whereType<Map>()) {
    final hash = asset['digest'];
    final bytes = asset['size'];
    if (asset['name'] == name &&
        asset['state'] == 'uploaded' &&
        asset['browser_download_url'] == url &&
        hash is String &&
        RegExp(r'^sha256:[a-f0-9]{64}$').hasMatch(hash) &&
        bytes is int &&
        bytes > 0 &&
        bytes <= maxBytes) {
      return OculumRlAsset(Uri.parse(url), bytes, hash.substring(7));
    }
  }
  return null;
}

OculumRlRelease? selectOculumRlRelease(
  String json, {
  required OculumRlVersion current,
  required OculumRlEdition edition,
}) {
  final decoded = jsonDecode(json);
  if (decoded is! List) {
    throw const FormatException('Elenco release GitHub non valido');
  }
  const prefix = 'oculum-rl-v';
  OculumRlRelease? newest;
  for (final release in decoded.whereType<Map>()) {
    final tag = release['tag_name'];
    if (release['draft'] != false ||
        release['published_at'] is! String ||
        tag is! String ||
        !tag.startsWith(prefix)) {
      continue;
    }
    final version = OculumRlVersion.parse(tag.substring(prefix.length));
    if (version == null ||
        version.compareTo(current) <= 0 ||
        (newest != null && version.compareTo(newest.version) <= 0)) {
      continue;
    }
    final assets = release['assets'];
    if (assets is! List) continue;
    final archives = {
      for (final target in OculumRlEdition.values)
        target: _findAsset(
          assets,
          tag,
          target.archive,
          oculumRlMaxArchiveBytes,
        ),
    };
    if (archives.values.any((asset) => asset == null)) continue;

    final hasIndexes = assets.whereType<Map>().any(
      (asset) => OculumRlEdition.values.any(
        (target) => asset['name'] == target.indexAssetName,
      ),
    );
    final indexes = {
      for (final target in OculumRlEdition.values)
        target: _findAsset(
          assets,
          tag,
          target.indexAssetName,
          oculumRlMaxIndexBytes,
        ),
    };
    if (hasIndexes && indexes.values.any((asset) => asset == null)) continue;
    final archive = archives[edition]!;
    newest = OculumRlRelease(
      version,
      archive.uri,
      archive.bytes,
      archive.sha256,
      index: indexes[edition],
    );
  }
  return newest;
}
