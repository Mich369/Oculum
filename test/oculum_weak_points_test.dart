import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'oculum_theme_effects_portrait_test.dart' as fixtures;

void main() {
  CharacterArt art(String name) =>
      CharacterArt(nome: name, tipo: name, descrizione: '', skills: []);
  test(
    'all catalogue entries have a weak point and distinct coherent target IDs',
    () {
      for (final monster in defaultMonsterBookEntries) {
        expect(
          monster.weakPointDescriptionIt.trim(),
          isNotEmpty,
          reason: monster.id,
        );
        final parts = oculumMonsterPrecisionAnatomy(monster);
        expect(parts, isNotEmpty, reason: monster.id);
        expect(
          parts.map((p) => p['id']).toSet().length,
          parts.length,
          reason: monster.id,
        );
        expect(
          parts.every((p) => '${p['label']}'.isNotEmpty),
          true,
          reason: monster.id,
        );
      }
    },
  );
  test(
    'multiple arms, wings and legs are separate; spells do not invent anatomy',
    () {
      List<Map<String, dynamic>> parts(String id) =>
          oculumMonsterPrecisionAnatomy(monsterBookEntryById(id)!);
      int count(String id, String group) =>
          parts(id).where((p) => p['group'] == group).length;
      expect(count('teschio_quattro_lame', 'arms'), 4);
      expect(count('teschio_mostruoso', 'arms'), 4);
      expect(count('snorlo', 'arms'), 4);
      expect(count('teirak', 'arms'), 8);
      expect(count('thunderbird', 'wings'), 6);
      expect(count('nuvi', 'wings'), 4);
      expect(count('feralis', 'legs'), 2);
      expect(count('feralis', 'tail'), 1);
      expect(
        parts('thunder_bot').any(
          (p) => const {'head', 'arms', 'legs', 'wings'}.contains(p['group']),
        ),
        false,
      );
      expect(parts('observers_tear').any((p) => p['group'] == 'arms'), false);
      expect(parts('meccanio').any((p) => p['group'] == 'legs'), false);
      expect(
        parts('bramble').any((p) => p['group'] == 'heart' && p['weak'] == true),
        true,
      );
    },
  );
  test(
    'explicit weak point and anatomy customizations survive catalogue copy',
    () {
      final base = monsterBookEntryById('thunderbird')!;
      final changed = base.copyWith(
        weakPointIt: 'La coda.',
        encounterRules: {
          ...base.encounterRules,
          'precisionBodyParts': [
            {'id': 'custom', 'label': 'Coda doppia', 'weak': true},
          ],
        },
      );
      expect(changed.weakPointDescriptionIt, 'La coda.');
      expect(oculumMonsterPrecisionAnatomy(changed).single['id'], 'custom');
      expect(base.weakPointDescriptionIt, contains('testa'));
    },
  );
  test(
    'Art anatomy supports Emblem location, Martial accuracy and no Defiled weak core',
    () {
      final emblem = art('Emblem Art')..weakPointLocation = 'Mano sinistra';
      final restored = CharacterArt.fromJson(emblem.toJson());
      expect(restored.weakPointLocation, 'Mano sinistra');
      final parts = oculumPrecisionBodyParts(
        arts: [art('Martial Art'), restored, art('Defiled Art')],
      );
      expect(parts.singleWhere((p) => p['id'] == 'ligaments')['penalty'], 2);
      expect(
        parts.singleWhere((p) => p['id'] == 'emblem')['label'],
        'Mano sinistra',
      );
      expect(parts.any((p) => p['artKind'] == 'defiled'), false);
      final monsterParts = oculumPrecisionBodyParts(
        monster: monsterBookEntryById('teschio_mostruoso'),
        arts: [art('Oculum Art')],
      );
      expect(monsterParts.any((p) => p['artKind'] != null), false);
    },
  );
  testWidgets('Art weak hit only penalizes that Art for an Action', (
    tester,
  ) async {
    final dynamic state = await fixtures.mountSheet(
      tester,
      const Size(1440, 900),
    );
    final probe = OculumPerformanceProbe(state);
    state.datiCaricati = false;
    if (state.schedePersonaggio.isEmpty) {
      final sheet = probe.snapshot()..['sheetTag'] = 'WeakTesterOcu:3690AAAA';
      state.schedePersonaggio.add(sheet);
      state.schedaCorrente = 0;
      probe.load(sheet);
    }
    state.arti.clear();
    state.arti.addAll([art('Oculum Art'), art('Martial Art')]);
    probe.hitBodyPart({'targetBodyPart': 'eyes'});
    expect(probe.weakArtPenalty('Oculum Art / raggio'), 3);
    expect(probe.weakArtPenalty('Martial Art / colpo'), 0);
    expect(probe.weakArtPenalty('Attacco base'), 0);
    probe.weakArtAction();
    expect(probe.weakArtPenalty('Oculum Art / raggio'), 0);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
  test(
    'Fate Golem fairy core reflects without a contested roll, Mini keeps its own rule',
    () {
      expect(
        oculumFateCoreReflects(
          monsterBookEntryById('fate_golem'),
          'fairy_core',
        ),
        true,
      );
      expect(
        oculumFateCoreReflects(monsterBookEntryById('fate_golem'), 'arms_1'),
        false,
      );
      expect(
        oculumFateCoreReflects(
          monsterBookEntryById('mini_fate_golem'),
          'fairy_core',
        ),
        false,
      );
      final core = oculumMonsterPrecisionAnatomy(
        monsterBookEntryById('fate_golem')!,
      ).singleWhere((p) => p['id'] == 'fairy_core');
      expect(core['label'], 'Nucleo con fata');
      expect(core['reflectAttack'], true);
    },
  );
  testWidgets(
    'Precision chooses the arm group then the correct side and number',
    (tester) async {
      final dynamic state = await fixtures.mountSheet(
        tester,
        const Size(1440, 900),
      );
      final probe = OculumPerformanceProbe(state);
      final result = probe.selectPrecisionPart({
        'id': 'skeleton',
        'monsterBookId': 'teschio_quattro_lame',
        'name': 'Teschio',
      });
      await tester.pumpAndSettle();
      await tester.tap(find.text('Braccia · 4'));
      await tester.pumpAndSettle();
      expect(find.text('Destra 1'), findsOneWidget);
      expect(find.text('Sinistra 2'), findsOneWidget);
      await tester.tap(find.text('Destra 2'));
      await tester.pumpAndSettle();
      expect((await result)!['id'], 'arms_3');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
  testWidgets(
    'different critical wing injuries halve then remove flight until long rest',
    (tester) async {
      final dynamic state = await fixtures.mountSheet(
        tester,
        const Size(1440, 900),
      );
      final probe = OculumPerformanceProbe(state);
      state.datiCaricati = false;
      if (state.schedePersonaggio.isEmpty) {
        final sheet = probe.snapshot()..['sheetTag'] = 'WingTesterOcu:3690AAAA';
        state.schedePersonaggio.add(sheet);
        state.schedaCorrente = 0;
        probe.load(sheet);
      }
      state.schedePersonaggio[state.schedaCorrente]['monsterBookSourceId'] =
          'nuvi';
      state.currentHpController.text = '100';
      expect(probe.flightBonus(3), 3);
      await probe.wingHit({'targetBodyPart': 'wings_1'}, critical: false);
      expect(probe.flightBonus(3), 3);
      await probe.wingHit({'targetBodyPart': 'wings_1'});
      expect(probe.flightBonus(3), 1);
      await probe.wingHit({'targetBodyPart': 'wings_1'});
      expect(probe.grounded, false);
      await probe.wingHit({'targetBodyPart': 'wings_2'});
      expect(probe.grounded, true);
      expect(probe.flightBonus(3), 0);
      expect(oculumWingFallDamage(60, 8), 52);
      expect(oculumWingFallDamage(5, 10), 0);
      probe.faunaLongRest();
      expect(probe.grounded, false);
      expect(probe.flightBonus(3), 3);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
  testWidgets(
    'fractures require different limbs, stop at three and survive saves',
    (tester) async {
      final dynamic state = await fixtures.mountSheet(
        tester,
        const Size(1440, 900),
      );
      final probe = OculumPerformanceProbe(state);
      state.datiCaricati = false;
      if (state.schedePersonaggio.isEmpty) {
        final sheet = probe.snapshot()
          ..['sheetTag'] = 'FractureTesterOcu:3690AAAA';
        state.schedePersonaggio.add(sheet);
        state.schedaCorrente = 0;
        probe.load(sheet);
      }
      state.schedePersonaggio[state.schedaCorrente]['monsterBookSourceId'] =
          'teschio_quattro_lame';
      state.scudoCriticoController.text = '1';
      probe.fractureHit({'id': 'protected', 'targetBodyPart': 'arms_1'});
      expect(probe.fracturePenalty('forza'), 0);
      final criticalDebuff = OculumStructuredEffect(
        type: 'stato',
        appliedState: 'stordito',
        criticalOnly: true,
      );
      expect(
        probe.criticalEffectAllowed({'natural': 20}, criticalDebuff),
        false,
      );
      state.scudoCriticoController.text = '0';
      // The critical that breaks the last shield is protected too.
      final protectedPacket = <String, dynamic>{
        'id': 'last-shield',
        'targetBodyPart': 'arms_1',
        'natural': 20,
        'criticalShieldProtected': true,
      };
      probe.fractureHit(protectedPacket);
      expect(probe.fracturePenalty('forza'), 0);
      expect(
        probe.criticalEffectAllowed(protectedPacket, criticalDebuff),
        false,
      );
      expect(
        probe.criticalEffectAllowed({'natural': 20}, criticalDebuff),
        true,
      );
      expect(
        probe.criticalEffectAllowed({'natural': 10}, criticalDebuff),
        false,
      );
      final ordinaryAcid = OculumStructuredEffect(
        type: 'stato',
        appliedState: 'corrosione_acida',
      );
      expect(probe.criticalEffectAllowed(protectedPacket, ordinaryAcid), true);
      expect(
        OculumStructuredEffect.fromJson(criticalDebuff.toJson()).criticalOnly,
        true,
      );
      for (final pair in [
        ('a', 'arms_1'),
        ('b', 'arms_1'),
        ('c', 'arms_2'),
        ('d', 'arms_3'),
        ('e', 'arms_4'),
      ]) {
        probe.fractureHit({
          'id': pair.$1,
          'targetBodyPart': pair.$2,
        }, percentile: 0);
      }
      expect(probe.fracturePenalty('forza'), 4);
      probe.fractureHit({
        'id': 'f',
        'targetBodyPart': 'arms_1',
      }, percentile: 99);
      expect(probe.fracturePenalty('forza'), 5);
      expect(probe.fractureDamagePenalty(), -4);
      expect(probe.fractureDefensePenalty(), -5);
      expect(probe.fracturePenalty('percezione'), 0);
      expect(probe.fracturePenalty('riflessi'), 0);
      final saved = probe.snapshot();
      probe.load(saved);
      expect(probe.fracturePenalty('forza'), 5);
      expect(probe.fractureDamagePenalty(), -4);
      expect(probe.fractureDefensePenalty(), -5);
      probe.fractureHit({'id': 'g'}, percentile: 0);
      expect(probe.fractureDamagePenalty(), -6);
      expect(probe.fractureDefensePenalty(), -5);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
  testWidgets(
    'Master weak point reveal targets the exact entry, never its variants',
    (tester) async {
      final dynamic state = await fixtures.mountSheet(
        tester,
        const Size(1440, 900),
      );
      final probe = OculumPerformanceProbe(state);
      state.datiCaricati = false;
      state.modalitaMaster = true;
      await probe.revealWeakPoint('feralis');
      expect(probe.monsterWeakPointKnown('feralis'), true);
      expect(probe.monsterWeakPointKnown('feralis_ancestrale'), false);
      state.modalitaMaster = false;
      await probe.revealWeakPoint('bramble');
      expect(probe.monsterWeakPointKnown('bramble'), false);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
}
