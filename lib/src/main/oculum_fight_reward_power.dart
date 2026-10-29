part of '../../main.dart';

/// One maximum per personal turn; extra samples and reactions never add weight.
int oculumFightRewardAverageTotalPower(Map token, {int fallback = 0}) {
  final raw = token['rewardPowerTurnMaxima'];
  if (raw is! Map || raw.isEmpty) return max(0, fallback);
  final values = raw.values
      .map((value) => max(0, readIntValue(value)))
      .toList();
  return values.fold<int>(0, (sum, value) => sum + value) ~/ values.length;
}

void oculumRecordFightRewardPowerSample(
  Map<String, dynamic> token,
  int value, {
  required String fightInstanceId,
}) {
  if (fightInstanceId.isEmpty) return;
  if ('${token['rewardPowerFightInstanceId'] ?? ''}' != fightInstanceId) {
    token['rewardPowerFightInstanceId'] = fightInstanceId;
    token['rewardPowerTurnSerial'] = 0;
    token['rewardPowerHasPersonalTurn'] = false;
    token['rewardPowerTurnReceipts'] = <String>[];
    token['rewardPowerTurnMaxima'] = <String, dynamic>{};
  }
  final serial = max(0, readIntValue(token['rewardPowerTurnSerial']));
  final maxima = Map<String, dynamic>.from(
    token['rewardPowerTurnMaxima'] as Map? ?? const {},
  );
  final key = '$serial';
  maxima[key] = max(max(0, value), readIntValue(maxima[key]));
  token['rewardPowerTurnMaxima'] = maxima;
}

void oculumBeginFightRewardPowerTurn(
  Map<String, dynamic> token,
  int value, {
  required String fightInstanceId,
  String turnReceipt = '',
}) {
  if ('${token['rewardPowerFightInstanceId'] ?? ''}' != fightInstanceId) {
    oculumRecordFightRewardPowerSample(
      token,
      value,
      fightInstanceId: fightInstanceId,
    );
  }
  final receipts = (token['rewardPowerTurnReceipts'] as List? ?? const [])
      .map((id) => '$id')
      .toSet();
  if (turnReceipt.isNotEmpty && !receipts.add(turnReceipt)) {
    oculumRecordFightRewardPowerSample(
      token,
      value,
      fightInstanceId: fightInstanceId,
    );
    return;
  }
  token['rewardPowerTurnReceipts'] = receipts.toList();
  if (readBoolValue(token['rewardPowerHasPersonalTurn'])) {
    token['rewardPowerTurnSerial'] =
        readIntValue(token['rewardPowerTurnSerial']) + 1;
  }
  token['rewardPowerHasPersonalTurn'] = true;
  oculumRecordFightRewardPowerSample(
    token,
    value,
    fightInstanceId: fightInstanceId,
  );
}

extension _OculumFightRewardPower on _OculumHomePageState {
  bool rewardPowerTokenParticipates(Map token) =>
      token['outsideFight'] != true &&
      !const {'fled', 'dead', 'expired'}.contains('${token['status'] ?? ''}');
  int? fightRewardPowerForToken(Map<String, dynamic> token) {
    final index = localSheetIndexForOculumTag(publicInitiativeSourceTag(token));
    if (index == schedaCorrente && index >= 0) {
      return currentEncounterRewardTotalPower();
    }
    if (index >= 0) {
      return oculumEncounterInstantRewardTotalPower(schedePersonaggio[index]);
    }
    final explicit =
        token['rewardTotalPowerCurrent'] ?? token['derivedRewardTotalPower'];
    if (explicit is num) return max(0, readIntValue(explicit));
    return oculumTokenDisplayTotalPower(token) ??
        (token['potenzaTotale'] is num
            ? max(0, readIntValue(token['potenzaTotale']))
            : null);
  }

  String fightRewardInstanceId(Map<String, dynamic> group, Map token) {
    for (final value in [
      token['fightInstanceId'],
      token['rewardPowerFightInstanceId'],
      group['rewardFightInstanceId'],
    ]) {
      final id = '${value ?? ''}'.trim();
      if (id.isNotEmpty) return id;
    }
    return 'legacy:${group['id']}:${readIntValue(group['completedFightCount'])}';
  }

  void recordFightRewardPowerSample(
    String tag,
    int value, {
    String? encounterId,
  }) {
    final normalized = normalizeOculumFriendTag(tag).toUpperCase();
    if (normalized.isEmpty) return;
    final groups = masterInitiativeGroups.where(
      (group) =>
          (encounterId == null || '${group['id']}' == encounterId) &&
          group['fightStarted'] != false &&
          group['combatEnded'] != true,
    );
    for (final group in groups) {
      final tokens = '${group['id']}' == selectedMasterInitiativeGroupId
          ? masterInitiativeTokens
          : group['tokens'];
      if (tokens is! List) continue;
      for (final raw in tokens) {
        if (raw is! Map<String, dynamic> ||
            !rewardPowerTokenParticipates(raw) ||
            normalizeOculumFriendTag(
                  publicInitiativeSourceTag(raw),
                ).toUpperCase() !=
                normalized) {
          continue;
        }
        oculumRecordFightRewardPowerSample(
          raw,
          value,
          fightInstanceId: fightRewardInstanceId(group, raw),
        );
      }
    }
  }

  void sampleFightRewardPowerToken(Map<String, dynamic> token) {
    if (!rewardPowerTokenParticipates(token)) return;
    final group = masterInitiativeGroups
        .where((group) => '${group['id']}' == selectedMasterInitiativeGroupId)
        .firstOrNull;
    if (group == null ||
        group['fightStarted'] == false ||
        group['combatEnded'] == true) {
      return;
    }
    final power = fightRewardPowerForToken(token);
    if (power == null) return;
    oculumRecordFightRewardPowerSample(
      token,
      power,
      fightInstanceId: fightRewardInstanceId(group, token),
    );
  }

  void beginFightRewardPowerTurn(Map<String, dynamic> token) {
    if (!rewardPowerTokenParticipates(token) ||
        token['temporaryTurn'] == true ||
        token['duplicateAction'] == true) {
      return;
    }
    final group = masterInitiativeGroups
        .where((group) => '${group['id']}' == selectedMasterInitiativeGroupId)
        .firstOrNull;
    if (group == null ||
        group['fightStarted'] == false ||
        group['combatEnded'] == true) {
      return;
    }
    final power = fightRewardPowerForToken(token);
    if (power == null) return;
    oculumBeginFightRewardPowerTurn(
      token,
      power,
      fightInstanceId: fightRewardInstanceId(group, token),
      turnReceipt:
          '$masterInitiativeRound:${publicInitiativeSourceTag(token).toUpperCase()}',
    );
  }
}
