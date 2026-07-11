part of '../../main.dart';

class RuneArtWordDef {
  const RuneArtWordDef({
    required this.id,
    required this.block,
    required this.choiceIt,
    required this.choiceEn,
    required this.effectIt,
    required this.effectEn,
    required this.cost,
    required this.dt,
    this.custom = false,
  });

  final String id;
  final String block;
  final String choiceIt;
  final String choiceEn;
  final String effectIt;
  final String effectEn;
  final int cost;
  final int dt;
  final bool custom;
}

const List<RuneArtWordDef> runeArtOfficialWords = <RuneArtWordDef>[
  RuneArtWordDef(
    id: 'target_self_ally',
    block: 'TARGET',
    choiceIt: 'Self / Ally',
    choiceEn: 'Self / Ally',
    effectIt: 'te o 1 alleato a 6m',
    effectEn: 'you or 1 ally within 6m',
    cost: 0,
    dt: 0,
  ),
  RuneArtWordDef(
    id: 'target_zone_3m',
    block: 'TARGET',
    choiceIt: 'Zona 3m',
    choiceEn: 'Zone 3m',
    effectIt: 'area centrata da 3m',
    effectEn: 'centered 3m area',
    cost: 1,
    dt: 0,
  ),
  RuneArtWordDef(
    id: 'target_zone_5m',
    block: 'TARGET',
    choiceIt: 'Zona 5m',
    choiceEn: 'Zone 5m',
    effectIt: 'area centrata da 5m',
    effectEn: 'centered 5m area',
    cost: 2,
    dt: 0,
  ),
  RuneArtWordDef(
    id: 'target_zone_7m',
    block: 'TARGET',
    choiceIt: 'Zona 7m',
    choiceEn: 'Zone 7m',
    effectIt: 'area centrata da 7m',
    effectEn: 'centered 7m area',
    cost: 3,
    dt: 0,
  ),
  RuneArtWordDef(
    id: 'target_line_10m',
    block: 'TARGET',
    choiceIt: 'Linea 10m',
    choiceEn: 'Line 10m',
    effectIt: 'linea retta da 10m',
    effectEn: '10m straight line',
    cost: 1,
    dt: 0,
  ),
  RuneArtWordDef(
    id: 'verb_ward',
    block: 'VERBO',
    choiceIt: 'WARD',
    choiceEn: 'WARD',
    effectIt: 'genera Resistenza',
    effectEn: 'generates Resistance',
    cost: 1,
    dt: 1,
  ),
  RuneArtWordDef(
    id: 'verb_mend',
    block: 'VERBO',
    choiceIt: 'MEND',
    choiceEn: 'MEND',
    effectIt: 'cura istantanea',
    effectEn: 'instant healing',
    cost: 1,
    dt: 1,
  ),
  RuneArtWordDef(
    id: 'verb_purge',
    block: 'VERBO',
    choiceIt: 'PURGE',
    choiceEn: 'PURGE',
    effectIt: 'rimuove 1 malus',
    effectEn: 'removes 1 malus',
    cost: 1,
    dt: 1,
  ),
  RuneArtWordDef(
    id: 'verb_bind',
    block: 'VERBO',
    choiceIt: 'BIND',
    choiceEn: 'BIND',
    effectIt: 'rallenta o immobilizza',
    effectEn: 'slows or immobilizes',
    cost: 1,
    dt: 2,
  ),
  RuneArtWordDef(
    id: 'verb_channel',
    block: 'VERBO',
    choiceIt: 'CHANNEL',
    choiceEn: 'CHANNEL',
    effectIt: 'potenzia skill e arti',
    effectEn: 'empowers skills and arts',
    cost: 1,
    dt: 1,
  ),
  RuneArtWordDef(
    id: 'verb_mirror',
    block: 'VERBO',
    choiceIt: 'MIRROR',
    choiceEn: 'MIRROR',
    effectIt: 'riflette una percentuale del danno',
    effectEn: 'reflects a damage percentage',
    cost: 2,
    dt: 3,
  ),
  RuneArtWordDef(
    id: 'verb_intercept',
    block: 'VERBO',
    choiceIt: 'INTERCEPT',
    choiceEn: 'INTERCEPT',
    effectIt: 'dirotta 1 colpo su di te o sullo scudo',
    effectEn: 'redirects 1 hit to you or your shield',
    cost: 1,
    dt: 2,
  ),
  RuneArtWordDef(
    id: 'verb_fortify',
    block: 'VERBO',
    choiceIt: 'FORTIFY',
    choiceEn: 'FORTIFY',
    effectIt: '+Difesa o CM temporanei',
    effectEn: '+temporary Defense or CM',
    cost: 1,
    dt: 1,
  ),
  RuneArtWordDef(
    id: 'verb_destroy',
    block: 'VERBO',
    choiceIt: 'DESTR0Y',
    choiceEn: 'DESTR0Y',
    effectIt: '+50% danni',
    effectEn: '+50% damage',
    cost: 3,
    dt: 5,
  ),
  RuneArtWordDef(
    id: 'aspect_vital',
    block: 'ASPETTO',
    choiceIt: 'Vital',
    choiceEn: 'Vital',
    effectIt: 'luce curativa',
    effectEn: 'healing light',
    cost: 1,
    dt: 0,
  ),
  RuneArtWordDef(
    id: 'aspect_lunar',
    block: 'ASPETTO',
    choiceIt: 'Lunar',
    choiceEn: 'Lunar',
    effectIt: 'bonus contro Oscuro e sinergie luna',
    effectEn: 'bonus vs Dark and moon synergies',
    cost: 1,
    dt: 1,
  ),
  RuneArtWordDef(
    id: 'aspect_aqua',
    block: 'ASPETTO',
    choiceIt: 'Aqua',
    choiceEn: 'Aqua',
    effectIt: 'purifica',
    effectEn: 'purifies',
    cost: 1,
    dt: 0,
  ),
  RuneArtWordDef(
    id: 'aspect_shadow',
    block: 'ASPETTO',
    choiceIt: 'Shadow',
    choiceEn: 'Shadow',
    effectIt: 'occultamento e reindirizzo',
    effectEn: 'concealment and redirection',
    cost: 1,
    dt: 1,
  ),
  RuneArtWordDef(
    id: 'aspect_stone',
    block: 'ASPETTO',
    choiceIt: 'Stone',
    choiceEn: 'Stone',
    effectIt: 'scudo piu efficiente',
    effectEn: 'more efficient shield',
    cost: 1,
    dt: 0,
  ),
  RuneArtWordDef(
    id: 'aspect_wind',
    block: 'ASPETTO',
    choiceIt: 'Wind',
    choiceEn: 'Wind',
    effectIt: 'mobilita e intercetto',
    effectEn: 'mobility and interception',
    cost: 1,
    dt: 1,
  ),
  RuneArtWordDef(
    id: 'aspect_flame',
    block: 'ASPETTO',
    choiceIt: 'Flame',
    choiceEn: 'Flame',
    effectIt: 'cauterizza e dot',
    effectEn: 'cauterizes and applies DoT',
    cost: 1,
    dt: 1,
  ),
  RuneArtWordDef(
    id: 'aspect_mind',
    block: 'ASPETTO',
    choiceIt: 'Mind',
    choiceEn: 'Mind',
    effectIt: 'anti-paura e anti-confusione',
    effectEn: 'anti-fear and anti-confusion',
    cost: 1,
    dt: 2,
  ),
  RuneArtWordDef(
    id: 'mod_pulse',
    block: 'MOD',
    choiceIt: 'Pulse',
    choiceEn: 'Pulse',
    effectIt: 'istantaneo ad area piccola',
    effectEn: 'instant small area',
    cost: 0,
    dt: 0,
  ),
  RuneArtWordDef(
    id: 'mod_dome',
    block: 'MOD',
    choiceIt: 'Dome',
    choiceEn: 'Dome',
    effectIt: 'cupola persistente',
    effectEn: 'persistent dome',
    cost: 1,
    dt: 1,
  ),
  RuneArtWordDef(
    id: 'mod_veil',
    block: 'MOD',
    choiceIt: 'Veil',
    choiceEn: 'Veil',
    effectIt: 'velo personale',
    effectEn: 'personal veil',
    cost: 0,
    dt: 0,
  ),
  RuneArtWordDef(
    id: 'mod_tether',
    block: 'MOD',
    choiceIt: 'Tether',
    choiceEn: 'Tether',
    effectIt: 'vincolo tra due bersagli',
    effectEn: 'bond between two targets',
    cost: 1,
    dt: 1,
  ),
  RuneArtWordDef(
    id: 'mod_glyph',
    block: 'MOD',
    choiceIt: 'Glyph',
    choiceEn: 'Glyph',
    effectIt: 'marchio a terra',
    effectEn: 'ground mark',
    cost: 0,
    dt: 0,
  ),
  RuneArtWordDef(
    id: 'mod_totem',
    block: 'MOD',
    choiceIt: 'Totem',
    choiceEn: 'Totem',
    effectIt: 'ancora stazionaria',
    effectEn: 'stationary anchor',
    cost: 1,
    dt: 1,
  ),
  RuneArtWordDef(
    id: 'mod_halo',
    block: 'MOD',
    choiceIt: 'Halo',
    choiceEn: 'Halo',
    effectIt: 'aura su portatore',
    effectEn: 'aura on carrier',
    cost: 1,
    dt: 1,
  ),
  RuneArtWordDef(
    id: 'intensity_i',
    block: 'INTENSITA',
    choiceIt: 'I',
    choiceEn: 'I',
    effectIt: 'base',
    effectEn: 'base',
    cost: 0,
    dt: 0,
  ),
  RuneArtWordDef(
    id: 'intensity_ii',
    block: 'INTENSITA',
    choiceIt: 'II',
    choiceEn: 'II',
    effectIt: '+50% potenza',
    effectEn: '+50% power',
    cost: 1,
    dt: 1,
  ),
  RuneArtWordDef(
    id: 'intensity_iii',
    block: 'INTENSITA',
    choiceIt: 'III',
    choiceEn: 'III',
    effectIt: '+100% potenza',
    effectEn: '+100% power',
    cost: 2,
    dt: 2,
  ),
  RuneArtWordDef(
    id: 'intensity_iv',
    block: 'INTENSITA',
    choiceIt: 'IV',
    choiceEn: 'IV',
    effectIt: '+150% potenza',
    effectEn: '+150% power',
    cost: 3,
    dt: 3,
  ),
  RuneArtWordDef(
    id: 'duration_1_action',
    block: 'DURATA',
    choiceIt: '1 azione',
    choiceEn: '1 action',
    effectIt: 'immediato',
    effectEn: 'immediate',
    cost: 0,
    dt: 0,
  ),
  RuneArtWordDef(
    id: 'duration_3_turns',
    block: 'DURATA',
    choiceIt: '3 turni',
    choiceEn: '3 turns',
    effectIt: 'persistenza breve',
    effectEn: 'short persistence',
    cost: 1,
    dt: 0,
  ),
  RuneArtWordDef(
    id: 'duration_5_turns',
    block: 'DURATA',
    choiceIt: '5 turni',
    choiceEn: '5 turns',
    effectIt: 'persistenza media',
    effectEn: 'medium persistence',
    cost: 2,
    dt: 1,
  ),
  RuneArtWordDef(
    id: 'duration_scene',
    block: 'DURATA',
    choiceIt: 'Scena',
    choiceEn: 'Scene',
    effectIt: 'persistenza lunga',
    effectEn: 'long persistence',
    cost: 3,
    dt: 2,
  ),
  RuneArtWordDef(
    id: 'trigger_on_crit',
    block: 'TRIGGER',
    choiceIt: 'On Crit',
    choiceEn: 'On Crit',
    effectIt: 'si attiva su critico',
    effectEn: 'triggers on critical',
    cost: 1,
    dt: 1,
  ),
  RuneArtWordDef(
    id: 'trigger_on_hit',
    block: 'TRIGGER',
    choiceIt: 'On Hit',
    choiceEn: 'On Hit',
    effectIt: 'si attiva a colpo riuscito',
    effectEn: 'triggers on hit',
    cost: 1,
    dt: 1,
  ),
  RuneArtWordDef(
    id: 'trigger_below_half_hp',
    block: 'TRIGGER',
    choiceIt: '<50% Vita',
    choiceEn: '<50% HP',
    effectIt: 'si attiva sotto meta vita',
    effectEn: 'triggers below half HP',
    cost: 1,
    dt: 1,
  ),
];

