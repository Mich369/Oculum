part of '../../main.dart';

// New campaign defaults, kept separate from the author's original materials.
const oculumAdditionalCraftingMaterials = <OculumAuthoredMaterial>[
  ...oculumFantasyCraftingMaterials,
  OculumAuthoredMaterial(
    'zanne_goblin',
    'Zanne di goblin',
    0,
    .05,
    1,
    20,
    'Zanne per il Guanto a lame di goblin di grado 0.',
  ),
  OculumAuthoredMaterial(
    'pelle_mostro',
    'Pelle di mostro',
    0,
    .1,
    2,
    20,
    'Pelle per guanti, protezioni e legature di grado 0.',
  ),
  OculumAuthoredMaterial(
    'corno_forest_demon',
    'Corno di Forest Demon',
    1,
    .1,
    2,
    30,
    'Componente per il guanto forte di grado I.',
  ),
  OculumAuthoredMaterial(
    'metallo_runico',
    'Metallo runico',
    1,
    .5,
    5,
    30,
    'Metallo per armamenti runici di grado I.',
  ),
  OculumAuthoredMaterial(
    'artigli_lupo',
    'Artigli di lupo',
    0,
    .05,
    1,
    20,
    'Drop da predatori per lame e ganci.',
  ),
  OculumAuthoredMaterial(
    'carapace_scarabeo',
    'Carapace di scarabeo gigante',
    1,
    .25,
    3,
    30,
    'Guscio duro per scudi e placche.',
  ),
  OculumAuthoredMaterial(
    'denti_troll',
    'Denti di troll',
    2,
    .1,
    2,
    35,
    'Punte spesse per mazze e placche dentate.',
  ),
  OculumAuthoredMaterial(
    'piume_arpia',
    'Piume di arpia',
    1,
    .05,
    1,
    25,
    'Piume flessibili per rivestimenti e filtri.',
  ),
  OculumAuthoredMaterial(
    'occhio_basilisco',
    'Occhio di basilisco',
    3,
    .1,
    1,
    45,
    'Reagente raro per catalizzatori alchemici.',
  ),
  OculumAuthoredMaterial(
    'membrana_pipistrello',
    'Membrana di pipistrello gigante',
    0,
    .1,
    1,
    20,
    'Membrana elastica per guanti e fasciature.',
  ),
  OculumAuthoredMaterial(
    'sangue_idra',
    'Sangue di idra',
    4,
    .1,
    1,
    50,
    'Reagente raro da stabilizzare con sale alchemico.',
  ),
  OculumAuthoredMaterial(
    'ferro_grezzo',
    'Ferro grezzo',
    0,
    1,
    10,
    30,
    'Minerale di cava: base per lingotti, lame e rivetti.',
  ),
  OculumAuthoredMaterial(
    'carbone_forgia',
    'Carbone da forgia',
    0,
    .5,
    5,
    20,
    'Combustibile per purificare metalli; non sostituisce il Carbone Magico.',
  ),
  OculumAuthoredMaterial(
    'rame_grezzo',
    'Rame grezzo',
    0,
    1,
    10,
    25,
    'Metallo malleabile per leghe e conduttori.',
  ),
  OculumAuthoredMaterial(
    'stagno',
    'Stagno',
    0,
    .5,
    5,
    25,
    'Si combina con il rame per ottenere bronzo.',
  ),
  OculumAuthoredMaterial(
    'lingotto_ferro',
    'Lingotto di ferro',
    0,
    1,
    10,
    30,
    'Ferro raffinato per armi, armature e scudi.',
  ),
  OculumAuthoredMaterial(
    'lingotto_bronzo',
    'Lingotto di bronzo',
    0,
    1,
    10,
    30,
    'Lega di rame e stagno per componenti resistenti.',
  ),
  OculumAuthoredMaterial(
    'cuoio_grezzo',
    'Cuoio grezzo',
    0,
    .5,
    5,
    30,
    'Pelli da conciare per impugnature e protezioni.',
  ),
  OculumAuthoredMaterial(
    'cuoio_conciato',
    'Cuoio conciato',
    0,
    .5,
    5,
    30,
    'Pelle lavorata per cinghie, guanti e armature leggere.',
  ),
  OculumAuthoredMaterial(
    'resina_ambrata',
    'Resina ambrata',
    0,
    .1,
    1,
    15,
    'Legante vegetale per colle, vernici e fasciature.',
  ),
  OculumAuthoredMaterial(
    'fibra_lino',
    'Fibra di lino',
    0,
    .1,
    2,
    20,
    'Fibra per tessuti, bende e filtri alchemici.',
  ),
  OculumAuthoredMaterial(
    'tessuto_lino',
    'Tessuto di lino',
    0,
    .1,
    2,
    20,
    'Lino tessuto, pronto per bende e fodere.',
  ),
  OculumAuthoredMaterial(
    'legno_frassino',
    'Legno di frassino',
    0,
    1,
    10,
    25,
    'Legno elastico per aste, archi e scudi.',
  ),
  OculumAuthoredMaterial(
    'sale_alchemico',
    'Sale alchemico',
    0,
    .1,
    1,
    15,
    'Reagente di purificazione e conservazione.',
  ),
  OculumAuthoredMaterial(
    'acqua_purificata',
    'Acqua purificata',
    0,
    .25,
    5,
    15,
    'Solvente per distillati e balsami.',
  ),
  OculumAuthoredMaterial(
    'fungo_luminoso',
    'Fungo luminoso',
    0,
    .05,
    1,
    15,
    'Fungo delle grotte per reagenti e pigmenti.',
  ),
  OculumAuthoredMaterial(
    'lingotto_acciaio',
    'Lingotto di acciaio',
    1,
    1,
    10,
    45,
    'Lega raffinata per armamenti rinforzati.',
  ),
  OculumAuthoredMaterial(
    'zanna_predatore',
    'Zanna di predatore',
    1,
    .1,
    2,
    30,
    'Trofeo da caccia per lame e punte dentate.',
  ),
  OculumAuthoredMaterial(
    'tendine_bestiale',
    'Tendine bestiale',
    1,
    .1,
    2,
    25,
    'Componente animale per corde robuste e legature.',
  ),
  OculumAuthoredMaterial(
    'seta_ragno',
    'Seta di ragno gigante',
    1,
    .1,
    2,
    30,
    'Fibra delle tane, per tessuti resistenti.',
  ),
  OculumAuthoredMaterial(
    'sacca_veneno',
    'Sacca di veleno',
    1,
    .05,
    .5,
    20,
    'Drop di creature velenose; reagente da trattare.',
  ),
  OculumAuthoredMaterial(
    'scaglia_draconica',
    'Scaglia draconica',
    3,
    .25,
    5,
    50,
    'Drop raro di creature draconiche per protezioni.',
  ),
  OculumAuthoredMaterial(
    'corno_chimera',
    'Corno di chimera',
    3,
    .25,
    3,
    45,
    'Componente raro per punte e catalizzatori.',
  ),
  OculumAuthoredMaterial(
    'cuore_golem',
    'Cuore di golem',
    3,
    1,
    10,
    60,
    'Nucleo minerale da creature costrutte per rinforzi.',
  ),
  OculumAuthoredMaterial(
    'argento_lunare',
    'Argento lunare',
    2,
    .5,
    5,
    45,
    'Metallo raro per leghe e incisioni rituali.',
  ),
  OculumAuthoredMaterial(
    'cristallo_oculum',
    'Cristallo di Oculum grezzo',
    2,
    .1,
    2,
    40,
    'Catalizzatore per lavorazioni rituali; non concede Oculum da solo.',
  ),
  OculumAuthoredMaterial(
    'cenere_fenice',
    'Cenere di fenice',
    4,
    .05,
    .5,
    60,
    'Reagente rarissimo per leganti di grado elevato.',
  ),
  OculumAuthoredMaterial(
    'polvere_stellare',
    'Polvere stellare',
    4,
    .05,
    .5,
    60,
    'Residuo celeste per catalizzatori raffinati.',
  ),
  OculumAuthoredMaterial(
    'essenza_fuoco',
    'Essenza di Fuoco',
    2,
    .1,
    1,
    30,
    'Reagente elementale concentrato per ricette del Fuoco.',
  ),
  OculumAuthoredMaterial(
    'essenza_gelo',
    'Essenza di Ghiaccio',
    2,
    .1,
    1,
    30,
    'Reagente elementale concentrato per ricette del Ghiaccio.',
  ),
  OculumAuthoredMaterial(
    'essenza_fulmine',
    'Essenza di Fulmine',
    2,
    .1,
    1,
    30,
    'Reagente elementale concentrato per ricette del Fulmine.',
  ),
  OculumAuthoredMaterial(
    'essenza_luce',
    'Essenza di Luce',
    2,
    .1,
    1,
    30,
    'Reagente elementale concentrato per ricette della Luce.',
  ),
  OculumAuthoredMaterial(
    'essenza_ombra',
    'Essenza di Oscuro',
    2,
    .1,
    1,
    30,
    'Reagente elementale concentrato per ricette dell’Oscuro.',
  ),
];

