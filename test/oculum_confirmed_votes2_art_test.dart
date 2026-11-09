import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'package:oculum/widgets/oculum_monster_theme.dart';
import 'package:pointycastle/digests/sha256.dart';

import 'support/oculum_monster_art_bundle.dart';

String digest(Uint8List value) => SHA256Digest()
    .process(value)
    .map((x) => x.toRadixString(16).padLeft(2, '0'))
    .join();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final receipt =
      jsonDecode(
            File(
              'design/approved-monster-desktops-2026-11-06-votes2.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  final files = (receipt['files'] as List).cast<Map<String, dynamic>>();

  test(
    '55 approved originals are preserved and their runtime artwork is bundled',
    () async {
      expect(files, hasLength(55));
      expect(files.map((x) => x['id']).toSet(), hasLength(55));
      for (final row in files) {
        final id = row['id'] as String;
        final entry = monsterBookEntryById(id);
        expect(entry, isNotNull, reason: id);
        final theme = OculumMonsterTheme(
          entry!,
          oculumMonsterColors(entry).first,
        );
        final canonical = row['asset'] as String;
        expect(
          theme.illustration,
          oculumMonsterArtworkAsset(canonical),
          reason: id,
        );
        expect(theme.preserveIllustrationFraming, isTrue, reason: id);
        await expectBundledMonsterArt(canonical);
        expect(
          digest(File(canonical).readAsBytesSync()),
          row['nativeSha256'],
          reason: id,
        );
      }
    },
  );

  test('approved revisions replace holds; Cyclops v4 is approved', () {
    final byId = {for (final r in files) r['id']: r};
    for (final id in [
      'ciclo_scarabeo_sigillo_ardente',
      'demone_glaciale_intermedio',
      'demone_intermedio',
      'weak_horror_lacrimante',
      'ciclo_guardiano_dodici_rintocchi',
    ]) {
      expect(byId[id]?['approvedRevision'], isTrue, reason: id);
    }
    expect(
      byId['ciclope_del_fato']?['nativeSha256'],
      '8c2da1fdadb33ddc8551404ee2490251ecf35678b87b10419b206426e0ecf722',
    );
    expect(receipt['heldIds'], isEmpty);
    expect(
      byId['ciclo_guardiano_dodici_rintocchi']?['nativeSha256'],
      '9ff4622da79dbcef2428626fca12c5a4b7309783be85ade3a3b77dec7dda62f3',
    );
  });
}