const Set<String> runeArtBaseWordIds = <String>{
  'target_self_ally',
  'mod_pulse',
  'intensity_i',
  'duration_1_action',
};

const List<String> _runeArtIntensityOrder = <String>[
  'intensity_i',
  'intensity_ii',
  'intensity_iii',
  'intensity_iv',
];

const List<String> _runeArtDurationOrder = <String>[
  'duration_1_action',
  'duration_3_turns',
  'duration_5_turns',
  'duration_scene',
];

String runeArtCustomIdFromName(String name) {
  final base = oculumNormalizeText(name.trim())
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  return 'custom_rune_${base.isEmpty ? DateTime.now().millisecondsSinceEpoch : base}';
}

RuneArtWordDef runeWordFromCustom(RuneArtCustomWord word) {
  return RuneArtWordDef(
    id: word.id,
    block: word.block.trim().isEmpty ? 'CUSTOM' : word.block.trim(),
    choiceIt: word.choiceIt,
    choiceEn: word.choiceEn,
    effectIt: word.effectIt,
    effectEn: word.effectEn,
    cost: word.cost,
    dt: word.dt,
    custom: true,
  );
}

String runeArtQuickCustomEffectText(CharacterArt art) {
  final selected = {...art.runeQuickWordIds, ...art.runeQuickWordIdsSlot2};
  if (selected.isEmpty || art.runeCustomWords.isEmpty) return '';
  final texts = <String>[];
  for (final word in art.runeCustomWords) {
    if (!selected.contains(word.id)) continue;
    if (word.effectIt.trim().isNotEmpty) texts.add(word.effectIt.trim());
    if (word.effectEn.trim().isNotEmpty &&
        word.effectEn.trim() != word.effectIt.trim()) {
      texts.add(word.effectEn.trim());
    }
  }
  return texts.join('\n');
}

