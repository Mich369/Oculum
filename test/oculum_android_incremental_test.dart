import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pointycastle/digests/sha256.dart';

import 'package:oculum/services/oculum_android_incremental.dart';

const _chunk = 2 * 1024 * 1024;
const _run = 1234567;
const _targetVersion = 100402;
final _commit = 'b' * 40;
final _url = Uri.parse(
  'https://github.com/Mich369/Oculum/releases/download/'
  'oculum-build-$_run/Oculum-Android-Incrementale.apk',
);

String _sha(Uint8List bytes) => SHA256Digest()
    .process(bytes)
    .map((value) => value.toRadixString(16).padLeft(2, '0'))
    .join();

Uint8List _text(String value) => Uint8List.fromList(utf8.encode(value));

int _crc(Uint8List bytes) {
  var crc = 0xffffffff;
  for (final byte in bytes) {
    crc ^= byte;
    for (var bit = 0; bit < 8; bit++) {
      crc = (crc >>> 1) ^ (0xedb88320 & -(crc & 1));
    }
  }
  return crc ^ 0xffffffff;
}

typedef _FixtureZip = ({
  Uint8List raw,
  List<({String name, int start, int bytes})> members,
});

_FixtureZip _zip(Map<String, Uint8List> entries, {int padding = 0}) {
  final archive = BytesBuilder(copy: false);
  final directory = BytesBuilder(copy: false);
  final members = <({String name, int start, int bytes})>[];
  for (final entry in entries.entries) {
    final name = _text(entry.key);
    final value = entry.value;
    final method = entry.key.endsWith('.bin') ? 8 : 0;
    final bytes = method == 0
        ? value
        : Uint8List.fromList(ZLibEncoder(raw: true).convert(value));
    final crc = _crc(value);
    final local = archive.length;
    final extra = ByteData(4 + padding)
      ..setUint16(0, 0xd935, Endian.little)
      ..setUint16(2, padding, Endian.little);
    final header = ByteData(30)
      ..setUint32(0, 0x04034b50, Endian.little)
      ..setUint16(4, 20, Endian.little)
      ..setUint16(6, 0x800, Endian.little)
      ..setUint16(8, method, Endian.little)
      ..setUint32(14, crc, Endian.little)
      ..setUint32(18, bytes.length, Endian.little)
      ..setUint32(22, value.length, Endian.little)
      ..setUint16(26, name.length, Endian.little)
      ..setUint16(28, extra.lengthInBytes, Endian.little);
    archive
      ..add(header.buffer.asUint8List())
      ..add(name)
      ..add(extra.buffer.asUint8List());
    members.add((name: entry.key, start: archive.length, bytes: bytes.length));
    archive.add(bytes);
    final central = ByteData(46)
      ..setUint32(0, 0x02014b50, Endian.little)
      ..setUint16(4, 20, Endian.little)
      ..setUint16(6, 20, Endian.little)
      ..setUint16(8, 0x800, Endian.little)
      ..setUint16(10, method, Endian.little)
      ..setUint32(16, crc, Endian.little)
      ..setUint32(20, bytes.length, Endian.little)
      ..setUint32(24, value.length, Endian.little)
      ..setUint16(28, name.length, Endian.little)
      ..setUint32(42, local, Endian.little);
    directory
      ..add(central.buffer.asUint8List())
      ..add(name);
  }
  // The draft reconstructs these opaque bytes exactly. Native Android owns signing checks.
  archive.add(_text('opaque APK signing block $padding'));
  final centralStart = archive.length;
  final centralLength = directory.length;
  archive.add(directory.takeBytes());
  final comment = _text('comment $padding');
  final end = ByteData(22)
    ..setUint32(0, 0x06054b50, Endian.little)
    ..setUint16(8, entries.length, Endian.little)
    ..setUint16(10, entries.length, Endian.little)
    ..setUint32(12, centralLength, Endian.little)
    ..setUint32(16, centralStart, Endian.little)
    ..setUint16(20, comment.length, Endian.little);
  archive
    ..add(end.buffer.asUint8List())
    ..add(comment);
  return (raw: archive.takeBytes(), members: members);
}

