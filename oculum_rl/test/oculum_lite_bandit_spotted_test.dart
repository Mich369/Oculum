import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum_rl/game/oculum_lite_run.dart';

const _source = Point<double>(24, 7);
const _target = Point<double>(20, 7);
const _hidden = Point<double>(3, 21);
const _west = Point<double>(-1, 0);

LiteRun _run(LiteEnemyKind kind, {int players = 1, bool alert = false}) {
  final bandit = LiteEnemy(6100, kind, _source, 120)
    ..guard = (LiteGuard(_source)
      ..facing = _west
      ..mode = alert ? LiteGuardMode.allerta : LiteGuardMode.ronda
      ..attention = alert ? 12 : 0)
    ..cooldown = 80;
  return LiteRun(
      seed: 41119,
      hero: LiteHero.evasore,
      weapon: LiteWeapon.spadaScudo,
      playerCount: players,
      explorationRoutes: true,
      biome: LiteBiome.deserto,
    )
    ..enemies.clear()
    ..enemies.add(bandit)
    ..fauna.clear()
    ..obstacles.clear()
    ..position = _target;
}

Iterable<LiteCombatImpact> _sightings(LiteRun run) => run.combatImpacts.where(
  (event) => event.target == LiteImpactTarget.banditSpotted,
);

void _wait(LiteRun run, double seconds) {
  for (var rest = seconds; rest > 1e-8; rest -= .10) {
    run.step(min(.10, rest));
  }
}

void main() {
  test('a real sighting emits in the current tick, once per alert cycle', () {
    final run = _run(LiteEnemyKind.scostubandito);
    run.step(1 / 120);
    final seen = _sightings(run).single;
    expect(seen.enemyKind, LiteEnemyKind.scostubandito);
    expect(seen.subjectId, 0);
    expect(seen.position, _source);
    expect(seen.end, _target);
    expect(seen.time, run.time);
    expect(run.alertCalls, isEmpty);
    _wait(run, .28);
    expect(_sightings(run).single, same(seen));

    final restored = LiteRun.fromJson(run.toJson(includeEffects: true));
    expect(_sightings(restored).single.time, seen.time);
    restored.step(.07);
    expect(_sightings(restored).single.time, seen.time);

    run.position = _hidden;
    _wait(run, 3.15);
    final bandit = run.enemies.single;
    expect(bandit.guard!.mode, LiteGuardMode.ronda);
    bandit
      ..position = _source
      ..guard!.facing = _west;
    run.position = _target;
    run.step(1 / 120);
    expect(_sightings(run).single.time, greaterThan(seen.time + 3));
  });

  test('a pre-alerted Gran Scostumato waits for real line of sight', () {
    final run = _run(LiteEnemyKind.granScostumato, alert: true);
    run.obstacles.add(LiteObstacle(21.8, 6, .5, 2, fixedMap: true));
    run.step(.10);
    expect(run.enemies.single.guard!.mode, LiteGuardMode.allerta);
    expect(_sightings(run), isEmpty);
    expect(run.alertCalls, isEmpty);

    run.obstacles.clear();
    run.step(1 / 120);
    expect(_sightings(run).single.enemyKind, LiteEnemyKind.granScostumato);
    expect(run.alertCalls, isEmpty);
  });

  test('a targetable old clone with ID zero does not impersonate the host', () {
    final run = _run(LiteEnemyKind.scostubandito)
      ..position = const Point(30, 7);
    // Older checkpoints can keep a clone of an ally who has left the party.
    // It remains targetable independently of the host's stealth.
    final clone = LiteClone(
      _target,
      14,
      LiteWeapon.guanti,
      id: 0,
      ownerId: 3000,
    );
    run.clones.add(clone);
    expect(run.companionConcealed(clone), isFalse);
    run.step(1 / 120);
    expect(run.enemies.single.guard!.mode, LiteGuardMode.allerta);
    expect(_sightings(run), isEmpty);
  });

  test('a guest-only sighting carries the guest ID in the native frame', () {
    final run = _run(LiteEnemyKind.scostubandito, players: 2)
      ..position = _hidden;
    expect(
      run.addCoopFighter('guest', 'G', LiteHero.evasore, LiteWeapon.arco),
      isTrue,
    );
    final guest = run.coopFighter('guest')!..position = _target;
    expect(
      run.setCoopControls(
        'guest',
        const Point(0, 0),
        guest.position,
        attack: false,
      ),
      isTrue,
    );
    run.step(1 / 120);
    final hostCue = _sightings(run).single;
    expect(hostCue.subjectId, guest.id);
    expect(hostCue.subjectId, isNot(0));
    final frame = LiteRun.fromJson(run.toJson(includeEffects: true));
    final guestCue = _sightings(frame).single;
    expect(guestCue.subjectId, guest.id);
    expect(guestCue.enemyKind, LiteEnemyKind.scostubandito);
    expect(guestCue.end, guest.position);
    final saved = LiteRun.fromJson(run.toJson());
    expect(_sightings(saved), isEmpty);
  });
}
