part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

extension _OculumCloudBarrier on _OculumHomePageState {
  void queueCloudBarrierResponse(
    Map<String, dynamic> incoming,
    Map receipt, {
    int? natural,
  }) {
    if (incoming['cloudBarrierResponse'] == true ||
        readIntValue(planarState['barrierTurns']) <= 0 ||
        readIntValue(receipt['shieldLost']) <= 0 ||
        !faunaReceipt('cloud-barrier:${incoming['id']}')) {
      return;
    }
    final source = sheetTagAt(schedaCorrente),
        target = '${incoming['sourceTag']}';
    final token = onlineCombatTokens()
        .where((t) => onlineCombatTokenTag(t) == target)
        .firstOrNull;
    if (token == null || escapeTokenIsOut(target)) return;
    final die = natural ?? Random.secure().nextInt(20) + 1;
    final stat = hiddenEyeStats
        .where((s) => s.id == 'manifestazione_potere')
        .firstOrNull;
    final attack = die + (stat == null ? 0 : hiddenEyeTotal(stat)) + 5;
    final packet = <String, dynamic>{
      'id': 'cloud-barrier:${incoming['id']}',
      'scope': permissionScope,
      'encounterId': onlineCombatEncounterId,
      'kind': 'attack',
      'cloudBarrierResponse': true,
      'sourceTag': source,
      'sourceName': realtimeDisplayName(),
      'sourceSide': combatScoutSide(source),
      'sourceMonsterBookId': faunaCurrentMonsterId,
      'targetTag': target,
      'targetName': token['name'],
      'natural': die,
      'attack': attack,
      'choice': 'manifestazione_potere',
      'damage': max(0, readIntValue(planarState['barrierPower'])),
      'element': 'fulmine',
      'difficulty': 'normale',
      'abilityName': 'Scarica · Scudo di Roccia Nuvola',
      'status': 'pending',
      'received': false,
      'effects': [
        OculumStructuredEffect(
          type: 'stato',
          appliedState: 'stordito',
          valueExpression: '1',
          duration: '1',
          durationUnit: 'azioni',
          recipient: 'bersaglio',
          criticalOnly: true,
        ).toJson(),
      ],
    };
    aggiungiLog(
      '[BARRIERA] Risposta gratuita: 1d20 ($die) + Manifestazione +5 = $attack.',
    );
    onlineCombatRequests['${packet['id']}'] = packet;
    receiveLocalCombatAttack(packet);
    unawaited(sendOnlineCombatRequest(packet));
  }

  void claimCloudBarrierCritical(Map<String, dynamic> request) {
    if (request['cloudBarrierResponse'] != true ||
        request['cloudBarrierSplash'] == true ||
        request['status'] != 'resolved' ||
        request['criticalShieldProtected'] == true ||
        request['outcome'] == OculumAttackOutcome.avoided.name ||
        !oculumAttackIsCritical(
              readIntValue(request['attack']),
              readIntValue(request['defense']),
            ) &&
            readIntValue(request['natural']) != 20) {
      return;
    }
    final source = '${request['sourceTag']}';
    if (!controlsOnlineCombatSheet(source)) return;
    faunaForOwnedSheet(source, () {
      if (!faunaReceipt('cloud-barrier-splash:${request['id']}')) return;
      final side = combatScoutSide('${request['targetTag']}');
      for (final target in onlineCombatTokens().where(
        (t) =>
            onlineCombatTokenTag(t) != request['targetTag'] &&
            combatScoutSide(onlineCombatTokenTag(t)) == side &&
            !const {'dead', 'fled', 'expired'}.contains(t['status']),
      )) {
        final tag = onlineCombatTokenTag(target);
        final packet = <String, dynamic>{
          ...request,
          'id': 'cloud-splash:${request['id']}:$tag',
          'cloudBarrierSplash': true,
          'status': 'pending',
          'received': false,
          'targetTag': tag,
          'targetName': target['name'],
          'effects': [
            OculumStructuredEffect(
              type: 'stato',
              appliedState: 'stordito',
              valueExpression: '1',
              duration: '1',
              durationUnit: 'azioni',
              recipient: 'bersaglio',
            ).toJson(),
          ],
        };
        for (final key in [
          'damageReceipt',
          'defense',
          'outcome',
          'criticalShieldProtected',
          'sent',
          'resolved',
        ]) {
          packet.remove(key);
        }
        onlineCombatRequests['${packet['id']}'] = packet;
        receiveLocalCombatAttack(packet);
        unawaited(sendOnlineCombatRequest(packet));
      }
      aggiungiLog(
        '[BARRIERA] Critico: scarica estesa agli alleati dell’attaccante nello stesso scontro.',
      );
    });
  }
}
