part of 'monster_book.dart';

final _packLeaderMonsterBookEntries = [
  for (final (baseId, name, description) in const [
    (
      'papera_ranocchio',
      'Papera Ranocchio Colossale',
      'Un enorme anfibio dalla testa di papera, che raduna il branco con colpi di gola e protegge le pozze di cova.',
    ),
    (
      'goblin_base',
      'Goblin Caposcavo',
      'Un goblin segnato da incisioni di comando; dirige le fughe del gruppo e difende le provviste.',
    ),
    (
      'arpia_base',
      'Matriarca delle Arpie',
      'Una grande arpia dalle piume consumate; riconosce i propri piccoli e coordina la difesa del nido.',
    ),
    (
      'inspired_ranocchio_fango',
      'Patriarca del Fango Verde',
      'Un ranocchio enorme con un cerchio di escrescenze sulla gola, capace di richiamare e guidare la colonia.',
    ),
    (
      'weak_horror_mastino',
      'Mastino Capocripta',
      'Un mastino possente, con cicatrici sulle costole; riconosce i compagni e tiene insieme il branco nei cunicoli.',
    ),
    (
      'weak_horror_affamato',
      'Affamato Capofossa',
      'Un affamato più grande degli altri, che divide gli scarti con il gruppo e custodisce il rifugio.',
    ),
  ])
    for (final base in [
      ..._craftedMonsterBookEntries,
      ..._manualMonsterBookEntries,
      ..._inspiredMonsterBookEntries,
      ..._weakHorrorMonsterBookEntries,
    ].where((entry) => entry.id == baseId))
      base.copyWith(
        id: 'pack_leader_$baseId',
        nameIt: name,
        nameEn: name,
        isMiniBoss: true,
        isBoss: false,
        classificationTags: [...base.formTags, 'Capobranco'],
        stats: {
          'level': 0,
          for (final stat in ['resilienza', 'volonta', 'materia', 'oculum'])
            stat: max(1, (base.stats[stat] ?? 0) * 3 + 2),
        },
        descIt:
            '$description Mini Boss, livello 0, grado 0. Conserva tutte le skill della creatura base. Una sola volta, quando la Vita è maggiore di zero e scende al 50% o meno, attiva Ricordo vitale (cura 75% della Vita massima entro il massimo, condizione per 9 turni personali), 200% (statistiche raddoppiate per 3 turni personali) e guadagna Scudo pari al 10% della Vita massima precedente alla fase, arrotondato per eccesso. Il Riposo Lungo ricarica la fase. Questa peculiarità resta attiva anche come Occhio dei Caduti. Nessun comando mentale sui giocatori.',
        descEn: description,
      ),
];
