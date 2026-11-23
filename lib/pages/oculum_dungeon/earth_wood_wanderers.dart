part of 'monster_book.dart';

const _armouredCrustaceanLeftClaw = 'left_claw';
const _armouredCrustaceanRightClaw = 'right_claw';

bool oculumArmouredCrustaceanCanUsePincers(Map anatomy) {
  final parts = anatomy['parts'];
  if (parts is! Map) return true;
  bool isDestroyed(String id) {
    final part = parts[id];
    if (part is! Map) return false;
    final maximum = part['maximumHp'];
    final damage = part['damageTaken'];
    return maximum is num && maximum > 0 && damage is num && damage >= maximum;
  }

  return !isDestroyed(_armouredCrustaceanLeftClaw) ||
      !isDestroyed(_armouredCrustaceanRightClaw);
}

const _earthGolemAnatomy = [
  {'id': 'body', 'group': 'body', 'label': 'Corpo', 'material': 'stone'},
  {'id': 'head', 'group': 'head', 'label': 'Testa', 'material': 'stone'},
  {
    'id': 'arms_1',
    'group': 'arms',
    'label': 'Braccio destro',
    'side': 'right',
    'material': 'stone',
  },
  {
    'id': 'arms_2',
    'group': 'arms',
    'label': 'Braccio sinistro',
    'side': 'left',
    'material': 'stone',
  },
  {
    'id': 'legs_1',
    'group': 'legs',
    'label': 'Gamba destra',
    'side': 'right',
    'material': 'stone',
  },
  {
    'id': 'legs_2',
    'group': 'legs',
    'label': 'Gamba sinistra',
    'side': 'left',
    'material': 'stone',
  },
];

const _woodGolemAnatomy = [
  {'id': 'body', 'group': 'body', 'label': 'Corpo', 'material': 'wood'},
  {'id': 'head', 'group': 'head', 'label': 'Testa', 'material': 'wood'},
  {
    'id': 'arms_1',
    'group': 'arms',
    'label': 'Braccio destro',
    'side': 'right',
    'material': 'wood',
  },
  {
    'id': 'arms_2',
    'group': 'arms',
    'label': 'Braccio sinistro',
    'side': 'left',
    'material': 'wood',
  },
  {
    'id': 'legs_1',
    'group': 'legs',
    'label': 'Gamba destra',
    'side': 'right',
    'material': 'wood',
  },
  {
    'id': 'legs_2',
    'group': 'legs',
    'label': 'Gamba sinistra',
    'side': 'left',
    'material': 'wood',
  },
];

const _deathRavenAnatomy = [
  {'id': 'body', 'group': 'body', 'label': 'Corpo'},
  {'id': 'head', 'group': 'head', 'label': 'Testa'},
  {'id': 'beak', 'group': 'beak', 'label': 'Becco'},
  {
    'id': 'mask',
    'group': 'mask',
    'label': 'Maschera ossea',
    'material': 'bone',
  },
  {'id': 'legs_1', 'group': 'legs', 'label': 'Zampa destra', 'side': 'right'},
  {'id': 'legs_2', 'group': 'legs', 'label': 'Zampa sinistra', 'side': 'left'},
  {
    'id': 'wings_1',
    'group': 'wings',
    'label': 'Ala destra',
    'side': 'right',
    'weak': true,
  },
  {
    'id': 'wings_2',
    'group': 'wings',
    'label': 'Ala sinistra',
    'side': 'left',
    'weak': true,
  },
];

const _sensimossAnatomy = [
  {'id': 'body', 'group': 'body', 'label': 'Corpo'},
  {'id': 'head', 'group': 'head', 'label': 'Testa con due zanne'},
  {'id': 'eyes_1', 'group': 'eyes', 'label': 'Occhio destro', 'side': 'right'},
  {'id': 'eyes_2', 'group': 'eyes', 'label': 'Occhio sinistro', 'side': 'left'},
  {
    'id': 'ears_1',
    'group': 'ears',
    'label': 'Orecchio a foglia destro',
    'side': 'right',
  },
  {
    'id': 'ears_2',
    'group': 'ears',
    'label': 'Orecchio a foglia sinistro',
    'side': 'left',
  },
  {
    'id': 'legs_1',
    'group': 'legs',
    'label': 'Zampa anteriore destra',
    'side': 'right',
  },
  {
    'id': 'legs_2',
    'group': 'legs',
    'label': 'Zampa anteriore sinistra',
    'side': 'left',
  },
  {
    'id': 'legs_3',
    'group': 'legs',
    'label': 'Zampa posteriore destra',
    'side': 'right',
  },
  {
    'id': 'legs_4',
    'group': 'legs',
    'label': 'Zampa posteriore sinistra',
    'side': 'left',
  },
];

