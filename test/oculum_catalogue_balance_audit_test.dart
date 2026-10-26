import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';

void main() {
  test(
    'paid resource-generating and protective catalogue forms have bounded reuse',
    () {
      final issues = <Map<String, dynamic>>[];
      final rows = <Map<String, dynamic>>[];
      final seen = <String>{};
      var forms = 0;
      for (final monster in defaultMonsterBookEntries.where((m) => !m.isNpc)) {
        final art = oculumMonsterBookArt(monster);
        final ids = monsterBookUsableSkillIds(monster);
        for (var index = 0; index < art.skills.length; index++) {
          final skill = art.skills[index];
          for (var form = 1; form <= 3; form++) {
            forms++;
            final minimum = skill.oculumMinimoPerLivello(form),
                maximum = skill.oculumMassimoPerLivello(form);
            expect(
              minimum,
              greaterThanOrEqualTo(0),
              reason: '${monster.id}/${skill.nome}',
            );
            expect(
              maximum,
              greaterThanOrEqualTo(minimum),
              reason: '${monster.id}/${skill.nome}',
            );
            final effects = skill.effettiEvoluzione(form);
            final signature = jsonEncode([
              skill.nome,
              form,
              effects.map((e) => e.toJson()).toList(),
              minimum,
              maximum,
              skill.cooldownPerLivello[form - 1].toJson(),
            ]);
            if (!seen.add(signature)) continue;
            final row = <String, dynamic>{
              'monster': monster.id,
              'skill': skill.nome,
              'form': form,
              'minimum': minimum,
              'maximum': maximum,
              'resource': skill.risorsaCostoPerLivello(form),
              'cooldown': skill.cooldownPerLivello[form - 1].amount,
              'effects': effects.map((e) => e.toJson()).toList(),
            };
            rows.add(row);
            final passive =
                index < ids.length &&
                oculumMonsterBookSkillIsPassive(ids[index]);
            final resourceGain = effects.any(
              (e) => const {
                'aggiungi_reazioni',
                'aggiungi_reazioni_rapide',
                'cura',
                'scudo',
                'hp_temporanei',
              }.contains(e.type),
            );
            if (!passive &&
                minimum > 0 &&
                resourceGain &&
                skill.cooldownPerLivello[form - 1].amount <= 0) {
              issues.add({
                'monster': monster.id,
                'skill': skill.nome,
                'form': form,
                'reason': 'paid resource gain without cooldown',
              });
            }
          }
        }
      }
      File('build/balance-audit-20261026.json').writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert({
          'catalogueEntries': defaultMonsterBookEntries.length,
          'formsChecked': forms,
          'distinctForms': rows.length,
          'issues': issues,
          'definitions': rows,
        }),
      );
      // The report contains only public catalogue definitions, never player saves.
      // ignore: avoid_print
      print(
        'BALANCE entries=${defaultMonsterBookEntries.length} forms=$forms distinct=${rows.length} issues=${issues.length}',
      );
      expect(issues, isEmpty, reason: jsonEncode(issues.take(25).toList()));
    },
  );
}
