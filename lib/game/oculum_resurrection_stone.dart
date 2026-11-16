/// Outcomes for using a Resurrection Stone against a recorded death.
enum OculumResurrectionStoneResult {
  eligible,
  alreadyApplied,
  invalidRequest,
  unrecordedDeath,
  wrongDeath,
  closedDeath,
  outsideWindow,
  ineligibleAlly,
  missingStone,
  missingAction,
}

int oculumResurrectionWindowSeconds(String normalizedDifficulty) {
  return switch (normalizedDifficulty) {
    'oculum' => 3 * 3600,
    'difficile' => 9 * 3600,
    _ => 18 * 3600,
  };
}

int oculumResurrectionStoneHp(int maximumHp) =>
    maximumHp > 0 ? (maximumHp + 1) ~/ 2 : 0;

class OculumResurrectionWindow {
  const OculumResurrectionWindow._({
    required this.campaignId,
    required this.deathId,
    required this.startedAtSeconds,
    required this.expiresAtSeconds,
    this.closed = false,
    this.stoneUseId,
  });

  final String campaignId;
  final String deathId;
  final int startedAtSeconds;
  final int expiresAtSeconds;
  final bool closed;
  final String? stoneUseId;

  // Called only on the authority's observed transition to confirmed death.
  // An already dead record without a known time must not silently get one.
  static OculumResurrectionWindow? recordDeath({
    required OculumResurrectionWindow? current,
    required bool isNewConfirmedDeath,
    required String campaignId,
    required String deathId,
    required int worldClockSeconds,
    required String normalizedDifficulty,
  }) {
    if (!isNewConfirmedDeath ||
        campaignId.isEmpty ||
        deathId.isEmpty ||
        worldClockSeconds < 0 ||
        (current != null && (!current.closed || current.deathId == deathId))) {
      return current;
    }
    return OculumResurrectionWindow._(
      campaignId: campaignId,
      deathId: deathId,
      startedAtSeconds: worldClockSeconds,
      expiresAtSeconds:
          worldClockSeconds +
          oculumResurrectionWindowSeconds(normalizedDifficulty),
    );
  }

  static OculumResurrectionWindow? fromJson(Object? value) {
    if (value is! Map) return null;
    final campaignId = value['campaignId'];
    final deathId = value['deathId'];
    final started = value['startedAtSeconds'];
    final expires = value['expiresAtSeconds'];
    final closed = value['closed'] == true;
    final useId = value['stoneUseId'];
    if (campaignId is! String ||
        campaignId.isEmpty ||
        deathId is! String ||
        deathId.isEmpty ||
        started is! int ||
        started < 0 ||
        expires is! int ||
        expires < started ||
        (useId != null && (useId is! String || useId.isEmpty || !closed))) {
      return null;
    }
    return OculumResurrectionWindow._(
      campaignId: campaignId,
      deathId: deathId,
      startedAtSeconds: started,
      expiresAtSeconds: expires,
      closed: closed,
      stoneUseId: useId as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'campaignId': campaignId,
    'deathId': deathId,
    'startedAtSeconds': startedAtSeconds,
    'expiresAtSeconds': expiresAtSeconds,
    if (closed) 'closed': true,
    if (stoneUseId != null) 'stoneUseId': stoneUseId,
  };

  OculumResurrectionWindow close({String? useId}) => closed
      ? this
      : OculumResurrectionWindow._(
          campaignId: campaignId,
          deathId: deathId,
          startedAtSeconds: startedAtSeconds,
          expiresAtSeconds: expiresAtSeconds,
          closed: true,
          stoneUseId: useId,
        );
}

OculumResurrectionStoneResult oculumCheckResurrectionStone({
  required OculumResurrectionWindow? window,
  required String campaignId,
  required String expectedDeathId,
  required String useId,
  required int worldClockSeconds,
  required bool targetIsConfirmedDead,
  required bool alliedLivingActor,
  required int availableStoneCount,
  required bool inFight,
  required bool hasAvailableAction,
}) {
  if (useId.isEmpty) return OculumResurrectionStoneResult.invalidRequest;
  if (window == null) return OculumResurrectionStoneResult.unrecordedDeath;
  if (window.campaignId != campaignId || window.deathId != expectedDeathId) {
    return OculumResurrectionStoneResult.wrongDeath;
  }
  if (window.stoneUseId == useId) {
    return OculumResurrectionStoneResult.alreadyApplied;
  }
  if (window.closed || !targetIsConfirmedDead) {
    return OculumResurrectionStoneResult.closedDeath;
  }
  if (worldClockSeconds < window.startedAtSeconds ||
      worldClockSeconds > window.expiresAtSeconds) {
    return OculumResurrectionStoneResult.outsideWindow;
  }
  if (!alliedLivingActor) return OculumResurrectionStoneResult.ineligibleAlly;
  if (availableStoneCount <= 0) {
    return OculumResurrectionStoneResult.missingStone;
  }
  if (inFight && !hasAvailableAction) {
    return OculumResurrectionStoneResult.missingAction;
  }
  return OculumResurrectionStoneResult.eligible;
}
