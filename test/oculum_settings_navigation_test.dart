import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oculum/main.dart';
import 'package:oculum/widgets/oculum_theme_presentation.dart';
import 'oculum_theme_effects_portrait_test.dart' as fixtures;

void main() {
  test('transparency upgrade preserves custom values and runs once', () async {
    SharedPreferences.setMockInitialValues({
      'oculum.surfaceTransparency': .18,
      'oculum.controlTransparency': .12,
      'oculum.sheetRelicSelections': '{"saved-sheet":"moon_iron"}',
    });
    await loadOculumThemePresentation();
    expect(oculumThemePresentation.value.surfaceTransparency, .34);
    expect(oculumThemePresentation.value.controlTransparency, .24);
    expect(oculumSheetRelicSelections.value['saved-sheet'], 'moon_iron');
    await setOculumThemePresentation(
      oculumThemePresentation.value.copyWith(
        surfaceTransparency: .18,
        controlTransparency: .12,
      ),
    );
    await loadOculumThemePresentation();
    expect(oculumThemePresentation.value.surfaceTransparency, .18);
    expect(oculumThemePresentation.value.controlTransparency, .12);
    SharedPreferences.setMockInitialValues({
      'oculum.surfaceTransparency': .29,
      'oculum.controlTransparency': .07,
    });
    await loadOculumThemePresentation();
    expect(oculumThemePresentation.value.surfaceTransparency, .29);
    expect(oculumThemePresentation.value.controlTransparency, .07);
  });

  testWidgets('settings sections and search work on phone and desktop', (
    tester,
  ) async {
    final regular = await rootBundle.load('assets/fonts/Poppins-Regular.ttf');
    for (final family in [
      'Poppins',
      'Roboto',
      'serif',
      'Segoe UI',
      'Garamond',
      'Georgia',
    ]) {
      await (FontLoader(family)..addFont(Future.value(regular))).load();
    }
    final icons = File(
      'build/unit_test_assets/fonts/MaterialIcons-Regular.otf',
    );
    if (icons.existsSync()) {
      await (FontLoader('MaterialIcons')..addFont(
            Future.value(ByteData.sublistView(icons.readAsBytesSync())),
          ))
          .load();
    }
    final capture = GlobalKey();
    final dynamic state = await fixtures.mountSheet(
      tester,
      const Size(1440, 1000),
      captureKey: capture,
    );
    final probe = OculumPerformanceProbe(state);
    state.updateOculumHomeUi(() {
      state.paginaCorrente = 11;
      state.settingsCategory = 'general';
      state.settingsQuery = '';
    });
    await tester.pumpAndSettle();
    final out = Directory('build/settings-verification')
      ..createSync(recursive: true);
    for (final width in [1440.0, 320.0]) {
      tester.view.physicalSize = Size(width, 1000);
      for (final category in [
        'general',
        'appearance',
        'colors',
        'sheet',
        'session',
        'rules',
        'data',
      ]) {
        state.updateOculumHomeUi(() {
          state.settingsCategory = category;
          state.settingsQuery = '';
        });
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$category at $width');
        expect(find.byKey(const ValueKey('settings-search')), findsOneWidget);
        if (['general', 'appearance', 'data'].contains(category)) {
          await tester.runAsync(() async {
            final boundary =
                capture.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final image = await boundary.toImage(pixelRatio: 1);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            File(
              '${out.path}/$category-${width.toInt()}.png',
            ).writeAsBytesSync(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
      }
    }
    final search = find.byKey(const ValueKey('settings-search'));
    await tester.ensureVisible(search);
    await tester.tap(search);
    await tester.enterText(search, 'backup');
    await tester.pumpAndSettle();
    expect(find.text('Dati e backup'), findsWidgets);
    expect(tester.testTextInput.isVisible, isTrue);
    await tester.enterText(search, 'nessun-risultato');
    await tester.pumpAndSettle();
    expect(find.textContaining('Nessuna impostazione trovata'), findsOneWidget);
    await tester.tap(find.byTooltip('Cancella ricerca'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(search).controller!.text, isEmpty);
    expect(tester.takeException(), isNull);
    probe.cancelPendingSave();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
  });
}
