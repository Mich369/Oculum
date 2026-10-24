part of 'monster_book.dart';

/// Habitat identifiers match the plane selector. Variants inherit the habitat.
const oculumMonsterHabitats = <String, String>{
  'mezzano': 'Regno mezzano',
  'sacro': 'Regno sacro',
  'angelico': 'Regno angelico',
  'oblio': 'Oblio',
  'isole': 'Isole volanti',
  'affogato': 'Regno affogato',
  'sotterraneo': 'Regno sotterraneo',
  'sotterraneo_maggiore': 'Regno sotterraneo maggiore',
  'demoniaco': 'Regno demoniaco',
  'shadow_hell': 'Shadow Hell',
  'diabolico': 'Regno diabolico',
  'vero_inferno': 'Il vero inferno',
  'postea': 'Postea',
  'caramella': 'Regno Caramella',
  'foresta_elementale': 'Foresta elementale',
  'morti': 'Regno dei Morti',
  'ghiaccio': 'Terre di ghiaccio',
  'nuvole_rocciose': 'Nuvole rocciose',
};
const oculumMicroRealityIds = <String>{
  'postea',
  'caramella',
  'foresta_elementale',
  'morti',
  'ghiaccio',
  'nuvole_rocciose',
};

const _planarSpeciesNames = <String, List<String>>{
  'postea': [
    'Segugio dei circuiti runici',
    'Mantide a pistoni',
    'Ratto portabatterie',
    'Falena al neon runico',
    'Granchio delle rotaie',
    'Serpente di cavi',
    'Ragno saldatore',
    'Corvo archivista',
    'Cinghiale delle discariche',
    'Anguilla del trasformatore',
    'Lumaca a dinamo',
    'Automate infermiere guasto',
    'Centauro monorotaia',
    'Millepiedi delle condotte',
    'Chimera di ricambi',
    'Colosso della sirena',
    'Custode dei terminali',
    'Tessitore di ologrammi runici',
    'Regina delle officine',
    'Archivista della città errante',
  ],
  'caramella': [
    'Topo di marzapane',
    'Granchio di torrone',
    'Serpente di liquirizia',
    'Falena di zucchero filato',
    'Cinghiale di croccante',
    'Ragno di caramello',
    'Corvo di cacao',
    'Lumaca di glassa',
    'Volpe di gelatina',
    'Rospo di crema',
    'Riccio di praline',
    'Golem di biscotto',
    'Medusa di confettura',
    'Cervo di candy cane',
    'Vespa di miele scuro',
    'Custode della fontana fondente',
    'Strega del forno freddo',
    'Masticatore di cristalli dolci',
    'Regina delle fave amare',
    'Drago del caramello bruciato',
  ],
  'foresta_elementale': [
    'Salamandra delle felci ardenti',
    'Cervo delle sorgenti',
    'Lince di brina verde',
    'Tartaruga delle radici',
    'Vipera di quarzo',
    'Colibri del temporale',
    'Falena dei vortici',
    'Gufo della nebbia viva',
    'Pantera del sottobosco oscuro',
    'Scarabeo del prisma',
    'Leone del polline solare',
    'Lepre della rugiada lunare',
    'Mantide dell’aureola',
    'Caprone della brace empia',
    'Ragno della linfa acida',
    'Rospo delle spore sonore',
    'Serpente del muschio psichico',
    'Custode delle stagioni spezzate',
    'Regina delle corolle vuote',
    'Antico dei venti elementi',
  ],
  'morti': [
    'Topo delle urne',
    'Corvo delle lapidi',
    'Ragno di falangi',
    'Segugio del camposanto',
    'Falena del sudario',
    'Serpente delle vertebre',
    'Custode delle nicchie',
    'Vedova delle ossa cucite',
    'Cervo del corteo funebre',
    'Rospo della palude sepolcrale',
    'Lumaca del marmo spento',
    'Scheletro del traghettatore',
    'Vespa delle candele',
    'Cavaliere senza epitaffio',
    'Bambola di ceneri',
    'Becchino dalle mani lunghe',
    'Araldo delle tombe aperte',
    'Campanaro delle anime ferme',
    'Regina delle cripte sommerse',
    'Re del corteo senza fine',
  ],
  'ghiaccio': [
    'Lepre delle crepe azzurre',
    'Volpe del ghiaccio fumante',
    'Granchio del lago cieco',
    'Falena della neve nera',
    'Cinghiale delle stalattiti',
    'Ragno del cristallo gelato',
    'Corvo del vento bianco',
    'Lumaca della brina cava',
    'Serpente del permafrost',
    'Rospo della fonte gelida',
    'Riccio delle schegge pallide',
    'Golem del ghiacciaio cavo',
    'Medusa della tormenta',
    'Cervo delle corna di vetro',
    'Vespa del gelo secco',
    'Custode del passo sepolto',
    'Tessitrice delle aurore',
    'Masticatore del sole spento',
    'Regina del disgelo nero',
    'Drago della notte polare',
  ],
  'nuvole_rocciose': [
    'Topo dei ciottoli sospesi',
    'Granchio della grandine',
    'Serpente del cumulonembo',
    'Falena del tuono sordo',
    'Cinghiale delle creste volanti',
    'Ragno dei ponti di vapore',
    'Corvo del magnete celeste',
    'Lumaca della nube pesante',
    'Volpe della pietra leggera',
    'Rospo della pioggia obliqua',
    'Riccio delle saette corte',
    'Golem delle ghiaie orbitanti',
    'Medusa dei fulmini lenti',
    'Cervo del vento minerale',
    'Vespa dei cristalli sonori',
    'Custode del monolite sospeso',
    'Tessitrice delle correnti',
    'Masticatore degli archi celesti',
    'Regina delle isole spezzate',
    'Leviatano della tempesta pietrificata',
  ],
  'mezzano': [
    'Segugio dei rovi cavi',
    'Ragno delle cisterne',
    'Cervo delle lanterne spente',
    'Rospo del mulino sommerso',
    'Bandito della maschera di corteccia',
    'Corvo delle monete false',
    'Custode del ponte muschioso',
    'Signore della foresta cava',
  ],
  'sacro': [
    'Scarabeo dell’altare solare',
    'Segugio delle reliquie',
    'Custode del vetro consacrato',
    'Falena dei ceri eterni',
    'Aberrazione del coro diviso',
    'Serpente del sigillo santo',
    'Araldo del sole ferito',
    'Giudice dalle sette aureole',
  ],
  'angelico': [
    'Colomba delle lame bianche',
    'Ariete delle porte celesti',
    'Falena del canto d’argento',
    'Custode delle piume cucite',
    'Cervo dell’aureola incrinata',
    'Cherubino delle lance vuote',
    'Araldo della scala luminosa',
    'Custode del coro perduto',
  ],
  'oblio': [
    'Segugio senza ricordo',
    'Falena delle pagine vuote',
    'Ragno delle ombre cancellate',
    'Serpente dei nomi rubati',
    'Custode del pozzo muto',
    'Maschera della memoria spenta',
    'Araldo del silenzio assoluto',
    'Divoratore degli ultimi nomi',
  ],
  'isole': [
    'Airone delle correnti inverse',
    'Vipera dei parafulmini',
    'Razza del cielo basso',
    'Falena dei cristalli di pioggia',
    'Cervo delle corde sospese',
    'Granchio delle navi aeree',
    'Custode del faro volante',
    'Regina dei nidi tempestosi',
  ],
  'affogato': [
    'Segugio delle alghe a nastro',
    'Granchio delle anfore',
    'Medusa del porto nero',
    'Anguilla delle campane sommerse',
    'Rospo dei coralli cavi',
    'Cervo delle foreste marine',
    'Custode della diga di perle',
    'Regina degli abissi respirabili',
  ],
  'sotterraneo': [
    'Talpa dei cristalli ciechi',
    'Ragno dei funghi di vetro',
    'Rospo delle vene ferrose',
    'Centopiedi della selce',
    'Salamandra della ghiaia',
    'Pipistrello delle radici nude',
    'Custode del pozzo di basalto',
    'Regina delle miniere mute',
  ],
  'sotterraneo_maggiore': [
    'Talpa del diamante nero',
    'Ragno delle geodi vive',
    'Rospo del ferro lunare',
    'Centopiedi del quarzo profondo',
    'Serpente delle faglie antiche',
    'Pipistrello del buio minerale',
    'Custode del cuore sotterraneo',
    'Regina delle montagne rovesciate',
  ],
  'demoniaco': [
    'Segugio delle scorie vive',
    'Scarabeo della lava fredda',
    'Caprone delle fornaci',
    'Serpente della cenere mobile',
    'Falena delle fiamme nere',
    'Custode dei chiodi roventi',
    'Araldo delle cicatrici ardenti',
    'Regina delle gole vulcaniche',
  ],
  'shadow_hell': [
    'Segugio dal riflesso obliterato',
    'Ragno dei sigilli corrotti',
    'Caprone della memoria bruciata',
    'Serpente dell’ombra diabolica',
    'Falena dell’aureola infetta',
    'Custode del pendaglio infranto',
    'Araldo della fenditura nera',
    'Regina dello specchio dell’Oblio',
  ],
  'diabolico': [
    'Segugio del patto di ferro',
    'Scarabeo dei contratti ardenti',
    'Caprone della fossa di vetro',
    'Serpente del marchio sovrano',
    'Falena dei sigilli di lava',
    'Custode della catena diabolica',
    'Araldo delle corone fuse',
    'Re dei patti consumati',
  ],
  'vero_inferno': [
    'Segugio delle nove fornaci',
    'Scarabeo del sole caduto',
    'Caprone dei troni bruciati',
    'Serpente del fiume delle corone',
    'Falena dell’ultimo giudizio',
    'Custode del cancello senza ritorno',
    'Araldo della cenere eterna',
    'Sovrano della fiamma originaria',
  ],
};
const _planarElements = <String, List<String>>{
  'mezzano': ['fisico', 'natura'],
  'sacro': ['solare', 'angelico'],
  'angelico': ['angelico'],
  'oblio': ['oblio'],
  'isole': ['fulmine', 'vento', 'nuvola', 'acqua', 'ghiaccio'],
  'affogato': ['acqua'],
  'sotterraneo': ['roccia', 'terra', 'buio'],
  'sotterraneo_maggiore': ['roccia', 'terra', 'buio'],
  'demoniaco': ['demoniaco', 'fuoco', 'lava'],
  'shadow_hell': ['diabolico', 'oblio'],
  'diabolico': ['diabolico', 'fuoco', 'lava'],
  'vero_inferno': ['diabolico', 'lava', 'fuoco'],
  'postea': ['fisico', 'fulmine', 'roccia'],
  'caramella': ['fisico', 'acqua', 'natura'],
  'foresta_elementale': [
    'fuoco',
    'acqua',
    'ghiaccio',
    'terra',
    'roccia',
    'fulmine',
    'vento',
    'nuvola',
    'buio',
    'luce',
    'solare',
    'lunare',
    'angelico',
    'demoniaco',
    'acido',
    'sonoro',
    'psichico',
    'natura',
    'oblio',
    'diabolico',
  ],
  'morti': ['necrotico', 'buio', 'fisico'],
  'ghiaccio': ['ghiaccio'],
  'nuvole_rocciose': ['roccia', 'fulmine', 'nuvola', 'vento'],
};
const _planarMinimumGrade = <String, int>{
  'sacro': 3,
  'sotterraneo_maggiore': 1,
  'shadow_hell': 4,
  'diabolico': 3,
  'vero_inferno': 9,
};

