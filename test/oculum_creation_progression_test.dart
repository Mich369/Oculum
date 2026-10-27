import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'oculum_escape_provoker_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

void main() {
  test(
    'all catalogue variants retain authored techniques and gain twelve executable choices',
    () {
      final rows = <Map<String, dynamic>>[];
      for (final monster in defaultMonsterBookEntries) {
        final ids = monster.skillIds
            .where((id) => id.startsWith(oculumMonsterProgressionPrefix))
            .toList();
        expect(ids.length, 12, reason: monster.id);
        expect(ids.toSet().length, 12);
        expect(oculumMonsterNaturalAttitude(monster).trim(), isNotEmpty);
        for (final id in ids) {
          final technique = monsterBookConcreteTechnique(id)!;
          expect(technique.forms, hasLength(3));
          expect(technique.forms.every((f) => f.isNotEmpty), isTrue);
          expect(monsterBookSkillText(id), technique.text());
        }
        rows.add({'id': monster.id, 'total': monster.skillIds.length});
      }
      expect(rows.length, greaterThan(1100));
    },
  );
  test(
    'requirements combine level, subtrait, alternative kills, skill criticals and Open',
    () {
      bool met(
        Map<String, dynamic> r, {
        int kills = 0,
        int fire = 0,
        int crits = 0,
        bool open = false,
      }) => oculumSkillRequirementsMet(
        r,
        level: 6,
        subtraits: {'riflessi': 4},
        kills: kills,
        elementalKills: {'fuoco': fire},
        skillCriticals: {'s': crits},
        open: open,
      );
      final r = <String, dynamic>{
        'level': 6,
        'subtrait': 'riflessi',
        'subtraitValue': 4,
        'kills': 8,
        'element': 'fuoco',
        'elementKills': 3,
        'killsEither': true,
      };
      expect(met(r), isFalse);
      expect(met(r, kills: 8), isTrue);
      expect(met(r, fire: 3), isTrue);
      r['level'] = 7;
      expect(met(r, kills: 100), isFalse);
      r['level'] = 6;
      r.addAll({'criticalSkill': 's', 'criticals': 1, 'open': true});
      expect(met(r, fire: 3, crits: 1), isFalse);
      expect(met(r, fire: 3, crits: 1, open: true), isTrue);
      final form = CharacterSkillForm(unlockRequirements: r, costo: '1 Oculum');
      final restored = CharacterSkillForm.fromJson(form.toJson());
      expect(restored.unlockRequirements, r);
      restored.unlockRequirements['level'] = 2;
      expect(form.unlockRequirements['level'], 6);
      final art = ArtSkill(nome: 'Scelta', unlockRequirementsPerLevel: [r]);
      expect(
        ArtSkill.fromJson(art.toJson()).unlockRequirementsPerLevel.first,
        r,
      );
    },
  );
  test('construct core and last strength follow exact confirmed formulas', () {
    expect(oculumConstructCoreMaximum(20), 15);
    expect(oculumConstructCoreMaximum(200), 50);
    expect(oculumConstructCoreSpillChance(0), 40);
    expect(oculumConstructCoreSpillChance(100), 1);
    expect(oculumConstructLastStrength(101, 10, 150), (hp: 200, oculum: 19));
  });
  testWidgets(
    'guided creation offers three own choices and refuses unmet skills without spending',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      p.generateCreation();
      final pool = p.creationPool();
      expect(pool.length, greaterThanOrEqualTo(15));
      expect((p.creationDraft['skills'] as List).length, 3);
      final skill = CharacterSkill(
        nome: 'Bloccata',
        tipo: 'Attacco',
        costo: '',
        cooldown: '',
        descrizione: '',
        forme: [
          CharacterSkillForm(
            costoStrutturato: OculumSkillCost(
              resource: 'oculum',
              amountExpression: '1',
            ),
            unlockRequirements: {'level': 999},
          ),
        ],
      );
      state.skills.add(skill);
      final before = state.currentOculumController.text;
      await p.useCharacterSkill(skill);
      expect(state.currentOculumController.text, before);
      state.tutorialGeneraMostro = true;
      state.tutorialMonsterPresetId = 'scostubanditi';
      state.tutorialMonsterVariantId = 'scostubanditi';
      final monsterPool = p.creationPool();
      expect(monsterPool, isNotEmpty);
      expect(
        monsterPool.every(
          (s) => monsterBookUsableSkillIds(
            monsterBookEntryById('scostubanditi')!,
          ).any((id) => monsterBookSkillText(id).startsWith(s.nome)),
        ),
        isTrue,
      );
      await closeFixture(tester, p);
    },
  );
  testWidgets(
    'construct last strength preserves overflow, cannot repeat, and core attacks respect shields',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      state.trattiRazziali.add(
        OculumTitle.fromJson({
          'nome': 'Costrutto',
          'buff': '@Costrutto',
          'equipaggiato': true,
        }),
      );
      state.resilienzaController.text = '10';
      state.currentHpController.text = '0';
      state.currentOculumController.text = '10';
      expect(p.lastStrength(150), isTrue);
      expect(state.currentOculumController.text, '19');
      expect(state.currentHpController.text, '${150 + p.maximumHp() ~/ 2}');
      expect(p.snapshot()['currentHp'], state.currentHpController.text);
      state.currentHpController.text = '0';
      expect(p.lastStrength(150), isFalse);
      p.restCore();
      p.constructCore['lastAttackCore'] = true;
      expect(p.lastStrength(150), isFalse);
      state.currentHpController.text = '${p.maximumHp()}';
      state.scudoController.text = '1000';
      final core = p.constructCoreHp;
      await p.damageConstructCore(10);
      expect(p.constructCoreHp, core);
      expect(p.constructCore['lastAttackCore'], isTrue);
      await closeFixture(tester, p);
    },
  );
}
