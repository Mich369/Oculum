import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/widgets/oculum_theme_presentation.dart';
import 'package:oculum/widgets/oculum_narrative_background.dart';
import 'oculum_theme_effects_portrait_test.dart' as fixtures;

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final fonts =
        jsonDecode(await rootBundle.loadString('FontManifest.json')) as List;
    for (final raw in fonts.whereType<Map>()) {
      final loader = FontLoader('${raw['family']}');
      for (final font in (raw['fonts'] as List).whereType<Map>()) {
        loader.addFont(rootBundle.load('${font['asset']}'));
      }
      await loader.load();
    }
    final segoe = File('C:/Windows/Fonts/segoeui.ttf');
    if (segoe.existsSync()) {
      await (FontLoader('Segoe UI')
            ..addFont(segoe.readAsBytes().then((b) => ByteData.sublistView(b))))
          .load();
    }
    await (FontLoader(
      'Roboto',
    )..addFont(rootBundle.load('assets/fonts/Poppins-Regular.ttf'))).load();
    await (FontLoader(
      'serif',
    )..addFont(rootBundle.load('assets/fonts/EBGaramond.ttf'))).load();
    await (FontLoader(
      'sans-serif',
    )..addFont(rootBundle.load('assets/fonts/Poppins-Regular.ttf'))).load();
  });
  testWidgets(
    'capture real narrative character sheets at desktop and phone sizes',
    (tester) async {
      for (final size in [
        const Size(1440, 1000),
        const Size(834, 1112),
        const Size(390, 844),
        const Size(320, 740),
      ]) {
        const capture = ValueKey('narrative-sheet-preview');
        final dynamic state = await fixtures.mountSheet(
          tester,
          size,
          captureKey: capture,
        );
        final p = OculumPerformanceProbe(state);
        p.applyTheme('black_briar_kingdom');
        state.datiCaricati = false;
        if (state.schedePersonaggio.isEmpty) {
          final sheet = p.snapshot()
            ..['id'] = 'ElaraOcu:3690AAAA'
            ..['sheetTag'] = 'ElaraOcu:3690AAAA';
          state.schedePersonaggio.add(sheet);
          state.schedaCorrente = 0;
          p.load(sheet);
        }
        state.updateOculumHomeUi(() {
          state.modalitaDesktop = size.width > 600;
          state.desktopSideMenuOpen = size.width > 600;
          state.paginaCorrente = 0;
          state.showPageGuidance = false;
          state.nomeController.text = 'Elara';
          if (state.schedePersonaggio.isNotEmpty) {
            state.schedePersonaggio[state.schedaCorrente]['nome'] = 'Elara';
          }
          state.activeSheetSummaryRevision.value++;
          state.livelloController.text = '6';
          state.resilienzaController.text = '18';
          state.currentResilienzaController.text = '18';
          state.volontaController.text = '16';
          state.currentVolontaController.text = '16';
          state.materiaController.text = '12';
          state.currentMateriaController.text = '12';
          state.oculumController.text = '10';
          state.currentOculumController.text = '10';
          state.currentHpController.text = '180';
        });
        p.saveSheet();
        state.datiCaricati = true;
        await tester.pump();
        final tag = tester
            .widget<OculumNarrativeBackground>(
              find.byType(OculumNarrativeBackground),
            )
            .sheetId;
        for (final theme in [
          'hidenas',
          'dedicated_indigo',
          'restyle_sogno',
          'plane_foresta_elementale',
          'plane_sotterraneo',
          'monster/fuocherelli/naturale',
          'monster/scostubanditi/rame',
          'monster/feralis_ancestrale/naturale',
        ]) {
          oculumThemePresentation.value = oculumThemePresentation.value
              .copyWith(
                artPackId: theme,
                variant: theme.contains('fuocherelli')
                    ? OculumThemeVariant.alive
                    : OculumThemeVariant.still,
              );
          oculumSheetRelicSelections.value = {tag: theme};
          await tester.pump();
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 600)),
          );
          await tester.pump(const Duration(milliseconds: 300));
          expect(
            find.byKey(ValueKey('narrative-background-$theme')),
            findsOneWidget,
          );
          if (size.width > 600) {
            expect(find.text('Attacco').hitTestable(), findsWidgets);
          }
          expect(tester.takeException(), isNull);
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(capture),
          );
          await tester.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 1);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final file = File(
              'build/theme-previews/$theme-${size.width.toInt()}.png',
            );
            file.parent.createSync(recursive: true);
            file.writeAsBytesSync(bytes!.buffer.asUint8List());
            image.dispose();
          });
          if (size.width > 600 && theme.contains('fuocherelli')) {
            for (var frame = 0; frame < 10; frame++) {
              await tester.pump(const Duration(milliseconds: 600));
              await tester.runAsync(() async {
                final image = await boundary.toImage(pixelRatio: 1);
                final bytes = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                final file = File(
                  'build/theme-previews/motion/frame-${frame.toString().padLeft(2, '0')}.png',
                );
                file.parent.createSync(recursive: true);
                file.writeAsBytesSync(bytes!.buffer.asUint8List());
                image.dispose();
              });
            }
          }
        }
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 2));
        oculumSheetRelicSelections.value = {};
        oculumThemePresentation.value = const OculumThemePresentation();
      }
    },
  );
}