String _planarSlug(String name) => name
    .toLowerCase()
    .replaceAll(RegExp('[^a-z0-9]+'), '_')
    .replaceAll(RegExp(r'^_|_$'), '');

final List<MonsterBookEntry> oculumPlanarMonsterEntries = [
  const MonsterBookEntry(
    id: 'meccanio',
    nameIt: 'Meccanio',
    nameEn: 'Meccanio',
    descIt:
        'Robottino pacifico di Postea in equilibrio su una sola ruota nera scanalata, con fianchi sottili e busto tondeggiante formato da piastre consumate. La testa larga e bassa porta grandi lenti luminose verde acqua, una fessura scura simile a un sorriso e una piccola antenna scomposta. Due braccia snodate con giunti scoperti terminano in pinze e utensili ripiegabili; strisce a contrasto proteggono spalle e avambracci. La scocca può avere colori diversi a ogni acquisto. Si autoripara con Meccanica al posto di Medicina; il padrone può ripararlo con il proprio tiro di Meccanica.',
    descEn:
        'A small peaceful Postea robot balancing on one black wheel. Rounded worn plates cover its torso; a wide low head holds large aqua lenses, a dark smile-like opening and a crooked antenna. Jointed arms end in pincers and folding tools. Shell colours may vary between purchases. It and its owner use Mechanics instead of Medicine to repair its HP.',
    planeIds: ['postea'],
    elementId: 'fisico',
    spriteAssetPath: '',
    isMiniBoss: false,
    isBoss: false,
    isNpc: true,
    isNullFateless: false,
    stats: {
      'level': 0,
      'resilienza': 4,
      'volonta': 2,
      'materia': 4,
      'oculum': 0,
    },
    encounterRules: {
      'dispositions': ['pacifico', 'neutrale'],
      'healingSubtrait': 'meccanica',
    },
    weakPointIt: 'I cavi scoperti sotto la piastra del nucleo.',
    classificationTags: ['Costrutto', 'Robot', 'Creatura Minore'],
  ),
  for (final spec in const [
    (
      'ammaccato',
      'Malconcio',
      'Scocca deformata, una lente incrinata e una ruota che oscilla; piccoli lampi sfuggono dai giunti scoperti.',
      3,
      1,
      3,
    ),
    (
      'primordiale',
      'Primitivo',
      'Piastre di roccia levigata invece del metallo, ruota di basalto e rune del Fulmine incise su testa, petto e pinze. Le rune si accendono a ogni movimento.',
      4,
      2,
      4,
    ),
    (
      'elite',
      'Élite',
      'Piastre rinforzate, lenti a diaframma e giunti protetti; un anello di rune precise circonda il nucleo.',
      6,
      4,
      6,
    ),
  ])
    MonsterBookEntry(
      id: 'meccanio_${spec.$1}',
      nameIt: 'Meccanio ${spec.$2}',
      nameEn: 'Meccanio ${spec.$2}',
      descIt:
          '${spec.$3} Variante selvatica neutrale di Postea. ${spec.$1 == 'ammaccato'
              ? 'Metà Scudo e skill indebolite al 75%.'
              : spec.$1 == 'primordiale'
              ? '+3 Difesa, meno Scudo (120% Vita) e poco Scudo Oculum (10% Vita).'
              : 'Skill potenziate al 125%.'} Senza Oculum né Art; tre skill casuali, almeno una offensiva, Protezioni di Emergenza e una sola Open. Addestrabile con Meccanica contro DT 13 + livello + 3×Grado, se non ha già un padrone. Un solo Meccanio per padrone.',
      descEn: spec.$3,
      planeIds: const ['postea'],
      elementId: spec.$1 == 'primordiale' ? 'roccia' : 'fisico',
      spriteAssetPath: '',
      isMiniBoss: false,
      isBoss: false,
      isNullFateless: false,
      stats: {
        'level': 0,
        'resilienza': spec.$4,
        'volonta': spec.$5,
        'materia': spec.$6,
        'oculum': 0,
      },
      encounterRules: {
        'meccanioVariant': spec.$1,
        'dispositions': ['neutrale'],
        'tamingSubtrait': 'meccanica',
      },
      weakPointIt: 'Il giunto scoperto sotto il nucleo runico.',
      classificationTags: const ['Costrutto', 'Robot', 'Creatura Minore'],
    ),
  _authoredPlanar(
    'parassita_larvale',
    'Parassita larvale',
    ['mezzano', 'sotterraneo', 'foresta_elementale'],
    'fisico',
    'Larva minuscola dalla testa appena più larga del corpo, pelle pallida e appendici sottili. Si contorce e scatta con Riflessi +9–15 per difendersi e infiltrarsi sotto la pelle. Ha un solo attacco: Infiltrazione. Dentro l’ospite non può essere colpito separatamente; controlla azioni e skill del corpo. Vita fissa, non cresce con livello o Grado. Medicina o una Open dell’ospite possono ucciderlo.',
    'Il capo morbido quando è fuori dall’ospite.',
    [1, 0, 0, 0],
    0,
    false,
    false,
    [],
    {'parasite': true, 'reflexMin': 9, 'reflexMax': 15, 'fixedHp': 10},
    {},
  ),
  _authoredPlanar(
    'martire_mortale',
    'Martire Mortale',
    ['mezzano', 'morti', 'sacro'],
    'spirituale',
    'Creatura minuta e fragile, avvolta in lembi di stoffa color cenere. Una luce tiepida pulsa sotto il petto cavo; alla morte si divide in fino a tre fili luminosi che raggiungono gli alleati scelti. Dà metà EXP. Bonus +10% alle statistiche, +10% ogni dieci livelli, per livello/5 turni (minimo uno).',
    'La cavità luminosa al centro del petto.',
    [1, 1, 1, 0],
    0,
    false,
    false,
    [],
    {'martyr': true, 'experienceMultiplier': .5},
    {},
  ),

  _authoredPlanar(
    'bringi',
    'Bringi',
    ['mezzano', 'foresta_elementale'],
    'natura',
    'Piccolo roditore simile a uno scoiattolo, dalla coda folta e arcuata, pelo color nocciola e guance sempre gonfie di semi. Pacifico e neutrale: raccoglie provviste e non attacca per primo. Alla prima aggressione sputa 1d20 semi; dopo tre colpi subiti risponde con 1d100+20 semi. Ogni seme toglie 1 Vita: il totale è un unico evento, senza moltiplicare danno base o bonus per seme.',
    'Le guance gonfie, esposte mentre inspira prima di sputare.',
    [2, 2, 5, 0],
    0,
    false,
    false,
    ['bringi_seeds'],
    {
      'dispositions': ['pacifico', 'neutrale'],
      'retaliationThreshold': 3,
    },
    {},
  ),
  ..._shieldCloudMonsterEntries,
  ..._canonicalPlanarVariants,
  for (final habitat in _planarSpeciesNames.entries)
    for (var i = 0; i < habitat.value.length; i++)
      _buildPlanarMonster(
        habitat.key,
        habitat.value[i],
        i,
        habitat.value.length,
      ),
];

