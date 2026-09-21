class HeroSkill {
  const HeroSkill(
    this.id,
    this.name,
    this.element,
    this.effect,
    this.resource,
    this.cost,
    this.amount, {
    this.cooldown = 0,
    this.condition = '',
  });
  final String id, name, element, effect, resource, condition;
  final int cost, amount, cooldown;
  String description(int level) => switch (effect) {
    'actions' =>
      'Ottieni altre ${amount + (level >= 2 ? 1 : 0)} azioni in questo turno. Una volta per turno.',
    'heal' => 'Cura ${amount + level} Vita e tratta le ferite.',
    'guard' => 'Ottieni ${amount + level} Scudo; prepara una parata.',
    'evade' => 'Schiva il prossimo attacco; +${amount + level} alla fuga.',
    'control' => 'Infliggi $condition per ${1 + (level >= 2 ? 1 : 0)} turni.',
    'area' => '${amount + level} danni a tutti i nemici.',
    'setup' => 'Il prossimo attacco ottiene +${amount + level} danni.',
    'sacrifice' => '${amount + level * 2} danni; assorbi 2 Vita.',
    _ =>
      '${amount + level} danni${condition.isEmpty ? '.' : '; applica $condition.'}',
  };
  int price(int level) => (cost - (level >= 3 ? 1 : 0)).clamp(0, 99);
  int cd(int level) => (cooldown - (level >= 2 ? 1 : 0)).clamp(0, 99);
}

