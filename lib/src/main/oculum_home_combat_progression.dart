part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member, unused_element

final RegExp _oculumIncomingDamageRulePattern = RegExp(
  r'@([A-Za-zÀ-ÿ]+)\s*([+-]\s*\d+\s*%?)?\s*([^@\n,;]*)',
);
final RegExp _oculumSafeHpCommandPattern = RegExp(
  r'@safehp\b',
  caseSensitive: false,
);
final RegExp _oculumSaveShieldCommandPattern = RegExp(
  r'@saveShield\s*\+?(\d+)',
  caseSensitive: false,
);
final RegExp _oculumConsumeSafeHpPattern = RegExp(
  r'\s*@safehp\b',
  caseSensitive: false,
);
final RegExp _oculumConsumeSaveShieldPattern = RegExp(
  r'\s*@saveShield\s*\+?\d+',
  caseSensitive: false,
);

String oculumRollZeroOutcomeText({
  required int total,
  required int difficulty,
}) {
  return difficulty != 0 && total == 0 ? '\nRiesci ma...' : '';
}

extension _OculumHomeCombatProgression on _OculumHomePageState {
  bool currentCombatIsActive() {
    final realtimeTokens = realtimeVisibleInitiativeSnapshot['tokens'];
    return masterInitiativePublished ||
        masterInitiativeTokens.isNotEmpty ||
        (realtimeTokens is List && realtimeTokens.isNotEmpty);
  }

  String currentTemporaryResistanceOwnerSheetId() {
    if (schedaCorrente < 0 || schedaCorrente >= schedePersonaggio.length) {
      return '';
    }
    final sheet = schedePersonaggio[schedaCorrente];
    final id = '${sheet['sheetTag'] ?? sheet['id'] ?? ''}'.trim();
    return id.isNotEmpty ? id : 'local_sheet_$schedaCorrente';
  }

  bool currentSheetHasAdaptationTemporaryResistance() {
    final ownerSheetId = currentTemporaryResistanceOwnerSheetId();
    if (ownerSheetId.isEmpty || !currentCombatIsActive()) return false;
    return temporaryCombatResistanceEffects.any(
      (effect) =>
          effect.ownerSheetId == ownerSheetId &&
          effect.isAdaptationAllDamageCurrentCombat,
    );
  }

  void clearTemporaryCombatResistanceEffects() {
    oculumRemoveCurrentCombatTemporaryEffects(temporaryCombatResistanceEffects);
  }

  // DADO / TIRI
  // =====================================================

  int tiraD20({bool countsAsCooldownRoll = true}) {
    if (countsAsCooldownRoll) {
      tickStructuredAbilityCooldowns('tiri');
    }
    return Random().nextInt(20) + 1;
  }

  void applyAutomaticAshForTurnProgress(int previous, int next) {
    if (next < previous) {
      automaticAshLastCheckedTurn = next;
      return;
    }
    final level = max(0, leggiNumero(livelloController));
    final firstAshTurn = oculumAutomaticAshFreeTurns(level) + 1;
    final firstTurn = max(
      firstAshTurn,
      max(previous + 1, automaticAshLastCheckedTurn + 1),
    );
    if (firstTurn > next) return;
    final random = Random.secure();
    for (var checkedTurn = firstTurn; checkedTurn <= next; checkedTurn++) {
      final chance = oculumAutomaticAshChancePercent(
        turn: checkedTurn,
        difficulty: campaignDifficulty,
        level: level,
        underStress: sottoStress,
      );
      final roll = random.nextInt(100) + 1;
      automaticAshLastCheckedTurn = checkedTurn;
      if (roll > chance) continue;
      final fainting = modificaCenereControllata(1);
      final message = t(
        'Cenere +1 automatica al turno $checkedTurn: '
            '$roll su 100, probabilita $chance% '
            '(${campaignDifficultyLabel()}).',
        'Automatic Ash +1 on turn $checkedTurn: '
            '$roll out of 100, $chance% chance '
            '(${campaignDifficultyLabel()}).',
      );
      aggiungiLog(fainting == null ? message : '$message\n$fainting');
    }
  }

  void checkAutomaticAshFromHpLoss(
    int before,
    int after, {
    String source = '',
  }) {
    final thresholds = oculumCrossedHpQuarterThresholds(
      before: before,
      after: after,
      maximum: maxHp(),
    );
    if (thresholds.isEmpty) return;
    final random = Random.secure();
    for (final remainingPercent in thresholds) {
      final chance = oculumHpLossAshChancePercent(
        remainingPercent: remainingPercent,
        difficulty: campaignDifficulty,
        underStress: sottoStress,
      );
      final roll = random.nextInt(100) + 1;
      final success = roll <= chance;
      final fainting = success ? modificaCenereControllata(1) : null;
      final sourceText = source.trim().isEmpty ? '' : ' ($source)';
      final message = t(
        'Soglia Vita $remainingPercent%$sourceText: $roll su 100, '
            'Cenere ${success ? "+1" : "non ottenuta"} '
            '(probabilita $chance%, ${campaignDifficultyLabel()}'
            '${sottoStress ? ", Sotto stress" : ""}).',
        'Life threshold $remainingPercent%$sourceText: $roll out of 100, '
            'Ash ${success ? "+1" : "not gained"} '
            '($chance% chance, ${campaignDifficultyLabel()}'
            '${sottoStress ? ", Under stress" : ""}).',
      );
      aggiungiLog(fainting == null ? message : '$message\n$fainting');
    }
  }

  void setPlayerReportedTurn(int value, {bool broadcast = true}) {
    final safe = max(0, value);
    if (safe == playerReportedTurn) return;
    final previous = playerReportedTurn;
    setState(() {
      playerReportedTurn = safe;
      final tag = sheetTagAt(schedaCorrente);
      final localTokenIndex = masterInitiativeTokens.indexWhere(
        (token) => '${token['sheetTag'] ?? token['id'] ?? ''}'.trim() == tag,
      );
      if (localTokenIndex >= 0) {
        masterInitiativeTokens[localTokenIndex]['reportedTurn'] = safe;
      }
    });
    if (safe > previous) {
      for (var turn = previous; turn < safe; turn++) {
        tickStructuredAbilityCooldowns('turni', scheduleSave: false);
      }
    }
    applyAutomaticAshForTurnProgress(previous, safe);
    programmaSalvataggio(invalidateCaches: false);
    if (broadcast) {
      sendRealtimeReportedTurn(
        sheetTag: sheetTagAt(schedaCorrente),
        turn: safe,
        senderRole: realtimeIsMasterRole ? 'master' : 'player',
      );
      if (realtimeIsMasterRole) sendRealtimeInitiativeSnapshotIfPublished();
    }
  }

  void setMasterTokenReportedTurn(int index, int value) {
    if (index < 0 || index >= masterInitiativeTokens.length) return;
    final safe = max(0, value);
    final token = masterInitiativeTokens[index];
    setState(() {
      token['reportedTurn'] = safe;
      token['updatedAt'] = DateTime.now().toIso8601String();
      if ('${token['sheetTag'] ?? token['id'] ?? ''}'.trim() ==
          sheetTagAt(schedaCorrente)) {
        playerReportedTurn = safe;
      }
    });
    programmaSalvataggio(invalidateCaches: false);
    sendRealtimeReportedTurn(
      sheetTag: '${token['sheetTag'] ?? token['id'] ?? ''}',
      turn: safe,
      senderRole: 'master',
    );
    sendRealtimeInitiativeSnapshotIfPublished();
  }

  int activeCriticalLevel() {
    return max(0, leggiNumero(livelloController) + rebirthLevelBonus());
  }

  int activeCriticalGrade() {
    return max(0, leggiNumero(gradoController));
  }

  int criticalDieModifier(int roll, int faces, {int? level, int? grade}) {
    if (faces <= 1) return 0;
    final criticalLevel = max(0, level ?? activeCriticalLevel());
    final criticalGrade = max(0, grade ?? activeCriticalGrade());
    final halfDie = faces ~/ 2;
    if (roll == faces) return halfDie + criticalLevel + criticalGrade * 6;
    if (roll == 1) return -(halfDie + criticalLevel + criticalGrade * 3);
    return 0;
  }

  String signedRollPart(int value) {
    if (value > 0) return '+$value';
    return '$value';
  }

  int rollTotalWithCritical(
    int roll,
    int faces,
    Iterable<int> bonuses, {
    int? level,
    int? grade,
    int? difficulty,
  }) {
    return roll +
        criticalDieModifier(roll, faces, level: level, grade: grade) +
        bonuses.fold<int>(0, (a, b) => a + b) +
        modificatoreDifficoltaTiro(difficulty: difficulty);
  }

  String rollFormulaWithCritical({
    required int roll,
    required int faces,
    Iterable<int> bonuses = const <int>[],
    int? level,
    int? grade,
    int? difficulty,
  }) {
    final parts = <String>['$roll'];
    final critical = criticalDieModifier(
      roll,
      faces,
      level: level,
      grade: grade,
    );
    if (critical != 0) parts.add(signedRollPart(critical));
    for (final bonus in bonuses) {
      if (bonus != 0) parts.add(signedRollPart(bonus));
    }
    final difficultyModifier = modificatoreDifficoltaTiro(
      difficulty: difficulty,
    );
    if (difficultyModifier != 0) parts.add(signedRollPart(difficultyModifier));
    final total = rollTotalWithCritical(
      roll,
      faces,
      bonuses,
      level: level,
      grade: grade,
      difficulty: difficulty,
    );
    final resolvedDifficulty = difficulty ?? difficoltaTiro();
    final difficultyText = resolvedDifficulty == 0
        ? ''
        : ' (DT ${signedRollPart(resolvedDifficulty)})';
    final zeroOutcome = oculumRollZeroOutcomeText(
      total: total,
      difficulty: resolvedDifficulty,
    );
    return '${parts.join()}=$total$difficultyText$zeroOutcome';
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

    _applyDadoCentraleOverlayState(
      valore: valore,
      criticoUno: criticoUno,
      criticoVenti: criticoVenti,
      facce: facce,
      reduceEffects: reduceEffects,
    );
    notifyDiceOverlayChanged();

    _scheduleDadoCentraleOverlayTimers(reduceEffects: reduceEffects);
  }

  void _applyDadoCentraleOverlayState({
    required String valore,
    required bool criticoUno,
    required bool criticoVenti,
    required int facce,
    required bool reduceEffects,
  }) {
    dadoOverlay = valore;
    dadoOverlayFacce = facce;
    if (!reduceEffects) dadoOverlaySpinSeed++;
    overlayCriticoUno = criticoUno;
    overlayCriticoVenti = criticoVenti;
    mostraOverlayDado = true;
    dadoOverlayMostraRisultato = reduceEffects;
    dadoOverlayDismissibile = false;
  }

  void _scheduleDadoCentraleOverlayTimers({required bool reduceEffects}) {
    if (!reduceEffects) {
      dadoOverlayRevealTimer = Timer(const Duration(milliseconds: 500), () {
        if (!mounted) return;

        dadoOverlayMostraRisultato = true;
        notifyDiceOverlayChanged();
      });
    }

    dadoOverlayTimer = Timer(
      Duration(milliseconds: reduceEffects ? 300 : 1000),
      () {
        if (!mounted) return;

        dadoOverlayDismissibile = true;
        notifyDiceOverlayChanged();
      },
    );
  }

