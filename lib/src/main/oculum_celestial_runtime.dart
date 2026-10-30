part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

const oculumLunarCrystalIds = <String>[
  'lunar_crystal_forehead',
  'lunar_crystal_sternum',
  'lunar_crystal_abdomen',
  'lunar_crystal_rear',
];

int oculumCloudOpenDamage(
  int rolledBase,
  int targets, {
  int percentPerExtraTarget = 15,
  int maximumTargets = 12,
}) =>
    (max(0, rolledBase) *
            (100 +
                max(0, percentPerExtraTarget) *
                    max(0, targets.clamp(1, max(1, maximumTargets)) - 1)) ~/
            100)
        .toInt();

extension _OculumCelestialRuntime on _OculumHomePageState {
  bool get isLunarOrderCreature =>
      faunaCurrentMonsterId == 'mostro_lunare' ||
      faunaCurrentMonsterId == 'mostro_lunare_demoniaco';
  Map<String, dynamic> get lunarCrystalState {
    final state = planarState;
    if (state['lunarCrystals'] is! Map) {
      state['lunarCrystals'] = <String, dynamic>{
        for (final id in oculumLunarCrystalIds)
          id: referenceRule('crystalHits', 3),
      };
    }
    if (state['lunarCrystals'] is! Map<String, dynamic>) {
      state['lunarCrystals'] = Map<String, dynamic>.from(
        state['lunarCrystals'] as Map,
      );
    }
    return state['lunarCrystals'] as Map<String, dynamic>;
  }

  List<String> get intactLunarCrystalIds => !isLunarOrderCreature
      ? const []
      : oculumLunarCrystalIds
            .where((id) => readIntValue(lunarCrystalState[id]) > 0)
            .toList();
  bool get lunarRearEyeIntact =>
      isLunarOrderCreature &&
      readIntValue(lunarCrystalState['lunar_crystal_rear']) > 0;
  int get lunarLinkedCriticalShields =>
      intactLunarCrystalIds.length *
      referenceRule('criticalShieldsPerCrystal', 1);
  int get lunarNormalShield =>
      intactLunarCrystalIds.length *
      referenceRule('normalShieldPerCrystal', 100);
  int get lunarAttackBonus =>
      lunarRearEyeIntact ? referenceRule('rearCrystalAttackBonus', 5) : 0;
  int get lunarDefenseRollBonus =>
      lunarRearEyeIntact ? referenceRule('rearCrystalDefenseRollBonus', 6) : 0;

  Future<bool> chooseLunarDoubleCriticalCrystal(
    Map<String, dynamic> request,
    bool doubleCritical,
  ) async {
    if (!isLunarOrderCreature ||
        !doubleCritical ||
        !oculumLunarCrystalIds.contains(request['targetBodyPart'])) {
      return true;
    }
    final primary = '${request['targetBodyPart']}';
    final others = intactLunarCrystalIds.where((id) => id != primary).toList();
    if (others.isEmpty || others.contains(request['lunarSecondCrystal'])) {
      return true;
    }
    final selected = others.length == 1
        ? others.single
        : await showDialog<String>(
            context: context,
            builder: (dialog) => SimpleDialog(
              title: const Text('Doppio critico · secondo cristallo distrutto'),
              children: [
                for (final id in others)
                  SimpleDialogOption(
                    onPressed: () => Navigator.pop(dialog, id),
                    child: Text(lunarCrystalLabel(id)),
                  ),
              ],
            ),
          );
    if (selected == null || !mounted) return false;
    request['lunarSecondCrystal'] = selected;
    return true;
  }

  String lunarCrystalLabel(String id) => switch (id) {
    'lunar_crystal_forehead' => 'Cristallo della fronte',
    'lunar_crystal_sternum' => 'Cristallo centrale del petto',
    'lunar_crystal_abdomen' => 'Cristallo dell’addome',
    'lunar_crystal_rear' => 'Cristallo posteriore · occhio',
    _ => id,
  };

  bool resolveLunarCrystalHit(
    Map<String, dynamic> request, {
    required bool hit,
    required bool critical,
    required bool doubleCritical,
  }) {
    final primary = '${request['targetBodyPart'] ?? ''}';
    if (!isLunarOrderCreature || !oculumLunarCrystalIds.contains(primary)) {
      return false;
    }
    if (!hit ||
        readIntValue(request['damage']) <= 0 ||
        readIntValue(lunarCrystalState[primary]) <= 0) {
      return true;
    }
    if (!faunaReceipt('lunar-crystal:${request['id']}')) return true;
    final state = lunarCrystalState;
    state[primary] = critical || doubleCritical
        ? 0
        : max(0, readIntValue(state[primary]) - 1);
    if (doubleCritical) {
      final second = '${request['lunarSecondCrystal'] ?? ''}';
      if (second != primary && oculumLunarCrystalIds.contains(second)) {
        state[second] = 0;
      }
    }
    final broken = oculumLunarCrystalIds
        .where((id) => readIntValue(state[id]) <= 0)
        .toList();
    for (final token in _writableOnlineCombatTokens().where(
      (t) => onlineCombatTokenTag(t) == sheetTagAt(schedaCorrente),
    )) {
      token['faunaPublic'] = {
        ...Map<String, dynamic>.from(token['faunaPublic'] as Map? ?? {}),
        'brokenLunarCrystals': broken,
      };
      token['precisionBodyParts'] = publicPrecisionBodyParts;
    }
    request['lunarCrystalReceipt'] = {
      'crystalId': primary,
      'hitsRemaining': readIntValue(state[primary]),
      'brokenCrystalIds': broken,
      'bodyHpLost': 0,
    };
    invalidateDerivedDataCaches();
    aggiungiLog(
      '[CRISTALLI] ${lunarCrystalLabel(primary)}: ${readIntValue(state[primary])} colpi rimasti. Cristalli integri ${intactLunarCrystalIds.length}/4; $lunarLinkedCriticalShields Scudi critici collegati. Vita del corpo invariata.',
    );
    return true;
  }

  bool celestialAbilityAllowed(List<OculumStructuredEffect> effects) {
    if (!isLunarOrderCreature) return true;
    final crystalEffects = effects
        .where(
          (e) =>
              e.id.contains('lunar_order_crown') ||
              e.id.contains('lunar_order_prism') ||
              e.id.contains('lunar_order_darts'),
        )
        .isNotEmpty;
    final rearEffects = effects.any(
      (e) => e.id.contains('lunar_order_rear_ray'),
    );
    if (crystalEffects && intactLunarCrystalIds.isEmpty ||
        rearEffects && !lunarRearEyeIntact) {
      aggiungiLog(
        '[CRISTALLI] Tecnica non disponibile: il cristallo necessario è distrutto.',
      );
      return false;
    }
    return true;
  }
}
