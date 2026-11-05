part of 'monster_book.dart';

const _idraxStats = {'hp': 70, 'atk': 16, 'def': 9, 'spd': 17};
const _idraxSkillIds = ['idrax_molt', 'serpent_coil', 'burrow_escape'];
const _idraxDropIds = ['pelle_serpente', 'carne_idrax'];
const _idraxPrecisionBodyParts = [
  {'id': 'body', 'label': 'Corpo', 'group': 'body', 'weak': false},
  {'id': 'head', 'label': 'Testa', 'group': 'head', 'weak': false},
  {'id': 'eyes_1', 'label': 'Occhio destro', 'group': 'eyes', 'weak': false},
  {'id': 'eyes_2', 'label': 'Occhio sinistro', 'group': 'eyes', 'weak': false},
  {'id': 'throat', 'label': 'Gola', 'group': 'neck', 'weak': true},
  {'id': 'tail', 'label': 'Coda', 'group': 'tail', 'weak': false},
];

const _glacialIdrax = MonsterBookEntry(
  id: 'idrax_glaciale',
  nameIt: 'Idrax Glaciale',
  nameEn: 'Glacial Idrax',
  descIt:
      'Variante delle Terre di ghiaccio dell’Idrax: un lungo serpente senza arti, '
      'dalle scaglie perlacee e dalla cresta di ghiaccio lungo il capo e la nuca. '
      'Si avvolge in spire fra i crepacci e ricorre a Muta, protezione e fuga '
      'come l’Idrax comune.',
  descEn:
      'A long, limbless Idrax from the Ice Lands, with pearly scales and a crest '
      'of ice. It coils, sheds its skin and escapes like the common Idrax.',
  elementId: 'ghiaccio',
  planeIds: ['ghiaccio'],
  spriteAssetPath: '',
  isMiniBoss: false,
  isBoss: false,
  isNullFateless: false,
  stats: _idraxStats,
  weakPointIt:
      'Le scaglie più sottili sotto la gola, esposte quando solleva il capo.',
  skillIds: _idraxSkillIds,
  dropIds: _idraxDropIds,
  damageResistancePresets: {'ghiaccio': 'resistenza'},
  encounterRules: {
    'authoredCanonical': true,
    'canonicalVariantOf': 'idrax',
    'precisionBodyParts': _idraxPrecisionBodyParts,
  },
  classificationTags: ['Bestia', 'Rettile', 'Serpente'],
);

