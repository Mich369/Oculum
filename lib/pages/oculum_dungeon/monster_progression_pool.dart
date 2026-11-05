part of 'monster_book.dart';

// Registered while building the catalogue, before its narration is generated.
// This avoids looking up the partially initialised default catalogue.
final Map<String, MonsterBookEntry> _progressionOwners = {};
const oculumMonsterProgressionPrefix = 'growth__';

String oculumMonsterNaturalAttitude(MonsterBookEntry entry) {
  final saved = '${entry.encounterRules['naturalAttitude'] ?? ''}'.trim();
  if (saved.isNotEmpty) return saved;
  final id = entry.id.replaceFirst(RegExp(r'_variante_.*$'), '');
  if (id == 'scostubanditi') {
    return 'Sfrontato, opportunista e legato alla propria banda. Preferisce intimidire, rubare e mettere in difficoltà gli avversari; non cerca di uccidere.';
  }
  if (id.contains('scostubandito') && id.contains('errato')) {
    return 'Prudente e disciplinato. Combina spada e magia spirituale, protegge la propria posizione e resta in silenzio durante il combattimento.';
  }
  if (id == 'shadow_devil') {
    return 'Tormentato dall’Oblio dello Shadow Hell, reagisce come un diavolo contaminato. Alla morte lascia percepire gratitudine per la liberazione.';
  }
  if (id == 'strana_presenza') {
    return 'Osserva danzando nell’ombra, logora chi la percepisce e respinge chi si avvicina. La Follia permette di accorgersi della sua presenza.';
  }
  if (id.contains('lunare') && !id.contains('demoniac')) {
    return 'Vigile e metodico, mantiene l’ordine contro i Solari. Protegge i propri cristalli e sfrutta l’occhio posteriore per sorvegliare l’ambiente.';
  }
  final prose = entry.descIt
      .split(RegExp(r'Ruolo in scena:|Skill per il giocatore:'))
      .first;
  final sentences = prose.split(RegExp(r'(?<=[.!?])\s+'));
  final relevant = sentences
      .where(
        (s) => RegExp(
          r'aggressiv|obbed|ordini|osserva|difende|protegge|caccia|insegue|preferisce|evita|attacca|si nasconde|pacific|curios|territori|solitari|gruppo|banda|timid|fugge',
          caseSensitive: false,
        ).hasMatch(s),
      )
      .take(3)
      .join(' ');
  return relevant.isNotEmpty
      ? relevant
      : 'Le sue reazioni dipendono dall’ambiente, dalle minacce e dai legami che ha sviluppato. ${prose.split('\n').first}';
}

List<MonsterBookEntry> _withMonsterProgressionPools(
  Iterable<MonsterBookEntry> entries,
) => [for (final entry in entries) _withMonsterProgressionPool(entry)];

bool oculumMonsterHasFixedProgressionSkills(MonsterBookEntry entry) =>
    const {
      'nuvi',
      'thunder_bot',
      'collezionista_di_elementi',
      'demonietto_bruciante',
      'demonietto_del_gelo',
      'coboldo_di_brina',
    }.contains(entry.id.split('_variante_').first) ||
    (entry.formTags.contains('Creatura Minore') && entry.skillIds.isEmpty);

MonsterBookEntry _withMonsterProgressionPool(MonsterBookEntry entry) {
  final ids = List.generate(
    12,
    (i) => '$oculumMonsterProgressionPrefix${entry.id}__$i',
  );
  for (final id in ids) {
    _progressionOwners[id] = entry;
  }
  // Keep legacy IDs resolvable, but do not add moves to a single-skill species.
  if (oculumMonsterHasFixedProgressionSkills(entry)) {
    return entry;
  }
  return entry.copyWith(
    skillIds: [
      ...entry.skillIds,
      ...ids.where((id) => !entry.skillIds.contains(id)),
    ],
    encounterRules: {
      ...entry.encounterRules,
      'naturalAttitude': oculumMonsterNaturalAttitude(entry),
      'additionalProgressionSkills': ids,
    },
  );
}

