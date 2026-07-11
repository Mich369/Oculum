part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member, unused_element

Map<String, String> _encodeOculumSavePayloadForStorage(
  Map<String, dynamic> data,
) {
  final encoded = jsonEncode(data);
  final comparable = Map<String, dynamic>.from(data)
    ..remove('savedAt')
    ..remove('saveRevision');
  final comparableEncoded = jsonEncode(comparable);
  return <String, String>{
    'encoded': encoded,
    'contentSignature':
        '${comparableEncoded.length}:${comparableEncoded.hashCode}',
  };
}

extension _OculumHomePersistence on _OculumHomePageState {
  List<CharacterArt> artiBase() {
    return [
      CharacterArt(
        nome: 'Prima Art',
        tipo: 'Oculum Art',
        descrizione: 'La prima manifestazione del potere personale.',
        sbloccata: true,
        openName: 'Open della Prima Art',
        openDescription:
            'Si sblocca quando tutte le Skill della Prima Art arrivano al livello 3.',
        openBuff: '@???',
        openSkill: 'Forma completa della Prima Art.',
        skills: [
          ArtSkill(nome: 'Prima Skill', livello: 0),
          ArtSkill(nome: 'Seconda Skill', livello: 0),
          ArtSkill(nome: 'Terza Skill', livello: 0),
        ],
      ),
      CharacterArt(
        nome: 'Seconda Art',
        tipo: '???',
        descrizione: 'Una seconda via ancora da comprendere.',
        sbloccata: false,
        openName: 'Open della Seconda Art',
        openDescription:
            'Si sblocca quando tutte le Skill della Seconda Art arrivano al livello 3.',
        openBuff: '@???',
        openSkill: 'Forma completa della Seconda Art.',
        skills: [
          ArtSkill(nome: 'Prima Skill', livello: 0),
          ArtSkill(nome: 'Seconda Skill', livello: 0),
          ArtSkill(nome: 'Terza Skill', livello: 0),
        ],
      ),
      CharacterArt(
        nome: 'Terza Art',
        tipo: '???',
        descrizione: 'Una terza forma del destino.',
        sbloccata: false,
        openName: 'Open della Terza Art',
        openDescription:
            'Si sblocca quando tutte le Skill della Terza Art arrivano al livello 3.',
        openBuff: '@???',
        openSkill: 'Forma completa della Terza Art.',
        skills: [
          ArtSkill(nome: 'Prima Skill', livello: 0),
          ArtSkill(nome: 'Seconda Skill', livello: 0),
          ArtSkill(nome: 'Terza Skill', livello: 0),
        ],
      ),
    ];
  }

  void assicuraArtiBase() {
    final base = artiBase();

    if (arti.isEmpty) {
      arti.addAll(base);
    } else {
      while (arti.length < base.length) {
        arti.add(base[arti.length]);
      }
    }

    for (final art in arti) {
      while (art.skills.length < 3) {
        art.skills.add(
          ArtSkill(nome: '${t('Skill', 'Skill')} ${art.skills.length + 1}'),
        );
      }
      final maxLevel = artMaxLevel(art);
      for (final skill in art.skills) {
        skill.livello = skill.livello.clamp(0, maxLevel).toInt();
      }

      final index = arti.indexOf(art);
      if (index >= 0 && index < base.length) {
        final baseArt = base[index];
        if (art.openName.trim().isEmpty) art.openName = baseArt.openName;
        if (art.openDescription.trim().isEmpty) {
          art.openDescription = baseArt.openDescription;
        }
        if (art.openBuff.trim().isEmpty) art.openBuff = baseArt.openBuff;
        if (art.openSkill.trim().isEmpty) art.openSkill = baseArt.openSkill;
      }
    }
  }

  void programmaSalvataggio({
    bool invalidateCaches = true,
    bool deferCacheInvalidation = false,
    Duration delay = const Duration(milliseconds: 1800),
  }) {
    if (appOculumInBackground || appOculumFocusTransition) {
      autosavePendingAfterFocusTransition = true;
      autosaveTimer?.cancel();
      autosaveTimer = null;
      return;
    }

    if (invalidateCaches && !deferCacheInvalidation) {
      invalidateDerivedDataCaches();
    }
    autosaveTimer?.cancel();

    autosaveTimer = Timer(delay, () {
      autosaveTimer = null;
      if (salvataggioBloccatoPerErrore) {
        debugPrint(
          'Autosave bloccato: il salvataggio precedente non deve essere sovrascritto.',
        );
        return;
      }

      if (invalidateCaches && deferCacheInvalidation) {
        invalidateDerivedDataCaches();
      }
      unawaited(salvaDati());
    });
  }

  String firmaContenutoSalvataggio(Map<String, dynamic> data) {
    final comparable = Map<String, dynamic>.from(data)
      ..remove('savedAt')
      ..remove('saveRevision');
    final encoded = jsonEncode(comparable);
    return '${encoded.length}:${encoded.hashCode}';
  }

  Future<({String encoded, String contentSignature})>
  codificaSalvataggioPerStorage(Map<String, dynamic> data) async {
    Map<String, String> encoded;
    if (kIsWeb) {
      encoded = _encodeOculumSavePayloadForStorage(data);
    } else {
      try {
        encoded = await compute(
          _encodeOculumSavePayloadForStorage,
          data,
          debugLabel: 'oculum-save-encode',
        );
      } catch (error) {
        debugPrint('Save encode fallback on main isolate: $error');
        encoded = _encodeOculumSavePayloadForStorage(data);
      }
    }

    return (
      encoded: encoded['encoded'] ?? jsonEncode(data),
      contentSignature:
          encoded['contentSignature'] ?? firmaContenutoSalvataggio(data),
    );
  }

  Map<String, dynamic> statoVuotoPersonaggio({
    String nome = '???',
    String tipo = 'Personaggio',
    int livello = 0,
    int grado = 0,
  }) {
    return {
      'nome': nome,
      'tipoScheda': tipo,
      'razza': '',
      'livello': livello.toString(),
      'grado': grado.toString(),
      'exp': '0',
      'expNomePersonalizzato': '',
      'puoEssereOsservato': false,
      'osservazionePuntiDaAssegnare': 0,
      'osservazioneStatScelta': 'Resilienza',
      'osservazioneStatAssegnata': '',
      'osservazionePuntiAssegnati': <String, int>{
        'resilienza': 0,
        'volonta': 0,
        'materia': 0,
        'oculum': 0,
      },
      'osservazionePuntiApplicati': false,
      'resilienza': tipo == 'Mostro' ? '6' : '3',
      'volonta': tipo == 'Mostro' ? '3' : '1',
      'materia': tipo == 'Mostro' ? '3' : '0',
      'oculum': tipo == 'Mostro' ? '2' : '1',
      'currentResilienza': tipo == 'Mostro' ? '6' : '3',
      'currentVolonta': tipo == 'Mostro' ? '3' : '1',
      'currentMateria': tipo == 'Mostro' ? '3' : '0',
      'currentOculum': tipo == 'Mostro' ? '2' : '1',
      'maxOculum': tipo == 'Mostro' ? 2 : 1,
      'currentHp': tipo == 'Mostro' ? '60' : '30',
      'hpTemp': '0',
      'hpTempBonusConsumati': 0,
      'scudo': '0',
      'scudoBonusConsumati': 0,
      'scudoCritico': '0',
      'scudoOculum': '0',
      'scudoOculumMax': '0',
      'attaccoRapido': '0',
      'cmRapido': '0',
      'difesaRapida': '0',
      'reazioni': '1',
      'reazioniVeloci': '0',
      'buffMalusRapidi': '',
      'rebirthato': false,
      'linguaInglese': false,
      'tutorialCompletato': false,
      'modalitaDesktop': false,
      'modalitaVeloce': false,
      'modalitaLeggera': false,
      'desktopSideMenuOpen': false,
      'background':
          'Scrivi qui il passato, lo scopo, i legami, le paure e il destino del personaggio.',
      'notePersonaggio': '',
      'spriteAssetPath': '',
      'textAttachments': <String, List<Map<String, dynamic>>>{},
      'obser': '0',
      'ascensionDust': '0',
      'ispirazioni': '0',
      'superIspirazioni': '0',
      'ispirazioniOculum': '0',
      'karma': '0',
      'follia': '0',
      'folliaDaMostri': false,
      'illnessArtSbloccata': false,
      'oculumTiroPreparato': '0',
      'cenere': '0',
      'sessioniSenzaBisogni': '0',
      'giorniSenzaCiboAcqua': '0',
      'oculumCurrentDay': '1',
      'statoForzaAttivo': '',
      'statoForzaPronto': true,
      'statoForzaTiriRimanenti': 0,
      'malusTiriOculumPostEsplosione': 0,
      'personaggioSvenuto': false,
      'cenereSvenimentoUltimoControllo': 0,
      'personaggioCaduto': false,
      'feriteMorte': 0,
      'volontaVitale': 0,
      'tempResilienza': 0,
      'tempVolonta': 0,
      'tempMateria': 0,
      'tempOculum': 0,
      'schivateOculumConsumate': 0,
      'schivataOculumRiduzionePronta': 0,
      'schivataOculumEtichettaPronta': '',
      'scudoSalvataggioAttivo': false,
      'vantaggioTiroSelezionato': 'Normale',
      'difficoltaTiro': '0',
      'dannoOltreDifesa': false,
      'dannoOltreScudi': false,
      'dannoBonusScudoPercent': '0',
      'expMilestoneRegenClaimed': 0,
      'raccoltaResilienzaSpesa': 0,
      'raccoltaVolontaSpesa': 0,
      'raccoltaMateriaSpesa': 0,
      'raccoltaOculumSpesa': 0,
      'levelUpDaAssegnare': 0,
      'monsterStatPoints': tipo == 'Mostro' ? livello * 9 : 0,
      'titoli': [],
      'trattiRazziali': [],
      'inventario': [],
      'skills': [],
      'arti': artiBase().map((x) => x.toJson()).toList(),
      'diarioPagine': [],
      'journalEntries': [],
      'draftNotes': [],
      'hiddenEyeStats': defaultHiddenEyeStats().map((x) => x.toJson()).toList(),
      'reputations': defaultReputations().map((x) => x.toJson()).toList(),
      'reputationsManuallyCleared': false,
      'logEventi': [],
      'campaignDifficulty': 'normale',
      'fortuna': 0,
      'fateTokens': 0,
      'userGuiScale': 1.0,
      'diarioRewardClaimedCount': 0,
      'campaignDifficultyStarterClaimed': false,
      'primaryColor': _OculumHomePageState.defaultPrimaryColor.toARGB32(),
      'secondaryColor': _OculumHomePageState.defaultSecondaryColor.toARGB32(),
      'tertiaryColor': _OculumHomePageState.defaultTertiaryColor.toARGB32(),
      'eyeUtilityColor': _OculumHomePageState.defaultEyeUtilityColor.toARGB32(),
      'backgroundTopColor': _OculumHomePageState.defaultBackgroundTopColor
          .toARGB32(),
      'backgroundMidColor': _OculumHomePageState.defaultBackgroundMidColor
          .toARGB32(),
      'backgroundBottomColor': _OculumHomePageState.defaultBackgroundBottomColor
          .toARGB32(),
      'eyePupilGlowColor': _OculumHomePageState.defaultEyePupilGlowColor
          .toARGB32(),
      'colorPreset': 'classic_reliquary',
      'colorDecorationPresetId': 'none',
      'colorGuiPresetId': 'classic_reliquary',
      'themeDecorationOpacityScale': 1.0,
      'themeDecorationGlowScale': 1.0,
      'themeDecorationIntensityScale': 1.0,
      'unlockedColorThemeIds': ['classic_reliquary'],
      'filtroPrimario': 'Tutti',
      'filtroSecondario': 'Tutti',
      'filtroTerziario': 'Tutti',
      'filtroExtraOcchio': 'Tutti',
      'filtroAmbiente': 'Tutti',
      'immaginePersonaggioBase64': '',
      'usaBarraVita': true,
      'mostraDannoCuraScheda': true,
      'mostraStrumentiManualeRapidi': true,
      'mostraBorsaCompatta': true,
      'mostraPartyScheda': true,
      'mostraTastiRapidiIndice': true,
      'mostraValoriEditabiliScheda': true,
      'scalaExpAutomatica': true,
      'sottraiStatsDaExpAggiunta': true,
      'mostraSempreScudoOculum': false,
      'coMasterCanSetCoMaster': false,
      'coMasterCanEditSheets': false,
      'masterKickRequiresConfirmation': true,
      'masterEnemyFullSheetVisibility': false,
      'masterPublicDiceVisible': false,
      'masterAskPublicDiceConfirmation': true,
      'relayAutoReconnect': true,
      'relayServerUrl': '',
      'relayRoomCode': '',
      'oculumUsername': '',
      'id': '',
      'sheetTag': '',
      'localUpdatedAt': DateTime.now().toIso8601String(),
      'inMasterParty': false,
      'countsForPartyStats': true,
      'masterSideOverride': '',
      'monsterBookCustomEntries': monsterBookCustomEntries
          .map((entry) => entry.toJson())
          .toList(),
      'monsterBookRemovedIds': monsterBookRemovedIds.toList()..sort(),
      'realtimeRevokedAccessTags': <String>[],
      'partyMembri': [],
      'fonteExpSelezionata': 'normale',
      'enemyGradeExp': '0',
      'elementColorOverrides': <String, int>{},
      'customDamageTypes': <String>[],
      'oculumStatFormulaColor': const Color(0xFF8B5CF6).toARGB32(),
    };
  }

  Map<String, dynamic> statoCorrenteJson() {
    assicuraTagSchede();

    return {
      'nome': nomeController.text,
      'tipoScheda': tipoSchedaController.text,
      'razza': razzaController.text,
      'livello': livelloController.text,
      'grado': gradoController.text,
      'exp': expController.text,
      'expNomePersonalizzato': expNomePersonalizzatoController.text,
      'puoEssereOsservato': puoEssereOsservato,
      'osservazionePuntiDaAssegnare': osservazionePuntiDisponibili(),
      'osservazioneStatScelta': osservazioneStatScelta,
      'osservazioneStatAssegnata': osservazioneStatAssegnataCompatibile(),
      'osservazionePuntiAssegnati': Map<String, int>.from(
        osservazionePuntiAssegnati,
      ),
      'osservazionePuntiApplicati': osservazionePuntiApplicati,
      'resilienza': resilienzaController.text,
      'volonta': volontaController.text,
      'materia': materiaController.text,
      'oculum': oculumController.text,
      'currentResilienza': currentResilienza().toString(),
      'currentVolonta': currentVolonta().toString(),
      'currentMateria': currentMateria().toString(),
      'currentOculum': currentOculum().toString(),
      'maxOculum': oculumMassimo(),
      'currentHp': currentHpController.text,
      'partialAwakeningHalfHpTriggered':
          schedePersonaggio.isNotEmpty &&
              schedaCorrente >= 0 &&
              schedaCorrente < schedePersonaggio.length
          ? readBoolValue(
              schedePersonaggio[schedaCorrente]['partialAwakeningHalfHpTriggered'],
            )
          : false,
      'hpTemp': hpTempController.text,
      'hpTempBonusConsumati': hpTempBonusConsumati,
      'scudo': scudoController.text,
      'scudoBonusConsumati': scudoBonusConsumati,
      'scudoCritico': scudoCriticoController.text,
      'scudoOculum': scudoOculumController.text,
      'scudoOculumMax': scudoOculumMaxController.text,
      'attaccoRapido': attaccoRapidoController.text,
      'cmRapido': cmRapidoController.text,
      'difesaRapida': difesaRapidaController.text,
      'reazioni': reazioniController.text,
      'reazioniVeloci': reazioniVelociController.text,
      'buffMalusRapidi': buffMalusRapidiController.text,
      'derivedResilienzaTotal': resilienzaTotale(),
      'derivedVolontaTotal': volontaTotale(),
      'derivedMateriaTotal': materiaTotale(),
      'derivedOculumTotal': oculumTotale(),
      'derivedMaxHp': maxHp(),
      'derivedDanno': dannoTotale(),
      'derivedDifesa': difesa(),
      'derivedVC': vc(),
      'derivedCM': cm(),
      'derivedIniziativa': iniziativa(),
      'derivedMovimento': movimento(),
      'derivedScudoOculum': scudoOculum(),
      'derivedScudoOculumMax': scudoOculumMax(),
      'derivedReazioni': reazioniTotali(),
      'derivedReazioniVeloci': reazioniVelociTotali(),
      'rebirthato': rebirthato,
      'linguaInglese': linguaInglese,
      'tutorialCompletato': tutorialCompletato,
      'modalitaDesktop': modalitaDesktop,
      'modalitaVeloce': modalitaVeloce,
      'modalitaLeggera': modalitaLeggera,
      'desktopSideMenuOpen': desktopSideMenuOpen,
      'background': backgroundController.text,
      'notePersonaggio': notePersonaggioController.text,
      'spriteAssetPath':
          schedaCorrente >= 0 && schedaCorrente < schedePersonaggio.length
          ? '${schedePersonaggio[schedaCorrente]['spriteAssetPath'] ?? ''}'
          : '',
      'textAttachments': textAttachments.map(
        (key, value) => MapEntry(
          key,
          value.map((item) => Map<String, dynamic>.from(item)).toList(),
        ),
      ),
      'obser': obserController.text,
      'ascensionDust': ascensionDustController.text,
      'ispirazioni': ispirazioniController.text,
      'superIspirazioni': superIspirazioniController.text,
      'ispirazioniOculum': ispirazioniOculumController.text,
      'karma': karmaController.text,
      'follia': folliaController.text,
      'folliaDaMostri': folliaDaMostri,
      'illnessArtSbloccata': illnessArtSbloccata,
      'oculumTiroPreparato': oculumTiroPreparato().toString(),
      'cenere': cenereController.text,
      'sessioniSenzaBisogni': sessioniSenzaBisogniController.text,
      'giorniSenzaCiboAcqua': giorniSenzaCiboAcquaController.text,
      'oculumCurrentDay': oculumCurrentDayController.text,
      'statoForzaAttivo': statoForzaAttivo,
      'statoForzaPronto': statoForzaPronto,
      'statoForzaTiriRimanenti': statoForzaTiriRimanenti,
      'malusTiriOculumPostEsplosione': malusTiriOculumPostEsplosione,
      'personaggioSvenuto': personaggioSvenuto,
      'cenereSvenimentoUltimoControllo': cenereSvenimentoUltimoControllo,
      'personaggioCaduto': personaggioCaduto,
      'feriteMorte': feriteMorte,
      'volontaVitale': volontaVitale,
      'tempResilienza': tempResilienza,
      'tempVolonta': tempVolonta,
      'tempMateria': tempMateria,
      'tempOculum': tempOculum,
      'schivateOculumConsumate': schivateOculumConsumate,
      'schivataOculumRiduzionePronta': schivataOculumRiduzionePronta,
      'schivataOculumEtichettaPronta': schivataOculumEtichettaPronta,
      'scudoSalvataggioAttivo': scudoSalvataggioAttivo,
      'vantaggioTiroSelezionato': vantaggioTiroSelezionato,
      'difficoltaTiro': difficoltaTiroController.text,
      'dannoOltreDifesa': dannoOltreDifesa,
      'dannoOltreScudi': dannoOltreScudi,
      'dannoBonusScudoPercent': dannoBonusScudoPercentController.text,
      'expMilestoneRegenClaimed': expMilestoneRegenClaimed,
      'raccoltaResilienzaSpesa': raccoltaResilienzaSpesa,
      'raccoltaVolontaSpesa': raccoltaVolontaSpesa,
      'raccoltaMateriaSpesa': raccoltaMateriaSpesa,
      'raccoltaOculumSpesa': raccoltaOculumSpesa,
      'levelUpDaAssegnare': levelUpDaAssegnare,
      'monsterStatPoints': monsterStatPoints,
      'titoli': titoli.map((x) => x.toJson()).toList(),
      'trattiRazziali': trattiRazziali.map((x) => x.toJson()).toList(),
      'inventario': inventario.map((x) => x.toJson()).toList(),
      'skills': skills.map((x) => x.toJson()).toList(),
      'arti': arti.map((x) => x.toJson()).toList(),
      'diarioPagine': List<String>.from(diarioPagine),
      'journalEntries': journalEntries.map((x) => x.toJson()).toList(),
      'draftNotes': draftNotes.map((x) => x.toJson()).toList(),
      'hiddenEyeStats': hiddenEyeStats.map((x) => x.toJson()).toList(),
      'reputations': reputations.map((x) => x.toJson()).toList(),
      'reputationsManuallyCleared': reputationsManuallyCleared,
      'logEventi': List<String>.from(logEventi),
      'campaignDifficulty': campaignDifficulty,
      'fortuna': fortuna,
      'fateTokens': fateTokens,
      'userGuiScale': userGuiScale,
      'diarioRewardClaimedCount': diarioRewardClaimedCount,
      'campaignDifficultyStarterClaimed': campaignDifficultyStarterClaimed,
      'primaryColor': primaryColor.toARGB32(),
      'secondaryColor': secondaryColor.toARGB32(),
      'tertiaryColor': tertiaryColor.toARGB32(),
      'eyeUtilityColor': eyeUtilityColor.toARGB32(),
      'backgroundTopColor': backgroundTopColor.toARGB32(),
      'backgroundMidColor': backgroundMidColor.toARGB32(),
      'backgroundBottomColor': backgroundBottomColor.toARGB32(),
      'eyePupilGlowColor': eyePupilGlowColor.toARGB32(),
      'colorPreset': colorPresetSelezionato,
      'colorDecorationPresetId': colorDecorationPresetId,
      'colorGuiPresetId': colorGuiPresetId,
      'themeDecorationOpacityScale': themeDecorationOpacityScale,
      'themeDecorationGlowScale': themeDecorationGlowScale,
      'themeDecorationIntensityScale': themeDecorationIntensityScale,
      'unlockedColorThemeIds': unlockedColorThemeIds.toList()..sort(),
      'filtroPrimario': filtroPrimario,
      'filtroSecondario': filtroSecondario,
      'filtroTerziario': filtroTerziario,
      'filtroExtraOcchio': filtroExtraOcchio,
      'filtroAmbiente': filtroAmbiente,
      'immaginePersonaggioBase64': immaginePersonaggio == null
          ? ''
          : base64Encode(immaginePersonaggio!),
      'usaBarraVita': usaBarraVita,
      'mostraDannoCuraScheda': mostraDannoCuraScheda,
      'mostraStrumentiManualeRapidi': mostraStrumentiManualeRapidi,
      'mostraBorsaCompatta': mostraBorsaCompatta,
      'mostraPartyScheda': mostraPartyScheda,
      'mostraTastiRapidiIndice': mostraTastiRapidiIndice,
      'mostraValoriEditabiliScheda': mostraValoriEditabiliScheda,
      'scalaExpAutomatica': scalaExpAutomatica,
      'sottraiStatsDaExpAggiunta': sottraiStatsDaExpAggiunta,
      'mostraSempreScudoOculum': mostraSempreScudoOculum,
      'coMasterCanSetCoMaster': coMasterCanSetCoMaster,
      'coMasterCanEditSheets': coMasterCanEditSheets,
      'masterKickRequiresConfirmation': masterKickRequiresConfirmation,
      'masterEnemyFullSheetVisibility': masterEnemyFullSheetVisibility,
      'masterPublicDiceVisible': masterPublicDiceVisible,
      'masterAskPublicDiceConfirmation': masterAskPublicDiceConfirmation,
      'relayAutoReconnect': relayAutoReconnect,
      'relayServerUrl': relayServerController.text,
      'relayRoomCode': relayRoomController.text,
      'oculumUsername': oculumUsernameController.text,
      'id': sheetTagAt(schedaCorrente),
      'sheetTag': sheetTagAt(schedaCorrente),
      'inMasterParty': sheetInMasterPartyAt(schedaCorrente),
      'countsForPartyStats': sheetCountsForPartyStatsAt(schedaCorrente),
      'masterSideOverride':
          schedaCorrente >= 0 && schedaCorrente < schedePersonaggio.length
          ? '${schedePersonaggio[schedaCorrente]['masterSideOverride'] ?? ''}'
          : '',
      'monsterBookCustomEntries': monsterBookCustomEntries
          .map((entry) => entry.toJson())
          .toList(),
      'monsterBookRemovedIds': monsterBookRemovedIds.toList()..sort(),
      'realtimeRevokedAccessTags':
          schedaCorrente >= 0 && schedaCorrente < schedePersonaggio.length
          ? currentSheetRevokedAccessTags().toList()
          : <String>[],
      'partyMembri': partyMembri
          .map((x) => Map<String, dynamic>.from(x))
          .toList(),
      'fonteExpSelezionata': fonteExpSelezionata,
      'enemyGradeExp': enemyGradeExpController.text,
      'elementColorOverrides': Map<String, int>.from(elementColorOverrides),
      'customDamageTypes': List<String>.from(customDamageTypes),
      'oculumStatFormulaColor': oculumStatFormulaColor.toARGB32(),
    };
  }

