/// Derived campaign memory. Never writes to a journal or to gameplay statistics.
class DiaryDocument {
  const DiaryDocument({
    required this.id,
    required this.author,
    required this.diary,
    required this.title,
    required this.text,
    required this.day,
  });
  final String id, author, diary, title, text;
  final int day;
}

class DiaryEntity {
  const DiaryEntity(
    this.id,
    this.name,
    this.kind, [
    this.aliases = const [],
    this.linkType,
  ]);
  final String id, name, kind;
  final List<String> aliases;
  final String? linkType;
}

/// Accepted aliases preserve old diary links and classify new explicit choices.
const diaryLinkKindByType = <String, String>{
  'personaggio': 'character',
  'pg': 'character',
  'party': 'party',
  'creatura': 'creature',
  'mostro': 'creature',
  'nemico': 'enemy',
  'alleato': 'party',
  'alleata': 'party',
  'alleati': 'party',
  'morto': 'dead',
  'morta': 'dead',
  'png': 'npc',
  'npc': 'npc',
  'luogo': 'place',
  'ambiente': 'place',
  'oggetto': 'item',
  'arma': 'weapon',
  'armatura': 'armor',
  'scudo': 'shield',
  'missione': 'quest',
  'quest': 'quest',
  'evento': 'event',
  'art': 'art',
  'titolo': 'title',
  'fazione': 'faction',
  'occhio dei caduti': 'fallen_eye',
  'occhio': 'fallen_eye',
};

class DiaryEvidence {
  const DiaryEvidence(this.document, this.start, this.end);
  final DiaryDocument document;
  final int start, end;
  String get quote => document.text.substring(start, end);
}

class DiaryRelation {
  const DiaryRelation(this.from, this.to, this.state, this.evidence);
  final String from, to, state;
  final DiaryEvidence evidence;
}

/// String IDs deliberately allow future states without an enum/save migration.
const diaryStateLabels = <String, String>{
  'seen': 'Avvistato',
  'met': 'Incontrato',
  'spoken': 'Parlato',
  'allied': 'Alleato',
  'hostile': 'Ostile',
  'fought': 'Combattuto',
  'injured': 'Ferito',
  'defeated': 'Sconfitto',
  'felled': 'Abbattuto',
  'killed': 'Ucciso',
  'escaped': 'Fuggito',
  'defeated_us': 'Ci ha sconfitto',
  'we_escaped': 'Noi siamo fuggiti',
  'captured': 'Catturato',
  'summoned': 'Evocato',
  'saved': 'Salvato',
  'betrayed': 'Tradito',
  'lost': 'Perso',
  'missing': 'Scomparso',
  'unknown': 'Stato sconosciuto',
  'uncertain': 'Esito incerto',
  'visited': 'Ha visitato',
  'observed_at': 'Osservato nel luogo',
  'written': 'Scritto in',
  'mentioned': 'Menzionato',
  'discovered': 'Scoperto',
  'died': 'Morto',
  'resonates': 'Risuona con',
};

class DiaryMemory {
  DiaryMemory(this.entities, this.relations);
  final Map<String, DiaryEntity> entities;
  final List<DiaryRelation> relations;
  List<DiaryRelation> backlinks(String id) =>
      relations.where((r) => r.from == id || r.to == id).toList();
  Set<String> diariesFor(String id) => backlinks(id)
      .map((r) => '${r.evidence.document.author}/${r.evidence.document.diary}')
      .toSet();

  /// Number of source-backed mentions and links. Repeated mentions deliberately
  /// increase the weight: the map reflects the living memory of the campaign.
  int mentionCount(String id) =>
      relations.where((r) => r.from == id || r.to == id).length;

  int uniqueConnectionCount(String id) => backlinks(id)
      .map((r) => r.from == id ? r.to : r.from)
      .where((other) => other != id)
      .toSet()
      .length;

  double importance(String id) =>
      1 + mentionCount(id) * .55 + uniqueConnectionCount(id) * 1.25;
}

String diaryKey(String value) => value.trim().toLowerCase();

class DiaryMemoryBuilder {
  DiaryMemoryBuilder({this.additionalStates = const {}});
  final Map<String, String> additionalStates;

