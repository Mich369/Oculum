part of 'monster_book.dart';

const oculumEivaFamilyIdRule = 'eivaFamilyId';
const oculumCorallwhirlId = 'affogato_vortice_delle_arcate';
const oculumCorallwhirlDashEffect = 'corallwhirl_scatto_tre_maree';
const oculumCorallwhirlDashSkillId =
    '${oculumCorallwhirlId}_skill_scatto_tre_maree';
const oculumPredoneBoomerangId = 'affogato_predone_delle_nasse';
const oculumPredoneCloseReduction = 'danni_ravvicinati_ricevuti';
const oculumPredoneRangedReduction = 'danni_a_distanza_ricevuti';
bool oculumIsPredoneOrbitTarget(Object? target) => const {
  oculumPredoneCloseReduction,
  oculumPredoneRangedReduction,
}.contains(target);

const oculumPiovraSucchiasangueId = 'piovra_succhiasangue';
const oculumPiovraBiteDrain = 'piovra_morso_assorbimento';

List<String> oculumPiovraNaturalSkillIds(MonsterBookEntry monster) =>
    monster.encounterRules[oculumEivaFamilyIdRule] ==
        oculumPiovraSucchiasangueId
    ? ['${monster.id}_skill_morso', '${monster.id}_skill_presa_succhiasangue']
    : const [];

class _SunkenFamily {
  const _SunkenFamily({
    required this.id,
    required this.name,
    required this.areaId,
    required this.description,
    required this.aggression,
    required this.anatomy,
    required this.base,
    required this.variants,
    this.nameChoices = const [],
    this.weapon,
  });

  final String id, name, areaId, description, aggression;
  final List<Map<String, dynamic>> anatomy;
  final _SunkenForm base;
  final List<_SunkenForm> variants;
  final List<({String name, String meaning})> nameChoices;
  final _SunkenWeapon? weapon;
}

class _SunkenForm {
  const _SunkenForm({
    required this.element,
    required this.stats,
    required this.moves,
    this.label = '',
    this.description = '',
    this.aggression = '',
  });

  final String element, label, description, aggression;
  final List<int> stats;
  final List<_SunkenMove> moves;
}

class _SunkenMove {
  const _SunkenMove({
    required this.id,
    required this.name,
    required this.kind,
    required this.description,
    this.conditionId,
  });

  final String id, name, kind, description;
  final String? conditionId;
}

class _SunkenWeapon {
  const _SunkenWeapon({
    required this.id,
    required this.name,
    required this.partId,
    this.held = false,
  });

  final String id, name, partId;
  final bool held;
}

Iterable<_SunkenFamily> get _sunkenFamilies sync* {
  yield* _sunkenFirstFamilies;
  yield* _sunkenLastFamilies;
}

String _sunkenEntryId(_SunkenFamily family, _SunkenForm form) =>
    form.label.isEmpty ? family.id : '${family.id}_variante_${form.element}';

String _sunkenSkillId(String entryId, _SunkenMove move) =>
    '${entryId}_skill_${move.id}';

MonsterBookEntry _sunkenBookEntry(_SunkenFamily family, _SunkenForm form) {
  final id = _sunkenEntryId(family, form);
  final octopus = family.id == oculumPiovraSucchiasangueId;
  final predone = family.id == oculumPredoneBoomerangId;
  final base = id == family.id;
  final name = base ? family.name : '${family.name} ${form.label}';
  final aggression = base ? family.aggression : form.aggression;
  final description = [
    family.description,
    if (!base) form.description,
    aggression,
  ].join(' ');
  final weapon = family.weapon;
  final anatomy = [
    for (final part in family.anatomy) Map<String, dynamic>.from(part),
  ];
  final weakPoints = anatomy
      .where((part) => part['weak'] == true)
      .map((part) => part['label'])
      .join(', ');
  return MonsterBookEntry(
    id: id,
    nameIt: name,
    nameEn: name,
    descIt: description,
    descEn: description,
    planeIds: const ['affogato'],
    elementId: form.element,
    spriteAssetPath: '',
    isBoss: false,
    isMiniBoss: false,
    isNullFateless: false,
    weakPointIt: weakPoints,
    stats: {
      'level': 0,
      'resilienza': form.stats[0],
      'volonta': form.stats[1],
      'materia': form.stats[2],
      'oculum': form.stats[3],
      if (form.stats[3] > 0) 'oculumArt': 1,
    },
    skillIds: [
      if (octopus) ...['${id}_skill_morso', '${id}_skill_presa_succhiasangue'],
      for (final move in form.moves) _sunkenSkillId(id, move),
      if (octopus)
        for (var index = 0; index < 7; index++)
          '$oculumMonsterProgressionPrefix${id}__$index',
    ],
    canWieldWeapons: weapon?.held == true,
    weaponTags: [
      if (weapon != null && weapon.held) weapon.name,
      if (predone) 'Spada corta del Predone',
    ],
    inventoryItems: [
      if (weapon != null && weapon.held)
        {
          'nome': weapon.name,
          'quantita': 1,
          'peso': 1.0,
          'arma': true,
          'equipaggiata': true,
          'elementoDanno': predone
              ? oculumLamaOrbitaElements.first
              : form.element,
          if (predone)
            'note':
                'Boomerang appuntito e bilanciato. Il guanto d’arme lo '
                'alloggia e lo orienta. Il volo è sostenuto dalla magia.',
          'craftData': {
            'eivaWeaponId': weapon.id,
            if (predone)
              oculumLamaOrbitaId: {
                'affinity': 0,
                'maximumAffinity': oculumLamaOrbitaMaximumAffinity,
                'elements': List<String>.of(oculumLamaOrbitaElements),
              },
          },
        },
      if (predone) ...[
        {
          'nome': 'Spada corta del Predone',
          'quantita': 1,
          'peso': 1.0,
          'arma': true,
          'equipaggiata': true,
          'bonusDanno': 3,
          'elementoDanno': 'taglio',
          'craftData': {'eivaWeaponId': 'spada_corta_del_predone'},
        },
        {
          'nome': 'Guanto d’arme di Orbita',
          'quantita': 1,
          'peso': .5,
          'protegge': true,
          'equipaggiata': true,
          'bonusDanno': 3,
          'bonusDifesa': 4,
          'bonusScudo': 10,
          'note':
              'Ha un alloggiamento aperto. Trattiene la Lama Orbita '
              'quando rientra e la lascia scorrere libera durante il lancio.',
          'craftData': {'eivaWeaponId': oculumLamaOrbitaGauntletId},
        },
      ],
    ],
    encounterRules: {
      'authoredCanonical': true,
      if (octopus) 'authoredSkillPool': true,
      if (id == oculumCorallwhirlId)
        'signatureSkillId': oculumCorallwhirlDashSkillId,
      if (predone) ...{
        'signatureSkillId': _sunkenSkillId(id, form.moves.first),
        'predoneLootScrollIds': [
          for (final move in form.moves) _sunkenSkillId(id, move),
        ],
      },
      oculumEivaFamilyIdRule: family.id,
      'eivaAreaId': family.areaId,
      'speciesId': family.id,
      'speciesNameIt': family.name,
      'speciesNameEn': family.name,
      'generationSide': 'enemy',
      'dispositions': const ['ostile'],
      'naturalAttitude': aggression,
      'precisionBodyParts': anatomy,
      if (!base) 'canonicalVariantOf': family.id,
      if (base && family.nameChoices.isNotEmpty)
        'proposedNames': [
          for (final choice in family.nameChoices)
            {'name': choice.name, 'meaning': choice.meaning},
        ],
      if (weapon != null) ...{
        'eivaWeaponId': weapon.id,
        'eivaWeaponPartId': weapon.partId,
      },
    },
    classificationTags: [
      'Creatura planare',
      'Ostile',
      if (weapon?.held == true) 'Umanoide',
      if (!base) 'Variante elementale',
    ],
  );
}

