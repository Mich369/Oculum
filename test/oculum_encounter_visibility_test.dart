import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/services/oculum_encounter_visibility.dart';

void main() {
  test(
    'An undiscovered enemy shares no name, generic artwork or secret weakness',
    () {
      final public = oculumPublicEncounterIdentity({
        'side': 'enemy',
        'name': 'Custode',
        'level': 12,
        'spriteAssetPath': 'private.png',
        'discoveredBlindSpot': 'Collo',
        'fragility': 30,
        'notes': 'Segreto del Master',
      });
      expect(public['name'], '???');
      expect(public['spriteAssetPath'], '');
      expect(public['level'], 12);
      expect(public.containsKey('discoveredBlindSpot'), isFalse);
      expect(public.containsKey('fragility'), isFalse);
      expect(public.containsKey('notes'), isFalse);
    },
  );
  test(
    'Explicit discovery reveals only the approved identity and weakness',
    () {
      final public = oculumPublicEncounterIdentity({
        'type': 'mostro',
        'name': 'Custode',
        'nameRevealed': true,
        'imageBase64': 'master-portrait',
        'blindSpotDiscovered': true,
        'discoveredBlindSpot': 'Collo',
        'fragility': 30,
      });
      expect(public['name'], 'Custode');
      expect(public['imageBase64'], 'master-portrait');
      expect(public['discoveredBlindSpot'], 'Collo');
      expect(public.containsKey('fragility'), isFalse);
    },
  );
}
