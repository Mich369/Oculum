part of '../../main.dart';

bool isBalenaRayEffect(Object? id) =>
    '$id'.startsWith('${oculumBalenaRaySkillId}_');

String oculumBalenaFightDifficulty(Iterable<String?> opposingDifficulties) {
  var lowest = 4;
  for (final difficulty in opposingDifficulties) {
    lowest = min(lowest, oculumDifficultyRank(difficulty ?? 'normale'));
  }
  return const ['facile', 'normale', 'difficile'][max(
    0,
    lowest - 1,
  ).clamp(0, 2)];
}

String? _oculumFightProfile(Map<String, dynamic> participant) {
  final value = participant['campaignDifficulty'];
  return value is String && value.trim().isNotEmpty
      ? normalizeTemporaryOculumDifficulty(value)
      : null;
}

String oculumBalenaRosterDifficulty(
  Iterable<Map<String, dynamic>> tokens,
  String sourceTeam, {
  String? Function(Map<String, dynamic>) profile = _oculumFightProfile,
}) => oculumBalenaFightDifficulty(
  tokens
      .where((token) {
        final team = combatParticipantTeamId(token);
        return sourceTeam != 'neutral' &&
            team != 'neutral' &&
            team != sourceTeam &&
            token['outsideFight'] != true &&
            !const {'dead', 'fled', 'expired'}.contains(token['status']);
      })
      .map(profile),
);

int oculumBalenaChargeDamage(int baseDamage, int chargedTurns) =>
    baseDamage +
    oculumBalenaRayDamagePerTurn *
        chargedTurns.clamp(0, oculumBalenaRayMaximumTurns);

extension _OculumBalena on _OculumHomePageState {
  Map<String, dynamic>? get balenaRayPreparation => activeStructuredEffects
      .where(
        (effect) =>
            effect['mode'] == 'prossima_azione' &&
            isBalenaRayEffect(effect['effectId']),
      )
      .lastOrNull;

  bool get balenaRayFocused =>
      schedePersonaggio[schedaCorrente]['combatConcentrationPending'] == true;

  int get balenaRayConcentrationTurns {
    final focusTurn = balenaRayPreparation?['balenaFocusTurn'];
    return balenaRayFocused && focusTurn != null
        ? max(0, playerReportedTurn - readIntValue(focusTurn))
        : 0;
  }

  bool balenaRayTargetInRange(String sourceTag, Map<String, dynamic> target) {
    final distance = _oculiathMapDistance(sourceTag, target);
    if (distance == null) return true;
    return oculumOculiathWithinRange(
      dxMeters: distance.dx,
      dyMeters: distance.dy,
      dzMeters: distance.dz,
      range: balenaRayFocused
          ? oculumBalenaRayFocusedRange
          : oculumBalenaRayBaseRange,
    );
  }

  String? fightProfileForToken(Map<String, dynamic> token) {
    final index = masterInitiativeSheetIndexForToken(token);
    return _oculumFightProfile(index < 0 ? token : schedePersonaggio[index]);
  }

  String balenaOutgoingDifficulty(String sourceMonsterId) {
    if (sourceMonsterId != oculumBalenaMilleOcchiId) {
      return normalizedCampaignDifficulty();
    }
    final tokens = onlineCombatTokens();
    final sourceTag = sheetTagAt(schedaCorrente);
    final source = tokens
        .where((token) => combatTokenMatchesSheet(token, sourceTag))
        .firstOrNull;
    return oculumBalenaRosterDifficulty(
      tokens,
      source == null ? 'neutral' : combatParticipantTeamId(source),
      profile: referenceUsesLocalTurnState
          ? fightProfileForToken
          : _oculumFightProfile,
    );
  }
}
