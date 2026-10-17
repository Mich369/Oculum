import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/widgets/oculum_art_button.dart';
import 'package:oculum/widgets/oculum_goth_ornaments.dart';
import 'package:oculum/widgets/oculum_theme_identity.dart';
import 'package:oculum/widgets/oculum_theme_asset_packs.dart';
import 'package:oculum/widgets/oculum_theme_presentation.dart';
import 'package:oculum/widgets/oculum_theme_sheet_art.dart';

void main() {
  testWidgets('theme identity gallery uses the real shared Flutter controls', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await (FontLoader(
        'OculumPreview',
      )..addFont(rootBundle.load('assets/fonts/Poppins-Regular.ttf'))).load();
      await (FontLoader(
        'OculumPreviewHeading',
      )..addFont(rootBundle.load('assets/fonts/Cinzel.ttf'))).load();
    });
    tester.view.physicalSize = const Size(1920, 1280);
    tester.view.devicePixelRatio = 1;
    final previous = oculumThemePresentation.value;
    oculumThemePresentation.value = const OculumThemePresentation(
      motion: OculumThemeMotion.disabled,
    );
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      oculumThemePresentation.value = previous;
    });
    const ids = [
      'restyle_legno',
      'restyle_cenere',
      'restyle_sogno',
      'element_pack_fuoco',
      'element_pack_lunare',
      'element_pack_solare',
      'canva_ice',
      'canva_spirit',
      'vervain_gothic',
      'blood_court',
      'funeral_clockwork',
      'abyssal_tide',
    ];
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RepaintBoundary(
            key: const ValueKey('gallery'),
            child: GridView.count(
              crossAxisCount: 4,
              childAspectRatio: 1.18,
              padding: const EdgeInsets.all(12),
              children: [
                for (final id in ids)
                  Builder(
                    builder: (context) {
                      final identity = oculumThemeIdentities[id]!;
                      final family = switch (identity.material) {
                        'wood' => OculumGothFamily.wood,
                        'ash' => OculumGothFamily.ash,
                        'bark' => OculumGothFamily.botanical,
                        'charred' => OculumGothFamily.ember,
                        'dream' => OculumGothFamily.dream,
                        'spirit' => OculumGothFamily.spirit,
                        'astral' => OculumGothFamily.astral,
                        'water' => OculumGothFamily.tide,
                        'crystal' => OculumGothFamily.crystal,
                        _ => OculumGothFamily.forged,
                      };
                      final accent = switch (identity.material) {
                        'charred' => const Color(0xFFEDA36C),
                        'dream' => const Color(0xFFD5B5E4),
                        'bark' => const Color(0xFFADBF9D),
                        'water' => const Color(0xFF9DC9D0),
                        _ => const Color(0xFFD9D0C0),
                      };
                      final theme = oculumWithArtButtons(
                        ThemeData.dark().copyWith(
                          textTheme: ThemeData.dark().textTheme.apply(
                            fontFamily: 'OculumPreview',
                          ),
                          colorScheme: ColorScheme.fromSeed(
                            seedColor: accent,
                            brightness: Brightness.dark,
                          ),
                          extensions: [
                            OculumGothOrnaments(
                              family: family,
                              ink: const Color(0xFF101016),
                              accent: accent,
                              opacity: .7,
                              motion: false,
                              themeId: id,
                            ),
                          ],
                        ),
                      );
                      return Padding(
                        padding: const EdgeInsets.all(9),
                        child: Theme(
                          data: theme,
                          child: OculumThemeSheetFrame(
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF121218),
                                image: DecorationImage(
                                  image: AssetImage(identity.surface),
                                  repeat: ImageRepeat.repeat,
                                  opacity: .10,
                                ),
                              ),
                              padding: const EdgeInsets.all(25),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    oculumThemeAssetPacks[id]!.name,
                                    style: TextStyle(
                                      color: accent,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'OculumPreviewHeading',
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    identity.motif,
                                    maxLines: 2,
                                    style: const TextStyle(
                                      color: Color(0xFFE6DFD5),
                                      fontFamily: 'OculumPreview',
                                      fontSize: 13,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'Vita e scudo   140 / 180',
                                    style: TextStyle(
                                      color: accent,
                                      fontFamily: 'OculumPreview',
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  LinearProgressIndicator(
                                    value: .78,
                                    color: accent,
                                    backgroundColor: const Color(0xFF25252D),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'RES 14     VOL 5     MAT 8     OCU 0',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontFamily: 'OculumPreview',
                                      color: Color(0xFFE6DFD5),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: FilledButton(
                                          onPressed: () => taps++,
                                          child: const Text('VC · Attacco'),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => taps++,
                                          child: const Text('CM · Difesa'),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  const OutlinedButton(
                                    onPressed: null,
                                    child: Text('Azione non disponibile'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('VC · Attacco').first);
    expect(taps, 1);
    await tester.pump(const Duration(milliseconds: 400));
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('gallery')),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('build/theme-identity-gallery.png');
      file.writeAsBytesSync(png!.buffer.asUint8List());
      image.dispose();
    });
  });
}
