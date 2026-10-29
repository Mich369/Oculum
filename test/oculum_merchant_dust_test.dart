import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oculum/main.dart';

void main() {
  test('merchant offer counts and selection stay varied but focused', () {
    final countRandom = Random(20261022);
    var twelveOfferShops = 0;
    for (var index = 0; index < 20000; index++) {
      final count = oculumMerchantOfferCount(countRandom);
      expect(count == 12 || (count >= 6 && count <= 9), isTrue);
      if (count == 12) twelveOfferShops++;
    }
    expect(twelveOfferShops / 20000, closeTo(.16, .01));

    final offers = <Map<String, dynamic>>[
      for (var index = 0; index < 3; index++)
        {'id': 'near_$index', 'kind': 'gear', 'level': 8 + index, 'cost': 500},
      {'id': 'far', 'kind': 'gear', 'level': 18, 'cost': 500},
    ];
    var nearLevelPicks = 0;
    final levelRandom = Random(281);
    for (var index = 0; index < 3000; index++) {
      final selected = oculumSelectMerchantOffers(
        offers,
        characterLevel: 9,
        budget: 1000,
        count: 1,
        random: levelRandom,
      ).single;
      if ('${selected['id']}' != 'far') nearLevelPicks++;
    }
    expect(nearLevelPicks / 3000, greaterThan(.85));

    final budgetOffers = [
      {'id': 'affordable', 'kind': 'food', 'cost': 100},
      {'id': 'costly', 'kind': 'food', 'cost': 1000},
    ];
    var affordablePicks = 0;
    final budgetRandom = Random(877);
    for (var index = 0; index < 3000; index++) {
      if (oculumSelectMerchantOffers(
            budgetOffers,
            characterLevel: 4,
            budget: 500,
            count: 1,
            random: budgetRandom,
          ).single['id'] ==
          'affordable') {
        affordablePicks++;
      }
    }
    expect(affordablePicks / 3000, inInclusiveRange(.53, .59));
  });

  test('merchant selection hides duplicate versions of the same effect', () {
    final offers = <Map<String, dynamic>>[
      {
        'id': 'meal_low',
        'kind': 'food',
        'condition': 'vampirismo',
        'conditionStage': 1,
      },
      {
        'id': 'meal_high',
        'kind': 'food',
        'condition': 'vampirismo',
        'conditionStage': 3,
      },
      {'id': 'damage_20', 'kind': 'food', 'damagePercent': 20},
      {'id': 'damage_30', 'kind': 'food', 'damagePercent': 30},
      {'id': 'defense_condition', 'kind': 'food', 'condition': 'fortificato'},
      {'id': 'defense_percent', 'kind': 'food', 'defensePercent': 20},
      {
        'id': 'monster_skill',
        'kind': 'black_market_monster_skill',
        'canonicalSkillName': 'Soffio Acido',
      },
      {
        'id': 'regular_skill',
        'kind': 'black_market_skill',
        'canonicalSkillName': 'Soffio Acido',
      },
      {'id': 'collector_0', 'kind': 'gathering_collector', 'grade': 0},
      {'id': 'collector_1', 'kind': 'gathering_collector', 'grade': 1},
      {'id': 'transparency', 'kind': 'food', 'condition': 'trasparenza'},
    ];

    final unique = oculumMerchantUniqueOffers(offers);
    expect(unique.map((offer) => offer['id']), [
      'meal_low',
      'damage_20',
      'defense_condition',
      'monster_skill',
      'collector_0',
      'transparency',
    ]);
  });

  test('food and drink combat effects persist for the authored turn count', () {
    final effects = oculumMerchantTimedFoodEffects({
      'damagePercent': 30,
      'defensePercent': 20,
      'conditionTurns': 3,
    }, source: 'Cibo e Bevanda · Prova');
    expect(effects, hasLength(2));
    expect(effects.map((effect) => effect['value']), [30, 20]);
    expect(effects.map((effect) => effect['remaining']), [3, 3]);
    expect(effects.map((effect) => effect['unit']), everyElement('turni'));
    expect(effects.map((effect) => effect['target']), [
      'danni_percentuale',
      'difesa_percentuale',
    ]);
  });

  test(
    'nurse Refull rolls buff, rare jackpot, duration and recovery price',
    () {
      expect(
        oculumNurseBuffPercentFromRoll(percentileRoll: 0, selectionRoll: 0),
        40,
      );
      expect(
        oculumNurseBuffPercentFromRoll(percentileRoll: 0, selectionRoll: 1),
        60,
      );
      expect(
        oculumNurseBuffPercentFromRoll(percentileRoll: 1, selectionRoll: 3),
        25,
      );
      expect(oculumNurseBuffSurcharge(10), 2);
      expect(oculumNurseBuffSurcharge(60), 12);
      expect(oculumNurseBuffDuration('facile'), 9);
      expect(oculumNurseBuffDuration('medio'), 6);
      expect(oculumNurseBuffDuration('difficile'), 3);
      expect(oculumNurseBuffDuration('oculum'), 1);
      expect(oculumNurseRareTempHpGift(percentileRoll: 0, level: 4), 20);
      expect(oculumNurseRareTempHpGift(percentileRoll: 1, level: 4), 0);
      expect(
        oculumNurseTempHpGiftFromRoll(
          percentileRoll: 0,
          level: 4,
          maximumTemporaryHp: 7,
        ),
        20,
      );
      expect(
        oculumNurseTempHpGiftFromRoll(
          percentileRoll: 1,
          level: 4,
          maximumTemporaryHp: 7,
        ),
        4,
      );
      expect(
        oculumNurseTempHpGiftFromRoll(
          percentileRoll: 3,
          level: 4,
          maximumTemporaryHp: 7,
        ),
        3,
      );
      expect(
        oculumNurseTempHpGiftFromRoll(
          percentileRoll: 8,
          level: 4,
          maximumTemporaryHp: 7,
        ),
        0,
      );
      expect(oculumNurseRareBuffBonusShield(101), 25);
      expect(
        oculumNurseFullRestorationCost(
          missingHp: 11,
          missingOculumShield: 3,
          missingStatPoints: 2,
          missingArtIntegrity: 11,
          negativeConditions: 1,
          buffPercent: 20,
        ),
        18,
      );
      expect(oculumDamageWithPercentage(100, 20), 120);
    },
  );

  test(
    'black market prices, level-zero eligibility and duplicate identity',
    () {
      expect(
        [0, 1, 2].map(
          (purchases) => oculumBlackMarketDustPrice(
            basePrice: 40,
            previousPurchases: purchases,
          ),
        ),
        [40, 50, 60],
      );
      expect(
        oculumBlackMarketDustPrice(basePrice: 50, previousPurchases: 2),
        69,
      );
      expect(
        oculumBlackMarketFallenEyePrice(
          totalStats: 18,
          ownerTotalStats: 18,
          level: 10,
        ),
        151,
      );
      expect(
        oculumBlackMarketFallenEyeBasePrice(level: 0, levelZeroBase: 36),
        36,
      );
      expect(
        oculumBlackMarketFallenEyeBasePrice(level: 0, levelZeroBase: 69),
        69,
      );
      expect(
        oculumBlackMarketFallenEyeBasePrice(level: 10, levelZeroBase: 36),
        115,
      );
      expect(
        oculumBlackMarketFallenEyeBasePrice(level: 10, levelZeroBase: 69),
        115,
      );
      expect(
        oculumBlackMarketFallenEyeBasePrice(level: 20, levelZeroBase: 50),
        180,
      );
      expect(
        oculumBlackMarketFallenEyePrice(
          totalStats: 37,
          ownerTotalStats: 18,
          level: 10,
        ),
        189,
      );
      expect(
        oculumBlackMarketFallenEyePrice(
          totalStats: 38,
          ownerTotalStats: 18,
          level: 10,
        ),
        238,
      );
      expect(
        oculumBlackMarketFallenEyePrice(
          totalStats: 58,
          ownerTotalStats: 18,
          level: 10,
        ),
        346,
      );
      final firstSkill = <String, dynamic>{
        'kind': 'black_market_monster_skill',
        'sourceSkillId': 'frost_bite_variante_ghiaccio',
        'canonicalSkillName': 'Soffio Acido',
        'damagePercent': 20,
      };
      final secondSkill = <String, dynamic>{
        ...firstSkill,
        'sourceSkillId': 'acid_breath_elite',
        'damagePercent': 40,
        'cost': 999999,
      };
      expect(
        oculumMerchantCanonicalOfferKey(firstSkill),
        oculumMerchantCanonicalOfferKey(secondSkill),
      );
      expect(
        oculumMerchantCanonicalOfferKey({
          'kind': 'nurse_service',
          'service': 'full',
          'buffPercent': 20,
        }),
        oculumMerchantCanonicalOfferKey({
          'kind': 'nurse_service',
          'service': 'full',
          'buffPercent': 40,
        }),
      );
    },
  );

  test('stat gems scale only with their own stat and are occasional', () {
    expect(oculumStatGemDieFaces(9), 3);
    expect(oculumStatGemDieFaces(90), 30);
    expect(oculumStatGemDieFaces(0), 1);
    expect(oculumStatGemPrice(10) - oculumStatGemPrice(9), 3);
    expect(oculumStatGemPrice(90) - oculumStatGemPrice(0), 27);
    final random = Random(42);
    final appearances = List.generate(
      100,
      (_) => oculumStatGemAvailable(random),
    );
    expect(appearances.every((v) => v), isFalse);
  });

  test('alchemy Fallen Eye offers follow level and price bands', () {
    expect(oculumAlchemyMediumFallenEyeLevel(0), 0);
    expect(oculumAlchemyMediumFallenEyeLevel(1), 0);
    expect(oculumAlchemyMediumFallenEyeLevel(2), 1);
    expect(oculumAlchemyMediumFallenEyeLevel(3), 2);
    expect(oculumAlchemyMediumFallenEyeLevel(10), 6);
    expect(oculumAlchemyRareFallenEyeLevel(1), 1);
    expect(oculumAlchemyRareFallenEyeLevel(10), 5);
    expect(
      oculumAlchemyMediumFallenEyePrice(
        ownerLevel: 10,
        ownerGrade: 2,
        priceRoll: 0,
      ),
      72,
    );
    expect(
      oculumAlchemyMediumFallenEyePrice(
        ownerLevel: 10,
        ownerGrade: 2,
        priceRoll: 33,
      ),
      105,
    );
    expect(
      oculumAlchemyRareFallenEyePrice(
        ownerLevel: 11,
        ownerGrade: 2,
        priceRoll: 0,
      ),
      243,
    );
    expect(
      oculumAlchemyRareFallenEyePrice(
        ownerLevel: 11,
        ownerGrade: 2,
        priceRoll: 220,
      ),
      463,
    );
  });
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Merchant Dust purchase is limited until Long Rest', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final regular = await rootBundle.load('assets/fonts/Poppins-Regular.ttf');
    for (final family in [
      'Poppins',
      'Roboto',
      'serif',
      'Segoe UI',
      'Garamond',
      'Georgia',
    ]) {
      await (FontLoader(family)..addFont(Future.value(regular))).load();
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
    final directory = Directory('build/layout-test-data')
      ..createSync(recursive: true);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => directory.absolute.path,
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
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final capture = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: RepaintBoundary(key: capture, child: const OculumHomePage()),
      ),
    );
    await tester.runAsync(
      () async => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
    await tester.pump(const Duration(seconds: 1));
    final dynamic state = tester.state(find.byType(OculumHomePage));
    final probe = OculumPerformanceProbe(state);
    state.updateOculumHomeUi(() {
      state.merchantProfiles.clear();
      state.merchantStock.clear();
      state.merchantStockSessionId = '';
      state.merchantActiveProfileId = 'merchant_default';
    });
    final firstMerchantId = state.merchantActiveProfileId as String;
    final firstMerchantStock = probe.merchantOfferIds();
    probe.createMerchantProfile();
    final secondMerchantId = state.merchantActiveProfileId as String;
    expect(secondMerchantId, isNot(firstMerchantId));
    expect(state.merchantProfiles.length, 2);
    probe.switchMerchantProfile(firstMerchantId);
    expect(state.merchantActiveProfileId, firstMerchantId);
    expect(probe.merchantOfferIds(), firstMerchantStock);
    probe.switchMerchantProfile(secondMerchantId);
    probe.shopType('chef');
    final chefOffers = probe.shopOffers();
    expect(
      chefOffers.length == 12 ||
          (chefOffers.length >= 6 && chefOffers.length <= 9),
      isTrue,
    );
    expect(chefOffers.every((offer) => offer['kind'] == 'food'), isTrue);
    expect(
      chefOffers.map(oculumMerchantOfferFamilyKey).toSet(),
      hasLength(chefOffers.length),
    );
    expect(
      state.merchantStock.where((offer) => offer['kind'] == 'food').length,
      greaterThanOrEqualTo(45),
    );
    final hunterFoodOffer = state.merchantStock.singleWhere(
      (offer) => offer['id'] == 'meal_hunters_fervor',
    );
    final hunterFood = probe.merchantItem(hunterFoodOffer);
    state.inventario.add(hunterFood);
    await probe.useMerchantItem(hunterFood);
    expect(
      probe.structuredEffects().singleWhere(
        (effect) => effect['target'] == 'danni_percentuale',
      ),
      containsPair('value', 30),
    );
    expect(
      probe.structuredEffects().singleWhere(
        (effect) => effect['target'] == 'danni_percentuale',
      )['remaining'],
      3,
    );
    final veilFood = probe.merchantItem({
      'kind': 'food',
      'id': 'test_veil_drink',
      'name': 'Bevanda di Prova',
      'condition': 'trasparenza',
      'conditionTurns': 3,
      'desc': 'Trasparenza per tre turni.',
    });
    state.inventario.add(veilFood);
    await probe.useMerchantItem(veilFood);
    final transparency = probe.conditions.singleWhere(
      (condition) => condition.conditionType == 'trasparenza',
    );
    expect(transparency.duration, 3);
    expect(transparency.durationType, OculumConditionDurationType.turns);
    state.volontaController.text = '10';
    state.materiaController.text = '7';
    state.volontaController.text = '9';
    state.currentVolontaController.text = '9';
    final gem = InventoryItem.fromJson(
      probe.merchantItem({
        'kind': 'stat_gem',
        'stat': 'volonta',
        'dieFaces': 3,
      }).toJson(),
    );
    expect(gem.statGemDieFaces, 3);
    state.inventario.add(gem);
    await probe.useMerchantItem(gem);
    final afterGem = int.parse(state.currentVolontaController.text);
    expect(afterGem, inInclusiveRange(10, 12));
    expect(state.inventario.contains(gem), isFalse);
    await probe.useMerchantItem(gem);
    expect(int.parse(state.currentVolontaController.text), afterGem);
    expect(state.volontaController.text, '9');
    final gemSave = probe.snapshot();
    probe.load(gemSave);
    expect(int.parse(state.currentVolontaController.text), afterGem);
    probe.recoverLongRestStats();
    expect(int.parse(state.currentVolontaController.text), 9);
    final pollen = probe.merchantItem({
      'kind': 'food',
      'name': 'Polline dei Riflessi',
      'isMaterial': true,
      'subtraitId': 'riflessi',
      'subtraitBonus': 2,
      'desc': 'Materiale da crafting e consumabile.',
    });
    expect(pollen.monsterLoot['material'], isTrue);
    state.inventario.add(pollen);
    await probe.useMerchantItem(pollen);
    expect(
      state.merchantHerbalEffects
          .where((effect) => effect['type'] == 'subtrait_bonus')
          .map((effect) => effect['value']),
      contains(2),
    );
    expect(state.inventario.contains(pollen), isFalse);
    probe.shortRest();
    expect(
      state.merchantHerbalEffects
          .where((effect) => effect['type'] == 'subtrait_bonus')
          .single['shortRestsRemaining'],
      1,
    );
    probe.shortRest();
    expect(
      state.merchantHerbalEffects.where(
        (effect) => effect['type'] == 'subtrait_bonus',
      ),
      isEmpty,
    );
    expect(
      state.recipes.any((recipe) => recipe.id == 'core_herbal_millefoglie'),
      isTrue,
      reason: 'Herb and ointment crafting recipes are seeded for the sheet',
    );
    for (final key in ['resilienza', 'materia', 'oculum']) {
      final maximum = probe.resourceMaximum(key);
      probe.setResourceCurrent(key, maximum);
      final resourceGem = probe.merchantItem({
        'kind': 'stat_gem',
        'stat': key,
        'dieFaces': 1,
      });
      state.inventario.add(resourceGem);
      await probe.useMerchantItem(resourceGem);
      expect(probe.resourceCurrent(key), maximum + 1);
      probe.load(probe.snapshot());
      expect(probe.resourceCurrent(key), maximum + 1);
      probe.recoverShortRestStats();
      expect(probe.resourceCurrent(key), maximum + 1);
      if (key == 'oculum') {
        probe.recoverOculum(1);
        expect(probe.resourceCurrent(key), greaterThanOrEqualTo(maximum + 1));
      }
      probe.recoverLongRestStats();
      // Other temporary Oculum bonuses retain their existing expiry rules.
      expect(probe.snapshot()['statGemOverflow'], isEmpty);
      if (key != 'oculum') expect(probe.resourceCurrent(key), maximum);
    }
    state.volontaController.text = '10';
    final weapon = probe.merchantItem({'kind': 'gear', 'weapon': true});
    expect(weapon.bonusDanno, 11);
    final shield = probe.merchantItem({
      'kind': 'gear',
      'weapon': true,
      'protection': true,
      'damage': 2,
      'shield': 40,
      'grade': 3,
    });
    expect(shield.arma && shield.protegge, isTrue);
    expect(shield.bonusDanno, 2);
    expect(shield.bonusDifesa, 19);
    final restored = InventoryItem.fromJson(shield.toJson());
    expect(probe.shieldBonus(restored), 40);
    final titleShield = probe.merchantItem({
      'kind': 'title_item',
      'damage': 11,
    }, titleType: 'scudo_offensivo');
    expect(titleShield.bonusDanno, 2);
    expect(titleShield.nome, 'Item Titolo — scudo offensivo');
    expect(oculumMerchantShieldValue(100, 35), 35);
    expect(oculumMerchantShieldValue(100, 50), 50);
    state.updateOculumHomeUi(() {
      state.activeGameMod = '';
      state.modalitaDesktop = true;
      state.tutorialCompletato = true;
      state.datiCaricati = true;
      state.paginaCorrente = 6;
      state.obserController.text = '1000';
      state.ascensionDustController.text = '0';
    });
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    final activeMerchantName = state.merchantProfiles.firstWhere(
      (profile) => profile['id'] == secondMerchantId,
    )['name'];
    // Inventory services are deliberately built only after opening this panel.
    final services = find.text('Mercato, party e guardiani');
    final inventoryScroll = find
        .descendant(
          of: find.byType(CustomScrollView).last,
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(services, 300, scrollable: inventoryScroll);
    await tester.tap(services);
    await tester.pump(const Duration(milliseconds: 350));
    final merchantHeader = find
        .ancestor(
          of: find.text(activeMerchantName as String),
          matching: find.byType(ListTile),
        )
        .first;
    await tester.ensureVisible(merchantHeader);
    // The scroll jump needs a layout frame before the nested header is hit-tested.
    await tester.pumpAndSettle();
    await tester.tap(merchantHeader);
    await tester.pumpAndSettle();
    expect(state.merchantIsOpen, isTrue);
    probe.shopType('alchimista');
    await tester.pumpAndSettle();
    final dustPrice = probe.dustPrice;
    final buy = find.widgetWithText(
      OutlinedButton,
      '$dustPrice Obser → 1 Ascension Dust · 0/3 per Riposo Lungo',
    );
    final callback = tester.widget<OutlinedButton>(buy).onPressed!;
    final dustCosts = <int>[];
    for (var i = 0; i < 3; i++) {
      dustCosts.add(probe.dustPrice);
      callback();
    }
    callback(); // A stale fourth click must be rejected by the transaction.
    await tester.pump();
    final dustTotal = dustCosts.fold<int>(0, (sum, price) => sum + price);
    expect(state.obserController.text, '${1000 - dustTotal}');
    expect(state.ascensionDustController.text, '3');
    expect(state.merchantDustPurchasedSinceLongRest, isTrue);
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(
              OutlinedButton,
              'Dust acquistata · disponibile dopo il Riposo Lungo',
            ),
          )
          .onPressed,
      isNull,
    );
    state.updateOculumHomeUi(() {
      state.paginaCorrente = 1;
    });
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    final shortRest = find.widgetWithText(ElevatedButton, 'Riposo Breve');
    tester.widget<ElevatedButton>(shortRest).onPressed!();
    expect(state.merchantDustPurchasedSinceLongRest, isTrue);
    final longRest = find.widgetWithText(
      ElevatedButton,
      'Riposo Lungo — 1 ora e mezza',
    );
    final dropGem = oculumCreateTemporaryDropGem(
      subtraitId: 'drop',
      naturalRoll: 19,
      usesOculum: false,
      stats: const {'resilienza': 9, 'volonta': 9, 'materia': 9},
      random: Random(42),
    )!;
    state.inventario.add(dropGem);
    tester.widget<ElevatedButton>(longRest).onPressed!();
    expect(
      state.inventario.contains(dropGem),
      isTrue,
      reason: 'Unused Drop gems remain in inventory after long rest',
    );
    expect(dropGem.quantita, 1);
    await probe.useMerchantItem(dropGem);
    expect(
      state.inventario.contains(dropGem),
      isFalse,
      reason: 'Drop gems are consumed only when used',
    );
    expect(state.merchantDustPurchasedSinceLongRest, isFalse);
    callback();
    expect(state.obserController.text, '${1000 - dustTotal - dustPrice}');
    expect(state.ascensionDustController.text, '4');

    state.livelloController.text = '0';
    state.gradoController.text = '0';
    probe.shopType('mercato_nero');
    final blackMarket = probe.shopOffers();
    expect(
      blackMarket.any(
        (offer) =>
            offer['kind'] == 'black_market_skill' &&
            readIntValue(offer['requiredLevel']) == 0,
      ),
      isTrue,
    );
    expect(
      blackMarket.any(
        (offer) =>
            offer['kind'] == 'technique_scroll' &&
            offer['blackMarketSelected'] == true &&
            readIntValue(offer['scrollGrade']) == 0,
      ),
      isTrue,
    );
    expect(
      blackMarket.any(
        (offer) => offer['kind'] == 'black_market_ascension_dust',
      ),
      isTrue,
    );
    final marketKeys = blackMarket
        .map(oculumMerchantCanonicalOfferKey)
        .whereType<String>()
        .toList();
    expect(marketKeys.toSet(), hasLength(marketKeys.length));
    probe.shopType('alchimista');
    state.obserController.text = '1000';
    final alchemistOffers = probe.shopOffers();
    expect(
      alchemistOffers.length == 12 ||
          (alchemistOffers.length >= 6 && alchemistOffers.length <= 9),
      isTrue,
    );
    final sign = alchemistOffers.singleWhere((o) => o['kind'] == 'fate_sign');
    final signCost = probe.shopCost(sign);
    await probe.buyShopOffer(sign);
    await probe.buyShopOffer(sign);
    expect(state.obserController.text, '${1000 - signCost}');
    expect(sign['remaining'], 0);
    expect(
      state.merchantStock.singleWhere(
        (o) => o['id'] == sign['id'],
      )['remaining'],
      0,
    );
    expect(probe.shopOffers().any((o) => o['id'] == sign['id']), isFalse);
    probe.load(probe.snapshot());
    expect(
      state.merchantStock.singleWhere(
        (o) => o['id'] == sign['id'],
      )['remaining'],
      0,
    );
    expect(probe.shopOffers().any((o) => o['id'] == sign['id']), isFalse);
    final chaos = probe.merchantItem(oculumChaosSignOffer('test-shop'));
    state.inventario.add(chaos);
    int totalStats() => [
      state.resilienzaController,
      state.volontaController,
      state.materiaController,
      state.oculumController,
    ].fold<int>(0, (sum, c) => sum + int.parse(c.text as String));
    final beforeChaos = totalStats();
    await probe.useMerchantItem(chaos);
    final afterChaos = totalStats();
    expect(
      afterChaos - beforeChaos,
      inInclusiveRange(
        0,
        ((chaos.craftData['chaosSign'] as Map)['cost'] as int) ~/ 10 * 3,
      ),
    );
    expect(state.inventario.contains(chaos), isFalse);
    await probe.useMerchantItem(chaos);
    expect(totalStats(), afterChaos);

    probe.shopType('infermiera_eroica');
    state.obserController.text = '100000';
    state.currentHpController.text = '1';
    for (final key in ['resilienza', 'volonta', 'materia', 'oculum']) {
      probe.setResourceCurrent(key, 0);
    }
    state.scudoOculumMaxController.text = '8';
    state.scudoOculumController.text = '1';
    state.scudoController.text = '7';
    final maxHpBeforeNurse = probe.maximumHp();
    final refill = probe.shopOffers().singleWhere(
      (offer) => offer['service'] == 'full',
    );
    refill['buffPercent'] = 20;
    refill['rareTempHpChancePercent'] = 0;
    final refillCost = probe.shopCost(refill);
    await probe.buyShopOffer(refill);
    expect(state.obserController.text, '${100000 - refillCost}');
    expect(probe.maximumHp(), greaterThanOrEqualTo(maxHpBeforeNurse));
    expect(state.currentHpController.text, '${probe.maximumHp()}');
    expect(state.scudoOculumController.text, '8');
    expect(state.scudoController.text, '27');
    for (final key in ['resilienza', 'volonta', 'materia', 'oculum']) {
      if (key == 'oculum') {
        expect(
          probe.snapshot()['normalCurrentOculum'],
          probe.resourceMaximum(key),
        );
        expect(
          probe.resourceCurrent(key),
          probe.resourceMaximum(key) + state.temporaryOculum,
        );
      } else {
        expect(
          probe.resourceCurrent(key),
          probe.resourceMaximum(key),
          reason: 'Nurse resource $key',
        );
      }
    }
    expect(state.heroicNursePendingBattleBuff['damagePercent'], 20);
    expect(state.heroicNursePendingBattleBuff['pending'], isTrue);

    final savedPendingBuff = probe.snapshot();
    probe.load(savedPendingBuff);
    expect(state.heroicNursePendingBattleBuff['damagePercent'], 20);

    refill['buffPercent'] = 40;
    await probe.buyShopOffer(refill);
    expect(state.scudoController.text, '${27 + 20 + probe.maximumHp() ~/ 4}');
    expect(state.heroicNursePendingBattleBuff['damagePercent'], 40);

    final nurseTestToken = <String, dynamic>{
      'id': 'nurse_refill_test_turn',
      'side': 'ally',
    };
    state.masterInitiativeTokens.add(nurseTestToken);
    expect(
      probe.activateNurseBuff(),
      isFalse,
      reason: 'Roleplay does not activate fight-only effects',
    );
    probe.ensureEncounters();
    final fightGroup = (state.masterInitiativeGroups as List)
        .cast<Map>()
        .firstWhere((g) => g['id'] == state.selectedMasterInitiativeGroupId);
    fightGroup['fightStarted'] = true;
    fightGroup['combatEnded'] = false;
    expect(probe.activateNurseBuff(), isTrue);
    expect(state.heroicNursePendingBattleBuff, isNull);
    final activatedEffects = probe
        .structuredEffects()
        .where((effect) => effect['source'] == 'Infermiera Eroica · Refull')
        .toList();
    expect(activatedEffects, hasLength(2));
    expect(activatedEffects.map((effect) => effect['value']), everyElement(40));
    expect(
      activatedEffects.map((effect) => effect['remaining']),
      everyElement(oculumNurseBuffDuration(probe.difficulty())),
    );
    state.masterInitiativeTokens.remove(nurseTestToken);

    state.currentHpController.text = '1';
    state.scudoController.text = '5';
    state.scudoOculumController.text = '1';
    for (final key in ['resilienza', 'volonta', 'materia', 'oculum']) {
      probe.setResourceCurrent(key, 0);
    }
    probe.refillStatsAndHealth();
    expect(state.currentHpController.text, '${probe.maximumHp()}');
    expect(state.scudoOculumController.text, '8');
    expect(state.scudoController.text, '5');
    for (final key in ['resilienza', 'volonta', 'materia', 'oculum']) {
      if (key == 'oculum') {
        expect(
          probe.snapshot()['normalCurrentOculum'],
          probe.resourceMaximum(key),
        );
        expect(
          probe.resourceCurrent(key),
          probe.resourceMaximum(key) + state.temporaryOculum,
        );
      } else {
        expect(probe.resourceCurrent(key), probe.resourceMaximum(key));
      }
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
  });
}
