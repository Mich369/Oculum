part of 'monster_book.dart';

const oculumCynervailId = 'cynervail';
const oculumCynervailVeil = 'cynervail_velo_incenso';
const oculumCynervailSeal = 'cynervail_sigillo';
const oculumCynervailLantern = 'cynervail_lantern';

bool oculumCynervailLanternDestroyed(Map anatomy) {
  final parts = anatomy['parts'];
  final lantern = parts is Map ? parts[oculumCynervailLantern] : null;
  if (lantern is! Map) return false;
  final maximum = num.tryParse('${lantern['maximumHp']}');
  final damage = num.tryParse('${lantern['damageTaken']}');
  return maximum != null && maximum > 0 && damage != null && damage >= maximum;
}

const _cynervailMonster = MonsterBookEntry(
  id: oculumCynervailId,
  nameIt: 'Cynervail',
  nameEn: 'Cynervail',
  descIt:
      'Spettro di cenere dell’elemento Spirituale. Una maschera di porcellana '
      'gli copre il volto. Porta una lanterna quadrata che usa come incensiere. '
      'In Fight è Immateriale per 3 turni personali, poi recupera per 1d3 '
      'turni e torna Immateriale. La lanterna resta materiale. Se viene '
      'infranta, Cynervail torna materiale e non può riprendere il ciclo.',
  descEn:
      'A Spirit-element ash spectre. A porcelain mask covers its face. '
      'It carries a square lantern used as a censer. In a Fight it is '
      'Immaterial for 3 personal turns and automatically returns to that '
      'state after a 1d3-turn cooldown. Its lantern stays material. Breaking '
      'it ends the cycle.',
  elementId: 'spirituale',
  spriteAssetPath: '',
  isMiniBoss: false,
  isBoss: false,
  isNullFateless: false,
  skillIds: [oculumCynervailVeil, oculumCynervailSeal],
  encounterRules: {
    'precisionBodyParts': [
      {'id': 'body', 'group': 'body', 'label': 'Corpo', 'material': 'spectral'},
      {
        'id': oculumCynervailLantern,
        'group': 'lantern',
        'label': 'Lanterna',
        'material': 'metal',
      },
    ],
  },
);

const _cynervailTechniques = <String, MonsterConcreteTechnique>{
  oculumCynervailVeil: MonsterConcreteTechnique(
    name: 'Velo d’incenso',
    action:
        'Il fumo ostacola il prossimo attacco a distanza. '
        'Risoluzione manuale del Master',
    element: 'spirituale',
    kind: 'controllo',
    requiredLevel: 0,
    costResource: 'nessuna',
    minimums: [0, 0, 0],
    maximums: [0, 0, 0],
    cooldownValues: [0, 0, 0],
    costDescription: 'Costo e recupero da definire.',
    forms: [
      _cynervailVeilEffects,
      _cynervailVeilEffects,
      _cynervailVeilEffects,
    ],
  ),
  oculumCynervailSeal: MonsterConcreteTechnique(
    name: 'Sigillo di cenere',
    action:
        'Marca il bersaglio per il prossimo colpo di un alleato. '
        'Risoluzione manuale del Master',
    element: 'spirituale',
    kind: 'controllo',
    requiredLevel: 0,
    costResource: 'nessuna',
    minimums: [0, 0, 0],
    maximums: [0, 0, 0],
    cooldownValues: [0, 0, 0],
    costDescription: 'Costo e recupero da definire.',
    forms: [
      _cynervailSealEffects,
      _cynervailSealEffects,
      _cynervailSealEffects,
    ],
  ),
};

// Preserve an editable descriptor without queuing it as an automatic attack.
const _cynervailVeilEffects = [
  MonsterTechniqueEffect('planar', '0', target: oculumCynervailVeil),
];
const _cynervailSealEffects = [
  MonsterTechniqueEffect('planar', '0', target: oculumCynervailSeal),
];
