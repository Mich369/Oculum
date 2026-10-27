part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

int oculumMantleProtection({
  required int initial,
  required int wear,
  required bool critical,
  required bool doubleCritical,
  int criticalWear = 5,
  int doubleCriticalWear = 20,
}) =>
    (initial -
            max(0, wear) -
            (doubleCritical
                ? doubleCriticalWear
                : critical
                ? criticalWear
                : 0))
        .clamp(0, 100)
        .toInt();

int oculumMagicShieldAbsorption({
  required int attack,
  required int defense,
  required bool doubleCritical,
  int maximum = 90,
  int minimum = 25,
  int lossPerMargin = 5,
}) => doubleCritical
    ? minimum.clamp(0, 100)
    : (maximum - max(0, attack - defense - 1) * lossPerMargin).clamp(
        minimum,
        maximum,
      );

bool oculumCanAttackStrangePresence({
  required int madness,
  required int days,
}) => madness >= 2 || days >= 37;

InventoryItem oculumRedcapBody({
  required String killId,
  required bool cooked,
  int level = 0,
  int grade = 0,
}) => InventoryItem(
  nome: cooked
      ? 'Funghetto Cappuccio Rosso cotto'
      : 'Funghetto Cappuccio Rosso',
  quantita: 1,
  peso: .1,
  livelloOggetto: level,
  gradoOggetto: grade,
  note: cooked
      ? 'Antiveleno: rimuove Avvelenato e Veleno Putrido, senza immunità permanente.'
      : 'Corpo del funghetto: cuocilo per ottenere un antiveleno. Non consumare crudo.',
  craftData: {'redcapBody': true, 'cooked': cooked},
  monsterLoot: {
    'id': '$killId:redcap',
    'monsterId': 'funghetto_cappuccio_rosso',
  },
);

extension _OculumReferenceCreatures on _OculumHomePageState {
  bool get isWrongBandit => const {
    'scostubandito_errato',
    'scostubandito_veterano_errato',
  }.contains(faunaCurrentMonsterId);
  Map get referenceCreatureRules =>
      monsterBookEntryById(faunaCurrentMonsterId)?.encounterRules ?? const {};
  int referenceRule(String key, int fallback) => readIntValue(
    planarState[key],
    fallback: readIntValue(referenceCreatureRules[key], fallback: fallback),
  );
  int get referenceHaloDefense =>
      faunaPassive('time_cyclops_halo') is OculumStructuredEffect &&
          hpCorrenti() * 2 > maxHp()
      ? referenceRule(
          'haloDefenseBonus',
          readIntValue(
            faunaPassive('time_cyclops_halo')?.valueExpression,
            fallback: 3,
          ),
        )
      : 0;
  int get referenceAttackBonus =>
      (isWrongBandit && !hasCondition('disarmato')
          ? 2 + (planarState['wrongBanditEmpowered'] == true ? 6 : 0)
          : 0) -
      referencePresencePenalty;
  int get referencePresencePenalty {
    if (follia() <= 0 ||
        currentCombatIsActive() ||
        faunaCurrentMonsterId == 'strana_presenza') {
      return 0;
    }
    return onlineCombatTokens()
            .where(
              (t) =>
                  monsterBookIdForCombatToken(t) == 'strana_presenza' &&
                  !const {'dead', 'fled', 'expired'}.contains(t['status']),
            )
            .isEmpty
        ? 0
        : 1;
  }

  void referenceBeforeMagic(List<OculumStructuredEffect> effects) {
    if (!isWrongBandit ||
        effects.every(
          (e) =>
              e.target == 'wrong_bandit_shield' ||
              e.target == 'wrong_bandit_sword',
        )) {
      return;
    }
    if (referenceRule('maintainedMagicSlots', 1) == 1) {
      planarState['wrongBanditShieldActive'] = false;
    }
    // With shield + infusion already maintained, a transient third spell
    // releases the infusion; the veteran can retain its shield while casting.
    if (referenceRule('maintainedMagicSlots', 1) == 2 &&
        planarState['wrongBanditShieldActive'] == true &&
        planarState['wrongBanditEmpowered'] == true &&
        effects.every((e) => e.target != 'wrong_bandit_empower')) {
      planarState['wrongBanditEmpowered'] = false;
      aggiungiLog(
        '[MAGIE] Infusione sospesa: scudo e magia in corso occupano i due spazi.',
      );
    }
  }

