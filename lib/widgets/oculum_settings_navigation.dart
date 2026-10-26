import 'package:flutter/material.dart';

class OculumSettingsCategory {
  const OculumSettingsCategory(this.id, this.label, this.icon);
  final String id, label;
  final IconData icon;
}

/// Keeps the search field focused while the surrounding settings are rebuilt.
class OculumSettingsNavigation extends StatefulWidget {
  const OculumSettingsNavigation({
    super.key,
    required this.categories,
    required this.selected,
    required this.query,
    required this.onSelect,
    required this.onSearch,
    this.english = false,
  });
  final List<OculumSettingsCategory> categories;
  final String selected, query;
  final ValueChanged<String> onSelect, onSearch;
  final bool english;
  @override
  State<OculumSettingsNavigation> createState() =>
      _OculumSettingsNavigationState();
}

class _OculumSettingsNavigationState extends State<OculumSettingsNavigation> {
  late final TextEditingController search = TextEditingController(
    text: widget.query,
  );
  @override
  void didUpdateWidget(OculumSettingsNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (search.text != widget.query) search.text = widget.query;
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextField(
        key: const ValueKey('settings-search'),
        controller: search,
        onChanged: widget.onSearch,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          labelText: widget.english
              ? 'Search settings'
              : 'Cerca nelle impostazioni',
          hintText: widget.english
              ? 'Transparency, backups, dice…'
              : 'Trasparenza, backup, dadi…',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: widget.query.isEmpty
              ? null
              : IconButton(
                  tooltip: widget.english ? 'Clear search' : 'Cancella ricerca',
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    search.clear();
                    widget.onSearch('');
                  },
                ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      const SizedBox(height: 14),
      LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 560) {
            return DropdownButtonFormField<String>(
              key: ValueKey('settings-category-${widget.selected}'),
              initialValue: widget.selected,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: widget.english ? 'Section' : 'Sezione',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: [
                for (final category in widget.categories)
                  DropdownMenuItem(
                    value: category.id,
                    child: Row(
                      children: [
                        Icon(category.icon, size: 20),
                        const SizedBox(width: 10),
                        Flexible(child: Text(category.label)),
                      ],
                    ),
                  ),
              ],
              onChanged: (id) {
                if (id != null) widget.onSelect(id);
              },
            );
          }
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final category in widget.categories)
                ChoiceChip(
                  key: ValueKey('settings-category-${category.id}'),
                  avatar: Icon(category.icon, size: 18),
                  label: Text(category.label),
                  selected:
                      widget.selected == category.id && widget.query.isEmpty,
                  onSelected: (_) => widget.onSelect(category.id),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                ),
            ],
          );
        },
      ),
    ],
  );
}
