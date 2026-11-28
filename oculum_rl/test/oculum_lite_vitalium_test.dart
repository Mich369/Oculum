import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum_rl/game/oculum_lite_run.dart';

LiteRun _arena({int players = 1}) => LiteRun(
  seed: 41120,
  hero: LiteHero.evasore,
  weapon: LiteWeapon.guanti,
  playerCount: players,
)..obstacles.clear();

void _pickUp(LiteRun world, LiteLootKind item, {LiteCoopFighter? fighter}) {
  world.loot.add(LiteLoot(fighter?.position ?? world.position, item, 1));
  world.step(.01);
  expect(world.loot.where((loot) => loot.kind == item), isEmpty);
}

void main() {
  test(
    'Vitalium fixes floor zero healing at 20 and 100 regardless of max Life',
    () {
      expect(LiteRun.normalLifeAtFloor(0), 100);
      for (final level in [1, 9]) {
        final world = _arena()
          ..level = level
          ..hp = 10
          ..oculum = 1;
        _pickUp(world, LiteLootKind.greenStone);
        expect(world.hp, 30);
        expect(world.oculum, 1);

        _pickUp(world, LiteLootKind.refinedGreenGem);
        expect(world.hp, min(world.maxHp, 130));
        expect(world.oculum, world.maxOculum);
        if (level == 9) expect(world.hp, lessThan(world.maxHp));
      }
    },
  );

  test(
    'a guest gets fixed Vitalium and full Oculum, only their companions heal',
    () {
      final world = _arena(players: 2);
      expect(
        world.addCoopFighter(
          'guest',
          'Ospite',
          LiteHero.evasore,
          LiteWeapon.arco,
        ),
        isTrue,
      );
      world
        ..stage = 9
        ..hp = 30
        ..oculum = 2;
      final guest = world.coopFighters.single
        ..position = const Point(11, 5)
        ..experience = 22000
        ..hp = 4
        ..oculum = 1;
      final pet = LiteClone(
        const Point(11, 6),
        201,
        LiteWeapon.arco,
        id: 907,
        ownerId: guest.id,
        companion: LiteCompanion.vedetta,
      )..hp = 12;
      final hostPet = LiteClone(
        const Point(11, 7),
        201,
        LiteWeapon.arco,
        id: 908,
        companion: LiteCompanion.vedetta,
      )..hp = 12;
      world.clones.addAll([pet, hostPet]);
      // Let the pets reach their owner levels before measuring the shared heal.
      expect(
        world.setCoopControls(
          guest.account,
          const Point(0, 0),
          guest.position,
          attack: false,
        ),
        isTrue,
      );
      world.step(.01);
      final beforePetLife = pet.hp;
      final beforeHostPetLife = hostPet.hp;
      world.loot.add(LiteLoot(guest.position, LiteLootKind.refinedGreenGem, 1));
      final healedBy = LiteRun.normalLifeAtFloor(9);
      expect(healedBy, greaterThan(100));
      expect(guest.maxHp, greaterThan(healedBy + 4));
      expect(guest.maxOculum, greaterThan(10));

      final snapshot =
          jsonDecode(jsonEncode(world.toJson())) as Map<String, dynamic>;
      final resumed = LiteRun.fromJson(snapshot);
      final player = resumed.coopFighters.single;
      final petResumed = resumed.clones.firstWhere(
        (clone) => clone.id == pet.id,
      );
      final hostPetResumed = resumed.clones.firstWhere(
        (clone) => clone.id == hostPet.id,
      );

      expect(
        resumed.setCoopControls(
          player.account,
          const Point(0, 0),
          player.position,
          attack: false,
        ),
        isTrue,
      );
      resumed.step(.01);
      expect(player.hp, closeTo(4 + healedBy, 1e-8));
      expect(player.oculum, player.maxOculum);
      expect(resumed.hp, 30);
      expect(resumed.oculum, 2);
      expect(petResumed.hp, closeTo(beforePetLife + .30 * healedBy, 1e-8));
      expect(hostPetResumed.hp, beforeHostPetLife);
      expect(resumed.loot, isEmpty);
      resumed.step(.01);
      expect(player.hp, closeTo(4 + healedBy, 1e-8));
    },
  );

  test('Grezzo scales by floor and sharing uses the effective capped heal', () {
    final world = _arena()..stage = 5;
    final pet = LiteClone(
      const Point(7, 11),
      120,
      LiteWeapon.arco,
      id: 910,
      companion: LiteCompanion.vedetta,
    )..hp = 20;
    world.clones.add(pet);
    world.hp = 4;
    _pickUp(world, LiteLootKind.greenStone);
    var expected = LiteRun.normalLifeAtFloor(5) * .20;
    expect(expected, greaterThan(20));
    expect(world.hp, closeTo(4 + expected, 1e-8));
    expect(pet.hp, closeTo(20 + expected * .30, 1e-8));

    world.hp = world.maxHp - 6;
    _pickUp(world, LiteLootKind.greenStone);
    expect(world.hp, world.maxHp);
    expect(pet.hp, closeTo(21.8 + expected * .30, 1e-8));
  });
}
