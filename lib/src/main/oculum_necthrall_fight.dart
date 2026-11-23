part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

const _necthrallBindingKey = 'necthrallControl';
const _necthrallPendingKey = 'necthrallPendingControl';
const _necthrallCommandKind = 'necthrall_command';

extension _OculumNecthrallFight on _OculumHomePageState {
  bool get _necthrallFightActive =>
      realtimeService?.isConnected == true && !realtimeIsMasterRole
      ? realtimeVisibleInitiativeSnapshot['fightStarted'] == true &&
            realtimeVisibleInitiativeSnapshot['combatEnded'] != true
      : encounterFightStarted(onlineCombatEncounterId);

  Map<String, dynamic>? _necthrallReadToken(String tag) =>
      _writableOnlineCombatTokens().where((token) {
        return combatTokenMatchesSheet(token, tag);
      }).firstOrNull;

  bool _necthrallActiveToken(Map<String, dynamic> token) =>
      masterInitiativeTokenCanAct(token) &&
      token['outsideFight'] != true &&
      !masterInitiativeTokenIsTemporary(token);

  Map? _necthrallBinding(Map<String, dynamic> boss) {
    final record = boss[_necthrallBindingKey];
    if (record is! Map ||
        record['encounterId'] != onlineCombatEncounterId ||
        record['campaignId'] != permissionCampaignId ||
        record['scope'] != permissionScope ||
        !_necthrallFightActive ||
        !_necthrallActiveToken(boss) ||
        record['bossFight'] != boss['fightInstanceId']) {
      return null;
    }
    final puppet = _necthrallReadToken('${record['targetTag']}');
    return puppet != null &&
            _necthrallActiveToken(puppet) &&
            record['targetFight'] == puppet['fightInstanceId']
        ? record
        : null;
  }

  Map? _necthrallBindingForPuppet(String tag) => _writableOnlineCombatTokens()
      .map(_necthrallBinding)
      .whereType<Map>()
      .where((record) => oculumSameSheetIdentity(record['targetTag'], tag))
      .firstOrNull;

  bool _necthrallControlsResources(String tag, String resource) =>
      (const {
            'azione',
            'reazione',
            'azione_anticipata',
            'reazione_veloce',
          }.contains(resource) ||
          onlineCombatRequests[resource]?['freeReaction'] == true) &&
      _necthrallBindingForPuppet(tag) != null;

  bool get _necthrallSpindleIntact => oculumOculiathPartIntact(
    anatomicalPartState['parts'],
    oculumNecthrallSpindle,
  );

  bool get _necthrallCanSelect =>
      escapeAuthority &&
      _usesLocalMasterInitiative &&
      _necthrallFightActive &&
      faunaCurrentMonsterId == oculumNecthrallId &&
      _necthrallSpindleIntact;

  int _necthrallRule(String key, int fallback) {
    final overrides = planarState['encounterRules'];
    return readIntValue(
      overrides is Map && overrides.containsKey(key)
          ? overrides[key]
          : cycleRules[key],
      fallback: fallback,
    ).clamp(0, 100000);
  }

  void _necthrallPublish() {
    captureActiveMasterInitiativeGroup();
    sendRealtimeInitiativeSnapshotIfPublished();
    programmaSalvataggio();
    notifyActiveSheetSummaryChanged();
  }

  void clearNecthrallControl(Map<String, dynamic> boss) {
    boss.remove(_necthrallPendingKey);
    final binding = boss.remove(_necthrallBindingKey);
    if (binding is Map) {
      aggiungiLog('[NECTHRALL] Il legame con la marionetta è terminato.');
    }
  }

  void breakNecthrallSpindle() {
    if (!escapeAuthority) return;
    final boss = _necthrallReadToken(sheetTagAt(schedaCorrente));
    if (boss == null) return;
    clearNecthrallControl(boss);
    _necthrallPublish();
  }

