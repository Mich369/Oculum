part of '../../main.dart';

String oculumFightOrdinal(int number) {
  if (number <= 0) return '';
  final text = StringBuffer();
  for (final pair in const [
    (1000, 'M'),
    (900, 'CM'),
    (500, 'D'),
    (400, 'CD'),
    (100, 'C'),
    (90, 'XC'),
    (50, 'L'),
    (40, 'XL'),
    (10, 'X'),
    (9, 'IX'),
    (5, 'V'),
    (4, 'IV'),
    (1, 'I'),
  ]) {
    while (number >= pair.$1) {
      text.write(pair.$2);
      number -= pair.$1;
    }
  }
  return text.toString();
}

/// Read actual spends, never infer a Reaction from somebody being off turn.
/// Completed, cancelled and other-fight requests cannot hold this indicator open.
String oculumCombatTurnStatus(
  Map<String, dynamic> encounter, {
  Iterable<Map<String, dynamic>> requests = const [],
  Iterable<Map<String, dynamic>> rollingSpends = const [],
  bool english = false,
}) {
  final tokens = (encounter['tokens'] as List? ?? const [])
      .whereType<Map>()
      .toList();
  final ordinal = max(1, readIntValue(encounter['fightOrdinal'], fallback: 1));
  final fight = 'Fight ${oculumFightOrdinal(ordinal)}';
  final index = readIntValue(encounter['activeIndex'], fallback: -1);
  if (index < 0 || index >= tokens.length) {
    return '$fight | ${english ? 'No active turn' : 'Nessun turno attivo'}';
  }
  final owner = oculumReferenceEncounterTokenName(tokens[index]);
  final activityNames = <String, String>{};
  void addSpend(Map spend) {
    if (spend['activityComplete'] == true) return;
    final resource = '${spend['activityResource'] ?? spend['resource'] ?? ''}';
    if (!const {
      'azione',
      'azione_anticipata',
      'reazione',
      'reazione_veloce',
    }.contains(resource)) {
      return;
    }
    final tag = '${spend['sheetTag'] ?? ''}';
    final actor = tokens
        .where(
          (token) =>
              oculumSameSheetIdentity(token['sheetTag'] ?? token['id'], tag),
        )
        .firstOrNull;
    if (actor == null || const {'dead', 'expired'}.contains(actor['status'])) {
      return;
    }
    final label = resource.startsWith('azione')
        ? (english ? 'Action' : 'Azione')
        : resource == 'reazione_veloce'
        ? (english ? 'Fast Reaction' : 'Reazione Veloce')
        : (english ? 'Reaction' : 'Reazione');
    activityNames['${actor['sheetTag'] ?? actor['id']}'.trim().toUpperCase()] =
        '$label ${oculumReferenceEncounterTokenName(actor)}';
  }

  final encounterId = '${encounter['encounterId'] ?? encounter['id'] ?? ''}';
  for (final request in requests) {
    if (encounter['combatEnded'] == true ||
        ('${request['encounterId'] ?? ''}' != encounterId &&
            !(encounter['mergedEncounterIds'] as List? ?? const []).contains(
              request['encounterId'],
            )) ||
        !const {
          'pending',
          'rolling',
          'awaiting_roll',
        }.contains(request['status'])) {
      continue;
    }
    for (final spend
        in (request['turnResourceSpends'] as List? ?? const [])
            .whereType<Map>()) {
      addSpend(spend);
    }
  }
  for (final spend in rollingSpends) {
    if (spend['encounterId'] == encounterId) addSpend(spend);
  }
  return [
    fight,
    if (activityNames.isEmpty)
      '${english ? 'Action' : 'Azione'} $owner'
    else ...[
      ...activityNames.values,
      '${english ? 'turn of' : 'turno di'} $owner',
    ],
  ].join(' | ');
}

extension _OculumCombatTurnStatus on _OculumHomePageState {
  bool get referenceUsesLocalTurnState =>
      realtimeService?.isConnected != true || realtimeIsMasterRole;
  Map<String, dynamic> referenceTurnEncounter() {
    final tag = sheetTagAt(schedaCorrente);
    if (!referenceUsesLocalTurnState) {
      if (realtimeEncounterSnapshots.isNotEmpty) {
        final own = oculumSelectSharedEncounter(
          realtimeEncounterSnapshots,
          sheetTag: tag,
          selectedId: realtimeSelectedEncounterId,
        );
        if ((own['tokens'] as List? ?? const []).isNotEmpty) return own;
      }
      return realtimeVisibleInitiativeSnapshot;
    }
    bool containsTag(Iterable tokens) => tokens.whereType<Map>().any(
      (token) =>
          publicInitiativeSourceTag(Map<String, dynamic>.from(token)) == tag,
    );
    final other = !containsTag(masterInitiativeTokens)
        ? masterInitiativeGroups
              .where(
                (group) =>
                    group['id'] != selectedMasterInitiativeGroupId &&
                    containsTag(group['tokens'] as List? ?? const []),
              )
              .firstOrNull
        : null;
    final selected =
        other ??
        masterInitiativeGroups
            .where((group) => group['id'] == selectedMasterInitiativeGroupId)
            .firstOrNull;
    final id = '${selected?['id'] ?? selectedMasterInitiativeGroupId}';
    return {
      ...?selected,
      'encounterId': id,
      'fightOrdinal': max(
        1,
        masterInitiativeGroups.indexWhere((group) => group['id'] == id) + 1,
      ),
      if (id == selectedMasterInitiativeGroupId) ...{
        'tokens': masterInitiativeTokens,
        'round': masterInitiativeRound,
        'activeIndex': masterInitiativeActiveIndex,
      },
    };
  }

  String referenceTurnStatusText() => oculumCombatTurnStatus(
    referenceTurnEncounter(),
    requests: onlineCombatRequests.values,
    rollingSpends: mostraOverlayDado
        ? pendingOnlineCombatTurnResourceSpends
        : const [],
    english: linguaInglese,
  );

  void stepReferenceTurn(int delta, String encounterId) {
    if (referenceUsesLocalTurnState) {
      if (encounterId.isNotEmpty &&
          encounterId != selectedMasterInitiativeGroupId) {
        selectMasterInitiativeGroup(encounterId);
      }
      nextMasterInitiativeTurn(delta: delta);
    } else if (realtimeIsCoMasterRole) {
      realtimeSelectedEncounterId = encounterId;
      selectSharedEncounterForCurrentSheet();
      requestVisibleEncounterStep(delta);
    }
  }
}
