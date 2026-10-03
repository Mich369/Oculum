from pathlib import Path
p=Path('lib/src/main/oculum_reference_sheet.dart')
s=p.read_text(encoding='utf-8')
s += r'''

extension _OculumReferenceResistanceDetails on _OculumHomePageState {
  String selectedIncomingDamageElement() => oculumNormalizeElementId(
    incomingDamageElement.isEmpty ? elementoDannoDominante() : incomingDamageElement);

  String configuredIncomingDamagePreset([String? element]) =>
    canonicalDamageModifierName(incomingDamagePresets[element ?? selectedIncomingDamageElement()] ?? 'Normale');

  void openResistanceDetails() => openReferenceDetail('Resistenze', 'sheet_resistances', resistanceDetailsPanel);

  Widget incomingElementSelector() {
    final selected = selectedIncomingDamageElement();
    final ids = {...allDamageElementIds(), if (selected.isNotEmpty) selected}.toList();
    return DropdownButtonFormField<String>(
      key: ValueKey('incoming_element_$selected'), initialValue: ids.contains(selected) ? selected : ids.first,
      isExpanded: true, decoration: fieldDecoration('Elemento del danno ricevuto'),
      items: [for (final id in ids) DropdownMenuItem(value: id, child: Text(elementDisplayName(id)))],
      onChanged: (value) { if (value == null) return; setState(() => incomingDamageElement = value); programmaSalvataggio(); notifyActiveSheetSummaryChanged(); },);
  }

  Widget resistanceDetailsPanel() => ValueListenableBuilder<int>(
    valueListenable: activeSheetSummaryRevision,
    builder: (context, _, child) => gothicPanel(child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        sectionTitle('Resistenze'),
        const Text('Fragilità, resistenze, immunità e rigenerazione sono salvate per elemento. Una percentuale libera sostituisce il preset di quell’elemento.'),
        const SizedBox(height: 12),
        for (final id in {...allDamageElementIds(), ...incomingDamagePresets.keys, ...dannoSubitoPercentPerTipo.keys})
          Padding(padding: const EdgeInsets.only(bottom: 12), child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                key: ValueKey('resistance_${id}_${configuredIncomingDamagePreset(id)}'),
                initialValue: configuredIncomingDamagePreset(id), isExpanded: true,
                decoration: fieldDecoration(elementDisplayName(id)),
                items: [for (final option in modificatoriDanno) DropdownMenuItem(value: option.name, child: Text(option.name))],
                onChanged: (value) { if (value == null) return; setState(() {
                  incomingDamagePresets[id] = value; dannoSubitoPercentPerTipo.remove(id);
                  if (id == selectedIncomingDamageElement()) dannoSubitoPercentController.clear();
                }); programmaSalvataggio(); notifyActiveSheetSummaryChanged(); },
              ),
              const SizedBox(height: 6),
              TextFormField(key: ValueKey('resistance_percent_${id}_${configuredIncomingDamagePreset(id)}'),
                initialValue: dannoSubitoPercentPerTipo[id] ?? '',
                decoration: fieldDecoration('Modifica libera (%)').copyWith(hintText: '+25% fragilità · −20% resistenza'),
                keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                onChanged: (value) { if (value.trim().isEmpty) { dannoSubitoPercentPerTipo.remove(id); } else { dannoSubitoPercentPerTipo[id] = value.trim(); }
                  programmaSalvataggio(invalidateCaches: false); },
                validator: (value) => (value ?? '').trim().isEmpty || oculumIncomingDamagePercentMultiplier(value ?? '') != null ? null : 'Percentuale non valida',
              ),
              Text(damageDescription(modificatoreDannoDaNome(configuredIncomingDamagePreset(id)))),
            ],)),
      ],)),);

  String subtraitFormulaHelp(HiddenEyeStat stat) {
    final group = hiddenEyeStatGroup(stat.id);
    final baseFormula = switch(stat.id) {
      'fortuna' => 'Karma + Fortuna nelle Risorse + ⌊Livello/2⌋',
      'nodo' => 'Karma + Livello',
      'investigazione' => '⌊max(Materia, Volontà)/2⌋ + Livello',
      'manifestazione_potere' => '⌊max(Materia, Oculum)/2⌋ + Livello',
      'concentrazione' => '⌊Volontà/2⌋ + Livello',
      _ => group == 'altro' ? 'Livello' : '⌊${hiddenEyeGroupLabel(group)}/2⌋ + Livello',
    };
    final total = hiddenEyeTotal(stat);
    final derived = hiddenEyeDerivedBonus(stat.id);
    final other = total - derived - (stat.id == 'fortuna' ? 0 : stat.valore);
    return '$baseFormula = $derived\nPunti assegnati: ${stat.id == 'fortuna' ? 0 : stat.valore} · altri bonus/malus: $other\nTiro: 1d20 + $total${hiddenEyeStatRollQuickBonus(stat) == 0 ? '' : ' + modificatore tiro ${hiddenEyeStatRollQuickBonus(stat)}'}';
  }

  Widget turnResetGesture(Widget child) => GestureDetector(
    onLongPress: requestEncounterReset, onSecondaryTap: requestEncounterReset,
    child: Tooltip(message: 'Tieni premuto o fai clic destro per resettare round e turni', child: child),);

  Future<void> requestEncounterReset() async {
    if (!haPermessiMaster && realtimeService?.isConnected == true) { await showReportedTurnEditor(); return; }
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Reset round e turni'), content: const Text('Riporta lo scontro al round 0 e i contatori personali a 0. Le schede rimangono nello scontro.'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reset'))],));
    if (confirmed == true && mounted) resetMasterInitiativeRound();
  }

  void removeReferenceEncounterMember(String id, Map token, {required bool local}) {
    final tag = '${token['sheetTag'] ?? token['id'] ?? ''}';
    if (!haPermessiMaster && tag != sheetTagAt(schedaCorrente)) return;
    if (local) {
      final previous = selectedMasterInitiativeGroupId;
      selectMasterInitiativeGroup(id);
      final index = masterInitiativeTokens.indexWhere((item) => item['id'] == token['id']);
      if (index >= 0) removeMasterInitiativeTokenAt(index);
      if (previous != id) selectMasterInitiativeGroup(previous);
      notifyActiveSheetSummaryChanged(); programmaSalvataggio();
    } else if (realtimeService?.isConnected == true) {
      unawaited(realtimeService!.sendInitiativeTurnAdjusted(senderRole: 'player',
        campaignId: activeCampaignId, campaignName: activeCampaignName(), sheetTag: tag,
        turn: playerReportedTurn, encounterId: id, leaveEncounter: true));
    }
  }

  // Advance only the participant who has completed a turn. Remote players own
  // their live effects; snapshots carry the same monotonic personal counter.
  void advanceEncounterParticipantTurn(int index) {
    final token = masterInitiativeTokens[index];
    final next = max(0, readIntValue(token['reportedTurn'])) + 1;
    final tag = '${token['sheetTag'] ?? token['id'] ?? ''}';
    if (tag == sheetTagAt(schedaCorrente)) {
      setPlayerReportedTurn(next, broadcast: false);
    } else {
      token['reportedTurn'] = next;
      final sheet = schedePersonaggio.where((s) => s['sheetTag'] == tag).firstOrNull;
      if (sheet != null) {
        sheet['playerReportedTurn'] = next;
        for (final raw in (sheet['activeStructuredEffects'] as List? ?? const []).whereType<Map>()) {
          if (oculumTurnUnit('${raw['unit']}') != 'turni') continue;
          final remaining = readIntValue(raw['remaining']);
          if (remaining > 0) raw['remaining'] = remaining - 1;
        }
        (sheet['activeStructuredEffects'] as List?)?.removeWhere((raw) => raw is Map && readIntValue(raw['remaining']) == 0);
        sheetCardRevision[tag] = (sheetCardRevision[tag] ?? 0) + 1;
      }
    }
    token['updatedAt'] = DateTime.now().toIso8601String();
  }
}

String oculumTurnUnit(String unit) => switch (oculumNormalizeText(unit)) {
  'turn' || 'turns' || 'turno' || 'turni' => 'turni',
  _ => oculumNormalizeText(unit),
};
'''
s=s.replace("        sheetCardRevision[tag] = (sheetCardRevision[tag] ?? 0) + 1;",'')
p.write_text(s,encoding='utf-8')
p=Path('lib/src/main/oculum_structured_effect_runtime.dart');s=p.read_text(encoding='utf-8').replace('final normalizedUnit = oculumNormalizeText(unit);','final normalizedUnit = oculumTurnUnit(unit);').replace("oculumNormalizeText('${effect['unit'] ?? ''}') != normalizedUnit", "oculumTurnUnit('${effect['unit'] ?? ''}') != normalizedUnit").replace("final unit = '${effect['unit'] ?? 'turni'}';", "final unit = oculumTurnUnit('${effect['unit'] ?? 'turni'}');");p.write_text(s,encoding='utf-8')
p=Path('lib/services/oculum_realtime_service.dart');s=p.read_text(encoding='utf-8').replace('bool joinEncounter = false,','bool joinEncounter = false,\n    bool leaveEncounter = false,').replace("if (joinEncounter) 'joinEncounter': true,", "if (joinEncounter) 'joinEncounter': true,\n      if (leaveEncounter) 'leaveEncounter': true,");p.write_text(s,encoding='utf-8')
p=Path('lib/src/main/oculum_realtime_integration.dart');s=p.read_text(encoding='utf-8');needle="      if (readBoolValue(payload['joinEncounter'])) {";s=s.replace(needle,r'''
      if (readBoolValue(payload['leaveEncounter'])) {
        final ownedSheet = schedePersonaggio.where((sheet) =>
          sheet['realtimeSourceSheetTag'] == targetTag &&
          '${sheet['realtimeOwnerName'] ?? ''}' == '${payload['playerName'] ?? ''}' &&
          '${sheet['realtimeOwnerName'] ?? ''}'.isNotEmpty).firstOrNull;
        if (ownedSheet != null) {
          final index = masterInitiativeTokens.indexWhere((token) => publicInitiativeSourceTag(token) == targetTag);
          if (index >= 0) removeMasterInitiativeTokenAt(index);
        }
        if (requestedId.isNotEmpty) selectMasterInitiativeGroup(previousGroup);
        notifyActiveSheetSummaryChanged();
        return;
      }
''' +needle);s=s.replace("        if ('${token['id'] ?? token['sheetTag'] ?? ''}' != currentTag)","        if ('${token['sheetTag'] ?? token['id'] ?? ''}' != currentTag)");p.write_text(s,encoding='utf-8')
