import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'package:oculum/widgets/oculum_custom_theme.dart';
import 'package:oculum/widgets/oculum_goth_ornaments.dart';
import 'package:oculum/widgets/oculum_monster_book_page.dart';
import 'package:oculum/widgets/oculum_monster_theme.dart';
import 'package:oculum/widgets/oculum_narrative_background.dart';
import 'package:oculum/widgets/oculum_theme_presentation.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Native ImageGen PNG digests from the selected immutable source receipts.
// JPEG gallery previews are not substituted for the selected originals.
const _nativeDesktopShaById = <String, String>{
  'basilisco_base':
      'c357f45c38a5d4dcec0116aecf48982d1a81ed8a19784788e45e70061e51b812',
  'capitano_della_ruggine':
      'd2d6c7b59a4b45f6bcf0aeca18a39d52fba33e01c89bfadff30d09fb4496b890',
  'coniglio_plasma':
      'b05df84f8b88c6743f13a8928b24875f4fec8eb9ffebab833bc0e9a576a2b7b1',
  'araldo_bozzoli':
      '6b17a130332fce847350f3ceef7275a3c9d9e1b409e95260761f3b18a4ccff04',
  'base_ghiaccio_02':
      '5ba6eeed17e9e1f403067ab15cbbd2c445c759744cf7dfa47577ce408a783abf',
  'lumaca_assassina':
      '4b3884151f3d11c64d219257299c0d6c4004353f4acc2e1c0a1c69209801af53',
  'base_postea_07':
      'd9f9031c80507eb85ab188bb535d492407fe5d293d9defe9001fdc5b9c96981f',
  'habitat_morti_becchino_dalle_mani_lunghe':
      'f1ff5c662cc33828b115a8d430c4bd1543fac79792fbcff2ada344afe3e489c5',
  'bandito_base':
      'f89baa4d8daf9e0a3a94ca4b880ea58cf9f4c7150eea6e82b63376552aa21785',
  'base_nuvole_07':
      'd9770dfcfd25319bd30b23ac8abb138d9ef15c905615b03c317cf73412369149',
  'arpia_base':
      '4543bc4b88204174a313c156663bc68bd1dd5e7611fcba3be0a26499f67867e0',
  'habitat_vero_inferno_araldo_della_cenere_eterna':
      '54ca480fb5c1a4c89de4e8fe9cdf5c2849880de22c6e82ad3020a096c8069567',
  'weak_horror_ciste':
      '13f88116ba026fd75486bdd6dc10483484dda6c4b98c0bb1e6c39380417f73e7',
  'ciclo_custode_nastri_sospesi':
      '56285c6d1acf7a94470423851d79ab6804c8ae3bcd173a9a146262619d5b1914',
  'habitat_affogato_anguilla_delle_campane_sommerse':
      '4a9a361802669bbe743f4a7116414a7d834ad75e2b4b3513b317d65e9617747b',
  'ciclo_cavaliere_filo_oro':
      '8b5b86f3786853f718bc2afe7bb5ed2ebb6b870eabbaf9f40bad4fad6d6cde69',
  'quadribrachio_ambra':
      'f746ad5858e334c7939bbc08fbb31c4c3374d72ee73d5d3752355514ae1a791b',
  'topo_con_mani':
      '062100de991437799745446456ba798bc935c4c330bae1ce6e17709b72f5abfa',
  'marshmallow':
      '684172f8783a3697f8752ac1c65090e90efca453a3f6889061f0e2e479f4c3f0',
  'serafino_angelico':
      '8f9575f4b3aae431f5b9b11d72d2312587a3efc30b2f4d3597e3b0a464e13eb9',
  'habitat_ghiaccio_falena_della_neve_nera':
      '43180af2c735e877b1aaedfb3253f83f3ff8fb13c4c62a38a87ab533da0ab73a',
  'gigante_comune':
      'e832ec9d90c6a7cbdb4d0e3ac45759b1664e0d51274bc6ef189addc0e9a30002',
  'gigante_comune_variante_massiccia':
      '0cdd9bb660d12baca73819a14adb3c150c6e68109d7b125931a6cba116b60286',
  'inspired_pipistrello_cavernicolo':
      'a58f92b3476b68c7d3ceebd914d5df981509a78f3567bc711b8685eb11c79690',
  'ciclo_guardiano_dodici_rintocchi':
      'ed5545b262118185425a4e851cbdb0b1bb339d5456c0bb16b4c2b685a0bd559d',
  'snorlo': '1a7014ee03d76017658c5194561c552c9ff4a590e500e9f3a292958dab014799',
  'weak_horror_portalanterna':
      '503c9585133feeac5b348b3ebd3636dea9b2eeebf99bf5c6aa20260aee491ae3',
  'weak_horror_cucitore':
      '9f5eb969750d98a60ae6dc6fe1443b1f6ac6681c01aee218527c855077d6592f',
  'ciclo_melma_null':
      '11ec572a8420d9c4d0a887845bbcd50bc2038888bc4f28e9c5e2fdd770bec351',
  'serafino_solare':
      '43eb14cb21ac32b0aee71973e2f5d9a36e8131b98d4720e59c932dd5aecd3f85',
  'ciclo_golem_brina_profonda':
      '8de7b54aa46a5a0b43167a414f534acceb987ceb8b2f17fa84e0cc9df9554cce',
  'ciclo_araldo_sei_albe':
      'e85696949afdc2a6c32a5b439b72f3e00f079736a75ad099a0b0544d5c15e3e9',
  'ciclo_porcello_fango_grasso':
      '6fedec0bd5111833f3b1e9ae908a7b0985da3e01cd4920eb5072f96f87e7291c',
  'ciclo_solare_siccita':
      '760f64b0e0318a39abfe8f1c2cd08bd4ed1dbb8bc4149c01259edadb039ff260',
  'araldo_raggio_angelico':
      '641c88556b87270d23e7e09de2f8a5b03e046566fc90ef0742a4d1b21f76fb43',
  'angelo_palpebra_sporca':
      '2eb6f9aabee9b4a2a994793c546fbbab38697ac64663f2094168ad818fc836b5',
  'black_dragon_shield':
      '4ac2d40cabf8c231a6cff8e85e139657edf81d6149cded1862145d791fd8e44c',
};
const _pendingBellCountId = 'ciclo_guardiano_dodici_rintocchi';

