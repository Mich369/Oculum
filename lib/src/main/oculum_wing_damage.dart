part of '../../main.dart';

double oculumWingFlightMultiplier(int damaged) => damaged >= 2
    ? 0
    : damaged == 1
    ? 0.5
    : 1;
int oculumWingFallDamage(int roll, int reflexes) =>
    max(0, roll.clamp(1, 60) - max(0, reflexes)).toInt();

const oculumWingFlightTurnLimit = 3;
const oculumWingFlightExpertReflexes = 50;

bool oculumWingFlightIsExpert(int effectiveReflexes) =>
    effectiveReflexes >= oculumWingFlightExpertReflexes;

/// Charge on first use in the current personal turn, including a takeoff that
/// ends before the next turn. Landing or retracting cannot refund that turn.
bool oculumPayWingFlightTurn(
  Map<String, dynamic> flight, {
  required bool unlimited,
}) {
  if (unlimited || flight['paidThisTurn'] == true) return true;
  final used = readIntValue(
    flight['usedTurns'],
  ).clamp(0, oculumWingFlightTurnLimit);
  if (used >= oculumWingFlightTurnLimit) return false;
  flight['usedTurns'] = used + 1;
  flight['paidThisTurn'] = true;
  return true;
}

extension _OculumWingDamage on _OculumHomePageState {
  bool criticalShieldBlocksDebuffs(Map request) =>
      request['criticalShieldProtected'] == true || scudoCritico() > 0;

  void resolveLimbCriticalDamage(
    Map<String, dynamic> request, {
    required int hpLost,
    required bool critical,
    bool partDestroyed = false,
    int? percentile,
  }) {
    if (hpLost <= 0 ||
        (!partDestroyed && criticalShieldBlocksDebuffs(request)) ||
        (!critical && !partDestroyed) ||
        !faunaReceipt('fracture:${request['id']}')) {
      return;
    }
    final condition = getCondition('frattura');
    final locations = (condition?.metadata['limbs'] as List? ?? [])
        .whereType<Map>()
        .map((p) => Map<String, dynamic>.from(p))
        .toList();
    if (condition != null && locations.length >= 3) {
      // Structural zero is not an additional critical after the three limbs.
      if (!critical || criticalShieldBlocksDebuffs(request)) return;
      final extra = readIntValue(condition.metadata['extraCriticals']) + 1;
      final penalty = 3 + extra;
      final target = (percentile ?? Random.secure().nextInt(100)) < 50
          ? 'danno'
          : 'difesa';
      final modifiers = Map<String, dynamic>.from(
        condition.metadata['modifiers'] as Map? ?? {},
      );
      modifiers[target] = -penalty;
      condition.metadata.addAll({
        'extraCriticals': extra,
        'modifiers': modifiers,
      });
      notifyConditionsChanged(conditionTargetsFor(condition));
      invalidateDerivedDataCaches();
      aggiungiLog(
        '[FRATTURE] Critico successivo $extra: −$penalty ai tiri degli arti fratturati e −$penalty ${target == 'danno' ? 'Danni' : 'Difesa'} (50%). Gli altri malus restano.',
      );
      programmaSalvataggio();
      return;
    }
    final point = currentPrecisionBodyParts
        .where((p) => p['id'] == request['targetBodyPart'])
        .firstOrNull;
    final group = '${point?['group'] ?? point?['id'] ?? ''}';
    if (!const {'arms', 'legs'}.contains(group) ||
        locations.any((p) => p['id'] == point!['id'])) {
      return;
    }
    locations.add({
      'id': point!['id'],
      'group': group,
      'label': point['label'],
    });
    applyCondition(
      'frattura',
      source:
          '${partDestroyed ? 'Integrità esaurita' : 'Critico'} · ${locations.map((p) => p['label']).join(', ')}',
      metadata: {'limbs': locations},
    );
    aggiungiLog(
      '[FRATTURA] ${point['label']} · ${getCondition('frattura')?.stacks ?? 0}/3. −${getCondition('frattura')?.stacks ?? 0} ai tiri degli arti fratturati.',
    );
  }

