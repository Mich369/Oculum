part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member, unused_element

const int oculumVttSaveVersion = 2;
const int oculumVttMaxScenes = 200;
const int oculumVttMaxSceneElements = 5000;
const int oculumVttMaxFogOperations = 2000;

enum OculumVttTool {
  pan,
  select,
  ruler,
  line,
  rectangle,
  circle,
  cone,
  fogReveal,
  fogHide,
  wall,
  door,
  light,
  note,
  ping,
  trigger,
  erase,
}

double _oculumVttDouble(dynamic value, [double fallback = 0]) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value'.replaceAll(',', '.')) ?? fallback;
}

int _oculumVttInt(dynamic value, [int fallback = 0]) {
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? fallback;
}

bool _oculumVttBool(dynamic value, [bool fallback = false]) {
  if (value is bool) return value;
  final normalized = '$value'.trim().toLowerCase();
  if (normalized == 'true' || normalized == '1' || normalized == 'si') {
    return true;
  }
  if (normalized == 'false' || normalized == '0' || normalized == 'no') {
    return false;
  }
  return fallback;
}

List<Map<String, dynamic>> _oculumVttMapList(
  dynamic raw, {
  int maxItems = oculumVttMaxSceneElements,
}) {
  if (raw is! List) return <Map<String, dynamic>>[];
  return raw
      .whereType<Map>()
      .take(maxItems)
      .map((item) => Map<String, dynamic>.from(item))
      .toList(growable: true);
}

Map<String, dynamic> _oculumVttDeepMap(Map<dynamic, dynamic> source) {
  return Map<String, dynamic>.from(jsonDecode(jsonEncode(source)) as Map);
}

Map<String, List<Map<String, dynamic>>> _oculumVttFogLayers(dynamic raw) {
  if (raw is! Map) {
    return <String, List<Map<String, dynamic>>>{
      'party': <Map<String, dynamic>>[],
    };
  }
  final result = <String, List<Map<String, dynamic>>>{};
  for (final entry in raw.entries.take(128)) {
    final key = '${entry.key}'.trim();
    if (key.isEmpty) continue;
    result[key] = _oculumVttMapList(
      entry.value,
      maxItems: oculumVttMaxFogOperations,
    );
  }
  result.putIfAbsent('party', () => <Map<String, dynamic>>[]);
  return result;
}

String oculumVttGenerateId(String prefix) {
  return '${prefix}_${DateTime.now().microsecondsSinceEpoch}_'
      '${Random().nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
}

class OculumVttPoint {
  const OculumVttPoint(this.x, this.y);

  final double x;
  final double y;

  factory OculumVttPoint.fromJson(dynamic raw) {
    if (raw is List && raw.length >= 2) {
      return OculumVttPoint(
        _oculumVttDouble(raw[0]).clamp(0.0, 1.0).toDouble(),
        _oculumVttDouble(raw[1]).clamp(0.0, 1.0).toDouble(),
      );
    }
    if (raw is Map) {
      return OculumVttPoint(
        _oculumVttDouble(raw['x']).clamp(0.0, 1.0).toDouble(),
        _oculumVttDouble(raw['y']).clamp(0.0, 1.0).toDouble(),
      );
    }
    return const OculumVttPoint(0.5, 0.5);
  }

  List<double> toJson() => <double>[x, y];

  Offset toOffset(Size size) => Offset(x * size.width, y * size.height);

  static OculumVttPoint fromOffset(Offset point, Size size) {
    return OculumVttPoint(
      (point.dx / max(1.0, size.width)).clamp(0.0, 1.0).toDouble(),
      (point.dy / max(1.0, size.height)).clamp(0.0, 1.0).toDouble(),
    );
  }
}

