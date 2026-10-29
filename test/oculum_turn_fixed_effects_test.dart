import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'oculum_escape_provoker_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

void main() {
  testWidgets(
    'inactive sheet turn safely ticks immutable snapshots and preserves Open/permanent effects',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      const remoteTag = 'OculumPlayerOcu:3690ABCD';
      final originalEffects = List<dynamic>.unmodifiable([
        Map<String, dynamic>.unmodifiable({
          'effectId': 'expires-now',
          'unit': 'turni',
          'remaining': 1,
          'type': 'modifica_statistica',
          'target': 'difesa',
          'value': 2,
        }),
        Map<String, dynamic>.unmodifiable({
          'effectId': 'expires-next',
          'unit': 'turns',
          'remaining': 2,
          'type': 'modifica_statistica',
          'target': 'danni',
          'value': 3,
        }),
        Map<String, dynamic>.unmodifiable({
          'effectId': 'owned-open-buff',
          'unit': 'open_lifecycle',
          'remaining': 0,
          'type': 'modifica_statistica',
          'target': 'difesa',
          'value': 10,
        }),
        Map<String, dynamic>.unmodifiable({
          'effectId': 'permanent',
          'unit': 'permanente',
          'remaining': 0,
          'type': 'modifica_statistica',
          'target': 'oculum',
          'value': 1,
        }),
      ]);
      final before = jsonEncode(originalEffects);
      final remote = <String, dynamic>{
        ...p.snapshot(),
        'id': remoteTag,
        'sheetTag': remoteTag,
        'nome': 'Alleato inattivo',
        'inMasterParty': true,
        'activeStructuredEffects': originalEffects,
      };
      state.schedePersonaggio.add(remote);
      final token = state.masterInitiativeTokens[1] as Map;
      token['id'] = token['sheetTag'] = remoteTag;
      state.masterInitiativeActiveIndex = 0;
      p.recordCurrentEncounter();
      // The counter ticks at the END of that participant's personal turn.
      // First leave the current hero, then leave the inactive remote ally.
      p.turn();
      expect(
        state.masterInitiativeTokens[state
            .masterInitiativeActiveIndex]['sheetTag'],
        remoteTag,
        reason: 'The remote participant must actually receive the next turn',
      );
      // Starting the remote turn runs referenceCreatureTurn through the real
      // load/save path, which replaces the saved Map. Install the immutable
      // transport snapshot on that canonical sheet AFTER this normal save;
      // otherwise checking `remote` below would only inspect a detached Map.
      final canonicalRemote = (state.schedePersonaggio as List)
          .whereType<Map>()
          .singleWhere((sheet) => sheet['sheetTag'] == remoteTag);
      canonicalRemote['activeStructuredEffects'] = originalEffects;
      p.turn();
      final settledRemote = (state.schedePersonaggio as List)
          .whereType<Map>()
          .singleWhere((sheet) => sheet['sheetTag'] == remoteTag);
      final effects = settledRemote['activeStructuredEffects'] as List;
      expect(effects, isNot(same(originalEffects)));
      expect(effects.whereType<Map>().map((e) => e['effectId']), [
        'expires-next',
        'owned-open-buff',
        'permanent',
      ]);
      expect(effects.whereType<Map>().first['remaining'], 1);
      expect(
        jsonEncode(originalEffects),
        before,
        reason:
            'Neither the fixed-length list nor its immutable maps is mutated',
      );
      expect(
        effects.whereType<Map>().where((e) => e['remaining'] == 0),
        hasLength(2),
      );
      expect(settledRemote['playerReportedTurn'], 1);
      await closeFixture(tester, p);
    },
  );
}