  void scheduleCombatRollSave() {
    programmaSalvataggio(
      invalidateCaches: false,
      delay: const Duration(milliseconds: 2600),
    );
  }

  Future<void> tiraStat(String nome, int valore) async {
    oculumProfileMark('roll_stat');
    final dado = tiraD20();
    final oculumSpend = consumaOculumTiro();
    final bonus = oculumStatRollBonus(
      statValue: valore,
      levelGradeBonus: bonusLivelloGrado(),
      quickBonus: statRollQuickBonus(nome),
      extraBonus: oculumSpend.bonus,
    );
    final totale = rollTotalWithCritical(dado, 20, [bonus]);
    final testoDado = rollFormulaWithCritical(
      roll: dado,
      faces: 20,
      bonuses: [bonus],
    );
    final expGuadagnata = oculumRollExperienceGain(
      naturalRoll: dado,
      faces: 20,
      rollSucceeded: totale > 0,
    );

    final statoForzaLog = registraTiroStatoForza();
    final expText = applicaEsperienzaFlat(
      expGuadagnata,
      motivo: t('Tiro superato', 'Successful roll'),
    );
    dadoMostrato = testoDado;
    dadoMostratoFacce = 20;
    tiroCriticoUno = dado == 1;
    tiroCriticoVenti = dado == 20;
    risultato = '$nome: $testoDado$statoForzaLog$expText';
    aggiungiLog(
      'Tiro $nome: $testoDado.${oculumTiroLogLabel(oculumSpend)}$statoForzaLog$expText',
    );
    registerValidRoll();
    notifyDiceResultChanged();
    if (statoForzaLog.isNotEmpty) {
      scheduleCombatRollSave();
    }

    mostraDadoCentrale(
      valore: testoDado,
      criticoUno: dado == 1,
      criticoVenti: dado == 20,
    );
    scheduleCombatRollRealtime(
      label: nome,
      roll: dado,
      bonus:
          bonus + criticalDieModifier(dado, 20) + modificatoreDifficoltaTiro(),
      total: totale,
    );
  }

  Future<void> tiraValoreSpeciale(
    String nome,
    int bonus, {
    bool applyGlobalRollModifier = true,
  }) async {
    oculumProfileMark('roll_special');
    final dado = tiraD20();
    final oculumSpend = consumaOculumTiro();
    final bonusTotale =
        bonus +
        (applyGlobalRollModifier ? tiroGlobaleBonus() : 0) +
        oculumSpend.bonus;
    final totale = rollTotalWithCritical(dado, 20, [bonusTotale]);
    final testoDado = rollFormulaWithCritical(
      roll: dado,
      faces: 20,
      bonuses: [bonusTotale],
    );
    final expGuadagnata = oculumRollExperienceGain(
      naturalRoll: dado,
      faces: 20,
      rollSucceeded: totale > 0,
    );

    final statoForzaLog = registraTiroStatoForza();
    final expText = applicaEsperienzaFlat(
      expGuadagnata,
      motivo: t('Tiro superato', 'Successful roll'),
    );
    dadoMostrato = testoDado;
    dadoMostratoFacce = 20;
    tiroCriticoUno = dado == 1;
    tiroCriticoVenti = dado == 20;
    risultato = '$nome: $testoDado$statoForzaLog$expText';
    aggiungiLog(
      'Tiro $nome: $testoDado.${oculumTiroLogLabel(oculumSpend)}$statoForzaLog$expText',
    );
    registerValidRoll();
    notifyDiceResultChanged();
    if (statoForzaLog.isNotEmpty) {
      scheduleCombatRollSave();
    }

    mostraDadoCentrale(
      valore: testoDado,
      criticoUno: dado == 1,
      criticoVenti: dado == 20,
    );
    scheduleCombatRollRealtime(
      label: nome,
      roll: dado,
      bonus:
          bonusTotale +
          criticalDieModifier(dado, 20) +
          modificatoreDifficoltaTiro(),
      total: totale,
    );
  }