extension _OculumHomeRuneArt on _OculumHomePageState {
  CharacterArt ensureRuneArtOnSheet() {
    CharacterArt? runeArt;
    for (final art in arti) {
      if (isRuneArt(art)) {
        runeArt = art;
        break;
      }
    }

    if (runeArt == null) {
      runeArt = CharacterArt(
        nome: 'Rune Art',
        tipo: 'Rune Art',
        descrizione:
            'Il potere delle rune si avvicina molto alle Oculum Art, ma e piu facilmente modificabile, anche in fight se si e esperti. Costruisci formule scegliendo target, verbo, aspetto, mod, intensita, durata e trigger. Puoi preparare primo o secondo slot. Le combo con Rune Art valgono il 25%.',
        skills: [
          ArtSkill(
            nome: 'Libro Runico',
            livello: 1,
            evo1:
                'Apprendi sei parole da un libro. Self / Ally, Pulse, Intensita I e 1 azione sono sempre disponibili.',
            evo2:
                'Puoi tenere due formule rapide e ricombinare parole tra primo e secondo slot.',
            evo3:
                'Le rune note possono essere adattate in fight se la scena lo permette.',
            evo4:
                'Runista esperto: intensita e durata avanzate restano sequenziali, ma puoi correggere una parola della formula durante il fight.',
          ),
          ArtSkill(
            nome: 'Composizione Runica',
            livello: 1,
            evo1:
                'Scegli parole rapide. La formula mostra costo, DT e blocchi mancanti.',
            evo2:
                'Se una formula ha Target, Verbo, Mod e Durata, il master puo trattarla come formula completa.',
            evo3:
                'Le parole custom del master possono entrare nella selezione rapida.',
            evo4:
                'Le formule rapide possono essere annotate come primo o secondo slot senza perdere le parole imparate.',
          ),
          ArtSkill(
            nome: 'Rune in Fight',
            livello: 1,
            evo1:
                'Le Rune Art sono piu modificabili delle Oculum Art, ma richiedono parole note.',
            evo2:
                'Durata e Intensita devono essere apprese in ordine: I, II, III, IV e 1 azione, 3 turni, 5 turni, Scena.',
            evo3:
                'Il master puo aggiungere parole nuove con costo e DT propri.',
            evo4:
                'Una formula Rune Art ben preparata puo sostenere altre Skill o Art, mantenendo la combo al 25%.',
          ),
        ],
        openName: 'Schema Runico',
        openDescription:
            'Apri una struttura di rune gia preparata: la formula resta leggibile, modificabile e compatibile con le altre regole della scheda.',
        openBuff: '@TiroOculum+1 @TiroMateria+1',
        openSkill:
            'Formula rapida: componi parole note e applica il costo totale e la DT totale.',
        runeWordsKnown: runeArtBaseWordIds.toList(),
        runeQuickWordIds: runeArtBaseWordIds.toList(),
        runeQuickWordIdsSlot2: runeArtBaseWordIds.toList(),
      );
      arti.add(runeArt);
    }

    ensureRuneArtDefaults(runeArt);
    return runeArt;
  }