  List<Map<String, dynamic>> _necthrallTargets(Map<String, dynamic> boss) =>
      _writableOnlineCombatTokens().where((target) {
        return _necthrallActiveToken(target) &&
            _attackTokenIsOpponent(target, combatParticipantTeamId(boss)) &&
            _necthrallBindingForPuppet(onlineCombatTokenTag(target)) == null &&
            localSheetIndexForOculumTag(onlineCombatTokenTag(target)) >= 0;
      }).toList();

  Future<String?> _pickNecthrallTarget(
    String title,
    Iterable<Map<String, dynamic>> candidates,
  ) => showDialog<String>(
    context: context,
    builder: (dialog) => SimpleDialog(
      title: Text(title),
      children: [
        for (final target in candidates)
          SimpleDialogOption(
            onPressed: () =>
                Navigator.pop(dialog, onlineCombatTokenTag(target)),
            child: Text(oculumReferenceEncounterTokenName(target)),
          ),
      ],
    ),
  );

  bool _isNecthrallBindForm(CharacterSkillForm form) =>
      form.effettiStrutturati.any(
        (effect) =>
            effect.enabled &&
            effect.type == 'planar' &&
            effect.target == oculumNecthrallBind,
      );

  Future<bool> selectNecthrallBind(
    CharacterSkill skill,
    CharacterSkillForm form,
  ) async {
    bool formIsAvailable() =>
        skills.contains(skill) &&
        skill.forme.contains(form) &&
        !skill.passiva &&
        _isNecthrallBindForm(form) &&
        combatNaturalFormAvailable(form);

    if (!_necthrallCanSelect || !formIsAvailable()) return false;
    final source = sheetTagAt(schedaCorrente);
    final boss = _necthrallReadToken(source);
    if (boss == null ||
        !corruptionCanSpendToken(boss, 'azione') ||
        boss[_necthrallPendingKey] != null ||
        _necthrallBinding(boss) != null) {
      return false;
    }
    final candidates = _necthrallTargets(boss);
    if (candidates.isEmpty) return false;
    final scope = permissionScope;
    final campaign = permissionCampaignId;
    final encounter = onlineCombatEncounterId;
    final fight = boss['fightInstanceId'];
    final turn = _turnSpendRetryTurn()?.key;
    final candidateFights = {
      for (final target in candidates)
        onlineCombatTokenTag(target): target['fightInstanceId'],
    };
    final selected = await _pickNecthrallTarget(
      t('Necthbind · Prova di Volontà', 'Necthbind · Will save'),
      candidates,
    );
    if (selected == null || !candidateFights.containsKey(selected)) {
      return false;
    }
    bool originalSelectionIsValid() {
      if (!mounted ||
          !_necthrallCanSelect ||
          !formIsAvailable() ||
          source != sheetTagAt(schedaCorrente) ||
          scope != permissionScope ||
          campaign != permissionCampaignId ||
          encounter != onlineCombatEncounterId ||
          turn != _turnSpendRetryTurn()?.key) {
        return false;
      }
      final currentBoss = _necthrallReadToken(source);
      final currentTarget = _necthrallReadToken(selected);
      return currentBoss != null &&
          currentBoss['fightInstanceId'] == fight &&
          corruptionCanSpendToken(currentBoss, 'azione') &&
          currentBoss[_necthrallPendingKey] == null &&
          _necthrallBinding(currentBoss) == null &&
          currentTarget != null &&
          currentTarget['fightInstanceId'] == candidateFights[selected] &&
          _necthrallTargets(currentBoss).contains(currentTarget);
    }

    bool commit(Map<String, int> payments) =>
        originalSelectionIsValid() &&
        _attemptNecthrallBind(selected, form.cooldownStrutturato, payments);

    final cost = oculumCharacterSkillFormCost(form);
    if (cost == null ||
        (oculumNormalizeEffectResource(cost.resource) == 'nessuna' &&
            cost.additionalCosts.isEmpty)) {
      return commit(const {});
    }
    return useConfiguredAbility(
      source: '${skill.nome} / ${form.nome}',
      effects: const [],
      cost: cost,
      cooldown: form.cooldownStrutturato,
      valid: originalSelectionIsValid,
      paymentOnly: true,
      commitPayment: commit,
    );
  }