class OculumVttScene {
  OculumVttScene({
    required this.id,
    required this.name,
    required this.collectionId,
    required this.collectionName,
    this.imagePath = '',
    this.imageName = '',
    this.imageDataBase64 = '',
    this.mapUrl = '',
    this.notes = '',
    this.description = '',
    this.category = '',
    this.levelName = '',
    this.tags = const <String>[],
    this.archived = false,
    this.isPrimary = false,
    this.visibleToPlayers = true,
    this.fogEnabled = false,
    this.gridType = 'none',
    this.gridSizePx = 64,
    this.distancePerCell = 1,
    this.distanceUnit = 'm',
    this.diagonalRule = 'euclidean',
    this.snapToGrid = false,
    this.showCoordinates = true,
    this.lockAspectRatio = true,
    this.rotationDegrees = 0,
    this.widthMeters = 30,
    this.heightMeters = 20,
    this.sortOrder = 0,
    this.revision = 0,
    String? updatedAt,
    List<Map<String, dynamic>>? tokens,
    List<Map<String, dynamic>>? drawings,
    List<Map<String, dynamic>>? walls,
    List<Map<String, dynamic>>? lights,
    List<Map<String, dynamic>>? triggers,
    Map<String, List<Map<String, dynamic>>>? fogLayers,
    Map<String, dynamic>? sharedData,
    Map<String, dynamic>? extra,
  }) : updatedAt = updatedAt ?? DateTime.now().toIso8601String(),
       tokens = tokens ?? <Map<String, dynamic>>[],
       drawings = drawings ?? <Map<String, dynamic>>[],
       walls = walls ?? <Map<String, dynamic>>[],
       lights = lights ?? <Map<String, dynamic>>[],
       triggers = triggers ?? <Map<String, dynamic>>[],
       fogLayers =
           fogLayers ??
           <String, List<Map<String, dynamic>>>{
             'party': <Map<String, dynamic>>[],
           },
       sharedData = sharedData ?? <String, dynamic>{},
       extra = extra ?? <String, dynamic>{};

  static const Set<String> _knownKeys = <String>{
    'id',
    'name',
    'collectionId',
    'collectionName',
    'imagePath',
    'imageName',
    'imageDataBase64',
    'mapUrl',
    'notes',
    'description',
    'category',
    'levelName',
    'tags',
    'archived',
    'isPrimary',
    'visibleToPlayers',
    'fogEnabled',
    'gridType',
    'gridSizePx',
    'distancePerCell',
    'distanceUnit',
    'diagonalRule',
    'snapToGrid',
    'showCoordinates',
    'lockAspectRatio',
    'rotationDegrees',
    'widthMeters',
    'heightMeters',
    'sortOrder',
    'revision',
    'updatedAt',
    'tokens',
    'drawings',
    'walls',
    'lights',
    'triggers',
    'fogLayers',
    'sharedData',
  };

  String id;
  String name;
  String collectionId;
  String collectionName;
  String imagePath;
  String imageName;
  String imageDataBase64;
  String mapUrl;
  String notes;
  String description;
  String category;
  String levelName;
  List<String> tags;
  bool archived;
  bool isPrimary;
  bool visibleToPlayers;
  bool fogEnabled;
  String gridType;
  double gridSizePx;
  double distancePerCell;
  String distanceUnit;
  String diagonalRule;
  bool snapToGrid;
  bool showCoordinates;
  bool lockAspectRatio;
  double rotationDegrees;
  double widthMeters;
  double heightMeters;
  int sortOrder;
  int revision;
  String updatedAt;
  List<Map<String, dynamic>> tokens;
  List<Map<String, dynamic>> drawings;
  List<Map<String, dynamic>> walls;
  List<Map<String, dynamic>> lights;
  List<Map<String, dynamic>> triggers;
  Map<String, List<Map<String, dynamic>>> fogLayers;
  Map<String, dynamic> sharedData;
  Map<String, dynamic> extra;

  factory OculumVttScene.empty({
    String name = 'Scena principale',
    String collectionName = 'Luogo principale',
  }) {
    final collectionId = oculumVttGenerateId('place');
    return OculumVttScene(
      id: oculumVttGenerateId('scene'),
      name: name,
      collectionId: collectionId,
      collectionName: collectionName,
      isPrimary: true,
    );
  }

