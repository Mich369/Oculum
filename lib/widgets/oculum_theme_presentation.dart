import 'dart:convert';

import 'oculum_custom_theme.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'oculum_goth_ornaments.dart';
import 'oculum_theme_asset_packs.dart';
import 'oculum_combat_theme.dart';
import 'oculum_monster_theme.dart';

enum OculumThemeMotion { complete, reduced, disabled }

/// Two structural art treatments that can be selected without changing the
/// active theme, palette, screen layout, or any control behavior.
enum OculumThemeVariant { still, alive }

@immutable
class OculumThemePresentation {
  const OculumThemePresentation({
    this.motion = OculumThemeMotion.complete,
    this.variant = OculumThemeVariant.still,
    this.relicScale = 1,
    this.relicOpacity = .8,
    this.surfaceTransparency = .18,
    this.artPackId = '',
  });
  final OculumThemeMotion motion;
  final OculumThemeVariant variant;
  final double relicScale, relicOpacity;

  /// Only the backing surfaces fade; labels and input stay fully visible.
  final double surfaceTransparency;
  final String artPackId;
  OculumThemePresentation copyWith({
    OculumThemeMotion? motion,
    OculumThemeVariant? variant,
    double? relicScale,
    double? relicOpacity,
    double? surfaceTransparency,
    String? artPackId,
  }) => OculumThemePresentation(
    motion: motion ?? this.motion,
    variant: variant ?? this.variant,
    relicScale: (relicScale ?? this.relicScale).clamp(.7, 1.3),
    relicOpacity: (relicOpacity ?? this.relicOpacity).clamp(.25, 1),
    surfaceTransparency: (surfaceTransparency ?? this.surfaceTransparency)
        .clamp(0, .4),
    artPackId: artPackId ?? this.artPackId,
  );
}

final oculumThemePresentation = ValueNotifier(const OculumThemePresentation());
final ValueNotifier<Map<String, String>> oculumSheetRelicSelections =
    ValueNotifier(<String, String>{});

Future<void> loadOculumThemePresentation() async {
  await loadOculumCustomArtwork();
  final prefs = await SharedPreferences.getInstance();
  final savedSheetRelics = prefs.getString('oculum.sheetRelicSelections');
  if (savedSheetRelics == null) {
    oculumSheetRelicSelections.value = <String, String>{};
  } else {
    try {
      final decoded = jsonDecode(savedSheetRelics);
      if (decoded is Map) {
        oculumSheetRelicSelections.value = {
          for (final entry in decoded.entries)
            if (entry.key is String && entry.value is String)
              entry.key as String: entry.value as String,
        };
      }
    } on FormatException {
      oculumSheetRelicSelections.value = <String, String>{};
    }
  }
  final name = prefs.getString('oculum.themeMotion');
  oculumThemePresentation.value = OculumThemePresentation(
    motion: OculumThemeMotion.values.firstWhere(
      (item) => item.name == name,
      orElse: () => OculumThemeMotion.complete,
    ),
    variant: OculumThemeVariant.values.firstWhere(
      (item) => item.name == prefs.getString('oculum.themeVariant'),
      orElse: () => OculumThemeVariant.still,
    ),
    relicScale: (prefs.getDouble('oculum.themeRelicScale') ?? 1).clamp(.7, 1.3),
    relicOpacity: (prefs.getDouble('oculum.themeRelicOpacity') ?? .8).clamp(
      .25,
      1,
    ),
    surfaceTransparency: (prefs.getDouble('oculum.surfaceTransparency') ?? .18)
        .clamp(0, .4),
    // An empty preference means that the player has never selected the Home
    // artwork. Choose an image pack for this launch, but do not persist it:
    // the next launch can choose again, while an explicit selection remains
    // stable through setOculumThemePresentation.
    artPackId: () {
      final selected = prefs.getString('oculum.themeArtPack') ?? '';
      if (selected.isNotEmpty) return selected;
      return '';
    }(),
  );
}

OculumThemePresentation oculumThemePresentationForSheet(String sheetId) {
  final id = sheetId.trim();
  final selected = id.isEmpty ? null : oculumSheetRelicSelections.value[id];
  final effective = selected ?? oculumSheetMonsterThemes.value[id];
  return effective == null
      ? oculumThemePresentation.value
      : oculumThemePresentation.value.copyWith(artPackId: effective);
}

Future<void> setOculumSheetRelic(String sheetId, String artPackId) async {
  final key = sheetId.trim();
  if (key.isEmpty) return;
  final selections = Map<String, String>.of(oculumSheetRelicSelections.value);
  if (artPackId.isEmpty) {
    selections.remove(key);
  } else {
    selections[key] = artPackId;
  }
  oculumSheetRelicSelections.value = selections;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('oculum.sheetRelicSelections', jsonEncode(selections));
}

