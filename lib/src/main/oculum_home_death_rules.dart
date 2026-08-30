part of '../../main.dart';

extension _OculumHomeDeathRules on _OculumHomePageState {
  static const int deathWoundLimit = 3;
  static const int vitalWillLimit = 3;

  bool get schedaAttivaCaduta => personaggioCaduto || hpCorrenti() <= 0;

  int sheetMaxHpForDeathAt(int index) {
    if (index == schedaCorrente) return max(1, maxHp());
    if (index < 0 || index >= schedePersonaggio.length) return 1;
    final sheet = schedePersonaggio[index];
    final saved = readIntValue(sheet['derivedMaxHp']);
    if (saved > 0) return saved;
    final resilience = max(
      1,
      readIntValue(
        sheet['currentResilienza'],
        fallback: readIntValue(sheet['resilienza'], fallback: 1),
      ),
    );
    final grade = max(0, readIntValue(sheet['grado']));
    return max(1, resilience * 10 * max(1, grade * 5)).toInt();
  }

  int sheetCurrentHpForDeathAt(int index) {
    if (index == schedaCorrente) return hpCorrenti();
    if (index < 0 || index >= schedePersonaggio.length) return 1;
    return max(0, readIntValue(schedePersonaggio[index]['currentHp']));
  }

  int sheetCurrentOculumForDeathAt(int index) {
    if (index == schedaCorrente) return oculumTotale();
    if (index < 0 || index >= schedePersonaggio.length) return 0;
    return max(
      0,
      readIntValue(
        schedePersonaggio[index]['derivedOculumTotal'],
        fallback: readIntValue(
          schedePersonaggio[index]['currentOculum'],
          fallback: readIntValue(schedePersonaggio[index]['oculum']),
        ),
      ),
    );
  }

  int sheetMaxOculumForDeathAt(int index) {
    if (index == schedaCorrente) return max(0, oculumMassimo());
    if (index < 0 || index >= schedePersonaggio.length) return 0;
    return max(
      0,
      readIntValue(
        schedePersonaggio[index]['maxOculum'],
        fallback: readIntValue(schedePersonaggio[index]['oculum']),
      ),
    );
  }

  int sheetWillForDeathAt(int index) {
    if (index == schedaCorrente) return max(0, volontaTotale());
    return max(0, sheetIntValueAt(index, 'volonta'));
  }

  int sheetMateriaForDeathAt(int index) {
    if (index == schedaCorrente) return max(0, materiaTotale());
    return max(0, sheetIntValueAt(index, 'materia'));
  }

  bool masterInitiativeTokenIsDowned(Map<String, dynamic> token) {
    return '${token['status'] ?? ''}' == 'downed' ||
        readBoolValue(token['downed']);
  }

  bool masterInitiativeTokenCanAct(Map<String, dynamic> token) {
    return !masterInitiativeTokenIsDead(token) &&
        !masterInitiativeTokenIsDowned(token);
  }

  int masterInitiativeTokenLevel(Map<String, dynamic> token) {
    return max(
      0,
      readIntValue(token['level'], fallback: readIntValue(token['livello'])),
    );
  }

  int masterInitiativeTokenGrade(Map<String, dynamic> token) {
    return max(
      0,
      readIntValue(token['grade'], fallback: readIntValue(token['grado'])),
    );
  }

  int assistedReviveTemporaryHp(Map<String, dynamic> token) {
    return masterInitiativeTokenLevel(token) +
        masterInitiativeTokenGrade(token) * 6;
  }

  void setMasterInitiativeDeathOutcome(
    Map<String, dynamic> token, {
    required String italian,
    required String english,
  }) {
    token['realtimeDeathOutcomeIt'] = italian;
    token['realtimeDeathOutcomeEn'] = english;
    token['realtimeDeathOutcomeAt'] = DateTime.now().toIso8601String();
  }

