import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import 'oculum_diary_memory.dart';
import 'oculum_diary_roles.dart';
import 'oculum_diary_links.dart';

final _knowledgeDomain = ECDomainParameters('secp256r1');

Map<String, dynamic> diaryPublicSheet(Map<String, dynamic> sheet) =>
    Map<String, dynamic>.from(sheet)
      ..remove('diaryEntityRoles')
      ..remove('diaryKnowledgeSync');
Uint8List _knowledgeRandom(int count) {
  final random = Random.secure();
  return Uint8List.fromList(List.generate(count, (_) => random.nextInt(256)));
}

/// Device identity and durable targeted outbox. Never included in sheet sharing.
class DiaryKnowledgeSync {
  DiaryKnowledgeSync();
  String? _private;
  final List<Map<String, dynamic>> outbox = [];
  final List<Map<String, dynamic>> received = [];
  int _revision = 0;
  final Set<String> acknowledged = {};

  static bool _validCommand(Map command) {
    bool text(String field, int maximum) =>
        command[field] is String &&
        (command[field] as String).trim().isNotEmpty &&
        (command[field] as String).length <= maximum;
    final role = command['role'];
    final name = command['displayName'];
    return text('id', 128) &&
        text('room', 128) &&
        text('senderTag', 128) &&
        text('recipientTag', 128) &&
        text('entityId', 512) &&
        text('originalName', 120) &&
        text('message', 2048) &&
        text('createdAt', 64) &&
        DateTime.tryParse(command['createdAt']) != null &&
        command['revision'] is int &&
        (role == null || diaryEditableRoles.containsKey(role)) &&
        (name == null ||
            (text('displayName', 120) &&
                !(name as String).contains(RegExp(r'[\n\r\[\]|]')))) &&
        (role != null || name != null);
  }

  factory DiaryKnowledgeSync.fromJson(dynamic raw) {
    final sync = DiaryKnowledgeSync();
    if (raw is! Map) return sync;
    if (raw['privateKey'] is String) {
      final key = BigInt.tryParse(raw['privateKey'], radix: 16);
      if (key != null && key > BigInt.zero && key < _knowledgeDomain.n) {
        sync._private = raw['privateKey'];
      }
    }
    for (final field in ['outbox', 'received']) {
      final target = field == 'outbox' ? sync.outbox : sync.received;
      if (raw[field] is List) {
        for (final item in (raw[field] as List).whereType<Map>()) {
          if (_validCommand(item)) {
            target.add(Map<String, dynamic>.from(jsonDecode(jsonEncode(item))));
          }
        }
      }
    }
    sync._revision = raw['revision'] is int ? raw['revision'] : 0;
    if (raw['acknowledged'] is List) {
      sync.acknowledged.addAll(
        (raw['acknowledged'] as List).whereType<String>(),
      );
    }
    return sync;
  }
  void mergeFrom(DiaryKnowledgeSync other) {
    _private ??= other._private;
    _revision = max(_revision, other._revision);
    acknowledged.addAll(other.acknowledged);
    for (final command in other.outbox) {
      if (!acknowledged.contains('${command['id']}') &&
          !outbox.any((item) => item['id'] == command['id'])) {
        outbox.add(command);
      }
    }
    outbox.removeWhere((item) => acknowledged.contains('${item['id']}'));
    for (final command in other.received) {
      if (!received.any((item) => item['id'] == command['id'])) {
        received.add(command);
      }
    }
  }

  void ensureIdentity() {
    if (_private != null) return;
    final random = FortunaRandom()..seed(KeyParameter(_knowledgeRandom(32)));
    final generator = ECKeyGenerator()
      ..init(
        ParametersWithRandom(
          ECKeyGeneratorParameters(_knowledgeDomain),
          random,
        ),
      );
    _private = generator.generateKeyPair().privateKey.d!.toRadixString(16);
  }

  ECPrivateKey get _key {
    ensureIdentity();
    return ECPrivateKey(BigInt.parse(_private!, radix: 16), _knowledgeDomain);
  }

