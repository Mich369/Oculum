import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'oculum_theme_effects_portrait_test.dart' as fixtures;

void main() {
  testWidgets('Master grants keep catalog clones independent of saved items', (
    tester,
  ) async {
    final dynamic state = await fixtures.mountSheet(
      tester,
      const Size(834, 1000),
    );
    state.datiCaricati = false;
    final probe = OculumPerformanceProbe(state);
    final source = InventoryItem(
      nome: 'Reliquia personale per test catalogo',
      peso: 1.5,
      quantita: 7,
      note: 'Mantieni questa descrizione',
      equipaggiata: true,
      craftData: {'test': 'personalizzato'},
    );
    final duplicate = InventoryItem.fromJson(source.toJson())..quantita = 3;
    state.inventario.addAll([source, duplicate]);
    final before = jsonEncode(source.toJson());
    final catalogItem = probe.masterCatalogItems().singleWhere(
      (item) => item.nome == source.nome,
    );
    expect(catalogItem.quantita, 1);
    expect(catalogItem.equipaggiata, isFalse);
    expect(catalogItem.craftData['test'], 'personalizzato');
    catalogItem.note = 'Copia modificata';
    expect(jsonEncode(source.toJson()), before);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
  });

  test(
    'catalog index combines search, grade and hybrid categories without changing custom JSON',
    () {
      final custom = InventoryItem(
        nome: 'Scudo di rame personale',
        peso: 1.25,
        quantita: 9,
        note: 'Reperto della famiglia',
        arma: true,
        protegge: true,
        equipaggiata: true,
        bonusScudo: 8,
        gradoOggetto: 2,
        gradoRichiesto: 3,
        buff: '@Volontà+7',
        elementoDanno: 'Luna personale',
        craftData: {
          'custom': {'preserved': true},
        },
      );
      final other = InventoryItem(
        nome: 'Pietra',
        peso: 0,
        quantita: 1,
        note: '',
      );
      final before = jsonEncode(custom.toJson());
      final index = OculumInventorySearchIndex([custom, other]);
      expect(
        index.search(query: 'rame famiglia', category: 'weapon', grade: 3),
        [same(custom)],
      );
      expect(index.search(category: 'shield'), [same(custom)]);
      expect(index.search(category: 'equipped'), [same(custom)]);
      expect(index.search(query: 'LUNA PERSONALE'), [same(custom)]);
      expect(index.search(category: 'shield', grade: 2), isEmpty);
      expect(index.search(query: 'nessuna corrispondenza'), isEmpty);
      expect(jsonEncode(custom.toJson()), before);
    },
  );

  test('item searches put closer names before fragments and notes', () {
    InventoryItem item(String name, {String note = ''}) =>
        InventoryItem(nome: name, peso: 0, quantita: 1, note: note);

    final noteMatch = item('Reliquia', note: 'Forgiata da un Demon');
    final firstFragment = item('Vyrdemon');
    final secondFragment = item('Arcdemon');
    final middleFragment = item('Oculdemonix');
    final wordPrefix = item('Gemma Demonium');
    final wordMatch = item('Sigillo Demon');
    final namePrefix = item('Demonward');
    final exact = item('Demon');
    final items = [
      noteMatch,
      firstFragment,
      secondFragment,
      middleFragment,
      wordPrefix,
      wordMatch,
      namePrefix,
      exact,
    ];
    final index = OculumInventorySearchIndex(items);

    final matches = index.search(query: ' DEMON ');
    expect(matches.take(4), [exact, namePrefix, wordMatch, wordPrefix]);
    expect(
      matches.skip(4).take(3),
      unorderedEquals([firstFragment, secondFragment, middleFragment]),
    );
    expect(
      matches.indexOf(firstFragment),
      lessThan(matches.indexOf(secondFragment)),
    );
    expect(matches.last, same(noteMatch));
    expect(index.search(), orderedEquals(items));
  });

  test('related projectile names prioritize items for the sheet elements', () {
    final fire = InventoryItem(
      nome: 'Palla di brace',
      peso: 0,
      quantita: 1,
      note: '',
      elementoDanno: 'Fuoco',
    );
    final waterScroll = InventoryItem(
      nome: 'Sfera di quarzo',
      peso: 0,
      quantita: 1,
      note: '',
      craftData: {
        'scroll': {'element': 'water', 'grade': 2},
      },
    );
    final waterAbility = InventoryItem(
      nome: 'Dardo di vetro',
      peso: 0,
      quantita: 1,
      note: '',
      ability: CharacterSkill(
        nome: 'Risveglio',
        tipo: 'Attacco',
        costo: '',
        cooldown: '',
        descrizione: '',
        forme: [
          CharacterSkillForm(
            effettiStrutturati: [
              OculumStructuredEffect(type: 'danno', elementType: 'acqua'),
            ],
          ),
        ],
      ),
    );
    final noteMatch = InventoryItem(
      nome: 'Reliquia',
      peso: 0,
      quantita: 1,
      note: 'Portava una sfera alla cintura.',
    );
    final index = OculumInventorySearchIndex([
      fire,
      noteMatch,
      waterAbility,
      waterScroll,
    ]);
    const preferred = {'acqua', 'fisico'};

    for (final query in ['sfera', 'dardo', 'palla', 'sparo energetico']) {
      final matches = index.search(query: query, preferredElements: preferred);
      expect(matches.take(2), unorderedEquals([waterScroll, waterAbility]));
      expect(matches[2], same(fire));
    }
    expect(
      index.search(query: 'sfera', preferredElements: preferred).last,
      same(noteMatch),
    );
    expect(
      index.search(
        query: 'dardo',
        category: 'scroll',
        grade: 2,
        preferredElements: preferred,
      ),
      [same(waterScroll)],
    );
    expect(
      index.search(query: 'sfera', preferredElements: {'fuoco'}).first,
      same(fire),
    );
  });

  testWidgets('closed inventory panels build their body only after a click', (
    tester,
  ) async {
    final dynamic state = await fixtures.mountSheet(
      tester,
      const Size(834, 1000),
    );
    final probe = OculumPerformanceProbe(state);
    var builds = 0;
    final opening = showDialog<void>(
      context: state.context,
      builder: (_) => Dialog(
        child: SingleChildScrollView(
          child: probe.deferredInventorySection((_) {
            builds++;
            return const Text('Body built on demand');
          }),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(builds, 0);
    expect(find.text('Body built on demand'), findsNothing);
    await tester.tap(find.text('Lazy inventory test'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(builds, 1);
    expect(find.text('Body built on demand'), findsOneWidget);
    Navigator.pop(state.context);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await opening;
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets(
    'Master search debounces against one snapshot and refreshes changed custom items',
    (tester) async {
      final dynamic state = await fixtures.mountSheet(
        tester,
        const Size(834, 1000),
      );
      final probe = OculumPerformanceProbe(state);
      var loads = 0;
      var name = 'Reliquia prima';
      late StateSetter refresh;
      final opening = showDialog<void>(
        context: state.context,
        builder: (_) => StatefulBuilder(
          builder: (context, update) {
            refresh = update;
            return Dialog(
              child: SingleChildScrollView(
                child: probe.catalogBrowserForTest(() {
                  loads++;
                  return [
                    InventoryItem(
                      nome: name,
                      peso: 1,
                      quantita: 1,
                      note: 'custom',
                    ),
                  ];
                }),
              ),
            );
          },
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(loads, 1);
      expect(find.text('Reliquia prima'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('master_catalog_search')),
        'assente',
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Reliquia prima'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Nessun oggetto trovato.'), findsOneWidget);
      expect(loads, 1);
      await tester.enterText(
        find.byKey(const ValueKey('master_catalog_search')),
        '',
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(loads, 1);
      refresh(() => name = 'Reliquia aggiornata');
      await tester.pump();
      expect(loads, 2);
      expect(find.text('Reliquia aggiornata'), findsOneWidget);
      expect(find.text('Reliquia prima'), findsNothing);
      Navigator.pop(state.context);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await opening;
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 3));
    },
  );

  for (final width in [320.0, 834.0, 1440.0]) {
    testWidgets(
      'inventory stays organized and defers Master catalog at width $width',
      (tester) async {
        final dynamic state = await fixtures.mountSheet(
          tester,
          Size(width, 1000),
        );
        final probe = OculumPerformanceProbe(state);
        state.modalitaMaster = true;
        state.inventario.clear();
        final custom = InventoryItem(
          nome: 'Reliquia personale',
          peso: .2,
          quantita: 3,
          note: 'Dettaglio non perso',
          buff: '@Volontà+2',
        );
        state.inventario.add(custom);
        final before = jsonEncode(custom.toJson());
        final opening = showDialog<void>(
          context: state.context,
          builder: (_) => Dialog(
            insetPadding: EdgeInsets.zero,
            child: SizedBox(
              width: width,
              height: 900,
              child: probe.inventory(),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        expect(
          find.byKey(const ValueKey('inventory_add_button')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('master_catalog_search')),
          findsNothing,
        );
        expect(find.text('Nome Oggetto'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.enterText(
          find.byKey(const ValueKey('inventory_search')),
          'assente',
        );
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('Reliquia personale'), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 100));
        expect(
          find.text('Nessun oggetto corrisponde ai filtri.'),
          findsOneWidget,
        );
        expect(jsonEncode(custom.toJson()), before);
        await tester.enterText(
          find.byKey(const ValueKey('inventory_search')),
          '',
        );
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tap(find.byKey(const ValueKey('inventory_add_button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        expect(
          find.byKey(const ValueKey('master_catalog_search')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        Navigator.pop(state.context);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        await opening;
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 3));
      },
    );
  }

  testWidgets(
    'quick equipment keeps grade limits, current shields and item JSON',
    (tester) async {
      final dynamic state = await fixtures.mountSheet(
        tester,
        const Size(834, 1000),
      );
      final probe = OculumPerformanceProbe(state);
      state.gradoController.text = '0';
      state.inventario.clear();
      state.scudoController.text = '0';
      final item = InventoryItem(
        nome: 'Scudo custom',
        peso: 1,
        quantita: 4,
        note: 'Conserva questa nota',
        protegge: true,
        bonusScudo: 8,
        gradoRichiesto: 1,
        craftData: {'custom': 42},
      );
      state.inventario.add(item);
      final before = jsonEncode(item.toJson());
      probe.equipItem(item, true);
      expect(item.equipaggiata, isFalse);
      expect(jsonEncode(item.toJson()), before);
      item.gradoRichiesto = 0;
      probe.equipItem(item, true);
      expect(item.equipaggiata, isTrue);
      expect(state.scudoController.text, '8');
      probe.equipItem(item, false);
      expect(item.equipaggiata, isFalse);
      expect(state.scudoController.text, '0');
      expect(item.craftData['custom'], 42);
      expect(item.quantita, 4);
      expect(item.note, 'Conserva questa nota');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 3));
    },
  );
}