  DiaryMemory build(
    List<DiaryDocument> documents,
    List<DiaryEntity> catalogue, {
    String? campaign,
  }) {
    final known = <String, DiaryEntity>{for (final e in catalogue) e.id: e};
    // Explicit links accept a type: [[luogo:Bosco Nero]], [[png:Arven]].
    for (final d in documents) {
      for (final m in RegExp(r'\[\[([^\]\n]+)\]\]').allMatches(d.text)) {
        final raw = m[1]!.split('|').first;
        final split = raw.indexOf(':');
        final name = (split < 0 ? raw : raw.substring(split + 1)).trim();
        if (name.isEmpty) continue;
        final kind = split < 0
            ? 'unknown'
            : diaryLinkKindByType[diaryKey(raw.substring(0, split))] ??
                  'unknown';
        final existing = known.values.where(
          (e) =>
              diaryKey(e.name) == diaryKey(name) ||
              e.aliases.any((a) => diaryKey(a) == diaryKey(name)),
        );
        if (existing.isEmpty) {
          known['$kind:${diaryKey(name)}'] = DiaryEntity(
            '$kind:${diaryKey(name)}',
            name,
            kind,
            const [],
            split < 0 ? null : raw.substring(0, split).trim(),
          );
        } else if (kind != 'unknown' && existing.length == 1) {
          final entity = existing.single;
          known[entity.id] = DiaryEntity(
            entity.id,
            entity.name,
            kind,
            entity.aliases,
            split < 0 ? entity.linkType : raw.substring(0, split).trim(),
          );
        }
      }
      for (final m in RegExp(
        r'\b(?:nel|nella|al|alla|a)\s+((?:Bosco|Foresta|Città|Villaggio|Tempio|Castello|Torre|Valle|Monte|Lago|Porto|Cripta|Rovine)\s+[A-ZÀ-Ý][\wÀ-ÿ]*(?:\s+[A-ZÀ-Ý][\wÀ-ÿ]*)*)',
      ).allMatches(d.text)) {
        final name = m[1]!;
        if (!known.values.any((e) => diaryKey(e.name) == diaryKey(name))) {
          known['place:${diaryKey(name)}'] = DiaryEntity(
            'place:${diaryKey(name)}',
            name,
            'place',
          );
        }
      }
      final freeNames = <String, String>{
        'npc':
            r'(?:parlato con|incontrato il mercante|incontrato la guardia|PNG)\s+([A-ZÀ-Ý][\wÀ-ÿ]+(?:\s+[A-ZÀ-Ý][\wÀ-ÿ]+)*)',
        'item':
            r'(?:oggetto|reliquia|artefatto|spada|sigillo)\s+([A-ZÀ-Ý][\wÀ-ÿ]+(?:\s+[A-ZÀ-Ý][\wÀ-ÿ]+)*)',
        'quest':
            r'(?:missione|incarico)\s+[«"“]?([A-ZÀ-Ý][\wÀ-ÿ]+(?:\s+[A-ZÀ-Ý][\wÀ-ÿ]+)*)',
      };
      for (final rule in freeNames.entries) {
        for (final match in RegExp(rule.value).allMatches(d.text)) {
          final name = match[1]!;
          if (!known.values.any((e) => diaryKey(e.name) == diaryKey(name))) {
            known['${rule.key}:${diaryKey(name)}'] = DiaryEntity(
              '${rule.key}:${diaryKey(name)}',
              name,
              rule.key,
            );
          }
        }
      }
    }
    final matchers = <String, RegExp>{
      for (final e in known.values)
        e.id: RegExp(
          '(?<![\\wÀ-ÿ])(?:${[e.name, ...e.aliases].where((n) => n.isNotEmpty).map(RegExp.escape).join('|')})(?![\\wÀ-ÿ])',
          caseSensitive: false,
        ),
    };
    final nodes = <String, DiaryEntity>{};
    final relations = <DiaryRelation>[];
    void add(
      DiaryEntity from,
      DiaryEntity to,
      String state,
      DiaryEvidence evidence,
    ) {
      nodes[from.id] = from;
      nodes[to.id] = to;
      relations.add(DiaryRelation(from.id, to.id, state, evidence));
    }

    for (final d in documents) {
      final candidates = known.values
          .where((e) => matchers[e.id]!.hasMatch(d.text))
          .toList();
      final author = DiaryEntity(
        'character:${diaryKey(d.author)}',
        d.author,
        'character',
      );
      final diary = DiaryEntity(
        'diary:${d.id}',
        '${d.diary} · ${d.title}',
        'diary',
      );
      DiaryEntity? previousTarget;
      DiaryEntity? previousPlace;
      for (final sentence in RegExp(r'[^.!?\n]+[.!?]?').allMatches(d.text)) {
        if (sentence[0]!.trim().isEmpty) continue;
        final evidence = DiaryEvidence(d, sentence.start, sentence.end);
        final text = sentence[0]!;
        final lower = text.toLowerCase();
        final mentioned = candidates
            .where((e) => matchers[e.id]!.hasMatch(text))
            .toList();
        add(author, diary, 'written', evidence);
        if (campaign != null) {
          add(
            DiaryEntity('campaign:${diaryKey(campaign)}', campaign, 'campaign'),
            diary,
            'written',
            evidence,
          );
        }
        final places = mentioned.where((e) => e.kind == 'place').toList();
        final targets = mentioned.where((e) => e.kind != 'place').toList();
        for (final place in places) {
          final visit = RegExp(
            '(?:nel|nella|al|alla|a)\\s+(?:\\[\\[luogo:)?${RegExp.escape(place.name)}',
            caseSensitive: false,
          ).hasMatch(text);
          add(
            author,
            place,
            visit && !RegExp(r'\bnon\b|forse|vorrei|andremo').hasMatch(lower)
                ? 'visited'
                : 'mentioned',
            evidence,
          );
        }
        if (targets.isEmpty &&
            previousTarget != null &&
            RegExp(
              r'\b(lo|lui|lei|esso|abbatterlo|ucciderlo|sconfiggerlo)\b',
            ).hasMatch(lower)) {
          targets.add(previousTarget);
        }
        for (final target in targets) {
          // Several subjects in a sentence are not enough to assign an outcome.
          final states = targets.length == 1 ? _states(lower) : ['mentioned'];
          for (final state in states) {
            add(author, target, state, evidence);
          }
          add(target, diary, 'mentioned', evidence);
          if (states.any(
            (s) => [
              'fought',
              'killed',
              'felled',
              'defeated',
              'defeated_us',
              'we_escaped',
              'escaped',
              'betrayed',
              'allied',
            ].contains(s),
          )) {
            final event = DiaryEntity(
              'event:${d.id}:${sentence.start}',
              '${states.map((s) => diaryStateLabels[s] ?? s).join(' · ')} — ${target.name}',
              'event',
            );
            add(author, event, 'mentioned', evidence);
            add(event, target, 'mentioned', evidence);
            add(event, diary, 'written', evidence);
          }
          final place = places.length == 1 ? places.single : previousPlace;
          if (place != null &&
              states.any((s) => ['seen', 'met', 'fought'].contains(s))) {
            add(target, place, 'observed_at', evidence);
          }
        }
        // Co-mentioned entities form a source-backed resonance. This adds
        // structure without inventing an outcome or changing the diary text.
        final coMentioned = <DiaryEntity>[...places, ...targets];
        if (coMentioned.length > 1) {
          for (var left = 0; left < coMentioned.length; left++) {
            for (var right = left + 1; right < coMentioned.length; right++) {
              add(coMentioned[left], coMentioned[right], 'resonates', evidence);
            }
          }
        }
        previousTarget = targets.length == 1 ? targets.single : null;
        previousPlace = places.length == 1 ? places.single : null;
      }
    }
    return DiaryMemory(nodes, relations);
  }