MonsterBookEntry _buildPlanarMonster(
  String habitat,
  String name,
  int index,
  int count,
) {
  final id = 'habitat_${habitat}_${_planarSlug(name)}';
  final boss = index == count - 1;
  final mini = !boss && index >= count - 3;
  final grade = _planarMinimumGrade[habitat] ?? 0;
  final level =
      (const {1: 10, 3: 40, 4: 50, 9: 100}[grade] ?? 0) +
      (index % (count > 8 ? 10 : 5));
  final element =
      _planarElements[habitat]![index % _planarElements[habitat]!.length];
  final role = index % 6;
  final extra = boss
      ? 6
      : mini
      ? 3
      : 0;
  const bodies = [
    'corpo basso e allungato, zampe anteriori robuste e una coda segnata da anelli',
    'carapace a piastre sovrapposte, arti uncinati e piccoli occhi ravvicinati',
    'sagoma sottile, lunghe appendici sensoriali e una cresta frastagliata',
    'corpo arrotondato, quattro ali nervate e mandibole corte',
    'spalle larghe, arti asimmetrici e placche consumate sui fianchi',
    'collo arcuato, mantello irregolare e dita lunghe adatte ad afferrare',
  ];
  final material = switch (habitat) {
    'postea' =>
      'Metallo riparato con rivetti, rune incise a mano e cavi scoperti; nessuna tecnologia funziona senza il circuito runico.',
    'caramella' =>
      'La superficie è commestibile: cioccolato amaro, zucchero cristallizzato e striature di sciroppo. Le crepe espongono un cuore morbido.',
    'foresta_elementale' =>
      'Linfa e venature luminose seguono l’elemento $element; foglie e cristalli reagiscono al suo respiro.',
    'morti' =>
      'Ossa ingiallite e lembi di sudario circondano un lume funebre; si muove senza respirare e segue i cortei dei defunti.',
    'ghiaccio' =>
      'Brina opaca e cristalli azzurri ricoprono il dorso; l’aria condensa attorno ai suoi giunti più caldi.',
    'nuvole_rocciose' =>
      'Pietra porosa e vapore denso formano il corpo; scintille passano tra frammenti sospesi senza sostegni.',
    'sacro' || 'angelico' =>
      'Avorio pallido, piume metalliche e incisioni luminose ne scandiscono la silhouette; la luce pulsa da una fessura centrale.',
    'oblio' || 'shadow_hell' =>
      'I bordi sembrano cancellati e gli occhi sono pozzi neri; l’ombra conserva gesti che il corpo ha già interrotto.',
    'demoniaco' || 'diabolico' || 'vero_inferno' =>
      'Basalto, corna annerite e membrane rosse proteggono fenditure incandescenti; catene o scorie tintinnano ai suoi passi.',
    'affogato' =>
      'Membrane traslucide, incrostazioni di conchiglie e branchie luminose consentono movimenti lenti ma precisi tra le rovine sommerse.',
    'isole' =>
      'Piume sfrangiate e membrane leggere raccolgono l’elettricità delle correnti; piccoli cristalli tengono stabile il volo.',
    'sotterraneo' || 'sotterraneo_maggiore' =>
      'Argilla scura e minerali cresciuti nella pelle mascherano la creatura contro le pareti; le antenne seguono le vibrazioni del terreno.',
    _ =>
      'Pelliccia terrosa e segni di vecchie ferite lo confondono con radici, pietre e manufatti abbandonati.',
  };
  const tactics = [
    'Predatore: isola una preda e prepara il colpo, poi lascia un’apertura mentre recupera.',
    'Guardiano: protegge uno stretto passaggio con Scudo; il recupero lascia spazio alla pressione del gruppo.',
    'Controllore: ostacola un bersaglio; gli alleati possono aiutarlo a superare la difesa.',
    'Supporto: cura un alleato ferito; impedire la cura richiede pressione sulla creatura.',
    'Schermagliatore: prepara Difesa e colpisce di fianco; non ottiene Azioni extra.',
    'Ritualista: prepara un riparo fragile, poi attacca; il riparo non agisce e non intercetta automaticamente.',
  ];
  return MonsterBookEntry(
    id: id,
    nameIt: name,
    nameEn: name,
    planeIds: [habitat],
    descIt:
        '$name: ${bodies[role]}. $material Habitat: ${oculumMonsterHabitats[habitat]}. ${tactics[role]} ${boss
            ? 'Boss'
            : mini
            ? 'Mini Boss'
            : 'Mostro comune'}, livello consigliato $level, Grado minimo $grade. Base e crescita restano separate: +9 punti per livello secondo le regole di creazione. Le due tecniche hanno tre forme modificabili.',
    descEn: '$name — ${oculumMonsterHabitats[habitat]}.',
    elementId: element,
    spriteAssetPath: '',
    isMiniBoss: mini,
    isBoss: boss,
    isNullFateless: false,
    stats: {
      'level': level,
      'grade': grade,
      'resilienza': 3 + role % 3 + extra,
      'volonta': 2 + (role + 1) % 4 + extra,
      'materia': 3 + (role + 2) % 4 + extra,
      'oculum': role == 0 ? 0 : 2 + extra,
    },
    weakPointIt: [
      'Il tendine scoperto sotto la mascella, visibile prima dell’affondo.',
      'La cerniera morbida sotto il bordo ventrale delle piastre.',
      'Il nodo sensoriale dietro la cresta, scoperto durante la tecnica.',
      'La membrana alla radice delle ali, esposta mentre prepara la cura.',
      'La fessura priva di placche sul fianco sinistro.',
      'Il piccolo nucleo nella gola, visibile quando prepara il riparo.',
    ][role],
    damageResistancePresets: {if (element != 'fisico') element: 'resistenza'},
    skillIds: ['${id}_strike', '${id}_utility'],
    dropIds: ['frammento_${_planarSlug(name)}'],
    dropChances: {
      'frammento_${_planarSlug(name)}': boss
          ? 65
          : mini
          ? 45
          : 30,
    },
    encounterRules: {
      'recommendedLevel': level,
      'minimumGrade': grade,
      'role': role,
      'catalogueVersion': 1,
    },
    classificationTags: [
      habitat == 'morti'
          ? 'Non morto'
          : habitat == 'postea'
          ? 'Costrutto'
          : 'Creatura planare',
    ],
  );
}

