part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member, unused_element

extension _OculumVttPanels on _OculumHomePageState {
  Widget vttContextMenuAnchor({
    required Widget child,
    required Future<void> Function(Offset globalPosition) onOpen,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onSecondaryTapDown: (details) => onOpen(details.globalPosition),
      onLongPressStart: (details) => onOpen(details.globalPosition),
      child: child,
    );
  }

  List<OculumVttScene> orderedVttScenes({bool includeArchived = false}) {
    final scenes = vttState.scenes
        .where((scene) => includeArchived || !scene.archived)
        .toList(growable: false);
    scenes.sort((a, b) {
      final collection = a.collectionName.toLowerCase().compareTo(
        b.collectionName.toLowerCase(),
      );
      if (collection != 0) return collection;
      final order = a.sortOrder.compareTo(b.sortOrder);
      return order != 0 ? order : a.name.compareTo(b.name);
    });
    return scenes;
  }

  Widget vttSceneManagerPanel() {
    final scenes = orderedVttScenes();
    final active = vttSceneForDisplay();
    final remote = vttShowingRemoteScene;
    return gothicPanel(
      borderColor: tertiaryColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.layers, color: tertiaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t('Luoghi e scene', 'Places and scenes'),
                  style: TextStyle(
                    color: tertiaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (vttCanManageMap) ...<Widget>[
                IconButton(
                  tooltip: t('Nuova scena', 'New scene'),
                  onPressed: showCreateVttSceneDialog,
                  icon: const Icon(Icons.add),
                ),
                IconButton(
                  tooltip: t('Duplica scena', 'Duplicate scene'),
                  onPressed: () => showCreateVttSceneDialog(duplicate: true),
                  icon: const Icon(Icons.copy),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          if (remote)
            ListTile(
              dense: true,
              leading: const Icon(Icons.cast_connected),
              title: Text(active.name),
              subtitle: Text(
                '${active.collectionName}${active.levelName.isEmpty ? '' : ' / ${active.levelName}'}',
              ),
              trailing:
                  realtimeVttAssetProgress < 1 &&
                      realtimeVisibleVttAssetId.isNotEmpty
                  ? SizedBox(
                      width: 76,
                      child: LinearProgressIndicator(
                        value: realtimeVttAssetProgress <= 0
                            ? null
                            : realtimeVttAssetProgress,
                      ),
                    )
                  : const Icon(Icons.visibility),
            )
          else
            DropdownButtonFormField<String>(
              initialValue:
                  scenes.any((scene) => scene.id == vttState.activeSceneId)
                  ? vttState.activeSceneId
                  : null,
              isExpanded: true,
              decoration: fieldDecoration(t('Scena attiva', 'Active scene')),
              items: <DropdownMenuItem<String>>[
                for (final scene in scenes)
                  DropdownMenuItem<String>(
                    value: scene.id,
                    child: vttContextMenuAnchor(
                      onOpen: (position) =>
                          showVttSceneContextMenu(scene, position),
                      child: Row(
                        children: <Widget>[
                          Icon(
                            scene.visibleToPlayers
                                ? Icons.visibility
                                : Icons.visibility_off,
                            size: 16,
                            color: scene.isPrimary
                                ? tertiaryColor
                                : Colors.white60,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${scene.collectionName} / ${scene.name}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
              onChanged: (value) {
                if (value != null) activateVttScene(value);
              },
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Chip(
                avatar: const Icon(Icons.place, size: 16),
                label: Text(active.collectionName),
              ),
              if (active.category.isNotEmpty)
                Chip(
                  avatar: const Icon(Icons.category_outlined, size: 16),
                  label: Text(active.category),
                ),
              if (active.levelName.isNotEmpty)
                Chip(
                  avatar: const Icon(Icons.stairs, size: 16),
                  label: Text(active.levelName),
                ),
              if (vttCanManageMap)
                IconButton.filledTonal(
                  tooltip: t('Modifica scena', 'Edit scene'),
                  onPressed: () => showEditVttSceneDialog(activeVttScene),
                  icon: const Icon(Icons.edit),
                ),
              if (modalitaMaster && realtimeService?.isConnected == true)
                FilledButton.icon(
                  onPressed: vttPublishing
                      ? null
                      : () => unawaited(
                          publishActiveVttScene(includeAsset: true),
                        ),
                  icon: Icon(vttPublishing ? Icons.sync : Icons.cast),
                  label: Text(t('Mostra ai giocatori', 'Show players')),
                ),
              if (!modalitaMaster && realtimeService?.isConnected == true)
                OutlinedButton.icon(
                  onPressed: requestRealtimeVttScene,
                  icon: const Icon(Icons.refresh),
                  label: Text(t('Aggiorna scena', 'Refresh scene')),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> showCreateVttSceneDialog({bool duplicate = false}) async {
    if (!vttCanManageMap) return;
    final nameController = TextEditingController(
      text: duplicate ? '${activeVttScene.name} - copia' : '',
    );
    final placeController = TextEditingController(
      text: activeVttScene.collectionName,
    );
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          duplicate
              ? t('Duplica scena', 'Duplicate scene')
              : t('Nuova scena', 'New scene'),
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: nameController,
                autofocus: true,
                maxLength: 100,
                decoration: fieldDecoration(t('Nome scena', 'Scene name')),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: placeController,
                maxLength: 100,
                decoration: fieldDecoration(
                  t('Luogo o raccolta', 'Place or collection'),
                ),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(t('Annulla', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, <String, String>{
              'name': nameController.text,
              'place': placeController.text,
            }),
            child: Text(t('Crea', 'Create')),
          ),
        ],
      ),
    );
    nameController.dispose();
    placeController.dispose();
    if (!mounted || result == null) return;
    createVttScene(
      name: result['name'] ?? '',
      collectionName: result['place'],
      duplicateActive: duplicate,
    );
  }

  Future<void> showEditVttSceneDialog(OculumVttScene scene) async {
    if (!vttCanManageMap) return;
    final nameController = TextEditingController(text: scene.name);
    final placeController = TextEditingController(text: scene.collectionName);
    final categoryController = TextEditingController(text: scene.category);
    final levelController = TextEditingController(text: scene.levelName);
    final descriptionController = TextEditingController(
      text: scene.description,
    );
    final tagsController = TextEditingController(text: scene.tags.join(', '));
    var visible = scene.visibleToPlayers;
    var primary = scene.isPrimary;
    var archived = scene.archived;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(t('Modifica scena', 'Edit scene')),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    controller: nameController,
                    decoration: fieldDecoration(t('Nome scena', 'Scene name')),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: placeController,
                    decoration: fieldDecoration(
                      t('Luogo o raccolta', 'Place or collection'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          controller: categoryController,
                          decoration: fieldDecoration(
                            t('Categoria', 'Category'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: levelController,
                          decoration: fieldDecoration(
                            t('Piano o livello', 'Floor or level'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: tagsController,
                    decoration: fieldDecoration(
                      t('Tag separati da virgola', 'Comma-separated tags'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: fieldDecoration(
                      t('Descrizione', 'Description'),
                    ),
                  ),
                  SwitchListTile.adaptive(
                    value: visible,
                    onChanged: (value) => setDialogState(() => visible = value),
                    title: Text(
                      t('Visibile ai giocatori', 'Visible to players'),
                    ),
                  ),
                  SwitchListTile.adaptive(
                    value: primary,
                    onChanged: (value) => setDialogState(() => primary = value),
                    title: Text(
                      t('Scena principale del luogo', 'Primary place scene'),
                    ),
                  ),
                  SwitchListTile.adaptive(
                    value: archived,
                    onChanged: (value) =>
                        setDialogState(() => archived = value),
                    title: Text(t('Archiviata', 'Archived')),
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(t('Annulla', 'Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, <String, dynamic>{
                'name': nameController.text.trim(),
                'place': placeController.text.trim(),
                'category': categoryController.text.trim(),
                'level': levelController.text.trim(),
                'description': descriptionController.text.trim(),
                'tags': tagsController.text,
                'visible': visible,
                'primary': primary,
                'archived': archived,
              }),
              child: Text(t('Salva', 'Save')),
            ),
          ],
        ),
      ),
    );
    for (final controller in <TextEditingController>[
      nameController,
      placeController,
      categoryController,
      levelController,
      descriptionController,
      tagsController,
    ]) {
      controller.dispose();
    }
    if (!mounted || result == null) return;
    final oldPlace = scene.collectionName;
    mutateActiveVttScene((active) {
      active.name = '${result['name']}'.trim().isEmpty
          ? active.name
          : '${result['name']}'.trim();
      final nextPlace = '${result['place']}'.trim();
      if (nextPlace.isNotEmpty && nextPlace != oldPlace) {
        final existing = vttState.scenes.where(
          (candidate) =>
              candidate.collectionName.toLowerCase() == nextPlace.toLowerCase(),
        );
        active.collectionName = nextPlace;
        active.collectionId = existing.isEmpty
            ? oculumVttGenerateId('place')
            : existing.first.collectionId;
      }
      active.category = '${result['category']}';
      active.levelName = '${result['level']}';
      active.description = '${result['description']}';
      active.tags = '${result['tags']}'
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toSet()
          .take(40)
          .toList();
      active.visibleToPlayers = result['visible'] == true;
      active.archived = result['archived'] == true;
      if (result['primary'] == true) {
        for (final candidate in vttState.scenes) {
          if (candidate.collectionId == active.collectionId) {
            candidate.isPrimary = candidate.id == active.id;
          }
        }
      } else {
        active.isPrimary = false;
      }
    }, includeAsset: true);
    vttState.normalize();
    setState(() {});
  }

  Future<void> showVttSceneContextMenu(
    OculumVttScene scene,
    Offset globalPosition,
  ) async {
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;
    final choice = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(globalPosition, globalPosition),
        Offset.zero & overlay.size,
      ),
      items: <PopupMenuEntry<String>>[
        PopupMenuItem(
          value: 'open',
          child: ListTile(
            leading: const Icon(Icons.open_in_new),
            title: Text(t('Apri scena', 'Open scene')),
          ),
        ),
        if (vttCanManageMap) ...<PopupMenuEntry<String>>[
          PopupMenuItem(
            value: 'edit',
            child: ListTile(
              leading: const Icon(Icons.edit),
              title: Text(t('Modifica', 'Edit')),
            ),
          ),
          PopupMenuItem(
            value: 'duplicate',
            child: ListTile(
              leading: const Icon(Icons.copy),
              title: Text(t('Duplica', 'Duplicate')),
            ),
          ),
          PopupMenuItem(
            value: 'up',
            child: ListTile(
              leading: const Icon(Icons.arrow_upward),
              title: Text(t('Sposta prima', 'Move earlier')),
            ),
          ),
          PopupMenuItem(
            value: 'down',
            child: ListTile(
              leading: const Icon(Icons.arrow_downward),
              title: Text(t('Sposta dopo', 'Move later')),
            ),
          ),
          PopupMenuItem(
            value: 'archive',
            child: ListTile(
              leading: Icon(scene.archived ? Icons.unarchive : Icons.archive),
              title: Text(
                scene.archived
                    ? t('Ripristina', 'Restore')
                    : t('Archivia', 'Archive'),
              ),
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem(
            value: 'delete',
            enabled: vttState.scenes.length > 1,
            child: ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(t('Elimina', 'Delete')),
            ),
          ),
        ],
      ],
    );
    if (!mounted || choice == null) return;
    switch (choice) {
      case 'open':
        activateVttScene(scene.id);
        break;
      case 'edit':
        if (scene.id != vttState.activeSceneId) {
          activateVttScene(scene.id);
        }
        await showEditVttSceneDialog(scene);
        break;
      case 'duplicate':
        if (scene.id != vttState.activeSceneId) activateVttScene(scene.id);
        createVttScene(name: '${scene.name} - copia', duplicateActive: true);
        break;
      case 'up':
        moveVttScene(scene, -1);
        break;
      case 'down':
        moveVttScene(scene, 1);
        break;
      case 'archive':
        archiveVttScene(scene, !scene.archived);
        break;
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(t('Eliminare la scena?', 'Delete scene?')),
            content: Text(scene.name),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(t('Annulla', 'Cancel')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(t('Elimina', 'Delete')),
              ),
            ],
          ),
        );
        if (confirmed == true) deleteVttScene(scene);
        break;
    }
  }

  Widget vttToolbarPanel() {
    final tools = <OculumVttTool>[
      OculumVttTool.pan,
      OculumVttTool.select,
      OculumVttTool.ruler,
      if (vttModuleEnabled('annotations')) ...<OculumVttTool>[
        OculumVttTool.line,
        OculumVttTool.rectangle,
        OculumVttTool.circle,
        OculumVttTool.cone,
        OculumVttTool.note,
      ],
      if (vttModuleEnabled('ping')) OculumVttTool.ping,
      if (vttModuleEnabled('fog')) ...<OculumVttTool>[
        OculumVttTool.fogReveal,
        OculumVttTool.fogHide,
      ],
      if (vttModuleEnabled('walls_doors')) ...<OculumVttTool>[
        OculumVttTool.wall,
        OculumVttTool.door,
      ],
      if (vttModuleEnabled('lights')) OculumVttTool.light,
      if (vttModuleEnabled('triggers')) OculumVttTool.trigger,
      OculumVttTool.erase,
    ];
    return gothicPanel(
      borderColor: primaryColor,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                for (final tool in tools)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: IconButton(
                      tooltip: vttToolLabel(tool),
                      onPressed:
                          (vttShowingRemoteScene &&
                                  tool != OculumVttTool.ping) ||
                              !vttCanSelectTool(tool)
                          ? null
                          : () {
                              setState(() => vttTool = tool);
                              vttCanvasRevision.value++;
                            },
                      style: IconButton.styleFrom(
                        backgroundColor: vttTool == tool
                            ? primaryColor.withValues(alpha: 0.36)
                            : null,
                        foregroundColor: vttTool == tool
                            ? Colors.white
                            : Colors.white70,
                      ),
                      icon: Icon(vttToolIcon(tool)),
                    ),
                  ),
                const VerticalDivider(width: 12),
                IconButton(
                  tooltip: t('Annulla', 'Undo'),
                  onPressed: vttUndoHistory.isEmpty ? null : undoVttChange,
                  icon: const Icon(Icons.undo),
                ),
                IconButton(
                  tooltip: t('Ripristina', 'Redo'),
                  onPressed: vttRedoHistory.isEmpty ? null : redoVttChange,
                  icon: const Icon(Icons.redo),
                ),
                IconButton(
                  tooltip: t('Cancella misura', 'Clear measurement'),
                  onPressed: vttMeasurePoints.isEmpty
                      ? null
                      : () {
                          vttMeasurePoints.clear();
                          vttCanvasRevision.value++;
                        },
                  icon: const Icon(Icons.clear_all),
                ),
                IconButton(
                  tooltip: t('Griglia e scala', 'Grid and scale'),
                  onPressed: vttCanManageMap ? showVttGridSettingsDialog : null,
                  icon: const Icon(Icons.grid_4x4),
                ),
                IconButton(
                  tooltip: t('Moduli mappa', 'Map modules'),
                  onPressed: vttCanManageMap ? showVttModulesDialog : null,
                  icon: const Icon(Icons.extension),
                ),
                IconButton(
                  tooltip: t('Permessi', 'Permissions'),
                  onPressed: modalitaMaster ? showVttPermissionsDialog : null,
                  icon: const Icon(Icons.admin_panel_settings),
                ),
              ],
            ),
          ),
          if (vttCanManageMap && vttModuleEnabled('fog')) ...<Widget>[
            const Divider(height: 10),
            Row(
              children: <Widget>[
                Icon(Icons.visibility, size: 16, color: tertiaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: vttFogAudience,
                    isExpanded: true,
                    decoration: fieldDecoration(t('Nebbia per', 'Fog for')),
                    items: <DropdownMenuItem<String>>[
                      DropdownMenuItem(
                        value: 'party',
                        child: Text(t('Party condiviso', 'Shared party')),
                      ),
                      for (final tag
                          in realtimeUsers
                              .map(
                                (user) => normalizeOculumFriendTag(
                                  '${user['activeSheetTag'] ?? ''}',
                                ),
                              )
                              .where((tag) => tag.isNotEmpty)
                              .toSet())
                        DropdownMenuItem(value: tag, child: Text(tag)),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => vttFogAudience = value);
                      vttCanvasRevision.value++;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Switch.adaptive(
                  value: activeVttScene.fogEnabled,
                  onChanged: (value) =>
                      mutateActiveVttScene((scene) => scene.fogEnabled = value),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> showVttGridSettingsDialog() async {
    final scene = activeVttScene;
    var gridType = scene.gridType;
    var gridSize = scene.gridSizePx;
    var distance = scene.distancePerCell;
    var unit = scene.distanceUnit;
    var diagonal = scene.diagonalRule;
    var snap = scene.snapToGrid;
    var showCoordinates = scene.showCoordinates;
    var lockAspectRatio = scene.lockAspectRatio;
    var rotation = scene.rotationDegrees;
    var widthMeters = scene.widthMeters;
    var heightMeters = scene.heightMeters;
    final aspectRatio = scene.widthMeters / max(1.0, scene.heightMeters);
    final widthController = TextEditingController(
      text: _oculumVttCompactNumber(widthMeters),
    );
    final heightController = TextEditingController(
      text: _oculumVttCompactNumber(heightMeters),
    );
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(t('Griglia e misure', 'Grid and measurement')),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SegmentedButton<String>(
                    segments: <ButtonSegment<String>>[
                      ButtonSegment(
                        value: 'none',
                        label: Text(t('Nessuna', 'None')),
                      ),
                      ButtonSegment(
                        value: 'square',
                        label: Text(t('Quadrata', 'Square')),
                      ),
                      ButtonSegment(
                        value: 'hex',
                        label: Text(t('Esagonale', 'Hex')),
                      ),
                    ],
                    selected: <String>{gridType},
                    onSelectionChanged: (selection) =>
                        setDialogState(() => gridType = selection.first),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${t('Dimensione cella', 'Cell size')}: ${gridSize.round()} px',
                  ),
                  Slider(
                    value: gridSize.clamp(12, 256),
                    min: 12,
                    max: 256,
                    divisions: 61,
                    onChanged: (value) =>
                        setDialogState(() => gridSize = value),
                  ),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextFormField(
                          initialValue: _oculumVttCompactNumber(distance),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: fieldDecoration(
                            t('Distanza per cella', 'Distance per cell'),
                          ),
                          onChanged: (value) => distance =
                              double.tryParse(value.replaceAll(',', '.')) ??
                              distance,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: unit,
                          decoration: fieldDecoration(t('Unita', 'Unit')),
                          items: const <DropdownMenuItem<String>>[
                            DropdownMenuItem(value: 'cm', child: Text('cm')),
                            DropdownMenuItem(value: 'm', child: Text('m')),
                            DropdownMenuItem(value: 'km', child: Text('km')),
                            DropdownMenuItem(
                              value: 'cells',
                              child: Text('celle'),
                            ),
                          ],
                          onChanged: (value) => unit = value ?? unit,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: diagonal,
                    decoration: fieldDecoration(t('Diagonali', 'Diagonals')),
                    items: <DropdownMenuItem<String>>[
                      DropdownMenuItem(
                        value: 'euclidean',
                        child: Text(t('Euclidea', 'Euclidean')),
                      ),
                      DropdownMenuItem(
                        value: 'chebyshev',
                        child: Text(t('Una cella', 'One cell')),
                      ),
                      DropdownMenuItem(
                        value: 'alternating',
                        child: Text(t('Alternata', 'Alternating')),
                      ),
                      DropdownMenuItem(
                        value: 'manhattan',
                        child: Text(t('Ortogonale', 'Orthogonal')),
                      ),
                    ],
                    onChanged: (value) => diagonal = value ?? diagonal,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          controller: widthController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: fieldDecoration(
                            t('Larghezza mappa', 'Map width'),
                          ),
                          onChanged: (value) {
                            final parsed = double.tryParse(
                              value.replaceAll(',', '.'),
                            );
                            if (parsed == null || parsed <= 0) return;
                            widthMeters = parsed;
                            if (lockAspectRatio) {
                              heightMeters = parsed / aspectRatio;
                              heightController.text = _oculumVttCompactNumber(
                                heightMeters,
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: heightController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: fieldDecoration(
                            t('Altezza mappa', 'Map height'),
                          ),
                          onChanged: (value) {
                            final parsed = double.tryParse(
                              value.replaceAll(',', '.'),
                            );
                            if (parsed == null || parsed <= 0) return;
                            heightMeters = parsed;
                            if (lockAspectRatio) {
                              widthMeters = parsed * aspectRatio;
                              widthController.text = _oculumVttCompactNumber(
                                widthMeters,
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  SwitchListTile.adaptive(
                    value: snap,
                    onChanged: (value) => setDialogState(() => snap = value),
                    title: Text(t('Snap alla griglia', 'Snap to grid')),
                  ),
                  SwitchListTile.adaptive(
                    value: showCoordinates,
                    onChanged: (value) =>
                        setDialogState(() => showCoordinates = value),
                    title: Text(t('Mostra coordinate', 'Show coordinates')),
                  ),
                  SwitchListTile.adaptive(
                    value: lockAspectRatio,
                    onChanged: (value) =>
                        setDialogState(() => lockAspectRatio = value),
                    title: Text(t('Blocca proporzioni', 'Lock aspect ratio')),
                  ),
                  Text(
                    '${t('Rotazione', 'Rotation')}: ${rotation.round()} deg',
                  ),
                  Slider(
                    value: rotation.clamp(-180, 180),
                    min: -180,
                    max: 180,
                    divisions: 72,
                    onChanged: (value) =>
                        setDialogState(() => rotation = value),
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(t('Annulla', 'Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(t('Applica', 'Apply')),
            ),
          ],
        ),
      ),
    );
    widthController.dispose();
    heightController.dispose();
    if (result != true || !mounted) return;
    mutateActiveVttScene((active) {
      active.gridType = gridType;
      active.gridSizePx = gridSize.clamp(12, 512);
      active.distancePerCell = distance.clamp(0.001, 100000);
      active.distanceUnit = unit;
      active.diagonalRule = diagonal;
      active.snapToGrid = snap;
      active.showCoordinates = showCoordinates;
      active.lockAspectRatio = lockAspectRatio;
      active.rotationDegrees = rotation.clamp(-180, 180);
      active.widthMeters = widthMeters.clamp(1, 1000000);
      active.heightMeters = heightMeters.clamp(1, 1000000);
    });
    applyVttSceneToLegacyMapState(activeVttScene);
    setState(() {});
  }

  Future<void> showVttModulesDialog() async {
    final working = Map<String, bool>.from(vttState.modules);
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(t('Moduli mappa', 'Map modules')),
          content: SizedBox(
            width: 480,
            height: min(560, MediaQuery.of(context).size.height * 0.65),
            child: ListView(
              children: <Widget>[
                for (final entry in working.entries)
                  SwitchListTile.adaptive(
                    value: entry.value,
                    onChanged: (value) =>
                        setDialogState(() => working[entry.key] = value),
                    title: Text(vttModuleLabel(entry.key)),
                  ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(t('Annulla', 'Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(t('Salva', 'Save')),
            ),
          ],
        ),
      ),
    );
    if (result != true || !mounted) return;
    setState(() {
      vttState.modules
        ..clear()
        ..addAll(working);
    });
    vttCanvasRevision.value++;
    programmaSalvataggio(invalidateCaches: false);
    scheduleVttRealtimePublish();
  }

  String vttModuleLabel(String key) {
    return <String, String>{
          'advanced_measurement': t(
            'Misurazione avanzata',
            'Advanced measurement',
          ),
          'fog': t('Nebbia di guerra', 'Fog of war'),
          'dynamic_vision': t('Visione dinamica', 'Dynamic vision'),
          'walls_doors': t('Muri e porte', 'Walls and doors'),
          'initiative': t('Iniziativa', 'Initiative'),
          'combat': t('Combattimento', 'Combat'),
          'conditions': t('Condizioni', 'Conditions'),
          'areas': t('Aree di effetto', 'Areas of effect'),
          'ping': 'Ping',
          'annotations': t('Annotazioni', 'Annotations'),
          'lights': t('Luci', 'Lights'),
          'triggers': t('Trigger e zone', 'Triggers and zones'),
          'ambient_audio': t('Audio ambientale', 'Ambient audio'),
          'random_tables': t('Tabelle casuali', 'Random tables'),
          'calendar_weather': t('Calendario e meteo', 'Calendar and weather'),
        }[key] ??
        key;
  }

  Future<void> showVttPermissionsDialog() async {
    final working = <String, Map<String, bool>>{
      for (final entry in vttState.permissions.entries)
        entry.key: Map<String, bool>.from(entry.value),
    };
    var selectedRole = 'player';
    const permissions = <String>[
      'view',
      'tokens',
      'doors',
      'sheets',
      'stats',
      'notes',
      'chat',
      'rolls',
      'scene',
      'map',
      'audio',
      'ping',
      'tools',
      'bestiary',
      'manual',
      'secret_images',
    ];
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(t('Permessi mappa', 'Map permissions')),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    decoration: fieldDecoration(t('Ruolo', 'Role')),
                    items: <DropdownMenuItem<String>>[
                      for (final role in <String>[
                        'master',
                        'co_master',
                        'player',
                        'observer',
                      ])
                        DropdownMenuItem(value: role, child: Text(role)),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedRole = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final itemWidth = constraints.maxWidth >= 520
                          ? (constraints.maxWidth - 8) / 2
                          : constraints.maxWidth;
                      return Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: <Widget>[
                          for (final permission in permissions)
                            SizedBox(
                              width: itemWidth,
                              child: SwitchListTile.adaptive(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                value:
                                    working[selectedRole]?[permission] ?? false,
                                onChanged: selectedRole == 'master'
                                    ? null
                                    : (value) => setDialogState(
                                        () =>
                                            working[selectedRole]![permission] =
                                                value,
                                      ),
                                title: Text(vttPermissionLabel(permission)),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(t('Annulla', 'Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(t('Salva', 'Save')),
            ),
          ],
        ),
      ),
    );
    if (result != true || !mounted) return;
    setState(() => vttState.permissions = working);
    programmaSalvataggio(invalidateCaches: false);
    scheduleVttRealtimePublish();
  }

  String vttPermissionLabel(String permission) =>
      <String, String>{
        'view': t('Vedere la mappa', 'View map'),
        'tokens': t('Muovere pedine', 'Move tokens'),
        'doors': t('Aprire porte', 'Open doors'),
        'sheets': t('Modificare schede', 'Edit sheets'),
        'stats': t('Vedere statistiche', 'View stats'),
        'notes': t('Vedere note', 'View notes'),
        'chat': t('Usare chat', 'Use chat'),
        'rolls': t('Usare tiri', 'Use rolls'),
        'scene': t('Cambiare scena', 'Change scene'),
        'map': t('Modificare mappa', 'Edit map'),
        'audio': t('Controllare audio', 'Control audio'),
        'ping': t('Creare ping', 'Create pings'),
        'tools': t('Usare strumenti', 'Use tools'),
        'bestiary': t('Accedere al bestiario', 'Access bestiary'),
        'manual': t('Accedere al manuale', 'Access manual'),
        'secret_images': t('Vedere immagini segrete', 'View secret images'),
      }[permission] ??
      permission;
}