const heroSkills = <HeroSkill>[
  HeroSkill(
    'slancio',
    'Slancio Oltre il Limite',
    'Tempo',
    'actions',
    'volonta',
    2,
    2,
  ),
  HeroSkill(
    'istante',
    'Istante Rubato',
    'Spazio',
    'actions',
    'oculum',
    3,
    3,
    cooldown: 2,
  ),
  HeroSkill(
    'brace',
    'Filo di Brace',
    'Fuoco',
    'attack',
    'oculum',
    1,
    3,
    condition: 'Brucia',
  ),
  HeroSkill('fornace', 'Cuore di Fornace', 'Fuoco', 'setup', 'materia', 1, 3),
  HeroSkill(
    'gelo',
    'Chiodo di Gelo',
    'Ghiaccio',
    'control',
    'oculum',
    1,
    0,
    condition: 'Legato',
    cooldown: 2,
  ),
  HeroSkill('brina', 'Pelle di Brina', 'Ghiaccio', 'guard', 'materia', 1, 3),
  HeroSkill(
    'arco',
    'Arco Spezzato',
    'Fulmine',
    'area',
    'oculum',
    2,
    2,
    cooldown: 2,
  ),
  HeroSkill(
    'scatto',
    'Scatto Elettrico',
    'Fulmine',
    'evade',
    'volonta',
    1,
    2,
    cooldown: 2,
  ),
  HeroSkill('vento', 'Lama di Pressione', 'Vento', 'attack', 'volonta', 1, 3),
  HeroSkill(
    'soffio',
    'Soffio Laterale',
    'Vento',
    'evade',
    'oculum',
    1,
    2,
    cooldown: 2,
  ),
  HeroSkill(
    'basalto',
    'Chiodo di Basalto',
    'Terra',
    'attack',
    'materia',
    1,
    2,
    condition: 'Legato',
  ),
  HeroSkill('argilla', 'Muro di Argilla', 'Terra', 'guard', 'materia', 1, 4),
  HeroSkill(
    'marea',
    'Ago di Marea',
    'Acqua',
    'attack',
    'oculum',
    1,
    2,
    condition: 'Esposto',
  ),
  HeroSkill(
    'pioggia',
    'Acqua Viva',
    'Acqua',
    'heal',
    'oculum',
    2,
    3,
    cooldown: 2,
  ),
  HeroSkill('notte', 'Ago di Notte', 'Ombra', 'attack', 'oculum', 1, 3),
  HeroSkill(
    'parassita',
    'Sussurro Parassita',
    'Ombra',
    'control',
    'oculum',
    1,
    0,
    condition: 'Confuso',
    cooldown: 2,
  ),
  HeroSkill('aurora', "Sigillo d’Aurora", 'Luce', 'heal', 'oculum', 2, 2),
  HeroSkill(
    'specchio',
    'Lancia di Specchio',
    'Luce',
    'attack',
    'materia',
    1,
    3,
    condition: 'Esposto',
  ),
  HeroSkill('tributo', 'Tributo Rosso', 'Sangue', 'sacrifice', 'vita', 2, 5),
  HeroSkill(
    'filo',
    'Filo di Sangue',
    'Sangue',
    'control',
    'vita',
    1,
    0,
    condition: 'Legato',
    cooldown: 2,
  ),
  HeroSkill('costola', 'Costola Estratta', 'Ossa', 'guard', 'vita', 1, 5),
  HeroSkill(
    'schegge',
    'Schegge Bianche',
    'Ossa',
    'area',
    'materia',
    2,
    2,
    cooldown: 2,
  ),
  HeroSkill(
    'veleno',
    'Morso Verde',
    'Veleno',
    'attack',
    'oculum',
    1,
    2,
    condition: 'Avvelenato',
  ),
  HeroSkill('antidoto', 'Linfa Amara', 'Veleno', 'heal', 'materia', 2, 2),
  HeroSkill(
    'radice',
    'Radice del Giuramento',
    'Piante',
    'control',
    'materia',
    1,
    0,
    condition: 'Legato',
    cooldown: 2,
  ),
  HeroSkill('linfa', 'Innesto Vivo', 'Piante', 'heal', 'oculum', 2, 3),
  HeroSkill(
    'prisma',
    'Prisma Rotto',
    'Cristallo',
    'area',
    'oculum',
    2,
    2,
    cooldown: 2,
  ),
  HeroSkill(
    'sfaccetta',
    'Sfaccettatura',
    'Cristallo',
    'setup',
    'materia',
    1,
    4,
  ),
  HeroSkill('lama', 'Lama Richiamata', 'Metallo', 'attack', 'volonta', 1, 4),
  HeroSkill(
    'magnete',
    'Presa Magnetica',
    'Metallo',
    'control',
    'materia',
    1,
    0,
    condition: 'Legato',
    cooldown: 2,
  ),
  HeroSkill(
    'eco',
    'Eco Vuota',
    'Suono',
    'control',
    'oculum',
    1,
    0,
    condition: 'Confuso',
    cooldown: 2,
  ),
  HeroSkill('coro', 'Coro delle Crepe', 'Suono', 'setup', 'volonta', 1, 3),
  HeroSkill(
    'sonno',
    'Sonno della Statua',
    'Sogno',
    'control',
    'oculum',
    2,
    0,
    condition: 'Stordito',
    cooldown: 3,
  ),
  HeroSkill('risveglio', 'Risveglio Rubato', 'Sogno', 'heal', 'oculum', 2, 3),
  HeroSkill(
    'cenere',
    'Marchio di Cenere',
    'Cenere',
    'control',
    'oculum',
    1,
    0,
    condition: 'Esposto',
  ),
  HeroSkill('ultima', 'Ultima Brace', 'Cenere', 'sacrifice', 'vita', 1, 4),
  HeroSkill(
    'velo',
    'Mantello Senza Volto',
    'Nebbia',
    'evade',
    'oculum',
    1,
    3,
    cooldown: 2,
  ),
  HeroSkill('umido', 'Velo Umido', 'Nebbia', 'guard', 'materia', 1, 3),
  HeroSkill(
    'peso',
    'Peso del Cielo',
    'Gravità',
    'control',
    'oculum',
    2,
    0,
    condition: 'Legato',
    cooldown: 2,
  ),
  HeroSkill(
    'caduta',
    'Caduta Senza Fine',
    'Gravità',
    'attack',
    'volonta',
    2,
    5,
  ),
  HeroSkill(
    'porta',
    'Porta Nera',
    'Spazio',
    'evade',
    'oculum',
    2,
    4,
    cooldown: 2,
  ),
  HeroSkill(
    'fenditura',
    'Fenditura Vicina',
    'Spazio',
    'attack',
    'oculum',
    2,
    4,
    condition: 'Esposto',
  ),
];

