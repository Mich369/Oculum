part of 'monster_book.dart';

final _solarObserverAndBiterEntries = <MonsterBookEntry>[
  _authoredPlanar(
    'sanguifang',
    'Sanguifang Errante',
    ['sotterraneo', 'mezzano'],
    'fisico',
    'Un predatore alato dalla pelle verde oliva. Un occhio nero a iride rossa '
        'sporge dalla corazza del capo. Piomba con le membrane viola tese e '
        'si rimargina a ogni morso riuscito.',
    'L’occhio singolo, protetto dalle scaglie sopra la mascella.',
    [5, 8, 5, 0],
    0,
    false,
    false,
    ['sanguifang_morso'],
    const {
      'authoredCanonical': true,
      'naturalFlight': true,
      'wingCount': 2,
      'signatureSkillId': 'sanguifang_morso',
    },
    const {},
  ).copyWith(classificationTags: const ['Errante']),
  _solgazeMonster,
  _solgazeMonster.copyWith(
    id: 'solgaze_variante_muschiosa',
    nameIt: 'Solgheiz del Santuario Allagato',
    nameEn: 'Solgheiz of the Flooded Shrine',
    descIt:
        'Un Solgheiz dalle ali verdi e dal guscio di bronzo coperto di muschio. Il disco solare si riflette nell’acqua del santuario.',
    descEn:
        'A green-winged Solgheiz with moss-covered bronze plates. Its solar disk reflects off the water of its shrine.',
  ),
];

final _solgazeMonster = _authoredPlanar(
  'solgaze',
  'Solgaze · Osservatore del Sole',
  ['sacro', 'mezzano'],
  'solare',
  'Un occhio d’ambra tra piastre di bronzo, con un disco solare sospeso '
      'tra le due ali. Fissa la stessa preda fino a immobilizzarla nell’oro.',
  'L’occhio esposto quando il disco solare si accende.',
  [7, 9, 5, 8],
  0,
  false,
  false,
  ['solgaze_sguardo'],
  const {
    'authoredCanonical': true,
    'naturalFlight': true,
    'wingCount': 2,
    'celestialIdentity': 'solare',
    'signatureSkillId': 'solgaze_sguardo',
    'precisionBodyParts': [
      {
        'id': 'body',
        'group': 'body',
        'label': 'Corpo',
        'penalty': 0,
        'material': 'metal',
      },
      {
        'id': 'eyes',
        'group': 'eyes',
        'label': 'Occhio d’ambra',
        'penalty': 0,
        'weak': true,
      },
      {
        'id': 'wings_1',
        'group': 'wings',
        'label': 'Ala destra',
        'penalty': 0,
        'side': 'right',
      },
      {
        'id': 'wings_2',
        'group': 'wings',
        'label': 'Ala sinistra',
        'penalty': 0,
        'side': 'left',
      },
    ],
  },
  const {},
);

const _solarObserverAndBiterTechniques = <String, MonsterConcreteTechnique>{
  'sanguifang_morso': MonsterConcreteTechnique(
    name: 'Morso dell’Errante',
    action:
        'Dopo un morso riuscito recupera Vita pari al 15% dei suoi '
        'Danni totali. Se il colpo è critico applica Sanguinamento',
    element: 'fisico',
    kind: 'danno',
    requiredLevel: 0,
    costResource: 'nessuna',
    minimums: [0, 0, 0],
    maximums: [0, 0, 0],
    cooldownValues: [0, 0, 0],
    forms: [
      [
        MonsterTechniqueEffect(
          'planar',
          '15',
          target: 'sanguifang_morso',
          recipient: 'nemico',
          maximumTargets: 1,
        ),
      ],
      [
        MonsterTechniqueEffect(
          'planar',
          '15',
          target: 'sanguifang_morso',
          recipient: 'nemico',
          maximumTargets: 1,
        ),
      ],
      [
        MonsterTechniqueEffect(
          'planar',
          '15',
          target: 'sanguifang_morso',
          recipient: 'nemico',
          maximumTargets: 1,
        ),
      ],
    ],
  ),
  'solgaze_sguardo': MonsterConcreteTechnique(
    name: 'Sguardo del Disco Solare',
    action:
        'Il terzo colpo riuscito sullo stesso bersaglio nel Fight o '
        'un doppio critico lo trasforma in oro per tre turni. Si può '
        'liberare con Forza, Controllo corporeo o Volontà, spendendo '
        'un’Azione o una Reazione contro DT 10 + livello + 2 × Grado',
    element: 'solare',
    kind: 'danno',
    requiredLevel: 0,
    minimums: [1, 2, 3],
    maximums: [1, 2, 3],
    cooldownValues: [1, 1, 1],
    forms: [
      [
        MonsterTechniqueEffect(
          'danno',
          '4',
          mode: 'prossima_azione',
          duration: '',
        ),
      ],
      [
        MonsterTechniqueEffect(
          'danno',
          '8',
          mode: 'prossima_azione',
          duration: '',
        ),
      ],
      [
        MonsterTechniqueEffect(
          'danno',
          '12',
          mode: 'prossima_azione',
          duration: '',
        ),
      ],
    ],
  ),
};
