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
  'upgrade': 'Potenziamento',
  'skill': 'Skill',
  'forge': 'Forgiatura',
  'crafting': 'Crafting',
  'unknown': 'Da classificare',
};

const diaryEyeChoices = <String, String>{
  'party': 'Occhio degli alleati',
  'enemy': 'Occhio dei nemici',
  'dead': 'Occhio dei morti',
  'obliterated': 'Occhio dell’Oblio',
};

const diaryProgressStates = <String, String>{
  'suggested': 'Suggerito',
  'discovered': 'Scoperto',
  'planned': 'Da realizzare',
  'in_progress': 'In corso',
  'completed': 'Completato',
  'learned': 'Appreso',
  'upgraded': 'Potenziato',
  'used': 'Usato',
  'lost': 'Perso',
  'abandoned': 'Abbandonato',
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
            if (diaryProgressStates.containsKey(record['status']))
              'status': record['status'],
            'statusHistory': [
              for (final change
                  in (record['statusHistory'] as List? ?? const [])
                      .whereType<Map>())
                Map<String, dynamic>.from(change),
            ],
            if (diaryEyeChoices.containsKey(record['eyeRole']))
              'eyeRole': record['eyeRole'],
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

  String statusOf(DiaryEntity entity) =>
      '${_record(entity)?['status'] ?? 'suggested'}';
  List<Map<String, dynamic>> statusHistoryFor(DiaryEntity entity) => [
    for (final change
        in (_record(entity)?['statusHistory'] as List? ?? const [])
            .whereType<Map>())
      Map<String, dynamic>.from(change),
  ];
  bool changeStatus(DiaryEntity entity, String status, DateTime now) {
    if (!diaryProgressStates.containsKey(status) || statusOf(entity) == status) {
      return false;
    }
    final record = _record(entity);
    final identity = '${record?['entityId'] ?? entity.id}';
    _records[identity] = {
      ...?record,
      'entityId': identity,
      'name': record?['name'] ?? entity.name,
      'role': roleOf(entity),
      'history': historyFor(entity),
      'status': status,
      'statusHistory': [
        ...statusHistoryFor(entity),
        {'from': statusOf(entity), 'to': status, 'at': now.toIso8601String()},
      ],
    };
    return true;
  }

  String eyeOf(DiaryEntity entity) =>
      '${_record(entity)?['eyeRole'] ?? roleOf(entity)}';

  bool changeEye(DiaryEntity entity, String? eyeRole) {
    if (eyeRole != null && !diaryEyeChoices.containsKey(eyeRole)) return false;
    final record = _record(entity);
    if (record?['eyeRole'] == eyeRole) return false;
    final identity = '${record?['entityId'] ?? entity.id}';
    _records[identity] = {
      ...?record,
      'entityId': identity,
      'name': record?['name'] ?? entity.name,
      'role': roleOf(entity),
      'history': historyFor(entity),
      'eyeRole': ?eyeRole,
    };
    if (eyeRole == null) _records[identity]!.remove('eyeRole');
    return true;
  }

  List<Map<String, dynamic>> historyFor(DiaryEntity entity) => [
    for (final item
        in (_record(entity)?['history'] as List? ?? const []).whereType<Map>())
      Map<String, dynamic>.from(item),
  ];

  bool change(
    DiaryEntity entity,
    String role,
    DateTime now, {
    String note = '',
    String noteAuthor = '',
  }) {
    if (!diaryEditableRoles.containsKey(role)) return false;
    final previous = roleOf(entity);
    if (previous == role) return false;
    final history = historyFor(entity)
      ..add({
        'from': previous,
        'to': role,
        'at': now.toIso8601String(),
        if (note.trim().isNotEmpty) 'note': note.trim(),
        if (noteAuthor.trim().isNotEmpty) 'noteAuthor': noteAuthor.trim(),
      });
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

  void apply(DiaryMemory memory, {List<DiaryEntity> catalogue = const []}) {
    // Rebuild only derived note edges, retaining every original diary source.
    memory.relations.removeWhere(
      (r) => r.evidence.document.id.startsWith('eye_note:'),
    );
    memory.entities.removeWhere((id, e) => id.startsWith('diary:eye_note:'));
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
    for (final subject in memory.entities.values.toList()) {
      if (subject.kind == 'diary' || subject.kind == 'campaign') continue;
      final history = historyFor(subject);
      for (var index = 0; index < history.length; index++) {
        final change = history[index];
        final note = '${change['note'] ?? ''}'.trim();
        if (note.isEmpty) continue;
        final document = DiaryDocument(
          id: 'eye_note:${subject.id}:$index:${change['at']}',
          author: '${change['noteAuthor'] ?? 'Nota dell’Occhio'}',
          diary: 'Note dell’Occhio',
          title:
              '${subject.name} · ${diaryEditableRoles[change['to']] ?? change['to']}',
          text: note,
          day: 0,
        );
        final parsed = DiaryMemoryBuilder().build(
          [document],
          [...catalogue, ...memory.entities.values],
        );
        final sourceId = 'diary:${document.id}';
        memory.entities[sourceId] = parsed.entities[sourceId]!;
        final fullEvidence = DiaryEvidence(document, 0, note.length);
        memory.relations.add(
          DiaryRelation(subject.id, sourceId, 'mentioned', fullEvidence),
        );
        final seen = <String>{};
        for (final relation in parsed.relations) {
          // The note's author is not assumed to be the attacker.
          final otherId =
              relation.to == sourceId && relation.state == 'mentioned'
              ? relation.from
              : relation.from == 'character:${diaryKey(document.author)}' &&
                    relation.state != 'written'
              ? relation.to
              : null;
          if (otherId == null) continue;
          final other = parsed.entities[otherId]!;
          if (other.kind == 'event' ||
              other.kind == 'diary' ||
              other.kind == 'campaign') {
            continue;
          }
          if (other.id == subject.id ||
              !seen.add('${other.id}:${relation.evidence.start}')) {
            continue;
          }
          memory.entities[other.id] = other;
          final evidence = relation.evidence;
          memory.relations.add(
            DiaryRelation(subject.id, other.id, 'mentioned', evidence),
          );
          memory.relations.add(
            DiaryRelation(other.id, sourceId, 'mentioned', evidence),
          );
          if (change['to'] != 'dead') continue;
          final sentence = evidence.quote.replaceAllMapped(
            RegExp(r'\[\[([^\]\n]+)\]\]'),
            (m) => m[1]!.split('|').first.split(':').last.trim(),
          );
          final names = [
            other.name,
            ...other.aliases,
          ].map(RegExp.escape).join('|');
          final subjectNames = [
            subject.name,
            ...subject.aliases,
          ].map(RegExp.escape).join('|');
          final killer = RegExp(
            '(?:^|\\bforse\\s+|\\bnon è stato\\s+)\\s*(?:(?:$subjectNames)\\s+)?(?:(?:è|e)\\s+(?:stat[oa]\\s+)?)?(?:uccis[oa]|abbattut[oa]|eliminat[oa])\\s+da\\s+(?:$names)(?![\\wÀ-ÿ])|(?<![\\wÀ-ÿ])(?:$names)\\s+(?:(?:lo|la)\\s+ha\\s+(?:ucciso|abbattuto|eliminato)|ha\\s+(?:ucciso|abbattuto|eliminato)\\s+(?:$subjectNames)(?![\\wÀ-ÿ]))',
            caseSensitive: false,
          ).hasMatch(sentence);
          if (!killer) continue;
          final uncertain = RegExp(
            r'\bnon\b|forse|incert|potrebbe|sarebbe|sembra|pare che|credo|secondo|dice|ha detto|avrebbe',
            caseSensitive: false,
          ).hasMatch(sentence);
          memory.relations.add(
            DiaryRelation(
              other.id,
              subject.id,
              uncertain ? 'uncertain' : 'killed',
              evidence,
            ),
          );
        }
      }
    }
    memory.invalidateRelationIndex();
  }
}
