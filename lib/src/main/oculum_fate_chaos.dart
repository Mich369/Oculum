part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

/// Exactly one percentile draw per newly reached grade. Zero-based input.
Map<String, int> oculumFateGradeReward(int percentile, {int currentHp = 0}) {
  final roll = percentile.clamp(0, 99);
  if (roll < 6) return {};
  if (roll < 20) return {'ispirazioni': 1};
  final result = {'ispirazioni': 1, 'superIspirazioni': 1};
  if (roll >= 50) result['ispirazioniOculum'] = 1;
  if (roll >= 90) result['schivateOculumBonus'] = 1;
  if (roll == 99) {
    final shield = (max(0, currentHp) / 5).ceil();
    result['scudo'] = shield;
    result['scudoOculum'] = (shield / 4).ceil();
  }
  return result;
}

extension _OculumFateChaos on _OculumHomePageState {
  bool get identityIsChaos => planarState['identityFateChaos'] == 'Chaos';

  Widget fateChaosIdentityEditor() => DropdownButtonFormField<String>(
    key: ValueKey('fate_chaos_${currentSheetScrollId()}'),
    initialValue: identityIsChaos ? 'Chaos' : 'Fato',
    decoration: const InputDecoration(labelText: 'Fato / Chaos'),
    items: const [
      DropdownMenuItem(value: 'Fato', child: Text('Fato')),
      DropdownMenuItem(value: 'Chaos', child: Text('Chaos')),
    ],
    onChanged: (value) {
      if (value == null) return;
      setState(() {
        // Choosing an identity never grants historical grade rewards.
        planarState.putIfAbsent(
          'identityRewardMaxGrade',
          () => activeCriticalGrade(),
        );
        planarState['identityFateChaos'] = value;
        planarState.remove('chaosStats');
        if (value == 'Chaos' && currentCombatIsActive()) refreshChaosStats();
        invalidateDerivedDataCaches();
      });
      programmaSalvataggio();
    },
  );

  void rewardIdentityGrades(int previous, int next, {int? percentile}) {
    final claimed = max(
      previous,
      readIntValue(planarState['identityRewardMaxGrade'], fallback: previous),
    );
    if (next <= claimed) return;
    // Claim before granting: switching identities or lowering grade cannot repeat.
    planarState['identityRewardMaxGrade'] = next;
    if (identityIsChaos) return;
    for (var grade = claimed + 1; grade <= next; grade++) {
      final roll = percentile ?? Random.secure().nextInt(100);
      final reward = oculumFateGradeReward(roll, currentHp: hpCorrenti());
      ispirazioniController.text =
          '${leggiNumero(ispirazioniController) + (reward['ispirazioni'] ?? 0)}';
      superIspirazioniController.text =
          '${leggiNumero(superIspirazioniController) + (reward['superIspirazioni'] ?? 0)}';
      ispirazioniOculumController.text =
          '${leggiNumero(ispirazioniOculumController) + (reward['ispirazioniOculum'] ?? 0)}';
      schivateOculumBonus += reward['schivateOculumBonus'] ?? 0;
      scudoController.text =
          '${leggiNumero(scudoController) + (reward['scudo'] ?? 0)}';
      final oculumShield = reward['scudoOculum'] ?? 0;
      if (oculumShield > 0) {
        scudoOculumMaxController.text =
            '${leggiNumero(scudoOculumMaxController) + oculumShield}';
        scudoOculumController.text =
            '${leggiNumero(scudoOculumController) + oculumShield}';
      }
      final description = reward.entries
          .map((e) => '+${e.value} ${e.key}')
          .join(', ');
      aggiungiLog(
        '[FATO] Grado $grade · ${roll + 1}/100: ${description.isEmpty ? 'nessun premio' : description}.',
      );
    }
    programmaSalvataggio();
  }

  void synchronizeIdentityCombat(String encounterKey) {
    if (!identityIsChaos || planarState['chaosEncounter'] == encounterKey) {
      return;
    }
    planarState['chaosEncounter'] = encounterKey;
    planarState.remove('chaosProcAttempts');
    refreshChaosStats();
  }

