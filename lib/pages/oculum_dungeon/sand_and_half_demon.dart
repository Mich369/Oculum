part of 'monster_book.dart';

// The supplied images are descriptive references, following the Book's rule.
// Initial numbers are editable balance values, not additional canonical rules.
final _sandAndHalfDemonEntries = <MonsterBookEntry>[
  _authoredPlanar(
    'mostro_sabbia',
    'Mostro di sabbia',
    ['mezzano'],
    'terra',
    'Miniboss dal corpo compatto di sabbia ocra, segnato da fessure scure. Ha quattro arti artigliati, piccole corna, occhi chiari e una grande coda arcuata di sabbia stratificata. Si muove nelle dune e fra rovine insabbiate; difende il proprio territorio con artigli e corazze di sabbia.',
    'Il nucleo di sabbia compatta esposto fra lo sterno e il ventre quando solleva entrambe le zampe anteriori.',
    [8, 5, 8, 2],
    4,
    false,
    true,
    [
      'sand_beast_claw',
      'sand_beast_armor',
      'sand_tail_attack',
      'sand_tail_parry',
    ],
    {
      'authoredCanonical': true,
      'dispositions': ['ostile', 'territoriale'],
      'habitats': ['dune', 'rovine insabbiate'],
    },
    const {},
  ).copyWith(
    dropIds: ['sabbia_compatta_bestia'],
    dropChances: {'sabbia_compatta_bestia': 50},
    classificationTags: ['Bestia', 'Miniboss', 'Sabbia'],
  ),
  _authoredPlanar(
    'gigante_sabbia',
    'Gigante di sabbia',
    ['mezzano'],
    'terra',
    'Gigante umanoide molto largo e bestiale, composto di sabbia ocra compatta '
        'con segni scuri. Possiede due braccia massicce artigliate, due gambe, '
        'due corna e la grande coda stratificata della specie. Il volto compatto '
        'ha segni scuri attorno agli occhi, muso corto, espressione vigile e '
        'denti grigio carbone. Il petto è pieno e solido, senza nucleo esposto. '
        'La coda può colpire o parare gratuitamente con un solo recupero condiviso. '
        'Teme il Fuoco; un doppio critico di Lava che raggiunge la Vita può '
        'vetrificarlo e altrimenti ne dimezza temporaneamente la Materia.',
    'Nessun punto debole anatomico. La sua fragilità è il Fuoco.',
    [14, 7, 12, 4],
    6,
    false,
    true,
    [
      'sand_beast_claw',
      'sand_beast_armor',
      'sand_tail_attack',
      'sand_tail_parry',
    ],
    {
      'authoredCanonical': true,
      'dispositions': ['ostile', 'territoriale'],
      'habitats': ['dune', 'rovine insabbiate'],
      'sandRules': {
        'cooldownPersonalTurns': 2,
        'receivedDamagePercent': 65,
        'lavaKillPercent': 50,
        'matterDurationTurns': 3,
        'matterDivisor': 2,
        'parryCriticalReference': 'resistenza',
      },
    },
    const {'fuoco': 'Fragilità'},
  ).copyWith(
    dropIds: ['sabbia_compatta_bestia'],
    dropChances: {'sabbia_compatta_bestia': 50},
    classificationTags: ['Gigante', 'Miniboss', 'Sabbia'],
  ),
  _authoredPlanar(
    'mezzo_demone_cosciente',
    'Mezzo demone cosciente',
    ['mezzano', 'demoniaco'],
    'taglio',
    'Creatura cosciente per metà demone, dal corpo umanoide atletico con pelle oliva opaca e rilievi angolari sulle spalle. La testa glabra ha lineamenti severi, due occhi vigili e due grandi corna chiare a lama, rivolte all’indietro. Possiede due braccia artigliate e due gambe robuste. Una grande bocca organica verticale occupa il centro del collo e del torace, bordata da denti chiari; il volto superiore rimane distinto e cosciente. Fasce di tessuto chiaro consumato gli avvolgono la vita. Può essere incontrato aggressivo, ma conserva coscienza e capacità di scegliere: non è una bestia priva di volontà.',
    'La bocca dello stomaco: la zona epigastrica al centro dell’addome superiore, sotto lo sterno.',
    [3, 4, 3, 2],
    2,
    false,
    false,
    ['half_demon_rake', 'half_demon_guard'],
    {
      'authoredCanonical': true,
      'conscious': true,
      'dispositions': ['ostile', 'neutrale'],
    },
    const {},
  ).copyWith(
    dropIds: ['artiglio_mezzo_demone'],
    dropChances: {'artiglio_mezzo_demone': 50},
    classificationTags: ['Mezzo demone', 'Cosciente'],
  ),
  _authoredPlanar(
    'shadow_devil',
    'Shadow Devil',
    ['shadow_hell'],
    'oscuro',
    'Un diavolo contaminato dall’Oblio dello Shadow Hell. La figura scura è attraversata da filamenti d’ombra, con corna ricurve, arti lunghi e mani ad artiglio; nella testa senza occhi visibili risalta una fila di denti chiari. La contaminazione lo tormenta: quando viene ucciso, il suo uccisore sente gratitudine da parte sua.',
    'Il nodo di ombra addensata al centro del torace, fra i filamenti che tengono insieme il corpo.',
    [4, 4, 3, 3],
    3,
    false,
    false,
    ['shadow_devil_claws', 'shadow_devil_veil'],
    {
      'authoredCanonical': true,
      'dispositions': ['ostile'],
      'oblivionContaminated': true,
      'magicalLuckOnDefeat': {'killer': 3, 'others': 1},
      'defeatMessage':
          'Senti gratitudine da parte del diavolo: la morte lo ha liberato dalla contaminazione dell’Oblio dello Shadow Hell.',
    },
    const {},
  ).copyWith(
    dropIds: ['filamento_shadow_devil'],
    dropChances: {'filamento_shadow_devil': 50},
    classificationTags: ['Diavolo', 'Contaminato dall’Oblio'],
  ),
];

