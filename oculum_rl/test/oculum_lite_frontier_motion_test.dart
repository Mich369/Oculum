import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum_rl/game/oculum_lite_run.dart';
import 'package:oculum_rl/widgets/oculum_lite_arena.dart';

class _ArenaCanvas extends TestRecordingCanvas {
  @override
  Float64List getTransform() => Matrix4.identity().storage;
}

void main() {
  testWidgets(
    'Orbryx hops and rolls while Rasvyr lowers its shell when running',
    (tester) async {
      final base =
          LiteRun(seed: 72241, hero: LiteHero.evasore, weapon: LiteWeapon.arco)
            ..position = const Point(14, 11)
            ..fauna.clear()
            ..enemies.clear()
            ..enemies.add(
              LiteEnemy(71, LiteEnemyKind.orbryx, const Point(18, 11), 50),
            );

      Future<List<Invocation>> capture({
        double distance = 0,
        double speed = 0,
        double windup = 0,
        double strike = 0,
        double clash = 0,
      }) async {
        final frame = base.toJson(includeEffects: true);
        final creature = (frame['enemies'] as List).single as Map;
        creature
          ..['stride'] = [distance, speed > 0 ? 1.0 : 0.0, speed]
          ..['windup'] = windup
          ..['strikePose'] = strike
          ..['clashRemaining'] = clash;
        await tester.pumpWidget(
          MaterialApp(home: OculumLiteArena(run: LiteRun.fromJson(frame))),
        );
        await tester.runAsync(() async {
          final context = tester.element(find.byType(OculumLiteArena));
          await precacheImage(OculumLiteArena.newActors, context);
        });
        await tester.pumpAndSettle();
        final painter = tester
            .widget<CustomPaint>(
              find.descendant(
                of: find.byType(OculumLiteArena),
                matching: find.byType(CustomPaint),
              ),
            )
            .painter!;
        final canvas = _ArenaCanvas();
        painter.paint(canvas, const Size(800, 600));
        return [for (final call in canvas.invocations) call.invocation];
      }

      bool usesCell(List<Invocation> calls, int column) => calls.any(
        (call) =>
            call.memberName == #drawImageRect &&
            call.positionalArguments[1] ==
                Rect.fromLTWH(column * 360, 5 * 240, 360, 240),
      );

      int meshes(List<Invocation> calls) =>
          calls.where((call) => call.memberName == #drawVertices).length;

      bool leavesGround(List<Invocation> calls) => calls.any(
        (call) =>
            call.memberName == #translate &&
            call.positionalArguments[0] == 0 &&
            (call.positionalArguments[1] as num) < -.18 &&
            (call.positionalArguments[1] as num) > -.45,
      );

      final idle = await capture();
      expect(usesCell(idle, 0), isTrue);
      expect(
        meshes(await capture(distance: .395, speed: 1.3)),
        greaterThan(meshes(idle)),
      );
      expect(meshes(await capture(windup: .29)), greaterThan(meshes(idle)));
      expect(leavesGround(await capture(distance: .395, speed: 3.6)), isTrue);
      expect(leavesGround(await capture(distance: 1.185, speed: 3.6)), isFalse);
      expect(usesCell(await capture(strike: .14), 3), isTrue);
      expect(
        usesCell(await capture(distance: .45, speed: 6.5, clash: .1), 3),
        isTrue,
      );
      base.enemies
        ..clear()
        ..add(LiteEnemy(72, LiteEnemyKind.rasvyr, const Point(18, 11), 50));
      bool pitchesBy(List<Invocation> calls, double angle) => calls.any(
        (call) =>
            call.memberName == #rotate &&
            ((call.positionalArguments.single as num) - angle).abs() < .0001,
      );
      final walk = await capture(distance: .395, speed: 1.3);
      final run = await capture(
        distance: .395,
        speed: LiteEnemyKind.rasvyr.speed,
      );
      expect(pitchesBy(walk, .024), isTrue);
      expect(pitchesBy(walk, .062), isFalse);
      expect(pitchesBy(run, .062), isTrue);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
