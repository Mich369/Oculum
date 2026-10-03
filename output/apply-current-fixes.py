from pathlib import Path
root=Path('.')
def edit(p,a,b,n=1):
 s=(root/p).read_text(encoding='utf-8'); assert a in s,(p,a[:90]); (root/p).write_text(s.replace(a,b,n),encoding='utf-8')
main='lib/main.dart'
edit(main,"  final cmRapidoController =", "  final vcRapidoController = TextEditingController(text: '0');\n  final cmRapidoController =")
edit(main,'    cmRapidoController.dispose();','    vcRapidoController.dispose();\n    cmRapidoController.dispose();')
edit(main,"  final Map<String, String> dannoSubitoPercentPerTipo", "  String incomingDamageElement = '';\n  final Map<String, String> incomingDamagePresets = {};\n  int assignableSubtraitPoints = 0;\n  final Map<String, String> dannoSubitoPercentPerTipo")
p='lib/src/main/oculum_home_persistence.dart'
edit(p,"      'cmRapido': cmRapidoController.text,", "      'cmRapido': cmRapidoController.text,\n      'vcRapido': vcRapidoController.text,\n      'incomingDamageElement': incomingDamageElement,\n      'incomingDamagePresets': Map<String, String>.from(incomingDamagePresets),\n      'assignableSubtraitPoints': assignableSubtraitPoints,")
edit(p,"    cmRapidoController.text = '${json['cmRapido'] ?? '0'}';", "    cmRapidoController.text = '${json['cmRapido'] ?? '0'}';\n    vcRapidoController.text = '${json['vcRapido'] ?? '0'}';\n    incomingDamageElement = '${json['incomingDamageElement'] ?? ''}';\n    assignableSubtraitPoints = max(0, readIntValue(json['assignableSubtraitPoints']));\n    incomingDamagePresets..clear()..addAll(\n      (json['incomingDamagePresets'] is Map ? Map<String, dynamic>.from(json['incomingDamagePresets'] as Map) : <String, dynamic>{}).map((key,value) => MapEntry(oculumNormalizeElementId(key), canonicalDamageModifierName('$value')))\n    );\n    modificatoreDannoSelezionato = 'Normale';")
p='lib/src/main/oculum_home_calculations.dart'
edit(p,'    return bonusLivelloGrado() +\n        (volontaTotale() ~/ 3) +','    return bonusLivelloGrado() +\n        leggiNumero(vcRapidoController) +\n        (volontaTotale() ~/ 3) +')
edit(p,'livelloGrado + (vol ~/ 3) + malusFatica + vantaggio','livelloGrado + (vol ~/ 3) + leggiNumero(vcRapidoController) + malusFatica + vantaggio',-1)
p='lib/src/main/oculum_home_dialogs_quick_edit.dart'
edit(p,"          OculumQuickEditEntry(\n            label: t('Bonus CM', 'CM Bonus'),", "          OculumQuickEditEntry(label: 'Bonus VC', controller: vcRapidoController),\n          OculumQuickEditEntry(\n            label: t('Bonus CM', 'CM Bonus'),")
edit(p,"                      quickField(\n                        t('Bonus CM', 'CM Bonus'),", "                      quickField('Bonus VC', vcRapidoController, allowNegative: true),\n                      SizedBox(height: compact ? 6 : 10),\n                      quickField(\n                        t('Bonus CM', 'CM Bonus'),")
p='lib/src/main/oculum_reference_sheet.dart'
start=(root/p).read_text(encoding='utf-8'); a=start.index('            compactNumericEditField('); b=start.index('\n          ],',a)
start=start[:a]+"""            for (final entry in <(String, TextEditingController)>[
              ('Bonus danno', attaccoRapidoController),
              ('Bonus VC', vcRapidoController),
              ('Bonus CM', cmRapidoController),
              ('Bonus difesa', difesaRapidaController),
            ]) Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: campoTesto(label: entry.$1, controller: entry.$2),
            ),"""+start[b:]; (root/p).write_text(start,encoding='utf-8')
