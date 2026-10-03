part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

const oculumHumanoidRoles = [
  'Bilanciato',
  'Support',
  'Tank',
  'Glass cannon',
  'Assassino',
  'Duellante',
  'Arciere',
  'Controllore',
];
Map<String, int> oculumHumanoidRoleStats(String role, int budget) {
  final weights = switch (role) {
    'Tank' => [45, 25, 20, 10],
    'Support' => [20, 30, 15, 35],
    'Glass cannon' => [10, 20, 50, 20],
    'Assassino' => [15, 30, 40, 15],
    'Duellante' => [25, 30, 35, 10],
    'Arciere' => [15, 25, 45, 15],
    'Controllore' => [15, 35, 15, 35],
    _ => [25, 25, 25, 25],
  };
  final total = max(4, budget);
  final values = [for (final weight in weights) max(1, total * weight ~/ 100)];
  while (values.reduce((a, b) => a + b) > total) {
    values[values.indexOf(values.reduce(max))]--;
  }
  var cursor = 0;
  while (values.reduce((a, b) => a + b) < total) {
    values[cursor++ % 4]++;
  }
  return Map.fromIterables([
    'resilienza',
    'volonta',
    'materia',
    'oculum',
  ], values);
}

bool oculumIsHumanoid(
  String type,
  String description,
  MonsterBookEntry? monster,
) {
  if (monster != null) {
    return monster.formTags.contains('Umanoide');
  }
  if (RegExp(
    r'non umanoide|quadrupede|slime|bestia|mammuth',
    caseSensitive: false,
  ).hasMatch(description)) {
    return false;
  }
  return RegExp(
    r'npc|png|nemico|umanoide|umano|bandito|soldato|cavaliere|elfo|nano|orco|goblin',
    caseSensitive: false,
  ).hasMatch('$type $description');
}

int oculumGlassCannonBonus({
  required String role,
  required int hp,
  required int maximum,
  required int baseAttack,
}) => role == 'Glass cannon' && hp > 0 && maximum > 0 && hp * 4 <= maximum
    ? max(1, baseAttack ~/ 2)
    : 0;

class OculumHumanoidChoice {
  const OculumHumanoidChoice(
    this.role,
    this.fateBonus,
    this.titleCount, {
    this.name = '',
    this.level,
    this.artMode,
  });
  final String name;
  final int? level;
  final String? artMode;
  final String role;
  final int fateBonus;
  final int titleCount;
}

Map<String, int> oculumRoleSubtraitBonuses(String role, int level) {
  final allocation = switch (role) {
    'Assassino' => {'velo': 4, 'riflessi': 3, 'inganno': 2},
    'Tank' => {'forza': 4, 'sopravvivenza': 3, 'schianto': 2},
    'Support' => {'medicina': 4, 'riflessi': 3, 'percezione': 2},
    'Glass cannon' => {'pressione': 4, 'forza': 3, 'riflessi': 2},
    'Duellante' => {'riflessi': 4, 'strategia': 3, 'forza': 2},
    'Arciere' => {'percezione': 4, 'riflessi': 3, 'velo': 2},
    'Controllore' => {'strategia': 4, 'eco': 3, 'percezione': 2},
    'Bilanciato' => {'strategia': 3, 'riflessi': 3, 'sopravvivenza': 3},
    _ => <String, int>{},
  };
  final packages = 1 + max(0, level) ~/ 3;
  return {
    for (final entry in allocation.entries) entry.key: entry.value * packages,
  };
}

