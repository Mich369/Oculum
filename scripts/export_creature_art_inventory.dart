// Pure Dart catalog export: does not import the Flutter application/runtime.
import 'dart:convert';
import 'dart:io';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

void main(List<String> args) {
  final destination = File(args.isEmpty
      ? 'build/creature-art-catalogue.json'
      : args.first);
  final rows = [
    for (final monster in defaultMonsterBookEntries)
      {
        'id': monster.id,
        'name': monster.nameIt,
        'planes': monster.planeIds,
        'element': monster.elementId,
        'classification': monster.classificationTags,
        'isBoss': monster.isBoss,
        'isMiniBoss': monster.isMiniBoss,
        'physicalDescription': oculumMonsterPhysicalDescription(monster),
        'anatomy': oculumMonsterPrecisionAnatomy(monster),
        'weakPoint': monster.weakPointDescriptionIt,
        'naturalAttitude': oculumMonsterNaturalAttitude(monster),
        'drops': monster.dropIds,
        'inventoryItems': monster.inventoryItems,
        'encounterRules': monster.encounterRules,
      },
  ];
  destination.parent.createSync(recursive: true);
  destination.writeAsStringSync(const JsonEncoder.withIndent('  ').convert({
    'schemaVersion': 1,
    'exportedAtUtc': DateTime.now().toUtc().toIso8601String(),
    'source': 'defaultMonsterBookEntries',
    'entriesIncludingVariants': rows.length,
    'entries': rows,
  }));
  stdout.writeln('${rows.length} catalog entries including variants exported to ${destination.path}.');
}