  factory OculumVttScene.fromJson(dynamic raw) {
    if (raw is! Map) return OculumVttScene.empty();
    final json = Map<String, dynamic>.from(raw);
    final id = '${json['id'] ?? ''}'.trim();
    final collectionId = '${json['collectionId'] ?? ''}'.trim();
    final safeGrid = switch ('${json['gridType'] ?? 'none'}') {
      'square' => 'square',
      'hex' => 'hex',
      _ => 'none',
    };
    final safeUnit = switch ('${json['distanceUnit'] ?? 'm'}') {
      'cm' => 'cm',
      'km' => 'km',
      'cells' => 'cells',
      _ => 'm',
    };
    final safeDiagonal = switch ('${json['diagonalRule'] ?? 'euclidean'}') {
      'chebyshev' => 'chebyshev',
      'manhattan' => 'manhattan',
      'alternating' => 'alternating',
      _ => 'euclidean',
    };
    final extra = <String, dynamic>{};
    for (final entry in json.entries) {
      if (!_knownKeys.contains(entry.key)) extra[entry.key] = entry.value;
    }
    return OculumVttScene(
      id: id.isEmpty ? oculumVttGenerateId('scene') : id,
      name: '${json['name'] ?? 'Scena'}'.trim().isEmpty
          ? 'Scena'
          : '${json['name']}'.trim(),
      collectionId: collectionId.isEmpty
          ? oculumVttGenerateId('place')
          : collectionId,
      collectionName: '${json['collectionName'] ?? 'Luogo'}'.trim().isEmpty
          ? 'Luogo'
          : '${json['collectionName']}'.trim(),
      imagePath: '${json['imagePath'] ?? ''}',
      imageName: '${json['imageName'] ?? ''}',
      imageDataBase64: '${json['imageDataBase64'] ?? ''}',
      mapUrl: '${json['mapUrl'] ?? ''}',
      notes: '${json['notes'] ?? ''}',
      description: '${json['description'] ?? ''}',
      category: '${json['category'] ?? ''}',
      levelName: '${json['levelName'] ?? ''}',
      tags: (json['tags'] is List ? json['tags'] as List : const <dynamic>[])
          .map((tag) => '$tag'.trim())
          .where((tag) => tag.isNotEmpty)
          .take(40)
          .toSet()
          .toList(growable: true),
      archived: _oculumVttBool(json['archived']),
      isPrimary: _oculumVttBool(json['isPrimary']),
      visibleToPlayers: _oculumVttBool(json['visibleToPlayers'], true),
      fogEnabled: _oculumVttBool(json['fogEnabled']),
      gridType: safeGrid,
      gridSizePx: _oculumVttDouble(
        json['gridSizePx'],
        64,
      ).clamp(12.0, 512.0).toDouble(),
      distancePerCell: _oculumVttDouble(
        json['distancePerCell'],
        1,
      ).clamp(0.001, 100000.0).toDouble(),
      distanceUnit: safeUnit,
      diagonalRule: safeDiagonal,
      snapToGrid: _oculumVttBool(json['snapToGrid']),
      showCoordinates: _oculumVttBool(json['showCoordinates'], true),
      lockAspectRatio: _oculumVttBool(json['lockAspectRatio'], true),
      rotationDegrees: _oculumVttDouble(
        json['rotationDegrees'],
      ).clamp(-180.0, 180.0).toDouble(),
      widthMeters: _oculumVttDouble(
        json['widthMeters'],
        30,
      ).clamp(1.0, 1000000.0).toDouble(),
      heightMeters: _oculumVttDouble(
        json['heightMeters'],
        20,
      ).clamp(1.0, 1000000.0).toDouble(),
      sortOrder: _oculumVttInt(json['sortOrder']),
      revision: max(0, _oculumVttInt(json['revision'])),
      updatedAt: '${json['updatedAt'] ?? DateTime.now().toIso8601String()}',
      tokens: _oculumVttMapList(json['tokens'], maxItems: 1000),
      drawings: _oculumVttMapList(json['drawings']),
      walls: _oculumVttMapList(json['walls']),
      lights: _oculumVttMapList(json['lights']),
      triggers: _oculumVttMapList(json['triggers']),
      fogLayers: _oculumVttFogLayers(json['fogLayers']),
      sharedData: json['sharedData'] is Map
          ? Map<String, dynamic>.from(json['sharedData'] as Map)
          : <String, dynamic>{},
      extra: extra,
    );
  }