  int masterInitiativeSheetIndexForToken(Map<String, dynamic> token) {
    final tag = '${token['sheetTag'] ?? ''}'.trim();
    if (tag.isEmpty) return -1;
    return schedePersonaggio.indexWhere(
      (sheet) => '${sheet['sheetTag'] ?? ''}' == tag,
    );
  }

  void syncMasterInitiativeTokenDeathFromSheet(int index) {
    if (index < 0 || index >= schedePersonaggio.length) return;
    final tag = sheetTagAt(index);
    final tokenIndex = masterInitiativeTokens.indexWhere(
      (token) => '${token['sheetTag'] ?? ''}' == tag,
    );
    if (tokenIndex < 0) return;

    final token = masterInitiativeTokens[tokenIndex];
    final isCurrent = index == schedaCorrente;
    final downed = isCurrent
        ? schedaAttivaCaduta
        : readBoolValue(schedePersonaggio[index]['personaggioCaduto']) ||
              sheetCurrentHpForDeathAt(index) <= 0;
    token['currentHp'] = sheetCurrentHpForDeathAt(index);
    token['maxHp'] = sheetMaxHpForDeathAt(index);
    token['currentOculum'] = sheetCurrentOculumForDeathAt(index);
    token['maxOculum'] = sheetMaxOculumForDeathAt(index);
    token['shield'] = isCurrent
        ? scudo()
        : max(0, readIntValue(schedePersonaggio[index]['scudo']));
    token['will'] = sheetWillForDeathAt(index);
    token['materia'] = sheetMateriaForDeathAt(index);
    token['deathWounds'] = isCurrent
        ? feriteMorte
        : readIntValue(
            schedePersonaggio[index]['feriteMorte'],
          ).clamp(0, deathWoundLimit).toInt();
    token['vitalWills'] = isCurrent
        ? volontaVitale
        : readIntValue(
            schedePersonaggio[index]['volontaVitale'],
          ).clamp(0, vitalWillLimit).toInt();
    token['downed'] = downed;
    if (!masterInitiativeTokenIsDead(token)) {
      token['status'] = downed ? 'downed' : 'ready';
    }
    token['updatedAt'] = DateTime.now().toIso8601String();
  }

  void syncCurrentSheetDeathStateToInitiative() {
    syncMasterInitiativeTokenDeathFromSheet(schedaCorrente);
    sendRealtimeInitiativeSnapshotIfPublished();
  }

  void segnaSchedaAttivaCaduta() {
    if (personaggioCaduto) return;
    personaggioCaduto = true;
    feriteMorte = 0;
    volontaVitale = 0;
    risultato = t(
      'Sei a terra. Al tuo turno effettua un tiro contro la morte.',
      'You are down. Make a death save on your turn.',
    );
    aggiungiLog(risultato);
    syncCurrentSheetDeathStateToInitiative();
  }

  void controllaCadutaDopoDanno() {
    if (hpCorrenti() > 0 || personaggioCaduto) return;
    segnaSchedaAttivaCaduta();
  }

  void rialzaSchedaAttiva({
    bool forzaMassimo = false,
    bool scudoCritico = false,
    String? prefissoIt,
    String? prefissoEn,
  }) {
    final fullStrength = forzaMassimo || feriteMorte == 0;
    final maxHitPoints = max(1, maxHp());
    final maxOculum = max(0, oculumMassimo());
    final hp = fullStrength ? maxHitPoints : max(1, (maxHitPoints / 2).ceil());
    final requestedOculum = fullStrength
        ? maxOculum
        : max(0, (maxOculum / 2).ceil());
    final oculum = oculumGainWhileSleeping(
      requestedOculum,
      sleeping: oculumAddormentato,
    );
    final shield = max(
      0,
      volontaTotale() + (scudoCritico ? materiaTotale() : 0),
    );

    currentHpController.text = hp.toString();
    applyTemporaryOculumState(
      TemporaryOculumState(
        normalCurrent: oculum,
        temporary: 0,
        rollsRemaining: 0,
      ),
    );
    impostaScudoTotale(shield);
    personaggioCaduto = false;
    personaggioSvenuto = false;
    feriteMorte = 0;
    volontaVitale = 0;
    final strengthIt = fullStrength
        ? 'al massimo delle forze'
        : 'con meta HP e meta Oculum';
    final strengthEn = fullStrength
        ? 'at full strength'
        : 'with half HP and half Oculum';
    risultato =
        '${prefissoIt ?? ''}Ti rialzi $strengthIt. Scudo ${scudoCritico ? '${volontaTotale()} Volonta + ${materiaTotale()} Materia' : '${volontaTotale()} Volonta'}.';
    aggiungiLog(
      '${prefissoIt ?? ''}${t('Ti rialzi', 'You rise')} $strengthIt.',
    );
    if (prefissoEn != null && linguaInglese) {
      risultato =
          '$prefissoEn${t('You rise', 'You rise')} $strengthEn. ${t('Shield', 'Shield')} ${scudoCritico ? '${volontaTotale()} Will + ${materiaTotale()} Materia' : '${volontaTotale()} Will'}.';
    }
    salvaSchedaCorrenteInMemoria();
    syncCurrentSheetDeathStateToInitiative();
  }

