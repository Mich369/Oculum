part of '../../main.dart';

const _stoneguardFightStateKey = 'stoneguardFightShield';
const _rhinoCorePublicKey = 'babyRockRhinoCore';

int oculumStoneguardStartingShield(int maximumHp, int percent) =>
    (max(0, maximumHp) * max(0, percent) + 99) ~/ 100;

bool _stoneguardOwnsSkillData(Object? data) =>
    data is Map && data['passiveId'] == oculumRhinoStoneguardPassiveId;

String _stoneguardFightInstance(Map token) =>
    '${token['fightInstanceId'] ?? ''}'.trim();

bool _stoneguardParticipant(Map token) =>
    token['outsideFight'] != true &&
    !const {'dead', 'fled', 'expired'}.contains(token['status']);

bool _stoneguardFightMatches(Map? state, String fightInstance) =>
    fightInstance.isNotEmpty && state?['fightInstanceId'] == fightInstance;

extension _OculumBabyRockRhino on _OculumHomePageState {
  Map? _stoneguardFightsAt(int index) {
    final runtime = schedePersonaggio[index]['planarRuntime'];
    final fights = runtime is Map ? runtime[_stoneguardFightStateKey] : null;
    return fights is Map ? fights : null;
  }

  Map? get _currentStoneguardFight {
    if (schedaCorrente < 0 || schedaCorrente >= schedePersonaggio.length) {
      return null;
    }
    final fights = _stoneguardFightsAt(schedaCorrente);
    if (fights == null || fights.isEmpty) return null;
    final encounter = referenceTurnEncounter();
    if (encounter['fightStarted'] != true || encounter['combatEnded'] == true) {
      return null;
    }
    final tag = sheetTagAt(schedaCorrente);
    final tokens = encounter['tokens'];
    if (tokens is! List) return null;
    for (final raw in tokens.whereType<Map>()) {
      final token = Map<String, dynamic>.from(raw);
      final fightInstance = _stoneguardFightInstance(token);
      final state = fights[fightInstance];
      if (combatTokenMatchesSheet(token, tag) &&
          _stoneguardParticipant(token) &&
          state is Map &&
          _stoneguardFightMatches(state, fightInstance)) {
        return state;
      }
    }
    return null;
  }

  int get stoneguardShieldRemaining =>
      max(0, readIntValue(_currentStoneguardFight?['remaining']));

  Map<String, dynamic>? get babyRockRhinoCorePublic {
    if (!oculumRhinoStoneguardMonsterIds.contains(faunaCurrentMonsterId)) {
      return null;
    }
    final state = _currentStoneguardFight;
    if (state == null) return null;
    return {
      'fightInstanceId': state['fightInstanceId'],
      'exposed': readIntValue(state['remaining'], fallback: 1) == 0,
    };
  }

  bool babyRockRhinoCoreExposedForToken(
    Map<String, dynamic> token, {
    required int index,
    required bool local,
  }) {
    if (!_stoneguardParticipant(token)) return false;
    final fightInstance = _stoneguardFightInstance(token);
    if (local) {
      if (index == schedaCorrente) {
        final state = babyRockRhinoCorePublic;
        return _stoneguardFightMatches(state, fightInstance) &&
            state?['exposed'] == true;
      }
      final state = _stoneguardFightsAt(index)?[fightInstance];
      return state is Map &&
          _stoneguardFightMatches(state, fightInstance) &&
          readIntValue(state['remaining'], fallback: 1) == 0;
    }
    final public = token['faunaPublic'];
    final state = public is Map ? public[_rhinoCorePublicKey] : null;
    return state is Map &&
        _stoneguardFightMatches(state, fightInstance) &&
        state['exposed'] == true;
  }

  int normalShieldTargetAfterStoneguard(
    int target,
    int before, {
    int? damageSpent,
  }) {
    final state = _currentStoneguardFight;
    final remaining = max(0, readIntValue(state?['remaining']));
    if (remaining == 0) return target;
    final spent = min(remaining, max(0, damageSpent ?? before - target));
    final after = remaining - spent;
    if (spent > 0) state!['remaining'] = after;
    return max(0, target - after);
  }

