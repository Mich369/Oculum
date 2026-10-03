from pathlib import Path
p=Path('test/oculum_resistances_turns_integrity_test.dart');s=p.read_text(encoding='utf-8').replace("      SharedPreferences.setMockInitialValues({});", """      SharedPreferences.setMockInitialValues({});
      final font = await rootBundle.load('assets/fonts/Poppins-Regular.ttf');
      for (final family in ['Poppins', 'Roboto', 'Georgia', 'Segoe UI', 'serif']) {
        await (FontLoader(family)..addFont(Future.value(font))).load();
      }
      final icons = File('build/unit_test_assets/fonts/MaterialIcons-Regular.otf');
      if (icons.existsSync()) { await (FontLoader('MaterialIcons')..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())))).load(); }
""")
s=s.replace('await tester.pumpAndSettle();','await tester.pump(const Duration(milliseconds: 600));')
s=s.replace("      probe.openResistances();", "      state.updateOculumHomeUi(() => state.referenceOculumFlames = true);\n      await photo('fiammelle-desktop');\n      probe.openResistances();")
s=s.replace("      await photo('sottotratti-mobile');", """      await photo('sottotratti-mobile');
      await tester.pageBack();
      await tester.pump(const Duration(milliseconds: 600));
      tester.view.physicalSize = const Size(1440, 1100);
      probe.openDice();
      await photo('dadi-desktop');
      expect(find.text('d15'), findsOneWidget);
      expect(find.text('d25'), findsOneWidget);
      expect(find.text('d200'), findsOneWidget);""")
p.write_text(s,encoding='utf-8')
p=Path('lib/src/main/oculum_performance_probe.dart');s=p.read_text(encoding='utf-8').replace('  void openResistances()', "  void openDice() => _state.openReferenceDetail('Sessione Dadi', 'sheet_dice', _state.sheetDiceRollPanel);\n  void openResistances()");p.write_text(s,encoding='utf-8')
