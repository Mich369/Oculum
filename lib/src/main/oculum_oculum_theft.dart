part of '../../main.dart';

const oculumOculumTheftKind = 'oculum_theft';
const _oculumTheftBuffCast = 'oculumTheftBuffCast';
const _oculumTheftBuffPrefix = 'oculum-theft:';
final _oculumTheftBusy = Expando<bool>();

int oculumTheftDebit(int reserve, int limit, int attack, int defense) =>
    attack > defense ? min(max(0, reserve), max(0, limit)) : 0;

int oculumTheftGain(
  int stolen,
  int maximum,
  int current, {
  int? unmaskedCurrent,
}) => min(
  max(0, stolen),
  max(0, maximum + 5 - max(current, unmaskedCurrent ?? current)),
);

int oculumTheftBuffRemaining(int duration, int firstTurn, int currentTurn) =>
    max(0, duration - max(0, currentTurn - firstTurn));

int _boundedOculumTheftChange(int maximum, bool Function(int) fits) {
  var low = 0;
  var high = maximum;
  while (low < high) {
    final candidate = (low + high + 1) ~/ 2;
    if (fits(candidate)) {
      low = candidate;
    } else {
      high = candidate - 1;
    }
  }
  return low;
}

class _OculumTheftForm {
  const _OculumTheftForm(
    this.limit,
    this.minimum,
    this.maximum,
    this.buff,
    this.turns,
  );

  final int limit;
  final int minimum;
  final int maximum;
  final int buff;
  final int turns;
}

extension _OculumOculumTheft on _OculumHomePageState {
  int get oculumTheftUses =>
      max(0, readIntValue(planarState[oculumTheftUsesRequirement]));

  _OculumTheftForm? _readOculumTheftForm(CharacterSkillForm form) {
    final marker = form.effettiStrutturati
        .where(
          (effect) => effect.enabled && effect.target == oculumOculumTheftKind,
        )
        .firstOrNull;
    if (marker == null) return null;
    final buff = form.effettiStrutturati
        .where(
          (effect) =>
              effect.enabled &&
              effect.type == 'modifica_statistica' &&
              effect.target == 'tutte',
        )
        .firstOrNull;
    int value(OculumStructuredEffect effect) => max(
      0,
      oculumEvaluateStructuredEffectValue(
        effect,
        variables: formulaValueContext(),
        subtraits: hiddenEyeStats,
      ),
    );
    final limit = value(marker).clamp(0, 1000000);
    final minimum = max(2, marker.minimumTargets).clamp(2, 100);
    if (limit == 0 || marker.maximumTargets < minimum) return null;
    return _OculumTheftForm(
      limit,
      minimum,
      marker.maximumTargets.clamp(2, 100),
      buff == null ? 0 : value(buff).clamp(0, 1000000),
      readIntValue(buff?.duration ?? marker.duration, fallback: 3).clamp(1, 20),
    );
  }

  Future<void> useOculumTheftScroll(
    Map<String, dynamic> data,
    InventoryItem item,
  ) async {
    final raw = data['authoredSkill'];
    if (raw is! Map) return;
    final skill = CharacterSkill.fromJson(Map<String, dynamic>.from(raw));
    skill.ensureForms();
    final form = skill.forme.reversed
        .where(
          (form) => form.effettiStrutturati.any(
            (effect) =>
                effect.enabled && effect.target == oculumOculumTheftKind,
          ),
        )
        .firstOrNull;
    if (form == null) return;
    await _castOculumTheft(
      skill.nome,
      form,
      valid: () => inventario.contains(item) && item.quantita > 0,
      commit: (natural, total) {
        item.quantita--;
        if (item.quantita == 0) inventario.remove(item);
        aggiungiLog('Pergamena consumata: ${data['name']}.');
        maybeLearnOculumTheftFromScroll(data, natural: natural, total: total);
      },
    );
  }

