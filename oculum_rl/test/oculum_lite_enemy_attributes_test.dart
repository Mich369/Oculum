import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum_rl/game/oculum_lite_run.dart';

LiteEnemyProfile _profile(
  LiteEnemyKind kind, {
  int floor = 9,
  LiteDifficulty difficulty = LiteDifficulty.medio,
  bool champion = false,
  bool applyBalance = true,
}) => LiteEnemyProfile.forKind(
  kind,
  difficulty,
  originFloor: floor,
  champion: champion,
  applyBalance: applyBalance,
);

LiteRun _world() =>
    LiteRun(seed: 41120, hero: LiteHero.evasore, weapon: LiteWeapon.guanti)
      ..obstacles.clear();

void main() {
  test('enemy budget grows by origin floor, difficulty and promoted role', () {
    const kind = LiteEnemyKind.scostubandito;
    final easy = _profile(
      kind,
      floor: 0,
      difficulty: LiteDifficulty.moltoFacile,
    );
    final hard = _profile(kind, floor: 0, difficulty: LiteDifficulty.oculum);
    final deeper = _profile(kind, floor: 18, difficulty: LiteDifficulty.oculum);
    final promoted = _profile(
      kind,
      floor: 18,
      difficulty: LiteDifficulty.oculum,
      champion: true,
    );
    expect(easy.attributes.total, 40);
    expect(hard.attributes.total, 52);
    expect(deeper.attributes.total, 61);
    expect(promoted.attributes.total, 66);
    expect(deeper.role, LiteEnemyRole.tiratore);
    expect(deeper.attributes.volonta, greaterThan(deeper.attributes.oculum));
    expect(
      deeper.attributes.materia,
      greaterThan(deeper.attributes.resilienza),
    );
  });

  test(
    'defenders and casters specialize without applying difficulty twice',
    () {
      final defender = _profile(LiteEnemyKind.guardianoSolare, floor: 0);
      final caster = _profile(LiteEnemyKind.veyrth, floor: 0);
      expect(
        defender.attributes.resilienza,
        greaterThan(caster.attributes.resilienza),
      );
      expect(
        defender.attributes.materia,
        greaterThan(caster.attributes.materia),
      );
      expect(caster.attributes.oculum, greaterThan(defender.attributes.oculum));
      expect(defender.lifeScale, greaterThan(1));
      expect(caster.lifeScale, lessThan(1));
      expect(caster.attackScale, greaterThan(1));
      for (final kind in LiteEnemyKind.values) {
        for (final difficulty in LiteDifficulty.values) {
          for (final floor in [0, 12, 36]) {
            final profile = _profile(
              kind,
              floor: floor,
              difficulty: difficulty,
            );
            expect(profile.lifeScale, inInclusiveRange(.96, 1.04));
            expect(profile.attackScale, inInclusiveRange(.96, 1.04));
            expect(profile.reachScale, inInclusiveRange(.96, 1.04));
            expect(profile.recoveryRate, inInclusiveRange(.97, 1.03));
          }
        }
      }
    },
  );

  test('Rush profiles preserve origin statistics without adding modifiers', () {
    final original = _profile(LiteEnemyKind.arconte, floor: 24);
    final rush = _profile(
      LiteEnemyKind.arconte,
      floor: 24,
      applyBalance: false,
    );
    expect(rush.originFloor, 24);
    for (final attribute in LiteAttribute.values) {
      expect(rush.attributes[attribute], original.attributes[attribute]);
    }
    expect(
      [rush.lifeScale, rush.attackScale, rush.reachScale, rush.recoveryRate],
      [1, 1, 1, 1],
    );
    for (final kind in [
      LiteEnemyKind.minionVeyrth,
      LiteEnemyKind.ecoSpeculare,
      LiteEnemyKind.luce,
      LiteEnemyKind.ombra,
    ]) {
      expect(_profile(kind).applyBalance, isFalse);
    }
  });

  test(
    'profile is serialized once and old saves keep actual Vita and Danni',
    () {
      final world = _world();
      final profile = _profile(LiteEnemyKind.rasvyr, floor: 5);
      final enemy =
          LiteEnemy(901, LiteEnemyKind.rasvyr, const Point(24, 5), 133)
            ..profile = profile
            ..hp = 75;
      world.enemies
        ..clear()
        ..add(enemy);
      final saved =
          jsonDecode(jsonEncode(world.toJson())) as Map<String, dynamic>;
      final loaded = LiteRun.fromJson(saved).enemies.single;
      expect(loaded.profile?.difficulty, LiteDifficulty.medio);
      expect(loaded.profile?.originFloor, 5);
      expect(loaded.profile?.role, LiteEnemyRole.assaltatore);
      expect(loaded.profile?.attributes.total, profile.attributes.total);
      expect(loaded.attackDamage, enemy.attackDamage);
      expect(loaded.maxHp, 133);
      expect(loaded.hp, 75);

      (saved['enemies'] as List).single.remove('attributes');
      final legacy = LiteRun.fromJson(saved).enemies.single;
      expect(legacy.profile, isNull);
      expect(legacy.attackDamage, LiteEnemyKind.rasvyr.damage.toDouble());
      expect(legacy.maxHp, 133);
      expect(legacy.hp, 75);
    },
  );

  test('Materia changes recovery of a normal fighter in the actual loop', () {
    final world = _world()..position = const Point(12, 11);
    final enemy =
        LiteEnemy(901, LiteEnemyKind.scostubandito, const Point(18, 11), 130)
          ..profile = _profile(LiteEnemyKind.scostubandito, floor: 0)
          ..cooldown = 1;
    world.enemies
      ..clear()
      ..add(enemy);
    final profile = enemy.profile!;
    expect(profile.recoveryRate, greaterThan(1));
    world.step(.075);
    expect(enemy.cooldown, closeTo(1 - .075 * profile.recoveryRate, 1e-8));
  });

  test('normal arena spawns apply the role Life adjustment exactly once', () {
    final world = LiteRun(
      seed: 41120,
      hero: LiteHero.evasore,
      weapon: LiteWeapon.guanti,
      biome: LiteBiome.deserto,
      explorationRoutes: true,
    );
    final enemy = world.enemies.first;
    expect(enemy.profile?.originFloor, 0);
    expect(enemy.profile?.difficulty, world.difficulty);
    final profile = enemy.profile!;
    expect(profile.applyBalance, isTrue);
    final beforeProfile =
        (enemy.kind.health *
                world.difficulty.enemyStrength *
                world.monsterLifeMultiplier)
            .roundToDouble();
    expect(enemy.maxHp, closeTo(beforeProfile * profile.lifeScale, 1e-8));
    final loaded = LiteRun.fromJson(world.toJson()).enemies.first;
    expect(loaded.maxHp, enemy.maxHp);
  });

  test('an actual Veyrth echo keeps its authored single point of Life', () {
    final world = _world()
      ..stage = LiteRun.veyrthStage
      ..enemies.clear()
      ..enemies.add(
        LiteEnemy(915, LiteEnemyKind.veyrth, const Point(26, 11), 200)
          ..summonIn = .01,
      );
    world.step(.03);
    final echo = world.enemies.firstWhere(
      (enemy) => enemy.kind == LiteEnemyKind.minionVeyrth,
    );
    expect(echo.maxHp, 1);
    expect(echo.hp, 1);
    expect(echo.profile?.applyBalance, isFalse);
  });

  test(
    'an actual Boss Rush health override keeps the original floor profile',
    () {
      final world = LiteRun(
        seed: 13,
        hero: LiteHero.evasore,
        weapon: LiteWeapon.arco,
        explorationRoutes: true,
        difficulty: LiteDifficulty.moltoFacile,
      );
      world
        ..stage = 13
        ..stageClear = true
        ..position = world.bossRushGate
        ..enemies.clear()
        ..obstacles.clear();
      expect(world.enterBossRush(), isTrue);
      final run = world.toJson();
      final roster = (run['bossRush'] as Map)['roster'] as List;
      final floor = (roster.first as List)[1] as int;
      final boss = world.enemies.single;
      expect(boss.profile?.originFloor, floor);
      expect(boss.profile?.applyBalance, isFalse);
      final previousLife =
          (boss.kind.health *
                  world.difficulty.enemyStrength *
                  (1 + .10 * floor) *
                  (1 + LiteRun.enemyLifeBonusAt(floor) / 100) *
                  (1 + LiteRun.challengeBonus(floor, boss.kind).life / 100) *
                  world.monsterLifeMultiplier)
              .roundToDouble();
      expect(boss.maxHp, previousLife);
      expect(boss.attackDamage, boss.kind.damage.toDouble());
    },
  );
}
