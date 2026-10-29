import 'package:flutter_test/flutter_test.dart';
import 'oculum_escape_provoker_test.dart' as fixtures;
import 'oculum_october27_resources_test.dart' show closeFixture;

void main() {
  testWidgets(
    'missing character identity is generated without derived-stat recursion',
    (tester) async {
      final (state, p) = await fixtures.mountFight(tester);
      state.oculumUsernameController.clear();
      state.nomeController.text = 'Prova Luna';
      state.schedePersonaggio[0]['sheetTag'] = '';
      state.schedePersonaggio[0]['id'] = '';
      expect(p.ensureSheetTags(), true);
      expect(p.ownerTag(), startsWith('ProvaLunaOcu:3690'));
      final stable = p.ownerTag();
      expect(p.ensureSheetTags(), false);
      expect(p.ownerTag(), stable);
      expect(tester.takeException(), isNull);
      await closeFixture(tester, p);
    },
  );
}
