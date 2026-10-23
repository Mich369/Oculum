import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
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
