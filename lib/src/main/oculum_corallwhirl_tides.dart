part of '../../main.dart';

/// Progress along the dash for a token whose centre is within the corridor.
/// Coordinates and radius use metres in all three dimensions.
double? oculumCorallwhirlCrossing(
  Offset start,
  Offset end,
  Offset target, {
  required double elevationDifference,
  required double radius,
}) {
  final route = end - start;
  final squaredDistance = route.distanceSquared;
  if (squaredDistance <= 0 || radius <= 0) return null;
  final point = target - start;
  final projection =
      ((point.dx * route.dx + point.dy * route.dy) / squaredDistance)
          .clamp(0.0, 1.0)
          .toDouble();
  final horizontal = (point - route * projection).distanceSquared;
  return horizontal + elevationDifference * elevationDifference <=
          radius * radius
      ? projection
      : null;
}

typedef _CorallwhirlTarget = ({
  Map<String, dynamic> token,
  Offset position,
  double elevation,
});

extension _OculumCorallwhirlTides on _OculumHomePageState {
  Future<bool> selectCorallwhirlDash({
    required String label,
    required OculumStructuredEffect effect,
    OculumSkillCost? cost,
    OculumAbilityCooldown? cooldown,
    bool Function()? valid,
  }) async {
    if (!requireConfirmedSheetRoll()) return false;
    final owner = sheetTagAt(schedaCorrente);
    final encounter = onlineCombatEncounterId;
    final scope = permissionScope;
    final scene = activeVttScene;
    final turn = masterInitiativeTurnKey();
    final actor = escapeToken(owner);
    final sourceFight = actor?['fightInstanceId'];
    final mapToken = actor == null
        ? null
        : localMapTokenForInitiativeToken(actor);
    bool available() =>
        mounted &&
        sheetTagAt(schedaCorrente) == owner &&
        onlineCombatEncounterId == encounter &&
        permissionScope == scope &&
        activeVttScene.id == scene.id &&
        masterInitiativeTurnKey() == turn &&
        _usesLocalMasterInitiative &&
        (!onlineMasterApprovalRequired || realtimeIsMasterRole) &&
        !vttShowingRemoteScene &&
        currentCombatIsActive() &&
        !outsideFight &&
        hpCorrenti() > 0 &&
        !hasCondition('paralisi_fato') &&
        !elementalSphereFrozen &&
        !elementalSphereSoulSeparated &&
        cooldown?.ready != false &&
        (valid == null || valid()) &&
        actor != null &&
        identical(escapeToken(owner), actor) &&
        masterInitiativeTokenCanAct(actor) &&
        actor['status'] == 'active' &&
        mapToken != null &&
        identical(localMapTokenForInitiativeToken(actor), mapToken) &&
        canManageLocalMapToken(mapToken);
    if (mapToken == null ||
        !available() ||
        !prepareLocalMapTokenMovement(mapToken)) {
      aggiungiLog(
        '[TRE MAREE] Serve il tuo turno e un token attivo sulla mappa del Master.',
      );
      return false;
    }

    Offset position(Map<String, dynamic> token) =>
        Offset(localMapTokenAxis(token, 'x'), localMapTokenAxis(token, 'y'));
    final start = position(mapToken);
    final elevation = readDoubleValue(mapToken['elevationMeters']);
    final width = mapWidthMetersValue();
    final height = mapHeightMetersValue();
    final multiplier = max(
      1,
      oculumEvaluateStructuredEffectValue(
        effect,
        variables: formulaValueContext(),
        subtraits: hiddenEyeStats,
      ),
    );
    final radius = scene.distancePerCell / 2;
    Offset metres(Offset point) => Offset(point.dx * width, point.dy * height);
    final team = combatScoutSide(owner);
    List<_CorallwhirlTarget> targets() => [
      for (final token in onlineAttackTokens())
        if (_attackTokenIsOpponent(token, team) &&
            masterInitiativeTokenCanAct(token) &&
            !escapeTokenIsOut(onlineCombatTokenTag(token)))
          if (localMapTokenForInitiativeToken(token)
              case final Map<String, dynamic> target)
            if (!identical(target, mapToken))
              (
                token: token,
                position: position(target),
                elevation: readDoubleValue(target['elevationMeters']),
              ),
    ];

    List<Map<String, dynamic>> crossed(
      Offset destination,
      List<_CorallwhirlTarget> candidates,
    ) {
      final from = metres(start);
      final to = metres(destination);
      final ordered = <({Map<String, dynamic> token, double progress})>[];
      for (final target in candidates) {
        final progress = oculumCorallwhirlCrossing(
          from,
          to,
          metres(target.position),
          elevationDifference: target.elevation - elevation,
          radius: radius,
        );
        if (progress != null) {
          ordered.add((token: target.token, progress: progress));
        }
      }
      ordered.sort((a, b) => a.progress.compareTo(b.progress));
      return ordered.map((target) => target.token).toList(growable: false);
    }

    bool canReach(Offset destination) {
      final route = metres(destination) - metres(start);
      return route.distance > 0 &&
          route.distance <=
              localMapTokenMovementRemaining(mapToken) * multiplier + .000001 &&
          vttConstrainTokenDelta(mapToken, route, width, height) == route;
    }

    (String, String) targetIdentity(Map<String, dynamic> token) =>
        (onlineCombatTokenTag(token), '${token['fightInstanceId'] ?? ''}');
    final candidates = targets();
    Offset? selected;
    final destination = await showDialog<Offset>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (context, refresh) {
          final point = selected;
          final withinRange = point != null && canReach(point);
          final names = point == null
              ? const <String>[]
              : crossed(point, candidates).map(faunaTargetName).toList();
          return AlertDialog(
            title: Text(t('Scatto delle Tre Maree', 'Three-Tide Dash')),
            content: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t(
                      'Tocca la destinazione dello scatto.',
                      'Tap the destination of the dash.',
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 190,
                    child: LayoutBuilder(
                      builder: (context, limits) => GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapUp: (event) => refresh(() {
                          selected = Offset(
                            (event.localPosition.dx / limits.maxWidth)
                                .clamp(0.0, 1.0)
                                .toDouble(),
                            (event.localPosition.dy / limits.maxHeight)
                                .clamp(0.0, 1.0)
                                .toDouble(),
                          );
                        }),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(color: primaryColor),
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              for (final token in [
                                (
                                  point: start,
                                  icon: Icons.adjust,
                                  color: primaryColor,
                                ),
                                for (final target in candidates)
                                  (
                                    point: target.position,
                                    icon: Icons.circle,
                                    color: Colors.redAccent,
                                  ),
                                if (point != null)
                                  (
                                    point: point,
                                    icon: Icons.location_on,
                                    color: tertiaryColor,
                                  ),
                              ])
                                Align(
                                  alignment: Alignment(
                                    token.point.dx * 2 - 1,
                                    token.point.dy * 2 - 1,
                                  ),
                                  child: Icon(
                                    token.icon,
                                    color: token.color,
                                    size: 13,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    point == null
                        ? t(
                            'Scegli un punto della mappa.',
                            'Choose a map point.',
                          )
                        : !withinRange
                        ? t(
                            'Destinazione fuori portata o passaggio ostruito.',
                            'Destination out of reach or path blocked.',
                          )
                        : '${(metres(point) - metres(start)).distance.toStringAsFixed(1)} m'
                              '${names.isEmpty ? '' : ' · ${names.join(', ')}'}',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialog),
                child: Text(t('Annulla', 'Cancel')),
              ),
              FilledButton(
                onPressed: withinRange
                    ? () => Navigator.pop(dialog, point)
                    : null,
                child: Text(t('Scatta', 'Dash')),
              ),
            ],
          );
        },
      ),
    );
    if (destination == null || !available() || !canReach(destination)) {
      return false;
    }