  Future<void> tiraSottotrattoOcchio(HiddenEyeStat stat) async {
    oculumProfileMark('roll_subtrait');
    final dado = tiraD20();
    final oculumSpend = consumaOculumTiro();
    final bonus =
        hiddenEyeTotal(stat) +
        hiddenEyeStatRollQuickBonus(stat) +
        tiroGlobaleBonus() +
        oculumSpend.bonus;
    final totale = rollTotalWithCritical(dado, 20, [bonus]);
    final testoDado = rollFormulaWithCritical(
      roll: dado,
      faces: 20,
      bonuses: [bonus],
    );
    final label =
        '${stat.nome} (${hiddenEyeGroupLabel(hiddenEyeStatGroup(stat.id))})';
    final masteryGain = oculusSubtraitMasteryGainForDie(dado);
    final expGuadagnata = oculumRollExperienceGain(
      naturalRoll: dado,
      faces: 20,
      rollSucceeded: totale > 0,
    );
    var masteryCompletedLevels = 0;
    final reduceDiceEffects =
        modalitaLeggera || modalitaVeloce || phoneCompactUi;
    var statoForzaLog = '';

    dadoOverlayTimer?.cancel();
    dadoOverlayRevealTimer?.cancel();
    if (masteryGain > 0) {
      masteryCompletedLevels = oculusSubtraitMasteryApplyGain(
        stat,
        masteryGain,
      );
      notifyHiddenEyeStatChanged(stat);
    }
    final masteryText = masteryGain <= 0
        ? ''
        : masteryCompletedLevels > 1
        ? ' ${t('Maestria piena: +$masteryCompletedLevels sottotratti.', 'Mastery full: +$masteryCompletedLevels subtraits.')}'
        : masteryCompletedLevels == 1
        ? ' ${t('Maestria piena: +1 sottotratto.', 'Mastery full: +1 subtrait.')}'
        : ' ${t('Maestria avanzata.', 'Mastery advanced.')}';
    statoForzaLog = registraTiroStatoForza();
    final expText = applicaEsperienzaFlat(
      expGuadagnata,
      motivo: t('Tiro superato', 'Successful roll'),
    );
    var adaptationCriticalText = '';
    if (stat.id == 'adattamento') {
      final outcome = oculumApplyAdaptationCritical(
        naturalRoll: dado,
        combatActive: currentCombatIsActive(),
        ownerSheetId: currentTemporaryResistanceOwnerSheetId(),
        effects: temporaryCombatResistanceEffects,
      );
      if (outcome.isNaturalCritical) {
        adaptationCriticalText = outcome.applied || outcome.alreadyActive
            ? '\n${t('CRITICO DI ADATTAMENTO: Resistenza Temporanea a tutti i danni ottenuta fino alla fine del combattimento.', 'ADAPTATION CRITICAL: Temporary Resistance to all damage gained until the end of combat.')}'
            : '\n${t('CRITICO DI ADATTAMENTO: nessun combattimento attivo, effetto temporaneo non applicato.', 'ADAPTATION CRITICAL: no active combat, temporary effect not applied.')}';
      }
    }
    dadoMostrato = testoDado;
    dadoMostratoFacce = 20;
    tiroCriticoUno = dado == 1;
    tiroCriticoVenti = dado == 20;
    risultato =
        '$label: $testoDado$masteryText$statoForzaLog$adaptationCriticalText$expText';
    _applyDadoCentraleOverlayState(
      valore: testoDado,
      criticoUno: dado == 1,
      criticoVenti: dado == 20,
      facce: 20,
      reduceEffects: reduceDiceEffects,
    );
    aggiungiLog(
      'Tiro sottotratto $label: $testoDado.${oculumTiroLogLabel(oculumSpend)}$masteryText$statoForzaLog$adaptationCriticalText$expText',
    );
    registerValidRoll();
    notifyDiceResultChanged();
    notifyDiceOverlayChanged();
    _scheduleDadoCentraleOverlayTimers(reduceEffects: reduceDiceEffects);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (masteryGain > 0 || statoForzaLog.isNotEmpty) {
        scheduleCombatRollSave();
      }
      scheduleCombatRollRealtime(
        label: label,
        roll: dado,
        bonus:
            bonus +
            criticalDieModifier(dado, 20) +
            modificatoreDifficoltaTiro(),
        total: totale,
        afterCurrentFrame: false,
      );
    });
  }

  void scheduleCombatRollRealtime({
    required String label,
    required int roll,
    required int bonus,
    required int total,
    bool afterCurrentFrame = true,
  }) {
    void enqueueAfterUiSettles() {
      Future<void>.delayed(const Duration(milliseconds: 120), () {
        if (!mounted) return;
        unawaited(
          sendRealtimeDiceRollWithMasterConsent(
            label: label,
            roll: roll,
            bonus: bonus,
            total: total,
          ),
        );
      });
    }

    if (!afterCurrentFrame) {
      enqueueAfterUiSettles();
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      enqueueAfterUiSettles();
    });
  }

  Future<void> tiraAiutaCompagno() async {
    final dado = Random().nextInt(10) + 1;
    final livello = max(0, leggiNumero(livelloController));
    final grado = max(0, leggiNumero(gradoController));
    final bonusGlobale = tiroGlobaleBonus();
    final bonus = livello + grado * 6 + bonusGlobale;
    final totale = rollTotalWithCritical(dado, 10, [
      livello,
      grado * 6,
      bonusGlobale,
    ]);
    final testoDado = rollFormulaWithCritical(
      roll: dado,
      faces: 10,
      bonuses: [livello, grado * 6, bonusGlobale],
    );
    final label = t('Aiuta compagno', 'Help ally');

    var statoForzaLog = '';
    setState(() {
      statoForzaLog = registraTiroStatoForza();
      dadoMostrato = testoDado;
      dadoMostratoFacce = 10;
      tiroCriticoUno = dado == 1;
      tiroCriticoVenti = dado == 10;
      risultato = '$label: $testoDado$statoForzaLog';
      aggiungiLog('Tiro $label: $testoDado.$statoForzaLog');
    });
    registerValidRoll();
    if (statoForzaLog.isNotEmpty) {
      programmaSalvataggio();
    }

    mostraDadoCentrale(
      valore: testoDado,
      criticoUno: dado == 1,
      criticoVenti: dado == 10,
      facce: 10,
    );
    await sendRealtimeDiceRollWithMasterConsent(
      label: label,
      roll: dado,
      bonus:
          bonus + criticalDieModifier(dado, 10) + modificatoreDifficoltaTiro(),
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
    return livello + grado * 6 + sheetRebirthLevelBonusAt(index);
  }

  int sheetRebirthLevelBonusAt(int index) {
    if (index < 0 || index >= schedePersonaggio.length) return 0;
    final rebirthed = index == schedaCorrente
        ? rebirthato
        : readBoolValue(schedePersonaggio[index]['rebirthato']);
    if (!rebirthed) return 0;
    return max(0, sheetIntValueAt(index, 'livello')) * 2;
  }

  int sheetCriticalLevelAt(int index) {
    return max(
      0,
      sheetIntValueAt(index, 'livello') + sheetRebirthLevelBonusAt(index),
    );
  }

  int sheetDifficoltaTiroAt(int index) {
    if (index < 0 || index >= schedePersonaggio.length) return 0;
    if (index == schedaCorrente) return difficoltaTiro();
    return readIntValue(schedePersonaggio[index]['difficoltaTiro']);
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
      case 'downed':
        return t('A terra', 'Downed');
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
      case 'downed':
        return Colors.deepOrangeAccent;
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

  int masterInitiativeTokenSize(Map<String, dynamic> token) {
    return readIntValue(token['tokenSize'], fallback: 54).clamp(36, 96).toInt();
  }

  bool masterInitiativeTokenUsesHex(Map<String, dynamic> token) {
    final side = '${token['side'] ?? 'ally'}'.toLowerCase();
    final type = '${token['type'] ?? ''}'.toLowerCase();
    return side == 'enemy' ||
        type.contains('mostro') ||
        type.contains('monster') ||
        type.contains('boss') ||
        type.contains('nemic') ||
        type.contains('enemy');
  }

  String masterInitiativeTokenSpriteAsset(Map<String, dynamic> token) {
    final existing = '${token['spriteAssetPath'] ?? ''}'.trim();
    if (existing.isNotEmpty) return existing;
    if (!masterInitiativeTokenUsesHex(token)) return '';

    final matched = monsterBookSpriteAssetForText(
      '${token['name'] ?? ''} ${token['type'] ?? ''} ${token['notes'] ?? ''}',
      variantSeed: monsterSpriteStableSeed('${token['id'] ?? ''}'),
    );
    if (matched.isNotEmpty) return matched;

    return '';
  }

  void setMasterInitiativeTokenSize(int index, int value) {
    if (index < 0 || index >= masterInitiativeTokens.length) return;
    setState(() {
      final token = masterInitiativeTokens[index];
      token['tokenSize'] = value.clamp(36, 96).toInt();
      token['updatedAt'] = DateTime.now().toIso8601String();
    });
    programmaSalvataggio();
    sendRealtimeInitiativeSnapshotIfPublished();
  }

  void adjustMasterInitiativeTokenSize(int index, int delta) {
    if (index < 0 || index >= masterInitiativeTokens.length) return;
    final current = masterInitiativeTokenSize(masterInitiativeTokens[index]);
    setMasterInitiativeTokenSize(index, current + delta);
  }

  int masterInitiativeReactionMax(Map<String, dynamic> token) {
    return max(1, readIntValue(token['reactionMax'], fallback: 1));
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
    resetLocalMapMovementForInitiativeToken(token);
  }

  bool masterInitiativeActionUsed(Map<String, dynamic> token) {
    return readBoolValue(token['actionUsed']);
  }

  bool masterInitiativeCanToggleAction(int index) {
    if (index < 0 || index >= masterInitiativeTokens.length) return false;
    return masterInitiativeTokenCanAct(masterInitiativeTokens[index]);
  }

  bool masterInitiativeCanUseReaction(int index) {
    if (index < 0 || index >= masterInitiativeTokens.length) return false;
    final token = masterInitiativeTokens[index];
    return masterInitiativeTokenCanAct(token) &&
        !masterInitiativeTokenIsTemporary(token);
  }

  bool masterInitiativeCanDuplicateAction(int index) {
    if (index < 0 || index >= masterInitiativeTokens.length) return false;
    final token = masterInitiativeTokens[index];
    if (masterInitiativeTokenIsDead(token) ||
        masterInitiativeTokenIsTemporary(token)) {
      return false;
    }

    return masterInitiativeDuplicateActionsUsedThisRound(token) <
        masterInitiativeReactionCapacity(token);
  }

  int masterInitiativeDuplicateActionsUsedThisRound(
    Map<String, dynamic> token,
  ) {
    final fallbackSourceId = '${token['id'] ?? token['sheetTag'] ?? ''}';
    final sourceId = '${token['sourceTokenId'] ?? fallbackSourceId}';
    return masterInitiativeTokens.where((item) {
      if (!masterInitiativeTokenIsTemporary(item)) return false;
      final sameSource = '${item['sourceTokenId'] ?? ''}' == sourceId;
      final sameRound =
          readIntValue(item['expiresRound'], fallback: masterInitiativeRound) ==
          masterInitiativeRound;
      return sameSource && sameRound;
    }).length;
  }

  void reindexMasterInitiativeTokens() {
    for (int i = 0; i < masterInitiativeTokens.length; i++) {
      masterInitiativeTokens[i]['manualOrder'] = i;
    }
  }

  int firstAliveMasterInitiativeIndex() {
    return masterInitiativeTokens.indexWhere(masterInitiativeTokenCanAct);
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
      token['tokenSize'] = masterInitiativeTokenSize(token);
      token['spriteAssetPath'] = masterInitiativeTokenSpriteAsset(token);
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
      token['level'] = sheetIndex >= 0
          ? sheetCriticalLevelAt(sheetIndex)
          : max(0, readIntValue(token['level']));
      token['grade'] = sheetIndex >= 0
          ? max(0, sheetIntValueAt(sheetIndex, 'grado'))
          : max(0, readIntValue(token['grade']));
      final reactionManual = readBoolValue(token['reactionManual']);
      final reactionFastManual = readBoolValue(token['reactionFastManual']);
      token['reactionManual'] = reactionManual;
      token['reactionFastManual'] = reactionFastManual;
      token['reactionMax'] = reactionManual || sheetIndex < 0
          ? max(1, readIntValue(token['reactionMax'], fallback: 1))
          : max(1, sheetReazioniAt(sheetIndex));
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
      normalizeMasterInitiativeDeathState(token);
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

  String monsterBookSpriteAssetForText(String raw, {int variantSeed = 0}) {
    // Le immagini scelte manualmente restano nei dati. Non assegnare più
    // sprite automatici in base a nome, tipo o descrizione del mostro.
    return '';
  }

  void updateMasterInitiativeToken({
    required int index,
    required int roll,
    required int base,
    required int total,
  }) {
    final tag = sheetTagAt(index);
    final sheetNotes = index == schedaCorrente
        ? notePersonaggioController.text.trim()
        : '${schedePersonaggio[index]['notePersonaggio'] ?? schedePersonaggio[index]['background'] ?? ''}'
              .trim();
    final storedSprite = '${schedePersonaggio[index]['spriteAssetPath'] ?? ''}'
        .trim();
    final token = <String, dynamic>{
      'id': tag,
      'sheetTag': tag,
      'name': nomeSchedaPersonaggio(index),
      'type': tipoSchedaPersonaggio(index),
      'side': sheetSideAt(index),
      'imageBase64': sheetImageBase64At(index),
      'spriteAssetPath': storedSprite.isNotEmpty
          ? storedSprite
          : monsterBookSpriteAssetForText(
              '${nomeSchedaPersonaggio(index)} ${tipoSchedaPersonaggio(index)} $sheetNotes',
              variantSeed: monsterSpriteStableSeed('$tag $sheetNotes'),
            ),
      'tokenSize': 54,
      'level': sheetCriticalLevelAt(index),
      'grade': max(0, sheetIntValueAt(index, 'grado')),
      'rollDifficulty': sheetDifficoltaTiroAt(index),
      'initiativeRoll': roll,
      'initiativeBase': base,
      'initiativeTotal': total,
      'tieBreaker': Random().nextInt(1 << 31),
      'status': 'ready',
      'notes': sheetNotes,
      'reactionMax': sheetReazioniAt(index),
      'reactionFastMax': sheetReazioniVelociAt(index),
      'reactionUsed': 0,
      'reactionFastUsed': 0,
      'reactionFastTurnKey': '',
      'actionUsed': false,
      'currentHp': sheetCurrentHpForDeathAt(index),
      'maxHp': sheetMaxHpForDeathAt(index),
      'currentOculum': sheetCurrentOculumForDeathAt(index),
      'maxOculum': sheetMaxOculumForDeathAt(index),
      'shield': index == schedaCorrente
          ? scudo()
          : readIntValue(schedePersonaggio[index]['scudo']),
      'will': sheetWillForDeathAt(index),
      'materia': sheetMateriaForDeathAt(index),
      'deathWounds': index == schedaCorrente
          ? feriteMorte
          : readIntValue(schedePersonaggio[index]['feriteMorte']),
      'vitalWills': index == schedaCorrente
          ? volontaVitale
          : readIntValue(schedePersonaggio[index]['volontaVitale']),
      'downed': index == schedaCorrente
          ? schedaAttivaCaduta
          : readBoolValue(schedePersonaggio[index]['personaggioCaduto']) ||
                sheetCurrentHpForDeathAt(index) <= 0,
      'reportedTurn': index == schedaCorrente
          ? playerReportedTurn
          : max(
              0,
              readIntValue(schedePersonaggio[index]['playerReportedTurn']),
            ),
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
      token['tokenSize'] = previous['tokenSize'] ?? token['tokenSize'];
      token['spriteAssetPath'] =
          '${previous['spriteAssetPath'] ?? ''}'.trim().isEmpty
          ? token['spriteAssetPath']
          : previous['spriteAssetPath'];
      token['notes'] = '${previous['notes'] ?? ''}'.trim().isEmpty
          ? sheetNotes
          : previous['notes'];
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
      token['deathWounds'] = previous['deathWounds'] ?? token['deathWounds'];
      token['vitalWills'] = previous['vitalWills'] ?? token['vitalWills'];
      token['downed'] = previous['downed'] ?? token['downed'];
      token['reportedTurn'] = previous['reportedTurn'] ?? token['reportedTurn'];
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

    final roll = rollInitiative ? tiraD20(countsAsCooldownRoll: false) : 0;
    final base = sheetRollBonusAt(index, 'iniziativa');
    final level = sheetCriticalLevelAt(index);
    final grade = max(0, sheetIntValueAt(index, 'grado'));
    final difficulty = sheetDifficoltaTiroAt(index);
    final total = rollInitiative
        ? rollTotalWithCritical(
            roll,
            20,
            [base],
            level: level,
            grade: grade,
            difficulty: difficulty,
          )
        : base;
    final rollText = rollInitiative
        ? rollFormulaWithCritical(
            roll: roll,
            faces: 20,
            bonuses: [base],
            level: level,
            grade: grade,
            difficulty: difficulty,
          )
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
    final roll = tiraD20(countsAsCooldownRoll: false);
    final level = activeCriticalLevel();
    final grade = activeCriticalGrade();
    final difficulty = difficoltaTiro();
    final total = rollTotalWithCritical(
      roll,
      20,
      [bonus],
      level: level,
      grade: grade,
      difficulty: difficulty,
    );

    setState(() {
      masterInitiativeTokens.add({
        'id':
            'manual_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(999999)}',
        'name': name,
        'type': type,
        'side': masterInitiativeSideFromType(type),
        'imageBase64': '',
        'spriteAssetPath': monsterBookSpriteAssetForText(
          '$name $type ${masterInitiativeNotesController.text}',
          variantSeed: monsterSpriteStableSeed('$name $type'),
        ),
        'tokenSize': 54,
        'level': level,
        'grade': grade,
        'rollDifficulty': difficulty,
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
        'currentHp': 1,
        'maxHp': 1,
        'currentOculum': 0,
        'maxOculum': 0,
        'shield': 0,
        'will': 0,
        'materia': 0,
        'deathWounds': 0,
        'vitalWills': 0,
        'downed': false,
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

        final roll = tiraD20(countsAsCooldownRoll: false);
        final base = readIntValue(token['initiativeBase']);
        final level = readIntValue(token['level']);
        final grade = readIntValue(token['grade']);
        final difficulty = readIntValue(token['rollDifficulty']);
        token['initiativeRoll'] = roll;
        token['initiativeTotal'] = rollTotalWithCritical(
          roll,
          20,
          [base],
          level: level,
          grade: grade,
          difficulty: difficulty,
        );
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
        if (masterInitiativeTokenCanAct(
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
      if (!masterInitiativeTokenCanAct(masterInitiativeTokens[index])) {
        risultato = t(
          'Un partecipante a terra o morto non puo ricevere il turno attivo.',
          'A downed or dead participant cannot receive the active turn.',
        );
        aggiungiLog(risultato);
        return;
      }
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
      if (delta > 0) {
        for (final token in masterInitiativeTokens) {
          if (masterInitiativeTokenIsDowned(token)) {
            resolveMasterInitiativeDeathSaveInPlace(token);
          }
        }
        normalizeMasterInitiativeTokens();
      }
      if (firstAliveMasterInitiativeIndex() < 0) {
        risultato = t(
          'Nessun partecipante in piedi: i caduti hanno effettuato il tiro contro la morte.',
          'Nobody is standing: downed participants made their death save.',
        );
        aggiungiLog(risultato);
        return;
      }
      final current = masterInitiativeActiveIndex
          .clamp(0, masterInitiativeTokens.length - 1)
          .toInt();
      if (masterInitiativeTokenCanAct(masterInitiativeTokens[current])) {
        masterInitiativeTokens[current]['status'] = delta > 0
            ? 'acted'
            : 'ready';
      }

      var next = current;
      for (int step = 0; step < masterInitiativeTokens.length; step++) {
        next = (next + delta) % masterInitiativeTokens.length;
        if (next < 0) next += masterInitiativeTokens.length;
        if (masterInitiativeTokenCanAct(masterInitiativeTokens[next])) break;
      }

      if (delta > 0 && next <= current) {
        masterInitiativeRound++;
        removeExpiredTemporaryInitiativeTurns();
        for (final token in masterInitiativeTokens) {
          if (masterInitiativeTokenCanAct(token)) token['status'] = 'ready';
        }
        next = 0;
        for (int step = 0; step < masterInitiativeTokens.length; step++) {
          if (masterInitiativeTokenCanAct(masterInitiativeTokens[next])) break;
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
        if (masterInitiativeTokenCanAct(token)) token['status'] = 'ready';
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
        if (masterInitiativeTokenCanAct(token)) {
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
        'spriteAssetPath': masterInitiativeTokenSpriteAsset(source),
        'tokenSize': masterInitiativeTokenSize(source),
        'initiativeRoll': source['initiativeRoll'] ?? 0,
        'initiativeBase': source['initiativeBase'] ?? 0,
        'initiativeTotal': source['initiativeTotal'] ?? 0,
        'rollDifficulty': source['rollDifficulty'] ?? 0,
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
      final duplicatesUsed = masterInitiativeDuplicateActionsUsedThisRound(
        source,
      );
      final duplicateCapacity = masterInitiativeReactionCapacity(source);
      risultato =
          '${t('Azione duplicata', 'Action duplicated')}: $name, ${t('subito dopo il turno attivo', 'right after the active turn')} ($duplicatesUsed/$duplicateCapacity).';
      aggiungiLog(risultato);
    });

    programmaSalvataggio();
    sendRealtimeInitiativeSnapshotIfPublished();
  }

  void clearMasterInitiativeTokens() {
    setState(() {
      masterInitiativeTokens.clear();
      clearTemporaryCombatResistanceEffects();
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
    if (index < 0 || index >= schedePersonaggio.length) {
      return;
    }
    final dado = tiraD20();
    final bonus = sheetRollBonusAt(index, key);
    final level = sheetCriticalLevelAt(index);
    final grade = max(0, sheetIntValueAt(index, 'grado'));
    final difficulty = sheetDifficoltaTiroAt(index);
    final totale = rollTotalWithCritical(
      dado,
      20,
      [bonus],
      level: level,
      grade: grade,
      difficulty: difficulty,
    );
    final testoDado = rollFormulaWithCritical(
      roll: dado,
      faces: 20,
      bonuses: [bonus],
      level: level,
      grade: grade,
      difficulty: difficulty,
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
      bonus:
          bonus +
          criticalDieModifier(dado, 20, level: level, grade: grade) +
          modificatoreDifficoltaTiro(difficulty: difficulty),
      total: totale,
    );
  }

  Future<void> tiraMasterInitiativeHelp(
    int tokenIndex, {
    bool reaction = false,
  }) async {
    if (tokenIndex < 0 || tokenIndex >= masterInitiativeTokens.length) {
      return;
    }
    String label = t('Aiuta compagno', 'Help ally');
    String name = '???';
    String testoDado = '';
    int dado = 0;
    int bonus = 0;
    int totale = 0;
    int difficultyForSend = 0;
    var ok = false;

    setState(() {
      normalizeMasterInitiativeTokens();
      if (tokenIndex >= masterInitiativeTokens.length) return;
      final token = masterInitiativeTokens[tokenIndex];
      name = '${token['name'] ?? '???'}';
      if (!masterInitiativeTokenCanAct(token)) {
        risultato = t(
          'Questo partecipante non puo aiutare ora.',
          'This participant cannot help now.',
        );
        aggiungiLog(risultato);
        return;
      }

      if (reaction) {
        if (!masterInitiativeCanUseReaction(tokenIndex)) {
          risultato = t(
            'Questo partecipante non puo usare reazioni.',
            'This participant cannot use reactions.',
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
        if (normalAvailable + fastAvailable <= 0) {
          risultato = t(
            'Nessuna reazione disponibile per aiutare.',
            'No reaction available to help.',
          );
          aggiungiLog(risultato);
          return;
        }
        if (normalAvailable > 0) {
          token['reactionUsed'] = normalUsed + 1;
          token['reactionUsedRound'] = masterInitiativeRound;
        } else {
          token['reactionFastUsed'] = fastUsed + 1;
          token['reactionFastTurnKey'] = masterInitiativeTurnKey();
        }
        token['reactionAt'] = DateTime.now().toIso8601String();
        label = t('Aiuta con reazione', 'Help with reaction');
      } else {
        if (masterInitiativeActionUsed(token)) {
          risultato = t(
            'Azione gia usata: puoi aiutare con una reazione se disponibile.',
            'Action already used: you can help with a reaction if available.',
          );
          aggiungiLog(risultato);
          return;
        }
        token['actionUsed'] = true;
      }

      final sheetTag = '${token['sheetTag'] ?? ''}';
      final sheetIndex = sheetTag.isEmpty
          ? -1
          : schedePersonaggio.indexWhere(
              (sheet) => '${sheet['sheetTag'] ?? ''}' == sheetTag,
            );
      final level = sheetIndex >= 0
          ? max(0, sheetIntValueAt(sheetIndex, 'livello'))
          : max(0, readIntValue(token['level']));
      final grade = sheetIndex >= 0
          ? max(0, sheetIntValueAt(sheetIndex, 'grado'))
          : max(0, readIntValue(token['grade']));
      final difficulty = sheetIndex >= 0
          ? sheetDifficoltaTiroAt(sheetIndex)
          : readIntValue(token['rollDifficulty']);
      difficultyForSend = difficulty;
      dado = Random().nextInt(10) + 1;
      bonus = level + grade * 6;
      totale = rollTotalWithCritical(dado, 10, [
        level,
        grade * 6,
      ], difficulty: difficulty);
      testoDado = rollFormulaWithCritical(
        roll: dado,
        faces: 10,
        bonuses: [level, grade * 6],
        difficulty: difficulty,
      );
      dadoMostrato = testoDado;
      dadoMostratoFacce = 10;
      tiroCriticoUno = dado == 1;
      tiroCriticoVenti = dado == 10;
      token['updatedAt'] = DateTime.now().toIso8601String();
      risultato = '$name - $label: $testoDado';
      aggiungiLog(risultato);
      ok = true;
    });

    programmaSalvataggio();
    sendRealtimeInitiativeSnapshotIfPublished();
    if (!ok) return;

    mostraDadoCentrale(
      valore: testoDado,
      criticoUno: dado == 1,
      criticoVenti: dado == 10,
      facce: 10,
    );
    await sendRealtimeDiceRollWithMasterConsent(
      label: '$name $label',
      roll: dado,
      bonus:
          bonus +
          criticalDieModifier(dado, 10) +
          modificatoreDifficoltaTiro(difficulty: difficultyForSend),
      total: totale,
    );
  }

  Future<void> tiraMasterInitiativeTokenQuickRoll(
    int tokenIndex,
    String key,
  ) async {
    if (tokenIndex < 0 || tokenIndex >= masterInitiativeTokens.length) {
      return;
    }
    normalizeMasterInitiativeTokens();
    final token = masterInitiativeTokens[tokenIndex];
    final sheetTag = '${token['sheetTag'] ?? ''}';
    final sheetIndex = sheetTag.isEmpty
        ? -1
        : schedePersonaggio.indexWhere(
            (sheet) => '${sheet['sheetTag'] ?? ''}' == sheetTag,
          );
    if (sheetIndex >= 0) {
      await tiraSchedaMasterParty(sheetIndex, key);
      return;
    }

    final dado = tiraD20();
    final level = readIntValue(token['level']);
    final grade = readIntValue(token['grade']);
    final difficulty = readIntValue(token['rollDifficulty']);
    final bonus = readIntValue(
      token[key],
      fallback: readIntValue(token['initiativeBase']),
    );
    final totale = rollTotalWithCritical(
      dado,
      20,
      [bonus],
      level: level,
      grade: grade,
      difficulty: difficulty,
    );
    final testoDado = rollFormulaWithCritical(
      roll: dado,
      faces: 20,
      bonuses: [bonus],
      level: level,
      grade: grade,
      difficulty: difficulty,
    );
    final label = sheetRollLabel(key);
    final name = '${token['name'] ?? '???'}';

    setState(() {
      dadoMostrato = testoDado;
      dadoMostratoFacce = 20;
      tiroCriticoUno = dado == 1;
      tiroCriticoVenti = dado == 20;
      risultato = '$name • $label: $testoDado';
      aggiungiLog('Tiro turnistica $name [$label]: $testoDado.');
    });

    mostraDadoCentrale(
      valore: testoDado,
      criticoUno: dado == 1,
      criticoVenti: dado == 20,
    );
    await sendRealtimeDiceRollWithMasterConsent(
      label: '$name $label',
      roll: dado,
      bonus:
          bonus +
          criticalDieModifier(dado, 20, level: level, grade: grade) +
          modificatoreDifficoltaTiro(difficulty: difficulty),
      total: totale,
    );
  }
  // =====================================================
  // DANNI / CURA / SCUDO CRITICO
  // =====================================================

  String canonicalDamageModifierName(String raw) {
    final value = cleanUiText(raw).trim().toLowerCase();

    const aliases = {
      'fragilita letale': 'Fragilità Letale',
      'fragilità letale': 'Fragilità Letale',
      'fragilita semi letale': 'Fragilità Semi Letale',
      'fragilità semi letale': 'Fragilità Semi Letale',
      'fragilita distruttiva': 'Fragilità Distruttiva',
      'fragilità distruttiva': 'Fragilità Distruttiva',
      'fragilita assoluta': 'Fragilità Assoluta',
      'fragilità assoluta': 'Fragilità Assoluta',
      'fragilita estrema': 'Fragilità Estrema',
      'fragilità estrema': 'Fragilità Estrema',
      'fragilita alta': 'Alta Fragilità',
      'fragilità alta': 'Alta Fragilità',
      'alta fragilita': 'Alta Fragilità',
      'alta fragilità': 'Alta Fragilità',
      'fragilita normale': 'Fragilità',
      'fragilità normale': 'Fragilità',
      'fragilita': 'Fragilità',
      'fragilità': 'Fragilità',
      'fragilita bassa': 'Bassa Fragilità',
      'fragilità bassa': 'Bassa Fragilità',
      'bassa fragilita': 'Bassa Fragilità',
      'bassa fragilità': 'Bassa Fragilità',
      'normale': 'Normale',
      'resistenza leggera': 'Resistenza Leggera',
      'resistenza normale': 'Resistenza',
      'resistenza': 'Resistenza',
      'resistenza alta': 'Alta Resistenza',
      'alta resistenza': 'Alta Resistenza',
      'semi perfetta': 'Resistenza Semi Perfetta',
      'resistenza semi perfetta': 'Resistenza Semi Perfetta',
      'impenetrabile': 'Resistenza Impenetrabile',
      'resistenza impenetrabile': 'Resistenza Impenetrabile',
      'immunita': 'Immunità',
      'immunità': 'Immunità',
      'rigenerazione leggera': 'Rigenerazione Leggera',
      'rigenerazione normale': 'Rigenerazione',
      'rigenerazione': 'Rigenerazione',
      'rigenerazione alta': 'Alta Rigenerazione',
      'alta rigenerazione': 'Alta Rigenerazione',
      'rigenerazione molto forte': 'Rigenerazione Molto Forte',
      'rigenerazione semi perfetta': 'Rigenerazione Semi Perfetta',
      'rigenerazione perfetta': 'Rigenerazione Perfetta',
    };

    final aliased = aliases[value];
    if (aliased != null) return aliased;

    return modificatoriDanno
        .firstWhere(
          (x) => x.name.toLowerCase() == value,
          orElse: () =>
              modificatoriDanno.firstWhere((x) => x.name == 'Normale'),
        )
        .name;
  }

  DamageModifierOption modificatoreDannoAttuale() {
    final canonical = canonicalDamageModifierName(modificatoreDannoSelezionato);
    return modificatoriDanno.firstWhere(
      (x) => x.name == canonical,
      orElse: () => modificatoriDanno.firstWhere((x) => x.name == 'Normale'),
    );
  }

  DamageModifierOption modificatoreDannoDaNome(String nome) {
    final canonical = canonicalDamageModifierName(nome);
    return modificatoriDanno.firstWhere(
      (x) => x.name == canonical,
      orElse: () => modificatoriDanno.firstWhere((x) => x.name == 'Normale'),
    );
  }

  List<String> scalaCriticaDanno() {
    return const [
      'Rigenerazione Perfetta',
      'Rigenerazione Semi Perfetta',
      'Rigenerazione Molto Forte',
      'Alta Rigenerazione',
      'Rigenerazione',
      'Rigenerazione Leggera',
      'Immunità',
      'Resistenza Impenetrabile',
      'Resistenza Semi Perfetta',
      'Alta Resistenza',
      'Resistenza',
      'Resistenza Leggera',
      'Normale',
      'Bassa Fragilità',
      'Fragilità',
      'Alta Fragilità',
      'Fragilità Estrema',
      'Fragilità Assoluta',
      'Fragilità Distruttiva',
      'Fragilità Semi Letale',
      'Fragilità Letale',
    ];
  }

  String prossimoStadioCriticoDanno(String attuale) {
    final scala = scalaCriticaDanno();
    final indice = scala.indexOf(canonicalDamageModifierName(attuale));

    if (indice < 0) return 'Bassa Fragilità';
    if (indice >= scala.length - 1) return scala.last;

    return scala[indice + 1];
  }

  DamageModifierOption prossimoStadioCriticoPercentualeLibera(
    double multiplier,
  ) {
    final next = oculumNextCriticalDamageMultiplier(multiplier);
    return modificatoriDanno.firstWhere(
      (option) => (option.multiplier - next).abs() < 0.000001,
      orElse: () => modificatoriDanno.firstWhere(
        (option) => option.name == 'Fragilità Letale',
      ),
    );
  }

  String testoPercentualeDannoLibera(double multiplier) {
    final percent = ((multiplier - 1) * 100).round();
    return percent > 0 ? '+$percent%' : '$percent%';
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
    final percentMultiplier = oculumIncomingDamagePercentMultiplier(
      dannoSubitoPercentController.text,
    );
    if (percentMultiplier != null) {
      return applicaModificatoreDannoPercentuale(dannoBase, percentMultiplier);
    }
    return applicaModificatoreDannoCon(dannoBase, modificatoreDannoAttuale());
  }

  int applicaModificatoreDannoPercentuale(int dannoBase, double multiplier) {
    if (dannoBase <= 0) return 0;
    final modified = dannoBase * multiplier;
    if (modified > 0 && modified < 1) return 1;
    return modified.round();
  }

  String normalizedDamageRuleText(String raw) {
    return cleanUiText(raw)
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('-', '')
        .replaceAll('_', '')
        .replaceAll('à', 'a')
        .replaceAll('è', 'e')
        .replaceAll('é', 'e')
        .replaceAll('ì', 'i')
        .replaceAll('ò', 'o')
        .replaceAll('ù', 'u');
  }

  double damageRuleMultiplierForCommand(String command) {
    switch (normalizedDamageRuleText(command)) {
      case 'resistenzaleggera':
        return 0.90;
      case 'resistenza':
      case 'resistenzanormale':
        return 0.75;
      case 'altaresistenza':
      case 'resistenzaalta':
        return 0.50;
      case 'resistenzasemiperfetta':
      case 'semiperfetta':
        return 0.25;
      case 'resistenzaimpenetrabile':
      case 'impenetrabile':
        return 0.10;
      case 'immunita':
        return 0.0;
      case 'fragilitabassa':
        return 1.10;
      case 'fragilita':
        return 1.25;
      case 'fragilitavera':
      case 'altafragilita':
        return 1.50;
      case 'fragilitaestrema':
        return 1.75;
      case 'fragilitaassoluta':
        return 1.90;
      case 'fragilitadistruttiva':
        return 2.00;
      case 'fragilitasemiletale':
        return 3.50;
      case 'fragilitaletale':
        return 6.00;
      default:
        return 1.0;
    }
  }

  bool isIncomingDamageParserCommand(String command) {
    final normalized = normalizedDamageRuleText(command);
    return normalized.startsWith('resistenza') ||
        normalized.startsWith('fragilita') ||
        normalized == 'immunita' ||
        normalized == 'impenetrabile' ||
        normalized == 'dannisubiti';
  }

  String normalizeDamageElementKey(String raw) {
    final value = normalizedDamageRuleText(raw);
    switch (value) {
      case 'fisico':
      case 'physical':
      case 'normale':
      case 'neutral':
        return 'fisico';
      case 'fire':
        return 'fuoco';
      case 'water':
        return 'acqua';
      case 'lightning':
      case 'fulmine':
        return 'fulmine';
      default:
        return value;
    }
  }

  bool incomingDamageRuleMatchesElement(String ruleElement, String active) {
    final rule = normalizeDamageElementKey(ruleElement);
    if (rule.isEmpty || rule == 'tutto' || rule == 'all') return true;
    final activeKey = normalizeDamageElementKey(active);
    final activeName = normalizeDamageElementKey(elementDisplayName(active));
    return rule == activeKey || rule == activeName;
  }

  List<({String command, String value, String element})> incomingDamageRules() {
    final text = activeQuickCommandText();
    if (!text.contains('@')) return const [];
    final cached = incomingDamageRulesCache[text];
    if (cached != null) return cached;
    final matches = _oculumIncomingDamageRulePattern.allMatches(text);
    final rules = <({String command, String value, String element})>[];
    for (final match in matches) {
      final command = (match.group(1) ?? '').trim();
      if (!isIncomingDamageParserCommand(command)) continue;
      final value = (match.group(2) ?? '').replaceAll(' ', '').trim();
      final element = (match.group(3) ?? '').trim();
      rules.add((command: command, value: value, element: element));
    }
    final result =
        List<({String command, String value, String element})>.unmodifiable(
          rules,
        );
    if (incomingDamageRulesCache.length >= 32) {
      incomingDamageRulesCache.clear();
    }
    incomingDamageRulesCache[text] = result;
    return result;
  }

  List<({String command, String value, String element})>
  activeIncomingDamageRules(String element) {
    return incomingDamageRules()
        .where(
          (rule) => incomingDamageRuleMatchesElement(rule.element, element),
        )
        .toList();
  }

  int applicaParserDanniSubiti(int damage, String element) {
    if (damage <= 0) return damage;
    var result = damage;
    for (final rule in activeIncomingDamageRules(element)) {
      final command = normalizedDamageRuleText(rule.command);
      if (command == 'dannisubiti') {
        if (rule.value.endsWith('%')) {
          final raw = rule.value.substring(0, rule.value.length - 1);
          final percent = int.tryParse(raw) ?? 0;
          result = max(0, (result * (1 + percent / 100)).round());
        } else {
          final delta = int.tryParse(rule.value) ?? 0;
          result = max(0, result + delta);
        }
      } else {
        final multiplier = damageRuleMultiplierForCommand(rule.command);
        result = max(0, (result * multiplier).round());
      }
    }
    return result;
  }

  String incomingDamageRulesSummary([String? element]) {
    final rules = element == null
        ? incomingDamageRules()
        : activeIncomingDamageRules(element);
    if (rules.isEmpty) return '';
    return rules
        .map((rule) {
          final value = rule.value.isEmpty ? '' : rule.value;
          final elementText = rule.element.isEmpty ? 'Tutto' : rule.element;
          return '@${rule.command}$value $elementText';
        })
        .join(' • ');
  }

  int currentOculumDayValue() {
    return max(1, leggiNumero(oculumCurrentDayController));
  }

  Iterable<String> activeOneShotNonItemCommandTexts() sync* {
    for (final titolo in titoli) {
      if (!titolo.equipaggiato) continue;
      yield* activeTitleQuickTexts(titolo);
    }
    for (final art in arti) {
      if (!art.sbloccata) continue;
      yield* activeArtQuickTexts(art);
    }
    for (final skill in skills) {
      if (!skill.equipaggiata) continue;
      yield* skillQuickCommandTexts(skill);
    }
    yield buffMalusRapidiController.text;
  }

  bool textHasSafeHpParserCommand(String text) {
    return _oculumSafeHpCommandPattern.hasMatch(text);
  }

  int textSaveShieldParserValue(String text) {
    final match = _oculumSaveShieldCommandPattern.firstMatch(text);
    if (match == null) return 0;
    return max(0, int.tryParse(match.group(1) ?? '') ?? 0);
  }

  bool hasSafeHpParserCommand() {
    if (activeOneShotNonItemCommandTexts().any(textHasSafeHpParserCommand)) {
      return true;
    }

    final day = currentOculumDayValue();
    return inventario.any(
      (item) =>
          item.equipaggiata &&
          item.safeHpUsedDay != day &&
          textHasSafeHpParserCommand(item.buff),
    );
  }

  int saveShieldParserValue() {
    for (final text in activeOneShotNonItemCommandTexts()) {
      final value = textSaveShieldParserValue(text);
      if (value > 0) return value;
    }

    final day = currentOculumDayValue();
    for (final item in inventario) {
      if (!item.equipaggiata || item.saveShieldUsedDay == day) continue;
      final value = textSaveShieldParserValue(item.buff);
      if (value > 0) return value;
    }
    return 0;
  }

  void consumeOneShotParserCommand(String command) {
    final source = buffMalusRapidiController.text;
    final pattern = command.toLowerCase() == 'saveshield'
        ? _oculumConsumeSaveShieldPattern
        : _oculumConsumeSafeHpPattern;
    final nextSource = source.replaceFirst(pattern, '').trim();
    if (nextSource != source.trim()) {
      buffMalusRapidiController.text = nextSource;
      return;
    }

    final day = currentOculumDayValue();
    for (final item in inventario) {
      if (!item.equipaggiata) continue;
      if (command.toLowerCase() == 'saveshield') {
        if (item.saveShieldUsedDay == day ||
            textSaveShieldParserValue(item.buff) <= 0) {
          continue;
        }
        item.saveShieldUsedDay = day;
        return;
      }
      if (item.safeHpUsedDay == day || !textHasSafeHpParserCommand(item.buff)) {
        continue;
      }
      item.safeHpUsedDay = day;
      return;
    }
  }

  int? leggiValoreDannoCura() {
    final raw = dannoSubitoController.text.trim();
    if (raw.isEmpty) return null;

    try {
      final value = oculumEvaluateFormula(raw, formulaValueContext());
      return oculumRoundFormulaResult(value);
    } catch (error) {
      setState(() {
        risultato = t(
          'Formula danno/cura non valida: $raw.',
          'Invalid damage/healing formula: $raw.',
        );
        aggiungiLog('$risultato ($error)');
      });
      return null;
    }
  }

  String dettaglioValoreDannoCura(int valore) {
    final raw = dannoSubitoController.text.trim();
    if (raw.isEmpty || raw == valore.toString()) return '$valore';
    return '$raw = $valore';
  }

  int applicaRiduzioneSchivataOculum(int danno) {
    final reduction = schivataOculumRiduzionePronta.clamp(0, 100).toInt();
    if (danno <= 0 || reduction <= 0) return danno;
    if (reduction >= 100) return 0;
    return max(0, (danno * (100 - reduction) / 100).ceil());
  }

  bool schivataOculumPronta() => schivataOculumRiduzionePronta > 0;

  String schivataOculumProntaLabel() {
    final label = schivataOculumEtichettaPronta.trim();
    final prefix = label.isEmpty ? '' : '$label, ';
    return '$prefix${schivataOculumRiduzionePronta.clamp(0, 100).toInt()}%';
  }

  void usaSchivataOculum({
    required String label,
    required int reductionPercent,
  }) {
    if (schivataOculumPronta()) {
      setState(() {
        risultato = t(
          'Schivata Oculum già pronta: ${schivataOculumProntaLabel()}. La carica è già stata consumata e non si rigenera.',
          'Oculum Dodge already ready: ${schivataOculumProntaLabel()}. The charge has already been consumed and does not regenerate.',
        );
        aggiungiLog(risultato);
      });
      return;
    }

    if (schivateOculumDisponibili() <= 0) {
      setState(() {
        risultato = t(
          'Nessuna Schivata Oculum disponibile.',
          'No Oculum Dodge available.',
        );
        aggiungiLog(risultato);
      });
      return;
    }

    setState(() {
      schivateOculumConsumate += 1;
      schivataOculumRiduzionePronta = reductionPercent.clamp(0, 100).toInt();
      schivataOculumEtichettaPronta = label;
      risultato = t(
        'Schivata Oculum consumata e pronta: $label, riduzione danni $schivataOculumRiduzionePronta%. Non si rigenera.',
        'Oculum Dodge consumed and ready: $label, $schivataOculumRiduzionePronta% damage reduction. It does not regenerate.',
      );
      aggiungiLog(risultato);
    });
    programmaSalvataggio();
  }

  Future<void> mostraMenuSchivataOculum() async {
    if (schivataOculumPronta()) {
      setState(() {
        risultato = t(
          'Schivata Oculum già pronta: ${schivataOculumProntaLabel()}. È un consumabile: verrà applicata al prossimo danno subito e non si rigenera.',
          'Oculum Dodge already ready: ${schivataOculumProntaLabel()}. It is a consumable: it will apply to the next damage taken and does not regenerate.',
        );
        aggiungiLog(risultato);
      });
      return;
    }

    if (schivateOculumDisponibili() <= 0) {
      setState(() {
        risultato = t(
          'Nessuna Schivata Oculum disponibile. Ne ottieni una ai gradi III, VI, IX, XII e cosi via, oppure con @SchivataOculum+1.',
          'No Oculum Dodge available. You gain one at grades III, VI, IX, XII and so on, or with @SchivataOculum+1.',
        );
        aggiungiLog(risultato);
      });
      return;
    }

    final choice = await showModalBottomSheet<(String, int)>(
      context: context,
      backgroundColor: const Color(0xFF10121A),
      builder: (sheetContext) {
        Widget tile({
          required String label,
          required String description,
          required int reduction,
          required IconData icon,
        }) {
          return ListTile(
            leading: Icon(icon, color: eyePupilGlowColor),
            title: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            subtitle: Text(
              description,
              style: TextStyle(color: Colors.grey.shade300),
            ),
            onTap: () => Navigator.pop(sheetContext, (label, reduction)),
          );
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.visibility, color: eyePupilGlowColor),
                  title: Text(
                    t('Schivata Oculum', 'Oculum Dodge'),
                    style: TextStyle(
                      color: eyePupilGlowColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  subtitle: Text(
                    t(
                      'Disponibili ${schivateOculumDisponibili()}/${schivateOculumTotali()}. Sono consumabili e non si rigenerano.',
                      'Available ${schivateOculumDisponibili()}/${schivateOculumTotali()}. They are consumables and do not regenerate.',
                    ),
                    style: TextStyle(color: Colors.grey.shade300),
                  ),
                ),
                tile(
                  label: 'Inferiore',
                  description: t(
                    'Immunita ai danni contro un grado inferiore.',
                    'Damage immunity against a lower grade.',
                  ),
                  reduction: 100,
                  icon: Icons.keyboard_double_arrow_down,
                ),
                tile(
                  label: 'Al tuo pari',
                  description: t(
                    'Riduci del 90% i danni contro un grado pari al tuo.',
                    'Reduce damage by 90% against your own grade.',
                  ),
                  reduction: 90,
                  icon: Icons.drag_handle,
                ),
                tile(
                  label: 'Forte',
                  description: t(
                    'Riduci del 75% i danni contro nemici fino a tre gradi maggiori.',
                    'Reduce damage by 75% against enemies up to three grades higher.',
                  ),
                  reduction: 75,
                  icon: Icons.trending_up,
                ),
                tile(
                  label: 'Impossibile',
                  description: t(
                    'Riduci del 50% i danni contro minacce oltre quel limite.',
                    'Reduce damage by 50% against threats beyond that limit.',
                  ),
                  reduction: 50,
                  icon: Icons.warning_amber,
                ),
              ],
            ),
          ),
        );
      },
    );

    if (choice == null) return;
    usaSchivataOculum(label: choice.$1, reductionPercent: choice.$2);
  }

  void attivaScudoSalvataggio() {
    setState(() {
      scudoSalvataggioAttivo = true;
      risultato = t(
        'Scudo di Salvataggio pronto: se il prossimo danno rompe il tuo ultimo scudo, il danno in eccesso non raggiunge HP temporanei o vita.',
        'Saving Shield ready: if the next damage breaks your last shield, overflow damage will not reach Temp HP or Life.',
      );
      aggiungiLog(risultato);
    });
    programmaSalvataggio();
  }

  void applicaDannoSubito({bool critico = false}) {
    final dannoInserito = leggiValoreDannoCura();

    if (dannoInserito == null || dannoInserito <= 0) return;

    final percentualeLiberaPrima = oculumIncomingDamagePercentMultiplier(
      dannoSubitoPercentController.text,
    );
    final stadioLiberoDopo = critico && percentualeLiberaPrima != null
        ? prossimoStadioCriticoPercentualeLibera(percentualeLiberaPrima)
        : null;
    final modificatorePrima = modificatoreDannoSelezionato;
    final modificatoreDopo =
        stadioLiberoDopo?.name ??
        (critico
            ? prossimoStadioCriticoDanno(modificatorePrima)
            : modificatorePrima);
    final riduzioneSchivata = schivataOculumRiduzionePronta;
    final schivataLabel = schivataOculumEtichettaPronta.trim();
    final dannoPrimaSchivata = dannoInserito + (critico ? 5 : 0);
    final dannoDopoSchivata = applicaRiduzioneSchivataOculum(
      dannoPrimaSchivata,
    );
    final dannoInArrivo = dannoDopoSchivata;
    final dannoInseritoLog = dettaglioValoreDannoCura(dannoInserito);
    final schivataLogIt = riduzioneSchivata > 0
        ? ' Schivata Oculum${schivataLabel.isEmpty ? "" : " $schivataLabel"}: -$riduzioneSchivata%, danno $dannoPrimaSchivata -> $dannoDopoSchivata.'
        : '';
    final schivataLogEn = riduzioneSchivata > 0
        ? ' Oculum Dodge${schivataLabel.isEmpty ? "" : " $schivataLabel"}: -$riduzioneSchivata%, damage $dannoPrimaSchivata -> $dannoDopoSchivata.'
        : '';
    final ignoraDifesa = dannoOltreDifesa;
    final ignoraScudi = dannoOltreScudi;
    final bonusScudi = bonusDannoScudiPercentuale();
    final dannoDopoDifesa = dannoInArrivo <= 0
        ? 0
        : ignoraDifesa
        ? dannoInArrivo
        : max(1, dannoInArrivo - difesa());
    final difesaLogIt = ignoraDifesa
        ? ' oltre Difesa = $dannoDopoDifesa'
        : ' - Difesa ${difesa()} = $dannoDopoDifesa';
    final difesaLogEn = ignoraDifesa
        ? ' beyond Defense = $dannoDopoDifesa'
        : ' - Defense ${difesa()} = $dannoDopoDifesa';
    final opzioniImpattoIt =
        '${ignoraScudi ? " Oltre Scudi: il danno salta Scudo Oculum e Scudo." : ""}'
        '${bonusScudi > 0 && !ignoraScudi ? " Danno agli scudi +$bonusScudi%." : ""}';
    final opzioniImpattoEn =
        '${ignoraScudi ? " Beyond Shields: damage skips Oculum Shield and Shield." : ""}'
        '${bonusScudi > 0 && !ignoraScudi ? " Shield damage +$bonusScudi%." : ""}';
    final modificatore = critico
        ? modificatoreDannoDaNome(modificatoreDopo)
        : modificatoreDannoAttuale();
    final modificatorePercentualeLibero =
        stadioLiberoDopo?.multiplier ?? percentualeLiberaPrima;
    final dannoModificatoBase = modificatorePercentualeLibero == null
        ? applicaModificatoreDannoCon(dannoDopoDifesa, modificatore)
        : applicaModificatoreDannoPercentuale(
            dannoDopoDifesa,
            modificatorePercentualeLibero,
          );
    final modificatoreNome = modificatorePercentualeLibero == null
        ? modificatore.name
        : '${((modificatorePercentualeLibero - 1) * 100).toStringAsFixed(0)}% danno ricevuto';
    final elementoAttivo = elementoDannoDominante();
    final dannoModificato = dannoModificatoBase > 0
        ? applicaParserDanniSubiti(dannoModificatoBase, elementoAttivo)
        : dannoModificatoBase;
    final parserRulesLog = activeIncomingDamageRules(elementoAttivo).isEmpty
        ? ''
        : ' Parser ${incomingDamageRulesSummary(elementoAttivo)}: $dannoModificatoBase -> $dannoModificato.';
    final dannoLog = critico
        ? '$dannoInseritoLog + 5 critico = $dannoPrimaSchivata'
        : dannoInseritoLog;
    final stadioPrimaLog = percentualeLiberaPrima == null
        ? modificatorePrima
        : testoPercentualeDannoLibera(percentualeLiberaPrima);
    final criticoLogIt = critico
        ? (stadioPrimaLog == modificatoreDopo
              ? ' Critico: +5 danni, stadio già a $modificatoreDopo.'
              : ' Critico: +5 danni, stadio $stadioPrimaLog → $modificatoreDopo (${testoPercentualeDannoLibera(modificatore.multiplier)}).')
        : '';
    final criticoLogEn = critico
        ? (stadioPrimaLog == modificatoreDopo
              ? ' Critical: +5 damage, stage already at $modificatoreDopo.'
              : ' Critical: +5 damage, stage $stadioPrimaLog → $modificatoreDopo (${testoPercentualeDannoLibera(modificatore.multiplier)}).')
        : '';

    if (dannoModificato < 0) {
      final curaDaRigenerazione = dannoModificato.abs();
      final hpPrimaCura = hpCorrenti();
      final hpTempPrimaCura = hpTemp();
      final healed = healOculumHp(
        current: hpPrimaCura,
        maximum: maxHp(),
        temporary: hpTempPrimaCura,
        amount: curaDaRigenerazione,
      );
      final hpRecuperati = healed.current - hpPrimaCura;
      final hpTempOttenuti = healed.temporary - hpTempPrimaCura;

      setState(() {
        if (critico) {
          modificatoreDannoSelezionato = modificatoreDopo;
          if (stadioLiberoDopo != null) {
            dannoSubitoPercentController.text = testoPercentualeDannoLibera(
              stadioLiberoDopo.multiplier,
            );
          }
        }
        schivataOculumRiduzionePronta = 0;
        schivataOculumEtichettaPronta = '';

        currentHpController.text = healed.current.toString();
        impostaHpTempTotali(healed.temporary);

        risultato = t(
          'Rigenerazione: $dannoLog$schivataLogIt$difesaLogIt. $modificatoreNome: +$hpRecuperati HP${hpTempOttenuti > 0 ? ", +$hpTempOttenuti HP temporanei" : ""}.$criticoLogIt$opzioniImpattoIt',
          'Regeneration: $dannoLog$schivataLogEn$difesaLogEn. $modificatoreNome: +$hpRecuperati HP${hpTempOttenuti > 0 ? ", +$hpTempOttenuti temporary HP" : ""}.$criticoLogEn$opzioniImpattoEn',
        );

        dannoSubitoController.clear();

        aggiungiLog(risultato);
      });

      programmaSalvataggio();
      sendRealtimeHpChanged();
      controllaStatoForzaDopoHp();
      return;
    }

    if (dannoModificato == 0) {
      setState(() {
        if (critico) {
          modificatoreDannoSelezionato = modificatoreDopo;
          if (stadioLiberoDopo != null) {
            dannoSubitoPercentController.text = testoPercentualeDannoLibera(
              stadioLiberoDopo.multiplier,
            );
          }
        }
        schivataOculumRiduzionePronta = 0;
        schivataOculumEtichettaPronta = '';

        risultato = t(
          'Danno annullato: $dannoLog$schivataLogIt$difesaLogIt. $modificatoreNome: nessun danno subito.$parserRulesLog$criticoLogIt$opzioniImpattoIt',
          'Damage negated: $dannoLog$schivataLogEn$difesaLogEn. $modificatoreNome: no damage taken.$parserRulesLog$criticoLogEn$opzioniImpattoEn',
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

    final resistenzaStatoForzaAttiva =
        statoForzaAttivo == 'azzeramento_vulnerabilita';
    if (resistenzaStatoForzaAttiva) {
      dannoFinale = max(1, (dannoFinale * 0.75).ceil());
    }
    final resistenzaStatoForzaLogIt = resistenzaStatoForzaAttiva
        ? ' Azzeramento delle vulnerabilita: danno ridotto a $dannoFinale.'
        : '';
    final resistenzaStatoForzaLogEn = resistenzaStatoForzaAttiva
        ? ' Vulnerability Reset: damage reduced to $dannoFinale.'
        : '';

    final resistenzaAdattamentoAttiva =
        currentSheetHasAdaptationTemporaryResistance();
    if (resistenzaAdattamentoAttiva) {
      dannoFinale = max(
        1,
        (dannoFinale * damageRuleMultiplierForCommand('Resistenza')).ceil(),
      );
    }
    final resistenzaAdattamentoLogIt = resistenzaAdattamentoAttiva
        ? ' Adattamento: Resistenza Temporanea a tutti i danni, danno ridotto a $dannoFinale.'
        : '';
    final resistenzaAdattamentoLogEn = resistenzaAdattamentoAttiva
        ? ' Adaptation: Temporary Resistance to all damage, damage reduced to $dannoFinale.'
        : '';

    int rimanente = dannoFinale;
    int oculumShield = scudoOculum();
    int shield = scudo();
    int temp = hpTemp();
    int hp = hpCorrenti();
    final hpPrima = hp;
    final safeHpPronto = hasSafeHpParserCommand();
    final saveShieldValue = saveShieldParserValue();
    final scudoSalvataggioPronto =
        !ignoraScudi && scudoSalvataggioAttivo && (oculumShield + shield) > 0;
    var scudoSalvataggioAttivato = false;
    var safeHpAttivato = false;
    var saveShieldAttivato = false;

    if (!ignoraScudi) {
      final oculumResult = assorbiDannoDaScudoConBonus(
        layer: oculumShield,
        remaining: rimanente,
        bonusPercent: bonusScudi,
      );
      oculumShield = oculumResult.layer;
      rimanente = oculumResult.remaining;

      final shieldResult = assorbiDannoDaScudoConBonus(
        layer: shield,
        remaining: rimanente,
        bonusPercent: bonusScudi,
      );
      shield = shieldResult.layer;
      rimanente = shieldResult.remaining;
    }

    if (scudoSalvataggioPronto &&
        rimanente > 0 &&
        oculumShield <= 0 &&
        shield <= 0) {
      rimanente = 0;
      scudoSalvataggioAttivato = true;
    }

    if (temp > 0 && rimanente > 0) {
      final assorbito = min(temp, rimanente);
      temp -= assorbito;
      rimanente -= assorbito;
    }

    if (rimanente > 0) {
      hp = max(0, hp - rimanente);
    }

    if (safeHpPronto && hp <= 0 && hpPrima > 0) {
      hp = 1;
      safeHpAttivato = true;
      consumeOneShotParserCommand('safehp');
    }

    if (saveShieldValue > 0 &&
        hp > 0 &&
        hp <= max(1, (maxHp() * 0.25).ceil())) {
      shield += saveShieldValue;
      saveShieldAttivato = true;
      consumeOneShotParserCommand('saveShield');
    }

    setState(() {
      if (critico) {
        modificatoreDannoSelezionato = modificatoreDopo;
        if (stadioLiberoDopo != null) {
          dannoSubitoPercentController.text = testoPercentualeDannoLibera(
            stadioLiberoDopo.multiplier,
          );
        }
      }
      schivataOculumRiduzionePronta = 0;
      schivataOculumEtichettaPronta = '';
      if (scudoSalvataggioAttivato) {
        scudoSalvataggioAttivo = false;
      }

      scudoOculumController.text = oculumShield.toString();
      impostaScudoTotale(shield);
      impostaHpTempTotali(temp);
      currentHpController.text = hp.toString();
      final partialAwakeningLog = applicaRisveglioParzialeMetaHpSeServe(
        hpBefore: hpPrima,
        hpAfter: hp,
        oculumDodgeUsedToday: riduzioneSchivata > 0,
      );
      final lowHpLog = applicaRicompensaAscensionDustRisorsaBassa(
        before: hpPrima,
        after: hp,
        maximum: maxHp(),
        resourceName: t('HP', 'HP'),
      );
      if (scudoCriticoSpezzato) {
        scudoCriticoController.text = max(0, scudoCriticoPrima - 1).toString();
      }

      risultato = t(
        'Danno subito: $dannoLog$schivataLogIt$difesaLogIt. $modificatoreNome: $dannoModificatoBase.$parserRulesLog$criticoLogIt ${scudoCriticoAttivo ? "Scudo Critico attivo: danno dimezzato a $dannoFinale. " : ""}$resistenzaStatoForzaLogIt$resistenzaAdattamentoLogIt$opzioniImpattoIt${scudoSalvataggioAttivato ? " Scudo di Salvataggio: l'overflow viene bloccato dopo l'ultimo scudo." : ""}${safeHpAttivato ? " @safehp: resti a 1 HP e il comando viene consumato." : ""}${saveShieldAttivato ? " @saveShield: +$saveShieldValue Scudo, comando consumato." : ""} Applicato a ${ignoraScudi ? "HP Temp -> HP" : "Scudo Oculum -> Scudo -> HP Temp -> HP"}.',
        'Damage taken: $dannoLog$schivataLogEn$difesaLogEn. $modificatoreNome: $dannoModificatoBase.$parserRulesLog$criticoLogEn ${scudoCriticoAttivo ? "Critical Shield active: damage halved to $dannoFinale. " : ""}$resistenzaStatoForzaLogEn$resistenzaAdattamentoLogEn$opzioniImpattoEn${scudoSalvataggioAttivato ? " Saving Shield: overflow is blocked after the last shield." : ""}${safeHpAttivato ? " @safehp: you stay at 1 HP and the command is consumed." : ""}${saveShieldAttivato ? " @saveShield: +$saveShieldValue Shield, command consumed." : ""} Applied to ${ignoraScudi ? "Temp HP -> HP" : "Oculum Shield -> Shield -> Temp HP -> HP"}.',
      );
      risultato += partialAwakeningLog;
      risultato += lowHpLog;

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
    checkAutomaticAshFromHpLoss(hpPrima, hp, source: t('danno', 'damage'));
    controllaCadutaDopoDanno();
    controllaStatoForzaDopoHp();
  }

  void curaHp() {
    final cura = leggiValoreDannoCura();

    if (cura == null || cura <= 0) return;
    final curaLog = dettaglioValoreDannoCura(cura);
    final hpPrima = hpCorrenti();
    final hpTempPrima = hpTemp();
    final healed = healOculumHp(
      current: hpPrima,
      maximum: maxHp(),
      temporary: hpTempPrima,
      amount: cura,
    );
    final hpRecuperati = healed.current - hpPrima;
    final hpTempOttenuti = healed.temporary - hpTempPrima;

    setState(() {
      currentHpController.text = healed.current.toString();
      impostaHpTempTotali(healed.temporary);

      risultato = t(
        'Cura applicata ($curaLog): +$hpRecuperati HP${hpTempOttenuti > 0 ? ", +$hpTempOttenuti HP temporanei" : ""}.',
        'Healing applied ($curaLog): +$hpRecuperati HP${hpTempOttenuti > 0 ? ", +$hpTempOttenuti temporary HP" : ""}.',
      );

      dannoSubitoController.clear();

      aggiungiLog(risultato);
    });

    programmaSalvataggio();
    sendRealtimeHpChanged();
    controllaStatoForzaDopoHp();
  }

  void refullVita() {
    setState(() {
      currentHpController.text = maxHp().toString();
      statoForzaAttivo = '';
      statoForzaPronto = true;
      statoForzaTiriRimanenti = 0;
      hpTempBonusConsumati = 0;
      final oculumShieldMax = scudoOculumMax();
      if (oculumShieldMax > 0) {
        ricaricaScudoOculum();
      }
      risultato = t(
        oculumShieldMax > 0
            ? 'Refull Vita: HP ${maxHp()}, HP Temp ${hpTemp()} e Scudo Oculum ${scudoOculum()}/$oculumShieldMax. Scudo normale invariato: ${scudo()}.'
            : 'Refull Vita: HP ${maxHp()} e HP Temp ${hpTemp()}. Scudo normale invariato: ${scudo()}.',
        oculumShieldMax > 0
            ? 'Refill Life: HP ${maxHp()}, Temp HP ${hpTemp()} and Oculum Shield ${scudoOculum()}/$oculumShieldMax. Normal Shield unchanged: ${scudo()}.'
            : 'Refill Life: HP ${maxHp()} and Temp HP ${hpTemp()}. Normal Shield unchanged: ${scudo()}.',
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

    invalidateHiddenEyeDerivedCaches();
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
      invalidateHiddenEyeDerivedCaches(notifyCards: false);
      scheduleHiddenEyeDerivedCardsRefresh();
    }
  }

  void toggleRebirth(bool value) {
    setState(() {
      rebirthato = value;
      aggiornaGradoAutomatico();
      invalidateHiddenEyeDerivedCaches();

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

  int expGradeBonus() => oculumGradeExperienceBonus(
    enemyGrade: max(0, leggiNumero(enemyGradeExpController)),
    rebirth: rebirthato,
    difficulty: normalizedCampaignDifficulty(),
  );

  String expGradeBonusLabel() => '+${expGradeBonus()} EXP grado';

  String applicaEsperienzaFlat(int amount, {required String motivo}) {
    final expAggiunta = max(0, amount);
    if (expAggiunta == 0) return '';

    final expPrima = expCorrente();
    final expTotale = expPrima + expAggiunta;
    final sogliaPrima = max(expMilestoneRegenClaimed, expPrima ~/ 369);
    final sogliaDopo = expTotale ~/ 369;
    final soglieRecupero = max(0, sogliaDopo - sogliaPrima);
    final recuperoCento = applicaRecuperoOgniCentoExp(expAggiunta);

    if (!scalaExpAutomatica) {
      expController.text = expTotale.clamp(0, 999999).toString();
      expMilestoneRegenClaimed = max(
        expMilestoneRegenClaimed,
        expTotale ~/ 369,
      );
      final recupero = applicaRecuperoSogliaExp(soglieRecupero);
      recordExperienceProgress();
      notifyExperienceChanged();
      scheduleInputUiRefresh(delay: Duration.zero);
      return '\n$motivo: +$expAggiunta EXP. Totale: ${expController.text}.$recuperoCento$recupero';
    }

    final expPerLivello = normalizedCampaignDifficulty() == 'oculum'
        ? 1369
        : 1000;
    final livelliGuadagnati = expTotale ~/ expPerLivello;
    final expRimasta = expTotale % expPerLivello;
    expController.text = expRimasta.toString();
    expMilestoneRegenClaimed = expRimasta ~/ 369;
    final recupero = applicaRecuperoSogliaExp(soglieRecupero);

    var livelloText = '';
    if (livelliGuadagnati > 0) {
      livelloController.text =
          (leggiNumero(livelloController) + livelliGuadagnati).toString();
      aggiornaGradoAutomatico();
      if (isMostro()) {
        monsterStatPoints += livelliGuadagnati * 9;
      } else {
        levelUpDaAssegnare += livelliGuadagnati;
      }
      refullaHp();
      invalidateHiddenEyeDerivedCaches(notifyCards: false);
      scheduleHiddenEyeDerivedCardsRefresh();
      livelloText = t(
        ' Livelli ottenuti: $livelliGuadagnati.',
        ' Levels gained: $livelliGuadagnati.',
      );
    }

    recordExperienceProgress();
    notifyExperienceChanged();
    scheduleInputUiRefresh(delay: Duration.zero);
    return '\n$motivo: +$expAggiunta EXP. EXP attuale: $expRimasta/$expPerLivello.$livelloText$recuperoCento$recupero';
  }

  int expFinalePreview() {
    final base = max(0, leggiNumero(expDaAggiungereController));
    if (base == 0) return 0;
    final value =
        (base * expSourceMultiplier() * expGradeMultiplier()) + expGradeBonus();
    if (value.isNaN || value.isInfinite) return 0;
    return value.round().clamp(0, 999999).toInt();
  }

  void aggiungiEsperienza() {
    final expBase = leggiNumero(expDaAggiungereController);
    final expAggiunta = expFinalePreview();

    if (expBase <= 0 || expAggiunta <= 0) {
      risultato = t(
        'Scrivi quanta EXP vuoi aggiungere.',
        'Write how much EXP you want to add.',
      );
      notifyDiceResultChanged();

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
    final expRealeAggiunta = oculumExperienceAfterStatTax(
      difficulty: normalizedCampaignDifficulty(),
      calculatedExperience: expAggiunta,
      statTax: tassaStatsExp,
    );
    final expPrima = expCorrente();
    final expTotale = expPrima + expRealeAggiunta;
    final sogliaPrima = max(expMilestoneRegenClaimed, expPrima ~/ 369);
    final sogliaDopo = expTotale ~/ 369;
    final soglieRecupero = max(0, sogliaDopo - sogliaPrima);
    final recuperoCento = applicaRecuperoOgniCentoExp(expRealeAggiunta);
    if (!scalaExpAutomatica) {
      expController.text = expTotale.clamp(0, 999999).toString();
      expMilestoneRegenClaimed = max(
        expMilestoneRegenClaimed,
        expTotale ~/ 369,
      );
      final recuperoExpLog = applicaRecuperoSogliaExp(soglieRecupero);
      risultato = t(
        'EXP aggiunta senza scalare livelli: base $expBase, ${expSourceLabel()}, grado x${expGradeMultiplier().toStringAsFixed(2)}, ${expGradeBonusLabel()} → +$expRealeAggiunta${tassaStatsExp > 0 ? ' ($expAggiunta - $tassaStatsExp stats)' : ''}. EXP attuale: ${expController.text}.',
        'EXP added without level scaling: base $expBase, ${expSourceLabel()}, grade x${expGradeMultiplier().toStringAsFixed(2)}, ${expGradeBonusLabel()} → +$expRealeAggiunta${tassaStatsExp > 0 ? ' ($expAggiunta - $tassaStatsExp stats)' : ''}. Current EXP: ${expController.text}.',
      );
      if (recuperoExpLog.isNotEmpty) {
        risultato += recuperoExpLog;
      }
      risultato += recuperoCento;
      expDaAggiungereController.clear();
      aggiungiLog(risultato);

      recordExperienceProgress();
      notifyExperienceChanged();
      notifyDiceResultChanged();
      scheduleInputUiRefresh(delay: Duration.zero);
      return;
    }

    final expPerLivello = normalizedCampaignDifficulty() == 'oculum'
        ? 1369
        : 1000;
    final livelliGuadagnati = expTotale ~/ expPerLivello;
    final expRimasta = expTotale % expPerLivello;

    expController.text = expRimasta.toString();
    expMilestoneRegenClaimed = expRimasta ~/ 369;
    final recuperoExpLog = applicaRecuperoSogliaExp(soglieRecupero);

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
        'EXP aggiunta: base $expBase, ${expSourceLabel()}, grado x${expGradeMultiplier().toStringAsFixed(2)}, ${expGradeBonusLabel()} → +$expRealeAggiunta${tassaStatsExp > 0 ? ' ($expAggiunta - $tassaStatsExp stats)' : ''}. EXP attuale: $expRimasta/1000.',
        'EXP added: base $expBase, ${expSourceLabel()}, grade x${expGradeMultiplier().toStringAsFixed(2)}, ${expGradeBonusLabel()} → +$expRealeAggiunta${tassaStatsExp > 0 ? ' ($expAggiunta - $tassaStatsExp stats)' : ''}. Current EXP: $expRimasta/1000.',
      );
    }

    if (recuperoExpLog.isNotEmpty) {
      risultato += recuperoExpLog;
    }
    risultato += recuperoCento;
    expDaAggiungereController.clear();

    aggiungiLog(risultato);

    recordExperienceProgress();
    notifyExperienceChanged();
    notifyDiceResultChanged();
    scheduleInputUiRefresh(delay: Duration.zero);
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

    invalidateHiddenEyeDerivedCaches();
    recordExperienceProgress(immediate: true);
    notifyExperienceChanged();
    scheduleInputUiRefresh(delay: Duration.zero);
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

    invalidateHiddenEyeDerivedCaches();
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

    invalidateHiddenEyeDerivedCaches();
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

    invalidateHiddenEyeDerivedCaches();
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

    recordExperienceProgress(immediate: true);
    notifyExperienceChanged();
    scheduleInputUiRefresh(delay: Duration.zero);
    invalidateHiddenEyeDerivedCaches();
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
      applyTemporaryOculumState(
        TemporaryOculumState(
          normalCurrent: ocu,
          temporary: 0,
          rollsRemaining: 0,
        ),
      );

      refullaHp();

      risultato =
          'Stats randomizzate in modo bilanciato: RES $res, VOL $vol, MAT $mat, OCU $ocu.';

      aggiungiLog(
        'Stats randomizzate: RES $res, VOL $vol, MAT $mat, OCU $ocu.',
      );
    });

    invalidateHiddenEyeDerivedCaches();
    programmaSalvataggio();
  }

  // =====================================================
}