const oculumFantasyCraftingMaterials = <OculumAuthoredMaterial>[
  OculumAuthoredMaterial(
    'gerin',
    'Gerin',
    0,
    .1,
    2,
    20,
    'Sfregando due frammenti genera scintille di Oculum. Con il tuo potere e il tiro più alto fra Canalizzazione e Manifestazione del Potere emette una vampata. Emissioni innocue: il nemico deve superare il tuo tiro per vederti. Emissioni dannose: il nemico tira CM; se fallisce subisce i tuoi Danni. Nessun bonus permanente.',
  ),
  OculumAuthoredMaterial(
    'velruna',
    'Velruna',
    0,
    .1,
    2,
    20,
    'Fibra vellutata che trattiene pigmenti: tele, filtri e fodere.',
  ),
  OculumAuthoredMaterial(
    'ambril',
    'Ambril',
    0,
    .1,
    2,
    20,
    'Resina dorata che lega polveri minerali senza nasconderne il colore.',
  ),
  OculumAuthoredMaterial(
    'nacrel',
    'Nacrel',
    0,
    .1,
    2,
    20,
    'Guscio madreperlaceo da polverizzare per smalti e rivestimenti.',
  ),
  OculumAuthoredMaterial(
    'feralis',
    'Feralis',
    0,
    .1,
    2,
    20,
    'Granulo ferrigno poroso per impasti metallici e levigatura.',
  ),
  OculumAuthoredMaterial(
    'lumerba',
    'Lumerba',
    0,
    .1,
    2,
    20,
    'Erba pallida che conserva una debole luminescenza nei distillati.',
  ),
  OculumAuthoredMaterial(
    'sileth',
    'Sileth',
    0,
    .1,
    2,
    20,
    'Pietra fessile che si separa in sottili lame da lavorazione.',
  ),
  OculumAuthoredMaterial(
    'draven',
    'Draven',
    0,
    .1,
    2,
    20,
    'Radice fibrosa per corde, lacci e leganti vegetali.',
  ),
  OculumAuthoredMaterial(
    'mirel',
    'Mirel',
    0,
    .1,
    2,
    20,
    'Argilla chiara per stampi, contenitori e paste alchemiche.',
  ),
  OculumAuthoredMaterial(
    'thornil',
    'Thornil',
    0,
    .1,
    2,
    20,
    'Spina cava per aghi, punte e applicatori di unguenti.',
  ),
  OculumAuthoredMaterial(
    'osserin',
    'Osserin',
    0,
    .1,
    2,
    20,
    'Osso leggero delle bestie di pianura, adatto a intarsi e impugnature.',
  ),
  OculumAuthoredMaterial(
    'aurvel',
    'Aurvel',
    0,
    .1,
    2,
    20,
    'Sabbia color rame per lucidature e polveri traccianti.',
  ),
  OculumAuthoredMaterial(
    'nebrin',
    'Nebrin',
    0,
    .1,
    2,
    20,
    'Sale grigio che genera vapore opaco quando viene scaldato in acqua.',
  ),
  OculumAuthoredMaterial(
    'crisol',
    'Crisol',
    0,
    .1,
    2,
    20,
    'Cristallo friabile per lenti semplici, reagenti e incisioni.',
  ),
  OculumAuthoredMaterial(
    'tessarin',
    'Tessarin',
    0,
    .1,
    2,
    20,
    'Filo prodotto da larve boschive, morbido e facile da tessere.',
  ),
  OculumAuthoredMaterial(
    'virdel',
    'Virdel',
    0,
    .1,
    2,
    20,
    'Muschio assorbente per medicazioni, filtri e polveri vegetali.',
  ),
  OculumAuthoredMaterial(
    'brumel',
    'Brumel',
    0,
    .1,
    2,
    20,
    'Bacca dalla buccia cerosa per sigillanti e sospensioni.',
  ),
  OculumAuthoredMaterial(
    'cendril',
    'Cendril',
    0,
    .1,
    2,
    20,
    'Cenere minerale fine per tempera, smalti e sali di reazione.',
  ),
  OculumAuthoredMaterial(
    'rhovan',
    'Rhovan',
    0,
    .1,
    2,
    20,
    'Legno nodoso da ridurre in pioli, carboni e supporti.',
  ),
  OculumAuthoredMaterial(
    'elun',
    'Elun',
    0,
    .1,
    2,
    20,
    'Petalo argentato per pigmenti, infusi e inchiostri.',
  ),
  OculumAuthoredMaterial(
    'gerin_puro',
    'Gerin puro',
    1,
    .1,
    2,
    30,
    'Scintille più stabili per catalizzatori lavorati; effetti concordati col Master.',
  ),
  OculumAuthoredMaterial(
    'velruna_lunare',
    'Velruna lunare',
    2,
    .1,
    2,
    35,
    'Tessuto lunare per fodere rituali e filtri di essenze.',
  ),
  OculumAuthoredMaterial(
    'ambril_draconico',
    'Ambril draconico',
    3,
    .1,
    2,
    40,
    'Resina maturata presso nidi draconici per leganti di scaglie.',
  ),
  OculumAuthoredMaterial(
    'crisol_astrale',
    'Crisol astrale',
    4,
    .1,
    2,
    45,
    'Cristallo per catalizzatori astrali e lenti rituali.',
  ),
  OculumAuthoredMaterial(
    'feralis_reale',
    'Feralis reale',
    5,
    .1,
    2,
    50,
    'Metallo da vene profonde per armamenti di grado elevato.',
  ),
  OculumAuthoredMaterial(
    'nacrel_abissale',
    'Nacrel abissale',
    6,
    .1,
    2,
    55,
    'Madreperla abissale per intarsi e sigilli.',
  ),
  OculumAuthoredMaterial(
    'osserin_titanico',
    'Osserin titanico',
    7,
    .1,
    2,
    60,
    'Osso di creature titaniche per rinforzi e componenti.',
  ),
  OculumAuthoredMaterial(
    'draven_eterno',
    'Draven eterno',
    8,
    .1,
    2,
    65,
    'Radice rarissima per legature rituali persistenti.',
  ),
  OculumAuthoredMaterial(
    'aurvel_celeste',
    'Aurvel celeste',
    9,
    .1,
    2,
    70,
    'Polvere celeste per leghe e sigilli di alto grado.',
  ),
  OculumAuthoredMaterial(
    'nebrin_vuoto',
    'Nebrin del Vuoto',
    10,
    .1,
    2,
    75,
    'Sale delle fratture del Vuoto per catalizzatori avanzati.',
  ),
  OculumAuthoredMaterial(
    'elun_origine',
    'Elun d’Origine',
    11,
    .1,
    2,
    80,
    'Petalo primordiale per inchiostri e formule leggendarie.',
  ),
  OculumAuthoredMaterial(
    'gerin_oculum',
    'Gerin Oculum',
    12,
    .1,
    2,
    90,
    'Forma rarissima di Gerin per lavorazioni al massimo grado. Non aumenta automaticamente statistiche o poteri.',
  ),
];

