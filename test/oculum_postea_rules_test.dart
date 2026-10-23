import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/game/oculum_opposed_attack.dart';

void main() {
  test(
    'plane pressure uses strict success, near miss, high die and negative critical',
    () {
      expect(
        oculumPlanePressurePenalty(total: 22, natural: 12, areaGrade: 3),
        0,
      );
      expect(
        oculumPlanePressurePenalty(total: 21, natural: 12, areaGrade: 3),
        5,
      );
      expect(
        oculumPlanePressurePenalty(total: 18, natural: 12, areaGrade: 3),
        5,
      );
      expect(
        oculumPlanePressurePenalty(total: 17, natural: 12, areaGrade: 3),
        10,
      );
      expect(
        oculumPlanePressurePenalty(total: 10, natural: 18, areaGrade: 3),
        5,
      );
      expect(
        oculumPlanePressurePenalty(total: 30, natural: 1, areaGrade: 3),
        20,
      );
    },
  );
  test(
    'Diabolic is distinct and resists only incoming Demonic by 75 percent',
    () {
      expect(
        oculumElementalDefenseMultiplier(
          incomingElement: 'demoniaco',
          defenseElement: 'diabolico',
          currentHp: 10,
          maximumHp: 100,
        ),
        .25,
      );
      expect(
        oculumElementalDefenseMultiplier(
          incomingElement: 'diabolico',
          defenseElement: 'demoniaco',
          currentHp: 100,
          maximumHp: 100,
        ),
        1,
      );
      expect(oculumPlanes.where((p) => p.id == 'oblio').length, 1);
      expect(oculumPlanes.first.id, 'mezzano');
      expect(oculumPlanes.firstWhere((p) => p.id == 'sacro').minimumGrade, 3);
      expect(
        oculumPlanes.firstWhere((p) => p.id == 'vero_inferno').minimumGrade,
        9,
      );
      final effect = oculumEquipmentAbility(
        'Arma angelica',
        3,
        element: 'angelico',
      ).forme.first.effettiStrutturati.first;
      expect(effect.elementType, 'angelico');
    },
  );
  test(
    'Ash exhaustion starts strictly above level plus three and caps at 100%',
    () {
      expect(oculumAshReactionLossChance(8, 5), 0);
      expect(oculumAshReactionLossChance(9, 5), 29);
      expect(oculumAshReactionLossChance(80, 5), 100);
      expect(oculumAshReactionLossChance(200, 5), 100);
    },
  );
  test(
    'only VC and CM inflict disadvantage at the exact two-thirds threshold',
    () {
      expect(oculumVcCmInflictsDisadvantage('vc', 20, 12), isTrue);
      expect(oculumVcCmInflictsDisadvantage('cm', 20, 12), isTrue);
      expect(oculumVcCmInflictsDisadvantage('vc', 19, 12), isFalse);
      expect(oculumVcCmInflictsDisadvantage('cm', 9, 5), isTrue);
      expect(oculumVcCmInflictsDisadvantage('cm', 8, 5), isFalse);
      for (final choice in [
        'riflessi',
        'resistenza',
        'precisione',
        'schianto',
      ]) {
        expect(oculumVcCmInflictsDisadvantage(choice, 100, 10), isFalse);
      }
    },
  );
  test(
    'Mitra adds one editable nonpassive damage effect and preserves bypass JSON',
    () {
      final skill = oculumPosteaMitraAbility(15);
      final effect = skill.forme.single.effettiStrutturati.single;
      expect(effect.valueExpression, '15');
      expect(effect.recipient, 'nemico');
      expect(effect.bypassResistance, isTrue);
      expect(effect.bypassDefense, isFalse);
      expect(effect.bypassShields, isFalse);
      final restored = OculumStructuredEffect.fromJson(effect.toJson());
      expect(restored.bypassResistance, isTrue);
      expect(
        OculumStructuredEffect.fromJson({'type': 'danno'}).bypassResistance,
        isFalse,
      );
    },
  );
  test('boots cooldown is ready, lasts five turns, and survives JSON', () {
    final form = oculumPosteaBootsAbility().forme.single;
    expect(form.tipo, 'Difesa');
    expect(form.costoStrutturato!.resource, 'nessuna');
    final cd = form.cooldownStrutturato!;
    expect(cd.activate(), isTrue);
    for (var i = 0; i < 4; i++) {
      cd.tick('turni');
      expect(cd.ready, isFalse);
    }
    cd.tick('turni');
    expect(cd.ready, isTrue);
    expect(form.descrizione, contains('senza Azioni o Reazioni'));
  });
}
