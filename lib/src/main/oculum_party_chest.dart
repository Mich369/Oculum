part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

double oculumPartyChestCapacity(Iterable<Map> members) => members.fold<double>(
  0,
  (total, member) => total + 1 + max(0, readIntValue(member['level'])) * .5,
);

double oculumPartyChestWeight(Iterable<Map> entries) =>
    entries.fold<double>(0, (total, entry) {
      final item = entry['item'];
      if (item is! Map) return total;
      return total +
          max(0, readDoubleValue(item['peso'])) *
              max(0, readIntValue(item['quantita']));
    });

/// Pure, serial application by the room's authenticated Master. Operation IDs
/// survive saves and retries, so concurrent withdrawals cannot spend one balance twice.
Map<String, dynamic> oculumApplyPartyChestOperation(Map previous, Map request) {
  final state = Map<String, dynamic>.from(
    jsonDecode(jsonEncode(previous)) as Map,
  );
  final receipts = Map<String, dynamic>.from(state['receipts'] as Map? ?? {});
  final id = '${request['id'] ?? ''}';
  if (id.isEmpty || receipts.containsKey(id)) return state;
  final items = (state['items'] as List? ?? [])
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
  var balance = max(0, readIntValue(state['obser']));
  final amount = readIntValue(request['amount']);
  var approved = false;
  var message = 'Operazione non valida';
  Map<String, dynamic>? transferred;
  switch (request['operation']) {
    case 'deposit_obser':
      if (amount > 0) {
        balance += amount;
        approved = true;
        message = '+$amount Obser';
      }
      break;
    case 'withdraw_obser':
      if (amount > 0 && amount <= balance) {
        balance -= amount;
        approved = true;
        message = '−$amount Obser';
      } else {
        message = 'Obser insufficienti nella cassa';
      }
      break;
    case 'deposit_item':
      if (request['item'] is Map) {
        final item = Map<String, dynamic>.from(request['item'] as Map);
        final quantity = readIntValue(item['quantita']);
        final weight = readDoubleValue(item['peso']);
        final members = (state['members'] as Map? ?? {}).values
            .whereType<Map>();
        if (quantity > 0 &&
            weight.isFinite &&
            weight > 0 &&
            oculumPartyChestWeight(items) + quantity * weight <=
                oculumPartyChestCapacity(members) + .000001) {
          item['equipaggiata'] = false;
          items.add({'id': id, 'item': item});
          approved = true;
          message = 'Depositato ${item['nome']} ×$quantity';
        } else {
          message = 'Capienza della cassa insufficiente';
        }
      }
      break;
    case 'withdraw_item':
      final index = items.indexWhere((e) => e['id'] == request['entryId']);
      if (index >= 0 && amount > 0) {
        final item = Map<String, dynamic>.from(items[index]['item'] as Map);
        final quantity = readIntValue(item['quantita']);
        if (amount <= quantity) {
          transferred = {...item, 'quantita': amount, 'equipaggiata': false};
          if (quantity == amount) {
            items.removeAt(index);
          } else {
            items[index]['item'] = {...item, 'quantita': quantity - amount};
          }
          approved = true;
          message = 'Prelevato ${item['nome']} ×$amount';
        }
      }
      if (!approved) message = 'Oggetto già prelevato o quantità insufficiente';
      break;
  }
  receipts[id] = {
    'id': id,
    'approved': approved,
    'message': message,
    'requesterTag': request['requesterTag'],
    'operation': request['operation'],
    'amount': amount,
    'item': ?transferred,
  };
  state.addAll({
    'obser': balance,
    'items': items,
    'receipts': receipts,
    'revision': readIntValue(state['revision']) + 1,
  });
  oculumPromotePendingChestLoot(state);
  return state;
}

int oculumItemTitleDustCost(int itemLevel) => (max(0, itemLevel) + 1) ~/ 2 + 1;

String oculumPartyHuntSpeciesId(String bookId) {
  var id = bookId.trim().replaceFirst(RegExp(r'_variante_.*$'), '');
  final visited = <String>{};
  while (visited.add(id)) {
    final parent =
        '${monsterBookEntryById(id)?.encounterRules['canonicalVariantOf'] ?? ''}';
    if (parent.isEmpty || visited.contains(parent)) break;
    id = parent;
  }
  return id;
}

