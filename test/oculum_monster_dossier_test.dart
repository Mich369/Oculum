import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/main.dart';
import 'package:oculum/pages/oculum_dungeon/monster_book.dart';
import 'oculum_theme_effects_portrait_test.dart' as fixtures;

void main() {
  test(
    'reading costs and prose preserve forms, custom JSON and canonical mechanics',
    () {
      final red = monsterById('uomo_maschera_rossa')!;
      final skill = oculumMonsterBookArt(red).skills.first;
      final before = jsonEncode(skill.toJson());
      expect(oculumMonsterReadingCost(skill, 1), 'Nessun costo statistico');
      expect(
        oculumMonsterOverview(red),
        isNot(contains('Skill per il giocatore:')),
      );
      expect(
        oculumMonsterReadableProse('I/@vol-3; forme II/III; hp_current'),
        'Volontà-3; forme II/III; Vita attuale',
      );
      expect(
        monsterBookSkillText('masked_oculum_shield'),
        isNot(contains('mask_violet')),
      );
      expect(
        oculumStructuredEffectDescription(
          OculumStructuredEffect(
            type: 'planar',
            valueExpression: '1',
            narrativeText: 'Scatto gratuito con una Reazione veloce.',
          ),
        ),
        'Scatto gratuito con una Reazione veloce.',
      );
      expect(jsonEncode(skill.toJson()), before);
      final hidden = red.copyWith(
        descIt: 'Un mantello rosso. Punto debole: la nuca. Combatte a pugni.',
      );
      expect(
        oculumMonsterOverview(hidden, weakPointKnown: false),
        isNot(contains('la nuca')),
      );
      expect(hidden.descIt, contains('la nuca'));
    },
  );

  testWidgets(
    'monster dossier separates skills, Open, forms and drops on phone and desktop',
    (tester) async {
      for (final size in [const Size(390, 844), const Size(1440, 1000)]) {
        final dynamic state = await fixtures.mountSheet(tester, size);
        state.datiCaricati = false;
        final probe = OculumPerformanceProbe(state);
        final monster = monsterById('uomo_maschera_rossa')!;
        final overlay = OverlayEntry(
          builder: (_) => Positioned.fill(
            child: Material(
              color: const Color(0xff101219),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: probe.monsterDossier(monster),
                ),
              ),
            ),
          ),
        );
        Overlay.of(tester.element(find.byType(OculumHomePage))).insert(overlay);
        await tester.pump();
        expect(find.text('Aspetto'), findsOneWidget);
        expect(find.text('Comportamento e particolarità'), findsOneWidget);
        await tester.ensureVisible(find.text('Pugno serio'));
        await tester.tap(find.text('Pugno serio'));
        await tester.pump(const Duration(milliseconds: 300));
        for (final form in ['I', 'II', 'III']) {
          expect(find.text('Forma $form'), findsOneWidget);
        }
        expect(find.text('Costo: Nessun costo statistico'), findsNWidgets(3));
        expect(find.text('Buff Open'), findsOneWidget);
        expect(find.text('Skill Open'), findsOneWidget);
        expect(find.text('Drop e ricompense'), findsOneWidget);
        expect(tester.takeException(), isNull);
        overlay.remove();
        overlay.dispose();
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 2));
      }
    },
  );
}
