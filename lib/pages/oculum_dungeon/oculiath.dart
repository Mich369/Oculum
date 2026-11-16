part of 'monster_book.dart';

const _baseOculiath = MonsterBookEntry(
  id: oculumOculiathId,
  nameIt: 'Oculiath',
  nameEn: 'Oculiath',
  descIt:
      'Un unico occhio sospeso tra due ali membranose. Vola e attacca soltanto con il suo raggio. Con il suo unico uncino ventrale può afferrare entità con Volontà inferiore alla propria e portarle in volo.',
  descEn:
      'One eye between two membranous wings. It flies and attacks only with its ray. Its single ventral hook can grab entities with lower Will and carry them in flight.',
  elementId: 'oculum',
  spriteAssetPath: '',
  isMiniBoss: false,
  isBoss: false,
  isNullFateless: false,
  weakPointIt: 'Nessun punto debole anatomico confermato.',
  weakPointEn: 'No confirmed anatomical weak point.',
  stats: {'oculum': 4, 'oculumArt': 1},
  skillIds: [oculumOculiathRayRule],
  encounterRules: {
    'naturalFlight': true,
    'hasAnatomicalWeakPoint': false,
    'precisionBodyParts': [
      {'id': 'body', 'group': 'body', 'label': 'Corpo', 'penalty': 0},
      {'id': 'eyes_1', 'group': 'eyes', 'label': 'Occhio', 'penalty': 3},
      {
        'id': 'wings_1',
        'group': 'wings',
        'label': 'Ala sinistra',
        'penalty': 3,
        'side': 'left',
      },
      {
        'id': 'wings_2',
        'group': 'wings',
        'label': 'Ala destra',
        'penalty': 3,
        'side': 'right',
      },
      {'id': 'hook', 'group': 'arms', 'label': 'Uncino ventrale', 'penalty': 3},
    ],
  },
);

final _oculiathEntries = [
  _baseOculiath,
  _baseOculiath.copyWith(
    id: oculumLesserOculiathId,
    nameIt: 'Oculiath minore',
    nameEn: 'Lesser Oculiath',
    descIt:
        'Oculiath dal guscio minuto, con iride rossa e due ali membranose verdi. Il raggio è più debole ma conserva la gittata. L’unico uncino ventrale può afferrare e sostenere un bersaglio in volo.',
    descEn:
        'A small-shelled Oculiath with a red iris and two green membranous wings. Its ray is weaker at the same range. Its single ventral hook lets it grab and carry a target in flight.',
    skillIds: const [oculumLesserOculiathRayTechnique],
  ),
  MonsterBookEntry(
    id: oculumGreaterOculiathId,
    nameIt: 'Oculiath Maggiore',
    nameEn: 'Greater Oculiath',
    descIt:
        'Carapace avorio levitante senza ali o arti. L’occhio maggiore emette il raggio principale. Ognuno dei quattro minori emette un raggio. Quando un occhio viene distrutto, il Maggiore perde soltanto il raggio corrispondente.',
    descEn:
        'A levitating ivory carapace without wings or limbs. The large eye fires the main ray. Each of the four smaller eyes fires one ray. Destroying an eye disables its own ray.',
    elementId: 'oculum',
    spriteAssetPath: '',
    isMiniBoss: true,
    isBoss: false,
    isNullFateless: false,
    weakPointIt: 'Nessun punto debole anatomico confermato.',
    weakPointEn: 'No confirmed anatomical weak point.',
    stats: {'oculum': 8, 'oculumArt': 1},
    skillIds: [oculumGreaterOculiathRayRule],
    encounterRules: {
      'naturalFlight': true,
      'levitationWithoutFall': true,
      'hasAnatomicalWeakPoint': false,
      'precisionBodyParts': [
        {'id': 'body', 'group': 'body', 'label': 'Carapace', 'penalty': 0},
        {
          'id': 'eyes_1',
          'group': 'eyes',
          'label': 'Occhio principale',
          'penalty': 3,
        },
        {
          'id': 'eyes_2',
          'group': 'eyes',
          'label': 'Occhio minore 1',
          'penalty': 3,
        },
        {
          'id': 'eyes_3',
          'group': 'eyes',
          'label': 'Occhio minore 2',
          'penalty': 3,
        },
        {
          'id': 'eyes_4',
          'group': 'eyes',
          'label': 'Occhio minore 3',
          'penalty': 3,
        },
        {
          'id': 'eyes_5',
          'group': 'eyes',
          'label': 'Occhio minore 4',
          'penalty': 3,
        },
      ],
    },
  ),
];

final _oculiathTechniques = {
  oculumOculiathRayRule: _oculiathRayTechnique(oculumOculiathRayBonuses),
  oculumLesserOculiathRayTechnique: _oculiathRayTechnique(
    oculumLesserOculiathRayBonuses,
  ),
  oculumGreaterOculiathRayRule: _oculiathRayTechnique(
    oculumGreaterOculiathRayBonuses,
    greater: true,
  ),
};

MonsterConcreteTechnique _oculiathRayTechnique(
  List<int> damageBonuses, {
  bool greater = false,
}) {
  return MonsterConcreteTechnique(
    name: greater ? 'Cinque raggi oculari' : 'Raggio oculare',
    action: greater
        ? 'Raggio principale e quattro raggi secondari indipendenti. Gittata 16/25/30 m; secondari −10%/−6%/−3% dei Danni del principale secondo la forma'
        : 'Un raggio contro un bersaglio, a 16/25/30 m secondo la forma',
    element: 'oculum',
    kind: 'attacco',
    requiredLevel: 0,
    minimums: greater ? const [3, 5, 8] : const [1, 2, 3],
    maximums: greater ? const [3, 5, 8] : const [1, 2, 3],
    cooldownValues: const [0, 0, 0],
    forms: [
      for (var form = 0; form < 3; form++)
        [
          MonsterTechniqueEffect(
            'danno',
            '${damageBonuses[form]}',
            target: oculumOculiathRayDamageRule,
            mode: 'immediato',
            recipient: 'nemico',
          ),
          MonsterTechniqueEffect(
            'planar',
            '${oculumOculiathRayRanges[form]}',
            target: greater
                ? oculumGreaterOculiathRayRule
                : oculumOculiathRayRule,
            duration: greater
                ? '${oculumOculiathSecondaryReduction[form]}'
                : '0',
            recipient: 'nemico',
            maximumTargets: greater ? 1 + oculumOculiathSecondaryRayCount : 1,
          ),
        ],
    ],
  );
}
