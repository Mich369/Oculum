import 'dart:ui' as ui;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oculum/services/oculum_diary_links.dart';
import 'package:oculum/widgets/oculum_diary_context_menu.dart';

void main() {
  test(
    'classification changes only the selected name, preserving surrounding prose',
    () {
      const text = 'Ho parlato con Quercia Sepolta, poi siamo tornati.';
      final start = text.indexOf('Quercia');
      final result = diaryAssignSelectionRole(
        text,
        start,
        start + 'Quercia Sepolta'.length,
        'enemy',
      )!;
      expect(
        result.text,
        'Ho parlato con [[Nemico:Quercia Sepolta]], poi siamo tornati.',
      );
      expect(result.cursor, result.text.indexOf(', poi'));
      final spaced = diaryAssignSelectionRole(
        'Prima  Arven  dopo',
        5,
        14,
        'npc',
      )!;
      expect(spaced.text, 'Prima  [[png:Arven]]  dopo');
    },
  );
  test(
    'reclassifying a linked word keeps identity and display alias without nesting links',
    () {
      const text = 'Oggi [[NPC:Arven|la guida]] ci ha salvati.';
      final start = text.indexOf('guida');
      final result = diaryAssignSelectionRole(text, start, start + 5, 'dead')!;
      expect(result.text, 'Oggi [[Morto:Arven|la guida]] ci ha salvati.');
      final name = text.indexOf('Arven');
      expect(
        diaryAssignSelectionRole(text, name, name + 5, 'obliterated')!.text,
        'Oggi [[Obliterato:Arven|la guida]] ci ha salvati.',
      );
      expect(diaryAssignSelectionRole('Arven', 0, 0, 'npc'), isNull);
      expect(diaryAssignSelectionRole('Arven\nMira', 0, 10, 'npc'), isNull);
      expect(diaryAssignSelectionRole('Arven', 0, 5, 'invalid'), isNull);
    },
  );

  for (final mobile in [false, true]) {
    testWidgets(
      mobile
          ? 'long press offers role assignment and keeps native copy'
          : 'right click offers role assignment and keeps native copy',
      (tester) async {
        tester.view.physicalSize = const Size(1100, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controller = TextEditingController(
          text: 'Arven ci ha guidati nel Bosco Nero.',
        );
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              platform: mobile
                  ? TargetPlatform.android
                  : TargetPlatform.windows,
            ),
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(40),
                child: TextField(
                  controller: controller,
                  contextMenuBuilder: (context, editable) =>
                      oculumDiaryContextMenu(
                        context,
                        editable,
                        onAssigned: (value) => controller.value = value,
                      ),
                ),
              ),
            ),
          ),
        );
        final position =
            tester.getTopLeft(find.byType(EditableText)) + const Offset(20, 12);
        if (mobile) {
          await tester.longPressAt(position);
        } else {
          await tester.tapAt(position);
          await tester.pumpAndSettle();
          controller.selection = const TextSelection(
            baseOffset: 0,
            extentOffset: 5,
          );
          await tester.pump();
          final gesture = await tester.startGesture(
            position,
            kind: ui.PointerDeviceKind.mouse,
            buttons: kSecondaryMouseButton,
          );
          await gesture.up();
        }
        await tester.pumpAndSettle();
        expect(find.text('Assegna ruolo'), findsOneWidget);
        expect(find.text('Copy'), findsOneWidget);
        await tester.tap(find.text('Assegna ruolo'));
        await tester.pumpAndSettle();
        expect(find.text('Ruolo di «Arven»'), findsOneWidget);
        expect(find.text('Obliterato / Oblio'), findsOneWidget);
        await tester.tap(find.text('NPC'));
        await tester.pumpAndSettle();
        expect(controller.text, '[[png:Arven]] ci ha guidati nel Bosco Nero.');
        expect(controller.selection.baseOffset, '[[png:Arven]]'.length);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
      variant: TargetPlatformVariant({
        mobile ? TargetPlatform.android : TargetPlatform.windows,
      }),
    );
  }
}
