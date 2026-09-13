from pathlib import Path

root = Path(__file__).resolve().parents[1]
def read(name): return (root / name).read_text(encoding='utf-8')
def save(name, text): (root / name).write_text(text, encoding='utf-8')
def swap(text, old, new):
    assert old in text, old[:100]
    return text.replace(old, new, 1)

p='lib/src/main/oculum_home_combat_progression.dart'
s=read(p)
a=s.index('  int gradoAutomaticoDaLivello('); b=s.index('  void aggiornaGradoAutomatico()', a)
s=s[:a]+'''  int gradoAutomaticoDaLivello(int livello, bool rebirth) =>
      oculumGradeForLevel(livello, rebirth: rebirth);

'''+s[b:]
s=swap(s, '      final gradiGuadagnati = nuovoGrado - gradoAttuale;', '''      final gradiGuadagnati = nuovoGrado - gradoAttuale;
      if (isMostro()) {
        monsterStatPoints += gradiGuadagnati *
            oculumMonsterStatPointsPerGrade(tipoSchedaController.text);
      }''')
s=swap(s, 'final bonus = grado * 10;', 'final bonus = grado * oculumMonsterStatPointsPerGrade(tipoSchedaController.text);')
save(p,s)

p='lib/src/main/oculum_home_persistence.dart'; s=read(p)
s=s.replace('livello * oculumMonsterStatPointsPerLevel(tipo) + grado * 10', 'livello * oculumMonsterStatPointsPerLevel(tipo) + grado * oculumMonsterStatPointsPerGrade(tipo)')
a=s.index('  int suggestedQuickSheetGrade('); b=s.index('  List<',a)
s=s[:a]+'''  int quickMonsterStatBudget(String tipo, int livello, int grado) {
    if (!tipo.toLowerCase().contains('mostro')) return 0;
    return oculumGeneratedMonsterBudget(tipo, livello);
  }

  Map<String, int> randomQuickMonsterStats(
    int points, {String hint = '', bool hasSkills = true, bool hasOculumArt = false}
  ) => oculumDistributeMonsterStats(points,
      hasSkills: hasSkills, hasOculumArt: hasOculumArt, role: hint);

'''+s[b:]
s=swap(s, '''      final grado =
          gradoForzato ??
          (levelZeroPreset ? 0 : suggestedQuickSheetGrade(selectedType));''', '''      final grado = selectedType.toLowerCase().contains('mostro') || matchedMonster != null
          ? oculumGradeForLevel(livello)
          : (gradoForzato ?? max(0, leggiNumero(quickSheetGradeController)));''')
# Allocate once after all skills and Arts have been resolved, so no late Art
# assignment can strand a monster with zero Oculum.
needle='''        if (enemyProfile) {
          for (final skill in skills) {'''
s=swap(s, needle, '''        if (matchedMonster != null && matchedMonster.skillIds.isEmpty) {
          skills.clear();
          arti.clear();
        }
        if (selectedType.toLowerCase().contains('mostro') || matchedMonster != null) {
          final hasSkills = skills.isNotEmpty ||
              (matchedMonster?.skillIds.isNotEmpty ?? false) ||
              arti.any((art) => art.skills.isNotEmpty);
          final hasArt = arti.any((art) => art.tipo == 'Oculum Art' || art.tipo == 'Art Mostro');
          final allocated = statsMostroForzate ?? (usesFixedLevelZeroBase
              ? oculumMonsterCreationStats(matchedMonster!, livello)
              : oculumDistributeMonsterStats(monsterPointBudget,
                  hasSkills: hasSkills, hasOculumArt: hasArt,
                  role: '$kind $description'));
          final total = allocated.values.fold<int>(0, (sum, value) => sum + max(0, value));
          final requiresOculum = hasSkills || hasArt;
          final corrected = (requiresOculum && (allocated['oculum'] ?? 0) <= 0) ||
                  (!requiresOculum && (allocated['oculum'] ?? 0) > 0)
              ? oculumDistributeMonsterStats(max(requiresOculum ? 4 : 3, total),
                  hasSkills: hasSkills, hasOculumArt: hasArt, role: kind)
              : allocated;
          int assigned(String key) => max(0, ((corrected[key] ?? 0) * variantMultiplier).round());
          resilienzaController.text = '${assigned('resilienza')}';
          volontaController.text = '${assigned('volonta')}';
          materiaController.text = '${assigned('materia')}';
          oculumController.text = '${assigned('oculum')}';
          currentResilienzaController.text = resilienzaController.text;
          currentVolontaController.text = volontaController.text;
          currentMateriaController.text = materiaController.text;
          applyTemporaryOculumState(TemporaryOculumState(
            normalCurrent: assigned('oculum'), temporary: 0, rollsRemaining: 0));
          monsterStatPoints = 0;
        }

'''+needle)
save(p,s)

