part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

String oculumRecognizedArtKind(CharacterArt art) {
  final text = oculumNormalizeText('${art.tipo} ${art.nome}');
  for (final kind in [
    'defiled',
    'illness',
    'emblem',
    'martial',
    'rune',
    'null',
  ]) {
    if (text.contains(kind)) return kind;
  }
  return 'oculum';
}

String oculumNextArtSwitchPhase(String phase) => switch (phase) {
  'visione' => 'risveglio',
  'risveglio' => '',
  _ => phase,
};

extension _OculumArtLoadout on _OculumHomePageState {
  void changeArtAvailability(CharacterArt art, VoidCallback change) {
    final wasActive = art.sbloccata && art.inUso;
    change();
    final active = art.sbloccata && art.inUso;
    if (wasActive != active) {
      for (final skill in art.skills) {
        applicaBonusArtSkillAttuali(
          skill,
          artSkillBonusLevel(skill) * (active ? 1 : -1),
          notifyHiddenEyeCards: false,
        );
      }
      if (active) {
        for (final skill in art.skills.where((skill) =>
            skill.tipoPerLivello(1).toLowerCase().contains('passiv'))) {
          final passiveEffects = skill.effettiEvoluzione(1);
          if (passiveEffects.isNotEmpty) {
            applyStructuredEffectsOnActivation(
              passiveEffects,
              source: '${art.nome} / ${skill.nome} (passiva)',
              level: 1,
            );
          }
        }
      } else {
        removeActiveStructuredEffectsForSourcePrefix('${art.nome} /');
      }
    }
  }

  String effectiveArtCostResource(
    CharacterArt art,
    ArtSkill skill,
    int level,
  ) => switch (oculumRecognizedArtKind(art)) {
    'emblem' => 'nessuna',
    'illness' => 'follia',
    _ => skill.risorsaCostoPerLivello(level),
  };

  void advanceArtSwitchTurn() {
    artSwitchActionDebt = max(0, artSwitchActionDebt - 1);
    artSwitchReactionDebt = max(
      0,
      artSwitchReactionDebt - max(1, leggiNumero(reazioniController)),
    );
    for (final art in arti) {
      changeArtAvailability(
        art,
        () => art.switchPhase = oculumNextArtSwitchPhase(art.switchPhase),
      );
    }
    invalidateDerivedDataCaches();
  }

  void advanceArtSwitchForToken(Map<String, dynamic> token) {
    final tag = '${token['sheetTag'] ?? token['id'] ?? ''}';
    final index = schedePersonaggio.indexWhere(
      (sheet) => '${sheet['sheetTag'] ?? sheet['id'] ?? ''}' == tag,
    );
    if (index < 0) return;
    if (index == schedaCorrente) {
      advanceArtSwitchTurn();
      return;
    }
    final sheet = schedePersonaggio[index];
    sheet['artSwitchActionDebt'] = max(
      0,
      readIntValue(sheet['artSwitchActionDebt']) - 1,
    );
    sheet['artSwitchReactionDebt'] = max(
      0,
      readIntValue(sheet['artSwitchReactionDebt']) -
          max(1, readIntValue(sheet['reazioni'])),
    );
    for (final raw in (sheet['arti'] as List? ?? [])) {
      if (raw is! Map) continue;
      final oldPhase = '${raw['switchPhase'] ?? ''}';
      raw['switchPhase'] = oculumNextArtSwitchPhase(oldPhase);
      if (oldPhase == 'visione' &&
          raw['incorporata'] != true &&
          raw['sbloccata'] != false) {
        for (final skill in (raw['skills'] as List? ?? const [])) {
          if (skill is! Map) continue;
          final level = readIntValue(skill['livello']);
          for (final stat in ['resilienza', 'volonta', 'materia', 'oculum']) {
            final key = 'current${stat[0].toUpperCase()}${stat.substring(1)}';
            final delta = readIntValue(skill[stat]) * level;
            if (delta != 0) sheet[key] = '${readIntValue(sheet[key]) + delta}';
          }
        }
      }
    }
  }

  int artDebtForToken(Map<String, dynamic> token, String resource) {
    final tag = '${token['sheetTag'] ?? token['id'] ?? ''}';
    final index = schedePersonaggio.indexWhere(
      (sheet) => '${sheet['sheetTag'] ?? sheet['id'] ?? ''}' == tag,
    );
    if (index >= 0 && index == schedaCorrente) {
      return resource == 'action' ? artSwitchActionDebt : artSwitchReactionDebt;
    }
    if (index < 0) return 0;
    return readIntValue(
      schedePersonaggio[index][resource == 'action'
          ? 'artSwitchActionDebt'
          : 'artSwitchReactionDebt'],
    );
  }

  void interruptArtAwakening() {
    for (final art in arti) {
      if (art.switchPhase == 'risveglio') {
        art.switchPhase = 'interrotto';
        aggiungiLog(
          'Risveglio interrotto: ${art.nome}. Occorre un nuovo turno senza essere colpito.',
        );
      }
    }
  }

  void selectIncorporatedArt(CharacterArt target) {
    if (!target.sbloccata) return;
    setState(() {
      for (final art in arti) {
        if (!identical(art, target)) {
          changeArtAvailability(art, () {
            art.incorporata = true;
            art.switchPhase = '';
            art.openAttiva = false;
          });
        }
      }
      final wasActive = target.inUso;
      target.incorporata = false;
      final kind = oculumRecognizedArtKind(target);
      if (kind == 'illness') {
        artSwitchActionDebt += 1;
        artSwitchReactionDebt += 2;
        target.switchPhase = '';
      } else if (['martial', 'defiled', 'emblem'].contains(kind)) {
        target.switchPhase = '';
      } else {
        artSwitchActionDebt += 1;
        target.switchPhase = 'visione';
      }
      if (wasActive != target.inUso) {
        for (final skill in target.skills) {
          applicaBonusArtSkillAttuali(
            skill,
            artSkillBonusLevel(skill) * (target.inUso ? 1 : -1),
            notifyHiddenEyeCards: false,
          );
        }
      }
      invalidateDerivedDataCaches();
      risultato =
          'Art selezionata: ${target.nome}. ${artSwitchExplanation(target)}';
      aggiungiLog(risultato);
    });
    programmaSalvataggio();
  }

