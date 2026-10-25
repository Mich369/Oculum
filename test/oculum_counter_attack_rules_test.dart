import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/game/oculum_opposed_attack.dart';

void main() {
  test(
    'counterattack boundaries and odd damage round down before protection',
    () {
      expect(oculumCounterAttackPercentages(20, 21), (
        incomingPercent: 0,
        outgoingPercent: 100,
      ));
      expect(oculumCounterAttackPercentages(20, 20), (
        incomingPercent: 50,
        outgoingPercent: 50,
      ));
      expect(oculumCounterAttackPercentages(20, 19), (
        incomingPercent: 75,
        outgoingPercent: 25,
      ));
      expect(oculumCounterAttackPercentages(20, 17), (
        incomingPercent: 75,
        outgoingPercent: 25,
      ));
      expect(oculumCounterAttackPercentages(20, 16), (
        incomingPercent: 100,
        outgoingPercent: 0,
      ));
      expect(oculumCounterAttackDamage(31, 50), 15);
      expect(oculumCounterAttackDamage(31, 75), 23);
      expect(oculumCounterAttackDamage(31, 25), 7);
      expect(oculumCounterAttackDamage(-1, 100), 0);
      expect(oculumAttackOutcome(20, 20), OculumAttackOutcome.avoided);
    },
  );
  test(
    'fast reaction bonus applies to its roll, with first participant exception',
    () {
      expect(oculumFastReactionRollBonus(initiativeIndex: 0, round: 0), 6);
      expect(oculumFastReactionRollBonus(initiativeIndex: 1, round: 0), 3);
      expect(oculumFastReactionRollBonus(initiativeIndex: 0, round: 1), 3);
    },
  );
}
