part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

/// Additive presets: legacy IDs, custom colors and unlocked themes are retained.
const oculumRestylePresets = <OculumColorPreset>[
  OculumColorPreset(
    id: 'restyle_originale',
    nameIt: 'Originale',
    nameEn: 'Original',
    descriptionIt:
        'Carbone, pergamena e rame antico. Tutti i colori sono modificabili.',
    descriptionEn:
        'Charcoal, parchment and antique copper. All colors are editable.',
    primary: Color(0xffe6ddc8),
    secondary: Color(0xff161318),
    tertiary: Color(0xffb58c72),
    utility: Color(0xffaaa28f),
    oculumFormula: Color(0xffb89de0),
    backgroundTop: Color(0xff09090c),
    backgroundMid: Color(0xff161318),
    backgroundBottom: Color(0xff0b0b0e),
    eyePupilGlow: Color(0xffb58c72),
  ),
  OculumColorPreset(
    id: 'restyle_cenere',
    nameIt: 'Cenere',
    nameEn: 'Ash',
    descriptionIt:
        'Antracite e argento spento. Tutti i colori sono modificabili.',
    descriptionEn: 'Anthracite and muted silver. All colors are editable.',
    primary: Color(0xffdedee2),
    secondary: Color(0xff181b21),
    tertiary: Color(0xff929cac),
    utility: Color(0xffa6aab4),
    oculumFormula: Color(0xffa2b6df),
    backgroundTop: Color(0xff0b0d10),
    backgroundMid: Color(0xff181b21),
    backgroundBottom: Color(0xff101217),
    eyePupilGlow: Color(0xff929cac),
  ),
  OculumColorPreset(
    id: 'restyle_sangue',
    nameIt: 'Sangue',
    nameEn: 'Blood',
    descriptionIt:
        'Nero e cremisi, testo caldo. Tutti i colori sono modificabili.',
    descriptionEn: 'Black and crimson with warm text. All colors are editable.',
    primary: Color(0xffe8d6ce),
    secondary: Color(0xff21151a),
    tertiary: Color(0xffb65a64),
    utility: Color(0xffc39a94),
    oculumFormula: Color(0xffd383a3),
    backgroundTop: Color(0xff100b0e),
    backgroundMid: Color(0xff21151a),
    backgroundBottom: Color(0xff130e12),
    eyePupilGlow: Color(0xffb65a64),
  ),
  OculumColorPreset(
    id: 'restyle_aurora',
    nameIt: 'Aurora',
    nameEn: 'Aurora',
    descriptionIt:
        'Viola notturno e ametista. Tutti i colori sono modificabili.',
    descriptionEn: 'Night violet and amethyst. All colors are editable.',
    primary: Color(0xffe5def0),
    secondary: Color(0xff1c1728),
    tertiary: Color(0xffac85d3),
    utility: Color(0xffb0a4c7),
    oculumFormula: Color(0xffb396e3),
    backgroundTop: Color(0xff0e0c15),
    backgroundMid: Color(0xff1c1728),
    backgroundBottom: Color(0xff120e1c),
    eyePupilGlow: Color(0xffac85d3),
  ),
  OculumColorPreset(
    id: 'restyle_natura',
    nameIt: 'Natura',
    nameEn: 'Nature',
    descriptionIt:
        'Foresta scura e bronzo vegetale. Tutti i colori sono modificabili.',
    descriptionEn: 'Dark forest and botanical bronze. All colors are editable.',
    primary: Color(0xffdde5d4),
    secondary: Color(0xff15221c),
    tertiary: Color(0xff8cb294),
    utility: Color(0xffa4b8a4),
    oculumFormula: Color(0xffa3c9b8),
    backgroundTop: Color(0xff0b100e),
    backgroundMid: Color(0xff15221c),
    backgroundBottom: Color(0xff0e1712),
    eyePupilGlow: Color(0xff8cb294),
  ),
  OculumColorPreset(
    id: 'restyle_lume',
    nameIt: 'Lume',
    nameEn: 'Candlelight',
    descriptionIt:
        'Carbone e oro di candela. Tutti i colori sono modificabili.',
    descriptionEn: 'Charcoal and candle gold. All colors are editable.',
    primary: Color(0xffeee3cb),
    secondary: Color(0xff241f16),
    tertiary: Color(0xffc3a365),
    utility: Color(0xffbaa885),
    oculumFormula: Color(0xffd8ba82),
    backgroundTop: Color(0xff100e0a),
    backgroundMid: Color(0xff241f16),
    backgroundBottom: Color(0xff17130d),
    eyePupilGlow: Color(0xffc3a365),
  ),
];

