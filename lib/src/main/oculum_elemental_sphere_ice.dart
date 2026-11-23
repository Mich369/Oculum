part of '../../main.dart';

const oculumElementalSphereIceCondition = 'elemental_sphere_ice';
const _elementalSphereIceReleaseDifficultyKey = 'releaseDifficulty';
const _elementalSphereIceHelpMode = 'elemental_sphere_ice_shatter';
const _elementalSphereIceInstanceKey = 'elementalSphereIceInstance';
const _elementalSphereHeatKey = 'elementalSphereHeat';

int oculumElementalSphereIceReleaseDifficulty(int level, int grade) =>
    10 + max<int>(0, level) + 2 * max<int>(0, grade);

extension _OculumElementalSphereIce on _OculumHomePageState {
  OculumConditionInstance? get elementalSphereIce =>
      getCondition(oculumElementalSphereIceCondition);

  bool get elementalSphereFrozen => elementalSphereIce != null;

  bool elementalSphereFrozenInSheet(Map sheet) =>
      (sheet['conditions'] as List? ?? const []).whereType<Map>().any(
        (condition) =>
            (condition['conditionType'] ?? condition['type']) ==
            oculumElementalSphereIceCondition,
      );

  bool applyElementalSphereFreeze(
    Map request, {
    required int durationTurns,
    required String difficulty,
  }) {
    final applied = applyCondition(
      oculumElementalSphereIceCondition,
      duration: max(
        1,
        (durationTurns > 0 ? durationTurns : 3) +
            oculumElementalSphereDifficulty(difficulty).turns,
      ),
      source: 'Sfera Gelo',
      metadata: {
        _elementalSphereIceInstanceKey: DateTime.now().microsecondsSinceEpoch
            .toString(),
        _elementalSphereIceReleaseDifficultyKey:
            oculumElementalSphereIceReleaseDifficulty(
              readIntValue(request['level']),
              readIntValue(request['grade']),
            ),
      },
    );
    if (applied) _publishElementalSphereIceChange();
    return applied;
  }

  bool shatterElementalSphereIce() {
    final ice = elementalSphereIce;
    return ice != null && removeCondition(ice, force: true, expired: true);
  }

  bool _canThawElementalSphereIceWithHeat() =>
      scrollMatchesUsableElement({'element': 'fuoco'}) ||
      scrollMatchesUsableElement({'element': 'lava'});

  String get _activeElementalSphereIceInstance {
    final ice = elementalSphereIce;
    return ice == null
        ? ''
        : '${ice.metadata[_elementalSphereIceInstanceKey] ?? ice.id}';
  }

  void _publishElementalSphereIceChange() {
    if (realtimeService?.isConnected != true) return;
    final tag = sheetTagAt(schedaCorrente);
    scheduleMicrotask(() {
      if (!mounted) return;
      final index = localSheetIndexForOculumTag(tag);
      if (index < 0 || !controlsOnlineCombatSheet(tag)) return;
      if (realtimeIsMasterRole) {
        syncSharedSheetToMasterEncounters(index);
      } else {
        if (index == schedaCorrente) salvaSchedaCorrenteInMemoria();
        sendRealtimeSheetToStaffAt(
          index,
          force: true,
          ensureMasterReceipt: true,
        );
      }
    });
  }

  String _elementalSphereIceForToken(Map<String, dynamic> token) {
    final tag = onlineCombatTokenTag(token);
    final index = localSheetIndexForOculumTag(tag);
    if (index >= 0 && controlsOnlineCombatSheet(tag)) {
      if (index == schedaCorrente) return _activeElementalSphereIceInstance;
      final conditions = schedePersonaggio[index]['conditions'];
      if (conditions is! List) return '';
      final ice = conditions
          .whereType<Map>()
          .where(
            (item) =>
                item['conditionType'] == oculumElementalSphereIceCondition,
          )
          .firstOrNull;
      final metadata = ice?['metadata'];
      final instance = metadata is Map
          ? metadata[_elementalSphereIceInstanceKey]
          : null;
      return '${instance ?? ice?['id'] ?? ''}';
    }
    final state = token['faunaPublic'];
    return state is Map ? '${state[_elementalSphereIceInstanceKey] ?? ''}' : '';
  }

