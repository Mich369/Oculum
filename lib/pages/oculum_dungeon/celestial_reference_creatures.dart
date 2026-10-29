part of 'monster_book.dart';

// Authored anatomy and rules; numerical values not supplied by the author
// remain initial, editable balance rather than additional canonical claims.
final _celestialReferenceBaseEntries = <MonsterBookEntry>[
  _authoredPlanar(
    'nuvola_in_bottiglia',
    'Nuvola in bottiglia',
    ['mezzano', 'nuvole_rocciose'],
    'fulmine',
    'Una creatura di nube compatta, con un grande occhio centrale viola e mani vaporose. Due ricevitori di fulmini emergono dalla parte alta; una piccola bottiglia è collegata al corpo da un collo di vapore. La bottiglia è il primo punto debole: un critico la rompe e libera la seconda fase, recuperando il 40% della Vita massima. Senza rottura anticipata, la seconda fase inizia al 15% Vita e recupera il 75% della Vita massima, entro il massimo. Usa attacchi di Fulmine. All’Open una folgore raggiunge i ricevitori e alimenta una scarica 2d50+25 su massimo 12 avversari, con +15% Danni per persona. Il Buff Open dà una Reazione veloce a ogni nuovo turno e potenzia Fulmine ferma-azione dal 20% e un quarto dei Danni al 60% e metà Danni; la porzione di danno viene inflitta anche quando l’interruzione fallisce.',
    'La bottiglia che lo contiene, prima che venga rotta nella prima fase.',
    [3, 3, 5, 4],
    3,
    false,
    false,
    ['bottled_cloud_arc', 'bottled_cloud_stop'],
    {
      'authoredCanonical': true,
      'phaseCount': 2,
      'secondPhaseHpPercent': 15,
      'secondPhaseHealPercent': 75,
      'bottleCriticalHealPercent': 40,
      'openMaximumTargets': 12,
      'openDamagePerTargetPercent': 15,
    },
    const {},
  ).copyWith(
    dropIds: ['vetro_ricevitore_nuvola'],
    classificationTags: ['Nuvola', 'Due fasi'],
  ),
  _authoredPlanar(
    'mostro_solare',
    'Mostro solare',
    ['sacro', 'mezzano'],
    'solare',
    'Predatore solare dal corpo dorato coperto da motivi scuri, testa lunga tenuta bassa e un corno scuro molto affilato. Le braccia sono lunghe e terminano in grandi artigli metallici; le zampe snelle hanno dita unghiate. Avanza aggressivamente con affondi del corno, tagli delle braccia e marchi Solari; quando deve resistere incrocia gli arti davanti al torace. Corno, artigli e lamine dorate forniscono materiali, scroll ed equipaggiamenti coerenti con queste tecniche.',
    'La giuntura sotto il collo quando abbassa il corno per caricare.',
    [3, 4, 2, 2],
    2,
    false,
    false,
    [
      'solar_beast_horn',
      'solar_beast_claws',
      'solar_beast_brand',
      'solar_beast_guard',
    ],
    {
      'authoredCanonical': true,
      'dispositions': ['aggressivo', 'ostile'],
    },
    const {},
  ).copyWith(
    dropIds: ['scheggia_corno_solare', 'lamina_dorata_solare'],
    classificationTags: ['Solare', 'Predatore'],
  ),
  _authoredPlanar(
    'mostro_lunare',
    'Mostro lunare',
    ['mezzano', 'sacro'],
    'lunare',
    'Una macchina lunare per mantenere l’ordine contro i Solari: armatura nera fatta di piastre angolari sovrapposte, spalle appuntite, corona di punte sul capo e lunghi avambracci a lama ricurva. Le gambe sono corazzate e i piedi unghiati. Quattro cristalli #7B68EE sono incastonati nella struttura: tre davanti, su fronte, sterno e addome, e uno dietro che funge anche da occhio. Sono tutti punti deboli separati dalla Vita del corpo: ogni cristallo resiste a tre colpi riusciti o a un critico; un doppio critico ne distrugge due. Ciascun cristallo integro sostiene uno Scudo critico e 100 Scudo normale. Questi Scudi critici non si consumano sui critici normali: scompaiono soltanto distruggendo i cristalli. Il cristallo posteriore integro dà +5 al tiro per colpire e +6 al tiro difensivo. È immune a Taglio e possiede Alta Resistenza ai danni Solari. Il pool contiene dodici Skill di Luna, Buio e Taglio, comprese tecniche dei cristalli.',
    'I quattro cristalli #7B68EE: fronte, sterno, addome e occhio posteriore.',
    [4, 5, 4, 3],
    3,
    false,
    false,
    [
      'lunar_order_lunge',
      'lunar_order_scissors',
      'lunar_order_crown',
      'lunar_order_shadow_step',
      'lunar_order_prism',
      'lunar_order_rear_ray',
      'lunar_order_veil',
      'lunar_order_dread',
      'lunar_order_guard',
      'lunar_order_darts',
      'lunar_order_orbit',
      'lunar_order_verdict',
    ],
    {
      'authoredCanonical': true,
      'crystalColor': '#7B68EE',
      'chestMoonSymbol': true,
      'precisionBodyParts': [
        for (final part in const [
          ('body', 'Corpo', false),
          ('head', 'Testa', false),
          ('arms_1', 'Braccio a lama destro', false),
          ('arms_2', 'Braccio a lama sinistro', false),
          ('legs_1', 'Gamba corazzata destra', false),
          ('legs_2', 'Gamba corazzata sinistra', false),
          ('lunar_crystal_forehead', 'Cristallo della fronte', true),
          (
            'lunar_crystal_sternum',
            'Cristallo centrale del petto · simbolo lunare',
            true,
          ),
          ('lunar_crystal_abdomen', 'Cristallo dell’addome', true),
          ('lunar_crystal_rear', 'Cristallo posteriore · occhio', true),
        ])
          {
            'id': part.$1,
            'label': part.$2,
            'weak': part.$3,
            'penalty': 0,
            'group': part.$1.startsWith('arms_')
                ? 'arms'
                : part.$1.startsWith('legs_')
                ? 'legs'
                : part.$1,
            if (part.$1.startsWith('arms_') || part.$1.startsWith('legs_'))
              'side': part.$1.endsWith('_1') ? 'right' : 'left',
          },
      ],
      'crystalHits': 3,
      'normalShieldPerCrystal': 100,
      'criticalShieldsPerCrystal': 1,
      'rearCrystalAttackBonus': 5,
      'rearCrystalDefenseRollBonus': 6,
      'crystalDamageOnly': true,
      'linkedCriticalShields': true,
      'priorityTargetAffinity': 'solare',
      'crystalSkillIds': [
        'lunar_order_crown',
        'lunar_order_prism',
        'lunar_order_rear_ray',
        'lunar_order_darts',
      ],
    },
    const {'taglio': 'Immunità', 'solare': 'Alta Resistenza'},
  ).copyWith(
    dropIds: ['scheggia_cristallo_lunare', 'piastra_custode_lunare'],
    classificationTags: [
      'Lunare',
      'Buio',
      'Taglio',
      'Costrutto',
      'Custode dell’ordine',
    ],
  ),
];

