import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/oculum_name_search.dart';
import '../pages/oculum_dungeon/monster_book.dart';

class OculumMonsterChoiceLabel extends StatelessWidget {
  const OculumMonsterChoiceLabel({
    super.key,
    required this.entry,
    this.english = false,
    this.title,
  });

  final MonsterBookEntry entry;
  final bool english;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final description = (english ? entry.descEn : entry.descIt).trim();
    final fallback = (english ? entry.descIt : entry.descEn).trim();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title ?? (english ? entry.nameEn : entry.nameIt),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (description.isNotEmpty || fallback.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            description.isEmpty ? fallback : description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

class OculumMonsterIdField extends StatefulWidget {
  const OculumMonsterIdField({
    super.key,
    required this.controller,
    required this.lookup,
    this.english = false,
  });

  final TextEditingController controller;
  final ({MonsterBookEntry? exact, List<MonsterBookEntry> suggestions})
  Function(String)
  lookup;
  final bool english;

  @override
  State<OculumMonsterIdField> createState() => _OculumMonsterIdFieldState();
}

class _OculumMonsterIdFieldState extends State<OculumMonsterIdField> {
  bool _choosing = false;

  String _label(String italian, String translation) =>
      widget.english ? translation : italian;

  Future<void> _complete(String value) async {
    if (_choosing) return;
    final controller = widget.controller;
    final initialText = controller.text;
    final result = widget.lookup(value);
    _choosing = true;
    final choice =
        result.exact ??
        await showDialog<MonsterBookEntry>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(_label('Mostri simili', 'Similar monsters')),
            content: SizedBox(
              width: 480,
              child: result.suggestions.isEmpty
                  ? Text(_label('Nessun mostro trovato', 'No monsters found'))
                  : SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final entry in result.suggestions)
                            ListTile(
                              title: OculumMonsterChoiceLabel(
                                entry: entry,
                                english: widget.english,
                              ),
                              subtitle: Text(entry.id),
                              onTap: () => Navigator.pop(context, entry),
                            ),
                        ],
                      ),
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(_label('Annulla', 'Cancel')),
              ),
            ],
          ),
        );
    _choosing = false;
    if (choice == null ||
        !mounted ||
        widget.controller != controller ||
        controller.text != initialText) {
      return;
    }
    controller.value = TextEditingValue(
      text: choice.id,
      selection: TextSelection.collapsed(offset: choice.id.length),
    );
  }

  @override
  Widget build(BuildContext context) => Focus(
    canRequestFocus: false,
    onKeyEvent: (_, event) {
      if (event is! KeyDownEvent ||
          event.logicalKey != LogicalKeyboardKey.tab ||
          HardwareKeyboard.instance.isShiftPressed) {
        return KeyEventResult.ignored;
      }
      final value = widget.controller.text.trim();
      if (value.isEmpty ||
          (value == widget.controller.text &&
              monsterById(value)?.visibleInMonsterBook == true)) {
        return KeyEventResult.ignored;
      }
      _complete(value);
      return KeyEventResult.handled;
    },
    child: TextField(
      controller: widget.controller,
      decoration: InputDecoration(
        labelText: _label('Nome o ID del mostro', 'Monster name or ID'),
        helperText: _label(
          'Facoltativo · TAB per trovare l’ID',
          'Optional · TAB to find the ID',
        ),
        suffixIcon: IconButton(
          tooltip: _label('Trova ID del mostro', 'Find monster ID'),
          onPressed: () {
            final value = widget.controller.text.trim();
            if (value.isNotEmpty) _complete(value);
          },
          icon: const Icon(Icons.search),
        ),
      ),
    ),
  );
}

/// Search is local to the picker; cancelling never changes the chosen monster.
class OculumMonsterPicker extends StatelessWidget {
  const OculumMonsterPicker({
    super.key,
    required this.entries,
    required this.selectedId,
    required this.onSelected,
    this.showDescriptions = false,
    this.allowClear = true,
    this.english = false,
    this.preferredElements,
  });

  final List<MonsterBookEntry> entries;
  final String selectedId;
  final ValueChanged<String> onSelected;
  final bool showDescriptions;
  final bool allowClear;
  final bool english;
  final Set<String> Function()? preferredElements;

  String _name(MonsterBookEntry entry) => english ? entry.nameEn : entry.nameIt;

  @override
  Widget build(BuildContext context) {
    final selected = entries
        .where((entry) => entry.id == selectedId)
        .firstOrNull;
    return OutlinedButton.icon(
      key: const ValueKey('tutorial_monster_picker'),
      icon: const Icon(Icons.search),
      label: selected != null && showDescriptions
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: OculumMonsterChoiceLabel(
                entry: selected,
                english: english,
                title: '${_name(selected)} · ${selected.presetType}',
              ),
            )
          : Text(
              selected == null
                  ? (english
                        ? 'Search for a monster in the Monster Book'
                        : 'Cerca un mostro nel Monster Book')
                  : _name(selected),
            ),
      onPressed: () async {
        final choice = await showDialog<String>(
          context: context,
          builder: (context) => _MonsterSearchDialog(
            entries: entries,
            showDescriptions: showDescriptions,
            allowClear: allowClear,
            english: english,
            preferredElements: preferredElements,
          ),
        );
        if (choice != null && context.mounted) onSelected(choice);
      },
    );
  }
}

