import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  test('elemental spheres are distinct and retain editable forms in JSON', () {
    expect(oculumElementalSphereElements.toSet().length, 59);
    expect(oculumElementalSphereElements, isNot(contains('cura')));
    expect(oculumElementalSphereElements, isNot(contains('sconosciuto')));
    final item = oculumElementalSphereScrollItem('acido', 4, maxForm: 2);
    final saved = InventoryItem.fromJson(item.toJson());
    final scroll = Map<String, dynamic>.from(saved.craftData['scroll'] as Map);
    final skill = CharacterSkill.fromJson(
      Map<String, dynamic>.from(scroll['authoredSkill'] as Map),
    );
    expect(skill.id, 'elemental_sphere/acido');
    expect(skill.forme.length, 3);
    expect(scroll['maxForm'], 2);
    for (final (index, form) in skill.forme.indexed) {
      final marker = form.effettiStrutturati.singleWhere(
        (effect) => effect.target == oculumElementalSphereEffect,
      );
      expect(marker.elementType, 'acido');
      expect(marker.valueExpression, '${20 - index}');
      expect(marker.duration, '${3 * (index + 1)}');
      expect(form.effettiStrutturati.last.valueExpression, '${3 * index}');
      expect(form.cooldownStrutturato?.amount, 3 + index);
      final oculumCost = oculumElementalSphereEffectiveCost(
        form,
        possessesOculum: true,
        evaluateCost: int.parse,
      );
      final materiaCost = oculumElementalSphereEffectiveCost(
        form,
        possessesOculum: false,
        evaluateCost: int.parse,
      );
      expect(oculumCost?.resource, 'oculum');
      expect(oculumCost?.amountExpression, ['3', '6', '12'][index]);
      expect(materiaCost?.resource, 'materia');
      expect(materiaCost?.amountExpression, ['3', '5', '9'][index]);
      expect(form.costoStrutturato?.resource, 'oculum');
    }
    final topForm = oculumScrollCombatEffects(scroll);
    expect(topForm.first.valueExpression, '19');
    expect(topForm.last.valueExpression, '3');
  });

  test(
    'direct scroll keeps acquired form and legacy scroll defaults to III',
    () {
      for (final form in [1, 2, 3]) {
        final item = oculumElementalSphereScrollItem('acido', 0, maxForm: form);
        final scroll = Map<String, dynamic>.from(
          item.craftData['scroll'] as Map,
        );
        expect(scroll['willCost'], 0);
        expect(
          oculumScrollCombatEffects(scroll).first.valueExpression,
          '${21 - form}',
        );
      }
      final legacy = Map<String, dynamic>.from(
        oculumElementalSphereScrollItem('acido', 0).craftData['scroll'] as Map,
      )..remove('maxForm');
      expect(oculumScrollCombatEffects(legacy).first.valueExpression, '18');
    },
  );

  test(
    'scroll prices include exact form bands and preserve the paid price',
    () {
      const ranges = [
        (minimum: 56, maximum: 79),
        (minimum: 80, maximum: 98),
        (minimum: 99, maximum: 120),
        (minimum: 125, maximum: 160),
        (minimum: 169, maximum: 220),
      ];
      for (final (index, range) in ranges.indexed) {
        expect(oculumSkillScrollFormPriceRange(index + 1), range);
      }
      expect(oculumElementalSphereScrollPriceRange(5), ranges[2]);
      for (final (index, range) in ranges.take(3).indexed) {
        for (var seed = 0; seed < 20; seed++) {
          expect(
            oculumElementalSphereScrollPrice(index + 1, Random(seed)),
            inInclusiveRange(range.minimum, range.maximum),
          );
        }
      }
      final sphere = oculumElementalSphereScrollItem('acido', 0, maxForm: 2);
      expect(sphere.note, contains('80–98 Obser'));
      final bought = oculumElementalSphereScrollItem(
        'acido',
        0,
        maxForm: 2,
        paidObser: 83,
      );
      expect(bought.note, contains('Prezzo di acquisto: 83 Obser'));
    },
  );
}
