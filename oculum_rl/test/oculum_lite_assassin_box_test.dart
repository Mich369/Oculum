import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum_rl/game/oculum_lite_run.dart';

const _still = Point<double>(0, 0);
const _east = Point<double>(1, 0);
const _west = Point<double>(-1, 0);
const _assassin = Point<double>(18, 3);
const _guardAt = Point<double>(23, 3);

LiteRun _world({bool party = false}) =>
    LiteRun(
        seed: 41120,
        hero: party ? LiteHero.evasore : LiteHero.assassino,
        weapon: LiteWeapon.guanti,
        biome: LiteBiome.deserto,
        explorationRoutes: true,
        playerCount: party ? 2 : 1,
      )
      ..position = party ? const Point(4, 4) : _assassin
      ..enemies.clear()
      ..obstacles.clear();

LiteEnemy _guard(LiteRun run, Point<double> facing) {
  final sentry = LiteEnemy(801, LiteEnemyKind.rasvyr, _guardAt, 120)
    ..cooldown = 99
    ..guard = (LiteGuard(_guardAt)..facing = facing);
  run.enemies.add(sentry);
  return sentry;
}

LiteRun _restore(LiteRun run) => LiteRun.fromJson(
  jsonDecode(jsonEncode(run.toJson(includeEffects: true)))
      as Map<String, dynamic>,
);

void _hit(LiteRun run, Point<double> point) {
  run.projectiles.add(
    LiteProjectile(
      position: point - _east * 1.5,
      direction: _east,
      speed: 15,
      remaining: 3,
      damage: 10,
      fromEnemy: true,
    ),
  );
  run.step(.18);
}

bool _input(LiteRun world, {bool box = false, bool dash = false}) =>
    world.setCoopControls(
      'guest',
      _still,
      _west,
      attack: false,
      dash: dash,
      assassinBox: box,
    );

void main() {
  test('unseen disguise survives a guard turning and forces slow walking', () {
    final run = _world();
    final guard = _guard(run, _east);
    expect(run.toggleAssassinBox(), isTrue);
    guard.guard!.facing = _west;
    run.step(.2, move: _west);
    expect(run.assassinBoxActive, isTrue);
    expect(run.quietSteps, isTrue);
    expect(run.position.distanceTo(_assassin), closeTo(.33, .02));
    expect(guard.guard!.mode, LiteGuardMode.ronda);
    expect(guard.guard!.lastSeen, isNull);

    expect(run.toggleAssassinBox(), isTrue);
    guard.guard!.facing = _west;
    run.position = _assassin;
    run.step(.02);
    expect(run.assassinBoxActive, isFalse);
    expect(guard.guard!.mode, LiteGuardMode.allerta);
  });

  test('a witness sees the disguise until actual cover breaks contact', () {
    var run = _world();
    _guard(run, _west);
    expect(run.toggleAssassinBox(), isTrue);
    expect(run.toJson()['assassinBox'], [801]);
    run = _restore(run);
    final guard = run.enemies.single;
    run.step(.04);
    expect(guard.guard!.mode, LiteGuardMode.allerta);
    expect(guard.guard!.lastSeen, _assassin);

    run.obstacles.add(LiteObstacle(19.5, 2, .6, 3, fixedMap: true));
    run.step(.02);
    expect(run.assassinBoxActive, isTrue);
    expect(run.toJson()['assassinBox'], isEmpty);
    run.obstacles.clear();
    run.position = const Point(18, 3.7);
    run.step(.02);
    expect(guard.guard!.lastSeen, _assassin);
  });

  test('successful melee, dash and shield damage open the box', () {
    final attacking = _world();
    _guard(attacking, _east);
    expect(attacking.toggleAssassinBox(), isTrue);
    expect(attacking.attack(_guardAt), isTrue);
    expect(attacking.assassinBoxActive, isFalse);

    final dashing = _world();
    _guard(dashing, _east);
    expect(dashing.toggleAssassinBox(), isTrue);
    expect(dashing.dash(_assassin + _west), isTrue);
    expect(dashing.assassinBoxActive, isFalse);
    expect(dashing.assassinVeilRemaining, 3);

    final shielded = _world();
    _guard(shielded, _east);
    shielded.shield = 60;
    final life = shielded.hp;
    expect(shielded.toggleAssassinBox(), isTrue);
    _hit(shielded, _assassin);
    expect(shielded.hp, life);
    expect(shielded.shield, lessThan(60));
    expect(shielded.assassinBoxActive, isFalse);
  });

  test(
    'authority restores the disguise per guest and opens it on guest dash',
    () {
      var host = _world(party: true);
      _guard(host, _east);
      expect(host.toggleAssassinBox(), isFalse);
      expect(
        host.addCoopFighter(
          'guest',
          'Assassino',
          LiteHero.assassino,
          LiteWeapon.doppieLame,
        ),
        isTrue,
      );
      host.coopFighter('guest')!.position = _assassin;

      expect(_input(host, box: true), isTrue);
      expect(host.coopFighter('guest')!.assassinBoxActive, isTrue);
      host = _restore(host);
      expect(host.coopFighter('guest')!.assassinBoxActive, isTrue);
      expect(host.assassinBoxActive, isFalse);

      final legacy = host.toJson();
      ((legacy['fighters'] as List).single as Map).remove('assassinBox');
      expect(
        LiteRun.fromJson(legacy).coopFighter('guest')!.assassinBoxActive,
        isFalse,
      );
      expect(_input(host, dash: true), isTrue);
      expect(host.coopFighter('guest')!.assassinBoxActive, isFalse);
      expect(host.assassinVeilRemaining, 3);
    },
  );
}