  void caricaStatoDaJson(Map<String, dynamic> json) {
    restoreMonsterBookCustomization(json);
    nomeController.text = '${json['nome'] ?? '???'}';
    tipoSchedaController.text = '${json['tipoScheda'] ?? 'Personaggio'}';
    razzaController.text = '${json['razza'] ?? ''}';
    livelloController.text = '${json['livello'] ?? '0'}';
    gradoController.text = '${json['grado'] ?? '0'}';
    expController.text = '${json['exp'] ?? '0'}';
    expNomePersonalizzatoController.text =
        '${json['expNomePersonalizzato'] ?? ''}';
    puoEssereOsservato = readBoolValue(json['puoEssereOsservato']);
    osservazioneStatScelta = normalizeObservationStat(
      '${json['osservazioneStatScelta'] ?? 'Resilienza'}',
    );
    osservazioneStatAssegnata = normalizeObservationStat(
      '${json['osservazioneStatAssegnata'] ?? ''}',
      allowEmpty: true,
    );
    osservazionePuntiAssegnati = oculumNormalizeObservationAssignedCounts(
      json['osservazionePuntiAssegnati'],
      legacyAssigned: osservazioneStatAssegnata,
    );
    osservazionePuntiApplicati = readBoolValue(
      json['osservazionePuntiApplicati'],
      fallback:
          puoEssereOsservato &&
          oculumObservationAssignedTotal(osservazionePuntiAssegnati) > 0,
    );
    osservazionePuntiDaAssegnare = osservazionePuntiDisponibili();

    resilienzaController.text = '${json['resilienza'] ?? '3'}';
    volontaController.text = '${json['volonta'] ?? '1'}';
    materiaController.text = '${json['materia'] ?? '0'}';
    oculumController.text = '${json['oculum'] ?? '1'}';
    final hasCurrentResilienza = json.containsKey('currentResilienza');
    final hasCurrentVolonta = json.containsKey('currentVolonta');
    final hasCurrentMateria = json.containsKey('currentMateria');
    final hasCurrentOculum = json.containsKey('currentOculum');
    currentResilienzaController.text = readIntValue(
      json['currentResilienza'],
      fallback: readIntValue(json['resilienza'], fallback: 3),
    ).toString();
    currentVolontaController.text = readIntValue(
      json['currentVolonta'],
      fallback: readIntValue(json['volonta'], fallback: 1),
    ).toString();
    currentMateriaController.text = readIntValue(
      json['currentMateria'],
      fallback: readIntValue(json['materia']),
    ).toString();
    final legacyOculumMax = readIntValue(
      json['maxOculum'],
      fallback: readIntValue(json['oculum'], fallback: 1),
    );
    currentOculumController.text = readIntValue(
      json['currentOculum'],
      fallback: legacyOculumMax,
    ).toString();

    currentHpController.text = '${json['currentHp'] ?? '30'}';
    hpTempController.text = '${json['hpTemp'] ?? '0'}';
    hpTempBonusConsumati = readIntValue(json['hpTempBonusConsumati']);
    scudoController.text = '${json['scudo'] ?? '0'}';
    scudoBonusConsumati = readIntValue(json['scudoBonusConsumati']);
    scudoCriticoController.text = '${json['scudoCritico'] ?? '0'}';
    scudoOculumController.text = '${json['scudoOculum'] ?? '0'}';
    scudoOculumMaxController.text = '${json['scudoOculumMax'] ?? '0'}';
    attaccoRapidoController.text = '${json['attaccoRapido'] ?? '0'}';
    cmRapidoController.text = '${json['cmRapido'] ?? '0'}';
    difesaRapidaController.text = '${json['difesaRapida'] ?? '0'}';
    reazioniController.text = '${json['reazioni'] ?? '1'}';
    reazioniVelociController.text = '${json['reazioniVeloci'] ?? '0'}';
    buffMalusRapidiController.text = '${json['buffMalusRapidi'] ?? ''}';

    rebirthato = readBoolValue(json['rebirthato']);
    linguaInglese = readBoolValue(json['linguaInglese']);
    tutorialCompletato = readBoolValue(json['tutorialCompletato']);
    modalitaDesktop = readBoolValue(json['modalitaDesktop']);
    modalitaVeloce = readBoolValue(json['modalitaVeloce']);
    modalitaLeggera = readBoolValue(json['modalitaLeggera']);
    desktopSideMenuOpen = readBoolValue(json['desktopSideMenuOpen']);
    backgroundController.text =
        '${json['background'] ?? 'Scrivi qui il passato, lo scopo, i legami, le paure e il destino del personaggio.'}';
    notePersonaggioController.text = '${json['notePersonaggio'] ?? ''}';
    textAttachments.clear();
    final attachmentsRaw = json['textAttachments'];
    if (attachmentsRaw is Map) {
      for (final entry in attachmentsRaw.entries) {
        final key = '${entry.key}'.trim();
        if (key.isEmpty || entry.value is! List) continue;
        final values = <Map<String, dynamic>>[];
        for (final raw in entry.value as List) {
          if (raw is! Map) continue;
          final item = Map<String, dynamic>.from(raw);
          final type = '${item['type'] ?? ''}'.trim();
          final path = '${item['path'] ?? ''}'.trim();
          final url = '${item['url'] ?? ''}'.trim();
          if (type.isEmpty || (path.isEmpty && url.isEmpty)) continue;
          values.add(item);
        }
        if (values.isNotEmpty) textAttachments[key] = values;
      }
    }

    obserController.text = '${json['obser'] ?? '0'}';
    ascensionDustController.text = '${json['ascensionDust'] ?? '0'}';
    ispirazioniController.text = '${json['ispirazioni'] ?? '0'}';
    superIspirazioniController.text = '${json['superIspirazioni'] ?? '0'}';
    ispirazioniOculumController.text = '${json['ispirazioniOculum'] ?? '0'}';
    karmaController.text = '${json['karma'] ?? '0'}';
    folliaController.text = readIntValue(json['follia']).toString();
    folliaDaMostri = readBoolValue(json['folliaDaMostri']);
    illnessArtSbloccata = readBoolValue(json['illnessArtSbloccata']);
    oculumTiroController.text = readIntValue(
      json['oculumTiroPreparato'],
    ).toString();

    cenereController.text = '${json['cenere'] ?? '0'}';
    sessioniSenzaBisogniController.text =
        '${json['sessioniSenzaBisogni'] ?? '0'}';
    giorniSenzaCiboAcquaController.text =
        '${json['giorniSenzaCiboAcqua'] ?? '0'}';
    oculumCurrentDayController.text =
        '${json['oculumCurrentDay'] ?? json['giornoOculum'] ?? '1'}';
    statoForzaAttivo = '${json['statoForzaAttivo'] ?? ''}';
    statoForzaPronto = readBoolValue(json['statoForzaPronto'], fallback: true);
    statoForzaTiriRimanenti = readIntValue(json['statoForzaTiriRimanenti']);
    malusTiriOculumPostEsplosione = readIntValue(
      json['malusTiriOculumPostEsplosione'],
    ).clamp(-1, 0).toInt();
    personaggioSvenuto = readBoolValue(json['personaggioSvenuto']);
    cenereSvenimentoUltimoControllo = readIntValue(
      json['cenereSvenimentoUltimoControllo'],
    );
    personaggioCaduto = readBoolValue(json['personaggioCaduto']);
    feriteMorte = readIntValue(json['feriteMorte']).clamp(0, 3).toInt();
    volontaVitale = readIntValue(json['volontaVitale']).clamp(0, 3).toInt();

    tempResilienza = readIntValue(json['tempResilienza']);
    tempVolonta = readIntValue(json['tempVolonta']);
    tempMateria = readIntValue(json['tempMateria']);
    tempOculum = readIntValue(json['tempOculum']);
    schivateOculumConsumate = readIntValue(json['schivateOculumConsumate']);
    schivataOculumRiduzionePronta = readIntValue(
      json['schivataOculumRiduzionePronta'],
    );
    schivataOculumEtichettaPronta =
        '${json['schivataOculumEtichettaPronta'] ?? ''}';
    scudoSalvataggioAttivo = readBoolValue(json['scudoSalvataggioAttivo']);
    vantaggioTiroSelezionato = canonicalVantaggioTiroName(
      '${json['vantaggioTiroSelezionato'] ?? 'Normale'}',
    );
    difficoltaTiroController.text = '${json['difficoltaTiro'] ?? '0'}';
    dannoOltreDifesa = readBoolValue(json['dannoOltreDifesa']);
    dannoOltreScudi = readBoolValue(json['dannoOltreScudi']);
    dannoBonusScudoPercentController.text =
        '${json['dannoBonusScudoPercent'] ?? '0'}';
    expMilestoneRegenClaimed = readIntValue(json['expMilestoneRegenClaimed']);

    raccoltaResilienzaSpesa = readIntValue(json['raccoltaResilienzaSpesa']);
    raccoltaVolontaSpesa = readIntValue(json['raccoltaVolontaSpesa']);
    raccoltaMateriaSpesa = readIntValue(json['raccoltaMateriaSpesa']);
    raccoltaOculumSpesa = readIntValue(json['raccoltaOculumSpesa']);

    levelUpDaAssegnare = readIntValue(json['levelUpDaAssegnare']);
    monsterStatPoints = readIntValue(json['monsterStatPoints']);

    final titoliRaw = json['titoli'];
    titoli
      ..clear()
      ..addAll(
        (titoliRaw is List ? titoliRaw : const []).whereType<Map>().map(
          (x) => OculumTitle.fromJson(Map<String, dynamic>.from(x)),
        ),
      );

    final trattiRazzialiRaw = json['trattiRazziali'];
    trattiRazziali
      ..clear()
      ..addAll(
        (trattiRazzialiRaw is List ? trattiRazzialiRaw : const [])
            .whereType<Map>()
            .map((x) => OculumTitle.fromJson(Map<String, dynamic>.from(x))),
      );

    final inventarioRaw = json['inventario'];
    inventario
      ..clear()
      ..addAll(
        (inventarioRaw is List ? inventarioRaw : const []).whereType<Map>().map(
          (x) => InventoryItem.fromJson(Map<String, dynamic>.from(x)),
        ),
      );

    final skillsRaw = json['skills'];
    skills
      ..clear()
      ..addAll(
        (skillsRaw is List ? skillsRaw : const []).whereType<Map>().map(
          (x) => CharacterSkill.fromJson(Map<String, dynamic>.from(x)),
        ),
      );

    final artiRaw = json['arti'];
    arti
      ..clear()
      ..addAll(
        (artiRaw is List ? artiRaw : const []).whereType<Map>().map(
          (x) => CharacterArt.fromJson(Map<String, dynamic>.from(x)),
        ),
      );

    assicuraArtiBase();
    normalizzaOpenAttiveSingole();

    final diarioRaw = json['diarioPagine'];
    diarioPagine
      ..clear()
      ..addAll((diarioRaw is List ? diarioRaw : const []).map((x) => '$x'));

    final journalRaw = json['journalEntries'];
    journalEntries
      ..clear()
      ..addAll(
        (journalRaw is List ? journalRaw : const []).whereType<Map>().map(
          (x) => JournalEntry.fromJson(Map<String, dynamic>.from(x)),
        ),
      );

    final draftRaw = json['draftNotes'];
    draftNotes
      ..clear()
      ..addAll(
        (draftRaw is List ? draftRaw : const []).whereType<Map>().map(
          (x) => DraftNote.fromJson(Map<String, dynamic>.from(x)),
        ),
      );

    final hiddenEyeRaw = json['hiddenEyeStats'];
    hiddenEyeStats
      ..clear()
      ..addAll(
        (hiddenEyeRaw is List ? hiddenEyeRaw : const []).whereType<Map>().map(
          (x) => HiddenEyeStat.fromJson(Map<String, dynamic>.from(x)),
        ),
      );
    ensureHiddenEyeDefaults();

    final reputationsRaw = json['reputations'];
    reputationsManuallyCleared =
        readBoolValue(json['reputationsManuallyCleared']) ||
        (json.containsKey('reputations') &&
            reputationsRaw is List &&
            reputationsRaw.isEmpty);
    reputations
      ..clear()
      ..addAll(
        (reputationsRaw is List ? reputationsRaw : const [])
            .whereType<Map>()
            .map((x) => ReputationEntry.fromJson(Map<String, dynamic>.from(x)))
            .where((entry) => entry.cityName.trim().isNotEmpty),
      );
    ensureReputationDefaults();

    campaignDifficulty = '${json['campaignDifficulty'] ?? 'normale'}';
    if (!{
      'oculum',
      'difficile',
      'medio',
      'facile',
      'normale',
    }.contains(campaignDifficulty)) {
      campaignDifficulty = 'normale';
    }
    fortuna = readIntValue(json['fortuna']);
    fateTokens = readIntValue(json['fateTokens']);
    userGuiScale = readDoubleValue(
      json['userGuiScale'],
      fallback: 1.0,
    ).clamp(0.82, 1.18).toDouble();
    diarioRewardClaimedCount = readIntValue(json['diarioRewardClaimedCount']);
    campaignDifficultyStarterClaimed = readBoolValue(
      json['campaignDifficultyStarterClaimed'],
    );

    final logRaw = json['logEventi'];
    logEventi
      ..clear()
      ..addAll((logRaw is List ? logRaw : const []).map((x) => '$x'));

    primaryColor = Color(
      readIntValue(
        json['primaryColor'],
        fallback: _OculumHomePageState.defaultPrimaryColor.toARGB32(),
      ),
    );
    secondaryColor = Color(
      readIntValue(
        json['secondaryColor'],
        fallback: _OculumHomePageState.defaultSecondaryColor.toARGB32(),
      ),
    );
    tertiaryColor = Color(
      readIntValue(
        json['tertiaryColor'],
        fallback: _OculumHomePageState.defaultTertiaryColor.toARGB32(),
      ),
    );
    eyeUtilityColor = Color(
      readIntValue(
        json['eyeUtilityColor'],
        fallback: _OculumHomePageState.defaultEyeUtilityColor.toARGB32(),
      ),
    );
    backgroundTopColor = Color(
      readIntValue(
        json['backgroundTopColor'],
        fallback: _OculumHomePageState.defaultBackgroundTopColor.toARGB32(),
      ),
    );
    backgroundMidColor = Color(
      readIntValue(
        json['backgroundMidColor'],
        fallback: _OculumHomePageState.defaultBackgroundMidColor.toARGB32(),
      ),
    );
    backgroundBottomColor = Color(
      readIntValue(
        json['backgroundBottomColor'],
        fallback: _OculumHomePageState.defaultBackgroundBottomColor.toARGB32(),
      ),
    );
    eyePupilGlowColor = Color(
      readIntValue(
        json['eyePupilGlowColor'],
        fallback: _OculumHomePageState.defaultEyePupilGlowColor.toARGB32(),
      ),
    );
    colorPresetSelezionato = '${json['colorPreset'] ?? 'custom'}';
    if (colorPresetSelezionato.trim().isEmpty ||
        !colorPresets.any((preset) => preset.id == colorPresetSelezionato)) {
      colorPresetSelezionato = 'custom';
    }
    normalizzaContrastoTemaAttivo();
    colorDecorationPresetId = '${json['colorDecorationPresetId'] ?? 'none'}';
    if (colorDecorationPresetId != 'none' &&
        (colorDecorationPresetId == 'custom' ||
            colorDecorationPresetId.trim().isEmpty ||
            !colorPresets.any(
              (preset) => preset.id == colorDecorationPresetId,
            ))) {
      colorDecorationPresetId = 'classic_reliquary';
    }
    colorGuiPresetId = '${json['colorGuiPresetId'] ?? colorDecorationPresetId}';
    if (colorGuiPresetId == 'custom' ||
        colorGuiPresetId.trim().isEmpty ||
        (!isBuiltInGuiModeId(colorGuiPresetId) &&
            !colorPresets.any((preset) => preset.id == colorGuiPresetId))) {
      colorGuiPresetId = colorDecorationPresetId == 'none'
          ? 'classic_reliquary'
          : colorDecorationPresetId;
    }
    themeDecorationOpacityScale = readDoubleValue(
      json['themeDecorationOpacityScale'],
      fallback: 1.0,
    ).clamp(0.25, 2.5).toDouble();
    themeDecorationGlowScale = readDoubleValue(
      json['themeDecorationGlowScale'],
      fallback: 1.0,
    ).clamp(0.0, 2.5).toDouble();
    themeDecorationIntensityScale = readDoubleValue(
      json['themeDecorationIntensityScale'],
      fallback: 1.0,
    ).clamp(0.35, 2.5).toDouble();
    final unlockedThemesRaw = json['unlockedColorThemeIds'];
    unlockedColorThemeIds
      ..clear()
      ..add('classic_reliquary')
      ..addAll(
        (unlockedThemesRaw is List ? unlockedThemesRaw : const [])
            .map((id) => '$id')
            .where((id) => colorPresets.any((preset) => preset.id == id)),
      );
    ensureSecretThemeUnlocks();

    elementColorOverrides
      ..clear()
      ..addAll(
        (json['elementColorOverrides'] is Map)
            ? Map<String, int>.from(
                (json['elementColorOverrides'] as Map).map(
                  (key, value) => MapEntry('$key', readIntValue(value)),
                ),
              )
            : <String, int>{},
      );
    final customDamageTypesRaw = json['customDamageTypes'];
    customDamageTypes
      ..clear()
      ..addAll(
        (customDamageTypesRaw is List ? customDamageTypesRaw : const [])
            .map((x) => cleanUiText('$x').trim())
            .where((x) => x.isNotEmpty),
      );
    oculumStatFormulaColor = Color(
      readIntValue(
        json['oculumStatFormulaColor'],
        fallback: const Color(0xFF8B5CF6).toARGB32(),
      ),
    );

    filtroPrimario = '${json['filtroPrimario'] ?? 'Tutti'}';
    filtroSecondario = '${json['filtroSecondario'] ?? 'Tutti'}';
    filtroTerziario = '${json['filtroTerziario'] ?? 'Tutti'}';
    filtroExtraOcchio = '${json['filtroExtraOcchio'] ?? 'Tutti'}';
    filtroAmbiente = '${json['filtroAmbiente'] ?? 'Tutti'}';

    usaBarraVita = readBoolValue(json['usaBarraVita'], fallback: true);
    mostraDannoCuraScheda = readBoolValue(
      json['mostraDannoCuraScheda'],
      fallback: true,
    );
    mostraStrumentiManualeRapidi = readBoolValue(
      json['mostraStrumentiManualeRapidi'],
      fallback: true,
    );
    mostraBorsaCompatta = readBoolValue(
      json['mostraBorsaCompatta'],
      fallback: true,
    );
    mostraPartyScheda = readBoolValue(
      json['mostraPartyScheda'],
      fallback: true,
    );
    mostraTastiRapidiIndice = readBoolValue(
      json['mostraTastiRapidiIndice'],
      fallback: true,
    );
    mostraValoriEditabiliScheda = readBoolValue(
      json['mostraValoriEditabiliScheda'],
      fallback: true,
    );
    scalaExpAutomatica = readBoolValue(
      json['scalaExpAutomatica'],
      fallback: true,
    );
    sottraiStatsDaExpAggiunta = readBoolValue(
      json['sottraiStatsDaExpAggiunta'],
      fallback: true,
    );
    mostraSempreScudoOculum = readBoolValue(json['mostraSempreScudoOculum']);
    coMasterCanSetCoMaster = readBoolValue(json['coMasterCanSetCoMaster']);
    coMasterCanEditSheets = readBoolValue(json['coMasterCanEditSheets']);
    masterKickRequiresConfirmation = readBoolValue(
      json['masterKickRequiresConfirmation'],
      fallback: masterKickRequiresConfirmation,
    );
    masterEnemyFullSheetVisibility = readBoolValue(
      json['masterEnemyFullSheetVisibility'],
    );
    masterPublicDiceVisible = readBoolValue(json['masterPublicDiceVisible']);
    masterAskPublicDiceConfirmation = readBoolValue(
      json['masterAskPublicDiceConfirmation'],
      fallback: true,
    );
    relayAutoReconnect = readBoolValue(
      json['relayAutoReconnect'],
      fallback: true,
    );
    relayServerController.text = '${json['relayServerUrl'] ?? ''}';
    relayRoomController.text = '${json['relayRoomCode'] ?? ''}';
    relayRoomCode = relayRoomController.text.trim().toUpperCase();

    fonteExpSelezionata = '${json['fonteExpSelezionata'] ?? 'normale'}';
    if (!['normale', 'miniboss', 'boss'].contains(fonteExpSelezionata)) {
      fonteExpSelezionata = 'normale';
    }
    enemyGradeExpController.text =
        '${json['enemyGradeExp'] ?? gradoController.text}';

    final imageRaw = '${json['immaginePersonaggioBase64'] ?? ''}';
    if (imageRaw.isNotEmpty) {
      try {
        immaginePersonaggio = base64Decode(imageRaw);
      } catch (_) {
        immaginePersonaggio = null;
      }
    } else {
      immaginePersonaggio = null;
    }

    final partyRaw = json['partyMembri'];
    partyMembri
      ..clear()
      ..addAll(
        (partyRaw is List ? partyRaw : const []).whereType<Map>().map(
          (x) => Map<String, dynamic>.from(x),
        ),
      );

    assicuraTagSchede();

    syncCurrentStatsToMax(
      resetResilienzaToMax: !hasCurrentResilienza,
      resetVolontaToMax: !hasCurrentVolonta,
      resetMateriaToMax: !hasCurrentMateria,
      resetOculumToMax: !hasCurrentOculum,
    );
  }

  String get _backupSaveKey1 => '${_OculumHomePageState.saveKey}_backup_1';
  String get _backupSaveKey2 => '${_OculumHomePageState.saveKey}_backup_2';
  String get _backupSaveKey3 => '${_OculumHomePageState.saveKey}_backup_3';
  String get _verifiedSaveKey => '${_OculumHomePageState.saveKey}_verified';
  String get _pendingSaveKey => '${_OculumHomePageState.saveKey}_pending';
  String get _diaryArchiveSaveKey =>
      '${_OculumHomePageState.saveKey}_diary_archive_v1';

  Future<String?> _readSaveBlob(SharedPreferences prefs, String key) async {
    if (kIsWeb) {
      try {
        final indexed = await oculumWebSaveRead(key);
        if (indexed != null && indexed.isNotEmpty) return indexed;
      } catch (error) {
        debugPrint('IndexedDB read fallback for $key: $error');
      }
    }
    return prefs.getString(key);
  }

  Future<bool> _writeSaveBlob(
    SharedPreferences prefs,
    String key,
    String value,
  ) async {
    if (kIsWeb) {
      try {
        if (await oculumWebSaveWrite(key, value)) return true;
      } catch (error) {
        debugPrint('IndexedDB write fallback for $key: $error');
      }
    }
    return prefs.setString(key, value);
  }

