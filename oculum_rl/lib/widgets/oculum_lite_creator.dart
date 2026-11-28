import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../game/oculum_lite_run.dart';
import '../services/oculum_lite_saves.dart';
import 'oculum_lite_arena.dart';

typedef OculumLiteCreation = ({String name, OculumLiteAppearance appearance});

Future<OculumLiteCreation?> editOculumLiteAppearance(
  BuildContext context, {
  required OculumLiteAppearance appearance,
  required LiteWeapon weapon,
  required String name,
}) => showDialog<OculumLiteCreation>(
  context: context,
  builder: (context) =>
      _Creator(appearance: appearance, weapon: weapon, name: name),
);

class _Creator extends StatefulWidget {
  const _Creator({
    required this.appearance,
    required this.weapon,
    required this.name,
  });

  final OculumLiteAppearance appearance;
  final LiteWeapon weapon;
  final String name;

  @override
  State<_Creator> createState() => _CreatorState();
}

enum _CreatorPose {
  posa('Posa'),
  cammina('Cammina'),
  corri('Corri'),
  scatto('Scatto'),
  attacco('Attacco');

  const _CreatorPose(this.label);
  final String label;
}

enum _CreatorSection {
  identity('Identità', Icons.person_outline),
  face('Volto', Icons.face_outlined),
  gear('Tenuta', Icons.shield_outlined),
  colors('Colori', Icons.palette_outlined);

  const _CreatorSection(this.label, this.icon);
  final String label;
  final IconData icon;
}

class _CreatorState extends State<_Creator> {
  late final _name = TextEditingController(text: widget.name);
  late var _look = widget.appearance;
  late var _weapon = widget.weapon;
  final _random = Random();
  final _previewAnchor = GlobalKey();
  final _sections = {
    for (final section in _CreatorSection.values) section: GlobalKey(),
  };
  var _pose = _CreatorPose.posa;
  var _take = 0;
  var _showClone = true;
  var _zoomed = false;
  var _readingSaves = false;

  void _change(OculumLiteAppearance appearance) =>
      setState(() => _look = appearance);

