import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum_rl/game/oculum_lite_run.dart';
import 'package:oculum_rl/services/oculum_lite_saves.dart';

LiteRun field({
  LiteHero hero = LiteHero.duplicatore,
  LiteDifficulty difficulty = LiteDifficulty.medio,
  LiteWeapon weapon = LiteWeapon.spadaScudo,
  int party = 1,
}) =>
    LiteRun(
        seed: 251,
        hero: hero,
        weapon: weapon,
        difficulty: difficulty,
        playerCount: party,
        biome: LiteBiome.campo,
      )
      ..obstacles.clear()
      ..enemies.clear()
      ..fauna.clear()
      ..stage = 1;

void main() {
  test('all 35 milestones are unique and higher difficulty unlocks cumulative rewards', () {
    expect(liteMilestoneRewards.length, 35);
    expect(
      liteMilestoneRewards
          .map((reward) => reward.hero ?? reward.weapon)
          .toSet(),
      hasLength(35),
    );
    final run = field(difficulty: LiteDifficulty.difficile)..stage = 9;
    var profile = const OculumLiteProgress().recordRun(run);
    expect(profile.canPlay(LiteHero.pysciwarden), isTrue);
    expect(profile.canPlay(LiteHero.lusierTre), isFalse);
    expect(profile.startingWeapons.contains(LiteWeapon.orbita1), isFalse);
    run.stageClear = true;
    profile = profile.recordRun(run);
    expect(profile.startingWeapons.where((item) => item.isMilestone), [
      LiteWeapon.orbita1,
      LiteWeapon.orbita2,
      LiteWeapon.orbita3,
      LiteWeapon.orbita4,
    ]);
    final restored = OculumLiteProgress.decode(profile.encode());
    expect(restored.startingWeapons, profile.startingWeapons);
    final ancient = OculumLiteProgress.decode('{"schema":1,"floor":15}');
    expect(ancient.startingWeapons.where((item) => item.isMilestone), isEmpty);
  });

  test('side rooms retain the completed floor and the third act continues the count', () {
    final run = field()
      ..stage = 11
      ..stageClear = true;
    expect(run.milestoneFloors, 12);
    run
      ..restHub = true
      ..stageClear = false;
    expect(run.milestoneFloors, 12);
    run
      ..restHub = false
      ..thirdRoom = 10
      ..stage = LiteRun.finalStage;
    expect(run.milestoneFloors, 34);
    run.stageClear = true;
    expect(run.milestoneFloors, 35);
    expect(LiteRun.fromJson(run.toJson()).milestoneFloors, 35);
  });

  test('wolves are neutral for others and never gate a cleared room', () {
    final run = field();
    final wolf = LiteEnemy(
      851,
      LiteEnemyKind.lupoLunare,
      const Point(8, 11),
      42,
    );
    run.enemies.add(wolf);
    run.step(.03);
    expect(run.enemies, isEmpty);
    expect(run.fauna, contains(wolf));
    expect(run.stageClear, isTrue);
    expect(run.clones, isEmpty);
    final reloaded = LiteRun.fromJson(run.toJson());
    expect(reloaded.fauna.single.kind, LiteEnemyKind.lupoLunare);
  });

  test('an Orea floor spawns optional Orbryx and saves its neutral status', () {
    final run = field()
      ..stage = 0
      ..stageClear = true;
    run.position = run.portalPosition;
    expect(run.advance(LiteBiome.orea), isTrue);
    expect(
      run.fauna.any((animal) => animal.kind == LiteEnemyKind.orbryx),
      isTrue,
    );
    final restored = LiteRun.fromJson(run.toJson());
    expect(
      restored.fauna.any((animal) => animal.kind == LiteEnemyKind.orbryx),
      isTrue,
    );
  });

  test('the unlocked weapon works from a guest seat', () {
    final run = LiteRun(
      seed: 251,
      hero: LiteHero.duplicatore,
      weapon: LiteWeapon.spadaScudo,
      playerCount: 2,
    )..enemies.clear();
    expect(
      run.addCoopFighter(
        'guest',
        'Ospite',
        LiteHero.duplicatore,
        LiteWeapon.segugio5,
      ),
      isTrue,
    );
    final guest = run.coopFighter('guest')!;
    expect(run.useWeaponArt(const Point(9, 11), guest), isTrue);
    expect(run.projectiles.length, 2);
    expect(
      run.projectiles.every((shot) => shot.sourceCloneId == guest.id),
      isTrue,
    );
    final clone = LiteRun.fromJson(run.toJson(includeEffects: true));
    expect(clone.coopFighters.single.weapon, LiteWeapon.segugio5);
    expect(clone.combatImpacts.single.subjectId, guest.id);
  });

  test(
    'solar allegiance turns wolves hostile even with a lunar hero present',
    () {
      final run =
          LiteRun(
              seed: 251,
              hero: LiteHero.cavaliereLunare,
              weapon: LiteWeapon.spadaScudo,
              playerCount: 2,
            )
            ..enemies.clear()
            ..fauna.clear();
      expect(
        run.addCoopFighter(
          'sun',
          'Solar',
          LiteHero.guardiaSolare,
          LiteWeapon.spadaScudo,
        ),
        isTrue,
      );
      final wolf = LiteEnemy(
        851,
        LiteEnemyKind.lupoLunare,
        const Point(8, 11),
        42,
      );
      run.fauna.add(wolf);
      run.step(.03);
      expect(run.enemies, contains(wolf));
      expect(run.fauna, isEmpty);
      expect(run.clones, isEmpty);
      expect(run.stageClear, isFalse);
    },
  );

  test('lunar allies and existing summons gain levels without healing their wounds', () {
    final run = field(hero: LiteHero.lupoDiVaitern)..level = 5;
    run.fauna.add(
      LiteEnemy(851, LiteEnemyKind.lupoLunare, const Point(8, 11), 42)..hp = 21,
    );
    final summon = LiteClone(
      const Point(7, 11),
      8,
      LiteWeapon.arco,
      companion: LiteCompanion.scheletroArco,
      summoned: true,
      expiresAfter: 15,
      maxHp: 16,
      id: 852,
    );
    run.clones.add(summon);
    run.step(.025);
    expect(run.fauna, isEmpty);
    expect(run.clones, hasLength(2));
    for (final ally in run.clones) {
      expect(ally.level, 5);
      expect(ally.hp / ally.maxHp, closeTo(.5, .00001));
    }
    final copy = LiteRun.fromJson(run.toJson());
    expect(copy.clones.map((ally) => ally.level), [5, 5]);
    expect(copy.clones.first.maxHp, closeTo(16 * 1.24, .00001));
    copy.level = 6;
    copy.step(.025);
    expect(copy.clones.first.level, 6);
    expect(copy.clones.first.hp / copy.clones.first.maxHp, closeTo(.5, .00001));
  });

  test(
    'each new hero executes talent and Open with its own saved identity',
    () {
      for (final hero in liteMilestoneHeirs) {
        final run = field(hero: hero);
        const target = Point<double>(6, 11);
        run.enemies.add(
          LiteEnemy(717, LiteEnemyKind.scostubandito, target, 750)..stunned = 6,
        );
        expect(run.special(target), isTrue, reason: hero.name);
        expect(run.useOpen(target), isTrue, reason: hero.name);
        final cues = run.combatImpacts.where(
          (hit) => hit.target == LiteImpactTarget.milestoneCast,
        );
        expect(cues, hasLength(2), reason: hero.name);
        expect(LiteRun.fromJson(run.toJson()).hero, hero);
      }
    },
  );

  test('every relic form has a working technique and a matching cooperative effect', () {
    for (final item in LiteWeapon.values.where(
      (weapon) => weapon.isMilestone,
    )) {
      final run = field(weapon: item);
      const target = Point<double>(8, 11);
      expect(run.useWeaponArt(target), isTrue, reason: item.label);
      expect(run.useWeaponArt(target), isFalse);
      final copy = LiteRun.fromJson(run.toJson(includeEffects: true));
      expect(copy.weapon, item);
      final cue = copy.combatImpacts.singleWhere(
        (hit) => hit.target == LiteImpactTarget.milestoneCast,
      );
      expect(cue.life, item.relicFamily!.index.toDouble());
      expect(cue.shield, item.form.toDouble());
      expect(run.attack(target), isTrue, reason: item.label);
    }
  });
}