  factory OculumVttScene.fromLegacy(Map<String, dynamic> legacy) {
    final scene = OculumVttScene.empty(
      name: '${legacy['mapImageName'] ?? ''}'.trim().isEmpty
          ? 'Scena principale'
          : '${legacy['mapImageName']}'.trim(),
    );
    scene.imagePath = '${legacy['mapImagePath'] ?? ''}';
    scene.imageName = '${legacy['mapImageName'] ?? ''}';
    scene.imageDataBase64 = '${legacy['mapImageDataBase64'] ?? ''}';
    scene.mapUrl = '${legacy['mapUrl'] ?? ''}';
    scene.notes = '${legacy['mapNotes'] ?? ''}';
    scene.widthMeters = _oculumVttDouble(
      legacy['mapWidthMeters'],
      30,
    ).clamp(1.0, 1000000.0).toDouble();
    scene.heightMeters = _oculumVttDouble(
      legacy['mapHeightMeters'],
      20,
    ).clamp(1.0, 1000000.0).toDouble();
    scene.tokens = _oculumVttMapList(legacy['localMapTokens'], maxItems: 1000);
    return scene;
  }

  OculumVttScene duplicate({String? newName}) {
    final copy = OculumVttScene.fromJson(toJson());
    copy.id = oculumVttGenerateId('scene');
    copy.name = newName ?? '$name - copia';
    copy.isPrimary = false;
    copy.revision = 0;
    copy.updatedAt = DateTime.now().toIso8601String();
    return copy;
  }

  void touch() {
    revision++;
    updatedAt = DateTime.now().toIso8601String();
  }

  Map<String, dynamic> toJson({bool includePrivate = true}) {
    final result = <String, dynamic>{
      ...extra,
      'id': id,
      'name': name,
      'collectionId': collectionId,
      'collectionName': collectionName,
      'imagePath': includePrivate ? imagePath : '',
      'imageName': imageName,
      'imageDataBase64': includePrivate ? imageDataBase64 : '',
      'mapUrl': mapUrl,
      'notes': includePrivate ? notes : '',
      'description': description,
      'category': category,
      'levelName': levelName,
      'tags': tags,
      'archived': archived,
      'isPrimary': isPrimary,
      'visibleToPlayers': visibleToPlayers,
      'fogEnabled': fogEnabled,
      'gridType': gridType,
      'gridSizePx': gridSizePx,
      'distancePerCell': distancePerCell,
      'distanceUnit': distanceUnit,
      'diagonalRule': diagonalRule,
      'snapToGrid': snapToGrid,
      'showCoordinates': showCoordinates,
      'lockAspectRatio': lockAspectRatio,
      'rotationDegrees': rotationDegrees,
      'widthMeters': widthMeters,
      'heightMeters': heightMeters,
      'sortOrder': sortOrder,
      'revision': revision,
      'updatedAt': updatedAt,
      'tokens': tokens.map(_oculumVttDeepMap).toList(growable: false),
      'drawings': drawings.map(_oculumVttDeepMap).toList(growable: false),
      'walls': walls.map(_oculumVttDeepMap).toList(growable: false),
      'lights': lights.map(_oculumVttDeepMap).toList(growable: false),
      'triggers': triggers.map(_oculumVttDeepMap).toList(growable: false),
      'fogLayers': <String, dynamic>{
        for (final entry in fogLayers.entries)
          entry.key: entry.value.map(_oculumVttDeepMap).toList(growable: false),
      },
      'sharedData': _oculumVttDeepMap(sharedData),
    };
    if (!includePrivate) {
      result['tokens'] = tokens
          .where(
            (token) =>
                _oculumVttBool(token['visible'], true) &&
                !_oculumVttBool(token['hidden']),
          )
          .map((raw) {
            final token = _oculumVttDeepMap(raw);
            for (final key in token.keys.toList()) {
              final lower = key.toLowerCase();
              if (lower.contains('private') || lower == 'masternotes') {
                token.remove(key);
              }
            }
            return token;
          })
          .toList(growable: false);
      result['triggers'] = const <Map<String, dynamic>>[];
      result['sharedData'] = <String, dynamic>{
        for (final entry in sharedData.entries)
          if (!entry.key.toLowerCase().contains('private'))
            entry.key: entry.value,
      };
    }
    return result;
  }
}

class OculumVttState {
  OculumVttState({
    required this.activeSceneId,
    required this.scenes,
    Map<String, bool>? modules,
    Map<String, Map<String, bool>>? permissions,
    this.graphicsQuality = 'medium',
    this.masterBypassCollisions = true,
    List<Map<String, dynamic>>? collections,
    Map<String, dynamic>? extra,
  }) : modules = modules ?? defaultModules(),
       permissions = permissions ?? defaultPermissions(),
       collections = collections ?? <Map<String, dynamic>>[],
       extra = extra ?? <String, dynamic>{} {
    normalize();
  }

