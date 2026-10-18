import 'package:flutter/material.dart';
import '../game/oculum_opposed_attack.dart';

class OculumAttackChoice {
  const OculumAttackChoice(this.id, this.name, this.bonus);
  final String id, name;
  final int bonus;
}

class OculumAttackPlan {
  const OculumAttackPlan(this.targetId, this.choiceId, this.reason);
  final String targetId, choiceId, reason;
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
  });
  final Map<String, String> targets;
  final List<OculumAttackChoice> choices;
  final OculumAttackForecast? Function(String target, OculumAttackChoice choice)
  chance;
  final String? initialTarget;
  @override
  State<OculumAttackPlanner> createState() => _OculumAttackPlannerState();
}

class _OculumAttackPlannerState extends State<OculumAttackPlanner> {
  late String target = widget.targets.containsKey(widget.initialTarget)
      ? widget.initialTarget!
      : widget.targets.keys.firstOrNull ?? '';
  String choice = 'vc';
  final reason = TextEditingController();
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
                if (value != null) setState(() => target = value);
              },
            ),
            const SizedBox(height: 12),
            const Text(
              'VC è il tiro di attacco ordinario. Con qualsiasi altro tiro devi descrivere l’attacco e motivare la scelta al Master; la scelta non garantisce che sia ammessa.',
            ),
            const SizedBox(height: 8),
            for (final option in widget.choices)
              Builder(
                builder: (_) {
                  final chance = widget.chance(target, option);
                  return ListTile(
                    selected: choice == option.id,
                    leading: Icon(
                      choice == option.id
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                    ),
                    title: Text(
                      '${option.name} ${option.bonus >= 0 ? '+' : ''}${option.bonus}',
                    ),
                    subtitle: Text(
                      chance == null
                          ? 'Probabilità non disponibile: difesa non condivisa.'
                          : 'Stima contro CM · evitato ${chance.avoided.toStringAsFixed(1)}% · ridotto ${chance.reduced.toStringAsFixed(1)}% · pieno ${chance.full.toStringAsFixed(1)}%',
                    ),
                    onTap: () => setState(() => choice = option.id),
                  );
                },
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
                !widget.choices.any((c) => c.id == choice) ||
                (choice != 'vc' && reason.text.trim().isEmpty)
            ? null
            : () => Navigator.pop(
                context,
                OculumAttackPlan(
                  target,
                  choice,
                  choice == 'vc' ? '' : reason.text.trim(),
                ),
              ),
        child: const Text('Dichiara e tira'),
      ),
    ],
  );
}
