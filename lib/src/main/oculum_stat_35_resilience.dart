part of '../../main.dart';

const _stat35ResRegen = 'res_regen';
const _stat35ResImmunity = 'res_immunity';
const _stat35ResGroupHeal = 'res_group_heal';
const _stat35ResGroupHealMode = 'stat35_res_group_heal';
final _stat35ResActionBusy = Expando<bool>();

extension _OculumStat35Resilience on _OculumHomePageState {
  String _stat35ResFight({String? tag}) =>
      combatSubtraitExperienceFightId(onlineCombatEncounterId, ownerTag: tag);

  int _stat35ResPercent(String option, String key, int fallback) =>
      stat35Value(option, key, fallback: fallback).clamp(0, 100).toInt();

  void recordStat35ResHpHit({required int hpLost, String? packetId}) {
    final hp = hpCorrenti();
    final tag = sheetTagAt(schedaCorrente);
    if (hpLost <= 0 ||
        hp <= 0 ||
        outsideFight ||
        !currentCombatIsActive() ||
        !hasStat35Choice('resilienza', _stat35ResRegen) ||
        realtimeService?.isConnected == true &&
            !controlsOnlineCombatSheet(tag)) {
      return;
    }
    final fight = _stat35ResFight();
    if (packetId != null &&
        packetId.isNotEmpty &&
        !faunaReceipt('stat35-res-regen:$fight:$packetId')) {
      return;
    }
    final saved = planarState['stat35ResRegen'];
    final ledger = saved is Map && saved['fight'] == fight
        ? Map<String, dynamic>.from(saved)
        : <String, dynamic>{'fight': fight};
    final hitsRequired = max(
      1,
      stat35Value(_stat35ResRegen, 'hitsRequired', fallback: 3),
    );
    final hits = max(0, readIntValue(ledger['hits'])) + 1;
    ledger['hits'] = hits >= hitsRequired ? 0 : hits;
    final threshold = _stat35ResPercent(
      _stat35ResRegen,
      'thresholdPercent',
      20,
    );
    if (ledger['vitalMemoryUsed'] != true && hp * 100 <= maxHp() * threshold) {
      final turns = max(
        1,
        stat35Value(_stat35ResRegen, 'vitalMemoryTurns', fallback: 3),
      );
      ledger['vitalMemoryUsed'] = true;
      final existing = getCondition('ricordo_vitale');
      if (existing == null ||
          existing.durationType == OculumConditionDurationType.turns &&
              existing.duration < turns) {
        applyCondition(
          'ricordo_vitale',
          duration: turns,
          source: 'Rigenerazione',
        );
      }
    }
    planarState['stat35ResRegen'] = ledger;
    if (hits >= hitsRequired) {
      final percent = _stat35ResPercent(_stat35ResRegen, 'healPercent', 12);
      applyStructuredHealing(
        'vita',
        oculumRoundFormulaResult(hp * percent / 100),
      );
      sendRealtimeHpChanged();
    }
    programmaSalvataggio();
  }

  int applyStat35ResImmunity(int damage, {required int? attackerGrade}) {
    if (damage <= 0 ||
        attackerGrade == null ||
        attackerGrade < 0 ||
        !hasStat35Choice('resilienza', _stat35ResImmunity) ||
        stat35ActiveTurns(_stat35ResImmunity) <= 0 ||
        !currentCombatIsActive() ||
        planarState['stat35ResImmunityFight'] != _stat35ResFight()) {
      return damage;
    }
    final difference = max(0, attackerGrade - activeCriticalGrade());
    final gradeStep = _stat35ResPercent(
      _stat35ResImmunity,
      'gradeStepPercent',
      25,
    );
    final percent = min(100, difference * gradeStep);
    return oculumRoundFormulaResult(damage * percent / 100);
  }

  Future<void> _useStat35ResAction(
    String option, {
    required bool longRest,
    required Future<void> Function() activate,
  }) async {
    final source = sheetTagAt(schedaCorrente);
    if (_stat35ResActionBusy[this] == true ||
        !hasStat35Choice('resilienza', option) ||
        !stat35RestReady(option) ||
        !currentCombatIsActive() ||
        outsideFight ||
        hpCorrenti() <= 0 ||
        realtimeService?.isConnected == true &&
            !controlsOnlineCombatSheet(source)) {
      return;
    }
    final scope = permissionScope;
    final fight = _stat35ResFight();
    _stat35ResActionBusy[this] = true;
    try {
      if (!await requestUtilitySpend('azione', preferFreeReaction: false) ||
          !mounted ||
          scope != permissionScope ||
          source != sheetTagAt(schedaCorrente) ||
          fight != _stat35ResFight()) {
        return;
      }
      spendStat35RestUse(option, long: longRest);
      await activate();
      await flushPendingCombatTurnResources();
      if (mounted) programmaSalvataggio();
    } finally {
      _stat35ResActionBusy[this] = null;
    }
  }

  Future<void> useStat35ResImmunity() => _useStat35ResAction(
    _stat35ResImmunity,
    longRest: true,
    activate: () async {
      final turns = max(
        1,
        stat35Value(_stat35ResImmunity, 'durationTurns', fallback: 2),
      );
      planarState['stat35ResImmunityFight'] = _stat35ResFight();
      setStat35ActiveTurns(_stat35ResImmunity, turns);
      aggiungiLog('[IMMUNITÀ] Protezione attiva per $turns turni personali.');
    },
  );

