import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/widgets/oculum_goth_ornaments.dart';
import 'package:oculum/widgets/oculum_theme_presentation.dart';
import 'package:oculum/widgets/oculum_theme_relic.dart';
import 'package:oculum/widgets/oculum_theme_sheet_art.dart';

void main() {
  testWidgets(
    'theme artwork preserves button position and content dimensions',
    (tester) async {
      final theme = oculumBaseTheme.copyWith(
        extensions: const [
          OculumGothOrnaments(
            family: OculumGothFamily.botanical,
            ink: Colors.green,
            accent: Colors.purple,
            opacity: .4,
            themeId: 'vervain_gothic',
          ),
        ],
      );
      Widget content() => SizedBox(
        width: 280,
        height: 112,
        child: Center(
          child: FilledButton(
            key: const ValueKey('stable-theme-action'),
            onPressed: () {},
            child: const Text('Attacco'),
          ),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(body: Center(child: content())),
        ),
      );
      final before = tester.getRect(
        find.byKey(const ValueKey('stable-theme-action')),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Center(
              child: OculumThemeSheetBackdrop(
                child: OculumThemeSheetFrame(child: content()),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(
        tester.getRect(find.byKey(const ValueKey('stable-theme-action'))),
        before,
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('stable-theme-action')));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('theme details stay at the edges and buttons remain usable', (
    tester,
  ) async {
    for (final family in OculumGothFamily.values) {
      var activated = 0;
      final theme =
          oculumBuildPaletteTheme(
            base: oculumBaseTheme,
            primary: const Color(0xffead7f2),
            secondary: const Color(0xff102015),
            accent: const Color(0xffb56fa5),
            surface: const Color(0xff102015),
            background: const Color(0xff050807),
            fontFamily: 'Georgia',
            buttonFamily: family,
            buttonInk: const Color(0xff78a85f),
            buttonDecorationOpacity: .315,
          ).copyWith(
            extensions: [
              OculumGothOrnaments(
                family: family,
                ink: const Color(0xff78a85f),
                accent: const Color(0xffb56fa5),
                opacity: .315,
                themeId: 'theme-${family.name}',
              ),
            ],
          );

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const OculumThemePanelArtwork(
                    child: SizedBox(
                      width: 240,
                      height: 76,
                      child: Center(child: Text('Sezione leggibile')),
                    ),
                  ),
                  FilledButton(
                    onPressed: () => activated++,
                    child: const Text('Usa abilità'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final shape = theme.filledButtonTheme.style!.shape!.resolve(
        const <WidgetState>{},
      );
      expect(shape, isA<OculumButtonFrame>(), reason: family.name);
      expect((shape! as OculumButtonFrame).family, family);
      expect(find.text('Sezione leggibile'), findsOneWidget);
      expect(find.text('Usa abilità'), findsOneWidget);

      final buttonRect = tester.getRect(find.byType(FilledButton));
      final labelRect = tester.getRect(find.text('Usa abilità'));
      expect(labelRect.left - buttonRect.left, greaterThan(8));
      expect(buttonRect.right - labelRect.right, greaterThan(8));
      await tester.tap(find.text('Usa abilità'));
      expect(activated, 1, reason: family.name);
      expect(tester.takeException(), isNull, reason: family.name);
    }
  });

  testWidgets('classic sheet signature does not show the eye relic image', (
    tester,
  ) async {
    final previousPresentation = oculumThemePresentation.value;
    oculumThemePresentation.value = const OculumThemePresentation();
    addTearDown(() => oculumThemePresentation.value = previousPresentation);
    final theme = oculumBaseTheme.copyWith(
      extensions: const [
        OculumGothOrnaments(
          family: OculumGothFamily.none,
          ink: Colors.transparent,
          accent: Colors.amber,
          opacity: 0,
          themeId: 'classic_reliquary',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(theme: theme, home: const OculumThemeRelicBanner()),
    );
    await tester.pump();

    expect(find.text('Classic Oculum'), findsOneWidget);
    expect(find.textContaining('occhio'), findsNothing);
    expect(find.byType(Image), findsNothing);
    expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
  });
}
