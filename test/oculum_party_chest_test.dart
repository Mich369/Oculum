import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  test('capacity includes each registered member and half each level', () {
    expect(
      oculumPartyChestCapacity([
        {'level': 2},
        {'level': 4},
        {'level': 6},
      ]),
      9,
    );
  });
  test(
    'shared withdrawals serialize, cannot overspend, and retry only once',
    () {
      var state = <String, dynamic>{'obser': 100};
      final a = {
        'id': 'a',
        'requesterTag': 'A',
        'operation': 'withdraw_obser',
        'amount': 70,
      };
      state = oculumApplyPartyChestOperation(state, a);
      expect(state['obser'], 30);
      state = oculumApplyPartyChestOperation(state, a);
      expect(state['obser'], 30);
      state = oculumApplyPartyChestOperation(state, {
        'id': 'b',
        'operation': 'withdraw_obser',
        'amount': 70,
      });
      expect(state['obser'], 30);
      expect((state['receipts'] as Map)['b']['approved'], false);
    },
  );
  test('item deposits respect capacity and withdrawals preserve JSON', () {
    var state = <String, dynamic>{
      'members': {
        'A': {'level': 2},
      },
    };
    final item = {
      'nome': 'Spada',
      'peso': 1.5,
      'quantita': 1,
      'buff': '@Danni+15',
      'craftData': {'custom': 42},
    };
    state = oculumApplyPartyChestOperation(state, {
      'id': 'a',
      'operation': 'deposit_item',
      'item': item,
    });
    expect((state['items'] as List).length, 1);
    state = oculumApplyPartyChestOperation(state, {
      'id': 'b',
      'operation': 'deposit_item',
      'item': item,
    });
    expect((state['items'] as List).length, 1);
    state = oculumApplyPartyChestOperation(state, {
      'id': 'c',
      'operation': 'withdraw_item',
      'entryId': 'a',
      'amount': 1,
    });
    expect((state['items'] as List), isEmpty);
    expect((state['receipts'] as Map)['c']['item']['craftData']['custom'], 42);
  });
  test('species rewards persist across sessions and credit only once', () {
    Map<String, dynamic> records = {};
    for (var i = 0; i < 3; i++) {
      final reward = oculumPartySpeciesRewards(records, [
        {
          'id': 'enemy',
          'monsterBookId': 'slime_blu',
          'statsTotal': 20,
          'source': 'Mostro',
        },
      ], 'fight$i');
      expect(reward.earned, i == 2 ? 70 : 0);
      records = reward.records;
    }
    expect(
      oculumPartySpeciesRewards(records, [
        {
          'id': 'enemy',
          'monsterBookId': 'slime_blu',
          'statsTotal': 20,
          'source': 'Mostro',
        },
      ], 'fight4').earned,
      0,
    );
    expect(oculumItemTitleDustCost(0), 3);
    expect(oculumItemTitleDustCost(3), 3);
  });
}
