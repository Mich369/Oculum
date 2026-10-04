import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oculum/main.dart';

void main() {
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
      state.obserController.text = '100';
      state.ascensionDustController.text = '0';
    });
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    final activeMerchantName = state.merchantProfiles.firstWhere(
      (profile) => profile['id'] == secondMerchantId,
    )['name'];
    await tester.tap(find.text(activeMerchantName as String));
    await tester.pumpAndSettle();
    final buy = find.widgetWithText(
      OutlinedButton,
      '20 Obser → 1 Ascension Dust · 1 per Riposo Lungo',
    );
    final callback = tester.widget<OutlinedButton>(buy).onPressed!;
    callback();
    callback(); // A queued second click must also be rejected by the transaction.
    await tester.pump();
    expect(state.obserController.text, '80');
    expect(state.ascensionDustController.text, '1');
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
    expect(state.obserController.text, '60');
    expect(state.ascensionDustController.text, '2');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
  });
}
