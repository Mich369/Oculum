part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

const oculumAberionMonsterId = 'ciclo_uomo_cactus_variante_aberion';
const oculumAberionMaxOculum = 10;

int oculumAberionDamageBonus(int paid) =>
    paid.clamp(0, oculumAberionMaxOculum) * 3 ~/ 2;

List<int> oculumAberionAllocatePaidOculum(List<int> investment, int paid) {
  var remaining = max(0, paid);
  final allocated = <int>[];
  for (final units in investment) {
    final share = min(remaining, units.clamp(0, oculumAberionMaxOculum));
    allocated.add(share);
    remaining -= share;
  }
  return allocated;
}

String oculumCelestialAllegiance(Map sheet) {
  final explicit =
      '${(sheet['planarRuntime'] as Map? ?? {})['identityCelestial'] ?? ''}';
  if (const {'solare', 'lunare', 'nessuna'}.contains(explicit)) return explicit;
  final source = oculumSavedMonsterBookEntryById(
    '${sheet['monsterBookSourceId'] ?? ''}',
  );
  final catalogueIdentity =
      '${source?.encounterRules['celestialIdentity'] ?? ''}';
  if (const {'solare', 'lunare', 'nessuna'}.contains(catalogueIdentity)) {
    return catalogueIdentity;
  }
  if (sheet['monsterBookSourceId'] == 'ciclo_solare_siccita') return 'solare';
  if (sheet['monsterBookSourceId'] == 'ciclo_lupo_lunare') return 'lunare';
  return '${sheet['razza'] ?? ''}'.toLowerCase().contains('mhunan')
      ? 'lunare'
      : 'nessuna';
}

int oculumCycleCelestialDamage(
  int damage, {
  required String source,
  required String target,
  int sourceSolarPercent = 0,
  int targetSolarPercent = 0,
}) {
  final percent = source == 'solare' && target == 'lunare'
      ? sourceSolarPercent
      : source == 'lunare' && target == 'solare'
      ? targetSolarPercent
      : 0;
  return (max(0, damage) * (1 + max(0, percent) / 100)).floor();
}

int oculumCycleSpineDamage(int base, Iterable<String> prior, String target) {
  final same = prior.where((tag) => tag == target).length;
  final other = prior.where((tag) => tag != target).length;
  return (max(0, base) * (1 + .05 * same + .10 * other)).floor();
}

int oculumSkeletonThrowMetres(int natural, int attack, int defense) =>
    max(0, attack - defense - (natural <= 17 ? 2 : 0));
int oculumSkeletonThrowDifficulty(int natural, int attack, int metres) =>
    natural >= 20
    ? attack * 2
    : natural == 19
    ? 16 + metres
    : natural == 18
    ? 13 + metres
    : attack;
bool oculumSkeletonThrowRecovered(
  int natural,
  int attack,
  int metres,
  int total,
) => natural >= 20
    ? total >= attack * 2
    : total > oculumSkeletonThrowDifficulty(natural, attack, metres);

const _imbrytoadSpitKey = 'imbrytoadSpit';

extension _OculumImbrytoadSpit on _OculumHomePageState {
  bool allowImbrytoadSpitDeclaration(Iterable<OculumStructuredEffect> effects) {
    if (faunaCurrentMonsterId != oculumImbrytoadId ||
        !effects.any(
          (effect) => effect.enabled && oculumIsImbrytoadSpitEffect(effect.id),
        )) {
      return true;
    }
    if (currentCombatIsActive() &&
        !outsideFight &&
        imbrytoadSpitWindow == null &&
        _imbrytoadTokenFor(sheetTagAt(schedaCorrente)) != null) {
      return true;
    }
    aggiungiLog('[IMBRYTOAD] Serve un Fight senza uno Sputo già dichiarato.');
    return false;
  }

  Map<String, dynamic>? _imbrytoadTokenFor(String tag) =>
      _writableOnlineCombatTokens()
          .where((token) => combatTokenMatchesSheet(token, tag))
          .firstOrNull;