  static const Set<String> _knownKeys = <String>{
    'version',
    'activeSceneId',
    'scenes',
    'modules',
    'permissions',
    'graphicsQuality',
    'masterBypassCollisions',
    'collections',
  };

  String activeSceneId;
  List<OculumVttScene> scenes;
  Map<String, bool> modules;
  Map<String, Map<String, bool>> permissions;
  String graphicsQuality;
  bool masterBypassCollisions;
  List<Map<String, dynamic>> collections;
  Map<String, dynamic> extra;

  static Map<String, bool> defaultModules() => <String, bool>{
    'advanced_measurement': true,
    'fog': true,
    'dynamic_vision': false,
    'walls_doors': true,
    'initiative': true,
    'combat': true,
    'conditions': true,
    'areas': true,
    'ping': true,
    'annotations': true,
    'lights': true,
    'triggers': true,
    'ambient_audio': false,
    'random_tables': false,
    'calendar_weather': false,
  };

  static Map<String, Map<String, bool>> defaultPermissions() {
    const all = <String, bool>{
      'view': true,
      'tokens': true,
      'doors': true,
      'sheets': true,
      'stats': true,
      'notes': true,
      'chat': true,
      'rolls': true,
      'scene': true,
      'map': true,
      'audio': true,
      'ping': true,
      'tools': true,
      'bestiary': true,
      'manual': true,
      'secret_images': true,
    };
    return <String, Map<String, bool>>{
      'master': Map<String, bool>.from(all),
      'co_master': Map<String, bool>.from(all),
      'player': <String, bool>{
        ...all,
        'doors': false,
        'scene': false,
        'map': false,
        'audio': false,
        'bestiary': false,
        'secret_images': false,
      },
      'observer': <String, bool>{
        ...all,
        'tokens': false,
        'doors': false,
        'sheets': false,
        'stats': false,
        'notes': false,
        'chat': false,
        'rolls': false,
        'scene': false,
        'map': false,
        'audio': false,
        'ping': false,
        'bestiary': false,
        'secret_images': false,
      },
    };
  }

  factory OculumVttState.empty() {
    final scene = OculumVttScene.empty();
    return OculumVttState(
      activeSceneId: scene.id,
      scenes: <OculumVttScene>[scene],
    );
  }

  factory OculumVttState.fromJson(dynamic raw, {Map<String, dynamic>? legacy}) {
    if (raw is! Map) {
      final scene = OculumVttScene.fromLegacy(legacy ?? <String, dynamic>{});
      return OculumVttState(
        activeSceneId: scene.id,
        scenes: <OculumVttScene>[scene],
      );
    }
    final json = Map<String, dynamic>.from(raw);
    final sceneRaw = json['scenes'];
    final scenes = (sceneRaw is List ? sceneRaw : const <dynamic>[])
        .take(oculumVttMaxScenes)
        .map(OculumVttScene.fromJson)
        .toList(growable: true);
    if (scenes.isEmpty) {
      scenes.add(OculumVttScene.fromLegacy(legacy ?? <String, dynamic>{}));
    }

    final modules = defaultModules();
    if (json['modules'] is Map) {
      for (final entry in (json['modules'] as Map).entries) {
        modules['${entry.key}'] = _oculumVttBool(entry.value);
      }
    }

    final permissions = defaultPermissions();
    if (json['permissions'] is Map) {
      for (final roleEntry in (json['permissions'] as Map).entries) {
        if (roleEntry.value is! Map) continue;
        final role = '${roleEntry.key}';
        final current = <String, bool>{...?permissions[role]};
        for (final permission in (roleEntry.value as Map).entries) {
          current['${permission.key}'] = _oculumVttBool(permission.value);
        }
        permissions[role] = current;
      }
    }

    final extra = <String, dynamic>{};
    for (final entry in json.entries) {
      if (!_knownKeys.contains(entry.key)) extra[entry.key] = entry.value;
    }
    return OculumVttState(
      activeSceneId: '${json['activeSceneId'] ?? ''}',
      scenes: scenes,
      modules: modules,
      permissions: permissions,
      graphicsQuality: '${json['graphicsQuality'] ?? 'medium'}',
      masterBypassCollisions: _oculumVttBool(
        json['masterBypassCollisions'],
        true,
      ),
      collections: _oculumVttMapList(
        json['collections'],
        maxItems: oculumVttMaxScenes,
      ),
      extra: extra,
    );
  }

