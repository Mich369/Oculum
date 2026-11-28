import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum_rl/services/oculum_rl_release.dart';
import 'package:oculum_rl/services/oculum_rl_update_native.dart';

final targetVersion = OculumRlVersion.parse('0.5.3')!;

Map<String, String> _target(OculumRlEdition edition) => {
  edition.executable: 'exe',
  'flutter_windows.dll': 'engine',
  'data/icudtl.dat': 'icu',
  'data/app.so': 'new implementation ' * 20,
  'data/return.webp': 'as originally shipped',
  'data/added.txt': 'new file',
  'data/empty': '',
};

class _Fixture {
  _Fixture(this.edition);

  final OculumRlEdition edition;
  late final HttpServer server;
  late final Directory workspace;
  late final Directory installed;
  late final Directory updates;
  final client = HttpClient()..autoUncompress = false;
  final requests = <(int, int)>[];
  final expectedRanges = <String, (int, int)>{};
  final delivered = <List<int>>[];
  String? failPath;
  String? corruptPath;
  bool ignoreRange = false;
  int fullRequests = 0;
  bool legacy = false;
  late List<int> bytes;
  late List<int> index;
  late Map<String, String> target;

  Future<void> setup({
    bool same = false,
    bool interveningVersion = false,
  }) async {
    workspace = await Directory.systemTemp.createTemp('oculum-rl-delta-');
    addTearDown(() => workspace.delete(recursive: true));
    installed = await Directory('${workspace.path}/installed').create();
    updates = await Directory('${workspace.path}/updates').create();
    target = _target(edition);
    final original = {
      ...target,
      'data/old.txt': 'previous managed file',
      'my-customization.txt': 'user file',
    };
    if (!same) {
      original['data/app.so'] = interveningVersion ? 'middle version' : 'old';
      original.remove('data/added.txt');
      original.remove('data/empty');
      if (interveningVersion)
        original['data/return.webp'] = 'temporarily changed';
    }
    for (final MapEntry(:key, :value) in original.entries) {
      final file = File('${installed.path}/$key');
      await file.parent.create(recursive: true);
      await file.writeAsString(value);
    }

    bytes = List.filled(40, 0, growable: true);
    final rows = <Map<String, Object>>[];
    for (final MapEntry(key: path, value: contents) in target.entries) {
      final raw = utf8.encode(contents);
      final encoded = path == 'data/app.so'
          ? ZLibCodec(raw: true).encode(raw)
          : raw;
      final start = bytes.length;
      bytes.addAll(encoded);
      if (encoded.isNotEmpty) {
        expectedRanges[path] = (start, bytes.length - 1);
      }
      rows.add({
        'path': path,
        'size': raw.length,
        'offset': start,
        'length': encoded.length,
        'method': path == 'data/app.so' ? 8 : 0,
        'sha256': sha256.convert(raw).toString(),
      });
    }
    index = utf8.encode(
      jsonEncode({
        'schemaVersion': 1,
        'version': '$targetVersion',
        'edition': edition.name,
        'archiveBytes': bytes.length,
        'archiveSha256': sha256.convert(bytes).toString(),
        'files': rows,
      }),
    );

    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async {
      client.close(force: true);
      await server.close(force: true);
    });
    server.listen((request) async {
      final response = request.response;
      final range = request.headers.value(HttpHeaders.rangeHeader);
      if (request.uri.path == '/index') {
        response.add(index);
      } else if (range == null || ignoreRange) {
        fullRequests++;
        response.add(bytes);
      } else {
        final endpoints = range.substring(6).split('-');
        final first = int.parse(endpoints[0]), last = int.parse(endpoints[1]);
        requests.add((first, last));
        if (expectedRanges[failPath] == (first, last)) {
          response.statusCode = HttpStatus.serviceUnavailable;
        } else {
          final payload = bytes.sublist(first, last + 1);
          if (expectedRanges[corruptPath] == (first, last)) payload[0] ^= 1;
          delivered.add(payload);
          response.statusCode = HttpStatus.partialContent;
          response.headers.set(
            HttpHeaders.contentRangeHeader,
            'bytes $first-$last/${bytes.length}',
          );
          response.contentLength = payload.length;
          response.add(payload);
        }
      }
      await response.close();
    });
  }

  OculumRlRelease get release {
    final origin = 'http://127.0.0.1:${server.port}';
    return OculumRlRelease(
      targetVersion,
      Uri.parse('$origin/zip'),
      bytes.length,
      sha256.convert(bytes).toString(),
      index: legacy
          ? null
          : OculumRlAsset(
              Uri.parse('$origin/index'),
              index.length,
              sha256.convert(index).toString(),
            ),
    );
  }

  Future<void> apply(void Function(OculumRlTransfer) onTransfer) =>
      stageOculumRlUpdate(
        updates,
        release,
        edition,
        installed: installed,
        fetch: (uri, {range}) async {
          final request = await client.getUrl(uri);
          if (range case (final first, final last)) {
            request.headers.set(HttpHeaders.rangeHeader, 'bytes=$first-$last');
          }
          return request.close();
        },
        onTransfer: onTransfer,
      );

  Directory get ready => Directory('${updates.path}/$targetVersion');
}

