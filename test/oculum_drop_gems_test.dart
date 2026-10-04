import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  test('Drop above 15 awards level plus a weighted 1 to 26 Obser', () {
    final counts = <int, int>{};
    for (var ticket = 0; ticket < 351; ticket++) {
      final reward = oculumDropObserReward(
        subtraitId: 'drop',
        rollTotal: 16,
        level: 10,
        dropBonus: 4,
        random: _TicketRandom(ticket),
      );
      expect(reward, inInclusiveRange(15, 40));
      counts.update(reward - 14, (value) => value + 1, ifAbsent: () => 1);
    }
    for (var amount = 1; amount <= 26; amount++) {
      expect(
        counts[amount],
        27 - amount,
        reason: 'Obser amount $amount must have weight ${27 - amount}',
      );
    }
    for (final (id, total) in [('drop', 15), ('riflessi', 20)]) {
      expect(
        oculumDropObserReward(
          subtraitId: id,
          rollTotal: total,
          level: 10,
          dropBonus: 4,
          random: _TicketRandom(0),
        ),
        0,
      );
    }
  });
  const stats = {'resilienza': 9, 'materia': 90, 'volonta': 30, 'oculum': 24};
  test('only natural Drop 19 and 20 award a stat gem', () {
    for (var roll = 1; roll <= 20; roll++) {
      final item = oculumCreateTemporaryDropGem(
        subtraitId: 'drop',
        naturalRoll: roll,
        usesOculum: true,
        stats: stats,
        random: Random(roll),
      );
      expect(item != null, roll >= 19, reason: 'Natural Drop roll: $roll');
      if (item != null) {
        expect(item.quantita, 1);
        expect(item.statGemDieFaces, stats[item.statGemStat]! ~/ 3);
        expect(InventoryItem.fromJson(item.toJson()).toJson(), item.toJson());
      }
    }
    expect(
      oculumCreateTemporaryDropGem(
        subtraitId: 'riflessi',
        naturalRoll: 20,
        usesOculum: true,
        stats: stats,
        random: Random(1),
      ),
      isNull,
    );
  });

  test('gem pool excludes Oculum users without Oculum capacity', () {
    for (final usesOculum in [false, true]) {
      final obtained = <String>{};
      for (var seed = 0; seed < 256; seed++) {
        final item = oculumCreateTemporaryDropGem(
          subtraitId: 'drop',
          naturalRoll: 19,
          usesOculum: usesOculum,
          stats: stats,
          random: Random(seed),
        )!;
        obtained.add(item.statGemStat);
      }
      expect(
        obtained,
        unorderedEquals([
          'resilienza',
          'materia',
          'volonta',
          if (usesOculum) 'oculum',
        ]),
      );
    }
  });
}

class _TicketRandom implements Random {
  _TicketRandom(this.ticket);
  final int ticket;
  @override
  int nextInt(int max) {
    expect(ticket, lessThan(max));
    return ticket;
  }

  @override
  bool nextBool() => throw UnsupportedError('Unused');
  @override
  double nextDouble() => throw UnsupportedError('Unused');
}
