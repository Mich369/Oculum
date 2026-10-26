part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

extension _OculumPowerScanner on _OculumHomePageState {
  int scoutTotalPowerAt(int index) => oculumScoutPower(
    sheetCriticalLevelAt(index),
    index == schedaCorrente
        ? [resilienzaTotale(), volontaTotale(), materiaTotale(), oculumTotale()]
        : [
            for (final stat in ['Resilienza', 'Volonta', 'Materia', 'Oculum'])
              readIntValue(
                schedePersonaggio[index]['derived${stat}Total'],
                fallback: sheetIntValueAt(index, stat.toLowerCase()),
              ),
          ],
    grade: sheetIntValueAt(index, 'grado'),
  );

  void ensurePowerScannerOffers() {
    final level = max(0, leggiNumero(livelloController));
    for (final postea in [false, true]) {
      for (final shape in ['Amuleto', 'Bracciale', 'Cavigliera']) {
        final id =
            'power_scanner_${postea ? 'postea' : 'alchemy'}_${shape.toLowerCase()}_$level';
        if (merchantStock.any((offer) => offer['id'] == id)) continue;
        merchantStock.add({
          'id': id,
          'kind': postea ? 'postea_power_scanner' : 'power_scanner',
          'name': '$shape rilevatore${postea ? ' Postea' : ' del cielo'}',
          'scannerLevel': level,
          'cost': oculumPowerScannerPrice(level, postea: postea),
          'desc':
              '${postea ? 'Gadget cyberpunk di Postea.' : 'Legno magico e piccoli cristalli che riflettono il cielo anche quando non lo vedono.'} '
              'Legge anche altri personaggi. Stima ±10%, portata ${oculumPowerScannerLimit(level)}; oltre il limite indica «oltre la portata». '
              '${postea ? '1d23+12' : '1d9+6'} utilizzi tirati una sola volta all’acquisto. Ogni scansione consuma un utilizzo, anche oltre la portata.',
        });
      }
    }
  }

  InventoryItem powerScannerFromOffer(Map<String, dynamic> offer) {
    final postea = offer['kind'] == 'postea_power_scanner';
    final uses = oculumPowerScannerUses(Random.secure(), postea: postea);
    return InventoryItem(
      nome: '${offer['name']}',
      peso: .1,
      quantita: 1,
      note: '${offer['desc']}',
      livelloOggetto: max(0, readIntValue(offer['scannerLevel'])),
      craftData: {
        'powerScanner': true,
        'scannerUses': uses,
        'scannerCapacity': uses,
        'scannerPostea': postea,
        'manualPriceObser': merchantOfferCost(offer),
      },
    );
  }