  Map<String, dynamic>? _elementalSphereIceCombatToken(String tag) =>
      onlineCombatTokens()
          .where((token) => combatTokenMatchesSheet(token, tag))
          .firstOrNull;

  bool _isElementalSphereIceAlly(
    Map<String, dynamic> caster,
    Map<String, dynamic> ally,
  ) =>
      !oculumSameSheetIdentity(
        onlineCombatTokenTag(caster),
        onlineCombatTokenTag(ally),
      ) &&
      combatParticipantsShareTeam(caster, ally) &&
      ally['outsideFight'] != true &&
      !masterInitiativeTokenIsDead(ally) &&
      !const {'fled', 'expired'}.contains(ally['status']);

  List<({Map<String, dynamic> token, String ice})>
  _elementalSphereIceAllyTargets() {
    if (outsideFight ||
        hpCorrenti() <= 0 ||
        elementalSphereFrozen ||
        elementalSphereSoulSeparated ||
        !currentCombatIsActive() ||
        !_canSpendElementalSphereIceReleaseAction() ||
        !_canThawElementalSphereIceWithHeat()) {
      return const [];
    }
    final source = _elementalSphereIceCombatToken(sheetTagAt(schedaCorrente));
    if (source == null) return const [];
    return [
      for (final ally in onlineCombatTokens())
        if (_isElementalSphereIceAlly(source, ally))
          if (_elementalSphereIceForToken(ally) case final ice
              when ice.isNotEmpty)
            (token: ally, ice: ice),
    ];
  }

  bool get canShatterElementalSphereIceForAlly =>
      _elementalSphereIceAllyTargets().isNotEmpty;

  Future<void> selectElementalSphereIceAlly() async {
    if (_elementalSphereIceReleaseInFlight) return;
    final candidates = _elementalSphereIceAllyTargets();
    if (candidates.isEmpty) return;
    final source = sheetTagAt(schedaCorrente);
    final scope = permissionScope;
    final encounter = onlineCombatEncounterId;
    final turn = _turnSpendRetryTurn()?.key;
    _elementalSphereIceReleaseInFlight = true;
    try {
      final chosen =
          await oculumShowDialogUntilClosed<({String target, String ice})>(
            context: context,
            builder: (dialog) => SimpleDialog(
              title: Text(t('Colpisci il ghiaccio', 'Shatter the ice')),
              children: [
                for (final candidate in candidates)
                  SimpleDialogOption(
                    onPressed: () => Navigator.pop(dialog, (
                      target: onlineCombatTokenTag(candidate.token),
                      ice: candidate.ice,
                    )),
                    child: Text(
                      oculumReferenceEncounterTokenName(candidate.token),
                    ),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(dialog),
                  child: Text(t('Annulla', 'Cancel')),
                ),
              ],
            ),
          );
      if (!mounted ||
          chosen == null ||
          source != sheetTagAt(schedaCorrente) ||
          scope != permissionScope ||
          encounter != onlineCombatEncounterId ||
          turn == null ||
          turn != _turnSpendRetryTurn()?.key) {
        return;
      }
      await _useElementalSphereIceAlly(chosen.target, chosen.ice);
    } finally {
      _elementalSphereIceReleaseInFlight = false;
    }
  }

