import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'oculum_goth_ornaments.dart';

/// Theme feedback driven only by damage that has already been resolved.
/// It deliberately does not participate in damage, resistance, or cost math.
@immutable
class OculumCombatThemeState {
  const OculumCombatThemeState({
    this.automatic = false,
    this.elementId = '',
    this.secondaryElementId = '',
    this.actionId = '',
    this.reaction = '',
    this.reactionElementId = '',
    this.revision = 0,
  });

  final bool automatic;
  final String elementId;
  final String secondaryElementId;
  final String actionId;
  final String reaction;
  final String reactionElementId;
  final int revision;

  OculumGothFamily? get activeFamily => oculumCombatElementFamily(elementId);

  OculumGothFamily? get secondaryFamily =>
      oculumCombatElementFamily(secondaryElementId);

  OculumGothFamily? get reactionFamily =>
      oculumCombatElementFamily(reactionElementId);
}

/// Single source for mapping Oculum's resolved damage identifiers to visual
/// material families. Unknown/custom elements leave the selected theme alone.
OculumGothFamily? oculumCombatElementFamily(String rawElementId) {
  final id = oculumCombatElementId(rawElementId);
  return switch (id) {
    'fuoco' || 'lava' || 'plasma' || 'esplosivo' => OculumGothFamily.ember,
    'gelo' || 'cristallo' => OculumGothFamily.crystal,
    'acqua' => OculumGothFamily.tide,
    'vento' ||
    'natura' ||
    'pianta' ||
    'radice' ||
    'bestiale' => OculumGothFamily.botanical,
    'veleno' ||
    'corrotto' ||
    'maledizione' ||
    'slime' => OculumGothFamily.botanical,
    'acido' => OculumGothFamily.acid,
    'cenere' => OculumGothFamily.ash,
    'terra' || 'vero' => OculumGothFamily.cathedral,
    'sconosciuto' => OculumGothFamily.cathedral,
    'metallo' ||
    'tecnologia' ||
    'proiettile' ||
    'taglio' ||
    'perforante' ||
    'contundente' ||
    'fisico' => OculumGothFamily.forged,
    'postea' || 'ruggine' => OculumGothFamily.forged,
    'sogno' => OculumGothFamily.dream,
    'lunare' ||
    'solare' ||
    'stella' ||
    'oculum' ||
    'psichico' ||
    'energia' ||
    'fulmine' ||
    'radiazione' ||
    'laser' ||
    'gravita' ||
    'tempo' ||
    'spazio' ||
    'vuoto' => OculumGothFamily.astral,
    'sonoro' || 'magia' || 'vapium' || 'specchio' => OculumGothFamily.astral,
    'sangue' => OculumGothFamily.ember,
    'oscuro' ||
    'diabolico' ||
    'necrotico' ||
    'nonmorto' ||
    'osso' ||
    'caos' => OculumGothFamily.cathedral,
    'spirituale' => OculumGothFamily.spirit,
    'sacro' || 'angelico' || 'benedizione' || 'cura' => OculumGothFamily.astral,
    _ => null,
  };
}

String oculumCombatElementId(String value) {
  final normalized = value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp('[àáâä]'), 'a')
      .replaceAll(RegExp('[èéêë]'), 'e')
      .replaceAll(RegExp('[ìíîï]'), 'i')
      .replaceAll(RegExp('[òóôö]'), 'o')
      .replaceAll(RegExp('[ùúûü]'), 'u')
      .replaceAll(RegExp('[^a-z0-9]+'), '');
  return const <String, String>{
        'physical': 'fisico',
        'slash': 'taglio',
        'cut': 'taglio',
        'piercing': 'perforante',
        'pierce': 'perforante',
        'blunt': 'contundente',
        'impact': 'contundente',
        'fire': 'fuoco',
        'ice': 'gelo',
        'ghiaccio': 'gelo',
        'spiritualita': 'spirituale',
        'water': 'acqua',
        'lightning': 'fulmine',
        'electric': 'fulmine',
        'earth': 'terra',
        'wind': 'vento',
        'poison': 'veleno',
        'acid': 'acido',
        'dark': 'oscuro',
        'holy': 'sacro',
        'moon': 'lunare',
        'sun': 'solare',
        'psychic': 'psichico',
        'spirit': 'spirituale',
        'necrotic': 'necrotico',
        'blood': 'sangue',
        'ash': 'cenere',
        'bone': 'osso',
        'crystal': 'cristallo',
        'dream': 'sogno',
        'metal': 'metallo',
        'root': 'radice',
        'star': 'stella',
        'undead': 'nonmorto',
        'magic': 'energia',
        'energy': 'energia',
        'explosive': 'esplosivo',
        'radiation': 'radiazione',
        'technology': 'tecnologia',
        'bullet': 'proiettile',
        'gravity': 'gravita',
        'time': 'tempo',
        'space': 'spazio',
        'void': 'vuoto',
        'chaos': 'caos',
        'nature': 'natura',
        'beast': 'bestiale',
        'curse': 'maledizione',
        'blessing': 'benedizione',
        'healing': 'cura',
        'true': 'vero',
        'unknown': 'sconosciuto',
      }[normalized] ??
      normalized;
}

