import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum_rl/game/oculum_lite_run.dart';
import 'package:oculum_rl/services/oculum_lite_saves.dart';

LiteRun _run({
  LiteHero hero = LiteHero.evasore,
  LiteWeapon weapon = LiteWeapon.arco,
  LiteBiome biome = LiteBiome.campo,
}) => LiteRun(seed: 241, hero: hero, weapon: weapon, biome: biome);

void _expectRouteMatchesFloor({
  required int before,
  required LiteBiome destination,
  bool coop = false,
}) {
  final run =
      LiteRun(
          seed: 6141,
          hero: LiteHero.evasore,
          weapon: LiteWeapon.arco,
          playerCount: coop ? 2 : 1,
        )
        ..stage = before
        ..stageClear = true;
  run.position = run.portalPosition;
  final beforePreview = run.toJson();
  final preview = run.previewNextFloor(destination)!;
  expect(run.toJson(), beforePreview);

  expect(
    coop ? run.advanceCoop(destination) : run.advance(destination),
    isTrue,
  );
  expect(run.biome, preview.biome);
  expect(run.stage, preview.floor);
  expect(run.encounter, preview.encounter);
  expect(run.floorLayout, preview.layout);
  expect(run.hasRest, preview.rest);
  if (preview.encounter == LiteEncounter.finalBoss) {
    expect(preview.openingEnemies, 0);
    expect(preview.featuredPower, isNull);
    expect(run.previewNextFloor(destination), isNull);
  } else {
    expect(run.enemies.length, preview.openingEnemies);
    expect(
      run.enemies.map((enemy) => enemy.kind).toSet(),
      preview.enemyKinds.toSet(),
    );
    run.enemies.clear();
    run.step(.01);
  }
  expect(run.enemies.singleOrNull?.kind, preview.special);
  if (preview.featuredPower case final power?) {
    if (!run.stageClear) {
      run.enemies.clear();
      run.step(.01);
    }
    expect(run.powerOffers, contains(power));
  }
}

void _wait(LiteRun run, double seconds) {
  for (var i = 0; i < (seconds * 120).ceil(); i++) {
    run.step(1 / 120);
  }
}

LiteRun _restore(LiteRun run) => LiteRun.fromJson(
  jsonDecode(jsonEncode(run.toJson())) as Map<String, dynamic>,
);

LiteEnemy _stationaryEnemy(int id, Point<double> at, {double hp = 60}) =>
    LiteEnemy(id, LiteEnemyKind.scostubandito, at, hp)..windup = 4;

void _strikeCampaignEnemy(LiteRun run, LiteEnemy enemy) {
  // Isolate encounter sequencing from combat balance and controller timing.
  run.position = const Point(4, 11);
  enemy.position = const Point(5.5, 11);
  enemy.cooldown = 100;
  if (enemy.burrow case final burrow?) {
    burrow
      ..leap = .05
      ..start = enemy.position
      ..end = enemy.position;
  }
  expect(run.attack(enemy.position), isTrue);
  _wait(run, .45);
  run.position = const Point(5.5, 11);
  run.step(1 / 120);
}

LiteRun _reachFloor(int target, {LiteHero hero = LiteHero.evasore}) {
  final run = _run(weapon: LiteWeapon.spadaScudo, hero: hero)..level = 300;
  run.hp = run.maxHp;
  for (var floor = 0; floor < target; floor++) {
    while (!run.stageClear) {
      _strikeCampaignEnemy(run, run.enemies.first);
    }
    run.position = run.portalPosition;
    expect(run.advance(), isTrue);
  }
  return run;
}

LiteClone _downAlly(LiteRun run) {
  final ally = LiteClone(
    run.position + const Point<double>(0, 1.2),
    10,
    LiteWeapon.spadaScudo,
  );
  run.clones.add(ally);
  run.projectiles.add(
    LiteProjectile(
      position: ally.position,
      direction: const Point(1, 0),
      speed: 8,
      remaining: 2,
      damage: 11,
      fromEnemy: true,
    ),
  );
  run.step(1 / 120);
  return ally;
}

void _killAtRange(LiteRun run, LiteEnemy enemy) {
  enemy
    ..position = const Point(7, 11)
    ..cooldown = 100
    ..hp = 1;
  run.projectiles.add(
    LiteProjectile(
      position: const Point(4, 11),
      direction: const Point(1, 0),
      speed: 23,
      remaining: 8,
      damage: 100,
    ),
  );
  _wait(run, .2);
  expect(enemy.hp, 0);
}

