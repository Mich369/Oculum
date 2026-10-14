import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oculum/widgets/oculum_combat_theme.dart';
import 'package:oculum/widgets/oculum_goth_ornaments.dart';
import 'package:oculum/main.dart' show oculumDefaultElementIds;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('automatic materials follow the resolved dominant damage', () async {
    final controller = OculumCombatThemeController();
    await controller.setAutomatic(true);

    expect(
      controller.resolveOutgoingAction(
        actionId: 'mixed-1',
        hitDamageByElement: [
          {'fisico': 15, 'fuoco': 13},
        ],
      ),
      isTrue,
    );
    expect(controller.value.elementId, 'fisico');
    expect(controller.value.secondaryElementId, isEmpty);
    expect(controller.value.activeFamily, OculumGothFamily.forged);

    controller.resolveOutgoingAction(
      actionId: 'mixed-2',
      hitDamageByElement: [
        {'fisico': 15, 'fuoco': 21},
      ],
    );
    expect(controller.value.elementId, 'fuoco');
    expect(controller.value.activeFamily, OculumGothFamily.ember);
    controller.dispose();
  });

  test('all default resistance elements resolve to a visual family', () {
    for (final element in oculumDefaultElementIds) {
      expect(
        oculumCombatElementFamily(element),
        isNotNull,
        reason: '$element needs an element-specific visual treatment.',
      );
    }
    expect(oculumCombatElementFamily('acido'), OculumGothFamily.acid);
    expect(oculumCombatElementFamily('spirituale'), OculumGothFamily.spirit);
  });

  test(
    'multihit is aggregated once and retains a near-equal secondary type',
    () async {
      final controller = OculumCombatThemeController();
      await controller.setAutomatic(true);

      controller.resolveOutgoingAction(
        actionId: 'multi-1',
        hitDamageByElement: [
          {'fisico': 7, 'fuoco': 6},
          {'fisico': 7, 'fuoco': 8},
        ],
      );
      expect(controller.value.elementId, 'fisico');
      expect(controller.value.secondaryElementId, 'fuoco');

      controller.resolveOutgoingAction(
        actionId: 'multi-2',
        hitDamageByElement: [
          {'fisico': 15, 'fuoco': 14},
        ],
      );
      expect(controller.value.elementId, 'fisico');
      expect(controller.value.secondaryElementId, 'fuoco');
      controller.dispose();
    },
  );

  test(
    'normal attacks, duplicate actions and unknown elements do not switch',
    () async {
      final controller = OculumCombatThemeController();
      await controller.setAutomatic(true);
      controller.resolveOutgoingAction(
        actionId: 'first',
        hitDamageByElement: [
          {'fuoco': 10},
        ],
      );

      expect(
        controller.resolveOutgoingAction(
          actionId: 'normal',
          hitDamageByElement: [
            {'fisico': 100},
          ],
          normalAction: true,
        ),
        isFalse,
      );
      expect(
        controller.resolveOutgoingAction(
          actionId: 'first',
          hitDamageByElement: [
            {'gelo': 50},
          ],
        ),
        isFalse,
      );
      expect(
        controller.resolveOutgoingAction(
          actionId: 'custom',
          hitDamageByElement: [
            {'elemento_personalizzato': 50},
          ],
        ),
        isFalse,
      );
      expect(controller.value.elementId, 'fuoco');
      controller.dispose();
    },
  );

  test(
    'received damage reaction does not change the offensive theme',
    () async {
      final controller = OculumCombatThemeController();
      await controller.setAutomatic(true);
      controller.resolveOutgoingAction(
        actionId: 'attack',
        hitDamageByElement: [
          {'acqua': 12},
        ],
      );
      controller.react('hit', elementId: 'fuoco');

      expect(controller.value.reaction, 'hit');
      expect(controller.value.reactionFamily, OculumGothFamily.ember);
      expect(controller.value.elementId, 'acqua');
      expect(controller.value.activeFamily, OculumGothFamily.tide);
      controller.dispose();
    },
  );
}
