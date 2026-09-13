from pathlib import Path
p=Path('lib/src/main/oculum_fallen_eyes.dart')
s=p.read_text(encoding='utf-8')
s=s.replace('Conoscenze ereditate: nessuna (Art, Skill e Titoli restano separati dall’evocatore).','Tecniche ereditate dal mostro: la rarità sblocca 0/1/2/3 Art. I Titoli del proprietario restano separati.')
s=s.replace("    // Un Occhio dei Perduti è una creatura indipendente: eredita soltanto\n    // corpo, immagine e statistiche della fonte, mai le sue conoscenze.","    // La creatura eredita il corpo e le tecniche, con i limiti della rarità.")
# Preserve actual technique payloads while editing their display names.
s=s.replace("        'fallenEyeOriginalArts': [\n          for (final controller in artNames)\n            {\n              'nome': controller.text.trim(),\n              'known': controller.text.trim().isNotEmpty,\n            },\n        ],", """        'fallenEyeOriginalArts': [
          for (var i = 0; i < artNames.length; i++)
            {
              if (i < (draft['arti'] as List? ?? const []).length)
                ...Map<String, dynamic>.from((draft['arti'] as List)[i] as Map),
              'nome': artNames[i].text.trim(),
              'known': artNames[i].text.trim().isNotEmpty,
            },
        ],""")
s=s.replace("          editingEye['sheetData'] = _cloneJsonMap(draft);", "          editingEye['sheetData'] = _cloneJsonMap(draft);\n          oculumFallenEyeApplyInheritedPowers(editingEye);")
s=s.replace("            schedePersonaggio[activeIndex] = _cloneJsonMap(draft);", "            schedePersonaggio[activeIndex] = _cloneJsonMap(editingEye['sheetData'] as Map<String, dynamic>);")
p.write_text(s,encoding='utf-8')