  int fractureRollPenalty(String roll) {
    if (statoForzaRimuoveMalus()) return 0;
    final structural = anatomicalPartRollPenalty(roll);
    final condition = getCondition('frattura');
    if (condition == null) return structural;
    final key = oculumNormalizeText(roll);
    final arms = const {
      'vc',
      'attacco',
      'precisione',
      'forza',
      'schianto',
      'fermezza',
      'meccanica',
      'crafting',
      'cm',
    }.contains(key);
    final legs = const {
      'riflessi',
      'iniziativa',
      'movimento',
      'agilita',
    }.contains(key);
    final locations = (condition.metadata['limbs'] as List? ?? [])
        .whereType<Map>();
    final relevant = locations
        .where(
          (p) => arms && p['group'] == 'arms' || legs && p['group'] == 'legs',
        )
        .length;
    final fracture = relevant > 0
        ? condition.stacks.clamp(1, 3).toInt() +
              readIntValue(condition.metadata['extraCriticals'])
        : 0;
    // Different material representations never double-count the same injury.
    return max(fracture, structural);
  }

  List<String> get damagedWingIds =>
      (planarState['damagedWings'] as List? ?? []).map((id) => '$id').toList();
  bool get wingsGrounded => damagedWingIds.length >= 2;
  bool wingFlightSource(String source) => RegExp(
    r'flight|fluttu|volo|ali di fata',
    caseSensitive: false,
  ).hasMatch(source);
  int wingAdjustedFlightBonus(int value, String source) =>
      value > 0 && wingFlightSource(source)
      ? (value * oculumWingFlightMultiplier(damagedWingIds.length)).floor()
      : value;

  MonsterBookEntry? _wingFlightMonsterAt(int index) {
    final id = '${schedePersonaggio[index]['monsterBookSourceId'] ?? ''}';
    if (id.isEmpty) return null;
    return monsterBookEntryById(id) ?? oculumSavedMonsterBookEntryById(id);
  }

  bool _wingFlightHasWingsAt(int index) {
    final parts = index == schedaCorrente
        ? currentPrecisionBodyParts
        : (schedePersonaggio[index]['precisionBodyParts'] as List? ?? const [])
              .whereType<Map>();
    if (parts.any((part) => part['group'] == 'wings')) return true;
    final monster = _wingFlightMonsterAt(index);
    return monster != null &&
        oculumMonsterPrecisionAnatomy(
          monster,
        ).any((part) => part['group'] == 'wings');
  }

  bool _wingFlightPermanentAt(int index) =>
      _wingFlightMonsterAt(index)?.id.split('_variante_').first == 'nuvi';

  bool _wingFlightNaturalAt(int index) =>
      _wingFlightMonsterAt(index)?.hasNaturalFlight == true;

  Map<String, dynamic> _wingFlightStateAt(int index) {
    final runtime = schedePersonaggio[index]['planarRuntime'];
    final state = runtime is Map ? runtime['wingFlight'] : null;
    return Map<String, dynamic>.from(state is Map ? state : const {});
  }

  void _storeWingFlightAt(int index, Map<String, dynamic> state) {
    final runtime = index == schedaCorrente
        ? planarState
        : Map<String, dynamic>.from(
            schedePersonaggio[index]['planarRuntime'] as Map? ?? {},
          );
    runtime['wingFlight'] = state;
    if (index != schedaCorrente) {
      schedePersonaggio[index]['planarRuntime'] = runtime;
    }
  }

  bool _wingFlightExpertAt(int index) =>
      oculumWingFlightIsExpert(escapeSubtraitAt(index, 'riflessi'));

  bool _wingFlightUnlimitedAt(int index) =>
      _wingFlightPermanentAt(index) ||
      _wingFlightNaturalAt(index) ||
      _wingFlightExpertAt(index);

  void markNaturalWingAirborneAt(int index) {
    if (schedePersonaggio[index]['realtimeSharedSheet'] == true ||
        !_wingFlightNaturalAt(index)) {
      return;
    }
    final state = _wingFlightStateAt(index);
    if (state['airborne'] == true) return;
    state['airborne'] = true;
    _bindWingFlightToEncounter(index, state);
    _storeWingFlightAt(index, state);
    _updateWingFlightProjection(index);
  }