final _sunkenRealmEntries = <MonsterBookEntry>[
  for (final family in _sunkenFamilies) ...[
    _sunkenBookEntry(family, family.base),
    for (final form in family.variants) _sunkenBookEntry(family, form),
  ],
];

List<MonsterTechniqueEffect> _sunkenEffects(_SunkenMove move, int form) {
  switch (move.kind) {
    case 'scatto_tre_maree':
      return const [
        MonsterTechniqueEffect(
          'danno',
          '3',
          target: oculumCorallwhirlDashEffect,
          mode: 'immediato',
          duration: '',
          recipient: 'nemico',
          shieldDamageBonusPercent: 120,
        ),
      ];
    case 'orbita_boomerang':
      return const [
        MonsterTechniqueEffect(
          'modifica_statistica',
          '12',
          target: oculumPredoneCloseReduction,
          mode: 'temporaneo',
          duration: '3',
          durationUnit: 'azioni',
        ),
        MonsterTechniqueEffect(
          'modifica_statistica',
          '6',
          target: oculumPredoneRangedReduction,
          mode: 'temporaneo',
          duration: '3',
          durationUnit: 'azioni',
        ),
      ];
    case 'danno':
    case 'stato_su_critico':
      return [
        MonsterTechniqueEffect(
          'danno',
          '${4 + form * 5}',
          mode: 'prossima_azione',
          duration: '',
        ),
        if (move.conditionId case final String condition)
          MonsterTechniqueEffect(
            'stato',
            '1',
            target: condition,
            duration: '2',
            recipient: 'nemico',
            criticalOnly: true,
          ),
      ];
    case 'scudo':
      return [
        MonsterTechniqueEffect(
          'scudo',
          '${8 + form * 7}',
          mode: 'immediato',
          duration: '',
        ),
      ];
    case 'difesa':
      return [MonsterTechniqueEffect('difesa', '${3 + form * 2}')];
    case 'iniziativa':
      return [
        MonsterTechniqueEffect(
          'modifica_sottotratto',
          '${2 + form * 2}',
          target: 'iniziativa',
        ),
      ];
    case 'stato':
      return [
        MonsterTechniqueEffect(
          'stato',
          '${form + 1}',
          target: move.conditionId!,
        ),
      ];
    default:
      throw ArgumentError.value(move.kind, 'kind');
  }
}

MonsterConcreteTechnique _sunkenTechnique(
  _SunkenForm form,
  _SunkenMove move,
) => _planarMove(
  move.name,
  move.description,
  form.element,
  switch (move.kind) {
    'scatto_tre_maree' => 'danno',
    'orbita_boomerang' => 'difesa',
    'iniziativa' => 'movimento',
    'stato_su_critico' => 'danno',
    _ => move.kind,
  },
  [for (var level = 0; level < 3; level++) _sunkenEffects(move, level)],
  costResource: move.kind == 'scatto_tre_maree' ? 'nessuna' : 'oculum',
  minimums: move.kind == 'scatto_tre_maree' ? const [0, 0, 0] : const [1, 2, 3],
  maximums: move.kind == 'scatto_tre_maree' ? const [0, 0, 0] : const [1, 2, 3],
  cd: move.kind == 'scatto_tre_maree' ? const [0, 0, 0] : const [2, 2, 3],
);

final _sunkenRealmTechniques = <String, MonsterConcreteTechnique>{
  for (final family in _sunkenFamilies)
    for (final form in [family.base, ...family.variants])
      for (final move in form.moves)
        _sunkenSkillId(_sunkenEntryId(family, form), move): _sunkenTechnique(
          form,
          move,
        ),
  for (final family in _sunkenLastFamilies)
    if (family.id == oculumPiovraSucchiasangueId)
      for (final form in [family.base, ...family.variants]) ...{
        '${_sunkenEntryId(family, form)}_skill_morso': _octopusBite(
          form.element,
        ),
        '${_sunkenEntryId(family, form)}_skill_presa_succhiasangue':
            _octopusGrab(form.element),
      },
};

MonsterConcreteTechnique _octopusBite(String element) =>
    MonsterConcreteTechnique(
      name: 'Morso succhiasangue',
      action: 'Morde da vicino con il becco al centro della corona di ventose.',
      element: element,
      kind: 'attacco',
      requiredLevel: 0,
      costResource: 'nessuna',
      minimums: const [0, 0, 0],
      maximums: const [0, 0, 0],
      cooldownValues: const [0, 0, 0],
      forms: List.filled(3, const [
        MonsterTechniqueEffect(
          'danno',
          '3*grado',
          dice: '1d12',
          mode: 'prossima_azione',
          duration: '',
        ),
        MonsterTechniqueEffect(
          'planar',
          '50',
          target: oculumPiovraBiteDrain,
          mode: 'prossima_azione',
          recipient: 'nemico',
          duration: '',
        ),
      ]),
    );

MonsterConcreteTechnique _octopusGrab(String element) =>
    MonsterConcreteTechnique(
      name: 'Presa succhiasangue',
      action:
          'Stringe una preda fra le braccia e la trattiene finché si libera.',
      element: element,
      kind: 'attacco',
      requiredLevel: 0,
      costResource: 'nessuna',
      minimums: const [0, 0, 0],
      maximums: const [0, 0, 0],
      cooldownValues: const [0, 0, 0],
      forms: List.filled(3, const [
        MonsterTechniqueEffect(
          'planar',
          'grado',
          dice: '1d6',
          target: 'piovra_presa_succhiasangue',
          mode: 'prossima_azione',
          recipient: 'nemico',
          duration: '',
        ),
        MonsterTechniqueEffect(
          'planar',
          '50',
          target: 'piovra_presa_recupero',
          mode: 'prossima_azione',
          duration: '',
        ),
      ]),
    );

