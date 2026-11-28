import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'oculum_theme_effects_portrait_test.dart' as fixtures;

void main() {
  testWidgets('old unknown deposit does not hide valid mineable deposits', (
    tester,
  ) async {
    final dynamic state = await fixtures.mountSheet(
      tester,
      const Size(1440, 900),
    );
    final probe = OculumPerformanceProbe(state);
    probe.saveSheet();
    final deposits = <String, dynamic>{
      'legacy': {
        'realm': 'reame_cristallo',
        'material': 'retired_material',
        'remainingGrams': 1000,
      },
      'quartz': {
        'realm': 'reame_cristallo',
        'material': 'quarzo_risonante',
        'remainingGrams': 500,
      },
      'wrong-realm-material': {
        'realm': 'reame_cristallo',
        'material': 'vetro_azzurro_divoratore',
        'remainingGrams': 500,
      },
    };
    final sheet = Map<String, dynamic>.from(state.schedePersonaggio[0] as Map)
      ..['selectedPlaneId'] = 'reame_cristallo'
      ..['planarRuntime'] = {
        'realmExploration': {'deposits': deposits},
      };
    state.schedePersonaggio[0] = sheet;
    probe.load(sheet);
    await tester.pumpAndSettle();

    final exploration = probe.openMicroRealm();
    await tester.pumpAndSettle();
    expect(find.text('Quarzo risonante'), findsOneWidget);
    expect(find.text('Vetro azzurro del Deserto'), findsNothing);
    expect(find.text('0.5 kg disponibili · Grado 0'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Estrai'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Estrai'));
    await tester.pumpAndSettle();
    expect(find.text('0.25 kg disponibili · Grado 0'), findsOneWidget);
    final runtime = probe.snapshot()['planarRuntime'] as Map;
    final explorationState = runtime['realmExploration'] as Map;
    final savedDeposits = explorationState['deposits'] as Map;
    expect(savedDeposits['legacy']['remainingGrams'], 1000);
    expect(savedDeposits['quartz']['remainingGrams'], 250);
    expect(tester.takeException(), isNull);
    await tester.tap(find.widgetWithText(TextButton, 'Chiudi').last);
    await tester.pumpAndSettle();
    await exploration;
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('the Sunken Realm areas show their art and restore per sheet', (
    tester,
  ) async {
    final dynamic state = await fixtures.mountSheet(
      tester,
      const Size(1440, 900),
    );
    final probe = OculumPerformanceProbe(state);
    probe.saveSheet();
    final original = Map<String, dynamic>.from(
      state.schedePersonaggio[0] as Map,
    )..['selectedPlaneId'] = 'affogato';
    state.schedePersonaggio[0] = original;
    probe.load(original);
    await tester.pumpAndSettle();

    Future<void> openAreas() async {
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('current_realm_indicator')),
          matching: find.byType(IconButton),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Esplora il Regno Sommerso').last);
      await tester.pumpAndSettle();
    }

    await openAreas();
    expect(
      find.textContaining('interamente immerso nell’Eiva'),
      findsOneWidget,
    );
    final coral = find.widgetWithText(ChoiceChip, 'Barriera del Corallo Cavo');
    final plants = find.widgetWithText(ChoiceChip, 'Selva delle Fronde d’Eiva');
    expect(tester.widget<ChoiceChip>(coral).selected, isFalse);
    await tester.tap(coral);
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Barriera del Corallo Cavo'), findsWidgets);
    await tester.tap(plants);
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Selva delle Fronde d’Eiva'), findsWidgets);

    Navigator.of(tester.element(find.byType(AlertDialog).last)).pop();
    await tester.pumpAndSettle();
    probe.saveSheet();
    final saved = Map<String, dynamic>.from(state.schedePersonaggio[0] as Map);
    expect(saved['selectedPlaneId'], 'affogato');
    expect((saved['planarRuntime'] as Map)['affogatoAreaId'], 'fronde_eiva');
    probe.load(saved);
    await openAreas();
    expect(tester.widget<ChoiceChip>(plants).selected, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets(
    'defensive help rewards the owner once, including failed protection',
    (tester) async {
      final dynamic state = await fixtures.mountSheet(
        tester,
        const Size(1440, 900),
      );
      final probe = OculumPerformanceProbe(state);
      probe.saveSheet();
      final owner = probe.currentTag();
      final hp = probe.currentHp();
      final robot = Map<String, dynamic>.from(state.schedePersonaggio[0] as Map)
        ..['id'] = 'PROTECTED_ROBOT'
        ..['sheetTag'] = 'PROTECTED_ROBOT'
        ..['monsterBookSourceId'] = 'meccanio'
        ..['meccanioOwnerTag'] = owner
        ..['meccanio'] = <String, dynamic>{
          'grudges': <String, dynamic>{owner: 60},
          'helpOwnerHealth': {'hp': hp + 50, 'maximum': 100},
        };
      state.schedePersonaggio.add(robot);
      state.schedaCorrente = 1;
      probe.load(Map<String, dynamic>.from(robot));
      int refusal() =>
          readIntValue((robot['meccanio'] as Map)['grudges'][owner]);
      final request = <String, dynamic>{
        'id': 'help-success',
        'attack': 20,
        'defense': 20,
        'defenseHelp': 4,
        'defenseHelpers': [owner],
      };
      probe.rewardRobotProtection(request, reduction: 15);
      expect(refusal(), 45);
      probe.rewardRobotProtection(request, reduction: 15);
      expect(refusal(), 45);
      probe.rewardRobotProtection({
        ...request,
        'id': 'help-failure',
        'defense': 19,
      });
      expect(refusal(), 24);
      probe.rewardRobotProtection({
        ...request,
        'id': 'other-helper',
        'defenseHelpers': ['OTHER'],
      }, reduction: 30);
      expect(refusal(), 24);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    },
  );
  testWidgets('empathy is saved per owner and recovers on both rests', (
    tester,
  ) async {
    final dynamic state = await fixtures.mountSheet(
      tester,
      const Size(1440, 900),
    );
    final probe = OculumPerformanceProbe(state);
    probe.saveSheet();
    final owner = probe.currentTag();
    final robot = Map<String, dynamic>.from(state.schedePersonaggio[0] as Map)
      ..['id'] = 'ROBOT'
      ..['sheetTag'] = 'ROBOT'
      ..['monsterBookSourceId'] = 'meccanio_ammaccato'
      ..['meccanioOwnerTag'] = owner
      ..['meccanio'] = <String, dynamic>{
        'grudges': <String, dynamic>{owner: 60},
      };
    state.schedePersonaggio.add(robot);
    int refusal() => readIntValue((robot['meccanio'] as Map)['grudges'][owner]);
    expect(probe.robotEmpathyAvailable, isTrue);
    expect(probe.applyRobotEmpathy(17), isTrue);
    expect(refusal(), 43);
    expect(probe.applyRobotEmpathy(17), isFalse);
    expect(probe.applyRobotEmpathy(20, deception: true, natural: 20), isFalse);
    probe.saveSheet();
    expect(state.schedePersonaggio[0]['meccanioEmpathyUsed'], isTrue);
    probe.robotOwnerRest(longRest: false);
    expect(refusal(), 23);
    expect(probe.robotEmpathyAvailable, isTrue);
    expect(probe.applyRobotEmpathy(10), isTrue);
    expect(refusal(), 13);
    probe.robotOwnerRest(longRest: true);
    expect(refusal(), 0);
    expect(probe.robotEmpathyAvailable, isTrue);
    expect(probe.applyRobotEmpathy(25, deception: true, natural: 11), isTrue);
    expect(refusal(), 10);
    expect(probe.applyRobotEmpathy(25), isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
  testWidgets(
    'realm shops sell learnable ray and piranha scrolls only in their realms',
    (tester) async {
      final dynamic state = await fixtures.mountSheet(
        tester,
        const Size(1440, 900),
      );
      final probe = OculumPerformanceProbe(state);
      probe.saveSheet();
      state.gradoController.text = '0';
      for (final plane in ['angelico', 'affogato', 'sacro']) {
        final profile = plane == 'affogato'
            ? 'richiamo_piranha'
            : 'raggio_angelico';
        final offers = probe
            .realmOffers(plane)
            .where((o) => o['scrollProfileId'] == profile)
            .toList();
        expect(offers, hasLength(1));
        final offer = offers.single;
        expect(offer['planeId'], plane);
        expect(offer['cost'], greaterThan(0));
        if (plane == 'sacro') expect(offer['grade'], 3);
        final item = probe.merchantItem(offer);
        final restored = InventoryItem.fromJson(item.toJson());
        final data = Map<String, dynamic>.from(
          restored.craftData['scroll'] as Map,
        )..['learned'] = true;
        final effects = oculumScrollCombatEffects(data);
        if (profile == 'raggio_angelico') {
          expect(effects.any((e) => oculumIsAngelRayEffectId(e.id)), isTrue);
          expect(data['description'], contains('Karma'));
        } else {
          expect(effects.single.type, 'costrutto');
          expect(effects.single.target, 'Piranha minore');
        }
      }
      expect(
        probe
            .realmOffers('mezzano')
            .any(
              (o) =>
                  o['planeId'] != null &&
                  const {
                    'raggio_angelico',
                    'richiamo_piranha',
                  }.contains(o['scrollProfileId']),
            ),
        isFalse,
      );
      final robotOffer = probe
          .realmOffers('postea')
          .singleWhere((o) => o['id'] == 'postea_meccanio');
      expect(
        probe.merchantItem(robotOffer).craftData['alchemyPet'],
        'meccanio',
      );
      expect(monsterById('meccanio')!.isNpc, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    },
  );

  testWidgets(
    'Meccanio repairs use the owner or its own Mechanics and cap at maximum HP',
    (tester) async {
      final dynamic state = await fixtures.mountSheet(
        tester,
        const Size(1440, 900),
      );
      final probe = OculumPerformanceProbe(state);
      probe.saveSheet();
      final ownerTag = probe.currentTag();
      final robot = Map<String, dynamic>.from(state.schedePersonaggio[0] as Map)
        ..['id'] = 'MECCANIO'
        ..['sheetTag'] = 'MECCANIO'
        ..['nome'] = 'Meccanio'
        ..['tipoScheda'] = 'NPC'
        ..['monsterBookSourceId'] = 'meccanio'
        ..['meccanioOwnerTag'] = ownerTag
        ..['resilienza'] = '20'
        ..['currentResilienza'] = '20'
        ..['currentHp'] = '1'
        ..['activeStructuredEffects'] = <dynamic>[]
        ..['conditions'] = <dynamic>[];
      state.schedePersonaggio.add(robot);
      probe.ensureSheetTags();
      final tag = '${state.schedePersonaggio[1]['sheetTag']}';
      expect(probe.robotRepairTargets(), [1]);
      expect(probe.repairRobot(tag, natural: 12, total: 6), isTrue);
      expect(readIntValue(state.schedePersonaggio[1]['currentHp']), 7);
      expect(probe.repairRobot(tag, natural: 20, total: 6), isTrue);
      expect(readIntValue(state.schedePersonaggio[1]['currentHp']), 19);
      state.schedePersonaggio[1]['meccanioOwnerTag'] = 'OTHER_OWNER';
      expect(probe.repairRobot(tag, natural: 20, total: 100), isFalse);
      state.schedaCorrente = 1;
      probe.load(Map<String, dynamic>.from(state.schedePersonaggio[1] as Map));
      expect(probe.robotRepairTargets(), [1]);
      expect(probe.repairRobot(tag, natural: 20, total: 100000), isTrue);
      expect(probe.currentHp(), probe.maximumHp());
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    },
  );
}