  bool _wingFlightAvailableAt(int index, Map<String, dynamic> state) {
    final runtime = schedePersonaggio[index]['planarRuntime'];
    final injuries = runtime is Map ? runtime['damagedWings'] : null;
    if (injuries is List && injuries.toSet().length >= 2) return false;
    return _wingFlightNaturalAt(index) ||
        _wingFlightPermanentAt(index) ||
        state['manifested'] != false && _wingFlightHasWingsAt(index);
  }

  bool wingFlightWingsVisibleAt(int index) =>
      index < 0 ||
      index >= schedePersonaggio.length ||
      _wingFlightPermanentAt(index) ||
      _wingFlightStateAt(index)['manifested'] != false;

  bool wingFlightTargetHidden(String part) =>
      !wingFlightWingsVisibleAt(schedaCorrente) &&
      (part.startsWith('wings') ||
          currentPrecisionBodyParts.any(
            (point) => point['id'] == part && point['group'] == 'wings',
          ));

  bool wingCarryEligibleAt(int index) {
    if (index < 0 || index >= schedePersonaggio.length) return false;
    final state = _wingFlightStateAt(index);
    return state['airborne'] == true &&
        _wingFlightAvailableAt(index, state) &&
        _wingFlightExpertAt(index);
  }

  bool wingCarryEligibleForEscapeTag(String tag) {
    final index = localSheetIndexForOculumTag(tag);
    if (index >= 0) {
      final sheet = schedePersonaggio[index];
      if (sheet['realtimeSharedSheet'] != true) {
        return wingCarryEligibleAt(index);
      }
      final public = sheet['faunaPublic'];
      if (public is Map && public['wingCarryEligible'] is bool) {
        return public['wingCarryEligible'] == true;
      }
    }
    final public = escapeToken(tag)?['faunaPublic'];
    return public is Map && public['wingCarryEligible'] == true;
  }

  void _updateWingFlightProjection(int index, {bool broadcast = true}) {
    final tag = sheetTagAt(index);
    final sheet = schedePersonaggio[index];
    final projection = {
      'wingFlightWingsVisible': wingFlightWingsVisibleAt(index),
      'wingCarryEligible': wingCarryEligibleAt(index),
    };
    sheet['faunaPublic'] = {
      ...Map<String, dynamic>.from(sheet['faunaPublic'] as Map? ?? {}),
      ...projection,
    };
    for (final token in _writableOnlineCombatTokens()) {
      if (onlineCombatTokenTag(token) != tag) continue;
      token['faunaPublic'] = {
        ...Map<String, dynamic>.from(token['faunaPublic'] as Map? ?? {}),
        ...projection,
      };
      if (index == schedaCorrente) {
        token['precisionBodyParts'] = publicPrecisionBodyParts;
      }
    }
    if (index != schedaCorrente || !broadcast) return;
    invalidateDerivedDataCaches();
    notifyActiveSheetSummaryChanged();
    programmaSalvataggio(invalidateCaches: false);
    if (realtimeService?.isConnected == true) {
      sendRealtimeCurrentSheetToStaff(immediate: true);
      if (realtimeIsMasterRole) sendRealtimeInitiativeSnapshotIfPublished();
    }
  }

  bool get _canControlWingFlight {
    if (schedaCorrente < 0 || schedaCorrente >= schedePersonaggio.length) {
      return false;
    }
    final sheet = schedePersonaggio[schedaCorrente];
    return sheet['realtimeSharedSheet'] != true &&
        sheet['realtimeReadOnlyByMaster'] != true &&
        sheet['realtimeRestrictedByMaster'] != true &&
        hpCorrenti() > 0 &&
        (realtimeService?.isConnected != true ||
            controlsOnlineCombatSheet(sheetTagAt(schedaCorrente)));
  }

  void _changeWingManifestation(bool visible) {
    if (!_canControlWingFlight ||
        (!visible && currentLocalWingElevation() > 0) ||
        _wingFlightPermanentAt(schedaCorrente) ||
        !_wingFlightHasWingsAt(schedaCorrente)) {
      return;
    }
    final state = _wingFlightStateAt(schedaCorrente);
    state['manifested'] = visible;
    if (!visible) _landWingFlight(schedaCorrente, state);
    updateOculumHomeUi(() => _storeWingFlightAt(schedaCorrente, state));
    _updateWingFlightProjection(schedaCorrente);
  }

