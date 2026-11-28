import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum_rl/game/oculum_lite_run.dart';

LiteRun _start(int seed, {bool explore = true, int players = 1}) => LiteRun(
  seed: seed,
  explorationRoutes: explore,
  hero: LiteHero.evasore,
  weapon: LiteWeapon.arco,
  biome: LiteBiome.startingZone(seed),
  playerCount: players,
);

void _walk(LiteRun run, List<Point<double>> stops) {
  for (final stop in stops) {
    for (var i = 0; i < 160 && run.position.distanceTo(stop) > .18; i++) {
      run.step(.025, move: stop - run.position, walk: true);
    }
    expect(
      run.position.distanceTo(stop),
      lessThanOrEqualTo(.18),
      reason:
          'Percorso interrotto prima di $stop dalla posizione ${run.position}',
    );
  }
}

void main() {
  const champions = {
    251: LiteEnemyKind.granScostumato,
    72241: LiteEnemyKind.ragnoSaldatore,
    41119: LiteEnemyKind.rasvyr,
    60803: LiteEnemyKind.orbryx,
  };

  for (final entry in champions.entries) {
    test(
      'seed ${entry.key}: due percorsi percorribili e portale con guardiano',
      () {
        final upper = _start(entry.key);
        final lower = _start(entry.key);
        expect(upper.inExplorationAtrium(upper.position), isTrue);
        expect(
          upper.explorationLandmarks.map((site) => site.site).toSet(),
          LiteFloorSite.values.toSet(),
        );
        for (final run in [upper, lower]) {
          final y = identical(run, upper) ? 5.9 : 16.1;
          _walk(run, [
            Point(16.25, y),
            Point(23, y),
            const Point(23, 11),
            run.portalPosition,
          ]);
          expect(run.hasMapped(LiteMapSector.uscita), isTrue);
          expect(run.advance(), isFalse);
          run.enemies.clear();
          run.step(.025);
          expect(run.enemies.first.kind, entry.value);
          expect(run.hasPortalNearby, isFalse);
          expect(run.enemies.first.chamberSeat, isNotNull);
          run.enemies.clear();
          run.step(.025);
          expect(run.hasPortalNearby, isTrue);
          expect(run.advance(), isTrue);
          expect(run.inExplorationAtrium(run.position), isTrue);
        }
        expect(
          upper.hasMapped(LiteMapSector.fianco),
          isFalse,
          reason: 'Al cambio di piano riparte la scoperta',
        );
      },
    );
  }

  test('da entrambe le gallerie si può tornare ai banchi', () {
    for (final entry in champions.entries) {
      final run = _start(entry.key);
      _walk(run, const [
        Point(16.25, 5.9),
        Point(23, 5.9),
        Point(23, 16.1),
        Point(16.25, 16.1),
        Point(16.25, 11),
      ]);
      expect(run.inExplorationAtrium(run.position), isTrue);
      expect(run.hasMapped(LiteMapSector.fianco), isTrue);
      expect(run.hasMapped(LiteMapSector.retro), isTrue);
    }
  });

  test('atrio protegge da aggro e proiettili anche al ripristino coop', () {
    var run = _start(41119, players: 2);
    expect(
      run.addCoopFighter('guest', 'Ospite', LiteHero.evasore, LiteWeapon.arco),
      isTrue,
    );
    expect(run.inExplorationAtrium(run.coopFighters.single.position), isTrue);
    final initial = run.enemies.map((enemy) => enemy.position).toList();
    final health = run.hp;
    final shield = run.shield;
    run.projectiles.add(
      LiteProjectile(
        position: const Point(16.25, 6.7),
        direction: const Point(0, 1),
        speed: 45,
        remaining: 12,
        damage: 100,
        fromEnemy: true,
      ),
    );
    run = LiteRun.fromJson(run.toJson());
    for (var i = 0; i < 16; i++) {
      run.step(.25);
    }
    expect(run.usesExplorableFloor, isTrue);
    expect(run.inExplorationAtrium(run.coopFighters.single.position), isTrue);
    expect(run.enemies.map((enemy) => enemy.position), initial);
    expect(run.projectiles, isEmpty);
    expect(run.hp, health);
    expect(run.shield, shield);
  });

  test('il detour ha una scorta sola anche dopo il ripristino', () {
    var run = _start(72241);
    final cache = run.explorationLandmarks.singleWhere(
      (landmark) => landmark.site == LiteFloorSite.encounter,
    );
    expect(run.hasMapped(LiteMapSector.cuore), isFalse);
    final amount = run.loot.single.amount;
    _walk(run, [
      const Point(16.25, 5.8),
      const Point(5.2, 5.8),
      cache.position,
    ]);
    expect(run.hasMapped(LiteMapSector.cuore), isTrue);
    expect(run.obser, amount);
    run = LiteRun.fromJson(run.toJson());
    expect(run.hasMapped(LiteMapSector.cuore), isTrue);
    expect(run.loot, isEmpty);
    run.step(.25);
    expect(run.obser, amount);
  });

  test('l’acquisto dai banchi richiede la vicinanza del combattente', () {
    final run = _start(72241, players: 2);
    expect(
      run.addCoopFighter('guest', 'Ospite', LiteHero.evasore, LiteWeapon.arco),
      isTrue,
    );
    run.obser = 200;
    expect(run.buyRestItem(LiteRestItem.artPlasma), isFalse);
    _walk(run, [run.restStationPoint(LiteRestStation.art)]);
    expect(run.restStationNearby(), LiteRestStation.art);
    expect(run.buyRestItem(LiteRestItem.artPlasma), isTrue);
    expect(run.supply.hasGrimoire, isTrue);
    final guest = run.coopFighters.single..obser = 200;
    guest.position = run.portalPosition;
    expect(run.buyRestItem(LiteRestItem.artPlasma, fighter: guest), isFalse);
    guest.position = run.restStationPoint(LiteRestStation.art);
    expect(run.buyRestItem(LiteRestItem.artPlasma, fighter: guest), isTrue);
    expect(guest.supply.hasGrimoire, isTrue);
  });

  test('il nuovo percorso prosegue oltre l’ingresso nelle run nuove', () {
    final run = _start(251);
    for (final floor in [1, 2, 3, 4, 5, 6, 7]) {
      run.position = run.portalPosition;
      run.enemies.clear();
      run.stageClear = true;
      expect(run.advance(), isTrue, reason: 'Transizione al piano $floor');
      expect(run.stage, floor);
      expect(run.usesExplorableFloor, floor != 3);
      expect(run.inExplorationAtrium(run.position), floor != 3);
      expect(run.explorationLandmarks.length, floor == 3 ? 0 : 5);
    }
  });

  test(
    'il portale sposta insieme l’host e gli ospiti nella prossima mappa',
    () {
      final run = _start(60803, players: 6);
      for (var i = 1; i <= 5; i++) {
        expect(
          run.addCoopFighter(
            'guest-$i',
            'Ospite $i',
            LiteHero.evasore,
            LiteWeapon.arco,
          ),
          isTrue,
        );
      }
      _walk(run, const [
        Point(16.25, 5.9),
        Point(23, 5.9),
        Point(23, 11),
        Point(29.7, 11),
      ]);
      final zone = run.routeBiomes.first;
      expect(run.advanceCoop(zone), isFalse);
      run.enemies.clear();
      run.step(.025);
      expect(run.advanceCoop(zone), isFalse);
      run.enemies.clear();
      run.step(.025);
      expect(run.advanceCoop(zone), isTrue);
      expect(run.stage, 1);
      final points = [
        run.position,
        ...run.coopFighters.map((guest) => guest.position),
      ];
      expect(points.toSet().length, 6);
      expect(points.every(run.inExplorationAtrium), isTrue);
      expect(LiteRun.fromJson(run.toJson()).coopFighters.length, 5);
    },
  );

  test('il fabbro del seed Campo vende e tempra anche prima del guardiano', () {
    final run = _start(251)..obser = 250;
    expect(run.explorationMerchant, LiteRestStation.forge);
    _walk(run, [run.restStationPoint(LiteRestStation.forge)]);
    expect(run.restStationNearby(), LiteRestStation.forge);
    expect(run.buyRestItem(LiteRestItem.chakram), isTrue);
    expect(run.weapon, LiteWeapon.chakram);
    expect(run.buyRestItem(LiteRestItem.tempra), isTrue);
    expect(run.supply.forgeRank(LiteWeapon.chakram), 1);
    expect(run.stageClear, isFalse);
  });

  test('Reysercth salva una sola scelta per combattente e conserva la quota di Vita', () {
    final run = _start(72241, players: 2);
    expect(
      run.addCoopFighter('guest', 'Ospite', LiteHero.evasore, LiteWeapon.arco),
      isTrue,
    );
    final guest = run.coopFighters.single;
    final station = run.reysercthPosition!;
    final unmodified = run.weaponDamage;
    run.hp = run.maxHp / 2;
    expect(run.acceptReysercthMod(LiteReysercthMod.propulsore, null), isFalse);
    _walk(run, [const Point(16.25, 5.8), const Point(5.2, 5.8), station]);
    expect(run.acceptReysercthMod(LiteReysercthMod.propulsore, null), isTrue);
    expect(run.acceptReysercthMod(LiteReysercthMod.rinforzo, null), isFalse);
    expect(run.maxHp, closeTo(108, 1e-9));
    expect(run.hp, closeTo(54, 1e-9));
    expect(run.weaponDamage, closeTo(unmodified * 1.08, 1e-9));
    expect(run.acceptReysercthMod(LiteReysercthMod.rinforzo, guest), isFalse);
    guest.position = station;
    run.setCoopControls('guest', const Point(0, 0), station, attack: false);
    expect(run.acceptReysercthMod(LiteReysercthMod.rinforzo, guest), isTrue);
    final reloaded = LiteRun.fromJson(run.toJson());
    expect(reloaded.supply.reysercthMod, LiteReysercthMod.propulsore);
    expect(
      reloaded.coopFighters.single.supply.reysercthMod,
      LiteReysercthMod.rinforzo,
    );
    expect(reloaded.coopFighters.single.maxHp, closeTo(108, 1e-9));
    expect(reloaded.canSpeakToReysercth(), isFalse);
  });

  test('il propulsore non scavalca ripari nella traiettoria del bersaglio', () {
    Point<double> hit({required bool addCover}) {
      final run = _start(72241);
      run.position = run.reysercthPosition!;
      expect(run.acceptReysercthMod(LiteReysercthMod.propulsore, null), isTrue);
      final enemy = LiteEnemy(
        151,
        LiteEnemyKind.ragnoSaldatore,
        const Point(4.2, 11),
        200,
      )..stunned = 10;
      run.enemies
        ..clear()
        ..add(enemy);
      final wall = LiteObstacle(2.5, 10, .45, 2, breakable: true);
      if (addCover) run.obstacles.add(wall);
      expect(run.attack(enemy.position), isTrue);
      for (var i = 0; i < 6; i++) {
        run.step(.1);
      }
      expect(enemy.hp, lessThan(enemy.maxHp));
      if (addCover) expect(run.obstacles, contains(wall));
      return enemy.position;
    }

    expect(hit(addCover: false).x, closeTo(1.2, .01));
    expect(hit(addCover: true).x, inInclusiveRange(3.6, 3.95));
  });

  test('salvataggi precedenti riprendono il loro ingresso laterale', () {
    final legacy = _start(41119, explore: false);
    final frame = legacy.toJson();
    expect(frame.containsKey('explorationRoutes'), isFalse);
    final restored = LiteRun.fromJson(frame);
    expect(restored.usesExplorableFloor, isFalse);
    expect(restored.position, const Point<double>(4, 11));
    expect(restored.restStationNearby(), isNull);
    expect(restored.obstacles.length, legacy.obstacles.length);
  });
}