  void ensureRuneArtDefaults(CharacterArt art) {
    for (final id in runeArtBaseWordIds) {
      if (!art.runeWordsKnown.contains(id)) art.runeWordsKnown.add(id);
    }
    art.runeWordsKnown = art.runeWordsKnown.toSet().toList();
    final known = runeKnownWordSet(art);
    art.runeQuickWordIds = <String>{
      for (final id in art.runeQuickWordIds)
        if (known.contains(id)) id,
    }.toList();
    art.runeQuickWordIdsSlot2 = <String>{
      for (final id in art.runeQuickWordIdsSlot2)
        if (known.contains(id)) id,
    }.toList();
    if (art.runeQuickWordIds.isEmpty) {
      art.runeQuickWordIds.addAll(runeArtBaseWordIds);
    }
    if (art.runeQuickWordIdsSlot2.isEmpty) {
      art.runeQuickWordIdsSlot2.addAll(runeArtBaseWordIds);
    }
    art.runeActiveSlot = art.runeActiveSlot == 2 ? 2 : 1;
  }

  Set<String> runeKnownWordSet(CharacterArt art) {
    return <String>{...runeArtBaseWordIds, ...art.runeWordsKnown};
  }

  List<RuneArtWordDef> runeWordsForArt(CharacterArt art) {
    return <RuneArtWordDef>[
      ...runeArtOfficialWords,
      for (final word in art.runeCustomWords) runeWordFromCustom(word),
    ];
  }

