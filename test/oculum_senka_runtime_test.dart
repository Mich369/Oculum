import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'oculum_escape_provoker_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

void main() {
  testWidgets(
    'moon boosts the transformed core once across fights until its own Open recovers',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      final sheet =
          Map<String, dynamic>.from(
              jsonDecode(
                    File(
                      'output/characters/senka_kamaria/Senka_Kamaria.json',
                    ).readAsStringSync(),
                  )
                  as Map,
            )
            ..['id'] = p.ownerTag()
            ..['sheetTag'] = p.ownerTag();
      p.load(sheet);
      final title = (state.titoli as List).cast<OculumTitle>().singleWhere(
        (t) => t.openEffects.any((e) => e.target == 'senka_moon_open'),
      );
      title.evoluto = true;
      final mask = (state.inventario as List).cast<InventoryItem>().singleWhere(
        (i) => i.craftData['senkaMask'] == true,
      );
      p.manifestSenkaMask(mask, true);
      p.invalidateDerivedCaches();
      final before = p.coreStats();
      p.useTitleOpen(title);
      expect(p.titleOpenBoost(title), true);
      p.invalidateDerivedCaches();
      final boosted = p.coreStats();
      for (final key in before.keys) {
        expect(
          boosted[key],
          before[key]! + (before[key]! * .30).floor(),
          reason: key,
        );
      }
      p.load(p.snapshot());
      p.invalidateDerivedCaches();
      expect(p.coreStats(), boosted);
      p.senkaEndFight();
      p.completeOpenFight('senka-moon-one');
      p.invalidateDerivedCaches();
      expect(p.coreStats(), boosted);
      final restored = (state.titoli as List).cast<OculumTitle>().singleWhere(
        (t) => t.openEffects.any((e) => e.target == 'senka_moon_open'),
      );
      expect(restored.openAttiva, true);
      expect(restored.openUsedSinceLongRest, true);
      p.tickOpenRest(longRest: true);
      p.invalidateDerivedCaches();
      expect(restored.openAttiva, true);
      expect(p.coreStats(), boosted);
      p.tickOpenRest(longRest: true);
      p.invalidateDerivedCaches();
      expect(restored.openAttiva, false);
      expect(restored.openUsedSinceLongRest, false);
      expect(p.coreStats(), before);
      expect(
        p.titleOpenBoost(restored),
        true,
        reason: 'recovery and Skill boost have independent clocks',
      );
      await closeFixture(tester, p);
    },
  );
  testWidgets(
    'lunar cuts require evolution and retain their own three-fight boost while another Open is active',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      final sheet =
          Map<String, dynamic>.from(
              jsonDecode(
                    File(
                      'output/characters/senka_kamaria/Senka_Kamaria.json',
                    ).readAsStringSync(),
                  )
                  as Map,
            )
            ..['id'] = p.ownerTag()
            ..['sheetTag'] = p.ownerTag();
      p.load(sheet);
      final title = (state.titoli as List).cast<OculumTitle>().singleWhere(
        (t) => t.openEffects.any((e) => e.target == 'senka_moon_open'),
      );
      final effects = title.skillExtra.single.effects;
      expect(p.prepareSenka(effects), isNull);
      title.evoluto = true;
      final weak = p.prepareSenka(effects)!.single;
      final weakData = jsonDecode(weak.narrativeText) as Map;
      expect(readIntValue(weakData['cuts']), inInclusiveRange(1, 6));
      expect(readIntValue(weakData['damagePerCut']), p.damageTotal() ~/ 6);
      expect(weak.maximumTargets, weakData['cuts']);
      p.useTitleOpen(title);
      expect(p.titleOpenBoost(title), true);
      final strong = p.prepareSenka(effects)!.single;
      final strongData = jsonDecode(strong.narrativeText) as Map;
      expect(readIntValue(strongData['cuts']), inInclusiveRange(1, 8));
      expect(strongData['ownOpen'], true);
      expect(
        effects.single.diceExpression,
        '1d6',
        reason: 'the editable definition is never overwritten',
      );
      final other = OculumTitle(
        nome: 'Altra Open',
        tipo: 'Standard',
        ottenimento: '',
        buff: '',
        puntoCieco: '',
        skill: '',
        richiede: '',
        evoluto: true,
        equipaggiato: true,
        openName: 'Altro potere',
      );
      state.titoli.add(other);
      p.useTitleOpen(other);
      expect(title.openAttiva, false);
      expect(other.openAttiva, true);
      expect(
        (jsonDecode(p.prepareSenka(effects)!.single.narrativeText)
            as Map)['ownOpen'],
        true,
      );
      p.completeOpenFight('senka-cuts-one');
      p.completeOpenFight('senka-cuts-one');
      p.completeOpenFight('senka-cuts-two');
      expect(p.titleOpenBoost(title), true);
      p.completeOpenFight('senka-cuts-three');
      final expired = p.prepareSenka(effects)!.single;
      final expiredData = jsonDecode(expired.narrativeText) as Map;
      expect(expiredData['ownOpen'], false);
      expect(readIntValue(expiredData['cuts']), inInclusiveRange(1, 6));
      expect(
        strongData['ownOpen'],
        true,
        reason: 'a prepared volley retains its original snapshot',
      );
      expect(other.openAttiva, true);
      expect(effects.single.diceExpression, '1d6');
      await closeFixture(tester, p);
    },
  );
  testWidgets(
    'mask protects only the aimed mask and resumes after a valid critical; Mille Tagli is one packet',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      final sheet =
          Map<String, dynamic>.from(
              jsonDecode(
                    File(
                      'output/characters/senka_kamaria/Senka_Kamaria.json',
                    ).readAsStringSync(),
                  )
                  as Map,
            )
            ..['id'] = p.ownerTag()
            ..['sheetTag'] = p.ownerTag();
      p.load(sheet);
      final mask = (state.inventario as List).cast<InventoryItem>().singleWhere(
        (i) => i.craftData['senkaMask'] == true,
      );
      p.manifestSenkaMask(mask, true);
      expect(
        p.senkaShadowEvades({'targetBodyPart': 'mask', 'element': 'tagliente'}),
        true,
      );
      expect(
        p.senkaShadowEvades({
          'targetBodyPart': 'torso',
          'element': 'tagliente',
        }),
        false,
      );
      expect(
        p.senkaShadowEvades({
          'targetBodyPart': 'mask',
          'element': 'spirituale',
        }),
        false,
      );
      expect(
        p.senkaShadowEvades({
          'targetBodyPart': 'mask',
          'canHitIntangible': true,
        }),
        false,
      );
      p.senkaMaskHit({
        'id': 'body',
        'targetBodyPart': 'torso',
        'canHitIntangible': true,
      });
      expect(mask.equipaggiata, true);
      final hit = <String, dynamic>{
        'id': 'mask-critical',
        'targetBodyPart': 'mask',
        'canHitIntangible': true,
      };
      p.senkaMaskHit(hit);
      expect(mask.equipaggiata, false);
      expect(p.manifestSenkaMask(mask, true), false);
      p.senkaStartTurn();
      expect(mask.equipaggiata, true);
      p.senkaMaskHit(hit);
      expect(
        mask.equipaggiata,
        true,
        reason: 'a replay cannot break the restored mask again',
      );
      final expected =
          p.damageTotal() + 23 + p.totalPower(state.schedaCorrente as int);
      final attack = <String, dynamic>{
        'id': 'cuts',
        'sourceTag': p.ownerTag(),
        'attack': 23,
        'effects': [
          {'target': 'senka_thousand_cuts'},
        ],
      };
      p.claimSenkaAttack(attack);
      expect(attack['damage'], expected);
      expect(attack['baseAttack'], false);
      expect(p.exhausted(), true);
      p.claimSenkaAttack(attack);
      expect(attack['damage'], expected);
      await closeFixture(tester, p);
    },
  );
  testWidgets(
    'readable Senka costs pay Oculum and variable Matter through the confirmation dialog',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      final sheet =
          Map<String, dynamic>.from(
              jsonDecode(
                    File(
                      'output/characters/senka_kamaria/Senka_Kamaria.json',
                    ).readAsStringSync(),
                  )
                  as Map,
            )
            ..['id'] = p.ownerTag()
            ..['sheetTag'] = p.ownerTag();
      p.load(sheet);
      final mask = (state.inventario as List).cast<InventoryItem>().singleWhere(
        (i) => i.craftData['senkaMask'] == true,
      );
      p.manifestSenkaMask(mask, true);
      final art = (state.arti as List).cast<CharacterArt>().firstWhere(
        (a) => a.nome == "L'Ombra Mascherata",
      );
      final mantle = oculumEquipmentAbilityFromArt(
        art.skills.first,
      ).forme.first;
      expect(oculumParseAbilityCost(mantle.costo)!.resource, 'oculum');
      final oculum = p.availableArtResource('oculum');
      final matter = p.availableArtResource('materia');
      final useMantle = p.useConfiguredForTest(mantle);
      var mantleComplete = false;
      useMantle.then((_) => mantleComplete = true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Conferma').last,
            )
            .onPressed,
        isNotNull,
      );
      await tester.tap(find.text('Conferma').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        mantleComplete,
        true,
        reason: tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data)
            .join(' | '),
      );
      expect(await useMantle, true);
      expect(p.availableArtResource('oculum'), oculum - 3);
      expect(p.availableArtResource('materia'), matter);
      final clone = (state.skills as List)
          .cast<CharacterSkill>()
          .singleWhere((s) => s.nome == 'Clone d’ombra di Senka')
          .forme
          .first;
      final useClone = p.useConfiguredForTest(clone);
      var cloneComplete = false;
      useClone.then((_) => cloneComplete = true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(matter, greaterThanOrEqualTo(2));
      await tester.enterText(
        find.widgetWithText(TextField, 'Quantità da spendere'),
        '2',
      );
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Conferma').last,
            )
            .onPressed,
        isNotNull,
      );
      await tester.tap(find.text('Conferma').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        cloneComplete,
        true,
        reason: tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data)
            .join(' | '),
      );
      expect(await useClone, true);
      expect(p.availableArtResource('materia'), matter - 2);
      expect(p.availableArtResource('oculum'), oculum - 3);
      final summoned = (state.schedePersonaggio as List)
          .cast<Map>()
          .singleWhere((s) => s['summonKind'] == 'senka_shadow');
      expect(readIntValue(summoned['currentHp']), 5);
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'mask refills only transformation reserves; shield repair, damage claims and save are exact',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      final input = Map<String, dynamic>.from(
        jsonDecode(
              File(
                'output/characters/senka_kamaria/Senka_Kamaria.json',
              ).readAsStringSync(),
            )
            as Map,
      );
      input['id'] = input['sheetTag'] = p.ownerTag();
      p.load(input);
      await tester.pump();
      p.invalidateDerivedCaches();
      final item = (state.inventario as List).cast<InventoryItem>().singleWhere(
        (i) => i.craftData['senkaMask'] == true,
      );
      final hp = p.currentHp(), oculum = p.coreStats()['oculum']!;
      final before = p.coreStats();
      expect(before['materia'], 8);
      expect(before['oculum'], 9);
      expect(p.currentHp(), p.maximumHp());
      File('build/oct27-senka-measured.json').writeAsStringSync(
        jsonEncode({
          'coreStats': before,
          'hp': p.currentHp(),
          'maximumHp': p.maximumHp(),
          'audit': {
            for (final key in ['resilienza', 'volonta', 'materia', 'oculum'])
              key: p.coreBonusAudit(key),
          },
        }),
      );
      final turn = p.combatTurnResources();
      expect(p.manifestSenkaMask(item, true), true);
      expect(p.coreStats()['resilienza'], before['resilienza']! + 6);
      expect(p.coreStats()['materia'], before['materia']! + 10);
      expect(p.currentHp(), hp + 54);
      expect(p.coreStats()['oculum'], oculum + 5);
      expect(p.combatTurnResources(), turn);
      final shield = state.scudoController.text;
      p.spendArtResource('oculum', 5);
      state.currentHpController.text = '${p.currentHp() - 30}';
      expect(p.manifestSenkaMask(item, false), true);
      expect(p.coreStats()['oculum'], oculum);
      expect(p.currentHp(), hp);
      p.manifestSenkaMask(item, true);
      expect(p.currentHp(), hp + 54);
      expect(p.coreStats()['oculum'], oculum + 5);
      expect(state.scudoController.text, shield);
      item.scudoIntegritaOculumCorrente = 0;
      state.scudoOculumController.text = '0';
      expect(p.repairSenkaMask(10), 8);
      expect(item.scudoIntegritaOculumCorrente, 8);
      expect(p.repairSenkaMask(30), 30);
      expect(item.scudoIntegritaOculumCorrente, 38);
      expect(p.repairSenkaMask(10), 0);
      item.scudoIntegritaOculumCorrente = 10;
      state.scudoOculumController.text = '10';
      final hit = {
        'id': 'one-hit',
        'sourceTag': p.ownerTag(),
        'targetLevel': 4,
        'damageReceipt': {'hpLost': 1},
      };
      p.senkaDamageReceipt(hit);
      p.senkaDamageReceipt(hit);
      expect(item.scudoIntegritaOculumCorrente, 14);
      final saved = p.snapshot();
      p.load(saved);
      final restored = (state.inventario as List)
          .cast<InventoryItem>()
          .singleWhere((i) => i.craftData['senkaMask'] == true);
      p.senkaDamageReceipt(hit);
      expect(restored.scudoIntegritaOculumCorrente, 14);
      await closeFixture(tester, p);
    },
  );
  testWidgets(
    'title items manifest freely without restoring consumed integrity',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      state.inventario.clear();
      state.scudoController.text = '0';
      state.scudoOculumController.text = '0';
      final item = InventoryItem(
        nome: 'Scudo titolo',
        peso: 1,
        quantita: 1,
        note: '',
        protegge: true,
        bonusScudo: 30,
        bonusScudoOculum: 20,
        scudoIntegritaCorrente: 8,
        scudoIntegritaOculumCorrente: 4,
        craftData: {'titleItem': true},
      );
      state.inventario.add(item);
      final turn = p.combatTurnResources();
      expect(p.manifestTitleItem(item, true), true);
      expect(state.scudoController.text, '8');
      expect(state.scudoOculumController.text, '4');
      p.manifestTitleItem(item, false);
      p.manifestTitleItem(item, true);
      expect(state.scudoController.text, '8');
      expect(item.scudoIntegritaCorrente, 8);
      expect(p.combatTurnResources(), turn);
      await closeFixture(tester, p);
    },
  );
  testWidgets(
    'Senka clones preserve effective stats, exact HP and the total limit after absorption',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      state.livelloController.text = '1';
      state.skills.clear();
      state.arti.clear();
      state.inventario.clear();
      state.trattiRazziali.clear();
      state.titoli.clear();
      p.invalidateDerivedCaches();
      final stats = p.coreStats();
      final first = p.senkaClone(9), second = p.senkaClone(5);
      expect(first, greaterThanOrEqualTo(0));
      expect(second, greaterThan(first));
      expect(p.senkaCloneCount(), 2);
      expect(p.senkaClone(100), -1);
      final clone = Map<String, dynamic>.from(
        state.schedePersonaggio[first] as Map,
      );
      expect(readIntValue(clone['currentHp']), 9);
      expect(readIntValue(clone['resilienza']), stats['resilienza']);
      final owner = p.snapshot();
      p.load(clone);
      expect(p.maximumHp(), 9);
      expect(p.senkaClone(10), -1);
      p.load(owner);
      final temporary = readIntValue(state.hpTempController.text);
      expect(p.senkaFusion(), 2);
      expect(readIntValue(state.hpTempController.text), temporary + 14);
      expect(p.senkaCloneCount(), 2);
      expect(p.senkaClone(100), -1);
      expect(state.schedePersonaggio[first]['summonExpired'], true);
      await closeFixture(tester, p);
    },
  );
}
