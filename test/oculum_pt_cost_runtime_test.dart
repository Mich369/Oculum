import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'oculum_escape_provoker_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

void main() {
  testWidgets('PT uses actual totals, activates once and applies exhaustion', (tester) async {
    final (state,p)=await fixtures.mountFight(tester);
    state.inventario.add(InventoryItem(nome:'Buff permanente',peso:1,quantita:1,note:'',equipaggiata:true,buff:'@mat+6'));
    p.applyEffects([OculumStructuredEffect(type:'modifica_statistica',target:'volonta',valueExpression:'3',mode:'finche_attivo',duration:'2')]);
    final context=p.formulaContext();
    final power=p.totalPower(state.schedaCorrente as int);
    expect(context['potenza_totale'],power);
    final before=p.damageTotal();
    final messages=p.applyEffects([OculumStructuredEffect(type:'danno',valueExpression:'PT',mode:'prossima_azione')]);
    expect(messages.join(' '),contains('Sfinimento'));
    expect(p.damageTotal(),before+power);
    expect((p.snapshot()['planarRuntime'] as Map)['totalPowerExhaustionTurns'],greaterThanOrEqualTo(1));
    expect(p.consumeNextAttackEffects(),isTrue);
    expect(p.damageTotal(),before);
    await closeFixture(tester,p);
  });
  testWidgets('Materia word cost actually spends Matter and survives save/reload', (tester) async {
    final (state,p)=await fixtures.mountFight(tester);
    state.currentMateriaController.text='10';
    state.materiaController.text='10';
    final skill=CharacterSkill(nome:'Costo Materia reale',tipo:'Attiva',costo:'Materia 1',cooldown:'',descrizione:'',equipaggiata:true,
      forme:[CharacterSkillForm.fromJson({'nome':'I','tipo':'Attiva','livello':'0','costo':'Materia 1','effettiStrutturati':[OculumStructuredEffect(type:'scudo',valueExpression:'5',mode:'immediato').toJson()]})]);
    state.skills.add(skill);
    final beforeMatter=p.resourceCurrent('materia');
    final beforeOculum=p.resourceCurrent('oculum');
    final use=p.useCharacterSkill(skill);
    // mountFight keeps the sheet loading; its spinner never settles.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Conferma'),findsWidgets);
    await tester.tap(find.text('Conferma').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await use;
    expect(p.resourceCurrent('materia'),beforeMatter-1);
    expect(p.resourceCurrent('oculum'),beforeOculum);
    final saved=p.snapshot();
    p.load(saved);
    expect(p.resourceCurrent('materia'),beforeMatter-1);
    expect(p.resourceCurrent('oculum'),beforeOculum);
    await closeFixture(tester,p);
  });
}
