import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum_rl/game/oculum_lite_run.dart';

LiteRun _gate({int floor = 13}) {
  final run = LiteRun(
    seed: 13,
    hero: LiteHero.evasore,
    weapon: LiteWeapon.arco,
    explorationRoutes: true,
    difficulty: LiteDifficulty.moltoFacile,
  );
  run.enemies.clear();
  run.obstacles.clear();
  run
    ..stage = floor
    ..stageClear = true
    ..position = run.bossRushGate
    ..shield = 50000;
  return run;
}

void _seconds(LiteRun run, double amount) {
  var remaining = amount;
  while (remaining > 1e-8) {
    final frame = remaining > .125 ? .125 : remaining;
    run.step(frame);
    remaining -= frame;
  }
}

void main() {
  test('optional gate only after floor 12, normal boss and exits closed', () {
    expect(_gate(floor: 12).hasBossRushGate, isFalse);
    final run = _gate();
    expect(run.hasBossRushGate, isTrue);
    expect(run.enterBossRush(), isTrue);
    expect(run.enterBossRush(), isFalse);
    expect(run.bossRushDeployed, 1);
    expect(run.enemies.single.kind, LiteEnemyKind.luce);
    expect(run.enemies.single.livery, isNull);
    expect(run.enemies.single.exalted, isFalse);
    expect(run.bossRushSecondsToNext, 30);
    expect(run.coopPortalOpen, isFalse);
    run.position = run.portalPosition;
    expect(run.hasPortalNearby, isFalse);
    expect(run.advance(), isFalse);
  });

  test('first can still be alive when the second arrives at 30 seconds', () {
    final run = _gate();
    expect(run.enterBossRush(), isTrue);
    _seconds(run, 29.875);
    expect(run.bossRushDeployed, 1);
    _seconds(run, .125);
    expect(run.bossRushDeployed, 2);
    expect(run.enemies.where((enemy) => enemy.hp > 0), hasLength(2));
  });

  test('solo cinematics freeze the fight clock', () {
    final run = _gate();
    expect(run.enterBossRush(), isTrue);
    expect(run.useOpen(run.position + const Point(1, 0)), isTrue);
    run.advanceFrame(.40);
    expect(run.bossRushSecondsToNext, 30);
    expect((run.toJson()['bossRush'] as Map)['elapsed'], 0);
  });

  test('third is at 45 if first falls by 16, or at 60 otherwise', () {
    for (final (firstAt, thirdAt) in [(15.75, 45.0), (17.0, 60.0)]) {
      var run = _gate();
      expect(run.enterBossRush(), isTrue);
      _seconds(run, firstAt);
      run.enemies.first.hp = 0;
      _seconds(run, .125);
      expect(run.bossRushDeployed, 2);
      run = LiteRun.fromJson(run.toJson());
      _seconds(run, thirdAt - firstAt - .25);
      expect(run.bossRushDeployed, 2);
      _seconds(run, .125);
      expect(run.bossRushDeployed, 3);
    }
  });

  test('second death advances immediately and victory pays once', () {
    var run = _gate();
    expect(run.enterBossRush(), isTrue);
    final originalLevel = run.level;
    run.exp = 13;
    for (var wave = 1; wave <= 3; wave++) {
      expect(run.bossRushDeployed, wave);
      run.enemies.single.hp = 0;
      _seconds(run, .125);
    }
    expect(run.bossRushActive, isFalse);
    expect(run.stageClear, isTrue);
    expect(run.level, originalLevel + 1);
    expect(run.exp, 13);
    expect(run.hp, run.maxHp);
    run = LiteRun.fromJson(run.toJson());
    expect(run.hasBossRushGate, isFalse);
    expect(run.enterBossRush(), isFalse);
    _seconds(run, 1);
    expect(run.level, originalLevel + 1);
    expect(run.coopPortalOpen, isTrue);
  });
}