  List<String> _states(String text) {
    if (RegExp(
      r'non so|non sappiamo|forse|incert|chissà|potrebbe|sia morto|sembra|pare che|credo|spero|vorrei|avrei|sogn|sarebbe|ha detto|dice che|secondo|cercherò|voglio|dovremo',
    ).hasMatch(text)) {
      return ['uncertain'];
    }
    final result = <String>[];
    // Split contrastive/coordinate clauses so a negated fight does not erase a meeting.
    for (final clause in text.split(RegExp(r'\bma\b|\bperò\b|;|,|\be\b'))) {
      if (RegExp(r'\bnon\b|\bmai\b|senza|nessun').hasMatch(clause)) continue;
      final rules = <String, String>{
        'we_escaped': r'(?:abbiamo|ho|siamo|sono).*(?:scapp|fugg)|dovuto scapp',
        'defeated_us': r'(?:ci|mi) ha sconfitt|ci hanno sconfitt',
        'escaped': r'(?:è|era|ha|sono) fuggit|è scappat',
        'killed':
            r'(?:ho|abbiamo) uccis|riuscit[oi] (?:a|ad) ucciderlo|è stat[oa] uccis[oa]',
        'felled': r'(?:ho|abbiamo) abbatt|riuscit[oi] (?:a|ad) abbatterlo',
        'defeated':
            r'(?:ho|abbiamo) sconfitt|riuscit[oi] (?:a|ad) sconfiggerlo',
        'fought': r'combatt|affrontat|lottato',
        'met': r'incontrat',
        'seen': r'avvistat|ho visto|abbiamo visto',
        'spoken': r'parlato|dialogato',
        'allied': r'alleat|alleanza',
        'hostile': r'ostil|nemico',
        'injured': r'ferit',
        'captured': r'catturat',
        'summoned': r'evocat',
        'saved': r'salvat',
        'betrayed': r'tradit',
        'lost': r'perso|perdut',
        'missing': r'scompars',
        'discovered': r'scopert|trovat',
        'died': r'\b(?:è|era) mort[oa]\b',
        ...additionalStates,
      };
      for (final rule in rules.entries) {
        if (RegExp(rule.value).hasMatch(clause)) result.add(rule.key);
      }
    }
    if (result.contains('we_escaped')) {
      result.removeWhere((s) => s == 'escaped');
    }
    return result.isEmpty ? ['mentioned'] : result.toSet().toList();
  }
}
