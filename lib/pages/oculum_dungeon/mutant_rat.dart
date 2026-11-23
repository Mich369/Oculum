part of 'monster_book.dart';

const _mutantRatEntries = <MonsterBookEntry>[
  MonsterBookEntry(
    id: oculumMutantRatId,
    nameIt: 'Topo Mutante',
    nameEn: 'Mutant Rat',
    descIt:
        'Un ratto bipede e ricurvo, con due occhi verdi, due braccia, due gambe, due orecchie e una lunga coda. Quando è minacciato richiama topolini dagli occhi verdi.',
    descEn:
        'A hunched bipedal rat with two green eyes, two arms, two legs, two ears and a long tail. When threatened, it calls green-eyed rat pups.',
    elementId: 'fisico',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {
      'level': 0,
      'resilienza': 5,
      'volonta': 4,
      'materia': 5,
      'oculum': 7,
    },
    encounterRules: {'authoredCanonical': true},
    skillIds: [oculumMutantRatSummon],
    dropIds: [],
  ),
];

final _mutantRatTechniques = <String, MonsterConcreteTechnique>{
  oculumMutantRatSummon: MonsterConcreteTechnique(
    name: 'Richiamo dalla grata',
    action:
        'Spendi un’Azione per evocare 1d4, 1d6 + 1 o 1d9 + 3 topolini secondo la forma. Hanno 1 Vita e al proprio turno usano la sola Reazione per mordere prima di sparire',
    element: 'fisico',
    kind: 'richiamo',
    requiredLevel: 0,
    minimums: const [3, 5, 7],
    maximums: const [3, 5, 7],
    cooldownValues: const [4, 4, 4],
    forms: [
      for (final count in oculumMutantRatPupCountFormulas)
        [
          MonsterTechniqueEffect(
            'evocazione',
            count,
            target: oculumMutantRatSummon,
            mode: 'immediato',
          ),
        ],
    ],
  ),
};
