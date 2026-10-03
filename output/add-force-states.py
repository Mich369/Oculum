from pathlib import Path
p=Path('lib/src/main/oculum_home_force_state.dart');s=p.read_text(encoding='utf-8');pos=s.index('    _StatoForzaDef(\n      id: \'vero_bruciore_anima\'');s=s[:pos]+'''    _StatoForzaDef(id: 'ricordo_vitale', nameIt: 'Ricordo vitale', nameEn: 'Vital Memory',
      descriptionIt: 'Molto raro: recuperi il 75% della Vita massima e ottieni Ricordo Vitale per 9 tuoi turni. La cura non viene sottratta alla scadenza.',
      descriptionEn: 'Very rare: restore 75% of maximum HP and gain Vital Memory for 9 personal turns. Healing is retained after expiry.', weight: 1),
    _StatoForzaDef(id: 'duecento_percento', nameIt: '200%', nameEn: '200%',
      descriptionIt: 'Raddoppia Resilienza, Volontà, Materia e Oculum per 3 tuoi turni, usando i valori all’attivazione. Non accumulabile. La scadenza non può ucciderti.',
      descriptionEn: 'Doubles Resilience, Will, Matter and Oculum for 3 personal turns, using activation values. Does not stack. Expiry cannot kill you.', weight: 3),
'''+s[pos:]
s=s.replace("    switch (id) {\n      case 'corpo_non_mollare':", """    switch (id) {
      case 'ricordo_vitale':
        if (activeStructuredEffects.any((e) => e['source'] == 'Stato di Forza: Ricordo vitale')) return 'Già attivo: nessuna cura aggiuntiva.';
        final recovered = (maxHp() * 3 / 4).ceil();
        currentHpController.text = min(maxHp(), hpCorrenti() + recovered).toString();
        applyCondition('ricordo_vitale', duration: 9, source: 'Stato di Forza: Ricordo vitale');
        activeStructuredEffects.add({'source': 'Stato di Forza: Ricordo vitale', 'target': 'durata_stato', 'type': 'bonus', 'value': 0, 'remaining': 9, 'unit': 'turni'});
        invalidateDerivedDataCaches();
        return 'Cura +$recovered HP, entro il massimo. Ricordo Vitale: 9 turni personali.';
      case 'duecento_percento':
        if (activeStructuredEffects.any((e) => e['source'] == 'Stato di Forza: 200%')) return '200% già attivo.';
        final values = {'resilienza': resilienzaTotale(), 'volonta': volontaTotale(), 'materia': materiaTotale(), 'oculum': oculumTotale()};
        for (final entry in values.entries) {
          activeStructuredEffects.add({'source': 'Stato di Forza: 200%', 'target': entry.key, 'type': 'bonus', 'value': max(0, entry.value), 'remaining': 3, 'unit': 'turni'});
        }
        invalidateDerivedDataCaches();
        return 'Statistiche raddoppiate per 3 turni personali.';
      case 'corpo_non_mollare':""")
s=s.replace("    final active = statoForzaAttivo;\n    statoForzaAttivo = '';", """    final active = statoForzaAttivo;
    final hpBeforeBuffRemoval = hpCorrenti();
    if (active == 'ricordo_vitale' || active == 'duecento_percento') {
      final source = active == 'ricordo_vitale' ? 'Stato di Forza: Ricordo vitale' : 'Stato di Forza: 200%';
      activeStructuredEffects.removeWhere((e) => e['source'] == source);
      if (active == 'ricordo_vitale') {
        final condition = getCondition('ricordo_vitale');
        if (condition?.source == source) removeCondition(condition!, force: true);
      }
    }
    statoForzaAttivo = '';
    invalidateDerivedDataCaches();
    preserveLivingHpAfterBuffRemoval(hpBeforeBuffRemoval);""")
s=s.replace('    if (hp > soglia) {', "    if ((statoForzaAttivo == 'ricordo_vitale' || statoForzaAttivo == 'duecento_percento') && activeStructuredEffects.any((e) => '${e['source']}'.startsWith('Stato di Forza:'))) return;\n    if (hp > soglia) {")
p.write_text(s,encoding='utf-8')
p=Path('lib/src/main/oculum_structured_effect_runtime.dart');s=p.read_text(encoding='utf-8');s=s.replace('    final before = activeStructuredEffects.length;','    final hpBeforeBuffRemoval = hpCorrenti();\n    final before = activeStructuredEffects.length;',1).replace('    scheduleHiddenEyeDerivedCardsRefresh();\n    return true;', '    preserveLivingHpAfterBuffRemoval(hpBeforeBuffRemoval);\n    scheduleHiddenEyeDerivedCardsRefresh();\n    return true;',1)
s=s.replace('    final normalizedUnit = oculumTurnUnit(unit);','    final hpBeforeBuffRemoval = hpCorrenti();\n    final normalizedUnit = oculumTurnUnit(unit);')
s=s.replace('      scheduleHiddenEyeDerivedCardsRefresh();\n    }\n    return changed;', """      preserveLivingHpAfterBuffRemoval(hpBeforeBuffRemoval);
      if ((statoForzaAttivo == 'ricordo_vitale' || statoForzaAttivo == 'duecento_percento') && !activeStructuredEffects.any((e) => '${e['source']}'.startsWith('Stato di Forza:'))) terminaStatoForzaAttivo(applicaEsitoEsplosione: false);
      scheduleHiddenEyeDerivedCardsRefresh();
    }
    return changed;""",1)
s=s.replace('  String normalizedStructuredTarget(String raw) {', """  void preserveLivingHpAfterBuffRemoval(int hpBefore) {
    if (hpBefore <= 0) return;
    currentHpController.text = max(1, min(leggiNumero(currentHpController), maxHp())).toString();
  }

  String normalizedStructuredTarget(String raw) {""")
p.write_text(s,encoding='utf-8')
# Same-turn manual correction must tick live effects once, not just replace UI counter.
p=Path('lib/src/main/oculum_home_combat_progression.dart');s=p.read_text(encoding='utf-8');a=s.index('  void setMasterTokenReportedTurn(');b=s.index('\n  int activeCriticalLevel()',a);section=s[a:b];section=section.replace('    setState(() {', "    if ('${token['sheetTag'] ?? token['id'] ?? ''}' == sheetTagAt(schedaCorrente)) {\n      setPlayerReportedTurn(safe, broadcast: false);\n    }\n    setState(() {",1);s=s[:a]+section+s[b:];p.write_text(s,encoding='utf-8')
# Notify the open starter allocation route immediately.
p=Path('lib/src/main/oculum_home_sheet_page.dart');s=p.read_text(encoding='utf-8');s=s.replace('      tutorialSubtraitPoints\n        ..clear()', '      notifyActiveSheetSummaryChanged();\n      tutorialSubtraitPoints\n        ..clear()',1);p.write_text(s,encoding='utf-8')
