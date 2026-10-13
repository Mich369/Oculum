import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'oculum_theme_asset_packs.dart';

enum OculumThemeMotion { complete, reduced, disabled }

@immutable
class OculumThemePresentation {
  const OculumThemePresentation({
    this.motion = OculumThemeMotion.complete,
    this.relicScale = 1,
    this.relicOpacity = .8,
    this.artPackId = '',
  });
  final OculumThemeMotion motion;
  final double relicScale, relicOpacity;
  final String artPackId;
  OculumThemePresentation copyWith({
    OculumThemeMotion? motion,
    double? relicScale,
    double? relicOpacity,
    String? artPackId,
  }) => OculumThemePresentation(
    motion: motion ?? this.motion,
    relicScale: (relicScale ?? this.relicScale).clamp(.7, 1.3),
    relicOpacity: (relicOpacity ?? this.relicOpacity).clamp(.25, 1),
    artPackId: artPackId ?? this.artPackId,
  );
}

final oculumThemePresentation = ValueNotifier(const OculumThemePresentation());

Future<void> loadOculumThemePresentation() async {
  final prefs = await SharedPreferences.getInstance();
  final name = prefs.getString('oculum.themeMotion');
  oculumThemePresentation.value = OculumThemePresentation(
    motion: OculumThemeMotion.values.firstWhere(
      (item) => item.name == name,
      orElse: () => OculumThemeMotion.complete,
    ),
    relicScale: (prefs.getDouble('oculum.themeRelicScale') ?? 1).clamp(.7, 1.3),
    relicOpacity: (prefs.getDouble('oculum.themeRelicOpacity') ?? .8).clamp(
      .25,
      1,
    ),
    artPackId: prefs.getString('oculum.themeArtPack') ?? '',
  );
}

Future<void> setOculumThemePresentation(OculumThemePresentation value) async {
  oculumThemePresentation.value = value;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('oculum.themeMotion', value.motion.name);
  await prefs.setDouble('oculum.themeRelicScale', value.relicScale);
  await prefs.setDouble('oculum.themeRelicOpacity', value.relicOpacity);
  await prefs.setString('oculum.themeArtPack', value.artPackId);
}

class OculumThemePresentationControls extends StatelessWidget {
  const OculumThemePresentationControls({super.key, this.english = false});
  final bool english;
  @override
  Widget build(
    BuildContext context,
  ) => ValueListenableBuilder<OculumThemePresentation>(
    valueListenable: oculumThemePresentation,
    builder: (context, value, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          leading: const Icon(Icons.auto_awesome_outlined),
          title: Text(english ? 'Theme animations' : 'Animazioni tema'),
          subtitle: Text(
            english
                ? 'Static artwork remains visible when motion is disabled.'
                : 'I PNG restano visibili anche con le animazioni disattivate.',
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonFormField<OculumThemeMotion>(
            key: ValueKey('theme-motion-${value.motion.name}'),
            initialValue: value.motion,
            decoration: InputDecoration(
              labelText: english ? 'Motion' : 'Movimento',
            ),
            items: [
              for (final motion in OculumThemeMotion.values)
                DropdownMenuItem(
                  value: motion,
                  child: Text(switch (motion) {
                    OculumThemeMotion.complete =>
                      english ? 'Complete' : 'Complete',
                    OculumThemeMotion.reduced =>
                      english ? 'Reduced' : 'Ridotte',
                    OculumThemeMotion.disabled =>
                      english ? 'Disabled' : 'Disattivate',
                  }),
                ),
            ],
            onChanged: (motion) {
              if (motion != null) {
                setOculumThemePresentation(value.copyWith(motion: motion));
              }
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
          child: DropdownButtonFormField<String>(
            key: ValueKey('theme-art-pack-${value.artPackId}'),
            initialValue: oculumThemeAssetPacks.containsKey(value.artPackId)
                ? value.artPackId
                : '',
            isExpanded: true,
            decoration: InputDecoration(
              labelText: english ? 'Relic artwork' : 'Reliquia del tema',
            ),
            items: [
              DropdownMenuItem(
                value: '',
                child: Text(
                  english
                      ? 'Follow selected theme'
                      : 'Segui il tema selezionato',
                ),
              ),
              for (final pack in oculumThemeAssetPacks.values)
                DropdownMenuItem(
                  value: pack.id,
                  child: Text(pack.name, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (id) {
              if (id != null) {
                setOculumThemePresentation(value.copyWith(artPackId: id));
              }
            },
          ),
        ),
        ListTile(
          title: Text(english ? 'Relic size' : 'Dimensione reliquie'),
          subtitle: Slider(
            value: value.relicScale,
            min: .7,
            max: 1.3,
            divisions: 6,
            label: '${(value.relicScale * 100).round()}%',
            onChanged: (scale) => oculumThemePresentation.value = value
                .copyWith(relicScale: scale),
            onChangeEnd: (_) =>
                setOculumThemePresentation(oculumThemePresentation.value),
          ),
        ),
        ListTile(
          title: Text(english ? 'Relic visibility' : 'Visibilità reliquie'),
          subtitle: Slider(
            value: value.relicOpacity,
            min: .25,
            max: 1,
            divisions: 15,
            label: '${(value.relicOpacity * 100).round()}%',
            onChanged: (opacity) => oculumThemePresentation.value = value
                .copyWith(relicOpacity: opacity),
            onChangeEnd: (_) =>
                setOculumThemePresentation(oculumThemePresentation.value),
          ),
        ),
      ],
    ),
  );
}
