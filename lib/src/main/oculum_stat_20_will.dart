part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

const _stat20WillSlam = 'will_heavy_slam';
const _stat20WillPressure = 'will_heavy_pressure';

int oculumStat20WillSlamDamage(int normal, {int percent = 150}) =>
    oculumRoundFormulaResult(max(0, normal) * max(0, percent) / 100);

({int bonus, int criticalMin}) oculumStat20WillPressureModifiers({
  required int casterPower,
  required int targetPower,
  int minimumBonus = 9,
  int minimumNatural = 18,
}) => (
  bonus: max(max(0, minimumBonus), casterPower - targetPower),
  criticalMin: minimumNatural.clamp(1, 20),
);

bool oculumStat20WillPressureGradeAllowed(
  int casterGrade,
  int targetGrade, {
  int gradeAbove = 1,
}) =>
    targetGrade >= 0 && targetGrade <= max(0, casterGrade) + max(0, gradeAbove);

final _stat20WillActionBusy = Expando<bool>();

extension _OculumStat20Will on _OculumHomePageState {
  bool _stat20WillAvailable(String option) =>
      stat20Choice('volonta') == option &&
      currentCombatIsActive() &&
      !outsideFight &&
      hpCorrenti() > 0 &&
      (realtimeService?.isConnected != true ||
          controlsOnlineCombatSheet(sheetTagAt(schedaCorrente)));

  bool get stat20WillSlamReady =>
      _stat20WillAvailable(_stat20WillSlam) &&
      stat35Cooldown(_stat20WillSlam) == 0;

  void commitStat20WillSlam() {
    if (!stat20WillSlamReady) return;
    setStat35Cooldown(
      _stat20WillSlam,
      stat35Value(_stat20WillSlam, 'cooldown', fallback: 3),
    );
    programmaSalvataggio();
  }

  int stat20WillSlamDamage(int normal) => oculumStat20WillSlamDamage(
    normal,
    percent: stat35Value(_stat20WillSlam, 'damagePercent', fallback: 150),
  );

  Future<void> activateStat20WillSlam() async {
    if (!stat20WillSlamReady || _stat20WillActionBusy[this] == true) return;
    _stat20WillActionBusy[this] = true;
    try {
      await planOnlineAttack(stat20WillSlam: true);
    } finally {
      _stat20WillActionBusy[this] = null;
    }
  }

  void applyStat20WillSlamFracture(
    Map<String, dynamic> request, {
    required int hpLost,
  }) {
    if (request['stat20WillSlam'] != true ||
        hpLost <= 0 ||
        criticalShieldBlocksDebuffs(request)) {
      return;
    }
    final tag = sheetTagAt(schedaCorrente);
    if (request['targetTag'] != tag ||
        request['scope'] != permissionScope ||
        request['encounterId'] != onlineCombatEncounterId) {
      return;
    }
    final parts = currentPrecisionBodyParts;
    final selected = '${request['targetBodyPart'] ?? ''}'.trim();
    final point =
        parts.where((part) => part['id'] == selected).firstOrNull ??
        parts.where((part) => part['group'] == 'torso').firstOrNull ??
        <String, dynamic>{'id': 'torso', 'group': 'torso', 'label': 'Torace'};
    final id = '${point['id']}';
    final group = '${point['group'] ?? id}';
    final label = '${point['label'] ?? id}';
    final locations =
        (getCondition('frattura')?.metadata['limbs'] as List? ?? [])
            .whereType<Map>()
            .map((part) => Map<String, dynamic>.from(part))
            .toList();
    if (locations.length >= 3 || locations.any((part) => part['id'] == id)) {
      return;
    }
    if (const {'arms', 'legs'}.contains(group)) {
      resolveLimbCriticalDamage(
        {...request, 'targetBodyPart': id},
        hpLost: hpLost,
        critical: true,
      );
      return;
    }
    final packet = '${request['id'] ?? ''}';
    if (packet.isEmpty || !faunaReceipt('fracture:$packet')) return;
    applyCondition(
      'frattura',
      source: 'Schianto Pesante · $label',
      metadata: {
        'limbs': [
          ...locations,
          {'id': id, 'group': group, 'label': label},
        ],
      },
    );
  }

  bool get stat20WillPressureReady => _stat20WillAvailable(_stat20WillPressure);

  int get stat20WillPressureMaxTargets =>
      stat35Value(_stat20WillPressure, 'maxTargets', fallback: 10).clamp(1, 10);

