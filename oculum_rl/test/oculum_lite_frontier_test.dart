import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum_rl/game/oculum_lite_run.dart';
import 'package:oculum_rl/services/oculum_lite_saves.dart';

const start = Point<double>(14, 11);
const right = Point<double>(1, 0);
const idle = Point<double>(0, 0);

LiteRun ready(LiteHero hero, LiteWeapon weapon, {int players = 1}) =>
    LiteRun(seed: 251, hero: hero, weapon: weapon, playerCount: players)
      ..position = start
      ..obstacles.clear()
      ..fauna.clear()
      ..loot.clear()
      ..enemies.clear();

LiteEnemy enemy(
  int id,
  LiteEnemyKind kind,
  Point<double> position,
  double hp,
) => LiteEnemy(id, kind, position, hp)..stunned = 20;

void waitFor(LiteRun run, double seconds) {
  for (var elapsed = 0.0; elapsed < seconds; elapsed += .02) {
    run.step(.02);
  }
}

void main() {
  test(
    'new hero achievements go to the fighter who defeated each creature',
    () {
      final run = ready(LiteHero.evasore, LiteWeapon.spadaScudo, players: 2);
      run.addCoopFighter(
        'isolate',
        'Ospite',
        LiteHero.evasore,
        LiteWeapon.spadaScudo,
      );
      final guest = run.coopFighter('isolate')!
        ..position = const Point(14, 15)
        ..cooldown = 0;
      final gablyn = enemy(900, LiteEnemyKind.gablyn, start + right * 2, 1);
      final funerys = enemy(
        901,
        LiteEnemyKind.funerys,
        guest.position + right * 2,
        1,
      );
      run.enemies.addAll([gablyn, funerys]);
      expect(run.attack(gablyn.position), isTrue);
      expect(
        run.setCoopControls('isolate', idle, funerys.position, attack: true),
        isTrue,
      );
      waitFor(run, .1);

      final saved = LiteRun.fromJson(run.toJson());
      final hostUnlocks = saved.unlockedHeroesFor(run.hero);
      final guestUnlocks = saved.unlockedHeroesFor(
        guest.hero,
        guestAccount: 'isolate',
      );
      expect(hostUnlocks, contains(LiteHero.gablyn));
      expect(hostUnlocks, isNot(contains(LiteHero.funerys)));
      expect(guestUnlocks, contains(LiteHero.funerys));
      expect(guestUnlocks, isNot(contains(LiteHero.gablyn)));
      final profile = OculumLiteProgress().recordRun(saved);
      expect(
        OculumLiteProgress.decode(profile.encode()).canPlay(LiteHero.gablyn),
        isTrue,
      );
      expect(
        run.loot.map((item) => item.weapon),
        containsAll([LiteWeapon.beccoCaverna, LiteWeapon.falceFunerys]),
      );
    },
  );

  test('Gablyn performs a continuous dash and Funerys pulls loose enemies', () {
    final gablyn = ready(LiteHero.gablyn, LiteWeapon.beccoCaverna);
    final foe = enemy(901, LiteEnemyKind.slime, start + right * 3.6, 100);
    gablyn.enemies.add(foe);
    expect(gablyn.special(foe.position), isTrue);
    expect(gablyn.position, start);
    expect(foe.hp, lessThan(100));
    gablyn.step(.08);
    expect(gablyn.position.x, inExclusiveRange(14, 16.1));
    waitFor(gablyn, .30);
    expect(gablyn.position.x, closeTo(16.1, .12));

    final funerys = ready(LiteHero.funerys, LiteWeapon.falceFunerys);
    final normal = enemy(902, LiteEnemyKind.slime, const Point(18.8, 11), 300);
    final boss = enemy(
      903,
      LiteEnemyKind.baghest,
      const Point(18.8, 12.5),
      500,
    );
    funerys.enemies.addAll([normal, boss]);
    final normalAt = normal.position;
    final bossAt = boss.position;
    expect(funerys.special(normalAt), isTrue);
    expect(normal.position.distanceTo(normalAt), greaterThan(.9));
    expect(boss.position.distanceTo(bossAt), lessThan(.4));
    expect(normal.shockRemaining, greaterThan(boss.shockRemaining));

    final resource = funerys.oculum;
    expect(funerys.useOpen(normalAt), isTrue);
    expect(funerys.oculum, resource - LiteRun.granSummonCost);
    expect(funerys.useOpen(normalAt), isFalse);
    final frame = LiteRun.fromJson(funerys.toJson(includeEffects: true));
    expect(frame.openScene?.hero, LiteHero.funerys);
    expect(
      frame.combatImpacts.any(
        (impact) => impact.target == LiteImpactTarget.frontierCast,
      ),
      isTrue,
    );
  });

  test('Bobina chains once per target and cannot conduct through cover', () {
    final run = ready(LiteHero.evasore, LiteWeapon.bobinaPostea);
    final first = enemy(901, LiteEnemyKind.slime, const Point(17, 11), 500);
    final second = enemy(902, LiteEnemyKind.slime, const Point(19, 11), 500);
    final third = enemy(903, LiteEnemyKind.slime, const Point(21.2, 11), 500);
    final covered = enemy(904, LiteEnemyKind.slime, const Point(18, 13.2), 500);
    run.enemies.addAll([first, second, third, covered]);
    run.obstacles.add(LiteObstacle(15.9, 12, 5.3, .6));
    expect(run.useWeaponArt(const Point(22, 11)), isTrue);
    expect(500 - first.hp, greaterThan(500 - second.hp));
    expect(500 - second.hp, greaterThan(500 - third.hp));
    expect(third.hp, lessThan(500));
    expect(covered.hp, 500);
    expect(
      run.combatImpacts.where(
        (impact) => impact.target == LiteImpactTarget.frontierCast,
      ),
      hasLength(3),
    );
    expect(run.useWeaponArt(first.position), isFalse);
  });

  test(
    'all three weapons buy and temper, with fusion working after reload',
    () {
      var run =
          LiteRun(
              seed: 251,
              hero: LiteHero.evasore,
              weapon: LiteWeapon.spadaScudo,
            )
            ..stage = 6
            ..restHub = true
            ..obser = 900;
      final weaponPrices = {
        LiteRestItem.beccoCaverna: LiteWeapon.beccoCaverna,
        LiteRestItem.falceFunerys: LiteWeapon.falceFunerys,
        LiteRestItem.bobinaPostea: LiteWeapon.bobinaPostea,
      };
      for (final entry in weaponPrices.entries) {
        expect(run.buyRestItem(entry.key), isTrue);
        expect(run.weapon, entry.value);
        expect(run.buySignature(entry.value), isFalse);
        expect(run.buyRestItem(LiteRestItem.tempra), isTrue);
        expect(run.supply.forgeRank(entry.value), 1);
      }
      expect(
        run.fuseWeapons(LiteWeapon.spadaScudo, LiteWeapon.bobinaPostea),
        isTrue,
      );
      run = LiteRun.fromJson(run.toJson())
        ..stage = 0
        ..restHub = false
        ..position = start
        ..obstacles.clear()
        ..enemies.clear();
      expect(run.fusedWeapon(), LiteWeapon.bobinaPostea);
      expect(run.maxBlockResistance, 240);
      expect(run.supply.forgeRank(LiteWeapon.bobinaPostea), 1);
      final foe = enemy(902, LiteEnemyKind.slime, start + right * 2, 500);
      run.enemies.add(foe);
      expect(run.attack(foe.position), isTrue);
      expect(foe.hp, lessThan(500));
      expect(
        run.projectiles.any((shot) => shot.magic && !shot.fromEnemy),
        isTrue,
      );
    },
  );

  test('both pet discoveries and their owner abilities survive a save', () {
    var run = ready(LiteHero.evasore, LiteWeapon.spadaScudo, players: 2);
    run.addCoopFighter(
      'guest',
      'Ospite',
      LiteHero.evasore,
      LiteWeapon.spadaScudo,
    );
    final guest = run.coopFighter('guest')!
      ..position = const Point(14, 15)
      ..cooldown = 0;
    final lapysrieth = enemy(
      920,
      LiteEnemyKind.lapysrieth,
      guest.position + right * 2,
      1,
    );
    final spider = enemy(
      921,
      LiteEnemyKind.ragnoSaldatore,
      start + right * 2,
      1,
    );
    run.enemies.addAll([lapysrieth, spider]);
    expect(run.attack(spider.position), isTrue);
    expect(
      run.setCoopControls('guest', idle, lapysrieth.position, attack: true),
      isTrue,
    );
    waitFor(run, .12);
    run = LiteRun.fromJson(run.toJson());
    expect(
      run.discoveredPets,
      containsAll([LiteCompanion.saldino, LiteCompanion.frammentoLapysrieth]),
    );
    final restoredGuest = run.coopFighter('guest')!;
    final ward = run.clones.singleWhere(
      (clone) => clone.companion == LiteCompanion.frammentoLapysrieth,
    );
    final solder = run.clones.singleWhere(
      (clone) => clone.companion == LiteCompanion.saldino,
    );
    expect(ward.ownerId, restoredGuest.id);
    expect(solder.ownerId, 0);

    run
      ..enemies.clear()
      ..shield = 0;
    restoredGuest
      ..position = const Point(14, 15)
      ..shield = 0;
    ward.position = const Point(15, 15);
    solder
      ..position = start + right
      ..cooldown = 0;
    final first = enemy(922, LiteEnemyKind.slime, const Point(19, 11), 250);
    final second = enemy(923, LiteEnemyKind.slime, const Point(20, 11), 250);
    run.enemies.addAll([first, second]);
    waitFor(run, .12);
    expect(restoredGuest.shield, greaterThanOrEqualTo(6));
    expect(run.shield, 0);
    expect(first.hp, lessThan(250));
    expect(second.hp, lessThan(250));
    restoredGuest.shield = 0;
    final loaded = LiteRun.fromJson(run.toJson());
    waitFor(loaded, .2);
    expect(
      loaded.coopFighter('guest')!.shield,
      0,
      reason: 'The pet shield cooldown persists across reload',
    );
  });
}
