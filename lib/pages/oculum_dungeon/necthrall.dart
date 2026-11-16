part of 'monster_book.dart';

const oculumNecthrallId = 'marionettista_boss';
const oculumNecthrallSpindle = 'necthrall_spindle';
const oculumNecthrallBind = 'necthrall_bind';
const oculumNecthrallDefaultDt = 18;
const oculumNecthrallDefaultDefenseCm = 3;

const _necthrallMonster = MonsterBookEntry(
  id: oculumNecthrallId,
  nameIt: 'Necthrall',
  nameEn: 'Necthrall',
  descIt:
      'Marionettista spirituale dalla maschera di legno e dalle mani '
      'articolate. Tende i fili del fuso per controllare un nemico. In '
      'difesa può spendere la Reazione del controllato per avere +3 CM. '
      'Rompere il fuso libera il bersaglio subito.',
  descEn:
      'A Spirit puppeteer with a wooden mask and articulated hands. She '
      'draws threads from her spindle to control an enemy. While defending '
      'she can spend the controlled enemy’s Reaction for +3 CM. Breaking '
      'the spindle immediately frees the target.',
  elementId: 'spirituale',
  spriteAssetPath: '',
  isMiniBoss: false,
  isBoss: true,
  isNullFateless: false,
  stats: {'resilienza': 24, 'volonta': 20, 'materia': 14, 'oculum': 22},
  weakPointIt: 'Il fuso alla cintura, che tiene tesi i fili spirituali.',
  weakPointEn: 'The spindle on her belt that keeps the spirit threads taut.',
  skillIds: [oculumNecthrallBind],
  encounterRules: {
    'authoredCanonical': true,
    'speciesNameIt': 'Marionettista',
    'speciesNameEn': 'Puppeteer',
    'necthrallControlDt': oculumNecthrallDefaultDt,
    'necthrallDefenseCm': oculumNecthrallDefaultDefenseCm,
    'precisionBodyParts': [
      {'id': 'body', 'group': 'body', 'label': 'Torace'},
      {'id': 'head', 'group': 'head', 'label': 'Testa con maschera'},
      {'id': 'arms_1', 'group': 'arms', 'label': 'Braccio destro', 'side': 'right'},
      {'id': 'arms_2', 'group': 'arms', 'label': 'Braccio sinistro', 'side': 'left'},
      {'id': 'legs_1', 'group': 'legs', 'label': 'Gamba destra', 'side': 'right'},
      {'id': 'legs_2', 'group': 'legs', 'label': 'Gamba sinistra', 'side': 'left'},
      {
        'id': oculumNecthrallSpindle,
        'group': 'spindle',
        'label': 'Fuso dei fili',
        'weak': false,
      },
    ],
  },
);

const _necthrallBindingEffects = [
  MonsterTechniqueEffect('planar', '0', target: oculumNecthrallBind),
];

const _necthrallTechniques = <String, MonsterConcreteTechnique>{
  oculumNecthrallBind: MonsterConcreteTechnique(
    name: 'Necthbind',
    action:
        'Spendi un’Azione. Il nemico può resistere con Volontà contro la DT '
        'del Boss. Se fallisce, lo controlli fino al prossimo turno '
        'personale o finché viene rotto il fuso',
    element: 'spirituale',
    kind: 'controllo',
    requiredLevel: 0,
    costResource: 'nessuna',
    minimums: [0, 0, 0],
    maximums: [0, 0, 0],
    cooldownValues: [0, 0, 0],
    costDescription: 'Un’Azione.',
    forms: [
      _necthrallBindingEffects,
      _necthrallBindingEffects,
      _necthrallBindingEffects,
    ],
  ),
};
