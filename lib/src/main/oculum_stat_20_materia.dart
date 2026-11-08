part of '../../main.dart';

const _materia20QuickAction = 'matter_quick_action';
const _materia20FreeDodge = 'matter_free_dodge';
final _materia20QuickRunning = Expando<bool>();

bool oculumMateria20CanDodgeAttack(Map<String, dynamic> request) {
  if (oculumCombatRequestIsObservation(request) ||
      const {
        'help',
        'corruption',
        'corruption_target',
        'corruption_command',
        'guardian_secondary',
        'guardian_secondary_waiting',
        'fauna_revive',
      }.contains(request['kind']) ||
      request['guardianSecondaryEvent'] == true ||
      request['referenceMadnessWave'] == true ||
      request['firstDefense'] != null ||
      request['counterAttackResponse'] != null ||
      request['counterAttackDamageOf'] != null ||
      readIntValue(request['cycleLunarStomp']) > 0 ||
      oculumIsFreeProtectiveImpact(request)) {
    return false;
  }
  final effects = request['effects'];
  return effects is! List ||
      !effects.whereType<Map>().any(
        (effect) =>
            effect['type'] == 'planar' && effect['target'] == 'lusier_derision',
      );
}

extension _OculumMateria20 on _OculumHomePageState {
  bool get canActivateMateria20QuickAction =>
      mounted &&
      _materia35OwnActiveFight &&
      stat20Choice('materia') == _materia20QuickAction &&
      stat35Cooldown(_materia20QuickAction) == 0 &&
      !totalPowerExhausted &&
      executingCorruptionCommand == null &&
      _materia20QuickRunning[this] != true;

  Future<void> activateMateria20QuickAction() async {
    if (!canActivateMateria20QuickAction) return;
    final sheet = currentSheetScrollId();
    final fight = _materia35Fight;
    _materia20QuickRunning[this] = true;
    try {
      if (!await requestUtilitySpend(
            'speed_grant_fast',
            preferFreeReaction: false,
            grantFastRollBonus: false,
          ) ||
          !mounted ||
          currentSheetScrollId() != sheet ||
          _materia35Fight != fight) {
        return;
      }
      setStat35Cooldown(
        _materia20QuickAction,
        max(1, stat35Value(_materia20QuickAction, 'cooldown', fallback: 4)),
      );
      aggiungiLog('[AZIONE RAPIDA] Una Reazione veloce extra.');
      programmaSalvataggio();
      unawaited(flushPendingCombatTurnResources());
    } finally {
      _materia20QuickRunning[this] = false;
    }
  }

  bool canUseMateria20FreeDodge(Map<String, dynamic> request) {
    final id = '${request['id'] ?? ''}';
    return mounted &&
        _materia35OwnActiveFight &&
        !parasiteOwnerLocked &&
        !stat20OculumChargeActive &&
        pawnPendingDamage.isEmpty &&
        stat20Choice('materia') == _materia20FreeDodge &&
        stat35RestReady(_materia20FreeDodge) &&
        id.isNotEmpty &&
        identical(onlineCombatRequests[id], request) &&
        request['status'] == 'pending' &&
        request['targetTag'] == sheetTagAt(schedaCorrente) &&
        request['scope'] == permissionScope &&
        request['encounterId'] == onlineCombatEncounterId &&
        oculumMateria20CanDodgeAttack(request);
  }

  Future<void> useMateria20FreeDodge(Map<String, dynamic> request) async {
    if (!canUseMateria20FreeDodge(request)) return;
    final id = '${request['id']}';
    if (!onlineCombatResolving.add(id)) return;
    try {
      if (bottledCloudAttackInterrupted(request)) return;
      if (cycleCloudBlocksDefense(request)) {
        await applyResolvedOnlineDefense(request, 'nube_rigida', -1000000);
        return;
      }
      await applyResolvedOnlineDefense(request, _materia20FreeDodge, 0);
    } finally {
      onlineCombatResolving.remove(id);
    }
  }

  bool claimMateria20FreeDodge(Map<String, dynamic> request) {
    if (!canUseMateria20FreeDodge(request)) return false;
    final rests = stat35Value(_materia20FreeDodge, 'shortRests', fallback: 2);
    _setStat35Value('restLocks', _materia20FreeDodge, max(1, rests));
    programmaSalvataggio();
    return true;
  }

  void recoverMateria20FreeDodge({required bool longRest}) {
    final rests = readIntValue(
      _stat35Section('restLocks')[_materia20FreeDodge],
    );
    if (rests <= 0) return;
    _setStat35Value(
      'restLocks',
      _materia20FreeDodge,
      longRest || rests == 1 ? null : rests - 1,
    );
  }
}
