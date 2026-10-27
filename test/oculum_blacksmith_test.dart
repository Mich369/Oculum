import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

InventoryItem weapon({int quantity = 1}) => InventoryItem(nome: 'Spada', peso: 1, quantita: quantity, note: 'Mia storia', arma: true, bonusDanno: 10, ability: CharacterSkill(nome:'Tecnica originale', costo:'', cooldown:'', tipo:'Attacco', descrizione:'', forme:[CharacterSkillForm(livello:'0', effettiStrutturati:[OculumStructuredEffect(type:'danno',valueExpression:'10',mode:'prossima_azione')])]));
InventoryItem quartz({String name = 'Quarzo risonante', double kg = .5}) => InventoryItem(nome: name, peso: kg, quantita: 1, note: '', livelloOggetto: 12, craftData: {'material':'quarzo_risonante','materialLevel':12});

void main() {
  test('material defaults put sixty percent at level zero through six and fewer in higher bands', () {
    final levels = oculumDefaultMaterialLevels();
    final bands = [for (final (a,b) in [(0,6),(7,12),(13,20),(21,30),(31,100)]) levels.values.where((v) => v >= a && v <= b).length];
    expect(bands.first, (levels.length * .6).ceil());
    for (var i = 1; i < bands.length; i++) expect(bands[i], lessThan(bands[i-1]));
    File('build/material-level-audit.json').writeAsStringSync(jsonEncode({'count': levels.length, 'bands': bands, 'levels': levels}));
  });
  test('combine consumes exact aliased material, splits once, preserves and boosts old powers and gates new ones', () {
    final item = weapon(quantity: 2);
    final material = quartz(name:'Il mio quarzo');
    final inventory = [item, material];
    expect(oculumBlacksmithDustCost(item),1);
    final result = oculumCombineEquipment(inventory,item,[material],receipt:'one',ownerPower:50)!;
    expect(item.quantita,1);
    expect(material.peso,closeTo(.45,.000001));
    expect(result.peso,closeTo(1.05,.000001));
    expect(result.livelloOggetto,12);
    expect(result.note,contains('Mia storia'));
    expect(result.ability!.nome,'Tecnica originale');
    expect(result.ability!.forme.first.unlockRequirements['equipmentItemLevel'],0);
    expect(oculumEquipmentSkillItemLevel(result,result.ability!.forme.first),0);
    expect(result.ability!.forme.first.effettiStrutturati.first.valueExpression,contains('100+8'));
    expect(result.materialAbilities.first.forme.first.livello,'12');
    expect(result.materialAbilities.first.forme.any((f)=>f.tipo=='Passiva'),isTrue);
    expect(oculumBlacksmithDustCost(result),2);
    expect(oculumBlacksmithDustCost(item),1);
    expect(oculumCombineEquipment(inventory,item,[material],receipt:'one',ownerPower:50),isNull);
    expect(material.peso,closeTo(.45,.000001));
    final saved = InventoryItem.fromJson(jsonDecode(jsonEncode(result.toJson())) as Map<String,dynamic>);
    expect(saved.toJson(),result.toJson());
  });
  test('missing material cannot mutate equipment, depleted source and duplicated entries do not pass', () {
    for (final kg in [0.001,.049]) {
      final item=weapon(), material=quartz(kg:kg);
      final inventory=[item,material];
      final before=jsonEncode(inventory.map((i)=>i.toJson()).toList());
      expect(oculumCombineEquipment(inventory,item,[material],receipt:'x',ownerPower:10),isNull);
      expect(jsonEncode(inventory.map((i)=>i.toJson()).toList()),before);
    }
    final item=weapon(), material=quartz();
    expect(oculumCombineEquipment([item,material],item,[material,material],receipt:'dupe',ownerPower:10),isNull);
  });
  test('evolved title reforges without deleting original Open, hides all until harder quest and keeps separate uses', () {
    final item=weapon(), material=quartz();
    oculumInitializeItemTitle(item);
    item.craftData['titleEvolution']['progress']=5;
    oculumApplyItemTitleEvolutionUpgrade(item);
    final old=jsonEncode(item.titleAbility!.toJson());
    final preview=oculumBlacksmithPreview(item,[material]);
    expect(preview.percent,40);
    final forged=oculumCombineEquipment([item,material],item,[material],receipt:'reforge',ownerPower:50)!;
    expect(forged.titleExtraAbilities,hasLength(1));
    expect(forged.titleAbility!.nome,item.titleAbility!.nome);
    expect(oculumItemTitleEvolutionReady(forged),isFalse);
    expect(oculumItemTitleEvolution(forged)['requiredKills'],7);
    expect(oculumItemTitleAbilities(forged),hasLength(2));
    expect(oculumItemTitleEvolution(forged)['minimumPower'],50);
    expect(jsonEncode(item.titleAbility!.toJson()),old,reason:'The source is not changed through shared nested JSON');
    forged.craftData['titleEvolution']['progress']=7;
    oculumApplyItemTitleEvolutionUpgrade(forged);
    expect(oculumItemTitleEvolutionReady(forged),isTrue);
    final saved=InventoryItem.fromJson(jsonDecode(jsonEncode(forged.toJson())) as Map<String,dynamic>);
    expect(saved.titleExtraAbilities,hasLength(1));
    expect(saved.materialAbilities,hasLength(1));
    final priced = weapon();
    for (var n=0;n<20;n++) { priced.craftData={'blacksmithForgeCount':n}; expect(oculumBlacksmithDustCost(priced), (n+1).clamp(1,12)); }
  });
}
