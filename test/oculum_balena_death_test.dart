import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

void main() {
  final receipt = <String, dynamic>{
    'status': 'resolved',
    'outcome': 'full',
    'targetFightInstance': 'fight-1',
    'damageReceipt': {'hpLost': 18, 'targetDownedByHit': true},
  };

  test('a whale knockout only hides the identity once death is confirmed', () {
    final victim = <String, dynamic>{
      'name': 'Nerea',
      'status': 'downed',
      'fightInstanceId': 'fight-1',
      'fightPlaneId': 'affogato',
    };
    oculumRecordBalenaKnockout(
      victim,
      receipt,
      sourceMonsterId: oculumBalenaMilleOcchiId,
    );
    expect(oculumConfirmCombatDeathMetadata(victim), isFalse);
    expect(oculumReferenceEncounterTokenName(victim), 'Nerea');
    victim['status'] = 'dead';
    expect(oculumConfirmCombatDeathMetadata(victim), isTrue);
    expect(oculumReferenceEncounterTokenName(victim), 'Identità dimenticata');
    expect(victim['name'], 'Nerea');
    expect(victim['deathPlaneId'], 'affogato');
    victim['fightPlaneId'] = 'mezzano';
    expect(oculumConfirmCombatDeathMetadata(victim), isFalse);
    expect(victim['deathPlaneId'], 'affogato');
  });

  test('old fights and shield damage cannot attribute a whale death', () {
    for (final invalid in [
      {...receipt, 'targetFightInstance': 'previous-fight'},
      {...receipt, 'outcome': 'avoided'},
      {
        ...receipt,
        'damageReceipt': {'hpLost': 0, 'targetDownedByHit': true},
      },
      {
        ...receipt,
        'damageReceipt': {'hpLost': 18, 'targetDownedByHit': false},
      },
    ]) {
      final victim = <String, dynamic>{
        'name': 'Nerea',
        'status': 'dead',
        'fightInstanceId': 'fight-1',
        'fightPlaneId': 'mezzano',
      };
      oculumRecordBalenaKnockout(
        victim,
        invalid,
        sourceMonsterId: oculumBalenaMilleOcchiId,
      );
      expect(oculumConfirmCombatDeathMetadata(victim), isFalse);
      expect(oculumReferenceEncounterTokenName(victim), 'Nerea');
      expect(victim['deathPlaneId'], 'mezzano');
    }
  });

  test('a new knockout replaces the whale as the cause', () {
    final victim = <String, dynamic>{
      'status': 'downed',
      'fightInstanceId': 'fight-1',
    };
    oculumRecordBalenaKnockout(
      victim,
      receipt,
      sourceMonsterId: oculumBalenaMilleOcchiId,
    );
    oculumRecordBalenaKnockout(victim, receipt, sourceMonsterId: 'altro');
    victim['status'] = 'dead';
    expect(oculumConfirmCombatDeathMetadata(victim), isFalse);
    expect(victim.containsKey('deathPlaneId'), isFalse);
  });
}
