import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

import 'oculum_oblivion_percentage_parser_test.dart' show cleanFight;
import 'oculum_october27_resources_test.dart' show closeFixture;

void main() {
  testWidgets('sheet and damage share catalogue defaults and saved overrides', (
    tester,
  ) async {
    final (state, probe) = await cleanFight(tester);
    addTearDown(resetMonsterBookEntries);
    const creature = MonsterBookEntry(
      id: 'test_incoming_resistance_catalogue',
      nameIt: 'Creatura di prova',
      nameEn: 'Test creature',
      descIt: 'Creatura di prova per le resistenze.',
      descEn: 'Creature for resistance testing.',
      elementId: 'gelo',
      spriteAssetPath: '',
      isMiniBoss: false,
      isBoss: false,
      isNullFateless: false,
      damageResistancePresets: {
        'fuoco': 'Alta Resistenza',
        'ghiaccio': 'Resistenza',
      },
    );
    final original = probe.snapshot()
      ..['monsterBookSourceId'] = creature.id
      ..['incomingDamageElement'] = 'fuoco'
      ..['dannoOltreDifesa'] = true
      ..['dannoOltreScudi'] = true;
    probe.loadCampaign({
      ...probe.campaignSnapshot(),
      'schedePersonaggio': [original],
      'schedaCorrente': 0,
      'monsterBookCustomEntries': [creature.toJson()],
    });

    void load({String? savedPreset, String? savedPercentage}) {
      final sheet = {
        ...original,
        'incomingDamagePresets': {'fuoco': ?savedPreset},
        'dannoSubitoPercentuale': '',
        'dannoSubitoPercentualePerTipo': {'fuoco': ?savedPercentage},
      };
      state.schedePersonaggio[0] = sheet;
      probe.load(sheet);
      probe.recordCurrentEncounter();
    }

    Future<int> manualLoss() async {
      final initial = probe.currentHp();
      await probe.applyDamageInput('40');
      return initial - probe.currentHp();
    }

    Future<int> sharedLoss(String id, {int precisionStages = 0}) async {
      final attack = <String, dynamic>{
        'id': id,
        'sourceTag': 'ENEMY',
        'sourceName': 'Provocatore',
        'targetTag': probe.ownerTag(),
        'targetName': 'Creatura di prova',
        'scope': probe.permissionScope,
        'encounterId': probe.activeCombatEncounterId,
        'status': 'pending',
        'kind': 'attack',
        'choice': precisionStages > 0 ? 'precisione' : 'vc',
        'precisionFragilityStages': precisionStages,
        'precisionDamagePercent': 100,
        'attack': 30,
        'natural': 10,
        'damage': 40,
        'element': 'fuoco',
        'defenseElement': 'fisico',
        'level': 0,
        'grade': 0,
        'difficulty': 'normale',
      };
      state.onlineCombatRequests[id] = attack;
      await tester.runAsync(() => probe.resolveCombatDefense(attack, 'cm', 20));
      expect(attack['status'], 'resolved');
      return (attack['damageReceipt'] as Map)['hpLost'] as int;
    }

    load();
    expect(probe.incomingDamagePreset('fuoco'), 'Alta Resistenza');
    expect(probe.incomingDamagePreset('ghiaccio'), 'Resistenza');
    expect(probe.snapshot()['incomingDamagePresets'], isEmpty);
    expect(await manualLoss(), 20);
    expect(await sharedLoss('catalogue-resistance'), 20);

    load(savedPreset: 'Normale');
    expect(probe.incomingDamagePreset('fuoco'), 'Normale');
    expect(await manualLoss(), 40);
    expect(await sharedLoss('explicit-normal-resistance'), 40);

    load(savedPercentage: '0%');
    expect(await manualLoss(), 40);
    expect(await sharedLoss('explicit-zero-resistance'), 40);

    load(savedPercentage: '-25%');
    expect(
      await sharedLoss('explicit-percent-precision', precisionStages: 1),
      36,
    );

    await closeFixture(tester, probe);
  });
}