  void effettuaTiroMorteSchedaAttiva() {
    if (!schedaAttivaCaduta) {
      updateOculumHomeUi(() {
        risultato = t(
          'Il personaggio non e a terra.',
          'The character is not down.',
        );
        aggiungiLog(risultato);
      });
      return;
    }

    final roll = tiraD20();
    registerValidRoll();
    final difficulty = difficoltaTiro();
    final total = roll + modificatoreDifficoltaTiro(difficulty: difficulty);
    final rollText = difficulty == 0
        ? '1d20=$roll'
        : '1d20=$roll${signedRollPart(modificatoreDifficoltaTiro(difficulty: difficulty))}=$total (DT ${signedRollPart(difficulty)})';
    updateOculumHomeUi(() {
      final expText = applicaEsperienzaFlat(
        oculumRollExperienceGain(
          naturalRoll: roll,
          faces: 20,
          rollSucceeded: roll == 20 || total >= 10,
        ),
        motivo: t('Tiro superato', 'Successful roll'),
      );
      dadoMostrato = rollText;
      dadoMostratoFacce = 20;
      tiroCriticoUno = roll == 1;
      tiroCriticoVenti = roll == 20;
      if (roll == 20) {
        rialzaSchedaAttiva(
          forzaMassimo: true,
          scudoCritico: true,
          prefissoIt: '20 critico. ',
          prefissoEn: 'Critical 20. ',
        );
      } else if (total >= 10) {
        volontaVitale = min(vitalWillLimit, volontaVitale + 1);
        risultato =
            'Tiro contro la morte: $rollText, successo. Volonta Vitale $volontaVitale/$vitalWillLimit.';
        if (volontaVitale >= vitalWillLimit) {
          rialzaSchedaAttiva(prefissoIt: 'Tre Volonta Vitale. ');
        } else {
          aggiungiLog(risultato);
          salvaSchedaCorrenteInMemoria();
          syncCurrentSheetDeathStateToInitiative();
        }
      } else {
        feriteMorte = min(deathWoundLimit, feriteMorte + 1);
        risultato =
            'Tiro contro la morte: $rollText${roll == 1 ? ' critico negativo' : ''}. Ferite $feriteMorte/$deathWoundLimit.';
        if (feriteMorte >= deathWoundLimit) {
          personaggioCaduto = false;
          risultato =
              'Tiro contro la morte: terza Ferita. Il personaggio e morto.';
          segnaFallenEyeMortoDaScheda(schedePersonaggio[schedaCorrente]);
        }
        aggiungiLog(risultato);
        salvaSchedaCorrenteInMemoria();
        syncCurrentSheetDeathStateToInitiative();
      }
      if (expText.isNotEmpty) {
        risultato += expText;
        aggiungiLog(expText.trim());
      }
    });
    mostraDadoCentrale(
      valore: rollText,
      criticoUno: roll == 1,
      criticoVenti: roll == 20,
    );
    programmaSalvataggio();
    sendRealtimeHpChanged();
  }

