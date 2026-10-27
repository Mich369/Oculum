part of 'monster_book.dart';

// User references define silhouettes and habitats; names and numerical values
// below are editable initial balance. Pictures are never codex portraits.
const _microRealmCreatureSeeds = <Map<String, dynamic>>[
  {
    'id': 'pianta_divoratrice_vetro',
    'name': 'Divoratrice dal nucleo vitreo',
    'realm': 'deserto_divoratore',
    'element': 'natura',
    'stats': [4, 3, 3, 2],
    'level': 3,
    'look':
        'Pianta mobile dalle radici nere prensili e petali corazzati, immersa nella sabbia cristallina umida e tagliente. Un nucleo azzurro al centro coordina le liane e la bocca vegetale. Cerca di divorare ciò che vede.',
    'weak': 'Il nucleo centrale fra i petali.',
    'attitude':
        'Aggressiva e guidata dalla fame; segue i movimenti e tenta di trascinare la preda nella sabbia.',
    'material': 'fibra_divoratrice_vetro',
    'attack': 'Stretta delle liane taglienti',
  },
  {
    'id': 'colosso_prismarite',
    'name': 'Colosso di Prismarite',
    'realm': 'reame_cristallo',
    'element': 'roccia',
    'stats': [8, 4, 6, 3],
    'level': 6,
    'mini': true,
    'look':
        'Colosso basso e largo di roccia scura, ricoperto da grandi cristalli verde pallido su spalle, schiena e pugni. Avanza sulle nocche; le giunture restano scoperte fra le placche.',
    'weak': 'Le giunture fra roccia e cristalli.',
    'attitude':
        'Territoriale: difende le vene di Prismarite e minaccia chi le percuote.',
    'material': 'prismarite',
    'attack': 'Urto delle nocche cristalline',
  },
  {
    'id': 'volto_ossidiana',
    'name': 'Volto di Ossidiana',
    'realm': 'reame_cristallo',
    'element': 'buio',
    'stats': [3, 5, 3, 5],
    'level': 5,
    'look':
        'Figura slanciata vestita di tessuto scuro; al posto della parte superiore del volto cresce una corona irregolare di cristallo nero. Una bocca chiara dentata resta visibile sotto le punte.',
    'weak': 'La base della corona, sopra la bocca.',
    'attitude':
        'Silenzioso e osservatore; si avvicina alle risonanze e diventa ostile se il suo cristallo viene toccato.',
    'material': 'ossidiana_sussurrante',
    'attack': 'Lame del riflesso nero',
  },
  {
    'id': 'predatore_smeraldo',
    'name': 'Predatore Smeraldo',
    'realm': 'reame_cristallo',
    'element': 'roccia',
    'stats': [6, 6, 4, 3],
    'level': 7,
    'look':
        'Grande rettile di scaglie nere fessurate, con cristalli verde smeraldo lungo il dorso e sulle mascelle. La gola emette una luce verde e i denti si incastrano come schegge minerali.',
    'weak': 'La gola luminosa quando apre le fauci.',
    'attitude':
        'Predatore solitario; tende agguati fra le vene di smeraldo e insegue chi fugge facendo rumore.',
    'material': 'smeraldo_memoria',
    'attack': 'Morso della geode smeraldo',
  },
  {
    'id': 'costrutto_prismatico',
    'name': 'Costrutto Prismatico',
    'realm': 'reame_cristallo',
    'element': 'luce',
    'stats': [4, 3, 5, 5],
    'level': 6,
    'look':
        'Costrutto umanoide interamente composto da facce di cristallo trasparente e iridescente. Il capo è una punta prismatica, le braccia terminano in cunei e il nucleo rifrange colori al centro del torace.',
    'weak': 'Il nucleo prismatico nel torace.',
    'attitude':
        'Vigile e metodico; protegge le camere profonde e risponde alle interferenze luminose.',
    'material': 'cuore_prismatico',
    'attack': 'Fendente del prisma',
  },
  {
    'id': 'quadribrachio_ambra',
    'name': 'Quadribrachio d’Ambra',
    'realm': 'reame_cristallo',
    'element': 'roccia',
    'stats': [8, 5, 6, 4],
    'level': 8,
    'mini': true,
    'look':
        'Creatura minerale a quattro braccia, pelle di pietra grigia e venature ambrate. Un grande cristallo arancio sporge dal capo e nuclei più piccoli ardono sulle spalle.',
    'weak': 'Il cristallo ambrato sulla testa.',
    'attitude':
        'Difende il proprio giacimento e cerca di circondare chi si avvicina usando le quattro braccia.',
    'material': 'ambra_palpitante',
    'attack': 'Morsa delle quattro braccia',
  },
  {
    'id': 'carne_falciante',
    'name': 'Falciante di Carne',
    'realm': 'carne_viva',
    'element': 'fisico',
    'stats': [4, 5, 2, 1],
    'level': 3,
    'look':
        'Umanoide di carne nuda, torso asimmetrico e una spalla rigonfia che ingloba il volto. Un braccio termina in una lunga falce tendinea e la schiena è coperta da pustole.',
    'weak': 'Il tendine scoperto alla radice della falce.',
    'attitude':
        'Aggressivo: insegue il sangue e colpisce con ampi archi del braccio deformato.',
    'material': 'tendine_falciante',
    'attack': 'Falciata tendinea',
  },
  {
    'id': 'alato_carne',
    'name': 'Alato di Carne',
    'realm': 'carne_viva',
    'element': 'fisico',
    'stats': [5, 5, 4, 2],
    'level': 5,
    'look':
        'Creatura alta e scarnificata, con ali membranose, mascella aperta e una coda muscolare enorme che termina in un pugno artigliato. Membrane e pustole pendono dal ventre.',
    'weak': 'Le radici delle ali e il ventre esposto.',
    'attitude':
        'Predatore mobile: aggira la preda e sfrutta la coda per abbatterla.',
    'material': 'membrana_alato_carne',
    'attack': 'Schianto della coda prensile',
  },
  {
    'id': 'velario_uncinato',
    'name': 'Velario Uncinato',
    'realm': 'carne_viva',
    'element': 'fisico',
    'stats': [4, 4, 5, 3],
    'level': 5,
    'look':
        'Figura altissima e sottile, con un mantello di membrane rosse e innumerevoli uncini ossei lungo il petto e i lembi. Le braccia sono lunghe, piegate e terminano in dita ricurve.',
    'weak': 'Il tessuto che unisce il mantello alle spalle.',
    'attitude':
        'Immobile finché una preda si avvicina; la avvolge con le membrane e la trattiene con gli uncini.',
    'material': 'uncino_osseo_velario',
    'attack': 'Avvolgimento degli uncini',
  },
  {
    'id': 'innesto_predatore',
    'name': 'Innesto Predatore',
    'realm': 'carne_viva',
    'element': 'fisico',
    'stats': [3, 4, 3, 2],
    'level': 3,
    'look':
        'Umanoide esile con un secondo corpo mostruoso innestato nell’addome. Zampe minute e una bocca dentata emergono dal petto; il corpo ospite mantiene braccia lunghe e mani tese.',
    'weak': 'L’innesto fra la bocca addominale e il torso.',
    'attitude':
        'Avanza lentamente e scatta con la creatura innestata quando la preda è vicina.',
    'material': 'fibra_innesto',
    'attack': 'Morso dell’innesto',
  },
  {
    'id': 'ammasso_pustoloso',
    'name': 'Ammasso Pustoloso',
    'realm': 'carne_viva',
    'element': 'veleno',
    'stats': [8, 4, 3, 2],
    'level': 6,
    'mini': true,
    'look':
        'Massa accovacciata di carne pallida e pustole, con una grande testa corazzata da escrescenze ossee. Piccole braccia e volti affiorano dal torace; un arto enorme si alza sopra il dorso.',
    'weak': 'Le sacche tese fra le placche ossee.',
    'attitude':
        'Lento e territoriale; attira le prede vicine e le travolge col proprio peso.',
    'material': 'sacca_pustolosa',
    'attack': 'Rottura delle sacche',
  },
  {
    'id': 'portatore_ematico',
    'name': 'Portatore Ematico',
    'realm': 'carne_viva',
    'element': 'fisico',
    'stats': [5, 5, 3, 2],
    'level': 5,
    'look':
        'Creatura arcuata di muscoli rossi e costole esterne, dal volto quasi scheletrico. Con un braccio solleva un bozzolo organico appeso a filamenti; tende i tendini come corde.',
    'weak': 'I tendini che sostengono il bozzolo.',
    'attitude':
        'Raccoglie resti e difende il carico; si avvicina a chi è ferito.',
    'material': 'filamento_ematico',
    'attack': 'Sferzata del bozzolo',
  },
  {
    'id': 'araldo_bozzoli',
    'name': 'Araldo dei Bozzoli',
    'realm': 'carne_viva',
    'element': 'fisico',
    'stats': [5, 4, 4, 4],
    'level': 6,
    'look':
        'Figura di carne e ossa dalla testa ramificata come corna; porta grossi bozzoli membranosi trascinati da lunghi filamenti. Un braccio termina in dita enormi ricurve.',
    'weak': 'Il nodo di filamenti fra i bozzoli e il torace.',
    'attitude':
        'Custodisce i bozzoli e respinge chi tenta di aprirli; non abbandona facilmente il proprio carico.',
    'material': 'membrana_bozzolo',
    'attack': 'Uncino del custode',
  },
  {
    'id': 'scheletrico_sudario',
    'name': 'Scheletrico del Sudario Vivo',
    'realm': 'carne_viva',
    'element': 'buio',
    'stats': [3, 4, 4, 4],
    'level': 5,
    'look':
        'Figura scheletrica alta, avvolta da un sudario nero vivo che si allunga in filamenti. Le braccia ossute finiscono in enormi dita appuntite; placche di carne restano sulle spalle.',
    'weak': 'Le giunture scoperte delle braccia.',
    'attitude':
        'Osserva in silenzio e immobilizza chi attraversa il suo sudario.',
    'material': 'sudario_organico',
    'attack': 'Artigli del sudario',
  },
  {
    'id': 'occhio_quadrilama',
    'name': 'Occhio Quadrilama',
    'realm': 'carne_viva',
    'element': 'fisico',
    'stats': [3, 5, 5, 2],
    'level': 5,
    'look':
        'Creatura sottile dominata da un grande occhio arancio al centro del torso. Quattro arti irregolari finiscono in lame ricurve e fasci di muscolo rosso si avvolgono sul corpo.',
    'weak': 'Il grande occhio centrale.',
    'attitude':
        'Sorveglia e attacca con scatti rapidi, tenendo l’occhio rivolto alla minaccia.',
    'material': 'lama_ossea_oculare',
    'attack': 'Incrocio delle quattro lame',
  },
  {
    'id': 'cervo_carne_aperta',
    'name': 'Cervo dalla Carne Aperta',
    'realm': 'carne_viva',
    'element': 'fisico',
    'stats': [4, 4, 6, 1],
    'level': 4,
    'look':
        'Cervo scarnificato dal collo lungo e dal corpo rosso scuro. Il cranio si apre in una bocca verticale fra corna ossee dentellate; zampe sottili terminano in dita deformate.',
    'weak': 'La base del collo sotto la bocca aperta.',
    'attitude':
        'Nervoso e territoriale: osserva a distanza e carica chi lo sorprende.',
    'material': 'corno_cervo_carne',
    'attack': 'Carica della bocca aperta',
  },
  {
    'id': 'orea_floscocorno',
    'name': 'Floscocorno di Zalira',
    'realm': 'orea_zalira',
    'element': 'fisico',
    'stats': [2, 2, 4, 2],
    'level': 1,
    'look':
        'Creatura buffa color malva, dal corpo morbido e corna che si piegano come steli. Le zampe cambiano ampiezza mentre cammina fra alberi flosci e rigidi.',
    'weak': 'Il piccolo addensamento al centro del ventre morbido.',
    'attitude':
        'Curioso, tende a imitare i movimenti dei viaggiatori e fugge se minacciato.',
    'material': 'fibra_floscocorno',
    'attack': 'Rimbalzo del corno molle',
  },
  {
    'id': 'orea_fioripasso',
    'name': 'Fioripasso Irregolare',
    'realm': 'orea_zalira',
    'element': 'natura',
    'stats': [2, 3, 3, 4],
    'level': 3,
    'look':
        'Pianta ambulante dai grandi fiori arancio e dai bulbi verde acqua. I passi alternano accelerazioni e pause; il corpo segue le trasformazioni del terreno morbido.',
    'weak': 'La corona di radici sotto il bulbo.',
    'attitude':
        'Segue la luce dei due soli senza occhi; difende le proprie radici se vengono schiacciate.',
    'material': 'bulbo_fioripasso',
    'attack': 'Frustata degli steli',
  },
  {
    'id': 'orea_velocilento',
    'name': 'Velocilento di Zalira',
    'realm': 'orea_zalira',
    'element': 'spirituale',
    'stats': [3, 3, 4, 4],
    'level': 4,
    'look':
        'Piccolo animale irregolare dalle orecchie a disco, mantello rosa e sfere azzurre lungo la schiena. Si muove a scatti, alternando lentezza e velocità come il tempo del reame.',
    'weak': 'La giuntura fra le sfere e la schiena.',
    'attitude':
        'Giocoso e imprevedibile; può affiancare i visitatori o allontanarsi in un istante. Non rivela la natura del sovrano ignoto.',
    'material': 'sfera_velocilento',
    'attack': 'Impulso del passo irregolare',
  },
  {
    'id': 'black_dragon_shield',
    'name': 'BlackDragonShield',
    'realm': 'shadow_hell',
    'element': 'buio',
    'stats': [24, 18, 20, 16],
    'level': 22,
    'boss': true,
    'look':
        'Enorme rettile nero corazzato a sei arti, affine al FireShield ma molto più potente. Placche nere sovrapposte e corna aguzze circondano un cranio draconico; fessure viola ardono fra le scaglie e lungo le mascelle. Dal ventre e dalla gola erompono vampate di fiamme d’ombra che raggiungono anche esseri immateriali.',
    'weak': 'Le giunture e la membrana sotto il ventre fra le placche nere.',
    'attitude':
        'Predatore d’assedio dominante: protegge il proprio territorio con la corazza e investe le minacce con vampate d’ombra.',
    'material': 'placca_black_dragon_shield',
    'attack': 'Vampata del drago d’ombra',
  },
];

