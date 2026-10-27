import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'oculum_escape_provoker_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

void main() {
  test(
    'every monster equipment converts, retains authored data and survives JSON without repeated upgrades',
    () {
      var total = 0, monsters = 0;
      final families = <String, int>{};
      for (final monster in defaultMonsterBookEntries) {
        final items = oculumMonsterEquipmentCatalogue(source: monster);
        if (items.isNotEmpty) monsters++;
        for (final item in items) {
          final before = jsonDecode(jsonEncode(item.toJson())) as Map;
          expect(
            oculumEquipmentCanBecomeTitle(item),
            isTrue,
            reason: item.nome,
          );
          oculumInitializeItemTitle(item);
          expect(oculumItemTitleDustCost(item.livelloOggetto), 3);
          expect(item.ability!.toJson(), before['ability'], reason: item.nome);
          expect(item.buff, before['buff']);
          expect(item.monsterLoot, before['monsterLoot']);
          expect(item.peso, before['peso']);
          expect(item.elementoDanno, before['elementoDanno']);
          expect(item.titleAbility!.forme, hasLength(2));
          expect(oculumItemTitleEvolutionReady(item), isFalse);
          expect(
            oculumItemTitleEvolution(item)['species'],
            oculumPartyHuntSpeciesId(monster.id),
          );
          expect(
            item.bonusDanno +
                item.bonusDifesa +
                item.bonusScudo +
                item.bonusScudoOculum,
            greaterThan(
              readIntValue(before['bonusDanno']) +
                  readIntValue(before['bonusDifesa']) +
                  readIntValue(before['bonusScudo']) +
                  readIntValue(before['bonusScudoOculum']),
            ),
          );
          final json = jsonEncode(item.toJson());
          oculumInitializeItemTitle(item);
          expect(jsonEncode(item.toJson()), json);
          final restored = InventoryItem.fromJson(
            jsonDecode(json) as Map<String, dynamic>,
          );
          expect(restored.toJson(), item.toJson());
          families.update(
            '${item.craftData['itemFamily']}',
            (n) => n + 1,
            ifAbsent: () => 1,
          );
          total++;
        }
      }
      expect(monsters, greaterThan(1000));
      expect(families.keys, containsAll(['weapon', 'armor', 'shield']));
      Directory('build').createSync();
      File('build/item-title-catalogue-audit.json').writeAsStringSync(
        jsonEncode({
          'monsters': monsters,
          'equipment': total,
          'families': families,
          'checks': [
            'fixed_cost_3',
            'original_skill_preserved',
            'buff_and_material_preserved',
            'positive_upgrade',
            'quest_locked',
            'json_roundtrip',
            'idempotent_upgrade',
          ],
        }),
      );
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );

  test(
    'quest requires attributed matching kills, rejects summons and replay, unlocks on fifth kill',
    () {
      final item = InventoryItem(
        nome: 'Lama',
        peso: 1,
        quantita: 1,
        note: '',
        arma: true,
        elementoDanno: 'Natura',
        craftData: {'monsterId': 'slime_blu'},
      );
      oculumInitializeItemTitle(item);
      Map<String, dynamic> enemy(
        String id, {
        String owner = 'HERO',
        bool summon = false,
        bool used = true,
        String species = 'slime_blu',
      }) => {
        'id': id,
        'killerTag': owner,
      'totalPower': 50,
      'killerTotalPower': 50,
        'monsterBookId': species,
        'isSummon': summon,
        'titleItemIds': [if (used) item.craftData['titleItemId']],
      };
      for (final e in [
        enemy('wrong-owner', owner: 'OTHER'),
        enemy('summon', summon: true),
        enemy('unused', used: false),
        enemy('wrong-species', species: 'shadow_devil'),
      ]) {
        expect(
          oculumAdvanceItemTitleKills(item, [e], 'fight', 'HERO'),
          isFalse,
        );
      }
      for (var i = 0; i < 5; i++) {
        expect(
          oculumAdvanceItemTitleKills(item, [enemy('$i')], 'fight', 'HERO'),
          isTrue,
        );
        expect(
          oculumAdvanceItemTitleKills(item, [enemy('$i')], 'fight', 'HERO'),
          isFalse,
        );
        expect(oculumItemTitleEvolutionReady(item), i == 4);
      }
      final copy = InventoryItem.fromJson(
        jsonDecode(jsonEncode(item.toJson())) as Map<String, dynamic>,
      );
      expect(
        oculumAdvanceItemTitleKills(copy, [enemy('4')], 'fight', 'HERO'),
        isFalse,
      );
      expect(oculumItemTitleEvolutionReady(copy), isTrue);
    },
  );

  testWidgets(
    'conversion spends exactly three, splits one, rejects consumables and double spend, repairs legacy once',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      final item = InventoryItem(
        nome: 'Scudo personalizzato',
        peso: 2,
        quantita: 3,
        note: 'Mia nota',
        protegge: true,
        equipaggiata: true,
        bonusScudo: 40,
        scudoIntegritaCorrente: 0,
        buff: '@Materia+7',
      );
      state.inventario.add(item);
      state.ascensionDustController.text = '2';
      p.convertItemTitle(item);
      expect(item.quantita, 3);
      state.ascensionDustController.text = '6';
      p.convertItemTitle(item);
      final converted = (state.inventario as List)
          .cast<InventoryItem>()
          .singleWhere((i) => i.craftData['titleItem'] == true);
      expect(item.quantita, 2);
      expect(item.craftData['titleItem'], isNull);
      expect(converted.quantita, 1);
      expect(converted.equipaggiata, isFalse);
      expect(converted.scudoIntegritaCorrente, 0);
      expect(converted.buff, '@Materia+7');
      expect(state.ascensionDustController.text, '3');
      p.convertItemTitle(converted);
      expect(state.ascensionDustController.text, '3');
      final potion = InventoryItem(
        nome: 'Pozione',
        peso: .1,
        quantita: 1,
        note: '',
      );
      state.inventario.add(potion);
      p.convertItemTitle(potion);
      expect(potion.craftData['titleItem'], isNull);
      expect(state.ascensionDustController.text, '3');
      final legacy = InventoryItem(
        nome: 'Titolo vecchio',
        peso: 1,
        quantita: 1,
        note: 'custom',
        arma: true,
        bonusDanno: 77,
        craftData: {'titleItem': true, 'conversionDustCost': 9},
      );
      state.inventario.add(legacy);
      p.repairItemTitles();
      expect(legacy.bonusDanno, greaterThan(77));
      final once = jsonEncode(legacy.toJson());
      p.repairItemTitles();
      expect(jsonEncode(legacy.toJson()), once);
      expect(state.ascensionDustController.text, '3');
      await p.useEquipment(converted, converted.titleAbility!.forme.first);
      expect(converted.craftData['titleOpenUsedSinceLongRest'], isNull);
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'evolution and Open use share gates; reduced skill cooldown persists and advances',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      final item = InventoryItem(
        nome: 'Scudo',
        peso: 1,
        quantita: 1,
        note: '',
        protegge: true,
        equipaggiata: true,
      );
      oculumInitializeItemTitle(item);
      state.inventario.add(item);
      final open = item.titleAbility!.forme.first;
      final reduced = item.titleAbility!.forme.last;
      expect(p.itemTitleAvailable(item, open), isFalse);
      final before = p.structuredEffects();
      await p.useEquipment(item, open);
      expect(p.structuredEffects(), before);
      item.craftData['titleEvolution']['progress'] = 5;
      expect(p.itemTitleAvailable(item, open), isTrue);
      expect(p.itemTitleAvailable(item, reduced), isTrue);
      final activation = p.useEquipment(item, open);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Conferma'), findsWidgets);
      await tester.tap(find.text('Conferma').last);
      await tester.pump();
      await activation;
      expect(item.craftData['titleOpenUsedSinceLongRest'], isTrue);
      expect(p.structuredEffects().length, greaterThan(before.length));
      expect(p.itemTitleAvailable(item, open), isFalse);
      expect(p.itemTitleAvailable(item, reduced), isTrue);
      reduced.cooldownStrutturato!.activate();
      final saved = InventoryItem.fromJson(
        jsonDecode(jsonEncode(item.toJson())) as Map<String, dynamic>,
      );
      expect(
        saved.titleAbility!.forme.last.cooldownStrutturato!.ready,
        isFalse,
      );
      for (var i = 0; i < 3; i++) {
        p.tickEquipmentCooldowns();
      }
      expect(reduced.cooldownStrutturato!.ready, isTrue);
      await p.useEquipment(item, open);
      expect(
        p.itemTitleAvailable(item, open),
        isFalse,
        reason: 'A replay cannot activate the Open twice',
      );
      await closeFixture(tester, p);
    },
  );
}
