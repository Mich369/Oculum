part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

const _swordBreakerInstanceKey = 'swordBreakerBladeInstance';
const _swordBreakerDropKey = 'swordBreakerDrop';
const _swordBreakerElements = {'fisico', 'taglio', 'perforante'};
typedef _SwordBreakerDrop = ({String id, String ownerTag, String name});
final _swordBreakerBladeNames = RegExp(
  r'\b(?:blade|dagger|sword|spada|spade|lama|lame|katana|pugnale|pugnali|'
  r'coltello|coltelli|knife|rapier|stocco|sciabola|scimitarra|sabre|saber|'
  r'ascia|asce|axe|alabarda|halberd|machete)\b',
);

bool oculumSwordBreakerDropped(InventoryItem item) =>
    item.craftData['titleItem'] != true &&
    item.craftData[_swordBreakerDropKey] is Map;

InventoryItem? oculumTakeSwordBreakerDrop(
  List<InventoryItem> inventory,
  String dropId, {
  required bool returningToOwner,
}) {
  final blade = inventory.where((item) {
    final marker = item.craftData[_swordBreakerDropKey];
    return item.arma &&
        oculumSwordBreakerDropped(item) &&
        marker is Map &&
        marker['id'] == dropId;
  }).singleOrNull;
  if (blade == null || blade.quantita != 1) return null;
  blade.craftData = {...blade.craftData}..remove(_swordBreakerDropKey);
  blade.equipaggiata = false;
  if (!returningToOwner) inventory.remove(blade);
  return blade;
}

bool oculumSwordBreakerPhysicalBlade(InventoryItem item) {
  if (!item.arma || item.quantita <= 0) return false;
  final element = oculumNormalizeElementId(item.elementoDanno);
  final type = oculumNormalizeText('${item.craftData['weaponType'] ?? ''}');
  if (!_swordBreakerElements.contains(element) ||
      const {'firearm', 'bow', 'blunt', 'staff'}.contains(type)) {
    return false;
  }
  return element == 'taglio' ||
      item.craftData['gunblade'] == true ||
      _swordBreakerBladeNames.hasMatch(
        '$type ${oculumNormalizeText(item.nome)}',
      );
}

String? _swordBreakerBladeId(Map request) {
  final blade = request['swordBreakerBlade'];
  final id = blade is Map ? blade['instanceId'] : null;
  return id is String && id.length == 32 && RegExp(r'^[0-9a-f]+$').hasMatch(id)
      ? id
      : null;
}

InventoryItem? oculumSwordBreakerOriginalBlade(
  Iterable<InventoryItem> items,
  Map request,
) {
  final id = _swordBreakerBladeId(request);
  if (id == null) return null;
  final blade = items
      .where((item) => item.craftData[_swordBreakerInstanceKey] == id)
      .singleOrNull;
  return blade != null && oculumSwordBreakerPhysicalBlade(blade) ? blade : null;
}

int? oculumSwordBreakerParryNatural(Map request, Map reply) {
  if (_swordBreakerBladeId(request) == null ||
      request['status'] != 'resolved' ||
      request['outcome'] != OculumAttackOutcome.avoided.name ||
      reply['defenseChoice'] != 'cm' ||
      reply['id'] != request['id'] ||
      reply['encounterId'] != request['encounterId'] ||
      reply['sourceTag'] != request['sourceTag'] ||
      reply['targetTag'] != request['targetTag'] ||
      request['counterAttackResponse'] is Map ||
      request['senkaShadowAvoided'] == true ||
      request['senkaImpaleUnavailable'] == true ||
      request['referenceAnatomicalTargetUnavailable'] == true ||
      oculumIsFreeProtectiveImpact(request) ||
      !_swordBreakerElements.contains(
        oculumNormalizeElementId('${request['element'] ?? ''}'),
      )) {
    return null;
  }
  final natural = reply['defenseNatural'];
  final attack = request['attack'];
  final defense = reply['defense'];
  if (natural is! int ||
      natural < 2 ||
      natural > 20 ||
      attack is! int ||
      defense is! int ||
      oculumAttackOutcome(
            attack,
            defense,
            difficulty: '${request['difficulty'] ?? 'normale'}',
          ) !=
          OculumAttackOutcome.avoided) {
    return null;
  }
  return natural;
}

