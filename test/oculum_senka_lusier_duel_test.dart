import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'oculum_escape_provoker_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

// A bounded production-engine scenario, not an estimate of either win rate.
// Totals and card dice are scripted; defensive resolution and damage layers
// are the same applyResolvedOnlineDefense path used by local/shared fights.
void main() {
  testWidgets(
    'Senka level12 with active mask matches Lusier PT and resolves a repeatable engine duel without altering her original code',
    (tester) async {
      final originalFile = File(
        'output/characters/senka_kamaria/Senka_Kamaria.json',
      );
      final originalText = originalFile.readAsStringSync();
      final original = Map<String, dynamic>.from(
        jsonDecode(originalText) as Map,
      );
      expect(readIntValue(original['livello']), 1);
      final (state, p) = await fixtures.mountFight(tester);
      final hero = p.ownerTag();
      final senka = Map<String, dynamic>.from(jsonDecode(originalText) as Map)
        ..['id'] = hero
        ..['sheetTag'] = hero
        ..['livello'] = '12'
        ..['grado'] = '0'
        ..['tipoScheda'] = 'Personaggio'
        ..['inMasterParty'] = true;
      final lusier = oculumBuildLusierSheet()
        ..['id'] = 'LUSIERDUEL'
        ..['sheetTag'] = 'LUSIERDUEL'
        ..['inMasterParty'] = false;
      state.schedePersonaggio
        ..clear()
        ..addAll([senka, lusier]);
      p.ensureSheetTags();
      final senkaTag = '${state.schedePersonaggio[0]['sheetTag']}';
      final lusierTag = '${state.schedePersonaggio[1]['sheetTag']}';
      state.masterInitiativeTokens
        ..clear()
        ..addAll([
          <String, dynamic>{
            'id': senkaTag,
            'sheetTag': senkaTag,
            'name': 'Kamaria Senka',
            'side': 'party',
            'status': 'active',
            'level': 12,
          },
          <String, dynamic>{
            'id': lusierTag,
            'sheetTag': lusierTag,
            'name': 'Lusier III',
            'side': 'enemy',
            'status': 'ready',
            'level': 13,
          },
        ]);
      p.recordCurrentEncounter();
      void load(int index) {
        state.schedaCorrente = index;
        p.load(
          Map<String, dynamic>.from(state.schedePersonaggio[index] as Map),
        );
        state.modalitaMaster = true;
        p.invalidateDerivedCaches();
      }

      void save() {
        state.schedePersonaggio[state.schedaCorrente] = p.snapshot();
      }

      load(1);
      p.refillStatsAndHealth();
      final lusierPower = p.totalPower(1);
      save();
      expect(lusierPower, 301); // Grade I HP multiplier 15 adds 3 PT.
      load(0);
      for (final art in (state.arti as List).cast<CharacterArt>()) {
        for (final skill in art.skills) {
          skill.livello = 3;
        }
      }
      for (final skill in (state.skills as List).cast<CharacterSkill>()) {
        skill.equipaggiata = true;
      }
      final moon = (state.titoli as List).cast<OculumTitle>().singleWhere(
        (t) => t.openEffects.any((e) => e.target == 'senka_moon_open'),
      );
      moon.evoluto = true;
      final runtime = Map<String, dynamic>.from(p.planarStateSnapshot());
      runtime['progressionNamedNpcKills'] = {
        'erik_i': {
          'count': 1,
          'killIds': ['fixture:erik'],
        },
      };
      final prepared = p.snapshot()..['planarRuntime'] = runtime;
      p.load(prepared);
      final mask = (state.inventario as List).cast<InventoryItem>().singleWhere(
        (i) => i.craftData['senkaMask'] == true,
      );
      expect(p.manifestSenkaMask(mask, true), true);
      // Allocate permanent base points on this isolated scenario copy only.
      // This is a fixture allocation, not an alteration of level-growth rules.
      var delta = lusierPower - p.totalPower(0);
      expect(delta, greaterThanOrEqualTo(0));
      final allocation = <String, int>{
        'resilienza': delta ~/ 5,
        'volonta': delta ~/ 5,
        'materia': delta * 3 ~/ 10,
      };
      allocation['oculum'] =
          delta - allocation.values.fold<int>(0, (a, b) => a + b);
      state.resilienzaController.text =
          '${readIntValue(state.resilienzaController.text) + allocation['resilienza']!}';
      state.volontaController.text =
          '${readIntValue(state.volontaController.text) + allocation['volonta']!}';
      state.materiaController.text =
          '${readIntValue(state.materiaController.text) + allocation['materia']!}';
      state.oculumController.text =
          '${readIntValue(state.oculumController.text) + allocation['oculum']!}';
      p.invalidateDerivedCaches();
      // Power reads current resources: fill this setup copy after assigning
      // base points before measuring the next delta, not only after the loop.
      p.refillStatsAndHealth();
      for (var i = 0; i < 4 && p.totalPower(0) != lusierPower; i++) {
        delta = lusierPower - p.totalPower(0);
        state.volontaController.text =
            '${readIntValue(state.volontaController.text) + delta}';
        p.invalidateDerivedCaches();
        p.refillStatsAndHealth();
      }
      p.refillStatsAndHealth();
      expect(p.totalPower(0), lusierPower);
      expect(mask.equipaggiata, true);
      final initialSenka = {
        'power': p.totalPower(0),
        'core': p.coreStats(),
        'hp': p.currentHp(),
        'maxHp': p.maximumHp(),
      };
      save();
      final trace = <Map<String, dynamic>>[];
      Map<String, dynamic> vitals() => {
        'hp': p.currentHp(),
        'normalShield': readIntValue(state.scudoController.text),
        'oculumShield': readIntValue(state.scudoOculumController.text),
        'turn': p.combatTurnStatus(),
        'resources': p.combatTurnResources(),
      };
      Map<String, dynamic> packet(
        String id,
        int source,
        int target,
        int attack,
        int damage,
        String element, {
        List<Map<String, dynamic>> effects = const [],
      }) => {
        'id': id,
        'status': 'pending',
        'kind': 'attack',
        'scope': p.permissionScope,
        'encounterId': p.turnResourceTestPacket('scope')['encounterId'],
        'sourceTag': source == 0 ? senkaTag : lusierTag,
        'targetTag': target == 0 ? senkaTag : lusierTag,
        'sourceName': source == 0 ? 'Kamaria Senka' : 'Lusier III',
        'targetName': target == 0 ? 'Kamaria Senka' : 'Lusier III',
        'attack': attack,
        'damage': damage,
        'natural': 12,
        'level': source == 0 ? 12 : 13,
        'grade': source == 0 ? 0 : 1,
        'difficulty': 'normale',
        'element': element,
        'effects': effects,
      };
      Future<void> resolve(
        Map<String, dynamic> request,
        int target,
        int defense,
      ) async {
        save();
        load(target);
        request['scope'] = p.permissionScope;
        request['encounterId'] = p.turnResourceTestPacket(
          'scope',
        )['encounterId'];
        state.onlineCombatRequests[request['id']] = request;
        final before = vitals();
        await p.resolveCombatDefense(request, 'riflessi', defense);
        expect(
          request['status'],
          isNot('pending'),
          reason: 'the engine must really resolve the packet',
        );
        final after = vitals();
        trace.add({
          'id': request['id'],
          'attack': request['attack'],
          'defense': defense,
          'damage': request['damage'],
          'outcome': request['outcome'],
          'receipt': request['damageReceipt'],
          'shadowAvoided': request['senkaShadowAvoided'],
          'before': before,
          'after': after,
        });
        final received = p.currentHp(),
            shield = readIntValue(state.scudoOculumController.text);
        await p.resolveCombatDefense(request, 'riflessi', defense);
        expect(p.currentHp(), received);
        expect(readIntValue(state.scudoOculumController.text), shield);
        save();
      }

      // Lusier launches five cards, using a fixed legal series of d25 results.
      load(1);
      p.setTurn(round: 1, activeIndex: 1);
      expect(await p.spendCombatRoll(), true);
      final deck = (state.inventario as List).cast<InventoryItem>().singleWhere(
        (i) => i.craftData.containsKey('cardsRemaining'),
      );
      final ammo = readIntValue(deck.craftData['cardsRemaining']);
      final cards = packet(
        'duel-cards',
        1,
        0,
        48,
        0,
        'solare',
        effects: [
          {
            'target': 'explosive_cards_damage',
            'type': 'planar',
            'narrativeText': 'Carte:5',
            'valueExpression':
                '${7 + 11 + 17 + 19 + 23 + 5 * (p.damageTotal() ~/ 5)}',
          },
        ],
      );
      expect(p.claimCards(cards), true);
      expect(readIntValue(deck.craftData['cardsRemaining']), ammo - 5);
      expect(p.claimCards(cards), true);
      expect(readIntValue(deck.craftData['cardsRemaining']), ammo - 5);
      await resolve(cards, 0, 39);
      p.turn();
      trace.add({
        'stage': 'turn advancement after the resolved cards',
        'turn': p.combatTurnStatus(),
        'resources': p.combatTurnResources(),
      });

      // A paid shadow form avoids a physical hit through the real defense path.
      final art = (state.arti as List).cast<CharacterArt>().firstWhere(
        (a) => a.nome == "L'Ombra Mascherata",
      );
      final mantle = oculumEquipmentAbilityFromArt(
        art.skills.first,
      ).forme.first;
      final beforeOculum = p.availableArtResource('oculum');
      expect(await p.spendCombatRoll(), true);
      expect(p.spendArtResource('oculum', 3), 3);
      p.applyEffects(mantle.effettiStrutturati, source: 'Duello · Mantello');
      expect(p.availableArtResource('oculum'), beforeOculum - 3);
      expect(p.senkaShadowEvades({'element': 'tagliente'}), true);
      save();
      final physical = packet('duel-shadow', 1, 0, 48, 75, 'tagliente');
      await resolve(physical, 0, 20);
      expect(physical['senkaShadowAvoided'], true);
      expect(readIntValue((physical['damageReceipt'] as Map?)?['hpLost']), 0);

      // Clone creation and absorption use production runtime, with no recursive
      // summon capability or resetting the per-fight lifetime counter.
      expect(p.spendArtResource('materia', 2), 2);
      final cloneIndex = p.senkaClone(2 * 2 + 12);
      expect(cloneIndex, greaterThanOrEqualTo(2));
      final clone = Map<String, dynamic>.from(
        state.schedePersonaggio[cloneIndex] as Map,
      );
      expect(readIntValue(clone['currentHp']), 16);
      expect((clone['planarRuntime'] as Map)['senkaClone'], true);
      final created = p.senkaCloneCount();
      final hpTemp = readIntValue(state.hpTempController.text);
      expect(p.senkaFusion(), 1);
      expect(p.senkaCloneCount(), created);
      expect(readIntValue(state.hpTempController.text), hpTemp + 16);
      save();

      // One seeded lunar volley, then the single-sum exhausted finishing skill.
      final moonNow = (state.titoli as List).cast<OculumTitle>().singleWhere(
        (t) => t.openEffects.any((e) => e.target == 'senka_moon_open'),
      );
      moonNow.openAttiva = true;
      p.invalidateDerivedCaches();
      final moonEffect = moonNow.skillExtra.first.effects;
      final preparedMoon = p.prepareSenka(moonEffect, seed: 17)!;
      final metadata = jsonDecode(preparedMoon.first.narrativeText) as Map;
      expect(metadata['ownOpen'], true);
      trace.add({
        'stage': 'Open lunare',
        'cuts': metadata['cuts'],
        'damagePerCut': metadata['damagePerCut'],
        'note':
            'preparazione reale; distribuzione bersagli non simulata in questo scenario',
      });
      final cuts = packet(
        'duel-mille',
        0,
        1,
        47,
        0,
        'tagliente',
        effects: [
          {'target': 'senka_thousand_cuts', 'type': 'planar'},
        ],
      );
      final totalBefore = p.totalPower(0);
      expect(p.spendArtResource('materia', 1), 1);
      final damageBefore = p.damageTotal();
      p.claimSenkaAttack(cuts);
      expect(cuts['damage'], damageBefore + 47 + p.totalPower(0));
      expect(p.exhausted(), true);
      trace.add({
        'stage': 'Mille Tagli',
        'powerBeforeCost': totalBefore,
        'powerUsed': p.totalPower(0),
        'exhausted': p.exhausted(),
      });
      await resolve(cuts, 1, 44);
      expect(originalFile.readAsStringSync(), originalText);
      final folder = Directory('output/simulation')
        ..createSync(recursive: true);
      File('${folder.path}/Senka_Lv12_vs_Lusier_III.json').writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert({
          'scenario': 'bounded production combat resolver',
          'initialSenka': initialSenka,
          'lusierInitialPower': lusierPower,
          'allocation': allocation,
          'scriptedCardDice': [7, 11, 17, 19, 23],
          'trace': trace,
          'limits': [
            'controlled totals, not dice UI',
            'no independent network clients',
            'bounded scenario: no winner or balance estimate',
            'lunar volley preparation only',
            'grapple/teleport covered by separate regressions',
          ],
          'originalSenkaLevel': 1,
        }),
      );
      await closeFixture(tester, p);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
