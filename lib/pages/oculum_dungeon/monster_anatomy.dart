part of 'monster_book.dart';

/// Read anatomy from the physical description, never from a spell it can cast.
String oculumMonsterPhysicalDescription(MonsterBookEntry entry) => entry.descIt
    .split(
      RegExp(
        r'Ruolo in scena:|Skill per il giocatore:|Abilità per il giocatore:',
      ),
    )
    .first
    .toLowerCase();

bool oculumFateCoreReflects(MonsterBookEntry? entry, String part) =>
    entry != null &&
    (entry.id == 'fate_golem' || entry.id.startsWith('fate_golem_variante_')) &&
    part == 'fairy_core';

/// A hidden internal weak point is not revealed by opening the target picker.
/// Keep the full anatomy available to discovery and hit resolution, and never
/// reinterpret an explicit saved Master anatomy as a catalogue default.
List<Map<String, dynamic>> oculumMonsterPrecisionChoices(
  Iterable<Map<String, dynamic>> parts, {
  required MonsterBookEntry? monster,
  required bool weakPointDiscovered,
}) {
  final choices = parts.map((p) => Map<String, dynamic>.from(p)).toList();
  final custom = monster?.encounterRules['precisionBodyParts'];
  if (monster?.id.split('_variante_').first == 'cavaliere_morto' &&
      !weakPointDiscovered &&
      !(custom is List && custom.isNotEmpty)) {
    choices.removeWhere((p) => p['id'] == 'core' || p['group'] == 'core');
  }
  return choices;
}

/// An elemental vulnerability is not automatically a body location to aim at.
/// Explicit Master rules can still define a different, saved custom anatomy.
bool oculumMonsterHasAnatomicalWeakPoint(MonsterBookEntry? entry) {
  if (entry == null) return true;
  final explicit = entry.encounterRules['hasAnatomicalWeakPoint'];
  if (explicit is bool) return explicit;
  if (entry.id.split('_variante_').first != 'gigante_sabbia') return true;
  final custom = entry.encounterRules['precisionBodyParts'];
  return custom is List &&
      custom.whereType<Map>().any((p) => p['weak'] == true);
}

