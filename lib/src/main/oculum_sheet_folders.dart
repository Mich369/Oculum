part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

bool oculumSheetFolderCanMove(
  List<Map<String, dynamic>> folders,
  String id,
  String parent,
) {
  final seen = <String>{id};
  var cursor = parent;
  while (cursor.isNotEmpty) {
    if (!seen.add(cursor)) return false;
    final folder = folders.where((f) => f['id'] == cursor).firstOrNull;
    if (folder == null) return false;
    cursor = '${folder['parent'] ?? ''}';
  }
  return true;
}

extension _OculumSheetFolders on _OculumHomePageState {
  void saveSheetFolders() {
    sheetSidebarRevision.value++;
    if (mounted) setState(() {});
    saveActiveCampaignInMemory();
    programmaSalvataggio();
  }

  Future<String?> sheetFolderName(String title, {String initial = ''}) async {
    final controller = TextEditingController(text: initial);
    final name = await showDialog<String>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 80,
          decoration: fieldDecoration('Nome cartella'),
          onSubmitted: (value) => Navigator.pop(dialog, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, controller.text),
            child: const Text('Salva'),
          ),
        ],
      ),
    );
    // Disposal is delayed until the closing route stops using its field.
    Future<void>.delayed(const Duration(milliseconds: 350), controller.dispose);
    final cleaned = name?.trim();
    return cleaned == null || cleaned.isEmpty ? null : cleaned;
  }

  Future<String?> createSheetFolder({
    String parent = '',
    int? sheetIndex,
  }) async {
    final name = await sheetFolderName(
      parent.isEmpty ? 'Nuova cartella' : 'Nuova sottocartella',
    );
    if (!mounted || name == null) return null;
    final id = 'folder_${DateTime.now().microsecondsSinceEpoch}';
    sheetSidebarFolders.add({
      'id': id,
      'name': name,
      'parent': parent,
      'expanded': true,
    });
    if (sheetIndex != null) {
      sheetSidebarPlacements[sheetTagAt(sheetIndex)] = {
        'folder': id,
        'order': sheetIndex.toDouble(),
      };
    }
    saveSheetFolders();
    return id;
  }

  String sheetFolderPath(String id) {
    final names = <String>[];
    final seen = <String>{};
    while (id.isNotEmpty && seen.add(id)) {
      final folder = sheetSidebarFolders
          .where((f) => f['id'] == id)
          .firstOrNull;
      if (folder == null) break;
      names.insert(0, '${folder['name']}');
      id = '${folder['parent'] ?? ''}';
    }
    return names.isEmpty ? 'Tutte le schede' : names.join(' / ');
  }

  Future<void> showSheetFolderMoveMenu(int index) async {
    final destination = await showDialog<String>(
      context: context,
      builder: (dialog) => SimpleDialog(
        title: Text('Organizza ${nomeSchedaPersonaggio(index)}'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialog, '@new'),
            child: const Text('Crea una nuova cartella…'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialog, '@free'),
            child: const Text('Sposta liberamente'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialog, ''),
            child: const Text('Tutte le schede'),
          ),
          for (final folder in sheetSidebarFolders)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialog, '${folder['id']}'),
              child: Text(sheetFolderPath('${folder['id']}')),
            ),
        ],
      ),
    );
    if (!mounted || destination == null) return;
    if (destination == '@new') {
      final parent =
          '${sheetSidebarPlacements[sheetTagAt(index)]?['folder'] ?? ''}';
      await createSheetFolder(parent: parent, sheetIndex: index);
    } else if (destination == '@free') {
      sheetSidebarFreeMove = true;
      sheetSidebarRevision.value++;
      setState(() {});
    } else {
      sheetSidebarPlacements[sheetTagAt(index)] = {
        'folder': destination,
        'order': DateTime.now().millisecondsSinceEpoch.toDouble(),
      };
      saveSheetFolders();
    }
  }

  Future<void> sheetFolderMenu(Map<String, dynamic> folder) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (dialog) => SimpleDialog(
        title: Text('${folder['name']}'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialog, 'rename'),
            child: const Text('Rinomina cartella'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialog, 'new'),
            child: const Text('Crea sottocartella'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialog, 'move'),
            child: const Text('Sposta liberamente'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (choice == 'rename') {
      final name = await sheetFolderName(
        'Rinomina cartella',
        initial: '${folder['name']}',
      );
      if (!mounted || name == null) return;
      folder['name'] = name;
      saveSheetFolders();
    } else if (choice == 'new') {
      await createSheetFolder(parent: '${folder['id']}');
    } else if (choice == 'move') {
      sheetSidebarFreeMove = true;
      sheetSidebarRevision.value++;
      setState(() {});
    }
  }

  void moveSidebarEntry(String data, String folderId, {int? beforeIndex}) {
    if (data.startsWith('folder:')) {
      final id = data.substring(7);
      if (!oculumSheetFolderCanMove(sheetSidebarFolders, id, folderId)) return;
      final folder = sheetSidebarFolders
          .where((f) => f['id'] == id)
          .firstOrNull;
      if (folder == null) return;
      folder['parent'] = folderId;
    } else {
      final index = localSheetIndexForOculumTag(data);
      if (index < 0) return;
      final tag = sheetTagAt(index);
      final siblings =
          List<int>.generate(schedePersonaggio.length, (i) => i)
              .where(
                (i) =>
                    i != index &&
                    '${sheetSidebarPlacements[sheetTagAt(i)]?['folder'] ?? ''}' ==
                        folderId,
              )
              .toList()
            ..sort(
              (a, b) =>
                  readDoubleValue(
                    sheetSidebarPlacements[sheetTagAt(a)]?['order'],
                    fallback: a.toDouble(),
                  ).compareTo(
                    readDoubleValue(
                      sheetSidebarPlacements[sheetTagAt(b)]?['order'],
                      fallback: b.toDouble(),
                    ),
                  ),
            );
      final at = beforeIndex == null ? -1 : siblings.indexOf(beforeIndex);
      siblings.insert(at < 0 ? siblings.length : at, index);
      for (var i = 0; i < siblings.length; i++) {
        sheetSidebarPlacements[sheetTagAt(siblings[i])] = {
          'folder': folderId,
          'order': i.toDouble(),
        };
      }
      assert(sheetSidebarPlacements.containsKey(tag));
    }
    saveSheetFolders();
  }

  Future<void> showSheetFoldersDialog() => showDialog<void>(
    context: context,
    builder: (dialog) => AlertDialog(
      title: const Text('Schede e cartelle'),
      content: SizedBox(
        width: 420,
        height: MediaQuery.sizeOf(dialog).height * .65,
        child: sheetFolderBrowser(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialog),
          child: const Text('Chiudi'),
        ),
      ],
    ),
  );

  Widget sheetFolderBrowser() => AnimatedBuilder(
    animation: sheetSidebarRevision,
    builder: (context, _) {
      final rows = <({Map<String, dynamic>? folder, int? index, int depth})>[];
      final seen = <String>{};
      void collect(String parent, int depth) {
        if (!seen.add(parent)) return;
        for (final folder in sheetSidebarFolders.where(
          (f) => '${f['parent'] ?? ''}' == parent,
        )) {
          rows.add((folder: folder, index: null, depth: depth));
          if (folder['expanded'] != false) {
            collect('${folder['id']}', depth + 1);
          }
        }
        final indexes =
            List<int>.generate(schedePersonaggio.length, (i) => i).where((i) {
              final id =
                  '${sheetSidebarPlacements[sheetTagAt(i)]?['folder'] ?? ''}';
              final valid = sheetSidebarFolders.any((f) => f['id'] == id);
              return (valid ? id : '') == parent;
            }).toList()..sort(
              (a, b) =>
                  readDoubleValue(
                    sheetSidebarPlacements[sheetTagAt(a)]?['order'],
                    fallback: a.toDouble(),
                  ).compareTo(
                    readDoubleValue(
                      sheetSidebarPlacements[sheetTagAt(b)]?['order'],
                      fallback: b.toDouble(),
                    ),
                  ),
            );
        for (final i in indexes) {
          rows.add((folder: null, index: i, depth: depth));
        }
      }

      collect('', 0);
      Widget target(
        Widget child,
        String parent, {
        int? beforeIndex,
      }) => DragTarget<String>(
        onWillAcceptWithDetails: (_) => sheetSidebarFreeMove,
        onAcceptWithDetails: (details) =>
            moveSidebarEntry(details.data, parent, beforeIndex: beforeIndex),
        builder: (context, candidates, _) => DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: candidates.isEmpty ? Colors.transparent : tertiaryColor,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Material(type: MaterialType.transparency, child: child),
        ),
      );
      Widget draggable(Widget child, String data) => sheetSidebarFreeMove
          ? Draggable<String>(
              data: data,
              feedback: Material(
                color: backgroundMidColor,
                child: SizedBox(width: 190, child: child),
              ),
              childWhenDragging: Opacity(opacity: .3, child: child),
              child: child,
            )
          : child;
      return ListView.builder(
        key: const PageStorageKey('sheet_folders'),
        itemCount: rows.length + 1,
        itemBuilder: (context, row) {
          if (row == 0) {
            return target(
              Row(
                children: [
                  Expanded(
                    child: Text(
                      sheetSidebarFreeMove
                          ? 'Trascina per spostare'
                          : 'Tutte le schede',
                      style: TextStyle(color: tertiaryColor, fontSize: 11),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Nuova cartella',
                    icon: const Icon(
                      Icons.create_new_folder_outlined,
                      size: 18,
                    ),
                    onPressed: () => createSheetFolder(),
                  ),
                  if (sheetSidebarFreeMove)
                    IconButton(
                      tooltip: 'Fine spostamento',
                      icon: const Icon(Icons.check, size: 18),
                      onPressed: () {
                        sheetSidebarFreeMove = false;
                        sheetSidebarRevision.value++;
                        setState(() {});
                      },
                    ),
                ],
              ),
              '',
            );
          }
          final item = rows[row - 1];
          if (item.folder != null) {
            final folder = item.folder!;
            final tile = ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              leading: Icon(
                folder['expanded'] == false
                    ? Icons.folder_outlined
                    : Icons.folder_open,
                color: tertiaryColor,
                size: 19,
              ),
              title: Text(
                '${folder['name']}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                tooltip: 'Gestisci cartella',
                icon: const Icon(Icons.more_horiz, size: 16),
                onPressed: () => sheetFolderMenu(folder),
              ),
              onTap: () {
                folder['expanded'] = folder['expanded'] == false;
                saveSheetFolders();
              },
              onLongPress: sheetSidebarFreeMove
                  ? null
                  : () => sheetFolderMenu(folder),
            );
            return Padding(
              padding: EdgeInsets.only(left: min(item.depth * 10.0, 40)),
              child: target(
                draggable(
                  GestureDetector(
                    onSecondaryTap: () => sheetFolderMenu(folder),
                    child: tile,
                  ),
                  'folder:${folder['id']}',
                ),
                '${folder['id']}',
              ),
            );
          }
          final i = item.index!;
          final parent =
              '${sheetSidebarPlacements[sheetTagAt(i)]?['folder'] ?? ''}';
          final tile = GestureDetector(
            onSecondaryTapDown: (details) => mostraMenuSchedaPersonaggio(
              index: i,
              position: details.globalPosition,
            ),
            child: ListTile(
              dense: true,
              selected: schedaCorrente == i,
              selectedTileColor: primaryColor.withValues(alpha: .1),
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              leading: Icon(
                sheetSidebarFreeMove
                    ? Icons.drag_indicator
                    : Icons.person_outline,
                size: 18,
                color: schedaCorrente == i ? tertiaryColor : Colors.grey,
              ),
              title: Text(
                cleanUiText(nomeSchedaPersonaggio(i)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                cleanUiText(tipoSchedaPersonaggio(i)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => cambiaSchedaPersonaggio(i),
              onLongPress: sheetSidebarFreeMove
                  ? null
                  : () => showSheetFolderMoveMenu(i),
            ),
          );
          return Padding(
            padding: EdgeInsets.only(left: min(item.depth * 10.0, 40)),
            child: target(
              draggable(tile, sheetTagAt(i)),
              parent,
              beforeIndex: i,
            ),
          );
        },
      );
    },
  );
}
