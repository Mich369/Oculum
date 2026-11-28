import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:pointycastle/digests/sha256.dart';

const _maxSegment = 2 * 1024 * 1024;
const _maxInlineSegment = 16 * 1024;
const _maxInlineTotal = 4 * 1024 * 1024;
const _maxManifest = 32 * 1024 * 1024;
const _maxSegments = 200000;
const _zip32Limit = 0xffffffff;
const _packageId = 'com.mich.oculum';
const _maxParallel = 4;
final _sha256 = RegExp(r'^[0-9a-f]{64}$');
final _commit = RegExp(r'^[0-9a-f]{40}$');
final _unsafeMemberCharacter = RegExp(r'[\\:\x00-\x1f\x7f]');

typedef _Segment = ({
  int offset,
  int bytes,
  String sha256,
  String? member,
  int? relativeOffset,
  Uint8List? inline,
});
typedef _Member = ({int start, int size});

String _hex(Uint8List value) =>
    value.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();

String _digest(Uint8List value) => _hex(SHA256Digest().process(value));

Future<String> _fileDigest(File file) async {
  final digest = SHA256Digest();
  await for (final chunk in file.openRead()) {
    final bytes = chunk is Uint8List ? chunk : Uint8List.fromList(chunk);
    digest.update(bytes, 0, bytes.length);
  }
  final result = Uint8List(digest.digestSize);
  digest.doFinal(result, 0);
  return _hex(result);
}

bool _validMemberName(String name) =>
    name.length <= 4096 &&
    !_unsafeMemberCharacter.hasMatch(name) &&
    !name.split('/').any((part) => part.isEmpty || part == '.' || part == '..');

({int versionCode, List<_Segment> segments}) _decodeManifest(
  Uint8List manifestBytes, {
  required String manifestSha256,
  required String commit,
  required int runId,
  required Uri apkUrl,
  required int apkBytes,
  required String apkSha256,
}) {
  final publishedUrl = Uri.https(
    'github.com',
    '/Mich369/Oculum/releases/download/oculum-build-$runId/'
        'Oculum-Android-Incrementale.apk',
  );
  if (manifestBytes.isEmpty ||
      manifestBytes.length > _maxManifest ||
      !_sha256.hasMatch(manifestSha256) ||
      _digest(manifestBytes) != manifestSha256 ||
      !_commit.hasMatch(commit) ||
      runId < 1 ||
      apkUrl != publishedUrl ||
      apkBytes < 22 ||
      apkBytes >= _zip32Limit ||
      !_sha256.hasMatch(apkSha256)) {
    throw const FormatException(
      'Invalid Android release metadata or manifest digest.',
    );
  }
  final document = jsonDecode(utf8.decode(manifestBytes));
  if (document is! Map<String, dynamic> ||
      document['schemaVersion'] is! int ||
      document['schemaVersion'] != 1 ||
      document['platform'] != 'android' ||
      document['commit'] != commit ||
      document['runId'] is! int ||
      document['runId'] != runId ||
      document['packageId'] != _packageId) {
    throw const FormatException(
      'Android manifest does not match the approved release.',
    );
  }
  final version = document['androidVersionCode'];
  final apk = document['apk'];
  final rows = document['segments'];
  if (version is! int ||
      version < 1 ||
      version > 0x7fffffff ||
      apk is! Map<String, dynamic> ||
      apk['url'] != publishedUrl.toString() ||
      apk['bytes'] is! int ||
      apk['bytes'] != apkBytes ||
      apk['sha256'] != apkSha256 ||
      rows is! List ||
      rows.isEmpty ||
      rows.length > _maxSegments) {
    throw const FormatException('Invalid Android APK or segment metadata.');
  }
  final segments = <_Segment>[];
  var nextOffset = 0;
  var inlineTotal = 0;
  for (final row in rows) {
    if (row is! Map<String, dynamic>) {
      throw const FormatException('Invalid Android APK segment.');
    }
    final offset = row['offset'];
    final bytes = row['bytes'];
    final hash = row['sha256'];
    final member = row['member'];
    final relative = row['relativeOffset'];
    final hasMember = row.containsKey('member');
    if (offset is! int ||
        offset != nextOffset ||
        bytes is! int ||
        bytes < 1 ||
        bytes > _maxSegment ||
        bytes > apkBytes - nextOffset ||
        hash is! String ||
        !_sha256.hasMatch(hash) ||
        hasMember != row.containsKey('relativeOffset') ||
        (hasMember &&
            (member is! String ||
                !_validMemberName(member) ||
                relative is! int ||
                relative < 0 ||
                relative > apkBytes - bytes))) {
      throw const FormatException(
        'Android APK segments must cover the asset exactly.',
      );
    }
    Uint8List? inline;
    if (row.containsKey('inline')) {
      final encoded = row['inline'];
      if (hasMember ||
          bytes > _maxInlineSegment ||
          inlineTotal + bytes > _maxInlineTotal ||
          encoded is! String ||
          encoded.length != ((bytes + 2) ~/ 3) * 4) {
        throw const FormatException('Invalid inline Android APK segment.');
      }
      inline = base64Decode(encoded);
      if (inline.length != bytes ||
          base64Encode(inline) != encoded ||
          _digest(inline) != hash) {
        throw const FormatException(
          'Inline Android APK segment did not match its encoding or SHA-256.',
        );
      }
      inlineTotal += bytes;
    }
    segments.add((
      offset: offset,
      bytes: bytes,
      sha256: hash,
      member: member as String?,
      relativeOffset: relative as int?,
      inline: inline,
    ));
    nextOffset += bytes;
  }
  if (nextOffset != apkBytes) {
    throw const FormatException(
      'Android APK segments leave an uncovered range.',
    );
  }
  return (versionCode: version, segments: List.unmodifiable(segments));
}

