part of '../../main.dart';

const _solarObserverHitsKey = 'solarObserverHits';
const _solarObserverSourceKey = 'solarObserverSource';

Map? _sanguifangBiteEffect(Map request) {
  final effects = request['effects'];
  if (effects is! List) return null;
  return effects.whereType<Map>().where((effect) {
    return effect['type'] == 'planar' &&
        effect['target'] == oculumBiterBiteEffect;
  }).firstOrNull;
}

extension _OculumSolarObserverAndBiter on _OculumHomePageState {
  void claimSanguifangBite(Map<String, dynamic> request, {required bool hit}) {
    final effect = _sanguifangBiteEffect(request);
    final encounter = '${request['encounterId'] ?? ''}';
    final packet = '${request['id'] ?? ''}';
    if (!hit ||
        effect == null ||
        encounter.isEmpty ||
        packet.isEmpty ||
        request['goblinGuardianIntercepted'] != null ||
        request['scope'] != permissionScope ||
        encounter != onlineCombatEncounterId ||
        _friendlyFireFor(request).friendly) {
      return;
    }
    faunaForOwnedSheet('${request['sourceTag'] ?? ''}', () {
      if (!faunaReceipt('sanguifang:$encounter:$packet')) return;
      final healing = oculumSanguifangHealing(
        readIntValue(request['sanguifangTotalDamage'], fallback: dannoTotale()),
        percent: readIntValue(effect['valueExpression'], fallback: 15),
      );
      final before = hpCorrenti();
      applyStructuredHealing('vita', healing);
      if (hpCorrenti() > before) {
        sendRealtimeHpChanged();
        notifyActiveSheetSummaryChanged();
      }
      programmaSalvataggio();
    });
  }

  void resolveObserverAndBiterHit(
    Map<String, dynamic> request, {
    required bool hit,
    required bool critical,
    required bool doubleCritical,
  }) {
    if (!hit) return;
    final bite = _sanguifangBiteEffect(request);
    final packet = '${request['id'] ?? ''}';
    final encounter = '${request['encounterId'] ?? ''}';
    final sourceTag = '${request['sourceTag'] ?? ''}';
    if (packet.isEmpty || encounter.isEmpty || sourceTag.isEmpty) return;
    final attackerIndex = localSheetIndexForOculumTag(sourceTag);
    final sourceId = attackerIndex < 0
        ? request['sourceMonsterBookId']
        : schedePersonaggio[attackerIndex]['monsterBookSourceId'];
    final observer =
        '$sourceId'.split('_variante_').first == oculumSolarObserverId;
    if ((!observer && bite == null) || _friendlyFireFor(request).friendly) {
      return;
    }
    if (bite != null) {
      request['sanguifangHit'] = true;
      claimSanguifangBite(request, hit: true);
    }
    final criticalProtected = criticalShieldBlocksDebuffs(request);
    if (!criticalProtected &&
        (critical ||
            doubleCritical ||
            readIntValue(request['natural']) ==
                oculumAttackRollFaces(request)) &&
        bite != null &&
        faunaReceipt('sanguifang-bleeding:$encounter:$packet')) {
      applyCondition('sanguinamento', source: 'Morso dell’Errante');
    }
    if (!observer) return;
    final prior = planarState[_solarObserverHitsKey];
    final ledger = prior is Map
        ? Map<String, dynamic>.from(prior)
        : <String, dynamic>{};
    final transformed = oculumRecordSolarObserverHit(
      ledger,
      fightKey: '$permissionScope:$encounter',
      sourceTag: sourceTag,
      packetId: packet,
      hit: true,
      doubleCritical: doubleCritical && !criticalProtected,
    );
    planarState[_solarObserverHitsKey] = ledger;
    if (!transformed) return;
    final source = attackerIndex < 0
        ? onlineCombatTokens()
              .where((token) => combatTokenMatchesSheet(token, sourceTag))
              .firstOrNull
        : schedePersonaggio[attackerIndex];
    applyCondition(
      oculumSolarGoldCondition,
      duration: oculumSolarGoldTurns,
      durationType: OculumConditionDurationType.turns,
      source: 'Osservatore del Sole',
      metadata: {
        _solarObserverSourceKey: sourceTag,
        'referenceCurseSource': 'solgaze:$sourceTag',
        'releaseDifficulty': oculumSolarGoldReleaseDifficulty(
          readIntValue(
            source?[attackerIndex < 0 ? 'level' : 'livello'],
            fallback: readIntValue(request['level']),
          ),
          readIntValue(
            source?[attackerIndex < 0 ? 'grade' : 'grado'],
            fallback: readIntValue(request['grade']),
          ),
        ),
      },
    );
  }