p='lib/src/main/oculum_home_rules_settings_search.dart'; s=read(p)
a=s.index('  Map<String, int> _tutorialMonsterStats('); b=s.index('  OculumTitle _tutorialMonsterRacialTrait',a)
s=s[:a]+'''  Map<String, int> _tutorialMonsterStats(MonsterBookEntry monster) =>
      oculumMonsterCreationStats(monster, _tutorialMonsterLevel(monster));

'''+s[b:]
s=swap(s,'final grado = min(gradoRichiesto, gradoMassimo);','final grado = tutorialGeneraMostro ? gradoMassimo : min(gradoRichiesto, gradoMassimo);')
s=s.replace('if (selectedMonster == null && puntiLivelloSpesi > puntiLibriDisponibili)', 'if (!tutorialGeneraMostro && puntiLivelloSpesi > puntiLibriDisponibili)')
s=s.replace('if (!isMonsterBookPreset && eMartial && extraOcu > 0)', 'if (!tutorialGeneraMostro && eMartial && extraOcu > 0)')
s=s.replace('''    final obserIniziale = switch (background.id) {''', '''    if (tutorialGeneraMostro) {
      final personalArts = arti.where((candidate) =>
          candidate.skills.isNotEmpty && candidate.tipo != 'Art Mostro' &&
          !oculumStarterArtChoices().any((starter) => starter.nome == candidate.nome));
      stats.addAll(selectedMonster != null
          ? _tutorialMonsterStats(selectedMonster)
          : oculumDistributeMonsterStats(
              max(3, oculumGeneratedMonsterBudget(tutorialMonsterTier, livello)),
              hasSkills: skills.isNotEmpty || personalArts.isNotEmpty,
              hasOculumArt: personalArts.any((candidate) => candidate.tipo == 'Oculum Art'),
              role: tutorialMonsterTier));
    }
    final obserIniziale = switch (background.id) {''',1)
s=s.replace("esistente.descrizione.startsWith('Peculiarità del Monster Book.')", "esistente.descrizione.startsWith('Peculiarità del Monster Book')")
s=s.replace("if (firstBaseIndex >= 0) {\n          arti[firstBaseIndex] = monsterArt;\n        } else {\n          arti.insert(0, monsterArt);\n        }", "if (selectedMonster.skillIds.isNotEmpty) {\n          if (firstBaseIndex >= 0) {\n            arti[firstBaseIndex] = monsterArt;\n          } else {\n            arti.insert(0, monsterArt);\n          }\n        }")
a=s.index('      monsterStatPoints = tutorialGeneraMostro'); b=s.index('      tutorialCompletato = true;',a)
s=s[:a]+'''      monsterStatPoints = 0;
      refullaHp();

'''+s[b:]
s=s.replace("${selectedMonster == null && tutorialMonsterStatsRandomized ? 'Punti distribuiti casualmente.' : 'Punti mostro disponibili: $monsterStatPoints.'}","Grado $grado calcolato dal livello. Statistiche assegnate in base alle Skill e alle Art.")
s=s.replace("hint: tutorialMonsterTier,", "hint: tutorialMonsterTier,\n                                  hasSkills: skills.isNotEmpty || arti.any((art) => art.skills.isNotEmpty),")
s=swap(s, '''                    campoTesto(
                      label: t('Grado iniziale', 'Starting grade'),
                      controller: tutorialGradeController,
                    ),''', '''                    if (!tutorialGeneraMostro)
                      campoTesto(
                        label: t('Grado iniziale', 'Starting grade'),
                        controller: tutorialGradeController,
                      )
                    else
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: tutorialLevelController,
                        builder: (context, value, _) => smallInfoText(
                          'Grado automatico: ${oculumGradeForLevel(max(0, int.tryParse(value.text) ?? 0))}. Per le forme del Book si usa il loro livello.'),
                      ),''')
s=s.replace('Budget attuale: 9 × livello + 10 × grado.', 'Grado dal livello: +10 punti per Mostro, +15 per Mini-Boss, +25 per Boss a ogni Grado. Le Skill e le Oculum Art ricevono una riserva di Oculum; senza entrambe i punti vanno a RES, VOL e MAT.')
save(p,s)
