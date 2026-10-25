part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

bool oculumBrambleHeatBypasses(String element) => const {
  'fuoco',
  'lava',
  'plasma',
}.contains(oculumNormalizeElementId(element));

bool oculumBrambleMelee(Map<String, dynamic> attack) {
  if (attack['melee'] is bool) return attack['melee'] == true;
  if (attack['ranged'] == true) return false;
  return const {
    'vc',
    'schianto',
    'forza',
    'corpo_a_corpo',
  }.contains(attack['choice']);
}

String oculumBrambleChallengeMatch(double multiplier) => !multiplier.isFinite
    ? ''
    : multiplier > 0 && multiplier < 1
    ? 'resistenza'
    : multiplier > 1
    ? 'fragilita'
    : '';

extension _OculumBramble on _OculumHomePageState {
  OculumStructuredEffect? get brambleChallengeDefinition {
    for (final effects in [
      for (final skill in skills.where((s) => s.equipaggiata && s.passiva))
        for (final form in skill.forme) form.effettiStrutturati,
      for (final art in arti)
        for (final skill in art.skills) skill.effettiEvoluzione(1),
    ]) {
      for (final effect in effects) {
        if (effect.type == 'planar' &&
            effect.target == 'bramble_arduous_challenge') {
          return effect;
        }
      }
    }
    return null;
  }

  int brambleAbsorbDamage(
    int damage,
    String element, {
    bool bypassShields = false,
  }) {
    if (damage <= 0 ||
        bypassShields ||
        oculumBrambleHeatBypasses(element) ||
        readIntValue(planarState['brambleShieldTurns']) <= 0) {
      return damage;
    }
    final absorbed = min(
      damage,
      max(0, readIntValue(planarState['brambleShield'])),
    );
    if (absorbed == 0) return damage;
    planarState['brambleShield'] =
        readIntValue(planarState['brambleShield']) - absorbed;
    aggiungiLog(
      '[ROVI] Assorbiti $absorbed Danni; barriera ${planarState['brambleShield']}.',
    );
    return damage - absorbed;
  }

  bool claimBrambleChallenge(Map<String, dynamic> request) {
    final definition = brambleChallengeDefinition;
    if (definition == null ||
        !(readIntValue(request['natural']) >= 20 ||
            request['forcedCritical'] == true ||
            oculumAttackIsCritical(
              readIntValue(request['attack']),
              readIntValue(request['defense']),
            ))) {
      return false;
    }
    final multiplier = request['brambleTargetMultiplier'];
    if (multiplier is! num) return false;
    final match = oculumBrambleChallengeMatch(multiplier.toDouble());
    final id = '${request['attackGroupId'] ?? request['id'] ?? ''}';
    if (match.isEmpty || id.isEmpty) return false;
    final seen = (planarState['brambleChallengeReceipts'] as List? ?? [])
        .map((e) => '$e')
        .toSet();
    if (!seen.add('$id:$match')) return false;
    planarState['brambleChallengeReceipts'] = seen.toList();
    if (match == 'resistenza') {
      final amount = max(
        0,
        readIntValue(definition.valueExpression, fallback: 1),
      );
      for (final stat in ['resilienza', 'oculum']) {
        final effectId = 'bramble_challenge_$stat';
        final previous = activeStructuredEffects
            .where((e) => e['effectId'] == effectId)
            .firstOrNull;
        final total = readIntValue(previous?['value']) + amount;
        activeStructuredEffects.removeWhere((e) => e['effectId'] == effectId);
        activeStructuredEffects.add({
          'effectId': effectId,
          'source': 'Sfida Ardua',
          'type': 'modifica_statistica',
          'target': stat,
          'value': total,
          'mode': 'finche_attivo',
          'remaining': -1,
          'unit': 'turni',
        });
      }
      aggiungiLog(
        '[SFIDA ARDUA] Critico contro Resistenza: +$amount Oculum e +$amount Resilienza fino a fine scontro.',
      );
    } else {
      final existing = getCondition('ricordo_vitale');
      if (existing?.durationType != OculumConditionDurationType.permanent) {
        applyCondition(
          'ricordo_vitale',
          duration: max(1, readIntValue(definition.duration, fallback: 6)),
          durationType: OculumConditionDurationType.turns,
          source: 'Sfida Ardua',
        );
      }
      aggiungiLog(
        '[SFIDA ARDUA] Critico contro Fragilità: Ricordo Vitale per ${max(1, readIntValue(definition.duration, fallback: 6))} turni.',
      );
    }
    invalidateDerivedDataCaches();
    programmaSalvataggio(invalidateCaches: false);
    return true;
  }

  void claimBrambleChallengeForSource(Map<String, dynamic> request) {
    final tag = '${request['sourceTag']}';
    if (!controlsOnlineCombatSheet(tag)) return;
    final index = localSheetIndexForOculumTag(tag);
    if (index < 0) return;
    final original = schedaCorrente;
    if (index == original) {
      claimBrambleChallenge(request);
      return;
    }
    salvaSchedaCorrenteInMemoria();
    final global = catturaImpostazioniGlobali();
    try {
      schedaCorrente = index;
      caricaStatoDaJson(schedePersonaggio[index]);
      ripristinaImpostazioniGlobali(global);
      if (claimBrambleChallenge(request)) salvaSchedaCorrenteInMemoria();
    } finally {
      schedaCorrente = original;
      caricaStatoDaJson(schedePersonaggio[original]);
      ripristinaImpostazioniGlobali(global);
    }
  }

  void resetBrambleFight() {
    activeStructuredEffects.removeWhere(
      (e) => '${e['effectId']}'.startsWith('bramble_challenge_'),
    );
    for (final key in [
      'brambleShield',
      'brambleShieldTurns',
      'brambleRetaliation',
      'brambleChallengeReceipts',
    ]) {
      planarState.remove(key);
    }
    final floor = currentOculumRuntimeFloor();
    if (currentOculum() < floor) currentOculumController.text = '$floor';
  }
}