void main() {
  for (final edition in OculumRlEdition.values) {
    for (final singleStep in [false, true]) {
      test(
        '${edition.label}: ${singleStep ? 'single' : 'skipped versions'} transfer only differences',
        () async {
          final f = _Fixture(edition);
          await f.setup(interveningVersion: singleStep);
          final changed = [
            if (singleStep) 'data/return.webp',
            'data/app.so',
            'data/added.txt',
          ];
          await f.apply((transfer) {
            expect(f.requests, isEmpty);
            expect(
              transfer.files,
              changed.length + 1,
            ); // Includes the empty file.
            expect(
              transfer.bytes,
              changed.fold<int>(0, (bytes, path) {
                final (first, last) = f.expectedRanges[path]!;
                return bytes + last - first + 1;
              }),
            );
          });
          expect(
            f.requests,
            unorderedEquals(changed.map((name) => f.expectedRanges[name]!)),
          );
          expect(f.fullRequests, 0);
          for (final MapEntry(key: path, value: contents) in f.target.entries) {
            expect(
              await File('${f.ready.path}/$path').readAsString(),
              contents,
            );
          }
          expect(
            await File('${f.ready.path}/.oculum-rl-update.json').exists(),
            isTrue,
          );
          expect(await File('${f.ready.path}/data/old.txt').exists(), isFalse);
          expect(
            await File('${f.installed.path}/data/old.txt').exists(),
            isTrue,
          );
          expect(
            await File('${f.installed.path}/my-customization.txt')
                .readAsString(),
            'user file',
          );
        },
      );
    }
  }

  test('identical files require zero requests for ZIP content', () async {
    final f = _Fixture(OculumRlEdition.normal);
    await f.setup(same: true);
    await f.apply((transfer) {
      expect(transfer.files, 0);
      expect(transfer.bytes, 0);
    });
    expect(f.requests, isEmpty);
    expect(f.fullRequests, 0);
    expect(await f.ready.exists(), isTrue);
  });

  test(
    'transfer interrupted after one file keeps the old install and can retry',
    () async {
      final f = _Fixture(OculumRlEdition.test);
      await f.setup();
      f.failPath = 'data/added.txt';
      await expectLater(f.apply((_) {}), throwsA(isA<HttpException>()));
      expect(f.delivered, hasLength(1));
      expect(await f.updates.list().isEmpty, isTrue);
      expect(
        await File('${f.installed.path}/data/app.so').readAsString(),
        'old',
      );
      f.failPath = null;
      await f.apply((_) {});
      expect(await f.ready.exists(), isTrue);
    },
  );

  test(
    'HTTP 200 on a range is rejected without retrying the full download',
    () async {
      final f = _Fixture(OculumRlEdition.normal);
      await f.setup();
      f.ignoreRange = true;
      await expectLater(f.apply((_) {}), throwsA(isA<HttpException>()));
      expect(f.fullRequests, 1);
      expect(await f.updates.list().isEmpty, isTrue);
    },
  );

  test(
    'older releases without an index still verify and install a full ZIP',
    () async {
      final f = _Fixture(OculumRlEdition.test);
      await f.setup();
      f.legacy = true;
      final archive = Archive();
      for (final MapEntry(key: path, value: contents) in f.target.entries) {
        final bytes = utf8.encode(contents);
        archive.addFile(ArchiveFile(path, bytes.length, bytes));
      }
      f.bytes = ZipEncoder().encode(archive);
      await f.apply((transfer) {
        expect(transfer.files, isNull);
        expect(transfer.bytes, f.bytes.length);
      });
      expect(f.fullRequests, 1);
      expect(f.requests, isEmpty);
      expect(
        await File('${f.ready.path}/${f.edition.executable}').exists(),
        isTrue,
      );
    },
  );

  test(
    'a wrong-edition index is rejected before requesting any ZIP bytes',
    () async {
      final f = _Fixture(OculumRlEdition.normal);
      await f.setup();
      final wrong = jsonDecode(utf8.decode(f.index)) as Map;
      wrong['edition'] = 'test';
      f.index = utf8.encode(jsonEncode(wrong));
      await expectLater(f.apply((_) {}), throwsFormatException);
      expect(f.requests, isEmpty);
      expect(f.fullRequests, 0);
      expect(await f.updates.list().isEmpty, isTrue);
    },
  );

  test('a changed file with the wrong hash never becomes ready', () async {
    final f = _Fixture(OculumRlEdition.normal);
    await f.setup();
    f.corruptPath = 'data/added.txt';
    await expectLater(f.apply((_) {}), throwsFormatException);
    expect(await f.updates.list().isEmpty, isTrue);
    expect(await File('${f.installed.path}/data/app.so').readAsString(), 'old');
  });
}
