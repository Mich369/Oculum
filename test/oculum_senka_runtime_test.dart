import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'oculum_escape_provoker_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

void main() {
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
        }),
      );
      final turn = p.combatTurnResources();
      expect(p.manifestSenkaMask(item, true), true);
      expect(p.coreStats()['resilienza'], before['resilienza']! + 6);
      expect(p.coreStats()['materia'], before['materia']! + 10);
      expect(p.currentHp(), hp + 60);
      expect(p.coreStats()['oculum'], oculum + 5);
      expect(p.combatTurnResources(), turn);
      final shield = state.scudoController.text;
      p.spendArtResource('oculum', 5);
      state.currentHpController.text = '${p.currentHp() - 30}';
      expect(p.manifestSenkaMask(item, false), true);
      expect(p.coreStats()['oculum'], oculum);
      expect(p.currentHp(), hp);
      p.manifestSenkaMask(item, true);
      expect(p.currentHp(), hp + 60);
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
