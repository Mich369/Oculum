from pathlib import Path
p=Path('lib/src/main/oculum_reference_sheet.dart')
s=p.read_text(encoding='utf-8'); start=s.index('PopupMenuButton<OculumTitle>('); end=s.index('\n                        ),\n                        TextButton(',start)
block=s[start:end]; assert block.endswith('),'); block=block[:-1]
# Replace existing popup with reusable selector.
s=s[:start]+'visibleTitleIdentitySelector(compact: compact),'+s[end:]
# Make display optionally title only for identity panel.
block=block.replace("""'${nomeController.text.trim().isEmpty ? t('Il tuo personaggio', 'Your character') : nomeController.text} | ${titoloSempreVisibile?.nome ?? t('Scegli titolo', 'Choose title')}'""", """'${includeName ? "${nomeController.text.trim().isEmpty ? t('Il tuo personaggio', 'Your character') : nomeController.text} | " : ""}${titoloSempreVisibile?.nome ?? t('Scegli titolo', 'Choose title')}'""")
pos=s.index('\n',s.index('extension '))+1
helper='''
  Widget visibleTitleIdentitySelector({bool compact = true, bool includeName = true}) {
    return GestureDetector(
      onSecondaryTap: openVisibleTitleIdentity,
      onLongPress: openVisibleTitleIdentity,
      child: POPUP,
    );
  }

  Future<void> openVisibleTitleIdentity() async {
    final title = titoloSempreVisibile;
    if (title == null) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: secondaryColor,
        title: Text(title.nome, style: TextStyle(color: primaryColor)),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              campoModello(
                label: t('Nome Titolo', 'Title name'),
                initialValue: title.nome,
                onChanged: (value) {
                  setState(() => title.nome = value);
                  syncMasterInitiativeVisibleTitle(schedaCorrente);
                  programmaSalvataggio();
                },
              ),
              const SizedBox(height: 12),
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
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () {
            Navigator.pop(dialogContext);
            final racial = trattiRazziali.any((item) => identical(item, title));
            final index = (racial ? trattiRazziali : titoli).indexOf(title);
            _expandedFunctionSections.add('${racial ? "racial_trait" : "title"}_${currentSheetScrollId()}_$index');
            vaiAllaFunzione(page: 2, anchorId: titleEditorAnchorId(title, trattoRazziale: racial), logTitle: title.nome);
          }, child: Text(t('Apri scheda', 'Open entry'))),
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(t('Chiudi', 'Close'))),
        ],
      ),
    );
  }
'''.replace('POPUP',block)
s=s[:pos]+helper+s[pos:]; p.write_text(s,encoding='utf-8')
p=Path('lib/src/main/oculum_home_sheet_page.dart');s=p.read_text(encoding='utf-8');start=s.index('  Widget sheetIdentityEditorPanel(');idx=s.index('          tipoSchedaDropdown(',start);s=s[:idx]+'''          visibleTitleIdentitySelector(includeName: false, compact: dense),
          const SizedBox(height: 8),
'''+s[idx:];p.write_text(s,encoding='utf-8')