  Future<void> _loadSavedLook() async {
    setState(() => _readingSaves = true);
    final List<(int, OculumLiteSaveSlot)> savedLooks;
    try {
      final store = await OculumLiteSaveStore.open();
      final slots = await Future.wait(
        List.generate(oculumLiteSaveSlotCount, store.read),
      );
      savedLooks = [
        for (var i = 0; i < oculumLiteSaveSlotCount; i++)
          if (slots[i].save case final save?
              when save.run.hero == LiteHero.duplicatore)
            (i, save),
      ];
    } on Exception {
      if (mounted) {
        setState(() => _readingSaves = false);
        await showDialog<void>(
          context: context,
          builder: (dialog) => AlertDialog(
            title: const Text('Salvataggi non disponibili'),
            content: const Text(
              'Impossibile leggere i salvataggi di Oculum RL.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialog),
                child: const Text('Chiudi'),
              ),
            ],
          ),
        );
      }
      return;
    }
    if (!mounted) return;
    setState(() => _readingSaves = false);
    final source = await showDialog<OculumLiteSaveSlot>(
      context: context,
      builder: (dialog) => SimpleDialog(
        title: const Text('Carica aspetto salvato'),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
            child: Text(
              savedLooks.isEmpty
                  ? 'Crea un Duplicatore in solo per ritrovarlo qui.'
                  : 'Copia nome e aspetto nella modifica corrente.',
            ),
          ),
          for (final (index, save) in savedLooks)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialog, save),
              child: Row(
                children: [
                  SizedBox(
                    width: 64,
                    height: 52,
                    child: OculumLiteHeroPreview(
                      hero: LiteHero.duplicatore,
                      weapon: _weapon,
                      appearance: save.appearance,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          save.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Salvataggio ${index + 1}',
                          style: Theme.of(dialog).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialog),
            child: const Text('Torna al creatore'),
          ),
        ],
      ),
    );
    if (!mounted || source == null) return;
    _name.text = source.name.trim().characters.take(32).toString();
    _change(source.appearance);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _jumpTo(GlobalKey anchor) {
    final section = anchor.currentContext;
    if (section == null) return;
    Scrollable.ensureVisible(
      section,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 230),
      curve: Curves.easeOut,
    );
  }

  Widget _sectionHeading(_CreatorSection section) => Padding(
    key: _sections[section],
    padding: const EdgeInsets.only(top: 12, bottom: 8),
    child: Semantics(
      header: true,
      child: Text(
        section.label,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    ),
  );

  Widget _sectionLinks({required bool includePreview}) => Wrap(
    spacing: 5,
    children: [
      if (includePreview)
        TextButton.icon(
          onPressed: () => _jumpTo(_previewAnchor),
          icon: const Icon(Icons.visibility_outlined, size: 16),
          label: const Text('Anteprima'),
        ),
      for (final section in _CreatorSection.values)
        TextButton.icon(
          onPressed: () => _jumpTo(_sections[section]!),
          icon: Icon(section.icon, size: 16),
          label: Text(section.label),
        ),
    ],
  );

  Widget _preview(double height) => Column(
    key: _previewAnchor,
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: double.infinity,
        height: height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: const RadialGradient(
            colors: [Color(0xff40333d), Color(0xff1b151e)],
            radius: .88,
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xff6f5146)),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedScale(
              scale: _zoomed ? 1.45 : 1,
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 160),
              alignment: const Alignment(0, .4),
              child: _pose == _CreatorPose.posa
                  ? OculumLiteHeroPreview(
                      hero: LiteHero.duplicatore,
                      weapon: _weapon,
                      appearance: _look,
                      showClone: _showClone,
                    )
                  : _CreatorMotionStage(
                      key: ValueKey((_pose, _take, _weapon, _showClone)),
                      pose: _pose,
                      weapon: _weapon,
                      appearance: _look,
                      showClone: _showClone,
                    ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                tooltip: _zoomed
                    ? 'Ripristina inquadratura'
                    : 'Avvicina anteprima',
                onPressed: () => setState(() => _zoomed = !_zoomed),
                icon: Icon(_zoomed ? Icons.zoom_out : Icons.zoom_in),
              ),
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 5,
          runSpacing: 2,
          children: [
            for (final pose in _CreatorPose.values)
              ChoiceChip(
                label: Text(pose.label),
                selected: _pose == pose,
                onSelected: (_) => setState(() {
                  _pose = pose;
                  _take++;
                }),
              ),
            if (_pose != _CreatorPose.posa)
              IconButton(
                tooltip: 'Ripeti prova',
                onPressed: () => setState(() => _take++),
                icon: const Icon(Icons.replay),
              ),
          ],
        ),
      ),
      DropdownButtonFormField<LiteWeapon>(
        initialValue: _weapon,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Posa da provare',
          helperText: 'Arma usata nell’anteprima',
        ),
        items: [
          for (final weapon in LiteWeapon.values)
            DropdownMenuItem(value: weapon, child: Text(weapon.label)),
        ],
        onChanged: (weapon) {
          if (weapon != null) setState(() => _weapon = weapon);
        },
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Mostra il clone'),
        value: _showClone,
        onChanged: (show) => setState(() => _showClone = show),
      ),
    ],
  );

  Widget _options() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionHeading(_CreatorSection.identity),
      TextField(
        controller: _name,
        maxLength: 32,
        decoration: const InputDecoration(labelText: 'Nome'),
      ),
      OutlinedButton.icon(
        onPressed: _readingSaves ? null : _loadSavedLook,
        icon: const Icon(Icons.folder_open_outlined),
        label: const Text('Carica aspetto salvato'),
      ),
      const SizedBox(height: 10),
      _choices(
        'Fisionomia',
        const ['Umano', 'Goblin'],
        OculumLiteLineage.values,
        _look.lineage,
        (lineage) => _change(_look.copyWith(lineage: lineage)),
      ),
      _choices(
        'Modello del corpo',
        const ['Maschile', 'Femminile', 'Androgino', 'Massiccio', 'Longilineo'],
        OculumLiteBody.values,
        _look.body,
        (body) => _change(_look.copyWith(body: body)),
      ),
      const Text('Corporatura'),
      Slider(
        key: const ValueKey('rl-corpo'),
        semanticFormatterCallback: (value) => '${(100 * value).round()}%',
        value: _look.frame,
        onChanged: (value) => _change(_look.copyWith(frame: value)),
      ),
      if (_look.lineage == OculumLiteLineage.goblin) ...[
        const Text('Apertura delle orecchie'),
        Slider(
          key: const ValueKey('rl-orecchie'),
          value: _look.ears,
          onChanged: (value) => _change(_look.copyWith(ears: value)),
        ),
      ],
      _sectionHeading(_CreatorSection.face),
      _choices(
        'Lineamenti',
        const [
          'Affilati',
          'Arrotondati',
          'Marcati',
          'Scavati',
          'Squadrati',
          'Dolci',
        ],
        OculumLiteFace.values,
        _look.face,
        (face) => _change(_look.copyWith(face: face)),
      ),
      _choices(
        'Pettinatura',
        [for (final hair in OculumLiteHair.values) hair.label],
        OculumLiteHair.values,
        _look.hairstyle,
        (hair) => _change(_look.copyWith(hairstyle: hair)),
      ),
      _choices(
        'Copricapo',
        const [
          'Scoperto',
          'Fascia',
          'Diadema',
          'Corna',
          'Occhiali',
          'Cappuccio',
        ],
        OculumLiteHeadgear.values,
        _look.headgear,
        (headgear) => _change(_look.copyWith(headgear: headgear)),
      ),
      _choices(
        'Dettaglio del volto',
        const [
          'Liscio',
          'Cicatrice',
          'Pittura di guerra',
          'Lentiggini',
          'Orecchino',
          'Benda sugli occhi',
          'Rune d’inchiostro',
        ],
        OculumLiteFaceDetail.values,
        _look.faceDetail,
        (detail) => _change(_look.copyWith(faceDetail: detail)),
      ),
      _sectionHeading(_CreatorSection.gear),
      _choices(
        'Tenuta',
        const [
          'Mantello',
          'Corazza',
          'Giubba',
          'Duellante',
          'Rituale',
          'Postea',
          'Esploratore',
          'Armatura lamellare',
        ],
        OculumLiteOutfit.values,
        _look.outfit,
        (outfit) => _change(_look.copyWith(outfit: outfit)),
      ),
      _choices(
        'Emblema',
        const [
          'Nessuno',
          'Occhio',
          'Luna',
          'Fiamma',
          'Runa',
          'Piuma',
          'Cristallo',
        ],
        OculumLiteEmblem.values,
        _look.emblem,
        (emblem) => _change(_look.copyWith(emblem: emblem)),
      ),
      _sectionHeading(_CreatorSection.colors),
      _swatches(
        'Abito',
        OculumLiteAppearance.clothPalette,
        _look.cloth,
        (color) => _change(_look.copyWith(cloth: color)),
      ),
      _swatches(
        'Dettagli',
        OculumLiteAppearance.accentPalette,
        _look.accent,
        (color) => _change(_look.copyWith(accent: color)),
      ),
      _swatches(
        'Capelli',
        OculumLiteAppearance.hairPalette,
        _look.hair,
        (color) => _change(_look.copyWith(hair: color)),
      ),
      _swatches(
        'Pelle',
        OculumLiteAppearance.skinPalette,
        _look.skin,
        (color) => _change(_look.copyWith(skin: color)),
      ),
      _swatches(
        'Iride',
        OculumLiteAppearance.eyePalette,
        _look.eyes,
        (color) => _change(_look.copyWith(eyes: color)),
      ),
    ],
  );

  Widget _choices<T>(
    String label,
    List<String> names,
    List<T> choices,
    T selected,
    ValueChanged<T> change,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        Wrap(
          spacing: 6,
          children: [
            for (final (i, option) in choices.indexed)
              ChoiceChip(
                label: Text(names[i]),
                selected: selected == option,
                onSelected: (_) => change(option),
              ),
          ],
        ),
      ],
    ),
  );

  Widget _swatches(
    String label,
    List<Color> palette,
    Color selected,
    ValueChanged<Color> change,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label),
      Wrap(
        children: [
          for (final (i, color) in palette.indexed)
            IconButton(
              tooltip: '$label · colore ${i + 1}',
              isSelected: color == selected,
              onPressed: () => change(color),
              icon: Icon(Icons.circle, color: color),
              selectedIcon: Icon(Icons.check_circle, color: color),
            ),
        ],
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final wide = screen.width >= 830 && screen.height >= 540;
    final panelHeight = min(540.0, screen.height - 152);
    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: wide ? 36 : 12,
        vertical: 16,
      ),
      contentPadding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
      title: Row(
        children: [
          const Expanded(child: Text('Clonatore · Crea il personaggio')),
          IconButton(
            tooltip: 'Genera aspetto casuale',
            onPressed: () => _change(OculumLiteAppearance.random(_random)),
            icon: const Icon(Icons.casino_outlined),
          ),
          IconButton(
            tooltip: 'Ripristina il preset',
            onPressed: () => _change(const OculumLiteAppearance()),
            icon: const Icon(Icons.restart_alt),
          ),
        ],
      ),
      content: SizedBox(
        width: wide ? 912 : 460,
        height: panelHeight,
        child: wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: _preview((panelHeight - 166).clamp(180.0, 310.0)),
                    ),
                  ),
                  const SizedBox(width: 22),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLinks(includePreview: false),
                        Expanded(
                          child: SingleChildScrollView(child: _options()),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLinks(includePreview: true),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(children: [_preview(172), _options()]),
                    ),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, (
            name: _name.text.trim(),
            appearance: _look,
          )),
          child: const Text('Usa questo aspetto'),
        ),
      ],
    );
  }
}

