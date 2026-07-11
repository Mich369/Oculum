import 'dart:io';
import 'dart:math';

import 'package:image/image.dart' as img;
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

const outputSize = 512;
const enemyDir = 'assets/oculum_dungeon/generated_sprites/enemies';
const atlasDir = 'assets/oculum_dungeon/generated_sprites/atlases';

class AtlasSpec {
  const AtlasSpec(
    this.fileName,
    this.grid, {
    this.margin = 0,
    this.gap = 0,
    this.inset = 0,
  });

  final String fileName;
  final int grid;
  final int margin;
  final int gap;
  final int inset;
}

int stableSeed(String text) => monsterSpriteStableSeed(text);

List<img.Image> loadAtlasCells(AtlasSpec spec) {
  final file = File('$atlasDir/${spec.fileName}');
  final atlas = img.decodeImage(file.readAsBytesSync());
  if (atlas == null) {
    throw StateError('Impossibile leggere ${file.path}');
  }
  final cellWidth =
      ((atlas.width - spec.margin * 2 - spec.gap * (spec.grid - 1)) / spec.grid)
          .round();
  final cellHeight =
      ((atlas.height - spec.margin * 2 - spec.gap * (spec.grid - 1)) /
              spec.grid)
          .round();
  final inset = spec.inset > 0
      ? spec.inset
      : max(2, min(cellWidth, cellHeight) ~/ 42);
  final cells = <img.Image>[];
  for (var row = 0; row < spec.grid; row++) {
    for (var col = 0; col < spec.grid; col++) {
      final left = spec.margin + col * (cellWidth + spec.gap);
      final top = spec.margin + row * (cellHeight + spec.gap);
      final crop = img.copyCrop(
        atlas,
        x: left + inset,
        y: top + inset,
        width: cellWidth - inset * 2,
        height: cellHeight - inset * 2,
      );
      cells.add(
        img.copyResize(
          crop,
          width: outputSize,
          height: outputSize,
          interpolation: img.Interpolation.cubic,
        ),
      );
    }
  }
  return cells;
}

img.Image naturalVariant(
  img.Image source, {
  required int seed,
  required bool boss,
  required bool miniBoss,
  required bool variant,
}) {
  var image = source.clone();
  if (seed.isOdd) {
    image = img.copyFlip(image, direction: img.FlipDirection.horizontal);
  }

  final hueR = ((seed * 37) % 47) - 23;
  final hueG = ((seed * 53) % 39) - 19;
  final hueB = ((seed * 71) % 55) - 27;
  final contrast = boss
      ? 1.11
      : miniBoss
      ? 1.10
      : 1.03;
  final darken = boss
      ? 7
      : miniBoss
      ? 7
      : 3;
  final variantBoost = variant ? 18 : 0;

  for (final p in image) {
    final x = p.x;
    final y = p.y;
    final dx = (x - outputSize / 2).abs() / (outputSize / 2);
    final dy = (y - outputSize / 2).abs() / (outputSize / 2);
    final vignette = max(0, (dx * dx + dy * dy - 0.58) * 38).round();
    final grain = ((x * 13 + y * 17 + seed) % 9) - 4;
    final r =
        (((p.r - 128) * contrast) + 128 + hueR + grain - darken - vignette)
            .clamp(0, 255)
            .round();
    final g =
        (((p.g - 128) * contrast) + 128 + hueG + grain - darken - vignette)
            .clamp(0, 255)
            .round();
    final b =
        (((p.b - 128) * contrast) +
                128 +
                hueB +
                grain +
                variantBoost -
                darken -
                vignette)
            .clamp(0, 255)
            .round();
    image.setPixelRgba(x, y, r, g, b, p.a.round());
  }

  return image;
}

void saveSprite(String path, img.Image image) {
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(img.encodePng(image, level: 7));
}

void deleteOldGeneratedVariants() {
  final dir = Directory(enemyDir);
  if (!dir.existsSync()) return;
  for (final file in dir.listSync().whereType<File>()) {
    final name = file.uri.pathSegments.last;
    if (name.contains('_variant_') && name.endsWith('.png')) {
      file.deleteSync();
    }
  }
}

void main() {
  final normalCells = [
    ...loadAtlasCells(const AtlasSpec('normal_1.png', 5, margin: 17, gap: 14)),
    ...loadAtlasCells(const AtlasSpec('normal_2.png', 6, margin: 38, gap: 11)),
  ];
  final miniBossCells = loadAtlasCells(
    const AtlasSpec('miniboss_1.png', 5, margin: 18, gap: 8, inset: 10),
  );
  final bossCells = loadAtlasCells(
    const AtlasSpec('boss_mix.png', 6, margin: 30, gap: 12, inset: 10),
  );
  final variantCells = [
    ...loadAtlasCells(const AtlasSpec('variants.png', 6, inset: 8)),
    ...normalCells,
    ...miniBossCells,
    ...bossCells,
  ];

  deleteOldGeneratedVariants();

  final groupedPaths = <String, List<String>>{};
  for (final monster in monsterBookEntries) {
    groupedPaths
        .putIfAbsent(monster.spriteAssetPath, () => <String>[])
        .add(monster.id);
  }
  final duplicatePaths = groupedPaths.entries
      .where((entry) => entry.value.length > 1)
      .toList(growable: false);
  if (duplicatePaths.isNotEmpty) {
    stdout.writeln('Percorsi sprite condivisi:');
    for (final entry in duplicatePaths) {
      stdout.writeln('  ${entry.key}: ${entry.value.join(', ')}');
    }
  }

  final normals = monsterBookEntries
      .where((m) => !m.isMiniBoss && !m.isBoss)
      .toList(growable: false);
  final miniBosses = monsterBookEntries
      .where((m) => m.isMiniBoss)
      .toList(growable: false);
  final bosses = monsterBookEntries
      .where((m) => m.isBoss)
      .toList(growable: false);

  var variantCursor = 0;

  void writeMonster(MonsterBookEntry monster, img.Image source, int index) {
    final seed = stableSeed('${monster.id}:$index');
    saveSprite(
      monster.spriteAssetPath,
      naturalVariant(
        source,
        seed: seed,
        boss: monster.isBoss,
        miniBoss: monster.isMiniBoss,
        variant: false,
      ),
    );

    for (var v = 1; v <= monsterSpriteVariantCount(monster.id); v++) {
      final variantSource = variantCells[variantCursor % variantCells.length];
      variantCursor++;
      saveSprite(
        monsterSpriteVariantAssetPath(monster.spriteAssetPath, v),
        naturalVariant(
          variantSource,
          seed: stableSeed('${monster.id}:variant:$v'),
          boss: monster.isBoss,
          miniBoss: monster.isMiniBoss,
          variant: true,
        ),
      );
    }
  }

  for (var i = 0; i < normals.length; i++) {
    writeMonster(normals[i], normalCells[i % normalCells.length], i);
  }
  for (var i = 0; i < miniBosses.length; i++) {
    final pool = i < miniBossCells.length ? miniBossCells : bossCells;
    writeMonster(miniBosses[i], pool[i % pool.length], i);
  }
  for (var i = 0; i < bosses.length; i++) {
    writeMonster(bosses[i], bossCells[i % bossCells.length], i);
  }

  stdout.writeln(
    'Applicati ${monsterBookEntries.length} sprite anime e $variantCursor varianti.',
  );
}
