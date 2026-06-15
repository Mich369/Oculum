// ignore_for_file: avoid_print

import 'dart:io';

void main() {
  final file = File('lib/src/main/oculum_home_sheet_page.dart');
  var content = file.readAsStringSync();

  // Add focus nodes to the text inputs
  content = content.replaceFirst(
    "label: t('Resilienza', 'Resilience'),\n                  controller: resilienzaController,",
    "label: t('Resilienza', 'Resilience'),\n                  controller: resilienzaController,\n                  focusNode: resilienzaFocusNode,",
  );
  content = content.replaceFirst(
    "label: t('Volontà', 'Will'),\n                  controller: volontaController,",
    "label: t('Volontà', 'Will'),\n                  controller: volontaController,\n                  focusNode: volontaFocusNode,",
  );
  content = content.replaceFirst(
    "label: 'Materia',\n                  controller: materiaController,",
    "label: 'Materia',\n                  controller: materiaController,\n                  focusNode: materiaFocusNode,",
  );
  content = content.replaceFirst(
    "label: 'Oculum',\n                  controller: oculumController,",
    "label: 'Oculum',\n                  controller: oculumController,\n                  focusNode: oculumFocusNode,",
  );

  // Make stats clickable in the quickStatTile area
  content = content.replaceFirst(
    "quickStatTile(\n                label: t('Resilienza', 'Resilience'),\n                value: '\${resilienza()}',\n                icon: Icons.shield_moon,\n                color: const Color(0xFF6B8A5A),\n              ),",
    "quickStatTile(\n                label: t('Resilienza', 'Resilience'),\n                value: '\${resilienza()}',\n                icon: Icons.shield_moon,\n                color: const Color(0xFF6B8A5A),\n                onTap: () => vaiAllaFunzione(page: 0, anchorId: 'sheet_editable_values_resilienza'),\n              ),",
  );
  content = content.replaceFirst(
    "quickStatTile(\n                label: t('Volontà', 'Will'),\n                value: '\${volonta()}',\n                icon: Icons.local_fire_department,\n                color: const Color(0xFFAC5959),\n              ),",
    "quickStatTile(\n                label: t('Volontà', 'Will'),\n                value: '\${volonta()}',\n                icon: Icons.local_fire_department,\n                color: const Color(0xFFAC5959),\n                onTap: () => vaiAllaFunzione(page: 0, anchorId: 'sheet_editable_values_volonta'),\n              ),",
  );
  content = content.replaceFirst(
    "quickStatTile(\n                label: 'Materia',\n                value: '\${materia()}',\n                icon: Icons.ac_unit,\n                color: const Color(0xFF4A7D91),\n              ),",
    "quickStatTile(\n                label: 'Materia',\n                value: '\${materia()}',\n                icon: Icons.ac_unit,\n                color: const Color(0xFF4A7D91),\n                onTap: () => vaiAllaFunzione(page: 0, anchorId: 'sheet_editable_values_materia'),\n              ),",
  );
  content = content.replaceFirst(
    "quickStatTile(\n                label: 'Oculum',\n                value: '\${oculum()}',\n                icon: Icons.remove_red_eye,\n                color: const Color(0xFF8B5A8B),\n              ),",
    "quickStatTile(\n                label: 'Oculum',\n                value: '\${oculum()}',\n                icon: Icons.remove_red_eye,\n                color: const Color(0xFF8B5A8B),\n                onTap: () => vaiAllaFunzione(page: 0, anchorId: 'sheet_editable_values_oculum'),\n              ),",
  );

  // Update VC to go to volonta since VC is derived from volonta. Wait, VC already has onTap: mostraModificaRapida.
  // The user said: "Per VC: clic su VC -> porta a Volontà/VC o al campo più coerente"
  // Let's replace the existing onTap for VC and CM.
  content = content.replaceFirst(
    "quickStatTile(\n                label: 'VC',\n                value: '\${vc()}',\n                icon: Icons.flash_on,\n                color: tertiaryColor,\n                onTap: mostraModificaRapida,\n              ),",
    "quickStatTile(\n                label: 'VC',\n                value: '\${vc()}',\n                icon: Icons.flash_on,\n                color: tertiaryColor,\n                onTap: () => vaiAllaFunzione(page: 0, anchorId: 'sheet_editable_values_volonta'),\n              ),",
  );
  content = content.replaceFirst(
    "quickStatTile(\n                label: 'CM',\n                value: '\${cm()}',\n                icon: Icons.security,\n                color: primaryColor,\n              ),",
    "quickStatTile(\n                label: 'CM',\n                value: '\${cm()}',\n                icon: Icons.security,\n                color: primaryColor,\n                onTap: () => vaiAllaFunzione(page: 0, anchorId: 'sheet_editable_values_materia'),\n              ),",
  );

  file.writeAsStringSync(content);
  print('oculum_home_sheet_page.dart patched');
}