({Map<String, dynamic> records, int earned}) oculumPartySpeciesRewards(
  Map previous,
  Iterable<Map> enemies,
  String encounterId,
) {
  final records = Map<String, dynamic>.from(
    jsonDecode(jsonEncode(previous)) as Map,
  );
  var earned = 0;
  for (final enemy in enemies) {
    if (oculumEncounterEnemyIsSummon(enemy)) continue;
    final species = oculumPartyHuntSpeciesId('${enemy['monsterBookId'] ?? ''}');
    if (species.isEmpty) continue;
    final source = oculumNormalizeText('${enemy['source'] ?? ''}');
    final book = monsterBookEntryById('${enemy['monsterBookId']}');
    final mini =
        book?.isMiniBoss == true ||
        source.contains('mini') && source.contains('boss');
    final boss = !mini && (book?.isBoss == true || source.contains('boss'));
    final needed = boss
        ? 1
        : mini
        ? 2
        : 3;
    final base = boss
        ? 50
        : mini
        ? 30
        : 10;
    final key =
        '$species:${boss
            ? 'boss'
            : mini
            ? 'mini'
            : 'ordinary'}';
    final record = Map<String, dynamic>.from(records[key] as Map? ?? {});
    if (record['credited'] == true) continue;
    final kills = (record['killIds'] as List? ?? []).map((id) => '$id').toSet();
    final killId = '$encounterId:${enemy['monsterSheetTag'] ?? enemy['id']}';
    if (!kills.add(killId)) continue;
    final stats = enemy.containsKey('statsTotal')
        ? max(0, readIntValue(enemy['statsTotal']))
        : ['resilienza', 'volonta', 'materia', 'oculum'].fold<int>(
            0,
            (sum, stat) => sum + max(0, readIntValue(enemy[stat])),
          );
    final totalStats = readIntValue(record['statsTotal']) + stats;
    final completed = kills.length >= needed;
    final reward = completed ? base + totalStats : 0;
    records[key] = {
      'species': species,
      'name': enemy['name'],
      'needed': needed,
      'count': kills.length,
      'killIds': kills.toList(),
      'statsTotal': totalStats,
      'credited': completed,
      'obser': reward,
    };
    earned += reward;
  }
  return (records: records, earned: earned);
}

extension _OculumPartyChest on _OculumHomePageState {
  Iterable<Map> partyHuntsForMonster(String monsterId) =>
      (partyChest['hunts'] as Map? ?? {}).values.whereType<Map>().where(
        (record) => record['species'] == oculumPartyHuntSpeciesId(monsterId),
      );

  String partyHuntProgressText(
    String monsterId,
  ) => partyHuntsForMonster(monsterId)
      .map(
        (r) => r['credited'] == true
            ? '+${r['obser']} Obser in cassa · premio già ottenuto'
            : 'Uccisioni ${r['count']}/${r['needed']} · ${r['statsTotal']} Obser statistici accumulati',
      )
      .join(' · ');

  void recordPartySpeciesHunts(Iterable<Map> enemies, String encounterId) {
    final previous = partyChest['hunts'] as Map? ?? {};
    final updated = oculumPartySpeciesRewards(previous, enemies, encounterId);
    if (jsonEncode(previous) == jsonEncode(updated.records)) return;
    partyChest['hunts'] = updated.records;
    partyChest['obser'] =
        max(0, readIntValue(partyChest['obser'])) + updated.earned;
    partyChest['revision'] = readIntValue(partyChest['revision']) + 1;
    for (final enemy in enemies) {
      final id = '${enemy['monsterBookId'] ?? ''}';
      if (id.isNotEmpty && !oculumEncounterEnemyIsSummon(enemy)) {
        rememberMonsterBookPartyDiscovery(id, seen: true, broadcast: true);
      }
    }
    if (updated.earned > 0) {
      aggiungiLog(
        '[MONSTER BOOK PARTY] +${updated.earned} Obser nella cassa comune: premio specie ottenuto una sola volta.',
      );
    }
    combatKnowledgeRevision.value++;
    programmaSalvataggio();
    unawaited(sendPartyChestState());
  }

  Map<String, dynamic> get partyChest => partyChestCampaigns.putIfAbsent(
    permissionCampaignId,
    () => {
      'obser': 0,
      'items': <dynamic>[],
      'members': <String, dynamic>{},
      'revision': 0,
      'receipts': <String, dynamic>{},
    },
  );

