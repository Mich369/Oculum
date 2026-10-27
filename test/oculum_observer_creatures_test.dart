import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'package:oculum/game/oculum_opposed_attack.dart';
import 'oculum_theme_effects_portrait_test.dart' as fixtures;

void main() {
  test('whole currency splits preserve totals and favor the majority', () {
    for (var amount = 0; amount <= 200; amount++) {
      for (var quarter = 0; quarter <= 4; quarter++) {
        for (final tie in [false, true]) {
          final split = oculumMixedCurrencySplit(
            amount,
            quarter,
            tieToObser: tie,
          );
          expect(split.obser + split.oculum, amount);
          expect(split.obser, greaterThanOrEqualTo(0));
          expect(split.oculum, greaterThanOrEqualTo(0));
          if (quarter == 0) expect(split.oculum, amount);
          if (quarter == 4) expect(split.obser, amount);
          if (quarter == 2 && amount.isOdd) {
            expect(split.obser > split.oculum, tie);
          }
        }
      }
    }
    expect(oculumMixedCurrencySplit(3, 1).obser, 0);
    expect(oculumMixedCurrencySplit(3, 3).obser, 3);
    expect(oculumCounterAttackDamage(11, 220), 24);
    final tear = defaultMonsterBookEntries.singleWhere(
      (m) => m.id == 'observers_tear',
    );
    final imported = oculumEquipmentAbilityFromArt(
      oculumMonsterBookArt(tear).skills.first,
    ).forme.first.effettiStrutturati.first;
    expect(
      oculumEvaluateStructuredEffectValue(
        imported,
        variables: {'manifestazione_potere': 18},
        spentResources: {'obser': 2, 'oculum': 1},
      ),
      31,
    );
  });

  test('percentage damage and multiple cost JSON follow confirmed limits', () {
    expect(
      oculumTargetPercentageDamage(
        percent: -30,
        hp: 100,
        temporaryHp: 20,
        shield: 30,
        oculumShield: 10,
      ),
      48,
    );
    expect(
      oculumTargetPercentageDamage(
        percent: -30,
        hp: 100,
        temporaryHp: 20,
        shield: 30,
        oculumShield: 10,
        bypassShields: true,
      ),
      36,
    );
    final cost = OculumSkillCost(
      resource: 'oculum',
      minimum: 1,
      maximum: 4,
      variable: true,
      additionalCosts: [
        OculumSkillCost(
          resource: 'obser',
          minimum: 2,
          maximum: 5,
          variable: true,
        ),
      ],
    );
    final saved = OculumSkillCost.fromJson(cost.toJson());
    expect(saved.isValid(), true);
    expect(saved.additionalCosts.single.maximum, 5);
    final art = oculumStarterArtChoices().first;
    art.skills.first.additionalCostsPerLevel[0].add(
      cost.additionalCosts.single,
    );
    expect(
      CharacterArt.fromJson(
        art.toJson(),
      ).skills.first.additionalCostsPerLevel[0].single.maximum,
      5,
    );
  });

  test('new creatures have distinct complete techniques, costs and drops', () {
    for (final id in [
      'observers_tear',
      'obser_sunshine',
      'saltalungo_maculato',
      'famelico_oblio',
    ]) {
      final monster = defaultMonsterBookEntries.singleWhere((m) => m.id == id);
      expect(monster.skillIds.length, 14);
      expect(monster.dropIds, isNotEmpty);
      // The two authored techniques belong to the Art; natural skills now
      // include a separate progression pool and need not spend the same pool.
      for (final source in oculumMonsterBookArt(monster).skills.take(2)) {
        final skill = oculumEquipmentAbilityFromArt(source);
        final saved = CharacterSkill.fromJson(skill.toJson());
        for (final form in saved.forme) {
          expect(form.effettiStrutturati, isNotEmpty);
          expect(form.costoStrutturato, isNotNull);
          expect(form.cooldownStrutturato!.amount, greaterThan(0));
          if (id == 'observers_tear' || id == 'obser_sunshine') {
            expect(form.costoStrutturato!.resource, 'obser');
            expect(
              form.effettiStrutturati.first.valueExpression,
              contains('manifestazione_potere'),
            );
          }
        }
      }
    }
    expect(
      defaultMonsterBookEntries
          .singleWhere((m) => m.id == 'obser_sunshine')
          .stats['oculum'],
      0,
    );
  });

  testWidgets(
    'mixed payment spends both pools exactly once; memory and tail persist correctly',
    (tester) async {
      final dynamic state = await fixtures.mountSheet(
        tester,
        const Size(1440, 1000),
      );
      final probe = OculumPerformanceProbe(state);
      state.datiCaricati = false;
      if (state.schedePersonaggio.isEmpty) {
        state.schedePersonaggio.add(
          Map<String, dynamic>.from(probe.snapshot())
            ..['id'] = 'ObserverTestOcu:3690ABCD'
            ..['sheetTag'] = 'ObserverTestOcu:3690ABCD',
        );
        state.schedaCorrente = 0;
      }
      state.hiddenEyeStats.clear();
      state.hiddenEyeStats.add(
        HiddenEyeStat(
          id: 'riflessi',
          nome: 'Riflessi',
          descrizione: '',
          valore: 6,
        ),
      );
      state.obserController.text = '100';
      state.oculumController.text = '6';
      state.currentOculumController.text = '6';
      final tear = defaultMonsterBookEntries.singleWhere(
        (m) => m.id == 'observers_tear',
      );
      final form = oculumEquipmentAbilityFromArt(
        oculumMonsterBookArt(tear).skills.first,
      ).forme.first;
      final pending = probe.useConfiguredForTest(form);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('¼ Obser'), findsOneWidget);
      await tester.tap(find.text('Oculum').last);
      await tester.pump();
      await tester.tap(find.text('Conferma').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(await pending, isTrue);
      expect(state.obserController.text, '100');
      expect(probe.snapshot()['currentOculum'].toString(), '3');
      expect(form.cooldownStrutturato!.ready, isFalse);
      expect(await probe.useConfiguredForTest(form), isFalse);
      expect(state.obserController.text, '100');

      final multi = CharacterSkillForm(
        costoStrutturato: OculumSkillCost(
          resource: 'obser',
          amountExpression: '2',
          additionalCosts: [
            OculumSkillCost(
              resource: 'oculum',
              variable: true,
              minimum: 1,
              maximum: 2,
              amountExpression: '1',
            ),
          ],
        ),
        effettiStrutturati: [
          OculumStructuredEffect(
            type: 'difesa',
            valueExpression: '1',
            duration: '1',
          ),
        ],
      );
      final multiPending = probe.useConfiguredForTest(multi);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Conferma').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(await multiPending, true);
      expect(state.obserController.text, '98');
      expect(probe.snapshot()['currentOculum'].toString(), '2');
      state.obserController.text = '100';
      state.currentOculumController.text = '3';
      final solar = defaultMonsterBookEntries.singleWhere(
        (m) => m.id == 'obser_sunshine',
      );
      final solarForm = oculumMonsterBookSkills(solar).first.forme.first;
      final solarPending = probe.useConfiguredForTest(solarForm);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('¼ Obser'), findsNothing);
      await tester.tap(find.text('Conferma').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(await solarPending, true);
      expect(state.obserController.text, '94');
      expect(probe.snapshot()['currentOculum'].toString(), '3');
      final art = oculumMonsterBookArt(tear);
      art.integritaCorrente = 100;
      state.arti.clear();
      state.arti.add(art);
      state.livelloController.text = '6';
      final artPending = probe.useArtSkill(0, 0, 1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('½ Obser'), findsOneWidget);
      await tester.tap(find.text('½ Obser'));
      await tester.pump();
      await tester.tap(find.text('Conferma').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await artPending;
      final obsSpent = 94 - int.parse(state.obserController.text);
      final ocuSpent =
          3 - int.parse(probe.snapshot()['currentOculum'].toString());
      expect(obsSpent + ocuSpent, 3);
      expect(obsSpent, greaterThan(0));
      expect(ocuSpent, greaterThan(0));
      expect(art.integritaCorrente, lessThan(100));
      expect(art.skills.first.cooldownPerLivello.first.ready, false);
      state.obserController.text = '100';

      final runtime =
          state.schedePersonaggio[state.schedaCorrente]['planarRuntime'] as Map;
      runtime['oblivionMemoryStage'] = 4;
      runtime['oblivionMemoryDifficulty'] = 20;
      probe.controlOblivion(19);
      expect(runtime['oblivionMemoryStage'], 5);
      final token = <String, dynamic>{
        'sheetTag': probe.ownerTag(),
        'name': 'Eroe',
      };
      probe.oblivionTurn(token, 49);
      expect(token['oblivionMemoryReactionLost'], true);
      probe.oblivionTurn(token, 50);
      expect(token['oblivionMemoryReactionLost'], false);
      probe.controlOblivion(20);
      expect(runtime['oblivionMemoryStage'], 4);

      state.schedePersonaggio[state.schedaCorrente]['monsterBookSourceId'] =
          'saltalungo_maculato';
      final reflex = (state.hiddenEyeStats as List).firstWhere(
        (dynamic s) => s.id == 'riflessi',
      );
      reflex.valore = 6;
      final before = probe.subtraitValue('riflessi');
      probe.damageSaltalungoTail({
        'natural': 20,
        'targetWeakPointPrecision': true,
      }, 0);
      expect(probe.subtraitValue('riflessi'), before);
      probe.damageSaltalungoTail({
        'natural': 20,
        'targetWeakPointPrecision': true,
      }, 1);
      expect(probe.subtraitValue('riflessi'), before - 6);
      probe.damageSaltalungoTail({
        'natural': 20,
        'targetWeakPointPrecision': true,
      }, 1);
      expect(probe.subtraitValue('riflessi'), before - 6);
      probe.finishPlanarFight();
      expect(probe.subtraitValue('riflessi'), before);

      final chestBefore = probe.partyChestSnapshot()['obser'] as int? ?? 0;
      probe.collectObserverCurrency({
        'id': 'tear-dead',
        'name': tear.nameIt,
        'monsterBookId': tear.id,
        'monsterSheetTag': probe.ownerTag(),
      }, 'fight-tear');
      expect(probe.partyChestSnapshot()['obser'], chestBefore + 100);
      expect(state.obserController.text, '0');
      probe.collectObserverCurrency({
        'id': 'tear-dead',
        'monsterBookId': tear.id,
        'monsterSheetTag': probe.ownerTag(),
      }, 'fight-tear');
      expect(probe.partyChestSnapshot()['obser'], chestBefore + 100);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    },
  );
}
