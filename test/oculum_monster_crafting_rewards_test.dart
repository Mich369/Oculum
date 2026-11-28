import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

class _Rolls implements Random {
  _Rolls(this.values);

  final List<int> values;
  int index = 0;

  @override
  int nextInt(int max) => values[index++] % max;

  @override
  double nextDouble() => throw UnimplementedError();

  @override
  bool nextBool() => throw UnimplementedError();
}

OculumRecipe recipe(String id, String type, {bool visible = true}) =>
    OculumRecipe(
      id: id,
      name: id,
      ingredients: const [
        OculumRecipeIngredient(name: 'Legno', grams: '200'),
        OculumRecipeIngredient(name: ' Legno ', grams: '100'),
        OculumRecipeIngredient(name: 'Ferro', grams: '100'),
      ],
      resultName: 'Oggetto $id',
      resultDescription: '',
      masterNotes: '',
      visibleToPlayers: visible,
      createdAt: '',
      updatedAt: '',
      forgeTarget: type,
    );

InventoryItem gear(String name, OculumEquipmentFusionKind kind) =>
    InventoryItem(
      nome: name,
      peso: 1,
      quantita: 1,
      note: '',
      arma: kind == OculumEquipmentFusionKind.weapon,
      protegge: kind != OculumEquipmentFusionKind.weapon,
      craftData: {
        if (kind != OculumEquipmentFusionKind.weapon)
          'wearProtectionKind': kind.name,
      },
    );

void main() {
  test(
    'A recipe roll keeps the old loot independent and targets missing gear and grams',
    () {
      final weapon = gear('Spada', OculumEquipmentFusionKind.weapon)
        ..equipaggiata = true;
      final ownedWood = InventoryItem(
        nome: 'legno',
        peso: .3,
        quantita: 1,
        note: '',
      );
      final reserved = <String>{};
      List<InventoryItem> drop(int roll) => oculumMonsterCraftingDrop(
        recipes: [
          recipe('arma', 'weapon'),
          recipe('corazza', 'armor'),
          recipe('segreta', 'armor', visible: false),
        ],
        inventory: [weapon, ownedWood],
        knownRecipeIds: const {},
        reservedRecipeIds: reserved,
        buildElements: const {},
        characterGrade: 12,
        killId: 'creatura:lotta',
        random: _Rolls([roll, 0]),
      );

      expect(drop(25), isEmpty);
      final loot = drop(24);
      expect(loot.first.craftData['recipeBook']['recipeIds'], ['corazza']);
      expect(
        loot.first.craftData['recipeBookInstance'],
        'drop:creatura:lotta:corazza',
      );
      expect(reserved, {'corazza'});
      expect(loot.skip(1).map((item) => item.nome), ['Ferro']);
      expect(loot.last.peso, .1);
    },
  );

  test('An unlearned recipe carries at most 75% of the full requirement', () {
    final book = InventoryItem(
      nome: 'Ricetta già in inventario',
      peso: .02,
      quantita: 1,
      note: '',
      craftData: {
        'recipeBook': {
          'recipeIds': ['already-owned'],
        },
      },
    );
    final loot = oculumMonsterCraftingDrop(
      recipes: [recipe('already-owned', 'weapon'), recipe('new', 'weapon')],
      inventory: [book],
      knownRecipeIds: const {},
      reservedRecipeIds: {},
      buildElements: const {'fisico'},
      characterGrade: 12,
      killId: 'new-kill',
      random: _Rolls([0, 200]),
    );
    expect(loot.first.craftData['recipeBook']['recipeIds'], ['new']);
    final grams = oculumRecipeInventoryGrams(loot.skip(1));
    expect(grams, {'legno': 225, 'ferro': 75});
  });

  test(
    'The smith consumes both items and keeps independent abilities and cooldowns',
    () {
      final first = gear('Fenditura', OculumEquipmentFusionKind.weapon)
        ..bonusDanno = 12
        ..ability = oculumEquipmentAbility('Fenditura', 1);
      final second = gear('Lama di brace', OculumEquipmentFusionKind.weapon)
        ..bonusDanno = 8
        ..ability = oculumEquipmentAbility('Lama di brace', 2);
      first.ability!.forme.first.cooldownStrutturato!.activate();
      final beforeFirst = first.ability!.toJson();
      final beforeSecond = second.ability!.toJson();
      final inventory = [first, second];
      final output = oculumFuseEquipment(
        inventory,
        first,
        second,
        name: ' Guardiabrace ',
        receipt: 'fusion:1',
      )!;
      expect(inventory, [output]);
      expect(output.nome, 'Guardiabrace');
      expect(output.bonusDanno, 13);
      expect(output.bonusDifesa, 0);
      expect(output.bonusScudo, 0);
      expect(
        oculumAllEquipmentAbilities(output).map((skill) => skill.toJson()),
        [beforeFirst, beforeSecond],
      );
      final loaded = InventoryItem.fromJson(output.toJson());
      expect(
        oculumAllEquipmentAbilities(loaded).map((skill) => skill.toJson()),
        [beforeFirst, beforeSecond],
      );
      expect(
        oculumFuseEquipment(
          inventory,
          first,
          second,
          name: 'Duplicates',
          receipt: 'fusion:1',
        ),
        isNull,
      );
    },
  );

  test(
    'Armour and shield bonuses use their categories and an invalid pair is untouched',
    () {
      final armor = gear('Corazza', OculumEquipmentFusionKind.armor)
        ..quantita = 2;
      final shieldA = gear('Brocchiere', OculumEquipmentFusionKind.shield)
        ..bonusScudo = 5;
      final shieldB = gear('Scudo', OculumEquipmentFusionKind.shield)
        ..bonusDifesa = 3;
      final inventory = [armor, shieldA, shieldB];
      expect(
        oculumFuseEquipment(
          inventory,
          armor,
          shieldA,
          name: 'Invalido',
          receipt: 'x',
        ),
        isNull,
      );
      expect(inventory.map((item) => item.quantita), [2, 1, 1]);
      final fusedArmor = oculumFuseEquipment(
        inventory,
        armor,
        armor,
        name: 'Armatura nuova',
        receipt: 'a',
      )!;
      expect(
        (fusedArmor.bonusDanno, fusedArmor.bonusDifesa, fusedArmor.bonusScudo),
        (0, 1, 1),
      );
      final fusedShield = oculumFuseEquipment(
        inventory,
        shieldA,
        shieldB,
        name: 'Guardia',
        receipt: 'b',
      )!;
      expect(
        (
          fusedShield.bonusDanno,
          fusedShield.bonusDifesa,
          fusedShield.bonusScudo,
        ),
        (1, 4, 5),
      );
      expect(oculumFusedShieldDamageBonus(fusedShield), 1);
      expect(oculumFusedShieldDamageBonus(fusedArmor), 0);
      expect(inventory, [fusedArmor, fusedShield]);
    },
  );
}