// Starting values for the ordinary catalogue and its editable sheet importer.
// These entries do not select an illustration or introduce a bespoke ability.
const _earthWoodWandererEntries = <MonsterBookEntry>[
  MonsterBookEntry(
    id: 'terramound',
    nameIt: 'Terramound',
    nameEn: 'Terramound',
    descIt:
        'Golem di terra umanoide con strati di argilla, pietrisco e muschio. La mazza Terramaul riprende gli strati duri e irregolari del suo corpo.',
    descEn:
        'An earth golem with layers of clay, gravel and moss. Its Terramaul echoes the hardened strata of its body.',
    elementId: 'terra',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    weakPointIt: 'Nessun punto debole anatomico confermato.',
    weakPointEn: 'No confirmed anatomical weak point.',
    encounterRules: {
      'authoredCanonical': true,
      'hasAnatomicalWeakPoint': false,
      'precisionBodyParts': [
        ..._earthGolemAnatomy,
        {'id': 'terramaul', 'group': 'weapon', 'label': 'Terramaul', 'material': 'stone', 'penalty': 3},
      ],
    },
    stats: {
      'level': 0,
      'resilienza': 9,
      'volonta': 5,
      'materia': 4,
      'oculum': 0,
    },
    canWieldWeapons: true,
    weaponTags: ['mazza', 'Terramaul'],
    skillIds: [],
    dropIds: [],
  ),
  MonsterBookEntry(
    id: 'lignobark',
    nameIt: 'Lignobark',
    nameEn: 'Lignobark',
    descIt:
        'Golem di legno umanoide fatto di quercia spaccata e radici. Lo scudo Lignoguard ha doghe scure percorse da nervature di radice.',
    descEn:
        'A wood golem of split oak and roots. Its Lignoguard shield is made of dark slats crossed by root veins.',
    elementId: 'natura',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    weakPointIt: 'Nessun punto debole anatomico confermato.',
    weakPointEn: 'No confirmed anatomical weak point.',
    encounterRules: {
      'authoredCanonical': true,
      'hasAnatomicalWeakPoint': false,
      'precisionBodyParts': _woodGolemAnatomy,
    },
    stats: {
      'level': 0,
      'resilienza': 8,
      'volonta': 5,
      'materia': 5,
      'oculum': 0,
    },
    armorTags: ['scudo ligneo', 'Lignoguard'],
    skillIds: [],
    dropIds: [],
  ),
  MonsterBookEntry(
    id: 'errante_della_forza',
    nameIt: 'Errante della Forza',
    nameEn: 'Wanderer of Strength',
    descIt:
        'Errante umanoide rosso, con criniera ispida, due braccia massicce e due gambe. Il suo maglio Fortimaul è avvolto in fibre rosse.',
    descEn:
        'A red humanoid wanderer with a bristled mane and massive arms. Its Fortimaul is wrapped in red fibres.',
    elementId: 'fisico',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    encounterRules: {'authoredCanonical': true},
    stats: {
      'level': 0,
      'resilienza': 6,
      'volonta': 11,
      'materia': 4,
      'oculum': 3,
    },
    canWieldWeapons: true,
    weaponTags: ['maglio', 'Fortimaul'],
    skillIds: [],
    dropIds: [],
  ),
  MonsterBookEntry(
    id: 'errante_della_resistenza',
    nameIt: 'Errante della Resistenza',
    nameEn: 'Wanderer of Resilience',
    descIt:
        'Errante umanoide azzurrino, con due braccia, due gambe e uno sguardo stralunato. La Durascale ripete le sue spesse lamelle azzurro pallido.',
    descEn:
        'A pale blue humanoid wanderer with a dazed gaze. Its Durascale echoes its thick blue plates.',
    elementId: 'fisico',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    encounterRules: {'authoredCanonical': true},
    stats: {
      'level': 0,
      'resilienza': 11,
      'volonta': 6,
      'materia': 4,
      'oculum': 3,
    },
    armorTags: ['armatura a lamelle', 'Durascale'],
    skillIds: [],
    dropIds: [],
  ),
  MonsterBookEntry(
    id: 'crostaceo_corazzato',
    nameIt: 'Crostaceo corazzato',
    nameEn: 'Armoured Crustacean',
    descIt:
        'Crostaceo di sei metri con otto zampe e due chele asimmetriche. '
        'Le chele riparano la testa. Il carapace stratificato è molto '
        'resistente. Lo Scutumclaw riprende la forma della chela e le sue piastre sovrapposte.',
    descEn:
        'A six-metre crustacean with eight legs, two asymmetric claws and '
        'a tough layered shell. The Scutumclaw echoes its overlapping claw plates.',
    elementId: 'acqua',
    spriteAssetPath: '',
    isMiniBoss: true,
    isBoss: false,
    isNullFateless: false,
    weakPointIt: 'La membrana verde esposta tra le piastre del dorso.',
    weakPointEn: 'The exposed green membrane between its dorsal plates.',
    encounterRules: {
      'authoredCanonical': true,
      'bodyLengthMeters': 6,
      'hasAnatomicalWeakPoint': true,
      'precisionBodyParts': [
        {
          'id': 'body',
          'group': 'body',
          'label': 'Carapace',
          'penalty': 0,
          'material': 'chitin',
        },
        {'id': 'head', 'group': 'head', 'label': 'Testa', 'penalty': 0},
        {
          'id': _armouredCrustaceanLeftClaw,
          'group': 'arms',
          'label': 'Chela sinistra',
          'penalty': 2,
          'side': 'left',
          'material': 'chitin',
        },
        {
          'id': _armouredCrustaceanRightClaw,
          'group': 'arms',
          'label': 'Chela destra',
          'penalty': 2,
          'side': 'right',
          'material': 'chitin',
        },
        {
          'id': 'legs_1',
          'group': 'legs',
          'label': 'Zampa sinistra 1',
          'side': 'left',
          'material': 'chitin',
        },
        {
          'id': 'legs_2',
          'group': 'legs',
          'label': 'Zampa destra 1',
          'side': 'right',
          'material': 'chitin',
        },
        {
          'id': 'legs_3',
          'group': 'legs',
          'label': 'Zampa sinistra 2',
          'side': 'left',
          'material': 'chitin',
        },
        {
          'id': 'legs_4',
          'group': 'legs',
          'label': 'Zampa destra 2',
          'side': 'right',
          'material': 'chitin',
        },
        {
          'id': 'legs_5',
          'group': 'legs',
          'label': 'Zampa sinistra 3',
          'side': 'left',
          'material': 'chitin',
        },
        {
          'id': 'legs_6',
          'group': 'legs',
          'label': 'Zampa destra 3',
          'side': 'right',
          'material': 'chitin',
        },
        {
          'id': 'legs_7',
          'group': 'legs',
          'label': 'Zampa sinistra 4',
          'side': 'left',
          'material': 'chitin',
        },
        {
          'id': 'legs_8',
          'group': 'legs',
          'label': 'Zampa destra 4',
          'side': 'right',
          'material': 'chitin',
        },
        {
          'id': 'dorsal_membrane',
          'group': 'body',
          'label': 'Membrana verde dorsale',
          'penalty': 5,
          'weak': true,
          'material': 'flesh',
        },
      ],
    },
    stats: {
      'level': 0,
      'resilienza': 16,
      'volonta': 8,
      'materia': 7,
      'oculum': 3,
    },
    armorTags: ['scudo a piastre', 'Scutumclaw'],
    skillIds: [],
    dropIds: [],
  ),
  MonsterBookEntry(
    id: 'corvo_della_morte',
    nameIt: 'Corvo della Morte',
    nameEn: 'Death Raven',
    descIt:
        'Corvo lunare neutrale e non aggressivo. Ha due ali, due zampe e una maschera ossea. Le penne rigide ricordano le lame da piuma dei viandanti lunari.',
    descEn:
        'A neutral, non-aggressive Lunar raven with two wings, two legs and a bone mask. Its rigid feathers resemble the feather blades of Lunar travellers.',
    elementId: 'luna',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    encounterRules: {
      'authoredCanonical': true,
      'celestialIdentity': 'lunare',
      'generationSide': 'neutral',
      'naturalAttitude': 'Neutrale e non aggressivo.',
      'naturalFlight': true,
      'wingCount': 2,
      'precisionBodyParts': _deathRavenAnatomy,
    },
    stats: {
      'level': 0,
      'resilienza': 4,
      'volonta': 4,
      'materia': 6,
      'oculum': 4,
    },
    skillIds: [],
    dropIds: [],
  ),
  MonsterBookEntry(
    id: 'corvo_della_morte_evoluto',
    nameIt: 'Corvo della Morte evoluto',
    nameEn: 'Evolved Death Raven',
    descIt:
        'Corvo lunare neutrale e non aggressivo, con due ali più ampie, due zampe, collo indaco violaceo e pochi tratti azzurri. La maschera ossea ricorda una visiera lunare.',
    descEn:
        'A neutral, non-aggressive Lunar raven with two broad wings, two legs, an indigo neck and sparse blue markings. Its bone mask resembles a Lunar visor.',
    elementId: 'luna',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    encounterRules: {
      'authoredCanonical': true,
      'speciesId': 'corvo_della_morte',
      'speciesNameIt': 'Corvo della Morte',
      'speciesNameEn': 'Death Raven',
      'celestialIdentity': 'lunare',
      'generationSide': 'neutral',
      'naturalAttitude': 'Neutrale e non aggressivo.',
      'naturalFlight': true,
      'wingCount': 2,
      'precisionBodyParts': _deathRavenAnatomy,
    },
    stats: {
      'level': 3,
      'resilienza': 6,
      'volonta': 5,
      'materia': 8,
      'oculum': 6,
    },
    skillIds: [],
    dropIds: [],
  ),
  MonsterBookEntry(
    id: 'durafur',
    nameIt: 'Durafur',
    nameEn: 'Durafur',
    descIt:
        'Mostro ricoperto da un pelo resistente ai colpi fisici. Le fibre fitte ricordano un mantello protettivo.',
    descEn:
        'A creature covered in dense fur that resists physical strikes. The fibres resemble a protective cloak.',
    elementId: 'fisico',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    encounterRules: {'authoredCanonical': true},
    damageResistancePresets: {
      'fisico': 'resistenza',
      'taglio': 'resistenza',
      'contundente': 'resistenza',
      'perforante': 'resistenza',
    },
    stats: {
      'level': 0,
      'resilienza': 10,
      'volonta': 7,
      'materia': 4,
      'oculum': 4,
    },
    armorTags: ['mantello di fibre fitte'],
    skillIds: ['durafur_fur_fury'],
    dropIds: [],
  ),
  MonsterBookEntry(
    id: 'sensimoss',
    nameIt: 'Sensimoss',
    nameEn: 'Sensimoss',
    descIt:
        'Animale neutrale e percettivo dal dorso muschioso, con quattro zampe, '
        'due orecchie a foglia, due occhi e due zanne chiare. Le foglie '
        'sovrapposte ricordano un piccolo mantello da esploratore.',
    descEn:
        'A neutral, perceptive animal with a mossy back, four legs, two '
        'leaf-shaped ears, two eyes and two pale tusks. Its overlapping '
        'leaves resemble an explorer’s small cloak.',
    elementId: 'natura',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNullFateless: false,
    encounterRules: {
      'authoredCanonical': true,
      'generationSide': 'neutral',
      'naturalAttitude': 'Neutrale e percettivo.',
      'hasAnatomicalWeakPoint': false,
      'precisionBodyParts': _sensimossAnatomy,
    },
    stats: {
      'level': 0,
      'resilienza': 4,
      'volonta': 3,
      'materia': 5,
      'oculum': 4,
    },
    armorTags: ['mantello da esploratore'],
    skillIds: [],
    dropIds: [],
  ),
];
