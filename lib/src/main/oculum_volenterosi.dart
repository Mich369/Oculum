part of '../../main.dart';

extension _OculumVolenterosi on _OculumHomePageState {
  bool isVolenterosiTransformationAnchor(OculumStructuredEffect effect) =>
      effect.recipient == 'se_stesso' &&
      effect.type == 'planar' &&
      normalizedStructuredTarget(effect.target) ==
          oculumVolenterosiTransformation;

  bool isVolenterosiTransformationStat(OculumStructuredEffect effect) =>
      effect.recipient == 'se_stesso' &&
      effect.type == 'modifica_statistica' &&
      const {'volonta', 'materia'}.contains(
        normalizedStructuredTarget(effect.target),
      );

  int volenterosiAttackWillBonus() {
    if (schedaCorrente < 0 || schedaCorrente >= schedePersonaggio.length) {
      return 0;
    }
    if (schedePersonaggio[schedaCorrente]['monsterBookSourceId'] !=
        oculumVolenterosiId) {
      return 0;
    }
    return currentStatWithRuntimeBuffs('volonta', currentVolonta());
  }

  Map<String, dynamic>? get _volenterosiShield => activeStructuredEffects
      .where(
        (effect) =>
            effect['volenterosiTransformation'] == true &&
            effect['target'] == oculumVolenterosiTransformation &&
            readIntValue(effect['remaining']) > 0,
      )
      .firstOrNull;

  int get volenterosiShieldRemaining =>
      max(0, readIntValue(_volenterosiShield?['value']));

  void grantVolenterosiShield({
    required String effectId,
    required String source,
    required int value,
    required int turns,
  }) {
    if (value <= 0 || turns <= 0) return;
    activeStructuredEffects.add({
      'volenterosiTransformation': true,
      'effectId': effectId,
      'source': source,
      'type': 'planar',
      'mode': 'finche_attivo',
      'target': oculumVolenterosiTransformation,
      'value': value,
      'remaining': turns,
      'unit': 'turni',
    });
    clearNormalShieldBreakPenaltyIfProtected();
  }

  int normalShieldTargetAfterVolenterosi(int target) {
    final effect = _volenterosiShield;
    if (effect == null) return target;
    final before = max(0, readIntValue(effect['value']));
    final combinedShield = scudo() - posteaTransformShieldRemaining;
    final spent = min(before, max(0, combinedShield - target));
    final remaining = before - spent;
    effect['value'] = remaining;
    return max(0, target - remaining);
  }

  void clearVolenterosiTransformation() {
    activeStructuredEffects.removeWhere(
      (effect) => effect['volenterosiTransformation'] == true,
    );
  }
}