class HeroSkillAchievement {
  const HeroSkillAchievement(this.skillId, this.name, this.requirement);
  final String skillId, name, requirement;
  String get id => 'art_$skillId';
}

// One unlock per locked Skill: exactly half of the 42-card catalogue.
const heroSkillAchievements = <HeroSkillAchievement>[
  HeroSkillAchievement(
    'istante',
    'Padrone del ritmo',
    'Conferma 3 nemici sconfitti in una run.',
  ),
  HeroSkillAchievement(
    'fornace',
    'Fuoco paziente',
    'Conferma 6 nemici sconfitti in una run.',
  ),
  HeroSkillAchievement('brina', 'Primo inverno', 'Raggiungi la scena 6.'),
  HeroSkillAchievement(
    'scatto',
    'Passo salvo',
    'Evita o fuggi da un incontro.',
  ),
  HeroSkillAchievement(
    'soffio',
    'Tre vie di fuga',
    'Evita o fuggi da 3 incontri in una run.',
  ),
  HeroSkillAchievement('argilla', 'Promessa mantenuta', 'Completa una Quest.'),
  HeroSkillAchievement(
    'pioggia',
    'Due promesse',
    'Completa 2 Quest in una run.',
  ),
  HeroSkillAchievement(
    'parassita',
    'Sussurro raccolto',
    'Ottieni un Occhio dei Caduti.',
  ),
  HeroSkillAchievement('specchio', 'Prima ascesa', 'Raggiungi il livello 2.'),
  HeroSkillAchievement(
    'filo',
    'Filo del destino',
    'Raggiungi 2 punti Destino.',
  ),
  HeroSkillAchievement(
    'schegge',
    'Oltre la frattura',
    'Raggiungi il livello 4.',
  ),
  HeroSkillAchievement(
    'antidoto',
    'Pelle che ricorda',
    'Ottieni adattamento contro un danno.',
  ),
  HeroSkillAchievement(
    'linfa',
    'Radici profonde',
    'In modalità Invecchiamento, sblocca la sopravvivenza della Foresta.',
  ),
  HeroSkillAchievement('sfaccetta', 'Nome conquistato', 'Scegli un Titolo.'),
  HeroSkillAchievement('magnete', 'Ferro nuovo', 'Migliora la tua arma.'),
  HeroSkillAchievement(
    'coro',
    'Voci della città',
    'Sblocca l’accesso alla Città.',
  ),
  HeroSkillAchievement(
    'risveglio',
    'Soglia del sogno',
    'Sblocca il Giardino del Sogno.',
  ),
  HeroSkillAchievement(
    'ultima',
    'Secondo respiro',
    'Sopravvivi a un tiro contro la morte.',
  ),
  HeroSkillAchievement('umido', 'Lunga veglia', 'Raggiungi la scena 12.'),
  HeroSkillAchievement('caduta', 'Passo nella Landa', 'Sblocca la Landa Nera.'),
  HeroSkillAchievement(
    'fenditura',
    'Arte affinata',
    'Potenzia una carta al livello 1.',
  ),
];

HeroSkillAchievement? heroSkillUnlock(String id) {
  for (final achievement in heroSkillAchievements) {
    if (achievement.skillId == id) return achievement;
  }
  return null;
}

bool heroSkillAvailable(String id, Set<String> achievements) {
  if (!heroSkills.any((skill) => skill.id == id)) return false;
  final unlock = heroSkillUnlock(id);
  return unlock == null || achievements.contains(unlock.id);
}

class HeroTitle {
  const HeroTitle(this.id, this.name, this.effect, this.description);
  final String id, name, effect, description;
}

