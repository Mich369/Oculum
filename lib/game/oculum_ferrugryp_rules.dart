const oculumFerrugrypWinchPart = 'ferrugryp_winch';

bool oculumFerrugrypCanRecallMaglio(Map anatomyState) {
  final parts = anatomyState['parts'];
  final winch = parts is Map ? parts[oculumFerrugrypWinchPart] : null;
  if (winch is! Map) return true;
  final maximum = winch['maximumHp'];
  final damage = winch['damageTaken'];
  return !(maximum is num && maximum > 0 && damage is num && damage >= maximum);
}

/// Per-activation state for Battipalo. The Fight must settle the sweep packets,
/// open its reaction window, then settle each reaction before claiming a follow-up.
class OculumFerrugrypBattipalo {
  OculumFerrugrypBattipalo.start({
    required this.fightId,
    required this.personalTurnId,
    required Iterable<String> sweepPacketIds,
  }) : _sweepPending = Set.unmodifiable(sweepPacketIds),
       settledSweepDamage = const {},
       _reactionsPending = null,
       stoppedByCritical = false,
       followUpClaimed = false {
    if (fightId.isEmpty || personalTurnId.isEmpty || _sweepPending.isEmpty) {
      throw ArgumentError(
        'Battipalo requires a Fight, a turn and sweep packets',
      );
    }
  }

  OculumFerrugrypBattipalo._({
    required this.fightId,
    required this.personalTurnId,
    required Set<String> sweepPending,
    required this.settledSweepDamage,
    required Set<String>? reactionsPending,
    required this.stoppedByCritical,
    required this.followUpClaimed,
  }) : _sweepPending = sweepPending,
       _reactionsPending = reactionsPending;

  final String fightId;
  final String personalTurnId;
  final Set<String> _sweepPending;
  final Set<String>? _reactionsPending;
  final Map<String, int> settledSweepDamage;
  final bool stoppedByCritical;
  final bool followUpClaimed;

  OculumFerrugrypBattipalo settleSweepHit({
    required String packetId,
    required int damage,
  }) {
    if (!_sweepPending.contains(packetId) || damage < 0) return this;
    return OculumFerrugrypBattipalo._(
      fightId: fightId,
      personalTurnId: personalTurnId,
      sweepPending: {..._sweepPending}..remove(packetId),
      settledSweepDamage: Map.unmodifiable({
        ...settledSweepDamage,
        packetId: damage,
      }),
      reactionsPending: _reactionsPending,
      stoppedByCritical: stoppedByCritical,
      followUpClaimed: followUpClaimed,
    );
  }

  OculumFerrugrypBattipalo openReactionWindow(Iterable<String> reactionIds) {
    if (_sweepPending.isNotEmpty || _reactionsPending != null) return this;
    return _withReactions(Set.of(reactionIds));
  }

  OculumFerrugrypBattipalo settleReaction({
    required String reactionId,
    required bool stoppedByCritical,
  }) {
    final pending = _reactionsPending;
    if (pending == null || !pending.contains(reactionId)) return this;
    return _withReactions(
      {...pending}..remove(reactionId),
      stoppedByCritical: this.stoppedByCritical || stoppedByCritical,
    );
  }

  bool canFollowUp({required String fightId, required String personalTurnId}) =>
      fightId == this.fightId &&
      personalTurnId == this.personalTurnId &&
      _reactionsPending?.isEmpty == true &&
      !stoppedByCritical &&
      !followUpClaimed;

  OculumFerrugrypBattipalo? claimFollowUp({
    required String fightId,
    required String personalTurnId,
  }) => canFollowUp(fightId: fightId, personalTurnId: personalTurnId)
      ? _withReactions(_reactionsPending!, followUpClaimed: true)
      : null;

  OculumFerrugrypBattipalo _withReactions(
    Set<String> pending, {
    bool? stoppedByCritical,
    bool? followUpClaimed,
  }) => OculumFerrugrypBattipalo._(
    fightId: fightId,
    personalTurnId: personalTurnId,
    sweepPending: _sweepPending,
    settledSweepDamage: settledSweepDamage,
    reactionsPending: pending,
    stoppedByCritical: stoppedByCritical ?? this.stoppedByCritical,
    followUpClaimed: followUpClaimed ?? this.followUpClaimed,
  );
}
