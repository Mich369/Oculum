part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

const _posteaArmorTriggeredKey = 'posteaArmorTriggered';
const _posteaArmorPendingKey = 'posteaArmorPendingShock';

bool oculumIsPosteaReactiveArmor(InventoryItem item) =>
    item.craftData['posteaReactiveArmor'] == true;

int oculumPosteaArmorBonusPercent({required int uses, required int capacity}) =>
    100 + (180 * (capacity - uses) ~/ capacity).clamp(0, 90).toInt();

void oculumRearmPosteaArmor(InventoryItem item) {
  if (!oculumIsPosteaReactiveArmor(item)) return;
  item.craftData = {...item.craftData}..remove(_posteaArmorTriggeredKey);
}

extension _OculumPosteaReactiveArmor on _OculumHomePageState {
  void recordPosteaArmorHalfIntegrity(
    InventoryItem item, {
    required int before,
    required int after,
    required String? damagePacketId,
  }) {
    if (!oculumIsPosteaReactiveArmor(item) ||
        item.craftData[_posteaArmorTriggeredKey] == true) {
      return;
    }
    final half = oculumEquipmentCapacity(item) ~/ 2;
    if (before <= half || after > half) return;
    item.craftData = {
      ...item.craftData,
      _posteaArmorTriggeredKey: true,
      _posteaArmorPendingKey: {
        'damagePacketId': damagePacketId,
        'id':
            'postea-armor:${DateTime.now().microsecondsSinceEpoch}:${Random.secure().nextInt(1 << 30)}',
        'scope': permissionScope,
        'encounter': onlineCombatEncounterId,
      },
    };
  }

  void completePosteaArmorShocks({String? damagePacketId}) {
    final source = sheetTagAt(schedaCorrente);
    for (final item in inventario) {
      final pending = item.craftData[_posteaArmorPendingKey];
      if (pending is! Map || pending['damagePacketId'] != damagePacketId) {
        continue;
      }
      item.craftData = {...item.craftData}..remove(_posteaArmorPendingKey);
      final percent = readIntValue(
        item.craftData['posteaArmorRecoveryPercent'],
        fallback: 25,
      ).clamp(0, 100).toInt();
      final contribution = itemIntegrityShieldCurrent(item);
      final restored = min(
        _itemBaseShieldBonus(item) * percent ~/ 100,
        max(0, itemTrackedNormalShieldMaximum(item) - contribution),
      );
      if (restored > 0 && item.equipaggiata && canEquipInventoryItem(item)) {
        item.scudoIntegritaCorrente = contribution + restored;
        item.craftData['wearNormalShieldTracked'] = true;
        scudoController.text =
            '${max(0, leggiNumero(scudoController)) + restored}';
        clearNormalShieldBreakPenaltyIfProtected();
        aggiungiLog('[POSTEA] ${item.nome}: +$restored Scudo.');
        sendRealtimeHpChanged();
      }
      programmaSalvataggio();
      final damage = readIntValue(
        item.craftData['posteaArmorShockDamage'],
        fallback: 50,
      ).clamp(0, 100000000).toInt();
      final radius = readIntValue(
        item.craftData['posteaArmorShockRadius'],
        fallback: 2,
      ).clamp(1, 100).toInt();
      final encounter = '${pending['encounter'] ?? ''}';
      if (source.isEmpty || encounter.isEmpty || damage == 0) continue;
      final scope = '${pending['scope'] ?? ''}';
      final receipt = '${pending['id']}';
      final name = item.nome;
      _oculumShieldBreakImpactQueue = _oculumShieldBreakImpactQueue
          .then((_) async {
            await WidgetsBinding.instance.endOfFrame;
            if (!mounted ||
                scope != permissionScope ||
                encounter != onlineCombatEncounterId ||
                !controlsOnlineCombatSheet(source)) {
              return;
            }
            await _sendPosteaArmorShock(
              source: source,
              scope: scope,
              encounter: encounter,
              receipt: receipt,
              name: name,
              damage: damage,
              radius: radius,
            );
          })
          .catchError((Object _) {
            if (mounted && scope == permissionScope) {
              combatLogFor(source, '[POSTEA] Invio della scarica interrotto.');
            }
          });
    }
  }

  bool _posteaArmorShockCanTarget(
    Map<String, dynamic> source,
    Map<String, dynamic> target,
    int radius,
  ) {
    if (!oculumShieldBreakCanTarget(source, target)) return false;
    final distance = faunaDistance(
      onlineCombatTokenTag(source),
      onlineCombatTokenTag(target),
    );
    return distance == null || distance <= radius;
  }