  Future<bool> _useElementalSphereIceAlly(String target, String ice) async {
    if (!_elementalSphereIceAllyTargets().any(
      (candidate) =>
          onlineCombatTokenTag(candidate.token) == target &&
          candidate.ice == ice,
    )) {
      return false;
    }
    final source = sheetTagAt(schedaCorrente);
    final encounter = onlineCombatEncounterId;
    final turn = _turnSpendRetryTurn()?.key;
    if (encounter.isEmpty || turn == null) return false;
    final request = <String, dynamic>{
      'id': 'sphere-ice:${DateTime.now().microsecondsSinceEpoch}:$source',
      'scope': permissionScope,
      'kind': 'help',
      'helpMode': _elementalSphereIceHelpMode,
      'sourceTag': source,
      'targetTag': target,
      'encounterId': encounter,
      'fightInstanceId': combatSubtraitExperienceFightId(
        encounter,
        ownerTag: target,
      ),
      'iceInstance': ice,
      'iceTurnKey': turn,
      'status': 'pending',
    };
    final service = realtimeService;
    if (service?.isConnected == true && !realtimeIsMasterRole) {
      onlineCombatRequests['${request['id']}'] = request;
      programmaSalvataggio();
      final sent = await _replayElementalSphereIceAlly(request);
      if (!sent && mounted) {
        aggiungiLog(
          t(
            'Il Master non ha ricevuto il tentativo di rompere il ghiaccio.',
            'The Master did not receive the attempt to break the ice.',
          ),
        );
      }
      return sent;
    }
    if ((!controlsOnlineCombatSheet(target) && service?.isConnected != true) ||
        !await requestUtilitySpend(
          'azione',
          preferFreeReaction: false,
          deferMasterTurn: true,
        )) {
      return false;
    }
    if (mounted &&
        onlineCombatEncounterId == encounter &&
        sheetTagAt(schedaCorrente) == source) {
      _finishElementalSphereIceAlly(permissionEnvelope(request));
    }
    return true;
  }

  void receiveElementalSphereIceAlly(Map<String, dynamic> payload) {
    final approved = payload['iceApproved'] == true;
    if (!validPermissionSender(payload, staff: approved) ||
        (approved && payload['senderRole'] != 'master') ||
        (!approved && !realtimeIsMasterRole) ||
        !currentCombatIsActive() ||
        payload['encounterId'] != onlineCombatEncounterId) {
      return;
    }
    final source = '${payload['sourceTag'] ?? ''}';
    final target = '${payload['targetTag'] ?? ''}';
    final id = '${payload['id'] ?? ''}';
    final ice = '${payload['iceInstance'] ?? ''}';
    final encounter = onlineCombatEncounterId;
    if (source.isEmpty ||
        target.isEmpty ||
        id.length > 160 ||
        !id.startsWith('sphere-ice:') ||
        ice.isEmpty ||
        payload['fightInstanceId'] !=
            combatSubtraitExperienceFightId(encounter, ownerTag: target)) {
      return;
    }
    if (approved) {
      final request = onlineCombatRequests[id];
      if (request != null &&
          request['sourceTag'] == source &&
          request['targetTag'] == target &&
          request['iceInstance'] == ice) {
        request['helpAcknowledged'] = true;
        request['status'] = 'resolved';
        programmaSalvataggio();
      }
      _applyElementalSphereIceAlly(payload);
      return;
    }
    if (!oculumSameSheetIdentity(payload['senderTag'], source)) return;
    final earlier = onlineCombatRequests[id];
    if (earlier != null) {
      if (earlier['iceApproved'] == true &&
          earlier['sourceTag'] == source &&
          earlier['targetTag'] == target &&
          earlier['iceInstance'] == ice) {
        unawaited(_sendApprovedElementalSphereIce(earlier));
      }
      return;
    }
    final caster = _elementalSphereIceCombatToken(source);
    final ally = _elementalSphereIceCombatToken(target);
    final projection = caster?['faunaPublic'];
    if (caster == null ||
        ally == null ||
        caster['outsideFight'] == true ||
        !masterInitiativeTokenCanAct(caster) ||
        masterInitiativeTokenIsTemporary(caster) ||
        projection is! Map ||
        projection[_elementalSphereHeatKey] != true ||
        _elementalSphereIceForToken(caster).isNotEmpty ||
        projection['elementalSphereSoulSeparated'] == true ||
        !_isElementalSphereIceAlly(caster, ally) ||
        _elementalSphereIceForToken(ally) != ice ||
        onlineCombatRequests.values.any(
          (request) =>
              request['helpMode'] == _elementalSphereIceHelpMode &&
              request['iceApproved'] == true &&
              request['scope'] == permissionScope &&
              request['encounterId'] == encounter &&
              request['targetTag'] == target &&
              request['iceInstance'] == ice,
        ) ||
        payload['iceTurnKey'] != _turnSpendRetryTurn()?.key ||
        !_consumeLocalCombatTurnResource(
          source,
          'azione',
          advanceMasterTurn: false,
        )) {
      return;
    }
    _finishElementalSphereIceAlly(payload);
  }

