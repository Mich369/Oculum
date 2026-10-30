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
      '${entry.id} ${entry.nameIt} ${oculumMonsterPhysicalDescription(entry)}'
          .toLowerCase();
  String pair(String it, String en) => english ? en : it;
  bool has(String pattern) => RegExp(pattern).hasMatch(text);
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
  // Confirmed artwork supplies missing physical facts, never new powers or
  // weak points. An explicit saved anatomy above remains authoritative.
  final confirmedPhysical = switch (entry.id) {
    'mostro_sabbia' => 'quadrupede, quattro zampe, due corna, testa e coda',
    'gigante_sabbia' => 'umanoide, due braccia, due gambe, due corna e coda',
    'costrutto_minore' =>
      'umanoide meccanico, due braccia, due gambe, due occhi',
    'funghetto_cappuccio_rosso' =>
      'umanoide fungino, due braccia, due gambe, testa, due occhi',
    'topino_avventuroso' =>
      'bipede umanoide, due braccia, due gambe, testa, due occhi, due orecchie e coda',
    'sharp' => 'quattro zampe, due occhi',
    'mosca_campana' => 'sei zampe, quattro ali, due occhi',
    'shadow_devil' => 'due corna, senza occhi',
    'mezzo_demone_cosciente' || 'mezzo_demone_massiccio' =>
      'umanoide, due braccia, due gambe, due corna e due occhi',
    'forest_demon' =>
      'rettile quadrupede, quattro zampe, due occhi, tre corna e coda',
    'ciclo_forest_demon_blu' =>
      'rettile quadrupede, quattro zampe, due occhi, due corna e coda, senza ali',
    _ => '',
  };
  final physical =
      '${oculumMonsterPhysicalDescription(entry)} $confirmedPhysical';
  final identity = '${entry.id} ${entry.nameIt} $physical'.toLowerCase();
  final weak = entry.weakPointDescriptionIt.toLowerCase();
  bool has(String pattern) => RegExp(pattern).hasMatch(identity);
  final spherical = has(
    r'thunder_bot|observer.?s.?tear|obser_sunshine|torretta_oculum|slime|gelatina|melma|occhio_caduto|plomp',
  );
  final incorporeal = has(
    r'incorporeo|incorporea|senza corpo|elementale|spettro|fantasma',
  );
  final humanoid =
      !spherical &&
      !incorporeal &&
      has(
        r'umano|goblin|coboldo|gnoll|orco|ogre|troll|gigante|bandit|scostum|monaco|cavalier|mago|demone|diavolo|vampiro|scheletro|teschio|cultista|pellegrino|angelo|adoratore|feralis|manichino|pupazzo',
      );
  final quadruped =
      !spherical &&
      has(
        r'quadrupede|mammuth|lupo|warg|cane|orso|cinghiale|iena|felino|leone|rinoceronte|grifone|drago|basilisco',
      );
  final parts = <Map<String, dynamic>>[];
  const numbers = {
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
    final canonicalCounts = switch (entry.id) {
      'mostro_sabbia' => {'legs': 4, 'eyes': 2, 'horns': 2},
      'gigante_sabbia' => {'arms': 2, 'legs': 2, 'eyes': 2, 'horns': 2},
      'costrutto_minore' ||
      'funghetto_cappuccio_rosso' ||
      'topino_avventuroso' => {'arms': 2, 'legs': 2, 'eyes': 2},
      'sharp' => {'legs': 4, 'eyes': 2},
      'mosca_campana' => {'legs': 6, 'wings': 4, 'eyes': 2},
      'shadow_devil' => {'horns': 2},
      'mezzo_demone_cosciente' ||
      'mezzo_demone_massiccio' => {'arms': 2, 'legs': 2, 'eyes': 2, 'horns': 2},
      'nuvola_in_bottiglia' => {'eyes': 1},
      'forest_demon' => {'legs': 4, 'eyes': 2, 'horns': 3},
      'ciclo_forest_demon_blu' => {'legs': 4, 'eyes': 2, 'horns': 2},
      _ => <String, int>{},
    };
    final group = switch (noun) {
      'braccia|braccio' => 'arms',
      'gambe|zampe' => 'legs',
      'occhi|occhio|lenti' => 'eyes',
      'ali' => 'wings',
      'corna|corno' => 'horns',
      _ => noun,
    };
    if (canonicalCounts.containsKey(group)) return canonicalCounts[group]!;
    final pattern = RegExp(
      '(\\d+|${numbers.keys.join('|')})\\s+(?:(coppie|paia)\\s+di\\s+)?(?:piccol[ei]\\s+|grand[ei]\\s+|lunghe\\s+|corte\\s+|principali\\s+|posteriori\\s+|anteriori\\s+)?(?:$noun)\\b',
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
  if (!has(r'senza occhi|nessun occhio') &&
      has(r'occhi|occhio|lenti|pupilla')) {
    group(
      'eyes',
      has(r'lenti') ? 'Lente' : 'Occhio',
      'Occhi',
      count(
        'occhi|occhio|lenti',
        has(r'occhio inciso|occhio centrale|singolo occhio|una sola lente')
            ? 1
            : 2,
      ),
      r'occhi|occhio|lente|pupilla',
    );
  }
  if (!spherical && (humanoid || has(r'\bbraccia\b|\bbraccio\b'))) {
    group(
      'arms',
      'Braccio',
      'Braccia',
      count('braccia|braccio', 2),
      r'braccia|braccio|gomito|polso|mani|mano|arto',
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
            r'\bali\b|alato|alata|arpia|uccello|rapace|angelo|grifone|drago|fata|falena|vespa',
          ) ||
          weak.contains('ala'))) {
    group(
      'wings',
      'Ala',
      'Ali',
      count('ali', entry.id.startsWith('nuvi') ? 4 : 2),
      r'ala|ali|piume',
    );
  }
  if (!spherical && has(r'\bcoda\b|\bcode\b')) {
    group('tail', 'Coda', 'Code', count('code|coda', 1), r'coda|code');
  }
  if (confirmedPhysical.contains('corna')) {
    group('horns', 'Corno', 'Corna', count('corna|corno', 2), r'corna|corno');
  }
  if (entry.id == 'topino_avventuroso' || entry.id == 'ogle') {
    group('ears', 'Orecchio', 'Orecchie', 2, r'orecchio|orecchie');
  }
  if (entry.id == 'funghetto_cappuccio_rosso') {
    add('cap', 'Cappello fungino', 'cap', false);
  }
  if (entry.id == 'il_doppione') {
    add('crest', 'Corona di lembi', 'crest', true);
    parts.firstWhere((p) => p['id'] == 'body')['weak'] = false;
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
    ('joint', 'Giuntura', r'giuntura|cerniera|giunto equatoriale'),
    ('wound', 'Ferita aperta', r'ferite aperte|ferita aperta'),
    ('sensor', 'Nodo sensoriale', r'nodo sensoriale'),
    ('sac', 'Sacca', r'sacca'),
    ('rim', 'Bordo', r'bordo|crepa'),
    ('fold', 'Piega del corpo', r'piega'),
  ];
  for (final d in details) {
    if (RegExp(d.$3).hasMatch('$physical $weak')) {
      add(d.$1, d.$2, d.$1, RegExp(d.$3).hasMatch(weak));
    }
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