MonsterBookEntry oculumRegisterProgressionPool(MonsterBookEntry entry) =>
    _withMonsterProgressionPool(entry);

typedef _MonsterProgressionMotion = ({
  String attack,
  String guard,
  String motion,
  String strikeText,
  String guardText,
  String motionText,
});

final _progressionMotions = Expando<_MonsterProgressionMotion>();

/// Uses body parts from the catalogue anatomy. Unknown bodies use timing and
/// positioning without assuming equipment or additional organs.
_MonsterProgressionMotion _monsterProgressionMotion(MonsterBookEntry owner) {
  final groups = oculumMonsterPrecisionAnatomy(
    owner,
  ).map((part) => part['group']).toSet();
  final physical = oculumMonsterPhysicalDescription(owner);
  if (groups.contains('wings')) {
    return (
      attack: 'Sferzata alare',
      guard: 'Profilo alare',
      motion: 'Virata corta',
      strikeText: 'Ruota e porta l’ala sulla traiettoria del colpo.',
      guardText: 'Riduce il profilo tenendo le ali vicine al corpo.',
      motionText: 'Cambia direzione con un battito breve.',
    );
  }
  if (groups.contains('arms')) {
    return (
      attack: 'Colpo di braccio',
      guard: 'Guardia raccolta',
      motion: 'Rotazione di guardia',
      strikeText: 'Muove un braccio lungo una traiettoria corta.',
      guardText: 'Porta le braccia davanti alle zone più esposte.',
      motionText: 'Ruota il corpo mantenendo la guardia.',
    );
  }
  if (groups.contains('tail')) {
    return (
      attack: 'Colpo di coda',
      guard: 'Fianco protetto',
      motion: 'Scarto di coda',
      strikeText: 'Porta la coda sulla traiettoria del colpo.',
      guardText: 'Riduce il profilo e protegge il fianco esposto.',
      motionText: 'Usa la coda per bilanciare uno scarto.',
    );
  }
  if (groups.contains('legs')) {
    return (
      attack: 'Impeto in appoggio',
      guard: 'Posizione salda',
      motion: 'Passo obliquo',
      strikeText:
          'Sfrutta l’appoggio a terra per dare slancio al prossimo colpo.',
      guardText: 'Abbassa il baricentro e mantiene gli appoggi.',
      motionText: 'Cambia appoggio per spostarsi in diagonale.',
    );
  }
  if (RegExp(r'\b(?:serpente|serpentiforme)\b').hasMatch(physical)) {
    return (
      attack: 'Slancio della spira',
      guard: 'Spira serrata',
      motion: 'Scivolata sinuosa',
      strikeText: 'Distende una spira per dare slancio al prossimo attacco.',
      guardText: 'Raccoglie le spire e riduce la superficie esposta.',
      motionText: 'Scivola fuori dalla traiettoria con un movimento sinuoso.',
    );
  }
  return (
    attack: 'Attacco in tempo',
    guard: 'Difesa compatta',
    motion: 'Cambio di posizione',
    strikeText: 'Concentra la propria forza nel momento del prossimo attacco.',
    guardText: 'Riduce il profilo esposto e mantiene la propria difesa.',
    motionText: 'Si sposta appena fuori dalla traiettoria più esposta.',
  );
}

