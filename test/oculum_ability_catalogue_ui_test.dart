import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'oculum_theme_effects_portrait_test.dart' as fixtures;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = await rootBundle.load('assets/fonts/Poppins-Regular.ttf');
    for (final family in [
      'Poppins',
      'Roboto',
      'serif',
      'Segoe UI',
      'Garamond',
      'Georgia',
    ]) {
      await (FontLoader(family)..addFont(Future.value(font))).load();
    }
  });
  for (final size in [const Size(1440, 1000), const Size(390, 844)]) {
    testWidgets('ability catalogue includes Arts and adapts to $size', (
      tester,
    ) async {
      final state = await fixtures.mountSheet(tester, size);
      final probe = OculumPerformanceProbe(state);
      expect(
        probe.abilityCostColors('@fortuna-1'),
        contains(const Color(0xFFD4AF37)),
      );
      expect(
        probe.abilityCostColors('@obser-5'),
        contains(const Color(0xFFADB1BA)),
      );
      expect(
        probe.abilityCostColors('Materiali @item:ferro-1'),
        contains(const Color(0xFF48484B)),
      );
      expect(
        probe.abilityCostColors('@mat-1 @item:ferro-1'),
        contains(const Color(0xFF44A7FF)),
      );
      expect(
        probe.abilityCostColors('@oculum-4'),
        contains(const Color(0xFFB68CFF)),
      );
      final before = probe.snapshot();
      final dialog = probe.abilityCatalogue();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      final search = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      await tester.enterText(search, oculumStarterArtChoices().first.nome);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(Checkbox), findsWidgets);
      expect(tester.takeException(), isNull);
      // Capture the modal's repaint boundary, including its responsive cards.
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find
            .ancestor(
              of: find.byType(AlertDialog),
              matching: find.byType(RepaintBoundary),
            )
            .first,
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File(
          'build/ability-catalogue-${size.width.toInt()}.png',
        ).writeAsBytesSync(bytes!.buffer.asUint8List());
        image.dispose();
      });
      await tester.tap(find.text('Annulla'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await dialog;
      expect(probe.snapshot()['arti'], before['arti']);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });
  }
}