  void refreshPartyChestMembers() {
    if (!realtimeIsMasterRole || realtimeService?.isConnected != true) return;
    final members = Map<String, dynamic>.from(
      partyChest['members'] as Map? ?? {},
    );
    final onlineTags = <String>{...ownPermissionTags};
    for (final user in realtimeUsers) {
      onlineTags.add('${user['activeSheetTag'] ?? ''}');
      for (final tag in user['localSheetTags'] as List? ?? []) {
        onlineTags.add('$tag');
      }
    }
    for (final index in masterPartyIndexes()) {
      final tag = sheetTagAt(index);
      if (!onlineTags.contains(tag) && !members.containsKey(tag)) continue;
      final type = oculumNormalizeText(tipoSchedaPersonaggio(index));
      if (isEnemySheetAt(index) ||
          RegExp(
            r'mostr|monster|boss|occhi|occhio|fallen|pawn|creatura|creature',
          ).hasMatch(type)) {
        continue;
      }
      members[tag] = {
        'tag': tag,
        'name': nomeSchedaPersonaggio(index),
        'level': index == schedaCorrente
            ? leggiNumero(livelloController)
            : sheetIntValueAt(index, 'livello'),
      };
    }
    if (jsonEncode(members) != jsonEncode(partyChest['members'])) {
      partyChest['members'] = members;
      partyChest['revision'] = readIntValue(partyChest['revision']) + 1;
      programmaSalvataggio();
      refreshPartyQuestStats();
    }
  }

  Future<void> sendPartyChestState() async {
    if (!realtimeIsMasterRole || realtimeService?.isConnected != true) return;
    refreshPartyChestMembers();
    refreshPartyQuestStats();
    await realtimeService!.sendPermissionEvent(
      'permission_decision',
      permissionEnvelope({
        'action': 'party_chest',
        'operation': 'snapshot',
        'state': partyChest,
      }),
    );
  }

  Future<void> replayPartyChestRequests() async {
    if (realtimeService?.isConnected != true) return;
    for (final request in partyChestPending.values.toList()) {
      if (request['status'] != 'pending' ||
          request['campaignId'] != permissionCampaignId) {
        continue;
      }
      if (realtimeIsMasterRole) {
        await receivePartyChestEvent(
          'permission_request',
          permissionEnvelope(request),
          local: true,
        );
      } else {
        await realtimeService!.sendPermissionEvent(
          'permission_request',
          permissionEnvelope(request),
        );
      }
    }
  }

  Future<void> receivePartyChestEvent(
    String event,
    Map<String, dynamic> payload, {
    bool local = false,
  }) async {
    if (payload['campaignId'] != permissionCampaignId ||
        payload['scope'] != permissionScope) {
      return;
    }
    if (event == 'permission_request') {
      if (!realtimeIsMasterRole ||
          (!local && !validPermissionSender(payload))) {
        return;
      }
      refreshPartyChestMembers();
      final state = oculumApplyPartyChestOperation(partyChest, payload);
      partyChestCampaigns[permissionCampaignId] = state;
      await salvaDatiSoloLocale();
      final receipt = (state['receipts'] as Map?)?['${payload['id']}'];
      if (receipt is! Map) return;
      final reply = permissionEnvelope({
        'action': 'party_chest',
        'operation': 'receipt',
        'receipt': receipt,
        'state': state,
      });
      await receivePartyChestEvent('permission_decision', reply, local: true);
      await realtimeService?.sendPermissionEvent('permission_decision', reply);
      return;
    }
    if (event != 'permission_decision' ||
        (!local &&
            (!validPermissionSender(payload, staff: true) ||
                payload['senderRole'] != 'master'))) {
      return;
    }
    if (payload['state'] is Map) {
      final incoming = Map<String, dynamic>.from(payload['state'] as Map);
      if (readIntValue(incoming['revision']) >=
          readIntValue(partyChest['revision'])) {
        partyChestCampaigns[permissionCampaignId] = incoming;
      }
    }
    settlePartyQuestRewards();
    final receipt = payload['receipt'];
    faunaConfirmedKills(
      (partyChest['confirmedFaunaKills'] as Map? ?? {}).values.whereType<Map>(),
      'confirmed',
    );
    if (receipt is Map) settlePartyChestReceipt(receipt);
    programmaSalvataggio();
    combatKnowledgeRevision.value++;
    if (mounted) setState(() {});
  }