final Map<String, MonsterConcreteTechnique> _planarTechniques = {
  for (final monster in oculumPlanarMonsterEntries.where(
    (m) => m.id.startsWith('habitat_'),
  ))
    for (var slot = 0; slot < 2; slot++)
      monster.skillIds[slot]: _buildPlanarTechnique(monster, slot),
};
MonsterConcreteTechnique? oculumPlanarTechnique(String rawId) =>
    _canonicalVariantTechniques[rawId] ??
    _extraPlanarTechniques[rawId.replaceFirst(
      RegExp(r'_variante_[a-z]+$'),
      '',
    )] ??
    _authoredPlanarTechniques[rawId.replaceFirst(
      RegExp(r'_variante_[a-z]+$'),
      '',
    )] ??
    _planarTechniques[rawId.replaceFirst(RegExp(r'_variante_[a-z]+$'), '')];

/// Damage preview/resolution rule shared by the Angelic Ray variants.
/// Karma is added before the target-class multiplier; positive target Karma
/// never increases the ray.
int oculumAngelRayDamage({
  required int baseDamage,
  required int attackerKarma,
  required int targetKarma,
  required String targetKind,
}) {
  final karmaDamage = baseDamage + attackerKarma + max(0, -targetKarma);
  return (karmaDamage * oculumAngelRayMultiplier(targetKind)).ceil();
}

double oculumAngelRayMultiplier(String targetKind) {
  final kind = targetKind.trim().toLowerCase();
  if (kind.contains('arcidiavol')) return 1.3;
  if (kind.contains('diavol')) return 1.5;
  if (kind.contains('demon')) return 2;
  return 1;
}

bool oculumIsAngelRayEffectId(String id) =>
    id.split('/').last.startsWith('raggio_angelico_forma_');

MonsterConcreteTechnique _buildPlanarTechnique(
  MonsterBookEntry owner,
  int slot,
) {
  final role = owner.encounterRules['role'] as int;
  final kind = slot == 0
      ? 'danno'
      : ['danno', 'scudo', 'controllo', 'cura', 'movimento', 'costrutto'][role];
  final name =
      slot == 0 &&
          const {'luce', 'solare', 'angelico'}.contains(owner.elementId)
      ? 'Raggio di luce · ${owner.nameIt}'
      : slot == 0 &&
            owner.planeIds.contains('morti') &&
            (owner.stats['oculum'] ?? 0) > 0
      ? 'Raggio necromantico · ${owner.nameIt}'
      : slot == 1 && kind == 'controllo' && owner.elementId == 'ghiaccio'
      ? 'Presa di ghiaccio · ${owner.nameIt}'
      : slot == 0
      ? '${['Affondo', 'Urto', 'Spina', 'Puntura', 'Falciata', 'Dardo'][role]} · ${owner.nameIt}'
      : '${['Caccia serrata', 'Piastre sovrapposte', 'Nodo di presa', 'Linfa ricucente', 'Passo laterale', 'Riparo intessuto'][role]} · ${owner.nameIt}';
  return MonsterConcreteTechnique(
    name: name,
    action: slot == 0
        ? 'Concentra ${owner.elementId} nel colpo e mira alla parte esposta; un solo bersaglio.'
        : [
            'Prepara un unico attacco ravvicinato più potente.',
            'Sovrappone il rivestimento a protezione del corpo.',
            'Stringe gli arti attorno al bersaglio; una difesa riuscita evita la presa.',
            'Ricuce le ferite di un alleato scelto, senza superarne la Vita massima.',
            'Scarta sul fianco e prepara la propria difesa.',
            'Intreccia un riparo inerte con Vita propria; nessuna iniziativa o Azione aggiuntiva.',
          ][role],
    element: owner.elementId,
    kind: kind,
    requiredLevel: 0,
    minimums: slot == 0 ? const [1, 5, 11] : const [1, 4, 9],
    maximums: slot == 0 ? const [4, 10, 20] : const [3, 8, 15],
    forms: List.generate(
      3,
      (form) => [
        switch (kind) {
          'scudo' => MonsterTechniqueEffect(
            'scudo',
            '${6 + form * 4}+oculum_spent',
            mode: 'immediato',
          ),
          'cura' => MonsterTechniqueEffect(
            'cura',
            'oculum_spent*${form + 1}',
            recipient: 'alleato',
          ),
          'movimento' => MonsterTechniqueEffect(
            'difesa',
            '${2 + form}',
            duration: '1',
          ),
          'controllo' => const MonsterTechniqueEffect(
            'stato',
            '1',
            target: 'immobilizzato',
            duration: '1',
            recipient: 'bersaglio',
          ),
          'costrutto' => MonsterTechniqueEffect(
            'costrutto',
            '${5 + form * 5}+oculum_spent',
            target: 'Riparo di ${owner.nameIt}',
            duration: '2',
          ),
          _ => MonsterTechniqueEffect(
            'danno',
            '${slot == 0 ? 3 + form * 5 : 5 + form * 6}+oculum_spent',
            mode: 'prossima_azione',
            duration: '',
          ),
        },
      ],
    ),
  );
}

