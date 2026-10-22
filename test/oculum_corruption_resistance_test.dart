import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'oculum_theme_effects_portrait_test.dart' as fixtures;

void main() {
  testWidgets(
    'Mastery counts only full hits per source, survives JSON and resets each attempt',
    (tester) async {
      final dynamic state = await fixtures.mountSheet(
        tester,
        const Size(1440, 900),
      );
      final probe = OculumPerformanceProbe(state);
      state.datiCaricati = false;
      state.schedePersonaggio
        ..clear()
        ..add(<String, dynamic>{
          'id': 'TargetOcu:3690FD5G',
          'sheetTag': 'TargetOcu:3690FD5G',
          'nome': 'Target',
        });
      state.schedaCorrente = 0;
      state.livelloController.text = '8';
      Map<String, dynamic> hit(
        String id, {
        String source = 'caster',
        String outcome = 'full',
        int level = 5,
        String encounter = 'fight',
      }) => {
        'id': id,
        'sourceTag': source,
        'sourceName': source,
        'level': level,
        'encounterId': encounter,
        'outcome': outcome,
      };
      expect(
        probe.recordCorruptionHit(hit('graze', outcome: 'reduced')),
        isFalse,
      );
      expect(probe.recordCorruptionHit(hit('first')), isFalse);
      expect(probe.recordCorruptionHit(hit('first')), isFalse);
      expect(probe.recordCorruptionHit(hit('other', source: 'other')), isFalse);
      expect(probe.recordCorruptionHit(hit('second')), isFalse);
      probe.saveSheet();
      final saved = probe.snapshot();
      probe.load(saved);
      expect(probe.recordCorruptionHit(hit('third')), isTrue);
      expect(probe.recordCorruptionHit(hit('third')), isFalse);
      expect(probe.recordCorruptionHit(hit('fourth')), isFalse);
      expect(probe.recordCorruptionHit(hit('fifth')), isFalse);
      expect(probe.recordCorruptionHit(hit('sixth')), isTrue);
      expect(probe.recordCorruptionHit(hit('same-level', level: 8)), isFalse);
      expect(
        probe.recordCorruptionHit(hit('new-fight', encounter: 'next')),
        isFalse,
      );
      probe.cancelPendingSave();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 3));
    },
  );

  testWidgets(
    'Third resolved full attack queues one Corruption defense without replaying damage',
    (tester) async {
      final dynamic state = await fixtures.mountSheet(
        tester,
        const Size(1440, 900),
      );
      final probe = OculumPerformanceProbe(state);
      state.datiCaricati = false;
      state.schedePersonaggio
        ..clear()
        ..add(<String, dynamic>{
          'id': 'TargetOcu:3690FD5G',
          'sheetTag': 'TargetOcu:3690FD5G',
          'nome': 'Target',
        });
      state.schedaCorrente = 0;
      state.livelloController.text = '8';
      final target = probe.currentTag();
      final requests = <Map<String, dynamic>>[];
      for (var i = 0; i < 3; i++) {
        final request = <String, dynamic>{
          'id': 'mastery-hit-$i',
          'encounterId': 'encounter_1',
          'sourceTag': 'caster',
          'sourceName': 'Caster',
          'targetTag': target,
          'attack': 30,
          'damage': 0,
          'level': 5,
          'difficulty': 'normale',
          'status': 'pending',
          'scope': probe.permissionScope,
          'effects': [
            OculumStructuredEffect(
              type: 'stato',
              appliedState: 'corruzione',
              resource: 'corruption_mastery:caster',
            ).toJson(),
          ],
        };
        requests.add(request);
        state.onlineCombatRequests[request['id']] = request;
        await tester.runAsync(
          () => probe.resolveCombatDefense(request, 'cm', 1),
        );
      }
      final applications = (state.onlineCombatRequests as Map).values
          .where((r) => r['kind'] == 'corruption')
          .toList();
      expect(applications, hasLength(1));
      expect(applications.single['status'], 'pending');
      expect(applications.single['fromMastery'], isTrue);
      expect(
        probe.conditions.any((c) => c.conditionType == 'corruzione'),
        isFalse,
      );
      expect(requests.last['corruptionFullHits'], 3);
      await tester.runAsync(
        () => probe.resolveCombatDefense(requests.last, 'cm', 1),
      );
      expect(
        (state.onlineCombatRequests as Map).values.where(
          (r) => r['kind'] == 'corruption',
        ),
        hasLength(1),
      );
      probe.cancelPendingSave();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 3));
    },
  );

  testWidgets(
    'Corruption request exposes Will defenses at equal level and resolves once',
    (tester) async {
      final dynamic state = await fixtures.mountSheet(
        tester,
        const Size(1440, 900),
      );
      final probe = OculumPerformanceProbe(state);
      state.datiCaricati = false;
      state.schedePersonaggio.clear();
      state.schedePersonaggio.add(<String, dynamic>{
        'id': 'DifensoreOcu:3690FD5G',
        'sheetTag': 'DifensoreOcu:3690FD5G',
        'nome': 'Difensore',
        'grado': '0',
      });
      state.schedaCorrente = 0;
      state.livelloController.text = '10';
      state.skills.clear();
      state.incomingDamagePresets.clear();
      state.dannoSubitoPercentPerTipo.clear();
      state.dannoSubitoPercentController.clear();
      final tag = probe.currentTag();
      probe.queueCorruption(targetTag: tag, sourceLevel: 10, sourceTotal: 25);
      final request =
          state.onlineCombatRequests['test-corruption'] as Map<String, dynamic>;
      expect(request['status'], 'pending');
      // A second incoming packet must not replace the pending request or reset it.
      probe.queueCorruption(targetTag: tag, sourceLevel: 10, sourceTotal: 999);
      expect(
        identical(state.onlineCombatRequests['test-corruption'], request),
        isTrue,
      );
      expect(request['attack'], 25);
      await tester.pumpWidget(
        MaterialApp(
          theme: oculumBaseTheme,
          home: Scaffold(body: probe.corruptionRequests()),
        ),
      );
      expect(find.text('Crepa −3'), findsOneWidget);
      expect(find.text('Fermezza −3'), findsOneWidget);
      probe.cancelPendingSave();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 3));
    },
  );

  testWidgets(
    'lower-level target receives Corruption automatically once without HP damage',
    (tester) async {
      final dynamic state = await fixtures.mountSheet(
        tester,
        const Size(1440, 900),
      );
      final probe = OculumPerformanceProbe(state);
      state.datiCaricati = false;
      state.schedePersonaggio.clear();
      state.schedePersonaggio.add(<String, dynamic>{
        'id': 'DifensoreOcu:3690FD5G',
        'sheetTag': 'DifensoreOcu:3690FD5G',
        'nome': 'Difensore',
        'grado': '0',
      });
      state.schedaCorrente = 0;
      state.livelloController.text = '0';
      state.skills.clear();
      state.incomingDamagePresets.clear();
      state.dannoSubitoPercentPerTipo.clear();
      state.dannoSubitoPercentController.clear();
      final tag = probe.currentTag();
      final hp = probe.currentHp();
      probe.queueCorruption(targetTag: tag, sourceLevel: 1, sourceTotal: 25);
      final request =
          state.onlineCombatRequests['test-corruption'] as Map<String, dynamic>;
      expect(request['status'], 'resolved');
      expect(request['infected'], isTrue);
      expect(
        probe.conditions.where(
          (condition) => condition.conditionType == 'corruzione',
        ),
        hasLength(1),
      );
      expect(probe.currentHp(), hp);
      final roll = request['roll'];
      probe.queueCorruption(targetTag: tag, sourceLevel: 1, sourceTotal: 25);
      expect(request['roll'], roll);
      expect(
        probe.conditions.where(
          (condition) => condition.conditionType == 'corruzione',
        ),
        hasLength(1),
      );
      probe.cancelPendingSave();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 3));
    },
  );
  testWidgets(
    'active and received sheets add mastery to existing Corruption resistance',
    (tester) async {
      final dynamic state = await fixtures.mountSheet(
        tester,
        const Size(1440, 900),
      );
      final probe = OculumPerformanceProbe(state);
      state.datiCaricati = false;
      final skill = CharacterSkill(
        nome: 'Padrone della Corruzione',
        tipo: 'Passiva',
        costo: '0',
        cooldown: '2',
        descrizione: '',
        scrollData: Map<String, dynamic>.from(
          oculumCorruptionScrollItem(0).craftData['scroll'] as Map,
        ),
      );
      state.skills.clear();
      state.skills.add(skill);
      state.incomingDamagePresets.clear();
      state.incomingDamagePresets['corrotto'] = 'Resistenza';
      state.dannoSubitoPercentPerTipo.clear();
      expect(probe.corruptionResistance(), 75);
      final received = <String, dynamic>{
        'skills': [skill.toJson()],
        'incomingDamagePresets': {'corrotto': 'Resistenza'},
        'dannoSubitoPercentualePerTipo': {'corrotto': '-20%'},
      };
      expect(
        probe.corruptionResistanceForSheet(received),
        closeTo(70, .000001),
      );
      state.dannoSubitoPercentPerTipo['corrotto'] = '-20%';
      expect(probe.corruptionResistance(), closeTo(70, .000001));
      expect(state.incomingDamagePresets['corrotto'], 'Resistenza');
      expect(state.dannoSubitoPercentPerTipo['corrotto'], '-20%');

      state.dannoSubitoPercentPerTipo['corrotto'] = '-50%';
      expect(probe.corruptionResistance(), 100);
      probe.applyEffects([
        OculumStructuredEffect(
          type: 'stato',
          appliedState: 'corruzione',
          recipient: 'se_stesso',
          valueExpression: '1',
          duration: '0',
        ),
      ]);
      expect(
        probe.conditions.where(
          (condition) => condition.conditionType == 'corruzione',
        ),
        isEmpty,
      );
      // An immune caster can still prepare an infection for an enemy: only the
      // recipient's resistance is relevant when the pending effect is delivered.
      probe.applyEffects([
        OculumStructuredEffect(
          type: 'stato',
          appliedState: 'corruzione',
          recipient: 'nemico',
          valueExpression: '1',
          duration: '0',
          resource: 'corruption_scroll:0',
        ),
      ]);
      expect(
        probe.structuredEffects().where(
          (effect) => effect['type'] == 'pending_target',
        ),
        isNotEmpty,
      );
      skill.scrollData['resistancePercent'] = 30;
      expect(probe.corruptionResistance(), 80);
      final saved = CharacterSkill.fromJson(skill.toJson());
      expect(saved.scrollData['resistancePercent'], 30);
      expect(
        probe.corruptionResistanceForSheet({
          'skills': [saved.toJson()],
          'dannoSubitoPercentualePerTipo': {'corrotto': '-50%'},
        }),
        80,
      );
      probe.cancelPendingSave();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 3));
    },
  );
}