  void resetSolarObserverFight() {
    planarState.remove(_solarObserverHitsKey);
    for (final condition in activeConditions.where((condition) {
      return condition.conditionType == oculumSolarGoldCondition &&
          condition.metadata.containsKey(_solarObserverSourceKey);
    }).toList()) {
      removeCondition(condition, force: true);
    }
  }

  Future<void> releaseSolarObserverGold(
    OculumConditionInstance condition,
    String trait,
    String resource,
  ) async {
    if (!const {'forza', 'controllo_corporeo', 'volonta'}.contains(trait) ||
        !const {'azione', 'reazione'}.contains(resource) ||
        condition.conditionType != oculumSolarGoldCondition ||
        !activeConditions.contains(condition) ||
        !currentTurnTrackerIsActive() ||
        !_solarGoldProofsInFlight.add(condition.id)) {
      return;
    }
    final origin = currentSheetScrollId();
    final fight = onlineCombatEncounterId;
    final scope = permissionScope;
    try {
      if (!await requestUtilitySpend(resource, preferFreeReaction: false) ||
          !mounted ||
          origin != currentSheetScrollId() ||
          fight != onlineCombatEncounterId ||
          scope != permissionScope ||
          !activeConditions.contains(condition)) {
        return;
      }
      final stat = hiddenEyeStats.where((s) => s.id == trait).firstOrNull;
      final base = trait == 'volonta'
          ? volontaTotale()
          : stat == null
          ? 0
          : hiddenEyeTotal(stat);
      final total = rollTotalWithCritical(tiraD20(), 20, [
        base,
        tiroGlobaleBonus(),
      ]);
      final difficulty = readIntValue(
        condition.metadata['releaseDifficulty'],
        fallback: 10,
      );
      final freed = total >= difficulty;
      if (freed) removeCondition(condition, force: true);
      aggiungiLog(
        '[LIBERAZIONE DALL’ORO] ${_solarGoldTraitLabel(trait)} $total / DT $difficulty: '
        '${freed ? t('libero', 'freed') : t('trasformazione mantenuta', 'transformation remains')}.',
      );
      programmaSalvataggio();
      if (mounted) updateOculumHomeUi(() {});
      await flushPendingCombatTurnResources();
    } finally {
      _solarGoldProofsInFlight.remove(condition.id);
    }
  }

  String _solarGoldTraitLabel(String trait) => switch (trait) {
    'forza' => t('Forza', 'Strength'),
    'controllo_corporeo' => t('Controllo corporeo', 'Body control'),
    _ => t('Volontà', 'Will'),
  };

  Widget solarObserverGoldificationControls({
    required VoidCallback refresh,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final condition in activeConditions.where(
        (c) => c.conditionType == oculumSolarGoldCondition,
      )) ...[
        Text(
          '${conditionName(condition)} · ${condition.duration} · '
          'DT ${readIntValue(condition.metadata['releaseDifficulty'], fallback: 10)}',
        ),
        Wrap(
          spacing: 6,
          children: [
            for (final trait in const [
              'forza',
              'controllo_corporeo',
              'volonta',
            ])
              for (final resource in const ['azione', 'reazione'])
                OutlinedButton(
                  onPressed:
                      !currentTurnTrackerIsActive() ||
                          _solarGoldProofsInFlight.contains(condition.id)
                      ? null
                      : () async {
                          final proof = releaseSolarObserverGold(
                            condition,
                            trait,
                            resource,
                          );
                          refresh();
                          await proof;
                          refresh();
                        },
                  child: Text(
                    '${_solarGoldTraitLabel(trait)} · '
                    '${resource == 'azione' ? t('Azione', 'Action') : t('Reazione', 'Reaction')}',
                  ),
                ),
          ],
        ),
      ],
    ],
  );
}