// Readapted first-edition creatures: one stable species, multiple habitats.
final _shieldCloudMonsterEntries = <MonsterBookEntry>[
  _authoredPlanar(
    'piranha_mortale',
    'Piranha Mortale',
    ['affogato'],
    'acqua',
    'Pesce predatore dal corpo stretto, pinne scure e mascelle sovradimensionate. Caccia in banchi coordinati: uno distrae la preda mentre gli altri mordono i fianchi. Può richiamare piccoli piranha pallidi, molto meno resistenti ma insistenti. Il morso può aprire una ferita sanguinante; una difesa riuscita evita sia il danno sia la condizione.',
    'Le branchie esterne, che restano scoperte quando il banco si ricompone.',
    [3, 2, 3, 1],
    2,
    false,
    false,
    ['piranha_morso', 'piranha_sciame', 'piranha_richiamo'],
    {
      'swarmAttackerCount': 2,
      'bleedOnNaturalCritical': true,
      'summon': {
        'id': 'piranha_minore',
        'count': 1,
        'maxAlive': 2,
        'weakerThanSource': true,
      },
    },
    {'acqua': 'resistenza', 'fulmine': 'Fragilità'},
  ),
  _authoredPlanar(
    'araldo_raggio_angelico',
    'Araldo del Raggio Angelico',
    ['angelico', 'sacro'],
    'angelico',
    'Creatura umanoide dalle ali stratificate d’avorio, con una fenditura di luce azzurra al centro del petto. Proietta un raggio lineare e preciso, poi deve attendere che il sigillo sul torace si ricomponga.',
    'La fenditura luminosa sul petto: interromperne la linea riduce la precisione del raggio.',
    [5, 7, 6, 5],
    3,
    false,
    false,
    ['raggio_angelico'],
    {'rayDamageUsesKarma': true},
    {'buio': 'Fragilità', 'diabolico': 'resistenza'},
  ),
  _authoredPlanar(
    'fire_shield',
    'FireShield',
    ['demoniaco', 'diabolico', 'vero_inferno'],
    'fuoco',
    'Un enorme rettile nero a sei arti, ventre grigio ripiegato e dorso formato da placche vulcaniche. Fenditure rosse attraversano corna, spalle e artigli; gli occhi ardono come feritoie. Tiene il ventre vicino al terreno e si solleva soltanto per il raggio. Boss di assedio: 2 Scudi critici. Resiste a Fuoco, Lava e fisico. Acqua spegne la resistenza fisica per il successivo attacco ricevuto, anche se schivato.',
    'La pelle grigia sotto la pancia, priva delle placche vulcaniche.',
    [12, 8, 10, 6],
    8,
    true,
    false,
    ['fire_shield_ray', 'fire_shield_charge'],
    {
      'criticalShields': 2,
      'waterExposesPhysicalForAttacks': 1,
      'waterExposureConsumesOnDodge': true,
      'huntReward': {'kills': 3, 'skillId': 'fire_shield_charge'},
      'finisherReward': {'condition': 'weak_point', 'criticalShields': 1},
    },
    {
      'fuoco': 'Alta Resistenza',
      'lava': 'Alta Resistenza',
      'fisico': 'resistenza',
      'acqua': 'Fragilità',
    },
  ),
  _authoredPlanar(
    'rock_shield',
    'RockShield',
    ['sotterraneo', 'sotterraneo_maggiore', 'nuvole_rocciose'],
    'roccia',
    'Un quadrupede tozzo con quattro braccia corte, lunghe unghie nere e dorso piramidale di scaglie chiare. La testa scompare sotto una cresta appuntita; ferite scure interrompono le scaglie sui fianchi. Mini Boss difensivo: 3 Scudi critici e 1 Schivata Oculum. La corazza rende preziosi gli attacchi contundenti non magici.',
    'Le ferite aperte e la pelle sotto la pancia, tra le zampe.',
    [10, 6, 8, 4],
    5,
    false,
    true,
    ['rock_shield_pressure', 'rock_shield_scales'],
    {
      'criticalShields': 3,
      'oculumDodges': 1,
      'huntReward': {'kills': 5, 'skillId': 'rock_shield_super_armor'},
      'finisherRewards': [
        {
          'condition': 'skill:rock_shield_pressure',
          'skillId': 'rock_shield_charge',
        },
        {'condition': 'nonmagical_blunt', 'skillId': 'rock_shield_blade'},
      ],
    },
    {'roccia': 'resistenza'},
  ),
  _authoredPlanar(
    'air_navigator',
    'Navigatore dell’Aria',
    ['isole', 'nuvole_rocciose'],
    'vento',
    'Creatura sottile dalla testa d’uccello e dal lungo mantello di piume color paglia. Le braccia nere finiscono in tre artigli ricurvi; la parte inferiore si disperde in un vortice scuro. Non ha zampe visibili. Si inclina controvento e protegge le correnti che attraversa.',
    'Il nodo scuro tra torace e vortice, visibile quando si ferma a fluttuare.',
    [4, 4, 6, 3],
    3,
    false,
    false,
    ['air_navigator_float', 'air_navigator_claws'],
    {
      'huntReward': {'kills': 10, 'skillId': 'air_navigator_vanish'},
      'finisherReward': {
        'condition': 'base_attack',
        'skillId': 'air_navigator_claws',
      },
    },
    {'vento': 'resistenza'},
  ),
  _authoredPlanar(
    'cloud_beast',
    'Bestia delle Nuvole',
    ['isole', 'nuvole_rocciose'],
    'nuvola',
    'Bestia alta e incurvata, con muso ossuto, orecchie appuntite e due corna color rame. Una criniera di nuvole pallide trabocca sulle spalle; avambracci lunghi e artigli sottili sostengono il busto. Stracci scuri pendono dai fianchi e una grande coda di vapore raccoglie elettricità. Mini Boss: 1 Scudo critico e 1 Schivata Oculum.',
    'Il petto ossuto sotto la criniera, esposto quando raccoglie aria tra le mani.',
    [8, 7, 7, 5],
    5,
    false,
    true,
    ['cloud_beast_orb', 'cloud_beast_tornado'],
    {
      'criticalShields': 1,
      'oculumDodges': 1,
      'huntReward': {'kills': 5, 'skillId': 'cloud_beast_prison'},
      'finisherReward': {
        'condition': 'ability',
        'skillId': 'cloud_beast_lightning',
      },
    },
    {'nuvola': 'resistenza', 'fulmine': 'resistenza'},
  ),
  _authoredPlanar(
    'smiling_storm',
    'Tempesta Sorridente',
    ['isole', 'nuvole_rocciose'],
    'fulmine',
    'Un volto largo e sorridente emerge da una nube scura allungata. Denti di ghiaccio lampeggiano tra filamenti elettrici; gli arti sono vortici corti che spariscono prima di toccare terra. Mini Boss: gli attacchi base lo attraversano se chi attacca non è più forte; le abilità possono colpirlo normalmente.',
    'La spirale densa dietro il sorriso, scoperta prima del Soffio Violento.',
    [7, 8, 6, 6],
    6,
    false,
    true,
    ['smiling_storm_breath', 'smiling_storm_lethal'],
    {
      'baseAttackGate': 'attacker_stronger',
      'huntReward': {'kills': 5, 'skillId': 'smiling_storm_lethal'},
      'finisherReward': {
        'condition': 'base_attack',
        'skillId': 'smiling_storm_cloud_life',
      },
    },
    {'fulmine': 'resistenza', 'nuvola': 'resistenza'},
  ),
  _authoredPlanar(
    'rock_cloud_golem',
    'Golem di nuvole rocciose',
    ['nuvole_rocciose'],
    'roccia',
    'Golem umanoide formato da blocchi di roccia grigia irregolari. Un cappuccio e una cintura di nuvole attraversano il petto e le cosce; due piccoli occhi azzurri brillano nella testa squadrata. I pugni sono massi enormi e nei giunti sospesi saltano archi elettrici.',
    'Il nucleo incassato al centro del petto, dietro la fascia di vapore.',
    [8, 5, 8, 4],
    4,
    false,
    false,
    ['rock_cloud_punch', 'rock_cloud_barrier'],
    {
      'bestDamageElement': ['nuvola', 'roccia', 'fulmine'],
      'huntReward': {'kills': 10, 'skillId': 'rock_cloud_barrier'},
      'finisherReward': {
        'condition': 'lethal_precision_weak_point',
        'skillId': 'rock_cloud_max_power',
      },
    },
    {'roccia': 'resistenza', 'fulmine': 'resistenza'},
  ),
  _authoredPlanar(
    'lightning_skull',
    'Teschio di fulmine',
    ['nuvole_rocciose', 'morti'],
    'fulmine',
    'Scheletro esile con cranio allungato a becco, grandi orbite vuote e mascella seghettata. Il collo si curva in avanti; archi viola uniscono costole e falangi mentre la schiena resta quasi orizzontale. Il cranio funziona da accumulatore e illumina le ossa dall’interno.',
    'La sutura dietro la mandibola, dove convergono le scariche.',
    [4, 5, 6, 4],
    3,
    false,
    false,
    ['lightning_skull_orb', 'lightning_skull_claws'],
    {
      'huntReward': {'kills': 10, 'skillId': 'lightning_skull_cloud'},
    },
    {'fulmine': 'resistenza'},
  ),
  _authoredPlanar(
    'blade_skull',
    'Teschio della Lama',
    ['morti', 'sotterraneo'],
    'necrotico',
    'Scheletro guerriero in piastre viola consumate, spallacci angolosi e gonna di strisce metalliche. Il cranio emette luce verde dalle orbite e dalla bocca; una lunga lingua sottile segue il filo dell’arma seghettata. Si regge con ginocchia piegate e protegge la mano armata.',
    'La vertebra scoperta sotto il bordo del collare metallico.',
    [5, 6, 6, 2],
    3,
    false,
    false,
    ['blade_skull_bones', 'blade_skull_vampirism'],
    {
      'huntReward': {'kills': 10, 'passive': 'slashing_critical_natural_19'},
    },
    {'necrotico': 'resistenza'},
  ),
  _authoredPlanar(
    'obliterated_devil',
    'Diavolo Obliterato',
    ['shadow_hell', 'oblio'],
    'oblio',
    'Diavolo aggressivo dalla pelle grigio cenere, corna piegate e occhi completamente neri, senza riflessi. Un terzo occhio si apre nel palmo o sulla fronte; allontanando la mano da esso forma una sfera nera che sembra sottrarre luce alla scena. Se fugge, il ricordo della sua identità si perde; il Titolo Malanno Annichilimento applica @res-30% per tre Riposi Lunghi. La fuga nasconde soltanto l’identità nel Book, senza cancellare progressi o premi.',
    'Il margine chiaro attorno al terzo occhio, visibile durante la preparazione della sfera.',
    [10, 9, 8, 8],
    40,
    false,
    true,
    ['obliterated_devil_sphere', 'obliterated_devil_annihilation'],
    {
      'annihilationMaxHpPercent': 30,
      'annihilationCooldown': 'riposo_lungo',
      'annihilationLongRests': 3,
      'annihilationTitleBuff': '@res-30%',
    },
    {'oblio': 'Alta Resistenza', 'diabolico': 'resistenza'},
  ),
];
MonsterBookEntry _authoredPlanar(
  String id,
  String name,
  List<String> habitats,
  String element,
  String look,
  String weak,
  List<int> stats,
  int level,
  bool boss,
  bool mini,
  List<String> skills,
  Map<String, dynamic> rules,
  Map<String, String> resistance,
) => MonsterBookEntry(
  id: id,
  nameIt: name,
  nameEn: name,
  planeIds: habitats,
  descIt: look,
  descEn: look,
  elementId: element,
  spriteAssetPath: '',
  isMiniBoss: mini,
  isBoss: boss,
  isNullFateless: false,
  stats: {
    'level': level,
    'resilienza': stats[0],
    'volonta': stats[1],
    'materia': stats[2],
    'oculum': stats[3],
    if (stats[3] > 0) 'oculumArt': 1,
  },
  weakPointIt: weak,
  skillIds: skills,
  encounterRules: rules,
  damageResistancePresets: resistance,
  dropIds: ['frammento_$id'],
  dropChances: {'frammento_$id': 40},
  classificationTags: [
    habitats.contains('morti') ? 'Non morto' : 'Creatura planare',
  ],
);

