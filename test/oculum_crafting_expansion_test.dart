import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/services/oculum_diary_links.dart';
import 'package:oculum/services/oculum_diary_memory.dart';
import 'package:oculum/services/oculum_diary_roles.dart';

void main() {
  test(
    'Fantasy materials cover 20 grade-zero names and every higher grade',
    () {
      expect(
        oculumFantasyCraftingMaterials.where((m) => m.grade == 0).length,
        greaterThanOrEqualTo(20),
      );
      for (var grade = 1; grade <= 12; grade++) {
        expect(
          oculumFantasyCraftingMaterials.any((m) => m.grade == grade),
          isTrue,
        );
      }
    },
  );
  test(
    'Weak and strong gauntlets retain exact ingredients, grade and equipped skill',
    () {
      final recipes = oculumAdditionalCraftingRecipes('now');
      final weak = recipes.firstWhere((r) => r.id == 'expansion_guanto_goblin');
      final strong = recipes.firstWhere(
        (r) => r.id == 'expansion_guanto_forest_demon',
      );
      expect(weak.ingredients.map((i) => i.name), [
        'Zanne di goblin',
        'Pelle di mostro',
      ]);
      expect(strong.ingredients.map((i) => i.name), [
        'Corno di Forest Demon',
        'Metallo runico',
      ]);
      expect(oculumCraftedEquipmentBonuses(weak).damage, 5);
      expect(oculumCraftedEquipmentBonuses(strong).grade, 1);
      final data = oculumCraftedEquipmentSkillData(strong);
      final skill = ArtSkill.fromJson(
        Map<String, dynamic>.from(data['skill'] as Map),
      );
      expect(skill.risorseCostoPerLivello.first, 'volonta');
      expect(skill.oculumMinimiPerLivello.first, 1);
      expect(skill.cooldownPerLivello.first.amount, 6);
      expect(skill.effettiPerLivello.first.single.valueExpression, 'Danni+20');
    },
  );
  final forge = oculumAdditionalCraftingRecipes(
    'now',
  ).firstWhere((r) => r.id == 'expansion_rinforzo');
  List<InventoryItem> stock(InventoryItem target) => [
    target,
    InventoryItem(nome: 'Lingotto di acciaio', peso: 1, quantita: 1, note: ''),
    InventoryItem(nome: 'Cuoio conciato', peso: .2, quantita: 1, note: ''),
  ];
  test(
    'Forge consumes exact materials, splits stacked target, blocks reapplication',
    () {
      final target = InventoryItem(
        nome: 'Lama',
        arma: true,
        quantita: 2,
        peso: 1,
        note: '',
      );
      final inventory = stock(target);
      expect(
        oculumApplyForgeToItem(inventory, target, forge, currentOculum: 0),
        isNull,
      );
      expect(target.quantita, 1);
      expect(target.buff, isEmpty);
      final forged = inventory.last;
      expect(forged.buff, contains('@Difesa+2'));
      expect(
        inventory.firstWhere((i) => i.nome == 'Lingotto di acciaio').peso,
        .5,
      );
      expect(inventory.firstWhere((i) => i.nome == 'Cuoio conciato').peso, .1);
      final before = inventory.map((i) => i.toJson()).toList();
      expect(
        oculumApplyForgeToItem(inventory, forged, forge, currentOculum: 0),
        isNotNull,
      );
      expect(inventory.map((i) => i.toJson()).toList(), before);
    },
  );
  test(
    'Any protection accepts forge; missing materials and invalid recipes consume nothing',
    () {
      final shield = InventoryItem(
        nome: 'Scudo',
        protegge: true,
        peso: 1,
        quantita: 1,
        note: '',
      );
      final inventory = stock(shield);
      inventory.removeLast();
      final before = inventory.map((i) => i.toJson()).toList();
      expect(
        oculumApplyForgeToItem(inventory, shield, forge, currentOculum: 0),
        isNotNull,
      );
      expect(inventory.map((i) => i.toJson()).toList(), before);
      inventory.add(
        InventoryItem(nome: 'Cuoio conciato', peso: .1, quantita: 1, note: ''),
      );
      expect(
        oculumApplyForgeToItem(
          inventory,
          shield,
          forge.copyWith(ingredients: []),
          currentOculum: 0,
        ),
        isNotNull,
      );
      expect(
        oculumApplyForgeToItem(inventory, shield, forge, currentOculum: 0),
        isNull,
      );
    },
  );
  test(
    'New roles classify diary words and state history survives serialization',
    () {
      for (final role in ['upgrade', 'skill', 'forge', 'crafting']) {
        final assigned = diaryAssignSelectionRole('Dardo', 0, 5, role)!;
        expect(diaryEntitiesFromLinks([assigned.text]).single.kind, role);
      }
      const entity = DiaryEntity('skill:dardo', 'Dardo', 'skill');
      final ledger = DiaryRoleLedger();
      expect(
        ledger.changeStatus(entity, 'learned', DateTime(2026, 10, 5)),
        isTrue,
      );
      expect(
        ledger.changeStatus(entity, 'learned', DateTime(2026, 10, 5)),
        isFalse,
      );
      ledger.changeStatus(entity, 'upgraded', DateTime(2026, 10, 6));
      final saved = DiaryRoleLedger.fromJson(ledger.toJson());
      expect(saved.statusOf(entity), 'upgraded');
      expect(saved.statusHistoryFor(entity).length, 2);
      expect(saved.roleOf(entity), 'skill');
    },
  );
}