  void _finishElementalSphereIceAlly(Map<String, dynamic> request) {
    final approved = {...request, 'iceApproved': true, 'status': 'resolved'};
    onlineCombatRequests['${request['id']}'] = approved;
    _applyElementalSphereIceAlly(approved);
    unawaited(_sendApprovedElementalSphereIce(approved));
    advanceMasterInitiativeAfterAction('${request['sourceTag']}');
    unawaited(flushPendingCombatTurnResources());
    programmaSalvataggio();
  }

  Future<bool> _replayElementalSphereIceAlly(
    Map<String, dynamic> request,
  ) async {
    final service = realtimeService;
    if (service?.isConnected != true ||
        request['scope'] != permissionScope ||
        request['encounterId'] != onlineCombatEncounterId) {
      return false;
    }
    if (request['iceApproved'] == true) {
      return _sendApprovedElementalSphereIce(request);
    }
    if (request['status'] != 'pending' ||
        request['sourceTag'] != sheetTagAt(schedaCorrente) ||
        request['iceTurnKey'] != _turnSpendRetryTurn()?.key) {
      return false;
    }
    return service!.sendCombatEvent('combat_help', permissionEnvelope(request));
  }

  Future<bool> _sendApprovedElementalSphereIce(
    Map<String, dynamic> request,
  ) async {
    final service = realtimeService;
    final ownTag = ownPermissionTags.contains(sheetTagAt(schedaCorrente))
        ? sheetTagAt(schedaCorrente)
        : ownPermissionTags.firstOrNull;
    if (!realtimeIsMasterRole ||
        service?.isConnected != true ||
        request['helpAcknowledged'] == true ||
        ownTag == null) {
      return false;
    }
    return service!.sendCombatEvent('combat_help', {
      ...permissionEnvelope(request),
      'senderTag': ownTag,
    });
  }

  void _applyElementalSphereIceAlly(Map<String, dynamic> request) {
    final target = '${request['targetTag']}';
    final source = '${request['sourceTag']}';
    final instance = '${request['iceInstance']}';
    final caster = _elementalSphereIceCombatToken(source);
    final ally = _elementalSphereIceCombatToken(target);
    if (caster == null ||
        ally == null ||
        !_isElementalSphereIceAlly(caster, ally)) {
      return;
    }
    faunaForOwnedSheet(target, () {
      if (_activeElementalSphereIceInstance == instance) {
        shatterElementalSphereIce();
      }
      unawaited(sendCombatAcknowledgement(request, 'help'));
    });
  }

  bool _canSpendElementalSphereIceReleaseAction() {
    if (!currentTurnTrackerIsActive()) return false;
    final tokens = _writableOnlineCombatTokens();
    final active = _usesLocalMasterInitiative
        ? masterInitiativeActiveIndex
        : readIntValue(realtimeVisibleInitiativeSnapshot['activeIndex']);
    if (active < 0 || active >= tokens.length) return false;
    final token = tokens[active];
    return combatTokenMatchesSheet(token, sheetTagAt(schedaCorrente)) &&
        masterInitiativeTokenCanAct(token) &&
        !masterInitiativeTokenIsTemporary(token) &&
        (!readBoolValue(token['actionUsed']) ||
            readIntValue(token['kiExtraActions']) > 0) &&
        artDebtForToken(token, 'action') <= 0;
  }

