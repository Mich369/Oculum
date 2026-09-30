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

  @override
  Widget build(BuildContext context) {
    final terms = query.trim().toLowerCase().split(RegExp(r'\s+'));
    final matches = widget.entries.where((entry) {
      final text = '${entry.nameIt} ${entry.nameEn} ${entry.id}'.toLowerCase();
      return terms.every(text.contains);
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