  void refreshChaosStats({List<int>? values}) {
    if (!identityIsChaos) return;
    final random = Random.secure();
    final stats = <String, int>{};
    for (final (i, key) in const [
      'resilienza',
      'volonta',
      'materia',
      'oculum',
    ].indexed) {
      stats[key] = (values == null ? random.nextInt(7) - 3 : values[i]).clamp(
        -3,
        3,
      );
    }
    planarState['chaosStats'] = stats;
    planarState.remove('chaosProcAttempts');
    invalidateDerivedDataCaches();
    aggiungiLog(
      '[CHAOS] ${stats.entries.map((e) => '${e.key} ${e.value >= 0 ? '+' : ''}${e.value}').join(' · ')} fino al prossimo tuo turno.',
    );
  }

  int chaosStatBonus(String stat) => identityIsChaos && currentCombatIsActive()
      ? readIntValue((planarState['chaosStats'] as Map? ?? {})[stat])
      : 0;

  bool rollChaosProc(String opponent, {int? percentile}) {
    if (!identityIsChaos || !currentCombatIsActive()) return false;
    final attempts = Map<String, dynamic>.from(
      planarState['chaosProcAttempts'] as Map? ?? {},
    );
    if (attempts.containsKey(opponent)) return false;
    final roll = percentile ?? Random.secure().nextInt(100);
    attempts[opponent] = roll;
    planarState['chaosProcAttempts'] = attempts;
    return roll < 25;
  }

  void applyChaosPenaltyToOwnedSheet(
    String target,
    String source,
    String receipt,
  ) {
    if (!controlsOnlineCombatSheet(target)) return;
    final index = localSheetIndexForOculumTag(target);
    if (index < 0) return;
    final original = schedaCorrente;
    salvaSchedaCorrenteInMemoria();
    final global = catturaImpostazioniGlobali();
    try {
      if (index != original) {
        schedaCorrente = index;
        caricaStatoDaJson(schedePersonaggio[index]);
        ripristinaImpostazioniGlobali(global);
      }
      final seen = (planarState['chaosPenaltyReceipts'] as List? ?? [])
          .map((v) => '$v')
          .toSet();
      if (seen.contains(receipt)) return;
      seen.add(receipt);
      planarState['chaosPenaltyReceipts'] = seen.toList();
      applyCondition('chaos_svantaggio', duration: 1, source: source);
      aggiungiLog('[CHAOS] $source: −3 a tutti i tiri per 1 turno.');
      salvaSchedaCorrenteInMemoria();
    } finally {
      if (index != original && mounted) {
        schedaCorrente = original;
        caricaStatoDaJson(schedePersonaggio[original]);
        ripristinaImpostazioniGlobali(global);
      }
    }
    programmaSalvataggio();
  }

  void applyChaosPenaltyGroup(
    Map<String, dynamic> request, {
    required bool attackingSide,
    required String source,
    required String receipt,
  }) {
    final target = '${request[attackingSide ? 'sourceTag' : 'targetTag']}';
    final helpers =
        request[attackingSide ? 'sourceHelpers' : 'defenseHelpers'] as List? ??
        [];
    final allowed = {
      ...onlineCombatTokens().map(onlineCombatTokenTag),
      for (var i = 0; i < schedePersonaggio.length; i++) sheetTagAt(i),
    };
    for (final tag in {target, ...helpers.take(30).map((v) => '$v')}) {
      if (allowed.contains(tag)) {
        applyChaosPenaltyToOwnedSheet(tag, source, '$receipt:$tag');
      }
    }
  }

  void resolveChaosIncomingAttack(
    Map<String, dynamic> request,
    OculumAttackOutcome outcome,
  ) {
    final source = '${request['sourceTag']}';
    final target = '${request['targetTag']}';
    if (outcome == OculumAttackOutcome.avoided) {
      request['chaosDefensePenalty'] = rollChaosProc(source);
      if (request['chaosDefensePenalty'] == true) {
        applyChaosPenaltyGroup(
          request,
          attackingSide: true,
          source: realtimeDisplayName(),
          receipt: 'defense:${request['id']}',
        );
      }
    } else if (request['sourceChaos'] == true) {
      // The target owner resolves the source's saved roll once per opponent/turn.
      final receipt = '${request['chaosTurn']}:$source:$target';
      final seen = (planarState['chaosAttackAttempts'] as List? ?? [])
          .map((v) => '$v')
          .toSet();
      if (seen.add(receipt)) {
        planarState['chaosAttackAttempts'] = seen.toList();
        if (readIntValue(request['chaosPercentile'], fallback: 99) < 25) {
          request['chaosAttackPenalty'] = true;
          applyChaosPenaltyGroup(
            request,
            attackingSide: false,
            source: '${request['sourceName']}',
            receipt: 'attack:$receipt',
          );
        }
      }
    }
  }
}
