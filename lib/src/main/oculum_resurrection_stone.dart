part of '../../main.dart';

const _resurrectionWindowKey = 'resurrectionStoneWindow';
const _resurrectionCorpsesKey = 'resurrectionCorpses';
final _localResurrectionBusy = Expando<bool>();

typedef _LocalResurrectionTarget = ({
  String encounter,
  Map<String, dynamic> token,
  Map<String, dynamic>? archive,
});

extension _OculumResurrectionStone on _OculumHomePageState {
  bool get _localResurrection => realtimeService?.isConnected != true;

  Iterable<Map<String, dynamic>> _localResurrectionCorpses(Map group) {
    final corpses = group[_resurrectionCorpsesKey];
    return corpses is List ? corpses.whereType<Map<String, dynamic>>() : const [];
  }

  void _archiveLocalResurrectionCorpses(Map<String, dynamic> group) {
    if (!_localResurrection) return;
    final corpses = <String, Map<String, dynamic>>{};
    for (final token in [
      ..._localResurrectionCorpses(group),
      ...masterInitiativeTokens.where(
        (token) =>
            !masterInitiativeTokenIsTemporary(token) &&
            !oculumEncounterEnemyIsSummon(token) &&
            token['encounterObject'] != true &&
            masterInitiativeSheetIndexForToken(token) < 0,
      ),
    ]) {
      if (!oculumEncounterEnemyKilled(token) || '${token['id'] ?? ''}'.isEmpty) {
        continue;
      }
      final window = OculumResurrectionWindow.fromJson(
        token[_resurrectionWindowKey],
      );
      if (window != null &&
          window.campaignId == activeCampaignId &&
          !window.closed &&
          worldClockSeconds <= window.expiresAtSeconds) {
        corpses.putIfAbsent(window.deathId, () => _cloneJsonMap(token));
      }
    }
    if (corpses.isEmpty) {
      group.remove(_resurrectionCorpsesKey);
    } else {
      group[_resurrectionCorpsesKey] = corpses.values.toList();
    }
  }

  void _recordLocalResurrectionDeath(Map<String, dynamic> record) {
    if (!_localResurrection) return;
    final previous = OculumResurrectionWindow.fromJson(
      record[_resurrectionWindowKey],
    );
    final next = OculumResurrectionWindow.recordDeath(
      current: previous,
      isNewConfirmedDeath: true,
      campaignId: activeCampaignId,
      deathId:
          'death:${DateTime.now().microsecondsSinceEpoch}:${Random.secure().nextInt(1 << 30)}',
      worldClockSeconds: worldClockSeconds,
      normalizedDifficulty: normalizedCampaignDifficulty(),
    );
    if (!identical(next, previous)) {
      record[_resurrectionWindowKey] = next!.toJson();
    }
  }

  void _closeLocalResurrectionDeath(Map<String, dynamic> record) {
    if (!_localResurrection) return;
    final window = OculumResurrectionWindow.fromJson(
      record[_resurrectionWindowKey],
    );
    if (window != null && !window.closed) {
      record[_resurrectionWindowKey] = window.close().toJson();
    }
  }

  void _recordLocalResurrectionTokenDeath(Map<String, dynamic> token) {
    final index = masterInitiativeSheetIndexForToken(token);
    final source = index < 0 ? null : schedePersonaggio[index];
    final saved = source?[_resurrectionWindowKey];
    if (saved != null) token.putIfAbsent(_resurrectionWindowKey, () => saved);
    _recordLocalResurrectionDeath(token);
    if (source != null && token[_resurrectionWindowKey] != null) {
      source[_resurrectionWindowKey] = token[_resurrectionWindowKey];
    }
  }

