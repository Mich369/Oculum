import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'package:oculum/widgets/oculum_resource_bar_fx.dart';
import 'package:oculum/widgets/oculum_theme_presentation.dart';

void main() {
  test('only authored no-Art exceptions may spawn without techniques', () {
    for (final monster in defaultMonsterBookEntries.where((m) => !m.isNpc)) {
      final count =
          oculumMonsterBookSkills(monster).length +
          (oculumMonsterBookImportArt(monster)?.skills.length ?? 0);
      if (count == 0) {
        expect(
          monster.formTags.contains('Creatura Minore') ||
              const {
                'demonietto_bruciante',
                'demonietto_del_gelo',
                'coboldo_di_brina',
              }.contains(monster.id.split('_variante_').first),
          isTrue,
          reason: monster.id,
        );
        expect(monster.skillIds, isEmpty, reason: monster.id);
      }
    }
  });
  test('Chaos wanderers receive editable titles with real trade-offs', () {
    final monster = monsterById('ghoul_errante')!;
    final pool = oculumMonsterBookTitles(monster);
    expect(pool, hasLength(3));
    expect(pool.every((title) => title.tipo == 'Titolo di Chaos'), isTrue);
    expect(pool.where((title) => title.sempreVisibile), hasLength(1));
    expect(pool.every((title) => title.buff.contains('@')), isTrue);
    expect(pool.every((title) => title.puntoCieco.contains('-')), isTrue);
    final original = pool.first;
    final restored = OculumTitle.fromJson(original.toJson());
    expect(oculumActiveTitleFormulaTexts(restored), isNotEmpty);
    restored.sempreVisibile = false;
    expect(oculumActiveTitleFormulaTexts(restored), isEmpty);
    restored.sempreVisibile = true;
    restored.equipaggiato = false;
    expect(oculumActiveTitleFormulaTexts(restored), isEmpty);
    expect(pool.every((title) => title.oculum == 0), isTrue);
  });
  test('health colour is continuous at each danger threshold', () {
    for (final stop in [.15, .30, .50, .75]) {
      final before = oculumHealthColor(stop - .0001);
      final after = oculumHealthColor(stop + .0001);
      expect((before.r - after.r).abs(), lessThan(.02));
      expect((before.g - after.g).abs(), lessThan(.02));
      expect((before.b - after.b).abs(), lessThan(.02));
    }
    expect(oculumHealthColor(double.nan), oculumHealthColor(0));
    expect(oculumHealthColor(2), oculumHealthColor(1));
  });
  testWidgets(
    'life fill retains the existing drop and system motion override',
    (tester) async {
      final previous = oculumThemePresentation.value;
      addTearDown(() => oculumThemePresentation.value = previous);
      oculumThemePresentation.value = const OculumThemePresentation();
      Widget fill(double value, {bool disabled = false}) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: disabled),
          child: SizedBox(
            width: 200,
            height: 20,
            child: OculumAnimatedResourceFill(
              fraction: value,
              child: const ColoredBox(color: Colors.red),
            ),
          ),
        ),
      );
      await tester.pumpWidget(fill(.8));
      await tester.pumpWidget(fill(.2));
      await tester.pump(const Duration(milliseconds: 190));
      final middle = tester
          .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
          .widthFactor!;
      expect(middle, greaterThan(.2));
      expect(middle, lessThan(.8));
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        tester
            .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
            .widthFactor,
        .2,
      );
      await tester.pumpWidget(fill(.9, disabled: true));
      await tester.pump();
      expect(
        tester
            .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
            .widthFactor,
        .9,
      );
    },
  );

  testWidgets('resource fills rise in one second on the same sheet', (
    tester,
  ) async {
    final previous = oculumThemePresentation.value;
    addTearDown(() => oculumThemePresentation.value = previous);
    oculumThemePresentation.value = const OculumThemePresentation();

    Widget bars(
      double target, {
      String sheet = 'first',
      bool sleeping = false,
    }) => MaterialApp(
      home: Column(
        children: [
          OculumAnimatedResourceFill(
            key: ValueKey(sheet),
            fraction: target,
            child: const SizedBox(height: 20),
          ),
          OculumAnimatedResourceValue(
            key: ValueKey((sheet, sleeping)),
            fraction: sleeping ? 0 : target,
            builder: (context, displayed, child) =>
                LinearProgressIndicator(value: displayed),
          ),
        ],
      ),
    );

    double life() => tester
        .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
        .widthFactor!;
    double oculum() => tester
        .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
        .value!;

    await tester.pumpWidget(bars(.2));
    expect(life(), .2);
    expect(oculum(), .2);
    await tester.pumpWidget(bars(.8));
    await tester.pump(const Duration(milliseconds: 500));
    expect(life(), allOf(greaterThan(.2), lessThan(.8)));
    expect(oculum(), closeTo(life(), 1e-6));

    await tester.pumpWidget(bars(.8));
    await tester.pump(const Duration(milliseconds: 500));
    expect(life(), .8);
    expect(oculum(), .8);

    await tester.pumpWidget(bars(.9));
    await tester.pump(const Duration(milliseconds: 250));
    expect(oculum(), allOf(greaterThan(.8), lessThan(.9)));
    await tester.pumpWidget(bars(.4, sheet: 'second'));
    expect(life(), .4);
    expect(oculum(), .4);

    await tester.pumpWidget(bars(.3, sheet: 'second'));
    await tester.pump();
    expect(oculum(), .3);
    await tester.pumpWidget(bars(.9, sheet: 'second'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(oculum(), allOf(greaterThan(.3), lessThan(.9)));
    await tester.pumpWidget(bars(.9, sheet: 'second', sleeping: true));
    expect(oculum(), 0);
  });

  testWidgets('healing during a falling life fill starts from actual Life', (
    tester,
  ) async {
    final previous = oculumThemePresentation.value;
    addTearDown(() => oculumThemePresentation.value = previous);
    oculumThemePresentation.value = const OculumThemePresentation();
    Widget fill(double fraction) => MaterialApp(
      home: OculumAnimatedResourceFill(
        fraction: fraction,
        child: const SizedBox(height: 20),
      ),
    );
    double shown() => tester
        .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
        .widthFactor!;

    await tester.pumpWidget(fill(.81));
    await tester.pumpWidget(fill(.57));
    await tester.pump(const Duration(milliseconds: 16));
    expect(shown(), greaterThan(.75));

    await tester.pumpWidget(fill(.75));
    expect(shown(), closeTo(.57, 1e-6));
    await tester.pump(const Duration(milliseconds: 250));
    expect(shown(), allOf(greaterThan(.57), lessThan(.75)));
    await tester.pump(const Duration(milliseconds: 750));
    expect(shown(), .75);

    await tester.pumpWidget(fill(.9));
    await tester.pump(const Duration(milliseconds: 250));
    final beforeSecondHeal = shown();
    expect(beforeSecondHeal, allOf(greaterThan(.75), lessThan(.9)));
    await tester.pumpWidget(fill(.95));
    expect(shown(), closeTo(beforeSecondHeal, 1e-6));
    await tester.pump(const Duration(seconds: 1));
    expect(shown(), .95);
  });

  testWidgets('resource fill follows reduced and disabled theme motion', (
    tester,
  ) async {
    final previous = oculumThemePresentation.value;
    addTearDown(() => oculumThemePresentation.value = previous);
    oculumThemePresentation.value = const OculumThemePresentation(
      motion: OculumThemeMotion.reduced,
    );
    Widget fill(double target) => MaterialApp(
      home: OculumAnimatedResourceValue(
        fraction: target,
        builder: (context, displayed, child) =>
            LinearProgressIndicator(value: displayed),
      ),
    );
    double shown() => tester
        .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
        .value!;

    await tester.pumpWidget(fill(.2));
    await tester.pumpWidget(fill(.8));
    await tester.pump(const Duration(milliseconds: 70));
    expect(shown(), allOf(greaterThan(.2), lessThan(.8)));
    await tester.pump(const Duration(milliseconds: 70));
    expect(shown(), .8);

    await tester.pumpWidget(fill(1));
    await tester.pump(const Duration(milliseconds: 40));
    expect(shown(), lessThan(1));
    oculumThemePresentation.value = const OculumThemePresentation(
      motion: OculumThemeMotion.disabled,
    );
    await tester.pump();
    expect(shown(), 1);
  });
}
