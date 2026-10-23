part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member, unused_element

extension _OculumCampaigns on _OculumHomePageState {
  String generateCampaignId() {
    return 'camp_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(999999)}';
  }

  String activeCampaignName() {
    final name = campaignNameController.text.trim();
    return name.isEmpty ? t('Campagna principale', 'Main campaign') : name;
  }

  Map<String, dynamic> currentCampaignSnapshot() {
    captureActiveMasterInitiativeGroup();
    return <String, dynamic>{
      'id': activeCampaignId.isEmpty ? generateCampaignId() : activeCampaignId,
      'name': activeCampaignName(),
      'pawnGuardians': pawnGuardians.map((pawn) => pawn.toJson()).toList(),
      'pawnDamageReceipts': pawnDamageReceipts,
      'pawnPendingDamage': pawnPendingDamage,
      'sheetSidebarFolders': sheetSidebarFolders
          .map((f) => Map<String, dynamic>.from(f))
          .toList(),
      'sheetSidebarPlacements': {
        for (final entry in sheetSidebarPlacements.entries)
          entry.key: Map<String, dynamic>.from(entry.value),
      },
      'schedaCorrente': schedaCorrente,
      'schedePersonaggio': schedePersonaggio
          .map((x) => Map<String, dynamic>.from(x))
          .toList(),
      'occhiCaduti': occhiCaduti
          .map((x) => Map<String, dynamic>.from(x))
          .toList(growable: false),
      'modalitaMaster': modalitaMaster,
      'masterEnemyFullSheetVisibility': masterEnemyFullSheetVisibility,
      'masterPublicDiceVisible': masterPublicDiceVisible,
      'masterAskPublicDiceConfirmation': masterAskPublicDiceConfirmation,
      'masterInitiativeTokens': masterInitiativeTokens
          .map((x) => Map<String, dynamic>.from(x))
          .toList(),
      'masterInitiativeGroups': masterInitiativeGroups
          .map((group) => Map<String, dynamic>.from(group))
          .toList(growable: false),
      'selectedMasterInitiativeGroupId': selectedMasterInitiativeGroupId,
      'masterInitiativeManualOrder': masterInitiativeManualOrder,
      'masterInitiativePublished': masterInitiativePublished,
      'masterInitiativeRound': masterInitiativeRound,
      'masterInitiativeActiveIndex': masterInitiativeActiveIndex,
      'masterInitiativeManualCounter': masterInitiativeManualCounter,
      'temporaryCombatResistanceEffects': currentCombatIsActive()
          ? temporaryCombatResistanceEffects
                .map((effect) => effect.toJson())
                .toList(growable: false)
          : <Map<String, dynamic>>[],
      'masterSessionNotes': masterSessionController.text,
      'storySessionNotes': storySessionNotes
          .map((note) => note.toJson())
          .toList(growable: false),
      'recipes': recipes
          .map((recipe) => recipe.toJson())
          .toList(growable: false),
      'mapMode': mapMode,
      'mapImagePath': mapImagePath,
      'mapImageName': mapImageName,
      'mapUrl': mapUrlController.text,
      'mapSplitPanelCount': mapSplitPanelCount,
      'mapSplitPanels': mapSplitPanels
          .map((panel) => Map<String, dynamic>.from(panel))
          .toList(growable: false),
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
          .toList(growable: false),
      'vttState': captureVttStateJson(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  void saveActiveCampaignInMemory() {
    if (activeCampaignId.isEmpty) {
      activeCampaignId = generateCampaignId();
    }

    final snapshot = currentCampaignSnapshot();
    final index = campagneOculum.indexWhere(
      (x) => '${x['id'] ?? ''}' == activeCampaignId,
    );

    if (index >= 0) {
      campagneOculum[index] = snapshot;
    } else {
      campagneOculum.add(snapshot);
    }
  }

  Map<String, dynamic> campaignFromLegacyData(Map<String, dynamic> data) {
    final sheets = <Map<String, dynamic>>[];
    if (data['multiScheda'] == true && data['schedePersonaggio'] is List) {
      sheets.addAll(
        ((data['schedePersonaggio'] ?? []) as List).whereType<Map>().map(
          (x) => Map<String, dynamic>.from(x),
        ),
      );
    } else {
      sheets.add(Map<String, dynamic>.from(data));
    }

    if (sheets.isEmpty) {
      sheets.add(statoVuotoPersonaggio());
    }

    return <String, dynamic>{
      'id': '${data['activeCampaignId'] ?? generateCampaignId()}',
      'name': '${data['campaignName'] ?? 'Campagna principale'}',
      'schedaCorrente': readIntValue(data['schedaCorrente']),
      'schedePersonaggio': sheets,
      'occhiCaduti':
          (data['occhiCaduti'] is List ? data['occhiCaduti'] as List : const [])
              .whereType<Map>()
              .map((x) => Map<String, dynamic>.from(x))
              .toList(growable: false),
      'modalitaMaster': readBoolValue(data['modalitaMaster']),
      'masterEnemyFullSheetVisibility': readBoolValue(
        data['masterEnemyFullSheetVisibility'],
      ),
      'masterPublicDiceVisible': readBoolValue(data['masterPublicDiceVisible']),
      'masterAskPublicDiceConfirmation': readBoolValue(
        data['masterAskPublicDiceConfirmation'],
        fallback: true,
      ),
      'masterInitiativeTokens': [],
      'masterInitiativeGroups': <Map<String, dynamic>>[],
      'selectedMasterInitiativeGroupId': 'encounter_1',
      'masterInitiativeManualOrder': false,
      'masterInitiativePublished': false,
      'masterInitiativeRound': 1,
      'masterInitiativeActiveIndex': 0,
      'masterInitiativeManualCounter': 0,
      'temporaryCombatResistanceEffects': <Map<String, dynamic>>[],
      'masterSessionNotes': '${data['masterSessionNotes'] ?? ''}',
      'storySessionNotes': oculumSessionNotesFromJson(
        data['storySessionNotes'],
      ).map((note) => note.toJson()).toList(growable: false),
      'recipes': ((data['recipes'] ?? data['ricette']) is List
          ? (data['recipes'] ?? data['ricette']) as List
          : const <dynamic>[]),
      'mapMode': '${data['mapMode'] ?? 'image'}',
      'mapImagePath': '${data['mapImagePath'] ?? ''}',
      'mapImageName': '${data['mapImageName'] ?? ''}',
      'mapUrl': '${data['mapUrl'] ?? ''}',
      'mapNotes': '${data['mapNotes'] ?? ''}',
      'mapSaveSession': readBoolValue(data['mapSaveSession']),
      'mapSessionChoiceAsked': readBoolValue(data['mapSessionChoiceAsked']),
      'mapPlayersCanManageOwnToken': readBoolValue(
        data['mapPlayersCanManageOwnToken'],
        fallback: true,
      ),
      'mapTokenSize': '${data['mapTokenSize'] ?? '64'}',
      'mapWidthMeters': '${data['mapWidthMeters'] ?? '30'}',
      'mapHeightMeters': '${data['mapHeightMeters'] ?? '20'}',
      'mapFreeTokenMovement': '${data['mapFreeTokenMovement'] ?? '6'}',
      'mapTokenSheetIndex': readIntValue(data['mapTokenSheetIndex']),
      'localMapTokens': _oculumVttMapList(
        data['localMapTokens'],
        maxItems: 1000,
      ),
      'vttState': OculumVttState.fromJson(
        data['vttState'],
        legacy: data,
      ).toJson(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  void loadCampaignSnapshot(Map<String, dynamic> campaign) {
    final sheetsRaw = campaign['schedePersonaggio'];
    final sheets = sheetsRaw is List
        ? sheetsRaw
              .whereType<Map>()
              .map((x) => Map<String, dynamic>.from(x))
              .toList()
        : <Map<String, dynamic>>[];

    if (sheets.isEmpty) {
      sheets.add(statoVuotoPersonaggio());
    }

    sheetSidebarFolders
      ..clear()
      ..addAll(
        (campaign['sheetSidebarFolders'] as List? ?? []).whereType<Map>().map(
          (folder) => Map<String, dynamic>.from(folder),
        ),
      );
    sheetSidebarPlacements.clear();
    final placements = campaign['sheetSidebarPlacements'];
    if (placements is Map) {
      for (final entry in placements.entries) {
        if (entry.value is Map) {
          sheetSidebarPlacements['${entry.key}'] = Map<String, dynamic>.from(
            entry.value as Map,
          );
        }
      }
    }
    sheetSidebarRevision.value++;
    activeCampaignId = '${campaign['id'] ?? generateCampaignId()}';
    loadPawnCampaignState(campaign);
    campaignNameController.text =
        '${campaign['name'] ?? 'Campagna principale'}';
    schedePersonaggio
      ..clear()
      ..addAll(sheets);
    occhiCaduti
      ..clear()
      ..addAll(
        (campaign['occhiCaduti'] is List
                ? campaign['occhiCaduti'] as List
                : const [])
            .whereType<Map>()
            .map((x) => Map<String, dynamic>.from(x)),
      );
    schedaCorrente = readIntValue(campaign['schedaCorrente']);
    modalitaMaster = readBoolValue(campaign['modalitaMaster']);
    masterEnemyFullSheetVisibility = readBoolValue(
      campaign['masterEnemyFullSheetVisibility'],
    );
    masterPublicDiceVisible = readBoolValue(
      campaign['masterPublicDiceVisible'],
    );
    masterAskPublicDiceConfirmation = readBoolValue(
      campaign['masterAskPublicDiceConfirmation'],
      fallback: true,
    );
    final initiativeRaw = campaign['masterInitiativeTokens'];
    masterInitiativeTokens
      ..clear()
      ..addAll(
        (initiativeRaw is List ? initiativeRaw : const []).whereType<Map>().map(
          (x) => Map<String, dynamic>.from(x),
        ),
      );
    masterInitiativeManualOrder = readBoolValue(
      campaign['masterInitiativeManualOrder'],
    );
    masterInitiativePublished = readBoolValue(
      campaign['masterInitiativePublished'],
    );
    masterInitiativeRound = max(
      0,
      readIntValue(campaign['masterInitiativeRound'], fallback: 1),
    );
    masterInitiativeActiveIndex = max(
      0,
      readIntValue(campaign['masterInitiativeActiveIndex']),
    );
    masterInitiativeManualCounter = max(
      0,
      readIntValue(campaign['masterInitiativeManualCounter']),
    );
    final groupsRaw = campaign['masterInitiativeGroups'];
    masterInitiativeGroups
      ..clear()
      ..addAll(
        (groupsRaw is List ? groupsRaw : const <dynamic>[])
            .whereType<Map>()
            .map((group) => Map<String, dynamic>.from(group)),
      );
    selectedMasterInitiativeGroupId =
        '${campaign['selectedMasterInitiativeGroupId'] ?? 'encounter_1'}';
    ensureMasterInitiativeGroups();
    loadSelectedMasterInitiativeGroup();
    final temporaryEffectsRaw = campaign['temporaryCombatResistanceEffects'];
    temporaryCombatResistanceEffects
      ..clear()
      ..addAll(
        (temporaryEffectsRaw is List ? temporaryEffectsRaw : const [])
            .whereType<Map>()
            .map(
              (effect) => OculumTemporaryResistanceEffect.fromJson(
                Map<String, dynamic>.from(effect),
              ),
            )
            .where(
              (effect) =>
                  effect.ownerSheetId.trim().isNotEmpty &&
                  effect.isAdaptationAllDamageCurrentCombat,
            ),
      );
    if (masterInitiativeTokens.isEmpty && !masterInitiativePublished) {
      temporaryCombatResistanceEffects.clear();
    }
    masterSessionController.text = '${campaign['masterSessionNotes'] ?? ''}';
    storySessionNotes
      ..clear()
      ..addAll(oculumSessionNotesFromJson(campaign['storySessionNotes']));
    final recipesRaw = campaign['recipes'] ?? campaign['ricette'];
    recipes
      ..clear()
      ..addAll(
        (recipesRaw is List ? recipesRaw : const <dynamic>[])
            .whereType<Map>()
            .map(
              (recipe) =>
                  OculumRecipe.fromJson(Map<String, dynamic>.from(recipe)),
            ),
      );
    recipesRevision.value++;
    mapMode = '${campaign['mapMode'] ?? 'image'}' == 'online'
        ? 'online'
        : 'image';
    mapImagePath = '${campaign['mapImagePath'] ?? ''}';
    mapImageName = '${campaign['mapImageName'] ?? ''}';
    mapUrlController.text = '${campaign['mapUrl'] ?? ''}';
    mapSplitPanelCount = readIntValue(
      campaign['mapSplitPanelCount'],
      fallback: 1,
    ).clamp(1, 4).toInt();
    final splitRaw = campaign['mapSplitPanels'];
    mapSplitPanels = splitRaw is List
        ? splitRaw
              .whereType<Map>()
              .take(4)
              .map((panel) => Map<String, dynamic>.from(panel))
              .toList(growable: true)
        : <Map<String, dynamic>>[];
    while (mapSplitPanels.length < mapSplitPanelCount) {
      mapSplitPanels.add(<String, dynamic>{
        'kind': 'sheet',
        'sheetTag': '',
        'url': '',
      });
    }
    mapNotesController.text = '${campaign['mapNotes'] ?? ''}';
    mapSaveSession = readBoolValue(campaign['mapSaveSession']);
    mapSessionChoiceAsked = readBoolValue(campaign['mapSessionChoiceAsked']);
    mapPlayersCanManageOwnToken = readBoolValue(
      campaign['mapPlayersCanManageOwnToken'],
      fallback: true,
    );
    mapTokenSizeController.text = '${campaign['mapTokenSize'] ?? '64'}';
    mapWidthMetersController.text = '${campaign['mapWidthMeters'] ?? '30'}';
    mapHeightMetersController.text = '${campaign['mapHeightMeters'] ?? '20'}';
    mapFreeTokenMovementController.text =
        '${campaign['mapFreeTokenMovement'] ?? '6'}';
    mapTokenSheetIndex = readIntValue(campaign['mapTokenSheetIndex']);
    final campaignMapTokens = _oculumVttMapList(
      campaign['localMapTokens'],
      maxItems: 1000,
    );
    localMapTokens
      ..clear()
      ..addAll(campaignMapTokens);
    restoreVttStateFromJson(
      campaign['vttState'],
      legacy: <String, dynamic>{
        ...campaign,
        'localMapTokens': campaignMapTokens,
      },
    );

    if (schedaCorrente < 0 || schedaCorrente >= schedePersonaggio.length) {
      schedaCorrente = 0;
    }

    repairMissingFallenEyeSheets();
    caricaStatoDaJson(schedePersonaggio[schedaCorrente]);
    assicuraTagSchede();
  }

  void ensureCampaignsReady() {
    if (activeCampaignId.isEmpty) {
      activeCampaignId = generateCampaignId();
    }
    if (campaignNameController.text.trim().isEmpty) {
      campaignNameController.text = 'Campagna principale';
    }
    if (campagneOculum.isEmpty) {
      saveActiveCampaignInMemory();
    }
  }

  Future<void> createCampaign() async {
    final name = newCampaignNameController.text.trim().isEmpty
        ? t('Nuova campagna', 'New campaign')
        : newCampaignNameController.text.trim();

    salvaSchedaCorrenteInMemoria();
    saveActiveCampaignInMemory();

    final newId = generateCampaignId();
    final emptySheet = statoVuotoPersonaggio(nome: '???');

    setState(() {
      activeCampaignId = newId;
      campaignNameController.text = name;
      newCampaignNameController.clear();
      schedePersonaggio
        ..clear()
        ..add(emptySheet);
      // Gli Occhi appartengono alla campagna uscente, già salvata poco sopra.
      // Una nuova campagna parte senza portarli con sé.
      occhiCaduti.clear();
      storySessionNotes.clear();
      recipes.clear();
      recipesRevision.value++;
      temporaryCombatResistanceEffects.clear();
      resetVttForNewCampaign();
      schedaCorrente = 0;
      caricaStatoDaJson(emptySheet);
      assicuraTagSchede();
      saveActiveCampaignInMemory();
      risultato = t('Campagna creata: $name.', 'Campaign created: $name.');
      aggiungiLog(risultato);
    });

    await salvaDatiSoloLocale();
  }

  Future<void> deleteActiveCampaignPermanently() async {
    ensureCampaignsReady();
    final name = activeCampaignName();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF10121A),
        title: Text(
          t('Eliminare campagna per sempre?', 'Permanently delete campaign?'),
          style: const TextStyle(color: Colors.redAccent),
        ),
        content: Text(
          t(
            '“$name”, tutte le sue schede, diari, ricette, gruppi e token saranno rimossi definitivamente dal salvataggio locale. Questa azione non modifica altre campagne.',
            '“$name”, all its sheets, diaries, recipes, groups and tokens will be permanently removed from the local save. Other campaigns are untouched.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(t('Annulla', 'Cancel')),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.delete_forever),
            label: Text(t('Elimina per sempre', 'Delete forever')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    salvaSchedaCorrenteInMemoria();
    saveActiveCampaignInMemory();
    setState(() {
      campagneOculum.removeWhere(
        (campaign) => '${campaign['id'] ?? ''}' == activeCampaignId,
      );
      if (campagneOculum.isEmpty) {
        activeCampaignId = generateCampaignId();
        campaignNameController.text = t('Campagna principale', 'Main campaign');
        schedePersonaggio
          ..clear()
          ..add(statoVuotoPersonaggio());
        occhiCaduti.clear();
        storySessionNotes.clear();
        recipes.clear();
        schedaCorrente = 0;
        caricaStatoDaJson(schedePersonaggio.first);
        saveActiveCampaignInMemory();
      } else {
        loadCampaignSnapshot(campagneOculum.first);
      }
      risultato = t(
        'Campagna eliminata definitivamente: $name.',
        'Campaign permanently deleted: $name.',
      );
      aggiungiLog(risultato);
    });
    await salvaDatiSoloLocale();
  }

  Future<void> switchCampaign(String campaignId) async {
    if (campaignId == activeCampaignId) return;

    salvaSchedaCorrenteInMemoria();
    saveActiveCampaignInMemory();

    final campaign = campagneOculum.firstWhere(
      (x) => '${x['id'] ?? ''}' == campaignId,
      orElse: () => <String, dynamic>{},
    );
    if (campaign.isEmpty) return;

    setState(() {
      loadCampaignSnapshot(campaign);
      risultato = t(
        'Campagna aperta: ${activeCampaignName()}.',
        'Campaign opened: ${activeCampaignName()}.',
      );
      aggiungiLog(risultato);
    });

    await salvaDatiSoloLocale();
  }

  Future<void> moveCampaignSheets() async {
    ensureCampaignsReady();
    if (realtimeService?.isConnected == true) {
      setState(() {
        risultato = t(
          'Scollega Realtime prima di spostare le schede: così la campagna online resta coerente.',
          'Disconnect Realtime before moving sheets so the online campaign stays consistent.',
        );
        aggiungiLog(risultato);
      });
      return;
    }

    salvaSchedaCorrenteInMemoria();
    assicuraTagSchede();
    saveActiveCampaignInMemory();
    final sourceId = activeCampaignId;
    final source = currentCampaignSnapshot();
    const createDestination = '__create_campaign__';
    final destinations = campagneOculum
        .where((campaign) => '${campaign['id'] ?? ''}' != sourceId)
        .toList(growable: false);
    final selectedTags = <String>{};
    final newName = TextEditingController(
      text: t('Nuova campagna', 'New campaign'),
    );
    var destinationId = destinations.isEmpty
        ? createDestination
        : '${destinations.first['id'] ?? ''}';

    final choice = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          scrollable: true,
          backgroundColor: const Color(0xFF10121A),
          shape: RoundedRectangleBorder(
            side: BorderSide(color: tertiaryColor.withValues(alpha: 0.8)),
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.swap_horiz_rounded, color: tertiaryColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  t('Sposta schede', 'Move sheets'),
                  style: TextStyle(color: tertiaryColor),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.sizeOf(context).width > 588
                ? 540
                : MediaQuery.sizeOf(context).width - 48,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                smallInfoText(
                  t(
                    'Seleziona una o più schede e scegli la campagna di destinazione. Statistiche, immagini, inventario, diari e dati collegati vengono conservati.',
                    'Select one or more sheets and choose a destination campaign. Stats, images, inventory, diaries and linked data are preserved.',
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: destinationId,
                  dropdownColor: const Color(0xFF11131A),
                  decoration: fieldDecoration(
                    t('Campagna di destinazione', 'Destination campaign'),
                  ),
                  items: [
                    for (final campaign in destinations)
                      DropdownMenuItem<String>(
                        value: '${campaign['id'] ?? ''}',
                        child: Text('${campaign['name'] ?? 'Campagna'}'),
                      ),
                    DropdownMenuItem<String>(
                      value: createDestination,
                      child: Text(
                        t('Crea una nuova campagna…', 'Create a new campaign…'),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setDialogState(() => destinationId = value);
                  },
                ),
                if (destinationId == createDestination) ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: newName,
                    maxLength: 64,
                    style: const TextStyle(color: Colors.white),
                    decoration: fieldDecoration(
                      t('Nome della nuova campagna', 'New campaign name'),
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  t(
                    'Schede in ${activeCampaignName()}',
                    'Sheets in ${activeCampaignName()}',
                  ),
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF090A10),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.35),
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: BoxConstraints(
                    maxHeight: (MediaQuery.sizeOf(context).height * 0.34).clamp(
                      100.0,
                      330.0,
                    ),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: schedePersonaggio.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                    itemBuilder: (context, index) {
                      final tag = sheetTagAt(index).toUpperCase();
                      final sheet = schedaJsonAt(index);
                      final type = '${sheet['tipoScheda'] ?? 'Personaggio'}';
                      return CheckboxListTile(
                        dense: true,
                        value: selectedTags.contains(tag),
                        activeColor: tertiaryColor,
                        checkColor: Colors.black,
                        title: Text(
                          nomeSchedaPersonaggio(index),
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          '$type · $tag',
                          style: const TextStyle(color: Colors.white54),
                        ),
                        onChanged: (value) => setDialogState(() {
                          if (value == true) {
                            selectedTags.add(tag);
                          } else {
                            selectedTags.remove(tag);
                          }
                        }),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(t('Annulla', 'Cancel')),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: tertiaryColor,
                foregroundColor: Colors.black,
              ),
              onPressed: selectedTags.isEmpty
                  ? null
                  : () => Navigator.pop(dialogContext, {
                      'sheetTags': selectedTags.toList(growable: false),
                      'destinationId': destinationId,
                      'newCampaignName': newName.text.trim(),
                    }),
              icon: const Icon(Icons.drive_file_move_outline),
              label: Text(t('Sposta', 'Move')),
            ),
          ],
        ),
      ),
    );
    newName.dispose();
    if (choice == null || !mounted) return;

    final tags = (choice['sheetTags'] as List? ?? const <dynamic>[])
        .map((tag) => '$tag'.trim().toUpperCase())
        .where((tag) => tag.isNotEmpty)
        .toSet();
    if (tags.isEmpty) return;
    final destinationChoice = '${choice['destinationId'] ?? ''}';
    final creating = destinationChoice == createDestination;
    Map<String, dynamic> target;
    if (creating) {
      final name = '${choice['newCampaignName'] ?? ''}'.trim().isEmpty
          ? t('Nuova campagna', 'New campaign')
          : '${choice['newCampaignName']}'.trim();
      final id = generateCampaignId();
      target =
          campaignFromLegacyData({
              'activeCampaignId': id,
              'campaignName': name,
              'multiScheda': true,
              'schedePersonaggio': <Map<String, dynamic>>[],
            })
            ..['id'] = id
            ..['name'] = name
            ..['schedePersonaggio'] = <Map<String, dynamic>>[];
    } else {
      final index = campagneOculum.indexWhere(
        (campaign) => '${campaign['id'] ?? ''}' == destinationChoice,
      );
      if (index < 0) return;
      target = Map<String, dynamic>.from(campagneOculum[index]);
    }

    try {
      final transferred = moveOculumCampaignSheets(
        source: source,
        destination: target,
        sheetTags: tags,
      );
      final updatedSource = transferred['source']!;
      final updatedDestination = transferred['destination']!;
      updatedSource['updatedAt'] = DateTime.now().toIso8601String();
      updatedDestination['updatedAt'] = DateTime.now().toIso8601String();
      setState(() {
        final sourceIndex = campagneOculum.indexWhere(
          (campaign) => '${campaign['id'] ?? ''}' == sourceId,
        );
        if (sourceIndex >= 0) campagneOculum[sourceIndex] = updatedSource;
        final targetIndex = campagneOculum.indexWhere(
          (campaign) =>
              '${campaign['id'] ?? ''}' == '${updatedDestination['id'] ?? ''}',
        );
        if (targetIndex >= 0) {
          campagneOculum[targetIndex] = updatedDestination;
        } else {
          campagneOculum.add(updatedDestination);
        }
        loadCampaignSnapshot(updatedDestination);
        risultato = t(
          'Spostate ${tags.length} schede in ${activeCampaignName()}.',
          'Moved ${tags.length} sheets to ${activeCampaignName()}.',
        );
        aggiungiLog(risultato);
        saveActiveCampaignInMemory();
      });
      await salvaDatiSoloLocale();
    } on StateError catch (error) {
      setState(() {
        risultato = t(
          'Spostamento non completato: ${error.message}',
          'Move not completed: ${error.message}',
        );
        aggiungiLog(risultato);
      });
    }
  }

  Future<void> renameActiveCampaign(String value) async {
    campaignNameController.text = value.trim().isEmpty
        ? activeCampaignName()
        : value.trim();
    salvaSchedaCorrenteInMemoria();
    saveActiveCampaignInMemory();
    await salvaDatiSoloLocale();
  }

  Future<void> requestKickSheet({
    required String targetId,
    required String targetName,
    int? sheetIndex,
    bool ban = false,
  }) async {
    if (!(modalitaMaster || isMasterHost || sonoCoMaster)) return;
    if (targetId.trim().isEmpty) return;
    if (ban && realtimeService?.isConnected != true) return;

    if (!masterKickRequiresConfirmation) {
      await kickSheetFromCampaign(
        targetId: targetId,
        targetName: targetName,
        sheetIndex: sheetIndex,
        ban: ban,
      );
      return;
    }

    var disableFutureConfirm = false;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF10121A),
              title: Text(
                t('Kickare davvero?', 'Really kick?'),
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t(
                      ban
                          ? 'Vuoi bannare $targetName dalla stanza? Potrà rientrare solo dopo aver tolto il ban.'
                          : 'Vuoi togliere $targetName dal party/sessione?',
                      ban
                          ? 'Do you want to ban $targetName from this room? They can return only after the ban is lifted.'
                          : 'Do you want to remove $targetName from the party/session?',
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: disableFutureConfirm,
                    activeColor: tertiaryColor,
                    title: Text(
                      t(
                        'l\'occhio non ti chiederà più la conferma fino a modifica nelle impostazioni master',
                        'the eye will not ask for confirmation again until changed in Master settings',
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    onChanged: (value) {
                      setDialogState(
                        () => disableFutureConfirm = value ?? false,
                      );
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    t('Non kickare', 'Do not kick'),
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  icon: const Icon(Icons.person_remove),
                  label: Text(
                    ban
                        ? t('Banna dalla stanza', 'Ban from room')
                        : t('Kicka davvero', 'Really kick'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) return;

    if (disableFutureConfirm) {
      setState(() => masterKickRequiresConfirmation = false);
    }

    await kickSheetFromCampaign(
      targetId: targetId,
      targetName: targetName,
      sheetIndex: sheetIndex,
      ban: ban,
    );
  }

  Future<void> kickSheetFromCampaign({
    required String targetId,
    required String targetName,
    int? sheetIndex,
    bool ban = false,
  }) async {
    if (realtimeService?.isConnected == true) {
      try {
        await realtimeService!.moderateRoomSheet(
          targetId,
          action: ban ? 'ban' : 'kick',
        );
      } catch (error) {
        if (mounted) {
          setState(() {
            risultato = 'Moderazione stanza non riuscita: $error';
            aggiungiLog(risultato);
          });
        }
        return;
      }
    } else if (ban) {
      return;
    }
    setState(() {
      if (sheetIndex != null &&
          sheetIndex >= 0 &&
          sheetIndex < schedePersonaggio.length) {
        schedePersonaggio[sheetIndex]['inMasterParty'] = false;
      }

      partyMembri.removeWhere(
        (member) =>
            '${member['id'] ?? member['sheetTag'] ?? ''}'.trim() == targetId,
      );

      risultato = t(
        ban
            ? '$targetName è stato bannato dalla stanza.'
            : '$targetName è stato kickato dal party.',
        ban
            ? '$targetName has been banned from the room.'
            : '$targetName was kicked from the party.',
      );
      aggiungiLog(risultato);
      saveActiveCampaignInMemory();
    });

    sendKickPlayer(targetId);
    await salvaDati();
  }

  Future<void> manageRoomBans() async {
    final service = realtimeService;
    if (service == null ||
        !service.isConnected ||
        !(modalitaMaster || isMasterHost || sonoCoMaster)) {
      return;
    }
    List<Map<String, dynamic>> bans;
    try {
      bans = await service.listRoomBans();
    } catch (error) {
      if (mounted) {
        setState(() => risultato = 'Elenco ban non disponibile: $error');
      }
      return;
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (context, refresh) => AlertDialog(
          title: const Text('Utenti bannati dalla stanza'),
          content: SizedBox(
            width: 420,
            child: bans.isEmpty
                ? const Text('Nessun utente bannato.')
                : ListView(
                    shrinkWrap: true,
                    children: [
                      for (final ban in bans)
                        ListTile(
                          title: Text('${ban['displayName'] ?? 'Giocatore'}'),
                          subtitle: Text('${ban['sheetTag'] ?? ''}'),
                          trailing: IconButton(
                            tooltip: 'Rimuovi ban',
                            icon: const Icon(Icons.lock_open),
                            onPressed: () async {
                              try {
                                await service.moderateRoomSheet(
                                  '${ban['sheetTag']}',
                                  action: 'unban',
                                );
                                refresh(() => bans.remove(ban));
                              } catch (error) {
                                if (mounted) {
                                  setState(
                                    () => risultato =
                                        'Rimozione ban non riuscita: $error',
                                  );
                                }
                              }
                            },
                          ),
                        ),
                    ],
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: const Text('Chiudi'),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, int> campaignQuickStats() {
    if (campaignQuickStatsCacheRevision == salvataggioMutazioneRevisione &&
        campaignQuickStatsCache != null) {
      return campaignQuickStatsCache!;
    }
    var diaryPages = 0;
    var partySheets = 0;
    for (int i = 0; i < schedePersonaggio.length; i++) {
      final sheet = schedaJsonAt(i);
      final diary = sheet['diarioPagine'];
      if (diary is List) diaryPages += diary.length;
      if (readBoolValue(sheet['inMasterParty'])) partySheets++;
    }

    final result = <String, int>{
      'sheets': schedePersonaggio.length,
      'party': partySheets,
      'diary': diaryPages,
    };
    campaignQuickStatsCacheRevision = salvataggioMutazioneRevisione;
    campaignQuickStatsCache = result;
    return result;
  }

  Widget campaignPanel() {
    ensureCampaignsReady();
    final stats = campaignQuickStats();
    const sheetPreviewLimit = 24;
    final previewCount = min(sheetPreviewLimit, schedePersonaggio.length);

    return gothicPanel(
      borderColor: tertiaryColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('Campagne', 'Campaigns'),
            style: TextStyle(
              color: tertiaryColor,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          smallInfoText(
            t(
              'Ogni campagna conserva le sue schede, i diari delle schede, il party e la vista rapida stats. Amici e nome utente restano globali.',
              'Each campaign keeps its sheets, sheet diaries, party and quick stats view. Friends and username stay global.',
            ),
          ),
          const SizedBox(height: 12),
          campoModello(
            label: t('Nome campagna attiva', 'Active campaign name'),
            initialValue: activeCampaignName(),
            onChanged: (value) {
              campaignNameController.text = value;
              saveActiveCampaignInMemory();
            },
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              campaignStatChip(
                t('Schede', 'Sheets'),
                '${stats['sheets'] ?? 0}',
              ),
              campaignStatChip('Party', '${stats['party'] ?? 0}'),
              campaignStatChip(t('Diari', 'Diaries'), '${stats['diary'] ?? 0}'),
            ],
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue:
                campagneOculum.any(
                  (x) => '${x['id'] ?? ''}' == activeCampaignId,
                )
                ? activeCampaignId
                : null,
            dropdownColor: const Color(0xFF11131A),
            decoration: fieldDecoration(t('Apri campagna', 'Open campaign')),
            items: campagneOculum
                .map(
                  (campaign) => DropdownMenuItem<String>(
                    value: '${campaign['id'] ?? ''}',
                    child: Text('${campaign['name'] ?? 'Campagna'}'),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) switchCampaign(value);
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: campoTesto(
                  label: t('Nuova campagna', 'New campaign'),
                  controller: newCampaignNameController,
                  numero: false,
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: createCampaign,
                icon: const Icon(Icons.add),
                label: Text(t('Crea', 'Create')),
              ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: moveCampaignSheets,
            icon: const Icon(Icons.drive_file_move_outline),
            label: Text(
              t('Sposta schede tra campagne', 'Move sheets between campaigns'),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: tertiaryColor,
              side: BorderSide(color: tertiaryColor.withValues(alpha: 0.65)),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: deleteActiveCampaignPermanently,
            icon: const Icon(Icons.delete_forever_outlined),
            label: Text(
              t(
                'Elimina campagna attiva per sempre',
                'Delete active campaign forever',
              ),
            ),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
          ),
          const SizedBox(height: 14),
          Text(
            t('Vista rapida stats', 'Quick stats view'),
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (int i = 0; i < previewCount; i++)
                campaignStatChip(
                  nomeSchedaPersonaggio(i),
                  'HP ${sheetIntValueAt(i, 'currentHp')}/${sheetMaxHpForDeathAt(i)} • OCU ${sheetIntValueAt(i, 'currentOculum')}',
                ),
            ],
          ),
          if (previewCount < schedePersonaggio.length) ...[
            const SizedBox(height: 8),
            smallInfoText(
              t(
                'Mostrate $previewCount di ${schedePersonaggio.length} schede per mantenere fluida la pagina Master. L’elenco completo è disponibile in Gestisci schede salvate.',
                'Showing $previewCount of ${schedePersonaggio.length} sheets to keep the Master page responsive. The full list is available in Manage saved sheets.',
              ),
              color: Colors.white54,
            ),
          ],
        ],
      ),
    );
  }

  Widget campaignStatChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF10121A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: primaryColor.withValues(alpha: 0.35)),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