  Future<bool> _removeSaveBlob(SharedPreferences prefs, String key) async {
    var indexedRemoved = false;
    if (kIsWeb) {
      try {
        indexedRemoved = await oculumWebSaveDelete(key);
      } catch (error) {
        debugPrint('IndexedDB delete fallback for $key: $error');
      }
    }
    final legacyRemoved = await prefs.remove(key);
    return indexedRemoved || legacyRemoved;
  }

  Set<String> get _knownTopLevelSaveKeys => const <String>{
    'saveVersion',
    'saveRevision',
    'savedAt',
    'multiScheda',
    'schedaCorrente',
    'schedePersonaggio',
    'activeCampaignId',
    'campaigns',
    'oculumFriends',
    'oculumFriendRequests',
    'oculumSentFriendRequests',
    'blockedOculumFriends',
    'oculumUsername',
    'masterKickRequiresConfirmation',
    'masterEnemyFullSheetVisibility',
    'masterPublicDiceVisible',
    'masterAskPublicDiceConfirmation',
  };

  void _memorizzaCampiTopLevelSconosciuti(Map<String, dynamic> data) {
    extraTopLevelSaveFields
      ..clear()
      ..addAll(
        Map<String, dynamic>.fromEntries(
          data.entries.where(
            (entry) => !_knownTopLevelSaveKeys.contains(entry.key),
          ),
        ),
      );
  }

  List<Map<String, dynamic>> _sheetsFromSaveData(Map<String, dynamic> data) {
    final sheets = <Map<String, dynamic>>[];

    void addSheets(dynamic value) {
      if (value is! List) return;
      for (final entry in value) {
        if (entry is Map) {
          sheets.add(Map<String, dynamic>.from(entry));
        }
      }
    }

    addSheets(data['schedePersonaggio']);

    final campaigns = data['campaigns'];
    if (campaigns is List) {
      for (final campaign in campaigns.whereType<Map>()) {
        addSheets(campaign['schedePersonaggio']);
      }
    }

    return sheets;
  }

  bool _sheetLooksMeaningful(Map<String, dynamic> sheet) {
    final name = '${sheet['nome'] ?? ''}'.trim();
    if (name.isNotEmpty && name != '???') return true;

    final type = '${sheet['tipoScheda'] ?? ''}'.trim();
    if (type.isNotEmpty && type != 'Personaggio') return true;

    for (final key in const <String>[
      'livello',
      'grado',
      'exp',
      'obser',
      'ascensionDust',
      'ispirazioni',
      'superIspirazioni',
      'ispirazioniOculum',
      'karma',
    ]) {
      if (readIntValue(sheet[key]) != 0) return true;
    }

    for (final key in const <String>[
      'titoli',
      'inventario',
      'skills',
      'diarioPagine',
      'logEventi',
      'partyMembri',
    ]) {
      final value = sheet[key];
      if (value is List && value.isNotEmpty) return true;
    }

    final background = '${sheet['background'] ?? ''}'.trim();
    if (background.isNotEmpty &&
        background !=
            'Scrivi qui il passato, lo scopo, i legami, le paure e il destino del personaggio.') {
      return true;
    }

    if ('${sheet['notePersonaggio'] ?? ''}'.trim().isNotEmpty) return true;
    if ('${sheet['immaginePersonaggioBase64'] ?? ''}'.trim().isNotEmpty) {
      return true;
    }

    return false;
  }