  bool validPosteaArmorShock(Map<String, dynamic> payload) {
    final id = '${payload['id'] ?? ''}';
    final source = '${payload['sourceTag'] ?? ''}';
    final target = '${payload['targetTag'] ?? ''}';
    final radius = readIntValue(payload['posteaArmorShockRadius']);
    final damage = readIntValue(payload['damage']);
    if (!id.startsWith('postea-armor:') ||
        id.length > 160 ||
        !id.endsWith(':$target') ||
        source.isEmpty ||
        payload['senderTag'] != source ||
        payload['scope'] != permissionScope ||
        payload['encounterId'] != onlineCombatEncounterId ||
        payload['posteaArmorShock'] != true ||
        payload['oculumShieldBreakImpact'] == true ||
        payload['kind'] != 'fauna_burst' ||
        payload['faunaBurst'] != true ||
        payload['element'] != 'energia' ||
        payload['attack'] != 1 ||
        payload['natural'] != 10 ||
        payload['forcedCritical'] == true ||
        payload['turnResourceSpends'] is List ||
        payload['effects'] is! List ||
        (payload['effects'] as List).isNotEmpty ||
        radius < 1 ||
        radius > 100 ||
        damage < 1 ||
        damage > 100000000) {
      return false;
    }
    final tokens = onlineCombatTokens();
    final bearer = tokens
        .where((token) => onlineCombatTokenTag(token) == source)
        .firstOrNull;
    final recipient = tokens
        .where((token) => onlineCombatTokenTag(token) == target)
        .firstOrNull;
    return bearer != null &&
        bearer['outsideFight'] != true &&
        recipient != null &&
        _posteaArmorShockCanTarget(bearer, recipient, radius);
  }

  Future<void> _sendPosteaArmorShock({
    required String source,
    required String scope,
    required String encounter,
    required String receipt,
    required String name,
    required int damage,
    required int radius,
  }) async {
    final tokens = onlineCombatTokens();
    final bearer = tokens
        .where((token) => onlineCombatTokenTag(token) == source)
        .firstOrNull;
    if (bearer == null || bearer['outsideFight'] == true) return;
    final candidates = tokens
        .where((token) => _posteaArmorShockCanTarget(bearer, token, radius))
        .toList();
    if (candidates.isEmpty) return;
    final selected = <String>{};
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text('$name · ${t('Scarica', 'Discharge')}'),
          content: SizedBox(
            width: 420,
            child: ListView(
              shrinkWrap: true,
              children: [
                Text(
                  t(
                    'Seleziona i nemici vicini. $damage Danni Energia ciascuno.',
                    'Select nearby enemies. $damage Energy Damage each.',
                  ),
                ),
                for (final token in candidates)
                  CheckboxListTile(
                    title: Text(
                      '${token['name'] ?? onlineCombatTokenTag(token)}',
                    ),
                    value: selected.contains(onlineCombatTokenTag(token)),
                    onChanged: (enabled) => update(() {
                      final tag = onlineCombatTokenTag(token);
                      if (enabled == true) {
                        selected.add(tag);
                      } else {
                        selected.remove(tag);
                      }
                    }),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog, false),
              child: Text(t('Nessuno', 'None')),
            ),
            FilledButton(
              onPressed: selected.isEmpty
                  ? null
                  : () => Navigator.pop(dialog, true),
              child: Text(t('Applica', 'Apply')),
            ),
          ],
        ),
      ),
    );
    if (accepted != true) return;
    for (final target in selected) {
      if (!mounted ||
          scope != permissionScope ||
          encounter != onlineCombatEncounterId ||
          !controlsOnlineCombatSheet(source)) {
        return;
      }
      final request = <String, dynamic>{
        'id': '$receipt:$target',
        'scope': scope,
        'campaignId': permissionCampaignId,
        'encounterId': encounter,
        'sourceTag': source,
        'senderTag': source,
        'targetTag': target,
        'sourceName': name,
        'targetName':
            candidates
                .where((token) => onlineCombatTokenTag(token) == target)
                .firstOrNull?['name'] ??
            target,
        'abilityName': t(
          'Scarica della corazza di Postea',
          'Postea armor discharge',
        ),
        'kind': 'fauna_burst',
        'choice': 'fauna_burst',
        'faunaBurst': true,
        'posteaArmorShock': true,
        'posteaArmorShockRadius': radius,
        'attack': 1,
        'natural': 10,
        'damage': damage,
        'element': 'energia',
        'effects': <Map<String, dynamic>>[],
        'status': 'pending',
      };
      if (!validPosteaArmorShock(request) ||
          onlineCombatRequests.containsKey('${request['id']}')) {
        continue;
      }
      onlineCombatRequests['${request['id']}'] = request;
      programmaSalvataggio();
      if (realtimeService?.isConnected == true) {
        await sendOnlineCombatRequest(request);
      }
      if (mounted &&
          scope == permissionScope &&
          encounter == onlineCombatEncounterId &&
          controlsOnlineCombatSheet(target) &&
          request['status'] == 'pending') {
        await resolveAutomaticFaunaDamage(request);
      }
    }
  }
}
