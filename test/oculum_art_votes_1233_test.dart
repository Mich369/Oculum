import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'package:oculum/widgets/oculum_monster_theme.dart';
import 'package:pointycastle/digests/sha256.dart';

import 'oculum_theme_effects_portrait_test.dart' as fixtures;

// Explicit choices from galleria-lotti-20261117-1233. Kept in the test so
// CI and archive cleanup do not depend on mutable, untracked output files.
const _votes = <({String id, String? name, String slot, String sha256})>[
  (
    id: 'habitat_oblio_ragno_delle_ombre_cancellate_variante_veterana',
    name: 'Abrasyweb',
    slot: 'B',
    sha256: '815a604243c3d702bc00cc7034a6f08b647a665d6b9a05e67c1bdfe12e0dde19',
  ),
  (
    id: 'carne_viva_soglia_della_sutura',
    name: null,
    slot: 'A',
    sha256: '5f0c2b0dd21da69d3caf5a6c997027563fd6fb8496854fb2032b1e3e2f837c2f',
  ),
  (
    id: 'habitat_morti_regina_delle_cripte_sommerse_variante_corazzata',
    name: 'Funeryshroud',
    slot: 'A',
    sha256: 'bfdee7c71b465d33cf39698732ec63d52ce79213db287945c1bf45d02428684b',
  ),
  (
    id: 'habitat_diabolico_re_dei_patti_consumati',
    name: 'Scoryrex',
    slot: 'A',
    sha256: '3e89c88baf4b31cb935a73ed951eef415ba5bb3209472ce754ca11ad9a60e278',
  ),
  (
    id: 'habitat_vero_inferno_custode_del_cancello_senza_ritorno_variante_rituale',
    name: 'Mirusclaust',
    slot: 'A',
    sha256: '25001c27cfe0f8ce760d7be3999bed4245714acbc8dcc64f95d84143dab9178f',
  ),
  (
    id: 'gabli_caverne',
    name: 'Gabli delle Caverne',
    slot: 'G',
    sha256: '0b7c77a3607d83afc468dae481b7e2aac5cd4316e7a3d4baf515577ac2f31590',
  ),
  (
    id: 'habitat_sotterraneo_talpa_dei_cristalli_ciechi',
    name: 'Vibryclaw',
    slot: 'A',
    sha256: 'fe2ba9247bc3876b3bca0717c4d543044623fafad790efe037095b5edeb03097',
  ),
  (
    id: 'habitat_nuvole_rocciose_serpente_del_cumulonembo_variante_corazzata',
    name: 'Nymboscyte',
    slot: 'B',
    sha256: '55004a92b2a8c924ddb334f107c89709b3d8d58d3717834834d662f3ae96c403',
  ),
  (
    id: 'habitat_shadow_hell_regina_dello_specchio_dell_oblio_variante_veterana',
    name: 'Umbracrown',
    slot: 'F',
    sha256: '33b014a218cdc722323ccadb6d1c6358a9f30fe811575deab69bdc3dc189265e',
  ),
  (
    id: 'habitat_isole_vipera_dei_parafulmini_variante_rituale',
    name: 'Mirusfulgur',
    slot: 'A',
    sha256: '5be3c673eff9225a89f769c720ecb7b82dc9011077b7aed6ddb595919cf7c841',
  ),
];

// Later name revisions leave the original plate/name votes above intact.
const _latestNameById = <String, String>{
  'habitat_oblio_ragno_delle_ombre_cancellate_variante_veterana': 'Abrasyrel',
  'habitat_morti_regina_delle_cripte_sommerse_variante_corazzata': 'Funerys',
  'habitat_diabolico_re_dei_patti_consumati': 'Scoryth',
  'habitat_vero_inferno_custode_del_cancello_senza_ritorno_variante_rituale':
      'Claustyr',
  'gabli_caverne': 'Gablyn',
  'habitat_sotterraneo_talpa_dei_cristalli_ciechi': 'Vibryn',
  'habitat_nuvole_rocciose_serpente_del_cumulonembo_variante_corazzata':
      'Nymboryth',
  'habitat_shadow_hell_regina_dello_specchio_dell_oblio_variante_veterana':
      'Umbreth',
  'habitat_isole_vipera_dei_parafulmini_variante_rituale': 'Fulgryn',
};

