import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/game/oculum_opposed_attack.dart';
import 'package:oculum/widgets/oculum_combat_theme.dart';
import 'package:oculum/widgets/oculum_element_theme_registry.dart';

void main() {
  test(
    'canonical element input keeps Demonic separate from Diabolic through damage resolution',
    () {
      final demonic = oculumNormalizeElementId('Demonic');
      final diabolic = oculumNormalizeElementId('Diabolic');
      expect(demonic, 'demoniaco');
      expect(diabolic, 'diabolico');
      expect(demonic, isNot(diabolic));
      expect(oculumElementDisplayEn(diabolic), 'Diabolic');
      expect(oculumElementDisplayEn(demonic), 'Demonic');
      for (final hp in [10, 100]) {
        expect(
          oculumElementalDefenseMultiplier(
            incomingElement: demonic,
            defenseElement: diabolic,
            currentHp: hp,
            maximumHp: 100,
          ),
          .25,
        );
      }
      expect(
        oculumElementalDefenseMultiplier(
          incomingElement: diabolic,
          defenseElement: diabolic,
          currentHp: 100,
          maximumHp: 100,
        ),
        1,
      );
    },
  );
  test(
    'Cloud and Rock keep their identities and all three elements have distinct artwork',
    () {
      expect(oculumNormalizeElementId('Cloud'), 'nuvola');
      expect(oculumNormalizeElementId('Rock'), 'roccia');
      expect(oculumCombatElementId('Demonic'), 'demoniaco');
      final ids = ['demoniaco', 'diabolico', 'nuvola', 'roccia'];
      expect(
        ids.map((id) => oculumElementThemePackIds[id]).toSet(),
        hasLength(4),
      );
      for (final id in ids) {
        expect(oculumDefaultElementIds, contains(id));
        expect(oculumCombatElementFamily(id), isNotNull);
      }
    },
  );
}