({
  String? winner,
  bool tied,
  List<({String tag, int natural, int? total})> rolls,
})
oculumSwordBreakerPickupContest({
  required String ownerTag,
  required Map<String, ({int reflexes, int movement})> contenders,
  required int Function() rollD20,
}) {
  final rolls = <({String tag, int natural, int? total})>[];
  for (final entry in contenders.entries) {
    final natural = rollD20();
    rolls.add((
      tag: entry.key,
      natural: natural,
      total: natural < 2 || natural > 20
          ? null
          : natural +
                entry.value.reflexes +
                entry.value.movement +
                (entry.key == ownerTag ? 2 : 0),
    ));
  }
  final successful = rolls.where((roll) => roll.total != null).toList()
    ..sort((a, b) => b.total!.compareTo(a.total!));
  final tied =
      successful.length >= 2 && successful[0].total == successful[1].total;
  return (
    winner: successful.isEmpty || tied ? null : successful.first.tag,
    tied: tied,
    rolls: rolls,
  );
}

extension _OculumSwordBreaker on _OculumHomePageState {
  bool get swordBreakerLocalPickupAvailable =>
      !onlineMasterApprovalRequired &&
      (modalitaMaster || isMasterHost) &&
      selectedMasterInitiativeGroupId.isNotEmpty;

  Map<String, dynamic>? swordBreakerBladeSnapshot(
    Iterable<InventoryItem> weapons, {
    required String attackElement,
  }) {
    final blade = weapons.firstOrNull;
    if (blade == null ||
        !inventario.contains(blade) ||
        !blade.equipaggiata ||
        oculumSwordBreakerDropped(blade) ||
        !oculumSwordBreakerPhysicalBlade(blade) ||
        !_swordBreakerElements.contains(
          oculumNormalizeElementId(attackElement),
        )) {
      return null;
    }
    var id = '${blade.craftData[_swordBreakerInstanceKey] ?? ''}';
    final valid = RegExp(r'^[0-9a-f]{32}$').hasMatch(id);
    if (!valid ||
        inventario.any(
          (other) =>
              !identical(other, blade) &&
              other.craftData[_swordBreakerInstanceKey] == id,
        )) {
      final random = Random.secure();
      id = List.generate(
        8,
        (_) => random.nextInt(1 << 16).toRadixString(16).padLeft(4, '0'),
      ).join();
      blade.craftData = {...blade.craftData, _swordBreakerInstanceKey: id};
      programmaSalvataggio();
    }
    return {'instanceId': id, 'name': blade.nome};
  }

  void attachSwordBreakerParry(Map<String, dynamic> request) {
    // The incoming attack cannot supply a defense claim for itself.
    request.remove('swordBreakerParry');
    if (oculumSwordBreakerParryNatural(request, request) == null ||
        sheetTagAt(schedaCorrente) != request['targetTag'] ||
        !armiEquipaggiate().any(
          (item) =>
              item.craftData['swordBreaker'] == true &&
              !oculumSwordBreakerDropped(item),
        )) {
      return;
    }
    request['swordBreakerParry'] = true;
  }

  void consumeSwordBreakerDisarmAction() {
    final condition = activeConditions
        .where(
          (entry) =>
              entry.conditionType == 'disarmato' &&
              entry.metadata['referenceCurseSource'] == 'sword-breaker',
        )
        .firstOrNull;
    if (condition == null) return;
    removeCondition(condition, force: true, expired: true);
  }