  bool _attemptNecthrallBind(
    String targetTag,
    OculumAbilityCooldown? cooldown,
    Map<String, int> payments,
  ) {
    if (!_necthrallCanSelect) return false;
    final source = sheetTagAt(schedaCorrente);
    final boss = _necthrallReadToken(source);
    final target = boss == null
        ? null
        : _necthrallTargets(boss)
              .where((token) => combatTokenMatchesSheet(token, targetTag))
              .firstOrNull;
    if (boss == null ||
        target == null ||
        boss[_necthrallPendingKey] != null ||
        _necthrallBinding(boss) != null ||
        !corruptionCanSpendToken(boss, 'azione') ||
        !_consumeLocalCombatTurnResource(
          source,
          'azione',
          advanceMasterTurn: false,
          payForAction: () => spendArtSkillPayments(payments),
        )) {
      return false;
    }
    cooldown?.activate();
    final id = 'necthrall:$source:${DateTime.now().microsecondsSinceEpoch}';
    final record = <String, dynamic>{
      'id': id,
      'kind': 'necthrall_bind',
      'status': 'awaiting_will',
      'scope': permissionScope,
      'campaignId': permissionCampaignId,
      'encounterId': onlineCombatEncounterId,
      'sourceTag': source,
      'targetTag': targetTag,
      'bossFight': boss['fightInstanceId'],
      'targetFight': target['fightInstanceId'],
      'dt': _necthrallRule('necthrallControlDt', oculumNecthrallDefaultDt),
      'natural': 1 + Random.secure().nextInt(20),
    };
    boss[_necthrallPendingKey] = id;
    onlineCombatRequests[id] = record;
    if (controlsOnlineCombatSheet(targetTag)) {
      final will = oculiathCurrentWillAt(
        localSheetIndexForOculumTag(targetTag),
      );
      _finishNecthrallWill(
        record,
        resisted:
            readIntValue(record['natural']) + will >=
            readIntValue(record['dt']),
        localWill: will,
      );
    } else {
      unawaited(_sendNecthrallEvent(record, 'will_request'));
    }
    advanceMasterInitiativeAfterAction(source);
    _necthrallPublish();
    return true;
  }

  void _finishNecthrallWill(
    Map<String, dynamic> record, {
    required bool resisted,
    int? localWill,
  }) {
    final source = '${record['sourceTag']}';
    final target = '${record['targetTag']}';
    final boss = _necthrallReadToken(source);
    final puppet = _necthrallReadToken(target);
    if (record['status'] != 'awaiting_will' ||
        boss == null ||
        puppet == null ||
        !_necthrallActiveToken(boss) ||
        !_necthrallActiveToken(puppet) ||
        !_necthrallFightActive ||
        boss[_necthrallPendingKey] != record['id'] ||
        boss['fightInstanceId'] != record['bossFight'] ||
        puppet['fightInstanceId'] != record['targetFight']) {
      return;
    }
    boss.remove(_necthrallPendingKey);
    record['status'] = 'resolved';
    final natural = readIntValue(record['natural']);
    final dt = readIntValue(record['dt']);
    if (!resisted && _necthrallBindingForPuppet(target) == null) {
      boss[_necthrallBindingKey] = {...record};
    }
    final check = localWill == null
        ? 'prova contro DT $dt'
        : 'Volontà $natural + $localWill = ${natural + localWill} contro DT $dt';
    final message =
        '[NECTHRALL] ${oculumReferenceEncounterTokenName(puppet)} '
        '· $check. '
        '${boss[_necthrallBindingKey] != null ? 'Controllo riuscito.' : 'Controllo resistito.'}';
    aggiungiLog(message);
    if (target != sheetTagAt(schedaCorrente)) combatLogFor(target, message);
    _necthrallPublish();
  }

  Future<void> _sendNecthrallEvent(
    Map<String, dynamic> record,
    String stage, {
    String? owner,
  }) async {
    final packet = permissionEnvelope({
      ...record,
      'id': '${record['id']}:$stage',
      'necthrallEvent': stage,
      'recordId': record['id'],
    });
    if (owner != null) packet['senderTag'] = owner;
    await realtimeService?.sendCombatEvent('combat_scout', packet);
  }

