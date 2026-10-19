import 'package:flutter/material.dart';
import '../game/oculum_opposed_attack.dart';

class OculumAttackChoice {
  const OculumAttackChoice(this.id, this.name, this.bonus, {this.color});
  final String id, name;
  final int bonus;
  final Color? color;
}

class OculumAttackPlan {
  const OculumAttackPlan(
    this.targetId,
    this.choiceId,
    this.reason, {
    this.additionalTargetIds = const [],
  });
  final String targetId, choiceId, reason;
  final List<String> additionalTargetIds;
  List<String> get targetIds => [targetId, ...additionalTargetIds];
}

/// Exact enumeration of supplied roll totals; callers decide which information
/// is public and which modifiers can legitimately be included in an estimate.
double oculumOpposedRollChance(List<int> attack, List<int> defense) {
  if (attack.isEmpty || defense.isEmpty) throw ArgumentError('Empty rolls');
  var wins = 0;
  for (final a in attack) {
    for (final d in defense) {
      if (a > d) wins++;
    }
  }
  return wins * 100 / (attack.length * defense.length);
}

class OculumAttackPlanner extends StatefulWidget {
  const OculumAttackPlanner({
    super.key,
    required this.targets,
    required this.choices,
    required this.chance,
    this.initialTarget,
    this.initialChoice = 'vc',
    this.minimumTargets = 1,
    this.maximumTargets = 1,
  });
  final Map<String, String> targets;
  final List<OculumAttackChoice> choices;
  final OculumAttackForecast? Function(String target, OculumAttackChoice choice)
  chance;
  final String? initialTarget;
  final String initialChoice;
  final int minimumTargets, maximumTargets;
  @override
  State<OculumAttackPlanner> createState() => _OculumAttackPlannerState();
}

class _OculumAttackPlannerState extends State<OculumAttackPlanner> {
  late String target = widget.targets.containsKey(widget.initialTarget)
      ? widget.initialTarget!
      : widget.targets.keys.firstOrNull ?? '';
  late String choice =
      widget.choices.any((option) => option.id == widget.initialChoice)
      ? widget.initialChoice
      : 'vc';
  late final Set<String> visible =
      widget.choices
          .where(
            (option) => const {
              'vc',
              'schianto',
              'forza',
              'riflessi',
              'manifestazione_potere',
            }.contains(option.id),
          )
          .map((option) => option.id)
          .toSet()
        ..add(choice);
  final reason = TextEditingController();
  final extraTargets = <String>{};

