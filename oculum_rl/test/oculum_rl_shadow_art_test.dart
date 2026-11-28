import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum_rl/game/oculum_lite_run.dart';

const _source = Point<double>(14, 11);
const _aim = Point<double>(21, 11);

LiteRun _study(LiteRestItem lesson) {
  final run =
      LiteRun(seed: 12773, hero: LiteHero.evasore, weapon: LiteWeapon.guanti)
        ..stage = 5
        ..restHub = true
        ..position = _source
        ..obser = 1000
        ..enemies.clear()
        ..fauna.clear()
        ..obstacles.clear();
  expect(run.buyRestItem(lesson), isTrue);
  expect(run.supply.hasGrimoire, isTrue);
  expect(run.activeArt(), lesson.art);
  run.restHub = false;
  return run;
}

void _advance(
  LiteRun run,
  int frames, {
  Point<double> move = const Point(0, 0),
}) {
  for (var i = 0; i < frames; i++) {
    run.advanceFrame(.01, move: move);
  }
}

void main() {
  test(
    'Eco velata adds two temporary shadow copies with the current weapon',
    () {
      final run = _study(LiteRestItem.artEcoVelata);
      final energy = run.oculum;
      expect(run.useLearnedArt(_aim), isTrue);
      expect(run.clones, hasLength(2));
      expect(
        run.clones.every(
          (copy) => copy.weapon == run.weapon && copy.expiresAfter == 8,
        ),
        isTrue,
      );
      expect(run.oculum, energy - LiteLearnedArt.ecoVelata.cost);
      expect(run.useLearnedArt(_aim), isFalse);
      final restored = LiteRun.fromJson(run.toJson());
      expect(restored.clones, hasLength(2));
      expect(restored.activeArt(), LiteLearnedArt.ecoVelata);
    },
  );

  test('Passo senza luce moves continuously and stops against a wall', () {
    final run = _study(LiteRestItem.artPassoSenzaLuce)
      ..obstacles.add(LiteObstacle(15.65, 9, .35, 5));
    expect(run.useLearnedArt(_aim), isTrue);
    expect(run.position, _source);
    expect(run.invulnerable, isTrue);
    _advance(run, 4);
    expect(run.position.x, greaterThan(_source.x + .30));
    expect(run.position.x, lessThan(15.35));
    _advance(run, 36);
    expect(run.position.x, inInclusiveRange(15.1, 15.5));
    expect(run.invulnerable, isFalse);
  });

  test('Filo d’Ombra roots its caster, respects cover and turns gradually', () {
    final run = _study(LiteRestItem.artFiloOmbra)
      ..obstacles.add(LiteObstacle(18.4, 9.3, .40, 3.6));
    final front = LiteEnemy(
      61,
      LiteEnemyKind.costrutto,
      const Point(16.6, 11),
      200,
    )..stunned = 10;
    final behind = LiteEnemy(
      62,
      LiteEnemyKind.costrutto,
      const Point(20.3, 11),
      200,
    )..stunned = 10;
    run.enemies.addAll([front, behind]);
    expect(run.useLearnedArt(_aim), isTrue);
    expect(run.shadowRays.single.end.x, lessThan(18.4));
    _advance(run, 8, move: const Point(0, 1));
    expect(run.position, _source);
    expect(front.hp, lessThan(200));
    expect(behind.hp, 200);
    run.lookAt(const Point(14, 21));
    _advance(run, 19, move: const Point(0, 1));
    expect(run.position, _source);
    expect(run.shadowRays.single.direction.y, inInclusiveRange(.10, .25));
    final copy = LiteRun.fromJson(run.toJson(includeEffects: true));
    expect(
      copy.shadowRays.single.direction.y,
      closeTo(run.shadowRays.single.direction.y, .005),
    );
    run.setBlocking(true);
    _advance(run, 1);
    expect(run.shadowRays, isEmpty);
  });
}
