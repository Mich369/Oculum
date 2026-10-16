import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/widgets/oculum_goth_ornaments.dart';
import 'package:oculum/widgets/oculum_theme_asset_packs.dart';
import 'package:oculum/widgets/oculum_theme_presentation.dart';
import 'package:oculum/widgets/oculum_theme_sheet_art.dart';

void main() {
  const ids = ['buried_herbarium', 'funeral_clockwork', 'tidal_stained_glass'];
  test('new themes ship distinct editable artwork and all button states', () {
    final signatures = <String>{};
    for (final id in ids) {
      final pack = oculumThemeAssetPacks[id]!;
      final source = File(
        'design/themes/$id/panel-alive.svg',
      ).readAsStringSync();
      expect(source, isNot(contains('<text')));
      signatures.add(source);
      for (final state in [
        'normal',
        'hover',
        'pressed',
        'selected',
        'disabled',
      ]) {
        expect(File(pack.buttonFrame(state)).lengthSync(), greaterThan(100));
      }
      expect(
        File(pack.frame('panel', variant: 'still')).readAsBytesSync(),
        isNot(File(pack.frame('panel', variant: 'alive')).readAsBytesSync()),
      );
    }
    expect(signatures.length, ids.length);
  });

  testWidgets(
    'new frames preserve taps and bounds in both screen orientations',
    (tester) async {
      final previous = oculumThemePresentation.value;
      addTearDown(() {
        oculumThemePresentation.value = previous;
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1;
      for (final size in [
        const Size(390, 844),
        const Size(1920, 1080),
        const Size(1080, 1920),
      ]) {
        tester.view.physicalSize = size;
        for (final id in ids) {
          var taps = 0;
          oculumThemePresentation.value = OculumThemePresentation(
            motion: OculumThemeMotion.disabled,
            artPackId: id,
          );
          await tester.pumpWidget(
            MaterialApp(
              theme: ThemeData.dark().copyWith(
                extensions: [
                  OculumGothOrnaments(
                    family: OculumGothFamily.wood,
                    ink: Colors.brown,
                    accent: Colors.amber,
                    opacity: .5,
                    themeId: id,
                  ),
                ],
              ),
              home: Scaffold(
                body: Center(
                  child: OculumThemeSheetFrame(
                    child: SizedBox(
                      width: 300,
                      height: 160,
                      child: Center(
                        child: TextButton(
                          onPressed: () => taps++,
                          child: const Text('Attacco'),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pump();
          expect(
            tester.getSize(find.byType(OculumThemeSheetFrame)),
            const Size(300, 160),
          );
          await tester.tap(find.text('Attacco'));
          expect(taps, 1, reason: '$id at $size');
          expect(tester.takeException(), isNull, reason: '$id at $size');
        }
      }
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
