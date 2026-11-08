part of '../../main.dart';

typedef _OculumKnightGroup = ({String target, int hits});

const _statOpenMateriaPermission = 'stat_open_materia_move';
const _statOpenMateriaIdentityFields = [
  'scope',
  'campaignId',
  'encounterId',
  'fight',
  'turn',
  'actor',
  'target',
  'form',
  'nonce',
  'range',
];
final _statOpenMateriaReplies =
    Expando<
      Map<String, (Map<String, dynamic>, Completer<Map<String, dynamic>?>)>
    >();
final _statOpenMateriaPermits = Expando<Map<String, _StatOpenMateriaPermit>>();

bool oculumStatOpenMateriaSameRequest(Map a, Map b) =>
    _statOpenMateriaIdentityFields.every(
      (field) => a.containsKey(field) && a[field] == b[field],
    );

bool oculumStatOpenMateriaPermissionRole(Map payload, {required bool reply}) =>
    '${payload['authenticatedUserId'] ?? ''}'.isNotEmpty &&
    payload['authenticatedRole'] == payload['senderRole'] &&
    (reply
        ? payload['authenticatedRole'] == 'master'
        : const {'player', 'coMaster'}.contains(payload['authenticatedRole']));

int? oculumStatOpenMateriaAuthorizedRange(Map sheet, String form) {
  final option = _statOpenForms[form];
  if (option == null || option.track != 'matter_geometry') return -1;
  final runtime = sheet['planarRuntime'];
  final milestones = runtime is Map ? runtime['stat35'] : null;
  if (milestones is! Map || !sheet.containsKey('livello')) return null;
  final level = readIntValue(sheet['livello']);
  final effectiveLevel = readBoolValue(sheet['rebirthato']) ? level * 3 : level;
  final oldChoices = milestones['choices20'];
  final newChoices = milestones['choices'];
  if (effectiveLevel < option.level ||
      oldChoices is! Map ||
      oldChoices['materia'] == null ||
      newChoices is! Map ||
      newChoices['materia'] == null) {
    return -1;
  }
  final options = milestones['parameters'];
  final values = options is Map ? options[form] : null;
  int value(String key) => max(
    0,
    readIntValue(
      values is Map ? values[key] : null,
      fallback: option.tier.values[key] ?? 0,
    ),
  );
  final opens = milestones['opens'];
  final active = opens is Map ? opens[form] : null;
  final ownBuff =
      active is Map &&
      readBoolValue(active['buffActive']) &&
      readBoolValue(active['skillEmpowered']);
  return value('movement') + (ownBuff ? value('movementBuff') : 0);
}

class _StatOpenMateriaMove {
  const _StatOpenMateriaMove({
    this.token,
    this.start,
    this.landing,
    this.finish,
    this.width = 1,
    this.height = 1,
    this.remote,
  });

  final Map<String, dynamic>? token;
  final Offset? start;
  final Offset? landing;
  final Offset? finish;
  final double width;
  final double height;
  final Map<String, dynamic>? remote;

  double meters(Offset a, Offset b) =>
      Offset((a.dx - b.dx) * width, (a.dy - b.dy) * height).distance;
}

class _StatOpenMateriaPermit {
  _StatOpenMateriaPermit(this.request)
    : expires = DateTime.now().add(const Duration(seconds: 90)),
      proof =
          '${Random.secure().nextInt(1 << 30).toRadixString(36)}'
          '${Random.secure().nextInt(1 << 30).toRadixString(36)}';

  final Map<String, dynamic> request;
  final DateTime expires;
  final String proof;
  bool? planned;
  String sceneId = '';
  int actorTurn = 0;
  bool manuallyApproved = false;
  _StatOpenMateriaMove? move;
  int retreatLimit = 0;
  int? retreatRequested;
  bool? approached;
  DateTime? approachedAt;
  bool? retreated;
}

