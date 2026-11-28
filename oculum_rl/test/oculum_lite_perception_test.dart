import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum_rl/game/oculum_lite_run.dart';

LiteRun _newRun({
  LiteBiome biome = LiteBiome.deserto,
  int players = 1,
  int seed = 41119,
  LiteWeapon weapon = LiteWeapon.guanti,
}) => LiteRun(
  seed: seed,
  explorationRoutes: true,
  biome: biome,
  playerCount: players,
  hero: LiteHero.evasore,
  weapon: weapon,
);

LiteEnemy _place(LiteEnemy enemy, Point<double> point, Point<double> facing) {
  enemy.position = point;
  enemy.guard = LiteGuard(point)..facing = facing;
  return enemy;
}

LiteRun _roundTrip(LiteRun run, {bool temporal = false}) => LiteRun.fromJson(
  jsonDecode(jsonEncode(run.toJson(includeEffects: temporal)))
      as Map<String, dynamic>,
);

void _settle(LiteRun run, {bool walk = true}) {
  for (var i = 0; i < 18; i++) {
    run.step(1 / 30, walk: walk);
  }
}

LiteEnemy _focusOn(LiteRun run) {
  final enemy = run.enemies.first;
  run.enemies.removeWhere((other) => other != enemy);
  run.obstacles.clear();
  return _place(enemy, const Point(24, 7), const Point(-1, 0))..cooldown = 90;
}

void _showTo(LiteRun run, LiteEnemy enemy) {
  enemy.position = const Point(24, 7);
  enemy.guard!.facing = const Point(-1, 0);
  run.position = const Point(20, 7);
  run.step(1 / 120);
}

void _stepFor(LiteRun run, double seconds, {bool hide = true}) {
  if (hide) run.position = const Point(3, 21);
  for (var rest = seconds; rest > 1e-9;) {
    final slice = min(rest, .10);
    for (final guest in run.coopFighters) {
      run.setCoopControls(
        guest.account,
        const Point(0, 0),
        guest.position,
        attack: false,
        slow: true,
      );
    }
    run.step(slice);
    rest -= slice;
  }
}

