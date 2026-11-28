import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum_rl/game/oculum_lite_coop.dart';
import 'package:oculum_rl/game/oculum_lite_run.dart';
import 'package:oculum_rl/pages/oculum_lite_coop_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('the Assassin toggles the same box with C and the touch button', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final run = LiteRun(
      seed: 251,
      hero: LiteHero.assassino,
      weapon: LiteWeapon.doppieLame,
      playerCount: 2,
    );
    final session = OculumLiteCoop(
      runId: 'touch-box',
      localAccount: 'master',
      authority: run,
      send: (_) async => true,
    );
    addTearDown(session.dispose);
    await tester.pumpWidget(
      MaterialApp(home: OculumLiteCoopPage(session: session)),
    );
    await tester.pump(const Duration(milliseconds: 24));
    expect(find.text('C · Nasconditi nella scatola'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
    await tester.pump(const Duration(milliseconds: 24));
    expect(run.assassinBoxActive, isTrue);
    final exit = find.text('C · Esci dalla scatola');
    await tester.ensureVisible(exit);
    await tester.tap(exit);
    await tester.pump();
    expect(run.assassinBoxActive, isFalse);
    await tester.pumpWidget(const SizedBox());
  });

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

  testWidgets(
    'the desktop co-op guide stays visible and the labelled scroll works',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final run = LiteRun(
        seed: 251,
        hero: LiteHero.evasore,
        weapon: LiteWeapon.arco,
        playerCount: 2,
      );
      final scroll = run.equippedScrolls[1];
      run.scrolls[scroll.index] = 1;
      run.oculum = 50;
      final session = OculumLiteCoop(
        runId: 'command-list-host',
        localAccount: 'master',
        authority: run,
        send: (_) async => true,
      );
      addTearDown(session.dispose);
      await tester.pumpWidget(
        MaterialApp(home: OculumLiteCoopPage(session: session)),
      );
      await tester.pump(const Duration(milliseconds: 24));
      expect(find.text('WASD / Frecce · Muoviti'), findsOneWidget);
      expect(find.text('Tieni R · Soccorri un alleato'), findsOneWidget);
      expect(find.text('1 · ${scroll.label}'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
      await tester.pump(const Duration(milliseconds: 24));
      expect(run.scrolls[scroll.index], 0);
      expect(find.text('WASD / Frecce · Muoviti'), findsOneWidget);
      expect(find.text('1 · ${scroll.label}'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
    variant: const TargetPlatformVariant({TargetPlatform.windows}),
  );

  testWidgets(
    'a wide Android tablet retains the co-op movement and attack controls',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(900, 600);
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
        runId: 'wide-android',
        localAccount: 'master',
        authority: run,
        send: (_) async => true,
      );
      addTearDown(session.dispose);
      await tester.pumpWidget(
        MaterialApp(home: OculumLiteCoopPage(session: session)),
      );
      await tester.pump(const Duration(milliseconds: 24));
      expect(find.text('Frecce a schermo · Muoviti'), findsOneWidget);
      expect(find.text('Tocca l’arena · Mira e attacca'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Cammina'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Attacca'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
    variant: const TargetPlatformVariant({TargetPlatform.android}),
  );
}
