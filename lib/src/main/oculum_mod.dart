part of '../../main.dart';

Map<String, dynamic> oculusDefaultCharacterData() => <String, dynamic>{
  'name': '',
  'player': '',
  'appearance': '',
  'forbiddenSight': '',
  'race': '',
  'raceSkill': '',
  'raceSkillCooldown': '',
  'title': '',
  'titleLevel': 0,
  'titleReward': '',
  'titleSkill': '',
  'titleOpenI': '',
  'titleOpenII': '',
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
  'shield': 0,
  'maxShield': 4,
  'oculumCurrent': 4,
  'maxOculum': 4,
  'defense': 5,
  'bonusPoints': 0,
  'inspirations': 3,
  'ascensionDust': 0,
  'absorbedDust': 0,
  'growthPoints': 0,
  'racialTraits': '',
  'skills': <String>['', '', ''],
  'artSkills': <Map<String, dynamic>>[
    <String, dynamic>{
      'name': '',
      'cost': '',
      'formI': '',
      'questI': '',
      'formII': '',
      'questII': '',
      'formIII': '',
      'questIII': '',
    },
    <String, dynamic>{
      'name': '',
      'cost': '',
      'formI': '',
      'questI': '',
      'formII': '',
      'questII': '',
      'formIII': '',
      'questIII': '',
    },
    <String, dynamic>{
      'name': '',
      'cost': '',
      'formI': '',
      'questI': '',
      'formII': '',
      'questII': '',
      'formIII': '',
      'questIII': '',
    },
  ],
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
  final rawArtSkills = result['artSkills'] is List
      ? List<dynamic>.from(result['artSkills'] as List)
      : <dynamic>[];
  final legacySkills = List<String>.from(result['skills'] as List<String>);
  result['artSkills'] = List<Map<String, dynamic>>.generate(3, (index) {
    final raw = index < rawArtSkills.length && rawArtSkills[index] is Map
        ? Map<String, dynamic>.from(rawArtSkills[index] as Map)
        : <String, dynamic>{};
    return <String, dynamic>{
      'name':
          '${raw['name'] ?? (index < legacySkills.length ? legacySkills[index].split('\n').first : '')}',
      'cost': '${raw['cost'] ?? ''}',
      'formI': '${raw['formI'] ?? ''}',
      'questI': '${raw['questI'] ?? ''}',
      'formII': '${raw['formII'] ?? ''}',
      'questII': '${raw['questII'] ?? ''}',
      'formIII': '${raw['formIII'] ?? ''}',
      'questIII': '${raw['questIII'] ?? ''}',
    };
  }, growable: true);
  // Oculus ha dodici soli livelli. Le vecchie schede restano leggibili, ma
  // non possono più oltrepassare il tetto della mod.
  result['level'] = readIntValue(result['level']).clamp(0, 12).toInt();
  result['progress'] = readIntValue(result['progress']).clamp(0, 2).toInt();
  result['titleLevel'] = readIntValue(
    result['titleLevel'],
  ).clamp(0, 12).toInt();
  result['growthPoints'] = readIntValue(
    result['growthPoints'],
  ).clamp(0, 36).toInt();
  result['inspirations'] = readIntValue(
    result['inspirations'],
    fallback: 3,
  ).clamp(0, 3).toInt();
  result['ascensionDust'] = max(0, readIntValue(result['ascensionDust']));
  result['absorbedDust'] = readIntValue(
    result['absorbedDust'],
  ).clamp(0, 3).toInt();
  return result;
}

