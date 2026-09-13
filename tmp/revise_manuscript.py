from pathlib import Path
p=Path('lib/src/main/oculum_home_sheet_page.dart'); s=p.read_text(encoding='utf-8')
a=s.index('  Widget manuscriptLivingDesktopPage('); b=s.index('  Widget characterDesktopPage()',a)
v=s[a:b]
v=v.replace('const moss = Color(0xFF304C27);', "final moss = statFormulaColor('resilienza');")
v=v.replace('const blood = Color(0xFF7D211B);', "final blood = statFormulaColor('volonta');")
v=v.replace('const matter = Color(0xFF1E6680);', "final matter = statFormulaColor('materia');")
v=v.replace('const oculum = Color(0xFF68406F);', "final oculum = statFormulaColor('oculum');")
v=v.replace('constraints.maxWidth >= 1180', 'constraints.maxWidth >= 760')
v=v.replace('compact ? 92 : 112','compact ? 72 : 82').replace('compact ? 94 : 116','compact ? 74 : 84')
v=v.replace('compact ? 118 : 150','compact ? 96 : 122')
v=v.replace('horizontal: 14, vertical: 10','horizontal: 12, vertical: 6')
v=v.replace('fontSize: 25','fontSize: 24').replace('minHeight: 6','minHeight: 3')
v=v.replace("stat('PV', leggiNumero(currentHpController), maxHp(), moss)","stat('RES · PV', leggiNumero(currentHpController), maxHp(), moss)")
v=v.replace("leggiNumero(volontaController),\n            max(1, leggiNumero(volontaController))", "currentSpendableStatValue('volonta'),\n            max(1, leggiNumero(volontaController))")
v=v.replace("leggiNumero(materiaController),\n            max(1, leggiNumero(materiaController))", "currentSpendableStatValue('materia'),\n            max(1, leggiNumero(materiaController))")
v=v.replace("stat('OCU', leggiNumero(oculumController), oculumMassimo(), oculum)","stat('OCU', oculumAttuale(), oculumMassimo(), oculum)")
# Draw the eye as an engraving, with the portrait retained on the character rail.
x=v.index('          if (immaginePersonaggio != null)'); y=v.index('        ],',x)
v=v[:x]+v[y:]
x=v.index('    Widget partyRow(int index)'); y=v.index('    Widget manuscriptSectionTab',x)
v=v[:x]+'''    Widget partyRow(int index) => Tooltip(
      message: '${nomeSchedaPersonaggio(index)} · ${tipoSchedaPersonaggio(index)}',
      child: InkWell(
        onTap: () => cambiaSchedaPersonaggio(index),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
          decoration: BoxDecoration(
            color: index == schedaCorrente ? const Color(0xFF302419) : shell,
            border: Border.all(color: index == schedaCorrente ? brass : const Color(0xFF483820)),
          ),
          child: Center(child: masterPartyAvatar(index, size: 42)),
        ),
      ),
    );
    final left = frame(Column(children: [
      const Padding(padding: EdgeInsets.symmetric(vertical: 8),
        child: Icon(Icons.people_outline, color: brass, size: 18)),
      Expanded(child: ListView.builder(
        itemCount: schedePersonaggio.length, itemExtent: 60,
        addAutomaticKeepAlives: false,
        itemBuilder: (context, index) => partyRow(index),
      )),
      IconButton(tooltip: 'Gestisci personaggi',
        onPressed: () => vaiAllaFunzione(page: 9, logTitle: 'Gestisci personaggi'),
        icon: const Icon(Icons.group_add_outlined, color: brass, size: 18)),
    ]));

'''+v[y:]
# The list stays useful on an empty sheet, with real existing actions.
x=v.index('    final center = frame(')
v=v[:x]+'''    Widget basicAction(String title, String detail, IconData icon, VoidCallback use) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF947747), width: .6))),
        child: Row(children: [
          Icon(icon, color: ink, size: 23), const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: ink, fontSize: 15, fontWeight: FontWeight.w600)),
            Text(detail, style: const TextStyle(color: Color(0xFF584632), fontSize: 11)),
          ])),
          OutlinedButton(onPressed: use,
            style: OutlinedButton.styleFrom(foregroundColor: ink,
              minimumSize: const Size(48, 32), padding: const EdgeInsets.symmetric(horizontal: 10),
              side: const BorderSide(color: Color(0xFF795C32)), shape: const RoundedRectangleBorder()),
            child: const Text('USA', style: TextStyle(fontSize: 10))),
        ]),
      );
    final basicActions = <Widget>[
      basicAction('Attacco · VC', '1d20 + $vcValue · Danno ${dannoTotale()}', Icons.gps_fixed,
          () => tiraValoreSpeciale('VC', vc())),
      basicAction('Difesa · CM', '1d20 + ${cm()} · Difesa ${difesa()}', Icons.shield_outlined,
          () => tiraValoreSpeciale('CM', cm())),
      basicAction('Iniziativa', 'Determina il tuo posto nel turno', Icons.hourglass_bottom,
          () => tiraValoreSpeciale('Iniziativa', iniziativa())),
      basicAction('Danno / Cura', 'Applica un danno o recupera Vita', Icons.favorite_border,
          () => vaiAllaFunzione(page: 0, anchorId: 'sheet_damage_heal', logTitle: 'Danno / Cura')),
      basicAction('Sottotratti', 'Scegli la prova adatta alla scena', Icons.auto_stories_outlined,
          () => vaiAllaFunzione(page: 0, anchorId: 'sheet_editable_values', logTitle: 'Sottotratti')),
    ];

'''.replace('$vcValue','${vc()}')+v[x:]
x=v.index('              Expanded(\n                child: skills.isEmpty'); y=v.index('              Container(',x)
v=v[:x]+'''              Expanded(
                child: RepaintBoundary(child: CustomPaint(
                  painter: const OculumManuscriptPaperPainter(),
                  child: ListView.builder(
                    itemCount: basicActions.length + skills.length,
                    addAutomaticKeepAlives: false,
                    itemBuilder: (context, index) => index < basicActions.length
                        ? basicActions[index] : actionRow(index - basicActions.length),
                  ),
                )),
              ),
'''+v[y:]
# Real action activation, preserving the existing cost/cooldown dialog.
v=v.replace("onPressed: () => vaiAllaFunzione(\n              page: 4,\n              anchorId: 'free_skill_$i',\n              logTitle: skills[i].nome,\n            )", "onPressed: () => usaFormaSkill(skills[i], i, 0)")
v=v.replace('height: 54','height: 40').replace('fontSize: 24,\n                          fontWeight','fontSize: 18,\n                          fontWeight')
v=v.replace('width: constraints.maxWidth * .22','width: 66')
v=v.replace('width: constraints.maxWidth * .27','width: compact ? 200 : 248')
# The right column must scroll on short windows instead of overflowing.
v=v.replace("          manuscriptHeading('BERSAGLIO'),", """          TextButton.icon(
            onPressed: masterInitiativeTokens.isEmpty ? null : () => nextMasterInitiativeTurn(),
            icon: const Icon(Icons.skip_next, size: 16),
            label: const Text('TURNO SUCCESSIVO'),
            style: TextButton.styleFrom(foregroundColor: brass),
          ),
          manuscriptHeading('BERSAGLIO'),""")
