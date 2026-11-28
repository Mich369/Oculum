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
  test('online art poses follow the actual caster and stay out of saves', () {
    final run = LiteRun(
      seed: 251,
      hero: LiteHero.duplicatore,
      weapon: LiteWeapon.guanti,
      playerCount: 2,
    )..enemies.clear();
    run.addCoopFighter('guest', 'Ospite', LiteHero.ashley, LiteWeapon.guanti);
    final guest = run.coopFighter('guest')!;
    run.supply.art = LiteLearnedArt.brace;
    guest.supply.art = LiteLearnedArt.plasma;
    const target = Point<double>(18, 11);
    expect(run.useLearnedArt(target), isTrue);
    expect(run.useLearnedArt(target, guest), isTrue);
    expect(run.useLearnedArt(target, guest), isFalse);
    final live = LiteRun.fromJson(run.toJson(includeEffects: true));
    final casts = live.combatImpacts.where(
      (hit) => hit.target == LiteImpactTarget.artCast,
    );
    expect(casts.map((hit) => hit.subjectId), [0, guest.id]);
    expect(casts.map((hit) => hit.life.toInt()), [
      LiteLearnedArt.brace.index,
      LiteLearnedArt.plasma.index,
    ]);
    expect(casts.map((hit) => hit.position), [run.position, guest.position]);
    final save = LiteRun.fromJson(run.toJson());
    expect(save.combatImpacts, isEmpty);
  });
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
    'vendor sells Art from the first rest hub and fixed Art stays fixed',
    () {
      final early = restHub();
      expect(early.enterRestHub(), isTrue);
      expect(early.buyRestItem(LiteRestItem.artPlasma), isTrue);
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
      expect(
        run.restPrice(LiteRestItem.artPlasma, fighter: lunar),
        lessThan(77),
      );
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

  test('two lessons improve the Art and survive a save', () {
    final run = restHub();
    expect(run.enterRestHub(), isTrue);
    for (var purchase = 0; purchase < 3; purchase++) {
      expect(run.buyRestItem(LiteRestItem.artPlasma), isTrue);
    }
    expect(run.buyRestItem(LiteRestItem.artPlasma), isFalse);

    final restored = LiteRun.fromJson(run.toJson())..restHub = false;
    expect(restored.activeArt(), LiteLearnedArt.plasma);
    expect(restored.supply.artTraining(LiteLearnedArt.plasma), 2);
    expect(
      restored.useLearnedArt(restored.position + const Point(5, 0)),
      isTrue,
    );
    expect(restored.projectiles, hasLength(3));
    expect(
      restored.supply.artCooldown,
      closeTo(LiteLearnedArt.plasma.cooldown * .80, .001),
    );
  });

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

  test(
    'forge pairs lower and upper rings and shields without replacing gear',
    () {
      var run = restHub();
      expect(run.enterRestHub(), isTrue);
      expect(run.buySignature(LiteWeapon.chakram), isTrue);
      expect(
        run.fuseWeapons(LiteWeapon.spadaScudo, LiteWeapon.chakram),
        isTrue,
      );
      expect(run.maxBlockResistance, 240);
      expect(run.weaponDamage, closeTo(14 * 1.15, .001));
      expect(
        run.fuseWeapons(LiteWeapon.spadaScudo, LiteWeapon.chakram),
        isFalse,
      );
      expect(run.buyRestItem(LiteRestItem.tempra), isTrue);
      run = LiteRun.fromJson(run.toJson())
        ..restHub = false
        ..stage = 0
        ..position = const Point(14, 11)
        ..obstacles.clear();
      expect(run.supply.forgeRank(LiteWeapon.spadaScudo), 1);
      expect(run.fusedWeapon(), LiteWeapon.chakram);
      expect(run.attack(const Point(20, 11)), isTrue);
      final rings = run.projectiles
          .where((shot) => shot.kind == LiteProjectileKind.chakram)
          .toList();
      expect(rings, hasLength(2));
      expect(rings.map((shot) => shot.chakramSide), [1, -1]);
      expect(rings.every((shot) => shot.chakramOrbit), isTrue);
      expect(rings.last.age, closeTo(-.30, .001));
      run.setAttackHeld(true);
      wait(run, .22);
      expect(rings.first.position, isNot(run.position));
      expect(rings.last.position, run.position);
      wait(run, 1.18);
      expect(run.projectiles, isEmpty);
      wait(run, .28);
      expect(
        run.projectiles.where(
          (shot) => shot.kind == LiteProjectileKind.chakram,
        ),
        hasLength(2),
      );
    },
  );

  test('a guest can buy, combine and save signature equipment', () {
    final run = restHub(stage: 0, players: 2);
    expect(
      run.addCoopFighter(
        'guest',
        'S',
        LiteHero.scostubandito,
        LiteWeapon.guanti,
      ),
      isTrue,
    );
    final guest = run.coopFighter('guest')!..obser = 500;
    run.restHub = true;
    expect(run.buySignature(LiteWeapon.vergaCorvina, guest), isTrue);
    expect(
      run.fuseWeapons(
        LiteWeapon.fucileScostubandito,
        LiteWeapon.vergaCorvina,
        guest,
      ),
      isTrue,
    );
    expect(run.buyRestItem(LiteRestItem.tempra, fighter: guest), isTrue);
    final copy = LiteRun.fromJson(run.toJson(includeEffects: true))
      ..restHub = false;
    final restored = copy.coopFighter('guest')!..cooldown = 0;
    copy.obstacles.clear();
    expect(restored.weapon, LiteWeapon.fucileScostubandito);
    expect(copy.fusedWeapon(restored), LiteWeapon.vergaCorvina);
    expect(restored.supply.forgeRank(restored.weapon), 1);
    expect(
      copy.setCoopControls(
        'guest',
        const Point(0, 0),
        const Point(14, 11),
        attack: true,
      ),
      isTrue,
    );
    copy.step(.016);
    expect(
      copy.projectiles.map((shot) => shot.kind),
      containsAll([
        LiteProjectileKind.rifleBullet,
        LiteProjectileKind.inkEmber,
      ]),
    );
  });

  test(
    'merchant interactions resolve from the approaching fighter position',
    () {
      final run = restHub(stage: 0, players: 2);
      expect(
        run.addCoopFighter('g', 'G', LiteHero.evasore, LiteWeapon.arco),
        isTrue,
      );
      final guest = run.coopFighter('g')!;
      run.restHub = true;
      run.stage = 5;
      run.position = LiteRestStation.forge.position + const Point(0, .9);
      guest.position = LiteRestStation.art.position;
      expect(run.restStationNearby(), LiteRestStation.forge);
      expect(run.restStationNearby(guest), LiteRestStation.art);
      guest.position = const Point(15, 20);
      expect(run.restStationNearby(guest), isNull);
    },
  );

  test('Lusier cards share one early attack against an elite', () {
    final run = restHub(stage: 2, hero: LiteHero.lusierTre)
      ..stageClear = false
      ..position = const Point(12, 11);
    final elite = LiteEnemy(
      818,
      LiteEnemyKind.eliteLunare,
      const Point(14, 11),
      240,
    )..stunned = 8;
    run.enemies.add(elite);
    expect(run.attack(elite.position), isTrue);
    expect(
      run.projectiles.where(
        (shot) => shot.kind == LiteProjectileKind.cartaLusier,
      ),
      hasLength(3),
    );
    expect(run.supply.lusierCards, 9);
    wait(run, .35);
    expect(elite.hp, closeTo(120, .001));
    wait(run, .77);
    expect(run.supply.lusierCards, 12);
    expect(run.callSolarRetinue(), isTrue);
    expect(
      run.clones.where(
        (ally) => ally.companion == LiteCompanion.guardiaDiLusier,
      ),
      hasLength(2),
    );
    expect(
      run.clones.where((ally) => ally.companion == LiteCompanion.eliteDiLusier),
      hasLength(1),
    );
  });

  test('Bunnys heals living enemies in battle and on defeat', () {
    final run = restHub(stage: 1, hero: LiteHero.lusierTre)
      ..stageClear = false
      ..position = const Point(12, 11);
    final wounded =
        LiteEnemy(919, LiteEnemyKind.eliteLunare, const Point(16, 11), 200)
          ..hp = 40
          ..stunned = 8;
    final bunny = LiteEnemy(920, LiteEnemyKind.bunnys, const Point(14, 11), 45)
      ..windup = .01;
    run.enemies.addAll([wounded, bunny]);
    run.step(.022);
    expect(wounded.hp, 50);
    expect(run.attack(bunny.position), isTrue);
    expect(bunny.hp, 0);
    expect(wounded.hp, 75);
  });

  test('the devil rejects reviving demons but the guest can help them', () {
    final run = restHub(stage: 0, hero: LiteHero.diavolo, players: 2);
    expect(
      run.addCoopFighter('g', 'G', LiteHero.evasore, LiteWeapon.arco),
      isTrue,
    );
    final guest = run.coopFighter('g')!;
    expect(run.useOpen(const Point(8, 11)), isTrue);
    expect(
      run.projectiles.where(
        (shot) => shot.kind == LiteProjectileKind.pattoFiamma,
      ),
      hasLength(5),
    );
    expect(
      run.clones.where((ally) => ally.companion?.isFlameDemon == true),
      hasLength(4),
    );
    final lesser = run.clones.first
      ..hp = 0
      ..downRemaining = 8;
    run.position = lesser.position + const Point(.5, 0);
    guest.position = lesser.position + const Point(0, .7);
    expect(run.beginRescue(), isFalse);
    expect(run.message, 'è una perdita di tempo è solo un inutile demone');
    expect(run.beginRescue(guest), isTrue);
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
