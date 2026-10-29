import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/game/oculum_anatomical_parts.dart';

void main() {
  Map<String, dynamic> rule({
    String material = 'flesh',
    String id = 'arms_1',
    String group = 'arms',
    Map overrides = const {},
  }) => oculumAnatomicalPartRule(
    monsterId: 'custom_creature',
    physicalDescription: '',
    part: {'id': id, 'group': group, 'label': id, 'material': material},
    maximumBodyHp: 100,
    overrides: overrides,
  );
  OculumAnatomicalPartHit hit(
    Map state, {
    Map? config,
    String id = 'attack1',
    int damage = 5,
    bool critical = false,
    bool protected = false,
  }) => oculumApplyAnatomicalPartHit(
    state: state,
    rule: config ?? rule(),
    attackId: id,
    hpLost: damage,
    critical: critical,
    criticalShieldProtected: protected,
  );

  test(
    'uses final hpLost once; it never applies body damage or changes rewards',
    () {
      final body = {'currentHp': 83, 'exp': 13};
      final result = hit({});
      expect(result.hpLost, 5);
      expect(result.remainingHp, 25);
      expect(result.becameInjured, false);
      expect(body, {'currentHp': 83, 'exp': 13});
      expect(
        result.state.keys,
        unorderedEquals(['receipts', 'version', 'parts']),
      );
    },
  );
  test(
    'shield-only damage and avoided receipts cannot injure or consume a pool',
    () {
      final result = hit({}, damage: 0, critical: true);
      expect(result.applied, false);
      expect(result.state['parts'], isNull);
      expect(hit(result.state, damage: 30).duplicate, true);
    },
  );
  test(
    'valid targeted critical injures before zero; blocked critical does not',
    () {
      final result = hit({}, critical: true);
      expect(result.becameInjured, true);
      expect(result.remainingHp, 25);
      final blocked = hit({}, critical: true, protected: true);
      expect(blocked.becameInjured, false);
    },
  );
  test(
    'ordinary damage reaching zero injures even if critical was protected',
    () {
      final result = hit({}, damage: 30, protected: true);
      expect(result.validCritical, false);
      expect(result.reachedZero, true);
      expect(result.becameInjured, true);
    },
  );
  test(
    'critical shortcut can be edited without changing the zero threshold',
    () {
      final config = rule(overrides: {'criticalCanInjure': false});
      final result = hit({}, config: config, critical: true);
      expect(result.becameInjured, false);
      expect(
        hit(result.state, id: 'next', config: config, damage: 25).becameInjured,
        true,
      );
    },
  );
  test(
    'single-hit receipts survive serialization, repair and a late replay',
    () {
      final original = hit({}, critical: true).state;
      final restored = jsonDecode(jsonEncode(original)) as Map;
      final repaired = oculumRepairAnatomicalPart(
        state: restored,
        partId: 'arms_1',
        method: 'appropriate_treatment',
        receiptId: 'cure1',
      );
      expect(hit(repaired).duplicate, true);
      final part = (repaired['parts'] as Map)['arms_1'] as Map;
      expect(part['damageTaken'], 0);
      expect(part['injured'], false);
    },
  );
  test(
    'two hits in the same group have distinct IDs and both damage the part',
    () {
      final first = hit({}, id: 'group:h1');
      final second = hit(first.state, id: 'group:h2');
      expect(second.remainingHp, 20);
      expect(hit(second.state, id: 'group:h1').duplicate, true);
    },
  );
  test('immutable nested transport state is not mutated', () {
    final first = hit({});
    final original = Map<String, dynamic>.unmodifiable({
      ...first.state,
      'parts': Map<String, dynamic>.unmodifiable({
        'arms_1': Map<String, dynamic>.unmodifiable(
          (first.state['parts'] as Map)['arms_1'] as Map<String, dynamic>,
        ),
      }),
      'receipts': Map<String, dynamic>.unmodifiable(
        first.state['receipts'] as Map,
      ),
    });
    final before = jsonEncode(original);
    expect(hit(original, id: 'next').remainingHp, 20);
    expect(jsonEncode(original), before);
  });
  test(
    'material-specific injuries do not produce bone fracture conditions',
    () {
      for (final material in [
        'wood',
        'fiber',
        'metal',
        'stone',
        'gel',
        'spectral',
      ]) {
        final config = rule(material: material);
        expect(config['legacyCriticalFracture'], false);
        expect(config['injuryLabel'], isNot('Frattura'));
        final result = hit({}, config: config, critical: true);
        expect(oculumAnatomicalPartRollPenalty(result.state, 'precisione'), 1);
        expect(oculumAnatomicalPartRollPenalty(result.state, 'alchimia'), 0);
      }
      expect(
        oculumAnatomicalPartRollPenalty(
          hit({}, critical: true).state,
          'precisione',
        ),
        0,
        reason: 'Native Frattura already applies its own penalty',
      );
    },
  );
  test('different physical limbs stay separate and penalties cap at three', () {
    Map state = {};
    for (var n = 1; n <= 4; n++) {
      state = hit(
        state,
        id: 'a$n',
        config: rule(
          material: 'wood',
          id: 'walking_root_$n',
          group: 'tentacles',
        ),
        critical: true,
      ).state;
    }
    expect((state['parts'] as Map).length, 4);
    expect(oculumAnatomicalPartRollPenalty(state, 'movimento'), 3);
    expect(oculumAnatomicalPartRollPenalty(state, 'attacco'), 0);
  });
  test(
    'pool maximum freezes on first damage instead of healing on HP buffs',
    () {
      final first = hit({});
      final second = hit(
        first.state,
        id: 'buffed',
        config: rule(overrides: {'maximumHp': 999}),
      );
      expect(second.remainingHp, 20);
      expect(
        ((second.state['parts'] as Map)['arms_1'] as Map)['maximumHp'],
        30,
      );
    },
  );
  test(
    'native core, crystals, mask, guardian chest and reflected core delegate',
    () {
      for (final id in [
        'core',
        'heart',
        'mask',
        'fairy_core',
        'lunar_crystal_forehead',
        'lunar_crystal_rear',
        'art_eyes',
      ]) {
        expect(
          oculumAnatomicalPartIsNative(monsterId: 'custom', part: {'id': id}),
          true,
          reason: id,
        );
      }
      expect(
        oculumAnatomicalPartIsNative(
          monsterId: 'guardiano_lunare',
          part: {'id': 'torso'},
        ),
        true,
      );
      expect(
        oculumAnatomicalPartIsNative(
          monsterId: 'guardian_devil_moon',
          part: {'id': 'core'},
        ),
        true,
      );
      expect(
        oculumAnatomicalPartIsNative(
          monsterId: 'custom',
          part: {'id': 'arms_1', 'nativeMechanic': true},
        ),
        true,
      );
    },
  );
  test('ordinary equipment does not turn a living body into metal', () {
    expect(
      oculumAnatomicalPartMaterial(
        monsterId: 'guardia_solare',
        physicalDescription: 'Umanoide pallido in armatura di metallo e oro.',
        part: {'id': 'arms_1'},
      ),
      'flesh',
    );
    expect(
      oculumAnatomicalPartMaterial(
        monsterId: 'pawn_guardiano',
        physicalDescription: 'Due mani fluttuanti separate, nessun braccio.',
        part: {'id': 'hands_1'},
      ),
      'metal',
    );
    expect(
      oculumAnatomicalPartMaterial(
        monsterId: 'bramble',
        physicalDescription: 'Due braccia e quattro tentacoli di rovi.',
        part: {'id': 'walking_root_1'},
      ),
      'wood',
    );
  });
  test(
    'saved custom rule takes precedence and preserves unrecognized fields',
    () {
      final config = rule(
        overrides: {
          'maximumHp': 42,
          'rollPenalty': 2,
          'myEditorExtension': 'preserve',
          'recovery': 'master_repair',
        },
      );
      expect(config['maximumHp'], 42);
      expect(config['myEditorExtension'], 'preserve');
      expect(hit({}, config: config).remainingHp, 37);
    },
  );
  test(
    'Short Rest, fight end and ordinary HP healing cannot repair a part',
    () {
      final damaged = hit({}, critical: true).state;
      for (final method in [
        'short_rest',
        'fight_end',
        'hp_heal',
        'long_rest',
      ]) {
        final result = oculumRepairAnatomicalPart(
          state: damaged,
          partId: 'arms_1',
          method: method,
          receiptId: method,
        );
        expect(((result['parts'] as Map)['arms_1'] as Map)['injured'], true);
      }
    },
  );
  test('wings recover on Long Rest, never on Short Rest', () {
    final damaged = hit(
      {},
      config: rule(id: 'wings_1', group: 'wings'),
      critical: true,
    ).state;
    final restored = oculumRepairAnatomicalPart(
      state: damaged,
      partId: 'wings_1',
      method: 'long_rest',
      receiptId: 'long1',
    );
    expect(((restored['parts'] as Map)['wings_1'] as Map)['injured'], false);
    expect(
      hit(
        restored,
        config: rule(id: 'wings_1', group: 'wings'),
      ).duplicate,
      true,
    );
  });
  test('no generic core death or inferred weak-point reveal is generated', () {
    final result = hit({}, damage: 100);
    expect(result.revealPartIds, isEmpty);
    expect(result.state.containsKey('dead'), false);
    expect(result.state.containsKey('weakPoint'), false);
  });
  test('same request ID from two sources cannot collide; target is scoped', () {
    String key(String source, String target) => oculumAnatomicalAttackReceiptId(
      sourceTag: source,
      targetTag: target,
      attackId: 'shared-id',
    );
    final first = hit({}, id: key('enemyA', 'defender'));
    final second = hit(first.state, id: key('enemyB', 'defender'));
    expect(second.remainingHp, 20);
    expect(hit(second.state, id: key('ENEMYA', 'DEFENDER')).duplicate, true);
    expect(key('enemyA', 'other'), isNot(key('enemyA', 'defender')));
    expect(
      oculumAnatomicalAttackReceiptId(
        sourceTag: '',
        targetTag: 'target',
        attackId: 'id',
      ),
      isEmpty,
    );
  });
  test(
    'public projection has an explicit allowlist and never leaks hidden cores',
    () {
      final state = hit({}, critical: true).state;
      (state['parts'] as Map)['secret_core'] = {
        'group': 'core',
        'maximumHp': 999,
        'damageTaken': 1,
        'weak': true,
        'secret': 'do not publish',
      };
      expect(oculumPublicAnatomicalPartStatus(state: state), isEmpty);
      final public = oculumPublicAnatomicalPartStatus(
        state: state,
        knownPartIds: ['arms_1', 'secret_core'],
      );
      expect(public, hasLength(1));
      expect(
        public.single.keys,
        unorderedEquals(['id', 'maximumHp', 'remainingHp', 'injured']),
      );
      expect(jsonEncode(public), isNot(contains('weak')));
      expect(jsonEncode(public), isNot(contains('receipts')));
      expect(jsonEncode(public), isNot(contains('core')));
      expect(
        oculumPublicAnatomicalPartStatus(state: state, ownerOrMaster: true),
        hasLength(1),
      );
    },
  );
  test('NaN and Infinity config cannot throw or enter serialized state', () {
    for (final value in [
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      final config = rule(
        overrides: {
          'maximumHp': value,
          'maximumHpFraction': value,
          'minimumHp': value,
        },
      );
      expect((config['maximumHp'] as int), greaterThan(0));
      final state = hit({}, config: config).state;
      expect(() => jsonEncode(state), returnsNormally);
      final structural = hit(
        {},
        config: rule(material: 'wood', overrides: {'rollPenalty': value}),
        critical: true,
      ).state;
      expect(oculumAnatomicalPartRollPenalty(structural, 'precisione'), 0);
      expect(() => jsonEncode(structural), returnsNormally);
    }
  });
}
