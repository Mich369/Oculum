import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'oculum_theme_effects_portrait_test.dart' as fixtures;

void main() {
  test(
    'common title slots can hold Fate and other dedicated title variants',
    () {
      expect(
        oculumChooseTitleSlot(
          preferredPool: 'Titoli del Fato',
          preferredUsed: 1,
          preferredCapacity: 1,
          standardUsed: 2,
          standardCapacity: 6,
        ),
        'Standard',
      );
      expect(
        oculumChooseTitleSlot(
          preferredPool: 'Titoli del Fato',
          preferredUsed: 1,
          preferredCapacity: 1,
          standardUsed: 6,
          standardCapacity: 6,
        ),
        isNull,
      );
      expect(
        oculumChooseTitleSlot(
          preferredPool: 'Titoli del Fato',
          preferredUsed: 0,
          preferredCapacity: 1,
          standardUsed: 6,
          standardCapacity: 6,
        ),
        'Titoli del Fato',
      );
    },
  );
  test(
    'monster relics resell for 30 percent of their moderate market price',
    () {
      expect(oculumMonsterRelicMarketPrice(level: 0, grade: 0), 50);
      expect(oculumMonsterRelicMarketPrice(level: 30, grade: 2), 390);
      expect(oculumMonsterRelicSaleValueForMarketPrice(390), 117);
      expect(oculumMonsterRelicSaleValueForMarketPrice(390, quantity: 2), 234);
    },
  );
  test('monster food learning uses percentage points and safe bounds', () {
    expect(oculumMonsterFoodLearningChance(5), 5.5);
    expect(oculumMonsterFoodLearningChance(-10), 0);
    expect(oculumMonsterFoodLearningChance(200), 100);
  });
  test('item level growth settings survive legacy-compatible JSON', () {
    final item = InventoryItem(
      nome: 'Guanto',
      note: '',
      peso: 1,
      quantita: 1,
      livelloOggetto: 15,
      puntiStatPerLivello: 3,
      statCrescita: 'resilienza',
    );
    final copy = InventoryItem.fromJson(item.toJson());
    expect(copy.livelloOggetto, 15);
    expect(copy.puntiStatPerLivello, 3);
    expect(copy.statCrescita, 'resilienza');
    final old = InventoryItem.fromJson({'nome': 'Vecchia arma'});
    expect(old.livelloOggetto, 0);
    expect(old.puntiStatPerLivello, 1);
  });
  test('equipment skill waits for both item and form levels', () {
    expect(
      oculumEquipmentSkillLevelAvailable(
        characterLevel: 4,
        itemLevel: 5,
        formLevel: '0',
      ),
      isFalse,
    );
    expect(
      oculumEquipmentSkillLevelAvailable(
        characterLevel: 5,
        itemLevel: 5,
        formLevel: '0',
      ),
      isTrue,
    );
    expect(
      oculumEquipmentSkillLevelAvailable(
        characterLevel: 8,
        itemLevel: 5,
        formLevel: '10',
      ),
      isFalse,
    );
    expect(
      oculumEquipmentSkillLevelAvailable(
        characterLevel: 10,
        itemLevel: 5,
        formLevel: '10',
      ),
      isTrue,
    );
  });
  test('shop blocks equipment above the character grade only', () {
    expect(
      oculumMerchantCanPurchaseOffer({
        'kind': 'gear',
        'grade': 2,
      }, characterGrade: 1),
      isFalse,
    );
    expect(
      oculumMerchantCanPurchaseOffer({
        'kind': 'gear',
        'grade': 1,
      }, characterGrade: 1),
      isTrue,
    );
    expect(
      oculumMerchantCanPurchaseOffer({
        'kind': 'gear',
        'grade': 1,
      }, characterGrade: 2),
      isTrue,
    );
    expect(
      oculumMerchantCanPurchaseOffer({
        'kind': 'food',
        'grade': 99,
      }, characterGrade: 0),
      isTrue,
    );
  });
  test('equipment minimum price scales by grade with Grade III at 260', () {
    expect(List<int>.generate(7, oculumMerchantEquipmentMinimumPrice), [
      50,
      120,
      190,
      260,
      330,
      400,
      470,
    ]);
    expect(
      oculumMerchantEquipmentPrice({
        'kind': 'gear',
        'grade': 3,
        'level': 15,
        'cost': 258,
      }),
      260,
    );
    expect(
      oculumMerchantEquipmentPrice({
        'kind': 'gear',
        'grade': 3,
        'level': 19,
        'cost': 258,
      }),
      300,
    );
  });
  testWidgets(
    'grade guard, percent food buffs, rewards and Master requests are idempotent',
    (tester) async {
      final dynamic state = await fixtures.mountSheet(
        tester,
        const Size(1440, 900),
      );
      final probe = OculumPerformanceProbe(state);
      state.datiCaricati = false;
      state.schedePersonaggio.clear();
      state.schedePersonaggio.add(<String, dynamic>{
        'id': 'TESTPG',
        'sheetTag': 'TESTPG',
        'nome': 'Test',
      });
      state.schedaCorrente = 0;
      state.gradoController.text = '0';
      final item = InventoryItem(
        nome: 'Guanto',
        note: '',
        peso: 1,
        quantita: 1,
        arma: true,
        equipaggiata: true,
        gradoOggetto: 1,
        livelloOggetto: 15,
        puntiStatPerLivello: 3,
        statCrescita: 'resilienza',
      );
      expect(probe.canEquip(item), isFalse);
      expect(probe.itemBonuses(item)['resilienza'] ?? 0, 0);
      state.gradoController.text = '1';
      expect(probe.itemBonuses(item)['resilienza'], 45);
      state.gradoController.text = '0';
      state.volontaController.text = '100';
      state.currentVolontaController.text = '100';
      probe.invalidateDerivedCaches();
      final before = probe.willTotal();
      probe.addCondition('nutrito_volonta', stage: 3);
      expect(probe.willTotal(), before + 6);
      probe.addCondition('nutrito_volonta', stage: 1);
      expect(probe.willTotal(), before + 6);
      state.expController.text = '0';
      state.scalaExpAutomatica = false;
      final tag = probe.currentTag();
      final reward = <String, dynamic>{
        'id': 'unique-kill',
        'amount': 23,
        'participants': [tag],
      };
      probe.encounterRewards([reward]);
      probe.encounterRewards([reward]);
      expect(state.expController.text, '23');
      state.gradoController.text = '0';
      state.schedePersonaggio.add(<String, dynamic>{
        'id': 'EXP_ALLY',
        'sheetTag': 'EXP_ALLY',
        'nome': 'Alleato grado I',
        'grado': '1',
        'rebirthato': false,
      });
      final currentSheet = state.schedaCorrente;
      state.schedaCorrente = state.schedePersonaggio.length - 1;
      final allyTag = probe.currentTag();
      state.schedaCorrente = currentSheet;
      final gradedReward = <String, dynamic>{
        'id': 'graded-kill',
        'amount': 20,
        'participants': [tag, allyTag],
        'defeated': [
          {'level': 5, 'statsTotal': 15, 'grade': 1, 'source': 'Mostro'},
        ],
      };
      probe.encounterRewards([gradedReward]);
      probe.encounterRewards([gradedReward]);
      expect(state.expController.text, '147');
      expect(state.obserController.text, isNotEmpty);
      final dustAfterReward = state.ascensionDustController.text;
      final obserAfterReward = state.obserController.text;
      state.onlineCombatRequests.remove('reward:graded-kill:$tag');
      probe.encounterRewards([gradedReward]);
      expect(state.expController.text, '147');
      expect(state.ascensionDustController.text, dustAfterReward);
      expect(state.obserController.text, obserAfterReward);
      expect(
        state.onlineCombatRequests['reward:graded-kill:$allyTag']['amount'],
        120,
      );
      expect(
        state.onlineCombatRequests['reward:graded-kill:$allyTag']['status'],
        'queued',
      );
      state.ascensionDustController.text = '5';
      state.ascensionDustUsataOggi = 0;
      if ((state.hiddenEyeStats as List).isEmpty) {
        state.hiddenEyeStats.add(
          HiddenEyeStat(id: 'forza', nome: 'Forza', descrizione: ''),
        );
      }
      final highest = probe.highestDustSubtraits().first;
      final beforeDustExp = readIntValue(state.expController.text);
      final beforeStatExp = readIntValue(
        state.esperienzaCriticaStatistiche['volonta'],
      );
      expect(probe.dustExperience(highest, 1), isTrue);
      expect(state.ascensionDustController.text, '4');
      expect(
        readIntValue(state.esperienzaCriticaStatistiche['volonta']),
        beforeStatExp + 21,
      );
      expect(
        readIntValue(state.expController.text),
        greaterThan(beforeDustExp),
      );
      state.ascensionDustUsataOggi = 3;
      expect(
        probe.dustExperience(probe.highestDustSubtraits().first, 90),
        isFalse,
      );
      expect(state.ascensionDustController.text, '4');
      final request = <String, dynamic>{
        'id': 'unique-roll',
        'targetTag': tag,
        'rollKey': 'materia',
        'rollName': 'Materia',
        'dt': 5,
      };
      probe.masterRollRequests({
        'rollRequests': [request],
      });
      state.onlineCombatRequests['unique-roll']['status'] = 'completed';
      probe.masterRollRequests({
        'rollRequests': [request],
      });
      expect(state.onlineCombatRequests['unique-roll']['status'], 'completed');
      probe.cancelPendingSave();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 3));
    },
  );
  testWidgets(
    'alchemist discount is specific and scrolls follow current grade',
    (tester) async {
      final dynamic state = await fixtures.mountSheet(
        tester,
        const Size(1440, 900),
      );
      final probe = OculumPerformanceProbe(state);
      probe.createMerchantProfile();
      final offers = (state.merchantStock as List)
          .whereType<Map>()
          .map((offer) => Map<String, dynamic>.from(offer))
          .where(
            (offer) => const {
              'weapon_lancia_velo',
              'weapon_pugnale_precisione',
              'armor_corazza_guardia',
              'shield_bastione_materia',
            }.contains(offer['id']),
          )
          .toList();
      expect(offers.length, 4);
      expect(offers.every((offer) => readIntValue(offer['level']) > 0), isTrue);
      // Isolate the alchemist discount from the merchant's price personality.
      (state.merchantProfiles as List).whereType<Map>().firstWhere(
        (profile) => profile['id'] == state.merchantActiveProfileId,
      )['pricePercent'] = 100;
      probe.shopType('alchimista');
      expect(probe.shopCost({'kind': 'refined_vitalium', 'cost': 100}), 90);
      expect(probe.shopOffers().any((o) => o['kind'] == 'alchemy_pet'), isTrue);
      expect(
        probe
            .shopOffers()
            .where((o) => o['kind'] == 'technique_scroll')
            .every((o) => o['scrollGrade'] == 0),
        isTrue,
      );
      probe.shopType('materiali');
      expect(probe.shopCost({'kind': 'refined_vitalium', 'cost': 100}), 100);
      expect(
        probe.shopOffers().any((o) => o['kind'] == 'raw_vitalium'),
        isTrue,
      );
      expect(
        probe.shopOffers().any((o) => o['kind'] == 'alchemy_pet'),
        isFalse,
      );
      probe.cancelPendingSave();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 3));
    },
  );
}
