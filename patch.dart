// ignore_for_file: avoid_print

import 'dart:io';

void main() {
  final file = File('lib/main.dart');
  var content = file.readAsStringSync();

  content = content.replaceAll(
    "final dannoCuraFocusNode = FocusNode();",
    "final dannoCuraFocusNode = FocusNode();\n  final resilienzaFocusNode = FocusNode();\n  final volontaFocusNode = FocusNode();\n  final materiaFocusNode = FocusNode();\n  final oculumFocusNode = FocusNode();",
  );

  content = content.replaceAll(
    "dannoCuraFocusNode.dispose();",
    "dannoCuraFocusNode.dispose();\n    resilienzaFocusNode.dispose();\n    volontaFocusNode.dispose();\n    materiaFocusNode.dispose();\n    oculumFocusNode.dispose();",
  );

  content = content.replaceAll(
    "case 'sheet_editable_values':\n        mostraValoriEditabiliScheda = true;",
    "case 'sheet_editable_values':\n      case 'sheet_editable_values_resilienza':\n      case 'sheet_editable_values_volonta':\n      case 'sheet_editable_values_materia':\n      case 'sheet_editable_values_oculum':\n        mostraValoriEditabiliScheda = true;",
  );

  content = content.replaceAll(
    "FocusNode? _focusNodeForAnchor(String? anchorId) {\n    switch (anchorId) {\n      case 'sheet_damage':\n      case 'sheet_heal':\n      case 'sheet_damage_heal':\n      case 'sheet_damage_heal_input':\n        return dannoCuraFocusNode;\n    }\n    return null;\n  }",
    "FocusNode? _focusNodeForAnchor(String? anchorId) {\n    switch (anchorId) {\n      case 'sheet_damage':\n      case 'sheet_heal':\n      case 'sheet_damage_heal':\n      case 'sheet_damage_heal_input':\n        return dannoCuraFocusNode;\n      case 'sheet_editable_values_resilienza':\n        return resilienzaFocusNode;\n      case 'sheet_editable_values_volonta':\n        return volontaFocusNode;\n      case 'sheet_editable_values_materia':\n        return materiaFocusNode;\n      case 'sheet_editable_values_oculum':\n        return oculumFocusNode;\n    }\n    return null;\n  }",
  );

  content = content.replaceAll(
    "final keyContext = _functionNavKeys[anchorId]?.currentContext;",
    "final baseAnchor = anchorId != null && anchorId.startsWith('sheet_editable_values_') ? 'sheet_editable_values' : anchorId;\n    final keyContext = _functionNavKeys[baseAnchor]?.currentContext;",
  );

  file.writeAsStringSync(content);
  print('main.dart patched');
}
