part of '../../main.dart';

String? oculumChaosInspirationType(int percentile) {
  RangeError.checkValueInInterval(percentile, 0, 99, 'percentile');
  return switch (percentile) {
    < 20 => null,
    < 70 => 'base',
    < 90 => 'super',
    _ => 'oculum',
  };
}

int oculumChaosInspirationIntervals(int now, int anchor) =>
    max(0, now - anchor) ~/ oculumWorldDaySeconds;

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

const _opposingChaosStats = ['resilienza', 'volonta', 'materia', 'oculum'];
final _withoutOpposingChaos = Expando<bool>();

Map<String, int> oculumOpposingChaosStatRoll(int Function(int) nextInt) => {
  for (final stat in _opposingChaosStats) stat: nextInt(11) - 5,
};

extension _OculumOpposingChaos on _OculumHomePageState {
  String fightMonsterElement(Map<String, dynamic> token, {int? sheetIndex}) {
    return oculumNormalizeElementId(
      oculumSavedMonsterBookEntryById(
            monsterBookIdForCombatToken(token, sheetIndex: sheetIndex),
          )?.elementId ??
          '${token['element'] ?? ''}',
    );
  }

  bool _differentFightSides(
    Map<String, dynamic> combatant,
    Map<String, dynamic> source,
  ) =>
      !combatParticipantsShareTeam(combatant, source) &&
      publicInitiativeSourceTag(combatant) != publicInitiativeSourceTag(source);

  bool _presentForElementalInfluence(Map<String, dynamic> token) =>
      token['outsideFight'] != true &&
      token['temporaryTurn'] != true &&
      token['duplicateAction'] != true &&
      !const {'dead', 'fled', 'expired'}.contains(token['status']);

  void refreshOpposingChaosTurn(
    Map<String, dynamic> token, {
    required String fightInstanceId,
    int Function(Map<String, dynamic>)? sheetIndexForToken,
  }) {
    if (!_presentForElementalInfluence(token)) return;
    final receipt = '$fightInstanceId:$masterInitiativeRound';
    if (token['opposingChaosTurn'] == receipt) return;
    token['opposingChaosTurn'] = receipt;
    if (!masterInitiativeTokens.any(
      (source) =>
          _presentForElementalInfluence(source) &&
          _differentFightSides(token, source) &&
          fightMonsterElement(
                source,
                sheetIndex: sheetIndexForToken?.call(source),
              ) ==
              'caos',
    )) {
      if (token.remove('opposingChaosStats') != null) {
        invalidateDerivedDataCaches();
      }
      return;
    }
    final stats = oculumOpposingChaosStatRoll(Random.secure().nextInt);
    token['opposingChaosStats'] = stats;
    invalidateDerivedDataCaches();
    combatLogFor(
      publicInitiativeSourceTag(token),
      '[CHAOS] ${stats.entries.map((e) => '${e.key} ${e.value >= 0 ? '+' : ''}${e.value}').join(' · ')}',
    );
  }

  Map? _opposingChaosForCurrentSheet() {
    if (_withoutOpposingChaos[this] == true) return null;
    final encounter = referenceTurnEncounter();
    if (encounter['combatEnded'] == true ||
        encounter['fightStarted'] == false) {
      return null;
    }
    final raw = encounter['tokens'];
    if (raw is! List) return null;
    final tag = sheetTagAt(schedaCorrente);
    for (final token in raw.whereType<Map<String, dynamic>>()) {
      if (!_presentForElementalInfluence(token) ||
          !combatTokenMatchesSheet(token, tag)) {
        continue;
      }
      final stats = token['opposingChaosStats'];
      if (stats is Map) return stats;
    }
    return null;
  }

  int opposingChaosModifier(String stat) =>
      readIntValue(_opposingChaosForCurrentSheet()?[stat]).clamp(-5, 5);

  // The Fight token holds its temporary modifiers. Derived fields exported
  // with a sheet must not carry them into another encounter or an offline save.
  T captureSheetWithoutOpposingChaos<T>(T Function() capture) {
    if (_opposingChaosForCurrentSheet() == null) return capture();
    _withoutOpposingChaos[this] = true;
    invalidateDerivedDataCaches(notifyHiddenEyeCards: false);
    try {
      return capture();
    } finally {
      _withoutOpposingChaos[this] = null;
      invalidateDerivedDataCaches(notifyHiddenEyeCards: false);
    }
  }

  void markOblivionFightExposure({
    int Function(Map<String, dynamic>)? sheetIndexForToken,
  }) {
    late final localIndexes = buildFightRewardSheetIndexLookup(
      resolveSourceAlias: realtimeIsMasterRole || localTurnCombat,
    );
    final lookup = sheetIndexForToken ?? (token) => localIndexes(token);
    final present = masterInitiativeTokens
        .where(_presentForElementalInfluence)
        .toList(growable: false);
    final oblivionSides = {
      for (final source in present)
        if (fightMonsterElement(source, sheetIndex: lookup(source)) == 'oblio')
          combatParticipantTeamId(source),
    };
    if (oblivionSides.isEmpty) return;
    for (final token in present) {
      if (oblivionSides.any((side) => side != combatParticipantTeamId(token))) {
        token['opposingOblivionExposed'] = true;
      }
    }
  }