  bool _imbrytoadTokenInFight(Map<String, dynamic> token) =>
      masterInitiativeTokenCanAct(token) && token['outsideFight'] != true;

  bool _imbrytoadWindowMatches(Map window, Map<String, dynamic> token) =>
      window['scope'] == permissionScope &&
      window['encounterId'] == onlineCombatEncounterId &&
      window['fightInstanceId'] == token['fightInstanceId'] &&
      _imbrytoadTokenInFight(token);

  Map<String, dynamic>? get imbrytoadSpitWindow {
    if (faunaCurrentMonsterId != oculumImbrytoadId || outsideFight) return null;
    final window = planarState[_imbrytoadSpitKey];
    if (window is! Map || window['id'] is! int) return null;
    final token = _imbrytoadTokenFor(sheetTagAt(schedaCorrente));
    return token != null && _imbrytoadWindowMatches(window, token)
        ? Map<String, dynamic>.from(window)
        : null;
  }

  Map<String, dynamic>? imbrytoadSpitWindowForToken(
    Map<String, dynamic> token,
  ) {
    if (monsterBookIdForCombatToken(token) != oculumImbrytoadId) return null;
    final tag = onlineCombatTokenTag(token);
    if (oculumSameSheetIdentity(tag, sheetTagAt(schedaCorrente)) &&
        controlsOnlineCombatSheet(tag)) {
      return imbrytoadSpitWindow;
    }
    final public = token['faunaPublic'];
    final window = public is Map ? public[_imbrytoadSpitKey] : null;
    return window is Map &&
            window['closed'] != true &&
            _imbrytoadWindowMatches(window, token)
        ? Map<String, dynamic>.from(window)
        : null;
  }

  Iterable<String> _imbrytoadTags(Object? raw) =>
      (raw is List ? raw : const []).whereType<String>();

  bool _imbrytoadCanRespondWithToken(Map<String, dynamic> token) =>
      _imbrytoadTokenInFight(token) &&
      masterInitiativeReactionAvailable(token, round: _onlineCombatRound()) > 0;

  bool _imbrytoadParticipantHasSheet(String tag) =>
      localSheetIndexForOculumTag(tag) >= 0 ||
      realtimeUsers.any(
        (user) =>
            _imbrytoadTags(user['localSheetTags']).contains(tag) ||
            user['activeSheetTag'] == tag,
      );

  void beginImbrytoadSpit() {
    if (faunaCurrentMonsterId != oculumImbrytoadId ||
        !currentCombatIsActive() ||
        outsideFight ||
        imbrytoadSpitWindow != null) {
      return;
    }
    final tag = sheetTagAt(schedaCorrente);
    final token = _imbrytoadTokenFor(tag);
    if (token == null || !_imbrytoadTokenInFight(token)) return;
    final team = combatParticipantTeamId(token);
    final window = <String, dynamic>{
      'id': DateTime.now().microsecondsSinceEpoch,
      'scope': permissionScope,
      'encounterId': onlineCombatEncounterId,
      'fightInstanceId': token['fightInstanceId'],
      'responders': [
        for (final opponent in _writableOnlineCombatTokens())
          if (_attackTokenIsOpponent(opponent, team) &&
              _imbrytoadCanRespondWithToken(opponent) &&
              _imbrytoadParticipantHasSheet(onlineCombatTokenTag(opponent)))
            onlineCombatTokenTag(opponent),
      ],
      'passed': <String>[],
    };
    planarState[_imbrytoadSpitKey] = window;
    aggiungiLog(
      '[IMBRYTOAD] Sputo dichiarato. Le due sacche si gonfiano: Reazioni avversarie aperte.',
    );
    _publishImbrytoadSpit(window);
  }

  void _publishImbrytoadSpit(Map<String, dynamic> window) {
    publishReferenceCreatureAnatomyState();
    if (_usesLocalMasterInitiative) sendRealtimeInitiativeSnapshotIfPublished();
    unawaited(
      realtimeService?.sendCombatEvent(
        'combat_scout',
        permissionEnvelope({
          'id': 'imbrytoad-${window['id']}',
          'imbrytoadSpitEvent': 'state',
          'sourceTag': sheetTagAt(schedaCorrente),
          'encounterId': onlineCombatEncounterId,
          'window': window,
        }),
      ),
    );
  }