Future<void> setOculumThemePresentation(OculumThemePresentation value) async {
  oculumThemePresentation.value = value;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('oculum.themeMotion', value.motion.name);
  await prefs.setString('oculum.themeVariant', value.variant.name);
  await prefs.setDouble('oculum.themeRelicScale', value.relicScale);
  await prefs.setDouble('oculum.themeRelicOpacity', value.relicOpacity);
  await prefs.setDouble(
    'oculum.surfaceTransparency',
    value.surfaceTransparency,
  );
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
    builder: (context, value, _) {
      final family = Theme.of(context).extension<OculumGothOrnaments>()?.family;
      final stillLabel = switch (family) {
        OculumGothFamily.botanical =>
          english ? 'Still nature · dry stems' : 'Natura morta · steli secchi',
        OculumGothFamily.dream =>
          english ? 'Quiet dream · blue clouds' : 'Sogno quieto · nubi blu',
        OculumGothFamily.wood => english ? 'Aged walnut' : 'Noce consumato',
        OculumGothFamily.ash => english ? 'Settled ash' : 'Cenere depositata',
        OculumGothFamily.acid => english ? 'Toxic glass' : 'Vetro tossico',
        OculumGothFamily.spirit => english ? 'Resting souls' : 'Anime quiete',
        _ => english ? 'Worn engraving' : 'Incisione consumata',
      };
      final aliveLabel = switch (family) {
        OculumGothFamily.botanical =>
          english
              ? 'Living nature · violet blooms'
              : 'Natura viva · fiori viola',
        OculumGothFamily.dream =>
          english
              ? 'Chromatic dream · blue, violet, pastel pink'
              : 'Sogno cromatico · blu, viola e rosa pastello',
        OculumGothFamily.wood => english ? 'Carved walnut' : 'Noce intagliato',
        OculumGothFamily.ash => english ? 'Ash and soot' : 'Cenere e fuliggine',
        OculumGothFamily.acid =>
          english ? 'Dripping acid glass' : 'Vetro d acido colante',
        OculumGothFamily.spirit =>
          english ? 'Circling pale souls' : 'Anime pallide in orbita',
        _ => english ? 'Awakened ornament' : 'Ornamento risvegliato',
      };
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: const Icon(Icons.layers_outlined),
            title: Text(
              english
                  ? 'Panel and button transparency'
                  : 'Trasparenza pannelli e pulsanti',
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  english
                      ? 'Only the backing fades. Text and icons stay visible; hover or keyboard focus restores the surface.'
                      : 'Schiarisce solo le superfici: testi e icone restano visibili. Mouse e focus ripristinano la superficie.',
                ),
                Slider(
                  key: const ValueKey('surface-transparency'),
                  value: value.surfaceTransparency,
                  min: 0,
                  max: .4,
                  divisions: 20,
                  label: '${(value.surfaceTransparency * 100).round()}%',
                  semanticFormatterCallback: (v) => '${(v * 100).round()}%',
                  onChanged: (v) => oculumThemePresentation.value = value
                      .copyWith(surfaceTransparency: v),
                  onChangeEnd: (_) =>
                      setOculumThemePresentation(oculumThemePresentation.value),
                ),
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('${(value.surfaceTransparency * 100).round()}%'),
                    TextButton(
                      key: const ValueKey('surface-transparency-reset'),
                      onPressed: () => setOculumThemePresentation(
                        value.copyWith(surfaceTransparency: .18),
                      ),
                      child: Text(
                        english
                            ? 'Restore recommended · 18%'
                            : 'Ripristina consigliato · 18%',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.auto_awesome_outlined),
            title: Text(english ? 'Theme animations' : 'Animazioni tema'),
            subtitle: Text(
              english
                  ? 'Static artwork remains visible when motion is disabled.'
                  : 'I PNG restano visibili anche con le animazioni disattivate.',
            ),
          ),
          ValueListenableBuilder<OculumCombatThemeState>(
            valueListenable: oculumCombatTheme,
            builder: (context, combat, _) => SwitchListTile.adaptive(
              secondary: const Icon(Icons.bolt_outlined),
              title: Text(
                english
                    ? 'Combat material response'
                    : 'Tema reattivo al combattimento',
              ),
              subtitle: Text(
                combat.elementId.isEmpty
                    ? (combat.automatic
                          ? (english
                                ? 'Automatic · changes after a typed attack is resolved.'
                                : 'Automatico · cambia dopo la risoluzione di un attacco elementale.')
                          : (english
                                ? 'Off · the selected theme stays in control.'
                                : 'Disattivato · resta attivo il tema selezionato.'))
                    : (english
                          ? 'Last resolved attack: ${combat.elementId}${combat.secondaryElementId.isEmpty ? '' : ' + ${combat.secondaryElementId}'}.'
                          : 'Ultimo attacco risolto: ${combat.elementId}${combat.secondaryElementId.isEmpty ? '' : ' + ${combat.secondaryElementId}'}.'),
              ),
              value: combat.automatic,
              onChanged: oculumCombatTheme.setAutomatic,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
            child: DropdownButtonFormField<OculumThemeVariant>(
              key: ValueKey('theme-variant-${value.variant.name}'),
              initialValue: value.variant,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: english ? 'Artwork variant' : 'Variante illustrata',
              ),
              items: [
                DropdownMenuItem(
                  value: OculumThemeVariant.still,
                  child: Text(stillLabel, overflow: TextOverflow.ellipsis),
                ),
                DropdownMenuItem(
                  value: OculumThemeVariant.alive,
                  child: Text(aliveLabel, overflow: TextOverflow.ellipsis),
                ),
              ],
              onChanged: (variant) {
                if (variant != null) {
                  setOculumThemePresentation(value.copyWith(variant: variant));
                }
              },
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
      );
    },
  );
}
