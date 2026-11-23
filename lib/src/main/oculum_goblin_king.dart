part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

bool _isGoblinRoyalGuard(Map<dynamic, dynamic> data) =>
    data['isSummon'] == true && data['summonKind'] == oculumGoblinGuardianKind;

extension _OculumGoblinKing on _OculumHomePageState {
  int _pendingGoblinTechnique(String target) {
    if (!currentCombatIsActive() || outsideFight) return 0;
    final encounterId = onlineCombatEncounterId;
    final fightId = _summonFightKey(sheetTagAt(schedaCorrente));
    return activeStructuredEffects
        .where(
          (effect) =>
              effect['target'] == target &&
              effect['goblinPreparedEncounterId'] == encounterId &&
              effect['goblinPreparedFightId'] == fightId,
        )
        .fold(0, (sum, effect) => sum + readIntValue(effect['value']));
  }

  int get pendingGoblinVanish =>
      _pendingGoblinTechnique(oculumGoblinVanishEffect);
  int get pendingGoblinRegalStrike =>
      _pendingGoblinTechnique(oculumGoblinRegalStrikeEffect);

  bool get goblinRoyalGuardActiveSheet =>
      schedaCorrente >= 0 &&
      schedaCorrente < schedePersonaggio.length &&
      _isGoblinRoyalGuard(schedePersonaggio[schedaCorrente]);

  void expireGoblinRoyalGuards(String encounterId) {
    if (encounterId.isEmpty) return;
    activeStructuredEffects.removeWhere(
      (effect) => effect['goblinPreparedEncounterId'] == encounterId,
    );
    for (var index = 0; index < schedePersonaggio.length; index++) {
      final sheet = schedePersonaggio[index];
      final effects = sheet['activeStructuredEffects'];
      if (effects is List) {
        sheet['activeStructuredEffects'] = [
          for (final effect in effects)
            if (effect is! Map ||
                effect['goblinPreparedEncounterId'] != encounterId)
              effect,
        ];
      }
      if (!_isGoblinRoyalGuard(sheet) ||
          sheet['summonEncounterId'] != encounterId ||
          sheet['summonExpired'] == true) {
        continue;
      }
      sheet['summonExpired'] = true;
      setMasterEnemyLayerValue(index, 'currentHp', 0);
      for (final token in masterInitiativeTokens.where(
        (token) => combatTokenMatchesSheet(token, sheetTagAt(index)),
      )) {
        token['status'] = 'expired';
        token['summonExpired'] = true;
        token['currentHp'] = 0;
      }
    }
  }

  void goblinVanishBehind(String source, String target) {
    final actor = faunaMapToken(source);
    final victim = faunaMapToken(target);
    if (actor == null || victim == null || !canManageLocalMapToken(actor)) {
      return;
    }
    final width = max(1.0, mapWidthMetersValue());
    final height = max(1.0, mapHeightMetersValue());
    final targetX = localMapTokenAxis(victim, 'x');
    final targetY = localMapTokenAxis(victim, 'y');
    final approach = Offset(
      (targetX - localMapTokenAxis(actor, 'x')) * width,
      (targetY - localMapTokenAxis(actor, 'y')) * height,
    );
    final direction = approach.distance == 0
        ? const Offset(1, 0)
        : approach / approach.distance;
    actor['x'] = (targetX + direction.dx / width).clamp(0.0, 1.0);
    actor['y'] = (targetY + direction.dy / height).clamp(0.0, 1.0);
    vttCanvasRevision.value++;
    if (modalitaMaster) {
      unawaited(sendAuthoritativeVttTokenPosition(actor));
    } else {
      unawaited(sendRealtimeVttTokenPosition(actor));
    }
  }

