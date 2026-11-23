part of '../../main.dart';

bool _isMutantRatPup(Map<dynamic, dynamic> data) =>
    data['isSummon'] == true && data['summonKind'] == oculumMutantRatPup;

bool _isMutantRatBite(Map<dynamic, dynamic> data) =>
    data['mutantRatBite'] == true && data['kind'] == 'fauna_burst';

extension _OculumMutantRat on _OculumHomePageState {
  bool get _resolvesMutantRatTurns =>
      realtimeService?.isConnected != true || realtimeIsMasterRole;

  bool get mutantRatPupActiveSheet =>
      schedaCorrente >= 0 &&
      schedaCorrente < schedePersonaggio.length &&
      _isMutantRatPup(schedePersonaggio[schedaCorrente]);

  int createMutantRatPups({required int count, required String source}) {
    if (!currentCombatIsActive() || outsideFight) return 0;
    final ownerTag = sheetTagAt(schedaCorrente);
    if (!onlineCombatTokens().any(
      (token) => combatTokenMatchesSheet(token, ownerTag),
    )) {
      return 0;
    }
    final side = sheetSideAt(schedaCorrente);
    var created = 0;
    for (var i = 0; i < count.clamp(0, 100); i++) {
      final index = createShadowCloneSheet(
        hp: oculumMutantRatPupHp,
        duration: 1,
        source: source,
        displayName: 'Topolino dagli occhi verdi',
        asSummon: true,
        summonKind: oculumMutantRatPup,
        summonDescription:
            'Topolino con quattro zampe, due occhi verdi, due orecchie e una coda. Ha 1 Vita. Al proprio turno morde automaticamente con la sola Reazione e scompare.',
      );
      if (index < 0) break;
      final sheet = schedePersonaggio[index];
      sheet['masterSideOverride'] = side;
      for (final key in const [
        'volonta',
        'currentVolonta',
        'materia',
        'currentMateria',
        'oculum',
        'currentOculum',
        'normalCurrentOculum',
        'temporaryOculum',
        'maxOculum',
      ]) {
        sheet[key] = '0';
      }
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
      sheet['temporaryOculumRollsRemaining'] = 0;
      sheet['precisionBodyParts'] = [
        {'id': 'body', 'group': 'body', 'label': 'Corpo'},
        {'id': 'head', 'group': 'head', 'label': 'Testa'},
        {
          'id': 'eyes_1',
          'group': 'eyes',
          'label': 'Occhio destro',
          'side': 'right',
        },
        {
          'id': 'eyes_2',
          'group': 'eyes',
          'label': 'Occhio sinistro',
          'side': 'left',
        },
        {
          'id': 'ears_1',
          'group': 'ears',
          'label': 'Orecchio destro',
          'side': 'right',
        },
        {
          'id': 'ears_2',
          'group': 'ears',
          'label': 'Orecchio sinistro',
          'side': 'left',
        },
        for (var i = 0; i < 4; i++)
          {'id': 'legs_${i + 1}', 'group': 'legs', 'label': 'Zampa ${i + 1}'},
        {'id': 'tail', 'group': 'tail', 'label': 'Coda'},
      ];
      created++;
    }
    if (created > 0) programmaSalvataggio();
    return created;
  }

  void recordMutantRatAttackAttempt(Map<String, dynamic> request) {
    if (!_resolvesMutantRatTurns ||
        request['scope'] != permissionScope ||
        request['encounterId'] != selectedMasterInitiativeGroupId ||
        request['status'] != 'pending' ||
        request['opposedRollDraft'] == true ||
        request['faunaBurst'] == true) {
      return;
    }
    final target = '${request['targetTag'] ?? ''}';
    final source = '${request['sourceTag'] ?? ''}';
    final id = '${request['id'] ?? ''}';
    if (source.isEmpty || target.isEmpty || id.isEmpty) return;
    final victim = masterInitiativeTokens
        .where((token) => combatTokenMatchesSheet(token, target))
        .firstOrNull;
    if (victim == null ||
        monsterBookIdForCombatToken(victim).split('_variante_').first !=
            oculumMutantRatId) {
      return;
    }
    final attacker = masterInitiativeTokens
        .where((token) => combatTokenMatchesSheet(token, source))
        .firstOrNull;
    if (attacker == null || !oculumShieldBreakCanTarget(victim, attacker)) {
      return;
    }
    final fight = _summonFightKey(target);
    if (victim['mutantRatAggressorFight'] != fight) {
      victim['mutantRatAggressorFight'] = fight;
      victim.remove('mutantRatAttackReceipts');
    }
    final seen = (victim['mutantRatAttackReceipts'] as List? ?? const [])
        .whereType<String>()
        .toList();
    if (seen.contains(id)) return;
    victim['mutantRatAttackReceipts'] = [
      ...seen.skip(max(0, seen.length - 199)),
      id,
    ];
    victim['mutantRatLastAggressor'] = source;
    captureActiveMasterInitiativeGroup();
    programmaSalvataggio();
  }

