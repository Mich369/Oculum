import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/widgets/oculum_goth_ornaments.dart';
import 'package:oculum/widgets/oculum_theme_sheet_art.dart';
import 'oculum_theme_effects_portrait_test.dart' as fixtures;

void main() {
  testWidgets('Tall sheet backgrounds preserve decorative strip proportions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark().copyWith(
          extensions: const [
            OculumGothOrnaments(
              family: OculumGothFamily.ash,
              ink: Colors.black,
              accent: Colors.grey,
              opacity: 1,
              themeId: 'restyle_cenere',
            ),
          ],
        ),
        home: const Scaffold(
          body: SizedBox(
            width: 390,
            height: 800,
            child: OculumThemeSheetScene(fillArea: true),
          ),
        ),
      ),
    );
    await tester.pump();
    final scenes = tester.widgetList<Image>(find.byType(Image)).where((image) {
      final provider = image.image is ResizeImage
          ? (image.image as ResizeImage).imageProvider
          : image.image;
      return provider is AssetImage &&
          provider.assetName.contains('/decorations/scene');
    });
    expect(scenes, hasLength(1));
    expect(scenes.single.fit, BoxFit.contain);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Skill catalogue and editor use the same desktop page width', (
    tester,
  ) async {
    final state = await fixtures.mountSheet(tester, const Size(1440, 900));
    final probe = OculumPerformanceProbe(state);
    final pageKey = GlobalKey();
    final entry = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: Material(key: pageKey, child: probe.skillsPage()),
      ),
    );
    Overlay.of(tester.element(find.byType(OculumHomePage))).insert(entry);
    await tester.pump();
    final page = find.byKey(pageKey);
    final catalogue = find.descendant(
      of: page,
      matching: find.widgetWithText(
        OutlinedButton,
        'Scegli abilità dal catalogo',
      ),
    );
    final name = find.descendant(
      of: page,
      matching: find.byWidgetPredicate(
        (w) => w is TextField && w.controller == state.skillNomeController,
      ),
    );
    expect(tester.getSize(catalogue).width, greaterThan(1000));
    expect(tester.getSize(name).width, greaterThan(1000));
    entry.remove();
    entry.dispose();
    probe.cancelPendingSave();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
  testWidgets(
    'Fallen Eye growth excludes source base stats and labels have space',
    (tester) async {
      final state = await fixtures.mountSheet(tester, const Size(1440, 900));
      final probe = OculumPerformanceProbe(state);
      for (
        var attempt = 0;
        attempt < 100 && state.datiCaricati != true;
        attempt++
      ) {
        await tester.pump(const Duration(milliseconds: 20));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
      }
      probe.load({
        'nome': 'Slime Roccioso',
        'livello': '0',
        'grado': '0',
        'resilienza': '14',
        'volonta': '5',
        'materia': '8',
        'oculum': '0',
        'currentResilienza': '14',
        'currentVolonta': '5',
        'currentMateria': '8',
        'currentOculum': '0',
        'currentHp': '140',
      });
      probe.saveSheet();
      unawaited(probe.showCreateFallenEye());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      Finder field(String label) => find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == label,
      );
      await tester.enterText(field('Livello'), '1');
      await tester.pump();
      expect(find.textContaining('mancano 9 punti'), findsOneWidget);
      expect(find.textContaining('27 punti'), findsOneWidget);
      final nameBounds = tester.getRect(field('Nome del mostro'));
      final levelBounds = tester.getRect(field('Livello'));
      expect(levelBounds.top - nameBounds.bottom, greaterThanOrEqualTo(15));
      final hpBounds = tester.getRect(field('Vita'));
      final oculumBounds = tester.getRect(field('Oculum'));
      expect(oculumBounds.top - hpBounds.bottom, greaterThanOrEqualTo(15));
      await tester.tap(find.text('Annulla'));
      await tester.pump(const Duration(milliseconds: 350));
      probe.cancelPendingSave();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    },
  );
}
