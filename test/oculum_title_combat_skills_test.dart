import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';

void main() {
  test(
    'title skills preserve separate cooldowns and editable combat roles',
    () {
      final title = OculumTitle(
        nome: 'Custode',
        tipo: 'Titolo',
        ottenimento: '',
        buff: '',
        puntoCieco: '',
        skill: 'Scudo+10',
        richiede: '',
        skillCombatRole: 'difesa',
        skillCooldown: OculumAbilityCooldown(amount: 6),
        skillExtra: [
          TitleExtraSkillEntry(
            nome: 'Sostegno',
            descrizione: 'Cura+5',
            combatRole: 'supporto',
            cooldown: OculumAbilityCooldown(amount: 3),
          ),
        ],
      );
      title.skillCooldown!.activate();
      final saved = OculumTitle.fromJson(title.toJson());
      expect(saved.skillCombatRole, 'difesa');
      expect(saved.skillCooldown!.remaining, 6);
      expect(saved.skillExtra.single.combatRole, 'supporto');
      expect(saved.skillExtra.single.cooldown!.ready, isTrue);
      saved.skillExtra.single.cooldown!.activate();
      expect(saved.skillCooldown!.remaining, 6);
      expect(saved.skillExtra.single.cooldown!.remaining, 3);
      final legacy = OculumTitle.fromJson({'nome': 'Vecchio titolo'});
      expect(legacy.skillCooldown, isNull);
      expect(legacy.skillCombatRole, isEmpty);
    },
  );
  test('ally damage bonuses go to help and explicit roles stay editable', () {
    final effects = [
      OculumStructuredEffect(
        type: 'danno',
        valueExpression: '5',
        recipient: 'alleato',
      ),
    ];
    expect(oculumCombatAbilityRole(effects), OculumCombatAbilityRole.support);
    expect(
      oculumCombatAbilityRole(effects, explicitType: 'difesa'),
      OculumCombatAbilityRole.defense,
    );
  });
}
