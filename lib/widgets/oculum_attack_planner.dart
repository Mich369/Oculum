import 'dart:math';
import 'package:flutter/material.dart';
import '../game/oculum_opposed_attack.dart';

class OculumAttackChoice {
  const OculumAttackChoice(
    this.id,
    this.name,
    this.bonus, {
    this.color,
    this.featured = false,
  });
  final String id, name;
  final int bonus;
  final Color? color;
  final bool featured;
}

class OculumCombatElement {
  const OculumCombatElement(this.id, this.name, this.color);
  final String id, name;
  final Color color;
}

class OculumAttackPlan {
  const OculumAttackPlan(
    this.targetId,
    this.choiceId,
    this.reason, {
    this.additionalTargetIds = const [],
    this.element = 'fisico',
  });
  final String targetId, choiceId, reason;
  final List<String> additionalTargetIds;
  final String element;
  List<String> get targetIds => [targetId, ...additionalTargetIds];
}

/// A forecast can be exact or intentionally approximate.  A hidden estimate
/// still carries a short explanation, but never a percentage or enemy value.
class OculumAttackChanceEstimate {
  const OculumAttackChanceEstimate(
    this.forecast, {
    this.approximate = false,
    this.hiddenReason = '',
  });
  const OculumAttackChanceEstimate.hidden(this.hiddenReason)
    : forecast = null,
      approximate = false;

