import 'dart:math';

const oculumSolarObserverId = 'solgaze';
const oculumBitingWandererId = 'sanguifang';
const oculumSolarGoldCondition = 'trasformato_in_oro';
const oculumBiterBiteEffect = 'sanguifang_morso';
const oculumSolarGoldTurns = 3;

int oculumSolarGoldReleaseDifficulty(int level, int grade) =>
    10 + max<int>(0, level) + 2 * max<int>(0, grade);

int oculumSanguifangHealing(int totalDamage, {int percent = 15}) =>
    max(0, totalDamage) * percent.clamp(0, 100) ~/ 100;

/// The target sheet owns this ledger. Keep each source independent and count
/// resolved packets once within the Fight, including across reloads.
bool oculumRecordSolarObserverHit(
  Map<String, dynamic> state, {
  required String fightKey,
  required String sourceTag,
  required String packetId,
  required bool hit,
  required bool doubleCritical,
}) {
  if (!hit || fightKey.isEmpty || sourceTag.isEmpty || packetId.isEmpty) {
    return false;
  }
  if (state['fight'] != fightKey) {
    state
      ..clear()
      ..['fight'] = fightKey;
  }
  final previousPackets = state['receipts'];
  final packets = previousPackets is List
      ? previousPackets.whereType<String>().toSet()
      : <String>{};
  if (!packets.add(packetId)) return false;
  final previousHits = state['hits'];
  final hits = previousHits is Map
      ? Map<String, dynamic>.from(previousHits)
      : <String, dynamic>{};
  final count = max(0, int.tryParse('${hits[sourceTag]}') ?? 0) + 1;
  hits[sourceTag] = count;
  state
    ..['receipts'] = packets.toList()
    ..['hits'] = hits;
  return count == 3 || doubleCritical;
}
