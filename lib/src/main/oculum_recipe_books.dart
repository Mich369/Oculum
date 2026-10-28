part of '../../main.dart';

/// Books add knowledge; they never replace a sheet's earlier unlocks.
Map<String, dynamic> oculumLearnPartyRecipes(
  Map previous, {
  required Iterable<String> recipeIds,
  required Iterable<String> tags,
}) {
  final result = occlumCopyRecipeKnowledge(previous);
  final ids = recipeIds.where((id) => id.trim().isNotEmpty).toSet();
  for (final tag in tags.where((s) => s.trim().isNotEmpty).toSet()) {
    result[tag] = {
      ...(result[tag] as List? ?? []).map((s) => '$s'),
      ...ids,
    }.toList()..sort();
  }
  return result;
}

Map<String, dynamic> occlumCopyRecipeKnowledge(Map value) => {
  for (final e in value.entries)
    '${e.key}': List<String>.from((e.value as List? ?? []).map((v) => '$v')),
};

List<Map<String, dynamic>> oculumRecipeBooks(Iterable<OculumRecipe> recipes) {
  final groups = <String, List<OculumRecipe>>{};
  for (final recipe in recipes.where(
    (r) => r.visibleToPlayers && !r.personal,
  )) {
    final realm = recipe.id.startsWith('core_realm_vetro_')
        ? 'deserto'
        : recipe.id.startsWith('core_realm_')
        ? 'cristallo'
        : '';
    final kind = realm.isNotEmpty
        ? realm
        : const {'alchemy', 'alchimia'}.contains(recipe.recipeKind)
        ? 'alchimia'
        : recipe.recipeKind == 'forge'
        ? 'fabbro'
        : 'artigianato';
    final grade = oculumCraftingGradeForRecipe(recipe);
    final tier = grade <= 0
        ? 0
        : grade <= 2
        ? 1
        : 2;
    groups.putIfAbsent('${kind}_$tier', () => []).add(recipe);
  }
  return [
    for (final entry in groups.entries)
      {
        'id': 'recipe_book_${entry.key}',
        'name':
            'Libro di ${entry.key.split('_').first} · ${entry.key.endsWith('_0')
                ? 'fondamenti'
                : entry.key.endsWith('_1')
                ? 'tecniche intermedie'
                : 'tecniche maggiori'}',
        'description':
            'Alla lettura si consuma e aggiunge cumulativamente ${entry.value.length} ricette collegate a tutti gli alleati del party. Restano necessari Grado, materiali e prove di lavorazione.',
        'recipeIds': entry.value.map((r) => r.id).toList(),
        'cost': 25 + entry.value.length * 3,
        if (entry.key.startsWith('cristallo')) 'planeId': 'reame_cristallo',
        if (entry.key.startsWith('deserto')) 'planeId': 'deserto_divoratore',
      },
  ];
}

extension _OculumRecipeBooks on _OculumHomePageState {
  Set<String> get knownRecipeIds => {
    ...(planarState['knownRecipeIds'] as List? ?? []).map((id) => '$id'),
    ...((partyChest['recipeKnowledgeByTag'] as Map?)?[sheetTagAt(
                  schedaCorrente,
                )]
                as List? ??
            [])
        .map((id) => '$id'),
    ...personalRecipes.map((r) => r.id),
  };
  bool recipeKnown(OculumRecipe recipe) =>
      haPermessiMaster ||
      personalRecipes.any((r) => r.id == recipe.id) ||
      recipe.visibleToPlayers && knownRecipeIds.contains(recipe.id);
  void retainPartyRecipeKnowledge() {
    final knowledge = partyChest['recipeKnowledgeByTag'] as Map? ?? {};
    for (var index = 0; index < schedePersonaggio.length; index++) {
      final sheet = schedePersonaggio[index];
      // A received party snapshot may retain knowledge only on locally owned
      // sheets. Remote owners persist their own characters on their clients.
      if (readBoolValue(sheet['realtimeSharedSheet'])) continue;
      final incoming = knowledge[sheetTagAt(index)];
      if (incoming is! List || incoming.isEmpty) continue;
      if (index == schedaCorrente) {
        planarState['knownRecipeIds'] = {
          ...(planarState['knownRecipeIds'] as List? ?? []).map((v) => '$v'),
          ...incoming.map((v) => '$v'),
        }.toList()..sort();
      } else {
        final runtime = Map<String, dynamic>.from(
          sheet['planarRuntime'] as Map? ?? {},
        );
        runtime['knownRecipeIds'] = {
          ...(runtime['knownRecipeIds'] as List? ?? []).map((v) => '$v'),
          ...incoming.map((v) => '$v'),
        }.toList()..sort();
        sheet['planarRuntime'] = runtime;
      }
    }
    recipesRevision.value++;
  }

  void ensureRecipeBookOffers() {
    for (final book in oculumRecipeBooks(recipes)) {
      if (merchantStock.any((o) => o['id'] == book['id'])) continue;
      merchantStock.add({
        ...book,
        'kind': 'recipe_book',
        'desc': book['description'],
      });
    }
  }

  Future<void> readRecipeBook(InventoryItem item) async {
    if (!inventario.contains(item) ||
        item.quantita <= 0 ||
        item.craftData['recipeBook'] is! Map) {
      return;
    }
    final book = Map<String, dynamic>.from(item.craftData['recipeBook'] as Map);
    final ids = (book['recipeIds'] as List? ?? []).map((s) => '$s').toList();
    if (ids.isEmpty) return;
    if (realtimeService?.isConnected == true) {
      await requestPartyChestOperation(
        'learn_recipe_book',
        amount: 1,
        item: item,
      );
    } else {
      final tags = {
        sheetTagAt(schedaCorrente),
        for (final i in questPartyIndices()) sheetTagAt(i),
      };
      final request = {
        'id':
            'book:${item.craftData['recipeBookInstance'] ?? DateTime.now().microsecondsSinceEpoch}',
        'operation': 'learn_recipe_book',
        'requesterTag': sheetTagAt(schedaCorrente),
        'item': item.toJson(),
        'recipeIds': ids,
        'recipients': tags.toList(),
      };
      final state = oculumApplyPartyChestOperation(partyChest, request);
      final approved =
          (state['receipts'] as Map?)?[request['id']] is Map &&
          ((state['receipts'] as Map)[request['id']] as Map)['approved'] ==
              true;
      if (!approved ||
          (partyChest['receipts'] as Map? ?? {}).containsKey(request['id'])) {
        return;
      }
      partyChestCampaigns[permissionCampaignId] = state;
      item.quantita--;
      if (item.quantita <= 0) inventario.remove(item);
      retainPartyRecipeKnowledge();
      aggiungiLog(
        '[RICETTARIO] ${item.nome}: ${ids.length} ricette aggiunte agli alleati del party. Libro consumato.',
      );
      programmaSalvataggio();
    }
  }
}
