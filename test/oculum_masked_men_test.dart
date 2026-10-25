import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'oculum_theme_effects_portrait_test.dart' as fixtures;

void main() {
  test(
    'masked attacks preserve exact dice, fractions, ordering and interruption thresholds',
    () {
      expect(oculumMaskedPunchDamage(100, 20, 1), 132);
      expect(oculumMaskedPunchDamage(100, 20, 2), 144);
      expect(oculumMaskedPunchDamage(100, 20, 3), 180);
      expect(
        [for (var f = 1; f <= 3; f++) oculumMaskedVolleyCount(f, false, 99)],
        [6, 9, 13],
      );
      expect(
        [for (var f = 1; f <= 3; f++) oculumMaskedVolleyCount(f, true, 99)],
        [4, 7, 9],
      );
      expect(oculumMaskedVolleyDamage(210, 1, false), 73);
      expect(oculumMaskedVolleyDamage(210, 2, true), 49);
      expect(oculumMaskedVolleyOrder(['a', 'b'], 5, 'b', random: Random(1)), [
        'b',
        'a',
        'b',
        'a',
        'b',
      ]);
      expect(oculumMaskedVolleyStops(19, 100, 20, 2), isFalse);
      expect(oculumMaskedVolleyStops(20, 20, 20, 0), isFalse);
      expect(oculumMaskedVolleyStops(20, 21, 20, 1), isTrue);
      expect(oculumMaskedVolleyStops(20, 1, 100, 2), isTrue);
    },
  );
  test(
    'all masks have independent identities, costs, Open and canonical forms',
    () {
      final ids = [
        'uomo_maschera',
        'uomo_maschera_verde',
        'uomo_maschera_rossa',
        'uomo_maschera_blu',
        'uomo_maschera_viola',
        'ombra_ignota',
        'uomo_maschera_solare',
        'uomo_maschera_angelica',
      ];
      for (final id in ids) {
        final m = monsterById(id)!;
        expect(m.dropIds, isNotEmpty, reason: id);
        final art = oculumMonsterBookArt(m);
        expect(art.openName, isNotEmpty, reason: id);
        expect(oculumEnemyAbilityVariants(m, seed: 5), isEmpty, reason: id);
        expect(
          oculumMonsterBookSkills(m).length +
              (oculumMonsterBookImportArt(m)?.skills.length ?? 0),
          m.skillIds.length,
          reason: id,
        );
        for (final skill in art.skills) {
          expect(ArtSkill.fromJson(skill.toJson()).nome, skill.nome);
          for (var f = 1; f <= 3; f++) {
            expect(
              skill.oculumMinimoPerLivello(f),
              lessThanOrEqualTo(skill.oculumMassimoPerLivello(f)),
            );
          }
        }
      }
      expect(
        oculumMonsterBookArt(monsterById('ombra_ignota')!).nome,
        'L’Ombra',
      );
      final red = oculumPlanarTechnique('masked_serious_punch')!;
      expect(red.costResource, 'nessuna');
      expect(red.cooldowns, [3, 3, 3]);
      expect(oculumPlanarTechnique('masked_blue_chain')!.cooldowns, [2, 2, 2]);
    },
  );
  testWidgets(
    'green memory, violet recovery, shadow lifetimes and angelic HP recovery persist correctly',
    (tester) async {
      final dynamic state = await fixtures.mountSheet(
        tester,
        const Size(1440, 1000),
      );
      final p = OculumPerformanceProbe(state);
      state.datiCaricati = false;
      if (state.schedePersonaggio.isEmpty) {
        state.schedePersonaggio.add(
          Map<String, dynamic>.from(p.snapshot())
            ..['id'] = 'MaskOcu:3690AAAA'
            ..['sheetTag'] = 'MaskOcu:3690AAAA',
        );
        state.schedaCorrente = 0;
      }
      state.skills.clear();
      state.skills.addAll(
        oculumMonsterBookSkills(monsterById('uomo_maschera_verde')!),
      );
      p.maskedPassives();
      expect(
        p.conditions.any((c) => c.conditionType == 'ricordo_vitale'),
        isTrue,
      );
      state.activeConditions.clear();
      state.skills.clear();
      state.skills.addAll(
        oculumMonsterBookSkills(monsterById('uomo_maschera_viola')!),
      );
      state.oculumController.text = '6';
      state.currentOculumController.text = '2';
      p.maskedTurn(99);
      expect(p.resourceCurrent('oculum'), 4);
      state.currentOculumController.text = '6';
      p.maskedTurn(19);
      expect(state.temporaryOculum, 1);
      p.maskedPower('mask_shadow_form', 1);
      expect(p.maskedShadow(), isTrue);
      expect(p.planarIncoming(30, element: 'taglio'), 0);
      expect(p.planarIncoming(30, element: 'fuoco'), 30);
      p.maskedAction();
      expect(p.maskedShadow(), isFalse);
      p.maskedPower('mask_shadow_form', 3);
      expect(p.maskedShadow(), isTrue);
      state.playerReportedTurn++;
      expect(p.maskedShadow(), isFalse);
      state.skills.clear();
      state.skills.addAll(
        oculumMonsterBookSkills(monsterById('uomo_maschera_angelica')!),
      );
      state.resilienzaController.text = '20';
      state.currentResilienzaController.text = '20';
      state.currentHpController.text = '100';
      expect(p.maskedAngelicHit(10), 0);
      expect(p.maskedAngelicHit(0), 0);
      expect(p.maskedAngelicHit(10), 0);
      expect(p.maskedAngelicHit(10), 5);
      expect(state.currentHpController.text, '105');
      p.finishPlanarFight();
      expect(p.planarStateSnapshot()['maskedAngelicHits'], isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
    },
  );
  testWidgets(
    'volley sends one hit at a time and third-hit interrupt retains completed hits',
    (tester) async {
      final dynamic state = await fixtures.mountSheet(
        tester,
        const Size(1440, 1000),
      );
      final p = OculumPerformanceProbe(state);
      state.datiCaricati = false;
      state.modalitaMaster = true;
      state.isMasterHost = true;
      if (state.schedePersonaggio.isEmpty) {
        state.schedePersonaggio.add(
          Map<String, dynamic>.from(p.snapshot())
            ..['id'] = 'VolleyOcu:3690AAAA'
            ..['sheetTag'] = 'VolleyOcu:3690AAAA',
        );
        state.schedaCorrente = 0;
      }
      p.ensureEncounters();
      final owner = p.ownerTag();
      final packets = [
        for (var i = 0; i < 4; i++)
          <String, dynamic>{
            'id': 'volley:$i',
            'attackGroupId': 'batch1',
            'kind': 'attack',
            'status': 'pending',
            'scope': p.permissionScope,
            'encounterId': state.selectedMasterInitiativeGroupId,
            'sourceTag': owner,
            'targetTag': 'TargetOcu:3690BBBB',
            'sourceName': 'Blu',
            'targetName': 'Bersaglio',
            'attack': 25,
            'damage': 8,
            'maskedVolley': true,
            'maskedHitIndex': i,
            'maskedSelectedTargets': [
              'TargetOcu:3690BBBB',
              'OtherOcu:3690CCCC',
            ],
          },
      ];
      p.startMaskedVolley(packets);
      expect(state.onlineCombatRequests.containsKey('volley:1'), isFalse);
      packets[0]['status'] = 'resolved';
      p.advanceMaskedVolley(packets[0], 10, 20);
      expect(state.onlineCombatRequests.containsKey('volley:1'), isTrue);
      p.advanceMaskedVolley(packets[0], 10, 20);
      expect(state.onlineCombatRequests.containsKey('volley:2'), isFalse);
      packets[1]['status'] = 'resolved';
      p.advanceMaskedVolley(packets[1], 10, 20);
      expect(state.onlineCombatRequests.containsKey('volley:2'), isTrue);
      final interrupt = <String, dynamic>{
        ...packets[2],
        'senderTag': 'OtherOcu:3690CCCC',
        'maskedInterrupt': true,
        'maskedInterruptNatural': 20,
      };
      expect(p.maskedInterrupt(interrupt), isTrue);
      expect(state.onlineCombatRequests['volley:2']['status'], 'cancelled');
      expect(state.onlineCombatRequests['volley:0']['status'], 'resolved');
      expect(state.onlineCombatRequests.containsKey('volley:3'), isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
    },
  );
}