Map<String, dynamic> _manifest(
  _FixtureZip archive, {
  String? apkDigest,
  bool inlineGaps = false,
}) {
  final rows = <Map<String, dynamic>>[];
  var cursor = 0;
  void addThrough(int end, {String? member, int? start}) {
    while (cursor < end) {
      final limit = end - cursor <= _chunk ? end : cursor + _chunk;
      final content = Uint8List.sublistView(archive.raw, cursor, limit);
      rows.add({
        'offset': cursor,
        'bytes': limit - cursor,
        'sha256': _sha(content),
        'member': ?member,
        if (start != null) 'relativeOffset': cursor - start,
        if (inlineGaps && member == null && content.length <= 16384)
          'inline': base64Encode(content),
      });
      cursor = limit;
    }
  }

  for (final entry in archive.members) {
    addThrough(entry.start);
    addThrough(
      entry.start + entry.bytes,
      member: entry.name,
      start: entry.start,
    );
  }
  addThrough(archive.raw.length);
  return {
    'schemaVersion': 1,
    'platform': 'android',
    'commit': _commit,
    'runId': _run,
    'androidVersionCode': _targetVersion,
    'packageId': 'com.mich.oculum',
    'apk': {
      'url': _url.toString(),
      'bytes': archive.raw.length,
      'sha256': apkDigest ?? _sha(archive.raw),
    },
    'segments': rows,
  };
}

Future<OculumAndroidIncrementalPlan> _prepare(
  File source,
  Map<String, dynamic> doc, {
  int version = _targetVersion - 1,
  String? manifestSha256,
}) {
  final bytes = _text(jsonEncode(doc));
  final apk = doc['apk'] as Map;
  return OculumAndroidIncrementalPlan.prepare(
    manifestBytes: bytes,
    manifestSha256: manifestSha256 ?? _sha(bytes),
    commit: _commit,
    runId: _run,
    apkUrl: _url,
    apkBytes: apk['bytes'] as int,
    apkSha256: apk['sha256'] as String,
    installedApk: source,
    installedVersionCode: version,
  );
}

typedef _Range = ({int start, int end});

class _FixtureTransport {
  _FixtureTransport(this.apk, {this.failure});

  final Uint8List apk;
  final String? failure;
  final ranges = <_Range>[];
  final allowed = <String>[];
  var active = 0;
  var peak = 0;
  late final client = MockClient.streaming((request, _) async {
    expect(request.followRedirects, isFalse);
    expect(request.headers['Accept-Encoding'], 'identity');
    allowed.add(request.url.host);
    if (request.url.host == 'github.com') {
      final host = failure == 'redirect'
          ? 'example.org'
          : 'release-assets.githubusercontent.com';
      return http.StreamedResponse(
        const Stream.empty(),
        302,
        headers: {'location': 'https://$host/apk?fixture=true'},
      );
    }
    expect(request.url.host, 'release-assets.githubusercontent.com');
    final match = RegExp(
      r'^bytes=(\d+)-(\d+)$',
    ).firstMatch(request.headers['Range']!)!;
    final start = int.parse(match[1]!);
    final end = int.parse(match[2]!);
    final length = end - start + 1;
    ranges.add((start: start, end: end));
    expect(length, inInclusiveRange(1, _chunk));
    active++;
    if (active > peak) peak = active;
    await Future<void>.delayed(const Duration(milliseconds: 10));
    active--;
    var bytes = Uint8List.fromList(apk.sublist(start, end + 1));
    if (failure == 'corrupt') bytes[0] ^= 1;
    if (failure == 'short') bytes = Uint8List.sublistView(bytes, 0, length - 1);
    if (failure == 'long') bytes = Uint8List.fromList([...bytes, 0]);
    return http.StreamedResponse(
      Stream.value(bytes),
      failure == 'status' ? 200 : 206,
      contentLength: failure == 'length' ? length + 1 : length,
      headers: {
        'content-range':
            'bytes $start-$end/${failure == 'bounds' ? apk.length + 1 : apk.length}',
        if (failure == 'encoding') 'content-encoding': 'gzip',
      },
    );
  });
}

