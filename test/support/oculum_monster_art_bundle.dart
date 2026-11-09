import 'dart:io';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/widgets/oculum_monster_theme.dart';

Future<void> expectBundledMonsterArt(String canonicalPath) async {
  final asset = oculumMonsterArtworkAsset(canonicalPath)!;
  final bytes = File(asset).readAsBytesSync();
  final bundled = await rootBundle.load(asset);
  expect(
    listEquals(
      bundled.buffer.asUint8List(bundled.offsetInBytes, bundled.lengthInBytes),
      bytes,
    ),
    isTrue,
    reason: asset,
  );
}