  int get referenceDefenseRollBonus => isWrongBandit
      ? (planarState['wrongBanditShieldActive'] == true &&
                readIntValue(planarState['wrongBanditShieldHp']) > 0
            ? referenceRule('magicShieldDefenseBase', 5) +
                  referenceRule('magicShieldDefensePerLevel', 2) *
                      leggiNumero(livelloController)
            : 2 * leggiNumero(livelloController))
      : 0;

  bool get referenceMantleAvailable =>
      faunaCurrentMonsterId.startsWith('aberrazione_metallica_') ||
      planarState['mantleInitialProtection'] is num;
  int get referenceResistanceValue {
    final resistance = hiddenEyeStats
        .where((s) => s.id == 'resistenza')
        .firstOrNull;
    return max(
      0,
      resistance == null ? resilienzaTotale() : hiddenEyeTotal(resistance),
    );
  }

  Future<void> defendWithReferenceMantle(
    Map<String, dynamic> request,
    String resource,
  ) async {
    final tag = sheetTagAt(schedaCorrente), id = '${request['id']}';
    if (!referenceMantleAvailable ||
        !controlsOnlineCombatSheet(tag) ||
        request['targetTag'] != tag ||
        request['status'] != 'pending' ||
        request['scope'] != permissionScope ||
        request['encounterId'] != onlineCombatEncounterId ||
        !identical(onlineCombatRequests[id], request) ||
        !onlineCombatResolving.add(id)) {
      return;
    }
    try {
      if (planarState['mantlePrepared'] != true &&
          !await requestUtilitySpend(resource, preferFreeReaction: false)) {
        return;
      }
      if (!mounted ||
          sheetTagAt(schedaCorrente) != tag ||
          request['status'] != 'pending') {
        return;
      }
      planarState.remove('mantlePrepared');
      await applyResolvedOnlineDefense(
        request,
        'mantello',
        referenceResistanceValue,
      );
    } finally {
      onlineCombatResolving.remove(id);
    }
  }

  int referenceAbsorbDamage(
    int damage,
    int mantlePercent,
    int magicShieldPercent,
  ) {
    var remaining = max(0, damage);
    if (mantlePercent > 0) {
      remaining = (remaining * (100 - mantlePercent.clamp(0, 100)) / 100)
          .floor();
    }
    if (magicShieldPercent > 0 &&
        planarState['wrongBanditShieldActive'] == true) {
      final hp = max(0, readIntValue(planarState['wrongBanditShieldHp']));
      final absorbed = min(
        hp,
        (remaining * magicShieldPercent.clamp(0, 100) / 100).ceil(),
      );
      remaining -= absorbed;
      planarState['wrongBanditShieldHp'] = hp - absorbed;
      if (hp <= absorbed) planarState['wrongBanditShieldActive'] = false;
      aggiungiLog(
        '[SCUDO MAGICO] Assorbiti $absorbed Danni; Scudo ${hp - absorbed}.',
      );
    }
    return remaining;
  }

  bool referenceTargetAllowed(Map<String, dynamic> token) {
    if (monsterBookIdForCombatToken(token) != 'strana_presenza') return true;
    return oculumCanAttackStrangePresence(
      madness: follia(),
      days: readIntValue(planarState['madnessDays']),
    );
  }

  Map<String, dynamic> referencePublicCopyMask(Map<String, dynamic> token) =>
      monsterBookIdForCombatToken(token) == 'il_doppione'
      ? {'type': 'Mostro', 'healthLabel': '???'}
      : const {};