Future<Uint8List> _readExact(
  RandomAccessFile file,
  int offset,
  int count,
) async {
  await file.setPosition(offset);
  final bytes = await file.read(count);
  if (bytes.length != count) {
    throw const FormatException('Truncated APK range.');
  }
  return bytes;
}

int _u16(ByteData bytes, int offset) => bytes.getUint16(offset, Endian.little);
int _u32(ByteData bytes, int offset) => bytes.getUint32(offset, Endian.little);

Future<Map<String, _Member>> _zipMembers(
  RandomAccessFile file,
  Set<String> wanted,
) async {
  final size = await file.length();
  if (size < 22 || size >= _zip32Limit) {
    throw const FormatException('Unsupported installed ZIP32 APK.');
  }
  final tailLength = size < 65557 ? size : 65557;
  final tail = ByteData.sublistView(
    await _readExact(file, size - tailLength, tailLength),
  );
  var end = tailLength - 22;
  while (end >= 0 &&
      (_u32(tail, end) != 0x06054b50 ||
          end + 22 + _u16(tail, end + 20) != tailLength)) {
    end--;
  }
  if (end < 0 || _u16(tail, end + 4) != 0 || _u16(tail, end + 6) != 0) {
    throw const FormatException('Missing single-disk APK directory.');
  }
  final count = _u16(tail, end + 10);
  final centralSize = _u32(tail, end + 12);
  final centralStart = _u32(tail, end + 16);
  final centralEnd = size - tailLength + end;
  if (count == 0xffff ||
      count != _u16(tail, end + 8) ||
      centralStart + centralSize != centralEnd ||
      centralSize < count * 46) {
    throw const FormatException(
      'Invalid or unsupported APK central directory.',
    );
  }

  final members = <String, _Member>{};
  final seen = <String>{};
  var cursor = centralStart;
  for (var entry = 0; entry < count; entry++) {
    if (cursor + 46 > centralEnd) {
      throw const FormatException('Truncated APK central header.');
    }
    final central = ByteData.sublistView(await _readExact(file, cursor, 46));
    final nameLength = _u16(central, 28);
    final nameOffset = cursor + 46;
    cursor = nameOffset + nameLength + _u16(central, 30) + _u16(central, 32);
    if (_u32(central, 0) != 0x02014b50 || cursor > centralEnd) {
      throw const FormatException('Invalid APK central entry.');
    }
    if (nameLength == 0 || nameLength > 4096) continue;
    final nameBytes = await _readExact(file, nameOffset, nameLength);
    final name = utf8.decode(nameBytes, allowMalformed: true);
    if (name.contains('\uFFFD') || !wanted.contains(name)) continue;
    if (!seen.add(name)) {
      members.remove(name);
      continue;
    }

    final flags = _u16(central, 8);
    final method = _u16(central, 10);
    final compressed = _u32(central, 20);
    final local = _u32(central, 42);
    if (_u16(central, 34) != 0 ||
        flags & 0x2041 != 0 ||
        (method != 0 && method != 8) ||
        compressed == 0 ||
        compressed == _zip32Limit ||
        local + 30 > centralStart) {
      continue;
    }
    final header = ByteData.sublistView(await _readExact(file, local, 30));
    final start = local + 30 + _u16(header, 26) + _u16(header, 28);
    if (_u32(header, 0) != 0x04034b50 ||
        _u16(header, 6) != flags ||
        _u16(header, 8) != method ||
        _u16(header, 26) != nameLength ||
        start + compressed > centralStart) {
      continue;
    }
    final actualName = await _readExact(file, local + 30, nameLength);
    if (utf8.decode(actualName, allowMalformed: true) != name) continue;
    members[name] = (start: start, size: compressed);
  }
  if (cursor != centralEnd) {
    throw const FormatException(
      'APK central directory has an unsupported trailer.',
    );
  }
  return members;
}

