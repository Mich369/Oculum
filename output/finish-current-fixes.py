from pathlib import Path
p=Path('lib/src/main/oculum_reference_sheet.dart');s=p.read_text(encoding='utf-8').replace("if (id == selectedIncomingDamageElement())\n                          dannoSubitoPercentController.clear();", "if (id == selectedIncomingDamageElement()) {\n                          dannoSubitoPercentController.clear();\n                        }")
# Do not progress an Art twice per full personal turn.
s=s.replace('setPlayerReportedTurn(next, broadcast: false);','setPlayerReportedTurn(next, broadcast: false, advanceArt: false);')
p.write_text(s,encoding='utf-8')
p=Path('lib/src/main/oculum_home_combat_progression.dart');s=p.read_text(encoding='utf-8');s=s.replace('void setPlayerReportedTurn(int value, {bool broadcast = true})', 'void setPlayerReportedTurn(int value, {bool broadcast = true, bool advanceArt = true})');s=s.replace('        advanceArtSwitchTurn();\n        processConditionTick', '        if (advanceArt) advanceArtSwitchTurn();\n        processConditionTick',1)
# Stored sheets share resets so changing the open sheet cannot restore stale counters.
s=s.replace("token['reportedTurn'] = 0;\n        }", "token['reportedTurn'] = 0;\n          final tag = '${token['sheetTag'] ?? token['id'] ?? ''}';\n          final sheet = schedePersonaggio.where((s) => s['sheetTag'] == tag).firstOrNull;\n          if (sheet != null) sheet['playerReportedTurn'] = 0;\n        }")
p.write_text(s,encoding='utf-8')
p=Path('lib/src/main/oculum_performance_probe.dart');s=p.read_text(encoding='utf-8');s=s.replace('  Map<String, dynamic> snapshot()', '''  Widget resistancePanel() => _state.resistanceDetailsPanel();
  Widget subtraitsPanel() => _state.referenceSubtraitsPanel();
  void resetEncounter() => _state.resetMasterInitiativeRound();
  void reportedTurn(int value) => _state.setPlayerReportedTurn(value, broadcast: false);
  void removeParticipant(int index) => _state.removeMasterInitiativeTokenAt(index);
  void damage(int amount) => _state.applicaDannoSubito(dannoEsplicito: amount);
  String activateForce(String id) { _state.statoForzaAttivo = id; return _state.applicaEffettoImmediatoStatoForza(id); }
  void endForce() => _state.terminaStatoForzaAttivo(applicaEsitoEsplosione: false);
  int currentHp() => _state.hpCorrenti();
  Map<String, int> coreStats() => {'resilienza': _state.resilienzaTotale(), 'volonta': _state.volontaTotale(), 'materia': _state.materiaTotale(), 'oculum': _state.oculumTotale()};
  Map<String, dynamic> snapshot()''');p.write_text(s,encoding='utf-8')
