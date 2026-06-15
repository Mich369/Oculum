part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member, unused_element

extension _OculumHomeCombatProgression on _OculumHomePageState {
  // DADO / TIRI
  // =====================================================

  int tiraD20() {
    return Random().nextInt(20) + 1;
  }

  int criticalDieModifier(int roll, int faces) {
    if (faces <= 1) return 0;
    final halfDie = faces ~/ 2;
    if (roll == faces) return halfDie;
    if (roll == 1) return -halfDie;
    return 0;
  }

  String signedRollPart(int value) {
    if (value > 0) return '+$value';
    return '$value';
  }

  int rollTotalWithCritical(int roll, int faces, Iterable<int> bonuses) {
    return roll +
        criticalDieModifier(roll, faces) +
        bonuses.fold(0, (a, b) => a + b);
  }

  String rollFormulaWithCritical({
    required int roll,
    required int faces,
    Iterable<int> bonuses = const <int>[],
  }) {
    final parts = <String>['$roll'];
    final critical = criticalDieModifier(roll, faces);
    if (critical != 0) parts.add(signedRollPart(critical));
    for (final bonus in bonuses) {
      if (bonus != 0) parts.add(signedRollPart(bonus));
    }
    final total = rollTotalWithCritical(roll, faces, bonuses);
    return '${parts.join()}=$total';
  }

  bool isEnemySheetAt(int index) {
    final tipo = tipoSchedaPersonaggio(index).trim().toLowerCase();
    return tipo.contains('mostro') ||
        tipo.contains('boss') ||
        tipo.contains('nemic');
  }

  String sheetSideAt(int index) {
    if (index >= 0 && index < schedePersonaggio.length) {
      final override = '${schedePersonaggio[index]['masterSideOverride'] ?? ''}'
          .trim()
          .toLowerCase();
      if (override == 'enemy' || override == 'ally' || override == 'neutral') {
        return override;
      }
    }
    return isEnemySheetAt(index) ? 'enemy' : 'ally';
  }

  Future<void> setSheetSideOverride(int index, String side) async {
    if (index < 0 || index >= schedePersonaggio.length) return;

    final normalized = side.trim().toLowerCase();
    final allowed =
        normalized == 'enemy' ||
        normalized == 'ally' ||
        normalized == 'neutral';
    final value = allowed ? normalized : '';
    final tag = sheetTagAt(index);

    salvaSchedaCorrenteInMemoria();

    setState(() {
      schedePersonaggio[index]['masterSideOverride'] = value;
      for (final token in masterInitiativeTokens) {
        if ('${token['sheetTag'] ?? token['sheetId'] ?? ''}' == tag) {
          token['side'] = sheetSideAt(index);
        }
      }
      risultato = value.isEmpty
          ? t(
              'Lato token automatico per ${nomeSchedaPersonaggio(index)}.',
              'Automatic token side for ${nomeSchedaPersonaggio(index)}.',
            )
          : t(
              '${nomeSchedaPersonaggio(index)} segnato come ${masterInitiativeSideLabel(value)}.',
              '${nomeSchedaPersonaggio(index)} marked as ${masterInitiativeSideLabel(value)}.',
            );
      aggiungiLog(risultato);
    });

    await salvaDati();
    if (sheetInMasterPartyAt(index)) {
      sendRealtimeSharedSheetAt(index);
    }
    sendRealtimeInitiativeSnapshotIfPublished();
  }

  String sheetImageBase64At(int index) {
    if (index == schedaCorrente && immaginePersonaggio != null) {
      return base64Encode(immaginePersonaggio!);
    }

    if (index < 0 || index >= schedePersonaggio.length) return '';
    return '${schedePersonaggio[index]['immaginePersonaggioBase64'] ?? ''}';
  }

  bool sheetIsOwnLocalSheetAt(int index) {
    if (index < 0 || index >= schedePersonaggio.length) return false;
    return !readBoolValue(schedePersonaggio[index]['realtimeSharedSheet']);
  }

  bool canUseSharedSheetsForMasterInitiative() {
    return modalitaMaster ||
        isMasterHost ||
        sonoCoMaster ||
        realtimeCanBrowseOtherSheets;
  }

  bool sheetCanBeAddedToMasterInitiative(int index) {
    if (index < 0 || index >= schedePersonaggio.length) return false;
    return sheetIsOwnLocalSheetAt(index) ||
        canUseSharedSheetsForMasterInitiative();
  }

  List<int> masterInitiativeAddableLocalSheetIndexes() {
    assicuraTagSchede();
    final indexes = <int>[];
    for (int i = 0; i < schedePersonaggio.length; i++) {
      if (sheetCanBeAddedToMasterInitiative(i)) indexes.add(i);
    }
    return indexes;
  }

  int ensureRealtimeSharedSheetForInitiative(int remoteIndex) {
    if (!canUseSharedSheetsForMasterInitiative()) return -1;
    if (remoteIndex < 0 || remoteIndex >= realtimeSharedSheets.length) {
      return -1;
    }

    final record = realtimeSharedSheets[remoteIndex];
    final key = '${record['key'] ?? ''}';
    if (key.isEmpty) return -1;

    var localIndex = realtimeLocalSheetIndexForKey(key);
    if (localIndex < 0) {
      final prepared = prepareRealtimeSheetForLocal(record);
      prepared['inMasterParty'] = true;
      schedePersonaggio.add(prepared);
      localIndex = schedePersonaggio.length - 1;
    } else if (!readBoolValue(
      schedePersonaggio[localIndex]['realtimeDirtyLocal'],
    )) {
      final prepared = prepareRealtimeSheetForLocal(
        record,
        existingIndex: localIndex,
      );
      prepared['inMasterParty'] = readBoolValue(
        schedePersonaggio[localIndex]['inMasterParty'],
      );
      schedePersonaggio[localIndex] = prepared;
    }

    return localIndex;
  }

  void mostraDadoCentrale({
    required String valore,
    required bool criticoUno,
    required bool criticoVenti,
    int facce = 20,
  }) {
    dadoOverlayTimer?.cancel();
    dadoOverlayRevealTimer?.cancel();
    final reduceEffects = modalitaLeggera || modalitaVeloce || phoneCompactUi;

    setState(() {
      dadoOverlay = valore;
      dadoOverlayFacce = facce;
      if (!reduceEffects) dadoOverlaySpinSeed++;
      overlayCriticoUno = criticoUno;
      overlayCriticoVenti = criticoVenti;
      mostraOverlayDado = true;
      dadoOverlayMostraRisultato = reduceEffects;
      dadoOverlayDismissibile = false;
    });

    if (!reduceEffects) {
      dadoOverlayRevealTimer = Timer(const Duration(milliseconds: 500), () {
        if (!mounted) return;

        setState(() {
          dadoOverlayMostraRisultato = true;
        });
      });
    }

    dadoOverlayTimer = Timer(
      Duration(milliseconds: reduceEffects ? 300 : 1000),
      () {
        if (!mounted) return;

        setState(() {
          dadoOverlayDismissibile = true;
        });
      },
    );
  }

  Future<void> tiraStat(String nome, int valore) async {
    final dado = tiraD20();
    final bonus =
        valore ~/ 2 +
        bonusLivelloGrado() +
        malusFaticaTiri() +
        statRollQuickBonus(nome);
    final totale = rollTotalWithCritical(dado, 20, [bonus]);
    final testoDado = rollFormulaWithCritical(
      roll: dado,
      faces: 20,
      bonuses: [bonus],
    );

    setState(() {
      dadoMostrato = testoDado;
      dadoMostratoFacce = 20;
      tiroCriticoUno = dado == 1;
      tiroCriticoVenti = dado == 20;
      risultato = '$nome: $testoDado';

      aggiungiLog('Tiro $nome: $testoDado.');
    });

    mostraDadoCentrale(
      valore: testoDado,
      criticoUno: dado == 1,
      criticoVenti: dado == 20,
    );
    await sendRealtimeDiceRollWithMasterConsent(
      label: nome,
      roll: dado,
      bonus: bonus + criticalDieModifier(dado, 20),
      total: totale,
    );
  }

  Future<void> tiraValoreSpeciale(String nome, int bonus) async {
    final dado = tiraD20();
    final totale = rollTotalWithCritical(dado, 20, [bonus]);
    final testoDado = rollFormulaWithCritical(
      roll: dado,
      faces: 20,
      bonuses: [bonus],
    );

    setState(() {
      dadoMostrato = testoDado;
      dadoMostratoFacce = 20;
      tiroCriticoUno = dado == 1;
      tiroCriticoVenti = dado == 20;
      risultato = '$nome: $testoDado';

      aggiungiLog('Tiro $nome: $testoDado.');
    });

    mostraDadoCentrale(
      valore: testoDado,
      criticoUno: dado == 1,
      criticoVenti: dado == 20,
    );
    await sendRealtimeDiceRollWithMasterConsent(
      label: nome,
      roll: dado,
      bonus: bonus + criticalDieModifier(dado, 20),
      total: totale,
    );
  }

  Future<void> tiraAiutaCompagno() async {
    final dado = Random().nextInt(10) + 1;
    final livello = max(0, leggiNumero(livelloController));
    final grado = max(0, leggiNumero(gradoController));
    final bonus = livello + grado * 6;
    final totale = rollTotalWithCritical(dado, 10, [livello, grado * 6]);
    final testoDado = rollFormulaWithCritical(
      roll: dado,
      faces: 10,
      bonuses: [livello, grado * 6],
    );
    final label = t('Aiuta compagno', 'Help ally');

    setState(() {
      dadoMostrato = testoDado;
      dadoMostratoFacce = 10;
      tiroCriticoUno = dado == 1;
      tiroCriticoVenti = dado == 10;
      risultato =
          '$label: 1d10 + Lv $livello + Grado x6 (${grado * 6}) = $totale';
      aggiungiLog('Tiro $label: $testoDado.');
    });

    mostraDadoCentrale(
      valore: testoDado,
      criticoUno: dado == 1,
      criticoVenti: dado == 10,
      facce: 10,
    );
    await sendRealtimeDiceRollWithMasterConsent(
      label: label,
      roll: dado,
      bonus: bonus + criticalDieModifier(dado, 10),
      total: totale,
    );
  }

  int sheetIntValueAt(int index, String key, {int fallback = 0}) {
    if (index < 0 || index >= schedePersonaggio.length) return fallback;

    if (index == schedaCorrente) {
      switch (key) {
        case 'livello':
          return leggiNumero(livelloController);
        case 'grado':
          return leggiNumero(gradoController);
        case 'resilienza':
          return resilienzaTotale();
        case 'volonta':
          return volontaTotale();
        case 'materia':
          return materiaTotale();
        case 'oculum':
          return oculumTotale();
      }
    }

    final json = schedePersonaggio[index];
    final currentKey = switch (key) {
      'resilienza' => 'currentResilienza',
      'volonta' => 'currentVolonta',
      'materia' => 'currentMateria',
      'oculum' => 'currentOculum',
      _ => key,
    };

    return readIntValue(
      json[currentKey],
      fallback: readIntValue(json[key], fallback: fallback),
    );
  }

  int sheetBonusLivelloGradoAt(int index) {
    final livello = max(0, sheetIntValueAt(index, 'livello'));
    final grado = max(0, sheetIntValueAt(index, 'grado'));
    return livello + grado * 6;
  }

