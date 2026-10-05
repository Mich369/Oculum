import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/oculum_diary_memory.dart';
import '../services/oculum_diary_roles.dart';
import '../widgets/oculum_memory_eye.dart';

class OculumEyeMemoryPage extends StatefulWidget {
  const OculumEyeMemoryPage({
    super.key,
    required this.memory,
    required this.author,
    this.onRoleChanged,
    this.onRoleChangedWithNote,
    this.roleHistory,
    this.onNameChanged,
    this.onShareKnowledge,
    this.nameHistory,
    this.knowledgeChanges,
    this.eyeRole,
    this.onEyeChanged,
    this.statusOf,
    this.statusHistory,
    this.onStatusChanged,
  });
  final DiaryMemory memory;
  final String author;
  final String Function(DiaryEntity entity)? statusOf;
  final List<Map<String, dynamic>> Function(DiaryEntity entity)? statusHistory;
  final Future<void> Function(DiaryEntity entity, String status)?
  onStatusChanged;
  final Future<void> Function(DiaryEntity entity, String role)? onRoleChanged;
  final Future<void> Function(DiaryEntity entity, String role, String note)?
  onRoleChangedWithNote;
  final List<Map<String, dynamic>> Function(DiaryEntity entity)? roleHistory;
  final Future<void> Function(DiaryEntity entity, String name)? onNameChanged;
  final Future<void> Function(DiaryEntity entity)? onShareKnowledge;
  final List<Map<String, dynamic>> Function(DiaryEntity entity)? nameHistory;
  final Listenable? knowledgeChanges;
  final String Function(DiaryEntity entity)? eyeRole;
  final Future<void> Function(DiaryEntity entity, String? eyeRole)?
  onEyeChanged;
  @override
  State<OculumEyeMemoryPage> createState() => _OculumEyeMemoryPageState();
}