  OculumVttScene get activeScene {
    return scenes.firstWhere(
      (scene) => scene.id == activeSceneId,
      orElse: () => scenes.first,
    );
  }

  void normalize() {
    if (scenes.isEmpty) scenes.add(OculumVttScene.empty());
    if (scenes.length > oculumVttMaxScenes) {
      scenes.removeRange(oculumVttMaxScenes, scenes.length);
    }
    final seenIds = <String>{};
    for (final scene in scenes) {
      if (scene.id.isEmpty || !seenIds.add(scene.id)) {
        scene.id = oculumVttGenerateId('scene');
        seenIds.add(scene.id);
      }
    }
    if (!seenIds.contains(activeSceneId)) {
      final visible = scenes.where((scene) => !scene.archived);
      activeSceneId = (visible.isEmpty ? scenes.first : visible.first).id;
    }
    if (!const <String>{'low', 'medium', 'high'}.contains(graphicsQuality)) {
      graphicsQuality = 'medium';
    }
    for (final entry in defaultModules().entries) {
      modules.putIfAbsent(entry.key, () => entry.value);
    }
    for (final entry in defaultPermissions().entries) {
      permissions.putIfAbsent(
        entry.key,
        () => Map<String, bool>.from(entry.value),
      );
    }
    _rebuildCollections();
  }

  void _rebuildCollections() {
    final byId = <String, Map<String, dynamic>>{
      for (final collection in collections)
        if ('${collection['id'] ?? ''}'.isNotEmpty)
          '${collection['id']}': Map<String, dynamic>.from(collection),
    };
    for (final scene in scenes) {
      byId.putIfAbsent(
        scene.collectionId,
        () => <String, dynamic>{
          'id': scene.collectionId,
          'name': scene.collectionName,
          'description': '',
          'tags': <String>[],
          'archived': false,
          'primarySceneId': scene.isPrimary ? scene.id : '',
          'sharedData': <String, dynamic>{},
        },
      );
      final collection = byId[scene.collectionId]!;
      if ('${collection['name'] ?? ''}'.trim().isEmpty) {
        collection['name'] = scene.collectionName;
      }
      if (scene.isPrimary) collection['primarySceneId'] = scene.id;
    }
    collections = byId.values.toList(growable: true);
  }

  Map<String, dynamic> toJson() {
    normalize();
    return <String, dynamic>{
      ...extra,
      'version': oculumVttSaveVersion,
      'activeSceneId': activeSceneId,
      'scenes': scenes.map((scene) => scene.toJson()).toList(growable: false),
      'modules': modules,
      'permissions': permissions,
      'graphicsQuality': graphicsQuality,
      'masterBypassCollisions': masterBypassCollisions,
      'collections': collections.map(_oculumVttDeepMap).toList(growable: false),
    };
  }
}

double oculumVttDistanceCells(
  Offset start,
  Offset end, {
  required String gridType,
  required double cellSize,
  String diagonalRule = 'euclidean',
}) {
  final safeCell = max(1.0, cellSize);
  final dx = (end.dx - start.dx).abs() / safeCell;
  final dy = (end.dy - start.dy).abs() / safeCell;
  if (gridType == 'hex') {
    final q1 = (sqrt(3) / 3 * start.dx - 1 / 3 * start.dy) / safeCell;
    final r1 = (2 / 3 * start.dy) / safeCell;
    final q2 = (sqrt(3) / 3 * end.dx - 1 / 3 * end.dy) / safeCell;
    final r2 = (2 / 3 * end.dy) / safeCell;
    final dq = q2 - q1;
    final dr = r2 - r1;
    final ds = -(q2 + r2) - (-(q1 + r1));
    return max(dq.abs(), max(dr.abs(), ds.abs()));
  }
  if (gridType != 'square') return sqrt(dx * dx + dy * dy);
  return switch (diagonalRule) {
    'chebyshev' => max(dx, dy),
    'manhattan' => dx + dy,
    'alternating' => min(dx, dy) * 1.5 + (dx - dy).abs(),
    _ => sqrt(dx * dx + dy * dy),
  };
}