List<OculumRecipe> oculumAdditionalCraftingRecipes(String now) {
  OculumRecipe make(
    String id,
    String name,
    Map<String, int> materials,
    int grams, {
    String target = 'material',
    String description = '',
    String effect = '',
    String kind = 'crafting',
  }) => OculumRecipe(
    id: 'expansion_$id',
    name: name,
    resultName: name,
    ingredients: [
      for (final entry in materials.entries)
        OculumRecipeIngredient(name: entry.key, grams: '${entry.value}'),
    ],
    resultDescription: description,
    masterNotes:
        'Ricetta originale Oculum ispirata alla combinazione di ingredienti dei GDR. Valori modificabili dal Master.',
    visibleToPlayers: true,
    createdAt: now,
    updatedAt: now,
    recipeKind: kind,
    forgeTarget: target,
    resultGrams: '$grams',
    forgeEffectText: effect,
  );
  return [
    make(
      'guanto_goblin',
      'Guanto a lame di goblin',
      {'Zanne di goblin': 200, 'Pelle di mostro': 300},
      500,
      target: 'weapon',
      description:
          'Versione debole, Grado 0: +5 Danni perforanti quando equipaggiato.',
    ),
    make(
      'guanto_forest_demon',
      'Guanto runico del Forest Demon',
      {'Corno di Forest Demon': 300, 'Metallo runico': 700},
      1000,
      target: 'weapon',
      description:
          'Versione forte, Grado I: +10 Danni perforanti quando equipaggiato.',
    ),
    make(
      'lama_lupo',
      'Lama del lupo',
      {
        'Artigli di lupo': 200,
        'Lingotto di ferro': 1000,
        'Cuoio conciato': 100,
      },
      1300,
      target: 'weapon',
      description: 'Arma: +3 Danni taglienti quando equipaggiata.',
    ),
    make(
      'scudo_scarabeo',
      'Scudo di scarabeo',
      {
        'Carapace di scarabeo gigante': 1000,
        'Legno di frassino': 1000,
        'Tendine bestiale': 200,
      },
      2200,
      target: 'armor',
      description: 'Scudo: +3 Difesa quando equipaggiato.',
    ),
    make(
      'mazza_troll',
      'Mazza dentata di troll',
      {'Denti di troll': 500, 'Legno di frassino': 1500},
      2000,
      target: 'weapon',
      description: 'Arma: +4 Danni contundenti quando equipaggiata.',
    ),
    make(
      'mantello_arpia',
      'Mantello di arpia',
      {'Piume di arpia': 300, 'Tessuto di lino': 500},
      800,
      target: 'armor',
      description: 'Protezione: +1 Difesa quando equipaggiata.',
    ),
    make(
      'guanti_membrana',
      'Guanti di membrana',
      {'Membrana di pipistrello gigante': 200, 'Cuoio conciato': 200},
      400,
      target: 'armor',
      description: 'Protezione: +1 Difesa quando equipaggiata.',
    ),
    make(
      'catalizzatore_basilisco',
      'Catalizzatore di basilisco',
      {
        'Occhio di basilisco': 100,
        'Sale alchemico': 50,
        'Acqua purificata': 50,
      },
      200,
      kind: 'alchemy',
      description:
          'Reagente di grado III per rituali e lavorazioni del Master.',
    ),
    make(
      'sangue_stabilizzato',
      'Sangue di idra stabilizzato',
      {'Sangue di idra': 100, 'Sale alchemico': 50},
      150,
      kind: 'alchemy',
      description: 'Reagente di grado IV per le ricette del Master.',
    ),
    for (final material in oculumFantasyCraftingMaterials)
      make(
        'legante_${material.id}',
        'Legante di ${material.name}',
        {material.name: 100, 'Resina ambrata': 50, 'Acqua purificata': 50},
        200,
        kind: 'alchemy',
        description:
            'Composto di grado ${material.grade} per lavorazioni successive. ${material.effect}',
      ),
    for (final material in oculumFantasyCraftingMaterials)
      make(
        'intarsio_${material.id}',
        'Intarsio di ${material.name}',
        {'Legante di ${material.name}': 200, 'Lingotto di ferro': 100},
        300,
        kind: 'forge',
        description:
            'Applica il materiale a un’arma, armatura o scudo. ${material.effect}',
      ),
    make('ferro', 'Lingotto di ferro', {
      'Ferro grezzo': 1200,
      'Carbone da forgia': 200,
    }, 1000),
    make('bronzo', 'Lingotto di bronzo', {
      'Rame grezzo': 900,
      'Stagno': 100,
    }, 1000),
    make('acciaio', 'Lingotto di acciaio', {
      'Lingotto di ferro': 1000,
      'Carbone da forgia': 200,
    }, 1000),
    make('cuoio', 'Cuoio conciato', {
      'Cuoio grezzo': 600,
      'Sale alchemico': 100,
    }, 500),
    make('tessuto', 'Tessuto di lino', {'Fibra di lino': 200}, 180),
    make(
      'bende',
      'Bende di lino',
      {'Tessuto di lino': 100, 'Resina ambrata': 20},
      120,
      description:
          'Bende per medicazioni; il Master determina l’effetto della cura.',
    ),
    make(
      'lama_acciaio',
      'Lama d’acciaio',
      {'Lingotto di acciaio': 1500, 'Cuoio conciato': 200},
      1700,
      target: 'weapon',
      description: 'Arma d’acciaio. Statistiche configurabili dal Master.',
    ),
    make(
      'scudo_bronzo',
      'Scudo di bronzo',
      {
        'Lingotto di bronzo': 2000,
        'Legno di frassino': 1000,
        'Cuoio conciato': 200,
      },
      3200,
      target: 'armor',
      description:
          'Scudo con anima di legno e superficie di bronzo. Statistiche configurabili dal Master.',
    ),
    make(
      'corazza_draconica',
      'Corazza draconica',
      {
        'Scaglia draconica': 2000,
        'Cuoio conciato': 1000,
        'Tendine bestiale': 200,
      },
      3200,
      target: 'armor',
      description:
          'Armatura di scaglie draconiche. Statistiche configurabili dal Master.',
    ),
    make(
      'distillato',
      'Radice delle Quattro Vene',
      {'Erba Lunare': 50, 'Fungo luminoso': 25, 'Acqua purificata': 25},
      100,
      target: 'consumable',
      kind: 'alchemy',
      description:
          'Ripristina le statistiche attuali ai massimali secondo le regole della Radice delle Quattro Vene.',
    ),
    make(
      'balsamo',
      'Balsamo di Corteccia Azzurra',
      {'Essenza di Ghiaccio': 25, 'Erba Lunare': 50, 'Acqua purificata': 25},
      100,
      target: 'consumable',
      kind: 'alchemy',
      description:
          'Resistenza al Ghiaccio e Fortificato fino al Riposo Lungo o dopo 2 Riposi Brevi.',
    ),
    make(
      'rinforzo',
      'Rinforzo d’acciaio',
      {'Lingotto di acciaio': 500, 'Cuoio conciato': 100},
      600,
      kind: 'forge',
      effect: '@Difesa+2',
      description: 'Rinforzo per qualsiasi arma, armatura o scudo: +2 Difesa.',
    ),
    make(
      'incisione_fuoco',
      'Incisione di Fuoco',
      {'Essenza di Fuoco': 100, 'Argento lunare': 100},
      200,
      kind: 'forge',
      effect: '@Danni+2 Fuoco',
      description:
          'Incisione per qualsiasi arma, armatura o scudo: +2 Danni da Fuoco.',
    ),
    make(
      'intarsio_golem',
      'Intarsio di golem',
      {'Cuore di golem': 500, 'Cristallo di Oculum grezzo': 100},
      600,
      kind: 'forge',
      effect: '@Scudo+3',
      description: 'Intarsio per qualsiasi arma, armatura o scudo: +3 Scudo.',
    ),
  ];
}