  void _changeWingAirborne(bool airborne) {
    if (!_canControlWingFlight) return;
    final state = _wingFlightStateAt(schedaCorrente);
    if (airborne) {
      if (!_wingFlightAvailableAt(schedaCorrente, state) ||
          !oculumPayWingFlightTurn(
            state,
            unlimited: _wingFlightUnlimitedAt(schedaCorrente),
          )) {
        return;
      }
      state['airborne'] = true;
      _bindWingFlightToEncounter(schedaCorrente, state);
    } else {
      if (currentLocalWingElevation() > 0) return;
      _landWingFlight(schedaCorrente, state);
    }
    updateOculumHomeUi(() => _storeWingFlightAt(schedaCorrente, state));
    _updateWingFlightProjection(schedaCorrente);
  }

  void _landWingFlight(int index, Map<String, dynamic> state) {
    state.remove('airborne');
    state.remove('encounterId');
    clearLocalWingElevation(sheetTagAt(index));
  }

  void _bindWingFlightToEncounter(int index, Map<String, dynamic> state) {
    if (state['encounterId'] != null || !currentCombatIsActive()) return;
    final token = escapeToken(sheetTagAt(index));
    final encounter = onlineCombatEncounterId;
    if (token != null &&
        token['outsideFight'] != true &&
        encounter.isNotEmpty) {
      state['encounterId'] = encounter;
    }
  }

  void endWingFlightForEscapeFall() {
    final index = schedaCorrente;
    if (index < 0 || index >= schedePersonaggio.length) return;
    final state = _wingFlightStateAt(index);
    if (state['airborne'] != true) return;
    _landWingFlight(index, state);
    _storeWingFlightAt(index, state);
    _updateWingFlightProjection(index);
  }

  void advanceWingFlightTurnAt(int index) {
    if (index < 0 ||
        index >= schedePersonaggio.length ||
        schedePersonaggio[index]['realtimeSharedSheet'] == true) {
      return;
    }
    if (realtimeService?.isConnected == true &&
        !controlsOnlineCombatSheet(sheetTagAt(index))) {
      return;
    }
    final state = _wingFlightStateAt(index);
    if (state['airborne'] != true && state['paidThisTurn'] != true) return;
    if (state['airborne'] == true) _bindWingFlightToEncounter(index, state);
    state.remove('paidThisTurn');
    if (state['airborne'] == true &&
        (!_wingFlightAvailableAt(index, state) ||
            !oculumPayWingFlightTurn(
              state,
              unlimited: _wingFlightUnlimitedAt(index),
            ))) {
      _landWingFlight(index, state);
      if (index == schedaCorrente) aggiungiLog('[VOLO] Termina il volo.');
    }
    _storeWingFlightAt(index, state);
    _updateWingFlightProjection(index);
  }

  void resetWingFlight({bool rest = false, String? encounterId}) {
    final index = schedaCorrente;
    if (index < 0 || index >= schedePersonaggio.length) return;
    final state = _wingFlightStateAt(index);
    if (!rest &&
        encounterId != null &&
        state['encounterId'] != null &&
        state['encounterId'] != encounterId) {
      return;
    }
    if (state['airborne'] != true &&
        state['paidThisTurn'] != true &&
        (!rest || !state.containsKey('usedTurns'))) {
      return;
    }
    _landWingFlight(index, state);
    state.remove('paidThisTurn');
    if (rest) state.remove('usedTurns');
    _storeWingFlightAt(index, state);
    _updateWingFlightProjection(index, broadcast: rest);
  }

  Widget wingFlightUtilityControls() => StatefulBuilder(
    builder: (_, refresh) =>
        _buildWingFlightUtilityControls(() => refresh(() {})),
  );

