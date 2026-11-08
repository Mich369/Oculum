part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

class _OculumStat35Option {
  const _OculumStat35Option(
    this.id,
    this.name,
    this.description,
    this.defaults,
  );

  final String id;
  final String name;
  final String description;
  final Map<String, int> defaults;
}

const _stat35Options = <String, List<_OculumStat35Option>>{
  'resilienza': [
    _OculumStat35Option(
      'res_regen',
      'Rigenerazione',
      'Ogni tre colpi confermati che tolgono Vita, recuperi il 12% della Vita attuale. Ricordo Vitale si attiva al 20% o meno per tre turni, una volta per Fight.',
      {
        'hitsRequired': 3,
        'healPercent': 12,
        'thresholdPercent': 20,
        'vitalMemoryTurns': 3,
      },
    ),
    _OculumStat35Option(
      'res_immunity',
      'Immunità',
      'Per due turni sei immune ai colpi di Grado pari o inferiore. Il danno passa al 25%, 50%, 75% e 100% ai Gradi superiori. Un’Azione, una volta per Riposo Lungo.',
      {'durationTurns': 2, 'gradeStepPercent': 25},
    ),
    _OculumStat35Option(
      'res_group_heal',
      'Cura di gruppo',
      'Recuperi il 23% della Vita massima e gli alleati il 46% della propria. Un’Azione, una volta per Riposo Breve.',
      {'allyHealPercent': 46, 'selfHealPercent': 23},
    ),
  ],
  'volonta': [
    _OculumStat35Option(
      'will_aura',
      'Aura della Volontà',
      'Per tre turni +20% Danni e Difesa per te, +10% per gli alleati. Aggiunge 200 Scudo normale che resta fino al consumo e si somma. Una volta per Riposo Breve.',
      {'durationTurns': 3, 'selfPercent': 20, 'allyPercent': 10, 'shield': 200},
    ),
    _OculumStat35Option(
      'will_decisive',
      'Colpo decisivo',
      'Un attacco Letale con difesa normale. Se colpisce, aggiunge il 15% della tua Potenza attuale ai Danni. Una volta per Riposo Lungo.',
      {'powerPercent': 15},
    ),
    _OculumStat35Option(
      'will_pressure',
      'Pressione dominante',
      'Per tre turni, chi cerca di colpirti ha −6 al tiro. Recupero 6 turni personali.',
      {'durationTurns': 3, 'attackPenalty': 6, 'cooldown': 6},
    ),
  ],
  'materia': [
    _OculumStat35Option(
      'matter_precision',
      'Mira',
      'Attacco con Precisione e +6 al tiro. Usa la risorsa normale di attacco. Recupero 2 turni personali.',
      {'precisionBonus': 6, 'cooldown': 2},
    ),
    _OculumStat35Option(
      'matter_wind',
      'Wind Step',
      'Gratuito. Ti sposti accanto a un nemico entro il tuo movimento e lo colpisci sei volte al 25% dei Danni. Recupero 5 turni personali.',
      {'hits': 6, 'damagePercent': 25, 'cooldown': 5},
    ),
    _OculumStat35Option(
      'matter_immaterial',
      'Immateriale',
      'Una Reazione per prepararlo. Il prossimo colpo infligge 0% danno fisico, 75% elementale o magico e 100% ombra, spirituale, etereo o perforante. Recupero 5 turni personali.',
      {
        'physicalPercent': 0,
        'elementalPercent': 75,
        'bypassPercent': 100,
        'cooldown': 5,
      },
    ),
  ],
  'oculum': [
    _OculumStat35Option(
      'oculum_regen',
      'Rigenerazione Oculum',
      'Recuperi 1 Oculum ogni sei colpi riusciti che infliggono danno.',
      {'hits': 6, 'amount': 1},
    ),
    _OculumStat35Option(
      'oculum_blast',
      'Esplosione Oculum',
      '100 + 3 × livello Danni. Costa 4 Oculum e ha recupero 5 turni personali.',
      {'baseDamage': 100, 'perLevel': 3, 'cost': 4, 'cooldown': 5},
    ),
    _OculumStat35Option(
      'oculum_reload',
      'Ricarica Oculum',
      'Recuperi 1d10 + livello Oculum. L’eccedenza resta fino a fine Fight. Un’Azione, una volta per Riposo Lungo.',
      {'die': 10},
    ),
  ],
};

