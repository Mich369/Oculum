part of '../../main.dart';

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
    r'npc|png|umanoide|umano|bandito|soldato|cavaliere|elfo|nano|orco|goblin',
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
  const OculumHumanoidChoice(this.role, this.fateBonus, this.titleCount);
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
  Future<OculumHumanoidChoice?> askHumanoidRole(int budget) async {
    var role = 'Bilanciato';
    var bonus = 2;
    var count = 1;
    return showDialog<OculumHumanoidChoice>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, refresh) {
          final stats = oculumHumanoidRoleStats(role, budget);
          return AlertDialog(
            title: const Text('Ruolo dell’umanoide'),
            content: SizedBox(
              width: 460,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                      'Sottotratti al livello 0: ${oculumRoleSubtraitBonuses(role, 0).entries.map((entry) => '${entry.key} +${entry.value}').join(' · ')}. Nuovo pacchetto di 9 punti ogni 3 livelli.',
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
                  OculumHumanoidChoice(role, bonus, count),
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
          nome: '${choice.role} del Fato ${i + 1}',
          tipo: 'Titolo del Fato',
          ottenimento: 'Identità dell’umanoide',
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
