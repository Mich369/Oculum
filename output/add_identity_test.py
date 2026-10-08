from pathlib import Path
source=Path('test/oculum_current_screen_dice_test.dart').read_text()
prefix=source[:source.index('      state.updateOculumHomeUi(() {')]
prefix=prefix.replace("'Dice stay on the current screen at $size'","'Visible title identity remains linked at $size'")
suffix='''      final title = OculumTitle.fromJson({'nome':'Uccidi Bunnys','leggenda':'Leggenda originale','equipaggiato':true,'evoluto':true});
      state.updateOculumHomeUi(() {
        state.tutorialCompletato = true;
        state.datiCaricati = true;
        state.paginaCorrente = 0;
        state.nuovoDesignOculum = 'cattedrale';
        state.temiOldSchool = false;
        state.nomeController.text = 'Rose';
        state.titoli.clear();
        state.trattiRazziali.clear();
        state.titoli.add(title);
      });
      await tester.pump(const Duration(seconds:1));
      final heading=find.text('Rose | Uccidi Bunnys');
      expect(heading,findsOneWidget);
      await tester.ensureVisible(heading);
      await tester.longPress(heading);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog),findsOneWidget);
      expect(find.text('Leggenda'),findsOneWidget);
      expect(find.text('Bonus'),findsNothing);
      final fields=find.descendant(of:find.byType(AlertDialog),matching:find.byType(TextFormField));
      expect(fields,findsNWidgets(2));
      await tester.enterText(fields.first,'Nuovo titolo');
      await tester.enterText(fields.last,'Nuova leggenda');
      await tester.tap(find.text('Chiudi'));
      await tester.pumpAndSettle();
      expect(title.nome,'Nuovo titolo');
      expect(title.leggenda,'Nuova leggenda');
      expect(find.text('Rose | Nuovo titolo'),findsOneWidget);
      expect(title.sempreVisibile,isTrue);
      expect(tester.takeException(),isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
'''
Path('test/oculum_visible_title_identity_test.dart').write_text(prefix+suffix)