extension _OculumHumanoidRoles on _OculumHomePageState {
  String get currentHumanoidRole =>
      schedaCorrente >= 0 && schedaCorrente < schedePersonaggio.length
      ? '${schedePersonaggio[schedaCorrente]['humanoidRole'] ?? ''}'
      : '';
  int roleSubtraitBonus(String id) =>
      oculumRoleSubtraitBonuses(
        currentHumanoidRole,
        leggiNumero(livelloController),
      )[id] ??
      0;
  Future<OculumHumanoidChoice?> askHumanoidRole(
    int budget, {
    String initialName = '',
    int initialLevel = 0,
    String initialArtMode = 'oculum',
    int Function(int)? budgetAtLevel,
  }) async {
    var name = initialName;
    var level = initialLevel;
    var artMode =
        [
          'oculum',
          'martial',
          'emblem',
          'defiled',
          'illness',
          'none',
        ].contains(initialArtMode)
        ? initialArtMode
        : 'oculum';
    var role = 'Bilanciato';
    var bonus = 2;
    var count = 1;
    return showDialog<OculumHumanoidChoice>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, refresh) {
          final stats = oculumHumanoidRoleStats(
            role,
            budgetAtLevel?.call(level) ?? budget,
          );
          return AlertDialog(
            title: const Text('Ruolo dell’umanoide'),
            content: SizedBox(
              width: 460,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      initialValue: name,
                      decoration: const InputDecoration(labelText: 'Nome'),
                      onChanged: (value) => name = value,
                    ),
                    TextFormField(
                      initialValue: '$level',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(labelText: 'Livello'),
                      onChanged: (value) => refresh(
                        () => level = max(0, int.tryParse(value) ?? 0),
                      ),
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: artMode,
                      decoration: const InputDecoration(labelText: 'Art'),
                      items: [
                        for (final kind in [
                          'oculum',
                          'martial',
                          'emblem',
                          'defiled',
                          'illness',
                          'none',
                        ])
                          DropdownMenuItem(
                            value: kind,
                            child: Text(
                              kind == 'none'
                                  ? 'Senza Art'
                                  : '${kind[0].toUpperCase()}${kind.substring(1)} Art',
                            ),
                          ),
                      ],
                      onChanged: (value) =>
                          refresh(() => artMode = value ?? artMode),
                    ),
                    const Text(
                      'Tecniche situazionali ai livelli 0, 3 e 6. Defiled: anche 9 e 12. Apertura dopo le evoluzioni richieste.',
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: role,
                      decoration: const InputDecoration(labelText: 'Categoria'),
                      items: [
                        for (final value in oculumHumanoidRoles)
                          DropdownMenuItem(value: value, child: Text(value)),
                      ],
                      onChanged: (value) => refresh(() => role = value ?? role),
                    ),
                    DropdownButtonFormField<int>(
                      initialValue: bonus,
                      decoration: const InputDecoration(
                        labelText: 'Bonus di ogni Titolo del Fato',
                      ),
                      items: [
                        for (var value = 2; value <= 6; value++)
                          DropdownMenuItem(
                            value: value,
                            child: Text('+$value a tutte le statistiche'),
                          ),
                      ],
                      onChanged: (value) =>
                          refresh(() => bonus = value ?? bonus),
                    ),
                    DropdownButtonFormField<int>(
                      initialValue: count,
                      decoration: const InputDecoration(
                        labelText: 'Numero di Titoli del Fato',
                      ),
                      items: [
                        for (var value = 1; value <= 3; value++)
                          DropdownMenuItem(value: value, child: Text('$value')),
                      ],
                      onChanged: (value) =>
                          refresh(() => count = value ?? count),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Base: ${stats.entries.map((entry) => '${entry.key}: ${entry.value}').join(' · ')}',
                    ),
                    Text(
                      'Sottotratti al livello $level: ${oculumRoleSubtraitBonuses(role, level).entries.map((entry) => '${entry.key} +${entry.value}').join(' · ')}. Nuovo pacchetto di 9 punti ogni 3 livelli.',
                    ),
                    Text(
                      'Con Titoli: ${stats.entries.map((entry) => '${entry.key}: ${entry.value + bonus * count}').join(' · ')}',
                    ),
                    const SizedBox(height: 12),
                    Text(switch (role) {
                      'Tank' =>
                        'Scudo = metà Vita. Bastione: Difesa ×2, CM +6 per 3 turni, cooldown 6.',
                      'Support' =>
                        'Passo evasivo: VC +4, Difesa +6 per 1 turno, cooldown 3.',
                      'Glass cannon' =>
                        'Attacco rapido ×2. A un quarto Vita: +50% Attacco rapido, fino alla guarigione oltre soglia.',
                      'Assassino' =>
                        'Materia e Volontà predominanti. Passo evasivo con cooldown 3.',
                      _ => 'Statistiche equilibrate e dotazione versatile.',
                    }),
                    const Text(
                      'Skill di ruolo autonome; Titoli ed equipaggiamento modificabili nella scheda.',
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annulla'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(
                  context,
                  OculumHumanoidChoice(
                    role,
                    bonus,
                    count,
                    name: name.trim(),
                    level: level,
                    artMode: artMode,
                  ),
                ),
                child: const Text('Crea'),
              ),
            ],
          );
        },
      ),
    );
  }

  void applyHumanoidRole(
    OculumHumanoidChoice choice,
    int budget,
    int level,
    int grade,
    String element,
  ) {
    final stats = oculumHumanoidRoleStats(choice.role, budget);
    resilienzaController.text = '${stats['resilienza']}';
    volontaController.text = '${stats['volonta']}';
    materiaController.text = '${stats['materia']}';
    oculumController.text = '${stats['oculum']}';
    currentResilienzaController.text = resilienzaController.text;
    currentVolontaController.text = volontaController.text;
    currentMateriaController.text = materiaController.text;
    applyTemporaryOculumState(
      TemporaryOculumState(
        normalCurrent: stats['oculum']!,
        temporary: 0,
        rollsRemaining: 0,
      ),
    );
    schedePersonaggio[schedaCorrente]['humanoidRole'] = choice.role;
    monsterStatPoints = 0;
    for (var i = 0; i < choice.titleCount; i++) {
      titoli.add(
        OculumTitle(
          nome: oculumHumanoidFateTitle(choice.role, i),
          tipo: 'Titolo del Fato',
          ottenimento:
              'Ruolo ${choice.role} · Titolo ${i + 1}/${choice.titleCount} · +${choice.fateBonus} a RES, VOL, MAT e OCU',
          buff: '',
          puntoCieco: '',
          skill: '',
          richiede: '',
          resilienza: choice.fateBonus,
          volonta: choice.fateBonus,
          materia: choice.fateBonus,
          oculum: choice.fateBonus,
          equipaggiato: true,
        ),
      );
    }
    final power = max(1, level + grade * 6);
    final tank = choice.role == 'Tank';
    inventario.addAll([
      InventoryItem(
        nome: choice.role == 'Support'
            ? 'Staffa del Custode'
            : tank
            ? 'Mazza del Bastione'
            : 'Lama del Predatore',
        peso: 1,
        quantita: 1,
        note: 'Titolo Item del ruolo ${choice.role}',
        arma: true,
        equipaggiata: true,
        gradoOggetto: grade,
        gradoRichiesto: grade,
        bonusDanno: power,
        elementoDanno: element,
      ),
      InventoryItem(
        nome: tank ? 'Corazza del Bastione' : 'Veste del ${choice.role}',
        peso: 2,
        quantita: 1,
        note: 'Titolo Item del ruolo ${choice.role}',
        protegge: true,
        equipaggiata: true,
        gradoOggetto: grade,
        gradoRichiesto: grade,
        bonusDifesa: tank ? power : max(1, power ~/ 3),
      ),
      if (tank)
        InventoryItem(
          nome: 'Scudo del Bastione',
          peso: 2,
          quantita: 1,
          note: 'Titolo Item del Tank',
          protegge: true,
          equipaggiata: true,
          gradoOggetto: grade,
          gradoRichiesto: grade,
          bonusScudo: power,
        ),
    ]);
    if (choice.role == 'Glass cannon') {
      attaccoRapidoController.text = '${max(2, level * 5 + power) * 2}';
      skills.add(
        CharacterSkill(
          nome: 'Ultimo assalto',
          tipo: 'Passiva di ruolo',
          costo: 'Passivo',
          cooldown: 'Sempre',
          descrizione:
              'A Vita positiva ≤ un quarto del massimo: Attacco rapido +50%, fino alla guarigione oltre soglia.',
          equipaggiata: true,
        ),
      );
    }
    if (tank || choice.role == 'Support' || choice.role == 'Assassino') {
      final name = tank ? 'Bastione' : 'Passo evasivo';
      final turns = tank ? 3 : 1;
      final description = tank
          ? 'Difesa ×2 e CM +6 per esattamente 3 turni. Cooldown 6 turni.'
          : 'VC +4 e Difesa +6 per 1 turno. Cooldown 3 turni.';
      skills.add(
        CharacterSkill(
          nome: name,
          tipo: 'Skill di ruolo',
          costo: '1 azione',
          cooldown: '${tank ? 6 : 3} turni',
          descrizione: description,
          equipaggiata: true,
          forme: [
            CharacterSkillForm(
              nome: name,
              costo: '1 azione',
              descrizione: description,
              cooldown: '${tank ? 6 : 3} turni',
              cooldownStrutturato: OculumAbilityCooldown(amount: tank ? 6 : 3),
              effettiStrutturati: [
                OculumStructuredEffect(
                  id: 'role:$name:defense',
                  type: 'modifica_statistica',
                  target: 'difesa',
                  valueExpression: tank ? 'Difesa' : '6',
                  duration: '$turns',
                ),
                OculumStructuredEffect(
                  id: 'role:$name:movement',
                  type: 'modifica_statistica',
                  target: tank ? 'cm' : 'vc',
                  valueExpression: tank ? '6' : '4',
                  duration: '$turns',
                ),
              ],
            ),
          ],
        ),
      );
    }
    invalidateDerivedDataCaches();
    if (tank) {
      scudoController.text = '${maxHp() ~/ 2}';
    }
  }
}