final _microRealmCreatureEntries = <MonsterBookEntry>[
  for (final s in _microRealmCreatureSeeds)
    _authoredPlanar(
      '${s['id']}',
      '${s['name']}',
      ['${s['realm']}'],
      '${s['element']}',
      '${s['look']}',
      '${s['weak']}',
      List<int>.from(s['stats'] as List),
      s['level'] as int,
      s['boss'] == true,
      s['mini'] == true,
      [for (var i = 0; i < 4; i++) 'realm_${s['id']}_$i'],
      {
        'authoredCanonical': true,
        'naturalAttitude': s['attitude'],
        if (s['id'] == 'black_dragon_shield') ...{
          'criticalShields': 4,
          'canHitIntangible': true,
          'strongerThan': 'fire_shield',
        },
      },
      s['id'] == 'black_dragon_shield'
          ? const {
              'fuoco': 'Alta Resistenza',
              'buio': 'Alta Resistenza',
              'fisico': 'resistenza',
            }
          : const {},
    ).copyWith(
      dropIds: ['${s['material']}'],
      dropChances: {'${s['material']}': 45},
      classificationTags: [
        if (s['realm'] == 'carne_viva')
          'Creatura di carne'
        else if (s['id'] == 'costrutto_prismatico')
          'Costrutto'
        else if (s['realm'] == 'reame_cristallo')
          'Creatura minerale'
        else
          'Creatura planare',
      ],
    ),
];

