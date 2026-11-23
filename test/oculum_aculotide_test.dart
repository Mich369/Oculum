import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

import 'oculum_escape_provoker_test.dart' show mountFight;
import 'oculum_october27_resources_test.dart' show closeFixture;

void main() {
  test('Aculotide has one eye and Guizzo exposes the three CM bonuses', () {
    final monster = monsterBookEntryById(oculumAculotideId)!;
    final anatomy = oculumMonsterPrecisionAnatomy(monster);
    expect(anatomy.where((part) => part['group'] == 'eyes'), hasLength(1));
    final guizzo = oculumPlanarTechnique(oculumAculotideDodgeSkill)!;
    expect(
      guizzo.forms.map((form) => (form.single.formula, form.single.duration)),
      [('2', '2'), ('3', '2'), ('6', '2')],
    );
  });

  test('Guizzo rises above the current altitude by at most two metres', () {
    expect(oculumAculotideRaisedElevation(4, 1.5), 5.5);
    expect(oculumAculotideRaisedElevation(-3, 2), -1);
    expect(oculumAculotideRaisedElevation(4, 0), isNull);
    expect(oculumAculotideRaisedElevation(4, 2.0001), isNull);
    expect(oculumAculotideRaisedElevation(4, double.nan), isNull);
    expect(oculumAculotideRaisedElevation(double.infinity, 2), isNull);
  });

  test('Guizzo expires without overwriting a different altitude', () {
    double restored(double current) => oculumAculotideRestoredElevation(
      current: current,
      original: -3,
      raised: -1,
    );
    expect(restored(-1), -3);
    expect(restored(0), 0);
  });

  test('Corona prepares three piercing spines and divides its damage once', () {
    final monster = monsterBookEntryById(oculumAculotideId)!;
    expect(monster.skillIds, contains(oculumAculotideCoronaSkill));
    final corona = oculumPlanarTechnique(oculumAculotideCoronaSkill)!;
    expect(corona.element, 'perforante');
    expect(corona.forms, hasLength(3));
    for (final form in corona.forms) {
      expect(form.single.target, oculumAculotideCoronaEffect);
      expect(form.single.maximumTargets, 3);
    }
    expect(List.generate(3, (index) => oculumAculotideSpineDamage(14, index)), [
      5,
      5,
      4,
    ]);
    expect(List.generate(3, (index) => oculumAculotideSpineDamage(1, index)), [
      1,
      0,
      0,
    ]);
  });

  testWidgets('Aculotide bursts once on confirmed death at melee attackers', (
    tester,
  ) async {
    final (state, probe) = await mountFight(tester);
    final base = probe.snapshot();
    final tag = probe.ownerTag();
    final sheet = <String, dynamic>{
      ...base,
      'monsterBookSourceId': oculumAculotideId,
      'currentHp': '100',
      'resilienza': '20',
      'currentResilienza': '20',
      'volonta': '20',
      'currentVolonta': '20',
    };
    state.schedePersonaggio[0] = sheet;
    probe.load(sheet);
    probe.invalidateDerivedCaches();
    probe.saveSheet();

    Future<void> attack(String id, String source, {required bool melee}) async {
      final packet = <String, dynamic>{
        'id': id,
        'sourceTag': source,
        'sourceName': source,
        'targetTag': tag,
        'targetName': 'Aculotide',
        'scope': probe.permissionScope,
        'encounterId': probe.activeCombatEncounterId,
        'attack': 120,
        'damage': 2,
        'natural': 10,
        'choice': 'vc',
        'element': 'fisico',
        'kind': 'attack',
        'status': 'pending',
        'melee': melee,
      };
      state.onlineCombatRequests[id] = packet;
      await tester.runAsync(() => probe.resolveCombatDefense(packet, 'cm', 0));
      expect(packet['status'], 'resolved');
    }

    Iterable<Map> bursts() => (state.onlineCombatRequests.values as Iterable)
        .whereType<Map>()
        .where((request) => request['aculotideDeathBurst'] == true);

    await attack('melee-1', 'ENEMY', melee: true);
    await attack('melee-2', 'ENEMY', melee: true);
    await attack('ranged', 'OTHER', melee: false);
    state.currentHpController.text = '0';
    state.feriteMorte = 0;
    probe.scostuSyncDeath();
    await tester.pump();
    expect(bursts(), isEmpty);
    state.feriteMorte = 3;
    probe.saveSheet();
    probe.scostuSyncDeath();
    probe.scostuSyncDeath();
    await tester.pump();
    final burst = bursts().single;
    expect(burst['targetTag'], 'ENEMY');
    expect(burst['element'], 'acqua');
    expect(burst['damage'], greaterThan(0));
    await closeFixture(tester, probe);
  });
}
