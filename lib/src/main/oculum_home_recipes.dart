part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

extension _OculumHomeRecipes on _OculumHomePageState {
  bool get canManageRecipes => modalitaMaster || isMasterHost;

  /// Seeds only the authored base recipe. It uses a stable id, so older
  /// campaigns and Master-made recipes retain their exact data and ordering.
  bool ensureCoreOculumRecipes() {
    const id = 'core_pinna_pesce_alato';
    if (recipes.any((recipe) => recipe.id == id)) return false;
    final now = DateTime.now().toIso8601String();
    recipes.add(
      OculumRecipe(
        id: id,
        name: 'Pinna di Pesce Alato',
        ingredients: const <OculumRecipeIngredient>[
          OculumRecipeIngredient(name: 'Polvere del Pesce Alato', grams: '1000'),
          OculumRecipeIngredient(name: 'Acqua contaminata dalle schegge', grams: '1000'),
        ],
        resultName: 'Pinna di Pesce Alato',
        resultDescription:
            'Usa: nuoti nell’aria per 3 turni. Creata spendendo automaticamente 3 Oculum.',
        masterNotes:
            'Si ricava dalla preda Pesce Alato o polverizzando le sue schegge nell’acqua contaminata.',
        visibleToPlayers: true,
        createdAt: now,
        updatedAt: now,
        recipeKind: 'alchemy',
        resultGrams: '250',
        oculumCost: 3,
      ),
    );
    recipesRevision.value++;
    return true;
  }

  int presaMaterialiMassimoBaseGrammi() =>
      max(0, currentStatValue('volonta')) * 500;

  int presaMaterialiMassimoGrammi() =>
      presaMaterialiMassimoBaseGrammi() +
      max(0, presaMaterialiBonusTemporaneoGrammi);

  String formatoPesoMateriali(int grammi) {
    final safe = max(0, grammi);
    if (safe < 1000) return '$safe g';
    final kg = safe / 1000;
    final decimals = safe % 1000 == 0 ? 0 : (safe % 10 == 0 ? 2 : 3);
    return '${kg.toStringAsFixed(decimals).replaceAll('.', ',')} kg';
  }

  int? _leggiGrammiDaKg(String raw, {bool allowZero = false}) {
    final lowered = raw.trim().toLowerCase();
    final isGrams = lowered.endsWith('g') && !lowered.endsWith('kg');
    final normalized = lowered
        .replaceAll(isGrams ? 'g' : 'kg', '')
        .trim()
        .replaceAll(',', '.');
    final parsed = double.tryParse(normalized);
    if (parsed == null || parsed < 0 || (!allowZero && parsed == 0)) {
      return null;
    }
    final grams = isGrams ? parsed : parsed * 1000;
    if ((grams - grams.round()).abs() > 0.001) return null;
    return grams.round();
  }