String oculumLogicalMonsterWeakPoint(
  MonsterBookEntry entry, {
  bool english = false,
}) {
  final text =
      '${entry.id} ${entry.speciesNameIt} ${oculumMonsterPhysicalDescription(entry)}'
          .toLowerCase();
  String pair(String it, String en) => english ? en : it;
  bool has(String pattern) => RegExp(pattern).hasMatch(text);
  if (entry.id.split('_variante_').first == 'cavaliere_morto') {
    return pair(
      'La sfera di Oculum nascosta alla base della vita.',
      'The Oculum sphere hidden at the base of the waist.',
    );
  }
  if (entry.id == 'pinepine' || entry.id.startsWith('pinepine_variante_')) {
    return pair(
      'Una squama naturalmente più tenera fra le protezioni della pigna integra.',
      'A naturally softer scale among the plates of its intact pine-cone shell.',
    );
  }
  if (has(r'headless|decapitat|senza testa')) {
    return pair(
      'Il moncone del collo, dove la forza che muove il corpo rimane esposta.',
      'The neck stump, where the force animating the body is exposed.',
    );
  }
  if (has(r'pawn|meccanio|robot|automa|costrutto|golem')) {
    return pair(
      'La giuntura di manutenzione fra le piastre del corpo, scoperta durante il movimento.',
      'The maintenance joint between its body plates, exposed as it moves.',
    );
  }
  if (has(r'legno|albero|rovo|radici|pianta|fungo')) {
    return pair(
      'Il nodo tenero alla base del corpo, dove si uniscono le fibre portanti.',
      'The soft knot at the base of the body where its supporting fibres meet.',
    );
  }
  if (has(r'slime|gelatina|melma|plomp|sanguisuga')) {
    return pair(
      'La parte centrale più densa del corpo, visibile quando si allunga per colpire.',
      'The denser centre of its body, visible when it stretches to strike.',
    );
  }
  if (has(r'ragno|vespa|falena|scarabeo|insetto|mantide|scorpione')) {
    return pair(
      'La membrana fra torace e addome, meno protetta mentre cambia direzione.',
      'The membrane between thorax and abdomen, exposed as it turns.',
    );
  }
  if (has(r'pesce|piranha|squalo|anguilla')) {
    return pair(
      'La fessura delle branchie, che si apre prima dello scatto.',
      'The gill slit, which opens before a sudden dart.',
    );
  }
  if (has(r'serpente|serpe|vipera')) {
    return pair(
      'Le scaglie più sottili sotto la gola, esposte quando solleva il capo.',
      'The thinner scales beneath its throat, exposed when it raises its head.',
    );
  }
  if (has(
    r'mammuth|lupo|warg|cane|orso|cinghiale|iena|quadrupede|felino|leone|rinoceronte',
  )) {
    return pair(
      'La giuntura interna della zampa anteriore, scoperta durante l’affondo.',
      'The inner joint of a foreleg, exposed during a lunge.',
    );
  }
  if (has(r'incorpore|spettro|fantasma|spirito|wraith|ghost|ombra')) {
    return pair(
      'Il punto in cui il contorno della sua presenza si raccoglie e rimane definito durante l’attacco.',
      'The spot where the outline of its presence gathers and stays defined during an attack.',
    );
  }
  if (has(r'elementale|fiamma compatta|acqua viva|risonanza viva')) {
    return pair(
      'Il centro di condensazione dell’elemento, esposto quando prepara la tecnica.',
      'The condensation centre of its element, exposed while preparing a technique.',
    );
  }
  if (has(r'\bali\b|alato|angelo|arpia|uccello|rapace|grifone|drago|fata')) {
    return pair(
      'L’attaccatura dell’ala, scoperta fra due battiti.',
      'The wing root, exposed between wingbeats.',
    );
  }
  if (has(r'corazz|guscio|carapace|placca|conchiglia')) {
    return pair(
      'La giuntura fra le protezioni sul lato del corpo, esposta quando si volta.',
      'The joint between the side plates, exposed when it turns.',
    );
  }
  if (has(r'scheletro|teschio|ossa|morto')) {
    return pair(
      'Le giunture che collegano le braccia al torace, meno solide delle ossa lunghe.',
      'The joints connecting the arms to the chest, weaker than the long bones.',
    );
  }
  if (has(
    r'umano|goblin|coboldo|gnoll|orco|ogre|troll|gigante|bandito|monaco|cavaliere|mago|demone|diavolo|vampiro|cultista|pellegrino',
  )) {
    return pair(
      'L’interno del gomito dell’arto con cui attacca, scoperto quando distende la presa.',
      'The inside of the attacking elbow, exposed when it extends its reach.',
    );
  }
  if (has(r'occhio|occhi')) {
    return pair(
      'Il bordo esposto dell’occhio mentre mette a fuoco il bersaglio.',
      'The exposed rim of the eye as it focuses on a target.',
    );
  }
  if (has(r'specchio|vetro|cristallo')) {
    return pair(
      'La crepa più sottile nel bordo del corpo, esposta quando ruota.',
      'The thinnest crack in the body rim, exposed when it rotates.',
    );
  }
  return pair(
    'La piega meno protetta del corpo, esposta quando cambia direzione per attaccare.',
    'The least protected fold in its body, exposed as it turns to attack.',
  );
}