double oculumVttDistance(
  Offset start,
  Offset end, {
  required String gridType,
  required double cellSize,
  required double distancePerCell,
  String diagonalRule = 'euclidean',
}) {
  return oculumVttDistanceCells(
        start,
        end,
        gridType: gridType,
        cellSize: cellSize,
        diagonalRule: diagonalRule,
      ) *
      max(0.001, distancePerCell);
}

double oculumVttBoundaryTranslationScale({
  required double x,
  required double y,
  required Offset delta,
  required double canvasWidth,
  required double canvasHeight,
}) {
  final safeWidth = max(1.0, canvasWidth);
  final safeHeight = max(1.0, canvasHeight);
  final safeX = x.clamp(0.0, 1.0);
  final safeY = y.clamp(0.0, 1.0);
  var scale = 1.0;

  if (delta.dx > 0) {
    scale = min(scale, ((1 - safeX) * safeWidth) / delta.dx);
  } else if (delta.dx < 0) {
    scale = min(scale, (safeX * safeWidth) / -delta.dx);
  }
  if (delta.dy > 0) {
    scale = min(scale, ((1 - safeY) * safeHeight) / delta.dy);
  } else if (delta.dy < 0) {
    scale = min(scale, (safeY * safeHeight) / -delta.dy);
  }

  return scale.clamp(0.0, 1.0).toDouble();
}

double oculumVttDistanceMetersForDelta(
  Offset delta, {
  required double canvasWidth,
  required double canvasHeight,
  required double mapWidthMeters,
  required double mapHeightMeters,
}) {
  final dxMeters = delta.dx / max(1.0, canvasWidth) * max(0.0, mapWidthMeters);
  final dyMeters =
      delta.dy / max(1.0, canvasHeight) * max(0.0, mapHeightMeters);
  return sqrt(dxMeters * dxMeters + dyMeters * dyMeters);
}

double oculumVttMovementTranslationScale(
  Offset delta, {
  required double remainingMeters,
  required double canvasWidth,
  required double canvasHeight,
  required double mapWidthMeters,
  required double mapHeightMeters,
}) {
  if (remainingMeters.isInfinite) return 1;
  if (remainingMeters <= 0) return 0;
  final requestedMeters = oculumVttDistanceMetersForDelta(
    delta,
    canvasWidth: canvasWidth,
    canvasHeight: canvasHeight,
    mapWidthMeters: mapWidthMeters,
    mapHeightMeters: mapHeightMeters,
  );
  if (requestedMeters <= 0) return 1;
  return (remainingMeters / requestedMeters).clamp(0.0, 1.0).toDouble();
}

Offset oculumVttSnapPoint(
  Offset point, {
  required String gridType,
  required double cellSize,
}) {
  final safeCell = max(1.0, cellSize);
  if (gridType == 'hex') {
    final q = (sqrt(3) / 3 * point.dx - 1 / 3 * point.dy) / safeCell;
    final r = (2 / 3 * point.dy) / safeCell;
    var x = q;
    var z = r;
    var y = -x - z;
    var rx = x.roundToDouble();
    var ry = y.roundToDouble();
    var rz = z.roundToDouble();
    final xDiff = (rx - x).abs();
    final yDiff = (ry - y).abs();
    final zDiff = (rz - z).abs();
    if (xDiff > yDiff && xDiff > zDiff) {
      rx = -ry - rz;
    } else if (yDiff > zDiff) {
      ry = -rx - rz;
    } else {
      rz = -rx - ry;
    }
    return Offset(safeCell * sqrt(3) * (rx + rz / 2), safeCell * 1.5 * rz);
  }
  if (gridType != 'square') return point;
  return Offset(
    (point.dx / safeCell).round() * safeCell,
    (point.dy / safeCell).round() * safeCell,
  );
}

double _oculumVttCross(Offset a, Offset b, Offset c) {
  return (b.dx - a.dx) * (c.dy - a.dy) - (b.dy - a.dy) * (c.dx - a.dx);
}

bool _oculumVttPointOnSegment(Offset a, Offset b, Offset point) {
  const epsilon = 0.000001;
  return point.dx >= min(a.dx, b.dx) - epsilon &&
      point.dx <= max(a.dx, b.dx) + epsilon &&
      point.dy >= min(a.dy, b.dy) - epsilon &&
      point.dy <= max(a.dy, b.dy) + epsilon &&
      _oculumVttCross(a, b, point).abs() <= epsilon;
}

