import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
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
        MaterialApp(
          theme: oculumBaseTheme,
          builder: (_, child) => OculumThemeScope(child: child!),
          home: const OculumHomePage(),
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