  bool createGoblinRoyalGuard({required int form, required String source}) {
    if (form <= 0 || !currentCombatIsActive() || outsideFight) return false;
    final level = max(0, leggiNumero(livelloController));
    final grade = max(0, leggiNumero(gradoController));
    final stats = oculumGoblinGuardianStats(
      form: form,
      level: level,
      grade: grade,
    );
    final multiplier = oculumHpMultiplierForGrade(grade, level: level);
    final hp = stats.resilience * multiplier;
    final index = createShadowCloneSheet(
      hp: hp,
      duration: 1,
      source: source,
      displayName: 'Guardia di ${nomeSchedaPersonaggio(schedaCorrente)}',
      asSummon: true,
      summonKind: oculumGoblinGuardianKind,
      summonDescription:
          'Guardia goblin. Una sola Reazione per turno personale, dedicata a prendere un colpo al posto dell’evocatore.',
    );
    if (index < 0) return false;
    final sheet = schedePersonaggio[index];
    sheet
      ..['resilienza'] = '${stats.resilience}'
      ..['currentResilienza'] = '${stats.resilience}'
      ..['volonta'] = '${stats.will}'
      ..['currentVolonta'] = '${stats.will}'
      ..['materia'] = '${stats.matter}'
      ..['currentMateria'] = '${stats.matter}'
      ..['oculum'] = '0'
      ..['currentOculum'] = '0'
      ..['normalCurrentOculum'] = '0'
      ..['temporaryOculum'] = '0'
      ..['temporaryOculumRollsRemaining'] = 0
      ..['maxOculum'] = '0'
      ..['manualHpMaximumAdjustment'] = 0
      ..['derivedMaxHp'] = hp
      ..['currentHp'] = '$hp';
    for (final key in const [
      'attaccoRapido',
      'vcRapido',
      'cmRapido',
      'difesaRapida',
      'hiddenEyeStats',
      'spriteAssetPath',
      'immaginePersonaggioBase64',
    ]) {
      sheet.remove(key);
    }
    programmaSalvataggio();
    return true;
  }

  Map<String, dynamic>? _goblinGuardForHit(Map<String, dynamic> request) {
    final king = '${request['targetTag'] ?? ''}';
    final source = '${request['sourceTag'] ?? ''}';
    final encounter = '${request['encounterId'] ?? ''}';
    if (king.isEmpty ||
        source.isEmpty ||
        encounter != onlineCombatEncounterId ||
        request['goblinGuardianIntercepted'] != null ||
        request['guardianSecondaryEvent'] == true ||
        oculumSameSheetIdentity(king, source)) {
      return null;
    }
    final tokens = _writableOnlineCombatTokens();
    final kingToken = tokens
        .where((t) => combatTokenMatchesSheet(t, king))
        .firstOrNull;
    if (kingToken == null || !masterInitiativeTokenCanAct(kingToken)) {
      return null;
    }
    final group = request['attackGroupId'] ?? request['id'];
    final otherTargets = onlineCombatRequests.values
        .where(
          (r) =>
              r['encounterId'] == encounter &&
              (r['attackGroupId'] ?? r['id']) == group,
        )
        .map((r) => '${r['targetTag'] ?? ''}');
    for (final token in tokens) {
      if (!_isGoblinRoyalGuard(token)) continue;
      final guard = onlineCombatTokenTag(token);
      final index = localSheetIndexForOculumTag(guard);
      if (guard.isEmpty || index < 0 || !controlsOnlineCombatSheet(guard)) {
        continue;
      }
      final sheet = schedePersonaggio[index];
      if (!oculumGoblinGuardianCanIntercept(
        summon: _isGoblinRoyalGuard(sheet),
        sameOwner: oculumSameSheetIdentity(sheet['summonerTag'], king),
        sameTeam: combatParticipantsShareTeam(token, kingToken),
        alive:
            sheetCurrentHpForDeathAt(index) > 0 &&
            masterInitiativeTokenCanAct(token),
        inFight:
            sheet['summonExpired'] != true &&
            sheet['summonFightInstanceId'] == _summonFightKey(king) &&
            token['outsideFight'] != true,
        targetedByAttack:
            oculumSameSheetIdentity(guard, source) ||
            otherTargets.any(
              (target) => oculumSameSheetIdentity(guard, target),
            ),
        normalReactionsRemaining: masterInitiativeNormalReactionRemaining(
          token,
        ),
      )) {
        continue;
      }
      if (artDebtForToken(token, 'reaction') > 0) continue;
      return token;
    }
    return null;
  }

