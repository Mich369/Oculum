import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum_rl/game/oculum_lite_coop.dart';
import 'package:oculum_rl/game/oculum_lite_run.dart';
import 'package:oculum_rl/services/oculum_lite_saves.dart';

void main() {
  const art = LiteLearnedArt.plasma;
  const cast = LiteGrimoireAction.art(art);

  LiteRun world(int seed, {int players = 1}) => LiteRun(
    seed: seed,
    explorationRoutes: true,
    hero: LiteHero.duplicatore,
    weapon: LiteWeapon.arco,
    biome: LiteBiome.startingZone(seed),
    playerCount: players,
  );

  test(
    'an Art lesson persists and uses the assigned slot and shared cooldown',
    () {
      final run = world(72241);
      expect(run.assignGrimoire(0, cast), isFalse);
      expect(run.grimoireConfigured(), isFalse);
      run
        ..obser = 200
        ..oculum = 12
        ..position = run.restStationPoint(LiteRestStation.art);
      expect(run.buyRestItem(LiteRestItem.artPlasma), isTrue);
      expect(run.assignGrimoire(0, cast), isTrue);
      expect(run.assignGrimoire(1, null), isTrue);
      final saved = LiteRun.fromJson(run.toJson());
      final target = saved.position + const Point<double>(0, 3);
      expect(saved.grimoireSlots()[0], cast);
      expect(saved.grimoireSlots()[1], isNull);
      expect(saved.useGrimoire(1, target), isFalse);
      expect(saved.useGrimoire(0, target), isTrue);
      expect(saved.oculum, 12 - art.cost);
      expect(saved.supply.artCooldown, art.cooldown);
      expect(saved.useLearnedArt(target), isFalse);
      expect(saved.useGrimoire(0, target), isFalse);
      expect(saved.oculum, 12 - art.cost);

      final profile = const OculumLiteProgress()
          .recordRun(saved)
          .recordGrimoire(
            saved.supply.knownArts,
            characterId: 'hero:duplicatore',
            hero: saved.hero,
            slots: saved.grimoireSlots(),
          );
      final fresh = world(75102);
      fresh.restoreProfileGrimoire(
        profile.grimoire.learnedArts,
        profile.grimoire.loadoutFor('hero:duplicatore', saved.hero).actions,
      );
      expect(fresh.grimoireArts(), contains(art));
      expect(fresh.grimoireSlots(), saved.grimoireSlots());
    },
  );

  test('the co-op host authorizes and deduplicates guest Art commands', () {
    final run = world(72241, players: 2);
    expect(
      run.addCoopFighter('guest', 'Ospite', LiteHero.evasore, LiteWeapon.arco),
      isTrue,
    );
    final fighter = run.coopFighters.single
      ..obser = 200
      ..oculum = 12
      ..position = run.restStationPoint(LiteRestStation.art);
    final host = OculumLiteCoop(
      runId: 'grimoire',
      localAccount: 'host',
      authority: run,
      send: (_) async => true,
    );
    addTearDown(host.dispose);

    void sendOrder(int input, int order, String kind, String item) {
      final target = fighter.position + const Point<double>(0, 3);
      host.receive(
        {
          'kind': 'playInput',
          'runId': 'grimoire',
          'stage': run.stage,
          'arena': run.inputArena,
          'input': input,
          'move': [0, 0],
          'aim': [target.x, target.y],
          'restAction': {'id': order, 'kind': kind, 'item': item},
        },
        account: 'guest',
        sessionId: 'guest-1',
        verifiedMaster: false,
      );
    }

    sendOrder(1, 1, 'grimoireEquip', '3:art:plasma');
    expect(run.grimoireConfigured(fighter), isFalse);
    sendOrder(2, 2, 'buy', LiteRestItem.artPlasma.name);
    expect(fighter.supply.knownArts, contains(art));
    expect(run.supply.knownArts, isEmpty);
    sendOrder(3, 3, 'grimoireEquip', '3:art:plasma');
    expect(run.grimoireSlots(fighter)[3], cast);
    expect(run.grimoireSlots()[3], isNull);
    sendOrder(4, 4, 'grimoireCast', '3');
    expect(fighter.oculum, 12 - art.cost);
    expect(fighter.supply.artCooldown, art.cooldown);
    fighter.supply.artCooldown = 0;
    sendOrder(5, 4, 'grimoireCast', '3');
    expect(fighter.oculum, 12 - art.cost);

    final restored = LiteRun.fromJson(run.toJson());
    final remote = restored.coopFighters.single;
    expect(restored.grimoireSlots(remote)[3], cast);
    expect(remote.supply.knownArts, contains(art));
    expect(remote.oculum, 12 - art.cost);
  });
}
