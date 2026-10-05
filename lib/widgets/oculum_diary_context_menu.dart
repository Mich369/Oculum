import 'package:flutter/material.dart';
import '../services/oculum_diary_links.dart';
import '../services/oculum_diary_roles.dart';
import '../services/oculum_diary_memory.dart';

Widget oculumDiaryContextMenu(
  BuildContext context,
  EditableTextState editable, {
  required ValueChanged<TextEditingValue> onAssigned,
  bool english = false,
  List<DiaryEntity> catalogue = const [],
}) {
  final original = editable.widget.controller.value;
  final selection = original.selection;
  final target = diarySelectedName(
    original.text,
    selection.start,
    selection.end,
  );
  return AdaptiveTextSelectionToolbar.buttonItems(
    anchors: editable.contextMenuAnchors,
    buttonItems: [
      ...editable.contextMenuButtonItems,
      if (target != null && catalogue.isNotEmpty)
        ContextMenuButtonItem(
          label: english ? 'Link a suggested entry' : 'Collega voce suggerita',
          onPressed: () async {
            editable.hideToolbar();
            final matches = catalogue
                .where(
                  (entity) => entity.name.toLowerCase().contains(
                    target.name.toLowerCase(),
                  ),
                )
                .toList();
            final suggestions = (matches.isEmpty ? catalogue : matches)
                .where((entity) => diaryLinkTypes.containsKey(entity.kind))
                .take(30);
            final entity = await showDialog<DiaryEntity>(
              context: context,
              builder: (context) => SimpleDialog(
                title: const Text('Voci già presenti'),
                children: [
                  for (final entry in suggestions)
                    SimpleDialogOption(
                      onPressed: () => Navigator.pop(context, entry),
                      child: Text(
                        '${entry.name} · ${diaryEditableRoles[entry.kind] ?? entry.kind}',
                      ),
                    ),
                ],
              ),
            );
            if (!editable.mounted ||
                entity == null ||
                editable.widget.controller.text != original.text) {
              return;
            }
            final link = '[[${diaryLinkTypes[entity.kind]}:${entity.name}]]';
            onAssigned(
              TextEditingValue(
                text: original.text.replaceRange(
                  target.start,
                  target.end,
                  link,
                ),
                selection: TextSelection.collapsed(
                  offset: target.start + link.length,
                ),
              ),
            );
          },
        ),
      if (target != null)
        ContextMenuButtonItem(
          label: english ? 'Assign role' : 'Assegna ruolo',
          onPressed: () async {
            editable.hideToolbar();
            final role = await showDialog<String>(
              context: context,
              builder: (context) => SimpleDialog(
                title: Text(
                  '${english ? 'Role of' : 'Ruolo di'} «${target.name}»',
                ),
                children: [
                  for (final entry in diaryEditableRoles.entries)
                    if (diaryLinkTypes.containsKey(entry.key))
                      SimpleDialogOption(
                        onPressed: () => Navigator.pop(context, entry.key),
                        child: Text(entry.value),
                      ),
                ],
              ),
            );
            if (!editable.mounted ||
                role == null ||
                editable.widget.controller.text != original.text) {
              return;
            }
            final result = diaryAssignSelectionRole(
              original.text,
              selection.start,
              selection.end,
              role,
            );
            if (result == null) return;
            editable.widget.focusNode.requestFocus();
            onAssigned(
              TextEditingValue(
                text: result.text,
                selection: TextSelection.collapsed(offset: result.cursor),
              ),
            );
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (editable.mounted &&
                  editable.widget.controller.text == result.text) {
                editable.widget.controller.selection = TextSelection.collapsed(
                  offset: result.cursor,
                );
              }
            });
          },
        ),
    ],
  );
}