  Future<bool> interceptWithGoblinRoyalGuard(
    Map<String, dynamic> request, {
    required int damage,
    required int defense,
    required String defenseChoice,
    required int defenseNatural,
    required bool critical,
    required bool doubleCritical,
    required bool wholePacket,
  }) async {
    if (damage <= 0 || hpCorrenti() <= 0) return false;
    final token = _goblinGuardForHit(request);
    if (token == null) return false;
    final guard = onlineCombatTokenTag(token);
    final king = sheetTagAt(schedaCorrente);
    final guardIndex = localSheetIndexForOculumTag(guard);
    final id = '${request['id']}';
    final round = readIntValue(
      token['reactionPoolRound'],
      fallback: _onlineCombatRound(),
    );
    token
      ..['reactionUsed'] = 1
      ..['reactionUsedRound'] = round
      ..['updatedAt'] = DateTime.now().toIso8601String();
    request
      ..['status'] = 'resolved'
      ..['goblinGuardianIntercepted'] = guard
      ..['goblinGuardianReactionRound'] = round;
    if (wholePacket) {
      request
        ..['outcome'] = OculumAttackOutcome.avoided.name
        ..['freeReaction'] = false
        ..['criticalReaction'] = false;
    }
    salvaSchedaCorrenteInMemoria();
    final global = catturaImpostazioniGlobali();
    try {
      schedaCorrente = guardIndex;
      caricaStatoDaJson(schedePersonaggio[guardIndex]);
      ripristinaImpostazioniGlobali(global);
      final previousElement = incomingDamageElement;
      incomingDamageElement = '${request['element'] ?? 'fisico'}';
      final friendlyFire = _friendlyFireFor({...request, 'targetTag': guard});
      try {
        await applicaDannoSubito(
          dannoEsplicito: damage,
          critico: critical,
          doubleCritical: doubleCritical,
          enemyLevel: readIntValue(request['level']),
          enemyGrade: readIntValue(request['grade']),
          magicalAttack: request['magicalAttack'] == true,
          allowPawnProtection: false,
          criticalBonusMultiplier: critical ? 2 : 1,
          criticalDamageBonusOverride: doubleCritical
              ? oculumDoubleCriticalDamageBonus(
                  readIntValue(request['level']),
                  readIntValue(request['grade']),
                )
              : null,
          friendlyFire: friendlyFire.friendly,
          friendlyFireResisted: friendlyFire.resisted,
          damagePacketId: '$id:goblin_guard:$guard',
        );
      } finally {
        incomingDamageElement = previousElement;
      }
      if (mounted && sheetTagAt(schedaCorrente) == guard) {
        salvaSchedaCorrenteInMemoria();
      }
    } finally {
      if (mounted && sheetTagAt(schedaCorrente) == guard) {
        final kingIndex = localSheetIndexForOculumTag(king);
        if (kingIndex >= 0) {
          schedaCorrente = kingIndex;
          caricaStatoDaJson(schedePersonaggio[kingIndex]);
          ripristinaImpostazioniGlobali(global);
        }
      }
    }
    if (!mounted ||
        sheetTagAt(schedaCorrente) != king ||
        request['encounterId'] != onlineCombatEncounterId) {
      return true;
    }
    syncMasterInitiativeTokenDeathFromSheet(guardIndex, participant: token);
    if (_usesLocalMasterInitiative) captureActiveMasterInitiativeGroup();
    aggiungiLog(
      '[GUARDIA REALE] ${nomeSchedaPersonaggio(guardIndex)} prende il colpo al posto del Re.',
    );
    sendRealtimeInitiativeSnapshotIfPublished();
    if (realtimeService?.isConnected == true) {
      unawaited(sendRealtimeSheetToStaffAt(guardIndex, force: true));
    }
    if (!wholePacket) return true;
    request['damageReceipt'] = const <String, int>{
      'hpLost': 0,
      'shieldLost': 0,
      'oculumShieldLost': 0,
      'temporaryHpLost': 0,
    };
    final reply = <String, dynamic>{
      ...request,
      'defense': defense,
      'defenseChoice': defenseChoice,
      'defenseNatural': defenseNatural,
    };
    attachPendingCombatTurnResources(reply);
    await salvaDatiSoloLocale();
    if (!mounted ||
        sheetTagAt(schedaCorrente) != king ||
        request['encounterId'] != onlineCombatEncounterId) {
      return true;
    }
    if (realtimeService?.isConnected == true) {
      await realtimeService?.sendCombatEvent(
        'combat_defense',
        permissionEnvelope(reply),
      );
    }
    advanceMaskedVolley(request, defenseNatural, defense);
    if (mounted) setState(() {});
    return true;
  }
}
