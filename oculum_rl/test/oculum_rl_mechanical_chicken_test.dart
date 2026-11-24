import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum_rl/game/oculum_lite_run.dart';
import 'package:oculum_rl/services/oculum_lite_saves.dart';
import 'package:oculum_rl/widgets/oculum_lite_appearance.dart';

const chicken = LiteHero.polloMeccanico;

LiteRun run({
  bool eligible = false,
  int players = 1,
  LiteHero hero = LiteHero.evasore,
}) {
  final world = LiteRun(
    seed: 20261124,
    hero: hero,
    weapon: LiteWeapon.guanti,
    allowMechanicalChicken: eligible,
    playerCount: players,
  );
  world.obstacles.clear();
  world.enemies.clear();
  return world;
}

Point<double> centerOfFlock(LiteRun world) {
  final chickens = world.fauna.where(
    (enemy) => enemy.kind == LiteEnemyKind.pollo,
  );
  return chickens.fold(
        const Point<double>(0, 0),
        (center, bird) => center + bird.position,
      ) *
      (1 / chickens.length);
}

void wait(LiteRun world, int tenths) {
  for (var i = 0; i < tenths; i++) {
    world.advanceFrame(.1);
  }
}

void main() {
  test(
    'the mechanical rooster uses its own sprite family, outside the infernals',
    () {
      expect(chicken.infernal, isFalse);
      expect(chicken.solar, isFalse);
      expect(LiteHero.values.where((hero) => hero.infernal), [
        LiteHero.demoneMinore,
        LiteHero.demoneIntermedio,
        LiteHero.demoneMaggiore,
        LiteHero.diavolo,
      ]);
    },
  );
  test(
    'a previous playable hero can equip a finish without replacing the run',
    () {
      final world = run(hero: LiteHero.ashley);
      final save = OculumLiteSaveSlot(
        run: world,
        name: 'Ashley',
        appearance: const OculumLiteAppearance(),
        attempt: 2,
        startingWeapon: world.weapon,
        startingBiome: world.biome,
      );
      expect(save.appearance.inkFinish, LiteInkFinish.canonica);
      final changed = save.withAppearance(
        save.appearance.copyWith(inkFinish: LiteInkFinish.patina),
      );
      expect(changed.run, same(world));
      final restored = OculumLiteSaveSlot.decode(changed.encode());
      expect(restored.appearance.inkFinish, LiteInkFinish.patina);
      expect(restored.run.hero, LiteHero.ashley);
      expect(restored.attempt, 2);
      expect(
        OculumLiteAppearance.fromJson({'inkFinish': 'missing'}).inkFinish,
        LiteInkFinish.canonica,
      );
    },
  );

  test(
    'prior Pollo unlock and ten uninterrupted peaceful seconds are required',
    () {
      final locked = run()..stageClear = true;
      locked.position = centerOfFlock(locked);
      wait(locked, 140);
      expect(locked.unlockedHeroesFor(locked.hero), isNot(contains(chicken)));

      final world = run(eligible: true)..stageClear = true;
      world.position = centerOfFlock(world);
      expect(
        world.fauna.where((bird) => bird.kind == LiteEnemyKind.pollo),
        hasLength(3),
      );
      wait(world, 50);
      world.advanceFrame(.08, move: const Point<double>(1, 0));
      world.position = centerOfFlock(world);
      wait(world, 99);
      expect(world.unlockedHeroesFor(world.hero), isNot(contains(chicken)));
      wait(world, 1);
      expect(world.unlockedHeroesFor(world.hero), contains(chicken));
      expect(
        OculumLiteProgress()
            .recordRun(LiteRun.fromJson(world.toJson()))
            .canPlay(chicken),
        isTrue,
      );
    },
  );

  test('harming wildlife in the run prevents the new unlock', () {
    final world = run(eligible: true)..stageClear = true;
    final bird = world.fauna.firstWhere(
      (enemy) => enemy.kind == LiteEnemyKind.pollo,
    );
    world.position = bird.position - const Point<double>(.45, 0);
    expect(world.attack(bird.position), isTrue);
    wait(world, 5);
    expect(world.provokedFaunaRooms, 1);
    world.position = centerOfFlock(world);
    wait(world, 120);
    expect(world.unlockedHeroesFor(world.hero), isNot(contains(chicken)));
  });

  test('a peaceful cooperative trial unlocks only for the eligible guest', () {
    final world = run(players: 2);
    final result = world.addCoopFighter(
      'guest',
      'Ospite',
      LiteHero.evasore,
      LiteWeapon.arco,
      allowMechanicalChicken: true,
    );
    expect(result, isTrue);
    world.stageClear = true;
    wait(world, 1);
    final guest = world.coopFighter('guest')!;
    guest.position = centerOfFlock(world);
    for (var i = 0; i < 100; i++) {
      world.setCoopControls(
        'guest',
        const Point<double>(0, 0),
        guest.position,
        attack: false,
      );
      world.advanceFrame(.1);
    }
    expect(world.unlockedHeroesFor(world.hero), isNot(contains(chicken)));
    final mirrored = LiteRun.fromJson(world.toJson());
    expect(
      mirrored.unlockedHeroesFor(guest.hero, guestAccount: 'guest'),
      contains(chicken),
    );
    expect(
      mirrored.unlockedHeroesFor(guest.hero, guestAccount: 'other'),
      isNot(contains(chicken)),
    );
  });

  test(
    'three ray projectiles turn toward a live opponent and survive a save',
    () {
      final world = run(hero: chicken)..position = const Point<double>(10, 10);
      world.enemies.add(
        LiteEnemy(9001, LiteEnemyKind.pollo, const Point<double>(16, 14), 150),
      );
      expect(world.attack(const Point<double>(21, 10)), isTrue);
      final rays = world.projectiles
          .where((shot) => shot.kind == LiteProjectileKind.posteaRay)
          .toList();
      expect(rays, hasLength(3));
      final heading = rays[1].direction.y;
      world.advanceFrame(.12);
      expect(rays[1].direction.y, greaterThan(heading));
      expect(
        LiteRun.fromJson(world.toJson()).projectiles
            .where((shot) => shot.kind == LiteProjectileKind.posteaRay),
        hasLength(3),
      );
    },
  );

  test('a ray triggers the owner’s planted egg before the normal fuse', () {
    final world = run(hero: chicken)..position = const Point<double>(15, 11);
    expect(world.special(const Point<double>(23, 11)), isTrue);
    wait(world, 5);
    final egg = world.projectiles[1];
    expect(egg.eggFuse, isNotNull);
    world.position = egg.position + const Point<double>(2, 0);
    expect(world.attack(egg.position), isTrue);
    wait(world, 2);
    expect(world.projectiles, isNot(contains(egg)));
    expect(
      world.combatImpacts.any(
        (impact) => impact.target == LiteImpactTarget.explosion,
      ),
      isTrue,
    );
  });

  test('Postea eggs travel farther and deal more damage than regular eggs', () {
    final organic = run(hero: LiteHero.pollo)
      ..position = const Point<double>(15, 11);
    final machine = run(hero: chicken)..position = organic.position;
    const target = Point<double>(23, 11);
    expect(organic.special(target), isTrue);
    expect(machine.special(target), isTrue);
    expect(machine.projectiles, hasLength(3));
    for (final egg in machine.projectiles) {
      expect(egg.kind, LiteProjectileKind.posteaEgg);
      expect(egg.direction.x, isNegative);
      expect(egg.remaining, greaterThan(organic.projectiles.first.remaining));
      expect(egg.damage, greaterThan(organic.projectiles.first.damage));
    }
    wait(machine, 5);
    expect(machine.projectiles.every((egg) => egg.eggFuse != null), isTrue);
    wait(machine, 10);
    expect(machine.projectiles, isEmpty);
  });
}