  Iterable<Map<String, dynamic>> _imbrytoadReactionPackets(
    int id,
    String tag,
  ) => onlineCombatRequests.values.where(
    (request) =>
        request['scope'] == permissionScope &&
        request['encounterId'] == onlineCombatEncounterId &&
        request['imbrytoadSpitReaction'] == id &&
        request['targetTag'] == tag &&
        request['status'] != 'cancelled',
  );

  bool imbrytoadMaySpit(int id) {
    final window = imbrytoadSpitWindow;
    if (window == null || window['id'] != id || hpCorrenti() <= 0) return false;
    final tag = sheetTagAt(schedaCorrente);
    final packets = _imbrytoadReactionPackets(id, tag).toList();
    if (packets.any((packet) => packet['status'] != 'resolved')) return false;
    final passed = _imbrytoadTags(window['passed']).toSet();
    return _imbrytoadTags(window['responders']).every((responder) {
      final token = _imbrytoadTokenFor(responder);
      return passed.contains(responder) ||
          packets.any((packet) => packet['sourceTag'] == responder) ||
          token == null ||
          !_imbrytoadCanRespondWithToken(token);
    });
  }

  bool imbrytoadMayReact(String target, int id) {
    final token = _imbrytoadTokenFor(sheetTagAt(schedaCorrente));
    return token != null &&
        _imbrytoadCanRespondWithToken(token) &&
        _imbrytoadMayPass(target, id);
  }

  bool _imbrytoadMayPass(String target, int id) {
    final owner = _imbrytoadTokenFor(target);
    final responder = sheetTagAt(schedaCorrente);
    final token = _imbrytoadTokenFor(responder);
    if (owner == null ||
        token == null ||
        !_imbrytoadTokenInFight(token) ||
        !_attackTokenIsOpponent(token, combatParticipantTeamId(owner))) {
      return false;
    }
    final window = imbrytoadSpitWindowForToken(owner);
    return window?['id'] == id &&
        _imbrytoadTags(window?['responders']).contains(responder) &&
        !_imbrytoadTags(window?['passed']).contains(responder) &&
        !_imbrytoadReactionPackets(
          id,
          target,
        ).any((p) => p['sourceTag'] == responder);
  }

  void finishImbrytoadSpit(int id) {
    final window = imbrytoadSpitWindow;
    if (window?['id'] != id) return;
    planarState.remove(_imbrytoadSpitKey);
    aggiungiLog('[IMBRYTOAD] Sputa. Le due sacche si sgonfiano.');
    _publishImbrytoadSpit({...window!, 'closed': true});
  }

  void _recordImbrytoadPass(String target, String actor, int id) {
    faunaForOwnedSheet(target, () {
      final window = imbrytoadSpitWindow;
      if (window?['id'] != id ||
          !_imbrytoadTags(window?['responders']).contains(actor) ||
          _imbrytoadReactionPackets(
            id,
            target,
          ).any((p) => p['sourceTag'] == actor)) {
        return;
      }
      final passed = _imbrytoadTags(window?['passed']).toSet();
      if (!passed.add(actor)) return;
      final updated = {...window!, 'passed': passed.toList()};
      planarState[_imbrytoadSpitKey] = updated;
      _publishImbrytoadSpit(updated);
    });
  }

