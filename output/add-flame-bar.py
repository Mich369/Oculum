from pathlib import Path
p=Path('lib/src/main/oculum_reference_sheet.dart');s=p.read_text(encoding='utf-8').replace('          if (referenceOculumFlames) oculumResourcePanel(),\n','');needle="                    if (!referenceOculumFlames)\n                      meter(";s=s.replace(needle,"                    if (referenceOculumFlames) referenceOculumFlameBar(),\n"+needle,1);s += '''

extension _OculumReferenceFlameBar on _OculumHomePageState {
  Widget referenceOculumFlameBar() {
    final current = oculumTotale();
    final maximum = oculumMassimo();
    final active = maximum <= 0 ? 0 : (current / maximum * 10).ceil().clamp(0, 10);
    final color = statFormulaColor('oculum');
    return Padding(padding: const EdgeInsets.only(top: 8), child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Oculum'), Text('$current/$maximum')]),
        const SizedBox(height: 3),
        Semantics(label: 'Oculum $current di $maximum', child: SizedBox(height: 24, child: LayoutBuilder(
          builder: (context, constraints) => Stack(alignment: Alignment.center, children: [
            Positioned(left: constraints.maxWidth / 20, right: constraints.maxWidth / 20,
              child: Container(height: 2, color: color.withValues(alpha: .35))),
            Row(children: [for (var index = 0; index < 10; index++) Expanded(child: Icon(
              Icons.local_fire_department, size: min(24.0, constraints.maxWidth / 10),
              color: index < active ? color : color.withValues(alpha: .20),
              shadows: index < active ? [Shadow(color: color.withValues(alpha: .55), blurRadius: 5)] : null,))]),
          ])))),
      ]));
  }
}
''';p.write_text(s,encoding='utf-8')
# Format lint fixes explicitly.
p=Path('lib/src/main/oculum_home_force_state.dart');s=p.read_text(encoding='utf-8');s=s.replace("        ))\n          return 'Già attivo: nessuna cura aggiuntiva.';", "        )) {\n          return 'Già attivo: nessuna cura aggiuntiva.';\n        }").replace("        ))\n          return '200% già attivo.';", "        )) {\n          return '200% già attivo.';\n        }").replace("        if (condition?.source == source)\n          removeCondition(condition!, force: true);", "        if (condition?.source == source) {\n          removeCondition(condition!, force: true);\n        }").replace("        ))\n      return;", "        )) {\n      return;\n    }");p.write_text(s,encoding='utf-8')
p=Path('lib/src/main/oculum_structured_effect_runtime.dart');s=p.read_text(encoding='utf-8').replace("          ))\n        terminaStatoForzaAttivo(applicaEsitoEsplosione: false);", "          )) {\n        terminaStatoForzaAttivo(applicaEsitoEsplosione: false);\n      }");p.write_text(s,encoding='utf-8')