  String _mutantRatBiteId(String encounter, String instance) =>
      '$encounter:mutant-rat:$instance';

  bool validMutantRatBite(Map<String, dynamic> request) {
    final encounter = '${request['encounterId'] ?? ''}';
    final expectedEncounter = _resolvesMutantRatTurns
        ? selectedMasterInitiativeGroupId
        : onlineCombatEncounterId;
    if (!_isMutantRatBite(request) ||
        encounter.isEmpty ||
        encounter != expectedEncounter ||
        request['faunaBurst'] != true ||
        request['damage'] != oculumMutantRatBiteDamage ||
        request['attack'] != 1 ||
        request['natural'] != 10 ||
        request['choice'] != oculumMutantRatBite ||
        request['element'] != 'fisico' ||
        request['forcedCritical'] == true ||
        request['turnResourceSpends'] != null ||
        request['effects'] is! List ||
        (request['effects'] as List).isNotEmpty ||
        request['targetBodyPart'] != null ||
        request['faunaPush'] == true ||
        request['faunaNonLethal'] == true) {
      return false;
    }
    final roster = _resolvesMutantRatTurns
        ? masterInitiativeTokens
        : onlineCombatTokens();
    final source = roster
        .where(
          (token) => combatTokenMatchesSheet(token, '${request['sourceTag']}'),
        )
        .firstOrNull;
    final target = roster
        .where(
          (token) => combatTokenMatchesSheet(token, '${request['targetTag']}'),
        )
        .firstOrNull;
    final instance = '${source?['summonInstanceId'] ?? ''}';
    return source != null &&
        target != null &&
        _isMutantRatPup(source) &&
        instance.isNotEmpty &&
        request['id'] == _mutantRatBiteId(encounter, instance) &&
        oculumShieldBreakCanTarget(source, target) &&
        source['mutantRatBiteTarget'] == request['targetTag'];
  }

  void startMutantRatPupTurn(Map<String, dynamic> token) {
    if (!_resolvesMutantRatTurns ||
        !_isMutantRatPup(token) ||
        token['mutantRatBiteTarget'] != null ||
        masterInitiativeTokenIsDowned(token) ||
        masterInitiativeTokenIsDead(token)) {
      return;
    }
    final encounter = selectedMasterInitiativeGroupId;
    final instance = '${token['summonInstanceId'] ?? ''}';
    final source = publicInitiativeSourceTag(token);
    if (encounter.isEmpty || instance.isEmpty || source.isEmpty) return;
    final owner = masterInitiativeTokens
        .where(
          (candidate) => combatTokenMatchesSheet(
            candidate,
            '${token['summonerTag'] ?? ''}',
          ),
        )
        .firstOrNull;
    final lastAggressor =
        owner?['mutantRatAggressorFight'] ==
            _summonFightKey('${token['summonerTag'] ?? ''}')
        ? (owner?['mutantRatLastAggressor'])?.toString()
        : null;
    final random = Random.secure();
    final target = oculumMutantRatBiteTarget(
      masterInitiativeTokens
          .where(
            (candidate) =>
                oculumShieldBreakCanTarget(token, candidate) &&
                !masterInitiativeTokenIsDowned(candidate),
          )
          .map(publicInitiativeSourceTag),
      lastAggressor,
      random.nextInt,
    );
    if (target == null) return;
    final id = _mutantRatBiteId(encounter, instance);
    token['mutantRatBiteTarget'] = target;
    token['reactionUsed'] = 1;
    token['reactionUsedRound'] = masterInitiativeRound;
    captureActiveMasterInitiativeGroup();
    final request = onlineCombatRequests.putIfAbsent(
      id,
      () => {
        'id': id,
        'scope': permissionScope,
        'campaignId': permissionCampaignId,
        'encounterId': encounter,
        'sourceTag': source,
        'sourceName': token['name'],
        'targetTag': target,
        'kind': 'fauna_burst',
        'choice': oculumMutantRatBite,
        'abilityName': 'Morso del topolino',
        'mutantRatBite': true,
        'faunaBurst': true,
        'baseAttack': false,
        'attack': 1,
        'natural': 10,
        'damage': oculumMutantRatBiteDamage,
        'element': 'fisico',
        'difficulty': 'normale',
        'effects': <Map<String, dynamic>>[],
        'status': 'pending',
      },
    );
    programmaSalvataggio();
    scheduleMicrotask(() => unawaited(dispatchMutantRatBite(request)));
  }