  bool _rawLooksLikeMeaningfulSave(String? raw) {
    if (raw == null || raw.trim().isEmpty) return false;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return false;
      return _saveDataLooksMeaningful(Map<String, dynamic>.from(decoded));
    } catch (_) {
      // Anche un JSON non leggibile non va cancellato automaticamente.
      // Potrebbe essere un salvataggio vecchio o parzialmente corrotto da recuperare.
      return true;
    }
  }

  bool _saveDataLooksMeaningful(Map<String, dynamic> data) {
    final sheets = _sheetsFromSaveData(data);
    if (sheets.any(_sheetLooksMeaningful)) return true;

    final campaigns = data['campaigns'];
    if (campaigns is List && campaigns.length > 1) return true;

    for (final key in const <String>[
      'oculumFriends',
      'oculumFriendRequests',
      'oculumSentFriendRequests',
      'blockedOculumFriends',
    ]) {
      final value = data[key];
      if (value is List && value.isNotEmpty) return true;
    }

    return false;
  }

  String _normalizeDiaryKey(String value) {
    return cleanUiText(
      value,
    ).trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  String _normalizeDiaryPage(String value) {
    return cleanUiText(value)
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  bool _diaryPageLooksPlaceholder(String page) {
    final normalized = _normalizeDiaryPage(page);
    if (normalized.isEmpty) return true;
    if (normalized == 'vuota' || normalized == 'empty') return true;
    return RegExp(
      r'^pagina\s+\d+\s*-\s*scrivi qui memoria',
    ).hasMatch(normalized);
  }

  List<String> _diaryPagesFromSheet(Map<String, dynamic> sheet) {
    final raw = sheet['diarioPagine'];
    if (raw is! List) return <String>[];
    return raw.map((x) => cleanUiText('$x')).toList();
  }

  List<String> _diarySheetArchiveKeys(
    Map<String, dynamic> sheet,
    int index, {
    String? campaignId,
  }) {
    final keys = <String>[];
    final seen = <String>{};

    void addKey(String key) {
      final clean = key.trim();
      if (clean.isEmpty || !seen.add(clean)) return;
      keys.add(clean);
    }

    final prefix = campaignId == null || campaignId.trim().isEmpty
        ? 'global'
        : 'campaign:${_normalizeDiaryKey(campaignId)}';

    for (final key in const <String>['sheetTag', 'id']) {
      final value = _normalizeDiaryKey('${sheet[key] ?? ''}');
      if (value.isNotEmpty && value != '---') {
        addKey('$prefix/$key:$value');
        addKey('$key:$value');
      }
    }

    final name = _normalizeDiaryKey('${sheet['nome'] ?? ''}');
    final type = _normalizeDiaryKey('${sheet['tipoScheda'] ?? ''}');
    if (name.isNotEmpty && name != '???') {
      addKey('$prefix/name:$type/$name');
      addKey('name:$type/$name');
    }

    addKey('$prefix/index:$index');
    return keys;
  }

  Map<String, dynamic> _emptyDiaryArchive() {
    return <String, dynamic>{
      'version': 1,
      'updatedAt': DateTime.now().toIso8601String(),
      'sheets': <String, dynamic>{},
    };
  }

  Map<String, dynamic> _decodeDiaryArchive(String? raw) {
    if (raw == null || raw.trim().isEmpty) return _emptyDiaryArchive();

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return _emptyDiaryArchive();
      final archive = Map<String, dynamic>.from(decoded);
      if (archive['sheets'] is! Map) {
        archive['sheets'] = <String, dynamic>{};
      }
      return archive;
    } catch (_) {
      return _emptyDiaryArchive();
    }
  }

  List<String> _archiveDiaryPages(dynamic value) {
    if (value is Map && value['pages'] is List) {
      return (value['pages'] as List).map((x) => cleanUiText('$x')).toList();
    }
    if (value is List) {
      return value.map((x) => cleanUiText('$x')).toList();
    }
    return <String>[];
  }

  int _diaryPageQuality(String page) {
    if (_diaryPageLooksPlaceholder(page)) return 0;
    final clean = cleanUiText(page).trim();
    if (clean.isEmpty) return 0;
    final words = clean.split(RegExp(r'\s+')).where((x) => x.isNotEmpty).length;
    return clean.length + words * 6;
  }

  String firmaDiarioSalvataggio(Map<String, dynamic> data) {
    final tokens = <String>[];

    void collectSheetList(dynamic rawSheets, {String? campaignId}) {
      if (rawSheets is! List) return;

      for (int i = 0; i < rawSheets.length; i++) {
        final rawSheet = rawSheets[i];
        if (rawSheet is! Map) continue;
        final sheet = Map<String, dynamic>.from(rawSheet);
        final pages = _diaryPagesFromSheet(sheet)
            .where((page) => !_diaryPageLooksPlaceholder(page))
            .map(_normalizeDiaryPage)
            .where((page) => page.isNotEmpty)
            .toList(growable: false);
        if (pages.isEmpty) continue;

        tokens.addAll(_diarySheetArchiveKeys(sheet, i, campaignId: campaignId));
        tokens.addAll(pages);
      }
    }

    collectSheetList(data['schedePersonaggio']);

    final campaigns = data['campaigns'];
    if (campaigns is List) {
      for (final rawCampaign in campaigns.whereType<Map>()) {
        final campaign = Map<String, dynamic>.from(rawCampaign);
        collectSheetList(
          campaign['schedePersonaggio'],
          campaignId: '${campaign['id'] ?? ''}',
        );
      }
    }

    if (tokens.isEmpty) return '';
    final encoded = jsonEncode(tokens);
    return '${encoded.length}:${encoded.hashCode}';
  }

  bool _diaryListContainsNormalized(List<String> pages, String candidate) {
    final normalized = _normalizeDiaryPage(candidate);
    if (normalized.isEmpty) return true;
    return pages.any((page) => _normalizeDiaryPage(page) == normalized);
  }

  bool _diaryCandidateExtendsCurrent(String current, String candidate) {
    final currentNormalized = _normalizeDiaryPage(current);
    final candidateNormalized = _normalizeDiaryPage(candidate);
    if (currentNormalized.length < 24) return false;
    if (candidateNormalized.length <= currentNormalized.length + 30) {
      return false;
    }
    return candidateNormalized.startsWith(currentNormalized);
  }

  bool _mergeDiaryPagesIntoSlotList(
    List<String> target,
    List<String> incoming, {
    bool replaceMeaningfulWithRicher = false,
    bool recoverLostContinuations = false,
  }) {
    var changed = false;

    for (int i = 0; i < incoming.length; i++) {
      final candidate = cleanUiText(incoming[i]).trimRight();
      if (_normalizeDiaryPage(candidate).isEmpty) continue;

      if (i >= target.length) {
        if (!_diaryListContainsNormalized(target, candidate)) {
          target.add(candidate);
          changed = true;
        }
        continue;
      }

      final current = target[i];
      final currentQuality = _diaryPageQuality(current);
      final candidateQuality = _diaryPageQuality(candidate);
      final sameText =
          _normalizeDiaryPage(current) == _normalizeDiaryPage(candidate);

      if (sameText) continue;

      if (currentQuality == 0 && candidateQuality > 0) {
        target[i] = candidate;
        changed = true;
      } else if (recoverLostContinuations &&
          _diaryCandidateExtendsCurrent(current, candidate) &&
          !_diaryListContainsNormalized(target, candidate)) {
        target[i] = candidate;
        changed = true;
      } else if (replaceMeaningfulWithRicher &&
          candidateQuality > currentQuality + 30 &&
          !_diaryListContainsNormalized(target, candidate)) {
        target[i] = candidate;
        changed = true;
      }
    }

    return changed;
  }

  List<String> _preserveDiaryPagesForSheetSave(
    Map<String, dynamic> next,
    Map<String, dynamic> previous,
  ) {
    final pages = _diaryPagesFromSheet(next);
    _mergeDiaryPagesIntoSlotList(
      pages,
      _diaryPagesFromSheet(previous),
      recoverLostContinuations: true,
    );
    return pages;
  }

  bool _mergeDiaryPagesIntoArchiveEntry(
    Map<String, dynamic> entry,
    List<String> incoming,
  ) {
    final pages = _archiveDiaryPages(entry['pages']);
    final changed = _mergeDiaryPagesIntoSlotList(
      pages,
      incoming,
      replaceMeaningfulWithRicher: true,
    );
    if (changed || entry['pages'] is! List) {
      entry['pages'] = pages;
      entry['updatedAt'] = DateTime.now().toIso8601String();
    }
    return changed;
  }

  int _mergeDiariesFromSaveDataIntoArchive(
    Map<String, dynamic> archive,
    Map<String, dynamic> data,
  ) {
    final sheetsArchive = Map<String, dynamic>.from(
      archive['sheets'] is Map ? archive['sheets'] as Map : const {},
    );
    var changed = 0;

    void mergeSheetList(dynamic rawSheets, {String? campaignId}) {
      if (rawSheets is! List) return;

      for (int i = 0; i < rawSheets.length; i++) {
        final rawSheet = rawSheets[i];
        if (rawSheet is! Map) continue;
        final sheet = Map<String, dynamic>.from(rawSheet);
        final pages = _diaryPagesFromSheet(sheet);
        if (pages.every(_diaryPageLooksPlaceholder)) continue;

        final keys = _diarySheetArchiveKeys(sheet, i, campaignId: campaignId);

        for (final key in keys) {
          final rawEntry = sheetsArchive[key];
          final entry = rawEntry is Map
              ? Map<String, dynamic>.from(rawEntry)
              : <String, dynamic>{};
          entry['name'] = '${sheet['nome'] ?? ''}';
          entry['type'] = '${sheet['tipoScheda'] ?? ''}';
          entry['sheetTag'] = '${sheet['sheetTag'] ?? sheet['id'] ?? ''}';
          entry['campaignId'] = campaignId ?? '';

          if (_mergeDiaryPagesIntoArchiveEntry(entry, pages)) {
            changed++;
          }
          sheetsArchive[key] = entry;
        }
      }
    }

    mergeSheetList(data['schedePersonaggio']);

    final campaigns = data['campaigns'];
    if (campaigns is List) {
      for (final rawCampaign in campaigns.whereType<Map>()) {
        final campaign = Map<String, dynamic>.from(rawCampaign);
        mergeSheetList(
          campaign['schedePersonaggio'],
          campaignId: '${campaign['id'] ?? ''}',
        );
      }
    }

    archive['sheets'] = sheetsArchive;
    if (changed > 0) {
      archive['updatedAt'] = DateTime.now().toIso8601String();
    }
    return changed;
  }

  Map<String, dynamic>? _decodeSaveDataForDiaryArchive(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return Map<String, dynamic>.from(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> _buildDiaryArchiveFromRecentSaves(
    SharedPreferences prefs, {
    Map<String, dynamic>? currentData,
    String? currentRaw,
  }) async {
    final archive = _decodeDiaryArchive(
      await _readSaveBlob(prefs, _diaryArchiveSaveKey),
    );

    for (final raw in <String?>[
      await _readSaveBlob(prefs, _backupSaveKey3),
      await _readSaveBlob(prefs, _backupSaveKey2),
      await _readSaveBlob(prefs, _backupSaveKey1),
      await _readSaveBlob(prefs, _verifiedSaveKey),
      await _readSaveBlob(prefs, _pendingSaveKey),
      currentRaw,
      await _readSaveBlob(prefs, _OculumHomePageState.saveKey),
    ]) {
      final data = _decodeSaveDataForDiaryArchive(raw);
      if (data != null) {
        _mergeDiariesFromSaveDataIntoArchive(archive, data);
      }
    }

    if (currentData != null) {
      _mergeDiariesFromSaveDataIntoArchive(archive, currentData);
    }

    await _writeSaveBlob(prefs, _diaryArchiveSaveKey, jsonEncode(archive));
    return archive;
  }

  List<String> _candidateDiaryPagesFromArchive(
    Map<String, dynamic> archive,
    Map<String, dynamic> sheet,
    int index, {
    String? campaignId,
  }) {
    final sheetsArchive = archive['sheets'] is Map
        ? archive['sheets'] as Map
        : const {};
    final candidates = <String>[];

    for (final key in _diarySheetArchiveKeys(
      sheet,
      index,
      campaignId: campaignId,
    )) {
      final pages = _archiveDiaryPages(sheetsArchive[key]);
      for (final page in pages) {
        if (!_diaryListContainsNormalized(candidates, page)) {
          candidates.add(page);
        }
      }
    }

    return candidates;
  }

  int _recoverDiaryPagesIntoSaveData(
    Map<String, dynamic> data,
    Map<String, dynamic> archive,
  ) {
    var restored = 0;

    void recoverSheetList(dynamic rawSheets, {String? campaignId}) {
      if (rawSheets is! List) return;

      for (int i = 0; i < rawSheets.length; i++) {
        final rawSheet = rawSheets[i];
        if (rawSheet is! Map) continue;
        final sheet = Map<String, dynamic>.from(rawSheet);
        final currentPages = _diaryPagesFromSheet(sheet);
        final candidatePages = _candidateDiaryPagesFromArchive(
          archive,
          sheet,
          i,
          campaignId: campaignId,
        );

        if (candidatePages.isEmpty) continue;

        final before = currentPages.length;
        final changed = _mergeDiaryPagesIntoSlotList(
          currentPages,
          candidatePages,
          recoverLostContinuations: true,
        );
        if (!changed) continue;

        sheet['diarioPagine'] = currentPages;
        rawSheets[i] = sheet;
        final added = max(0, currentPages.length - before);
        restored += added > 0 ? added : 1;
      }
    }

    recoverSheetList(data['schedePersonaggio']);

    final campaigns = data['campaigns'];
    if (campaigns is List) {
      for (int i = 0; i < campaigns.length; i++) {
        final rawCampaign = campaigns[i];
        if (rawCampaign is! Map) continue;
        final campaign = Map<String, dynamic>.from(rawCampaign);
        recoverSheetList(
          campaign['schedePersonaggio'],
          campaignId: '${campaign['id'] ?? ''}',
        );
        campaigns[i] = campaign;
      }
    }

    return restored;
  }

  Future<int> _recoverDiariesFromRecentSaves(
    SharedPreferences prefs,
    Map<String, dynamic> data,
    String currentRaw,
  ) async {
    final archive = await _buildDiaryArchiveFromRecentSaves(
      prefs,
      currentData: data,
      currentRaw: currentRaw,
    );
    final restored = _recoverDiaryPagesIntoSaveData(data, archive);

    if (restored > 0) {
      _mergeDiariesFromSaveDataIntoArchive(archive, data);
      await _writeSaveBlob(prefs, _diaryArchiveSaveKey, jsonEncode(archive));
    }

    return restored;
  }

  Future<void> _archiveDiaryForSheetBeforeRemoval(int index) async {
    if (index < 0 || index >= schedePersonaggio.length) return;

    final sheet = jsonDecode(jsonEncode(schedaJsonAt(index))) as Map;
    final safeSheet = Map<String, dynamic>.from(sheet);
    final pages = _diaryPagesFromSheet(safeSheet);
    if (pages.isEmpty || pages.every(_diaryPageLooksPlaceholder)) return;

    final prefs = await SharedPreferences.getInstance();
    await _buildDiaryArchiveFromRecentSaves(
      prefs,
      currentData: <String, dynamic>{
        'activeCampaignId': activeCampaignId,
        'schedePersonaggio': <Map<String, dynamic>>[safeSheet],
        'campaigns': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': activeCampaignId,
            'schedePersonaggio': <Map<String, dynamic>>[safeSheet],
          },
        ],
      },
    );
  }

  Future<void> _creaBackupDelSalvataggioCorrente(
    SharedPreferences prefs, {
    bool force = false,
  }) async {
    final current = await _readSaveBlob(prefs, _OculumHomePageState.saveKey);
    if (!_rawLooksLikeMeaningfulSave(current)) return;

    final backup1 = await _readSaveBlob(prefs, _backupSaveKey1);
    if (backup1 == current) return;

    final now = DateTime.now();
    final lastRotation = ultimaRotazioneBackupAt;
    if (!force &&
        lastRotation != null &&
        now.difference(lastRotation) < const Duration(seconds: 45)) {
      return;
    }

    final backup2 = await _readSaveBlob(prefs, _backupSaveKey2);
    if (backup2 != null && backup2.isNotEmpty) {
      await _writeSaveBlob(prefs, _backupSaveKey3, backup2);
    }
    if (backup1 != null && backup1.isNotEmpty) {
      await _writeSaveBlob(prefs, _backupSaveKey2, backup1);
    }
    await _writeSaveBlob(prefs, _backupSaveKey1, current!);
    ultimaRotazioneBackupAt = now;
  }

  Future<String?> _firstMeaningfulBackupRaw(
    SharedPreferences prefs, {
    String? exclude,
  }) async {
    for (final key in <String>[
      _pendingSaveKey,
      _verifiedSaveKey,
      _backupSaveKey1,
      _backupSaveKey2,
      _backupSaveKey3,
    ]) {
      final raw = await _readSaveBlob(prefs, key);
      if (raw == null || raw.isEmpty || raw == exclude) continue;
      if (_rawLooksLikeMeaningfulSave(raw)) return raw;
    }
    return null;
  }

  Future<bool> _scriviSalvataggioProtetto(
    SharedPreferences prefs,
    Map<String, dynamic> data,
  ) async {
    if (salvataggioBloccatoPerErrore) {
      debugPrint(
        'Scrittura salvataggio bloccata per proteggere i dati vecchi.',
      );
      return false;
    }

    final dataLooksMeaningful = _saveDataLooksMeaningful(data);
    final diarySignature = firmaDiarioSalvataggio(data);
    final dataRevision = readIntValue(
      data['saveRevision'],
      fallback: salvataggioRevisione,
    );
    final payload = await codificaSalvataggioPerStorage(data);
    final encoded = payload.encoded;
    final contentSignature = payload.contentSignature;
    if (contentSignature == ultimoSalvataggioContenutoFirma) {
      return false;
    }
    final previous = await _readSaveBlob(prefs, _OculumHomePageState.saveKey);

    // Se esiste un salvataggio vero e la nuova scrittura sembra una scheda vuota,
    // non lo sovrascrivo. Il reset intenzionale usa cancellaSalvataggio().
    if (_rawLooksLikeMeaningfulSave(previous) && !dataLooksMeaningful) {
      salvataggioBloccatoPerErrore = true;
      ultimoErroreCaricamentoSalvataggio =
          'Scrittura bloccata: la nuova memoria sembrava vuota e avrebbe sovrascritto un salvataggio esistente.';
      risultato = ultimoErroreCaricamentoSalvataggio;
      aggiungiLog(risultato);
      return false;
    }

    await _creaBackupDelSalvataggioCorrente(prefs);
    if (diarySignature.isNotEmpty &&
        diarySignature != ultimoArchivioDiarioFirma) {
      await _buildDiaryArchiveFromRecentSaves(
        prefs,
        currentData: data,
        currentRaw: previous,
      );
      ultimoArchivioDiarioFirma = diarySignature;
    }
    await _writeSaveBlob(prefs, _pendingSaveKey, encoded);
    final writeOk = await _writeSaveBlob(
      prefs,
      _OculumHomePageState.saveKey,
      encoded,
    );
    if (!kIsWeb) await prefs.reload();
    final verified = await _readSaveBlob(prefs, _OculumHomePageState.saveKey);
    if (!writeOk || verified != encoded) {
      salvataggioFallimentiConsecutivi++;
      ultimoErroreCaricamentoSalvataggio =
          'Scrittura salvataggio non verificata: i dati non sono stati confermati dal disco.';
      risultato = ultimoErroreCaricamentoSalvataggio;
      aggiungiLog(risultato);
      return false;
    }

    await _writeSaveBlob(prefs, _verifiedSaveKey, encoded);
    await _removeSaveBlob(prefs, _pendingSaveKey);
    salvataggioFallimentiConsecutivi = 0;
    salvataggioRevisione = dataRevision;
    ultimoSalvataggioCompletatoAt = DateTime.now();
    ultimoSalvataggioFirma = '${encoded.length}:$dataRevision';
    ultimoSalvataggioContenutoFirma = contentSignature;
    return true;
  }

  void salvaSchedaCorrenteInMemoria() {
    if (schedePersonaggio.isEmpty) {
      final next = statoCorrenteJson();
      next['localUpdatedAt'] = DateTime.now().toIso8601String();
      schedePersonaggio.add(next);
      schedaCorrente = 0;
      assicuraTagSchede();
      return;
    }

    if (schedaCorrente < 0 || schedaCorrente >= schedePersonaggio.length) {
      schedaCorrente = 0;
    }

    final previous = Map<String, dynamic>.from(
      schedePersonaggio[schedaCorrente],
    );
    final next = <String, dynamic>{...previous, ...statoCorrenteJson()};
    next['diarioPagine'] = _preserveDiaryPagesForSheetSave(next, previous);

    bool hasMeaningfulValue(dynamic value) {
      if (value == null) return false;
      if (value is String) return value.trim().isNotEmpty;
      if (value is Iterable) return value.isNotEmpty;
      if (value is Map) return value.isNotEmpty;
      return true;
    }

    void preservePreviousIfCurrentLost(String key) {
      if (!hasMeaningfulValue(previous[key])) return;
      if (hasMeaningfulValue(next[key])) return;
      next[key] = previous[key];
    }

    for (final key in <String>[
      'textAttachments',
      'titoli',
      'trattiRazziali',
      'inventario',
      'skills',
      'arti',
      'diarioPagine',
      'journalEntries',
      'draftNotes',
      'hiddenEyeStats',
      'reputations',
      'logEventi',
      'partyMembri',
      'customDamageTypes',
      'elementColorOverrides',
      'immaginePersonaggioBase64',
    ]) {
      preservePreviousIfCurrentLost(key);
    }

    final previousName = '${previous['nome'] ?? ''}'.trim();
    final nextName = '${next['nome'] ?? ''}'.trim();
    if (previousName.isNotEmpty &&
        previousName != '???' &&
        (nextName.isEmpty || nextName == '???')) {
      next['nome'] = previousName;
    }

    const realtimeKeys = <String>[
      'realtimeSharedSheet',
      'realtimeSourceKey',
      'realtimeSourceSheetTag',
      'realtimeOwnerTag',
      'realtimeOwnerName',
      'realtimeCampaignId',
      'realtimeCampaignName',
      'realtimeSharedAt',
      'realtimeReceivedAt',
      'realtimeLocalSheetTag',
      'realtimeDirtyLocal',
      'realtimeDirtyAt',
      'localUpdatedAt',
      'realtimeRestrictedByMaster',
      'realtimeReadOnlyByMaster',
      'publicTokenSide',
      'publicInitiativeBase',
      'publicInitiativeTotal',
      'publicInitiativeRollHidden',
      'realtimeCoMaster',
      'realtimeShareWithFriends',
    ];

    Map<String, dynamic> comparableSheet(Map<String, dynamic> sheet) {
      final copy = Map<String, dynamic>.from(sheet);
      for (final key in realtimeKeys) {
        copy.remove(key);
      }
      return copy;
    }

    final contentChanged =
        jsonEncode(comparableSheet(previous)) !=
        jsonEncode(comparableSheet(next));

    if (contentChanged && !applyingHistorySnapshot) {
      undoHistory.add(<String, dynamic>{
        'index': schedaCorrente,
        'sheet': jsonDecode(jsonEncode(previous)),
      });
      if (undoHistory.length > 80) {
        undoHistory.removeAt(0);
      }
      redoHistory.clear();
    }

    for (final key in realtimeKeys) {
      if (previous.containsKey(key)) {
        next[key] = previous[key];
      }
    }

    final previousLocalUpdatedAt = '${previous['localUpdatedAt'] ?? ''}'.trim();
    if (contentChanged || previousLocalUpdatedAt.isEmpty) {
      next['localUpdatedAt'] = DateTime.now().toIso8601String();
    } else {
      next['localUpdatedAt'] = previousLocalUpdatedAt;
    }

    if (readBoolValue(previous['realtimeSharedSheet']) &&
        !readBoolValue(previous['realtimeReadOnlyByMaster']) &&
        !applyingRealtimeRemoteSheet &&
        contentChanged) {
      next['realtimeDirtyLocal'] = true;
      next['realtimeDirtyAt'] = DateTime.now().toIso8601String();
    }

    schedePersonaggio[schedaCorrente] = next;
  }

  Map<String, dynamic> currentHistorySnapshot() {
    return <String, dynamic>{
      'index': schedaCorrente,
      'sheet': jsonDecode(jsonEncode(statoCorrenteJson())),
    };
  }

  void restoreHistorySnapshot(Map<String, dynamic> snapshot) {
    final index = readIntValue(snapshot['index'], fallback: schedaCorrente);
    final rawSheet = snapshot['sheet'];
    if (rawSheet is! Map) return;
    if (index < 0 || index >= schedePersonaggio.length) return;

    final sheet = Map<String, dynamic>.from(rawSheet);
    applyingHistorySnapshot = true;
    try {
      schedePersonaggio[index] = sheet;
      schedaCorrente = index;
      caricaStatoDaJson(sheet);
    } finally {
      applyingHistorySnapshot = false;
    }
  }

  void annullaUltimaModifica() {
    salvaSchedaCorrenteInMemoria();

    if (undoHistory.isEmpty) {
      setState(() {
        risultato = t('Nessuna modifica da annullare.', 'No change to undo.');
      });
      return;
    }

    final redo = currentHistorySnapshot();
    final snapshot = undoHistory.removeLast();
    setState(() {
      redoHistory.add(redo);
      restoreHistorySnapshot(snapshot);
      risultato = t('Ultima modifica annullata.', 'Last change undone.');
      aggiungiLog(risultato);
    });
    programmaSalvataggio();
  }

  void ripristinaModificaAnnullata() {
    salvaSchedaCorrenteInMemoria();

    if (redoHistory.isEmpty) {
      setState(() {
        risultato = t(
          'Nessuna modifica da ripristinare.',
          'No change to redo.',
        );
      });
      return;
    }

    final undo = currentHistorySnapshot();
    final snapshot = redoHistory.removeLast();
    setState(() {
      undoHistory.add(undo);
      restoreHistorySnapshot(snapshot);
      risultato = t('Modifica ripristinata.', 'Change redone.');
      aggiungiLog(risultato);
    });
    programmaSalvataggio();
  }

  Map<String, dynamic> datiSalvataggioJson({required int revision}) {
    return {
      ...extraTopLevelSaveFields,
      'saveVersion': 11,
      'saveRevision': revision,
      'savedAt': DateTime.now().toIso8601String(),
      'multiScheda': true,
      'schedaCorrente': schedaCorrente,
      'schedePersonaggio': schedePersonaggio,
      'activeCampaignId': activeCampaignId,
      'campaigns': campagneOculum,
      'oculumFriends': amiciOculum,
      'oculumFriendRequests': pendingOculumFriendRequests,
      'oculumSentFriendRequests': sentOculumFriendRequests,
      'blockedOculumFriends': blockedOculumFriends,
      'oculumUsername': oculumUsernameController.text,
      'masterKickRequiresConfirmation': masterKickRequiresConfirmation,
      'masterEnemyFullSheetVisibility': masterEnemyFullSheetVisibility,
      'masterPublicDiceVisible': masterPublicDiceVisible,
      'masterAskPublicDiceConfirmation': masterAskPublicDiceConfirmation,
    };
  }

  Future<void> forzaSalvataggioImmediato({bool soloLocale = false}) async {
    autosaveTimer?.cancel();
    if (soloLocale) {
      await salvaDatiSoloLocale();
    } else {
      await salvaDati();
    }
  }

  Future<void> _salvaDatiSerializzato({required bool soloLocale}) async {
    if (!datiCaricati) return;

    final running = activeSaveFuture;
    if (running != null) {
      salvataggioRichiestoDuranteScrittura = true;
      if (!soloLocale) {
        salvataggioCompletoRichiestoDuranteScrittura = true;
      }
      await running;
      return;
    }

    final save = _eseguiCodaSalvataggio(soloLocale: soloLocale);
    activeSaveFuture = save;
    await save;
  }

  Future<void> _eseguiCodaSalvataggio({required bool soloLocale}) async {
    salvataggioInCorso = true;
    var prossimaScritturaSoloLocale = soloLocale;
    try {
      while (true) {
        salvataggioRichiestoDuranteScrittura = false;
        salvataggioCompletoRichiestoDuranteScrittura = false;
        await _salvaDatiCore(soloLocale: prossimaScritturaSoloLocale);
        if (!salvataggioRichiestoDuranteScrittura) break;
        prossimaScritturaSoloLocale =
            !salvataggioCompletoRichiestoDuranteScrittura;
      }
    } finally {
      salvataggioInCorso = false;
      salvataggioRichiestoDuranteScrittura = false;
      salvataggioCompletoRichiestoDuranteScrittura = false;
      activeSaveFuture = null;
    }
  }

  Future<void> _salvaDatiCore({required bool soloLocale}) async {
    if (!datiCaricati) return;

    if (!salvataggioInChiusura) {
      salvaSchedaCorrenteInMemoria();
      if (!soloLocale) {
        await sendRealtimeEditedSharedSheetBack();
      }
      saveActiveCampaignInMemory();
    }

    final prefs = await SharedPreferences.getInstance();
    final revision = salvataggioRevisione + 1;
    final saved = await _scriviSalvataggioProtetto(
      prefs,
      datiSalvataggioJson(revision: revision),
    );
    if (!saved || soloLocale) return;

    // Sincronizza la scheda in rete P2P
    p2pSyncOnSave();
    sendRealtimeCurrentPartySheet();
    sendRealtimeCurrentSheetToFriendsIfEnabled();
  }

  Future<void> salvaDati() => _salvaDatiSerializzato(soloLocale: false);

  Future<void> salvaDatiSoloLocale() =>
      _salvaDatiSerializzato(soloLocale: true);

  Future<bool> importaBackupCompletoProtetto(
    Map<String, dynamic> backup,
  ) async {
    if (!_saveDataLooksMeaningful(backup)) return false;
    await forzaSalvataggioImmediato(soloLocale: true);
    final prefs = await SharedPreferences.getInstance();
    await _creaBackupDelSalvataggioCorrente(prefs, force: true);
    final imported = _oculumVttDeepMap(backup)
      ..remove('oculumBackup')
      ..remove('versioneBackup')
      ..remove('backupCreatedAt');
    imported['saveVersion'] = max(11, readIntValue(imported['saveVersion']));
    imported['saveRevision'] = salvataggioRevisione + 1;
    imported['savedAt'] = DateTime.now().toIso8601String();
    salvataggioBloccatoPerErrore = false;
    ultimoSalvataggioContenutoFirma = '';
    final written = await _scriviSalvataggioProtetto(prefs, imported);
    if (!written) return false;
    await caricaDati(allowBackupRecovery: true);
    return true;
  }

  Future<void> caricaDati({bool allowBackupRecovery = true}) async {
    final prefs = await SharedPreferences.getInstance();
    var raw = await _readSaveBlob(prefs, _OculumHomePageState.saveKey);

    // Se il salvataggio principale è vuoto/non significativo ma esiste un backup,
    // ripristina automaticamente il backup prima di inizializzare una scheda vuota.
    if (!_rawLooksLikeMeaningfulSave(raw)) {
      final recovery = await _firstMeaningfulBackupRaw(prefs);
      if (recovery != null) {
        raw = recovery;
        await _writeSaveBlob(prefs, _OculumHomePageState.saveKey, recovery);
        await _writeSaveBlob(prefs, _verifiedSaveKey, recovery);
      }
    }

    if (raw == null || raw.isEmpty) {
      if (!mounted) return;
      setState(() {
        extraTopLevelSaveFields.clear();
        schedePersonaggio
          ..clear()
          ..add(statoVuotoPersonaggio());

        schedaCorrente = 0;
        oculumUsernameController.clear();
        pendingOculumFriendRequests.clear();
        sentOculumFriendRequests.clear();
        blockedOculumFriends.clear();
        caricaStatoDaJson(schedePersonaggio.first);
        assicuraTagSchede();
        activeCampaignId = generateCampaignId();
        campaignNameController.text = 'Campagna principale';
        campagneOculum
          ..clear()
          ..add(currentCampaignSnapshot());
        salvataggioBloccatoPerErrore = false;
        ultimoErroreCaricamentoSalvataggio = '';
        salvataggioRevisione = 0;
        salvataggioFallimentiConsecutivi = 0;
        ultimoSalvataggioCompletatoAt = null;
        ultimoSalvataggioFirma = '';
        datiCaricati = true;
      });

      return;
    }

    try {
      final data = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      final diariRipristinati = await _recoverDiariesFromRecentSaves(
        prefs,
        data,
        raw,
      );

      if (!mounted) return;
      setState(() {
        _memorizzaCampiTopLevelSconosciuti(data);
        schedePersonaggio.clear();
        campagneOculum.clear();
        activeCampaignId = '${data['activeCampaignId'] ?? ''}';
        masterKickRequiresConfirmation = readBoolValue(
          data['masterKickRequiresConfirmation'],
          fallback: true,
        );
        masterEnemyFullSheetVisibility = readBoolValue(
          data['masterEnemyFullSheetVisibility'],
        );
        masterPublicDiceVisible = readBoolValue(
          data['masterPublicDiceVisible'],
        );
        masterAskPublicDiceConfirmation = readBoolValue(
          data['masterAskPublicDiceConfirmation'],
          fallback: true,
        );

        if (data['campaigns'] is List) {
          campagneOculum.addAll(
            ((data['campaigns'] ?? []) as List).whereType<Map>().map(
              (x) => Map<String, dynamic>.from(x),
            ),
          );
          oculumUsernameController.text = '${data['oculumUsername'] ?? ''}';
          amiciOculum
            ..clear()
            ..addAll(
              ((data['oculumFriends'] ?? []) as List).whereType<Map>().map(
                (x) => Map<String, dynamic>.from(x),
              ),
            );
          pendingOculumFriendRequests
            ..clear()
            ..addAll(
              ((data['oculumFriendRequests'] ?? []) as List)
                  .whereType<Map>()
                  .map((x) => Map<String, dynamic>.from(x)),
            );
          sentOculumFriendRequests
            ..clear()
            ..addAll(
              ((data['oculumSentFriendRequests'] ?? []) as List)
                  .whereType<Map>()
                  .map((x) => Map<String, dynamic>.from(x)),
            );
          blockedOculumFriends
            ..clear()
            ..addAll(
              ((data['blockedOculumFriends'] ?? []) as List)
                  .whereType<Map>()
                  .map((x) => Map<String, dynamic>.from(x)),
            );

          if (campagneOculum.isEmpty) {
            campagneOculum.add(campaignFromLegacyData(data));
          }

          if (activeCampaignId.isEmpty ||
              !campagneOculum.any(
                (x) => '${x['id'] ?? ''}' == activeCampaignId,
              )) {
            activeCampaignId =
                '${campagneOculum.first['id'] ?? generateCampaignId()}';
          }

          final activeCampaign = campagneOculum.firstWhere(
            (x) => '${x['id'] ?? ''}' == activeCampaignId,
            orElse: () => campagneOculum.first,
          );
          loadCampaignSnapshot(activeCampaign);
        } else if (data['multiScheda'] == true &&
            data['schedePersonaggio'] is List) {
          final campaign = campaignFromLegacyData(data);
          campagneOculum.add(campaign);
          activeCampaignId = '${campaign['id'] ?? generateCampaignId()}';
          oculumUsernameController.text = '${data['oculumUsername'] ?? ''}';
          loadCampaignSnapshot(campaign);
          amiciOculum
            ..clear()
            ..addAll(
              ((data['oculumFriends'] ?? []) as List).whereType<Map>().map(
                (x) => Map<String, dynamic>.from(x),
              ),
            );
          pendingOculumFriendRequests
            ..clear()
            ..addAll(
              ((data['oculumFriendRequests'] ?? []) as List)
                  .whereType<Map>()
                  .map((x) => Map<String, dynamic>.from(x)),
            );
          sentOculumFriendRequests
            ..clear()
            ..addAll(
              ((data['oculumSentFriendRequests'] ?? []) as List)
                  .whereType<Map>()
                  .map((x) => Map<String, dynamic>.from(x)),
            );
          blockedOculumFriends
            ..clear()
            ..addAll(
              ((data['blockedOculumFriends'] ?? []) as List)
                  .whereType<Map>()
                  .map((x) => Map<String, dynamic>.from(x)),
            );
        } else {
          final campaign = campaignFromLegacyData(data);
          campagneOculum.add(campaign);
          activeCampaignId = '${campaign['id'] ?? generateCampaignId()}';
          oculumUsernameController.text = '${data['oculumUsername'] ?? ''}';
          loadCampaignSnapshot(campaign);
          amiciOculum.clear();
          pendingOculumFriendRequests.clear();
          sentOculumFriendRequests.clear();
          blockedOculumFriends.clear();
        }

        if (schedePersonaggio.isEmpty) {
          schedePersonaggio.add(statoVuotoPersonaggio());
        }

        if (schedaCorrente < 0 || schedaCorrente >= schedePersonaggio.length) {
          schedaCorrente = 0;
        }

        caricaStatoDaJson(schedePersonaggio[schedaCorrente]);
        assicuraTagSchede();
        saveActiveCampaignInMemory();
        assicuraAmiciOculum();
        salvataggioBloccatoPerErrore = false;
        ultimoErroreCaricamentoSalvataggio = '';
        salvataggioRevisione = readIntValue(data['saveRevision']);
        salvataggioFallimentiConsecutivi = 0;
        ultimoSalvataggioCompletatoAt = DateTime.tryParse(
          '${data['savedAt'] ?? ''}',
        );
        ultimoSalvataggioFirma =
            '${raw!.length}:${data['saveRevision'] ?? salvataggioRevisione}';
        ultimoSalvataggioContenutoFirma = firmaContenutoSalvataggio(data);
        datiCaricati = true;
        if (diariRipristinati > 0) {
          risultato = t(
            'Recupero diario completato: ripristinate $diariRipristinati pagine dai salvataggi recenti.',
            'Diary recovery completed: restored $diariRipristinati pages from recent saves.',
          );
          aggiungiLog(risultato);
        }
      });

      // Il caricamento è riuscito: crea una copia di sicurezza del raw originale.
      await _creaBackupDelSalvataggioCorrente(prefs);
      if (diariRipristinati > 0) {
        await salvaDatiSoloLocale();
      }
    } catch (error, stackTrace) {
      debugPrint('Errore caricamento salvataggio Oculum: $error');
      debugPrint('$stackTrace');

      if (allowBackupRecovery) {
        final recovery = await _firstMeaningfulBackupRaw(prefs, exclude: raw);
        if (recovery != null) {
          await _writeSaveBlob(prefs, _OculumHomePageState.saveKey, recovery);
          await _writeSaveBlob(prefs, _verifiedSaveKey, recovery);
          return caricaDati(allowBackupRecovery: false);
        }
      }

      if (!mounted) return;
      setState(() {
        extraTopLevelSaveFields.clear();
        schedePersonaggio
          ..clear()
          ..add(statoVuotoPersonaggio());

        schedaCorrente = 0;
        oculumUsernameController.clear();
        pendingOculumFriendRequests.clear();
        sentOculumFriendRequests.clear();
        blockedOculumFriends.clear();
        caricaStatoDaJson(schedePersonaggio.first);
        assicuraTagSchede();
        activeCampaignId = generateCampaignId();
        campaignNameController.text = 'Campagna principale';
        campagneOculum
          ..clear()
          ..add(currentCampaignSnapshot());
        salvataggioBloccatoPerErrore = true;
        salvataggioFallimentiConsecutivi++;
        ultimoErroreCaricamentoSalvataggio =
            'Il salvataggio vecchio non è stato caricato, ma NON è stato cancellato né sovrascritto. Errore: $error';
        risultato = ultimoErroreCaricamentoSalvataggio;
        aggiungiLog(risultato);
        datiCaricati = true;
      });
    }
  }

  Future<void> cancellaSalvataggio() async {
    salvaSchedaCorrenteInMemoria();
    saveActiveCampaignInMemory();

    final prefs = await SharedPreferences.getInstance();
    await _creaBackupDelSalvataggioCorrente(prefs, force: true);

    if (!mounted) return;

    setState(() {
      final archived =
          jsonDecode(jsonEncode(currentCampaignSnapshot()))
              as Map<String, dynamic>;
      archived['id'] = generateCampaignId();
      archived['name'] =
          '${t('Archivio', 'Archive')} - ${activeCampaignName()} - ${DateTime.now().toLocal().toIso8601String().substring(0, 16)}';
      archived['archivedAt'] = DateTime.now().toIso8601String();
      campagneOculum.add(archived);

      schedePersonaggio
        ..clear()
        ..add(statoVuotoPersonaggio());
      salvataggioBloccatoPerErrore = false;
      ultimoErroreCaricamentoSalvataggio = '';

      schedaCorrente = 0;
      activeCampaignId = generateCampaignId();
      campaignNameController.text = 'Campagna principale';
      caricaStatoDaJson(schedePersonaggio.first);
      saveActiveCampaignInMemory();

      risultato = t(
        'Nessun salvataggio cancellato: la campagna precedente e stata archiviata e hai una nuova scheda vuota.',
        'No save was deleted: the previous campaign was archived and you have a new empty sheet.',
      );

      aggiungiLog(risultato);
    });

    await salvaDatiSoloLocale();
  }

  // =====================================================
  // UTILITY BASE
  // =====================================================

  int leggiNumero(TextEditingController controller) {
    return int.tryParse(controller.text.trim()) ?? 0;
  }

  double leggiDouble(TextEditingController controller) {
    return double.tryParse(controller.text.trim().replaceAll(',', '.')) ?? 0;
  }

  bool isMostro() => tipoSchedaController.text == 'Mostro';

  int clampKarmaTitolo(int valore) {
    if (valore > 0) return 1;
    if (valore < 0) return -1;
    return 0;
  }

  int leggiKarmaTitolo(TextEditingController controller) {
    return clampKarmaTitolo(int.tryParse(controller.text.trim()) ?? 0);
  }

  String nomeSchedaPersonaggio(int index) {
    if (index < 0 || index >= schedePersonaggio.length) {
      return '???';
    }

    if (index == schedaCorrente) {
      final nomeAttuale = nomeController.text.trim();
      return nomeAttuale.isEmpty ? '???' : nomeAttuale;
    }

    final nome = '${schedePersonaggio[index]['nome'] ?? '???'}'.trim();
    return nome.isEmpty ? '???' : nome;
  }

  String chiaveNomeScheda(String value) {
    return cleanUiText(
      value,
    ).trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  Set<String> nomiSchedeEsistenti({int? escluso}) {
    final names = <String>{};
    for (int i = 0; i < schedePersonaggio.length; i++) {
      if (i == escluso) continue;
      final key = chiaveNomeScheda('${schedePersonaggio[i]['nome'] ?? ''}');
      if (key.isNotEmpty) names.add(key);
    }
    return names;
  }

  String nomeSchedaImportataUnico(String rawName, Set<String> usedNames) {
    final base = cleanUiText(rawName).trim().isEmpty
        ? t('Scheda importata', 'Imported sheet')
        : cleanUiText(rawName).trim();

    var candidate = base;
    var key = chiaveNomeScheda(candidate);
    if (key.isEmpty) {
      candidate = t('Scheda importata', 'Imported sheet');
      key = chiaveNomeScheda(candidate);
    }

    if (usedNames.add(key)) return candidate;

    candidate = '$base Copy';
    key = chiaveNomeScheda(candidate);
    if (usedNames.add(key)) return candidate;

    var counter = 2;
    while (true) {
      candidate = '$base Copy $counter';
      key = chiaveNomeScheda(candidate);
      if (usedNames.add(key)) return candidate;
      counter++;
    }
  }

  List<Map<String, dynamic>> preparaSchedeImportateUniche(
    Iterable<Map<String, dynamic>> rawSheets,
  ) {
    final usedNames = nomiSchedeEsistenti();
    return rawSheets.map((sheet) {
      final copy = Map<String, dynamic>.from(sheet);
      copy['nome'] = nomeSchedaImportataUnico(
        '${copy['nome'] ?? t('Scheda importata', 'Imported sheet')}',
        usedNames,
      );
      return copy;
    }).toList();
  }

  String tipoSchedaPersonaggio(int index) {
    if (index < 0 || index >= schedePersonaggio.length) {
      return 'Personaggio';
    }

    if (index == schedaCorrente) {
      return tipoSchedaController.text;
    }

    return '${schedePersonaggio[index]['tipoScheda'] ?? 'Personaggio'}';
  }

  Map<String, dynamic> schedaJsonAt(int index) {
    if (index < 0 || index >= schedePersonaggio.length) {
      return statoVuotoPersonaggio();
    }

    if (index == schedaCorrente) {
      return statoCorrenteJson();
    }

    return schedePersonaggio[index];
  }

  bool assicuraTagSchede() {
    if (schedePersonaggio.isEmpty) return false;

    var changed = false;
    final usati = <String>{};

    for (int i = 0; i < schedePersonaggio.length; i++) {
      final scheda = schedePersonaggio[i];
      var tag = normalizeOculumFriendTag('${scheda['sheetTag'] ?? ''}');

      final nonValido = shouldReplaceSheetTag(tag, i, usati);

      if (nonValido) {
        tag = generaTagUnicoScheda(i, usati);
        scheda['sheetTag'] = tag;
        scheda['id'] = tag;
        changed = true;
      } else if ('${scheda['sheetTag'] ?? ''}' != tag) {
        scheda['sheetTag'] = tag;
        scheda['id'] = tag;
        changed = true;
      }

      if ('${scheda['id'] ?? ''}'.trim() != tag) {
        scheda['id'] = tag;
        changed = true;
      }

      usati.add(tag.toUpperCase());

      if (!scheda.containsKey('inMasterParty')) {
        scheda['inMasterParty'] = false;
        changed = true;
      }

      if (scheda['inMasterParty'] is! bool) {
        scheda['inMasterParty'] = readBoolValue(scheda['inMasterParty']);
        changed = true;
      }

      if (!scheda.containsKey('countsForPartyStats')) {
        scheda['countsForPartyStats'] = !isEnemySheetAt(i);
        changed = true;
      }

      if (scheda['countsForPartyStats'] is! bool) {
        scheda['countsForPartyStats'] = readBoolValue(
          scheda['countsForPartyStats'],
        );
        changed = true;
      }

      final sideOverride = '${scheda['masterSideOverride'] ?? ''}'.trim();
      if (sideOverride.isNotEmpty &&
          sideOverride != 'enemy' &&
          sideOverride != 'ally' &&
          sideOverride != 'neutral') {
        scheda['masterSideOverride'] = '';
        changed = true;
      }
    }

    return changed;
  }

  String sheetTagAt(int index) {
    if (index < 0 || index >= schedePersonaggio.length) return '---';

    assicuraTagSchede();
    return '${schedePersonaggio[index]['sheetTag'] ?? '---'}';
  }

  bool sheetInMasterPartyAt(int index) {
    if (index < 0 || index >= schedePersonaggio.length) return false;

    assicuraTagSchede();
    return readBoolValue(schedePersonaggio[index]['inMasterParty']);
  }

  bool sheetCountsForPartyStatsAt(int index) {
    if (index < 0 || index >= schedePersonaggio.length) return false;
    if (!sheetInMasterPartyAt(index) || isEnemySheetAt(index)) return false;
    final sheet = schedePersonaggio[index];
    if (!sheet.containsKey('countsForPartyStats')) return true;
    return readBoolValue(sheet['countsForPartyStats']);
  }

  List<int> masterPartyIndexes() {
    assicuraTagSchede();

    final indexes = <int>[];
    for (int i = 0; i < schedePersonaggio.length; i++) {
      if (sheetInMasterPartyAt(i)) indexes.add(i);
    }
    return indexes;
  }

  List<int> partyStatsCountIndexes() {
    return masterPartyIndexes()
        .where(sheetCountsForPartyStatsAt)
        .toList(growable: false);
  }

  Future<void> cambiaConteggioStatsParty(int index, bool value) async {
    if (index < 0 || index >= schedePersonaggio.length) return;
    salvaSchedaCorrenteInMemoria();
    setState(() {
      schedePersonaggio[index]['countsForPartyStats'] = value;
      risultato = value
          ? t(
              '${nomeSchedaPersonaggio(index)} conta per le stats del party.',
              '${nomeSchedaPersonaggio(index)} counts for party stats.',
            )
          : t(
              '${nomeSchedaPersonaggio(index)} non conta per le stats del party.',
              '${nomeSchedaPersonaggio(index)} does not count for party stats.',
            );
      aggiungiLog(risultato);
    });
    await salvaDati();
  }

  Uint8List? immagineSchedaAt(int index) {
    if (index < 0 || index >= schedePersonaggio.length) return null;
    if (index == schedaCorrente) return immaginePersonaggio;

    final raw =
        '${schedePersonaggio[index]['immaginePersonaggioBase64'] ?? ''}';
    if (raw.isEmpty) return null;

    return decodedBase64ImageCached(raw);
  }

  Future<void> cambiaSchedaMasterParty(int index, bool inParty) async {
    if (index < 0 || index >= schedePersonaggio.length) return;

    salvaSchedaCorrenteInMemoria();
    assicuraTagSchede();

    setState(() {
      schedePersonaggio[index]['inMasterParty'] = inParty;
      if (inParty && !isEnemySheetAt(index)) {
        schedePersonaggio[index]['countsForPartyStats'] = true;
      }
      risultato = inParty
          ? 'Scheda aggiunta al party: ${nomeSchedaPersonaggio(index)}.'
          : 'Scheda rimossa dal party: ${nomeSchedaPersonaggio(index)}.';
      aggiungiLog(risultato);
    });

    await salvaDati();
    if (inParty) {
      if (realtimeIsMasterRole) {
        sendRealtimeMasterVisibleTokenAt(index);
      } else {
        sendRealtimeSharedSheetAt(index);
      }
    }
  }

  Future<void> apriSchedaDaParty(int index) async {
    if (index < 0 || index >= schedePersonaggio.length) return;

    await cambiaSchedaPersonaggio(index);
    if (!mounted) return;

    setState(() {
      paginaCorrente = 0;
      mostraPartyScheda = true;
      _expandedFunctionSections.add('sheet_party');
    });
  }

  void aggiungiLog(String testo) {
    final now = DateTime.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final ss = now.second.toString().padLeft(2, '0');

    logEventi.insert(0, '[$hh:$mm:$ss] $testo');

    if (logEventi.length > 250) {
      logEventi.removeRange(250, logEventi.length);
    }
  }

  void pulisciLog() {
    setState(() {
      logEventi.clear();
      risultato = t('Log cancellato.', 'Log cleared.');
    });

    programmaSalvataggio();
  }

  Map<String, dynamic> catturaImpostazioniGlobali() {
    return <String, dynamic>{
      'linguaInglese': linguaInglese,
      'tutorialCompletato': tutorialCompletato,
      'modalitaDesktop': modalitaDesktop,
      'modalitaMaster': modalitaMaster,
      'coMasterCanSetCoMaster': coMasterCanSetCoMaster,
      'coMasterCanEditSheets': coMasterCanEditSheets,
      'masterKickRequiresConfirmation': masterKickRequiresConfirmation,
      'masterEnemyFullSheetVisibility': masterEnemyFullSheetVisibility,
      'masterPublicDiceVisible': masterPublicDiceVisible,
      'masterAskPublicDiceConfirmation': masterAskPublicDiceConfirmation,
      'relayAutoReconnect': relayAutoReconnect,
      'relayServerUrl': relayServerController.text,
      'relayRoomCode': relayRoomController.text,
      'realtimeRoom': realtimeRoomController.text,
      'realtimeName': realtimeNameController.text,
      'mapMode': mapMode,
      'mapImagePath': mapImagePath,
      'mapImageName': mapImageName,
      'mapUrl': mapUrlController.text,
      'mapNotes': mapNotesController.text,
      'mapSaveSession': mapSaveSession,
      'mapSessionChoiceAsked': mapSessionChoiceAsked,
      'mapPlayersCanManageOwnToken': mapPlayersCanManageOwnToken,
      'mapTokenSize': mapTokenSizeController.text,
      'mapWidthMeters': mapWidthMetersController.text,
      'mapHeightMeters': mapHeightMetersController.text,
      'mapFreeTokenMovement': mapFreeTokenMovementController.text,
      'mapTokenSheetIndex': mapTokenSheetIndex,
      'localMapTokens': localMapTokens
          .map((token) => Map<String, dynamic>.from(token))
          .toList(),
      'vttState': captureVttStateJson(),
      'diceAmount': diceAmountController.text,
      'diceModifier': diceModifierController.text,
      'unlockedColorThemeIds': unlockedColorThemeIds.toList()..sort(),
    };
  }

  void ripristinaImpostazioniGlobali(Map<String, dynamic> globali) {
    linguaInglese = readBoolValue(globali['linguaInglese']);
    tutorialCompletato = readBoolValue(globali['tutorialCompletato']);
    modalitaDesktop = readBoolValue(globali['modalitaDesktop']);
    modalitaMaster = readBoolValue(globali['modalitaMaster']);
    coMasterCanSetCoMaster = readBoolValue(globali['coMasterCanSetCoMaster']);
    coMasterCanEditSheets = readBoolValue(globali['coMasterCanEditSheets']);
    masterKickRequiresConfirmation = readBoolValue(
      globali['masterKickRequiresConfirmation'],
      fallback: true,
    );
    masterEnemyFullSheetVisibility = readBoolValue(
      globali['masterEnemyFullSheetVisibility'],
    );
    masterPublicDiceVisible = readBoolValue(globali['masterPublicDiceVisible']);
    masterAskPublicDiceConfirmation = readBoolValue(
      globali['masterAskPublicDiceConfirmation'],
      fallback: true,
    );
    relayAutoReconnect = readBoolValue(
      globali['relayAutoReconnect'],
      fallback: true,
    );
    relayServerController.text = '${globali['relayServerUrl'] ?? ''}';
    relayRoomController.text = '${globali['relayRoomCode'] ?? ''}';
    relayRoomCode = relayRoomController.text.trim().toUpperCase();
    realtimeRoomController.text =
        '${globali['realtimeRoom'] ?? realtimeRoomController.text}';
    realtimeNameController.text =
        '${globali['realtimeName'] ?? realtimeNameController.text}';
    mapMode = '${globali['mapMode'] ?? mapMode}' == 'online'
        ? 'online'
        : 'image';
    mapImagePath = '${globali['mapImagePath'] ?? ''}';
    mapImageName = '${globali['mapImageName'] ?? ''}';
    mapUrlController.text = '${globali['mapUrl'] ?? mapUrlController.text}';
    mapNotesController.text =
        '${globali['mapNotes'] ?? mapNotesController.text}';
    mapSaveSession = readBoolValue(globali['mapSaveSession']);
    mapSessionChoiceAsked = readBoolValue(globali['mapSessionChoiceAsked']);
    mapPlayersCanManageOwnToken = readBoolValue(
      globali['mapPlayersCanManageOwnToken'],
      fallback: true,
    );
    mapTokenSizeController.text =
        '${globali['mapTokenSize'] ?? mapTokenSizeController.text}';
    mapWidthMetersController.text =
        '${globali['mapWidthMeters'] ?? mapWidthMetersController.text}';
    mapHeightMetersController.text =
        '${globali['mapHeightMeters'] ?? mapHeightMetersController.text}';
    mapFreeTokenMovementController.text =
        '${globali['mapFreeTokenMovement'] ?? mapFreeTokenMovementController.text}';
    mapTokenSheetIndex = readIntValue(globali['mapTokenSheetIndex']);
    final savedMapTokens = globali['localMapTokens'];
    localMapTokens
      ..clear()
      ..addAll(
        (savedMapTokens is List ? savedMapTokens : const [])
            .whereType<Map>()
            .map((token) => Map<String, dynamic>.from(token)),
      );
    restoreVttStateFromJson(globali['vttState'], legacy: globali);
    diceAmountController.text =
        '${globali['diceAmount'] ?? diceAmountController.text}';
    diceModifierController.text =
        '${globali['diceModifier'] ?? diceModifierController.text}';
    final unlockedThemesRaw = globali['unlockedColorThemeIds'];
    unlockedColorThemeIds
      ..clear()
      ..add('classic_reliquary')
      ..addAll(
        (unlockedThemesRaw is List ? unlockedThemesRaw : const [])
            .map((id) => '$id')
            .where((id) => colorPresets.any((preset) => preset.id == id)),
      );
  }

  // =====================================================
  // SCHEDE MULTIPLE
  // =====================================================

  Future<void> creaNuovaSchedaPersonaggio({
    String nome = '???',
    String tipo = 'Personaggio',
    int livello = 0,
    int grado = 0,
    bool aggiungiAlMasterParty = false,
  }) async {
    salvaSchedaCorrenteInMemoria();
    final globali = catturaImpostazioniGlobali();

    setState(() {
      final nuovaScheda = statoVuotoPersonaggio(
        nome: nome,
        tipo: tipo,
        livello: livello,
        grado: grado,
      );
      nuovaScheda['inMasterParty'] = aggiungiAlMasterParty;

      schedePersonaggio.add(nuovaScheda);
      assicuraTagSchede();

      schedaCorrente = schedePersonaggio.length - 1;
      caricaStatoDaJson(schedePersonaggio[schedaCorrente]);
      ripristinaImpostazioniGlobali(globali);

      if (isMostro()) {
        currentHpController.text = maxHp().toString();
      }

      aggiornaGradoAutomatico();

      risultato = t(
        'Nuova scheda creata: $nome ($tipo).',
        'New sheet created: $nome ($tipo).',
      );

      aggiungiLog('Nuova scheda creata: $nome ($tipo).');
    });

    await salvaDati();
  }

  Future<void> mostraMenuSchedaPersonaggio({
    required int index,
    required Offset position,
  }) async {
    if (index < 0 || index >= schedePersonaggio.length) return;

    final choice = await showMenu<String>(
      context: context,
      color: const Color(0xFF10121A),
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: [
        PopupMenuItem<String>(
          value: 'copy',
          child: Row(
            children: [
              Icon(Icons.copy, color: primaryColor, size: 18),
              const SizedBox(width: 10),
              Text(t('Copia', 'Copy')),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'rename',
          child: Row(
            children: [
              Icon(Icons.edit, color: primaryColor, size: 18),
              const SizedBox(width: 10),
              Text(t('Rinomina', 'Rename')),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'send_full_realtime',
          enabled: realtimeService?.isConnected == true,
          child: Row(
            children: [
              Icon(
                Icons.send_to_mobile,
                color: realtimeService?.isConnected == true
                    ? primaryColor
                    : Colors.grey,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  t(
                    'Invia scheda completa realtime',
                    'Send full realtime sheet',
                  ),
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          enabled: schedePersonaggio.length > 1,
          child: Row(
            children: [
              Icon(
                Icons.delete_outline,
                color: schedePersonaggio.length > 1
                    ? tertiaryColor
                    : Colors.grey,
                size: 18,
              ),
              const SizedBox(width: 10),
              Text(t('Elimina', 'Delete')),
            ],
          ),
        ),
      ],
    );

    if (!mounted || choice == null) return;

    if (choice == 'copy') {
      await duplicaSchedaPersonaggio(index);
    } else if (choice == 'rename') {
      await rinominaSchedaPersonaggio(index);
    } else if (choice == 'send_full_realtime') {
      sendRealtimeFullSheetToFriendsAndPartyAt(index);
    } else if (choice == 'delete') {
      await eliminaSchedaPersonaggio(index);
    }
  }

  Future<void> rinominaSchedaPersonaggio(int index) async {
    if (index < 0 || index >= schedePersonaggio.length) return;

    salvaSchedaCorrenteInMemoria();

    final controller = TextEditingController(
      text: nomeSchedaPersonaggio(index),
    );
    final nuovoNome = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF10121A),
          title: Text(
            t('Rinomina scheda', 'Rename sheet'),
            style: TextStyle(color: primaryColor),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: t('Nome', 'Name'),
              labelStyle: TextStyle(color: primaryColor),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: primaryColor.withValues(alpha: 0.45),
                ),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: tertiaryColor),
              ),
            ),
            onSubmitted: (value) => Navigator.pop(context, value.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t('Annulla', 'Cancel')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: Text(t('Salva', 'Save')),
            ),
          ],
        );
      },
    );
    controller.dispose();

    final clean = cleanUiText(nuovoNome ?? '').trim();
    if (clean.isEmpty) return;

    setState(() {
      schedePersonaggio[index]['nome'] = clean;
      if (index == schedaCorrente) {
        nomeController.text = clean;
      }
      risultato = t('Scheda rinominata: $clean.', 'Sheet renamed: $clean.');
      aggiungiLog(risultato);
    });

    await salvaDati();
  }

  Future<void> duplicaSchedaCorrente() async {
    await duplicaSchedaPersonaggio(schedaCorrente);
  }

  Future<void> duplicaSchedaPersonaggio(int index) async {
    if (index < 0 || index >= schedePersonaggio.length) {
      return;
    }

    salvaSchedaCorrenteInMemoria();
    final globali = catturaImpostazioniGlobali();
    final sourceName = nomeSchedaPersonaggio(index);
    final copy =
        jsonDecode(jsonEncode(schedePersonaggio[index]))
            as Map<String, dynamic>;

    for (final key in const <String>[
      'id',
      'sheetTag',
      'realtimeSharedSheet',
      'realtimeSourceKey',
      'realtimeSourceSheetTag',
      'realtimeOwnerTag',
      'realtimeOwnerName',
      'realtimeCampaignId',
      'realtimeCampaignName',
      'realtimeSharedAt',
      'realtimeReceivedAt',
      'realtimeLocalSheetTag',
      'realtimeDirtyLocal',
      'realtimeDirtyAt',
      'localUpdatedAt',
      'realtimeRestrictedByMaster',
      'realtimeReadOnlyByMaster',
      'publicTokenSide',
      'publicInitiativeBase',
      'publicInitiativeTotal',
      'publicInitiativeRollHidden',
      'realtimeCoMaster',
      'realtimeShareWithFriends',
    ]) {
      copy.remove(key);
    }

    copy['nome'] = t('Copia di $sourceName', 'Copy of $sourceName');
    copy['inMasterParty'] = false;
    copy['masterSideOverride'] = '';

    setState(() {
      schedePersonaggio.add(copy);
      assicuraTagSchede();
      schedaCorrente = schedePersonaggio.length - 1;
      caricaStatoDaJson(schedePersonaggio[schedaCorrente]);
      ripristinaImpostazioniGlobali(globali);
      risultato = t(
        'Scheda duplicata: ${nomeSchedaPersonaggio(schedaCorrente)}.',
        'Sheet duplicated: ${nomeSchedaPersonaggio(schedaCorrente)}.',
      );
      aggiungiLog(risultato);
    });

    await salvaDati();
  }

  Future<void> cambiaSchedaPersonaggio(int index) async {
    if (index < 0 || index >= schedePersonaggio.length) return;
    if (index == schedaCorrente) return;

    salvaSchedaCorrenteInMemoria();
    final globali = catturaImpostazioniGlobali();

    setState(() {
      schedaCorrente = index;
      caricaStatoDaJson(schedePersonaggio[schedaCorrente]);
      ripristinaImpostazioniGlobali(globali);

      risultato = t(
        'Scheda caricata: ${nomeSchedaPersonaggio(index)}',
        'Sheet loaded: ${nomeSchedaPersonaggio(index)}',
      );

      aggiungiLog('Scheda caricata: ${nomeSchedaPersonaggio(index)}.');
    });

    await salvaDati();
  }

  Future<void> eliminaSchedaCorrente() async {
    await eliminaSchedaPersonaggio(schedaCorrente);
  }

  Future<void> eliminaSchedaPersonaggio(int index) async {
    if (index < 0 || index >= schedePersonaggio.length) return;

    if (schedePersonaggio.length <= 1) {
      setState(() {
        risultato = t(
          'Non puoi eliminare l’unica scheda rimasta.',
          'You cannot delete the only remaining sheet.',
        );
      });

      return;
    }

    salvaSchedaCorrenteInMemoria();
    await _archiveDiaryForSheetBeforeRemoval(index);

    final nomeEliminato = nomeSchedaPersonaggio(index);
    final globali = catturaImpostazioniGlobali();

    setState(() {
      schedePersonaggio.removeAt(index);

      if (schedaCorrente >= schedePersonaggio.length) {
        schedaCorrente = schedePersonaggio.length - 1;
      } else if (index < schedaCorrente) {
        schedaCorrente -= 1;
      }

      caricaStatoDaJson(schedePersonaggio[schedaCorrente]);
      ripristinaImpostazioniGlobali(globali);

      risultato = t(
        'Scheda eliminata: $nomeEliminato',
        'Sheet deleted: $nomeEliminato',
      );

      aggiungiLog('Scheda eliminata: $nomeEliminato.');
    });

    await salvaDati();
  }

  Map<String, int> balancedQuickSheetStats(
    String tipo, {
    bool forceEnemyProfile = false,
    int level = 0,
    int grade = 0,
    String description = '',
  }) {
    final party = partyStatsCountIndexes();
    final source = party.isEmpty ? <int>[schedaCorrente] : party;
    final countedMembers = max(1, party.length).toInt();
    const keys = ['resilienza', 'volonta', 'materia', 'oculum'];
    final rng = Random();
    final rareRoll = rng.nextInt(100);
    final mode = rareRoll < 8
        ? 'strongest'
        : rareRoll >= 92
        ? 'weakest'
        : 'average';
    final diff = normalizedCampaignDifficulty();
    var multiplier = switch (diff) {
      'oculum' => 1.35,
      'difficile' => 1.22,
      'facile' => 0.90,
      _ => 1.12,
    };
    final lowerType = tipo.toLowerCase();
    if (lowerType.contains('alleato') && !forceEnemyProfile) {
      multiplier = min(multiplier, 0.98);
    } else if (lowerType.contains('boss')) {
      multiplier += lowerType.contains('mini') ? 0.18 : 0.32;
    } else if (forceEnemyProfile ||
        lowerType.contains('mostro') ||
        lowerType.contains('npc')) {
      multiplier += 0.10;
    }

    final result = <String, int>{};
    for (final key in keys) {
      final values = [
        for (final index in source) max(0, sheetIntValueAt(index, key)),
      ];
      final base = switch (mode) {
        'strongest' => values.reduce((a, b) => max(a, b)),
        'weakest' => values.reduce((a, b) => min(a, b)),
        _ => (values.reduce((a, b) => a + b) / values.length).round(),
      };
      result[key] = max(0, (base * multiplier).round());
    }
    if (forceEnemyProfile || isEnemyTypeName(tipo)) {
      List<int> partyValues(String key, int fallback) {
        final values = [
          for (final index in source) max(0, sheetIntValueAt(index, key)),
        ].where((value) => value > 0).toList();
        if (values.isEmpty) values.add(max(1, fallback));
        return values;
      }

      int average(List<int> values) =>
          max(1, (values.reduce((a, b) => a + b) / values.length).round());

      int rollBetween(int low, int high) {
        final a = max(1, low);
        final b = max(a, high);
        return a + rng.nextInt(b - a + 1);
      }

      final resValues = partyValues(
        'resilienza',
        leggiNumero(resilienzaController),
      );
      final volValues = partyValues('volonta', leggiNumero(volontaController));
      final matValues = partyValues('materia', leggiNumero(materiaController));
      final ocuValues = partyValues('oculum', leggiNumero(oculumController));

      final partyResilienza = average(resValues);
      final partyOculum = average(ocuValues);
      final volMin = volValues.reduce((a, b) => min(a, b));
      final volMax = volValues.reduce((a, b) => max(a, b));
      final volAvg = average(volValues);
      final volSpread = max(0, volMax - volMin);
      final matMin = matValues.reduce((a, b) => min(a, b));
      final matMax = matValues.reduce((a, b) => max(a, b));
      final matAvg = average(matValues);
      final matSpread = max(0, matMax - matMin);

      final participantLow = countedMembers;
      final participantHigh = countedMembers * 5;
      final resRoll = rollBetween(
        partyResilienza + participantLow,
        partyResilienza + participantHigh,
      );
      final ocuRoll = rollBetween(
        partyOculum + participantLow,
        partyOculum + participantHigh,
      );
      final volRoll = rollBetween(
        volSpread == 0 ? volAvg - 3 : volMin - 2,
        volSpread == 0 ? volAvg + 5 : volMax + max(3, volSpread ~/ 2),
      );
      final matRoll = rollBetween(
        matSpread >= 5 ? matAvg : matAvg - 4,
        matSpread >= 5 ? matMax : matAvg + 5,
      );

      final difficultyMultiplier = switch (diff) {
        'oculum' => 1.24,
        'difficile' => 1.13,
        'facile' => 0.90,
        _ => 1.0,
      };
      final bossBonus = lowerType.contains('boss')
          ? (lowerType.contains('mini') ? 2 + grade * 2 : 5 + grade * 4)
          : 0;
      final levelBonus = max(0, level - 2) ~/ 2 + max(0, grade) * 2;

      int tuneEnemyStat(int value, {bool bossFavored = false}) {
        final tuned =
            (value * difficultyMultiplier).round() +
            levelBonus +
            (bossFavored ? bossBonus : bossBonus ~/ 2);
        return max(1, tuned);
      }

      result['resilienza'] = tuneEnemyStat(resRoll, bossFavored: true);
      result['volonta'] = tuneEnemyStat(volRoll);
      result['materia'] = tuneEnemyStat(matRoll);
      result['oculum'] = tuneEnemyStat(ocuRoll, bossFavored: true);
      final normalizedDescription = oculumNormalizeText(description);
      if (normalizedDescription.contains('patalpa')) {
        result['resilienza'] = max(result['resilienza'] ?? 0, 15);
        result['volonta'] = max(result['volonta'] ?? 0, 3);
        result['materia'] = max(result['materia'] ?? 0, 15);
        result['oculum'] = max(result['oculum'] ?? 0, 10);
      }
      if (isFolliaGhostText(normalizedDescription)) {
        result['resilienza'] = ((result['resilienza'] ?? 0) * 1.22).round();
        result['volonta'] = ((result['volonta'] ?? 0) * 1.20).round();
        result['materia'] = max(1, ((result['materia'] ?? 0) * 1.12).round());
        result['oculum'] = ((result['oculum'] ?? 0) * 1.28).round();
        if (normalizedDescription.contains('tre donne')) {
          result['resilienza'] = ((result['resilienza'] ?? 0) * 1.35).round();
          result['materia'] = ((result['materia'] ?? 0) * 1.18).round();
        }
      }
    }
    result['countedMembers'] = countedMembers;
    result['participantExtra'] = forceEnemyProfile || isEnemyTypeName(tipo)
        ? countedMembers
        : 0;
    result['profile'] = mode == 'strongest'
        ? 2
        : mode == 'weakest'
        ? -1
        : 0;
    return result;
  }

  bool isEnemyTypeName(String tipo) {
    final lower = tipo.toLowerCase();
    return lower.contains('mostro') ||
        lower.contains('boss') ||
        lower.contains('nemic');
  }

  int quickPartyAverageValue(String key, {int fallback = 0}) {
    final party = partyStatsCountIndexes();
    final source = party.isEmpty ? <int>[schedaCorrente] : party;
    if (source.isEmpty) return fallback;
    final total = source.fold<int>(
      0,
      (sum, index) => sum + max(0, sheetIntValueAt(index, key)),
    );
    return max(0, (total / source.length).round());
  }

  int suggestedQuickSheetLevel(bool enemyProfile) {
    final written = max(0, leggiNumero(quickSheetLevelController));
    if (written > 0) return written;
    final base = quickPartyAverageValue(
      'livello',
      fallback: leggiNumero(livelloController),
    );
    final diffBonus = switch (normalizedCampaignDifficulty()) {
      'oculum' => 5,
      'difficile' => 3,
      'facile' => 1,
      _ => 2,
    };
    return max(1, base + diffBonus + (enemyProfile ? 1 : 0));
  }

  int suggestedQuickSheetGrade(String tipo) {
    final written = max(0, leggiNumero(quickSheetGradeController));
    if (written > 0) return written;
    final base = quickPartyAverageValue(
      'grado',
      fallback: leggiNumero(gradoController),
    );
    if (tipo.toLowerCase().contains('boss') &&
        !tipo.toLowerCase().contains('mini')) {
      return max(base, base + 1);
    }
    return base;
  }

  List<
    ({
      String id,
      String label,
      String name,
      String type,
      String side,
      String description,
      String artMode,
      bool enemy,
    })
  >
  folliaGeneratorPresets() => const [
    (
      id: 'infant_worm_head',
      label: 'Testa errata',
      name: 'Testa di infante errata',
      type: 'Mostro Mini Boss',
      side: 'enemy',
      artMode: 'illness',
      enemy: true,
      description:
          'Mostro fantasma errato da Follia: testa di infante ripiena di vermi. Fluttua trasparente guardando il vuoto con occhi completamente bianco latte. I vermi la mangiano, ma la carne trasparente si rigenera sempre. Ha Pensiero pesante, Apertura Mentale e infezione entro 9 ore se la Open skill riesce.',
    ),
    (
      id: 'three_women',
      label: 'Le Tre Donne',
      name: 'Le Tre Donne',
      type: 'Mostro Boss',
      side: 'enemy',
      artMode: 'illness',
      enemy: true,
      description:
          'Mostro fantasma errato da Follia: due donne attaccate da una terza, due braccia, due gambe e tre teste, una al centro del petto e due sui colli a destra e sinistra. Riflette la luce nella sua trasparenza. Tank con tre vite: modifica il suolo con spuntoni, buchi e muro difensivo.',
    ),
    (
      id: 'coro_facce_spezzate',
      label: 'Coro Facce',
      name: 'Coro delle Facce Spezzate',
      type: 'Mostro',
      side: 'enemy',
      artMode: 'illness',
      enemy: true,
      description:
          'Mostro Follia fantasma: maschere incrinate fuse in un coro nero. Urlo della Memoria stunna, Eco Follia aumenta la follia presa, Frantuma Volonta crea Vero Svantaggio.',
    ),
    (
      id: 'utero_di_specchio',
      label: 'Utero Specchio',
      name: 'Utero di Specchio',
      type: 'Mostro Mini Boss',
      side: 'enemy',
      artMode: 'illness',
      enemy: true,
      description:
          'Mini Boss Follia: guscio riflettente con occhi interni. Copia paure, riflette skill con critico e chiude il bersaglio in immagini false.',
    ),
    (
      id: 'giullare_ossa_filo',
      label: 'Giullare Filo',
      name: 'Giullare Ossa-Filo',
      type: 'Mostro',
      side: 'enemy',
      artMode: 'illness',
      enemy: true,
      description:
          'Mostro Follia veloce: burattino d ossa appeso a fili neri. La risata stunna, i fili tagliano reazioni e lo scatto appeso da vantaggio.',
    ),
    (
      id: 'santo_vene_candela',
      label: 'Santo Candela',
      name: 'Santo delle Vene di Candela',
      type: 'Mostro Boss',
      side: 'enemy',
      artMode: 'illness',
      enemy: true,
      description:
          'Boss Follia: santo di cera, aghi e vene accese. Brucia certezze, rigenera il proprio orrore e marchia il Fato.',
    ),
  ];

  bool isFolliaGhostText(String raw) {
    final text = oculumNormalizeText(raw);
    return text.contains('follia') ||
        text.contains('illness') ||
        text.contains('errat') ||
        text.contains('incubo') ||
        text.contains('trasparent') ||
        text.contains('infante') ||
        text.contains('vermi') ||
        text.contains('tre donne') ||
        text.contains('facce spezzate') ||
        text.contains('utero di specchio') ||
        text.contains('ossa-filo') ||
        text.contains('vene di candela');
  }

  ({String description, String name, String type, String artMode})?
  folliaPresetById(String id) {
    for (final preset in folliaGeneratorPresets()) {
      if (preset.id == id) {
        return (
          description: preset.description,
          name: preset.name,
          type: preset.type,
          artMode: preset.artMode,
        );
      }
    }
    return null;
  }

  Future<void> creaSchedaRapidaFollia(String presetId) async {
    final preset = folliaPresetById(presetId);
    if (preset == null) return;

    if (!folliaGeneratoreSbloccato()) {
      setState(() {
        risultato = t(
          'Generatore Follia bloccato: serve almeno 1 Follia nel party.',
          'Madness generator locked: the party needs at least 1 Madness.',
        );
        aggiungiLog(risultato);
      });
      return;
    }

    quickSheetNameController.text = preset.name;
    quickSheetDescriptionController.text = preset.description;
    quickSheetCountController.text = '1';
    quickSheetArtMode = preset.artMode;
    await creaSchedaRapidaMaster(
      forcedType: preset.type,
      fallbackName: preset.name,
      sideOverride: 'enemy',
      forceEnemyProfile: true,
    );
  }

  void restoreMonsterBookCustomization(Map<String, dynamic> json) {
    final hasCustom = json.containsKey('monsterBookCustomEntries');
    final hasRemoved = json.containsKey('monsterBookRemovedIds');
    if (!hasCustom && !hasRemoved) return;

    final restoredEntries = <MonsterBookEntry>[];
    final entriesRaw = json['monsterBookCustomEntries'];
    if (entriesRaw is List) {
      for (final raw in entriesRaw.whereType<Map>()) {
        try {
          final entry = MonsterBookEntry.fromJson(
            Map<String, dynamic>.from(raw),
          );
          if (entry.id.isNotEmpty && entry.nameIt.isNotEmpty) {
            restoredEntries.add(entry);
          }
        } catch (error) {
          debugPrint('Monster Book entry ignored: $error');
        }
      }
    }

    final restoredRemoved = <String>{};
    final removedRaw = json['monsterBookRemovedIds'];
    if (removedRaw is List) {
      restoredRemoved.addAll(
        removedRaw
            .map((value) => '$value'.trim())
            .where((value) => value.isNotEmpty),
      );
    }

    monsterBookCustomEntries
      ..clear()
      ..addAll(restoredEntries);
    monsterBookRemovedIds
      ..clear()
      ..addAll(restoredRemoved);
    configureMonsterBookEntries(
      customEntries: monsterBookCustomEntries,
      removedIds: monsterBookRemovedIds,
    );
  }

  void syncMonsterBookCustomizationToSheets() {
    configureMonsterBookEntries(
      customEntries: monsterBookCustomEntries,
      removedIds: monsterBookRemovedIds,
    );
    final entriesJson = monsterBookCustomEntries
        .map((entry) => entry.toJson())
        .toList(growable: false);
    final removedJson = monsterBookRemovedIds.toList()..sort();
    for (final sheet in schedePersonaggio) {
      sheet['monsterBookCustomEntries'] = jsonDecode(jsonEncode(entriesJson));
      sheet['monsterBookRemovedIds'] = List<String>.from(removedJson);
    }
  }

  String newMonsterBookEntryId(String name) {
    final base = oculumNormalizeText(
      name,
    ).replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'^_+|_+$'), '');
    final prefix = base.isEmpty ? 'custom_entry' : base;
    var id = prefix;
    var suffix = 2;
    final used = <String>{
      for (final entry in defaultMonsterBookEntries) entry.id,
      for (final entry in monsterBookCustomEntries) entry.id,
    };
    while (used.contains(id)) {
      id = '${prefix}_$suffix';
      suffix++;
    }
    return id;
  }

  Future<void> upsertMonsterBookEntry(MonsterBookEntry entry) async {
    final index = monsterBookCustomEntries.indexWhere(
      (existing) => existing.id == entry.id,
    );
    setState(() {
      if (index >= 0) {
        monsterBookCustomEntries[index] = entry;
      } else {
        monsterBookCustomEntries.add(entry);
      }
      monsterBookRemovedIds.remove(entry.id);
      syncMonsterBookCustomizationToSheets();
      risultato = t(
        'Preset Monster Book salvato: ${entry.nameIt}.',
        'Monster Book preset saved: ${entry.nameEn}.',
      );
      aggiungiLog(risultato);
    });
    await salvaDati();
    if (realtimeIsMasterRole) {
      sendRealtimeMasterVisiblePartyTokens();
    }
  }

  Future<void> removeMonsterBookEntry(MonsterBookEntry entry) async {
    setState(() {
      monsterBookCustomEntries.removeWhere((custom) => custom.id == entry.id);
      monsterBookRemovedIds.add(entry.id);
      syncMonsterBookCustomizationToSheets();
      risultato = t(
        'Preset rimosso dal Monster Book: ${entry.nameIt}.',
        'Preset removed from the Monster Book: ${entry.nameEn}.',
      );
      aggiungiLog(risultato);
    });
    await salvaDati();
  }

  Future<void> resetMonsterBookCustomization() async {
    setState(() {
      monsterBookCustomEntries.clear();
      monsterBookRemovedIds.clear();
      syncMonsterBookCustomizationToSheets();
      risultato = t(
        'Monster Book ripristinato ai preset originali.',
        'Monster Book restored to the original presets.',
      );
      aggiungiLog(risultato);
    });
    await salvaDati();
  }

  List<
    ({
      String id,
      String label,
      String name,
      String type,
      String side,
      String description,
      String artMode,
      bool enemy,
    })
  >
  systemMonsterGeneratorPresets() => [
    for (final monster in monsterBookEntries)
      (
        id: monster.id,
        label: systemMonsterPresetLabel(monster.nameIt),
        name: monster.nameIt,
        type: monster.presetType,
        side: monster.isNpc ? 'ally' : 'enemy',
        artMode: systemMonsterPresetArtMode(monster),
        enemy: !monster.isNpc,
        description: systemMonsterGeneratorDescription(monster),
      ),
  ];

  String systemMonsterGeneratorDescription(MonsterBookEntry monster) {
    final variants = monsterSpriteAssetPaths(monster).length;
    final weaponLine = monster.canWieldWeapons
        ? 'Armi: puo impugnare ${monster.weaponTags.join(', ')}. Armature: ${monster.armorTags.isEmpty ? 'nessuna preferenza' : monster.armorTags.join(', ')}.'
        : 'Armi: non impugna armi, usa corpo, forma o poteri naturali.';
    return [
      'Descrizione del mostro: ${monster.descIt}',
      'Elemento: ${elementDisplayName(monster.elementId)}.',
      weaponLine,
      'Abilita: ${monster.skillIds.map(systemMonsterReadableId).join(', ')}.',
      'Drop: ${monster.dropIds.map(systemMonsterReadableId).join(', ')}.',
      'Token: sprite pre-caricato con $variants ${variants == 1 ? 'forma' : 'forme'} possibile${variants == 1 ? '' : 'i'}. Stats, skill, drop, HP e note restano modificabili dopo la creazione.',
    ].join('\n');
  }

  String systemMonsterReadableId(String id) {
    final clean = id
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (clean.isEmpty) return id;
    return clean[0].toUpperCase() + clean.substring(1);
  }

  String systemMonsterPresetLabel(String name) {
    final clean = cleanUiText(name).trim();
    if (clean.length <= 18) return clean;
    return '${clean.substring(0, 17)}...';
  }

  String systemMonsterPresetType(MonsterBookEntry monster) {
    return monster.presetType;
  }

  String systemMonsterPresetArtMode(MonsterBookEntry monster) {
    final element = oculumNormalizeElementId(monster.elementId);
    final text = oculumNormalizeText(
      '${monster.nameIt} ${monster.nameEn} ${monster.descIt} ${monster.descEn} $element',
    );
    if (monster.isNullFateless ||
        element == 'vuoto' ||
        element == 'nullum' ||
        text.contains('null') ||
        text.contains('oblit')) {
      return 'null';
    }
    if (text.contains('zombie') ||
        text.contains('grimorio') ||
        text.contains('contrasto')) {
      return 'grimorio';
    }
    if (text.contains('follia') || text.contains('errat')) return 'illness';
    if (element == 'fisico' ||
        element == 'metallo' ||
        element == 'osso' ||
        element == 'cenere' ||
        element == 'natura' ||
        element == 'bestiale' ||
        text.contains('cavaliere') ||
        text.contains('fabbro')) {
      return 'martial';
    }
    if (text.contains('slime') || text.contains('patalpa')) return 'none';
    return 'oculum';
  }

  ({
    String description,
    String name,
    String type,
    String artMode,
    String side,
    bool enemy,
  })?
  systemMonsterPresetById(String id) {
    for (final preset in systemMonsterGeneratorPresets()) {
      if (preset.id == id) {
        return (
          description: preset.description,
          name: preset.name,
          type: preset.type,
          artMode: preset.artMode,
          side: preset.side,
          enemy: preset.enemy,
        );
      }
    }
    return null;
  }

  Future<void> creaSchedaRapidaMostroSistema(String presetId) async {
    final preset = systemMonsterPresetById(presetId);
    if (preset == null) return;
    quickSheetNameController.text = preset.name;
    quickSheetDescriptionController.text = preset.description;
    quickSheetCountController.text = '1';
    quickSheetArtMode = preset.artMode;
    await creaSchedaRapidaMaster(
      forcedType: preset.type,
      fallbackName: preset.name,
      sideOverride: preset.side,
      forceEnemyProfile: preset.enemy,
    );
  }

  List<String> partyResistanceFragilityElements() {
    final found = <String>[];

    void add(String raw) {
      final id = oculumNormalizeElementId(raw);
      if (id.isEmpty || id == 'sconosciuto' || found.contains(id)) return;
      found.add(id);
    }

    final candidates = <String>[
      ...oculumDefaultElementIds,
      ...customDamageTypes,
      for (final monster in monsterBookEntries) monster.elementId,
    ];
    final indexes = partyStatsCountIndexes();
    final source = indexes.isEmpty ? <int>[schedaCorrente] : indexes;
    for (final index in source) {
      if (index < 0 || index >= schedePersonaggio.length) continue;
      final sheet = schedePersonaggio[index];
      final text = oculumNormalizeText(
        '${sheet['buffMalusRapidi'] ?? ''} ${sheet['notePersonaggio'] ?? ''} '
        '${sheet['background'] ?? ''} ${sheet['customDamageTypes'] ?? ''}',
      );
      if (!text.contains('resistenza') &&
          !text.contains('resistent') &&
          !text.contains('fragil') &&
          !text.contains('vulnerabil')) {
        continue;
      }
      for (final candidate in candidates) {
        final id = oculumNormalizeElementId(candidate);
        final label = oculumNormalizeText(elementDisplayName(candidate));
        if (text.contains(id) || (label.isNotEmpty && text.contains(label))) {
          add(candidate);
        }
      }
    }
    return found;
  }

  List<String> generatedEntityElements(String description, String name) {
    final text = oculumNormalizeText('$description $name');
    final found = <String>[];

    void add(String id) {
      final normalized = oculumNormalizeElementId(id);
      if (normalized.isNotEmpty && !found.contains(normalized)) {
        found.add(normalized);
      }
    }

    for (final monster in monsterBookEntries) {
      final id = oculumNormalizeText(monster.id);
      final nameIt = oculumNormalizeText(monster.nameIt);
      final nameEn = oculumNormalizeText(monster.nameEn);
      if ((id.isNotEmpty && text.contains(id)) ||
          (nameIt.isNotEmpty && text.contains(nameIt)) ||
          (nameEn.isNotEmpty && text.contains(nameEn))) {
        add(monster.elementId);
      }
    }

    final affinity = partyResistanceFragilityElements();
    if (affinity.isNotEmpty && Random().nextInt(100) < 55) {
      add(affinity[Random().nextInt(affinity.length)]);
    }

    if (text.contains('fuoco') ||
        text.contains('fiamma') ||
        text.contains('brucia')) {
      add('fuoco');
    }
    if (text.contains('ghiaccio') ||
        text.contains('gelo') ||
        text.contains('fredd')) {
      add('gelo');
    }
    if (text.contains('fulmine') || text.contains('elettr')) {
      add('fulmine');
    }
    if (text.contains('sangue') ||
        text.contains('pelle') ||
        text.contains('muscol')) {
      add('sangue');
    }
    if (text.contains('zombie') ||
        text.contains('decaden') ||
        text.contains('morto')) {
      add('necrotico');
    }
    if (text.contains('palude') ||
        text.contains('opale') ||
        text.contains('cobalto')) {
      add('acqua');
      add('palude');
    }
    if (text.contains('opale') || text.contains('cristall')) {
      add('cristallo');
    }
    if (text.contains('sole') ||
        text.contains('solar') ||
        text.contains('oro')) {
      add('solare');
    }
    if (text.contains('campana') || text.contains('ruggine')) {
      add('ruggine');
    }
    if (text.contains('specchio')) {
      add('specchio');
    }
    if (text.contains('filo') || text.contains('burattino')) {
      add('filo');
    }
    if (text.contains('candela') || text.contains('cera')) {
      add('cera');
    }
    if (text.contains('ombra') || text.contains('invisibil')) {
      add('oscuro');
    }
    if (text.contains('suono') ||
        text.contains('urlo') ||
        text.contains('strill')) {
      add('sonoro');
    }
    if (text.contains('slime') || text.contains('gelatina')) {
      add('slime');
    }
    if (text.contains('foresta') ||
        text.contains('radice') ||
        text.contains('patalpa')) {
      add('natura');
    }
    if (text.contains('null') ||
        text.contains('oblit') ||
        text.contains('vuoto')) {
      add('vuoto');
    }
    if (isFolliaGhostText(text) ||
        text.contains('pensier') ||
        text.contains('cervello')) {
      add('psichico');
      add('necrotico');
    }
    if (text.contains('contrasto') || text.contains('forze contrastanti')) {
      add('sacro');
      add('diabolico');
    }
    if (found.isEmpty) {
      add(isEnemyTypeName(quickSheetType) ? 'fisico' : 'magia');
    }
    return found.take(4).toList();
  }

  String generatedEntityKind(String description, String name, String tipo) {
    final text = oculumNormalizeText('$description $name');
    if (text.contains('tre donne')) return 'Errato - Le Tre Donne';
    if (text.contains('facce spezzate')) return 'Coro delle Facce Spezzate';
    if (text.contains('utero di specchio')) return 'Utero di Specchio';
    if (text.contains('ossa-filo') || text.contains('giullare')) {
      return 'Giullare Ossa-Filo';
    }
    if (text.contains('vene di candela') || text.contains('santo')) {
      return 'Santo delle Vene di Candela';
    }
    if (text.contains('infante') || text.contains('vermi')) {
      return 'Errato - Testa di infante';
    }
    if (isFolliaGhostText(text)) return 'Errato di Follia';
    for (final monster in monsterBookEntries) {
      final id = oculumNormalizeText(monster.id);
      final nameIt = oculumNormalizeText(monster.nameIt);
      final nameEn = oculumNormalizeText(monster.nameEn);
      if ((id.isNotEmpty && text.contains(id)) ||
          (nameIt.isNotEmpty && text.contains(nameIt)) ||
          (nameEn.isNotEmpty && text.contains(nameEn))) {
        return monster.nameIt;
      }
    }
    if (text.contains('patalpa')) return 'Patalpa Dolce';
    if (text.contains('zombie') && text.contains('mago')) {
      return 'Mago zombie in decadenza';
    }
    if (text.contains('opale') || text.contains('palude')) return 'Opalus';
    if (text.contains('sole') || text.contains('ali') || text.contains('oro')) {
      return 'Ushrin';
    }
    if (text.contains('campana') || text.contains('ruggine')) {
      return 'Cavaliere Campana Ruggine';
    }
    if (text.contains('foresta')) return 'Forest Demon';
    if (text.contains('slime')) return 'Kitty Slime';
    return tipo.contains('Boss') ? 'Orrore superiore' : 'Mostro generato';
  }

  String generatedArtModeForDescription(String description) {
    final text = oculumNormalizeText(description);
    if (isFolliaGhostText(text)) {
      return quickSheetArtMode == 'random' ? 'illness' : quickSheetArtMode;
    }
    if (text.contains('grimorio') ||
        (text.contains('zombie') && text.contains('mago')) ||
        text.contains('forze contrastanti')) {
      return 'grimorio';
    }
    if (text.contains('oblit') || text.contains('null')) return 'null';
    if (quickSheetArtMode != 'random') return quickSheetArtMode;
    final roll = Random().nextInt(100);
    if (roll < 44) return 'martial';
    if (roll < 80) return 'oculum';
    if (roll < 87) return 'emblem';
    if (roll < 92) return 'defiled';
    if (roll < 97) return 'grimorio';
    if (roll < 99) return 'null';
    return 'none';
  }

  CharacterSkill generatedEntitySkill({
    required String name,
    required String element,
    required int level,
    required int grade,
    required int index,
    bool defensive = false,
  }) {
    final label = elementDisplayName(element);
    final power = max(4, level + grade * 6 + index * 3);
    final cooldown = defensive ? 4 + index : 2 + index;
    final cost = defensive
        ? '${max(1, 2 + grade)} Materia'
        : '${max(1, 2 + grade)} Oculum';
    final verb = defensive ? 'Scudo' : 'Morso';
    return CharacterSkill(
      nome: '$verb $label $index',
      tipo: defensive ? 'Difesa mostro' : 'Skill mostro',
      costo: cost,
      cooldown: '$cooldown turni',
      descrizione: defensive
          ? 'Si chiude in una difesa $label. @Difesa+$power $element'
          : 'Colpo $label generato dal corpo. @Danni+$power $element',
      danni: defensive ? 0 : power,
      difesa: defensive ? power : 0,
      equipaggiata: true,
      forme: [
        CharacterSkillForm(
          nome: 'Forma I',
          tipo: defensive ? 'Difesa' : 'Attacco',
          livello: 'I',
          costo: cost,
          cooldown: '$cooldown turni',
          descrizione: defensive
              ? 'Riduce il prossimo impatto. @Difesa+$power $element'
              : 'Attacco base $label. @Danni+$power $element',
        ),
        CharacterSkillForm(
          nome: 'Forma II',
          tipo: defensive ? 'Difesa' : 'Attacco',
          livello: 'II',
          costo: '${max(2, 3 + grade)} Oculum',
          cooldown: '${cooldown + 1} turni',
          descrizione: defensive
              ? 'La difesa diventa piu dura. @Difesa+${power + level} $element'
              : 'La ferita porta pressione. @Danni+${power + level} $element',
        ),
        CharacterSkillForm(
          nome: 'Forma III',
          tipo: defensive ? 'Difesa' : 'Attacco',
          livello: 'III',
          costo: '${max(4, 5 + grade * 2)} Oculum',
          cooldown: '${cooldown + 2} turni',
          descrizione: defensive
              ? 'Assorbe e prepara risposta. @Difesa+${power + level + grade * 6} $element'
              : 'Colpo pieno con effetto secondario. @Danni+${power + level + grade * 6} $element',
        ),
      ],
    );
  }

  List<CharacterSkill> generatedFolliaMonsterSkills({
    required String kind,
    required int level,
    required int grade,
  }) {
    final power = max(10, level + grade * 6);
    final quest = 'Quest skill: livello $level del mostro.';
    final normalizedKind = oculumNormalizeText(kind);
    if (normalizedKind.contains('facce spezzate')) {
      return [
        CharacterSkill(
          nome: 'Urlo della Memoria',
          tipo: 'Skill mostro Follia',
          costo: '2 Oculum',
          cooldown: '3 turni',
          descrizione:
              'Il coro urla con tutte le maschere: @Danni+${power + 10} Psichico e Stun se il bersaglio fallisce Volonta.\n$quest',
          danni: power + 10,
          equipaggiata: true,
        ),
        CharacterSkill(
          nome: 'Eco Follia',
          tipo: 'Skill mostro Follia',
          costo: '1 reazione',
          cooldown: '4 turni',
          descrizione:
              'Quando qualcuno usa Oculum vicino al coro, rimbalza un eco. Aggiunge 1 Follia e @Danni+${power ~/ 2} Sonoro.',
          danni: power ~/ 2,
          equipaggiata: true,
        ),
        CharacterSkill(
          nome: 'Frantuma Volonta',
          tipo: 'Skill mostro Follia',
          costo: '3 Oculum',
          cooldown: '5 turni',
          descrizione:
              'Una faccia si rompe e guarda il bersaglio: Vero Svantaggio al prossimo tiro e @Danni+${power + grade * 6} Necrotico.',
          danni: power + grade * 6,
          equipaggiata: true,
        ),
      ];
    }
    if (normalizedKind.contains('utero di specchio')) {
      return [
        CharacterSkill(
          nome: 'Nascita Riflessa',
          tipo: 'Skill mostro Follia',
          costo: '4 Oculum',
          cooldown: '4 turni',
          descrizione:
              'Copia la paura piu forte vista nel round. @Danni+${power + 14} Specchio e se critta riflette una skill appena subita.',
          danni: power + 14,
          equipaggiata: true,
        ),
        CharacterSkill(
          nome: 'Guscio d Argento',
          tipo: 'Skill mostro Follia',
          costo: '2 Materia',
          cooldown: '3 turni',
          descrizione:
              'Chiude il guscio e mostra occhi interni. @Difesa+${power + 16} Specchio, resistenza fisica per un turno.',
          difesa: power + 16,
          equipaggiata: true,
        ),
        CharacterSkill(
          nome: 'Falsa Gestazione',
          tipo: 'Skill mostro Follia',
          costo: '5 Oculum',
          cooldown: '6 turni',
          descrizione:
              'Intrappola il bersaglio in immagini false: Stun 1 se fallisce, o Vero Svantaggio se pareggia.',
          equipaggiata: true,
        ),
      ];
    }
    if (normalizedKind.contains('ossa-filo') ||
        normalizedKind.contains('giullare')) {
      return [
        CharacterSkill(
          nome: 'Risata Appesa',
          tipo: 'Skill mostro Follia',
          costo: '1 Oculum',
          cooldown: '2 turni',
          descrizione:
              'Ride tirato dai fili: @Danni+${power + 6} Sonoro e Stun se il tiro del bersaglio e 6 o meno.',
          danni: power + 6,
          equipaggiata: true,
        ),
        CharacterSkill(
          nome: 'Taglia Reazione',
          tipo: 'Skill mostro Follia',
          costo: '1 azione',
          cooldown: '3 turni',
          descrizione:
              'I fili neri tagliano lo spazio: il bersaglio perde una reazione o prende @Danni+${power + 4} Filo.',
          danni: power + 4,
          equipaggiata: true,
        ),
        CharacterSkill(
          nome: 'Scatto Burattino',
          tipo: 'Skill mostro Follia',
          costo: '2 Materia',
          cooldown: '2 turni',
          descrizione:
              'Si tira su un filo e diventa quasi invisibile per una azione, ottenendo vantaggio al prossimo colpo.',
          equipaggiata: true,
        ),
      ];
    }
    if (normalizedKind.contains('vene di candela') ||
        normalizedKind.contains('santo')) {
      return [
        CharacterSkill(
          nome: 'Aureola di Aghi',
          tipo: 'Skill mostro Follia',
          costo: '6 Oculum',
          cooldown: '4 turni',
          descrizione:
              'Gli aghi dell aureola cadono come pioggia: @Danni+${power + 28} Cera e Fragilita se fallisci.',
          danni: power + 28,
          equipaggiata: true,
        ),
        CharacterSkill(
          nome: 'Benedizione delle Vene',
          tipo: 'Skill mostro Follia',
          costo: '5 Oculum',
          cooldown: '5 turni',
          descrizione:
              'Rigenera orrore: cura 25% HP, ottiene @Difesa+${power + 20} Sangue e brucia chi lo colpisce.',
          difesa: power + 20,
          equipaggiata: true,
        ),
        CharacterSkill(
          nome: 'Marchio del Fato Cotto',
          tipo: 'Skill mostro Follia',
          costo: '8 Oculum',
          cooldown: '7 turni',
          descrizione:
              'Marchia il Fato del bersaglio: Vero Svantaggio e @Danni+${power + 36} Psichico. Con critico impedisce una cura.',
          danni: power + 36,
          equipaggiata: true,
        ),
      ];
    }
    if (normalizedKind.contains('tre donne')) {
      return [
        CharacterSkill(
          nome: 'Spuntoni',
          tipo: 'Skill mostro Follia',
          costo: '1 azione',
          cooldown: '2 turni',
          descrizione:
              'Modifica il suolo creando spuntoni. Somma sempre i danni normali del mostro. @Danni+${power + 8} Fisico\n$quest',
          danni: power + 8,
          equipaggiata: true,
        ),
        CharacterSkill(
          nome: 'Buchi',
          tipo: 'Skill mostro Follia',
          costo: '1 azione',
          cooldown: '3 turni',
          descrizione:
              'Apre buchi e pendenze sotto i bersagli: svantaggio agli avversari finche il suolo resta instabile.\n$quest',
          equipaggiata: true,
          forme: [
            CharacterSkillForm(
              nome: 'Buchi',
              tipo: 'Controllo',
              livello: 'I',
              costo: '1 azione',
              cooldown: '3 turni',
              descrizione:
                  'Il terreno cede: applica Svantaggio o Vero Svantaggio secondo la scena.',
              buff: 'Svantaggio',
            ),
          ],
        ),
        CharacterSkill(
          nome: 'Muro difensivo',
          tipo: 'Skill mostro Follia',
          costo: '1 azione',
          cooldown: '3 turni',
          descrizione:
              'Alza il suolo come muro trasparente e carnoso. @Difesa+${power + 12} Fisico @CM+${max(3, grade + 3)}\n$quest',
          difesa: power + 12,
          equipaggiata: true,
        ),
      ];
    }

    return [
      CharacterSkill(
        nome: 'Pensiero pesante',
        tipo: 'Skill mostro Follia',
        costo: 'Oculum/Follia',
        cooldown: '2 turni',
        descrizione:
            'Si connette ai pensieri altrui. I danni normali del mostro si sommano sempre ai danni della skill. @Danni+10 Psichico\n$quest',
        danni: 10,
        equipaggiata: true,
        forme: [
          CharacterSkillForm(
            nome: 'Pensiero pesante I',
            tipo: 'Psichico',
            livello: 'I',
            costo: '1 Oculum',
            cooldown: '2 turni',
            descrizione:
                'Ti connetti ai pensieri altrui: se falliscono prendono 1 Follia e 10 danni + danni normali.',
            danni: '@Danni+10 Psichico',
          ),
          CharacterSkillForm(
            nome: 'Pensiero pesante II',
            tipo: 'Psichico',
            livello: 'II',
            costo: '2 Oculum',
            cooldown: '3 turni',
            descrizione:
                'Pensieri intrusivi: Vero Svantaggio a tutti, 2 Follia e @Danni+16 Psichico se riesci. Se il tiro fallisce: 3 danni e 1 Follia, salvo critico positivo.',
            danni: '@Danni+16 Psichico',
            buff: 'Vero Svantaggio',
          ),
          CharacterSkillForm(
            nome: 'Pensiero pesante III',
            tipo: 'Psichico',
            livello: 'III',
            costo: '3 Oculum',
            cooldown: '4 turni',
            descrizione:
                'Pensieri intrusivi estremi: Vero Svantaggio a tutti, 2 Follia e @Danni+16 Psichico se riesci. Se fallisci: 3 danni e 1 Follia salvo critico negativo; con critico positivo metti 3 Follia e Svantaggio Oculum.',
            danni: '@Danni+16 Psichico',
            buff: 'Vero Svantaggio; Svantaggio Oculum su critico positivo',
          ),
        ],
      ),
    ];
  }

  CharacterArt generatedFolliaEntityArt({
    required int level,
    required int grade,
    required String kind,
  }) {
    final power = max(10, level + grade * 6);
    final normalizedKind = oculumNormalizeText(kind);
    if (normalizedKind.contains('tre donne')) {
      return CharacterArt(
        nome: 'Illness Art - Le Tre Donne',
        tipo: 'illness',
        descrizione:
            'Art errata da Follia. Corpo trasparente, tank a tre vite, controllo del suolo. Le skill hanno come quest il livello stesso del mostro.',
        openName: 'Tre vite riflesse',
        openDescription:
            'Quando una testa cade o il corpo perde una vita, la luce si riflette nella trasparenza e il terreno cambia forma.',
        openBuff: '@Stats+5 @Difesa+${power + 15} Fisico',
        openSkill:
            'Alla perdita di una vita puo creare subito Spuntoni, Buchi o Muro difensivo.',
        skills: [
          ArtSkill(
            nome: 'Spuntoni',
            livello: level,
            evo1:
                'I/ Il suolo fa spuntoni. Somma danni normali. @Danni+${power + 8} Fisico',
            evo2:
                'II/ Spuntoni concatenati: bersagli vicini prendono svantaggio se si muovono.',
            evo3:
                'III/ Il terreno resta minaccioso fino a fine round. @Danni+${power + 18} Fisico',
            danni: power + 8,
          ),
          ArtSkill(
            nome: 'Buchi',
            livello: level,
            evo1: 'I/ Buchi nel suolo: svantaggio agli avversari.',
            evo2:
                'II/ Vero Svantaggio se il bersaglio corre, carica o difende male.',
            evo3:
                'III/ La zona diventa trappola fino a fine scena se non viene stabilizzata.',
          ),
          ArtSkill(
            nome: 'Muro difensivo',
            livello: level,
            evo1: 'I/ Muro di suolo trasparente. @Difesa+${power + 12} Fisico',
            evo2:
                'II/ Il muro spinge e copre una testa. @CM+${max(3, grade + 3)}',
            evo3: 'III/ Il muro protegge tutte e tre le vite per un turno.',
            difesa: power + 12,
          ),
        ],
      );
    }

    return CharacterArt(
      nome: 'Illness Art - Apertura Mentale',
      tipo: 'illness',
      descrizione:
          'Art errata da Follia: creatura trasparente, inquietante e vista solo quando la Follia apre la percezione.',
      openName: 'Apertura Mentale',
      openDescription:
          'La testa del bambino si spacca in due: cervello, larve e parassiti si mostrano. Nasce un punto debole, ma il mostro ottiene +50 danni psichici.',
      openBuff: '@Stats+5 @Danni+50 Psichico',
      openSkill:
          'Quando viene colpito nel punto debole ottiene +5 Materia e fa un tiro su Materia: chi fallisce viene infettato e si trasforma entro 9 ore, salvo cura magica.',
      skills: [
        ArtSkill(
          nome: 'Pensiero pesante',
          livello: level,
          evo1:
              'I/ Connessione mentale: se falliscono prendono 1 Follia e @Danni+10 Psichico, sommando sempre i danni normali.',
          evo2:
              'II/ Pensieri intrusivi: Vero Svantaggio a tutti, 2 Follia e @Danni+16 Psichico se riesci. Se fallisci: 3 danni e 1 Follia salvo critico positivo.',
          evo3:
              'III/ Pensieri intrusivi estremi: come II, ma con critico positivo metti 3 Follia e Svantaggio Oculum; con critico negativo eviti il backlash.',
          danni: 16,
        ),
      ],
    );
  }

  CharacterArt? generatedEntityArt({
    required String mode,
    required List<String> elements,
    required int level,
    required int grade,
    required String kind,
  }) {
    if (mode == 'none') return null;
    if (mode == 'illness' || isFolliaGhostText(kind)) {
      return generatedFolliaEntityArt(level: level, grade: grade, kind: kind);
    }
    final skillCount = mode == 'grimorio' ? 6 : 3;
    final artElements = {
      ...elements,
      'fuoco',
      'gelo',
      'fulmine',
      'sangue',
      'sonoro',
      'vuoto',
    }.take(skillCount).toList();
    final artName = switch (mode) {
      'martial' => 'Martial Art del $kind',
      'oculum' => 'Oculum Art del $kind',
      'emblem' => 'Emblem Art del $kind',
      'defiled' => 'Defiled Art del $kind',
      'null' => 'Null Art - Obliterato',
      'grimorio' => 'Grimorio del $kind',
      _ => 'Art del $kind',
    };
    return CharacterArt(
      nome: artName,
      tipo: mode,
      descrizione: mode == 'null'
          ? 'Cancella cio che uccide o disintegra dall esistenza e dal ricordo.'
          : 'Art generata in base alla descrizione del mostro. Modificabile dal Master.',
      openName: mode == 'grimorio' ? 'Sei pagine vive' : 'Istinto della forma',
      openDescription: mode == 'grimorio'
          ? 'Contiene sei skill di elementi diversi.'
          : 'La forma si adatta al combattimento.',
      openBuff: mode == 'null'
          ? '@Danni+${max(10, level + grade * 6)} Vuoto'
          : '@Danni+${max(3, level ~/ 2 + grade * 3)} ${artElements.first}',
      openSkill: mode == 'grimorio'
          ? 'Il grimorio cambia pagina quando il bersaglio resiste.'
          : 'Combo naturale fra skill generate.',
      skills: [
        for (var i = 0; i < skillCount; i++)
          ArtSkill(
            nome: 'Pagina ${i + 1} - ${elementDisplayName(artElements[i])}',
            livello: min(3, max(1, level ~/ 5 + 1)),
            evo1:
                'I/ @Danni+${max(5, level + i * 2)} ${artElements[i]} - costo ${i + 1} Oculum - CD ${2 + i} turni.',
            evo2:
                'II/ @Danni+${max(8, level * 2 + i * 3)} ${artElements[i]} - combo se usata dopo una skill diversa.',
            evo3:
                'III/ @Danni+${max(12, level * 3 + grade * 6 + i * 4)} ${artElements[i]} - effetto forte, CD ${4 + i} turni.',
            danni: max(1, level + grade * 6 + i),
          ),
      ],
    );
  }

  MonsterBookEntry? monsterBookEntryForGeneratedEntity(
    String description,
    String name,
  ) {
    final text = oculumNormalizeText('$name $description');
    if (text.isEmpty) return null;
    for (final monster in monsterBookEntries) {
      final id = oculumNormalizeText(monster.id);
      final nameIt = oculumNormalizeText(monster.nameIt);
      final nameEn = oculumNormalizeText(monster.nameEn);
      if ((id.isNotEmpty && text.contains(id)) ||
          (nameIt.isNotEmpty && text.contains(nameIt)) ||
          (nameEn.isNotEmpty && text.contains(nameEn))) {
        return monster;
      }
    }
    return null;
  }

  String generatedEntityNotes({
    required String name,
    required String kind,
    required String description,
    required List<String> elements,
    required String defenseElement,
    required String artMode,
    MonsterBookEntry? monster,
  }) {
    final base = description.trim().isEmpty
        ? 'Creatura generata dal Master: corpo instabile, presenza ostile, comportamento modificabile.'
        : description.trim();
    final readableSkills = monster?.skillIds
        .map(systemMonsterReadableId)
        .join(', ');
    final readableDrops = monster?.dropIds
        .map(systemMonsterReadableId)
        .join(', ');
    final weaponLine = monster == null
        ? 'Armi: gestibili dal Master in base alla forma.'
        : monster.canWieldWeapons
        ? 'Armi: puo impugnare ${monster.weaponTags.join(', ')}. Armature: ${monster.armorTags.isEmpty ? 'nessuna preferenza' : monster.armorTags.join(', ')}.'
        : 'Armi: non impugna armi, usa corpo, forma o poteri naturali.';
    final spriteLine = monster == null
        ? 'Token: se il nome coincide con un mostro del bestiario viene usato lo sprite pre-caricato.'
        : 'Token: ${monsterSpriteAssetPaths(monster).length} forma/e pre-caricate per questa creatura.';
    return [
      'Descrizione del mostro: $base',
      'Tipo: $kind.',
      'Danni: ${elements.map(elementDisplayName).join(', ')}. Difesa: ${elementDisplayName(defenseElement)}.',
      weaponLine,
      if (readableSkills != null && readableSkills.isNotEmpty)
        'Abilita base: $readableSkills.',
      if (readableDrops != null && readableDrops.isNotEmpty)
        'Drop consigliati: $readableDrops.',
      'Art: $artMode. Skill e Art sono scritte ma partono disattivate; il Master puo attivarle quando servono.',
      spriteLine,
      if (isFolliaGhostText('$description $name $kind'))
        'Follia: usa questi mostri solo se il party ha Follia. Chance attuale errati ${folliaIncontroPercentuale()}%. I danni normali del mostro si sommano sempre alle skill.',
      'Spawn: puo avere @TypeSwitch, @safehp e @saveShield se la scena lo richiede.',
    ].join('\n');
  }

  Future<void> creaSchedaRapidaMaster({
    String? forcedType,
    String? fallbackName,
    String sideOverride = '',
    bool forceEnemyProfile = false,
  }) async {
    final selectedType = forcedType ?? quickSheetType;
    final baseName = quickSheetNameController.text.trim().isEmpty
        ? (fallbackName?.trim().isNotEmpty == true
              ? fallbackName!.trim()
              : '???')
        : quickSheetNameController.text.trim();
    final description = cleanUiText(
      quickSheetDescriptionController.text,
    ).trim();
    final enemyProfile = forceEnemyProfile || isEnemyTypeName(selectedType);
    final count = readIntValue(
      quickSheetCountController.text,
      fallback: 1,
    ).clamp(1, 10).toInt();
    if (isFolliaGhostText('$description $baseName') &&
        !folliaGeneratoreSbloccato()) {
      setState(() {
        risultato = t(
          'Generatore Follia bloccato: serve almeno 1 Follia nel party.',
          'Madness generator locked: the party needs at least 1 Madness.',
        );
        aggiungiLog(risultato);
      });
      return;
    }
    final createdNames = <String>[];

    for (var i = 0; i < count; i++) {
      final nome = count == 1 ? baseName : '$baseName ${i + 1}';
      final livello = suggestedQuickSheetLevel(enemyProfile);
      final grado = suggestedQuickSheetGrade(selectedType);
      final generatedStats = balancedQuickSheetStats(
        selectedType,
        forceEnemyProfile: forceEnemyProfile,
        level: livello,
        grade: grado,
        description: '$description $nome',
      );
      final elements = generatedEntityElements(description, nome);
      final defenseElement = elements.length > 1
          ? elements.last
          : elements.first;
      final matchedMonster = monsterBookEntryForGeneratedEntity(
        description,
        nome,
      );
      final kind =
          matchedMonster?.nameIt ??
          generatedEntityKind(description, nome, selectedType);
      final artMode = matchedMonster == null
          ? generatedArtModeForDescription(description)
          : systemMonsterPresetArtMode(matchedMonster);
      final spriteAssetPath = matchedMonster == null
          ? ''
          : monsterSpriteAssetFor(
              matchedMonster,
              seed: monsterSpriteStableSeed('$nome $i $description'),
            );
      Uint8List? presetImageBytes;
      final presetImageBase64 = matchedMonster?.imageBase64 ?? '';
      if (presetImageBase64.isNotEmpty) {
        try {
          presetImageBytes = base64Decode(presetImageBase64);
        } catch (error) {
          debugPrint('Monster Book custom image ignored: $error');
        }
      }

      await creaNuovaSchedaPersonaggio(
        nome: nome,
        tipo: selectedType,
        livello: livello,
        grado: grado,
        aggiungiAlMasterParty: true,
      );

      setState(() {
        resilienzaController.text = '${generatedStats['resilienza'] ?? 0}';
        volontaController.text = '${generatedStats['volonta'] ?? 0}';
        materiaController.text = '${generatedStats['materia'] ?? 0}';
        oculumController.text = '${generatedStats['oculum'] ?? 0}';
        quickSheetType = selectedType;
        final normalizedSide = sideOverride.trim().toLowerCase();
        if (normalizedSide == 'enemy' ||
            normalizedSide == 'ally' ||
            normalizedSide == 'neutral') {
          schedePersonaggio[schedaCorrente]['masterSideOverride'] =
              normalizedSide;
        } else if (enemyProfile) {
          schedePersonaggio[schedaCorrente]['masterSideOverride'] = 'enemy';
        }
        if (spriteAssetPath.isNotEmpty) {
          schedePersonaggio[schedaCorrente]['spriteAssetPath'] =
              spriteAssetPath;
        }
        if (presetImageBytes != null) {
          immaginePersonaggio = presetImageBytes;
        }

        backgroundController.text = generatedEntityNotes(
          name: nome,
          kind: kind,
          description: description,
          elements: elements,
          defenseElement: defenseElement,
          artMode: artMode,
          monster: matchedMonster,
        );
        notePersonaggioController.text = backgroundController.text;
        if (matchedMonster != null) {
          inventario
            ..clear()
            ..addAll([
              for (final dropId in matchedMonster.dropIds)
                InventoryItem(
                  nome: systemMonsterReadableId(dropId),
                  peso: 0,
                  quantita: 1,
                  note:
                      'Drop preset Monster Book: ${matchedMonster.nameIt}. Modificabile dal Master.',
                  elementoDanno: elementDisplayName(matchedMonster.elementId),
                ),
            ]);
        }
        buffMalusRapidiController.text = [
          '@TypeSwitch ${elementDisplayName(elements.first)}',
          '@safehp',
          '@saveShield+${max(1, livello + grado * 6)}',
          for (var e = 0; e < elements.length; e++)
            '@Danni+${max(1, livello + grado * 6 + e * 3)} ${elementDisplayName(elements[e])}',
          '@Difesa+${max(1, livello ~/ 2 + grado * 6)} ${elementDisplayName(defenseElement)}',
        ].join(' ');

        skills
          ..clear()
          ..addAll([
            for (var s = 0; s < max(1, min(3, elements.length + 1)); s++)
              generatedEntitySkill(
                name: nome,
                element: elements[s % elements.length],
                level: livello,
                grade: grado,
                index: s + 1,
                defensive: s == 1,
              ),
          ]);

        if (oculumNormalizeText('$description $nome').contains('patalpa')) {
          skills
            ..clear()
            ..addAll([
              CharacterSkill(
                nome: 'Generazione',
                tipo: 'Skill mostro',
                costo: '10 Oculum',
                cooldown: '10 turni',
                descrizione:
                    'Spende un azione per richiamare una Patalpa Dolce con le stats attuali del Patalpa piu debole e senza Generazione.',
                equipaggiata: true,
              ),
              CharacterSkill(
                nome: 'Palata',
                tipo: 'Skill mostro',
                costo: '1 azione',
                cooldown: '3 turni',
                descrizione:
                    'Con critico applica Stun x critico. @Danni+${max(2, livello * 2)} Fisico',
                danni: max(2, livello * 2),
                equipaggiata: true,
              ),
              CharacterSkill(
                nome: 'Rigenerazione sotterranea',
                tipo: 'Skill mostro',
                costo: '1 azione',
                cooldown: '2 turni',
                descrizione:
                    'Si mette per meta sotto terra: CM raddoppiata, non puo fare il tiro, rigenera 25% HP ogni turno.',
                difesa: cm(),
                equipaggiata: true,
              ),
            ]);
          notePersonaggioController.text =
              '${notePersonaggioController.text}\nDrop: [Patalpa Dolce] [250gr] [Cibo 2/1] [+1 a tutte le stats per un ora]. Con critico ottieni [Pala del Patalpa Dolce]: +4 VC, Palata, Punto Cieco -2 percezione.';
        }

        if (kind == 'Opalus') {
          skills
            ..clear()
            ..addAll([
              CharacterSkill(
                nome: 'Open Palude Opalina',
                tipo: 'Open mostro',
                costo: '4 Oculum',
                cooldown: '6 turni',
                descrizione:
                    'Trasforma la zona in palude. In palude Opalus ottiene +10 a stats rapide e @Difesa+${max(10, livello + grado * 6)} Palude.',
                difesa: max(10, livello + grado * 6),
                equipaggiata: true,
              ),
              CharacterSkill(
                nome: 'Riflesso Cobalto',
                tipo: 'Skill mostro',
                costo: '1 reazione',
                cooldown: '4 turni',
                descrizione:
                    'Con critico riflette parte dell attacco. @Danni+${max(8, livello + grado * 6)} Cristallo',
                danni: max(8, livello + grado * 6),
                equipaggiata: true,
              ),
              CharacterSkill(
                nome: 'Morso Palustre',
                tipo: 'Skill mostro',
                costo: '2 Materia',
                cooldown: '2 turni',
                descrizione:
                    'Morde e trascina nel fango. @Danni+${max(12, livello * 2 + grado * 6)} Acqua, rallenta il bersaglio.',
                danni: max(12, livello * 2 + grado * 6),
                equipaggiata: true,
              ),
            ]);
        } else if (kind == 'Ushrin') {
          skills
            ..clear()
            ..addAll([
              CharacterSkill(
                nome: 'Branco Solare',
                tipo: 'Skill mostro',
                costo: '2 Oculum',
                cooldown: '3 turni',
                descrizione:
                    'Gli Ushrin attaccano in branco. @Danni+${max(7, livello + grado * 6)} Solare per ogni piccolo gruppo vicino.',
                danni: max(7, livello + grado * 6),
                equipaggiata: true,
              ),
              CharacterSkill(
                nome: 'Spillo Dorato',
                tipo: 'Skill mostro',
                costo: '1 Materia',
                cooldown: '2 turni',
                descrizione:
                    'Colpisce con uno spillo di luce. @Danni+${max(9, livello * 2)} Solare, vantaggio se arriva dall alto.',
                danni: max(9, livello * 2),
                equipaggiata: true,
              ),
              CharacterSkill(
                nome: 'Battito Abbagliante',
                tipo: 'Skill mostro',
                costo: '3 Oculum',
                cooldown: '5 turni',
                descrizione:
                    'Le ali dorate esplodono di luce: svantaggio ai nemici che guardano, Stun con critico.',
                equipaggiata: true,
              ),
            ]);
        } else if (kind == 'Cavaliere Campana Ruggine') {
          skills
            ..clear()
            ..addAll([
              CharacterSkill(
                nome: 'Rintocco di Ruggine',
                tipo: 'Skill mostro',
                costo: '3 Oculum',
                cooldown: '3 turni',
                descrizione:
                    'La campana rintocca e spacca la guardia. @Danni+${max(14, livello * 2 + grado * 6)} Ruggine, riduce Difesa.',
                danni: max(14, livello * 2 + grado * 6),
                equipaggiata: true,
              ),
              CharacterSkill(
                nome: 'Guardia Campana',
                tipo: 'Skill mostro',
                costo: '2 Materia',
                cooldown: '2 turni',
                descrizione:
                    'Si chiude nella corazza. @Difesa+${max(18, livello + grado * 12)} Ruggine e scudo extra.',
                difesa: max(18, livello + grado * 12),
                equipaggiata: true,
              ),
              CharacterSkill(
                nome: 'Catena Trascinante',
                tipo: 'Skill mostro',
                costo: '1 azione',
                cooldown: '4 turni',
                descrizione:
                    'Trascina un bersaglio vicino. Se cade prende Fragilita e perde movimento.',
                equipaggiata: true,
              ),
            ]);
        } else if (kind == 'Kitty Slime') {
          skills
            ..clear()
            ..addAll([
              CharacterSkill(
                nome: 'Rimbalzo Morbido',
                tipo: 'Skill mostro innocua',
                costo: '1 azione',
                cooldown: '2 turni',
                descrizione:
                    'Rimbalza senza voler ferire. @Danni+${max(1, livello ~/ 2)} Slime solo se provocato.',
                danni: max(1, livello ~/ 2),
                equipaggiata: true,
              ),
              CharacterSkill(
                nome: 'Fusa Gelatinose',
                tipo: 'Skill mostro innocua',
                costo: '1 azione',
                cooldown: '4 turni',
                descrizione:
                    'Se trattato bene cura leggermente un alleato o dona uno scudo morbido.',
                equipaggiata: true,
              ),
            ]);
        }

        if (isFolliaGhostText('$description $nome $kind')) {
          skills
            ..clear()
            ..addAll(
              generatedFolliaMonsterSkills(
                kind: kind,
                level: livello,
                grade: grado,
              ),
            );
          notePersonaggioController.text =
              '${notePersonaggioController.text}\nRegola Follia: piu Follia nel party aumenta la frequenza di questi incontri. Illness Art raddoppia la Follia presa, ma evita il danno passivo. Danno Follia convertibile ora: ${folliaDannoConvertibile()} parziale / ${folliaDannoConvertibile(totale: true)} totale.';
          buffMalusRapidiController.text = [
            buffMalusRapidiController.text,
            '@Danni+16 Psichico',
            '@Difesa+${max(1, livello + grado * 6)} Necrotico',
            '@Stats+5',
          ].where((value) => value.trim().isNotEmpty).join(' ');
        }

        final generatedArt = generatedEntityArt(
          mode: artMode,
          elements: elements,
          level: livello,
          grade: grado,
          kind: kind,
        );
        if (generatedArt != null) {
          arti
            ..clear()
            ..add(generatedArt);
        } else if (skills.isEmpty) {
          skills.add(
            generatedEntitySkill(
              name: nome,
              element: elements.first,
              level: livello,
              grade: grado,
              index: 1,
            ),
          );
        }

        if (enemyProfile) {
          for (final skill in skills) {
            skill.equipaggiata = false;
          }
          for (final art in arti) {
            art.sbloccata = false;
          }
        }

        currentHpController.text = maxHp().toString();
        final countedMembers = max(1, generatedStats['countedMembers'] ?? 1);
        final enemyShieldBonus = enemyProfile ? livello * countedMembers : 0;
        scudoController.text = (scudoRefullTarget() + enemyShieldBonus)
            .toString();
        final profile = generatedStats['profile'] ?? 0;
        final profileLabel = profile > 0
            ? t('profilo raro forte', 'rare strong profile')
            : profile < 0
            ? t('profilo raro fragile', 'rare fragile profile')
            : t('media party', 'party average');
        risultato = t(
          'Scheda rapida $nome creata: $selectedType, $kind, $profileLabel (${campaignDifficultyLabel()}).',
          'Quick sheet $nome created: $selectedType, $kind, $profileLabel (${campaignDifficultyLabel()}).',
        );
        aggiungiLog(risultato);
      });

      salvaSchedaCorrenteInMemoria();
      createdNames.add(nome);
      if (quickSheetAddToInitiative && enemyProfile) {
        addSheetToMasterInitiative(schedaCorrente, rollInitiative: true);
      }
    }

    setState(() {
      risultato = t(
        'Generate ${createdNames.length} schede: ${createdNames.join(', ')}.',
        'Generated ${createdNames.length} sheets: ${createdNames.join(', ')}.',
      );
      aggiungiLog(risultato);
    });

    await salvaDati();
  }

  void cambiaTipoScheda(String tipo) {
    if (!tipiScheda.contains(tipo)) return;

    setState(() {
      tipoSchedaController.text = tipo;

      if (tipo == 'Mostro' && monsterStatPoints == 0) {
        monsterStatPoints = leggiNumero(livelloController) * 9;
      }

      risultato = t(
        'Tipo scheda cambiato in: $tipo.',
        'Sheet type changed to: $tipo.',
      );

      aggiungiLog('Tipo scheda cambiato in: $tipo.');
    });

    programmaSalvataggio();
  }

  // =====================================================
  // IMMAGINE PERSONAGGIO
  // =====================================================

  Future<void> scegliImmagine() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);

    if (file == null) return;

    final bytes = await file.readAsBytes();
    await importaImmaginePersonaggioDaBytes(
      bytes,
      sourceName: file.name.trim().isEmpty ? 'gallery' : file.name.trim(),
    );
  }

  Future<void> incollaImmaginePersonaggioDaClipboard() async {
    try {
      final clipboardImage = await Pasteboard.image;
      if (clipboardImage != null && clipboardImage.isNotEmpty) {
        await importaImmaginePersonaggioDaBytes(
          clipboardImage,
          sourceName: t('appunti', 'clipboard'),
        );
        return;
      }

      if (!kIsWeb) {
        final files = await Pasteboard.files();
        for (final rawPath in files) {
          final path = rawPath.startsWith('file:')
              ? Uri.parse(rawPath).toFilePath()
              : rawPath;
          final file = File(path);
          if (!await file.exists()) continue;

          final bytes = await file.readAsBytes();
          if (img.decodeImage(bytes) == null) continue;

          await importaImmaginePersonaggioDaBytes(
            bytes,
            sourceName: file.uri.pathSegments.isEmpty
                ? t('appunti', 'clipboard')
                : Uri.decodeComponent(file.uri.pathSegments.last),
          );
          return;
        }
      }

      if (!mounted) return;
      setState(() {
        risultato = t(
          'Nessuna immagine trovata negli appunti.',
          'No image found in the clipboard.',
        );
        aggiungiLog(risultato);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        risultato = t(
          'Impossibile leggere l\'immagine dagli appunti.',
          'Could not read an image from the clipboard.',
        );
        aggiungiLog('$risultato ($error)');
      });
    }
  }

  Future<void> importaImmaginePersonaggioDaBytes(
    Uint8List bytes, {
    String sourceName = '',
  }) async {
    if (bytes.isEmpty) {
      if (!mounted) return;
      setState(() {
        risultato = t('Immagine vuota ignorata.', 'Empty image ignored.');
        aggiungiLog(risultato);
      });
      return;
    }

    final decoded = img.decodeImage(bytes);
    if (decoded == null || decoded.width <= 0 || decoded.height <= 0) {
      if (!mounted) return;
      setState(() {
        risultato = t(
          'File immagine non valido: non ha sostituito l’immagine attuale.',
          'Invalid image file: current image was not replaced.',
        );
        aggiungiLog(risultato);
      });
      return;
    }

    final cropped = await mostraEditorCropEsagono(bytes);
    if (cropped == null || cropped.isEmpty) {
      if (!mounted) return;
      setState(() {
        risultato = t(
          'Ritaglio annullato: immagine precedente mantenuta.',
          'Crop cancelled: previous image kept.',
        );
        aggiungiLog(risultato);
      });
      return;
    }

    if (!mounted) return;

    setState(() {
      immaginePersonaggio = cropped;
      if (schedaCorrente >= 0 && schedaCorrente < schedePersonaggio.length) {
        schedePersonaggio[schedaCorrente]['immaginePersonaggioBase64'] =
            base64Encode(cropped);
      }
      final suffix = sourceName.trim().isEmpty ? '' : ' ($sourceName)';
      risultato = t(
        'Immagine scheda aggiornata$suffix.',
        'Sheet image updated$suffix.',
      );
      aggiungiLog(risultato);
    });

    await salvaDati();
  }

  Future<Uint8List?> mostraEditorCropEsagono(Uint8List bytes) async {
    final decoded = img.decodeImage(bytes);
    if (decoded == null || decoded.width <= 0 || decoded.height <= 0) {
      if (!mounted) return null;
      setState(() {
        risultato = t('Immagine non leggibile.', 'Image could not be read.');
        aggiungiLog(risultato);
      });
      return null;
    }

    double zoom = 1.0;
    double offsetX = 0.0;
    double offsetY = 0.0;
    int rotationDegrees = 0;
    bool flipHorizontal = false;
    double contrast = 1.0;
    double saturation = 1.0;
    double brightness = 1.0;
    int outputSize = 960;
    int outputQuality = 92;

    return showDialog<Uint8List>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final compact = MediaQuery.of(context).size.shortestSide < 600;
            final previewSize = compact ? 230.0 : 340.0;
            img.Image editedImage() {
              var result = img.Image.from(decoded);
              if (rotationDegrees % 360 != 0) {
                result = img.copyRotate(
                  result,
                  angle: rotationDegrees,
                  interpolation: img.Interpolation.cubic,
                );
              }
              if (flipHorizontal) {
                result = img.flipHorizontal(result);
              }
              if (contrast != 1.0 || saturation != 1.0 || brightness != 1.0) {
                result = img.adjustColor(
                  result,
                  contrast: contrast,
                  saturation: saturation,
                  brightness: brightness,
                );
              }
              return result;
            }

            final working = editedImage();

            Rect cropRect() {
              final minSide = min(working.width, working.height);
              final cropSide = (minSide / zoom).round().clamp(1, minSide);
              final maxX = max(0, working.width - cropSide);
              final maxY = max(0, working.height - cropSide);
              final cropX = ((offsetX + 1) * 0.5 * maxX).round().clamp(0, maxX);
              final cropY = ((offsetY + 1) * 0.5 * maxY).round().clamp(0, maxY);
              return Rect.fromLTWH(
                cropX.toDouble(),
                cropY.toDouble(),
                cropSide.toDouble(),
                cropSide.toDouble(),
              );
            }

            Uint8List cropCurrentImage({
              int? previewOutputSize,
              int? previewQuality,
            }) {
              final rect = cropRect();
              final cropped = img.copyCrop(
                working,
                x: rect.left.round(),
                y: rect.top.round(),
                width: rect.width.round(),
                height: rect.height.round(),
              );
              final targetSize = previewOutputSize ?? outputSize;
              final resized = img.copyResize(
                cropped,
                width: targetSize,
                height: targetSize,
                interpolation: img.Interpolation.cubic,
              );
              final encoded = img.encodeJpg(
                resized,
                quality: previewQuality ?? outputQuality,
              );
              if (encoded.isEmpty) return Uint8List(0);
              return Uint8List.fromList(encoded);
            }

            void clampOffsets() {
              final rect = cropRect();
              if (working.width <= rect.width.round()) offsetX = 0.0;
              if (working.height <= rect.height.round()) offsetY = 0.0;
              offsetX = offsetX.clamp(-1.0, 1.0).toDouble();
              offsetY = offsetY.clamp(-1.0, 1.0).toDouble();
            }

            void moveCrop(Offset delta) {
              setDialogState(() {
                final rect = cropRect();
                final horizontalRoom = max(0.0, working.width - rect.width);
                final verticalRoom = max(0.0, working.height - rect.height);
                if (horizontalRoom > 0) {
                  offsetX = (offsetX + delta.dx / previewSize * 2.0)
                      .clamp(-1.0, 1.0)
                      .toDouble();
                }
                if (verticalRoom > 0) {
                  offsetY = (offsetY + delta.dy / previewSize * 2.0)
                      .clamp(-1.0, 1.0)
                      .toDouble();
                }
              });
            }

            final previewBytes = cropCurrentImage(
              previewOutputSize: compact ? 460 : 680,
              previewQuality: 82,
            );

            Widget slider({
              required String label,
              required double value,
              required double min,
              required double max,
              required ValueChanged<double> onChanged,
            }) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Slider(
                    value: value,
                    min: min,
                    max: max,
                    activeColor: tertiaryColor,
                    inactiveColor: primaryColor.withValues(alpha: 0.22),
                    onChanged: (next) => setDialogState(() => onChanged(next)),
                  ),
                ],
              );
            }

            return Dialog(
              backgroundColor: const Color(0xFF060408),
              insetPadding: EdgeInsets.all(compact ? 10 : 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: tertiaryColor.withValues(alpha: 0.75)),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(compact ? 12 : 18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.crop, color: tertiaryColor),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                t(
                                  'Ritaglia immagine esagonale',
                                  'Crop hex portrait',
                                ),
                                style: TextStyle(
                                  color: tertiaryColor,
                                  fontSize: compact ? 17 : 21,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              icon: Icon(Icons.close, color: primaryColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: SizedBox(
                            width: previewSize,
                            height: previewSize,
                            child: GestureDetector(
                              onPanUpdate: (details) => moveCrop(details.delta),
                              child: ClipPath(
                                clipper: const HexagonClipper(),
                                child: ColoredBox(
                                  color: Colors.black,
                                  child: previewBytes.isEmpty
                                      ? Image.memory(
                                          bytes,
                                          fit: BoxFit.cover,
                                          alignment: Alignment(
                                            offsetX,
                                            offsetY,
                                          ),
                                        )
                                      : Image.memory(
                                          previewBytes,
                                          fit: BoxFit.cover,
                                          gaplessPlayback: true,
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: smallInfoText(
                            t(
                              'Trascina l\'immagine o usa gli slider. Il ritaglio salvato e esattamente quello mostrato.',
                              'Drag the image or use the sliders. The saved crop is exactly what is shown.',
                            ),
                            color: primaryColor.withValues(alpha: 0.72),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () {
                                setDialogState(() {
                                  rotationDegrees =
                                      (rotationDegrees + 90) % 360;
                                  offsetX = 0.0;
                                  offsetY = 0.0;
                                });
                              },
                              icon: const Icon(Icons.rotate_90_degrees_cw),
                              label: Text(t('Ruota', 'Rotate')),
                            ),
                            OutlinedButton.icon(
                              onPressed: () {
                                setDialogState(() {
                                  flipHorizontal = !flipHorizontal;
                                  offsetX = 0.0;
                                });
                              },
                              icon: const Icon(Icons.flip),
                              label: Text(t('Specchia', 'Flip')),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        slider(
                          label: t('Zoom', 'Zoom'),
                          value: zoom,
                          min: 1.0,
                          max: 3.0,
                          onChanged: (next) {
                            zoom = next;
                            clampOffsets();
                          },
                        ),
                        slider(
                          label: t('Sposta orizzontale', 'Move horizontal'),
                          value: offsetX,
                          min: -1.0,
                          max: 1.0,
                          onChanged: (next) {
                            offsetX = next;
                            clampOffsets();
                          },
                        ),
                        slider(
                          label: t('Sposta verticale', 'Move vertical'),
                          value: offsetY,
                          min: -1.0,
                          max: 1.0,
                          onChanged: (next) {
                            offsetY = next;
                            clampOffsets();
                          },
                        ),
                        slider(
                          label: t('Contrasto', 'Contrast'),
                          value: contrast,
                          min: 0.65,
                          max: 1.45,
                          onChanged: (next) => contrast = next,
                        ),
                        slider(
                          label: t('Saturazione', 'Saturation'),
                          value: saturation,
                          min: 0.55,
                          max: 1.55,
                          onChanged: (next) => saturation = next,
                        ),
                        slider(
                          label: t('Luminosita', 'Brightness'),
                          value: brightness,
                          min: 0.75,
                          max: 1.35,
                          onChanged: (next) => brightness = next,
                        ),
                        slider(
                          label: t('Qualita salvataggio', 'Save quality'),
                          value: outputQuality.toDouble(),
                          min: 72,
                          max: 96,
                          onChanged: (next) => outputQuality = next.round(),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  setDialogState(() {
                                    zoom = 1.0;
                                    offsetX = 0.0;
                                    offsetY = 0.0;
                                    rotationDegrees = 0;
                                    flipHorizontal = false;
                                    contrast = 1.0;
                                    saturation = 1.0;
                                    brightness = 1.0;
                                    outputSize = 960;
                                    outputQuality = 92;
                                  });
                                },
                                icon: const Icon(Icons.restart_alt),
                                label: Text(t('Reset', 'Reset')),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  final cropped = cropCurrentImage();
                                  Navigator.pop(dialogContext, cropped);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: tertiaryColor,
                                  foregroundColor:
                                      tertiaryColor.computeLuminance() > 0.45
                                      ? Colors.black
                                      : Colors.white,
                                ),
                                icon: const Icon(Icons.check),
                                label: Text(t('Usa ritaglio', 'Use crop')),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void rimuoviImmagine() {
    setState(() {
      immaginePersonaggio = null;
      aggiungiLog('Immagine scheda rimossa.');
    });

    programmaSalvataggio();
  }

  // =====================================================
}
