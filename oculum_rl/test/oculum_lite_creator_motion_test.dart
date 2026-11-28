import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum_rl/game/oculum_lite_run.dart';
import 'package:oculum_rl/widgets/oculum_lite_arena.dart';
import 'package:oculum_rl/widgets/oculum_lite_creator.dart';

void main() {
  testWidgets('preview plays movement, dash and weapon release in the arena', (
    tester,
  ) async {
    _window(tester, const Size(1120, 780));
    await _open(tester);
    await _pose(tester, 'Cammina');
    final walk = _arena(tester);
    await _frames(tester, 12);
    expect(walk.run.stride.distance, greaterThan(0));
    expect(walk.run.clones, hasLength(1));
    final walkSpeed = walk.run.stride.speed;
    await _pose(tester, 'Corri');
    await _frames(tester, 12);
    expect(_arena(tester).run.stride.speed, greaterThan(walkSpeed));
    await _pose(tester, 'Scatto');
    expect(_arena(tester).run.burstRemaining, greaterThan(0));
    await _frames(tester, 4);
    expect(_arena(tester).run.burstTraces, isNotEmpty);

    await tester.tap(find.byType(DropdownButtonFormField<LiteWeapon>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(LiteWeapon.chakram.label).last);
    await tester.pumpAndSettle();
    await _pose(tester, 'Attacco');
    final throwRun = _arena(tester).run;
    expect(throwRun.weapon, LiteWeapon.chakram);
    await _frames(tester, 10);
    expect(throwRun.projectiles, isNotEmpty);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Ripeti prova'));
    await tester.pump();
    expect(_arena(tester).run, isNot(same(throwRun)));
    await _pose(tester, 'Posa');
    expect(find.byType(OculumLiteArena), findsNothing);
  });

  testWidgets('compact section links keep preview and name accessible', (
    tester,
  ) async {
    _window(tester, const Size(390, 740));
    OculumLiteCreation? result;
    await _open(tester, onSave: (saved) => result = saved);
    await tester.tap(find.widgetWithText(TextButton, 'Colori'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Abito · colore 1').hitTestable(), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Identità'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Nivra');
    final goblin = find.widgetWithText(ChoiceChip, 'Goblin');
    await tester.ensureVisible(goblin);
    await tester.tap(goblin);
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Anteprima'));
    await tester.pumpAndSettle();
    final preview = tester.widget<OculumLiteHeroPreview>(
      find.byType(OculumLiteHeroPreview),
    );
    expect(preview.appearance?.lineage, OculumLiteLineage.goblin);
    await tester.tap(find.text('Usa questo aspetto'));
    await tester.pumpAndSettle();
    expect(result?.name, 'Nivra');
    expect(result?.appearance.lineage, OculumLiteLineage.goblin);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion holds a sample from the requested move', (
    tester,
  ) async {
    _window(tester, const Size(1120, 780));
    await _open(tester, disableAnimations: true);
    await _pose(tester, 'Scatto');
    final run = _arena(tester).run;
    final center = Point(run.width / 2, run.height / 2);
    expect(run.position.distanceTo(center), greaterThan(0));
    final sampled = run.position;
    await _frames(tester, 24);
    expect(run.position, sampled);
    expect(tester.takeException(), isNull);
  });
}

void _window(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _open(
  WidgetTester tester, {
  bool disableAnimations = false,
  ValueChanged<OculumLiteCreation?>? onSave,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(disableAnimations: disableAnimations),
        child: child!,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async {
              final result = await editOculumLiteAppearance(
                context,
                appearance: const OculumLiteAppearance(),
                weapon: LiteWeapon.spadaScudo,
                name: 'Prima',
              );
              onSave?.call(result);
            },
            child: const Text('Apri creatore'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Apri creatore'));
  await tester.pumpAndSettle();
}

Future<void> _pose(WidgetTester tester, String label) async {
  await tester.tap(find.widgetWithText(ChoiceChip, label));
  await tester.pump();
}

OculumLiteArena _arena(WidgetTester tester) =>
    tester.widget<OculumLiteArena>(find.byType(OculumLiteArena));

Future<void> _frames(WidgetTester tester, int count) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}
