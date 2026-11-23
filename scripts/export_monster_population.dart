import 'dart:convert';
import 'dart:io';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

void main(List<String> args) {
  final enemies = monsterBookEntries
      .where(
        (entry) =>
            entry.visibleInMonsterBook &&
            !entry.isNpc &&
            entry.generationSide == 'enemy',
      )
      .toList();
  final areas =
      <Map<String, dynamic>>[
        for (final habitat in oculumMonsterHabitats.entries)
          buildArea(habitat.key, habitat.value, enemies),
      ]..sort(
        (a, b) => (a['independentForms'] as int).compareTo(
          b['independentForms'] as int,
        ),
      );
  final output = File(
    args.isEmpty
        ? 'output/artwork/POPOLAZIONE-NEMICI-PER-AREA-20261118.json'
        : args.first,
  );
  output.parent.createSync(recursive: true);
  output.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert({'schemaVersion': 1, 'generatedAtUtc': DateTime.now().toUtc().toIso8601String(), 'source': 'live_runtime_monster_catalogue', 'countingRule': 'Visible hostile non-NPC entries. Canonical _variante_ forms counted separately. A multi-habitat entry appears in each authored habitat; area totals are not a global sum.', 'hostileEntries': enemies.length, 'withoutAssignedHabitat': enemies.where((entry) => entry.planeIds.isEmpty).length, 'areas': areas})}\n',
  );
  for (final area in areas.take(6)) {
    stdout.writeln(
      '${area['name']}: ${area['independentForms']} basi/forme indipendenti, ${area['variantForms']} varianti.',
    );
  }
}

Map<String, dynamic> buildArea(
  String id,
  String name,
  List<MonsterBookEntry> enemies,
) {
  final entries = enemies
      .where((entry) => entry.planeIds.contains(id))
      .toList();
  final variants = entries
      .where((entry) => RegExp(r'_variante_[a-z]+$').hasMatch(entry.id))
      .length;
  return {
    'id': id,
    'name': name,
    'type': oculumMicroRealityIds.contains(id) ? 'microreality' : 'realm',
    'independentForms': entries.length - variants,
    'variantForms': variants,
    'totalEntries': entries.length,
    'ids': [for (final entry in entries) entry.id],
  };
}
