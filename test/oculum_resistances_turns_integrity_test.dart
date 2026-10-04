import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oculum/main.dart';

void main() {
  test('Oculum dodge display cannot exceed its total', () {
    expect(oculumAvailableDodgeCount(total: 2, consumed: -5), 2);
    expect(oculumAvailableDodgeCount(total: 2, consumed: 0), 2);
    expect(oculumAvailableDodgeCount(total: 2, consumed: 1), 1);
    expect(oculumAvailableDodgeCount(total: 2, consumed: 8), 0);
  });

  test('Oculum overfill stays usable and displays its actual cap', () {
    expect(oculumAvailableDisplayMaximum(available: 7, naturalMaximum: 2), 7);
    expect(oculumAvailableDisplayMaximum(available: 2, naturalMaximum: 7), 7);
  });

  test('Only a natural Reflexes 20 can earn an Oculum dodge, at 25%', () {
    expect(
      oculumReflexCriticalAwardsDodge(
        subtraitId: 'riflessi',
        naturalRoll: 20,
        percentileRoll: 0,
      ),
      isTrue,
    );
    expect(
      oculumReflexCriticalAwardsDodge(
        subtraitId: 'riflessi',
        naturalRoll: 20,
        percentileRoll: 24,
      ),
      isTrue,
    );
    expect(
      oculumReflexCriticalAwardsDodge(
        subtraitId: 'riflessi',
        naturalRoll: 20,
        percentileRoll: 25,
      ),
      isFalse,
    );
    expect(
      oculumReflexCriticalAwardsDodge(
        subtraitId: 'forza',
        naturalRoll: 20,
        percentileRoll: 0,
      ),
      isFalse,
    );
    expect(
      oculumReflexCriticalAwardsDodge(
        subtraitId: 'riflessi',
        naturalRoll: 19,
        percentileRoll: 0,
      ),
      isFalse,
    );
  });

  test('Legacy turn unit aliases use the same personal duration', () {
    for (final unit in ['turn', 'turns', 'turno', 'turni', 'TURN']) {
      expect(oculumTurnUnit(unit), 'turni');
    }
    expect(oculumTurnUnit('tiri'), 'tiri');
  });
  testWidgets(
    'Per-element saves, inventory integrity, VC, personal turns and timed force states',
    (tester) async {
      final previousTargetPlatform = debugDefaultTargetPlatformOverride;
      addTearDown(() {
        debugDefaultTargetPlatformOverride = previousTargetPlatform;
      });
      SharedPreferences.setMockInitialValues({});
      final font = await rootBundle.load('assets/fonts/Poppins-Regular.ttf');
      for (final family in [
        'Poppins',
        'Roboto',
        'Georgia',
        'Segoe UI',
        'serif',
      ]) {
        await (FontLoader(family)..addFont(Future.value(font))).load();
      }
      final icons = File(
        'build/unit_test_assets/fonts/MaterialIcons-Regular.otf',
      );
      if (icons.existsSync()) {
        await (FontLoader('MaterialIcons')..addFont(
              Future.value(ByteData.sublistView(icons.readAsBytesSync())),
            ))
            .load();
      }

      final data = Directory(
        'build/current-integrity-${DateTime.now().microsecondsSinceEpoch}',
      )..createSync(recursive: true);
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (_) async => data.absolute.path,
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/connectivity'),
        (_) async => ['none'],
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/connectivity_status'),
        (_) async => null,
      );
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1440, 1100);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final capture = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          builder: (context, child) =>
              RepaintBoundary(key: capture, child: child!),
          home: const OculumHomePage(),
        ),
      );
      final dynamic state = tester.state(find.byType(OculumHomePage));
      state.tutorialDialogPending = true;
      await tester.pump(const Duration(seconds: 1));
      await tester.runAsync(() async {
        for (var i = 0; i < 100 && !state.datiCaricati; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
      });
      await tester.pump(const Duration(seconds: 1));
      final probe = OculumPerformanceProbe(state);
      state.updateOculumHomeUi(() {
        state.datiCaricati = true;
        state.tutorialCompletato = true;
        state.modalitaDesktop = true;
        state.activeGameMod = '';
        state.nuovoDesignOculum = 'cattedrale';
        state.statoForzaAttivo = '';
        state.inventario.clear();
        state.arti.clear();
        state.skills.clear();
      });
      final base = {
        ...probe.snapshot(),
        'nome': 'Hoshy',
        'resilienza': '20',
        'volonta': '30',
        'materia': '18',
        'oculum': '24',
        'currentResilienza': '20',
        'currentVolonta': '30',
        'currentMateria': '18',
        'currentOculum': '24',
        // Keep this elemental-damage fixture above the random awakening at 50%.
        'currentHp': '200',
        'livello': '6',
        'grado': '1',
        'vcRapido': '0',
        'incomingDamageElement': 'fuoco',
        'incomingDamagePresets': {
          'fuoco': 'Immunità',
          'ghiaccio': 'Alta Fragilità',
          'cenere_del_master': 'Rigenerazione',
        },
        'dannoSubitoPercentualePerTipo': {'fulmine': '+30%'},
        'assignableSubtraitPoints': 4,
        'inventario': [
          InventoryItem(
            nome: 'Zanna conservata',
            quantita: 7,
            peso: 1,
            note: 'Materiale',
          ).toJson(),
        ],
        'tutorialSubtraitAllocation': {
          'forza': 3,
          'riflessi': 3,
          'medicina': 3,
        },
      };
      probe.load(base);
      probe.load({...base, 'grado': '6', 'schivateOculumConsumate': -5});
      final normalizedDodges =
          probe.snapshot()['schivateOculumConsumate'] as int;
      expect(normalizedDodges, 0);
      expect(
        oculumAvailableDodgeCount(total: 2, consumed: normalizedDodges),
        2,
      );
      probe.load(base);
      probe.quickEditDodge(1);
      expect(probe.dodgeTotal(), 1);
      final savedDodge = probe.snapshot();
      expect(savedDodge['schivateOculumBonus'], 1);
      probe.load(savedDodge);
      expect(probe.dodgeTotal(), 1);
      probe.load(base);
      expect(probe.dodgeTotal(), 0);
      final inventory = probe.snapshot()['inventario'];
      final stats = probe.coreStats();
      final vc = probe.attackVc();
      final damage = probe.outgoingDamage();
      expect(
        probe.attackVc(),
        probe.levelGradeBonus() + (probe.coreStats()['volonta']! ~/ 3),
        reason: 'VC includes the level and grade bonus',
      );
      expect(
        probe.defenseCm(),
        probe.levelGradeBonus() + (probe.coreStats()['materia']! ~/ 2),
        reason: 'CM includes the level and grade bonus',
      );
      state.vcRapidoController.text = '11';
      state.updateOculumHomeUi(() {});
      expect(probe.attackVc(), vc + 11);
      expect(probe.outgoingDamage(), damage + 11);
      final saved = probe.snapshot();
      expect(saved['vcRapido'], '11');
      probe.load({
        ...probe.snapshot(),
        'nome': 'Elyra',
        'incomingDamagePresets': {},
        'assignableSubtraitPoints': 0,
      });
      expect(state.incomingDamagePresets, isEmpty);
      probe.load(saved);
      expect(probe.snapshot()['inventario'], inventory);
      expect(probe.coreStats(), stats);
      expect(state.incomingDamagePresets['fuoco'], 'Immunità');
      expect(
        state.incomingDamagePresets[oculumNormalizeElementId('ghiaccio')],
        'Alta Fragilità',
      );
      expect(
        state.incomingDamagePresets[oculumNormalizeElementId(
          'cenere_del_master',
        )],
        'Rigenerazione',
      );
      expect(state.assignableSubtraitPoints, 4);
      state.masterInitiativeTokens.clear();
      state.masterInitiativeGroups.clear();
      state.masterInitiativeActiveIndex = 0;
      state.masterInitiativeRound = 0;
      state.currentOculumController.text = '0';
      final hp = probe.currentHp();
      state.dannoOltreDifesa = true;
      state.dannoOltreScudi = true;
      // Test elemental damage independently of the random Luck dodge.
      final luck = (state.hiddenEyeStats as List<HiddenEyeStat>).firstWhere(
        (stat) => stat.id == 'fortuna',
      );
      final luckUnlocked = luck.unlocked;
      luck.unlocked = false;
      try {
        probe.damage(10);
        expect(probe.currentHp(), hp);
        state.incomingDamageElement = 'ghiaccio';
        probe.damage(10);
        expect(
          probe.currentHp(),
          lessThan(hp),
          reason:
              'Il danno da ghiaccio deve diminuire gli HP: stats=${probe.coreStats()}, stato=${state.statoForzaAttivo}, log=${state.risultato}',
        );
      } finally {
        luck.unlocked = luckUnlocked;
      }
      // The legacy armor effect used singular English "turn" and never expired.
      state.activeStructuredEffects.add({
        'source': 'Armatura del Combattente',
        'type': 'bonus',
        'target': 'danni',
        'value': 36,
        'remaining': 2,
        'unit': 'turn',
      });
      final tag = probe.ownerTag();
      state.masterInitiativeTokens.clear();
      state.masterInitiativeTokens.addAll([
        {
          'id': tag,
          'sheetTag': tag,
          'name': 'Hoshy',
          'status': 'active',
          'reportedTurn': 0,
          'hp': 100,
          'maxHp': 100,
        },
        {
          'id': 'other',
          'sheetTag': 'other',
          'name': 'Forest Demon',
          'status': 'ready',
          'reportedTurn': 0,
          'hp': 100,
          'maxHp': 100,
        },
      ]);
      state.masterInitiativeActiveIndex = 0;
      state.masterInitiativeRound = 0;
      probe.turn();
      expect(state.playerReportedTurn, 1);
      expect(
        state.activeStructuredEffects.singleWhere(
          (e) => e['source'] == 'Armatura del Combattente',
        )['remaining'],
        1,
      );
      probe.turn();
      expect(state.playerReportedTurn, 1);
      probe.turn();
      expect(state.playerReportedTurn, 2);
      expect(
        state.activeStructuredEffects.where(
          (e) => e['source'] == 'Armatura del Combattente',
        ),
        isEmpty,
      );
      probe.resetEncounter();
      expect(state.masterInitiativeRound, 0);
      expect(state.playerReportedTurn, 0);
      expect(
        state.masterInitiativeTokens.every(
          (token) => token['reportedTurn'] == 0,
        ),
        isTrue,
      );
      probe.removeParticipant(1);
      expect(state.masterInitiativeTokens.length, 1);
      expect(probe.snapshot()['inventario'], inventory);
      final before200 = probe.coreStats();
      probe.activateForce('duecento_percento');
      expect(
        probe.coreStats(),
        before200.map((key, value) => MapEntry(key, value * 2)),
      );
      probe.reportedTurn(1);
      probe.reportedTurn(2);
      expect(state.statoForzaAttivo, 'duecento_percento');
      probe.reportedTurn(3);
      expect(probe.coreStats(), before200);
      expect(state.statoForzaAttivo, '');
      state.currentHpController.text = '1';
      probe.activateForce('ricordo_vitale');
      final healed = probe.currentHp();
      expect(healed, greaterThan(1));
      expect(
        state.activeConditions.any((c) => c.conditionType == 'ricordo_vitale'),
        isTrue,
      );
      final current = state.playerReportedTurn as int;
      probe.reportedTurn(current + 8);
      expect(state.statoForzaAttivo, 'ricordo_vitale');
      probe.reportedTurn(current + 9);
      expect(state.statoForzaAttivo, '');
      expect(probe.currentHp(), greaterThanOrEqualTo(1));
      expect(probe.currentHp(), healed);
      // A buff expiring must not revive an already dead character.
      state.currentHpController.text = '0';
      probe.activateForce('duecento_percento');
      probe.endForce();
      expect(probe.currentHp(), 0);
      state.currentHpController.text = '1';
      probe.activateForce('duecento_percento');
      probe.endForce();
      expect(probe.currentHp(), 1);
      probe.loseResilienceBuff(999);
      expect(probe.currentHp(), 1);
      expect(probe.snapshot()['inventario'], inventory);
      probe.load(base);
      await tester.pump(const Duration(milliseconds: 600));
      Future<void> photo(String name) async {
        await tester.pump(const Duration(milliseconds: 600));
        expect(tester.takeException(), isNull);
        await tester.runAsync(() async {
          final boundary =
              capture.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 1);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final dir = Directory('output/ui/resistances-turns-20261003')
            ..createSync(recursive: true);
          File(
            '${dir.path}/$name.png',
          ).writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }

      state.updateOculumHomeUi(() => state.referenceOculumFlames = true);
      await photo('fiammelle-desktop');
      probe.openResistances();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      final ashCard = tester.widget<Container>(
        find.byKey(const ValueKey('resistance_element_cenere')),
      );
      final ashDecoration = ashCard.decoration! as BoxDecoration;
      expect(
        (ashDecoration.border! as Border).top.color,
        const Color(0xFF8D8A82).withValues(alpha: .82),
        reason: 'Cenere must use its own element color as its card border',
      );
      expect(probe.hpMultiplier(), 10);
      state.gradoController.text = '50';
      expect(
        probe.hpMultiplier(),
        10,
        reason: 'each Resilienza point provides exactly 10 maximum HP',
      );
      state.gradoController.text = '1';
      final beforeGrowth = probe.coreStats();
      final hpBeforeGrowth = probe.currentHp();
      for (final key in beforeGrowth.keys) {
        probe.increaseBaseStat(key, 2);
      }
      for (final key in beforeGrowth.keys) {
        expect(
          probe.coreStats()[key],
          beforeGrowth[key]! + 2,
          reason: '$key growth must be immediately usable',
        );
      }
      expect(
        probe.currentHp(),
        hpBeforeGrowth + 20,
        reason: '+2 Resilienza must also grant 20 current HP',
      );
      state.oculumController.text = '0';
      state.currentOculumController.text = '0';
      probe.invalidateDerivedCaches();
      // This fixture may still have Art or title bonuses: remove those
      // through its normal collections to exercise a truly zero total.
      state.arti.clear();
      state.titoli.clear();
      state.skills.clear();
      probe.invalidateDerivedCaches();
      final noOculumGrowth = probe.levelUpBonuses();
      expect(noOculumGrowth['Oculum'], 0);
      expect(
        noOculumGrowth.values.fold<int>(0, (a, b) => a + b),
        7,
        reason: 'excluding Oculum must preserve all seven level-up points',
      );
      await photo('resistenze-desktop');
      tester.view.physicalSize = const Size(390, 844);
      await photo('resistenze-mobile');
      tester.state<NavigatorState>(find.byType(Navigator).first).pop();
      await tester.pump(const Duration(milliseconds: 600));
      probe.openSubtraits();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      final help = find.byWidgetPredicate(
        (widget) =>
            widget is Tooltip &&
            widget.richMessage?.toPlainText().contains('A cosa serve') == true,
      );
      expect(help, findsWidgets);
      final helpWidget = tester.widget<Tooltip>(help.first);
      final helpDecoration = helpWidget.decoration! as BoxDecoration;
      expect(
        helpDecoration.gradient!.colors.every(
          (color) => color.computeLuminance() < .05,
        ),
        isTrue,
      );
      expect(helpDecoration.border, isNotNull);
      expect(helpWidget.textStyle!.color, const Color(0xffeadfc8));
      expect(helpWidget.richMessage!.toPlainText(), contains('A cosa serve'));
      expect(helpWidget.richMessage!.toPlainText(), isNot(contains('⌊')));
      expect(helpWidget.richMessage!.toPlainText(), isNot(contains('⌋')));
      expect(helpWidget.richMessage!.toPlainText(), contains('Formula'));
      tester.view.physicalSize = const Size(1440, 900);
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      final mouse = await tester.createGesture(
        kind: ui.PointerDeviceKind.mouse,
      );
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(help.first));
      await tester.pump(const Duration(milliseconds: 800));
      await photo('sottotratti-tooltip-desktop');
      expect(
        tester.widgetList<RichText>(find.byType(RichText)).any(
          (richText) => richText.text.toPlainText().contains('A cosa serve'),
        ),
        isTrue,
        reason: 'Desktop hover must open the themed subtrait explanation',
      );
      await mouse.removePointer();
      Tooltip.dismissAllToolTips();
      tester.view.physicalSize = const Size(390, 844);
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.ensureVisible(help.first);
      await tester.pump(const Duration(milliseconds: 600));
      await tester.longPress(help.first);
      await photo('sottotratti-tooltip-mobile');
      Tooltip.dismissAllToolTips();
      await photo('sottotratti-mobile');
      tester.state<NavigatorState>(find.byType(Navigator).first).pop();
      await tester.pump(const Duration(milliseconds: 600));
      tester.view.physicalSize = const Size(1440, 1100);
      final diceNavigator = tester.state<NavigatorState>(
        find.byType(Navigator).first,
      );
      unawaited(
        diceNavigator.push<void>(
          MaterialPageRoute<void>(
            builder: (_) => Scaffold(body: probe.dicePanel()),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));
      await photo('dadi-desktop');
      for (final die in ['d15', 'd25', 'd200', 'd250']) {
        expect(
          find.byWidgetPredicate(
            (widget) => widget is D20Widget && widget.text == die,
          ),
          findsOneWidget,
          reason: '$die must be rendered in the quick dice panel',
        );
      }
      final diceLabels = find
          .byType(D20Widget)
          .evaluate()
          .map((element) => (element.widget as D20Widget).text)
          .toList();
      for (final pair in [
        ('d14', 'd15'),
        ('d15', 'd16'),
        ('d24', 'd25'),
        ('d25', 'd26'),
        ('d120', 'd200'),
        ('d200', 'd250'),
      ]) {
        expect(
          diceLabels.indexOf(pair.$1),
          lessThan(diceLabels.indexOf(pair.$2)),
          reason: '${pair.$1} must appear before ${pair.$2} in dice order',
        );
      }
      // This is a new encounter, independent of the earlier turn/removal checks.
      state.masterInitiativeTokens.clear();
      state.masterInitiativeGroups.clear();
      state.masterInitiativeTokens.add({
        'id': 'manual_test',
        'name': 'Hoshy',
        'status': 'ready',
        'side': 'ally',
        'currentHp': 10,
        'maxHp': 10,
      });
      probe.setTurn(round: 7, activeIndex: 0);
      expect(probe.masterRound(), 7);
      expect(state.masterInitiativeTokens, hasLength(1));
      expect(state.masterInitiativeTokens.single['status'], 'active');
      probe.cancelPendingSave();
      await tester.pumpWidget(const SizedBox());
    },
  );
}