  void receiveImbrytoadSpitEvent(Map<String, dynamic> payload) {
    if (!validPermissionSender(payload) ||
        payload['encounterId'] != onlineCombatEncounterId ||
        payload['senderTag'] != payload['sourceTag']) {
      return;
    }
    if (payload['imbrytoadSpitEvent'] == 'pass') {
      final id = payload['windowId'];
      if (id is int) {
        _recordImbrytoadPass(
          '${payload['targetTag']}',
          '${payload['sourceTag']}',
          id,
        );
      }

      return;
    }
    final token = _imbrytoadTokenFor('${payload['sourceTag']}');
    final window = payload['window'];
    if (token == null ||
        monsterBookIdForCombatToken(token) != oculumImbrytoadId ||
        window is! Map ||
        window['id'] is! int ||
        !_imbrytoadWindowMatches(window, token)) {
      return;
    }
    final public = Map<String, dynamic>.from(
      token['faunaPublic'] as Map? ?? const {},
    );
    final previous = public[_imbrytoadSpitKey];
    if (previous is Map &&
        (readIntValue(previous['id']) > readIntValue(window['id']) ||
            previous['id'] == window['id'] && previous['closed'] == true)) {
      return;
    }
    public[_imbrytoadSpitKey] = {
      ...window,
      'passed': {
        if (previous is Map && previous['id'] == window['id'])
          ..._imbrytoadTags(previous['passed']),
        ..._imbrytoadTags(window['passed']),
      }.toList(),
    };
    token['faunaPublic'] = public;
    notifyActiveSheetSummaryChanged();
    programmaSalvataggio();
    if (_usesLocalMasterInitiative) sendRealtimeInitiativeSnapshotIfPublished();
    if (mounted) setState(() {});
  }

  Iterable<Widget> imbrytoadSpitActions(
    void Function(VoidCallback) select,
  ) sync* {
    final own = imbrytoadSpitWindow;
    if (own != null) {
      final id = own['id'] as int;
      yield ListTile(
        title: const Text('Sputa'),
        subtitle: Text(
          imbrytoadMaySpit(id)
              ? 'Le Reazioni si sono concluse.'
              : 'In attesa delle Reazioni avversarie.',
        ),
        enabled: imbrytoadMaySpit(id),
        onTap: () =>
            select(() => unawaited(planOnlineAttack(imbrytoadSpitId: id))),
      );
    }
    for (final token in _writableOnlineCombatTokens()) {
      final window = imbrytoadSpitWindowForToken(token);
      final target = onlineCombatTokenTag(token);
      final id = window?['id'];
      if (id is! int || !_imbrytoadMayPass(target, id)) continue;
      if (imbrytoadMayReact(target, id)) {
        yield ListTile(
          title: const Text('Reagisci allo Sputo'),
          subtitle: const Text(
            'Attacca Imbrytoad spendendo una Reazione. Puoi mirare alle sacche con Precisione.',
          ),
          onTap: () => select(
            () => unawaited(
              planOnlineAttack(targetId: target, imbrytoadReactionOf: id),
            ),
          ),
        );
      }
      yield ListTile(
        title: const Text('Passa la Reazione allo Sputo'),
        onTap: () => select(() {
          if (!_imbrytoadMayPass(target, id)) return;
          final actor = sheetTagAt(schedaCorrente);
          _recordImbrytoadPass(target, actor, id);
          unawaited(
            realtimeService?.sendCombatEvent(
              'combat_scout',
              permissionEnvelope({
                'id': 'imbrytoad-$id-pass-$actor',
                'imbrytoadSpitEvent': 'pass',
                'sourceTag': actor,
                'targetTag': target,
                'encounterId': onlineCombatEncounterId,
                'windowId': id,
              }),
            ),
          );
        }),
      );
    }
  }
}

extension OculumImbrytoadProbe on OculumPerformanceProbe {
  Map<String, dynamic>? imbrytoadWindow() => _state.imbrytoadSpitWindow;
  bool imbrytoadReady(int id) => _state.imbrytoadMaySpit(id);
  void receiveImbrytoadEvent(Map<String, dynamic> packet) =>
      _state.receiveImbrytoadSpitEvent(packet);
  Future<void> playImbrytoadSpit(int id, {int? total, int? natural}) =>
      _state.planOnlineAttack(
        imbrytoadSpitId: id,
        preparedAttackTotal: total,
        preparedAttackNatural: natural,
      );
}

