import 'dart:convert';

/// Moves saved sheets and the campaign-owned records that point at them.
/// The input snapshots are never mutated, so callers can persist both sides
/// together after the transfer succeeds.
Map<String, Map<String, dynamic>> moveOculumCampaignSheets({
  required Map<String, dynamic> source,
  required Map<String, dynamic> destination,
  required Set<String> sheetTags,
}) {
  final selectedTags = sheetTags
      .map((tag) => tag.trim().toUpperCase())
      .where((tag) => tag.isNotEmpty)
      .toSet();
  if (selectedTags.isEmpty) throw ArgumentError('No sheets selected.');
  if ('${source['id'] ?? ''}' == '${destination['id'] ?? ''}') {
    throw ArgumentError('The destination must be another campaign.');
  }

  final from = _cloneMap(source);
  final to = _cloneMap(destination);
  final sourceSheets = _mapList(from['schedePersonaggio']);
  final destinationSheets = _mapList(to['schedePersonaggio']);
  final movedSheets = sourceSheets
      .where((sheet) => selectedTags.contains(_sheetTag(sheet)))
      .toList(growable: false);
  final foundTags = movedSheets.map(_sheetTag).toSet();
  if (foundTags.length != selectedTags.length ||
      !foundTags.containsAll(selectedTags)) {
    throw StateError('A selected sheet is no longer in the source campaign.');
  }
  final destinationTags = destinationSheets.map(_sheetTag).toSet();
  if (movedSheets.any((sheet) => destinationTags.contains(_sheetTag(sheet)))) {
    throw StateError('The destination already contains one of these sheets.');
  }

  from['schedePersonaggio'] = sourceSheets
      .where((sheet) => !selectedTags.contains(_sheetTag(sheet)))
      .toList();
  final destinationSheetStart = destinationSheets.length;
  to['schedePersonaggio'] = [...destinationSheets, ...movedSheets];
  from['schedaCorrente'] = _clampIndex(
    from['schedaCorrente'],
    sourceSheets.length - movedSheets.length,
  );
  to['schedaCorrente'] = destinationSheetStart;

  _moveOwnedList(from, to, 'occhiCaduti', selectedTags, const ['ownerSheetId']);
  _moveOwnedList(from, to, 'localMapTokens', selectedTags, const [
    'sheetTag',
    'ownerTag',
  ]);
  _moveOwnedList(from, to, 'pawnGuardians', selectedTags, const ['ownerTag']);
  _moveOwnedList(
    from,
    to,
    'temporaryCombatResistanceEffects',
    selectedTags,
    const ['ownerSheetId'],
  );
  _moveSheetFolderPlacements(from, to, selectedTags);
  _movePawnReceipts(from, to, selectedTags);

  final pending = from['pawnPendingDamage'];
  if (pending is Map &&
      selectedTags.contains(_normalizedTag(pending['sheetTag'])) &&
      (to['pawnPendingDamage'] is! Map ||
          (to['pawnPendingDamage'] as Map).isEmpty)) {
    to['pawnPendingDamage'] = _cloneMap(Map<String, dynamic>.from(pending));
    from['pawnPendingDamage'] = <String, dynamic>{};
  }

  return {'source': from, 'destination': to};
}

String _sheetTag(Map<String, dynamic> sheet) =>
    _normalizedTag(sheet['sheetTag'] ?? sheet['id']);

String _normalizedTag(Object? value) => '$value'.trim().toUpperCase();

int _clampIndex(Object? value, int sheetCount) {
  if (sheetCount <= 0) return 0;
  final index = value is num ? value.toInt() : int.tryParse('$value') ?? 0;
  return index.clamp(0, sheetCount - 1);
}

Map<String, dynamic> _cloneMap(Map<String, dynamic> value) =>
    Map<String, dynamic>.from(jsonDecode(jsonEncode(value)) as Map);

List<Map<String, dynamic>> _mapList(Object? value) => value is List
    ? value.whereType<Map>().map((entry) => _cloneMap(Map.from(entry))).toList()
    : <Map<String, dynamic>>[];

void _moveOwnedList(
  Map<String, dynamic> source,
  Map<String, dynamic> destination,
  String field,
  Set<String> tags,
  List<String> ownerFields,
) {
  final records = _mapList(source[field]);
  if (records.isEmpty) return;
  final moved = <Map<String, dynamic>>[];
  final remaining = <Map<String, dynamic>>[];
  for (final record in records) {
    final belongsToMovedSheet = ownerFields.any(
      (ownerField) => tags.contains(_normalizedTag(record[ownerField])),
    );
    (belongsToMovedSheet ? moved : remaining).add(record);
  }
  if (moved.isEmpty) return;
  source[field] = remaining;
  destination[field] = [..._mapList(destination[field]), ...moved];
}

