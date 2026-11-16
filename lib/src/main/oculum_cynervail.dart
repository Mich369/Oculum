part of '../../main.dart';

const _cynervailPhaseKey = 'cynervailPhase';
const _cynervailInitialPhase = <String, dynamic>{
  'immaterial': true,
  'remaining': 3,
};

/// The Master advances this once per completed personal turn. Snapshots and
/// saved games only read the resulting phase, including the already rolled CD.
Map<String, dynamic> oculumCynervailAdvancePhase(
  Map phase, {
  required int Function() rollCooldown,
}) {
  final immaterial = phase['immaterial'] != false;
  final remaining = readIntValue(phase['remaining'], fallback: 3);
  if (remaining > 1) {
    return {'immaterial': immaterial, 'remaining': remaining - 1};
  }
  return immaterial
      ? {'immaterial': false, 'remaining': rollCooldown().clamp(1, 3)}
      : _cynervailInitialPhase;
}

extension _OculumCynervail on _OculumHomePageState {
  void resetCynervailPhaseForToken(Map<String, dynamic> token) {
    if (monsterBookIdForCombatToken(token) == oculumCynervailId) {
      token[_cynervailPhaseKey] = _cynervailInitialPhase;
    }
  }

  void finishCynervailPersonalTurn(Map<String, dynamic> token) {
    if (monsterBookIdForCombatToken(token) != oculumCynervailId) return;
    final activeFight = masterInitiativeGroups.any(
      (group) =>
          group['id'] == selectedMasterInitiativeGroupId &&
          group['fightStarted'] == true &&
          group['combatEnded'] != true,
    );
    if (!activeFight) return;
    final phase = token[_cynervailPhaseKey];
    token[_cynervailPhaseKey] = oculumCynervailAdvancePhase(
      phase is Map ? phase : _cynervailInitialPhase,
      rollCooldown: () => Random().nextInt(3) + 1,
    );
  }

  Map? currentCynervailFightPhase([Map<String, dynamic>? encounter]) {
    if (faunaCurrentMonsterId != oculumCynervailId) return null;
    final fight = encounter ?? referenceTurnEncounter();
    if (fight['fightStarted'] != true || fight['combatEnded'] == true) {
      return null;
    }
    final tag = sheetTagAt(schedaCorrente);
    final tokens = fight['tokens'] as List? ?? const [];
    for (final raw in tokens.whereType<Map>()) {
      final token = Map<String, dynamic>.from(raw);
      if (!combatTokenMatchesSheet(token, tag)) continue;
      final phase = token[_cynervailPhaseKey];
      return phase is Map ? phase : _cynervailInitialPhase;
    }
    return null;
  }

  String? cynervailFightPhaseLabel(Map<String, dynamic> encounter) {
    final phase = currentCynervailFightPhase(encounter);
    if (phase == null) return null;
    if (oculumCynervailLanternDestroyed(anatomicalPartState)) {
      return t('Materiale · Lanterna infranta', 'Material · Broken lantern');
    }
    final remaining = readIntValue(phase['remaining'], fallback: 3);
    final state = phase['immaterial'] == false
        ? t('Materiale · Recupero', 'Material · Cooldown')
        : t('Immateriale', 'Immaterial');
    return t('$state · $remaining t.', '$state · $remaining turns');
  }

  int? cynervailIncomingDamagePercent({
    required String element,
    required bool magicalAttack,
    required String attackKind,
    required String? hitBodyPart,
    bool canHitIntangible = false,
  }) {
    if (hitBodyPart == oculumCynervailLantern) return null;
    final phase = currentCynervailFightPhase();
    if (phase == null ||
        phase['immaterial'] == false ||
        oculumCynervailLanternDestroyed(anatomicalPartState)) {
      return null;
    }
    if (canHitIntangible) return 100;
    return oculumMateria35ImmaterialePercent(
      element: element,
      magicalAttack: magicalAttack,
      attackKind: attackKind,
    );
  }
}