/// Twelve extra, species-owned techniques. Existing authored moves are retained.
/// Anatomy supplies the movement language; element and payment follow the owner.
MonsterConcreteTechnique? _monsterProgressionTechnique(String id) {
  final owner = _progressionOwners[id];
  if (owner == null) return null;
  final slot = int.tryParse(id.split('__').last);
  if (slot == null || slot < 0 || slot >= 12) return null;
  final anatomy = _progressionMotions[owner] ??= _monsterProgressionMotion(
    owner,
  );
  final resource = (owner.stats['oculum'] ?? 0) > 0
      ? 'oculum'
      : (owner.stats['materia'] ?? 0) > 0
      ? 'materia'
      : (owner.stats['volonta'] ?? 0) > 0
      ? 'volonta'
      : 'resilienza';
  final labels = [
    '${anatomy.attack} · precisione',
    '${anatomy.attack} · pressione',
    '${anatomy.attack} · impeto',
    '${anatomy.guard} · tenuta',
    '${anatomy.guard} · riposizionamento',
    '${anatomy.guard} · rinforzo',
    '${anatomy.motion} · controllo',
    'Ricognizione di ${owner.nameIt}',
    'Presenza di ${owner.nameIt}',
    'Open · ${anatomy.attack}',
    'Open · ${anatomy.guard}',
    'Open · ${anatomy.motion}',
  ];
  final actions = [
    '${anatomy.strikeText} Concentra l’impatto in un unico attacco.',
    '${anatomy.strikeText} Mantiene pressione con una traiettoria corta.',
    '${anatomy.strikeText} Impegna più energia in un colpo risolutivo.',
    '${anatomy.guardText} Rafforza la protezione contro il prossimo confronto.',
    '${anatomy.motionText} Mantiene la guardia durante lo spostamento.',
    '${anatomy.guardText} Accumula una riserva protettiva.',
    '${anatomy.motionText} Mantiene un movimento controllato.',
    'Studia il territorio con i sensi della propria specie.',
    'Coordina il proprio ritmo e la propria presenza.',
    '${anatomy.strikeText} Richiede un’Open attiva.',
    '${anatomy.guardText} Richiede un’Open attiva.',
    '${anatomy.motionText} Richiede un’Open attiva.',
  ];
  final kind = switch (slot) {
    0 || 1 || 2 || 9 => 'colpo',
    3 || 5 || 10 => 'scudo',
    4 || 6 || 11 => 'movimento',
    _ => 'richiamo',
  };
  return MonsterConcreteTechnique(
    name: '${labels[slot]} · ${owner.nameIt}',
    action: actions[slot],
    element: owner.elementId,
    kind: kind,
    requiredLevel: slot >= 9 ? 15 : (slot % 3) * 2,
    costResource: resource,
    minimums: slot >= 9 ? const [3, 6, 10] : const [1, 2, 3],
    maximums: slot >= 9 ? const [3, 6, 10] : const [1, 2, 3],
    cooldownValues: slot >= 9 ? const [4, 5, 6] : const [2, 3, 4],
    forms: List.generate(3, (form) {
      final rank = form + 1;
      return switch (slot) {
        0 || 1 || 2 || 9 => [
          MonsterTechniqueEffect(
            'danno',
            '${rank * (slot == 9 ? 9 : slot + 3)}',
            mode: 'prossima_azione',
            duration: '',
          ),
        ],
        3 => [
          MonsterTechniqueEffect(
            'difesa',
            '${rank * 4}',
            mode: 'prossima_azione',
            duration: '',
          ),
        ],
        4 => [
          MonsterTechniqueEffect(
            'modifica_statistica',
            '$rank',
            target: 'CM',
            duration: '1',
          ),
        ],
        5 || 10 => [
          MonsterTechniqueEffect(
            'scudo',
            '${rank * (slot == 10 ? 15 : 6)}',
            mode: 'immediato',
            duration: '',
          ),
        ],
        6 => [MonsterTechniqueEffect('velocita', '${rank * 2}', duration: '1')],
        7 => [
          MonsterTechniqueEffect(
            'modifica_sottotratto',
            '${rank * 2}',
            target: 'percezione',
            duration: '1',
          ),
        ],
        8 => [
          MonsterTechniqueEffect(
            'modifica_sottotratto',
            '${rank * 2}',
            target: 'concentrazione',
            duration: '1',
          ),
        ],
        _ => [
          MonsterTechniqueEffect(
            'aggiungi_reazioni_rapide',
            '1',
            duration: '1',
          ),
        ],
      };
    }),
  );
}
