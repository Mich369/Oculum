part of '../../main.dart';

class OculumSearchHit {
  const OculumSearchHit({required this.title, required this.preview, required this.page, this.anchor});
  final String title;
  final String preview;
  final int page;
  final String? anchor;
}

extension _OculumGlobalSearch on _OculumHomePageState {
  List<OculumSearchHit> _searchOculum(String query) {
    final needle = oculumNormalizeText(query);
    if (needle.isEmpty) return const [];
    final hits = <OculumSearchHit>[];
    final pages = <String, int>{
      'scheda': 0, 'storia': 1, 'inventario': 2, 'risorse': 3, 'regole': 4,
      'master': 5, 'mappa': 6, 'impostazioni': 7, 'online': 8, 'dadi': 9,
      'ricette': 10, 'condizioni': 11, 'occhi': 12,
    };
    for (final entry in pages.entries) {
      if (oculumNormalizeText(entry.key).contains(needle)) {
        hits.add(OculumSearchHit(title: entry.key, preview: 'Sezione dell’app', page: entry.value));
      }
    }
    final raw = schedePersonaggio.isEmpty ? <String, dynamic>{} : schedePersonaggio[schedaCorrente];
    void scan(dynamic value, String path) {
      if (hits.length >= 80) return;
      if (value is Map) {
        for (final item in value.entries) scan(item.value, '$path/${item.key}');
      } else if (value is Iterable) {
        var index = 0; for (final item in value) scan(item, '$path[$index++]');
      } else if (oculumNormalizeText('$value').contains(needle)) {
        hits.add(OculumSearchHit(title: path.split('/').last, preview: '$value', page: 0, anchor: _anchorForSearchPath(path)));
      }
    }
    scan(raw, 'scheda');
    return hits;
  }

  String? _anchorForSearchPath(String path) {
    final lower = path.toLowerCase();
    if (lower.contains('buff') || lower.contains('danni')) return 'sheet_damage_heal';
    if (lower.contains('resilienza')) return 'sheet_editable_values_resilienza';
    if (lower.contains('volonta')) return 'sheet_editable_values_volonta';
    if (lower.contains('materia')) return 'sheet_editable_values_materia';
    if (lower.contains('oculum')) return 'sheet_editable_values_oculum';
    if (lower.contains('invent')) return 'inventory_root';
    return 'sheet_editable_values';
  }

  Future<void> openOculumGlobalSearch() async {
    final controller = TextEditingController();
    await showDialog<void>(context: context, builder: (dialogContext) {
      var hits = <OculumSearchHit>[];
      return StatefulBuilder(builder: (context, refresh) => AlertDialog(
        title: const Text('Cerca in Oculum  (Ctrl+F)'),
        content: SizedBox(width: 620, height: 480, child: Column(children: [
          TextField(controller: controller, autofocus: true, decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Cerca nell’app e nei testi della scheda…'),
            onChanged: (value) => refresh(() => hits = _searchOculum(value))),
          const SizedBox(height: 10), Expanded(child: hits.isEmpty ? const Center(child: Text('Scrivi una parola o una frase.')) : ListView.builder(
            itemCount: hits.length, itemBuilder: (context, index) { final hit = hits[index]; return ListTile(
              leading: const Icon(Icons.link), title: Text(hit.title), subtitle: Text(hit.preview, maxLines: 2, overflow: TextOverflow.ellipsis),
              onTap: () { Navigator.pop(dialogContext); vaiAllaFunzione(page: hit.page, anchorId: hit.anchor, logTitle: hit.title); });
            })),
        ])), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Chiudi'))],
      ));
    });
    controller.dispose();
  }
}
