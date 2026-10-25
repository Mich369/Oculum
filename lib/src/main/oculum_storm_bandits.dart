part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

int oculumScostuRobbedObser(int obser, {int percent = 75}) =>
    (max(0, obser) * percent.clamp(0, 100) / 100).floor();
bool oculumThunderTeleportWins(int natural, int total, int opposing) =>
    natural > 10 && total > opposing;
bool oculumScostuPacketCritical(Map request) =>
    request['scostuPunch'] == true &&
    readIntValue(request['scostuCriticalRoll'], fallback: 100) >= 0 &&
    readIntValue(request['scostuCriticalRoll'], fallback: 100) < 25;

extension _OculumStormBandits on _OculumHomePageState {
  bool get isBanditFamily => const {
    'scostubanditi',
    'scostubanditi_empatico',
    'granscostumato',
    'granscostumato_empatico',
  }.contains(faunaCurrentMonsterId);
  bool banditTargetMarked(Map<String, dynamic> token) {
    final index = localSheetIndexForOculumTag(onlineCombatTokenTag(token));
    final data = index >= 0 ? schedaJsonAt(index) : token;
    return (data['faunaPublic'] as Map?)?['banditVendetta'] == true ||
        (token['faunaPublic'] as Map?)?['banditVendetta'] == true;
  }

  String faunaTargetName(Map<String, dynamic> token) =>
      '${isBanditFamily && banditTargetMarked(token) ? '☠ ' : ''}${token['name'] ?? '???'}';
  bool get isScostubanditi =>
      schedePersonaggio.isNotEmpty &&
      const {
        'scostubanditi',
        'scostubanditi_empatico',
      }.contains(schedePersonaggio[schedaCorrente]['monsterBookSourceId']);
  OculumStructuredEffect? faunaPassive(String target) =>
      <OculumStructuredEffect>[
        ...automaticMonsterPassiveEffects(),
        for (final item in inventario.where(
          (i) => i.equipaggiata && canEquipInventoryItem(i),
        ))
          if (item.ability?.passiva == true)
            ...item.ability!.forme
                    .where(
                      (f) =>
                          (int.tryParse(f.livello) ?? 0) <=
                          leggiNumero(livelloController),
                    )
                    .lastOrNull
                    ?.effettiStrutturati ??
                const <OculumStructuredEffect>[],
      ].where((e) => e.type == 'planar' && e.target == target).firstOrNull;
  int scostuWeaponDamage(int damage) =>
      isScostubanditi &&
          (hasCondition('disarmato') ||
              planarState['scostuRifleDropped'] == true)
      ? max(0, damage) ~/ 2
      : damage;

  bool faunaReceipt(String key) {
    final receipts = (planarState['faunaReceipts'] as List? ?? [])
        .map((e) => '$e')
        .toSet();
    if (!receipts.add(key)) return false;
    planarState['faunaReceipts'] = receipts.toList();
    return true;
  }

  void faunaForOwnedSheet(String tag, VoidCallback apply) {
    if (!controlsOnlineCombatSheet(tag)) return;
    final index = localSheetIndexForOculumTag(tag);
    if (index < 0) return;
    if (index == schedaCorrente) {
      apply();
      return;
    }
    salvaSchedaCorrenteInMemoria();
    final original = schedaCorrente;
    final global = catturaImpostazioniGlobali();
    try {
      schedaCorrente = index;
      caricaStatoDaJson(schedePersonaggio[index]);
      ripristinaImpostazioniGlobali(global);
      apply();
      salvaSchedaCorrenteInMemoria();
    } finally {
      schedaCorrente = original;
      caricaStatoDaJson(schedePersonaggio[original]);
      ripristinaImpostazioniGlobali(global);
    }
  }

  Map<String, dynamic>? faunaMapToken(String tag) {
    final initiative = onlineCombatTokens()
        .where((t) => onlineCombatTokenTag(t) == tag)
        .firstOrNull;
    return initiative == null
        ? null
        : localMapTokenForInitiativeToken(initiative);
  }

  double? faunaDistance(String a, String b) {
    final first = faunaMapToken(a), second = faunaMapToken(b);
    if (first == null || second == null) return null;
    return Offset(
      (localMapTokenAxis(first, 'x') - localMapTokenAxis(second, 'x')) *
          mapWidthMetersValue(),
      (localMapTokenAxis(first, 'y') - localMapTokenAxis(second, 'y')) *
          mapHeightMetersValue(),
    ).distance;
  }