extension _OculumCycleExpansion on _OculumHomePageState {
  Map<String, dynamic> get cycleRules => faunaCurrentMonsterId.isEmpty
      ? const {}
      : monsterBookEntryById(faunaCurrentMonsterId)?.encounterRules ?? const {};
  String get celestialAllegiance =>
      oculumCelestialAllegiance(schedePersonaggio[schedaCorrente]);
  String get cyclePhaseId => oculumPhaseForDay(oculumCurrentDay()).id;
  int get cycleFateGiftBonus {
    final bonus = readIntValue(planarState['cycleFateGiftBonus']);
    return bonus > 0 && !identityIsChaos && cyclePhaseId == 'the_fate'
        ? bonus.clamp(0, 6)
        : 0;
  }

  int get cycleNaturalFlightBonus =>
      faunaCurrentMonsterId == 'ciclo_solare_siccita' &&
          monsterBookEntryById(faunaCurrentMonsterId)?.hasNaturalFlight == true
      ? wingAdjustedFlightBonus(3, 'Volo naturale')
      : 0;

  String mostEffectiveIncomingElement(List<String> elements, {int? tieIndex}) {
    double multiplier(String element) =>
        dannoSubitoPercentPerTipo.containsKey(element)
        ? max(0, 1 + readIntValue(dannoSubitoPercentPerTipo[element]) / 100)
        : damageRuleMultiplierForCommand(
            incomingDamagePresets[element] ??
                monsterBookEntryById(
                  faunaCurrentMonsterId,
                )?.incomingDamageResistancePresets[element] ??
                'Normale',
          );
    final bestValue = elements.map(multiplier).reduce(max);
    final best = elements.where((e) => multiplier(e) == bestValue).toList();
    return best[(tieIndex ?? Random.secure().nextInt(best.length)) %
        best.length];
  }

  String cycleLunarBiteElement({bool? chooseLunarOnTie}) =>
      mostEffectiveIncomingElement(
        ['lunare', 'ombra'],
        tieIndex: chooseLunarOnTie == null
            ? null
            : chooseLunarOnTie
            ? 0
            : 1,
      );

  Widget celestialIdentityEditor() => DropdownButtonFormField<String>(
    key: ValueKey('celestial_identity_${currentSheetScrollId()}'),
    isExpanded: true,
    initialValue: celestialAllegiance,
    decoration: const InputDecoration(
      labelText: 'Appartenenza · Solare / Lunare',
      helperText: 'Indipendente da Fato / Chaos. I Mhunan sono Lunari di base.',
      helperMaxLines: 3,
    ),
    items: const [
      DropdownMenuItem(value: 'nessuna', child: Text('Nessuna appartenenza')),
      DropdownMenuItem(value: 'lunare', child: Text('Lunare')),
      DropdownMenuItem(value: 'solare', child: Text('Solare')),
    ],
    onChanged: (value) {
      if (value == null) return;
      setState(() => planarState['identityCelestial'] = value);
      programmaSalvataggio();
    },
  );

  bool grantCycleFateGift(String donor, {int? percentile}) {
    if (donor.trim().isEmpty || identityIsChaos || cyclePhaseId != 'the_fate') {
      aggiungiLog(
        '[MARMOCCHI DEL FATO] Il dono richiede identità Fato e fase The Fate.',
      );
      return false;
    }
    final donors = (planarState['cycleFateDonors'] as List? ?? [])
        .map((v) => '$v')
        .toSet();
    if (donors.contains(donor) || donors.length >= 3) return false;
    final bonus = (percentile ?? Random.secure().nextInt(100)) < 25 ? 2 : 1;
    donors.add(donor);
    planarState['cycleFateDonors'] = donors.toList();
    planarState['cycleFateGiftBonus'] =
        readIntValue(planarState['cycleFateGiftBonus']) + bonus;
    invalidateDerivedDataCaches();
    aggiungiLog(
      '[MARMOCCHI DEL FATO] +$bonus alle quattro statistiche; ${donors.length}/3 incontri distinti, totale +${planarState['cycleFateGiftBonus']} fino alla fine di The Fate.',
    );
    return true;
  }

