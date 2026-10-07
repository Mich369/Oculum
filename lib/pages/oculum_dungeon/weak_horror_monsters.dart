part of 'monster_book.dart';

// Original early-game creatures: unsettling silhouettes, readable weaknesses,
// no unavoidable disables, and six to ten total core stat points at level zero.
const _weakHorrorProfiles = [
  (
    id: 'lacrimante',
    name: 'Lacrimante',
    element: 'acqua',
    stats: [2, 1, 2, 1],
    description:
        'Piccola testa senza bocca, sorretta da mani pallide; una pupilla enorme versa acqua nera. Abita cantine umide. Il getto arriva entro 3 metri: una porta o un angolo interrompe la linea di tiro.',
    attack: 'Lacrima nera',
    action:
        'Scagli una lacrima pesante contro un solo bersaglio visibile entro 3 metri',
    guard: 'Palpebra serrata',
    defense: 'Chiudi la pupilla dietro una membrana spessa',
    drops: ['nebrin', 'pelle_mostro'],
  ),
  (
    id: 'ciste',
    name: 'Ciste Errante',
    element: 'fisico',
    stats: [3, 1, 2, 1],
    description:
        'Sacca carnosa grande quanto una zucca, con tre zampe di cartilagine. Striscia nelle fogne e urta ciò che le sbarra il passo. Non esplode alla morte e fatica a superare gradini alti.',
    attack: 'Urto molle',
    action: 'Urti un solo avversario a contatto con il sacco di cartilagine',
    guard: 'Cartilagine raccolta',
    defense: 'Raccogli le zampe sotto il corpo per proteggere il ventre',
    drops: ['pelle_mostro', 'ambril'],
  ),
  (
    id: 'moscerino',
    name: 'Moscerino degli Occhi',
    element: 'fisico',
    stats: [1, 1, 3, 1],
    description:
        'Insetto grosso come un pugno, con occhi concentrici e ali trasparenti. Vive presso candele e resti organici; attacca isolatamente e non attraversa coperture solide.',
    attack: 'Puntura della pupilla',
    action: 'Pungi un singolo avversario a contatto con la proboscide',
    guard: 'Ali sovrapposte',
    defense: 'Ripieghi le ali a protezione degli occhi',
    drops: ['nacrel', 'thornil'],
  ),
  (
    id: 'sagrestano',
    name: 'Sagrestano Cavo',
    element: 'oscuro',
    stats: [2, 2, 3, 1],
    description:
        'Servitore curvo avvolto in una tunica vuota, con una campanella cucita al collo. Veglia cappelle abbandonate. La campanella annuncia la sua presenza: non possiede paura o stordimento automatici.',
    attack: 'Campana scheggiata',
    action: 'Colpisci un solo avversario a contatto con una campana incrinata',
    guard: 'Maniche annodate',
    defense: 'Avvolgi le maniche attorno al braccio esposto',
    drops: ['feralis', 'tessarin'],
  ),
  (
    id: 'portalanterna',
    name: 'Portalanterna Spento',
    element: 'fuoco',
    stats: [2, 3, 2, 2],
    description:
        'Figura minuta con una lanterna innestata nello sterno. Cerca braci nei corridoi e protegge la sua ultima scintilla; il soffio ha portata di 2 metri e non incendia automaticamente il bersaglio.',
    attack: 'Ultima brace',
    action: 'Soffi una brace contro un solo bersaglio visibile entro 2 metri',
    guard: 'Sportello di ferro',
    defense: 'Chiudi lo sportello della lanterna per schermare il petto',
    drops: ['cendril', 'feralis'],
  ),
  (
    id: 'mastino',
    name: 'Mastino della Cripta',
    element: 'fisico',
    stats: [3, 1, 4, 1],
    description:
        'Cane magro dalla pelle color cenere e denti consumati, spesso legato a una tomba. Cerca avversari isolati ma arretra davanti a una linea compatta; il morso non provoca emorragie permanenti.',
    attack: 'Morso della soglia',
    action: 'Mordi un solo bersaglio a contatto senza trascinarlo',
    guard: 'Costole raccolte',
    defense: 'Ti rannicchi dietro le costole sporgenti',
    drops: ['pelle_mostro', 'osserin'],
  ),
  (
    id: 'affamato',
    name: 'Affamato delle Fosse',
    element: 'fisico',
    stats: [3, 2, 4, 1],
    description:
        'Piccolo umanoide dagli arti lunghi e dallo stomaco vuoto, rintanato tra fosse e cucine in rovina. Raccoglie scarti e può essere distratto con cibo. Non divora arti né sottrae statistiche permanenti.',
    attack: 'Unghie del digiuno',
    action: 'Graffi un solo avversario a contatto con le unghie spezzate',
    guard: 'Braccia sul ventre',
    defense: 'Copri ventre e gola con entrambe le braccia',
    drops: ['pelle_mostro', 'thornil'],
  ),
  (
    id: 'cucitore',
    name: 'Cucitore di Stracci',
    element: 'metallo',
    stats: [2, 2, 3, 1],
    description:
        'Fantoccio basso di stoffa umida, con aghi spuntati al posto delle dita. Ripara i propri stracci nelle stanze vuote. Le sue cuciture non imprigionano automaticamente e si interrompono allontanandosi.',
    attack: 'Ago storto',
    action: 'Affondi un ago contro un solo bersaglio a contatto',
    guard: 'Toppa ripiegata',
    defense: 'Sovrapponi una toppa sul punto più esposto',
    drops: ['tessarin', 'feralis'],
  ),
  (
    id: 'larva',
    name: 'Larva del Pozzo',
    element: 'natura',
    stats: [2, 1, 2, 2],
    description:
        'Larva lattiginosa con una maschera ossea e filamenti verdi. Si nasconde nelle crepe di pozzi abbandonati. La secrezione colpisce entro 2 metri e non infligge malattie o paralisi permanenti.',
    attack: 'Getto del fondo',
    action:
        'Lanci una goccia irritante contro un bersaglio visibile entro 2 metri',
    guard: 'Maschera ossea',
    defense: 'Inclini il guscio osseo verso il colpo',
    drops: ['tessarin', 'virdel'],
  ),
];

