part of '../../main.dart';

const _stat20VitalWake = 'res_vital_wake';
const _stat20Physical = 'res_physical';
const _stat20WakingLifeKey = 'stat20WakingLife';
const _stat20PhysicalResistanceKey = 'stat20PhysicalResistance';

String oculumStat20PhysicalResistanceTier({
  required int attackTotal,
  required int resistanceTotal,
  int pointsPerTier = 6,
}) {
  final tiersLost =
      max(0, attackTotal - resistanceTotal) ~/ max(1, pointsPerTier);
  return switch (tiersLost) {
    0 => 'Alta Resistenza',
    1 => 'Resistenza',
    2 => 'Resistenza Leggera',
    _ => 'Normale',
  };
}

extension _OculumStat20Resilience on _OculumHomePageState {
  Map? get _stat20WakingLife {
    final saved = planarState[_stat20WakingLifeKey];
    return saved is Map ? saved : null;
  }

  int stat20WakingLifeRemaining() =>
      max(0, readIntValue(_stat20WakingLife?['remaining']));

  int grantStat20WakingLife({int? day, int? worldSeconds, Random? random}) {
    if (stat20Choice('resilienza') != _stat20VitalWake || hpCorrenti() <= 0) {
      return 0;
    }
    final usesWorldClock =
        worldSeconds != null ||
        day == null && worldClockProgress.calendarOriginDay > 0;
    final dayNumber = usesWorldClock
        ? max(0, worldSeconds ?? worldClockSeconds) ~/ oculumWorldDaySeconds
        : max(1, day ?? currentOculumDayValue());
    final dayKey = '${usesWorldClock ? 'clock' : 'calendar'}:$dayNumber';
    final previous = _stat20WakingLife;
    if (previous?['day'] == dayKey ||
        usesWorldClock &&
            readIntValue(previous?['clockDay'], fallback: -1) > dayNumber) {
      return 0;
    }
    final faces = stat35Value(
      _stat20VitalWake,
      'diceFaces',
      fallback: 50,
    ).clamp(1, 10000).toInt();
    final bonus = stat35Value(
      _stat20VitalWake,
      'flatLife',
      fallback: 50,
    ).clamp(0, 1000000).toInt();
    final total = (random ?? Random.secure()).nextInt(faces) + 1 + bonus;
    planarState[_stat20WakingLifeKey] = {
      'day': dayKey,
      'remaining': total,
      if (usesWorldClock) 'clockDay': dayNumber,
    };
    aggiungiLog('[RISVEGLIO VITALE] $total Vita temporanea.');
    sendRealtimeHpChanged();
    programmaSalvataggio();
    return total;
  }

  int consumeStat20WakingLife(int amount) {
    final remaining = stat20WakingLifeRemaining();
    final spent = min(remaining, max(0, amount));
    if (spent > 0) _stat20WakingLife?['remaining'] = remaining - spent;
    return max(0, amount) - spent;
  }

  String _stat20ResistanceFight() =>
      '$permissionScope:$permissionCampaignId:$onlineCombatEncounterId:'
      '${combatSubtraitExperienceFightId(onlineCombatEncounterId)}';

  void recordStat20PhysicalResistance({
    required String element,
    required int attackTotal,
    required int resistanceTotal,
    String? packetId,
  }) {
    final elementId = oculumNormalizeElementId(element);
    if (elementId == 'sconosciuto' ||
        stat20Choice('resilienza') != _stat20Physical ||
        outsideFight ||
        !currentCombatIsActive() ||
        realtimeService?.isConnected == true &&
            !controlsOnlineCombatSheet(sheetTagAt(schedaCorrente))) {
      return;
    }
    final fight = _stat20ResistanceFight();
    if (packetId != null &&
        packetId.isNotEmpty &&
        !faunaReceipt('stat20-physical:$fight:$packetId')) {
      return;
    }
    final previous = planarState[_stat20PhysicalResistanceKey];
    final elements =
        previous is Map &&
            previous['fight'] == fight &&
            previous['elements'] is Map
        ? Map<String, dynamic>.from(previous['elements'] as Map)
        : <String, dynamic>{};
    final tier = oculumStat20PhysicalResistanceTier(
      attackTotal: attackTotal,
      resistanceTotal: resistanceTotal,
      pointsPerTier: stat35Value(_stat20Physical, 'pointsPerTier', fallback: 6),
    );
    if (tier == 'Normale') {
      elements.remove(elementId);
    } else {
      elements[elementId] = tier;
    }
    planarState[_stat20PhysicalResistanceKey] = {
      'fight': fight,
      'elements': elements,
    };
    programmaSalvataggio();
  }

  String? stat20PhysicalResistancePreset(String element) {
    if (stat20Choice('resilienza') != _stat20Physical ||
        outsideFight ||
        !currentCombatIsActive()) {
      return null;
    }
    final saved = planarState[_stat20PhysicalResistanceKey];
    if (saved is! Map || saved['fight'] != _stat20ResistanceFight()) {
      return null;
    }
    final elements = saved['elements'];
    final tier = elements is Map
        ? elements[oculumNormalizeElementId(element)]
        : null;
    return switch (tier) {
      'Alta Resistenza' ||
      'Resistenza' ||
      'Resistenza Leggera' => tier as String,
      _ => null,
    };
  }

  void resetStat20PhysicalResistance() {
    planarState.remove(_stat20PhysicalResistanceKey);
  }
}