class OculumAndroidIncrementalPlan {
  OculumAndroidIncrementalPlan._({
    required this.versionCode,
    required this.changedCount,
    required this.downloadBytes,
    required this.inlineBytes,
    required this.reusedBytes,
    required this.isNoOp,
    required this.apkSha256,
    required int apkBytes,
    required Uri apkUrl,
    required File installedApk,
    required List<_Segment> segments,
    required List<int?> offsets,
  }) : _apkBytes = apkBytes,
       _apkUrl = apkUrl,
       _installedApk = installedApk,
       _segments = segments,
       _offsets = offsets;

  final int versionCode;
  final int changedCount;
  final int downloadBytes;
  final int inlineBytes;
  final int reusedBytes;
  final bool isNoOp;
  final String apkSha256;
  final int _apkBytes;
  final Uri _apkUrl;
  final File _installedApk;
  final List<_Segment> _segments;
  final List<int?> _offsets;

  bool get canStage => !isNoOp && reusedBytes > 0;

  static Future<OculumAndroidIncrementalPlan> prepare({
    required Uint8List manifestBytes,
    required String manifestSha256,
    required String commit,
    required int runId,
    required Uri apkUrl,
    required int apkBytes,
    required String apkSha256,
    required File installedApk,
    required int installedVersionCode,
  }) async {
    final manifest = _decodeManifest(
      manifestBytes,
      manifestSha256: manifestSha256,
      commit: commit,
      runId: runId,
      apkUrl: apkUrl,
      apkBytes: apkBytes,
      apkSha256: apkSha256,
    );
    if (await FileSystemEntity.type(installedApk.path, followLinks: false) !=
            FileSystemEntityType.file ||
        installedVersionCode < 1 ||
        installedVersionCode > manifest.versionCode) {
      throw StateError('Installed APK cannot be used for this Android update.');
    }
    final offsets = <int?>[];
    var downloadBytes = 0;
    var inlineBytes = 0;
    var changedCount = 0;
    final isNoOp = installedVersionCode == manifest.versionCode;
    if (isNoOp) {
      if (await installedApk.length() != apkBytes ||
          await _fileDigest(installedApk) != apkSha256) {
        throw StateError(
          'This Android version code is already installed with different bytes.',
        );
      }
    } else {
      final source = await installedApk.open();
      try {
        final members = await _zipMembers(source, {
          for (final segment in manifest.segments)
            if (segment.member != null) segment.member!,
        });
        for (final segment in manifest.segments) {
          if (segment.inline != null) {
            offsets.add(null);
            inlineBytes += segment.bytes;
            continue;
          }
          final member = members[segment.member];
          final relative = segment.relativeOffset;
          int? matched;
          if (member != null &&
              relative != null &&
              relative <= member.size - segment.bytes) {
            final start = member.start + relative;
            if (_digest(await _readExact(source, start, segment.bytes)) ==
                segment.sha256) {
              matched = start;
            }
          }
          offsets.add(matched);
          if (matched == null) {
            downloadBytes += segment.bytes;
            changedCount++;
          }
        }
      } finally {
        await source.close();
      }
    }
    return OculumAndroidIncrementalPlan._(
      versionCode: manifest.versionCode,
      changedCount: changedCount,
      downloadBytes: downloadBytes,
      inlineBytes: inlineBytes,
      reusedBytes: apkBytes - downloadBytes - inlineBytes,
      isNoOp: isNoOp,
      apkSha256: apkSha256,
      apkBytes: apkBytes,
      apkUrl: apkUrl,
      installedApk: installedApk,
      segments: manifest.segments,
      offsets: List.unmodifiable(offsets),
    );
  }

