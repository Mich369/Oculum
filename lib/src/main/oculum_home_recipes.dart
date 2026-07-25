part of '../../main.dart';

extension _OculumHomeRecipes on _OculumHomePageState {
  bool get canManageRecipes => modalitaMaster || isMasterHost;

  String _newRecipeId() =>
      'recipe_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(999999)}';

  void _notifyRecipesChanged() {
    recipesRevision.value++;
    programmaSalvataggio(
      invalidateCaches: false,
      delay: const Duration(milliseconds: 450),
    );
  }

  Future<void> _openRecipeEditor([OculumRecipe? existing]) async {
    if (!canManageRecipes || recipeMutationInProgress) return;
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
      if (!mounted || result == null || !canManageRecipes) return;

      final existingIndex = recipes.indexWhere((item) => item.id == result.id);
      if (existingIndex >= 0) {
        recipes[existingIndex] = result;
      } else {
        recipes.insert(0, result);
      }
      _notifyRecipesChanged();
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
    if (!canManageRecipes || recipeMutationInProgress) return;
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
      if (!mounted || confirmed != true || !canManageRecipes) return;
      recipes.removeWhere((item) => item.id == recipe.id);
      _notifyRecipesChanged();
    } finally {
      recipeMutationInProgress = false;
    }
  }

  Widget recipesPage() {
    final isMaster = canManageRecipes;
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
              if (isMaster)
                FilledButton.icon(
                  key: const ValueKey<String>('recipe_create_button'),
                  onPressed: () => _openRecipeEditor(),
                  icon: const Icon(Icons.add),
                  label: Text(t('Nuova ricetta', 'New recipe')),
                ),
            ],
          ),
          const SizedBox(height: 14),
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
                      final visible = oculumVisibleRecipes(
                        recipes: recipes,
                        isMaster: isMaster,
                        query: query,
                      );
                      if (visible.isEmpty) {
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
                      return ListView.separated(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        itemCount: visible.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) =>
                            _recipeCard(visible[index], isMaster: isMaster),
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
    return RepaintBoundary(
      key: ValueKey<String>('recipe_card_${recipe.id}'),
      child: Card(
        color: const Color(0xFF10121A),
        elevation: 1,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: tertiaryColor.withValues(alpha: 0.35)),
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
                        color: primaryColor,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
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
              if (isMaster) ...[
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
                    OutlinedButton.icon(
                      onPressed: () => _duplicateRecipe(recipe),
                      icon: const Icon(Icons.copy_outlined),
                      label: Text(t('Duplica', 'Duplicate')),
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
  late final TextEditingController _notesController;
  final List<_RecipeIngredientControllers> _ingredients = [];
  late bool _visibleToPlayers;
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
    _notesController = TextEditingController(text: existing?.masterNotes ?? '');
    _visibleToPlayers = existing?.visibleToPlayers ?? true;
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
    _notesController.dispose();
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
