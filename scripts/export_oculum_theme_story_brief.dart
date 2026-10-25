import 'dart:convert';
import 'dart:io';
import 'package:oculum/widgets/oculum_theme_asset_packs.dart';

void main() {
  final briefs = [
    for (final pack in oculumThemeAssetPacks.values)
      {'id': pack.id, 'name': pack.name, 'motif': pack.motif, 'motion': pack.motion},
  ];
  File('build/oculum_theme_story_catalogue.json')
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(const JsonEncoder.withIndent('  ').convert(briefs));
  stdout.writeln('${briefs.length} theme briefs exported.');
}
