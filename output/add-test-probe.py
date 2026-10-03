from pathlib import Path
p=Path('lib/src/main/oculum_performance_probe.dart');s=p.read_text(encoding='utf-8').replace('  Widget resistancePanel()', "  void openResistances() => _state.openResistanceDetails();\n  void openSubtraits() => _state.openReferenceDetail('Sottotratti', 'sheet_subtraits', _state.referenceSubtraitsPanel);\n  Widget resistancePanel()")
p.write_text(s,encoding='utf-8')
