part of 'monster_book.dart';

/// Golden marble aberrations born from the Solar and Angelic powers. The
/// Solar variants spend their tier budget on offense; Angelic variants are
/// balanced and carry two extra level-zero stat points.
const List<MonsterBookEntry> _goldMarbleAberrationEntries = [
  MonsterBookEntry(
    id: 'aberrazione_oro_marmo_minore_solare',
    nameIt: 'Aberrazione Minore d’Oro e Marmo · Solare',
    nameEn: 'Lesser Gold-and-Marble Aberration · Solar',
    descIt:
        'Creatura d’oro e marmo plasmata dai Solari. È un glass cannon: concentra la potenza in Volontà e Oculum, ma Resilienza e Materia sono basse. Statistiche base al livello 0: RES 2, VOL 10, MAT 1, OCU 7 (20 punti).',
    descEn:
        'A gold-and-marble creature shaped by the Solars. Glass cannon: high Will and Oculum, low Resilience and Matter. Level-zero core stats: RES 2, WILL 10, MAT 1, OCU 7 (20 points).',
    elementId: 'solare',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'level': 0, 'resilienza': 2, 'volonta': 10, 'materia': 1, 'oculum': 7},
    skillIds: ['solar_swarm', 'golden_pin', 'wing_flash'],
    dropIds: ['sun_pin', 'black_gold_chip'],
    classificationTags: ['Aberrazione d’Oro e Marmo', 'Minore', 'Solare'],
  ),
  MonsterBookEntry(
    id: 'aberrazione_oro_marmo_minore_angelica',
    nameIt: 'Aberrazione Minore d’Oro e Marmo · Angelica',
    nameEn: 'Lesser Gold-and-Marble Aberration · Angelic',
    descIt:
        'Creatura d’oro e marmo creata dagli Angeli. Equilibrata, con una lieve riserva di statistiche superiore alla variante Solare. Statistiche base al livello 0: RES 6, VOL 5, MAT 6, OCU 5 (22 punti).',
    descEn:
        'A gold-and-marble creature created by Angels. Balanced, with a small stat reserve above the Solar variant. Level-zero core stats: RES 6, WILL 5, MAT 6, OCU 5 (22 points).',
    elementId: 'angelico',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'level': 0, 'resilienza': 6, 'volonta': 5, 'materia': 6, 'oculum': 5},
    skillIds: [
      'protective_angel_intercept',
      'protective_angel_wing_wall',
      'protective_angel_vow',
    ],
    dropIds: ['piuma_protettrice', 'sigillo_di_guardia'],
    classificationTags: ['Aberrazione d’Oro e Marmo', 'Minore', 'Angelica'],
  ),
  MonsterBookEntry(
    id: 'aberrazione_oro_marmo_intermedia_solare',
    nameIt: 'Aberrazione Intermedia d’Oro e Marmo · Solare',
    nameEn: 'Intermediate Gold-and-Marble Aberration · Solar',
    descIt:
        'Aberrazione solare di taglia intermedia: rapida e devastante, ma vulnerabile quando viene raggiunta. Glass cannon con 40 statistiche base al livello 0: RES 3, VOL 20, MAT 3, OCU 14.',
    descEn:
        'Intermediate Solar aberration: swift and devastating, but vulnerable when caught. Glass cannon with 40 level-zero core stats: RES 3, WILL 20, MAT 3, OCU 14.',
    elementId: 'solare',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'level': 0, 'resilienza': 3, 'volonta': 20, 'materia': 3, 'oculum': 14},
    skillIds: ['solar_swarm', 'golden_pin', 'wing_flash'],
    dropIds: ['sun_pin', 'black_gold_chip'],
    classificationTags: ['Aberrazione d’Oro e Marmo', 'Intermedia', 'Solare'],
  ),
  MonsterBookEntry(
    id: 'aberrazione_oro_marmo_intermedia_angelica',
    nameIt: 'Aberrazione Intermedia d’Oro e Marmo · Angelica',
    nameEn: 'Intermediate Gold-and-Marble Aberration · Angelic',
    descIt:
        'Aberrazione angelica d’oro e marmo, capace di sostenere il gruppo e colpire con precisione. È bilanciata e dispone di 42 statistiche base al livello 0, due più della variante Solare: RES 11, VOL 10, MAT 11, OCU 10.',
    descEn:
        'Angelic gold-and-marble aberration that can protect allies and strike precisely. Balanced, with 42 level-zero core stats, two above the Solar variant: RES 11, WILL 10, MAT 11, OCU 10.',
    elementId: 'angelico',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'level': 0, 'resilienza': 11, 'volonta': 10, 'materia': 11, 'oculum': 10},
    skillIds: [
      'protective_angel_intercept',
      'protective_angel_wing_wall',
      'protective_angel_vow',
    ],
    dropIds: ['piuma_protettrice', 'sigillo_di_guardia'],
    classificationTags: ['Aberrazione d’Oro e Marmo', 'Intermedia', 'Angelica'],
  ),
  MonsterBookEntry(
    id: 'aberrazione_oro_marmo_maggiore_solare',
    nameIt: 'Aberrazione Maggiore d’Oro e Marmo · Solare',
    nameEn: 'Greater Gold-and-Marble Aberration · Solar',
    descIt:
        'Aberrazione solare maggiore, un colosso luminoso che concentra ogni apertura in un colpo. È un glass cannon: 60 statistiche base al livello 0, RES 4, VOL 30, MAT 4, OCU 22.',
    descEn:
        'Greater Solar aberration: a radiant colossus that concentrates every opening into one strike. Glass cannon with 60 level-zero core stats: RES 4, WILL 30, MAT 4, OCU 22.',
    elementId: 'solare',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'level': 0, 'resilienza': 4, 'volonta': 30, 'materia': 4, 'oculum': 22},
    skillIds: ['solar_swarm', 'golden_pin', 'wing_flash'],
    dropIds: ['sun_pin', 'black_gold_chip'],
    classificationTags: ['Aberrazione d’Oro e Marmo', 'Maggiore', 'Solare'],
  ),
  MonsterBookEntry(
    id: 'aberrazione_oro_marmo_maggiore_angelica',
    nameIt: 'Aberrazione Maggiore d’Oro e Marmo · Angelica',
    nameEn: 'Greater Gold-and-Marble Aberration · Angelic',
    descIt:
        'Aberrazione angelica maggiore, equilibrata e dotata di una riserva di statistiche leggermente superiore al corrispettivo Solare: 62 punti base al livello 0, RES 16, VOL 15, MAT 16, OCU 15.',
    descEn:
        'Greater Angelic aberration, balanced and with a slightly larger stat reserve than its Solar counterpart: 62 level-zero core stats, RES 16, WILL 15, MAT 16, OCU 15.',
    elementId: 'angelico',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    stats: {'level': 0, 'resilienza': 16, 'volonta': 15, 'materia': 16, 'oculum': 15},
    skillIds: [
      'protective_angel_intercept',
      'protective_angel_wing_wall',
      'protective_angel_vow',
    ],
    dropIds: ['piuma_protettrice', 'sigillo_di_guardia'],
    classificationTags: ['Aberrazione d’Oro e Marmo', 'Maggiore', 'Angelica'],
  ),
];
