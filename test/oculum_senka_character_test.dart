import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  test(
    'Senka code imports one private-data-free sheet and preserves editable models',
    () {
      final folder = Directory('output/characters/senka_kamaria');
      final sheet = oculumDecodeSheetShareText(
        File('${folder.path}/Senka_Kamaria.codice.txt').readAsStringSync(),
      ).single;
      expect(
        sheet,
        jsonDecode(
          File('${folder.path}/Senka_Kamaria.json').readAsStringSync(),
        ),
      );
      expect(sheet['nome'], 'Senka Kamaria');
      expect(sheet['livello'], '1');
      expect(sheet['grado'], '0');
      expect(sheet['razza'], 'Mhunan');
      for (final key in [
        'id',
        'sheetTag',
        'realtimeOwnerTag',
        'realtimeCampaignId',
      ]) {
        expect(sheet.containsKey(key), isFalse);
      }
      final art = CharacterArt.fromJson(
        Map<String, dynamic>.from((sheet['arti'] as List).single),
      );
      expect(art.skills, hasLength(3));
      expect(art.skills.map((s) => s.livello), [1, 1, 0]);
      expect(art.skills.first.oculumMinimoPerLivello(1), 3);
      expect(art.skills.last.unlockRequirementsPerLevel.first['level'], 3);
      final restored = CharacterArt.fromJson(art.toJson());
      expect(restored.toJson(), art.toJson());
      final mask = (sheet['inventario'] as List)
          .map((t) => InventoryItem.fromJson(Map<String, dynamic>.from(t)))
          .firstWhere((t) => t.craftData['senkaMask'] == true);
      expect(mask.buff, '@res+6; @vol+5; @mat+10; @ocu+5');
      expect(mask.equipaggiata, isFalse);
      expect(mask.note, contains('VELO'));
      expect(mask.note, contains('ceil(3 × tiro / 4)'));
      expect(mask.note, contains('RICARICANO'));
      expect(
        [mask.bonusDanno, mask.bonusDifesa, mask.bonusScudoOculum],
        [6, 3, 20],
      );
      final abilities = (sheet['skills'] as List)
          .map((t) => CharacterSkill.fromJson(Map<String, dynamic>.from(t)))
          .toList();
      final attack = abilities.firstWhere((s) => s.nome == 'Mille Tagli');
      expect(attack.forme.single.costoStrutturato!.resource, 'materia');
      expect(attack.forme.single.cooldownStrutturato!.unit, 'riposi_lunghi');
      expect(attack.descrizione, contains('SENKA riceve Sfinimento'));
      expect(attack.descrizione, contains('UNICO danno'));
      expect(attack.equipaggiata, isFalse);
      expect(
        CharacterSkill.fromJson(attack.toJson()).toJson(),
        attack.toJson(),
      );
      expect(oculumCharacterSkillFormCost(attack.forme.single)!.minimum, 1);
      final clone = abilities.firstWhere(
        (s) => s.nome == 'Clone d’ombra di Senka',
      );
      final cost = oculumCharacterSkillFormCost(clone.forme.single)!;
      expect([cost.resource, cost.minimum, cost.maximum], ['materia', 1, 10]);
      expect(clone.descrizione, contains('0 Azioni e 1 Reazione normale'));
    },
  );
}
