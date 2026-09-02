part of '../../main.dart';

Map<String, dynamic> oculusDefaultCharacterData() => <String, dynamic>{
  'name': '',
  'appearance': '',
  'forbiddenSight': '',
  'race': '',
  'title': '',
  'art': '',
  'wound': '',
  'desire': '',
  'protectedPerson': '',
  'activeMission': '',
  'resilienzaDie': 4,
  'volontaDie': 4,
  'materiaDie': 4,
  'oculumDie': 4,
  'forceDie': 4,
  'activeForce': 'fato',
  'enemyVolontaDie': 4,
  'enemyMateriaDie': 4,
  'enemyForceDie': 4,
  'resilienzaMastery': 0,
  'volontaMastery': 0,
  'materiaMastery': 0,
  'oculumMastery': 0,
  'level': 0,
  'progress': 0,
  'life': 4,
  'maxLife': 4,
  'defense': 5,
  'bonusPoints': 0,
  'racialTraits': '',
  'skills': <String>['', '', ''],
  'missions': List<String>.filled(12, ''),
  'madness': 0,
  'corruption': 0,
  'notes': '',
  'helpEnabled': true,
};

const Map<String, List<(String, String)>>
oculusArtSkillCatalog = <String, List<(String, String)>>{
  'Fuoco': <(String, String)>[
    ('Filo di Brace', '3 danni a un bersaglio vicino.'),
    (
      'Fiamma Errante',
      'Muovi una fiamma tra tre zone; illumina e rivela il nascosto.',
    ),
    ('Marchio di Cenere', "Nessun danno: il bersaglio e' Esposto."),
    ('Cuore di Fornace', 'Assorbi Brucia da un alleato e recuperi 1 Vita.'),
    ('Pugnale Solare', '2 danni; se eri Velato, +2 al tiro.'),
    (
      'Coro delle Scintille',
      'Tre alleati ottengono +1 al prossimo tiro offensivo.',
    ),
  ],
  'Acqua': <(String, String)>[
    ('Ago di Marea', "2 danni e Legato se il bersaglio e' vicino a liquidi."),
    (
      'Velo di Pioggia',
      'Crea Velato per te o un alleato fino al prossimo turno.',
    ),
    ('Memoria Sommersa', "Leggi l'ultima emozione forte impressa in un luogo."),
    ('Morsa di Sale', "3 danni contro una creatura gia' Fratturata."),
    (
      'Passo di Goccia',
      'Attraversa una linea di pericolo senza provocare reazioni.',
    ),
    ('Pozzo Inverso', 'Sposta una creatura piccola in una zona adiacente.'),
  ],
  'Terra': <(String, String)>[
    ('Chiodo di Basalto', '2 danni e Legato.'),
    ('Muro di Argilla', 'Crea copertura per due persone fino a fine scena.'),
    ("Polvere d'Osso", 'Rivela impronte, sangue o passaggi invisibili.'),
    ('Pugno di Faglia', '3 danni, ma resti fermo fino al prossimo turno.'),
    (
      'Tomba Gentile',
      "Un alleato a 0 Vita non muore finche' la scena non cambia.",
    ),
    ('Radice del Giuramento', 'Un bersaglio Esposto diventa Fratturato.'),
  ],
  'Aria': <(String, String)>[
    ('Lama di Pressione', '2 danni a distanza.'),
    ('Soffio di Sgomento', 'Spingi un nemico in una zona adiacente.'),
    ('Voce Tra le Crepe', 'Invia una frase breve a un alleato che conosci.'),
    (
      'Cerchio di Vento',
      'Devia il prossimo attacco a distanza contro un alleato.',
    ),
    ('Polline di Nebbia', 'Rendi Velata una piccola area.'),
    (
      'Caduta Senza Fine',
      'Un nemico Legato subisce 3 danni e perde la reazione.',
    ),
  ],
  'Luce': <(String, String)>[
    ("Sigillo d'Aurora", 'Un alleato recupera 2 Vita.'),
    ('Lancia di Specchio', '2 danni; ignora Velato.'),
    (
      'Giudizio Cieco',
      "Un nemico Esposto non puo' nascondersi fino a fine scena.",
    ),
    (
      'Lanterna del Nome',
      'Chiedi il vero nome o la debolezza simbolica di una creatura.',
    ),
    ('Pelle di Alba', 'Rimuovi Fratturato o Brucia da un alleato.'),
    (
      'Fenditura Bianca',
      "3 danni a un'ombra, un'illusione o una creatura corrotta.",
    ),
  ],
  'Ombra': <(String, String)>[
    ('Ago di Notte', "2 danni; se il bersaglio e' solo, +1 danno."),
    ('Porta Nera', 'Scambia posizione con un alleato visibile.'),
    ('Sussurro Parassita', "Un bersaglio riceve -2 alla prossima Volonta'."),
    (
      'Mantello Senza Volto',
      'Diventi Velato e non lasci tracce per una scena.',
    ),
    ("Morsa dell'Assente", 'Un nemico Velato diventa Esposto.'),
    (
      'Sonno della Statua',
      'Un bersaglio Fratturato non usa reazioni fino al suo turno.',
    ),
  ],
};

