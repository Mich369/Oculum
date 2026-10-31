import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'oculum_oblivion_percentage_parser_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

Future<(dynamic, OculumPerformanceProbe)> setup(WidgetTester tester) async {
  final (s, p) = await fixtures.cleanFight(tester);
  s.resilienzaController.text = '10';
  s.currentHpController.text = '60';
  s.materiaController.text = '0';
  s.oculumController.text = '0';
  for (final dynamic stat in s.hiddenEyeStats) {
    stat.valore = 0;
  }
  s.inventario.add(oculumAntiCorruptionStone());
  s.schedePersonaggio[0]['monsterBookSourceId'] = '';
  p.saveSheet();
  final target = jsonDecode(jsonEncode(p.snapshot())) as Map<String, dynamic>;
  target.addAll({
    'id': 'ENEMY',
    'sheetTag': 'ENEMY',
    'nome': 'Manichino di Baghest',
    'monsterBookSourceId': 'manichino_baghest',
    'inventario': <dynamic>[],
    'conditions': <dynamic>[],
  });
  s.schedePersonaggio.add(target);
  s.schedaCorrente = 1;
  p.load(target);
  p.initializeBaghest();
  p.saveSheet();
  final targetTag = p.ownerTag();
  s.schedaCorrente = 0;
  p.load(s.schedePersonaggio[0]);
  s.masterInitiativeTokens[0].addAll({'currentHp': 60, 'actionsUsed': 0});
  s.masterInitiativeTokens[1].addAll({
    'id': targetTag,
    'sheetTag': targetTag,
    'currentHp': 60,
    'monsterBookSourceId': 'manichino_baghest',
  });
  return (s, p);
}

