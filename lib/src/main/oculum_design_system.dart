part of '../../main.dart';

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
      color: Color.lerp(cathedralStone, surface, elevated ? 0.56 : 0.24),
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