  int _elementalSphereIceReleaseDifficulty(OculumConditionInstance ice) =>
      readIntValue(
        ice.metadata[_elementalSphereIceReleaseDifficultyKey],
        fallback: 10,
      );

  Future<void> _attemptElementalSphereIceRelease(
    OculumConditionInstance ice, {
    required bool withHeat,
    int? natural,
  }) async {
    if (!identical(ice, elementalSphereIce) ||
        _elementalSphereIceReleaseInFlight ||
        !_canSpendElementalSphereIceReleaseAction() ||
        (withHeat && !_canThawElementalSphereIceWithHeat())) {
      return;
    }
    _elementalSphereIceReleaseInFlight = true;
    final tag = currentSheetScrollId();
    final combatTag = sheetTagAt(schedaCorrente);
    final encounter = onlineCombatEncounterId;
    final scope = permissionScope;
    try {
      if (!await requestUtilitySpend(
            'azione',
            preferFreeReaction: false,
            elementalSphereIceRelease: ice,
          ) ||
          !mounted ||
          tag != currentSheetScrollId() ||
          encounter != onlineCombatEncounterId ||
          scope != permissionScope ||
          !identical(ice, elementalSphereIce)) {
        return;
      }
      final difficulty = _elementalSphereIceReleaseDifficulty(ice);
      final total = withHeat
          ? null
          : rollTotalWithCritical(natural ?? tiraD20(), 20, [
              volontaTotale(),
              tiroGlobaleBonus(),
            ]);
      final freed = total == null || total >= difficulty;
      if (freed) shatterElementalSphereIce();
      aggiungiLog(
        total == null
            ? t(
                'Fuoco o Lava sciolgono il ghiaccio.',
                'Fire or Lava melts the ice.',
              )
            : t(
                'Liberazione dal ghiaccio · Volontà $total / DT $difficulty: '
                    '${freed ? 'libero.' : 'ancora congelato.'}',
                'Break free from the ice · Will $total / DC $difficulty: '
                    '${freed ? 'free.' : 'still frozen.'}',
              ),
      );
      programmaSalvataggio();
      unawaited(flushPendingCombatTurnResources());
      advanceMasterInitiativeAfterAction(combatTag);
    } finally {
      _elementalSphereIceReleaseInFlight = false;
    }
  }

  Widget elementalSphereIceControls({required VoidCallback refresh}) {
    final ice = elementalSphereIce;
    if (ice == null) return const SizedBox.shrink();
    final canTry =
        !_elementalSphereIceReleaseInFlight &&
        _canSpendElementalSphereIceReleaseAction();

    Future<void> attempt({required bool withHeat}) async {
      final pending = _attemptElementalSphereIceRelease(
        ice,
        withHeat: withHeat,
      );
      refresh();
      await pending;
      refresh();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${conditionLabel(ice)} · DT ${_elementalSphereIceReleaseDifficulty(ice)}',
        ),
        Wrap(
          spacing: 6,
          children: [
            OutlinedButton(
              key: const ValueKey('elemental_sphere_ice_will'),
              onPressed: canTry ? () => attempt(withHeat: false) : null,
              child: Text(t('Volontà · 1 Azione', 'Will · 1 Action')),
            ),
            if (_canThawElementalSphereIceWithHeat())
              OutlinedButton(
                key: const ValueKey('elemental_sphere_ice_heat'),
                onPressed: canTry ? () => attempt(withHeat: true) : null,
                child: Text(
                  t(
                    'Scongela · Fuoco o Lava · 1 Azione',
                    'Thaw · Fire or Lava · 1 Action',
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