  String _stat20WillCombatTeam(Map token) {
    final side = '${token['side'] ?? 'ally'}';
    return side == 'party' ? 'ally' : side;
  }

  Map<String, dynamic>? _stat20WillCombatToken(String tag) =>
      onlineCombatTokens()
          .where((token) => combatTokenMatchesSheet(token, tag))
          .firstOrNull;

  int? _stat20WillCombatGrade(Map<String, dynamic> token) {
    final index = localSheetIndexForOculumTag(onlineCombatTokenTag(token));
    if (index >= 0) return max(0, sheetIntValueAt(index, 'grado'));
    final grade = token['grade'] ?? token['grado'];
    return grade is num ? grade.toInt() : int.tryParse('$grade');
  }

  bool _stat20WillPressureOpponents(
    Map<String, dynamic> source,
    Map<String, dynamic> target,
  ) =>
      onlineCombatTokenTag(target).isNotEmpty &&
      _stat20WillCombatTeam(source) != _stat20WillCombatTeam(target) &&
      target['outsideFight'] != true &&
      target['mechaOccupied'] != true &&
      !masterInitiativeTokenIsDead(target) &&
      !const {'fled', 'expired'}.contains(target['status']);

  bool stat20WillPressureCanTarget(Map<String, dynamic> token) {
    final source = _stat20WillCombatToken(sheetTagAt(schedaCorrente));
    final grade = _stat20WillCombatGrade(token);
    return source != null &&
        grade != null &&
        _stat20WillPressureOpponents(source, token) &&
        oculumStat20WillPressureGradeAllowed(
          activeCriticalGrade(),
          grade,
          gradeAbove: stat35Value(
            _stat20WillPressure,
            'gradeAbove',
            fallback: 1,
          ).clamp(0, 1),
        );
  }

  Map<String, dynamic> stat20WillPressurePayload() => {
    'stat20WillPressure': true,
    'stat20WillPressureFight': combatSubtraitExperienceFightId(
      onlineCombatEncounterId,
    ),
    'stat20WillPressureCasterPower': scoutPowerReserveForActiveSheet().total,
    'stat20WillPressureGradeAbove': stat35Value(
      _stat20WillPressure,
      'gradeAbove',
      fallback: 1,
    ).clamp(0, 1),
    'stat20WillPressureMinimumBonus': max(
      0,
      stat35Value(_stat20WillPressure, 'minimumBonus', fallback: 9),
    ),
    'stat20WillPressureMinimumNatural': stat35Value(
      _stat20WillPressure,
      'minimumNatural',
      fallback: 18,
    ).clamp(1, 20),
  };

  Future<void> activateStat20WillPressure() async {
    if (!stat20WillPressureReady || _stat20WillActionBusy[this] == true) return;
    _stat20WillActionBusy[this] = true;
    try {
      await planOnlineAttack(
        stat20WillPressure: true,
        maximumTargets: stat20WillPressureMaxTargets,
      );
    } finally {
      _stat20WillActionBusy[this] = null;
    }
  }

  bool applyStat20WillPressure(Map<String, dynamic> request) {
    final targetTag = sheetTagAt(schedaCorrente);
    final casterTag = '${request['sourceTag'] ?? ''}';
    final packet = '${request['id'] ?? ''}';
    if (request['stat20WillPressure'] != true ||
        packet.isEmpty ||
        casterTag.isEmpty ||
        request['targetTag'] != targetTag ||
        request['scope'] != permissionScope ||
        request['encounterId'] != onlineCombatEncounterId ||
        request['stat20WillPressureFight'] !=
            combatSubtraitExperienceFightId(
              onlineCombatEncounterId,
              ownerTag: casterTag,
            ) ||
        !currentCombatIsActive() ||
        outsideFight ||
        hpCorrenti() <= 0) {
      return false;
    }
    final source = _stat20WillCombatToken(casterTag);
    final target = _stat20WillCombatToken(targetTag);
    final grade = source == null ? null : _stat20WillCombatGrade(source);
    if (source == null ||
        target == null ||
        grade == null ||
        !_stat20WillPressureOpponents(source, target) ||
        !oculumStat20WillPressureGradeAllowed(
          grade,
          activeCriticalGrade(),
          gradeAbove: readIntValue(
            request['stat20WillPressureGradeAbove'],
            fallback: 1,
          ).clamp(0, 1),
        ) ||
        !faunaReceipt('stat20-will-pressure:$packet')) {
      return false;
    }
    final encounter = onlineCombatEncounterId;
    final fight = combatSubtraitExperienceFightId(encounter);
    final modifiers = oculumStat20WillPressureModifiers(
      casterPower: max(
        0,
        readIntValue(request['stat20WillPressureCasterPower']),
      ),
      targetPower: scoutPowerReserveForActiveSheet().total,
      minimumBonus: readIntValue(
        request['stat20WillPressureMinimumBonus'],
        fallback: 9,
      ),
      minimumNatural: readIntValue(
        request['stat20WillPressureMinimumNatural'],
        fallback: 18,
      ),
    );
    return applyCondition(
      'immobilizzato',
      duration: 1,
      durationType: OculumConditionDurationType.turns,
      tickTrigger: OculumConditionTickTrigger.endTurn,
      source: 'Pressione Pesante · ${source['name'] ?? casterTag}',
      metadata: {
        'referenceCurseSource': 'stat20-pressure:$fight:$casterTag',
        'stat20WillPressureEncounter': encounter,
        'stat20WillPressureCampaign': permissionCampaignId,
        'stat20WillPressureFight': fight,
        'stat20WillPressureCaster': casterTag,
        'stat20WillPressureBonus': modifiers.bonus,
        'stat20WillPressureNatural': modifiers.criticalMin,
      },
    );
  }

