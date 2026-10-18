part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

extension _OculumReferenceSheet on _OculumHomePageState {
  Widget visibleTitleIdentitySelector({
    bool compact = true,
    bool includeName = true,
  }) {
    return PopupMenuButton<OculumTitle>(
      tooltip: t('Scegli titolo visibile', 'Choose visible title'),
      color: secondaryColor,
      onSelected: (title) {
        setState(() {
          final previous = titoloSempreVisibile?.nome ?? '';
          final all = [...titoli, ...trattiRazziali];
          for (final other in all) {
            other.sempreVisibile = identical(other, title);
            other.visibleSelectionManual = identical(other, title);
          }
          oculumNormalizeAlwaysVisibleTitles(all, racialTraits: trattiRazziali);
          aggiungiLog(
            'Titolo visibile: [$previous] → [${titoloSempreVisibile?.nome ?? ""}].',
          );
          invalidateDerivedDataCaches();
        });
        syncMasterInitiativeVisibleTitle(schedaCorrente);
        programmaSalvataggio();
      },
      itemBuilder: (_) {
        final all = [...titoli, ...trattiRazziali]
          ..sort((a, b) => (b.evoluto ? 1 : 0).compareTo(a.evoluto ? 1 : 0));
        final hasEvolved = all.any((title) => title.evoluto);
        return [
          for (final title in all)
            PopupMenuItem<OculumTitle>(
              value: title,
              enabled:
                  (!hasEvolved || title.evoluto) &&
                  oculumTitleCanBeAlwaysVisible(title, all),
              child: Text(
                '${title.nome}${hasEvolved && !title.evoluto
                    ? " · ${t('evoluzione necessaria', 'evolution required')}"
                    : !title.equipaggiato
                    ? " · ${t('da equipaggiare', 'equip first')}"
                    : ""}',
                style: TextStyle(
                  color: hasEvolved && !title.evoluto || !title.equipaggiato
                      ? primaryColor.withValues(alpha: .35)
                      : primaryColor,
                ),
              ),
            ),
        ];
      },
      child: GestureDetector(
        onSecondaryTap: openVisibleTitleIdentity,
        onLongPress: openVisibleTitleIdentity,
        child: Text(
          '${includeName ? "${nomeController.text.trim().isEmpty ? t('Il tuo personaggio', 'Your character') : nomeController.text} | " : ""}${titoloSempreVisibile?.nome ?? t('Scegli titolo', 'Choose title')}',
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
    );
  }

  Future<void> openVisibleTitleIdentity([OculumTitle? selected]) async {
    final title = selected ?? titoloSempreVisibile;
    if (title == null) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: secondaryColor,
        title: Text(title.nome, style: TextStyle(color: primaryColor)),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                campoModello(
                  label: t('Nome Titolo', 'Title name'),
                  initialValue: title.nome,
                  onChanged: (value) {
                    setState(() => title.nome = value);
                    syncMasterInitiativeVisibleTitle(schedaCorrente);
                    programmaSalvataggio();
                  },
                ),
                SizedBox(height: 12),
                campoModello(
                  label: t('Leggenda', 'Legend'),
                  initialValue: title.leggenda,
                  maxLines: 5,
                  onChanged: (value) {
                    setState(() => title.leggenda = value);
                    syncMasterInitiativeVisibleTitle(schedaCorrente);
                    programmaSalvataggio();
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              final racial = trattiRazziali.any(
                (item) => identical(item, title),
              );
              final index = (racial ? trattiRazziali : titoli).indexOf(title);
              _expandedFunctionSections.add(
                '${racial ? "racial_trait" : "title"}_${currentSheetScrollId()}_$index',
              );
              vaiAllaFunzione(
                page: 2,
                anchorId: titleEditorAnchorId(title, trattoRazziale: racial),
                logTitle: title.nome,
              );
            },
            child: Text(t('Apri scheda', 'Open entry')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(t('Chiudi', 'Close')),
          ),
        ],
      ),
    );
  }

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
            SizedBox(height: 14),
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
        !realtimeIsMasterRole &&
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
        color: Color(0xff14212e),
        border: Border.all(color: Color(0xff51718f)),
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
                ? realtimeIsCoMasterRole && hasFight
                      ? () => requestVisibleEncounterStep(-1)
                      : null
                : () => hasFight
                      ? nextMasterInitiativeTurn(delta: -1)
                      : setPlayerReportedTurn(playerReportedTurn - 1),
            icon: Icon(Icons.chevron_left),
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
                ? realtimeIsCoMasterRole && hasFight
                      ? () => requestVisibleEncounterStep(1)
                      : null
                : () => hasFight
                      ? nextMasterInitiativeTurn()
                      : setPlayerReportedTurn(playerReportedTurn + 1),
            icon: Icon(Icons.chevron_right),
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
              icon: Icon(Icons.add_circle_outline),
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
                  icon: Icon(Icons.add),
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
                    title: Text('Assegna punti sottotratti'),
                    content: TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Punti concessi dal Master',
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text('Annulla'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(
                          ctx,
                          max(0, readIntValue(controller.text)),
                        ),
                        child: Text('Aggiungi'),
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
              icon: Icon(Icons.stars_outlined),
              label: Text('Concedi punti'),
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
                    waitDuration: Duration(milliseconds: 450),
                    constraints: BoxConstraints(
                      maxWidth: min(360, MediaQuery.sizeOf(context).width - 32),
                    ),
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xff19131b), Color(0xff0b0a0e)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: statFormulaColor(group).withValues(alpha: .72),
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.black87, blurRadius: 16),
                      ],
                    ),
                    textStyle: TextStyle(
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
                        TextSpan(
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
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerLow,
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
                          minimumSize: Size(0, 34),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () => tiraSottotrattoOcchio(stat),
                        child: Text(
                          '${stat.nome} · ${hiddenEyeTotal(stat) >= 0 ? '+' : ''}${hiddenEyeTotal(stat)}',
                          style: TextStyle(
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

  Future<void> mostraRitrattoIngrandito() async {
    final bytes = immaginePersonaggio;
    final asset =
        oculumMemoryEyeAsset(portraitEyeRole) ?? 'assets/icon/oculum_eye.png';
    await oculumShowDialogUntilClosed<void>(
      context: context,
      builder: (dialogContext) {
        final size = MediaQuery.sizeOf(dialogContext);
        final side = max(
          80.0,
          min(600.0, min(size.width - 64, size.height - 180)),
        );
        return AlertDialog(
          key: const ValueKey('portrait-enlarged-dialog'),
          title: Text(t('Ritratto ingrandito', 'Enlarged portrait')),
          content: SizedBox.square(
            dimension: side,
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 5,
              child: bytes == null
                  ? Image.asset(asset, fit: BoxFit.contain)
                  : Image.memory(
                      bytes,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(t('Chiudi', 'Close')),
            ),
          ],
        );
      },
    );
  }

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
      bool shields = false,
    }) => Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                shields ? Icons.favorite_outline : Icons.visibility_outlined,
                size: 15,
                color: color,
              ),
              const SizedBox(width: 6),
              Expanded(child: Text(name)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(label, style: TextStyle(fontWeight: FontWeight.w700)),
                  if (shields && !hidden && vitalMemoryPendingHealing() > 0)
                    Text(
                      'Ricordo Vitale +${vitalMemoryPendingHealing()}',
                      style: TextStyle(
                        fontSize: 10,
                        color: vitalMemoryThemeColor(),
                      ),
                    ),
                ],
              ),
            ],
          ),
          SizedBox(height: 5),
          if (!hidden)
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: backgroundBottomColor,
                border: Border.all(color: color.withValues(alpha: .35)),
                borderRadius: BorderRadius.circular(5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Stack(
                  children: [
                    TweenAnimationBuilder<double>(
                      key: ValueKey(
                        'reference-meter-$shields-${currentSheetScrollId()}',
                      ),
                      tween: Tween(
                        end: maximum > 0
                            ? (current / maximum).clamp(0.0, 1.0)
                            : 0.0,
                      ),
                      duration:
                          MediaQuery.disableAnimationsOf(context) ||
                              oculumThemePresentation.value.motion ==
                                  OculumThemeMotion.disabled
                          ? Duration.zero
                          : const Duration(milliseconds: 380),
                      curve: Curves.easeOutCubic,
                      builder: (context, fraction, _) {
                        final palette = lifeBarGradient(
                          stileBarraVita,
                          oculumHealthColor(fraction),
                        );
                        return LinearProgressIndicator(
                          value: fraction,
                          minHeight: 8,
                          color: shields ? palette[palette.length ~/ 2] : color,
                          backgroundColor: color.withValues(alpha: .15),
                        );
                      },
                    ),
                    if (shields &&
                        maximum > 0 &&
                        maximum > current &&
                        vitalMemoryPendingHealing() > 0)
                      Positioned.fill(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor:
                                ((max(0, current) +
                                            vitalMemoryPendingHealing()) /
                                        maximum)
                                    .clamp(0.0, 1.0),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: FractionallySizedBox(
                                widthFactor:
                                    min(
                                      vitalMemoryPendingHealing(),
                                      maximum - max(0, current),
                                    ) /
                                    min(
                                      maximum,
                                      max(0, current) +
                                          vitalMemoryPendingHealing(),
                                    ),
                                child: ColoredBox(
                                  color: vitalMemoryThemeColor().withValues(
                                    alpha: .72,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (shields && scudo() > 0)
                      LinearProgressIndicator(
                        key: ValueKey('reference_shield_bar'),
                        value: maximum > 0
                            ? (scudo() / maximum).clamp(0.0, 1.0)
                            : 0,
                        minHeight: 8,
                        color: Color(0xFF44A7FF),
                        backgroundColor: Colors.transparent,
                      ),
                    if (shields && scudoOculum() > 0)
                      LinearProgressIndicator(
                        key: ValueKey('reference_oculum_shield_bar'),
                        value: maximum > 0
                            ? (scudoOculum() / maximum).clamp(0.0, 1.0)
                            : 0,
                        minHeight: 8,
                        color: eyePupilGlowColor,
                        backgroundColor: Colors.transparent,
                      ),
                  ],
                ),
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
            key: const ValueKey('reference_portrait_frame'),
            width: compact ? 72 : 104,
            height: compact ? 72 : 104,
            child: OculumThemeSheetFrame(
              role: OculumThemeFrameRole.portrait,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: tertiaryColor.withValues(alpha: .65),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: GestureDetector(
                    onTap: mostraRitrattoIngrandito,
                    onLongPress: immaginePersonaggio == null
                        ? null
                        : mostraAzioniImmaginePersonaggio,
                    onSecondaryTap: immaginePersonaggio == null
                        ? null
                        : copiaImmaginePersonaggioNegliAppunti,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (portraitShowEyeBehind ||
                            immaginePersonaggio == null)
                          Center(
                            child: Image.asset(
                              oculumMemoryEyeAsset(portraitEyeRole) ??
                                  'assets/icon/oculum_eye.png',
                              width: compact ? 48 : 72,
                            ),
                          ),
                        if (immaginePersonaggio != null)
                          Image.memory(
                            immaginePersonaggio!,
                            fit: BoxFit.contain,
                            cacheWidth: 320,
                          ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: IconButton(
                            key: const ValueKey('portrait-enlarge'),
                            tooltip: t('Ingrandisci immagine', 'Enlarge image'),
                            visualDensity: VisualDensity.compact,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            icon: const Icon(Icons.open_in_full, size: 15),
                            onPressed: mostraRitrattoIngrandito,
                          ),
                        ),
                      ],
                    ),
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
                          child: visibleTitleIdentitySelector(compact: compact),
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
                      healthShieldLabel(),
                      hpReadoutProtetto(),
                      hpCorrenti(),
                      maxHp(),
                      statFormulaColor('resilienza'),
                      hidden: vitaAfonaAttiva(),
                      shields: true,
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
    return OculumThemeSheetBackdrop(
      child: SingleChildScrollView(
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
                      icon: Icon(Icons.auto_awesome_outlined),
                      label: Text('Oculum Art'),
                    ),
                    TextButton.icon(
                      onPressed: () => vaiAllaFunzione(page: 6),
                      icon: Icon(Icons.inventory_2_outlined),
                      label: Text(t('Inventario', 'Inventory')),
                    ),
                    TextButton.icon(
                      onPressed: () => vaiAllaFunzione(page: 5),
                      icon: Icon(Icons.menu_book_outlined),
                      label: Text(t('Diario', 'Diary')),
                    ),
                    TextButton.icon(
                      onPressed: openResistanceDetails,
                      icon: Icon(Icons.shield_outlined),
                      label: Text('Resistenze'),
                    ),
                  ],
                ),
              ),
            OculumThemeSheetFrame(child: hero),
            const OculumThemeRelicBanner(),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  setState(
                    () => referenceOculumFlames = !referenceOculumFlames,
                  );
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
                        onlineAttackButton(),
                      ],
                    ),
                    SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Color(0xff491c24),
                            foregroundColor: Color(0xffffddd4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                              side: BorderSide(color: Color(0xffad5559)),
                            ),
                          ),
                          onPressed: () => tiraValoreSpeciale(
                            'VC',
                            vc(),
                            applyGlobalRollModifier: false,
                          ),
                          icon: Icon(Icons.casino_outlined),
                          label: Text('VC ${vc()} · ${t('Attacco', 'Attack')}'),
                        ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Color(0xff142a40),
                            foregroundColor: Color(0xffd6eaff),
                            side: BorderSide(color: Color(0xff517dab)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          onPressed: () => tiraValoreSpeciale(
                            'CM',
                            cm(),
                            applyGlobalRollModifier: false,
                          ),
                          icon: Icon(Icons.shield_outlined),
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
                          icon: Icon(Icons.visibility_outlined),
                          label: Text(
                            '${t('Schivata', 'Dodge')} ${schivateOculumDisponibili()}/${schivateOculumTotali()}',
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: tiraAiutaCompagno,
                          icon: Icon(Icons.volunteer_activism_outlined),
                          label: Text(t('Aiuta compagno', 'Help ally')),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => tiraValoreSpeciale(
                            'Iniziativa',
                            iniziativa(),
                            applyGlobalRollModifier: false,
                          ),
                          icon: Icon(Icons.bolt_outlined),
                          label: Text(
                            '${t('Iniziativa', 'Initiative')} +${iniziativa()}',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: tertiaryColor,
                            side: BorderSide(color: tertiaryColor),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => apriDannoCuraDalCentroPartita(),
                          icon: Icon(Icons.favorite_outline),
                          label: Text(
                            t(
                              'Danni subiti e cura',
                              'Damage taken and healing',
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    onlineCombatRequestsPanel(),
                    combatAbilityQuickBar(),
                    Text(
                      '${t('Danni inflitti', 'Damage dealt')}: ${dannoTotale()} · ${t('Difesa totale', 'Total defense')}: ${difesa()} · ${t('I Sottotratti sono tiri alternativi', 'Subtraits are alternative rolls')}',
                      style: TextStyle(fontSize: 12),
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
                      key: ValueKey('reference_portrait_preview'),
                      constraints: BoxConstraints(maxWidth: 390),
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
                if (i > 0) SizedBox(width: 6),
                Expanded(
                  child: OculumThemeSheetFrame(
                    role: OculumThemeFrameRole.statistics,
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
                      child: Ink(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color.lerp(
                                backgroundBottomColor,
                                statFormulaColor(stats[i].$1),
                                .09,
                              )!,
                              backgroundBottomColor,
                            ],
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          hoverColor: statFormulaColor(
                            stats[i].$1,
                          ).withValues(alpha: .09),
                          splashColor: statFormulaColor(
                            stats[i].$1,
                          ).withValues(alpha: .18),
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
                                  Icon(
                                    switch (stats[i].$1) {
                                      'resilienza' => Icons.favorite_outline,
                                      'volonta' =>
                                        Icons.local_fire_department_outlined,
                                      'materia' => Icons.shield_outlined,
                                      _ => Icons.visibility_outlined,
                                    },
                                    size: compact ? 15 : 18,
                                    color: statFormulaColor(stats[i].$1),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    stats[i].$2,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: compact ? 10 : 13,
                                      color: primaryColor,
                                    ),
                                  ),
                                  SizedBox(height: 4),
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
    final local = realtimeIsMasterRole || realtimeService?.isConnected != true;
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
          Text(
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
                final tokens = (group['tokens'] as List? ?? [])
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
                        decoration: InputDecoration(
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
                                      icon: Icon(Icons.person_remove_outlined),
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
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Text('Nessun partecipante assegnato.'),
                      ),
                    if (local)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton(
                          onPressed: () => enterLocalReferenceEncounter(id),
                          child: Text('Entra con questa scheda'),
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
                            child: Text('Seleziona'),
                          ),
                          OutlinedButton(
                            onPressed: () async {
                              setState(() => selectMasterInitiativeGroup(id));
                              await mostraAggiungiSchedaIniziativa();
                            },
                            child: Text('Aggiungi PG / NPC / mostro'),
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
                            child: Text('Gestisci turni'),
                          ),
                          if (realtimeService?.isConnected == true)
                            OutlinedButton(
                              onPressed: () {
                                setState(() => selectMasterInitiativeGroup(id));
                                publishRealtimeInitiativeSnapshot();
                              },
                              child: Text('Pubblica online'),
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
                                  syncCurrentSheetEncounterTurn();
                                });
                                if (!realtimeIsCoMasterRole) {
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
                                }
                              },
                        child: Text(
                          realtimeService?.isConnected == true
                              ? realtimeIsCoMasterRole
                                    ? 'Apri scontro condiviso'
                                    : 'Entra nello scontro'
                              : 'Online non connesso',
                        ),
                      ),
                    SizedBox(height: 8),
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
      automaticMonsterPassiveEffects()
          .where(
            (effect) =>
                effect.type == 'elemental_resistance' &&
                (oculumNormalizeElementId(effect.elementType) == elementId ||
                    effect.elementType == 'tutti' ||
                    effect.elementType == 'tutti i danni'),
          )
          .map(
            (effect) => canonicalDamageModifierName(effect.customDisplayText),
          ),
    );
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
    final spineArmor = spineArmorPreset();
    if (spineVariant == 'legno' &&
        oculumNormalizeElementId(elementId) == 'fuoco') {
      return 'Fragilità';
    }
    if (spineArmor.isNotEmpty) temporary.add(spineArmor);
    // A precise volley exposes the caster even when the passive armor is on.
    if (oculumNormalizeElementId(elementId) == 'perforante' &&
        activeStructuredEffects.any((effect) {
          return effect['effectId'] == 'spine_piercing_weakness' &&
              readIntValue(effect['remaining']) > 0;
        })) {
      return 'Fragilità';
    }
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
          Text(
            'Fragilità, resistenze, immunità e rigenerazione sono salvate per elemento. Una percentuale libera sostituisce il preset di quell’elemento.',
          ),
          SizedBox(height: 12),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: resistanceElementSearchController,
            builder: (context, search, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  key: ValueKey('resistance_element_search'),
                  controller: resistanceElementSearchController,
                  decoration: fieldDecoration('Cerca elemento').copyWith(
                    prefixIcon: Icon(Icons.search),
                    suffixIcon: search.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Cancella ricerca',
                            onPressed: resistanceElementSearchController.clear,
                            icon: Icon(Icons.clear),
                          ),
                  ),
                ),
                SizedBox(height: 12),
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
    if (ids.isEmpty) return Text('Nessun elemento trovato.');
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        final columns = max(
          1,
          min(3, ((constraints.maxWidth + gap) / 260).floor()),
        );
        final cardWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;
        return OculumElementMotifClock(
          child: Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final id in ids)
                SizedBox(width: cardWidth, child: _resistanceElementCard(id)),
            ],
          ),
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
        color: Theme.of(context).colorScheme.surfaceContainerLow,
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
              OculumElementSigil(elementId: id, color: color),
              SizedBox(width: 6),
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
          SizedBox(height: 7),
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
          SizedBox(height: 6),
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
          SizedBox(height: 4),
          Text(
            damageDescription(modificatoreDannoDaNome(preset)),
            style: TextStyle(fontSize: 11, height: 1.2),
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
    if (canActWithoutMasterApproval) return true;
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
      requestMasterAction(
        'encounter_reset',
        'Reset round e turni dello scontro',
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reset round e turni'),
        content: Text(
          'Riporta lo scontro al round 0 e i contatori personali a 0. Le schede rimangono nello scontro.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Reset'),
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
    final scrollEffects = (token['scrollEffects'] as List? ?? [])
        .whereType<Map>()
        .map((effect) => Map<String, dynamic>.from(effect))
        .toList();
    final remainingScrollEffects = <Map<String, dynamic>>[];
    final expiredScrollNotes = <String>{};
    for (final effect in scrollEffects) {
      final turns = max(0, readIntValue(effect['remainingTurns']) - 1);
      if (turns > 0) {
        effect['remainingTurns'] = turns;
        remainingScrollEffects.add(effect);
      } else if ('${effect['note'] ?? ''}'.isNotEmpty) {
        expiredScrollNotes.add('${effect['note']}');
      }
    }
    token['scrollEffects'] = remainingScrollEffects;
    if (expiredScrollNotes.isNotEmpty) {
      token['notes'] = '${token['notes'] ?? ''}'
          .split('\n')
          .where((line) => !expiredScrollNotes.contains(line))
          .join('\n')
          .trim();
    }
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
            in (sheet['activeStructuredEffects'] as List? ?? [])
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
            children: [Text('Oculum'), Text('$current/$maximum')],
          ),
          SizedBox(height: 3),
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