  Future<void> useLearnedOculumTheft(
    CharacterSkill skill,
    int formIndex,
  ) async {
    if (formIndex < 0 || formIndex >= skill.forme.length) return;
    final form = skill.forme[formIndex];
    final cooldown = form.cooldownStrutturato ??= OculumAbilityCooldown(
      amount: 3,
    );
    bool valid() =>
        skills.contains(skill) &&
        skill.forme.contains(form) &&
        skill.forme.every(
          (entry) => entry.cooldownStrutturato?.ready != false,
        ) &&
        progressionRequirementsMet(form.unlockRequirements) &&
        leggiNumero(livelloController) >= readIntValue(form.livello);
    if (!valid()) return;
    await _castOculumTheft(
      skill.nome,
      form,
      valid: valid,
      commit: (_, _) {
        planarState[oculumTheftUsesRequirement] = oculumTheftUses + 1;
        for (final entry in skill.forme) {
          entry.cooldownStrutturato ??= OculumAbilityCooldown(amount: 3);
          entry.cooldownStrutturato!.remaining = cooldown.amount;
        }
      },
    );
  }

  HiddenEyeStat _oculumTheftStat(String id) =>
      hiddenEyeStats.where((stat) => stat.id == id).firstOrNull ??
      defaultHiddenEyeStats().firstWhere((stat) => stat.id == id);

  Map<String, Map<String, dynamic>> _oculumTheftTargets(String own) {
    final tokens = onlineCombatTokens();
    final source = tokens
        .where((token) => combatTokenMatchesSheet(token, own))
        .firstOrNull;
    if (source == null || !masterInitiativeTokenCanAct(source)) return {};
    return {
      for (final token in tokens)
        if (!masterInitiativeTokenIsDead(token) &&
            oculumShieldBreakCanTarget(source, token))
          onlineCombatTokenTag(token): token,
    };
  }

