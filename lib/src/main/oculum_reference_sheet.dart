part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

extension _OculumReferenceSheet on _OculumHomePageState {
  Widget referenceCombatDetails() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      gothicPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionTitle(
              t('Attacco, difesa e bonus', 'Attack, defense and bonuses'),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in <(String, int, IconData)>[
                  ('VC', vc(), Icons.flash_on),
                  ('CM', cm(), Icons.shield_outlined),
                  (
                    t('Danni inflitti', 'Damage dealt'),
                    dannoTotale(),
                    Icons.sports_martial_arts,
                  ),
                  (t('Difesa', 'Defense'), difesa(), Icons.security),
                ])
                  OutlinedButton.icon(
                    onPressed: () => tiraValoreSpeciale(
                      entry.$1,
                      entry.$2,
                      applyGlobalRollModifier: false,
                    ),
                    icon: Icon(entry.$3),
                    label: Text('${entry.$1}: ${entry.$2}'),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            for (final entry in <(String, TextEditingController)>[
              ('Bonus danno', attaccoRapidoController),
              ('Bonus VC', vcRapidoController),
              ('Bonus CM', cmRapidoController),
              ('Bonus difesa', difesaRapidaController),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: campoTesto(label: entry.$1, controller: entry.$2),
              ),
          ],
        ),
      ),
      combatOverviewPanel(dense: false),
    ],
  );

  Widget referenceTurnControls() {
    final remote =
        !haPermessiMaster &&
        realtimeService?.isConnected == true &&
        realtimeVisibleInitiativeSnapshot['tokens'] is List;
    final hasFight = remote
        ? (realtimeVisibleInitiativeSnapshot['tokens'] as List).isNotEmpty
        : masterInitiativeTokens.isNotEmpty;
    final round = remote
        ? readIntValue(realtimeVisibleInitiativeSnapshot['round'], fallback: 0)
        : masterInitiativeRound;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xff14212e),
        border: Border.all(color: const Color(0xff51718f)),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          IconButton(
            tooltip: remote
                ? 'Il Master gestisce il turno'
                : 'Turno precedente',
            visualDensity: VisualDensity.compact,
            onPressed: remote
                ? null
                : () => hasFight
                      ? nextMasterInitiativeTurn(delta: -1)
                      : setPlayerReportedTurn(playerReportedTurn - 1),
            icon: const Icon(Icons.chevron_left),
          ),
          turnResetGesture(
            Text(
              hasFight
                  ? 'Round $round · Tuo turno $playerReportedTurn'
                  : 'Turno $playerReportedTurn',
            ),
          ),
          IconButton(
            tooltip: remote
                ? 'Il Master gestisce il turno'
                : 'Turno successivo',
            visualDensity: VisualDensity.compact,
            onPressed: remote
                ? null
                : () => hasFight
                      ? nextMasterInitiativeTurn()
                      : setPlayerReportedTurn(playerReportedTurn + 1),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget referenceSubtraitsPanel() => ValueListenableBuilder<int>(
    valueListenable: activeSheetSummaryRevision,
    builder: (context, revision, child) => gothicPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionTitle(t('Sottotratti', 'Subtraits')),
          if (oculumStarterSubtraitPointsRemaining(
                appliedTutorialSubtraitPoints,
              ) >
              0)
            OutlinedButton.icon(
              onPressed: showStarterSubtraitPointsDialog,
              icon: const Icon(Icons.add_circle_outline),
              label: Text(
                'Punti iniziali disponibili: ${oculumStarterSubtraitPointsRemaining(appliedTutorialSubtraitPoints)} · massimo 3 per sottotratto',
              ),
            ),
          if (assignableSubtraitPoints > 0) ...[
            Text('Punti da assegnare: $assignableSubtraitPoints'),
            for (final stat in hiddenEyeStats.where((s) => s.id != 'fortuna'))
              ListTile(
                title: Text(stat.nome),
                trailing: IconButton(
                  tooltip: 'Assegna un punto',
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    setState(() {
                      stat.valore++;
                      assignableSubtraitPoints--;
                    });
                    notifyHiddenEyeStatChanged(stat);
                    programmaSalvataggio();
                    notifyActiveSheetSummaryChanged();
                  },
                ),
              ),
          ],
          if (haPermessiMaster)
            TextButton.icon(
              onPressed: () async {
                final controller = TextEditingController(text: '0');
                final amount = await showDialog<int>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Assegna punti sottotratti'),
                    content: TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Punti concessi dal Master',
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Annulla'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(
                          ctx,
                          max(0, readIntValue(controller.text)),
                        ),
                        child: const Text('Aggiungi'),
                      ),
                    ],
                  ),
                );
                if (amount != null && mounted) {
                  setState(() => assignableSubtraitPoints += amount);
                  programmaSalvataggio();
                  notifyActiveSheetSummaryChanged();
                }
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => controller.dispose(),
                );
              },
              icon: const Icon(Icons.stars_outlined),
              label: const Text('Concedi punti'),
            ),

          for (final group in [
            'resilienza',
            'volonta',
            'materia',
            'oculum',
            'altro',
          ]) ...[
            if (hiddenEyeStats.any(
              (stat) => hiddenEyeStatGroup(stat.id) == group,
            ))
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Text(
                  hiddenEyeGroupLabel(group),
                  style: TextStyle(
                    color: statFormulaColor(group),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final stat in hiddenEyeStats.where(
                  (stat) => hiddenEyeStatGroup(stat.id) == group,
                ))
                  Tooltip(
                    waitDuration: const Duration(milliseconds: 450),
                    constraints: BoxConstraints(
                      maxWidth: min(360, MediaQuery.sizeOf(context).width - 32),
                    ),
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xff19131b), Color(0xff0b0a0e)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: statFormulaColor(group).withValues(alpha: .72),
                      ),
                      boxShadow: const [
                        BoxShadow(color: Colors.black87, blurRadius: 16),
                      ],
                    ),
                    textStyle: const TextStyle(
                      fontFamily: 'Poppins',
                      color: Color(0xffeadfc8),
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                    richMessage: TextSpan(
                      children: [
                        TextSpan(
                          text: '${stat.nome} — A cosa serve\n',
                          style: TextStyle(
                            color: statFormulaColor(group),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text:
                              '${stat.descrizione.split('Bonus:').first.trim()}\n\n',
                        ),
                        const TextSpan(
                          text: 'Formula\n',
                          style: TextStyle(
                            color: Color(0xffcda86c),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(text: subtraitFormulaHelp(stat)),
                      ],
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xff100f13),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: statFormulaColor(group).withValues(alpha: .62),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: statFormulaColor(
                              group,
                            ).withValues(alpha: .10),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          minimumSize: const Size(0, 34),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () => tiraSottotrattoOcchio(stat),
                        child: Text(
                          '${stat.nome} · ${hiddenEyeTotal(stat) >= 0 ? '+' : ''}${hiddenEyeTotal(stat)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    ),
  );

  Widget referenceCharacterPage() {
    final requested = referenceRequestedAnchor;
    String groupFor(String anchor) => switch (anchor) {
      'sheet_image' => 'portrait',
      'sheet_identity' => 'identity',
      'sheet_subtraits' => 'subtraits',
      'sheet_initiative' => 'initiative',
      'sheet_race' => 'race',
      'sheet_exp' => 'experience',
      'sheet_party' => 'party',
      'sheet_command_center' => 'commands',
      'sheet_combat_values' => 'combat',
      'sheet_values' => 'values',
      'sheet_stats' => 'stats',
      _ when anchor.startsWith('sheet_editable') => 'editable',
      _
          when anchor.startsWith('sheet_hp') ||
              anchor.startsWith('sheet_shield') =>
        'health',
      _
          when anchor.startsWith('sheet_damage') ||
              anchor.startsWith('sheet_heal') =>
        'damage',
      _
          when anchor.startsWith('sheet_attack') ||
              anchor.startsWith('sheet_defense') =>
        'combat',
      _ => '',
    };
    Widget fold(
      String id,
      String label,
      String anchor,
      IconData icon,
      Widget Function() content,
    ) => (id == 'editable' && !requested.startsWith('sheet_editable'))
        ? const SizedBox.shrink()
        : (referenceSheetSection == 'statistics' &&
                      !{
                        'stats',
                        'editable',
                        'health',
                        'oculum',
                        'values',
                      }.contains(id) ||
                  referenceSheetSection == 'general' &&
                      {'stats', 'values', 'editable'}.contains(id)) &&
              groupFor(requested) != id
        ? const SizedBox.shrink()
        : referenceDetailTile(
            label,
            anchor,
            icon,
            content,
            requested: groupFor(requested) == id,
          );
    Widget meter(
      String name,
      String label,
      int current,
      int maximum,
      Color color, {
      bool hidden = false,
    }) => Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(name)),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 5),
          if (!hidden)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: maximum > 0 ? (current / maximum).clamp(0.0, 1.0) : 0,
                minHeight: 8,
                color: color,
                backgroundColor: color.withValues(alpha: .15),
              ),
            ),
        ],
      ),
    );
    final hero = gothicPanel(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 500;
          final portrait = SizedBox(
            width: compact ? 86 : 136,
            height: compact ? 112 : 160,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: tertiaryColor.withValues(alpha: .65)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: GestureDetector(
                  onTap: () => openReferenceDetail(
                    t('Ritratto e Occhio', 'Portrait and Eye'),
                    'sheet_image',
                    oculumEyeBox,
                  ),
                  onLongPress: immaginePersonaggio == null
                      ? null
                      : mostraAzioniImmaginePersonaggio,
                  onSecondaryTap: immaginePersonaggio == null
                      ? null
                      : copiaImmaginePersonaggioNegliAppunti,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (portraitShowEyeBehind)
                        Center(
                          child: Image.asset(
                            oculumMemoryEyeAsset(portraitEyeRole) ??
                                'assets/icon/oculum_eye.png',
                            width: compact ? 72 : 112,
                          ),
                        ),
                      if (immaginePersonaggio != null)
                        Image.memory(
                          immaginePersonaggio!,
                          fit: BoxFit.contain,
                          cacheWidth: 320,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              portrait,
              SizedBox(width: compact ? 12 : 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            nomeController.text.trim().isEmpty
                                ? t('Il tuo personaggio', 'Your character')
                                : nomeController.text,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: compact ? 22 : 30,
                              fontFamily: 'serif',
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => vaiAllaFunzione(
                            page: 0,
                            anchorId: 'sheet_identity',
                          ),
                          child: Text(t('Modifica', 'Edit')),
                        ),
                      ],
                    ),
                    Text(
                      '${tipoSchedaPersonaggio(schedaCorrente)} · ${t('Livello', 'Level')} ${leggiNumero(livelloController)} · ${t('Grado', 'Grade')} ${leggiNumero(gradoController)}',
                      style: TextStyle(
                        color: primaryColor.withValues(alpha: .72),
                        fontSize: 12,
                      ),
                    ),
                    meter(
                      t('Vita', 'HP'),
                      hpReadoutProtetto(),
                      hpCorrenti(),
                      maxHp(),
                      statFormulaColor('resilienza'),
                      hidden: vitaAfonaAttiva(),
                    ),
                    if (referenceOculumFlames) referenceOculumFlameBar(),
                    if (!referenceOculumFlames)
                      meter(
                        'Oculum',
                        '${oculumTotale()}/${oculumDisplayMassimo()}',
                        oculumTotale(),
                        oculumDisplayMassimo(),
                        statFormulaColor('oculum'),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
    return SingleChildScrollView(
      key: sheetScrollKey('sheet'),
      padding: responsivePagePadding(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!modalitaDesktop || phoneCompactUi)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final section in [
                    ('general', t('Generale', 'General')),
                    ('statistics', t('Statistiche', 'Statistics')),
                  ])
                    ChoiceChip(
                      label: Text(section.$2),
                      selected: referenceSheetSection == section.$1,
                      onSelected: (_) => setState(() {
                        referenceSheetSection = section.$1;
                        referenceRequestedAnchor = '';
                      }),
                    ),
                  TextButton.icon(
                    onPressed: () => vaiAllaFunzione(page: 3),
                    icon: const Icon(Icons.auto_awesome_outlined),
                    label: const Text('Oculum Art'),
                  ),
                  TextButton.icon(
                    onPressed: () => vaiAllaFunzione(page: 6),
                    icon: const Icon(Icons.inventory_2_outlined),
                    label: Text(t('Inventario', 'Inventory')),
                  ),
                  TextButton.icon(
                    onPressed: () => vaiAllaFunzione(page: 5),
                    icon: const Icon(Icons.menu_book_outlined),
                    label: Text(t('Diario', 'Diary')),
                  ),
                  TextButton.icon(
                    onPressed: openResistanceDetails,
                    icon: const Icon(Icons.shield_outlined),
                    label: const Text('Resistenze'),
                  ),
                ],
              ),
            ),
          hero,
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                setState(() => referenceOculumFlames = !referenceOculumFlames);
                programmaSalvataggio();
              },
              icon: Icon(
                referenceOculumFlames
                    ? Icons.view_agenda_outlined
                    : Icons.local_fire_department_outlined,
                size: 16,
              ),
              label: Text(
                referenceOculumFlames
                    ? t('Oculum: usa la barra', 'Oculum: use the bar')
                    : t('Oculum: usa le fiammelle', 'Oculum: use the flames'),
              ),
            ),
          ),
          referenceStatStrip(),
          if (referenceSheetSection == 'statistics')
            referenceStatisticsEditor(),
          if (referenceSheetSection == 'general')
            gothicPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        t('Tiri e azioni', 'Rolls and actions'),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: tertiaryColor,
                        ),
                      ),
                      referenceTurnControls(),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xff491c24),
                          foregroundColor: const Color(0xffffddd4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                            side: const BorderSide(color: Color(0xffad5559)),
                          ),
                        ),
                        onPressed: () => tiraValoreSpeciale(
                          'VC',
                          vc(),
                          applyGlobalRollModifier: false,
                        ),
                        icon: const Icon(Icons.casino_outlined),
                        label: Text('VC ${vc()} · ${t('Attacco', 'Attack')}'),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xff142a40),
                          foregroundColor: const Color(0xffd6eaff),
                          side: const BorderSide(color: Color(0xff517dab)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        onPressed: () => tiraValoreSpeciale(
                          'CM',
                          cm(),
                          applyGlobalRollModifier: false,
                        ),
                        icon: const Icon(Icons.shield_outlined),
                        label: Text('CM ${cm()} · ${t('Difesa', 'Defense')}'),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: eyePupilGlowColor.withValues(
                            alpha: .12,
                          ),
                          foregroundColor: eyePupilGlowColor,
                          side: BorderSide(
                            color: eyePupilGlowColor.withValues(alpha: .72),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        onPressed: mostraMenuSchivataOculum,
                        icon: const Icon(Icons.visibility_outlined),
                        label: Text(
                          '${t('Schivata', 'Dodge')} ${schivateOculumDisponibili()}/${schivateOculumTotali()}',
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: tiraAiutaCompagno,
                        icon: const Icon(Icons.volunteer_activism_outlined),
                        label: Text(t('Aiuta compagno', 'Help ally')),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => apriDannoCuraDalCentroPartita(),
                        icon: const Icon(Icons.favorite_outline),
                        label: Text(
                          t('Danni subiti e cura', 'Damage taken and healing'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${t('Danni inflitti', 'Damage dealt')}: ${dannoTotale()} · ${t('I Sottotratti sono tiri alternativi', 'Subtraits are alternative rolls')}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          if (referenceSheetSection == 'general')
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                fold(
                  'subtraits',
                  t('Sottotratti', 'Subtraits'),
                  'sheet_subtraits',
                  Icons.visibility_outlined,
                  referenceSubtraitsPanel,
                ),
                fold(
                  'initiative',
                  t('Turnistica', 'Turn order'),
                  'sheet_initiative',
                  Icons.swap_vert,
                  referenceEncounterSlots,
                ),
              ],
            ),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              fold(
                'commands',
                t('Centro combattimento', 'Combat center'),
                'sheet_command_center',
                Icons.auto_stories_outlined,
                sheetCommandCenter,
              ),
              fold(
                'combat',
                t('Attacco, difesa e bonus', 'Attack, defense and bonuses'),
                'sheet_combat_values',
                Icons.shield_outlined,
                referenceCombatDetails,
              ),
              fold(
                'health',
                t('Vita, scudi e condizioni', 'HP, shields and conditions'),
                'sheet_hp',
                Icons.favorite_outline,
                hpModePanel,
              ),
              referenceDetailTile(
                'Occhi dei Caduti attivi · ${occhiCaduti.where((eye) => '${eye['ownerSheetId'] ?? ''}' == sheetTagAt(schedaCorrente) && readBoolValue(eye['active']) && !oculumFallenEyeIsDead(eye)).length}',
                'sheet_fallen_eyes_active',
                Icons.visibility,
                fallenEyesPage,
              ),
              fold(
                'damage',
                t('Danni subiti e cura', 'Damage taken and healing'),
                'sheet_damage_heal',
                Icons.healing_outlined,
                damageHealPanel,
              ),
              fold(
                'values',
                t('Valori e formule', 'Values and formulas'),
                'sheet_values',
                Icons.functions,
                () => mainValuesOverviewPanel(dense: true),
              ),
              fold(
                'editable',
                t('Modifica statistiche', 'Edit stats'),
                'sheet_editable_values',
                Icons.tune,
                editableMainValuesDropdown,
              ),
              fold(
                'experience',
                t('Esperienza e progressione', 'Experience and progression'),
                'sheet_exp',
                Icons.auto_awesome_outlined,
                experiencePanel,
              ),
              fold(
                'identity',
                t('Nome e identità', 'Name and identity'),
                'sheet_identity',
                Icons.badge_outlined,
                () => sheetIdentityEditorPanel(dense: true),
              ),
              fold(
                'race',
                t('Stirpe e origine', 'Lineage and origin'),
                'sheet_race',
                Icons.history_edu_outlined,
                raceIdentityPanel,
              ),
              fold(
                'portrait',
                t('Ritratto e Occhio', 'Portrait and Eye'),
                'sheet_image',
                Icons.portrait_outlined,
                () => Center(
                  child: ConstrainedBox(
                    key: const ValueKey('reference_portrait_preview'),
                    constraints: const BoxConstraints(maxWidth: 390),
                    child: oculumEyeBox(),
                  ),
                ),
              ),
              fold(
                'party',
                t('Party e alleati', 'Party and allies'),
                'sheet_party',
                Icons.groups_outlined,
                partyPanel,
              ),
              referenceDetailTile(
                t('Dadi rapidi', 'Quick dice'),
                'sheet_dice_quick',
                Icons.casino_outlined,
                () => sheetDiceDropdownPanel(dense: true),
              ),
              if (!referenceOculumFlames)
                fold(
                  'oculum',
                  t('Oculum completo e fiammelle', 'Full Oculum and flames'),
                  'reference_oculum_full',
                  Icons.local_fire_department_outlined,
                  oculumResourcePanel,
                ),
              fold(
                'stats',
                t('Dettagli delle statistiche', 'Stat details'),
                'sheet_stats',
                Icons.insights_outlined,
                () => statsOverviewPanel(dense: true),
              ),
              if (referenceSheetSection == 'general')
                fold(
                  'tools',
                  t('Azioni e consultazione', 'Actions and reference'),
                  'sheet_quick_glance',
                  Icons.explore_outlined,
                  () => Column(
                    children: [
                      occhiataVeloceRaWidget(),
                      quickLoreButtonsPanel(),
                      manualQuickToolsPanel(),
                      gradeBonusActionButton(),
                    ],
                  ),
                ),
            ],
          ),
          ValueListenableBuilder<int>(
            valueListenable: diceResultRevision,
            builder: (context, revision, child) => dadoMostrato.isEmpty
                ? const SizedBox.shrink()
                : diceResultPanel(),
          ),
        ],
      ),
    );
  }

  Widget referenceStatStrip() => ValueListenableBuilder<int>(
    valueListenable: activeSheetSummaryRevision,
    builder: (context, revision, child) => LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 600;
        final stats = [
          ('resilienza', t('Resilienza', 'Resilience'), resilienzaTotale()),
          ('volonta', t('Volontà', 'Will'), volontaTotale()),
          ('materia', t('Materia', 'Matter'), materiaTotale()),
          ('oculum', 'Oculum', oculumTotale()),
        ];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              for (var i = 0; i < stats.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: Material(
                    color: backgroundBottomColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: statFormulaColor(
                          stats[i].$1,
                        ).withValues(alpha: .55),
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => tiraStat(stats[i].$2, stats[i].$3),
                      onLongPress: () => vaiAllaFunzione(
                        page: 0,
                        anchorId: 'sheet_editable_values_${stats[i].$1}',
                      ),
                      child: Semantics(
                        button: true,
                        label:
                            '${stats[i].$2} ${stats[i].$3}. ${t('Tocca per tirare; tieni premuto per modificare.', 'Tap to roll; hold to edit.')}',
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: compact ? 4 : 12,
                            vertical: compact ? 9 : 10,
                          ),
                          child: Column(
                            children: [
                              Text(
                                stats[i].$2,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: compact ? 10 : 13,
                                  color: primaryColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${stats[i].$3}',
                                style: TextStyle(
                                  fontSize: compact ? 21 : 28,
                                  fontWeight: FontWeight.w700,
                                  color: statFormulaColor(stats[i].$1),
                                ),
                              ),
                              Text(
                                t('Tira', 'Roll'),
                                style: TextStyle(
                                  fontSize: compact ? 10 : 11,
                                  color: primaryColor.withValues(alpha: .7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    ),
  );
}

extension _OculumReferenceEncounters on _OculumHomePageState {
  void enterLocalReferenceEncounter(String id) {
    if (schedaCorrente < 0 || schedaCorrente >= schedePersonaggio.length) {
      return;
    }
    setState(() => selectMasterInitiativeGroup(id));
    final tag = sheetTagAt(schedaCorrente);
    if (!masterInitiativeTokens.any(
      (token) => '${token['sheetTag'] ?? token['id'] ?? ''}' == tag,
    )) {
      addSheetToMasterInitiative(schedaCorrente, rollInitiative: true);
    }
    programmaSalvataggio();
  }

  Widget referenceEncounterSlots() {
    final local = haPermessiMaster || realtimeService?.isConnected != true;
    if (local) {
      captureActiveMasterInitiativeGroup();
    }
    final groups = local
        ? masterInitiativeGroups.take(5).toList()
        : realtimeEncounterSnapshots.take(5).toList();
    return gothicPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          sectionTitle('Turnistiche'),
          const Text(
            'Cinque scontri indipendenti. Apri una tendina per vedere i partecipanti.',
          ),
          for (var index = 0; index < 5; index++)
            Builder(
              builder: (context) {
                final group = index < groups.length
                    ? groups[index]
                    : <String, dynamic>{
                        'name': 'Scontro ${index + 1}',
                        'tokens': [],
                      };
                final id = '${group[local ? 'id' : 'encounterId'] ?? ''}';
                final tokens = (group['tokens'] as List? ?? const [])
                    .whereType<Map>()
                    .toList();
                final selected =
                    id.isNotEmpty &&
                    id ==
                        (local
                            ? selectedMasterInitiativeGroupId
                            : realtimeSelectedEncounterId);
                return ExpansionTile(
                  key: ValueKey(
                    'encounter_slot_${haPermessiMaster ? "master" : "player"}_$index',
                  ),
                  leading: Icon(
                    selected ? Icons.visibility : Icons.circle_outlined,
                    color: selected ? tertiaryColor : primaryColor,
                  ),
                  title: Text(
                    '${group['name'] ?? "Scontro ${index + 1}"} · ${tokens.length} partecipanti',
                  ),
                  subtitle: Text(
                    id.isEmpty
                        ? 'In attesa del Master'
                        : 'Round ${group['round'] ?? 0}${selected ? " · selezionato" : ""}',
                  ),
                  children: [
                    if (haPermessiMaster)
                      TextFormField(
                        initialValue:
                            '${group['name'] ?? "Scontro ${index + 1}"}',
                        decoration: const InputDecoration(
                          labelText: 'Nome dello scontro',
                        ),
                        onChanged: (value) {
                          group['name'] = value.trim().isEmpty
                              ? 'Scontro ${index + 1}'
                              : value.trim();
                          programmaSalvataggio(invalidateCaches: false);
                        },
                      ),
                    if (tokens.isNotEmpty)
                      SizedBox(
                        height: min(220.0, tokens.length * 56.0),
                        child: ListView.builder(
                          itemCount: tokens.length,
                          itemBuilder: (context, row) {
                            final token = tokens[row];
                            return ListTile(
                              dense: true,
                              title: Text('${token['name'] ?? "???"}'),
                              trailing: canRemoveOwnEncounterToken(token)
                                  ? IconButton(
                                      tooltip: 'Esci dallo scontro',
                                      icon: const Icon(
                                        Icons.person_remove_outlined,
                                      ),
                                      onPressed: () =>
                                          removeReferenceEncounterMember(
                                            id,
                                            token,
                                            local: local,
                                          ),
                                    )
                                  : null,
                              subtitle: Text(
                                '${token['type'] ?? "Partecipante"} · Iniziativa ${readIntValue(token['initiativeRoll'])} + ${readIntValue(token['initiativeBase'])} = ${readIntValue(token['initiativeTotal'])} · Riflessi ${readIntValue(token['reflexes'])} · ${masterInitiativeStatusLabel("${token['status'] ?? 'ready'}")}',
                              ),
                            );
                          },
                        ),
                      ),
                    if (tokens.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: Text('Nessun partecipante assegnato.'),
                      ),
                    if (local)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton(
                          onPressed: () => enterLocalReferenceEncounter(id),
                          child: const Text('Entra con questa scheda'),
                        ),
                      ),
                    if (local)
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          OutlinedButton(
                            onPressed: () {
                              setState(() => selectMasterInitiativeGroup(id));
                            },
                            child: const Text('Seleziona'),
                          ),
                          OutlinedButton(
                            onPressed: () async {
                              setState(() => selectMasterInitiativeGroup(id));
                              await mostraAggiungiSchedaIniziativa();
                            },
                            child: const Text('Aggiungi PG / NPC / mostro'),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              setState(() => selectMasterInitiativeGroup(id));
                              openReferenceDetail(
                                'Turnistica — ${group['name']}',
                                'encounter_$id',
                                masterInitiativeTrackerPanel,
                              );
                            },
                            child: const Text('Gestisci turni'),
                          ),
                          if (realtimeService?.isConnected == true)
                            OutlinedButton(
                              onPressed: () {
                                setState(() => selectMasterInitiativeGroup(id));
                                publishRealtimeInitiativeSnapshot();
                              },
                              child: const Text('Pubblica online'),
                            ),
                        ],
                      )
                    else if (!local)
                      FilledButton(
                        onPressed:
                            id.isEmpty || realtimeService?.isConnected != true
                            ? null
                            : () {
                                setState(() {
                                  realtimeSelectedEncounterId = id;
                                  realtimeVisibleInitiativeSnapshot =
                                      Map<String, dynamic>.from(group);
                                });
                                unawaited(
                                  realtimeService!.sendInitiativeTurnAdjusted(
                                    senderRole: 'player',
                                    campaignId:
                                        '${group['campaignId'] ?? activeCampaignId}',
                                    campaignName:
                                        '${group['campaignName'] ?? activeCampaignName()}',
                                    sheetTag: sheetTagAt(schedaCorrente),
                                    turn: playerReportedTurn,
                                    encounterId: id,
                                    joinEncounter: true,
                                  ),
                                );
                              },
                        child: Text(
                          realtimeService?.isConnected == true
                              ? 'Entra nello scontro'
                              : 'Online non connesso',
                        ),
                      ),
                    const SizedBox(height: 8),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

extension _OculumReferenceResistanceDetails on _OculumHomePageState {
  String selectedIncomingDamageElement() => oculumNormalizeElementId(
    incomingDamageElement.isEmpty
        ? elementoDannoDominante()
        : incomingDamageElement,
  );

  String configuredIncomingDamagePreset([String? element]) {
    final elementId = element ?? selectedIncomingDamageElement();
    final saved = canonicalDamageModifierName(
      incomingDamagePresets[elementId] ?? 'Normale',
    );
    final temporary = activeStructuredEffects
        .where(
          (effect) =>
              effect['type'] == 'elemental_resistance' &&
              effect['element'] == elementId &&
              readIntValue(effect['remaining']) > 0,
        )
        .map((effect) => canonicalDamageModifierName('${effect['preset']}'))
        .toList();
    temporary.addAll(
      merchantHerbalEffects
          .where(
            (effect) =>
                effect['type'] == 'resistance' &&
                effect['element'] == elementId &&
                readIntValue(effect['shortRestsRemaining']) > 0,
          )
          .map((effect) => canonicalDamageModifierName('${effect['preset']}')),
    );
    if (temporary.isEmpty) return saved;
    final temporaryPreset = temporary.reduce(
      (strongest, candidate) =>
          modificatoreDannoDaNome(candidate).multiplier <
              modificatoreDannoDaNome(strongest).multiplier
          ? candidate
          : strongest,
    );
    return modificatoreDannoDaNome(temporaryPreset).multiplier <
            modificatoreDannoDaNome(saved).multiplier
        ? temporaryPreset
        : saved;
  }

  void openResistanceDetails() => openReferenceDetail(
    'Resistenze',
    'sheet_resistances',
    resistanceDetailsPanel,
  );

  Widget incomingElementSelector() {
    final selected = selectedIncomingDamageElement();
    final ids = {
      ...allDamageElementIds(),
      if (selected.isNotEmpty) selected,
    }.toList();
    return DropdownButtonFormField<String>(
      key: ValueKey('incoming_element_$selected'),
      initialValue: ids.contains(selected) ? selected : ids.first,
      isExpanded: true,
      decoration: fieldDecoration('Elemento del danno ricevuto'),
      items: [
        for (final id in ids)
          DropdownMenuItem(value: id, child: Text(elementDisplayName(id))),
      ],
      onChanged: (value) {
        if (value == null) return;
        setState(() => incomingDamageElement = value);
        programmaSalvataggio();
        notifyActiveSheetSummaryChanged();
      },
    );
  }

  Widget resistanceDetailsPanel() => ValueListenableBuilder<int>(
    valueListenable: activeSheetSummaryRevision,
    builder: (context, _, child) => gothicPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          sectionTitle('Resistenze'),
          const Text(
            'Fragilità, resistenze, immunità e rigenerazione sono salvate per elemento. Una percentuale libera sostituisce il preset di quell’elemento.',
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: resistanceElementSearchController,
            builder: (context, search, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  key: const ValueKey('resistance_element_search'),
                  controller: resistanceElementSearchController,
                  decoration: fieldDecoration('Cerca elemento').copyWith(
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: search.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Cancella ricerca',
                            onPressed: resistanceElementSearchController.clear,
                            icon: const Icon(Icons.clear),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                _filteredResistanceCards(search.text),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _filteredResistanceCards(String search) {
    final needle = search.trim().toLowerCase();
    final ids =
        {
              ...allDamageElementIds(),
              ...incomingDamagePresets.keys,
              ...dannoSubitoPercentPerTipo.keys,
            }
            .where(
              (id) =>
                  needle.isEmpty ||
                  elementDisplayName(id).toLowerCase().contains(needle) ||
                  id.toLowerCase().contains(needle),
            )
            .toList();
    if (ids.isEmpty) return const Text('Nessun elemento trovato.');
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        final columns = max(
          1,
          min(3, ((constraints.maxWidth + gap) / 260).floor()),
        );
        final cardWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final id in ids)
              SizedBox(width: cardWidth, child: _resistanceElementCard(id)),
          ],
        );
      },
    );
  }

  Widget _resistanceElementCard(String id) {
    final color = elementColor(id);
    final preset = configuredIncomingDamagePreset(id);
    return Container(
      key: ValueKey('resistance_element_$id'),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xff111014),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: .82), width: 1.25),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: .10), blurRadius: 9),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.remove_red_eye_outlined, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  elementDisplayName(id),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: color, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          DropdownButtonFormField<String>(
            key: ValueKey('resistance_${id}_$preset'),
            initialValue: preset,
            isExpanded: true,
            decoration: fieldDecoration('Stato'),
            items: [
              for (final option in modificatoriDanno)
                DropdownMenuItem(value: option.name, child: Text(option.name)),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                incomingDamagePresets[id] = value;
                dannoSubitoPercentPerTipo.remove(id);
                if (id == selectedIncomingDamageElement()) {
                  dannoSubitoPercentController.clear();
                }
              });
              programmaSalvataggio();
              notifyActiveSheetSummaryChanged();
            },
          ),
          const SizedBox(height: 6),
          TextFormField(
            key: ValueKey('resistance_percent_${id}_$preset'),
            initialValue: dannoSubitoPercentPerTipo[id] ?? '',
            decoration: fieldDecoration(
              'Modifica libera (%)',
            ).copyWith(hintText: '+25% fragilità · −20% resistenza'),
            keyboardType: const TextInputType.numberWithOptions(
              signed: true,
              decimal: true,
            ),
            onChanged: (value) {
              if (value.trim().isEmpty) {
                dannoSubitoPercentPerTipo.remove(id);
              } else {
                dannoSubitoPercentPerTipo[id] = value.trim();
              }
              programmaSalvataggio(invalidateCaches: false);
            },
            validator: (value) =>
                (value ?? '').trim().isEmpty ||
                    oculumIncomingDamagePercentMultiplier(value ?? '') != null
                ? null
                : 'Percentuale non valida',
          ),
          const SizedBox(height: 4),
          Text(
            damageDescription(modificatoreDannoDaNome(preset)),
            style: const TextStyle(fontSize: 11, height: 1.2),
          ),
        ],
      ),
    );
  }

  String subtraitFormulaHelp(HiddenEyeStat stat) {
    final group = hiddenEyeStatGroup(stat.id);
    final baseFormula = switch (stat.id) {
      'fortuna' => 'Karma + Fortuna nelle Risorse + floor(Livello/2)',
      'nodo' => 'Karma + Livello',
      'investigazione' => 'floor(max(Materia, Volontà)/2) + Livello',
      'manifestazione_potere' => 'floor(max(Materia, Oculum)/2) + Livello',
      'concentrazione' => 'floor(Volontà/2) + Livello',
      _ =>
        group == 'altro'
            ? 'Livello'
            : 'floor(${hiddenEyeGroupLabel(group)}/2) + Livello',
    };
    final total = hiddenEyeTotal(stat);
    final derived = hiddenEyeDerivedBonus(stat.id);
    final other = total - derived - (stat.id == 'fortuna' ? 0 : stat.valore);
    return '$baseFormula = $derived\nPunti assegnati: ${stat.id == 'fortuna' ? 0 : stat.valore} · altri bonus/malus: $other\nTiro: 1d20 + $total${hiddenEyeStatRollQuickBonus(stat) == 0 ? '' : ' + modificatore tiro ${hiddenEyeStatRollQuickBonus(stat)}'}';
  }

  Widget turnResetGesture(Widget child) => GestureDetector(
    onLongPress: requestEncounterReset,
    onSecondaryTap: requestEncounterReset,
    child: Tooltip(
      message: 'Tieni premuto o fai clic destro per resettare round e turni',
      child: child,
    ),
  );

  bool canRemoveOwnEncounterToken(Map token) {
    if (haPermessiMaster) return true;
    final tokenTag = '${token['sheetTag'] ?? token['id'] ?? ''}'.trim();
    if (tokenTag == sheetTagAt(schedaCorrente)) return true;
    if (schedaCorrente < 0 || schedaCorrente >= schedePersonaggio.length) {
      return false;
    }
    final ownSheet = schedePersonaggio[schedaCorrente];
    final ownTags = <String>{
      '${ownSheet['sheetTag'] ?? ownSheet['id'] ?? ''}'.trim(),
      '${ownSheet['realtimeSourceSheetTag'] ?? ''}'.trim(),
      '${ownSheet['realtimeLocalSheetTag'] ?? ''}'.trim(),
    }..remove('');
    return ownTags.contains(tokenTag);
  }

  Future<void> requestEncounterReset() async {
    if (!haPermessiMaster && realtimeService?.isConnected == true) {
      await showReportedTurnEditor();
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset round e turni'),
        content: const Text(
          'Riporta lo scontro al round 0 e i contatori personali a 0. Le schede rimangono nello scontro.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) resetMasterInitiativeRound();
  }

  void removeReferenceEncounterMember(
    String id,
    Map token, {
    required bool local,
  }) {
    final tag = '${token['sheetTag'] ?? token['id'] ?? ''}';
    if (!canRemoveOwnEncounterToken(token)) return;
    if (local) {
      final previous = selectedMasterInitiativeGroupId;
      selectMasterInitiativeGroup(id);
      final index = masterInitiativeTokens.indexWhere(
        (item) => item['id'] == token['id'],
      );
      if (index >= 0) removeMasterInitiativeTokenAt(index);
      if (previous != id) selectMasterInitiativeGroup(previous);
      notifyActiveSheetSummaryChanged();
      programmaSalvataggio();
    } else if (realtimeService?.isConnected == true) {
      unawaited(
        realtimeService!.sendInitiativeTurnAdjusted(
          senderRole: 'player',
          campaignId: activeCampaignId,
          campaignName: activeCampaignName(),
          sheetTag: tag,
          turn: playerReportedTurn,
          encounterId: id,
          leaveEncounter: true,
        ),
      );
    }
  }

  // Advance only the participant who has completed a turn. Remote players own
  // their live effects; snapshots carry the same monotonic personal counter.
  void advanceEncounterParticipantTurn(int index) {
    final token = masterInitiativeTokens[index];
    final next = max(0, readIntValue(token['reportedTurn'])) + 1;
    if (token['pawnId'] != null) {
      advancePawnTurn('${token['pawnId']}', next);
      token['reportedTurn'] = next;
      return;
    }
    final tag = '${token['sheetTag'] ?? token['id'] ?? ''}';
    if (tag == sheetTagAt(schedaCorrente)) {
      setPlayerReportedTurn(next, broadcast: false, advanceArt: false);
    } else {
      token['reportedTurn'] = next;
      final sheet = schedePersonaggio
          .where((s) => s['sheetTag'] == tag)
          .firstOrNull;
      if (sheet != null) {
        sheet['playerReportedTurn'] = next;
        for (final raw
            in (sheet['activeStructuredEffects'] as List? ?? const [])
                .whereType<Map>()) {
          if (oculumTurnUnit('${raw['unit']}') != 'turni') continue;
          final remaining = readIntValue(raw['remaining']);
          if (remaining > 0) raw['remaining'] = remaining - 1;
        }
        (sheet['activeStructuredEffects'] as List?)?.removeWhere(
          (raw) => raw is Map && readIntValue(raw['remaining']) == 0,
        );
      }
    }
    token['updatedAt'] = DateTime.now().toIso8601String();
  }
}

String oculumTurnUnit(String unit) => switch (oculumNormalizeText(unit)) {
  'turn' || 'turns' || 'turno' || 'turni' => 'turni',
  _ => oculumNormalizeText(unit),
};

extension _OculumReferenceFlameBar on _OculumHomePageState {
  Widget referenceOculumFlameBar() {
    final current = oculumTotale();
    final maximum = oculumMassimo();
    final active = maximum <= 0
        ? 0
        : (current / maximum * 10).ceil().clamp(0, 10);
    final color = statFormulaColor('oculum');
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [const Text('Oculum'), Text('$current/$maximum')],
          ),
          const SizedBox(height: 3),
          Semantics(
            label: 'Oculum $current di $maximum',
            child: SizedBox(
              height: 24,
              child: LayoutBuilder(
                builder: (context, constraints) => Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      left: constraints.maxWidth / 20,
                      right: constraints.maxWidth / 20,
                      child: Container(
                        height: 2,
                        color: color.withValues(alpha: .35),
                      ),
                    ),
                    Row(
                      children: [
                        for (var index = 0; index < 10; index++)
                          Expanded(
                            child: Icon(
                              Icons.local_fire_department,
                              size: min(24.0, constraints.maxWidth / 10),
                              color: index < active
                                  ? color
                                  : color.withValues(alpha: .20),
                              shadows: index < active
                                  ? [
                                      Shadow(
                                        color: color.withValues(alpha: .55),
                                        blurRadius: 5,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                      ],
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
}