  void settlePartyChestReceipt(Map receipt) {
    final pending = partyChestPending['${receipt['id']}'];
    if (pending == null ||
        pending['status'] != 'pending' ||
        pending['campaignId'] != permissionCampaignId ||
        receipt['requesterTag'] != pending['requesterTag']) {
      return;
    }
    final index = localSheetIndexForOculumTag('${pending['requesterTag']}');
    if (index < 0 ||
        !ownPermissionTags.contains('${pending['requesterTag']}')) {
      return;
    }
    final original = schedaCorrente;
    salvaSchedaCorrenteInMemoria();
    final global = catturaImpostazioniGlobali();
    try {
      if (index != original) {
        schedaCorrente = index;
        caricaStatoDaJson(schedePersonaggio[index]);
        ripristinaImpostazioniGlobali(global);
      }
      final approved = receipt['approved'] == true;
      final operation = '${pending['operation']}';
      final amount = readIntValue(pending['amount']);
      if (approved && operation == 'withdraw_obser' ||
          !approved && operation == 'deposit_obser') {
        obserController.text =
            '${max(0, leggiNumero(obserController)) + amount}';
      }
      if (approved && operation == 'withdraw_item' && receipt['item'] is Map) {
        inventario.add(
          InventoryItem.fromJson(
            Map<String, dynamic>.from(receipt['item'] as Map),
          ),
        );
      }
      if (!approved && operation == 'deposit_item' && pending['item'] is Map) {
        inventario.add(
          InventoryItem.fromJson(
            Map<String, dynamic>.from(pending['item'] as Map),
          ),
        );
      }
      // Settle before any save: replaying a receipt cannot mint a second copy.
      pending['status'] = approved ? 'approved' : 'rejected';
      partyChestPending['${receipt['id']}']?['status'] = pending['status'];
      aggiungiLog(
        '[CASSA COMUNE] ${receipt['message']}${approved ? '' : ' · deposito restituito'}.',
      );
      invalidateDerivedDataCaches();
      salvaSchedaCorrenteInMemoria();
    } finally {
      if (index != original && mounted) {
        final updatedGlobal = catturaImpostazioniGlobali();
        schedaCorrente = original;
        caricaStatoDaJson(schedePersonaggio[original]);
        ripristinaImpostazioniGlobali(updatedGlobal);
      }
    }
  }

  Future<void> requestPartyChestOperation(
    String operation, {
    int amount = 0,
    InventoryItem? item,
    String? entryId,
  }) async {
    if (realtimeService?.isConnected != true && !haPermessiMaster) return;
    if (amount <= 0) return;
    if (operation == 'deposit_obser' && amount > leggiNumero(obserController)) {
      return;
    }
    if (operation == 'deposit_item' &&
        (item == null ||
            !inventario.contains(item) ||
            item.equipaggiata ||
            amount > item.quantita)) {
      return;
    }
    final id =
        'chest:${sheetTagAt(schedaCorrente)}:${DateTime.now().microsecondsSinceEpoch}:${Random.secure().nextInt(1 << 30)}';
    final request = <String, dynamic>{
      'id': id,
      'action': 'party_chest',
      'operation': operation,
      'campaignId': permissionCampaignId,
      'scope': permissionScope,
      'requesterTag': sheetTagAt(schedaCorrente),
      'status': 'pending',
      'amount': amount,
      'entryId': ?entryId,
    };
    if (operation == 'deposit_obser') {
      obserController.text = '${leggiNumero(obserController) - amount}';
    }
    if (operation == 'deposit_item' && item != null) {
      request['item'] = {
        ...item.toJson(),
        'quantita': amount,
        'equipaggiata': false,
      };
      item.quantita -= amount;
      if (item.quantita == 0) inventario.remove(item);
    }
    partyChestPending[id] = request;
    salvaSchedaCorrenteInMemoria();
    await salvaDatiSoloLocale();
    if (realtimeService?.isConnected == true) {
      await replayPartyChestRequests();
    } else {
      final state = oculumApplyPartyChestOperation(partyChest, request);
      partyChestCampaigns[permissionCampaignId] = state;
      settlePartyChestReceipt((state['receipts'] as Map)[id] as Map);
    }
    programmaSalvataggio();
    if (mounted) setState(() {});
  }