  void cycleCalendarChanged(int before, int after, {int delta = 0}) {
    if (oculumPhaseForDay(before).id == 'the_fate' &&
        oculumPhaseForDay(after).id == 'the_fate' &&
        delta.abs() < 36) {
      return;
    }
    // Clear every locally owned sheet, including characters not currently open.
    for (final sheet in schedePersonaggio) {
      if (sheet['realtimeSharedSheet'] == true) continue;
      final state = sheet['planarRuntime'];
      if (state is Map) {
        state.remove('cycleFateDonors');
        state.remove('cycleFateGiftBonus');
      }
    }
    invalidateDerivedDataCaches();
  }

  String get cyclePreparedAttackSignature => jsonEncode([
    for (final key in const [
      'cycleSpines',
      'cycleLunarStomp',
      'cycleLunarBite',
      'cycleSkeletonThrow',
    ])
      planarState[key],
  ]);
  bool get cycleHasPreparedAttack =>
      readIntValue(planarState['cycleSpines']) > 0 ||
      readIntValue(planarState['cycleLunarStomp']) > 0 ||
      planarState['cycleLunarBite'] == true ||
      planarState['cycleSkeletonThrow'] == true;

  bool activateCycleEffect(OculumStructuredEffect effect, int value) {
    switch (effect.target) {
      case 'cycle_fate_gift':
        grantCycleFateGift(effect.resource);
        return true;
      case 'cycle_bear_spines':
        planarState['cycleSpines'] = Random.secure().nextInt(8) + 3;
        planarState['cycleSpineForm'] = max(1, value);
        aggiungiLog(
          '[ACULEI GHIACCIATI] ${planarState['cycleSpines']} colpi pronti, distribuibili. Ogni bersaglio difende ogni colpo.',
        );
        return true;
      case 'cycle_lunar_stomp':
        planarState['cycleLunarStomp'] = max(0, value);
        aggiungiLog(
          '[PEDATA LUNARE] Scegli i nemici: Manifestazione del Potere contro Resistenza, −$value ai tiri per un turno soltanto a chi perde.',
        );
        return true;
      case 'cycle_lunar_bite':
        planarState['cycleLunarBite'] = true;
        return true;
      case 'skeleton_giant_throw':
        planarState['cycleSkeletonThrow'] = true;
        return true;
    }
    return false;
  }

  void cycleTurnReactions(Map<String, dynamic> token) {
    if (!currentCombatIsActive()) return;
    final id = monsterBookIdForCombatToken(token);
    final monster = monsterBookEntryById(id);
    final goblin =
        id.contains('goblin') ||
        (monster?.classificationTags.any(
              (tag) => tag.toLowerCase() == 'goblin',
            ) ??
            false);
    if (id != 'ciclo_la_follia' && !goblin) return;
    bool aliveAlly(Map<String, dynamic> other) =>
        other['side'] == token['side'] &&
        publicInitiativeSourceTag(other) != publicInitiativeSourceTag(token) &&
        !const {'dead', 'fled', 'expired'}.contains(other['status']) &&
        !masterInitiativeTokenIsDead(other);
    if (id == 'ciclo_la_follia' &&
        masterInitiativeTokens.any(
          (other) =>
              aliveAlly(other) &&
              monsterBookEntryById(monsterBookIdForCombatToken(other)) !=
                  null &&
              oculumMonsterCyclePhase(
                    monsterBookEntryById(monsterBookIdForCombatToken(other))!,
                  ) ==
                  'illness',
        )) {
      token['extraFastReactionCurrent'] =
          readIntValue(token['extraFastReactionCurrent']) + 1;
      aggiungiLog(
        '[ILLNESS] La Follia: una Reazione veloce extra dagli alleati, per questo turno.',
      );
    }
    if (goblin &&
        id != 'ciclo_gigante_goblin' &&
        token['cycleGoblinGiftClaimed'] != true &&
        masterInitiativeTokens.any(
          (other) =>
              aliveAlly(other) &&
              monsterBookIdForCombatToken(other) == 'ciclo_gigante_goblin',
        )) {
      token['cycleGoblinGiftClaimed'] = true;
      token['extraNormalReactionCurrent'] =
          readIntValue(token['extraNormalReactionCurrent']) + 1;
      aggiungiLog(
        '[GIGANTE GOBLIN] ${token['name']}: una Reazione normale extra, una sola volta nello scontro.',
      );
    }
  }

