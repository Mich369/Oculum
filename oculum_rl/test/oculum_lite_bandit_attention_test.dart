import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum_rl/game/oculum_lite_run.dart';

const _visible = Point<double>(18, 3);
const _hidden = Point<double>(5, 18);
const _west = Point<double>(-1, 0);

LiteRun _world([int players = 1]) =>
    LiteRun(
        seed: 41120,
        hero: LiteHero.evasore,
        weapon: LiteWeapon.guanti,
        biome: LiteBiome.deserto,
        explorationRoutes: true,
        playerCount: players,
      )
      ..position = _visible
      ..obstacles.clear()
      ..enemies.clear();

LiteEnemy _place(
  LiteRun run,
  LiteEnemyKind kind,
  int id,
  Point<double> at,
  Point<double> facing,
) {
  final enemy = LiteEnemy(id, kind, at, 160)
    ..guard = (LiteGuard(at)..facing = facing)
    ..cooldown = 80;
  run.enemies.add(enemy);
  return enemy;
}

void _tick(LiteRun run, double seconds) {
  for (var rest = seconds; rest > 1e-9;) {
    final slice = min(rest, .1);
    for (final guest in run.coopFighters) {
      run.setCoopControls(
        guest.account,
        const Point(0, 0),
        guest.position,
        attack: false,
      );
    }
    run.step(slice);
    rest -= slice;
  }
}

Iterable<LiteAlertCall> _calls(LiteRun run, LiteEnemyKind kind) =>
    run.alertCalls.where((call) => call.enemy == kind && call.viewerId == null);

void main() {
  for (final kind in [
    LiteEnemyKind.scostubandito,
    LiteEnemyKind.granScostumato,
  ]) {
    final delay = kind == LiteEnemyKind.scostubandito ? 2.0 : 3.0;
    test('$kind broadcasts the actual target location once at $delay s', () {
      var run = _world();
      _place(run, kind, 811, const Point(23, 3), _west);
      _place(
        run,
        LiteEnemyKind.rasvyr,
        812,
        const Point(6, 18),
        const Point(0, 1),
      );
      _tick(run, delay - .12);
      expect(_calls(run, kind), isEmpty);
      expect(run.enemies.last.guard!.lastSeen, isNull);

      run = LiteRun.fromJson(run.toJson(includeEffects: true));
      expect(run.enemies.first.guard!.lastSeen, _visible);
      _tick(run, .14);
      final receiver = run.enemies.last;
      expect(_calls(run, kind), hasLength(1));
      expect(receiver.guard!.mode, LiteGuardMode.allerta);
      expect(receiver.guard!.lastSeen, _visible);
      expect(receiver.attackTarget, isNull);
      run.position = const Point(8, 13);
      _tick(run, .22);
      expect(receiver.guard!.lastSeen, _visible);
      expect(_calls(run, kind), hasLength(1));
    });
  }

  test('another observer postpones the forgetful guard losing a guest', () {
    var run = _world(2)..position = const Point(3, 21);
    expect(
      run.addCoopFighter('g', 'Ospite', LiteHero.evasore, LiteWeapon.guanti),
      isTrue,
    );
    final guest = run.coopFighters.single..position = _visible;
    final bandit = _place(
      run,
      LiteEnemyKind.scostubandito,
      821,
      const Point(23, 3),
      _west,
    );
    final witness = _place(
      run,
      LiteEnemyKind.rasvyr,
      822,
      const Point(18, 5),
      const Point(0, -1),
    );
    _tick(run, .05);
    expect(bandit.guard!.lastSeen, guest.position);

    bandit.guard!.facing = const Point(1, 0);
    bandit.position = const Point(29.5, 3);
    run.obstacles.add(LiteObstacle(22, 0, .7, 13, fixedMap: true));
    _tick(run, 3.07);
    expect(bandit.guard!.mode, LiteGuardMode.allerta);
    expect(witness.guard!.lastSeen, _visible);
    expect(bandit.attackTarget, isNull);

    guest.position = _hidden;
    witness.position = const Point(20, 15);
    _tick(run, 2.89);
    expect(bandit.guard!.mode, LiteGuardMode.allerta);
    expect(bandit.guard!.lastSeen, _visible);
    run = LiteRun.fromJson(run.toJson(includeEffects: true));
    _tick(run, .10);
    expect(run.enemies.first.guard!.mode, LiteGuardMode.allerta);
    _tick(run, .03);
    expect(run.enemies.first.guard!.mode, LiteGuardMode.ronda);
    expect(run.enemies.first.guard!.lastSeen, isNull);
    expect(run.enemies.last.guard!.lastSeen, _visible);
  });
}
