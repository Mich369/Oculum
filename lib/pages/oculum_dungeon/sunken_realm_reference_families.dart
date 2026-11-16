part of 'monster_book.dart';

const _sunkenReferenceBody = {'id': 'body', 'group': 'body', 'label': 'Corpo'};
const _sunkenReferenceHead = {'id': 'head', 'group': 'head', 'label': 'Testa'};
const _sunkenReferenceEyes = [
  {'id': 'eyes_1', 'group': 'eyes', 'label': 'Occhio destro', 'side': 'right'},
  {'id': 'eyes_2', 'group': 'eyes', 'label': 'Occhio sinistro', 'side': 'left'},
];
const _sunkenReferenceHumanoidLimbs = [
  {'id': 'arms_1', 'group': 'arms', 'label': 'Braccio destro', 'side': 'right'},
  {
    'id': 'arms_2',
    'group': 'arms',
    'label': 'Braccio sinistro',
    'side': 'left',
  },
  {'id': 'legs_1', 'group': 'legs', 'label': 'Gamba destra', 'side': 'right'},
  {'id': 'legs_2', 'group': 'legs', 'label': 'Gamba sinistra', 'side': 'left'},
];
const _sunkenReferenceFishGills = [
  {
    'id': 'gills_1',
    'group': 'gills',
    'label': 'Branchia destra',
    'side': 'right',
    'weak': true,
  },
  {
    'id': 'gills_2',
    'group': 'gills',
    'label': 'Branchia sinistra',
    'side': 'left',
    'weak': true,
  },
];
const _sunkenReferenceAmphibianLegs = [
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

const _sunkenFirstFamilies = <_SunkenFamily>[
  _SunkenFamily(
    id: 'affogato_sentinella_di_basalto',
    name: 'Luxryf',
    areaId: 'corallo_cavo',
    description:
        'Grande costrutto di basalto nero con due braccia e due gambe. Una spalla porta lastroni lunghi, l’altra colonne spezzate. Dietro le costole di pietra pende una lanterna di corniola sospesa ad anelli di bronzo. Una maschera di pietra ripara il volto.',
    aggression:
        'Sbarra il passaggio con la propria mole e carica chi tenta di attraversarlo.',
    anatomy: [
      {
        'id': 'body',
        'group': 'body',
        'label': 'Torace fra le costole',
        'weak': true,
      },
      {'id': 'head', 'group': 'head', 'label': 'Testa mascherata'},
      ..._sunkenReferenceHumanoidLimbs,
    ],
    nameChoices: [
      (name: 'Saxybulwark', meaning: 'saxum + bulwark, bastione di roccia'),
      (name: 'Luxreef', meaning: 'lux + reef, scogliera luminosa'),
    ],
    base: _SunkenForm(
      element: 'roccia',
      stats: [7, 3, 5, 1],
      moves: [
        _SunkenMove(
          id: 'basaltcrush',
          name: 'Basaltcrush',
          kind: 'danno',
          description: 'Abbatte il braccio a lastroni sul bersaglio.',
        ),
        _SunkenMove(
          id: 'saxyrampart',
          name: 'Saxyrampart',
          kind: 'difesa',
          description: 'Sovrappone i lastroni delle spalle davanti al torace.',
        ),
      ],
    ),
    variants: [
      _SunkenForm(
        label: 'di Buio',
        element: 'buio',
        stats: [7, 4, 4, 2],
        description:
            'Il basalto è nero opaco e la corniola delle costole sfuma nel viola spento.',
        aggression:
            'Resta sotto gli archi e si sporge all’ultimo per sbarrare il percorso con un pugno.',
        moves: [
          _SunkenMove(
            id: 'umbramaul',
            name: 'Umbramaul',
            kind: 'danno',
            description: 'Sferra un pugno avvolto nel Buio.',
          ),
          _SunkenMove(
            id: 'noctylock',
            name: 'Noctylock',
            kind: 'scudo',
            description: 'Compatta una cortina scura davanti alle costole.',
          ),
        ],
      ),
      _SunkenForm(
        label: 'di Fulmine',
        element: 'fulmine',
        stats: [6, 3, 5, 3],
        description:
            'Vene color rame percorrono le costole e brevi scintille restano vicine agli anelli di bronzo.',
        aggression:
            'Carica con una spalla abbassata e scarica l’energia della lanterna nel colpo.',
        moves: [
          _SunkenMove(
            id: 'fulgurcrush',
            name: 'Fulgurcrush',
            kind: 'danno',
            description: 'Carica un pugno di Fulmine prima dell’impatto.',
          ),
          _SunkenMove(
            id: 'bronzyrush',
            name: 'Bronzyrush',
            kind: 'iniziativa',
            description: 'Si dà slancio agganciando le dita a una colonna.',
          ),
        ],
      ),
    ],
  ),
  _SunkenFamily(
    id: 'affogato_tessitore_della_corrente',
    name: 'Undathread',
    areaId: 'fronde_eiva',
    description:
        'Figura sottile di alghe intrecciate ed Eiva. Ha due braccia con tre dita di giunco ciascuna, due gambe appuntite, una maschera di madreperla a foglia con due fori e una sciarpa che segue la corrente.',
    aggression:
        'Si accosta dal lato a monte e trafigge gli intrusi torcendo la corrente fra le dita.',
    anatomy: [
      _sunkenReferenceBody,
      {
        'id': 'head',
        'group': 'head',
        'label': 'Testa mascherata',
        'weak': true,
      },
      ..._sunkenReferenceHumanoidLimbs,
    ],
    nameChoices: [
      (name: 'Undathread', meaning: 'unda + thread, filo d’onda'),
      (name: 'Texyflow', meaning: 'textor + flow, tessitore della corrente'),
    ],
    base: _SunkenForm(
      element: 'acqua',
      stats: [3, 5, 4, 3],
      moves: [
        _SunkenMove(
          id: 'undalash',
          name: 'Undalash',
          kind: 'danno',
          description: 'Tende un filo d’Eiva fra le dita e lo usa come sferza.',
        ),
        _SunkenMove(
          id: 'textorweave',
          name: 'Textorweave',
          kind: 'difesa',
          description: 'Intreccia due flussi d’Eiva davanti alla maschera.',
        ),
      ],
    ),
    variants: [
      _SunkenForm(
        label: 'di Buio',
        element: 'buio',
        stats: [3, 5, 3, 4],
        description:
            'La maschera perde lucentezza. Sciarpa e filamenti assumono un color prugna quasi nero.',
        aggression:
            'Aspetta fra i filamenti più scuri e sferza da dietro un pilastro sommerso.',
        moves: [
          _SunkenMove(
            id: 'umbrathread',
            name: 'Umbrathread',
            kind: 'danno',
            description: 'Fa scattare fra due pilastri un filo di Buio.',
          ),
          _SunkenMove(
            id: 'caecyveil',
            name: 'Caecyveil',
            kind: 'stato_su_critico',
            conditionId: 'accecato',
            description:
                'Intrappola il viso del bersaglio in un lembo d’ombra.',
          ),
        ],
      ),
      _SunkenForm(
        label: 'Spirituale',
        element: 'spirituale',
        stats: [3, 5, 3, 5],
        description:
            'L’intreccio è malva pallido e la madreperla è attraversata da sottili venature d’argento.',
        aggression:
            'Si lancia verso gli intrusi con un intreccio spettrale serrato fra le mani.',
        moves: [
          _SunkenMove(
            id: 'animyweft',
            name: 'Animyweft',
            kind: 'danno',
            description: 'Infligge un colpo Spirituale con l’intreccio.',
          ),
          _SunkenMove(
            id: 'spiryshroud',
            name: 'Spiryshroud',
            kind: 'scudo',
            description:
                'Avvolge il busto in più strati di filamenti spirituali.',
          ),
        ],
      ),
    ],
  ),
  _SunkenFamily(
    id: 'affogato_palmatore_dei_nastri',
    name: 'Palmatore dei nastri',
    areaId: 'fronde_eiva',
    description:
        'Anfibio turchese dal ventre chiaro, corpo largo e basso, due occhi ambrati, quattro zampe a pagaia, coda corta e arrotondata e una membrana a nastro per fianco. Le macchie sono color corallo.',
    aggression:
        'Si schiaccia contro la roccia, poi scatta dalle fronde e colpisce lungo il fianco.',
    anatomy: [
      _sunkenReferenceBody,
      _sunkenReferenceHead,
      ..._sunkenReferenceEyes,
      ..._sunkenReferenceAmphibianLegs,
      {
        'id': 'flank_ribbon_right',
        'group': 'membranes',
        'label': 'Membrana destra',
        'side': 'right',
        'weak': true,
      },
      {
        'id': 'flank_ribbon_left',
        'group': 'membranes',
        'label': 'Membrana sinistra',
        'side': 'left',
        'weak': true,
      },
      {'id': 'tail', 'group': 'tail', 'label': 'Coda corta'},
    ],
    nameChoices: [
      (name: 'Pynnasway', meaning: 'pinna + sway, pinne ondeggianti'),
      (name: 'Velypaddle', meaning: 'velum + paddle, pagaia a vela'),
    ],
    base: _SunkenForm(
      element: 'acqua',
      stats: [4, 3, 5, 2],
      moves: [
        _SunkenMove(
          id: 'pynnasweep',
          name: 'Pynnasweep',
          kind: 'danno',
          description: 'Colpisce di taglio con il nastro del fianco.',
        ),
        _SunkenMove(
          id: 'velypivot',
          name: 'Velypivot',
          kind: 'iniziativa',
          description:
              'Raccoglie le quattro zampe a pagaia per virare in fretta.',
        ),
      ],
    ),
    variants: [
      _SunkenForm(
        label: 'di Natura',
        element: 'natura',
        stats: [4, 3, 6, 2],
        description:
            'Le membrane sono verdi come foglie, con nervature opache e macchie di rame sul dorso.',
        aggression:
            'Si nasconde fra le foglie e balza con le membrane rigide per colpire di taglio.',
        moves: [
          _SunkenMove(
            id: 'folyyslice',
            name: 'Folyyslice',
            kind: 'danno',
            description: 'Agita una membrana a foglia come un bordo affilato.',
          ),
          _SunkenMove(
            id: 'radixbrace',
            name: 'Radixbrace',
            kind: 'difesa',
            description: 'Fa presa sul fondo e stringe le membrane ai fianchi.',
          ),
        ],
      ),
      _SunkenForm(
        label: 'di Veleno',
        element: 'veleno',
        stats: [4, 4, 4, 3],
        description:
            'I nastri sono viola e verde acido. Piccole ghiandole si raccolgono sul margine del fianco.',
        aggression:
            'Attacca di sghembo e sfiora la pelle del bersaglio con il margine della membrana.',
        moves: [
          _SunkenMove(
            id: 'toxypaddle',
            name: 'Toxypaddle',
            kind: 'danno',
            description: 'Sferra un colpo di Veleno con la membrana.',
          ),
          _SunkenMove(
            id: 'venynick',
            name: 'Venynick',
            kind: 'stato_su_critico',
            conditionId: 'avvelenato',
            description: 'Lascia il veleno delle ghiandole sul bersaglio.',
          ),
        ],
      ),
    ],
  ),
  _SunkenFamily(
    id: 'affogato_faldavela',
    name: 'Faldavela',
    areaId: 'fronde_eiva',
    description:
        'Piccolo anfibio violetto con due occhi, due braccia dotate di membrane aderenti, due zampe posteriori palmate e una sola esca ambrata su uno stelo sotto il mento.',
    aggression:
        'Porta avanti l’esca per attirare la preda e le balza addosso con gli avambracci distesi.',
    anatomy: [
      _sunkenReferenceBody,
      _sunkenReferenceHead,
      ..._sunkenReferenceEyes,
      {
        'id': 'arms_1',
        'group': 'arms',
        'label': 'Braccio destro',
        'side': 'right',
      },
      {
        'id': 'arms_2',
        'group': 'arms',
        'label': 'Braccio sinistro',
        'side': 'left',
      },
      {
        'id': 'legs_1',
        'group': 'legs',
        'label': 'Zampa posteriore destra',
        'side': 'right',
      },
      {
        'id': 'legs_2',
        'group': 'legs',
        'label': 'Zampa posteriore sinistra',
        'side': 'left',
      },
      {
        'id': 'forearm_veil_right',
        'group': 'membranes',
        'label': 'Membrana destra',
        'side': 'right',
      },
      {
        'id': 'forearm_veil_left',
        'group': 'membranes',
        'label': 'Membrana sinistra',
        'side': 'left',
      },
      {
        'id': 'chin_lure',
        'group': 'lure',
        'label': 'Esca sotto il mento',
        'weak': true,
      },
    ],
    nameChoices: [
      (name: 'Mentylure', meaning: 'mentum + lure, esca del mento'),
      (name: 'Pallydveil', meaning: 'pallidus + veil, velo pallido'),
    ],
    base: _SunkenForm(
      element: 'acqua',
      stats: [3, 4, 4, 3],
      moves: [
        _SunkenMove(
          id: 'mentylunge',
          name: 'Mentylunge',
          kind: 'danno',
          description:
              'Protende l’esca e attacca con un balzo avvolto nell’Eiva.',
        ),
        _SunkenMove(
          id: 'velumbrace',
          name: 'Velumbrace',
          kind: 'difesa',
          description: 'Ripiega le membrane davanti al viso e al petto.',
        ),
      ],
    ),
    variants: [
      _SunkenForm(
        label: 'di Gelo',
        element: 'ghiaccio',
        stats: [3, 4, 3, 5],
        description:
            'Il corpo sfuma nel blu ardesia. La brina orla le membrane e la luce dell’esca resta ambrata.',
        aggression:
            'Si tuffa dai gradini freddi e spinge la membrana gelata contro la preda.',
        moves: [
          _SunkenMove(
            id: 'gelysnatch',
            name: 'Gelysnatch',
            kind: 'danno',
            description: 'Colpisce con l’orlo ghiacciato della membrana.',
          ),
          _SunkenMove(
            id: 'glacyveil',
            name: 'Glacyveil',
            kind: 'stato_su_critico',
            conditionId: 'rallentato',
            description: 'Lascia brina sulle giunture del bersaglio.',
          ),
        ],
      ),
      _SunkenForm(
        label: 'di Fulmine',
        element: 'fulmine',
        stats: [3, 3, 4, 5],
        description:
            'Nervature ocra segnano le membrane color prugna. Le scariche restano vicine alle dita e all’esca.',
        aggression:
            'Si stacca dal pilastro e piomba con i due avambracci verso la preda.',
        moves: [
          _SunkenMove(
            id: 'fulgylure',
            name: 'Fulgylure',
            kind: 'danno',
            description: 'Scarica il Fulmine accumulato fra le dita e l’esca.',
          ),
          _SunkenMove(
            id: 'celyrush',
            name: 'Celyrush',
            kind: 'iniziativa',
            description:
                'Scatta spingendo contro la parete con i piedi palmati.',
          ),
        ],
      ),
    ],
  ),
  _SunkenFamily(
    id: 'affogato_rospo_riccio_ocra',
    name: 'Rospo riccio ocra',
    areaId: 'corallo_cavo',
    description:
        'Rospo largo dal dorso coperto di placche ocra a rilievo e dalla gola liscia. Ha due occhi e quattro zampe. Un grosso artiglio a falce spunta fra le dita di ciascuna zampa anteriore.',
    aggression:
        'Si pianta sulla soglia e si slancia con le due falci protese verso chi sale.',
    anatomy: [
      _sunkenReferenceBody,
      _sunkenReferenceHead,
      ..._sunkenReferenceEyes,
      ..._sunkenReferenceAmphibianLegs,
      {
        'id': 'front_hook_right',
        'group': 'claws',
        'label': 'Artiglio a falce destro',
        'side': 'right',
      },
      {
        'id': 'front_hook_left',
        'group': 'claws',
        'label': 'Artiglio a falce sinistro',
        'side': 'left',
      },
      {'id': 'dorsal_plates', 'group': 'shell', 'label': 'Placche dorsali'},
      {'id': 'throat', 'group': 'throat', 'label': 'Gola', 'weak': true},
    ],
    nameChoices: [
      (name: 'Falcytoad', meaning: 'falx + toad, rospo della falce'),
      (name: 'Echynclaw', meaning: 'echinus + claw, artiglio del riccio'),
    ],
    base: _SunkenForm(
      element: 'acqua',
      stats: [6, 3, 5, 2],
      moves: [
        _SunkenMove(
          id: 'falcyswipe',
          name: 'Falcyswipe',
          kind: 'danno',
          description: 'Aggancia e sferza con un artiglio anteriore.',
        ),
        _SunkenMove(
          id: 'echynbrace',
          name: 'Echynbrace',
          kind: 'difesa',
          description: 'Si raccoglie e offre il dorso più duro all’attacco.',
        ),
      ],
    ),
    variants: [
      _SunkenForm(
        label: 'di Roccia',
        element: 'roccia',
        stats: [7, 3, 5, 2],
        description:
            'Le placche hanno l’aspetto di ciottoli di basalto con fessure di calcare. Mantiene le due falci anteriori.',
        aggression:
            'Sale aggrappandosi con le falci e si getta di schiena contro l’intruso.',
        moves: [
          _SunkenMove(
            id: 'saxyhook',
            name: 'Saxyhook',
            kind: 'danno',
            description: 'Sferza con la falce incrostata di pietra.',
          ),
          _SunkenMove(
            id: 'calxshield',
            name: 'Calxshield',
            kind: 'scudo',
            description:
                'Accumula uno strato protettivo di calcare sulle placche.',
          ),
        ],
      ),
      _SunkenForm(
        label: 'd’Acido',
        element: 'acido',
        stats: [5, 4, 5, 3],
        description:
            'Gocce color celadon perlinano fra le placche. I due artigli presentano punte verdi opache.',
        aggression:
            'Si scaglia sui passi altrui e porta l’acido a contatto con la falce anteriore.',
        moves: [
          _SunkenMove(
            id: 'acrydclaw',
            name: 'Acrydclaw',
            kind: 'danno',
            description: 'Incide con una falce bagnata d’Acido.',
          ),
          _SunkenMove(
            id: 'corrodybound',
            name: 'Corrodybound',
            kind: 'iniziativa',
            description:
                'Si tira in avanti lungo la soglia facendo presa con le falci.',
          ),
        ],
      ),
    ],
  ),
  _SunkenFamily(
    id: 'affogato_pesce_scalpellino',
    name: 'Pesce scalpellino',
    areaId: 'corallo_cavo',
    description:
        'Pesce umanoide massiccio con testa a cuneo, due occhi, branchie laterali, due braccia e due gambe palmate. Ha scaglie alle spalle e porta un concio squadrato in una rete di fibre intrecciate.',
    aggression:
        'Punta il concio verso gli intrusi, lo solleva tirando entrambe le corde e lo usa per colpire.',
    anatomy: [
      _sunkenReferenceBody,
      _sunkenReferenceHead,
      ..._sunkenReferenceEyes,
      ..._sunkenReferenceFishGills,
      ..._sunkenReferenceHumanoidLimbs,
      {'id': 'stone_net', 'group': 'equipment', 'label': 'Rete da concio'},
    ],
    weapon: _SunkenWeapon(
      id: 'rete_da_concio',
      name: 'Rete da concio',
      partId: 'stone_net',
      held: true,
    ),
    nameChoices: [
      (name: 'Retymason', meaning: 'rete + mason, muratore della rete'),
      (name: 'Caementfin', meaning: 'caementum + fin, pinna del pietrame'),
    ],
    base: _SunkenForm(
      element: 'acqua',
      stats: [7, 4, 5, 1],
      moves: [
        _SunkenMove(
          id: 'caementslam',
          name: 'Caementslam',
          kind: 'danno',
          description: 'Lancia in avanti il concio con entrambe le corde.',
        ),
        _SunkenMove(
          id: 'retyhold',
          name: 'Retyhold',
          kind: 'difesa',
          description:
              'Tende la rete davanti al petto mentre arretra sulla scala.',
        ),
      ],
    ),
    variants: [
      _SunkenForm(
        label: 'di Metallo',
        element: 'metallo',
        stats: [7, 4, 5, 2],
        description:
            'Scaglie grigio ferro orlano le spalle. Nella stessa rete è legato un blocco di metallo grezzo.',
        aggression:
            'Tiene la rete corta e tenta di schiacciare il bersaglio contro i gradini col blocco.',
        moves: [
          _SunkenMove(
            id: 'ferrymason',
            name: 'Ferrymason',
            kind: 'danno',
            description: 'Fa oscillare il blocco intrappolato nella rete.',
          ),
          _SunkenMove(
            id: 'ferrynet',
            name: 'Ferrynet',
            kind: 'scudo',
            description: 'Fa passare il blocco metallico davanti al corpo.',
          ),
        ],
      ),
      _SunkenForm(
        label: 'di Terra',
        element: 'terra',
        stats: [7, 3, 6, 2],
        description:
            'Le scaglie sono ocra e avorio. La rete contiene un blocco pressato di ghiaia e argilla.',
        aggression:
            'Fa roteare il blocco a livello del petto, cercando un varco nella guardia della preda.',
        moves: [
          _SunkenMove(
            id: 'terramason',
            name: 'Terramason',
            kind: 'danno',
            description:
                'Colpisce di fianco con la massa d’argilla nella rete.',
          ),
          _SunkenMove(
            id: 'limyswing',
            name: 'Limyswing',
            kind: 'iniziativa',
            description:
                'Sfrutta lo slancio della rete per anticipare l’avversario.',
          ),
        ],
      ),
    ],
  ),
  _SunkenFamily(
    id: oculumPredoneBoomerangId,
    name: 'Falxfin',
    areaId: 'corallo_cavo',
    description:
        'Pesce umanoide slanciato dal muso allungato, due occhi d’ambra, due branchie laterali, due braccia, due gambe e una piccola pinna sulla nuca. Impugna una spada corta. Sul guanto d’arme alloggia la Lama Orbita, un boomerang appuntito ed equilibrato che gli gira accanto per magia.',
    aggression:
        'Scatta da dietro le arcate, fa passare il boomerang fra sé e gli attacchi in arrivo e lo richiama rasente al fondale.',
    anatomy: [
      _sunkenReferenceBody,
      _sunkenReferenceHead,
      ..._sunkenReferenceEyes,
      ..._sunkenReferenceFishGills,
      ..._sunkenReferenceHumanoidLimbs,
      {'id': 'nape_fin', 'group': 'fins', 'label': 'Pinna della nuca'},
      {'id': 'weighted_net', 'group': 'equipment', 'label': 'Lama Orbita'},
      {'id': 'short_sword', 'group': 'equipment', 'label': 'Spada corta'},
      {'id': 'orbit_gauntlet', 'group': 'equipment', 'label': 'Guanto d’arme'},
    ],
    weapon: _SunkenWeapon(
      id: oculumLamaOrbitaId,
      name: 'Lama Orbita',
      partId: 'weighted_net',
      held: true,
    ),
    nameChoices: [
      (name: 'Falcyloop', meaning: 'falx + loop, falce che torna in cerchio'),
      (name: 'Circyfin', meaning: 'circulus + fin, pinna che gira in cerchio'),
    ],
    base: _SunkenForm(
      element: 'acqua',
      stats: [4, 4, 5, 2],
      moves: [
        _SunkenMove(
          id: 'nassacast',
          name: 'Orbita del Boomerang',
          kind: 'orbita_boomerang',
          description:
              'Il boomerang rimane vicino al Predone e intercetta i colpi per le sue tre Azioni successive.',
        ),
        _SunkenMove(
          id: 'anguylsnag',
          name: 'Falce di ritorno',
          kind: 'stato_su_critico',
          conditionId: 'rallentato',
          description:
              'Fa incurvare il boomerang per colpire la preda sul fianco.',
        ),
      ],
    ),
    variants: [
      _SunkenForm(
        label: 'di Buio',
        element: 'buio',
        stats: [4, 5, 4, 3],
        description:
            'Squame prugna e boomerang d’ossidiana con un bordo di madreperla scura.',
        aggression:
            'Esce dalle arcate scure seguendo la traiettoria del suo boomerang.',
        moves: [
          _SunkenMove(
            id: 'umbracast',
            name: 'Orbita del Boomerang',
            kind: 'orbita_boomerang',
            description:
                'Il boomerang rimane vicino al Predone e intercetta i colpi per le sue tre Azioni successive.',
          ),
          _SunkenMove(
            id: 'noxskulk',
            name: 'Noxskulk',
            kind: 'iniziativa',
            description:
                'Cambia fianco mentre il boomerang disegna un arco nel Buio.',
          ),
        ],
      ),
      _SunkenForm(
        label: 'di Veleno',
        element: 'veleno',
        stats: [4, 4, 4, 4],
        description:
            'Macchie giallo-verdi sul muso e una fila di vescicole lungo il boomerang.',
        aggression:
            'Fa ruotare il boomerang vicino alla preda e cerca il punto da sfiorare con il bordo velenoso.',
        moves: [
          _SunkenMove(
            id: 'toxynet',
            name: 'Orbita del Boomerang',
            kind: 'orbita_boomerang',
            description:
                'Il boomerang rimane vicino al Predone e intercetta i colpi per le sue tre Azioni successive.',
          ),
          _SunkenMove(
            id: 'venynode',
            name: 'Venynedge',
            kind: 'stato_su_critico',
            conditionId: 'avvelenato',
            description:
                'Sparge veleno quando il bordo del boomerang tocca il bersaglio.',
          ),
        ],
      ),
    ],
  ),
  _SunkenFamily(
    id: oculumCorallwhirlId,
    name: 'Corallwhirl',
    areaId: 'corallo_cavo',
    description:
        'Tre correnti di Eiva avvolgono un singolo disco di corallo. Non ha occhi, volto o arti. Il disco resta visibile fra i getti che si ripiegano verso il centro.',
    aggression:
        'Si serra intorno a chi passa sotto l’arco e fa convergere i getti sul bersaglio.',
    anatomy: [
      _sunkenReferenceBody,
      {
        'id': 'coral_disk',
        'group': 'core',
        'label': 'Disco corallino',
        'weak': true,
      },
      {'id': 'current_1', 'group': 'currents', 'label': 'Prima corrente'},
      {'id': 'current_2', 'group': 'currents', 'label': 'Seconda corrente'},
      {'id': 'current_3', 'group': 'currents', 'label': 'Terza corrente'},
    ],
    nameChoices: [
      (name: 'Corallwhirl', meaning: 'corallium + whirl, vortice di corallo'),
      (name: 'Arcuflow', meaning: 'arcus + flow, corrente dell’arcata'),
    ],
    base: _SunkenForm(
      element: 'acqua',
      stats: [5, 3, 4, 4],
      moves: [
        _SunkenMove(
          id: 'scatto_tre_maree',
          name: 'Scatto delle Tre Maree',
          kind: 'scatto_tre_maree',
          description: 'Triplica il Movimento residuo durante uno scatto. '
              'Divide i Danni base fra i nemici attraversati e aggiunge a '
              'ciascuno tutti i metri percorsi. Infligge +120% Danni agli '
              'Scudi e usa Acqua o Contundente, scegliendo la resistenza '
              'minore e sorteggiando a parità.',
        ),
        _SunkenMove(
          id: 'arcustrike',
          name: 'Arcustrike',
          kind: 'danno',
          description: 'Fa convergere le tre correnti in un colpo d’Acqua.',
        ),
        _SunkenMove(
          id: 'vertystill',
          name: 'Vertystill',
          kind: 'difesa',
          description: 'Arrotola le correnti attorno al disco.',
        ),
      ],
    ),
    variants: [
      _SunkenForm(
        label: 'Spirituale',
        element: 'spirituale',
        stats: [4, 5, 3, 5],
        description:
            'Tre correnti pallide avvolgono un disco corallino opaco. Nel centro non compare alcun volto.',
        aggression:
            'Si forma alle spalle di chi entra sotto l’arco e stringe le tre correnti intorno alla preda.',
        moves: [
          _SunkenMove(
            id: 'spirywhirl',
            name: 'Spirywhirl',
            kind: 'danno',
            description: 'Comprime una corrente in un colpo Spirituale.',
          ),
          _SunkenMove(
            id: 'animyshroud',
            name: 'Animyshroud',
            kind: 'scudo',
            description: 'Avvolge il disco in uno strato di Eiva spettrale.',
          ),
        ],
      ),
      _SunkenForm(
        label: 'di Fulmine',
        element: 'fulmine',
        stats: [4, 3, 4, 6],
        description:
            'Pochi guizzi ocra corrono fra esattamente tre correnti e il bordo del disco.',
        aggression:
            'Si sposta a scatti lungo l’arcata e attacca da un punto cieco della colonna.',
        moves: [
          _SunkenMove(
            id: 'fulgywhirl',
            name: 'Fulgywhirl',
            kind: 'danno',
            description:
                'Rilascia una scarica dove i vortici si sovrappongono.',
          ),
          _SunkenMove(
            id: 'celercurl',
            name: 'Celercurl',
            kind: 'iniziativa',
            description:
                'Si ripiega nel centro e accelera sull’altro lato dell’arco.',
          ),
        ],
      ),
    ],
  ),
  _SunkenFamily(
    id: 'affogato_granchio_delle_cappelle',
    name: 'Granchio delle Cappelle',
    areaId: 'corallo_cavo',
    description:
        'Granchio massiccio con due occhi su peduncoli, due chele, otto zampe da marcia e carapace a cupola. Si accovaccia fra le cappelle immerse nell’Eiva.',
    aggression:
        'Balza rasoterra da sotto la cappella e chiude le chele sugli intrusi.',
    anatomy: [
      _sunkenReferenceBody,
      {
        'id': 'eyes_1',
        'group': 'eyes',
        'label': 'Occhio destro',
        'side': 'right',
        'weak': true,
      },
      {
        'id': 'eyes_2',
        'group': 'eyes',
        'label': 'Occhio sinistro',
        'side': 'left',
        'weak': true,
      },
      {'id': 'shell', 'group': 'shell', 'label': 'Carapace'},
      {
        'id': 'claw_right',
        'group': 'claws',
        'label': 'Chela destra',
        'side': 'right',
      },
      {
        'id': 'claw_left',
        'group': 'claws',
        'label': 'Chela sinistra',
        'side': 'left',
      },
      {
        'id': 'legs_1',
        'group': 'legs',
        'label': 'Prima zampa destra',
        'side': 'right',
      },
      {
        'id': 'legs_2',
        'group': 'legs',
        'label': 'Seconda zampa destra',
        'side': 'right',
      },
      {
        'id': 'legs_3',
        'group': 'legs',
        'label': 'Terza zampa destra',
        'side': 'right',
      },
      {
        'id': 'legs_4',
        'group': 'legs',
        'label': 'Quarta zampa destra',
        'side': 'right',
      },
      {
        'id': 'legs_5',
        'group': 'legs',
        'label': 'Prima zampa sinistra',
        'side': 'left',
      },
      {
        'id': 'legs_6',
        'group': 'legs',
        'label': 'Seconda zampa sinistra',
        'side': 'left',
      },
      {
        'id': 'legs_7',
        'group': 'legs',
        'label': 'Terza zampa sinistra',
        'side': 'left',
      },
      {
        'id': 'legs_8',
        'group': 'legs',
        'label': 'Quarta zampa sinistra',
        'side': 'left',
      },
    ],
    nameChoices: [
      (name: 'Sacryclaw', meaning: 'sacer + claw, chela del luogo sacro'),
      (name: 'Testavault', meaning: 'testa + vault, volta di guscio'),
    ],
    base: _SunkenForm(
      element: 'acqua',
      stats: [7, 3, 5, 1],
      moves: [
        _SunkenMove(
          id: 'sacrypinch',
          name: 'Sacrypinch',
          kind: 'danno',
          description: 'Stringe un avversario con una delle sue chele.',
        ),
        _SunkenMove(
          id: 'testaguard',
          name: 'Testaguard',
          kind: 'difesa',
          description: 'Si abbassa e protegge gli occhi sotto il carapace.',
        ),
      ],
    ),
    variants: [
      _SunkenForm(
        label: 'di Roccia',
        element: 'roccia',
        stats: [8, 3, 5, 1],
        description:
            'Il carapace a cupola è grigio sabbia e porta concrezioni piatte di pietra.',
        aggression:
            'Avanza di traverso, poi spinge l’avversario contro la cappella con una chela.',
        moves: [
          _SunkenMove(
            id: 'saxypinch',
            name: 'Saxypinch',
            kind: 'danno',
            description: 'Chiude la chela incrostata contro il bersaglio.',
          ),
          _SunkenMove(
            id: 'lapyguard',
            name: 'Lapyguard',
            kind: 'scudo',
            description:
                'Accosta le chele al carapace di pietra per ripararsi.',
          ),
        ],
      ),
      _SunkenForm(
        label: 'di Gelo',
        element: 'ghiaccio',
        stats: [6, 4, 4, 3],
        description:
            'Il carapace è grigio-azzurro e le giunture delle chele portano una sottile crosta di ghiaccio.',
        aggression:
            'Abbassa le chele nell’ombra e scatta di lato verso le gambe del bersaglio.',
        moves: [
          _SunkenMove(
            id: 'gelypinch',
            name: 'Gelypinch',
            kind: 'danno',
            description: 'Colpisce con una chela ghiacciata.',
          ),
          _SunkenMove(
            id: 'glacygrip',
            name: 'Glacygrip',
            kind: 'stato_su_critico',
            conditionId: 'rallentato',
            description: 'Lascia gelo sulla parte raggiunta dalla chela.',
          ),
        ],
      ),
    ],
  ),
  _SunkenFamily(
    id: 'affogato_razziatore_delle_fronde',
    name: 'Razziatore delle Fronde',
    areaId: 'fronde_eiva',
    description:
        'Pesce umanoide asciutto con testa a vanga arrotondata, due occhi, branchie laterali, due braccia e due gambe palmate. Impugna un’anfora piena di fronde d’Eiva spinose.',
    aggression:
        'Esce dalle fronde e brandisce l’anfora per sferzare gli intrusi con la vegetazione spinosa.',
    anatomy: [
      _sunkenReferenceBody,
      _sunkenReferenceHead,
      ..._sunkenReferenceEyes,
      ..._sunkenReferenceFishGills,
      ..._sunkenReferenceHumanoidLimbs,
      {
        'id': 'frond_amphora',
        'group': 'equipment',
        'label': 'Anfora delle fronde',
      },
    ],
    weapon: _SunkenWeapon(
      id: 'anfora_delle_fronde',
      name: 'Anfora delle fronde',
      partId: 'frond_amphora',
      held: true,
    ),
    nameChoices: [
      (
        name: 'Frondyskulk',
        meaning: 'frons, frondis + skulk, imboscato fra le fronde',
      ),
      (name: 'Spynajar', meaning: 'spina + jar, anfora di spine'),
    ],
    base: _SunkenForm(
      element: 'acqua',
      stats: [4, 4, 5, 2],
      moves: [
        _SunkenMove(
          id: 'spynalash',
          name: 'Spynalash',
          kind: 'danno',
          description: 'Inclina l’anfora e sferza con le fronde spinose.',
        ),
        _SunkenMove(
          id: 'frondaglide',
          name: 'Frondaglide',
          kind: 'iniziativa',
          description: 'Passa in anticipo lungo un corridoio di fronde.',
        ),
      ],
    ),
    variants: [
      _SunkenForm(
        label: 'di Natura',
        element: 'natura',
        stats: [4, 3, 6, 3],
        description:
            'Le fronde hanno steli intrecciati, punte color rame e foglie a nervature avorio.',
        aggression:
            'Picchia la spalla contro il fusto sommerso e allunga le fronde intorno alla guardia del bersaglio.',
        moves: [
          _SunkenMove(
            id: 'folyylash',
            name: 'Folyylash',
            kind: 'danno',
            description: 'Flette gli steli prima di sferzare con le punte.',
          ),
          _SunkenMove(
            id: 'radixscreen',
            name: 'Radixscreen',
            kind: 'difesa',
            description: 'Apre le foglie davanti all’anfora come un riparo.',
          ),
        ],
      ),
      _SunkenForm(
        label: 'di Veleno',
        element: 'veleno',
        stats: [4, 4, 4, 4],
        description:
            'L’anfora è opaca e le fronde violacee portano spine color lime.',
        aggression:
            'Spinge prima l’anfora da sotto le fronde e fa seguire una sferzata delle foglie velenose.',
        moves: [
          _SunkenMove(
            id: 'venynlash',
            name: 'Venynlash',
            kind: 'danno',
            description: 'Colpisce con le foglie di Veleno dall’anfora.',
          ),
          _SunkenMove(
            id: 'toxypuncture',
            name: 'Toxypuncture',
            kind: 'stato_su_critico',
            conditionId: 'avvelenato',
            description:
                'Fa penetrare le spine velenose quando il colpo riesce in modo critico.',
          ),
        ],
      ),
    ],
  ),
];
