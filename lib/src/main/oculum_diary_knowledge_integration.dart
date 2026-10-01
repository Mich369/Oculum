part of '../../main.dart';

extension _OculumDiaryKnowledgeIntegration on _OculumHomePageState {
  String diaryKnowledgeRoom() {
    if (realtimeService != null) return realtimeService!.normalizedRoomId;
    final room = realtimeRoomController.text.trim().replaceAll(
      RegExp(r'[^A-Za-z0-9_-]'),
      '_',
    );
    return room.isEmpty ? 'test' : room.substring(0, min(64, room.length));
  }

  String diaryKnowledgeSenderTag() => localOculumTags().isNotEmpty
      ? localOculumTags().first
      : sheetTagAt(schedaCorrente);

  List<Map<String, String>> diaryKnowledgeRecipients() {
    final own = localOculumTags().map((tag) => tag.toUpperCase()).toSet();
    final recipients = <String, String>{};
    for (final sheet in schedePersonaggio) {
      if (sheet['realtimeSharedSheet'] != true) continue;
      final tag =
          '${sheet['realtimeOwnerTag'] ?? sheet['realtimeSourceSheetTag'] ?? ''}'
              .trim();
      if (tag.isNotEmpty && !own.contains(tag.toUpperCase())) {
        recipients[tag] =
            '${sheet['realtimeOwnerName'] ?? sheet['nome'] ?? tag}';
      }
    }
    for (final user in realtimeUsers) {
      if (user['role'] == 'master') continue;
      final tag = '${user['activeSheetTag'] ?? ''}'.trim();
      if (tag.isNotEmpty && !own.contains(tag.toUpperCase())) {
        recipients[tag] = '${user['playerName'] ?? tag}';
      }
    }
    return [
      for (final entry in recipients.entries)
        {'tag': entry.key, 'name': entry.value},
    ];
  }

  String? diaryKnowledgeTrustedKey(String tag, {bool masterOnly = false}) {
    for (final user in realtimeUsers) {
      if (masterOnly && user['role'] != 'master') continue;
      final tags = [
        user['knowledgeSenderTag'],
        user['activeSheetTag'],
        if (user['localSheetTags'] is List) ...user['localSheetTags'] as List,
      ];
      if (!tags.any(
        (candidate) => '$candidate'.toUpperCase() == tag.toUpperCase(),
      )) {
        continue;
      }
      final key = user['knowledgePublicKey'];
      if (key is String && key.length <= 128) return key;
    }
    return null;
  }