  Future<int?> askPartyChestAmount(String title, int maximum) async {
    var amount = min(1, maximum);
    return showDialog<int>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text(title),
          content: TextFormField(
            initialValue: '$amount',
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Quantità · massimo $maximum',
            ),
            onChanged: (v) => update(() => amount = int.tryParse(v) ?? 0),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: amount > 0 && amount <= maximum
                  ? () => Navigator.pop(dialog, amount)
                  : null,
              child: const Text('Conferma'),
            ),
          ],
        ),
      ),
    );
  }

  Widget partyChestPanel() {
    final chest = partyChest;
    final items = (chest['items'] as List? ?? []).whereType<Map>().toList();
    final members = (chest['members'] as Map? ?? {}).values
        .whereType<Map>()
        .toList();
    final balance = max(0, readIntValue(chest['obser']));
    final enabled = realtimeService?.isConnected == true || haPermessiMaster;
    Future<void> money(bool deposit) async {
      final amount = await askPartyChestAmount(
        deposit ? 'Versa Obser' : 'Preleva Obser',
        deposit ? leggiNumero(obserController) : balance,
      );
      if (amount != null && mounted) {
        await requestPartyChestOperation(
          deposit ? 'deposit_obser' : 'withdraw_obser',
          amount: amount,
        );
      }
    }

    Future<void> depositItem() async {
      final selected = await showDialog<InventoryItem>(
        context: context,
        builder: (dialog) => SimpleDialog(
          title: const Text('Deposita un oggetto non equipaggiato'),
          children: [
            for (final item in inventario.where(
              (i) => !i.equipaggiata && i.quantita > 0,
            ))
              SimpleDialogOption(
                onPressed: () => Navigator.pop(dialog, item),
                child: Text(
                  '${item.nome} ×${item.quantita} · ${item.peso} kg ciascuno',
                ),
              ),
          ],
        ),
      );
      if (selected == null || !mounted) return;
      final amount = await askPartyChestAmount(
        'Deposita ${selected.nome}',
        selected.quantita,
      );
      if (amount != null && mounted) {
        await requestPartyChestOperation(
          'deposit_item',
          amount: amount,
          item: selected,
        );
      }
    }

    return gothicPanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cassa comune · $balance Obser',
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
          ),
          Text(
            '${oculumPartyChestWeight(items).toStringAsFixed(2)} / ${oculumPartyChestCapacity(members).toStringAsFixed(2)} kg · ${members.length} partecipanti registrati nella campagna del Master',
          ),
          const Text(
            'Gli Obser non pesano. Online tutti possono versare e prelevare; offline il Master gestisce la cassa manualmente.',
          ),
          Wrap(
            spacing: 8,
            children: [
              TextButton(
                onPressed: enabled ? () => unawaited(money(true)) : null,
                child: const Text('Versa Obser'),
              ),
              TextButton(
                onPressed: enabled && balance > 0
                    ? () => unawaited(money(false))
                    : null,
                child: const Text('Preleva Obser'),
              ),
              TextButton(
                onPressed: enabled ? () => unawaited(depositItem()) : null,
                child: const Text('Deposita oggetto'),
              ),
            ],
          ),
          for (final entry in items)
            if (entry['item'] is Map)
              ListTile(
                dense: true,
                title: Text(
                  '${(entry['item'] as Map)['nome']} ×${(entry['item'] as Map)['quantita']}',
                ),
                subtitle: Text('${(entry['item'] as Map)['peso']} kg ciascuno'),
                trailing: TextButton(
                  onPressed: enabled
                      ? () async {
                          final amount = await askPartyChestAmount(
                            'Preleva oggetto',
                            readIntValue((entry['item'] as Map)['quantita']),
                          );
                          if (amount != null && mounted) {
                            await requestPartyChestOperation(
                              'withdraw_item',
                              amount: amount,
                              entryId: '${entry['id']}',
                            );
                          }
                        }
                      : null,
                  child: const Text('Prendi'),
                ),
              ),
          if (partyChestPending.values.any(
            (p) =>
                p['campaignId'] == permissionCampaignId &&
                p['status'] == 'pending',
          ))
            const Text(
              'Trasferimento in attesa di sincronizzazione. I depositi sono riservati e verranno restituiti se rifiutati.',
            ),
        ],
      ),
    );
  }

  void convertInventoryItemToTitle(InventoryItem item) {
    if (!inventario.contains(item) ||
        item.quantita <= 0 ||
        item.craftData['titleItem'] == true) {
      return;
    }
    final cost = oculumItemTitleDustCost(item.livelloOggetto);
    if (leggiNumero(ascensionDustController) < cost) return;
    var converted = item;
    if (item.quantita > 1) {
      item.quantita--;
      converted = InventoryItem.fromJson({
        ...item.toJson(),
        'quantita': 1,
        'equipaggiata': false,
      });
      inventario.add(converted);
    }
    converted.craftData = {
      ...converted.craftData,
      'titleItem': true,
      'evolvable': true,
      'conversionDustCost': cost,
    };
    converted.note +=
        '\nTitolo Item evolvibile: effetti originali conservati; conversione $cost Ascension Dust.';
    if (converted.ability != null && converted.ability!.nonEvolvibile) {
      converted.ability = CharacterSkill.fromJson({
        ...converted.ability!.toJson(),
        'scrollData': <String, dynamic>{},
      });
    }
    ascensionDustController.text =
        '${leggiNumero(ascensionDustController) - cost}';
    aggiungiLog(
      '[TITOLO ITEM] ${converted.nome}: −$cost Ascension Dust, effetti conservati, evoluzioni abilitate.',
    );
    programmaSalvataggio();
    if (mounted) setState(() {});
  }
}
