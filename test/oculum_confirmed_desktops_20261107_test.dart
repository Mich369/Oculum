import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'package:oculum/widgets/oculum_goth_ornaments.dart';
import 'package:oculum/widgets/oculum_monster_theme.dart';
import 'package:oculum/widgets/oculum_narrative_background.dart';
import 'package:oculum/widgets/oculum_theme_sheet_art.dart';
import 'package:pointycastle/digests/sha256.dart';

const _receipt = 'design/approved-monster-desktops-2026-11-07-votes3.json';
const _previousReceipt = 'design/approved-monster-desktops-2026-11-06-votes2.json';

String _sha256(Uint8List bytes) => SHA256Digest()
    .process(bytes)
    .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
    .join();

OculumMonsterTheme _themeFor(String id) {
  final entry = monsterBookEntryById(id)!;
  return OculumMonsterTheme(entry, oculumMonsterColors(entry).first);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('exact approved desktop PNGs are bundled and selected by ID', () async {
    final receipt =
        jsonDecode(File(_receipt).readAsStringSync()) as Map<String, dynamic>;
    final files = (receipt['files'] as List).cast<Map<String, dynamic>>();
    expect(files, hasLength(18));
    expect(files.map((file) => file['id']).toSet(), hasLength(files.length));
    expect(receipt['heldIds'], isEmpty);
    final king = files.singleWhere((file) => file['id'] == 'king_slime');
    expect(king['letter'], 'A');
    expect(king['approvedRevision'], isTrue);
    expect(
      king['nativeSha256'],
      '3455eccff020389fe88ea49c6d1a28b09c42fc1689fafd55290eda3cd4967494',
    );
    for (final file in files) {
      final id = file['id'] as String;
      final asset = file['asset'] as String;
      final sha = file['nativeSha256'] as String;
      final bytes = File(asset).readAsBytesSync();
      expect(bytes.take(8), [137, 80, 78, 71, 13, 10, 26, 10], reason: id);
      expect(bytes.length, file['bytes'], reason: id);
      expect(_sha256(bytes), sha, reason: id);
      final bundled = await rootBundle.load(asset);
      expect(
        _sha256(
          bundled.buffer.asUint8List(
            bundled.offsetInBytes,
            bundled.lengthInBytes,
          ),
        ),
        sha,
        reason: id,
      );
      final theme = _themeFor(id);
      expect(theme.illustration, asset, reason: id);
      expect(theme.preserveIllustrationFraming, isTrue, reason: id);
      expect(theme.illustrationMobile, isNull, reason: id);
      expect(theme.relicIllustration, isNull, reason: id);
    }
  });

  test('the base Bandito and its Errante retain separate art', () {
    const base = 'habitat_mezzano_bandito_della_maschera_di_corteccia';
    expect(
      _themeFor(base).illustration,
      'assets/oculum/home_art/theme_${base}_canon_20261107_votes3.png',
    );
    expect(
      _themeFor('${base}_variante_errante').illustration,
      'assets/oculum/home_art/theme_${base}_variante_errante_canon_20261106_votes2.png',
    );
    expect(
      _sha256(File(_previousReceipt).readAsBytesSync()),
      '6a6a0ef490e7fa532d018ad78ae63d023450d1227ef478c703de1540f9d009be',
    );
  });

  for (final width in [320.0, 834.0, 1440.0]) {
    testWidgets('reference sheet preserves the chosen artwork at $width px', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const sheetId = 'sentinella-approved-art';
      const asset =
          'assets/oculum/home_art/theme_inspired_sentinella_spirale_canon_20261107_votes3.png';
      final theme = _themeFor('inspired_sentinella_spirale');
      final previous = oculumSheetMonsterThemes.value;
      oculumSheetMonsterThemes.value = {sheetId: theme.id};
      addTearDown(() => oculumSheetMonsterThemes.value = previous);

      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            extensions: const [
              OculumGothOrnaments(
                family: OculumGothFamily.crystal,
                ink: Colors.white,
                accent: Colors.amber,
                opacity: .3,
                themeId: 'classic_reliquary',
              ),
            ],
          ),
          home: Scaffold(
            body: Stack(
              fit: StackFit.expand,
              children: [
                const OculumNarrativeBackground(sheetId: sheetId),
                OculumThemeSheetBackdrop(
                  sheetId: sheetId,
                  child: SingleChildScrollView(
                    child: FilledButton(
                      onPressed: () => taps++,
                      child: const Text('Usa'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final narrative = find.byKey(ValueKey('narrative-background-${theme.id}'));
      final backdrop = find.descendant(
        of: find.byKey(ValueKey('monster-scene-${theme.id}')),
        matching: find.byType(Image),
      );
      for (final layer in [narrative, backdrop]) {
        final image = tester.widget<Image>(layer);
        final provider = image.image;
        final source = provider is ResizeImage ? provider.imageProvider : provider;
        expect((source as AssetImage).assetName, asset);
        expect(image.fit, BoxFit.contain);
        expect(image.alignment, Alignment.centerRight);
      }
      await tester.tap(find.text('Usa'));
      expect(taps, 1);
      expect(tester.takeException(), isNull);
    });
  }
}