int oculusPowerDieForTitleLevel(int level) {
  final safeLevel = level.clamp(0, 12).toInt();
  if (safeLevel >= 12) return 20;
  if (safeLevel >= 10) return 12;
  if (safeLevel >= 7) return 10;
  if (safeLevel >= 4) return 8;
  if (safeLevel >= 2) return 6;
  return 4;
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

  int oculusStatBonus(String key) =>
      max(0, oculusInt('${key}Mastery')).clamp(0, 99).toInt();

  int oculusDerivedMaximum(String key) {
    final die = max(4, oculusInt('${key}Die', fallback: 4));
    final bonus = oculusStatBonus(key);
    if (key == 'materia') return die + bonus;
    final power = oculusInt('forceDie', fallback: 4);
    return die + power + bonus;
  }

  List<Map<String, dynamic>> oculusArtSkills() {
    final raw = oculusModData['artSkills'];
    if (raw is! List) return const <Map<String, dynamic>>[];
    return raw
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .take(3)
        .toList(growable: false);
  }

  void setOculusArtSkillField(int index, String key, String value) {
    final skills = oculusArtSkills().map(Map<String, dynamic>.from).toList();
    final legacySkills =
        (oculusModData['skills'] as List?)
            ?.map((entry) => '$entry')
            .toList(growable: false) ??
        const <String>[];
    while (skills.length < 3) {
      skills.add(<String, dynamic>{});
    }
    skills[index][key] = value;
    oculusModData['artSkills'] = skills;
    // Il vecchio campo resta aggiornato per i salvataggi e gli export
    // precedenti. Quando si compila una Forma non tocchiamo il testo legacy;
    // quando si cambia solo il nome, conserviamo l'eventuale descrizione
    // storica dopo la prima riga.
    final nextLegacy = <String>[
      for (var skillIndex = 0; skillIndex < skills.length; skillIndex++)
        skillIndex < legacySkills.length
            ? legacySkills[skillIndex]
            : '${skills[skillIndex]['name'] ?? ''}',
    ];
    if (key == 'name') {
      final previous = nextLegacy[index];
      final lineBreak = previous.indexOf('\n');
      final tail = lineBreak < 0 ? '' : previous.substring(lineBreak);
      nextLegacy[index] = '${skills[index]['name'] ?? ''}$tail';
    }
    oculusModData['skills'] = nextLegacy;
    programmaSalvataggio(
      invalidateCaches: false,
      delay: const Duration(milliseconds: 900),
    );
  }

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

  Widget oculusArtTextField(
    int index,
    String key,
    String label, {
    int minLines = 1,
    int maxLines = 1,
    String helper = '',
  }) {
    final skills = oculusArtSkills();
    final value = index < skills.length ? '${skills[index][key] ?? ''}' : '';
    return TextFormField(
      key: ValueKey<String>('oculus_art_${index}_${key}_$value'),
      initialValue: value,
      minLines: minLines,
      maxLines: maxLines,
      onChanged: (next) => setOculusArtSkillField(index, key, next),
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

  Widget oculusMissionField(int index) {
    final missions =
        (oculusModData['missions'] as List?)
            ?.map((entry) => '$entry')
            .toList(growable: true) ??
        <String>[];
    while (missions.length < 12) {
      missions.add('');
    }
    final value = missions[index];
    return TextFormField(
      key: ValueKey<String>('oculus_title_requirement_${index}_$value'),
      initialValue: value,
      minLines: 1,
      maxLines: 2,
      onChanged: (next) {
        missions[index] = next;
        setOculusData('missions', missions);
      },
      decoration: InputDecoration(
        labelText: '${t('Requisito', 'Requirement')} ${index + 1}',
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
  Future<void> saveOculusReferencePdf({required bool sheet}) async {
    const manualAssetPath = 'assets/manuals/Manuale_Oculus.pdf';
    const manualFileName = 'Manuale_Oculus.pdf';
    const sheetAssetPath = 'assets/manuals/Scheda_Oculus_CORRETTA.pdf';
    const sheetFileName = 'Scheda_Oculus_CORRETTA.pdf';
    final assetPath = sheet ? sheetAssetPath : manualAssetPath;
    final fileName = sheet ? sheetFileName : manualFileName;
    final label = sheet ? 'scheda Oculus' : 'manuale Oculus';
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
          'Download di $label avviato.',
          '$label download started.',
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
          '${sheet ? 'Scheda' : 'Manuale'} Oculus salvato: ${file.path}',
          'Oculus ${sheet ? 'sheet' : 'manual'} saved: ${file.path}',
        );
      }
      aggiungiLog(risultato);
      notifyDiceResultChanged();
    } catch (error) {
      risultato = t(
        'Impossibile salvare $label: $error',
        'Could not save $label: $error',
      );
      notifyDiceResultChanged();
    }
  }

  Future<void> saveOculusFilledSheetPdf() async {
    final now = DateTime.now();
    final stamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    final fileName = 'Scheda_Oculus_compilata_$stamp.pdf';
    try {
      final bytes = await buildOculusFilledSheetPdf();
      if (kIsWeb) {
        await oculumDownloadBytes(
          bytes: bytes,
          fileName: fileName,
          mimeType: 'application/pdf',
        );
        risultato = t(
          'Download della scheda Oculus compilata avviato.',
          'Filled Oculus sheet download started.',
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
          'Scheda Oculus compilata salvata: ${file.path}',
          'Filled Oculus sheet saved: ${file.path}',
        );
      }
      aggiungiLog(risultato);
      notifyDiceResultChanged();
    } catch (error) {
      risultato = t(
        'Impossibile generare la scheda Oculus compilata: $error',
        'Could not generate the filled Oculus sheet: $error',
      );
      notifyDiceResultChanged();
    }
  }

  Future<Uint8List> buildOculusFilledSheetPdf() async {
    final doc = pw.Document(
      title: 'Scheda Oculus',
      author: 'Oculum',
      subject: 'Scheda Oculus compilata',
    );
    final regular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Poppins-Regular.ttf'),
    );
    final bold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Poppins-SemiBold.ttf'),
    );
    final theme = pw.ThemeData.withFont(base: regular, bold: bold);
    final dark = PdfColor.fromInt(0xFF151825);
    final cyan = PdfColor.fromInt(0xFF65C9DF);
    final pale = PdfColor.fromInt(0xFFEAF5F7);
    pw.Widget field(String label, String value) => pw.Container(
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: cyan, width: .65),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(font: bold, fontSize: 7.5, color: cyan),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            value.trim().isEmpty ? '—' : value.trim(),
            style: pw.TextStyle(font: regular, fontSize: 9.5),
          ),
        ],
      ),
    );
    pw.Widget section(String title, List<pw.Widget> children) => pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.all(9),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFF202536),
        border: pw.Border.all(color: cyan, width: .7),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title.toUpperCase(),
            style: pw.TextStyle(
              font: bold,
              fontSize: 11,
              color: cyan,
              letterSpacing: 1.2,
            ),
          ),
          pw.SizedBox(height: 7),
          ...children,
        ],
      ),
    );
    final stats = <(String, String)>[
      ('RES', 'resilienza'),
      ('VOL', 'volonta'),
      ('MAT', 'materia'),
      ('OCU', 'oculum'),
    ];
    final skills =
        (oculusModData['skills'] as List?)
            ?.map((value) => '$value')
            .take(3)
            .toList(growable: false) ??
        const <String>[];
    final artSkills = oculusArtSkills();
    final missions =
        (oculusModData['missions'] as List?)
            ?.map((value) => '$value')
            .take(12)
            .toList(growable: false) ??
        const <String>[];
    doc.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        pageTheme: pw.PageTheme(
          theme: theme,
          buildBackground: (_) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Container(color: dark),
          ),
        ),
        build: (_) => [
          pw.Text(
            'OCULUS',
            style: pw.TextStyle(
              font: bold,
              fontSize: 28,
              color: cyan,
              letterSpacing: 4,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Scheda compilata - Livello 0-12',
            style: pw.TextStyle(font: regular, fontSize: 10, color: pale),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              pw.Expanded(child: field('Nome', oculusText('name'))),
              pw.SizedBox(width: 8),
              pw.Expanded(child: field('Giocatore', oculusText('player'))),
              pw.SizedBox(width: 8),
              pw.Expanded(child: field('Livello', '${oculusInt('level')}/12')),
            ],
          ),
          pw.SizedBox(height: 8),
          field('Aspetto / Razza', oculusText('appearance')),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(child: field('Razza', oculusText('race'))),
              pw.SizedBox(width: 8),
              pw.Expanded(child: field('Titolo', oculusText('title'))),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: field('Livello Titolo', '${oculusInt('titleLevel')}/12'),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                child: field('Skill di Razza', oculusText('raceSkill')),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: field('CD Skill Razza', oculusText('raceSkillCooldown')),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          section('Dadi e Potere', [
            pw.Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final stat in stats)
                  field(
                    '${stat.$1} dado / bonus',
                    'd${oculusInt('${stat.$2}Die', fallback: 4)}  +${oculusStatBonus(stat.$2)}',
                  ),
                field(
                  'Potere',
                  '${oculusText('activeForce').toUpperCase()} d${oculusPowerDieForTitleLevel(oculusInt('titleLevel'))}',
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Tiro: dado Stat + dado Potere + bonus. Se il Master dichiara una DT, confronta il totale con la DT; altrimenti è sempre uno scontro.',
              style: pw.TextStyle(font: regular, fontSize: 8.6, color: pale),
            ),
          ]),
          section('Vita e risorse', [
            pw.Row(
              children: [
                pw.Expanded(
                  child: field(
                    'Vita',
                    '${oculusInt('life')}/${oculusInt('maxLife', fallback: 1)}',
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(child: field('Difesa', '${oculusInt('defense')}')),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: field(
                    'Ispirazioni',
                    '${oculusInt('inspirations', fallback: 3)}/3',
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 7),
            pw.Row(
              children: [
                pw.Expanded(
                  child: field(
                    'Scudo',
                    '${oculusInt('shield')}/${oculusInt('maxShield', fallback: 1)}',
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: field(
                    'Oculum',
                    '${oculusInt('oculumCurrent')}/${oculusInt('maxOculum', fallback: 1)}',
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: field(
                    'Ascension Dust',
                    '${oculusInt('ascensionDust')} possedute / ${oculusInt('absorbedDust')} assorbite',
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 7),
            field('Crescita', '${oculusInt('growthPoints')}/36 punti'),
          ]),
          section('Ferita e Missione', [
            field('Ferita', oculusText('wound')),
            pw.SizedBox(height: 7),
            field('Missione attiva', oculusText('activeMission')),
          ]),
          section('Oculum Art', [
            field('Art', oculusText('art')),
            pw.SizedBox(height: 7),
            for (var index = 0; index < 3; index++) ...[
              pw.Text(
                'SKILL ${index + 1}',
                style: pw.TextStyle(font: bold, fontSize: 9, color: cyan),
              ),
              pw.SizedBox(height: 4),
              field(
                'Nome / Costo Oculum',
                index < artSkills.length
                    ? '${artSkills[index]['name'] ?? ''}  |  ${artSkills[index]['cost'] ?? ''}'
                    : (index < skills.length ? skills[index] : ''),
              ),
              if (index < artSkills.length) ...[
                for (final form in const <(String, String)>[
                  ('I', 'formI'),
                  ('II', 'formII'),
                  ('III', 'formIII'),
                ]) ...[
                  pw.SizedBox(height: 5),
                  field(
                    'Forma ${form.$1}',
                    '${artSkills[index][form.$2] ?? ''}\nQuest: ${artSkills[index]['quest${form.$1}'] ?? ''}',
                  ),
                ],
              ],
              if (index < 2) pw.SizedBox(height: 10),
            ],
          ]),
          section('Missioni del Titolo', [
            for (var index = 0; index < 12; index++)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Text(
                  '${index + 1}. ${index < missions.length && missions[index].trim().isNotEmpty ? missions[index].trim() : '—'}',
                  style: pw.TextStyle(
                    font: regular,
                    fontSize: 8.5,
                    color: pale,
                  ),
                ),
              ),
          ]),
        ],
      ),
    );
    return doc.save();
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

  // Conservata per confronto con vecchie schede; la pagina usata dalla mod è
  // la versione in sezioni qui sotto, aderente alla Scheda Oculus corretta.
  // ignore: unused_element
  Widget _oculusModPageLegacy() {
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
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => saveOculusReferencePdf(sheet: false),
                        icon: const Icon(Icons.menu_book_outlined),
                        label: Text(t('Scarica manuale', 'Download manual')),
                      ),
                      FilledButton.icon(
                        onPressed: saveOculusFilledSheetPdf,
                        icon: const Icon(Icons.download_for_offline_outlined),
                        label: Text(
                          t(
                            'Scarica scheda compilata',
                            'Download filled sheet',
                          ),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => saveOculusReferencePdf(sheet: true),
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: Text(
                          t('Scarica scheda vuota', 'Download blank sheet'),
                        ),
                      ),
                    ],
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
                      'Tutti iniziano al livello 0 con d4 in RES, VOL, MAT e OCU. La scala è d4, d6, d8, d10, d12, d20.',
                      'Everyone starts at level 0 with d4 in RES, WILL, MAT and OCU. The ladder is d4, d6, d8, d10, d12, d20.',
                    ),
                  ),
                ],
              ]),
            oculusSection(t('Regole essenziali', 'Essential rules'), [
              SelectableText(
                t(
                  'LIVELLI: esistono solo 12 livelli, da 0 a 12. Ogni livello ottieni 3 punti Crescita: aumenta di 1 una Stat e scegli un dado Stat da far crescere di un gradino (d4 → d6 → d8 → d10 → d12 → d20). Ritrai Vita e Oculum e tieni il risultato più alto.\n'
                      'POTERE: Fato, Chaos o Oblio parte da d4. Il dado Potere cresce completando le Missioni del Titolo: livello Titolo 0-1 d4, 2-3 d6, 4-6 d8, 7-9 d10, 10-11 d12, 12 d20.\n'
                      'TIRO: dado Potere + dado della Stat + bonus della Stat. Di norma è sempre uno scontro tra giocatore e Master; si usa una DT solo se viene dichiarata.\n'
                      'VITA / OCULUM / SCUDO: Vita massima = massimo dado RES + Potere + bonus RES; Oculum massimo = massimo dado OCU + Potere + bonus OCU; Scudo = massimo dado MAT + bonus MAT e assorbe sempre prima della Vita.\n'
                      'ISPIRAZIONI: alla creazione scegli da 0 a 3 Ispirazioni. Spenderne una ritenta qualsiasi tiro; il Master ne assegna altre fino al massimo di 3.\n'
                      'OCULUM ART: ha esattamente tre Skill. Ogni Skill ha forme I, II e III e un proprio costo; le forme crescono con le missioni Art dedicate.',
                  'LEVELS: there are only 12 levels, from 0 to 12. Each level grants 3 Growth points: raise one Stat by 1 and choose one Stat die to advance by one step (d4 → d6 → d8 → d10 → d12 → d20). Reroll Life and Oculum, keeping the highest result.\n'
                      'POWER: Fate, Chaos or Oblivion starts at d4. The Power die grows by completing Title Missions: Title levels 0-1 d4, 2-3 d6, 4-6 d8, 7-9 d10, 10-11 d12, 12 d20.\n'
                      'ROLL: Power die + Stat die + Stat bonus. Normally every roll is contested by player and Master; use a DT only when declared.\n'
                      'LIFE / OCULUM / SHIELD: maximum Life = highest RES die + Power + RES bonus; maximum Oculum = highest OCU die + Power + OCU bonus; Shield = highest MAT die + MAT bonus and always absorbs before Life.\n'
                      'INSPIRATIONS: at creation choose 0 to 3 Inspirations. Spend one to retry any roll; the Master can grant more up to a maximum of 3.\n'
                      'OCULUM ART: has exactly three Skills. Each Skill has forms I, II and III and its own cost; forms grow through dedicated Art missions.',
                ),
              ),
            ]),
          ],
        );
      },
    );
  }

  Widget oculusHeader({required int page, required bool help}) {
    const labels = <(IconData, String, String)>[
      (Icons.badge_outlined, 'Scheda', 'Sheet'),
      (Icons.auto_awesome_motion_outlined, 'Titolo', 'Title'),
      (Icons.visibility_outlined, 'Oculum Art', 'Oculum Art'),
      (Icons.menu_book_outlined, 'Regole', 'Rules'),
    ];
    return gothicPanel(
      borderColor: primaryColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                        'Scheda carta e penna, organizzata in quattro pagine.',
                        'Paper-and-pencil sheet, organized into four pages.',
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
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var index = 0; index < labels.length; index++)
                ChoiceChip(
                  avatar: Icon(labels[index].$1, size: 17),
                  selected: page == index,
                  label: Text(t(labels[index].$2, labels[index].$3)),
                  onSelected: (_) =>
                      setOculusData('oculusPage', index, rebuild: true),
                ),
            ],
          ),
          const SizedBox(height: 6),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: help,
            title: Text(t('Aiuti contestuali', 'Context help')),
            subtitle: Text(
              t(
                'Spiegazioni brevi, senza automatizzare lo scontro con il Master.',
                'Short explanations without automating the Master contest.',
              ),
            ),
            onChanged: (value) =>
                setOculusData('helpEnabled', value, rebuild: true),
          ),
        ],
      ),
    );
  }

  Widget oculusIdentityAndStatsPage() {
    const stats = <(String, String)>[
      ('resilienza', 'RESILIENZA'),
      ('volonta', 'VOLONTA'),
      ('materia', 'MATERIA'),
      ('oculum', 'OCULUM'),
    ];
    return responsivePageList(
      pageKey: 'mod_oculus_identity',
      maxColumns: 2,
      minColumnWidth: 350,
      masonryColumns: true,
      fullWidthIndexes: const <int>{0},
      children: [
        oculusSection(t('Personaggio', 'Character'), [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(
                width: 250,
                child: oculusTextField('name', t('Personaggio', 'Character')),
              ),
              SizedBox(
                width: 250,
                child: oculusTextField('player', t('Giocatore', 'Player')),
              ),
              SizedBox(
                width: 170,
                child: oculusNumberField(
                  'level',
                  t('Livello 0-12', 'Level 0-12'),
                  maximum: 12,
                ),
              ),
              SizedBox(
                width: 220,
                child: oculusNumberField(
                  'growthPoints',
                  t('Crescita 0-36', 'Growth 0-36'),
                  maximum: 36,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          oculusTextField(
            'appearance',
            t('Aspetto / Razza', 'Appearance / Race'),
            minLines: 3,
            maxLines: 6,
            helper: t(
              'Descrivi oppure disegna la razza.',
              'Describe or draw the race.',
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(
                width: 300,
                child: oculusTextField('race', t('Razza', 'Race')),
              ),
              SizedBox(
                width: 180,
                child: oculusTextField(
                  'raceSkillCooldown',
                  t('CD Skill di Razza', 'Race Skill CD'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          oculusTextField(
            'raceSkill',
            t(
              'Skill di Razza / attacco con arma',
              'Race Skill / weapon attack',
            ),
            minLines: 2,
            maxLines: 4,
            helper: t(
              'La Skill può anche essere un attacco con arma; il CD è deciso con il Master.',
              'The Skill may also be a weapon attack; its CD is agreed with the Master.',
            ),
          ),
        ]),
        oculusSection(t('Dadi delle Stat', 'Stat dice'), [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final stat in stats) ...[
                SizedBox(
                  width: 168,
                  child: oculusDieSelector('${stat.$1}Die', stat.$2),
                ),
                SizedBox(
                  width: 128,
                  child: oculusNumberField(
                    '${stat.$1}Mastery',
                    '${t('Bonus', 'Bonus')} ${stat.$2}',
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          smallInfoText(
            t(
              'Ogni Level Up aumenta un dado di un gradino e assegna +1 a una Stat. Dado e bonus possono andare a Stat diverse.',
              'Each Level Up advances one die and grants +1 to a Stat. Die and bonus can go to different Stats.',
            ),
          ),
        ]),
        oculusSection(t('Risorse e combattimento', 'Resources and combat'), [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(
                width: 136,
                child: oculusNumberField(
                  'life',
                  t('Vita attuale', 'Current Life'),
                ),
              ),
              SizedBox(
                width: 136,
                child: oculusNumberField(
                  'maxLife',
                  t('Vita massima', 'Maximum Life'),
                  minimum: 1,
                ),
              ),
              SizedBox(
                width: 136,
                child: oculusNumberField(
                  'shield',
                  t('Scudo attuale', 'Current Shield'),
                ),
              ),
              SizedBox(
                width: 136,
                child: oculusNumberField(
                  'maxShield',
                  t('Scudo massimo', 'Maximum Shield'),
                ),
              ),
              SizedBox(
                width: 136,
                child: oculusNumberField(
                  'oculumCurrent',
                  t('Oculum attuale', 'Current Oculum'),
                ),
              ),
              SizedBox(
                width: 136,
                child: oculusNumberField(
                  'maxOculum',
                  t('Oculum massimo', 'Maximum Oculum'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          smallInfoText(
            t(
              'Riferimenti massimi: Vita ${oculusDerivedMaximum('resilienza')}, Scudo ${oculusDerivedMaximum('materia')}, Oculum ${oculusDerivedMaximum('oculum')}. Difesa: Materia + Potere + bonus Materia. Danno: massimo Volontà + Potere + bonus Volontà. Lo Scudo si consuma prima della Vita.',
              'Maximum references: Life ${oculusDerivedMaximum('resilienza')}, Shield ${oculusDerivedMaximum('materia')}, Oculum ${oculusDerivedMaximum('oculum')}. Defense: Matter + Power + Matter bonus. Damage: maximum Will + Power + Will bonus. Shield is spent before Life.',
            ),
          ),
        ]),
        oculusSection(t('Ispirazione e Dust', 'Inspiration and Dust'), [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(
                width: 170,
                child: oculusNumberField(
                  'inspirations',
                  t('Ispirazioni max 3', 'Inspirations max 3'),
                  maximum: 3,
                ),
              ),
              SizedBox(
                width: 180,
                child: oculusNumberField('ascensionDust', 'Ascension Dust'),
              ),
              SizedBox(
                width: 190,
                child: oculusNumberField(
                  'absorbedDust',
                  t('Dust assorbite', 'Absorbed Dust'),
                  maximum: 3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          smallInfoText(
            t(
              'Una Ispirazione ritenta qualsiasi tiro. Le Dust assorbite aumentano temporaneamente il dado di una Stat: massimo 3 nella sessione; 2 Dust causano 1d6 danni al corpo per turno, 3 Dust 2d6.',
              'One Inspiration retries any roll. Absorbed Dust temporarily advances a Stat die: maximum 3 in the session; 2 Dust cause 1d6 body damage per turn, 3 Dust 2d6.',
            ),
          ),
        ]),
      ],
    );
  }

  Widget oculusTitlePage() {
    final titleLevel = oculusInt('titleLevel').clamp(0, 12).toInt();
    final powerDie = oculusPowerDieForTitleLevel(titleLevel);
    return responsivePageList(
      pageKey: 'mod_oculus_title',
      maxColumns: 2,
      minColumnWidth: 350,
      masonryColumns: true,
      fullWidthIndexes: const <int>{0},
      children: [
        oculusSection(t('Titolo e Potere', 'Title and Power'), [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(
                width: 280,
                child: oculusTextField('title', t('Titolo', 'Title')),
              ),
              SizedBox(
                width: 170,
                child: TextFormField(
                  key: ValueKey<String>('oculus_title_level_$titleLevel'),
                  initialValue: '$titleLevel',
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                  ),
                  onChanged: (raw) {
                    final next = (int.tryParse(raw.trim()) ?? 0)
                        .clamp(0, 12)
                        .toInt();
                    oculusModData['titleLevel'] = next;
                    oculusModData['forceDie'] = oculusPowerDieForTitleLevel(
                      next,
                    );
                    gameModRevision.value++;
                    programmaSalvataggio(invalidateCaches: false);
                  },
                  decoration: InputDecoration(
                    labelText: t('Livello Titolo 0-12', 'Title Level 0-12'),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<String>(
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
                    labelText: t('Potere', 'Power'),
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
              ),
            ],
          ),
          const SizedBox(height: 10),
          smallInfoText(
            t(
              'Dado Potere automatico: d$powerDie. OPEN I al Titolo 6, OPEN II al Titolo 12; ogni OPEN è usabile una volta per Riposo Lungo.',
              'Automatic Power die: d$powerDie. OPEN I at Title 6, OPEN II at Title 12; each OPEN is usable once per Long Rest.',
            ),
          ),
          const SizedBox(height: 8),
          oculusTextField(
            'titleSkill',
            t('Skill / ricompensa del Titolo', 'Title Skill / reward'),
            minLines: 2,
            maxLines: 4,
          ),
          const SizedBox(height: 8),
          oculusTextField(
            'titleReward',
            t('Ricompensa aggiuntiva', 'Additional reward'),
            minLines: 2,
            maxLines: 3,
          ),
          const SizedBox(height: 8),
          oculusTextField('titleOpenI', 'OPEN I', minLines: 1, maxLines: 2),
          const SizedBox(height: 8),
          oculusTextField('titleOpenII', 'OPEN II', minLines: 1, maxLines: 2),
        ]),
        oculusSection(
          t('Ferita e Missione attiva', 'Wound and Active Mission'),
          [
            oculusTextField(
              'wound',
              t('Ferita', 'Wound'),
              minLines: 2,
              maxLines: 4,
            ),
            const SizedBox(height: 8),
            oculusTextField(
              'activeMission',
              t('Missione attiva', 'Active mission'),
              minLines: 3,
              maxLines: 6,
            ),
          ],
        ),
        oculusSection(
          t('Dodici requisiti del Titolo', 'Twelve Title requirements'),
          [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var index = 0; index < 12; index++)
                  SizedBox(width: 300, child: oculusMissionField(index)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget oculusArtPage() {
    return responsivePageList(
      pageKey: 'mod_oculus_art',
      maxColumns: 1,
      minColumnWidth: 350,
      fullWidthIndexes: const <int>{0, 1, 2, 3},
      children: [
        oculusSection(t('Oculum Art', 'Oculum Art'), [
          oculusTextField('art', t('Nome Art', 'Art name')),
          const SizedBox(height: 8),
          smallInfoText(
            t(
              'Esattamente tre Skill. Ogni Skill ha un costo in Oculum e le Forme I, II e III con quest dedicate: non sono i dodici requisiti del Titolo.',
              'Exactly three Skills. Each has an Oculum cost and Forms I, II and III with dedicated quests: they are not the twelve Title requirements.',
            ),
          ),
        ]),
        for (var index = 0; index < 3; index++)
          oculusSection('${t('Skill', 'Skill')} ${index + 1}', [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SizedBox(
                  width: 340,
                  child: oculusArtTextField(index, 'name', t('Nome', 'Name')),
                ),
                SizedBox(
                  width: 190,
                  child: oculusArtTextField(
                    index,
                    'cost',
                    t('Costo Oculum', 'Oculum cost'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            for (final form in const <(String, String)>[
              ('I', 'formI'),
              ('II', 'formII'),
              ('III', 'formIII'),
            ]) ...[
              Text(
                'FORMA ${form.$1}',
                style: TextStyle(
                  color: tertiaryColor,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 5),
              oculusArtTextField(
                index,
                form.$2,
                t('Effetto', 'Effect'),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 6),
              oculusArtTextField(
                index,
                'quest${form.$1}',
                t('Quest della Forma', 'Form quest'),
                minLines: 1,
                maxLines: 3,
              ),
              if (form.$1 != 'III') const SizedBox(height: 12),
            ],
          ]),
        oculusSection(t('Inventario iniziale', 'Starting inventory'), [
          smallInfoText(
            t(
              'Vitalium grezzo: ripristina Vita pari all’Oculum speso. Fiala di Oculum: recupera 1d4 Oculum. Aggiungi qui ogni altro oggetto della scheda carta e penna.',
              'Raw Vitalium: restores Life equal to Oculum spent. Oculum vial: restores 1d4 Oculum. Add every other paper-sheet item here.',
            ),
          ),
          const SizedBox(height: 8),
          oculusTextField(
            'notes',
            t('Altro inventario / note', 'Other inventory / notes'),
            minLines: 3,
            maxLines: 6,
          ),
        ]),
      ],
    );
  }

  Widget oculusRulesPage() {
    return responsivePageList(
      pageKey: 'mod_oculus_rules',
      maxColumns: 1,
      minColumnWidth: 350,
      fullWidthIndexes: const <int>{0, 1},
      children: [
        oculusSection(t('Manuale e schede', 'Manual and sheets'), [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => saveOculusReferencePdf(sheet: false),
                icon: const Icon(Icons.menu_book_outlined),
                label: Text(t('Scarica manuale', 'Download manual')),
              ),
              OutlinedButton.icon(
                onPressed: () => saveOculusReferencePdf(sheet: true),
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: Text(t('Scarica scheda vuota', 'Download blank sheet')),
              ),
              FilledButton.icon(
                onPressed: saveOculusFilledSheetPdf,
                icon: const Icon(Icons.download_for_offline_outlined),
                label: Text(
                  t('Scarica scheda compilata', 'Download filled sheet'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          smallInfoText(
            t(
              'La scheda vuota è quella ufficiale fornita; la compilata usa i dati di queste quattro pagine.',
              'The blank sheet is the supplied official one; the filled version uses the data from these four pages.',
            ),
          ),
        ]),
        oculusSection(t('Regole essenziali', 'Essential rules'), [
          SelectableText(
            t(
              'CREAZIONE: Livello 0, tutte le Stat a d4, Potere Fato/Chaos/Oblio a d4, 0-3 Ispirazioni, Vitalium grezzo e Fiala di Oculum.\n\nTIRI: dado Potere + dado Stat + bonus Stat. Il confronto è tra giocatore e Master dal vivo oppure tra due app separate; usa una DT soltanto se è dichiarata.\n\nCRESCITA: 3 Punti Crescita = 1 Level Up; 36 = livello 12. A ogni Level Up avanza un dado Stat e assegna +1 a una Stat; ritira Vita e Oculum e mantieni il più alto.\n\nTITOLO: le 12 missioni fanno crescere il Titolo e il dado Potere; OPEN I al livello Titolo 6, OPEN II al 12.\n\nART: tre Skill, ciascuna con costo Oculum, Forme I/II/III e quest dedicate.\n\nRIPOSO LUNGO: recupera completamente Vita, Scudo, Oculum e OPEN.',
              'CREATION: Level 0, every Stat at d4, Fate/Chaos/Oblivion Power at d4, 0-3 Inspirations, Raw Vitalium and an Oculum Vial.\n\nROLLS: Power die + Stat die + Stat bonus. The contest is player versus Master in person or across two separate apps; use a DT only when declared.\n\nGROWTH: 3 Growth Points = 1 Level Up; 36 = level 12. At each Level Up advance one Stat die and grant +1 to a Stat; reroll Life and Oculum and keep the higher result.\n\nTITLE: the 12 missions grow the Title and Power die; OPEN I at Title level 6, OPEN II at 12.\n\nART: three Skills, each with Oculum cost, Forms I/II/III and dedicated quests.\n\nLONG REST: fully restores Life, Shield, Oculum and OPEN.',
            ),
          ),
        ]),
      ],
    );
  }

  Widget oculusModPage() {
    return ValueListenableBuilder<int>(
      valueListenable: gameModRevision,
      builder: (context, revision, child) {
        final page = oculusInt('oculusPage').clamp(0, 3).toInt();
        final help = readBoolValue(
          oculusModData['helpEnabled'],
          fallback: true,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            oculusHeader(page: page, help: help),
            const SizedBox(height: 10),
            switch (page) {
              0 => oculusIdentityAndStatsPage(),
              1 => oculusTitlePage(),
              2 => oculusArtPage(),
              _ => oculusRulesPage(),
            },
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
