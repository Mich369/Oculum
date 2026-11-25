import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum_rl/game/oculum_lite_coop.dart';
import 'package:oculum_rl/game/oculum_lite_run.dart';

LiteRun _coopField({LiteWeapon weapon = LiteWeapon.guanti}) {
  final run = LiteRun(
    seed: 251,
    hero: LiteHero.duplicatore,
    weapon: LiteWeapon.guanti,
    biome: LiteBiome.campo,
    playerCount: 2,
  );
  expect(
    run.addCoopFighter('guest', 'Ospite', LiteHero.ashley, weapon),
    isTrue,
  );
  return run;
}

void _clearAtPortal(LiteRun run) {
  run
    ..enemies.clear()
    ..stageClear = true
    ..position = run.portalPosition;
}

void main() {
  test('a guest dash from the old floor never crosses the portal', () {
    final run = _coopField();
    final [near, far] = run.dashPads;
    final guest = run.coopFighter('guest')!..position = near;
    expect(
      run.setCoopControls(
        'guest',
        const Point(0, 0),
        far,
        attack: false,
        dash: true,
      ),
      isTrue,
    );
    expect(run.toJson()['padDashes'], isNotEmpty);
    _clearAtPortal(run);
    expect(run.advanceCoop(LiteBiome.foresta), isTrue);
    final spawn = guest.position;
    for (var frame = 0; frame < 45; frame++) {
      run.step(1 / 120);
    }
    expect(guest.position, spawn);
    expect(run.toJson()['padDashes'], isNull);
    expect(
      run.achievements.where((key) => key.startsWith('passaggio-scatto-')),
      isEmpty,
    );
  });

  test(
    'the supply room cancels a guest move carried from the cleared floor',
    () {
      final run = _coopField()..stage = 5;
      final guest = run.coopFighter('guest')!;
      expect(
        run.setCoopControls(
          'guest',
          const Point(1, 0),
          const Point(11, 11),
          attack: true,
        ),
        isTrue,
      );
      _clearAtPortal(run);
      expect(run.enterRestHub(), isTrue);
      expect(guest.firing, isFalse);
      expect(guest.movement, const Point(0, 0));
      expect(run.toJson()['padDashes'], isNull);
    },
  );

  test('a coop Art obeys the block in its own packet and spends only once', () {
    final run = _coopField();
    final guest = run.coopFighter('guest')!;
    guest.supply.art = LiteLearnedArt.plasma;
    final before = guest.oculum;
    final session = OculumLiteCoop(
      runId: 'test',
      localAccount: 'master',
      send: (_) async => true,
      authority: run,
    );
    addTearDown(session.dispose);

    void press(int input, int action, {required bool block}) {
      session.receive(
        {
          'kind': 'playInput',
          'runId': 'test',
          'stage': run.stage,
          'arena': run.inputArena,
          'input': input,
          'move': [0, 0],
          'aim': [12, 11],
          'attack': false,
          'block': block,
          'restAction': {'kind': 'art', 'item': '', 'id': action},
        },
        account: 'guest',
        sessionId: 'device',
        verifiedMaster: false,
      );
    }

    press(1, 1, block: true);
    expect(guest.blocking, isTrue);
    expect(guest.oculum, before);
    expect(run.projectiles, isEmpty);

    press(2, 2, block: false);
    expect(guest.blocking, isFalse);
    expect(run.projectiles.single.kind, LiteProjectileKind.plasma);
    expect(guest.oculum, before - LiteLearnedArt.plasma.cost);

    guest.supply.artCooldown = 0;
    press(3, 2, block: false);
    expect(run.projectiles, hasLength(1));
    expect(guest.oculum, before - LiteLearnedArt.plasma.cost);
  });
}
