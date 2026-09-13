from pathlib import Path
p=Path('lib/src/main/oculum_home_secondary_pages.dart')
s=p.read_text(encoding='utf-8')
a=s.index('  Future<void> showMonsterBookQuickSpawnDialog('); b=s.index('  Widget masterDashboardMonsterBookPanel()',a)
s=s[:a]+'''  Future<void> showMonsterBookQuickSpawnDialog(MonsterBookEntry entry) async {
    final level = TextEditingController(text: '${entry.stats['level'] ?? 1}');
    final initial = oculumMonsterCreationStats(entry, max(0, int.tryParse(level.text) ?? 0));
    final controllers = {
      for (final key in initial.keys) key: TextEditingController(text: '${initial[key]}'),
    };
    var variant = 'base';
    void distribute() {
      final allocated = oculumMonsterCreationStats(entry, max(0, int.tryParse(level.text) ?? 0));
      for (final key in controllers.keys) { controllers[key]!.text = '${allocated[key]}'; }
    }
    try {
      await showDialog<void>(context: context, builder: (dialogContext) => StatefulBuilder(
        builder: (context, refresh) {
          final selectedLevel = max(0, int.tryParse(level.text) ?? 0);
          final selectedGrade = oculumGradeForLevel(selectedLevel);
          final expected = oculumMonsterCreationStats(entry, selectedLevel).values.fold<int>(0, (a,b) => a+b);
          final assigned = controllers.values.fold<int>(0, (a,c) => a + max(0, int.tryParse(c.text) ?? 0));
          final ocu = max(0, int.tryParse(controllers['oculum']!.text) ?? 0);
          final validOculum = entry.skillIds.isNotEmpty ? ocu > 0 : ocu == 0;
          final validNumbers = controllers.values.every((c) => int.tryParse(c.text) != null && int.parse(c.text) >= 0);
          final valid = validNumbers && assigned == expected && validOculum;
          return AlertDialog(
            backgroundColor: backgroundMidColor,
            title: Text('Genera ${entry.nameIt}'),
            content: SizedBox(width: 460, child: SingleChildScrollView(child: Column(
              mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(controller: level, keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Livello'),
                  onChanged: (_) => refresh(distribute)),
                const SizedBox(height: 8),
                Text('Grado $selectedGrade · +${oculumMonsterStatPointsPerGrade(entry.presetType)} punti per Grado'),
                const SizedBox(height: 8),
                smallInfoText(entry.skillIds.isNotEmpty
                    ? 'Volontà e Materia sostengono attacco e difesa; la riserva più ampia va a Oculum per le tecniche. Puoi rifinire i valori qui sotto.'
                    : 'Questa creatura non ha Skill né Oculum Art: i punti vanno a Resilienza, Volontà e Materia.'),
                if (selectedLevel == 0) smallInfoText('Livello 0: redistribuisce il totale della base del Book, senza bonus di Grado.'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(initialValue: variant,
                  decoration: const InputDecoration(labelText: 'Variante'),
                  items: const [
                    DropdownMenuItem(value: 'base', child: Text('Base')),
                    DropdownMenuItem(value: 'predatore', child: Text('Predatore · assalto e inseguimento')),
                    DropdownMenuItem(value: 'elite', child: Text('Élite · poteri e statistiche superiori')),
                  ], onChanged: (value) => refresh(() => variant = value ?? 'base')),
                for (final key in controllers.keys)
                  TextField(controller: controllers[key], keyboardType: TextInputType.number,
                    onChanged: (_) => refresh(() {}),
                    decoration: InputDecoration(labelText: switch(key) {
                      'resilienza' => 'Resilienza', 'volonta' => 'Volontà',
                      'materia' => 'Materia', _ => 'Oculum',
                    })),
                const SizedBox(height: 10),
                Text('Punti assegnati: $assigned / $expected',
                    style: TextStyle(color: valid ? Colors.greenAccent : Colors.amberAccent)),
                if (!validOculum) Text(entry.skillIds.isNotEmpty
                    ? 'Con almeno una Skill serve Oculum maggiore di zero.'
                    : 'Senza Skill e Oculum Art, Oculum deve restare a zero.'),
                TextButton.icon(onPressed: () => refresh(distribute),
                  icon: const Icon(Icons.balance), label: const Text('Distribuisci in base alle tecniche')),
              ],
            ))),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annulla')),
              FilledButton(onPressed: !valid ? null : () async {
                quickSheetNameController.text = entry.nameIt;
                quickSheetDescriptionController.text = systemMonsterGeneratorDescription(entry);
                quickSheetCountController.text = '1';
                await creaSchedaRapidaMaster(forcedType: entry.presetType,
                  fallbackName: entry.nameIt, sideOverride: entry.isNpc ? 'ally' : 'enemy',
                  forceEnemyProfile: !entry.isNpc, livelloForzato: selectedLevel,
                  statsMostroForzate: {for (final key in controllers.keys) key: int.parse(controllers[key]!.text)},
                  monsterVariant: variant, monsterBookSource: entry);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              }, child: const Text('Genera nella mia scheda')),
            ],
          );
        },
      ));
    } finally {
      level.dispose();
      for (final controller in controllers.values) { controller.dispose(); }
    }
  }

'''+s[b:]
s=s.replace('''              final grade = campoTesto(
                label: t('Grado iniziale', 'Starting grade'),
                controller: quickSheetGradeController,
              );''','''              final grade = quickSheetType.toLowerCase().contains('mostro')
                  ? ValueListenableBuilder<TextEditingValue>(
                      valueListenable: quickSheetLevelController,
                      builder: (context, value, _) => Text('Grado automatico: ${oculumGradeForLevel(max(0, int.tryParse(value.text) ?? 0))}'),
                    )
                  : campoTesto(label: t('Grado iniziale', 'Starting grade'), controller: quickSheetGradeController);''')
s=s.replace(' + grado × 10). Vita/Resilienza deve restare il tratto più alto.', ' + grado × ${oculumMonsterStatPointsPerGrade(quickSheetType)}). Distribuzione automatica in base alle Skill e alle Art.')
s=s.replace(' + grade × 10). Health/Resilience remains the highest trait.', ' + grade × ${oculumMonsterStatPointsPerGrade(quickSheetType)}). Stats are assigned from Skills and Arts.')
p.write_text(s,encoding='utf-8')