  void applySwordBreakerParry(Map request, Map reply) {
    if (reply['swordBreakerParry'] != true) return;
    final natural = oculumSwordBreakerParryNatural(request, reply);
    final encounter = '${request['encounterId'] ?? ''}';
    final packet = '${request['id'] ?? ''}';
    final source = '${request['sourceTag'] ?? ''}';
    final target = '${request['targetTag'] ?? ''}';
    if (natural == null ||
        packet.isEmpty ||
        encounter.isEmpty ||
        encounter != onlineCombatEncounterId ||
        !currentCombatIsActive() ||
        source.isEmpty ||
        target.isEmpty ||
        source == target) {
      return;
    }
    faunaForOwnedSheet(source, () {
      final blade = oculumSwordBreakerOriginalBlade(inventario, request);
      if (blade == null || !faunaReceipt('sword-breaker:$encounter:$packet')) {
        return;
      }
      final disarmed = applyCondition(
        'disarmato',
        duration: 1,
        durationType: OculumConditionDurationType.actions,
        tickTrigger: OculumConditionTickTrigger.action,
        source: 'Sword Breaker',
        metadata: {
          'referenceCurseSource': 'sword-breaker',
          _swordBreakerInstanceKey: blade.craftData[_swordBreakerInstanceKey],
        },
      );
      if (disarmed) setInventoryItemEquipped(blade, false);
      if ((disarmed || natural == 20) &&
          oculumEquipmentCanWear(blade) &&
          !oculumSwordBreakerDropped(blade) &&
          blade.quantita > 1) {
        final remaining = InventoryItem.fromJson(blade.toJson())
          ..quantita = blade.quantita - 1
          ..equipaggiata = false
          ..craftData = ({...blade.craftData}
            ..remove(_swordBreakerInstanceKey));
        inventario.add(remaining);
        blade.quantita = 1;
      }
      if (disarmed &&
          swordBreakerLocalPickupAvailable &&
          oculumEquipmentCanWear(blade) &&
          !oculumSwordBreakerDropped(blade)) {
        blade.craftData = {
          ...blade.craftData,
          _swordBreakerDropKey: {
            'id': '$encounter:$packet',
            'encounterId': encounter,
            'ownerTag': source,
            'defenderTag': target,
          },
        };
      }
      if (natural == 20 &&
          oculumDefenseGrantsFreeReaction(
            readIntValue(request['attack']),
            readIntValue(reply['defense']),
          ) &&
          oculumEquipmentCanWear(blade)) {
        final spent = oculumSpendEquipmentWear(
          blade,
          oculumEquipmentUses(blade),
        );
        if (spent > 0) aggiungiLog('[SWORD BREAKER] ${blade.nome} si spezza.');
      }
      invalidateDerivedDataCaches();
      notifyActiveSheetSummaryChanged();
      programmaSalvataggio();
    });
  }

  List<_SwordBreakerDrop> _localSwordBreakerDrops(String encounter) {
    final drops = <_SwordBreakerDrop>[];
    for (var index = 0; index < schedePersonaggio.length; index++) {
      final tag = sheetTagAt(index);
      if (!controlsOnlineCombatSheet(tag)) continue;
      final items = index == schedaCorrente
          ? inventario.map((item) => item.toJson())
          : (schedePersonaggio[index]['inventario'] as List? ?? [])
                .whereType<Map>();
      for (final item in items) {
        final craft = item['craftData'];
        if (item['arma'] != true ||
            craft is! Map ||
            craft['titleItem'] == true) {
          continue;
        }
        final drop = craft[_swordBreakerDropKey];
        if (drop is! Map ||
            drop['encounterId'] != encounter ||
            drop['ownerTag'] != tag) {
          continue;
        }
        final id = '${drop['id'] ?? ''}';
        if (id.isNotEmpty) {
          drops.add((id: id, ownerTag: tag, name: '${item['nome']}'));
        }
      }
    }
    final counts = <String, int>{};
    for (final drop in drops) {
      counts.update(drop.id, (count) => count + 1, ifAbsent: () => 1);
    }
    return drops.where((drop) => counts[drop.id] == 1).toList();
  }

  Map<String, String> _localSwordBreakerContenders() => {
    for (final token in masterInitiativeTokens)
      if (masterInitiativeTokenCanAct(token) &&
          token['status'] != 'fled' &&
          !masterInitiativeTokenIsTemporary(token) &&
          controlsOnlineCombatSheet(publicInitiativeSourceTag(token)))
        publicInitiativeSourceTag(token): '${token['name'] ?? '???'}',
  };

