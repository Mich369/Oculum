part of 'monster_book.dart';

final _rebirthRageEvergreenEntries = <MonsterBookEntry>[
  _canonicalCreature(
    'fuocherelli',
    'Fuocherelli',
    '',
    ['mezzano', 'demoniaco', 'foresta_elementale'],
    'fuoco',
    [1, 1, 1, 2],
    0,
    'Un piccolo essere umanoide di brace rossa e scura, con due corna corte, occhi incandescenti e una bocca larga piena di denti aguzzi. Fiamme vive gli formano i capelli e avvolgono le mani artigliate; fra le scaglie carbonizzate corrono fenditure arancioni. Ha gambe piegate, piedi unghiuti e una coda corta che lascia fumo. È molto facile da abbattere, ma il suo ultimo guizzo può incendiare chi gli sta vicino. L’Acqua lo spegne in parte e gli impedisce di usare skill Fuoco per una propria azione.',
    'Acqua: spegne le fiamme e impedisce Seconda Vita.',
    ['fuocherelli_dart', 'fuocherelli_second_life', 'fuocherelli_reanimate'],
    'brace_spenta_fuocherelli',
    resistances: {'fuoco': 'resistenza', 'acqua': 'debolezza'},
  ).copyWith(
    encounterRules: {
      'authoredCanonical': true,
      'difficulty': 'molto_facile',
      'huntReward': {'kills': 10, 'skillId': 'fuocherelli_dart'},
      'finisherReward': {
        'condition': 'element:acqua',
        'skillId': 'fuocherelli_reanimate',
      },
      'naturalScrollDrops': {
        'fuocherelli_second_life': {'minimum': 20, 'maximum': 20},
      },
    },
  ),
  _canonicalCreature(
    'feralis',
    'Feralis',
    '',
    ['foresta_elementale', 'mezzano'],
    'natura',
    [9, 7, 8, 6],
    5,
    'Un enorme essere bestiale eretto, dal corpo massiccio e muscoloso e dal volto feroce simile a quello di un lupo. Una criniera lunghissima blu notte e nera si apre all’indietro in ciocche appuntite; il petto ha un folto pelo avorio e le fauci spalancate mostrano zanne bianche. Gli occhi brillano di turchese. Grandi placche appuntite color rame rossastro sporgono dalle spalle e rivestono gli avambracci, attraversate da segni luminosi azzurri a spirale. Le mani enormi terminano in artigli lunghi e ricurvi; due zampe posteriori robuste e pelose sostengono il corpo, con piedi larghi unghiuti. Una coda lunga e folta curva dietro il fianco. Non indossa vestiti né impugna armi. Abita la foresta luminosa fra alberi contorti e vegetazione rosa e azzurra. È un Mini Boss difficile, vulnerabile all’Oblio.',
    'Oblio: la sua energia spezza il ciclo di rigenerazione naturale.',
    [
      'feralis_claw',
      'feralis_fury',
      'feralis_kill_rebirth',
      'feralis_elemental_resistance',
    ],
    'ciocca_luminosa_feralis',
    resistances: {'oblio': 'debolezza'},
  ).copyWith(
    isMiniBoss: true,
    encounterRules: {
      'authoredCanonical': true,
      'difficulty': 'difficile',
      'miniBossFirstElementExcludesOwn': true,
      'huntReward': {'kills': 5, 'skillId': 'feralis_kill_rebirth'},
      'finisherReward': {
        'condition': 'common_natural_element',
        'skillId': 'feralis_elemental_resistance',
      },
      'naturalScrollDrops': {
        'feralis_fury': {'minimum': 20, 'maximum': 20},
      },
    },
  ),
  _canonicalCreature(
    'granscostumato',
    'GranScostumato',
    '',
    ['mezzano', 'postea'],
    'fisico',
    [9, 8, 9, 5],
    5,
    'Un bandito roditore enorme, con criniera irta color oro, orecchie grandi dall’interno rosa, baffi lunghi e muso spalancato in un ringhio di zanne. Il petto e l’addome sono scoperti e molto muscolosi; una giacca di cuoio marrone strappata lascia libere le spalle. Porta pantaloni kaki al ginocchio, cinturone con tasche, guanti senza dita e piedi artigliati. Una lunga coda rosa nuda si curva dietro le gambe. Impugna un cannone di ferro gigantesco, legato con fasce di cuoio, e alterna spari a colpi ravvicinati e insulti. È difficile: a differenza degli Scostubanditi può uccidere per eccesso di forza. Quando accade esclama «oh merda l’ho rotto».',
    'Le armi da fuoco interrompono la sua carica e sfruttano la sua fragilità.',
    [
      'gran_cannon_strike',
      'gran_leave',
      'gran_cannon',
      'gran_unstun',
      'gran_base_counter',
    ],
    'ferro_cannone_granscostumato',
  ).copyWith(
    encounterRules: {
      'authoredCanonical': true,
      'difficulty': 'difficile',
      'firearmWeaknessPercent': 50,
      'huntReward': {'kills': 5, 'skillId': 'gran_cannon'},
      'finisherRewards': [
        {'condition': 'stunning_attack', 'skillId': 'gran_unstun'},
        {'condition': 'base_attack', 'skillId': 'gran_base_counter'},
      ],
      'naturalScrollDrops': {
        'gran_leave': {'minimum': 20, 'maximum': 20},
      },
    },
  ),
  _canonicalCreature(
    'sempre_verde',
    'Sempre verde',
    '',
    ['mezzano', 'foresta_elementale'],
    'natura',
    [2, 1, 3, 2],
    1,
    'Un combattente snello e silenzioso, avvolto in strati di stoffa verde scuro. Il cappuccio nasconde una maschera di legno allungata, con due grandi fori neri per gli occhi e sottili fenditure verticali sul volto. Ai lati spuntano due piccole punte chiare. Fasce e imbottiture verdi proteggono spalle e ginocchia; lunghi nastri rossi si sciolgono dalla vita e dal collo. Impugna due lame corte ricurve, una per mano, e si muove fra tronchi e nebbia con balzi bassi. È un mostro facile; sotto il costume si nasconde una presenza che può essere colpita nell’anima senza lacerare gli abiti.',
    'La maschera di legno: è esposta quando allarga le braccia.',
    ['evergreen_leaves', 'evergreen_dodge', 'evergreen_disguise'],
    'foglia_acciaiata_sempre_verde',
  ).copyWith(
    encounterRules: {
      'authoredCanonical': true,
      'difficulty': 'facile',
      'huntReward': {'kills': 5, 'skillId': 'evergreen_dodge'},
      'leavesDropTotal': 36,
      'intactCostumeFinisher': 'soul_only',
    },
  ),
];

