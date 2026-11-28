import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum_rl/game/oculum_lite_run.dart';

LiteRun _newRun({
  LiteBiome biome = LiteBiome.deserto,
  int players = 1,
  LiteWeapon weapon = LiteWeapon.guanti,
}) => LiteRun(
  seed: 41119,
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
}
