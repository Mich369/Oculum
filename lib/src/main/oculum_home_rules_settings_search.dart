part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member, unused_element

const String oculumSheetShareCodePrefix = 'OCULUM-SHEETS-v1:';

List<Map<String, dynamic>> oculumDecodeSheetShareText(String rawText) {
  List<Map<String, dynamic>> sheetsFromPayload(dynamic decoded) {
    if (decoded is! Map) {
      throw const FormatException('Payload non valido.');
    }
    final map = Map<String, dynamic>.from(decoded);
    final rawSheets = map['sheets'] ?? map['schedePersonaggio'];
    if (rawSheets is List) {
      return rawSheets
          .whereType<Map>()
          .map((sheet) => Map<String, dynamic>.from(sheet))
          .toList();
    }
    if (map.containsKey('nome') || map.containsKey('tipoScheda')) {
      return <Map<String, dynamic>>[map];
    }
    throw const FormatException('Nessuna scheda trovata.');
  }

  final text = rawText.trim();
  if (text.isEmpty) throw const FormatException('Il codice e vuoto.');
  final codeParts = text
      .split(RegExp(r'[\s,;]+'))
      .map((part) => part.trim())
      .where((part) => part.startsWith(oculumSheetShareCodePrefix))
      .toList();
  if (codeParts.isEmpty) return sheetsFromPayload(jsonDecode(text));

  final sheets = <Map<String, dynamic>>[];
  for (final code in codeParts) {
    var encoded = code.substring(oculumSheetShareCodePrefix.length).trim();
    while (encoded.length % 4 != 0) {
      encoded += '=';
    }
    final decodedText = utf8.decode(base64Url.decode(encoded));
    sheets.addAll(sheetsFromPayload(jsonDecode(decodedText)));
  }
  if (sheets.isEmpty) {
    throw const FormatException('Nessuna scheda trovata.');
  }
  return sheets;
}

dynamic oculumDecodeJsonText(String text) => jsonDecode(text);

extension _OculumHomeRulesSettingsSearch on _OculumHomePageState {
  // REGOLE / MANUALE
  // =====================================================

  String manualPdfSafeText(String value) {
    return cleanUiText(value)
        .replaceAll('•', '-')
        .replaceAll('•', '-')
        .replaceAll('—', '-')
        .replaceAll('–', '-')
        .replaceAll('¼', '1/4')
        .replaceAll('½', '1/2')
        .replaceAll('¾', '3/4')
        .replaceAll('⅓', '1/3')
        .replaceAll('⅔', '2/3');
  }

  String manualPdfExtraSafeText(String value) {
    return manualPdfSafeText(value)
        .replaceAll('•', '-')
        .replaceAll('—', '-')
        .replaceAll('–', '-')
        .replaceAll('→', '->')
        .replaceAll('’', "'")
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('…', '...')
        .replaceAll('¼', '1/4')
        .replaceAll('½', '1/2')
        .replaceAll('¾', '3/4')
        .replaceAll('⅓', '1/3')
        .replaceAll('⅔', '2/3')
        .replaceAll('Ã ', 'a')
        .replaceAll('Ã¨', 'e')
        .replaceAll('Ã©', 'e')
        .replaceAll('Ã¬', 'i')
        .replaceAll('Ã²', 'o')
        .replaceAll('Ã¹', 'u')
        .replaceAll('à', 'a')
        .replaceAll('è', 'e')
        .replaceAll('é', 'e')
        .replaceAll('ì', 'i')
        .replaceAll('ò', 'o')
        .replaceAll('ù', 'u');
  }

  String manualParserExamplesPdfText() {
    return t(
      '''
Esempi complessi funzionanti:

@Resistenza Fuoco
Riduce il danno Fuoco in arrivo.

@FragilitaVera Acqua
Aumenta molto il danno Acqua in arrivo.

@ResistenzaImpenetrabile fisico
Riduce fortemente il danno fisico/normale.

@DanniSubiti+15% Acqua
Aumenta del 15% il danno Acqua dopo difesa e modificatori.

@DanniSubiti-6 fuoco
Toglie 6 danni Fuoco dopo difesa e modificatori.

@safehp
Consumabile: se un colpo ti porterebbe a 0 HP, resti a 1 HP.

@saveShield+30
Consumabile: se dopo un colpo resti vivo a 25% HP o meno, ottieni 30 Scudo.

Combo esempio:
@Resistenza Fuoco
@DanniSubiti-6 Fuoco
@saveShield+25
Un colpo Fuoco viene ridotto, poi perde 6 danni; se sopravvivi sotto il 25% HP ricevi 25 Scudo.
''',
      '''
Working complex examples:

@Resistenza Fuoco
Reduces incoming Fire damage.

@FragilitaVera Acqua
Greatly increases incoming Water damage.

@ResistenzaImpenetrabile fisico
Strongly reduces physical/normal damage.

@DanniSubiti+15% Acqua
Increases Water damage by 15% after defense and modifiers.

@DanniSubiti-6 fuoco
Removes 6 Fire damage after defense and modifiers.

@safehp
Consumable: if a hit would take you to 0 HP, you stay at 1 HP.

@saveShield+30
Consumable: if after a hit you survive at 25% HP or lower, you gain 30 Shield.

Combo example:
@Resistenza Fuoco
@DanniSubiti-6 Fuoco
@saveShield+25
A Fire hit is reduced, then loses 6 damage; if you survive under 25% HP you gain 25 Shield.
''',
    );
  }

  List<String> manualPdfSplitTextBlocks(String value, {int maxChars = 650}) {
    final text = manualPdfExtraSafeText(
      value,
    ).replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();
    if (text.isEmpty) return const <String>[];

    final blocks = <String>[];

    void addWrappedLine(String rawLine) {
      final line = rawLine.trim();
      if (line.isEmpty) return;
      if (line.length <= maxChars) {
        blocks.add(line);
        return;
      }

      final words = line.split(RegExp(r'\s+'));
      final buffer = StringBuffer();
      for (final word in words) {
        if (word.isEmpty) continue;
        final nextLength = buffer.isEmpty
            ? word.length
            : buffer.length + 1 + word.length;
        if (nextLength > maxChars && buffer.isNotEmpty) {
          blocks.add(buffer.toString());
          buffer.clear();
        }
        if (buffer.isNotEmpty) buffer.write(' ');
        buffer.write(word);
      }
      if (buffer.isNotEmpty) blocks.add(buffer.toString());
    }

    for (final paragraph in text.split(RegExp(r'\n{2,}'))) {
      for (final line in paragraph.split('\n')) {
        addWrappedLine(line);
      }
    }

    return blocks;
  }

  List<pw.Widget> manualPdfTextWidgets(String value, pw.TextStyle style) {
    final blocks = manualPdfSplitTextBlocks(value);
    return [
      for (final block in blocks) ...[
        pw.Text(block, style: style),
        pw.SizedBox(height: 4),
      ],
    ];
  }

  Future<void> salvaManualePdfAggiornato() async {
    setState(() {
      risultato = t('Genero il PDF del manuale...', 'Generating manual PDF...');
    });

    try {
      final now = DateTime.now();
      final stamp =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
      final fileName = 'oculum_manuale_$stamp.pdf';
      final bytes = await oculumBuildManualPdf(english: linguaInglese);
      if (kIsWeb) {
        await oculumDownloadBytes(
          bytes: bytes,
          fileName: fileName,
          mimeType: 'application/pdf',
        );
        if (!mounted) return;
        setState(() {
          risultato = t(
            'Download manuale PDF avviato.',
            'Manual PDF download started.',
          );
          aggiungiLog(risultato);
        });
        return;
      }

      Directory dir;
      try {
        dir = await getApplicationDocumentsDirectory();
      } catch (_) {
        dir = Directory.current;
      }
      final file = File('${dir.path}${Platform.pathSeparator}$fileName');
      await file.writeAsBytes(bytes);

      if (!mounted) return;
      setState(() {
        risultato = t(
          'Manuale PDF salvato: ${file.path}',
          'Manual PDF saved: ${file.path}',
        );
        aggiungiLog(risultato);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        risultato = t(
          'Errore salvataggio PDF manuale: $error',
          'Manual PDF save error: $error',
        );
        aggiungiLog(risultato);
      });
    }
  }

