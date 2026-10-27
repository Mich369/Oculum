part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

String oculumSheetAssignmentReceipt(Map receipt, {required bool local}) =>
    'assignment-v1:${receipt['room_id']}:${receipt['transfer_id']}:${receipt['sheet_tag']}:${local ? 'owner' : 'master'}';

Map<String, dynamic> oculumAssignedLocalSheet(Map receipt, Map raw) {
  final sheet = jsonDecode(jsonEncode(raw)) as Map<String, dynamic>;
  sheet.removeWhere((key, _) => key.startsWith('realtime'));
  for (final key in const [
    'relayServerUrl',
    'relayRoomCode',
    'connectedMasterIp',
    'campaigns',
    'schedePersonaggio',
    'oculumFriends',
    'oculumFriendRequests',
    'oculumSentFriendRequests',
    'blockedOculumFriends',
  ]) {
    sheet.remove(key);
  }
  final tag = '${sheet['sheetTag'] ?? sheet['id'] ?? receipt['sheet_tag']}';
  if (!oculumSameSheetIdentity(tag, receipt['sheet_tag'])) {
    throw const FormatException(
      'Identità della scheda assegnata non corrispondente.',
    );
  }
  sheet['sheetTag'] = tag;
  sheet.putIfAbsent('id', () => tag);
  sheet['sheetAssignmentReceipt'] = oculumSheetAssignmentReceipt(
    receipt,
    local: true,
  );
  sheet['sheetAssignmentSourceName'] = receipt['source_name'];
  sheet['sheetAssignmentOwnerUserId'] = receipt['target_user_id'];
  return sheet;
}

extension _OculumSheetAssignments on _OculumHomePageState {
  Map<String, dynamic> sheetAssignmentBody(int index) {
    final original = schedaJsonAt(index);
    final safe = realtimeSafeSheetJson(
      original,
      includeImage: true,
      includePartyMembers: false,
    );
    // Ownership is transferred with its anti-replay receipts, not reset as if
    // this were a new character. Ordinary sharing intentionally omits these.
    for (final key in const [
      'claimedEncounterRewardIds',
      'magicalLuckCriticalIds',
    ]) {
      if (original.containsKey(key)) {
        safe[key] = oculumCopyJsonTree(original[key]);
      }
    }
    return safe;
  }