final _iceCreatureEntries = <MonsterBookEntry>[
  _iceCreature(
    'costrutto_dei_tre_crani',
    'Costrutto dei Tre Crani',
    'Three-Skull Construct',
    'Costrutto bipede curvo di ghiaccio opaco e ferro incastrato. Tre calchi ossei incassati nel torace sporgono sotto una cresta spezzata. Una testa bassa sovrasta il torace e i due avambracci lunghi raschiano il suolo. Nei passaggi stretti sbarra la via con il proprio peso.',
    'Il giunto del collo sotto la cresta, scoperto quando solleva gli avambracci.',
    5,
    [8, 5, 7, 0],
    'Costrutto',
    'crystal',
    ('neck', 'Giunto del collo', 'joint'),
    ['ice_three_skull_sweep', 'ice_three_skull_brace'],
  ),
  _iceCreature(
    'scheletro_delle_lame_di_brina',
    'Scheletro delle Lame di Brina',
    'Rimeblade Skeleton',
    'Scheletro alto con due braccia, due gambe e costole esposte sotto un pettorale asimmetrico. Il ghiaccio fascia le mani che stringono due lame, una stretta e una più larga. Tra le rovine avanza di lato e cerca un varco con un fendente incrociato.',
    'Le costole esposte sotto il lato corto del pettorale.',
    3,
    [4, 5, 5, 0],
    'Non morto',
    'bone',
    ('ribs', 'Costole esposte', 'torso'),
    ['ice_rimeblade_cut', 'ice_rimeblade_parry'],
    weapons: ['lame di brina'],
  ),
  _iceCreature(
    'cacciatore_della_cresta_glaciale',
    'Cacciatore della Cresta Glaciale',
    'Glacial Crest Hunter',
    'Cacciatore bipede dal muso lupino, con due occhi, braccia artigliate e gambe robuste. Una cresta diseguale di ghiaccio lattiginoso si alza sul dorso sopra il pelo grigio cenere. Sui pendii si abbassa fra le rocce e si lancia di sbieco contro chi resta isolato.',
    'La gola sotto la mandibola, dove il pelo si dirada.',
    4,
    [5, 7, 4, 0],
    'Bestia',
    'flesh',
    ('throat', 'Gola sotto la mandibola', 'neck'),
    ['ice_crest_pounce', 'ice_crest_retreat'],
    eyes: true,
  ),
  _iceCreature(
    'arciere_del_gelo_cavo',
    'Arciere del Gelo Cavo',
    'Hollow Frost Archer',
    'Arciere umanoide con due braccia, due gambe, maschera chiusa e mantello scuro irrigidito dalla brina. L’arco, lungo e asimmetrico, ha un’anima scura rivestita di ghiaccio. Vigila sulle strettoie e scocca dalla distanza, abbassandosi dietro la pietra dopo il tiro.',
    'Il polso che tende la corda, scoperto all’allungo.',
    4,
    [4, 7, 5, 0],
    'Umanoide',
    'flesh',
    ('drawing_wrist', 'Polso di trazione', 'joint'),
    ['ice_hollow_bow_shot', 'ice_hollow_bow_cover'],
    weapons: ['arco del gelo cavo'],
  ),
  _iceCreature(
    'gigante_della_clava_polarnotte',
    'Gigante della Clava Polarnotte',
    'Polar Night Club Giant',
    'Gigante bipede dal busto largo, con due braccia robuste, due occhi e una corta barba di brina. Porta un pesante tronco di larice con una testa di ghiaccio nero. Fa leva sui piedi larghi per far scendere la clava da un lato, anche quando il terreno cede.',
    'Il ginocchio anteriore, dove la fascia lascia libera la piega.',
    6,
    [10, 6, 8, 0],
    'Gigante',
    'flesh',
    ('forward_knee', 'Ginocchio anteriore', 'joint'),
    ['ice_polar_club_crush', 'ice_polar_club_stance'],
    eyes: true,
    weapons: ['clava polarnotte'],
  ),
  _iceCreature(
    'ice_shield',
    'Ice Shield',
    'Ice Shield',
    'Guardiano bipede massiccio di ghiaccio sfaccettato. Il volto è incassato fra due spalle alte; due braccia terminano in pugni di cristallo. Su un avambraccio le lastre si sovrappongono fino a formare una paratia naturale. Occupa il centro dei valichi e alterna urti brevi a una guardia frontale.',
    'La giuntura del gomito dell’avambraccio a paratia, scoperta quando alza la guardia.',
    7,
    [11, 7, 9, 0],
    'Guardiano',
    'crystal',
    ('shield_elbow', 'Gomito dietro la paratia', 'joint'),
    ['ice_shield_ram', 'ice_shield_plates'],
  ),
];

