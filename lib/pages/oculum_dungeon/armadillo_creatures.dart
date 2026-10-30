part of 'monster_book.dart';

/// The three CM values and A-or-R activation are user rules. Other numbers are
/// editable initial balance; these are living beasts, not lunar constructs.
const oculumArmadilloSpeciesIds = <String>{
  'armadillo_corazzato',
  'armadillo_sabbia',
  'armadillo_cristallo',
  'armadillo_legno',
};

const _armadilloSeeds = <Map<String, dynamic>>[
  {
    'id': 'armadillo_corazzato',
    'name': 'Armadillo Corazzato',
    'element': 'contundente',
    'planes': ['mezzano', 'foresta_elementale'],
    'stats': [4, 2, 3, 1],
    'level': 0,
    'look':
        'Piccolo quadrupede corazzato lungo circa settanta centimetri, con muso affusolato, due occhi scuri, quattro zampe corte artigliate e una coda rastremata. Placche cornee brune si sovrappongono sul dorso; il ventre è morbido e color crema. Non porta armi né vestiti. Si chiude avvolgendo muso, zampe e coda entro il carapace; può ancora rotolare e speronare.',
    'attitude':
        'Schivo e curioso, cerca radici e insetti. Preferisce chiudersi e fuggire rotolando; attacca chi lo insegue o minaccia la tana.',
    'material': 'placche_di_armadillo',
    'shellMaterial': 'chitin',
    'attack': 'Speronamento corazzato',
    'damage': [3, 5, 8],
  },
  {
    'id': 'armadillo_sabbia',
    'name': 'Armadillo della Sabbia',
    'element': 'terra',
    'planes': ['deserto_divoratore'],
    'stats': [4, 2, 4, 1],
    'level': 1,
    'look':
        'Quadrupede basso delle dune, con muso corto protetto da narici richiudibili, due piccoli occhi ambrati, quattro zampe larghe da scavo e coda piatta. Le placche cornee sono rivestite da sabbia compatta color ocra e creste abrasive, senza cristalli o nucleo scoperto. Il ventre grigio chiaro resta morbido. Chiudendosi assume una forma quasi sferica che scivola fra i pendii sabbiosi.',
    'attitude':
        'Territoriale vicino alle tane, segue le vibrazioni nel suolo e cerca una discesa per fuggire quando viene accerchiato.',
    'material': 'placche_sabbiose_di_armadillo',
    'shellMaterial': 'chitin',
    'attack': 'Urto della duna compatta',
    'damage': [4, 7, 10],
  },
  {
    'id': 'armadillo_cristallo',
    'name': 'Armadillo di Cristallo',
    'element': 'roccia',
    'planes': ['reame_cristallo'],
    'stats': [5, 2, 4, 2],
    'level': 2,
    'look':
        'Quadrupede largo dal muso triangolare e due occhi grigio-verdi. Quattro zampe corte terminano in piccoli artigli minerali; una coda segmentata si ripiega sotto il corpo. Placche cornee scure sostengono basse facce di quarzo fumoso verde pallido, sfaccettate e distanziate per permettere la chiusura. Il ventre è opaco e privo di cristalli. Non ha cristalli-occhio né Scudi critici legati alle gemme.',
    'attitude':
        'Pacifico finché le vene minerali o i piccoli non vengono disturbati. Si appallottola per attraversare le gallerie e risponde agli urti con brevi speronamenti.',
    'material': 'quarzo_corazzato_di_armadillo',
    'shellMaterial': 'crystal',
    'attack': 'Speronamento delle facce di quarzo',
    'damage': [5, 8, 12],
  },
  {
    'id': 'armadillo_legno',
    'name': 'Armadillo di Legno',
    'element': 'natura',
    'planes': ['foresta_elementale', 'mezzano'],
    'stats': [4, 3, 4, 1],
    'level': 1,
    'look':
        'Piccolo quadrupede dal muso smussato, due occhi color nocciola e quattro zampe robuste con artigli corti. Il carapace è una successione di placche lignee vive, sovrapposte come corteccia di castagno, con sottili fibre flessibili alle giunture; una coda corta completa la chiusura. Il ventre è di fibra morbida e pallida. Non ha braccia umane, bocche aggiuntive, nucleo o tentacoli di radici.',
    'attitude':
        'Tranquillo e gregario, riposa sotto le radici senza confondersi con esse. Difende i piccoli, ma lascia andare chi abbandona la sua radura.',
    'material': 'corteccia_flessibile_di_armadillo',
    'shellMaterial': 'wood',
    'attack': 'Urto delle placche di castagno',
    'damage': [3, 6, 9],
  },
];