void main() {
  late Directory work;
  late Directory output;
  late File saves;
  late File old;
  late _FixtureZip oldZip;
  late _FixtureZip target;
  late Map<String, dynamic> document;
  late Uint8List stableLarge;
  final stableCompressed = _text(
    'same compressed member across versions. ' * 37,
  );

  setUpAll(() {
    stableLarge = Uint8List(_chunk + 59);
    for (var i = 0; i < stableLarge.length; i++) {
      stableLarge[i] = i & 0xff;
    }
    target = _zip({
      'AndroidManifest.xml': _text('signed release manifest'),
      'assets/long.dat': stableLarge,
      'assets/résistance.bin': stableCompressed,
      'lib/a.dat': _text('new library'),
    }, padding: 17);
    final largeWithOldTail = Uint8List.fromList(stableLarge)
      ..[stableLarge.length - 1] = 0;
    oldZip = _zip({
      'assets/résistance.bin': stableCompressed,
      'assets/long.dat': largeWithOldTail,
      'AndroidManifest.xml': _text('older manifest'),
    }, padding: 3);
  });

  setUp(() async {
    final fixtureRoot = await Directory('build').absolute.create();
    work = await fixtureRoot.createTemp('oculum-android-incremental-');
    final owned = Directory(await work.resolveSymbolicLinks());
    expect(owned.parent.path, await fixtureRoot.resolveSymbolicLinks());
    addTearDown(() => owned.delete(recursive: true));
    output = await Directory('${work.path}/cache').create();
    old = await File('${work.path}/base.apk').writeAsBytes(oldZip.raw);
    saves = await File(
      '${work.path}/oculum-save.json',
    ).writeAsString('{"private":true}');
    document = _manifest(target);
  });

  test(
    'reconstructs exact signed-target bytes from two older, reordered packages',
    () async {
      final older = _zip({
        'lib/a.dat': _text('even older library'),
        'assets/long.dat': stableLarge,
        'assets/résistance.bin': stableCompressed,
      }, padding: 1);
      final oldRelease = await File(
        '${work.path}/older.apk',
      ).writeAsBytes(older.raw);
      for (final version in [
        (file: old, code: 100390, raw: oldZip.raw, expected: _chunk),
        (
          file: oldRelease,
          code: 100012,
          raw: older.raw,
          expected: stableLarge.length,
        ),
      ]) {
        final plan = await _prepare(
          version.file,
          document,
          version: version.code,
        );
        final compressed = target.members
            .singleWhere((row) => row.name.endsWith('.bin'))
            .bytes;
        expect(plan.versionCode, _targetVersion);
        expect(plan.apkSha256, _sha(target.raw));
        expect(plan.reusedBytes, version.expected + compressed);
        expect(plan.downloadBytes, target.raw.length - plan.reusedBytes);
        expect(plan.changedCount, greaterThan(0));
        final transport = _FixtureTransport(target.raw);
        addTearDown(transport.client.close);
        final accepted = <int>[];
        final file = await plan.stage(
          workDirectory: output,
          client: transport.client,
          onProgress: (done, total) {
            expect(total, plan.downloadBytes);
            accepted.add(done);
          },
        );
        expect(await file.readAsBytes(), target.raw);
        expect(
          transport.ranges.fold<int>(
            0,
            (sum, range) => sum + range.end - range.start + 1,
          ),
          plan.downloadBytes,
        );
        expect(transport.peak, inInclusiveRange(2, 4));
        expect(
          transport.allowed,
          containsAll(['github.com', 'release-assets.githubusercontent.com']),
        );
        expect(accepted.first, 0);
        expect(accepted.last, plan.downloadBytes);
        expect(await version.file.readAsBytes(), version.raw);
        expect(await saves.readAsString(), '{"private":true}');
      }
    },
  );

  test(
    'an identical installed APK is a no-op and a no-reuse plan cannot download it all',
    () async {
      await old.writeAsBytes(target.raw);
      final same = await _prepare(old, document, version: _targetVersion);
      expect(same.isNoOp, isTrue);
      expect(same.downloadBytes, 0);
      expect(same.changedCount, 0);
      expect(same.canStage, isFalse);
      await expectLater(
        _prepare(old, document, version: _targetVersion + 1),
        throwsStateError,
      );
      await old.writeAsBytes(
        _zip({'unrelated.dat': _text('different app bytes')}).raw,
      );
      await expectLater(
        _prepare(old, document, version: _targetVersion),
        throwsStateError,
      );
      final all = await _prepare(old, document);
      expect(all.canStage, isFalse);
      expect(all.downloadBytes, target.raw.length);
      final transport = _FixtureTransport(target.raw);
      addTearDown(transport.client.close);
      await expectLater(
        all.stage(workDirectory: output, client: transport.client),
        throwsStateError,
      );
      expect(transport.ranges, isEmpty);
      expect(await output.list().toList(), isEmpty);
    },
  );

  test(
    'rejects unapproved metadata, noncontiguous ranges and unsafe member hints',
    () async {
      await expectLater(
        _prepare(old, document, manifestSha256: '0' * 64),
        throwsFormatException,
      );
      for (final key in ['packageId', 'platform', 'runId', 'commit']) {
        await expectLater(
          _prepare(old, {...document, key: 'incorrect'}),
          throwsFormatException,
        );
      }
      for (final patch in <Map<String, Object?>>[
        {'offset': 1},
        {'bytes': _chunk + 1},
        {'sha256': 'X' * 64},
        {'member': '../escape', 'relativeOffset': 0},
        {'member': 'assets/ok'},
        {'member': 'assets/ok', 'relativeOffset': -1},
      ]) {
        final rows = (document['segments'] as List<Map<String, dynamic>>)
            .toList();
        rows[0] = {...rows.first, ...patch};
        await expectLater(
          _prepare(old, {...document, 'segments': rows}),
          throwsFormatException,
        );
      }
      final wrongUrl = {
        ...document['apk'] as Map,
        'url': _url.replace(host: 'example.org').toString(),
      };
      await expectLater(
        _prepare(old, {...document, 'apk': wrongUrl}),
        throwsFormatException,
      );
    },
  );

  test(
    'rejects corrupted ranges and bad response envelopes and leaves no staged APK',
    () async {
      final plan = await _prepare(old, document);
      for (final fault in [
        'corrupt',
        'status',
        'bounds',
        'length',
        'short',
        'long',
        'redirect',
        'encoding',
      ]) {
        final transport = _FixtureTransport(target.raw, failure: fault);
        try {
          await expectLater(
            plan.stage(workDirectory: output, client: transport.client),
            throwsFormatException,
          );
          expect(transport.allowed, isNot(contains('example.org')));
        } finally {
          transport.client.close();
        }
        expect(await output.list().toList(), isEmpty, reason: fault);
      }
      expect(await old.readAsBytes(), oldZip.raw);
    },
  );

  test(
    'verifies inline structure and avoids issuing tiny Range requests',
    () async {
      final inlineDocument = _manifest(target, inlineGaps: true);
      final structure =
          (inlineDocument['segments'] as List<Map<String, dynamic>>)
              .where((row) => row.containsKey('inline'))
              .toList();
      final plan = await _prepare(old, inlineDocument);
      final transport = _FixtureTransport(target.raw);
      addTearDown(transport.client.close);
      expect(
        plan.inlineBytes,
        structure.fold<int>(0, (sum, row) => sum + (row['bytes'] as int)),
      );
      expect(
        plan.reusedBytes + plan.inlineBytes + plan.downloadBytes,
        target.raw.length,
      );
      final file = await plan.stage(
        workDirectory: output,
        client: transport.client,
      );
      expect(await file.readAsBytes(), target.raw);
      expect(
        transport.ranges.fold<int>(
          0,
          (sum, row) => sum + row.end - row.start + 1,
        ),
        plan.downloadBytes,
      );
      for (final row in structure) {
        final start = row['offset'] as int;
        final end = start + (row['bytes'] as int) - 1;
        expect(
          transport.ranges.any(
            (range) => range.start <= end && range.end >= start,
          ),
          isFalse,
        );
      }
      expect(
        plan.changedCount,
        3,
      ); // New XML, tail of the large asset, and new library.

      final sameMembers = _zip({
        'assets/long.dat': stableLarge,
        'AndroidManifest.xml': _text('signed release manifest'),
        'lib/a.dat': _text('new library'),
        'assets/résistance.bin': stableCompressed,
      }, padding: 7);
      await old.writeAsBytes(sameMembers.raw);
      final offline = await _prepare(old, inlineDocument);
      expect(offline.canStage, isTrue);
      expect(offline.downloadBytes, 0);
      expect(offline.changedCount, 0);
      final neverFetch = MockClient(
        (_) async => throw StateError('Inline plan made an HTTP request.'),
      );
      addTearDown(neverFetch.close);
      expect(
        await (await offline.stage(
          workDirectory: output,
          client: neverFetch,
        )).readAsBytes(),
        target.raw,
      );
    },
  );

  test(
    'rejects noncanonical, oversized and unauthenticated inline structure',
    () async {
      final whole = _manifest(target, inlineGaps: true);
      final good = whole['segments'] as List<Map<String, dynamic>>;
      final first = good.first;
      final encoded = first['inline'] as String;
      for (final patch in <Map<String, Object?>>[
        {'inline': encoded.replaceAll('=', '')},
        {'inline': base64Encode(Uint8List(first['bytes'] as int))},
        {'member': 'assets/long.dat', 'relativeOffset': 0},
        {'inline': null},
        {'bytes': 16385, 'inline': base64Encode(Uint8List(16385))},
      ]) {
        await expectLater(
          _prepare(old, {
            ...whole,
            'segments': [
              {...first, ...patch},
              ...good.skip(1),
            ],
          }),
          throwsFormatException,
        );
      }
      const block = 16384;
      final inline = Uint8List(block);
      final inlineHash = _sha(inline);
      final inlineText = base64Encode(inline);
      final oversize = {
        ...whole,
        'apk': {...whole['apk'] as Map, 'bytes': block * 257},
        'segments': [
          for (var i = 0; i < 257; i++)
            {
              'offset': i * block,
              'bytes': block,
              'sha256': inlineHash,
              'inline': inlineText,
            },
        ],
      };
      await expectLater(_prepare(old, oversize), throwsFormatException);
    },
  );

  test(
    'checks the full hash even when every segment independently matches',
    () async {
      final plan = await _prepare(old, _manifest(target, apkDigest: 'a' * 64));
      final transport = _FixtureTransport(target.raw);
      addTearDown(transport.client.close);
      await expectLater(
        plan.stage(workDirectory: output, client: transport.client),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('release SHA-256'),
          ),
        ),
      );
      expect(await output.list().toList(), isEmpty);
    },
  );

  test(
    'rechecks reused bytes and cannot substitute an unapproved full download',
    () async {
      final plan = await _prepare(old, document);
      final original = oldZip.members.singleWhere(
        (row) => row.name == 'assets/long.dat',
      );
      final damaged = Uint8List.fromList(oldZip.raw)..[original.start] = 47;
      await old.writeAsBytes(damaged);
      final transport = _FixtureTransport(target.raw);
      addTearDown(transport.client.close);
      await expectLater(
        plan.stage(workDirectory: output, client: transport.client),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('changed after'),
          ),
        ),
      );
      final reusedTarget = target.members
          .singleWhere((row) => row.name == 'assets/long.dat')
          .start;
      expect(
        transport.ranges.where(
          (range) => range.start <= reusedTarget && range.end >= reusedTarget,
        ),
        isEmpty,
      );
      expect(await output.list().toList(), isEmpty);
    },
  );
}