const heroTitles = <HeroTitle>[
  HeroTitle(
    'custode',
    'Custode della Soglia',
    'shield',
    '+1 Scudo all’inizio degli incontri.',
  ),
  HeroTitle(
    'cerusico',
    'Cerusico Senza Casa',
    'medicine',
    '+1 ai tiri Medicina.',
  ),
  HeroTitle(
    'fuggiasco',
    'Fuggiasco delle Campane',
    'escape',
    '+1 ai tentativi di fuga.',
  ),
  HeroTitle(
    'cacciatore',
    'Cacciatore di Silenzi',
    'quiet',
    'L’Alce fatica a percepirti.',
  ),
  HeroTitle(
    'ospite',
    'Ospite degli Alberi Bianchi',
    'forest',
    'Adattamento ambientale più rapido.',
  ),
  HeroTitle(
    'mercante',
    'Mercante di Ceneri',
    'trade',
    'Un Obser in più dalle cacce del Villaggio.',
  ),
  HeroTitle(
    'legatore',
    'Legatore dei Caduti',
    'bond',
    '+1 Sintonia a ogni evocazione.',
  ),
  HeroTitle(
    'minatore',
    'Minatore delle Vene',
    'ore',
    'Un minerale in più quando trovi una vena.',
  ),
  HeroTitle(
    'guardiano',
    'Guardiano della Brace',
    'guard',
    '+1 Scudo usando Difenditi.',
  ),
  HeroTitle(
    'pelle',
    'Pelle di Cenere',
    'adapt',
    'Apprendi più rapidamente dagli attacchi trattati.',
  ),
  HeroTitle(
    'lanterna',
    'Lanterna tra i Denti',
    'light',
    'Più incontri con viandanti; meno imboscate.',
  ),
  HeroTitle(
    'sognatore',
    'Sognatore del Pozzo',
    'dream',
    'Apre gli incontri del sogno.',
  ),
  HeroTitle(
    'rosso',
    'Testimone Rosso',
    'red',
    'Può trattare con i Corrotti Rossi.',
  ),
  HeroTitle(
    'cartografo',
    'Cartografo delle Cicatrici',
    'path',
    'Rivela la via della Landa Nera.',
  ),
  HeroTitle(
    'carnaio',
    'Santo del Carnaio',
    'sacrifice',
    'Le carte Vitalità infliggono +1 danno.',
  ),
  HeroTitle(
    'eco',
    'Portatore dell’Eco',
    'control',
    'Le condizioni inflitte durano un turno in più.',
  ),
  HeroTitle('ultimo', 'Ultimo della Veglia', 'rest', '+1 Vita dopo il riposo.'),
  HeroTitle('ago', 'Ago nel Buio', 'exposed', '+1 danno ai bersagli Esposti.'),
  HeroTitle(
    'archivista',
    'Archivista dei Perduti',
    'quest',
    'Le Quest completate donano una Dust.',
  ),
  HeroTitle(
    'ritorno',
    'Colui che è Tornato',
    'survivor',
    '+1 Scudo dopo una rinascita.',
  ),
];

class HeroMonster {
  const HeroMonster(
    this.id,
    this.name,
    this.description,
    this.family,
    this.role,
    this.locations, {
    this.weapon = '',
    this.boss = false,
    this.mini = false,
  });
  final String id, name, description, family, role, weapon;
  final List<String> locations;
  final bool boss, mini;
}