const _sunkenLastFamilies = <_SunkenFamily>[
  _SunkenFamily(
    id: oculumPiovraSucchiasangueId,
    name: 'Octocruor',
    areaId: 'corallo_cavo',
    description:
        'Piovra nero melanzana con un mantello ruggine e corallo. Le otto braccia hanno ventose scure. Al centro, una corona distinta di ventose più fini circonda la bocca con cui si nutre.',
    aggression:
        'Insegue attivamente chi passa vicino alla tana, si aggrappa a una sola preda e le avvicina la corona delle ventose.',
    anatomy: [
      {'id': 'body', 'label': 'Corpo', 'group': 'body'},
      {'id': 'mantle', 'label': 'Mantello corallino', 'group': 'mantle'},
      {
        'id': 'eyes_1',
        'label': 'Occhio destro',
        'group': 'eyes',
        'side': 'right',
      },
      {
        'id': 'eyes_2',
        'label': 'Occhio sinistro',
        'group': 'eyes',
        'side': 'left',
      },
      {'id': 'arms_1', 'label': 'Braccio 1', 'group': 'arms'},
      {'id': 'arms_2', 'label': 'Braccio 2', 'group': 'arms'},
      {'id': 'arms_3', 'label': 'Braccio 3', 'group': 'arms'},
      {'id': 'arms_4', 'label': 'Braccio 4', 'group': 'arms'},
      {'id': 'arms_5', 'label': 'Braccio 5', 'group': 'arms'},
      {'id': 'arms_6', 'label': 'Braccio 6', 'group': 'arms'},
      {'id': 'arms_7', 'label': 'Braccio 7', 'group': 'arms'},
      {'id': 'arms_8', 'label': 'Braccio 8', 'group': 'arms'},
      {
        'id': 'feeding_ring',
        'label': 'Corona delle ventose di nutrimento',
        'group': 'mouth',
        'weak': true,
      },
    ],
    nameChoices: [
      (
        name: 'Sanguysiph',
        meaning: 'sanguis · sangue; siphon · sifone. Sifone del sangue.',
      ),
      (
        name: 'Octydrain',
        meaning:
            'octo · otto; drain · prosciugare. Prosciugatrice a otto braccia.',
      ),
    ],
    weapon: _SunkenWeapon(
      id: 'ventose_prensive',
      name: 'Corona di ventose e braccia prensili',
      partId: 'feeding_ring',
    ),
    base: _SunkenForm(
      element: 'veleno',
      stats: [4, 3, 2, 4],
      moves: [
        _SunkenMove(
          id: 'attack',
          name: 'Sanguis Grasp',
          kind: 'danno',
          description: 'Serra le ventose per un colpo di Veleno.',
        ),
        _SunkenMove(
          id: 'drain',
          name: 'Octy Drain',
          kind: 'stato',
          description:
              'Cura legata al colpo tramite Vampirismo esistente, con valori modificabili.',
          conditionId: 'vampirismo',
        ),
      ],
    ),
    variants: [
      _SunkenForm(
        label: 'A corona nera',
        element: 'buio',
        stats: [4, 4, 2, 3],
        description:
            'Nero melanzana quasi uniforme, con una corona più scura delle braccia.',
        aggression: 'Cerca le pieghe in ombra fra i supporti delle rimesse.',
        moves: [
          _SunkenMove(
            id: 'attack',
            name: 'Sanguis Shade',
            kind: 'danno',
            description: 'Le ventose portano un colpo di Buio.',
          ),
          _SunkenMove(
            id: 'guard',
            name: 'Octy Fold',
            kind: 'difesa',
            description:
                'Ripiega le braccia sopra la corona e aumenta la Difesa temporanea.',
          ),
        ],
      ),
      _SunkenForm(
        label: 'A ventose pallide',
        element: 'spirituale',
        stats: [3, 5, 1, 4],
        description:
            'Il mantello rimane ruggine, le ventose di nutrimento brillano color madreperla.',
        aggression:
            'Lascia le travi allo scoperto e punta il nemico isolato dietro al gruppo.',
        moves: [
          _SunkenMove(
            id: 'attack',
            name: 'Octy Wail',
            kind: 'danno',
            description:
                'Una vibrazione nella corona produce un colpo Spirituale.',
          ),
          _SunkenMove(
            id: 'protect',
            name: 'Sanguis Ward',
            kind: 'scudo',
            description:
                'Porta le braccia davanti al mantello e ottiene Scudo normale.',
          ),
        ],
      ),
    ],
  ),
  _SunkenFamily(
    id: 'eiva_rondine_guglie',
    name: 'Rondine delle guglie',
    areaId: 'corallo_cavo',
    description:
        'Un pesce lungo quanto un avambraccio porta due grandi pinne a falce, due pinne pelviche corte e una coda biforcuta. Le lamine delle pinne vibrano nelle correnti verticali dell’Eiva.',
    aggression:
        'Sale sopra il bersaglio e gli piomba contro tra una guglia e l’altra, quindi si prepara a risalire.',
    anatomy: [
      {'id': 'body', 'label': 'Corpo', 'group': 'body'},
      {'id': 'head', 'label': 'Testa', 'group': 'head'},
      {
        'id': 'gills_1',
        'label': 'Branchia destra',
        'group': 'gills',
        'weak': true,
        'side': 'right',
      },
      {
        'id': 'gills_2',
        'label': 'Branchia sinistra',
        'group': 'gills',
        'weak': true,
        'side': 'left',
      },
      {
        'id': 'fins_1',
        'label': 'Pinna destra',
        'group': 'fins',
        'side': 'right',
      },
      {
        'id': 'fins_2',
        'label': 'Pinna sinistra',
        'group': 'fins',
        'side': 'left',
      },
      {
        'id': 'pelvic_fins_1',
        'label': 'Pinna pelvica 1',
        'group': 'pelvic_fins',
      },
      {
        'id': 'pelvic_fins_2',
        'label': 'Pinna pelvica 2',
        'group': 'pelvic_fins',
      },
      {'id': 'tail', 'label': 'Coda', 'group': 'tail'},
    ],
    nameChoices: [
      (
        name: 'Turrydart',
        meaning: 'turris · torre; dart · dardo. Dardo delle torri.',
      ),
      (name: 'Furcawyng', meaning: 'furca · forca; wing · ala. Ala a forca.'),
    ],
    weapon: _SunkenWeapon(
      id: 'becco_sagittale',
      name: 'Becco affusolato',
      partId: 'head',
    ),
    base: _SunkenForm(
      element: 'fulmine',
      stats: [2, 3, 1, 5],
      moves: [
        _SunkenMove(
          id: 'attack',
          name: 'Turris Spark',
          kind: 'danno',
          description:
              'Punta il muso sul bersaglio e scarica un colpo di Fulmine.',
        ),
        _SunkenMove(
          id: 'tempo',
          name: 'Furca Swift',
          kind: 'iniziativa',
          description:
              'Le pinne vibrano e aumentano temporaneamente l’Iniziativa.',
        ),
      ],
    ),
    variants: [
      _SunkenForm(
        label: 'Delle risalite',
        element: 'acqua',
        stats: [3, 2, 2, 4],
        description: 'Le lamelle larghe diventano azzurro lattiginoso.',
        aggression: 'Risale sotto le vittime che voltano verso i gradoni.',
        moves: [
          _SunkenMove(
            id: 'attack',
            name: 'Unda Pike',
            kind: 'danno',
            description: 'Usa entrambe le pinne per dirigere un colpo d’Acqua.',
          ),
          _SunkenMove(
            id: 'protect',
            name: 'Furca Foam',
            kind: 'scudo',
            description: 'L’Eiva spinta dalle pinne forma Scudo normale.',
          ),
        ],
      ),
      _SunkenForm(
        label: 'Senza riflesso',
        element: 'buio',
        stats: [2, 4, 2, 3],
        description: 'Pinne nere e ventre privo delle striature riflettenti.',
        aggression:
            'Attacca dai passaggi stretti quando gli intrusi si avvicinano al muro.',
        moves: [
          _SunkenMove(
            id: 'attack',
            name: 'Umbradart',
            kind: 'danno',
            description: 'Concentra Buio nel colpo di becco.',
          ),
          _SunkenMove(
            id: 'guard',
            name: 'Turris Shroud',
            kind: 'difesa',
            description:
                'Si raccoglie dietro le pinne e aumenta temporaneamente la Difesa.',
          ),
        ],
      ),
    ],
  ),
  _SunkenFamily(
    id: 'eiva_razza_cisterne',
    name: 'Razza delle cisterne',
    areaId: 'corallo_cavo',
    description:
        'Razza a rombo col muso incavato, due grandi ali natatorie, due branchie ventrali esterne e un’unica lunga coda con pungiglione. Il dorso si sporca della stessa polvere delle tegole.',
    aggression:
        'Aspetta di lato a una cisterna e sferza l’ultimo del gruppo quando il grosso è già passato.',
    anatomy: [
      {'id': 'body', 'label': 'Corpo', 'group': 'body'},
      {'id': 'head', 'label': 'Testa', 'group': 'head'},
      {
        'id': 'fins_1',
        'label': 'Pinna destra',
        'group': 'fins',
        'side': 'right',
      },
      {
        'id': 'fins_2',
        'label': 'Pinna sinistra',
        'group': 'fins',
        'side': 'left',
      },
      {
        'id': 'gills_1',
        'label': 'Branchia destra',
        'group': 'gills',
        'weak': true,
        'side': 'right',
      },
      {
        'id': 'gills_2',
        'label': 'Branchia sinistra',
        'group': 'gills',
        'weak': true,
        'side': 'left',
      },
      {'id': 'tail', 'label': 'Coda', 'group': 'tail'},
      {'id': 'stinger', 'label': 'Pungiglione', 'group': 'stinger'},
    ],
    nameChoices: [
      (
        name: 'Cystarow',
        meaning:
            'cisterna · cisterna; row · vogare. Quella che voga fra le cisterne.',
      ),
      (
        name: 'Venybarb',
        meaning:
            'venenum · veleno; barb · punta uncinata. Pungiglione di veleno.',
      ),
    ],
    weapon: _SunkenWeapon(
      id: 'pungiglione_caudale',
      name: 'Pungiglione caudale',
      partId: 'stinger',
    ),
    base: _SunkenForm(
      element: 'veleno',
      stats: [3, 3, 2, 4],
      moves: [
        _SunkenMove(
          id: 'condition',
          name: 'Veny Barb',
          kind: 'stato_su_critico',
          description: 'La sferzata può avvelenare su critico.',
          conditionId: 'avvelenato',
        ),
        _SunkenMove(
          id: 'attack',
          name: 'Cyster Whip',
          kind: 'danno',
          description: 'Usa la coda per un colpo ordinario ravvicinato.',
        ),
      ],
    ),
    variants: [
      _SunkenForm(
        label: 'Delle radichette',
        element: 'natura',
        stats: [4, 3, 2, 3],
        description: 'Sottili fronde vere crescono lungo il rombo e la coda.',
        aggression:
            'Intercetta chi attraversa le radici fra una cisterna e l’altra.',
        moves: [
          _SunkenMove(
            id: 'attack',
            name: 'Radix Lash',
            kind: 'danno',
            description: 'Le fronde accompagnano un colpo di Natura.',
          ),
          _SunkenMove(
            id: 'protect',
            name: 'Cyster Bark',
            kind: 'scudo',
            description:
                'Ripiega le fronde sopra il dorso e trae Scudo normale.',
          ),
        ],
      ),
      _SunkenForm(
        label: 'Di coccio',
        element: 'roccia',
        stats: [5, 2, 4, 1],
        description:
            'Sul rombo crescono placche piatte, simili ai cocci delle cisterne.',
        aggression:
            'Taglia l’uscita dai canali bassi, spingendo l’intruso contro il bordo.',
        moves: [
          _SunkenMove(
            id: 'attack',
            name: 'Saxum Ram',
            kind: 'danno',
            description: 'Colpisce di piatto con il dorso corazzato.',
          ),
          _SunkenMove(
            id: 'guard',
            name: 'Cyster Plate',
            kind: 'difesa',
            description: 'Usa le scaglie di coccio per Difesa temporanea.',
          ),
        ],
      ),
    ],
  ),
  _SunkenFamily(
    id: 'eiva_spugna_salmastra',
    name: 'Spugna succhiasale',
    areaId: 'fronde_eiva',
    description:
        'Colonia spugnosa alta fino alla vita, con una bocca a imbuto, tre peduncoli prensili e due filtri a nastro. Il bordo pieghevole dell’imbuto rivela fibre chiare.',
    aggression:
        'Si apposta sul ramo orientato controcorrente e scatta appena qualcuno attraversa vicino alla bocca.',
    anatomy: [
      {'id': 'body', 'label': 'Corpo', 'group': 'body'},
      {
        'id': 'funnel',
        'label': 'Orlo dell’imbuto',
        'group': 'mouth',
        'weak': true,
      },
      {'id': 'stems_1', 'label': 'Peduncolo 1', 'group': 'stems'},
      {'id': 'stems_2', 'label': 'Peduncolo 2', 'group': 'stems'},
      {'id': 'stems_3', 'label': 'Peduncolo 3', 'group': 'stems'},
      {'id': 'filters_1', 'label': 'Filtro a nastro 1', 'group': 'filters'},
      {'id': 'filters_2', 'label': 'Filtro a nastro 2', 'group': 'filters'},
    ],
    nameChoices: [
      (
        name: 'Salysieve',
        meaning: 'sal · sale; sieve · setaccio. Setaccio del sale.',
      ),
      (
        name: 'Spongystalk',
        meaning: 'spongia · spugna; stalk · peduncolo. Spugna dai fusti.',
      ),
    ],
    weapon: _SunkenWeapon(
      id: 'imbuto_contrattile',
      name: 'Orlo a imbuto',
      partId: 'funnel',
    ),
    base: _SunkenForm(
      element: 'natura',
      stats: [4, 2, 3, 3],
      moves: [
        _SunkenMove(
          id: 'attack',
          name: 'Salysieve Snap',
          kind: 'danno',
          description: 'Chiude l’orlo in un colpo di Natura.',
        ),
        _SunkenMove(
          id: 'protect',
          name: 'Spongia Wrap',
          kind: 'scudo',
          description:
              'Arrotola i filtri davanti all’imbuto e ottiene Scudo normale.',
        ),
      ],
    ),
    variants: [
      _SunkenForm(
        label: 'Del ritorno',
        element: 'spirituale',
        stats: [3, 5, 1, 3],
        description:
            'I due filtri sono velati da un bagliore lattiginoso e l’imbuto resta distinguibile.',
        aggression: 'Aggredisce chi si ferma a osservare i filtri da vicino.',
        moves: [
          _SunkenMove(
            id: 'attack',
            name: 'Spongia Echo',
            kind: 'danno',
            description: 'L’imbuto emette un colpo Spirituale.',
          ),
          _SunkenMove(
            id: 'guard',
            name: 'Salysieve Ward',
            kind: 'difesa',
            description: 'Contrae le fibre chiare e rinforza la Difesa.',
          ),
        ],
      ),
      _SunkenForm(
        label: 'Dell’ansa',
        element: 'acqua',
        stats: [4, 2, 2, 4],
        description: 'L’imbuto ha un orlo blu slavato e filtri larghi.',
        aggression:
            'Si sporge dalle anse del sentiero e colpisce chi passa a valle.',
        moves: [
          _SunkenMove(
            id: 'attack',
            name: 'Spongia Pulse',
            kind: 'danno',
            description: 'I filtri sospingono un colpo d’Acqua.',
          ),
          _SunkenMove(
            id: 'tempo',
            name: 'Salysieve Rush',
            kind: 'iniziativa',
            description: 'Cede alla corrente e migliora l’Iniziativa.',
          ),
        ],
      ),
    ],
  ),
  _SunkenFamily(
    id: 'eiva_serracapo_mosaici',
    name: 'Malleysaw',
    areaId: 'corallo_cavo',
    description:
        'Umanoide squalo martello, con un cranio largo e appiattito e un occhio a ciascuna estremità. Ha una pinna dorsale, una coda eterocerca e una sega lunga a due mani, fatta di una lama d’osso con denti di conchiglia.',
    aggression:
        'Contende i passaggi stretti con la sega traversa. Se il party lascia aperto un lato, allunga la lama su quel fianco.',
    anatomy: [
      {'id': 'body', 'label': 'Corpo', 'group': 'body'},
      {'id': 'head', 'label': 'Testa', 'group': 'head'},
      {
        'id': 'eyes_1',
        'label': 'Occhio destro',
        'group': 'eyes',
        'side': 'right',
      },
      {
        'id': 'eyes_2',
        'label': 'Occhio sinistro',
        'group': 'eyes',
        'side': 'left',
      },
      {
        'id': 'gills_1',
        'label': 'Branchia destra',
        'group': 'gills',
        'side': 'right',
        'weak': true,
      },
      {
        'id': 'gills_2',
        'label': 'Branchia sinistra',
        'group': 'gills',
        'side': 'left',
        'weak': true,
      },
      {
        'id': 'arms_1',
        'label': 'Braccio destro',
        'group': 'arms',
        'side': 'right',
      },
      {
        'id': 'arms_2',
        'label': 'Braccio sinistro',
        'group': 'arms',
        'side': 'left',
      },
      {
        'id': 'legs_1',
        'label': 'Gamba destra',
        'group': 'legs',
        'side': 'right',
      },
      {
        'id': 'legs_2',
        'label': 'Gamba sinistra',
        'group': 'legs',
        'side': 'left',
      },
      {'id': 'dorsal_fin', 'label': 'Pinna dorsale', 'group': 'fins'},
      {'id': 'tail', 'label': 'Coda dello squalo', 'group': 'tail'},
      {
        'id': 'shell_saw',
        'label': 'Sega a denti di conchiglia',
        'group': 'weapon',
      },
    ],
    nameChoices: [
      (
        name: 'Malleysaw',
        meaning: 'malleus · martello; saw · sega. Sega dalla testa a martello.',
      ),
      (
        name: 'Conchytooth',
        meaning: 'concha · conchiglia; tooth · dente. Dente di conchiglia.',
      ),
    ],
    weapon: _SunkenWeapon(
      id: 'sega_due_mani_conchiglia',
      name: 'Sega lunga a denti di conchiglia',
      partId: 'shell_saw',
      held: true,
    ),
    base: _SunkenForm(
      element: 'roccia',
      stats: [5, 2, 4, 2],
      moves: [
        _SunkenMove(
          id: 'attack',
          name: 'Malleus Rake',
          kind: 'danno',
          description: 'Trascina i denti della sega per un colpo di Roccia.',
        ),
        _SunkenMove(
          id: 'guard',
          name: 'Concha Brace',
          kind: 'difesa',
          description: 'Usa di piatto la sega per aumentare Difesa.',
        ),
      ],
    ),
    variants: [
      _SunkenForm(
        label: 'Della marea chiara',
        element: 'acqua',
        stats: [4, 2, 3, 4],
        description:
            'Il legaccio della sega reca conchiglie bianche e una gola turchese.',
        aggression:
            'Spinge la lotta verso i canali di marea in cui la lama è più facile da muovere.',
        moves: [
          _SunkenMove(
            id: 'attack',
            name: 'Malleus Wash',
            kind: 'danno',
            description: 'Il filo spinge un colpo d’Acqua.',
          ),
          _SunkenMove(
            id: 'tempo',
            name: 'Concha Slide',
            kind: 'iniziativa',
            description:
                'Si volta con un movimento di coda e guadagna Iniziativa.',
          ),
        ],
      ),
      _SunkenForm(
        label: 'Denti di rame',
        element: 'fulmine',
        stats: [4, 3, 2, 4],
        description:
            'Una guaina ramata percorre l’osso della sega fino all’impugnatura.',
        aggression:
            'Aspetta che i nemici si affianchino sulla soglia, poi anticipa il primo che entra.',
        moves: [
          _SunkenMove(
            id: 'attack',
            name: 'Malleus Spark',
            kind: 'danno',
            description: 'Scarica Fulmine lungo i denti della sega.',
          ),
          _SunkenMove(
            id: 'protect',
            name: 'Concha Ward',
            kind: 'scudo',
            description: 'Pianta la lama di traverso e ottiene Scudo normale.',
          ),
        ],
      ),
    ],
  ),
  _SunkenFamily(
    id: 'eiva_pteroi_delle_fronde',
    name: 'Pteroi delle fronde',
    areaId: 'fronde_eiva',
    description:
        'Pesce scorpione umanoide. Ha strisce bruno porpora, occhi sporgenti, una corona dorsale a ventaglio e tre grossi raggi pettorali per lato. Stringe un sottile stocco lungo con guardia a ventaglio.',
    aggression:
        'Punta l’avversario più vicino, presenta il ventaglio per coprire lo stocco e punge quando vede uno spazio.',
    anatomy: [
      {'id': 'body', 'label': 'Corpo', 'group': 'body'},
      {'id': 'head', 'label': 'Testa', 'group': 'head'},
      {
        'id': 'eyes_1',
        'label': 'Occhio destro',
        'group': 'eyes',
        'side': 'right',
      },
      {
        'id': 'eyes_2',
        'label': 'Occhio sinistro',
        'group': 'eyes',
        'side': 'left',
      },
      {
        'id': 'gills_1',
        'label': 'Branchia destra',
        'group': 'gills',
        'side': 'right',
        'weak': true,
      },
      {
        'id': 'gills_2',
        'label': 'Branchia sinistra',
        'group': 'gills',
        'side': 'left',
        'weak': true,
      },
      {
        'id': 'arms_1',
        'label': 'Braccio destro',
        'group': 'arms',
        'side': 'right',
      },
      {
        'id': 'arms_2',
        'label': 'Braccio sinistro',
        'group': 'arms',
        'side': 'left',
      },
      {
        'id': 'legs_1',
        'label': 'Gamba destra',
        'group': 'legs',
        'side': 'right',
      },
      {
        'id': 'legs_2',
        'label': 'Gamba sinistra',
        'group': 'legs',
        'side': 'left',
      },
      {'id': 'dorsal_fan', 'label': 'Ventaglio dorsale', 'group': 'crest'},
      {'id': 'fins_1', 'label': 'Pinna raggiata 1', 'group': 'fins'},
      {'id': 'fins_2', 'label': 'Pinna raggiata 2', 'group': 'fins'},
      {'id': 'fins_3', 'label': 'Pinna raggiata 3', 'group': 'fins'},
      {'id': 'fins_4', 'label': 'Pinna raggiata 4', 'group': 'fins'},
      {'id': 'fins_5', 'label': 'Pinna raggiata 5', 'group': 'fins'},
      {'id': 'fins_6', 'label': 'Pinna raggiata 6', 'group': 'fins'},
      {'id': 'estoc', 'label': 'Stocco a guardia aperta', 'group': 'weapon'},
    ],
    nameChoices: [
      (
        name: 'Pynnastock',
        meaning: 'pinna · pinna; estoc · stocco. Stocco delle pinne.',
      ),
      (
        name: 'Pennaspike',
        meaning: 'penna · penna; spike · spina. Penna spinosa.',
      ),
    ],
    weapon: _SunkenWeapon(
      id: 'stocco_guardia_ventaglio',
      name: 'Stocco a guardia a ventaglio',
      partId: 'estoc',
      held: true,
    ),
    base: _SunkenForm(
      element: 'veleno',
      stats: [3, 4, 2, 4],
      moves: [
        _SunkenMove(
          id: 'condition',
          name: 'Pinna Sting',
          kind: 'stato_su_critico',
          description: 'La punta può applicare Avvelenato su critico.',
          conditionId: 'avvelenato',
        ),
        _SunkenMove(
          id: 'guard',
          name: 'Pynnastock Guard',
          kind: 'difesa',
          description:
              'Presenta di piatto la guardia dello stocco per Difesa temporanea.',
        ),
      ],
    ),
    variants: [
      _SunkenForm(
        label: 'Delle spine vegetali',
        element: 'natura',
        stats: [4, 3, 3, 3],
        description: 'Frange verdi scorrono fra le spine del ventaglio.',
        aggression:
            'Si appropria dei passaggi sotto le fronde e contrattacca da dietro le coste delle foglie.',
        moves: [
          _SunkenMove(
            id: 'attack',
            name: 'Pinna Briar',
            kind: 'danno',
            description: 'Le spine conducono un affondo di Natura.',
          ),
          _SunkenMove(
            id: 'protect',
            name: 'Estoc Frond',
            kind: 'scudo',
            description: 'Dispiega la corona e ottiene Scudo normale.',
          ),
        ],
      ),
      _SunkenForm(
        label: 'Del ventaglio bruciato',
        element: 'buio',
        stats: [3, 5, 2, 3],
        description:
            'Le strisce sono bordò e nere, le spine appaiono abbrustolite.',
        aggression:
            'Preferisce il lato oscuro delle fronde e finta prima di scegliere quale fianco colpire.',
        moves: [
          _SunkenMove(
            id: 'attack',
            name: 'Pinna Shade',
            kind: 'danno',
            description: 'Convoglia Buio nello stocco per il colpo.',
          ),
          _SunkenMove(
            id: 'tempo',
            name: 'Estoc Shift',
            kind: 'iniziativa',
            description: 'Scarta di lato e anticipa l’azione con Iniziativa.',
          ),
        ],
      ),
    ],
  ),
  _SunkenFamily(
    id: 'eiva_stella_fratture',
    name: 'Stella delle fratture',
    areaId: 'fronde_eiva',
    description:
        'Un echinoderma si muove su cinque braccia radiali incrostate. Sotto il disco centrale la bocca chiara è raccolta in una corona di placche più piccole.',
    aggression:
        'Rimane contratta sul pendio fino a quando intrusi risalgono una crepa, poi apre le braccia e avanza dal basso.',
    anatomy: [
      {'id': 'body', 'label': 'Corpo', 'group': 'body'},
      {
        'id': 'mouth',
        'label': 'Bocca ventrale',
        'group': 'mouth',
        'weak': true,
      },
      {'id': 'arms_1', 'label': 'Braccio radiale 1', 'group': 'arms'},
      {'id': 'arms_2', 'label': 'Braccio radiale 2', 'group': 'arms'},
      {'id': 'arms_3', 'label': 'Braccio radiale 3', 'group': 'arms'},
      {'id': 'arms_4', 'label': 'Braccio radiale 4', 'group': 'arms'},
      {'id': 'arms_5', 'label': 'Braccio radiale 5', 'group': 'arms'},
    ],
    nameChoices: [
      (
        name: 'Stellycrack',
        meaning: 'stella · stella; crack · frattura. Stella delle fratture.',
      ),
      (
        name: 'Rymaspur',
        meaning: 'rima · crepa; spur · sperone. Sperone delle crepe.',
      ),
    ],
    weapon: _SunkenWeapon(
      id: 'braccia_incrostate',
      name: 'Braccia incrostate',
      partId: 'arms_1',
    ),
    base: _SunkenForm(
      element: 'roccia',
      stats: [5, 2, 4, 2],
      moves: [
        _SunkenMove(
          id: 'attack',
          name: 'Stella Maul',
          kind: 'danno',
          description: 'Abbatte un braccio incrostato per un colpo di Roccia.',
        ),
        _SunkenMove(
          id: 'protect',
          name: 'Rima Lock',
          kind: 'scudo',
          description: 'Serra le placche e ottiene Scudo normale.',
        ),
      ],
    ),
    variants: [
      _SunkenForm(
        label: 'Dei cinque ciuffi',
        element: 'natura',
        stats: [4, 3, 3, 3],
        description:
            'I cinque bracci portano ciuffi verdi separati dalla bocca chiara.',
        aggression:
            'Scatta contro chi calpesta i ciuffi che sporgono dalle crepe.',
        moves: [
          _SunkenMove(
            id: 'attack',
            name: 'Stella Briar',
            kind: 'danno',
            description: 'I ciuffi rigidi accompagnano il colpo di Natura.',
          ),
          _SunkenMove(
            id: 'guard',
            name: 'Rima Frond',
            kind: 'difesa',
            description:
                'Cala i ciuffi sopra la bocca per ottenere Difesa temporanea.',
          ),
        ],
      ),
      _SunkenForm(
        label: 'A vene bianche',
        element: 'fulmine',
        stats: [4, 3, 2, 4],
        description:
            'Bianche venature accendono le placche lungo tutta l’estensione delle braccia.',
        aggression:
            'Concentra gli assalti sugli intrusi che sostano a metà della spianata.',
        moves: [
          _SunkenMove(
            id: 'attack',
            name: 'Stella Spark',
            kind: 'danno',
            description: 'Concentra Fulmine su un solo braccio e colpisce.',
          ),
          _SunkenMove(
            id: 'tempo',
            name: 'Rima Quick',
            kind: 'iniziativa',
            description:
                'Rimpicciolisce il disco e aumenta temporaneamente l’Iniziativa.',
          ),
        ],
      ),
    ],
  ),
  _SunkenFamily(
    id: 'eiva_chiocciola_condotte',
    name: 'Chiocciola delle condotte',
    areaId: 'corallo_cavo',
    description:
        'Grande gasteropode con guscio alto a gomito, due antenne oculari, un piede allungato e una membrana al margine dell’apertura. Le scie del piede restano sulla parete.',
    aggression:
        'Segue le vibrazioni lungo la condotta e si lascia cadere dall’alto quando un intruso le passa sotto.',
    anatomy: [
      {'id': 'body', 'label': 'Corpo', 'group': 'body'},
      {'id': 'head', 'label': 'Testa', 'group': 'head'},
      {
        'id': 'eyes_1',
        'label': 'Occhio destro',
        'group': 'eyes',
        'side': 'right',
      },
      {
        'id': 'eyes_2',
        'label': 'Occhio sinistro',
        'group': 'eyes',
        'side': 'left',
      },
      {'id': 'foot', 'label': 'Piede muscolare', 'group': 'foot'},
      {'id': 'shell', 'label': 'Guscio', 'group': 'shell'},
      {
        'id': 'lip',
        'label': 'Membrana del guscio',
        'group': 'membrane',
        'weak': true,
      },
    ],
    nameChoices: [
      (
        name: 'Ductyshell',
        meaning: 'ductus · condotto; shell · guscio. Guscio delle condotte.',
      ),
      (
        name: 'Cochlyclimb',
        meaning:
            'cochlea · chiocciola; climb · arrampicarsi. Chiocciola arrampicatrice.',
      ),
    ],
    weapon: _SunkenWeapon(
      id: 'guscio_a_gomito',
      name: 'Guscio alto a gomito',
      partId: 'shell',
    ),
    base: _SunkenForm(
      element: 'acqua',
      stats: [4, 3, 3, 3],
      moves: [
        _SunkenMove(
          id: 'attack',
          name: 'Ductus Rush',
          kind: 'danno',
          description:
              'Lancia un colpo d’Acqua schiacciando il piede contro una parete.',
        ),
        _SunkenMove(
          id: 'guard',
          name: 'Cochlea Curl',
          kind: 'difesa',
          description: 'Si ritrae nell’apertura e aumenta la Difesa.',
        ),
      ],
    ),
    variants: [
      _SunkenForm(
        label: 'Della calcite',
        element: 'roccia',
        stats: [6, 2, 4, 1],
        description:
            'Le spire del guscio sono segnate da gradini di calcite chiara.',
        aggression: 'Tenta di respingere chi supera il suo ingresso preferito.',
        moves: [
          _SunkenMove(
            id: 'attack',
            name: 'Ductus Ram',
            kind: 'danno',
            description:
                'Usa il guscio, ruotato avanti, per un colpo di Roccia.',
          ),
          _SunkenMove(
            id: 'protect',
            name: 'Cochlea Keep',
            kind: 'scudo',
            description:
                'Compatta il margine di calcite e ottiene Scudo normale.',
          ),
        ],
      ),
      _SunkenForm(
        label: 'Dei muri verdi',
        element: 'veleno',
        stats: [4, 4, 2, 3],
        description:
            'Il piede viola lascia una striscia di muco verde nelle condotte.',
        aggression:
            'Si apposta dove due condotte confluiscono e colpisce prima che il gruppo svolti.',
        moves: [
          _SunkenMove(
            id: 'condition',
            name: 'Ductus Slime',
            kind: 'stato_su_critico',
            description:
                'Su critico può applicare la condizione di Veleno già disponibile.',
            conditionId: 'avvelenato',
          ),
          _SunkenMove(
            id: 'guard',
            name: 'Cochlea Film',
            kind: 'difesa',
            description: 'Si ricopre di muco difensivo per un breve rinforzo.',
          ),
        ],
      ),
    ],
  ),
  _SunkenFamily(
    id: 'eiva_tassello_cupole',
    name: 'Tessyfin',
    areaId: 'corallo_cavo',
    description:
        'Pesce triangolare grande quanto uno scudo, con tre pinne asimmetriche e un occhio su ciascun lato largo. Ha il ventre di cotto a scacchi e una gola molle scoperta sul bordo anteriore.',
    aggression:
        'Si stacca dalla volta da un lato e si mette di traverso davanti a chi imbocca l’arco successivo.',
    anatomy: [
      {'id': 'body', 'label': 'Corpo', 'group': 'body'},
      {
        'id': 'eyes_1',
        'label': 'Occhio destro',
        'group': 'eyes',
        'side': 'right',
      },
      {
        'id': 'eyes_2',
        'label': 'Occhio sinistro',
        'group': 'eyes',
        'side': 'left',
      },
      {'id': 'fins_1', 'label': 'Pinna 1', 'group': 'fins'},
      {'id': 'fins_2', 'label': 'Pinna 2', 'group': 'fins'},
      {'id': 'fins_3', 'label': 'Pinna 3', 'group': 'fins'},
      {
        'id': 'throat',
        'label': 'Gola del bordo',
        'group': 'throat',
        'weak': true,
      },
    ],
    nameChoices: [
      (
        name: 'Tessyfin',
        meaning: 'tessera · tassello; fin · pinna. Tassello pinnato.',
      ),
      (
        name: 'Fornyglide',
        meaning:
            'fornix · volta; glide · scivolare. Quello che scivola sotto le volte.',
      ),
    ],
    weapon: _SunkenWeapon(
      id: 'bordo_triangolare',
      name: 'Bordo anteriore triangolare',
      partId: 'throat',
    ),
    base: _SunkenForm(
      element: 'acqua',
      stats: [3, 3, 3, 4],
      moves: [
        _SunkenMove(
          id: 'attack',
          name: 'Tessera Slash',
          kind: 'danno',
          description: 'Usa il bordo anteriore per un colpo d’Acqua.',
        ),
        _SunkenMove(
          id: 'tempo',
          name: 'Fornix Glide',
          kind: 'iniziativa',
          description:
              'Apre le pinne per anticipare la manovra con Iniziativa.',
        ),
      ],
    ),
    variants: [
      _SunkenForm(
        label: 'Della cupola ramata',
        element: 'fulmine',
        stats: [3, 3, 2, 5],
        description: 'Dal mosaico ventrale emergono venature di rame opaco.',
        aggression:
            'Si getta su chi attraversa per primo il centro della cupola.',
        moves: [
          _SunkenMove(
            id: 'attack',
            name: 'Fornix Spark',
            kind: 'danno',
            description: 'Canalizza un colpo di Fulmine attraverso il bordo.',
          ),
          _SunkenMove(
            id: 'guard',
            name: 'Tessera Brace',
            kind: 'difesa',
            description:
                'Ripiega due pinne sopra la gola e rinforza la Difesa.',
          ),
        ],
      ),
      _SunkenForm(
        label: 'Delle cupole pallide',
        element: 'spirituale',
        stats: [3, 5, 1, 4],
        description:
            'Gli occhi sono opalini e le tessere disegnano figure appena riconoscibili.',
        aggression:
            'Assedia i passaggi con piccoli affondi quando qualcuno si gira a cercarlo.',
        moves: [
          _SunkenMove(
            id: 'attack',
            name: 'Tessera Shade',
            kind: 'danno',
            description: 'Canalizza un colpo Spirituale attraverso lo sguardo.',
          ),
          _SunkenMove(
            id: 'protect',
            name: 'Fornix Ward',
            kind: 'scudo',
            description: 'Dispone le pinne a scudo e ottiene Scudo normale.',
          ),
        ],
      ),
    ],
  ),
  _SunkenFamily(
    id: 'eiva_bocca_tonante',
    name: 'Bocca tonante',
    areaId: 'fronde_eiva',
    description:
        'Una bestia pesante con quattro zampe palmate, due occhi piccoli e una mandibola larga coperta di screpolature. Le due fessure branchiali sono ai lati della piega più tenue del collo.',
    aggression:
        'Grugnisce prima dell’affondo e avanza sempre al centro del passaggio, tentando di chiuderlo con la propria mole.',
    anatomy: [
      {'id': 'body', 'label': 'Corpo', 'group': 'body'},
      {'id': 'head', 'label': 'Testa', 'group': 'head'},
      {
        'id': 'eyes_1',
        'label': 'Occhio destro',
        'group': 'eyes',
        'side': 'right',
      },
      {
        'id': 'eyes_2',
        'label': 'Occhio sinistro',
        'group': 'eyes',
        'side': 'left',
      },
      {
        'id': 'gills_1',
        'label': 'Branchia destra',
        'group': 'gills',
        'weak': true,
        'side': 'right',
      },
      {
        'id': 'gills_2',
        'label': 'Branchia sinistra',
        'group': 'gills',
        'weak': true,
        'side': 'left',
      },
      {'id': 'legs_1', 'label': 'Zampa palmata 1', 'group': 'legs'},
      {'id': 'legs_2', 'label': 'Zampa palmata 2', 'group': 'legs'},
      {'id': 'legs_3', 'label': 'Zampa palmata 3', 'group': 'legs'},
      {'id': 'legs_4', 'label': 'Zampa palmata 4', 'group': 'legs'},
      {'id': 'jaw', 'label': 'Mandibola', 'group': 'jaw'},
    ],
    nameChoices: [
      (
        name: 'Tonaryjaw',
        meaning: 'tonare · tuonare; jaw · mascella. Mascella tonante.',
      ),
      (
        name: 'Rymagape',
        meaning:
            'rima · fessura; gape · apertura delle fauci. Fauci a fessura.',
      ),
    ],
    weapon: _SunkenWeapon(
      id: 'fauci_tonanti',
      name: 'Mandibola larga',
      partId: 'jaw',
    ),
    base: _SunkenForm(
      element: 'buio',
      stats: [5, 3, 2, 3],
      moves: [
        _SunkenMove(
          id: 'attack',
          name: 'Tonare Bite',
          kind: 'danno',
          description: 'Satura di Buio il morso lungo il passaggio.',
        ),
        _SunkenMove(
          id: 'guard',
          name: 'Rima Grunt',
          kind: 'difesa',
          description: 'Piega il collo prima dell’impatto e aumenta Difesa.',
        ),
      ],
    ),
    variants: [
      _SunkenForm(
        label: 'Di guado duro',
        element: 'roccia',
        stats: [6, 2, 4, 1],
        description: 'Scudi di pietra naturale coprono il muso e le spalle.',
        aggression:
            'Blocca chi cerca di passare tra due radici lontano dal branco.',
        moves: [
          _SunkenMove(
            id: 'attack',
            name: 'Tonare Ram',
            kind: 'danno',
            description: 'Colpisce di muso con un impatto di Roccia.',
          ),
          _SunkenMove(
            id: 'protect',
            name: 'Rima Wall',
            kind: 'scudo',
            description: 'Serra le placche spontanee e ottiene Scudo normale.',
          ),
        ],
      ),
      _SunkenForm(
        label: 'Dei rami risonanti',
        element: 'fulmine',
        stats: [4, 3, 2, 4],
        description:
            'Tacche irregolari gialle ravvivano la mandibola e i palmi.',
        aggression:
            'Parte appena l’intruso prova a scavalcare un ramo immerso.',
        moves: [
          _SunkenMove(
            id: 'attack',
            name: 'Tonare Bolt',
            kind: 'danno',
            description:
                'Accende la mandibola e convoglia un colpo di Fulmine.',
          ),
          _SunkenMove(
            id: 'tempo',
            name: 'Rima Rush',
            kind: 'iniziativa',
            description: 'Il fremito delle zampe aumenta l’Iniziativa.',
          ),
        ],
      ),
    ],
  ),
];