  Future<double?> _chiediKg({
    required String title,
    required String label,
    String initial = '0,5',
    bool allowZero = false,
  }) async {
    final controller = TextEditingController(text: initial);
    final result = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.text,
          decoration: InputDecoration(
            labelText: label,
            helperText: t(
              'Scrivi 5g, 120g oppure i kg (es. 0,125).',
              'Enter 5g, 120g or kg (e.g. 0.125).',
            ),
          ),
          onSubmitted: (_) {
            final grams = _leggiGrammiDaKg(
              controller.text,
              allowZero: allowZero,
            );
            if (grams != null) {
              Navigator.pop(dialogContext, grams / 1000);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(t('Annulla', 'Cancel')),
          ),
          FilledButton(
            onPressed: () {
              final grams = _leggiGrammiDaKg(
                controller.text,
                allowZero: allowZero,
              );
              if (grams == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      t(
                        'Inserisci un valore valido fino al singolo grammo.',
                        'Enter a valid value down to one gram.',
                      ),
                    ),
                  ),
                );
                return;
              }
              Navigator.pop(dialogContext, grams / 1000);
            },
            child: Text(t('Conferma', 'Confirm')),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _usaPresaMateriali() async {
    final kg = await _chiediKg(
      title: t('Raccogli materiali', 'Gather materials'),
      label: t('Quanto prendi/spendi (kg)', 'Amount taken/spent (kg)'),
    );
    if (kg == null || !mounted) return;
    final requested = (kg * 1000).round();
    if (requested > presaMaterialiGrammi) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t(
              'Presa insufficiente: disponibili ${formatoPesoMateriali(presaMaterialiGrammi)}.',
              'Insufficient capacity: ${formatoPesoMateriali(presaMaterialiGrammi)} available.',
            ),
          ),
        ),
      );
      return;
    }
    setState(() {
      presaMaterialiGrammi -= requested;
      risultato = t(
        'Materiali presi: ${formatoPesoMateriali(requested)}. Presa rimasta: ${formatoPesoMateriali(presaMaterialiGrammi)}.',
        'Materials taken: ${formatoPesoMateriali(requested)}. Remaining capacity: ${formatoPesoMateriali(presaMaterialiGrammi)}.',
      );
      aggiungiLog(risultato);
    });
    programmaSalvataggio();
  }

  Future<void> _aumentaPresaMaterialiTemporanea() async {
    final kg = await _chiediKg(
      title: t('Aumento temporaneo', 'Temporary increase'),
      label: t('Bonus temporaneo (kg)', 'Temporary bonus (kg)'),
    );
    if (kg == null || !mounted) return;
    final added = (kg * 1000).round();
    setState(() {
      presaMaterialiBonusTemporaneoGrammi += added;
      presaMaterialiGrammi += added;
      risultato = t(
        'Presa materiali aumentata temporaneamente di ${formatoPesoMateriali(added)}.',
        'Material capacity temporarily increased by ${formatoPesoMateriali(added)}.',
      );
      aggiungiLog(risultato);
    });
    programmaSalvataggio();
  }

  void _refullaPresaMateriali() {
    setState(() {
      presaMaterialiGrammi = presaMaterialiMassimoGrammi();
      risultato = t(
        'Presa materiali ricaricata manualmente a ${formatoPesoMateriali(presaMaterialiGrammi)}.',
        'Material capacity manually refilled to ${formatoPesoMateriali(presaMaterialiGrammi)}.',
      );
      aggiungiLog(risultato);
    });
    programmaSalvataggio();
  }

  String _newRecipeId() =>
      'recipe_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(999999)}';

  bool _recipeTargetMatches(String rawTarget) {
    final target = rawTarget.trim().toUpperCase();
    if (target.isEmpty) return true;
    return localOculumTags()
        .map((tag) => tag.trim().toUpperCase())
        .contains(target);
  }

  bool receiveRealtimeRecipesSnapshot(Map<String, dynamic> payload) {
    if ('${payload['campaignId'] ?? ''}'.trim() != activeCampaignId ||
        !_recipeTargetMatches('${payload['targetTag'] ?? ''}')) {
      return false;
    }
    final raw = payload['recipes'];
    if (raw is! List) return false;
    final incoming = raw
        .whereType<Map>()
        .map((item) => OculumRecipe.fromJson(Map<String, dynamic>.from(item)))
        .where((recipe) => !recipe.personal)
        .toList(growable: false);
    final current = recipes
        .map((recipe) => jsonEncode(recipe.toJson()))
        .join('|');
    final next = incoming
        .map((recipe) => jsonEncode(recipe.toJson()))
        .join('|');
    if (current == next) return false;
    recipes
      ..clear()
      ..addAll(incoming);
    recipesRevision.value++;
    return true;
  }

  Future<void> sendRealtimeRecipesSnapshot({String targetTag = ''}) async {
    final service = realtimeService;
    if (service?.isConnected != true || !realtimeIsMasterRole) return;
    await service!.sendRecipesSnapshot(
      recipes: recipes.map((recipe) => recipe.toJson()).toList(growable: false),
      campaignId: activeCampaignId,
      campaignName: activeCampaignName(),
      targetTag: targetTag,
    );
  }

  void syncRealtimeRecipes() {
    final service = realtimeService;
    if (service?.isConnected != true) return;
    if (realtimeIsMasterRole) {
      unawaited(sendRealtimeRecipesSnapshot());
    } else {
      unawaited(
        service!.sendRecipesRequest(
          requesterTag: storySessionAuthorTag(),
          campaignId: activeCampaignId,
        ),
      );
    }
  }

  void _notifyRecipesChanged({bool campaignShared = true}) {
    recipesRevision.value++;
    programmaSalvataggio(
      invalidateCaches: false,
      delay: const Duration(milliseconds: 450),
    );
    if (campaignShared && realtimeIsMasterRole) {
      unawaited(sendRealtimeRecipesSnapshot());
    }
  }

  Future<void> _openRecipeEditor([OculumRecipe? existing]) async {
    final personalEdit = existing?.personal == true;
    if ((!canManageRecipes && !personalEdit) || recipeMutationInProgress) {
      return;
    }
    recipeMutationInProgress = true;
    try {
      final result = await showDialog<OculumRecipe>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => _OculumRecipeEditorDialog(
          existing: existing,
          recipeId: existing?.id ?? _newRecipeId(),
          primaryColor: primaryColor,
          tertiaryColor: tertiaryColor,
          english: linguaInglese,
        ),
      );
      if (!mounted || result == null || (!canManageRecipes && !personalEdit)) {
        return;
      }

      final target = result.personal ? personalRecipes : recipes;
      final existingIndex = target.indexWhere((item) => item.id == result.id);
      if (existingIndex >= 0) {
        target[existingIndex] = result;
      } else {
        target.insert(0, result);
      }
      _notifyRecipesChanged(campaignShared: !result.personal);
    } finally {
      recipeMutationInProgress = false;
    }
  }

  Future<void> _duplicateRecipe(OculumRecipe source) async {
    if (!canManageRecipes || recipeMutationInProgress) return;
    recipeMutationInProgress = true;
    try {
      final now = DateTime.now().toIso8601String();
      recipes.insert(
        0,
        source.copyWith(
          id: _newRecipeId(),
          name: '${source.name} ${t('(copia)', '(copy)')}',
          ingredients: source.ingredients
              .map(
                (item) =>
                    OculumRecipeIngredient(name: item.name, grams: item.grams),
              )
              .toList(growable: false),
          createdAt: now,
          updatedAt: now,
        ),
      );
      _notifyRecipesChanged();
      await Future<void>.delayed(const Duration(milliseconds: 350));
    } finally {
      recipeMutationInProgress = false;
    }
  }

  Future<void> _deleteRecipe(OculumRecipe recipe) async {
    if ((!canManageRecipes && !recipe.personal) || recipeMutationInProgress) {
      return;
    }
    recipeMutationInProgress = true;
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: const Color(0xFF10121A),
          title: Text(
            t('Elimina ricetta', 'Delete recipe'),
            style: const TextStyle(color: Colors.white),
          ),
          content: Text(
            t(
              'Vuoi eliminare definitivamente “${recipe.name}”?',
              'Permanently delete “${recipe.name}”?',
            ),
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(t('Annulla', 'Cancel')),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.delete_outline),
              label: Text(t('Elimina', 'Delete')),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true) return;
      (recipe.personal ? personalRecipes : recipes).removeWhere(
        (item) => item.id == recipe.id,
      );
      _notifyRecipesChanged(campaignShared: !recipe.personal);
    } finally {
      recipeMutationInProgress = false;
    }
  }

  Future<void> _createPersonalRecipe(OculumRecipe source) async {
    final owner = storySessionAuthorTag();
    final now = DateTime.now().toIso8601String();
    await _openRecipeEditor(
      source.copyWith(
        id: _newRecipeId(),
        name: '${source.name} ${t('(personale)', '(personal)')}',
        personal: true,
        ownerTag: owner,
        sourceRecipeId: source.id,
        visibleToPlayers: false,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> _createBlankPersonalRecipe({String category = 'crafting'}) {
    final now = DateTime.now().toIso8601String();
    return _openRecipeEditor(
      OculumRecipe(
        id: _newRecipeId(),
        name: '',
        ingredients: const <OculumRecipeIngredient>[],
        resultName: '',
        resultDescription: '',
        masterNotes: '',
        visibleToPlayers: false,
        createdAt: now,
        updatedAt: now,
        recipeKind: category,
        personal: true,
        ownerTag: storySessionAuthorTag(),
      ),
    );
  }

  Future<void> _applyPersonalForge(OculumRecipe recipe) async {
    final candidates = inventario
        .where((item) {
          if (recipe.forgeTarget == 'arma') return item.arma;
          if (recipe.forgeTarget == 'protezione') return item.protegge;
          return item.arma || item.protegge;
        })
        .toList(growable: false);
    if (candidates.isEmpty || !mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t('Nessun oggetto compatibile.', 'No compatible item.'),
          ),
        ),
      );
      return;
    }
    final selected = await showDialog<InventoryItem>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(t('Applica Forge a…', 'Apply Forge to…')),
        children: [
          for (final item in candidates)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, item),
              child: Text(item.nome),
            ),
        ],
      ),
    );
    if (selected == null || !mounted) return;
    final effect = recipe.forgeEffectText.trim();
    setState(() {
      if (effect.isNotEmpty && !selected.buff.contains(effect)) {
        selected.buff = [
          selected.buff.trim(),
          effect,
        ].where((part) => part.isNotEmpty).join('\n');
      }
      final forgeNote = 'Forge: ${recipe.name}';
      if (!selected.note.contains(forgeNote)) {
        selected.note = [
          selected.note.trim(),
          forgeNote,
        ].where((part) => part.isNotEmpty).join('\n');
      }
    });
    invalidateDerivedDataCaches();
    programmaSalvataggio();
  }

  String _recipeMaterialKey(String name) => name.trim().toLowerCase();

  int _recipeGrams(String raw) =>
      (double.tryParse(raw.replaceAll(',', '.')) ?? 0).round();

  int _finishedProductGrams(OculumRecipe recipe) {
    final explicit = _recipeGrams(recipe.resultGrams);
    if (explicit > 0) return explicit;
    return recipe.ingredients.fold<int>(
      0,
      (total, ingredient) => total + _recipeGrams(ingredient.grams),
    );
  }

  Map<String, int> _availableRecipeMaterialGrams() {
    final available = <String, int>{};
    for (final item in inventario) {
      final key = _recipeMaterialKey(item.nome);
      if (key.isEmpty) continue;
      final grams = (item.peso * 1000 * max(0, item.quantita)).round();
      available[key] = (available[key] ?? 0) + max(0, grams);
    }
    return available;
  }

  List<OculumRecipeIngredient> _recipeRequirements(
    OculumRecipe recipe, {
    int quantity = 1,
  }) {
    final required = <String, int>{};
    final labels = <String, String>{};
    for (final ingredient in recipe.ingredients) {
      final key = _recipeMaterialKey(ingredient.name);
      if (key.isEmpty) continue;
      required[key] =
          (required[key] ?? 0) +
          _recipeGrams(ingredient.grams) * max(1, quantity);
      labels.putIfAbsent(key, () => ingredient.name.trim());
    }
    return required.entries
        .map(
          (entry) => OculumRecipeIngredient(
            name: labels[entry.key] ?? entry.key,
            grams: '${entry.value}',
          ),
        )
        .toList(growable: false);
  }

  List<OculumRecipeIngredient> _missingRecipeIngredients(
    OculumRecipe recipe, {
    int quantity = 1,
  }) {
    final available = _availableRecipeMaterialGrams();
    return _recipeRequirements(recipe, quantity: quantity)
        .where(
          (ingredient) =>
              (available[_recipeMaterialKey(ingredient.name)] ?? 0) <
              _recipeGrams(ingredient.grams),
        )
        .map(
          (ingredient) => OculumRecipeIngredient(
            name: ingredient.name,
            grams:
                '${_recipeGrams(ingredient.grams) - (available[_recipeMaterialKey(ingredient.name)] ?? 0)}',
          ),
        )
        .toList(growable: false);
  }

  void _consumeRecipeMaterial(String name, int grams) {
    var remaining = grams;
    final key = _recipeMaterialKey(name);
    for (
      var index = inventario.length - 1;
      index >= 0 && remaining > 0;
      index--
    ) {
      final item = inventario[index];
      if (_recipeMaterialKey(item.nome) != key) continue;
      final itemGrams = (item.peso * 1000 * max(0, item.quantita)).round();
      final consumed = min(itemGrams, remaining);
      final left = itemGrams - consumed;
      remaining -= consumed;
      if (left <= 0) {
        inventario.removeAt(index);
      } else {
        // Materials can be consumed down to one gram; keep the remainder as one stack.
        item
          ..quantita = 1
          ..peso = left / 1000;
      }
    }
  }

  Future<void> _craftRecipe(OculumRecipe recipe, {int quantity = 1}) async {
    final safeQuantity = max(1, quantity);
    final missing = _missingRecipeIngredients(recipe, quantity: safeQuantity);
    final oculumRequired = max(0, recipe.oculumCost) * safeQuantity;
    if (missing.isNotEmpty) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(t('Materiali mancanti', 'Missing materials')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t(
                  'Per ${recipe.name} ×$safeQuantity ti manca:',
                  'For ${recipe.name} ×$safeQuantity you need:',
                ),
              ),
              const SizedBox(height: 10),
              ...missing.map(
                (item) => Text(
                  '• ${cleanUiText(item.name)}: ${formatoPesoMateriali(_recipeGrams(item.grams))}',
                ),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(t('Va bene', 'OK')),
            ),
          ],
        ),
      );
      return;
    }

    if (leggiNumero(currentOculumController) < oculumRequired) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(t('Oculum insufficiente', 'Insufficient Oculum')),
          content: Text(
            t(
              'Per ${recipe.name} ×$safeQuantity servono $oculumRequired Oculum.',
              '${recipe.name} ×$safeQuantity requires $oculumRequired Oculum.',
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(t('Va bene', 'OK')),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      for (final ingredient in recipe.ingredients) {
        _consumeRecipeMaterial(
          ingredient.name,
          _recipeGrams(ingredient.grams) * safeQuantity,
        );
      }
      if (oculumRequired > 0) {
        currentOculumController.text = max(
          0,
          leggiNumero(currentOculumController) - oculumRequired,
        ).toString();
      }
      inventario.add(
        InventoryItem(
          nome: recipe.resultName,
          peso: _finishedProductGrams(recipe) / 1000,
          quantita: safeQuantity,
          note: recipe.resultDescription,
        ),
      );
      risultato = t(
        '${recipe.resultName} ×$safeQuantity creato: ${formatoPesoMateriali(_finishedProductGrams(recipe) * safeQuantity)}${oculumRequired > 0 ? ', -$oculumRequired Oculum' : ''}.',
        '${recipe.resultName} ×$safeQuantity crafted: ${formatoPesoMateriali(_finishedProductGrams(recipe) * safeQuantity)}${oculumRequired > 0 ? ', -$oculumRequired Oculum' : ''}.',
      );
      aggiungiLog(risultato);
    });
    invalidateDerivedDataCaches();
    programmaSalvataggio();
  }

  Future<void> _openCraftingPreview(OculumRecipe recipe) async {
    final quantityController = TextEditingController(text: '1');
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final quantity = max(1, int.tryParse(quantityController.text) ?? 1);
          final requirements = _recipeRequirements(recipe, quantity: quantity);
          final available = _availableRecipeMaterialGrams();
          final missing = _missingRecipeIngredients(recipe, quantity: quantity);
          final oculumRequired = max(0, recipe.oculumCost) * quantity;
          final currentOculum = leggiNumero(currentOculumController);
          final canCraft = missing.isEmpty && currentOculum >= oculumRequired;
          return AlertDialog(
            title: Text(t('Anteprima crafting', 'Crafting preview')),
            content: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: quantityController,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: t('Quantità da creare', 'Quantity to craft'),
                      helperText: t(
                        'Materiali e peso vengono calcolati prima di confermare.',
                        'Materials and weight are calculated before confirming.',
                      ),
                    ),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '${cleanUiText(recipe.resultName)} ×$quantity · ${formatoPesoMateriali(_finishedProductGrams(recipe) * quantity)}',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  if (oculumRequired > 0) ...[
                    const SizedBox(height: 6),
                    Text(
                      t(
                        'Oculum: $oculumRequired / $currentOculum',
                        'Oculum: $oculumRequired / $currentOculum',
                      ),
                      style: TextStyle(
                        color: currentOculum >= oculumRequired
                            ? Colors.lightBlueAccent
                            : Colors.redAccent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(t('Materiali richiesti', 'Required materials')),
                  const SizedBox(height: 6),
                  ...requirements.map((ingredient) {
                    final required = _recipeGrams(ingredient.grams);
                    final owned =
                        available[_recipeMaterialKey(ingredient.name)] ?? 0;
                    final enough = owned >= required;
                    return Text(
                      '• ${cleanUiText(ingredient.name)}: ${formatoPesoMateriali(required)} / ${formatoPesoMateriali(owned)}',
                      style: TextStyle(
                        color: enough ? Colors.greenAccent : Colors.redAccent,
                      ),
                    );
                  }),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(t('Annulla', 'Cancel')),
              ),
              FilledButton.icon(
                onPressed: canCraft
                    ? () {
                        Navigator.pop(dialogContext);
                        _craftRecipe(recipe, quantity: quantity);
                      }
                    : null,
                icon: const Icon(Icons.handyman_outlined),
                label: Text(t('Conferma creazione', 'Confirm craft')),
              ),
            ],
          );
        },
      ),
    );
    quantityController.dispose();
  }

  Widget _craftingDemandPanel() {
    final selected = <OculumRecipe>[...recipes, ...personalRecipes]
        .where(
          (recipe) =>
              recipe.recipeKind != 'forge' &&
              favoriteRecipeIds.contains(recipe.id),
        )
        .toList(growable: false);
    if (selected.isEmpty) return const SizedBox.shrink();

    final requirements = <String, OculumRecipeIngredient>{};
    for (final recipe in selected) {
      final quantity = max(1, craftingDemandQuantities[recipe.id] ?? 1);
      for (final ingredient in _recipeRequirements(
        recipe,
        quantity: quantity,
      )) {
        final key = _recipeMaterialKey(ingredient.name);
        final current = requirements[key];
        requirements[key] = OculumRecipeIngredient(
          name: current?.name ?? ingredient.name,
          grams:
              '${_recipeGrams(current?.grams ?? '0') + _recipeGrams(ingredient.grams)}',
        );
      }
    }
    final available = _availableRecipeMaterialGrams();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('Fabbisogno crafting', 'Crafting requirements'),
            style: const TextStyle(
              color: Colors.amberAccent,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            t(
              'Aggregato delle ricette preferite. Imposta quante copie vuoi preparare.',
              'Aggregate of favorite recipes. Set how many copies you want to prepare.',
            ),
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final recipe in selected)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        cleanUiText(recipe.name),
                        style: const TextStyle(color: Colors.white),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: t('Una copia in meno', 'One less copy'),
                        onPressed: () {
                          setState(() {
                            final next = max(
                              1,
                              (craftingDemandQuantities[recipe.id] ?? 1) - 1,
                            );
                            craftingDemandQuantities[recipe.id] = next;
                          });
                          _notifyRecipesChanged(campaignShared: false);
                        },
                        icon: const Icon(Icons.remove, size: 17),
                      ),
                      Text(
                        '×${max(1, craftingDemandQuantities[recipe.id] ?? 1)}',
                        style: const TextStyle(
                          color: Colors.amberAccent,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: t('Una copia in più', 'One more copy'),
                        onPressed: () {
                          setState(() {
                            craftingDemandQuantities[recipe.id] = max(
                              1,
                              (craftingDemandQuantities[recipe.id] ?? 1) + 1,
                            );
                          });
                          _notifyRecipesChanged(campaignShared: false);
                        },
                        icon: const Icon(Icons.add, size: 17),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ...requirements.values.map((ingredient) {
            final required = _recipeGrams(ingredient.grams);
            final owned = available[_recipeMaterialKey(ingredient.name)] ?? 0;
            final enough = owned >= required;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• ${cleanUiText(ingredient.name)}: ${formatoPesoMateriali(required)} / ${formatoPesoMateriali(owned)}',
                style: TextStyle(
                  color: enough ? Colors.greenAccent : Colors.redAccent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget recipesPage() {
    final isMaster = canManageRecipes;
    final gatherableMaterialKg = formatoPesoMateriali(presaMaterialiGrammi);
    final gatherableMaterialMaxKg = formatoPesoMateriali(
      presaMaterialiMassimoGrammi(),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('Ricette', 'Recipes'),
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isMaster
                          ? t(
                              'Crea e gestisci il ricettario della campagna.',
                              'Create and manage the campaign cookbook.',
                            )
                          : t(
                              'Consulta le ricette condivise dal Master.',
                              'Browse recipes shared by the Game Master.',
                            ),
                      style: const TextStyle(color: Colors.white60),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (isMaster)
                    FilledButton.icon(
                      key: const ValueKey<String>('recipe_create_button'),
                      onPressed: () => _openRecipeEditor(),
                      icon: const Icon(Icons.add),
                      label: Text(t('Nuova campagna', 'New campaign recipe')),
                    ),
                  OutlinedButton.icon(
                    onPressed: () => _createBlankPersonalRecipe(),
                    icon: const Icon(Icons.person_add_alt_1),
                    label: Text(t('Nuova personale', 'New personal recipe')),
                  ),
                  if (selectedForgeTemplateId.isNotEmpty)
                    FilledButton.icon(
                      onPressed: () {
                        final index = recipes.indexWhere(
                          (recipe) =>
                              recipe.id == selectedForgeTemplateId &&
                              recipe.recipeKind == 'forge',
                        );
                        if (index >= 0) {
                          _createPersonalRecipe(recipes[index]);
                        }
                      },
                      icon: const Icon(Icons.auto_fix_high),
                      label: Text(t('Forgia selezionata', 'Forge selected')),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFA726).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFFA726).withValues(alpha: 0.55),
              ),
            ),
            child: Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Icon(Icons.scale_outlined, color: Color(0xFFFFA726)),
                SizedBox(
                  width: 360,
                  child: Text(
                    t(
                      'Presa materiali: $gatherableMaterialKg / $gatherableMaterialMaxKg '
                          '(Volontà ${currentStatValue('volonta')} ÷ 2)',
                      'Material capacity: $gatherableMaterialKg / $gatherableMaterialMaxKg '
                          '(Will ${currentStatValue('volonta')} ÷ 2)',
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: _usaPresaMateriali,
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: Text(t('Prendi', 'Take')),
                ),
                OutlinedButton.icon(
                  onPressed: _aumentaPresaMaterialiTemporanea,
                  icon: const Icon(Icons.add),
                  label: Text(t('Bonus temporaneo', 'Temporary bonus')),
                ),
                IconButton(
                  tooltip: t('Ricarica manualmente', 'Refill manually'),
                  onPressed: _refullaPresaMateriali,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _craftingDemandPanel(),
          if (favoriteRecipeIds.isNotEmpty) const SizedBox(height: 14),
          TextField(
            key: const ValueKey<String>('recipe_search_field'),
            controller: recipeSearchController,
            onChanged: (value) => recipeSearchQuery.value = value,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: t(
                'Cerca per nome, ingrediente o risultato',
                'Search by name, ingredient, or result',
              ),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: ValueListenableBuilder<String>(
                valueListenable: recipeSearchQuery,
                builder: (context, query, child) => query.isEmpty
                    ? const SizedBox.shrink()
                    : IconButton(
                        tooltip: t('Cancella ricerca', 'Clear search'),
                        onPressed: () {
                          recipeSearchController.clear();
                          recipeSearchQuery.value = '';
                        },
                        icon: const Icon(Icons.close),
                      ),
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.055),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ValueListenableBuilder<int>(
              valueListenable: recipesRevision,
              builder: (context, revision, child) =>
                  ValueListenableBuilder<String>(
                    valueListenable: recipeSearchQuery,
                    builder: (context, query, child) {
                      final visiblePersonal = oculumVisibleRecipes(
                        recipes: personalRecipes,
                        isMaster: true,
                        query: query,
                      );
                      final visibleCampaign = oculumVisibleRecipes(
                        recipes: recipes,
                        isMaster: isMaster,
                        query: query,
                      );
                      visiblePersonal.sort(_sortRecipesForCrafting);
                      visibleCampaign.sort(_sortRecipesForCrafting);
                      if (visiblePersonal.isEmpty && visibleCampaign.isEmpty) {
                        return Center(
                          child: Text(
                            query.trim().isNotEmpty
                                ? t(
                                    'Nessuna ricetta corrisponde alla ricerca.',
                                    'No recipes match your search.',
                                  )
                                : isMaster
                                ? t(
                                    'Nessuna ricetta. Crea la prima ricetta.',
                                    'No recipes yet. Create the first one.',
                                  )
                                : t(
                                    'Il Master non ha ancora condiviso ricette.',
                                    'The Game Master has not shared recipes yet.',
                                  ),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 16,
                            ),
                          ),
                        );
                      }
                      return ListView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        children: [
                          if (visibleCampaign.isNotEmpty) ...[
                            _recipeSectionTitle(
                              t('Ricette della campagna', 'Campaign recipes'),
                            ),
                            const SizedBox(height: 8),
                            for (final recipe in visibleCampaign) ...[
                              _recipeCard(recipe, isMaster: isMaster),
                              const SizedBox(height: 12),
                            ],
                          ],
                          if (visiblePersonal.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            _recipeSectionTitle(
                              t('Ricette personali', 'Personal recipes'),
                            ),
                            const SizedBox(height: 8),
                            for (final recipe in visiblePersonal) ...[
                              _recipeCard(recipe, isMaster: isMaster),
                              const SizedBox(height: 12),
                            ],
                          ],
                        ],
                      );
                    },
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _recipeCard(OculumRecipe recipe, {required bool isMaster}) {
    final gatherableMaterialKg = formatoPesoMateriali(presaMaterialiGrammi);
    final missingMaterials = recipe.recipeKind == 'forge'
        ? const <OculumRecipeIngredient>[]
        : _missingRecipeIngredients(recipe);
    final categoryColor = switch (recipe.recipeKind) {
      'forge' =>
        recipe.personal ? const Color(0xFFFFA726) : const Color(0xFFE53935),
      'alchemy' =>
        recipe.personal ? const Color(0xFF8BE28B) : const Color(0xFF2EAD5B),
      _ => recipe.personal ? const Color(0xFF62C7FF) : const Color(0xFF1976D2),
    };
    return RepaintBoundary(
      key: ValueKey<String>('recipe_card_${recipe.id}'),
      child: Card(
        color: Color.lerp(const Color(0xFF10121A), categoryColor, 0.12),
        elevation: 1,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: categoryColor.withValues(alpha: 0.75)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      cleanUiText(recipe.name),
                      style: TextStyle(
                        color: categoryColor,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (recipe.personal)
                    const Chip(
                      avatar: Icon(Icons.person_outline, size: 16),
                      label: Text('Personale'),
                      visualDensity: VisualDensity.compact,
                    ),
                  IconButton(
                    tooltip: favoriteRecipeIds.contains(recipe.id)
                        ? t('Rimuovi dai preferiti', 'Remove from favorites')
                        : t('Aggiungi ai preferiti', 'Add to favorites'),
                    onPressed: () {
                      setState(() {
                        if (!favoriteRecipeIds.add(recipe.id)) {
                          favoriteRecipeIds.remove(recipe.id);
                        }
                      });
                      _notifyRecipesChanged(campaignShared: false);
                    },
                    icon: Icon(
                      favoriteRecipeIds.contains(recipe.id)
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.amberAccent,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Chip(
                    label: Text(switch (recipe.recipeKind) {
                      'forge' => t('Forgia', 'Forge'),
                      'alchemy' => t('Alchimia', 'Alchemy'),
                      _ => 'Crafting',
                    }),
                    backgroundColor: categoryColor.withValues(alpha: 0.2),
                    side: BorderSide(color: categoryColor),
                    visualDensity: VisualDensity.compact,
                  ),
                  if (isMaster)
                    Chip(
                      avatar: Icon(
                        recipe.visibleToPlayers
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 16,
                      ),
                      label: Text(
                        recipe.visibleToPlayers
                            ? t('Visibile', 'Visible')
                            : t('Segreta', 'Hidden'),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (recipe.recipeKind == 'forge') ...[
                _recipeSectionTitle('Forge'),
                const SizedBox(height: 6),
                Text(
                  '${t('Peso', 'Weight')}: ${recipe.forgeWeightMinKg.isEmpty ? '?' : recipe.forgeWeightMinKg}–${recipe.forgeWeightMaxKg.isEmpty ? '?' : recipe.forgeWeightMaxKg} kg · ${t('Presa', 'Capacity')}: $gatherableMaterialKg',
                  style: const TextStyle(color: Colors.white70),
                ),
                if (recipe.forgeDuration.trim().isNotEmpty)
                  Text(
                    '${t('Tempo', 'Time')}: ${cleanUiText(recipe.forgeDuration)}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                if (recipe.forgeAttributes.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${t('Attributi', 'Attributes')}: ${cleanUiText(recipe.forgeAttributes)}',
                    style: const TextStyle(color: Colors.white70, height: 1.35),
                  ),
                ],
                if (recipe.forgeEffectText.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${t('Effetti/parser', 'Effects/parser')}: ${cleanUiText(recipe.forgeEffectText)}',
                    style: TextStyle(color: primaryColor, height: 1.35),
                  ),
                ],
                const Divider(height: 24),
              ],
              _recipeSectionTitle(t('Ingredienti', 'Ingredients')),
              const SizedBox(height: 6),
              ...recipe.ingredients.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.circle, size: 6, color: tertiaryColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          cleanUiText(item.name),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      Text(
                        '${item.grams} g',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 24),
              _recipeSectionTitle(t('Risultato', 'Result')),
              const SizedBox(height: 5),
              Text(
                cleanUiText(recipe.resultName),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                cleanUiText(recipe.resultDescription),
                style: const TextStyle(color: Colors.white70, height: 1.35),
              ),
              if (recipe.recipeKind != 'forge') ...[
                const SizedBox(height: 8),
                Text(
                  '${t('Grammatura prodotto finito', 'Finished product weight')}: ${formatoPesoMateriali(_finishedProductGrams(recipe))}',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color:
                        (missingMaterials.isEmpty ? Colors.green : Colors.red)
                            .withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        missingMaterials.isEmpty
                            ? t(
                                'Scheda crafting: materiali disponibili',
                                'Crafting panel: materials available',
                              )
                            : t(
                                'Scheda crafting: materiali mancanti',
                                'Crafting panel: missing materials',
                              ),
                        style: TextStyle(
                          color: missingMaterials.isEmpty
                              ? Colors.greenAccent
                              : Colors.redAccent,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (missingMaterials.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        ...missingMaterials.map(
                          (item) => Text(
                            '• ${cleanUiText(item.name)}: ${formatoPesoMateriali(_recipeGrams(item.grams))}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: () => _openCraftingPreview(recipe),
                        icon: const Icon(Icons.preview_outlined),
                        label: Text(t('Anteprima e crea', 'Preview and craft')),
                      ),
                    ],
                  ),
                ),
              ],
              if (isMaster && recipe.masterNotes.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${t('Note del Master', 'Game Master notes')}: ${cleanUiText(recipe.masterNotes)}',
                    style: const TextStyle(color: Colors.amberAccent),
                  ),
                ),
              ],
              if (!recipe.personal) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    if (recipe.recipeKind == 'forge')
                      OutlinedButton.icon(
                        onPressed: () {
                          selectedForgeTemplateId = recipe.id;
                          programmaSalvataggio(invalidateCaches: false);
                          recipesRevision.value++;
                        },
                        icon: Icon(
                          selectedForgeTemplateId == recipe.id
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                        ),
                        label: Text(t('Segna Forge', 'Mark Forge')),
                      ),
                    FilledButton.icon(
                      onPressed: () => _createPersonalRecipe(recipe),
                      icon: Icon(
                        recipe.recipeKind == 'forge'
                            ? Icons.auto_fix_high
                            : Icons.person_add_alt_1,
                      ),
                      label: Text(
                        recipe.recipeKind == 'forge'
                            ? t('Forgia per me', 'Forge for me')
                            : t('Copia personale', 'Personal copy'),
                      ),
                    ),
                  ],
                ),
              ],
              if (isMaster || recipe.personal) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _openRecipeEditor(recipe),
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(t('Modifica', 'Edit')),
                    ),
                    if (!recipe.personal)
                      OutlinedButton.icon(
                        onPressed: () => _duplicateRecipe(recipe),
                        icon: const Icon(Icons.copy_outlined),
                        label: Text(t('Duplica', 'Duplicate')),
                      ),
                    if (recipe.personal && recipe.recipeKind == 'forge')
                      FilledButton.icon(
                        onPressed: () => _applyPersonalForge(recipe),
                        icon: const Icon(Icons.build_circle_outlined),
                        label: Text(t('Usa sull’oggetto', 'Use on item')),
                      ),
                    OutlinedButton.icon(
                      onPressed: () => _deleteRecipe(recipe),
                      icon: const Icon(Icons.delete_outline),
                      label: Text(t('Elimina', 'Delete')),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _recipeSectionTitle(String text) => Text(
    text.toUpperCase(),
    style: TextStyle(
      color: tertiaryColor,
      fontSize: 11,
      fontWeight: FontWeight.w900,
      letterSpacing: 1.2,
    ),
  );

  int _sortRecipesForCrafting(OculumRecipe left, OculumRecipe right) {
    final leftFavorite = favoriteRecipeIds.contains(left.id);
    final rightFavorite = favoriteRecipeIds.contains(right.id);
    if (leftFavorite != rightFavorite) return leftFavorite ? -1 : 1;
    return left.name.toLowerCase().compareTo(right.name.toLowerCase());
  }
}

class _OculumRecipeEditorDialog extends StatefulWidget {
  const _OculumRecipeEditorDialog({
    required this.existing,
    required this.recipeId,
    required this.primaryColor,
    required this.tertiaryColor,
    required this.english,
  });

  final OculumRecipe? existing;
  final String recipeId;
  final Color primaryColor;
  final Color tertiaryColor;
  final bool english;

  @override
  State<_OculumRecipeEditorDialog> createState() =>
      _OculumRecipeEditorDialogState();
}

class _OculumRecipeEditorDialogState extends State<_OculumRecipeEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _resultController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _resultGramsController;
  late final TextEditingController _notesController;
  late final TextEditingController _forgeMinKgController;
  late final TextEditingController _forgeMaxKgController;
  late final TextEditingController _forgeDurationController;
  late final TextEditingController _forgeAttributesController;
  late final TextEditingController _forgeEffectController;
  final List<_RecipeIngredientControllers> _ingredients = [];
  late bool _visibleToPlayers;
  late String _recipeCategory;
  late String _forgeTarget;
  bool _submitting = false;

  String _t(String italian, String english) =>
      widget.english ? english : italian;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _resultController = TextEditingController(text: existing?.resultName ?? '');
    _descriptionController = TextEditingController(
      text: existing?.resultDescription ?? '',
    );
    _resultGramsController = TextEditingController(
      text: existing?.resultGrams ?? '',
    );
    _notesController = TextEditingController(text: existing?.masterNotes ?? '');
    _forgeMinKgController = TextEditingController(
      text: existing?.forgeWeightMinKg ?? '',
    );
    _forgeMaxKgController = TextEditingController(
      text: existing?.forgeWeightMaxKg ?? '',
    );
    _forgeDurationController = TextEditingController(
      text: existing?.forgeDuration ?? '',
    );
    _forgeAttributesController = TextEditingController(
      text: existing?.forgeAttributes ?? '',
    );
    _forgeEffectController = TextEditingController(
      text: existing?.forgeEffectText ?? '',
    );
    _visibleToPlayers = existing?.visibleToPlayers ?? true;
    _recipeCategory = existing?.recipeKind ?? 'crafting';
    _forgeTarget = existing?.forgeTarget ?? 'auto';
    for (final ingredient in existing?.ingredients ?? const []) {
      _ingredients.add(
        _RecipeIngredientControllers(
          name: ingredient.name,
          grams: ingredient.grams,
        ),
      );
    }
    if (_ingredients.isEmpty) _ingredients.add(_RecipeIngredientControllers());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _resultController.dispose();
    _descriptionController.dispose();
    _resultGramsController.dispose();
    _notesController.dispose();
    _forgeMinKgController.dispose();
    _forgeMaxKgController.dispose();
    _forgeDurationController.dispose();
    _forgeAttributesController.dispose();
    _forgeEffectController.dispose();
    for (final ingredient in _ingredients) {
      ingredient.dispose();
    }
    super.dispose();
  }

  void _addIngredient() {
    setState(() => _ingredients.add(_RecipeIngredientControllers()));
  }

  void _removeIngredient(int index) {
    final removed = _ingredients.removeAt(index);
    removed.dispose();
    setState(() {});
  }

  void _submit() {
    if (_submitting) return;
    setState(() => _submitting = true);
    if (!(_formKey.currentState?.validate() ?? false) || _ingredients.isEmpty) {
      setState(() => _submitting = false);
      if (_ingredients.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _t(
                'Aggiungi almeno un ingrediente.',
                'Add at least one ingredient.',
              ),
            ),
          ),
        );
      }
      return;
    }

    final normalizedIngredients = <OculumRecipeIngredient>[];
    for (final ingredient in _ingredients) {
      final grams = oculumNormalizePositiveGramText(ingredient.grams.text);
      if (grams == null) {
        setState(() => _submitting = false);
        return;
      }
      normalizedIngredients.add(
        OculumRecipeIngredient(name: ingredient.name.text.trim(), grams: grams),
      );
    }

    final now = DateTime.now().toIso8601String();
    Navigator.of(context).pop(
      OculumRecipe(
        id: widget.recipeId,
        name: _nameController.text.trim(),
        ingredients: normalizedIngredients,
        resultName: _resultController.text.trim(),
        resultDescription: _descriptionController.text.trim(),
        masterNotes: _notesController.text.trim(),
        visibleToPlayers: _visibleToPlayers,
        createdAt: widget.existing?.createdAt ?? now,
        updatedAt: now,
        recipeKind: _recipeCategory,
        forgeWeightMinKg: _forgeMinKgController.text.trim(),
        forgeWeightMaxKg: _forgeMaxKgController.text.trim(),
        forgeDuration: _forgeDurationController.text.trim(),
        forgeAttributes: _forgeAttributesController.text.trim(),
        forgeEffectText: _forgeEffectController.text.trim(),
        forgeTarget: _forgeTarget,
        resultGrams: _recipeCategory == 'forge'
            ? ''
            : oculumNormalizePositiveGramText(_resultGramsController.text) ??
                  '',
        personal: widget.existing?.personal ?? false,
        ownerTag: widget.existing?.ownerTag ?? '',
        sourceRecipeId: widget.existing?.sourceRecipeId ?? '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF10121A),
      insetPadding: const EdgeInsets.all(16),
      title: Text(
        widget.existing == null
            ? _t('Nuova ricetta', 'New recipe')
            : _t('Modifica ricetta', 'Edit recipe'),
        style: TextStyle(
          color: widget.primaryColor,
          fontWeight: FontWeight.w900,
        ),
      ),
      content: SizedBox(
        width: 680,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _field(
                  controller: _nameController,
                  label: _t('Nome della ricetta', 'Recipe name'),
                ),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: <ButtonSegment<String>>[
                    const ButtonSegment<String>(
                      value: 'crafting',
                      label: Text('Crafting'),
                      icon: Icon(Icons.menu_book_outlined),
                    ),
                    ButtonSegment<String>(
                      value: 'forge',
                      label: Text(_t('Forgia', 'Forge')),
                      icon: const Icon(Icons.construction_outlined),
                    ),
                    ButtonSegment<String>(
                      value: 'alchemy',
                      label: Text(_t('Alchimia', 'Alchemy')),
                      icon: const Icon(Icons.science_outlined),
                    ),
                  ],
                  selected: <String>{_recipeCategory},
                  onSelectionChanged: (selection) =>
                      setState(() => _recipeCategory = selection.first),
                ),
                if (_recipeCategory == 'forge') ...[
                  const SizedBox(height: 14),
                  Text(
                    _t('Dati materiale Forge', 'Forge material data'),
                    style: TextStyle(
                      color: widget.tertiaryColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          controller: _forgeMinKgController,
                          label: _t('Peso min (kg)', 'Min weight (kg)'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _field(
                          controller: _forgeMaxKgController,
                          label: _t('Peso max (kg)', 'Max weight (kg)'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _t(
                      'I kg raccoglibili sono pari alla Volontà attuale divisa per 2.',
                      'Gatherable kg equal the character current Will divided by 2.',
                    ),
                    style: const TextStyle(color: Colors.white54),
                  ),
                  const SizedBox(height: 10),
                  _field(
                    controller: _forgeDurationController,
                    label: _t('Tempo (es. 50\')', 'Time (e.g. 50\')'),
                    required: false,
                  ),
                  const SizedBox(height: 10),
                  _field(
                    controller: _forgeAttributesController,
                    label: _t(
                      'Attributi Forge (uno per riga)',
                      'Forge attributes (one per line)',
                    ),
                    minLines: 2,
                    maxLines: 5,
                    required: false,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: _forgeTarget,
                    decoration: InputDecoration(
                      labelText: _t('Oggetto compatibile', 'Compatible item'),
                      border: const OutlineInputBorder(),
                    ),
                    items: <DropdownMenuItem<String>>[
                      DropdownMenuItem(
                        value: 'auto',
                        child: Text(
                          _t('Arma o protezione', 'Weapon or protection'),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'arma',
                        child: Text(_t('Solo arma', 'Weapon only')),
                      ),
                      DropdownMenuItem(
                        value: 'protezione',
                        child: Text(_t('Scudo o armatura', 'Shield or armor')),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _forgeTarget = value ?? 'auto'),
                  ),
                  const SizedBox(height: 10),
                  _field(
                    controller: _forgeEffectController,
                    label: _t(
                      'Effetti e parser applicati all’oggetto',
                      'Effects and parser applied to the item',
                    ),
                    minLines: 3,
                    maxLines: 8,
                    required: false,
                  ),
                ],
                const SizedBox(height: 18),
                Text(
                  _t('Ingredienti', 'Ingredients'),
                  style: TextStyle(
                    color: widget.tertiaryColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                ...List.generate(
                  _ingredients.length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 4,
                          child: _field(
                            controller: _ingredients[index].name,
                            label: _t('Ingrediente', 'Ingredient'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: _field(
                            controller: _ingredients[index].grams,
                            label: _t('Quantità', 'Quantity'),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.,]'),
                              ),
                            ],
                            validator: (value) =>
                                oculumNormalizePositiveGramText(value ?? '') ==
                                    null
                                ? _t(
                                    'Inserisci grammi maggiori di zero',
                                    'Enter grams greater than zero',
                                  )
                                : null,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.fromLTRB(8, 17, 2, 0),
                          child: Text(
                            'g',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: _t(
                            'Rimuovi ingrediente',
                            'Remove ingredient',
                          ),
                          onPressed: () => _removeIngredient(index),
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _addIngredient,
                    icon: const Icon(Icons.add),
                    label: Text(_t('Aggiungi ingrediente', 'Add ingredient')),
                  ),
                ),
                const SizedBox(height: 18),
                _field(
                  controller: _resultController,
                  label: _t('Nome del risultato', 'Result name'),
                ),
                const SizedBox(height: 12),
                _field(
                  controller: _descriptionController,
                  label: _t(
                    'Descrizione completa del risultato',
                    'Full result description',
                  ),
                  minLines: 4,
                  maxLines: 8,
                ),
                if (_recipeCategory != 'forge') ...[
                  const SizedBox(height: 12),
                  _field(
                    controller: _resultGramsController,
                    label: _t(
                      'Grammatura del prodotto finito (g)',
                      'Finished product weight (g)',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    validator: (value) =>
                        oculumNormalizePositiveGramText(value ?? '') == null
                        ? _t(
                            'Inserisci grammi maggiori di zero',
                            'Enter grams greater than zero',
                          )
                        : null,
                  ),
                ],
                const SizedBox(height: 12),
                _field(
                  controller: _notesController,
                  label: _t(
                    'Note aggiuntive del Master (facoltative)',
                    'Additional Game Master notes (optional)',
                  ),
                  minLines: 2,
                  maxLines: 5,
                  required: false,
                ),
                const SizedBox(height: 10),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _t('Visibile ai giocatori', 'Visible to players'),
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    _visibleToPlayers
                        ? _t(
                            'I giocatori possono consultare questa ricetta.',
                            'Players can view this recipe.',
                          )
                        : _t(
                            'Ricetta segreta: visibile soltanto al Master.',
                            'Secret recipe: visible only to the Game Master.',
                          ),
                    style: const TextStyle(color: Colors.white54),
                  ),
                  value: _visibleToPlayers,
                  onChanged: (value) =>
                      setState(() => _visibleToPlayers = value),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: Text(_t('Annulla', 'Cancel')),
        ),
        FilledButton.icon(
          key: const ValueKey<String>('recipe_save_button'),
          onPressed: _submitting ? null : _submit,
          icon: const Icon(Icons.save_outlined),
          label: Text(_t('Salva ricetta', 'Save recipe')),
        ),
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int minLines = 1,
    int maxLines = 1,
    bool required = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      minLines: minLines,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.045),
        border: const OutlineInputBorder(),
      ),
      validator:
          validator ??
          (value) {
            if (!required) return null;
            return (value ?? '').trim().isEmpty
                ? _t('Campo obbligatorio', 'Required field')
                : null;
          },
    );
  }
}

class _RecipeIngredientControllers {
  _RecipeIngredientControllers({String name = '', String grams = ''})
    : name = TextEditingController(text: name),
      grams = TextEditingController(text: grams);

  final TextEditingController name;
  final TextEditingController grams;

  void dispose() {
    name.dispose();
    grams.dispose();
  }
}
