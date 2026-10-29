import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'oculum_escape_provoker_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

void main() {
  test(
    'HP multipliers follow the confirmed first three levels of every Grade',
    () {
      for (var grade = 0; grade <= 12; grade++) {
        for (var offset = 0; offset <= 9; offset++) {
          final expected =
              (offset == 0
                  ? 6
                  : offset <= 2
                  ? 9
                  : 10) +
              grade * 5;
          expect(
            oculumHpMultiplierForGrade(grade, level: grade * 10 + offset),
            expected,
            reason: 'Grade $grade, level ${grade * 10 + offset}',
          );
        }
      }
      expect(oculumHpMultiplierForGrade(0, level: 0), 6);
      expect(oculumHpMultiplierForGrade(0, level: 1), 9);
      expect(oculumHpMultiplierForGrade(0, level: 2), 9);
      expect(oculumHpMultiplierForGrade(0, level: 3), 10);
      expect(oculumHpMultiplierForGrade(1, level: 10), 11);
      expect(oculumHpMultiplierForGrade(1, level: 11), 14);
      expect(oculumHpMultiplierForGrade(1, level: 13), 15);
      expect(oculumHpMultiplierForGrade(2, level: 20), 16);
      expect(oculumHpMultiplierForGrade(2, level: 22), 19);
      expect(oculumHpMultiplierForGrade(2, level: 23), 20);
      expect(
        oculumHpMultiplierForGrade(1),
        15,
        reason: 'Missing level keeps incomplete legacy payloads compatible',
      );
      expect(
        oculumHpMultiplierForGrade(1, level: 6),
        15,
        reason: 'A manually set Grade retains the level-decade phase',
      );
    },
  );

  test(
    'remote HP recalculates saved multiplier once and preserves flat HP bonuses',
    () {
      final old = <String, dynamic>{
        'livello': '1',
        'grado': '0',
        'resilienza': '5',
        'derivedResilienzaTotal': 5,
        'derivedMaxHp': 57,
        'hpGradeMultiplier': 10,
        'manualHpMaximumAdjustment': 7,
        'currentHp': '40',
      };
      expect(oculumSheetHpMaximum(old), 52);
      expect(
        old['currentHp'],
        '40',
        reason: 'Recalculation never heals a save',
      );
      final migrated = {...old, 'derivedMaxHp': 52, 'hpGradeMultiplier': 9};
      expect(
        oculumSheetHpMaximum(migrated),
        52,
        reason: 'Repeated JSON round trips do not scale again',
      );
      expect(oculumSheetHpMaximum({...old, 'livello': '0'}), 37);
      expect(oculumSheetHpMaximum({...old, 'livello': '3'}), 57);
      expect(
        oculumSheetHpMaximum({
          'livello': 10,
          'grado': 1,
          'resilienza': 5,
          'derivedResilienzaTotal': 5,
          'derivedMaxHp': 75,
          'hpGradeMultiplier': 15,
        }),
        55,
      );
      expect(
        oculumSheetHpMaximum({
          'livello': 20,
          'grado': 2,
          'resilienza': 5,
          'derivedResilienzaTotal': 5,
          'derivedMaxHp': 100,
          'hpGradeMultiplier': 20,
        }),
        80,
      );
    },
  );

  test(
    'explicit summon HP and mecha-body HP remain independent of Resilience',
    () {
      final base = <String, dynamic>{
        'livello': 1,
        'grado': 0,
        'resilienza': 12,
        'derivedResilienzaTotal': 12,
        'hpGradeMultiplier': 10,
        'derivedMaxHp': 9,
      };
      expect(
        oculumSheetHpMaximum({
          ...base,
          'planarRuntime': {'senkaClone': true},
        }),
        9,
      );
      expect(
        oculumSheetHpMaximum({...base, 'shadowCloneOwnerTag': 'owner'}),
        9,
      );
      expect(oculumSheetHpMaximum({...base, 'oculumShadowClone': true}), 9);
      expect(
        oculumSheetHpMaximum({
          ...base,
          'planarRuntime': {'doppioneCopy': true},
        }),
        1,
      );
      expect(
        oculumSheetHpMaximum({
          ...base,
          'planarRuntime': {'mechaBodyMaxHp': 147},
        }),
        147,
      );
    },
  );

  testWidgets(
    'loaded HP clamps only at the new maximum without refilling wounds',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      final base = p.snapshot();
      for (final entry in [
        (level: 0, grade: 0, multiplier: 6),
        (level: 1, grade: 0, multiplier: 9),
        (level: 2, grade: 0, multiplier: 9),
        (level: 3, grade: 0, multiplier: 10),
        (level: 10, grade: 1, multiplier: 11),
        (level: 11, grade: 1, multiplier: 14),
        (level: 13, grade: 1, multiplier: 15),
        (level: 20, grade: 2, multiplier: 16),
      ]) {
        final sheet = <String, dynamic>{
          ...base,
          'livello': '${entry.level}',
          'grado': '${entry.grade}',
          'currentHp': '1',
          'planarRuntime': <String, dynamic>{},
        };
        state.schedePersonaggio[state.schedaCorrente] = sheet;
        p.load(sheet);
        p.invalidateDerivedCaches();
        expect(p.hpMultiplier(), entry.multiplier);
        expect(p.currentHp(), 1);
        state.currentHpController.text = '${p.maximumHp() + 80}';
        expect(p.currentHp(), p.maximumHp());
        final roundTrip = p.snapshot();
        expect(roundTrip['hpGradeMultiplier'], entry.multiplier);
        expect(readIntValue(roundTrip['currentHp']), p.maximumHp());
        expect(oculumSheetHpMaximum(roundTrip), p.maximumHp());
      }
      final clone = {
        ...base,
        'livello': '1',
        'grado': '0',
        'currentHp': '7',
        'derivedMaxHp': 9,
        'planarRuntime': {'senkaClone': true},
      };
      state.schedePersonaggio[state.schedaCorrente] = clone;
      p.load(clone);
      expect(p.maximumHp(), 9);
      expect(p.currentHp(), 7);
      await closeFixture(tester, p);
    },
  );
}
