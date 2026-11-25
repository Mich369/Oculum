import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum_rl/game/oculum_lite_run.dart';

void wait(LiteRun run, double seconds) {
  for (var i = 0; i < (seconds * 120).ceil(); i++) {
    run.step(1 / 120);
  }
}

LiteRun restHub({int stage = 5, LiteHero hero = LiteHero.duplicatore}) =>
    LiteRun(seed: 251, hero: hero, weapon: LiteWeapon.spadaScudo)
      ..obstacles.clear()
      ..enemies.clear()
      ..stage = stage
      ..stageClear = true
      ..position = const Point(30, 11)
      ..obser = 1500;

void main() {
  test('weapon tempra stops at 12 and doubles the iron riposte reach', () {
    final run = restHub();
    expect(run.enterRestHub(), isTrue);
    final before = run.weaponDamage;
    final beforeBalance = run.obser;
    for (var rank = 1; rank <= 12; rank++) {
      expect(run.buyRestItem(LiteRestItem.tempra), isTrue);
      expect(run.supply.forgeRank(run.weapon), rank);
    }
    expect(run.weaponDamage, closeTo(before * 1.48, 1e-8));
    expect(run.buyRestItem(LiteRestItem.tempra), isFalse);
    expect(run.obser, beforeBalance - 534);
    final restored = LiteRun.fromJson(run.toJson());
    expect(restored.supply.forgeRank(LiteWeapon.spadaScudo), 12);
    expect(restored.supply.forgeRank(LiteWeapon.arco), 0);
    restored
      ..restHub = false
      ..stageClear = false
      ..position = const Point(4, 11);
    final distant = LiteEnemy(
      901,
      LiteEnemyKind.slime,
      const Point(9.5, 11),
      500,
    );
    final behind = LiteEnemy(
      902,
      LiteEnemyKind.slime,
      const Point(2.6, 11),
      500,
    );
    restored.enemies.addAll([distant, behind]);
    expect(restored.useWeaponArt(distant.position), isTrue);
    expect(distant.hp, lessThan(500));
    expect(distant.position.x, closeTo(21.5, .25));
    expect(behind.hp, 500);
  });

  test(
    'vendor sells Art after the second rest hub and fixed Art stays fixed',
    () {
      final early = restHub();
      expect(early.enterRestHub(), isTrue);
      expect(early.buyRestItem(LiteRestItem.artPlasma), isFalse);
      final run = restHub(stage: 11);
      expect(run.enterRestHub(), isTrue);
      expect(run.buyRestItem(LiteRestItem.artPlasma), isTrue);
      expect(run.buyRestItem(LiteRestItem.artCorruzione), isFalse);
      final restored = LiteRun.fromJson(run.toJson())..restHub = false;
      expect(restored.activeArt(), LiteLearnedArt.plasma);
      expect(restored.useLearnedArt(const Point(17, 11)), isTrue);
      expect(restored.projectiles.single.kind, LiteProjectileKind.plasma);
      expect(restored.useLearnedArt(const Point(17, 11)), isFalse);
      final solar = restHub(stage: 11, hero: LiteHero.guardiaSolare);
      expect(solar.enterRestHub(), isTrue);
      expect(solar.activeArt(), LiteLearnedArt.pattuglia);
      expect(solar.buyRestItem(LiteRestItem.artPlasma), isFalse);
    },
  );

  test('a potion heals only companions of its living consumer', () {
    final run = restHub()
      ..shopOpen = true
      ..hp = 50;
    final own = LiteClone(
      const Point(4, 12),
      15,
      LiteWeapon.arco,
      id: 994,
      maxHp: 55,
      companion: LiteCompanion.vedetta,
    );
    final others = LiteClone(
      const Point(4, 13),
      15,
      LiteWeapon.arco,
      id: 995,
      maxHp: 55,
      ownerId: 5,
      companion: LiteCompanion.vedetta,
    );
    run.clones.addAll([own, others]);
    expect(run.buyPotion(), isTrue);
    expect(own.hp, closeTo(15 + (run.hp - 50) * .30, .001));
    expect(others.hp, 15);
  });

  test('Baghest grants one challenge and his grip survives a save', () {
    final run =
        LiteRun(
            seed: 251,
            hero: LiteHero.duplicatore,
            weapon: LiteWeapon.guanti,
            biome: LiteBiome.dungeon,
          )
          ..stage = 8
          ..stageClear = true
          ..position = LiteRun.secretCache
          ..achievements.add('sala-segreta:8')
          ..obstacles.clear()
          ..enemies.clear();
    expect(run.challengeBaghest(), isTrue);
    expect(run.challengeBaghest(), isFalse);
    final boss = run.enemies.first;
    expect(boss.kind, LiteEnemyKind.baghest);
    run.position = const Point(5, 11);
    boss
      ..position = const Point(9, 11)
      ..attackTarget = run.position
      ..windup = .02
      ..combatCycle = 1;
    wait(run, .04);
    expect(run.gripRemaining(), 5);
    expect(run.attack(boss.position), isFalse);
    final restored = LiteRun.fromJson(run.toJson());
    expect(restored.gripRemaining(), 5);
    for (var remaining = 4; remaining >= 0; remaining--) {
      expect(restored.shakeRedGrip(), isTrue);
      expect(restored.gripRemaining(), remaining);
    }
    expect(restored.shakeRedGrip(), isFalse);
  });
}