edit(p,"          sectionTitle(t('Sottotratti', 'Subtraits')),", """          sectionTitle(t('Sottotratti', 'Subtraits')),
          if (oculumStarterSubtraitPointsRemaining(appliedTutorialSubtraitPoints) > 0)
            OutlinedButton.icon(onPressed: showStarterSubtraitPointsDialog,
              icon: const Icon(Icons.add_circle_outline),
              label: Text('Punti iniziali disponibili: ${oculumStarterSubtraitPointsRemaining(appliedTutorialSubtraitPoints)} · massimo 3 per sottotratto')),
          if (assignableSubtraitPoints > 0) ...[
            Text('Punti da assegnare: $assignableSubtraitPoints'),
            for (final stat in hiddenEyeStats.where((s) => s.id != 'fortuna'))
              ListTile(title: Text(stat.nome), trailing: IconButton(
                tooltip: 'Assegna un punto', icon: const Icon(Icons.add),
                onPressed: () { setState(() { stat.valore++; assignableSubtraitPoints--; });
                  notifyHiddenEyeStatChanged(stat); programmaSalvataggio(); notifyActiveSheetSummaryChanged(); },)),
          ],
          if (haPermessiMaster) TextButton.icon(
            onPressed: () async {
              final controller = TextEditingController(text: '0');
              final amount = await showDialog<int>(context: context, builder: (ctx) => AlertDialog(
                title: const Text('Assegna punti sottotratti'),
                content: TextField(controller: controller, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Punti concessi dal Master')),
                actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla')),
                  FilledButton(onPressed: () => Navigator.pop(ctx, max(0, readIntValue(controller.text))), child: const Text('Aggiungi'))],));
              if (amount != null && mounted) { setState(() => assignableSubtraitPoints += amount); programmaSalvataggio(); notifyActiveSheetSummaryChanged(); }
              WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());
            }, icon: const Icon(Icons.stars_outlined), label: const Text('Concedi punti')),
""")
edit(p,'                  OutlinedButton(\n                    onPressed: () => tiraSottotrattoOcchio(stat),',"""                  Tooltip(
                    richMessage: TextSpan(children: [
                      TextSpan(text: '${stat.nome} — A cosa serve\\n', style: const TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: '${stat.descrizione.split('Bonus:').first.trim()}\\n\\n'),
                      const TextSpan(text: 'Formula\\n', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: subtraitFormulaHelp(stat)),
                    ]),
                    triggerMode: TooltipTriggerMode.longPress,
                    child: OutlinedButton(
                    onPressed: () => tiraSottotrattoOcchio(stat),""")
edit(p,"${hiddenEyeTotal(stat)}',\n                    ),\n                  ),", "${hiddenEyeTotal(stat)}',\n                    ),\n                  )),")
# Tiny reset wrapper used by both turn controls.
edit(p,'          Text(\n            hasFight', '          turnResetGesture(Text(\n            hasFight')
edit(p,"                : 'Turno $playerReportedTurn',\n          ),", "                : 'Turno $playerReportedTurn',\n          )),")
edit(p,"fallback: 1)","fallback: 0)")
# remove permission: Master any, Player only own local tag
edit(p,"                              title: Text('${token['name'] ?? \"???\"}'),", """                              title: Text('${token['name'] ?? "???"}'),
                              trailing: (haPermessiMaster || '${token['sheetTag'] ?? token['id'] ?? ''}' == sheetTagAt(schedaCorrente))
                                ? IconButton(tooltip: 'Esci dallo scontro', icon: const Icon(Icons.person_remove_outlined),
                                  onPressed: () => removeReferenceEncounterMember(id, token, local: local)) : null,""")
edit(p,"group['round'] ?? 1", "group['round'] ?? 0")
# mobile access next to diary
edit(p,"                    label: Text(t('Diario', 'Diary')),\n                  ),", """                    label: Text(t('Diario', 'Diary')),
                  ),
                  TextButton.icon(onPressed: openResistanceDetails, icon: const Icon(Icons.shield_outlined), label: const Text('Resistenze')),""")