const _stat20Options = <String, List<_OculumStat35Option>>{
  'resilienza': [
    _OculumStat35Option(
      'res_vital_wake',
      'Risveglio Vitale',
      'Al risveglio ottieni 1d50 + 50 Vita temporanea, una volta al giorno.',
      {'diceFaces': 50, 'flatLife': 50},
    ),
    _OculumStat35Option(
      'res_physical',
      'Resistenza Fisica',
      'Tiri Resistenza contro il colpo. L’effetto sul suo elemento dura fino alla fine del Fight; ogni 6 punti di scarto in difetto perdi un livello di Resistenza.',
      {'pointsPerTier': 6},
    ),
  ],
  'volonta': [
    _OculumStat35Option(
      'will_heavy_slam',
      'Schianto Pesante',
      'Afferri il nemico e lo schianti a terra. ×1,5 Danni e Frattura. Recupero 3 turni.',
      {'damagePercent': 150, 'cooldown': 3},
    ),
    _OculumStat35Option(
      'will_heavy_pressure',
      'Pressione Pesante',
      'Blocchi fino a dieci bersagli di Grado al massimo uno sopra il tuo. Tu e i tuoi alleati fate critico dal 18 naturale e aggiungete la differenza di Potenza al tiro, minimo +9.',
      {
        'maxTargets': 10,
        'gradeAbove': 1,
        'minimumBonus': 9,
        'minimumNatural': 18,
      },
    ),
  ],
  'materia': [
    _OculumStat35Option(
      'matter_quick_action',
      'Azione Rapida',
      'Ottieni una Reazione veloce extra come azione gratuita ogni quattro turni.',
      {'cooldown': 4},
    ),
    _OculumStat35Option(
      'matter_free_dodge',
      'Schivata Gratuita',
      'Schivi gratuitamente un attacco. Un uso recuperato con un Riposo Lungo o due Riposi Brevi.',
      {'shortRests': 2},
    ),
  ],
  'oculum': [
    _OculumStat35Option(
      'oculum_sphere',
      'Sfera di Oculum',
      '30 Danni più i tuoi. Il risultato raddoppia contro chi non possiede Oculum.',
      {'baseDamage': 30, 'noOculumFactor': 2},
    ),
    _OculumStat35Option(
      'oculum_still_reload',
      'Ricarica dell’Oculum',
      'Rimani fermo un turno intero e recuperi 1d25 Oculum. Un colpo che supera gli Scudi interrompe la ricarica.',
      {'die': 25},
    ),
  ],
};

const _stat35Labels = {
  'resilienza': 'Resilienza',
  'volonta': 'Volontà',
  'materia': 'Materia',
  'oculum': 'Oculum',
};

const _stat35ParameterLabels = {
  'hitsRequired': 'Colpi richiesti',
  'healPercent': 'Vita recuperata (%)',
  'thresholdPercent': 'Soglia di Vita (%)',
  'vitalMemoryTurns': 'Durata Ricordo Vitale (turni)',
  'durationTurns': 'Durata (turni personali)',
  'gradeStepPercent': 'Danno per Grado superiore (%)',
  'allyHealPercent': 'Cura alleati (%)',
  'selfHealPercent': 'Cura propria (%)',
  'selfPercent': 'Bonus proprio (%)',
  'allyPercent': 'Bonus alleati (%)',
  'shield': 'Scudo normale',
  'powerPercent': 'Potenza aggiunta ai Danni (%)',
  'attackPenalty': 'Penalità al tiro',
  'cooldown': 'Recupero (turni personali)',
  'precisionBonus': 'Bonus Precisione',
  'hits': 'Colpi',
  'damagePercent': 'Danno per colpo (%)',
  'physicalPercent': 'Danno fisico ricevuto (%)',
  'elementalPercent': 'Danno elementale ricevuto (%)',
  'bypassPercent': 'Danno che attraversa (%)',
  'amount': 'Oculum recuperato',
  'baseDamage': 'Danno iniziale',
  'perLevel': 'Danno per livello',
  'cost': 'Costo in Oculum',
  'die': 'Facce del dado',
  'diceFaces': 'Facce del dado',
  'flatLife': 'Vita temporanea aggiuntiva',
  'pointsPerTier': 'Scarto per ridurre la resistenza',
  'maxTargets': 'Massimo bersagli',
  'gradeAbove': 'Grado di vantaggio massimo del bersaglio',
  'minimumBonus': 'Bonus minimo al tiro',
  'minimumNatural': 'Naturale minimo per il critico',
  'shortRests': 'Riposi Brevi per il recupero',
  'noOculumFactor': 'Moltiplicatore contro chi non ha Oculum',
  'damageBuffPercent': 'Bonus Danni Open (%)',
  'defenseBuffPercent': 'Bonus Difesa Open (%)',
  'rollBuff': 'Bonus al tiro con la propria Open',
  'openingShield': 'Scudo proprio all’apertura',
  'allyShield': 'Scudo alleati con la propria Open',
};

