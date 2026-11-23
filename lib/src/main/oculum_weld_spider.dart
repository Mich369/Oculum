part of '../../main.dart';

const _weldSpiderBeamState = 'weldSpiderBeam';

int oculumWeldSpiderSustainedAttack(
  int initialAttack,
  int fullTurns, {
  int bonusPerTurn = 3,
}) => initialAttack + bonusPerTurn * max(0, fullTurns);

int oculumWeldSpiderSustainedDamage(
  int baseDamage, {
  int? primaryLocks,
  int primaryBonusPercent = 50,
  int secondaryPercent = 60,
}) =>
    (max(0, baseDamage) *
            max(
              0,
              primaryLocks == null
                  ? secondaryPercent
                  : 100 + primaryBonusPercent * max(0, primaryLocks),
            ) +
        99) ~/
    100;

bool _isWeldSpiderBeamPreparation(Map entry) =>
    entry['type'] == 'pending_target' &&
    entry['effect'] is Map &&
    oculumIsWeldSpiderBeamEffect((entry['effect'] as Map)['id']);

extension _OculumWeldSpider on _OculumHomePageState {
  Map<String, dynamic>? get weldSpiderBeamPreparation {
    final preparation = activeStructuredEffects
        .where(
          (entry) =>
              _isWeldSpiderBeamPreparation(entry) &&
              (entry['effect'] as Map)['type'] == 'danno',
        )
        .lastOrNull;
    return preparation?['effect'] as Map<String, dynamic>?;
  }

  bool weldSpiderBeamAvailable() {
    if (faunaCurrentMonsterId != oculumWeldSpiderId ||
        !oculumWeldSpiderTailIsBroken(anatomicalPartState)) {
      return true;
    }
    clearWeldSpiderBeam();
    aggiungiLog(
      '[RAGGIO AL PLASMA] La coda è rotta. Il raggio è indisponibile.',
    );
    return false;
  }

  void clearWeldSpiderBeam() {
    activeStructuredEffects.removeWhere(_isWeldSpiderBeamPreparation);
    planarState.remove(_weldSpiderBeamState);
    programmaSalvataggio();
  }

  void endWeldSpiderBeamConcentration() {
    if (planarState.remove(_weldSpiderBeamState) != null) {
      aggiungiLog('[RAGGIO AL PLASMA] Concentrazione terminata.');
      programmaSalvataggio();
    }
  }

  void focusWeldSpiderBeam(int turn) {
    final beam = planarState[_weldSpiderBeamState];
    if (beam is Map && beam['encounterId'] == onlineCombatEncounterId) {
      beam['focusTurn'] ??= turn;
    }
  }

  void sustainWeldSpiderBeam(
    Map<String, dynamic> opening, [
    Iterable<Map> preparedEffects = const [],
  ]) {
    if (!currentCombatIsActive()) return;
    final source = '${opening['sourceTag']}';
    final token = onlineCombatTokens()
        .where((entry) => combatTokenMatchesSheet(entry, source))
        .firstOrNull;
    final turn = readIntValue(
      token?['reportedTurn'],
      fallback: playerReportedTurn,
    );
    final settings = {
      for (final effect in preparedEffects)
        if (oculumIsWeldSpiderBeamEffect(effect['id']) &&
            oculumWeldSpiderSustainTargets.contains(effect['target']))
          effect['target']: effect,
    };
    planarState[_weldSpiderBeamState] = {
      for (final key in const [
        'id',
        'sourceTag',
        'sourceName',
        'sourceMonsterBookId',
        'encounterId',
        'scope',
        'attack',
        'natural',
        'dieFaces',
        'level',
        'grade',
        'difficulty',
        'element',
        'damage',
        'choice',
      ])
        if (opening.containsKey(key)) key: opening[key],
      'castTurn': turn,
      'reportedTurn': turn,
      if (schedePersonaggio[schedaCorrente]['combatConcentrationPending'] ==
          true)
        'focusTurn': turn,
      'primary': opening['targetTag'],
      'primaryLocks': 0,
      'secondary': <String>[],
      for (final entry in settings.entries)
        entry.key: readIntValue(entry.value['valueExpression']),
      if (settings[oculumWeldSpiderLocksPerTurn] case final Map locks)
        'maxFocusedTurns': max(0, readIntValue(locks['duration'])),
    };
  }

  bool _weldSpiderBeamIsSustained(Map beam) =>
      currentCombatIsActive() &&
      !outsideFight &&
      hpCorrenti() > 0 &&
      beam['encounterId'] == onlineCombatEncounterId &&
      beam['scope'] == permissionScope &&
      schedePersonaggio[schedaCorrente]['combatConcentrationPending'] == true &&
      weldSpiderBeamAvailable();

  Map<String, Map<String, dynamic>> _weldSpiderBeamTargets(Map beam) {
    final source = '${beam['sourceTag']}';
    final tokens = onlineCombatTokens();
    final actor = tokens
        .where((token) => combatTokenMatchesSheet(token, source))
        .firstOrNull;
    if (actor == null) return {};
    final team = combatParticipantTeamId(actor);
    return {
      for (final token in onlineAttackTokens())
        if (_attackTokenIsOpponent(token, team) &&
            token['outsideFight'] != true &&
            token['fightInstanceId'] == actor['fightInstanceId'])
          onlineCombatTokenTag(token): token,
    };
  }

