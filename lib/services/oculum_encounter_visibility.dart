/// Only explicitly discovered information leaves the Master's encounter.
/// Existing token identities and portraits are retained locally.
Map<String, dynamic> oculumPublicEncounterIdentity(Map<String, dynamic> token) {
  final type = '${token['type'] ?? ''}'.toLowerCase();
  final hiddenCreature =
      token['side'] == 'enemy' ||
      type.contains('mostro') ||
      type.contains('monster');
  final visibleName =
      [token['name'], token['visibleTitleName'], token['sheetTag'], token['id']]
          .map((value) => '${value ?? ''}'.trim())
          .firstWhere(
            (value) => value.isNotEmpty && value != '???',
            orElse: () => '???',
          );
  return {
    'name': hiddenCreature && token['nameRevealed'] != true
        ? '???'
        : visibleName,
    'imageBase64': '${token['imageBase64'] ?? ''}',
    // Generic monster art is never substituted for a Master's portrait.
    'spriteAssetPath': hiddenCreature
        ? ''
        : '${token['spriteAssetPath'] ?? ''}',
    'level': token['level'] ?? 0,
    if (token['blindSpotDiscovered'] == true)
      'discoveredBlindSpot': '${token['discoveredBlindSpot'] ?? ''}',
  };
}
