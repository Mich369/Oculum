part of '../../main.dart';

const _bunnysHelpMode = 'bunnys_heal';
const _bunnysOutbound = 'bunnysOutbound';
final _bunnysCureInProgress = Expando<bool>();

extension _OculumBunnys on _OculumHomePageState {
  Map<String, dynamic>? _bunnysCombatToken(String tag) => onlineCombatTokens()
      .where((token) => combatTokenMatchesSheet(token, tag))
      .firstOrNull;

  bool _bunnysCanHeal(
    Map<String, dynamic> source,
    Map<String, dynamic> target, {
    required bool atDeath,
  }) =>
      !oculumSameSheetIdentity(
        onlineCombatTokenTag(source),
        onlineCombatTokenTag(target),
      ) &&
      combatParticipantsShareTeam(source, target) == atDeath &&
      onlineCombatTokenTag(target).isNotEmpty &&
      source['outsideFight'] != true &&
      target['outsideFight'] != true &&
      !masterInitiativeTokenIsDead(target) &&
      !const {'fled', 'expired'}.contains(target['status']) &&
      target['mechaOccupied'] != true;

  int _bunnysTargetLevel(Map<String, dynamic> target) {
    final index = localSheetIndexForOculumTag(onlineCombatTokenTag(target));
    return index >= 0 &&
            (realtimeIsMasterRole ||
                schedePersonaggio[index]['realtimeSharedSheet'] != true)
        ? sheetCriticalLevelAt(index)
        : max(0, readIntValue(target['level']));
  }

