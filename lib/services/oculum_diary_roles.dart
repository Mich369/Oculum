import 'oculum_diary_memory.dart';

const diaryEditableRoles = <String, String>{
  'party': 'Party / Alleato',
  'character': 'Personaggio',
  'npc': 'NPC',
  'enemy': 'Nemico',
  'creature': 'Mostro',
  'dead': 'Morto',
  'obliterated': 'Obliterato / Oblio',
  'fallen_eye': 'Occhio dei Caduti',
  'place': 'Ambiente / Luogo',
  'weapon': 'Arma',
  'armor': 'Armatura',
  'shield': 'Scudo',
  'item': 'Oggetto',
  'art': 'Art',
  'title': 'Titolo',
  'faction': 'Fazione',
  'quest': 'Missione',
  'event': 'Evento',
  'unknown': 'Da classificare',
};

/// Personal knowledge metadata. It never transforms the underlying game sheet.
class DiaryRoleLedger {
  DiaryRoleLedger();
  final Map<String, Map<String, dynamic>> _records = {};

  factory DiaryRoleLedger.fromJson(dynamic raw) {
    final ledger = DiaryRoleLedger();
    if (raw is List) {
      for (final record in raw.whereType<Map>()) {
        final id = record['entityId'];
        final role = record['role'];
        if (id is String &&
            role is String &&
            diaryEditableRoles.containsKey(role)) {
          ledger._records[id] = {
            'entityId': id,
            'name': '${record['name'] ?? ''}',
            'role': role,
            if (record['displayName'] is String)
              'displayName': record['displayName'],
            'nameHistory': [
              for (final change
                  in (record['nameHistory'] is List
                          ? record['nameHistory'] as List
                          : const [])
                      .whereType<Map>())
                Map<String, dynamic>.from(change),
            ],
            'history': [
              for (final change
                  in (record['history'] is List
                          ? record['history'] as List
                          : const [])
                      .whereType<Map>())
                Map<String, dynamic>.from(change),
            ],
          };
        }
      }
    }
    return ledger;
  }

  List<Map<String, dynamic>> toJson() => [
    for (final record in _records.values)
      {
        ...record,
        'nameHistory': [
          for (final change
              in (record['nameHistory'] as List? ?? const []).whereType<Map>())
            Map<String, dynamic>.from(change),
        ],
        'history': [
          for (final change in record['history'] as List)
            Map<String, dynamic>.from(change as Map),
        ],
      },
  ];

  Map<String, dynamic>? _record(DiaryEntity entity) {
    if (_records.containsKey(entity.id)) return _records[entity.id];
    final sameName = _records.values
        .where((r) => diaryKey('${r['name']}') == diaryKey(entity.name))
        .toList();
    return sameName.length == 1 ? sameName.single : null;
  }

  String roleOf(DiaryEntity entity) =>
      '${_record(entity)?['role'] ?? entity.kind}';

  List<Map<String, dynamic>> historyFor(DiaryEntity entity) => [
    for (final item
        in (_record(entity)?['history'] as List? ?? const []).whereType<Map>())
      Map<String, dynamic>.from(item),
  ];

  bool change(DiaryEntity entity, String role, DateTime now) {
    if (!diaryEditableRoles.containsKey(role)) return false;
    final previous = roleOf(entity);
    if (previous == role) return false;
    final history = historyFor(entity)
      ..add({'from': previous, 'to': role, 'at': now.toIso8601String()});
    final identity = '${_record(entity)?['entityId'] ?? entity.id}';
    _records[identity] = {
      ...?_record(entity),
      'entityId': identity,
      'name': _record(entity)?['name'] ?? entity.name,
      'role': role,
      'history': history,
    };
    return true;
  }

  String nameOf(DiaryEntity entity) =>
      '${_record(entity)?['displayName'] ?? entity.name}';
  String originalNameOf(DiaryEntity entity) =>
      '${_record(entity)?['name'] ?? entity.name}';

  List<Map<String, dynamic>> nameHistoryFor(DiaryEntity entity) => [
    for (final change
        in (_record(entity)?['nameHistory'] as List? ?? const [])
            .whereType<Map>())
      Map<String, dynamic>.from(change),
  ];

  bool rename(DiaryEntity entity, String name, DateTime now) {
    name = name.trim();
    if (name.isEmpty ||
        name.length > 120 ||
        name.contains(RegExp(r'[\n\r\[\]|]')) ||
        name == nameOf(entity)) {
      return false;
    }
    final record = _record(entity);
    final identity = '${record?['entityId'] ?? entity.id}';
    _records[identity] = {
      ...?record,
      'entityId': identity,
      'name': record?['name'] ?? entity.name,
      'displayName': name,
      'role': roleOf(entity),
      'history': historyFor(entity),
      'nameHistory': [
        ...nameHistoryFor(entity),
        {'from': nameOf(entity), 'to': name, 'at': now.toIso8601String()},
      ],
    };
    return true;
  }

  void apply(DiaryMemory memory) {
    for (final entry in memory.entities.entries.toList()) {
      final entity = entry.value;
      if (entity.kind == 'diary' || entity.kind == 'campaign') continue;
      final role = roleOf(entity);
      final name = nameOf(entity);
      if (role != entity.kind || name != entity.name) {
        memory.entities[entry.key] = DiaryEntity(
          entity.id,
          name,
          role,
          {
            ...entity.aliases,
            if (name != entity.name) entity.name,
            for (final change in nameHistoryFor(entity)) '${change['from']}',
          }.toList(),
          entity.linkType,
        );
      }
    }
  }
}