final _weakHorrorMonsterBookEntries = [
  for (final p in _weakHorrorProfiles)
    MonsterBookEntry(
      id: 'weak_horror_${p.id}',
      nameIt: p.name,
      nameEn: p.name,
      descIt:
          '${p.description} Creatura Minore, livello 0, grado 0: RES ${p.stats[0]}, VOL ${p.stats[1]}, MAT ${p.stats[2]}, OCU ${p.stats[3]}; totale ${p.stats.reduce((a, b) => a + b)} punti. Le tecniche richiedono un tiro riuscito quando offensive e rispettano Scudi e Difesa. Nessuna variante potenziata automatica.',
      descEn: p.description,
      elementId: p.element,
      spriteAssetPath: '',
      isMiniBoss: false,
      isBoss: false,
      isNullFateless: false,
      classificationTags: const ['Creatura Minore'],
      stats: {
        'level': 0,
        'resilienza': p.stats[0],
        'volonta': p.stats[1],
        'materia': p.stats[2],
        'oculum': p.stats[3],
      },
      skillIds: ['weak_horror_${p.id}_attack', 'weak_horror_${p.id}_guard'],
      dropIds: p.drops,
      dropChances: {p.drops[0]: 60, p.drops[1]: 35},
    ),
];

String oculumWeakHorrorSkillText(String id) {
  for (final p in _weakHorrorProfiles) {
    if (id != 'weak_horror_${p.id}_attack' &&
        id != 'weak_horror_${p.id}_guard') {
      continue;
    }
    final guard = id.endsWith('_guard');
    final name = guard ? p.guard : p.attack;
    final action = guard ? p.defense : p.action;
    return '$name — ${[
      for (var form = 0; form < 3; form++) '${['I', 'II', 'III'][form]}/$action. ${guard ? '+${form + 1} Difesa per un turno, solo su te stesso; non cumulabile con la stessa tecnica' : 'Tiro per colpire normale: Danni +${form + 1}, un solo bersaglio; nessun danno se il tiro fallisce'}. Richiede livello ${form * 3}. (${form + 1}/${form + 1} Oculum). CD 3 turni.',
    ].join(' ')}';
  }
  return '';
}