  Future<bool> _useBunnysCure({
    required String label,
    required OculumStructuredEffect effect,
    required Future<bool> Function(int cost, bool Function() valid) activate,
  }) async {
    if (_bunnysCureInProgress[this] == true ||
        outsideFight ||
        !currentCombatIsActive() ||
        hpCorrenti() <= 0) {
      return false;
    }
    final tag = sheetTagAt(schedaCorrente);
    final source = _bunnysCombatToken(tag);
    if (source == null || !controlsOnlineCombatSheet(tag)) return false;
    final encounter = onlineCombatEncounterId;
    final scope = permissionScope;
    final fight = combatSubtraitExperienceFightId(encounter, ownerTag: tag);
    final targets = onlineCombatTokens()
        .where((target) => _bunnysCanHeal(source, target, atDeath: false))
        .toList(growable: false);
    if (targets.isEmpty) return false;
    _bunnysCureInProgress[this] = true;
    try {
      final selection = await oculumShowDialogUntilClosed<String>(
        context: context,
        builder: (dialog) => SimpleDialog(
          title: Text(label),
          children: [
            for (final target in targets)
              SimpleDialogOption(
                onPressed: _bunnysTargetLevel(target) <= currentOculum()
                    ? () => Navigator.pop(dialog, onlineCombatTokenTag(target))
                    : null,
                child: Text(
                  '${oculumReferenceEncounterTokenName(target)} · '
                  '${_bunnysTargetLevel(target)} Oculum',
                ),
              ),
            TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: Text(t('Annulla', 'Cancel')),
            ),
          ],
        ),
      );
      if (!mounted || selection == null) return false;
      final target = _bunnysCombatToken(selection);
      if (target == null) return false;
      final price = _bunnysTargetLevel(target);
      bool stillValid() {
        if (!mounted ||
            permissionScope != scope ||
            onlineCombatEncounterId != encounter ||
            sheetTagAt(schedaCorrente) != tag ||
            combatSubtraitExperienceFightId(encounter, ownerTag: tag) !=
                fight ||
            !currentCombatIsActive() ||
            outsideFight ||
            hpCorrenti() <= 0) {
          return false;
        }
        final currentTarget = _bunnysCombatToken(selection);
        final currentSource = _bunnysCombatToken(tag);
        return currentTarget != null &&
            currentSource != null &&
            _bunnysTargetLevel(currentTarget) == price &&
            _bunnysCanHeal(currentSource, currentTarget, atDeath: false);
      }

      if (!stillValid() || !await activate(price, stillValid) || !mounted) {
        return false;
      }
      final percent = oculumEvaluateStructuredEffectValue(
        effect,
        variables: formulaValueContext(),
        subtraits: hiddenEyeStats,
      ).clamp(0, 100).toInt();
      final request = _buildBunnysHeal(
        source: tag,
        target: selection,
        fight: fight,
        encounter: encounter,
        percent: percent,
        atDeath: false,
      );
      if (realtimeService?.isConnected == true) {
        attachPendingCombatTurnResources(request);
        _queueBunnysHeal(request);
        programmaSalvataggio();
        await sendQueuedBunnysHeal(request);
      } else {
        _claimBunnysHeal(request);
      }
      return true;
    } finally {
      _bunnysCureInProgress[this] = null;
    }
  }

  void resolveBunnysDeathHealing(int index, Map<String, dynamic> token) {
    if (!mounted ||
        !currentCombatIsActive() ||
        (realtimeService?.isConnected == true && !realtimeIsMasterRole) ||
        !masterInitiativeTokenIsDead(token)) {
      return;
    }
    final sheet = schedePersonaggio[index];
    final localTag = sheetTagAt(index);
    if ((!controlsOnlineCombatSheet(localTag) &&
            !(realtimeService?.isConnected == true && realtimeIsMasterRole)) ||
        '${sheet['monsterBookSourceId'] ?? ''}'.split('_variante_').first !=
            'bunnys' ||
        token['outsideFight'] == true) {
      return;
    }
    final tag = onlineCombatTokenTag(token);
    final encounter = onlineCombatEncounterId;
    final fight = combatSubtraitExperienceFightId(encounter, ownerTag: tag);
    final online = realtimeService?.isConnected == true;
    if (tag.isEmpty ||
        encounter.isEmpty ||
        _bunnysCombatToken(tag) == null ||
        (token['fightInstanceId'] != null &&
            token['fightInstanceId'] != fight)) {
      return;
    }
    // Defer sheet switching and publishing until the current death update ends.
    final scope = permissionScope;
    scheduleMicrotask(() async {
      if (!mounted ||
          permissionScope != scope ||
          onlineCombatEncounterId != encounter ||
          combatSubtraitExperienceFightId(encounter, ownerTag: tag) != fight ||
          (online && !realtimeIsMasterRole)) {
        return;
      }
      final source = _bunnysCombatToken(tag);
      if (source == null || !masterInitiativeTokenIsDead(source)) return;
      final currentIndex = localSheetIndexForOculumTag(localTag);
      if (currentIndex < 0) return;
      final ledger = currentIndex == schedaCorrente
          ? planarState
          : Map<String, dynamic>.from(
              schedePersonaggio[currentIndex]['planarRuntime'] as Map? ?? {},
            );
      if (ledger['bunnysDeathFight'] == fight) return;
      final passives = currentIndex == schedaCorrente
          ? skills
          : (schedePersonaggio[currentIndex]['skills'] as List? ?? const [])
                .whereType<Map>()
                .map(
                  (skill) =>
                      CharacterSkill.fromJson(Map<String, dynamic>.from(skill)),
                );
      final passive = passives
          .where((skill) => skill.equipaggiata && skill.passiva)
          .expand((skill) => skill.forme)
          .where(
            (form) =>
                readIntValue(form.livello) <=
                sheetCriticalLevelAt(currentIndex),
          )
          .expand((form) => form.effettiStrutturati)
          .where(
            (effect) =>
                effect.type == 'planar' &&
                effect.target == oculumBunnysDeathHealSkill,
          )
          .lastOrNull;
      if (passive?.enabled == false) return;
      final percent = passive == null
          ? 50
          : oculumEvaluateStructuredEffectValue(
              passive,
              variables: const {},
            ).clamp(0, 100).toInt();
      final targets = onlineCombatTokens()
          .where((target) => _bunnysCanHeal(source, target, atDeath: true))
          .map(onlineCombatTokenTag)
          .toSet();
      final requests = [
        for (final target in targets)
          _buildBunnysHeal(
            source: tag,
            target: target,
            fight: fight,
            encounter: encounter,
            percent: percent,
            atDeath: true,
          ),
      ];
      if (online) {
        for (final request in requests) {
          _queueBunnysHeal(request);
        }
      }
      ledger['bunnysDeathFight'] = fight;
      if (currentIndex != schedaCorrente) {
        schedePersonaggio[currentIndex]['planarRuntime'] = ledger;
      }
      programmaSalvataggio();
      for (final request in requests) {
        if (online) {
          await sendQueuedBunnysHeal(request);
        } else {
          _claimBunnysHeal(request);
        }
      }
    });
  }

  Map<String, dynamic> _buildBunnysHeal({
    required String source,
    required String target,
    required String fight,
    required String encounter,
    required int percent,
    required bool atDeath,
  }) {
    final mode = atDeath ? 'death' : 'cure';
    return <String, dynamic>{
      'id': atDeath
          ? 'bunnys:$mode:$fight:$source:$target'
          : 'bunnys:$mode:$source:${DateTime.now().microsecondsSinceEpoch}',
      'kind': 'help',
      'helpMode': _bunnysHelpMode,
      'scope': permissionScope,
      'encounterId': encounter,
      'fightInstanceId': fight,
      'sourceTag': source,
      'targetTag': target,
      'sourceName': atDeath ? 'Pelo sulla ferita' : 'Leccata dei Bunnys',
      'targetName': '${_bunnysCombatToken(target)?['name'] ?? target}',
      'bunnysDeath': atDeath,
      'bunnysHealPercent': percent,
      'status': 'pending',
    };
  }

  void _queueBunnysHeal(Map<String, dynamic> request) {
    request[_bunnysOutbound] = true;
    onlineCombatRequests.putIfAbsent('${request['id']}', () => request);
  }

  Future<void> sendQueuedBunnysHeal(Map<String, dynamic> request) async {
    final service = realtimeService;
    final source = '${request['sourceTag']}';
    final target = '${request['targetTag']}';
    final encounter = onlineCombatEncounterId;
    if (!mounted ||
        service?.isConnected != true ||
        request[_bunnysOutbound] != true ||
        request['helpAcknowledged'] == true ||
        request['scope'] != permissionScope ||
        request['encounterId'] != encounter ||
        request['fightInstanceId'] !=
            combatSubtraitExperienceFightId(encounter, ownerTag: source) ||
        !currentCombatIsActive() ||
        (request['bunnysDeath'] == true
            ? !realtimeIsMasterRole
            : !oculumSameSheetIdentity(source, sheetTagAt(schedaCorrente)))) {
      return;
    }
    final envelope = permissionEnvelope({...request}..remove(_bunnysOutbound));
    if (controlsOnlineCombatSheet(target)) _claimBunnysHeal(envelope);
    await service!.sendCombatEvent('combat_help', envelope);
    if (mounted) programmaSalvataggio();
  }

  bool validBunnysHeal(Map<String, dynamic> payload) {
    final id = '${payload['id'] ?? ''}';
    final source = '${payload['sourceTag'] ?? ''}';
    final target = '${payload['targetTag'] ?? ''}';
    final percent = readIntValue(payload['bunnysHealPercent']);
    final atDeath = payload['bunnysDeath'] == true;
    final encounter = onlineCombatEncounterId;
    final fight = combatSubtraitExperienceFightId(encounter, ownerTag: source);
    if (payload['kind'] != 'help' ||
        payload['helpMode'] != _bunnysHelpMode ||
        !validPermissionSender(payload) ||
        (atDeath
            ? payload['senderRole'] != 'master'
            : !oculumSameSheetIdentity(payload['senderTag'], source)) ||
        payload['encounterId'] != encounter ||
        payload['fightInstanceId'] != fight ||
        percent < 0 ||
        percent > 100 ||
        (atDeath
            ? id != 'bunnys:death:$fight:$source:$target'
            : !id.startsWith('bunnys:cure:$source:')) ||
        !currentCombatIsActive()) {
      return false;
    }
    final caster = _bunnysCombatToken(source);
    final recipient = _bunnysCombatToken(target);
    return caster != null &&
        recipient != null &&
        (!atDeath ||
            monsterBookIdForCombatToken(caster).split('_variante_').first ==
                'bunnys') &&
        (atDeath || !masterInitiativeTokenIsDead(caster)) &&
        _bunnysCanHeal(caster, recipient, atDeath: atDeath);
  }

  void receiveBunnysHeal(Map<String, dynamic> payload) {
    if (validBunnysHeal(payload)) {
      _claimBunnysHeal({...payload}..remove(_bunnysOutbound));
    }
  }

  void _claimBunnysHeal(Map<String, dynamic> request) {
    final target = '${request['targetTag']}';
    if (!controlsOnlineCombatSheet(target)) return;
    final index = localSheetIndexForOculumTag(target);
    if (index < 0) return;
    final id = '${request['id']}';
    final previous = onlineCombatRequests[id];
    if (previous?['received'] == true) {
      unawaited(sendCombatAcknowledgement(previous!, 'help'));
      return;
    }
    final receipt = {
      ...?previous,
      ...request,
      'received': true,
      'status': 'resolved',
    };
    onlineCombatRequests[id] = receipt;
    final percent = readIntValue(request['bunnysHealPercent']);
    applySupportToOwnedSheet(index, [
      OculumStructuredEffect(
        id: 'bunnys_current_life',
        type: 'cura',
        resource: 'vita',
        valueExpression: 'hp_current * $percent / 100',
        duration: '0',
      ),
    ], '${request['sourceName']}');
    if (realtimeService?.isConnected == true) {
      unawaited(sendCombatAcknowledgement(receipt, 'help'));
    }
    if (mounted) {
      programmaSalvataggio();
      refreshOculumHome(() {});
    }
  }
}
