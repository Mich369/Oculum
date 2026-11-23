import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'oculum_escape_provoker_test.dart' show mountFight;
import 'oculum_october27_resources_test.dart' show closeFixture;

void main() {
  testWidgets(
    'party roll bonus excludes temporary summons and clones and saves remainders',
    (tester) async {
      final (state, probe) = await mountFight(tester);
      final current = state.schedaCorrente;
      state.rebirthato = true;
      state.schedePersonaggio[current]['inMasterParty'] = true;
      state.schedePersonaggio[current]['rebirthato'] = true;
      state.schedePersonaggio.addAll([
        <String, dynamic>{
          'id': 'REBIRTH-PARTNER',
          'nome': 'Compagna Rebirthata',
          'tipoScheda': 'Personaggio',
          'inMasterParty': true,
          'rebirthato': true,
        },
        <String, dynamic>{
          'id': 'REBIRTH-CLONE',
          'nome': 'Clone Rebirthato',
          'tipoScheda': 'Personaggio',
          'inMasterParty': true,
          'rebirthato': true,
          'planarRuntime': {'doppioneCopy': true},
        },
        <String, dynamic>{
          'id': 'REBIRTH-SUMMON',
          'nome': 'Evocazione Rebirthata',
          'tipoScheda': 'Personaggio',
          'inMasterParty': true,
          'rebirthato': true,
          'isSummon': true,
          'summonInstanceId': 'temporary',
        },
      ]);
      probe.ensureSheetTags();

      expect(probe.rebirthPartyRollBonusPercent, 27);
      expect(probe.addRebirthPartyRollExperience(9, 'test-bar'), 11);
      expect(
        probe.planarStateSnapshot()['rebirthPartyRollExperienceRemainders'],
        {'test-bar': 43},
      );
      final saved = probe.snapshot();
      probe.load(saved);
      expect(probe.addRebirthPartyRollExperience(9, 'test-bar'), 11);
      expect(
        probe.planarStateSnapshot()['rebirthPartyRollExperienceRemainders'],
        {'test-bar': 86},
      );
      await closeFixture(tester, probe);
    },
  );

  testWidgets(
    'Rebirth cancel leaves level, EXP and saved customization intact',
    (tester) async {
      final (state, probe) = await mountFight(tester);
      state.rebirthato = false;
      state.livelloController.text = '25';
      state.expController.text = '2500';
      final source = probe.snapshot();
      source['planarRuntime'] = {
        ...Map<String, dynamic>.from(
          source['planarRuntime'] as Map? ?? const {},
        ),
        'customRebirthNote': 'keep',
      };
      state.schedePersonaggio[state.schedaCorrente] = source;
      probe.load(source);
      expect(probe.planarStateSnapshot()['customRebirthNote'], 'keep');
      final pending = probe.requestRebirth(true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.textContaining('13 uccisioni'), findsOneWidget);
      expect(state.rebirthato, false);
      expect(state.livelloController.text, '25');
      await tester.tap(find.byKey(const ValueKey('rebirth_cancel')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await pending;
      expect(state.rebirthato, false);
      expect(state.expController.text, '2500');
      expect(probe.planarStateSnapshot()['customRebirthNote'], 'keep');
      await closeFixture(tester, probe);
    },
  );

  testWidgets(
    'confirmed Rebirth starts a fresh level0 cycle and archives previous EXP',
    (tester) async {
      final (state, probe) = await mountFight(tester);
      state.rebirthato = false;
      state.livelloController.text = '25';
      state.gradoController.text = '2';
      state.expController.text = '2500';
      state.scalaExpAutomatica = true;
      final pending = probe.requestRebirth(true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(find.byKey(const ValueKey('rebirth_confirm')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await pending;
      expect(state.rebirthato, true);
      expect(state.livelloController.text, '0');
      expect(state.gradoController.text, '2');
      expect(state.expController.text, '0');
      expect(probe.rebirthKillsRemaining, 13);
      final history = probe.planarStateSnapshot()['rebirthHistory'] as List;
      expect((history.single as Map)['previousExp'], 2500);
      probe.awardExperience(1, receiptId: 'after-rebirth-small-gain');
      expect(state.livelloController.text, '0');
      expect(state.expController.text, '1');
      final saved = probe.snapshot();
      probe.load(saved);
      expect(probe.rebirthKillsRemaining, 13);
      expect(state.livelloController.text, '0');
      await closeFixture(tester, probe);
    },
  );
}