const heroMonsters = <HeroMonster>[
  HeroMonster(
    'lupo',
    'Lupo Scorticato',
    'Il pelo nasconde cicatrici fresche.',
    'Taglio',
    'hunter',
    ['Foresta', 'Villaggio'],
  ),
  HeroMonster(
    'cervello',
    'Cervello Errante',
    'Cerca un cranio ancora caldo.',
    'Mente',
    'brain',
    ['Dungeon', 'Landa Nera', 'Città'],
  ),
  HeroMonster(
    'capo_cervelli',
    'Capo dei Cervelli',
    'La colonia pulsa al suo ritmo.',
    'Mente',
    'beam',
    ['Dungeon', 'Landa Nera'],
    boss: true,
  ),
  HeroMonster(
    'diverso_tank',
    'Diverso Muraglia',
    'Ossa intrecciate chiudono il sentiero.',
    'Impatto',
    'tank',
    ['Landa Nera', 'Foresta', 'Dungeon'],
  ),
  HeroMonster(
    'diverso_assalto',
    'Diverso Segugio',
    'Corre sulle proprie nocche.',
    'Taglio',
    'assault',
    ['Landa Nera', 'Foresta', 'Dungeon'],
  ),
  HeroMonster(
    'diverso_lancia',
    'Diverso Portalance',
    'Ha imparato a impugnare ciò che lo trafisse.',
    'Perforazione',
    'armed',
    ['Landa Nera', 'Dungeon'],
    weapon: 'Lancia',
  ),
  HeroMonster(
    'diverso_ascia',
    'Diverso Spaccaporte',
    'Trascina un’ascia più vecchia del suo volto.',
    'Taglio',
    'armed',
    ['Landa Nera', 'Città'],
    weapon: 'Ascia',
  ),
  HeroMonster(
    'alce',
    'Alce dagli Occhi Ciechi',
    'Le corna tremano a ogni tuo respiro.',
    'Impatto',
    'elk',
    ['Foresta', 'Landa Nera'],
    mini: true,
  ),
  HeroMonster(
    'rosso',
    'Corrotto Rosso',
    'Sotto la pelle qualcosa cerca una via d’uscita.',
    'Corruzione',
    'transform',
    ['Città'],
  ),
  HeroMonster(
    'eiva',
    'Eiva della Carne Bianca',
    'Dieci cicatrici, dieci vite consumate.',
    'Corruzione',
    'eiva',
    ['Città', 'Landa Nera'],
    boss: true,
  ),
  HeroMonster(
    'ossa',
    'Raccoglitore d’Ossa',
    'Tra gli alberi bianchi trascina resti umani.',
    'Perforazione',
    'guard',
    ['Landa Nera', 'Dungeon'],
  ),
  HeroMonster(
    'carne',
    'Radice di Carne',
    'Il terreno nero respira sotto i tuoi piedi.',
    'Veleno',
    'root',
    ['Landa Nera'],
  ),
  HeroMonster(
    'brace',
    'Sacrestano di Brace',
    'Benedice con mani ancora in fiamme.',
    'Fuoco',
    'burn',
    ['Dungeon', 'Landa Nera'],
  ),
  HeroMonster(
    'guardia',
    'Guardia Senza Turno',
    'Nessuno le ha detto che la prigione è caduta.',
    'Taglio',
    'armed',
    ['Dungeon', 'Città'],
    weapon: 'Spada',
  ),
];

const dungeonScenarios = {
  'cripte': 'I nomi sono stati raschiati dalle lapidi.',
  'miniere': 'Un carrello torna dal buio. È vuoto, ma geme.',
  'prigioni': 'Qualcuno serve ancora la cena alle celle vuote.',
  'templi distrutti': 'La statua prega rivolta al muro.',
  'strutture organiche': 'La porta si apre quando smetti di respirare.',
  'catacombe': 'Le ossa indicano tutte la stessa direzione.',
  'laboratori': 'Un cuore continua a battere dentro il vetro.',
  'rovine': 'Le scale ricordano un piano che non esiste più.',
  'fogne': 'Sotto l’acqua passa un’ombra troppo lunga.',
  'sale rituali': 'Il cerchio è interrotto dall’interno.',
  'stanze infestate': 'Una sedia si sposta per farti posto.',
  'grotte': 'Il vento restituisce una voce che non è la tua.',
  'aree contaminate': 'I funghi crescono soltanto sulle impronte.',
};

