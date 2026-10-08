from pathlib import Path
p=Path('lib/src/main/oculum_pawn_cores.dart');s=p.read_text(encoding="utf-8");s=s.replace("if (source != null) 'coreSource': source","'coreSource': ?source");s=s.replace("item.craftData['brokenCore'] != true)\n      return;","item.craftData['brokenCore'] != true) {\n      return;\n    }");s=s.replace("item.craftData['brokenCore'] == true)\n      return;","item.craftData['brokenCore'] == true) {\n      return;\n    }");p.write_text(s,encoding="utf-8")
p=Path('lib/src/main/oculum_home_titles_inventory_pages.dart');s=p.read_text(encoding="utf-8");chunk="""          if (item.craftData['brokenCore'] == true)
            const PopupMenuItem<String>(
              value: 'restore_pawn_core',
              child: Text('Rievoca Pawn Lv 10 · 6 kg Metallo runico'),
            ),
""";assert s.count(chunk)==1;s=s.replace(chunk,'');start=s.index('    Future<void> showInventoryContextMenu');idx=s.index('        items: <PopupMenuEntry<String>>[',start)+len('        items: <PopupMenuEntry<String>>[\n');s=s[:idx]+chunk+s[idx:];p.write_text(s,encoding="utf-8")

