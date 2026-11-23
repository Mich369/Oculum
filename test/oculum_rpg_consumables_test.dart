import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'oculum_escape_provoker_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

Map<String, dynamic> definition(String id) =>
    oculumRpgConsumables.singleWhere((entry) => entry['id'] == id);

void main() {
  testWidgets(
    'a leaf keeps its item and turn resource if the chosen limb disappears before confirmation',
    (tester) async {
      final (state, probe) = await fixtures.mountFight(tester);
      final saved = probe.snapshot()
        ..['planarRuntime'] = {
          'anatomicalParts': {
            'parts': {
              'qa_arm': {
                'id': 'qa_arm',
                'label': 'Braccio da rivalidare',
                'maximumHp': 20,
                'damageTaken': 10,
              },
            },
          },
        };
      state.schedePersonaggio[state.schedaCorrente] = saved;
      probe.load(saved);
      state.currentHpController.text = '10';
      final item = oculumRpgConsumableFromOffer(definition('leaf_greenheart'));
      state.inventario.add(item);
      final use = probe.useMerchantItem(item);
      await tester.pump();
      await tester.tap(find.text('Braccio da rivalidare'));
      await tester.pump(const Duration(milliseconds: 350));
      saved['planarRuntime']['anatomicalParts']['parts']['qa_arm']['missing'] =
          true;
      await tester.tap(find.text('1 Azione'));
      await tester.pump(const Duration(milliseconds: 350));
      await use;
      expect(item.quantita, 1);
      expect((state.inventario as List<InventoryItem>).contains(item), isTrue);
      expect(state.masterInitiativeTokens.first['actionUsed'] == true, isFalse);
      expect(state.currentHpController.text, '10');
      await closeFixture(tester, probe);
    },
  );
  testWidgets(
    'a leaf heals a character without part HP by a quarter plus target level',
    (tester) async {
      final (state, probe) = await fixtures.mountFight(tester);
      state.masterInitiativeGroups.first['fightStarted'] = false;
      final saved = probe.snapshot()
        ..['planarRuntime'] = {
          'anatomicalParts': {
            'parts': {
              'arm_right': {
                'id': 'arm_right',
                'label': 'Braccio senza riserva separata',
                'group': 'arms',
                'injured': true,
              },
            },
          },
        };
      saved['monsterBookSourceId'] = '';
      state.schedePersonaggio[state.schedaCorrente] = saved;
      probe.load(saved);
      state.livelloController.text = '4';
      state.currentHpController.text = '1';
      final maximum = probe.maximumHp();
      final item = oculumRpgConsumableFromOffer(definition('leaf_greenheart'));
      state.inventario.add(item);
      final use = probe.useMerchantItem(item);
      await tester.pump();
      await tester.tap(find.text('Braccio senza riserva separata'));
      await tester.pump(const Duration(milliseconds: 350));
      await use;
      expect(
        state.currentHpController.text,
        '${(1 + (maximum + 3) ~/ 4 + 4).clamp(0, maximum)}',
      );
      expect(item.quantita, 0);
      await closeFixture(tester, probe);
    },
  );

  test(
    'Asher adapts absent Oculum and saved custom values stay independent',
    () {
      final offer = definition('wing_asher_fragment');
      final item = oculumRpgConsumableFromOffer(offer);
      final effects =
          (item.craftData['rpgConsumable'] as Map)['effects'] as Map;
      expect(oculumRpgConsumableStatBonuses(effects, hasOculum: true), {
        'resilienza': 6,
        'volonta': 9,
        'materia': 6,
        'oculum': 6,
      });
      expect(oculumRpgConsumableStatBonuses(effects, hasOculum: false), {
        'resilienza': 6,
        'volonta': 15,
        'materia': 8,
        'oculum': 0,
      });
      (effects['stats'] as Map)['volonta'] = 23;
      final restored = InventoryItem.fromJson(
        jsonDecode(jsonEncode(item.toJson())),
      );
      expect(
        ((restored.craftData['rpgConsumable'] as Map)['effects']
            as Map)['stats']['volonta'],
        23,
      );
      expect((offer['effects'] as Map)['stats']['volonta'], 9);
      expect(
        oculumInventoryCatalogCategories(restored),
        contains('consumable'),
      );
    },
  );

  testWidgets('merchant prices remain fixed and Asher expires at Long Rest', (
    tester,
  ) async {
    final (state, probe) = await fixtures.mountFight(tester);
    state.masterInitiativeGroups.first['fightStarted'] = false;
    state.currentHpController.text = '10';
    state.oculumController.text = '0';
    state.merchantStock.clear();
    probe.merchantOfferIds();
    final stock = state.merchantStock as List<Map<String, dynamic>>;
    final leafOffer = stock.singleWhere(
      (entry) => entry['id'] == 'leaf_greenheart',
    );
    expect(leafOffer['rarity'], 'non_comune');
    final boughtLeaf = oculumRpgConsumableFromOffer(leafOffer);
    expect(boughtLeaf.note, startsWith('Non comune'));
    expect(
      InventoryItem.fromJson(
        jsonDecode(jsonEncode(boughtLeaf.toJson())),
      ).craftData['rarity'],
      'non_comune',
    );
    // Filling the new catalogue field must preserve an already saved price.
    leafOffer.remove('rarity');
    leafOffer['cost'] = 103;
    probe.merchantOfferIds();
    expect(leafOffer['rarity'], 'non_comune');
    expect(leafOffer['cost'], 103);
    leafOffer['rarity'] = 'raro';
    probe.merchantOfferIds();
    expect(leafOffer['rarity'], 'raro');
    final price =
        stock.singleWhere(
              (entry) => entry['id'] == 'wing_asher_fragment',
            )['cost']
            as int;
    expect(price, inInclusiveRange(300, 369));
    probe.merchantOfferIds();
    expect(
      stock.singleWhere(
        (entry) => entry['id'] == 'wing_asher_fragment',
      )['cost'],
      price,
    );
    final item = oculumRpgConsumableFromOffer(definition('wing_asher_fragment'))
      ..quantita = 2;
    state.inventario.add(item);
    await probe.useMerchantItem(item);
    expect(probe.herbalBonus('volonta'), 15);
    expect(probe.herbalBonus('materia'), 8);
    expect(probe.herbalBonus('oculum'), 0);
    await probe.useMerchantItem(item);
    expect(
      probe.herbalBonus('volonta'),
      15,
      reason: 'A new fragment renews its own effect.',
    );
    final saved =
        jsonDecode(jsonEncode(probe.snapshot())) as Map<String, dynamic>;
    probe.load(saved);
    expect(probe.herbalBonus('volonta'), 15);
    probe.longRest(advanceWorldClock: false);
    expect(probe.herbalBonus('volonta'), 0);
    expect(probe.herbalBonus('materia'), 0);
    await closeFixture(tester, probe);
  });

  testWidgets(
    'a leaf heals only its selected part and preserves another injury',
    (tester) async {
      final (state, probe) = await fixtures.mountFight(tester);
      state.masterInitiativeGroups.first['fightStarted'] = false;
      final saved = probe.snapshot();
      saved['planarRuntime'] = {
        'anatomicalParts': {
          'parts': {
            for (final side in ['left', 'right'])
              'arm_$side': {
                'id': 'arm_$side',
                'label': 'Braccio $side',
                'group': 'arms',
                'maximumHp': 20,
                'damageTaken': 20,
                'injured': true,
                'legacyCriticalFracture': true,
              },
            'missing_arm': {
              'label': 'Braccio mancante',
              'missing': true,
              'maximumHp': 20,
              'damageTaken': 20,
            },
          },
        },
      };
      state.schedePersonaggio[state.schedaCorrente] = saved;
      probe.load(saved);
      state.currentHpController.text = '10';
      state.activeConditions.add(
        OculumConditionInstance(
          id: 'qa-fractures',
          conditionType: 'frattura',
          category: oculumConditionDefinition('frattura')!.category,
          stacks: 2,
          metadata: {
            'limbs': [
              {'id': 'arm_left', 'group': 'arms', 'label': 'Braccio left'},
              {'id': 'arm_right', 'group': 'arms', 'label': 'Braccio right'},
            ],
          },
        ),
      );
      final item = oculumRpgConsumableFromOffer(definition('leaf_greenheart'));
      state.inventario.add(item);
      final use = probe.useMerchantItem(item);
      await tester.pump();
      expect(find.text('Braccio mancante'), findsNothing);
      await tester.tap(find.text('Braccio right'));
      await tester.pump(const Duration(milliseconds: 350));
      await use;
      final parts = probe.anatomicalPartsSnapshot()['parts'] as Map;
      expect(parts['arm_right']['damageTaken'], 0);
      expect(parts['arm_left']['damageTaken'], 20);
      expect(parts['missing_arm']['missing'], true);
      expect(state.currentHpController.text, '10');
      final condition =
          (state.activeConditions as List<OculumConditionInstance>).single;
      expect(condition.stacks, 1);
      expect((condition.metadata['limbs'] as List).single['id'], 'arm_left');
      expect(item.quantita, 0);
      await closeFixture(tester, probe);
    },
  );

  testWidgets(
    'a leaf treats another living sheet without consuming its inventory',
    (tester) async {
      final (state, probe) = await fixtures.mountFight(tester);
      state.masterInitiativeGroups.first['fightStarted'] = false;
      state.currentHpController.text = '10';
      final patient =
          jsonDecode(jsonEncode(probe.snapshot())) as Map<String, dynamic>;
      patient.addAll({
        'id': 'ALLY',
        'sheetTag': 'ALLY',
        'nome': 'Paziente',
        'currentHp': '8',
        'planarRuntime': {
          'anatomicalParts': {
            'parts': {
              'patient_arm': {
                'id': 'patient_arm',
                'label': 'Braccio bersaglio',
                'group': 'arms',
                'maximumHp': 15,
                'damageTaken': 12,
                'injured': true,
              },
            },
          },
        },
        'inventario': <dynamic>[],
      });
      state.schedePersonaggio.add(patient);
      final item = oculumRpgConsumableFromOffer(definition('leaf_greenheart'))
        ..quantita = 2;
      state.inventario.add(item);
      final use = probe.useMerchantItem(item);
      await tester.pump();
      await tester.tap(find.text('Paziente'));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(find.text('Braccio bersaglio'));
      await tester.pump(const Duration(milliseconds: 350));
      await use;
      expect(state.schedaCorrente, 0);
      expect(state.currentHpController.text, '10');
      expect(
        (state.inventario as List<InventoryItem>)
            .singleWhere((i) => i.nome == item.nome)
            .quantita,
        1,
      );
      final healed = state.schedePersonaggio[1] as Map;
      expect(healed['currentHp'], '8');
      expect(
        healed['planarRuntime']['anatomicalParts']['parts']['patient_arm']['damageTaken'],
        0,
      );
      await closeFixture(tester, probe);
    },
  );

  testWidgets('a crystal can spend a Reaction instead of an Action once', (
    tester,
  ) async {
    final (state, probe) = await fixtures.mountFight(tester);
    state.currentHpController.text = '10';
    final item = oculumRpgConsumableFromOffer(definition('crystal_restore'));
    state.masterInitiativeTokens.first['reactionUsed'] = 0;
    state.masterInitiativeTokens.first['reactionPoolInitialized'] = true;
    state.masterInitiativeTokens.first['reactionNormalFirstRoundLocked'] =
        false;
    state.masterInitiativeTokens.first['reactionPoolRound'] =
        state.masterInitiativeRound;
    state.masterInitiativeTokens.first['reactionUsedRound'] =
        state.masterInitiativeRound;
    probe.recordCurrentEncounter();
    state.inventario.add(item);
    final use = probe.useMerchantItem(item);
    await tester.pump();
    final duplicate = probe.useMerchantItem(item);
    await tester.tap(find.text('1 Reazione'));
    await tester.pump(const Duration(milliseconds: 350));
    await Future.wait([use, duplicate]);
    final actor = state.masterInitiativeTokens.first as Map;
    expect(item.quantita, 0, reason: '${state.logEventi.take(3).toList()}');
    expect(
      actor['reactionUsed'],
      1,
      reason: jsonEncode({
        'actor': actor,
        'resources': probe.combatTurnResources(),
        'log': state.logEventi.take(3).toList(),
      }),
    );
    expect(actor['actionUsed'] == true, false);
    expect(item.quantita, 0);
    expect(tester.takeException(), isNull);
    await closeFixture(tester, probe);
  });
}