  void normalizeMasterInitiativeDeathState(Map<String, dynamic> token) {
    token['deathWounds'] = readIntValue(
      token['deathWounds'],
    ).clamp(0, deathWoundLimit).toInt();
    token['vitalWills'] = readIntValue(
      token['vitalWills'],
    ).clamp(0, vitalWillLimit).toInt();
    token['currentHp'] = max(0, readIntValue(token['currentHp'], fallback: 1));
    token['maxHp'] = max(
      1,
      readIntValue(
        token['maxHp'],
        fallback: readIntValue(token['currentHp'], fallback: 1),
      ),
    );
    token['currentOculum'] = max(0, readIntValue(token['currentOculum']));
    token['maxOculum'] = max(0, readIntValue(token['maxOculum']));
    token['shield'] = max(0, readIntValue(token['shield']));
    token['will'] = max(0, readIntValue(token['will']));
    token['materia'] = max(0, readIntValue(token['materia']));
    final markedDown =
        readBoolValue(token['downed']) ||
        '${token['status'] ?? ''}' == 'downed';
    token['downed'] = markedDown;
    if (markedDown && !masterInitiativeTokenIsDead(token)) {
      token['status'] = 'downed';
    }
  }

  void applyMasterInitiativeTokenVitalsToSource(Map<String, dynamic> token) {
    final index = masterInitiativeSheetIndexForToken(token);
    if (index < 0) return;

    final downed = masterInitiativeTokenIsDowned(token);
    final sheet = schedePersonaggio[index];
    final hp = max(0, readIntValue(token['currentHp']));
    final oculum = max(0, readIntValue(token['currentOculum']));
    final shield = max(0, readIntValue(token['shield']));
    final temporaryHp = readIntValue(
      token['hpTemp'],
    ).clamp(0, oculumTemporaryHpLimit).toInt();
    final wounds = readIntValue(
      token['deathWounds'],
    ).clamp(0, deathWoundLimit).toInt();
    final vital = readIntValue(
      token['vitalWills'],
    ).clamp(0, vitalWillLimit).toInt();

    sheet['currentHp'] = '$hp';
    sheet['currentOculum'] = '$oculum';
    sheet['scudo'] = '$shield';
    sheet['hpTemp'] = '$temporaryHp';
    sheet['personaggioCaduto'] = downed;
    sheet['feriteMorte'] = wounds;
    sheet['volontaVitale'] = vital;
    final outcomeIt = '${token['realtimeDeathOutcomeIt'] ?? ''}'.trim();
    final outcomeEn = '${token['realtimeDeathOutcomeEn'] ?? ''}'.trim();
    if (outcomeIt.isNotEmpty) sheet['realtimeDeathOutcomeIt'] = outcomeIt;
    if (outcomeEn.isNotEmpty) sheet['realtimeDeathOutcomeEn'] = outcomeEn;
    final outcomeAt = '${token['realtimeDeathOutcomeAt'] ?? ''}'.trim();
    if (outcomeAt.isNotEmpty) sheet['realtimeDeathOutcomeAt'] = outcomeAt;

    if (index == schedaCorrente) {
      currentHpController.text = '$hp';
      applyTemporaryOculumState(
        TemporaryOculumState(
          normalCurrent: oculum,
          temporary: 0,
          rollsRemaining: 0,
        ),
      );
      hpTempController.text = '$temporaryHp';
      impostaScudoTotale(shield);
      personaggioCaduto = downed;
      feriteMorte = wounds;
      volontaVitale = vital;
      salvaSchedaCorrenteInMemoria();
    }
    sendRealtimeMasterDeathPatchToOwner(index, token);
  }