extension _OculumStat35 on _OculumHomePageState {
  Map _stat35Section(String section) {
    final data = planarState['stat35'];
    final value = data is Map ? data[section] : null;
    return value is Map ? value : const {};
  }

  void _writeStat35Section(String section, Map value) {
    final data = planarState['stat35'];
    planarState['stat35'] = {if (data is Map) ...data, section: value};
  }

  void _setStat35Value(String section, String key, Object? value) {
    final map = Map<String, dynamic>.from(_stat35Section(section));
    if (value == null) {
      if (!map.containsKey(key)) return;
      map.remove(key);
    } else {
      if (map[key] == value) return;
      map[key] = value;
    }
    _writeStat35Section(section, map);
  }

  String? stat35Choice(String stat) {
    final choice = _stat35Section('choices')[stat];
    return (_stat35Options[stat] ?? const []).any(
          (option) => option.id == choice,
        )
        ? choice as String
        : null;
  }

  bool hasStat35Choice(String stat, String option) =>
      stat35Choice(stat) == option;

  String? stat20Choice(String stat) {
    final choice = _stat35Section('choices20')[stat];
    return (_stat20Options[stat] ?? const []).any(
          (option) => option.id == choice,
        )
        ? choice as String
        : null;
  }

  List<String> _statMilestoneStats(String section, int threshold) {
    final data = planarState['stat35'];
    final value = data is Map ? data['$section$threshold'] : null;
    return _statMilestoneValidStats(value);
  }

  List<String> _statMilestoneValidStats(Object? value) => value is List
      ? value
            .whereType<String>()
            .where(_stat35Labels.containsKey)
            .toSet()
            .toList()
      : <String>[];

  List<List<String>> _statMilestoneQueued(int threshold) {
    final data = planarState['stat35'];
    final value = data is Map ? data['queued$threshold'] : null;
    return value is List
        ? value
              .map(_statMilestoneValidStats)
              .where((group) => group.isNotEmpty)
              .toList()
        : <List<String>>[];
  }

  void _writeStatMilestoneValue(String section, int threshold, List values) {
    final data = planarState['stat35'];
    planarState['stat35'] = {
      if (data is Map) ...data,
      '$section$threshold': values,
    };
  }

  int _statMilestoneLimit(int threshold) => threshold == 20 ? 2 : 3;

  bool _statMilestoneEntitled(String stat, int threshold) =>
      _statMilestoneStats('order', threshold).contains(stat) ||
      (threshold == 20 && _statMilestoneStats('order', 35).contains(stat));