  Future<bool> confirmAssignmentConflict(String name) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: const Text('Scheda locale già presente'),
          content: Text(
            '«$name» contiene dati locali diversi. Per ricevere l’assegnazione puoi conservarne prima una copia locale con un nuovo tag.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog, false),
              child: const Text('Più tardi'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialog, true),
              child: const Text('Conserva copia e ricevi'),
            ),
          ],
        ),
      ) ==
      true;

  Future<bool> applySheetAssignment(
    Map<String, dynamic> receipt,
    Map<String, dynamic> body, {
    bool? preserveConflictingCopy,
  }) async {
    await initialSheetLoad;
    final service = realtimeService;
    final user = service?.authenticatedUserId;
    final local = user != null && user == receipt['target_user_id'];
    final source = user != null && user == receipt['source_user_id'];
    if (!mounted ||
        !datiCaricati ||
        service?.isConnected != true ||
        !local && !source) {
      return false;
    }
    final marker = oculumSheetAssignmentReceipt(receipt, local: local);
    if ((ultimoRawSalvataggioConfermato ?? '').contains(jsonEncode(marker))) {
      return true;
    }
    salvaSchedaCorrenteInMemoria();
    final tag = '${body['sheetTag'] ?? body['id'] ?? receipt['sheet_tag']}';
    if (!oculumSameSheetIdentity(tag, receipt['sheet_tag'])) return false;
    var index = localSheetIndexForOculumTag(tag);
    final previous = index >= 0
        ? Map<String, dynamic>.from(schedePersonaggio[index])
        : null;
    final alreadyApplied = previous?['sheetAssignmentReceipt'] == marker;
    final sameContent =
        index >= 0 &&
        oculumRealtimeSheetContentSignature(sheetAssignmentBody(index)) ==
            oculumRealtimeSheetContentSignature(body);
    if (index >= 0 && !alreadyApplied && (local || !sameContent)) {
      final accepted =
          preserveConflictingCopy ??
          await confirmAssignmentConflict(
            '${previous?['nome'] ?? receipt['sheet_name']}',
          );
      if (!accepted || !mounted || realtimeService != service) return false;
      // Preserve the pre-existing character; never overwrite that saved work.
      final used = schedePersonaggio
          .map((s) => '${s['sheetTag'] ?? s['id']}'.toUpperCase())
          .toSet();
      final backup = jsonDecode(jsonEncode(previous)) as Map<String, dynamic>;
      final backupTag = generaTagUnicoScheda(schedePersonaggio.length, used);
      backup['id'] = backup['sheetTag'] = backupTag;
      backup['nome'] =
          '${backup['nome'] ?? 'Scheda'} · copia prima dell’assegnazione';
      backup.removeWhere(
        (key, _) =>
            key.startsWith('realtime') || key.startsWith('sheetAssignment'),
      );
      backup['inMasterParty'] = false;
      schedePersonaggio.add(backup);
    }
    if (alreadyApplied) {
      await salvaDatiSoloLocale();
      return (ultimoRawSalvataggioConfermato ?? '').contains(
        jsonEncode(marker),
      );
    }
    Map<String, dynamic> incoming;
    if (local) {
      incoming = oculumAssignedLocalSheet(receipt, body);
      if ('${incoming['monsterBookSourceId'] ?? ''}'.isNotEmpty) {
        incoming['monsterBookApproved'] = true;
        incoming['monsterBookApprovedScope'] = permissionScope;
        incoming['monsterBookApprovalRequired'] = false;
      }
      sheetSidebarPlacements[tag] = {
        'folder': '',
        'order': DateTime.now().microsecondsSinceEpoch.toDouble(),
      };
    } else {
      incoming = {
        ...?previous,
        ...jsonDecode(jsonEncode(body)) as Map<String, dynamic>,
      };
      if (previous != null && previous.containsKey('logEventi')) {
        incoming['logEventi'] = previous['logEventi'];
      }
      final record = <String, dynamic>{
        'ownerTag': tag,
        'ownerName': receipt['target_name'],
        'sheetId': tag,
        'sheetName': receipt['sheet_name'],
        'campaignId': receipt['campaign_id'],
        'campaignName': receipt['campaign_name'],
        'senderUserId': receipt['target_user_id'],
        'authenticatedUserId': receipt['target_user_id'],
        'senderRole': 'player',
        'sheet': body,
        'sentAt': receipt['created_at'],
      };
      record['key'] = realtimeSharedSheetKey(
        ownerTag: tag,
        campaignId: '${receipt['campaign_id'] ?? ''}',
        sheetId: tag,
        senderUserId: '${receipt['target_user_id']}',
      );
      final existingRecord = realtimeSharedSheetIndexForKey('${record['key']}');
      if (existingRecord < 0) {
        realtimeSharedSheets.add(record);
      } else {
        realtimeSharedSheets[existingRecord] = record;
      }
      incoming.addAll({
        'realtimeSharedSheet': true,
        'realtimeSourceSheetTag': tag,
        'realtimeSourceKey': record['key'],
        'realtimeLocalSheetTag': tag,
        'realtimeOwnerTag': tag,
        'realtimeOwnerName': receipt['target_name'],
        'realtimeCampaignId': receipt['campaign_id'],
        'realtimeCampaignName': receipt['campaign_name'],
        'realtimeDirtyLocal': false,
        'sheetAssignmentReceipt': marker,
        'sheetAssignmentOwnerUserId': receipt['target_user_id'],
      });
      const folderId = 'oculum_received_online_sheets';
      if (!sheetSidebarFolders.any((folder) => folder['id'] == folderId)) {
        sheetSidebarFolders.add({
          'id': folderId,
          'name': 'Online',
          'parent': '',
          'expanded': true,
        });
      }
      sheetSidebarPlacements[tag] = {
        'folder': folderId,
        'order': DateTime.now().microsecondsSinceEpoch.toDouble(),
      };
    }
    if (index < 0) {
      index = schedePersonaggio.length;
      schedePersonaggio.add(incoming);
    } else {
      schedePersonaggio[index] = incoming;
    }
    if (index == schedaCorrente) caricaStatoDaJson(incoming);
    sheetSidebarRevision.value++;
    notifyActiveSheetSummaryChanged();
    if (mounted) setState(() {});
    await salvaDatiSoloLocale();
    return (ultimoRawSalvataggioConfermato ?? '').contains(jsonEncode(marker));
  }

  Future<void> syncSheetAssignments() {
    final old = sheetAssignmentsSync;
    if (old != null) {
      sheetAssignmentsSyncRequested = true;
      return old;
    }
    final service = realtimeService;
    return sheetAssignmentsSync = _syncSheetAssignments(service).whenComplete(
      () {
        sheetAssignmentsSync = null;
        final requested = sheetAssignmentsSyncRequested;
        sheetAssignmentsSyncRequested = false;
        if (mounted &&
            (realtimeService != service || requested) &&
            realtimeService?.isConnected == true) {
          unawaited(syncSheetAssignments());
        }
      },
    );
  }

  Future<void> _syncSheetAssignments(OculumRealtimeService? service) async {
    await initialSheetLoad;
    if (service?.isConnected != true || !datiCaricati) return;
    try {
      final pending = await service!.pendingSheetAssignments();
      var acknowledged = 0;
      for (final receipt in pending) {
        if (!mounted || realtimeService != service) return;
        final owner = service.authenticatedUserId == receipt['target_user_id'];
        final marker = oculumSheetAssignmentReceipt(receipt, local: owner);
        final saved = (ultimoRawSalvataggioConfermato ?? '').contains(
          jsonEncode(marker),
        );
        if (!saved) {
          final body = await service.assignedSheetBody(receipt);
          if (!mounted ||
              realtimeService != service ||
              !await applySheetAssignment(receipt, body)) {
            continue;
          }
        }
        await service.acknowledgeSheetAssignment(receipt);
        acknowledged++;
      }
      if (pending.length == 50 && acknowledged == 50) {
        sheetAssignmentsSyncRequested = true;
      }
      if (pending.isNotEmpty && mounted && realtimeService == service) {
        await service.refreshPresence();
      }
    } catch (error) {
      if (!mounted || realtimeService != service) return;
      risultato =
          'Schede assegnate in attesa. Usa Sincronizza assegnazioni quando la connessione è disponibile.';
      aggiungiLog('[ASSEGNAZIONE] $error');
      notifyActiveSheetSummaryChanged();
    }
  }

  Widget sheetAssignmentControls() => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      if (realtimeService?.isConnected == true && realtimeIsMasterRole)
        OutlinedButton.icon(
          key: const ValueKey('assign_owned_sheets'),
          onPressed: showAssignSheetsDialog,
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text('Assegna schede a un giocatore'),
        ),
      if (realtimeService?.isConnected == true)
        TextButton.icon(
          onPressed: syncSheetAssignments,
          icon: const Icon(Icons.sync),
          label: const Text('Sincronizza assegnazioni'),
        ),
    ],
  );

  Future<void> showAssignSheetsDialog() async {
    await initialSheetLoad;
    if (!mounted) return;
    final service = realtimeService;
    if (service?.isConnected != true || !realtimeIsMasterRole) return;
    salvaSchedaCorrenteInMemoria();
    final sheets = <String, String>{
      for (var i = 0; i < schedePersonaggio.length; i++)
        if (!readBoolValue(schedePersonaggio[i]['realtimeSharedSheet']))
          sheetTagAt(i): nomeSchedaPersonaggio(i),
    };
    final players = <String, Map<String, dynamic>>{
      for (final user in realtimeUsers)
        if (user['role'] == 'player' &&
            '${user['userId'] ?? ''}'.isNotEmpty &&
            readIntValue(user['sheetAssignmentVersion']) >= 1)
          '${user['userId']}': user,
    };
    final selected = <String>{}; // Always empty, including on reopening.
    String? recipient;
    var sending = false;
    var submitted = false;
    var registered = false;
    final transferId = service!.newSheetTransferId();
    List<Map<String, dynamic>>? submittedPackets;
    String? errorText;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialog) => StatefulBuilder(
        builder: (dialog, update) => PopScope(
          canPop: !sending,
          child: AlertDialog(
            title: const Text('Assegna schede'),
            content: SizedBox(
              width: 520,
              height: min(460.0, MediaQuery.sizeOf(dialog).height * .6),
              child: Column(
                children: [
                  const Text(
                    'Le schede scelte diventeranno locali del giocatore e Online per il Master.',
                  ),
                  DropdownButtonFormField<String>(
                    key: const ValueKey('assignment_recipient'),
                    initialValue: recipient,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Giocatore destinatario',
                    ),
                    items: [
                      for (final entry in players.entries)
                        DropdownMenuItem(
                          value: entry.key,
                          child: Text(
                            '${entry.value['playerName'] ?? entry.value['name'] ?? entry.value['displayName'] ?? 'Giocatore'}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: sending || submitted
                        ? null
                        : (value) => update(() => recipient = value),
                  ),
                  if (players.isEmpty)
                    const Text(
                      'Attendi un giocatore autorizzato con una versione dell’app che supporta le assegnazioni.',
                    ),
                  Expanded(
                    child: ListView(
                      children: [
                        for (final entry in sheets.entries)
                          CheckboxListTile(
                            key: ValueKey('assign_sheet_${entry.key}'),
                            value: selected.contains(entry.key),
                            title: Text(entry.value),
                            subtitle: Text(entry.key),
                            onChanged: sending || submitted
                                ? null
                                : (value) => update(() {
                                    if (value == true) {
                                      selected.add(entry.key);
                                    } else {
                                      selected.remove(entry.key);
                                    }
                                  }),
                          ),
                      ],
                    ),
                  ),
                  if (errorText != null)
                    Text(
                      errorText!,
                      style: const TextStyle(color: Colors.orangeAccent),
                    ),
                  if (sending) const LinearProgressIndicator(),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: sending ? null : () => Navigator.pop(dialog),
                child: const Text('Chiudi'),
              ),
              FilledButton(
                key: const ValueKey('confirm_assign_sheets'),
                onPressed: sending || recipient == null || selected.isEmpty
                    ? null
                    : () async {
                        update(() {
                          sending = true;
                          errorText = null;
                        });
                        try {
                          final packets =
                              submittedPackets ?? <Map<String, dynamic>>[];
                          if (!submitted) {
                            for (final tag in selected) {
                              final index = localSheetIndexForOculumTag(tag);
                              if (index < 0 ||
                                  readBoolValue(
                                    schedePersonaggio[index]['realtimeSharedSheet'],
                                  )) {
                                throw StateError(
                                  'La selezione è cambiata. Riapri l’assegnazione.',
                                );
                              }
                              packets.add({
                                'sheetTag': tag,
                                'sheetName': nomeSchedaPersonaggio(index),
                                'sheet': sheetAssignmentBody(index),
                              });
                            }
                          }
                          if (realtimeService != service ||
                              !realtimeIsMasterRole) {
                            throw StateError(
                              'La connessione o il ruolo Master sono cambiati.',
                            );
                          }
                          submittedPackets = packets;
                          submitted = true;
                          if (!registered) {
                            await service.assignSheetsToPlayer(
                              transferId: transferId,
                              targetUserId: recipient!,
                              campaignId: activeCampaignId,
                              campaignName: activeCampaignName(),
                              sheets: packets,
                            );
                          }
                          registered = true;
                          await syncSheetAssignments();
                          final moved = selected.every((tag) {
                            final index = localSheetIndexForOculumTag(tag);
                            return index >= 0 &&
                                readBoolValue(
                                  schedePersonaggio[index]['realtimeSharedSheet'],
                                );
                          });
                          if (dialog.mounted) {
                            if (moved) {
                              Navigator.pop(dialog);
                            } else {
                              update(
                                () => errorText =
                                    'Assegnazione registrata. Completa la sincronizzazione per salvarla su questo dispositivo.',
                              );
                            }
                          }
                        } catch (error) {
                          aggiungiLog('[ASSEGNAZIONE] $error');
                          if (dialog.mounted) {
                            update(
                              () => errorText =
                                  'Trasferimento non confermato. Riprova o usa Sincronizza assegnazioni.',
                            );
                          }
                        } finally {
                          if (dialog.mounted) update(() => sending = false);
                        }
                      },
                child: Text(
                  registered
                      ? 'Riprova sincronizzazione'
                      : submitted
                      ? 'Riprova assegnazione'
                      : 'Assegna ${selected.length} schede',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