  Future<void> useRedcapBody(InventoryItem item) async {
    if (item.quantita <= 0 || !inventario.contains(item)) return;
    if (item.craftData['cooked'] != true) {
      final cooked = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: const Text('Cuoci il Funghetto Cappuccio Rosso'),
          content: const Text(
            'Quando hai un fuoco disponibile, una cottura trasforma un funghetto in una dose di antiveleno.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog, false),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialog, true),
              child: const Text('Fuoco disponibile · Cuoci'),
            ),
          ],
        ),
      );
      if (cooked != true ||
          !mounted ||
          !inventario.contains(item) ||
          item.quantita <= 0) {
        return;
      }
      item.quantita--;
      inventario.add(
        oculumRedcapBody(
          killId:
              '${item.monsterLoot['id']}:cooked:${DateTime.now().microsecondsSinceEpoch}',
          cooked: true,
          level: item.livelloOggetto,
          grade: item.gradoOggetto,
        ),
      );
      if (item.quantita == 0) inventario.remove(item);
    } else {
      if (!await requestUtilitySpend('azione')) return;
      for (final condition
          in activeConditions
              .where(
                (c) => const {
                  'avvelenato',
                  'veleno_putrido',
                }.contains(c.conditionType),
              )
              .toList()) {
        removeCondition(condition, force: true);
      }
      item.quantita--;
      if (item.quantita == 0) inventario.remove(item);
      aggiungiLog('[ANTIVELENO] Rimossi Avvelenato e Veleno Putrido.');
    }
    invalidateDerivedDataCaches();
    if (mounted) setState(() {});
    programmaSalvataggio();
  }

  void referenceCreatureTurn(Map<String, dynamic> token) {
    if (!currentCombatIsActive() ||
        masterInitiativeActiveIndex < 0 ||
        masterInitiativeActiveIndex >= masterInitiativeTokens.length ||
        !identical(
          masterInitiativeTokens[masterInitiativeActiveIndex],
          token,
        )) {
      return;
    }
    final tag = publicInitiativeSourceTag(token);
    final group = masterInitiativeGroups
        .where((g) => g['id'] == selectedMasterInitiativeGroupId)
        .firstOrNull;
    final stamp =
        '$onlineCombatEncounterId:$selectedMasterInitiativeGroupId:${readIntValue(group?['completedFightCount'])}:$masterInitiativeRound';
    var wave = false;
    faunaForOwnedSheet(tag, () {
      if (planarState['referenceTurnStamp'] == stamp) return;
      planarState['referenceTurnStamp'] = stamp;
      if (faunaCurrentMonsterId == 'il_doppione' &&
          planarState['doppioneCopy'] != true) {
        // Authored +1 is exact, including with Illness Art.
        illnessArtSbloccata = true;
        folliaController.text = '${follia() + 1}';
        final turn = readIntValue(planarState['doppioneOwnTurns']) + 1;
        planarState['doppioneOwnTurns'] = turn;
        wave =
            turn % referenceRule('madnessWaveEveryTurns', 3).clamp(1, 100) == 0;
        aggiungiLog('[DOPPIONE] +1 Follia. Turno personale $turn.');
      }
      if (faunaPassive('metallic_quick') != null &&
          Random.secure().nextInt(100) <
              referenceRule('extraFastReactionChance', 90)) {
        token['extraFastReactionCurrent'] =
            readIntValue(token['extraFastReactionCurrent']) + 1;
        aggiungiLog('[LAMELLE] Una Reazione veloce extra per questo turno.');
      }
      salvaSchedaCorrenteInMemoria();
    });
    if (wave) scheduleMicrotask(() => referenceMadnessWave(tag, stamp));
  }

  Future<void> referenceMadnessWave(String sourceTag, String stamp) async {
    if (!mounted || outsideFight) return;
    final packets = <Map<String, dynamic>>[];
    faunaForOwnedSheet(sourceTag, () {
      final natural = Random.secure().nextInt(20) + 1;
      final total = rollTotalWithCritical(natural, 20, [volontaTotale()]);
      final side = combatScoutSide(sourceTag);
      for (final token in onlineCombatTokens()) {
        final target = onlineCombatTokenTag(token);
        if (target == sourceTag ||
            combatScoutSide(target) == side ||
            !masterInitiativeTokenCanAct(token)) {
          continue;
        }
        packets.add(
          permissionEnvelope({
            'id': 'doppione-wave:$sourceTag:$stamp:$target',
            'attackGroupId': 'doppione-wave:$sourceTag:$stamp',
            'scope': permissionScope,
            'campaignId': permissionCampaignId,
            'encounterId': onlineCombatEncounterId,
            'sourceTag': sourceTag,
            'senderTag': sourceTag,
            'targetTag': target,
            'sourceName': nomeSchedaPersonaggio(schedaCorrente),
            'targetName': token['name'],
            'abilityName': 'Onda di Follia',
            'choice': 'skill',
            'referenceMadnessWave': true,
            'attack': total,
            'natural': natural,
            'damage': 0,
            'baseDamage': 0,
            'element': 'mentale',
            'level': leggiNumero(livelloController),
            'grade': leggiNumero(gradoController),
            'status': 'pending',
            'createdAt': DateTime.now().toIso8601String(),
            'effects': <Map<String, dynamic>>[],
          }),
        );
      }
    });
    for (final packet in packets) {
      onlineCombatRequests.putIfAbsent('${packet['id']}', () => packet);
      if (realtimeService?.isConnected == true) {
        packet['sent'] =
            await realtimeService?.sendCombatEvent('combat_attack', packet) ==
            true;
      } else {
        packet['sent'] = true;
      }
    }
    if (mounted) setState(() {});
    programmaSalvataggio();
  }

  bool activateReferenceCreatureEffect(
    OculumStructuredEffect effect,
    int value,
    int duration,
    String source,
  ) {
    switch (effect.target) {
      case 'redcap_poison':
        applyCondition('veleno_putrido', stage: max(1, value), source: source);
        return true;
      case 'strange_presence_push':
        faunaPush(
          effect.resource,
          sheetTagAt(schedaCorrente),
          max(1, value).toDouble(),
        );
        activeStructuredEffects.removeWhere((e) => e['effectId'] == effect.id);
        activeStructuredEffects.add({
          'effectId': effect.id,
          'type': 'modifica_sottotratto',
          'target': 'vc',
          'value': -max(1, value),
          'remaining': max(1, duration),
          'unit': 'turni',
          'source': source,
        });
        return true;
      case 'minor_malicious_shaman_aphonia':
      case 'malicious_shaman_aphonia':
        applyCondition(
          'vita_afona',
          duration: 1,
          durationType: effect.target.startsWith('minor_')
              ? OculumConditionDurationType.shortRest
              : OculumConditionDurationType.longRest,
          source: source,
          metadata: {'referenceCurseSource': effect.resource},
        );
        return true;
      case 'minor_malicious_shaman_drain':
      case 'malicious_shaman_drain':
        for (final stat in ['resilienza', 'volonta', 'materia']) {
          final key = '${effect.id}:${effect.resource}:$stat';
          activeStructuredEffects.removeWhere((e) => e['effectId'] == key);
          activeStructuredEffects.add({
            'effectId': key,
            'type': 'modifica_statistica',
            'target': stat,
            'value': -max(1, value),
            'remaining': -1,
            'unit': 'turni',
            'source': source,
            'referenceCurseSource': effect.resource,
            'referenceCurseShortRest': effect.target.startsWith('minor_'),
          });
        }
        invalidateDerivedDataCaches();
        return true;
      case 'doppione_copies':
        if (planarState['doppioneCopy'] == true) return true;
        final originalVc = vc(),
            originalDamage = dannoTotale(),
            originalCm = cm();
        for (var n = 0; n < value.clamp(1, 2); n++) {
          final index = createShadowCloneSheet(
            hp: 1,
            duration: 0,
            source: source,
            displayName: nomeSchedaPersonaggio(schedaCorrente),
            asSummon: true,
            copyResilience: true,
            summonKind: 'doppione',
            summonDescription: 'Copia indistinguibile del Doppione.',
          );
          if (index < 0) continue;
          final copy = schedePersonaggio[index];
          copy['monsterBookSourceId'] = 'il_doppione';
          copy['inMasterParty'] =
              schedePersonaggio[schedaCorrente]['inMasterParty'];
          copy['manualHpMaximumAdjustment'] =
              1 -
              readIntValue(copy['resilienza']) *
                  oculumHpMultiplierForGrade(readIntValue(copy['grado']));
          copy['planarRuntime'] = {
            'doppioneCopy': true,
            'doppioneAttackBonus': originalVc,
            'doppioneDamage': originalDamage ~/ 4,
            'doppioneCm': originalCm,
          };
        }
        return true;
      case 'time_cyclops_quick':
        final token = masterInitiativeTokens
            .where(
              (t) => publicInitiativeSourceTag(t) == sheetTagAt(schedaCorrente),
            )
            .firstOrNull;
        if (token != null) {
          token['extraFastReactionCurrent'] =
              readIntValue(token['extraFastReactionCurrent']) + max(1, value);
        }
        return true;
      case 'time_cyclops_rewind':
        final last = planarState['lastAttackHp'];
        if (last is Map &&
            last['rewound'] != true &&
            feriteMorte < 3 &&
            hpCorrenti() < readIntValue(last['before'])) {
          last['rewound'] = true;
          currentHpController.text =
              '${min(maxHp(), readIntValue(last['before']))}';
          aggiungiLog('[TEMPO] Vita riportata a ${hpCorrenti()}/${maxHp()}.');
        }
        return true;
      case 'metallic_mantle':
        planarState['mantleInitialProtection'] = value.clamp(0, 100);
        planarState['mantlePrepared'] = true;
        return true;
      case 'wrong_bandit_shield':
        planarState['wrongBanditShieldHp'] =
            referenceRule('magicShieldBaseHp', 15) +
            referenceRule('magicShieldHpPerLevel', 8) *
                max(0, leggiNumero(livelloController));
        planarState['wrongBanditShieldActive'] = true;
        if (referenceRule('maintainedMagicSlots', 1) < 2) {
          planarState['wrongBanditEmpowered'] = false;
        }
        return true;
      case 'wrong_bandit_empower':
        if (referenceRule('maintainedMagicSlots', 1) < 2) {
          planarState['wrongBanditShieldActive'] = false;
        }
        planarState['wrongBanditEmpowered'] = true;
        return true;
      case 'minor_construct_guard':
        applyStructuredEffectsOnActivation([
          OculumStructuredEffect(
            id: effect.id,
            type: 'difesa',
            valueExpression: '$value',
            duration: '${max(1, duration)}',
          ),
        ], source: source);
        return true;
      case 'minor_construct_summon':
        final book = monsterBookEntryById('costrutto_minore');
        if (book == null) return true;
        final index = createShadowCloneSheet(
          hp: 10,
          duration: 0,
          source: source,
          displayName: book.nameIt,
          asSummon: true,
          summonKind: 'costrutto_minore',
          summonSkills: oculumMonsterBookSkills(book),
        );
        if (index >= 0) {
          final summon = schedePersonaggio[index];
          for (final stat in ['resilienza', 'volonta', 'materia']) {
            summon[stat] = '1';
            summon['current${stat[0].toUpperCase()}${stat.substring(1)}'] = '1';
          }
          summon['monsterBookSourceId'] = book.id;
          summon['hiddenEyeStats'] = <dynamic>[];
          summon['oculum'] = '0';
          summon['currentOculum'] = '0';
          summon['planarRuntime'] = <String, dynamic>{};
        }
        return true;
      case 'doppione_presence':
      case 'metallic_quick':
      case 'time_cyclops_halo':
      case 'minor_construct_shield':
      case 'wrong_bandit_sword':
      case 'strange_presence_watch':
        return true;
    }
    return false;
  }

  void referenceLongRest() {
    planarState.remove('mantleWear');
    planarState.remove('mantlePrepared');
    planarState.remove('lastAttackHp');
    activeStructuredEffects.removeWhere(
      (e) => e['referenceCurseSource'] != null,
    );
  }

  void referenceShortRest() {
    activeStructuredEffects.removeWhere(
      (e) => e['referenceCurseShortRest'] == true,
    );
  }

  void clearReferenceCursesFromKilled(Iterable<Map> enemies) {
    final tags = enemies
        .where((e) => !oculumEncounterEnemyIsSummon(e))
        .map(
          (e) => normalizeOculumFriendTag(
            '${e['monsterSheetTag'] ?? e['id'] ?? ''}',
          ),
        )
        .where((t) => t.isNotEmpty)
        .toSet();
    if (tags.isEmpty) return;
    for (final tag in schedePersonaggio.asMap().keys.map(sheetTagAt).toList()) {
      faunaForOwnedSheet(tag, () {
        activeStructuredEffects.removeWhere(
          (e) => tags.contains(
            normalizeOculumFriendTag('${e['referenceCurseSource'] ?? ''}'),
          ),
        );
        for (final condition
            in activeConditions
                .where(
                  (c) => tags.contains(
                    normalizeOculumFriendTag(
                      '${c.metadata['referenceCurseSource'] ?? ''}',
                    ),
                  ),
                )
                .toList()) {
          removeCondition(condition, force: true);
        }
        invalidateDerivedDataCaches();
      });
    }
  }
}