  void reviveMasterInitiativeToken(
    Map<String, dynamic> token, {
    bool forceFull = false,
    bool criticalShield = false,
    bool assisted = false,
    String? prefixIt,
    String? prefixEn,
  }) {
    final fullStrength = forceFull || readIntValue(token['deathWounds']) == 0;
    final maxHp = max(1, readIntValue(token['maxHp'], fallback: 1));
    final maxOculum = max(0, readIntValue(token['maxOculum']));
    final will = max(0, readIntValue(token['will']));
    final materia = max(0, readIntValue(token['materia']));
    token['currentHp'] = fullStrength ? maxHp : max(1, (maxHp / 2).ceil());
    token['currentOculum'] = fullStrength
        ? maxOculum
        : max(0, (maxOculum / 2).ceil());
    token['shield'] = will + (criticalShield ? materia : 0);
    final grantedTemporaryHp = assisted ? assistedReviveTemporaryHp(token) : 0;
    if (grantedTemporaryHp > 0) {
      token['hpTemp'] = max(readIntValue(token['hpTemp']), grantedTemporaryHp);
    }
    token['deathWounds'] = 0;
    token['vitalWills'] = 0;
    token['downed'] = false;
    token['status'] = 'ready';
    final name = '${token['name'] ?? '???'}';
    final strengthIt = fullStrength ? 'al massimo delle forze' : 'con meta HP';
    final strengthEn = fullStrength ? 'at full strength' : 'with half HP';
    final temporaryIt = grantedTemporaryHp > 0
        ? ' +$grantedTemporaryHp HP temporanei.'
        : '';
    final temporaryEn = grantedTemporaryHp > 0
        ? ' +$grantedTemporaryHp temporary HP.'
        : '';
    final resultIt =
        '${prefixIt ?? ''}$name si rialza $strengthIt. Scudo ${token['shield']}.$temporaryIt';
    final resultEn =
        '${prefixEn ?? ''}$name rises $strengthEn. Shield ${token['shield']}.$temporaryEn';
    setMasterInitiativeDeathOutcome(
      token,
      italian: resultIt,
      english: resultEn,
    );
    token['updatedAt'] = DateTime.now().toIso8601String();
    applyMasterInitiativeTokenVitalsToSource(token);
    risultato = resultIt;
    aggiungiLog(
      '${prefixIt ?? ''}$name ${t('si rialza', 'rises')} $strengthIt.',
    );
    if (linguaInglese && prefixEn != null) {
      risultato = resultEn;
    }
  }

  void resolveMasterInitiativeDeathSaveInPlace(Map<String, dynamic> token) {
    if (!masterInitiativeTokenIsDowned(token)) return;
    final roll = tiraD20();
    final difficulty = readIntValue(token['rollDifficulty']);
    final total = roll + modificatoreDifficoltaTiro(difficulty: difficulty);
    final rollText = difficulty == 0
        ? '1d20=$roll'
        : '1d20=$roll${signedRollPart(modificatoreDifficoltaTiro(difficulty: difficulty))}=$total (DT ${signedRollPart(difficulty)})';
    final name = '${token['name'] ?? '???'}';
    if (roll == 20) {
      reviveMasterInitiativeToken(
        token,
        forceFull: true,
        criticalShield: true,
        prefixIt: 'Tiro contro la morte 20 critico. ',
        prefixEn: 'Critical 20 death save. ',
      );
      return;
    }
    if (total >= 10) {
      token['vitalWills'] = min(
        vitalWillLimit,
        readIntValue(token['vitalWills']) + 1,
      );
      risultato =
          'Tiro contro la morte di $name: $rollText, successo. Volonta Vitale ${token['vitalWills']}/$vitalWillLimit.';
      if (readIntValue(token['vitalWills']) >= vitalWillLimit) {
        reviveMasterInitiativeToken(
          token,
          prefixIt: 'Tre Volonta Vitale. ',
          prefixEn: 'Three Vital Wills. ',
        );
      } else {
        final outcomeIt =
            'Tiro contro la morte di $name: $rollText, successo. Volonta Vitale ${token['vitalWills']}/$vitalWillLimit.';
        final outcomeEn =
            '$name death save: $rollText, success. Vital Will ${token['vitalWills']}/$vitalWillLimit.';
        setMasterInitiativeDeathOutcome(
          token,
          italian: outcomeIt,
          english: outcomeEn,
        );
        risultato = linguaInglese ? outcomeEn : outcomeIt;
        aggiungiLog(risultato);
        applyMasterInitiativeTokenVitalsToSource(token);
      }
      return;
    }

    token['deathWounds'] = min(
      deathWoundLimit,
      readIntValue(token['deathWounds']) + 1,
    );
    final wounds = readIntValue(token['deathWounds']);
    if (wounds >= deathWoundLimit) {
      token['downed'] = false;
      token['status'] = 'dead';
      risultato =
          'Tiro contro la morte di $name: $rollText. Terza Ferita: morto.';
    } else {
      risultato =
          'Tiro contro la morte di $name: $rollText${roll == 1 ? ' critico negativo' : ''}. Ferite $wounds/$deathWoundLimit.';
    }
    setMasterInitiativeDeathOutcome(
      token,
      italian: risultato,
      english: wounds >= deathWoundLimit
          ? '$name death save: $rollText. Third Wound: dead.'
          : '$name death save: $rollText${roll == 1 ? ' critical failure' : ''}. Wounds $wounds/$deathWoundLimit.',
    );
    token['updatedAt'] = DateTime.now().toIso8601String();
    aggiungiLog(risultato);
    applyMasterInitiativeTokenVitalsToSource(token);
    if (wounds >= deathWoundLimit) {
      final sheetIndex = masterInitiativeSheetIndexForToken(token);
      if (sheetIndex >= 0) {
        segnaFallenEyeMortoDaScheda(schedePersonaggio[sheetIndex]);
      }
    }
  }

