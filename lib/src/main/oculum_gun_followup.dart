part of '../../main.dart';

String _gunFollowupKey(bool shield) => shield ? 'gunShield' : 'gunblade';

String _gunFollowupPacketId(
  String kind,
  String origin,
  String scope,
  String encounter,
) {
  final hash = SHA256Digest().process(
    Uint8List.fromList(
      utf8.encode(jsonEncode([kind, origin, scope, encounter])),
    ),
  );
  return 'gun-followup:${hash.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join()}';
}

extension _OculumGunFollowup on _OculumHomePageState {
  Map<String, dynamic>? _gunFollowupToken(String tag) => onlineCombatTokens()
      .where((token) => combatTokenMatchesSheet(token, tag))
      .firstOrNull;

  String _gunFollowupFight(Map<String, dynamic> owner) =>
      '$permissionScope:$onlineCombatEncounterId:${owner['fightInstanceId'] ?? ''}';

  InventoryItem? _gunFollowupEquipment(bool shield) => inventario
      .where(
        (item) =>
            item.craftData[_gunFollowupKey(shield)] == true &&
            item.quantita > 0 &&
            item.equipaggiata &&
            canEquipInventoryItem(item),
      )
      .firstOrNull;

  bool _gunFollowupCanTarget(
    Map<String, dynamic> owner,
    Map<String, dynamic> target,
  ) =>
      owner['outsideFight'] != true &&
      masterInitiativeTokenCanAct(owner) &&
      masterInitiativeTokenCanAct(target) &&
      oculumShieldBreakCanTarget(owner, target);

  bool _gunFollowupHasDamage(Map<String, dynamic> request) {
    final receipt = request['damageReceipt'];
    return receipt is Map &&
        const [
          'hpLost',
          'temporaryHpLost',
          'shieldLost',
          'oculumShieldLost',
        ].any((key) => readIntValue(receipt[key]) > 0);
  }

  void offerGunShieldFollowup(Map<String, dynamic> request) {
    final natural = readIntValue(request['defenseNatural']);
    if (request['outcome'] != OculumAttackOutcome.avoided.name ||
        request['defenseChoice'] != 'cm' ||
        natural <= 1 ||
        natural > 20 ||
        readIntValue(request['defense']) < readIntValue(request['attack'])) {
      return;
    }
    _offerGunFollowup(request, shield: true);
  }

  void offerGunbladeFollowup(Map<String, dynamic> request) {
    if (request['gunbladeAttack'] != true ||
        request['outcome'] != OculumAttackOutcome.full.name ||
        !_gunFollowupHasDamage(request)) {
      return;
    }
    _offerGunFollowup(request, shield: false);
  }

  void _offerGunFollowup(Map<String, dynamic> request, {required bool shield}) {
    if (request['gunFollowup'] == true ||
        request['faunaBurst'] == true ||
        request['scope'] != permissionScope ||
        request['encounterId'] != onlineCombatEncounterId ||
        !currentCombatIsActive()) {
      return;
    }
    final kind = _gunFollowupKey(shield);
    final origin = '${request['id'] ?? ''}';
    final source = '${request[shield ? 'targetTag' : 'sourceTag'] ?? ''}';
    final target = '${request[shield ? 'sourceTag' : 'targetTag'] ?? ''}';
    if (origin.isEmpty ||
        !oculumSameSheetIdentity(source, sheetTagAt(schedaCorrente)) ||
        !controlsOnlineCombatSheet(source)) {
      return;
    }
    final ownerToken = _gunFollowupToken(source);
    final targetToken = _gunFollowupToken(target);
    final item = _gunFollowupEquipment(shield);
    if (ownerToken == null ||
        targetToken == null ||
        item == null ||
        !_gunFollowupCanTarget(ownerToken, targetToken)) {
      return;
    }
    final fight = _gunFollowupFight(ownerToken);
    if (!faunaReceipt('gun-followup:$fight:$kind:$origin')) return;
    final key = '${kind}Followup';
    final previous = planarState[key];
    final readyAt = previous is Map && previous['fight'] == fight
        ? readIntValue(previous['readyAtTurn'])
        : 0;
    if (playerReportedTurn >= readyAt) {
      planarState[key] = {
        'fight': fight,
        'readyAtTurn': readyAt,
        'origin': origin,
        'target': target,
        'targetToken': '${targetToken['id'] ?? ''}',
        'targetInstance': '${targetToken['fightInstanceId'] ?? ''}',
      };
      notifyActiveSheetSummaryChanged();
    }
    programmaSalvataggio();
  }

  ({String origin, String tag, String name, int damage, int cooldown})?
  availableGunFollowup(bool shield) {
    final source = sheetTagAt(schedaCorrente);
    final owner = _gunFollowupToken(source);
    final state = planarState['${_gunFollowupKey(shield)}Followup'];
    if (owner == null ||
        state is! Map ||
        state['fight'] != _gunFollowupFight(owner) ||
        playerReportedTurn < readIntValue(state['readyAtTurn']) ||
        !currentCombatIsActive() ||
        !controlsOnlineCombatSheet(source)) {
      return null;
    }
    final origin = '${state['origin'] ?? ''}';
    final tag = '${state['target'] ?? ''}';
    if (origin.isEmpty || tag.isEmpty) return null;
    final target = _gunFollowupToken(tag);
    final item = _gunFollowupEquipment(shield);
    if (target == null ||
        item == null ||
        !_gunFollowupCanTarget(owner, target) ||
        '${target['id'] ?? ''}' != state['targetToken'] ||
        '${target['fightInstanceId'] ?? ''}' != state['targetInstance']) {
      return null;
    }
    final damage = readIntValue(
      item.craftData['gunFollowupDamage'],
      fallback: shield ? 15 : 20,
    ).clamp(0, 100000000).toInt();
    if (damage == 0) return null;
    return (
      origin: origin,
      tag: tag,
      name: '${target['name'] ?? tag}',
      damage: damage,
      cooldown: max(
        0,
        readIntValue(item.craftData['gunFollowupCooldown'], fallback: 2),
      ),
    );
  }

