import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  test(
    'PT aliases and fractions are formula variables rather than elements',
    () {
      for (final expr in ['PT', 'pt', 'potenza_totale', 'PotenzaTotale']) {
        final command = oculumParseFormulaCommands('@Danni+$expr', {
          'danni': 5,
          'potenza_totale': 101,
        }).single;
        expect(command.valid, isTrue, reason: expr);
        expect(command.value, 101);
        expect(command.elementId, isEmpty);
      }
      expect(
        oculumParseFormulaCommands('@Danni+PT/2', {
          'danni': 5,
          'potenza_totale': 101,
        }).single.value,
        50,
      );
    final passive = oculumPassiveQuickTextWithoutTotalPower('@Danni+PT; @Difesa+3');
    expect(passive, isNot(contains('PT')));
    final remaining = oculumParseFormulaCommands(passive, {'difesa': 0});
    expect(remaining.single.key, 'difesa');
    expect(remaining.single.value, 3);
    },
  );
  test('PT exhaustion sums only power shares across one activation', () {
    OculumStructuredEffect effect(String value) =>
        OculumStructuredEffect(valueExpression: value);
    const vars = <String, num>{'potenza_totale': 100};
    expect(oculumTotalPowerExhaustionChance([effect('PT')], vars), 100);
    expect(oculumTotalPowerExhaustionChance([effect('PT/2+30')], vars), 50);
    expect(oculumTotalPowerExhaustionChance([effect('PT/4')], vars), 25);
    expect(
      oculumTotalPowerExhaustionChance([effect('PT/2'), effect('PT/2')], vars),
      100,
    );
    expect(oculumTotalPowerExhaustionChance([effect('PT*2')], vars), 100);
    expect(oculumTotalPowerExhaustionChance([effect('30')], vars), 0);
  });
  test(
    'all cost spellings load visible quantities and replace stale guided amounts',
    () {
      for (final text in ['Materia 1', '1 Materia', '@mat-1']) {
        final form = CharacterSkillForm.fromJson({
          'nome': 'I',
          'costo': text,
          'oculumMinimoUtilizzabile': 0,
          'oculumMassimoUtilizzabile': 0,
        });
        final cost = oculumCharacterSkillFormCost(form)!;
        expect([cost.resource, cost.minimum, cost.maximum], ['materia', 1, 1]);
        expect(
          [form.oculumMinimoUtilizzabile, form.oculumMassimoUtilizzabile],
          [1, 1],
        );
        final restored = CharacterSkillForm.fromJson(form.toJson());
        expect(oculumCharacterSkillFormCost(restored)!.minimum, 1);
      }
      final guided = CharacterSkillForm(
        costo: 'Materia',
        costoStrutturato: OculumSkillCost(
          resource: 'materia',
          minimum: 1,
          maximum: 1,
          amountExpression: '1',
        ),
        oculumMinimoUtilizzabile: 1,
        oculumMassimoUtilizzabile: 1,
      );
      oculumSetCharacterSkillCostText(guided, 'Obser 2/5');
      final cost = oculumCharacterSkillFormCost(guided)!;
      expect([cost.resource, cost.minimum, cost.maximum], ['obser', 2, 5]);
      oculumSetCharacterSkillCostText(guided, 'costo non riconosciuto');
      expect(oculumCharacterSkillFormCost(guided), isNull);
    },
  );
}
