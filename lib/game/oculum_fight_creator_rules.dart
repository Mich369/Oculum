import 'dart:math';

/// One independent creation roll; loading or joining a Fight never rerolls it.
({int hp, int percent}) oculumFightCreatorInitialHealth(
  int maximumHp, {
  required Random random,
}) {
  final maximum = max(0, maximumHp);
  if (maximum == 0) return (hp: 0, percent: 100);
  final percent = random.nextInt(100) < 20 ? 25 + random.nextInt(51) : 100;
  return (hp: max(1, (maximum * percent + 99) ~/ 100), percent: percent);
}

/// Connected roles are authoritative; Co-Master is not the Master-only view.
bool oculumFightCreatorMasterAccess({
  required bool connected,
  required bool masterRole,
  required bool coMasterRole,
  required bool localMasterMode,
  required bool localMasterHost,
}) => connected
    ? masterRole
    : masterRole || !coMasterRole && (localMasterMode || localMasterHost);

/// Each instance contributes exactly once. Copies need their own stable ID.
({int total, int count, Map<String, int> teams}) oculumFightCreatorPowerSummary(
  Iterable<({String id, String teamId, int power})> participants,
) {
  final seen = <String>{}, teams = <String, int>{};
  var total = 0;
  for (final participant in participants) {
    if (participant.id.trim().isEmpty ||
        participant.teamId.trim().isEmpty ||
        !seen.add(participant.id)) {
      throw ArgumentError(
        'Each fight participant needs a unique stable ID and a team',
      );
    }
    final power = max(0, participant.power);
    teams.update(
      participant.teamId,
      (value) => value + power,
      ifAbsent: () => power,
    );
    total += power;
  }
  return (total: total, count: seen.length, teams: Map.unmodifiable(teams));
}

int oculumFightCreatorRemainingEnemyPower({
  required int allyPower,
  required int enemyPower,
  required int targetPercent,
}) => max(
  0,
  (max(0, allyPower) * max(0, targetPercent) / 100).round() -
      max(0, enemyPower),
);
