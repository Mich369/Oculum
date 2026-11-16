part of '../../main.dart';

const oculumElementalSphereSoulCondition = 'elemental_sphere_soul_separated';

extension _OculumElementalSphereSpiritual on _OculumHomePageState {
  bool get elementalSphereSoulSeparated => activeConditions.any(
    (condition) =>
        condition.conditionType == oculumElementalSphereSoulCondition &&
        condition.metadata['sphereFightScope'] == permissionScope &&
        condition.metadata['sphereEncounterId'] == onlineCombatEncounterId,
  );

  bool elementalSphereSoulSeparatedInSheet(Map sheet) {
    final conditions = sheet['conditions'];
    return conditions is List &&
        conditions.whereType<Map>().any((condition) {
          final metadata = condition['metadata'];
          return (condition['conditionType'] ?? condition['type']) ==
                  oculumElementalSphereSoulCondition &&
              metadata is Map &&
              metadata['sphereFightScope'] == permissionScope &&
              metadata['sphereEncounterId'] == onlineCombatEncounterId;
        });
  }

  bool applyElementalSphereSoulSeparation(
    Map request, {
    required int durationTurns,
    required String difficulty,
  }) {
    final sourceTag = '${request['sourceTag'] ?? ''}'.trim();
    final targetTag = '${request['targetTag'] ?? ''}'.trim();
    final packetId = '${request['id'] ?? ''}'.trim();
    final encounter = onlineCombatEncounterId;
    if (sourceTag.isEmpty ||
        packetId.isEmpty ||
        encounter.isEmpty ||
        request['encounterId'] != encounter ||
        request['scope'] != permissionScope ||
        !oculumSameSheetIdentity(targetTag, sheetTagAt(schedaCorrente)) ||
        oculumSameSheetIdentity(sourceTag, targetTag) ||
        !faunaReceipt('sphere-soul:$permissionScope:$encounter:$packetId')) {
      return false;
    }

    final duration = max(
      2,
      (durationTurns > 0 ? durationTurns : 3) +
          oculumElementalSphereDifficulty(difficulty).turns,
    );
    return applyCondition(
      oculumElementalSphereSoulCondition,
      duration: duration,
      source: 'Sfera Spirituale · $sourceTag',
      metadata: {
        'referenceCurseSource': 'sphere-soul:$packetId',
        'sphereSourceTag': sourceTag,
        'sphereFightScope': permissionScope,
        'sphereEncounterId': encounter,
        'sphereAttackId': packetId,
        'sphereOpportunityUsed': false,
      },
    );
  }

  bool _elementalSphereOpportunityAvailable(Map metadata, String sourceTag) =>
      metadata['sphereFightScope'] == permissionScope &&
      metadata['sphereEncounterId'] == onlineCombatEncounterId &&
      oculumSameSheetIdentity(metadata['sphereSourceTag'], sourceTag) &&
      metadata['sphereOpportunityUsed'] != true;

  ({String sourceTag, String targetTag, String conditionId})?
  elementalSphereOpportunityFor(String targetTag, String sourceTag) {
    if (!currentCombatIsActive() ||
        !controlsOnlineCombatSheet(targetTag) ||
        oculumSameSheetIdentity(sourceTag, targetTag)) {
      return null;
    }
    final tokens = onlineCombatTokens();
    final source = tokens
        .where((token) => combatTokenMatchesSheet(token, sourceTag))
        .firstOrNull;
    final target = tokens
        .where((token) => combatTokenMatchesSheet(token, targetTag))
        .firstOrNull;
    if (source == null ||
        target == null ||
        !masterInitiativeTokenCanAct(source) ||
        masterInitiativeTokenIsTemporary(source) ||
        source['outsideFight'] == true ||
        masterInitiativeTokenIsDead(target) ||
        target['outsideFight'] == true ||
        combatParticipantsShareTeam(source, target)) {
      return null;
    }
    final index = localSheetIndexForOculumTag(targetTag);
    if (index < 0) return null;
    final conditions = index == schedaCorrente
        ? activeConditions.map((condition) => condition.toJson())
        : (schedePersonaggio[index]['conditions'] as List? ?? const [])
              .whereType<Map>();
    final condition = conditions.where((condition) {
      final metadata = condition['metadata'];
      return condition['conditionType'] == oculumElementalSphereSoulCondition &&
          metadata is Map &&
          _elementalSphereOpportunityAvailable(metadata, sourceTag);
    }).firstOrNull;
    final id = '${condition?['id'] ?? ''}';
    return id.isEmpty
        ? null
        : (sourceTag: sourceTag, targetTag: targetTag, conditionId: id);
  }

  bool claimElementalSphereOpportunity({
    required String targetTag,
    required String sourceTag,
    required String conditionId,
  }) {
    final opportunity = elementalSphereOpportunityFor(targetTag, sourceTag);
    if (opportunity == null || opportunity.conditionId != conditionId) {
      return false;
    }
    var claimed = false;
    faunaForOwnedSheet(targetTag, () {
      final condition = activeConditions.where((condition) {
        return condition.id == conditionId &&
            condition.conditionType == oculumElementalSphereSoulCondition &&
            _elementalSphereOpportunityAvailable(condition.metadata, sourceTag);
      }).firstOrNull;
      if (condition == null) return;
      condition.metadata['sphereOpportunityUsed'] = true;
      claimed = true;
      programmaSalvataggio();
    });
    return claimed;
  }

  List<Widget> elementalSphereOpportunityActions(
    void Function(VoidCallback action) select,
  ) {
    if (!localTurnCombat ||
        realtimeService?.isConnected == true ||
        elementalSphereFrozen ||
        elementalSphereSoulSeparated ||
        hasCondition('paralisi_fato')) {
      return const [];
    }
    final source = sheetTagAt(schedaCorrente);
    return [
      for (final token in onlineCombatTokens())
        if (elementalSphereOpportunityFor(onlineCombatTokenTag(token), source)
            case final opportunity?)
          ListTile(
            leading: const Icon(Icons.bolt_outlined),
            title: Text(t('Attacco di opportunità', 'Opportunity attack')),
            subtitle: Text(faunaTargetName(token)),
            onTap: () => select(
              () => unawaited(
                planOnlineAttack(
                  targetId: opportunity.targetTag,
                  sphereSoulOpportunityId: opportunity.conditionId,
                ),
              ),
            ),
          ),
    ];
  }

  void clearElementalSphereSoulSeparation(String encounter) {
    if (encounter.isEmpty) return;
    final conditions = activeConditions.where((condition) {
      return condition.conditionType == oculumElementalSphereSoulCondition &&
          condition.metadata['sphereFightScope'] == permissionScope &&
          condition.metadata['sphereEncounterId'] == encounter;
    }).toList();
    for (final condition in conditions) {
      removeCondition(condition, force: true, expired: true);
    }
  }
}