  bool _stat35ResHealCanTarget(
    Map<String, dynamic> source,
    Map<String, dynamic> target,
  ) {
    final sourceTag = onlineCombatTokenTag(source);
    final targetTag = onlineCombatTokenTag(target);
    return sourceTag.isNotEmpty &&
        targetTag.isNotEmpty &&
        !oculumSameSheetIdentity(sourceTag, targetTag) &&
        combatParticipantsShareTeam(source, target) &&
        source['outsideFight'] != true &&
        target['outsideFight'] != true &&
        !masterInitiativeTokenIsDead(target) &&
        !const {'fled', 'expired'}.contains(target['status']) &&
        target['mechaOccupied'] != true;
  }

  Future<void> useStat35ResGroupHeal() => _useStat35ResAction(
    _stat35ResGroupHeal,
    longRest: false,
    activate: () async {
      final own = sheetTagAt(schedaCorrente);
      final encounter = onlineCombatEncounterId;
      final scope = permissionScope;
      final fight = _stat35ResFight();
      final online = realtimeService?.isConnected == true;
      final tokens = onlineCombatTokens();
      final source = tokens
          .where((token) => combatTokenMatchesSheet(token, own))
          .firstOrNull;
      final selfPercent = _stat35ResPercent(
        _stat35ResGroupHeal,
        'selfHealPercent',
        23,
      );
      final allyPercent = _stat35ResPercent(
        _stat35ResGroupHeal,
        'allyHealPercent',
        46,
      );
      applyStructuredHealing(
        'vita',
        oculumRoundFormulaResult(maxHp() * selfPercent / 100),
      );
      sendRealtimeHpChanged();
      if (source == null || allyPercent == 0) return;
      final group =
          'stat35-res-heal:$own:${DateTime.now().microsecondsSinceEpoch}';
      final requests = <Map<String, dynamic>>[];
      final seen = <String>{};
      for (final token in tokens) {
        final tag = onlineCombatTokenTag(token);
        if (!_stat35ResHealCanTarget(source, token) || !seen.add(tag)) continue;
        requests.add({
          'id': '$group:${requests.length}',
          'scope': scope,
          'encounterId': encounter,
          'kind': 'help',
          'helpMode': _stat35ResGroupHealMode,
          'sourceTag': own,
          'sourceName': realtimeDisplayName(),
          'targetTag': tag,
          'targetName': '${token['name'] ?? tag}',
          'fightInstanceId': fight,
          'stat35HealPercent': allyPercent,
          'status': 'pending',
        });
      }
      if (online) {
        for (final request in requests) {
          attachPendingCombatTurnResources(request);
          onlineCombatRequests['${request['id']}'] = request;
        }
        programmaSalvataggio();
      }
      for (final request in requests) {
        if (!mounted ||
            scope != permissionScope ||
            fight != _stat35ResFight()) {
          return;
        }
        if (!online) {
          _applyStat35ResGroupHeal(request);
          continue;
        }
        final payload = permissionEnvelope(request);
        if (controlsOnlineCombatSheet('${request['targetTag']}')) {
          _claimStat35ResGroupHeal(payload);
        }
        await realtimeService?.sendCombatEvent('combat_help', payload);
      }
    },
  );

  bool validStat35ResGroupHeal(Map<String, dynamic> payload) {
    final id = '${payload['id'] ?? ''}';
    final source = '${payload['sourceTag'] ?? ''}';
    final target = '${payload['targetTag'] ?? ''}';
    final percent = readIntValue(payload['stat35HealPercent']);
    if (!id.startsWith('stat35-res-heal:') ||
        id.length > 160 ||
        payload['kind'] != 'help' ||
        payload['helpMode'] != _stat35ResGroupHealMode ||
        payload['senderTag'] != source ||
        !validPermissionSender(payload) ||
        payload['encounterId'] != onlineCombatEncounterId ||
        payload['fightInstanceId'] != _stat35ResFight(tag: source) ||
        !currentCombatIsActive() ||
        percent < 1 ||
        percent > 100) {
      return false;
    }
    final tokens = onlineCombatTokens();
    final caster = tokens
        .where((token) => onlineCombatTokenTag(token) == source)
        .firstOrNull;
    final recipient = tokens
        .where((token) => onlineCombatTokenTag(token) == target)
        .firstOrNull;
    return caster != null &&
        recipient != null &&
        _stat35ResHealCanTarget(caster, recipient);
  }

  void receiveStat35ResGroupHeal(Map<String, dynamic> payload) {
    final target = '${payload['targetTag'] ?? ''}';
    if (!validStat35ResGroupHeal(payload) ||
        !controlsOnlineCombatSheet(target)) {
      return;
    }
    _claimStat35ResGroupHeal(payload);
  }

  void _claimStat35ResGroupHeal(Map<String, dynamic> payload) {
    final id = '${payload['id']}';
    final existing = onlineCombatRequests[id];
    if (existing?['received'] == true) {
      unawaited(sendCombatAcknowledgement(existing!, 'help'));
      return;
    }
    final receipt = {...payload, 'received': true, 'status': 'resolved'};
    onlineCombatRequests[id] = receipt;
    _applyStat35ResGroupHeal(receipt);
    unawaited(sendCombatAcknowledgement(receipt, 'help'));
    programmaSalvataggio();
  }

  void _applyStat35ResGroupHeal(Map<String, dynamic> request) {
    final target = '${request['targetTag']}';
    final index = localSheetIndexForOculumTag(target);
    if (index < 0 || !controlsOnlineCombatSheet(target)) return;
    final percent = readIntValue(request['stat35HealPercent']);
    applySupportToOwnedSheet(index, [
      OculumStructuredEffect(
        id: 'stat35_res_group_heal',
        type: 'cura',
        resource: 'vita',
        recipient: 'se_stesso',
        valueExpression: 'hp_max * $percent / 100',
        duration: '0',
      ),
    ], 'Cura di gruppo');
  }
}