  void receiveNecthrallEvent(Map<String, dynamic> payload) {
    if (!validPermissionSender(payload) ||
        payload['encounterId'] != onlineCombatEncounterId ||
        !_necthrallFightActive) {
      return;
    }
    final id = '${payload['recordId'] ?? ''}';
    if (id.isEmpty || id.length > 160) return;
    final stage = payload['necthrallEvent'];
    final target = '${payload['targetTag'] ?? ''}';
    final fromMaster = payload['senderRole'] == 'master';
    final stored = onlineCombatRequests[id];
    final matchingOwner =
        oculumSameSheetIdentity(payload['senderTag'], target) &&
        stored?['targetTag'] == target;
    if (stage == 'will_reply' &&
        realtimeIsMasterRole &&
        matchingOwner &&
        stored?['kind'] == 'necthrall_bind') {
      final resisted = payload['resisted'];
      if (resisted is bool) {
        _finishNecthrallWill(stored!, resisted: resisted);
      }
      return;
    }
    if (stage == 'command_done' &&
        realtimeIsMasterRole &&
        matchingOwner &&
        stored?['kind'] == _necthrallCommandKind &&
        stored?['status'] == 'issued') {
      _finishNecthrallCommand(stored!);
      return;
    }
    if (!fromMaster || !controlsOnlineCombatSheet(target)) return;
    final token = _necthrallReadToken(target);
    if (token == null ||
        token['fightInstanceId'] != payload['targetFight'] ||
        !_necthrallActiveToken(token)) {
      return;
    }
    if (stage == 'will_request') {
      final natural = readIntValue(payload['natural']);
      if (natural < 1 || natural > 20) return;
      final dt = readIntValue(payload['dt']);
      final will = oculiathCurrentWillAt(localSheetIndexForOculumTag(target));
      unawaited(
        _sendNecthrallEvent(
          {
            'id': id,
            'encounterId': payload['encounterId'],
            'targetTag': target,
            'resisted': natural + will >= dt,
          },
          'will_reply',
          owner: target,
        ),
      );
    } else if (stage == 'command' && stored == null) {
      onlineCombatRequests[id] = {
        ...payload,
        'id': id,
        'kind': _necthrallCommandKind,
        'status': 'ready',
      };
      programmaSalvataggio();
      if (mounted) setState(() {});
    }
  }

  int _necthrallDefenseOffer(Map<String, dynamic> request) {
    if (!_necthrallCanSelect || request['firstDefense'] != null) return 0;
    final boss = _necthrallReadToken(sheetTagAt(schedaCorrente));
    final bind = boss == null ? null : _necthrallBinding(boss);
    final puppet = bind == null
        ? null
        : _necthrallReadToken('${bind['targetTag']}');
    if (puppet == null ||
        masterInitiativeNormalReactionRemaining(
              puppet,
              round: _onlineCombatRound(),
            ) <=
            0 ||
        artDebtForToken(puppet, 'reaction') > 0 ||
        totalPowerTokenExhausted(puppet)) {
      return 0;
    }
    return _necthrallRule(
      'necthrallDefenseCm',
      oculumNecthrallDefaultDefenseCm,
    );
  }

  int spendNecthrallDefense(Map<String, dynamic> request) {
    final bonus = _necthrallDefenseOffer(request);
    final boss = _necthrallReadToken(sheetTagAt(schedaCorrente));
    final bind = boss == null ? null : _necthrallBinding(boss);
    if (bonus <= 0 ||
        request['necthrallDefenseCm'] != null ||
        request['status'] != 'pending' ||
        !oculumSameSheetIdentity(
          request['targetTag'],
          sheetTagAt(schedaCorrente),
        ) ||
        !_consumeLocalCombatTurnResource(
          '${bind?['targetTag']}',
          'reazione',
          advanceMasterTurn: false,
          necthrallAuthorized: true,
        )) {
      return 0;
    }
    request['necthrallDefenseCm'] = bonus;
    aggiungiLog(
      '[NECTHRALL] Reazione normale della marionetta: +$bonus CM alla Difesa.',
    );
    _necthrallPublish();
    return bonus;
  }