extension _OculumStatOpenAttackPlanning on _OculumHomePageState {
  Future<List<_OculumKnightGroup>?> planStatOpenKnightGroups(
    List<String> targets,
    Map<String, Map<String, dynamic>> tokens,
    int hits,
  ) async {
    if (targets.isEmpty || targets.length > 4 || hits < 4) return null;
    final groups = List<String>.generate(
      4,
      (index) => targets[index % targets.length],
    );
    final amounts = List<int>.generate(
      4,
      (index) => hits ~/ 4 + (index < hits % 4 ? 1 : 0),
    );
    List<_OculumKnightGroup> result() => [
      for (var i = 0; i < groups.length; i++)
        (target: groups[i], hits: amounts[i]),
    ];
    if (targets.length == 1 && hits == 4) return result();
    return showDialog<List<_OculumKnightGroup>>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (context, update) {
          final theme = Theme.of(context);
          final total = amounts.fold<int>(0, (sum, value) => sum + value);
          final usedTargets = groups.toSet();
          return AlertDialog(
            scrollable: true,
            title: Text(
              'Distribuisci $hits colpi dei Cavalieri Rossi',
              style: TextStyle(color: theme.colorScheme.primary),
            ),
            content: SizedBox(
              width: 450,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('$total / $hits assegnati · una difesa per gruppo'),
                  for (var i = 0; i < groups.length; i++)
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: combatParticipantSideColor(
                            tokens[groups[i]] ?? const {},
                          ).withValues(alpha: .65),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: DropdownButton<String>(
                              value: groups[i],
                              isExpanded: true,
                              items: [
                                for (final tag in targets)
                                  DropdownMenuItem(
                                    value: tag,
                                    child: Text(
                                      '${i + 1} · ${tokens[tag]?['name'] ?? 'Bersaglio'}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                              onChanged: (tag) {
                                if (tag != null) update(() => groups[i] = tag);
                              },
                            ),
                          ),
                          IconButton(
                            tooltip: 'Rimuovi un colpo dal gruppo ${i + 1}',
                            onPressed: amounts[i] > 1
                                ? () => update(() => amounts[i]--)
                                : null,
                            icon: const Icon(Icons.remove),
                          ),
                          Text('${amounts[i]}'),
                          IconButton(
                            tooltip: 'Aggiungi un colpo al gruppo ${i + 1}',
                            onPressed: total < hits
                                ? () => update(() => amounts[i]++)
                                : null,
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialog),
                child: const Text('Annulla'),
              ),
              FilledButton(
                onPressed: total == hits && usedTargets.length == targets.length
                    ? () => Navigator.pop(dialog, result())
                    : null,
                child: const Text('Conferma gruppi'),
              ),
            ],
          );
        },
      ),
    );
  }

  int statOpenMateriaRange(String id) =>
      max(0, statOpenValue(id, 'movement')) +
      (statOpenOwnBuff(id) ? max(0, statOpenValue(id, 'movementBuff')) : 0);

  ({Map<String, dynamic>? actor, Map<String, dynamic>? target})
  _statOpenMateriaTokens(String targetTag, {String? actorTag}) {
    final tokens = onlineCombatTokens();
    final sourceTag = actorTag ?? sheetTagAt(schedaCorrente);
    Map<String, dynamic>? tokenFor(String tag) => tokens
        .where((token) => combatTokenMatchesSheet(token, tag))
        .firstOrNull;
    final source = tokenFor(sourceTag);
    final target = tokenFor(targetTag);
    return (
      actor: source == null ? null : localMapTokenForInitiativeToken(source),
      target: target == null ? null : localMapTokenForInitiativeToken(target),
    );
  }

  Offset _statOpenMapPosition(Map<String, dynamic> token) =>
      Offset(localMapTokenAxis(token, 'x'), localMapTokenAxis(token, 'y'));

  bool _statOpenPathClear(Offset start, Offset finish) =>
      !vttModuleEnabled('walls_doors') ||
      !oculumVttMovementBlocked(start, finish, activeVttScene.walls);

  Future<_StatOpenMateriaMove?> planStatOpenMateriaMove(
    String id,
    String targetTag,
  ) async {
    if (!_materia35MapAuthority) {
      return _planRemoteStatOpenMateriaMove(id, targetTag);
    }
    final tokens = _statOpenMateriaTokens(targetTag);
    final actor = tokens.actor;
    final target = tokens.target;
    final range = statOpenMateriaRange(id);
    if (actor == null || target == null) {
      final approved = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: const Text('Conferma il percorso'),
          content: Text(
            'Verifica un riposizionamento entro $range m e il movimento residuo.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialog, true),
              child: const Text('Percorso confermato'),
            ),
          ],
        ),
      );
      return approved == true ? const _StatOpenMateriaMove() : null;
    }

    final route = _statOpenMateriaRoute(actor, target, range);
    if (route == null) {
      aggiungiLog(
        '[OPEN MATERIA] Il percorso verso il bersaglio non è raggiungibile.',
      );
      return null;
    }

    final (move, retreat) = route;
    if (statOpenLevel(id) < 100 || retreat <= .001) return move;
    final before = move.meters(move.start!, move.landing!);
    final after = await _selectStatOpenMateriaRetreat(before, retreat);
    if (after == null) return null;
    return _withStatOpenMateriaRetreat(move, after);
  }

  Future<double?> _selectStatOpenMateriaRetreat(
    double before,
    double retreat,
  ) => showDialog<double>(
    context: context,
    builder: (dialog) {
      var meters = 0.0;
      return StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: const Text('Movimento dopo il colpo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Avanzi di ${before.toStringAsFixed(1)} m. Dopo il colpo rientri di ${meters.toStringAsFixed(1)} m.',
              ),
              Slider(
                value: meters,
                max: retreat,
                onChanged: (value) => update(() => meters = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialog, meters),
              child: const Text('Conferma percorso'),
            ),
          ],
        ),
      );
    },
  );

  (_StatOpenMateriaMove, double)? _statOpenMateriaRoute(
    Map<String, dynamic> actor,
    Map<String, dynamic> target,
    int range,
  ) {
    final width = mapWidthMetersValue();
    final height = mapHeightMetersValue();
    final start = _statOpenMapPosition(actor);
    final limit = min(range.toDouble(), localMapTokenMovementRemaining(actor));
    final landing = oculumMateria35WindLanding(
      source: start,
      target: _statOpenMapPosition(target),
      widthMeters: width,
      heightMeters: height,
      movement: limit,
      adjacency: activeVttScene.distancePerCell,
      occupied: localMapTokens
          .where(
            (token) => !identical(token, actor) && !identical(token, target),
          )
          .map(_statOpenMapPosition),
    );
    if (landing == null || !_statOpenPathClear(start, landing)) return null;
    final move = _StatOpenMateriaMove(
      token: actor,
      start: start,
      landing: landing,
      width: width,
      height: height,
    );
    final before = move.meters(start, landing);
    return (move, min(before, max(0.0, limit - before)));
  }

  _StatOpenMateriaMove _withStatOpenMateriaRetreat(
    _StatOpenMateriaMove move,
    double after,
  ) {
    if (after <= 0) return move;
    final start = move.start!;
    final landing = move.landing!;
    final before = move.meters(start, landing);
    return _StatOpenMateriaMove(
      token: move.token,
      start: start,
      landing: landing,
      finish: Offset.lerp(landing, start, after / before),
      width: move.width,
      height: move.height,
    );
  }

  Future<_StatOpenMateriaMove?> _planRemoteStatOpenMateriaMove(
    String id,
    String target,
  ) async {
    final encounter = onlineCombatEncounterId;
    final turn = _turnSpendRetryTurn();
    if (realtimeService?.isConnected != true ||
        turn == null ||
        turn.encounterId != encounter) {
      aggiungiLog('[OPEN MATERIA] Serve un Fight condiviso con il Master.');
      return null;
    }
    final actor = sheetTagAt(schedaCorrente);
    final request = <String, dynamic>{
      'scope': permissionScope,
      'campaignId': permissionCampaignId,
      'encounterId': encounter,
      'fight': combatSubtraitExperienceFightId(encounter, ownerTag: actor),
      'turn': turn.key,
      'actor': actor,
      'target': target,
      'form': id,
      'nonce':
          '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
          '${Random.secure().nextInt(1 << 30).toRadixString(36)}',
      'range': statOpenMateriaRange(id),
    };
    aggiungiLog('[OPEN MATERIA] Percorso inviato al Master.');
    final reply = await _requestStatOpenMateriaMovement(request, 'plan');
    if (!mounted || !_statOpenMateriaOwnerCurrent(request)) return null;
    if (reply?['accepted'] != true) {
      aggiungiLog('[OPEN MATERIA] Percorso rifiutato o conferma scaduta.');
      return null;
    }
    final proof = '${reply?['proof'] ?? ''}';
    final masterSession = '${reply?['sessionId'] ?? ''}';
    if (proof.isEmpty || masterSession.isEmpty) return null;
    final limit = readIntValue(reply?['retreatLimit']);
    var retreat = 0;
    if (limit > 0) {
      final selected = await _selectStatOpenMateriaRetreat(
        readIntValue(reply?['approachLength']) / 100,
        limit / 100,
      );
      if (selected == null ||
          !mounted ||
          !_statOpenMateriaOwnerCurrent(request)) {
        return null;
      }
      retreat = (selected * 100).round().clamp(0, limit);
    }
    return _StatOpenMateriaMove(
      remote: {
        ...request,
        'proof': proof,
        'masterSession': masterSession,
        'retreat': retreat,
      },
    );
  }

  bool _statOpenMateriaOwnerCurrent(Map request, {bool retreat = false}) =>
      request['actor'] == sheetTagAt(schedaCorrente) &&
      request['scope'] == permissionScope &&
      request['campaignId'] == permissionCampaignId &&
      request['encounterId'] == onlineCombatEncounterId &&
      (retreat || request['turn'] == _turnSpendRetryTurn()?.key);

  Future<Map<String, dynamic>?> _requestStatOpenMateriaMovement(
    Map<String, dynamic> request,
    String phase,
  ) async {
    final service = realtimeService;
    if (service?.isConnected != true ||
        !_statOpenMateriaOwnerCurrent(request, retreat: phase == 'retreat')) {
      return null;
    }
    final key = '${request['nonce']}:$phase';
    final pending = _statOpenMateriaReplies[this] ??= {};
    if (pending.containsKey(key)) return null;
    final reply = Completer<Map<String, dynamic>?>();
    pending[key] = (request, reply);
    try {
      for (var attempt = 0; attempt < 2; attempt++) {
        await service!.sendPermissionEvent(
          'permission_request',
          permissionEnvelope({
            ...request,
            'action': _statOpenMateriaPermission,
            'phase': phase,
          }),
        );
        final result = await reply.future.timeout(
          Duration(
            seconds: attempt == 0
                ? 3
                : phase == 'plan'
                ? 42
                : 5,
          ),
          onTimeout: () => null,
        );
        if (result != null) return result;
        if (!mounted ||
            !_statOpenMateriaOwnerCurrent(
              request,
              retreat: phase == 'retreat',
            )) {
          return null;
        }
      }
      return null;
    } finally {
      pending.remove(key);
    }
  }

  Future<bool> commitStatOpenMateriaApproach(_StatOpenMateriaMove move) async {
    final remote = move.remote;
    if (remote == null) return true;
    final reply = await _requestStatOpenMateriaMovement(remote, 'approach');
    final ok =
        mounted &&
        _statOpenMateriaOwnerCurrent(remote) &&
        reply?['accepted'] == true;
    if (mounted && !ok) {
      aggiungiLog('[OPEN MATERIA] Il percorso non è più valido.');
    }
    return ok;
  }

  Future<void> receiveStatOpenMateriaPermission(
    String event,
    Map<String, dynamic> payload,
  ) async {
    final reply = event == 'permission_decision';
    if (event != 'permission_request' && !reply) return;
    final nonce = '${payload['nonce'] ?? ''}';
    final phase = '${payload['phase'] ?? ''}';
    if (!RegExp(r'^[a-z0-9]{8,40}$').hasMatch(nonce) ||
        !const {'plan', 'approach', 'retreat'}.contains(phase) ||
        !oculumStatOpenMateriaPermissionRole(payload, reply: reply) ||
        !validPermissionSender(payload, staff: reply)) {
      return;
    }
    if (reply) {
      final pending = _statOpenMateriaReplies[this]?['$nonce:$phase'];
      if (pending != null &&
          !pending.$2.isCompleted &&
          oculumStatOpenMateriaSameRequest(pending.$1, payload) &&
          _statOpenMateriaOwnerCurrent(payload, retreat: phase == 'retreat') &&
          (phase == 'plan' ||
              (payload['sessionId'] == pending.$1['masterSession'] &&
                  payload['proof'] == pending.$1['proof'])) &&
          payload['retreat'] == pending.$1['retreat'] &&
          payload['attackId'] == pending.$1['attackId']) {
        pending.$2.complete(payload);
      }
      return;
    }
    final actor = '${payload['actor'] ?? ''}';
    final target = '${payload['target'] ?? ''}';
    final form = '${payload['form'] ?? ''}';
    final range = payload['range'];
    if (!realtimeIsMasterRole ||
        !modalitaMaster ||
        !mounted ||
        actor.isEmpty ||
        target.isEmpty ||
        !oculumSameSheetIdentity(actor, payload['senderTag']) ||
        statOpenTrack(form) != 'matter_geometry' ||
        range is! int ||
        range < 0 ||
        range > 1000000) {
      return;
    }
    final permits = _statOpenMateriaPermits[this] ??= {};
    final now = DateTime.now();
    permits.removeWhere((_, value) => !value.expires.isAfter(now));
    final permitKey =
        '${payload['authenticatedUserId']}:${payload['sessionId']}:$nonce';
    final existing = permits[permitKey];
    if (existing != null &&
        !oculumStatOpenMateriaSameRequest(existing.request, payload)) {
      return;
    }
    if (phase == 'plan') {
      if (existing != null) {
        if (existing.planned != null) {
          await _replyStatOpenMateriaMovement(
            payload,
            existing,
            existing.planned!,
          );
        }
        return;
      }
      if (permits.values.any((permit) => permit.planned == null) ||
          permits.length >= 32) {
        await _replyStatOpenMateriaMovement(payload, null, false);
        return;
      }
      final permit = _StatOpenMateriaPermit(payload);
      permits[permitKey] = permit;
      permit.planned = await _planMasterStatOpenMateriaMovement(
        permit,
        actor,
        target,
        range,
      );
      await _replyStatOpenMateriaMovement(payload, permit, permit.planned!);
      return;
    }
    if (existing?.planned != true) {
      // Another Master device may have issued the permit.
      return;
    }
    final permit = existing!;
    if (payload['proof'] != permit.proof) return;
    final requested = payload['retreat'];
    if (requested is! int ||
        requested < 0 ||
        requested > permit.retreatLimit ||
        (permit.retreatRequested != null &&
            permit.retreatRequested != requested)) {
      await _replyStatOpenMateriaMovement(payload, permit, false);
      return;
    }
    permit.retreatRequested = requested;
    if (phase == 'retreat' && permit.approached == true) {
      final attackId = '${payload['attackId'] ?? ''}';
      final attack = onlineCombatRequests[attackId];
      if (attackId.isNotEmpty && attack == null) {
        return; // Combat packet may still be in flight.
      }
      if (attack == null ||
          (attack['kind'] != null && attack['kind'] != 'attack') ||
          attack['attack'] is! num ||
          attack['status'] == 'cancelled' ||
          attack['scope'] != payload['scope'] ||
          attack['encounterId'] != payload['encounterId'] ||
          attack['statOpenId'] != form ||
          attack['statOpenMateriaPermit'] != permit.proof ||
          !oculumSameSheetIdentity(attack['sourceTag'], actor) ||
          !oculumSameSheetIdentity(attack['targetTag'], target)) {
        await _replyStatOpenMateriaMovement(payload, permit, false);
        return;
      }
      permit.retreated ??= _commitMasterStatOpenMateriaMovement(
        permit,
        after: true,
      );
      await _replyStatOpenMateriaMovement(payload, permit, permit.retreated!);
    } else if (phase == 'approach') {
      permit.approached ??= _commitMasterStatOpenMateriaMovement(permit);
      if (permit.approached == true) permit.approachedAt ??= now;
      await _replyStatOpenMateriaMovement(payload, permit, permit.approached!);
    }
  }

  bool _statOpenMateriaFightCurrent(Map request, {bool after = false}) {
    final encounter = onlineCombatEncounterId;
    final actor = '${request['actor']}';
    final snapshot = referenceTurnEncounter();
    final tokens = onlineCombatTokens();
    final active = readIntValue(snapshot['activeIndex'], fallback: -1);
    if (request['scope'] != permissionScope ||
        request['campaignId'] != permissionCampaignId ||
        request['encounterId'] != encounter ||
        request['fight'] !=
            combatSubtraitExperienceFightId(encounter, ownerTag: actor) ||
        !currentCombatIsActive() ||
        active < 0 ||
        active >= tokens.length) {
      return false;
    }
    return after ||
        (request['turn'] == _turnSpendRetryTurn()?.key &&
            combatTokenMatchesSheet(tokens[active], actor));
  }

  Future<bool> _planMasterStatOpenMateriaMovement(
    _StatOpenMateriaPermit permit,
    String actorTag,
    String targetTag,
    int range,
  ) async {
    if (!_statOpenMateriaFightCurrent(permit.request)) return false;
    final tokens = onlineCombatTokens();
    final actor = tokens
        .where((token) => combatTokenMatchesSheet(token, actorTag))
        .firstOrNull;
    final target = tokens
        .where((token) => combatTokenMatchesSheet(token, targetTag))
        .firstOrNull;
    if (actor == null ||
        target == null ||
        !masterInitiativeTokenCanAct(actor) ||
        !oculumShieldBreakCanTarget(actor, target)) {
      return false;
    }
    final form = '${permit.request['form']}';
    final authorizedRange = _statOpenMateriaVerifiedRange(permit.request);
    if (authorizedRange != null && range > authorizedRange) return false;
    permit.actorTurn = readIntValue(actor['reportedTurn']);
    permit.sceneId = activeVttScene.id;
    final map = _statOpenMateriaTokens(targetTag, actorTag: actorTag);
    final actorMap = map.actor;
    final targetMap = map.target;
    if (authorizedRange == null || actorMap == null || targetMap == null) {
      final approved = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: const Text('Percorso Open Materia'),
          content: Text(
            '${oculumReferenceEncounterTokenName(actor)} vuole raggiungere '
            '${oculumReferenceEncounterTokenName(target)}. Conferma che il percorso '
            'rispetti il movimento residuo e il limite di $range m '
            'per ${statOpenName(form)}.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog, false),
              child: const Text('Rifiuta'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialog, true),
              child: const Text('Approva percorso'),
            ),
          ],
        ),
      );
      if (approved != true ||
          !mounted ||
          !_statOpenMateriaFightCurrent(permit.request)) {
        return false;
      }
      permit.manuallyApproved = true;
    }
    if (actorMap == null || targetMap == null) return true;
    final role = permit.request['authenticatedRole'] == 'coMaster'
        ? 'co_master'
        : 'player';
    if (!(vttState.permissions[role]?['tokens'] ?? false) ||
        !oculumSameSheetIdentity(localMapTokenOwnerTag(actorMap), actorTag)) {
      return false;
    }
    final route = _statOpenMateriaRoute(actorMap, targetMap, range);
    if (route == null) return false;
    permit.move = route.$1;
    if (statOpenLevel(form) >= 100) {
      permit.retreatLimit = (route.$2 * 100).floor();
    }
    return true;
  }

  int? _statOpenMateriaVerifiedRange(Map request) {
    final actor = '${request['actor']}';
    final form = '${request['form']}';
    for (final record in realtimeSharedSheets.reversed) {
      if (record['senderUserId'] != request['authenticatedUserId'] ||
          record['campaignId'] != request['campaignId'] ||
          !oculumSameSheetIdentity(record['sheetId'], actor) ||
          record['sheet'] is! Map) {
        continue;
      }
      final bound = oculumStatOpenMateriaAuthorizedRange(
        record['sheet'] as Map,
        form,
      );
      if (bound != null) return bound;
    }
    return null;
  }

  bool _commitMasterStatOpenMateriaMovement(
    _StatOpenMateriaPermit permit, {
    bool after = false,
  }) {
    if (!mounted ||
        permit.sceneId != activeVttScene.id ||
        !_statOpenMateriaFightCurrent(permit.request, after: after)) {
      return false;
    }
    final move = permit.move;
    if (move == null) return true; // Staff approved the narrated route.
    final token = move.token!;
    final role = permit.request['authenticatedRole'] == 'coMaster'
        ? 'co_master'
        : 'player';
    if (!(vttState.permissions[role]?['tokens'] ?? false) ||
        !oculumSameSheetIdentity(
          localMapTokenOwnerTag(token),
          permit.request['actor'],
        ) ||
        !localMapTokens.any((candidate) => identical(candidate, token))) {
      return false;
    }
    if (!after) {
      final authorizedRange = _statOpenMateriaVerifiedRange(permit.request);
      final range = readIntValue(permit.request['range']);
      if (authorizedRange == null
          ? !permit.manuallyApproved
          : range > authorizedRange) {
        return false;
      }
      final target = _statOpenMateriaTokens(
        '${permit.request['target']}',
        actorTag: '${permit.request['actor']}',
      ).target;
      if (target == null) return false;
      final updated = _statOpenMateriaRoute(token, target, range);
      if (updated == null ||
          updated.$1.start != move.start ||
          updated.$1.landing != move.landing ||
          (permit.retreatRequested ?? 0) > (updated.$2 * 100).floor()) {
        return false;
      }
      if (!prepareLocalMapTokenMovement(token)) return false;
      return commitStatOpenMateriaMove(move);
    }
    final approachedAt = permit.approachedAt;
    final actor = onlineCombatTokens()
        .where(
          (token) =>
              combatTokenMatchesSheet(token, '${permit.request['actor']}'),
        )
        .firstOrNull;
    final elapsedTurns =
        readIntValue(actor?['reportedTurn']) - permit.actorTurn;
    if (approachedAt == null ||
        DateTime.now().difference(approachedAt) > const Duration(seconds: 20) ||
        actor == null ||
        !masterInitiativeTokenCanAct(actor) ||
        elapsedTurns < 0 ||
        elapsedTurns > 1 ||
        (elapsedTurns > 0 && actor['status'] == 'active')) {
      return false;
    }
    final retreat = (permit.retreatRequested ?? 0) / 100;
    return commitStatOpenMateriaMove(
      _withStatOpenMateriaRetreat(move, retreat),
      after: true,
    );
  }

  Future<void> _replyStatOpenMateriaMovement(
    Map<String, dynamic> request,
    _StatOpenMateriaPermit? permit,
    bool accepted,
  ) async {
    if (!mounted ||
        !realtimeIsMasterRole ||
        request['scope'] != permissionScope ||
        request['campaignId'] != permissionCampaignId) {
      return;
    }
    final move = permit?.move;
    await realtimeService?.sendPermissionEvent(
      'permission_decision',
      permissionEnvelope({
        for (final field in _statOpenMateriaIdentityFields)
          field: request[field],
        'action': _statOpenMateriaPermission,
        'phase': request['phase'],
        'accepted': accepted,
        if (permit != null) 'proof': permit.proof,
        if (request.containsKey('retreat')) 'retreat': request['retreat'],
        if (request.containsKey('attackId')) 'attackId': request['attackId'],
        if (accepted && request['phase'] == 'plan') ...{
          'retreatLimit': permit?.retreatLimit ?? 0,
          'approachLength': move == null
              ? 0
              : (move.meters(move.start!, move.landing!) * 100).round(),
        },
      }),
    );
  }

  bool commitStatOpenMateriaMove(
    _StatOpenMateriaMove move, {
    bool after = false,
    String? attackId,
  }) {
    final remote = move.remote;
    if (remote != null) {
      if (after && attackId != null && readIntValue(remote['retreat']) > 0) {
        unawaited(
          _requestStatOpenMateriaMovement({
            ...remote,
            'attackId': attackId,
          }, 'retreat').then((reply) {
            if (mounted && reply?['accepted'] != true) {
              aggiungiLog(
                '[OPEN MATERIA] Il Master non ha confermato il rientro.',
              );
            }
          }),
        );
      }
      return true;
    }
    final token = move.token;
    if (token == null) return true;
    final start = after ? move.landing! : move.start!;
    final end = after ? move.finish : move.landing;
    if (end == null || end == start) return true;
    final meters = move.meters(start, end);
    if (_statOpenMapPosition(token) != start ||
        !_statOpenPathClear(start, end) ||
        meters > localMapTokenMovementRemaining(token) + .000001) {
      return false;
    }
    consumeLocalMapTokenMovement(
      token,
      Offset(
        (end.dx - start.dx) * move.width,
        (end.dy - start.dy) * move.height,
      ),
      move.width,
      move.height,
    );
    token['x'] = end.dx;
    token['y'] = end.dy;
    notifyVttCanvasChanged(save: true);
    evaluateVttTriggersForToken(token);
    unawaited(sendAuthoritativeVttTokenPosition(token));
    return true;
  }
}
