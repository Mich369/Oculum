import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  group('Vitalium Grezzo', () {
    test('usa il tiro di Medicina per grado senza alterare la cura base', () {
      expect(oculumRawVitaliumMedicineBonus(grade: 0, medicineRoll: 15), 0);
      expect(oculumRawVitaliumMedicineBonus(grade: 1, medicineRoll: 15), 7);
      expect(oculumRawVitaliumMedicineBonus(grade: 2, medicineRoll: 15), 7);
      expect(oculumRawVitaliumMedicineBonus(grade: 3, medicineRoll: 15), 15);
      expect(oculumRawVitaliumMedicineRoll(die: 1, medicine: 8), -9);
      expect(oculumRawVitaliumMedicineBonus(grade: 2, medicineRoll: -9), -4);
      expect(oculumRawVitaliumRuleForGrade(1), contains('d10'));
      expect(oculumRawVitaliumRuleForGrade(2), contains('d20'));
      expect(oculumRawVitaliumRuleForGrade(3), contains('d30'));
    });
  });

  group('Ricette', () {
    test('accetta grammi interi e decimali positivi senza perdere cifre', () {
      expect(oculumNormalizePositiveGramText('25'), '25');
      expect(oculumNormalizePositiveGramText('0012,500'), '12.500');
      expect(oculumNormalizePositiveGramText('0.0001'), '0.0001');
      expect(oculumNormalizePositiveGramText('0'), isNull);
      expect(oculumNormalizePositiveGramText('-2'), isNull);
      expect(oculumNormalizePositiveGramText('1.2.3'), isNull);
    });

    test('salva e ricarica tutti i campi con quantità testuale precisa', () {
      const recipe = OculumRecipe(
        id: 'recipe_1',
        name: 'Inchiostro lunare',
        ingredients: [OculumRecipeIngredient(name: 'Cenere', grams: '0.1250')],
        resultName: 'Inchiostro',
        resultDescription: 'Rimane luminoso per un’ora.',
        masterNotes: 'Solo durante la luna piena.',
        visibleToPlayers: false,
        createdAt: '2026-07-19T10:00:00.000',
        updatedAt: '2026-07-19T10:00:00.000',
      );

      final restored = OculumRecipe.fromJson(recipe.toJson());
      expect(restored.id, recipe.id);
      expect(restored.ingredients.single.grams, '0.1250');
      expect(restored.visibleToPlayers, isFalse);
      expect(restored.masterNotes, recipe.masterNotes);
    });

    test('i vecchi salvataggi senza visibilità restano visibili', () {
      final restored = OculumRecipe.fromJson({
        'nome': 'Pozione',
        'ingredienti': [
          {'nome': 'Erba', 'quantita': 5},
        ],
        'risultato': 'Pozione verde',
      });

      expect(restored.visibleToPlayers, isTrue);
      expect(restored.ingredients.single.grams, '5');
    });

    test('la ricetta Forge conserva peso, tempo e attributi', () {
      const recipe = OculumRecipe(
        id: 'forge_1',
        name: 'Roccia',
        ingredients: [OculumRecipeIngredient(name: 'Pietra', grams: '5')],
        resultName: 'Roccia attiva',
        resultDescription: 'Difesa basata su Oculum.',
        masterNotes: '',
        visibleToPlayers: true,
        createdAt: '',
        updatedAt: '',
        recipeKind: 'forge',
        forgeWeightMinKg: '5',
        forgeWeightMaxKg: '30',
        forgeDuration: '50 min',
        forgeAttributes: 'hollow resilience\nforgecraft',
      );

      final restored = OculumRecipe.fromJson(recipe.toJson());
      expect(restored.recipeKind, 'forge');
      expect(restored.forgeWeightMinKg, '5');
      expect(restored.forgeWeightMaxKg, '30');
      expect(restored.forgeDuration, '50 min');
      expect(restored.forgeAttributes, contains('forgecraft'));
    });

    test(
      'la grammatura del prodotto finito resta compatibile con i salvataggi',
      () {
        const recipe = OculumRecipe(
          id: 'alchemy_weight',
          name: 'Elisir',
          ingredients: [OculumRecipeIngredient(name: 'Erba', grams: '50')],
          resultName: 'Elisir pronto',
          resultDescription: '',
          masterNotes: '',
          visibleToPlayers: true,
          createdAt: '',
          updatedAt: '',
          recipeKind: 'alchemy',
          resultGrams: '35',
        );

        expect(OculumRecipe.fromJson(recipe.toJson()).resultGrams, '35');
        expect(
          OculumRecipe.fromJson({
            'id': 'legacy_weight',
            'name': 'Ricetta vecchia',
          }).resultGrams,
          isEmpty,
        );
      },
    );

    test('il costo Oculum della ricetta è additivo e legacy-safe', () {
      const recipe = OculumRecipe(
        id: 'pinna_alata',
        name: 'Pinna di Pesce Alato',
        ingredients: [
          OculumRecipeIngredient(
            name: 'Polvere del Pesce Alato',
            grams: '1000',
          ),
        ],
        resultName: 'Pinna di Pesce Alato',
        resultDescription: 'Nuoto nell’aria.',
        masterNotes: '',
        visibleToPlayers: true,
        createdAt: '',
        updatedAt: '',
        recipeKind: 'alchemy',
        oculumCost: 3,
      );
      expect(OculumRecipe.fromJson(recipe.toJson()).oculumCost, 3);
      expect(OculumRecipe.fromJson({'id': 'legacy_recipe'}).oculumCost, 0);
    });

    test('categorie e copie personali restano separate nel JSON', () {
      final legacy = OculumRecipe.fromJson(<String, dynamic>{
        'id': 'legacy',
        'name': 'Vecchia ricetta',
      });
      expect(legacy.recipeKind, 'crafting');

      final personal = legacy.copyWith(
        id: 'personal',
        recipeKind: 'alchemy',
        personal: true,
        ownerTag: 'PLAYER-1',
        sourceRecipeId: 'legacy',
      );
      final restored = OculumRecipe.fromJson(personal.toJson());
      expect(restored.recipeKind, 'alchemy');
      expect(restored.personal, isTrue);
      expect(restored.ownerTag, 'PLAYER-1');
      expect(restored.sourceRecipeId, 'legacy');
    });

    test('ricerca per nome, ingrediente e risultato e nasconde i segreti', () {
      const visible = OculumRecipe(
        id: 'visible',
        name: 'Balsamo solare',
        ingredients: [OculumRecipeIngredient(name: 'Muschio', grams: '2.5')],
        resultName: 'Unguento dorato',
        resultDescription: 'Cura.',
        masterNotes: '',
        visibleToPlayers: true,
        createdAt: '',
        updatedAt: '',
      );
      const hidden = OculumRecipe(
        id: 'hidden',
        name: 'Veleno segreto',
        ingredients: [OculumRecipeIngredient(name: 'Belladonna', grams: '1')],
        resultName: 'Veleno',
        resultDescription: 'Segreto.',
        masterNotes: '',
        visibleToPlayers: false,
        createdAt: '',
        updatedAt: '',
      );

      expect(
        oculumVisibleRecipes(
          recipes: const [visible, hidden],
          isMaster: false,
        ).map((item) => item.id),
        ['visible'],
      );
      expect(
        oculumVisibleRecipes(
          recipes: const [visible, hidden],
          isMaster: true,
          query: 'belladonna',
        ).single.id,
        'hidden',
      );
      expect(
        oculumVisibleRecipes(
          recipes: const [visible, hidden],
          isMaster: true,
          query: 'dorato',
        ).single.id,
        'visible',
      );
    });
  });
}
