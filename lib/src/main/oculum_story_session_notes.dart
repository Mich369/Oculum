part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

const int oculumSessionNoteMaxLength = 2000;
const int oculumSessionNoteSyncChunkSize = 20;

String _oculumSessionNoteText(Object? value, int maxLength) {
  final clean = '${value ?? ''}'.replaceAll('\u0000', '').trim();
  if (clean.length <= maxLength) return clean;
  return clean.substring(0, maxLength).trimRight();
}

String _oculumSessionNoteStableHash(String value) {
  var hash = 0x811C9DC5;
  for (final unit in value.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}

class OculumSessionNote {
  const OculumSessionNote({
    required this.id,
    required this.author,
    required this.authorTag,
    required this.message,
    required this.createdAt,
  });

  factory OculumSessionNote.create({
    required String author,
    required String authorTag,
    required String message,
    DateTime? createdAt,
  }) {
    final timestamp = (createdAt ?? DateTime.now()).toUtc();
    final entropy = Random().nextInt(0x7FFFFFFF).toRadixString(16);
    return OculumSessionNote(
      id: 'note_${timestamp.microsecondsSinceEpoch}_$entropy',
      author: _oculumSessionNoteText(author, 80),
      authorTag: _oculumSessionNoteText(authorTag, 128),
      message: _oculumSessionNoteText(message, oculumSessionNoteMaxLength),
      createdAt: timestamp,
    );
  }

  final String id;
  final String author;
  final String authorTag;
  final String message;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'author': author,
    'authorTag': authorTag,
    'message': message,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };

  static OculumSessionNote? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final data = Map<String, dynamic>.from(raw);
    final message = _oculumSessionNoteText(
      data['message'] ?? data['text'],
      oculumSessionNoteMaxLength,
    );
    if (message.isEmpty) return null;

    final author = _oculumSessionNoteText(
      data['author'] ?? data['playerName'] ?? '???',
      80,
    );
    final authorTag = _oculumSessionNoteText(
      data['authorTag'] ?? data['senderTag'],
      128,
    );
    final rawCreatedAt = '${data['createdAt'] ?? data['sentAt'] ?? ''}';
    final createdAt =
        DateTime.tryParse(rawCreatedAt)?.toUtc() ?? DateTime.now().toUtc();
    var id = _oculumSessionNoteText(data['id'] ?? data['noteId'], 160);
    if (id.isEmpty) {
      id =
          'legacy_${_oculumSessionNoteStableHash('$authorTag|$author|$rawCreatedAt|$message')}';
    }

    return OculumSessionNote(
      id: id,
      author: author.isEmpty ? '???' : author,
      authorTag: authorTag,
      message: message,
      createdAt: createdAt,
    );
  }
}

List<OculumSessionNote> oculumSessionNotesFromJson(Object? raw) {
  if (raw is! List) return <OculumSessionNote>[];
  final notes = <OculumSessionNote>[];
  final ids = <String>{};
  for (final entry in raw) {
    final note = OculumSessionNote.tryParse(entry);
    if (note == null || !ids.add(note.id)) continue;
    notes.add(note);
  }
  notes.sort(_oculumSessionNoteCompareAscending);
  return notes;
}

int _oculumSessionNoteCompareAscending(
  OculumSessionNote a,
  OculumSessionNote b,
) {
  final byTime = a.createdAt.compareTo(b.createdAt);
  return byTime != 0 ? byTime : a.id.compareTo(b.id);
}

int oculumMergeSessionNotes(
  List<OculumSessionNote> target,
  Iterable<OculumSessionNote> incoming,
) {
  final ids = target.map((note) => note.id).toSet();
  var added = 0;
  for (final note in incoming) {
    if (note.message.isEmpty || !ids.add(note.id)) continue;
    target.add(note);
    added++;
  }
  if (added > 0) target.sort(_oculumSessionNoteCompareAscending);
  return added;
}

List<List<Map<String, dynamic>>> oculumSessionNoteJsonChunks(
  Iterable<OculumSessionNote> notes, {
  int chunkSize = oculumSessionNoteSyncChunkSize,
}) {
  final safeChunkSize = max(1, chunkSize);
  final serialized = notes.map((note) => note.toJson()).toList();
  if (serialized.isEmpty) return <List<Map<String, dynamic>>>[[]];
  return <List<Map<String, dynamic>>>[
    for (var start = 0; start < serialized.length; start += safeChunkSize)
      serialized.sublist(start, min(serialized.length, start + safeChunkSize)),
  ];
}

