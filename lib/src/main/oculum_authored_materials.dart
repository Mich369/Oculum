part of '../../main.dart';

class OculumAuthoredMaterial {
  const OculumAuthoredMaterial(
    this.id,
    this.name,
    this.grade,
    this.minKg,
    this.maxKg,
    this.minutes,
    this.effect, {
    this.passive = '',
    this.active = '',
  });
  final String id, name, effect, passive, active;
  final int grade, minutes;
  final double minKg, maxKg;
}

const oculumAuthoredMaterials = <OculumAuthoredMaterial>[
  OculumAuthoredMaterial(
    'roccia',
    'Roccia',
    0,
    1,
    10,
    50,
    'Base: Materia/6 Danni. Attivo: Oculum/5 Difesa. Con 10 kg i divisori diventano 5 e 4.',
    passive: '@Danni+Materia/6',
    active: '@Difesa+Oculum/5',
  ),
  OculumAuthoredMaterial(
    'carbone_magico',
    'Carbone Magico',
    0,
    3,
    28,
    40,
    'Attivo e acceso: Oculum totale/3 Danni da Fuoco. Critico: 1d3 turni; ogni 5 kg aggiunti il dado cresce fino a d12. Ogni turno perde 1/N della potenza iniziale, dove N è la durata tirata; può essere completamente parato.',
  ),
  OculumAuthoredMaterial(
    'vitalium_grezzo',
    'Vitalium Grezzo',
    0,
    2,
    3,
    20,
    'Attivo: ogni utilizzo a buon segno cura Oculum totale/3 Vita; con 3 kg cura Oculum/2. Trasforma l’energia degli impatti in Oculum Vitali.',
  ),
  OculumAuthoredMaterial(
    'ossa',
    'Ossa',
    0,
    5,
    10,
    30,
    'Base: Materia/4 Danni; attivo: Oculum/4 Difesa. Con 10 kg entrambi i divisori diventano 3.',
    passive: '@Danni+Materia/4',
    active: '@Difesa+Oculum/4',
  ),
  OculumAuthoredMaterial(
    'vapium',
    'Vapium',
    0,
    3,
    100,
    40,
    'Minerale Mutabile del Reame Dimenticato, sostenuto dal Quinto Lucifero. Vapore comprimibile in solido durissimo. Ogni 10 kg: +9 Resistenza e +6 Difesa dell’oggetto. Pozione: +1 Materia ogni 3 kg per un’ora.',
  ),
  OculumAuthoredMaterial(
    'lunium',
    'Lunium',
    0,
    15,
    100,
    40,
    'Minerale Lunare rosato luminoso, potere diabolico. Ogni 5 kg oltre i 15: +2 Danni. Attivo: +1 Volontà ogni 15 kg soltanto con buona reputazione nelle MoonHills. Raro dopo la scomparsa di luna e stelle.',
  ),
  OculumAuthoredMaterial(
    'metallo_slime',
    'Metallo Slime',
    1,
    10,
    25,
    10,
    'Attivo: si indurisce, liquefa e cambia forma e colore. Altamente incendiabile; acceso: Oculum/2 Danni da Fuoco. Critico: d3 turni, ogni 3 kg aggiunti cresce fino a d12; perde 1/N potenza iniziale per turno. Da 15 kg si autoripara.',
  ),
  OculumAuthoredMaterial(
    'ossa_dure',
    'Ossa Dure',
    1,
    10,
    20,
    50,
    'Base: Materia/3 Danni; attivo: Oculum/3 Difesa. Con 20 kg i divisori diventano 2.',
    passive: '@Danni+Materia/3',
    active: '@Difesa+Oculum/3',
  ),
  OculumAuthoredMaterial(
    'resilenzium',
    'Resilenzium',
    1,
    10,
    20,
    50,
    'Base: Resilienza/3 Danni; attivo: Resilienza/3 Scudo. Con 20 kg i divisori diventano 2.',
    passive: '@Danni+Resilienza/3',
    active: '@Scudo+Resilienza/3',
  ),
  OculumAuthoredMaterial(
    'slime_corrotto',
    'Slime Corrotto',
    2,
    5,
    10,
    15,
    'Attivo, tiro 18+: Veleno metà Oscuro e metà Demoniaco, durata Oculum/3 azioni, danni non curabili. Comunque 1/4 dei tuoi Danni non è curabile; con 10 kg diventa 1/3.',
  ),
  OculumAuthoredMaterial(
    'flamirion',
    'Flamirion',
    2,
    1,
    20,
    30,
    '+10 Danni da Fuoco. Attivo, critico positivo: Scottatura.',
    passive: '@Danni+10 Fuoco',
  ),
  OculumAuthoredMaterial(
    'aqualatis',
    'Aqualatis',
    2,
    1,
    20,
    20,
    '+10 Danni d’Acqua. Attivo, critico positivo: dona una Reazione a te o a un alleato contro il nemico colpito.',
    passive: '@Danni+10 Acqua',
  ),
  OculumAuthoredMaterial(
    'corallo',
    'Corallo',
    2,
    5,
    100,
    45,
    'Abissi dei Geosgaeono. Ogni 5 kg: +1 Difesa e +3 Resistenza dell’oggetto, consumate prima della tua Vita. Riparazione in acqua: almeno 2 ore se rotto, altrimenti 25% ogni 45 minuti. Resiste all’Acqua, estremamente fragile al puro Ghiaccio. Effetti dimezzati in caldo arido o dopo 6 ore senza immersione.',
  ),
  OculumAuthoredMaterial(
    'rame_fatato',
    'Rame Fatato',
    3,
    25,
    25,
    20,
    'Attivo: ritira fino a un doppio critico negativo o maggiore nella riforgiatura.',
  ),
  OculumAuthoredMaterial(
    'pietra_focolare',
    'Pietra Focolare',
    3,
    20,
    45,
    50,
    'Attiva: si accende a comando, +Oculum/3 Danni da Fuoco. Critico: d6 turni, ogni 5 kg cresce fino a d20; perde 1/N della potenza iniziale per turno.',
  ),
  OculumAuthoredMaterial(
    'metallo_slime_corrotto',
    'Metallo Slime Corrotto',
    3,
    15,
    33,
    15,
    'Attivo: si indurisce, cambia forma e colore e brucia di viola; acceso: +Oculum totale Danni. Critico: d3 turni, ogni 3 kg cresce fino a d12; perde 1/N potenza iniziale per turno. Autoriparazione da 16 kg.',
  ),
  OculumAuthoredMaterial(
    'virelion',
    'Virelion',
    3,
    20,
    100,
    40,
    'Danni e Difesa aumentano di Materia × (Grado Titolo + Grado Materiale). Attivo: Volontà/5 Svantaggio al nemico, massimo cinque applicazioni. Ogni 20 kg diminuisce il divisore, minimo 2.',
  ),
  OculumAuthoredMaterial(
    'tarium',
    'Tarium',
    3,
    3,
    100,
    50,
    'Minerale Roccioso marrone bronzato delle cime. Varianti fino a grado IX. Ogni 3 kg: 30+Grado Resistenza e 10+Grado Difesa dell’oggetto. Fragile al Contundente, estremamente fragile al Frantumante.',
  ),
  OculumAuthoredMaterial(
    'eclisium',
    'Eclisium',
    3,
    60,
    180,
    50,
    'Con Luna visibile: +10 Danni e Difesa ogni 100 kg. Ignora un moltiplicatore di grado ogni 60 kg, massimo tre. Potenzia gli effetti lunari dei materiali di grado inferiore o pari al tuo.',
  ),
  OculumAuthoredMaterial(
    'urgalite',
    'Urgalite',
    3,
    50,
    180,
    50,
    'Cristallo di Gravità. Base: +Materia Danni. Attivo: -1 Velocità nemica ogni 50 kg e -1 Iniziativa ogni 60 kg. Oltre 100 kg può creare un’area: -5 Movimento e -3 Iniziativa ai nemici.',
    passive: '@Danni+Materia',
  ),
  OculumAuthoredMaterial(
    'stray',
    'Stray',
    -1,
    1,
    10,
    60,
    'Minerale Ribelle arancione, di estrema Volontà nel non variare. Aumenta di 1 il grado del risultato. Tiro 18+ se Materia e Volontà sono entrambe >10; altrimenti 20 naturale. Con almeno 20 in una delle due, tiro 15+. Il grado aumentato resta richiesto anche passando dal fabbro.',
  ),
  OculumAuthoredMaterial(
    'grofix',
    'Grofix',
    -1,
    0.1,
    1,
    20,
    'Materiale Infestante. Assorbe il potere dei materiali poco raccolti e ne diminuisce il grado e la grammatura utile. Cresce nei sotterranei: muschio mutevole, poi cristalli variegati, appuntiti e lunghi secondo il grado rubato. Può diventare un mostro. Usabile come veleno che danneggia e assorbe Oculum.',
  ),
];

