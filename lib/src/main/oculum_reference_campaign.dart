part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

extension _OculumReferenceCampaign on _OculumHomePageState {
  void selectReferenceRole(bool master) {
    setState(() {
      modalitaMaster = master;
      paginaCorrente = master ? 9 : 0;
      aggiungiLog(
        master ? 'Modalità Master attiva.' : 'Modalità Player attiva.',
      );
    });
    refreshRealtimeRolePresence();
    programmaSalvataggio();
  }

  Widget referenceHomePage() => SingleChildScrollView(
    key: sheetScrollKey('home'),
    padding: responsivePagePadding(),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 880),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            sectionTitle('Home'),
            Text(t('Benvenuto in Oculum', 'Welcome to Oculum')),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) => gothicPanel(
                padding: const EdgeInsets.all(8),
                child: OculumReferenceArt(
                  height: (constraints.maxWidth * .6).clamp(200, 440),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => selectReferenceRole(false),
                    icon: const Icon(Icons.person_outline),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xffc5d5ec),
                      backgroundColor: const Color(0xff101b2c),
                      side: const BorderSide(color: Color(0xff6485ad)),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                    label: const Text(
                      'PLAYER',
                      style: TextStyle(fontFamily: 'Georgia', fontSize: 21),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => selectReferenceRole(true),
                    icon: const Icon(Icons.admin_panel_settings_outlined),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xffeed7d1),
                      backgroundColor: const Color(0xff301416),
                      side: const BorderSide(color: Color(0xffa4625a)),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                    label: const Text(
                      'MASTER',
                      style: TextStyle(fontFamily: 'Georgia', fontSize: 21),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            gothicPanel(
              child: Row(
                children: [
                  const OculumMemoryEye(role: 'party', size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t('CAMPAGNA ATTIVA', 'ACTIVE CAMPAIGN'),
                          style: const TextStyle(fontSize: 10),
                        ),
                        Text(
                          activeCampaignName(),
                          style: const TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 20,
                          ),
                        ),
                        Text(
                          '${schedePersonaggio.length} ${t('schede', 'sheets')} · ${realtimeConnected ? 'Online' : 'Offline'}',
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () =>
                        vaiAllaFunzione(page: modalitaMaster ? 9 : 0),
                    child: Text(t('Continua', 'Continue')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget referenceSheetSideMenu(int page) {
    final entries = <(String, IconData, bool, VoidCallback)>[
      (
        t('Generale', 'General'),
        Icons.home_outlined,
        page == 0 && referenceSheetSection == 'general',
        () {
          referenceSheetSection = 'general';
          vaiAllaFunzione(page: 0);
        },
      ),
      (
        t('Statistiche', 'Stats'),
        Icons.insights_outlined,
        page == 0 && referenceSheetSection == 'statistics',
        () {
          vaiAllaFunzione(page: 0);
          setState(() {
            referenceSheetSection = 'statistics';
            referenceRequestedAnchor = '';
          });
        },
      ),
      (
        'Oculum Art',
        Icons.auto_awesome_outlined,
        page == 3,
        () => vaiAllaFunzione(page: 3),
      ),
      (
        t('Sottotratti', 'Subtraits'),
        Icons.account_tree_outlined,
        false,
        () => openReferenceDetail(
          t('Sottotratti', 'Subtraits'),
          'sheet_command_center',
          referenceSubtraitsPanel,
        ),
      ),
      (
        t('Inventario', 'Inventory'),
        Icons.inventory_2_outlined,
        page == 6,
        () => vaiAllaFunzione(page: 6),
      ),
      (
        t('Occhi', 'Eyes'),
        Icons.visibility_outlined,
        page == 16,
        () => vaiAllaFunzione(page: _OculumHomePageState.fallenEyesPageIndex),
      ),
      (
        t('Diario', 'Diary'),
        Icons.menu_book_outlined,
        page == 5,
        () => vaiAllaFunzione(page: 5),
      ),
      ('Resistenze', Icons.shield_outlined, false, openResistanceDetails),
    ];
    return Container(
      width: 142,
      decoration: const BoxDecoration(
        color: Color(0xff09090c),
        border: Border(right: BorderSide(color: Color(0xff594447))),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Text(
              nomeController.text.trim().isEmpty
                  ? 'Scheda'
                  : nomeController.text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Georgia',
                fontSize: 16,
                color: Color(0xffded5cb),
              ),
            ),
          ),
          for (final entry in entries)
            Material(
              color: entry.$3 ? const Color(0xff25161a) : Colors.transparent,
              child: InkWell(
                onTap: entry.$4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 13,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        entry.$2,
                        size: 16,
                        color: entry.$3
                            ? const Color(0xffd5a29a)
                            : const Color(0xffada69e),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.$1,
                          style: TextStyle(
                            fontSize: 11,
                            color: entry.$3
                                ? const Color(0xffeee3dc)
                                : const Color(0xffbcb5ae),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> openReferenceDetail(
    String title,
    String anchor,
    Widget Function() content,
  ) async {
    if (!mounted) return;
    if (anchor == 'sheet_dice' || anchor == 'sheet_dice_quick') {
      await openDiceInCurrentScreen();
      return;
    }
    final parentDetailActive = referenceDetailRouteActive;
    _expandedFunctionSections.add(anchor);
    if (anchor == 'sheet_editable_values') mostraValoriEditabiliScheda = true;
    referenceDetailRouteActive = true;
    void returnToGeneral() {
      if (!mounted) return;
      setState(() {
        referenceSheetSection = 'general';
        referenceRequestedAnchor = '';
      });
      Navigator.of(context).popUntil((route) => route.isFirst);
    }

    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          // Detail content reads the saved sheet and encounter state. Rebuild
          // covered details on return instead of retaining duplicate controls.
          maintainState: false,
          builder: (context) => CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.escape): returnToGeneral,
              const SingleActivator(LogicalKeyboardKey.keyF, control: true):
                  openOculumGlobalSearch,
              const SingleActivator(LogicalKeyboardKey.keyF, meta: true):
                  openOculumGlobalSearch,
            },
            child: Focus(
              autofocus: true,
              child: Scaffold(
                backgroundColor: backgroundBottomColor,
                appBar: AppBar(
                  title: Text(
                    title,
                    style: const TextStyle(fontFamily: 'Georgia'),
                  ),
                  backgroundColor: backgroundTopColor,
                ),
                body: ValueListenableBuilder<int>(
                  valueListenable: activeSheetSummaryRevision,
                  builder: (context, revision, child) => DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: campaignBackgroundMode == 'checker'
                          ? null
                          : oculumBackgroundGradient(campaignBackgroundMode, [
                              backgroundTopColor,
                              backgroundMidColor,
                              backgroundBottomColor,
                            ]),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (campaignBackgroundMode == 'checker')
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: OculumCheckerBackground(
                                  backgroundTopColor,
                                  backgroundBottomColor,
                                ),
                              ),
                            ),
                          ),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: returnToGeneral,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(14),
                            child: Center(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {},
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 820,
                                  ),
                                  child: functionAnchor(anchor, content()),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } finally {
      referenceDetailRouteActive =
          parentDetailActive && mounted && Navigator.of(context).canPop();
      referenceDetailRouteQueued = false;
      referenceRequestedAnchor = '';
    }
  }

  Widget referenceDetailTile(
    String title,
    String anchor,
    IconData icon,
    Widget Function() content, {
    bool requested = false,
  }) {
    if (requested &&
        !referenceDetailRouteActive &&
        !referenceDetailRouteQueued) {
      referenceDetailRouteQueued = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(openReferenceDetail(title, anchor, content));
      });
    }
    return SizedBox(
      width: min(270.0, MediaQuery.sizeOf(context).width - 32),
      child: Material(
        color: const Color(0xff0e0e12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
          side: const BorderSide(color: Color(0xff594447)),
        ),
        child: InkWell(
          onTap: () => openReferenceDetail(title, anchor, content),
          borderRadius: BorderRadius.circular(5),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Icon(icon, size: 17, color: const Color(0xffb79386)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xffe6ddd4),
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 17,
                  color: Color(0xffb79386),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget referenceDiaryPage() {
    final builders = <WidgetBuilder>[
      (_) => functionAnchor(
        'story_root',
        sectionTitle(t('Diari e Mappa', 'Diaries and Map')),
      ),
      (_) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final tab in [
            ('diaries', t('Diari', 'Diaries')),
            ('map', t('Mappa', 'Map')),
            ('links', t('Collegamenti', 'Links')),
          ])
            ChoiceChip(
              label: Text(tab.$2),
              selected: referenceStoryTab == tab.$1,
              onSelected: (_) => setState(() => referenceStoryTab = tab.$1),
            ),
          IconButton(
            tooltip: t('Mappa degli Occhi completa', 'Full Eyes Map'),
            onPressed: () => openEyeMemory(campaign: haPermessiMaster),
            icon: const OculumMemoryEye(role: 'party', size: 32),
          ),
        ],
      ),
      if (referenceStoryTab != 'diaries') (_) => storyConstellationPanel(),
      if (referenceStoryTab == 'map')
        (_) => OutlinedButton.icon(
          onPressed: () =>
              vaiAllaFunzione(page: _OculumHomePageState.mapPageIndex),
          icon: const Icon(Icons.map_outlined),
          label: Text(t('Apri mappa dei luoghi', 'Open location map')),
        ),
      if (referenceStoryTab == 'links')
        (_) {
          final linked = diaryEntitiesFromLinks([
            for (final entry in journalEntries) entry.description,
            ...diarioPagine,
          ]);
          return gothicPanel(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entity in linked)
                  ActionChip(
                    label: Text(entity.name),
                    avatar: OculumMemoryEye(
                      role: diaryRoleLedger.roleOf(entity),
                      size: 22,
                    ),
                    onPressed: () => openEyeMemory(campaign: haPermessiMaster),
                  ),
                if (linked.isEmpty)
                  Text(
                    t(
                      'Collega un nome nel diario con [[ per ritrovarlo qui.',
                      'Link a name in your diary with [[ to find it here.',
                    ),
                  ),
              ],
            ),
          );
        },
      if (referenceStoryTab == 'diaries') ...[
        (_) => gothicPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t('La memoria della tua campagna', 'Your campaign memory'),
                style: const TextStyle(fontFamily: 'Georgia', fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                t(
                  'Scrivi [[ per collegare un nome. Ogni ricordo conserva la sua fonte.',
                  'Type [[ to link a name. Every memory keeps its source.',
                ),
              ),
              Wrap(
                spacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: aggiungiVoceDatabaseDiario,
                    icon: const Icon(Icons.edit_note),
                    label: Text(t('Nuova nota', 'New note')),
                  ),
                  TextButton.icon(
                    onPressed: aggiungiPaginaDiario,
                    icon: const Icon(Icons.auto_stories_outlined),
                    label: Text(t('Pagina con ricompensa', 'Rewarded page')),
                  ),
                ],
              ),
            ],
          ),
        ),
        for (var i = 0; i < journalEntries.length; i++)
          (_) => RepaintBoundary(
            key: ValueKey('diary_tile_${currentSheetScrollId()}_$i'),
            child: storyDiaryDatabaseTile(i),
          ),
        (_) => Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            referenceDetailTile(
              t('Background e note', 'Background and notes'),
              'story_background',
              Icons.history_edu_outlined,
              storyBackgroundPanelEfficient,
            ),
            if (modalitaMaster)
              referenceDetailTile(
                t('Note del Master', 'Master notes'),
                'story_master',
                Icons.auto_stories_outlined,
                storyMasterPanelEfficient,
              ),
          ],
        ),
        (_) => storyOnlineSessionNotesPanel(),
      ],
    ];
    return responsivePageBuilder(
      pageKey: 'story',
      builders: builders,
      fullWidthIndexes: const {0, 1},
      maxColumns: 2,
      minColumnWidth: 340,
      cacheExtent: 420,
    );
  }

  int referenceStatMaximum(String key) => switch (key) {
    'resilienza' => resilienzaMassimoNaturale(),
    'volonta' => volontaMassimoNaturale(),
    'materia' => materiaMassimoNaturale(),
    _ => oculumMassimoNaturale(),
  };
  bool get referenceCampaignStyle =>
      !manuscriptLivingActive &&
      !temiOldSchool &&
      nuovoDesignOculum == 'cattedrale';

  Widget referenceBackgroundSelector() => gothicPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionTitle(t('Disegno dello sfondo', 'Background pattern')),
        DropdownButtonFormField<String>(
          initialValue: campaignBackgroundMode,
          isExpanded: true,
          decoration: fieldDecoration(
            t('Sfumatura o scacchi', 'Gradient or checkerboard'),
          ),
          items: [
            for (final mode in oculumBackgroundModes.entries)
              DropdownMenuItem(value: mode.key, child: Text(mode.value)),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() => campaignBackgroundMode = value);
            programmaSalvataggio();
          },
        ),
        const SizedBox(height: 8),
        Text(
          t(
            'Le sfumature usano i colori alto, centro e basso. Gli scacchi usano alto e basso: scegli i due colori qui sotto.',
            'Gradients use top, middle and bottom colors. Checkerboard uses top and bottom: choose both colors below.',
          ),
        ),
      ],
    ),
  );

  Widget referenceStatisticsEditor() => gothicPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionTitle(
          t('Statistiche · massimale e attuale', 'Stats · maximum and current'),
        ),
        Text(
          t(
            'Massimale e attuale sono separati. Modificare il massimale regola la statistica base, conservando i bonus attivi; non recupera i punti spesi.',
            'Maximum and current are separate. Editing maximum adjusts the base stat and preserves active bonuses; it does not restore spent points.',
          ),
        ),
        const SizedBox(height: 12),
        for (final entry in <(String, String, TextEditingController)>[
          ('resilienza', t('Resilienza', 'Resilience'), resilienzaController),
          ('volonta', t('Volontà', 'Will'), volontaController),
          ('materia', t('Materia', 'Matter'), materiaController),
          ('oculum', 'Oculum', oculumController),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.$2,
                  style: TextStyle(
                    color: statFormulaColor(entry.$1),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: campoModello(
                        label: t('Massimale', 'Maximum'),
                        fieldKey: ValueKey(
                          'reference_max_${currentSheetScrollId()}_${entry.$1}',
                        ),
                        initialValue: '${referenceStatMaximum(entry.$1)}',
                        keyboardType: TextInputType.number,
                        enableCommandAutocomplete: false,
                        liveRefresh: true,
                        onChanged: (text) {
                          final wanted = int.tryParse(text);
                          if (wanted == null || wanted < 0) return;
                          final base = readIntValue(entry.$3.text);
                          entry.$3.text = max(
                            0,
                            base + wanted - referenceStatMaximum(entry.$1),
                          ).toString();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: campoStatAttualeVisibile(
                        label: t('Attuale', 'Current'),
                        key: entry.$1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        if (!vitaAfonaAttiva()) ...[
          Text(
            t('Vita', 'Health'),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          Row(
            children: [
              Expanded(
                child: campoModello(
                  label: t('Massimale Vita', 'Maximum HP'),
                  fieldKey: ValueKey(
                    'reference_hp_max_${currentSheetScrollId()}',
                  ),
                  initialValue: '${maxHp()}',
                  keyboardType: TextInputType.number,
                  enableCommandAutocomplete: false,
                  liveRefresh: true,
                  onChanged: (text) {
                    final wanted = int.tryParse(text);
                    if (wanted == null || wanted < 1) return;
                    manualHpMaximumAdjustment += wanted - maxHp();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: campoTesto(
                  label: t('Vita attuale', 'Current HP'),
                  controller: currentHpController,
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: () {
              setState(() => manualHpMaximumAdjustment = 0);
              programmaSalvataggio();
            },
            child: Text(
              t('Ripristina massimale automatico', 'Restore automatic maximum'),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          t('Scudo Oculum', 'Oculum shield'),
          style: TextStyle(
            color: eyePupilGlowColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: compactScudoOculumMaxEditField()),
            const SizedBox(width: 8),
            Expanded(child: compactScudoOculumEditField()),
          ],
        ),
        const SizedBox(height: 12),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: compactNumericEditField(
              label: t('Scudo · attuale', 'Shield · current'),
              controller: scudoController,
              displayValue: '${scudo()}',
              color: const Color(0xFF44A7FF),
              onSaved: () => impostaScudoTotale(
                max(0, readIntValue(scudoController.text)),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Future<void> donateReferenceItem(InventoryItem item) async {
    final owner = sheetTagAt(schedaCorrente);
    final targets = [
      for (var i = 0; i < schedePersonaggio.length; i++)
        if (i != schedaCorrente &&
            (haPermessiMaster ||
                schedePersonaggio[i]['realtimeSharedSheet'] != true))
          i,
    ];
    if (targets.isEmpty) {
      setState(
        () => risultato = t(
          'Aggiungi o importa la scheda del destinatario prima di donare.',
          'Add or import the recipient sheet before donating.',
        ),
      );
      return;
    }
    var target = targets.first;
    var amount = 1;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text('Dona ${item.nome}'),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: target,
                  isExpanded: true,
                  decoration: fieldDecoration(t('Destinatario', 'Recipient')),
                  items: [
                    for (final i in targets)
                      DropdownMenuItem(
                        value: i,
                        child: Text(
                          nomeSchedaPersonaggio(i),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (i) {
                    if (i != null) update(() => target = i);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: '1',
                  keyboardType: TextInputType.number,
                  decoration: fieldDecoration(
                    '${t('Quantità disponibile', 'Available quantity')}: ${item.quantita}',
                  ),
                  onChanged: (value) =>
                      update(() => amount = int.tryParse(value) ?? 0),
                ),
                const SizedBox(height: 8),
                Text(
                  t(
                    'Gli oggetti donati vengono rimossi dal tuo inventario.',
                    'Donated items are removed from your inventory.',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(t('Annulla', 'Cancel')),
            ),
            FilledButton(
              onPressed: amount > 0 && amount <= item.quantita
                  ? () => Navigator.pop(context, true)
                  : null,
              child: Text(t('Dona', 'Give')),
            ),
          ],
        ),
      ),
    );
    if (accepted != true ||
        !mounted ||
        owner != sheetTagAt(schedaCorrente) ||
        !inventario.contains(item) ||
        target >= schedePersonaggio.length ||
        amount > item.quantita) {
      return;
    }
    final gift = copiaOggetto(item)
      ..quantita = amount
      ..equipaggiata = false;
    setState(() {
      final destination = schedePersonaggio[target];
      final raw = _updatedRawList(destination, 'inventario')
        ..add(gift.toJson());
      destination['inventario'] = raw;
      if (destination['realtimeSharedSheet'] == true) {
        destination['realtimeDirtyLocal'] = true;
        destination['realtimeDirtyAt'] = DateTime.now().toIso8601String();
      }
      item.quantita -= amount;
      if (item.quantita == 0) {
        if (item.equipaggiata) applicaScudoItemAttuale(item, -1);
        inventario.remove(item);
        referenceSelectedItem = null;
      }
      aggiungiLog(
        'Donati $amount × ${gift.nome} a ${nomeSchedaPersonaggio(target)}.',
      );
    });
    await salvaDati();
    if (realtimeIsMasterRole) unawaited(drainRealtimeDirtySheets());
  }

  Widget referenceInventoryPage() {
    final selected = inventario.contains(referenceSelectedItem)
        ? referenceSelectedItem
        : null;
    return CustomScrollView(
      key: sheetScrollKey('inventory'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverPadding(
          padding: responsivePagePadding(),
          sliver: SliverList.list(
            children: [
              functionAnchor(
                'inventory_root',
                sectionTitle(
                  t('Inventario e crafting', 'Inventory and crafting'),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: showMerchantDialog,
                    icon: const Icon(Icons.storefront),
                    label: Text(t('Mercato', 'Market')),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => vaiAllaFunzione(
                      page: _OculumHomePageState.recipesPageIndex,
                    ),
                    icon: const Icon(Icons.handyman),
                    label: Text(t('Ricette', 'Recipes')),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (haPermessiMaster)
                masterItemGiftPanel(initiallyExpanded: true),
              pawnGuardiansPanel(),
              if (inventario.isEmpty)
                Text(
                  t(
                    'Il tuo inventario è vuoto. Aggiungi un oggetto o visita il mercato.',
                    'Your inventory is empty. Add an item or visit the market.',
                  ),
                ),
              merchantQuickPanel(),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          sliver: SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 116,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: .94,
            ),
            itemCount: inventario.length,
            itemBuilder: (context, i) {
              final item = inventario[i];
              return Tooltip(
                message: item.nome,
                child: Material(
                  color: const Color(0xff101116),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                    side: BorderSide(
                      color: identical(item, selected)
                          ? tertiaryColor
                          : primaryColor.withValues(alpha: .25),
                    ),
                  ),
                  child: InkWell(
                    onTap: () => setState(() => referenceSelectedItem = item),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          Expanded(
                            child: Icon(
                              item.arma
                                  ? Icons.gavel
                                  : item.protegge
                                  ? Icons.shield
                                  : isMerchantConsumable(item)
                                  ? Icons.science_outlined
                                  : Icons.diamond_outlined,
                              color: item.equipaggiata
                                  ? tertiaryColor
                                  : primaryColor,
                              size: 32,
                            ),
                          ),
                          Text(
                            item.nome,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11),
                          ),
                          Text(
                            '×${item.quantita}',
                            style: TextStyle(
                              color: tertiaryColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SliverPadding(
          padding: responsivePagePadding(),
          sliver: SliverList.list(
            children: [
              if (selected != null) ...[
                gothicPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      sectionTitle(selected.nome),
                      if (selected.note.isNotEmpty) Text(selected.note),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (isMerchantConsumable(selected))
                            FilledButton(
                              onPressed: () => useMerchantConsumable(selected),
                              child: Text(t('Usa', 'Use')),
                            ),
                          OutlinedButton(
                            onPressed: () => donateReferenceItem(selected),
                            child: Text(t('Dona', 'Give')),
                          ),
                          OutlinedButton(
                            onPressed: merchantIsOpen
                                ? () => sellInventoryItemToMerchant(selected)
                                : null,
                            child: Text(
                              '${t('Vendi', 'Sell')} · ${merchantSaleValue(selected)} Obser',
                            ),
                          ),
                          if (!merchantIsOpen)
                            TextButton(
                              onPressed: showMerchantDialog,
                              child: Text(
                                t(
                                  'Apri il mercato per vendere',
                                  'Open market to sell',
                                ),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        t(
                          'La vendita usa il prezzo ridotto del Negoziante.',
                          'Selling uses the merchant’s reduced price.',
                        ),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                inventoryItemCardEfficient(inventario.indexOf(selected)),
              ],
              inventoryAddItemPanelEfficient(),
              dropdownSection(
                title: t('Capacità e comandi', 'Capacity and commands'),
                sectionId: 'reference_inventory_capacity',
                borderColor: tertiaryColor,
                icon: Icons.scale,
                child: Column(
                  children: [
                    inventoryCapacityPanelEfficient(),
                    inventoryQuickDropdownPanel(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget referenceEncounterPanel({
    required List<Map<String, dynamic>> tokens,
    required int activeIndex,
    bool master = false,
  }) {
    final shown = tokens
        .map((token) {
          final copy = Map<String, dynamic>.from(token);
          final type = '${copy['type'] ?? ''}'.toLowerCase();
          if (copy['side'] == 'enemy' || type.contains('mostro')) {
            copy['spriteAssetPath'] = '';
          }
          if (!master) {
            final local = encounterPlayerIdentities['${token['id']}'];
            if (local != null) copy.addAll(local);
          }
          return copy;
        })
        .toList(growable: false);
    final events = logEventi
        .where(
          (event) =>
              event.contains('[MORTE]') ||
              event.contains('[DADO]') ||
              event.contains('Tiro ') ||
              RegExp(
                r'\b\d*d(?:20|60|100|120)\b',
                caseSensitive: false,
              ).hasMatch(event) ||
              event.contains('🎲'),
        )
        .take(60)
        .toList(growable: false);
    return gothicPanel(
      child: Column(
        children: [
          const OculumReferenceArt(combat: true, height: 96),
          const SizedBox(height: 12),
          OculumEncounterStage(
            key: ValueKey(
              'encounter_stage_${master ? selectedMasterInitiativeGroupId : activeCampaignId}',
            ),
            tokens: shown,
            activeIndex: activeIndex,
            accent: tertiaryColor,
            events: events,
            onNextTurn: master ? () => nextMasterInitiativeTurn() : null,
            onIdentify: master ? null : identifyEncounterParticipant,
            onReveal: master ? revealEncounterParticipant : null,
            portraitBuilder: (token) =>
                '${token['imageBase64'] ?? ''}'.isEmpty &&
                    '${token['spriteAssetPath'] ?? ''}'.isEmpty
                ? const Center(
                    child: Text(
                      '?',
                      style: TextStyle(fontSize: 32, color: Color(0xffb5a390)),
                    ),
                  )
                : FittedBox(
                    fit: BoxFit.cover,
                    child: initiativeTokenAvatar(token),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> identifyEncounterParticipant(Map<String, dynamic> token) async {
    final owner = sheetTagAt(schedaCorrente);
    final id = '${token['id']}';
    final name = TextEditingController(
      text: token['name'] == '???' ? '' : '${token['name']}',
    );
    String? image;
    try {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, update) => AlertDialog(
            title: Text(t('Identifica partecipante', 'Identify participant')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: fieldDecoration(
                    t('Nome conosciuto', 'Known name'),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final file = await _picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (file == null) return;
                    final bytes = await file.readAsBytes();
                    if (!context.mounted) return;
                    update(() => image = base64Encode(bytes));
                  },
                  icon: const Icon(Icons.image_outlined),
                  label: Text(
                    image == null
                        ? t('Scegli immagine', 'Choose image')
                        : t('Immagine scelta', 'Image selected'),
                  ),
                ),
                Text(
                  t(
                    'Queste informazioni rimangono nella tua memoria personale.',
                    'These details remain in your personal memory.',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(t('Annulla', 'Cancel')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(t('Salva', 'Save')),
              ),
            ],
          ),
        ),
      );
      if (accepted != true || !mounted || owner != sheetTagAt(schedaCorrente)) {
        return;
      }
      setState(() {
        encounterPlayerIdentities[id] = {
          ...?encounterPlayerIdentities[id],
          if (name.text.trim().isNotEmpty) 'name': name.text.trim(),
          'imageBase64': ?image,
        };
      });
      programmaSalvataggio();
    } finally {
      name.dispose();
    }
  }

  Future<void> revealEncounterParticipant(
    Map<String, dynamic> displayed,
  ) async {
    if (!canActWithoutMasterApproval) return;
    final i = masterInitiativeTokens.indexWhere(
      (token) => token['id'] == displayed['id'],
    );
    if (i < 0) return;
    final token = masterInitiativeTokens[i];
    var nameVisible = token['nameRevealed'] == true;
    var blindVisible = token['blindSpotDiscovered'] == true;
    final sheet = localSheetIndexForOculumTag(
      '${token['sheetTag'] ?? token['id']}',
    );
    final point = sheet < 0
        ? '${token['discoveredBlindSpot'] ?? ''}'
        : '${masterBlindSpots['$activeCampaignId:${sheetTagAt(sheet)}']?['name'] ?? ''}';
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text(t('Informazioni scoperte', 'Discovered details')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                value: nameVisible,
                onChanged: (value) => update(() => nameVisible = value),
                title: Text(t('Nome noto ai Player', 'Name known to players')),
              ),
              SwitchListTile(
                value: blindVisible,
                onChanged: point.isEmpty
                    ? null
                    : (value) => update(() => blindVisible = value),
                title: Text(t('Punto Cieco scoperto', 'Blind spot discovered')),
                subtitle: Text(
                  point.isEmpty
                      ? t(
                          'Definisci prima il Punto Cieco nei controlli Master.',
                          'Define the blind spot in Master controls first.',
                        )
                      : point,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(t('Annulla', 'Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(t('Condividi', 'Share')),
            ),
          ],
        ),
      ),
    );
    if (accepted != true ||
        !mounted ||
        !masterInitiativeTokens.contains(token)) {
      return;
    }
    setState(() {
      token['nameRevealed'] = nameVisible;
      token['blindSpotDiscovered'] = blindVisible;
      token['discoveredBlindSpot'] = blindVisible ? point : '';
    });
    programmaSalvataggio();
    sendRealtimeInitiativeSnapshotIfPublished();
  }
}