  Widget _buildWingFlightUtilityControls(VoidCallback refresh) {
    final index = schedaCorrente;
    if (index < 0 || index >= schedePersonaggio.length) {
      return const SizedBox.shrink();
    }
    final wings = _wingFlightHasWingsAt(index);
    final natural = _wingFlightNaturalAt(index);
    if (!wings && !natural && !_wingFlightPermanentAt(index)) {
      return const SizedBox.shrink();
    }
    final state = _wingFlightStateAt(index);
    final visible = wingFlightWingsVisibleAt(index);
    final airborne = state['airborne'] == true;
    final unlimited = _wingFlightUnlimitedAt(index);
    final remaining =
        (oculumWingFlightTurnLimit - readIntValue(state['usedTurns'])).clamp(
          0,
          oculumWingFlightTurnLimit,
        );
    final canTakeOff =
        _canControlWingFlight &&
        _wingFlightAvailableAt(index, state) &&
        (unlimited || remaining > 0 || state['paidThisTurn'] == true);
    final canLand = _canControlWingFlight && currentLocalWingElevation() <= 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          leading: const Icon(Icons.air),
          title: Text(t('Volo', 'Flight')),
          subtitle: Text(
            unlimited
                ? t('Volo senza limite di turni', 'No flight turn limit')
                : t(
                    '$remaining turni disponibili · recupero al riposo',
                    '$remaining turns available · recovers with rest',
                  ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (wings && !_wingFlightPermanentAt(index))
              OutlinedButton(
                onPressed: _canControlWingFlight && (!visible || canLand)
                    ? () {
                        _changeWingManifestation(!visible);
                        refresh();
                      }
                    : null,
                child: Text(
                  visible
                      ? t('Ritrai ali', 'Retract wings')
                      : t('Manifesta ali', 'Manifest wings'),
                ),
              ),
            OutlinedButton(
              onPressed: (airborne ? canLand : canTakeOff)
                  ? () {
                      _changeWingAirborne(!airborne);
                      refresh();
                    }
                  : null,
              child: Text(
                airborne
                    ? t('Atterra', 'Land')
                    : t('Prendi il volo', 'Take flight'),
              ),
            ),
            if (airborne) ...wingFlightElevationControls(refresh),
          ],
        ),
      ],
    );
  }

  Future<void> resolveWingCriticalDamage(
    Map<String, dynamic> request, {
    required int hpLost,
    required bool critical,
    bool partDestroyed = false,
    int? fallRoll,
  }) async {
    final part = '${request['targetBodyPart'] ?? ''}';
    if (hpLost <= 0 ||
        (!critical && !partDestroyed) ||
        (!partDestroyed && criticalShieldBlocksDebuffs(request)) ||
        wingFlightTargetHidden(part)) {
      return;
    }
    if (!currentPrecisionBodyParts.any(
      (p) => p['id'] == part && p['group'] == 'wings',
    )) {
      return;
    }
    final wings = damagedWingIds.toSet();
    if (!wings.add(part)) return;
    planarState['damagedWings'] = wings.toList();
    aggiungiLog(
      '[ALI] ${wings.length == 1 ? 'Ala danneggiata: bonus del volo dimezzati' : 'Due ali danneggiate: volo impossibile'}. Recupero al Riposo Lungo.',
    );
    invalidateDerivedDataCaches();
    if (wings.length == 2) {
      final attackId = '${request['id'] ?? ''}';
      if (attackId.isNotEmpty) {
        planarState['lastWingFallInterceptionId'] = attackId;
      }
      endWingFlightForEscapeFall();
      final reflex = hiddenEyeStats
          .where((s) => s.id == 'riflessi')
          .firstOrNull;
      final bonus = reflex == null ? 0 : hiddenEyeTotal(reflex);
      final die = fallRoll ?? 1 + Random.secure().nextInt(60);
      final damage = oculumWingFallDamage(die, bonus);
      planarState['flightTurns'] = 0;
      aggiungiLog(
        '[CADUTA] 1d60 ($die) − Riflessi $bonus = $damage Danni, poi normali protezioni.',
      );
      if (damage > 0) {
        await applyRunicReflectedDamage(
          sheetTagAt(schedaCorrente),
          damage,
          element: 'contundente',
          source: 'Caduta',
        );
      }
    }
    programmaSalvataggio();
  }

  void restoreDamagedWings() {
    restoreAnatomicalPartsByRecovery('long_rest');
    if (damagedWingIds.isEmpty) return;
    planarState.remove('damagedWings');
    invalidateDerivedDataCaches();
    aggiungiLog('[ALI] Riposo Lungo: ali ripristinate.');
  }
}