void main() {
  test('two puppets have distinct IDs, artwork sides and editable rules', () {
    final base = monsterBookEntryById('manichino_spada')!;
    final red = monsterBookEntryById('manichino_baghest')!;
    expect(base.descIt, contains('sinistro'));
    expect(base.descIt, contains('viola'));
    expect(red.descIt, contains('destro'));
    expect(red.encounterRules['initialCorruptionNights'], 3);
    expect(red.skillIds.take(3), base.skillIds.take(3));
    expect(MonsterBookEntry.fromJson(red.toJson()).id, 'manichino_baghest');
    for (final monster in [base, red]) {
      final parts = oculumMonsterPrecisionAnatomy(monster);
      expect(parts.where((p) => p['group'] == 'arms'), hasLength(2));
      expect(parts.where((p) => p['group'] == 'legs'), hasLength(2));
      expect(parts.where((p) => p['group'] == 'eyes'), hasLength(1));
    }
    expect(oculumIsAntiCorruptionStone(oculumAntiCorruptionStone()), true);
    expect(
      oculumIsAntiCorruptionStone(
        InventoryItem(
          nome: 'Anti-corruzione',
          peso: .1,
          quantita: 1,
          note: '',
          craftData: {'antiCorruption': true},
        ),
      ),
      false,
    );
  });

  testWidgets(
    'success spends one Action and last stone, dissolves without a kill, persists once',
    (tester) async {
      final (s, p) = await setup(tester);
      final result = await p.purifyBaghest(
        '${s.schedePersonaggio[0]['sheetTag']}',
        '${s.schedePersonaggio[1]['sheetTag']}',
        20,
        1,
      );
      expect(
        result,
        true,
        reason:
            '${s.schedePersonaggio.map((e) => [e['sheetTag'], e['monsterBookSourceId']]).toList()} | ${s.masterInitiativeTokens} | ${p.snapshot()['logEventi']}',
      );
      expect(s.schedaCorrente, 0);
      expect(s.inventario, isEmpty);
      expect(s.schedePersonaggio[0]['inventario'], isEmpty);
      expect(s.masterInitiativeTokens[0]['lastTurnResource'], 'azione');
      expect(s.masterInitiativeTokens[1]['status'], 'expired');
      expect(oculumEncounterEnemyKilled(s.masterInitiativeTokens[1]), false);
      expect(s.schedePersonaggio[1]['baghestPurified'], true);
      expect(s.schedePersonaggio[1]['currentHp'], '60');
      expect(
        (s.schedePersonaggio[1]['conditions'] as List).where(
          (c) => c['conditionType'] == 'corruzione',
        ),
        isEmpty,
      );
      final log = '${s.schedePersonaggio[0]['logEventi']}';
      expect(log, contains('Sconfitta pacifica'));
      expect(
        await p.purifyBaghest(
          '${s.schedePersonaggio[0]['sheetTag']}',
          '${s.schedePersonaggio[1]['sheetTag']}',
          20,
          1,
        ),
        false,
      );
      p.load(jsonDecode(jsonEncode(s.schedePersonaggio[0])));
      expect(s.inventario, isEmpty);
      await closeFixture(tester, p);
    },
  );

  testWidgets('failure spends Action but no stone and preserves corruption', (
    tester,
  ) async {
    final (s, p) = await setup(tester);
    expect(
      await p.purifyBaghest(
        '${s.schedePersonaggio[0]['sheetTag']}',
        '${s.schedePersonaggio[1]['sheetTag']}',
        1,
        20,
      ),
      false,
    );
    expect(s.inventario.single.quantita, 1);
    expect(s.masterInitiativeTokens[0]['lastTurnResource'], 'azione');
    expect(s.masterInitiativeTokens[1]['status'], isNot('expired'));
    expect(s.schedePersonaggio[1]['baghestPurified'], isNot(true));
    final conditions = s.schedePersonaggio[1]['conditions'] as List;
    expect(conditions.single['metadata']['elapsedNights'], 3);
    expect(conditions.single['metadata']['corruptionKind'], 'rossa');
    await closeFixture(tester, p);
  });

  testWidgets('missing stone does not roll, spend Action or create a defeat', (
    tester,
  ) async {
    final (s, p) = await setup(tester);
    s.inventario.clear();
    s.schedePersonaggio[0]['inventario'] = <dynamic>[];
    expect(
      await p.purifyBaghest(
        '${s.schedePersonaggio[0]['sheetTag']}',
        '${s.schedePersonaggio[1]['sheetTag']}',
        20,
        1,
      ),
      false,
    );
    expect(s.masterInitiativeTokens[0]['lastTurnResource'], isNot('azione'));
    expect(s.masterInitiativeTokens[1]['status'], 'ready');
    await closeFixture(tester, p);
  });

  testWidgets('saving the last removed condition does not resurrect it', (
    tester,
  ) async {
    final (s, p) = await setup(tester);
    s.schedaCorrente = 1;
    p.load(s.schedePersonaggio[1]);
    expect(p.conditions, isNotEmpty);
    s.activeConditions.clear();
    p.saveSheet();
    expect(p.snapshot()['conditions'], isEmpty);
    p.load(jsonDecode(jsonEncode(s.schedePersonaggio[1])));
    expect(p.conditions, isEmpty);
    await closeFixture(tester, p);
  });

  testWidgets('a tied purification preserves the stone and spends the Action', (
    tester,
  ) async {
    final (s, p) = await setup(tester);
    expect(
      await p.purifyBaghest(
        '${s.schedePersonaggio[0]['sheetTag']}',
        '${s.schedePersonaggio[1]['sheetTag']}',
        10,
        10,
      ),
      false,
    );
    expect(s.inventario.single.quantita, 1);
    expect(s.masterInitiativeTokens[0]['actionUsed'], true);
    await closeFixture(tester, p);
  });

  testWidgets(
    'no available Action cannot spend a stone or roll a purification',
    (tester) async {
      final (s, p) = await setup(tester);
      s.masterInitiativeTokens[0]['actionUsed'] = true;
      expect(
        await p.purifyBaghest(
          '${s.schedePersonaggio[0]['sheetTag']}',
          '${s.schedePersonaggio[1]['sheetTag']}',
          20,
          1,
        ),
        false,
      );
      expect(s.inventario.single.quantita, 1);
      expect(s.schedePersonaggio[1]['baghestPurified'], isNot(true));
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'connected Player cannot purify enemy sheets even with stale local data',
    (tester) async {
      final (s, p) = await setup(tester);
      s.modalitaMaster = false;
      s.isMasterHost = false;
      s.sonoCoMaster = false;
      s.isConnectedToMaster = true;
      expect(
        await p.purifyBaghest(
          '${s.schedePersonaggio[0]['sheetTag']}',
          '${s.schedePersonaggio[1]['sheetTag']}',
          20,
          1,
        ),
        false,
      );
      expect(s.inventario.single.quantita, 1);
      expect(s.masterInitiativeTokens[0]['actionUsed'], isNot(true));
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'new scene and ordinary puppet cannot be purified by this exception',
    (tester) async {
      final (s, p) = await setup(tester);
      s.schedePersonaggio[1]['monsterBookSourceId'] = 'manichino_spada';
      expect(
        await p.purifyBaghest(
          '${s.schedePersonaggio[0]['sheetTag']}',
          '${s.schedePersonaggio[1]['sheetTag']}',
          20,
          1,
        ),
        false,
      );
      expect(s.inventario.single.quantita, 1);
      expect(s.masterInitiativeTokens[0]['lastTurnResource'], isNot('azione'));
      await closeFixture(tester, p);
    },
  );
}