  void tryRaiseMasterInitiativeCompanion(int targetIndex) {
    if (targetIndex < 0 || targetIndex >= masterInitiativeTokens.length) return;
    if (masterInitiativeTokens.isEmpty) return;

    updateOculumHomeUi(() {
      normalizeMasterInitiativeTokens();
      if (targetIndex >= masterInitiativeTokens.length) return;
      final target = masterInitiativeTokens[targetIndex];
      if (!masterInitiativeTokenIsDowned(target)) {
        risultato = t(
          'Questo partecipante non e a terra.',
          'This participant is not down.',
        );
        aggiungiLog(risultato);
        return;
      }

      final activeIndex = masterInitiativeActiveIndex
          .clamp(0, masterInitiativeTokens.length - 1)
          .toInt();
      final helper = masterInitiativeTokens[activeIndex];
      if (!masterInitiativeTokenCanAct(helper) ||
          '${helper['side'] ?? 'ally'}' == 'enemy' ||
          masterInitiativeActionUsed(helper)) {
        risultato = t(
          'Per rialzare un compagno serve un alleato con azione pronta nel turno attivo.',
          'Raising a companion needs an ally with an available action in the active turn.',
        );
        aggiungiLog(risultato);
        return;
      }

      final roll = tiraD20();
      final difficulty = readIntValue(helper['rollDifficulty']);
      final total = roll + modificatoreDifficoltaTiro(difficulty: difficulty);
      final rollText = difficulty == 0
          ? '1d20=$roll'
          : '1d20=$roll${signedRollPart(modificatoreDifficoltaTiro(difficulty: difficulty))}=$total (DT ${signedRollPart(difficulty)})';
      helper['actionUsed'] = true;
      helper['updatedAt'] = DateTime.now().toIso8601String();
      dadoMostrato = rollText;
      dadoMostratoFacce = 20;
      tiroCriticoUno = roll == 1;
      tiroCriticoVenti = roll == 20;
      final targetName = '${target['name'] ?? '???'}';

      if (roll == 1) {
        target['deathWounds'] = min(
          deathWoundLimit,
          readIntValue(target['deathWounds']) + 1,
        );
        if (readIntValue(target['deathWounds']) >= deathWoundLimit) {
          target['downed'] = false;
          target['status'] = 'dead';
          risultato =
              'Rialza compagno: 1 critico. $targetName riceve la terza Ferita e muore.';
        } else {
          risultato =
              'Rialza compagno: 1 critico. $targetName riceve una Ferita (${target['deathWounds']}/$deathWoundLimit).';
        }
        setMasterInitiativeDeathOutcome(
          target,
          italian: risultato,
          english: readIntValue(target['deathWounds']) >= deathWoundLimit
              ? 'Raise companion: critical 1. $targetName receives the third Wound and dies.'
              : 'Raise companion: critical 1. $targetName receives a Wound (${target['deathWounds']}/$deathWoundLimit).',
        );
        aggiungiLog(risultato);
        applyMasterInitiativeTokenVitalsToSource(target);
        if (readIntValue(target['deathWounds']) >= deathWoundLimit) {
          final sheetIndex = masterInitiativeSheetIndexForToken(target);
          if (sheetIndex >= 0) {
            segnaFallenEyeMortoDaScheda(schedePersonaggio[sheetIndex]);
          }
        }
      } else if (roll == 20 || total >= 20) {
        reviveMasterInitiativeToken(
          target,
          forceFull: true,
          criticalShield: true,
          assisted: true,
          prefixIt: 'Rialza compagno $rollText. ',
          prefixEn: 'Raise companion $rollText. ',
        );
      } else if (total <= 7) {
        risultato =
            'Rialza compagno: $rollText. Nessun effetto su $targetName.';
        setMasterInitiativeDeathOutcome(
          target,
          italian: risultato,
          english: 'Raise companion: $rollText. No effect on $targetName.',
        );
        aggiungiLog(risultato);
        applyMasterInitiativeTokenVitalsToSource(target);
      } else if (total <= 15) {
        target['vitalWills'] = min(
          vitalWillLimit,
          readIntValue(target['vitalWills']) + 1,
        );
        if (readIntValue(target['vitalWills']) >= vitalWillLimit) {
          reviveMasterInitiativeToken(
            target,
            assisted: true,
            prefixIt: 'Rialza compagno $rollText. ',
            prefixEn: 'Raise companion $rollText. ',
          );
        } else {
          risultato =
              'Rialza compagno: $rollText. $targetName riceve 1 Volonta Vitale (${target['vitalWills']}/$vitalWillLimit).';
          setMasterInitiativeDeathOutcome(
            target,
            italian: risultato,
            english:
                'Raise companion: $rollText. $targetName receives 1 Vital Will (${target['vitalWills']}/$vitalWillLimit).',
          );
          aggiungiLog(risultato);
          applyMasterInitiativeTokenVitalsToSource(target);
        }
      } else if (total <= 19) {
        target['vitalWills'] = min(
          vitalWillLimit,
          readIntValue(target['vitalWills']) + 2,
        );
        if (readIntValue(target['vitalWills']) >= vitalWillLimit) {
          reviveMasterInitiativeToken(
            target,
            assisted: true,
            prefixIt: 'Rialza compagno $rollText. ',
            prefixEn: 'Raise companion $rollText. ',
          );
        } else {
          risultato =
              'Rialza compagno: $rollText. $targetName riceve 2 Volonta Vitale (${target['vitalWills']}/$vitalWillLimit).';
          setMasterInitiativeDeathOutcome(
            target,
            italian: risultato,
            english:
                'Raise companion: $rollText. $targetName receives 2 Vital Wills (${target['vitalWills']}/$vitalWillLimit).',
          );
          aggiungiLog(risultato);
          applyMasterInitiativeTokenVitalsToSource(target);
        }
      } else {
        reviveMasterInitiativeToken(
          target,
          forceFull: true,
          criticalShield: true,
          assisted: true,
          prefixIt: 'Rialza compagno $rollText. ',
          prefixEn: 'Raise companion $rollText. ',
        );
      }
    });

    mostraDadoCentrale(
      valore: dadoMostrato,
      criticoUno: tiroCriticoUno,
      criticoVenti: tiroCriticoVenti,
    );
    programmaSalvataggio();
    sendRealtimeInitiativeSnapshotIfPublished();
  }
}