  void recordStatMilestoneOrder() {
    if (!datiCaricati || loadingThresholdSheet || !_stat35CanEdit) return;
    final base = stat35PermanentBaseStats();
    for (final threshold in [20, 35]) {
      final ordered = _statMilestoneStats('order', threshold);
      if (ordered.length >= _statMilestoneLimit(threshold)) continue;
      final pending = _statMilestoneStats('pending', threshold);
      final queued = _statMilestoneQueued(threshold);
      final known = {
        ...ordered,
        ...pending,
        ...queued.expand((group) => group),
      };
      final reached = [
        for (final entry in base.entries)
          if (entry.value >= threshold && !known.contains(entry.key)) entry.key,
      ];
      if (reached.isEmpty) continue;
      if (pending.isNotEmpty) {
        if (ordered.length +
                pending.length +
                queued.expand((group) => group).length <
            _statMilestoneLimit(threshold)) {
          _writeStatMilestoneValue('queued', threshold, [...queued, reached]);
        }
      } else if (reached.length == 1) {
        _writeStatMilestoneValue('order', threshold, [
          ...ordered,
          reached.single,
        ]);
      } else {
        _writeStatMilestoneValue('pending', threshold, reached);
      }
    }
  }

  void _chooseStatMilestoneOrder(int threshold, String stat) {
    if (!_stat35CanEdit) return;
    final ordered = _statMilestoneStats('order', threshold);
    final pending = _statMilestoneStats('pending', threshold);
    if (ordered.length >= _statMilestoneLimit(threshold) ||
        ordered.contains(stat) ||
        !pending.contains(stat)) {
      return;
    }
    ordered.add(stat);
    pending.remove(stat);
    final queued = _statMilestoneQueued(threshold);
    final limit = _statMilestoneLimit(threshold);
    while (pending.isEmpty && queued.isNotEmpty && ordered.length < limit) {
      final next = queued.removeAt(0);
      if (next.length == 1) {
        ordered.add(next.single);
      } else {
        pending.addAll(next);
      }
    }
    setState(() {
      _writeStatMilestoneValue('order', threshold, ordered);
      _writeStatMilestoneValue(
        'pending',
        threshold,
        ordered.length >= limit ? [] : pending,
      );
      _writeStatMilestoneValue(
        'queued',
        threshold,
        ordered.length >= limit ? [] : queued,
      );
    });
    programmaSalvataggio();
  }

  int stat35Value(String option, String key, {required int fallback}) {
    final fields = _stat35Section('parameters')[option];
    return fields is Map
        ? readIntValue(fields[key], fallback: fallback)
        : fallback;
  }

  int stat35Cooldown(String option) =>
      max(0, readIntValue(_stat35Section('cooldowns')[option]));

  void setStat35Cooldown(String option, int turns) =>
      _setStat35Value('cooldowns', option, turns > 0 ? turns : null);

  int stat35ActiveTurns(String option) =>
      max(0, readIntValue(_stat35Section('activeTurns')[option]));

  void setStat35ActiveTurns(String option, int turns) =>
      _setStat35Value('activeTurns', option, turns > 0 ? turns : null);

  bool stat35RestReady(String option) =>
      !_stat35Section('restLocks').containsKey(option);

  void spendStat35RestUse(String option, {required bool long}) =>
      _setStat35Value('restLocks', option, long ? 'long' : 'short');

  void resetStat35Rest({required bool long}) {
    final locks = _stat35Section('restLocks');
    if (locks.isEmpty) return;
    _writeStat35Section('restLocks', {
      if (!long)
        for (final entry in locks.entries)
          if (entry.value != 'short') '${entry.key}': entry.value,
    });
  }

  void advanceStat35Cooldowns() {
    for (final section in ['cooldowns', 'activeTurns']) {
      final timers = _stat35Section(section);
      if (timers.isEmpty) continue;
      _writeStat35Section(section, {
        for (final entry in timers.entries)
          if (readIntValue(entry.value) > 1)
            '${entry.key}': readIntValue(entry.value) - 1,
      });
    }
  }

  Map<String, int> stat35PermanentBaseStats() {
    final values = <String, int>{
      'resilienza': max(0, leggiNumero(resilienzaController)),
      'volonta': max(0, leggiNumero(volontaController)),
      'materia': max(0, leggiNumero(materiaController)),
      'oculum': max(0, leggiNumero(oculumController)),
    };
    final ownerTag = sheetTagAt(schedaCorrente);
    for (final eye in occhiCaduti) {
      if (!readBoolValue(eye['active']) || eye['ownerSheetId'] != ownerTag) {
        continue;
      }
      final bonuses = eye['summonStatBonuses'];
      if (bonuses is! Map) continue;
      for (final key in values.keys) {
        values[key] = max(0, values[key]! - readIntValue(bonuses[key]));
      }
    }
    return values;
  }

