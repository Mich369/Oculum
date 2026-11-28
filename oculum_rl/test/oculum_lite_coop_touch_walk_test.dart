import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum_rl/game/oculum_lite_coop.dart';
import 'package:oculum_rl/game/oculum_lite_run.dart';
import 'package:oculum_rl/pages/oculum_lite_coop_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('co-op touch walking and Ctrl use the same movement mode', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final run = LiteRun(
      seed: 251,
      hero: LiteHero.evasore,
      weapon: LiteWeapon.arco,
      playerCount: 2,
    );
    final session = OculumLiteCoop(
      runId: 'touch-walk',
      localAccount: 'master',
      authority: run,
      send: (_) async => true,
    );
    addTearDown(session.dispose);
    final chip = find.widgetWithText(FilterChip, 'Cammina');

    await tester.pumpWidget(
      MaterialApp(home: OculumLiteCoopPage(session: session)),
    );
    await tester.pump(const Duration(milliseconds: 24));
    expect(chip, findsOneWidget);
    expect(tester.widget<FilterChip>(chip).selected, isFalse);
    expect(session.slowed, isFalse);

    await tester.tap(chip);
    await tester.pump();
    expect(tester.widget<FilterChip>(chip).selected, isTrue);
    expect(session.slowed, isTrue);

    await tester.tap(chip);
    await tester.pump();
    expect(session.slowed, isFalse);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    expect(session.slowed, isTrue);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    expect(session.slowed, isFalse);
    await tester.pumpWidget(const SizedBox());
  });
}
