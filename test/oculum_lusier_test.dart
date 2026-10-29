import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'oculum_escape_provoker_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

void main() {
  testWidgets(
    'Lusier export measures current Total Power in the production sheet',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      final sheet = oculumBuildLusierSheet();
      sheet['id'] = sheet['sheetTag'] = p.ownerTag();
      p.load(sheet);
      p.invalidateDerivedCaches();
      p.refillStatsAndHealth();
      final power = p.totalPower(state.schedaCorrente as int);
      expect(power, 301);
      final fullState = p.snapshot();
      p.refillStatsAndHealth();
      expect(
        p.totalPower(state.schedaCorrente as int),
        power,
        reason: 'refill cannot stack core bonuses',
      );
      final portable = oculumBuildLusierSheet();
      for (final key in [
        'currentResilienza',
        'currentVolonta',
        'currentMateria',
        'currentOculum',
        'normalCurrentOculum',
        'maxOculum',
        'currentHp',
        'scudoOculum',
        'scudoOculumMax',
      ]) {
        if (fullState.containsKey(key)) portable[key] = fullState[key];
      }
      // Tests can run beside other suites importing the canonical characters.
      // Stage exports separately; only promote them after the suite succeeds.
      final folder = Directory('build/verified-character-exports/lusier_iii')
        ..createSync(recursive: true);
      File('${folder.path}/Lusier_III.json').writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(portable)}\n',
      );
      final portableCode = oculumEncodeSheetShareText([portable]);
      File(
        '${folder.path}/Lusier_III.codice.txt',
      ).writeAsStringSync('$portableCode\n');
      expect(oculumDecodeSheetShareText(portableCode).single, portable);
      expect(readIntValue(portable['currentHp']), p.maximumHp());
      expect(portable.containsKey('sheetTag'), false);
      final report = {
        'totalPower': power,
        'coreStats': p.coreStats(),
        'maximumHp': p.maximumHp(),
        'haniel':
            'Quando avrai una potenza totale pari o superiore a $power sarai pronta.',
      };
      File('${folder.path}/potenza.json').writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(report)}\n',
      );
      final imported = oculumDecodeSheetShareText(portableCode).single;
      p.load({...imported, 'id': p.ownerTag(), 'sheetTag': p.ownerTag()});
      p.invalidateDerivedCaches();
      expect(p.currentHp(), 690);
      expect(p.maximumHp(), 690);
      expect(p.totalPower(state.schedaCorrente as int), 301);
      await closeFixture(tester, p);
    },
  );
  test(
    'Lusier preserves the elite base and assigns every level and grade point once',
    () {
      final s = oculumBuildLusierSheet();
      final stats = [
        'resilienza',
        'volonta',
        'materia',
        'oculum',
      ].map((k) => int.parse('${s[k]}')).toList();
      expect(
        stats.reduce((a, b) => a + b),
        56 + oculumGeneratedMonsterBudget('Mostro', 13),
      );
      expect(stats[1], greaterThan(stats[3]));
      expect(stats[3], greaterThan(stats[0]));
      expect(s['scudoCritico'], '1');
      expect(s['scudoOculum'], '150');
      expect(s['livello'], '13');
      expect(s['grado'], '1');
      for (final raw in s['skills'] as List) {
        final skill = CharacterSkill.fromJson(Map<String, dynamic>.from(raw));
        expect(
          CharacterSkill.fromJson(skill.toJson()).toJson(),
          skill.toJson(),
        );
        expect(
          oculumCharacterSkillFormCost(skill.forme.first)!.minimum,
          greaterThan(0),
        );
      }
      final code = oculumEncodeSheetShareText([s]);
      expect(oculumDecodeSheetShareText(code).single, s);
      final items = (s['inventario'] as List)
          .map((i) => InventoryItem.fromJson(Map<String, dynamic>.from(i)))
          .toList();
      expect(
        items.singleWhere((i) => i.nome == 'Vitalium Ridefinito').quantita,
        1,
      );
      expect(
        items
            .singleWhere((i) => i.nome == 'Spada sacra di Lusier III')
            .bonusDanno,
        20,
      );
    },
  );
  testWidgets(
    'cards keep per-object ammo, recharge once per turn and retain Lusier exception across JSON',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      state.livelloController.text = '13';
      state.gradoController.text = '1';
      final deck = oculumExplosiveCards(lusier: true);
      state.inventario.add(deck);
      final request = {
        'id': 'cards-one',
        'effects': [
          {
            'target': 'explosive_cards_damage',
            'narrativeText': 'Carte:5',
            'valueExpression': '67',
          },
        ],
      };
      expect(p.claimCards(request), true);
      expect(deck.craftData['cardsRemaining'], 5);
      expect(request['damage'], 67);
      expect(p.claimCards(request), true);
      expect(deck.craftData['cardsRemaining'], 5);
      p.cardsTurnStart();
      expect(deck.craftData['cardsRemaining'], 8);
      p.cardsTurnStart();
      expect(deck.craftData['cardsRemaining'], 8);
      expect(p.itemSaleValue(deck), inInclusiveRange(180, 250));
      final restored = InventoryItem.fromJson(deck.toJson());
      expect(restored.craftData['cardsRechargeOverride'], 3);
      expect(restored.ability!.forme.map((f) => f.livello), ['10', '12', '20']);
      expect(oculumExplosiveCardsForm(1).capacity, 5);
      expect(oculumExplosiveCardsForm(2).recharge, 2);
      expect(oculumExplosiveCardsForm(3).capacity, 15);
      await closeFixture(tester, p);
    },
  );
  test(
    'Derision boundaries, natural criticals and double critical replace rewards',
    () {
      ({int will, bool advantage, int accuracy, int beyondDefense}) r(
        int def, {
        int nat = 10,
        int attacker = 10,
      }) => oculumLusierDerisionResult(
        attack: 20,
        defense: def,
        attackNatural: attacker,
        defenseNatural: nat,
      );
      expect(r(19).will, -5);
      expect(r(20).will, -3);
      expect(r(25).will, -3);
      expect(r(26).will, 3);
      expect(r(26).advantage, true);
      expect(r(21, nat: 20).accuracy, 5);
      expect(r(21, attacker: 1).accuracy, 5);
      expect(r(40, nat: 20).accuracy, 9);
      expect(r(40, nat: 20).beyondDefense, 10);
      expect(r(40, nat: 19).beyondDefense, 0);
    },
  );
  testWidgets(
    'Derision applies through combat resolution once, even when defended, and never damages HP',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      final tag = p.ownerTag();
      final request = <String, dynamic>{
        'id': 'lusier-test',
        'status': 'pending',
        'targetTag': tag,
        'sourceTag': 'lusier',
        'sourceName': 'Lusier III',
        'scope': p.permissionScope,
        'encounterId': p.turnResourceTestPacket('probe')['encounterId'],
        'attack': 20,
        'natural': 10,
        'damage': 999,
        'level': 13,
        'grade': 1,
        'element': 'solare',
        'effects': [
          {
            'type': 'planar',
            'target': 'lusier_derision',
            'valueExpression': '1',
          },
        ],
      };
      state.onlineCombatRequests['lusier-test'] = request;
      final hp = p.currentHp();
      await p.resolveCombatDefense(request, 'volonta', 26);
      expect(p.currentHp(), hp);
      expect(request['lusierDerisionResolved'], true);
      final effects = (state.activeStructuredEffects as List)
          .where((e) => '${e['effectId']}'.startsWith('lusier_will:'))
          .toList();
      expect(effects, hasLength(1));
      expect(effects.single['value'], 3);
      await p.resolveCombatDefense(request, 'volonta', 26);
      expect(
        (state.activeStructuredEffects as List).where(
          (e) => '${e['effectId']}'.startsWith('lusier_will:'),
        ),
        hasLength(1),
      );
      final saved = p.snapshot();
      p.load(saved);
      expect(
        (state.activeStructuredEffects as List).any(
          (e) => e['type'] == 'lusier_reply',
        ),
        true,
      );
      await closeFixture(tester, p);
    },
  );
}