/// Centralized visual language for the main Oculum application.
/// Pages should consume these tokens instead of introducing new hard-coded
/// spacing, radii or animation durations.
abstract final class OculumDesignTokens {
  static const double space2 = 2;
  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space24 = 24;
  static const double radiusSmall = 8;
  static const double radiusMedium = 12;
  static const double radiusLarge = 18;
  static const double compactControlHeight = 40;
  static const double normalControlHeight = 46;
  static const Duration motionFast = Duration(milliseconds: 120);
  static const Duration motionNormal = Duration(milliseconds: 220);

  static const Color obsidian = Color(0xFF090A0F);
  static const Color cathedralStone = Color(0xFF12151D);
  static const Color raisedStone = Color(0xFF191D27);
  static const Color parchment = Color(0xFFE6DDC8);
  static const Color mutedParchment = Color(0xFFAAA28F);
  static const Color danger = Color(0xFFB84A52);

  static EdgeInsets pagePadding(bool compact) => EdgeInsets.symmetric(
    horizontal: compact ? space8 : space16,
    vertical: compact ? space8 : space12,
  );

  static BoxDecoration panelDecoration({
    required Color accent,
    bool elevated = true,
    double decorationIntensity = 1,
    String style = 'cattedrale',
    Color? background,
  }) {
    final intensity = decorationIntensity.clamp(0.0, 1.0);
    final surface = switch (style) {
      'manoscritto' => const Color(0xFF211C19),
      'ferro_battuto' => const Color(0xFF171A1E),
      'pergamena_nera' => const Color(0xFF252018),
      'vetro_arcano' => const Color(0xFF101923),
      'sigillo_rituale' => const Color(0xFF1E111B),
      _ => raisedStone,
    };
    final radius = switch (style) {
      'ferro_battuto' => radiusSmall,
      'vetro_arcano' => radiusLarge,
      'sigillo_rituale' => radiusLarge,
      _ => radiusMedium,
    };
    return BoxDecoration(
      color: background == null
          ? Color.lerp(cathedralStone, surface, elevated ? 0.56 : 0.24)
          : Color.lerp(background, accent, elevated ? .035 : .015),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: accent.withValues(alpha: 0.30 + 0.30 * intensity),
        width: 1,
      ),
      boxShadow: elevated && intensity > 0
          ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25 * intensity),
                blurRadius: 12 * intensity,
                offset: Offset(0, 4 * intensity),
              ),
              BoxShadow(
                color: accent.withValues(alpha: 0.05 * intensity),
                blurRadius: 18 * intensity,
              ),
            ]
          : const [],
    );
  }
}

/// Static corner engravings; no asset decoding, animation or layout cost.
class OculumPanelEngraving extends CustomPainter {
  const OculumPanelEngraving({required this.accent});
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 40 || size.height < 40) return;
    final ink = Paint()
      ..color = accent.withValues(alpha: .42)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (final origin in [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ]) {
      final dx = origin.dx == 0 ? 1.0 : -1.0;
      final dy = origin.dy == 0 ? 1.0 : -1.0;
      final path = Path()
        ..moveTo(origin.dx + dx * 3, origin.dy + dy * 16)
        ..lineTo(origin.dx + dx * 3, origin.dy + dy * 7)
        ..lineTo(origin.dx + dx * 7, origin.dy + dy * 3)
        ..lineTo(origin.dx + dx * 16, origin.dy + dy * 3);
      canvas.drawPath(path, ink);
      // Small hooked tendrils and a diamond echo the author's etched frame.
      final vine = Path()
        ..moveTo(origin.dx + dx * 4, origin.dy + dy * 31)
        ..cubicTo(origin.dx + dx * 12, origin.dy + dy * 28,
          origin.dx + dx * 7, origin.dy + dy * 20,
          origin.dx + dx * 18, origin.dy + dy * 13)
        ..cubicTo(origin.dx + dx * 25, origin.dy + dy * 7,
          origin.dx + dx * 29, origin.dy + dy * 13,
          origin.dx + dx * 34, origin.dy + dy * 4);
      canvas.drawPath(vine, ink);
      final point = Offset(origin.dx + dx * 12, origin.dy + dy * 12);
      canvas.drawPath(Path()..moveTo(point.dx, point.dy - 3)
        ..lineTo(point.dx + 3, point.dy)..lineTo(point.dx, point.dy + 3)
        ..lineTo(point.dx - 3, point.dy)..close(), ink);
    }
  }

  @override
  bool shouldRepaint(OculumPanelEngraving oldDelegate) =>
      oldDelegate.accent != accent;
}

class OculumGothicDivider extends StatelessWidget {
  const OculumGothicDivider({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: color.withValues(alpha: 0.25))),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: OculumDesignTokens.space8,
          ),
          child: Icon(Icons.auto_awesome, size: 12, color: color),
        ),
        Expanded(child: Divider(color: color.withValues(alpha: 0.25))),
      ],
    );
  }
}