class HeroEvent {
  const HeroEvent(
    this.id,
    this.text,
    this.choices, {
    this.locations = const [],
    this.requiredFlag = '',
    this.excludedFlag = '',
    this.cooldown = 4,
    this.weight = 10,
    this.tag = '',
  });
  final String id, text, requiredFlag, excludedFlag, tag;
  final List<String> locations, choices;
  final int cooldown, weight;
}

const heroEvents = <HeroEvent>[
  HeroEvent(
    'mappa_viandante',
    'Nella bisaccia abbandonata riconosci il segno del viandante.',
    ['Prendi la mappa', 'Lasciala'],
    locations: ['Villaggio', 'Foresta'],
    cooldown: 0,
    tag: 'quest',
  ),
  HeroEvent(
    'tracce_citta',
    'Il carovaniere sistema i sacchi. Conosce ogni porta della città.',
    ['Chiedi la strada'],
    locations: ['Villaggio'],
    cooldown: 0,
    tag: 'quest',
  ),
  HeroEvent(
    'eco_campana',
    'Una crepa nella pietra ripete l’ultimo rintocco.',
    ['Restituisci l’eco', 'Custodiscila'],
    locations: ['Dungeon'],
    cooldown: 0,
    tag: 'quest',
  ),
  HeroEvent(
    'tracce_campana',
    'Le impronte scendono verso una corda annodata.',
    ['Segui le tracce'],
    locations: ['Dungeon'],
    cooldown: 0,
    tag: 'quest',
  ),
  HeroEvent(
    'residuo_eiva',
    'La fonte è spenta. Nei canali resta una polvere rossa.',
    ['Purifica i resti'],
    locations: ['Città'],
    cooldown: 0,
    tag: 'quest',
  ),
  HeroEvent(
    'ritorno_memoria',
    'Il focolare si accende prima che tu tocchi la brace.',
    ['Affida il ricordo'],
    locations: ['Villaggio'],
    cooldown: 0,
    tag: 'quest',
  ),
  HeroEvent(
    'fonte_eiva',
    'Sotto la piazza, una creatura respira per tutta la città.',
    ['Affronta l’Eiva', 'Cerca un’altra soluzione'],
    locations: ['Città'],
    cooldown: 0,
    tag: 'quest',
  ),
  HeroEvent(
    'sigillo_eiva',
    'La corruzione passa da una sola chiusa.',
    ['Chiudi il canale'],
    locations: ['Città'],
    cooldown: 0,
    tag: 'quest',
  ),
  HeroEvent(
    'viandante',
    'Un viandante è preso sotto un carro. Il cavallo aspetta ancora.',
    ['Libera il viandante', 'Prendi la borsa', 'Prosegui'],
    excludedFlag: 'viandante_morto',
    tag: 'npc',
  ),
  HeroEvent(
    'ritorno',
    'Il viandante ti riconosce. «La città ha una porta che non sorvegliano.»',
    ['Segui la guida', 'Resta qui'],
    requiredFlag: 'viandante_salvo',
    excludedFlag: 'citta_aperta',
    cooldown: 8,
    weight: 30,
    tag: 'quest',
  ),
  HeroEvent(
    'colonia',
    'Piccole masse rosa si passano un elmo. Dentro c’è ancora una testa.',
    ['Affronta la colonia', 'Passa in silenzio'],
    locations: ['Dungeon', 'Landa Nera'],
    tag: 'brain',
  ),
  HeroEvent(
    'follia',
    'La tua ombra arriva al bivio prima di te. Poi si volta.',
    ['Segui l’ombra', 'Resisti', 'Scappa'],
    tag: 'madness',
  ),
  HeroEvent(
    'vena',
    'Una vena lucida attraversa la pietra. Senti battere dall’altro lato.',
    ['Estrai il minerale', 'Ascolta la roccia', 'Prosegui'],
    locations: ['Dungeon', 'Landa Nera'],
    tag: 'ore',
  ),
  HeroEvent(
    'tazza',
    'Una vecchia offre una tazza vuota. «Il prezzo viene dopo.»',
    ['Bevi', 'Rifiuta'],
    cooldown: 10,
    tag: 'cup',
  ),
  HeroEvent(
    'altare',
    'Una palpebra di pietra custodisce un piccolo occhio.',
    ['Raccogli l’Occhio', 'Lascia un’offerta', 'Prosegui'],
    cooldown: 12,
    tag: 'eye',
  ),
  HeroEvent(
    'rosso',
    'Un cittadino stringe il braccio che ha iniziato a parlare.',
    ['Aiutalo', 'Affrontalo', 'Cerca la fonte'],
    locations: ['Città'],
    tag: 'corruption',
  ),
  HeroEvent(
    'sogno',
    'La persona che hai perduto ti tiene un posto accanto al fuoco.',
    ['Ascolta', 'Spegni il fuoco'],
    requiredFlag: 'sogno_aperto',
    tag: 'dream',
  ),
  HeroEvent(
    'memoria',
    'Riconosci una cicatrice sulla porta. L’avevi lasciata in un’altra vita.',
    ['Apri la porta', 'Prosegui'],
    requiredFlag: 'memoria',
    tag: 'meta',
  ),
  HeroEvent(
    'bivio',
    'Tra i tronchi bianchi corre un sentiero di foglie rosse.',
    ['Entra nella Landa', 'Segna il sentiero', 'Prosegui'],
    requiredFlag: 'landa_aperta',
    tag: 'path',
  ),
  HeroEvent(
    'incontro',
    'Qualcosa si muove oltre il sentiero. Non sembra averti sentito.',
    ['Avvicinati', 'Evitalo', 'Attira la creatura'],
    cooldown: 0,
    weight: 25,
    tag: 'combat',
  ),
  HeroEvent(
    'riparo',
    'Una tettoia regge ancora. Sul tavolo restano pane e una candela.',
    ['Riposa', 'Esamina il tavolo', 'Prosegui'],
    cooldown: 3,
    tag: 'rest',
  ),
  HeroEvent(
    'quest_campana',
    'Una campana suona sotto terra. La corda sale invece verso il cielo.',
    ['Cerca il campanaro', 'Taglia la corda', 'Prosegui'],
    excludedFlag: 'campana_finita',
    tag: 'quest',
  ),
  HeroEvent(
    'campanaro',
    'Il campanaro ha le mani legate. La campana suona con il suo cuore.',
    ['Libera il campanaro', 'Prendi il cuore'],
    requiredFlag: 'campana_cercata',
    excludedFlag: 'campana_finita',
    locations: ['Dungeon', 'Landa Nera'],
    weight: 35,
    tag: 'quest',
  ),
];