  String get publicKey =>
      base64Encode((_knowledgeDomain.G * _key.d!)!.getEncoded(false));
  Map<String, dynamic> toJson() => jsonDecode(
    jsonEncode({
      'privateKey': _private,
      'revision': _revision,
      'outbox': outbox,
      'received': received,
      'acknowledged': acknowledged.toList(),
    }),
  );

  Uint8List _sharedKey(String other, String id) {
    final point = _knowledgeDomain.curve.decodePoint(base64Decode(other));
    if (point == null || point.isInfinity) {
      throw const FormatException('Invalid knowledge key');
    }
    final agreement = ECDHBasicAgreement()..init(_key);
    final secret = agreement.calculateAgreement(
      ECPublicKey(point, _knowledgeDomain),
    );
    return SHA256Digest().process(
      Uint8List.fromList(
        utf8.encode('${secret.toRadixString(16)}|oculum-knowledge-v1|$id'),
      ),
    );
  }

  Map<String, dynamic> seal(
    Map<String, dynamic> command,
    String recipientPublicKey,
  ) {
    final nonce = _knowledgeRandom(12);
    final id = '${command['id']}';
    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        true,
        AEADParameters(
          KeyParameter(_sharedKey(recipientPublicKey, id)),
          128,
          nonce,
          Uint8List.fromList(utf8.encode(id)),
        ),
      );
    return {
      'id': id,
      'room': command['room'],
      'senderTag': command['senderTag'],
      'recipientTag': command['recipientTag'],
      'publicKey': publicKey,
      'nonce': base64Encode(nonce),
      'ciphertext': base64Encode(
        cipher.process(Uint8List.fromList(utf8.encode(jsonEncode(command)))),
      ),
    };
  }

  Map<String, dynamic>? open(
    Map<String, dynamic> envelope,
    String trustedPublicKey,
  ) {
    try {
      if (envelope['publicKey'] != trustedPublicKey) return null;
      if (trustedPublicKey.length > 128 ||
          '${envelope['ciphertext']}'.length > 22000 ||
          '${envelope['nonce']}'.length > 24 ||
          '${envelope['id']}'.length > 128) {
        return null;
      }
      final id = '${envelope['id']}';
      final ciphertext = base64Decode('${envelope['ciphertext']}');
      if (ciphertext.length > 16384) return null;
      final nonce = base64Decode('${envelope['nonce']}');
      if (nonce.length != 12) return null;
      final cipher = GCMBlockCipher(AESEngine())
        ..init(
          false,
          AEADParameters(
            KeyParameter(_sharedKey(trustedPublicKey, id)),
            128,
            nonce,
            Uint8List.fromList(utf8.encode(id)),
          ),
        );
      final decoded = jsonDecode(utf8.decode(cipher.process(ciphertext)));
      if (decoded is! Map) return null;
      final command = Map<String, dynamic>.from(decoded);
      for (final key in ['id', 'room', 'senderTag', 'recipientTag']) {
        if (command[key] != envelope[key]) return null;
      }
      return command;
    } catch (_) {
      return null;
    }
  }

  void enqueue({
    required String room,
    required String senderTag,
    required Iterable<String> recipients,
    required DiaryEntity entity,
    String? role,
    String? displayName,
    required String originalName,
  }) {
    if (role == null && displayName == null) return;
    ensureIdentity();
    _revision = max(_revision + 1, DateTime.now().microsecondsSinceEpoch);
    for (final recipient in recipients.toSet()) {
      final type = diaryLinkTypes[role];
      final message =
          'Il Master comunica: [[${type == null ? '' : '$type:'}$originalName]]${role == null ? '' : ' — ruolo: ${diaryEditableRoles[role]}'}${displayName == null ? '' : ' — nome corretto: $displayName'}.';
      outbox.add({
        'id': base64UrlEncode(_knowledgeRandom(18)),
        'room': room,
        'senderTag': senderTag,
        'recipientTag': recipient,
        'entityId': entity.id,
        'originalName': originalName,
        'role': role,
        'displayName': displayName,
        'message': message,
        'revision': _revision,
        'createdAt': DateTime.now().toIso8601String(),
      });
    }
  }

  List<DiaryDocument> documentsFor(String room, String recipientTag) {
    final commands =
        received
            .where(
              (command) =>
                  command['room'] == room &&
                  command['recipientTag'] == recipientTag &&
                  command['message'] is String,
            )
            .toList()
          ..sort(
            (a, b) => (a['revision'] as int).compareTo(b['revision'] as int),
          );
    return [
      for (final command in commands)
        DiaryDocument(
          id: 'master-knowledge:${command['id']}',
          author: 'Master',
          diary: 'Comunicazioni del Master',
          title: '${command['createdAt']}',
          text: command['message'],
          day: 0,
        ),
    ];
  }

  bool acknowledge(String id, String recipient) {
    final length = outbox.length;
    outbox.removeWhere(
      (command) => command['id'] == id && command['recipientTag'] == recipient,
    );
    if (outbox.length != length) acknowledged.add(id);
    return outbox.length != length;
  }

  bool accept(Map<String, dynamic> command) {
    if (!_validCommand(command)) return false;
    final name = command['originalName'];
    final role = command['role'];
    final displayName = command['displayName'];
    if (command['id'] is! String ||
        command['entityId'] is! String ||
        command['revision'] is! int ||
        name is! String ||
        name.trim().isEmpty ||
        name.length > 120 ||
        (role != null && !diaryEditableRoles.containsKey(role)) ||
        (displayName != null &&
            (displayName is! String ||
                displayName.trim().isEmpty ||
                displayName.length > 120))) {
      return false;
    }
    if (received.any((item) => item['id'] == command['id'])) return false;
    received.add({
      ...Map<String, dynamic>.from(jsonDecode(jsonEncode(command))),
      'receivedAt': DateTime.now().toIso8601String(),
    });
    return true;
  }

  /// Per-field revisions keep a later name correction when an older role arrives.
  void apply(
    DiaryMemory memory, {
    String? room,
    String? recipientTag,
    DiaryRoleLedger? personal,
  }) {
    for (final entry in memory.entities.entries.toList()) {
      final entity = entry.value;
      if (entity.kind == 'diary' || entity.kind == 'campaign') continue;
      final matches =
          received
              .where(
                (command) =>
                    (room == null || command['room'] == room) &&
                    (recipientTag == null ||
                        command['recipientTag'] == recipientTag) &&
                    (command['entityId'] == entity.id ||
                        diaryKey('${command['originalName']}') ==
                            diaryKey(entity.name) ||
                        entity.aliases.any(
                          (alias) =>
                              diaryKey(alias) ==
                              diaryKey('${command['originalName']}'),
                        )),
              )
              .toList()
            ..sort(
              (a, b) => (a['revision'] as int).compareTo(b['revision'] as int),
            );
      var name = entity.name, role = entity.kind;
      final aliases = {...entity.aliases};
      for (final command in matches) {
        final receivedAt =
            DateTime.tryParse('${command['receivedAt']}') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final roleHistory = personal?.historyFor(entity) ?? const [];
        final nameHistory = personal?.nameHistoryFor(entity) ?? const [];
        final localRoleAt = roleHistory.isEmpty
            ? null
            : DateTime.tryParse('${roleHistory.last['at']}');
        final localNameAt = nameHistory.isEmpty
            ? null
            : DateTime.tryParse('${nameHistory.last['at']}');
        if (command['role'] != null &&
            (localRoleAt == null || !localRoleAt.isAfter(receivedAt))) {
          role = command['role'];
        }
        if (command['displayName'] != null &&
            (localNameAt == null || !localNameAt.isAfter(receivedAt))) {
          aliases.add(name);
          name = command['displayName'];
        }
      }
      memory.entities[entry.key] = DiaryEntity(
        entity.id,
        name,
        role,
        aliases.toList(),
        entity.linkType,
      );
    }
  }
}
