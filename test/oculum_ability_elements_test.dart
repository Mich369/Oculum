import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'oculum_escape_provoker_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

void main() {
  testWidgets('automatic attack and defense use separate bonuses; typed skills override manual choices', (tester) async {
    final (state, p) = await fixtures.mountFight(tester);
    state.titoli.clear(); state.trattiRazziali.clear(); state.arti.clear();
    state.skills.clear(); state.inventario.clear(); state.activeStructuredEffects.clear();
    state.buffMalusRapidiController.text='@Danni+15 Ghiaccio\n@Danni+10 Fuoco\n@Difesa+15 Fuoco\n@Difesa+10 Ghiaccio';
    p.invalidateDerivedCaches();
    expect(p.attackElement(), 'gelo');
    expect(p.defenseElement(), 'fuoco');
    expect(p.defenseElement({'defenseElement':'Ghiaccio'}), 'gelo');
    state.buffMalusRapidiController.text+='\n@TypeSwitch Acqua';
    p.invalidateDerivedCaches();
    expect(p.attackElement(), 'acqua');
    final prepared = p.applyEffects([OculumStructuredEffect(type:'danno', valueExpression:'1',
      elementType:'fulmine',mode:'prossima_azione')]);
    expect(p.attackElement(), 'fulmine', reason: '$prepared ${p.structuredEffects()}');
    p.applyEffects([OculumStructuredEffect(type:'difesa', valueExpression:'1',
      elementType:'gelo',mode:'prossima_azione')]);
    expect(p.defenseElement({'defenseElement':'Fuoco'}), 'gelo');
    final saved=p.snapshot(); p.load(saved);
    expect(p.attackElement(), 'fulmine');
    expect(p.defenseElement(), 'gelo');
    await closeFixture(tester,p);
  });

  test('ability resistance adds percentage points, caps at ninety, preserves immunity', () {
    expect(oculumAbilityResistanceDamage(unmodifiedDamage:100,modifiedDamage:75,bonusPercent:6),69);
    expect(oculumAbilityResistanceDamage(unmodifiedDamage:100,modifiedDamage:25,bonusPercent:30),10);
    expect(oculumAbilityResistanceDamage(unmodifiedDamage:100,modifiedDamage:5,bonusPercent:30),5);
    expect(oculumAbilityResistanceDamage(unmodifiedDamage:100,modifiedDamage:0,bonusPercent:90),0);
    expect(oculumAbilityResistanceDamage(unmodifiedDamage:100,modifiedDamage:-25,bonusPercent:90),-25);
  });

  testWidgets('an Art and its two skills grant nine percent; forms and ordinary gear never duplicate it', (tester) async {
    final (state,p)=await fixtures.mountFight(tester);
    state.arti.clear(); state.skills.clear(); state.titoli.clear();
    state.trattiRazziali.clear(); state.inventario.clear();
    ArtSkill technique(String name)=>ArtSkill(nome:name,evo1:'Fuoco',evo2:'Fuoco',evo3:'Fuoco',
      effettiPerLivello:[for(var i=0;i<3;i++) [OculumStructuredEffect(type:'danno',valueExpression:'1',elementType:'fuoco')]]);
    final art=CharacterArt(nome:'Art del Fuoco',tipo:'Oculum Art',descrizione:'',
      skills:[technique('Fiammata'),technique('Dardo')]);
    state.arti.add(art);
    state.inventario.add(InventoryItem(nome:'Spada normale',peso:1,quantita:1,note:'',arma:true,
      equipaggiata:true,elementoDanno:'Fuoco',ability:oculumCharacterSkillFromArt(technique('Arma normale'))));
    expect(p.abilityResistance('fuoco'),9);
    expect(p.abilityResistance('gelo'),0);
    final saved=p.snapshot(); p.load(saved);
    expect(p.abilityResistance('fuoco'),9);
    state.arti.first.sbloccata=false;
    expect(p.abilityResistance('fuoco'),0);
    await closeFixture(tester,p);
  });
}
