part of '../../main.dart';

int oculumSpineArmorForm(int level) => level >= 6 ? 3 : level >= 4 ? 2 : level >= 2 ? 1 : 0;

extension _OculumSpineHedgehogRuntime on _OculumHomePageState {
  String get spineVariant => oculumSpineVariantKey(arti.where((art) => art.skills.any((s) => s.nome == 'Armatura sottopelle')).map((a) => a.descrizione).join('\n'));
  int get spineMaterialDefense => switch (spineVariant) { 'osso' => 1, 'ferro' => 2, 'runico' => 3, _ => 0 };
  int get spineMaterialDamage => oculumSpineVariants.where((v) => v.id == spineVariant).firstOrNull?.bonus ?? 0;
  bool get hasSpineHedgehogArt => arti.any((art) =>
      art.nome == 'L’aculeo' || art.skills.any((skill) => skill.nome == 'Armatura sottopelle'));

  String spineArmorPreset() => hasSpineHedgehogArt
      ? ['', 'Resistenza Leggera', 'Resistenza', 'Alta Resistenza'][oculumSpineArmorForm(leggiNumero(livelloController))]
      : '';

  Future<List<String>> activateSpineHedgehogSkill(CharacterArt art, ArtSkill skill, int form, int oculumBefore, {int spent = 0}) async {
    if (!hasSpineHedgehogArt || !art.skills.any((s) => s.nome == 'Armatura sottopelle')) return [];
    final source = '${art.nome} / ${skill.nome} ${artLevelRoman(form)}';
    if (skill.nome == 'Armatura sottopelle') return ['Passiva automatica: ${spineArmorPreset()}.'];
    if (skill.nome == 'Lancio di aculei') {
      final bonus = (form == 3 ? oculumBefore + 100 : form == 2 ? 40 : 0) + spineMaterialDamage;
      final messages = applyStructuredEffectsOnActivation([
        OculumStructuredEffect(id: 'spine_volley', type: 'danno', valueExpression: '$bonus', duration: '1'),
      ], source: source);
      final condition = spineVariant == 'velenoso' ? 'veleno_putrido' : spineVariant == 'ghiaccio' ? 'gelo' : '';
      if (condition.isNotEmpty) await confirmSpineHitConditions([condition], 1, source, maxTargets: oculumBefore);
      return ['Fino a $oculumBefore avversari; danni ${spineVariant.isEmpty ? 'perforanti' : oculumSpineVariants.firstWhere((v) => v.id == spineVariant).element} per ciascun bersaglio colpito. Rispetta Difesa e Scudi.', ...messages];
    }
    if (skill.nome != 'Aculei precisi') return [];
    final precision = hiddenEyeStats.firstWhere((stat) => stat.id == 'precisione');
    var total = 0;
    var natural = 0;
    await tiraSottotrattoOcchio(precision, actionLabel: 'Aculei precisi', onResolved: (roll, value) { natural = roll; total = value; });
    if (!mounted) return [];
    if (spineVariant == 'runico' && natural == 20) addOculum(1, scheduleSave: false);
    final bonus = total + oculumBefore * (form == 3 ? 5 : form == 2 ? 2 : 0) + (form == 3 ? max(0, spent - 11) * 5 : 0) + spineMaterialDamage;
    activeStructuredEffects.removeWhere((effect) => effect['effectId'] == 'spine_piercing_weakness');
    activeStructuredEffects.add({
      'effectId': 'spine_piercing_weakness', 'source': source, 'type': 'elemental_resistance',
      'element': 'perforante', 'preset': 'Fragilità', 'remaining': 1, 'unit': 'turni',
    });
    final messages = applyStructuredEffectsOnActivation([
      OculumStructuredEffect(id: 'spine_precise_damage', type: 'danno', valueExpression: '$bonus', duration: '1'),
    ], source: source);
    final conditions = [if (form >= 2) 'privo_reazioni', if (spineVariant == 'velenoso') 'veleno_putrido', if (spineVariant == 'ghiaccio') 'gelo'];
    if (conditions.isNotEmpty) await confirmSpineHitConditions(conditions, form == 3 ? 2 : 1, source);
    return ['Precisione $total: bonus Danni +$bonus per un turno. Fragilità perforante per un turno.',
      if (form >= 2) 'Al bersaglio colpito: Aculei vincolanti — nessuna reazione per ${form == 3 ? 2 : 1} turni. Il Master applica la condizione nella Turnistica soltanto se il colpo riesce.',
      ...messages];
  }