v=v.replace("onPressed: () => vaiAllaFunzione(\n                        page: 2,\n                        anchorId: 'settings_mods',\n                        logTitle: 'MOD',\n                      )", 'onPressed: mostraModificaRapida')
# On narrow windows keep the portrait strip short instead of a 340px list.
v=v.replace('SizedBox(height: 340, child: left)', '''SizedBox(height: 68, child: ListView.builder(
                          scrollDirection: Axis.horizontal, itemCount: schedePersonaggio.length,
                          itemExtent: 62, itemBuilder: (context, index) => partyRow(index)))''')
v=v.replace('SizedBox(height: 680, child: center)','SizedBox(height: 620, child: center)')
v=v.replace('SizedBox(height: 440, child: right)','SizedBox(height: 640, child: right)')
s=s[:a]+v+s[b:]
s+='''
/// A fixed seed keeps the engraving still across rebuilds. No image decoding
/// or generated bitmap is needed for the parchment surface.
class OculumManuscriptPaperPainter extends CustomPainter {
  const OculumManuscriptPaperPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..shader = const LinearGradient(
      colors: [Color(0xFFC6AD7C), Color(0xFFE7D6AF), Color(0xFFD9C397)],
      begin: Alignment.topLeft, end: Alignment.bottomRight,
    ).createShader(rect));
    final random = Random(91);
    final grain = Paint()..color = const Color(0xFF513B21).withValues(alpha: .075);
    for (var i = 0; i < 750; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      canvas.drawLine(Offset(x,y), Offset(x + random.nextDouble() * 5,y), grain);
    }
    final edge = Paint()..color = const Color(0xFF846536).withValues(alpha: .4)
      ..style = PaintingStyle.stroke ..strokeWidth = 1;
    canvas.drawRect(rect.deflate(4), edge);
    for (final corner in [rect.topLeft, rect.topRight, rect.bottomLeft, rect.bottomRight]) {
      canvas.drawCircle(corner, 15, edge);
      canvas.drawCircle(corner, 19, edge);
    }
  }
  @override
  bool shouldRepaint(covariant OculumManuscriptPaperPainter oldDelegate) => false;
}
'''
p.write_text(s,encoding='utf-8')
p=Path('lib/main.dart'); s=p.read_text(encoding='utf-8').replace('final forceIconRail = viewportWidth < 980;', 'final forceIconRail = viewportWidth < 980 || manuscriptLivingActive;'); p.write_text(s,encoding='utf-8')