  bool get _stat35CanEdit {
    if (schedaCorrente < 0 || schedaCorrente >= schedePersonaggio.length) {
      return false;
    }
    final sheet = schedePersonaggio[schedaCorrente];
    return !readBoolValue(sheet['realtimeReadOnlyByMaster']) &&
        !readBoolValue(sheet['realtimeRestrictedByMaster']);
  }

  String? _statMilestoneChoice(String stat, int threshold) =>
      threshold == 20 ? stat20Choice(stat) : stat35Choice(stat);

  Future<void> _chooseStatMilestone(String stat, int threshold) async {
    final options = (threshold == 20 ? _stat20Options : _stat35Options)[stat];
    if (options == null ||
        !_stat35CanEdit ||
        _statMilestoneChoice(stat, threshold) != null ||
        (threshold == 35 && stat20Choice(stat) == null) ||
        !_statMilestoneEntitled(stat, threshold)) {
      return;
    }
    final origin = (currentSheetScrollId(), activeCampaignId);
    var submitted = false;
    final selected = await showDialog<_OculumStat35Option>(
      context: context,
      builder: (dialog) => AlertDialog(
        scrollable: true,
        title: Text('${_stat35Labels[stat]} · $threshold'),
        content: SizedBox(
          width: min(704, max(140, MediaQuery.sizeOf(dialog).width - 112)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Scegli una sola capacità per questa statistica.'),
              const SizedBox(height: 8),
              if (threshold == 20)
                const Text(
                  'La scelta viene salvata. L’attivazione sarà disponibile con l’integrazione di queste capacità.',
                ),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final columns = min(
                    options.length,
                    max(1, (width / 172).floor()),
                  );
                  final size = min(
                    230.0,
                    (width - 8 * (columns - 1)) / columns,
                  );
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final option in options)
                        SizedBox.square(
                          dimension: size,
                          child: _OculumStatMilestoneCard(
                            option: option,
                            color: _statMilestoneColor(stat),
                            choose: () {
                              if (submitted) return;
                              submitted = true;
                              Navigator.pop(dialog, option);
                            },
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: const Text('Annulla'),
          ),
        ],
      ),
    );
    if (!mounted ||
        selected == null ||
        origin != (currentSheetScrollId(), activeCampaignId) ||
        !_stat35CanEdit ||
        _statMilestoneChoice(stat, threshold) != null ||
        (threshold == 35 && stat20Choice(stat) == null) ||
        !_statMilestoneEntitled(stat, threshold)) {
      return;
    }
    setState(
      () => _setStat35Value(
        threshold == 20 ? 'choices20' : 'choices',
        stat,
        selected.id,
      ),
    );
    aggiungiLog(
      '${_stat35Labels[stat]} $threshold · scelta ${selected.name} salvata.',
    );
    programmaSalvataggio();
  }

  Future<void> _editStat35(_OculumStat35Option option) async {
    if (!_stat35CanEdit) return;
    final origin = (currentSheetScrollId(), activeCampaignId);
    final values = {
      for (final entry in option.defaults.entries)
        entry.key: stat35Value(option.id, entry.key, fallback: entry.value),
    };
    final form = GlobalKey<FormState>();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(option.name),
        scrollable: true,
        content: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final entry in values.entries)
                TextFormField(
                  initialValue: '${entry.value}',
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: _stat35ParameterLabels[entry.key] ?? entry.key,
                  ),
                  validator: (text) {
                    final value = int.tryParse(text ?? '');
                    return value == null || value < 0
                        ? 'Inserisci un numero intero positivo o zero.'
                        : null;
                  },
                  onSaved: (text) => values[entry.key] = int.parse(text!),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState?.validate() != true) return;
              form.currentState!.save();
              Navigator.pop(dialog, true);
            },
            child: const Text('Salva'),
          ),
        ],
      ),
    );
    if (!mounted ||
        accepted != true ||
        origin != (currentSheetScrollId(), activeCampaignId) ||
        !_stat35CanEdit) {
      return;
    }
    setState(() => _setStat35Value('parameters', option.id, values));
    programmaSalvataggio();
  }

  Widget stat35ChoicePanel() {
    final base = stat35PermanentBaseStats();
    return gothicPanel(
      borderColor: tertiaryColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Traguardi delle statistiche · 20 e 35'),
          for (final threshold in [20, 35])
            if (_statMilestoneStats('pending', threshold).isNotEmpty &&
                _statMilestoneStats('order', threshold).length <
                    _statMilestoneLimit(threshold))
              _statMilestonePrecedence(threshold),
          for (final entry in _stat35Options.entries)
            _stat35ChoiceTile(entry.key, base[entry.key] ?? 0),
        ],
      ),
    );
  }

  Color _statMilestoneColor(String stat) => switch (stat) {
    'resilienza' => const Color(0xFF62E597),
    'volonta' => const Color(0xFFFF7269),
    'materia' => const Color(0xFF63CDFF),
    _ => eyePupilGlowColor,
  };

  Widget _statMilestonePrecedence(int threshold) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Soglia $threshold · scegli quale statistica ha precedenza.'),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final stat in _statMilestoneStats('pending', threshold))
            OutlinedButton(
              onPressed: _stat35CanEdit
                  ? () => _chooseStatMilestoneOrder(threshold, stat)
                  : null,
              child: Text(_stat35Labels[stat]!),
            ),
        ],
      ),
    ],
  );

  Widget _stat35ChoiceTile(String stat, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_stat35Labels[stat]} · $value base',
            style: TextStyle(color: _statMilestoneColor(stat)),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final threshold in [20, 35])
                _statMilestoneChoiceButton(stat, threshold),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statMilestoneChoiceButton(String stat, int threshold) {
    final options = (threshold == 20 ? _stat20Options : _stat35Options)[stat]!;
    final selected = options
        .where((option) => option.id == _statMilestoneChoice(stat, threshold))
        .firstOrNull;
    if (selected != null) {
      return Tooltip(
        message: selected.description,
        child: OutlinedButton.icon(
          onPressed: selected.defaults.isNotEmpty && _stat35CanEdit
              ? () => _editStat35(selected)
              : null,
          icon: Icon(
            selected.defaults.isNotEmpty ? Icons.tune : Icons.check,
            size: 15,
          ),
          label: Text('$threshold · ${selected.name}'),
        ),
      );
    }
    final entitled = _statMilestoneEntitled(stat, threshold);
    final needsEarlierChoice =
        entitled && threshold == 35 && stat20Choice(stat) == null;
    return OutlinedButton.icon(
      onPressed: entitled && !needsEarlierChoice && _stat35CanEdit
          ? () => _chooseStatMilestone(stat, threshold)
          : null,
      icon: Icon(
        entitled && !needsEarlierChoice
            ? Icons.auto_awesome
            : Icons.lock_outline,
        size: 15,
      ),
      label: Text(
        needsEarlierChoice
            ? 'Prima scegli a 20'
            : entitled
            ? 'Scegli a $threshold'
            : '$threshold',
      ),
    );
  }

  List<Widget> stat20ActionWidgets(
    OculumCombatAbilityRole role, {
    required void Function(VoidCallback) select,
  }) {
    final attack = OculumCombatAbilityRole.attack;
    final support = OculumCombatAbilityRole.support;
    final actions =
        <String, (OculumCombatAbilityRole, bool, Future<void> Function())>{
          _stat20WillSlam: (
            attack,
            stat20WillSlamReady,
            activateStat20WillSlam,
          ),
          _stat20WillPressure: (
            attack,
            stat20WillPressureReady,
            activateStat20WillPressure,
          ),
          _materia20QuickAction: (
            support,
            canActivateMateria20QuickAction,
            activateMateria20QuickAction,
          ),
          _stat20OculumSphere: (
            attack,
            stat20OculumSphereReady,
            activateStat20OculumSphere,
          ),
          _stat20OculumReload: (
            support,
            stat20OculumCanStartCharge,
            activateStat20OculumReload,
          ),
        };
    return [
      for (final entry in _stat20Options.entries)
        for (final option in entry.value)
          if (stat20Choice(entry.key) == option.id &&
              actions[option.id]?.$1 == role)
            ListTile(
              leading: Icon(
                Icons.auto_awesome,
                color: _statMilestoneColor(entry.key),
              ),
              title: Text(option.name),
              subtitle: Text(
                stat35Cooldown(option.id) > 0
                    ? 'Recupero · ${stat35Cooldown(option.id)} turni personali'
                    : option.description,
              ),
              enabled: actions[option.id]!.$2,
              onTap: actions[option.id]!.$2
                  ? () => select(() => unawaited(actions[option.id]!.$3()))
                  : null,
            ),
    ];
  }

  List<Widget> stat35ActionWidgets(
    OculumCombatAbilityRole role, {
    required void Function(VoidCallback) select,
  }) {
    final attack = OculumCombatAbilityRole.attack;
    final defense = OculumCombatAbilityRole.defense;
    final support = OculumCombatAbilityRole.support;
    final actions =
        <String, (OculumCombatAbilityRole, Future<void> Function())>{
          'will_aura': (support, activateStat35WillAura),
          'will_decisive': (attack, activateStat35WillDecisive),
          'will_pressure': (defense, activateStat35WillPressure),
          'matter_precision': (attack, activateMateria35Aim),
          'matter_wind': (attack, activateMateria35WindStep),
          'matter_immaterial': (defense, prepareMateria35Immateriale),
          'oculum_blast': (attack, activateStat35OculumBlast),
          'oculum_reload': (support, activateStat35OculumReload),
          'res_immunity': (defense, useStat35ResImmunity),
          'res_group_heal': (support, useStat35ResGroupHeal),
        };
    return [
      for (final entry in _stat35Options.entries)
        for (final option in entry.value)
          if (hasStat35Choice(entry.key, option.id) &&
              actions[option.id]?.$1 == role)
            ListTile(
              leading: Icon(
                Icons.auto_awesome,
                color: _statMilestoneColor(entry.key),
              ),
              title: Text(option.name),
              subtitle: Text(
                stat35Cooldown(option.id) > 0
                    ? 'Recupero · ${stat35Cooldown(option.id)} turni personali'
                    : stat35RestReady(option.id)
                    ? option.description
                    : 'In recupero fino al prossimo riposo richiesto.',
              ),
              enabled:
                  stat35Cooldown(option.id) == 0 && stat35RestReady(option.id),
              onTap:
                  stat35Cooldown(option.id) == 0 && stat35RestReady(option.id)
                  ? () => select(() => unawaited(actions[option.id]!.$2()))
                  : null,
            ),
    ];
  }
}