Map<String, dynamic> oculusNormalizeCharacterData(Object? raw) {
  final result = oculusDefaultCharacterData();
  if (raw is Map) result.addAll(Map<String, dynamic>.from(raw));
  final rawSkills = result['skills'] is List
      ? List<dynamic>.from(result['skills'] as List)
      : <dynamic>[];
  final rawMissions = result['missions'] is List
      ? List<dynamic>.from(result['missions'] as List)
      : <dynamic>[];
  result['skills'] = <String>[
    ...rawSkills.map((value) => '$value'),
    '',
    '',
    '',
  ].take(3).toList(growable: true);
  result['missions'] = <String>[
    ...rawMissions.map((value) => '$value'),
    ...List<String>.filled(12, ''),
  ].take(12).toList(growable: true);
  // Oculus ha dodici soli livelli. Le vecchie schede restano leggibili, ma
  // non possono più oltrepassare il tetto della mod.
  result['level'] = readIntValue(result['level']).clamp(0, 12).toInt();
  result['progress'] = readIntValue(result['progress']).clamp(0, 2).toInt();
  return result;
}

extension _OculumGameModUi on _OculumHomePageState {
  bool get oculusModActive => activeGameMod == 'oculus';
  bool get manuscriptLivingActive => activeGameMod == 'manuscript_living';
  // I valori legacy rimangono leggibili nei salvataggi, ma non fanno più
  // parte della schermata Oculus essenziale.
  bool get oculusShowLegacyControls => false;

  void setActiveGameMod(String id) {
    final normalized = id.trim().toLowerCase();
    if (activeGameMod == normalized) return;
    updateOculumHomeUi(() {
      activeGameMod = normalized;
      paginaCorrente = normalized == 'oculus' ? 0 : paginaCorrente;
      if (normalized == 'oculus') {
        // Oculus è una modalità esclusiva: le mod grafiche/roulette restano
        // configurate ma vengono spente, senza modificare dati di gioco.
        temiOldSchool = false;
        slotMachineRollsEnabled = false;
        oculusModData = oculusNormalizeCharacterData(oculusModData);
      }
    });
    gameModRevision.value++;
    programmaSalvataggio(invalidateCaches: false);
  }

  bool sheetUsesOculusMod(Map<String, dynamic> sheet) =>
      '${sheet['activeGameMod'] ?? ''}'.trim().toLowerCase() == 'oculus';

  Future<void> openOrCreateOculusSheet() async {
    salvaSchedaCorrenteInMemoria();
    final existingIndex = schedePersonaggio.indexWhere(sheetUsesOculusMod);
    if (existingIndex >= 0) {
      await cambiaSchedaPersonaggio(existingIndex);
      return;
    }

    await creaNuovaSchedaPersonaggio(
      nome: t('Scheda Oculus', 'Oculus Sheet'),
      tipo: 'Personaggio',
    );
    setActiveGameMod('oculus');
    salvaSchedaCorrenteInMemoria();
    await salvaDati();
  }