  List<_LocalResurrectionTarget> _localResurrectionTargets() {
    final inFight = currentCombatIsActive();
    final sourceTag = sheetTagAt(schedaCorrente);
    final source =
        (inFight ? masterInitiativeTokens : const <Map<String, dynamic>>[])
            .where((token) => combatTokenMatchesSheet(token, sourceTag))
            .firstOrNull;
    if (inFight && (source == null || !masterInitiativeTokenCanAct(source))) {
      return const [];
    }
    final actor = source ?? {'side': sheetSideAt(schedaCorrente)};
    final seen = <String>{};
    bool accessible(Map<String, dynamic> token, Map actingToken) {
      final window = OculumResurrectionWindow.fromJson(
        token[_resurrectionWindowKey],
      );
      final index = masterInitiativeSheetIndexForToken(token);
      if (index >= 0 && !sheetIsOwnLocalSheetAt(index)) return false;
      final saved = index < 0
          ? null
          : OculumResurrectionWindow.fromJson(
              schedePersonaggio[index][_resurrectionWindowKey],
            );
      return token['status'] == 'dead' &&
          window != null &&
          !window.closed &&
          (saved == null ||
              (saved.deathId == window.deathId && !saved.closed)) &&
          window.campaignId == activeCampaignId &&
          worldClockSeconds >= window.startedAtSeconds &&
          worldClockSeconds <= window.expiresAtSeconds &&
          combatParticipantsShareTeam(actingToken, token) &&
          !combatTokenMatchesSheet(token, sourceTag) &&
          seen.add(window.deathId);
    }

    final tokens = <_LocalResurrectionTarget>[
      for (final token in masterInitiativeTokens)
        if (accessible(token, actor))
          (
            encounter: selectedMasterInitiativeGroupId,
            token: token,
            archive: null,
          ),
      if (!inFight)
        for (final group in masterInitiativeGroups)
          if ('${group['id']}' != selectedMasterInitiativeGroupId)
            for (final token in masterParticipantTokens('${group['id']}'))
              if (accessible(token, actor))
                (encounter: '${group['id']}', token: token, archive: null),
    ];
    if (inFight) return tokens;
    for (final group in masterInitiativeGroups) {
      if (group['combatEnded'] != true || group['fightStarted'] == true) continue;
      final encounter = '${group['id'] ?? ''}';
      if (encounter.isEmpty) continue;
      final roster = masterParticipantTokens(encounter);
      final encounterActor = roster
          .where((token) => combatTokenMatchesSheet(token, sourceTag))
          .firstOrNull;
      for (final corpse in _localResurrectionCorpses(group)) {
        if (roster.any((token) => token['id'] == corpse['id']) ||
            !accessible(corpse, encounterActor ?? actor)) {
          continue;
        }
        tokens.add((encounter: encounter, token: corpse, archive: group));
      }
    }
    for (var index = 0; index < schedePersonaggio.length; index++) {
      final sheet = schedePersonaggio[index];
      if (!oculumCombatConfirmedDeath(
        hp: sheetCurrentHpForDeathAt(index),
        deathWounds: readIntValue(sheet['feriteMorte']),
      )) {
        continue;
      }
      final token = <String, dynamic>{
        'sheetTag': sheetTagAt(index),
        'name': nomeSchedaPersonaggio(index),
        'currentHp': 0,
        'maxHp': sheetMaxHpForDeathAt(index),
        'side': sheetSideAt(index),
        'status': 'dead',
        _resurrectionWindowKey: sheet[_resurrectionWindowKey],
      };
      if (accessible(token, actor)) {
        tokens.add((encounter: '', token: token, archive: null));
      }
    }
    return tokens;
  }