void main() {
  const environmentId = 'carne_viva_soglia_della_sutura';

  testWidgets(
    'Only the explicitly approved ritual gatekeeper returns to creation',
    (tester) async {
      const baseId = 'habitat_vero_inferno_custode_del_cancello_senza_ritorno';
      const chosenId = '${baseId}_variante_rituale';
      expect(oculumIsRetiredMonsterId(baseId), isTrue);
      expect(monsterById(baseId), isNull);
      expect(defaultMonsterBookEntries.any((m) => m.id == baseId), isFalse);
      expect(oculumSavedMonsterBookEntryById(baseId), isNotNull);
      expect(oculumIsRetiredMonsterId(chosenId), isFalse);
      final source = monsterById(chosenId)!;
      expect(defaultMonsterBookEntries.any((m) => m.id == chosenId), isTrue);
      expect(source.nameIt, 'Claustyr');
      final before = source.toJson();
      final dynamic state = await fixtures.mountSheet(
        tester,
        const Size(1440, 1000),
      );
      final probe = OculumPerformanceProbe(state);
      state.modalitaMaster = true;
      state.datiCaricati = false;
      state.quickSheetNameController.clear();
      state.quickSheetDescriptionController.clear();
      state.quickSheetCountController.text = '1';
      final generation = probe.generateBookCreatureFromSource(
        source,
        forcedType: source.creationStatType,
        stats: source.stats,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      if (source.formTags.contains('Umanoide')) {
        expect(find.text('Ruolo dell’umanoide'), findsOneWidget);
        await tester.tap(find.widgetWithText(FilledButton, 'Crea'));
        await tester.pump();
      }
      await tester.runAsync(() => generation);
      await tester.pump();
      final created = probe.snapshot();
      expect(created['monsterBookSourceId'], chosenId);
      expect(created['nome'], 'Claustyr');
      expect(source.toJson(), before);
      expect(monsterById(baseId), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
    },
  );

  testWidgets('All ten approved plates resolve to the exact voted WebP', (
    tester,
  ) async {
    expect(_votes, hasLength(10));
    expect(_votes.map((vote) => vote.id).toSet(), hasLength(10));
    for (final vote in _votes) {
      final id = vote.id;
      final asset = id == environmentId
          ? oculumHomeArtworkPath(id)
          : OculumMonsterTheme.desktopIllustrationForId(id);
      expect(asset, isNotNull, reason: id);
      final data = await rootBundle.load(asset!);
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      final digest = SHA256Digest()
          .process(bytes)
          .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
          .join();
      expect(digest, vote.sha256, reason: '$id / ${vote.slot}');
      if (id == environmentId) {
        expect(monsterById(id), isNull, reason: 'The threshold is a place');
      } else {
        final monster = monsterById(id)!;
        final name = vote.name!;
        expect(monster.id, id);
        final currentName = _latestNameById[id] ?? name;
        expect(monster.nameIt, currentName);
        expect(oculumLookupMonsterId(name).exact?.id, id);
        final aliases = oculumMonsterNameSearchAliases(monster);
        expect(
          aliases,
          containsAll({name, currentName, monster.speciesNameIt}),
        );
        final customized = monster.copyWith(
          nameIt: 'Nome del Master',
          nameEn: 'Custom',
        );
        expect(customized.nameIt, 'Nome del Master');
        expect(oculumMonsterNameSearchAliases(customized), contains(name));
      }
    }
  });

  testWidgets('The approved threshold can be selected in the real Home menu', (
    tester,
  ) async {
    final dynamic state = await fixtures.mountSheet(
      tester,
      const Size(1440, 1000),
    );
    final probe = OculumPerformanceProbe(state);
    state.updateOculumHomeUi(() {
      state.paginaCorrente = 17;
      state.homeArtworkChoice = 'amber_shore';
      state.homeArtworkFollowsTheme = false;
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    final choice = find.byKey(
      const ValueKey('choose_home_artwork_$environmentId'),
    );
    expect(choice, findsOneWidget);
    await tester.ensureVisible(choice);
    await tester.tap(choice);
    await tester.pump();
    expect(state.homeArtworkChoice, environmentId);
    expect(
      probe.homeHeroArtwork(),
      'assets/oculum/theme_stories/webp/$environmentId.webp',
    );
    expect(probe.snapshot()['homeArtworkChoice'], environmentId);
    expect(probe.snapshot()['homeArtworkFollowsTheme'], isFalse);
    expect(oculumHomeArtworkChoices, contains('amber_shore'));
    expect(oculumHomeArtworkChoices, contains('cathedral_eye'));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
  });
}
