import 'package:flutter/material.dart';

// Helper for color values, assuming it's already defined elsewhere or will be.
// For now, using a simple extension.
extension ColorExtension on Color {
  Color withValues({double? alpha, int? red, int? green, int? blue}) {
    return Color.fromRGBO(
      red ?? (r * 255.0).round().clamp(0, 255),
      green ?? (g * 255.0).round().clamp(0, 255),
      blue ?? (b * 255.0).round().clamp(0, 255),
      alpha ?? a,
    );
  }
}

/// Defines a complete color scheme for a theme.
class PaletteProfile {
  final String name;
  final Color primary;
  final Color secondary;
  final Color tertiary;
  final Color backgroundTop;
  final Color backgroundMiddle;
  final Color backgroundBottom;
  final Color accent;
  final Color glow;
  final Color textPrimary;
  final Color textSecondary;
  final Color formulaColor;
  final Color contrastFallback;

  const PaletteProfile({
    required this.name,
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.backgroundTop,
    required this.backgroundMiddle,
    required this.backgroundBottom,
    required this.accent,
    required this.glow,
    required this.textPrimary,
    required this.textSecondary,
    required this.formulaColor,
    required this.contrastFallback,
  });

  // Placeholder for automatic contrast adjustment.
  Color getAdjustedColor(Color color, Color backgroundColor) {
    // Implement contrast logic here later
    return color;
  }
}

/// Defines the visual identity of decorations for a theme.
class DecorationIdentity {
  final List<String> motifs; // e.g., ['lune', 'falci', 'stelle']
  // final CustomPainter painter; // This would be more complex to define here
  final double density;
  final List<String> preferredZones; // e.g., ['bordi', 'angoli']
  final double gothicIntensity;

  const DecorationIdentity({
    required this.motifs,
    // required this.painter,
    this.density = 1.0,
    this.preferredZones = const [],
    this.gothicIntensity = 0.0,
  });
}

/// Defines the GUI style for the main sheet and other core UI elements.
class MainSheetGuiStyle {
  // final ShapeBorder cardShape; // Placeholder
  // final BorderStyle borderStyle; // Placeholder
  // final PanelStyle panelStyle; // Placeholder
  // final SeparatorStyle separatorStyle; // Placeholder
  // final ButtonStyle buttonStyle; // Placeholder
  // final StatPanelStyle statPanelStyle; // Placeholder
  // final InventoryStyle inventoryStyle; // Placeholder
  // final NoteStyle noteStyle; // Placeholder
  // final DiaryStyle diaryStyle; // Placeholder
  // final FormulaStyle formulaStyle; // Placeholder
  final double densityLevel;

  const MainSheetGuiStyle({
    // required this.cardShape,
    // required this.borderStyle,
    // required this.panelStyle,
    // required this.separatorStyle,
    // required this.buttonStyle,
    // required this.statPanelStyle,
    // required this.inventoryStyle,
    // required this.noteStyle,
    // required this.diaryStyle,
    // required this.formulaStyle,
    this.densityLevel = 1.0,
  });
}

/// Combines all visual aspects of a theme.
class ThemeVisualIdentity {
  final PaletteProfile colorPalette;
  final DecorationIdentity decorationIdentity;
  final MainSheetGuiStyle mainSheetGuiStyle;
  final Color decorationTint;
  final double decorationOpacity;
  final double decorationGlow;

  const ThemeVisualIdentity({
    required this.colorPalette,
    required this.decorationIdentity,
    required this.mainSheetGuiStyle,
    this.decorationTint = Colors.white,
    this.decorationOpacity = 1.0,
    this.decorationGlow = 1.0,
  });
}

/// The complete theme skin, including painters for various elements.
class ThemeSkin {
  // final CustomPainter backgroundPainter; // Placeholder
  // final CustomPainter cardFramePainter; // Placeholder
  // final CustomPainter panelFramePainter; // Placeholder
  // final CustomPainter headerPainter; // Placeholder
  // final CustomPainter buttonPainter; // Placeholder
  // final CustomPainter separatorPainter; // Placeholder
  // final CustomPainter navbarPainter; // Placeholder
  // final CustomPainter decorationOverlayPainter; // Placeholder
  final double densityProfile;
  final double contrastProfile;

  const ThemeSkin({
    // required this.backgroundPainter,
    // required this.cardFramePainter,
    // required this.panelFramePainter,
    // required this.headerPainter,
    // required this.buttonPainter,
    // required this.separatorPainter,
    // required this.navbarPainter,
    // required this.decorationOverlayPainter,
    this.densityProfile = 1.0,
    this.contrastProfile = 1.0,
  });
}

// Predefined Palettes
class OculumPalettes {
  static const PaletteProfile verdigrisMourning = PaletteProfile(
    name: 'Verdigris Mourning',
    primary: Color(0xFF4A6B62), // Verde verderame / teal ossidato
    secondary: Color(0xFF3B2A4C), // Prugna scurissimo
    tertiary: Color(0xFFA28D3F), // Senape antica / oro spento
    backgroundTop: Color(0xFF2C3E4C), // Petrolio scuro
    backgroundMiddle: Color(0xFF382A3F), // Melanzana profonda
    backgroundBottom: Color(0xFF4F3A30), // Marrone rame bruciato
    accent: Color(0xFF9E5C5C), // Corallo spento o rosa ruggine
    glow: Color(
      0xFF8FFF00,
    ), // Verde acido molto controllato (will be toned down by decorationGlow)
    textPrimary: Color(0xFFF0F2E8), // Avorio sporco
    textSecondary: Color(0xFFB0C4B0), // Grigio salvia chiaro
    formulaColor: Color(
      0xFF4A6B62,
    ), // Verde verderame luminoso (will adjust contrast)
    contrastFallback: Colors.white, // Fallback for extreme low contrast
  );

  // Add other default palettes here
}