/// Plays a brief take with the same simulation and renderer as an actual run.
class _CreatorMotionStage extends StatefulWidget {
  const _CreatorMotionStage({
    super.key,
    required this.pose,
    required this.weapon,
    required this.appearance,
    required this.showClone,
  });

  final _CreatorPose pose;
  final LiteWeapon weapon;
  final OculumLiteAppearance appearance;
  final bool showClone;

  @override
  State<_CreatorMotionStage> createState() => _CreatorMotionStageState();
}

class _CreatorMotionStageState extends State<_CreatorMotionStage>
    with SingleTickerProviderStateMixin {
  late final LiteRun _run;
  late final Ticker _ticker;
  final _view = ValueNotifier<int>(0);
  Duration _lastTick = Duration.zero;
  bool _started = false;
  double _played = 0;

  bool get _moving =>
      widget.pose == _CreatorPose.cammina || widget.pose == _CreatorPose.corri;

  double get _duration => switch (widget.pose) {
    _CreatorPose.posa => 0,
    _CreatorPose.cammina => 1.45,
    _CreatorPose.corri => 1.05,
    _CreatorPose.scatto => .46,
    _CreatorPose.attacco =>
      widget.weapon.chargeSeconds + (widget.weapon.returns ? 2.1 : .58),
  };

  @override
  void initState() {
    super.initState();
    _run = LiteRun(seed: 251, hero: LiteHero.duplicatore, weapon: widget.weapon)
      ..stageClear = true
      ..enemies.clear()
      ..obstacles.clear()
      ..fauna.clear()
      ..loot.clear();
    _run.position = Point(_run.width / 2, _run.height / 2);
    final aim = _run.position + const Point<double>(8, 0);
    if (widget.showClone) {
      _run.special(_run.position - const Point<double>(2, 0));
    }
    _run.lookAt(aim);
    switch (widget.pose) {
      case _CreatorPose.scatto:
        _run.dash(aim);
      case _CreatorPose.attacco:
        _run.attack(aim);
      case _CreatorPose.posa:
      case _CreatorPose.cammina:
      case _CreatorPose.corri:
        break;
    }
    _ticker = createTicker(_tick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      // A still from the selected move is enough with reduced motion.
      _step(widget.pose == _CreatorPose.scatto ? .09 : .13);
    } else {
      _ticker.start();
    }
  }

  void _step(double seconds) {
    _run.advanceFrame(
      seconds,
      move: _moving ? const Point(1, 0) : const Point(0, 0),
      walk: widget.pose == _CreatorPose.cammina,
    );
    _played += seconds;
  }

  void _tick(Duration elapsed) {
    final delta = (elapsed - _lastTick).inMicroseconds / 1000000;
    _lastTick = elapsed;
    final seconds = min(min(delta, .05), _duration - _played);
    if (seconds <= 0) return;
    _step(seconds);
    _view.value++;
    if (_played >= _duration - .0001) _ticker.stop();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _view.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Transform.scale(
      scale: 2.25,
      alignment: const Alignment(0, -.15),
      child: OculumLiteArena(
        run: _run,
        appearance: widget.appearance,
        view: _view,
      ),
    ),
  );
}
