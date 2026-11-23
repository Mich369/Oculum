import 'dart:math';

/// ceil(5 * pre-Rebirth level / 10), with no floating point rounding.
int oculumRebirthKillQuota(int previousLevel) =>
    (max(0, previousLevel) + 1) ~/ 2;

/// Each other rebirthed party member contributes 15%; the acting rebirthed
/// character contributes 12% instead of the ordinary 15% self contribution.
int oculumRebirthPartyRollExperiencePercent({
  required bool rebirthed,
  required int otherRebirthedMembers,
}) => (max(0, otherRebirthedMembers) * 15) + (rebirthed ? 12 : 0);

/// Applies a percentage to a small roll-earned bar without rounding every
/// single roll up. Remainders are stored as hundredths of an EXP point.
({int gain, int remainder}) oculumRebirthPartyRollExperienceGain({
  required int baseGain,
  required int bonusPercent,
  required int previousRemainder,
}) {
  final int base = max(0, baseGain);
  final int percent = max(0, bonusPercent);
  final int remainder = max(0, previousRemainder).clamp(0, 99).toInt();
  final int total = base * percent + remainder;
  final int extra = total ~/ 100;
  return (gain: base + extra, remainder: total % 100);
}

bool oculumRebirthCriticalAvailable({
  required bool rebirthed,
  required String campaignDay,
  required Map state,
}) =>
    rebirthed &&
    campaignDay.isNotEmpty &&
    !(state['rebirthCriticalDaysUsed'] is List &&
        (state['rebirthCriticalDaysUsed'] as List).contains(campaignDay));

Map<String, dynamic> oculumConsumeRebirthCritical(
  Map state,
  String campaignDay,
) => {
  for (final entry in state.entries) '${entry.key}': entry.value,
  'rebirthCriticalDaysUsed': <String>{
    if (state['rebirthCriticalDaysUsed'] is List)
      for (final day in state['rebirthCriticalDaysUsed'] as List) '$day',
    campaignDay,
  }.toList(),
};

int _integer(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;

/// Each row carries the existing per-monster EXP calculation for this recipient.
/// The bonus never multiplies resources, training, weak monsters or NPC rewards.
({int bonus, int consumed, Map<String, dynamic> progress})
oculumRebirthMonsterExperienceBonus({
  required bool rebirthed,
  required int ownerPower,
  required Map progress,
  required Iterable<Map> monsters,
}) {
  var remaining = max(0, _integer(progress['remaining']));
  final seen = <String>{
    if (progress['claimedKills'] is List)
      for (final id in progress['claimedKills'] as List) '$id',
  };
  var bonus = 0, consumed = 0;
  if (rebirthed) {
    for (final monster in monsters) {
      final id = '${monster['id'] ?? ''}';
      if (remaining <= 0 ||
          id.isEmpty ||
          seen.contains(id) ||
          monster['isSummon'] == true ||
          monster['isNpc'] == true ||
          _integer(monster['power']) <= max(0, ownerPower)) {
        continue;
      }
      seen.add(id);
      remaining--;
      consumed++;
      // Same nearest-integer convention as the existing monster EXP pipeline.
      bonus += (max(0, _integer(monster['experience'])) * 9 + 5) ~/ 10;
    }
  }
  return (
    bonus: bonus,
    consumed: consumed,
    progress: {
      for (final entry in progress.entries) '${entry.key}': entry.value,
      'remaining': remaining,
      'claimedKills': seen.toList(),
    },
  );
}