MonsterBookEntry _iceCreature(
  String id,
  String name,
  String englishName,
  String look,
  String weakPoint,
  int level,
  List<int> stats,
  String classification,
  String material,
  (String, String, String) weakPart,
  List<String> skills, {
  bool eyes = false,
  List<String> weapons = const [],
}) =>
    _authoredPlanar(
      id,
      name,
      ['ghiaccio'],
      'ghiaccio',
      look,
      weakPoint,
      stats,
      level,
      false,
      false,
      skills,
      {
        'authoredCanonical': true,
        'dispositions': ['ostile'],
        'precisionBodyParts': [
          for (final (partId, label, group) in [
            ('body', 'Corpo', 'body'),
            ('head', 'Testa', 'head'),
            ('arms_1', 'Braccio destro', 'arms'),
            ('arms_2', 'Braccio sinistro', 'arms'),
            ('legs_1', 'Gamba destra', 'legs'),
            ('legs_2', 'Gamba sinistra', 'legs'),
            if (eyes) ...[
              ('eyes_1', 'Occhio destro', 'eyes'),
              ('eyes_2', 'Occhio sinistro', 'eyes'),
            ],
            weakPart,
          ])
            {
              'id': partId,
              'label': label,
              'group': group,
              'material': material,
              'weak': partId == weakPart.$1,
            },
        ],
      },
      {'ghiaccio': 'resistenza'},
    ).copyWith(
      nameEn: englishName,
      classificationTags: [classification, 'Bipede'],
      canWieldWeapons: weapons.isNotEmpty,
      weaponTags: weapons,
    );

final _iceCreatureTechniques = <String, MonsterConcreteTechnique>{
  'ice_three_skull_sweep': _canonicalAttack(
    'Spazzata dei Tre Crani',
    'Trascina il lungo avambraccio e lo abbatte contro un solo bersaglio.',
    'contundente',
    [5, 8, 12],
  ),
  'ice_three_skull_brace': _canonicalProtection(
    'Cerniera del valico',
    'Punta gli avambracci a terra e si irrigidisce in una guardia bassa.',
    'difesa',
    [4, 6, 8],
  ),
  'ice_rimeblade_cut': _canonicalAttack(
    'Fendente incrociato di brina',
    'Chiude entrambe le lame sullo stesso bersaglio con un singolo tiro di attacco.',
    'ghiaccio',
    [4, 7, 10],
  ),
  'ice_rimeblade_parry': _canonicalProtection(
    'Parata a forbice',
    'Incrocia le lame per coprire le costole.',
    'difesa',
    [2, 4, 6],
  ),
  'ice_crest_pounce': _canonicalAttack(
    'Balzo di cresta',
    'Scatta dal fianco e tenta un colpo d’artiglio contro un solo bersaglio.',
    'ghiaccio',
    [5, 8, 11],
  ),
  'ice_crest_retreat': _canonicalProtection(
    'Schermatura di cresta',
    'Si rannicchia dietro la cresta per prepararsi alla risposta.',
    'difesa',
    [3, 5, 7],
  ),
  'ice_hollow_bow_shot': _canonicalAttack(
    'Freccia del Gelo Cavo',
    'Tende l’arco e scocca da lontano una sola freccia contro il bersaglio scelto.',
    'ghiaccio',
    [4, 8, 12],
  ),
  'ice_hollow_bow_cover': _canonicalProtection(
    'Guardia dell’arciere',
    'Abbassa il profilo e tiene l’arco davanti al busto.',
    'difesa',
    [2, 4, 6],
  ),
  'ice_polar_club_crush': _canonicalAttack(
    'Percossa della clava Polarnotte',
    'Fa scendere di traverso la clava contro un solo bersaglio.',
    'contundente',
    [6, 10, 14],
  ),
  'ice_polar_club_stance': _canonicalProtection(
    'Appoggio sulla clava',
    'Pianta la testa della clava a terra e assesta la propria guardia.',
    'difesa',
    [4, 6, 9],
  ),
  'ice_shield_ram': _canonicalAttack(
    'Urto della paratia',
    'Spinge l’avambraccio a lastre contro un solo bersaglio.',
    'ghiaccio',
    [6, 9, 13],
  ),
  'ice_shield_plates': _canonicalProtection(
    'Paratia di ghiaccio',
    'Serra davanti al busto le lastre dell’avambraccio e ottiene Scudo normale.',
    'scudo',
    [6, 9, 13],
  ),
};
