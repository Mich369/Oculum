import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/widgets/oculum_goth_ornaments.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = await rootBundle.load('assets/fonts/Poppins-Regular.ttf');
    await (FontLoader('Segoe UI')..addFont(Future.value(font))).load();
    final icons = File(
      'build/unit_test_assets/fonts/MaterialIcons-Regular.otf',
    );
    if (icons.existsSync()) {
      await (FontLoader('MaterialIcons')..addFont(
            Future.value(ByteData.sublistView(icons.readAsBytesSync())),
          ))
          .load();
    }
  });
  test('readability uses the visible translucent color', () {
    const background = Color(0xFF10121A);
    const faint = Color(0x20FFFFFF);
    final readable = oculumReadableThemeColor(faint, background);
    expect(
      oculumThemeContrastRatio(
        Color.alphaBlend(readable, background),
        background,
      ),
      greaterThanOrEqualTo(4.5),
    );
    expect(oculumReadableThemeColor(Colors.white, background), Colors.white);
  });

  for (final size in [const Size(1440, 900), const Size(390, 844)]) {
    testWidgets('Every theme reaches the navigator and dialogs at $size', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final previousGraphics = oculumGraphicsEnabled.value;
      oculumGraphicsEnabled.value = size.width >= 600;
      addTearDown(() => oculumGraphicsEnabled.value = previousGraphics);
      final directory = Directory(
        'build/all-themes-${DateTime.now().microsecondsSinceEpoch}',
      )..createSync(recursive: true);
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (_) async => directory.absolute.path,
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/connectivity'),
        (_) async => ['none'],
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/connectivity_status'),
        (_) async => null,
      );
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      oculumActiveTheme.value = null;
      await tester.pumpWidget(
        RepaintBoundary(
          key: const ValueKey('real-themed-screen'),
          child: MaterialApp(
            theme: oculumBaseTheme,
            builder: (_, child) => OculumThemeScope(child: child!),
            home: const OculumHomePage(),
          ),
        ),
      );
      final dynamic state = tester.state(find.byType(OculumHomePage));
      state.tutorialDialogPending = true;
      await tester.runAsync(() async {
        for (var i = 0; i < 100 && !state.datiCaricati; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
      });
      state.updateOculumHomeUi(() {
        state.tutorialCompletato = true;
        state.datiCaricati = true;
        state.modalitaLeggera = size.width < 600;
      });
      final probe = OculumPerformanceProbe(state);
      expect(probe.themes.length, greaterThan(10));
      for (final preset in probe.themes) {
        probe.applyTheme(preset.id);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        final context = tester.element(find.byType(OculumHomePage));
        final theme = Theme.of(context);
        expect(
          theme.extension<OculumGothOrnaments>(),
          isNotNull,
          reason: preset.id,
        );
        if ([
          'vervain_gothic',
          'frost_chapel',
          'bolted_black_iron',
        ].contains(preset.id)) {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('real-themed-screen')),
          );
          await tester.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 1);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            image.dispose();
            final file = File(
              'output/ui/temi-goth/real-${preset.id}-${size.width.toInt()}.png',
            );
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes!.buffer.asUint8List());
          });
        }
        expect(
          theme.colorScheme.surface,
          preset.backgroundMid,
          reason: preset.id,
        );
        expect(theme.dialogTheme.backgroundColor, preset.backgroundMid);
        expect(theme.popupMenuTheme.color, preset.backgroundMid);
        expect(
          theme.bottomSheetTheme.modalBackgroundColor,
          preset.backgroundMid,
        );
        expect(
          oculumThemeContrastRatio(
            theme.colorScheme.onSurface,
            theme.colorScheme.surface,
          ),
          greaterThanOrEqualTo(4.5),
          reason: preset.id,
        );
        expect(
          oculumThemeContrastRatio(
            theme.colorScheme.onPrimary,
            theme.colorScheme.primary,
          ),
          greaterThanOrEqualTo(4.5),
          reason: preset.id,
        );
        showDialog<void>(
          context: context,
          builder: (dialogContext) {
            expect(
              Theme.of(dialogContext).colorScheme.surface,
              preset.backgroundMid,
            );
            return AlertDialog(
              title: Text(preset.nameIt),
              content: const TextField(
                decoration: InputDecoration(labelText: 'Nome'),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Chiudi'),
                ),
              ],
            );
          },
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        await tester.tap(find.text('Chiudi'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        expect(tester.takeException(), isNull, reason: preset.id);
        showMenu<void>(
          context: context,
          position: const RelativeRect.fromLTRB(24, 24, 24, 24),
          items: const [PopupMenuItem<void>(child: Text('Tema menu'))],
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        expect(
          Theme.of(tester.element(find.text('Tema menu'))).popupMenuTheme.color,
          preset.backgroundMid,
          reason: preset.id,
        );
        await tester.tap(find.text('Tema menu'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        showModalBottomSheet<void>(
          context: context,
          builder: (sheetContext) {
            expect(
              Theme.of(sheetContext).colorScheme.surface,
              preset.backgroundMid,
            );
            return SizedBox(
              height: 100,
              child: Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('Chiudi pannello'),
                ),
              ),
            );
          },
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        await tester.tap(find.text('Chiudi pannello'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        expect(tester.takeException(), isNull, reason: preset.id);
      }
      state.updateOculumHomeUi(() => state.stileCarattereApp = 'pergamena');
      await tester.pump();
      await tester.pump();
      expect(
        Theme.of(
          tester.element(find.byType(OculumHomePage)),
        ).textTheme.bodyMedium?.fontFamily,
        'Georgia',
      );
      debugPrint('Verified ${probe.themes.length} themes at $size');
      // Custom palettes receive the same readability and component treatment.
      final custom = oculumBuildPaletteTheme(
        base: oculumBaseTheme,
        primary: Colors.white,
        secondary: const Color(0xFFF0E8D8),
        accent: Colors.yellow,
        surface: const Color(0xFFFFF4DD),
        background: Colors.white,
        fontFamily: 'Georgia',
      );
      expect(
        oculumThemeContrastRatio(
          custom.colorScheme.onSurface,
          custom.colorScheme.surface,
        ),
        greaterThanOrEqualTo(4.5),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 400));
      oculumActiveTheme.value = null;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        null,
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/connectivity'),
        null,
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/connectivity_status'),
        null,
      );
    });
  }
}
