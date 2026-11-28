import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum_rl/game/oculum_lite_run.dart';

LiteRun _run({
  int seed = 41120,
  LiteHero hero = LiteHero.evasore,
  int players = 1,
}) => LiteRun(
  seed: seed,
  explorationRoutes: true,
  biome: LiteBiome.deserto,
  playerCount: players,
  hero: hero,
  weapon: LiteWeapon.guanti,
);

LiteRun _restore(LiteRun world, {bool effects = false}) => LiteRun.fromJson(
  jsonDecode(jsonEncode(world.toJson(includeEffects: effects)))
      as Map<String, dynamic>,
);

void _eliminateGuard(
  LiteRun world, {
  String? guest,
  bool witnessed = false,
  bool alert = false,
}) {
  const attackFrom = Point<double>(21, 5);
  const contact = Point<double>(23, 5);
  final guard = LiteEnemy(901 + world.stage, LiteEnemyKind.rasvyr, contact, 3)
    ..guard = (LiteGuard(contact)
      ..facing = const Point(1, 0)
      ..attention = alert ? 5 : 0
      ..mode = alert ? LiteGuardMode.allerta : LiteGuardMode.ronda);
  world
    ..position = guest == null ? attackFrom : const Point(3, 21)
    ..obstacles.clear()
    ..enemies.clear()
    ..enemies.add(guard);
  if (witnessed) {
    const witness = Point<double>(26, 5);
    world.enemies.add(
      LiteEnemy(920, LiteEnemyKind.scostubandito, witness, 500)
        ..cooldown = 90
        ..guard = (LiteGuard(witness)..facing = const Point(-1, 0)),
    );
  }
  if (guest == null) {
    world.step(.025, walk: true);
    expect(world.attack(contact), isTrue);
  } else {
    world.coopFighter(guest)!
      ..position = attackFrom
      ..cooldown = 0;
    expect(
      world.setCoopControls(
        guest,
        const Point(0, 0),
        contact,
        attack: true,
        slow: true,
      ),
      isTrue,
    );
  }
  for (var i = 0; i < 18; i++) {
    world.step(1 / 30, walk: true);
  }
  expect(guard.hp, 0);
  expect(
    world.defeats.firstWhere((event) => event.subjectId == guard.id).silent,
    !alert,
  );
}

void _clearFloor(LiteRun world) {
  for (var phase = 0; phase < 4 && !world.stageClear; phase++) {
    world.enemies.clear();
    world.step(.025);
  }
  expect(world.stageClear, isTrue);
}

void _next(LiteRun world) {
  _clearFloor(world);
  world.position = world.portalPosition;
  final moved = world.playerCount == 1
      ? world.advance(LiteBiome.deserto)
      : world.advanceCoop(LiteBiome.deserto);
  expect(moved, isTrue);
}

bool _unlocked(LiteRun world, [String? guest]) => world
    .unlockedHeroesFor(LiteHero.evasore, guestAccount: guest)
    .contains(LiteHero.assassino);

Map<String, dynamic> _progress(LiteRun world) =>
    Map<String, dynamic>.from(world.toJson()['assassinStealth'] as Map? ?? {});

void _advance(LiteRun world, double duration) {
  for (var left = duration; left > 1e-9;) {
    final part = min(.10, left);
    world.advanceFrame(part);
    left -= part;
  }
}