p='lib/src/main/oculum_reference_campaign.dart'
edit(p,"        () => vaiAllaFunzione(page: 5),\n      ),\n    ];", "        () => vaiAllaFunzione(page: 5),\n      ),\n      ('Resistenze', Icons.shield_outlined, false, openResistanceDetails),\n    ];")
p='lib/src/main/oculum_home_sheet_page.dart'
edit(p,'          impactOptionsPanel(),\n          const SizedBox(height: 10),','',1)
edit(p,"  Widget damageHealPanel() {", "  Widget damageHealPanel() {")
s=(root/p).read_text(encoding='utf-8');pos=s.index('  Widget damageHealPanel()');idx=s.index('        children: [',pos)+len('        children: [');s=s[:idx]+ '\n          impactOptionsPanel(),\n          const SizedBox(height: 12),\n          incomingElementSelector(),'+s[idx:];(root/p).write_text(s,encoding='utf-8')
# Incoming damage is selected independently from outgoing weapon.
p='lib/src/main/oculum_home_combat_progression.dart'
edit(p,'final canonical = canonicalDamageModifierName(modificatoreDannoSelezionato);', 'final canonical = configuredIncomingDamagePreset();')
edit(p,'final activePercentDamageType = elementoDannoDominante()', 'final activePercentDamageType = selectedIncomingDamageElement()')
edit(p,'final modificatorePrima = modificatoreDannoSelezionato;', 'final modificatorePrima = configuredIncomingDamagePreset();')
edit(p,'final elementoAttivo = elementoDannoDominante();', 'final elementoAttivo = selectedIncomingDamageElement();')
edit(p,'modificatoreDannoSelezionato = modificatoreDopo;', 'incomingDamagePresets[activePercentDamageType] = modificatoreDopo;',-1)
# keep custom percent legacy fallback only with no preset configuration
edit(p,'if (dannoSubitoPercentPerTipo.isEmpty) {', 'if (dannoSubitoPercentPerTipo.isEmpty && incomingDamagePresets.isEmpty) {')
p='lib/src/main/oculum_home_colors_and_base_widgets.dart'
edit(p,'modificatoreDannoSelezionato,','configuredIncomingDamagePreset(),')
edit(p,"                    dannoSubitoPercentController.clear();", "                    incomingDamagePresets[selectedIncomingDamageElement()] = modificatoreDannoSelezionato;\n                    dannoSubitoPercentController.clear();")
edit(p,"elementoDannoDominante().trim().toLowerCase(),", "selectedIncomingDamageElement(),")
edit(p,'final safeValue = canonicalDamageModifierName(modificatoreDannoSelezionato);','final safeValue = configuredIncomingDamagePreset();')
edit(p,'final activeDamageType = elementoDannoDominante().trim().toLowerCase();','final activeDamageType = selectedIncomingDamageElement();')
edit(p,'elementDisplayName(elementoDannoDominante())}', 'elementDisplayName(selectedIncomingDamageElement())}')
# reset true 0; per-owner count increases at END of their turn, no other participant.
p='lib/src/main/oculum_home_combat_progression.dart'
edit(p,'      if (increment) masterInitiativeRound++;', "      if (increment) { masterInitiativeRound++; } else { masterInitiativeRound = 0; playerReportedTurn = 0; for (final token in masterInitiativeTokens) { token['reportedTurn'] = 0; } }")
edit(p,"      if (masterInitiativeTokenCanAct(masterInitiativeTokens[current])) {", "      if (delta > 0) advanceEncounterParticipantTurn(current);\n      if (masterInitiativeTokenCanAct(masterInitiativeTokens[current])) {")
edit(p,'    applyAutomaticAshForTurnProgress(previous, safe);', '    applyAutomaticAshForTurnProgress(previous, safe);\n    notifyActiveSheetSummaryChanged();')
p='lib/src/main/oculum_home_secondary_pages.dart'
edit(p,"                child: Text(\n                  '${t('Iniziativa Master', 'Master Initiative')}", "                child: turnResetGesture(Text(\n                  '${t('Iniziativa Master', 'Master Initiative')}")
edit(p,"fontSize: compact ? 17 : 22,\n                    fontWeight: FontWeight.w900,\n                  ),\n                ),", "fontSize: compact ? 17 : 22,\n                    fontWeight: FontWeight.w900,\n                  ),\n                )),")
