part of '../../main.dart';

const _statOpenDominionPenaltyKey = 'statOpenDominionPenalty';

int oculumStatOpenDamageShare(int damage, int targets, int index) {
  if (damage <= 0 || targets <= 0 || index < 0 || index >= targets) return 0;
  return damage ~/ targets + (index < damage % targets ? 1 : 0);
}

extension _OculumStatOpenNewTracks on _OculumHomePageState {
  int statOpenAttackDamage(
    String id, {
    required int damage,
    required int level,
    required int power,
    required int targets,
    required int index,
  }) {
    if (targets <= 0 || index < 0 || index >= targets) return 0;
    int value(String key) => max(0, statOpenValue(id, key));
    final base = max(0, damage) * value('damagePercent') ~/ 100;
    switch (statOpenTrack(id)) {
      case 'will_oath':
        return oculumStatOpenDamageShare(base, targets, index) +
            max(0, power) * value('powerPercent') ~/ 100;
      case 'matter_geometry':
        return base;
      case 'oculum_meridian':
        final multiplier =
            value('levelDamageMultiplier') +
            (statOpenOwnBuff(id) ? value('levelBuffMultiplier') : 0);
        return oculumStatOpenDamageShare(
          base + max(0, level) * multiplier,
          targets,
          index,
        );
      default:
        return 0;
    }
  }

  int statOpenAttackPenalty(String id) {
    if (statOpenTrack(id) != 'will_oath') return 0;
    return max(0, statOpenValue(id, 'attackPenalty')) +
        (statOpenOwnBuff(id) ? max(0, statOpenValue(id, 'penaltyBuff')) : 0);
  }

  int statOpenAttackCost(String id) => statOpenTrack(id) == 'oculum_meridian'
      ? max(0, statOpenValue(id, 'cost'))
      : 0;

  bool canPayStatOpenAttack(String id) {
    if (statOpenTrack(id).isEmpty) return false;
    final cost = statOpenAttackCost(id);
    return cost == 0 ||
        (!hasCondition('oculum_sigillato') &&
            readIntValue(planarState['mortalKiLock']) <= 0 &&
            oculumTotale() >= cost &&
            currentTemporaryOculumState().total - currentOculumRuntimeFloor() >=
                cost);
  }

  bool payStatOpenAttack(String id) {
    if (!canPayStatOpenAttack(id)) return false;
    final cost = statOpenAttackCost(id);
    if (cost == 0) return true;
    final before = currentTemporaryOculumState().total;
    spendOculum(cost);
    return before - currentTemporaryOculumState().total == cost;
  }

  ({int round, int active, int target})? _statOpenTurnPosition() {
    final encounter = referenceTurnEncounter();
    final raw = encounter['tokens'];
    if (raw is! List) return null;
    final active = readIntValue(encounter['activeIndex'], fallback: -1);
    final round = readIntValue(encounter['round'], fallback: -1);
    if (active < 0 || active >= raw.length || round < 0) return null;
    final own = sheetTagAt(schedaCorrente);
    final target = raw.indexWhere(
      (token) =>
          token is Map &&
          combatTokenMatchesSheet(Map<String, dynamic>.from(token), own),
    );
    return target < 0 ? null : (round: round, active: active, target: target);
  }

  void applyStatOpenDominionPenalty(
    Map<String, dynamic> request, {
    required OculumAttackOutcome outcome,
  }) {
    if (outcome == OculumAttackOutcome.avoided ||
        statOpenTrack('${request['statOpenId'] ?? ''}') != 'will_oath') {
      return;
    }
    final own = sheetTagAt(schedaCorrente);
    final encounter = '${request['encounterId'] ?? ''}';
    final packet = '${request['id'] ?? ''}';
    final amount = readIntValue(request['statOpenDominionPenalty']);
    if (amount <= 0 ||
        amount > 20000 ||
        packet.isEmpty ||
        encounter.isEmpty ||
        request['scope'] != permissionScope ||
        request['targetTag'] != own ||
        encounter != onlineCombatEncounterId ||
        !controlsOnlineCombatSheet(own)) {
      return;
    }
    final fight = combatSubtraitExperienceFightId(encounter);
    if (!faunaReceipt('stat-open-dominion:$permissionScope:$fight:$packet')) {
      return;
    }
    final turn = _statOpenTurnPosition();
    planarState[_statOpenDominionPenaltyKey] = {
      'scope': permissionScope,
      'encounter': encounter,
      'fight': fight,
      'packet': packet,
      'amount': amount,
      if (turn != null)
        'lastRound': turn.round + (turn.target <= turn.active ? 1 : 0),
      'turns': 2,
    };
    aggiungiLog('[DOMINIO] −$amount al prossimo tiro d’attacco.');
    programmaSalvataggio();
  }

  Map? _statOpenFightDominionPenalty() {
    final data = planarState[_statOpenDominionPenaltyKey];
    if (data is! Map) return null;
    final encounter = onlineCombatEncounterId;
    if (!currentCombatIsActive() ||
        data['scope'] != permissionScope ||
        data['encounter'] != encounter ||
        data['fight'] != combatSubtraitExperienceFightId(encounter)) {
      return null;
    }
    return data;
  }

  Map? _statOpenPendingDominionPenalty() {
    final data = _statOpenFightDominionPenalty();
    if (data == null) return null;
    final turn = _statOpenTurnPosition();
    final lastRound = data['lastRound'];
    if (turn != null && lastRound is int) {
      if (turn.round > lastRound ||
          (turn.round == lastRound && turn.active > turn.target)) {
        return null;
      }
    } else if (readIntValue(data['turns']) <= 0) {
      return null;
    }
    return data;
  }

  String? pendingStatOpenDominionPenaltyReceipt() {
    final packet = _statOpenPendingDominionPenalty()?['packet'];
    return packet is String && packet.isNotEmpty ? packet : null;
  }

  int takeStatOpenDominionPenalty({String? receipt}) {
    final data = receipt == null
        ? _statOpenPendingDominionPenalty()
        : _statOpenFightDominionPenalty();
    if (data == null || (receipt != null && data['packet'] != receipt)) {
      return 0;
    }
    planarState.remove(_statOpenDominionPenaltyKey);
    programmaSalvataggio();
    return readIntValue(data['amount']);
  }

  void advanceStatOpenDominionPenalty() {
    if (!planarState.containsKey(_statOpenDominionPenaltyKey)) return;
    final data = _statOpenPendingDominionPenalty();
    if (data == null) {
      planarState.remove(_statOpenDominionPenaltyKey);
    } else {
      data['turns'] = max(0, readIntValue(data['turns']) - 1);
    }
  }
}
