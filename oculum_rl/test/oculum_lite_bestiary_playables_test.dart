import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum_rl/game/oculum_lite_run.dart';
import 'package:oculum_rl/services/oculum_lite_saves.dart';

const feet = Point<double>(14, 10);
const east = Point<double>(1, 0);
const still = Point<double>(0, 0);

LiteRun forest(LiteHero hero, {int players = 1, bool explore = true}) =>
    LiteRun(
      seed: 9751,
      hero: hero,
      weapon: LiteWeapon.spadaScudo,
      biome: LiteBiome.foresta,
      playerCount: players,
      explorationRoutes: explore,
    );

LiteRun arena(LiteHero hero, {int players = 1}) =>
    forest(hero, players: players, explore: false)
      ..position = feet
      ..fauna.clear()
      ..enemies.clear()
      ..obstacles.clear()
      ..loot.clear();

void main() {
  test('the base Bell Fly is in the Forest and the Armadillo is optional', () {
    final run = forest(LiteHero.evasore);
    expect(
      run.enemies.any((enemy) => enemy.kind == LiteEnemyKind.moscaCampana),
      isTrue,
    );
    final armadillo = run.fauna.singleWhere(
      (animal) => animal.kind == LiteEnemyKind.armadilloCorazzato,
    );
    expect(run.enemies, isNot(contains(armadillo)));
    final copy = LiteRun.fromJson(run.toJson());
    expect(
      copy.fauna.map((animal) => animal.kind),
      contains(LiteEnemyKind.armadilloCorazzato),
    );

    // Slow steps towards the animal result in retreat. Leaving does not hurt it
    // or provoke fauna, and the ordinary chamber check excludes it.
    run.obstacles.clear();
    run.position = armadillo.position - const Point(1.65, 0);
    final start = armadillo.position;
    final hp = run.hp;
    run.step(.08, move: east, walk: true);
    expect(armadillo.position.x, greaterThan(start.x));
    expect(armadillo.windup, 0);
    expect(run.hp, hp);
    expect(run.provokedFaunaRooms, 0);
    run.position = const Point(27, 11);
    run.step(.06, move: east);
    expect(armadillo.windup, 0);
    expect(armadillo.hp, armadillo.maxHp);
  });

  test('the territorial Armadillo defends itself after a strike', () {
    final run = forest(LiteHero.evasore)
      ..enemies.clear()
      ..obstacles.clear();
    final armadillo = run.fauna.singleWhere(
      (animal) => animal.kind == LiteEnemyKind.armadilloCorazzato,
    );
    run.position = armadillo.position - const Point(1.85, 0);
    expect(run.attack(armadillo.position), isTrue);
    expect(armadillo.hp, lessThan(armadillo.maxHp));
    expect(run.provokedFaunaRooms, 1);
    for (var tick = 0; tick < 36 && armadillo.windup == 0; tick++) {
      run.step(.025);
    }
    expect(armadillo.windup, greaterThan(0));
    run.position = const Point(27, 11);
    run.step(.08);
    expect(armadillo.windup, 0);
  });

  test('each kill achievement belongs to the finishing side and persists', () {
    final run = arena(LiteHero.evasore, players: 2);
    run.addCoopFighter('qa', 'Ospite', LiteHero.evasore, LiteWeapon.spadaScudo);
    final guest = run.coopFighter('qa')!
      ..position = const Point(14, 14)
      ..cooldown = 0;
    final fly = LiteEnemy(
      1900,
      LiteEnemyKind.moscaCampana,
      feet + east * 1.8,
      1,
    );
    final animal = LiteEnemy(
      1901,
      LiteEnemyKind.armadilloCorazzato,
      guest.position + east * 1.9,
      1,
    );
    run.enemies.add(fly);
    run.fauna.add(animal);
    expect(run.attack(fly.position), isTrue);
    expect(
      run.setCoopControls('qa', still, animal.position, attack: true),
      isTrue,
    );
    run.step(.08);
    final saved = LiteRun.fromJson(run.toJson());
    final host = saved.unlockedHeroesFor(run.hero);
    final remote = saved.unlockedHeroesFor(guest.hero, guestAccount: 'qa');
    expect(host, contains(LiteHero.moscaCampana));
    expect(host, isNot(contains(LiteHero.armadilloCorazzato)));
    expect(remote, contains(LiteHero.armadilloCorazzato));
    expect(remote, isNot(contains(LiteHero.moscaCampana)));
    final profile = OculumLiteProgress().recordRun(saved);
    expect(
      OculumLiteProgress.decode(profile.encode())
          .canPlay(LiteHero.moscaCampana),
      isTrue,
    );
  });

  for (final hero in [LiteHero.moscaCampana, LiteHero.armadilloCorazzato]) {
    test(
      '${hero.name} starts, fights, reloads and forges without a carried weapon',
      () {
        final run = arena(hero);
        expect(run.weapon, LiteWeapon.armamentoNaturale);
        final near = LiteEnemy(1902, LiteEnemyKind.slime, feet + east * 2, 300)
          ..cooldown = 10;
        final covered = LiteEnemy(
          1903,
          LiteEnemyKind.slime,
          feet + east * 3.4,
          300,
        )..cooldown = 10;
        run.enemies.addAll([near, covered]);
        run.obstacles.add(LiteObstacle(16.7, 8.4, .3, 4));
        expect(run.attack(near.position), isTrue);
        expect(near.hp, lessThan(near.maxHp));
        expect(covered.hp, covered.maxHp);
        expect(run.useWeaponArt(near.position), isFalse);
        expect(run.projectiles, isEmpty);
        final saved = LiteRun.fromJson(run.toJson());
        expect(saved.weapon, LiteWeapon.armamentoNaturale);
        saved
          ..restHub = true
          ..obser = 500;
        expect(saved.buyRestItem(LiteRestItem.picca), isFalse);
        expect(saved.buySignature(LiteWeapon.bobinaPostea), isFalse);
      },
    );
  }

  test('Bell Fly Open staggers common opponents more than elite and boss', () {
    final run = arena(LiteHero.moscaCampana);
    final normal = LiteEnemy(1904, LiteEnemyKind.slime, feet + east * 4, 400);
    final elite = LiteEnemy(
      1905,
      LiteEnemyKind.costrutto,
      const Point(18, 9),
      500,
    );
    final boss = LiteEnemy(
      1906,
      LiteEnemyKind.baghest,
      const Point(18, 12),
      800,
    );
    run.enemies.addAll([normal, elite, boss]);
    expect(run.useOpen(normal.position), isTrue);
    expect(normal.stunned, greaterThan(1.3));
    expect(elite.stunned, closeTo(.45, .001));
    expect(boss.stunned, closeTo(.22, .001));
    expect(run.projectiles, isEmpty);
    final replica = LiteRun.fromJson(run.toJson(includeEffects: true));
    expect(
      replica.combatImpacts.any(
        (hit) => hit.target == LiteImpactTarget.bestiaryCast,
      ),
      isTrue,
    );
  });

  test('guest armadillo starts a continuous roll and shields only itself', () {
    final run = arena(LiteHero.evasore, players: 2);
    run.addCoopFighter(
      'guest',
      'Ospite',
      LiteHero.armadilloCorazzato,
      LiteWeapon.arco,
    );
    final guest = run.coopFighter('guest')!..position = const Point(14, 14);
    final at = guest.position;
    expect(guest.weapon, LiteWeapon.armamentoNaturale);
    final hostShield = run.shield;
    final foe = LiteEnemy(1907, LiteEnemyKind.slime, at + east * 6.2, 400)
      ..cooldown = 10;
    run.enemies.add(foe);
    expect(
      run.setCoopControls(
        'guest',
        still,
        foe.position,
        attack: false,
        open: true,
      ),
      isTrue,
    );
    expect(guest.position, at);
    expect(guest.shield, greaterThanOrEqualTo(20));
    expect(run.shield, hostShield);
    expect(run.openProtects(guest.id), isTrue);
    expect(run.openProtects(0), isFalse);
    expect(foe.hp, lessThan(400));
    run.advanceFrame(.20);
    expect(guest.position.x, inExclusiveRange(at.x, at.x + 5.1));
  });
}
