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
        return GestureDetector(
          onTap: () => showOculumRelicPicker(context),
          child: Container(
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
                                          MediaQuery.devicePixelRatioOf(
                                            context,
                                          ))
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
          ),
        );
      },
    );
  }
}

Future<void> showOculumRelicPicker(BuildContext context) async {
  var query = '';
  final selected = await showDialog<String>(
    context: context,
    builder: (dialog) => StatefulBuilder(
      builder: (context, update) {
        final matches = oculumThemeAssetPacks.values.where((pack) {
          final text = '${pack.id} ${pack.name} ${pack.motif}'.toLowerCase();
          final search = query.toLowerCase().trim();
          return text.contains(search) ||
              (search == 'acqua' &&
                  RegExp(
                    'water|tide|mare|abis|onda|ocean|acqua',
                  ).hasMatch(text));
        }).toList();
        return AlertDialog(
          title: const Text('Reliquie Oculum'),
          content: SizedBox(
            width: 520,
            height: MediaQuery.sizeOf(context).height * .55,
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Cerca nome o elemento',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) => update(() => query = value),
                ),
                TextButton.icon(
                  onPressed: () => Navigator.pop(dialog, ''),
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Predefinita del tema attuale'),
                ),
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          childAspectRatio: .85,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                        ),
                    itemCount: matches.length,
                    itemBuilder: (context, index) {
                      final pack = matches[index];
                      return InkWell(
                        onTap: () => Navigator.pop(dialog, pack.id),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(5),
                            child: Column(
                              children: [
                                Expanded(
                                  child: Image.asset(
                                    pack.relic,
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.high,
                                    cacheWidth: 256,
                                    errorBuilder: (_, _, _) =>
                                        const Icon(Icons.diamond_outlined),
                                  ),
                                ),
                                Text(
                                  pack.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: const Text('Chiudi'),
            ),
          ],
        );
      },
    ),
  );
  if (selected != null) {
    await setOculumThemePresentation(
      oculumThemePresentation.value.copyWith(artPackId: selected),
    );
  }
}