  Future<void> dispatchMutantRatBite(Map<String, dynamic> request) async {
    final busyKey = 'mutant-rat-dispatch:${request['id']}';
    if (!mounted ||
        !_resolvesMutantRatTurns ||
        request['status'] != 'pending' ||
        !validMutantRatBite(request) ||
        !onlineCombatResolving.add(busyKey)) {
      return;
    }
    try {
      final target = '${request['targetTag']}';
      if (controlsOnlineCombatSheet(target)) {
        await resolveMutantRatBiteForTarget(request);
      } else if (realtimeService?.isConnected == true) {
        captureActiveMasterInitiativeGroup();
        final service = realtimeService!;
        await service.sendInitiativeSnapshot(
          snapshot: buildRealtimeInitiativeSnapshot(),
          campaignId: activeCampaignId,
          campaignName: activeCampaignName(),
          closed: false,
        );
        if (!mounted ||
            realtimeService != service ||
            request['encounterId'] != selectedMasterInitiativeGroupId ||
            request['scope'] != permissionScope) {
          return;
        }
        request['sent'] = await realtimeService?.sendCombatEvent(
          'combat_attack',
          permissionEnvelope(request),
        );
      }
      if (mounted && request['status'] == 'resolved') {
        finishMutantRatBite(request);
      }
    } finally {
      onlineCombatResolving.remove(busyKey);
      if (mounted) programmaSalvataggio();
    }
  }

  Future<void> resolveMutantRatBiteForTarget(
    Map<String, dynamic> request,
  ) async {
    final key = 'mutant-rat-target:${request['id']}';
    if (!mounted || !onlineCombatResolving.add(key)) return;
    try {
      if (request['status'] == 'resolved') {
        await resendMutantRatBiteReply(request);
      } else if (request['status'] == 'pending') {
        await resolveAutomaticFaunaDamage(request);
      }
    } finally {
      onlineCombatResolving.remove(key);
    }
  }

  void finishMutantRatBite(Map<String, dynamic> request) {
    if (!_resolvesMutantRatTurns ||
        request['encounterId'] != selectedMasterInitiativeGroupId) {
      return;
    }
    final source = '${request['sourceTag']}';
    final token = masterInitiativeTokens
        .where((candidate) => combatTokenMatchesSheet(candidate, source))
        .firstOrNull;
    if (token == null ||
        !_isMutantRatPup(token) ||
        token['summonExpired'] == true) {
      return;
    }
    _expireMutantRatPup(token);
    captureActiveMasterInitiativeGroup();
    notifyActiveSheetSummaryChanged();
    sendRealtimeInitiativeSnapshotIfPublished();
    if (masterInitiativeTokens.indexOf(token) == masterInitiativeActiveIndex) {
      scheduleMicrotask(() {
        if (mounted &&
            selectedMasterInitiativeGroupId == request['encounterId'] &&
            identical(
              masterInitiativeTokens.elementAtOrNull(
                masterInitiativeActiveIndex,
              ),
              token,
            )) {
          nextMasterInitiativeTurn();
        }
      });
    }
  }

  Future<void> resendMutantRatBiteReply(Map<String, dynamic> request) async {
    if (!controlsOnlineCombatSheet('${request['targetTag']}')) return;
    await realtimeService?.sendCombatEvent('combat_defense', {
      ...permissionEnvelope(request),
      'senderTag': request['targetTag'],
    });
  }

  void receiveMutantRatPupExpiry(Map token, String encounter) {
    if (!_isMutantRatPup(token) || token['status'] != 'expired') return;
    final tag = '${token['sheetTag'] ?? token['id'] ?? ''}';
    final index = localSheetIndexForOculumTag(tag);
    if (index < 0 || !controlsOnlineCombatSheet(tag)) return;
    final sheet = schedePersonaggio[index];
    if (!_isMutantRatPup(sheet) ||
        sheet['summonExpired'] == true ||
        sheet['summonInstanceId'] != token['summonInstanceId'] ||
        sheet['summonEncounterId'] != encounter) {
      return;
    }
    sheet['summonExpired'] = true;
    setMasterEnemyLayerValue(index, 'currentHp', 0);
    programmaSalvataggio();
  }

  void _expireMutantRatPup(Map<String, dynamic> token) {
    if (token['summonExpired'] == true) return;
    token['summonExpired'] = true;
    token['status'] = 'expired';
    token['currentHp'] = 0;
    final index = localSheetIndexForOculumTag(publicInitiativeSourceTag(token));
    if (index >= 0 && _isMutantRatPup(schedePersonaggio[index])) {
      schedePersonaggio[index]['summonExpired'] = true;
      setMasterEnemyLayerValue(index, 'currentHp', 0);
    }
  }

  void expireMutantRatPups(String encounter) {
    if (encounter.isEmpty) return;
    for (var index = 0; index < schedePersonaggio.length; index++) {
      final sheet = schedePersonaggio[index];
      if (_isMutantRatPup(sheet) &&
          sheet['summonEncounterId'] == encounter &&
          sheet['summonExpired'] != true) {
        sheet['summonExpired'] = true;
        setMasterEnemyLayerValue(index, 'currentHp', 0);
      }
    }
    if (encounter == selectedMasterInitiativeGroupId) {
      for (final token in masterInitiativeTokens.where(_isMutantRatPup)) {
        _expireMutantRatPup(token);
      }
      captureActiveMasterInitiativeGroup();
    }
    notifyActiveSheetSummaryChanged();
  }
}