  void faunaPush(String source, String target, double meters) {
    final first = faunaMapToken(source), second = faunaMapToken(target);
    if (first == null || second == null) return;
    final width = max(1.0, mapWidthMetersValue()),
        height = max(1.0, mapHeightMetersValue());
    final delta = Offset(
      (localMapTokenAxis(second, 'x') - localMapTokenAxis(first, 'x')) * width,
      (localMapTokenAxis(second, 'y') - localMapTokenAxis(first, 'y')) * height,
    );
    final direction = delta.distance > 0
        ? delta / delta.distance
        : const Offset(1, 0);
    second['x'] =
        (localMapTokenAxis(second, 'x') + direction.dx * meters / width).clamp(
          0.0,
          1.0,
        );
    second['y'] =
        (localMapTokenAxis(second, 'y') + direction.dy * meters / height).clamp(
          0.0,
          1.0,
        );
  }

  Future<void> sendFaunaBurst({
    required String sourceTag,
    required String centerTag,
    required String receipt,
    required String name,
    required String element,
    required int damage,
    double radius = 2,
    bool bothSides = false,
    bool targetCompanions = false,
    bool push = false,
    bool nonLethal = false,
    String skillId = '',
    int maximumTargets = 100,
    int damagePerAdditionalTargetPercent = 0,
  }) async {
    final scope = permissionScope, encounter = onlineCombatEncounterId;
    final sourceIndex = localSheetIndexForOculumTag(sourceTag);
    final sourceMonster = sourceIndex < 0
        ? null
        : monsterBookEntryById(
            '${schedePersonaggio[sourceIndex]['monsterBookSourceId'] ?? ''}',
          );
    final side = combatScoutSide(centerTag);
    final candidates = onlineCombatTokens().where((t) {
      final tag = onlineCombatTokenTag(t);
      if (tag == centerTag ||
          tag == sourceTag ||
          !masterInitiativeTokenCanAct(t)) {
        return false;
      }
      return bothSides ||
          (targetCompanions
              ? combatScoutSide(tag) == side
              : combatScoutSide(tag) != side);
    }).toList();
    final selected = <String>{};
    final unknown = <Map<String, dynamic>>[];
    for (final token in candidates) {
      final tag = onlineCombatTokenTag(token),
          distance = faunaDistance(centerTag, tag);
      if (distance == null) {
        unknown.add(token);
      } else if (distance <= radius) {
        selected.add(tag);
      }
    }
    if (unknown.isNotEmpty && mounted) {
      final chosen = <String>{};
      final accepted = await showDialog<bool>(
        context: context,
        builder: (dialog) => StatefulBuilder(
          builder: (context, update) => AlertDialog(
            title: Text('$name · area'),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Posizioni non indicate sulla mappa: seleziona chi è entro $radius metri. Nessuna Azione o Reazione aggiuntiva.',
                    ),
                    for (final token in unknown)
                      CheckboxListTile(
                        title: Text(
                          '${token['name'] ?? onlineCombatTokenTag(token)}',
                        ),
                        value: chosen.contains(onlineCombatTokenTag(token)),
                        onChanged: (v) => update(() {
                          if (v == true) {
                            chosen.add(onlineCombatTokenTag(token));
                          } else {
                            chosen.remove(onlineCombatTokenTag(token));
                          }
                        }),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialog, false),
                child: const Text('Nessuno'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialog, true),
                child: const Text('Applica ai selezionati'),
              ),
            ],
          ),
        ),
      );
      if (accepted == true) selected.addAll(chosen);
    }
    if (!mounted ||
        permissionScope != scope ||
        onlineCombatEncounterId != encounter) {
      return;
    }
    final targets = selected.take(maximumTargets.clamp(1, 100)).toList();
    final burstDamage =
        (damage *
                (1 +
                    max(0, targets.length - 1) *
                        max(0, damagePerAdditionalTargetPercent) /
                        100))
            .floor();
    for (final target in targets) {
      final request = <String, dynamic>{
        'id': '$receipt:$target',
        'scope': scope,
        'campaignId': permissionCampaignId,
        'encounterId': encounter,
        'sourceTag': sourceTag,
        'targetTag': target,
        'sourceName': name,
        'targetName':
            onlineCombatTokens()
                .where((t) => onlineCombatTokenTag(t) == target)
                .firstOrNull?['name'] ??
            target,
        'kind': 'fauna_burst',
        'abilityName': name,
        'choice': 'fauna_burst',
        'faunaBurst': true,
        'faunaPush': push,
        'faunaNonLethal': nonLethal,
        'faunaRobberyPercent': readIntValue(
          sourceMonster?.encounterRules['robberyPercent'],
          fallback: 75,
        ),
        'faunaSkillId': skillId,
        'attack': 1,
        'damage': max(0, burstDamage),
        'element': element,
        'natural': 10,
        'level': 0,
        'grade': 0,
        'difficulty': 'normale',
        'effects': <Map<String, dynamic>>[],
        'status': 'pending',
      };
      if (controlsOnlineCombatSheet(target)) {
        await resolveAutomaticFaunaDamage(request);
      }
      await realtimeService?.sendCombatEvent('combat_attack', {
        ...permissionEnvelope(request),
        'senderTag': sourceTag,
      });
    }
  }

  Future<void> resolveAutomaticFaunaDamage(Map<String, dynamic> request) async {
    final tag = '${request['targetTag']}';
    if (!controlsOnlineCombatSheet(tag)) return;
    final index = localSheetIndexForOculumTag(tag);
    if (index < 0) return;
    final previous = schedaCorrente;
    salvaSchedaCorrenteInMemoria();
    final global = catturaImpostazioniGlobali();
    try {
      if (index != previous) {
        schedaCorrente = index;
        caricaStatoDaJson(schedePersonaggio[index]);
        ripristinaImpostazioniGlobali(global);
      }
      if (!faunaReceipt('burst:${request['id']}')) return;
      onlineCombatRequests['${request['id']}'] = request;
      await applyResolvedOnlineDefense(request, 'cm', 0);
      if (request['faunaPush'] == true) {
        faunaPush('${request['sourceTag']}', tag, 2);
      }
      salvaSchedaCorrenteInMemoria();
    } finally {
      if (index != previous && mounted) {
        schedaCorrente = previous;
        caricaStatoDaJson(schedePersonaggio[previous]);
        ripristinaImpostazioniGlobali(global);
      }
    }
  }

  void scostuShieldResponse(
    Map<String, dynamic> request,
    Map<String, dynamic> receipt,
  ) {
    final effect = faunaPassive('scostu_breath');
    if (request['faunaBurst'] != true &&
        effect != null &&
        readIntValue(receipt['shieldLost']) > 0 &&
        scudo() > 0 &&
        faunaReceipt('breath:${request['id']}')) {
      unawaited(
        sendFaunaBurst(
          sourceTag: sheetTagAt(schedaCorrente),
          centerTag: sheetTagAt(schedaCorrente),
          receipt: 'scostu:${request['id']}',
          name: 'Dammi il tempo di respirare, cazzo!',
          element: 'contundente',
          damage: max(0, readIntValue(effect.valueExpression)),
          push: true,
          nonLethal:
              isScostubanditi ||
              monsterBookEntryById(
                    faunaCurrentMonsterId,
                  )?.encounterRules['nonLethal'] ==
                  true,
          skillId: 'scostu_breath',
        ),
      );
    }
    final recovery = faunaPassive('scostu_recover');
    if (recovery != null &&
        readIntValue(receipt['shieldLost']) > 0 &&
        scudo() == 0 &&
        planarState['scostuShieldRecovered'] != true) {
      planarState['scostuShieldRecovered'] = true;
      final amount =
          max(0, readIntValue(recovery.valueExpression, fallback: 50)) +
          3 * leggiNumero(livelloController);
      scudoController.text = '$amount';
      aggiungiLog(
        '[SCUDO] Recuperati $amount punti, una volta per fight; il danno già ricevuto resta.',
      );
    }
  }

  void scostuNonLethalDefeat({int robberyPercent = 75}) {
    if (faunaReceipt('scostu-robbery:$onlineCombatEncounterId')) {
      final money = max(0, leggiNumero(obserController));
      final lost = oculumScostuRobbedObser(money, percent: robberyPercent);
      obserController.text = '${money - lost}';
      aggiungiLog(
        '[SCOSTUBANDITI] Sconfitta non letale: ti risvegli con 1 Vita. Rubati $lost Obser; rimangono ${money - lost}.',
      );
    }
    for (final token in _writableOnlineCombatTokens().where(
      (t) => onlineCombatTokenTag(t) == sheetTagAt(schedaCorrente),
    )) {
      token['downed'] = true;
      token['scostuNonLethalDowned'] = true;
    }
  }

  void claimStormBanditAttack(Map<String, dynamic> request) {
    faunaForOwnedSheet('${request['sourceTag']}', () {
      final group = '${request['attackGroupId'] ?? request['id']}';
      final critical =
          readIntValue(request['natural']) >= 20 ||
          request['forcedCritical'] == true ||
          oculumScostuPacketCritical(request) ||
          oculumAttackIsCritical(
            readIntValue(request['attack']),
            readIntValue(request['defense']),
          );
      final hit =
          request['outcome'] != 'avoided' &&
          readIntValue(request['attack']) > readIntValue(request['defense']);
      if (hit) deadlyGreatswordHit(request);
      if (request['scostuRifle'] == true &&
          (readIntValue(request['scostuRifleForm']) == 1 || hit) &&
          faunaReceipt('rifle:$group')) {
        final form = readIntValue(request['scostuRifleForm']);
        planarState['scostuRifleAmmo'] = max(
          0,
          readIntValue(planarState['scostuRifleAmmo']) -
              1 +
              (form == 3 && critical && hit ? 3 : 0),
        );
        aggiungiLog(
          '[FUCILE] ${planarState['scostuRifleAmmo']} colpi rimasti.',
        );
      }
      if (request['scostuRifle'] == true &&
          critical &&
          hit &&
          faunaReceipt('rifle-dodge:$group')) {
        schivateOculumBonus++;
        aggiungiLog('[FUCILE SCHIVATA] Critico a segno: +1 Schivata Oculum.');
      }
      if (hit &&
          request['granLeave'] == true &&
          faunaReceipt('gran-push:$group')) {
        faunaPush('${request['sourceTag']}', '${request['targetTag']}', 2);
      }
      if (hit && request['thunderTeleportFragility'] == true) {
        planarState.remove('thunderTeleportTarget');
      }
      if (critical && hit && faunaReceipt('claw:$group')) {
        final claw = (request['effects'] as List? ?? [])
            .whereType<Map>()
            .where((e) => e['target'] == 'thunderbird_claw')
            .firstOrNull;
        if (claw != null) {
          unawaited(
            sendFaunaBurst(
              sourceTag: '${request['sourceTag']}',
              centerTag: '${request['targetTag']}',
              receipt: 'claw:$group',
              name: 'Scosse dell’Artiglio di Fulmine',
              element: 'fulmine',
              damage: max(0, readIntValue(claw['valueExpression'])),
              targetCompanions: true,
            ),
          );
        }
      }
    });
  }

  Future<void> useThunderTeleport() async {
    final source = currentSheetScrollId(), scope = permissionScope;
    final targets = onlineAttackTokens()
        .where((t) => onlineCombatTokenTag(t) != source)
        .toList();
    final target = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialog) => SimpleDialog(
        title: const Text('TP elettrico · bersaglio'),
        children: [
          for (final token in targets)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialog, token),
              child: Text('${token['name']}'),
            ),
        ],
      ),
    );
    if (!mounted ||
        target == null ||
        source != currentSheetScrollId() ||
        scope != permissionScope) {
      return;
    }
    final tag = onlineCombatTokenTag(target);
    final reflex = hiddenEyeStats.where((s) => s.id == 'riflessi').firstOrNull;
    if (reflex == null) return;
    await tiraSottotrattoOcchio(
      reflex,
      resourceAlreadySpent: true,
      actionLabel: 'TP elettrico',
      onResolved: (natural, total) {
        if (source != currentSheetScrollId() || scope != permissionScope) {
          return;
        }
        final index = localSheetIndexForOculumTag(tag);
        final opposing =
            rollTotalWithCritical(Random.secure().nextInt(20) + 1, 20, [
              index >= 0
                  ? sheetRollBonusAt(index, 'riflessi')
                  : readIntValue(target['reflexes']),
            ]);
        aggiungiLog(
          '[TP ELETTRICO] Riflessi $total contro $opposing: ${total > opposing ? 'riuscito' : 'fallito'}.',
        );
        if (total <= opposing) return;
        planarState['thunderTeleportTarget'] = tag;
        activeStructuredEffects.addAll([
          {
            'effectId': 'thunder_tp_roll',
            'source': 'TP elettrico',
            'type': 'modifica_statistica',
            'target': 'tiro_globale',
            'value': 5,
            'mode': 'prossimo_tiro',
            'remaining': 1,
            'unit': 'tiri',
          },
          {
            'effectId': 'thunder_tp_initiative',
            'source': 'TP elettrico',
            'type': 'modifica_sottotratto',
            'target': 'iniziativa',
            'value': 2,
            'mode': 'temporaneo',
            'remaining': 1,
            'unit': 'turni',
          },
        ]);
        final mine = faunaMapToken(source), theirs = faunaMapToken(tag);
        if (mine != null && theirs != null) {
          mine['x'] =
              (localMapTokenAxis(theirs, 'x') +
                      1 / max(1.0, mapWidthMetersValue()))
                  .clamp(0.0, 1.0);
          mine['y'] = localMapTokenAxis(theirs, 'y');
        }
        if (oculumThunderTeleportWins(natural, total, opposing)) {
          grantDollSpringReaction(100, percentile: 0);
        }
        invalidateDerivedDataCaches();
        programmaSalvataggio();
      },
    );
  }

  void resetStormBanditFight() {
    for (final key in [
      'faunaReceipts',
      'scostuShieldRecovered',
      'scostuRifleAmmo',
      'scostuRifleForm',
      'scostuPunch',
      'thunderTeleportTarget',
    ]) {
      planarState.remove(key);
    }
    activeStructuredEffects.removeWhere(
      (e) => '${e['effectId']}'.startsWith('thunder_tp_'),
    );
    for (final token in _writableOnlineCombatTokens()) {
      if (token.remove('scostuNonLethalDowned') == true) {
        token['downed'] = false;
      }
    }
  }
}