class OculumCombatThemeController
    extends ValueNotifier<OculumCombatThemeState> {
  OculumCombatThemeController() : super(const OculumCombatThemeState());

  Future<void> loadPreference() async {
    final enabled =
        (await SharedPreferences.getInstance()).getBool(
          'oculum.combatThemeAutomatic',
        ) ??
        false;
    value = OculumCombatThemeState(
      automatic: enabled,
      elementId: value.elementId,
      secondaryElementId: value.secondaryElementId,
      actionId: value.actionId,
      reaction: value.reaction,
      reactionElementId: value.reactionElementId,
      revision: value.revision + 1,
    );
  }

  Future<void> setAutomatic(bool enabled) async {
    value = OculumCombatThemeState(
      automatic: enabled,
      elementId: value.elementId,
      secondaryElementId: value.secondaryElementId,
      actionId: value.actionId,
      reaction: value.reaction,
      reactionElementId: value.reactionElementId,
      revision: value.revision + 1,
    );
    await (await SharedPreferences.getInstance()).setBool(
      'oculum.combatThemeAutomatic',
      enabled,
    );
  }

  /// Resolves a whole action, summing each hit by its final damage type before
  /// selecting one material. The 90% secondary threshold is shared by all
  /// attacks, so small elemental fragments do not cause theme flicker.
  bool resolveOutgoingAction({
    required String actionId,
    required Iterable<Map<String, int>> hitDamageByElement,
    bool normalAction = false,
  }) {
    if (!value.automatic || actionId.isEmpty || actionId == value.actionId) {
      return false;
    }
    if (normalAction) return false;

    final totalByElement = <String, int>{};
    final firstSeen = <String, int>{};
    for (final hit in hitDamageByElement) {
      for (final entry in hit.entries) {
        final amount = entry.value;
        if (amount <= 0) continue;
        final id = oculumCombatElementId(entry.key);
        if (oculumCombatElementFamily(id) == null) continue;
        firstSeen.putIfAbsent(id, () => firstSeen.length);
        totalByElement.update(
          id,
          (total) => total + amount,
          ifAbsent: () => amount,
        );
      }
    }
    if (totalByElement.isEmpty) return false;

    final ordered = totalByElement.entries.toList()
      ..sort((a, b) {
        final byDamage = b.value.compareTo(a.value);
        return byDamage != 0
            ? byDamage
            : firstSeen[a.key]!.compareTo(firstSeen[b.key]!);
      });
    final primary = ordered.first;
    final secondary = ordered.skip(1).firstOrNull;
    final secondaryId =
        secondary != null && secondary.value * 100 >= primary.value * 90
        ? secondary.key
        : '';
    value = OculumCombatThemeState(
      automatic: true,
      elementId: primary.key,
      secondaryElementId: secondaryId,
      actionId: actionId,
      reaction: value.reaction,
      reactionElementId: value.reactionElementId,
      revision: value.revision + 1,
    );
    return true;
  }

  /// Reactions are cosmetic and never replace the offensive material choice.
  void react(String kind, {String elementId = ''}) {
    value = OculumCombatThemeState(
      automatic: value.automatic,
      elementId: value.elementId,
      secondaryElementId: value.secondaryElementId,
      actionId: value.actionId,
      reaction: kind,
      reactionElementId: elementId.isEmpty ? value.elementId : elementId,
      revision: value.revision + 1,
    );
  }

  void clearReaction(int expectedRevision) {
    if (value.revision != expectedRevision || value.reaction.isEmpty) return;
    value = OculumCombatThemeState(
      automatic: value.automatic,
      elementId: value.elementId,
      secondaryElementId: value.secondaryElementId,
      actionId: value.actionId,
      revision: value.revision + 1,
    );
  }
}

final oculumCombatTheme = OculumCombatThemeController();