  Widget manualIndexButton(int index) {
    final section = activeManualSections[index];
    final selected = manualSectionIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() => manualSectionIndex = index);
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: selected
              ? tertiaryColor.withValues(alpha: 0.20)
              : Colors.black.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? tertiaryColor
                : primaryColor.withValues(alpha: 0.35),
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.visibility : Icons.menu_book,
              color: selected ? tertiaryColor : Colors.grey.shade400,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                manualTitle(section),
                style: TextStyle(
                  color: selected ? tertiaryColor : Colors.white,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget rulesPageEfficient() {
    final filteredIndexes = manualFilteredIndexes();

    if (manualSectionIndex < 0 ||
        manualSectionIndex >= activeManualSections.length) {
      manualSectionIndex = 0;
    }

    final section = activeManualSections[manualSectionIndex];
    final builders = <WidgetBuilder>[
      (_) => functionAnchor('rules_root', sectionTitle(t('Regole', 'Rules'))),
      (_) => manualQuickToolsPanel(),
      (_) => appUsageGuideNavigationPanel(),
      (_) => rulesManualIntroPanelEfficient(),
      (_) => rulesSearchPanelEfficient(filteredIndexes.length),
      (_) => sectionTitle(t('Indice', 'Index')),
    ];

    if (filteredIndexes.isEmpty) {
      builders.add(
        (_) => gothicPanel(
          borderColor: tertiaryColor,
          child: Text(t('Nessuna sezione trovata.', 'No section found.')),
        ),
      );
    } else {
      for (final index in filteredIndexes) {
        final manualIndex = index;
        builders.add(
          (_) => RepaintBoundary(
            key: ValueKey('manual_index_$manualIndex'),
            child: gothicPanel(
              borderColor: tertiaryColor.withValues(alpha: 0.55),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: manualIndexButton(manualIndex),
            ),
          ),
        );
      }
    }

    builders.addAll([
      (_) => functionAnchor(
        'rules_open_section',
        sectionTitle(t('Sezione Aperta', 'Opened Section')),
      ),
      (_) => rulesOpenedSectionPanelEfficient(section),
    ]);

    final fullWidthIndexes = <int>{
      0,
      5,
      builders.length - 2,
      builders.length - 1,
    };

    return responsivePageBuilder(
      pageKey: 'rules',
      builders: builders,
      fullWidthIndexes: fullWidthIndexes,
      maxColumns: 3,
      minColumnWidth: 320,
      cacheExtent: 420,
    );
  }

  Widget rulesManualIntroPanelEfficient() {
    return gothicPanel(
      borderColor: tertiaryColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MANUALE OCULUM',
            style: TextStyle(
              color: tertiaryColor,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(height: 10),
          smallInfoText(
            t(
              'Questo manuale e pensato anche per nuovi giocatori. Ogni sezione spiega non solo la regola, ma anche il senso narrativo dietro la regola.',
              'This manual is also written for new players. Each section explains not only the rule, but also the narrative meaning behind it.',
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: salvaManualePdfAggiornato,
            icon: const Icon(Icons.picture_as_pdf),
            label: Text(t('Salva PDF aggiornato', 'Save updated PDF')),
            style: ElevatedButton.styleFrom(
              backgroundColor: tertiaryColor,
              foregroundColor: tertiaryColor.computeLuminance() > 0.45
                  ? Colors.black
                  : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget rulesSearchPanelEfficient(int resultCount) {
    return gothicPanel(
      borderColor: primaryColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('Cerca nel Manuale', 'Search Manual'),
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          campoTesto(
            label: t(
              'Cerca regole, mostri, titoli, arti...',
              'Search rules, monsters, titles, arts...',
            ),
            controller: manualSearchController,
            numero: false,
          ),
          const SizedBox(height: 12),
          Text(
            '${t('Risultati', 'Results')}: $resultCount/${activeManualSections.length}',
          ),
        ],
      ),
    );
  }

  Widget rulesOpenedSectionPanelEfficient(ManualSection section) {
    return gothicPanel(
      borderColor: tertiaryColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            manualTitle(section),
            style: TextStyle(
              color: tertiaryColor,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          SelectableText(
            manualContent(section).trim(),
            style: TextStyle(
              color: Colors.grey.shade100,
              fontSize: 15.5,
              height: 1.50,
            ),
          ),
        ],
      ),
    );
  }

  Widget rulesPage() {
    final filteredIndexes = manualFilteredIndexes();

    if (manualSectionIndex < 0 ||
        manualSectionIndex >= activeManualSections.length) {
      manualSectionIndex = 0;
    }

    final section = activeManualSections[manualSectionIndex];

    return responsivePageList(
      pageKey: 'rules',
      maxColumns: 3,
      minColumnWidth: 320,
      fullWidthIndexes: const <int>{0, 7, 8},
      children: [
        functionAnchor('rules_root', sectionTitle(t('Regole', 'Rules'))),
        manualQuickToolsPanel(),
        appUsageGuideNavigationPanel(),
        gothicPanel(
          borderColor: tertiaryColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MANUALE OCULUM',
                style: TextStyle(
                  color: tertiaryColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.5,
                ),
              ),
              const SizedBox(height: 10),
              smallInfoText(
                t(
                  'Questo manuale è pensato anche per nuovi giocatori. Ogni sezione spiega non solo la regola, ma anche il senso narrativo dietro la regola.',
                  'This manual is also written for new players. Each section explains not only the rule, but also the narrative meaning behind it.',
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: salvaManualePdfAggiornato,
                icon: const Icon(Icons.picture_as_pdf),
                label: Text(t('Salva PDF aggiornato', 'Save updated PDF')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: tertiaryColor,
                  foregroundColor: tertiaryColor.computeLuminance() > 0.45
                      ? Colors.black
                      : Colors.white,
                ),
              ),
            ],
          ),
        ),
        gothicPanel(
          borderColor: primaryColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t('Cerca nel Manuale', 'Search Manual'),
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              campoTesto(
                label: t(
                  'Cerca regole, mostri, titoli, arti...',
                  'Search rules, monsters, titles, arts...',
                ),
                controller: manualSearchController,
                numero: false,
              ),
              const SizedBox(height: 12),
              Text(
                '${t('Risultati', 'Results')}: ${filteredIndexes.length}/${activeManualSections.length}',
              ),
            ],
          ),
        ),
        sectionTitle(t('Indice', 'Index')),
        gothicPanel(
          borderColor: tertiaryColor,
          child: Column(
            children: [
              if (filteredIndexes.isEmpty)
                Text(t('Nessuna sezione trovata.', 'No section found.'))
              else
                for (final index in filteredIndexes) manualIndexButton(index),
            ],
          ),
        ),
        functionAnchor(
          'rules_open_section',
          sectionTitle(t('Sezione Aperta', 'Opened Section')),
        ),
        gothicPanel(
          borderColor: tertiaryColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                manualTitle(section),
                style: TextStyle(
                  color: tertiaryColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              SelectableText(
                manualContent(section).trim(),
                style: TextStyle(
                  color: Colors.grey.shade100,
                  fontSize: 15.5,
                  height: 1.50,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> appUsageGuideDestinations() {
    return <Map<String, dynamic>>[
      {
        'title': t(
          'Immagine scheda / drop Windows',
          'Sheet image / Windows drop',
        ),
        'page': 0,
        'anchorId': 'sheet_image',
        'icon': Icons.image,
      },
      {
        'title': t('Centro comandi scheda', 'Sheet command center'),
        'page': 0,
        'anchorId': 'sheet_command_center',
        'icon': Icons.dashboard_customize,
      },
      {
        'title': t(
          'Nome, tipo, livello e grado',
          'Name, type, level and grade',
        ),
        'page': 0,
        'anchorId': 'sheet_identity',
        'icon': Icons.badge,
      },
      {
        'title': t('Razza e tratti', 'Race and traits'),
        'page': 0,
        'anchorId': 'sheet_race',
        'icon': Icons.diversity_3,
      },
      {
        'title': 'EXP',
        'page': 0,
        'anchorId': 'sheet_exp',
        'icon': Icons.trending_up,
      },
      {
        'title': 'HP / Scudi',
        'page': 0,
        'anchorId': 'sheet_hp',
        'icon': Icons.favorite,
      },
      {
        'title': t('Danno / Cura / Tipo danno', 'Damage / Heal / Damage type'),
        'page': 0,
        'anchorId': 'sheet_damage_heal',
        'icon': Icons.local_fire_department,
      },
      {
        'title': t('Combattimento', 'Combat'),
        'page': 0,
        'anchorId': 'sheet_combat_values',
        'icon': Icons.sports_martial_arts,
      },
      {
        'title': t('Riepilogo rapido', 'Quick summary'),
        'page': 0,
        'anchorId': 'sheet_values',
        'icon': Icons.dashboard,
      },
      {
        'title': t('Statistiche cliccabili', 'Clickable stats'),
        'page': 0,
        'anchorId': 'sheet_stats',
        'icon': Icons.auto_graph,
      },
      {
        'title': t('Valori modificabili', 'Editable values'),
        'page': 0,
        'anchorId': 'sheet_editable_values',
        'icon': Icons.tune,
      },
      {
        'title': t('Party scheda', 'Sheet party'),
        'page': 0,
        'anchorId': 'sheet_party',
        'icon': Icons.groups,
      },
      {
        'title': t('Riposo / stati', 'Rest / conditions'),
        'page': 1,
        'anchorId': 'rest_root',
        'icon': Icons.nightlight_round,
      },
      {
        'title': t('Titoli', 'Titles'),
        'page': 2,
        'anchorId': 'titles_root',
        'icon': Icons.auto_awesome,
      },
      {
        'title': t('Crea Titolo', 'Create Title'),
        'page': 2,
        'anchorId': 'titles_create',
        'icon': Icons.add_circle,
      },
      {
        'title': t('Art', 'Arts'),
        'page': 3,
        'anchorId': 'art_root',
        'icon': Icons.auto_fix_high,
      },
      {
        'title': t('Skill', 'Skills'),
        'page': 4,
        'anchorId': 'skills_root',
        'icon': Icons.blur_circular,
      },
      {
        'title': t('Storia / diario', 'Story / diary'),
        'page': 5,
        'anchorId': 'story_root',
        'icon': Icons.menu_book,
      },
      {
        'title': t('Inventario / armi', 'Inventory / weapons'),
        'page': 6,
        'anchorId': 'inventory_root',
        'icon': Icons.backpack,
      },
      {
        'title': t('Risorse', 'Resources'),
        'page': 7,
        'anchorId': 'resources_root',
        'icon': Icons.diamond,
      },
      {
        'title': t('Master', 'Master'),
        'page': 9,
        'anchorId': 'master_root',
        'icon': Icons.admin_panel_settings,
      },
      {
        'title': t('Impostazioni', 'Settings'),
        'page': _OculumHomePageState.settingsPageIndex,
        'anchorId': 'settings_root',
        'icon': Icons.settings,
      },
      {
        'title': t('Online', 'Online'),
        'page': _OculumHomePageState.onlinePageIndex,
        'anchorId': 'online_root',
        'icon': Icons.public,
      },
    ];
  }

  Widget appUsageGuideNavigationPanel() {
    return dropdownSection(
      title: t('Guida speciale dell’app', 'Special app guide'),
      subtitle: t(
        'Ogni pulsante porta direttamente allo spazio dell’app spiegato dal manuale. Usa questa guida quando non ricordi dove si trova una casella.',
        'Each button jumps directly to the app area explained by the manual. Use this guide when you do not remember where a field is.',
      ),
      icon: Icons.explore,
      borderColor: tertiaryColor,
      initiallyExpanded: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          smallInfoText(
            t(
              'Apri la sezione “Guida app: scheda, zone e click” nell’indice per leggere cosa fa ogni zona e cosa succede quando tocchi un riquadro.',
              'Open “App guide: sheet, areas and taps” in the index to read what every area does and what happens when you tap a card.',
            ),
            color: primaryColor,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final destination in appUsageGuideDestinations())
                ElevatedButton.icon(
                  onPressed: () {
                    vaiAllaFunzione(
                      page: readIntValue(destination['page']),
                      anchorId: '${destination['anchorId'] ?? ''}',
                      logTitle: '${destination['title']}',
                    );
                  },
                  icon: Icon(destination['icon'] as IconData, size: 18),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.35),
                    foregroundColor: primaryColor,
                    side: BorderSide(
                      color: tertiaryColor.withValues(alpha: 0.55),
                    ),
                  ),
                  label: Text('${destination['title']}'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // =====================================================
  // IMPOSTAZIONI / COLORE AVANZATO
  // =====================================================
  // =====================================================
  // IMPORT / EXPORT SALVATAGGIO
  // =====================================================

  String creaBackupJson() {
    salvaSchedaCorrenteInMemoria();
    saveActiveCampaignInMemory();

    final data = <String, dynamic>{
      ...datiSalvataggioJson(revision: salvataggioRevisione),
      'oculumBackup': true,
      'versioneBackup': 2,
      'backupCreatedAt': DateTime.now().toIso8601String(),
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<void> esportaBackupNegliAppunti() async {
    final backup = creaBackupJson();

    await Clipboard.setData(ClipboardData(text: backup));
    if (kIsWeb) {
      final now = DateTime.now();
      final stamp =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
      await oculumDownloadBytes(
        bytes: Uint8List.fromList(utf8.encode(backup)),
        fileName: 'oculum_backup_$stamp.json',
        mimeType: 'application/json',
      );
    }

    setState(() {
      risultato = t(
        kIsWeb
            ? 'Backup completo copiato e scaricato in JSON.'
            : 'Backup completo esportato negli appunti. Incollalo in un file di testo per conservarlo.',
        kIsWeb
            ? 'Full backup copied and downloaded as JSON.'
            : 'Full backup exported to clipboard. Paste it into a text file to keep it safe.',
      );

      aggiungiLog('Backup esportato negli appunti.');
    });
  }

  String get sheetShareCodePrefix => oculumSheetShareCodePrefix;

  Map<String, dynamic> schedaPerCodiceCondivisione(int index) {
    if (index < 0 || index >= schedePersonaggio.length) {
      return statoCorrenteJson();
    }

    return Map<String, dynamic>.from(
      jsonDecode(jsonEncode(schedePersonaggio[index])) as Map,
    );
  }

  String creaCodiceSchedeCondivisibili(Iterable<int> rawIndexes) {
    salvaSchedaCorrenteInMemoria();

    final indexes =
        rawIndexes
            .where((index) => index >= 0 && index < schedePersonaggio.length)
            .toSet()
            .toList()
          ..sort();

    if (indexes.isEmpty && schedePersonaggio.isNotEmpty) {
      indexes.add(schedaCorrente.clamp(0, schedePersonaggio.length - 1));
    }

    final payload = <String, dynamic>{
      'kind': 'oculum_sheets',
      'version': 1,
      'createdAt': DateTime.now().toIso8601String(),
      'sheets': indexes.map(schedaPerCodiceCondivisione).toList(),
    };

    return '$sheetShareCodePrefix${base64UrlEncode(utf8.encode(jsonEncode(payload)))}';
  }

  List<Map<String, dynamic>> schedeDaPayloadCodice(dynamic decoded) {
    if (decoded is! Map) {
      throw const FormatException('Payload non valido.');
    }

    final map = Map<String, dynamic>.from(decoded);
    final rawSheets = map['sheets'] ?? map['schedePersonaggio'];

    if (rawSheets is List) {
      return rawSheets
          .whereType<Map>()
          .map((sheet) => Map<String, dynamic>.from(sheet))
          .toList();
    }

    if (map.containsKey('nome') || map.containsKey('tipoScheda')) {
      return [map];
    }

    throw const FormatException('Nessuna scheda trovata.');
  }

  List<Map<String, dynamic>> decodificaCodiciScheda(String rawText) {
    return oculumDecodeSheetShareText(rawText);
  }

  Future<List<Map<String, dynamic>>> decodificaCodiciSchedaAsync(
    String rawText,
  ) async {
    if (kIsWeb || rawText.length < 48 * 1024) {
      return decodificaCodiciScheda(rawText);
    }
    try {
      return await compute(
        oculumDecodeSheetShareText,
        rawText,
        debugLabel: 'oculum-sheet-import-decode',
      );
    } catch (_) {
      return decodificaCodiciScheda(rawText);
    }
  }

  Map<String, dynamic> normalizzaSchedaImportata(Map<String, dynamic> raw) {
    final safeRaw = Map<String, dynamic>.from(
      jsonDecode(jsonEncode(raw)) as Map,
    );
    final nome = '${safeRaw['nome'] ?? 'Scheda importata'}'.trim();
    final tipo = '${safeRaw['tipoScheda'] ?? 'Personaggio'}'.trim();
    final base = statoVuotoPersonaggio(
      nome: nome.isEmpty ? 'Scheda importata' : nome,
      tipo: tipo.isEmpty ? 'Personaggio' : tipo,
      livello: readIntValue(safeRaw['livello']),
      grado: readIntValue(safeRaw['grado']),
    );

    base.addAll(safeRaw);

    const chiaviPrivate = <String>[
      'id',
      'sheetTag',
      'inMasterParty',
      'masterSideOverride',
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
      'realtimeRestrictedByMaster',
      'realtimeReadOnlyByMaster',
      'publicTokenSide',
      'publicInitiativeBase',
      'publicInitiativeTotal',
      'publicInitiativeRollHidden',
      'realtimeCoMaster',
      'realtimeShareWithFriends',
    ];

    for (final key in chiaviPrivate) {
      base.remove(key);
    }

    base['id'] = '';
    base['sheetTag'] = '';
    base['inMasterParty'] = false;
    base['masterSideOverride'] = '';

    return base;
  }

  Future<void> copiaCodiceSchedaCorrente() async {
    await copiaCodiceSchede({schedaCorrente});
  }

  Future<void> copiaCodiceSchedeSelezionate() async {
    await copiaCodiceSchede(selectedSheetCodeIndexes);
  }

  Future<void> copiaCodiceSchede(Iterable<int> indexes) async {
    final code = creaCodiceSchedeCondivisibili(indexes);
    await Clipboard.setData(ClipboardData(text: code));

    final count = decodificaCodiciScheda(code).length;

    if (!mounted) return;
    setState(() {
      sheetCodeController.text = code;
      risultato = t(
        'Codice copiato negli appunti. Schede incluse: $count.',
        'Code copied to clipboard. Included sheets: $count.',
      );
      aggiungiLog('Codice scheda copiato. Schede: $count.');
    });
  }

  Future<void> incollaCodiceSchedeDagliAppunti() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;

    setState(() {
      sheetCodeController.text = data?.text ?? '';
      risultato = sheetCodeController.text.trim().isEmpty
          ? t('Appunti vuoti.', 'Clipboard is empty.')
          : t(
              'Codice incollato nel riquadro. Premi Importa codice per salvarlo.',
              'Code pasted into the box. Press Import code to save it.',
            );
    });
  }

  Future<void> importaCodiceSchedeIncollato() async {
    try {
      final decodedSheets = await decodificaCodiciSchedaAsync(
        sheetCodeController.text,
      );
      final imported = preparaSchedeImportateUniche(
        decodedSheets.map(normalizzaSchedaImportata),
      );

      if (imported.isEmpty) {
        throw const FormatException('Nessuna scheda trovata.');
      }

      salvaSchedaCorrenteInMemoria();
      final globali = catturaImpostazioniGlobali();
      final startIndex = schedePersonaggio.length;

      setState(() {
        schedePersonaggio.addAll(imported);
        assicuraTagSchede();
        schedaCorrente = startIndex;
        caricaStatoDaJson(schedePersonaggio[schedaCorrente]);
        ripristinaImpostazioniGlobali(globali);
        selectedSheetCodeIndexes
          ..clear()
          ..addAll(
            List<int>.generate(
              imported.length,
              (offset) => startIndex + offset,
            ),
          );
        risultato = t(
          'Codice importato. Nuove schede salvate: ${imported.length}.',
          'Code imported. New saved sheets: ${imported.length}.',
        );
        aggiungiLog(
          'Codice scheda importato. Schede nuove: ${imported.length}.',
        );
      });

      await salvaDati();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        risultato = t(
          'Import fallito: codice scheda non valido o incompleto.',
          'Import failed: invalid or incomplete sheet code.',
        );
        aggiungiLog('Import codice scheda fallito: $error');
      });
    }
  }

  Future<void> importaBackupDaTesto(String testo) async {
    try {
      final pulito = testo.trim();

      if (pulito.isEmpty) {
        setState(() {
          risultato = t(
            'Import fallito: il testo è vuoto.',
            'Import failed: the text is empty.',
          );
        });

        return;
      }

      final decoded = kIsWeb || pulito.length < 48 * 1024
          ? jsonDecode(pulito)
          : await compute(
              oculumDecodeJsonText,
              pulito,
              debugLabel: 'oculum-backup-import-decode',
            );

      if (decoded is! Map<String, dynamic>) {
        throw Exception('Formato backup non valido.');
      }
      if (!mounted) return;

      if (readIntValue(decoded['versioneBackup']) >= 2 &&
          decoded['campaigns'] is List) {
        final mode = await showDialog<String>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(t('Importa backup completo', 'Import full backup')),
            content: Text(
              t(
                'Puoi aggiungere solo le schede senza toccare i dati attuali, oppure ripristinare campagne, scene, mappe e impostazioni. Prima del ripristino Oculum conserva comunque i backup recenti.',
                'You can add only the sheets without changing current data, or restore campaigns, scenes, maps and settings. Oculum still preserves recent backups before restoring.',
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(t('Annulla', 'Cancel')),
              ),
              OutlinedButton(
                onPressed: () => Navigator.pop(dialogContext, 'sheets'),
                child: Text(t('Aggiungi schede', 'Add sheets')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, 'full'),
                child: Text(t('Ripristina tutto', 'Restore all')),
              ),
            ],
          ),
        );
        if (!mounted || mode == null) return;
        if (mode == 'full') {
          final restored = await importaBackupCompletoProtetto(decoded);
          if (!mounted) return;
          setState(() {
            risultato = restored
                ? t(
                    'Backup completo ripristinato con protezione.',
                    'Full backup restored with protection.',
                  )
                : t(
                    'Ripristino completo non riuscito: i dati precedenti sono rimasti protetti.',
                    'Full restore failed: previous data remained protected.',
                  );
            aggiungiLog(risultato);
          });
          return;
        }
      }

      List<dynamic> rawSchede;

      if (decoded['multiScheda'] == true &&
          decoded['schedePersonaggio'] is List) {
        rawSchede = decoded['schedePersonaggio'] as List;
      } else {
        rawSchede = [decoded];
      }

      if (rawSchede.isEmpty) {
        throw Exception('Il backup non contiene schede.');
      }

      final nuoveSchede = preparaSchedeImportateUniche(
        rawSchede.whereType<Map>().map(
          (x) => normalizzaSchedaImportata(Map<String, dynamic>.from(x)),
        ),
      );

      if (nuoveSchede.isEmpty) {
        throw Exception('Il backup non contiene schede valide.');
      }

      salvaSchedaCorrenteInMemoria();
      final startIndex = schedePersonaggio.length;

      setState(() {
        schedePersonaggio.addAll(nuoveSchede);
        assicuraTagSchede();
        schedaCorrente = startIndex;

        caricaStatoDaJson(schedePersonaggio[schedaCorrente]);

        datiCaricati = true;

        risultato = t(
          'Backup importato. Nuove schede aggiunte: ${nuoveSchede.length}. Le schede esistenti non sono state sovrascritte.',
          'Backup imported. New sheets added: ${nuoveSchede.length}. Existing sheets were not overwritten.',
        );

        aggiungiLog(
          'Backup importato senza sovrascrivere. Schede nuove: ${nuoveSchede.length}.',
        );
      });

      await salvaDati();
    } catch (e) {
      setState(() {
        risultato = t(
          'Import fallito: il testo non sembra un backup valido di Oculum.',
          'Import failed: the text does not seem to be a valid Oculum backup.',
        );

        aggiungiLog('Import backup fallito: $e');
      });
    }
  }

  void mostraDialogImportBackup() {
    final importController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF10121A),
          title: Text(
            t('Importa Backup', 'Import Backup'),
            style: TextStyle(color: tertiaryColor, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  smallInfoText(
                    t(
                      'Incolla qui il testo JSON esportato da Oculum. Attenzione: l’import sostituirà le schede salvate attuali.',
                      'Paste here the JSON text exported from Oculum. Warning: importing will replace the current saved sheets.',
                    ),
                    color: tertiaryColor,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: importController,
                    maxLines: 14,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: fieldDecoration(
                      t('Incolla backup JSON', 'Paste JSON backup'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(t('Annulla', 'Cancel')),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final testo = importController.text;
                Navigator.pop(context);
                await importaBackupDaTesto(testo);
              },
              icon: const Icon(Icons.upload_file),
              style: ElevatedButton.styleFrom(
                backgroundColor: tertiaryColor,
                foregroundColor: tertiaryColor.computeLuminance() > 0.45
                    ? Colors.black
                    : Colors.white,
              ),
              label: Text(t('Importa', 'Import')),
            ),
          ],
        );
      },
    ).whenComplete(importController.dispose);
  }

  Color withAdvancedColor({
    required Color base,
    required double luminosita,
    required double saturazione,
    required double opacita,
  }) {
    final hsl = HSLColor.fromColor(base);

    final adjusted = hsl
        .withLightness(luminosita.clamp(0.0, 1.0))
        .withSaturation(saturazione.clamp(0.0, 1.0))
        .toColor();

    return adjusted.withValues(alpha: opacita.clamp(0.12, 1.0));
  }

  Widget colorPreviewSmall(Color color) {
    return Container(
      width: 56,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.18),
            blurRadius: 7,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  OculumColorPreset? colorPresetById(String id) {
    for (final preset in colorPresets) {
      if (preset.id == id) return preset;
    }
    return null;
  }

  int colorPresetDisplayRank(String id) {
    switch (id) {
      case 'classic_reliquary':
        return 0;
      case 'classic_rpg':
        return 1;
      case 'classic_low_detail':
        return 2;
    }
    final index = colorPresets.indexWhere((preset) => preset.id == id);
    return index < 0 ? 999999 : 100 + index;
  }

  List<OculumColorPreset> orderedColorPresets({
    bool visibleOnly = false,
    bool unlockedOnly = false,
  }) {
    final presets = [
      for (final preset in colorPresets)
        if ((!visibleOnly || isColorThemeVisibleInPicker(preset)) &&
            (!unlockedOnly || isColorThemeUnlocked(preset.id)))
          preset,
    ];
    presets.sort(
      (a, b) =>
          colorPresetDisplayRank(a.id).compareTo(colorPresetDisplayRank(b.id)),
    );
    return presets;
  }

  List<String> orderedColorPresetIds(Iterable<String> ids) {
    final unique = <String>{};
    final ordered = [
      for (final id in ids)
        if (unique.add(id)) id,
    ];
    ordered.sort(
      (a, b) => colorPresetDisplayRank(a).compareTo(colorPresetDisplayRank(b)),
    );
    return ordered;
  }

  String colorPresetName(OculumColorPreset preset) {
    return t(preset.nameIt, preset.nameEn);
  }

  String colorPresetDescription(OculumColorPreset preset) {
    return t(preset.descriptionIt, preset.descriptionEn);
  }

  bool isColorThemeUnlocked(String id) {
    return id == 'classic_reliquary' ||
        id == 'classic_rpg' ||
        oculumThemeStartsUnlocked(id) ||
        (id == 'hoshy_cosmic_cat' && hoshySecretThemeCondition()) ||
        (id == 'phobia_dark' && phobiaSecretThemeCondition()) ||
        unlockedColorThemeIds.contains(id);
  }

  bool isColorThemeVisibleInPicker(OculumColorPreset preset) {
    if (preset.id == 'hoshy_cosmic_cat' || preset.id == 'phobia_dark') {
      return isColorThemeUnlocked(preset.id);
    }
    return true;
  }

  void markCustomColorPreset() {
    colorPresetSelezionato = 'custom';
  }

  void setColorDecorationPreset(String id) {
    if (id == 'none') {
      colorDecorationPresetId = 'none';
      return;
    }
    final preset = colorPresetById(id);
    if (preset == null || !isColorThemeUnlocked(id)) return;
    colorDecorationPresetId = preset.id;
  }

  void setColorGuiPreset(String id) {
    final clean = id.trim();
    if (isBuiltInGuiModeId(clean)) {
      colorGuiPresetId = clean;
      return;
    }
    final preset = colorPresetById(clean);
    if (preset == null || !isColorThemeUnlocked(clean)) return;
    colorGuiPresetId = preset.id;
  }

  void applicaDecorazioneNessuna() {
    setState(() {
      colorDecorationPresetId = 'none';
      risultato = t(
        'Decorazioni disattivate. La palette attuale resta invariata.',
        'Decorations disabled. Current palette is unchanged.',
      );
      aggiungiLog(risultato);
    });
    programmaSalvataggio();
  }

  void applicaDecorazioneColorPreset(String id) {
    final preset = colorPresetById(id);
    if (preset == null || !isColorThemeUnlocked(id)) return;
    setState(() {
      setColorDecorationPreset(id);
      risultato = t(
        'Decorazioni applicate: ${themeDecorationLabel(id)}. I colori attuali restano invariati.',
        'Decorations applied: ${themeDecorationLabel(id)}. Current colors are unchanged.',
      );
      aggiungiLog(risultato);
    });
    programmaSalvataggio();
  }

  void applicaGuiColorPreset(String id) {
    final clean = id.trim();
    final preset = colorPresetById(clean);
    if (!isBuiltInGuiModeId(clean) &&
        (preset == null || !isColorThemeUnlocked(clean))) {
      return;
    }
    setState(() {
      setColorGuiPreset(clean);
      risultato = t(
        'GUI applicata: ${guiSkinLabel(clean)}. Colori, disegni e tema restano invariati.',
        'GUI applied: ${guiSkinLabel(clean)}. Colors, drawings and theme stay unchanged.',
      );
      aggiungiLog(risultato);
    });
    programmaSalvataggio();
  }

  void applicaSoloColoriPreset(String id) {
    final preset = colorPresetById(id);
    if (preset == null || !isColorThemeUnlocked(id)) return;
    setState(() {
      primaryColor = preset.primary;
      secondaryColor = preset.secondary;
      tertiaryColor = preset.tertiary;
      eyeUtilityColor = preset.utility;
      oculumStatFormulaColor = preset.oculumFormula;
      backgroundTopColor = preset.backgroundTop;
      backgroundMidColor = preset.backgroundMid;
      backgroundBottomColor = preset.backgroundBottom;
      eyePupilGlowColor = preset.eyePupilGlow;
      colorPresetSelezionato = preset.id;
      normalizzaContrastoTemaAttivo();
      risultato = t(
        'Solo colori applicati: ${preset.nameIt}. GUI e decorazioni non cambiano.',
        'Colors only applied: ${preset.nameEn}. GUI and decorations do not change.',
      );
      aggiungiLog(risultato);
    });
    programmaSalvataggio();
  }

  void applicaColorPreset(String id) {
    final preset = colorPresetById(id);
    if (preset == null) return;

    if (!isColorThemeUnlocked(id)) {
      setState(() {
        risultato = id == 'hoshy_cosmic_cat'
            ? t(
                'Tema segreto bloccato: una scheda deve chiamarsi Hoshy.',
                'Secret theme locked: a sheet must be named Hoshy.',
              )
            : id == 'phobia_dark'
            ? t(
                'Tema segreto bloccato: una scheda deve chiamarsi Vergil oppure sbloccalo nel dungeon.',
                'Secret theme locked: a sheet must be named Vergil or unlock it in the dungeon.',
              )
            : t(
                'Tema bloccato: gioca al minigioco Oculum per sbloccarlo.',
                'Locked theme: play the Oculum minigame to unlock it.',
              );
        aggiungiLog(risultato);
      });
      return;
    }

    final keepExplicitGui =
        isBuiltInGuiModeId(colorGuiPresetId) && colorGuiPresetId != 'gui_auto';
    setState(() {
      primaryColor = preset.primary;
      secondaryColor = preset.secondary;
      tertiaryColor = preset.tertiary;
      eyeUtilityColor = preset.utility;
      oculumStatFormulaColor = preset.oculumFormula;
      backgroundTopColor = preset.backgroundTop;
      backgroundMidColor = preset.backgroundMid;
      backgroundBottomColor = preset.backgroundBottom;
      eyePupilGlowColor = preset.eyePupilGlow;
      colorPresetSelezionato = preset.id;
      normalizzaContrastoTemaAttivo();
      colorDecorationPresetId =
          (preset.id == 'classic_reliquary' ||
              preset.id == 'classic_low_detail')
          ? 'none'
          : preset.id;
      if (!keepExplicitGui) {
        colorGuiPresetId = preset.id;
      }
      if (preset.id == 'classic_low_detail') {
        themeDecorationOpacityScale = 0.6;
        themeDecorationGlowScale = 0.45;
        themeDecorationIntensityScale = 0.55;
      } else if (preset.id == 'classic_reliquary') {
        themeDecorationOpacityScale = 1.0;
        themeDecorationGlowScale = 1.0;
        themeDecorationIntensityScale = 1.0;
      }
      risultato = keepExplicitGui
          ? t(
              'Tema applicato: ${preset.nameIt}. Colori e disegni aggiornati; GUI fissa mantenuta: ${guiSkinLabel(colorGuiPresetId)}.',
              'Theme applied: ${preset.nameEn}. Colors and drawings updated; fixed GUI kept: ${guiSkinLabel(colorGuiPresetId)}.',
            )
          : t(
              'Tema applicato: ${preset.nameIt}. Colori, GUI e decorazioni aggiornati.',
              'Theme applied: ${preset.nameEn}. Colors, GUI and decorations updated.',
            );
      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  void unlockColorThemeFromDungeon(String presetId) {
    final preset = colorPresetById(presetId);
    if (preset == null || isColorThemeUnlocked(presetId)) return;

    setState(() {
      unlockedColorThemeIds.add(presetId);
      risultato = t(
        'Tema sbloccato dal minigioco: ${preset.nameIt}.',
        'Theme unlocked from the minigame: ${preset.nameEn}.',
      );
      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  Widget colorPresetSwatches(OculumColorPreset preset, {double size = 18}) {
    final colors = [
      preset.primary,
      preset.secondary,
      preset.tertiary,
      preset.utility,
      preset.oculumFormula,
      preset.backgroundMid,
      preset.eyePupilGlow,
    ];

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (final color in colors)
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24),
            ),
          ),
      ],
    );
  }

  Widget colorPresetDropdownPanel() {
    final selectedPreset = colorPresetById(colorPresetSelezionato);
    final dropdownValue =
        selectedPreset != null && isColorThemeUnlocked(selectedPreset.id)
        ? selectedPreset.id
        : 'custom';
    final screenWidth = MediaQuery.maybeOf(context)?.size.width ?? 420;
    final itemWidth = min(360.0, max(220.0, screenWidth - 86));

    return gothicPanel(
      borderColor: tertiaryColor,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('Disposizione colori', 'Color arrangement'),
            style: TextStyle(
              color: tertiaryColor,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          smallInfoText(
            t(
              'Preset intelligenti per testi, occhio, sfondo sfumato e bagliore arancio-rossastro vicino alla pupilla. I temi nuovi si sbloccano giocando al minigioco.',
              'Smart presets for text, eye, gradient background and the orange-red glow near the pupil. New themes unlock by playing the minigame.',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: dropdownValue,
            isExpanded: true,
            dropdownColor: const Color(0xFF11131A),
            decoration: fieldDecoration(t('Tema colore', 'Color theme')),
            items: [
              DropdownMenuItem<String>(
                value: 'custom',
                child: Text(t('Personalizzato', 'Custom')),
              ),
              for (final preset in orderedColorPresets(visibleOnly: true))
                if (isColorThemeVisibleInPicker(preset))
                  DropdownMenuItem<String>(
                    value: preset.id,
                    enabled: isColorThemeUnlocked(preset.id),
                    child: Opacity(
                      opacity: isColorThemeUnlocked(preset.id) ? 1 : 0.45,
                      child: SizedBox(
                        width: itemWidth,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 132,
                              child: colorPresetSwatches(preset, size: 12),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                isColorThemeUnlocked(preset.id)
                                    ? colorPresetName(preset)
                                    : '${colorPresetName(preset)} (${t('bloccato', 'locked')})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
            ],
            onChanged: (value) {
              if (value == null) return;
              if (value == 'custom') {
                setState(() {
                  colorPresetSelezionato = 'custom';
                });
                programmaSalvataggio();
                return;
              }
              applicaColorPreset(value);
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final preset in orderedColorPresets(visibleOnly: true))
                if (isColorThemeVisibleInPicker(preset))
                  Tooltip(
                    message:
                        '${colorPresetName(preset)} - ${colorPresetDescription(preset)}',
                    child: ActionChip(
                      avatar: Icon(
                        isColorThemeUnlocked(preset.id)
                            ? Icons.palette
                            : Icons.lock,
                        size: 16,
                        color: isColorThemeUnlocked(preset.id)
                            ? preset.tertiary
                            : Colors.grey,
                      ),
                      backgroundColor: preset.secondary.withValues(alpha: 0.78),
                      side: BorderSide(
                        color: colorPresetSelezionato == preset.id
                            ? preset.tertiary
                            : Colors.white24,
                      ),
                      label: Text(
                        colorPresetName(preset),
                        style: TextStyle(
                          color: isColorThemeUnlocked(preset.id)
                              ? preset.primary
                              : Colors.grey.shade500,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: isColorThemeUnlocked(preset.id)
                          ? () => applicaColorPreset(preset.id)
                          : null,
                    ),
                  ),
            ],
          ),
        ],
      ),
    );
  }

  Widget compactColorSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String shownValue,
    required void Function(double) onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            label: shownValue,
            activeColor: tertiaryColor,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 48,
          child: Text(
            shownValue,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget advancedColorPanel({
    required String target,
    required Color currentColor,
    required void Function(Color) onSelected,
  }) {
    int r = (currentColor.r * 255.0).round().clamp(0, 255);
    int g = (currentColor.g * 255.0).round().clamp(0, 255);
    int b = (currentColor.b * 255.0).round().clamp(0, 255);

    double opacity = currentColor.a;
    HSLColor hsl = HSLColor.fromColor(currentColor);
    double lightness = hsl.lightness;
    double saturation = hsl.saturation;

    return StatefulBuilder(
      builder: (context, setLocalState) {
        final rawColor = Color.fromARGB(255, r, g, b);

        final preview = withAdvancedColor(
          base: rawColor,
          luminosita: lightness,
          saturazione: saturation,
          opacita: opacity,
        );

        void applyLive() {
          setState(() {
            markCustomColorPreset();
            onSelected(preview);
            risultato = t(
              'Colore $target aggiornato.',
              '$target color updated.',
            );
            aggiungiLog('Colore $target aggiornato.');
          });
          programmaSalvataggio();
        }

        return gothicPanel(
          borderColor: preview.withValues(alpha: 0.85),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  colorPreviewSmall(preview),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      t(
                        '$target — RGB, luminosità, saturazione, opacità',
                        '$target — RGB, lightness, saturation, opacity',
                      ),
                      style: TextStyle(
                        color: preview,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              smallInfoText(
                t(
                  'Riquadro compatto: modifica il colore senza occupare troppo spazio. L’opacità influenza quanto il colore appare trasparente nei punti dove viene applicato.',
                  'Compact panel: edit the color without taking too much space. Opacity affects how transparent the color appears where it is applied.',
                ),
              ),
              const SizedBox(height: 8),
              compactColorSlider(
                label: 'R',
                value: r.toDouble(),
                min: 0,
                max: 255,
                divisions: 255,
                shownValue: '$r',
                onChanged: (value) {
                  setLocalState(() {
                    r = value.round();
                    hsl = HSLColor.fromColor(Color.fromARGB(255, r, g, b));
                  });
                },
              ),
              compactColorSlider(
                label: 'G',
                value: g.toDouble(),
                min: 0,
                max: 255,
                divisions: 255,
                shownValue: '$g',
                onChanged: (value) {
                  setLocalState(() {
                    g = value.round();
                    hsl = HSLColor.fromColor(Color.fromARGB(255, r, g, b));
                  });
                },
              ),
              compactColorSlider(
                label: 'B',
                value: b.toDouble(),
                min: 0,
                max: 255,
                divisions: 255,
                shownValue: '$b',
                onChanged: (value) {
                  setLocalState(() {
                    b = value.round();
                    hsl = HSLColor.fromColor(Color.fromARGB(255, r, g, b));
                  });
                },
              ),
              compactColorSlider(
                label: t('Luminosità', 'Lightness'),
                value: lightness,
                min: 0,
                max: 1,
                divisions: 100,
                shownValue: '${(lightness * 100).round()}%',
                onChanged: (value) {
                  setLocalState(() => lightness = value);
                },
              ),
              compactColorSlider(
                label: t('Saturazione', 'Saturation'),
                value: saturation,
                min: 0,
                max: 1,
                divisions: 100,
                shownValue: '${(saturation * 100).round()}%',
                onChanged: (value) {
                  setLocalState(() => saturation = value);
                },
              ),
              compactColorSlider(
                label: t('Opacità', 'Opacity'),
                value: opacity,
                min: 0.12,
                max: 1,
                divisions: 88,
                shownValue: '${(opacity * 100).round()}%',
                onChanged: (value) {
                  setLocalState(() => opacity = value);
                },
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: applyLive,
                icon: const Icon(Icons.palette),
                style: ElevatedButton.styleFrom(
                  backgroundColor: preview,
                  foregroundColor: preview.computeLuminance() > 0.45
                      ? Colors.black
                      : Colors.white,
                  minimumSize: const Size.fromHeight(42),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                label: Text(t('Applica colore', 'Apply color')),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget colorDropdown({
    required String label,
    required String value,
    required void Function(String) onChanged,
  }) {
    final categorie = categorieColori();

    return DropdownButtonFormField<String>(
      initialValue: categorie.contains(value) ? value : 'Tutti',
      dropdownColor: const Color(0xFF11131A),
      decoration: fieldDecoration(label),
      items: categorie
          .map(
            (categoria) => DropdownMenuItem<String>(
              value: categoria,
              child: Text(categoria),
            ),
          )
          .toList(),
      onChanged: (nuovoValore) {
        if (nuovoValore == null) return;
        setState(() => onChanged(nuovoValore));
        programmaSalvataggio();
      },
    );
  }

  Widget colorPicker({
    required String titolo,
    required Color selectedColor,
    required String filtro,
    required void Function(String) onFiltroChanged,
    required void Function(Color) onSelected,
    required bool editorAperto,
    required VoidCallback onToggleEditor,
  }) {
    final colori = coloriFiltrati(filtro);

    return gothicPanel(
      borderColor: selectedColor.withValues(alpha: 0.85),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onToggleEditor,
                child: Tooltip(
                  message: editorAperto
                      ? t('Chiudi editor RGB', 'Close RGB editor')
                      : t('Apri editor RGB', 'Open RGB editor'),
                  child: Container(
                    width: 56,
                    height: 32,
                    decoration: BoxDecoration(
                      color: selectedColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: editorAperto
                            ? tertiaryColor
                            : Colors.white.withValues(alpha: 0.65),
                        width: editorAperto ? 2.2 : 1.1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: selectedColor.withValues(alpha: 0.22),
                          blurRadius: editorAperto ? 12 : 7,
                          spreadRadius: editorAperto ? 1.5 : 1,
                        ),
                      ],
                    ),
                    child: Icon(
                      editorAperto ? Icons.expand_less : Icons.tune,
                      color: selectedColor.computeLuminance() > 0.45
                          ? Colors.black
                          : Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  titolo,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: selectedColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          smallInfoText(
            t(
              'Tocca il quadratino colore per aprire o chiudere l’editor RGB avanzato.',
              'Tap the color square to open or close the advanced RGB editor.',
            ),
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          colorDropdown(
            label: t('Filtro colore', 'Color filter'),
            value: filtro,
            onChanged: onFiltroChanged,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: colori.map((option) {
              final selected =
                  selectedColor.toARGB32() == option.color.toARGB32();

              return Tooltip(
                message: '${option.name} — ${option.category}',
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      markCustomColorPreset();
                      onSelected(option.color);
                      aggiungiLog('Colore scelto: ${option.name}.');
                    });
                    programmaSalvataggio();
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: option.color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? Colors.white : Colors.black54,
                        width: selected ? 2.5 : 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: option.color.withValues(
                            alpha: selected ? 0.30 : 0.14,
                          ),
                          blurRadius: selected ? 8 : 4,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // TUTORIAL
  // =====================================================

  void applicaSettaggioTutorial() {
    final livello = max(0, leggiNumero(tutorialLevelController));
    final extraRes = leggiNumero(tutorialExtraResController);
    final extraVol = leggiNumero(tutorialExtraVolController);
    final extraMat = leggiNumero(tutorialExtraMatController);
    final extraOcu = leggiNumero(tutorialExtraOcuController);

    setState(() {
      livelloController.text = livello.toString();

      resilienzaController.text = (3 + extraRes).toString();
      volontaController.text = (1 + extraVol).toString();
      materiaController.text = (0 + extraMat).toString();
      oculumController.text = (1 + extraOcu).toString();
      currentResilienzaController.text = resilienzaController.text;
      currentVolontaController.text = volontaController.text;
      currentMateriaController.text = materiaController.text;
      currentOculumController.text = oculumController.text;

      aggiornaGradoAutomatico();
      refullaHp();

      tutorialCompletato = true;

      risultato = t(
        'Tutorial applicato. Scheda inizializzata dal livello $livello.',
        'Tutorial applied. Sheet initialized from level $livello.',
      );

      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  void mostraTutorial() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF10121A),
          title: Text(
            'Tutorial Oculum',
            style: TextStyle(color: tertiaryColor, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t('Setup iniziale', 'Starting setup'),
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  smallInfoText(
                    t(
                      'Il tutorial parte da livello 0. Il livello 0 serve per creare la scheda senza forzare subito il primo avanzamento. I Titoli del Fato non dipendono dal livello del personaggio, ma dal livello delle Skill nelle Art.',
                      'The tutorial starts at level 0. Level 0 lets you create the sheet without forcing the first advancement immediately. Fate Titles do not depend on character level, but on Skill levels inside Arts.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  campoTesto(
                    label: t('Livello iniziale', 'Starting level'),
                    controller: tutorialLevelController,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: campoTesto(
                          label: 'Extra RES',
                          controller: tutorialExtraResController,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: campoTesto(
                          label: 'Extra VOL',
                          controller: tutorialExtraVolController,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: campoTesto(
                          label: 'Extra MAT',
                          controller: tutorialExtraMatController,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: campoTesto(
                          label: 'Extra OCU',
                          controller: tutorialExtraOcuController,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    t('Regole fondamentali', 'Core rules'),
                    style: TextStyle(
                      color: tertiaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t(
                      '• Resilienza aumenta gli HP massimi.\n'
                          '• Volontà aumenta danno, difesa, VC e peso trasportabile.\n'
                          '• Materia aumenta CM e Difesa.\n'
                          '• Oculum potenzia Arti, cerchi, rituali e poteri oculari.\n'
                          '• Lo Scudo Critico dimezza i danni finché non viene spezzato da un critico in fight.\n'
                          '• I Titoli del Fato si ottengono dalle Skill delle Art: prima Skill livello 1, seconda Skill livello 2, terza Skill livello 3.\n'
                          '• Le pagine diario possono dare Ispirazioni.\n'
                          '• I Gradi vengono controllati automaticamente in base al livello e al Rebirth.',
                      '• Resilience increases max HP.\n'
                          '• Will increases damage, defense, VC and carrying weight.\n'
                          '• Materia increases CM and Defense.\n'
                          '• Oculum empowers Arts, circles, rituals and eye powers.\n'
                          '• Critical Shield halves damage until broken by a critical during combat.\n'
                          '• Fate Titles are gained from Art Skills: first Skill level 1, second Skill level 2, third Skill level 3.\n'
                          '• Diary pages can grant Inspirations.\n'
                          '• Grades are checked automatically based on level and Rebirth.',
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    t('Funzioni principali', 'Main features'),
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t(
                      'Scheda: HP, danni, cura, tiri, stats, livello e grado.\n'
                          'Riposo: bisogni, cenere, recuperi e attività pesanti.\n'
                          'Titoli: buff, karma, Open e punti ciechi.\n'
                          'Art: nome, tipo e descrizione delle Art.\n'
                          'Skill: skill scritte e creazione skill.\n'
                          'Storia: background e diario.\n'
                          'Risorse: Obser, polveri e Ispirazioni.\n'
                          'Impostazioni: colori avanzati, log, lingua e tutorial.',
                      'Sheet: HP, damage, healing, rolls, stats, level and grade.\n'
                          'Rest: needs, ash, recovery and heavy activities.\n'
                          'Titles: buffs, Karma, Opens and blind spots.\n'
                          'Arts: Art name, type and description.\n'
                          'Skills: written skills and skill creation.\n'
                          'Story: background and diary.\n'
                          'Resources: Obser, powders and Inspirations.\n'
                          'Settings: advanced colors, log, language and tutorial.',
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  tutorialCompletato = true;
                  aggiungiLog('Tutorial skippato/completato.');
                });
                programmaSalvataggio();
                Navigator.pop(context);
              },
              child: Text(t('Skippa', 'Skip')),
            ),
            ElevatedButton(
              onPressed: () {
                applicaSettaggioTutorial();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: tertiaryColor,
                foregroundColor: tertiaryColor.computeLuminance() > 0.45
                    ? Colors.black
                    : Colors.white,
              ),
              child: Text(t('Applica e inizia', 'Apply and start')),
            ),
          ],
        );
      },
    ).whenComplete(() {
      tutorialDialogPending = false;
    });
  }

  void mostraTutorialSeNecessario() {
    if (tutorialCompletato || tutorialDialogPending) return;

    tutorialDialogPending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      mostraTutorial();
    });
  }

  // =====================================================
  // CERCA
  // =====================================================

  List<Map<String, dynamic>> searchResults(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];

    final results = <Map<String, dynamic>>[];
    final labels = linguaInglese ? pageNamesEn : pageNamesIt;

    for (int i = 0; i < labels.length; i++) {
      if (oculumSearchScore(q, labels[i]) > 0) {
        results.add({
          'title': labels[i],
          'subtitle': t('Pagina app', 'App page'),
          'page': i,
        });
      }
    }

    final funzioni = <Map<String, dynamic>>[
      {
        'key': 'danno damage subito ferita subisci colpo',
        'title': t('Danno', 'Damage'),
        'page': 0,
        'anchorId': 'sheet_damage',
      },
      {
        'key': 'cura heal guarigione recupero vita guarire',
        'title': t('Cura', 'Healing'),
        'page': 0,
        'anchorId': 'sheet_heal',
      },
      {
        'key':
            'danno cura damage heal gestione vita hp scudo critico resistenza fragilita fragilità',
        'title': t('Danno / Cura', 'Damage / Healing'),
        'page': 0,
        'anchorId': 'sheet_damage_heal',
      },
      {
        'key': 'hp vita salute punti ferita current hp temp scudo',
        'title': 'HP',
        'page': 0,
        'anchorId': 'sheet_hp',
      },
      {
        'key': 'vc valore combattimento tiro combattimento',
        'title': 'VC',
        'page': 0,
        'anchorId': 'sheet_combat_values',
      },
      {
        'key': 'cm classe mentale mente tiro mentale',
        'title': 'CM',
        'page': 0,
        'anchorId': 'sheet_combat_values',
      },
      {
        'key': 'difesa defense protezione',
        'title': t('Difesa', 'Defense'),
        'page': 0,
        'anchorId': 'sheet_combat_values',
      },
      {
        'key': 'danni danno totale damage bonus arma',
        'title': t('Danni', 'Damage'),
        'page': 0,
        'anchorId': 'sheet_combat_values',
      },
      {
        'key': 'level up grado rebirth exp esperienza livello',
        'title': t('Level up / Esperienza', 'Level up / Experience'),
        'page': 0,
        'anchorId': 'sheet_exp',
      },
      {
        'key': 'riposo cenere mangia bevi sonno bisogni stati',
        'title': t('Riposo', 'Rest'),
        'page': 1,
        'anchorId': 'rest_root',
      },
      {
        'key': 'titoli open fato karma punto cieco',
        'title': t('Titoli', 'Titles'),
        'page': 2,
        'anchorId': 'titles_root',
      },
      {
        'key': 'aggiungi titolo crea nuovo title add create',
        'title': t('Aggiungi Titolo', 'Add Title'),
        'page': 2,
        'anchorId': 'titles_create',
      },
      {
        'key':
            'comandi rapidi titoli vc cm def difesa danni damage scudo res vol mat ocu',
        'title': t('Comandi rapidi Titoli', 'Title quick commands'),
        'page': 2,
        'anchorId': 'titles_quick_commands',
      },
      {
        'key': 'art nome tipo descrizione dati art',
        'title': t('Art', 'Arts'),
        'page': 3,
        'anchorId': 'art_root',
      },
      {
        'key': 'skill scritte crea creazione tecniche talenti poteri',
        'title': t('Skill', 'Skills'),
        'page': 4,
        'anchorId': 'skills_root',
      },
      {
        'key': 'background diario storia ispirazioni',
        'title': t('Storia', 'Story'),
        'page': 5,
        'anchorId': 'story_root',
      },
      {
        'key': 'inventario peso arma oggetto borsa',
        'title': t('Borsa', 'Bag'),
        'page': 6,
        'anchorId': 'inventory_root',
      },
      {
        'key': 'obser risorse ascension dust ispirazioni diamanti',
        'title': t('Risorse', 'Resources'),
        'page': 7,
        'anchorId': 'resources_root',
      },
      {
        'key': 'manuale regole cerca indice',
        'title': t('Regole', 'Rules'),
        'page': 8,
        'anchorId': 'rules_root',
      },
      {
        'key': 'master mostro scheda rapida npc boss',
        'title': 'Master',
        'page': 9,
        'anchorId': 'master_root',
      },
      {
        'key':
            'iniziativa master turno round npc mostri boss summon partecipanti note acted skipped dead ordine manuale',
        'title': t('Iniziativa Master', 'Master Initiative'),
        'page': 9,
        'anchorId': 'master_root',
      },
      {
        'key':
            'impostazioni colori rgb luminosita luminosità saturazione opacita opacità log tutorial scudo oculum mostra sempre senza buff',
        'title': t('Opzioni', 'Options'),
        'page': _OculumHomePageState.settingsPageIndex,
        'anchorId': 'settings_root',
      },
      {
        'key':
            'scudo oculum mostra sempre senza buff vita barra hp shield oculumshield',
        'title': t('Mostra sempre Scudo Oculum', 'Always show Oculum Shield'),
        'page': _OculumHomePageState.settingsPageIndex,
        'anchorId': 'settings_oculum_shield',
      },
      {
        'key':
            'online connessione internet party tag master sync realtime supabase relay',
        'title': 'Online',
        'page': _OculumHomePageState.onlinePageIndex,
        'anchorId': 'online_root',
      },
      {
        'key':
            'dungeon minigioco run pawn mostri boss reward drop exp null fateless',
        'title': 'Dungeon',
        'page': 0,
        'action': 'dungeon',
      },
    ];

    for (final funzione in funzioni) {
      final key = '${funzione['key']} ${funzione['title']}';
      if (oculumSearchScore(q, key) > 0) {
        results.add({
          'title': funzione['title'] ?? key,
          'subtitle': t('Funzione rapida', 'Quick function'),
          'page': funzione['page'],
          'anchorId': funzione['anchorId'],
          'action': funzione['action'],
        });
      }
    }

    for (int i = 0; i < activeManualSections.length; i++) {
      final sec = activeManualSections[i];

      if (oculumSearchScore(
            q,
            '${manualTitle(sec)} ${manualContent(sec)} ${sec.titleIt} ${sec.titleEn} ${sec.contentIt} ${sec.contentEn}',
          ) >
          0) {
        results.add({
          'title': manualTitle(sec),
          'subtitle': t('Sezione Manuale', 'Manual section'),
          'page': 8,
          'anchorId': 'rules_open_section',
          'manualIndex': i,
        });
      }
    }

    void addUserResult({
      required String title,
      required String subtitle,
      required String haystack,
      required int page,
      String? anchorId,
    }) {
      final score = oculumSearchScore(q, '$title $subtitle $haystack');
      if (score <= 0) return;
      results.add({
        'title': title,
        'subtitle': subtitle,
        'page': page,
        'anchorId': anchorId,
        'score': score,
      });
    }

    for (int i = 0; i < titoli.length; i++) {
      final titolo = titoli[i];
      addUserResult(
        title: titolo.nome.trim().isEmpty
            ? t('Titolo senza nome', 'Unnamed title')
            : titolo.nome,
        subtitle: t('Titolo creato dall’utente', 'User-created title'),
        haystack:
            '${titolo.tipo} ${titolo.ottenimento} ${titolo.buff} ${titolo.puntoCieco} ${titolo.skill} ${titolo.richiede} ${titolo.openName} ${titolo.openDescription} ${titolo.openBuff} ${titolo.openSkill}',
        page: 2,
        anchorId: titleEditorAnchorId(titolo),
      );
    }

    for (int i = 0; i < trattiRazziali.length; i++) {
      final tratto = trattiRazziali[i];
      addUserResult(
        title: tratto.nome.trim().isEmpty
            ? t('Tratto razziale senza nome', 'Unnamed racial trait')
            : tratto.nome,
        subtitle: t('Tratto razziale / Razza', 'Racial trait / Race'),
        haystack:
            '${tratto.tipo} ${tratto.ottenimento} ${tratto.buff} ${tratto.puntoCieco} ${tratto.skill} ${tratto.richiede} ${tratto.openName} ${tratto.openDescription} ${tratto.openBuff} ${tratto.openSkill}',
        page: 2,
        anchorId: titleEditorAnchorId(tratto, trattoRazziale: true),
      );
    }

    for (int i = 0; i < skills.length; i++) {
      final skill = skills[i];
      addUserResult(
        title: skill.nome.trim().isEmpty
            ? t('Skill senza nome', 'Unnamed skill')
            : skill.nome,
        subtitle: t('Skill creata dall’utente', 'User-created skill'),
        haystack:
            '${skill.tipo} ${skill.costo} ${skill.cooldown} ${skill.descrizione}',
        page: 4,
        anchorId: 'free_skill_$i',
      );
    }

    for (int i = 0; i < arti.length; i++) {
      final art = arti[i];
      addUserResult(
        title: art.nome.trim().isEmpty ? 'Art' : art.nome,
        subtitle: t('Art / Open', 'Art / Open'),
        haystack: '${art.tipo} ${art.descrizione}',
        page: 3,
        anchorId: 'art_$i',
      );

      addUserResult(
        title: '${t('Open', 'Open')}: ${artOpenDisplayName(art, i)}',
        subtitle: t('Open Art', 'Art Open'),
        haystack:
            '${art.openName} ${art.openDescription} ${art.openBuff} ${art.openSkill}',
        page: 3,
        anchorId: 'art_${i}_open',
      );

      for (int skillIndex = 0; skillIndex < art.skills.length; skillIndex++) {
        final skill = art.skills[skillIndex];
        addUserResult(
          title:
              '${t('Skill', 'Skill')}: ${skill.nome.trim().isEmpty ? '${skillIndex + 1}' : skill.nome}',
          subtitle: art.nome.trim().isEmpty
              ? t('Skill Art', 'Art Skill')
              : '${t('Skill Art', 'Art Skill')}: ${art.nome}',
          haystack:
              '${skill.nome} ${skill.evo1} ${skill.evo2} ${skill.evo3} ${skill.evo4} ${skill.evo5}',
          page: 3,
          anchorId: 'art_${i}_skill_$skillIndex',
        );
      }
    }

    for (final item in inventario) {
      addUserResult(
        title: item.nome.trim().isEmpty
            ? t('Oggetto senza nome', 'Unnamed item')
            : item.nome,
        subtitle: item.arma && item.protegge
            ? t('Arma / Protezione', 'Weapon / Protection')
            : item.arma
            ? t('Arma / Inventario', 'Weapon / Inventory')
            : item.protegge
            ? t('Protezione / Inventario', 'Protection / Inventory')
            : t('Inventario', 'Inventory'),
        haystack:
            '${item.buff} ${item.note} ${item.elementoDanno} ${item.bonusDanno} ${item.bonusDifesa} ${item.bonusScudo}',
        page: 6,
        anchorId: 'inventory_root',
      );
    }

    for (final entry in inferredDamageTypeLabels().entries) {
      addUserResult(
        title: entry.value,
        subtitle: t('Tipo danno rilevato', 'Detected damage type'),
        haystack: '${entry.key} ${entry.value} danni difesa colore elemento',
        page: _OculumHomePageState.settingsPageIndex,
        anchorId: 'settings_root',
      );
    }

    for (final element in [...oculumDefaultElementIds, ...customDamageTypes]) {
      addUserResult(
        title: elementDisplayName(element),
        subtitle: t('Elemento / Tipo danno', 'Element / Damage type'),
        haystack: '$element ${elementDisplayName(element)} colore danni difesa',
        page: _OculumHomePageState.settingsPageIndex,
        anchorId: 'settings_root',
      );
    }

    for (final token in masterInitiativeTokens) {
      addUserResult(
        title: '${token['name'] ?? t('Partecipante', 'Participant')}',
        subtitle: t('Iniziativa Master', 'Master Initiative'),
        haystack:
            '${token['type'] ?? ''} ${token['side'] ?? ''} ${token['status'] ?? ''} ${token['notes'] ?? ''} ${token['initiativeRoll'] ?? ''} ${token['initiativeBase'] ?? ''} ${token['initiativeTotal'] ?? ''}',
        page: 9,
        anchorId: 'master_root',
      );
    }

    addUserResult(
      title: t('Storia della scheda', 'Sheet story'),
      subtitle: t('Background e note', 'Background and notes'),
      haystack:
          '${backgroundController.text} ${notePersonaggioController.text} ${diarioPagine.join(' ')} ${masterSessionController.text}',
      page: 5,
      anchorId: 'story_root',
    );

    results.sort(
      (a, b) => readIntValue(b['score']).compareTo(readIntValue(a['score'])),
    );
    return results;
  }

  void mostraCerca() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            final results = searchResults(controller.text);

            return AlertDialog(
              backgroundColor: const Color(0xFF10121A),
              title: Text(
                t('Cerca funzioni', 'Search functions'),
                style: TextStyle(
                  color: tertiaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 420,
                child: Column(
                  children: [
                    TextField(
                      controller: controller,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: fieldDecoration(
                        t('Scrivi cosa cerchi...', 'Type what you search...'),
                      ),
                      onChanged: (_) => setLocalState(() {}),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: results.isEmpty
                          ? Center(
                              child: Text(
                                t('Nessun risultato.', 'No results.'),
                              ),
                            )
                          : ListView.builder(
                              itemCount: results.length,
                              itemBuilder: (context, index) {
                                final r = results[index];

                                return Material(
                                  color: Colors.transparent,
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.search,
                                      color: tertiaryColor,
                                    ),
                                    title: Text(
                                      '${r['title']}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${r['subtitle']}',
                                      style: TextStyle(
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                    onTap: () {
                                      Navigator.pop(context);
                                      FocusManager.instance.primaryFocus
                                          ?.unfocus();

                                      if (r['action'] == 'dungeon') {
                                        _openDungeonMiniGame();
                                        return;
                                      }

                                      vaiAllaFunzione(
                                        page: readIntValue(r['page']),
                                        anchorId: '${r['anchorId'] ?? ''}',
                                        manualIndex: r['manualIndex'] == null
                                            ? null
                                            : readIntValue(r['manualIndex']),
                                        logTitle: '${r['title']}',
                                        focusField: false,
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(t('Chiudi', 'Close')),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(controller.dispose);
  }

  // =====================================================
  // IMPOSTAZIONI
  // =====================================================

  Widget sheetCodeSettingsPanel() {
    final hasSheets = schedePersonaggio.isNotEmpty;

    return gothicPanel(
      borderColor: tertiaryColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.ios_share, color: tertiaryColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  t('Codici Scheda', 'Sheet Codes'),
                  style: TextStyle(
                    color: tertiaryColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          smallInfoText(
            t(
              'Copia una scheda o piu schede in un codice unico. Puoi mandarlo fuori dall app in chat, al party o agli amici: chi lo incolla qui lo salva come nuova scheda.',
              'Copy one or more sheets into a single code. You can send it outside the app in chat, to the party or friends: whoever pastes it here saves it as a new sheet.',
            ),
          ),
          const SizedBox(height: 14),
          if (hasSheets) ...[
            Text(
              t('Schede da includere', 'Sheets to include'),
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (int i = 0; i < schedePersonaggio.length; i++)
                  FilterChip(
                    selected: selectedSheetCodeIndexes.contains(i),
                    selectedColor: tertiaryColor.withValues(alpha: 0.25),
                    backgroundColor: Colors.black.withValues(alpha: 0.28),
                    checkmarkColor: tertiaryColor,
                    side: BorderSide(
                      color: selectedSheetCodeIndexes.contains(i)
                          ? tertiaryColor
                          : primaryColor.withValues(alpha: 0.35),
                    ),
                    label: Text(
                      '${i + 1}. ${nomeSchedaPersonaggio(i)}',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selectedSheetCodeIndexes.contains(i)
                            ? tertiaryColor
                            : Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onSelected: (value) {
                      setState(() {
                        if (value) {
                          selectedSheetCodeIndexes.add(i);
                        } else {
                          selectedSheetCodeIndexes.remove(i);
                        }
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: copiaCodiceSchedaCorrente,
                  icon: const Icon(Icons.content_copy),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tertiaryColor,
                    foregroundColor: Colors.black,
                  ),
                  label: Text(t('Copia aperta', 'Copy current')),
                ),
                ElevatedButton.icon(
                  onPressed: selectedSheetCodeIndexes.isEmpty
                      ? null
                      : copiaCodiceSchedeSelezionate,
                  icon: const Icon(Icons.copy_all),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.black,
                  ),
                  label: Text(t('Copia selezionate', 'Copy selected')),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      selectedSheetCodeIndexes
                        ..clear()
                        ..addAll(
                          List<int>.generate(
                            schedePersonaggio.length,
                            (index) => index,
                          ),
                        );
                    });
                  },
                  icon: const Icon(Icons.select_all),
                  label: Text(t('Tutte', 'All')),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(selectedSheetCodeIndexes.clear);
                  },
                  icon: const Icon(Icons.backspace_outlined),
                  label: Text(t('Pulisci', 'Clear')),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: sheetCodeController,
            minLines: 4,
            maxLines: 8,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              labelText: t(
                'Incolla qui uno o piu codici scheda',
                'Paste one or more sheet codes here',
              ),
              labelStyle: TextStyle(color: primaryColor),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.28),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: primaryColor.withValues(alpha: 0.35),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: tertiaryColor),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: incollaCodiceSchedeDagliAppunti,
                icon: const Icon(Icons.paste),
                style: ElevatedButton.styleFrom(
                  backgroundColor: secondaryColor,
                  foregroundColor: Colors.white,
                  side: BorderSide(color: tertiaryColor),
                ),
                label: Text(t('Incolla appunti', 'Paste clipboard')),
              ),
              ElevatedButton.icon(
                onPressed: importaCodiceSchedeIncollato,
                icon: const Icon(Icons.save_alt),
                style: ElevatedButton.styleFrom(
                  backgroundColor: tertiaryColor,
                  foregroundColor: Colors.black,
                ),
                label: Text(t('Importa codice', 'Import code')),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  setState(sheetCodeController.clear);
                },
                icon: const Icon(Icons.close),
                label: Text(t('Svuota riquadro', 'Empty box')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget elementColorsSettingsPanel() {
    return gothicPanel(
      borderColor: elementColor('oculum'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t(
              'Colori Elementi / Tipi di Danno',
              'Element / Damage Type Colors',
            ),
            style: TextStyle(
              color: elementColor('oculum'),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          smallInfoText(
            t(
              'Il colore del danno usa l’elemento dominante. Puoi personalizzare i colori principali; se un tipo nuovo non ha colore dedicato userà il colore extra dell’occhio senza alterare lo sprite.',
              'Damage color uses the dominant element. You can customize main colors; if a new type has no dedicated color it uses the extra eye color without altering the sprite.',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: campoTesto(
                  label: t('Nuovo tipo di danno', 'New damage type'),
                  controller: customDamageTypeController,
                  numero: false,
                  helper: t(
                    'Esempi: Ruggine, Etere, Memoria, Fato spezzato. Verrà usato nei menu danno e nei colori.',
                    'Examples: Rust, Aether, Memory, Broken Fate. It will be used in damage menus and colors.',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: addCustomDamageTypeFromSettings,
                icon: const Icon(Icons.add),
                style: ElevatedButton.styleFrom(
                  backgroundColor: tertiaryColor,
                  foregroundColor: tertiaryColor.computeLuminance() > 0.45
                      ? Colors.black
                      : Colors.white,
                ),
                label: Text(t('Aggiungi', 'Add')),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final element in oculumDefaultElementIds)
                InputChip(
                  backgroundColor: elementColor(
                    element,
                  ).withValues(alpha: 0.18),
                  side: BorderSide(
                    color: elementColor(element).withValues(alpha: 0.65),
                  ),
                  label: Text(
                    elementDisplayName(element),
                    style: TextStyle(
                      color: elementColor(element),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () => setElementColor(element, tertiaryColor),
                  onDeleted: () => resetElementColor(element),
                  deleteIcon: Icon(
                    Icons.restore,
                    color: primaryColor,
                    size: 16,
                  ),
                ),
            ],
          ),
          if (customDamageTypes.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              t('Tipi personalizzati', 'Custom types'),
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final element in customDamageTypes)
                  InputChip(
                    backgroundColor: elementColor(
                      element,
                    ).withValues(alpha: 0.18),
                    side: BorderSide(
                      color: elementColor(element).withValues(alpha: 0.65),
                    ),
                    label: Text(
                      elementDisplayName(element),
                      style: TextStyle(
                        color: elementColor(element),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () => setElementColor(element, tertiaryColor),
                    onDeleted: () => removeCustomDamageType(element),
                    deleteIcon: const Icon(
                      Icons.delete,
                      color: Colors.redAccent,
                      size: 16,
                    ),
                  ),
              ],
            ),
          ],
          Builder(
            builder: (context) {
              final inferred = inferredDamageTypeLabels().entries
                  .where(
                    (entry) =>
                        !oculumDefaultElementIds.contains(entry.key) &&
                        !customDamageTypes.any(
                          (custom) =>
                              oculumNormalizeElementId(custom) == entry.key,
                        ),
                  )
                  .toList();
              if (inferred.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 14),
                  Text(
                    t('Rilevati nei testi', 'Detected in texts'),
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  smallInfoText(
                    t(
                      'Questi tipi esistono finché sono scritti in Titoli, Art, Skill o oggetti. Tocca per assegnare il colore terziario; reset per togliere solo il colore.',
                      'These types exist while they are written in Titles, Arts, Skills or items. Tap to assign the tertiary color; reset removes only the color.',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final entry in inferred)
                        InputChip(
                          backgroundColor: elementColor(
                            entry.key,
                          ).withValues(alpha: 0.18),
                          side: BorderSide(
                            color: elementColor(
                              entry.key,
                            ).withValues(alpha: 0.65),
                          ),
                          label: Text(
                            entry.value,
                            style: TextStyle(
                              color: elementColor(entry.key),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () =>
                              setElementColor(entry.key, tertiaryColor),
                          onDeleted: () => resetElementColor(entry.key),
                          deleteIcon: Icon(
                            Icons.restore,
                            color: primaryColor,
                            size: 16,
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          smallInfoText(
            t(
              'Tocca un elemento per assegnargli il colore terziario attuale; usa l’icona di reset per tornare al default. Il colore Oculum delle formule segue il colore qui sotto.',
              'Tap an element to assign the current tertiary color; use reset to restore default. Formula Oculum color follows the color below.',
            ),
            color: primaryColor,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: resetAllElementColors,
            icon: const Icon(Icons.restore),
            style: ElevatedButton.styleFrom(
              backgroundColor: secondaryColor,
              foregroundColor: Colors.white,
            ),
            label: Text(
              t('Reset tutti i colori elemento', 'Reset all element colors'),
            ),
          ),
        ],
      ),
    );
  }

  Widget settingsColorSwatch(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.68)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white24),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String settingsCompactDate(DateTime? value) {
    if (value == null) return t('Mai', 'Never');
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute';
  }

  String settingsEnabledLabel(bool value) {
    return value ? t('Attivo', 'On') : t('Spento', 'Off');
  }

  Color settingsEnabledColor(bool value) {
    return value ? tertiaryColor : Colors.grey.shade500;
  }

  Widget settingsStatusCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    String? detail,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 178, maxWidth: 268),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.24),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.55)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.55)),
              ),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: primaryColor.withValues(alpha: 0.92),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (detail != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      detail,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade300,
                        fontSize: 11.5,
                        height: 1.2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget settingsSectionBanner({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return gothicPanel(
      borderColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.55)),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                smallInfoText(subtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void resetSheetLayoutSettings() {
    setState(() {
      _expandedFunctionSections.clear();
      mostraDannoCuraScheda = true;
      mostraStrumentiManualeRapidi = true;
      mostraBorsaCompatta = true;
      mostraPartyScheda = true;
      mostraTastiRapidiIndice = true;
      mostraValoriEditabiliScheda = true;
      desktopSideMenuOpen = false;
      risultato = t(
        'Layout della scheda ripristinato.',
        'Sheet layout restored.',
      );
      aggiungiLog(risultato);
    });
    programmaSalvataggio();
  }

  Widget settingsHeroPanel() {
    final selectedPreset = colorPresetById(colorPresetSelezionato);
    final themeName = selectedPreset == null
        ? t('Personalizzato', 'Custom')
        : colorPresetName(selectedPreset);
    final saveColor = salvataggioBloccatoPerErrore
        ? Colors.redAccent
        : tertiaryColor;
    final compactSaveDate = settingsCompactDate(ultimoSalvataggioCompletatoAt);

    return gothicPanel(
      borderColor: tertiaryColor,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(lightweightUi ? 9 : 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                backgroundTopColor.withValues(alpha: 0.62),
                secondaryColor.withValues(alpha: 0.52),
                backgroundBottomColor.withValues(alpha: 0.82),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: eyePupilGlowColor.withValues(alpha: 0.72),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: eyePupilGlowColor.withValues(alpha: 0.18),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Icon(Icons.tune, color: tertiaryColor, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t('Impostazioni Oculum', 'Oculum Settings'),
                          style: TextStyle(
                            color: tertiaryColor,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        smallInfoText(
                          t(
                            'Stato rapido, controlli principali e personalizzazione della scheda in un unico posto.',
                            'Quick status, main controls and sheet customization in one place.',
                          ),
                          color: Colors.grey.shade200,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  settingsStatusCard(
                    icon: Icons.save,
                    title: t('Ultimo salvataggio', 'Last save'),
                    value: compactSaveDate,
                    color: saveColor,
                    detail: t(
                      'Rev. $salvataggioRevisione / errori $salvataggioFallimentiConsecutivi',
                      'Rev. $salvataggioRevisione / errors $salvataggioFallimentiConsecutivi',
                    ),
                  ),
                  settingsStatusCard(
                    icon: Icons.palette,
                    title: t('Tema colore', 'Color theme'),
                    value: themeName,
                    color: tertiaryColor,
                    detail: selectedPreset == null
                        ? t('Palette manuale', 'Manual palette')
                        : colorPresetDescription(selectedPreset),
                  ),
                  settingsStatusCard(
                    icon: Icons.phone_iphone,
                    title: t('Modalita veloce', 'Fast mode'),
                    value: settingsEnabledLabel(modalitaVeloce),
                    color: settingsEnabledColor(modalitaVeloce),
                    detail: t('Vista scheda compatta', 'Compact sheet view'),
                  ),
                  settingsStatusCard(
                    icon: Icons.desktop_windows,
                    title: t('Interfaccia', 'Interface'),
                    value: modalitaDesktop
                        ? t('Desktop', 'Desktop')
                        : t('Mobile', 'Mobile'),
                    color: modalitaDesktop ? tertiaryColor : primaryColor,
                    detail: linguaInglese ? 'English' : 'Italiano',
                  ),
                  settingsStatusCard(
                    icon: Icons.admin_panel_settings,
                    title: t('Master', 'Master'),
                    value: settingsEnabledLabel(modalitaMaster),
                    color: settingsEnabledColor(modalitaMaster),
                    detail: masterPublicDiceVisible
                        ? t('Dadi pubblici', 'Public dice')
                        : t('Dadi privati', 'Private dice'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.32),
                  ),
                  gradient: LinearGradient(
                    colors: [
                      backgroundTopColor,
                      backgroundMidColor,
                      backgroundBottomColor,
                    ],
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      settingsColorSwatch(
                        t('Primario', 'Primary'),
                        primaryColor,
                      ),
                      const SizedBox(width: 8),
                      settingsColorSwatch(
                        t('Secondario', 'Secondary'),
                        secondaryColor,
                      ),
                      const SizedBox(width: 8),
                      settingsColorSwatch(
                        t('Terziario', 'Tertiary'),
                        tertiaryColor,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      await salvaDati();
                      if (mounted) setState(() {});
                    },
                    icon: const Icon(Icons.save),
                    label: Text(t('Salva ora', 'Save now')),
                  ),
                  OutlinedButton.icon(
                    onPressed: esportaBackupNegliAppunti,
                    icon: const Icon(Icons.download),
                    label: Text(t('Backup', 'Backup')),
                  ),
                  const SizedBox(width: 8),
                  const OculumAuthPanel(),
                  OutlinedButton.icon(
                    onPressed: resetSheetLayoutSettings,
                    icon: const Icon(Icons.dashboard_customize),
                    label: Text(t('Reset layout', 'Reset layout')),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => applicaColorPreset('classic_reliquary'),
                    icon: const Icon(Icons.restore),
                    label: Text(t('Tema default', 'Default theme')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget settingsControlCenterPanel() {
    final lastSave = ultimoSalvataggioCompletatoAt == null
        ? t('Mai in questa sessione', 'Never in this session')
        : ultimoSalvataggioCompletatoAt!.toLocal().toString();

    ExpansionTile tile({
      required IconData icon,
      required String title,
      required List<Widget> children,
      bool expanded = false,
    }) {
      return ExpansionTile(
        initiallyExpanded: expanded,
        maintainState: true,
        tilePadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        backgroundColor: Colors.black.withValues(alpha: 0.16),
        collapsedBackgroundColor: Colors.black.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: tertiaryColor.withValues(alpha: 0.30)),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: primaryColor.withValues(alpha: 0.16)),
        ),
        leading: Icon(icon, color: tertiaryColor),
        iconColor: tertiaryColor,
        collapsedIconColor: primaryColor,
        title: Text(
          title,
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.w900),
        ),
        children: children,
      );
    }

    return gothicPanel(
      borderColor: tertiaryColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune, color: tertiaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t('Pannello di controllo', 'Control panel'),
                  style: TextStyle(
                    color: tertiaryColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          smallInfoText(
            t(
              'Sezioni compatte per tema, salvataggi, parser @, Osservato e forme Skill. I controlli completi restano sotto.',
              'Compact sections for theme, saves, @ parser, Observation and Skill forms. Full controls remain below.',
            ),
          ),
          const SizedBox(height: 10),
          tile(
            icon: Icons.save,
            title: t(
              'Salvataggi / Backup / Autosave',
              'Saves / Backup / Autosave',
            ),
            expanded: true,
            children: [
              smallInfoText(
                t(
                  'Ultimo salvataggio: $lastSave. Revisione: $salvataggioRevisione. Fallimenti consecutivi: $salvataggioFallimentiConsecutivi.',
                  'Last save: $lastSave. Revision: $salvataggioRevisione. Consecutive failures: $salvataggioFallimentiConsecutivi.',
                ),
                color: salvataggioBloccatoPerErrore
                    ? Colors.redAccent
                    : tertiaryColor,
              ),
              if (ultimoErroreCaricamentoSalvataggio.isNotEmpty) ...[
                const SizedBox(height: 6),
                smallInfoText(
                  ultimoErroreCaricamentoSalvataggio,
                  color: Colors.redAccent,
                ),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      await salvaDati();
                      if (mounted) setState(() {});
                    },
                    icon: const Icon(Icons.save),
                    label: Text(t('Salva ora', 'Save now')),
                  ),
                  OutlinedButton.icon(
                    onPressed: esportaBackupNegliAppunti,
                    icon: const Icon(Icons.download),
                    label: Text(t('Esporta backup', 'Export backup')),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          tile(
            icon: Icons.palette,
            title: t(
              'Aspetto / Tema e colori',
              'Appearance / Theme and colors',
            ),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  settingsColorSwatch(t('Primario', 'Primary'), primaryColor),
                  settingsColorSwatch(
                    t('Secondario', 'Secondary'),
                    secondaryColor,
                  ),
                  settingsColorSwatch(
                    t('Terziario', 'Tertiary'),
                    tertiaryColor,
                  ),
                  settingsColorSwatch(
                    t('Utility / dettagli', 'Utility / details'),
                    eyeUtilityColor,
                  ),
                  settingsColorSwatch(
                    t('Formule Oculum', 'Oculum formulas'),
                    oculumStatFormulaColor,
                  ),
                  settingsColorSwatch(
                    t('Sfondo alto', 'Background top'),
                    backgroundTopColor,
                  ),
                  settingsColorSwatch(
                    t('Sfondo medio', 'Background middle'),
                    backgroundMidColor,
                  ),
                  settingsColorSwatch(
                    t('Sfondo basso', 'Background bottom'),
                    backgroundBottomColor,
                  ),
                  settingsColorSwatch(
                    t('Glow occhio', 'Eye glow'),
                    eyePupilGlowColor,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => applicaColorPreset('classic_reliquary'),
                icon: const Icon(Icons.restore),
                label: Text(
                  t('Ripristina tema predefinito', 'Restore default theme'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          tile(
            icon: Icons.alternate_email,
            title: t('Parser e comandi @', '@ parser and commands'),
            children: [
              smallInfoText(
                '@Ocu+1 ogni 50 HPSpesi\n@Stats+1\n@HP-10=Stats+1\n@Danni+Vol/2 Fuoco\n@Difesa+15 Cenere',
                color: primaryColor,
              ),
            ],
          ),
          const SizedBox(height: 8),
          tile(
            icon: Icons.remove_red_eye,
            title: t(
              'Osservato / Punti extra livello',
              'Observation / Extra level points',
            ),
            children: [
              smallInfoText(
                t(
                  'Se una scheda e Osservata, ottiene 1 punto statistica extra per ogni livello totale, anche per i livelli raggiunti prima di essere osservata. I punti non si duplicano e restano salvati.',
                  'If a sheet is Observed, it gains 1 extra stat point for each total level, including levels reached before being observed. Points do not duplicate and remain saved.',
                ),
                color: tertiaryColor,
              ),
            ],
          ),
          const SizedBox(height: 8),
          tile(
            icon: Icons.account_tree,
            title: t(
              'Skill normali / Forme skill',
              'Normal Skills / Skill forms',
            ),
            children: [
              smallInfoText(
                t(
                  'Le Skill normali possono avere da 1 a 5 forme. Le Skill vecchie vengono trattate come Forma 1 senza perdere dati.',
                  'Normal Skills can have 1 to 5 forms. Old Skills are treated as Form 1 without losing data.',
                ),
                color: tertiaryColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget settingsPage() {
    return responsivePageList(
      pageKey: 'settings',
      maxColumns: 2,
      minColumnWidth: 340,
      fullWidthIndexes: const <int>{0, 2, 3, 4, 5, 6, 7, 17},
      children: [
        functionAnchor(
          'settings_root',
          sectionTitle(t('Impostazioni', 'Settings')),
        ),
        gothicPanel(borderColor: tertiaryColor, child: pageDropdown()),
        functionAnchor('settings_hero', settingsHeroPanel()),
        functionAnchor('settings_control_center', settingsControlCenterPanel()),
        functionAnchor('settings_theme_showcase', settingsThemeShowcasePanel()),
        functionAnchor('settings_gui_skins', settingsGuiSkinGalleryPanel()),
        functionAnchor(
          'settings_skin_customization',
          themeCustomizationSlidersPanel(),
        ),
        functionAnchor(
          'settings_decorations_gallery',
          settingsDecorationsGalleryPanel(),
        ),
        functionAnchor(
          'settings_management_layout',
          settingsSectionBanner(
            icon: Icons.dashboard_customize,
            title: t('Gestione e layout', 'Management and layout'),
            subtitle: t(
              'Codici scheda, sicurezza visiva, modalita, lingua e tutorial.',
              'Sheet codes, visual safeguards, modes, language and tutorial.',
            ),
            color: primaryColor,
          ),
        ),
        functionAnchor('settings_sheet_codes', sheetCodeSettingsPanel()),
        functionAnchor(
          'settings_oculum_shield',
          gothicPanel(
            borderColor: eyePupilGlowColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('Scudo Oculum', 'Oculum Shield'),
                  style: TextStyle(
                    color: eyePupilGlowColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                smallInfoText(
                  t(
                    'Controlla se la sezione dello Scudo Oculum resta visibile anche quando non hai buff o valore.',
                    'Controls whether the Oculum Shield section stays visible even without a buff or value.',
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: mostraSempreScudoOculum,
                  activeThumbColor: eyePupilGlowColor,
                  title: Text(
                    t('Mostra anche senza buff', 'Show even without buff'),
                  ),
                  subtitle: Text(
                    t(
                      'Se spento compare solo quando hai Scudo Oculum o @ScudoOculum attivo.',
                      'When off, it appears only when you have Oculum Shield or active @ScudoOculum.',
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      mostraSempreScudoOculum = value;
                      risultato = value
                          ? t(
                              'Scudo Oculum sempre visibile.',
                              'Oculum Shield always visible.',
                            )
                          : t(
                              'Scudo Oculum visibile solo quando presente.',
                              'Oculum Shield visible only when present.',
                            );
                      aggiungiLog(risultato);
                    });
                    programmaSalvataggio();
                  },
                ),
              ],
            ),
          ),
        ),

        gothicPanel(
          borderColor: primaryColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t('Layout Scheda', 'Sheet Layout'),
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              smallInfoText(
                t(
                  'Ripristina tendine, pannelli rapidi e menu laterale senza toccare personaggio, titoli, skill o inventario.',
                  'Restore dropdowns, quick panels and side menu without touching character, titles, skills or inventory.',
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: resetSheetLayoutSettings,
                icon: const Icon(Icons.dashboard_customize),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: primaryColor.computeLuminance() > 0.45
                      ? Colors.black
                      : Colors.white,
                ),
                label: Text(t('Reset layout scheda', 'Reset sheet layout')),
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
                t('Interfaccia Telefono', 'Phone Interface'),
                style: TextStyle(
                  color: tertiaryColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              smallInfoText(
                t(
                  'Attiva o nascondi sezioni ripetute. Le funzioni restano disponibili dai menù a tendina.',
                  'Enable or hide repeated sections. Features remain available from dropdown menus.',
                ),
              ),
              SwitchListTile(
                value: modalitaVeloce,
                activeThumbColor: tertiaryColor,
                title: Text(t('Modalità veloce', 'Fast mode')),
                subtitle: Text(
                  t(
                    'Mostra prima azioni essenziali e nasconde dettagli duplicati nella Scheda.',
                    'Shows essential actions first and hides duplicated details on the Sheet.',
                  ),
                ),
                onChanged: (value) {
                  setState(() => modalitaVeloce = value);
                  programmaSalvataggio();
                },
              ),
              SwitchListTile(
                value: modalitaLeggera,
                activeThumbColor: tertiaryColor,
                title: Text(t('Modalita leggera', 'Lightweight mode')),
                subtitle: Text(
                  t(
                    'Riduce ombre, glow e spaziature pesanti senza nascondere funzioni.',
                    'Reduces heavy shadows, glow and spacing without hiding features.',
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    modalitaLeggera = value;
                    risultato = value
                        ? t(
                            'Modalita leggera attiva.',
                            'Lightweight mode enabled.',
                          )
                        : t(
                            'Modalita leggera spenta.',
                            'Lightweight mode disabled.',
                          );
                    aggiungiLog(risultato);
                  });
                  programmaSalvataggio();
                },
              ),
              SwitchListTile(
                value: modalitaMaster,
                activeThumbColor: tertiaryColor,
                title: Text(t('Modalita Master', 'Master Mode')),
                subtitle: Text(
                  t(
                    'Abilita permessi e strumenti Master locali. La sezione Sessione Master compare nella pagina Storia.',
                    'Enables local Master permissions and tools. The Master Session section appears on the Story page.',
                  ),
                ),
                onChanged: oculumStartupRole == OculumStartupRole.player
                    ? null
                    : (value) {
                        setState(() {
                          modalitaMaster = value;
                          risultato = value
                              ? t(
                                  'Modalita Master attiva.',
                                  'Master Mode enabled.',
                                )
                              : t(
                                  'Modalita Master spenta.',
                                  'Master Mode disabled.',
                                );
                          aggiungiLog(risultato);
                        });
                        programmaSalvataggio();
                      },
              ),
              SwitchListTile(
                value: usaBarraVita,
                activeThumbColor: tertiaryColor,
                title: Text(t('Vita come barra', 'HP as bar')),
                onChanged: (value) {
                  setState(() => usaBarraVita = value);
                  programmaSalvataggio();
                },
              ),
              SwitchListTile(
                value: mostraDannoCuraScheda,
                activeThumbColor: tertiaryColor,
                title: Text(t('Mostra Danno / Cura', 'Show Damage / Healing')),
                onChanged: (value) {
                  setState(() => mostraDannoCuraScheda = value);
                  programmaSalvataggio();
                },
              ),
              SwitchListTile(
                value: mostraValoriEditabiliScheda,
                activeThumbColor: tertiaryColor,
                title: Text(
                  t('Valori principali a tendina', 'Main values dropdown'),
                ),
                onChanged: (value) {
                  setState(() => mostraValoriEditabiliScheda = value);
                  programmaSalvataggio();
                },
              ),
              SwitchListTile(
                value: scalaExpAutomatica,
                activeThumbColor: tertiaryColor,
                title: Text(
                  t('EXP scala automaticamente', 'EXP scales automatically'),
                ),
                subtitle: Text(
                  t(
                    'Quando aggiungi EXP, ogni 1000 viene sottratto e trasformato in livello. Spegnilo per tenere EXP grezza.',
                    'When you add EXP, each 1000 is subtracted and converted into a level. Turn it off to keep raw EXP.',
                  ),
                ),
                onChanged: (value) {
                  setState(() => scalaExpAutomatica = value);
                  programmaSalvataggio();
                },
              ),
              SwitchListTile(
                value: coMasterCanSetCoMaster,
                activeThumbColor: tertiaryColor,
                title: Text(
                  t(
                    'I Co-Master possono nominare altri Co-Master',
                    'Co-Masters can appoint other Co-Masters',
                  ),
                ),
                subtitle: Text(
                  t(
                    'Se abilitato, i Co-Master possono promuovere altri giocatori a Co-Master dalla pagina Online.',
                    'If enabled, Co-Masters can promote other players to Co-Master from the Online page.',
                  ),
                ),
                onChanged: (value) {
                  setState(() => coMasterCanSetCoMaster = value);
                  programmaSalvataggio();
                },
              ),
              SwitchListTile(
                value: masterKickRequiresConfirmation,
                activeThumbColor: tertiaryColor,
                title: Text(
                  t('Conferma prima di kickare', 'Confirm before kicking'),
                ),
                subtitle: Text(
                  t(
                    'Se disattivato, Kicka rimuove subito la scheda o il giocatore dalla campagna/sessione.',
                    'If disabled, Kick removes the sheet or player from the campaign/session immediately.',
                  ),
                ),
                onChanged: (value) {
                  setState(() => masterKickRequiresConfirmation = value);
                  programmaSalvataggio();
                },
              ),
              SwitchListTile(
                value: masterEnemyFullSheetVisibility,
                activeThumbColor: tertiaryColor,
                title: Text(
                  t(
                    'Mostra dettagli schede nemiche',
                    'Show enemy sheet details',
                  ),
                ),
                subtitle: Text(
                  t(
                    'Spento: agli altri arrivano solo immagine, lato token e iniziativa delle schede nemiche del Master.',
                    'Off: others receive only image, token side and initiative for the Master enemy sheets.',
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    masterEnemyFullSheetVisibility = value;
                    risultato = value
                        ? t(
                            'Dettagli nemici visibili nelle condivisioni Master.',
                            'Enemy details visible in Master shares.',
                          )
                        : t(
                            'Schede nemiche limitate a immagine e iniziativa.',
                            'Enemy sheets limited to image and initiative.',
                          );
                    aggiungiLog(risultato);
                  });
                  if (realtimeIsMasterRole) {
                    sendRealtimeMasterVisiblePartyTokens();
                  } else {
                    sendRealtimeCurrentSheetToStaff();
                  }
                  programmaSalvataggio();
                },
              ),
              SwitchListTile(
                value: masterPublicDiceVisible,
                activeThumbColor: tertiaryColor,
                title: Text(
                  t(
                    'Dadi Master visibili a tutti',
                    'Master dice visible to everyone',
                  ),
                ),
                subtitle: Text(
                  t(
                    'Se attivo, i tiri non-iniziativa del Master possono essere mandati in realtime dopo conferma.',
                    'When active, non-initiative Master rolls can be sent realtime after confirmation.',
                  ),
                ),
                onChanged: (value) async {
                  if (!value) {
                    setState(() {
                      masterPublicDiceVisible = false;
                      risultato = t(
                        'Dadi Master nascosti agli altri.',
                        'Master dice hidden from others.',
                      );
                      aggiungiLog(risultato);
                    });
                    programmaSalvataggio();
                    return;
                  }

                  final choice = await showDialog<String>(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) {
                      return AlertDialog(
                        backgroundColor: const Color(0xFF10121A),
                        title: Text(
                          t(
                            'Dadi visibili a tutti?',
                            'Dice visible to everyone?',
                          ),
                          style: TextStyle(
                            color: tertiaryColor,
                            fontWeight: FontWeight.bold,
                          ),
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
                            child: Text(
                              t('Non chiedere piu', 'Do not ask again'),
                            ),
                          ),
                        ],
                      );
                    },
                  );

                  if (!context.mounted) return;
                  setState(() {
                    masterPublicDiceVisible =
                        choice == 'yes' || choice == 'never';
                    masterAskPublicDiceConfirmation = choice != 'never';
                    risultato = masterPublicDiceVisible
                        ? t(
                            'Dadi Master pubblici abilitati.',
                            'Public Master dice enabled.',
                          )
                        : t(
                            'Dadi Master rimasti nascosti.',
                            'Master dice stayed hidden.',
                          );
                    aggiungiLog(risultato);
                  });
                  programmaSalvataggio();
                },
              ),
              SwitchListTile(
                value: masterAskPublicDiceConfirmation,
                activeThumbColor: tertiaryColor,
                title: Text(
                  t('Chiedi prima del tiro pubblico', 'Ask before public roll'),
                ),
                subtitle: Text(
                  t(
                    'Riattiva la domanda prima che un tiro Master non-iniziativa sia visibile a tutti.',
                    'Turns the prompt back on before a non-initiative Master roll becomes visible to everyone.',
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    masterAskPublicDiceConfirmation = value;
                    risultato = value
                        ? t(
                            'Domanda dadi pubblici riattivata.',
                            'Public dice prompt restored.',
                          )
                        : t(
                            'Domanda dadi pubblici disattivata.',
                            'Public dice prompt disabled.',
                          );
                    aggiungiLog(risultato);
                  });
                  programmaSalvataggio();
                },
              ),
              SwitchListTile(
                value: sottraiStatsDaExpAggiunta,
                activeThumbColor: tertiaryColor,
                title: Text(
                  t(
                    'Sottrai stats dall’EXP aggiunta',
                    'Subtract stats from added EXP',
                  ),
                ),
                subtitle: Text(
                  t(
                    'Quando aggiungi EXP, Resilienza + Volontà + Materia + Oculum totali vengono sottratti dall’EXP realmente aggiunta.',
                    'When adding EXP, total Resilience + Will + Matter + Oculum are subtracted from the EXP actually added.',
                  ),
                ),
                onChanged: (value) {
                  setState(() => sottraiStatsDaExpAggiunta = value);
                  programmaSalvataggio();
                },
              ),
              SwitchListTile(
                value: mostraStrumentiManualeRapidi,
                activeThumbColor: tertiaryColor,
                title: Text(
                  t('Strumenti rapidi manuale', 'Manual quick tools'),
                ),
                onChanged: (value) {
                  setState(() => mostraStrumentiManualeRapidi = value);
                  programmaSalvataggio();
                },
              ),
              SwitchListTile(
                value: mostraBorsaCompatta,
                activeThumbColor: tertiaryColor,
                title: Text(t('Borsa rapida a tendina', 'Quick bag dropdown')),
                onChanged: (value) {
                  setState(() => mostraBorsaCompatta = value);
                  programmaSalvataggio();
                },
              ),
              SwitchListTile(
                value: mostraPartyScheda,
                activeThumbColor: tertiaryColor,
                title: Text(t('Sezione Party', 'Party section')),
                onChanged: (value) {
                  setState(() => mostraPartyScheda = value);
                  programmaSalvataggio();
                },
              ),
              SwitchListTile(
                value: mostraTastiRapidiIndice,
                activeThumbColor: tertiaryColor,
                title: Text(t('Tasti rapidi a indice', 'Quick index buttons')),
                onChanged: (value) {
                  setState(() => mostraTastiRapidiIndice = value);
                  programmaSalvataggio();
                },
              ),
            ],
          ),
        ),
        blockedOculumFriendsSettingsPanel(),
        gothicPanel(
          borderColor: modalitaDesktop ? tertiaryColor : primaryColor,
          child: SwitchListTile(
            value: modalitaDesktop,
            activeThumbColor: tertiaryColor,
            title: Text(
              t('Modalità Desktop', 'Desktop Mode'),
              style: TextStyle(
                color: modalitaDesktop ? tertiaryColor : primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              modalitaDesktop
                  ? t(
                      'Attiva: uso menu alto e nascondo la barra mobile in basso.',
                      'Enabled: using top menu and hiding the mobile bottom bar.',
                    )
                  : t(
                      'Disattiva: uso la barra mobile in basso.',
                      'Disabled: using the mobile bottom bar.',
                    ),
            ),
            onChanged: (value) {
              setState(() {
                modalitaDesktop = value;
                risultato = modalitaDesktop
                    ? t('Modalità Desktop attivata.', 'Desktop Mode enabled.')
                    : t('Modalità Mobile attivata.', 'Mobile Mode enabled.');

                aggiungiLog(risultato);
              });

              programmaSalvataggio();
            },
          ),
        ),
        gothicPanel(
          borderColor: primaryColor,
          child: SwitchListTile(
            value: linguaInglese,
            activeThumbColor: tertiaryColor,
            title: Text(
              t('Lingua', 'Language'),
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              linguaInglese
                  ? 'English enabled. Turn off to return to Italian.'
                  : 'Attiva per cambiare le scritte principali in inglese.',
            ),
            onChanged: (value) {
              setState(() {
                linguaInglese = value;
                risultato = linguaInglese
                    ? 'Choose a stat and roll the die.'
                    : 'Scegli una statistica e tira il dado.';
                aggiungiLog('Lingua cambiata: ${linguaInglese ? "EN" : "IT"}.');
              });
              programmaSalvataggio();
            },
          ),
        ),
        gothicPanel(
          borderColor: tertiaryColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t('Tutorial', 'Tutorial'),
                style: TextStyle(
                  color: tertiaryColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              smallInfoText(
                t(
                  'Puoi riaprire il tutorial iniziale quando vuoi. Il setup ora parte da livello 0.',
                  'You can reopen the starting tutorial whenever you want. The setup now starts from level 0.',
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: mostraTutorial,
                icon: const Icon(Icons.school),
                style: ElevatedButton.styleFrom(
                  backgroundColor: tertiaryColor,
                  foregroundColor: tertiaryColor.computeLuminance() > 0.45
                      ? Colors.black
                      : Colors.white,
                  minimumSize: const Size.fromHeight(46),
                ),
                label: Text(t('Apri Tutorial', 'Open Tutorial')),
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
                t('Scheda Colori', 'Color Sheet'),
                style: TextStyle(
                  color: tertiaryColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              smallInfoText(
                t(
                  'Ogni colore può essere scelto dalla palette oppure modificato con RGB, luminosità, saturazione e opacità. I primi tre colori restano quelli dell’occhio: il colore extra non cambia il disegno dell’occhio e serve come fallback per tipi danno nuovi o rilevati nei testi.',
                  'Each color can be chosen from the palette or edited with RGB, lightness, saturation and opacity. The first three colors remain the eye colors: the extra color does not change the eye artwork and is used as fallback for new or detected damage types.',
                ),
              ),
            ],
          ),
        ),
        colorPresetDropdownPanel(),
        elementColorsSettingsPanel(),
        colorPicker(
          titolo: t(
            'Colore Extra Occhio / Tipi Danno Nuovi',
            'Extra Eye Color / New Damage Types',
          ),
          selectedColor: eyeUtilityColor,
          filtro: filtroExtraOcchio,
          onFiltroChanged: (value) => filtroExtraOcchio = value,
          onSelected: (color) => eyeUtilityColor = color,
          editorAperto: mostraEditorExtraOcchio,
          onToggleEditor: () {
            setState(() {
              mostraEditorExtraOcchio = !mostraEditorExtraOcchio;
            });
          },
        ),
        if (mostraEditorExtraOcchio)
          advancedColorPanel(
            target: t('Extra occhio', 'Extra eye'),
            currentColor: eyeUtilityColor,
            onSelected: (color) => eyeUtilityColor = color,
          ),
        colorPicker(
          titolo: t(
            'Bagliore Pupilla / Centro Occhio',
            'Pupil Glow / Eye Center',
          ),
          selectedColor: eyePupilGlowColor,
          filtro: filtroAmbiente,
          onFiltroChanged: (value) => filtroAmbiente = value,
          onSelected: (color) => eyePupilGlowColor = color,
          editorAperto: mostraEditorPupilla,
          onToggleEditor: () {
            setState(() {
              mostraEditorPupilla = !mostraEditorPupilla;
            });
          },
        ),
        if (mostraEditorPupilla)
          advancedColorPanel(
            target: t('Bagliore pupilla', 'Pupil glow'),
            currentColor: eyePupilGlowColor,
            onSelected: (color) => eyePupilGlowColor = color,
          ),
        colorPicker(
          titolo: t('Sfondo Alto', 'Background Top'),
          selectedColor: backgroundTopColor,
          filtro: filtroAmbiente,
          onFiltroChanged: (value) => filtroAmbiente = value,
          onSelected: (color) => backgroundTopColor = color,
          editorAperto: mostraEditorSfondoAlto,
          onToggleEditor: () {
            setState(() {
              mostraEditorSfondoAlto = !mostraEditorSfondoAlto;
            });
          },
        ),
        if (mostraEditorSfondoAlto)
          advancedColorPanel(
            target: t('Sfondo alto', 'Background top'),
            currentColor: backgroundTopColor,
            onSelected: (color) => backgroundTopColor = color,
          ),
        colorPicker(
          titolo: t('Sfondo Centro', 'Background Center'),
          selectedColor: backgroundMidColor,
          filtro: filtroAmbiente,
          onFiltroChanged: (value) => filtroAmbiente = value,
          onSelected: (color) => backgroundMidColor = color,
          editorAperto: mostraEditorSfondoMedio,
          onToggleEditor: () {
            setState(() {
              mostraEditorSfondoMedio = !mostraEditorSfondoMedio;
            });
          },
        ),
        if (mostraEditorSfondoMedio)
          advancedColorPanel(
            target: t('Sfondo centro', 'Background center'),
            currentColor: backgroundMidColor,
            onSelected: (color) => backgroundMidColor = color,
          ),
        colorPicker(
          titolo: t('Sfondo Basso', 'Background Bottom'),
          selectedColor: backgroundBottomColor,
          filtro: filtroAmbiente,
          onFiltroChanged: (value) => filtroAmbiente = value,
          onSelected: (color) => backgroundBottomColor = color,
          editorAperto: mostraEditorSfondoBasso,
          onToggleEditor: () {
            setState(() {
              mostraEditorSfondoBasso = !mostraEditorSfondoBasso;
            });
          },
        ),
        if (mostraEditorSfondoBasso)
          advancedColorPanel(
            target: t('Sfondo basso', 'Background bottom'),
            currentColor: backgroundBottomColor,
            onSelected: (color) => backgroundBottomColor = color,
          ),
        colorPicker(
          titolo: t(
            'Colore Primario / Testi Magici',
            'Primary Color / Magical Text',
          ),
          selectedColor: primaryColor,
          filtro: filtroPrimario,
          onFiltroChanged: (value) => filtroPrimario = value,
          onSelected: (color) => primaryColor = color,
          editorAperto: mostraEditorPrimario,
          onToggleEditor: () {
            setState(() {
              mostraEditorPrimario = !mostraEditorPrimario;
            });
          },
        ),
        if (mostraEditorPrimario)
          advancedColorPanel(
            target: t('Primario', 'Primary'),
            currentColor: primaryColor,
            onSelected: (color) => primaryColor = color,
          ),
        colorPicker(
          titolo: t(
            'Colore Secondario / Fondi / Dadi',
            'Secondary Color / Backgrounds / Dice',
          ),
          selectedColor: secondaryColor,
          filtro: filtroSecondario,
          onFiltroChanged: (value) => filtroSecondario = value,
          onSelected: (color) => secondaryColor = color,
          editorAperto: mostraEditorSecondario,
          onToggleEditor: () {
            setState(() {
              mostraEditorSecondario = !mostraEditorSecondario;
            });
          },
        ),
        if (mostraEditorSecondario)
          advancedColorPanel(
            target: t('Secondario', 'Secondary'),
            currentColor: secondaryColor,
            onSelected: (color) => secondaryColor = color,
          ),
        colorPicker(
          titolo: t(
            'Colore Terziario / Open / Critici / Rituali',
            'Tertiary Color / Opens / Criticals / Rituals',
          ),
          selectedColor: tertiaryColor,
          filtro: filtroTerziario,
          onFiltroChanged: (value) => filtroTerziario = value,
          onSelected: (color) => tertiaryColor = color,
          editorAperto: mostraEditorTerziario,
          onToggleEditor: () {
            setState(() {
              mostraEditorTerziario = !mostraEditorTerziario;
            });
          },
        ),
        if (mostraEditorTerziario)
          advancedColorPanel(
            target: t('Terziario', 'Tertiary'),
            currentColor: tertiaryColor,
            onSelected: (color) => tertiaryColor = color,
          ),
        sectionTitle(t('Import / Export', 'Import / Export')),
        gothicPanel(
          borderColor: tertiaryColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t('Backup Schede', 'Sheet Backup'),
                style: TextStyle(
                  color: tertiaryColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              smallInfoText(
                t(
                  'Esporta copia tutte le schede negli appunti in formato JSON. Importa permette di incollare quel JSON e ripristinare il salvataggio.',
                  'Export copies all sheets to the clipboard as JSON. Import lets you paste that JSON and restore the save.',
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: esportaBackupNegliAppunti,
                icon: const Icon(Icons.download),
                style: ElevatedButton.styleFrom(
                  backgroundColor: tertiaryColor,
                  foregroundColor: tertiaryColor.computeLuminance() > 0.45
                      ? Colors.black
                      : Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
                label: Text(t('Esporta Backup', 'Export Backup')),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: mostraDialogImportBackup,
                icon: const Icon(Icons.upload_file),
                style: ElevatedButton.styleFrom(
                  backgroundColor: secondaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
                label: Text(t('Importa Backup', 'Import Backup')),
              ),
            ],
          ),
        ),
        sectionTitle(t('Log Eventi', 'Event Log')),
        gothicPanel(
          borderColor: primaryColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ElevatedButton.icon(
                onPressed: pulisciLog,
                icon: const Icon(Icons.cleaning_services),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent.shade700,
                  foregroundColor: Colors.white,
                ),
                label: Text(t('Pulisci Log', 'Clear Log')),
              ),
              const SizedBox(height: 12),
              if (logEventi.isEmpty)
                Text(t('Nessun evento registrato.', 'No events recorded.'))
              else
                for (final voce in logEventi.take(120))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      voce,
                      style: TextStyle(
                        color: Colors.grey.shade200,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
            ],
          ),
        ),
        sectionTitle(t('Anteprima Colori', 'Color Preview')),
        gothicPanel(
          borderColor: primaryColor,
          child: Column(
            children: [
              Text(
                'OCULUM',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 18),
              D20Widget(
                text: '20+8=28',
                fillColor: secondaryColor,
                textColor: primaryColor,
                glow: true,
                tertiaryColor: tertiaryColor,
              ),
            ],
          ),
        ),
        gothicPanel(
          borderColor: Colors.redAccent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t('Archivio salvataggio', 'Save Archive'),
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                t(
                  'Non cancella nulla: archivia la campagna attuale e apre una nuova scheda vuota.',
                  'Nothing is deleted: it archives the current campaign and opens a new empty sheet.',
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: cancellaSalvataggio,
                icon: const Icon(Icons.archive),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent.shade700,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
                label: Text(t('Archivia e riparti', 'Archive and restart')),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =====================================================
}
