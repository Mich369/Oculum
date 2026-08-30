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
  return result;
}

extension _OculumGameModUi on _OculumHomePageState {
  bool get oculusModActive => activeGameMod == 'oculus';

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

  Widget oculusNumberField(String key, String label, {int minimum = 0}) {
    return TextFormField(
      key: ValueKey<String>('oculus_number_$key'),
      initialValue: '${oculusInt(key)}',
      keyboardType: const TextInputType.numberWithOptions(signed: true),
      onChanged: (value) => setOculusData(
        key,
        max(minimum, int.tryParse(value.trim()) ?? minimum),
      ),
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

  void rollOculusOpposed({required bool attack}) {
    final random = Random.secure();
    int roll(String key) {
      final faces = max(2, oculusInt(key, fallback: 4));
      return random.nextInt(faces) + 1;
    }

    final playerStatKey = attack ? 'volontaDie' : 'materiaDie';
    final enemyStatKey = attack ? 'enemyMateriaDie' : 'enemyVolontaDie';
    final playerStat = roll(playerStatKey);
    final playerForce = roll('forceDie');
    final masteryKey = attack ? 'volontaMastery' : 'materiaMastery';
    final playerBonus = oculusInt(masteryKey).clamp(0, 3).toInt();
    final enemyStat = roll(enemyStatKey);
    final enemyForce = roll('enemyForceDie');
    final playerTotal = playerStat + playerForce + playerBonus;
    final enemyTotal = enemyStat + enemyForce;
    final outcome = playerTotal > enemyTotal
        ? t('SUCCESSO', 'SUCCESS')
        : playerTotal < enemyTotal
        ? t('FALLIMENTO', 'FAILURE')
        : t('PAREGGIO', 'TIE');
    final label = attack ? t('Attacco', 'Attack') : t('Difesa', 'Defense');
    final playerStatLabel = attack ? t('Volonta', 'Will') : 'Materia';
    risultato =
        '$label - $outcome: '
        '$playerStatLabel $playerStat + Bonus $playerBonus + Forza $playerForce = $playerTotal. '
        '${t('Tiro nemico nascosto.', 'Enemy roll hidden.')}';
    dadoMostrato = '$playerTotal : ?';
    showOculusDice(<Map<String, dynamic>>[
      <String, dynamic>{
        'label': playerStatLabel,
        'faces': oculusInt(playerStatKey, fallback: 4),
        'value': playerStat,
        'bonus': playerBonus,
      },
      <String, dynamic>{
        'label': t('Forza', 'Force'),
        'faces': oculusInt('forceDie', fallback: 4),
        'value': playerForce,
      },
    ]);
    aggiungiLog(risultato);
    notifyDiceResultChanged();
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
        final skills = oculusModData['skills'] as List<String>;
        final missions = oculusModData['missions'] as List<String>;
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
            oculusSection(t('Identita e storia', 'Identity and story'), [
              oculusTextField(
                'name',
                t('Nome', 'Name'),
                helper: t(
                  'Come ti chiama il mondo?',
                  'What does the world call you?',
                ),
              ),
              const SizedBox(height: 8),
              oculusTextField('race', t('Razza', 'Race')),
              const SizedBox(height: 8),
              oculusTextField('title', t('Titolo', 'Title')),
              const SizedBox(height: 8),
              oculusTextField('art', 'Art'),
              const SizedBox(height: 8),
              oculusTextField(
                'appearance',
                t('Aspetto', 'Appearance'),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              oculusTextField(
                'forbiddenSight',
                t(
                  'Cosa il tuo occhio non sopporta vedere',
                  'What your eye cannot bear to see',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              oculusTextField('wound', t('Ferita', 'Wound')),
              const SizedBox(height: 8),
              oculusTextField('desire', t('Desiderio', 'Desire')),
              const SizedBox(height: 8),
              oculusTextField(
                'protectedPerson',
                t('Persona da proteggere', 'Person to protect'),
              ),
              const SizedBox(height: 8),
              oculusTextField(
                'activeMission',
                t('Missione attiva', 'Active mission'),
              ),
            ]),
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
                    child: oculusNumberField('level', t('Livello', 'Level')),
                  ),
                  SizedBox(
                    width: 120,
                    child: oculusNumberField(
                      'progress',
                      t('Progresso /3', 'Progress /3'),
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
                    child: oculusNumberField('defense', t('Difesa', 'Defense')),
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
            oculusSection(t('Contrasto rapido', 'Quick opposition'), [
              Text(
                t(
                  'Quattro dadi in contrasto: ai tuoi dadi Volonta o Materia si somma il relativo bonus Maestria.',
                  'Four opposed dice: the matching Mastery bonus is added to your Will or Materia die.',
                ),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: 170,
                    child: oculusDieSelector(
                      'enemyVolontaDie',
                      t('Volonta nemica', 'Enemy Will'),
                    ),
                  ),
                  SizedBox(
                    width: 170,
                    child: oculusDieSelector(
                      'enemyMateriaDie',
                      t('Materia nemica', 'Enemy Materia'),
                    ),
                  ),
                  SizedBox(
                    width: 170,
                    child: oculusDieSelector(
                      'enemyForceDie',
                      t('Forza nemica', 'Enemy Force'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    onPressed: () => rollOculusOpposed(attack: true),
                    icon: const Icon(Icons.gps_fixed),
                    label: Text(
                      t(
                        'Attacco: Volonta + bonus + Forza',
                        'Attack: Will + bonus + Force',
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => rollOculusOpposed(attack: false),
                    icon: const Icon(Icons.shield_outlined),
                    label: Text(
                      t(
                        'Difesa: Materia + bonus + Forza',
                        'Defense: Materia + bonus + Force',
                      ),
                    ),
                  ),
                ],
              ),
              if (risultato.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                SelectableText(risultato),
              ],
            ]),
            oculusSection(t('Tratti e Skill', 'Traits and Skills'), [
              FilledButton.icon(
                onPressed: showOculusArtPicker,
                icon: const Icon(Icons.auto_awesome),
                label: Text(
                  t('Scegli Art e 3 Skill', 'Choose Art and 3 Skills'),
                ),
              ),
              const SizedBox(height: 10),
              oculusTextField(
                'racialTraits',
                t('Tratti razziali', 'Racial traits'),
                minLines: 3,
                maxLines: 6,
              ),
              const SizedBox(height: 10),
              for (var i = 0; i < 3; i++) ...[
                TextFormField(
                  key: ValueKey<String>('oculus_skill_$i'),
                  initialValue: skills[i],
                  minLines: 2,
                  maxLines: 4,
                  onChanged: (value) {
                    skills[i] = value;
                    setOculusData('skills', skills);
                  },
                  decoration: InputDecoration(
                    labelText: '${t('Skill', 'Skill')} ${i + 1}',
                    helperText: help
                        ? t(
                            'Si sblocca soltanto tramite Quest del Master.',
                            'Unlocked only through a Master Quest.',
                          )
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ]),
            oculusSection(
              t('Dodici missioni del Titolo', 'Twelve Title missions'),
              [
                for (var i = 0; i < 12; i++) ...[
                  TextFormField(
                    key: ValueKey<String>('oculus_mission_$i'),
                    initialValue: missions[i],
                    onChanged: (value) {
                      missions[i] = value;
                      setOculusData('missions', missions);
                    },
                    decoration: InputDecoration(
                      labelText: '${i + 1}',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              ],
            ),
            oculusSection(t('Horror e note', 'Horror and notes'), [
              Row(
                children: [
                  Expanded(
                    child: oculusNumberField(
                      'madness',
                      t('Follia 0-6', 'Madness 0-6'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: oculusNumberField(
                      'corruption',
                      t('Corruzione 0-6', 'Corruption 0-6'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              oculusTextField(
                'notes',
                t('Note', 'Notes'),
                minLines: 5,
                maxLines: 12,
              ),
            ]),
            oculusSection(t('Regole essenziali', 'Essential rules'), [
              OutlinedButton.icon(
                onPressed: saveOculusManualPdf,
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: Text(
                  t('Salva il manuale completo', 'Save the full manual'),
                ),
              ),
              const SizedBox(height: 10),
              SelectableText(
                t(
                  'TIRO: dado Stat + dado Forza. DT 5 / 7 / 9 / 11 / 14.\n'
                      'VANTAGGIO / SVANTAGGIO: +3 / -3 quando la situazione lo giustifica.\n'
                      'VITA: 3 + tiro Resilienza; quando Resilienza cresce, la Vita MAX sale solo se il nuovo tiro e migliore.\n'
                      'CRITICO: massimo naturale del dado Stat, +1 danno oppure un effetto coerente.\n'
                      'DANNO: lieve 1, normale 2, pesante 3, Skill 2-4.\n'
                      'EFFETTI BASE: Brucia, Legato, Esposto, Velato, Fratturato; lo stesso effetto si rinnova e non si somma.\n'
                      'CRESCITA: 3 Progresso = +1 livello, massimo 12; ogni livello aumenta una Stat di un grado.\n'
                      'SKILL: solo tramite Missione/Quest del Master. Una Skill usa un solo effetto ricorrente.\n'
                      'SICUREZZA: concordate temi da evitare e un segnale semplice per fermare una scena.',
                  'ROLL: Stat die + Force die. DT 5 / 7 / 9 / 11 / 14.\n'
                      'ADVANTAGE / DISADVANTAGE: +3 / -3 when the situation warrants it.\n'
                      'LIFE: 3 + Resilience roll; when Resilience grows, max Life rises only if the new roll is better.\n'
                      'CRITICAL: natural maximum on the Stat die, +1 damage or a coherent effect.\n'
                      'DAMAGE: light 1, normal 2, heavy 3, Skill 2-4.\n'
                      'BASE EFFECTS: Burn, Bound, Exposed, Veiled, Fractured; the same effect refreshes and never stacks.\n'
                      'GROWTH: 3 Progress = +1 level, maximum 12; each level raises one Stat by one die step.\n'
                      'SKILLS: only through a Master Mission/Quest. A Skill uses one recurring effect.\n'
                      'SAFETY: agree on avoided themes and a simple signal to stop a scene.',
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
