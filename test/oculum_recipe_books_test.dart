import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'oculum_escape_provoker_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

OculumRecipe recipe(String id, {bool public = true}) => OculumRecipe(
  id: id,
  name: id,
  ingredients: const [],
  resultName: id,
  resultDescription: '',
  masterNotes: 'private',
  visibleToPlayers: public,
  createdAt: '',
  updatedAt: '',
);
void main() {
  testWidgets(
    'reading a real book consumes one copy and retains cumulative recipes on every owned ally across save and leaving the campaign',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      state.partyChestCampaigns.clear();
      final first = p.snapshot()
        ..['inMasterParty'] = true
        ..['tipoScheda'] = 'Personaggio';
      final second =
          Map<String, dynamic>.from(jsonDecode(jsonEncode(first)) as Map)
            ..['id'] = 'ALLY'
            ..['sheetTag'] = 'ALLY'
            ..['inMasterParty'] = true
            ..['planarRuntime'] = {
              'knownRecipeIds': ['older'],
              'custom': 42,
            };
      final remote =
          Map<String, dynamic>.from(jsonDecode(jsonEncode(first)) as Map)
            ..['id'] = 'REMOTE'
            ..['sheetTag'] = 'REMOTE'
            ..['realtimeSharedSheet'] = true
            ..['inMasterParty'] = true
            ..['planarRuntime'] = {
              'knownRecipeIds': ['remote_only'],
            };
      state.schedePersonaggio
        ..clear()
        ..addAll([first, second, remote]);
      state.schedaCorrente = 0;
      p.load(first);
      p.ensureSheetTags();
      state.modalitaMaster = false;
      state.isMasterHost = false;
      state.sonoCoMaster = false;
      state.inventario.clear();
      final a = recipe('a'), b = recipe('b');
      expect(p.recipeKnown(a), false);
      final book = InventoryItem(
        nome: 'Libro di ricette',
        peso: .1,
        quantita: 1,
        note: '',
        craftData: {
          'recipeBookInstance': 'real-book-one',
          'recipeBook': {
            'recipeIds': ['a', 'b'],
          },
        },
      );
      state.inventario.add(book);
      await p.readRecipeBook(book);
      expect(book.quantita, 0);
      expect((state.inventario as List).contains(book), false);
      expect(p.recipeKnown(a), true);
      expect(p.recipeKnown(b), true);
      final knowledgeBefore = jsonEncode(
        p.partyChestSnapshot()['recipeKnowledgeByTag'],
      );
      await p.readRecipeBook(book);
      expect(
        jsonEncode(p.partyChestSnapshot()['recipeKnowledgeByTag']),
        knowledgeBefore,
      );
      final ally = Map<String, dynamic>.from(state.schedePersonaggio[1] as Map);
      expect(
        (ally['planarRuntime'] as Map)['knownRecipeIds'],
        containsAll(['a', 'b', 'older']),
      );
      expect((ally['planarRuntime'] as Map)['custom'], 42);
      expect(
        (state.schedePersonaggio[2]['planarRuntime'] as Map)['knownRecipeIds'],
        ['remote_only'],
      );
      state.schedePersonaggio[0] = p.snapshot();
      state.partyChestCampaigns.clear();
      state.schedaCorrente = 1;
      p.load(Map<String, dynamic>.from(jsonDecode(jsonEncode(ally)) as Map));
      state.modalitaMaster = false;
      state.isMasterHost = false;
      state.sonoCoMaster = false;
      expect(p.recipeKnown(a), true);
      expect(p.recipeKnown(b), true);
      expect(p.recipeKnown(recipe('older')), true);
      expect(p.recipeKnown(recipe('unlearned')), false);
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'Master access does not permanently unlock recipes or leak locked favorites to a player',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      state.partyChestCampaigns.clear();
      final hidden = OculumRecipe(
        id: 'secret_recipe',
        name: 'Ricetta segreta',
        ingredients: const [
          OculumRecipeIngredient(name: 'Ingrediente segreto', grams: '50'),
        ],
        resultName: 'Risultato segreto',
        resultDescription: '',
        masterNotes: '',
        visibleToPlayers: false,
        createdAt: '',
        updatedAt: '',
      );
      state.recipes
        ..clear()
        ..add(hidden);
      state.personalRecipes.clear();
      state.favoriteRecipeIds
        ..clear()
        ..add(hidden.id);
      expect(p.recipeKnown(hidden), true);
      p.retainRecipes();
      state.modalitaMaster = false;
      state.isMasterHost = false;
      state.sonoCoMaster = false;
      expect(p.recipeKnown(hidden), false);
      final entry = OverlayEntry(
        builder: (_) => Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Material(child: p.recipeDemandPanel()),
        ),
      );
      Overlay.of(tester.element(find.byType(OculumHomePage))).insert(entry);
      await tester.pump();
      expect(find.textContaining('Ingrediente segreto'), findsNothing);
      entry.remove();
      await tester.pump();
      await closeFixture(tester, p);
    },
  );
  test(
    'unknown recipes are locked for players and all are visible to Master only while Master',
    () {
      final recipes = [
        recipe('a'),
        recipe('b'),
        recipe('private', public: false),
      ];
      expect(
        oculumVisibleRecipes(
          recipes: recipes,
          isMaster: false,
          knownRecipeIds: {},
        ),
        isEmpty,
      );
      expect(
        oculumVisibleRecipes(
          recipes: recipes,
          isMaster: false,
          knownRecipeIds: {'a', 'private'},
        ).map((r) => r.id),
        ['a'],
      );
      expect(
        oculumVisibleRecipes(
          recipes: recipes,
          isMaster: true,
          knownRecipeIds: {},
        ),
        hasLength(3),
      );
      expect(
        oculumVisibleRecipes(
          recipes: recipes,
          isMaster: false,
          knownRecipeIds: {'a'},
        ).map((r) => r.id),
        ['a'],
      );
    },
  );
  test('thematic books omit private recipes and cover public recipes', () {
    final recipes = [
      recipe('a'),
      recipe('b'),
      recipe('private', public: false),
      recipe('core_realm_prismarite_weapon'),
    ];
    final books = oculumRecipeBooks(recipes);
    final ids = books
        .expand((b) => (b['recipeIds'] as List).cast<String>())
        .toSet();
    expect(ids, {'a', 'b', 'core_realm_prismarite_weapon'});
    expect(books.where((b) => b['planeId'] == 'reame_cristallo'), hasLength(1));
  });
  test(
    'book receipt grants cumulative knowledge to party and retry never repeats operation',
    () {
      Map<String, dynamic> state = {
        'members': {'A': {}, 'B': {}},
      };
      Map<String, dynamic> request(String id, List<String> recipes) => {
        'id': id,
        'operation': 'learn_recipe_book',
        'requesterTag': 'A',
        'recipeIds': recipes,
        'recipients': ['A', 'B'],
        'item': {
          'nome': 'Libro',
          'quantita': 1,
          'craftData': {
            'recipeBook': {'recipeIds': recipes},
          },
        },
      };
      state = oculumApplyPartyChestOperation(state, request('one', ['a', 'b']));
      final first = jsonEncode(state);
      expect(state['recipeKnowledgeByTag'], {
        'A': ['a', 'b'],
        'B': ['a', 'b'],
      });
      expect(
        jsonEncode(
          oculumApplyPartyChestOperation(state, request('one', ['c'])),
        ),
        first,
      );
      state = oculumApplyPartyChestOperation(state, request('two', ['b', 'c']));
      expect(state['recipeKnowledgeByTag'], {
        'A': ['a', 'b', 'c'],
        'B': ['a', 'b', 'c'],
      });
      expect(
        oculumApplyPartyChestOperation(state, {
          'id': 'invalid',
          'operation': 'learn_recipe_book',
          'requesterTag': 'A',
          'recipients': ['A'],
          'recipeIds': ['private'],
        })['recipeKnowledgeByTag'],
        state['recipeKnowledgeByTag'],
      );
      expect(
        (oculumApplyPartyChestOperation(state, {
              'id': 'invalid',
              'operation': 'learn_recipe_book',
            })['receipts']
            as Map)['invalid']['approved'],
        isFalse,
      );
    },
  );
}