  Future<void> addChoice() async {
    final hidden = widget.choices
        .where((option) => !visible.contains(option.id))
        .toList();
    final selected = await showDialog<String>(
      context: context,
      builder: (dialog) => SimpleDialog(
        title: const Text('Aggiungi tiro alternativo'),
        children: [
          for (final option in hidden)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialog, option.id),
              child: Text(
                '${option.name} +${option.bonus}',
                style: TextStyle(color: option.color),
              ),
            ),
        ],
      ),
    );
    if (mounted && selected != null) setState(() => visible.add(selected));
  }

  @override
  void dispose() {
    reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Attacco · bersaglio e tiro'),
    content: SizedBox(
      width: 560,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              initialValue: target.isEmpty ? null : target,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Bersaglio nella turnistica',
              ),
              items: [
                for (final e in widget.targets.entries)
                  DropdownMenuItem(value: e.key, child: Text(e.value)),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    target = value;
                    extraTargets.remove(value);
                  });
                }
              },
            ),
            if (widget.maximumTargets > 1) ...[
              Text(
                'Bersagli: ${1 + extraTargets.length} · minimo ${widget.minimumTargets}, massimo ${widget.maximumTargets}',
              ),
              for (final entry in widget.targets.entries.where(
                (e) => e.key != target,
              ))
                CheckboxListTile(
                  dense: true,
                  title: Text(entry.value),
                  value: extraTargets.contains(entry.key),
                  onChanged:
                      extraTargets.contains(entry.key) ||
                          1 + extraTargets.length < widget.maximumTargets
                      ? (checked) => setState(() {
                          if (checked == true) {
                            extraTargets.add(entry.key);
                          } else {
                            extraTargets.remove(entry.key);
                          }
                        })
                      : null,
                ),
            ],
            const SizedBox(height: 12),
            const Text(
              'VC è il tiro di attacco ordinario. Con qualsiasi altro tiro devi descrivere l’attacco e motivare la scelta al Master; la scelta non garantisce che sia ammessa.',
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed:
                    widget.choices.any((option) => !visible.contains(option.id))
                    ? addChoice
                    : null,
                icon: const Icon(Icons.add),
                label: const Text('Aggiungi tiro'),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final option in widget.choices.where(
                    (option) => visible.contains(option.id),
                  ))
                    Builder(
                      builder: (_) {
                        final chance = widget.chance(target, option);
                        final color =
                            option.color ??
                            Theme.of(context).colorScheme.primary;
                        return SizedBox(
                          width: constraints.maxWidth < 300
                              ? constraints.maxWidth
                              : (constraints.maxWidth - 8) / 2,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: color.withValues(
                                alpha: choice == option.id ? .16 : .05,
                              ),
                              border: Border.all(
                                color: color.withValues(
                                  alpha: choice == option.id ? 1 : .5,
                                ),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextButton(
                                        onPressed: () =>
                                            setState(() => choice = option.id),
                                        style: TextButton.styleFrom(
                                          foregroundColor: color,
                                          minimumSize: const Size(0, 48),
                                        ),
                                        child: Text(
                                          '${option.name} ${option.bonus >= 0 ? '+' : ''}${option.bonus}',
                                        ),
                                      ),
                                    ),
                                    if (option.id != 'vc')
                                      IconButton(
                                        tooltip: 'Rimuovi ${option.name}',
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                          size: 18,
                                        ),
                                        color: color,
                                        onPressed: () => setState(() {
                                          visible.remove(option.id);
                                          if (choice == option.id) {
                                            choice = 'vc';
                                          }
                                        }),
                                      ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    8,
                                    0,
                                    8,
                                    8,
                                  ),
                                  child: Text(
                                    chance == null
                                        ? 'Probabilità non disponibile: difesa non condivisa.'
                                        : 'Stima contro CM · evitato ${chance.avoided.toStringAsFixed(1)}% · ridotto ${chance.reduced.toStringAsFixed(1)}% · pieno ${chance.full.toStringAsFixed(1)}%',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            if (choice != 'vc')
              TextField(
                key: const ValueKey('attack-reason'),
                controller: reason,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descrivi l’attacco e motiva il tiro',
                  helperText: 'Obbligatorio per un attacco diverso da VC.',
                ),
                onChanged: (_) => setState(() {}),
              ),
            const SizedBox(height: 8),
            const Text(
              'Quasi riuscito se superi la difesa di 1–6 in Facile, 1–5 in Medio, 1–3 in Difficile. In Oculum: attacco pari alla difesa o inferiore di 1. In questi casi Difesa ×1,5 e durata degli effetti dimezzata, minimo 0. Attacco doppio: bonus critico ×2 e Fragilità. Difesa doppia: reazione critica gratuita.',
            ),
            const Text(
              'Le stime usano solo i modificatori noti: non includono reazioni, spese future, dadi speciali o decisioni del Master.',
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
        onPressed:
            target.isEmpty ||
                1 + extraTargets.length < widget.minimumTargets ||
                !widget.choices.any((c) => c.id == choice) ||
                (choice != 'vc' && reason.text.trim().isEmpty)
            ? null
            : () => Navigator.pop(
                context,
                OculumAttackPlan(
                  target,
                  choice,
                  choice == 'vc' ? '' : reason.text.trim(),
                  additionalTargetIds: extraTargets.toList(),
                ),
              ),
        child: const Text('Dichiara e tira'),
      ),
    ],
  );
}