({int damage, int defense, String element, int grade})
oculumCraftedEquipmentBonuses(OculumRecipe recipe) => switch (recipe.id) {
  'expansion_guanto_goblin' => (
    damage: 5,
    defense: 0,
    element: 'perforante',
    grade: 0,
  ),
  'expansion_guanto_forest_demon' => (
    damage: 10,
    defense: 0,
    element: 'perforante',
    grade: 1,
  ),
  'expansion_lama_lupo' => (
    damage: 3,
    defense: 0,
    element: 'tagliente',
    grade: 0,
  ),
  'expansion_mazza_troll' => (
    damage: 4,
    defense: 0,
    element: 'contundente',
    grade: 2,
  ),
  'expansion_scudo_scarabeo' => (
    damage: 0,
    defense: 3,
    element: 'Fisico',
    grade: 1,
  ),
  'expansion_mantello_arpia' => (
    damage: 0,
    defense: 1,
    element: 'Fisico',
    grade: 1,
  ),
  'expansion_guanti_membrana' => (
    damage: 0,
    defense: 1,
    element: 'Fisico',
    grade: 0,
  ),
  _ => (damage: 0, defense: 0, element: 'Fisico', grade: 0),
};

/// Validates everything before consuming anything. Returns an Italian error,
/// or null on success. Only one copy of a stacked target is modified.
String? oculumApplyForgeToItem(
  List<InventoryItem> inventory,
  InventoryItem target,
  OculumRecipe recipe, {
  required int currentOculum,
}) {
  if (!inventory.contains(target) ||
      target.quantita <= 0 ||
      !(target.arma || target.protegge)) {
    return 'Seleziona un’arma, armatura o scudo presente nell’inventario.';
  }
  if (recipe.recipeKind != 'forge' || recipe.ingredients.isEmpty) {
    return 'La forgiatura richiede materiali indicati nella ricetta.';
  }
  final key = recipe.sourceRecipeId.isEmpty ? recipe.id : recipe.sourceRecipeId;
  final applied = List<String>.from(
    target.craftData['forgedRecipes'] as List? ?? const [],
  );
  if (applied.contains(key)) {
    return 'Questa forgiatura è già applicata all’oggetto.';
  }
  if (currentOculum < max(0, recipe.oculumCost)) return 'Oculum insufficiente.';
  final required = <String, int>{};
  for (final ingredient in recipe.ingredients) {
    final grams = double.tryParse(ingredient.grams.replaceAll(',', '.'));
    final name = ingredient.name.trim().toLowerCase();
    if (name.isEmpty ||
        grams == null ||
        !grams.isFinite ||
        grams <= 0 ||
        grams.round() <= 0) {
      return 'Indica nome e grammatura positiva per ogni materiale.';
    }
    required[name] = (required[name] ?? 0) + grams.round();
  }
  for (final entry in required.entries) {
    final available = inventory
        .where(
          (item) =>
              !identical(item, target) &&
              item.nome.trim().toLowerCase() == entry.key,
        )
        .fold<int>(
          0,
          (total, item) =>
              total +
              max(0, (item.peso * 1000 * max(0, item.quantita)).round()),
        );
    if (available < entry.value) {
      return 'Materiali mancanti: ${entry.key}, servono ${entry.value} g (disponibili $available g).';
    }
  }
  var forged = target;
  if (target.quantita > 1) {
    forged = InventoryItem.fromJson(target.toJson())..quantita = 1;
    target.quantita--;
    inventory.add(forged);
  }
  for (final entry in required.entries) {
    var remaining = entry.value;
    for (
      var index = inventory.length - 1;
      index >= 0 && remaining > 0;
      index--
    ) {
      final item = inventory[index];
      if (identical(item, target) ||
          identical(item, forged) ||
          item.nome.trim().toLowerCase() != entry.key) {
        continue;
      }
      final grams = max(0, (item.peso * 1000 * max(0, item.quantita)).round());
      final taken = min(grams, remaining);
      remaining -= taken;
      if (taken == 0) continue;
      if (grams == taken) {
        inventory.removeAt(index);
      } else {
        item
          ..quantita = 1
          ..peso = (grams - taken) / 1000;
      }
    }
  }
  final effect = recipe.forgeEffectText.trim();
  if (effect.isNotEmpty) {
    forged.buff = [
      forged.buff.trim(),
      effect,
    ].where((part) => part.isNotEmpty).join('\n');
  }
  forged.note = [
    forged.note.trim(),
    'Forge: ${recipe.name}',
    recipe.resultDescription,
    'Materiali: ${recipe.ingredients.map((item) => '${item.name} ${item.grams} g').join(', ')}',
  ].where((part) => part.isNotEmpty).join('\n');
  forged.craftData = {
    ...forged.craftData,
    'forgedRecipes': [...applied, key],
  };
  return null;
}