MonsterConcreteTechnique _planarMove(
  String name,
  String action,
  String element,
  String kind,
  List<List<MonsterTechniqueEffect>> forms, {
  int level = 0,
  String costResource = 'oculum',
  List<int> minimums = const [1, 5, 11],
  List<int> maximums = const [4, 10, 30],
  List<int>? cd,
}) => MonsterConcreteTechnique(
  name: name,
  action: action,
  element: element,
  kind: kind,
  forms: forms,
  requiredLevel: level,
  costResource: costResource,
  minimums: minimums,
  maximums: maximums,
  cooldownValues: cd,
);
List<List<MonsterTechniqueEffect>> _planarDamageForms(
  List<int> base, {
  int multiplier = 1,
}) => [
  for (final n in base)
    [
      MonsterTechniqueEffect(
        'danno',
        '$n+oculum_spent*$multiplier',
        mode: 'prossima_azione',
        duration: '',
      ),
    ],
];
final _authoredPlanarTechniques = <String, MonsterConcreteTechnique>{
  'fire_shield_ray': _planarMove(
    'Raggio di fuoco rosso',
    'Apre le placche del collo e concentra un raggio rosso su un bersaglio. Il recupero lungo lascia il boss esposto alla manovra del party.',
    'fuoco',
    'danno',
    _planarDamageForms([12, 24, 40], multiplier: 2),
    cd: [4, 5, 6],
  ),
  'fire_shield_charge': _planarMove(
    'Carica di pura ira',
    'Un’armatura di metallo rosso e fiamme avvolge busto, guanti e stivali. Carichi un avversario: bonus al solo prossimo attacco corpo a corpo, non a ogni attacco del fight.',
    'fuoco',
    'danno',
    _planarDamageForms([8, 16, 26]),
    cd: [3, 4, 5],
  ),
  'rock_shield_pressure': _planarMove(
    'Pressione amplificata',
    'Espande un’onda che respinge il nemico. Tiro di Pressione +9; il Master può regolare l’amplificazione per un bersaglio più forte. Un singolo bersaglio difende normalmente.',
    'roccia',
    'danno',
    _planarDamageForms([6, 12, 20]),
    cd: [3, 4, 5],
  ),
  'rock_shield_scales': _planarMove(
    'Scaglie di Roccia',
    'Scaglie magiche rivestono la pelle per 1d3 turni estratti automaticamente: metà danni, tranne contundente non magico; taglio non magico non infligge danni.',
    'roccia',
    'scudo',
    [
      for (var f = 0; f < 3; f++)
        [MonsterTechniqueEffect('difesa', '${3 + f * 2}', duration: '1')],
    ],
    cd: [4, 5, 6],
  ),
  'rock_shield_super_armor': _planarMove(
    'Super Armatura',
    'Per 3 colpi subiti dimezza i danni fisici; Schianto riuscito ignora la Difesa durante questa protezione. Il contatore dei colpi e l’eccezione si gestiscono nelle difese.',
    'roccia',
    'scudo',
    [
      for (var f = 0; f < 3; f++)
        [MonsterTechniqueEffect('difesa', '${2 + f}', duration: '3')],
    ],
    cd: [5, 6, 7],
  ),
  'rock_shield_charge': _planarMove(
    'Carica di roccia',
    'Roccia avvolge gli avambracci e due lame a scatto si aprono durante la carica; bonus al solo prossimo colpo.',
    'roccia',
    'danno',
    _planarDamageForms([6, 12, 20]),
    cd: [2, 3, 4],
  ),
  'rock_shield_blade': _planarMove(
    'Lama a scatto di roccia',
    'Colpo devastante come Schianto: un pugno apre la lama sotto pressione. Dopo il colpo hai -2 al prossimo tiro di Difesa.',
    'roccia',
    'danno',
    [
      for (var f = 0; f < 3; f++)
        [
          MonsterTechniqueEffect(
            'danno',
            '${10 + f * 10}+oculum_spent',
            mode: 'prossima_azione',
            duration: '',
          ),
          const MonsterTechniqueEffect(
            'difesa',
            '2',
            mode: 'diminuzione',
            duration: '1',
          ),
        ],
    ],
    cd: [3, 4, 5],
  ),
  'air_navigator_float': _planarMove(
    'Fluttuare',
    'Versione ridotta delle Ali di Fata: voli per 1d4 turni estratti automaticamente, +3 Difesa e +3 Movimento fino alla scadenza, senza immunità automatica. Costo 2 Oculum, CD 3 turni; Azione nel tuo turno o Reazione fuori turno.',
    'vento',
    'movimento',
    List.generate(
      3,
      (_) => [
        const MonsterTechniqueEffect(
          'stato',
          '1',
          target: 'volo',
          duration: '1',
        ),
      ],
    ),
    minimums: [2, 2, 2],
    maximums: [2, 2, 2],
    cd: [3, 3, 3],
  ),
  'air_navigator_claws': _planarMove(
    'Artigliata del Vento',
    'Porti due artigliate nella stessa azione; il danno indicato è il totale, non si duplica. Un colpo riuscito disorienta il bersaglio per un’azione.',
    'vento',
    'danno',
    [
      for (var f = 0; f < 3; f++)
        [
          MonsterTechniqueEffect(
            'danno',
            '${4 + f * 6}+oculum_spent',
            mode: 'prossima_azione',
            duration: '',
          ),
          const MonsterTechniqueEffect(
            'stato',
            '1',
            target: 'disorientato',
            duration: '1',
            recipient: 'nemico',
          ),
        ],
    ],
    cd: [2, 3, 4],
  ),
  'air_navigator_vanish': _planarMove(
    'Sparizione nell’Aria',
    'Scompari fino alla tua prossima azione: vantaggio al prossimo attacco e invulnerabilità fisica per il turno; l’uso chiude la sparizione. Gestisci il vantaggio e l’immunità nella scheda.',
    'vento',
    'movimento',
    List.generate(
      3,
      (_) => [
        const MonsterTechniqueEffect(
          'stato',
          '1',
          target: 'invisibile',
          duration: '1',
        ),
      ],
    ),
    cd: [4, 5, 6],
  ),
  'cloud_beast_orb': _planarMove(
    'Sfera d’Aria',
    'Comprime una sfera tra le mani e la scaglia contro un nemico; il consumo degli Scudi critici segue la normale risoluzione del colpo.',
    'vento',
    'danno',
    _planarDamageForms([8, 16, 28]),
    cd: [3, 4, 5],
  ),
  'cloud_beast_tornado': _planarMove(
    'TP del Vento',
    'Un tornado concentra il colpo; su critico positivo applica Stun per un’azione, da confermare dopo il tiro e la difesa.',
    'vento',
    'danno',
    _planarDamageForms([6, 12, 20]),
    cd: [3, 4, 5],
  ),
  'cloud_beast_prison': _planarMove(
    'Nuvola Prigioniera',
    'Una nube si allunga dal corpo e avvolge un nemico. La presa termina se lo colpisci o si libera; se la stringi per danneggiarlo, Stun per la prima azione.',
    'nuvola',
    'controllo',
    List.generate(
      3,
      (_) => [
        const MonsterTechniqueEffect(
          'stato',
          '1',
          target: 'immobilizzato',
          recipient: 'nemico',
          duration: '1',
        ),
      ],
    ),
    cd: [3, 4, 5],
  ),
  'cloud_beast_lightning': _planarMove(
    'Scarica di fulmini',
    'Instabile: nessuna azione di carica, svantaggio. Stabile: 1 azione di carica. Perfezionato: 2 azioni di carica, vantaggio e danni critici minori. Mentre carichi non agisci; subire un colpo annulla la carica, anche conservata. Carica e spendi il turno nel tuo turno o la Reazione fuori turno. Le tre forme indicano queste tre preparazioni, da gestire nella turnistica.',
    'fulmine',
    'danno',
    _planarDamageForms([15, 24, 32]),
    cd: [4, 5, 6],
  ),
  'smiling_storm_breath': _planarMove(
    'Soffio Violento',
    'Una forte pressione d’aria sradica rami e respinge il bersaglio; danno e normale difesa si risolvono prima dello spostamento narrativo.',
    'vento',
    'danno',
    _planarDamageForms([8, 16, 26]),
    cd: [3, 4, 5],
  ),
  'smiling_storm_lethal': _planarMove(
    'Fulmine Letale · Open',
    'Lanci un fulmine concentrato: il colpo usa la normale difesa e le normali regole dei critici. Valore iniziale ridotto rispetto alla prima edizione.',
    'fulmine',
    'danno',
    _planarDamageForms([20, 35, 55]),
    level: 6,
    cd: [6, 7, 8],
  ),
  'smiling_storm_cloud_life': _planarMove(
    'La Vita di una Nuvola',
    'Una volta a sessione, alla morte diventi una nube con metà della Vita massima originale. Puoi muoverti ma non attaccare, i mostri sono attratti da te. Se sopravvive integra fino a un Riposo Lungo, rinasci. Gestione manuale della forma e della rinascita.',
    'nuvola',
    'movimento',
    List.generate(3, (_) => <MonsterTechniqueEffect>[]),
    cd: [1, 1, 1],
  ),
  'rock_cloud_punch': _planarMove(
    'Pugno elettrico',
    'Un pugno di roccia nuvolosa accumula elettricità. Scegli Nuvola, Roccia o Fulmine in base alla resistenza effettiva del nemico; in parità scegli liberamente. Il danno non si somma tre volte.',
    'fulmine',
    'danno',
    _planarDamageForms([6, 12, 22]),
    cd: [2, 3, 4],
  ),
  'rock_cloud_barrier': _planarMove(
    'Scudo di Roccia Nuvola',
    'Una barriera cresce dalla mano; chi la colpisce riceve una scarica. Un critico della risposta stordisce per un’azione ed estende la scarica agli alleati vicini: Manifestazione del Potere +5. Conferma reazione e bersagli nella turnistica.',
    'roccia',
    'scudo',
    [
      for (var f = 0; f < 3; f++)
        [
          MonsterTechniqueEffect(
            'scudo',
            '${10 + f * 10}+oculum_spent',
            mode: 'immediato',
          ),
        ],
    ],
    cd: [4, 5, 6],
  ),
  'rock_cloud_max_power': _planarMove(
    'Max Power · Open',
    'Raddoppia Resilienza fino a fine fight, concede una Schivata Oculum e potenzia il danno. Il Master annota Resilienza iniziale e ripristino a fine fight; non cura automaticamente la Vita mancante.',
    'fulmine',
    'danno',
    _planarDamageForms([10, 20, 32]),
    level: 6,
    cd: [6, 7, 8],
  ),
  'lightning_skull_orb': _planarMove(
    'Sfera Elettra',
    'Una sfera attraversa i nemici nel tragitto. Il valore è un budget totale da dividere tra i bersagli colpiti, mai l’intero danno per ciascuno. Più bersagli: meno danno individuale.',
    'fulmine',
    'danno',
    _planarDamageForms([8, 16, 26]),
    cd: [3, 4, 5],
  ),
  'lightning_skull_claws': _planarMove(
    'Artigli Oscuri',
    'Artigli avvolti di ombra colpiscono un nemico. Un critico positivo applica Vita Afona per tre azioni, dopo la normale difesa.',
    'buio',
    'danno',
    _planarDamageForms([5, 11, 19]),
    cd: [3, 4, 5],
  ),
  'lightning_skull_cloud': _planarMove(
    'Nuvola Tuonante',
    'Una nube scura si allunga dal corpo e stringe il nemico folgorandolo; un critico positivo applica Stun per un’azione.',
    'fulmine',
    'danno',
    _planarDamageForms([7, 14, 24]),
    cd: [3, 4, 5],
  ),
  'blade_skull_bones': _planarMove(
    'Spuntoni di ossa',
    'Proietta ossa affilate dal suolo contro un nemico.',
    'fisico',
    'danno',
    _planarDamageForms([4, 10, 18]),
    cd: [2, 3, 4],
  ),
  'blade_skull_vampirism': _planarMove(
    'Vampirismo',
    'Recupera una quota dei soli danni realmente tolti alla Vita; non cura dai danni assorbiti dagli Scudi. Valore iniziale proposto 10%, modificabile, da applicare dopo la risoluzione.',
    'necrotico',
    'cura',
    List.generate(3, (_) => <MonsterTechniqueEffect>[]),
    cd: [0, 0, 0],
  ),
  'obliterated_devil_sphere': _planarMove(
    'Sfera dell’Annichilimento',
    'Allontana la mano dal terzo occhio formando una sfera nera priva di luce; la scaglia contro un bersaglio. La riduzione della Vita massima resta separata e in attesa della durata confermata.',
    'oblio',
    'danno',
    _planarDamageForms([18, 30, 48]),
    cd: [4, 5, 6],
  ),
};

