import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

import 'oculum_escape_provoker_test.dart' show mountFight;
import 'oculum_october27_resources_test.dart' show closeFixture;
import 'oculum_protection_wear_test.dart' show prepareProtectionFixture;

void main() {
  testWidgets(
    'Postea sword caps its own Shield and rejects duplicate receipts',
    (tester) async {
      final (state, probe) = await mountFight(tester);
      prepareProtectionFixture(state, probe);
      state.inventario.add(
        InventoryItem(
          nome: 'Spada al Plasma',
          peso: 1,
          quantita: 1,
          note: '',
          arma: true,
          equipaggiata: true,
          craftData: {'posteaReactiveSword': true, 'posteaSwordShieldCap': 100},
        ),
      );
      final attack = {
        'id': 'sword-1',
        'encounterId': probe.activeCombatEncounterId,
        'sourceTag': probe.ownerTag(),
        'outcome': 'full',
        'posteaSwordAttack': true,
        'damageReceipt': {'hpLost': 5},
      };
      final base = probe.shieldTotal();
      probe.confirmPosteaSwordHit(attack);
      expect(probe.shieldTotal(), base + 100);
      await probe.damageResolved(30, bypassDefense: true);
      expect(probe.shieldTotal(), base + 70);
      probe.confirmPosteaSwordHit(attack);
      expect(probe.shieldTotal(), base + 70);
      probe.confirmPosteaSwordHit({...attack, 'id': 'sword-2'});
      expect(probe.shieldTotal(), base + 100);
      await closeFixture(tester, probe);
    },
  );
}
