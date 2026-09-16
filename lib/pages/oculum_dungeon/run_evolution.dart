import 'dart:math';

class DungeonEvolution {
  const DungeonEvolution(
    this.id,
    this.nameIt,
    this.nameEn,
    this.family,
    this.descriptionIt,
    this.descriptionEn,
  );
  final String id, nameIt, nameEn, family, descriptionIt, descriptionEn;
}

const dungeonEvolutions = <DungeonEvolution>[
  DungeonEvolution(
    'fury',
    'Muscoli di vetro',
    'Glass muscles',
    'assalto',
    '+6 Danno, −2 Difesa per grado.',
    '+6 Damage, −2 Defense per rank.',
  ),
  DungeonEvolution(
    'duelist',
    'Nervi del duellante',
    'Duelist nerves',
    'assalto',
    '+4 VC, −2 CM per grado.',
    '+4 VC, −2 CM per rank.',
  ),
  DungeonEvolution(
    'last_spark',
    'Ultima scintilla',
    'Last spark',
    'assalto',
    '+10 Danno per grado mentre hai il 35% della Vita o meno.',
    '+10 Damage per rank while at 35% HP or below.',
  ),
  DungeonEvolution(
    'stone',
    'Ossa di basalto',
    'Basalt bones',
    'baluardo',
    '+5 Difesa, −2 Danno per grado.',
    '+5 Defense, −2 Damage per rank.',
  ),
  DungeonEvolution(
    'aegis',
    'Pelle prismatica',
    'Prismatic skin',
    'baluardo',
    '+6 Scudo per grado quando entri in una nuova stanza.',
    '+6 Shield per rank on entering a new room.',
  ),
  DungeonEvolution(
    'vital',
    'Cuore doppio',
    'Twin heart',
    'baluardo',
    '+20 Vita massima e attuale, −1 Danno per grado.',
    '+20 maximum and current HP, −1 Damage per rank.',
  ),
  DungeonEvolution(
    'oracle',
    'Terzo sguardo',
    'Third sight',
    'occulto',
    '+4 CM, −2 VC per grado.',
    '+4 CM, −2 VC per rank.',
  ),
  DungeonEvolution(
    'ember',
    'Sangue di brace',
    'Ember blood',
    'occulto',
    'Attacco base VC/CM: Bruciatura per 2 turni, potenza +2 per grado.',
    'Basic VC/CM attack: Burn for 2 turns, +2 potency per rank.',
  ),
  DungeonEvolution(
    'razor',
    'Dita uncinate',
    'Hooked fingers',
    'occulto',
    'Attacco base VC/CM: Sanguinamento per 2 turni, potenza +2 per grado.',
    'Basic VC/CM attack: Bleed for 2 turns, +2 potency per rank.',
  ),
  DungeonEvolution(
    'hunger',
    'Fame del superstite',
    'Survivor hunger',
    'sopravvivenza',
    'Vittoria normale: recuperi 6 Vita per grado.',
    'Normal victory: recover 6 HP per rank.',
  ),
  DungeonEvolution(
    'pilgrim',
    'Passo del pellegrino',
    'Pilgrim stride',
    'sopravvivenza',
    'Entrare in una nuova stanza cura 3 Vita per grado.',
    'Entering a new room heals 3 HP per rank.',
  ),
  DungeonEvolution(
    'collector',
    'Occhio avido',
    'Greedy eye',
    'sopravvivenza',
    'Vittoria normale: +8 Obser; −1 Danno per grado.',
    'Normal victory: +8 Obser; −1 Damage per rank.',
  ),
];

/// Pending offers and consumed milestones persist together: reloads cannot
/// reroll a reward or apply the same milestone twice.
class DungeonEvolutionProgress {
  DungeonEvolutionProgress();
  int completed = 0;
  int pendingMilestone = 0;
  final List<String> history = [];
  final List<String> offers = [];
  int rank(String id) => history.where((item) => item == id).length;
  int familyRank(String family) => dungeonEvolutions
      .where((item) => item.family == family)
      .fold(0, (sum, item) => sum + rank(item.id));
  bool synergy(String family) => familyRank(family) >= 3;
  bool due(int room) => room ~/ 3 > completed;
  int roomsUntilChoice(int room) => due(room) ? 0 : (completed + 1) * 3 - room;
  void prepare(int room, Random random) {
    if (!due(room) || offers.isNotEmpty) return;
    pendingMilestone = completed + 1;
    final pool = dungeonEvolutions.where((item) => rank(item.id) < 3).toList()
      ..shuffle(random);
    final families = <String>{};
    for (final item in pool) {
      if (families.add(item.family)) offers.add(item.id);
      if (offers.length == 3) break;
    }
    for (final item in pool) {
      if (offers.length == 3) break;
      if (!offers.contains(item.id)) offers.add(item.id);
    }
  }

  bool choose(String id) {
    if (!offers.contains(id) ||
        pendingMilestone != completed + 1 ||
        rank(id) >= 3) {
      return false;
    }
    history.add(id);
    completed = pendingMilestone;
    pendingMilestone = 0;
    offers.clear();
    return true;
  }

  Map<String, dynamic> toJson() => {
    'completed': completed,
    'pendingMilestone': pendingMilestone,
    'history': List<String>.of(history),
    'offers': List<String>.of(offers),
  };
  factory DungeonEvolutionProgress.fromJson(dynamic raw, {int legacyRoom = 0}) {
    final result = DungeonEvolutionProgress();
    if (raw is! Map) {
      result.completed = max(0, legacyRoom ~/ 3);
      return result;
    }
    final ids = dungeonEvolutions.map((item) => item.id).toSet();
    for (final item in (raw['history'] as List? ?? const [])) {
      if (item is String && ids.contains(item) && result.rank(item) < 3) {
        result.history.add(item);
      }
    }
    result.completed = max(
      result.history.length,
      (raw['completed'] as num?)?.toInt() ?? 0,
    );
    final pending = (raw['pendingMilestone'] as num?)?.toInt() ?? 0;
    if (pending == result.completed + 1) {
      result.pendingMilestone = pending;
      result.offers.addAll(
        (raw['offers'] as List? ?? const [])
            .whereType<String>()
            .where((id) => ids.contains(id) && result.rank(id) < 3)
            .toSet()
            .take(3),
      );
    }
    return result;
  }
}
