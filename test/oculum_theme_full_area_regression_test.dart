import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'package:oculum/widgets/oculum_goth_ornaments.dart';
import 'package:oculum/widgets/oculum_monster_theme.dart';
import 'package:oculum/widgets/oculum_theme_presentation.dart';
import 'package:oculum/widgets/oculum_theme_sheet_art.dart';
import 'oculum_theme_effects_portrait_test.dart' as fixtures;

void main() {
  for (final size in const [
    Size(1920, 1080),
    Size(1080, 1920),
    Size(390, 844),
  ]) {
    testWidgets('whole sheet background and safe frames at $size', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final fonts =
            jsonDecode(await rootBundle.loadString('FontManifest.json'))
                as List;
        for (final entry in fonts.cast<Map>()) {
          final loader = FontLoader(entry['family'] as String);
          for (final font in (entry['fonts'] as List).cast<Map>()) {
            loader.addFont(rootBundle.load(font['asset'] as String));
          }
          await loader.load();
        }
        await (FontLoader(
          'serif',
        )..addFont(rootBundle.load('assets/fonts/EBGaramond.ttf'))).load();
      });
      final previous = oculumThemePresentation.value;
      final selections = oculumSheetRelicSelections.value;
      addTearDown(() {
        oculumThemePresentation.value = previous;
        oculumSheetRelicSelections.value = selections;
      });
      final capture = GlobalKey();
      final dynamic state = await fixtures.mountSheet(
        tester,
        size,
        captureKey: capture,
      );
      final monster = monsterBookEntryById('guardia_solare_elite')!;
      final theme = OculumMonsterTheme(
        monster,
        oculumMonsterColors(monster).first,
      );
      oculumThemePresentation.value = previous.copyWith(
        motion: OculumThemeMotion.disabled,
      );
      state.updateOculumHomeUi(() {
        state.modalitaDesktop = size.width >= 600;
        state.nuovoDesignOculum = 'cattedrale';
        state.temiOldSchool = false;
        state.paginaCorrente = 0;
        state.referenceSheetSection = 'general';
        state.nomeController.text = 'Lusier III · prova interfaccia';
        if (state.schedePersonaggio.isEmpty) {
          state.schedePersonaggio.add(<String, dynamic>{
            'id': 'qa-theme-full-area',
            'sheetTag': 'qa-theme-full-area',
          });
          state.schedaCorrente = 0;
        }
        final Map<String, dynamic> sheet =
            state.schedePersonaggio[state.schedaCorrente];
        sheet['monsterBookSourceId'] = monster.id;
        sheet['relicArtPackId'] = theme.id;
        OculumPerformanceProbe(state).restoreCreatureAppearance(sheet);
      });
      oculumSheetRelicSelections.value = {
        state.currentSheetScrollId(): theme.id,
      };
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final images = find.byType(Image).evaluate().toList();
      await tester.runAsync(() async {
        await Future.wait(
          images.map((e) => precacheImage((e.widget as Image).image, e)),
        );
      });
      await tester.pump();

      final background = find.byKey(
        ValueKey('narrative-background-${theme.id}'),
      );
      expect(background, findsOneWidget);
      expect(tester.widget<Image>(background).fit, BoxFit.cover);
      if (size.height > size.width) {
        final image = tester.widget<Image>(background);
        final source = const Size(1536, 1024);
        final visible = applyBoxFit(
          BoxFit.cover,
          source,
          tester.getSize(background),
        ).source;
        final crop = image.alignment
            .resolve(TextDirection.ltr)
            .inscribe(visible, Offset.zero & source);
        expect(
          crop.center.dx / source.width,
          closeTo(.66, .005),
          reason:
              'The solar guard, rather than the far-right gate, stays centered.',
        );
      }
      final menu = find.byKey(const ValueKey('reference-sheet-side-menu'));
      if (size.width >= 600) {
        expect(menu, findsOneWidget);
        expect(
          tester.getRect(background).contains(tester.getCenter(menu)),
          isTrue,
        );
      }
      expect(
        find.byType(OculumThemeSheetScene),
        findsNothing,
        reason:
            'The sheet must not overlay a second, differently aligned scene.',
      );

      final title = find.text('Tiri e azioni');
      expect(title, findsOneWidget);
      final panels = find.ancestor(
        of: title,
        matching: find.byType(CustomPaint),
      );
      for (final element in panels.evaluate()) {
        final paint = element.widget as CustomPaint;
        final painter = paint.foregroundPainter ?? paint.painter;
        if (painter is! OculumGothPainter || !painter.panel) continue;
        final rect = tester.getRect(find.byWidget(paint));
        expect(
          tester.getRect(title).top - rect.top,
          greaterThanOrEqualTo(12),
          reason:
              'Decorative lines must sit outside the title, in its padded gutter.',
        );
      }
      for (final element in find.byType(Image).evaluate()) {
        final image = element.widget as Image;
        if (image.centerSlice == null ||
            image.key is! ValueKey<String> ||
            !(image.key! as ValueKey<String>).value.startsWith(
              'theme-sheet-frame-',
            )) {
          continue;
        }
        expect(
          image.centerSlice!.left,
          lessThanOrEqualTo(10),
          reason: 'Fixed frame corners must fit the live control margins.',
        );
      }
      expect(tester.takeException(), isNull);
      final boundary =
          capture.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        final directory = Directory('build/qa-20261118')
          ..createSync(recursive: true);
        File(
          '${directory.path}/TEMA-CORRETTO-${size.width.toInt()}x${size.height.toInt()}.png',
        ).writeAsBytesSync(png!.buffer.asUint8List());
        image.dispose();
      });

      if (size.width >= 600) {
        final stats = find.descendant(
          of: menu,
          matching: find.text('Statistiche'),
        );
        await tester.tap(stats);
        await tester.pump();
        expect(state.referenceSheetSection, 'statistics');
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
