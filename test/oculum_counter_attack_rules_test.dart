import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/game/oculum_opposed_attack.dart';

void main() {
  test('grade threshold returns damage only after a winning counterattack', () {
    for (var grade = 0; grade <= 12; grade++) {
      final minimum = 20 - grade ~/ 2;
      expect(oculumCounterReflectionNaturalMinimum(grade), minimum);
      for (var natural = 1; natural <= 20; natural++) {
        for (final counter in [16, 17, 19, 20, 21, 40]) {
          expect(
            oculumCounterReturnsDamage(
              incomingAttack: 20,
              counterAttack: counter,
              natural: natural,
              grade: grade,
            ),
            counter > 20 && natural >= minimum,
            reason: 'grade $grade natural $natural counter $counter',
          );
        }
        expect(
          oculumCounterReturnsDamage(
            incomingAttack: 20,
            counterAttack: 40,
            natural: natural,
            grade: grade,
            wouldRegenerateLife: true,
          ),
          isFalse,
        );
      }
    }
    expect(oculumCounterReflectionNaturalMinimum(-3), 20);
    expect(oculumCounterReflectionNaturalMinimum(1000), 2);
    for (final natural in [-1, 0, 1, 21]) {
      expect(
        oculumCounterReturnsDamage(
          incomingAttack: 20,
          counterAttack: 40,
          natural: natural,
          grade: 1000,
        ),
        isFalse,
      );
    }
  });
  test(
    'returned packet preserves the original hit but no offensive modifiers',
    () {
      final original = <String, dynamic>{
        'id': 'hit',
        'sourceTag': 'enemy',
        'sourceName': 'Enemy',
        'targetTag': 'hero',
        'scope': 'room',
        'encounterId': 'fight',
        'attack': 20,
        'damage': 71,
        'element': 'fulmine',
        'forcedCritical': true,
        'targetWeakPointPrecision': true,
        'effects': [
          {'type': 'danno', 'bypassShields': true},
        ],
      };
      final response = <String, dynamic>{
        'id': 'counter:hit',
        'sourceTag': 'hero',
        'sourceName': 'Hero',
        'targetTag': 'enemy',
        'scope': 'room',
        'encounterId': 'fight',
        'attack': 25,
        'natural': 19,
        'grade': 2,
        'level': 6,
        'damage': 10,
        'element': 'acqua',
        'forcedCritical': true,
      };
      final returned = oculumCounterReflectionPacket(original, response)!;
      expect(returned['damage'], 71);
      expect(returned['element'], 'fulmine');
      expect(returned['id'], 'counter-reflect:hit');
      expect(returned['sourceTag'], 'hero');
      expect(returned['targetTag'], 'enemy');
      expect(returned['natural'], 0);
      expect(returned['effects'], isEmpty);
      expect(returned.containsKey('forcedCritical'), isFalse);
      expect(returned.containsKey('targetWeakPointPrecision'), isFalse);
      for (final override in <Map<String, dynamic>>[
        {'attack': 20},
        {'natural': 18},
        {'grade': 1},
        {'id': 'wrong'},
        {'sourceTag': 'intruder'},
        {'targetTag': 'someone'},
        {'scope': 'another-room'},
        {'encounterId': 'another-fight'},
      ]) {
        expect(
          oculumCounterReflectionPacket(original, {...response, ...override}),
          isNull,
        );
      }
      expect(
        oculumCounterReflectionPacket({...original, 'damage': -1}, response),
        isNull,
      );
    },
  );
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
