part of '../../main.dart';

String oculumRecipeMaterialKey(String name) => name.trim().toLowerCase();

int oculumRecipeIngredientGrams(String raw) {
  final grams = double.tryParse(raw.replaceAll(',', '.'));
  return grams == null || !grams.isFinite ? 0 : max(0, grams.round());
}

Map<String, int> oculumRecipeInventoryGrams(Iterable<InventoryItem> inventory) {
  final available = <String, int>{};
  for (final item in inventory) {
    final key = oculumRecipeMaterialKey(item.nome);
    if (key.isEmpty || item.quantita <= 0 || !item.peso.isFinite) continue;
    final grams = max(0, (item.peso * 1000 * item.quantita).round());
    available.update(key, (value) => value + grams, ifAbsent: () => grams);
  }
  return available;
}

List<InventoryItem> oculumMonsterCraftingDrop({
  required Iterable<OculumRecipe> recipes,
  required Iterable<InventoryItem> inventory,
  required Set<String> knownRecipeIds,
  required Set<String> reservedRecipeIds,
  required Set<String> buildElements,
  Set<String> plannedRecipeIds = const {},
  required int characterGrade,
  required String killId,
  required Random random,
}) {
  if (killId.isEmpty || random.nextInt(100) >= 25) return [];
  final owned = inventory.where((item) => item.quantita > 0).toList();
  final available = oculumRecipeInventoryGrams(owned);
  final known = {
    ...knownRecipeIds,
    ...reservedRecipeIds,
    for (final item in owned)
      if (item.craftData['recipeBook'] case {'recipeIds': final List ids})
        ...ids.whereType<String>(),
  };
  final plannedMaterials = <String>{
    for (final recipe in recipes)
      if (plannedRecipeIds.contains(recipe.id))
        ...recipe.ingredients.map(
          (ingredient) => oculumRecipeMaterialKey(ingredient.name),
        ),
  };
  final equipped = owned.where((item) => item.equipaggiata).toList();
  final hasWeapon = equipped.any((item) => item.arma);
  final hasProtection = equipped.any((item) => item.protegge);
  final bestWeapon = equipped.fold<int>(
    0,
    (best, item) => item.arma ? max(best, item.bonusDanno) : best,
  );
  final bestProtection = equipped.fold<int>(
    0,
    (best, item) => item.protegge ? max(best, item.bonusDifesa) : best,
  );

  OculumRecipe? chosen;
  var bestScore = -1;
  var chosenTotal = 0;
  var chosenMissing = <String, int>{};
  var tied = 0;
  for (final recipe in recipes) {
    final grade = oculumCraftingGradeForRecipe(recipe);
    if (!recipe.visibleToPlayers ||
        recipe.personal ||
        known.contains(recipe.id) ||
        recipe.id.isEmpty ||
        recipe.resultName.trim().isEmpty ||
        grade > characterGrade) {
      continue;
    }
    final quantities = <String, int>{};
    final labels = <String, String>{};
    for (final ingredient in recipe.ingredients) {
      final key = oculumRecipeMaterialKey(ingredient.name);
      final grams = oculumRecipeIngredientGrams(ingredient.grams);
      if (key.isEmpty || grams == 0) continue;
      quantities.update(key, (value) => value + grams, ifAbsent: () => grams);
      labels.putIfAbsent(key, () => ingredient.name.trim());
    }
    final full = quantities.values.fold<int>(0, (sum, grams) => sum + grams);
    final missing = {
      for (final entry in quantities.entries)
        if (entry.value > (available[entry.key] ?? 0))
          labels[entry.key]!: entry.value - (available[entry.key] ?? 0),
    };
    final needed = missing.values.fold<int>(0, (sum, grams) => sum + grams);
    // A one-gram recipe cannot receive a whole number of grams in range.
    if (full < 2 || needed < (full + 3) ~/ 4) continue;
    final output = oculumCraftedEquipmentBonuses(recipe);
    final weapon = const {'weapon', 'arma'}.contains(recipe.forgeTarget);
    final protection = const {
      'armor',
      'protezione',
      'shield',
    }.contains(recipe.forgeTarget);
    final element = oculumNormalizeElementId(output.element);
    final equipmentGap = weapon && !hasWeapon || protection && !hasProtection;
    final upgrades =
        weapon && output.damage > bestWeapon ||
        protection && output.defense > bestProtection;
    final planned =
        plannedRecipeIds.contains(recipe.id) ||
        missing.keys.any(
          (name) => plannedMaterials.contains(oculumRecipeMaterialKey(name)),
        );
    final score =
        (equipmentGap ? 140 : 0) +
        (upgrades ? 50 : 0) +
        (weapon && buildElements.contains(element) ? 60 : 0) +
        (planned ? 90 : 0) +
        max<int>(0, 24 - 6 * (characterGrade - grade)) +
        40 * (full - needed) ~/ full;
    if (score < bestScore) continue;
    if (score == bestScore) {
      tied++;
      if (random.nextInt(tied) != 0) continue;
    } else {
      tied = 1;
    }
    chosen = recipe;
    bestScore = score;
    chosenTotal = full;
    chosenMissing = missing;
  }
  if (chosen == null) return [];
  final recipe = chosen;
  final totalMissing = chosenMissing.values.fold<int>(
    0,
    (sum, value) => sum + value,
  );
  final minimum = (chosenTotal + 3) ~/ 4;
  final maximum = min(totalMissing, chosenTotal * 3 ~/ 4);
  var remaining = minimum + random.nextInt(maximum - minimum + 1);
  final amounts = <String, int>{};
  for (final entry in chosenMissing.entries) {
    amounts[entry.key] = remaining * entry.value ~/ totalMissing;
  }
  remaining -= amounts.values.fold<int>(0, (sum, value) => sum + value);
  final missing = chosenMissing.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  for (final entry in missing.take(remaining)) {
    amounts[entry.key] = amounts[entry.key]! + 1;
  }
  reservedRecipeIds.add(recipe.id);
  return [
    InventoryItem(
      nome: 'Ricetta · ${recipe.name}',
      peso: .02,
      quantita: 1,
      note: 'Leggi per apprendere ${recipe.name}. Bottino di fine Fight.',
      craftData: {
        'recipeBook': {
          'id': 'recipe_drop:${recipe.id}',
          'recipeIds': [recipe.id],
        },
        'recipeBookInstance': 'drop:$killId:${recipe.id}',
      },
    ),
    for (final entry in amounts.entries)
      if (entry.value > 0)
        InventoryItem(
          nome: entry.key,
          peso: entry.value / 1000,
          quantita: 1,
          note: 'Materiale per ${recipe.name}.',
        ),
  ];
}

