import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum_rl/game/oculum_lite_run.dart';
import 'package:oculum_rl/widgets/oculum_lite_arena.dart';

void main() {
  for (final (hero, weapon, art, rectIndex, rect) in [
    (
      LiteHero.curatorePeste,
      LiteWeapon.scettro,
      OculumLiteArena.newActors,
      1,
      const Rect.fromLTWH(0, 0, 360, 240),
    ),
    (
      LiteHero.evasore,
      LiteWeapon.guanti,
      OculumLiteArena.evasorFrames,
      2,
      const Rect.fromLTWH(0, 0, 336, 336),
    ),
  ]) {
    testWidgets('light, shadow and echoes use the illustrated ${hero.name}', (
      tester,
    ) async {
      final run = LiteRun(seed: 49, hero: hero, weapon: weapon)
        ..position = const Point(14, 11)
        ..enemies.clear()
        ..obstacles.clear();
      final rivals = [
        LiteEnemyKind.luce,
        LiteEnemyKind.ombra,
        LiteEnemyKind.ecoSpeculare,
      ];
      for (final (index, kind) in rivals.indexed) {
        run.enemies.add(
          LiteEnemy(100 + index, kind, Point(17.2 + index * 2.3, 11), 100)
            ..mirror = LiteMirrorBuild(
              hero: hero,
              weapon: weapon,
              slots: [],
              quantities: [],
              learned: {},
              oculum: 40,
              damage: 10,
              shield: 0,
            ),
        );
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: OculumLiteArena(run: run)),
        ),
      );
      final arena = find.byType(OculumLiteArena);
      await tester.runAsync(() async {
        await precacheImage(art, tester.element(arena));
      });
      await tester.pumpAndSettle();

      final paint = tester.widget<CustomPaint>(
        find.descendant(of: arena, matching: find.byType(CustomPaint)),
      );
      final canvas = TestRecordingCanvas();
      paint.painter!.paint(canvas, const Size(800, 450));
      final illustratedActors = canvas.invocations.where(
        (call) =>
            call.invocation.memberName == #drawImageRect &&
            call.invocation.positionalArguments[rectIndex] == rect,
      );
      expect(illustratedActors, hasLength(1 + rivals.length));
    });
  }
}
