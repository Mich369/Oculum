import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'oculum_theme_effects_portrait_test.dart' as fixtures;

void main() {
  const base = {'resilienza': 14, 'volonta': 5, 'materia': 8, 'oculum': 0};
  for (final phases in [
    [
      (level: 0, multiplier: 6),
      (level: 1, multiplier: 9),
      (level: 2, multiplier: 9),
      (level: 3, multiplier: 10),
    ],
    [
      (level: 10, multiplier: 11),
      (level: 11, multiplier: 14),
      (level: 12, multiplier: 14),
      (level: 13, multiplier: 15),
    ],
  ]) {
    for (final offset in [-7, 5]) {
      testWidgets(
        'Fallen Eye editor keeps HP offset$offset across phase${phases.first.level}',
        (tester) async {
          final dynamic state = await fixtures.mountSheet(
            tester,
            const Size(834, 1000),
          );
          final probe = OculumPerformanceProbe(state);
          final initial = phases.first;
          final growth = oculumFallenEyeGrowthStats(initial.level, base);
          final stats = {
            for (final key in base.keys) key: base[key]! + growth[key]!,
          };
          final source = <String, dynamic>{
            'nome': 'Occhio personalizzato',
            'livello': '${initial.level}',
            'grado': '${initial.level ~/ 10}',
            'monsterBaseStats': {...base},
            'fallenEyeLevelStatBonuses': {...growth},
            for (final key in stats.keys) key: '${stats[key]}',
            'currentHp':
                '${stats['resilienza']! * initial.multiplier + offset}',
            'custom': {'preserved': 'testo e dati personali'},
          };
          final before = jsonEncode(source);
          final opening = probe.showCreateFallenEye(
            editingEye: {'rarity': 'comune', 'sheetData': source},
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 350));
          Finder field(String label) => find.byWidgetPredicate(
            (w) => w is TextField && w.decoration?.labelText == label,
          );
          int value(String label) => int.parse(
            tester.widget<TextField>(field(label)).controller!.text,
          );
          for (final phase in [...phases, ...phases.reversed]) {
            await tester.enterText(field('Livello'), '${phase.level}');
            await tester.pump();
            expect(
              value('Vita'),
              value('Resilienza') * phase.multiplier + offset,
              reason:
                  'Lv${phase.level}: fixed multiplier${phase.multiplier}, offset$offset',
            );
          }
          expect(
            value('Vita'),
            stats['resilienza']! * initial.multiplier + offset,
          );
          await tester.tap(find.text('Annulla'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 350));
          await opening;
          expect(
            jsonEncode(source),
            before,
            reason: 'Cancelled editor never rewrites custom source JSON',
          );
          probe.cancelPendingSave();
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump(const Duration(seconds: 3));
        },
      );
    }
  }
}