  int sheetAttaccoRapidoAt(int index) {
    if (index < 0 || index >= schedePersonaggio.length) return 0;
    if (index == schedaCorrente) return bonusAttaccoRapido();
    return readIntValue(schedePersonaggio[index]['attaccoRapido']);
  }

  int sheetCmRapidoAt(int index) {
    if (index < 0 || index >= schedePersonaggio.length) return 0;
    if (index == schedaCorrente) return bonusCmRapido();
    return readIntValue(schedePersonaggio[index]['cmRapido']);
  }

  int sheetReazioniAt(int index) {
    if (index < 0 || index >= schedePersonaggio.length) return 1;
    if (index == schedaCorrente) return reazioniTotali();
    final derived = readIntValue(
      schedePersonaggio[index]['derivedReazioni'],
      fallback: -1,
    );
    if (derived >= 0) return derived;
    final grado = max(0, sheetIntValueAt(index, 'grado'));
    return max(
      0,
      readIntValue(schedePersonaggio[index]['reazioni'], fallback: 1) +
          (grado ~/ 6),
    );
  }

  int sheetReazioniVelociAt(int index) {
    if (index < 0 || index >= schedePersonaggio.length) return 0;
    if (index == schedaCorrente) return reazioniVelociTotali();
    final derived = readIntValue(
      schedePersonaggio[index]['derivedReazioniVeloci'],
      fallback: -1,
    );
    if (derived >= 0) return derived;
    return max(0, readIntValue(schedePersonaggio[index]['reazioniVeloci']));
  }

  int? sheetDerivedRollBonusAt(int index, String key) {
    if (index < 0 || index >= schedePersonaggio.length) return null;
    if (index == schedaCorrente) return null;

    final field = switch (key) {
      'vc' => 'derivedVC',
      'cm' => 'derivedCM',
      'iniziativa' => 'derivedIniziativa',
      _ => '',
    };
    if (field.isEmpty || !schedePersonaggio[index].containsKey(field)) {
      return null;
    }
    return readIntValue(schedePersonaggio[index][field]);
  }

  int sheetRollBonusAt(int index, String key) {
    final derived = sheetDerivedRollBonusAt(index, key);
    if (derived != null) return derived;

    final levelGrade = sheetBonusLivelloGradoAt(index);

    switch (key) {
      case 'vc':
        return levelGrade +
            sheetIntValueAt(index, 'volonta') ~/ 3 +
            sheetAttaccoRapidoAt(index);
      case 'cm':
        return levelGrade +
            sheetIntValueAt(index, 'materia') ~/ 2 +
            sheetCmRapidoAt(index);
      case 'iniziativa':
        return levelGrade + sheetIntValueAt(index, 'materia') ~/ 5;
      default:
        return sheetIntValueAt(index, key) ~/ 2 + levelGrade;
    }
  }

  String sheetRollLabel(String key) {
    switch (key) {
      case 'resilienza':
        return t('Resilienza', 'Resilience');
      case 'volonta':
        return t('Volontà', 'Will');
      case 'materia':
        return 'Materia';
      case 'oculum':
        return 'Oculum';
      case 'iniziativa':
        return t('Iniziativa', 'Initiative');
      case 'vc':
        return 'VC';
      case 'cm':
        return 'CM';
      default:
        return key.toUpperCase();
    }
  }

  String masterInitiativeSideFromType(String type) {
    final lower = type.toLowerCase();
    if (lower.contains('boss') ||
        lower.contains('mostro') ||
        lower.contains('monster') ||
        lower.contains('nemic') ||
        lower.contains('enemy')) {
      return 'enemy';
    }
    if (lower.contains('neutral') || lower.contains('neutr')) {
      return 'neutral';
    }
    return 'ally';
  }

  String masterInitiativeSideLabel(String side) {
    switch (side) {
      case 'enemy':
        return t('Nemico', 'Enemy');
      case 'neutral':
        return t('Neutrale', 'Neutral');
      default:
        return t('Alleato', 'Ally');
    }
  }

  String masterInitiativeStatusLabel(String status) {
    switch (status) {
      case 'active':
        return t('Attivo', 'Active');
      case 'acted':
        return t('Agito', 'Acted');
      case 'skipped':
        return t('Saltato', 'Skipped');
      case 'dead':
        return t('Morto/KO', 'Dead/KO');
      default:
        return t('Da agire', 'Ready');
    }
  }

  Color masterInitiativeStatusColor(String status) {
    switch (status) {
      case 'active':
        return tertiaryColor;
      case 'acted':
        return Colors.greenAccent;
      case 'skipped':
        return Colors.orangeAccent;
      case 'dead':
        return Colors.redAccent;
      default:
        return primaryColor;
    }
  }

  bool masterInitiativeTokenIsTemporary(Map<String, dynamic> token) {
    return readBoolValue(token['temporaryTurn']) ||
        readBoolValue(token['duplicateAction']);
  }

  bool masterInitiativeTokenIsDead(Map<String, dynamic> token) {
    return '${token['status'] ?? ''}' == 'dead';
  }

  int masterInitiativeReactionMax(Map<String, dynamic> token) {
    return max(0, readIntValue(token['reactionMax'], fallback: 1));
  }

  int masterInitiativeFastReactionMax(Map<String, dynamic> token) {
    return max(0, readIntValue(token['reactionFastMax']));
  }

  String masterInitiativeTurnKey() {
    return '$masterInitiativeRound:${activeMasterInitiativeTokenId()}';
  }

  int masterInitiativeReactionUsed(Map<String, dynamic> token) {
    final maxReactions = masterInitiativeReactionMax(token);
    final legacyUsed =
        readIntValue(token['reactionUsedRound']) == masterInitiativeRound
        ? 1
        : 0;
    final used = max(readIntValue(token['reactionUsed']), legacyUsed);
    return used.clamp(0, maxReactions).toInt();
  }

  int masterInitiativeFastReactionUsedThisTurn(Map<String, dynamic> token) {
    final maxFast = masterInitiativeFastReactionMax(token);
    if ('${token['reactionFastTurnKey'] ?? ''}' != masterInitiativeTurnKey()) {
      return 0;
    }
    return readIntValue(token['reactionFastUsed']).clamp(0, maxFast).toInt();
  }

  int masterInitiativeReactionCapacity(Map<String, dynamic> token) {
    return masterInitiativeReactionMax(token) +
        masterInitiativeFastReactionMax(token);
  }

  int masterInitiativeReactionAvailable(Map<String, dynamic> token) {
    return max(
      0,
      masterInitiativeReactionMax(token) -
          masterInitiativeReactionUsed(token) +
          masterInitiativeFastReactionMax(token) -
          masterInitiativeFastReactionUsedThisTurn(token),
    );
  }

  int masterInitiativeReactionUsedTotal(Map<String, dynamic> token) {
    return masterInitiativeReactionUsed(token) +
        masterInitiativeFastReactionUsedThisTurn(token);
  }

  bool masterInitiativeReactionUsedThisRound(Map<String, dynamic> token) {
    return masterInitiativeReactionUsedTotal(token) > 0;
  }

  void restoreMasterInitiativeTokenReactions(Map<String, dynamic> token) {
    token['reactionUsed'] = 0;
    token['reactionUsedRound'] = 0;
    token['reactionFastUsed'] = 0;
    token['reactionFastTurnKey'] = masterInitiativeTurnKey();
    token.remove('reactionAt');
    token['updatedAt'] = DateTime.now().toIso8601String();
  }

  void restoreMasterInitiativeTurnResources(Map<String, dynamic> token) {
    restoreMasterInitiativeTokenReactions(token);
    token['actionUsed'] = false;
  }

  bool masterInitiativeActionUsed(Map<String, dynamic> token) {
    return readBoolValue(token['actionUsed']);
  }

  bool masterInitiativeCanToggleAction(int index) {
    if (index < 0 || index >= masterInitiativeTokens.length) return false;
    return !masterInitiativeTokenIsDead(masterInitiativeTokens[index]);
  }

  bool masterInitiativeCanUseReaction(int index) {
    if (index < 0 || index >= masterInitiativeTokens.length) return false;
    final token = masterInitiativeTokens[index];
    return !masterInitiativeTokenIsDead(token) &&
        !masterInitiativeTokenIsTemporary(token);
  }

  bool masterInitiativeCanDuplicateAction(int index) {
    if (index < 0 || index >= masterInitiativeTokens.length) return false;
    final token = masterInitiativeTokens[index];
    if (masterInitiativeTokenIsDead(token) ||
        masterInitiativeTokenIsTemporary(token)) {
      return false;
    }

    final sourceId =
        '${token['sourceTokenId'] ?? token['id'] ?? token['sheetTag'] ?? index}';
    return !masterInitiativeTokens.any((item) {
      if (!masterInitiativeTokenIsTemporary(item)) return false;
      final sameSource = '${item['sourceTokenId'] ?? ''}' == sourceId;
      final sameRound =
          readIntValue(item['expiresRound'], fallback: masterInitiativeRound) ==
          masterInitiativeRound;
      return sameSource && sameRound;
    });
  }

  void reindexMasterInitiativeTokens() {
    for (int i = 0; i < masterInitiativeTokens.length; i++) {
      masterInitiativeTokens[i]['manualOrder'] = i;
    }
  }

  int firstAliveMasterInitiativeIndex() {
    return masterInitiativeTokens.indexWhere(
      (token) => !masterInitiativeTokenIsDead(token),
    );
  }

  String activeMasterInitiativeTokenId() {
    if (masterInitiativeTokens.isEmpty) return '';
    final safeIndex = masterInitiativeActiveIndex
        .clamp(0, masterInitiativeTokens.length - 1)
        .toInt();
    return '${masterInitiativeTokens[safeIndex]['id'] ?? ''}';
  }

  void removeExpiredTemporaryInitiativeTurns({bool all = false}) {
    if (masterInitiativeTokens.isEmpty) return;

    var removedBeforeActive = 0;
    for (var i = masterInitiativeTokens.length - 1; i >= 0; i--) {
      final token = masterInitiativeTokens[i];
      final isTemporary = masterInitiativeTokenIsTemporary(token);
      final expired =
          isTemporary &&
          (all ||
              readIntValue(
                    token['expiresRound'],
                    fallback: masterInitiativeRound,
                  ) <
                  masterInitiativeRound);
      if (!expired) continue;
      if (i < masterInitiativeActiveIndex) removedBeforeActive++;
      masterInitiativeTokens.removeAt(i);
    }

    if (removedBeforeActive > 0) {
      masterInitiativeActiveIndex -= removedBeforeActive;
    }
    reindexMasterInitiativeTokens();
  }