  RuneArtWordDef? runeWordById(CharacterArt art, String id) {
    for (final word in runeWordsForArt(art)) {
      if (word.id == id) return word;
    }
    return null;
  }

  bool runeCanLearnWord(CharacterArt art, RuneArtWordDef word) {
    final known = runeKnownWordSet(art);
    if (known.contains(word.id)) return false;

    final intensityIndex = _runeArtIntensityOrder.indexOf(word.id);
    if (intensityIndex > 0) {
      return known.contains(_runeArtIntensityOrder[intensityIndex - 1]);
    }

    final durationIndex = _runeArtDurationOrder.indexOf(word.id);
    if (durationIndex > 0) {
      return known.contains(_runeArtDurationOrder[durationIndex - 1]);
    }

    return true;
  }

  List<RuneArtWordDef> runeLearnableWords(CharacterArt art) {
    return [
      for (final word in runeWordsForArt(art))
        if (runeCanLearnWord(art, word)) word,
    ];
  }

  String runeWordLabel(RuneArtWordDef word) {
    return t(word.choiceIt, word.choiceEn);
  }

  String runeWordEffect(RuneArtWordDef word) {
    return t(word.effectIt, word.effectEn);
  }

  List<String> runeSlotWordIds(CharacterArt art, int slot) {
    return slot == 2 ? art.runeQuickWordIdsSlot2 : art.runeQuickWordIds;
  }

  String runeArtFormulaSummary(CharacterArt art, {int? slot}) {
    ensureRuneArtDefaults(art);
    final activeSlot = slot ?? art.runeActiveSlot;
    final words = [
      for (final id in runeSlotWordIds(art, activeSlot))
        if (runeWordById(art, id) != null) runeWordById(art, id)!,
    ];
    final totalCost = words.fold<int>(0, (sum, word) => sum + word.cost);
    final totalDt = words.fold<int>(0, (sum, word) => sum + word.dt);
    final blocks = <String, List<String>>{};
    for (final word in words) {
      blocks.putIfAbsent(word.block, () => <String>[]).add(runeWordLabel(word));
    }
    final blockText = blocks.entries
        .map((entry) => '${entry.key}: ${entry.value.join(', ')}')
        .join(' | ');
    return t(
      'Slot $activeSlot Rune Art: $blockText. Costo $totalCost Oculum, DT $totalDt. Combo al 25%.',
      'Rune Art slot $activeSlot: $blockText. Oculum cost $totalCost, DT $totalDt. Combo at 25%.',
    );
  }