  Future<File> stage({
    required Directory workDirectory,
    required http.Client client,
    void Function(int received, int total)? onProgress,
  }) async {
    if (!canStage) {
      throw StateError(
        'This Android plan does not need or cannot use incremental staging.',
      );
    }
    if (await FileSystemEntity.type(workDirectory.path, followLinks: false) !=
            FileSystemEntityType.directory ||
        await FileSystemEntity.type(_installedApk.path, followLinks: false) !=
            FileSystemEntityType.file) {
      throw StateError(
        'Android update requires ordinary files in its private cache.',
      );
    }
    final attempt = await workDirectory.createTemp('oculum-verified-apk-');
    final staged = File('${attempt.path}${Platform.pathSeparator}oculum.apk');
    try {
      await staged.create(exclusive: true);
      final source = await _installedApk.open();
      try {
        final output = await staged.open(mode: FileMode.writeOnly);
        try {
          await _reconstruct(source, output, client, onProgress);
          await output.flush();
        } finally {
          await output.close();
        }
      } finally {
        await source.close();
      }
      if (await staged.length() != _apkBytes ||
          await _fileDigest(staged) != apkSha256) {
        throw const FormatException(
          'Reconstructed APK did not match the release SHA-256.',
        );
      }
      return staged;
    } catch (_) {
      try {
        if (await staged.exists()) await staged.delete();
        await attempt.delete();
      } on FileSystemException {
        // A failed cleanup never makes an incomplete candidate installable.
      }
      rethrow;
    }
  }