void main() {
  test('royal combo stuns by rank and uses its 1.8 second timer', () {
    final run = _run(hero: LiteHero.reGoblin)..obstacles.clear();
    final host = run.position;
    final enemies = [
      LiteEnemy(
        701,
        LiteEnemyKind.goblinColtello,
        host + const Point<double>(1.6, .3),
        100,
      ),
      LiteEnemy(
        702,
        LiteEnemyKind.costrutto,
        host + const Point<double>(2.2, -.3),
        100,
      ),
      LiteEnemy(
        703,
        LiteEnemyKind.luce,
        host + const Point<double>(2.8, 0),
        100,
      ),
    ];
    run.enemies
      ..clear()
      ..addAll(enemies);
    expect(run.special(host + const Point<double>(3, 0)), isTrue);
    expect(enemies.map((e) => e.stunned), [.9, .6, .3]);
    _wait(run, 1.78);
    expect(run.special(run.position + const Point<double>(3, 0)), isFalse);
    _wait(run, .04);
    expect(run.special(run.position + const Point<double>(3, 0)), isTrue);
  });

  test('the goblin camp plays six waves, saves, then awards the King', () {
    final run = _run(weapon: LiteWeapon.spadaScudo)
      ..stage = 7
      ..stageClear = true
      ..level = 500;
    run.achievements.add('sala-segreta:7');
    run.enemies.clear();
    run.position = LiteRun.secretCache;
    run.hp = run.maxHp;
    run.step(.01);
    for (var wave = 1; wave <= 6; wave++) {
      expect(run.goblinWave, wave);
      expect(run.enemies.length, greaterThanOrEqualTo(wave + 2));
      expect(
        run.enemies.any((e) => e.kind == LiteEnemyKind.goblinFango),
        isTrue,
      );
      run.enemies.clear();
      run.step(.01);
    }
    final checkpoint = _restore(run);
    expect(checkpoint.goblinWave, 7);
    expect(checkpoint.enemies.single.kind, LiteEnemyKind.reGoblin);
    _strikeCampaignEnemy(checkpoint, checkpoint.enemies.single);
    expect(checkpoint.goblinWave, 8);
    expect(checkpoint.stageClear, isTrue);
    expect(
      checkpoint.unlockedHeroesFor(checkpoint.hero),
      contains(LiteHero.reGoblin),
    );
  });

  test(
    'mud covers view for 0.9 seconds and glue only slows movement on contact',
    () {
      final run = _run()..obstacles.clear();
      run.enemies
        ..clear()
        ..add(_stationaryEnemy(714, const Point(22, 11)));
      run.projectiles.add(
        LiteProjectile(
          position: run.position,
          direction: const Point(1, 0),
          speed: 4,
          remaining: 1,
          damage: 4,
          fromEnemy: true,
          kind: LiteProjectileKind.mud,
        ),
      );
      run.step(1 / 120);
      expect(run.night.mud, .9);
      expect(run.hp, 96);
      expect(_restore(run).night.mud, .9);
      _wait(run, .91);
      expect(run.night.mud, 0);
      final start = run.position;
      run.groundShots.add(LiteGroundShot(start, true, true, 6));
      expect(run.terrainSpeedAt(start, enemy: false), lessThan(1));
      run.step(.2, move: const Point(1, 0));
      expect(run.position.x - start.x, lessThan(.7));
      expect(run.hp, 96);
      expect(
        run.terrainSpeedAt(start + const Point<double>(0, 2), enemy: false),
        1,
      );
    },
  );

  test(
    'royal call revives allies within 10 m and rare glue follows discovery',
    () {
      final run = _run(hero: LiteHero.reGoblin);
      final near = LiteClone(
        run.position + const Point<double>(0, 2),
        0,
        LiteWeapon.guanti,
        maxHp: 44,
      );
      final far = LiteClone(
        run.position + const Point<double>(15, 0),
        0,
        LiteWeapon.guanti,
        maxHp: 44,
      );
      run.clones.addAll([near, far]);
      expect(run.royalCall(), isTrue);
      expect(near.hp, 22);
      expect(far.hp, 0);
      expect(run.royalCall(), isFalse);
      run.achievements.add(LiteCompanion.goblinColla.unlockKey);
      expect(run.useOpen(run.aim + run.position), isTrue);
      expect(
        run.clones.where((c) => c.companion == LiteCompanion.goblinColla),
        hasLength(1),
      );
    },
  );

  test('slime credits combine across runs without duplicating reloads', () {
    final start = const OculumLiteProgress().record(
      1,
      {},
      slimeCounters: {'a': 5},
    );
    final reload = start.record(1, {}, slimeCounters: {'a': 5});
    expect(reload.slimeKills, 5);
    expect(reload.canPlay(LiteHero.slimeBlu), isFalse);
    final result = reload.record(1, {}, slimeCounters: {'b': 5});
    expect(
      OculumLiteProgress.decode(result.encode()).canPlay(LiteHero.slimeBlu),
      isTrue,
    );
  });

  test(
    'Slime Blu maintains the link with repeated click and refills Oculum',
    () {
      final run = _run(hero: LiteHero.slimeBlu)..obstacles.clear();
      final target = _stationaryEnemy(
        735,
        run.position + const Point<double>(2.2, 0),
        hp: 150,
      );
      run.enemies
        ..clear()
        ..add(target);
      run.oculum = 0;
      run.hp = 50;
      for (var i = 0; i < 4; i++) {
        expect(run.special(target.position), isTrue);
        _wait(run, .30);
      }
      expect(target.hp, lessThan(130));
      expect(run.oculum, greaterThan(0));
      expect(run.hp, greaterThan(50));
      expect(run.slimeDash(target.position), isTrue);
      expect(run.night.absorb, 0);
      expect(run.night.veil, .55);
    },
  );

  test(
    'Vampire adds impact damage against both solid and breakable scenery',
    () {
      for (final breakable in [false, true]) {
        final run = _run(hero: LiteHero.vampiro)..obstacles.clear();
        final target = _stationaryEnemy(
          745,
          run.position + const Point<double>(1.7, 0),
          hp: 100,
        );
        run.enemies
          ..clear()
          ..add(target);
        final cover = LiteObstacle(7, 10, 1, 2, breakable: breakable, hp: 99);
        run.obstacles.add(cover);
        expect(run.attack(target.position), isTrue);
        _wait(run, .35);
        expect(target.hp, 100 - run.weaponDamage - 5);
        expect(run.obstacles.contains(cover), !breakable);
      }
    },
  );

  test('Doppelganger copies an elite, restores form from save and survives its defeat', () {
    final run = _run(hero: LiteHero.doppelganger)..obstacles.clear();
    final at = run.position;
    final boss = LiteEnemy(
      901,
      LiteEnemyKind.luce,
      at + const Point<double>(3, 0),
      90,
    );
    run.enemies
      ..clear()
      ..add(boss);
    expect(run.special(boss.position), isFalse);
    final monster = LiteEnemy(
      902,
      LiteEnemyKind.forestDemon,
      at + const Point<double>(4, 0),
      110,
    )..hp = 52;
    run.enemies.add(monster);
    run.hp = 80;
    expect(run.special(monster.position), isTrue);
    expect(run.hp, 52);
    expect(run.maxHp, 110);
    final restored = _restore(run);
    expect(restored.mimic?.kind, LiteEnemyKind.forestDemon);
    restored.projectiles.add(
      LiteProjectile(
        position: at,
        direction: const Point(1, 0),
        speed: 5,
        remaining: 1,
        damage: 150,
        fromEnemy: true,
      ),
    );
    restored.step(1 / 120);
    expect(restored.mimic, isNull);
    expect(restored.hp, 52);
    expect(restored.dead, isFalse);
  });

  test('fireballs reflect from cover and fissures stop at solid cover', () {
    final pyrel = _run(hero: LiteHero.pyrel);
    pyrel.obstacles
      ..clear()
      ..add(LiteObstacle(6, 9, .55, 4));
    pyrel.enemies
      ..clear()
      ..add(_stationaryEnemy(901, const Point(13, 11)));
    expect(pyrel.special(const Point(8, 11)), isTrue);
    _wait(pyrel, .2);
    expect(pyrel.projectiles.single.direction.x, lessThan(0));
    expect(pyrel.projectiles.single.bounces, 2);
    final lithra = _run(hero: LiteHero.lithra);
    lithra.obstacles
      ..clear()
      ..add(LiteObstacle(7, 9, .55, 4));
    final before = _stationaryEnemy(902, const Point(5.8, 11));
    final behind = _stationaryEnemy(903, const Point(8, 11));
    lithra.enemies
      ..clear()
      ..addAll([before, behind]);
    expect(lithra.special(behind.position), isTrue);
    expect(before.hp, lessThan(before.maxHp));
    expect(behind.hp, behind.maxHp);
    final snapshot = LiteRun.fromJson(lithra.toJson(includeEffects: true));
    expect(snapshot.combatImpacts.first.end?.x, lessThan(7));
  });

  test('a seeded Orea secret room awards its pet and loot only once', () {
    final seed = Iterable<int>.generate(100).firstWhere(
      (seed) => (LiteRun(
        seed: seed,
        hero: LiteHero.evasore,
        weapon: LiteWeapon.spadaScudo,
      )..stage = 2).hasSecretRoom,
    );
    final run =
        LiteRun(
            seed: seed,
            hero: LiteHero.evasore,
            weapon: LiteWeapon.spadaScudo,
          )
          ..stage = 1
          ..stageClear = true
          ..level = 30;
    run.position = run.portalPosition;
    expect(run.advance(LiteBiome.orea), isTrue);
    final gate = run.obstacles.singleWhere((wall) => wall.secretGate);
    run.position = gate.center + const Point<double>(0, 1.1);
    expect(run.attack(gate.center), isTrue);
    expect(run.obstacles.any((wall) => wall.secretGate), isFalse);
    expect(run.discoveredPets, {LiteCompanion.orbietto});
    final restored = _restore(run);
    expect(
      restored.clones.where((pet) => pet.companion == LiteCompanion.orbietto),
      hasLength(1),
    );
    expect(
      restored.loot.where((item) => item.kind == LiteLootKind.scroll),
      hasLength(1),
    );
    expect(restored.routeBiomes.toSet(), hasLength(3));
    expect(restored.routeBiomes, run.routeBiomes);
  });

  test(
    'a guest Bandit throws a bomb from their position and cannot spam it',
    () {
      final run = LiteRun(
        seed: 39,
        hero: LiteHero.evasore,
        weapon: LiteWeapon.spadaScudo,
        playerCount: 2,
      );
      run.addCoopFighter(
        'guest',
        'Vedetta',
        LiteHero.scostubandito,
        LiteWeapon.fucileScostubandito,
      );
      final guest = run.coopFighter('guest')!;
      final at = guest.position + const Point<double>(4, 0);
      final target = _stationaryEnemy(902, at, hp: 100);
      run.obstacles.clear();
      run.enemies
        ..clear()
        ..add(target);
      for (var i = 0; i < 2; i++) {
        run.setCoopControls(
          'guest',
          const Point(0, 0),
          at,
          attack: false,
          bomb: true,
        );
      }
      expect(
        run.projectiles.where((shot) => shot.kind == LiteProjectileKind.bomb),
        hasLength(1),
      );
      expect(guest.oculum, 8);
      _wait(run, .50);
      expect(target.hp, lessThan(target.maxHp));
      expect(
        run.combatImpacts.any(
          (item) => item.target == LiteImpactTarget.explosion,
        ),
        isTrue,
      );
    },
  );

  test(
    'the living lookout beyond the adult Forest Demon unlocks Scostubandito',
    () {
      for (final survives in [false, true]) {
        final run = _reachFloor(6)
          ..clones.clear()
          ..enemies.clear();
        run.step(.01);
        final forestDemon = run.enemies.single;
        expect(forestDemon.kind, LiteEnemyKind.forestDemon);
        _killAtRange(run, forestDemon);
        const lookout = LiteCompanion.vedetta;
        run.clones.add(
          LiteClone(
            run.position,
            survives ? lookout.life : 0,
            lookout.weapon,
            id: 104,
            maxHp: lookout.life,
            companion: lookout,
          )..downRemaining = survives ? 0 : 5,
        );
        expect(run.achievements, isNot(contains(LiteRun.unlockScostubandito)));
        run.position = run.portalPosition;
        expect(run.advance(), isTrue);
        expect(
          _restore(run).achievements.contains(LiteRun.unlockScostubandito),
          survives,
        );
      }
    },
  );

  test(
    'Scostubandito Open fires a cannon and survives a save as a single summon',
    () {
      var run = _run(hero: LiteHero.scostubandito)
        ..enemies.clear()
        ..obstacles.clear();
      run.enemies.add(_stationaryEnemy(110, const Point(9, 11), hp: 280));
      expect(run.useOpen(const Point(9, 11)), isTrue);
      expect(run.oculum, run.maxOculum - LiteRun.granSummonCost);
      expect(run.useOpen(const Point(9, 11)), isFalse);
      run = _restore(run);
      expect(run.clones.single.companion, LiteCompanion.granScostumato);
      expect(run.clones.single.expiresAfter, LiteRun.granSummonDuration);
      _wait(run, .47);
      expect(
        run.projectiles.any(
          (shot) => shot.kind == LiteProjectileKind.cannon && !shot.fromEnemy,
        ),
        isTrue,
      );
      _wait(run, LiteRun.granSummonDuration);
      expect(
        run.clones.where(
          (ally) => ally.companion == LiteCompanion.granScostumato,
        ),
        isEmpty,
      );
    },
  );

  test(
    'every hero has an Open with its own effect and recoverable resource state',
    () {
      for (final hero in LiteHero.values) {
        final run = _run(hero: hero)..obstacles.clear();
        final target = _stationaryEnemy(301, const Point(6.5, 11));
        run.enemies
          ..clear()
          ..add(target);
        if (hero == LiteHero.doppelganger) {
          expect(run.useOpen(target.position), isFalse);
          expect(run.special(target.position), isTrue);
        }
        expect(run.useOpen(target.position), isTrue, reason: hero.name);
        expect(run.oculum, run.maxOculum - LiteRun.granSummonCost);
        expect(run.useOpen(target.position), isFalse);
        expect(_restore(run).openCooldown, LiteRun.openRecovery);
        switch (hero) {
          case LiteHero.evasore:
            expect(run.intangible, isTrue);
            expect(run.burstRemaining, .48);
          case LiteHero.duplicatore:
            expect(run.clones, hasLength(2));
            expect(run.clones.every((ally) => ally.expiresAfter == 12), isTrue);
          case LiteHero.ashley:
            expect(run.springPunchActive, isTrue);
            expect(target.hp, target.maxHp - 42);
          case LiteHero.scostubandito:
            expect(run.ownedWeapons, [LiteWeapon.fucileScostubandito]);
            expect(run.clones.single.companion, LiteCompanion.granScostumato);
          case LiteHero.granScostumato:
            expect(run.clones.map((ally) => ally.companion), [
              LiteCompanion.vedetta,
              LiteCompanion.vedetta,
            ]);
            expect(run.clones.every((ally) => ally.expiresAfter == 12), isTrue);
          case LiteHero.dronePostea:
            expect(target.hp, lessThan(target.maxHp));
            expect(target.shockRemaining, greaterThan(0));
          case LiteHero.sentinella:
            expect(run.shield, 42);
            expect(target.position.x, greaterThan(6.5));
          case LiteHero.babyForestDemon:
            expect(target.hp, lessThan(target.maxHp));
          case LiteHero.pyrel:
            expect(
              run.projectiles.map((shot) => shot.kind),
              everyElement(LiteProjectileKind.fireball),
            );
            expect(run.projectiles, hasLength(3));
          case LiteHero.lithra:
            expect(
              run.combatImpacts.where((impact) => impact.end != null),
              hasLength(3),
            );
          case LiteHero.luce:
            expect(run.shield, greaterThanOrEqualTo(21));
            expect(target.hp, lessThan(target.maxHp));
          case LiteHero.ombra:
            expect(run.intangible, isTrue);
            expect(run.position.x, greaterThan(6.5));
          case LiteHero.veyrth:
            expect(run.projectiles, hasLength(7));
          case LiteHero.doppelganger:
            expect(run.mimic?.kind, target.kind);
            expect(run.maxHp, target.maxHp);
          case LiteHero.polloMeccanico:
            expect(run.projectiles, hasLength(3));
            expect(
              run.projectiles.every(
                (shot) => shot.kind == LiteProjectileKind.posteaEgg,
              ),
              isTrue,
            );
          case LiteHero.pollo:
            expect(
              run.projectiles
                  .where((shot) => shot.kind == LiteProjectileKind.egg)
                  .length,
              3,
            );
          case LiteHero.raganella ||
              LiteHero.pipistrello ||
              LiteHero.guardiaSolare ||
              LiteHero.demoneMinore ||
              LiteHero.demoneMaggiore:
            expect(run.intangible, isTrue);
          case LiteHero.eliteSolare:
            expect(
              run.projectiles.any(
                (shot) => shot.kind == LiteProjectileKind.solarRay,
              ),
              isTrue,
            );
          case LiteHero.guardianoSolare:
            expect(run.night.solarMace, greaterThan(0));
          case LiteHero.aberrazioneSolare:
            expect(run.night.solarMantle, greaterThan(0));
          case LiteHero.demoneIntermedio:
            expect(run.openCooldown, greaterThan(0));
          case LiteHero.diavolo:
            expect(
              run.projectiles
                  .where((shot) => shot.kind == LiteProjectileKind.fireball)
                  .length,
              5,
            );
          case LiteHero.cavaliereLunare:
            expect(run.clones.single.companion, LiteCompanion.guardianoLunare);
            expect(run.maxBlockResistance, 300);
          case LiteHero.slimeBlu:
            expect(run.night.absorb, greaterThan(0));
            expect(run.shield, greaterThanOrEqualTo(16));
          case LiteHero.vampiro:
            expect(run.maxHp, 200);
            expect(run.night.sanguine, greaterThan(5));
          case LiteHero.reGoblin:
            expect(run.clones.map((clone) => clone.companion), [
              LiteCompanion.goblinColtello,
              LiteCompanion.goblinColtello,
              LiteCompanion.goblinFango,
            ]);
          case LiteHero.curatorePeste:
            expect(run.plagueForm, isTrue);
            expect(run.maxHp, 200);
            expect(_restore(run).maxHp, 200);
        }
      }
    },
  );

  test(
    'a guest Scostubandito starts with the rifle and uses Open independently',
    () {
      final run = LiteRun(
        seed: 310,
        hero: LiteHero.evasore,
        weapon: LiteWeapon.arco,
        playerCount: 2,
      );
      expect(
        run.addCoopFighter(
          'guest',
          'Vedetta',
          LiteHero.scostubandito,
          LiteWeapon.arco,
        ),
        isTrue,
      );
      final guest = run.coopFighter('guest')!;
      expect(guest.weapon, LiteWeapon.fucileScostubandito);
      const at = Point<double>(10, 11);
      expect(
        run.setCoopControls(
          'guest',
          const Point(0, 0),
          at,
          attack: false,
          dodge: true,
        ),
        isTrue,
      );
      expect(run.clones, isEmpty);
      expect(
        run.setCoopControls(
          'guest',
          const Point(0, 0),
          at,
          attack: false,
          open: true,
          rifleSkill: true,
        ),
        isTrue,
      );
      expect(run.clones.single.ownerId, guest.id);
      expect(guest.oculum, 1);
      expect(run.oculum, run.maxOculum);
      final copy = _restore(run).coopFighter('guest')!;
      expect(copy.banditRounds, 4);
      expect(copy.openCooldown, LiteRun.openRecovery);
    },
  );

  test(
    'the risky route preview matches the arena and pays once after a reload',
    () {
      for (final trial in LiteArenaTrial.values) {
        late LiteRun run;
        late LiteFloorPreview preview;
        for (var seed = 0; seed < 400; seed++) {
          final candidate =
              LiteRun(
                  seed: seed,
                  hero: LiteHero.evasore,
                  weapon: LiteWeapon.arco,
                )
                ..stage = 1
                ..stageClear = true;
          final routes = LiteBiome.values.map(candidate.previewNextFloor);
          final found = routes
              .where((route) => route?.trial == trial)
              .firstOrNull;
          if (found == null) continue;
          run = candidate;
          preview = found;
          break;
        }
        run.position = run.portalPosition;
        expect(run.advance(preview.biome), isTrue);
        expect(run.arenaTrial, trial);
        expect(run.enemies, hasLength(preview.openingEnemies));
        if (trial == LiteArenaTrial.muraglia) {
          final kind = run.enemies.first.kind;
          expect(
            run.enemies.first.maxHp,
            (kind.health * 1.2 * 1.25).roundToDouble(),
          );
        }
        final resumed = _restore(run);
        expect(resumed.arenaTrial, trial);
        final beforeReward = resumed.obser;
        resumed.enemies.clear();
        resumed.step(.01);
        expect(resumed.obser - beforeReward, 20 + trial.obser);
        expect(resumed.powerOffers.first, trial.power);
        final completed = _restore(resumed)..step(.1);
        expect(completed.obser, resumed.obser);
        if (trial == LiteArenaTrial.caccia) {
          final lateRun = LiteRun.fromJson({
            ...run.toJson(),
            'time': run.time + 41,
          });
          expect(lateRun.trialSecondsLeft, 0);
          final beforeLateReward = lateRun.obser;
          lateRun.enemies.clear();
          lateRun.step(.01);
          expect(lateRun.stageClear, isTrue);
          expect(lateRun.obser - beforeLateReward, 20);
        }
      }
    },
  );

  test('Scostubandito uses the rifle, guards, and preserves infused rounds in saves', () {
    final run = _run(hero: LiteHero.scostubandito)..obstacles.clear();
    final target = _stationaryEnemy(510, const Point(5.5, 11));
    run.enemies
      ..clear()
      ..add(target);
    expect(run.banditRifleSkill(), isTrue);
    expect(run.banditRifleSkill(), isFalse);
    expect(run.attack(target.position), isTrue);
    expect(run.projectiles, isEmpty);
    expect(target.hp, lessThan(target.maxHp));
    expect(run.banditRounds, 4);
    expect(run.special(target.position), isTrue);
    expect(run.special(target.position), isFalse);

    void hitHost(double damage) {
      run.projectiles.add(
        LiteProjectile(
          position: run.position,
          direction: const Point(1, 0),
          speed: 17,
          remaining: 3,
          damage: damage,
          fromEnemy: true,
        ),
      );
      run.step(1 / 120);
    }

    final beforeGuard = target.hp;
    hitHost(3);
    expect(run.shield, 5);
    expect(target.hp, beforeGuard - 6);
    expect(target.position.x, greaterThan(5.5));
    _wait(run, 1);
    hitHost(6);
    expect(run.shield, 16);
    expect(run.hp, run.maxHp - 1);
    target.position = const Point(8, 11);
    expect(run.attack(target.position), isTrue);
    expect(run.projectiles, hasLength(1));
    expect(run.banditRounds, 3);
    final resumed = _restore(run);
    expect(resumed.banditRounds, 3);
    expect(resumed.weapon, LiteWeapon.fucileScostubandito);

    final critical = _restore(run)..projectiles.clear();
    critical.projectiles.add(
      LiteProjectile(
        position: critical.enemies.single.position,
        direction: const Point(1, 0),
        speed: 14,
        remaining: 2,
        damage: 13,
        kind: LiteProjectileKind.rifleCritical,
      ),
    );
    critical.step(1 / 120);
    expect(critical.banditDodgeReady, isTrue);
    expect(critical.dash(const Point(1, 11)), isTrue);
    expect(critical.banditDodgeReady, isFalse);
    expect(critical.intangible, isTrue);
  });

  test('staff lightning hits nearby enemies and slows their movement', () {
    LiteRun build(LiteWeapon weapon) {
      final run = _run(weapon: weapon)..obstacles.clear();
      run.enemies
        ..clear()
        ..addAll([
          LiteEnemy(510, LiteEnemyKind.scostubandito, const Point(6.2, 11), 40)
            ..cooldown = 80,
          _stationaryEnemy(511, const Point(12, 14)),
        ]);
      return run;
    }

    final arc = build(LiteWeapon.scettro);
    final control = build(LiteWeapon.arco);
    _wait(arc, .34);
    _wait(control, .34);
    expect(arc.enemies[0].hp, 36);
    expect(arc.enemies[0].position.x, lessThan(control.enemies[0].position.x));
    expect(arc.enemies[0].shockRemaining, greaterThan(0));
    expect(arc.enemies[1].hp, 60);
    final restored = _restore(arc);
    expect(restored.enemies[0].shockRemaining, arc.enemies[0].shockRemaining);
    _wait(restored, .28);
    expect(restored.enemies[0].shockRemaining, 0);
    expect(restored.enemies[0].hp, 36);
  });

  test('enemies aim at living duplicates and companions and can down them', () {
    for (final companion in [null, LiteCompanion.vedetta]) {
      final run = _run()
        ..obstacles.clear()
        ..enemies.clear();
      final ally = LiteClone(
        const Point(10, 11),
        4,
        LiteWeapon.arco,
        companion: companion,
        id: 100,
      )..cooldown = 80;
      final attacker = LiteEnemy(
        101,
        LiteEnemyKind.scostubandito,
        const Point(14, 11),
        30,
      )..cooldown = 0;
      run.clones.add(ally);
      run.enemies.add(attacker);
      run.step(.02);
      expect(attacker.attackTarget, ally.position);
      expect(_restore(run).enemies.single.attackTarget, ally.position);
      final life = run.hp;
      _wait(run, 1);
      expect(ally.down, isTrue);
      expect(run.hp, life);
      final resumed = _restore(run);
      expect(resumed.clones.single.downRemaining, ally.downRemaining);
      expect(resumed.clones.single.companion, companion);
      expect(resumed.enemies.single.attackTarget, resumed.position);
      resumed.enemies.single.cooldown = 0;
      resumed.step(.02);
      expect(resumed.enemies.single.attackTarget, resumed.position);
    }
  });

  test(
    'the arena accelerates for both player and enemies every three floors',
    () {
      for (final (floor, speed) in [
        (0, 1.0),
        (2, 1.0),
        (3, 1.1),
        (5, 1.1),
        (6, 1.2),
        (9, 1.3),
        (12, 1.4),
        (13, 1.4),
      ]) {
        final run = _run()..stage = floor;
        final exact = _restore(run);
        const move = Point<double>(1, 0);
        run.advanceFrame(.1, move: move);
        exact.step(.1 * speed, move: move);
        expect(run.arenaSpeed, closeTo(speed, 1e-9));
        expect(run.time, closeTo(.1 * speed, 1e-9));
        expect(run.position, exact.position);
        expect(
          run.enemies.map((enemy) => enemy.position),
          exact.enemies.map((enemy) => enemy.position),
        );
        expect(_restore(run).arenaSpeed, run.arenaSpeed);
      }
    },
  );
  test('mirror bosses drop their weapons, which join the saved arsenal', () {
    for (final (floor, kind, weapon) in [
      (3, LiteEnemyKind.luce, LiteWeapon.piccaOssidiana),
      (9, LiteEnemyKind.ombra, LiteWeapon.balestraRunica),
    ]) {
      final run = _reachFloor(floor)..enemies.clear();
      run.step(.01);
      final boss = run.enemies.single;
      expect(boss.kind, kind);
      _killAtRange(run, boss);
      expect(run.loot.where((item) => item.weapon == weapon), hasLength(1));
      run.position = boss.position;
      run.step(.01);
      expect(_restore(run).ownedWeapons, contains(weapon));
      expect(LiteWeapon.starters, isNot(contains(weapon)));
    }
  });

  test('obsidian pike strikes down its axis and crossbow slows a target', () {
    final pike = _run(weapon: LiteWeapon.piccaOssidiana)..enemies.clear();
    final along = _stationaryEnemy(950, const Point(8, 11));
    final beside = _stationaryEnemy(951, const Point(6.5, 13.5));
    pike.enemies.addAll([along, beside]);
    expect(pike.attack(along.position), isTrue);
    expect(along.hp, 60);
    _wait(pike, .24);
    expect(along.hp, lessThan(60));
    expect(beside.hp, 60);

    final crossbow = _run(weapon: LiteWeapon.balestraRunica)..enemies.clear();
    final target = _stationaryEnemy(952, const Point(10, 11));
    crossbow.enemies.add(target);
    expect(crossbow.attack(target.position), isTrue);
    _wait(crossbow, .32);
    expect(crossbow.projectiles.single.kind, LiteProjectileKind.frostBolt);
    _wait(crossbow, .23);
    expect(target.hp, lessThan(60));
    expect(target.hitFlash, greaterThan(.4));
  });

  test('recruited NPCs fight, travel, can be rescued and serialize once', () {
    for (final (biome, type) in [
      (LiteBiome.campo, LiteCompanion.vedetta),
      (LiteBiome.postea, LiteCompanion.drone),
    ]) {
      var run = _run(biome: biome)..enemies.clear();
      run.step(.01);
      final elite = run.enemies.single;
      expect(elite.kind, type.unlocksAfter);
      _killAtRange(run, elite);
      expect(run.clones.single.companion, type);
      expect(run.achievements, contains(type.unlockKey));
      run = _restore(run);
      run.position = run.portalPosition;
      expect(run.advance(), isTrue);
      final ally = run.clones.single;
      expect(ally.companion, type);
      final target = _stationaryEnemy(953, const Point(8, 11));
      run.enemies
        ..clear()
        ..add(target);
      _wait(run, .85);
      expect(target.hp, lessThan(60));
      ally
        ..hp = 0
        ..downRemaining = LiteRun.allyRescueWindow;
      run.position = ally.position;
      expect(run.beginRescue(), isTrue);
      _wait(run, LiteRun.rescueDuration + .05);
      expect(ally.hp, greaterThan(0));
      expect(_restore(run).clones.single.companion, type);
    }
  });
  test('stride follows displacement and survives a cooperative frame', () {
    final run = _run();
    final enemy = run.enemies.first;
    final original = enemy.position;
    final initial = run.position;
    run.step(.20, move: const Point(1, 0));
    expect(
      run.stride.distance,
      closeTo(run.position.distanceTo(initial), .0001),
    );
    expect(enemy.position, isNot(original));
    expect(enemy.stride.strength, greaterThan(.3));
    final guestFrame = LiteRun.fromJson(run.toJson(includeEffects: true));
    expect(guestFrame.stride.distance, run.stride.distance);
    expect(guestFrame.enemies.first.stride.distance, enemy.stride.distance);
    expect(_restore(run).stride.distance, 0);

    run.position = const Point(.4, 8);
    final beforeWall = run.stride.distance;
    for (var i = 0; i < 4; i++) {
      run.step(.20, move: const Point(-1, 0));
    }
    expect(run.stride.distance, beforeWall);
    expect(run.stride.strength, lessThan(.01));

    enemy.windup = .02;
    enemy.attackTarget = run.position;
    run.step(.04);
    expect(enemy.strikePose, greaterThan(.1));
    final attacking = LiteRun.fromJson(run.toJson(includeEffects: true));
    expect(attacking.enemies.first.strikePose, enemy.strikePose);
  });

  test(
    'floor three increases generated life and incoming damage progressively',
    () {
      final run = _run()
        ..stage = 2
        ..stageClear = true;
      run.position = run.portalPosition;
      expect(run.advance(LiteBiome.campo), isTrue);
      expect(run.stage, 3);
      expect(
        run.enemies.first.maxHp,
        (LiteEnemyKind.scostubandito.health * 1.3 * 1.15).round(),
      );
      run.projectiles.add(
        LiteProjectile(
          position: run.position,
          direction: const Point(1, 0),
          speed: 15,
          remaining: 6,
          damage: 10,
          fromEnemy: true,
        ),
      );
      run.step(1 / 120);
      expect(run.hp, closeTo(88.8, .0001));
      run.enemies.clear();
      run.step(1 / 120);
      final light = run.enemies.single;
      expect(light.kind, LiteEnemyKind.luce);
      expect(
        light.maxHp,
        (LiteEnemyKind.luce.health * 1.3 * 1.15 * 1.25).round(),
      );
      expect(LiteRun.challengeBonus(0, LiteEnemyKind.granScostumato), (
        life: 0,
        damage: 0,
      ));
      expect(LiteRun.challengeBonus(6, LiteEnemyKind.forestDemon), (
        life: 20,
        damage: 10,
      ));
      expect(LiteRun.challengeBonus(13, LiteEnemyKind.veyrth), (
        life: 30,
        damage: 18,
      ));
      expect(LiteRun.challengeBonus(13, LiteEnemyKind.minionVeyrth), (
        life: 0,
        damage: 0,
      ));
      expect(LiteRun.enemyLifeBonusAt(2), 0);
      expect(LiteRun.enemyDamageBonusAt(2), 0);
      expect(LiteRun.enemyLifeBonusAt(13), 35);
      expect(LiteRun.enemyDamageBonusAt(13), 22);
    },
  );

  test('route previews match generated floors without advancing the RNG', () {
    for (final destination in LiteBiome.values) {
      for (final stage in [0, 2, 5, 8, 11, 12, 14, 17, 20, 23]) {
        _expectRouteMatchesFloor(before: stage, destination: destination);
      }
      for (final stage in [2, 14, 17, 20, 23]) {
        _expectRouteMatchesFloor(
          before: stage,
          destination: destination,
          coop: true,
        );
      }
    }
  });

  test(
    'Master and guest Duplicators use independent lives and clone limits',
    () {
      final run = LiteRun(
        seed: 241,
        hero: LiteHero.duplicatore,
        weapon: LiteWeapon.spadaScudo,
        playerCount: 2,
      );
      expect(
        run.addCoopFighter(
          'ospite',
          'Ospite',
          LiteHero.duplicatore,
          LiteWeapon.arco,
        ),
        isTrue,
      );
      final guest = run.coopFighter('ospite')!;
      final hostLife = run.hp;
      final guestLife = guest.hp;
      final target = const Point<double>(9, 11);
      expect(run.special(target), isTrue);
      expect(run.special(target), isTrue);
      expect(run.special(target), isFalse);
      for (var i = 0; i < 3; i++) {
        expect(
          run.setCoopControls(
            'ospite',
            const Point(0, 0),
            target,
            attack: false,
            dodge: true,
            reload: false,
          ),
          isTrue,
        );
      }
      expect(run.hp, hostLife - 2 * (run.maxHp * LiteRun.cloneFraction).ceil());
      expect(
        guest.hp,
        guestLife - 2 * (guest.maxHp * LiteRun.cloneFraction).ceil(),
      );
      expect(
        run.clones
            .where((clone) => clone.ownerId == guest.id)
            .map((clone) => clone.weapon),
        [LiteWeapon.arco, LiteWeapon.arco],
      );
      expect(
        run.clones
            .where((clone) => clone.ownerId == 0)
            .map((clone) => clone.weapon),
        [LiteWeapon.spadaScudo, LiteWeapon.spadaScudo],
      );
      expect(
        _restore(run).clones.where((clone) => clone.ownerId == guest.id).length,
        2,
      );
    },
  );
  test('Ashley spring punch uses its own range, cooldown and save state', () {
    final run = _run(hero: LiteHero.ashley);
    run.position = const Point(4, 11);
    final close = _stationaryEnemy(81, const Point(8, 11));
    final far = _stationaryEnemy(82, const Point(10, 11));
    run.enemies
      ..clear()
      ..addAll([close, far]);
    expect(run.special(close.position), isTrue);
    expect(close.hp, 60 - (14 + 2 * run.level));
    expect(far.hp, 60);
    expect(run.arrows, LiteRun.bowCapacity);
    final restored = _restore(run);
    expect(restored.springPunchActive, isTrue);
    expect(restored.special(close.position), isFalse);
    _wait(restored, .3);
    expect(restored.springPunchActive, isFalse);
    expect(restored.special(close.position), isFalse);
    _wait(restored, 3.12);
    expect(restored.special(close.position), isTrue);
  });
  test('Ristoro is available every third floor before the finale', () {
    final run = _run();
    expect(run.hasRest, isTrue);
    run.position = run.restPosition;
    run.hp = 18;
    run.oculum = 1;
    expect(run.useRest(), isFalse);
    run.stageClear = true;
    expect(run.useRest(), isTrue);
    expect(run.hp, 68);
    expect(run.oculum, 3.5);
    expect(run.useRest(), isFalse);
    expect(_restore(run).restUsed, isTrue);
    run.loot..add(LiteLoot(run.position, LiteLootKind.greenStone, 1));
    run.enemies.clear();
    run.step(1 / 120);
    expect(run.hp, 88);
    run.loot.add(LiteLoot(run.position, LiteLootKind.refinedGreenGem, 1));
    run.step(1 / 120);
    expect(run.hp, run.maxHp);
    expect(run.oculum, run.maxOculum);
    for (var floor = 0; floor <= LiteRun.finalStage; floor++) {
      run.stage = floor;
      expect(run.hasRest, [0, 3, 6, 9, 12, 15, 18, 21].contains(floor));
    }
  });

  test(
    'six players scale monsters by difficulty and minions retain one HP',
    () {
      for (final (difficulty, step) in [
        (LiteDifficulty.moltoFacile, .01),
        (LiteDifficulty.facile, .03),
        (LiteDifficulty.medio, .06),
        (LiteDifficulty.difficile, .09),
        (LiteDifficulty.oculum, .12),
      ]) {
        final run = LiteRun(
          seed: 241,
          hero: LiteHero.evasore,
          difficulty: difficulty,
          weapon: LiteWeapon.arco,
          playerCount: 6,
        );
        expect(run.monsterLifeMultiplier, closeTo(1 + 5 * step, 1e-10));
        expect(run.ownedWeapons, [LiteWeapon.arco]);
        final foe = run.enemies.first;
        expect(
          foe.maxHp,
          (foe.kind.health * difficulty.enemyStrength * (1 + 5 * step)).round(),
        );
        for (var index = 0; index < 5; index++) {
          expect(
            run.addCoopFighter(
              'player-$index',
              'Giocatore $index',
              LiteHero.duplicatore,
              LiteWeapon.guanti,
            ),
            isTrue,
          );
        }
        expect(
          run.addCoopFighter(
            'terzo',
            'Fuori capienza',
            LiteHero.evasore,
            LiteWeapon.arco,
          ),
          isFalse,
        );
        final copy = _restore(run);
        expect(copy.playerCount, 6);
        expect(copy.coopFighters, hasLength(5));
        expect(copy.clones, isEmpty);
      }
    },
  );

  LiteProjectile shot(
    Point<double> position,
    Point<double> direction, {
    bool enemy = true,
    bool own = true,
  }) => LiteProjectile(
    position: position,
    direction: direction,
    speed: 25,
    remaining: 6,
    damage: 10,
    fromEnemy: enemy,
    ownerCanHeal: own,
  );

  test(
    'block absorbs before shield and life and gains 10 per healing pickup',
    () {
      final run = _run()..shield = 4;
      run.setBlocking(true);
      expect(run.blockResistance, 100);
      expect(run.attack(const Point(9, 11)), isFalse);
      void hit(double damage) {
        run.projectiles.add(
          LiteProjectile(
            position: run.position,
            direction: const Point(1, 0),
            speed: 20,
            remaining: 3,
            damage: damage,
            fromEnemy: true,
          ),
        );
        run.step(1 / 120);
      }

      hit(95);
      expect(run.blockResistance, 5);
      expect(run.shield, 4);
      expect(run.hp, 100);
      expect(run.invulnerable, isFalse);
      hit(15);
      expect(run.blockResistance, 0);
      expect(run.shield, 0);
      expect(run.hp, 94);
      run.loot.add(LiteLoot(run.position, LiteLootKind.greenStone, 1));
      run.step(.01);
      expect(run.hp, 100);
      expect(run.blockResistance, 10);
      run.step(.01);
      expect(run.blockResistance, 10);
      final resumed = _restore(run);
      expect(resumed.blockResistance, 10);
      expect(resumed.blocking, isFalse);
      resumed.ownedWeapons.add(LiteWeapon.spadaScudo);
      expect(resumed.switchWeapon(), isTrue);
      expect(resumed.maxBlockResistance, 160);
      expect(resumed.blockResistance, 70);
      expect(resumed.switchWeapon(), isTrue);
      expect(resumed.blockResistance, 10);
    },
  );

  test('co-op guard and curative loot belong to the guest who used them', () {
    final run = LiteRun(
      seed: 61,
      hero: LiteHero.evasore,
      weapon: LiteWeapon.arco,
      playerCount: 2,
    );
    run.addCoopFighter(
      'guest',
      'Ospite',
      LiteHero.ashley,
      LiteWeapon.spadaScudo,
    );
    final guest = run.coopFighter('guest')!;
    expect(guest.blockResistance, 160);
    run.setCoopControls(
      'guest',
      const Point(0, 0),
      const Point(9, 11),
      attack: false,
      block: true,
    );
    run.projectiles.add(shot(guest.position, const Point(1, 0)));
    run.step(1 / 120);
    expect(guest.shield, 6);
    expect(guest.blockResistance, 150);
    run.setCoopControls(
      'guest',
      const Point(0, 0),
      const Point(9, 11),
      attack: false,
    );
    run.projectiles.add(shot(guest.position, const Point(1, 0)));
    run.step(1 / 120);
    expect(guest.hp, 96);
    expect(guest.blockResistance, 150);
    run.loot.add(LiteLoot(guest.position, LiteLootKind.refinedGreenGem, 1));
    run.step(1 / 120);
    expect(guest.hp, 100);
    expect(guest.blockResistance, 160);
    expect(run.blockResistance, 100);
    expect(run.loot, isEmpty);
  });

  test(
    'healing still refills the shared block after unequipping a worn shield',
    () {
      final run = _run(weapon: LiteWeapon.spadaScudo)
        ..ownedWeapons.add(LiteWeapon.arco);
      run.setBlocking(true);
      run.projectiles.add(
        LiteProjectile(
          position: run.position,
          direction: const Point(1, 0),
          speed: 20,
          remaining: 3,
          damage: 151,
          fromEnemy: true,
        ),
      );
      run.step(1 / 120);
      expect(run.blockResistance, 10);
      expect(run.switchWeapon(), isTrue);
      expect(run.blockResistance, 0);
      run.loot.add(LiteLoot(run.position, LiteLootKind.healing, 1));
      run.step(.01);
      expect(run.blockResistance, 10);
      expect(run.switchWeapon(), isTrue);
      expect(run.blockResistance, 20);
      expect(_restore(run).blockResistance, 20);
    },
  );

  test('max-rank modifiers change Open, weapon recovery and clash damage', () {
    final run = LiteRun.fromJson({
      ..._run(hero: LiteHero.duplicatore).toJson(),
      'powers': {'riflusso': 3, 'risonanza': 3, 'braci': 3},
    })..obstacles.clear();
    const focus = Point<double>(6, 11);
    final target = _stationaryEnemy(841, const Point(7.2, 11), hp: 90);
    run.enemies
      ..clear()
      ..add(target);
    expect(run.useOpen(focus), isTrue);
    expect(run.shield, 22);
    run.clones.clear();
    expect(run.attack(target.position), isTrue);
    expect(run.attackCooldown, LiteWeapon.arco.cooldown * .5);
    run.projectiles
      ..clear()
      ..addAll([
        shot(focus, const Point(1, 0), enemy: false),
        shot(focus, const Point(-1, 0)),
      ]);
    run.step(1 / 120);
    expect(target.hp, 70);
    expect(
      run.combatImpacts.any(
        (impact) => impact.target == LiteImpactTarget.clash,
      ),
      isTrue,
    );
  });

  test('a downed Master cannot pick up a gem or revive an ally', () {
    final run = LiteRun(
      seed: 43,
      hero: LiteHero.ashley,
      weapon: LiteWeapon.arco,
      playerCount: 2,
    )..hp = 1;
    expect(
      run.addCoopFighter('guest', 'Ospite', LiteHero.evasore, LiteWeapon.arco),
      isTrue,
    );
    final ally = _downAlly(run);
    expect(ally.down, isTrue);
    expect(run.beginRescue(), isTrue);
    run.loot.add(LiteLoot(run.position, LiteLootKind.refinedGreenGem, 1));
    run.projectiles.add(shot(run.position, const Point(1, 0)));
    run.step(1 / 120);
    expect(run.hostDown, isTrue);
    expect(run.rescuing, isFalse);
    expect(run.beginRescue(), isFalse);
    expect(run.loot.single.kind, LiteLootKind.refinedGreenGem);
  });

  test('a guest who falls loses a charged shot before the next arena', () {
    final run = LiteRun(
      seed: 43,
      hero: LiteHero.ashley,
      weapon: LiteWeapon.arco,
      playerCount: 2,
    );
    run.addCoopFighter(
      'guest',
      'Ospite',
      LiteHero.evasore,
      LiteWeapon.carabinaImpulsi,
    );
    final guest = run.coopFighter('guest')!
      ..hp = 1
      ..cooldown = 0;
    run.setCoopControls(
      'guest',
      const Point(0, 0),
      const Point(10, 11),
      attack: true,
    );
    run.step(1 / 120);
    expect(guest.preparingAttack, isTrue);
    run.projectiles.add(shot(guest.position, const Point(1, 0)));
    run.step(1 / 120);
    expect(guest.hp, 0);
    expect(guest.preparingAttack, isFalse);
    run.stageClear = true;
    expect(run.advanceCoop(LiteBiome.postea), isTrue);
    expect(guest.hp, greaterThan(0));
    _wait(run, .5);
    expect(
      run.projectiles.where((projectile) => !projectile.fromEnemy),
      isEmpty,
    );
  });

  test('Vita grants 1.9 seconds and a fully absorbed hit grants .95', () {
    final run = _run();
    run.projectiles.add(shot(run.position, const Point(1, 0)));
    run.step(1 / 120);
    expect(run.hp, 90);
    expect(run.hitProtectionRemaining, LiteRun.lifeHitProtection);
    expect(run.combatImpacts.single.life, 10);
    expect(run.intangible, isFalse);
    run.projectiles.add(shot(run.position, const Point(1, 0)));
    _wait(run, 1.85);
    expect(run.hp, 90);
    expect(run.invulnerable, isTrue);
    _wait(run, .05);
    expect(run.invulnerable, isFalse);

    run.shield = 15;
    run.projectiles.add(shot(run.position, const Point(1, 0)));
    run.step(1 / 120);
    expect(run.hp, 90);
    expect(run.shield, 5);
    expect(run.combatImpacts.single.shield, 10);
    final sharedFrame = LiteRun.fromJson(run.toJson(includeEffects: true));
    expect(sharedFrame.combatImpacts.single.shield, 10);
    expect(sharedFrame.combatImpacts.single.position, run.position);
    expect(sharedFrame.combatImpacts.single.life, 0);
    final restored = _restore(run);
    expect(restored.hitProtectionRemaining, LiteRun.shieldHitProtection);
    expect(restored.combatImpacts, isEmpty);
  });

  test(
    'a real personal hit ends protection, an allied hit or miss does not',
    () {
      final run = _run();
      final enemy = _stationaryEnemy(107, const Point(7, 11));
      run.enemies
        ..clear()
        ..add(enemy);
      run.projectiles.add(shot(run.position, const Point(1, 0)));
      run.step(1 / 120);
      run.projectiles.add(
        shot(enemy.position, const Point(1, 0), enemy: false, own: false),
      );
      run.step(1 / 120);
      expect(enemy.hp, 50);
      expect(run.invulnerable, isTrue);
      run.attack(const Point(7, 14));
      _wait(run, .49);
      expect(run.invulnerable, isTrue);
      expect(run.attack(enemy.position), isTrue);
      expect(run.invulnerable, isTrue);
      _wait(run, .16);
      expect(run.invulnerable, isFalse);
      expect(enemy.hp, 39);
    },
  );

  test(
    'hostile projectiles clash with friendly projectiles and blade strikes',
    () {
      final run = _run(weapon: LiteWeapon.spadaScudo);
      run.projectiles.addAll([
        shot(const Point(6, 11), const Point(1, 0), enemy: false),
        shot(const Point(7, 11), const Point(-1, 0)),
      ]);
      _wait(run, .05);
      expect(run.projectiles, isEmpty);
      expect(run.combatImpacts.single.target, LiteImpactTarget.clash);
      final enemy = _stationaryEnemy(107, const Point(6, 11));
      run.enemies.add(enemy);
      run.projectiles.add(shot(const Point(5.6, 11), const Point(-1, 0)));
      expect(run.attack(enemy.position), isTrue);
      expect(enemy.hp, enemy.maxHp);
      expect(run.projectiles.single.remaining, 0);
      expect(run.combatImpacts.last.target, LiteImpactTarget.clash);
    },
  );

  test('simultaneous melee makes both attackers retreat while intangible', () {
    final run = _run(weapon: LiteWeapon.spadaScudo);
    run.position = const Point(16, 11);
    run.obstacles.clear();
    final enemy = LiteEnemy(107, LiteEnemyKind.slime, const Point(17, 11), 70)
      ..attackTarget = run.position
      ..windup = .04;
    run.enemies
      ..clear()
      ..add(enemy);
    expect(run.attack(enemy.position), isTrue);
    expect(run.clashDashing, isTrue);
    expect(run.intangible, isTrue);
    expect(enemy.clashRemaining, LiteRun.clashDashDuration);
    expect(enemy.hp, 70);
    run.lookAt(const Point(0, 11));
    expect(run.aim.x, 1);
    _wait(run, .13);
    expect(run.position.x, lessThan(16));
    expect(enemy.position.x, greaterThan(17));
    final frame = LiteRun.fromJson(run.toJson(includeEffects: true));
    final trails = frame.burstTraces.toList();
    expect(trails.map((trail) => trail.kind), [
      LiteBurstKind.clash,
      LiteBurstKind.clash,
    ]);
    expect(trails.first.end.x, lessThan(16));
    expect(trails.last.end.x, greaterThan(17));
    expect(run.intangible, isTrue);
    expect(_restore(run).clashDashing, isTrue);
    _wait(run, .14);
    expect(run.hp, 100);
    expect(run.intangible, isFalse);
    expect(enemy.clashRemaining, 0);
  });

  test('power offers are saved in order, grant one rank and cap at three', () {
    var run = _reachFloor(0);
    final startingDamage = run.weaponDamage;
    for (var i = 1; i <= 3; i++) {
      while (!run.stageClear) {
        _strikeCampaignEnemy(run, run.enemies.first);
      }
      expect(run.powerOffers.length, 3);
      final offers = run.powerOffers.toList();
      run = _restore(run);
      expect(run.powerOffers, offers);
      expect(offers.first, LitePowerUp.lama);
      expect(run.choosePowerUp(LitePowerUp.lama), isTrue);
      expect(run.choosePowerUp(offers.last), isFalse);
      expect(run.powerRank(LitePowerUp.lama), i);
      run.position = run.portalPosition;
      expect(run.advance(LiteBiome.campo), isTrue);
    }
    expect(run.weaponDamage, closeTo(startingDamage * 1.65, 1e-6));
    while (!run.stageClear) {
      _strikeCampaignEnemy(run, run.enemies.first);
    }
    expect(run.powerOffers, isNot(contains(LitePowerUp.lama)));
    expect(run.enemies, isEmpty);
  });

  test('reflective encounters keep independent power snapshots and signature moves', () {
    final run = _reachFloor(9, hero: LiteHero.duplicatore);
    while (run.enemies.every((it) => it.kind != LiteEnemyKind.ombra)) {
      _strikeCampaignEnemy(run, run.enemies.first);
    }
    final boss = run.enemies.singleWhere(
      (it) => it.kind == LiteEnemyKind.ombra,
    );
    run.obstacles.clear();
    run.position = const Point(16, 11);
    boss
      ..position = const Point(20, 11)
      ..windup = 0;
    boss.mirror!.signatureCooldown = 0;
    run.step(1 / 120);
    expect(boss.position, isNot(const Point(20, 11)));
    expect(boss.mirror!.shadowVeilRemaining, LiteRun.shadowVeilDuration);
    expect(_restore(run).enemies.single.mirror!.shadowVeilRemaining, 3);
    final low = _run();
    final high = _run()..level = 28;
    expect(high.verdictDamage, greaterThan(low.verdictDamage));
  });

  test(
    'necromancer summons two weapons and crow form persists with knockback',
    () {
      var run = _run(hero: LiteHero.curatorePeste)
        ..enemies.clear()
        ..obstacles.clear();
      expect(run.special(const Point(9, 11)), isTrue);
      expect(run.special(const Point(9, 11)), isFalse);
      expect(run.clones.map((ally) => ally.weapon), [
        LiteWeapon.falceRunica,
        LiteWeapon.arco,
      ]);
      expect(
        run.clones.every((ally) => ally.summoned && ally.expiresAfter == 18),
        isTrue,
      );
      run.clones.clear();
      run.hp = 60;
      expect(run.useOpen(const Point(9, 11)), isTrue);
      expect(run.hp, 120);
      run = _restore(run);
      expect(run.plagueForm, isTrue);
      expect(run.maxHp, 200);
      final enemy = _stationaryEnemy(901, const Point(7.5, 11), hp: 180);
      run.enemies.add(enemy);
      expect(run.attack(enemy.position), isTrue);
      _wait(run, .38);
      expect(enemy.position.x, greaterThan(8.5));
      _wait(run, 3.65);
      expect(run.plagueForm, isFalse);
      expect(run.hp, 60);
    },
  );

  test('an attributed necromancer kill restores life and block resistance', () {
    final run = _run(hero: LiteHero.curatorePeste)
      ..enemies.clear()
      ..obstacles.clear()
      ..hp = 62;
    run.setBlocking(true);
    run.projectiles.add(shot(run.position, const Point(1, 0)));
    run.step(1 / 120);
    run.setBlocking(false);
    expect(run.blockResistance, 90);
    final target = _stationaryEnemy(902, const Point(7.1, 11), hp: 4);
    run.enemies.add(target);
    expect(run.attack(target.position), isTrue);
    _wait(run, .42);
    expect(target.hp, 0);
    expect(run.blockResistance, 100);
    expect(run.hp, 70);
  });

  test(
    'Open effects and cooldowns use the character level, also for guests',
    () {
      for (final (level, grade, cooldown) in [
        (1, 1, 8),
        (3, 2, 7),
        (6, 3, 6),
      ]) {
        final run = _run(hero: LiteHero.granScostumato)..level = level;
        expect(run.openGrade, grade);
        expect(run.useOpen(const Point(9, 11)), isTrue);
        expect(run.openCooldown, cooldown);
        expect(run.clones.first.expiresAfter, 12 + 3 * (grade - 1));
        expect(_restore(run).openCooldown, cooldown);
      }
      final run = LiteRun(
        seed: 43,
        hero: LiteHero.evasore,
        weapon: LiteWeapon.arco,
        playerCount: 2,
      );
      run.addCoopFighter(
        'guest',
        'Gran Scostumato',
        LiteHero.granScostumato,
        LiteWeapon.arco,
      );
      final guest = run.coopFighter('guest')!..experience = 675;
      expect(guest.level, 6);
      run.setCoopControls(
        'guest',
        const Point(0, 0),
        const Point(8, 11),
        attack: false,
        open: true,
      );
      expect(guest.openCooldown, 6);
      expect(
        run.clones.where((ally) => ally.ownerId == guest.id),
        hasLength(2),
      );
      expect(_restore(run).coopFighter('guest')!.maxHp, 150);
    },
  );

  test(
    'NPC escort is granted only after a later floor and a living companion',
    () {
      final run = _run(weapon: LiteWeapon.spadaScudo, biome: LiteBiome.dungeon);
      run.enemies
        ..clear()
        ..add(LiteEnemy(901, LiteEnemyKind.costrutto, const Point(5.5, 11), 1));
      _strikeCampaignEnemy(run, run.enemies.single);
      final sentinel = run.clones.single;
      expect(sentinel.companion, LiteCompanion.sentinella);
      expect(sentinel.recruitedFloor, 0);
      run.stageClear = true;
      run.position = run.portalPosition;
      expect(run.advance(), isTrue);
      expect(
        run.unlockedHeroesFor(run.hero),
        isNot(contains(LiteHero.sentinella)),
      );
      final restored = _restore(run);
      final ally = restored.clones.single;
      expect(ally.recruitedFloor, 0);
      restored.stageClear = true;
      restored.position = restored.portalPosition;
      expect(restored.advance(), isTrue);
      expect(
        restored.unlockedHeroesFor(restored.hero),
        contains(LiteHero.sentinella),
      );
    },
  );

  test('holding R rescues and reloads together only after the full hold', () {
    final run = _run();
    expect(run.attack(run.position + const Point<double>(1, 0)), isTrue);
    final ally = _downAlly(run);
    expect(ally.down, isTrue);
    expect(run.beginRescue(), isTrue);
    _wait(run, .6);
    run.endRescue();
    expect(run.arrows, LiteRun.bowCapacity - 1);
    expect(ally.hp, 0);

    expect(run.beginRescue(), isTrue);
    _wait(run, .5);
    final restored = _restore(run);
    expect(restored.rescuing, isFalse);
    expect(restored.clones.single.down, isTrue);
    _wait(run, .7);
    expect(ally.hp, 3);
    expect(run.arrows, LiteRun.bowCapacity);
    expect(run.rescuing, isFalse);
  });

  test(
    'melee weapons rescue without reloading and distance cancels the hold',
    () {
      final run = _run(weapon: LiteWeapon.guanti);
      expect(run.beginReload(), isFalse);
      final ally = _downAlly(run);
      expect(run.beginRescue(), isTrue);
      expect(run.reloadingDuringRescue, isFalse);
      run.step(.25, move: const Point(0, -1));
      expect(run.rescuing, isFalse);
      expect(ally.down, isTrue);
      run.position = ally.position;
      expect(run.beginRescue(), isTrue);
      _wait(run, LiteRun.rescueDuration);
      expect(ally.hp, 3);
    },
  );

  test(
    'co-op rescue reaches the Master and pauses without losing progress',
    () {
      final run = LiteRun(
        seed: 43,
        hero: LiteHero.ashley,
        weapon: LiteWeapon.guanti,
        playerCount: 2,
      );
      run.enemies.clear();
      run.addCoopFighter('guest', 'Ospite', LiteHero.evasore, LiteWeapon.arco);
      final guest = run.coopFighter('guest')!..arrows = 2;
      run.hp = 0;

      void send({bool held = true}) => run.setCoopControls(
        'guest',
        const Point(0, 0),
        const Point(10, 11),
        attack: false,
        rescue: held,
      );

      send();
      _wait(run, .40);
      final progress = guest.rescueStatus!.progress;
      expect(progress, closeTo(.40 / LiteRun.rescueDuration, 1e-9));
      run.projectiles.add(shot(guest.position, const Point(1, 0)));
      _wait(run, .20);
      expect(guest.hp, lessThan(guest.maxHp));
      expect(guest.rescueStatus!.progress, closeTo(progress, 1e-9));
      expect(guest.rescueStatus!.paused, isTrue);
      final view = LiteRun.fromJson(run.toJson(includeEffects: true));
      expect(view.coopFighter('guest')!.rescueStatus, guest.rescueStatus);
      expect(_restore(run).coopFighter('guest')!.rescueStatus, isNull);

      send(held: false);
      expect(guest.rescueStatus, isNull);
      expect(guest.arrows, 2);
      expect(run.hostDown, isTrue);

      send();
      _wait(run, .65);
      send();
      _wait(run, .56);
      expect(run.hp, 30);
      expect(guest.arrows, LiteRun.bowCapacity);
      expect(guest.rescueStatus, isNull);

      guest.hp = 0;
      send(held: false);
      expect(run.beginRescue(), isTrue);
      _wait(run, .65);
      send(held: false);
      _wait(run, .56);
      expect(guest.hp, 30);
    },
  );

  test('co-op Ristoro is personal, authoritative and once per floor', () {
    final run = LiteRun(
      seed: 43,
      hero: LiteHero.ashley,
      weapon: LiteWeapon.guanti,
      playerCount: 2,
    );
    run.addCoopFighter(
      'guest',
      'Ospite',
      LiteHero.evasore,
      LiteWeapon.arco,
      upgrades: {LitePermanentUpgrade.vita: 2, LitePermanentUpgrade.oculum: 2},
    );
    final guest = run.coopFighter('guest')!
      ..hp = 20
      ..oculum = 2;
    run
      ..position = run.restPosition
      ..hp = 20
      ..oculum = 2;
    void requestRest() => run.setCoopControls(
      'guest',
      const Point(0, 0),
      run.restPosition,
      attack: false,
      rest: true,
    );

    requestRest();
    expect(guest.hp, 20);
    expect(guest.restUsed, isFalse);
    guest.position = run.restPosition;
    requestRest();
    expect(guest.hp, 20);
    run.stageClear = true;
    requestRest();
    expect(guest.hp, 75);
    expect(guest.oculum, 5);
    expect(run.hp, 20);
    expect(run.useRest(), isTrue);
    expect(run.hp, 70);
    requestRest();
    expect(guest.hp, 75);
    expect(run.useRest(), isFalse);
    expect(_restore(run).coopFighter('guest')!.restUsed, isTrue);
    expect(run.advanceCoop(LiteBiome.postea), isTrue);
    expect(guest.restUsed, isFalse);
    expect(run.restUsed, isFalse);
  });

  test('bow reload keeps its progress across save and swap', () {
    final run = _run();
    run.ownedWeapons.add(LiteWeapon.spadaScudo);
    expect(run.attack(const Point(7, 11)), isTrue);
    expect(run.beginReload(), isTrue);
    _wait(run, .6);
    expect(run.beginReload(), isFalse);
    expect(run.switchWeapon(), isTrue);
    final restored = _restore(run);
    expect(restored.reloading, isTrue);
    _wait(restored, .6);
    expect(restored.reloading, isFalse);
    expect(restored.arrows, LiteRun.bowCapacity);
    expect(restored.weapon, LiteWeapon.spadaScudo);
  });

  test('same seed and play produce identical state after resuming combat', () {
    final original = _run(weapon: LiteWeapon.boomerang);
    expect(_run(weapon: LiteWeapon.boomerang).toJson(), original.toJson());
    original.attack(const Point(28, 11));
    original.step(.17, move: const Point(1, .2));
    final restored = _restore(original);
    expect(restored.toJson(), original.toJson());
    for (var i = 0; i < 230; i++) {
      original.step(1 / 120, move: const Point(.17, -1));
      restored.step(1 / 120, move: const Point(.17, -1));
    }
    expect(restored.toJson(), original.toJson());
  });

  test('bow deals base +3 and counts the full 10 m, with no hit past it', () {
    for (final distance in [9.9, 10.0, 10.02]) {
      final run = _run();
      final enemy = LiteEnemy(
        500,
        LiteEnemyKind.scostubandito,
        Point(run.position.x + distance, run.position.y),
        80,
      )..cooldown = 90;
      run.enemies
        ..clear()
        ..add(enemy);
      run.obstacles.clear();
      expect(run.attack(enemy.position), true);
      final arrow = run.projectiles.single;
      expect(arrow.damage, 11);
      expect(arrow.remaining, 10);
      arrow.position = Point(run.position.x + 9.999, run.position.y);
      arrow.remaining = .001;
      run.step(.0001);
      expect(enemy.hp, distance <= 10 ? 69 : 80, reason: '$distance m');
    }
  });

  test('wall stops an arrow before it can hit a nearby target', () {
    final run = _run();
    final enemy = LiteEnemy(
      700,
      LiteEnemyKind.scostubandito,
      const Point(10, 11),
      60,
    )..cooldown = 20;
    run.enemies
      ..clear()
      ..add(enemy);
    run.obstacles
      ..clear()
      ..add(LiteObstacle(6, 10, 1, 2));
    run.attack(enemy.position);
    _wait(run, .5);
    expect(run.projectiles, isEmpty);
    expect(enemy.hp, 60);
  });

  test(
    'sceptre empowers direct magic and a scroll once, with normal costs',
    () {
      final run = _run(weapon: LiteWeapon.scettro);
      const target = Point<double>(14, 11);
      expect(run.attack(target), true);
      expect(run.projectiles.single.damage, closeTo(8 * 1.15, .0001));
      expect(run.oculum, 10);
      run.scrolls[LiteScroll.dardo.index] = 1;
      expect(run.castScroll(0, target), true);
      expect(run.projectiles.last.damage, closeTo(24 * 1.15, .0001));
      expect(run.oculum, 7);
      expect(run.scrolls[LiteScroll.dardo.index], 0);
    },
  );

  test('tangible Shift and intangible dodge keep different rules', () {
    LiteProjectile hostile(Point<double> p) => LiteProjectile(
      position: p,
      direction: const Point(-1, 0),
      speed: 8,
      remaining: 8,
      damage: 10,
      fromEnemy: true,
    );
    const aim = Point<double>(14, 11);
    final dodger = _run();
    dodger.projectiles.add(hostile(dodger.position));
    expect(dodger.special(aim), true);
    expect(dodger.dodgeCharges, 0);
    expect(dodger.invulnerable, true);
    dodger.step(1 / 120);
    expect(dodger.hp, dodger.maxHp);
    expect(dodger.projectiles, hasLength(1));
    _wait(dodger, 3.3);
    expect(dodger.dodgeCharges, 1);

    final dasher = _run();
    dasher.projectiles.add(hostile(dasher.position));
    expect(dasher.dash(aim), true);
    expect(dasher.invulnerable, false);
    expect(dasher.dodgeCharges, 1);
    dasher.step(1 / 120);
    expect(dasher.hp, dasher.maxHp - 10);
  });

  test('two duplicates snapshot their weapon and cost 2% max Life each', () {
    final run = _run(hero: LiteHero.duplicatore, weapon: LiteWeapon.guanti)
      ..level = 2
      ..hp = 40;
    expect(run.special(const Point(14, 11)), true);
    expect(run.special(const Point(14, 11)), true);
    expect(run.special(const Point(14, 11)), false);
    expect(run.hp, 34);
    expect(run.clones, hasLength(2));
    for (final clone in run.clones) {
      expect(clone.hp, 3);
      expect(clone.weapon, LiteWeapon.guanti);
    }
    expect(_restore(run).toJson(), run.toJson());
    run.clones.clear();
    run.hp = 2;
    expect(run.special(const Point(14, 11)), false);
    expect(run.hp, 2);
  });

  test('passive on a confirmed kill is reproducible and heals 6% max Life', () {
    final source = _run(weapon: LiteWeapon.spadaScudo)
      ..level = 2
      ..hp = 80;
    source.enemies
      ..clear()
      ..add(
        LiteEnemy(100, LiteEnemyKind.granScostumato, const Point(5.5, 11), 1),
      );
    final good = source.toJson()..['rng'] = 1;
    final bad = source.toJson()..['rng'] = 30000;
    final success = LiteRun.fromJson(good);
    final failure = LiteRun.fromJson(bad);
    expect(success.attack(const Point(5.5, 11)), true);
    expect(failure.attack(const Point(5.5, 11)), true);
    expect(success.hp, closeTo(80 + 110 * .06, .0001));
    expect(failure.hp, 80);
    expect(_restore(success).hp, success.hp);
  });

  test('evasive character has four independent scroll bindings', () {
    final run = _run();
    const aim = Point<double>(12, 11);
    run.scrolls[LiteScroll.dardo.index] = 1;
    run.scrolls[LiteScroll.velo.index] = 1;
    expect(run.castScroll(1, aim), false);
    expect(run.castScroll(0, aim), true);
    _wait(run, .5);
    expect(run.castScroll(0, aim), false);
    expect(run.castScroll(2, aim), true);
    expect(run.shield, 15);
    expect(run.oculum, 4);
  });

  test('starting weapons retain sword shield, clear glove windup and wooden return', () {
    final sword = _run(weapon: LiteWeapon.spadaScudo);
    expect(sword.weaponDamage, 14);
    expect(sword.shield, 6);
    sword.projectiles.add(
      LiteProjectile(
        position: sword.position,
        direction: const Point(1, 0),
        speed: 8,
        remaining: 2,
        damage: 10,
        fromEnemy: true,
      ),
    );
    sword.step(1 / 120);
    expect(sword.shield, 0);
    expect(sword.hp, 97);

    final gauntlets = _run(weapon: LiteWeapon.guanti);
    final near = _stationaryEnemy(100, const Point(6.1, 11));
    gauntlets.enemies
      ..clear()
      ..add(near);
    expect(gauntlets.attack(near.position), isTrue);
    expect(gauntlets.preparingAttack, isTrue);
    _wait(gauntlets, .30);
    expect(near.hp, 60);
    _wait(gauntlets, .05);
    expect(near.hp, 42);

    final wood = _run(weapon: LiteWeapon.boomerang);
    final offAxis = _stationaryEnemy(101, const Point(8, 12));
    wood.enemies
      ..clear()
      ..add(offAxis);
    expect(wood.attack(const Point(12, 11)), isTrue);
    _wait(wood, .25);
    expect(wood.projectiles.single.direction.y, greaterThan(0));
    expect(wood.projectiles.single.damage, 13);
    _wait(wood, .32);
    expect(wood.projectiles.single.returning, isTrue);
    _wait(wood, .58);
    expect(wood.projectiles, isEmpty);
    expect(LiteWeapon.starters, hasLength(5));
    expect(LiteWeapon.starters.every((item) => !item.isPostea), isTrue);
  });

  test('duplicated wooden boomerang returns to the thrower after resuming', () {
    final run = _run(hero: LiteHero.duplicatore, weapon: LiteWeapon.boomerang);
    run.enemies
      ..clear()
      ..add(_stationaryEnemy(100, const Point(8, 12.2)));
    expect(run.special(const Point(10, 11)), isTrue);
    _wait(run, .40);
    final clone = run.clones.single;
    expect(run.projectiles.single.sourceCloneId, clone.id);
    clone.cooldown = 5;
    final restored = _restore(run);
    _wait(restored, .54);
    final flight = restored.projectiles.single;
    expect(flight.returning, isTrue);
    expect(flight.sourceCloneId, restored.clones.single.id);
    final pull = restored.clones.single.position - flight.position;
    expect(flight.direction.y, closeTo(pull.y / pull.magnitude, .02));
  });

  test('runic scythe sweeps a wider arc and pulls on its return', () {
    final run = _run(weapon: LiteWeapon.falceRunica, biome: LiteBiome.postea);
    final flank = _stationaryEnemy(100, const Point(4.9, 14));
    final across = _stationaryEnemy(101, const Point(9.5, 11));
    run.enemies
      ..clear()
      ..addAll([flank, across]);
    expect(run.attack(const Point(14, 11)), isTrue);
    expect(flank.hp, 45);
    expect(across.hp, 60);
    _wait(run, .52);
    expect(across.hp, 52.5);
    final returning = _restore(run);
    _wait(returning, .17);
    final pulled = returning.enemies.last;
    expect(pulled.hp, 45);
    expect(pulled.position.x, closeTo(8.6, .01));
  });

  test('dual blades step and resolve the second hit after resuming', () {
    final run = _run(weapon: LiteWeapon.doppieLame, biome: LiteBiome.postea);
    final enemy = _stationaryEnemy(100, const Point(5.6, 11));
    run.enemies
      ..clear()
      ..add(enemy);
    expect(run.attack(enemy.position), isTrue);
    expect(enemy.hp, closeTo(60 - 12 * .56, .0001));
    expect(run.position.x, closeTo(5.05, .0001));
    final restored = _restore(run);
    _wait(restored, .13);
    expect(restored.enemies.single.hp, closeTo(60 - 24 * .56, .0001));
    expect(restored.preparingAttack, isFalse);
  });

  test('pulse carbine charges, hits past bow range and pierces twice', () {
    final run = _run(
      weapon: LiteWeapon.carabinaImpulsi,
      biome: LiteBiome.postea,
    );
    run.enemies
      ..clear()
      ..addAll([
        _stationaryEnemy(100, const Point(14.6, 11)),
        _stationaryEnemy(101, const Point(15.6, 11)),
        _stationaryEnemy(102, const Point(16.6, 11)),
      ]);
    expect(run.attack(const Point(20, 11)), isTrue);
    _wait(run, .40);
    expect(run.projectiles, isEmpty);
    final restored = _restore(run);
    _wait(restored, .09);
    expect(restored.projectiles.single.kind, LiteProjectileKind.pulse);
    _wait(restored, .55);
    expect(restored.enemies.map((enemy) => enemy.hp), [44, 44, 60]);
    expect(restored.arrows, LiteRun.bowCapacity);
  });

  test('Gran Scostumato lifts the cannon and breaks destructible cover', () {
    final run = _run();
    final elite = LiteEnemy(
      100,
      LiteEnemyKind.granScostumato,
      const Point(10, 11),
      125,
    )..cooldown = 0;
    run.enemies
      ..clear()
      ..add(elite);
    run.obstacles
      ..clear()
      ..add(LiteObstacle(7, 10, 1, 2, breakable: true, hp: 80));
    _wait(run, .90);
    expect(elite.cannonRaised, isTrue);
    expect(run.projectiles, isEmpty);
    final restored = _restore(run);
    _wait(restored, .50);
    expect(restored.obstacles, isEmpty);
    expect(restored.projectiles.single.kind, LiteProjectileKind.cannon);
    _wait(restored, .26);
    expect(restored.hp, 78);
  });

  test('Postea loot and merchant put weapons in the same saved inventory', () {
    final oldShop = _run()
      ..shopOpen = true
      ..obser = 100;
    expect(oldShop.shopWeapons.contains(LiteWeapon.falceRunica), isFalse);
    expect(oldShop.buyWeapon(LiteWeapon.falceRunica), isFalse);
    expect(oldShop.buyWeapon(LiteWeapon.piccaOssidiana), isFalse);

    final run = _run(weapon: LiteWeapon.spadaScudo, biome: LiteBiome.postea);
    expect(
      run.enemies.any((enemy) => enemy.kind == LiteEnemyKind.ragnoSaldatore),
      isTrue,
    );
    expect(
      run.enemies.any((enemy) => enemy.kind == LiteEnemyKind.dronePostea),
      isTrue,
    );
    final spider = LiteEnemy(
      100,
      LiteEnemyKind.ragnoSaldatore,
      const Point(5.5, 11),
      1,
    );
    run.enemies
      ..clear()
      ..add(spider);
    expect(run.attack(spider.position), isTrue);
    final savedLoot = _restore(run);
    expect(
      savedLoot.loot
          .where((item) => item.kind == LiteLootKind.weapon)
          .single
          .weapon,
      LiteWeapon.carabinaImpulsi,
    );
    savedLoot.position = spider.position;
    savedLoot.step(1 / 120);
    expect(savedLoot.ownedWeapons, contains(LiteWeapon.carabinaImpulsi));
    savedLoot
      ..shopOpen = true
      ..obser = 100;
    expect(savedLoot.shopWeapons.contains(LiteWeapon.falceRunica), isTrue);
    expect(savedLoot.canBuyWeapon(LiteWeapon.carabinaImpulsi), isFalse);
    expect(savedLoot.buyWeapon(LiteWeapon.falceRunica), isTrue);
    expect(savedLoot.obser, 100 - LiteRun.posteaWeaponPrice);
  });

  test(
    'a natural 20 from Ragno Saldatore drops an equipable plasma scroll',
    () {
      final seed = _run(weapon: LiteWeapon.spadaScudo, biome: LiteBiome.postea);
      final spider = LiteEnemy(
        100,
        LiteEnemyKind.ragnoSaldatore,
        const Point(5.5, 11),
        1,
      );
      seed.enemies
        ..clear()
        ..add(spider);
      final data = seed.toJson()
        ..['rng'] = 44000
        ..['scrolls'] = [0, 0, 0, 0];
      final run = LiteRun.fromJson(data);
      expect(run.equippedScrolls, hasLength(4));
      expect(run.scrolls, hasLength(LiteScroll.values.length));
      expect(run.attack(spider.position), isTrue);
      run.position = spider.position;
      run.step(1 / 120);
      expect(run.scrolls[LiteScroll.raggioAlPlasma.index], 1);
      expect(run.equipScroll(4, LiteScroll.raggioAlPlasma), isFalse);
      expect(run.equipScroll(3, LiteScroll.raggioAlPlasma), isTrue);

      final restored = _restore(run);
      expect(restored.equippedScrolls[3], LiteScroll.raggioAlPlasma);
      expect(restored.castScroll(3, const Point(10, 11)), isTrue);
      expect(restored.projectiles.single.kind, LiteProjectileKind.plasma);
      expect(restored.projectiles.single.damage, 22);
      expect(restored.oculum, 6);
      expect(restored.scrolls[LiteScroll.raggioAlPlasma.index], 0);
    },
  );

  for (final biome in LiteBiome.values) {
    test('${biome.name}: wave, elite, 3 quests, shop and voluntary exit', () {
      final run = _run(weapon: LiteWeapon.spadaScudo, biome: biome);
      final ids = run.quests.map((quest) => quest.id).toSet();
      expect(ids, hasLength(3));
      expect(run.advance(), false);
      expect(run.buyPotion(), false);

      // Use a controlled combat lane to test settlement and traversal for each
      // roster without tying combat rules to a particular controller.
      var attacks = 0;
      while (!run.stageClear && !run.dead && attacks < 50) {
        final enemy = run.enemies.first;
        run.position = const Point(4, 11);
        enemy.position = const Point(5.5, 11);
        enemy.cooldown = 10;
        run.attack(enemy.position);
        run.step(.05);
        _wait(run, .44);
        run.position = const Point(5.5, 11);
        run.step(1 / 120);
        attacks++;
      }
      expect(run.dead, false);
      expect(run.stageClear, true);
      expect(run.eliteDefeated, true);
      expect(run.quests.every((quest) => quest.complete), true);
      expect(run.spentOculum, 3 + run.quests.first.target);
      expect(run.ascensionDust, 1);
      expect(run.crystals, 1);
      expect(run.quests.last.reward, 20);
      expect(run.achievements.containsAll(ids), true);
      final finished = _restore(run);
      _wait(finished, .8);
      expect(finished.crystals, 1);
      expect(finished.obser, run.obser);
      finished.position = finished.shopPosition;
      finished.hp = finished.maxHp * .5;
      expect(finished.interact(), true);
      expect(finished.buyPotion(), true);
      expect(finished.hp, finished.maxHp * .75);
      expect(_restore(finished).shopOpen, true);
      finished.closeShop();
      finished.position = finished.portalPosition;
      expect(finished.stage, 0);
      final destination =
          LiteBiome.values[(biome.index + 1) % LiteBiome.values.length];
      expect(finished.advance(destination), true);
      expect(finished.stage, 1);
      expect(finished.biome, destination);
      expect(finished.stageClear, false);
    });
  }

  test('campaign traverses 25 rooms with nine specials and saved victory', () {
    final route = <int, LiteEnemyKind>{};
    final layouts = <String>{};
    final questIds = <String>{};
    var ordinaryTotal = 0;
    var run = _run(weapon: LiteWeapon.spadaScudo)..level = 300;
    run.hp = run.maxHp;
    for (var floor = 0; floor <= LiteRun.finalStage; floor++) {
      expect(run.stage, floor);
      expect(run.toJson(), _restore(run).toJson());
      layouts.add(jsonEncode(run.toJson()['obstacles']));
      questIds.addAll(run.quests.map((quest) => quest.id));
      ordinaryTotal += run.enemies
          .where(
            (enemy) =>
                !enemy.kind.boss && !enemy.kind.elite && !enemy.kind.echo,
          )
          .length;
      while (!run.stageClear) {
        final enemy = run.enemies.first;
        if (enemy.kind.elite || enemy.kind.boss) route[floor] = enemy.kind;
        _strikeCampaignEnemy(run, enemy);
      }
      if (floor < LiteRun.finalStage) {
        expect(run.victorious, isFalse);
        run.position = run.portalPosition;
        expect(run.advance(), isTrue);
        run = _restore(run);
      }
    }
    expect(route, {
      0: LiteEnemyKind.granScostumato,
      3: LiteEnemyKind.luce,
      6: LiteEnemyKind.forestDemon,
      9: LiteEnemyKind.ombra,
      12: LiteEnemyKind.costrutto,
      15: LiteEnemyKind.divoramituBoss,
      18: LiteEnemyKind.eliteSolare,
      21: LiteEnemyKind.diavolo,
      24: LiteEnemyKind.veyrth,
    });
    expect(layouts, hasLength(25));
    expect(questIds, hasLength(75));
    expect(run.dead, isFalse);
    expect(run.finished, isTrue);
    expect(run.victorious, isTrue);
    expect(run.ascensionDust, 4);
    expect(run.bossCrystalGrades, hasLength(5));
    expect(run.spentOculum, ordinaryTotal + 4 * 3 + 5 * 5);
    expect(run.arenaSpeedBonus, 80);
    expect(
      run.unlockedHeroesFor(run.hero),
      containsAll([LiteHero.luce, LiteHero.ombra, LiteHero.veyrth]),
    );
    final restored = _restore(run);
    expect(restored.finalBossPhase, LiteFinalBossPhase.defeated);
    restored.position = restored.portalPosition;
    expect(restored.advance(), isFalse);
    expect(restored.attack(restored.position), isFalse);
    final settled = restored.toJson();
    _wait(restored, 2);
    expect(restored.toJson(), settled);
  });

  test('all four supply stops remain accessible in solo and co-op', () {
    for (final players in [1, 2]) {
      final run = LiteRun(
        seed: 241,
        hero: LiteHero.evasore,
        weapon: LiteWeapon.arco,
        playerCount: players,
      );
      for (final floor in [5, 11, 17, 23]) {
        run
          ..stage = floor
          ..stageClear = true
          ..restHub = false
          ..position = run.portalPosition;
        expect(run.awaitsRestHub, isTrue);
        expect(run.enterRestHub(), isTrue);
        expect(run.hasRest, isTrue);
        expect(run.awaitsRestHub, isFalse);
        final frame = LiteRun.fromJson(run.toJson(includeEffects: true));
        expect(frame.restHub, isTrue);
        expect(frame.lastStage, 24);
        expect(frame.awaitsRestHub, isFalse);
      }
      run.position = run.portalPosition;
      if (players == 1) {
        expect(run.advance(LiteBiome.foresta), isTrue);
      } else {
        expect(run.advanceCoop(LiteBiome.foresta), isTrue);
      }
      expect(run.isFinalFloor, isTrue);
      expect(run.enemies.single.kind, LiteEnemyKind.veyrth);
    }
  });

  test('the six-player world can publish every floor through Veyrth', () {
    final host = LiteRun(
      seed: 241,
      hero: LiteHero.evasore,
      weapon: LiteWeapon.spadaScudo,
      playerCount: 6,
    )..level = 300;
    host.hp = host.maxHp;
    for (var slot = 1; slot < LiteRun.maxCoopPlayers; slot++) {
      expect(
        host.addCoopFighter(
          'guest-$slot',
          'Ospite $slot',
          LiteHero.ashley,
          LiteWeapon.arco,
        ),
        isTrue,
      );
    }
    final visited = <int>[];
    final restStops = <int>[];

    void clearOpenings() {
      while (!host.stageClear) {
        host.enemies.clear();
        host.step(.01);
      }
    }

    for (var floor = 0; floor <= LiteRun.finalStage; floor++) {
      expect(host.stage, floor);
      final guest = LiteRun.fromJson(host.toJson(includeEffects: true));
      visited.add(guest.stage);
      expect(guest.lastStage, LiteRun.finalStage);
      expect(guest.coopFighters, hasLength(5));
      expect(guest.isFinalFloor, floor == LiteRun.finalStage);
      expect(guest.victorious, isFalse);
      if (host.isFinalFloor) {
        expect(guest.enemies.single.kind, LiteEnemyKind.veyrth);
        while (!host.stageClear) {
          _strikeCampaignEnemy(host, host.enemies.first);
        }
        break;
      }
      clearOpenings();
      host.position = host.portalPosition;
      if (host.awaitsRestHub) {
        expect(host.enterRestHub(), isTrue);
        restStops.add(floor);
        host.position = host.portalPosition;
        if (host.canChooseActTwo) {
          expect(host.enterSecondAct(LiteRealm.postea), isTrue);
          for (var visit = 1; visit <= LiteSecondAct.actTwoRooms; visit++) {
            clearOpenings();
            host.position = host.portalPosition;
            expect(host.awaitsRestHub, isFalse);
            if (visit < LiteSecondAct.actTwoRooms) {
              expect(host.advanceActTwo(), isTrue);
            }
          }
        }
      }
      expect(host.advanceCoop(LiteBiome.foresta), isTrue);
    }
    expect(visited, List.generate(25, (i) => i));
    expect(restStops, [5, 11, 17, 23]);
    final end = LiteRun.fromJson(host.toJson(includeEffects: true));
    expect(end.victorious, isTrue);
    expect(end.coopPortalOpen, isFalse);
  });

  test('old Veyrth saves preserve their fight and victory on floor 13', () {
    final source = _reachFloor(LiteRun.finalStage);
    final old = source.toJson()
      ..['campaignVersion'] = 1
      ..['stage'] = 13;
    final ongoing = LiteRun.fromJson(old);
    expect(ongoing.lastStage, 13);
    expect(ongoing.encounter, LiteEncounter.finalBoss);
    expect(ongoing.enemies.single.kind, LiteEnemyKind.veyrth);
    expect(ongoing.finalBossPhase, LiteFinalBossPhase.tangible);
    expect(_restore(ongoing).lastStage, 13);
    while (!ongoing.stageClear) {
      _strikeCampaignEnemy(ongoing, ongoing.enemies.first);
    }
    expect(ongoing.victorious, isTrue);
    expect(_restore(ongoing).victorious, isTrue);
    final completed = LiteRun.fromJson(
      ongoing.toJson()..['campaignVersion'] = 1,
    );
    expect(completed.victorious, isTrue);
    expect(completed.lastStage, 13);
    expect(OculumLiteProgress().recordRun(completed).earned, 6);
    final oldEarlierFloor = LiteRun.fromJson(
      _reachFloor(12).toJson()..['campaignVersion'] = 1,
    );
    expect(oldEarlierFloor.lastStage, 24);
    while (!oldEarlierFloor.stageClear) {
      _strikeCampaignEnemy(oldEarlierFloor, oldEarlierFloor.enemies.first);
    }
    oldEarlierFloor.position = oldEarlierFloor.portalPosition;
    expect(oldEarlierFloor.advance(), isTrue);
    expect(oldEarlierFloor.stage, 13);
    expect(oldEarlierFloor.encounter, LiteEncounter.ordinary);
    expect(oldEarlierFloor.victorious, isFalse);
  });

  test('existing checkpoint keeps current actors and position, then follows new schedule', () {
    final previous = _run(weapon: LiteWeapon.spadaScudo)
      ..position = const Point(14.4, 10)
      ..level = 300;
    final data = previous.toJson()
      ..remove('campaignVersion')
      ..remove('startingBiome')
      ..['stage'] = 2;
    final restored = LiteRun.fromJson(data);
    expect(restored.stage, 2);
    expect(restored.position, previous.position);
    expect(restored.toJson()['enemies'], data['enemies']);
    while (!restored.stageClear) {
      expect(
        restored.enemies.every(
          (enemy) => !enemy.kind.elite && !enemy.kind.boss,
        ),
        isTrue,
      );
      _strikeCampaignEnemy(restored, restored.enemies.first);
    }
    restored.position = restored.portalPosition;
    expect(restored.advance(), isTrue);
    expect(restored.encounter, LiteEncounter.boss);
    while (!restored.enemies.first.kind.boss) {
      _strikeCampaignEnemy(restored, restored.enemies.first);
    }
    expect(restored.enemies.single.kind, LiteEnemyKind.luce);
  });

  test(
    'mirrored boss freezes equipped actions and spends its own resources',
    () {
      final run = _reachFloor(3, hero: LiteHero.duplicatore);
      run.equipScroll(0, LiteScroll.raggioAlPlasma);
      run.scrolls[LiteScroll.raggioAlPlasma.index] = 1;
      while (!run.enemies.first.kind.boss) {
        _strikeCampaignEnemy(run, run.enemies.first);
      }
      final boss = run.enemies.single;
      expect(boss.mirror!.hero, LiteHero.duplicatore);
      expect(boss.mirror!.weapon, LiteWeapon.spadaScudo);
      expect(boss.mirror!.slots.first, LiteScroll.raggioAlPlasma);
      final available = boss.mirror!.oculum;
      run.equipScroll(0, LiteScroll.onda);
      run.scrolls[LiteScroll.raggioAlPlasma.index] = 3;
      run.obstacles.clear();
      run.position = const Point(24, 11);
      boss.mirror!.artCooldown = 0;
      final restored = _restore(run);
      _wait(restored, .04);
      final enemy = restored.enemies.single;
      expect(restored.projectiles.single.kind, LiteProjectileKind.plasma);
      expect(enemy.mirror!.oculum, available - LiteScroll.raggioAlPlasma.cost);
      expect(enemy.mirror!.quantities[LiteScroll.raggioAlPlasma.index], 0);
      expect(restored.scrolls[LiteScroll.raggioAlPlasma.index], 3);
      expect(restored.equippedScrolls.first, LiteScroll.onda);
    },
  );

  test('Veyrth summons 1-Life echoes every 3 seconds and cannot take damage while they live', () {
    final run = _reachFloor(LiteRun.finalStage);
    final boss = run.enemies.single..cooldown = 100;
    expect(run.finalBossPhase, LiteFinalBossPhase.tangible);
    _wait(run, 359 / 120);
    expect(run.enemies, hasLength(1));
    run.step(1 / 120);
    expect(run.enemies, hasLength(2));
    final echo = run.enemies.last;
    expect(echo.hp, 1);
    expect(echo.maxHp, 1);
    expect(run.finalBossPhase, LiteFinalBossPhase.intangible);
    final originalHp = boss.hp;
    final spent = run.spentOculum;
    run.position = const Point(26.4, 11);
    echo.position = const Point(25, 14);
    expect(run.attack(boss.position), isTrue);
    expect(boss.hp, originalHp);
    _wait(run, .44);
    echo.position = const Point(26.4, 12.4);
    expect(run.attack(echo.position), isTrue);
    expect(echo.hp, 0);
    expect(run.spentOculum, spent);
    expect(run.finalBossPhase, LiteFinalBossPhase.tangible);
    _wait(run, 2.56);
    expect(
      run.enemies.where((enemy) => enemy.kind == LiteEnemyKind.minionVeyrth),
      hasLength(1),
    );
    expect(run.finalBossTangible, isFalse);
  });

  test('Veyrth beam only starts tangible, persists across summons and burns cover at 2.5s', () {
    final run = _reachFloor(LiteRun.finalStage)..clones.clear();
    while (run.activeBeam == null) {
      run.step(1 / 120);
    }
    expect(run.activeBeam!.remaining, 6);
    expect(run.finalBossPhase, LiteFinalBossPhase.beamTangible);
    final numberOfWalls = run.obstacles.length;
    final originalLife = run.hp;
    _wait(run, 2);
    expect(run.finalBossPhase, LiteFinalBossPhase.beamIntangible);
    expect(run.activeBeam!.coverContact, closeTo(2, .0001));
    expect(run.activeBeam!.end.x, closeTo(19.8, .0001));
    expect(run.hp, originalLife);
    final restored = _restore(run);
    expect(restored.toJson(), run.toJson());
    _wait(restored, 59 / 120);
    expect(restored.obstacles, hasLength(numberOfWalls));
    restored.step(1 / 120);
    expect(restored.obstacles, hasLength(numberOfWalls - 1));
    expect(restored.activeBeam!.coverContact, 0);
    expect(restored.quests[1].complete, isTrue);
    final direction = restored.activeBeam!.direction;
    restored.position = const Point(7, 3);
    _wait(restored, .25);
    final after = restored.activeBeam!.direction;
    final turn = acos(
      (direction.x * after.x + direction.y * after.y).clamp(-1, 1),
    );
    expect(turn, closeTo(.38 * .25, .001));
    _wait(restored, 389 / 120);
    expect(restored.activeBeam!.remaining, closeTo(1 / 120, .0001));
    restored.step(1 / 120);
    expect(restored.activeBeam, isNull);
  });

  test(
    'an intangible Veyrth uses radial spheres instead of starting a beam',
    () {
      final run = _reachFloor(LiteRun.finalStage);
      final boss = run.enemies.single
        ..summonIn = 0
        ..cooldown = 0;
      _wait(run, .2);
      expect(boss.preparingSpheres, isTrue);
      expect(run.projectiles, isEmpty);
      expect(_restore(run).enemies.first.preparingSpheres, isTrue);
      _wait(run, .32);
      expect(boss.preparingSpheres, isFalse);
      expect(boss.preparingBeam, isFalse);
      expect(run.finalBossPhase, LiteFinalBossPhase.intangible);
      expect(run.activeBeam, isNull);
      expect(run.projectiles, hasLength(LiteRun.finalSphereCount));
      for (final shot in run.projectiles) {
        expect(shot.fromEnemy, isTrue);
        expect(shot.kind, LiteProjectileKind.veyrthSphere);
        expect(
          shot.origin.distanceTo(boss.position),
          closeTo(LiteRun.finalSphereRingRadius, .0001),
        );
        expect(shot.damage, closeTo(16.52, .0001));
      }
      final east = run.projectiles.fold(
        0.0,
        (sum, shot) => sum + shot.direction.x,
      );
      final south = run.projectiles.fold(
        0.0,
        (sum, shot) => sum + shot.direction.y,
      );
      expect(east, closeTo(0, .0001));
      expect(south, closeTo(0, .0001));
    },
  );

  test(
    'a beam interrupted by an echo gives the sphere attack its own warning',
    () {
      final run = _reachFloor(LiteRun.finalStage)..obstacles.clear();
      final boss = run.enemies.single
        ..summonIn = 0
        ..windup = .02
        ..preparingBeam = true;
      _wait(run, .1);
      expect(run.activeBeam, isNull);
      expect(boss.preparingSpheres, isTrue);
      expect(run.projectiles, isEmpty);
      _wait(run, .42);
      expect(
        run.projectiles.where((p) => p.kind == LiteProjectileKind.veyrthSphere),
        hasLength(LiteRun.finalSphereCount),
      );
    },
  );
}
