import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart' as monster_book;
import 'package:oculum/services/oculum_diary_links.dart';
import 'package:oculum/services/oculum_diary_memory.dart';
import 'package:oculum/services/oculum_diary_roles.dart';

void main() {
  test(
    'Crafting checks use the matching skill and scale by material grade',
    () {
      final recipes = oculumAdditionalCraftingRecipes('now');
      final alchemy = recipes.firstWhere(
        (recipe) => recipe.recipeKind == 'alchemy',
      );
      final forge = recipes.firstWhere(
        (recipe) => recipe.id == 'expansion_guanto_forest_demon',
      );
      final intarsioZero = recipes.firstWhere(
        (recipe) => recipe.id == 'expansion_intarsio_gerin',
      );
      final intarsioFour = recipes.firstWhere(
        (recipe) => recipe.id == 'expansion_intarsio_crisol_astrale',
      );
      expect(oculumCraftingSubtraitId(alchemy), 'alchimia');
      expect(oculumCraftingSubtraitId(forge), 'riparazioni');
      expect(oculumCraftingSubtraitId(intarsioZero), 'riparazioni');
      expect(oculumCraftingDifficulty(intarsioZero), 13);
      expect(oculumCraftingDifficulty(intarsioFour), 21);
      expect(oculumCraftingDifficulty(forge), 15);
      expect(
        oculumCraftingDifficulty(intarsioZero, quantity: 8),
        oculumCraftingDifficulty(intarsioZero) + 3,
      );
      expect(
        oculumCraftingCheckSucceeds(naturalRoll: 20, total: 1, difficulty: 30),
        isTrue,
      );
      expect(
        oculumCraftingCheckSucceeds(naturalRoll: 1, total: 100, difficulty: 1),
        isFalse,
      );
      expect(
        oculumCraftingCheckSucceeds(naturalRoll: 10, total: 13, difficulty: 13),
        isTrue,
      );
      expect(oculumCraftingFailureLossGrams(100), 25);
      expect(oculumCraftingFailureLossGrams(1), 1);
      for (final material in oculumFantasyCraftingMaterials) {
        final recipe = recipes.firstWhere(
          (entry) => entry.id == 'expansion_intarsio_${material.id}',
        );
        expect(recipe.forgeEffectText, contains('@Ocu+'));
        expect(oculumCraftingDifficulty(recipe), 13 + 2 * material.grade);
      }
    },
  );

  test(
    'Gerin resonance replenishes Oculum with diminishing bounded yields',
    () {
      expect(
        [
          for (var previous = 0; previous < 4; previous++)
            oculumGerinResonanceGain(
              grade: 0,
              attackTotal: 21,
              previousTriggers: previous,
            ),
        ],
        [1, 0, 0, 0],
      );
      expect(
        [
          for (var previous = 0; previous < 3; previous++)
            oculumGerinResonanceGain(
              grade: 8,
              attackTotal: 21,
              previousTriggers: previous,
            ),
        ],
        [3, 2, 1],
      );
      expect(
        oculumGerinResonanceGain(
          grade: 12,
          attackTotal: 20,
          previousTriggers: 0,
        ),
        0,
      );
    },
  );

  test('Combat Ash checks are rare and prefer a one-turn light penalty', () {
    expect(oculumCombatAshTriggersCheck(3), isFalse);
    expect(oculumCombatAshTriggersCheck(6), isTrue);
    expect(oculumCombatAshTriggersCheck(8), isFalse);
    expect(oculumCombatAshTriggersCheck(9), isTrue);
    expect(
      oculumCombatAshCausesUnconscious(ash: 11, percentileRoll: 0),
      isFalse,
    );
    expect(
      oculumCombatAshCausesUnconscious(ash: 12, percentileRoll: 0),
      isTrue,
    );
    expect(
      oculumCombatAshCausesUnconscious(ash: 20, percentileRoll: 1),
      isFalse,
    );
    final blurred = oculumConditionDefinition('vista_appannata')!;
    expect(blurred.rollModifierForStage(1), -1);
    expect(blurred.durationForStage(1), 1);
  });

  test(
    'Crafting drops map to recipes and optional monster materials have odds',
    () {
      final monsters = monster_book.defaultMonsterBookEntries;
      for (final entry in [
        ('arpia_base', 'piume_arpia', 65),
        ('forest_demon', 'corno_forest_demon', 35),
        ('goblin_base', 'zanne_goblin', 70),
        ('lupo_di_bruma', 'artigli_lupo', 60),
        ('scarabeo_di_basalto', 'carapace_scarabeo', 55),
        ('troll_delle_caverne', 'denti_troll', 65),
        ('basilisco_delle_rovine', 'occhio_basilisco', 35),
        ('pipistrello_cavernicolo', 'membrana_pipistrello', 55),
      ]) {
        final monster = monsters.firstWhere(
          (m) =>
              m.id == entry.$1 ||
              m.id.startsWith('${entry.$1}_') ||
              m.id == 'inspired_${entry.$1}',
        );
        expect(monster.dropIds, contains(entry.$2));
        expect(monster.dropChances[entry.$2], entry.$3);
        expect(
          monster_book.MonsterBookEntry.fromJson(
            monster.toJson(),
          ).dropChances[entry.$2],
          entry.$3,
        );
      }
      expect(oculumMonsterDropName('piume_arpia'), 'Piume di arpia');
    },
  );

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