  void claimCycleCriticalSource(Map<String, dynamic> request) {
    if (request['status'] != 'resolved' ||
        request['outcome'] == OculumAttackOutcome.avoided.name ||
        request['sourceMonsterBookId'] != 'ciclo_forest_demon_blu' ||
        !oculumAttackIsCritical(
          readIntValue(request['attack']),
          readIntValue(request['defense']),
        )) {
      return;
    }
    faunaForOwnedSheet('${request['sourceTag']}', () {
      if (!faunaReceipt(
        'cycle-critical:${request['attackGroupId'] ?? request['id']}',
      )) {
        return;
      }
      planarState['cycleCriticalCount'] =
          readIntValue(planarState['cycleCriticalCount']) + 1;
    });
  }

  void cycleIncomingCritical(
    Map<String, dynamic> request, {
    required bool critical,
    required bool hit,
  }) {
    if (!const {
          'ciclo_la_follia',
          'ciclo_forest_demon_blu',
        }.contains(request['sourceMonsterBookId']) &&
        request['cycleSpines'] != true) {
      return;
    }
    if (!hit ||
        !critical ||
        criticalShieldBlocksDebuffs(request) ||
        !faunaReceipt('cycle-target:${request['id']}')) {
      return;
    }
    final id = '${request['sourceMonsterBookId']}';
    if (id == 'ciclo_la_follia') {
      folliaController.text = '${leggiNumero(folliaController) + 1}';
      aggiungiLog('[LA FOLLIA] Critico ricevuto: +1 Follia.');
    }
    if (id == 'ciclo_forest_demon_blu') {
      final count = readIntValue(request['cycleCriticalCount']) + 1;
      final chance = (5 * count).clamp(0, 100);
      planarState['cycleCloudChance'] = max(
        readIntValue(planarState['cycleCloudChance']),
        chance,
      );
      activeStructuredEffects.removeWhere(
        (e) => e['effectId'] == 'cycle_rigid_cloud',
      );
      activeStructuredEffects.add({
        'effectId': 'cycle_rigid_cloud',
        'source': 'Nube rigida',
        'type': 'modifica_sottotratto',
        'target': 'movimento',
        'value': -3,
        'remaining': -1,
        'mode': 'finche_attivo',
        'unit': 'turni',
      });
      aggiungiLog(
        '[NUBE RIGIDA] −3 Movimento; ${planarState['cycleCloudChance']}% di non riuscire a difendersi. Fino a fine scontro, senza nubi sovrapposte.',
      );
    }
    if (request['cycleSpines'] == true) {
      applyCondition(
        'gelo',
        stage: 1,
        duration: 1,
        source: 'Aculei ghiacciati',
      );
      aggiungiLog(
        '[ACULEI] Gelo per un turno; altri colpi critici aumentano lo stadio.',
      );
    }
  }

  bool cycleCloudBlocksDefense(
    Map<String, dynamic> request, {
    int? percentile,
  }) {
    final chance = readIntValue(planarState['cycleCloudChance']).clamp(0, 100);
    if (chance == 0) return false;
    final roll = readIntValue(
      request.putIfAbsent(
        'cycleCloudDefenseRoll',
        () => percentile ?? Random.secure().nextInt(100),
      ),
    );
    if (roll >= chance) return false;
    aggiungiLog(
      '[NUBE RIGIDA] ${roll + 1}/100, probabilità $chance%: non riesci a difenderti da ${request['sourceName']}.',
    );
    return true;
  }