  void normalizeMasterInitiativeTokens() {
    removeExpiredTemporaryInitiativeTurns();

    for (int i = 0; i < masterInitiativeTokens.length; i++) {
      final token = masterInitiativeTokens[i];
      token['id'] = '${token['id'] ?? token['sheetTag'] ?? 'manual_$i'}';
      token['name'] = '${token['name'] ?? '???'}';
      token['type'] = '${token['type'] ?? 'Partecipante'}';
      token['side'] =
          '${token['side'] ?? masterInitiativeSideFromType('${token['type']}')}';
      token['status'] = '${token['status'] ?? 'ready'}';
      token['notes'] = '${token['notes'] ?? ''}';
      token['initiativeRoll'] = readIntValue(token['initiativeRoll']);
      token['initiativeBase'] = readIntValue(token['initiativeBase']);
      token['initiativeTotal'] = readIntValue(token['initiativeTotal']);
      token['tieBreaker'] = readIntValue(
        token['tieBreaker'],
        fallback: Random().nextInt(1 << 31),
      );
      token['manualOrder'] = readIntValue(token['manualOrder'], fallback: i);
      final sheetTag = '${token['sheetTag'] ?? ''}';
      final sheetIndex = sheetTag.isEmpty
          ? -1
          : schedePersonaggio.indexWhere(
              (sheet) => '${sheet['sheetTag'] ?? ''}' == sheetTag,
            );
      final reactionManual = readBoolValue(token['reactionManual']);
      final reactionFastManual = readBoolValue(token['reactionFastManual']);
      token['reactionManual'] = reactionManual;
      token['reactionFastManual'] = reactionFastManual;
      token['reactionMax'] = reactionManual || sheetIndex < 0
          ? max(0, readIntValue(token['reactionMax'], fallback: 1))
          : sheetReazioniAt(sheetIndex);
      token['reactionFastMax'] = reactionFastManual || sheetIndex < 0
          ? max(0, readIntValue(token['reactionFastMax']))
          : sheetReazioniVelociAt(sheetIndex);
      final legacyUsedRound = readIntValue(token['reactionUsedRound']);
      final legacyUsed = legacyUsedRound == masterInitiativeRound ? 1 : 0;
      token['reactionUsed'] = max(
        0,
        max(readIntValue(token['reactionUsed']), legacyUsed),
      ).clamp(0, masterInitiativeReactionMax(token));
      token['reactionUsedRound'] = readIntValue(token['reactionUsed']) > 0
          ? masterInitiativeRound
          : 0;
      token['reactionFastUsed'] = max(
        0,
        readIntValue(token['reactionFastUsed']),
      ).clamp(0, masterInitiativeFastReactionMax(token));
      token['reactionFastTurnKey'] = '${token['reactionFastTurnKey'] ?? ''}';
      token['actionUsed'] = readBoolValue(token['actionUsed']);
      final isTemporary = masterInitiativeTokenIsTemporary(token);
      token['temporaryTurn'] = isTemporary;
      token['duplicateAction'] = readBoolValue(
        token['duplicateAction'],
        fallback: isTemporary,
      );
      if (isTemporary) {
        token['sourceTokenId'] =
            '${token['sourceTokenId'] ?? token['id'] ?? token['sheetTag'] ?? ''}';
        token['expiresRound'] = max(
          1,
          readIntValue(token['expiresRound'], fallback: masterInitiativeRound),
        );
      } else {
        token['temporaryTurn'] = false;
        token['duplicateAction'] = false;
      }
    }

    if (masterInitiativeTokens.isEmpty) {
      masterInitiativeActiveIndex = 0;
    } else {
      masterInitiativeActiveIndex = masterInitiativeActiveIndex
          .clamp(0, masterInitiativeTokens.length - 1)
          .toInt();
    }
  }

  void sortMasterInitiativeTokens({bool forceInitiative = false}) {
    normalizeMasterInitiativeTokens();
    if (masterInitiativeManualOrder && !forceInitiative) {
      masterInitiativeTokens.sort(
        (a, b) => readIntValue(
          a['manualOrder'],
        ).compareTo(readIntValue(b['manualOrder'])),
      );
      return;
    }

    masterInitiativeTokens.sort((a, b) {
      final totalCompare = readIntValue(
        b['initiativeTotal'],
      ).compareTo(readIntValue(a['initiativeTotal']));
      if (totalCompare != 0) return totalCompare;

      final baseCompare = readIntValue(
        b['initiativeBase'],
      ).compareTo(readIntValue(a['initiativeBase']));
      if (baseCompare != 0) return baseCompare;

      return readIntValue(
        b['tieBreaker'],
      ).compareTo(readIntValue(a['tieBreaker']));
    });

    for (int i = 0; i < masterInitiativeTokens.length; i++) {
      masterInitiativeTokens[i]['manualOrder'] = i;
    }
    masterInitiativeManualOrder = false;
  }