  Future<void> openFirstOculumSheet() async {
    salvaSchedaCorrenteInMemoria();
    final normalIndex = schedePersonaggio.indexWhere(
      (sheet) => !sheetUsesOculusMod(sheet),
    );
    if (normalIndex >= 0) {
      await cambiaSchedaPersonaggio(normalIndex);
      return;
    }

    await creaNuovaSchedaPersonaggio(
      nome: t('Nuova scheda', 'New sheet'),
      tipo: 'Personaggio',
    );
  }

  String oculusText(String key) => '${oculusModData[key] ?? ''}';

  int oculusInt(String key, {int fallback = 0}) =>
      readIntValue(oculusModData[key], fallback: fallback);

  void setOculusData(String key, Object value, {bool rebuild = false}) {
    oculusModData[key] = value;
    if (rebuild) gameModRevision.value++;
    programmaSalvataggio(
      invalidateCaches: false,
      delay: const Duration(milliseconds: 900),
    );
  }

  Widget oculusTextField(
    String key,
    String label, {
    int minLines = 1,
    int maxLines = 1,
    String helper = '',
  }) {
    return TextFormField(
      key: ValueKey<String>('oculus_$key'),
      initialValue: oculusText(key),
      minLines: minLines,
      maxLines: maxLines,
      onChanged: (value) => setOculusData(key, value),
      decoration: InputDecoration(
        labelText: label,
        helperText:
            helper.isEmpty || !readBoolValue(oculusModData['helpEnabled'])
            ? null
            : helper,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget oculusNumberField(
    String key,
    String label, {
    int minimum = 0,
    int? maximum,
  }) {
    return TextFormField(
      key: ValueKey<String>('oculus_number_$key'),
      initialValue: '${oculusInt(key)}',
      keyboardType: const TextInputType.numberWithOptions(signed: true),
      onChanged: (value) {
        final parsed = max(minimum, int.tryParse(value.trim()) ?? minimum);
        setOculusData(key, maximum == null ? parsed : min(maximum, parsed));
      },
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget oculusDieSelector(String key, String label) {
    const dice = <int>[4, 6, 8, 10, 12, 20];
    final current = oculusInt(key, fallback: 4);
    return DropdownButtonFormField<int>(
      key: ValueKey<String>('oculus_die_${key}_$current'),
      initialValue: dice.contains(current) ? current : 4,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: [
        for (final faces in dice)
          DropdownMenuItem<int>(value: faces, child: Text('d$faces')),
      ],
      onChanged: (value) {
        if (value != null) setOculusData(key, value, rebuild: true);
      },
    );
  }

  void rollOculusStat(String key, String label) {
    final random = Random.secure();
    final statFaces = max(2, oculusInt('${key}Die', fallback: 4));
    final forceFaces = max(2, oculusInt('forceDie', fallback: 4));
    final statRoll = random.nextInt(statFaces) + 1;
    final forceRoll = random.nextInt(forceFaces) + 1;
    final mastery = oculusInt('${key}Mastery').clamp(0, 3).toInt();
    final total = statRoll + forceRoll + mastery;
    final force = oculusText('activeForce').toUpperCase();
    risultato =
        '$label $statRoll + $force $forceRoll + '
        '${t('Maestria', 'Mastery')} $mastery = $total.';
    dadoMostrato = '$total';
    showOculusDice(<Map<String, dynamic>>[
      <String, dynamic>{
        'label': label,
        'faces': statFaces,
        'value': statRoll,
        'bonus': mastery,
      },
      <String, dynamic>{
        'label': oculusText('activeForce').toUpperCase(),
        'faces': forceFaces,
        'value': forceRoll,
      },
    ]);
    aggiungiLog(risultato);
    notifyDiceResultChanged();
  }

  void showOculusDice(List<Map<String, dynamic>> dice) {
    oculusDiceRevealTimer?.cancel();
    oculusLastDice
      ..clear()
      ..addAll(dice);
    oculusDiceAnimationSeed++;
    oculusDiceResultsVisible = false;
    gameModRevision.value++;
    oculusDiceRevealTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      oculusDiceResultsVisible = true;
      gameModRevision.value++;
    });
  }

  Widget oculusDiceTray() {
    if (oculusLastDice.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            for (var i = 0; i < oculusLastDice.length; i++)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    key: ValueKey<String>(
                      'oculus_die_${oculusDiceAnimationSeed}_$i',
                    ),
                    tween: Tween<double>(begin: -.16, end: 0),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    builder: (context, turns, child) =>
                        Transform.rotate(angle: turns * pi * 2, child: child),
                    child: D20Widget(
                      text: oculusDiceResultsVisible
                          ? '${oculusLastDice[i]['value']}'
                          : '',
                      fillColor: secondaryColor,
                      textColor: primaryColor,
                      glow:
                          readIntValue(oculusLastDice[i]['value']) ==
                          readIntValue(oculusLastDice[i]['faces']),
                      tertiaryColor: tertiaryColor,
                      faces: readIntValue(
                        oculusLastDice[i]['faces'],
                        fallback: 4,
                      ),
                      size: 88,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'd${oculusLastDice[i]['faces']} - ${oculusLastDice[i]['label']}'
                    '${readIntValue(oculusLastDice[i]['bonus']) == 0 ? '' : ' +${oculusLastDice[i]['bonus']}'}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  void buyOculusMastery(String key) {
    final masteryKey = '${key}Mastery';
    final current = oculusInt(masteryKey).clamp(0, 3).toInt();
    if (current >= 3) return;
    final cost = (current + 1) * 3;
    final available = oculusInt('bonusPoints');
    if (available < cost) {
      risultato = t(
        'Servono $cost Punti Bonus per Maestria +${current + 1}.',
        '$cost Bonus Points are required for Mastery +${current + 1}.',
      );
      notifyDiceResultChanged();
      return;
    }
    oculusModData[masteryKey] = current + 1;
    oculusModData['bonusPoints'] = available - cost;
    gameModRevision.value++;
    programmaSalvataggio(invalidateCaches: false);
  }

  Widget oculusMasteryControl(String key, String label) {
    final value = oculusInt('${key}Mastery').clamp(0, 3).toInt();
    final nextCost = value >= 3 ? 0 : (value + 1) * 3;
    return SizedBox(
      width: 160,
      child: OutlinedButton.icon(
        onPressed: value >= 3 ? null : () => buyOculusMastery(key),
        icon: const Icon(Icons.add),
        label: Text(
          '$label +$value${nextCost > 0 ? ' ($nextCost PT)' : ''}',
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  // I dati e l'editor legacy restano qui per leggere le vecchie schede; la
  // schermata Oculus essenziale non li espone più.
  // ignore: unused_element
  Future<void> showOculusArtPicker() async {
    var selectedArt = oculusArtSkillCatalog.containsKey(oculusText('art'))
        ? oculusText('art')
        : oculusArtSkillCatalog.keys.first;
    final selectedSkills = <String>{};
    final currentSkills = (oculusModData['skills'] as List<String>)
        .map((entry) => entry.split('\n').first.trim())
        .where((entry) => entry.isNotEmpty)
        .toSet();
    selectedSkills.addAll(
      oculusArtSkillCatalog[selectedArt]!
          .where((entry) => currentSkills.contains(entry.$1))
          .map((entry) => entry.$1)
          .take(3),
    );
    final choice = await showDialog<(String, List<String>)>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final choices = oculusArtSkillCatalog[selectedArt]!;
          return AlertDialog(
            title: Text(
              t(
                'Scegli una Art e tre Skill',
                'Choose one Art and three Skills',
              ),
            ),
            content: SizedBox(
              width: 680,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        for (final art in oculusArtSkillCatalog.keys)
                          ChoiceChip(
                            selected: selectedArt == art,
                            label: Text(art),
                            onSelected: (_) => setDialogState(() {
                              selectedArt = art;
                              selectedSkills.clear();
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    for (final skill in choices)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: selectedSkills.contains(skill.$1),
                        title: Text(
                          skill.$1,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        subtitle: Text(skill.$2),
                        onChanged: (selected) => setDialogState(() {
                          if (selected == true) {
                            if (selectedSkills.length < 3) {
                              selectedSkills.add(skill.$1);
                            }
                          } else {
                            selectedSkills.remove(skill.$1);
                          }
                        }),
                      ),
                    Text(
                      '${t('Scelte', 'Selected')}: ${selectedSkills.length}/3',
                      style: TextStyle(
                        color: selectedSkills.length == 3
                            ? Colors.greenAccent
                            : tertiaryColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(t('Annulla', 'Cancel')),
              ),
              FilledButton(
                onPressed: selectedSkills.length != 3
                    ? null
                    : () {
                        final byName = <String, (String, String)>{
                          for (final skill in choices) skill.$1: skill,
                        };
                        Navigator.pop(context, (
                          selectedArt,
                          <String>[
                            for (final name in selectedSkills)
                              '${byName[name]!.$1}\n${byName[name]!.$2}',
                          ],
                        ));
                      },
                child: Text(t('Conferma tre Skill', 'Confirm three Skills')),
              ),
            ],
          );
        },
      ),
    );
    if (choice == null) return;
    oculusModData['art'] = choice.$1;
    oculusModData['skills'] = choice.$2;
    gameModRevision.value++;
    programmaSalvataggio(invalidateCaches: false);
  }

  // ignore: unused_element
  Future<void> saveOculusManualPdf() async {
    const assetPath = 'assets/manuals/oculus_manuale_libero_gotico_horror.pdf';
    const fileName = 'Oculus_Manuale_Libero_Gotico_Horror.pdf';
    try {
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      if (kIsWeb) {
        await oculumDownloadBytes(
          bytes: bytes,
          fileName: fileName,
          mimeType: 'application/pdf',
        );
        risultato = t(
          'Download del manuale Oculus avviato.',
          'Oculus manual download started.',
        );
      } else {
        Directory directory;
        try {
          directory = await getApplicationDocumentsDirectory();
        } catch (_) {
          directory = Directory.current;
        }
        final file = File(
          '${directory.path}${Platform.pathSeparator}$fileName',
        );
        await file.writeAsBytes(bytes, flush: true);
        risultato = t(
          'Manuale Oculus salvato: ${file.path}',
          'Oculus manual saved: ${file.path}',
        );
      }
      aggiungiLog(risultato);
      notifyDiceResultChanged();
    } catch (error) {
      risultato = t(
        'Impossibile salvare il manuale Oculus: $error',
        'Could not save the Oculus manual: $error',
      );
      notifyDiceResultChanged();
    }
  }

  Widget oculusSection(String title, List<Widget> children) {
    return gothicPanel(
      borderColor: tertiaryColor.withValues(alpha: .72),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: tertiaryColor,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget oculusModPage() {
    return ValueListenableBuilder<int>(
      valueListenable: gameModRevision,
      builder: (context, revision, child) {
        final help = readBoolValue(
          oculusModData['helpEnabled'],
          fallback: true,
        );
        return responsivePageList(
          pageKey: 'mod_oculus_sheet',
          maxColumns: 2,
          minColumnWidth: 360,
          masonryColumns: true,
          fullWidthIndexes: const <int>{0, 3},
          children: [
            gothicPanel(
              borderColor: primaryColor,
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.visibility, color: primaryColor, size: 34),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'OCULUS',
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 4,
                                fontSize: 26,
                              ),
                            ),
                            Text(
                              t(
                                'Scheda libera gotico horror - nessuna formula nascosta',
                                'Free gothic horror sheet - no hidden formulas',
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: t('Colori e stile', 'Colors and style'),
                        onPressed: () => vaiAllaFunzione(
                          page: _OculumHomePageState.settingsPageIndex,
                          anchorId: 'settings_root',
                          logTitle: t('Colori e stile', 'Colors and style'),
                        ),
                        icon: const Icon(Icons.palette_outlined),
                      ),
                    ],
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: help,
                    title: Text(t('Aiuti contestuali', 'Context help')),
                    subtitle: Text(
                      t(
                        'Mostra suggerimenti brevi mentre compili il personaggio.',
                        'Show short hints while filling in the character.',
                      ),
                    ),
                    onChanged: (value) =>
                        setOculusData('helpEnabled', value, rebuild: true),
                  ),
                  oculusDiceTray(),
                ],
              ),
            ),
            oculusSection(t('Ferita e missione', 'Wound and mission'), [
              oculusTextField('wound', t('Ferita', 'Wound')),
              const SizedBox(height: 8),
              oculusTextField(
                'activeMission',
                t('Missione attiva', 'Active mission'),
                maxLines: 3,
              ),
            ]),
            if (oculusShowLegacyControls)
              oculusSection(t('Dadi e valori', 'Dice and values'), [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    SizedBox(
                      width: 155,
                      child: oculusDieSelector('resilienzaDie', 'Resilienza'),
                    ),
                    SizedBox(
                      width: 155,
                      child: oculusDieSelector(
                        'volontaDie',
                        t('Volonta', 'Will'),
                      ),
                    ),
                    SizedBox(
                      width: 155,
                      child: oculusDieSelector('materiaDie', 'Materia'),
                    ),
                    SizedBox(
                      width: 155,
                      child: oculusDieSelector('oculumDie', 'Oculum'),
                    ),
                    SizedBox(
                      width: 155,
                      child: oculusDieSelector(
                        'forceDie',
                        t('Forza attiva', 'Active Force'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  key: ValueKey<String>(
                    'oculus_force_${oculusText('activeForce')}',
                  ),
                  initialValue:
                      const <String>{
                        'fato',
                        'chaos',
                        'oblio',
                      }.contains(oculusText('activeForce'))
                      ? oculusText('activeForce')
                      : 'fato',
                  decoration: InputDecoration(
                    labelText: t('Forza della scena', 'Scene Force'),
                    border: const OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'fato', child: Text('Fato')),
                    DropdownMenuItem(value: 'chaos', child: Text('Chaos')),
                    DropdownMenuItem(value: 'oblio', child: Text('Oblio')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setOculusData('activeForce', value, rebuild: true);
                    }
                  },
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    SizedBox(
                      width: 120,
                      child: oculusNumberField(
                        'level',
                        t('Livello /12', 'Level /12'),
                        maximum: 12,
                      ),
                    ),
                    SizedBox(
                      width: 120,
                      child: oculusNumberField(
                        'progress',
                        t('Progresso /3', 'Progress /3'),
                        maximum: 2,
                      ),
                    ),
                    SizedBox(
                      width: 120,
                      child: oculusNumberField('life', t('Vita', 'Life')),
                    ),
                    SizedBox(
                      width: 120,
                      child: oculusNumberField(
                        'maxLife',
                        t('Vita MAX', 'Max life'),
                        minimum: 1,
                      ),
                    ),
                    SizedBox(
                      width: 120,
                      child: oculusNumberField(
                        'defense',
                        t('Difesa', 'Defense'),
                      ),
                    ),
                    SizedBox(
                      width: 140,
                      child: oculusNumberField(
                        'bonusPoints',
                        t('Punti Bonus', 'Bonus points'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '${t('Maestria acquistabile', 'Purchasable Mastery')} - ${t('massimo +3 per Stat', 'maximum +3 per Stat')}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    oculusMasteryControl('resilienza', 'RES'),
                    oculusMasteryControl('volonta', 'VOL'),
                    oculusMasteryControl('materia', 'MAT'),
                    oculusMasteryControl('oculum', 'OCU'),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final entry in const <(String, String)>[
                      ('resilienza', 'Resilienza'),
                      ('volonta', 'Volonta'),
                      ('materia', 'Materia'),
                      ('oculum', 'Oculum'),
                    ])
                      FilledButton.tonalIcon(
                        onPressed: () => rollOculusStat(entry.$1, entry.$2),
                        icon: const Icon(Icons.casino_outlined),
                        label: Text('${t('Tira', 'Roll')} ${entry.$2}'),
                      ),
                  ],
                ),
                if (help) ...[
                  const SizedBox(height: 10),
                  smallInfoText(
                    t(
                      'Scala dadi: d4, d6, d8, d10, d12, d20. Vita iniziale: 3 + tiro reale di Resilienza. Difesa iniziale: 5.',
                      'Dice ladder: d4, d6, d8, d10, d12, d20. Starting life: 3 + a real Resilience roll. Starting defense: 5.',
                    ),
                  ),
                ],
              ]),
            oculusSection(t('Regole essenziali', 'Essential rules'), [
              SelectableText(
                t(
                  'LIVELLI: esistono solo 12 livelli, da 0 a 12. A 3 Progresso il Master assegna +1 livello; il contatore torna a 0 e al livello 12 non cresce più.\n'
                      'DADI STAT: quando sali di livello scegli una sola Stat tra RES, VOL, MAT e OCU e falla avanzare di un gradino: d4 → d6 → d8 → d10 → d12 → d20. Il Master conferma la scelta e aggiorni il selettore corrispondente.\n'
                      'POTERE / FORZA: il dado Forza è il Potere della scena. Sale sulla stessa scala solo come ricompensa esplicita del Master, normalmente dopo una Missione attiva conclusa; poi aggiorni “Forza attiva”.\n'
                      'MAESTRIA: spendi Punti Bonus per aggiungere da +1 a +3 a una Stat; i costi sono 3, poi 6, poi 9 Punti Bonus.\n'
                      'TIRO: dado Stat + dado Forza + eventuale Maestria. DT 5 / 7 / 9 / 11 / 14; vantaggio/svantaggio vale +3/-3 quando il Master lo stabilisce.\n'
                      'VITA: 3 + tiro Resilienza; quando RES cresce, la Vita MAX aumenta solo se il nuovo tiro è più alto. Critico = massimo naturale del dado Stat: +1 danno o un effetto coerente.',
                  'LEVELS: there are only 12 levels, from 0 to 12. At 3 Progress the Master grants +1 level; progress returns to 0 and level 12 cannot increase further.\n'
                      'STAT DICE: on a level up choose one Stat—RES, WILL, MAT or OCU—and move it one step: d4 → d6 → d8 → d10 → d12 → d20. The Master confirms the choice, then update that selector.\n'
                      'POWER / FORCE: the Force die is the scene Power. It rises on the same ladder only as an explicit Master reward, normally after the active Mission is completed; then update Active Force.\n'
                      'MASTERY: spend Bonus Points for +1 to +3 on a Stat; costs are 3, then 6, then 9 Bonus Points.\n'
                      'ROLL: Stat die + Force die + optional Mastery. DT 5 / 7 / 9 / 11 / 14; advantage/disadvantage is +3/-3 when the Master establishes it.\n'
                      'LIFE: 3 + a Resilience roll; when RES rises, max Life rises only if the new roll is higher. Critical = natural maximum on the Stat die: +1 damage or a coherent effect.',
                ),
              ),
            ]),
          ],
        );
      },
    );
  }

  Widget oculusModSettingsPanel() {
    return gothicPanel(
      borderColor: oculusModActive ? primaryColor : tertiaryColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.extension, color: primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t('Mod di gioco', 'Game mods'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
              if (oculusModActive) const Chip(label: Text('OCULUS')),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            t(
              'Oculus usa schede separate. Attivandola apri una scheda Oculus esistente oppure ne crei una nuova senza modificare quella attuale. Selezionare una scheda Oculum o Oculus cambia automaticamente interfaccia.',
              'Oculus uses separate sheets. Enabling it opens an existing Oculus sheet or creates a new one without changing the current sheet. Selecting an Oculum or Oculus sheet automatically changes the interface.',
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: oculusModActive ? null : openOrCreateOculusSheet,
                icon: const Icon(Icons.visibility),
                label: Text(t('Attiva mod Oculus', 'Enable Oculus mod')),
              ),
              OutlinedButton.icon(
                onPressed: oculusModActive ? openFirstOculumSheet : null,
                icon: const Icon(Icons.undo),
                label: Text(t('Torna a Oculum', 'Return to Oculum')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