  Future<int> cycleSkeletonCollision(
    Map<String, dynamic> request,
    int defense,
  ) async {
    if (request['cycleSkeletonThrow'] != true ||
        readIntValue(request['attack']) <= defense) {
      return 0;
    }
    if (request.containsKey('cycleCollisionDamage')) {
      return readIntValue(request['cycleCollisionDamage']);
    }
    final natural = readIntValue(request['natural']),
        attack = readIntValue(request['attack']);
    final metres = oculumSkeletonThrowMetres(natural, attack, defense);
    final difficulty = oculumSkeletonThrowDifficulty(natural, attack, metres);
    final origin = currentSheetScrollId();
    var stat = 'riflessi';
    final paid = natural >= 20;
    final resource = await showDialog<String>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text('Riprenditi in aria · $metres metri'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                paid
                    ? 'Serve un totale di almeno $difficulty e una risorsa disponibile. Riprendersi evita urto e Schianto; resta il Danno base.'
                    : 'Prova gratuita: supera $difficulty. Riprendersi evita urto e Schianto; resta il Danno base.',
              ),
              DropdownButtonFormField<String>(
                initialValue: stat,
                items: [
                  for (final key in [
                    'riflessi',
                    'controllo_corporeo',
                    'movimento',
                  ])
                    DropdownMenuItem(
                      value: key,
                      child: Text(key.replaceAll('_', ' ')),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) update(() => stat = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: const Text('Accetta l’urto'),
            ),
            if (!paid)
              FilledButton(
                onPressed: () => Navigator.pop(dialog, 'gratis'),
                child: const Text('Tira gratis'),
              ),
            if (paid) ...[
              for (final r in ['azione', 'reazione', 'reazione_veloce'])
                TextButton(
                  onPressed: () => Navigator.pop(dialog, r),
                  child: Text(r.replaceAll('_', ' ')),
                ),
            ],
          ],
        ),
      ),
    );
    if (!mounted || currentSheetScrollId() != origin) return 0;
    var recovered = false;
    if (resource != null &&
        (!paid ||
            await requestUtilitySpend(resource, preferFreeReaction: false))) {
      if (!mounted || currentSheetScrollId() != origin) return 0;
      final subtrait = hiddenEyeStats.where((s) => s.id == stat).firstOrNull;
      final bonus = subtrait == null ? 0 : hiddenEyeTotal(subtrait);
      await tiraValoreSpeciale(
        'Riprenditi in aria · ${stat.replaceAll('_', ' ')}',
        bonus,
        resourceAlreadySpent: true,
        onResolved: (_, total) {
          recovered = oculumSkeletonThrowRecovered(
            natural,
            attack,
            metres,
            total,
          );
          request['cycleRecoveryTotal'] = total;
        },
      );
    }
    final collision = recovered
        ? 0
        : metres * 2 +
              (natural >= 19 ? readIntValue(request['cycleThrowSchianto']) : 0);
    request['cycleCollisionDamage'] = collision;
    request['cycleThrowMetres'] = metres;
    request['cycleRecovered'] = recovered;
    aggiungiLog(
      '[TELECINESI] Lancio di $metres metri: ${recovered ? 'ripresa riuscita, solo Danno base' : '+$collision Danni da urto${natural >= 19 ? ' e Schianto' : ''}, prima delle protezioni'}.',
    );
    return collision;
  }

  void resetCycleFight() {
    planarState.remove(_imbrytoadSpitKey);
    for (final key in [
      'cycleCriticalCount',
      'cycleCloudChance',
      'cycleSpines',
      'cycleSpineForm',
      'cycleLunarStomp',
      'cycleLunarBite',
      'cycleSkeletonThrow',
    ]) {
      planarState.remove(key);
    }
    activeStructuredEffects.removeWhere(
      (e) =>
          e['effectId'] == 'cycle_rigid_cloud' ||
          oculumIsPredoneOrbitTarget(e['target']) ||
          (faunaCurrentMonsterId == oculumImbrytoadId &&
              oculumIsImbrytoadSpitEffect(e['effectId'])),
    );
  }
}
