part of 'monster_book.dart';

const oculumOblyvuardId = 'oblyvuard';
const oculumOblyvuardTreePart = 'oblyvuard_black_tree';
const oculumOblyvuardSilentThreshold = 'oblyvuard_soglia_muta';
const oculumOblyvuardOblivionSlash = 'oblyvuard_fendente_oblio';

const _oblyvuardMonster = MonsterBookEntry(
  id: oculumOblyvuardId,
  nameIt: 'Oblyvuard',
  nameEn: 'Oblyvuard',
  descIt:
      'Un’armatura vuota animata dall’albero nero alle sue spalle. '
      'Impugna una spada e uno scudo fra le radici. L’albero ha venature '
      'bianche e ferirlo fa infuriare il guardiano.',
  descEn:
      'A hollow suit of armour animated by the black tree behind it. '
      'It wields a sword and shield among the roots. The tree has white '
      'veins, and injuring it enrages the guardian.',
  elementId: 'oblio',
  planeIds: ['oblio'],
  spriteAssetPath: '',
  isMiniBoss: false,
  isBoss: false,
  isNullFateless: false,
  weakPointIt: 'L’albero nero che anima l’armatura è colpibile.',
  weakPointEn: 'The black tree animating the armour can be targeted.',
  stats: {'level': 0, 'resilienza': 8, 'volonta': 7, 'materia': 7, 'oculum': 5},
  canWieldWeapons: true,
  skillIds: [oculumOblyvuardSilentThreshold, oculumOblyvuardOblivionSlash],
  encounterRules: {
    'authoredCanonical': true,
    'hasAnatomicalWeakPoint': false,
    'precisionBodyParts': [
      {
        'id': 'body',
        'group': 'body',
        'label': 'Busto dell’armatura',
        'material': 'metal',
      },
      {
        'id': 'head',
        'group': 'head',
        'label': 'Elmo vuoto',
        'material': 'metal',
      },
      {
        'id': 'arms_1',
        'group': 'arms',
        'label': 'Braccio destro',
        'material': 'metal',
        'side': 'right',
      },
      {
        'id': 'arms_2',
        'group': 'arms',
        'label': 'Braccio sinistro',
        'material': 'metal',
        'side': 'left',
      },
      {
        'id': 'legs_1',
        'group': 'legs',
        'label': 'Gamba destra',
        'material': 'metal',
        'side': 'right',
      },
      {
        'id': 'legs_2',
        'group': 'legs',
        'label': 'Gamba sinistra',
        'material': 'metal',
        'side': 'left',
      },
      {
        'id': oculumOblyvuardTreePart,
        'group': 'tree',
        'label': 'Albero nero',
        'material': 'wood',
      },
    ],
  },
);

const _oblyvuardThresholdEffects = [
  MonsterTechniqueEffect('planar', '4', target: oculumOblyvuardSilentThreshold),
];

const _oblyvuardSlashEffects = [
  MonsterTechniqueEffect(
    'planar',
    '0',
    target: oculumOblyvuardOblivionSlash,
    mode: 'prossima_azione',
    recipient: 'nemico',
    criticalOnly: true,
  ),
];

const _oblyvuardTechniques = <String, MonsterConcreteTechnique>{
  oculumOblyvuardSilentThreshold: MonsterConcreteTechnique(
    name: 'Soglia muta',
    action:
        'Quando para vicino alle radici dell’albero nero, il guardiano '
        'aggiunge +4 CM al tiro. Risoluzione manuale del Master',
    element: 'oblio',
    kind: 'difesa',
    requiredLevel: 0,
    costResource: 'nessuna',
    minimums: [0, 0, 0],
    maximums: [0, 0, 0],
    cooldownValues: [0, 0, 0],
    costDescription: 'Costo e recupero da definire.',
    forms: [
      _oblyvuardThresholdEffects,
      _oblyvuardThresholdEffects,
      _oblyvuardThresholdEffects,
    ],
  ),
  oculumOblyvuardOblivionSlash: MonsterConcreteTechnique(
    name: 'Fendente dell’Oblio',
    action:
        'Colpisce con Danni d’Oblio. Su un critico riuscito ostacola '
        'il prossimo tiro di Memoria del bersaglio. Risoluzione manuale del Master',
    element: 'oblio',
    kind: 'attacco',
    requiredLevel: 0,
    costResource: 'nessuna',
    minimums: [0, 0, 0],
    maximums: [0, 0, 0],
    cooldownValues: [0, 0, 0],
    costDescription: 'Costo e recupero da definire.',
    forms: [
      _oblyvuardSlashEffects,
      _oblyvuardSlashEffects,
      _oblyvuardSlashEffects,
    ],
  ),
};