  Future<void> _useLocalResurrectionStone(
    InventoryItem item, {
    String targetDeathId = '',
  }) async {
    if (!_localResurrection) {
      aggiungiLog(
        t(
          'L’uso della Pietra della Resurrezione è disponibile in una campagna locale.',
          'The Resurrection Stone can be used in a local campaign.',
        ),
      );
      return;
    }
    if (_localResurrectionBusy[this] == true ||
        !sheetIsOwnLocalSheetAt(schedaCorrente) ||
        hpCorrenti() <= 0 ||
        !inventario.contains(item) ||
        item.quantita <= 0 ||
        item.craftData['resurrectionStone'] != true) {
      return;
    }
    final actor = sheetTagAt(schedaCorrente);
    final campaign = activeCampaignId;
    final targets = _localResurrectionTargets();
    String deathId(Map token) => OculumResurrectionWindow.fromJson(
      token[_resurrectionWindowKey],
    )!.deathId;
    final selected = targetDeathId.isNotEmpty
        ? targetDeathId
        : await showDialog<String>(
            context: context,
            builder: (dialog) => SimpleDialog(
              title: Text(t('Resuscita un alleato', 'Resurrect an ally')),
              children: [
                if (targets.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      t(
                        'Nessun alleato morto entro la finestra.',
                        'No dead ally within the time window.',
                      ),
                    ),
                  ),
                for (final entry in targets)
                  SimpleDialogOption(
                    onPressed: () =>
                        Navigator.of(dialog).pop(deathId(entry.token)),
                    child: Text(cleanUiText('${entry.token['name'] ?? '???'}')),
                  ),
              ],
            ),
          );
    if (!mounted ||
        !_localResurrection ||
        _localResurrectionBusy[this] == true ||
        selected == null ||
        actor != sheetTagAt(schedaCorrente) ||
        campaign != activeCampaignId ||
        !inventario.contains(item) ||
        item.quantita <= 0) {
      return;
    }
    final target = _localResurrectionTargets()
        .where((candidate) => deathId(candidate.token) == selected)
        .firstOrNull;
    if (target == null) return;
    final token = target.token;
    final window = OculumResurrectionWindow.fromJson(
      token[_resurrectionWindowKey],
    )!;
    final targetIndex = masterInitiativeSheetIndexForToken(token);
    final maximum = targetIndex < 0
        ? readIntValue(token['maxHp'], fallback: 1)
        : sheetMaxHpForDeathAt(targetIndex);
    final hp = oculumResurrectionStoneHp(maximum);
    if (hp <= 0) return;
    final inFight = currentCombatIsActive();
    if (inFight && !currentTurnTrackerIsActive()) return;
    final targetTag = targetIndex < 0 ? '' : sheetTagAt(targetIndex);
    final useId = 'stone:${window.deathId}';
    if (oculumCheckResurrectionStone(
          window: window,
          campaignId: campaign,
          expectedDeathId: selected,
          useId: useId,
          worldClockSeconds: worldClockSeconds,
          targetIsConfirmedDead: token['status'] == 'dead',
          alliedLivingActor: hpCorrenti() > 0,
          availableStoneCount: item.quantita,
          inFight: inFight,
          hasAvailableAction: true,
        ) !=
        OculumResurrectionStoneResult.eligible) {
      return;
    }
    _localResurrectionBusy[this] = true;
    try {
      if (inFight &&
          !await requestUtilitySpend(
            'azione',
            preferFreeReaction: false,
            deferMasterTurn: true,
          )) {
        return;
      }
      if (!mounted ||
          !_localResurrection ||
          actor != sheetTagAt(schedaCorrente) ||
          campaign != activeCampaignId ||
          !inventario.contains(item) ||
          item.quantita <= 0 ||
          !_localResurrectionTargets().any(
            (entry) =>
                entry.encounter == target.encounter &&
                identical(entry.archive, target.archive) &&
                deathId(entry.token) == selected,
          )) {
        if (mounted && inFight && campaign == activeCampaignId) {
          advanceMasterInitiativeAfterAction(actor);
        }
        return;
      }
      final spent = window.close(useId: useId).toJson();
      if (--item.quantita == 0) inventario.remove(item);
      token.addAll({
        _resurrectionWindowKey: spent,
        'currentHp': hp,
        'deathWounds': 0,
        'vitalWills': 0,
        'downed': false,
        'friendlyFireDowned': false,
        'automaticDeath': false,
        'status': 'ready',
      });
      final archive = target.archive;
      if (archive != null) {
        final remaining = _localResurrectionCorpses(archive)
            .where(
              (corpse) =>
                  OculumResurrectionWindow.fromJson(
                    corpse[_resurrectionWindowKey],
                  )?.deathId !=
                  selected,
            )
            .toList();
        if (remaining.isEmpty) {
          archive.remove(_resurrectionCorpsesKey);
        } else {
          archive[_resurrectionCorpsesKey] = remaining;
        }
        final roster = masterParticipantTokens(target.encounter);
        token
          ..remove('fightInstanceId')
          ..addAll({
            'outsideFight': true,
            'actionUsed': false,
            'reportedTurn': 0,
            'manualOrder': roster.length,
          });
        roster.add(token);
        if (target.encounter != selectedMasterInitiativeGroupId) {
          archive['tokens'] = roster;
        }
      }
      if (targetIndex >= 0) {
        salvaSchedaCorrenteInMemoria();
        schedePersonaggio[targetIndex].addAll({
          _resurrectionWindowKey: spent,
          'currentHp': '$hp',
          'feriteMorte': 0,
          'volontaVitale': 0,
          'personaggioCaduto': false,
          'friendlyFireDowned': false,
          'personaggioSvenuto': false,
        });
        faunaForOwnedSheet(targetTag, syncCurrentSheetDeathStateToInitiative);
      }
      if (target.encounter.isNotEmpty) {
        saveMasterParticipantChange(target.encounter);
      }
      if (inFight) advanceMasterInitiativeAfterAction(actor);
      aggiungiLog('[RESURREZIONE] ${token['name'] ?? targetTag} · $hp Vita.');
      salvaSchedaCorrenteInMemoria();
      programmaSalvataggio();
      notifyActiveSheetSummaryChanged();
    } finally {
      _localResurrectionBusy[this] = null;
    }
  }

  Future<void> _delegateLocalResurrectionStone(
    Map<String, dynamic> target,
  ) async {
    final window = OculumResurrectionWindow.fromJson(
      target[_resurrectionWindowKey],
    );
    if (window == null) return;
    final item = inventario
        .where(
          (item) =>
              item.craftData['resurrectionStone'] == true && item.quantita > 0,
        )
        .firstOrNull;
    if (item != null) {
      await _useLocalResurrectionStone(item, targetDeathId: window.deathId);
    } else {
      aggiungiLog(
        t(
          'Seleziona la scheda dell’alleato che possiede la pietra.',
          'Select the sheet of the ally who has the stone.',
        ),
      );
    }
  }
}
