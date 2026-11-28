import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum_rl/game/oculum_lite_run.dart';

LiteRun scene({LiteHero hero = LiteHero.duplicatore, int seed = 251}) =>
    LiteRun(seed: seed, hero: hero, weapon: LiteWeapon.spadaScudo)
      ..enemies.clear()
      ..fauna.clear()
      ..obstacles.clear()
      ..position = const Point(12, 11);

void advance(
  LiteRun run,
  double seconds, {
  Point<double> move = const Point(0, 0),
}) {
  for (var i = 0; i < (seconds * 120).round(); i++) {
    run.advanceFrame(1 / 120, move: move);
  }
}

void main() {
  test('there are two harmless pups and each defeat hastens the miniboss', () {
    final run = scene()
      ..stage = LiteRun.secondActEntranceFloor
      ..restHub = true
      ..stageClear = true;
    run.position = run.portalPosition;
    expect(run.enterSecondAct(LiteRealm.caramella), isTrue);
    run
      ..stageClear = true
      ..position = run.portalPosition;
    expect(run.advanceActTwo(), isTrue);
    run.obstacles.clear();
    final boss = run.enemies.singleWhere(
      (enemy) => enemy.kind == LiteEnemyKind.divoramitu,
    );
    final pups = run.enemies
        .where((enemy) => enemy.pupParent == boss.id)
        .toList();
    expect(pups, hasLength(2));
    expect(boss.hitboxHalfLength, greaterThan(1.5));
    run.enemies.retainWhere((enemy) => enemy == boss || pups.contains(enemy));
    boss.burrow!.delay = 100;
    for (final pup in pups) {
      pup.position = const Point(13, 11);
      pup.hp = 1;
    }
    run.position = const Point(12, 11);
    final hp = run.hp;
    advance(run, .15);
    expect(run.hp, hp);
    expect(pups.first.windup, 0);
    for (final (index, pup) in pups.indexed) {
      pups.where((other) => other != pup && other.hp > 0).forEach((other) {
        other.position = const Point(6, 6);
      });
      pup.position = const Point(13, 11);
      expect(run.attack(pup.position), isTrue);
      expect(pup.hp, 0);
      expect(boss.burrowSpeed, closeTo(2.3 + .3 * (index + 1), 1e-9));
      advance(run, .55);
    }
    boss
      ..position = const Point(13, 11)
      ..hp = 1;
    boss.burrow!.leap = .1;
    expect(run.attack(boss.position), isTrue);
    expect(run.discoveredPets, contains(LiteCompanion.divoramituMini));
    expect(
      run.clones.where(
        (clone) => clone.companion == LiteCompanion.divoramituMini,
      ),
      hasLength(1),
    );
  });

  test(
    'the pet casts on a real ten second cooldown and its field survives a save',
    () {
      final run = scene()..stageClear = true;
      expect(run.bringStarterPet(LiteCompanion.divoramituMini), isTrue);
      final pet = run.clones.single;
      final foe = LiteEnemy(
        990,
        LiteEnemyKind.costrutto,
        const Point(15, 11),
        10000,
      )..stunned = 20;
      run.enemies.add(foe);
      advance(run, .20);
      expect(pet.burrowing, isTrue);
      final resumed = LiteRun.fromJson(run.toJson(includeEffects: true));
      expect(resumed.clones.single.burrowing, isTrue);
      expect(
        resumed.clones.single.burrowCooldown,
        closeTo(pet.burrowCooldown, .001),
      );
      advance(run, .50);
      final field = run.divoramituFields.single;
      expect(foe.hp, lessThan(foe.maxHp));
      expect(pet.burrowing, isFalse);
      final afterImpact = foe.hp;
      advance(run, .65);
      expect(foe.hp, lessThan(afterImpact));

      final snapshot = run.toJson(includeEffects: true);
      final without = LiteRun.fromJson(
        {...snapshot}..remove('divoramituFields'),
      );
      final withField = LiteRun.fromJson(snapshot);
      for (final world in [without, withField]) {
        world.clones.clear();
        world.position = field.center;
      }
      expect(
        withField.divoramituFields.single.remaining,
        closeTo(field.remaining, 1e-8),
      );
      expect(without.attack(field.center + const Point(1, 0)), isTrue);
      expect(withField.attack(field.center + const Point(1, 0)), isTrue);
      final base = without.attackCooldown;
      advance(without, .10, move: const Point(1, 0));
      advance(withField, .10, move: const Point(1, 0));
      expect(
        base - withField.attackCooldown,
        closeTo(2 * (base - without.attackCooldown), .005),
      );
      expect(
        withField.position.distanceTo(field.center),
        closeTo(1.40 * without.position.distanceTo(field.center), .02),
      );

      advance(run, 8.55);
      expect(run.divoramituFields, isEmpty);
      expect(pet.burrowCooldown, greaterThan(0));
      advance(run, .85);
      expect(run.divoramituFields, hasLength(1));
    },
  );

  test('Bunnys cures an injured ally and cannot be rescued or brought back by the King', () {
    final run = scene(hero: LiteHero.reGoblin)..stageClear = true;
    final hp = run.hp = run.maxHp * .45;
    expect(run.bringStarterPet(LiteCompanion.bunnys), isTrue);
    final pet = run.clones.single;
    advance(run, .9);
    expect(run.hp, closeTo(hp * 1.25, 1e-8));
    // It dies from a real hostile projectile aimed apart from the King.
    pet.position = run.position + const Point(0, 3.5);
    run.projectiles.add(
      LiteProjectile(
        position: pet.position - const Point(.6, 0),
        direction: const Point(1, 0),
        speed: 17,
        remaining: 1,
        damage: 80,
        fromEnemy: true,
      ),
    );
    final beforeDeath = run.hp;
    advance(run, .065);
    expect(run.hp, closeTo(beforeDeath * 1.5, .001));
    expect(pet.hp, 0);
    expect(run.clones, isEmpty);
    expect(run.fallenAllyNearby, isNull);
    expect(run.royalCall(), isFalse);
  });

  test('starter picks only unlocked local pets and the trader never grants an achievement', () {
    final discovered = {
      LiteCompanion.bunnys,
      LiteCompanion.orbietto,
      LiteCompanion.lumin,
    };
    expect(
      LitePets.starterOffers(discovered, LiteBiome.foresta, 7).first,
      LiteCompanion.bunnys,
    );
    expect(
      LitePets.starterOffers(discovered, LiteBiome.foresta, 7).toSet(),
      discovered,
    );
    LiteRun? found;
    for (var seed = 1; seed < 100; seed++) {
      final world = scene(seed: seed)
        ..stageClear = true
        ..restHub = true;
      if (world.petTraderPosition != null) {
        found = world;
        break;
      }
    }
    final run = found!;
    expect(run.bringStarterPet(LiteCompanion.bunnys), isTrue);
    expect(run.bringStarterPet(LiteCompanion.lumin), isFalse);
    run.position = run.petTraderPosition!;
    final offer = run.petTradeOffers().first;
    final giveId = run.clones.single.id;
    expect(run.tradePet(giveId, offer), isTrue);
    expect(run.clones.single.companion, offer);
    expect(run.discoveredPets, isEmpty);
    expect(LiteRun.fromJson(run.toJson()).petTradeOffers(), isEmpty);
  });

  test('the smith sends enemies back and his Open summons 20 fragile unhealable weapons', () {
    final run = scene(hero: LiteHero.fabbro)..stageClear = true;
    expect(run.weapon, LiteWeapon.martelloForgia);
    final left = LiteEnemy(
      880,
      LiteEnemyKind.costrutto,
      const Point(9, 11),
      3000,
    );
    final right = LiteEnemy(
      881,
      LiteEnemyKind.costrutto,
      const Point(15, 11),
      3000,
    );
    run.enemies.addAll([left, right]);
    expect(run.special(run.position + const Point(1, 0)), isTrue);
    expect(left.position.x, lessThan(9));
    expect(right.position.x, greaterThan(15));
    expect(
      run.combatImpacts.where(
        (impact) => impact.target == LiteImpactTarget.fissure,
      ),
      hasLength(8),
    );

    expect(run.useOpen(run.position + const Point(1, 0)), isTrue);
    final weapons = run.clones.where((clone) => clone.forgedWeapon);
    expect(weapons, hasLength(20));
    expect(
      weapons.every(
        (arm) => arm.hp == 7 && arm.forgedProtected && !arm.canBeRevived,
      ),
      isTrue,
    );
    final restored = LiteRun.fromJson(run.toJson(includeEffects: true));
    expect(restored.clones.where((arm) => arm.forgedProtected), hasLength(20));
    restored.enemies.clear();
    for (var i = 0; i < 6; i++) {
      restored.advanceFrame(LiteOpenScene.duration / 6);
    }
    expect(restored.clones.every((arm) => arm.forgedProtected), isTrue);
    advance(restored, 2.01);
    expect(restored.clones.every((arm) => !arm.forgedProtected), isTrue);
  });

  test('the rare vampire pact deducts maximum HP once across saves', () {
    final run = Iterable.generate(
      1600,
      (seed) => scene(seed: seed)
        ..stage = 4
        ..stageClear = true,
    ).firstWhere((world) => world.vampirePosition != null);
    final original = run.maxHp;
    run
      ..position = run.vampirePosition!
      ..hp = original * .8;
    expect(run.acceptVampirePact(LiteVampirePact.ferocia), isTrue);
    expect(run.maxHp, closeTo(original * .65, 1e-8));
    expect(run.hp, closeTo(run.maxHp * .8, 1e-8));
    expect(run.acceptVampirePact(LiteVampirePact.fame), isFalse);
    final restored = LiteRun.fromJson(run.toJson());
    expect(restored.supply.vampirePact, LiteVampirePact.ferocia);
    expect(restored.maxHp, run.maxHp);
  });
}