const heroFoods = <String, (int, String, String, int)>{
  'Zuppa scura': (2, 'resilienza', 'giorno', 2),
  'Pane di corteccia': (3, 'materia', 'giorno', 2),
  'Cuore sotto sale': (15, 'volonta', 'run', 1),
  'Frutto bianco': (18, 'oculum', 'run', 1),
};
const heroMinerals = <String, int>{
  'Ferro opaco': 1,
  'Argento nero': 2,
  'Ossidiana viva': 3,
  'Cristallo Oculum': 4,
};

/// Short technique descriptions shared by encounter inspection and Monster Book.
const heroMonsterTechniques = <String, List<(String, String)>>{
  'brain': [
    ('Presa Cranica', 'Confondi il bersaglio e consumi 1 Oculum.'),
    ('Ospite Rubato', 'Passi a un ospite: +2 Scudo e +2 danno per due turni.'),
    ('Interferenza', 'Disturbi la Volontà del bersaglio: −2 al tiro.'),
  ],
  'beam': [
    (
      'Raggio del Capo',
      'Infliggi il doppio del danno; 18 naturale ignora Scudo, 20 naturale anche Difesa.',
    ),
    ('Comando di Colonia', 'Coordini gli ospiti della colonia.'),
    ('Interferenza Sovrana', 'Confondi il bersaglio prima del raggio.'),
  ],
  'elk': [
    ('Incornata', 'Aumenti il danno di +20. CD 2 turni.'),
    (
      'Ascolto Cieco',
      'Percepisci Oculum e rumori; il silenzio ostacola la tua caccia.',
    ),
    (
      'Corna Spezzate',
      'Le tue corna possono diventare un componente arma: +15 danno.',
    ),
  ],
  'tank': [
    ('Muro Vivente', 'La tua carne resiste; infliggi meno danni.'),
    ('Blocco', 'Rendi Legato chi tenta di passarti accanto.'),
    ('Ossa a Scudo', 'Proteggi la tua posizione con Materia superiore.'),
  ],
  'assault': [
    ('Pressione', 'Il tuo assalto infligge +2 danni.'),
    ('Inseguimento', 'Aumenti di 2 la difficoltà della fuga.'),
    ('Passo Affamato', 'Insegui il bersaglio attraverso la zona.'),
  ],
  'armed': [
    ('Arma Reale', 'La tua arma modifica il danno: Ascia +3, altre armi +1.'),
    ('Punta Ferma', 'La Lancia rende Legato il bersaglio.'),
    (
      'Ferita Aperta',
      'Il colpo può causare Sanguinante: contrasto di Resilienza.',
    ),
  ],
  'transform': [
    ('Seconda Pelle', 'A metà Vita ti trasformi: +3 Scudo e +2 danno.'),
    ('Voce dell’Eiva', 'La trasformazione aumenta la Corruzione.'),
    ('Contagio', 'Porti il segno di una creatura oltre il livello 9.'),
  ],
  'eiva': [
    ('Corruzione Rossa', 'Ogni ferita aumenta la Corruzione.'),
    ('Decima Cicatrice', 'La tua evoluzione ha superato il livello 9.'),
    (
      'Carne Sovrana',
      'La tua crescita da Boss ottiene +12 punti ogni tre livelli.',
    ),
  ],
  'guard': [
    ('Raccolta d’Ossa', 'Recuperi 1 Scudo a ogni turno.'),
    ('Punta Bianca', 'Le ferite perforanti possono causare Sanguinante.'),
    ('Custode', 'Difendi il passaggio tra le ossa.'),
  ],
  'root': [
    ('Radici', 'Rendi Legato il bersaglio.'),
    ('Linfa Guasta', 'Il tuo attacco appartiene alla famiglia Veleno.'),
    ('Carne della Landa', 'Nascondi il corpo sotto il terreno nero.'),
  ],
  'burn': [
    ('Mani di Brace', 'Quando ferisci applichi Brucia per due turni.'),
    ('Benedizione Cava', 'Il tuo attacco appartiene alla famiglia Fuoco.'),
    ('Veglia', 'Controlli il passaggio al tempio distrutto.'),
  ],
  'hunter': [
    ('Morso', 'Le tue ferite possono causare Sanguinante.'),
    ('Fiuto', 'Insegui chi fugge dal tuo territorio.'),
    ('Caccia', 'Affronti chi attraversa il sentiero.'),
  ],
};

/// Scenario changes are used by event selection, encounter roles and loot.
const heroScenarioProfiles = <String, (List<String>, String, int)>{
  'cripte': (['guard', 'tank'], 'quest', 10),
  'miniere': (['root', 'armed'], 'ore', 65),
  'prigioni': (['armed', 'brain'], 'npc', 10),
  'templi distrutti': (['burn', 'guard'], 'quest', 15),
  'strutture organiche': (['brain', 'root'], 'madness', 20),
  'catacombe': (['guard', 'assault'], 'eye', 20),
  'laboratori': (['brain', 'transform'], 'corruption', 35),
  'rovine': (['armed', 'hunter'], 'path', 30),
  'fogne': (['root', 'transform'], 'corruption', 10),
  'sale rituali': (['burn', 'beam'], 'quest', 20),
  'stanze infestate': (['assault', 'tank'], 'dream', 10),
  'grotte': (['hunter', 'elk'], 'ore', 50),
  'aree contaminate': (['transform', 'root'], 'madness', 25),
};