  void updateMasterInitiativeToken({
    required int index,
    required int roll,
    required int base,
    required int total,
  }) {
    final tag = sheetTagAt(index);
    final token = <String, dynamic>{
      'id': tag,
      'sheetTag': tag,
      'name': nomeSchedaPersonaggio(index),
      'type': tipoSchedaPersonaggio(index),
      'side': sheetSideAt(index),
      'imageBase64': sheetImageBase64At(index),
      'initiativeRoll': roll,
      'initiativeBase': base,
      'initiativeTotal': total,
      'tieBreaker': Random().nextInt(1 << 31),
      'status': 'ready',
      'notes': '',
      'reactionMax': sheetReazioniAt(index),
      'reactionFastMax': sheetReazioniVelociAt(index),
      'reactionUsed': 0,
      'reactionFastUsed': 0,
      'reactionFastTurnKey': '',
      'actionUsed': false,
      'manualOrder': masterInitiativeManualCounter++,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    final existingIndex = masterInitiativeTokens.indexWhere(
      (item) => '${item['sheetTag'] ?? ''}' == tag,
    );
    if (existingIndex >= 0) {
      final previous = masterInitiativeTokens[existingIndex];
      token['tieBreaker'] = previous['tieBreaker'];
      token['status'] = previous['status'] ?? 'ready';
      token['notes'] = previous['notes'] ?? '';
      token['manualOrder'] = previous['manualOrder'] ?? existingIndex;
      token['reactionManual'] = previous['reactionManual'] ?? false;
      token['reactionFastManual'] = previous['reactionFastManual'] ?? false;
      token['reactionMax'] = readBoolValue(previous['reactionManual'])
          ? previous['reactionMax']
          : token['reactionMax'];
      token['reactionFastMax'] = readBoolValue(previous['reactionFastManual'])
          ? previous['reactionFastMax']
          : token['reactionFastMax'];
      token['reactionUsed'] = previous['reactionUsed'] ?? 0;
      token['reactionUsedRound'] = previous['reactionUsedRound'] ?? 0;
      token['reactionFastUsed'] = previous['reactionFastUsed'] ?? 0;
      token['reactionFastTurnKey'] = previous['reactionFastTurnKey'] ?? '';
      token['reactionAt'] = previous['reactionAt'];
      token['actionUsed'] = previous['actionUsed'] ?? false;
      masterInitiativeTokens[existingIndex] = token;
    } else {
      masterInitiativeTokens.add(token);
    }

    sortMasterInitiativeTokens(forceInitiative: true);
    masterInitiativeActiveIndex = masterInitiativeTokens.isEmpty
        ? 0
        : masterInitiativeActiveIndex
              .clamp(0, masterInitiativeTokens.length - 1)
              .toInt();
  }

  void addSheetToMasterInitiative(int index, {bool rollInitiative = true}) {
    if (index < 0 || index >= schedePersonaggio.length) return;
    if (!sheetCanBeAddedToMasterInitiative(index)) {
      setState(() {
        risultato = t(
          'Puoi aggiungere solo le tue schede. Master e Co-Master possono aggiungere anche le schede online accessibili.',
          'You can add only your own sheets. Masters and Co-Masters can also add accessible online sheets.',
        );
        aggiungiLog(risultato);
      });
      return;
    }

    final roll = rollInitiative ? tiraD20() : 0;
    final base = sheetRollBonusAt(index, 'iniziativa');
    final total = rollInitiative
        ? rollTotalWithCritical(roll, 20, [base])
        : base;
    final rollText = rollInitiative
        ? rollFormulaWithCritical(roll: roll, faces: 20, bonuses: [base])
        : '';
    final name = nomeSchedaPersonaggio(index);

    setState(() {
      updateMasterInitiativeToken(
        index: index,
        roll: roll,
        base: base,
        total: total,
      );
      schedePersonaggio[index]['inMasterParty'] = true;
      risultato = rollInitiative
          ? t(
              'Scheda aggiunta in iniziativa: $name ($rollText).',
              'Sheet added to initiative: $name ($rollText).',
            )
          : t(
              'Scheda aggiunta in iniziativa: $name (base $base).',
              'Sheet added to initiative: $name (base $base).',
            );
      aggiungiLog(risultato);
    });

    programmaSalvataggio();
    sendRealtimeMasterVisibleTokenAt(index);
    sendRealtimeInitiativeSnapshotIfPublished();
  }

  void addManualMasterInitiativeToken() {
    final name = cleanUiText(masterInitiativeNameController.text).trim();
    if (name.isEmpty) return;
    final type = cleanUiText(masterInitiativeTypeController.text).trim().isEmpty
        ? t('Partecipante', 'Participant')
        : cleanUiText(masterInitiativeTypeController.text).trim();
    final bonus = readIntValue(masterInitiativeBonusController.text);
    final roll = tiraD20();
    final total = rollTotalWithCritical(roll, 20, [bonus]);

    setState(() {
      masterInitiativeTokens.add({
        'id':
            'manual_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(999999)}',
        'name': name,
        'type': type,
        'side': masterInitiativeSideFromType(type),
        'imageBase64': '',
        'initiativeRoll': roll,
        'initiativeBase': bonus,
        'initiativeTotal': total,
        'tieBreaker': Random().nextInt(1 << 31),
        'status': 'ready',
        'notes': cleanUiText(masterInitiativeNotesController.text).trim(),
        'reactionMax': 1,
        'reactionFastMax': 0,
        'reactionManual': true,
        'reactionFastManual': true,
        'reactionUsed': 0,
        'reactionUsedRound': 0,
        'reactionFastUsed': 0,
        'reactionFastTurnKey': '',
        'actionUsed': false,
        'temporaryTurn': false,
        'duplicateAction': false,
        'manualOrder': masterInitiativeManualCounter++,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      masterInitiativeNameController.clear();
      masterInitiativeNotesController.clear();
      sortMasterInitiativeTokens(forceInitiative: true);
      risultato = t(
        'Partecipante aggiunto in iniziativa: $name ($roll+$bonus=$total).',
        'Participant added to initiative: $name ($roll+$bonus=$total).',
      );
      aggiungiLog(risultato);
    });

    programmaSalvataggio();
    sendRealtimeInitiativeSnapshotIfPublished();
  }

  void rollMasterInitiativeTokens({bool npcOnly = false}) {
    if (masterInitiativeTokens.isEmpty) {
      for (final index in masterPartyIndexes()) {
        final type = tipoSchedaPersonaggio(index);
        if (npcOnly && sheetSideAt(index) == 'ally' && !type.contains('NPC')) {
          continue;
        }
        final base = sheetRollBonusAt(index, 'iniziativa');
        updateMasterInitiativeToken(
          index: index,
          roll: 0,
          base: base,
          total: base,
        );
      }
    }

    setState(() {
      normalizeMasterInitiativeTokens();
      removeExpiredTemporaryInitiativeTurns(all: true);
      var rolled = 0;
      for (final token in masterInitiativeTokens) {
        final side = '${token['side'] ?? ''}';
        final type = '${token['type'] ?? ''}'.toLowerCase();
        final isNpcOrMonster =
            side == 'enemy' || type.contains('npc') || type.contains('neutral');
        if (npcOnly && !isNpcOrMonster) continue;

        final roll = tiraD20();
        final base = readIntValue(token['initiativeBase']);
        token['initiativeRoll'] = roll;
        token['initiativeTotal'] = rollTotalWithCritical(roll, 20, [base]);
        token['status'] = 'ready';
        token['reactionUsed'] = 0;
        token['reactionUsedRound'] = 0;
        token['reactionFastUsed'] = 0;
        token['reactionFastTurnKey'] = '';
        token['actionUsed'] = false;
        token['tieBreaker'] = token['tieBreaker'] ?? Random().nextInt(1 << 31);
        token['updatedAt'] = DateTime.now().toIso8601String();
        rolled++;
      }
      sortMasterInitiativeTokens(forceInitiative: true);
      masterInitiativeRound = 1;
      masterInitiativeActiveIndex = masterInitiativeTokens.isEmpty ? 0 : 0;
      if (masterInitiativeTokens.isNotEmpty) {
        masterInitiativeTokens.first['status'] = 'active';
        restoreMasterInitiativeTurnResources(masterInitiativeTokens.first);
      }
      risultato = npcOnly
          ? t(
              'Iniziativa tirata per $rolled mostri/NPC.',
              'Initiative rolled for $rolled monsters/NPCs.',
            )
          : t(
              'Iniziativa tirata per $rolled partecipanti.',
              'Initiative rolled for $rolled participants.',
            );
      aggiungiLog(risultato);
    });

    programmaSalvataggio();
    sendRealtimeInitiativeSnapshotIfPublished();
  }

  void moveMasterInitiativeToken(int index, int delta) {
    if (index < 0 || index >= masterInitiativeTokens.length) return;
    final next = index + delta;
    if (next < 0 || next >= masterInitiativeTokens.length) return;

    setState(() {
      normalizeMasterInitiativeTokens();
      final activeId = activeMasterInitiativeTokenId();
      final item = masterInitiativeTokens.removeAt(index);
      masterInitiativeTokens.insert(next, item);
      reindexMasterInitiativeTokens();
      masterInitiativeManualOrder = true;
      final activeIndex = masterInitiativeTokens.indexWhere(
        (token) => '${token['id'] ?? ''}' == activeId,
      );
      masterInitiativeActiveIndex = activeIndex >= 0
          ? activeIndex
          : next.clamp(0, masterInitiativeTokens.length - 1).toInt();
      risultato = t(
        'Ordine iniziativa modificato.',
        'Initiative order changed.',
      );
      aggiungiLog(risultato);
    });

    programmaSalvataggio();
    sendRealtimeInitiativeSnapshotIfPublished();
  }

  void removeMasterInitiativeTokenAt(int index) {
    if (index < 0 || index >= masterInitiativeTokens.length) return;

    setState(() {
      normalizeMasterInitiativeTokens();
      if (index >= masterInitiativeTokens.length) return;

      final activeId = activeMasterInitiativeTokenId();
      final removedId = '${masterInitiativeTokens[index]['id'] ?? ''}';
      masterInitiativeTokens.removeAt(index);
      reindexMasterInitiativeTokens();

      if (masterInitiativeTokens.isEmpty) {
        masterInitiativeActiveIndex = 0;
      } else if (removedId == activeId) {
        final fallback = min(index, masterInitiativeTokens.length - 1);
        final alive = firstAliveMasterInitiativeIndex();
        masterInitiativeActiveIndex = alive >= 0 ? alive : fallback;
        for (final token in masterInitiativeTokens) {
          if ('${token['status']}' == 'active') token['status'] = 'ready';
        }
        if (!masterInitiativeTokenIsDead(
          masterInitiativeTokens[masterInitiativeActiveIndex],
        )) {
          masterInitiativeTokens[masterInitiativeActiveIndex]['status'] =
              'active';
          restoreMasterInitiativeTurnResources(
            masterInitiativeTokens[masterInitiativeActiveIndex],
          );
        }
      } else {
        final activeIndex = masterInitiativeTokens.indexWhere(
          (token) => '${token['id'] ?? ''}' == activeId,
        );
        masterInitiativeActiveIndex = activeIndex >= 0
            ? activeIndex
            : masterInitiativeActiveIndex
                  .clamp(0, masterInitiativeTokens.length - 1)
                  .toInt();
      }

      risultato = t(
        "Partecipante rimosso dall'iniziativa.",
        'Participant removed from initiative.',
      );
      aggiungiLog(risultato);
    });

    programmaSalvataggio();
    sendRealtimeInitiativeSnapshotIfPublished();
  }

  void setMasterInitiativeActiveIndex(int index) {
    if (index < 0 || index >= masterInitiativeTokens.length) return;
    setState(() {
      normalizeMasterInitiativeTokens();
      for (final token in masterInitiativeTokens) {
        if ('${token['status'] ?? ''}' == 'active') token['status'] = 'ready';
      }
      masterInitiativeActiveIndex = index;
      masterInitiativeTokens[index]['status'] = 'active';
      restoreMasterInitiativeTurnResources(masterInitiativeTokens[index]);
      risultato =
          '${t('Turno attivo', 'Active turn')}: ${masterInitiativeTokens[index]['name']}.';
      aggiungiLog(risultato);
    });
    programmaSalvataggio();
    sendRealtimeInitiativeSnapshotIfPublished();
  }

  void nextMasterInitiativeTurn({int delta = 1}) {
    if (masterInitiativeTokens.isEmpty) return;
    setState(() {
      normalizeMasterInitiativeTokens();
      if (firstAliveMasterInitiativeIndex() < 0) {
        risultato = t(
          'Nessun partecipante attivo: tutti sono KO.',
          'No active participant: everyone is KO.',
        );
        aggiungiLog(risultato);
        return;
      }
      final current = masterInitiativeActiveIndex
          .clamp(0, masterInitiativeTokens.length - 1)
          .toInt();
      if ('${masterInitiativeTokens[current]['status']}' != 'dead') {
        masterInitiativeTokens[current]['status'] = delta > 0
            ? 'acted'
            : 'ready';
      }

      var next = current;
      for (int step = 0; step < masterInitiativeTokens.length; step++) {
        next = (next + delta) % masterInitiativeTokens.length;
        if (next < 0) next += masterInitiativeTokens.length;
        if ('${masterInitiativeTokens[next]['status']}' != 'dead') break;
      }

      if (delta > 0 && next <= current) {
        masterInitiativeRound++;
        removeExpiredTemporaryInitiativeTurns();
        for (final token in masterInitiativeTokens) {
          if ('${token['status']}' != 'dead') token['status'] = 'ready';
        }
        next = 0;
        for (int step = 0; step < masterInitiativeTokens.length; step++) {
          if ('${masterInitiativeTokens[next]['status']}' != 'dead') break;
          next = (next + 1) % masterInitiativeTokens.length;
        }
      }

      if (masterInitiativeTokens.isEmpty) {
        masterInitiativeActiveIndex = 0;
        risultato = t('Iniziativa pulita.', 'Initiative cleared.');
        aggiungiLog(risultato);
        return;
      }

      masterInitiativeActiveIndex = next;
      masterInitiativeTokens[next]['status'] = 'active';
      restoreMasterInitiativeTurnResources(masterInitiativeTokens[next]);
      risultato =
          '${t('Turno', 'Turn')} $masterInitiativeRound: ${masterInitiativeTokens[next]['name']}.';
      aggiungiLog(risultato);
    });
    programmaSalvataggio();
    sendRealtimeInitiativeSnapshotIfPublished();
  }

  void resetMasterInitiativeRound({bool increment = false}) {
    setState(() {
      normalizeMasterInitiativeTokens();
      if (increment) masterInitiativeRound++;
      removeExpiredTemporaryInitiativeTurns(all: !increment);
      for (final token in masterInitiativeTokens) {
        if ('${token['status']}' != 'dead') token['status'] = 'ready';
      }
      final alive = firstAliveMasterInitiativeIndex();
      masterInitiativeActiveIndex = alive >= 0 ? alive : 0;
      if (alive >= 0) {
        masterInitiativeTokens[alive]['status'] = 'active';
        restoreMasterInitiativeTurnResources(masterInitiativeTokens[alive]);
      }
      risultato = increment
          ? t('Nuovo round iniziativa.', 'New initiative round.')
          : t('Round iniziativa resettato.', 'Initiative round reset.');
      aggiungiLog(risultato);
    });
    programmaSalvataggio();
    sendRealtimeInitiativeSnapshotIfPublished();
  }

  void toggleMasterInitiativeReaction(int index) {
    if (index < 0 || index >= masterInitiativeTokens.length) return;

    setState(() {
      normalizeMasterInitiativeTokens();
      if (index >= masterInitiativeTokens.length) return;

      final token = masterInitiativeTokens[index];
      if (!masterInitiativeCanUseReaction(index)) {
        risultato = t(
          'Questo turno non puo usare reazioni.',
          'This turn cannot use reactions.',
        );
        aggiungiLog(risultato);
        return;
      }

      final normalMax = masterInitiativeReactionMax(token);
      final normalUsed = masterInitiativeReactionUsed(token);
      final fastMax = masterInitiativeFastReactionMax(token);
      final fastUsed = masterInitiativeFastReactionUsedThisTurn(token);
      final normalAvailable = max(0, normalMax - normalUsed);
      final fastAvailable = max(0, fastMax - fastUsed);
      final available = normalAvailable + fastAvailable;

      if (available <= 0) {
        restoreMasterInitiativeTokenReactions(token);
        risultato =
            '${t('Reazioni ripristinate', 'Reactions restored')}: ${token['name']}.';
      } else if (normalAvailable > 0) {
        final nextUsed = normalUsed + 1;
        token['reactionUsed'] = nextUsed;
        token['reactionUsedRound'] = nextUsed > 0 ? masterInitiativeRound : 0;
        token['reactionAt'] = DateTime.now().toIso8601String();
        risultato =
            '${t('Reazione usata', 'Reaction used')}: ${token['name']} ($nextUsed/$normalMax).';
      } else {
        final nextFastUsed = fastUsed + 1;
        token['reactionFastUsed'] = nextFastUsed;
        token['reactionFastTurnKey'] = masterInitiativeTurnKey();
        token['reactionAt'] = DateTime.now().toIso8601String();
        risultato =
            '${t('Reazione veloce usata', 'Fast reaction used')}: ${token['name']} ($nextFastUsed/$fastMax).';
      }
      token['updatedAt'] = DateTime.now().toIso8601String();
      aggiungiLog(risultato);
    });

    programmaSalvataggio();
    sendRealtimeInitiativeSnapshotIfPublished();
  }

  void modificaMasterInitiativeReactionMax(
    int index,
    int delta, {
    bool fast = false,
  }) {
    if (index < 0 || index >= masterInitiativeTokens.length || delta == 0) {
      return;
    }

    setState(() {
      normalizeMasterInitiativeTokens();
      if (index >= masterInitiativeTokens.length) return;

      final token = masterInitiativeTokens[index];
      final key = fast ? 'reactionFastMax' : 'reactionMax';
      final manualKey = fast ? 'reactionFastManual' : 'reactionManual';
      final usedKey = fast ? 'reactionFastUsed' : 'reactionUsed';
      final current = fast
          ? masterInitiativeFastReactionMax(token)
          : masterInitiativeReactionMax(token);
      final next = max(0, current + delta);
      token[key] = next;
      token[manualKey] = true;
      token[usedKey] = readIntValue(token[usedKey]).clamp(0, next).toInt();
      if (!fast) {
        token['reactionUsedRound'] = readIntValue(token['reactionUsed']) > 0
            ? masterInitiativeRound
            : 0;
      }
      token['updatedAt'] = DateTime.now().toIso8601String();
      risultato =
          '${fast ? t('Reazioni veloci', 'Fast reactions') : t('Reazioni', 'Reactions')}: ${token['name']} $next.';
      aggiungiLog(risultato);
    });

    programmaSalvataggio();
    sendRealtimeInitiativeSnapshotIfPublished();
  }

  void toggleMasterInitiativeActionUsed(int index) {
    if (index < 0 || index >= masterInitiativeTokens.length) return;

    setState(() {
      normalizeMasterInitiativeTokens();
      if (!masterInitiativeCanToggleAction(index)) {
        risultato = t(
          'Questo partecipante non puo usare azioni.',
          'This participant cannot use actions.',
        );
        aggiungiLog(risultato);
        return;
      }
      final token = masterInitiativeTokens[index];
      final next = !masterInitiativeActionUsed(token);
      token['actionUsed'] = next;
      token['updatedAt'] = DateTime.now().toIso8601String();
      risultato = next
          ? '${t('Azione usata', 'Action used')}: ${token['name']}.'
          : '${t('Azione ripristinata', 'Action restored')}: ${token['name']}.';
      aggiungiLog(risultato);
    });

    programmaSalvataggio();
    sendRealtimeInitiativeSnapshotIfPublished();
  }

  void resetMasterInitiativeActions() {
    setState(() {
      normalizeMasterInitiativeTokens();
      for (final token in masterInitiativeTokens) {
        if (!masterInitiativeTokenIsDead(token)) {
          token['actionUsed'] = false;
          token['updatedAt'] = DateTime.now().toIso8601String();
        }
      }
      risultato = t(
        'Azioni della turnistica ripristinate.',
        'Initiative actions restored.',
      );
      aggiungiLog(risultato);
    });

    programmaSalvataggio();
    sendRealtimeInitiativeSnapshotIfPublished();
  }

  void duplicateMasterInitiativeActionNow(int index) {
    if (index < 0 || index >= masterInitiativeTokens.length) return;

    setState(() {
      normalizeMasterInitiativeTokens();
      if (index >= masterInitiativeTokens.length) return;

      if (!masterInitiativeCanDuplicateAction(index)) {
        risultato = t(
          'Azione gia duplicata per questo round o token non valido.',
          'Action already duplicated this round or invalid token.',
        );
        aggiungiLog(risultato);
        return;
      }

      final source = masterInitiativeTokens[index];
      final sourceId =
          '${source['sourceTokenId'] ?? source['id'] ?? source['sheetTag'] ?? index}';
      final active = masterInitiativeTokens.isEmpty
          ? 0
          : masterInitiativeActiveIndex
                .clamp(0, masterInitiativeTokens.length - 1)
                .toInt();
      final insertAt = min(active + 1, masterInitiativeTokens.length);
      final name = '${source['name'] ?? '???'}';

      masterInitiativeTokens.insert(insertAt, {
        'id':
            'duplicate_${sourceId}_${masterInitiativeRound}_${DateTime.now().microsecondsSinceEpoch}',
        'sourceTokenId': sourceId,
        'sheetTag': '${source['sheetTag'] ?? ''}',
        'name': '$name + ${t('azione extra', 'extra action')}',
        'type': '${source['type'] ?? t('Partecipante', 'Participant')}',
        'side': '${source['side'] ?? 'ally'}',
        'imageBase64': '${source['imageBase64'] ?? ''}',
        'initiativeRoll': source['initiativeRoll'] ?? 0,
        'initiativeBase': source['initiativeBase'] ?? 0,
        'initiativeTotal': source['initiativeTotal'] ?? 0,
        'tieBreaker': source['tieBreaker'] ?? Random().nextInt(1 << 31),
        'status': 'ready',
        'notes': t(
          'Turno extra generato per duplicare una azione nel round $masterInitiativeRound.',
          'Extra turn generated to duplicate an action in round $masterInitiativeRound.',
        ),
        'reactionMax': source['reactionMax'] ?? 0,
        'reactionFastMax': source['reactionFastMax'] ?? 0,
        'reactionUsed': 0,
        'reactionUsedRound': 0,
        'reactionFastUsed': 0,
        'reactionFastTurnKey': '',
        'actionUsed': false,
        'temporaryTurn': true,
        'duplicateAction': true,
        'expiresRound': masterInitiativeRound,
        'manualOrder': insertAt,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      reindexMasterInitiativeTokens();
      masterInitiativeManualOrder = true;
      risultato =
          '${t('Azione duplicata', 'Action duplicated')}: $name, ${t('subito dopo il turno attivo', 'right after the active turn')}.';
      aggiungiLog(risultato);
    });

    programmaSalvataggio();
    sendRealtimeInitiativeSnapshotIfPublished();
  }

  void clearMasterInitiativeTokens() {
    setState(() {
      masterInitiativeTokens.clear();
      masterInitiativeRound = 1;
      masterInitiativeActiveIndex = 0;
      masterInitiativeManualOrder = false;
      risultato = t('Iniziativa pulita.', 'Initiative cleared.');
      aggiungiLog(risultato);
    });
    programmaSalvataggio();
    sendRealtimeInitiativeSnapshotIfPublished();
  }

  Future<bool> confirmMasterPublicDiceRoll() async {
    if (!(modalitaMaster || isMasterHost)) return true;
    if (!masterPublicDiceVisible) return false;
    if (!masterAskPublicDiceConfirmation) return true;
    if (!mounted) return false;

    final choice = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF10121A),
          title: Text(
            t('Dadi visibili a tutti?', 'Dice visible to everyone?'),
            style: TextStyle(color: tertiaryColor, fontWeight: FontWeight.bold),
          ),
          content: Text(
            t(
              'Sei sicuro che vuoi che tutti vedano i dadi?',
              'Are you sure you want everyone to see the dice?',
            ),
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'no'),
              child: Text(t('No', 'No')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'yes'),
              child: Text(t('Si', 'Yes')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, 'never'),
              child: Text(t('Non chiedere piu', 'Do not ask again')),
            ),
          ],
        );
      },
    );