void main() {
  test(
    'a new ordinary monster senses running, walking and a blocked sight line',
    () {
      final run = _newRun();
      final foe = run.enemies.first;
      expect(foe.kind, LiteEnemyKind.rasvyr);
      expect(foe.guard, isNotNull);
      run.enemies
        ..clear()
        ..add(foe);
      run.obstacles.clear();
      run.position = const Point(14, 5);
      _place(foe, const Point(21, 5), const Point(1, 0));
      run.step(.025, move: const Point(1, 0), walk: true);
      expect(foe.guard!.mode, LiteGuardMode.ronda);
      run.step(.025, move: const Point(1, 0));
      expect(foe.guard!.mode, LiteGuardMode.indaga);

      run.position = const Point(16, 5);
      _place(foe, const Point(19, 5), const Point(-1, 0));
      run.obstacles.add(LiteObstacle(17.35, 4, .5, 2, fixedMap: true));
      run.step(.025, walk: true);
      expect(foe.guard!.mode, LiteGuardMode.ronda);
      run.obstacles.clear();
      run.step(.025, walk: true);
      expect(foe.guard!.mode, LiteGuardMode.allerta);
    },
  );

  test(
    'machines and predators distinguish the same sound at different distances',
    () {
      final postea = _newRun(biome: LiteBiome.postea);
      final desert = _newRun();
      final tested = [
        postea.enemies.firstWhere(
          (enemy) => enemy.kind == LiteEnemyKind.dronePostea,
        ),
        desert.enemies.first,
      ];
      for (final (i, run) in [postea, desert].indexed) {
        final foe = tested[i];
        expect(foe.guard, isNotNull);
        run.enemies
          ..clear()
          ..add(foe);
        run.obstacles.clear();
        run.position = const Point(14, 4);
        _place(foe, const Point(21, 4), const Point(1, 0));
        run.step(.025, move: const Point(1, 0));
        expect(
          foe.guard!.mode,
          i == 0 ? LiteGuardMode.ronda : LiteGuardMode.indaga,
        );
      }
    },
  );

  test('a Force blow only goes silent if ordinary damage actually kills', () {
    for (final (lethal, detected) in [
      (true, false),
      (false, false),
      (true, true),
    ]) {
      final run = _newRun();
      final foe = run.enemies.first;
      run.enemies
        ..clear()
        ..add(foe);
      run.obstacles.clear();
      run.position = const Point(21, 5);
      _place(foe, const Point(23, 5), const Point(1, 0));
      final before = lethal ? run.weaponDamage - 1 : run.weaponDamage + 7;
      foe.hp = before;
      if (detected) {
        foe.guard!
          ..mode = LiteGuardMode.allerta
          ..attention = 5;
      }
      run.step(.025, walk: true);
      expect(
        foe.guard!.mode,
        detected ? LiteGuardMode.allerta : LiteGuardMode.ronda,
      );
      expect(run.attack(foe.position), isTrue);
      _settle(run);
      expect(foe.hp, lethal ? 0 : closeTo(7, 1e-8));
      final impact = run.combatImpacts.singleWhere(
        (effect) => effect.subjectId == foe.id,
      );
      expect(impact.silent, lethal && !detected);
      if (!lethal) {
        expect(foe.guard!.mode, LiteGuardMode.allerta);
        final restored = _roundTrip(run);
        expect(restored.enemies.first.guard!.mode, LiteGuardMode.allerta);
        expect(restored.enemies.first.guard!.target, foe.guard!.target);
      }
    }
  });

  test('witnesses alert on sight, while cover hides the silent kill', () {
    for (final covered in [true, false]) {
      final run = _newRun();
      final victim = run.enemies.first;
      final witness = run.enemies[1];
      run.enemies.removeWhere((enemy) => enemy != victim && enemy != witness);
      run.obstacles.clear();
      run.position = const Point(21, 5);
      _place(victim, const Point(23, 5), const Point(1, 0));
      _place(witness, const Point(26, 5), const Point(-1, 0));
      if (covered) {
        run.obstacles.add(LiteObstacle(24.5, 4, .4, 2, fixedMap: true));
      }
      victim.hp = 3;
      run.step(.025, walk: true);
      expect(witness.guard!.mode, LiteGuardMode.ronda);
      expect(run.attack(victim.position), isTrue);
      _settle(run);
      expect(victim.hp, 0);
      expect(
        run.defeats
            .singleWhere((effect) => effect.subjectId == victim.id)
            .silent,
        isTrue,
      );
      expect(
        witness.guard!.mode,
        covered ? LiteGuardMode.ronda : LiteGuardMode.allerta,
      );
      final previousExp = run.exp;
      final previousLoot = run.loot.length;
      final replay = _roundTrip(run);
      expect(replay.enemies.any((enemy) => enemy.id == victim.id), isFalse);
      _settle(replay);
      expect(replay.exp, previousExp);
      expect(replay.loot.length, previousLoot);
    }
  });

  test('a lethal cut from a blade is heard without a line of sight', () {
    final run = _newRun(weapon: LiteWeapon.spadaScudo);
    final victim = run.enemies.first;
    final witness = run.enemies[1];
    run.enemies.removeWhere((enemy) => enemy != victim && enemy != witness);
    run.obstacles.clear();
    run.position = const Point(21, 5);
    _place(victim, const Point(23, 5), const Point(1, 0));
    _place(witness, const Point(27.5, 5), const Point(-1, 0));
    // The wall covers both the origin and the hit. It does not silence the blade.
    run.obstacles.add(LiteObstacle(24.5, 4, .4, 2, fixedMap: true));
    victim.hp = 3;
    run.step(.025, walk: true);
    expect(run.attack(victim.position), isTrue);
    _settle(run);
    expect(victim.hp, 0);
    expect(
      run.defeats.singleWhere((effect) => effect.subjectId == victim.id).silent,
      isFalse,
    );
    expect(witness.guard!.mode, isNot(LiteGuardMode.ronda));
  });

  test(
    'the co-op host resolves the guest’s Force kill and checkpoints it once',
    () {
      var run = _newRun(players: 2);
      expect(
        run.addCoopFighter(
          'guest',
          'Ospite',
          LiteHero.evasore,
          LiteWeapon.guanti,
        ),
        isTrue,
      );
      final victim = run.enemies.first;
      run.enemies
        ..clear()
        ..add(victim);
      run.obstacles.clear();
      var guest = run.coopFighters.single;
      guest
        ..position = const Point(21, 5)
        ..cooldown = 0;
      _place(victim, const Point(23, 5), const Point(1, 0));
      victim.hp = 3;
      run = _roundTrip(run, temporal: true);
      guest = run.coopFighters.single;
      final target = run.enemies.single;
      expect(target.guard!.mode, LiteGuardMode.ronda);
      expect(
        run.setCoopControls(
          guest.account,
          const Point(0, 0),
          target.position,
          attack: true,
          slow: true,
        ),
        isTrue,
      );
      _settle(run);
      expect(target.hp, 0);
      expect(
        run.defeats
            .singleWhere((effect) => effect.subjectId == target.id)
            .silent,
        isTrue,
      );
      final savedExp = guest.experience;
      expect(savedExp, greaterThan(0));
      run = _roundTrip(run, temporal: true);
      _settle(run);
      expect(run.coopFighters.single.experience, savedExp);
      expect(run.enemies.any((enemy) => enemy.id == target.id), isFalse);
    },
  );

  test('a promoted miniboss and a boss attack without spotting the runner', () {
    final run = _newRun();
    run.enemies.clear();
    run.step(.025);
    final champion = run.enemies.single;
    expect(champion.kind, LiteEnemyKind.rasvyr);
    expect(champion.chamberSeat, isNotNull);
    expect(champion.guard, isNull);
    run.obstacles.clear();
    run.position = champion.position - const Point(4.1, 0);
    final old = champion.position;
    run.step(.025, walk: true);
    expect(champion.attackTarget, isNotNull);
    expect(
      champion.position.distanceTo(run.position),
      lessThan(old.distanceTo(run.position)),
    );

    for (var i = 0; i < 3; i++) {
      run.stageClear = true;
      run.position = run.portalPosition;
      expect(run.advance(), isTrue);
    }
    expect(run.stage, 3);
    run.enemies.clear();
    run.step(.025);
    final boss = run.enemies.firstWhere((enemy) => enemy.kind.boss);
    expect(boss.kind, LiteEnemyKind.luce);
    expect(boss.guard, isNull);
    run.obstacles.clear();
    run.position = boss.position - const Point(4.2, 0);
    run.step(.025, walk: true);
    expect(boss.attackTarget, isNotNull);
  });

  test('an incoming guest is quiet on foot and audible during a dash', () {
    final run = _newRun(players: 2);
    expect(
      run.addCoopFighter(
        'guest',
        'Ospite',
        LiteHero.evasore,
        LiteWeapon.guanti,
      ),
      isTrue,
    );
    final guest = run.coopFighters.single;
    final enemy = run.enemies.first;
    run.enemies.removeWhere((other) => other != enemy);
    run.obstacles.clear();
    guest.position = const Point(14, 5);
    _place(enemy, const Point(21, 5), const Point(1, 0));
    expect(run.inExplorationAtrium(run.position), isTrue);
    expect(
      run.setCoopControls(
        guest.account,
        const Point(1, 0),
        enemy.position,
        attack: false,
        slow: true,
      ),
      isTrue,
    );
    run.step(.025);
    expect(enemy.guard!.mode, LiteGuardMode.ronda);
    expect(
      run.setCoopControls(
        guest.account,
        const Point(1, 0),
        enemy.position,
        attack: false,
        slow: true,
        dash: true,
      ),
      isTrue,
    );
    run.step(.025);
    expect(enemy.guard!.mode, LiteGuardMode.indaga);
    expect(enemy.guard!.target!.distanceTo(guest.position), lessThan(1e-8));
    expect(enemy.guard!.target, isNot(run.position));
  });

  test('old exploration checkpoints retain an already engaged opponent', () {
    final run = _newRun();
    final old = run.enemies.first;
    old.guard = null;
    old.attackTarget = const Point(21, 5);
    final restored = _roundTrip(run);
    final foe = restored.enemies.firstWhere((enemy) => enemy.id == old.id);
    expect(foe.guard!.mode, LiteGuardMode.allerta);
    expect(foe.guard!.target, old.attackTarget);
  });

  test('fauna in a quiet region does not become a combat patrol', () {
    final run = _newRun(biome: LiteBiome.foresta);
    expect(run.fauna, isNotEmpty);
    final wolves = run.fauna.where(
      (enemy) => enemy.kind == LiteEnemyKind.lupoLunare,
    );
    expect(wolves, isNotEmpty);
    for (final animal in run.fauna) {
      expect(animal.guard, isNull);
      expect(run.enemies, isNot(contains(animal)));
    }
  });

  test(
    'reacquisition gives 1.3 seconds only after ten seconds without eyes',
    () {
      var run = _newRun();
      var enemy = _focusOn(run);
      _showTo(run, enemy);
      expect(run.spottingWarningRemaining(), 0);
      expect(enemy.guard!.mode, LiteGuardMode.allerta);
      _stepFor(run, 9.8);
      _showTo(run, enemy);
      expect(run.spottingWarningRemaining(), 0);

      _stepFor(run, 10.02);
      _showTo(run, enemy);
      expect(run.spottingWarningRemaining(), closeTo(1.3, 1e-8));
      expect(enemy.attackTarget, isNull);
      _stepFor(run, .52, hide: false);
      run = _roundTrip(run, temporal: true);
      enemy = run.enemies.single;
      expect(run.spottingWarningRemaining(), closeTo(.78, 1e-8));
      _stepFor(run, .77, hide: false);
      expect(run.spottingWarningRemaining(), closeTo(.01, 1e-8));
      expect(enemy.attackTarget, isNull);
      _stepFor(run, .02, hide: false);
      expect(run.spottingWarningRemaining(), 0);
      expect(enemy.attackTarget, isNotNull);
    },
  );

  test('a canceled warning does not restart until another quiet interval', () {
    final run = _newRun();
    final enemy = _focusOn(run);
    _showTo(run, enemy);
    _stepFor(run, 10.1);
    _showTo(run, enemy);
    expect(run.spottingWarningRemaining(), closeTo(1.3, 1e-8));
    _stepFor(run, .35, hide: false);
    _stepFor(run, .1);
    expect(run.spottingWarningRemaining(), 0);
    _showTo(run, enemy);
    expect(run.spottingWarningRemaining(), 0);
    expect(enemy.attackTarget, isNotNull);
  });

  test('a second guard keeps the sight clock active but the guest has a separate clock', () {
    final run = _newRun(players: 2);
    expect(
      run.addCoopFighter('guest', 'Ospite', LiteHero.evasore, LiteWeapon.arco),
      isTrue,
    );
    final guest = run.coopFighters.single;
    final first = run.enemies.first;
    final second = run.enemies[1];
    run.enemies.removeWhere((enemy) => enemy != first && enemy != second);
    run.obstacles.clear();
    _place(first, const Point(24, 7), const Point(-1, 0));
    _place(second, const Point(23, 13), const Point(1, 0));
    first.cooldown = second.cooldown = 90;
    run.position = const Point(20, 7);
    guest.position = const Point(25, 13);
    _stepFor(run, .025, hide: false);
    expect(run.spottingWarningRemaining(guest), 0);
    expect(second.guard!.mode, LiteGuardMode.allerta);
    // The host moves to the second guard, who sees him while the guest hides.
    run.position = const Point(25, 13);
    guest.position = const Point(3, 21);
    _stepFor(run, 10.1, hide: false);
    run.position = const Point(20, 7);
    guest.position = const Point(25, 13);
    first.position = const Point(24, 7);
    first.guard!.facing = const Point(-1, 0);
    second.position = const Point(23, 13);
    second.guard!.facing = const Point(1, 0);
    _stepFor(run, .025, hide: false);
    expect(run.spottingWarningRemaining(), 0);
    expect(run.spottingWarningRemaining(guest), closeTo(1.3 - 2 / 120, .02));
  });

  test('an alert witness can follow a bush entry and a second guard cannot share it', () {
    var run = _newRun();
    var first = run.enemies.first;
    var second = run.enemies[1];
    run.enemies.removeWhere((enemy) => enemy != first && enemy != second);
    run.obstacles.clear();
    final bush = run.concealmentBushes.last;
    _place(first, bush.center - const Point(3.6, 0), const Point(1, 0));
    _place(second, bush.center + const Point(2.4, 0), const Point(1, 0));
    first.cooldown = second.cooldown = 50;
    run.position = bush.center - Point(bush.radiusX + .2, 0);
    run.step(1 / 120);
    expect(first.guard!.mode, LiteGuardMode.allerta);
    expect(second.guard!.mode, isNot(LiteGuardMode.allerta));
    run.position = bush.center;
    run.step(1 / 120);
    expect(first.attackTarget, bush.center);
    expect(second.attackTarget, isNull);
    run = _roundTrip(run, temporal: true);
    first = run.enemies[0];
    second = run.enemies[1];
    run.step(1 / 120);
    expect(first.attackTarget, bush.center);
    expect(second.attackTarget, isNull);
  });

  test('a wholly occluded object is unknown and a visible corner can guide a search', () {
    var run = _newRun();
    var enemy = _focusOn(run);
    run.obstacles.addAll([
      LiteObstacle(24, 14.3, 1, 3.4, fixedMap: true),
      LiteObstacle(26.4, 15.3, .5, 1, fixedMap: true),
    ]);
    _place(enemy, const Point(22.8, 16), const Point(1, 0));
    enemy.cooldown = 80;
    run.position = const Point(28, 16);
    run.step(.09);
    expect(enemy.guard!.knownObstacleCount, 1);
    expect(enemy.attackTarget, isNull);
    expect(run.guardVisionOutline(enemy, quiet: false)[3].x, lessThan(24.05));

    // Last legitimate observation from the north side of the known wall.
    enemy.position = const Point(22.8, 13);
    enemy.guard!.facing = const Point(1, 0);
    const previousSight = Point<double>(26.1, 13);
    run.position = previousSight;
    run.step(.025);
    expect(enemy.guard!.lastSeen, previousSight);

    enemy.position = const Point(23, 16);
    run.position = const Point(4, 21);
    run = _roundTrip(run);
    enemy = run.enemies.single;
    _stepFor(run, 1.3, hide: false);
    expect(enemy.attackTarget, isNull);
    expect(enemy.guard!.lastSeen, previousSight);
    expect(enemy.position.y, lessThan(15));
    expect(
      enemy.position.distanceTo(previousSight),
      lessThan(const Point<double>(23, 16).distanceTo(previousSight)),
    );
  });

  test(
    'an unresolved glimpse can trigger a deterministic single investigation',
    () {
      final rolls = <bool>{};
      for (final seed in [9, 14, 23, 33, 49, 41119]) {
        var run = _newRun(seed: seed);
        var enemy = _focusOn(run);
        _showTo(run, enemy);
        _stepFor(run, 10.2);
        enemy.guard!
          ..mode = LiteGuardMode.ronda
          ..attention = 0
          ..target = null;
        _showTo(run, enemy);
        _stepFor(run, .95, hide: false);
        expect(run.spottingWarningRemaining(), greaterThan(0));
        run = _roundTrip(run, temporal: true);
        final mirrored = _roundTrip(run, temporal: true);
        _stepFor(run, .04);
        _stepFor(mirrored, .04);
        enemy = run.enemies.single;
        final other = mirrored.enemies.single;
        final went = enemy.guard!.mode == LiteGuardMode.indaga;
        expect(other.guard!.mode, enemy.guard!.mode);
        expect(enemy.attackTarget, isNull);
        expect(enemy.guard!.mode, isNot(LiteGuardMode.allerta));
        expect(run.toJson()['rng'], mirrored.toJson()['rng']);
        rolls.add(went);
      }
      expect(rolls, {false, true});
    },
  );

  test('the five-field guard frame remains readable', () {
    final guard = LiteGuard.read(const [
      [3, 7],
      'allerta',
      [-1, 0],
      [5, 7],
      3.1,
    ])!;
    expect(guard.target, const Point<double>(5, 7));
    expect(guard.lastSeen, guard.target);
    expect(guard.mode, LiteGuardMode.allerta);
    expect(guard.knownObstacleCount, 0);
  });

  test('a faster floor still gives the actual one point three seconds', () {
    final run = _newRun()..stage = 7;
    expect(run.arenaSpeed, greaterThan(1));
    final enemy = _focusOn(run);
    _showTo(run, enemy);
    run.position = const Point(3, 21);
    for (var i = 0; i < 101; i++) {
      run.advanceFrame(.10);
    }
    enemy.position = const Point(24, 7);
    enemy.guard!.facing = const Point(-1, 0);
    run.position = const Point(20, 7);
    run.advanceFrame(.01);
    expect(run.spottingWarningRemaining(), closeTo(1.3, .01));
    for (var i = 0; i < 12; i++) {
      run.advanceFrame(.10);
    }
    expect(run.spottingWarningRemaining(), closeTo(.10, .01));
    expect(enemy.attackTarget, isNull);
    run.advanceFrame(.11);
    expect(run.spottingWarningRemaining(), 0);
    expect(enemy.attackTarget, isNotNull);
  });

  test(
    'a bat is not a sight target and the previous last sight is retained',
    () {
      final host = LiteRun(
        seed: 41119,
        explorationRoutes: true,
        biome: LiteBiome.deserto,
        hero: LiteHero.vampiro,
        weapon: LiteWeapon.guanti,
      );
      final guard = _focusOn(host);
      _showTo(host, guard);
      final memory = guard.guard!.lastSeen;
      expect(guard.attackTarget, isNotNull);
      expect(host.special(const Point(25, 7)), isTrue);
      host.position = const Point(20.7, 5);
      host.step(.025, move: const Point(1, 0));
      expect(guard.attackTarget, isNull);
      expect(guard.guard!.lastSeen, memory);

      final party = _newRun(players: 2);
      expect(
        party.addCoopFighter(
          'guest',
          'Ospite',
          LiteHero.vampiro,
          LiteWeapon.guanti,
        ),
        isTrue,
      );
      final guest = party.coopFighters.single;
      final watcher = _focusOn(party);
      guest.position = const Point(20, 7);
      expect(
        party.setCoopControls(
          guest.account,
          const Point(0, 0),
          watcher.position,
          attack: false,
          dodge: true,
        ),
        isTrue,
      );
      expect(guest.night.bat, greaterThan(0));
      expect(party.inExplorationAtrium(party.position), isTrue);
      party.step(.025);
      expect(watcher.attackTarget, isNull);
      expect(watcher.guard!.lastSeen, isNull);
      expect(watcher.guard!.mode, LiteGuardMode.ronda);
    },
  );

  test(
    'perception payload stays below the live frame limit with six seats',
    () {
      final run = _newRun(players: 6);
      for (var seat = 1; seat < 6; seat++) {
        expect(
          run.addCoopFighter(
            'guest-$seat',
            'Ospite $seat',
            LiteHero.evasore,
            LiteWeapon.arco,
          ),
          isTrue,
        );
      }
      run.obstacles.clear();
      for (var i = 0; i < 6; i++) {
        run.obstacles.add(LiteObstacle(21.7 + i * .9, 3.7, .38, 1.0));
        run.obstacles.add(LiteObstacle(21.7 + i * .9, 8.5, .38, 1.0));
      }
      for (final (i, foe) in run.enemies.indexed) {
        _place(foe, Point(25.0 + i * .3, 6.8), const Point(-1, 0));
        foe.cooldown = 100;
      }
      run.position = const Point(21, 6);
      for (final (i, guest) in run.coopFighters.indexed) {
        guest.position = Point(20.8, 5.4 + i * .18);
      }
      _stepFor(run, 1.4, hide: false);
      expect(
        run.enemies.any((foe) => foe.guard!.knownObstacleCount >= 2),
        isTrue,
      );
      final size = utf8
          .encode(
            jsonEncode({
              'kind': 'playState',
              'world': run.toJson(includeEffects: true),
            }),
          )
          .length;
      expect(size, lessThan(46000));
    },
  );
}