class _OculumEyeMemoryPageState extends State<OculumEyeMemoryPage> {
  String? selected;
  String query = '', kind = 'all';
  int page = 0;
  int timelineLimit = 60;
  List<DiaryEntity>? _matchingEntities;
  String _matchingQuery = '', _matchingKind = '';
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
    'obliterated': 'Obliterati / Oblio',
    'fallen_eye': 'Occhi dei Caduti',
    'weapon': 'Armi',
    'armor': 'Armature',
    'shield': 'Scudi',
    'art': 'Art',
    'title': 'Titoli',
    'faction': 'Fazioni',
    'upgrade': 'Potenziamenti',
    'skill': 'Skill',
    'forge': 'Forgiature',
    'crafting': 'Crafting',
  };

  Future<void> _changeState(DiaryEntity entity) async {
    if (widget.onStatusChanged == null ||
        entity.kind == 'diary' ||
        entity.kind == 'campaign') {
      return;
    }
    final next = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Stato di ${entity.name}'),
        children: [
          for (final entry in diaryProgressStates.entries)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, entry.key),
              child: Text(
                '${entry.value}${widget.statusOf?.call(entity) == entry.key ? ' ✓' : ''}',
              ),
            ),
        ],
      ),
    );
    if (!mounted || next == null) return;
    await widget.onStatusChanged!(entity, next);
    if (mounted) {
      setState(() {
        selected = entity.id;
      });
    }
  }

  Future<void> _nodeMenu(DiaryEntity entity, Offset position) async {
    if (entity.kind == 'diary' || entity.kind == 'campaign') return;
    final action = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(position.dx, position.dy, 1, 1),
        Offset.zero & MediaQuery.sizeOf(context),
      ),
      items: [
        if (widget.onStatusChanged != null)
          const PopupMenuItem(value: 'state', child: Text('Cambia stato')),
        if (widget.onRoleChangedWithNote != null ||
            widget.onRoleChanged != null)
          const PopupMenuItem(value: 'role', child: Text('Cambia categoria')),
        const PopupMenuItem(value: 'history', child: Text('Cronologia')),
      ],
    );
    if (!mounted || action == null) return;
    setState(() {
      selected = entity.id;
    });
    if (action == 'state') {
      await _changeState(entity);
      return;
    }
    if (action == 'role') {
      final role = await showDialog<String>(
        context: context,
        builder: (context) => SimpleDialog(
          title: Text('Categoria di ${entity.name}'),
          children: [
            for (final entry in diaryEditableRoles.entries)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, entry.key),
                child: Text(entry.value),
              ),
          ],
        ),
      );
      if (!mounted || role == null) return;
      if (widget.onRoleChangedWithNote != null) {
        await widget.onRoleChangedWithNote!(entity, role, '');
      } else {
        await widget.onRoleChanged!(entity, role);
      }
      if (mounted) {
        setState(() {
          _matchingEntities = null;
          kind = 'all';
        });
      }
      return;
    }
    if (action == 'history') {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Cronologia di ${entity.name}'),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final entry
                      in widget.statusHistory?.call(entity) ??
                          const <Map<String, dynamic>>[])
                    ListTile(
                      title: Text(
                        '${diaryProgressStates[entry['from']] ?? entry['from']} → ${diaryProgressStates[entry['to']] ?? entry['to']}',
                      ),
                      subtitle: Text('${entry['at']}'),
                    ),
                  for (final entry
                      in widget.roleHistory?.call(entity) ??
                          const <Map<String, dynamic>>[])
                    ListTile(
                      title: Text(
                        '${diaryEditableRoles[entry['from']] ?? entry['from']} → ${diaryEditableRoles[entry['to']] ?? entry['to']}',
                      ),
                      subtitle: Text('${entry['at']}'),
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
  }

  @override
  void initState() {
    super.initState();
    widget.knowledgeChanges?.addListener(_knowledgeChanged);
    selected = 'character:${diaryKey(widget.author)}';
    if (widget.memory.entities.containsKey(
      'campaign:${diaryKey(widget.author)}',
    )) {
      selected = 'campaign:${diaryKey(widget.author)}';
    }
    if (!widget.memory.entities.containsKey(selected)) selected = null;
  }

  void _knowledgeChanged() {
    _matchingEntities = null;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.knowledgeChanges?.removeListener(_knowledgeChanged);
    super.dispose();
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
        _matchingEntities != null &&
            _matchingQuery == query &&
            _matchingKind == kind
        ? _matchingEntities!
        : (memory.entities.values
              .where(
                (e) =>
                    (kind == 'all' || kind == e.kind) &&
                    (e.name.toLowerCase().contains(query.toLowerCase()) ||
                        e.aliases.any(
                          (alias) =>
                              alias.toLowerCase().contains(query.toLowerCase()),
                        )),
              )
              .toList()
            ..sort((a, b) {
              final byWeight = memory
                  .importance(b.id)
                  .compareTo(memory.importance(a.id));
              return byWeight == 0 ? a.name.compareTo(b.name) : byWeight;
            }));
    _matchingEntities = matches;
    _matchingQuery = query;
    _matchingKind = kind;
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
                  child: GestureDetector(
                    onSecondaryTapDown: (details) =>
                        _nodeMenu(e, details.globalPosition),
                    onLongPress: () => _changeState(e),
                    child: ActionChip(
                      avatar: OculumMemoryEye(
                        role: widget.eyeRole?.call(e) ?? e.kind,
                        size: 24,
                      ),
                      label: Text(e.name),
                      onPressed: () => setState(() {
                        selected = e.id;
                        page = 0;
                        timelineLimit = 60;
                      }),
                    ),
                  ),
                );
              },
            ),
          ),
          if (center != null) ...[
            if (widget.statusOf != null &&
                center.kind != 'diary' &&
                center.kind != 'campaign')
              ListTile(
                title: Text(
                  'Stato: ${diaryProgressStates[widget.statusOf!(center)] ?? widget.statusOf!(center)}',
                ),
                trailing: widget.onStatusChanged == null
                    ? null
                    : IconButton(
                        tooltip: 'Cambia stato',
                        icon: const Icon(Icons.edit_note),
                        onPressed: () => _changeState(center),
                      ),
              ),
            if ((widget.statusHistory?.call(center) ?? const []).isNotEmpty)
              ExpansionTile(
                title: const Text('Cronologia degli stati'),
                children: [
                  for (final entry in widget.statusHistory!(center))
                    ListTile(
                      title: Text(
                        '${diaryProgressStates[entry['from']] ?? entry['from']} → ${diaryProgressStates[entry['to']] ?? entry['to']}',
                      ),
                      subtitle: Text('${entry['at']}'),
                    ),
                ],
              ),
            Wrap(
              spacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '${center.name} · ${diaryEditableRoles[center.kind] ?? kinds[center.kind] ?? center.kind}',
                  style: const TextStyle(color: gold),
                ),
                if (widget.onEyeChanged != null &&
                    center.kind != 'campaign' &&
                    center.kind != 'diary')
                  OutlinedButton.icon(
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text('Scegli occhio'),
                    onPressed: () async {
                      final choice = await showDialog<String>(
                        context: context,
                        builder: (context) => SimpleDialog(
                          title: Text('Occhio di ${center.name}'),
                          children: [
                            for (final eye in diaryEyeChoices.entries)
                              SimpleDialogOption(
                                onPressed: () =>
                                    Navigator.pop(context, eye.key),
                                child: Row(
                                  children: [
                                    OculumMemoryEye(role: eye.key, size: 40),
                                    const SizedBox(width: 12),
                                    Expanded(child: Text(eye.value)),
                                  ],
                                ),
                              ),
                            SimpleDialogOption(
                              onPressed: () =>
                                  Navigator.pop(context, 'automatic'),
                              child: const Text('Automatico dal ruolo'),
                            ),
                          ],
                        ),
                      );
                      if (choice == null || !mounted) return;
                      await widget.onEyeChanged!(
                        center,
                        choice == 'automatic' ? null : choice,
                      );
                      if (mounted) setState(() {});
                    },
                  ),
                if ((widget.onRoleChanged != null ||
                        widget.onRoleChangedWithNote != null) &&
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
                      if (!mounted || !context.mounted) return;
                      if (widget.onRoleChangedWithNote != null) {
                        var draft = '';
                        final note = await showDialog<String>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Nota del cambiamento'),
                            content: SizedBox(
                              width: 480,
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${center.name}: ${diaryEditableRoles[center.kind] ?? center.kind} → ${diaryEditableRoles[role] ?? role}',
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      minLines: 3,
                                      maxLines: 6,
                                      decoration: const InputDecoration(
                                        labelText: 'Nota facoltativa',
                                        hintText:
                                            'Ucciso da [[Hoshy]] nel [[Bosco Nero]].',
                                        border: OutlineInputBorder(),
                                      ),
                                      onChanged: (value) => draft = value,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Nomi conosciuti e collegamenti [[Nome]] creano legami con questa nota come fonte. Per indicare chi lo ha ucciso, scrivi «Ucciso da Nome». La nota resta nella cronologia dell’Occhio; il Diario originale resta intatto.',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Annulla'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, draft),
                                child: const Text('Conferma cambiamento'),
                              ),
                            ],
                          ),
                        );
                        if (note == null || !mounted) return;
                        await widget.onRoleChangedWithNote!(center, role, note);
                      } else {
                        await widget.onRoleChanged!(center, role);
                      }
                      if (!mounted) return;
                      setState(() {
                        _matchingEntities = null;
                        kind = 'all';
                      });
                    },
                  ),
                if (widget.onNameChanged != null &&
                    center.kind != 'campaign' &&
                    center.kind != 'diary')
                  OutlinedButton.icon(
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Rinomina'),
                    onPressed: () async {
                      var draft = center.name;
                      final form = GlobalKey<FormState>();
                      final name = await showDialog<String>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Correggi il nome nella tua mappa'),
                          content: Form(
                            key: form,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'La frase originale del Diario resta la fonte. Il nome precedente rimane un alias.',
                                ),
                                TextFormField(
                                  initialValue: center.name,
                                  onChanged: (value) => draft = value,
                                  maxLength: 120,
                                  autofocus: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Nome corretto',
                                  ),
                                  validator: (value) =>
                                      value == null ||
                                          value.trim().isEmpty ||
                                          value.contains(RegExp(r'[\n\r\[\]|]'))
                                      ? 'Inserisci un nome valido'
                                      : null,
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Annulla'),
                            ),
                            FilledButton(
                              onPressed: () {
                                if (form.currentState!.validate()) {
                                  Navigator.pop(context, draft.trim());
                                }
                              },
                              child: const Text('Salva solo per me'),
                            ),
                          ],
                        ),
                      );
                      if (!mounted || name == null) return;
                      await widget.onNameChanged!(center, name);
                      _matchingEntities = null;
                      if (mounted) setState(() {});
                    },
                  ),
                if (widget.onShareKnowledge != null &&
                    center.kind != 'campaign' &&
                    center.kind != 'diary')
                  OutlinedButton.icon(
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Condividi con il party'),
                    onPressed: () => widget.onShareKnowledge!(center),
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
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${change['at'] ?? ''}'),
                          if ('${change['note'] ?? ''}'.isNotEmpty)
                            SelectableText('${change['note']}'),
                        ],
                      ),
                    ),
                ],
              ),
            if ((widget.nameHistory?.call(center) ?? const []).isNotEmpty)
              ExpansionTile(
                title: const Text('Evoluzione del nome'),
                children: [
                  for (final change in widget.nameHistory!(center))
                    ListTile(
                      dense: true,
                      title: Text('${change['from']} → ${change['to']}'),
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
                                  (58 +
                                      min(
                                        30.0,
                                        memory.importance(entry.key) * 2,
                                      )),
                              top:
                                  entry.value.dy -
                                  (entry.key == selected ? 42 : 32) -
                                  min(15.0, memory.importance(entry.key)),
                              width:
                                  116 +
                                  min(60.0, memory.importance(entry.key) * 4),
                              child: Semantics(
                                button: true,
                                label: memory.entities[entry.key]!.name,
                                child: InkWell(
                                  onSecondaryTapDown: (details) => _nodeMenu(
                                    memory.entities[entry.key]!,
                                    details.globalPosition,
                                  ),
                                  onLongPress: () =>
                                      _changeState(memory.entities[entry.key]!),
                                  onTap: () => setState(() {
                                    selected = entry.key;
                                    page = 0;
                                    timelineLimit = 60;
                                  }),
                                  child: Column(
                                    children: [
                                      OculumMemoryEye(
                                        role:
                                            widget.eyeRole?.call(
                                              memory.entities[entry.key]!,
                                            ) ??
                                            memory.entities[entry.key]!.kind,
                                        size:
                                            (entry.key == selected
                                                ? 84.0
                                                : 64.0) +
                                            min(
                                              30.0,
                                              memory.importance(entry.key) * 2,
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
      oldDelegate.center != center ||
      oldDelegate.fontFamily != fontFamily ||
      !mapEquals(oldDelegate.positions, positions) ||
      !mapEquals(oldDelegate.labels, labels);
}
