import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  test(
    'Drop rewards natural 16 to 20 only, at most three before Long Rest',
    () {
      var earned = 0;
      for (final roll in [1, 15, 16, 18, 20, 19, 20]) {
        if (oculumCanReceiveDustFromDrop(
          subtraitId: 'drop',
          naturalRoll: roll,
          earnedSinceLongRest: earned,
        )) {
          earned++;
        }
      }
      expect(earned, 3);
      expect(
        oculumCanReceiveDustFromDrop(
          subtraitId: 'eco',
          naturalRoll: 20,
          earnedSinceLongRest: 0,
        ),
        isFalse,
      );
      expect(
        oculumCanReceiveDustFromDrop(
          subtraitId: 'drop',
          naturalRoll: 15,
          earnedSinceLongRest: 0,
        ),
        isFalse,
      );
      expect(
        oculumCanReceiveDustFromDrop(
          subtraitId: 'drop',
          naturalRoll: 16,
          earnedSinceLongRest: 0,
        ),
        isTrue,
      );
      expect(
        oculumFallenEyeDropCreatesOnNaturalTwenty(
          subtraitId: 'drop',
          naturalRoll: 20,
        ),
        isTrue,
      );
    },
  );
  test('Dust gives +2, locks one choice and enforces three per session', () {
    final dust = OculumDustCombatBoost();
    expect(dust.consume('attacco', 2, available: 10), isTrue);
    expect(dust.attackBonus, 4);
    expect(dust.consume('difesa', 1, available: 8), isFalse);
    expect(dust.consume('attacco', 2, available: 8), isFalse);
    expect(dust.consume('attacco', 1, available: 8), isTrue);
    expect(dust.attackBonus, 6);
    expect(dust.consume('attacco', 1, available: 7), isFalse);
    dust.longRest();
    expect(dust.attackBonus, 3);
    expect(dust.used, 3);
    expect(dust.choice, 'attacco');
    expect(dust.consume('attacco', 1, available: 7), isFalse);
    dust.newSession();
    expect(dust.consume('difesa', 3, available: 7), isTrue);
    expect(dust.defenseBonus, 6);
    expect(dust.attackBonus, 3);
    dust.longRest();
    dust.longRest();
    expect(dust.defenseBonus, 3);
  });

  test(
    'Dust survives saving, switching sheets and new sessions before rest',
    () {
      final dust = OculumDustCombatBoost();
      expect(dust.consume('difesa', 1, available: 0), isFalse);
      expect(dust.consume('difesa', 0, available: 5), isFalse);
      expect(dust.consume('oculum', 1, available: 5), isFalse);
      expect(dust.consume('difesa', 2, available: 5), isTrue);
      final restored = OculumDustCombatBoost.fromJson(dust.toJson());
      expect(restored.toJson(), dust.toJson());
      restored.newSession();
      expect(restored.defenseBonus, 4);
      restored.longRest();
      expect(restored.defenseBonus, 2);
      expect(OculumDustCombatBoost.fromJson(null).attackBonus, 0);
      expect(OculumDustCombatBoost.fromJson(null).remaining, 3);
    },
  );
}
