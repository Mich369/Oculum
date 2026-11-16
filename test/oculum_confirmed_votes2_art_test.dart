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
        final current = switch (id) {
          'armaiolo_della_fila_lunga_variante_rituale' ||
          'bambola_vapium_variante_veterana' ||
          'demone_glaciale_minore' =>
            'assets/oculum/home_art_authored/theme_${id}_canon_20261115.webp',
          'ciclope_del_fato' =>
            'assets/oculum/home_art_authored/theme_ciclope_del_fato_canon_20261107.webp',
          _ => canonical,
        };
        expect(
          theme.illustration,
          oculumMonsterArtworkAsset(current),
          reason: id,
        );
        expect(theme.preserveIllustrationFraming, isTrue, reason: id);
        await expectBundledMonsterArt(canonical);
        if (current != canonical) await expectBundledMonsterArt(current);
        expect(
          digest(File(canonical).readAsBytesSync()),
          row['nativeSha256'],
          reason: id,
        );
      }
    },
  );

  test('the earlier approvals retain their exact archived artwork', () {
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

  test(
    'Bunnys desktop uses its own approved ears and shows no wings',
    () async {
      final bunny = monsterBookEntryById('bunnys')!;
      final parts = oculumMonsterPrecisionAnatomy(bunny);
      final theme = OculumMonsterTheme(bunny, oculumMonsterColors(bunny).first);
      const art =
          'assets/oculum/home_art_authored/theme_bunnys_canon_20261107.webp';
      expect(theme.illustration, art);
      expect(theme.preserveIllustrationFraming, isTrue);
      expect(parts.where((part) => part['group'] == 'ears'), hasLength(2));
      expect(parts.where((part) => part['group'] == 'legs'), hasLength(4));
      expect(parts.where((part) => part['group'] == 'wings'), isEmpty);
      await expectBundledMonsterArt(art);
    },
  );

  test('the Fate Cyclops has two independently targetable wings', () {
    final cyclops = monsterBookEntryById('ciclope_del_fato')!;
    final parts = oculumMonsterPrecisionAnatomy(cyclops);
    final wings = parts.where((part) => part['group'] == 'wings');
    expect(wings.map((part) => part['side']).toSet(), {'left', 'right'});
    expect(parts.where((part) => part['group'] == 'eyes'), hasLength(1));
    expect(parts.where((part) => part['group'] == 'ears'), hasLength(2));
    const savedParts = [
      {'id': 'custom_part', 'group': 'body', 'label': 'Parte personale'},
    ];
    expect(
      oculumMonsterPrecisionAnatomy(
        cyclops.copyWith(encounterRules: {'precisionBodyParts': savedParts}),
      ),
      savedParts,
    );
  });
}