  String _stoneguardMonsterIdAt(int index, Map<String, dynamic> token) {
    final sheet = schedePersonaggio[index];
    final specific = '${sheet['monsterBookSourceId'] ?? ''}'.trim();
    if (specific.isNotEmpty) return specific;
    final legacy = '${sheet['monsterBookId'] ?? ''}'.trim();
    if (legacy.isNotEmpty) return legacy;
    return monsterBookIdForCombatToken(token, sheetIndex: index);
  }

  bool _ownsStoneguardAt(int index) {
    final sheet = schedePersonaggio[index];
    if (index == schedaCorrente) {
      return skills.any((skill) => _stoneguardOwnsSkillData(skill.scrollData));
    }
    final saved = sheet['skills'];
    return saved is List &&
        saved.whereType<Map>().any(
          (skill) => _stoneguardOwnsSkillData(skill['scrollData']),
        );
  }

  int? _stoneguardPercent() {
    final innate = oculumRhinoStoneguardMonsterIds.contains(
      faunaCurrentMonsterId,
    );
    final learned = skills
        .where(
          (skill) =>
              skill.equipaggiata && _stoneguardOwnsSkillData(skill.scrollData),
        )
        .firstOrNull;
    if (!innate && learned == null) return null;
    final catalogue = innate
        ? monsterBookEntryById(faunaCurrentMonsterId)?.encounterRules
        : null;
    final defaults = readIntValue(
      catalogue?['startingStoneShieldPercent'],
      fallback: oculumRhinoStoneguardShieldPercent,
    );
    final specification = innate
        ? planarState['startingStoneShieldPercent']
        : learned?.scrollData['startingShieldPercent'];
    return max(0, readIntValue(specification, fallback: defaults));
  }

  void synchronizeStoneguardFightStart(Iterable<Map<String, dynamic>> tokens) {
    for (final token in tokens.toList()) {
      final tag = onlineCombatTokenTag(token);
      final instance = _stoneguardFightInstance(token);
      if (instance.isEmpty || !_stoneguardParticipant(token)) continue;
      final index = localSheetIndexForOculumTag(tag);
      if (index < 0) continue;
      final monsterId = _stoneguardMonsterIdAt(index, token);
      final innate = oculumRhinoStoneguardMonsterIds.contains(monsterId);
      if (!innate && !_ownsStoneguardAt(index)) continue;
      final previous = _stoneguardFightsAt(index)?[instance];
      if (previous is Map && _stoneguardFightMatches(previous, instance)) {
        continue;
      }
      faunaForOwnedSheet(tag, () {
        if (innate && faunaCurrentMonsterId.isEmpty) {
          // Legacy owned sheets and tokens can carry only the stable Book ID.
          // Persist the exact ID so normal defense also sees the core gate.
          schedePersonaggio[schedaCorrente]['monsterBookSourceId'] = monsterId;
        }
        final percent = _stoneguardPercent();
        if (percent == null || hpCorrenti() <= 0) return;
        final granted = oculumStoneguardStartingShield(maxHp(), percent);
        planarState[_stoneguardFightStateKey] = {
          ...?_stoneguardFightsAt(schedaCorrente),
          instance: {'fightInstanceId': instance, 'remaining': granted},
        };
        clearNormalShieldBreakPenaltyIfProtected();
        updateStoneguardCombatToken(token);
        notifyActiveSheetSummaryChanged();
        programmaSalvataggio();
        if (realtimeService?.isConnected == true && !realtimeIsMasterRole) {
          sendRealtimeCurrentSheetToStaff(immediate: true);
        }
      });
    }
  }

  void updateStoneguardCombatToken(Map<String, dynamic> token) {
    token['shield'] = scudo();
    if (!oculumRhinoStoneguardMonsterIds.contains(faunaCurrentMonsterId)) {
      return;
    }
    token['faunaPublic'] = {
      ...Map<String, dynamic>.from(token['faunaPublic'] as Map? ?? const {}),
      _rhinoCorePublicKey: babyRockRhinoCorePublic,
    };
    token['precisionBodyParts'] = publicPrecisionBodyParts;
  }
}

extension OculumStoneguardProbe on OculumPerformanceProbe {
  Future<void> stoneguardDamageForTest(
    int damage, {
    String? part,
    bool bypassShields = false,
  }) => _state.applicaDannoSubito(
    dannoEsplicito: damage,
    hitBodyPart: part,
    bypassShields: bypassShields,
    bypassDefense: true,
  );
}
