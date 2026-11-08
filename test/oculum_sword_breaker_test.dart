import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

InventoryItem _weapon(
  String name,
  String element, {
  Map<String, dynamic>? data,
}) => InventoryItem(
  nome: name,
  peso: 1,
  quantita: 1,
  note: '',
  arma: true,
  equipaggiata: true,
  elementoDanno: element,
  craftData: data ?? {},
);

void main() {
  const id = '0123456789abcdef0123456789abcdef';

  test(
    'pickup adds the owner bonus, excludes natural one and keeps ties open',
    () {
      const contenders = {
        'owner': (reflexes: 3, movement: 9),
        'rival': (reflexes: 4, movement: 9),
        'critical_failure': (reflexes: 30, movement: 90),
      };
      final rolls = [10, 10, 1].iterator;
      int nextRoll() {
        rolls.moveNext();
        return rolls.current;
      }

      final result = oculumSwordBreakerPickupContest(
        ownerTag: 'owner',
        contenders: contenders,
        rollD20: nextRoll,
      );
      expect(result.winner, 'owner');
      expect(result.rolls.map((roll) => roll.total), [24, 23, null]);
      final tie = [10, 11, 1].iterator;
      final tied = oculumSwordBreakerPickupContest(
        ownerTag: 'owner',
        contenders: contenders,
        rollD20: () {
          tie.moveNext();
          return tie.current;
        },
      );
      expect(tied.winner, isNull);
      expect(tied.tied, isTrue);
      expect(
        oculumSwordBreakerPickupContest(
          ownerTag: 'owner',
          contenders: {'rival': contenders['rival']!},
          rollD20: () => 2,
        ).winner,
        'rival',
      );
    },
  );

  test('pickup releases the marked weapon only once', () {
    final blade = _weapon(
      'Lama',
      'Taglio',
      data: {
        'swordBreakerDrop': {'id': 'fight:attack'},
        'custom': 42,
      },
    );
    final unrelated = _weapon('Lama', 'Taglio');
    final inventory = [blade, unrelated];
    expect(
      oculumTakeSwordBreakerDrop(
        inventory,
        'fight:attack',
        returningToOwner: false,
      ),
      same(blade),
    );
    expect(inventory, [unrelated]);
    expect(blade.craftData['custom'], 42);
    expect(oculumSwordBreakerDropped(blade), isFalse);
    expect(
      oculumTakeSwordBreakerDrop(
        inventory,
        'fight:attack',
        returningToOwner: false,
      ),
      isNull,
    );
  });

  test(
    'Sword Breaker selects a physical blade by its exact saved identity',
    () {
      final sword = _weapon(
        'Spada corta',
        'Fisico',
        data: {'swordBreakerBladeInstance': id},
      );
      final other = _weapon('Spada corta', 'Fisico');
      final request = {
        'swordBreakerBlade': {'instanceId': id, 'name': 'Arma diversa'},
      };
      expect(
        oculumSwordBreakerOriginalBlade([other, sword], request),
        same(sword),
      );
      expect(oculumSwordBreakerOriginalBlade([other], request), isNull);
      final duplicate = InventoryItem.fromJson(sword.toJson());
      expect(
        oculumSwordBreakerOriginalBlade([sword, duplicate], request),
        isNull,
      );
      expect(
        oculumSwordBreakerPhysicalBlade(_weapon('Spada', 'Fuoco')),
        isFalse,
      );
      expect(
        oculumSwordBreakerPhysicalBlade(_weapon('Arco', 'Perforante')),
        isFalse,
      );
    },
  );

  test(
    'Sword Breaker requires the exact avoided CM reply and valid natural',
    () {
      final request = <String, dynamic>{
        'id': 'attack-1',
        'encounterId': 'fight-1',
        'sourceTag': 'attacker',
        'targetTag': 'defender',
        'element': 'taglio',
        'status': 'resolved',
        'outcome': 'avoided',
        'attack': 15,
        'swordBreakerBlade': {'instanceId': id},
      };
      final reply = {
        ...request,
        'defenseChoice': 'cm',
        'defense': 35,
        'defenseNatural': 20,
      };
      expect(oculumSwordBreakerParryNatural(request, reply), 20);
      expect(
        oculumSwordBreakerParryNatural(request, {
          ...reply,
          'defenseNatural': 8,
        }),
        8,
      );
      for (final invalid in [
        {'defenseNatural': 1},
        {'defenseNatural': 21},
        {'defense': 5},
        {'defenseChoice': 'riflessi'},
        {'encounterId': 'another-fight'},
        {'targetTag': 'another-defender'},
      ]) {
        expect(
          oculumSwordBreakerParryNatural(request, {...reply, ...invalid}),
          isNull,
        );
      }
      expect(
        oculumSwordBreakerParryNatural({
          ...request,
          'senkaShadowAvoided': true,
        }, reply),
        isNull,
      );
    },
  );

  test('Title Items cannot be marked as dropped or broken equipment', () {
    final ordinary = _weapon(
      'Lama',
      'Taglio',
      data: {
        'swordBreakerDrop': {'id': 'fight:attack'},
      },
    );
    final title = _weapon(
      'Lama del Titolo',
      'Taglio',
      data: {
        'titleItem': true,
        'swordBreakerDrop': {'id': 'fight:attack'},
      },
    );
    expect(oculumSwordBreakerDropped(ordinary), isTrue);
    expect(oculumSwordBreakerDropped(title), isFalse);
    expect(oculumSpendEquipmentWear(title, oculumEquipmentUses(title)), 0);
    expect(oculumEquipmentUses(title), oculumEquipmentCapacity(title));
  });
}