  Future<void> usePowerScanner(InventoryItem item) async {
    if (!inventario.contains(item) || item.craftData['powerScanner'] != true) {
      return;
    }
    final remaining = readIntValue(item.craftData['scannerUses']);
    if (remaining <= 0) {
      aggiungiLog('[RILEVATORE] ${item.nome}: utilizzi esauriti.');
      return;
    }
    final origin = currentSheetScrollId();
    final online = realtimeService?.isConnected == true;
    final encounter = onlineCombatEncounterId;
    final own = sheetTagAt(schedaCorrente);
    final active = online ? onlineAttackTokens() : <Map<String, dynamic>>[];
    final targets = active.isNotEmpty
        ? active
        : <Map<String, dynamic>>[
            for (var i = 0; i < schedePersonaggio.length; i++)
              if (i != schedaCorrente)
                {'sheetTag': sheetTagAt(i), 'name': nomeSchedaPersonaggio(i)},
          ];
    final target = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialog) => SimpleDialog(
        title: Text(
          '${item.nome} · $remaining utilizzi · portata ${oculumPowerScannerLimit(item.livelloOggetto)}',
        ),
        children: [
          if (targets.where((t) => onlineCombatTokenTag(t) != own).isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Nessun altro bersaglio disponibile.'),
            ),
          for (final token in targets)
            if (onlineCombatTokenTag(token) != own)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(dialog, token),
                child: Text('${token['name'] ?? '???'}'),
              ),
        ],
      ),
    );
    if (!mounted ||
        target == null ||
        currentSheetScrollId() != origin ||
        online && encounter != onlineCombatEncounterId ||
        !inventario.contains(item) ||
        readIntValue(item.craftData['scannerUses']) <= 0) {
      return;
    }
    if (currentTurnTrackerIsActive() && !await spendCombatRollResource()) {
      return;
    }
    if (!mounted || currentSheetScrollId() != origin) return;
    final tag = onlineCombatTokenTag(target);
    setState(() {
      item.craftData = {
        ...item.craftData,
        'scannerUses': readIntValue(item.craftData['scannerUses']) - 1,
      };
    });
    programmaSalvataggio();
    final request = <String, dynamic>{
      'id': 'scanner:$own:${DateTime.now().microsecondsSinceEpoch}',
      'kind': 'power_scanner',
      'status': 'pending',
      'scope': permissionScope,
      'encounterId': encounter,
      'sourceTag': own,
      'sourceName': realtimeDisplayName(),
      'targetTag': tag,
      'targetName': '${target['name'] ?? '???'}',
      'scoutPhase': 'request',
      'scannerLevel': item.livelloOggetto,
    };
    if (online) {
      onlineCombatRequests['${request['id']}'] = request;
      await realtimeService!.sendCombatEvent(
        'combat_scout',
        permissionEnvelope(request),
      );
      aggiungiLog(
        '[RILEVATORE] Scansione inviata a ${target['name']}. Utilizzi: ${item.craftData['scannerUses']}.',
      );
    } else {
      final index = localSheetIndexForOculumTag(tag);
      if (index < 0) return;
      final result = oculumPowerScannerRead(
        scoutTotalPowerAt(index),
        item.livelloOggetto,
        Random.secure(),
      );
      aggiungiLog(
        '[RILEVATORE] ${target['name']}: ${scoutLogReading(result, 'lettura non disponibile')}. Utilizzi: ${item.craftData['scannerUses']}.',
      );
    }
  }

  void receivePowerScanner(Map<String, dynamic> payload, int targetIndex) {
    final id = '${payload['id']}';
    final target = '${payload['targetTag']}';
    final source = '${payload['sourceTag']}';
    if (payload['scoutPhase'] == 'request') {
      if (payload['senderTag'] != source ||
          targetIndex < 0 ||
          !controlsOnlineCombatSheet(target)) {
        return;
      }
      final previous = onlineCombatRequests[id];
      final reply = previous?['scoutPhase'] == 'result'
          ? previous!
          : <String, dynamic>{
              for (final key in [
                'id',
                'kind',
                'scope',
                'encounterId',
                'sourceTag',
                'targetTag',
                'targetName',
              ])
                key: payload[key],
              'status': 'resolved',
              'scoutPhase': 'result',
              ...oculumPowerScannerRead(
                scoutTotalPowerAt(targetIndex),
                readIntValue(payload['scannerLevel']).clamp(0, 10000),
                Random.secure(),
              ),
            };
      onlineCombatRequests[id] = reply;
      unawaited(
        realtimeService?.sendCombatEvent('combat_scout', {
          ...permissionEnvelope(reply),
          'senderTag': target,
        }),
      );
    } else if (payload['scoutPhase'] == 'result' &&
        payload['senderTag'] == target &&
        controlsOnlineCombatSheet(source)) {
      final request = onlineCombatRequests[id];
      if (request == null ||
          request['status'] != 'pending' ||
          request['kind'] != 'power_scanner' ||
          request['targetTag'] != target) {
        return;
      }
      request['status'] = 'resolved';
      aggiungiLog(
        '[RILEVATORE] ${request['targetName']}: ${scoutLogReading(payload, 'lettura non disponibile')}.',
      );
      programmaSalvataggio();
      if (mounted) setState(() {});
    }
  }
}
