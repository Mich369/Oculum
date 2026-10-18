import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  test('ability parser separates requirements, costs and real bonuses', () {
    final parsed = oculumParseAbilityMechanics(
      'Richiede livello 24. Costo: 5/5 Oculum.\n@VC+2 e +34 danni per 2 turni',
    );
    expect(parsed.effects, hasLength(2));
    expect(parsed.effects.first.target, 'VC');
    expect(parsed.effects.first.valueExpression, '2');
    expect(parsed.effects.last.valueExpression, '34');
    expect(parsed.effects.last.duration, '2');
  });
  test('ability parser keeps invested Oculum, dice and healing resources', () {
    final heal = oculumParseAbilityMechanics('recuperi 1d6 + Medicina Vita');
    expect(heal.effects.single.type, 'cura');
    expect(heal.effects.single.resource, 'vita');
    expect(heal.effects.single.valueExpression, '1d6 + Medicina');
    final damage = oculumParseAbilityMechanics(
      '+5 + Oculum danni',
      investedOculum: true,
    );
    expect(damage.effects.single.valueExpression, '5 + oculum_spent');
  });
  test('ability parser never turns costs or unknown prose into a bonus', () {
    final parsed = oculumParseAbilityMechanics(
      'Richiede livello 15. Costo: 11/30 Oculum.\nOsservi il cielo.',
    );
    expect(parsed.effects, isEmpty);
    expect(parsed.unrecognizedText, contains('Osservi il cielo'));
    expect(oculumParseAbilityCost('(11/30 Oculum)')?.maximum, 30);
    expect(oculumParseAbilityCost('spendi 2 Oculum')?.minimum, 2);
    expect(oculumParseAbilityCost('(8/2 Oculum)'), isNull);
  });
  test('critical bonus follows difficulty and only that bonus doubles', () {
    for (final entry in {
      'facile': 30,
      'normale': 20,
      'difficile': 10,
      'oculum': 5,
    }.entries) {
      final bonus = oculumCriticalDamageBonusForDifficulty(entry.key, 10);
      expect(bonus, entry.value);
      expect(
        oculumCriticalDamageBonusForDifficulty(entry.key, 10) * 2 + 51,
        51 + entry.value * 2,
      );
    }
    expect(oculumParseAbilityCost('costa 3 Oculum')?.minimum, 3);
    expect(
      oculumParseAbilityMechanics(
        'recuperi Vita massima/3 Vita',
      ).effects.single.valueExpression,
      'hp/3',
    );
  });
}