int oculumStrayDifficulty({required int materia, required int volonta}) =>
    materia >= 20 || volonta >= 20
    ? 15
    : materia > 10 && volonta > 10
    ? 18
    : 20;

int oculumActiveMaterialCapacity({required int level, required int grade}) =>
    level < 1 ? 0 : 3 + max(0, grade) ~/ 3;

List<OculumRecipe> oculumUsefulCoreRecipes(String now) {
  OculumRecipe recipe(
    String id,
    String name,
    String material,
    int grams,
    String description, {
    String target = 'weapon',
  }) => OculumRecipe(
    id: 'core_useful_$id',
    name: name,
    ingredients: [OculumRecipeIngredient(name: material, grams: '$grams')],
    resultName: name,
    resultDescription: description,
    masterNotes:
        'Ricetta pronta, modificabile dal Master. Il grado e gli effetti derivano dal materiale; le condizioni di attivazione restano valide.',
    visibleToPlayers: true,
    createdAt: now,
    updatedAt: now,
    forgeTarget: target,
    resultGrams: '$grams',
  );
  return [
    recipe(
      'lama_ossa',
      'Lama d’ossa',
      'Ossa',
      5000,
      'Arma: Materia/4 Danni. Materiale attivo: Oculum/4 Difesa.',
    ),
    recipe(
      'scudo_roccia',
      'Scudo di roccia',
      'Roccia',
      10000,
      'Scudo: con 10 kg, materiale attivo dà Oculum/4 Difesa.',
      target: 'armor',
    ),
    recipe(
      'martello_resilenzium',
      'Martello di Resilenzium',
      'Resilenzium',
      10000,
      'Arma: Resilienza/3 Danni. Materiale attivo: Resilienza/3 Scudo.',
    ),
    recipe(
      'lama_flamirion',
      'Lama di Flamirion',
      'Flamirion',
      1000,
      'Arma: +10 Danni da Fuoco; materiale attivo e critico positivo infliggono Scottatura.',
    ),
    recipe(
      'lancia_aqualatis',
      'Lancia di Aqualatis',
      'Aqualatis',
      1000,
      'Arma: +10 Danni d’Acqua; materiale attivo e critico positivo donano una Reazione.',
    ),
    recipe(
      'corazza_tarium',
      'Corazza di Tarium',
      'Tarium',
      3000,
      'Armatura: Resistenza propria 30+Grado e Difesa propria 10+Grado. Fragile a Contundente, estremamente fragile a Frantumante.',
      target: 'armor',
    ),
    recipe(
      'scudo_corallo',
      'Scudo di corallo',
      'Corallo',
      5000,
      'Scudo: +1 Difesa propria, +3 Resistenza propria; si ripara immerso in acqua.',
      target: 'armor',
    ),
    recipe(
      'pozione_vapium',
      'Pozione di Vapium',
      'Vapium',
      3000,
      'Consuma: +1 Materia per un’ora. Controlli meglio vaporizzazione e indurimento.',
      target: 'consumable',
    ),
    recipe(
      'veleno_grofix',
      'Veleno di Grofix',
      'Grofix',
      100,
      'Applica a un’arma: il colpo avvelenato danneggia e assorbe Oculum del bersaglio. Potenza pari al grado assorbito dal Grofix; il Master configura il valore del campione.',
      target: 'consumable',
    ),
    recipe(
      'lega_stray',
      'Lega di Stray',
      'Stray',
      1000,
      'Componente ribelle: aumenta di uno il grado del risultato. Richiede tiro di lavorazione di Stray.',
      target: 'material',
    ),
  ];
}