class _OculumStatMilestoneCard extends StatefulWidget {
  const _OculumStatMilestoneCard({
    required this.option,
    required this.color,
    required this.choose,
  });

  final _OculumStat35Option option;
  final Color color;
  final VoidCallback choose;

  @override
  State<_OculumStatMilestoneCard> createState() =>
      _OculumStatMilestoneCardState();
}

class _OculumStatMilestoneCardState extends State<_OculumStatMilestoneCard> {
  bool _hover = false;
  bool _focus = false;

  @override
  Widget build(BuildContext context) {
    final lit = _hover || _focus;
    final color = widget.color;
    const radius = BorderRadius.all(Radius.circular(11));
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: color.withValues(alpha: lit ? 1 : .72)),
        gradient: RadialGradient(
          center: Alignment.bottomCenter,
          radius: lit ? 1.4 : .75,
          colors: [
            color.withValues(alpha: lit ? .44 : .11),
            const Color(0xFF14141E),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: lit ? .35 : .11),
            blurRadius: lit ? 18 : 5,
            offset: Offset(0, lit ? -4 : 0),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onHover: (value) => setState(() => _hover = value),
          onFocusChange: (value) => setState(() => _focus = value),
          onTap: widget.choose,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: LayoutBuilder(
              builder: (context, constraints) => FittedBox(
                alignment: Alignment.topLeft,
                fit: BoxFit.scaleDown,
                child: SizedBox(
                  width: constraints.maxWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.option.name,
                        style: TextStyle(
                          color: color,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.option.description,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
