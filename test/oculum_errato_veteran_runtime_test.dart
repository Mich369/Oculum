import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'oculum_escape_provoker_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

Map<String, dynamic> bandit(
  String id, {
  String tag = 'BANDIT',
  String side = 'enemy',
}) => {
  'id': tag,
  'sheetTag': tag,
  'side': side,
  'status': 'ready',
  'monsterBookId': id,
  'reportedTurn': 1,
};
Map<String, dynamic> victim({String tag = 'HERO', String status = 'downed'}) =>
    {
      'id': tag,
      'sheetTag': tag,
      'side': 'party',
      'status': status,
      'downed': status == 'downed',
      'currentHp': status == 'downed' ? 1 : 50,
    };

void main() {
  test(
    'Errato settlement waits for victory and excludes escaped or winning victims',
    () {
      final errato = bandit(oculumErratoMonsterId);
      expect(
        oculumErratoFightSettlements([errato, victim()]).single,
        containsPair('percent', 75),
      );
      expect(
        oculumErratoFightSettlements([errato, victim()]).single['lethal'],
        false,
      );
      expect(
        oculumErratoFightSettlements([errato, victim(status: 'ready')]),
        isEmpty,
      );
      expect(
        oculumErratoFightSettlements([errato, victim(status: 'fled')]),
        isEmpty,
      );
      expect(
        oculumErratoFightSettlements([
          errato,
          victim(),
          victim(tag: 'ALLY', status: 'ready'),
        ]),
        isEmpty,
      );
      expect(
        oculumErratoFightSettlements([
          {...errato, 'status': 'dead'},
          victim(),
        ]),
        isEmpty,
      );
      expect(
        oculumErratoFightSettlements([
          {...errato, 'status': 'fled'},
          victim(),
        ]),
        isEmpty,
      );
    },
  );
  test('living veteran upgrades the settlement; its aura does not stack', () {
    final vet = bandit(oculumVeteranErratoMonsterId);
    final second = bandit(oculumVeteranErratoMonsterId, tag: 'VET2');
    final result = oculumErratoFightSettlements([vet, victim()]).single;
    expect(result['percent'], 100);
    expect(result['lethal'], true);
    expect(
      oculumErratoVeteranWillPercent(oculumErratoMonsterId, 'enemy', [
        vet,
        second,
      ]),
      5,
    );
    expect(
      oculumErratoVeteranWillPercent(oculumVeteranErratoMonsterId, 'enemy', [
        vet,
        second,
      ]),
      15,
    );
    expect(
      oculumErratoVeteranWillPercent(oculumErratoMonsterId, 'party', [vet]),
      0,
    );
    expect(
      oculumErratoVeteranWillPercent(oculumErratoMonsterId, 'enemy', [
        {...vet, 'status': 'dead'},
      ]),
      0,
    );
    expect(
      oculumErratoVeteranWillPercent(oculumErratoMonsterId, 'enemy', [
        {...vet, 'status': 'fled'},
      ]),
      0,
    );
    expect(oculumErratoVeteranWillPercent('scostubanditi', 'enemy', [vet]), 0);
    expect(oculumScostuRobbedObser(4), 3);
  });
  testWidgets(
    'Errato steals three of four items and 75 percent Obser once, preserving Title Items and saves',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      state.obserController.text = '100';
      state.inventario.clear();
      for (var i = 0; i < 4; i++) {
        state.inventario.add(
          InventoryItem(nome: 'Oggetto $i', peso: 1, quantita: 1, note: ''),
        );
      }
      state.inventario.add(
        InventoryItem(
          nome: 'Titolo evocabile',
          peso: 1,
          quantita: 1,
          note: '',
          craftData: {'titleItem': true},
        ),
      );
      final hp = p.currentHp();
      p.scostuNonLethal(oculumErratoMonsterId);
      expect(
        state.obserController.text,
        '100',
        reason: 'no theft during the single blow',
      );
      final reward = <String, dynamic>{
        'id': 'errato-fight',
        'endedEncounterId': 'encounter_1',
        'scostuSettlements': [
          {'victimTag': p.ownerTag(), 'percent': 75, 'lethal': false},
        ],
      };
      p.encounterRewards([reward]);
      expect(state.obserController.text, '25');
      expect(
        (state.inventario as List).where(
          (i) => i.craftData['titleItem'] != true,
        ),
        hasLength(1),
      );
      expect(
        (state.inventario as List).where(
          (i) => i.craftData['titleItem'] == true,
        ),
        hasLength(1),
      );
      expect(p.currentHp(), hp);
      p.load(p.snapshot());
      p.encounterRewards([reward]);
      expect(state.obserController.text, '25');
      expect(state.inventario.length, 2);
      await closeFixture(tester, p);
    },
  );
  testWidgets(
    'veteran kills only at settlement and takes all ordinary quantities',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      state.obserController.text = '250';
      state.inventario.clear();
      state.inventario.add(
        InventoryItem(nome: 'Materiale', peso: 1, quantita: 8, note: ''),
      );
      state.inventario.add(
        InventoryItem(
          nome: 'Titolo',
          peso: 1,
          quantita: 1,
          note: '',
          craftData: {'titleItem': true},
        ),
      );
      p.scostuNonLethal(oculumVeteranErratoMonsterId);
      expect(p.currentHp(), greaterThan(0));
      expect(state.obserController.text, '250');
      p.encounterRewards([
        {
          'id': 'veteran-fight',
          'scostuSettlements': [
            {'victimTag': p.ownerTag(), 'percent': 100, 'lethal': true},
          ],
        },
      ]);
      expect(state.obserController.text, '0');
      expect(p.currentHp(), 0);
      expect(state.feriteMorte, 3);
      expect(state.inventario.length, 1);
      expect(state.inventario.first.craftData['titleItem'], true);
      await closeFixture(tester, p);
    },
  );
  testWidgets('a captive healed above one HP is able to rejoin the fight', (
    tester,
  ) async {
    final (state, p) = await fixtures.mountFight(tester);
    state.currentHpController.text = '1';
    state.personaggioCaduto = false;
    p.scostuNonLethal(oculumErratoMonsterId);
    expect(state.masterInitiativeTokens.first['downed'], true);
    state.currentHpController.text = '15';
    p.scostuSyncDeath();
    expect(state.masterInitiativeTokens.first['downed'], false);
    expect(state.masterInitiativeTokens.first['scostuNonLethalDowned'], isNull);
    expect(state.masterInitiativeTokens.first['scostuDeferredDefeat'], isNull);
    await closeFixture(tester, p);
  });
  testWidgets(
    'veteran target bonus is refreshed not stacked and expires on defense or next veteran turn',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      final tag = p.ownerTag();
      state.schedePersonaggio[state.schedaCorrente]['monsterBookSourceId'] =
          oculumErratoMonsterId;
      state.masterInitiativeTokens
        ..clear()
        ..addAll([
          bandit(oculumErratoMonsterId, tag: tag),
          bandit(oculumVeteranErratoMonsterId, tag: 'VET'),
          {...victim(tag: 'TARGET', status: 'ready'), 'side': 'party'},
        ]);
      p.recordCurrentEncounter();
      final hit = <String, dynamic>{
        'id': 'hit1',
        'sourceTag': 'VET',
        'targetTag': 'TARGET',
        'sourceMonsterBookId': oculumVeteranErratoMonsterId,
        'attack': 30,
        'defense': 20,
        'outcome': 'full',
      };
      p.scostuCoordination(hit);
      p.recordCurrentEncounter();
      expect(p.scostuAccuracy('TARGET'), 2);
      p.scostuCoordination({...hit, 'id': 'hit2'});
      p.recordCurrentEncounter();
      expect(p.scostuAccuracy('TARGET'), 2);
      expect(p.scostuAccuracy('OTHER'), 0);
      p.scostuCoordination({
        ...hit,
        'id': 'defense',
        'outcome': 'avoided',
        'attack': 10,
        'defense': 20,
      });
      p.recordCurrentEncounter();
      expect(p.scostuAccuracy('TARGET'), 0);
      p.scostuCoordination({...hit, 'id': 'hit3'});
      p.recordCurrentEncounter();
      expect(p.scostuAccuracy('TARGET'), 2);
      state.masterInitiativeTokens[1]['reportedTurn'] = 2;
      p.recordCurrentEncounter();
      expect(p.scostuAccuracy('TARGET'), 0);
      await closeFixture(tester, p);
    },
  );
}