class _MonsterSearchDialog extends StatefulWidget {
  const _MonsterSearchDialog({
    required this.entries,
    required this.showDescriptions,
    required this.allowClear,
    required this.english,
    this.preferredElements,
  });

  final List<MonsterBookEntry> entries;
  final bool showDescriptions;
  final bool allowClear;
  final bool english;
  final Set<String> Function()? preferredElements;

  @override
  State<_MonsterSearchDialog> createState() => _MonsterSearchDialogState();
}

class _MonsterSearchDialogState extends State<_MonsterSearchDialog> {
  String query = '';
  String habitat = '';
  String cyclePhase = '';

  String _label(String italian, String translation) =>
      widget.english ? translation : italian;

  String _name(MonsterBookEntry entry) =>
      widget.english ? entry.nameEn : entry.nameIt;

  @override
  Widget build(BuildContext context) {
    final normalized = query.trim().toLowerCase().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    final terms = normalized.isEmpty
        ? const <String>[]
        : normalized.split(RegExp(r'\s+'));
    final nameQuery = OculumNameQuery(normalized);
    final preferredElements = nameQuery.hasRelatedNames
        ? widget.preferredElements?.call() ?? const <String>{}
        : const <String>{};
    final scores = <String, int>{};
    final matches = widget.entries.where((entry) {
      if ((habitat.isNotEmpty && !entry.planeIds.contains(habitat)) ||
          (cyclePhase.isNotEmpty &&
              oculumMonsterCyclePhase(entry) != cyclePhase)) {
        return false;
      }
      if (terms.isEmpty) return true;
      final score = oculumMonsterNameMatchScore(
        entry,
        nameQuery,
        normalize: (name) => name.toLowerCase().trim(),
      );
      if (score > 0) {
        scores[entry.id] = nameQuery.rank(
          score,
          preferredElement: preferredElements.contains(
            entry.elementId.toLowerCase().trim(),
          ),
        );
        return true;
      }
      final text =
          '${entry.nameIt} ${entry.nameEn} ${entry.id} ${oculumMonsterCyclePhaseName(entry)}'
              .toLowerCase();
      return terms.every(text.contains) ||
          oculumMonsterNameSearchAliases(entry).any((alias) {
            final normalized = alias.toLowerCase();
            return terms.every(normalized.contains);
          });
    }).toList();
    if (terms.isNotEmpty) {
      final ranks = {
        for (var index = 0; index < matches.length; index++)
          matches[index].id: (scores[matches[index].id] ?? 0, index),
      };
      matches.sort((a, b) {
        final first = ranks[a.id]!;
        final second = ranks[b.id]!;
        final score = second.$1.compareTo(first.$1);
        return score != 0 ? score : first.$2.compareTo(second.$2);
      });
    }
    return AlertDialog(
      title: Text(_label('Cerca un mostro', 'Search for a monster')),
      content: SizedBox(
        width: 520,
        height: 400,
        child: Column(
          children: [
            TextField(
              key: const ValueKey('tutorial_monster_search'),
              autofocus: true,
              decoration: InputDecoration(
                labelText: _label('Nome del mostro', 'Monster name'),
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => query = value),
            ),
            DropdownButtonFormField<String>(
              initialValue: habitat,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: _label(
                  'Piano / microrealtà',
                  'Plane / microreality',
                ),
              ),
              items: [
                DropdownMenuItem(
                  value: '',
                  child: Text(_label('Tutti i luoghi', 'All places')),
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
              decoration: InputDecoration(
                labelText: _label('Fase del ciclo', 'Cycle phase'),
              ),
              items: [
                DropdownMenuItem(
                  value: '',
                  child: Text(_label('Tutte le fasi', 'All phases')),
                ),
                for (final phase in oculumCycleMonsterPhaseNames.entries)
                  DropdownMenuItem(value: phase.key, child: Text(phase.value)),
              ],
              onChanged: (value) => setState(() => cyclePhase = value ?? ''),
            ),
            if (widget.allowClear)
              ListTile(
                title: Text(
                  _label(
                    'Crea una creatura libera',
                    'Create a custom creature',
                  ),
                ),
                onTap: () => Navigator.pop(context, ''),
              ),
            Expanded(
              child: matches.isEmpty
                  ? Center(
                      child: Text(
                        _label('Nessun mostro trovato', 'No monsters found'),
                      ),
                    )
                  : ListView.builder(
                      itemCount: matches.length,
                      itemBuilder: (context, index) {
                        final entry = matches[index];
                        return ListTile(
                          title: widget.showDescriptions
                              ? OculumMonsterChoiceLabel(
                                  entry: entry,
                                  english: widget.english,
                                  title:
                                      '${_name(entry)} · ${entry.presetType}',
                                )
                              : Text(_name(entry)),
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
          child: Text(_label('Annulla', 'Cancel')),
        ),
      ],
    );
  }
}
