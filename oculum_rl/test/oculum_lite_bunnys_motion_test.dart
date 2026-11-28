import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum_rl/game/oculum_lite_run.dart';
import 'package:oculum_rl/widgets/oculum_lite_arena.dart';

class _BunnysRecordingCanvas extends TestRecordingCanvas {
  @override
  Float64List getTransform() => Matrix4.identity().storage;
}

LiteRun _arena() =>
    LiteRun(seed: 251, hero: LiteHero.evasore, weapon: LiteWeapon.arco)
      ..stage = 2
      ..position = const Point(12, 11)
      ..stageClear = false
      ..enemies.clear()
      ..obstacles.clear()
      ..fauna.clear();

void main() {
  test('a fleeing Bunnys faces its actual travel after a co-op frame', () {
    final run = _arena();
    final enemy = LiteEnemy(920, LiteEnemyKind.bunnys, const Point(9, 11), 40);
    run.enemies.add(enemy);
    expect(enemy.bunnysFacingRight, isNull);
    run.step(1 / 30);
    expect(enemy.position.x, lessThan(9.0));
    expect(enemy.bunnysFacingRight, isFalse);
    final restored = LiteRun.fromJson(run.toJson(includeEffects: true));
    expect(restored.enemies.single.bunnysFacingRight, isFalse);
    final old = run.toJson();
    ((old['enemies'] as List).single as Map).remove('bunnysFacingRight');
    expect(LiteRun.fromJson(old).enemies.single.bunnysFacingRight, isNull);
  });

  testWidgets('enemy and pet render distinct grounded and airborne cels', (
    tester,
  ) async {
    final run = _arena();
    run.enemies.add(
      LiteEnemy(920, LiteEnemyKind.bunnys, const Point(15, 8), 40),
    );
    run.clones.add(
      LiteClone(
        const Point(17, 12),
        36,
        LiteWeapon.arco,
        companion: LiteCompanion.bunnys,
        id: 921,
      ),
    );
    final snapshot = run.toJson(includeEffects: true);
    final enemy = (snapshot['enemies'] as List).single as Map;
    final pet = (snapshot['clones'] as List).single as Map;

    Future<List<(int, Rect, Rect)>> draw() async {
      final arena = find.byType(OculumLiteArena);
      await tester.pumpWidget(
        MaterialApp(home: OculumLiteArena(run: LiteRun.fromJson(snapshot))),
      );
      await tester.runAsync(() async {
        final context = tester.element(arena);
        await precacheImage(OculumLiteArena.bunnysArt, context);
        await precacheImage(OculumLiteArena.bunnysGait, context);
      });
      await tester.pumpAndSettle();
      final painter = tester
          .widget<CustomPaint>(
            find.descendant(of: arena, matching: find.byType(CustomPaint)),
          )
          .painter!;
      final canvas = _BunnysRecordingCanvas();
      painter.paint(canvas, const Size(800, 600));
      return [
        for (final call in canvas.invocations)
          if (call.invocation.memberName == #drawImageRect)
            (
              (call.invocation.positionalArguments[0] as ui.Image).width,
              call.invocation.positionalArguments[1] as Rect,
              call.invocation.positionalArguments[2] as Rect,
            ),
      ];
    }

    for (var cel = 0; cel < 4; cel++) {
      enemy['stride'] = [.93 * (cel + .5) / 4, 1.0, 3.1];
      pet['stride'] = [1.15 * (cel + .5) / 4, 1.0, 4.2];
      final poses = (await draw()).where((entry) => entry.$1 == 992);
      expect(poses, hasLength(2), reason: 'phase $cel');
      final walk = poses.singleWhere((entry) => entry.$2.top == 0);
      final gallop = poses.singleWhere((entry) => entry.$2.top == 248);
      expect(walk.$2.left, cel * 248);
      expect(gallop.$2.left, cel * 248);
      expect(walk.$3.bottom, closeTo(0, 1e-9));
      expect(
        gallop.$3.bottom,
        cel == 1 || cel == 2 ? lessThan(-.12) : closeTo(0, 1e-9),
      );
    }

    enemy['windup'] = .24;
    pet['preparingPose'] = .24;
    final healing = await draw();
    expect(healing.where((entry) => entry.$1 == 992), isEmpty);
    expect(
      healing.where(
        (entry) =>
            entry.$1 == 768 &&
            entry.$2 == const Rect.fromLTWH(256, 256, 256, 256),
      ),
      hasLength(2),
    );
    await tester.pumpWidget(const SizedBox());
  });
}
