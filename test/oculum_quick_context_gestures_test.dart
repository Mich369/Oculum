import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'oculum_escape_provoker_test.dart' show mountFight;
import 'oculum_october27_resources_test.dart' show closeFixture;
import 'oculum_theme_effects_portrait_test.dart' as fixtures;

void main() {
  testWidgets('Resilience shows only tracked part HP after a targeted hit', (
    tester,
  ) async {
    final (state, probe) = await mountFight(tester);
    final sheet = state.schedePersonaggio[state.schedaCorrente] as Map;
    sheet['monsterBookSourceId'] = 'teschio_quattro_lame';
    probe.invalidateDerivedCaches();
    const statsKey = ValueKey('resilience-context-fixture');
    final home = tester.element(find.byType(OculumHomePage));
    final entry = OverlayEntry(
      builder: (_) => Positioned(
        left: 50,
        top: 100,
        width: 1060,
        child: Material(key: statsKey, child: probe.statsOverview()),
      ),
    );
    Overlay.of(home).insert(entry);
    await tester.pump();
    final resilience = find.descendant(
      of: find.byKey(statsKey),
      matching: find.text('Resilienza'),
    );
    final health = find.text('Vita delle parti');
    final mouse = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );

    Future<void> openMenu() async {
      await mouse.down(tester.getCenter(resilience));
      await mouse.up();
      await tester.pumpAndSettle();
      expect(find.text('Tira Resilienza'), findsOneWidget);
    }

    Future<void> closeMenu() async {
      Navigator.of(home).pop();
      await tester.pumpAndSettle();
    }

    await openMenu();
    expect(health, findsNothing);
    await closeMenu();

    await probe.anatomicalTargetHit(
      {'id': 'untargeted', 'sourceTag': 'ENEMY'},
      hpLost: 4,
      critical: false,
    );
    await probe.anatomicalTargetHit(
      {'id': 'absorbed', 'sourceTag': 'ENEMY', 'targetBodyPart': 'arms_1'},
      hpLost: 0,
      critical: false,
    );
    await openMenu();
    expect(health, findsNothing);
    await closeMenu();

    await probe.anatomicalTargetHit(
      {'id': 'targeted', 'sourceTag': 'ENEMY', 'targetBodyPart': 'arms_1'},
      hpLost: 1,
      critical: false,
    );
    await openMenu();
    await tester.tap(health);
    await tester.pumpAndSettle();
    final parts = probe.anatomicalPartsSnapshot()['parts'] as Map;
    final arm = parts.values.single as Map;
    final maximum = readIntValue(arm['maximumHp']);
    expect(
      find.text('${arm['label']} · ${maximum - 1}/$maximum HP'),
      findsOneWidget,
    );
    await closeMenu();

    final current = state.schedePersonaggio[state.schedaCorrente] as Map;
    current['realtimeSharedSheet'] = true;
    await openMenu();
    expect(health, findsNothing);
    await closeMenu();
    current.remove('realtimeSharedSheet');

    probe.repairAnatomicalParts('master_repair');
    await openMenu();
    expect(health, findsNothing);
    await closeMenu();
    entry.remove();
    entry.dispose();
    await closeFixture(tester, probe);
  });

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