  void learnRuneBookForSheet() {
    refreshOculumHome(() {
      final art = ensureRuneArtOnSheet();
      final learned = <RuneArtWordDef>[];
      while (learned.length < 6) {
        final learnable = runeLearnableWords(art);
        if (learnable.isEmpty) break;
        final next = learnable.first;
        art.runeWordsKnown.add(next.id);
        learned.add(next);
      }
      art.runeBooksRead += 1;
      ensureRuneArtDefaults(art);
      final learnedText = learned.isEmpty
          ? t('nessuna parola nuova', 'no new word')
          : learned.map(runeWordLabel).join(', ');
      risultato = t(
        'Libro Runico letto. Parole apprese: $learnedText. ${runeArtFormulaSummary(art)}',
        'Runic book read. Learned words: $learnedText. ${runeArtFormulaSummary(art)}',
      );
      aggiungiLog(risultato);
    });
    programmaSalvataggio();
  }

  void createRuneArtQuickly() {
    refreshOculumHome(() {
      final art = ensureRuneArtOnSheet();
      risultato = t(
        'Rune Art pronta. ${runeArtFormulaSummary(art)}',
        'Rune Art ready. ${runeArtFormulaSummary(art)}',
      );
      aggiungiLog(risultato);
    });
    programmaSalvataggio();
  }