final _microRealmTechniques = <String, MonsterConcreteTechnique>{
  for (final s in _microRealmCreatureSeeds)
    for (var i = 0; i < 4; i++)
      'realm_${s['id']}_$i': _planarMove(
        i == 0
            ? '${s['attack']}'
            : i == 1
            ? 'Guardia di ${s['name']}'
            : i == 2
            ? 'Passo di ${s['name']}'
            : 'Riserva di ${s['name']}',
        i == 0
            ? '${s['look']} Concentra un attacco coerente con la propria anatomia.${s['id'] == 'black_dragon_shield' ? ' Le fiamme d’ombra colpiscono anche gli immateriali.' : ''}'
            : i == 1
            ? 'Protegge i punti deboli con la propria struttura.'
            : i == 2
            ? 'Sposta il corpo seguendo il ritmo del proprio habitat.'
            : 'Accumula una barriera del proprio elemento, senza curare i danni già subiti.',
        '${s['element']}',
        i == 0
            ? 'danno'
            : i == 1
            ? 'scudo'
            : i == 2
            ? 'movimento'
            : 'scudo',
        [
          for (var f = 0; f < 3; f++)
            [
              MonsterTechniqueEffect(
                i == 0
                    ? 'danno'
                    : i == 1
                    ? 'difesa'
                    : i == 2
                    ? 'modifica_sottotratto'
                    : 'scudo',
                '${(f + 1) * (s['boss'] == true
                        ? (i == 0
                              ? 45
                              : i == 3
                              ? 80
                              : 12)
                        : i == 0
                        ? 5 + (s['level'] as int)
                        : i == 3
                        ? 10
                        : 3)}',
                target: i == 2 ? 'movimento' : '',
                mode: i == 0
                    ? 'prossima_azione'
                    : i == 3
                    ? 'immediato'
                    : 'finche_attivo',
                duration: i == 0 || i == 3 ? '' : '1',
              ),
            ],
        ],
        costResource: (s['stats'] as List).last > 0 ? 'oculum' : 'volonta',
        minimums: const [1, 2, 3],
        maximums: const [1, 2, 3],
        cd: i == 0 ? const [2, 3, 4] : const [3, 4, 5],
      ),
};
