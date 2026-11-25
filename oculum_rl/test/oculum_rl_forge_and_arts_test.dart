import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum_rl/game/oculum_lite_run.dart';

void wait(LiteRun run, double seconds) {
  for (var i = 0; i < (seconds * 120).ceil(); i++) {
    run.step(1 / 120);
  }
}

LiteRun restHub({
  int stage = 5,
  LiteHero hero = LiteHero.duplicatore,
  int players = 1,
}) =>
    LiteRun(
        seed: 251,
        hero: hero,
        weapon: LiteWeapon.spadaScudo,
        playerCount: players,
      )
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
      expect(solar.buyRestItem(LiteRestItem.artPlasma), isTrue);
      expect(solar.activeArt(), LiteLearnedArt.pattuglia);
      expect(solar.extraArt(), LiteLearnedArt.plasma);
      solar.restHub = false;
      expect(solar.useLearnedArt(const Point(16, 11), null, true), isTrue);
      expect(solar.useLearnedArt(const Point(16, 11)), isTrue);
    },
  );

  test(
    'the personal Grimorio gates purchases and retains old and new Arts',
    () {
      final run = restHub(stage: 11, players: 2);
      expect(run.enterRestHub(), isTrue);
      run.addCoopFighter(
        'luna',
        'Luna',
        LiteHero.cavaliereLunare,
        LiteWeapon.spadaScudo,
      );
      final lunar = run.coopFighter('luna')!..obser = 255;
      expect(run.restPrice(LiteRestItem.artPlasma), 96);
      expect(run.restPrice(LiteRestItem.artPlasma, fighter: lunar), 77);
      expect(run.restPrice(LiteRestItem.linfa, fighter: lunar), 21);
      expect(run.equipRestArt(LiteRestItem.artPlasma, fighter: lunar), isFalse);
      expect(run.buyRestItem(LiteRestItem.artPlasma, fighter: lunar), isTrue);
      expect(lunar.obser, 178);
      expect(lunar.supply.hasGrimoire, isTrue);
      expect(run.supply.hasGrimoire, isFalse);
      expect(run.restPrice(LiteRestItem.artBrace, fighter: lunar), 54);
      expect(run.buyRestItem(LiteRestItem.artBrace, fighter: lunar), isTrue);
      expect(run.buyRestItem(LiteRestItem.artPlasma, fighter: lunar), isFalse);
      expect(run.equipRestArt(LiteRestItem.artPlasma, fighter: lunar), isTrue);
      final restored = LiteRun.fromJson(run.toJson(includeEffects: true));
      final guest = restored.coopFighter('luna')!;
      expect(restored.devilArtTutor, run.devilArtTutor);
      expect(restored.activeArt(guest), LiteLearnedArt.lame);
      expect(restored.extraArt(guest), LiteLearnedArt.plasma);
      expect(
        restored.equipRestArt(LiteRestItem.artBrace, fighter: guest),
        isTrue,
      );
      expect(restored.extraArt(guest), LiteLearnedArt.brace);
      expect(restored.supply.hasGrimoire, isFalse);

      final old = LiteRestLoadout()..restore({'chosenArt': 'linfa'});
      expect(old.hasGrimoire, isTrue);
      expect(old.knowsArt(LiteLearnedArt.linfa), isTrue);
    },
  );

  test('Incisione adds braci without extra presses and shares the Ink cue', () {
    for (final (level, rank) in [(1, 1), (4, 2), (7, 3)]) {
      final run = restHub(stage: 11)..level = level;
      expect(run.enterRestHub(), isTrue);
      expect(run.buyRestItem(LiteRestItem.artBrace), isTrue);
      run.restHub = false;
      final before = run.oculum;
      expect(run.useLearnedArt(run.position + const Point(5, 0)), isTrue);
      expect(run.oculum, before - LiteLearnedArt.brace.cost);
      expect(run.projectiles, hasLength(rank + 1));
      expect(run.projectiles.map((shot) => shot.damage).toSet(), {
        8 + rank * 3,
      });
      expect(run.projectiles.map((shot) => shot.bounces).toSet(), {rank + 1});
      final copy = LiteRun.fromJson(run.toJson(includeEffects: true));
      final cue = copy.combatImpacts.singleWhere(
        (event) => event.target == LiteImpactTarget.artCast,
      );
      expect(cue.shield, rank);
      expect(copy.useLearnedArt(copy.position + const Point(5, 0)), isFalse);
    }
  });

  test('the devil is a rare deterministic tutor across floor seeds', () {
    final devilVisits = [
      for (var seed = 100; seed < 300; seed++)
        LiteRun(seed: seed, hero: LiteHero.duplicatore, weapon: LiteWeapon.arco)
          ..stage = 11,
    ].where((run) => run.devilArtTutor);
    expect(devilVisits.length, inInclusiveRange(8, 43));
  });

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
