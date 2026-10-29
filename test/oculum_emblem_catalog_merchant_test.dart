import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'oculum_theme_effects_portrait_test.dart' as fixtures;

class _PriceTicket implements Random {
  _PriceTicket(this.ticket);
  final int ticket;
  @override
  int nextInt(int max) => max == 100 ? ticket : 0;
  @override
  double nextDouble() => 0;
  @override
  bool nextBool() => false;
}

void main() {
  testWidgets(
    'combat hides unavailable abilities and restores ready affordable forms',
    (tester) async {
      final dynamic state = await fixtures.mountSheet(
        tester,
        const Size(1440, 900),
      );
      final probe = OculumPerformanceProbe(state);
      state.skills.clear();
      state.arti.clear();
      state.titoli.clear();
      state.trattiRazziali.clear();
      final form = CharacterSkillForm(
        descrizione: 'Infligge 5 danni al bersaglio.',
        costoStrutturato: OculumSkillCost(
          resource: 'obser',
          amountExpression: '5',
        ),
        effettiStrutturati: [
          OculumStructuredEffect(
            type: 'danno',
            valueExpression: '5',
            recipient: 'bersaglio',
          ),
        ],
        cooldownStrutturato: OculumAbilityCooldown(amount: 2, unit: 'turni'),
      );
      state.skills.add(
        CharacterSkill(
          nome: 'Colpo vincolato',
          tipo: 'attiva',
          costo: '',
          cooldown: '',
          descrizione: '',
          equipaggiata: true,
          forme: [form],
        ),
      );
      Future<void> check(bool visible) async {
        final opening = probe.openCombatActionPanel(
          OculumCombatAbilityRole.attack,
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        expect(
          find.text('Colpo vincolato'),
          visible ? findsOneWidget : findsNothing,
        );
        await tester.tap(find.text('Chiudi'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        await opening;
      }

      state.obserController.text = '0';
      await check(false);
      state.obserController.text = '5';
      await check(true);
      form.cooldownStrutturato!.remaining = 1;
      await check(false);
      form.cooldownStrutturato!.remaining = 0;
      await check(true);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 3));
    },
  );
  test('slime shares a finite 120 HP pool and has no Pawn regeneration', () {
    final slime = OculumPawnGuardian(
      id: 'pawn_slime',
      ownerTag: 'owner',
      hp: 120,
      targets: ['a', 'b', 'c', 'd'],
      summoningEmblem: {
        ...oculumSummoningEmblemDefaults,
        'encounterId': 'fight',
      },
    );
    expect(oculumSummoningEmblemPrice, greaterThan(oculumPawnPrice));
    expect(slime.targets, ['a', 'b', 'c']);
    expect(slime.maxHp, 120);
    expect(slime.intercept(70), 0);
    expect(slime.advanceTo(5), isTrue);
    expect(slime.hp, 50);
    expect(slime.shield, 0);
    final saved = OculumPawnGuardian.fromJson(slime.toJson());
    expect(oculumSummoningSlimeApplies(saved, 'a', 'fight'), isTrue);
    expect(oculumSummoningSlimeApplies(saved, 'a', 'other'), isFalse);
    expect(oculumSummoningSlimeApplies(saved, 'd', 'fight'), isFalse);
    expect(saved.intercept(70), 20);
    expect(saved.hp, 0);
    expect(oculumSummoningSlimeApplies(saved, 'a', 'fight'), isFalse);
    final legacy = OculumPawnGuardian(id: 'legacy', ownerTag: 'owner');
    final legacyMaximum =
        legacy.stats['resilienza']! *
        oculumHpMultiplierForGrade(legacy.grade, level: legacy.level);
    expect(legacy.maxHp, legacyMaximum);
    expect(
      legacy.hp,
      legacyMaximum,
      reason: 'Legacy Pawn starts at its level-adjusted maximum',
    );
  });

  test(
    'merchant price chances are exact and ordinary prices stay within five percent',
    () {
      final values = [
        for (var ticket = 0; ticket < 100; ticket++)
          oculumMerchantPricePercent(_PriceTicket(ticket)),
      ];
      expect(values.where((v) => v == 125), hasLength(3));
      expect(values.where((v) => v == 85), hasLength(1));
      expect(values.where((v) => v >= 95 && v <= 105), hasLength(96));
      expect(oculumMerchantApplyPricePercent(200, 125), 250);
      expect(oculumMerchantApplyPricePercent(200, 85), 170);
    },
  );

  test(
    'catalog categorizes hybrid shields, food, scrolls and their effective grade',
    () {
      final shield = InventoryItem(
        nome: 'Scudo offensivo',
        peso: 1,
        quantita: 1,
        note: '',
        arma: true,
        protegge: true,
        bonusScudo: 10,
        gradoOggetto: 2,
        gradoRichiesto: 3,
      );
      expect(
        oculumInventoryCatalogCategories(shield),
        containsAll(['shield', 'weapon']),
      );
      expect(oculumInventoryCatalogGrade(shield), 3);
      final scroll = InventoryItem(
        nome: 'Scroll',
        peso: 0,
        quantita: 1,
        note: '',
        craftData: {
          'scroll': {'grade': 4},
        },
      );
      expect(oculumInventoryCatalogGrade(scroll), 4);
      expect(oculumInventoryCatalogCategories(scroll), contains('scroll'));
      final food = InventoryItem(
        nome: 'Pasto',
        peso: 1,
        quantita: 1,
        note: '',
        monsterLoot: {
          'food': {'healHpPercent': 10},
        },
      );
      expect(oculumInventoryCatalogCategories(food), contains('food'));
    },
  );

  test(
    'placement preserves element text and overrides automatic attack placement',
    () {
      final type = oculumAbilityTypeWithPlacement('Fuoco', 'difesa');
      expect(oculumAbilityPlacement(type), 'difesa');
      expect(oculumAbilityTypeWithPlacement(type, ''), 'Fuoco');
      expect(
        oculumCombatAbilityRoles([
          OculumStructuredEffect(
            type: 'danno',
            recipient: 'bersaglio',
            valueExpression: '5',
          ),
        ], explicitType: type),
        {OculumCombatAbilityRole.defense},
      );
      final extra = TitleOpenEntry(
        nome: 'Eclisse',
        combatRole: 'supporto',
        usedSinceLongRest: true,
      );
      final copy = TitleOpenEntry.fromJson(extra.toJson());
      expect(copy.combatRole, 'supporto');
      expect(copy.usedSinceLongRest, isTrue);
      expect(
        TitleOpenEntry.fromJson({'nome': 'Legacy'}).usedSinceLongRest,
        isFalse,
      );
    },
  );

  testWidgets(
    'emblem consumes once, grants temporary bonuses and ends with its fight',
    (tester) async {
      final dynamic state = await fixtures.mountSheet(
        tester,
        const Size(1440, 900),
      );
      final probe = OculumPerformanceProbe(state);
      state.schedePersonaggio.add(probe.snapshot());
      state.schedaCorrente = 0;
      final tag = probe.currentTag();
      state.masterInitiativeTokens.clear();
      state.masterInitiativeTokens.addAll(<Map<String, dynamic>>[
        {
          'id': tag,
          'sheetTag': tag,
          'name': 'Tu',
          'side': 'ally',
          'status': 'ready',
        },
        for (var i = 1; i <= 3; i++)
          {
            'id': 'ally$i',
            'sheetTag': 'ally$i',
            'name': 'Alleato $i',
            'side': 'ally',
            'status': 'ready',
          },
      ]);
      probe.ensureEncounters();
      final encounter = '${state.selectedMasterInitiativeGroupId}';
      final item = probe.merchantItem(oculumSummoningEmblemOffer());
      state.inventario.add(item);
      final original = state.resilienzaController.text;
      final action = probe.useMerchantItem(item);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Alleato 1'));
      await tester.tap(find.text('Alleato 2'));
      await tester.tap(find.text('Alleato 3'));
      await tester.pump();
      await tester.tap(find.text('Evoca'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await action;
      expect(probe.pawns.single.targets, hasLength(3));
      expect(probe.pawns.single.hp, 120);
      expect(state.inventario.contains(item), isFalse);
      expect(probe.emblemBonus(), 3);
      expect(probe.emblemBonus(subtrait: true), 2);
      expect(state.resilienzaController.text, original);
      probe.expireEmblems(encounter);
      expect(probe.pawns, isEmpty);
      expect(probe.emblemBonus(), 0);
      expect(state.resilienzaController.text, original);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 3));
    },
  );
}