class OculumCombatReactionOverlay extends StatelessWidget {
  const OculumCombatReactionOverlay({
    super.key,
    required this.state,
    this.transitionDuration = const Duration(milliseconds: 120),
  });

  final OculumCombatThemeState state;
  final Duration transitionDuration;

  @override
  Widget build(BuildContext context) {
    final familyColor = switch (state.reactionFamily) {
      OculumGothFamily.ember => const Color(0xFFE7A15A),
      OculumGothFamily.crystal => const Color(0xFF9BCFE1),
      OculumGothFamily.tide => const Color(0xFF7CC7D0),
      OculumGothFamily.botanical => const Color(0xFFA8C68D),
      OculumGothFamily.forged => const Color(0xFFC2A786),
      OculumGothFamily.astral => const Color(0xFFB9A2E1),
      OculumGothFamily.dream => const Color(0xFFC2A9DD),
      OculumGothFamily.wood => const Color(0xFFC6A475),
      OculumGothFamily.ash => const Color(0xFFBDB8AF),
      OculumGothFamily.acid => const Color(0xFFC2E36E),
      OculumGothFamily.spirit => const Color(0xFFE8EAF0),
      OculumGothFamily.cathedral ||
      OculumGothFamily.none ||
      null => const Color(0xFFC8C0D5),
    };
    final color = switch (state.reaction) {
      'critical' => const Color(0xFFFFD18A),
      'resisted' || 'parry' || 'blocked' => const Color(0xFF8DD8D1),
      'vulnerable' || 'open' => const Color(0xFFE58D83),
      'heal' || 'shield' => const Color(0xFFB7D69A),
      'outgoing' => const Color(0xFFE4B77D),
      'dodge' => const Color(0xFF9CD9E5),
      'shieldBreak' => const Color(0xFFDBA3CF),
      _ => familyColor,
    };
    return IgnorePointer(
      child: ExcludeSemantics(
        child: AnimatedSwitcher(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : transitionDuration,
          child: state.reaction.isEmpty
              ? const SizedBox.shrink(key: ValueKey('combat-reaction-empty'))
              : CustomPaint(
                  key: ValueKey('combat-reaction-${state.revision}'),
                  painter: _OculumCombatReactionPainter(color: color),
                ),
        ),
      ),
    );
  }
}

class OculumCombatReactionHost extends StatefulWidget {
  const OculumCombatReactionHost({
    super.key,
    required this.state,
    this.transitionDuration = const Duration(milliseconds: 120),
  });

  final OculumCombatThemeState state;
  final Duration transitionDuration;

  @override
  State<OculumCombatReactionHost> createState() =>
      _OculumCombatReactionHostState();
}

class _OculumCombatReactionHostState extends State<OculumCombatReactionHost> {
  Timer? _expiry;
  var _expiredRevision = -1;

  @override
  void initState() {
    super.initState();
    _scheduleExpiry();
  }

  @override
  void didUpdateWidget(covariant OculumCombatReactionHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.revision != widget.state.revision) {
      _scheduleExpiry();
    }
  }

  void _scheduleExpiry() {
    _expiry?.cancel();
    final revision = widget.state.revision;
    if (widget.state.reaction.isEmpty) {
      _expiredRevision = -1;
      return;
    }
    _expiredRevision = -1;
    _expiry = Timer(const Duration(milliseconds: 760), () {
      if (!mounted) return;
      setState(() => _expiredRevision = revision);
      oculumCombatTheme.clearReaction(revision);
    });
  }

  @override
  void dispose() {
    _expiry?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => OculumCombatReactionOverlay(
    state: _expiredRevision == widget.state.revision
        ? OculumCombatThemeState(
            automatic: widget.state.automatic,
            elementId: widget.state.elementId,
            secondaryElementId: widget.state.secondaryElementId,
            actionId: widget.state.actionId,
            revision: widget.state.revision,
          )
        : widget.state,
    transitionDuration: widget.transitionDuration,
  );
}

class _OculumCombatReactionPainter extends CustomPainter {
  const _OculumCombatReactionPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final edgePaint = Paint()
      ..color = color.withValues(alpha: .11)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    final innerPaint = Paint()
      ..color = color.withValues(alpha: .045)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7;
    final rect = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(3), const Radius.circular(12)),
      innerPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(2), const Radius.circular(12)),
      edgePaint,
    );
  }

  @override
  bool shouldRepaint(_OculumCombatReactionPainter oldDelegate) =>
      oldDelegate.color != color;
}