void _moveSheetFolderPlacements(
  Map<String, dynamic> source,
  Map<String, dynamic> destination,
  Set<String> tags,
) {
  final sourcePlacements = source['sheetSidebarPlacements'];
  if (sourcePlacements is! Map) return;
  final movedPlacements = <String, Map<String, dynamic>>{};
  for (final tag in tags) {
    final placement =
        sourcePlacements[tag] ?? sourcePlacements[tag.toLowerCase()];
    if (placement is Map) {
      movedPlacements[tag] = _cloneMap(Map<String, dynamic>.from(placement));
    }
  }
  if (movedPlacements.isEmpty) return;

  final targetPlacements = destination['sheetSidebarPlacements'] is Map
      ? Map<String, dynamic>.from(destination['sheetSidebarPlacements'] as Map)
      : <String, dynamic>{};
  final sourceFolders = _mapList(source['sheetSidebarFolders']);
  final targetFolders = _mapList(destination['sheetSidebarFolders']);
  final sourceById = <String, Map<String, dynamic>>{
    for (final folder in sourceFolders)
      if ('${folder['id'] ?? ''}'.isNotEmpty) '${folder['id']}': folder,
  };
  final targetById = <String, Map<String, dynamic>>{
    for (final folder in targetFolders)
      if ('${folder['id'] ?? ''}'.isNotEmpty) '${folder['id']}': folder,
  };
  final neededIds = <String>{};
  for (final placement in movedPlacements.values) {
    var id = '${placement['folder'] ?? ''}';
    final seen = <String>{};
    while (id.isNotEmpty && seen.add(id)) {
      neededIds.add(id);
      id = '${sourceById[id]?['parent'] ?? ''}';
    }
  }

  final remappedIds = <String, String>{};
  for (final id in neededIds) {
    final sourceFolder = sourceById[id];
    if (sourceFolder == null) continue;
    final existing = targetById[id];
    if (existing == null || _folderEquivalent(existing, sourceFolder)) {
      remappedIds[id] = id;
      continue;
    }
    var suffix = 1;
    var nextId = '${id}_moved_$suffix';
    while (targetById.containsKey(nextId) || sourceById.containsKey(nextId)) {
      suffix++;
      nextId = '${id}_moved_$suffix';
    }
    remappedIds[id] = nextId;
  }
  for (final id in neededIds) {
    final folder = sourceById[id];
    if (folder == null) continue;
    final mappedId = remappedIds[id] ?? id;
    if (targetById.containsKey(mappedId)) continue;
    final parent = '${folder['parent'] ?? ''}';
    final copy = _cloneMap(folder)
      ..['id'] = mappedId
      ..['parent'] = remappedIds[parent] ?? parent;
    targetFolders.add(copy);
    targetById[mappedId] = copy;
  }
  for (final entry in movedPlacements.entries) {
    final folder = '${entry.value['folder'] ?? ''}';
    entry.value['folder'] = remappedIds[folder] ?? folder;
    targetPlacements[entry.key] = entry.value;
    sourcePlacements.remove(entry.key);
    sourcePlacements.remove(entry.key.toLowerCase());
  }
  destination['sheetSidebarPlacements'] = targetPlacements;
  destination['sheetSidebarFolders'] = targetFolders;
  source['sheetSidebarPlacements'] = Map<String, dynamic>.from(
    sourcePlacements,
  );
}

bool _folderEquivalent(Map<String, dynamic> left, Map<String, dynamic> right) =>
    '${left['name'] ?? ''}' == '${right['name'] ?? ''}' &&
    '${left['parent'] ?? ''}' == '${right['parent'] ?? ''}';

void _movePawnReceipts(
  Map<String, dynamic> source,
  Map<String, dynamic> destination,
  Set<String> tags,
) {
  final sourceReceipts = source['pawnDamageReceipts'];
  if (sourceReceipts is! Map) return;
  final targetReceipts = destination['pawnDamageReceipts'] is Map
      ? Map<String, dynamic>.from(destination['pawnDamageReceipts'] as Map)
      : <String, dynamic>{};
  final moved = <String, dynamic>{};
  for (final entry in sourceReceipts.entries) {
    if (entry.value is Map &&
        tags.contains(_normalizedTag((entry.value as Map)['sheetTag']))) {
      moved['${entry.key}'] = _cloneMap(
        Map<String, dynamic>.from(entry.value as Map),
      );
    }
  }
  if (moved.isEmpty) return;
  sourceReceipts.removeWhere((key, _) => moved.containsKey('$key'));
  targetReceipts.addAll(moved);
  destination['pawnDamageReceipts'] = targetReceipts;
  source['pawnDamageReceipts'] = Map<String, dynamic>.from(sourceReceipts);
}