String _assetFor(String id) =>
    'assets/oculum/home_art/theme_${id}_canon_20261106.png';

OculumMonsterTheme _themeFor(String id) {
  final entry = monsterBookEntryById(id)!;
  return OculumMonsterTheme(entry, oculumMonsterColors(entry).first);
}

String _sha256(Uint8List bytes) => SHA256Digest()
    .process(bytes)
    .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
    .join();

Future<Uint8List> _tinyCustomPng() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawColor(const Color(0xff248e66), BlendMode.src);
  final picture = recorder.endRecording();
  final image = await picture.toImage(2, 2);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  return data!.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final originalPresentation = oculumThemePresentation.value;
  final originalSelections = oculumSheetRelicSelections.value;
  final originalAutomatic = oculumSheetMonsterThemes.value;
  final originalCustomArtwork = oculumCustomArtwork.value;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    oculumThemePresentation.value = const OculumThemePresentation(
      motion: OculumThemeMotion.disabled,
    );
    oculumSheetRelicSelections.value = {};
    oculumSheetMonsterThemes.value = {};
    oculumCustomArtwork.value = {};
  });
  tearDown(() {
    oculumThemePresentation.value = originalPresentation;
    oculumSheetRelicSelections.value = originalSelections;
    oculumSheetMonsterThemes.value = originalAutomatic;
    oculumCustomArtwork.value = originalCustomArtwork;
  });

  test('37 native PNG copies retain exact selected source bytes', () async {
    expect(_nativeDesktopShaById, hasLength(37));
    for (final entry in _nativeDesktopShaById.entries) {
      final asset = _assetFor(entry.key);
      final bytes = File(asset).readAsBytesSync();
      expect(bytes.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
      expect(_sha256(bytes), entry.value, reason: entry.key);
      final bundled = await rootBundle.load(asset);
      expect(
        _sha256(
          bundled.buffer.asUint8List(
            bundled.offsetInBytes,
            bundled.lengthInBytes,
          ),
        ),
        entry.value,
        reason: 'The native file must also be in the Flutter asset bundle.',
      );
    }
  });

  test('36 desktop defaults link without claiming new phone or relic art', () {
    var linked = 0;
    for (final id in _nativeDesktopShaById.keys) {
      final theme = _themeFor(id);
      if (id == _pendingBellCountId) {
        expect(
          theme.illustration,
          'assets/oculum/home_art/theme_${id}_canon_20261106_votes2.png',
          reason:
              'The subsequently approved twelve-bell revision replaces the held ten-bell draft.',
        );
      } else {
        linked++;
        expect(theme.illustration, _assetFor(id));
        expect(theme.preserveIllustrationFraming, isTrue);
      }
      expect(
        theme.illustrationMobile,
        isNull,
        reason: 'No new mobile derivative was generated or approved.',
      );
      expect(
        theme.relicIllustration,
        isNull,
        reason: 'Keep vector fallback until a relic is approved.',
      );
    }
    expect(linked, 36);
    expect(
      _themeFor('gigante_comune').illustration,
      isNot(_themeFor('gigante_comune_variante_massiccia').illustration),
    );
    expect(
      _themeFor('fire_shield').illustration,
      'assets/oculum/home_art/theme_fire_shield_canon_20261101.png',
    );
  });

  test('saved sheet theme and custom portraits retain their data', () async {
    SharedPreferences.setMockInitialValues({
      'oculum.sheetRelicSelections': jsonEncode({
        'saved-sheet': 'classic_reliquary',
      }),
    });
    oculumSheetMonsterThemes.value = {
      'saved-sheet': _themeFor('basilisco_base').id,
    };
    await loadOculumThemePresentation();
    expect(
      oculumThemePresentationForSheet('saved-sheet').artPackId,
      'classic_reliquary',
    );
    final prefs = await SharedPreferences.getInstance();
    expect(jsonDecode(prefs.getString('oculum.sheetRelicSelections')!), {
      'saved-sheet': 'classic_reliquary',
    });
    final customEntry = monsterBookEntryById('basilisco_base')!.copyWith(
      spriteAssetPath: 'user-authored/retained-sprite.png',
      imageBase64: base64Encode([11, 22, 33]),
    );
    final before = jsonEncode(customEntry.toJson());
    final theme = OculumMonsterTheme(
      customEntry,
      oculumMonsterColors(customEntry).last,
    );
    expect(theme.illustration, _assetFor('basilisco_base'));
    expect(jsonEncode(customEntry.toJson()), before);
    expect(theme.color.id, oculumMonsterColors(customEntry).last.id);
  });

  for (final width in [320.0, 834.0, 1440.0]) {
    testWidgets(
      'desktop fallback at $width keeps whole artwork and active controls',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var taps = 0;
        for (final id in [
          'capitano_della_ruggine',
          'basilisco_base',
          'gigante_comune',
          'gigante_comune_variante_massiccia',
        ]) {
          final theme = _themeFor(id);
          oculumSheetRelicSelections.value = {'native-preview': theme.id};
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
                  children: [
                    const Positioned.fill(
                      child: OculumNarrativeBackground(
                        sheetId: 'native-preview',
                      ),
                    ),
                    Center(
                      child: FilledButton(
                        onPressed: () => taps++,
                        child: const Text('Usa'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
          final image = tester.widget<Image>(find.byType(Image).first);
          final provider = image.image is ResizeImage
              ? (image.image as ResizeImage).imageProvider
              : image.image;
          expect((provider as AssetImage).assetName, _assetFor(id));
          expect(image.fit, BoxFit.contain);
          await tester.runAsync(
            () => precacheImage(
              image.image,
              tester.element(find.byType(Image).first),
            ),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
          final before = taps;
          await tester.tap(find.text('Usa'));
          expect(taps, before + 1);
          await tester.pumpWidget(const SizedBox.shrink());
          PaintingBinding.instance.imageCache.clear();
          PaintingBinding.instance.imageCache.clearLiveImages();
        }
      },
    );
  }

  testWidgets('purchased page uses background without a portrait', (
    tester,
  ) async {
    final entry = monsterBookEntryById('basilisco_base')!;
    expect(entry.spriteAssetPath, isEmpty);
    expect(entry.imageBase64, isEmpty);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OculumMonsterBookPage(
            monster: entry,
            purchased: true,
            child: const Text('Scheda'),
          ),
        ),
      ),
    );
    final image = tester.widget<Image>(
      find.byKey(const ValueKey('monster-page-art-basilisco_base')),
    );
    expect((image.image as AssetImage).assetName, _assetFor(entry.id));
    expect(image.fit, BoxFit.contain);
    expect(find.text('Scheda'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  testWidgets('theme scope composites custom artwork exactly once', (
    tester,
  ) async {
    final bytes = await tester.runAsync(_tinyCustomPng);
    oculumCustomArtwork.value = {
      'version': 1,
      'enabled': true,
      'layers': [
        {
          'image': base64Encode(bytes!),
          'x': .5,
          'y': .5,
          'size': .2,
          'opacity': .3,
          'rotation': 0,
        },
      ],
      'colors': <String, dynamic>{},
    };
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        builder: (_, child) => OculumThemeScope(child: child!),
        home: Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () => taps++,
              child: const Text('Custom'),
            ),
          ),
        ),
      ),
    );
    final layer = find.byType(OculumCustomArtworkLayer);
    expect(layer, findsOneWidget);
    expect(
      find.descendant(of: layer, matching: find.byType(Image)),
      findsOneWidget,
    );
    final opacity = tester.widget<Opacity>(
      find.descendant(of: layer, matching: find.byType(Opacity)).first,
    );
    expect(opacity.opacity, closeTo(.3, .000001));
    await tester.tap(find.text('Custom'));
    expect(taps, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });
}
