part of 'monster_book.dart';

const oculumAcuagoblinId = 'acuagoblin';
const oculumAcuagoblinDodgeSkill = 'acuagoblin_guizzo';
const oculumAcuagoblinDodgeEffect = 'acuagoblin_guizzo_preparato';
const oculumAcuagoblinWaterJetSkill = 'acuagoblin_getto_acqua';

bool oculumCanAcuagoblinDash({
  required bool inWater,
  required bool defenseSucceeded,
  required double distanceMeters,
  required double maximumMeters,
}) =>
    inWater &&
    defenseSucceeded &&
    distanceMeters.isFinite &&
    maximumMeters.isFinite &&
    distanceMeters > 0 &&
    distanceMeters <= maximumMeters;

const _acuagoblinAnatomy = <Map<String, dynamic>>[
  {'id': 'body', 'group': 'body', 'label': 'Corpo'},
  {'id': 'head', 'group': 'head', 'label': 'Testa'},
  {'id': 'eyes_1', 'group': 'eyes', 'label': 'Occhio destro', 'side': 'right'},
  {'id': 'eyes_2', 'group': 'eyes', 'label': 'Occhio sinistro', 'side': 'left'},
  {
    'id': 'ears_1',
    'group': 'ears',
    'label': 'Orecchio a pinna destro',
    'side': 'right',
  },
  {
    'id': 'ears_2',
    'group': 'ears',
    'label': 'Orecchio a pinna sinistro',
    'side': 'left',
  },
  {
    'id': 'gills_1',
    'group': 'gills',
    'label': 'Branchia destra',
    'side': 'right',
    'penalty': 4,
  },
  {
    'id': 'gills_2',
    'group': 'gills',
    'label': 'Branchia sinistra',
    'side': 'left',
    'penalty': 4,
  },
  {'id': 'arms_1', 'group': 'arms', 'label': 'Braccio destro', 'side': 'right'},
  {
    'id': 'arms_2',
    'group': 'arms',
    'label': 'Braccio sinistro',
    'side': 'left',
  },
  {'id': 'legs_1', 'group': 'legs', 'label': 'Gamba destra', 'side': 'right'},
  {'id': 'legs_2', 'group': 'legs', 'label': 'Gamba sinistra', 'side': 'left'},
];

final _acuagoblinEntries = <MonsterBookEntry>[
  for (final variant in const [
    (
      id: 'territoriale',
      it: 'Territoriale',
      en: 'Territorial',
      side: 'neutral',
      attitude:
          'Sorveglia gli accessi della colonia e avverte chi si avvicina. Difende il territorio se gli avvisi vengono ignorati.',
      stats: [6, 4, 6, 3],
    ),
    (
      id: 'predatore',
      it: 'Predatore',
      en: 'Predator',
      side: 'enemy',
      attitude:
          'Aspetta nelle nicchie allagate e tende imboscate a chi si allontana dal gruppo.',
      stats: [5, 7, 5, 3],
    ),
    (
      id: 'curioso',
      it: 'Curioso',
      en: 'Curious',
      side: 'neutral',
      attitude:
          'Si avvicina per osservare gli sconosciuti e mostra interesse per gli oggetti che portano. Si ritira se minacciato.',
      stats: [4, 4, 5, 6],
    ),
  ])
    MonsterBookEntry(
      id: '${oculumAcuagoblinId}_variante_${variant.id}',
      nameIt: 'Acuagoblin ${variant.it}',
      nameEn: 'Acuagoblin ${variant.en}',
      descIt:
          'Goblin anfibio turchese dagli occhi gialli, con due orecchie a pinna, due branchie sui lati del collo, due braccia, due gambe e dita palmate. Abita le rovine sommerse del Regno Affogato. ${variant.attitude}',
      descEn:
          'A turquoise amphibious goblin with yellow eyes, two fin-like ears, two gills on the sides of its neck, two arms, two legs, and webbed digits. It inhabits submerged ruins in the Drowned Realm.',
      elementId: 'acqua',
      planeIds: const ['affogato'],
      spriteAssetPath: '',
      isMiniBoss: false,
      isBoss: false,
      isNullFateless: false,
      stats: {
        'level': 0,
        'resilienza': variant.stats[0],
        'volonta': variant.stats[1],
        'materia': variant.stats[2],
        'oculum': variant.stats[3],
      },
      encounterRules: {
        'authoredCanonical': true,
        'speciesId': oculumAcuagoblinId,
        'speciesNameIt': 'Acuagoblin',
        'speciesNameEn': 'Acuagoblin',
        'generationSide': variant.side,
        'naturalAttitude': variant.attitude,
        'precisionBodyParts': _acuagoblinAnatomy,
      },
      classificationTags: [variant.it],
      skillIds: const [
        oculumAcuagoblinDodgeSkill,
        oculumAcuagoblinWaterJetSkill,
      ],
      dropIds: const [],
    ),
];

final _acuagoblinTechniques = <String, MonsterConcreteTechnique>{
  oculumAcuagoblinDodgeSkill: MonsterConcreteTechnique(
    name: 'Guizzo',
    action: 'Dopo una difesa riuscita puoi spostarti fino a 3 metri in acqua',
    element: 'acqua',
    kind: 'difesa',
    requiredLevel: 0,
    costResource: 'materia',
    minimums: const [1, 2, 3],
    maximums: const [1, 2, 3],
    cooldownValues: const [2, 2, 2],
    forms: List.filled(3, const [
      MonsterTechniqueEffect(
        'planar',
        '3',
        target: oculumAcuagoblinDodgeEffect,
        duration: '1',
      ),
    ]),
  ),
  oculumAcuagoblinWaterJetSkill: MonsterConcreteTechnique(
    name: 'Getto d’Acqua',
    action:
        'Attacchi un avversario con un getto d’Acqua. Un critico riuscito lo rallenta per 1 turno',
    element: 'acqua',
    kind: 'attacco',
    requiredLevel: 0,
    costResource: 'materia',
    minimums: const [1, 2, 3],
    maximums: const [1, 2, 3],
    cooldownValues: const [2, 2, 3],
    forms: [
      for (final damage in [3, 6, 9])
        [
          MonsterTechniqueEffect(
            'danno',
            '$damage',
            mode: 'prossima_azione',
            recipient: 'nemico',
          ),
          const MonsterTechniqueEffect(
            'stato',
            '1',
            target: 'rallentato',
            mode: 'prossima_azione',
            recipient: 'nemico',
            criticalOnly: true,
          ),
        ],
    ],
  ),
};
