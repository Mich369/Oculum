import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

import 'oculum_escape_provoker_test.dart' show mountFight;
import 'oculum_october27_resources_test.dart' show closeFixture;

void main() {
  test(
    'special Fabbro gear keeps its equipment roles and firearm defaults',
    () {
      final offers = oculumBlacksmithSpecialEquipmentOffers();
      expect(offers.map((offer) => offer['id']).toSet(), hasLength(11));
      expect(
        offers.every((offer) => '${offer['weaponAppearance']}'.isNotEmpty),
        isTrue,
      );
      InventoryItem item(String id) =>
          oculumBlacksmithSpecialEquipmentFromOffer(
            offers.firstWhere((offer) => offer['id'] == 'fabbro_$id'),
          );
      final thorn = item('frusta_di_spine');
      expect(thorn.nome, 'Spinavine');
      expect(thorn.note, contains('Frusta di Spine'));
      expect(thorn.arma, isTrue);
      expect(thorn.elementoDanno, 'natura');
      expect(thorn.craftData['natureThornWhip'], isTrue);
      expect(item('chakram_di_brina_pura').elementoDanno, 'gelo');
      final dread = item('dread_bow');
      expect(dread.nome, 'Eclipse Dread-Bow');
      expect(dread.elementoDanno, 'oscuro');
      expect(dread.craftData['dreadBowIgnoresPhysicalArmor'], isTrue);
      expect(item('sword_breaker').craftData['swordBreaker'], isTrue);
      expect(item('ascia_bipenne').nome, 'Bipennis');
      final fireMace = item('fire_mace');
      expect(
        (fireMace.nome, fireMace.elementoDanno),
        ('Malleus Ignis', 'fuoco'),
      );
      expect(fireMace.craftData['fireMace'], isTrue);
      expect(fireMace.note, contains('polvere e zolfo'));
      final shield = item('gun_shield');
      final blade = item('gunblade');
      expect(
        (shield.arma, shield.protegge, shield.bonusScudo),
        (true, true, 10),
      );
      expect((blade.arma, blade.protegge), (true, false));
      expect(shield.craftData['gunShield'], isTrue);
      expect(blade.craftData['gunblade'], isTrue);
      expect(shield.craftData['gunFollowupDamage'], 15);
      expect(blade.craftData['gunFollowupDamage'], 20);
      for (final weapon in [shield, blade]) {
        final restored = InventoryItem.fromJson(weapon.toJson());
        expect(restored.craftData['gunFollowupCooldown'], 2);
      }
    },
  );

  test(
    'generated relics cover the weapon shapes and keep the Teschio skill',
    () {
      final weapons = oculumMonsterEquipmentCatalogue()
          .where((item) => item.arma)
          .toList();
      final forms = weapons.map((item) => item.craftData['weaponForm']).toSet();
      expect(
        forms,
        containsAll([
          'sciabola',
          'spadone',
          'lancia',
          'stocco',
          'alabarda',
          'arco',
          'balestra_a_una_mano',
        ]),
      );
      expect(
        weapons.map((item) => item.monsterLoot['id']).toSet(),
        hasLength(weapons.length),
      );
      expect(
        weapons.every((item) => item.craftData['weaponAppearance'] is String),
        isTrue,
      );
      final named = weapons.singleWhere(
        (item) =>
            item.monsterLoot['id'] ==
            'monster-relic:teschio_quattro_lame:0:weapon',
      );
      expect(named.nome, 'Ossivigil');
      expect(
        named.note,
        contains('Sciabola d’Osso del Teschio a Quattro Lame'),
      );
      expect(named.ability!.nome, 'Lama d’osso');
      expect(
        named.craftData['weaponAppearance'],
        contains('quattro lame ricurve'),
      );
    },
  );

  test('Fabbro stocks exact monster weapons and rejects duplicate ids', () {
    final monster = monsterBookEntryById('raccoglitore_di_chiodi')!;
    final native = oculumMonsterEquipmentCatalogue(
      source: monster,
    ).where((item) => item.arma).toList();
    final physical = monster.inventoryItems.indexed
        .where((entry) => entry.$2['arma'] == true)
        .toList();

    List<Map<String, dynamic>> stock(Set<String> excluded, {int grade = 12}) =>
        oculumBlacksmithMonsterWeaponOffers(
          monsters: [monster, monster.copyWith(isNpc: true)],
          characterLevel: 6,
          characterGrade: grade,
          minimumGrade: 0,
          characterTotalPower: 70,
          budget: 2000,
          random: Random(23),
          excludedIds: excluded,
          count: 3,
        );
    final first = stock({
      for (final (index, _) in physical)
        'fabbro_monster_weapon_${monster.id}:inventory:$index',
    }).single;
    final nativeItem = InventoryItem.fromJson(
      jsonDecode(jsonEncode(first['relicItem'])) as Map<String, dynamic>,
    );
    expect(nativeItem.ability, isNotNull);
    expect(nativeItem.arma, isTrue);
    expect(nativeItem.equipaggiata, isFalse);
    expect(nativeItem.quantita, 1);
    expect(
      native.map((item) => item.monsterLoot['id']),
      contains(nativeItem.monsterLoot['id']),
    );
    expect(nativeItem.craftData['fabbroMonsterWeaponId'], first['id']);

    final physicalOffer = stock({
      for (final item in native)
        'fabbro_monster_weapon_${item.monsterLoot['id']}',
    }).single;
    final physicalItem = InventoryItem.fromJson(
      physicalOffer['relicItem'] as Map<String, dynamic>,
    );
    expect(physicalOffer['name'], 'Vigilnail');
    expect(physicalOffer['desc'], contains('Martello da banco'));
    expect(physicalOffer['weaponAppearance'], contains('ferro battuto'));
    expect(
      physical.map((entry) => entry.$2['nome']),
      contains(physicalItem.nome),
    );
    expect(physicalItem.equipaggiata, isFalse);
    expect(
      stock({
        for (final item in native)
          'fabbro_monster_weapon_${item.monsterLoot['id']}',
        for (final (index, _) in physical)
          'fabbro_monster_weapon_${monster.id}:inventory:$index',
      }),
      isEmpty,
    );
    expect(
      oculumMerchantCanPurchaseOffer({...first, 'grade': 4}, characterGrade: 3),
      isFalse,
    );
  });

  test(
    'Postea offers each reactive item separately with saved editable effects',
    () {
      final offers = oculumPosteaReactiveEquipmentOffers(3);
      expect(offers.map((offer) => offer['id']).toSet(), hasLength(5));
      InventoryItem item(String id) {
        final created = oculumPosteaReactiveEquipment(
          offers.firstWhere((offer) => offer['id'] == id),
          acquisitionLevel: 7,
        )!;
        return InventoryItem.fromJson(
          jsonDecode(jsonEncode(created.toJson())) as Map<String, dynamic>,
        );
      }

      final armor = item('postea_reactive_armor');
      expect((armor.livelloOggetto, armor.bonusScudo), (6, 200));
      expect(armor.craftData['manualPriceObser'], 1200);
      expect(armor.craftData['posteaArmorShockDamage'], 50);
      expect(armor.craftData['posteaArmorRecoveryPercent'], 25);
      final shield = item('postea_perfect_shield');
      expect(shield.craftData['posteaParryShieldGain'], 25);
      expect(shield.craftData['posteaParryShieldCap'], 75);
      final sword = item('postea_reactive_sword');
      expect(sword.nome, 'Reductus');
      expect(sword.note, contains('Lama di Ritorno di Postea'));
      expect(
        (sword.livelloOggetto, sword.bonusDanno, sword.elementoDanno),
        (7, 45, 'plasma'),
      );
      expect(sword.craftData['posteaSwordShieldCap'], 100);
      final chakram = item('postea_homing_chakram');
      final boomerang = item('postea_homing_boomerang');
      expect(chakram.nome, 'Cerberus Disc');
      expect(boomerang.nome, 'Hellhound Arc');
      for (final weapon in [chakram, boomerang]) {
        expect(weapon.livelloOggetto, 7);
        expect(weapon.elementoDanno, 'plasma');
        expect(weapon.craftData['posteaHomingPlasmaHitBonus'], 6);
      }
    },
  );

  testWidgets(
    'transforming Postea armor keeps the persisted quote despite merchant markup',
    (tester) async {
      final (state, probe) = await mountFight(tester);
      const armorId = 'postea_transform_armor';
      Map<String, dynamic> armorOffer() {
        probe.merchantOfferIds();
        return (state.merchantStock as List<Map<String, dynamic>>).singleWhere(
          (offer) => offer['id'] == armorId,
        );
      }

      final offer = armorOffer();
      expect(offer['cost'], inInclusiveRange(8000, 13000));
      final profile = (state.merchantProfiles as List)
          .whereType<Map>()
          .firstWhere(
            (profile) => profile['id'] == state.merchantActiveProfileId,
          );
      profile['pricePercent'] = 200;
      expect(probe.shopCost(offer), offer['cost']);
      offer['cost'] = 13000;
      armorOffer();
      final saved =
          jsonDecode(jsonEncode(probe.snapshot())) as Map<String, dynamic>;
      probe.load(saved);
      final restored = armorOffer();
      expect(restored['cost'], 13000);
      expect(probe.shopCost(restored), 13000);

      final item = oculumPosteaReactiveEquipment(
        restored,
        acquisitionLevel: 1,
      )!;
      final roundTripped = InventoryItem.fromJson(item.toJson());
      expect(roundTripped.nome, 'Ferrum Mutabile');
      expect((roundTripped.arma, roundTripped.protegge), (false, true));
      expect(roundTripped.bonusDifesa, 12);
      expect(roundTripped.bonusScudo, 0);
      expect(roundTripped.craftData['posteaTransformArmor'], isTrue);
      expect(roundTripped.craftData['posteaTransformDurationTurns'], 3);
      expect(roundTripped.craftData['posteaTransformHpPercent'], 150);
      expect(roundTripped.craftData['posteaTransformStatsPercent'], 130);
      expect(roundTripped.craftData['posteaTransformShield'], 400);
      await closeFixture(tester, probe);
    },
  );
}