  Future<void> _reconstruct(
    RandomAccessFile source,
    RandomAccessFile output,
    http.Client client,
    void Function(int received, int total)? onProgress,
  ) async {
    final transport = _ApkRangeReader(client, _apkUrl, _apkBytes);
    var downloaded = 0;
    onProgress?.call(0, downloadBytes);
    bool needsNetwork(int index) =>
        _offsets[index] == null && _segments[index].inline == null;
    var next = 0;
    while (next < _segments.length) {
      final batch = <({int first, int end, int bytes, bool remote})>[];
      var downloads = 0;
      while (next < _segments.length && batch.length < 16) {
        final first = next;
        final remote = needsNetwork(first);
        if (remote && downloads == _maxParallel) break;
        var bytes = _segments[next++].bytes;
        if (remote) {
          downloads++;
          while (next < _segments.length &&
              needsNetwork(next) &&
              bytes + _segments[next].bytes <= _maxSegment) {
            bytes += _segments[next++].bytes;
          }
        }
        batch.add((first: first, end: next, bytes: bytes, remote: remote));
      }
      final fetched = <int, Uint8List>{};
      await Future.wait([
        for (final range in batch)
          if (range.remote)
            transport.fetch(_segments[range.first].offset, range.bytes).then((
              data,
            ) {
              fetched[range.first] = data;
            }),
      ]);
      for (final range in batch) {
        final data = range.remote
            ? fetched.remove(range.first)!
            : _segments[range.first].inline ??
                  await _readExact(source, _offsets[range.first]!, range.bytes);
        var cursor = 0;
        for (var index = range.first; index < range.end; index++) {
          final segment = _segments[index];
          if (_digest(
                Uint8List.sublistView(data, cursor, cursor + segment.bytes),
              ) !=
              segment.sha256) {
            throw FormatException(
              range.remote
                  ? 'Downloaded APK segment SHA-256 mismatch.'
                  : 'Installed APK changed after the incremental plan. Prepare a new plan.',
            );
          }
          cursor += segment.bytes;
        }
        await output.writeFrom(data);
        if (range.remote) {
          downloaded += range.bytes;
          onProgress?.call(downloaded, downloadBytes);
        }
      }
    }
  }
}

class _ApkRangeReader {
  _ApkRangeReader(this.client, this.origin, this.total);

  final http.Client client;
  final Uri origin;
  final int total;
  Uri? _cdn;

  bool _trusted(Uri uri) =>
      uri.scheme == 'https' &&
      uri.port == 443 &&
      uri.userInfo.isEmpty &&
      !uri.hasFragment &&
      (uri == origin ||
          const {
            'release-assets.githubusercontent.com',
            'objects.githubusercontent.com',
          }.contains(uri.host));

  Future<Uint8List> fetch(int offset, int bytes) async {
    var url = _cdn ?? origin;
    final end = offset + bytes - 1;
    for (var attempt = 0; attempt < 5; attempt++) {
      if (!_trusted(url)) {
        throw const FormatException('Untrusted Android APK redirect.');
      }
      final request = http.Request('GET', url)..followRedirects = false;
      request.headers['Range'] = 'bytes=$offset-$end';
      request.headers['Accept-Encoding'] = 'identity';
      final response = await client
          .send(request)
          .timeout(const Duration(seconds: 30));
      if (const {301, 302, 303, 307, 308}.contains(response.statusCode)) {
        final location = response.headers['location'];
        await response.stream.listen(null).cancel();
        if (location == null || location.isEmpty) {
          throw const FormatException(
            'Missing Android APK redirect destination.',
          );
        }
        url = url.resolve(location);
        continue;
      }
      final encoding = response.headers['content-encoding'];
      if (response.statusCode != 206 ||
          response.contentLength != bytes ||
          response.headers['content-range'] != 'bytes $offset-$end/$total' ||
          (encoding != null && encoding.toLowerCase() != 'identity')) {
        await response.stream.listen(null).cancel();
        throw const FormatException(
          'Server did not return the exact Android APK range.',
        );
      }
      final result = Uint8List(bytes);
      var received = 0;
      final input = StreamIterator(response.stream);
      final clock = Stopwatch()..start();
      try {
        const limit = Duration(seconds: 45);
        while (await input.moveNext().timeout(limit - clock.elapsed)) {
          final chunk = input.current;
          if (chunk.length > bytes - received) {
            throw const FormatException(
              'Android APK range exceeded its declared length.',
            );
          }
          result.setRange(received, received + chunk.length, chunk);
          received += chunk.length;
        }
      } finally {
        await input.cancel();
      }
      if (received != bytes) {
        throw const FormatException('Incomplete Android APK range.');
      }
      if (url != origin) _cdn = url;
      return result;
    }
    throw const FormatException('Android APK redirect limit reached.');
  }
}