  Future<void> chooseDiaryKnowledgeRecipients(DiaryEntity entity) async {
    if (!realtimeIsMasterRole && !modalitaMaster && !isMasterHost) return;
    final members = diaryKnowledgeRecipients();
    final selected = <String>{};
    var includeRole = true, includeName = false;
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, refresh) => AlertDialog(
          title: Text('Condividi ${entity.name}'),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Le correzioni restano private finché scegli di condividerle. I destinatari ricevono solo i campi selezionati.',
                  ),
                  CheckboxListTile(
                    value: includeRole,
                    onChanged: (value) =>
                        refresh(() => includeRole = value ?? false),
                    title: Text(
                      'Ruolo: ${diaryEditableRoles[entity.kind] ?? entity.kind}',
                    ),
                  ),
                  CheckboxListTile(
                    value: includeName,
                    onChanged: (value) =>
                        refresh(() => includeName = value ?? false),
                    title: Text('Nome: ${entity.name}'),
                  ),
                  if (members.isEmpty)
                    const Text(
                      'Nessun membro con un tag disponibile. Le correzioni locali funzionano comunque.',
                    ),
                  if (members.isNotEmpty)
                    TextButton(
                      onPressed: () => refresh(
                        () => selected.addAll(
                          members.map((member) => member['tag']!),
                        ),
                      ),
                      child: const Text('Seleziona tutto il party'),
                    ),
                  for (final member in members)
                    CheckboxListTile(
                      value: selected.contains(member['tag']),
                      onChanged: (value) => refresh(() {
                        if (value == true) {
                          selected.add(member['tag']!);
                        } else {
                          selected.remove(member['tag']);
                        }
                      }),
                      title: Text(member['name']!),
                      subtitle: Text(member['tag']!),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Mantieni solo per me'),
            ),
            FilledButton(
              onPressed: selected.isEmpty || (!includeRole && !includeName)
                  ? null
                  : () => Navigator.pop(context, true),
              child: const Text('Condividi'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || approved != true) return;
    diaryKnowledgeSync.enqueue(
      room: diaryKnowledgeRoom(),
      senderTag: diaryKnowledgeSenderTag(),
      recipients: selected,
      entity: entity,
      originalName: diaryRoleLedger.originalNameOf(entity),
      role: includeRole ? entity.kind : null,
      displayName: includeName ? entity.name : null,
    );
    await forzaSalvataggioImmediato(soloLocale: true);
    await flushDiaryKnowledge();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Condivisione registrata. Le consegne non confermate restano salvate per la sincronizzazione.',
        ),
      ),
    );
  }

  Future<void> flushDiaryKnowledge() async {
    if (!mounted || diaryKnowledgeSending) return;
    if (diaryKnowledgeSync.outbox.isEmpty) {
      diaryKnowledgeRetryTimer?.cancel();
      diaryKnowledgeRetryTimer = null;
      return;
    }
    diaryKnowledgeRetryTimer ??= Timer.periodic(
      const Duration(seconds: 30),
      (_) => unawaited(flushDiaryKnowledge()),
    );
    final service = realtimeService;
    if (service?.isConnected != true || !realtimeIsMasterRole) return;
    diaryKnowledgeSending = true;
    try {
      for (final command in [...diaryKnowledgeSync.outbox]) {
        if (!mounted || realtimeService != service || !service!.isConnected) {
          break;
        }
        if (command['room'] != service.normalizedRoomId) continue;
        final key = diaryKnowledgeTrustedKey('${command['recipientTag']}');
        if (key == null) continue;
        try {
          await service.sendDiaryKnowledge(
            diaryKnowledgeSync.seal(command, key),
          );
        } catch (_) {
          /* Durable queue is retried after reconnect. */
        }
      }
    } finally {
      diaryKnowledgeSending = false;
    }
  }

  Future<void> receiveDiaryKnowledge(
    String event,
    Map<String, dynamic> envelope,
  ) async {
    if (!mounted || envelope['room'] != diaryKnowledgeRoom()) return;
    final recipient = '${envelope['recipientTag']}';
    final own = localOculumTags().map((tag) => tag.toUpperCase()).toSet();
    if (!own.contains(recipient.toUpperCase()) &&
        recipient.toUpperCase() != diaryKnowledgeSenderTag().toUpperCase()) {
      return;
    }
    final key = diaryKnowledgeTrustedKey(
      '${envelope['senderTag']}',
      masterOnly: event == 'diary_knowledge',
    );
    if (key == null) return;
    final command = diaryKnowledgeSync.open(envelope, key);
    if (command == null) return;
    if (event == 'diary_knowledge_ack') {
      if (command['kind'] != 'ack') return;
      if (diaryKnowledgeSync.acknowledge(
        '${command['id']}',
        '${command['senderTag']}',
      )) {
        await forzaSalvataggioImmediato(soloLocale: true);
      }
      return;
    }
    final accepted = diaryKnowledgeSync.accept(command);
    if (!accepted &&
        !diaryKnowledgeSync.received.any(
          (item) => item['id'] == command['id'],
        )) {
      return;
    }
    await forzaSalvataggioImmediato(soloLocale: true);
    if (!mounted) return;
    if (openedEyeMemory != null) {
      final additions = DiaryMemoryBuilder().build(
        diaryKnowledgeSync.documentsFor(
          diaryKnowledgeRoom(),
          sheetTagAt(schedaCorrente),
        ),
        openedEyeMemory!.entities.values.toList(),
      );
      for (final entry in additions.entities.entries) {
        openedEyeMemory!.entities.putIfAbsent(entry.key, () => entry.value);
      }
      final sourceIds = openedEyeMemory!.relations
          .map((relation) => relation.evidence.document.id)
          .toSet();
      openedEyeMemory!.relations.addAll(
        additions.relations.where(
          (relation) => !sourceIds.contains(relation.evidence.document.id),
        ),
      );
      diaryRoleLedger.apply(openedEyeMemory!);
      diaryKnowledgeSync.apply(
        openedEyeMemory!,
        room: diaryKnowledgeRoom(),
        recipientTag: sheetTagAt(schedaCorrente),
        personal: diaryRoleLedger,
      );
      diaryKnowledgeRevision.value++;
    }
    final ack = {
      'id': command['id'],
      'kind': 'ack',
      'room': command['room'],
      'senderTag': recipient,
      'recipientTag': command['senderTag'],
    };
    await realtimeService?.sendDiaryKnowledge(
      diaryKnowledgeSync.seal(ack, key),
      acknowledgement: true,
    );
  }
}