  Future<void> _castOculumTheft(
    String name,
    CharacterSkillForm form, {
    required bool Function() valid,
    required void Function(int natural, int total) commit,
  }) async {
    if (_oculumTheftBusy[this] == true || !mounted || !valid()) return;
    alignCombatEncounterForRoll();
    final actor = sheetTagAt(schedaCorrente);
    final scope = permissionScope;
    final encounter = onlineCombatEncounterId;
    final fight = combatSubtraitExperienceFightId(encounter, ownerTag: actor);
    final origin = currentSheetScrollId();
    bool current() =>
        mounted &&
        currentSheetScrollId() == origin &&
        permissionScope == scope &&
        onlineCombatEncounterId == encounter &&
        currentCombatIsActive() &&
        !outsideFight &&
        hpCorrenti() > 0 &&
        controlsOnlineCombatSheet(actor) &&
        combatSubtraitExperienceFightId(encounter, ownerTag: actor) == fight &&
        valid();
    final config = _readOculumTheftForm(form);
    if (!current() || config == null) return;
    final targets = _oculumTheftTargets(actor);
    if (targets.length < config.minimum) {
      aggiungiLog('[$name] Servono almeno ${config.minimum} nemici nel Fight.');
      return;
    }
    final stat = _oculumTheftStat('manifestazione_potere');
    _oculumTheftBusy[this] = true;
    try {
      final mode = await showDialog<String>(
        context: context,
        builder: (dialog) => SimpleDialog(
          title: Text(name),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialog, 'reload'),
              child: const Text('Ricarica Oculum · fino al massimo +5'),
            ),
            if (config.buff > 0)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(dialog, 'buff'),
                child: Text(
                  '+${config.buff} a tutte le statistiche per nemico assorbito · ${config.turns} turni personali',
                ),
              ),
          ],
        ),
      );
      if (!mounted || mode == null || !current()) return;
      final plan = await showDialog<OculumAttackPlan>(
        context: context,
        builder: (_) => OculumAttackPlanner(
          targets: {
            for (final entry in targets.entries)
              entry.key: faunaTargetName(entry.value),
          },
          targetColors: {
            for (final entry in targets.entries)
              entry.key: combatParticipantSideColor(entry.value),
          },
          choices: [
            OculumAttackChoice(stat.id, stat.nome, hiddenEyeTotal(stat)),
          ],
          chance: (_, _) => null,
          initialChoice: stat.id,
          minimumTargets: config.minimum,
          maximumTargets: config.maximum,
          distinctTargets: true,
          comparisonRule:
              'Tira Manifestazione del Potere una volta. Ogni bersaglio si difende con Canalizzazione e vince in caso di parità.',
        ),
      );
      if (plan == null || !current()) return;
      final selected = plan.targetIds.toSet();
      bool canCommit() =>
          current() &&
          selected.length >= config.minimum &&
          selected.length <= config.maximum &&
          _oculumTheftTargets(actor).keys.toSet().containsAll(selected);
      if (!canCommit() ||
          !await requestUtilitySpend('azione', preferFreeReaction: false) ||
          !canCommit()) {
        return;
      }
      await tiraSottotrattoOcchio(
        stat,
        actionLabel: name,
        resourceAlreadySpent: true,
        consumeRollStats: false,
        canCommitFortuneRoll: canCommit,
        onResolved: (natural, total) {
          if (!canCommit()) return;
          final cast = '$actor:${DateTime.now().microsecondsSinceEpoch}';
          commit(natural, total);
          if (mode == 'buff') {
            planarState[_oculumTheftBuffCast] = {
              'id': cast,
              'fight': fight,
              'hits': 0,
            };
          }
          var index = 0;
          for (final target in selected) {
            final packet = <String, dynamic>{
              'id': 'theft:$cast:${index++}',
              'kind': oculumOculumTheftKind,
              'attackGroupId': cast,
              'scope': scope,
              'encounterId': encounter,
              'sourceTag': actor,
              'sourceName': nomeController.text,
              'targetTag': target,
              'targetName': faunaTargetName(targets[target]!),
              'status': 'pending',
              'choice': stat.id,
              'abilityName': name,
              'attack': total,
              'natural': natural,
              'damage': 0,
              'element': 'oculum',
              'theftFight': fight,
              'theftMode': mode,
              'theftLimit': config.limit,
              'theftBuff': config.buff,
              'theftTurns': config.turns,
              'theftTargets': selected.length,
            };
            onlineCombatRequests['${packet['id']}'] = packet;
            receiveLocalCombatAttack(packet);
            unawaited(sendOnlineCombatRequest(packet));
          }
          programmaSalvataggio();
        },
      );
    } finally {
      _oculumTheftBusy[this] = null;
    }
  }

  bool validOculumTheftAttack(Map request) =>
      request['kind'] == oculumOculumTheftKind &&
      request['choice'] == 'manifestazione_potere' &&
      request['damage'] == 0 &&
      request['attack'] is num &&
      const {'reload', 'buff'}.contains(request['theftMode']) &&
      readIntValue(request['theftLimit']).clamp(1, 1000000) ==
          request['theftLimit'] &&
      readIntValue(request['theftTargets']).clamp(2, 100) ==
          request['theftTargets'] &&
      readIntValue(request['theftBuff']).clamp(0, 1000000) ==
          request['theftBuff'] &&
      readIntValue(request['theftTurns']).clamp(1, 20) ==
          request['theftTurns'] &&
      '${request['attackGroupId'] ?? ''}'.isNotEmpty &&
      '${request['theftFight'] ?? ''}'.isNotEmpty;

  bool oculumTheftPacketFightMatches(Map request) {
    final encounter = onlineCombatEncounterId;
    return validOculumTheftAttack(request) &&
        currentCombatIsActive() &&
        request['scope'] == permissionScope &&
        request['encounterId'] == encounter &&
        request['theftFight'] ==
            combatSubtraitExperienceFightId(
              encounter,
              ownerTag: '${request['sourceTag']}',
            );
  }

  bool _oculumTheftRequestCurrent(Map request) =>
      !outsideFight && oculumTheftPacketFightMatches(request);

  Future<void> defendOculumTheft(
    Map<String, dynamic> request,
    String choice,
  ) async {
    final id = '${request['id']}';
    final target = sheetTagAt(schedaCorrente);
    bool valid() =>
        mounted &&
        _oculumTheftRequestCurrent(request) &&
        request['status'] == 'pending' &&
        request['targetTag'] == target &&
        sheetTagAt(schedaCorrente) == target &&
        controlsOnlineCombatSheet(target) &&
        identical(onlineCombatRequests[id], request);
    if (choice != 'canalizzazione' ||
        !valid() ||
        !onlineCombatResolving.add(id)) {
      return;
    }
    try {
      int? defense;
      await tiraSottotrattoOcchio(
        _oculumTheftStat(choice),
        defenseRoll: true,
        actionLabel: 'Difesa contro ${request['abilityName']}',
        canCommitFortuneRoll: valid,
        onResolved: (_, total) => defense = total,
      );
      if (defense != null && valid()) {
        await applyResolvedOnlineDefense(request, choice, defense!);
      }
    } finally {
      onlineCombatResolving.remove(id);
    }
  }

  Future<void> resolveOculumTheftDefense(
    Map<String, dynamic> request,
    String choice,
    int defense,
  ) async {
    if (choice != 'canalizzazione' || !_oculumTheftRequestCurrent(request)) {
      return;
    }
    final targets = _oculumTheftTargets('${request['sourceTag']}');
    final eligible = targets.keys.any(
      (target) => oculumSameSheetIdentity(target, request['targetTag']),
    );
    final canDebit =
        eligible && faunaReceipt(_oculumTheftReceiptKey(request, 'debit'));
    final before = oculumTotale();
    final amount = canDebit
        ? oculumTheftDebit(
            before,
            readIntValue(request['theftLimit']),
            readIntValue(request['attack']),
            defense,
          )
        : 0;
    if (amount > 0) {
      final beforeState = currentTemporaryOculumState();
      final debit = _boundedOculumTheftChange(
        amount,
        (candidate) =>
            before -
                oculumTotale(storedCurrent: beforeState.total - candidate) <=
            amount,
      );
      final next = spendOculumFromTemporaryState(
        state: beforeState,
        amount: debit,
        minimumNormalCurrent: currentOculumRuntimeFloor(),
      );
      setStat35OculumOverflow(
        max(0, stat35OculumOverflow - (temporaryOculum - next.temporary)),
      );
      applyTemporaryOculumState(next);
      recordCurrentOculumProgress();
    }
    final stolen = max(0, before - oculumTotale());
    request.addAll({
      'status': 'resolved',
      'defense': defense,
      'defenseChoice': choice,
      'theftStolen': stolen,
    });
    aggiungiLog(
      '[${request['abilityName']}] Canalizzazione $defense · $stolen Oculum sottratto.',
    );
    final reply = permissionEnvelope(request);
    attachPendingCombatTurnResources(reply);
    creditOculumTheftReceipt(request, stolen);
    programmaSalvataggio();
    await realtimeService?.sendCombatEvent('combat_defense', reply);
  }

  bool acceptOculumTheftDefense(
    Map<String, dynamic> request,
    Map<String, dynamic> reply,
  ) {
    if (!validOculumTheftAttack(request) ||
        reply['defenseChoice'] != 'canalizzazione' ||
        reply['defense'] is! num ||
        reply['theftStolen'] is! int) {
      return false;
    }
    final stolen = readIntValue(reply['theftStolen']);
    if (stolen < 0 ||
        stolen > readIntValue(request['theftLimit']) ||
        (stolen > 0 &&
            readIntValue(request['attack']) <=
                readIntValue(reply['defense']))) {
      return false;
    }
    request.addAll({
      'status': 'resolved',
      'defense': reply['defense'],
      'defenseChoice': 'canalizzazione',
      'theftStolen': stolen,
    });
    creditOculumTheftReceipt(request, stolen);
    notifyActiveSheetSummaryChanged();
    programmaSalvataggio();
    return true;
  }

  void creditOculumTheftReceipt(Map request, int stolen) {
    if (stolen <= 0) return;
    faunaForOwnedSheet('${request['sourceTag']}', () {
      if (!_oculumTheftRequestCurrent(request) ||
          !faunaReceipt(_oculumTheftReceiptKey(request, 'credit'))) {
        return;
      }
      if (request['theftMode'] == 'reload') {
        _gainOculumTheft(stolen, '${request['abilityName']}');
      } else {
        _applyOculumTheftBuff(request);
      }
      programmaSalvataggio();
    });
  }

  String _oculumTheftReceiptKey(Map request, String direction) =>
      '$_oculumTheftBuffPrefix$direction:${request['scope']}:${request['theftFight']}:${request['attackGroupId']}:${request['targetTag']}';

  void _gainOculumTheft(int stolen, String name) {
    if (isMeccanio || isThunderBot || hasCondition('vuoto')) return;
    final before = currentTemporaryOculumState();
    final visibleBefore = oculumTotale();
    final unmaskedBefore = oculumTotale(
      storedCurrent: before.total,
      ignoreTemporarySuppression: true,
    );
    final allowed = oculumTheftGain(
      stolen,
      oculumMassimoNaturale(),
      visibleBefore,
      unmaskedCurrent: unmaskedBefore,
    );
    final amount = _boundedOculumTheftChange(allowed, (candidate) {
      final projected = before.total + candidate;
      return oculumTotale(storedCurrent: projected) - visibleBefore <=
              allowed &&
          oculumTotale(
                    storedCurrent: projected,
                    ignoreTemporarySuppression: true,
                  ) -
                  unmaskedBefore <=
              allowed;
    });
    if (amount <= 0) return;
    final normal = min(
      amount,
      max(0, _currentOculumCapacity - before.normalCurrent),
    );
    final extra = amount - normal;
    setStat35OculumOverflow(stat35OculumOverflow + extra);
    applyTemporaryOculumState(
      TemporaryOculumState(
        normalCurrent: before.normalCurrent + normal,
        temporary: before.temporary + extra,
        rollsRemaining: before.rollsRemaining,
      ),
    );
    final visibleGain = max(0, oculumTotale() - visibleBefore);
    showSheetStatGain('oculum', visibleGain);
    recordCurrentOculumProgress();
    aggiungiLog('[$name] +$visibleGain Oculum dalla sfera.');
  }

  void _applyOculumTheftBuff(Map request) {
    final cast = planarState[_oculumTheftBuffCast];
    if (cast is! Map ||
        cast['id'] != request['attackGroupId'] ||
        cast['fight'] != request['theftFight']) {
      return;
    }
    final start = readIntValue(cast['firstTurn'], fallback: playerReportedTurn);
    final remaining = oculumTheftBuffRemaining(
      readIntValue(request['theftTurns']),
      start,
      playerReportedTurn,
    );
    if (remaining == 0) return;
    final hits = readIntValue(cast['hits']) + 1;
    if (hits > readIntValue(request['theftTargets'])) return;
    final bonus = hits * readIntValue(request['theftBuff']);
    if (bonus <= 0) return;
    planarState[_oculumTheftBuffCast] = {
      ...cast,
      'firstTurn': start,
      'hits': hits,
    };
    final source = '${request['abilityName']}';
    applyStructuredEffectsOnActivation(
      [
        for (final stat in const ['resilienza', 'volonta', 'materia', 'oculum'])
          OculumStructuredEffect(
            id: '$_oculumTheftBuffPrefix$stat',
            type: 'modifica_statistica',
            target: stat,
            valueExpression: '$bonus',
            mode: 'temporaneo',
            duration: '$remaining',
          ),
      ],
      source: source,
      applyFusionBonus: false,
    );
    aggiungiLog(
      '[$source] +$bonus a tutte le statistiche · $remaining turni personali rimasti.',
    );
  }

  void clearOculumTheftFight() {
    planarState.remove(_oculumTheftBuffCast);
    activeStructuredEffects.removeWhere(
      (effect) => '${effect['effectId']}'.startsWith(_oculumTheftBuffPrefix),
    );
  }
}