List<Map<String, dynamic>> _armadilloAnatomy(String shellMaterial) => [
  {
    'id': 'shell',
    'label': 'Carapace a placche',
    'group': 'armor',
    'weak': false,
    'integrity': {
      'material': shellMaterial,
      'maximumHpFraction': .75,
      'rollPenalty': 0,
    },
  },
  for (final (id, label, group, fraction, weak) in [
    ('head', 'Muso', 'head', .30, false),
    ('eyes_1', 'Occhio destro', 'eyes', .06, false),
    ('eyes_2', 'Occhio sinistro', 'eyes', .06, false),
    ('belly', 'Ventre fra le placche', 'belly', .40, true),
    ('legs_1', 'Zampa anteriore destra', 'legs', .25, false),
    ('legs_2', 'Zampa anteriore sinistra', 'legs', .25, false),
    ('legs_3', 'Zampa posteriore destra', 'legs', .25, false),
    ('legs_4', 'Zampa posteriore sinistra', 'legs', .25, false),
    ('tail', 'Coda', 'tail', .20, false),
  ])
    {
      'id': id,
      'label': label,
      'group': group,
      'weak': weak,
      'hiddenWhileArmadilloClosed': true,
      'integrity': {
        'material': shellMaterial == 'wood' ? 'wood' : 'flesh',
        'maximumHpFraction': fraction,
      },
    },
];

final _armadilloCreatureEntries = <MonsterBookEntry>[
  for (final seed in _armadilloSeeds)
    MonsterBookEntry(
      id: seed['id'] as String,
      nameIt: seed['name'] as String,
      nameEn: seed['name'] as String,
      descIt:
          '${seed['look']} ${seed['attitude']} Ruolo in scena: '
          'difensore mobile di basso livello; si chiude usando un’Azione '
          'oppure una Reazione, non entrambe. Appallottolamento I/II/III '
          'concede +6/+9/+16 CM finché chiuso e consente rotolamento e '
          'speronamento. Riaprirsi termina quel bonus.',
      descEn:
          '${seed['look']} A mobile low-level armored beast. Curling '
          'costs one Action OR Reaction and grants +6/+9/+16 CM while '
          'closed, preserving rolling and ramming.',
      elementId: seed['element'] as String,
      planeIds: List<String>.from(seed['planes'] as List),
      spriteAssetPath: '',
      isMiniBoss: false,
      isBoss: false,
      isNullFateless: false,
      stats: {
        'level': seed['level'] as int,
        'resilienza': (seed['stats'] as List)[0] as int,
        'volonta': (seed['stats'] as List)[1] as int,
        'materia': (seed['stats'] as List)[2] as int,
        'oculum': (seed['stats'] as List)[3] as int,
        'oculumArt': 1,
      },
      weakPointIt:
          'Il ventre morbido fra le placche, accessibile quando '
          'l’animale non è appallottolato.',
      weakPointEn: 'The softer belly between plates, exposed when uncurled.',
      skillIds: [
        'armadillo_roll_up',
        'armadillo_uncurl',
        'armadillo_roll',
        '${seed['id']}_ram',
      ],
      dropIds: [seed['material'] as String],
      dropChances: {seed['material'] as String: 55},
      damageResistancePresets: {
        'tagliente': 'Resistenza',
        if (seed['id'] == 'armadillo_legno') 'fuoco': 'Fragilità',
        if (seed['id'] == 'armadillo_cristallo') 'contundente': 'Fragilità',
      },
      encounterRules: {
        'authoredCanonical': true,
        if (seed['id'] != 'armadillo_corazzato')
          'canonicalVariantOf': 'armadillo_corazzato',
        'naturalAttitude': seed['attitude'],
        'dispositions': ['pacifico', 'territoriale'],
        'armadillo': true,
        'armadilloRules': {
          'cmByForm': [6, 9, 16],
          'resourceByForm': [1, 2, 3],
          'costResource': 'materia',
          'allowedTurnResources': ['azione', 'reazione'],
          'canRollWhileClosed': true,
          'canRamWhileClosed': true,
        },
        'precisionBodyParts': _armadilloAnatomy(
          seed['shellMaterial'] as String,
        ),
      },
      classificationTags: [
        seed['id'] == 'armadillo_legno' ? 'Creatura vegetale' : 'Bestia',
        'Quadrupede',
        'Corazzato',
      ],
    ),
];

