import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'oculum_theme_effects_portrait_test.dart' as fixtures;

void main() {
  InventoryItem item({bool attack = false, bool defend = false}) =>
      InventoryItem(
        nome: 'Oggetto',
        peso: 1,
        quantita: 1,
        note: '',
        arma: attack,
        protegge: defend,
        livelloOggetto: 4,
      );

  test(
    'crafting caps are independent from scrolls; Rebirth luck rounds up',
    () {
      expect(oculumCraftLuckChance(200), 90);
      expect(oculumCraftLuckChance(200, rebirthed: true), 100);
      expect(oculumCraftLuckChance(5), 15);
      expect(oculumScrollLuck(3, rebirthed: true), 5);
      expect(oculumScrollLuck(3), 3);
      expect(
        oculumScrollLearningChance('normale', luck: 200, characterGrade: 8),
        75,
      );
      expect(
        oculumScrollLearningChance('normale', luck: 200, characterGrade: 9),
        90,
      );
    },
  );
  test(
    'wearable bonuses use item level and a saved receipt prevents replay',
    () {
      for (final role in [
        (true, false),
        (false, true),
        (true, true),
        (false, false),
      ]) {
        final made = item(attack: role.$1, defend: role.$2);
        if (!role.$1 && !role.$2) made.craftData = {'clothing': true};
        expect(
          oculumCompleteEquipmentCraft(
            made,
            receipt: 'one',
            roll: 0,
            luck: 0,
            forged: true,
          ),
          true,
        );
        expect(made.livelloOggetto, 5);
        expect(made.bonusDanno, role.$1 ? 5 : 0);
        expect(made.bonusDifesa, role.$2 || !role.$1 ? 5 : 0);
        final restored = InventoryItem.fromJson(made.toJson());
        expect(
          oculumCompleteEquipmentCraft(
            restored,
            receipt: 'one',
            roll: 0,
            luck: 100,
            forged: true,
          ),
          false,
        );
        expect(restored.livelloOggetto, 5);
        expect(restored.bonusDanno, made.bonusDanno);
      }
      final failed = item(attack: true);
      expect(
        oculumCompleteEquipmentCraft(
          failed,
          receipt: 'miss',
          roll: 99,
          luck: 100,
          forged: true,
        ),
        false,
      );
      expect(failed.livelloOggetto, 5);
      expect(failed.bonusDanno, 0);
      expect(
        oculumCompleteEquipmentCraft(
          failed,
          receipt: 'next',
          roll: 99,
          luck: 100,
          rebirthed: true,
          forged: true,
        ),
        true,
      );
      expect(failed.livelloOggetto, 6);
      expect(failed.bonusDanno, 6);
    },
  );
  test('new recipes produce usable, level gated equipment and magic silk', () {
    final recipes = oculumFaunaCraftingRecipes('2026-10-25');
    expect(recipes.length, 22);
    expect(recipes.map((r) => r.id).toSet().length, 22);
    for (final recipe in recipes) {
      final made = oculumFaunaCraftedItem(recipe)!;
      expect(oculumCraftWearable(made), true, reason: recipe.id);
      expect(made.peso, greaterThan(0));
      expect(recipe.ingredients.every((i) => i.name.isNotEmpty), true);
      if (recipe.id.startsWith('fauna_')) {
        expect(made.ability, isNotNull, reason: recipe.id);
      } else {
        expect(made.craftData['silkResistances'], isNotEmpty);
      }
    }
  });
  testWidgets('silk resistance only applies while equipped and can be edited', (
    tester,
  ) async {
    final dynamic state = await fixtures.mountSheet(
      tester,
      const Size(1440, 900),
    );
    final probe = OculumPerformanceProbe(state);
    final silk = oculumMagicSilkItem('urti')!..equipaggiata = true;
    state.inventario.add(silk);
    expect(probe.silkMultiplier('contundente'), .8);
    silk.craftData['silkResistances'] = {'contundente': 30};
    expect(probe.silkMultiplier('contundente'), .7);
    silk.equipaggiata = false;
    expect(probe.silkMultiplier('contundente'), 1);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