/// Catalogo locale: il ruolo determina l'utilità, l'elemento l'identità.
/// Non sostituisce le Art già salvate o quelle del Monster Book.
CharacterArt oculumBalancedHumanoidArt({
  required String mode,
  required String role,
  required String element,
}) {
  final ice = RegExp(
    'gelo|ghiaccio|ice',
    caseSensitive: false,
  ).hasMatch(element);
  final defense = role == 'Tank';
  final support = role == 'Support';
  final controller = role == 'Controllore';
  final shadow = role == 'Assassino';
  final theme = ice ? 'Brina Sepolta' : '$element — $role';
  final resource = mode == 'emblem' || mode == 'martial'
      ? 'nessuna'
      : mode == 'illness'
      ? 'follia'
      : mode == 'defiled'
      ? 'obser'
      : 'oculum';
  String evolution(int tier, int index) {
    final requiredLevel = (tier - 1) * 3;
    final effect = switch (index) {
      0 =>
        defense
            ? 'Proteggi un compagno adiacente: Difesa +${tier * 2} per 1 turno; non si cumula con se stessa.'
            : support
            ? 'Un compagno a portata recupera 1d${tier * 4} Vita, senza superare il massimale.'
            : shadow
            ? 'Se il bersaglio non ti vede, il prossimo colpo ottiene +${tier * 3} danni $element; poi ti riveli.'
            : 'Un bersaglio a portata subisce 1d${tier * 4} danni $element. Nessun danno aggiuntivo automatico.',
      1 =>
        controller || ice
            ? 'Rendi insidiosa una piccola zona visibile per 1 turno: chi la attraversa spende $tier metri di movimento extra. Su critico applica ${ice ? "Gelo I" : "svantaggio al prossimo tiro di movimento"}.'
            : 'Muoviti di ${tier + 1} metri verso una posizione libera e visibile; non attraversi ostacoli né annulli attacchi già risolti.',
      _ =>
        defense
            ? 'Se rimani fermo, Difesa +${tier * 3} contro il prossimo attacco; termina al movimento o dopo 1 turno.'
            : 'Marchi un bersaglio visibile per 1 turno: il primo colpo di un compagno contro di lui ottiene +${tier * 2} danni $element; poi il marchio termina.',
    };
    return 'Richiede livello $requiredLevel\n${["I", "II", "III", "IV", "V"][tier - 1]} · $effect';
  }

  final maxTier = mode == 'defiled' ? 5 : 3;
  return CharacterArt(
    nome: '${mode[0].toUpperCase()}${mode.substring(1)} Art — $theme',
    tipo: mode,
    descrizione:
        'Art del $role. Una sola applicazione per bersaglio; le evoluzioni sostituiscono la precedente. Tecniche iniziali contenute, crescita per livello. Costi fissi per evoluzione: ${resource == "nessuna" ? "cooldown" : "2 / 5 / 9 / 14 / 20 $resource"}.',
    hasIntegrity: mode != 'emblem',
    openName: ice ? 'Dominio della Brina Sepolta' : 'Risveglio — $theme',
    openDescription: ice
        ? 'Richiede livello ${maxTier == 5 ? 20 : 15}. Una volta ogni 10 turni, entro 6 metri tutto si ghiaccia: ogni nemico subisce 1d100 danni da ghiaccio e Gelo III per 1 turno. Non colpisce gli alleati. Il bonus dura finché l’Apertura resta attiva; richiede tutte le Skill alla massima evoluzione.'
        : 'Richiede livello ${maxTier == 5 ? 20 : 15}. Una volta ogni 10 turni, entro 4 metri ${support || defense ? "i compagni ottengono 1d20 Scudo" : "ogni nemico subisce 1d60 danni $element"}. Il bonus dura finché l’Apertura resta attiva; richiede tutte le Skill alla massima evoluzione.',
    openBuff: '@Stats+5',
    monsterOpenSkill: true,
    openSkill: ice
        ? 'Spine glaciali: genera spine da terreno, pareti o soffitto visibili entro 6 metri. Un nemico subisce 1d30 danni da ghiaccio; su critico applica Gelo I per 1 turno. Richiede Apertura attiva e 1 azione. Cooldown: 2 turni.'
        : 'Sigillo del $role: ${support || defense ? "un compagno visibile ottiene Difesa +6 per 1 turno" : "un nemico visibile subisce 1d20 danni $element"}. Richiede Apertura attiva e 1 azione. Cooldown: 2 turni.',
    openDescriptionCooldown: OculumAbilityCooldown(amount: 10, unit: 'turni'),
    openSkillCooldown: OculumAbilityCooldown(amount: 2, unit: 'turni'),
    skills: [
      for (var index = 0; index < 3; index++)
        ArtSkill(
          nome: index == 0
              ? (support
                    ? 'Sollievo del Custode'
                    : defense
                    ? 'Guardia condivisa'
                    : 'Morso del Sigillo')
              : index == 1
              ? (ice ? 'Passo sulla Brina' : 'Varco furtivo')
              : 'Segno del Compagno',
          livello: 0,
          evo1: evolution(1, index),
          evo2: evolution(2, index),
          evo3: evolution(3, index),
          evo4: mode == 'defiled' ? evolution(4, index) : '???',
          evo5: mode == 'defiled' ? evolution(5, index) : '???',
          oculumMinimiPerLivello: [2, 5, 9, 14, 20],
          oculumMassimiPerLivello: [2, 5, 9, 14, 20],
          risorseCostoPerLivello: List.filled(5, resource),
          cooldownPerLivello: [
            for (var tier = 1; tier <= 5; tier++)
              OculumAbilityCooldown(
                amount: resource == 'nessuna' ? 2 + tier : 1,
                unit: 'turni',
              ),
          ],
        ),
    ],
  );
}