  bool validGunFollowup(Map<String, dynamic> payload) {
    final kind = '${payload['gunFollowupKind'] ?? ''}';
    final origin = '${payload['gunFollowupOrigin'] ?? ''}';
    final source = '${payload['sourceTag'] ?? ''}';
    final target = '${payload['targetTag'] ?? ''}';
    final scope = permissionScope;
    final encounter = onlineCombatEncounterId;
    final damage = readIntValue(payload['damage']);
    if (payload['gunFollowup'] != true ||
        !const {'gunShield', 'gunblade'}.contains(kind) ||
        origin.isEmpty ||
        origin.length > 160 ||
        payload['id'] != _gunFollowupPacketId(kind, origin, scope, encounter) ||
        payload['senderTag'] != source ||
        payload['scope'] != scope ||
        payload['encounterId'] != encounter ||
        payload['kind'] != 'fauna_burst' ||
        payload['faunaBurst'] != true ||
        payload['posteaArmorShock'] == true ||
        payload['oculumShieldBreakImpact'] == true ||
        payload['element'] != 'perforante' ||
        payload['attack'] != 1 ||
        payload['natural'] != 10 ||
        payload['forcedCritical'] == true ||
        payload['turnResourceSpends'] is List ||
        payload['effects'] is! List ||
        (payload['effects'] as List).isNotEmpty ||
        damage < 1 ||
        damage > 100000000) {
      return false;
    }
    final shield = kind == 'gunShield';
    final original = onlineCombatRequests[origin];
    if (original == null ||
        original['gunFollowup'] == true ||
        original['scope'] != payload['scope'] ||
        original['encounterId'] != payload['encounterId'] ||
        !oculumSameSheetIdentity(
          original[shield ? 'targetTag' : 'sourceTag'],
          source,
        ) ||
        !oculumSameSheetIdentity(
          original[shield ? 'sourceTag' : 'targetTag'],
          target,
        ) ||
        !shield && original['gunbladeAttack'] != true) {
      return false;
    }
    if (original['status'] == 'resolved' && original.containsKey('outcome')) {
      if (shield &&
          (original['outcome'] != OculumAttackOutcome.avoided.name ||
              original['defenseChoice'] != 'cm' ||
              readIntValue(original['defense']) <
                  readIntValue(original['attack']))) {
        return false;
      }
      if (!shield &&
          (original['outcome'] != OculumAttackOutcome.full.name ||
              original.containsKey('damageReceipt') &&
                  !_gunFollowupHasDamage(original))) {
        return false;
      }
    }
    final owner = _gunFollowupToken(source);
    final recipient = _gunFollowupToken(target);
    return owner != null &&
        recipient != null &&
        _gunFollowupCanTarget(owner, recipient);
  }

  Future<void> fireGunFollowup(bool shield) async {
    final shot = availableGunFollowup(shield);
    if (shot == null) return;
    final kind = _gunFollowupKey(shield);
    final scope = permissionScope;
    final encounter = onlineCombatEncounterId;
    final source = sheetTagAt(schedaCorrente);
    final id = _gunFollowupPacketId(kind, shot.origin, scope, encounter);
    final label = shield ? 'Gun Shield' : 'Gunblade';
    final request = <String, dynamic>{
      'id': id,
      'scope': scope,
      'campaignId': permissionCampaignId,
      'encounterId': encounter,
      'sourceTag': source,
      'senderTag': source,
      'targetTag': shot.tag,
      'sourceName': nomeController.text,
      'targetName': shot.name,
      'abilityName': label,
      'kind': 'fauna_burst',
      'choice': 'fauna_burst',
      'faunaBurst': true,
      'gunFollowup': true,
      'gunFollowupKind': kind,
      'gunFollowupOrigin': shot.origin,
      'attack': 1,
      'natural': 10,
      'damage': shot.damage,
      'element': 'perforante',
      'effects': <Map<String, dynamic>>[],
      'status': 'pending',
    };
    if (!validGunFollowup(request) || onlineCombatRequests.containsKey(id)) {
      return;
    }
    final state = planarState['${kind}Followup'] as Map;
    state['readyAtTurn'] = playerReportedTurn + shot.cooldown;
    state.remove('origin');
    state.remove('target');
    state.remove('targetToken');
    state.remove('targetInstance');
    onlineCombatRequests[id] = request;
    aggiungiLog('[$label] Colpo gratuito contro ${shot.name}.');
    notifyActiveSheetSummaryChanged();
    programmaSalvataggio();
    await sendOnlineCombatRequest(request);
    if (mounted &&
        scope == permissionScope &&
        encounter == onlineCombatEncounterId &&
        controlsOnlineCombatSheet(shot.tag) &&
        request['status'] == 'pending') {
      await resolveAutomaticFaunaDamage(request);
    }
  }
}
