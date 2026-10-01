import 'oculum_diary_memory.dart';

const diaryEditableRoles = <String, String>{
  'party': 'Party / Alleato',
  'character': 'Personaggio',
  'npc': 'NPC',
  'enemy': 'Nemico',
  'creature': 'Mostro',
  'dead': 'Morto',
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
      'entityId': identity,
      'name': entity.name,
      'role': role,
      'history': history,
    };
    return true;
  }

  void apply(DiaryMemory memory) {
    for (final entry in memory.entities.entries.toList()) {
      final entity = entry.value;
      if (entity.kind == 'diary' || entity.kind == 'campaign') continue;
      final role = roleOf(entity);
      if (role != entity.kind) {
        memory.entities[entry.key] = DiaryEntity(
          entity.id,
          entity.name,
          role,
          entity.aliases,
          entity.linkType,
        );
      }
    }
  }
}