String oculumHumanoidFateTitle(String role, int index) {
  final names = switch (role) {
    'Controllore' => [
      'Custode dei Fili',
      'Volontà del Sigillo',
      'Tessitore del Destino',
    ],
    'Tank' => ['Bastione Giurato', 'Cuore di Pietra', 'Ultima Muraglia'],
    'Support' => ['Mano del Custode', 'Veglia Benevola', 'Faro del Party'],
    'Assassino' => ['Passo Senza Eco', 'Lama del Crepuscolo', 'Ombra del Fato'],
    'Glass cannon' => ['Fiamma Fragile', 'Colpo Temerario', 'Ultima Scintilla'],
    'Arciere' => ['Occhio Distante', 'Filo della Mira', 'Sentinella del Fato'],
    'Duellante' => ['Lama Giurata', 'Passo del Duello', 'Custode della Sfida'],
    _ => ['Viandante Giurato', 'Cuore Saldo', 'Compagno del Fato'],
  };
  return names[index % names.length];
}

extension _OculumBalancedOpen on _OculumHomePageState {
  Future<bool> resolveBalancedOpen(
    CharacterArt art, {
    required bool activation,
  }) async {
    final sourceTag = sheetTagAt(schedaCorrente);
    final text = activation ? art.openDescription : art.openSkill;
    final faces = int.tryParse(
      RegExp(r'1d(\d+)', caseSensitive: false).firstMatch(text)?.group(1) ?? '',
    );
    final chosen = <int>{};
    var critical = false;
    final candidates = masterPartyIndexes()
        .where((i) => i != schedaCorrente)
        .toList();
    if (haPermessiMaster && candidates.isNotEmpty) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, refresh) => AlertDialog(
            title: Text(
              activation
                  ? 'Bersagli nell’area dell’Apertura'
                  : 'Bersaglio della Skill Open',
            ),
            content: SizedBox(
              width: 440,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Seleziona solo i bersagli validi e a portata. Il tiro si applica alle schede scelte.',
                    ),
                    for (final index in candidates)
                      CheckboxListTile(
                        value: chosen.contains(index),
                        title: Text(nomeSchedaPersonaggio(index)),
                        onChanged: (value) => refresh(() {
                          if (!activation) chosen.clear();
                          if (value == true) {
                            chosen.add(index);
                          } else {
                            chosen.remove(index);
                          }
                        }),
                      ),
                    if (!activation && text.contains('su critico'))
                      CheckboxListTile(
                        value: critical,
                        title: const Text('Il colpo è un critico positivo'),
                        onChanged: (value) =>
                            refresh(() => critical = value ?? false),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annulla'),
              ),
              FilledButton(
                onPressed: chosen.isEmpty
                    ? null
                    : () => Navigator.pop(context, true),
                child: const Text('Applica'),
              ),
            ],
          ),
        ),
      );
      if (confirmed != true ||
          !mounted ||
          sheetTagAt(schedaCorrente) != sourceTag ||
          !arti.contains(art)) {
        return false;
      }
    }
    final roll = faces == null ? 6 : Random.secure().nextInt(faces) + 1;
    for (final index in chosen) {
      if (text.contains('Scudo')) {
        setMasterEnemyLayerValue(
          index,
          'scudo',
          sheetIntValueAt(index, 'scudo') + roll,
        );
      } else if (faces != null) {
        applyMasterEnemyQuickHpAction(index, damage: roll);
      } else {
        final effects = List<dynamic>.from(
          schedePersonaggio[index]['activeStructuredEffects'] as List? ??
              const [],
        );
        effects.add({
          'effectId': 'open:${DateTime.now().microsecondsSinceEpoch}',
          'source': art.nome,
          'type': 'difesa',
          'mode': 'finche_attivo',
          'target': 'difesa',
          'value': 6,
          'remaining': 1,
          'unit': 'turni',
        });
        schedePersonaggio[index]['activeStructuredEffects'] = effects;
      }
      final stage = activation && text.contains('Gelo III')
          ? 3
          : critical && text.contains('Gelo I')
          ? 1
          : 0;
      if (stage > 0) {
        final sheet = schedePersonaggio[index];
        final immunities = sheet['conditionImmunities'] as List? ?? const [];
        if (!immunities.contains('gelo')) {
          final definition = oculumConditionDefinition('gelo')!;
          final conditions = List<dynamic>.from(
            sheet['activeConditions'] as List? ?? const [],
          );
          final existing = conditions
              .whereType<Map>()
              .where((value) => value['conditionType'] == 'gelo')
              .firstOrNull;
          if (existing != null) {
            existing['stage'] = max(stage, readIntValue(existing['stage']));
            existing['duration'] = max(1, readIntValue(existing['duration']));
          } else {
            conditions.add(
              OculumConditionInstance(
                id: 'gelo_${DateTime.now().microsecondsSinceEpoch}',
                conditionType: 'gelo',
                category: definition.category,
                stage: stage,
                duration: 1,
                tickTrigger: definition.tickTrigger,
                source: art.nome,
              ).toJson(),
            );
          }
          sheet['activeConditions'] = conditions;
        }
      }
    }
    setState(() {
      risultato =
          '$text\n${faces == null ? "Difesa +6" : "1d$faces = $roll"}${chosen.isEmpty ? " · assegna il risultato al bersaglio nella tua sessione" : " · ${chosen.map(nomeSchedaPersonaggio).join(", ")}"}';
      aggiungiLog(risultato);
      if (!activation) art.openSkillCooldown?.activate();
      invalidateDerivedDataCaches();
    });
    programmaSalvataggio();
    return true;
  }
}