  ({int bonus, int criticalMin}) stat20WillPressureAttackModifiers(
    Map<String, dynamic> request,
  ) {
    var result = (bonus: 0, criticalMin: 21);
    final encounter = onlineCombatEncounterId;
    final targetTag = sheetTagAt(schedaCorrente);
    if (request['stat20WillPressure'] == true ||
        request['targetTag'] != targetTag ||
        request['scope'] != permissionScope ||
        request['encounterId'] != encounter ||
        !currentCombatIsActive()) {
      return result;
    }
    final attacker = _stat20WillCombatToken('${request['sourceTag'] ?? ''}');
    if (attacker == null) return result;
    final fight = combatSubtraitExperienceFightId(encounter);
    for (final condition in activeConditions) {
      final metadata = condition.metadata;
      if (condition.conditionType != 'immobilizzato' ||
          condition.duration <= 0 ||
          metadata['stat20WillPressureEncounter'] != encounter ||
          metadata['stat20WillPressureCampaign'] != permissionCampaignId ||
          metadata['stat20WillPressureFight'] != fight) {
        continue;
      }
      final caster = _stat20WillCombatToken(
        '${metadata['stat20WillPressureCaster'] ?? ''}',
      );
      if (caster == null ||
          _stat20WillCombatTeam(caster) != _stat20WillCombatTeam(attacker)) {
        continue;
      }
      final bonus = max(0, readIntValue(metadata['stat20WillPressureBonus']));
      final natural = readIntValue(
        metadata['stat20WillPressureNatural'],
        fallback: 18,
      ).clamp(1, 20);
      if (bonus > result.bonus ||
          bonus == result.bonus && natural < result.criticalMin) {
        result = (bonus: bonus, criticalMin: natural);
      }
    }
    return result;
  }

  void expireStat20WillPressureAtFightEnd(
    String encounter, {
    String? campaignId,
  }) {
    if (encounter.isEmpty) return;
    final campaign = campaignId ?? permissionCampaignId;
    bool matches(Object? metadata) =>
        metadata is Map &&
        metadata['stat20WillPressureEncounter'] == encounter &&
        metadata['stat20WillPressureCampaign'] == campaign;
    var changed = false;
    for (var index = 0; index < schedePersonaggio.length; index++) {
      final sheet = schedePersonaggio[index];
      if (sheet['realtimeSharedSheet'] == true) continue;
      if (index == schedaCorrente) {
        final before = activeConditions.length;
        activeConditions.removeWhere(
          (condition) =>
              condition.conditionType == 'immobilizzato' &&
              matches(condition.metadata),
        );
        if (before == activeConditions.length) continue;
        notifyConditionsChanged({OculumConditionTarget.movimento});
        sheet['conditions'] = activeConditions
            .map((condition) => condition.toJson())
            .toList();
      } else {
        final conditions = sheet['conditions'] ?? sheet['activeConditions'];
        if (conditions is! List) continue;
        final remaining = conditions
            .where(
              (condition) =>
                  condition is! Map ||
                  condition['conditionType'] != 'immobilizzato' ||
                  !matches(condition['metadata']),
            )
            .toList();
        if (remaining.length == conditions.length) continue;
        sheet['conditions'] = remaining;
      }
      changed = true;
    }
    if (changed) programmaSalvataggio();
  }
}
