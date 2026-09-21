import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/game/hero_path/hero_engine.dart' hide HeroMode;
import 'package:oculum/pages/hero_path_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final width in [360.0, 1440.0]) {
    testWidgets('Cammino creazione e combattimento a $width px', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final font = await rootBundle.load('assets/fonts/Poppins-Regular.ttf');
      await (FontLoader('Roboto')..addFont(Future.value(font))).load();
      final icons = File(
        'build/unit_test_assets/fonts/MaterialIcons-Regular.otf',
      );
      if (icons.existsSync()) {
        await (FontLoader('MaterialIcons')..addFont(
              Future.value(ByteData.sublistView(icons.readAsBytesSync())),
            ))
            .load();
      }
      await tester.pumpWidget(
        const MaterialApp(home: HeroPathPage(initialName: 'Iris')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Cammino dell’Eroe'), findsOneWidget);
      expect(find.text('Nome'), findsOneWidget);
      expect(find.textContaining('(0/3)'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Inizia il Cammino'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Inizia il Cammino'),
            )
            .onPressed,
        isNull,
      );
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .jumpTo(0);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Fuoco'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fuoco'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CheckboxListTile>(
              find.widgetWithText(CheckboxListTile, 'Filo di Brace'),
            )
            .value,
        false,
      );
      expect(
        tester
            .widget<CheckboxListTile>(
              find.widgetWithText(CheckboxListTile, 'Cuore di Fornace'),
            )
            .onChanged,
        isNull,
      );
      expect(tester.takeException(), isNull);
      final run = HeroRun(
        seed: 7,
        name: 'Iris',
        art: ['brace', 'gelo', 'aurora'],
      );
      run.encounter(forced: 'lupo');
      final capture = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: RepaintBoundary(
            key: capture,
            child: HeroPathPage(key: UniqueKey(), initialRun: run),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('2 carte ancora giocabili'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Difenditi · Lv.0'));
      await tester.tap(find.text('Difenditi · Lv.0'));
      await tester.pumpAndSettle();
      expect(run.actionsLeft, 1);
      expect(run.turn, 0);
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final image =
            await (capture.currentContext!.findRenderObject()
                    as RenderRepaintBoundary)
                .toImage(pixelRatio: 1);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        Directory('output/ui').createSync(recursive: true);
        File(
          'output/ui/hero-path-combat-${width.toInt()}.png',
        ).writeAsBytesSync(bytes!.buffer.asUint8List());
        image.dispose();
      });
    });
  }
}
