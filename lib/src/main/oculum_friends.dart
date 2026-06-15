part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member, unused_element

extension _OculumFriends on _OculumHomePageState {
  String sanitizeOculumUsername(String value) {
    final compact = value
        .trim()
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '');
    return compact.isEmpty ? 'OculumPlayer' : compact;
  }

  String bestSheetNameForUsername() {
    var bestIndex = schedaCorrente;
    var bestScore = -1;

    for (int i = 0; i < schedePersonaggio.length; i++) {
      final score =
          sheetIntValueAt(i, 'resilienza') +
          sheetIntValueAt(i, 'volonta') +
          sheetIntValueAt(i, 'materia') +
          sheetIntValueAt(i, 'oculum');
      if (score > bestScore) {
        bestScore = score;
        bestIndex = i;
      }
    }

    final name = nomeSchedaPersonaggio(bestIndex).trim();
    return name.isEmpty || name == '???' ? 'OculumPlayer' : name;
  }

  String effectiveOculumUsername() {
    final custom = oculumUsernameController.text.trim();
    return sanitizeOculumUsername(
      custom.isEmpty ? bestSheetNameForUsername() : custom,
    );
  }

  String normalizeOculumFriendTag(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), '');
  }

  bool isLegacyOculumTag(String tag) {
    return RegExp(r'^\d{3}-[A-Z0-9]{4,}$', caseSensitive: false).hasMatch(tag);
  }

  bool isNamedOculumTag(String tag) {
    return RegExp(
      r'^[A-Z0-9_-]{2,24}OCU:([0-9]{3,}|3690)[A-Z0-9]{2,}$',
      caseSensitive: false,
    ).hasMatch(tag);
  }

  bool isValidOculumFriendTag(String tag) {
    final clean = normalizeOculumFriendTag(tag);
    return isLegacyOculumTag(clean) || isNamedOculumTag(clean);
  }

  String randomOculumTagSuffix(int length) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }

  String tagPrefixForSheetIndex(int index) {
    if (index < 3) return '${effectiveOculumUsername()}Ocu:3690';

    final prefixNumber = 410 + (index % 470);
    final safePrefix = prefixNumber == 369 ? 410 : prefixNumber;
    return '${effectiveOculumUsername()}Ocu:$safePrefix';
  }

  String generaTagUnicoScheda(int index, Set<String> usati) {
    final prefix = tagPrefixForSheetIndex(index);

    for (int attempt = 0; attempt < 10000; attempt++) {
      final tag = '$prefix${randomOculumTagSuffix(index < 3 ? 4 : 5)}';
      if (!usati.contains(tag.toUpperCase())) return tag;
    }

    var fallback = 1;
    while (true) {
      final tag = '$prefix${fallback.toString().padLeft(4, '0')}';
      if (!usati.contains(tag.toUpperCase())) return tag;
      fallback++;
    }
  }

  bool shouldReplaceSheetTag(String tag, int index, Set<String> used) {
    final clean = normalizeOculumFriendTag(tag);
    if (clean.isEmpty) return true;
    if (used.contains(clean.toUpperCase())) return true;
    if (isLegacyOculumTag(clean)) return false;
    if (!isNamedOculumTag(clean)) return true;

    final firstPrefix = RegExp(
      r':3690[A-Z0-9]{2,}$',
      caseSensitive: false,
    ).hasMatch(clean);
    return index < 3 ? !firstPrefix : firstPrefix;
  }

  bool assicuraAmiciOculum() {
    var changed = false;
    final used = <String>{};

    for (int i = amiciOculum.length - 1; i >= 0; i--) {
      final friend = amiciOculum[i];
      final tag = normalizeOculumFriendTag('${friend['tag'] ?? ''}');
      if (!isValidOculumFriendTag(tag) || used.contains(tag.toUpperCase())) {
        amiciOculum.removeAt(i);
        changed = true;
        continue;
      }

      friend['tag'] = tag;
      friend['name'] = '${friend['name'] ?? ''}'.trim();
      used.add(tag.toUpperCase());
    }

    return changed;
  }

  List<String> localOculumTags() {
    assicuraTagSchede();
    return schedePersonaggio
        .map((sheet) => normalizeOculumFriendTag('${sheet['sheetTag'] ?? ''}'))
        .where((tag) => tag.isNotEmpty)
        .toList();
  }

  bool isOculumFriendBlocked(String tag) {
    final clean = normalizeOculumFriendTag(tag).toUpperCase();
    return blockedOculumFriends.any(
      (friend) =>
          normalizeOculumFriendTag('${friend['tag'] ?? ''}').toUpperCase() ==
          clean,
    );
  }

  bool isOculumFriendSaved(String tag) {
    final clean = normalizeOculumFriendTag(tag).toUpperCase();
    return amiciOculum.any(
      (friend) =>
          normalizeOculumFriendTag('${friend['tag'] ?? ''}').toUpperCase() ==
          clean,
    );
  }

  void addOrUpdateOculumFriendByTag({
    required String tag,
    required String name,
  }) {
    final clean = normalizeOculumFriendTag(tag);
    if (!isValidOculumFriendTag(clean)) return;

    final existingIndex = amiciOculum.indexWhere(
      (x) =>
          normalizeOculumFriendTag('${x['tag'] ?? ''}').toUpperCase() ==
          clean.toUpperCase(),
    );
    final friend = <String, dynamic>{
      'tag': clean,
      'name': name.trim(),
      'addedAt': DateTime.now().toIso8601String(),
    };

    if (existingIndex >= 0) {
      amiciOculum[existingIndex] = friend;
    } else {
      amiciOculum.add(friend);
    }

    pendingOculumFriendRequests.removeWhere(
      (request) =>
          normalizeOculumFriendTag(
            '${request['requesterTag'] ?? ''}',
          ).toUpperCase() ==
          clean.toUpperCase(),
    );
    sentOculumFriendRequests.removeWhere(
      (request) =>
          normalizeOculumFriendTag(
            '${request['targetTag'] ?? ''}',
          ).toUpperCase() ==
          clean.toUpperCase(),
    );
  }

  void blockOculumFriendTag({required String tag, required String name}) {
    final clean = normalizeOculumFriendTag(tag);
    if (clean.isEmpty) return;

    amiciOculum.removeWhere(
      (friend) =>
          normalizeOculumFriendTag('${friend['tag'] ?? ''}').toUpperCase() ==
          clean.toUpperCase(),
    );
    pendingOculumFriendRequests.removeWhere(
      (request) =>
          normalizeOculumFriendTag(
            '${request['requesterTag'] ?? ''}',
          ).toUpperCase() ==
          clean.toUpperCase(),
    );
    sentOculumFriendRequests.removeWhere(
      (request) =>
          normalizeOculumFriendTag(
            '${request['targetTag'] ?? ''}',
          ).toUpperCase() ==
          clean.toUpperCase(),
    );

    final blocked = <String, dynamic>{
      'tag': clean,
      'name': name.trim(),
      'blockedAt': DateTime.now().toIso8601String(),
    };
    final existingIndex = blockedOculumFriends.indexWhere(
      (friend) =>
          normalizeOculumFriendTag('${friend['tag'] ?? ''}').toUpperCase() ==
          clean.toUpperCase(),
    );
    if (existingIndex >= 0) {
      blockedOculumFriends[existingIndex] = blocked;
    } else {
      blockedOculumFriends.add(blocked);
    }
  }

  void sendOculumFriendRequest() {
    final service = realtimeService;
    if (service?.isConnected != true) {
      setState(() {
        risultato = t(
          'Connettiti a Realtime Oculum per inviare una richiesta amicizia.',
          'Connect to Realtime Oculum to send a friend request.',
        );
        aggiungiLog(risultato);
      });
      return;
    }

    final targetTag = normalizeOculumFriendTag(friendTagController.text);
    if (!isValidOculumFriendTag(targetTag)) {
      setState(() {
        risultato = t(
          'Tag amico non valido per la richiesta.',
          'Invalid friend tag for request.',
        );
        aggiungiLog(risultato);
      });
      return;
    }

    if (localOculumTags()
        .map((tag) => tag.toUpperCase())
        .contains(targetTag.toUpperCase())) {
      setState(() {
        risultato = t(
          'Questo tag appartiene gia a una tua scheda.',
          'This tag already belongs to one of your sheets.',
        );
      });
      return;
    }
    if (isOculumFriendSaved(targetTag)) {
      setState(() {
        risultato = t('Siete gia amici.', 'You are already friends.');
      });
      return;
    }
    if (isOculumFriendBlocked(targetTag)) {
      setState(() {
        risultato = t(
          'Questo tag e bloccato. Sbloccalo dalle impostazioni prima di inviare una richiesta.',
          'This tag is blocked. Unblock it from settings before sending a request.',
        );
      });
      return;
    }
    final alreadyPending = sentOculumFriendRequests.any(
      (request) =>
          normalizeOculumFriendTag(
            '${request['targetTag'] ?? ''}',
          ).toUpperCase() ==
          targetTag.toUpperCase(),
    );
    if (alreadyPending) {
      setState(() {
        risultato = t(
          'Richiesta gia in attesa per $targetTag.',
          'Request already pending for $targetTag.',
        );
      });
      return;
    }

    final requesterTag = sheetTagAt(schedaCorrente);
    final requesterName = effectiveOculumUsername();
    final requestId =
        'fr_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(999999)}';
    unawaited(
      service!.sendFriendRequest(
        requestId: requestId,
        targetTag: targetTag,
        requesterTag: requesterTag,
        requesterName: requesterName,
      ),
    );

    setState(() {
      sentOculumFriendRequests.add(<String, dynamic>{
        'requestId': requestId,
        'targetTag': targetTag,
        'targetName': friendNameController.text.trim(),
        'requesterTag': requesterTag,
        'requesterName': requesterName,
        'sentAt': DateTime.now().toIso8601String(),
      });
      risultato = t(
        'Richiesta amicizia inviata a $targetTag.',
        'Friend request sent to $targetTag.',
      );
      friendTagController.clear();
      friendNameController.clear();
      aggiungiLog(risultato);
    });
    unawaited(salvaDatiSoloLocale());
  }

  bool registerIncomingOculumFriendRequest(Map<String, dynamic> payload) {
    final targetTag = normalizeOculumFriendTag('${payload['targetTag'] ?? ''}');
    final requesterTag = normalizeOculumFriendTag(
      '${payload['requesterTag'] ?? ''}',
    );
    final requesterName =
        '${payload['requesterName'] ?? payload['playerName'] ?? ''}'.trim();

    if (targetTag.isEmpty || requesterTag.isEmpty) return false;
    if (!localOculumTags()
        .map((tag) => tag.toUpperCase())
        .contains(targetTag.toUpperCase())) {
      return false;
    }
    if (isOculumFriendBlocked(requesterTag)) return false;
    if (isOculumFriendSaved(requesterTag)) return false;

    final request = <String, dynamic>{
      'requestId': '${payload['requestId'] ?? ''}',
      'requesterTag': requesterTag,
      'requesterName': requesterName.isEmpty ? requesterTag : requesterName,
      'targetTag': targetTag,
      'sentAt': '${payload['sentAt'] ?? DateTime.now().toIso8601String()}',
    };

    final existingIndex = pendingOculumFriendRequests.indexWhere(
      (item) =>
          normalizeOculumFriendTag(
            '${item['requesterTag'] ?? ''}',
          ).toUpperCase() ==
          requesterTag.toUpperCase(),
    );
    if (existingIndex >= 0) {
      pendingOculumFriendRequests[existingIndex] = request;
    } else {
      pendingOculumFriendRequests.add(request);
    }

    aggiungiLog(
      t(
        'Richiesta amicizia ricevuta da ${request['requesterName']}.',
        'Friend request received from ${request['requesterName']}.',
      ),
    );
    return true;
  }

  bool registerIncomingOculumFriendResponse(Map<String, dynamic> payload) {
    final targetTag = normalizeOculumFriendTag('${payload['targetTag'] ?? ''}');
    final responderTag = normalizeOculumFriendTag(
      '${payload['responderTag'] ?? ''}',
    );
    final responderName =
        '${payload['responderName'] ?? payload['playerName'] ?? ''}'.trim();
    final status = '${payload['status'] ?? ''}'.trim().toLowerCase();

    if (targetTag.isEmpty || responderTag.isEmpty) return false;
    if (!localOculumTags()
        .map((tag) => tag.toUpperCase())
        .contains(targetTag.toUpperCase())) {
      return false;
    }

    if (status == 'accepted' && !isOculumFriendBlocked(responderTag)) {
      sentOculumFriendRequests.removeWhere(
        (request) =>
            '${request['requestId'] ?? ''}' ==
                '${payload['requestId'] ?? ''}' ||
            normalizeOculumFriendTag(
                  '${request['targetTag'] ?? ''}',
                ).toUpperCase() ==
                responderTag.toUpperCase(),
      );
      addOrUpdateOculumFriendByTag(
        tag: responderTag,
        name: responderName.isEmpty ? responderTag : responderName,
      );
      aggiungiLog(
        t(
          '${responderName.isEmpty ? responderTag : responderName} ha accettato la richiesta amicizia.',
          '${responderName.isEmpty ? responderTag : responderName} accepted the friend request.',
        ),
      );
      return true;
    }

    if (status == 'blocked') {
      sentOculumFriendRequests.removeWhere(
        (request) =>
            '${request['requestId'] ?? ''}' ==
                '${payload['requestId'] ?? ''}' ||
            normalizeOculumFriendTag(
                  '${request['targetTag'] ?? ''}',
                ).toUpperCase() ==
                responderTag.toUpperCase(),
      );
      aggiungiLog(
        t(
          '${responderName.isEmpty ? responderTag : responderName} ha bloccato la richiesta amicizia.',
          '${responderName.isEmpty ? responderTag : responderName} blocked the friend request.',
        ),
      );
      return true;
    }

    if (status == 'rejected') {
      sentOculumFriendRequests.removeWhere(
        (request) =>
            '${request['requestId'] ?? ''}' ==
                '${payload['requestId'] ?? ''}' ||
            normalizeOculumFriendTag(
                  '${request['targetTag'] ?? ''}',
                ).toUpperCase() ==
                responderTag.toUpperCase(),
      );
      aggiungiLog(
        t(
          '${responderName.isEmpty ? responderTag : responderName} ha rifiutato la richiesta amicizia.',
          '${responderName.isEmpty ? responderTag : responderName} rejected the friend request.',
        ),
      );
      return true;
    }

    if (status == 'cancelled') {
      pendingOculumFriendRequests.removeWhere(
        (request) =>
            '${request['requestId'] ?? ''}' ==
                '${payload['requestId'] ?? ''}' ||
            normalizeOculumFriendTag(
                  '${request['requesterTag'] ?? ''}',
                ).toUpperCase() ==
                responderTag.toUpperCase(),
      );
      aggiungiLog(
        t(
          '${responderName.isEmpty ? responderTag : responderName} ha annullato la richiesta amicizia.',
          '${responderName.isEmpty ? responderTag : responderName} cancelled the friend request.',
        ),
      );
      return true;
    }

    return false;
  }

  Future<void> acceptOculumFriendRequest(int index) async {
    if (index < 0 || index >= pendingOculumFriendRequests.length) return;

    final request = pendingOculumFriendRequests[index];
    final requesterTag = normalizeOculumFriendTag(
      '${request['requesterTag'] ?? ''}',
    );
    final requesterName = '${request['requesterName'] ?? requesterTag}';
    final responderTag = sheetTagAt(schedaCorrente);
    final responderName = effectiveOculumUsername();
    final requestId = '${request['requestId'] ?? ''}';

    setState(() {
      addOrUpdateOculumFriendByTag(tag: requesterTag, name: requesterName);
      pendingOculumFriendRequests.removeAt(index);
      risultato = t(
        'Richiesta amicizia accettata: $requesterName.',
        'Friend request accepted: $requesterName.',
      );
      aggiungiLog(risultato);
    });

    final service = realtimeService;
    if (service?.isConnected == true) {
      unawaited(
        service!.sendFriendResponse(
          requestId: requestId,
          targetTag: requesterTag,
          responderTag: responderTag,
          responderName: responderName,
          status: 'accepted',
        ),
      );
    }
    await salvaDatiSoloLocale();
  }

  Future<void> rejectOculumFriendRequest(
    int index, {
    bool block = false,
  }) async {
    if (index < 0 || index >= pendingOculumFriendRequests.length) return;

    final request = pendingOculumFriendRequests[index];
    final requesterTag = normalizeOculumFriendTag(
      '${request['requesterTag'] ?? ''}',
    );
    final requesterName = '${request['requesterName'] ?? requesterTag}';
    final responderTag = sheetTagAt(schedaCorrente);
    final responderName = effectiveOculumUsername();
    final requestId = '${request['requestId'] ?? ''}';

    setState(() {
      pendingOculumFriendRequests.removeAt(index);
      if (block) {
        blockOculumFriendTag(tag: requesterTag, name: requesterName);
      }
      risultato = block
          ? t(
              '$requesterName bloccato. Puoi sbloccarlo dalle impostazioni.',
              '$requesterName blocked. You can unblock them in settings.',
            )
          : t(
              'Richiesta amicizia rifiutata: $requesterName.',
              'Friend request rejected: $requesterName.',
            );
      aggiungiLog(risultato);
    });

    final service = realtimeService;
    if (service?.isConnected == true) {
      unawaited(
        service!.sendFriendResponse(
          requestId: requestId,
          targetTag: requesterTag,
          responderTag: responderTag,
          responderName: responderName,
          status: block ? 'blocked' : 'rejected',
        ),
      );
    }
    await salvaDatiSoloLocale();
  }

  Future<void> cancelSentOculumFriendRequest(int index) async {
    if (index < 0 || index >= sentOculumFriendRequests.length) return;

    final request = sentOculumFriendRequests[index];
    final targetTag = normalizeOculumFriendTag('${request['targetTag'] ?? ''}');
    final requesterTag = normalizeOculumFriendTag(
      '${request['requesterTag'] ?? sheetTagAt(schedaCorrente)}',
    );
    final requesterName =
        '${request['requesterName'] ?? effectiveOculumUsername()}';
    final requestId = '${request['requestId'] ?? ''}';

    setState(() {
      sentOculumFriendRequests.removeAt(index);
      risultato = t(
        'Richiesta amicizia annullata.',
        'Friend request cancelled.',
      );
      aggiungiLog(risultato);
    });

    final service = realtimeService;
    if (service?.isConnected == true && targetTag.isNotEmpty) {
      unawaited(
        service!.sendFriendResponse(
          requestId: requestId,
          targetTag: targetTag,
          responderTag: requesterTag,
          responderName: requesterName,
          status: 'cancelled',
        ),
      );
    }
    await salvaDatiSoloLocale();
  }

  Future<void> unblockOculumFriend(int index) async {
    if (index < 0 || index >= blockedOculumFriends.length) return;

    setState(() {
      final friend = blockedOculumFriends.removeAt(index);
      risultato = t(
        'Sbloccato: ${friend['name'] ?? friend['tag']}.',
        'Unblocked: ${friend['name'] ?? friend['tag']}.',
      );
      aggiungiLog(risultato);
    });

    await salvaDatiSoloLocale();
  }

  void addOculumFriend() {
    final tag = normalizeOculumFriendTag(friendTagController.text);
    final name = friendNameController.text.trim();

    if (!isValidOculumFriendTag(tag)) {
      setState(() {
        risultato = t(
          'Tag amico non valido. Usa NomeUtenteOcu:3690AB o il vecchio formato 369-000000.',
          'Invalid friend tag. Use NameOcu:3690AB or the old 369-000000 format.',
        );
        aggiungiLog(risultato);
      });
      return;
    }

    final existingIndex = amiciOculum.indexWhere(
      (x) => '${x['tag'] ?? ''}'.toUpperCase() == tag.toUpperCase(),
    );

    setState(() {
      final friend = <String, dynamic>{
        'tag': tag,
        'name': name,
        'addedAt': DateTime.now().toIso8601String(),
      };

      if (existingIndex >= 0) {
        amiciOculum[existingIndex] = friend;
        risultato = t('Amico aggiornato.', 'Friend updated.');
      } else {
        amiciOculum.add(friend);
        risultato = t('Amico aggiunto.', 'Friend added.');
      }

      friendTagController.clear();
      friendNameController.clear();
      aggiungiLog(risultato);
    });

    salvaDatiSoloLocale();
  }

  void removeOculumFriend(int index) {
    if (index < 0 || index >= amiciOculum.length) return;

    setState(() {
      final removed = amiciOculum.removeAt(index);
      risultato = t(
        'Amico rimosso: ${removed['name'] ?? removed['tag']}.',
        'Friend removed: ${removed['name'] ?? removed['tag']}.',
      );
      aggiungiLog(risultato);
    });

    salvaDatiSoloLocale();
  }

  void prepareOculumFriendEdit(Map<String, dynamic> friend) {
    setState(() {
      friendTagController.text = normalizeOculumFriendTag(
        '${friend['tag'] ?? ''}',
      );
      friendNameController.text = '${friend['name'] ?? ''}'.trim();
      risultato = t(
        'Amico caricato nei campi rapidi.',
        'Friend loaded into quick fields.',
      );
    });
  }

  Future<void> copyOculumFriendTag(Map<String, dynamic> friend) async {
    final tag = normalizeOculumFriendTag('${friend['tag'] ?? ''}');
    if (tag.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: tag));
    if (!mounted) return;
    setState(() {
      risultato = t('Tag copiato: $tag.', 'Copied tag: $tag.');
      aggiungiLog(risultato);
    });
  }

  Future<void> blockSavedOculumFriend(int index) async {
    if (index < 0 || index >= amiciOculum.length) return;

    setState(() {
      final friend = amiciOculum[index];
      final tag = normalizeOculumFriendTag('${friend['tag'] ?? ''}');
      final name = '${friend['name'] ?? tag}'.trim();
      blockOculumFriendTag(tag: tag, name: name);
      risultato = t(
        'Amico bloccato: ${name.isEmpty ? tag : name}.',
        'Friend blocked: ${name.isEmpty ? tag : name}.',
      );
      aggiungiLog(risultato);
    });

    await salvaDatiSoloLocale();
  }

  List<String> currentSheetRevokedAccessTags() {
    return sheetRevokedAccessTagsAt(schedaCorrente);
  }

  List<String> sheetRevokedAccessTagsAt(int index) {
    if (index < 0 || index >= schedePersonaggio.length) {
      return <String>[];
    }

    final raw = schedePersonaggio[index]['realtimeRevokedAccessTags'];
    return (raw is List ? raw : const [])
        .map((tag) => normalizeOculumFriendTag('$tag'))
        .where((tag) => tag.isNotEmpty)
        .toSet()
        .toList();
  }

  bool currentSheetAccessRevokedForTag(String tag) {
    return sheetAccessRevokedForTagAt(schedaCorrente, tag);
  }

  bool sheetAccessRevokedForTagAt(int index, String tag) {
    final normalized = normalizeOculumFriendTag(tag).toUpperCase();
    if (normalized.isEmpty) return false;
    return sheetRevokedAccessTagsAt(
      index,
    ).any((item) => item.toUpperCase() == normalized);
  }

  void setCurrentSheetAccessRevokedForFriend(
    Map<String, dynamic> friend,
    bool revoked,
  ) {
    if (schedaCorrente < 0 || schedaCorrente >= schedePersonaggio.length) {
      return;
    }

    final tag = normalizeOculumFriendTag('${friend['tag'] ?? ''}');
    if (tag.isEmpty) return;
    final name = '${friend['name'] ?? tag}'.trim();

    setState(() {
      final tags = currentSheetRevokedAccessTags()
          .where((item) => item.toUpperCase() != tag.toUpperCase())
          .toList();
      if (revoked) tags.add(tag);

      schedePersonaggio[schedaCorrente]['realtimeRevokedAccessTags'] = tags;
      risultato = revoked
          ? t(
              'Permesso sulla scheda revocato a ${name.isEmpty ? tag : name}.',
              'Sheet permission revoked for ${name.isEmpty ? tag : name}.',
            )
          : t(
              'Permesso sulla scheda ripristinato per ${name.isEmpty ? tag : name}.',
              'Sheet permission restored for ${name.isEmpty ? tag : name}.',
            );
      aggiungiLog(risultato);
    });

    salvaDatiSoloLocale();
  }

  bool oculumFriendIsOnline(String tag) {
    final clean = normalizeOculumFriendTag(tag).toUpperCase();
    if (clean.isEmpty || !realtimeConnected) return false;

    for (final user in realtimeUsers) {
      final activeTag = normalizeOculumFriendTag(
        '${user['activeSheetTag'] ?? ''}',
      ).toUpperCase();
      if (activeTag == clean) return true;

      final rawTags = user['localSheetTags'];
      if (rawTags is List) {
        for (final raw in rawTags) {
          if (normalizeOculumFriendTag('$raw').toUpperCase() == clean) {
            return true;
          }
        }
      }
    }

    return false;
  }

  Future<int?> scegliSchedaDaCondividereDialog({required String title}) async {
    int? selectedIndex;
    return showDialog<int>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF10121A),
              title: Text(
                title,
                style: TextStyle(
                  color: tertiaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: DropdownButtonFormField<int>(
                initialValue: selectedIndex,
                dropdownColor: const Color(0xFF11131A),
                decoration: fieldDecoration(t('Scegli scheda', 'Choose sheet')),
                items: [
                  for (int i = 0; i < schedePersonaggio.length; i++)
                    DropdownMenuItem<int>(
                      value: i,
                      child: Text(
                        '${i + 1}. ${nomeSchedaPersonaggio(i)}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) {
                  setDialogState(() {
                    selectedIndex = value;
                  });
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(t('Annulla', 'Cancel')),
                ),
                ElevatedButton.icon(
                  onPressed: selectedIndex == null
                      ? null
                      : () => Navigator.pop(context, selectedIndex),
                  icon: const Icon(Icons.ios_share),
                  label: Text(t('Condividi', 'Share')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> shareSheetToAllOculumFriends() async {
    final index = await scegliSchedaDaCondividereDialog(
      title: t('Scheda da condividere agli amici', 'Sheet to share to friends'),
    );
    if (index == null) return;
    sendRealtimeCurrentSheetToFriendsInternal(manual: true, sheetIndex: index);
  }

  Future<void> shareSheetToOculumFriend(Map<String, dynamic> friend) async {
    final tag = normalizeOculumFriendTag('${friend['tag'] ?? ''}');
    if (tag.isEmpty ||
        isOculumFriendBlocked(tag) ||
        !realtimeConnected ||
        realtimeIsMasterRole) {
      return;
    }

    final index = await scegliSchedaDaCondividereDialog(
      title: t('Scheda da condividere', 'Sheet to share'),
    );
    if (index == null) return;
    if (sheetAccessRevokedForTagAt(index, tag)) {
      setState(() {
        risultato = t(
          'Accesso revocato per questa scheda.',
          'Access revoked for this sheet.',
        );
        aggiungiLog(risultato);
      });
      return;
    }
    if (readBoolValue(schedePersonaggio[index]['realtimeSharedSheet'])) {
      return;
    }

    final name = '${friend['name'] ?? ''}'.trim();
    sendRealtimeCurrentSheetToFriendsInternal(
      manual: true,
      sheetIndex: index,
      targetTagsOverride: <String>[tag],
      targetLabel: name.isEmpty ? tag : name,
    );
  }

  Widget pendingOculumFriendRequestsPanel() {
    if (pendingOculumFriendRequests.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t('Richieste amicizia', 'Friend requests'),
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...pendingOculumFriendRequests.asMap().entries.map((entry) {
          final index = entry.key;
          final request = entry.value;
          final name = '${request['requesterName'] ?? ''}'.trim();
          final tag = '${request['requesterTag'] ?? ''}';

          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: primaryColor.withValues(alpha: 0.45)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? tag : name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                smallInfoText(tag),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => acceptOculumFriendRequest(index),
                      icon: const Icon(Icons.check),
                      label: Text(t('Accetta', 'Accept')),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => rejectOculumFriendRequest(index),
                      icon: const Icon(Icons.close),
                      label: Text(t('Rifiuta', 'Reject')),
                    ),
                    OutlinedButton.icon(
                      onPressed: () =>
                          rejectOculumFriendRequest(index, block: true),
                      icon: const Icon(Icons.block),
                      label: Text(t('Blocca', 'Block')),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget sentOculumFriendRequestsPanel() {
    if (sentOculumFriendRequests.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t('Richieste inviate', 'Sent requests'),
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...sentOculumFriendRequests.asMap().entries.map((entry) {
          final index = entry.key;
          final request = entry.value;
          final name = '${request['targetName'] ?? ''}'.trim();
          final tag = '${request['targetTag'] ?? ''}';

          return Material(
            color: Colors.transparent,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.schedule, color: tertiaryColor),
              title: Text(
                name.isEmpty ? tag : name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                t('In attesa - $tag', 'Pending - $tag'),
                style: const TextStyle(color: Colors.grey),
              ),
              trailing: OutlinedButton.icon(
                onPressed: () => cancelSentOculumFriendRequest(index),
                icon: const Icon(Icons.close),
                label: Text(t('Annulla', 'Cancel')),
              ),
            ),
          );
        }),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget blockedOculumFriendsSettingsPanel() {
    return gothicPanel(
      borderColor: blockedOculumFriends.isEmpty ? primaryColor : tertiaryColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('Amici bloccati', 'Blocked friends'),
            style: TextStyle(
              color: tertiaryColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          smallInfoText(
            t(
              'Qui puoi sbloccare i tag che hai bloccato dalle richieste amicizia.',
              'Here you can unblock tags blocked from friend requests.',
            ),
          ),
          const SizedBox(height: 10),
          if (blockedOculumFriends.isEmpty)
            smallInfoText(t('Nessun tag bloccato.', 'No blocked tag.'))
          else
            ...blockedOculumFriends.asMap().entries.map((entry) {
              final index = entry.key;
              final friend = entry.value;
              final name = '${friend['name'] ?? ''}'.trim();
              final tag = '${friend['tag'] ?? ''}';

              return Material(
                color: Colors.transparent,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    name.isEmpty ? tag : name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    tag,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  trailing: OutlinedButton.icon(
                    onPressed: () => unblockOculumFriend(index),
                    icon: const Icon(Icons.lock_open),
                    label: Text(t('Sblocca', 'Unblock')),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget oculumFriendsPanel() {
    final myTag = sheetTagAt(schedaCorrente);

    return gothicPanel(
      borderColor: tertiaryColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('Amici Oculum', 'Oculum Friends'),
            style: TextStyle(
              color: tertiaryColor,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          smallInfoText(
            t(
              'Il nome utente è modificabile. Se resta vuoto usa il nome del tuo personaggio con le stats più alte. La rubrica resta locale.',
              'The username is editable. If left empty, it uses the name of your character with the highest stats. The friend list stays local.',
            ),
          ),
          const SizedBox(height: 12),
          campoTesto(
            label: t('Nome utente Oculum', 'Oculum username'),
            controller: oculumUsernameController,
            numero: false,
            helper: t(
              'Attuale: ${effectiveOculumUsername()}',
              'Current: ${effectiveOculumUsername()}',
            ),
          ),
          const SizedBox(height: 10),
          SelectableText(
            t('Il tuo tag: $myTag', 'Your tag: $myTag'),
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          pendingOculumFriendRequestsPanel(),
          sentOculumFriendRequestsPanel(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: campoTesto(
                  label: t('Tag amico', 'Friend tag'),
                  controller: friendTagController,
                  numero: false,
                  helper: 'NomeUtenteOcu:3690AB',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: campoTesto(
                  label: t('Nome amico', 'Friend name'),
                  controller: friendNameController,
                  numero: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: addOculumFriend,
                icon: const Icon(Icons.person_add),
                label: Text(t('Aggiungi manualmente', 'Add manually')),
              ),
              ElevatedButton.icon(
                onPressed: realtimeConnected ? sendOculumFriendRequest : null,
                icon: const Icon(Icons.send),
                label: Text(t('Invia richiesta', 'Send request')),
              ),
              ElevatedButton.icon(
                onPressed:
                    realtimeConnected &&
                        amiciOculum.isNotEmpty &&
                        !realtimeIsMasterRole
                    ? shareSheetToAllOculumFriends
                    : null,
                icon: const Icon(Icons.ios_share),
                label: Text(
                  t('Condividi ai tuoi staff amici', 'Share to friend staff'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (amiciOculum.isEmpty)
            smallInfoText(t('Nessun amico salvato.', 'No saved friends.'))
          else
            ...amiciOculum.asMap().entries.map((entry) {
              final index = entry.key;
              final friend = entry.value;
              final name = '${friend['name'] ?? ''}'.trim();
              final tag = '${friend['tag'] ?? ''}';
              final isOnline = oculumFriendIsOnline(tag);

              final canShareToFriend =
                  realtimeConnected &&
                  !realtimeIsMasterRole &&
                  !isOculumFriendBlocked(tag) &&
                  schedePersonaggio.any(
                    (sheet) => !readBoolValue(sheet['realtimeSharedSheet']),
                  );
              final accessRevoked = currentSheetAccessRevokedForTag(tag);
              Widget friendAction({
                required String tooltip,
                required IconData icon,
                required VoidCallback? onPressed,
                Color? color,
              }) {
                final activeColor = color ?? primaryColor;
                final enabled = onPressed != null;
                return SizedBox.square(
                  dimension: 40,
                  child: IconButton(
                    tooltip: tooltip,
                    onPressed: onPressed,
                    style: IconButton.styleFrom(
                      backgroundColor: enabled
                          ? activeColor.withValues(alpha: 0.14)
                          : Colors.black26,
                      side: BorderSide(
                        color: enabled
                            ? activeColor.withValues(alpha: 0.55)
                            : Colors.grey.shade800,
                      ),
                    ),
                    icon: Icon(
                      icon,
                      size: 20,
                      color: enabled ? activeColor : Colors.grey.shade600,
                    ),
                  ),
                );
              }

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.38),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name.isEmpty ? tag : name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: (isOnline ? Colors.greenAccent : Colors.grey)
                                .withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: isOnline
                                  ? Colors.greenAccent
                                  : Colors.grey.shade600,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.circle,
                                size: 8,
                                color: isOnline
                                    ? Colors.greenAccent
                                    : Colors.grey.shade500,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isOnline
                                    ? t('Online', 'Online')
                                    : t('Offline', 'Offline'),
                                style: TextStyle(
                                  color: isOnline
                                      ? Colors.greenAccent
                                      : Colors.grey.shade400,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      tag,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        friendAction(
                          tooltip: t('Copia tag', 'Copy tag'),
                          icon: Icons.copy,
                          onPressed: () => copyOculumFriendTag(friend),
                        ),
                        friendAction(
                          tooltip: t('Modifica amico', 'Edit friend'),
                          icon: Icons.edit,
                          onPressed: () => prepareOculumFriendEdit(friend),
                        ),
                        friendAction(
                          tooltip: t('Condividi scheda', 'Share sheet'),
                          icon: Icons.ios_share,
                          onPressed: canShareToFriend
                              ? () => shareSheetToOculumFriend(friend)
                              : null,
                          color: tertiaryColor,
                        ),
                        friendAction(
                          tooltip: accessRevoked
                              ? t('Riabilita scheda', 'Restore sheet')
                              : t('Revoca scheda', 'Revoke sheet'),
                          icon: accessRevoked
                              ? Icons.lock_open
                              : Icons.lock_outline,
                          onPressed: () =>
                              setCurrentSheetAccessRevokedForFriend(
                                friend,
                                !accessRevoked,
                              ),
                          color: accessRevoked
                              ? Colors.greenAccent
                              : Colors.orangeAccent,
                        ),
                        friendAction(
                          tooltip: t('Blocca amico', 'Block friend'),
                          icon: Icons.block,
                          onPressed: () => blockSavedOculumFriend(index),
                          color: Colors.deepOrangeAccent,
                        ),
                        friendAction(
                          tooltip: t('Rimuovi', 'Remove'),
                          icon: Icons.delete,
                          onPressed: () => removeOculumFriend(index),
                          color: Colors.redAccent,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
