part of '../../main.dart';

double oculumWingFlightMultiplier(int damaged) => damaged >= 2
    ? 0
    : damaged == 1
    ? 0.5
    : 1;
int oculumWingFallDamage(int roll, int reflexes) =>
    max(0, roll.clamp(1, 60) - max(0, reflexes)).toInt();

extension _OculumWingDamage on _OculumHomePageState {
  bool criticalShieldBlocksDebuffs(Map request) =>
      request['criticalShieldProtected'] == true || scudoCritico() > 0;

  void resolveLimbCriticalDamage(
    Map<String, dynamic> request, {
    required int hpLost,
    required bool critical,
    int? percentile,
  }) {
    if (hpLost <= 0 ||
        criticalShieldBlocksDebuffs(request) ||
        !critical ||
        !faunaReceipt('fracture:${request['id']}')) {
      return;
    }
    final condition = getCondition('frattura');
    final locations = (condition?.metadata['limbs'] as List? ?? [])
        .whereType<Map>()
        .map((p) => Map<String, dynamic>.from(p))
        .toList();
    if (condition != null && locations.length >= 3) {
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
      source: 'Critico · ${locations.map((p) => p['label']).join(', ')}',
      metadata: {'limbs': locations},
    );
    aggiungiLog(
      '[FRATTURA] ${point['label']} · ${getCondition('frattura')?.stacks ?? 0}/3. −${getCondition('frattura')?.stacks ?? 0} ai tiri degli arti fratturati.',
    );
  }

  int fractureRollPenalty(String roll) {
    if (statoForzaRimuoveMalus()) return 0;
    final condition = getCondition('frattura');
    if (condition == null) return 0;
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
    return relevant > 0
        ? condition.stacks.clamp(1, 3).toInt() +
              readIntValue(condition.metadata['extraCriticals'])
        : 0;
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
  Future<void> resolveWingCriticalDamage(
    Map<String, dynamic> request, {
    required int hpLost,
    required bool critical,
    int? fallRoll,
  }) async {
    final part = '${request['targetBodyPart'] ?? ''}';
    if (hpLost <= 0 ||
        !critical ||
        criticalShieldBlocksDebuffs(request) ||
        !part.startsWith('wings')) {
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
    if (damagedWingIds.isEmpty) return;
    planarState.remove('damagedWings');
    invalidateDerivedDataCaches();
    aggiungiLog('[ALI] Riposo Lungo: ali ripristinate.');
  }
}
