import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum_rl/game/oculum_lite_coop.dart';
import 'package:oculum_rl/game/oculum_lite_run.dart';

LiteRun _desert(int seed, {int players = 1}) => LiteRun(
  seed: seed,
  biome: LiteBiome.deserto,
  hero: LiteHero.evasore,
  weapon: LiteWeapon.arco,
  playerCount: players,
  explorationRoutes: true,
);

LiteRun _reload(LiteRun world) => LiteRun.fromJson(
  jsonDecode(jsonEncode(world.toJson())) as Map<String, dynamic>,
);

Future<void> _until(bool Function() present) async {
  final clock = Stopwatch()..start();
  while (!present()) {
    if (clock.elapsed > const Duration(seconds: 7)) {
      fail('Il frame atteso non è arrivato');
    }
    await Future<void>.delayed(const Duration(milliseconds: 15));
  }
}

void main() {
  test('Fortuna assegna tutte e venti le facce secondo la soglia', () {
    for (var roll = 1; roll <= 20; roll++) {
      final expected = switch (roll) {
        1 => LiteDesertEyeOutcome.negativoEccezionale,
        <= 10 => LiteDesertEyeOutcome.negativo,
        20 => LiteDesertEyeOutcome.positivoEccezionale,
        _ => LiteDesertEyeOutcome.positivo,
      };
      expect(LiteDesertEyeOutcome.fromRoll(roll), expected);
    }
    expect(() => LiteDesertEyeOutcome.fromRoll(0), throwsRangeError);
  });

  test(
    '41119 fa scendere nel varco calpestandolo e rimette sullo stesso piano',
    () {
      var run = _desert(41119)..shield = 20;
      final originalLife = run.hp;
      final initial = run.enemies.map((enemy) => enemy.id).toList();
      final loot = run.loot.map((drop) => drop.amount).toList();
      final obstacles = run.obstacles
          .map((cover) => (cover.top, cover.hp, cover.fixedMap))
          .toList();
      final fauna = run.fauna.map((animal) => animal.id).toList();
      final before = run.position;
      final site = run.desertEyePosition!;
      run.step(.025);
      expect(run.position, before);
      expect(run.hp, originalLife);
      expect(run.shield, 20, reason: 'Il terreno normale non taglia');
      expect(run.inDesertEye, isFalse);
      run.position = site + const Point(1.2, 0);
      for (var i = 0; i < 30 && !run.inDesertEye; i++) {
        run.step(.025, move: const Point(-1, 0), walk: true);
      }
      expect(run.desertEyeFortune, 14);
      expect(run.desertEyeCut, 9);
      expect(run.hp, originalLife);
      expect(run.shield, 11);
      expect(run.arenaLabel, contains('Taglio 1d12: 9'));
      expect(run.milestoneFloors, 0);
      expect(run.stageClear, isTrue);
      expect(run.hasRest, isFalse);
      expect(run.canOpenShop, isFalse);
      expect(run.obser, 15);
      run = _reload(run);
      expect(run.desertEyeFortune, 14);
      expect(run.desertEyeCut, 9);
      expect(run.shield, 11);
      run.position = run.portalPosition;
      expect(run.advance(), isTrue);
      expect(run.stage, 0);
      expect(run.obser, 15);
      expect(run.inDesertEye, isFalse);
      expect(run.loot.map((drop) => drop.amount), loot);
      expect(
        run.obstacles.map((cover) => (cover.top, cover.hp, cover.fixedMap)),
        obstacles,
      );
      expect(run.fauna.map((animal) => animal.id), fauna);
      expect(run.enemies.map((enemy) => enemy.id), initial);
      expect(run.desertEyePosition, isNull);
      expect(run.position.distanceTo(site), greaterThan(.9));
      expect(run.hasFloorMap, isTrue);
      run.position = site;
      run.step(.025);
      expect(run.inDesertEye, isFalse);
      expect(run.obser, 15);
      expect(run.hp, originalLife);
      expect(run.shield, 11);
    },
  );

  test(
    'rami negativi chiudono il varco e premiano la sopravvivenza una volta',
    () {
      for (final (seed, roll, count, reward) in [
        (73, 1, 4, 8),
        (130, 10, 2, 5),
      ]) {
        var run = _desert(seed);
        run.position = run.desertEyePosition!;
        run.step(.025);
        expect(run.desertEyeFortune, roll);
        expect(run.enemies.length, count);
        expect(run.obser, 0);
        run.position = run.portalPosition;
        expect(run.hasPortalNearby, isFalse);
        expect(run.advance(), isFalse);
        run = _reload(run);
        run.enemies.clear();
        run.step(.025);
        expect(run.obser, reward);
        expect(run.advance(), isTrue);
        expect(
          run.stageClear,
          isFalse,
          reason: 'Il piano padre non è stato completato',
        );
        expect(run.milestoneFloors, 0);
        expect(run.enemies.length, 3);
      }
    },
  );

  test(
    'il 20 guarisce il party e lascia intatta una vittoria sul piano padre',
    () {
      var run = _desert(32, players: 2);
      expect(
        run.addCoopFighter(
          'guest',
          'Ospite',
          LiteHero.evasore,
          LiteWeapon.arco,
        ),
        isTrue,
      );
      final guest = run.coopFighters.single;
      run.hp = guest.hp = 50;
      run.shield = 20;
      run.position = run.desertEyePosition!;
      run.stageClear = true;
      run.enemies.clear();
      run.step(.025);
      expect(run.desertEyeFortune, 20);
      expect(run.hp, 75);
      expect(guest.hp, 75);
      expect(run.obser, 30);
      expect(guest.obser, 30);
      expect(run.milestoneFloors, 1);
      run = _reload(run);
      run.step(.025);
      expect(run.hp, 75);
      expect(run.obser, 30);
      expect(run.advanceCoop(LiteBiome.postea), isTrue);
      expect(run.stage, 0);
      expect(run.stageClear, isTrue);
      expect(run.milestoneFloors, 1);
    },
  );

  test('un vecchio salvataggio nel Deserto mantiene il formato e il piano', () {
    final old = LiteRun(
      seed: 41119,
      biome: LiteBiome.deserto,
      hero: LiteHero.evasore,
      weapon: LiteWeapon.arco,
    );
    old.position = const Point(5.2, 11);
    final restored = _reload(old);
    restored.step(.025);
    expect(restored.inDesertEye, isFalse);
    expect(restored.desertEyePosition, isNull);
  });

  test('due sessioni coop entrano dal passo dell’ospite, riprendono dopo riapertura e tornano insieme', () async {
    var world = _desert(130, players: 2);
    expect(
      world.addCoopFighter(
        'guest',
        'Ospite',
        LiteHero.evasore,
        LiteWeapon.arco,
      ),
      isTrue,
    );
    late OculumLiteCoop authority;
    Map<String, dynamic>? previousFrame;
    var epoch = 0;
    final guest = OculumLiteCoop(
      runId: 'occhio',
      localAccount: 'guest',
      localSessionId: 'guest-1',
      send: (packet) async {
        authority.receive(
          packet,
          account: 'guest',
          sessionId: 'guest-1',
          verifiedMaster: false,
        );
        return true;
      },
    );
    OculumLiteCoop master(LiteRun saved) => OculumLiteCoop(
      runId: 'occhio',
      localAccount: 'master',
      authority: saved,
      epoch: epoch,
      send: (packet) async {
        if (epoch == 0 && packet['kind'] == 'playState') previousFrame = packet;
        guest.receive(
          packet,
          account: 'master',
          sessionId: 'master-$epoch',
          verifiedMaster: true,
        );
        return true;
      },
    );
    authority = master(world);
    addTearDown(() {
      authority.dispose();
      guest.dispose();
    });
    authority.start();
    guest.start();
    await _until(() => guest.canAct);
    expect(guest.run?.inDesertEye, isFalse);
    final hostLife = world.hp;
    final guestLife = world.coopFighters.single.hp;
    world.coopFighters.single
      ..shield = 20
      ..position = world.desertEyePosition!;
    await _until(() => guest.run?.inDesertEye == true);
    expect(world.hp, hostLife);
    expect(world.coopFighters.single.hp, guestLife);
    expect(world.coopFighters.single.shield, 20 - world.desertEyeCut!);
    expect(world.inputArena, guest.run!.inputArena);
    expect(world.desertEyeFortune, guest.run!.desertEyeFortune);
    expect(world.milestoneFloors, 0);
    expect(world.position.x, lessThan(6));
    expect(world.coopFighters.single.position.x, lessThan(8));

    final saved = _reload(world);
    authority.dispose();
    epoch++;
    world = saved;
    authority = master(world);
    authority.start();
    guest.adoptAuthority(epoch);
    guest.receive(
      previousFrame!,
      account: 'master',
      sessionId: 'master-0',
      verifiedMaster: true,
    );
    await _until(() => guest.canAct);
    expect(guest.run!.inputArena, '0:occhio-divoratore');
    expect(world.obser, 0);

    world.enemies.clear();
    world.position = world.portalPosition;
    world.coopFighters.single.position = world.portalPosition;
    await _until(() => guest.nearPortal('guest'));
    authority.confirmPortal(world.biome);
    await _until(() => guest.destination != null);
    expect(world.inDesertEye, isTrue);
    guest.confirmPortal();
    await _until(() => guest.run?.inDesertEye == false);
    expect(world.stage, 0);
    expect(world.enemies.length, 3);
    expect(
      world.position.x,
      greaterThan(15),
      reason: 'L’host torna alla sua posizione di partenza',
    );
    expect(
      world.coopFighters.single.position.distanceTo(const Point(5.2, 11)),
      greaterThan(.9),
    );
    expect(world.obser, 5);
    expect(world.coopFighters.single.obser, 5);
    expect(world.hp, hostLife);
    expect(world.coopFighters.single.shield, 11);
  });
}
