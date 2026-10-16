import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'oculum_theme_effects_portrait_test.dart' as fixtures;

void main() {
  testWidgets('secondary click and long press expose the same useful actions', (
    tester,
  ) async {
    final state = await fixtures.mountSheet(tester, const Size(1440, 900));
    final probe = OculumPerformanceProbe(state);
    var activations = 0;
    var rolls = 0;
    const anchorKey = ValueKey('context-gesture-fixture');
    final entry = OverlayEntry(
      builder: (_) => Positioned(
        left: 70,
        top: 70,
        width: 130,
        height: 70,
        child: Material(
          child: probe.contextActionAnchor(
            activate: () => activations++,
            roll: () => rolls++,
            child: const SizedBox(key: anchorKey, child: Text('Volontà')),
          ),
        ),
      ),
    );
    Overlay.of(tester.element(find.byType(OculumHomePage))).insert(entry);
    await tester.pump();
    final mouse = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await mouse.down(tester.getCenter(find.byKey(anchorKey)));
    await mouse.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    const labels = [
      'Tira Volontà',
      'Statistiche e bonus',
      'Sottotratti e tiri',
      'Resistenze e vulnerabilità',
      'Vita, scudi e condizioni',
      'Danni subiti e cura',
    ];
    for (final label in labels) {
      expect(
        find.ancestor(
          of: find.text(label),
          matching: find.byType(PopupMenuItem<String>),
        ),
        findsOneWidget,
      );
    }
    expect(activations, 0);
    expect(rolls, 0);
    await tester.tap(find.text('Tira Volontà'));
    await tester.pump(const Duration(milliseconds: 350));
    expect(rolls, 1);
    await tester.longPress(find.byKey(anchorKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    for (final label in labels) {
      expect(
        find.ancestor(
          of: find.text(label),
          matching: find.byType(PopupMenuItem<String>),
        ),
        findsOneWidget,
      );
    }
    expect(activations, 0);
    await tester.tapAt(const Offset(1100, 800));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.byKey(anchorKey));
    await tester.pump(const Duration(milliseconds: 350));
    expect(activations, 1);
    expect(rolls, 1);
    entry.remove();
    entry.dispose();
    probe.cancelPendingSave();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}