  Future<void> advanceWeldSpiderBeamTurn(String owner, int reportedTurn) async {
    final index = localSheetIndexForOculumTag(owner);
    if (!mounted || index < 0 || !controlsOnlineCombatSheet(owner)) {
      return;
    }
    final runtime = index == schedaCorrente
        ? planarState
        : schedePersonaggio[index]['planarRuntime'];
    final raw = runtime is Map ? runtime[_weldSpiderBeamState] : null;
    if (raw is! Map || reportedTurn <= readIntValue(raw['reportedTurn'])) {
      return;
    }
    final launchId = '${raw['id']}';
    final claim = 'weld-spider-turn:$launchId';
    if (!onlineCombatResolving.add(claim)) return;
    try {
      Map<String, Map<String, dynamic>> options = {};
      var ready = false;
      faunaForOwnedSheet(owner, () {
        final focusTurn = raw['focusTurn'];
        if (focusTurn == null &&
            reportedTurn <= readIntValue(raw['castTurn']) + 1) {
          return;
        }
        if (!_weldSpiderBeamIsSustained(raw)) {
          clearWeldSpiderBeam();
          return;
        }
        final focusedTurns = reportedTurn - readIntValue(focusTurn) - 1;
        if (focusedTurns <= 0) return;
        final maximum = readIntValue(raw['maxFocusedTurns']);
        if (maximum > 0 && focusedTurns > maximum) {
          endWeldSpiderBeamConcentration();
          return;
        }
        ready = true;
        options = _weldSpiderBeamTargets(raw);
      });
      if (!ready) return;
      final primary = '${raw['primary']}';
      final alreadyAttached = (raw['secondary'] as List? ?? const [])
          .whereType<String>()
          .toSet();
      final count = readIntValue(
        raw[oculumWeldSpiderLocksPerTurn],
        fallback: 1,
      ).clamp(0, 100);
      final primaryBonus = readIntValue(
        raw[oculumWeldSpiderPrimaryPercent],
        fallback: 50,
      );
      final secondaryPercent = readIntValue(
        raw[oculumWeldSpiderSecondaryPercent],
        fallback: 60,
      );
      final added = <String>[];
      for (var lock = 0; lock < count && mounted; lock++) {
        if (!options.keys.any((tag) => !alreadyAttached.contains(tag))) break;
        final selected = await showDialog<String>(
          context: context,
          builder: (dialogContext) => SimpleDialog(
            title: const Text('Raggio al plasma · Nuovo aggancio'),
            children: [
              for (final entry in options.entries)
                if (!alreadyAttached.contains(entry.key))
                  SimpleDialogOption(
                    onPressed: () => Navigator.of(dialogContext).pop(entry.key),
                    child: Text(
                      '${faunaTargetName(entry.value)} · '
                      '${entry.key == primary ? '+$primaryBonus' : '$secondaryPercent'}% Danni base',
                    ),
                  ),
              SimpleDialogOption(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Mantieni gli agganci'),
              ),
            ],
          ),
        );
        if (selected == null) break;
        added.add(selected);
        if (selected != primary) alreadyAttached.add(selected);
      }
      if (!mounted) return;
      final packets = <Map<String, dynamic>>[];
      faunaForOwnedSheet(owner, () {
        final beam = planarState[_weldSpiderBeamState];
        if (beam is! Map ||
            beam['id'] != launchId ||
            readIntValue(beam['reportedTurn']) >= reportedTurn ||
            !_weldSpiderBeamIsSustained(beam)) {
          return;
        }
        final targets = _weldSpiderBeamTargets(beam);
        final secondary = (beam['secondary'] as List? ?? const [])
            .whereType<String>()
            .where(targets.containsKey)
            .toSet();
        var primaryLocks = readIntValue(beam['primaryLocks']);
        for (final tag in added.where(targets.containsKey)) {
          if (tag == primary) {
            primaryLocks++;
          } else {
            secondary.add(tag);
          }
        }
        beam['reportedTurn'] = reportedTurn;
        beam['primaryLocks'] = primaryLocks;
        beam['secondary'] = secondary.toList();
        final fullTurns = reportedTurn - readIntValue(beam['focusTurn']) - 1;
        for (final tag in [
          if (targets.containsKey(primary)) primary,
          ...secondary,
        ]) {
          final target = targets[tag]!;
          final damage = oculumWeldSpiderSustainedDamage(
            readIntValue(beam['damage']),
            primaryLocks: tag == primary ? primaryLocks : null,
            primaryBonusPercent: primaryBonus,
            secondaryPercent: secondaryPercent,
          );
          final group = 'plasma:$launchId:$reportedTurn';
          packets.add({
            for (final key in const [
              'sourceTag',
              'sourceName',
              'sourceMonsterBookId',
              'encounterId',
              'scope',
              'natural',
              'dieFaces',
              'level',
              'grade',
              'difficulty',
              'element',
              'choice',
            ])
              if (beam.containsKey(key)) key: beam[key],
            'id': '$group:$tag',
            'attackGroupId': group,
            'targetTag': tag,
            'targetName': faunaTargetName(target),
            'targetFightInstance': target['fightInstanceId'],
            'attack': oculumWeldSpiderSustainedAttack(
              readIntValue(beam['attack']),
              fullTurns,
              bonusPerTurn: readIntValue(
                beam[oculumWeldSpiderAttackPerTurn],
                fallback: 3,
              ),
            ),
            'damage': damage,
            'damageTotal': damage,
            'abilityName': 'Raggio al plasma · Mantenimento',
            'weldSpiderBeamSustained': true,
            'ranged': true,
            'status': 'pending',
            'createdAt': DateTime.now().toIso8601String(),
          });
        }
        if (packets.isEmpty) clearWeldSpiderBeam();
      });
      for (final packet in packets) {
        final id = '${packet['id']}';
        if (onlineCombatRequests.containsKey(id)) continue;
        onlineCombatRequests[id] = packet;
        receiveLocalCombatAttack(packet);
        unawaited(sendOnlineCombatRequest(packet));
      }
      programmaSalvataggio();
    } finally {
      onlineCombatResolving.remove(claim);
    }
  }
}