final _extraPlanarTechniques = <String, MonsterConcreteTechnique>{
  'piranha_morso': _planarMove(
    'Morso sanguinante',
    'Un piranha del banco azzanna il bersaglio. Le Forme II e III applicano Sanguinante per 2 turni dopo un colpo riuscito; la Forma I infligge soltanto il danno. La difesa o una schivata riuscita evitano il colpo e la condizione.',
    'acqua',
    'danno',
    [
      for (var form = 0; form < 3; form++)
        [
          MonsterTechniqueEffect(
            'danno',
            '${4 + form * 4}+oculum_spent',
            mode: 'prossima_azione',
            duration: '',
          ),
          if (form > 0)
            const MonsterTechniqueEffect(
              'stato',
              '1',
              target: 'sanguinante',
              duration: '2',
              recipient: 'nemico',
            ),
        ],
    ],
    minimums: [1, 4, 9],
    maximums: [4, 8, 15],
    cd: [1, 2, 3],
  ),
  'piranha_sciame': _planarMove(
    'Attacco del banco',
    'Due piranha coordinano il morso: un solo tiro d’attacco e una sola difesa, con danno complessivo moderato. Non moltiplica i danni per il numero di pesci.',
    'acqua',
    'danno',
    _planarDamageForms([8, 14, 22]),
    minimums: [1, 5, 11],
    maximums: [1, 5, 11],
    cd: [2, 3, 4],
  ),
  'piranha_richiamo': _planarMove(
    'Richiamo dei piccoli',
    'Richiama un piranha minore con iniziativa propria. Ha 1/3/5 Vita, 1 Resilienza, nessuna skill e non può evocare altri pesci; massimo due vivi. Dura fino alla fine dello scontro.',
    'acqua',
    'costrutto',
    [
      for (final hp in [1, 3, 5])
        [
          MonsterTechniqueEffect(
            'costrutto',
            '$hp',
            target: 'Piranha minore',
            mode: 'immediato',
            duration: '3',
          ),
        ],
    ],
    minimums: [2, 5, 11],
    maximums: [2, 5, 11],
    cd: [5, 5, 5],
  ),
  'raggio_angelico': _planarMove(
    'Raggio Angelico',
    'Scaglia un raggio lineare di energia angelica. Formula danno: Danno base dell’attacco + Karma dell’attaccante + valore assoluto del Karma negativo del bersaglio. Moltiplicatore dopo la somma: ×2 contro Demoni, ×1,5 contro Diavoli, ×1,3 contro Arcidiavoli; nessun moltiplicatore contro altri bersagli. Risolve una sola difesa e rispetta resistenze, Scudi e regole dei critici. Il Master può modificare costo, danno base, recupero e moltiplicatori nella skill salvata.',
    'angelico',
    'danno',
    [
      for (var form = 0; form < 3; form++)
        [
          MonsterTechniqueEffect(
            'danno',
            '0',
            mode: 'prossima_azione',
            duration: '',
          ),
        ],
    ],
    minimums: [1, 5, 11],
    maximums: [1, 5, 11],
    cd: [3, 4, 5],
  ),
  'bringi_seeds': _planarMove(
    'Guance piene',
    'Risposta automatica alla prima aggressione: 1d20 semi da 1 Vita; dopo tre colpi subiti 1d100+20 semi, poi ricomincia il conteggio. Pacifico/neutrale, non provoca il combattimento.',
    'natura',
    'danno',
    List.generate(3, (_) => <MonsterTechniqueEffect>[]),
    minimums: [0, 0, 0],
    maximums: [0, 0, 0],
    cd: [0, 0, 0],
  ),
  'rock_eater': _planarMove(
    'Mangia Roccia',
    'Si forma una bocca che consuma fino a 10 metri cubi di roccia non magica. Non distrugge creature né oggetti equipaggiati.',
    'roccia',
    'movimento',
    List.generate(3, (_) => <MonsterTechniqueEffect>[]),
    minimums: [1, 1, 1],
    maximums: [1, 1, 1],
    cd: [3, 3, 3],
  ),
  'rocket_flight': _planarMove(
    'Volo Sfrecciante',
    'Due razzetti spingono fino a 100 metri a circa 30 km/h nell’arco di due turni.',
    'vento',
    'movimento',
    List.generate(3, (_) => <MonsterTechniqueEffect>[]),
    minimums: [1, 1, 1],
    maximums: [1, 1, 1],
    cd: [4, 4, 4],
  ),
  'ogle_split': _planarMove(
    'Dispersione illusiva',
    'Ogle si disperde in copie senza Vita reale o azioni proprie. Un attacco diretto a una copia la dissolve.',
    'psichico',
    'movimento',
    List.generate(3, (_) => <MonsterTechniqueEffect>[]),
    cd: [3, 4, 5],
  ),
  'psycho_bark': _planarMove(
    'Latrito psicoillusivo',
    'Le immagini abbaiano da direzioni diverse: una difesa fallita disorienta per un turno.',
    'psichico',
    'controllo',
    List.generate(3, (_) => <MonsterTechniqueEffect>[]),
    cd: [3, 4, 5],
  ),
  'illusion_stun': _planarMove(
    'Urto delle copie',
    'Il corpo vero attraversa le copie e colpisce. Su critico positivo stordisce per un turno.',
    'psichico',
    'danno',
    _planarDamageForms([2, 5, 9]),
    cd: [3, 4, 5],
  ),
  'fiaccolata': _planarMove(
    'Fiaccolata',
    'Lancia una fiaccola e ne prende un’altra dall’inventario. Richiede e consuma una Fiaccola per uso.',
    'fuoco',
    'danno',
    [
      for (final die in ['1d6', '1d8', '1d12'])
        [
          MonsterTechniqueEffect(
            'danno',
            '0',
            dice: die,
            mode: 'prossima_azione',
            duration: '',
          ),
        ],
    ],
    level: 1,
    minimums: [1, 11, 21],
    maximums: [10, 20, 30],
    cd: [1, 1, 2],
  ),
  'topino_backstep': _planarMove(
    'Scatto Arretrante',
    'Scatta all’indietro e prepara una riduzione piatta al prossimo danno ricevuto, pari all’Oculum immesso moltiplicato per la forma.',
    'vento',
    'movimento',
    List.generate(3, (_) => <MonsterTechniqueEffect>[]),
    level: 2,
    minimums: [1, 4, 9],
    maximums: [3, 8, 30],
    cd: [2, 3, 4],
  ),
  'cura_topesca': _planarMove(
    'Cura topesca',
    'Cura tutti gli alleati del party, entro la loro Vita massima, di Oculum immesso ×1/×2/×3.',
    'natura',
    'cura',
    List.generate(3, (_) => <MonsterTechniqueEffect>[]),
    level: 3,
    minimums: [1, 2, 3],
    maximums: [1, 2, 3],
    cd: [3, 4, 5],
  ),
  'topino_poison_knife': _planarMove(
    'Coltello avvelenato',
    'Lancia il coltello nascosto: danno aggiuntivo pari a Oculum; il colpo riuscito avvelena per due turni.',
    'veleno',
    'danno',
    _planarDamageForms([0, 0, 0]),
    level: 9,
    minimums: [1, 2, 3],
    maximums: [1, 2, 3],
    cd: [4, 5, 6],
  ),
  'bell_fate_paralysis': _planarMove(
    'Rintocco del Fato',
    'Muove la campanella: il bersaglio difende contro DT 25. Se fallisce subisce Paralisi dal Fato per 4 turni. Un 20 naturale aggiunge Stun per un turno e cura gli alleati di Volontà.',
    'sonoro',
    'controllo',
    List.generate(3, (_) => <MonsterTechniqueEffect>[]),
    minimums: [3, 3, 3],
    maximums: [3, 3, 3],
    cd: [5, 5, 5],
  ),
  'critical_stun': _planarMove(
    'Eco della Campana',
    'Lo Stun del rintocco si applica automaticamente soltanto su critico: non è una seconda azione da attivare.',
    'sonoro',
    'controllo',
    List.generate(3, (_) => <MonsterTechniqueEffect>[]),
    cd: [5, 5, 5],
  ),
  'will_heal': _planarMove(
    'Risonanza curativa',
    'La cura degli alleati è inclusa automaticamente nel critico del Rintocco del Fato.',
    'sonoro',
    'cura',
    List.generate(3, (_) => <MonsterTechniqueEffect>[]),
    cd: [5, 5, 5],
  ),
  'obliterated_devil_annihilation': _planarMove(
    'Occhi dell’Annichilimento',
    'Il terzo occhio si apre: un 20 naturale dopo una difesa fallita impone il Titolo Malanno Annichilimento, @res-30%, per tre Riposi Lunghi. Non si cumula: una nuova applicazione rinnova la durata.',
    'oblio',
    'controllo',
    List.generate(3, (_) => <MonsterTechniqueEffect>[]),
    minimums: [3, 3, 3],
    maximums: [3, 3, 3],
    cd: [1, 1, 1],
  ),
  'blade_skull_critical': _planarMove(
    'Filo del Teschio',
    'Passiva: con armi da taglio anche il 19 naturale può essere critico positivo; il tiro deve comunque colpire.',
    'fisico',
    'danno',
    List.generate(3, (_) => <MonsterTechniqueEffect>[]),
    minimums: [0, 0, 0],
    maximums: [0, 0, 0],
    cd: [0, 0, 0],
  ),
};
