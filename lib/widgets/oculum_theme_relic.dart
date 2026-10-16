import 'package:flutter/material.dart';
import 'oculum_goth_ornaments.dart';
import 'oculum_theme_asset_packs.dart';
import 'oculum_theme_presentation.dart';
import 'oculum_element_theme_registry.dart';

OculumThemeAssetPack oculumResolveThemeArt(
  OculumGothOrnaments spec,
  OculumThemePresentation presentation,
) =>
    oculumThemeAssetPacks[presentation.artPackId] ??
    oculumThemeAssetPacks[spec.themeId] ??
    oculumThemeAssetPacks[oculumElementThemePackIds[spec.themeId.startsWith(
          'element_',
        )
        ? spec.themeId.substring(8)
        : '']] ??
    oculumThemeAssetPacks[switch (spec.family) {
      OculumGothFamily.botanical => 'vervain_gothic',
      OculumGothFamily.crystal => 'frost_chapel',
      OculumGothFamily.forged => 'bolted_black_iron',
      OculumGothFamily.astral => 'lunar_eclipse',
      OculumGothFamily.tide => 'abyssal_tide',
      OculumGothFamily.ember => 'ember_rite',
      OculumGothFamily.dream => 'restyle_sogno',
      OculumGothFamily.wood => 'restyle_legno',
      OculumGothFamily.ash => 'restyle_cenere',
      OculumGothFamily.acid => 'restyle_acido',
      OculumGothFamily.spirit => 'restyle_spiritualita',
      _ => 'classic_reliquary',
    }]!;

/// Gives legacy panels the selected theme's engraved edge without putting
/// artwork behind text or over interactive controls.
class OculumThemePanelArtwork extends StatelessWidget {
  const OculumThemePanelArtwork({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final spec = Theme.of(context).extension<OculumGothOrnaments>();
    if (spec == null ||
        spec.themeId.isEmpty ||
        spec.family == OculumGothFamily.none ||
        spec.opacity <= 0) {
      return child;
    }
    return ValueListenableBuilder<OculumThemePresentation>(
      valueListenable: oculumThemePresentation,
      child: child,
      builder: (context, presentation, child) => CustomPaint(
        foregroundPainter: OculumGothPainter(
          spec.copyWith(variant: presentation.variant),
          panel: true,
        ),
        child: child,
      ),
    );
  }
}

/// A small, text-first theme signature. It uses no default eye or reliquary
/// image; the selected theme is identified by its own palette and motif.
class OculumThemeRelicBanner extends StatelessWidget {
  const OculumThemeRelicBanner({super.key, this.dense = false});
  final bool dense;

  IconData _iconFor(OculumGothFamily family) => switch (family) {
    OculumGothFamily.botanical => Icons.local_florist_outlined,
    OculumGothFamily.crystal => Icons.diamond_outlined,
    OculumGothFamily.forged => Icons.hardware_outlined,
    OculumGothFamily.astral => Icons.auto_awesome_outlined,
    OculumGothFamily.tide => Icons.waves_outlined,
    OculumGothFamily.ember => Icons.local_fire_department_outlined,
    OculumGothFamily.cathedral => Icons.architecture_outlined,
    OculumGothFamily.dream => Icons.cloud_outlined,
    OculumGothFamily.wood => Icons.forest_outlined,
    OculumGothFamily.ash => Icons.blur_on_outlined,
    OculumGothFamily.acid => Icons.opacity_outlined,
    OculumGothFamily.spirit => Icons.blur_circular_outlined,
    OculumGothFamily.none => Icons.shield_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final spec = Theme.of(context).extension<OculumGothOrnaments>();
    if (spec == null || spec.themeId.isEmpty) return const SizedBox.shrink();
    return ValueListenableBuilder<OculumThemePresentation>(
      valueListenable: oculumThemePresentation,
      builder: (context, presentation, _) {
        final pack = oculumResolveThemeArt(spec, presentation);
        final showThemeArtwork =
            pack.id != 'classic_reliquary' && pack.id != 'classic_low_detail';
        final theme = Theme.of(context);
        final accent = spec.accent;
        final iconSize = dense ? 30.0 : 42.0;
        return Container(
          margin: EdgeInsets.symmetric(vertical: dense ? 4 : 10),
          padding: EdgeInsets.symmetric(
            horizontal: dense ? 10 : 14,
            vertical: dense ? 7 : 11,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh.withValues(
              alpha: .72,
            ),
            borderRadius: BorderRadius.circular(dense ? 8 : 12),
            border: Border.all(color: accent.withValues(alpha: .52)),
          ),
          child: Row(
            children: [
              Container(
                width: dense ? 38 : 52,
                height: dense ? 38 : 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: accent.withValues(alpha: .72)),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accent.withValues(alpha: .2),
                      spec.ink.withValues(alpha: .16),
                    ],
                  ),
                ),
                child: showThemeArtwork
                    ? ExcludeSemantics(
                        child: Opacity(
                          opacity: presentation.relicOpacity,
                          child: Image.asset(
                            pack.relic,
                            width: iconSize,
                            height: iconSize,
                            cacheWidth:
                                (iconSize *
                                        MediaQuery.devicePixelRatioOf(context))
                                    .round()
                                    .clamp(96, 384),
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.medium,
                            errorBuilder: (_, _, _) => Icon(
                              _iconFor(spec.family),
                              size: iconSize,
                              color: accent,
                            ),
                          ),
                        ),
                      )
                    : Icon(
                        _iconFor(spec.family),
                        size: iconSize,
                        color: accent,
                        semanticLabel: null,
                      ),
              ),
              SizedBox(width: dense ? 9 : 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pack.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: dense
                          ? theme.textTheme.labelLarge
                          : theme.textTheme.titleMedium,
                    ),
                    if (!dense) const SizedBox(height: 3),
                    Text(
                      pack.motif,
                      maxLines: dense ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: .78,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
