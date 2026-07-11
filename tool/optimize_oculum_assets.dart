import 'dart:io';
import 'dart:math';

import 'package:image/image.dart' as img;

const _assetRoots = <String>[
  'assets/icon',
  'assets/oculum',
  'assets/oculum_dungeon/generated_sprites',
];

const _spriteDirs = <String>[
  'assets/oculum/sprites',
  'assets/oculum/monsters',
  'assets/oculum/bosses',
  'assets/oculum/icons',
  'assets/oculum_dungeon/generated_sprites/enemies',
  'assets/oculum_dungeon/generated_sprites/equipment',
  'assets/oculum_dungeon/generated_sprites/npc',
];

const _largeUiAssets = <String, int>{
  'assets/icon/oculum_eye.png': 512,
  'assets/oculum/obser.png': 512,
  'assets/oculum/kingi_robot.png': 512,
  'assets/oculum/sfondo.png': 1280,
};

const _defaultSpriteMaxSide = 256;

class AssetReport {
  AssetReport({
    required this.path,
    required this.originalBytes,
    required this.optimizedBytes,
    required this.width,
    required this.height,
    required this.nextWidth,
    required this.nextHeight,
    required this.changed,
  });

  final String path;
  final int originalBytes;
  final int optimizedBytes;
  final int width;
  final int height;
  final int nextWidth;
  final int nextHeight;
  final bool changed;

  int get savedBytes => originalBytes - optimizedBytes;
}

Future<void> main(List<String> args) async {
  final apply = args.contains('--apply');
  final reports = <AssetReport>[];

  for (final root in _assetRoots) {
    final directory = Directory(root);
    if (!directory.existsSync()) continue;
    await for (final entity in directory.list(recursive: true)) {
      if (entity is! File || !entity.path.toLowerCase().endsWith('.png')) {
        continue;
      }
      final report = optimizePng(entity, apply: apply);
      if (report != null) reports.add(report);
    }
  }

  reports.sort((a, b) => b.originalBytes.compareTo(a.originalBytes));
  final originalTotal = reports.fold<int>(
    0,
    (sum, item) => sum + item.originalBytes,
  );
  final optimizedTotal = reports.fold<int>(
    0,
    (sum, item) => sum + item.optimizedBytes,
  );
  final changed = reports.where((item) => item.changed).toList()
    ..sort((a, b) => b.savedBytes.compareTo(a.savedBytes));

  stdout.writeln(
    '${apply ? 'Applied' : 'Scanned'} ${reports.length} PNG asset(s).',
  );
  stdout.writeln(
    'Total PNG size: ${fmt(originalTotal)} -> ${fmt(optimizedTotal)} '
    '(${fmt(originalTotal - optimizedTotal)} saved potential).',
  );
  stdout.writeln('Changed candidates: ${changed.length}.');
  stdout.writeln('');
  stdout.writeln('Top heavy assets:');
  for (final item in reports.take(40)) {
    stdout.writeln(
      '${fmt(item.originalBytes).padLeft(9)} '
      '${item.width}x${item.height} -> ${item.nextWidth}x${item.nextHeight} '
      '${item.path}',
    );
  }
  stdout.writeln('');
  stdout.writeln(apply ? 'Optimized assets:' : 'Optimization candidates:');
  for (final item in changed.take(80)) {
    stdout.writeln(
      '${fmt(item.originalBytes).padLeft(9)} -> '
      '${fmt(item.optimizedBytes).padLeft(9)} '
      'saved ${fmt(item.savedBytes).padLeft(9)} '
      '${item.width}x${item.height} -> ${item.nextWidth}x${item.nextHeight} '
      '${item.path}',
    );
  }
}

AssetReport? optimizePng(File file, {required bool apply}) {
  final path = normalize(file.path);
  final original = file.readAsBytesSync();
  final decoded = img.decodePng(original);
  if (decoded == null) return null;

  final maxSide = maxSideFor(path);
  final nextSize = fittedSize(decoded.width, decoded.height, maxSide);
  final working =
      nextSize.width == decoded.width && nextSize.height == decoded.height
      ? decoded
      : img.copyResize(
          decoded,
          width: nextSize.width,
          height: nextSize.height,
          interpolation: img.Interpolation.average,
        );

  final optimized = img.encodePng(working, level: 9);
  final changed = optimized.length < original.length;
  if (apply && changed) {
    file.writeAsBytesSync(optimized, flush: true);
  }

  return AssetReport(
    path: path,
    originalBytes: original.length,
    optimizedBytes: changed ? optimized.length : original.length,
    width: decoded.width,
    height: decoded.height,
    nextWidth: working.width,
    nextHeight: working.height,
    changed: changed,
  );
}

({int width, int height}) fittedSize(int width, int height, int maxSide) {
  final largest = max(width, height);
  if (largest <= maxSide) return (width: width, height: height);
  final scale = maxSide / largest;
  return (
    width: max(1, (width * scale).round()),
    height: max(1, (height * scale).round()),
  );
}

int maxSideFor(String path) {
  final explicit = _largeUiAssets[path];
  if (explicit != null) return explicit;
  if (_spriteDirs.any((dir) => path == dir || path.startsWith('$dir/'))) {
    return _defaultSpriteMaxSide;
  }
  return 1024;
}

String normalize(String path) => path.replaceAll('\\', '/');

String fmt(int bytes) {
  if (bytes >= 1024 * 1024) {
    return '${(bytes / 1024 / 1024).toStringAsFixed(2)} MB';
  }
  return '${(bytes / 1024).toStringAsFixed(1)} KB';
}
