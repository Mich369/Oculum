part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member, unused_element

extension _OculumHomeTitlesInventoryPages on _OculumHomePageState {
  // STORIA / DIARIO
  // =====================================================

  Widget backgroundAndSkillsPage() {
    return responsivePageList(
      pageKey: 'story',
      maxColumns: 2,
      minColumnWidth: 340,
      fullWidthIndexes: const <int>{0},
      children: [
        functionAnchor(
          'story_root',
          sectionTitle(t('Background', 'Background')),
        ),
        gothicPanel(
          borderColor: primaryColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t('Storia della Scheda', 'Sheet Story'),
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              smallInfoText(
                t(
                  'Qui puoi scrivere chi è il personaggio, cosa ha perso, cosa desidera, chi ama, chi teme e quale parte di sé sta cercando di capire.',
                  'Here you can write who the character is, what they lost, what they desire, who they love, who they fear and what part of themselves they are trying to understand.',
                ),
              ),
              const SizedBox(height: 12),
              campoTesto(
                label: t('Background scritto', 'Written background'),
                controller: backgroundController,
                numero: false,
                maxLines: 10,
              ),
              const SizedBox(height: 12),
              campoTesto(
                label: t(
                  'Note personali / scopo / legami / drop / lore',
                  'Personal notes / purpose / bonds / drops / lore',
                ),
                controller: notePersonaggioController,
                numero: false,
                maxLines: 5,
              ),
            ],
          ),
        ),
        if (modalitaMaster)
          gothicPanel(
            borderColor: tertiaryColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('Sessione Master', 'Master Session'),
                  style: TextStyle(
                    color: tertiaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                smallInfoText(
                  t(
                    'Note della sessione della campagna. Compaiono qui solo quando la Modalita Master e attiva nelle impostazioni o all ingresso.',
                    'Campaign session notes. They appear here only when Master Mode is enabled in settings or at entry.',
                  ),
                ),
                const SizedBox(height: 12),
                campoTesto(
                  label: t('Sessione scritta', 'Written session'),
                  controller: masterSessionController,
                  numero: false,
                  maxLines: 8,
                ),
              ],
            ),
          ),
        sectionTitle(t('Diario', 'Diary')),
        gothicPanel(
          borderColor: tertiaryColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              smallInfoText(
                t(
                  'Il diario è una parte meccanica e narrativa. Scrivere ricordi, paure, sogni, traumi, promesse e decisioni importanti può dare Ispirazioni. Non serve scrivere tanto: serve scrivere qualcosa che abbia peso.',
                  'The diary is both narrative and mechanical. Writing memories, fears, dreams, traumas, promises and important decisions can grant Inspirations. It does not need to be long: it needs to matter.',
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: aggiungiPaginaDiario,
                icon: const Icon(Icons.edit_note),
                style: ElevatedButton.styleFrom(
                  backgroundColor: tertiaryColor,
                  foregroundColor: tertiaryColor.computeLuminance() > 0.45
                      ? Colors.black
                      : Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
                label: Text(
                  t(
                    'Aggiungi pagina diario e +1 Ispirazione',
                    'Add diary page and +1 Inspiration',
                  ),
                ),
              ),
            ],
          ),
        ),
        for (int i = 0; i < diarioPagine.length; i++)
          gothicPanel(
            padding: EdgeInsets.zero,
            borderColor: primaryColor.withValues(alpha: 0.75),
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                key: sheetExpansionKey('diary_page_$i'),
                initiallyExpanded: false,
                iconColor: primaryColor,
                collapsedIconColor: primaryColor,
                title: Text(
                  '${t('Pagina Diario', 'Diary Page')} ${i + 1}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  cleanUiText(
                    diarioPagine[i].trim().isEmpty
                        ? t('Vuota', 'Empty')
                        : diarioPagine[i],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
                childrenPadding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                children: [
                  campoModello(
                    fieldKey: ValueKey(
                      'diary_page_${currentSheetScrollId()}_${i}_text',
                    ),
                    label: t('Testo diario', 'Diary text'),
                    initialValue: diarioPagine[i],
                    onChanged: (value) => diarioPagine[i] = value,
                    maxLines: 7,
                  ),
                  smallInfoText(
                    t(
                      'Memoria permanente: questa pagina non viene eliminata.',
                      'Permanent memory: this page is not deleted.',
                    ),
                    color: tertiaryColor,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget backgroundAndSkillsPageEfficient() {
    final diaryTitleIndex = modalitaMaster ? 4 : 3;
    final headerBuilders = <WidgetBuilder>[
      (_) => functionAnchor(
        'story_root',
        sectionTitle(t('Background', 'Background')),
      ),
      (_) => storyBackgroundPanelEfficient(),
      if (modalitaMaster) (_) => storyMasterPanelEfficient(),
      (_) => storyOnlineSessionNotesPanel(),
      (_) => sectionTitle(t('Diario', 'Diary')),
      (_) => storyDiaryIntroPanelEfficient(),
    ];

    final builders = <WidgetBuilder>[
      ...headerBuilders,
      for (int i = 0; i < diarioPagine.length; i++)
        (_) {
          final diaryIndex = i;
          return RepaintBoundary(
            key: ValueKey('diary_tile_${currentSheetScrollId()}_$diaryIndex'),
            child: storyDiaryPageTileEfficient(diaryIndex),
          );
        },
    ];

    return responsivePageBuilder(
      pageKey: 'story',
      builders: builders,
      fullWidthIndexes: <int>{0, diaryTitleIndex},
      maxColumns: 2,
      minColumnWidth: 340,
      cacheExtent: 420,
    );
  }

  Widget storyBackgroundPanelEfficient() {
    return gothicPanel(
      borderColor: primaryColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('Storia della Scheda', 'Sheet Story'),
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          smallInfoText(
            t(
              'Qui puoi scrivere chi e il personaggio, cosa ha perso, cosa desidera, chi ama, chi teme e quale parte di se sta cercando di capire.',
              'Here you can write who the character is, what they lost, what they desire, who they love, who they fear and what part of themselves they are trying to understand.',
            ),
          ),
          const SizedBox(height: 12),
          campoTesto(
            label: t('Background scritto', 'Written background'),
            controller: backgroundController,
            numero: false,
            maxLines: 10,
          ),
          const SizedBox(height: 12),
          campoTesto(
            label: t(
              'Note personali / scopo / legami / drop / lore',
              'Personal notes / purpose / bonds / drops / lore',
            ),
            controller: notePersonaggioController,
            numero: false,
            maxLines: 5,
          ),
        ],
      ),
    );
  }

  Widget storyMasterPanelEfficient() {
    return gothicPanel(
      borderColor: tertiaryColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('Sessione Master', 'Master Session'),
            style: TextStyle(
              color: tertiaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          smallInfoText(
            t(
              'Note della sessione della campagna. Compaiono qui solo quando la Modalita Master e attiva nelle impostazioni o all ingresso.',
              'Campaign session notes. They appear here only when Master Mode is enabled in settings or at entry.',
            ),
          ),
          const SizedBox(height: 12),
          campoTesto(
            label: t('Sessione scritta', 'Written session'),
            controller: masterSessionController,
            numero: false,
            maxLines: 8,
          ),
        ],
      ),
    );
  }

  Widget storyDiaryIntroPanelEfficient() {
    return gothicPanel(
      borderColor: tertiaryColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          smallInfoText(
            t(
              'Il diario e una parte meccanica e narrativa. Scrivere ricordi, paure, sogni, traumi, promesse e decisioni importanti puo dare Ispirazioni. Non serve scrivere tanto: serve scrivere qualcosa che abbia peso.',
              'The diary is both narrative and mechanical. Writing memories, fears, dreams, traumas, promises and important decisions can grant Inspirations. It does not need to be long: it needs to matter.',
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: aggiungiPaginaDiario,
            icon: const Icon(Icons.edit_note),
            style: ElevatedButton.styleFrom(
              backgroundColor: tertiaryColor,
              foregroundColor: tertiaryColor.computeLuminance() > 0.45
                  ? Colors.black
                  : Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
            label: Text(
              t(
                'Aggiungi pagina diario e +1 Ispirazione',
                'Add diary page and +1 Inspiration',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget storyDiaryPageTileEfficient(int i) {
    return gothicPanel(
      padding: EdgeInsets.zero,
      borderColor: primaryColor.withValues(alpha: 0.75),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: sheetExpansionKey('diary_page_$i'),
          initiallyExpanded: false,
          iconColor: primaryColor,
          collapsedIconColor: primaryColor,
          title: Text(
            '${t('Pagina Diario', 'Diary Page')} ${i + 1}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: primaryColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            cleanUiText(
              diarioPagine[i].trim().isEmpty
                  ? t('Vuota', 'Empty')
                  : diarioPagine[i],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          children: [
            campoModello(
              fieldKey: ValueKey(
                'diary_page_${currentSheetScrollId()}_${i}_text',
              ),
              label: t('Testo diario', 'Diary text'),
              initialValue: diarioPagine[i],
              onChanged: (value) => diarioPagine[i] = value,
              maxLines: 7,
            ),
            smallInfoText(
              t(
                'Memoria permanente: questa pagina non viene eliminata.',
                'Permanent memory: this page is not deleted.',
              ),
              color: tertiaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget skillBonusCreateFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        smallInfoText(
          t(
            'Bonus opzionali applicati quando la Skill è equipaggiata.',
            'Optional bonuses applied when the Skill is equipped.',
          ),
          color: tertiaryColor,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: campoTesto(
                label: t('Resilienza +', 'Resilience +'),
                controller: skillResController,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: campoTesto(
                label: t('Volontà +', 'Will +'),
                controller: skillVolController,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: campoTesto(
                label: 'Materia +',
                controller: skillMatController,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: campoTesto(
                label: 'Oculum +',
                controller: skillOcuController,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: campoTesto(
                label: t('Danni +', 'Damage +'),
                controller: skillDanniController,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: campoTesto(
                label: t('Difesa +', 'Defense +'),
                controller: skillDifesaController,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget skillBonusEditFields(CharacterSkill skill) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        smallInfoText(
          t(
            'Questi bonus entrano nel calcolo solo quando la Skill è equipaggiata.',
            'These bonuses are counted only while the Skill is equipped.',
          ),
          color: tertiaryColor,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: campoModello(
                label: t('Resilienza +', 'Resilience +'),
                initialValue: '${skill.resilienza}',
                onChanged: (value) {
                  final nuovo = readIntValue(value);
                  if (skill.equipaggiata) {
                    applicaBonusAttuali(resilienza: nuovo - skill.resilienza);
                  }
                  skill.resilienza = nuovo;
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: campoModello(
                label: t('Volontà +', 'Will +'),
                initialValue: '${skill.volonta}',
                onChanged: (value) {
                  final nuovo = readIntValue(value);
                  if (skill.equipaggiata) {
                    applicaBonusAttuali(volonta: nuovo - skill.volonta);
                  }
                  skill.volonta = nuovo;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: campoModello(
                label: 'Materia +',
                initialValue: '${skill.materia}',
                onChanged: (value) {
                  final nuovo = readIntValue(value);
                  if (skill.equipaggiata) {
                    applicaBonusAttuali(materia: nuovo - skill.materia);
                  }
                  skill.materia = nuovo;
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: campoModello(
                label: 'Oculum +',
                initialValue: '${skill.oculum}',
                onChanged: (value) {
                  final nuovo = readIntValue(value);
                  if (skill.equipaggiata) {
                    applicaBonusAttuali(oculum: nuovo - skill.oculum);
                  }
                  skill.oculum = nuovo;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: campoModello(
                label: t('Danni +', 'Damage +'),
                initialValue: '${skill.danni}',
                onChanged: (value) => skill.danni = readIntValue(value),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: campoModello(
                label: t('Difesa +', 'Defense +'),
                initialValue: '${skill.difesa}',
                onChanged: (value) => skill.difesa = readIntValue(value),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void syncSkillLegacyFromForm(CharacterSkill skill, int formIndex) {
    if (formIndex == 0) {
      skill.syncLegacyFromFirstForm();
    }
  }

  Future<void> confermaEliminaFormaSkill(
    CharacterSkill skill,
    int formIndex,
  ) async {
    skill.ensureForms();
    if (skill.forme.length <= 1) {
      setState(() {
        risultato = t(
          'Non puoi eliminare l unica forma rimasta.',
          'You cannot delete the only remaining form.',
        );
        aggiungiLog(risultato);
      });
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF120D18),
        title: Text(t('Elimina forma?', 'Delete form?')),
        content: Text(
          t(
            'La forma verra rimossa dalla Skill senza toccare le altre forme.',
            'The form will be removed from the Skill without touching the other forms.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t('Annulla', 'Cancel')),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.shade700,
              foregroundColor: Colors.white,
            ),
            label: Text(t('Elimina', 'Delete')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    setState(() {
      skill.forme.removeAt(formIndex);
      skill.ensureForms();
      risultato = t('Forma eliminata.', 'Form deleted.');
      aggiungiLog(risultato);
    });
    programmaSalvataggio();
  }

  Widget skillFormTextField({
    required CharacterSkill skill,
    required CharacterSkillForm form,
    required int formIndex,
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
    int maxLines = 1,
  }) {
    return campoModello(
      label: label,
      initialValue: value,
      maxLines: maxLines,
      onChanged: (value) {
        onChanged(value);
        syncSkillLegacyFromForm(skill, formIndex);
      },
    );
  }

  void usaFormaSkill(CharacterSkill skill, int skillIndex, int formIndex) {
    skill.ensureForms();
    if (formIndex < 0 || formIndex >= skill.forme.length) return;
    final form = skill.forme[formIndex];
    final formName = form.nome.trim().isEmpty
        ? 'Forma ${formIndex + 1}'
        : form.nome.trim();
    final isHighLearnedForm = formIndex >= max(0, skill.forme.length - 2);
    final atQuarterHp = hpCorrenti() <= sogliaStatoForzaHp();

    setState(() {
      final parts = <String>[
        t('Forma skill usata', 'Skill form used'),
        '${skill.nome.trim().isEmpty ? t('Skill senza nome', 'Unnamed skill') : skill.nome.trim()} - $formName',
      ];
      if (form.costo.trim().isNotEmpty) {
        parts.add('${t('Costo', 'Cost')}: ${form.costo.trim()}');
      }
      if (form.cooldown.trim().isNotEmpty) {
        parts.add('Cooldown: ${form.cooldown.trim()}');
      }

      if (atQuarterHp && isHighLearnedForm) {
        final svenimento = modificaCenereControllata(1);
        parts.add(
          t(
            'A un quarto HP o meno, usare una forma alta imparata aggiunge +1 Cenere.',
            'At one quarter HP or lower, using a high learned form adds +1 Ash.',
          ),
        );
        if (svenimento != null) parts.add(svenimento);
      }

      risultato = parts.join('\n');
      ultimoEventoRiposo = risultato;
      aggiungiLog(risultato);
    });
    programmaSalvataggio();
  }

  Widget skillFormEditorTile(
    CharacterSkill skill,
    int skillIndex,
    int formIndex,
  ) {
    skill.ensureForms();
    final form = skill.forme[formIndex];
    final canDelete = skill.forme.length > 1;
    final formTitle = form.nome.trim().isEmpty
        ? 'Forma ${formIndex + 1}'
        : form.nome.trim();
    final summary = [
      if (form.tipo.trim().isNotEmpty) form.tipo.trim(),
      if (form.costo.trim().isNotEmpty) form.costo.trim(),
      if (form.cooldown.trim().isNotEmpty) 'CD ${form.cooldown.trim()}',
      if (form.buff.trim().isNotEmpty) '@',
    ].join(' - ');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: primaryColor.withValues(alpha: 0.35)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: sheetExpansionKey('free_skill_${skillIndex}_form_$formIndex'),
          initiallyExpanded: false,
          maintainState: true,
          tilePadding: const EdgeInsets.fromLTRB(10, 0, 8, 0),
          childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          leading: CircleAvatar(
            radius: 16,
            backgroundColor: tertiaryColor.withValues(alpha: 0.16),
            child: Text(
              '${formIndex + 1}',
              style: TextStyle(
                color: tertiaryColor,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
          title: Text(
            cleanUiText(formTitle),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: summary.isEmpty
              ? null
              : Text(
                  cleanUiText(summary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
          trailing: canDelete
              ? IconButton(
                  tooltip: t('Elimina forma', 'Delete form'),
                  onPressed: () => confermaEliminaFormaSkill(skill, formIndex),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                )
              : null,
          children: [
            skillFormTextField(
              skill: skill,
              form: form,
              formIndex: formIndex,
              label: t('Nome forma', 'Form name'),
              value: form.nome,
              onChanged: (value) => form.nome = value,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: skillFormTextField(
                    skill: skill,
                    form: form,
                    formIndex: formIndex,
                    label: t('Tipo / elemento', 'Type / element'),
                    value: form.tipo,
                    onChanged: (value) => form.tipo = value,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: skillFormTextField(
                    skill: skill,
                    form: form,
                    formIndex: formIndex,
                    label: t('Livello / requisito', 'Level / requirement'),
                    value: form.livello,
                    onChanged: (value) => form.livello = value,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: skillFormTextField(
                    skill: skill,
                    form: form,
                    formIndex: formIndex,
                    label: t('Costo', 'Cost'),
                    value: form.costo,
                    onChanged: (value) => form.costo = value,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: skillFormTextField(
                    skill: skill,
                    form: form,
                    formIndex: formIndex,
                    label: 'Cooldown',
                    value: form.cooldown,
                    onChanged: (value) => form.cooldown = value,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            skillFormTextField(
              skill: skill,
              form: form,
              formIndex: formIndex,
              label: t('Descrizione', 'Description'),
              value: form.descrizione,
              maxLines: 4,
              onChanged: (value) => form.descrizione = value,
            ),
            const SizedBox(height: 8),
            skillFormTextField(
              skill: skill,
              form: form,
              formIndex: formIndex,
              label: t('Effetto', 'Effect'),
              value: form.effetto,
              maxLines: 3,
              onChanged: (value) => form.effetto = value,
            ),
            const SizedBox(height: 8),
            skillFormTextField(
              skill: skill,
              form: form,
              formIndex: formIndex,
              label: t('Buff / comando @', '@ buff / command'),
              value: form.buff,
              maxLines: 2,
              onChanged: (value) => form.buff = value,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: skillFormTextField(
                    skill: skill,
                    form: form,
                    formIndex: formIndex,
                    label: t('Danni', 'Damage'),
                    value: form.danni,
                    onChanged: (value) => form.danni = value,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: skillFormTextField(
                    skill: skill,
                    form: form,
                    formIndex: formIndex,
                    label: t('Cura', 'Healing'),
                    value: form.cura,
                    onChanged: (value) => form.cura = value,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: skillFormTextField(
                    skill: skill,
                    form: form,
                    formIndex: formIndex,
                    label: t('Difesa', 'Defense'),
                    value: form.difesa,
                    onChanged: (value) => form.difesa = value,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            skillFormTextField(
              skill: skill,
              form: form,
              formIndex: formIndex,
              label: t('Note', 'Notes'),
              value: form.note,
              maxLines: 3,
              onChanged: (value) => form.note = value,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: () => usaFormaSkill(skill, skillIndex, formIndex),
                icon: const Icon(Icons.play_arrow),
                label: Text(t('Usa forma', 'Use form')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget skillFormsEditor(CharacterSkill skill, int skillIndex) {
    skill.ensureForms();
    const maxSkillForms = 12;
    final canAdd = skill.forme.length < maxSkillForms;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.account_tree, color: tertiaryColor, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                t('Forme Skill', 'Skill Forms'),
                style: TextStyle(
                  color: tertiaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              '${skill.forme.length}/$maxSkillForms',
              style: TextStyle(
                color: canAdd ? tertiaryColor : Colors.grey.shade400,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        smallInfoText(
          t(
            'Le Skill vecchie sono Forma 1. Se la Skill e equipaggiata, i comandi @ nelle forme contano una sola volta.',
            'Old Skills are Form 1. If the Skill is equipped, @ commands inside forms count once.',
          ),
          color: Colors.grey.shade300,
        ),
        const SizedBox(height: 10),
        for (int formIndex = 0; formIndex < skill.forme.length; formIndex++)
          skillFormEditorTile(skill, skillIndex, formIndex),
        if (canAdd)
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                skill.forme.add(
                  CharacterSkillForm(nome: 'Forma ${skill.forme.length + 1}'),
                );
                skill.ensureForms();
                risultato = t('Forma aggiunta.', 'Form added.');
                aggiungiLog(risultato);
              });
              programmaSalvataggio();
            },
            icon: const Icon(Icons.add),
            label: Text(t('Aggiungi forma', 'Add form')),
          ),
      ],
    );
  }

  Widget freeSkillsPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        sectionTitle(t('Skill Scritte', 'Written Skills')),
        gothicPanel(
          borderColor: tertiaryColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t('Crea Skill Libera', 'Create Free Skill'),
                style: TextStyle(
                  color: tertiaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              smallInfoText(
                t(
                  'Skill libere, tecniche, talenti, cerchi e poteri ottenuti da Titoli, oggetti o storia. Possono anche aggiungere stats, danni e difesa.',
                  'Free skills, techniques, talents, circles and powers gained from Titles, items or story. They can also add stats, damage and defense.',
                ),
              ),
              const SizedBox(height: 12),
              campoTesto(
                label: t('Nome Skill', 'Skill Name'),
                controller: skillNomeController,
                numero: false,
              ),
              const SizedBox(height: 12),
              campoTesto(
                label: t('Tipo Skill', 'Skill Type'),
                controller: skillTipoController,
                numero: false,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: campoTesto(
                      label: t('Costo', 'Cost'),
                      controller: skillCostoController,
                      numero: false,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: campoTesto(
                      label: 'Cooldown',
                      controller: skillCooldownController,
                      numero: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              campoTesto(
                label: t('Descrizione Skill', 'Skill Description'),
                controller: skillDescrizioneController,
                numero: false,
                maxLines: 5,
              ),
              const SizedBox(height: 12),
              skillBonusCreateFields(),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: creaSkill,
                style: ElevatedButton.styleFrom(
                  backgroundColor: tertiaryColor,
                  foregroundColor: tertiaryColor.computeLuminance() > 0.45
                      ? Colors.black
                      : Colors.white,
                  minimumSize: const Size.fromHeight(50),
                ),
                child: Text(t('Crea Skill', 'Create Skill')),
              ),
            ],
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 760 ? 2 : 1;
            const gap = 8.0;
            final itemWidth =
                (constraints.maxWidth - gap * (columns - 1)) / columns;

            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (int i = 0; i < skills.length; i++)
                  SizedBox(
                    width: itemWidth,
                    child: functionAnchor(
                      'free_skill_$i',
                      gothicPanel(
                        borderColor: skills[i].equipaggiata
                            ? tertiaryColor
                            : primaryColor.withValues(alpha: 0.7),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      final quickRes =
                                          skillQuickResilienzaBonus(skills[i]);
                                      final nuovaEquipaggiata =
                                          !skills[i].equipaggiata;
                                      skills[i].equipaggiata =
                                          nuovaEquipaggiata;
                                      final segno = nuovaEquipaggiata ? 1 : -1;
                                      applicaBonusSkillAttuali(
                                        skills[i],
                                        segno,
                                      );
                                      rimarginaHpDaAumentoResilienza(
                                        quickRes * segno,
                                      );
                                      aggiungiLog(
                                        '${skills[i].nome}: ${skills[i].equipaggiata ? "equipaggiata" : "rimossa"}.',
                                      );
                                    });
                                    programmaSalvataggio();
                                  },
                                  icon: Icon(
                                    skills[i].equipaggiata
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
                                    color: skills[i].equipaggiata
                                        ? tertiaryColor
                                        : Colors.grey,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    skills[i].equipaggiata
                                        ? t(
                                            'Skill equipaggiata',
                                            'Equipped skill',
                                          )
                                        : t(
                                            'Skill non equipaggiata',
                                            'Unequipped skill',
                                          ),
                                    style: TextStyle(
                                      color: skills[i].equipaggiata
                                          ? tertiaryColor
                                          : Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: t(
                                    'Copia / invia Skill',
                                    'Copy / send Skill',
                                  ),
                                  onPressed: () =>
                                      mostraDialogCopiaSkill(skills[i]),
                                  icon: Icon(Icons.send, color: primaryColor),
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      if (skills[i].equipaggiata) {
                                        applicaBonusSkillAttuali(skills[i], -1);
                                        rimarginaHpDaAumentoResilienza(
                                          -skillQuickResilienzaBonus(skills[i]),
                                        );
                                      }
                                      aggiungiLog(
                                        'Skill eliminata: ${skills[i].nome}.',
                                      );
                                      skills.removeAt(i);
                                    });
                                    programmaSalvataggio();
                                  },
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            campoModello(
                              label: t('Nome Skill', 'Skill Name'),
                              initialValue: skills[i].nome,
                              onChanged: (value) => skills[i].nome = value,
                            ),
                            const SizedBox(height: 8),
                            campoModello(
                              label: t('Tipo Skill', 'Skill Type'),
                              initialValue: skills[i].tipo,
                              onChanged: (value) {
                                skills[i].tipo = value;
                                skills[i].ensureForms();
                                skills[i].forme.first.tipo = value;
                              },
                            ),
                            const SizedBox(height: 10),
                            skillFormsEditor(skills[i], i),
                            const SizedBox(height: 10),
                            skillBonusEditFields(skills[i]),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  // =====================================================
  // TITOLI
  // =====================================================

  String titleEditorAnchorId(
    OculumTitle titolo, {
    bool trattoRazziale = false,
  }) {
    final list = trattoRazziale ? trattiRazziali : titoli;
    final index = list.indexWhere((item) => identical(item, titolo));
    if (index < 0) return 'titles_root';
    return trattoRazziale
        ? 'racial_trait_editor_$index'
        : 'title_editor_$index';
  }

  Widget plusEyeButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
    String? subtitle,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 104,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: color.withValues(alpha: 0.85),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomPaint(
                size: const Size(58, 34),
                painter: SmallPlusEyePainter(
                  primaryColor: primaryColor,
                  secondaryColor: color,
                  tertiaryColor: tertiaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget conditionalBuffPanel({
    required String title,
    required List<ConditionalBuffEntry> buffs,
    required Color color,
    bool appliesToCurrentStats = true,
  }) {
    return gothicPanel(
      borderColor: color.withValues(alpha: 0.75),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          smallInfoText(
            t(
              'Buff che si attivano solo quando una condizione è vera. Esempio: “di notte”, “contro demoni”, “quando l’Open è attiva”.',
              'Buffs that activate only when a condition is true. Example: “at night”, “against demons”, “when the Open is active”.',
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                buffs.add(
                  ConditionalBuffEntry(
                    nome: t('Nuovo Buff Condizionale', 'New Conditional Buff'),
                    descrizione: '',
                    condizione: '',
                  ),
                );
              });

              programmaSalvataggio();
            },
            icon: const Icon(Icons.add),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: color.computeLuminance() > 0.45
                  ? Colors.black
                  : Colors.white,
              minimumSize: const Size.fromHeight(44),
            ),
            label: Text(
              t('Aggiungi Buff Condizionale', 'Add Conditional Buff'),
            ),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < buffs.length; i++)
            gothicPanel(
              borderColor: buffs[i].attivo
                  ? tertiaryColor
                  : primaryColor.withValues(alpha: 0.55),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    value: buffs[i].attivo,
                    activeThumbColor: tertiaryColor,
                    title: Text(
                      buffs[i].attivo
                          ? t('Buff attivo', 'Buff active')
                          : t('Buff spento', 'Buff inactive'),
                      style: TextStyle(
                        color: buffs[i].attivo ? tertiaryColor : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      t(
                        'Quando è attivo, i bonus entrano nelle statistiche totali.',
                        'When active, bonuses are added to total stats.',
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        final deltaRes = appliesToCurrentStats
                            ? buffs[i].resilienza * (value ? 1 : -1)
                            : 0;
                        buffs[i].attivo = value;
                        rimarginaHpDaAumentoResilienza(deltaRes);
                      });

                      programmaSalvataggio();
                    },
                  ),
                  const SizedBox(height: 8),
                  campoModello(
                    label: t('Nome Buff', 'Buff Name'),
                    initialValue: buffs[i].nome,
                    onChanged: (value) => buffs[i].nome = value,
                  ),
                  const SizedBox(height: 8),
                  campoModello(
                    label: t('Condizione', 'Condition'),
                    initialValue: buffs[i].condizione,
                    onChanged: (value) => buffs[i].condizione = value,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  campoModello(
                    label: t('Descrizione', 'Description'),
                    initialValue: buffs[i].descrizione,
                    onChanged: (value) => buffs[i].descrizione = value,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: campoModello(
                          label: '+ Res',
                          initialValue: buffs[i].resilienza.toString(),
                          onChanged: (value) {
                            final nuovo = int.tryParse(value.trim()) ?? 0;
                            final deltaRes =
                                appliesToCurrentStats && buffs[i].attivo
                                ? nuovo - buffs[i].resilienza
                                : 0;
                            buffs[i].resilienza = nuovo;
                            rimarginaHpDaAumentoResilienza(deltaRes);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: campoModello(
                          label: '+ Vol',
                          initialValue: buffs[i].volonta.toString(),
                          onChanged: (value) {
                            final nuovo = int.tryParse(value.trim()) ?? 0;
                            buffs[i].volonta = nuovo;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: campoModello(
                          label: '+ Mat',
                          initialValue: buffs[i].materia.toString(),
                          onChanged: (value) {
                            final nuovo = int.tryParse(value.trim()) ?? 0;
                            buffs[i].materia = nuovo;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: campoModello(
                          label: '+ Ocu',
                          initialValue: buffs[i].oculum.toString(),
                          onChanged: (value) {
                            final nuovo = int.tryParse(value.trim()) ?? 0;
                            buffs[i].oculum = nuovo;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  campoModello(
                    label: 'Karma',
                    initialValue: buffs[i].karma.toString(),
                    onChanged: (value) {
                      buffs[i].karma = int.tryParse(value.trim()) ?? 0;
                    },
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          final deltaRes =
                              appliesToCurrentStats && buffs[i].attivo
                              ? -buffs[i].resilienza
                              : 0;
                          buffs.removeAt(i);
                          rimarginaHpDaAumentoResilienza(deltaRes);
                        });

                        programmaSalvataggio();
                      },
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget karmaTitleEditorRow({
    required int value,
    required void Function(int) onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => onChanged(-1),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7A1026),
              foregroundColor: Colors.white,
            ),
            child: const Text('-1'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            onPressed: () => onChanged(0),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('0'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            onPressed: () => onChanged(1),
            style: ElevatedButton.styleFrom(
              backgroundColor: tertiaryColor,
              foregroundColor: tertiaryColor.computeLuminance() > 0.45
                  ? Colors.black
                  : Colors.white,
            ),
            child: const Text('+1'),
          ),
        ),
      ],
    );
  }

  Widget titleCard(
    OculumTitle titolo,
    int index, {
    bool trattoRazziale = false,
  }) {
    final equipped = titolo.equipaggiato;
    final openExtraCount = titolo.openExtra.length;
    final list = trattoRazziale ? trattiRazziali : titoli;
    final titleKind = trattoRazziale
        ? t('Tratto razziale', 'Racial trait')
        : t('Titolo', 'Title');
    final sectionId =
        '${trattoRazziale ? 'racial_trait' : 'title'}_${currentSheetScrollId()}_$index';
    final expanded = _expandedFunctionSections.contains(sectionId);
    final categoryColor = trattoRazziale
        ? const Color(0xFF7EE7C8)
        : titleCategoryColor(normalizeTitleCategory(titolo.tipo));
    final borderColor = titolo.openAttiva
        ? tertiaryColor
        : equipped
        ? categoryColor
        : categoryColor.withValues(alpha: 0.55);
    final titleColor = titolo.openAttiva
        ? tertiaryColor
        : equipped
        ? categoryColor
        : Colors.white;
    final quickBonuses = titleQuickBonuses(titolo);
    final titleSubtitleParts = <String>[
      if (titolo.tipo.trim().isNotEmpty) cleanUiText(titolo.tipo),
      if (titolo.openAttiva) t('Open attiva', 'Open active'),
      if (quickBonuses.isNotEmpty)
        '${quickBonuses.length} ${t('comandi @', '@ commands')}',
    ];

    void toggleTitleEquipped() {
      setState(() {
        final runtimeRes =
            titleQuickResilienzaBonus(titolo) +
            buffCondizionaleResilienza(titolo);
        titolo.equipaggiato = !titolo.equipaggiato;
        final segno = titolo.equipaggiato ? 1 : -1;
        applicaBonusTitoloAttuali(titolo, segno);
        rimarginaHpDaAumentoResilienza(runtimeRes * segno);
        if (!titolo.equipaggiato) {
          titolo.openAttiva = false;
          for (final open in titolo.openExtra) {
            open.attiva = false;
          }
        }
        aggiungiLog(
          '${titolo.equipaggiato ? "Equipaggiato" : "Rimosso"} $titleKind: [${titolo.nome}].',
        );
      });
      programmaSalvataggio();
    }

    void deleteTitle() {
      final currentIndex = list.indexOf(titolo);
      if (currentIndex < 0) return;
      setState(() {
        _expandedFunctionSections.remove(sectionId);
        if (titolo.equipaggiato) {
          applicaBonusTitoloAttuali(titolo, -1);
          rimarginaHpDaAumentoResilienza(
            -titleQuickResilienzaBonus(titolo) -
                buffCondizionaleResilienza(titolo),
          );
        }
        aggiungiLog('$titleKind eliminato: [${titolo.nome}].');
        list.removeAt(currentIndex);
      });
      programmaSalvataggio();
    }

    void duplicateTitle() {
      final currentIndex = list.indexOf(titolo);
      if (currentIndex < 0) return;
      if (trattoRazziale && list.length >= 13) {
        setState(() {
          risultato = t(
            'Puoi avere al massimo 13 Tratti razziali.',
            'You can have at most 13 Racial Traits.',
          );
        });
        return;
      }
      final copy = copiaTitolo(titolo)
        ..nome = '${titolo.nome} - ${t('copia', 'copy')}'
        ..equipaggiato = false
        ..openAttiva = false
        ..chiaveSistema = '';
      for (final open in copy.openExtra) {
        open.attiva = false;
      }
      setState(() {
        list.insert(currentIndex + 1, copy);
        aggiungiLog('$titleKind duplicato: [${titolo.nome}].');
      });
      programmaSalvataggio();
    }

    Future<void> showTitleContextMenu(Offset position) async {
      final choice = await showMenu<String>(
        context: context,
        color: const Color(0xFF10121A),
        position: RelativeRect.fromLTRB(
          position.dx,
          position.dy,
          position.dx,
          position.dy,
        ),
        items: <PopupMenuEntry<String>>[
          PopupMenuItem<String>(
            value: 'equip',
            child: ListTile(
              leading: Icon(
                titolo.equipaggiato
                    ? Icons.remove_circle_outline
                    : Icons.check_circle_outline,
              ),
              title: Text(
                titolo.equipaggiato
                    ? t('Rimuovi equipaggiamento', 'Unequip')
                    : t('Equipaggia', 'Equip'),
              ),
            ),
          ),
          PopupMenuItem<String>(
            value: 'send',
            child: ListTile(
              leading: const Icon(Icons.send_outlined),
              title: Text(t('Copia o invia', 'Copy or send')),
            ),
          ),
          PopupMenuItem<String>(
            value: 'duplicate',
            enabled: !trattoRazziale || list.length < 13,
            child: ListTile(
              leading: const Icon(Icons.copy),
              title: Text(t('Duplica', 'Duplicate')),
            ),
          ),
          PopupMenuItem<String>(
            value: 'manual',
            child: ListTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: Text(t('Cerca nel manuale', 'Search in manual')),
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem<String>(
            value: 'delete',
            child: ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(t('Elimina', 'Delete')),
            ),
          ),
        ],
      );
      if (!mounted || choice == null || !list.contains(titolo)) return;
      switch (choice) {
        case 'equip':
          toggleTitleEquipped();
          break;
        case 'send':
          await mostraDialogCopiaTitolo(titolo);
          break;
        case 'duplicate':
          duplicateTitle();
          break;
        case 'manual':
          openManualForQuickTerm(titolo.nome);
          break;
        case 'delete':
          deleteTitle();
          break;
      }
    }

    final card = gothicPanel(
      borderColor: borderColor,
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: sheetExpansionKey(sectionId),
          initiallyExpanded: expanded,
          onExpansionChanged: (value) {
            if (!mounted) return;
            setState(() {
              if (value) {
                _expandedFunctionSections.add(sectionId);
              } else {
                _expandedFunctionSections.remove(sectionId);
              }
            });
          },
          tilePadding: const EdgeInsets.fromLTRB(10, 4, 8, 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
          iconColor: borderColor,
          collapsedIconColor: borderColor,
          leading: Tooltip(
            message: equipped
                ? t('Rimuovi Titolo', 'Unequip Title')
                : t('Equipaggia Titolo', 'Equip Title'),
            child: IconButton(
              onPressed: toggleTitleEquipped,
              icon: Icon(
                equipped ? Icons.check_circle : Icons.radio_button_unchecked,
                color: equipped ? categoryColor : Colors.grey,
              ),
            ),
          ),
          title: Text(
            '[${titolo.nome}]',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
          ),
          subtitle: titleSubtitleParts.isEmpty
              ? null
              : Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    titleSubtitleParts.join(' - '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: titleColor.withValues(alpha: 0.78),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (titolo.chiaveSistema.isNotEmpty)
                Tooltip(
                  message: t(
                    'Creato automaticamente dal sistema delle Art.',
                    'Automatically created by the Art system.',
                  ),
                  child: Icon(Icons.auto_awesome, color: tertiaryColor),
                ),
              IconButton(
                tooltip: t('Copia / invia Titolo', 'Copy / send Title'),
                onPressed: () => mostraDialogCopiaTitolo(titolo),
                icon: Icon(Icons.send, color: primaryColor),
              ),
              IconButton(
                tooltip: t('Elimina Titolo', 'Delete Title'),
                onPressed: deleteTitle,
                icon: const Icon(Icons.delete, color: Colors.redAccent),
              ),
              Icon(Icons.expand_more, color: borderColor),
            ],
          ),
          children: expanded
              ? [
                  titleQuickCombatLine(titolo),
                  if (quickBonuses.isNotEmpty) const SizedBox(height: 8),
                  const SizedBox(height: 10),
                  campoModello(
                    label: t('Nome Titolo', 'Title Name'),
                    initialValue: titolo.nome,
                    onChanged: (value) => titolo.nome = value,
                  ),
                  const SizedBox(height: 8),
                  campoModello(
                    label: t('Tipo Titolo', 'Title Type'),
                    initialValue: titolo.tipo,
                    onChanged: (value) => titolo.tipo = value,
                  ),
                  const SizedBox(height: 8),
                  campoModello(
                    label: t('Ottenimento', 'Obtained'),
                    initialValue: titolo.ottenimento,
                    onChanged: (value) => titolo.ottenimento = value,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 8),
                  campoModello(
                    label: t('Leggenda', 'Legend'),
                    initialValue: titolo.leggenda,
                    onChanged: (value) => titolo.leggenda = value,
                    maxLines: 5,
                    helper: t(
                      'Scrivi la storia, la memoria o la diceria legata a questo Titolo.',
                      'Write the story, memory, or tale connected to this Title.',
                    ),
                  ),
                  const SizedBox(height: 8),
                  campoModello(
                    label: t('Buff @ Titolo', 'Title @ Buff'),
                    initialValue: titolo.buff,
                    onChanged: (value) => titolo.buff = value,
                    maxLines: 3,
                    helper:
                        '@HP+5 @HPTemp+Vol1/6 @ScudoOculum+5 @TiroAttacco+1',
                  ),
                  const SizedBox(height: 8),
                  campoModello(
                    label: t('Skill aggiunta', 'Added Skill'),
                    initialValue: titolo.skill,
                    onChanged: (value) => titolo.skill = value,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 8),
                  campoModello(
                    label: t('Punto Cieco', 'Blind Spot'),
                    initialValue: titolo.puntoCieco,
                    onChanged: (value) => titolo.puntoCieco = value,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 8),
                  campoModello(
                    label: t('Richiede / Evoluzione', 'Requires / Evolution'),
                    initialValue: titolo.richiede,
                    onChanged: (value) => titolo.richiede = value,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      statChip('RES', titolo.resilienza),
                      statChip('VOL', titolo.volonta),
                      statChip('MAT', titolo.materia),
                      statChip('OCU', titolo.oculum),
                      statChip('KARMA', titolo.karma),
                    ],
                  ),
                  const SizedBox(height: 16),
                  titleQuickCommandChips(titolo),
                  if (quickBonuses.isNotEmpty) const SizedBox(height: 12),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: campoModello(
                          label: '+ Res',
                          initialValue: titolo.resilienza.toString(),
                          onChanged: (value) {
                            final nuovo = int.tryParse(value.trim()) ?? 0;
                            if (titolo.equipaggiato) {
                              applicaBonusAttuali(
                                resilienza: nuovo - titolo.resilienza,
                              );
                            }
                            titolo.resilienza = nuovo;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: campoModello(
                          label: '+ Vol',
                          initialValue: titolo.volonta.toString(),
                          onChanged: (value) {
                            final nuovo = int.tryParse(value.trim()) ?? 0;
                            if (titolo.equipaggiato) {
                              applicaBonusAttuali(
                                volonta: nuovo - titolo.volonta,
                              );
                            }
                            titolo.volonta = nuovo;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: campoModello(
                          label: '+ Mat',
                          initialValue: titolo.materia.toString(),
                          onChanged: (value) {
                            final nuovo = int.tryParse(value.trim()) ?? 0;
                            if (titolo.equipaggiato) {
                              applicaBonusAttuali(
                                materia: nuovo - titolo.materia,
                              );
                            }
                            titolo.materia = nuovo;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: campoModello(
                          label: '+ Ocu',
                          initialValue: titolo.oculum.toString(),
                          onChanged: (value) {
                            final nuovo = int.tryParse(value.trim()) ?? 0;
                            if (titolo.equipaggiato) {
                              applicaBonusAttuali(
                                oculum: nuovo - titolo.oculum,
                              );
                            }
                            titolo.oculum = nuovo;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t('Karma Titolo', 'Title Karma'),
                    style: TextStyle(
                      color: tertiaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  karmaTitleEditorRow(
                    value: titolo.karma,
                    onChanged: (value) {
                      setState(() {
                        titolo.karma = value;
                      });
                      programmaSalvataggio();
                    },
                  ),
                  const SizedBox(height: 12),
                  conditionalBuffPanel(
                    title: t(
                      'Buff Condizionali del Titolo',
                      'Title Conditional Buffs',
                    ),
                    buffs: titolo.titleConditionalBuffs,
                    color: tertiaryColor,
                    appliesToCurrentStats: titolo.equipaggiato,
                  ),
                  Divider(color: tertiaryColor.withValues(alpha: 0.5)),
                  SwitchListTile(
                    value: titolo.evoluto,
                    activeThumbColor: tertiaryColor,
                    title: Text(t('Evoluto', 'Evolved')),
                    subtitle: Text(
                      t(
                        'Un Titolo Evoluto può avere una Open e Skill extra.',
                        'An Evolved Title can have an Open and extra Skills.',
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        if (!value) disattivaOpenDelTitolo(titolo);
                        titolo.evoluto = value;
                        if (value) {
                          final expText = assegnaEsperienzaOpenTitolo(titolo);
                          if (expText.isNotEmpty) {
                            risultato = expText.trim();
                            aggiungiLog(risultato);
                          }
                        }
                      });
                      programmaSalvataggio();
                    },
                  ),
                  if (titolo.evoluto) ...[
                    campoModello(
                      label: t('Nome Open', 'Open Name'),
                      initialValue: titolo.openName,
                      onChanged: (value) => titolo.openName = value,
                    ),
                    const SizedBox(height: 8),
                    campoModello(
                      label: t('Descrizione Open', 'Open Description'),
                      initialValue: titolo.openDescription,
                      onChanged: (value) => titolo.openDescription = value,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 8),
                    campoModello(
                      label: t('Open Buff @', 'Open @ Buff'),
                      initialValue: titolo.openBuff,
                      onChanged: (value) => titolo.openBuff = value,
                      maxLines: 2,
                      helper: '@Iniziativa+5 @TiroDifesa+1 @Danni+Vol/2 Fuoco',
                    ),
                    const SizedBox(height: 8),
                    campoModello(
                      label: t('Open Skill', 'Open Skill'),
                      initialValue: titolo.openSkill,
                      onChanged: (value) => titolo.openSkill = value,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => usaOpen(titolo),
                      icon: Icon(
                        titolo.openAttiva
                            ? Icons.lock_open
                            : Icons.auto_awesome,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: titolo.openAttiva
                            ? tertiaryColor
                            : secondaryColor,
                        foregroundColor: titolo.openAttiva
                            ? Colors.black
                            : Colors.white,
                        minimumSize: const Size.fromHeight(46),
                      ),
                      label: Text(
                        titolo.openAttiva
                            ? t('Open Attiva', 'Open Active')
                            : t('Usa Open', 'Use Open'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    conditionalBuffPanel(
                      title: t(
                        'Buff Condizionali della Open',
                        'Open Conditional Buffs',
                      ),
                      buffs: titolo.openConditionalBuffs,
                      color: primaryColor,
                      appliesToCurrentStats:
                          titolo.equipaggiato && titolo.openAttiva,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        plusEyeButton(
                          label: t('Aggiungi Open', 'Add Open'),
                          subtitle: '$openExtraCount/12',
                          color: tertiaryColor,
                          onTap: () => aggiungiOpenExtra(titolo),
                        ),
                        const SizedBox(width: 10),
                        plusEyeButton(
                          label: t('Aggiungi Skill', 'Add Skill'),
                          color: primaryColor,
                          onTap: () => aggiungiSkillExtraTitolo(titolo),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    for (int i = 0; i < titolo.openExtra.length; i++)
                      gothicPanel(
                        borderColor: titolo.openExtra[i].attiva
                            ? tertiaryColor
                            : primaryColor.withValues(alpha: 0.6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            campoModello(
                              label: t('Nome Open Extra', 'Extra Open Name'),
                              initialValue: titolo.openExtra[i].nome,
                              onChanged: (value) =>
                                  titolo.openExtra[i].nome = value,
                            ),
                            const SizedBox(height: 8),
                            campoModello(
                              label: t('Descrizione', 'Description'),
                              initialValue: titolo.openExtra[i].descrizione,
                              onChanged: (value) {
                                titolo.openExtra[i].descrizione = value;
                              },
                              maxLines: 2,
                            ),
                            const SizedBox(height: 8),
                            campoModello(
                              label: t(
                                'Buff @ Open Extra',
                                'Extra Open @ Buff',
                              ),
                              initialValue: titolo.openExtra[i].openBuff,
                              onChanged: (value) {
                                titolo.openExtra[i].openBuff = value;
                              },
                              maxLines: 2,
                              helper: '@HP+5 @Scudo+3 @ScudoOculum+5',
                            ),
                            const SizedBox(height: 8),
                            campoModello(
                              label: t('Open Skill', 'Open Skill'),
                              initialValue: titolo.openExtra[i].openSkill,
                              onChanged: (value) {
                                titolo.openExtra[i].openSkill = value;
                              },
                              maxLines: 2,
                            ),
                            const SizedBox(height: 10),
                            conditionalBuffPanel(
                              title: t(
                                'Buff Condizionali Open Extra',
                                'Extra Open Conditional Buffs',
                              ),
                              buffs: titolo.openExtra[i].conditionalBuffs,
                              color: tertiaryColor,
                              appliesToCurrentStats:
                                  titolo.equipaggiato &&
                                  titolo.openExtra[i].attiva,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => usaOpen(
                                      titolo,
                                      openExtra: titolo.openExtra[i],
                                    ),
                                    icon: Icon(
                                      titolo.openExtra[i].attiva
                                          ? Icons.lock_open
                                          : Icons.auto_awesome,
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          titolo.openExtra[i].attiva
                                          ? tertiaryColor
                                          : secondaryColor,
                                      foregroundColor:
                                          titolo.openExtra[i].attiva
                                          ? Colors.black
                                          : Colors.white,
                                    ),
                                    label: Text(
                                      titolo.openExtra[i].attiva
                                          ? t('Attiva', 'Active')
                                          : t('Usa', 'Use'),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      if (titolo.openExtra[i].attiva &&
                                          titolo.equipaggiato) {
                                        rimarginaHpDaAumentoResilienza(
                                          -extraOpenRuntimeResilienzaBonus(
                                            titolo.openExtra[i],
                                          ),
                                        );
                                      }
                                      titolo.openExtra.removeAt(i);
                                      aggiungiLog(
                                        'Open extra rimossa da [${titolo.nome}].',
                                      );
                                    });
                                    programmaSalvataggio();
                                  },
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    for (int i = 0; i < titolo.skillExtra.length; i++)
                      gothicPanel(
                        borderColor: tertiaryColor.withValues(alpha: 0.65),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            campoModello(
                              label: t('Nome Skill Extra', 'Extra Skill Name'),
                              initialValue: titolo.skillExtra[i].nome,
                              onChanged: (value) =>
                                  titolo.skillExtra[i].nome = value,
                            ),
                            const SizedBox(height: 8),
                            campoModello(
                              label: t(
                                'Descrizione Skill Extra',
                                'Extra Skill Description',
                              ),
                              initialValue: titolo.skillExtra[i].descrizione,
                              onChanged: (value) {
                                titolo.skillExtra[i].descrizione = value;
                              },
                              maxLines: 3,
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                onPressed: () {
                                  setState(() {
                                    titolo.skillExtra.removeAt(i);
                                    aggiungiLog(
                                      'Skill extra rimossa da [${titolo.nome}].',
                                    );
                                  });
                                  programmaSalvataggio();
                                },
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ]
              : const <Widget>[],
        ),
      ),
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onSecondaryTapDown: (details) =>
          showTitleContextMenu(details.globalPosition),
      onLongPressStart: (details) =>
          showTitleContextMenu(details.globalPosition),
      child: card,
    );
  }

  Widget createTitlePanel() {
    final sectionId = 'titles_create_form';
    final expanded = _expandedFunctionSections.contains(sectionId);
    const createColor = Color(0xFF7EE7C8);

    return gothicPanel(
      borderColor: createColor,
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: sheetExpansionKey(sectionId),
          initiallyExpanded: expanded,
          onExpansionChanged: (value) {
            if (!mounted) return;
            setState(() {
              if (value) {
                _expandedFunctionSections.add(sectionId);
              } else {
                _expandedFunctionSections.remove(sectionId);
              }
            });
          },
          tilePadding: const EdgeInsets.fromLTRB(12, 4, 10, 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
          iconColor: createColor,
          collapsedIconColor: createColor,
          leading: const Icon(Icons.add_circle_outline, color: createColor),
          title: Text(
            t('Crea Nuovo Titolo', 'Create New Title'),
            style: TextStyle(
              color: createColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            t(
              'I Titoli sono memoria, reputazione, ferite, benedizioni e identita. Possono dare bonus, malus, skill, Open e Punto Cieco.',
              'Titles are memory, reputation, wounds, blessings and identity. They can grant bonuses, penalties, skills, Opens and Blind Spots.',
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey.shade300,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          children: expanded
              ? [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      smallInfoText(
                        t(
                          'I Titoli sono memoria, reputazione, ferite, benedizioni e identità. Possono dare bonus, malus, skill, Open e Punto Cieco.',
                          'Titles are memory, reputation, wounds, blessings and identity. They can grant bonuses, penalties, skills, Opens and Blind Spots.',
                        ),
                      ),
                      const SizedBox(height: 12),
                      campoTesto(
                        label: t('Nome Titolo', 'Title Name'),
                        controller: titoloNomeController,
                        numero: false,
                      ),
                      const SizedBox(height: 12),
                      campoTesto(
                        label: t('Tipo', 'Type'),
                        controller: titoloTipoController,
                        numero: false,
                      ),
                      const SizedBox(height: 6),
                      smallInfoText(
                        t(
                          'Categorie regole: ${titleCategoryOrder.join(', ')}. Se Tipo è Tratto razziale, Razza o Sottorazza, viene salvato nei Tratti Razziali.',
                          'Rule categories: ${titleCategoryOrder.join(', ')}. If Type is Racial Trait, Race or Subrace, it is saved into Racial Traits.',
                        ),
                      ),
                      const SizedBox(height: 12),
                      campoTesto(
                        label: t('Ottenimento', 'Obtained'),
                        controller: titoloOttenimentoController,
                        numero: false,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      campoTesto(
                        label: t('Leggenda', 'Legend'),
                        controller: titoloLeggendaController,
                        numero: false,
                        maxLines: 5,
                        helper: t(
                          'Scrivi la storia, la memoria o la diceria legata a questo Titolo.',
                          'Write the story, memory, or tale connected to this Title.',
                        ),
                      ),
                      const SizedBox(height: 12),
                      campoTesto(
                        label: t('Buff @ Titolo', 'Title @ Buff'),
                        controller: titoloBuffController,
                        numero: false,
                        maxLines: 3,
                        helper:
                            '@HP+5 @HPTemp+Vol1/6 @ScudoOculum+5 @TiroAttacco+1',
                      ),
                      const SizedBox(height: 12),
                      campoTesto(
                        label: t('Skill Aggiunta', 'Added Skill'),
                        controller: titoloSkillController,
                        numero: false,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      campoTesto(
                        label: t('Punto Cieco', 'Blind Spot'),
                        controller: titoloPuntoCiecoController,
                        numero: false,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      campoTesto(
                        label: t(
                          'Richiede / Evoluzione',
                          'Requires / Evolution',
                        ),
                        controller: titoloRichiedeController,
                        numero: false,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: campoTesto(
                              label: '+ Res',
                              controller: titoloResController,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: campoTesto(
                              label: '+ Vol',
                              controller: titoloVolController,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: campoTesto(
                              label: '+ Mat',
                              controller: titoloMatController,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: campoTesto(
                              label: '+ Ocu',
                              controller: titoloOcuController,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        t(
                          'Karma del Titolo: ${titoloKarmaController.text}',
                          'Title Karma: ${titoloKarmaController.text}',
                        ),
                        style: TextStyle(
                          color: coloreTestoKarma(
                            leggiKarmaTitolo(titoloKarmaController),
                          ),
                          fontWeight: FontWeight.bold,
                          shadows: ombraKarma(
                            leggiKarmaTitolo(titoloKarmaController),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      karmaTitleEditorRow(
                        value: leggiKarmaTitolo(titoloKarmaController),
                        onChanged: (value) {
                          modificaKarmaTitolo(titoloKarmaController, value);
                        },
                      ),
                      const SizedBox(height: 14),
                      SwitchListTile(
                        value: nuovoTitoloEvoluto,
                        activeThumbColor: tertiaryColor,
                        title: Text(
                          t(
                            'Titolo Evoluto con Open',
                            'Evolved Title with Open',
                          ),
                        ),
                        subtitle: Text(
                          t(
                            'Attiva se il Titolo ha già una forma evoluta o una Open.',
                            'Enable if the Title already has an evolved form or an Open.',
                          ),
                        ),
                        onChanged: (value) {
                          setState(() => nuovoTitoloEvoluto = value);
                          programmaSalvataggio();
                        },
                      ),
                      if (nuovoTitoloEvoluto) ...[
                        campoTesto(
                          label: t('Nome Open', 'Open Name'),
                          controller: titoloOpenNameController,
                          numero: false,
                        ),
                        const SizedBox(height: 12),
                        campoTesto(
                          label: t('Descrizione Open', 'Open Description'),
                          controller: titoloOpenDescriptionController,
                          numero: false,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),
                        campoTesto(
                          label: t('Open Buff @', 'Open @ Buff'),
                          controller: titoloOpenBuffController,
                          numero: false,
                          maxLines: 3,
                          helper:
                              '@Iniziativa+5 @TiroDifesa+1 @Danni+Vol/2 Fuoco',
                        ),
                        const SizedBox(height: 12),
                        campoTesto(
                          label: t('Open Skill', 'Open Skill'),
                          controller: titoloOpenSkillController,
                          numero: false,
                          maxLines: 3,
                        ),
                      ],
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: creaTitolo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: tertiaryColor,
                          foregroundColor:
                              tertiaryColor.computeLuminance() > 0.45
                              ? Colors.black
                              : Colors.white,
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: Text(t('Crea Titolo', 'Create Title')),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: trattiRazziali.length >= 13
                            ? null
                            : creaTrattoRazziale,
                        icon: const Icon(Icons.diversity_3),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor:
                              primaryColor.computeLuminance() > 0.45
                              ? Colors.black
                              : Colors.white,
                          minimumSize: const Size.fromHeight(48),
                        ),
                        label: Text(
                          t(
                            'Crea come Tratto Razziale (${trattiRazziali.length}/13)',
                            'Create as Racial Trait (${trattiRazziali.length}/13)',
                          ),
                        ),
                      ),
                    ],
                  ),
                ]
              : const <Widget>[],
        ),
      ),
    );
  }

  Widget racialTraitsPanel() {
    return functionAnchor(
      'titles_racial_traits',
      gothicPanel(
        borderColor: const Color(0xFF7EE7C8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.diversity_3, color: Color(0xFF7EE7C8)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t(
                      'Tratti razziali: razze e sottorazze',
                      'Racial traits: races and subraces',
                    ),
                    style: const TextStyle(
                      color: Color(0xFF7EE7C8),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  '${trattiRazziali.length}/13',
                  style: const TextStyle(
                    color: Color(0xFF7EE7C8),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            smallInfoText(
              t(
                'Funzionano come Titoli veri: se equipaggiati aggiungono bonus, comandi @, Open e buff condizionali, ma usano 13 slot separati dai Titoli normali.',
                'They work like real Titles: when equipped they add bonuses, @ commands, Opens and conditional buffs, but use 13 slots separate from normal Titles.',
              ),
            ),
            const SizedBox(height: 8),
            smallInfoText(
              t(
                'La Razza visibile nella Scheda usa il campo Razza; se resta vuoto, mostra il primo Tratto razziale inserito.',
                'The visible Race on the Sheet uses the Race field; if empty, it shows the first inserted Racial Trait.',
              ),
              color: primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget titlesPageEfficient() {
    final equipaggiati = titoli.where((x) => x.equipaggiato).length;
    final openAttive =
        titoli.where((x) => x.openAttiva).length +
        titoli.fold<int>(
          0,
          (somma, titolo) =>
              somma + titolo.openExtra.where((open) => open.attiva).length,
        );
    final titleIndicesByCategory = <String, List<int>>{
      for (final category in titleCategoryOrder) category: <int>[],
    };

    for (int i = 0; i < titoli.length; i++) {
      final category = normalizeTitleCategory(titoli[i].tipo);
      titleIndicesByCategory.putIfAbsent(category, () => <int>[]).add(i);
    }

    final fullWidthIndexes = <int>{0, 3, 4, 5};
    final builders = <WidgetBuilder>[
      (_) => functionAnchor('titles_root', sectionTitle(t('Titoli', 'Titles'))),
      (_) => titlesSummaryPanelEfficient(equipaggiati, openAttive),
      (_) => functionAnchor(
        'titles_quick_commands',
        titlesQuickCommandsPanelEfficient(),
      ),
      (_) => titlesFateCheckPanelEfficient(),
      (_) => functionAnchor('titles_create', createTitlePanel()),
      (_) => racialTraitsPanel(),
    ];

    if (trattiRazziali.isEmpty) {
      builders.add(
        (_) => Padding(
          padding: const EdgeInsets.only(left: 6, right: 6, bottom: 10),
          child: smallInfoText(
            t('Nessun tratto razziale inserito.', 'No racial trait inserted.'),
          ),
        ),
      );
    } else {
      for (int i = 0; i < trattiRazziali.length; i++) {
        final traitIndex = i;
        builders.add(
          (_) => RepaintBoundary(
            key: ValueKey('racial_trait_${currentSheetScrollId()}_$traitIndex'),
            child: functionAnchor(
              titleEditorAnchorId(
                trattiRazziali[traitIndex],
                trattoRazziale: true,
              ),
              titleCard(
                trattiRazziali[traitIndex],
                traitIndex,
                trattoRazziale: true,
              ),
            ),
          ),
        );
      }
    }

    for (final category in titleCategoryOrder) {
      final categoryName = category;
      final indexes = titleIndicesByCategory[categoryName] ?? const <int>[];
      fullWidthIndexes.add(builders.length);
      builders.add(
        (_) => functionAnchor(
          'titles_category_${titleCategorySlug(categoryName)}',
          titleCategoryHeader(categoryName, indexes.length),
        ),
      );

      if (indexes.isEmpty) {
        builders.add(
          (_) => Padding(
            padding: const EdgeInsets.only(left: 6, right: 6, bottom: 10),
            child: smallInfoText(
              t(
                'Nessun titolo in questa categoria.',
                'No title in this category.',
              ),
            ),
          ),
        );
      } else {
        for (final index in indexes) {
          final titleIndex = index;
          builders.add(
            (_) => RepaintBoundary(
              key: ValueKey('title_card_${currentSheetScrollId()}_$titleIndex'),
              child: functionAnchor(
                titleEditorAnchorId(titoli[titleIndex]),
                titleCard(titoli[titleIndex], titleIndex),
              ),
            ),
          );
        }
      }
    }

    return responsivePageBuilder(
      pageKey: 'titles',
      builders: builders,
      fullWidthIndexes: fullWidthIndexes,
      maxColumns: 2,
      minColumnWidth: 380,
      cacheExtent: 420,
    );
  }

  Widget titlesSummaryPanelEfficient(int equipaggiati, int openAttive) {
    return gothicPanel(
      borderColor: primaryColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          smallInfoText(
            t(
              'Apri un Titolo dalla tendina per modificarlo. Usa l\'icona a sinistra per equipaggiarlo o rimuoverlo. I Titoli equipaggiati sommano i loro bonus alle statistiche totali.',
              'Open a Title dropdown to edit it. Use the icon on the left to equip or remove it. Equipped Titles add their bonuses to total stats.',
            ),
          ),
          const SizedBox(height: 6),
          smallInfoText(
            t(
              'Regola fight: i Titoli non si cambiano durante un fight; cio che e stato consumato o attivato resta contato fino alla fine.',
              'Fight rule: Titles cannot be changed during a fight; anything consumed or activated remains counted until the end.',
            ),
            color: tertiaryColor,
          ),
          const SizedBox(height: 10),
          Text(
            '${t('Titoli indossati', 'Equipped titles')}: $equipaggiati / ${titoli.length}',
          ),
          const SizedBox(height: 8),
          Text('${t('Open attive', 'Active Opens')}: $openAttive'),
          const SizedBox(height: 8),
          Text(
            '${t('Buff attivi', 'Active buffs')}: '
            'RES ${buffResilienza() >= 0 ? '+' : ''}${buffResilienza()}   '
            'VOL ${buffVolonta() >= 0 ? '+' : ''}${buffVolonta()}   '
            'MAT ${buffMateria() >= 0 ? '+' : ''}${buffMateria()}   '
            'OCU ${buffOculum() >= 0 ? '+' : ''}${buffOculum()}   '
            'KARMA ${karmaTitoli() >= 0 ? '+' : ''}${karmaTitoli()}',
            style: TextStyle(color: tertiaryColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget titlesQuickCommandsPanelEfficient() {
    return gothicPanel(
      borderColor: tertiaryColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('Comandi rapidi Titoli', 'Title quick commands'),
            style: TextStyle(
              color: tertiaryColor,
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 8),
          smallInfoText(
            '@VC+10, @Difesa+15, @Danni-5, @Scudo+10, @CM-2, @Res+1, @Vol+1, @Mat+1, @Ocu+1',
            color: primaryColor,
          ),
          const SizedBox(height: 6),
          smallInfoText(
            t(
              'I comandi vengono applicati solo dai Titoli equipaggiati. Open e buff condizionali valgono quando sono attivi.',
              'Commands apply only from equipped Titles. Opens and conditional buffs count when active.',
            ),
          ),
        ],
      ),
    );
  }

  Widget titlesFateCheckPanelEfficient() {
    final fateColor = titleCategoryColor('Titoli del Fato');
    return gothicPanel(
      borderColor: fateColor,
      child: ElevatedButton.icon(
        onPressed: controllaTitoliDelFatoAutomatici,
        icon: const Icon(Icons.auto_awesome),
        style: ElevatedButton.styleFrom(
          backgroundColor: fateColor,
          foregroundColor: fateColor.computeLuminance() > 0.45
              ? Colors.black
              : Colors.white,
          minimumSize: const Size.fromHeight(48),
        ),
        label: Text(
          t(
            'Controlla Titoli del Fato dalle Art',
            'Check Fate Titles from Arts',
          ),
        ),
      ),
    );
  }

  Widget titlesPage() {
    final equipaggiati = titoli.where((x) => x.equipaggiato).length;
    final openAttive =
        titoli.where((x) => x.openAttiva).length +
        titoli.fold(
          0,
          (somma, titolo) =>
              somma + titolo.openExtra.where((open) => open.attiva).length,
        );
    final titleIndicesByCategory = <String, List<int>>{
      for (final category in titleCategoryOrder) category: <int>[],
    };

    for (int i = 0; i < titoli.length; i++) {
      final category = normalizeTitleCategory(titoli[i].tipo);
      titleIndicesByCategory.putIfAbsent(category, () => <int>[]).add(i);
    }

    return responsivePageList(
      pageKey: 'titles',
      maxColumns: 2,
      minColumnWidth: 350,
      fullWidthIndexes: const <int>{0, 6},
      children: [
        functionAnchor('titles_root', sectionTitle(t('Titoli', 'Titles'))),
        gothicPanel(
          borderColor: primaryColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              smallInfoText(
                t(
                  'Apri un Titolo dalla tendina per modificarlo. Usa l\'icona a sinistra per equipaggiarlo o rimuoverlo. I Titoli equipaggiati sommano i loro bonus alle statistiche totali.',
                  'Open a Title dropdown to edit it. Use the icon on the left to equip or remove it. Equipped Titles add their bonuses to total stats.',
                ),
              ),
              const SizedBox(height: 6),
              smallInfoText(
                t(
                  'Regola fight: i Titoli non si cambiano durante un fight; cio che e stato consumato o attivato resta contato fino alla fine.',
                  'Fight rule: Titles cannot be changed during a fight; anything consumed or activated remains counted until the end.',
                ),
                color: tertiaryColor,
              ),
              const SizedBox(height: 10),
              Text(
                '${t('Titoli indossati', 'Equipped titles')}: $equipaggiati / ${titoli.length}',
              ),
              const SizedBox(height: 8),
              Text('${t('Open attive', 'Active Opens')}: $openAttive'),
              const SizedBox(height: 8),
              Text(
                '${t('Buff attivi', 'Active buffs')}: '
                'RES ${buffResilienza() >= 0 ? '+' : ''}${buffResilienza()}   '
                'VOL ${buffVolonta() >= 0 ? '+' : ''}${buffVolonta()}   '
                'MAT ${buffMateria() >= 0 ? '+' : ''}${buffMateria()}   '
                'OCU ${buffOculum() >= 0 ? '+' : ''}${buffOculum()}   '
                'KARMA ${karmaTitoli() >= 0 ? '+' : ''}${karmaTitoli()}',
                style: TextStyle(
                  color: tertiaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        functionAnchor(
          'titles_quick_commands',
          gothicPanel(
            borderColor: tertiaryColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('Comandi rapidi Titoli', 'Title quick commands'),
                  style: TextStyle(
                    color: tertiaryColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 8),
                smallInfoText(
                  '@VC+10, @Difesa+15, @Danni-5, @Scudo+10, @CM-2, @Res+1, @Vol+1, @Mat+1, @Ocu+1',
                  color: primaryColor,
                ),
                const SizedBox(height: 6),
                smallInfoText(
                  t(
                    'I comandi vengono applicati solo dai Titoli equipaggiati. Open e buff condizionali valgono quando sono attivi.',
                    'Commands apply only from equipped Titles. Opens and conditional buffs count when active.',
                  ),
                ),
              ],
            ),
          ),
        ),
        gothicPanel(
          borderColor: tertiaryColor,
          child: ElevatedButton.icon(
            onPressed: controllaTitoliDelFatoAutomatici,
            icon: const Icon(Icons.auto_awesome),
            style: ElevatedButton.styleFrom(
              backgroundColor: tertiaryColor,
              foregroundColor: tertiaryColor.computeLuminance() > 0.45
                  ? Colors.black
                  : Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
            label: Text(
              t(
                'Controlla Titoli del Fato dalle Art',
                'Check Fate Titles from Arts',
              ),
            ),
          ),
        ),
        functionAnchor('titles_create', createTitlePanel()),
        racialTraitsPanel(),
        if (trattiRazziali.isEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 6, right: 6, bottom: 10),
            child: smallInfoText(
              t(
                'Nessun tratto razziale inserito.',
                'No racial trait inserted.',
              ),
            ),
          )
        else
          for (int i = 0; i < trattiRazziali.length; i++)
            functionAnchor(
              titleEditorAnchorId(trattiRazziali[i], trattoRazziale: true),
              titleCard(trattiRazziali[i], i, trattoRazziale: true),
            ),
        for (final category in titleCategoryOrder) ...[
          functionAnchor(
            'titles_category_${titleCategorySlug(category)}',
            titleCategoryHeader(
              category,
              titleIndicesByCategory[category]?.length ?? 0,
            ),
          ),
          if ((titleIndicesByCategory[category] ?? const <int>[]).isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 6, right: 6, bottom: 10),
              child: smallInfoText(
                t(
                  'Nessun titolo in questa categoria.',
                  'No title in this category.',
                ),
              ),
            )
          else
            for (final index in titleIndicesByCategory[category]!)
              functionAnchor(
                titleEditorAnchorId(titoli[index]),
                titleCard(titoli[index], index),
              ),
        ],
      ],
    );
  }

  // =====================================================
  // INVENTARIO
  // =====================================================

  Widget inventoryFieldGrid(List<Widget> children, {double minWidth = 180}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = max(1, constraints.maxWidth ~/ minWidth);
        const spacing = 8.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }

  Widget inventoryModeToggle({
    required String label,
    required String subtitle,
    required bool value,
    required IconData icon,
    required Color color,
    required ValueChanged<bool> onChanged,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => onChanged(!value),
        child: Ink(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: value
                ? color.withValues(alpha: 0.16)
                : const Color(0xFF080A12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: value ? color : primaryColor.withValues(alpha: 0.42),
            ),
          ),
          child: Row(
            children: [
              Icon(value ? Icons.check_circle : icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cleanUiText(label),
                      style: TextStyle(
                        color: value ? color : Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cleanUiText(subtitle),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 11,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String itemCombatLabel(InventoryItem item) {
    if (item.arma && item.protegge) {
      return item.equipaggiata
          ? t('Arma / Protezione equipaggiata', 'Equipped weapon / protection')
          : t('Arma / Protezione', 'Weapon / protection');
    }
    if (item.arma) {
      return item.equipaggiata
          ? t('Arma equipaggiata', 'Equipped weapon')
          : t('Arma non equipaggiata', 'Unequipped weapon');
    }
    if (item.protegge) {
      return item.equipaggiata
          ? t('Protezione equipaggiata', 'Equipped protection')
          : t('Protezione non equipaggiata', 'Unequipped protection');
    }
    return t('Oggetto', 'Item');
  }

  Widget inventoryPageEfficient() {
    final builders = <WidgetBuilder>[
      (_) => functionAnchor(
        'inventory_root',
        sectionTitle(t('Inventario', 'Inventory')),
      ),
      (_) => inventoryQuickDropdownPanel(),
      (_) => inventoryCapacityPanelEfficient(),
      (_) => inventoryAddItemPanelEfficient(),
    ];

    for (int i = 0; i < inventario.length; i++) {
      final itemIndex = i;
      builders.add(
        (_) => RepaintBoundary(
          key: ValueKey('inventory_item_${currentSheetScrollId()}_$itemIndex'),
          child: inventoryItemCardEfficient(itemIndex),
        ),
      );
    }

    return responsivePageBuilder(
      pageKey: 'inventory',
      builders: builders,
      fullWidthIndexes: const <int>{0},
      maxColumns: 2,
      minColumnWidth: 360,
      cacheExtent: 420,
    );
  }

  Widget inventoryCapacityPanelEfficient() {
    final maxPeso = pesoMassimo();
    final usato = pesoUsato();
    final rimasto = pesoRimanente();
    final ratio = maxPeso <= 0 ? 0.0 : (usato / maxPeso).clamp(0.0, 1.0);

    final pesoColor = ratio < 0.6
        ? Colors.greenAccent
        : ratio < 0.9
        ? tertiaryColor
        : Colors.redAccent;

    return gothicPanel(
      borderColor: pesoColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('Capacita: Volonta Totale x 3 kg', 'Capacity: Total Will x 3 kg'),
          ),
          const SizedBox(height: 8),
          smallInfoText(
            t(
              'Oggetti, armi, armature e scudi sono uniti: puoi segnare se danneggiano, proteggono o entrambe le cose. Se equipaggiati, danno bonus a Danno, Difesa e Scudo.',
              'Items, weapons, armor and shields are unified: mark whether they damage, protect, or both. When equipped, they add Damage, Defense and Shield bonuses.',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${usato.toStringAsFixed(1)} / ${maxPeso.toStringAsFixed(1)} kg',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            '${t('Rimanenti', 'Remaining')}: ${rimasto.toStringAsFixed(1)} kg',
            style: TextStyle(
              color: rimasto >= 0 ? Colors.greenAccent : Colors.redAccent,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton.icon(
              onPressed: inventario.isEmpty ? null : segnaSessioneInventario,
              icon: const Icon(Icons.event_available),
              label: Text(t('Segna giorno inventario', 'Mark inventory day')),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 20,
              color: pesoColor,
              backgroundColor: Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  Widget inventoryAddItemPanelEfficient() {
    return dropdownSection(
      title: t('Aggiungi Oggetto', 'Add Item'),
      subtitle: t(
        'Apri solo quando devi inserire qualcosa.',
        'Open only when you need to insert something.',
      ),
      icon: Icons.add_box,
      borderColor: tertiaryColor,
      sectionId: 'inventory_add_item',
      initiallyExpanded: inventario.isEmpty,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          campoTesto(
            label: t('Nome Oggetto', 'Item Name'),
            controller: itemNomeController,
            numero: false,
          ),
          const SizedBox(height: 12),
          inventoryFieldGrid([
            campoTesto(
              label: t('Peso kg', 'Weight kg'),
              controller: itemPesoController,
            ),
            campoTesto(
              label: t('Quantita', 'Quantity'),
              controller: itemQuantitaController,
            ),
            campoTesto(
              label: t('Putrefazione giorni', 'Rot days'),
              controller: itemPutrefazioneSessioniController,
              helper: t('0 = non marcisce', '0 = does not rot'),
            ),
          ]),
          const SizedBox(height: 12),
          campoTesto(
            label: t('Note', 'Notes'),
            controller: itemNoteController,
            numero: false,
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          campoTesto(
            label: t('Buff @ Oggetto', 'Item @ Buff'),
            controller: itemBuffController,
            numero: false,
            maxLines: 2,
            helper:
                '@HP+5 @HPTemp+Vol1/6 @Scudo+3 @ScudoOculum+5 @TiroAttacco+1',
          ),
          const SizedBox(height: 6),
          smallInfoText(
            t(
              'Questi comandi valgono solo quando l oggetto e equipaggiato.',
              'These commands count only while the item is equipped.',
            ),
          ),
          const SizedBox(height: 12),
          inventoryFieldGrid([
            inventoryModeToggle(
              label: t('Danneggia', 'Deals damage'),
              subtitle: t(
                'Arma, artiglio, focus o oggetto offensivo.',
                'Weapon, claw, focus or offensive item.',
              ),
              value: nuovoItemArma,
              icon: Icons.gavel,
              color: tertiaryColor,
              onChanged: (value) {
                setState(() {
                  nuovoItemArma = value;
                  if (!nuovoItemArma &&
                      !nuovoItemProtegge &&
                      itemBuffController.text.trim().isEmpty) {
                    nuovoItemEquipaggiato = false;
                  }
                });
                programmaSalvataggio();
              },
            ),
            inventoryModeToggle(
              label: t('Protegge', 'Protects'),
              subtitle: t(
                'Armatura, scudo, barriera o reliquia difensiva.',
                'Armor, shield, barrier or defensive relic.',
              ),
              value: nuovoItemProtegge,
              icon: Icons.shield,
              color: primaryColor,
              onChanged: (value) {
                setState(() {
                  nuovoItemProtegge = value;
                  if (!nuovoItemArma &&
                      !nuovoItemProtegge &&
                      itemBuffController.text.trim().isEmpty) {
                    nuovoItemEquipaggiato = false;
                  }
                });
                programmaSalvataggio();
              },
            ),
          ]),
          const SizedBox(height: 12),
          inventoryFieldGrid([
            campoTesto(
              label: t('Bonus Danno', 'Damage Bonus'),
              controller: itemBonusDannoController,
            ),
            campoTesto(
              label: t('Bonus Difesa', 'Defense Bonus'),
              controller: itemBonusDifesaController,
            ),
            campoTesto(
              label: t('Bonus Scudo', 'Shield Bonus'),
              controller: itemBonusScudoController,
            ),
            campoTesto(
              label: t('Grado oggetto', 'Item grade'),
              controller: itemGradoOggettoController,
            ),
            campoTesto(
              label: t('Grado richiesto', 'Required grade'),
              controller: itemGradoRichiestoController,
            ),
          ]),
          const SizedBox(height: 12),
          campoTesto(
            label: t('Tipo danno / protezione', 'Damage / protection type'),
            controller: itemElementoDannoController,
            numero: false,
            enableCommandAutocomplete: true,
            helper: t(
              'Testo libero: vale per danno, difesa elementale e colore. Premi Tab per completare un tipo noto.',
              'Free text: used for damage, elemental defense and color. Press Tab to complete a known type.',
            ),
          ),
          SwitchListTile(
            value: nuovoItemEquipaggiato,
            activeThumbColor: tertiaryColor,
            title: Text(t('Equipaggiata', 'Equipped')),
            subtitle: Text(
              t(
                'Serve anche per attivare i buff @ dell oggetto.',
                'Also enables this item\'s @ buffs.',
              ),
            ),
            onChanged: (value) {
              setState(() => nuovoItemEquipaggiato = value);
              programmaSalvataggio();
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: creaItem,
            style: ElevatedButton.styleFrom(
              backgroundColor: tertiaryColor,
              foregroundColor: tertiaryColor.computeLuminance() > 0.45
                  ? Colors.black
                  : Colors.white,
              minimumSize: const Size.fromHeight(50),
            ),
            child: Text(t('Aggiungi all Inventario', 'Add to Inventory')),
          ),
        ],
      ),
    );
  }

  Widget inventoryItemCardEfficient(int i) {
    if (i < 0 || i >= inventario.length) {
      return const SizedBox.shrink();
    }

    final item = inventario[i];
    final itemColor = item.equipaggiata ? tertiaryColor : primaryColor;
    final totalBuff = item.buff.trim().isEmpty
        ? 0
        : parseTitleQuickCommands(
            item.buff,
          ).values.fold(0, (sum, value) => sum + value);

    Widget compactInventoryChip({
      required String label,
      required Color color,
      IconData? icon,
    }) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.55)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
            ],
            Text(
              cleanUiText(label),
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
    }

    void setItemEquipped(bool value) {
      if (!inventario.contains(item)) return;
      setState(() {
        if (value && !canEquipInventoryItem(item)) {
          risultato = t(
            'Non puoi equipaggiare ${item.nome}: richiede Grado ${requiredItemGrade(item)}.',
            'You cannot equip ${item.nome}: requires Grade ${requiredItemGrade(item)}.',
          );
          aggiungiLog(risultato);
          return;
        }
        if (item.equipaggiata != value) {
          applicaScudoItemAttuale(item, value ? 1 : -1);
        }
        item.equipaggiata = value;
      });
      programmaSalvataggio();
    }

    void deleteItem() {
      final currentIndex = inventario.indexOf(item);
      if (currentIndex < 0) return;
      setState(() {
        if (item.equipaggiata) {
          applicaScudoItemAttuale(item, -1);
        }
        aggiungiLog('Oggetto eliminato: ${item.nome}.');
        inventario.removeAt(currentIndex);
      });
      programmaSalvataggio();
    }

    void duplicateItem() {
      final currentIndex = inventario.indexOf(item);
      if (currentIndex < 0) return;
      final copy = copiaOggetto(item)
        ..nome = '${item.nome} - ${t('copia', 'copy')}'
        ..equipaggiata = false;
      setState(() {
        inventario.insert(currentIndex + 1, copy);
        aggiungiLog('Oggetto duplicato: ${item.nome}.');
      });
      programmaSalvataggio();
    }

    Future<void> showInventoryContextMenu(Offset position) async {
      final choice = await showMenu<String>(
        context: context,
        color: const Color(0xFF10121A),
        position: RelativeRect.fromLTRB(
          position.dx,
          position.dy,
          position.dx,
          position.dy,
        ),
        items: <PopupMenuEntry<String>>[
          PopupMenuItem<String>(
            value: 'equip',
            child: ListTile(
              leading: Icon(
                item.equipaggiata
                    ? Icons.remove_circle_outline
                    : Icons.check_circle_outline,
              ),
              title: Text(
                item.equipaggiata
                    ? t('Rimuovi equipaggiamento', 'Unequip')
                    : t('Equipaggia', 'Equip'),
              ),
            ),
          ),
          PopupMenuItem<String>(
            value: 'send',
            child: ListTile(
              leading: const Icon(Icons.send_outlined),
              title: Text(t('Copia o invia', 'Copy or send')),
            ),
          ),
          PopupMenuItem<String>(
            value: 'duplicate',
            child: ListTile(
              leading: const Icon(Icons.copy),
              title: Text(t('Duplica', 'Duplicate')),
            ),
          ),
          PopupMenuItem<String>(
            value: 'quantity_add',
            child: ListTile(
              leading: const Icon(Icons.add),
              title: Text(t('Aumenta quantita', 'Increase quantity')),
            ),
          ),
          PopupMenuItem<String>(
            value: 'quantity_remove',
            enabled: item.quantita > 1,
            child: ListTile(
              leading: const Icon(Icons.remove),
              title: Text(t('Riduci quantita', 'Decrease quantity')),
            ),
          ),
          PopupMenuItem<String>(
            value: 'manual',
            child: ListTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: Text(t('Cerca nel manuale', 'Search in manual')),
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem<String>(
            value: 'delete',
            child: ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(t('Elimina', 'Delete')),
            ),
          ),
        ],
      );
      if (!mounted || choice == null || !inventario.contains(item)) return;
      switch (choice) {
        case 'equip':
          setItemEquipped(!item.equipaggiata);
          break;
        case 'send':
          await mostraDialogCopiaOggetto(item);
          break;
        case 'duplicate':
          duplicateItem();
          break;
        case 'quantity_add':
          setState(() => item.quantita++);
          programmaSalvataggio();
          break;
        case 'quantity_remove':
          setState(() => item.quantita = max(1, item.quantita - 1));
          programmaSalvataggio();
          break;
        case 'manual':
          openManualForQuickTerm(item.nome);
          break;
        case 'delete':
          deleteItem();
          break;
      }
    }

    final card = gothicPanel(
      borderColor: tertiaryColor.withValues(alpha: 0.7),
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.fromLTRB(10, 3, 8, 3),
          childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          iconColor: itemColor,
          collapsedIconColor: itemColor,
          leading: Icon(
            item.arma && item.protegge
                ? Icons.construction
                : item.arma
                ? Icons.gavel
                : item.protegge
                ? Icons.shield
                : Icons.inventory_2,
            color: itemColor,
            size: 20,
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  item.nome.trim().isEmpty ? itemCombatLabel(item) : item.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: itemColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
              IconButton(
                tooltip: t('Copia / invia Oggetto', 'Copy / send Item'),
                onPressed: () => mostraDialogCopiaOggetto(item),
                constraints: const BoxConstraints.tightFor(
                  width: 30,
                  height: 30,
                ),
                padding: EdgeInsets.zero,
                icon: Icon(Icons.send, color: primaryColor),
              ),
              IconButton(
                constraints: const BoxConstraints.tightFor(
                  width: 30,
                  height: 30,
                ),
                padding: EdgeInsets.zero,
                onPressed: deleteItem,
                icon: const Icon(Icons.delete, color: Colors.redAccent),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Wrap(
              spacing: 5,
              runSpacing: 5,
              children: [
                compactInventoryChip(
                  label: item.equipaggiata
                      ? t('Equip', 'Equip')
                      : t('Non equip', 'Unequip'),
                  color: item.equipaggiata ? tertiaryColor : Colors.grey,
                  icon: item.equipaggiata
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                ),
                compactInventoryChip(
                  label:
                      '${(item.peso * item.quantita).toStringAsFixed(1)}kg x${item.quantita}',
                  color: Colors.grey.shade300,
                  icon: Icons.scale,
                ),
                if (item.arma)
                  compactInventoryChip(
                    label:
                        'DAN ${itemAttackBonus(item) >= 0 ? '+' : ''}${itemAttackBonus(item)}',
                    color: tertiaryColor,
                    icon: Icons.close,
                  ),
                if (item.protegge)
                  compactInventoryChip(
                    label:
                        'DIF ${itemDefenseBonus(item) >= 0 ? '+' : ''}${itemDefenseBonus(item)}',
                    color: primaryColor,
                    icon: Icons.shield_outlined,
                  ),
                if (item.protegge)
                  compactInventoryChip(
                    label:
                        'SCU ${itemShieldBonus(item) >= 0 ? '+' : ''}${itemShieldBonus(item)}',
                    color: Colors.lightBlueAccent,
                    icon: Icons.shield,
                  ),
                if (item.gradoOggetto > 0 || item.gradoRichiesto > 0)
                  compactInventoryChip(
                    label:
                        'G ${item.gradoOggetto.clamp(0, 12)}/R ${item.gradoRichiesto.clamp(0, 12)}',
                    color: canEquipInventoryItem(item)
                        ? Colors.amberAccent
                        : Colors.redAccent,
                    icon: Icons.military_tech,
                  ),
                if (totalBuff != 0)
                  compactInventoryChip(
                    label: '@ ${totalBuff >= 0 ? '+' : ''}$totalBuff',
                    color: oculumStatFormulaColor,
                    icon: Icons.functions,
                  ),
                if (item.arma || item.protegge)
                  compactInventoryChip(
                    label: elementDisplayName(item.elementoDanno),
                    color: elementColor(item.elementoDanno),
                    icon: item.protegge ? Icons.shield : Icons.gavel,
                  ),
                if (item.putrefazioneSessioni > 0 || item.sessioniSegnate > 0)
                  compactInventoryChip(
                    label:
                        'PUT ${item.sessioniSegnate}/${item.putrefazioneSessioni}G',
                    color:
                        item.putrefazioneSessioni > 0 &&
                            item.sessioniSegnate < item.putrefazioneSessioni
                        ? Colors.lightGreenAccent
                        : Colors.redAccent,
                    icon: Icons.compost,
                  ),
              ],
            ),
          ),
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: item.equipaggiata,
              activeThumbColor: tertiaryColor,
              title: Text(t('Equipaggiata', 'Equipped')),
              subtitle: Text(
                t(
                  'Attiva arma/protezione e buff @ dell oggetto.',
                  'Enables weapon/protection and this item\'s @ buffs.',
                ),
              ),
              onChanged: setItemEquipped,
            ),
            const SizedBox(height: 6),
            campoModello(
              label: t('Nome Oggetto', 'Item Name'),
              initialValue: item.nome,
              onChanged: (value) => item.nome = value,
            ),
            const SizedBox(height: 6),
            inventoryFieldGrid([
              campoModello(
                label: t('Peso kg', 'Weight kg'),
                initialValue: item.peso.toString(),
                onChanged: (value) {
                  item.peso =
                      double.tryParse(value.trim().replaceAll(',', '.')) ?? 0;
                },
              ),
              campoModello(
                label: t('Quantita', 'Quantity'),
                initialValue: item.quantita.toString(),
                onChanged: (value) {
                  item.quantita = max(1, int.tryParse(value.trim()) ?? 1);
                },
              ),
              campoModello(
                label: t('Grado oggetto', 'Item grade'),
                initialValue: item.gradoOggetto.toString(),
                onChanged: (value) {
                  item.gradoOggetto = (int.tryParse(value.trim()) ?? 0)
                      .clamp(0, 12)
                      .toInt();
                },
              ),
              campoModello(
                label: t('Grado richiesto', 'Required grade'),
                initialValue: item.gradoRichiesto.toString(),
                onChanged: (value) {
                  item.gradoRichiesto = (int.tryParse(value.trim()) ?? 0)
                      .clamp(0, 12)
                      .toInt();
                },
              ),
              campoModello(
                label: t('Putrefazione giorni', 'Rot days'),
                initialValue: item.putrefazioneSessioni.toString(),
                onChanged: (value) {
                  final previous = item.putrefazioneSessioni;
                  item.putrefazioneSessioni = max(
                    0,
                    int.tryParse(value.trim()) ?? 0,
                  );
                  if (item.putrefazioneSessioni > 0 &&
                      (item.putrefazioneGiornoInizio <= 0 || previous == 0)) {
                    item.putrefazioneGiornoInizio = oculumCurrentDay();
                    item.sessioniSegnate = 0;
                  }
                },
              ),
            ]),
            const SizedBox(height: 6),
            inventoryFieldGrid([
              inventoryModeToggle(
                label: t('Danneggia', 'Deals damage'),
                subtitle: t(
                  'Conta come arma o fonte offensiva.',
                  'Counts as a weapon or offensive source.',
                ),
                value: item.arma,
                icon: Icons.gavel,
                color: tertiaryColor,
                onChanged: (value) {
                  setState(() {
                    item.arma = value;
                    if (!item.arma &&
                        !item.protegge &&
                        item.buff.trim().isEmpty) {
                      item.equipaggiata = false;
                    }
                  });
                  programmaSalvataggio();
                },
              ),
              inventoryModeToggle(
                label: t('Protegge', 'Protects'),
                subtitle: t(
                  'Conta come armatura, scudo o barriera.',
                  'Counts as armor, shield or barrier.',
                ),
                value: item.protegge,
                icon: Icons.shield,
                color: primaryColor,
                onChanged: (value) {
                  setState(() {
                    final wasProtecting = item.protegge;
                    if (item.equipaggiata && wasProtecting && !value) {
                      applicaScudoItemAttuale(item, -1);
                    }
                    item.protegge = value;
                    if (item.equipaggiata && !wasProtecting && value) {
                      applicaScudoItemAttuale(item, 1);
                    }
                    if (!item.arma &&
                        !item.protegge &&
                        item.buff.trim().isEmpty) {
                      item.equipaggiata = false;
                    }
                  });
                  programmaSalvataggio();
                },
              ),
            ]),
            const SizedBox(height: 6),
            inventoryFieldGrid([
              campoModello(
                label: t('Bonus Danno', 'Damage Bonus'),
                initialValue: item.bonusDanno.toString(),
                onChanged: (value) {
                  item.bonusDanno = int.tryParse(value.trim()) ?? 0;
                },
                liveRefresh: true,
              ),
              campoModello(
                label: t('Bonus Difesa', 'Defense Bonus'),
                initialValue: item.bonusDifesa.toString(),
                onChanged: (value) {
                  item.bonusDifesa = int.tryParse(value.trim()) ?? 0;
                },
                liveRefresh: true,
              ),
              campoModello(
                label: t('Bonus Scudo', 'Shield Bonus'),
                initialValue: item.bonusScudo.toString(),
                onChanged: (value) {
                  final nuovo = int.tryParse(value.trim()) ?? 0;
                  if (item.equipaggiata && item.protegge) {
                    scudoController.text = max(
                      0,
                      leggiNumero(scudoController) +
                          (nuovo + itemGrade(item) * 5) -
                          itemShieldBonus(item),
                    ).toString();
                  }
                  item.bonusScudo = nuovo;
                },
                liveRefresh: true,
              ),
            ]),
            const SizedBox(height: 6),
            campoModello(
              label: t('Tipo danno / protezione', 'Damage / protection type'),
              initialValue: item.elementoDanno,
              helper: t(
                'Libero: vale per danno e difesa elementale, e puoi colorarlo dalle Impostazioni.',
                'Free: used for damage and elemental defense, and can be colored from Settings.',
              ),
              onChanged: (value) => item.elementoDanno = value.trim().isEmpty
                  ? 'Fisico'
                  : value.trim(),
              liveRefresh: true,
            ),
            const SizedBox(height: 6),
            campoModello(
              label: t('Buff @ Oggetto', 'Item @ Buff'),
              initialValue: item.buff,
              onChanged: (value) => item.buff = value,
              maxLines: 2,
              helper:
                  '@HP+5 @HPTemp+Vol1/6 @Scudo+3 @ScudoOculum+5 @TiroAttacco+1',
              liveRefresh: true,
            ),
            const SizedBox(height: 6),
            campoModello(
              label: t('Note', 'Notes'),
              initialValue: item.note,
              onChanged: (value) => item.note = value,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onSecondaryTapDown: (details) =>
          showInventoryContextMenu(details.globalPosition),
      onLongPressStart: (details) =>
          showInventoryContextMenu(details.globalPosition),
      child: card,
    );
  }

  Widget inventoryPage() {
    final maxPeso = pesoMassimo();
    final usato = pesoUsato();
    final rimasto = pesoRimanente();
    final ratio = maxPeso <= 0 ? 0.0 : (usato / maxPeso).clamp(0.0, 1.0);

    Color pesoColor;
    if (ratio < 0.6) {
      pesoColor = Colors.greenAccent;
    } else if (ratio < 0.9) {
      pesoColor = tertiaryColor;
    } else {
      pesoColor = Colors.redAccent;
    }

    return responsivePageList(
      pageKey: 'inventory',
      maxColumns: 2,
      minColumnWidth: 360,
      fullWidthIndexes: const <int>{0},
      children: [
        functionAnchor(
          'inventory_root',
          sectionTitle(t('Inventario', 'Inventory')),
        ),
        inventoryQuickDropdownPanel(),
        gothicPanel(
          borderColor: pesoColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t(
                  'Capacità: Volontà Totale × 3 kg',
                  'Capacity: Total Will × 3 kg',
                ),
              ),
              const SizedBox(height: 8),
              smallInfoText(
                t(
                  'Oggetti, armi, armature e scudi sono uniti: puoi segnare se danneggiano, proteggono o entrambe le cose. Se equipaggiati, danno bonus a Danno, Difesa e Scudo.',
                  'Items, weapons, armor and shields are unified: mark whether they damage, protect, or both. When equipped, they add Damage, Defense and Shield bonuses.',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${usato.toStringAsFixed(1)} / ${maxPeso.toStringAsFixed(1)} kg',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${t('Rimanenti', 'Remaining')}: ${rimasto.toStringAsFixed(1)} kg',
                style: TextStyle(
                  color: rimasto >= 0 ? Colors.greenAccent : Colors.redAccent,
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton.icon(
                  onPressed: inventario.isEmpty
                      ? null
                      : segnaSessioneInventario,
                  icon: const Icon(Icons.event_available),
                  label: Text(
                    t('Segna giorno inventario', 'Mark inventory day'),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 20,
                  color: pesoColor,
                  backgroundColor: Colors.black45,
                ),
              ),
            ],
          ),
        ),
        gothicPanel(
          borderColor: tertiaryColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t('Aggiungi Oggetto', 'Add Item'),
                style: TextStyle(
                  color: tertiaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              campoTesto(
                label: t('Nome Oggetto', 'Item Name'),
                controller: itemNomeController,
                numero: false,
              ),
              const SizedBox(height: 12),
              inventoryFieldGrid([
                campoTesto(
                  label: t('Peso kg', 'Weight kg'),
                  controller: itemPesoController,
                ),
                campoTesto(
                  label: t('Quantità', 'Quantity'),
                  controller: itemQuantitaController,
                ),
                campoTesto(
                  label: t('Putrefazione giorni', 'Rot days'),
                  controller: itemPutrefazioneSessioniController,
                  helper: t('0 = non marcisce', '0 = does not rot'),
                ),
              ]),
              const SizedBox(height: 12),
              campoTesto(
                label: t('Note', 'Notes'),
                controller: itemNoteController,
                numero: false,
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              campoTesto(
                label: t('Buff @ Oggetto', 'Item @ Buff'),
                controller: itemBuffController,
                numero: false,
                maxLines: 2,
                helper:
                    '@HP+5 @HPTemp+Vol1/6 @Scudo+3 @ScudoOculum+5 @TiroAttacco+1',
              ),
              const SizedBox(height: 6),
              smallInfoText(
                t(
                  'Questi comandi valgono solo quando l\'oggetto e equipaggiato.',
                  'These commands count only while the item is equipped.',
                ),
              ),
              const SizedBox(height: 12),
              inventoryFieldGrid([
                inventoryModeToggle(
                  label: t('Danneggia', 'Deals damage'),
                  subtitle: t(
                    'Arma, artiglio, focus o oggetto offensivo.',
                    'Weapon, claw, focus or offensive item.',
                  ),
                  value: nuovoItemArma,
                  icon: Icons.gavel,
                  color: tertiaryColor,
                  onChanged: (value) {
                    setState(() {
                      nuovoItemArma = value;
                      if (!nuovoItemArma &&
                          !nuovoItemProtegge &&
                          itemBuffController.text.trim().isEmpty) {
                        nuovoItemEquipaggiato = false;
                      }
                    });
                    programmaSalvataggio();
                  },
                ),
                inventoryModeToggle(
                  label: t('Protegge', 'Protects'),
                  subtitle: t(
                    'Armatura, scudo, barriera o reliquia difensiva.',
                    'Armor, shield, barrier or defensive relic.',
                  ),
                  value: nuovoItemProtegge,
                  icon: Icons.shield,
                  color: primaryColor,
                  onChanged: (value) {
                    setState(() {
                      nuovoItemProtegge = value;
                      if (!nuovoItemArma &&
                          !nuovoItemProtegge &&
                          itemBuffController.text.trim().isEmpty) {
                        nuovoItemEquipaggiato = false;
                      }
                    });
                    programmaSalvataggio();
                  },
                ),
              ]),
              const SizedBox(height: 12),
              inventoryFieldGrid([
                campoTesto(
                  label: t('Bonus Danno', 'Damage Bonus'),
                  controller: itemBonusDannoController,
                ),
                campoTesto(
                  label: t('Bonus Difesa', 'Defense Bonus'),
                  controller: itemBonusDifesaController,
                ),
                campoTesto(
                  label: t('Bonus Scudo', 'Shield Bonus'),
                  controller: itemBonusScudoController,
                ),
                campoTesto(
                  label: t('Grado oggetto', 'Item grade'),
                  controller: itemGradoOggettoController,
                ),
                campoTesto(
                  label: t('Grado richiesto', 'Required grade'),
                  controller: itemGradoRichiestoController,
                ),
              ]),
              const SizedBox(height: 12),
              campoTesto(
                label: t('Tipo danno / protezione', 'Damage / protection type'),
                controller: itemElementoDannoController,
                numero: false,
                enableCommandAutocomplete: true,
                helper: t(
                  'Testo libero: vale per danno, difesa elementale e colore. Premi Tab per completare un tipo noto.',
                  'Free text: used for damage, elemental defense and color. Press Tab to complete a known type.',
                ),
              ),
              SwitchListTile(
                value: nuovoItemEquipaggiato,
                activeThumbColor: tertiaryColor,
                title: Text(t('Equipaggiata', 'Equipped')),
                subtitle: Text(
                  t(
                    'Serve anche per attivare i buff @ dell\'oggetto.',
                    'Also enables this item\'s @ buffs.',
                  ),
                ),
                onChanged: (value) {
                  setState(() => nuovoItemEquipaggiato = value);
                  programmaSalvataggio();
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: creaItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: tertiaryColor,
                  foregroundColor: tertiaryColor.computeLuminance() > 0.45
                      ? Colors.black
                      : Colors.white,
                  minimumSize: const Size.fromHeight(50),
                ),
                child: Text(t('Aggiungi all’Inventario', 'Add to Inventory')),
              ),
            ],
          ),
        ),
        for (int i = 0; i < inventario.length; i++)
          gothicPanel(
            borderColor: tertiaryColor.withValues(alpha: 0.7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        itemCombatLabel(inventario[i]),
                        style: TextStyle(
                          color: inventario[i].equipaggiata
                              ? tertiaryColor
                              : primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: t('Copia / invia Oggetto', 'Copy / send Item'),
                      onPressed: () => mostraDialogCopiaOggetto(inventario[i]),
                      icon: Icon(Icons.send, color: primaryColor),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          if (inventario[i].equipaggiata) {
                            applicaScudoItemAttuale(inventario[i], -1);
                          }
                          aggiungiLog(
                            'Oggetto eliminato: ${inventario[i].nome}.',
                          );
                          inventario.removeAt(i);
                        });
                        programmaSalvataggio();
                      },
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (inventario[i].arma)
                      statChip('DMG', itemAttackBonus(inventario[i])),
                    if (inventario[i].protegge)
                      statChip('DIF', itemDefenseBonus(inventario[i])),
                    if (inventario[i].protegge)
                      statChip('SCU', itemShieldBonus(inventario[i])),
                    if (inventario[i].gradoOggetto > 0 ||
                        inventario[i].gradoRichiesto > 0)
                      Chip(
                        avatar: const Icon(Icons.military_tech, size: 16),
                        label: Text(
                          'G ${inventario[i].gradoOggetto.clamp(0, 12)}/R ${inventario[i].gradoRichiesto.clamp(0, 12)}',
                        ),
                        backgroundColor:
                            (canEquipInventoryItem(inventario[i])
                                    ? Colors.amberAccent
                                    : Colors.redAccent)
                                .withValues(alpha: 0.18),
                      ),
                    if (inventario[i].buff.trim().isNotEmpty)
                      statChip(
                        '@',
                        parseTitleQuickCommands(
                          inventario[i].buff,
                        ).values.fold(0, (sum, value) => sum + value),
                      ),
                    if (inventario[i].arma || inventario[i].protegge)
                      Chip(
                        label: Text(
                          elementDisplayName(inventario[i].elementoDanno),
                        ),
                        avatar: Icon(
                          inventario[i].protegge ? Icons.shield : Icons.gavel,
                          size: 16,
                        ),
                        backgroundColor: elementColor(
                          inventario[i].elementoDanno,
                        ).withValues(alpha: 0.18),
                        side: BorderSide(
                          color: elementColor(inventario[i].elementoDanno),
                        ),
                        labelStyle: TextStyle(
                          color: elementColor(inventario[i].elementoDanno),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    if (inventario[i].putrefazioneSessioni > 0 ||
                        inventario[i].sessioniSegnate > 0)
                      Chip(
                        avatar: const Icon(Icons.compost, size: 16),
                        label: Text(
                          'PUT ${inventario[i].sessioniSegnate}/${inventario[i].putrefazioneSessioni}G',
                        ),
                        backgroundColor:
                            (inventario[i].putrefazioneSessioni > 0 &&
                                        inventario[i].sessioniSegnate <
                                            inventario[i].putrefazioneSessioni
                                    ? Colors.lightGreenAccent
                                    : Colors.redAccent)
                                .withValues(alpha: 0.18),
                      ),
                  ],
                ),
                if (inventario[i].arma || inventario[i].protegge)
                  const SizedBox(height: 8),

                campoModello(
                  label: t('Nome Oggetto', 'Item Name'),
                  initialValue: inventario[i].nome,
                  onChanged: (value) => inventario[i].nome = value,
                ),

                const SizedBox(height: 8),

                inventoryFieldGrid([
                  campoModello(
                    label: t('Peso kg', 'Weight kg'),
                    initialValue: inventario[i].peso.toString(),
                    onChanged: (value) {
                      inventario[i].peso =
                          double.tryParse(value.trim().replaceAll(',', '.')) ??
                          0;
                    },
                  ),
                  campoModello(
                    label: t('Quantità', 'Quantity'),
                    initialValue: inventario[i].quantita.toString(),
                    onChanged: (value) {
                      inventario[i].quantita = max(
                        1,
                        int.tryParse(value.trim()) ?? 1,
                      );
                    },
                  ),
                  campoModello(
                    label: t('Grado oggetto', 'Item grade'),
                    initialValue: inventario[i].gradoOggetto.toString(),
                    onChanged: (value) {
                      inventario[i].gradoOggetto =
                          (int.tryParse(value.trim()) ?? 0)
                              .clamp(0, 12)
                              .toInt();
                    },
                  ),
                  campoModello(
                    label: t('Grado richiesto', 'Required grade'),
                    initialValue: inventario[i].gradoRichiesto.toString(),
                    onChanged: (value) {
                      inventario[i].gradoRichiesto =
                          (int.tryParse(value.trim()) ?? 0)
                              .clamp(0, 12)
                              .toInt();
                    },
                  ),
                  campoModello(
                    label: t('Putrefazione giorni', 'Rot days'),
                    initialValue: inventario[i].putrefazioneSessioni.toString(),
                    onChanged: (value) {
                      final previous = inventario[i].putrefazioneSessioni;
                      inventario[i].putrefazioneSessioni = max(
                        0,
                        int.tryParse(value.trim()) ?? 0,
                      );
                      if (inventario[i].putrefazioneSessioni > 0 &&
                          (inventario[i].putrefazioneGiornoInizio <= 0 ||
                              previous == 0)) {
                        inventario[i].putrefazioneGiornoInizio =
                            oculumCurrentDay();
                        inventario[i].sessioniSegnate = 0;
                      }
                    },
                  ),
                ]),

                const SizedBox(height: 8),

                campoModello(
                  label: t('Buff @ Oggetto', 'Item @ Buff'),
                  initialValue: inventario[i].buff,
                  onChanged: (value) => inventario[i].buff = value,
                  maxLines: 2,
                  helper:
                      '@HP+5 @HPTemp+Vol1/6 @Scudo+3 @ScudoOculum+5 @TiroAttacco+1',
                ),

                const SizedBox(height: 8),

                inventoryFieldGrid([
                  campoModello(
                    label: t('Bonus Danno', 'Damage Bonus'),
                    initialValue: inventario[i].bonusDanno.toString(),
                    onChanged: (value) {
                      inventario[i].bonusDanno =
                          int.tryParse(value.trim()) ?? 0;
                    },
                  ),
                  campoModello(
                    label: t('Bonus Difesa', 'Defense Bonus'),
                    initialValue: inventario[i].bonusDifesa.toString(),
                    onChanged: (value) {
                      inventario[i].bonusDifesa =
                          int.tryParse(value.trim()) ?? 0;
                    },
                  ),
                  campoModello(
                    label: t('Bonus Scudo', 'Shield Bonus'),
                    initialValue: inventario[i].bonusScudo.toString(),
                    onChanged: (value) {
                      final nuovo = int.tryParse(value.trim()) ?? 0;
                      if (inventario[i].equipaggiata &&
                          inventario[i].protegge) {
                        scudoController.text = max(
                          0,
                          leggiNumero(scudoController) +
                              (nuovo + itemGrade(inventario[i]) * 5) -
                              itemShieldBonus(inventario[i]),
                        ).toString();
                      }
                      inventario[i].bonusScudo = nuovo;
                    },
                  ),
                ]),

                const SizedBox(height: 8),

                campoModello(
                  label: t(
                    'Tipo danno / protezione',
                    'Damage / protection type',
                  ),
                  initialValue: inventario[i].elementoDanno,
                  helper: t(
                    'Libero: vale per danno e difesa elementale, e puoi colorarlo dalle Impostazioni.',
                    'Free: used for damage and elemental defense, and can be colored from Settings.',
                  ),
                  onChanged: (value) => inventario[i].elementoDanno =
                      value.trim().isEmpty ? 'Fisico' : value.trim(),
                ),

                const SizedBox(height: 8),

                inventoryFieldGrid([
                  inventoryModeToggle(
                    label: t('Danneggia', 'Deals damage'),
                    subtitle: t(
                      'Conta come arma o fonte offensiva.',
                      'Counts as a weapon or offensive source.',
                    ),
                    value: inventario[i].arma,
                    icon: Icons.gavel,
                    color: tertiaryColor,
                    onChanged: (value) {
                      setState(() {
                        inventario[i].arma = value;
                        if (!inventario[i].arma &&
                            !inventario[i].protegge &&
                            inventario[i].buff.trim().isEmpty) {
                          inventario[i].equipaggiata = false;
                        }
                      });
                      programmaSalvataggio();
                    },
                  ),
                  inventoryModeToggle(
                    label: t('Protegge', 'Protects'),
                    subtitle: t(
                      'Conta come armatura, scudo o barriera.',
                      'Counts as armor, shield or barrier.',
                    ),
                    value: inventario[i].protegge,
                    icon: Icons.shield,
                    color: primaryColor,
                    onChanged: (value) {
                      setState(() {
                        final wasProtecting = inventario[i].protegge;
                        if (inventario[i].equipaggiata &&
                            wasProtecting &&
                            !value) {
                          applicaScudoItemAttuale(inventario[i], -1);
                        }
                        inventario[i].protegge = value;
                        if (inventario[i].equipaggiata &&
                            !wasProtecting &&
                            value) {
                          applicaScudoItemAttuale(inventario[i], 1);
                        }
                        if (!inventario[i].arma &&
                            !inventario[i].protegge &&
                            inventario[i].buff.trim().isEmpty) {
                          inventario[i].equipaggiata = false;
                        }
                      });
                      programmaSalvataggio();
                    },
                  ),
                ]),

                SwitchListTile(
                  value: inventario[i].equipaggiata,
                  activeThumbColor: tertiaryColor,
                  title: Text(t('Equipaggiata', 'Equipped')),
                  subtitle: Text(
                    t(
                      'Attiva arma/protezione e buff @ dell\'oggetto.',
                      'Enables weapon/protection and this item\'s @ buffs.',
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      if (value && !canEquipInventoryItem(inventario[i])) {
                        risultato = t(
                          'Non puoi equipaggiare ${inventario[i].nome}: richiede Grado ${requiredItemGrade(inventario[i])}.',
                          'You cannot equip ${inventario[i].nome}: requires Grade ${requiredItemGrade(inventario[i])}.',
                        );
                        aggiungiLog(risultato);
                        return;
                      }
                      if (inventario[i].equipaggiata != value) {
                        applicaScudoItemAttuale(inventario[i], value ? 1 : -1);
                      }
                      inventario[i].equipaggiata = value;
                    });
                    programmaSalvataggio();
                  },
                ),

                campoModello(
                  label: t('Note', 'Notes'),
                  initialValue: inventario[i].note,
                  onChanged: (value) => inventario[i].note = value,
                  maxLines: 3,
                ),
              ],
            ),
          ),
      ],
    );
  }

  // =====================================================
}