extension _OculumAuthoredCrafting on _OculumHomePageState {
  bool ensureAuthoredCraftingRecipes() {
    final now = DateTime.now().toIso8601String();
    final defaults = [
      ...oculumUsefulCoreRecipes(now),
      for (final material in oculumAuthoredMaterials)
        OculumRecipe(
          id: 'core_material_${material.id}',
          name: material.name,
          ingredients: [
            OculumRecipeIngredient(
              name: material.name,
              grams: '${(material.minKg * 1000).round()}',
            ),
          ],
          resultName: material.name,
          resultDescription: material.effect,
          masterNotes:
              'Materiale dell’autore. Dati originali in docs/MATERIALI_AUTORE_20261001.txt. I pesi e tempi non specificati dall’autore sono valori iniziali modificabili dal Master.',
          visibleToPlayers: true,
          createdAt: now,
          updatedAt: now,
          recipeKind: 'forge',
          forgeWeightMinKg: '${material.minKg}',
          forgeWeightMaxKg: '${material.maxKg}',
          forgeDuration: '${material.minutes} minuti',
          forgeAttributes: material.grade < 0
              ? 'Grado indefinito'
              : 'Grado ${material.grade}',
          forgeEffectText: material.effect,
        ),
    ];
    var added = false;
    for (final recipe in defaults) {
      if (recipes.any((current) => current.id == recipe.id)) continue;
      recipes.add(recipe);
      added = true;
    }
    if (added) recipesRevision.value++;
    return added;
  }

