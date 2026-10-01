import 'dart:math';
import 'package:flutter/material.dart';
import '../services/oculum_diary_memory.dart';
import '../services/oculum_diary_roles.dart';

class OculumEyeMemoryPage extends StatefulWidget {
  const OculumEyeMemoryPage({
    super.key,
    required this.memory,
    required this.author,
    this.onRoleChanged,
    this.roleHistory,
  });
  final DiaryMemory memory;
  final String author;
  final Future<void> Function(DiaryEntity entity, String role)? onRoleChanged;
  final List<Map<String, dynamic>> Function(DiaryEntity entity)? roleHistory;
  @override
  State<OculumEyeMemoryPage> createState() => _OculumEyeMemoryPageState();
}

class _OculumEyeMemoryPageState extends State<OculumEyeMemoryPage> {
  String? selected;
  String query = '', kind = 'all';
  int page = 0;
  int timelineLimit = 60;
  static const gold = Color(0xffc3a46b);
  static const kinds = {
    'all': 'Tutte le memorie',
    'character': 'Personaggi',
    'campaign': 'Campagna',
    'creature': 'Bestiario personale',
    'place': 'Luoghi conosciuti',
    'npc': 'PNG incontrati',
    'item': 'Oggetti scoperti',
    'quest': 'Missioni',
    'event': 'Eventi',
    'diary': 'Diari',
    'unknown': 'Nomi da classificare',
    'party': 'Party / Alleati',
    'enemy': 'Nemici',
    'dead': 'Morti',
    'fallen_eye': 'Occhi dei Caduti',
    'weapon': 'Armi',
    'armor': 'Armature',
    'shield': 'Scudi',
    'art': 'Art',
    'title': 'Titoli',
    'faction': 'Fazioni',
  };
  @override
  void initState() {
    super.initState();
    selected = 'character:${diaryKey(widget.author)}';
    if (widget.memory.entities.containsKey(
      'campaign:${diaryKey(widget.author)}',
    )) {
      selected = 'campaign:${diaryKey(widget.author)}';
    }
    if (!widget.memory.entities.containsKey(selected)) selected = null;
  }