/// Stable, separate hit locations. Saved Master anatomy overrides win.
List<Map<String, dynamic>> oculumMonsterPrecisionAnatomy(
  MonsterBookEntry entry, {
  bool solarFaceUncovered = false,
}) {
  final custom = entry.encounterRules['precisionBodyParts'];
  if (custom is List && custom.isNotEmpty) {
    return [
      for (final p in custom.whereType<Map>()) Map<String, dynamic>.from(p),
    ];
  }
  final pinepine =
      entry.id == 'pinepine' || entry.id.startsWith('pinepine_variante_');
  final fireShield = entry.id.split('_variante_').first == 'fire_shield';
  final rockShield = entry.id.split('_variante_').first == 'rock_shield';
  final runicGolem = entry.id.split('_variante_').first == 'golem_runico';
  final canonicalBase = entry.id.split('_variante_').first;
  final reviewedPhysical = const {
    'deadly_sins':
        'umanoide, testa con elmo chiuso senza occhi visibili, torace, due braccia, due gambe e due corna di ferro',
    'rascalume':
        'roditore quadrupede, testa, torace, quattro zampe, due occhi, due orecchie, una coda e vibrisse',
    'mirula':
        'salamandra quadrupede, testa, torace, quattro zampe, due occhi, una coda e branchie esterne',
    'colosso_prismarite':
        'colosso umanoide di pietra, testa senza occhi, torace, due braccia sulle nocche e due gambe',
    'brumilio':
        'uccello, testa, becco, torace, due occhi, due ali, due zampe e una coda',
    'vendulo': 'quadrupede, testa, torace, quattro zampe e due occhi',
    'obliterated_devil':
        'umanoide, testa, torace, due braccia, due gambe, due occhi neri e due corna',
  }[canonicalBase];
  final reviewedCounts = const <String, Map<String, int>>{
    'deadly_sins': {'arms': 2, 'legs': 2, 'eyes': 0, 'horns': 2},
    'rascalume': {'legs': 4, 'eyes': 2, 'tail': 1},
    'mirula': {'legs': 4, 'eyes': 2, 'tail': 1},
    'colosso_prismarite': {'arms': 2, 'legs': 2, 'eyes': 0},
    'brumilio': {'legs': 2, 'wings': 2, 'eyes': 2, 'tail': 1},
    'vendulo': {'legs': 4, 'eyes': 2},
    // The third, weak eye is a separately labelled forehead target below.
    'obliterated_devil': {'arms': 2, 'legs': 2, 'eyes': 2, 'horns': 2},
  }[canonicalBase];
  // Confirmed artwork supplies missing physical facts, never new powers or
  // weak points. An explicit saved anatomy above remains authoritative.
  final confirmedPhysical =
      reviewedPhysical ??
      (pinepine
          ? 'umanoide, due braccia, due gambe, testa e due occhi'
          : fireShield
          ? 'bipede, testa, due braccia, due zampe, due occhi e due corna'
          : rockShield
          ? 'gigante umanoide bipede, testa, due braccia e due gambe'
          : runicGolem
          ? 'costrutto umanoide, due braccia, due gambe, testa a calotta senza occhi'
          : switch (entry.id) {
              'ciclope_non_morto' =>
                'umanoide, testa con un occhio centrale, torace, due braccia e due gambe',
              'inspired_sentinella_spirale' =>
                'costrutto con una lente centrale',
              'manichino_spada' || 'manichino_baghest' =>
                'umanoide, due braccia, due gambe e un occhio nella guardia della lama',
              'mostro_sabbia' =>
                'quadrupede, quattro zampe, due corna, testa e coda',
              'gigante_sabbia' =>
                'umanoide, due braccia, due gambe, due corna e coda',
              'costrutto_minore' =>
                'umanoide meccanico, due braccia, due gambe, due occhi',
              'funghetto_cappuccio_rosso' =>
                'umanoide fungino, due braccia, due gambe, testa, due occhi',
              'topino_avventuroso' =>
                'bipede umanoide, due braccia, due gambe, testa, due occhi, due orecchie e coda',
              'sharp' => 'quattro zampe, due occhi',
              'mosca_campana' => 'sei zampe, quattro ali, due occhi',
              'custode_campana_cieca' =>
                'umanoide, due braccia, due gambe, testa a campana, senza occhi',
              'sciamano_malizioso' =>
                'umanoide ligneo, due braccia, due gambe, testa mascherata, senza occhi biologici',
              'mammuth_in_decomposizione' =>
                'quadrupede, quattro zampe, due occhi, due orecchie, una proboscide, due zanne e coda',
              'shadow_devil' => 'due corna, senza occhi',
              'mezzo_demone_cosciente' || 'mezzo_demone_massiccio' =>
                'umanoide, due braccia, due gambe, due corna e due occhi',
              'forest_demon' =>
                'rettile quadrupede, quattro zampe, due occhi, tre corna e coda',
              'ciclo_forest_demon_blu' =>
                'rettile quadrupede, quattro zampe, due occhi, due corna e coda, senza ali',
              'famelico_oblio' =>
                'quadrupede, quattro zampe, due occhi, due corna, una coda',
              'saltalungo_maculato' =>
                'bipede, due braccia, due gambe, due occhi, due orecchie, una coda',
              'cloud_beast' =>
                'bipede lupino, due braccia, due gambe, due occhi, due orecchie, due corna, una coda',
              'laer' => 'umanoide, testa, due braccia, due gambe',
              'mostro_solare' =>
                'umanoide, testa, due braccia, due gambe, due occhi, un corno',
              'sciamano_malizioso_minore' =>
                'umanoide ligneo, testa, due braccia, due gambe, senza occhi biologici',
              'strana_presenza' =>
                'presenza umanoide, due braccia, due gambe, senza testa, senza occhi',
              'air_navigator' =>
                'testa, becco, due braccia, senza ali, senza gambe, senza zampe, vortice inferiore',
              'lupo_infernale_del_ghiaccio' =>
                'quadrupede, quattro zampe, testa, due occhi, due orecchie, una coda',
              _ => '',
            });
  final physical = entry.id.split('_variante_').first == 'cavaliere_morto'
      // The optional summoned woman is not a body part of the empty armour.
      ? 'armatura vuota umanoide, due braccia, due gambe, elmo chiuso senza occhi, sfera di Oculum nascosta alla base della vita'
      : '${oculumMonsterPhysicalDescription(entry)} $confirmedPhysical';
  final identity = '${entry.id} ${entry.speciesNameIt} $physical'.toLowerCase();
  final weak = entry.weakPointDescriptionIt.toLowerCase();
  bool has(String pattern) => RegExp(pattern).hasMatch(identity);
  final spherical = has(
    r'thunder_bot|observer.?s.?tear|obser_sunshine|torretta_oculum|slime|gelatina|melma|occhio_caduto|plomp',
  );
  final incorporeal =
      !pinepine &&
      has(r'incorporeo|incorporea|senza corpo|elementale|spettro|fantasma');
  final approvedQuadruped = const {
    'mostro_sabbia',
    'forest_demon',
    'ciclo_forest_demon_blu',
    'famelico_oblio',
  }.contains(entry.id);
  final humanoid =
      !spherical &&
      !incorporeal &&
      !approvedQuadruped &&
      has(
        r'umano|goblin|coboldo|gnoll|\borco\b|\bogre\b|troll|gigante|bandit|scostum|monaco|cavalier|mago|demone|diavolo|vampiro|scheletro|teschio|cultista|pellegrino|angelo|adoratore|feralis|manichino|pupazzo',
      );
  final quadruped =
      !spherical &&
      has(
        r'\b(?:quadrupede|mammuth|lupo|warg|cane|orso|cinghiale|iena|felino|leone|rinoceronte|grifone|drago|basilisco)\b',
      );
  final parts = <Map<String, dynamic>>[];
  const numbers = {
    'un': 1,
    'uno': 1,
    'una': 1,
    'due': 2,
    'tre': 3,
    'quattro': 4,
    'cinque': 5,
    'sei': 6,
    'sette': 7,
    'otto': 8,
    'nove': 9,
    'dieci': 10,
  };
  int count(String noun, int fallback) {
    // Do not count the same limbs twice when the description already contains
    // a number and the approved-art facts repeat it.
    final canonicalCounts =
        reviewedCounts ??
        (pinepine
            ? {'arms': 2, 'legs': 2, 'eyes': 2}
            : fireShield
            ? {'arms': 2, 'legs': 2, 'eyes': 2, 'horns': 2}
            : rockShield
            ? {'arms': 2, 'legs': 2}
            : runicGolem
            ? {'arms': 2, 'legs': 2, 'eyes': 0}
            : switch (entry.id) {
                'ciclope_non_morto' => {'arms': 2, 'legs': 2, 'eyes': 1},
                'inspired_sentinella_spirale' => {'eyes': 1},
                'manichino_spada' ||
                'manichino_baghest' => {'arms': 2, 'legs': 2, 'eyes': 1},
                'mostro_sabbia' => {'legs': 4, 'eyes': 2, 'horns': 2},
                'gigante_sabbia' => {
                  'arms': 2,
                  'legs': 2,
                  'eyes': 2,
                  'horns': 2,
                },
                'costrutto_minore' ||
                'funghetto_cappuccio_rosso' ||
                'topino_avventuroso' => {'arms': 2, 'legs': 2, 'eyes': 2},
                'sharp' => {'legs': 4, 'eyes': 2},
                'mosca_campana' => {'legs': 6, 'wings': 4, 'eyes': 2},
                'custode_campana_cieca' ||
                'sciamano_malizioso' => {'arms': 2, 'legs': 2},
                'mammuth_in_decomposizione' => {'legs': 4, 'eyes': 2},
                'shadow_devil' => {'horns': 2},
                'mezzo_demone_cosciente' || 'mezzo_demone_massiccio' => {
                  'arms': 2,
                  'legs': 2,
                  'eyes': 2,
                  'horns': 2,
                },
                'nuvola_in_bottiglia' => {'eyes': 1},
                'forest_demon' => {'legs': 4, 'eyes': 2, 'horns': 3},
                'ciclo_forest_demon_blu' => {'legs': 4, 'eyes': 2, 'horns': 2},
                'famelico_oblio' => {
                  'legs': 4,
                  'eyes': 2,
                  'horns': 2,
                  'tail': 1,
                },
                'saltalungo_maculato' => {
                  'arms': 2,
                  'legs': 2,
                  'eyes': 2,
                  'tail': 1,
                },
                'cloud_beast' => {
                  'arms': 2,
                  'legs': 2,
                  'eyes': 2,
                  'horns': 2,
                  'tail': 1,
                },
                'laer' || 'sciamano_malizioso_minore' => {'arms': 2, 'legs': 2},
                'mostro_solare' => {
                  'arms': 2,
                  'legs': 2,
                  'eyes': 2,
                  'horns': 1,
                },
                'strana_presenza' => {'arms': 2, 'legs': 2},
                'air_navigator' => {'arms': 2},
                'lupo_infernale_del_ghiaccio' => {
                  'legs': 4,
                  'eyes': 2,
                  'tail': 1,
                },
                _ => <String, int>{},
              });
    final group = switch (noun) {
      'braccia|braccio' => 'arms',
      'gambe|zampe' => 'legs',
      'occhi|occhio|lenti|lente' => 'eyes',
      'ali' => 'wings',
      'corna|corno' => 'horns',
      'code|coda' => 'tail',
      _ => noun,
    };
    if (canonicalCounts.containsKey(group)) return canonicalCounts[group]!;
    final pattern = RegExp(
      '\\b(\\d+|${numbers.keys.join('|')})\\s+(?:(coppie|coppia|paia|paio)\\s+di\\s+)?(?:piccol[ei]\\s+|grand[ei]\\s+|lunghe\\s+|corte\\s+|principali\\s+|posteriori\\s+|anteriori\\s+)?(?:$noun)\\b',
    );
    final matches = pattern.allMatches(physical).toList();
    if (matches.isEmpty) return fallback;
    return matches
        .fold<int>(
          0,
          (n, m) =>
              n +
              (numbers[m[1]] ?? int.tryParse(m[1]!) ?? fallback) *
                  (m[2] == null ? 1 : 2),
        )
        .clamp(1, 12)
        .toInt();
  }

  void add(String id, String label, String group, bool vulnerable) {
    if (parts.any((p) => p['id'] == id)) return;
    parts.add({
      'id': id,
      'label': label,
      'group': group,
      'weak': vulnerable,
      'penalty': 0,
    });
  }

  void group(
    String id,
    String singular,
    String plural,
    int n,
    String weakPattern,
  ) {
    final vulnerable = RegExp(weakPattern).hasMatch(weak);
    for (var i = 0; i < n; i++) {
      final side = i.isEven ? 'destro' : 'sinistro';
      final feminine =
          id == 'wings' ||
          id == 'legs' ||
          id == 'tail' ||
          id == 'head' ||
          id == 'hands';
      final sideLabel = feminine ? (i.isEven ? 'destra' : 'sinistra') : side;
      final pair = n <= 2
          ? ''
          : n == 4
          ? (id == 'legs'
                ? (i < 2 ? ' anteriore' : ' posteriore')
                : (i < 2 ? ' superiore' : ' inferiore'))
          : ' · coppia ${i ~/ 2 + 1}';
      add(
        n == 1 ? id : '${id}_${i + 1}',
        n == 1 ? singular : '$singular $sideLabel$pair',
        id,
        vulnerable,
      );
      if (n > 1) {
        parts.last['side'] = i.isEven ? 'right' : 'left';
        parts.last['sideIndex'] = i ~/ 2 + 1;
      }
    }
  }

  add(
    'body',
    'Corpo',
    'body',
    RegExp(
      r'piega|fianco|pelle|corpo|contorno|condensazione|parte centrale',
    ).hasMatch(weak),
  );
  if (entry.id != 'mosca_campana' &&
      !spherical &&
      !has(r'headless|decapitat|senza testa|nessuna testa') &&
      (humanoid ||
          quadruped ||
          has(
            r'testa|cranio|muso|becco|insetto|ragno|vespa|falena|coniglio|nuvi|bringi',
          ))) {
    group(
      'head',
      'Testa',
      'Teste',
      count('teste|testa', 1),
      r'testa|cranio|gola|mascella|collo',
    );
  }
  if (!has(
        r'\b(?:senza occhi|nessun occhio|non (?:ha|hanno|possiede|possiedono|presenta|presentano) (?:gli |alcun[io]? )?occhi(?:o)?|priv[oaie] di occhi)\b',
      ) &&
      has(r'occhi|occhio|lenti|lente|pupilla')) {
    group(
      'eyes',
      switch (entry.id) {
        'ciclope_non_morto' => 'Occhio centrale',
        'inspired_sentinella_spirale' => 'Lente centrale',
        _ => has(r'lenti|lente') ? 'Lente' : 'Occhio',
      },
      'Occhi',
      count(
        'occhi|occhio|lenti|lente',
        has(r'occhio inciso|occhio centrale|singolo occhio|una sola lente')
            ? 1
            : 2,
      ),
      r'occhi|occhio|lente|pupilla',
    );
  }
  if (!spherical &&
      !approvedQuadruped &&
      (humanoid || has(r'\bbraccia\b|\bbraccio\b'))) {
    group(
      'arms',
      'Braccio',
      'Braccia',
      count('braccia|braccio', 2),
      r'\b(?:braccia|braccio|gomito|polso|mani|mano|arto)\b',
    );
  }
  if (!spherical &&
      !incorporeal &&
      !has(r'senza gambe|senza zampe|una sola ruota') &&
      (humanoid ||
          quadruped ||
          has(
            r'gambe|zampe|ragno|scorpione|insetto|vespa|scarabeo|falena|mantide',
          ))) {
    group(
      'legs',
      humanoid ? 'Gamba' : 'Zampa',
      'Zampe',
      count(
        'gambe|zampe',
        has(r'ragno|scorpione')
            ? 8
            : has(r'vespa|insetto|scarabeo|falena|mantide')
            ? 6
            : quadruped
            ? 4
            : 2,
      ),
      r'gambe|zampa|zampe|ginocchi|piede|piedi',
    );
  }
  if (!spherical &&
      !has(r'senza ali|non ha ali|non hanno ali|nessuna ala|priv[oa] di ali') &&
      (has(
            r'\b(?:ali|alato|alata)\b|arpia|uccello|rapace|angelo|grifone|drago|fata|falena|vespa',
          ) ||
          RegExp(r'\b(?:ala|ali|alare|alari)\b').hasMatch(weak))) {
    group(
      'wings',
      'Ala',
      'Ali',
      count('ali', entry.id.startsWith('nuvi') ? 4 : 2),
      r'\b(?:ala|ali|alare|alari|piume)\b',
    );
  }
  if (!spherical && has(r'\bcoda\b|\bcode\b')) {
    group('tail', 'Coda', 'Code', count('code|coda', 1), r'coda|code');
  }
  if (RegExp(r'\bcorna\b|\bcorno\b').hasMatch(confirmedPhysical)) {
    group('horns', 'Corno', 'Corna', count('corna|corno', 2), r'corna|corno');
  }
  if (const {
        'topino_avventuroso',
        'ogle',
        'saltalungo_maculato',
        'cloud_beast',
        'lupo_infernale_del_ghiaccio',
      }.contains(entry.id) ||
      canonicalBase == 'rascalume') {
    group('ears', 'Orecchio', 'Orecchie', 2, r'orecchio|orecchie');
  }
  if (entry.id == 'funghetto_cappuccio_rosso') {
    add('cap', 'Cappello fungino', 'cap', false);
  }
  if (entry.id == 'mammuth_in_decomposizione') {
    group('ears', 'Orecchio', 'Orecchie', 2, r'orecchio|orecchie');
    group('tusks', 'Zanna', 'Zanne', 2, r'zanna|zanne');
    for (final part in parts.where((p) => p['group'] == 'tusks')) {
      part['material'] = 'bone';
    }
    add('trunk', 'Proboscide', 'trunk', weak.contains('proboscide'));
    parts.last['material'] = 'flesh';
  }
  if (entry.id == 'custode_campana_cieca') {
    for (final part in parts) {
      part['material'] = 'metal';
      if (part['group'] == 'head') part['label'] = 'Campana-testa';
    }
  }
  if (entry.id == 'il_doppione') {
    add('crest', 'Corona di lembi', 'crest', true);
    parts.firstWhere((p) => p['id'] == 'body')['weak'] = false;
  }
  if (entry.id == 'laer') {
    add('joint', 'Giunture dell’armatura', 'joint', true);
    for (final part in parts) {
      part['material'] = const {'mask', 'joint'}.contains(part['group'])
          ? 'metal'
          : 'flesh';
    }
  }
  if (entry.id == 'sciamano_malizioso_minore') {
    parts.removeWhere((part) => part['group'] == 'mask');
    for (final part in parts) {
      part['material'] = 'wood';
      part['weak'] = part['group'] == 'head';
    }
  }
  if (entry.id == 'strana_presenza') {
    add('suspended_point', 'Punto sospeso nella corona', 'sensor', true);
    for (final part in parts) {
      part['material'] = 'spectral';
      part['weak'] = part['id'] == 'suspended_point';
    }
  }
  if (entry.id == 'air_navigator') {
    for (final part in parts) {
      part['material'] = 'flesh';
    }
    add('lower_vortex', 'Vortice inferiore', 'vortex', false);
    parts.last['material'] = 'spectral';
  }
  if (entry.id.startsWith('aberrazione_metallica_')) {
    for (final part in parts.where((p) => p['group'] == 'head')) {
      part['weak'] = false;
    }
    add('joint', 'Giunti d’oro del collo', 'joint', true);
    parts.last['material'] = 'metal';
  }
  if (entry.id == 'nuvola_in_bottiglia') {
    group('hands', 'Mano vaporosa', 'Mani', 2, r'mani|mano');
    group('receivers', 'Ricevitore di fulmini', 'Ricevitori', 2, r'ricevitor');
    for (final part in parts.where((p) => p['group'] == 'receivers')) {
      part['material'] = 'metal';
    }
    add('bottle', 'Bottiglia', 'bottle', true);
    parts.last['material'] = 'glass';
  }
  const details = [
    ('torso', 'Torace', r'petto|torace|costole'),
    ('belly', 'Ventre', r'pancia|ventre|addome'),
    ('core', 'Nucleo', r'nucleo|core'),
    ('heart', 'Cuore', r'cuore'),
    ('mask', 'Maschera', r'maschera'),
    ('antennae', 'Antenne', r'antenne|antenna'),
    ('gills', 'Branchie', r'branchie'),
    ('root', 'Nodo delle radici', r'radici|nodo tenero|fibre portanti'),
    ('runes', 'Rune esposte', r'rune esposte|nodo runico'),
    ('joint', 'Giuntura', r'giuntur[ae]|cernier[ae]|giunto equatoriale'),
    ('wound', 'Ferita aperta', r'ferite aperte|ferita aperta'),
    ('sensor', 'Nodo sensoriale', r'nodo sensoriale'),
    ('sac', 'Sacca', r'sacca'),
    ('rim', 'Bordo', r'bordo|crepa'),
    ('fold', 'Piega del corpo', r'piega|pieghe'),
    ('whiskers', 'Vibrisse', r'baffi|vibrisse'),
  ];
  for (final d in details) {
    final detail = RegExp('\\b(?:${d.$3})\\b');
    // Living among roots does not give an animal roots of its own. Keep
    // bodily roots and authored root weak points, and preserve saved anatomy
    // through the explicit override at the beginning of this function.
    if (d.$1 == 'root' &&
        !detail.hasMatch(weak) &&
        !RegExp(
          r'\b(?:corpo|pianta|tronco|arti|gambe|braccia|piedi|zampe|muschio)\b[^.!?;]*\bradici\b',
        ).hasMatch(physical)) {
      continue;
    }
    if (detail.hasMatch('$physical $weak')) {
      add(d.$1, d.$2, d.$1, detail.hasMatch(weak));
    }
  }
  if (canonicalBase == 'deadly_sins') {
    if (weak ==
        'la catena che collega il polso alla lama quando cambia forma.') {
      for (final part in parts) {
        part['weak'] = false;
      }
    }
    add(
      'weapon_chain',
      'Catena fra polso e lama',
      'chain',
      RegExp(r'\bcatena\b').hasMatch(weak),
    );
    parts.last['material'] = 'metal';
  }
  if (canonicalBase == 'colosso_prismarite') {
    for (final part in parts) {
      part['material'] = 'stone';
    }
  }
  if (canonicalBase == 'vendulo' &&
      weak == 'la pelle tenera sotto le due placche del muso.') {
    for (final part in parts) {
      part['weak'] = false;
    }
    add('facial_skin', 'Pelle sotto le placche del muso', 'skin', true);
    parts.last['material'] = 'flesh';
  }
  if (canonicalBase == 'obliterated_devil') {
    final thirdWeak = RegExp(r'\bterzo occhio\b').hasMatch(weak);
    if (weak ==
        'il margine chiaro attorno al terzo occhio, visibile durante la preparazione della sfera.') {
      for (final part in parts) {
        part['weak'] = false;
      }
    }
    add('third_eye', 'Terzo occhio sulla fronte', 'eyes', thirdWeak);
    parts.last['material'] = 'flesh';
  }
  const exactCoreWeakPoints = {
    'costrutto_prismatico': 'il nucleo prismatico nel torace.',
    'rock_cloud_golem':
        'il nucleo incassato al centro del petto, dietro la fascia di vapore.',
    'golem_runico':
        'il nucleo runico dietro le incisioni convergenti al centro del petto, mirabile soltanto dopo aver rotto le piastre frontali.',
  };
  if (weak == exactCoreWeakPoints[canonicalBase]) {
    for (final part in parts) {
      part['weak'] = part['id'] == 'core';
    }
  }
  if (canonicalBase == 'brumilio' &&
      weak == 'il petto, esposto fra due battiti d’ala.') {
    for (final part in parts) {
      part['weak'] = part['id'] == 'torso';
    }
  }
  if (canonicalBase == 'rock_shield' &&
      weak == 'le ferite aperte e la pelle sotto la pancia, tra le zampe.') {
    for (final part in parts) {
      part['weak'] = const {'belly', 'wound'}.contains(part['id']);
    }
  }
  if (canonicalBase == 'pupazzo_artigliato' &&
      weak ==
          'le molle sono visibili tra i segmenti delle gambe mentre le comprime.') {
    for (final part in parts) {
      part['weak'] = false;
    }
    add('leg_springs', 'Molle fra i segmenti delle gambe', 'joint', true);
    parts.last['material'] = 'metal';
  }
  if (canonicalBase == 'goblin_kamikaze' &&
      weak ==
          'l’innesco centrale sul ventre, da cui partono le micce verso le cariche laterali.') {
    final trigger = parts.where((p) => p['id'] == 'belly').firstOrNull;
    if (trigger != null) {
      trigger['label'] = 'Innesco centrale sul ventre';
    }
  }
  if (entry.id.split('_variante_').first == 'cavaliere_morto') {
    final sphereWeak = RegExp(r'sfera|sphere').hasMatch(weak);
    add('core', 'Sfera di Oculum alla base della vita', 'core', sphereWeak);
    for (final part in parts) {
      if (sphereWeak) part['weak'] = part['id'] == 'core';
      if (part['group'] == 'head') part['label'] = 'Elmo dell’armatura';
      part['material'] = part['id'] == 'core' ? 'oculum' : 'metal';
    }
  }
  if (pinepine) {
    add('soft_scale', 'Squama tenera', 'scale', true);
    parts.last['material'] = 'wood';
  }
  if (entry.id == 'il_doppione') {
    for (final part in parts) {
      part['weak'] = part['id'] == 'crest';
    }
  }
  if (const {
    'guardia_solare',
    'guardia_solare_elite',
    'guardiano_solare',
  }.contains(entry.id)) {
    // Lusier and Erik are confirmed personal exceptions to the full helmet.
    parts.removeWhere((p) => p['group'] == 'eyes');
    if (solarFaceUncovered) {
      group('eyes', 'Occhio', 'Occhi', 2, r'occhi|occhio');
    } else {
      add('helmet_visor', 'Visiera dell’elmo solare', 'sensor', false);
      parts.last['material'] = 'metal';
    }
  }
  if (entry.id == 'gigante_sabbia') {
    // Its only confirmed vulnerabilities are elemental, not an exposed core.
    parts.removeWhere(
      (p) => const {'core', 'heart', 'wound'}.contains(p['group']),
    );
    for (final part in parts) {
      part['weak'] = false;
    }
  }
  if (oculumFateCoreReflects(entry, 'fairy_core')) {
    parts.removeWhere((p) => p['group'] == 'core');
    add('fairy_core', 'Nucleo con fata', 'core', false);
    parts.last['reflectAttack'] = true;
  }
  return parts;
}
