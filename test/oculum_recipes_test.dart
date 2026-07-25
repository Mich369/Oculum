import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
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
