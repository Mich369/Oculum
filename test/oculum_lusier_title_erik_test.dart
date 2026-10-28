import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'oculum_escape_provoker_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

void main() {
  testWidgets(
    'title editor cannot reopen a spent Open while its Open Skill stays available',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      final sheet = oculumBuildLusierSheet()
        ..['id'] = p.ownerTag()
        ..['sheetTag'] = p.ownerTag();
      p.load(sheet);
      final title = (state.titoli as List).cast<OculumTitle>().single;
      // Isolate activation from the independently tested attack planner.
      title.openEffects.removeWhere((e) => e.target == 'lusier_open_ray');
      p.useTitleOpen(title);
      expect(title.openAttiva, true);
      p.useTitleOpen(title);
      expect(title.openAttiva, false);
      p.useTitleOpen(title);
      expect(title.openAttiva, false);
      expect(title.openUsedSinceLongRest, true);
      expect(p.prepareLusierTitle(title.skillExtra.single.effects), isNotNull);
      await closeFixture(tester, p);
    },
  );
  testWidgets(
    'royal weapon strike uses current damage once and grants shield only on hit, once across save',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      final sheet = oculumBuildLusierSheet()..['id'] = p.ownerTag();
      sheet['sheetTag'] = p.ownerTag();
      p.load(sheet);
      p.invalidateDerivedCaches();
      final title = (state.titoli as List).cast<OculumTitle>().single;
      final base = p.damageTotal();
      File('build/oct28-lusier-bonus-audit.json').writeAsStringSync(
        jsonEncode({
          for (final key in ['resilienza', 'volonta', 'materia', 'oculum'])
            key: p.coreBonusAudit(key),
        }),
      );
      final vars = p.formulaContext();
      final agility = max(
        vars['riflessi'] ?? 0,
        vars['precisione'] ?? 0,
      ).toInt();
      final effects = p.prepareLusierTitle(title.skillEffects)!;
      final request = <String, dynamic>{
        'id': 'regal-one',
        'sourceTag': p.ownerTag(),
        'attack': 30,
        'damage': 99999,
        'effects': effects.map((e) => e.toJson()).toList(),
        'outcome': 'avoided',
      };
      p.claimLusierTitle(request);
      expect(request['damage'], base + agility);
      final shield = int.parse(state.scudoOculumController.text as String);
      p.confirmLusierTitle(request);
      expect(int.parse(state.scudoOculumController.text as String), shield);
      request['outcome'] = 'full';
      p.confirmLusierTitle(request);
      expect(
        int.parse(state.scudoOculumController.text as String),
        shield + 5 + agility ~/ 2,
      );
      p.load(p.snapshot());
      p.confirmLusierTitle(request);
      expect(
        int.parse(state.scudoOculumController.text as String),
        shield + 5 + agility ~/ 2,
      );
      final broken = <String, dynamic>{
        'effects': [
          {'target': 'lusier_open_ray', 'narrativeText': 'broken'},
        ],
      };
      expect(() => p.claimLusierTitle(broken), returnsNormally);
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'own Open upgrades the thin ray; another Open does not; large-ray critical damage never compounds',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      final sheet = oculumBuildLusierSheet()..['id'] = p.ownerTag();
      sheet['sheetTag'] = p.ownerTag();
      p.load(sheet);
      p.invalidateDerivedCaches();
      final title = (state.titoli as List).cast<OculumTitle>().single;
      final thin = title.skillExtra.single;
      expect(p.lusierConditionGuard(), 15);
      expect(p.lusierConditionResisted('vita_afona', 15), true);
      expect(p.lusierConditionResisted('vita_afona', 16), false);
      final weak = p.prepareLusierTitle(thin.effects)!;
      final weakData = jsonDecode(weak.single.narrativeText) as Map;
      expect(weakData['buff'], false);
      expect(readIntValue(weakData['dice']), inInclusiveRange(1, 25));
      title.openAttiva = true;
      p.invalidateDerivedCaches();
      expect(p.lusierConditionGuard(), 30);
      expect(p.lusierConditionResisted('vita_afona', 30), true);
      expect(p.lusierConditionResisted('vita_afona', 31), false);
      final buffed = p.prepareLusierTitle(thin.effects)!;
      expect(buffed.single.maximumTargets, 2);
      final one = <String, dynamic>{
        'attack': 30,
        'effects': buffed.map((e) => e.toJson()).toList(),
      };
      final two = <String, dynamic>{
        'attack': 30,
        'effects': buffed.map((e) => e.toJson()).toList(),
      };
      p.claimLusierTitle(one);
      p.claimLusierTitle(two, targets: 2);
      expect(one['attack'], 40);
      expect(two['attack'], 30);
      expect(one['damage'], two['damage']);
      List<OculumStructuredEffect>? ray;
      for (var seed = 0; seed < 1000; seed++) {
        final candidate = p.prepareLusierTitle(title.openEffects, seed: seed)!;
        final r = candidate.singleWhere((e) => e.target == 'lusier_open_ray');
        if (readIntValue((jsonDecode(r.narrativeText) as Map)['dice']) > 90) {
          ray = candidate;
          break;
        }
      }
      expect(ray, isNotNull);
      final r = ray!.singleWhere((e) => e.target == 'lusier_open_ray');
      final packet = <String, dynamic>{
        'attack': 30,
        'effects': ray.map((e) => e.toJson()).toList(),
      };
      final expected = (readIntValue(r.valueExpression) * 1.25).floor();
      p.claimLusierTitle(packet, targets: 2);
      p.claimLusierTitle(packet, targets: 2);
      expect(packet['attack'], 35);
      expect(packet['damage'], expected);
      title.openAttiva = false;
      final other = OculumTitle.fromJson(title.toJson())
        ..chiaveSistema = 'other_open'
        ..openAttiva = true;
      state.titoli.add(other);
      p.invalidateDerivedCaches();
      expect(
        (jsonDecode(p.prepareLusierTitle(thin.effects)!.single.narrativeText)
            as Map)['buff'],
        false,
      );
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'Solar Vitalium is granted once per fight and heals 65 percent current plus 10 percent maximum capped without reducing overflow',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      final sheet = oculumBuildLusierSheet()..['id'] = p.ownerTag();
      sheet['sheetTag'] = p.ownerTag();
      p.load(sheet);
      p.grantSolarVitalium();
      p.grantSolarVitalium();
      final items = (state.inventario as List)
          .cast<InventoryItem>()
          .where((i) => i.nome == 'Vitalium Solare')
          .toList();
      expect(items, hasLength(1));
      expect(p.usableMerchantItem(items.single), true);
      final maximum = p.maximumHp();
      expect(oculumSolarVitaliumHp(40, 100), 76);
      expect(oculumSolarVitaliumHp(90, 100), 100);
      expect(oculumSolarVitaliumHp(0, 100), 10);
      expect(oculumSolarVitaliumHp(1, 15), 4);
      expect(oculumSolarVitaliumHp(110, 100), 110);
      state.currentHpController.text = '${maximum ~/ 4}';
      final before = p.currentHp();
      p.applySolarVitalium();
      expect(p.currentHp(), oculumSolarVitaliumHp(before, maximum));
      state.currentHpController.text = '${maximum - 5}';
      final critical = p.criticalShieldTotal();
      p.applySolarVitalium();
      expect(p.currentHp(), maximum);
      expect(p.criticalShieldTotal(), critical + 1);
      state.currentHpController.text = '${maximum + 10}';
      p.applySolarVitalium();
      expect(state.currentHpController.text, '${maximum + 10}');
      // Ordinary Solar HP retains its normal cap; the consumable must not erase
      // an existing raw reserve while restoring resources.
      expect(p.currentHp(), maximum);
      await closeFixture(tester, p);
    },
  );

  testWidgets(
    'Erik allocates elite level growth once, exports a separate private-data-free code and measures his actual power',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      final sheet = oculumBuildErikSheet();
      expect(sheet['livello'], '8');
      expect(sheet['grado'], '0');
      expect(
        [
          'resilienza',
          'volonta',
          'materia',
          'oculum',
        ].fold<int>(0, (n, k) => n + readIntValue(sheet[k])),
        56 + oculumGeneratedMonsterBudget('Mostro', 8),
      );
      expect(
        (sheet['inventario'] as List).every(
          (i) => (i as Map)['equipaggiata'] == true,
        ),
        true,
      );
      expect(jsonEncode(sheet), isNot(contains('lusier_self_mastery')));
      final input = {...sheet, 'id': p.ownerTag(), 'sheetTag': p.ownerTag()};
      p.load(input);
      p.invalidateDerivedCaches();
      p.refillStatsAndHealth();
      final power = p.totalPower(state.schedaCorrente as int);
      final folder = Directory('output/characters/erik_i')
        ..createSync(recursive: true);
      File('${folder.path}/Erik_I.json').writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(sheet)}\n',
      );
      final code = oculumEncodeSheetShareText([sheet]);
      File('${folder.path}/Erik_I.codice.txt').writeAsStringSync('$code\n');
      expect(oculumDecodeSheetShareText(code).single, sheet);
      File('${folder.path}/potenza.json').writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert({'totalPower': power, 'level': 8, 'grade': 0, 'coreStats': p.coreStats(), 'knownBy': 'Haniel'})}\n',
      );
      expect(power, lessThan(277));
      await closeFixture(tester, p);
    },
  );
}
