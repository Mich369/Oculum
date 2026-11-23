/// An active reading is scoped to a specific fight, team and personal turn.
/// The game must supply authoritative team membership and line of sight.
class OculumSensimossReading {
  const OculumSensimossReading({
    required this.fightId,
    required this.teamId,
    required this.personalTurnId,
  });

  final String fightId;
  final String teamId;
  final String personalTurnId;

  /// Resolve current Power afresh for each eligible reader and visible target.
  /// Authorization precedes reading the private value.
  int? readCurrentPower({
    required String activeFightId,
    required String activePersonalTurnId,
    required String sensimossTeamId,
    required String viewerTeamId,
    required String targetTeamId,
    required bool hasLineOfSight,
    required int? Function() currentPower,
  }) {
    if (fightId.isEmpty ||
        fightId != activeFightId ||
        personalTurnId.isEmpty ||
        personalTurnId != activePersonalTurnId ||
        teamId.isEmpty ||
        teamId != sensimossTeamId ||
        teamId != viewerTeamId ||
        targetTeamId.isEmpty ||
        targetTeamId == teamId ||
        !hasLineOfSight) {
      return null;
    }
    return currentPower();
  }
}
