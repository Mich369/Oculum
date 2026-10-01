import 'package:flutter/material.dart';
import '../services/oculum_diary_links.dart';
import '../services/oculum_diary_roles.dart';

Widget oculumDiaryContextMenu(
  BuildContext context,
  EditableTextState editable, {
  required ValueChanged<TextEditingValue> onAssigned,
  bool english = false,
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