bool oculumVttSegmentsIntersect(Offset a1, Offset a2, Offset b1, Offset b2) {
  final d1 = _oculumVttCross(a1, a2, b1);
  final d2 = _oculumVttCross(a1, a2, b2);
  final d3 = _oculumVttCross(b1, b2, a1);
  final d4 = _oculumVttCross(b1, b2, a2);
  if (((d1 > 0 && d2 < 0) || (d1 < 0 && d2 > 0)) &&
      ((d3 > 0 && d4 < 0) || (d3 < 0 && d4 > 0))) {
    return true;
  }
  return (d1.abs() <= 0.000001 && _oculumVttPointOnSegment(a1, a2, b1)) ||
      (d2.abs() <= 0.000001 && _oculumVttPointOnSegment(a1, a2, b2)) ||
      (d3.abs() <= 0.000001 && _oculumVttPointOnSegment(b1, b2, a1)) ||
      (d4.abs() <= 0.000001 && _oculumVttPointOnSegment(b1, b2, a2));
}

bool oculumVttMovementBlocked(
  Offset start,
  Offset end,
  Iterable<Map<String, dynamic>> walls,
) {
  for (final wall in walls) {
    if (!_oculumVttBool(wall['blocksMovement'], true)) continue;
    if ('${wall['type'] ?? 'wall'}' == 'door' && _oculumVttBool(wall['open'])) {
      continue;
    }
    final a = OculumVttPoint.fromJson(wall['a']).toOffset(const Size(1, 1));
    final b = OculumVttPoint.fromJson(wall['b']).toOffset(const Size(1, 1));
    if (oculumVttSegmentsIntersect(start, end, a, b)) return true;
  }
  return false;
}

class OculumVttAssetAssembler {
  OculumVttAssetAssembler({required this.assetId, required int chunkCount})
    : chunkCount = chunkCount.clamp(1, 1024),
      _chunks = List<String?>.filled(chunkCount.clamp(1, 1024), null);

  final String assetId;
  final int chunkCount;
  final List<String?> _chunks;
  int _received = 0;

  int get received => _received;
  bool get isComplete => _received == chunkCount;
  double get progress => chunkCount == 0 ? 0 : _received / chunkCount;

  bool addChunk(int index, String data) {
    if (index < 0 || index >= chunkCount || data.length > 32768) return false;
    if (_chunks[index] != null) return false;
    _chunks[index] = data;
    _received++;
    return true;
  }

  Uint8List? completeBytes() {
    if (!isComplete) return null;
    final encoded = _chunks.join();
    if (encoded.length > 24 * 1024 * 1024) return null;
    try {
      return base64Decode(encoded);
    } catch (_) {
      return null;
    }
  }
}

int _oculumVttStableBytesHash(Uint8List bytes) {
  var hash = 0x811C9DC5;
  for (final byte in bytes) {
    hash ^= byte;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash;
}

Map<String, dynamic> prepareOculumVttSharedImage(Map<String, dynamic> input) {
  final rawBytes = input['bytes'];
  if (rawBytes is! Uint8List || rawBytes.isEmpty) return <String, dynamic>{};
  final decoded = img.decodeImage(rawBytes);
  if (decoded == null) return <String, dynamic>{};
  final maxDimension = _oculumVttInt(
    input['maxDimension'],
    2048,
  ).clamp(512, 4096);
  img.Image output = decoded;
  if (max(decoded.width, decoded.height) > maxDimension) {
    final scale = maxDimension / max(decoded.width, decoded.height);
    output = img.copyResize(
      decoded,
      width: max(1, (decoded.width * scale).round()),
      height: max(1, (decoded.height * scale).round()),
      interpolation: img.Interpolation.average,
    );
  }
  final quality = _oculumVttInt(input['quality'], 76).clamp(45, 92);
  final encoded = Uint8List.fromList(img.encodeJpg(output, quality: quality));
  final hash = _oculumVttStableBytesHash(
    encoded,
  ).toRadixString(16).padLeft(8, '0');
  return <String, dynamic>{
    'assetId': 'vtt_${encoded.length}_$hash',
    'bytes': encoded,
    'base64': base64Encode(encoded),
    'mime': 'image/jpeg',
    'width': output.width,
    'height': output.height,
  };
}
