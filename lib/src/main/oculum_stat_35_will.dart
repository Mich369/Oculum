part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

final _stat35WillActionBusy = Expando<bool>();
const _stat35WillAura = 'will_aura';
const _stat35WillDecisive = 'will_decisive';
const _stat35WillPressure = 'will_pressure';

extension _OculumStat35Will on _OculumHomePageState {
  bool _stat35WillAvailable(String option) =>
      hasStat35Choice('volonta', option) &&
      currentCombatIsActive() &&
      !outsideFight &&
      hpCorrenti() > 0 &&
      (realtimeService?.isConnected != true ||
          controlsOnlineCombatSheet(sheetTagAt(schedaCorrente)));

  bool get will35DecisiveReady =>
      _stat35WillAvailable(_stat35WillDecisive) &&
      stat35RestReady(_stat35WillDecisive);

  void commitWill35Decisive() {
    if (!will35DecisiveReady) return;
    spendStat35RestUse(_stat35WillDecisive, long: true);
    programmaSalvataggio();
  }

  int will35DecisiveDamage(int normal) =>
      normal +
      oculumRoundFormulaResult(
        scoutPowerReserveForActiveSheet().current *
            max(
              0,
              stat35Value(_stat35WillDecisive, 'powerPercent', fallback: 15),
            ) /
            100,
      );

  Future<void> activateStat35WillDecisive() async {
    if (!will35DecisiveReady || _stat35WillActionBusy[this] == true) return;
    _stat35WillActionBusy[this] = true;
    try {
      await planOnlineAttack(stat35Decisive: true);
    } finally {
      _stat35WillActionBusy[this] = null;
    }
  }

  int get will35PressurePenalty {
    if (!_stat35WillAvailable(_stat35WillPressure) ||
        stat35ActiveTurns(_stat35WillPressure) <= 0 ||
        planarState['stat35WillPressureEncounter'] != onlineCombatEncounterId) {
      return 0;
    }
    return max(
      0,
      stat35Value(_stat35WillPressure, 'attackPenalty', fallback: 6),
    );
  }

  Future<void> _useStat35WillAction(
    String option,
    Future<void> Function() activate,
  ) async {
    if (_stat35WillActionBusy[this] == true ||
        !_stat35WillAvailable(option) ||
        !stat35RestReady(option) ||
        stat35Cooldown(option) > 0) {
      return;
    }
    final origin = (
      currentSheetScrollId(),
      permissionScope,
      onlineCombatEncounterId,
    );
    _stat35WillActionBusy[this] = true;
    try {
      if (!await requestUtilitySpend('azione', preferFreeReaction: false) ||
          !mounted ||
          origin !=
              (
                currentSheetScrollId(),
                permissionScope,
                onlineCombatEncounterId,
              ) ||
          !_stat35WillAvailable(option)) {
        return;
      }
      await activate();
      await flushPendingCombatTurnResources();
      if (mounted) programmaSalvataggio();
    } finally {
      _stat35WillActionBusy[this] = null;
    }
  }

  Future<void> activateStat35WillPressure() =>
      _useStat35WillAction(_stat35WillPressure, () async {
        final turns = max(
          1,
          stat35Value(_stat35WillPressure, 'durationTurns', fallback: 3),
        );
        planarState['stat35WillPressureEncounter'] = onlineCombatEncounterId;
        setStat35ActiveTurns(_stat35WillPressure, turns);
        setStat35Cooldown(
          _stat35WillPressure,
          stat35Value(_stat35WillPressure, 'cooldown', fallback: 6),
        );
        aggiungiLog('[PRESSIONE DOMINANTE] Attiva per $turns turni personali.');
      });

  Future<void> activateStat35WillAura() => _useStat35WillAction(
    _stat35WillAura,
    () async {
      const source = 'Aura della Volontà';
      final turns = max(
        1,
        stat35Value(_stat35WillAura, 'durationTurns', fallback: 3),
      );
      final self = max(
        0,
        stat35Value(_stat35WillAura, 'selfPercent', fallback: 20),
      );
      final allies = max(
        0,
        stat35Value(_stat35WillAura, 'allyPercent', fallback: 10),
      );
      final shield = max(
        0,
        stat35Value(_stat35WillAura, 'shield', fallback: 200),
      );
      final own = sheetTagAt(schedaCorrente);
      final tokens = onlineCombatTokens();
      final actor = tokens
          .where((token) => combatTokenMatchesSheet(token, own))
          .firstOrNull;
      final alliesTags = actor == null
          ? <String>[]
          : {
              for (final target in tokens)
                if (_stat35ResHealCanTarget(actor, target))
                  onlineCombatTokenTag(target),
            }.toList();
      spendStat35RestUse(_stat35WillAura, long: false);
      applyStructuredEffectsOnActivation(
        [
          if (shield > 0)
            OculumStructuredEffect(type: 'scudo', valueExpression: '$shield'),
          for (final type in ['danno_percentuale', 'difesa_percentuale']) ...[
            if (self > 0)
              OculumStructuredEffect(
                id: 'stat35:will_aura:self:$type',
                type: type,
                valueExpression: '$self',
                mode: 'finche_attivo',
                duration: '$turns',
              ),
            if (allies > 0 && alliesTags.isNotEmpty)
              OculumStructuredEffect(
                id: 'stat35:will_aura:ally:$type',
                type: type,
                valueExpression: '$allies',
                mode: 'finche_attivo',
                duration: '$turns',
                recipient: 'alleato',
              ),
          ],
        ],
        source: source,
        applyFusionBonus: false,
      );
      if (allies > 0 && alliesTags.isNotEmpty) {
        await deliverPendingSupport(
          minimum: alliesTags.length,
          maximum: alliesTags.length,
          selectedTags: alliesTags,
          excludeSelf: true,
          sourcePrefix: source,
        );
      }
      if (mounted && sheetTagAt(schedaCorrente) == own) {
        aggiungiLog(
          '[AURA DELLA VOLONTÀ] Scudo +$shield. Bonus attivi per $turns turni.',
        );
      }
    },
  );
}