  List<String> oblivionFightParticipants() {
    markOblivionFightExposure();
    return {
      for (final token in masterInitiativeTokens)
        if (token['opposingOblivionExposed'] == true &&
            token['temporaryTurn'] != true &&
            token['duplicateAction'] != true)
          publicInitiativeSourceTag(token),
    }.where((tag) => tag.isNotEmpty).toList();
  }

  String _oblivionFightKey(String campaign, String instance) =>
      jsonEncode([campaign, instance]);

  void recordOblivionArmorPain() {
    final context = currentCombatSubtraitExperienceContext();
    if (context == null) return;
    final key = _oblivionFightKey(
      permissionCampaignId,
      context['fightInstanceId'] as String,
    );
    final receipts = <String>{
      ...(planarState['oblivionArmorPain'] as List? ?? const [])
          .whereType<String>(),
      key,
    };
    planarState['oblivionArmorPain'] = receipts
        .toList()
        .reversed
        .take(64)
        .toList()
        .reversed
        .toList();
  }

  void receiveOblivionFightEnd(Map reward, {String? campaignId}) {
    final participants = reward['oblivionFightParticipants'];
    if (participants is! Map || '${reward['endedEncounterId'] ?? ''}'.isEmpty) {
      return;
    }
    var changed = false;
    for (final entry in participants.entries) {
      final tag = entry.key;
      final instance = entry.value;
      if (tag is! String || instance is! String || instance.isEmpty) continue;
      final key = _oblivionFightKey(
        campaignId ?? permissionCampaignId,
        instance,
      );
      if (!controlsOnlineCombatSheet(tag)) continue;
      final index = localSheetIndexForOculumTag(tag);
      if (index < 0) continue;
      final sheet = schedePersonaggio[index];
      final runtime = index == schedaCorrente
          ? planarState
          : Map<String, dynamic>.from(
              sheet['planarRuntime'] as Map? ?? const {},
            );
      final receipts = <String>{
        ...(runtime['oblivionFightEndReceipts'] as List? ?? const [])
            .whereType<String>(),
      };
      if (!receipts.add(key)) continue;
      runtime['oblivionFightEndReceipts'] = receipts.toList();
      final pain = (runtime['oblivionArmorPain'] as List? ?? const [])
          .whereType<String>()
          .toSet();
      final hurt = pain.remove(key);
      runtime['oblivionArmorPain'] = pain.toList();
      if (index != schedaCorrente) sheet['planarRuntime'] = runtime;
      combatLogFor(
        tag,
        hurt ? 'non ricordo nulla, perché sento dolore?' : 'non ricordi nulla',
      );
      changed = true;
    }
    if (changed) programmaSalvataggio(invalidateCaches: false);
  }

  // This is the value used by rolls and derived subtalents. oculumTotale()
  // remains the spendable pool used by costs, refills and the resource bar.
  int oculumCombatStatTotal() {
    final available = oculumTotale();
    if (oculumAddormentato || isMeccanio || isThunderBot) return available;
    return max(0, available + opposingChaosModifier('oculum'));
  }
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
        final progress = worldNeedsData;
        if (value == 'Chaos') {
          progress['chaosInspirationAt'] = worldClockSeconds;
        } else {
          progress.remove('chaosInspirationAt');
        }
        worldNeedsCampaigns[worldNeedsCampaignKey] = progress;
        planarState.remove('chaosStats');
        if (value == 'Chaos' && currentCombatIsActive()) refreshChaosStats();
        invalidateDerivedDataCaches();
      });
      programmaSalvataggio();
    },
  );

  bool syncChaosInspiration(Map<String, dynamic> progress, int now) {
    if (!identityIsChaos) return false;
    final saved = progress['chaosInspirationAt'];
    if (saved == null) {
      progress['chaosInspirationAt'] = now;
      return false;
    }
    final anchor = readIntValue(saved);
    final intervals = oculumChaosInspirationIntervals(now, anchor);
    if (intervals == 0) return false;
    progress['chaosInspirationAt'] = anchor + intervals * oculumWorldDaySeconds;
    final messages = <String>[];
    final random = Random.secure();
    for (var interval = 0; interval < intervals; interval++) {
      final type = oculumChaosInspirationType(random.nextInt(100));
      if (type != null) grantInspirationWithCap(type, 1, messages);
    }
    aggiungiLog(
      '[Chaos] ${messages.isEmpty ? t('Nessuna Ispirazione.', 'No Inspiration.') : messages.join(' · ')}',
    );
    return true;
  }

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
