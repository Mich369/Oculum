import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oculum/widgets/oculum_theme_presentation.dart';
import 'package:oculum/widgets/oculum_hover_surface.dart';
import 'package:oculum/widgets/oculum_art_button.dart';

void main() {
  test(
    'secondary controls preserve independent transparency and safe bounds',
    () {
      const presentation = OculumThemePresentation();
      expect(presentation.controlTransparency, .24);
      expect(
        presentation.copyWith(surfaceTransparency: .3).controlTransparency,
        .24,
      );
      expect(
        presentation.copyWith(controlTransparency: .25).surfaceTransparency,
        .34,
      );
      expect(
        presentation.copyWith(controlTransparency: 5).controlTransparency,
        .4,
      );
      expect(
        presentation.copyWith(controlTransparency: -1).controlTransparency,
        0,
      );
    },
  );
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    oculumThemePresentation.value = const OculumThemePresentation();
  });
  tearDown(
    () => oculumThemePresentation.value = const OculumThemePresentation(),
  );

  test(
    'surface preference persists and stays within readable limits',
    () async {
      expect(oculumThemePresentation.value.surfaceTransparency, .34);
      await setOculumThemePresentation(
        oculumThemePresentation.value.copyWith(surfaceTransparency: .32),
      );
      oculumThemePresentation.value = const OculumThemePresentation();
      await loadOculumThemePresentation();
      expect(oculumThemePresentation.value.surfaceTransparency, .32);
      expect(
        oculumThemePresentation.value
            .copyWith(surfaceTransparency: 10)
            .surfaceTransparency,
        .4,
      );
      expect(
        oculumThemePresentation.value
            .copyWith(surfaceTransparency: -1)
            .surfaceTransparency,
        0,
      );
    },
  );

  testWidgets(
    'action group highlights together then only the hovered button; input stays active',
    (tester) async {
      var clicks = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: OculumHoverSurface(
                actionGroup: true,
                builder: (context, opacity) => Theme(
                  data: oculumWithArtButtons(
                    Theme.of(context),
                    highlightAll:
                        OculumSurfaceScope.maybeOf(context)?.highlightAll ==
                        true,
                  ),
                  child: Container(
                    key: const Key('panel'),
                    width: 380,
                    height: 180,
                    color: oculumSurfaceColor(Colors.black, opacity),
                    padding: const EdgeInsets.all(30),
                    child: Row(
                      children: [
                        for (final label in ['Attacco', 'Difesa'])
                          OculumSurfaceButton(
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              onPressed: () => clicks++,
                              child: Text(label),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      Material material(String label) => tester.widget<Material>(
        find
            .descendant(
              of: find.ancestor(
                of: find.text(label),
                matching: find.byType(FilledButton),
              ),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(material('Attacco').color!.a, closeTo(.66, .01));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(
        tester.getTopLeft(find.byKey(const Key('panel'))) + const Offset(5, 5),
      );
      await tester.pumpAndSettle();
      expect(material('Attacco').color!.a, 1);
      expect(material('Difesa').color!.a, 1);
      await mouse.moveTo(tester.getCenter(find.text('Attacco')));
      await tester.pumpAndSettle();
      expect(material('Attacco').color!.a, 1);
      expect(material('Difesa').color!.a, closeTo(.66, .01));
      await tester.tap(find.text('Attacco'));
      expect(clicks, 1);
      expect(
        find.ancestor(of: find.text('Difesa'), matching: find.byType(Opacity)),
        findsNothing,
      );
      await mouse.removePointer();
    },
  );

  testWidgets(
    'transparency slider and recommended reset remain usable on phone',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: OculumThemePresentationControls(),
            ),
          ),
        ),
      );
      final slider = find.byKey(const ValueKey('surface-transparency'));
      await tester.tapAt(tester.getTopRight(slider) + const Offset(-24, 24));
      await tester.pumpAndSettle();
      expect(
        oculumThemePresentation.value.surfaceTransparency,
        greaterThan(.34),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface-transparency-reset')),
      );
      await tester.pumpAndSettle();
      expect(oculumThemePresentation.value.surfaceTransparency, .34);
      expect(tester.takeException(), isNull);
    },
  );
}