    final hits = crossed(destination, candidates);
    final targetIdentities = hits.map(targetIdentity).toList();
    bool canCommit() =>
        available() &&
        actor?['fightInstanceId'] == sourceFight &&
        position(mapToken) == start &&
        readDoubleValue(mapToken['elevationMeters']) == elevation &&
        canReach(destination) &&
        listEquals(
          targetIdentities,
          crossed(destination, targets()).map(targetIdentity).toList(),
        );
    if (!canCommit()) return false;
    var natural = 0;
    var attack = 0;
    if (hits.isNotEmpty) {
      final calculation = _captureSheetRollMath(20, vc() + tiroGlobaleBonus());
      final roll = tiraDado(20);
      final review = await _reviewInteractiveSheetRoll(
        label: label,
        natural: roll,
        total: calculation.totalForNatural(roll),
        faces: 20,
        totalForNatural: calculation.totalForNatural,
        reviewFailure: false,
        succeeds: (_, total) => total >= 0,
        canCommit: canCommit,
      );
      if (review == null) return false;
      natural = review.natural;
      attack = review.total;
    }

    final travelled = (metres(destination) - metres(start)).distance;
    bool settle(Map<String, int> payments) {
      if (!canCommit() ||
          !prepareLocalMapTokenMovement(mapToken) ||
          !_consumeLocalCombatTurnResource(
            owner,
            'azione',
            advanceMasterTurn: false,
            payForAction: () => spendArtSkillPayments(payments),
          )) {
        return false;
      }
      cooldown?.activate();
      final damage = oculumDamagePerTarget(
        dannoTotale(),
        hits.length,
        flatBonusPerTarget: travelled.floor(),
      );
      final movementUsed = localMapTokenMovementUsed(mapToken);
      mapToken
        ..['x'] = destination.dx
        ..['y'] = destination.dy
        ..['movementUsedMeters'] = movementUsed + travelled / multiplier;
      final group = 'tre-maree:${DateTime.now().microsecondsSinceEpoch}';
      final packets = <Map<String, dynamic>>[];
      for (var i = 0; i < hits.length; i++) {
        final target = hits[i];
        final id = '$group:$i';
        final packet = <String, dynamic>{
          'id': id,
          'attackGroupId': group,
          'scope': scope,
          'encounterId': encounter,
          'sourceTag': owner,
          'sourceName': realtimeDisplayName(),
          'sourceFightInstance': sourceFight,
          'sourceMonsterBookId': faunaCurrentMonsterId,
          'targetTag': onlineCombatTokenTag(target),
          'targetName': faunaTargetName(target),
          'targetFightInstance': target['fightInstanceId'],
          'attack': attack,
          'damage': damage,
          'damageTotal': damage,
          'effects': [effect.toJson()],
          'difficulty': normalizedCampaignDifficulty(),
          'element': 'acqua',
          'natural': natural,
          'dieFaces': 20,
          'level': activeCriticalLevel(),
          'grade': activeCriticalGrade(),
          'choice': 'vc',
          'abilityName': label,
          'melee': true,
          'status': 'pending',
          'timestamp': DateTime.now().toIso8601String(),
          'corallwhirlDash': true,
          'corallwhirlTie': Random.secure().nextInt(2),
        };
        onlineCombatRequests[id] = packet;
        packets.add(packet);
      }
      if (hits.isNotEmpty) registerValidRoll();
      notifyVttCanvasChanged(save: true);
      unawaited(sendAuthoritativeVttTokenPosition(mapToken));
      aggiungiLog(
        '[TRE MAREE] ${travelled.toStringAsFixed(1)} m · '
        '${hits.length} bersagli · $damage Danni a testa.',
      );
      for (final packet in packets) {
        unawaited(sendOnlineCombatRequest(packet));
        receiveLocalCombatAttack(packet);
      }
      evaluateVttTriggersForToken(mapToken);
      advanceMasterInitiativeAfterAction(owner);
      programmaSalvataggio();
      return true;
    }

    if (cost == null ||
        (oculumNormalizeEffectResource(cost.resource) == 'nessuna' &&
            cost.additionalCosts.isEmpty)) {
      return settle(const {});
    }
    return useConfiguredAbility(
      source: label,
      effects: const [],
      cost: cost,
      cooldown: cooldown,
      paymentOnly: true,
      valid: canCommit,
      commitPayment: settle,
    );
  }
}