    if (choice == 'never') {
      setState(() => masterAskPublicDiceConfirmation = false);
      unawaited(salvaDatiSoloLocale());
      return true;
    }

    return choice == 'yes';
  }

  Future<void> tiraSchedaMasterParty(int index, String key) async {
    if (index < 0 || index >= schedePersonaggio.length) return;

    final dado = tiraD20();
    final bonus = sheetRollBonusAt(index, key);
    final totale = rollTotalWithCritical(dado, 20, [bonus]);
    final testoDado = rollFormulaWithCritical(
      roll: dado,
      faces: 20,
      bonuses: [bonus],
    );
    final label = sheetRollLabel(key);
    final nome = nomeSchedaPersonaggio(index);

    setState(() {
      dadoMostrato = testoDado;
      dadoMostratoFacce = 20;
      tiroCriticoUno = dado == 1;
      tiroCriticoVenti = dado == 20;
      risultato = '$nome • $label: $testoDado';

      aggiungiLog('Tiro party $nome [$label]: $testoDado.');
      if (key == 'iniziativa') {
        updateMasterInitiativeToken(
          index: index,
          roll: dado,
          base: bonus,
          total: totale,
        );
      }
    });

    mostraDadoCentrale(
      valore: testoDado,
      criticoUno: dado == 1,
      criticoVenti: dado == 20,
    );

    if (key == 'iniziativa') {
      sendRealtimeMasterVisibleTokenAt(index);
      sendRealtimeInitiativeSnapshotIfPublished();
      await salvaDatiSoloLocale();
      return;
    }

    await sendRealtimeDiceRollWithMasterConsent(
      label: '$nome $label',
      roll: dado,
      bonus: bonus + criticalDieModifier(dado, 20),
      total: totale,
    );
  }
  // =====================================================
  // DANNI / CURA / SCUDO CRITICO
  // =====================================================

  DamageModifierOption modificatoreDannoAttuale() {
    return modificatoriDanno.firstWhere(
      (x) => x.name == modificatoreDannoSelezionato,
      orElse: () => modificatoriDanno.first,
    );
  }

  DamageModifierOption modificatoreDannoDaNome(String nome) {
    return modificatoriDanno.firstWhere(
      (x) => x.name == nome,
      orElse: () => modificatoriDanno.first,
    );
  }

  List<String> scalaCriticaDanno() {
    return const [
      'Rigenerazione Perfetta',
      'Rigenerazione Semi Perfetta',
      'Rigenerazione Molto Forte',
      'Rigenerazione Alta',
      'Rigenerazione Normale',
      'Rigenerazione Leggera',
      'Immunità',
      'Impenetrabile',
      'Semi Perfetta',
      'Resistenza Alta',
      'Resistenza Normale',
      'Resistenza Leggera',
      'Normale',
      'Fragilità Bassa',
      'Fragilità Normale',
      'Fragilità Alta',
      'Fragilità Estrema',
      'Fragilità Distruttiva',
      'Fragilità Assoluta',
      'Fragilità Semi Letale',
      'Fragilità Letale',
    ];
  }

  String prossimoStadioCriticoDanno(String attuale) {
    final scala = scalaCriticaDanno();
    final indice = scala.indexOf(attuale);

    if (indice < 0) return 'Fragilità Bassa';
    if (indice >= scala.length - 1) return scala.last;

    return scala[indice + 1];
  }

  int applicaModificatoreDannoCon(
    int dannoBase,
    DamageModifierOption modificatore,
  ) {
    if (dannoBase <= 0) return 0;

    final modificato = dannoBase * modificatore.multiplier;

    if (modificato > 0 && modificato < 1) {
      return 1;
    }

    return modificato.round();
  }

  int applicaModificatoreDanno(int dannoBase) {
    return applicaModificatoreDannoCon(dannoBase, modificatoreDannoAttuale());
  }

  void applicaDannoSubito({bool critico = false}) {
    final dannoInserito = leggiNumero(dannoSubitoController);

    if (dannoInserito <= 0) return;

    final modificatorePrima = modificatoreDannoSelezionato;
    final modificatoreDopo = critico
        ? prossimoStadioCriticoDanno(modificatorePrima)
        : modificatorePrima;
    final dannoInArrivo = dannoInserito + (critico ? 5 : 0);
    final dannoDopoDifesa = max(1, dannoInArrivo - difesa());
    final modificatore = critico
        ? modificatoreDannoDaNome(modificatoreDopo)
        : modificatoreDannoAttuale();
    final dannoModificato = applicaModificatoreDannoCon(
      dannoDopoDifesa,
      modificatore,
    );
    final dannoLog = critico
        ? '$dannoInserito + 5 critico = $dannoInArrivo'
        : '$dannoInArrivo';
    final criticoLogIt = critico
        ? (modificatorePrima == modificatoreDopo
              ? ' Critico: +5 danni, stadio già a $modificatoreDopo.'
              : ' Critico: +5 danni, stadio $modificatorePrima → $modificatoreDopo.')
        : '';
    final criticoLogEn = critico
        ? (modificatorePrima == modificatoreDopo
              ? ' Critical: +5 damage, stage already at $modificatoreDopo.'
              : ' Critical: +5 damage, stage $modificatorePrima → $modificatoreDopo.')
        : '';

    if (dannoModificato < 0) {
      final curaDaRigenerazione = dannoModificato.abs();

      setState(() {
        if (critico) {
          modificatoreDannoSelezionato = modificatoreDopo;
        }

        currentHpController.text = min(
          maxHp(),
          hpCorrenti() + curaDaRigenerazione,
        ).toString();

        risultato = t(
          'Rigenerazione: $dannoLog - Difesa ${difesa()} = $dannoDopoDifesa. ${modificatore.name}: curi $curaDaRigenerazione HP.$criticoLogIt',
          'Regeneration: $dannoLog - Defense ${difesa()} = $dannoDopoDifesa. ${modificatore.name}: you heal $curaDaRigenerazione HP.$criticoLogEn',
        );

        dannoSubitoController.clear();

        aggiungiLog(risultato);
      });

      programmaSalvataggio();
      sendRealtimeHpChanged();
      return;
    }

    if (dannoModificato == 0) {
      setState(() {
        if (critico) {
          modificatoreDannoSelezionato = modificatoreDopo;
        }

        risultato = t(
          'Danno annullato: $dannoLog - Difesa ${difesa()} = $dannoDopoDifesa. ${modificatore.name}: nessun danno subito.$criticoLogIt',
          'Damage negated: $dannoLog - Defense ${difesa()} = $dannoDopoDifesa. ${modificatore.name}: no damage taken.$criticoLogEn',
        );

        dannoSubitoController.clear();

        aggiungiLog(risultato);
      });

      programmaSalvataggio();
      return;
    }

    int dannoFinale = dannoModificato;
    final scudoCriticoPrima = scudoCritico();
    final scudoCriticoAttivo = scudoCriticoPrima > 0;
    final scudoCriticoSpezzato = critico && scudoCriticoAttivo;

    if (scudoCriticoAttivo) {
      dannoFinale = max(1, (dannoFinale / 2).ceil());
    }

    int rimanente = dannoFinale;
    int oculumShield = scudoOculum();
    int shield = scudo();
    int temp = hpTemp();
    int hp = hpCorrenti();

    if (oculumShield > 0 && rimanente > 0) {
      final assorbito = min(oculumShield, rimanente);
      oculumShield -= assorbito;
      rimanente -= assorbito;
    }

    if (shield > 0 && rimanente > 0) {
      final assorbito = min(shield, rimanente);
      shield -= assorbito;
      rimanente -= assorbito;
    }

    if (temp > 0 && rimanente > 0) {
      final assorbito = min(temp, rimanente);
      temp -= assorbito;
      rimanente -= assorbito;
    }

    if (rimanente > 0) {
      hp = max(0, hp - rimanente);
    }

    setState(() {
      if (critico) {
        modificatoreDannoSelezionato = modificatoreDopo;
      }

      scudoOculumController.text = oculumShield.toString();
      impostaScudoTotale(shield);
      impostaHpTempTotali(temp);
      currentHpController.text = hp.toString();
      if (scudoCriticoSpezzato) {
        scudoCriticoController.text = max(0, scudoCriticoPrima - 1).toString();
      }

      risultato = t(
        'Danno subito: $dannoLog - Difesa ${difesa()} = $dannoDopoDifesa. ${modificatore.name}: $dannoModificato.$criticoLogIt ${scudoCriticoAttivo ? "Scudo Critico attivo: danno dimezzato a $dannoFinale. " : ""}Applicato a Scudo Oculum -> Scudo -> HP Temp -> HP.',
        'Damage taken: $dannoLog - Defense ${difesa()} = $dannoDopoDifesa. ${modificatore.name}: $dannoModificato.$criticoLogEn ${scudoCriticoAttivo ? "Critical Shield active: damage halved to $dannoFinale. " : ""}Applied to Oculum Shield -> Shield -> Temp HP -> HP.',
      );

      if (scudoCriticoSpezzato) {
        risultato += t(
          '\nScudo Critico spezzato dal danno critico: -1.',
          '\nCritical Shield broken by critical damage: -1.',
        );
      }

      dannoSubitoController.clear();

      aggiungiLog(risultato);
    });

    programmaSalvataggio();
    sendRealtimeHpChanged();
  }

  void curaHp() {
    final cura = leggiNumero(dannoSubitoController);

    if (cura <= 0) return;

    setState(() {
      currentHpController.text = min(maxHp(), hpCorrenti() + cura).toString();

      risultato = t(
        'Cura applicata: +$cura HP.',
        'Healing applied: +$cura HP.',
      );

      dannoSubitoController.clear();

      aggiungiLog(risultato);
    });

    programmaSalvataggio();
    sendRealtimeHpChanged();
  }

  void refullVita() {
    setState(() {
      currentHpController.text = maxHp().toString();
      hpTempBonusConsumati = 0;
      scudoBonusConsumati = 0;
      final shieldBonus = runtimeQuickBonus('scudo');
      final shieldTargetTotal = max(scudo(), scudoRefullTarget());
      scudoController.text = max(0, shieldTargetTotal - shieldBonus).toString();
      final oculumShieldMax = scudoOculumMax();
      if (oculumShieldMax > 0) {
        ricaricaScudoOculum();
      }
      risultato = t(
        oculumShieldMax > 0
            ? 'Refull Vita: HP ${maxHp()}, HP Temp ${hpTemp()}, Scudo ${scudo()} e Scudo Oculum ${scudoOculum()}/$oculumShieldMax.'
            : 'Refull Vita: HP ${maxHp()}, HP Temp ${hpTemp()} e Scudo ${scudo()}.',
        oculumShieldMax > 0
            ? 'Refill Life: HP ${maxHp()}, Temp HP ${hpTemp()}, Shield ${scudo()} and Oculum Shield ${scudoOculum()}/$oculumShieldMax.'
            : 'Refill Life: HP ${maxHp()}, Temp HP ${hpTemp()} and Shield ${scudo()}.',
      );
      aggiungiLog(risultato);
    });

    programmaSalvataggio();
    sendRealtimeHpChanged();
  }

  void rompiScudoCritico() {
    setState(() {
      if (scudoCritico() > 0) {
        scudoCriticoController.text = max(0, scudoCritico() - 1).toString();

        risultato = t(
          'Scudo Critico spezzato da un critico in fight. -1 Scudo Critico.',
          'Critical Shield broken by a critical during combat. -1 Critical Shield.',
        );
      } else {
        risultato = t(
          'Non hai Scudo Critico da spezzare.',
          'You have no Critical Shield to break.',
        );
      }

      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  // =====================================================
  // EXP / LEVEL UP / GRADI / REBIRTH
  // =====================================================

  int gradoAutomaticoDaLivello(int livello, bool rebirth) {
    final soglieNormali = {
      1: 10,
      2: 30,
      3: 40,
      4: 50,
      5: 60,
      6: 70,
      7: 80,
      8: 90,
      9: 100,
      10: 120,
      11: 150,
      12: 200,
    };

    final soglieRebirth = {
      1: 8,
      2: 20,
      3: 30,
      4: 40,
      5: 50,
      6: 60,
      7: 70,
      8: 80,
      9: 90,
      10: 110,
      11: 130,
      12: 190,
    };

    final soglie = rebirth ? soglieRebirth : soglieNormali;

    int grado = 0;

    for (final entry in soglie.entries) {
      if (livello >= entry.value) {
        grado = entry.key;
      }
    }

    return grado;
  }

  void aggiornaGradoAutomatico() {
    final livello = leggiNumero(livelloController);
    final nuovoGrado = gradoAutomaticoDaLivello(livello, rebirthato);
    final gradoAttuale = max(0, leggiNumero(gradoController));

    if (nuovoGrado > gradoAttuale) {
      final gradiGuadagnati = nuovoGrado - gradoAttuale;
      gradoController.text = nuovoGrado.toString();
      scudoController.text =
          (leggiNumero(scudoController) + gradiGuadagnati * 36).toString();
      scudoCriticoController.text =
          (leggiNumero(scudoCriticoController) + gradiGuadagnati).toString();

      risultato = t(
        'Grado aggiornato automaticamente a Grado $nuovoGrado. +${gradiGuadagnati * 36} Scudo, +$gradiGuadagnati Scudo Critico.',
        'Grade automatically updated to Grade $nuovoGrado. +${gradiGuadagnati * 36} Shield, +$gradiGuadagnati Critical Shield.',
      );

      aggiungiLog(
        'Grado automatico: $gradoAttuale -> $nuovoGrado. +${gradiGuadagnati * 36} Scudo, +$gradiGuadagnati Scudo Critico.',
      );
    }
  }

  void toggleRebirth(bool value) {
    setState(() {
      rebirthato = value;
      aggiornaGradoAutomatico();

      risultato = rebirthato
          ? t(
              'Rebirth attivato. Le soglie Grado ora sono ridotte.',
              'Rebirth enabled. Grade thresholds are now reduced.',
            )
          : t(
              'Rebirth disattivato. Le soglie Grado tornano normali.',
              'Rebirth disabled. Grade thresholds are back to normal.',
            );

      aggiungiLog(rebirthato ? 'Rebirth attivato.' : 'Rebirth disattivato.');
    });

    programmaSalvataggio();
  }

  double expSourceMultiplier() {
    switch (fonteExpSelezionata) {
      case 'miniboss':
        return 1.3;
      case 'boss':
        return 2.0;
      default:
        return 1.0;
    }
  }

  String expSourceLabel() {
    switch (fonteExpSelezionata) {
      case 'miniboss':
        return 'Mini-Boss x1.3';
      case 'boss':
        return 'Boss x2';
      default:
        return t('Normale x1', 'Normal x1');
    }
  }

  String expDisplayName() {
    final custom = cleanUiText(expNomePersonalizzatoController.text).trim();
    if (custom.isNotEmpty) return custom;
    return isMostro() ? 'EXP MOSTRO' : 'EXP';
  }

  String normalizeObservationStat(
    String value, {
    String fallback = 'Resilienza',
    bool allowEmpty = false,
  }) {
    final normalized = oculumNormalizeText(value);
    if (normalized.isEmpty) return allowEmpty ? '' : fallback;

    for (final stat in statsLevelUp) {
      if (oculumNormalizeText(stat) == normalized) return stat;
    }

    return allowEmpty ? '' : fallback;
  }

  String observationStatKey(String stat) {
    switch (oculumNormalizeText(stat)) {
      case 'resilienza':
      case 'res':
        return 'resilienza';
      case 'volonta':
      case 'vol':
        return 'volonta';
      case 'materia':
      case 'mat':
        return 'materia';
      case 'oculum':
      case 'ocu':
        return 'oculum';
      default:
        return 'resilienza';
    }
  }

  String observationStatLabel(String stat) {
    final normalized = normalizeObservationStat(stat);
    switch (observationStatKey(normalized)) {
      case 'resilienza':
        return t('Resilienza', 'Resilience');
      case 'volonta':
        return t('Volontà', 'Will');
      case 'materia':
        return 'Materia';
      case 'oculum':
        return 'Oculum';
      default:
        return normalized;
    }
  }

  Map<String, int> osservazionePuntiAssegnatiSicuri() {
    return oculumNormalizeObservationAssignedCounts(
      osservazionePuntiAssegnati,
      legacyAssigned: osservazioneStatAssegnata,
    );
  }

  int osservazioneLivelloTotale() {
    return max(0, leggiNumero(livelloController));
  }

  int osservazionePuntiTeorici() {
    return oculumObservationTheoreticalPoints(
      observed: puoEssereOsservato,
      level: osservazioneLivelloTotale(),
    );
  }

  int osservazionePuntiAssegnatiTotali() {
    return oculumObservationAssignedTotal(osservazionePuntiAssegnatiSicuri());
  }

  int osservazionePuntiDisponibili() {
    return oculumObservationAvailablePoints(
      observed: puoEssereOsservato,
      level: osservazioneLivelloTotale(),
      assigned: osservazionePuntiAssegnatiSicuri(),
    );
  }

  String osservazioneStatAssegnataCompatibile() {
    final safe = osservazionePuntiAssegnatiSicuri();
    final preferred = observationStatKey(osservazioneStatAssegnata);
    if ((safe[preferred] ?? 0) > 0) {
      return normalizeObservationStat(osservazioneStatAssegnata);
    }
    for (final entry in safe.entries) {
      if (entry.value > 0) return observationStatLabel(entry.key);
    }
    return '';
  }

  String osservazioneAssegnazioniTesto() {
    final parts = <String>[];
    for (final entry in osservazionePuntiAssegnatiSicuri().entries) {
      if (entry.value <= 0) continue;
      parts.add('+${entry.value} ${observationStatLabel(entry.key)}');
    }
    return parts.join(' · ');
  }

  void sincronizzaOsservazioneDisponibile() {
    osservazionePuntiAssegnati = osservazionePuntiAssegnatiSicuri();
    osservazionePuntiDaAssegnare = osservazionePuntiDisponibili();
    osservazioneStatAssegnata = osservazioneStatAssegnataCompatibile();
  }

  void applicaPuntiOsservazioneAssegnati(int segno) {
    for (final entry in osservazionePuntiAssegnatiSicuri().entries) {
      if (entry.value <= 0) continue;
      aumentaStatBaseEAttuale(entry.key, entry.value * segno);
    }
  }

  String osservazioneMessaggioDisponibili() {
    final available = osservazionePuntiDisponibili();
    final theoretical = osservazionePuntiTeorici();
    final assigned = osservazionePuntiAssegnatiTotali();
    return t(
      'Osservazione: $available punti disponibili su $theoretical totali ($assigned assegnati).',
      'Observation: $available points available out of $theoretical total ($assigned assigned).',
    );
  }

  void togglePuoEssereOsservato(bool value) {
    if (value == puoEssereOsservato) return;

    setState(() {
      osservazionePuntiAssegnati = osservazionePuntiAssegnatiSicuri();
      if (value) {
        puoEssereOsservato = true;
        if (!osservazionePuntiApplicati &&
            osservazionePuntiAssegnatiTotali() > 0) {
          applicaPuntiOsservazioneAssegnati(1);
          osservazionePuntiApplicati = true;
        }
        sincronizzaOsservazioneDisponibile();
        risultato = osservazioneMessaggioDisponibili();
      } else {
        if (osservazionePuntiApplicati &&
            osservazionePuntiAssegnatiTotali() > 0) {
          applicaPuntiOsservazioneAssegnati(-1);
        }
        puoEssereOsservato = false;
        osservazionePuntiApplicati = false;
        sincronizzaOsservazioneDisponibile();
        risultato = t(
          'Osservazione disattivata: il punto bonus è stato rimosso.',
          'Observation disabled: assigned bonuses are suspended without losing the record.',
        );
        risultato = t(
          'Osservazione disattivata: i bonus assegnati sono sospesi senza perdere il registro.',
          'Observation disabled: assigned bonuses are suspended without losing the record.',
        );
      }
      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  void assegnaPuntoOsservazione() {
    if (!puoEssereOsservato || osservazionePuntiDisponibili() <= 0) {
      setState(() {
        risultato = t(
          'Non hai punti osservazione da assegnare.',
          'You have no observation points to assign.',
        );
      });
      return;
    }

    final stat = normalizeObservationStat(osservazioneStatScelta);
    final key = observationStatKey(stat);

    setState(() {
      osservazionePuntiAssegnati = osservazionePuntiAssegnatiSicuri();
      if (!osservazionePuntiApplicati &&
          osservazionePuntiAssegnatiTotali() > 0) {
        applicaPuntiOsservazioneAssegnati(1);
      }
      osservazionePuntiApplicati = true;
      aumentaStatBaseEAttuale(key, 1);
      osservazionePuntiAssegnati[key] =
          max(0, osservazionePuntiAssegnati[key] ?? 0) + 1;
      osservazioneStatScelta = stat;
      sincronizzaOsservazioneDisponibile();
      risultato = t(
        'Punto osservazione assegnato a ${observationStatLabel(stat)}. ${osservazioneMessaggioDisponibili()}',
        'Observation point assigned to ${observationStatLabel(stat)}. ${osservazioneMessaggioDisponibili()}',
      );
      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  void rimuoviPuntoOsservazioneAssegnato([String? stat]) {
    final safe = osservazionePuntiAssegnatiSicuri();
    var key = oculumObservationStatKey(stat ?? '', allowEmpty: true);
    if (key.isEmpty || (safe[key] ?? 0) <= 0) {
      key = safe.entries
          .firstWhere(
            (entry) => entry.value > 0,
            orElse: () => const MapEntry('', 0),
          )
          .key;
    }
    if (key.isEmpty) return;

    setState(() {
      osservazionePuntiAssegnati = safe;
      if (osservazionePuntiApplicati) {
        aumentaStatBaseEAttuale(key, -1);
      }
      osservazionePuntiAssegnati[key] = max(
        0,
        (osservazionePuntiAssegnati[key] ?? 0) - 1,
      );
      osservazioneStatScelta = observationStatLabel(key);
      sincronizzaOsservazioneDisponibile();
      risultato = t(
        'Punto osservazione rimosso da ${observationStatLabel(key)}. ${osservazioneMessaggioDisponibili()}',
        'Observation point removed from ${observationStatLabel(key)}. ${osservazioneMessaggioDisponibili()}',
      );
      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  double expGradeMultiplier() {
    final diff =
        leggiNumero(enemyGradeExpController) - leggiNumero(gradoController);
    if (diff <= 0) return 1.0;
    return pow(1.2, diff).toDouble();
  }

  int expFinalePreview() {
    final base = max(0, leggiNumero(expDaAggiungereController));
    final value = base * expSourceMultiplier() * expGradeMultiplier();
    if (value.isNaN || value.isInfinite) return 0;
    return value.round().clamp(0, 999999).toInt();
  }

  void aggiungiEsperienza() {
    final expBase = leggiNumero(expDaAggiungereController);
    final expAggiunta = expFinalePreview();

    if (expBase <= 0 || expAggiunta <= 0) {
      setState(() {
        risultato = t(
          'Scrivi quanta EXP vuoi aggiungere.',
          'Write how much EXP you want to add.',
        );
      });

      return;
    }

    final tassaStatsExp = sottraiStatsDaExpAggiunta
        ? max(
            0,
            resilienzaTotale() +
                volontaTotale() +
                materiaTotale() +
                oculumTotale(),
          )
        : 0;
    final expRealeAggiunta = max(0, expAggiunta - tassaStatsExp);
    final expTotale = expCorrente() + expRealeAggiunta;
    if (!scalaExpAutomatica) {
      setState(() {
        expController.text = expTotale.clamp(0, 999999).toString();
        ricaricaScudoOculum();
        risultato = t(
          'EXP aggiunta senza scalare livelli: base $expBase, ${expSourceLabel()}, grado x${expGradeMultiplier().toStringAsFixed(2)} → +$expRealeAggiunta${tassaStatsExp > 0 ? ' ($expAggiunta - $tassaStatsExp stats)' : ''}. EXP attuale: ${expController.text}.',
          'EXP added without level scaling: base $expBase, ${expSourceLabel()}, grade x${expGradeMultiplier().toStringAsFixed(2)} → +$expRealeAggiunta${tassaStatsExp > 0 ? ' ($expAggiunta - $tassaStatsExp stats)' : ''}. Current EXP: ${expController.text}.',
        );
        expDaAggiungereController.clear();
        aggiungiLog(risultato);
      });

      programmaSalvataggio();
      return;
    }

    final livelliGuadagnati = expTotale ~/ 1000;
    final expRimasta = expTotale % 1000;

    setState(() {
      expController.text = expRimasta.toString();
      ricaricaScudoOculum();

      if (livelliGuadagnati > 0) {
        livelloController.text =
            (leggiNumero(livelloController) + livelliGuadagnati).toString();

        aggiornaGradoAutomatico();

        if (isMostro()) {
          monsterStatPoints += livelliGuadagnati * 9;
          refullaHp();

          risultato = t(
            'Mostro salito di $livelliGuadagnati livello/i. +${livelliGuadagnati * 9} punti mostro da distribuire. HP refullati.',
            'Monster gained $livelliGuadagnati level(s). +${livelliGuadagnati * 9} monster points to assign. HP refilled.',
          );
        } else {
          levelUpDaAssegnare += livelliGuadagnati;
          refullaHp();

          risultato = t(
            'Hai guadagnato $livelliGuadagnati livello/i. Level up da assegnare: $levelUpDaAssegnare. HP refullati.',
            'You gained $livelliGuadagnati level(s). Level ups to assign: $levelUpDaAssegnare. HP refilled.',
          );
        }
      } else {
        risultato = t(
          'EXP aggiunta: base $expBase, ${expSourceLabel()}, grado x${expGradeMultiplier().toStringAsFixed(2)} → +$expRealeAggiunta${tassaStatsExp > 0 ? ' ($expAggiunta - $tassaStatsExp stats)' : ''}. EXP attuale: $expRimasta/1000.',
          'EXP added: base $expBase, ${expSourceLabel()}, grade x${expGradeMultiplier().toStringAsFixed(2)} → +$expRealeAggiunta${tassaStatsExp > 0 ? ' ($expAggiunta - $tassaStatsExp stats)' : ''}. Current EXP: $expRimasta/1000.',
        );
      }

      expDaAggiungereController.clear();

      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  void aggiungiLivelliRapidi() {
    final livelli = leggiNumero(livelliRapidiController);

    if (livelli <= 0) {
      setState(() {
        risultato = t(
          'Scrivi quanti livelli vuoi aggiungere.',
          'Write how many levels you want to add.',
        );
      });

      return;
    }

    setState(() {
      livelloController.text = (leggiNumero(livelloController) + livelli)
          .toString();

      aggiornaGradoAutomatico();

      if (isMostro()) {
        monsterStatPoints += livelli * 9;
        refullaHp();

        risultato = t(
          'Mostro aumentato di $livelli livelli. +${livelli * 9} punti mostro. HP refullati.',
          'Monster increased by $livelli levels. +${livelli * 9} monster points. HP refilled.',
        );
      } else {
        levelUpDaAssegnare += livelli;
        refullaHp();

        risultato = t(
          'Aggiunti $livelli livelli rapidi. Ora hai $levelUpDaAssegnare level up da assegnare. HP refullati.',
          'Added $livelli quick levels. You now have $levelUpDaAssegnare level ups to assign. HP refilled.',
        );
      }

      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  int bonusLevelUpPerStat(String stat) {
    if (stat == levelUpStatTre) return 3;
    if (stat == levelUpStatDue) return 2;

    return 1;
  }

  void modificaCmRapido(int delta) {
    if (delta == 0) return;
    final materiaDelta = delta * 2;

    setState(() {
      final baseMateria = leggiNumero(materiaController);
      final nextBaseMateria = max(0, baseMateria + materiaDelta);
      final appliedDelta = nextBaseMateria - baseMateria;
      materiaController.text = nextBaseMateria.toString();
      currentMateriaController.text = (currentMateria() + appliedDelta)
          .toString();
      syncVisibleCurrentStatEditor('materia');
      risultato = t(
        '${delta > 0 ? '+1' : '-1'} CM: Materia reale ${appliedDelta > 0 ? '+' : ''}$appliedDelta.',
        '${delta > 0 ? '+1' : '-1'} CM: real Matter ${appliedDelta > 0 ? '+' : ''}$appliedDelta.',
      );
      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  void modificaBonusCmRapido(int delta) {
    if (delta == 0) return;

    setState(() {
      cmRapidoController.text = (bonusCmRapido() + delta).toString();
      risultato = t(
        'Bonus CM rapido ${delta > 0 ? '+' : ''}$delta. Totale bonus CM: ${cmRapidoController.text}.',
        'Quick CM bonus ${delta > 0 ? '+' : ''}$delta. Total CM bonus: ${cmRapidoController.text}.',
      );
      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  void modificaAttaccoRapido(int delta) {
    if (delta == 0) return;

    setState(() {
      attaccoRapidoController.text = (bonusAttaccoRapido() + delta).toString();
      risultato = t(
        'Bonus Attacco rapido ${delta > 0 ? '+' : ''}$delta. Totale: ${attaccoRapidoController.text}.',
        'Quick Attack bonus ${delta > 0 ? '+' : ''}$delta. Total: ${attaccoRapidoController.text}.',
      );
      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  void modificaDifesaRapida(int delta) {
    if (delta == 0) return;

    setState(() {
      difesaRapidaController.text = (bonusDifesaRapido() + delta).toString();
      risultato = t(
        'Bonus Difesa rapido ${delta > 0 ? '+' : ''}$delta. Totale: ${difesaRapidaController.text}.',
        'Quick Defense bonus ${delta > 0 ? '+' : ''}$delta. Total: ${difesaRapidaController.text}.',
      );
      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  void modificaVcRapido(int delta) {
    if (delta == 0) return;
    final volontaDelta = delta * 3;

    setState(() {
      final baseVolonta = leggiNumero(volontaController);
      final nextBaseVolonta = max(0, baseVolonta + volontaDelta);
      final appliedDelta = nextBaseVolonta - baseVolonta;
      volontaController.text = nextBaseVolonta.toString();
      currentVolontaController.text = (currentVolonta() + appliedDelta)
          .toString();
      syncVisibleCurrentStatEditor('volonta');
      risultato = t(
        '${delta > 0 ? '+1' : '-1'} VC: Volonta reale ${appliedDelta > 0 ? '+' : ''}$appliedDelta.',
        '${delta > 0 ? '+1' : '-1'} VC: real Will ${appliedDelta > 0 ? '+' : ''}$appliedDelta.',
      );
      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  void applicaLevelUp({required bool tutti}) {
    if (isMostro()) {
      setState(() {
        risultato = t(
          'Questa crescita è per i Personaggi. I Mostri usano i punti mostro.',
          'This growth is for Characters. Monsters use monster points.',
        );
      });

      return;
    }

    if (levelUpDaAssegnare <= 0) {
      setState(() {
        risultato = t(
          'Non hai level up da assegnare.',
          'You have no level ups to assign.',
        );
      });

      return;
    }

    if (levelUpStatTre == levelUpStatDue) {
      setState(() {
        risultato = t(
          'La statistica da +3 e quella da +2 devono essere diverse.',
          'The +3 stat and +2 stat must be different.',
        );
      });

      return;
    }

    final volte = tutti ? levelUpDaAssegnare : 1;

    final bonusRes = bonusLevelUpPerStat('Resilienza') * volte;
    final bonusVol = bonusLevelUpPerStat('Volontà') * volte;
    final bonusMat = bonusLevelUpPerStat('Materia') * volte;
    final bonusOcu = bonusLevelUpPerStat('Oculum') * volte;
    final bonusScudo = 6 * volte;

    setState(() {
      aumentaStatBaseEAttuale('resilienza', bonusRes);
      aumentaStatBaseEAttuale('volonta', bonusVol);
      aumentaStatBaseEAttuale('materia', bonusMat);
      aumentaStatBaseEAttuale('oculum', bonusOcu);

      scudoController.text = (leggiNumero(scudoController) + bonusScudo)
          .toString();

      levelUpDaAssegnare -= volte;
      refullaHp();

      risultato = t(
        tutti
            ? 'Scelta copiata su $volte livelli: +$bonusRes Res, +$bonusVol Vol, +$bonusMat Mat, +$bonusOcu Ocu, +$bonusScudo Scudo. HP refullati.'
            : 'Level up applicato: +$bonusRes Res, +$bonusVol Vol, +$bonusMat Mat, +$bonusOcu Ocu, +$bonusScudo Scudo. HP refullati.',
        tutti
            ? 'Choice copied on $volte levels: +$bonusRes Res, +$bonusVol Will, +$bonusMat Mat, +$bonusOcu Ocu, +$bonusScudo Shield. HP refilled.'
            : 'Level up applied: +$bonusRes Res, +$bonusVol Will, +$bonusMat Mat, +$bonusOcu Ocu, +$bonusScudo Shield. HP refilled.',
      );

      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  void assegnaPuntiMostro() {
    if (!isMostro()) {
      setState(() {
        risultato = t(
          'Questi punti sono riservati alle schede Mostro.',
          'These points are only for Monster sheets.',
        );
      });

      return;
    }

    final quantita = leggiNumero(monsterPointAmountController);

    if (quantita <= 0) {
      setState(() {
        risultato = t(
          'Scrivi quanti punti mostro vuoi assegnare.',
          'Write how many monster points you want to assign.',
        );
      });

      return;
    }

    if (quantita > monsterStatPoints) {
      setState(() {
        risultato = t(
          'Non hai abbastanza punti mostro. Disponibili: $monsterStatPoints.',
          'Not enough monster points. Available: $monsterStatPoints.',
        );
      });

      return;
    }

    setState(() {
      if (monsterSelectedStat == 'Resilienza') {
        aumentaStatBaseEAttuale('resilienza', quantita);
      } else if (monsterSelectedStat == 'Volontà') {
        aumentaStatBaseEAttuale('volonta', quantita);
      } else if (monsterSelectedStat == 'Materia') {
        aumentaStatBaseEAttuale('materia', quantita);
      } else {
        aumentaStatBaseEAttuale('oculum', quantita);
      }

      monsterStatPoints -= quantita;
      refullaHp();

      risultato = t(
        'Assegnati $quantita punti mostro a $monsterSelectedStat. HP refullati.',
        'Assigned $quantita monster points to $monsterSelectedStat. HP refilled.',
      );

      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  void applicaBonusGradoMostro() {
    if (!isMostro()) {
      setState(() {
        risultato = t(
          'Il bonus +10 × Grado è pensato per i Mostri.',
          'The +10 × Grade bonus is meant for Monsters.',
        );
      });

      return;
    }

    final grado = leggiNumero(gradoController);
    final bonus = grado * 10;

    if (bonus <= 0) {
      setState(() {
        risultato = t(
          'Il Mostro deve avere almeno Grado 1.',
          'The Monster must have at least Grade 1.',
        );
      });

      return;
    }

    setState(() {
      if (monsterGradeStat == 'Resilienza') {
        aumentaStatBaseEAttuale('resilienza', bonus);
      } else if (monsterGradeStat == 'Volontà') {
        aumentaStatBaseEAttuale('volonta', bonus);
      } else if (monsterGradeStat == 'Materia') {
        aumentaStatBaseEAttuale('materia', bonus);
      } else {
        aumentaStatBaseEAttuale('oculum', bonus);
      }

      scudoController.text = (leggiNumero(scudoController) + 36).toString();
      scudoCriticoController.text = (leggiNumero(scudoCriticoController) + 1)
          .toString();

      refullaHp();

      risultato = t(
        'Bonus Grado Mostro applicato: +$bonus a $monsterGradeStat, +36 Scudo, +1 Scudo Critico, HP refullati.',
        'Monster Grade bonus applied: +$bonus to $monsterGradeStat, +36 Shield, +1 Critical Shield, HP refilled.',
      );

      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  void applicaBonusGradoPersonaggio() {
    final grado = leggiNumero(gradoController);

    if (grado <= 0) {
      setState(() {
        risultato = t('Serve almeno Grado 1.', 'At least Grade 1 is required.');
      });

      return;
    }

    setState(() {
      scudoController.text = (leggiNumero(scudoController) + 36).toString();

      scudoCriticoController.text = (leggiNumero(scudoCriticoController) + 1)
          .toString();

      refullaHp();

      risultato = t(
        'Bonus Grado applicato: +36 Scudo, +1 Scudo Critico e HP refullati.',
        'Grade bonus applied: +36 Shield, +1 Critical Shield and HP refilled.',
      );

      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  void randomizzaStatsBilanciate() {
    final random = Random();

    final livello = max(0, leggiNumero(livelloController));
    final grado = max(0, leggiNumero(gradoController));

    final punti = 5 + livello * 6 + grado * 8;

    int res = 3;
    int vol = 1;
    int mat = 0;
    int ocu = 1;

    final stats = ['Resilienza', 'Volontà', 'Materia', 'Oculum'];

    int remaining = punti;

    while (remaining > 0) {
      stats.shuffle(random);

      for (final stat in stats) {
        if (remaining <= 0) break;

        final valori = {
          'Resilienza': res,
          'Volontà': vol,
          'Materia': mat,
          'Oculum': ocu,
        };

        final minVal = valori.values.reduce(min);
        final isLow = valori[stat] == minVal;

        final incremento = isLow
            ? 1 + random.nextInt(2)
            : random.nextDouble() < 0.75
            ? 1
            : 0;

        if (incremento <= 0) continue;

        if (stat == 'Resilienza') {
          res += incremento;
        } else if (stat == 'Volontà') {
          vol += incremento;
        } else if (stat == 'Materia') {
          mat += incremento;
        } else {
          ocu += incremento;
        }

        remaining -= incremento;
      }
    }

    setState(() {
      resilienzaController.text = res.toString();
      volontaController.text = vol.toString();
      materiaController.text = mat.toString();
      oculumController.text = ocu.toString();
      currentResilienzaController.text = res.toString();
      currentVolontaController.text = vol.toString();
      currentMateriaController.text = mat.toString();
      currentOculumController.text = ocu.toString();

      refullaHp();

      risultato =
          'Stats randomizzate in modo bilanciato: RES $res, VOL $vol, MAT $mat, OCU $ocu.';

      aggiungiLog(
        'Stats randomizzate: RES $res, VOL $vol, MAT $mat, OCU $ocu.',
      );
    });

    programmaSalvataggio();
  }

  // =====================================================
}
