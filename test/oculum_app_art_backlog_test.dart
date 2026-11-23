import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'package:oculum/widgets/oculum_monster_theme.dart';

void main() {
  test(
    'active VTT creature artwork resolves to existing assets and exports remaining work',
    () {
      final rows = <Map<String, Object?>>[];
      final missingAssets = <String>[];
      for (final entry in defaultMonsterBookEntries.where(
        (entry) => entry.visibleInMonsterBook && !entry.isNpc,
      )) {
        final theme = OculumMonsterTheme(
          entry,
          oculumMonsterColors(entry).first,
        );
        final assets = {
          'desktop': theme.illustration,
          'phone': theme.illustrationMobile,
          'relic': theme.relicIllustration,
        };
        for (final asset in assets.values.whereType<String>()) {
          if (!File(asset).existsSync())
            missingAssets.add('${entry.id}: $asset');
        }
        rows.add({
          'id': entry.id,
          'name': entry.nameIt,
          'nameEn': entry.nameEn,
          'habitats': entry.planeIds,
          ...assets,
          'missingDedicatedArtwork': [
            for (final asset in assets.entries)
              if (asset.value == null) asset.key,
          ],
        });
      }
      expect(missingAssets, isEmpty);
      expect(rows.map((row) => row['id']).toSet(), hasLength(rows.length));
      rows.sort((a, b) => '${a['name']}'.compareTo('${b['name']}'));
      final summary = {
        'activeCreatureEntriesIncludingVariants': rows.length,
        for (final kind in ['desktop', 'phone', 'relic'])
          '${kind}Missing': rows.where((row) => row[kind] == null).length,
      };
      final directory = Directory('build/app-art-backlog-audit')
        ..createSync(recursive: true);
      File('${directory.path}/inventory.json').writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert({'scope': 'Active non-NPC VTT catalogue; current names and resolved dedicated asset mappings. Does not infer approvals or rename votes. Desktop fallback on phones does not count as a dedicated phone asset.', 'summary': summary, 'entries': rows})}\n',
      );
      final text = StringBuffer(
        '# Artwork e nomi attuali delle creature VTT\n\n',
      );
      text.writeln(
        'Elenco ricavato dal catalogo attivo e dal risolutore degli asset. Include le varianti ed esclude gli NPC e le voci ritirate. Un collegamento non certifica lo stile o un nuovo voto. «Da completare» indica un asset dedicato assente; il fallback desktop sul telefono resta disponibile.\n',
      );
      text.writeln('Riepilogo: ${jsonEncode(summary)}\n');
      text.writeln('| ID | Nome attuale | Asset dedicati da completare |');
      text.writeln('| --- | --- | --- |');
      for (final row in rows) {
        final missing = (row['missingDedicatedArtwork'] as List).join(', ');
        text.writeln(
          '| ${row['id']} | ${'${row['name']}'.replaceAll('|', '/')} | ${missing.isEmpty ? 'Nessuno' : missing} |',
        );
      }
      File('${directory.path}/inventory.md').writeAsStringSync(text.toString());
    },
  );
}
