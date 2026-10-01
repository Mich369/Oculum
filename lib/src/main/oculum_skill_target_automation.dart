part of '../../main.dart';

int oculumSkillStatStealAmount(String text) {
  if (!RegExp(r'stat|stats', caseSensitive: false).hasMatch(text)) return 0;
  if (!RegExp(r'rub|sottr|togli|assorb', caseSensitive: false).hasMatch(text)) return 0;
  return int.tryParse(RegExp(r'(?:ruba|sottrai|togli|assorbi)\s+(\d+)', caseSensitive: false)
      .firstMatch(text)?.group(1) ?? '') ?? 0;
}

extension _OculumSkillTargetAutomation on _OculumHomePageState {
  Future<OculumSkillUseDialogResult?> askFixedStatTheftTargets(ArtSkill skill, int level) async {
    var count = 1;
    final selected = <String>{};
    final candidates = schedePersonaggio.asMap().entries.where((entry) => entry.key != schedaCorrente &&
      ((modalitaMaster || isMasterHost || realtimeIsMasterRole) || entry.value['realtimeSharedSheet'] != true)).toList();
    final cost = skill.oculumMinimoPerLivello(level);
    return showDialog<OculumSkillUseDialogResult>(context: context, builder: (context) => StatefulBuilder(
      builder: (context, refresh) => AlertDialog(
        title: Text('${skill.nome} — entità colpite'),
        content: SizedBox(width: 460, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Costo fisso: $cost Oculum. Indica quante entità viventi vengono colpite, oppure seleziona le schede per applicare anche la sottrazione.'),
          TextFormField(initialValue: '1', keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Numero di entità viventi'),
            onChanged: (value) => refresh(() => count = (int.tryParse(value) ?? 0).clamp(0, 1000))),
          for (final entry in candidates)
            CheckboxListTile(value: selected.contains(sheetTagAt(entry.key)),
              title: Text(nomeSchedaPersonaggio(entry.key)),
              onChanged: (value) => refresh(() {
                final tag = sheetTagAt(entry.key);
                if (value == true) {
                  selected.add(tag);
                } else {
                  selected.remove(tag);
                }
              })),
          Text('Entità effettive: ${selected.isEmpty ? count : selected.length}'),
        ]))),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
          FilledButton(onPressed: selected.isEmpty && count < 1 ? null : () => Navigator.pop(context,
            OculumSkillUseDialogResult(selected: cost, minimum: cost, maximum: cost,
              limitsChanged: false, targetCount: selected.isEmpty ? count : selected.length,
              targetSheetTags: selected.toList())), child: const Text('Attiva'))],
      ),
    ));
  }

  List<String> applyAutomaticStatTheft(ArtSkill skill, int level, OculumSkillUseDialogResult? use, String source) {
    final amount = oculumSkillStatStealAmount(skill.testoEvoluzione(level));
    if (amount <= 0 || use == null) return const [];
    final gains = <String, int>{for (final stat in ['resilienza', 'volonta', 'materia', 'oculum']) stat: amount * use.targetCount};
    for (final tag in use.targetSheetTags) {
      final index = schedePersonaggio.indexWhere((sheet) => '${sheet['sheetTag'] ?? sheet['id']}' == tag);
      if (index < 0) continue;
      final sheet = schedePersonaggio[index];
      final effects = List<dynamic>.from(sheet['activeStructuredEffects'] as List? ?? const []);
      for (final stat in gains.keys) {
        effects.add({'effectId': 'theft:${DateTime.now().microsecondsSinceEpoch}:$stat',
          'source': source, 'type': 'modifica_statistica', 'mode': 'diminuzione',
          'target': stat, 'resource': stat, 'value': -amount, 'stackable': true,
          'remaining': -1, 'unit': 'turni'});
      }
      sheet['activeStructuredEffects'] = effects;
      if (modalitaMaster || isMasterHost || realtimeIsMasterRole) sendRealtimeMasterVisibleTokenAt(index);
    }
    final effects = [for (final entry in gains.entries) OculumStructuredEffect(
      id: 'theft:${DateTime.now().microsecondsSinceEpoch}:${entry.key}',
      type: 'modifica_statistica', target: entry.key, valueExpression: '${entry.value}',
      stackable: true, recipient: 'se_stesso',
    )];
    return applyStructuredEffectsOnActivation(effects, source: source);
  }
}