  String artSwitchExplanation(
    CharacterArt art,
  ) => switch (oculumRecognizedArtKind(art)) {
    'illness' =>
      'Cambio: −1 azione e −2 reazioni, anche sotto zero. Recupero nei turni successivi. Selezionata: +5 a tutte le statistiche. Le Skill spendono Follia.',
    'emblem' =>
      'Cambio istantaneo. Le Skill usano solo cooldown. Ogni Emblem incorporata dopo la prima dona +3 Volontà e +2 Materia, anche se non in uso.',
    'defiled' =>
      'Cambio istantaneo. Cinque evoluzioni: I / II / III / IV / V. Costi configurabili: Obser, oggetti e statistiche.',
    'martial' => 'Cambio istantaneo.',
    _ =>
      'Cambio: 1 azione senza vedere dall’occhio o dagli occhi coinvolti. Al turno seguente torna la visione; serve poi un intero turno senza essere colpito per attingere al potere risvegliato.',
  };

  Widget artLoadoutPanel() => gothicPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionTitle('Art incorporate e cambio Art'),
        Text(
          'Azioni disponibili: ${1 - artSwitchActionDebt} · Reazioni disponibili: ${leggiNumero(reazioniController) - artSwitchReactionDebt}',
        ),
        for (final art in arti.where((art) => art.sbloccata))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${art.nome} · ${art.incorporata ? 'Incorporata, non in uso' : 'Selezionata'}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (art.incorporata)
                      OutlinedButton(
                        onPressed: () => selectIncorporatedArt(art),
                        child: const Text('Seleziona Art'),
                      ),
                    if (art.incorporata)
                      TextButton(
                        onPressed: () => openReferenceDetail(
                          'Art incorporata · ${art.nome}',
                          'incorporated_art_${arti.indexOf(art)}',
                          () => Column(
                            children: [
                              artDataPanel(arti.indexOf(art)),
                              artFormsPanel(arti.indexOf(art)),
                            ],
                          ),
                        ),
                        child: const Text('Modifica Art incorporata'),
                      ),
                    if (!art.incorporata)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            changeArtAvailability(art, () {
                              art.incorporata = true;
                              art.openAttiva = false;
                              art.switchPhase = '';
                            });
                            invalidateDerivedDataCaches();
                          });
                          programmaSalvataggio();
                        },
                        child: const Text('Metti tra le non usate'),
                      ),
                  ],
                ),
                Text(artSwitchExplanation(art)),
                if (oculumRecognizedArtKind(art) == 'oculum')
                  campoModello(
                    label: 'Occhio / occhi coinvolti',
                    initialValue: art.occhiCoinvolti,
                    keyboardType: TextInputType.text,
                    onChanged: (value) => art.occhiCoinvolti = value,
                  ),
                if (art.switchPhase.isNotEmpty)
                  Text(
                    art.switchPhase == 'visione'
                        ? 'Visione sospesa: ${art.occhiCoinvolti.isEmpty ? 'occhi dell’Art' : art.occhiCoinvolti}.'
                        : art.switchPhase == 'risveglio'
                        ? 'Risveglio: termina il turno senza essere colpito.'
                        : 'Risveglio interrotto.',
                  ),
                if (art.switchPhase == 'interrotto')
                  TextButton(
                    onPressed: () {
                      setState(() => art.switchPhase = 'risveglio');
                      programmaSalvataggio();
                    },
                    child: const Text('Inizia nuovo turno di risveglio'),
                  ),
              ],
            ),
          ),
        OutlinedButton.icon(
          onPressed: addIncorporatedArt,
          icon: const Icon(Icons.add),
          label: const Text('Incorpora un’altra Art'),
        ),
      ],
    ),
  );

  Future<void> addIncorporatedArt() async {
    var name = '';
    var kind = 'emblem';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: const Text('Incorpora Art'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Nome Art'),
                onChanged: (value) => name = value,
              ),
              DropdownButtonFormField<String>(
                initialValue: kind,
                items: [
                  for (final value in [
                    'oculum',
                    'martial',
                    'defiled',
                    'illness',
                    'emblem',
                    'rune',
                    'null',
                  ])
                    DropdownMenuItem(value: value, child: Text('$value Art')),
                ],
                onChanged: (value) => update(() => kind = value ?? kind),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annulla'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Incorpora'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted || name.trim().isEmpty) return;
    setState(() {
      arti.add(
        CharacterArt(
          nome: name.trim(),
          tipo: kind,
          descrizione: '',
          incorporata: true,
          hasIntegrity: kind != 'emblem',
          skills: List.generate(
            3,
            (i) => ArtSkill(
              nome: 'Skill ${i + 1}',
              risorseCostoPerLivello: List.filled(
                5,
                kind == 'illness'
                    ? 'follia'
                    : kind == 'emblem'
                    ? 'nessuna'
                    : 'oculum',
              ),
              cooldownPerLivello: List.generate(
                5,
                (_) => OculumAbilityCooldown(amount: kind == 'emblem' ? 1 : 0),
              ),
            ),
          ),
        ),
      );
      invalidateDerivedDataCaches();
    });
    programmaSalvataggio();
  }
}