  void showSource(DiaryEvidence evidence) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '${evidence.document.author} · ${evidence.document.diary}\n${evidence.document.title}',
        ),
        content: SizedBox(
          width: 620,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Giorno ${evidence.document.day} · Frase originale',
                  style: const TextStyle(color: gold),
                ),
                const SizedBox(height: 12),
                SelectableText.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: evidence.document.text.substring(
                          0,
                          evidence.start,
                        ),
                      ),
                      TextSpan(
                        text: evidence.quote,
                        style: const TextStyle(
                          color: gold,
                          backgroundColor: Color(0xff302537),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: evidence.document.text.substring(evidence.end),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final memory = widget.memory;
    final matches =
        memory.entities.values
            .where(
              (e) =>
                  (kind == 'all' || kind == e.kind) &&
                  e.name.toLowerCase().contains(query.toLowerCase()),
            )
            .toList()
          ..sort((a, b) {
            final byWeight = memory
                .importance(b.id)
                .compareTo(memory.importance(a.id));
            return byWeight == 0 ? a.name.compareTo(b.name) : byWeight;
          });
    final related = selected == null
        ? <DiaryRelation>[]
        : memory.backlinks(selected!);
    final neighbors = related
        .map((r) => r.from == selected ? r.to : r.from)
        .toSet()
        .where((id) => id != selected)
        .toList();
    final pageSize = MediaQuery.sizeOf(context).width < 600 ? 6 : 10;
    final maxPage = max(0, (neighbors.length - 1) ~/ pageSize);
    final currentPage = min(page, maxPage);
    final shown = neighbors
        .skip(currentPage * pageSize)
        .take(pageSize)
        .toList();
    final center = memory.entities[selected];
    final chronology = [...related]
      ..sort(
        (a, b) => a.evidence.document.day.compareTo(b.evidence.document.day),
      );
    return Scaffold(
      backgroundColor: const Color(0xff090910),
      appBar: AppBar(
        title: const Text('MAPPA DEGLI OCCHI'),
        backgroundColor: const Color(0xff17121e),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Le parole restano. Gli Occhi ricordano.',
            style: TextStyle(color: gold, fontSize: 22),
          ),
          const SizedBox(height: 8),
          const Text(
            'Scegli il centro della costellazione. Ogni legame apre la frase che lo ha generato. Le risonanze indicano nomi condivisi fra diari, senza confermare i racconti.',
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Cerca una memoria',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) => setState(() {
              query = value;
            }),
          ),
          const SizedBox(height: 8),
          if (pageSize == 6)
            DropdownButtonFormField<String>(
              initialValue: kind,
              decoration: const InputDecoration(
                labelText: 'Archivio delle memorie',
              ),
              items: kinds.entries
                  .map(
                    (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                  )
                  .toList(),
              onChanged: (value) => setState(() {
                kind = value ?? 'all';
              }),
            )
          else
            Wrap(
              spacing: 6,
              children: kinds.entries
                  .map(
                    (e) => ChoiceChip(
                      label: Text(e.value),
                      selected: kind == e.key,
                      onSelected: (_) => setState(() {
                        kind = e.key;
                      }),
                    ),
                  )
                  .toList(),
            ),
          if (matches.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Nessuna memoria. Scrivi nel Diario o collega un nome con [[luogo:Bosco Nero]], [[png:Arven]], [[oggetto:Sigillo]] o [[missione:La torre]].',
              ),
            ),
          SizedBox(
            height: 76,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: matches.length,
              separatorBuilder: (_, index) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                final e = matches[index];
                return Center(
                  child: ActionChip(
                    avatar: const Icon(Icons.visibility, size: 18),
                    label: Text(e.name),
                    onPressed: () => setState(() {
                      selected = e.id;
                      page = 0;
                      timelineLimit = 60;
                    }),
                  ),
                );
              },
            ),
          ),
          if (center != null) ...[
            Wrap(
              spacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '${center.name} · ${diaryEditableRoles[center.kind] ?? kinds[center.kind] ?? center.kind}',
                  style: const TextStyle(color: gold),
                ),
                if (widget.onRoleChanged != null &&
                    center.kind != 'campaign' &&
                    center.kind != 'diary')
                  OutlinedButton.icon(
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('Cambia ruolo'),
                    onPressed: () async {
                      final role = await showDialog<String>(
                        context: context,
                        builder: (context) => SimpleDialog(
                          title: Text('Ruolo di ${center.name}'),
                          children: [
                            for (final entry in diaryEditableRoles.entries)
                              SimpleDialogOption(
                                onPressed: () =>
                                    Navigator.pop(context, entry.key),
                                child: Text(
                                  '${entry.value}${entry.key == center.kind ? ' ✓' : ''}',
                                ),
                              ),
                          ],
                        ),
                      );
                      if (role == null || role == center.kind) return;
                      await widget.onRoleChanged!(center, role);
                      if (!mounted) return;
                      setState(() {
                        kind = 'all';
                      });
                    },
                  ),
              ],
            ),
            if ((widget.roleHistory?.call(center) ?? const []).isNotEmpty)
              ExpansionTile(
                title: const Text('Evoluzione del ruolo'),
                children: [
                  for (final change in widget.roleHistory!(center))
                    ListTile(
                      dense: true,
                      title: Text(
                        '${diaryEditableRoles[change['from']] ?? change['from']} → ${diaryEditableRoles[change['to']] ?? change['to']}',
                      ),
                      subtitle: Text('${change['at'] ?? ''}'),
                    ),
                ],
              ),
            SizedBox(
              height: 500,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = max(320.0, constraints.maxWidth);
                  final origin = Offset(width / 2, 250);
                  final positions = <String, Offset>{center.id: origin};
                  for (int i = 0; i < shown.length; i++) {
                    final angle = 2 * pi * i / max(1, shown.length) - pi / 2;
                    positions[shown[i]] =
                        origin +
                        Offset(cos(angle) * (width / 2 - 65), sin(angle) * 190);
                  }
                  return InteractiveViewer(
                    minScale: .5,
                    maxScale: 2.5,
                    constrained: false,
                    child: SizedBox(
                      width: width,
                      height: 500,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _ConstellationPainter(
                                positions,
                                center.id,
                                {
                                  for (final id in shown)
                                    id: related
                                        .where(
                                          (r) => r.from == id || r.to == id,
                                        )
                                        .map(
                                          (r) =>
                                              diaryStateLabels[r.state] ??
                                              r.state,
                                        )
                                        .toSet()
                                        .take(2)
                                        .join(' · '),
                                },
                                Theme.of(
                                  context,
                                ).textTheme.bodySmall?.fontFamily,
                              ),
                            ),
                          ),
                          for (final entry in positions.entries)
                            Positioned(
                              left:
                                  entry.value.dx -
                                  (58 + memory.importance(entry.key) * 2),
                              top: entry.value.dy - 35,
                              width: 116 + memory.importance(entry.key) * 4,
                              child: Semantics(
                                button: true,
                                label: memory.entities[entry.key]!.name,
                                child: InkWell(
                                  onTap: () => setState(() {
                                    selected = entry.key;
                                    page = 0;
                                    timelineLimit = 60;
                                  }),
                                  child: Column(
                                    children: [
                                      Container(
                                        width: entry.key == selected
                                            ? 54 +
                                                  min(
                                                    30.0,
                                                    memory.importance(
                                                          entry.key,
                                                        ) *
                                                        2,
                                                  )
                                            : 40 +
                                                  min(
                                                    30.0,
                                                    memory.importance(
                                                          entry.key,
                                                        ) *
                                                        2,
                                                  ),
                                        height:
                                            32 +
                                            min(
                                              18.0,
                                              memory.importance(entry.key),
                                            ),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: gold),
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
                                          color: const Color(0xff23162c),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Color(0x665f397a),
                                              blurRadius: 20,
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.visibility,
                                          color: gold,
                                        ),
                                      ),
                                      Text(
                                        '${memory.entities[entry.key]!.name} · ${memory.mentionCount(entry.key)}',
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: gold,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (neighbors.length > pageSize)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: currentPage > 0
                        ? () => setState(() {
                            page = currentPage - 1;
                          })
                        : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text(
                    'Legami ${currentPage + 1}/${maxPage + 1} · ${neighbors.length} nodi',
                  ),
                  IconButton(
                    onPressed: currentPage < maxPage
                        ? () => setState(() {
                            page = currentPage + 1;
                          })
                        : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            Text(
              '${center.name} · Cronologia e collegamenti',
              style: const TextStyle(color: gold, fontSize: 20),
            ),
            if (memory.diariesFor(center.id).length > 1)
              Text('Risonanze: ${memory.diariesFor(center.id).join(' · ')}'),
            for (final r in chronology.take(timelineLimit))
              Card(
                color: const Color(0xff17121e),
                child: ListTile(
                  key: ValueKey(
                    'memory_${r.evidence.document.id}_${r.evidence.start}_${r.from}_${r.to}_${r.state}',
                  ),
                  leading: const Icon(Icons.link, color: gold),
                  title: Text(
                    '${memory.entities[r.from]!.name} → ${diaryStateLabels[r.state] ?? r.state} → ${memory.entities[r.to]!.name}',
                  ),
                  subtitle: Text(
                    'Giorno ${r.evidence.document.day} · ${r.evidence.document.diary}\n${r.evidence.quote}',
                  ),
                  onTap: () => showSource(r.evidence),
                ),
              ),
            if (chronology.length > timelineLimit)
              OutlinedButton(
                onPressed: () => setState(() {
                  timelineLimit += 60;
                }),
                child: Text(
                  'Altri legami · $timelineLimit/${chronology.length} mostrati',
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ConstellationPainter extends CustomPainter {
  _ConstellationPainter(
    this.positions,
    this.center,
    this.labels,
    this.fontFamily,
  );
  final Map<String, Offset> positions;
  final String center;
  final Map<String, String> labels;
  final String? fontFamily;
  @override
  void paint(Canvas canvas, Size size) {
    final origin = positions[center]!;
    final paint = Paint()
      ..color = const Color(0xff796448)
      ..strokeWidth = 1;
    for (final point in positions.values) {
      canvas.drawLine(origin, point, paint);
    }
    for (final entry in labels.entries) {
      final point = positions[entry.key];
      if (point == null) continue;
      final text = TextPainter(
        text: TextSpan(
          text: entry.value,
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: 10,
            color: Color(0xffc3a46b),
            backgroundColor: Color(0xdd090910),
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 2,
      )..layout(maxWidth: 110);
      final middle = Offset.lerp(origin, point, .55)!;
      text.paint(canvas, middle - Offset(text.width / 2, text.height / 2));
    }
    final ring = Paint()
      ..color = const Color(0x335f397a)
      ..style = PaintingStyle.stroke;
    for (final radius in [65.0, 120.0, 200.0]) {
      canvas.drawCircle(origin, radius, ring);
    }
    final stars = Random(19);
    for (int i = 0; i < 90; i++) {
      canvas.drawCircle(
        Offset(
          stars.nextDouble() * size.width,
          stars.nextDouble() * size.height,
        ),
        i % 3 == 0 ? 1.4 : .7,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ConstellationPainter oldDelegate) =>
      oldDelegate.positions != positions;
}