extension _OculumPageGuidance on _OculumHomePageState {
  Widget pageGuidancePanel(int page) {
    final (it, en) = switch (page) {
      0 => (
        'Controlla Vita e statistiche. VC tira l’attacco, CM la difesa; i Sottotratti sono tiri alternativi.',
        'Check HP and stats. VC rolls attack, CM defense; Subtraits are alternative rolls.',
      ),
      1 => (
        'Scegli riposo breve o lungo: leggi i recuperi prima di confermare.',
        'Choose Short or Long Rest: review recovery before confirming.',
      ),
      2 => (
        'Apri un Titolo per leggere effetti e requisiti, poi scegli se equipaggiarlo.',
        'Open a Title to read effects and requirements, then choose whether to equip it.',
      ),
      3 => (
        'Apri un’Art: scegli la Skill e la forma disponibile, controlla costo e cooldown.',
        'Open an Art: choose its Skill and available form, check cost and cooldown.',
      ),
      4 => (
        'Leggi o modifica le Skill della scheda. Usa solo quelle disponibili per il tuo livello.',
        'Read or edit sheet Skills. Use only those available at your level.',
      ),
      5 => (
        'Scrivi nel Diario. Digita [[ per collegare un nome; apri gli Occhi della Memoria per seguirne la storia.',
        'Write in the Diary. Type [[ to link a name; open the Eyes of Memory to follow its history.',
      ),
      6 => (
        'Seleziona un oggetto per equipaggiarlo o consumarlo. Il mercato e il crafting restano accessibili qui.',
        'Select an item to equip or consume it. The market and crafting remain accessible here.',
      ),
      7 => (
        'Usa le risorse quando servono: le Ispirazioni ritirano i dadi, l’Accordo col Fato vale una sola volta.',
        'Use resources when needed: Inspirations reroll dice, the Pact with Fate works once.',
      ),
      8 => (
        'Cerca una regola o apri la Guida speciale dell’app per raggiungere il comando spiegato.',
        'Search a rule or open the Special app guide to reach the command it explains.',
      ),
      9 => (
        'Master: scegli le schede del Party e i nemici. I danni inseriti qui sono subiti dal bersaglio.',
        'Master: choose Party sheets and enemies. Damage entered here is taken by the target.',
      ),
      10 => (
        'Apri o crea una mappa, poi posiziona i token. La mappa funziona anche offline.',
        'Open or create a map, then place tokens. Maps also work offline.',
      ),
      11 => (
        'Scegli un tema e modifica i colori singoli. Le immagini conservano i colori originali.',
        'Choose a theme and edit individual colors. Images keep their original colors.',
      ),
      12 => (
        'Scegli il ruolo e la sessione. Condividi la scheda con il Master; offline puoi continuare a giocare.',
        'Choose role and session. Share your sheet with the Master; you can keep playing offline.',
      ),
      13 => (
        'Scegli il dado e il tiro da eseguire. Il risultato compare nel pannello dei dadi.',
        'Choose the die and roll to make. The result appears in the dice panel.',
      ),
      14 => (
        'Apri una ricetta e controlla materiali, quantità e Grado prima di creare l’oggetto.',
        'Open a recipe and check materials, quantities and Grade before crafting.',
      ),
      15 => (
        'Scegli la condizione e il bersaglio, poi applicala. Controlla durata e rimozione.',
        'Choose the condition and target, then apply it. Check duration and removal.',
      ),
      16 => (
        'Apri un Occhio dei Caduti per controllare il legame e le opzioni di evocazione.',
        'Open a Fallen Eye to inspect bond and summon options.',
      ),
      _ => (
        'Apri una sezione per vedere i comandi disponibili.',
        'Open a section to see available commands.',
      ),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Icon(Icons.explore_outlined, size: 18, color: tertiaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              t(it, en),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                height: 1.3,
                color: readableOnTheme(
                  primaryColor,
                  background: backgroundBottomColor,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: t(
              'Nascondi indicazioni · riattivabili nelle Impostazioni',
              'Hide guidance · enable again in Settings',
            ),
            onPressed: () {
              setState(() => showPageGuidance = false);
              programmaSalvataggio();
            },
            icon: Icon(Icons.close, size: 16, color: tertiaryColor),
          ),
        ],
      ),
    );
  }
}

class OculumAdaptiveActions extends StatelessWidget {
  const OculumAdaptiveActions({
    super.key,
    required this.children,
    this.spacing = OculumDesignTokens.space8,
  });

  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          for (final child in children)
            ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: constraints.maxWidth < 420
                    ? constraints.maxWidth
                    : 120,
              ),
              child: child,
            ),
        ],
      ),
    );
  }
}
