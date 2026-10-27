import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

OculumRecipe recipe(String id, {bool public = true}) => OculumRecipe(id:id,name:id,ingredients:const [],resultName:id,resultDescription:'',masterNotes:'private',visibleToPlayers:public,createdAt:'',updatedAt:'');
void main() {
  test('unknown recipes are locked for players and all are visible to Master only while Master', () {
    final recipes=[recipe('a'),recipe('b'),recipe('private', public:false)];
    expect(oculumVisibleRecipes(recipes:recipes,isMaster:false,knownRecipeIds:{}),isEmpty);
    expect(oculumVisibleRecipes(recipes:recipes,isMaster:false,knownRecipeIds:{'a','private'}).map((r)=>r.id),['a']);
    expect(oculumVisibleRecipes(recipes:recipes,isMaster:true,knownRecipeIds:{}),hasLength(3));
    expect(oculumVisibleRecipes(recipes:recipes,isMaster:false,knownRecipeIds:{'a'}).map((r)=>r.id),['a']);
  });
  test('thematic books omit private recipes and cover public recipes', () {
    final recipes=[recipe('a'),recipe('b'),recipe('private',public:false),recipe('core_realm_prismarite_weapon')];
    final books=oculumRecipeBooks(recipes);
    final ids=books.expand((b)=>(b['recipeIds'] as List).cast<String>()).toSet();
    expect(ids, {'a','b','core_realm_prismarite_weapon'});
    expect(books.where((b)=>b['planeId']=='reame_cristallo'),hasLength(1));
  });
  test('book receipt grants cumulative knowledge to party and retry never repeats operation', () {
    Map<String,dynamic> state={'members':{'A':{},'B':{}}};
    Map<String,dynamic> request(String id,List<String> recipes)=>{'id':id,'operation':'learn_recipe_book','requesterTag':'A','recipeIds':recipes,'recipients':['A','B'],'item':{'nome':'Libro','quantita':1,'craftData':{'recipeBook':{'recipeIds':recipes}}}};
    state=oculumApplyPartyChestOperation(state,request('one',['a','b']));
    final first=jsonEncode(state);
    expect(state['recipeKnowledgeByTag'],{'A':['a','b'],'B':['a','b']});
    expect(jsonEncode(oculumApplyPartyChestOperation(state,request('one',['c']))),first);
    state=oculumApplyPartyChestOperation(state,request('two',['b','c']));
    expect(state['recipeKnowledgeByTag'],{'A':['a','b','c'],'B':['a','b','c']});
    expect(oculumApplyPartyChestOperation(state,{'id':'invalid','operation':'learn_recipe_book','requesterTag':'A','recipients':['A'],'recipeIds':['private']})['recipeKnowledgeByTag'], state['recipeKnowledgeByTag']);
    expect((oculumApplyPartyChestOperation(state,{'id':'invalid','operation':'learn_recipe_book'})['receipts'] as Map)['invalid']['approved'],isFalse);
  });
}