  final OculumAttackForecast? forecast;
  final bool approximate;
  final String hiddenReason;
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
    this.elements = const [],
    this.initialElement = 'fisico',
    this.availableForTarget,
    this.knowledgeRevision,
  });
  final Map<String, String> targets;
  final List<OculumAttackChoice> choices;
  final OculumAttackChanceEstimate? Function(
    String target,
    OculumAttackChoice choice,
  )
  chance;
  final String? initialTarget;
  final String initialChoice;
  final int minimumTargets, maximumTargets;
  final List<OculumCombatElement> elements;
  final String initialElement;
  final bool Function(String target, OculumAttackChoice choice)?
  availableForTarget;
  final Listenable? knowledgeRevision;
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
  late String element =
      widget.elements.any((option) => option.id == widget.initialElement)
      ? widget.initialElement
      : widget.elements.firstOrNull?.id ?? 'fisico';
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
        ..addAll(
          widget.choices
              .where((option) => option.featured)
              .map((option) => option.id),
        )
        ..add(choice);
  final reason = TextEditingController();
  final extraTargets = <String>[];

  @override
  void initState() {
    super.initState();
    widget.knowledgeRevision?.addListener(_knowledgeChanged);
  }

  @override
  void didUpdateWidget(covariant OculumAttackPlanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.knowledgeRevision != widget.knowledgeRevision) {
      oldWidget.knowledgeRevision?.removeListener(_knowledgeChanged);
      widget.knowledgeRevision?.addListener(_knowledgeChanged);
    }
  }

  void _knowledgeChanged() {
    if (mounted) setState(() {});
  }

  Future<void> chooseElement() async {
    if (widget.elements.isEmpty) return;
    final selected = await showDialog<String>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Elemento dell’attacco'),
        content: SizedBox(
          width: 360,
          height: MediaQuery.sizeOf(dialog).height * .6,
          child: ListView.builder(
            itemCount: widget.elements.length,
            itemBuilder: (context, index) {
              final option = widget.elements[index];
              return ListTile(
                leading: Icon(Icons.circle, color: option.color, size: 16),
                title: Text(option.name),
                selected: option.id == element,
                onTap: () => Navigator.pop(dialog, option.id),
              );
            },
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
    if (mounted && selected != null) setState(() => element = selected);
  }

  List<String> completedExtraTargets() {
    final result = [target, ...extraTargets];
    final selected = result.toSet().toList();
    final random = Random();
    while (result.length < widget.minimumTargets && selected.isNotEmpty) {
      result.add(selected[random.nextInt(selected.length)]);
    }
    return result.skip(1).toList();
  }

  bool targetAllowsSelectedChoice(String targetId) {
    final option = widget.choices
        .where((candidate) => candidate.id == choice)
        .firstOrNull;
    return option == null ||
        (widget.availableForTarget?.call(targetId, option) ?? true);
  }

  Future<void> addChoice() async {
    final hidden = widget.choices
        .where(
          (option) =>
              !visible.contains(option.id) &&
              (widget.availableForTarget?.call(target, option) ?? true),
        )
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
    widget.knowledgeRevision?.removeListener(_knowledgeChanged);
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
            if (widget.elements.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: chooseElement,
                  icon: Icon(
                    Icons.water_drop_outlined,
                    color: widget.elements
                        .firstWhere((option) => option.id == element)
                        .color,
                  ),
                  label: Text(
                    'Elemento · ${widget.elements.firstWhere((option) => option.id == element).name}',
                    style: TextStyle(
                      color: widget.elements
                          .firstWhere((option) => option.id == element)
                          .color,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
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
                    extraTargets.removeWhere((id) => id == value);
                    if (choice == 'precisione_punto_debole') choice = 'vc';
                  });
                }
              },
            ),
            if (widget.maximumTargets > 1) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Colpi sul bersaglio: ${1 + extraTargets.where((id) => id == target).length}',
                    ),
                  ),
                  IconButton(
                    tooltip: 'Ripeti sul bersaglio',
                    onPressed: 1 + extraTargets.length < widget.maximumTargets
                        ? () => setState(() => extraTargets.add(target))
                        : null,
                    icon: const Icon(Icons.add),
                  ),
                  IconButton(
                    tooltip: 'Rimuovi colpo ripetuto',
                    onPressed: extraTargets.contains(target)
                        ? () => setState(() => extraTargets.remove(target))
                        : null,
                    icon: const Icon(Icons.remove),
                  ),
                ],
              ),
              if (1 + extraTargets.length < widget.minimumTargets)
                const Text(
                  'I colpi rimanenti saranno distribuiti casualmente fra i bersagli selezionati.',
                ),
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
                      targetAllowsSelectedChoice(entry.key) &&
                          (extraTargets.contains(entry.key) ||
                              1 + extraTargets.length < widget.maximumTargets)
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
              'VC è il tiro di attacco ordinario. Per un tiro alternativo descrivi l’attacco a voce al Master; non serve scriverlo.',
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
                    (option) =>
                        visible.contains(option.id) &&
                        (widget.availableForTarget?.call(target, option) ??
                            true),
                  ))
                    Builder(
                      builder: (_) {
                        final estimate = widget.chance(target, option);
                        final chance = estimate?.forecast;
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
                                if (chance != null)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      8,
                                      0,
                                      8,
                                      8,
                                    ),
                                    child: Text(
                                      '${estimate!.approximate ? 'Stima approssimata' : 'Stima Percezione'} contro CM · evitato ${chance.avoided.toStringAsFixed(1)}% · ridotto ${chance.reduced.toStringAsFixed(1)}% · pieno ${chance.full.toStringAsFixed(1)}%',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ),
                                if (chance == null &&
                                    estimate != null &&
                                    estimate.hiddenReason.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      8,
                                      0,
                                      8,
                                      8,
                                    ),
                                    child: Text(
                                      estimate.hiddenReason,
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
                  labelText: 'Nota al Master (facoltativa)',
                  helperText: 'Puoi descrivere l’attacco a voce.',
                ),
                onChanged: (_) => setState(() {}),
              ),
            const SizedBox(height: 8),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Regole del confronto'),
              children: [
                const Text(
                  'Quasi riuscito se superi la difesa di 1–6 in Facile, 1–5 in Medio, 1–3 in Difficile. In Oculum: attacco pari alla difesa o inferiore di 1. In questi casi Difesa ×1,5 e durata degli effetti dimezzata, minimo 0. Attacco doppio: bonus critico ×2 e Fragilità. Difesa doppia: reazione critica gratuita.',
                ),
                const Text(
                  'Le stime usano solo i modificatori noti: non includono reazioni, spese future, dadi speciali o decisioni del Master.',
                ),
              ],
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
        onPressed: target.isEmpty || !widget.choices.any((c) => c.id == choice)
            ? null
            : () => Navigator.pop(
                context,
                OculumAttackPlan(
                  target,
                  choice,
                  choice == 'vc' ? '' : reason.text.trim(),
                  additionalTargetIds: completedExtraTargets(),
                  element: element,
                ),
              ),
        child: const Text('Dichiara e tira'),
      ),
    ],
  );
}