  OculumAuthoredMaterial? authoredMaterialForRecipe(OculumRecipe recipe) {
    if (!recipe.id.startsWith('core_') || recipe.ingredients.isEmpty) {
      return null;
    }
    final name = recipe.ingredients.first.name.toLowerCase();
    for (final material in oculumAuthoredMaterials) {
      if (material.name.toLowerCase() == name) return material;
    }
    return null;
  }

  InventoryItem authoredCraftedItem(OculumRecipe recipe, int quantity) {
    final material = authoredMaterialForRecipe(recipe);
    final grade = max(0, material?.grade ?? 0);
    final grams = _finishedProductGrams(recipe);
    var passive = material?.passive ?? '';
    var active = material?.active ?? '';
    if (material?.id == 'roccia' && grams >= 10000) {
      passive = '@Danni+Materia/5';
      active = '@Difesa+Oculum/4';
    }
    if (material?.id == 'ossa' && grams >= 10000) {
      passive = '@Danni+Materia/3';
      active = '@Difesa+Oculum/3';
    }
    final weapon = recipe.forgeTarget == 'weapon';
    final armor = recipe.forgeTarget == 'armor';
    return InventoryItem(
      nome: recipe.resultName,
      peso: grams / 1000,
      quantita: quantity,
      note: recipe.resultDescription,
      arma: weapon,
      protegge: armor,
      gradoOggetto: grade + (material?.id == 'stray' ? 1 : 0),
      gradoRichiesto: grade + (material?.id == 'stray' ? 1 : 0),
      buff: weapon ? passive : '',
      bonusDifesa: material?.id == 'tarium' ? 10 + grade : 0,
      bonusScudo: material?.id == 'tarium'
          ? 30 + grade
          : material?.id == 'corallo'
          ? 3
          : 0,
      craftData: material == null
          ? const {}
          : {
              'material': material.id,
              'materialGrade': grade,
              'active': false,
              'activeBuff': active,
              'effect': material.effect,
              'grams': grams,
            },
    );
  }

  bool canActivateAuthoredMaterial(InventoryItem item) {
    if (item.craftData['material'] == 'gerin_esausto') return false;
    final grade = max(0, leggiNumero(gradoController));
    if (readIntValue(item.craftData['materialGrade']) > grade) return false;
    final active = inventario
        .where((other) => other.craftData['active'] == true)
        .toList();
    final capacity = oculumActiveMaterialCapacity(
      level: leggiNumero(livelloController),
      grade: grade,
    );
    if (active.length >= capacity) return false;
    final ownGradeCount = active
        .where(
          (other) => readIntValue(other.craftData['materialGrade']) == grade,
        )
        .length;
    return readIntValue(item.craftData['materialGrade']) < grade ||
        ownGradeCount < 1 + grade ~/ 3;
  }

  void toggleAuthoredMaterial(InventoryItem item) {
    if (item.craftData.isEmpty) return;
    final enabled = item.craftData['active'] != true;
    if (enabled && !canActivateAuthoredMaterial(item)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Limite dei materiali attivi o grado insufficiente. Dal livello 1: tre materiali, uno del tuo grado e due inferiori; +1 ogni tre Gradi.',
          ),
        ),
      );
      return;
    }
    if (enabled && item.craftData['material'] == 'gerin') {
      _exhaustGerinFragments(1);
      aggiungiLog(
        'Un frammento di Gerin si è scaricato diventando Gerin Esausto.',
      );
      programmaSalvataggio();
      refreshOculumHome(() {});
      return;
    }
    refreshOculumHome(
      () => item.craftData = {...item.craftData, 'active': enabled},
    );
    programmaSalvataggio();
  }
}
