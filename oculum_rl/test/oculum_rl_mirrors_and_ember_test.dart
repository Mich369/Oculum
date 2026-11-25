import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum_rl/game/oculum_lite_run.dart';

void main() {
  test('each cooperative fighter gets their own Light and Shadow kit', () {
    final run = LiteRun(
      seed: 251,
      hero: LiteHero.pyrel,
      weapon: LiteWeapon.scettro,
      playerCount: 3,
    );
    expect(
      run.addCoopFighter(
        'a',
        'Cavaliere',
        LiteHero.cavaliereLunare,
        LiteWeapon.spadaScudo,
      ),
      isTrue,
    );
    expect(
      run.addCoopFighter('b', 'Ashley', LiteHero.ashley, LiteWeapon.guanti),
      isTrue,
    );
    final knight = run.coopFighter('a')!;
    final ashley = run.coopFighter('b')!..supply.art = LiteLearnedArt.plasma;
    run.supply.art = LiteLearnedArt.linfa;
    final seen = <LiteEnemyKind>{};
    for (final floor in [3, 9]) {
      run
        ..stage = floor - 1
        ..stageClear = true;
      expect(run.advanceCoop(LiteBiome.campo), isTrue);
      run.enemies.clear();
      run.step(.02);
      expect(run.enemies, hasLength(3));
      seen.add(run.enemies.first.kind);
      final loaded = LiteRun.fromJson(run.toJson(includeEffects: true));
      final builds = {
        for (final enemy in loaded.enemies)
          enemy.mirror!.playerId: enemy.mirror!,
      };
      expect(builds.keys, containsAll([0, knight.id, ashley.id]));
      expect(builds[0]!.chosenArt, LiteLearnedArt.linfa);
      expect(builds[knight.id]!.chosenArt, LiteLearnedArt.lame);
      expect(builds[ashley.id]!.chosenArt, LiteLearnedArt.plasma);
      expect(builds[ashley.id]!.weapon, LiteWeapon.guanti);
    }
    expect(seen, {LiteEnemyKind.luce, LiteEnemyKind.ombra});
  });

  test('mirrors cast Open and increase Art use by difficulty', () {
    final counts = <int>[];
    for (final difficulty in LiteDifficulty.values) {
      final run =
          LiteRun(
              seed: 251,
              hero: LiteHero.duplicatore,
              weapon: LiteWeapon.spadaScudo,
              difficulty: difficulty,
            )
            ..enemies.clear()
            ..obstacles.clear();
      final mirror =
          LiteMirrorBuild(
              hero: LiteHero.pyrel,
              weapon: LiteWeapon.guanti,
              slots: [],
              quantities: [],
              learned: {},
              oculum: 100,
              damage: 6,
              shield: 0,
              chosenArt: LiteLearnedArt.plasma,
            )
            ..signatureCooldown = 120
            ..talentCooldown = 120
            ..techniqueCooldown = 120
            ..artCooldown = 0;
      run.enemies.add(
        LiteEnemy(900, LiteEnemyKind.luce, const Point(9, 11), 1000)
          ..mirror = mirror,
      );
      for (var frame = 0; frame < 1560; frame++) {
        run.hp = run.maxHp;
        run.step(1 / 120);
      }
      expect(mirror.openUses, greaterThan(0), reason: difficulty.name);
      expect(mirror.oculum, lessThan(100));
      counts.add(mirror.learnedUses);
    }
    for (var i = 1; i < counts.length; i++) {
      expect(counts[i], greaterThanOrEqualTo(counts[i - 1]), reason: '$counts');
    }
    expect(counts.last, greaterThan(counts.first));
  });

  test('Pyrel has one flame and one saved explosive resurrection', () {
    final run =
        LiteRun(seed: 251, hero: LiteHero.pyrel, weapon: LiteWeapon.scettro)
          ..enemies.clear()
          ..obstacles.clear()
          ..hp = 4;
    run.enemies.add(
      LiteEnemy(100, LiteEnemyKind.slime, const Point(7, 11), 150)
        ..cooldown = 100,
    );
    expect(run.hasEmberSentinel(), isTrue);
    expect(run.emberPosition().x, lessThan(run.position.x));
    run.step(.02);
    expect(
      run.projectiles.where(
        (shot) => !shot.fromEnemy && shot.kind == LiteProjectileKind.fireball,
      ),
      hasLength(1),
    );
    run.projectiles.add(
      LiteProjectile(
        position: run.position,
        direction: const Point(1, 0),
        speed: 0,
        remaining: 1,
        damage: 200,
        fromEnemy: true,
      ),
    );
    run.step(.02);
    expect(run.dead, isFalse);
    expect(run.hp, closeTo(run.maxHp * .35, 1e-5));
    expect(run.hasEmberSentinel(), isFalse);
    expect(run.enemies.first.hp, lessThan(150));
    expect(
      run.combatImpacts.where(
        (hit) => hit.target == LiteImpactTarget.emberRebirth,
      ),
      hasLength(1),
    );
    expect(
      LiteRun.fromJson(run.toJson(includeEffects: true)).supply.emberSpent,
      isTrue,
    );
  });
}