const _sandAndHalfDemonTechniques = <String, MonsterConcreteTechnique>{
  'sand_tail_attack': MonsterConcreteTechnique(
    name: 'Sferzata della coda',
    action:
        'Prepara una sferzata a contatto: il prossimo attacco singolo con '
        'la coda è gratuito anche fuori turno. Condivide con la parata una '
        'disponibilità ogni due turni personali, senza avanzare la turnistica.',
    element: 'terra',
    kind: 'danno',
    requiredLevel: 0,
    costResource: 'nessuna',
    minimums: [0, 0, 0],
    maximums: [0, 0, 0],
    cooldownValues: [0, 0, 0],
    forms: [[], [], []],
  ),
  'sand_tail_parry': MonsterConcreteTechnique(
    name: 'Riparo della coda',
    action:
        'Para un colpo senza tiro e senza Azioni o Reazioni, ricevendo '
        'il 65% dei Danni dopo la Difesa e prima degli Scudi. Condivide con '
        'la sferzata una disponibilità ogni due turni personali.',
    element: 'terra',
    kind: 'difesa',
    requiredLevel: 0,
    costResource: 'nessuna',
    minimums: [0, 0, 0],
    maximums: [0, 0, 0],
    cooldownValues: [0, 0, 0],
    forms: [[], [], []],
  ),
  'shadow_devil_claws': MonsterConcreteTechnique(
    name: 'Artigli contaminati',
    action: 'Sferra gli artigli contro un solo bersaglio a contatto',
    element: 'oscuro',
    kind: 'danno',
    requiredLevel: 3,
    costResource: 'oculum',
    minimums: [1, 2, 3],
    maximums: [1, 2, 3],
    cooldownValues: [2, 2, 3],
    forms: [
      [MonsterTechniqueEffect('danno', '8', mode: 'prossima_azione')],
      [MonsterTechniqueEffect('danno', '14', mode: 'prossima_azione')],
      [MonsterTechniqueEffect('danno', '20', mode: 'prossima_azione')],
    ],
  ),
  'shadow_devil_veil': MonsterConcreteTechnique(
    name: 'Velo lacerato',
    action: 'Raccogli i filamenti d’ombra attorno al corpo per proteggerti',
    element: 'oscuro',
    kind: 'difesa',
    requiredLevel: 3,
    costResource: 'volonta',
    minimums: [1, 2, 3],
    maximums: [1, 2, 3],
    cooldownValues: [3, 3, 4],
    forms: [
      [MonsterTechniqueEffect('difesa', '5')],
      [MonsterTechniqueEffect('difesa', '8')],
      [MonsterTechniqueEffect('difesa', '12')],
    ],
  ),
  'sand_beast_claw': MonsterConcreteTechnique(
    name: 'Artiglio abrasivo',
    action: 'Colpisci con un artiglio di sabbia un bersaglio a contatto',
    element: 'terra',
    kind: 'danno',
    requiredLevel: 4,
    costResource: 'materia',
    minimums: [1, 2, 3],
    maximums: [1, 2, 3],
    cooldownValues: [2, 2, 3],
    forms: [
      [MonsterTechniqueEffect('danno', '8', mode: 'prossima_azione')],
      [MonsterTechniqueEffect('danno', '14', mode: 'prossima_azione')],
      [MonsterTechniqueEffect('danno', '22', mode: 'prossima_azione')],
    ],
  ),
  'sand_beast_armor': MonsterConcreteTechnique(
    name: 'Corazza di sabbia',
    action: 'Addensa la sabbia sul corpo in una protezione consumabile',
    element: 'terra',
    kind: 'scudo',
    requiredLevel: 4,
    costResource: 'materia',
    minimums: [1, 2, 3],
    maximums: [1, 2, 3],
    cooldownValues: [3, 3, 4],
    forms: [
      [MonsterTechniqueEffect('scudo', '15')],
      [MonsterTechniqueEffect('scudo', '25')],
      [MonsterTechniqueEffect('scudo', '40')],
    ],
  ),
  'half_demon_rake': MonsterConcreteTechnique(
    name: 'Sferzata artigliata',
    action: 'Sferra un artiglio contro un solo bersaglio a contatto',
    element: 'taglio',
    kind: 'danno',
    requiredLevel: 2,
    costResource: 'oculum',
    minimums: [1, 2, 3],
    maximums: [1, 2, 3],
    cooldownValues: [2, 2, 3],
    forms: [
      [MonsterTechniqueEffect('danno', '6', mode: 'prossima_azione')],
      [MonsterTechniqueEffect('danno', '10', mode: 'prossima_azione')],
      [MonsterTechniqueEffect('danno', '16', mode: 'prossima_azione')],
    ],
  ),
  'half_demon_guard': MonsterConcreteTechnique(
    name: 'Guardia cosciente',
    action:
        'Copri la bocca dello stomaco con gli avambracci e rinforza la difesa',
    element: 'fisico',
    kind: 'difesa',
    requiredLevel: 2,
    costResource: 'volonta',
    minimums: [1, 2, 3],
    maximums: [1, 2, 3],
    cooldownValues: [3, 3, 4],
    forms: [
      [MonsterTechniqueEffect('difesa', '5')],
      [MonsterTechniqueEffect('difesa', '8')],
      [MonsterTechniqueEffect('difesa', '12')],
    ],
  ),
};
