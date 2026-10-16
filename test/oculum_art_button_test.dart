import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/widgets/oculum_art_button.dart';
import 'package:oculum/widgets/oculum_combat_theme.dart';
import 'package:oculum/widgets/oculum_theme_asset_packs.dart';

void main() {
  testWidgets('compact icon frames fit without changing tap bounds', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              for (final size in [12.0, 24.0, 32.0, 44.0])
                SizedBox(
                  width: size,
                  height: size,
                  child: const OculumArtButtonLayer(
                    states: {},
                    child: SizedBox.expand(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  test('every pack ships transparent nine-slice button states', () async {
    for (final pack in oculumThemeAssetPacks.values) {
      for (final state in [
        'normal',
        'hover',
        'pressed',
        'selected',
        'disabled',
      ]) {
        final file = File(pack.buttonFrame(state));
        expect(file.existsSync(), isTrue, reason: '${pack.id}/$state');
        final codec = await ui.instantiateImageCodec(await file.readAsBytes());
        final image = (await codec.getNextFrame()).image;
        final pixels = (await image.toByteData(
          format: ui.ImageByteFormat.rawStraightRgba,
        ))!;
        expect(image.width, 1024);
        expect(image.height, 512);
        expect(
          pixels.getUint8((256 * 1024 + 512) * 4 + 3),
          0,
          reason: 'Reading center',
        );
        image.dispose();
        codec.dispose();
      }
    }
  });

  testWidgets(
    'native buttons retain keyboard activation and disabled behavior',
    (tester) async {
      var count = 0;
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: oculumWithArtButtons(ThemeData.dark()),
          home: Scaffold(
            body: Column(
              children: [
                TextButton(
                  focusNode: focus,
                  onPressed: () => count++,
                  child: const Text('Act'),
                ),
                const TextButton(onPressed: null, child: Text('Disabled')),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      focus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(count, 1);
      await tester.tap(find.text('Disabled'));
      expect(count, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'combat dominance changes shared PNG without replacing the action',
    (tester) async {
      addTearDown(
        () => oculumCombatTheme.value = const OculumCombatThemeState(),
      );
      var count = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: oculumWithArtButtons(ThemeData.dark()),
          home: Scaffold(
            body: TextButton(
              onPressed: () => count++,
              child: const Text('Act'),
            ),
          ),
        ),
      );
      oculumCombatTheme.value = const OculumCombatThemeState(
        automatic: true,
        elementId: 'fuoco',
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('button-art-element_pack_fuoco-normal')),
        findsOneWidget,
      );
      oculumCombatTheme.value = const OculumCombatThemeState(
        automatic: true,
        elementId: 'fisico',
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('button-art-canva_physical-normal')),
        findsOneWidget,
      );
      await tester.tap(find.text('Act'));
      expect(count, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