final _armadilloTechniques = <String, MonsterConcreteTechnique>{
  'armadillo_roll_up': const MonsterConcreteTechnique(
    name: 'Appallottolamento',
    action:
        'Chiude muso, zampe e coda nel carapace usando una sola Azione '
        'oppure una sola Reazione. Concede +6/+9/+16 CM finché resta chiuso, '
        'senza sommare più attivazioni. Può ancora rotolare e speronare. '
        'Non è un’immunità e non ignora i Danni inevitabili.',
    element: 'fisico',
    kind: 'difesa',
    requiredLevel: 0,
    costResource: 'materia',
    minimums: [1, 2, 3],
    maximums: [1, 2, 3],
    cooldownValues: [2, 3, 4],
    forms: [
      [
        MonsterTechniqueEffect(
          'planar',
          '6',
          target: 'armadillo_roll_up',
          duration: '',
        ),
      ],
      [
        MonsterTechniqueEffect(
          'planar',
          '9',
          target: 'armadillo_roll_up',
          duration: '',
        ),
      ],
      [
        MonsterTechniqueEffect(
          'planar',
          '16',
          target: 'armadillo_roll_up',
          duration: '',
        ),
      ],
    ],
  ),
  'armadillo_uncurl': const MonsterConcreteTechnique(
    name: 'Riapertura delle placche',
    action:
        'Riapre il carapace e termina il bonus CM di Appallottolamento. '
        'Non spende statistiche, ma richiede un’Azione oppure una Reazione.',
    element: 'fisico',
    kind: 'utility',
    requiredLevel: 0,
    costResource: 'nessuna',
    minimums: [0, 0, 0],
    maximums: [0, 0, 0],
    cooldownValues: [0, 0, 0],
    forms: [
      [
        MonsterTechniqueEffect(
          'planar',
          '0',
          target: 'armadillo_uncurl',
          duration: '',
        ),
      ],
      [
        MonsterTechniqueEffect(
          'planar',
          '0',
          target: 'armadillo_uncurl',
          duration: '',
        ),
      ],
      [
        MonsterTechniqueEffect(
          'planar',
          '0',
          target: 'armadillo_uncurl',
          duration: '',
        ),
      ],
    ],
  ),
  'armadillo_roll': const MonsterConcreteTechnique(
    name: 'Rotolamento controllato',
    action:
        'Da chiuso prende velocità lungo il terreno, senza abbandonare '
        'il bonus CM del carapace. Aumenta Movimento per un turno personale; '
        'non è un teletrasporto e non attraversa pareti.',
    element: 'fisico',
    kind: 'movimento',
    requiredLevel: 0,
    costResource: 'materia',
    minimums: [1, 2, 3],
    maximums: [1, 2, 3],
    cooldownValues: [2, 2, 3],
    forms: [
      [
        MonsterTechniqueEffect(
          'planar',
          '0',
          target: 'armadillo_closed_required',
        ),
        MonsterTechniqueEffect(
          'modifica_sottotratto',
          '2',
          target: 'movimento',
        ),
      ],
      [
        MonsterTechniqueEffect(
          'planar',
          '0',
          target: 'armadillo_closed_required',
        ),
        MonsterTechniqueEffect(
          'modifica_sottotratto',
          '3',
          target: 'movimento',
        ),
      ],
      [
        MonsterTechniqueEffect(
          'planar',
          '0',
          target: 'armadillo_closed_required',
        ),
        MonsterTechniqueEffect(
          'modifica_sottotratto',
          '5',
          target: 'movimento',
        ),
      ],
    ],
  ),
  for (final seed in _armadilloSeeds)
    '${seed['id']}_ram': MonsterConcreteTechnique(
      name: seed['attack'] as String,
      action:
          'Da chiuso rotola contro un solo avversario a contatto. '
          'Il Danno aggiuntivo si somma una sola volta ai Danni attuali; '
          'restano Difesa, Scudi e normale tiro contrapposto. '
          'Lo speronamento non disattiva Appallottolamento.',
      element: seed['element'] as String,
      kind: 'danno',
      requiredLevel: 0,
      costResource: 'materia',
      minimums: const [1, 2, 3],
      maximums: const [1, 2, 3],
      cooldownValues: const [1, 2, 2],
      forms: [
        for (final bonus in seed['damage'] as List)
          [
            const MonsterTechniqueEffect(
              'planar',
              '0',
              target: 'armadillo_closed_required',
            ),
            MonsterTechniqueEffect(
              'danno',
              '$bonus',
              mode: 'prossima_azione',
              duration: '',
            ),
          ],
      ],
    ),
};
