from pathlib import Path
p=Path('lib/src/main/oculum_home_persistence.dart'); s=p.read_text(encoding='utf-8')
s=s.replace('''        if (generatedArt != null) {
          arti''','''        if (generatedArt != null) {
          if (selectedType.toLowerCase().contains('mostro') || matchedMonster != null) {
            oculumCompleteMonsterOpen(generatedArt, name: kind, level: livello, grade: grado);
          }
          arti''')
p.write_text(s,encoding='utf-8')
p=Path('lib/src/main/oculum_home_rules_settings_search.dart'); s=p.read_text(encoding='utf-8')
s=s.replace('final monsterArt = _tutorialMonsterArt(selectedMonster, livello);', '''final monsterArt = oculumCompleteMonsterOpen(
          _tutorialMonsterArt(selectedMonster, livello),
          name: selectedMonster.nameIt, level: livello, grade: grado);''')
p.write_text(s,encoding='utf-8')
p=Path('lib/src/main/oculum_home_secondary_pages.dart'); s=p.read_text(encoding='utf-8')
s=s.replace('?targetArt.openSkillCooldown,', 'if (!targetArt.monsterOpenSkill) ?targetArt.openSkillCooldown,')
s=s.replace('art.openSkillCooldown?.activate();', 'if (!art.monsterOpenSkill) art.openSkillCooldown?.activate();')
s=s.replace('''            ...art.openSkillEffects,
            ...art.openBuffEffects,''','''            if (!art.monsterOpenSkill) ...art.openSkillEffects,
            ...art.openBuffEffects,''')
pos=s.index('  Widget artQuickCommandChips(')
s=s[:pos]+'''  void usaSkillOpenMostro(int artIndex) {
    if (artIndex < 0 || artIndex >= arti.length) return;
    final art = arti[artIndex];
    if (!art.monsterOpenSkill || !art.sbloccata || !art.openAttiva || !artOpenSbloccata(art)) return;
    final cooldown = art.openSkillCooldown;
    if (cooldown != null && !cooldown.ready) return;
    setState(() {
      cooldown?.activate();
      final messages = applyStructuredEffectsOnActivation(art.openSkillEffects,
          source: '${artOpenDisplayName(art, artIndex)} · Skill Open');
      risultato = '${art.openSkill}\\n${messages.join('\\n')}';
      aggiungiLog(risultato);
      invalidateDerivedDataCaches();
    });
    programmaSalvataggio();
    scheduleRealtimeOculumChanged();
  }

'''+s[pos:]
needle='''            structuredCooldownEditor(
              cooldown: art.openSkillCooldown,'''
s=s.replace(needle,'''            if (art.monsterOpenSkill) ...[
              FilledButton.icon(
                onPressed: art.sbloccata && art.openAttiva && artOpenSbloccata(art) && (art.openSkillCooldown?.ready ?? true)
                    ? () => usaSkillOpenMostro(artIndex) : null,
                icon: const Icon(Icons.flash_on), label: const Text('Usa Skill Open'),
              ),
              Text(!art.openAttiva ? 'Attiva prima l’Open.'
                  : !(art.openSkillCooldown?.ready ?? true)
                  ? 'Recupero: ${art.openSkillCooldown!.remaining} ${art.openSkillCooldown!.unit}.'
                  : 'Skill pronta. Il cooldown parte quando la usi.'),
            ],
'''+needle)
s=s.replace('if (dialogContext.mounted)\n                            Navigator.pop(dialogContext);', 'if (dialogContext.mounted) { Navigator.pop(dialogContext); }')
p.write_text(s,encoding='utf-8')