  Future<void> confirmSpineHitConditions(List<String> kinds, int turns, String source, {int maxTargets = 1}) async {
    final candidates = schedePersonaggio.asMap().entries.where((e) => e.key != schedaCorrente &&
      ((modalitaMaster || isMasterHost || realtimeIsMasterRole) || e.value['realtimeSharedSheet'] != true)).toList();
    if (candidates.isEmpty || maxTargets < 1) return;
    final selected = <int>{};
    final hits = await showDialog<List<int>>(context: context, builder: (dialogContext) => StatefulBuilder(builder: (_, refresh) => AlertDialog(
      title: const Text('Aculei: conferma i bersagli colpiti'),
      content: SizedBox(width: 420, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Applica ${kinds.join(', ')} solo dopo un tiro per colpire riuscito. Massimo $maxTargets bersagli.'),
        for (final e in candidates) CheckboxListTile(title: Text(nomeSchedaPersonaggio(e.key)), value: selected.contains(e.key),
          onChanged: (value) => refresh(() { if (value == true && selected.length < maxTargets) { selected.add(e.key); } else { selected.remove(e.key); } })),
      ]))), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Nessun colpo confermato')),
        TextButton(onPressed: selected.isEmpty ? null : () => Navigator.pop(dialogContext, selected.toList()), child: const Text('Conferma colpi e condizioni'))],
    )));
    if (hits == null || !mounted) return;
    for (final index in hits) {
      final sheet = schedePersonaggio[index];
      final conditions = List<dynamic>.from(sheet['conditions'] as List? ?? []);
      for (final kind in kinds) {
        conditions.removeWhere((c) => c is Map && c['source'] == source && c['conditionType'] == kind);
        conditions.add(OculumConditionInstance(id: 'spine_${kind}_${DateTime.now().microsecondsSinceEpoch}', conditionType: kind,
          category: OculumConditionCategory.special, duration: kind == 'privo_reazioni' ? turns : 1,
          tickTrigger: OculumConditionTickTrigger.endTurn, source: source).toJson());
      }
      sheet['conditions'] = conditions;
      aggiungiLog('$source: colpo confermato su ${nomeSchedaPersonaggio(index)}. ${kinds.join(', ')} per $turns turni (Veleno/Gelo: un turno).');
      if (modalitaMaster || isMasterHost || realtimeIsMasterRole) sendRealtimeMasterVisibleTokenAt(index);
    }
    programmaSalvataggio();
  }

  Future<void> useSpineHedgehogOpen(CharacterArt art) async {
    var defenseRoll = 0;
    int? target;
    final candidates = schedePersonaggio.asMap().entries.where((e) => e.key != schedaCorrente &&
      ((modalitaMaster || isMasterHost || realtimeIsMasterRole) || e.value['realtimeSharedSheet'] != true)).toList();
    final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => StatefulBuilder(builder: (_, refresh) => AlertDialog(
      title: const Text('Pioggia di aculei · 1d200'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Richiede livello 10. Inserisci il totale CM del bersaglio. Se supera VC, dimezza tutti i danni. Senza bersaglio viene registrato soltanto il risultato.'),
        TextFormField(initialValue: '0', keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Tiro CM del bersaglio'), onChanged: (text) => defenseRoll = int.tryParse(text) ?? 0),
        DropdownButtonFormField<int>(decoration: const InputDecoration(labelText: 'Bersaglio (facoltativo)'), items: [for (final e in candidates) DropdownMenuItem(value: e.key, child: Text(nomeSchedaPersonaggio(e.key)))], onChanged: (value) => refresh(() => target = value)),
      ]), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annulla')),
        TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Lancia'))],
    )));
    if (confirmed != true || !mounted || leggiNumero(livelloController) < 10 || !art.openAttiva) return;
    final needles = Random.secure().nextInt(200) + 1;
    final attackRoll = rollTotalWithCritical(tiraD20(), 20, [vc()]);
    final normalDamage = dannoTotale();
    final total = needles + normalDamage;
    final damage = defenseRoll > attackRoll ? (total / 2).ceil() : total;
    if (target != null) applyMasterEnemyQuickHpAction(target!, damage: damage);
    risultato = 'Pioggia di aculei: 1d200 = $needles + Danni $normalDamage = $total. VC $attackRoll contro CM $defenseRoll: $damage danni perforanti; Difesa e Scudi restano validi.';
    aggiungiLog(risultato);
    mostraDadoCentrale(valore: '$needles', facce: 200, criticoUno: needles == 1, criticoVenti: needles == 200);
    sendRealtimeDiceRoll(label: risultato, roll: needles, bonus: damage - needles, total: damage, forceMasterVisible: true);
    notifyDiceResultChanged();
    programmaSalvataggio();
  }
}