final _celestialReferenceEntries = <MonsterBookEntry>[
  ..._celestialReferenceBaseEntries,
  _celestialReferenceBaseEntries.last.copyWith(
    id: 'mostro_lunare_demoniaco',
    nameIt: 'Mostro lunare demoniaco',
    nameEn: 'Demonic lunar creature',
    descIt:
        'Versione potenziata del custode lunare, dal corpo di metallo incandescente. Corna più pronunciate e piastre affilate gli danno un aspetto demoniaco; i quattro cristalli sono rossi. Nel cristallo centrale del petto rimane il simbolo della Luna. Conserva le dodici tecniche di Luna, Buio e Taglio e le stesse regole dei cristalli: tre colpi riusciti o un critico, due cristalli su doppio critico. Ogni cristallo integro sostiene 100 Scudo e uno Scudo critico collegato; solo quello posteriore dà +5 al tiro per colpire e +6 al tiro difensivo. Danni ai cristalli separati dalla Vita del corpo. Immunità a Taglio e Alta Resistenza Solare.',
    stats: {
      ..._celestialReferenceBaseEntries.last.stats,
      'level': 5,
      'resilienza': 6,
      'volonta': 7,
      'materia': 6,
      'oculum': 5,
    },
    weakPointIt:
        'I quattro cristalli rossi: fronte, petto con simbolo lunare, addome e occhio posteriore.',
    encounterRules: {
      ..._celestialReferenceBaseEntries.last.encounterRules,
      'crystalColor': '#E53935',
      'empoweredVariantOf': 'mostro_lunare',
    },
    classificationTags: [
      ..._celestialReferenceBaseEntries.last.classificationTags,
      'Demoniaco',
      'Potenziato',
    ],
  ),
];