void main() {
  test('one personal silent finish on every eligible floor unlocks on floor 3 clear', () {
    var world = _run();
    for (var floor = 0; floor <= 3; floor++) {
      expect(world.stage, floor);
      _eliminateGuard(world);
      expect(_unlocked(world), isFalse);
      if (floor < 3) _next(world);
      if (floor == 1) world = _restore(world);
    }
    _clearFloor(world);
    expect(_unlocked(world), isTrue);
    expect(_unlocked(_restore(world)), isTrue);
    expect(_progress(world)['floors'], {'': 15});
  });

  test('a witness or an alert victim does not earn that floor', () {
    final world = _run();
    _eliminateGuard(world, witnessed: true);
    expect(_progress(world)['floors'], isNull);
    _next(world);
    _eliminateGuard(world, alert: true);
    expect(_progress(world)['floors'], isNull);
    _next(world);
    _eliminateGuard(world);
    _next(world);
    _eliminateGuard(world);
    _clearFloor(world);
    expect(_unlocked(world), isFalse);
    expect(_progress(world)['floors'], {'': 12});
  });

  test(
    'a generated bush ambush is excluded and remains marked after saving',
    () {
      var world = _run(seed: 41119);
      var excluded = 0;
      for (var floor = 0; floor <= 3; floor++) {
        final masked = (_progress(world)['ambush'] as int? ?? 0) & (1 << floor);
        if (masked != 0) {
          excluded |= masked;
          world = _restore(world);
        }
        _eliminateGuard(world);
        if (floor < 3) _next(world);
      }
      expect(excluded, isNot(0));
      _clearFloor(world);
      expect(_progress(world)['ambush'], excluded);
      expect(_progress(world)['floors'], {'': 15 & ~excluded});
      expect(_unlocked(world), isTrue);
    },
  );

  test('a guest earns their own Assassin and never credits the host or another guest', () {
    var world = _run(players: 3);
    for (final account in ['finisher', 'spectator']) {
      expect(
        world.addCoopFighter(
          account,
          account,
          LiteHero.evasore,
          LiteWeapon.guanti,
        ),
        isTrue,
      );
    }
    for (var floor = 0; floor <= 3; floor++) {
      _eliminateGuard(world, guest: 'finisher');
      if (floor < 3) _next(world);
      if (floor == 1) world = _restore(world, effects: true);
    }
    _clearFloor(world);
    expect(_progress(world)['floors'], {'finisher': 15});
    expect(_unlocked(world, 'finisher'), isTrue);
    expect(_unlocked(world, 'spectator'), isFalse);
    expect(_unlocked(world), isFalse);
  });

  test(
    'three real seconds of shared sight veil, six seconds between dashes',
    () {
      var world = _run(hero: LiteHero.assassino, players: 2);
      expect(
        world.addCoopFighter(
          'guest',
          'Ospite',
          LiteHero.evasore,
          LiteWeapon.guanti,
        ),
        isTrue,
      );
      const guardAt = Point<double>(24, 7);
      const partyAt = Point<double>(21, 7);
      world
        ..stage = 18
        ..position = partyAt
        ..obstacles.clear()
        ..enemies.clear()
        ..enemies.add(
          LiteEnemy(821, LiteEnemyKind.scostubandito, guardAt, 999)
            ..cooldown = 90
            ..guard = (LiteGuard(guardAt)..facing = const Point(-1, 0)),
        );
      world.coopFighters.single.position = const Point(20, 7);
      world.clones.add(
        LiteClone(const Point(21, 8), 30, LiteWeapon.guanti, id: 825),
      );
      world.advanceFrame(.02);
      expect(world.enemies.single.attackTarget, isNotNull);
      expect(world.dash(const Point(17, 7)), isTrue);
      expect(world.assassinVeilRemaining, 3);
      expect(world.assassinVeilCooldown, 6);
      expect(world.intangible, isFalse);

      final before = world.hp;
      world.projectiles.add(
        LiteProjectile(
          position: world.position + const Point(-.25, 0),
          direction: const Point(1, 0),
          speed: 9,
          remaining: 4,
          damage: 10,
          fromEnemy: true,
        ),
      );
      _advance(world, .10);
      expect(world.hp, lessThan(before));
      expect(world.enemies.single.attackTarget, isNull);
      final saved = _restore(world, effects: true);
      expect(saved.assassinVeilRemaining, closeTo(2.9, 1e-8));
      world = saved;
      _advance(world, 2.89);
      expect(world.assassinVeilRemaining, closeTo(.01, 1e-8));
      expect(world.enemies.single.attackTarget, isNull);
      _advance(world, .02);
      expect(world.assassinVeilRemaining, 0);
      expect(world.assassinVeilCooldown, closeTo(2.99, 1e-8));

      expect(world.dash(const Point(17, 7)), isTrue);
      expect(world.assassinVeilRemaining, 0);
      _advance(world, 2.99);
      expect(world.assassinVeilCooldown, 0);
      expect(world.dash(const Point(17, 7)), isTrue);
      expect(world.assassinVeilRemaining, 3);
    },
  );

  test('an Assassin guest starts the same timer when crossing a dash pad', () {
    final world = _run(players: 2);
    expect(
      world.addCoopFighter(
        'guest',
        'Ospite',
        LiteHero.assassino,
        LiteWeapon.guanti,
      ),
      isTrue,
    );
    world.obstacles
      ..clear()
      ..add(LiteObstacle(25.75, 0, 2.15, 4.12, dashGap: true, fixedMap: true));
    final guest = world.coopFighters.single..position = world.dashPads.first;
    expect(world.dash(world.position + const Point(0, 1)), isTrue);
    expect(world.assassinVeilRemaining, 0);
    expect(
      world.setCoopControls(
        'guest',
        const Point(1, 0),
        world.dashPads.last,
        attack: false,
        dash: true,
      ),
      isTrue,
    );
    expect(world.burstTraceFor(guest.id)?.kind, LiteBurstKind.phase);
    expect(world.assassinVeilRemaining, 3);
    expect(_restore(world).assassinVeilCooldown, 6);
  });

  test('a boss can aim at memories but cannot take a concealed human or pet position', () {
    final world = _run(players: 2);
    expect(
      world.addCoopFighter(
        'guest',
        'Ospite',
        LiteHero.assassino,
        LiteWeapon.guanti,
      ),
      isTrue,
    );
    final boss = LiteEnemy(
      801,
      LiteEnemyKind.guardianoSolare,
      const Point(24, 5),
      999,
    )..cooldown = 90;
    final guest = world.coopFighters.single..position = const Point(19, 6);
    final pet = LiteClone(
      const Point(17, 5),
      75,
      LiteWeapon.guanti,
      id: 802,
      companion: LiteCompanion.bunnys,
    );
    world
      ..position = const Point(20, 5)
      ..obstacles.clear()
      ..enemies.clear()
      ..enemies.add(boss)
      ..clones.add(pet);
    world.advanceFrame(.045);
    expect(boss.attackTarget, const Point(20, 5));

    expect(
      world.setCoopControls(
        guest.account,
        const Point(-1, 0),
        const Point(13, 6),
        attack: false,
        dash: true,
      ),
      isTrue,
    );
    world.position = const Point(22, 5);
    pet.position = const Point(23, 4.7);
    world.advanceFrame(.045);
    expect(world.assassinVeilRemaining, greaterThan(2.9));
    expect(boss.attackTarget, isIn([const Point(20, 5), const Point(19, 6)]));
    expect(boss.attackTarget, isNot(guest.position));
    expect(boss.attackTarget, isNot(pet.position));
  });
}