final _rebirthRageEvergreenTechniques = <String, MonsterConcreteTechnique>{
  'fuocherelli_dart': _planarMove(
    'Dardo di fuoco',
    'Un dardo diretto contro un nemico. +4/8/12 Danni Fuoco; con critico positivo applica Fuoco per 1d4 turni. Costo fisso 2 Oculum in ogni forma.',
    'fuoco',
    'danno',
    [
      for (var f = 0; f < 3; f++)
        [
          MonsterTechniqueEffect(
            'danno',
            '${4 + f * 4}',
            mode: 'prossima_azione',
            duration: '',
          ),
          const MonsterTechniqueEffect(
            'planar',
            '1',
            target: 'fuocherelli_critical_fire',
            recipient: 'nemico',
            mode: 'immediato',
          ),
        ],
    ],
    minimums: [2, 2, 2],
    maximums: [2, 2, 2],
    cd: [2, 2, 2],
  ),
  'fuocherelli_second_life': _newPassive(
    'Seconda Vita · Open',
    'Passiva Open, una volta per Riposo Lungo. Quando muori senza un colpo finale Acqua esplodi: 10+2×Livello Danni Fuoco a nemici e alleati entro 3 metri. Torni con il 5% della Vita massima, minimo 20 e senza superare il massimo. Scudo I 1d120; II 1d200+Livello; III 1d250+3×Livello. Acqua impedisce completamente l’attivazione.',
    'fuocherelli_second_life',
    [1, 2, 3],
    element: 'fuoco',
  ),
  'fuocherelli_reanimate': _planarMove(
    'Rianimazione',
    'Prima del primo turno personale successivo alla morte di un compagno puoi cedergli Vita reale a scelta, anche tutta. Una Azione o Reazione; oltre il 75% della tua Vita corrente chiede conferma con perdita e residuo esatti. Non crea Vita né la cede oltre il massimo del ricevente.',
    'vita',
    'cura',
    [
      for (var f = 0; f < 3; f++)
        [
          const MonsterTechniqueEffect(
            'planar',
            '1',
            target: 'fuocherelli_reanimate',
            mode: 'immediato',
          ),
        ],
    ],
    costResource: 'nessuna',
    minimums: [0, 0, 0],
    maximums: [0, 0, 0],
    cd: [3, 3, 3],
  ),
  'feralis_claw': _canonicalAttack(
    'Artigli primordiali',
    'Un colpo ravvicinato di artigli, con un solo tiro e un solo bersaglio.',
    'taglio',
    [5, 9, 13],
  ),
  'feralis_fury': _planarMove(
    'Furia Primordiale · Open',
    'Attivabile soltanto a metà Vita o meno. Danni ×2 e danni ricevuti dimezzati; all’attivazione recuperi un quarto dell’Oculum massimo. Dal secondo turno personale paga 3 Oculum e aggiunge +5 Danni/+2 Difesa per ogni turno pagato. Puoi detrasformarti gratuitamente quando vuoi; termina se non puoi pagare o a fine fight.',
    'natura',
    'utility',
    [
      for (var f = 1; f <= 3; f++)
        [
          MonsterTechniqueEffect(
            'planar',
            '$f',
            target: 'feralis_fury',
            mode: 'immediato',
          ),
        ],
    ],
    costResource: 'nessuna',
    minimums: [0, 0, 0],
    maximums: [0, 0, 0],
    cd: [6, 6, 6],
    level: 5,
  ),
  'feralis_kill_rebirth': _newPassive(
    'La tua morte è la mia rinascita',
    'Ogni nemico ucciso direttamente da te cura metà della tua Vita corrente e recupera metà del tuo Oculum corrente, arrotondati per eccesso, entro i massimi. Una sola applicazione per nemico ucciso.',
    'feralis_kill_rebirth',
    [1, 1, 1],
    element: 'natura',
    level: 5,
  ),
  'feralis_elemental_resistance': _newPassive(
    'Resistenza elementale',
    'Per ogni colpo comune ricevuto aumenta di 15 punti la Resistenza a quell’elemento: Fuoco, Acqua, Gelo, Terra, Vento, Fulmine. Ogni elemento cresce separatamente, fino a 150%; a 100% è immune e oltre il danno residuo cura, massimo 50%. Si azzera a fine fight. La normale resistenza del Mini Boss al primo elemento diverso dai propri resta separata.',
    'feralis_elemental_resistance',
    [15, 15, 15],
    element: 'natura',
    level: 5,
  ),
  'gran_cannon_strike': _canonicalAttack(
    'Colpo del cannone',
    'Colpisce con il cannone a distanza o con la sua massa da vicino. I danni possono essere letali.',
    'contundente',
    [6, 10, 14],
  ),
  'gran_leave': _planarMove(
    'Levati dal cazzo!',
    'Un colpo ravvicinato di Schianto +5. Il totale del tiro si aggiunge ai Danni e il bersaglio viene respinto di 2 metri dopo un colpo riuscito. Una sola Azione o Reazione.',
    'contundente',
    'danno',
    [
      for (var f = 1; f <= 3; f++)
        [
          MonsterTechniqueEffect(
            'planar',
            '$f',
            target: 'gran_leave',
            mode: 'immediato',
          ),
        ],
    ],
    costResource: 'volonta',
    minimums: [1, 2, 3],
    maximums: [1, 2, 3],
    cd: [3, 3, 3],
  ),
  'gran_cannon': _planarMove(
    'Vaffanculo!',
    'Genera un cannone gigantesco per una azione. Prima dei danni distrugge uno Scudo critico; se non ce ne sono spezza fino a 150 punti fra Scudo Oculum e Scudo normale, senza danni alla Vita da questa rottura. Il normale colpo successivo infligge +50% danni agli Scudi.',
    'esplosivo',
    'danno',
    [
      for (var f = 1; f <= 3; f++)
        [
          MonsterTechniqueEffect(
            'planar',
            '$f',
            target: 'gran_cannon',
            mode: 'immediato',
          ),
        ],
    ],
    minimums: [3, 5, 7],
    maximums: [3, 5, 7],
    cd: [4, 4, 4],
    level: 5,
  ),
  'gran_unstun': _planarMove(
    'Ma Porca Troia!',
    'Ti riprendi da qualsiasi Stun. Gratuita in statistiche, Azioni e Reazioni; disponibile anche mentre lo Stun impedisce di agire. CD condiviso 4 turni.',
    'fisico',
    'utility',
    [
      for (var f = 0; f < 3; f++)
        [
          const MonsterTechniqueEffect(
            'planar',
            '1',
            target: 'gran_unstun',
            mode: 'immediato',
          ),
        ],
    ],
    costResource: 'nessuna',
    minimums: [0, 0, 0],
    maximums: [0, 0, 0],
    cd: [4, 4, 4],
  ),
  'gran_base_counter': _newPassive(
    'Ti Faccio il Culo, Pezzo Di Merda!',
    'Ogni nove attacchi base effettivamente eseguiti nella stessa battaglia recuperi 1 Oculum, anche se vengono schivati. Conta una sola volta l’attacco, indipendentemente dai bersagli. Il conteggio riparte a fine fight.',
    'gran_base_counter',
    [9, 9, 9],
  ),
  'evergreen_leaves': _planarMove(
    'Foglie Lama',
    'Una raffica di 1d20 + Oculum speso foglie, ciascuna da 2 Danni: un solo tiro contro un bersaglio e un unico danno totale, con normali Difesa e resistenze. Totale 2×(1d20+Oculum speso).',
    'taglio',
    'danno',
    [
      for (var f = 0; f < 3; f++)
        [
          const MonsterTechniqueEffect(
            'planar',
            'oculum_spent',
            target: 'evergreen_leaves',
            mode: 'immediato',
            duration: '',
          ),
        ],
    ],
    minimums: [1, 5, 11],
    maximums: [4, 10, 40],
    cd: [2, 2, 3],
  ),
  'evergreen_dodge': _planarMove(
    'Schivata rapida',
    'Vantaggio alto al prossimo tiro di Difesa con Riflessi. Una sola difesa complessiva, senza una seconda Azione o Reazione. Costo fisso 1 Oculum, CD condiviso 2 turni.',
    'vento',
    'difesa',
    [
      for (var f = 0; f < 3; f++)
        [
          const MonsterTechniqueEffect(
            'planar',
            '6',
            target: 'evergreen_dodge',
            mode: 'immediato',
          ),
        ],
    ],
    minimums: [1, 1, 1],
    maximums: [1, 1, 1],
    cd: [2, 2, 2],
  ),
  'evergreen_disguise': _newPassive(
    'Costume dei Sempre Verde',
    'Finché non attacchi un mostro, ogni mostro ha il 50% a ogni proprio turno di non riuscire a sceglierti come bersaglio. Può colpire altri e non perde risorse. Il tuo primo attacco contro un mostro termina il travestimento per lo scontro.',
    'evergreen_disguise',
    [50, 50, 50],
    element: 'natura',
  ),
};