String oculumSessionNoteDayKey(DateTime value) {
  final local = value.toLocal();
  return '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}

String oculumSessionNoteDayLabel(DateTime value, {required bool english}) {
  final local = value.toLocal();
  final today = DateTime.now();
  final todayKey = oculumSessionNoteDayKey(today);
  final dayKey = oculumSessionNoteDayKey(local);
  if (dayKey == todayKey) return english ? 'Today' : 'Oggi';
  final yesterday = today.subtract(const Duration(days: 1));
  if (dayKey == oculumSessionNoteDayKey(yesterday)) {
    return english ? 'Yesterday' : 'Ieri';
  }
  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/${local.year}';
}

String oculumSessionNoteTimeLabel(DateTime value) {
  final local = value.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}

class _OculumSessionTimelineItem {
  const _OculumSessionTimelineItem.day(this.day, this.date) : note = null;
  const _OculumSessionTimelineItem.note(this.note) : day = '', date = null;

  final String day;
  final DateTime? date;
  final OculumSessionNote? note;
}

extension _OculumStorySessionNotes on _OculumHomePageState {
  String storySessionAuthorTag() {
    final tag = sheetTagAt(schedaCorrente).trim();
    return tag.isNotEmpty ? tag : effectiveOculumUsername();
  }

  bool storySessionNotesTargetMatches(String targetTag) {
    final clean = targetTag.trim().toUpperCase();
    if (clean.isEmpty) return true;
    return <String>{
      storySessionAuthorTag(),
      ...localOculumTags(),
    }.map((tag) => tag.trim().toUpperCase()).contains(clean);
  }

  bool mergeStorySessionNotePayload(Object? raw) {
    final note = OculumSessionNote.tryParse(raw);
    if (note == null) return false;
    if (note.authorTag.isNotEmpty && isOculumFriendBlocked(note.authorTag)) {
      return false;
    }
    return oculumMergeSessionNotes(storySessionNotes, <OculumSessionNote>[
          note,
        ]) >
        0;
  }

  bool mergeStorySessionNotesSnapshot(Map<String, dynamic> payload) {
    if (!storySessionNotesTargetMatches('${payload['targetTag'] ?? ''}')) {
      return false;
    }
    final incoming = oculumSessionNotesFromJson(payload['notes']);
    final accepted = incoming.where(
      (note) =>
          note.authorTag.isEmpty || !isOculumFriendBlocked(note.authorTag),
    );
    return oculumMergeSessionNotes(storySessionNotes, accepted) > 0;
  }

  void scheduleStorySessionNotesSave() {
    storySessionNotesSaveTimer?.cancel();
    storySessionNotesSaveTimer = Timer(const Duration(milliseconds: 420), () {
      storySessionNotesSaveTimer = null;
      if (!mounted || !datiCaricati || salvataggioBloccatoPerErrore) return;
      unawaited(salvaDatiSoloLocale());
    });
  }

  void submitStorySessionNote() {
    final message = cleanUiText(storySessionNoteController.text).trim();
    if (message.isEmpty) return;
    final note = OculumSessionNote.create(
      author: realtimeDisplayName(),
      authorTag: storySessionAuthorTag(),
      message: message,
    );

    setState(() {
      oculumMergeSessionNotes(storySessionNotes, <OculumSessionNote>[note]);
      storySessionNoteController.clear();
    });
    scheduleStorySessionNotesSave();

    final service = realtimeService;
    if (service?.isConnected == true) {
      unawaited(
        service!.sendSessionNote(
          note: note.toJson(),
          campaignId: activeCampaignId,
          campaignName: activeCampaignName(),
        ),
      );
    }
    sendStorySessionNoteP2p(note);
  }

  void syncStorySessionNotesRealtime() {
    final service = realtimeService;
    if (service?.isConnected != true) return;
    final requesterTag = storySessionAuthorTag();
    unawaited(
      service!.requestSessionNotes(
        requesterTag: requesterTag,
        campaignId: activeCampaignId,
      ),
    );
    unawaited(sendRealtimeStorySessionNotesSnapshot());
  }

  Future<void> sendRealtimeStorySessionNotesSnapshot({
    String targetTag = '',
  }) async {
    final service = realtimeService;
    if (service?.isConnected != true) return;
    final chunks = oculumSessionNoteJsonChunks(storySessionNotes);
    final syncId =
        'notes_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(999999)}';
    for (var i = 0; i < chunks.length; i++) {
      if (service?.isConnected != true) return;
      await service!.sendSessionNotesSnapshot(
        notes: chunks[i],
        targetTag: targetTag,
        syncId: syncId,
        chunkIndex: i,
        chunkCount: chunks.length,
        campaignId: activeCampaignId,
        campaignName: activeCampaignName(),
      );
    }
  }

  List<Map<String, dynamic>> storySessionNotesSnapshotPayloads({
    String targetTag = '',
  }) {
    final chunks = oculumSessionNoteJsonChunks(storySessionNotes);
    final syncId =
        'notes_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(999999)}';
    return <Map<String, dynamic>>[
      for (var i = 0; i < chunks.length; i++)
        <String, dynamic>{
          'type': 'SESSION_NOTES_SNAPSHOT',
          'notes': chunks[i],
          'targetTag': targetTag,
          'syncId': syncId,
          'chunkIndex': i,
          'chunkCount': chunks.length,
          'campaignId': activeCampaignId,
          'campaignName': activeCampaignName(),
          'senderTag': storySessionAuthorTag(),
          'playerName': realtimeDisplayName(),
          'sentAt': DateTime.now().toUtc().toIso8601String(),
        },
    ];
  }

  bool get storySessionNotesSyncActive =>
      realtimeConnected ||
      relayConnected ||
      isConnectedToMaster ||
      isMasterHost;

  String storySessionNotesStatusLabel() {
    if (realtimeConnected) {
      return t('Realtime connesso', 'Realtime connected');
    }
    if (relayConnected) {
      return t('Stanza Internet connessa', 'Internet room connected');
    }
    if (isConnectedToMaster) {
      return t('Party locale connesso', 'Local party connected');
    }
    if (isMasterHost) return t('Sessione Master aperta', 'Master session open');
    return t('Offline - salvataggio locale', 'Offline - local save');
  }

  List<_OculumSessionTimelineItem> storySessionTimelineItems() {
    final sorted = List<OculumSessionNote>.from(storySessionNotes)
      ..sort((a, b) => -_oculumSessionNoteCompareAscending(a, b));
    final items = <_OculumSessionTimelineItem>[];
    var lastDay = '';
    for (final note in sorted) {
      final day = oculumSessionNoteDayKey(note.createdAt);
      if (day != lastDay) {
        items.add(_OculumSessionTimelineItem.day(day, note.createdAt));
        lastDay = day;
      }
      items.add(_OculumSessionTimelineItem.note(note));
    }
    return items;
  }

  Widget storyOnlineSessionNotesPanel() {
    final items = storySessionTimelineItems();
    final ownTag = storySessionAuthorTag().toUpperCase();
    final listHeight = min(430.0, max(180.0, items.length * 64.0));

    return gothicPanel(
      borderColor: storySessionNotesSyncActive
          ? Colors.greenAccent
          : primaryColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.forum_outlined, color: primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t('Appunti online', 'Online notes'),
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: storySessionNotesSyncActive
                      ? Colors.greenAccent
                      : Colors.white38,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            storySessionNotesStatusLabel(),
            style: TextStyle(
              color: storySessionNotesSyncActive
                  ? Colors.greenAccent
                  : Colors.white54,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            SizedBox(
              height: 90,
              child: Center(
                child: Text(
                  t(
                    'Nessun appunto per questa sessione.',
                    'No notes for this session.',
                  ),
                  style: const TextStyle(color: Colors.white54),
                ),
              ),
            )
          else
            SizedBox(
              height: listHeight,
              child: ListView.builder(
                key: ValueKey('story_notes_${activeCampaignId}_$ownTag'),
                itemCount: items.length,
                // Compatibilità Flutter 3.41/3.44.
                // ignore: deprecated_member_use
                cacheExtent: 360,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final note = item.note;
                  if (note == null) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      child: Row(
                        children: [
                          const Expanded(child: Divider(color: Colors.white24)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              oculumSessionNoteDayLabel(
                                item.date ?? DateTime.now(),
                                english: linguaInglese,
                              ),
                              style: TextStyle(
                                color: tertiaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider(color: Colors.white24)),
                        ],
                      ),
                    );
                  }
                  final own = note.authorTag.toUpperCase() == ownTag;
                  return Align(
                    alignment: own
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                        decoration: BoxDecoration(
                          color: own
                              ? primaryColor.withValues(alpha: 0.14)
                              : Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: own
                                ? primaryColor.withValues(alpha: 0.46)
                                : Colors.white24,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    note.author,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: own ? primaryColor : tertiaryColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  oculumSessionNoteTimeLabel(note.createdAt),
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            SelectableText(
                              note.message,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: storySessionNoteController,
                  minLines: 1,
                  maxLines: 3,
                  keyboardType: TextInputType.multiline,
                  inputFormatters: <TextInputFormatter>[
                    LengthLimitingTextInputFormatter(
                      oculumSessionNoteMaxLength,
                    ),
                  ],
                  style: const TextStyle(color: Colors.white),
                  decoration: fieldDecoration(
                    t('Appunto della sessione', 'Session note'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: t('Invia appunto', 'Send note'),
                onPressed: submitStorySessionNote,
                icon: const Icon(Icons.send),
                color: Colors.black,
                style: IconButton.styleFrom(
                  backgroundColor: primaryColor,
                  minimumSize: const Size(48, 48),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