  Future<bool> chooseNecthrallDefense(Map<String, dynamic> request) async {
    final bonus = _necthrallDefenseOffer(request);
    if (bonus <= 0) return false;
    return await showDialog<bool>(
          context: context,
          builder: (dialog) => AlertDialog(
            title: Text(t('Difesa di Necthrall', 'Necthrall’s defense')),
            content: Text(
              t(
                'Spendi la Reazione normale della marionetta per +$bonus CM su questo tiro?',
                'Spend the puppet’s normal Reaction for +$bonus CM on this roll?',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialog, false),
                child: Text(t('Tira senza bonus', 'Roll without bonus')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialog, true),
                child: Text(t('Spendi Reazione', 'Spend Reaction')),
              ),
            ],
          ),
        ) ==
        true;
  }

  Future<void> selectNecthrallCommand() async {
    if (!_necthrallCanSelect) return;
    final source = sheetTagAt(schedaCorrente);
    final boss = _necthrallReadToken(source);
    final bind = boss == null ? null : _necthrallBinding(boss);
    if (bind == null) return;
    final puppetTag = '${bind['targetTag']}';
    final puppet = _necthrallReadToken(puppetTag);
    if (puppet == null || !corruptionCanSpendToken(puppet, 'azione')) {
      aggiungiLog(
        '[NECTHRALL] La marionetta può attaccare con un’Azione disponibile nel suo turno.',
      );
      return;
    }
    final candidates = _writableOnlineCombatTokens().where((target) {
      return _necthrallActiveToken(target) &&
          !combatTokenMatchesSheet(target, puppetTag) &&
          !combatTokenMatchesSheet(target, source);
    });
    if (candidates.isEmpty) return;
    final attackTarget = await _pickNecthrallTarget(
      t('Attacco della marionetta', 'Puppet attack'),
      candidates,
    );
    if (attackTarget == null ||
        !mounted ||
        source != sheetTagAt(schedaCorrente)) {
      return;
    }
    final currentBoss = _necthrallReadToken(source);
    final live = currentBoss == null ? null : _necthrallBinding(currentBoss);
    final currentPuppet = _necthrallReadToken(puppetTag);
    final victim = _necthrallReadToken(attackTarget);
    if (live?['id'] != bind['id'] ||
        currentPuppet == null ||
        victim == null ||
        !_necthrallActiveToken(victim) ||
        !corruptionCanSpendToken(currentPuppet, 'azione') ||
        !_consumeLocalCombatTurnResource(
          puppetTag,
          'azione',
          advanceMasterTurn: false,
          necthrallAuthorized: true,
        )) {
      return;
    }
    final id = '${bind['id']}:attack:${DateTime.now().microsecondsSinceEpoch}';
    final owned = controlsOnlineCombatSheet(puppetTag);
    final record = <String, dynamic>{
      ...bind.cast<String, dynamic>(),
      'id': id,
      'controlId': bind['id'],
      'kind': _necthrallCommandKind,
      'status': owned ? 'ready' : 'issued',
      'attackTarget': attackTarget,
    };
    onlineCombatRequests[id] = record;
    aggiungiLog('[NECTHRALL] Attacco ordinato alla marionetta.');
    if (!owned) unawaited(_sendNecthrallEvent(record, 'command'));
    _necthrallPublish();
  }

  bool _necthrallCommandCanExecute(Map<String, dynamic> record) {
    final own = sheetTagAt(schedaCorrente);
    final bind = _necthrallBindingForPuppet(own);
    final victim = _necthrallReadToken('${record['attackTarget']}');
    return record['kind'] == _necthrallCommandKind &&
        record['targetTag'] == own &&
        record['scope'] == permissionScope &&
        record['campaignId'] == permissionCampaignId &&
        record['encounterId'] == onlineCombatEncounterId &&
        bind?['id'] == record['controlId'] &&
        victim != null &&
        _necthrallActiveToken(victim);
  }

  Map<String, dynamic>? get executingCombatCommand =>
      executingCorruptionCommand ??
      onlineCombatRequests.values.where((record) {
        return record['status'] == 'executing' &&
            _necthrallCommandCanExecute(record);
      }).firstOrNull;

  Future<void> executeNecthrallCommand(Map<String, dynamic> record) async {
    if (record['status'] != 'ready' || !_necthrallCommandCanExecute(record)) {
      return;
    }
    record['status'] = 'executing';
    record['executionResourceClaimed'] = false;
    try {
      await planOnlineAttack();
    } finally {
      if (record['executionResourceClaimed'] == true) {
        if (escapeAuthority) {
          _finishNecthrallCommand(record);
        } else {
          record['status'] = 'resolved';
          await _sendNecthrallEvent(
            record,
            'command_done',
            owner: '${record['targetTag']}',
          );
        }
      } else {
        record['status'] = 'ready';
      }
      programmaSalvataggio();
      if (mounted) setState(() {});
    }
  }

  void _finishNecthrallCommand(Map<String, dynamic> record) {
    record['status'] = 'resolved';
    if (_necthrallBindingForPuppet('${record['targetTag']}')?['id'] ==
        record['controlId']) {
      advanceMasterInitiativeAfterAction('${record['targetTag']}');
    }
    _necthrallPublish();
  }

  Iterable<Widget> necthrallFightControls(
    void Function(VoidCallback) run,
  ) sync* {
    if (_necthrallCanSelect) {
      final boss = _necthrallReadToken(sheetTagAt(schedaCorrente));
      if (boss != null) {
        final bind = _necthrallBinding(boss);
        if (bind == null && boss[_necthrallPendingKey] == null) {
          final skill = skills.where((skill) {
            return skill.equipaggiata &&
                !skill.passiva &&
                skill.forme.any(_isNecthrallBindForm);
          }).firstOrNull;
          if (skill != null) {
            final canAct =
                corruptionCanSpendToken(boss, 'azione') &&
                skill.forme.any(
                  (form) =>
                      _isNecthrallBindForm(form) &&
                      combatNaturalFormAvailable(form),
                );
            yield ListTile(
              leading: const Icon(Icons.cable),
              title: Text(
                t('Necthbind · Controlla nemico', 'Necthbind · Control enemy'),
              ),
              subtitle: Text(
                t('1 Azione · Prova di Volontà', '1 Action · Will save'),
              ),
              onTap: canAct
                  ? () => run(
                      () => unawaited(
                        chooseCombatAbilityForm(
                          natural: skill,
                          naturalFormFilter: _isNecthrallBindForm,
                        ),
                      ),
                    )
                  : null,
            );
          }
        } else if (bind != null) {
          final puppet = _necthrallReadToken('${bind['targetTag']}');
          yield ListTile(
            leading: const Icon(Icons.cable),
            title: Text(
              t('Comanda l’attacco della marionetta', 'Command puppet attack'),
            ),
            subtitle: Text(
              t('Usa l’Azione della marionetta', 'Uses the puppet’s Action'),
            ),
            onTap: puppet != null && corruptionCanSpendToken(puppet, 'azione')
                ? () => run(() => unawaited(selectNecthrallCommand()))
                : null,
          );
        }
      }
    }
    final own = sheetTagAt(schedaCorrente);
    final bind = _necthrallBindingForPuppet(own);
    if (bind == null) return;
    final ready = onlineCombatRequests.values
        .where(
          (request) =>
              request['status'] == 'ready' &&
              _necthrallCommandCanExecute(request),
        )
        .firstOrNull;
    yield ListTile(
      leading: const Icon(Icons.cable),
      title: Text(
        ready == null
            ? t('Sotto il controllo di Necthrall', 'Controlled by Necthrall')
            : t('Esegui l’attacco ordinato', 'Resolve the commanded attack'),
      ),
      subtitle: Text(
        t('Fino al prossimo turno di Necthrall', 'Until Necthrall’s next turn'),
      ),
      onTap: ready == null
          ? null
          : () => run(() => unawaited(executeNecthrallCommand(ready))),
    );
  }
}
