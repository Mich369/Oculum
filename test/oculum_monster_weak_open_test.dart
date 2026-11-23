import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

import 'oculum_escape_provoker_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

CharacterArt _primary() => CharacterArt(
  nome: 'Art naturale',
  tipo: 'Art mostro',
  descrizione: '',
  skills: [],
  openName: 'Prova',
  openDescription: 'Richiede livello 8.',
  openDescriptionEffects: [
    OculumStructuredEffect(
      id: 'monster_open_ultimate_test',
      type: 'modifica_statistica',
      target: 'monster_open_marker',
    ),
  ],
  openBuffEffects: [
    OculumStructuredEffect(
      type: 'difesa',
      valueExpression: '80',
      mode: 'finche_attivo',
    ),
    OculumStructuredEffect(
      type: 'stato',
      appliedState: 'stordito',
      valueExpression: '1',
      duration: '2',
      recipient: 'nemico',
      criticalOnly: true,
    ),
  ],
  openSkill: 'Costo: 2/3 Oculum.',
  openSkillEffects: [
    OculumStructuredEffect(
      type: 'danno',
      valueExpression: '72',
      diceExpression: '1d2+7',
    ),
  ],
  openSkillCooldown: OculumAbilityCooldown(unit: 'turni', amount: 4),
);

void main() {
  test(
    'Open debole scales the resolved magnitude and preserves requirements',
    () {
      final primary = _primary();
      final weak = oculumMonsterWeakOpen(primary)!;
      final restored = CharacterArt.fromJson(
        Map<String, dynamic>.from(jsonDecode(jsonEncode(weak.toJson())) as Map),
      );
      expect(oculumIsMonsterWeakOpen(restored), isTrue);
      expect(restored.skills, isEmpty);
      expect(restored.hasIntegrity, isFalse);
      expect(restored.openDescription, startsWith('Richiede livello 3.'));
      expect(restored.openSkillCooldown!.amount, 4);
      expect(oculumParseAbilityCost(restored.openSkill), (
        minimum: 2,
        maximum: 3,
        resource: 'oculum',
      ));
      for (final (grade, expected) in [(0, 20), (3, 26)]) {
        final buff = oculumResolveStructuredEffectRoll(
          restored.openBuffEffects.first,
          variables: const {},
          grade: grade,
        );
        final skill = oculumResolveStructuredEffectRoll(
          restored.openSkillEffects.single,
          variables: const {},
          grade: grade,
          random: Random(0),
        );
        expect((buff.value, skill.value), (expected, expected));
      }
      final condition = restored.openBuffEffects.last;
      expect(condition.appliedState, 'stordito');
      expect(condition.criticalOnly, isTrue);
      expect(condition.recipient, 'nemico');
      expect(condition.duration, '2');
      expect(condition.scaleMonsterWeakOpen, isFalse);
      expect(primary.openBuffEffects.first.scaleMonsterWeakOpen, isFalse);
      expect(primary.openDescription, 'Richiede livello 8.');
    },
  );

  test('ordinary spawn gets a second Open without changing its skill pool', () {
    final mimic = monsterById('mimic_base')!;
    final loadout = oculumMonsterBookLoadout(
      mimic,
      random: Random(1),
      level: 2,
    );
    expect(
      loadout.weakOpen!.openName,
      'Open debole · ${loadout.art!.openName}',
    );
    expect(loadout.weakOpen!.skills, isEmpty);
    for (final id in ['nuvi', 'thunder_bot', 'cynervail', 'slime_roccioso']) {
      final monster = monsterById(id)!;
      final chosen = oculumMonsterBookLoadout(monster, random: Random(1));
      expect(chosen.weakOpen, isNull, reason: id);
    }
  });

  testWidgets(
    'normal Open controls enforce level 3 and preserve the real Art',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      final primary = _primary()..openBuffEffects.removeLast();
      final weak = oculumMonsterWeakOpen(primary)!;
      state.arti
        ..clear()
        ..addAll([primary, weak]);
      state.livelloController.text = '2';
      state.gradoController.text = '0';
      await p.useOpen(1);
      expect(weak.openAttiva, isFalse);
      state.livelloController.text = '3';
      await p.useOpen(1);
      expect(weak.openAttiva, isTrue);
      expect(primary.openAttiva, isFalse);
      expect(primary.integritaCorrente, -1);
      expect(
        (state.activeStructuredEffects as List).whereType<Map>().any(
          (effect) => effect['target'] == 'difesa' && effect['value'] == 20,
        ),
        isTrue,
      );
      await closeFixture(tester, p);
    },
  );
}