extension _OculumGerin on _OculumHomePageState {
  Future<void> useGerin() async {
    final fragments = inventario
        .where((item) => item.nome.trim().toLowerCase() == 'gerin')
        .fold<int>(0, (count, item) => count + max(0, item.quantita));
    final stats =
        hiddenEyeStats
            .where(
              (stat) =>
                  stat.unlocked &&
                  (stat.id == 'canalizzazione' ||
                      stat.id == 'manifestazione_potere'),
            )
            .toList()
          ..sort((a, b) => hiddenEyeTotal(b).compareTo(hiddenEyeTotal(a)));
    if (fragments < 2 || stats.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Servono due frammenti di Gerin e Canalizzazione o Manifestazione del Potere sbloccata.',
          ),
        ),
      );
      return;
    }
    final harmful = await showDialog<bool>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Vampata di Gerin'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Emissione innocua: nasconde alla vista'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Emissione dannosa: CM oppure i tuoi Danni'),
          ),
        ],
      ),
    );
    if (!mounted || harmful == null) return;
    await tiraSottotrattoOcchio(stats.first);
    if (!mounted) return;
    final rules = harmful
        ? 'I bersagli tirano CM contro questo tiro; se falliscono subiscono i tuoi Danni. Il Master applica elemento, resistenze e danni.'
        : 'I bersagli devono superare questo tiro per vederti. Il Master risolve il confronto.';
    risultato = 'Gerin · ${stats.first.nome}: $dadoMostrato\n$rules';
    aggiungiLog(risultato);
    notifyDiceResultChanged();
    programmaSalvataggio();
  }
}

Map<String, dynamic> oculumCraftedEquipmentSkillData(OculumRecipe recipe) {
  if (recipe.id != 'expansion_guanto_forest_demon') return const {};
  final skill = ArtSkill(
    nome: 'Affondo runico',
    livello: 1,
    evo1:
        'Costo: 1 Volontà. CD 6 turni. Il colpo infligge i tuoi Danni +20, perforanti.',
    oculumMinimiPerLivello: [1],
    oculumMassimiPerLivello: [1],
    risorseCostoPerLivello: ['volonta'],
    aumentoMassimoOculumAttivoPerLivello: [false, false, false, false, false],
    cooldownPerLivello: [OculumAbilityCooldown(amount: 6)],
    effettiPerLivello: [
      [
        OculumStructuredEffect(
          id: 'forest_demon_affondo',
          type: 'danno',
          valueExpression: 'Danni+20',
          recipient: 'bersaglio',
          elementType: 'perforante',
        ),
      ],
    ],
  );
  return {
    'id': 'crafted_forest_demon_gauntlet',
    'craftingRecipeId': recipe.id,
    'skill': skill.toJson(),
  };
}