  Future<void> openRuneQuickWordsDialog() async {
    final art = ensureRuneArtOnSheet();
    ensureRuneArtDefaults(art);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        var selectedSlot = art.runeActiveSlot;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final known = runeKnownWordSet(art);
            final words = [
              for (final word in runeWordsForArt(art))
                if (known.contains(word.id)) word,
            ];
            final groupedWords = <String, List<RuneArtWordDef>>{};
            for (final word in words) {
              groupedWords.putIfAbsent(word.block, () => []).add(word);
            }
            final selectedIds = runeSlotWordIds(art, selectedSlot);

            return AlertDialog(
              backgroundColor: backgroundMidColor,
              title: Text(
                t('Parole rapide Rune Art', 'Rune Art quick words'),
                style: TextStyle(color: primaryColor),
              ),
              content: SizedBox(
                width: min(MediaQuery.of(context).size.width * 0.92, 720),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      smallInfoText(
                        t(
                          'Ogni libro insegna fino a sei parole; Self / Ally, Pulse e Intensita I restano sempre disponibili. Seleziona lo slot e le sottovoci: la scheda calcola costo Oculum e DT.',
                          'Each book teaches up to six words; Self / Ally, Pulse and Intensity I always stay available. Select the slot and subvoices: the sheet calculates Oculum cost and DT.',
                        ),
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<int>(
                        segments: [
                          ButtonSegment<int>(
                            value: 1,
                            icon: const Icon(Icons.looks_one),
                            label: Text(t('Primo slot', 'First slot')),
                          ),
                          ButtonSegment<int>(
                            value: 2,
                            icon: const Icon(Icons.looks_two),
                            label: Text(t('Secondo slot', 'Second slot')),
                          ),
                        ],
                        selected: {selectedSlot},
                        onSelectionChanged: (selection) {
                          final next = selection.first;
                          refreshOculumHome(() {
                            selectedSlot = next;
                            art.runeActiveSlot = next;
                            risultato = runeArtFormulaSummary(art);
                          });
                          setDialogState(() {});
                          programmaSalvataggio();
                        },
                      ),
                      const SizedBox(height: 12),
                      for (final entry in groupedWords.entries)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            childrenPadding: const EdgeInsets.only(bottom: 8),
                            initiallyExpanded: runeArtBaseWordIds.any(
                              (id) => entry.value.any((word) => word.id == id),
                            ),
                            title: Text(
                              entry.key,
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final word in entry.value)
                                    FilterChip(
                                      selected: selectedIds.contains(word.id),
                                      label: Text(
                                        '${runeWordLabel(word)}  +${word.cost} / DT ${word.dt}',
                                      ),
                                      tooltip: runeWordEffect(word),
                                      selectedColor: tertiaryColor.withValues(
                                        alpha: 0.35,
                                      ),
                                      checkmarkColor: primaryColor,
                                      onSelected: (selected) {
                                        refreshOculumHome(() {
                                          final target = runeSlotWordIds(
                                            art,
                                            selectedSlot,
                                          );
                                          if (selected) {
                                            if (!target.contains(word.id)) {
                                              target.add(word.id);
                                            }
                                          } else {
                                            target.remove(word.id);
                                          }
                                          art.runeActiveSlot = selectedSlot;
                                          ensureRuneArtDefaults(art);
                                          risultato = runeArtFormulaSummary(
                                            art,
                                          );
                                          aggiungiLog(risultato);
                                        });
                                        setDialogState(() {});
                                        programmaSalvataggio();
                                      },
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 14),
                      smallInfoText(runeArtFormulaSummary(art)),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(t('Chiudi', 'Close')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> openRuneCustomWordDialog() async {
    final art = ensureRuneArtOnSheet();
    final nameController = TextEditingController();
    final effectController = TextEditingController();
    final costController = TextEditingController(text: '1');
    final dtController = TextEditingController(text: '1');
    var block = 'CUSTOM';

    final custom = await showDialog<RuneArtCustomWord>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: backgroundMidColor,
              title: Text(
                t('Parola runica master', 'Master rune word'),
                style: TextStyle(color: primaryColor),
              ),
              content: SizedBox(
                width: min(MediaQuery.of(context).size.width * 0.92, 560),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      smallInfoText(
                        t(
                          'Il master puo aggiungere parole nuove. Sono additive, salvate dentro la Rune Art e non cancellano parole ufficiali.',
                          'The master can add new words. They are additive, saved inside Rune Art and never delete official words.',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: fieldDecoration(
                          t('Nome parola', 'Word name'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: block,
                        dropdownColor: backgroundMidColor,
                        decoration: fieldDecoration(t('Blocco', 'Block')),
                        items: const [
                          DropdownMenuItem(
                            value: 'TARGET',
                            child: Text('TARGET'),
                          ),
                          DropdownMenuItem(
                            value: 'VERBO',
                            child: Text('VERBO'),
                          ),
                          DropdownMenuItem(
                            value: 'ASPETTO',
                            child: Text('ASPETTO'),
                          ),
                          DropdownMenuItem(value: 'MOD', child: Text('MOD')),
                          DropdownMenuItem(
                            value: 'TRIGGER',
                            child: Text('TRIGGER'),
                          ),
                          DropdownMenuItem(
                            value: 'CUSTOM',
                            child: Text('CUSTOM'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() => block = value);
                        },
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: effectController,
                        minLines: 2,
                        maxLines: 4,
                        style: const TextStyle(color: Colors.white),
                        decoration: fieldDecoration(t('Effetto', 'Effect')),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: costController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              decoration: fieldDecoration(t('Costo', 'Cost')),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: dtController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              decoration: fieldDecoration('DT'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(t('Annulla', 'Cancel')),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    final name = cleanUiText(nameController.text).trim();
                    if (name.isEmpty) return;
                    final idBase = runeArtCustomIdFromName(name);
                    var id = idBase;
                    var suffix = 2;
                    final used = {
                      for (final word in runeWordsForArt(art)) word.id,
                    };
                    while (used.contains(id)) {
                      id = '${idBase}_$suffix';
                      suffix += 1;
                    }
                    Navigator.of(dialogContext).pop(
                      RuneArtCustomWord(
                        id: id,
                        block: block,
                        choiceIt: name,
                        choiceEn: name,
                        effectIt: effectController.text.trim(),
                        effectEn: effectController.text.trim(),
                        cost: leggiNumero(costController),
                        dt: leggiNumero(dtController),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: Text(t('Aggiungi', 'Add')),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    effectController.dispose();
    costController.dispose();
    dtController.dispose();
    if (!mounted || custom == null) return;

    refreshOculumHome(() {
      art.runeCustomWords.add(custom);
      art.runeWordsKnown.add(custom.id);
      runeSlotWordIds(art, art.runeActiveSlot).add(custom.id);
      ensureRuneArtDefaults(art);
      risultato = t(
        'Parola runica aggiunta: ${custom.choiceIt}. ${runeArtFormulaSummary(art)}',
        'Rune word added: ${custom.choiceEn}. ${runeArtFormulaSummary(art)}',
      );
      aggiungiLog(risultato);
    });
    programmaSalvataggio();
  }
}