MonsterConcreteTechnique _celestialDamage(
  String name,
  String action,
  String element,
  List<int> values, {
  String resource = 'volonta',
  int targets = 1,
  bool burn = false,
}) => MonsterConcreteTechnique(
  name: name,
  action: action,
  element: element,
  kind: 'danno',
  requiredLevel: 0,
  costResource: resource,
  minimums: [1, 2, 3],
  maximums: [1, 2, 3],
  cooldownValues: [2, 3, 4],
  forms: [
    for (final value in values)
      [
        MonsterTechniqueEffect(
          'danno',
          '$value',
          mode: 'prossima_azione',
          maximumTargets: targets,
        ),
        if (burn)
          const MonsterTechniqueEffect(
            'stato',
            '1',
            target: 'bruciatura',
            recipient: 'nemico',
            duration: '3',
          ),
      ],
  ],
);

final _celestialReferenceTechniques = <String, MonsterConcreteTechnique>{
  'bottled_cloud_arc': _celestialDamage(
    'Arco fra i ricevitori',
    'Raccoglie elettricità nei due ricevitori e prepara un singolo arco di Fulmine',
    'fulmine',
    [8, 14, 20],
    resource: 'oculum',
  ),
  'bottled_cloud_stop': _octoberMove(
    'Fulmine ferma-azione',
    '20% di fermare un’Azione, infliggendo comunque un quarto dei Danni totali. Con Buff Open: 60% e metà dei Danni totali',
    'bottled_cloud_stop',
    [1, 1, 1],
    element: 'fulmine',
    costs: [2, 3, 4],
  ),
  'solar_beast_horn': _celestialDamage(
    'Affondo del corno solare',
    'Abbassa il lungo corno e prepara un affondo contro un avversario',
    'solare',
    [12, 18, 24],
  ),
  'solar_beast_claws': _celestialDamage(
    'Taglio delle grandi lame',
    'Incrocia i lunghi artigli metallici e prepara un taglio ampio',
    'taglio',
    [8, 14, 20],
    targets: 2,
  ),
  'solar_beast_brand': _celestialDamage(
    'Marchio del Sole ostile',
    'Prepara una traccia di energia Solare che lascia Bruciatura sul colpo riuscito',
    'solare',
    [5, 9, 13],
    resource: 'oculum',
    burn: true,
  ),
  'solar_beast_guard': MonsterConcreteTechnique(
    name: 'Guardia degli avambracci',
    action: 'Incrocia le piastre degli avambracci davanti al collo e al torace',
    element: 'fisico',
    kind: 'difesa',
    requiredLevel: 0,
    costResource: 'materia',
    minimums: [1, 2, 3],
    maximums: [1, 2, 3],
    cooldownValues: [2, 3, 4],
    forms: [
      for (final value in [4, 7, 10])
        [MonsterTechniqueEffect('difesa', '$value', duration: '1')],
    ],
  ),
  'lunar_order_lunge': _celestialDamage(
    'Affondo delle lame lunari',
    'Prepara un affondo con la lama dell’avambraccio',
    'taglio',
    [10, 16, 22],
  ),
  'lunar_order_scissors': _celestialDamage(
    'Forbice dell’ordine',
    'Prepara un taglio incrociato contro fino a due avversari',
    'taglio',
    [8, 13, 18],
    targets: 2,
  ),
  'lunar_order_crown': _celestialDamage(
    'Corona di schegge lunari',
    'Un cristallo integro libera schegge lunari contro fino a tre avversari',
    'lunare',
    [6, 10, 14],
    resource: 'oculum',
    targets: 3,
  ),
  'lunar_order_shadow_step': MonsterConcreteTechnique(
    name: 'Passo nel Buio',
    action: 'Si sposta fra le ombre mantenendo le lame in guardia',
    element: 'oscuro',
    kind: 'movimento',
    requiredLevel: 0,
    costResource: 'materia',
    minimums: [1, 2, 3],
    maximums: [1, 2, 3],
    cooldownValues: [2, 3, 4],
    forms: [
      for (final value in [4, 6, 8])
        [MonsterTechniqueEffect('velocita', '$value', duration: '1')],
    ],
  ),
  'lunar_order_prism': _celestialDamage(
    'Prisma della Luna scomparsa',
    'Concentra la luce dei cristalli integri in un solo raggio Lunare',
    'lunare',
    [12, 18, 24],
    resource: 'oculum',
  ),
  'lunar_order_rear_ray': _celestialDamage(
    'Raggio dell’occhio posteriore',
    'Il cristallo posteriore integro prepara un raggio di Buio contro chi si trova alle spalle',
    'oscuro',
    [8, 14, 20],
    resource: 'oculum',
  ),
  'lunar_order_veil': MonsterConcreteTechnique(
    name: 'Velo d’ossidiana',
    action: 'Il corpo si confonde nell’ombra con Trasparenza temporanea',
    element: 'oscuro',
    kind: 'controllo',
    requiredLevel: 0,
    costResource: 'materia',
    minimums: [1, 2, 3],
    maximums: [1, 2, 3],
    cooldownValues: [3, 4, 5],
    forms: [
      for (final turns in [1, 2, 3])
        [
          MonsterTechniqueEffect(
            'stato',
            '1',
            target: 'trasparenza',
            duration: '$turns',
          ),
        ],
    ],
  ),
  'lunar_order_dread': MonsterConcreteTechnique(
    name: 'Ombra opprimente',
    action:
        'Un impulso di Buio penalizza il tiro per colpire dell’avversario che fallisce la difesa',
    element: 'oscuro',
    kind: 'controllo',
    requiredLevel: 0,
    costResource: 'oculum',
    minimums: [1, 2, 3],
    maximums: [1, 2, 3],
    cooldownValues: [3, 4, 5],
    forms: [
      for (final value in [2, 3, 4])
        [
          MonsterTechniqueEffect(
            'modifica_sottotratto',
            '$value',
            target: 'vc',
            mode: 'diminuzione',
            recipient: 'nemico',
            duration: '2',
          ),
        ],
    ],
  ),
  'lunar_order_guard': MonsterConcreteTechnique(
    name: 'Guardia delle lame nere',
    action: 'Protegge il corpo incrociando gli avambracci corazzati',
    element: 'taglio',
    kind: 'difesa',
    requiredLevel: 0,
    costResource: 'materia',
    minimums: [1, 2, 3],
    maximums: [1, 2, 3],
    cooldownValues: [2, 3, 4],
    forms: [
      for (final value in [5, 8, 11])
        [MonsterTechniqueEffect('difesa', '$value', duration: '1')],
    ],
  ),
  'lunar_order_darts': _celestialDamage(
    'Dardi dei cristalli',
    'Proietta fino a due dardi Lunari da cristalli ancora integri',
    'lunare',
    [7, 12, 17],
    resource: 'oculum',
    targets: 2,
  ),
  'lunar_order_orbit': MonsterConcreteTechnique(
    name: 'Risposta orbitale',
    action: 'Prepara una Reazione veloce aggiuntiva per questo turno',
    element: 'lunare',
    kind: 'difesa',
    requiredLevel: 0,
    costResource: 'materia',
    minimums: [2, 3, 4],
    maximums: [2, 3, 4],
    cooldownValues: [3, 4, 5],
    forms: [
      for (final value in [1, 1, 1])
        [
          MonsterTechniqueEffect(
            'aggiungi_reazioni_rapide',
            '$value',
            duration: '1',
          ),
        ],
    ],
  ),
  'lunar_order_verdict': _celestialDamage(
    'Verdetto delle lame',
    'Prepara un preciso colpo di Taglio con entrambe le lame',
    'taglio',
    [14, 21, 28],
  ),
};
