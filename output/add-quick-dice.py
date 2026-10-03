from pathlib import Path
p=Path('test/oculum_resistances_turns_integrity_test.dart');s=p.read_text(encoding='utf-8').replace("tipo: 'Materiale',", "peso: 1, note: 'Materiale',");p.write_text(s,encoding='utf-8')
p=Path('lib/src/main/oculum_home_dice_page.dart');s=p.read_text(encoding='utf-8');s=s.replace('      120,\n    ];','      120,\n      15,\n      25,\n      200,\n    ];',1).replace('final columns = availableWidth >= 760\n            ? 7','final columns = availableWidth >= 760\n            ? 9',1)
s=s.replace('final itemWidth = rawItemWidth\n            .clamp(dense ? 72.0 : 84.0, dense ? 104.0 : 120.0)\n            .toDouble();','final itemWidth = max(1.0, rawItemWidth);',1)
a=s.index('        Widget diceGrid(List<int> dice,');b=s.index('\n        return Column(',a);s=s[:a]+'''        Widget diceGrid() => Wrap(spacing: spacing, runSpacing: spacing, children: [
          for (final facce in [...classicDice, ...extraDice]) SizedBox(width: itemWidth, height: itemHeight,
            child: sheetDiceButton(facce, extra: !classicDice.contains(facce), dense: dense)),
        ]);
'''+s[b:];s=s.replace('diceGrid(classicDice, extra: false),\n            const SizedBox(height: 10),\n            diceGrid(extraDice, extra: true),','diceGrid(),',1);p.write_text(s,encoding='utf-8')
