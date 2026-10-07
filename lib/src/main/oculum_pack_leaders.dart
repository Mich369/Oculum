part of '../../main.dart';

bool oculumApplyPackLeaderPhase(
  Map<String, dynamic> sheet, {
  required int maximumHp,
  Map<String, int>? statTotals,
}) {
  final source = '${sheet['monsterBookSourceId'] ?? ''}';
  final hp = readIntValue(sheet['currentHp']);
  if (!source.startsWith('pack_leader_') ||
      readBoolValue(sheet['packLeaderPhaseTriggered']) ||
      maximumHp <= 0 ||
      hp <= 0 ||
      hp * 2 > maximumHp) {
    return false;
  }
  sheet['packLeaderPhaseTriggered'] = true;
  sheet['packLeaderPhaseBaseMaxHp'] = maximumHp;
  sheet['scudo'] = '${readIntValue(sheet['scudo']) + (maximumHp / 10).ceil()}';
  final effects = [
    for (final effect in sheet['activeStructuredEffects'] as List? ?? const [])
      if (effect is Map) Map<String, dynamic>.from(effect),
  ];
  final alreadyVital = (sheet['conditions'] as List? ?? const [])
      .whereType<Map>()
      .any((condition) => condition['conditionType'] == 'ricordo_vitale');
  sheet['currentHp'] =
      '${alreadyVital ? hp : min(maximumHp, hp + (maximumHp * .75).ceil())}';
  final alreadyBoosted = effects.any(
    (effect) => const [
      'Stato di Forza: 200%',
      'Capobranco: 200%',
    ].contains(effect['source']),
  );
  for (final stat in ['resilienza', 'volonta', 'materia', 'oculum']) {
    if (alreadyBoosted) continue;
    effects.add({
      'source': 'Capobranco: 200%',
      'target': stat,
      'type': 'bonus',
      'value': max(0, statTotals?[stat] ?? readIntValue(sheet[stat])),
      'remaining': 3,
      'unit': 'turni',
    });
  }
  effects.add({
    'source': 'Capobranco: Ricordo vitale',
    'target': 'durata_stato',
    'type': 'bonus',
    'value': 0,
    'remaining': 9,
    'unit': 'turni',
  });
  sheet['activeStructuredEffects'] = effects;
  final conditions = [
    for (final condition in sheet['conditions'] as List? ?? const [])
      if (condition is Map) Map<String, dynamic>.from(condition),
  ];
  if (!conditions.any(
    (condition) => condition['conditionType'] == 'ricordo_vitale',
  )) {
    conditions.add(
      OculumConditionInstance(
        id: 'pack_leader_vital_memory',
        conditionType: 'ricordo_vitale',
        category: OculumConditionCategory.special,
        duration: 9,
        source: 'Capobranco: Ricordo vitale',
      ).toJson(),
    );
  }
  sheet['conditions'] = conditions;
  final message =
      'Capobranco: fase a metà Vita attivata una sola volta. Ricordo vitale: cura fino a $maximumHp HP e durata 9 turni; 200%: 3 turni; Scudo +${(maximumHp / 10).ceil()} (10% di $maximumHp).';
  sheet['logEventi'] = [...(sheet['logEventi'] as List? ?? const []), message];
  return true;
}

extension _OculumPackLeaders on _OculumHomePageState {
  bool applicaFaseCapobrancoSeServe() {
    if (schedaCorrente < 0 || schedaCorrente >= schedePersonaggio.length) {
      return false;
    }
    final sheet = schedePersonaggio[schedaCorrente];
    if (!'${sheet['monsterBookSourceId'] ?? ''}'.startsWith('pack_leader_') ||
        readBoolValue(sheet['packLeaderPhaseTriggered'])) {
      return false;
    }
    final data = {...schedePersonaggio[schedaCorrente], ...statoCorrenteJson()};
    final applied = oculumApplyPackLeaderPhase(
      data,
      maximumHp: maxHp(),
      statTotals: {
        'resilienza': resilienzaTotale(),
        'volonta': volontaTotale(),
        'materia': materiaTotale(),
        'oculum': oculumTotale(),
      },
    );
    if (!applied) return false;
    schedePersonaggio[schedaCorrente]['packLeaderPhaseTriggered'] = true;
    schedePersonaggio[schedaCorrente]['packLeaderPhaseBaseMaxHp'] =
        data['packLeaderPhaseBaseMaxHp'];
    currentHpController.text = '${data['currentHp']}';
    scudoController.text = '${data['scudo']}';
    activeStructuredEffects
      ..clear()
      ..addAll(
        (data['activeStructuredEffects'] as List).cast<Map<String, dynamic>>(),
      );
    activeConditions
      ..clear()
      ..addAll(
        (data['conditions'] as List).map(
          (condition) => OculumConditionInstance.fromJson(
            Map<String, dynamic>.from(condition as Map),
          ),
        ),
      );
    aggiungiLog('${(data['logEventi'] as List).last}');
    invalidateDerivedDataCaches();
    notifyConditionsChanged();
    programmaSalvataggio();
    return true;
  }
}
