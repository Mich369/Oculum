import 'package:flutter/material.dart';

import '../pages/oculum_dungeon/monster_book.dart';

/// Search is local to the picker; cancelling never changes the chosen monster.
class OculumMonsterPicker extends StatelessWidget {
  const OculumMonsterPicker({
    super.key,
    required this.entries,
    required this.selectedId,
    required this.onSelected,
  });

  final List<MonsterBookEntry> entries;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final selected = entries.where((entry) => entry.id == selectedId);
    return OutlinedButton.icon(
      key: const ValueKey('tutorial_monster_picker'),
      icon: const Icon(Icons.search),
      label: Text(
        selected.isEmpty
            ? 'Cerca un mostro nel Monster Book'
            : selected.first.nameIt,
      ),
      onPressed: () async {
        final choice = await showDialog<String>(
          context: context,
          builder: (context) => _MonsterSearchDialog(entries: entries),
        );
        if (choice != null) onSelected(choice);
      },
    );
  }
}

class _MonsterSearchDialog extends StatefulWidget {
  const _MonsterSearchDialog({required this.entries});

  final List<MonsterBookEntry> entries;

  @override
  State<_MonsterSearchDialog> createState() => _MonsterSearchDialogState();
}

class _MonsterSearchDialogState extends State<_MonsterSearchDialog> {
  String query = '';
  String habitat = '';
  String cyclePhase = '';

  @override
  Widget build(BuildContext context) {
    final terms = query.trim().toLowerCase().split(RegExp(r'\s+'));
    final matches = widget.entries.where((entry) {
      final text =
          '${entry.nameIt} ${entry.nameEn} ${entry.id} ${oculumMonsterCyclePhaseName(entry)}'
              .toLowerCase();
      return terms.every(text.contains) &&
          (habitat.isEmpty || entry.planeIds.contains(habitat)) &&
          (cyclePhase.isEmpty || oculumMonsterCyclePhase(entry) == cyclePhase);
    }).toList();
    return AlertDialog(
      title: const Text('Cerca un mostro'),
      content: SizedBox(
        width: 520,
        height: 400,
        child: Column(
          children: [
            TextField(
              key: const ValueKey('tutorial_monster_search'),
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nome del mostro',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => query = value),
            ),
            DropdownButtonFormField<String>(
              initialValue: habitat,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Piano / microrealtà',
              ),
              items: [
                const DropdownMenuItem(
                  value: '',
                  child: Text('Tutti i luoghi'),
                ),
                for (final place in oculumMonsterHabitats.entries)
                  DropdownMenuItem(value: place.key, child: Text(place.value)),
              ],
              onChanged: (value) => setState(() => habitat = value ?? ''),
            ),
            DropdownButtonFormField<String>(
              key: const ValueKey('monster_cycle_phase_filter'),
              initialValue: cyclePhase,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Fase del ciclo'),
              items: [
                const DropdownMenuItem(value: '', child: Text('Tutte le fasi')),
                for (final phase in oculumCycleMonsterPhaseNames.entries)
                  DropdownMenuItem(value: phase.key, child: Text(phase.value)),
              ],
              onChanged: (value) => setState(() => cyclePhase = value ?? ''),
            ),
            ListTile(
              title: const Text('Crea una creatura libera'),
              onTap: () => Navigator.pop(context, ''),
            ),
            Expanded(
              child: matches.isEmpty
                  ? const Center(child: Text('Nessun mostro trovato'))
                  : ListView.builder(
                      itemCount: matches.length,
                      itemBuilder: (context, index) {
                        final entry = matches[index];
                        return ListTile(
                          title: Text(entry.nameIt),
                          subtitle: oculumMonsterCyclePhaseName(entry).isEmpty
                              ? null
                              : Text(oculumMonsterCyclePhaseName(entry)),
                          onTap: () => Navigator.pop(context, entry.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
      ],
    );
  }
}