  Future<void> showSwordBreakerPickup() async {
    if (!swordBreakerLocalPickupAvailable) return;
    final encounter = selectedMasterInitiativeGroupId;
    final drops = _localSwordBreakerDrops(encounter);
    final candidates = _localSwordBreakerContenders();
    if (drops.isEmpty || candidates.isEmpty) {
      aggiungiLog(
        t(
          'Nessuna arma a terra raccoglibile nello scontro.',
          'No weapon can be picked up in this encounter.',
        ),
      );
      return;
    }
    var drop = drops.first;
    final selected = <String>{};
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          scrollable: true,
          title: Text(t('Armi a terra', 'Dropped weapons')),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: drop.id,
                  isExpanded: true,
                  items: [
                    for (final item in drops)
                      DropdownMenuItem(value: item.id, child: Text(item.name)),
                  ],
                  onChanged: (id) {
                    if (id != null) {
                      update(
                        () => drop = drops.firstWhere((item) => item.id == id),
                      );
                    }
                  },
                ),
                Text(
                  t(
                    'Scegli chi tenta la raccolta. Riflessi + Movimento, con +2 al proprietario.',
                    'Choose who attempts pickup. Reflexes + Movement, with +2 to the owner.',
                  ),
                ),
                for (final candidate in candidates.entries)
                  CheckboxListTile(
                    title: Text(
                      '${candidate.value}${candidate.key == drop.ownerTag ? ' (+2)' : ''}',
                    ),
                    value: selected.contains(candidate.key),
                    onChanged: (value) => update(() {
                      if (value == true) {
                        selected.add(candidate.key);
                      } else {
                        selected.remove(candidate.key);
                      }
                    }),
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
              onPressed: selected.isEmpty
                  ? null
                  : () => Navigator.pop(dialog, true),
              child: Text(t('Tira per la raccolta', 'Roll for pickup')),
            ),
          ],
        ),
      ),
    );
    if (!mounted ||
        confirmed != true ||
        !swordBreakerLocalPickupAvailable ||
        selectedMasterInitiativeGroupId != encounter ||
        !_localSwordBreakerDrops(encounter).contains(drop)) {
      return;
    }

    final contenders = <String, ({int reflexes, int movement})>{};
    final active = _localSwordBreakerContenders();
    for (final tag in selected.where(active.containsKey)) {
      faunaForOwnedSheet(tag, () {
        final reflexes = hiddenEyeStats
            .where((stat) => stat.id == 'riflessi')
            .firstOrNull;
        contenders[tag] = (
          reflexes: reflexes == null ? 0 : hiddenEyeTotal(reflexes),
          movement: movimento(),
        );
      });
    }
    final random = Random.secure();
    final result = oculumSwordBreakerPickupContest(
      ownerTag: drop.ownerTag,
      contenders: contenders,
      rollD20: () => random.nextInt(20) + 1,
    );
    for (final roll in result.rolls) {
      aggiungiLog(
        '[RACCOLTA] ${active[roll.tag]}: ${roll.natural} naturale · ${roll.total ?? t('fallito', 'failed')}.',
      );
    }
    final winner = result.winner;
    if (winner == null) {
      aggiungiLog(
        result.tied
            ? t(
                'Parità: l’arma resta a terra.',
                'Tie: the weapon remains on the ground.',
              )
            : t(
                'Nessun tiro valido: l’arma resta a terra.',
                'No valid roll: the weapon remains on the ground.',
              ),
      );
      return;
    }
    final winnerIndex = localSheetIndexForOculumTag(winner);
    if (winnerIndex < 0 || !controlsOnlineCombatSheet(winner)) return;
    var pickedUp = false;
    faunaForOwnedSheet(drop.ownerTag, () {
      final destination = schedePersonaggio[winnerIndex];
      final returningToOwner = winner == drop.ownerTag;
      final destinationItems = returningToOwner
          ? null
          : List<dynamic>.from(destination['inventario'] as List? ?? []);
      final blade = oculumTakeSwordBreakerDrop(
        inventario,
        drop.id,
        returningToOwner: returningToOwner,
      );
      if (blade == null) return;
      if (destinationItems != null) {
        destination['inventario'] = [...destinationItems, blade.toJson()];
      }
      pickedUp = true;
    });
    if (!pickedUp) return;
    aggiungiLog('[RACCOLTA] ${active[winner]} raccoglie ${drop.name}.');
    invalidateDerivedDataCaches();
    notifyActiveSheetSummaryChanged();
    programmaSalvataggio();
    if (mounted) setState(() {});
  }
}