extension _OculumEncounterCraftingDrop on _OculumHomePageState {
  List<InventoryItem> craftingDropForEncounterParticipant({
    required int sheetIndex,
    required String sheetTag,
    required String killId,
    required List<InventoryItem> earlierDrops,
    required Set<String> reservedRecipeIds,
  }) {
    final sheet = schedePersonaggio[sheetIndex];
    final current = sheetIndex == schedaCorrente;
    final storedItems = current
        ? inventario
        : [
            for (final raw
                in (sheet['inventario'] as List? ?? const []).whereType<Map>())
              InventoryItem.fromJson(Map<String, dynamic>.from(raw)),
          ];
    final grade = current
        ? leggiNumero(gradoController)
        : readIntValue(sheet['grado']);
    final levels = current
        ? leggiNumero(livelloController)
        : readIntValue(sheet['livello']);
    final equipment = storedItems.where(
      (item) =>
          item.equipaggiata &&
          max(item.gradoOggetto, item.gradoRichiesto) <= grade,
    );
    final build = current
        ? usableSheetSearchElements()
        : <String>{
            for (final item in equipment)
              if (item.arma) oculumNormalizeElementId(item.elementoDanno),
            for (final raw
                in (sheet['skills'] as List? ?? const []).whereType<Map>())
              if (raw['equipaggiata'] == true)
                for (final form in CharacterSkill.fromJson(
                  Map<String, dynamic>.from(raw),
                ).forme)
                  if (readIntValue(form.livello) <= levels)
                    for (final effect in form.effettiStrutturati)
                      if (effect.enabled &&
                          effect.elementType.trim().isNotEmpty)
                        oculumNormalizeElementId(effect.elementType),
          };
    final knowledge = current
        ? knownRecipeIds
        : <String>{
            ...((sheet['planarRuntime'] as Map?)?['knownRecipeIds'] as List? ??
                    const [])
                .whereType<String>(),
            ...((partyChest['recipeKnowledgeByTag'] as Map?)?[sheetTag]
                        as List? ??
                    const [])
                .whereType<String>(),
          };
    return oculumMonsterCraftingDrop(
      recipes: recipes,
      inventory: [...storedItems, ...earlierDrops],
      knownRecipeIds: knowledge,
      reservedRecipeIds: reservedRecipeIds,
      buildElements: build,
      plannedRecipeIds: current
          ? favoriteRecipeIds
          : (sheet['favoriteRecipeIds'] as List? ?? const [])
                .whereType<String>()
                .toSet(),
      characterGrade: grade,
      killId: killId,
      // Keep one stable draw for a kill and leave the normal Drop dice untouched.
      random: Random(monsterSpriteStableSeed('crafting:$killId:$sheetTag')),
    );
  }
}
