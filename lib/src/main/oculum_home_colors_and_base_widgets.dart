part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member, unused_element

class _OculumModelTextField extends StatefulWidget {
  const _OculumModelTextField({
    super.key,
    required this.initialValue,
    required this.onChanged,
    required this.onEdited,
    required this.onRefreshRequested,
    required this.decoration,
    required this.style,
    required this.linguaInglese,
    this.maxLines = 1,
    this.enableCommandAutocomplete = true,
    this.liveRefresh = false,
  });

  final String initialValue;
  final void Function(String) onChanged;
  final VoidCallback onEdited;
  final VoidCallback onRefreshRequested;
  final InputDecoration decoration;
  final TextStyle style;
  final bool linguaInglese;
  final int maxLines;
  final bool enableCommandAutocomplete;
  final bool liveRefresh;

  @override
  State<_OculumModelTextField> createState() => _OculumModelTextFieldState();
}

class _OculumSectionTitle extends StatelessWidget {
  const _OculumSectionTitle({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

class _OculumModelTextFieldState extends State<_OculumModelTextField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _dirtySinceRefresh = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(covariant _OculumModelTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (!_focusNode.hasFocus && _dirtySinceRefresh) {
      _refreshParent();
    }
  }

  void _refreshParent() {
    _dirtySinceRefresh = false;
    widget.onRefreshRequested();
  }

  void _notifyEdited() {
    widget.onChanged(_controller.text);
    widget.onEdited();
    _dirtySinceRefresh = true;
    if (widget.liveRefresh) {
      _refreshParent();
    }
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (!widget.enableCommandAutocomplete ||
        event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.tab) {
      return KeyEventResult.ignored;
    }

    final completed = oculumApplyCommandAutocomplete(
      _controller,
      linguaInglese: widget.linguaInglese,
    );
    if (!completed) return KeyEventResult.ignored;

    _notifyEdited();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final multiline = widget.maxLines > 1;

    return Focus(
      onKeyEvent: _handleKey,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        keyboardType: multiline ? TextInputType.multiline : TextInputType.text,
        textInputAction: multiline ? TextInputAction.newline : null,
        maxLines: widget.maxLines,
        onChanged: (_) => _notifyEdited(),
        style: widget.style,
        decoration: widget.decoration,
      ),
    );
  }
}

extension _OculumHomeColorsAndBaseWidgets on _OculumHomePageState {
  // COLORI / FILTRI / RGB + LUMINOSITÀ + SATURAZIONE + OPACITÀ
  // =====================================================

  Color defaultElementColor(String element) {
    switch (oculumNormalizeElementId(element)) {
      case 'fuoco':
        return const Color(0xFFFF5A3C);
      case 'gelo':
        return const Color(0xFF9BE7FF);
      case 'acqua':
        return const Color(0xFF44A7FF);
      case 'fulmine':
        return const Color(0xFFFFF06A);
      case 'terra':
        return const Color(0xFF8B6B3E);
      case 'vento':
        return const Color(0xFF7EE7C8);
      case 'veleno':
        return const Color(0xFF78D64B);
      case 'acido':
        return const Color(0xFFB8FF3C);
      case 'oscuro':
        return const Color(0xFF4C3A78);
      case 'sacro':
        return const Color(0xFFFFE3A3);
      case 'lunare':
        return const Color(0xFFD7B9FF);
      case 'solare':
        return const Color(0xFFFFD36A);
      case 'diabolico':
        return const Color(0xFF8F1D2C);
      case 'angelico':
        return const Color(0xFFFFF3C4);
      case 'psichico':
        return const Color(0xFFFF7CE5);
      case 'spirituale':
        return const Color(0xFFAAD7FF);
      case 'necrotico':
        return const Color(0xFF7D8A55);
      case 'sangue':
        return const Color(0xFFC5283D);
      case 'cenere':
        return const Color(0xFF8D8A82);
      case 'osso':
        return const Color(0xFFE8DEC7);
      case 'cristallo':
        return const Color(0xFFA98BFF);
      case 'lava':
        return const Color(0xFFFF7A1A);
      case 'vapium':
        return const Color(0xFFA7AAB8);
      case 'sogno':
        return const Color(0xFFB6A0FF);
      case 'metallo':
        return const Color(0xFF9AA1AE);
      case 'postea':
        return const Color(0xFF8FB7FF);
      case 'radice':
        return const Color(0xFF55B86B);
      case 'slime':
        return const Color(0xFF63D8FF);
      case 'stella':
        return const Color(0xFFFFF0A8);
      case 'corrotto':
        return const Color(0xFFB65A72);
      case 'nonmorto':
        return const Color(0xFF8EA08A);
      case 'magia':
        return const Color(0xFF8B5CF6);
      case 'energia':
        return const Color(0xFF5CC8FF);
      case 'esplosivo':
        return const Color(0xFFFF7A1A);
      case 'sonoro':
        return const Color(0xFFFF8DD8);
      case 'radiazione':
        return const Color(0xFF9DFF4A);
      case 'plasma':
        return const Color(0xFF7CFFFF);
      case 'tecnologia':
        return const Color(0xFF55D7FF);
      case 'proiettile':
        return const Color(0xFF9AA1AE);
      case 'laser':
        return const Color(0xFFFF4F6D);
      case 'gravita':
        return const Color(0xFF7C5CFF);
      case 'tempo':
        return const Color(0xFF8FB7FF);
      case 'spazio':
        return const Color(0xFF223A73);
      case 'vuoto':
        return const Color(0xFF1F2230);
      case 'caos':
        return const Color(0xFFFF4FD8);
      case 'natura':
        return const Color(0xFF55B86B);
      case 'pianta':
        return const Color(0xFF6FD86A);
      case 'bestiale':
        return const Color(0xFFC49A5A);
      case 'maledizione':
        return const Color(0xFF7A2AA8);
      case 'benedizione':
        return const Color(0xFFFFD98A);
      case 'cura':
        return const Color(0xFF6AFFA7);
      case 'vero':
        return const Color(0xFFFFFFFF);
      case 'taglio':
        return const Color(0xFFD8D8E8);
      case 'perforante':
        return const Color(0xFFC9C9D3);
      case 'contundente':
        return const Color(0xFFB0A8A0);
      case 'oculum':
        return oculumStatFormulaColor;
      case 'fisico':
        return const Color(0xFFBFB7DD);
      default:
        return eyeUtilityColor;
    }
  }

  Color elementColor(String element) {
    final id = oculumNormalizeElementId(element);
    final saved = elementColorOverrides[id];
    return saved == null ? defaultElementColor(id) : Color(saved);
  }

  Color statFormulaColor(String stat) {
    switch (oculumStatKey(stat)) {
      case 'volonta':
        return const Color(0xFFE74C3C);
      case 'materia':
        return const Color(0xFF44A7FF);
      case 'resilienza':
        return const Color(0xFF2ECC71);
      case 'oculum':
        return oculumStatFormulaColor;
      default:
        return primaryColor;
    }
  }

  String elementDisplayName(String element) {
    final id = oculumNormalizeElementId(element);
    for (final custom in customDamageTypes) {
      if (oculumNormalizeElementId(custom) == id) {
        return cleanUiText(custom);
      }
    }
    final inferred = inferredDamageTypeLabels()[id];
    if (inferred != null && inferred.trim().isNotEmpty) {
      return inferred;
    }
    return linguaInglese
        ? oculumElementDisplayEn(element)
        : oculumElementDisplayIt(element);
  }

  Map<String, String> inferredDamageTypeLabels() {
    final cached = inferredDamageTypeLabelsCache;
    if (cached != null &&
        inferredDamageTypeLabelsCacheRevision == derivedDataRevision) {
      return cached;
    }

    final found = <String, String>{};
    final vars = formulaValueContext();

    void addLabel(String label) {
      final clean = cleanUiText(label).trim();
      if (clean.isEmpty) return;
      final id = oculumNormalizeElementId(clean);
      if (id.isEmpty || id == 'sconosciuto') return;
      found.putIfAbsent(id, () => clean);
    }

    void scanFormulaText(String text) {
      if (text.trim().isEmpty) return;
      final regex = RegExp(r'@([^\s@,+\-*/();]+)\s*([+-])\s*([^@,;\n]+)');
      for (final match in regex.allMatches(text)) {
        final key = oculumStatKey(match.group(1) ?? '');
        if (key != 'danni' && key != 'difesa') continue;
        final expression = (match.group(3) ?? '').trim();
        final trailing = oculumSplitTrailingElement(expression, vars);
        if (trailing != null && trailing.trim().isNotEmpty) {
          addLabel(trailing);
          continue;
        }
        for (final command in oculumParseFormulaCommands(text, vars)) {
          if (!command.valid) continue;
          if (command.key != 'danni' && command.key != 'difesa') continue;
          if (command.elementId.isNotEmpty) addLabel(command.elementId);
        }
      }
    }

    void scanTitle(OculumTitle titolo) {
      for (final text in [
        titolo.nome,
        titolo.tipo,
        titolo.ottenimento,
        titolo.buff,
        titolo.skill,
        titolo.puntoCieco,
        titolo.richiede,
        titolo.openName,
        titolo.openDescription,
        titolo.openBuff,
        titolo.openSkill,
        for (final open in titolo.openExtra) ...[
          open.nome,
          open.descrizione,
          open.openBuff,
          open.openSkill,
          for (final buff in open.conditionalBuffs) ...[
            buff.nome,
            buff.descrizione,
            buff.condizione,
          ],
        ],
        for (final buff in titolo.titleConditionalBuffs) ...[
          buff.nome,
          buff.descrizione,
          buff.condizione,
        ],
        for (final buff in titolo.openConditionalBuffs) ...[
          buff.nome,
          buff.descrizione,
          buff.condizione,
        ],
      ]) {
        scanFormulaText(text);
      }
    }

    for (final titolo in titoli) {
      scanTitle(titolo);
    }
    for (final tratto in trattiRazziali) {
      scanTitle(tratto);
    }
    for (final item in inventario) {
      addLabel(item.elementoDanno);
      scanFormulaText(item.nome);
      scanFormulaText(item.buff);
      scanFormulaText(item.note);
    }
    for (final skill in skills) {
      for (final text in [
        skill.nome,
        skill.tipo,
        skill.costo,
        skill.cooldown,
        skill.descrizione,
      ]) {
        scanFormulaText(text);
      }
    }
    for (final art in arti) {
      for (final text in [
        art.nome,
        art.tipo,
        art.descrizione,
        art.openName,
        art.openDescription,
        art.openBuff,
        art.openSkill,
        for (final skill in art.skills) ...[
          skill.nome,
          skill.evo1,
          skill.evo2,
          skill.evo3,
        ],
      ]) {
        scanFormulaText(text);
      }
    }

    final result = Map<String, String>.unmodifiable(found);
    inferredDamageTypeLabelsCache = result;
    inferredDamageTypeLabelsCacheRevision = derivedDataRevision;
    return result;
  }

  List<String> allDamageElementIds() {
    final cached = allDamageElementIdsCache;
    if (cached != null &&
        allDamageElementIdsCacheRevision == derivedDataRevision) {
      return cached;
    }

    final ids = <String>[...oculumDefaultElementIds];
    for (final custom in customDamageTypes) {
      final id = oculumNormalizeElementId(custom);
      if (id.isEmpty || ids.contains(id)) continue;
      ids.add(id);
    }
    for (final id in inferredDamageTypeLabels().keys) {
      if (ids.contains(id)) continue;
      ids.add(id);
    }
    final result = List<String>.unmodifiable(ids);
    allDamageElementIdsCache = result;
    allDamageElementIdsCacheRevision = derivedDataRevision;
    return result;
  }

  List<String> elementDropdownValues() {
    return allDamageElementIds().map(elementDisplayName).toList();
  }

  void addCustomDamageTypeFromSettings() {
    final raw = cleanUiText(customDamageTypeController.text).trim();
    if (raw.isEmpty) return;

    final id = oculumNormalizeElementId(raw);
    final alreadyDefault = oculumDefaultElementIds.contains(id);
    final alreadyCustom = customDamageTypes.any(
      (name) => oculumNormalizeElementId(name) == id,
    );

    setState(() {
      if (!alreadyDefault && !alreadyCustom) {
        customDamageTypes.add(raw);
      }
      customDamageTypeController.clear();
      risultato = alreadyDefault || alreadyCustom
          ? t(
              'Tipo di danno gia presente: ${elementDisplayName(raw)}.',
              'Damage type already exists: ${elementDisplayName(raw)}.',
            )
          : t('Tipo di danno aggiunto: $raw.', 'Damage type added: $raw.');
      aggiungiLog(risultato);
    });
    programmaSalvataggio();
  }

  void removeCustomDamageType(String custom) {
    final id = oculumNormalizeElementId(custom);
    setState(() {
      customDamageTypes.removeWhere(
        (name) => oculumNormalizeElementId(name) == id,
      );
      elementColorOverrides.remove(id);
      if (oculumNormalizeElementId(itemElementoDannoController.text) == id) {
        itemElementoDannoController.text = 'Fisico';
      }
      risultato = t(
        'Tipo di danno rimosso: ${cleanUiText(custom)}.',
        'Damage type removed: ${cleanUiText(custom)}.',
      );
      aggiungiLog(risultato);
    });
    programmaSalvataggio();
  }

  void setElementColor(String element, Color color) {
    setState(() {
      elementColorOverrides[oculumNormalizeElementId(element)] = color
          .toARGB32();
      risultato = t(
        'Colore elemento aggiornato: ${elementDisplayName(element)}.',
        'Element color updated: ${elementDisplayName(element)}.',
      );
      aggiungiLog(risultato);
    });
    programmaSalvataggio();
  }

  void resetElementColor(String element) {
    setState(() {
      elementColorOverrides.remove(oculumNormalizeElementId(element));
      risultato = t(
        'Colore elemento ripristinato: ${elementDisplayName(element)}.',
        'Element color restored: ${elementDisplayName(element)}.',
      );
      aggiungiLog(risultato);
    });
    programmaSalvataggio();
  }

  void resetAllElementColors() {
    setState(() {
      elementColorOverrides.clear();
      oculumStatFormulaColor = const Color(0xFF8B5CF6);
      eyeUtilityColor = _OculumHomePageState.defaultEyeUtilityColor;
      risultato = t(
        'Colori elementi ripristinati.',
        'Element colors restored.',
      );
      aggiungiLog(risultato);
    });
    programmaSalvataggio();
  }

  Color coloreConOpacita(Color color, double opacity) {
    return color.withValues(alpha: opacity.clamp(0.05, 1.0));
  }

  double themeContrastRatio(Color a, Color b) {
    final l1 = a.computeLuminance();
    final l2 = b.computeLuminance();
    final lighter = max(l1, l2);
    final darker = min(l1, l2);
    return (lighter + 0.05) / (darker + 0.05);
  }

  Color readableOnTheme(
    Color color, {
    Color? background,
    double minRatio = 4.5,
  }) {
    final bg = background ?? backgroundMidColor;
    var candidate = color.withValues(alpha: 1);
    if (themeContrastRatio(candidate, bg) >= minRatio) {
      return color;
    }

    final backgroundIsLight = bg.computeLuminance() > 0.42;
    var hsl = HSLColor.fromColor(candidate);
    for (var i = 0; i < 16; i++) {
      final nextLightness = backgroundIsLight
          ? (hsl.lightness - 0.055).clamp(0.0, 1.0)
          : (hsl.lightness + 0.055).clamp(0.0, 1.0);
      hsl = hsl.withLightness(nextLightness);
      candidate = hsl.toColor();
      if (themeContrastRatio(candidate, bg) >= minRatio) {
        return candidate.withValues(alpha: color.a);
      }
    }

    final blackRatio = themeContrastRatio(Colors.black, bg);
    final whiteRatio = themeContrastRatio(Colors.white, bg);
    return (whiteRatio >= blackRatio ? Colors.white : Colors.black).withValues(
      alpha: color.a,
    );
  }

  List<Shadow> readableTextShadow(Color color, {Color? background}) {
    if (lightweightUi) return const <Shadow>[];
    final bg = background ?? backgroundMidColor;
    final shadowBase = color.computeLuminance() > bg.computeLuminance()
        ? Colors.black
        : Colors.white;
    return [
      Shadow(color: shadowBase.withValues(alpha: 0.72), blurRadius: 4),
      Shadow(color: color.withValues(alpha: 0.22), blurRadius: 9),
    ];
  }

  Color cambiaSaturazione(Color color, double saturation) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withSaturation(saturation.clamp(0.0, 1.0)).toColor();
  }

  Color cambiaLuminosita(Color color, double lightness) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness(lightness.clamp(0.0, 1.0)).toColor();
  }

  Color cambiaLuminositaSaturazioneOpacita({
    required Color color,
    required double lightness,
    required double saturation,
    required double opacity,
  }) {
    final hsl = HSLColor.fromColor(color);

    final changed = hsl
        .withLightness(lightness.clamp(0.0, 1.0))
        .withSaturation(saturation.clamp(0.0, 1.0))
        .toColor();

    return changed.withValues(alpha: opacity.clamp(0.05, 1.0));
  }

  void impostaColoreRgb({
    required String target,
    required int r,
    required int g,
    required int b,
    double? opacity,
  }) {
    final color = Color.fromRGBO(
      r.clamp(0, 255),
      g.clamp(0, 255),
      b.clamp(0, 255),
      opacity?.clamp(0.05, 1.0) ?? 1.0,
    );

    setState(() {
      if (target == 'Primario') {
        primaryColor = color;
      } else if (target == 'Secondario') {
        secondaryColor = color;
      } else {
        tertiaryColor = color;
      }

      risultato = 'Colore $target impostato con RGB($r, $g, $b).';
      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  void impostaColoreAvanzato({required String target, required Color color}) {
    setState(() {
      if (target == 'Primario') {
        primaryColor = color;
      } else if (target == 'Secondario') {
        secondaryColor = color;
      } else {
        tertiaryColor = color;
      }

      risultato = t('Colore $target aggiornato.', '$target color updated.');

      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  List<String> categorieColori() {
    final categorie = palette.map((e) => e.category).toSet().toList();
    categorie.sort();
    return ['Tutti', ...categorie];
  }

  List<ColorOption> coloriFiltrati(String filtro) {
    if (filtro == 'Tutti') return palette;
    return palette.where((c) => c.category == filtro).toList();
  }

  List<int> manualFilteredIndexes() {
    final q = manualSearchText.trim().toLowerCase();
    final cacheKey =
        '$q|$linguaInglese|${activeManualSections.length}|$derivedDataRevision';
    final cached = manualFilteredIndexesCache;
    if (cached != null && manualFilteredIndexesCacheKey == cacheKey) {
      return cached;
    }

    final results = q.isEmpty
        ? List<int>.generate(activeManualSections.length, (index) => index)
        : <int>[];

    if (q.isEmpty) {
      final cachedResults = List<int>.unmodifiable(results);
      manualFilteredIndexesCache = cachedResults;
      manualFilteredIndexesCacheKey = cacheKey;
      return cachedResults;
    }

    for (int i = 0; i < activeManualSections.length; i++) {
      final section = activeManualSections[i];

      if (manualTitle(section).toLowerCase().contains(q) ||
          manualContent(section).toLowerCase().contains(q) ||
          section.titleIt.toLowerCase().contains(q) ||
          section.titleEn.toLowerCase().contains(q) ||
          section.contentIt.toLowerCase().contains(q) ||
          section.contentEn.toLowerCase().contains(q)) {
        results.add(i);
      }
    }

    final cachedResults = List<int>.unmodifiable(results);
    manualFilteredIndexesCache = cachedResults;
    manualFilteredIndexesCacheKey = cacheKey;
    return cachedResults;
  }

  // =====================================================
  // WIDGET BASE / STILE
  // =====================================================

  bool get phoneCompactUi =>
      (MediaQuery.maybeOf(context)?.size.shortestSide ?? 900) < 600;

  bool get tabletCompactUi {
    final size = MediaQuery.maybeOf(context)?.size;
    if (size == null) return false;
    return size.shortestSide >= 600 && size.width < 1100;
  }

  bool get playDenseUi => phoneCompactUi || tabletCompactUi || modalitaDesktop;

  bool get lightweightUi => playDenseUi || modalitaVeloce || modalitaLeggera;

  bool get lowCostVisuals {
    final size = MediaQuery.maybeOf(context)?.size;
    final wideDesktopSurface = (size?.width ?? 0) >= 1000;
    return modalitaVeloce ||
        modalitaLeggera ||
        phoneCompactUi ||
        tabletCompactUi ||
        modalitaDesktop ||
        wideDesktopSurface;
  }

  double uiScale(double value, [double phoneScale = 0.82]) {
    if (phoneCompactUi) return value * (phoneScale * 0.96);
    if (tabletCompactUi) return value * 0.92;
    if (modalitaDesktop || modalitaVeloce || modalitaLeggera) {
      return value * 0.90;
    }
    return value;
  }

  EdgeInsets scaledInsets(EdgeInsets value, [double phoneScale = 0.80]) {
    if (!phoneCompactUi) {
      final factor = modalitaDesktop || tabletCompactUi || modalitaLeggera
          ? 0.70
          : modalitaVeloce
          ? 0.78
          : 1.0;
      if (factor == 1.0) return value;
      return EdgeInsets.fromLTRB(
        value.left * factor,
        value.top * factor,
        value.right * factor,
        value.bottom * factor,
      );
    }
    return EdgeInsets.fromLTRB(
      value.left * phoneScale * 0.90,
      value.top * phoneScale * 0.90,
      value.right * phoneScale * 0.90,
      value.bottom * phoneScale * 0.90,
    );
  }

  InputDecoration fieldDecoration(String label, {String? helper}) {
    final light = lightweightUi;
    final radius = themeFieldRadiusValue(compact: light);
    final fill = themeFieldFillColor();
    return InputDecoration(
      labelText: cleanUiText(label),
      labelStyle: TextStyle(color: primaryColor.withValues(alpha: 0.90)),
      floatingLabelStyle: TextStyle(
        color: tertiaryColor,
        fontWeight: FontWeight.w800,
      ),
      helperText: light || helper == null ? null : cleanUiText(helper),
      helperMaxLines: 2,
      helperStyle: TextStyle(
        color: Colors.grey.shade500,
        fontSize: uiScale(11.5),
        height: 1.15,
      ),
      filled: true,
      fillColor: fill,
      contentPadding: scaledInsets(
        EdgeInsets.symmetric(
          horizontal: light ? 8 : 11,
          vertical: light ? 6 : 10,
        ),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: themeFieldBorderSide(primaryColor, compact: light),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: themeFieldBorderSide(primaryColor, compact: light),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: themeFieldBorderSide(
          tertiaryColor,
          compact: light,
          focused: true,
        ),
      ),
    );
  }

  Widget campoTesto({
    required String label,
    required TextEditingController controller,
    bool numero = true,
    int maxLines = 1,
    String? helper,
    FocusNode? focusNode,
    bool enableCommandAutocomplete = false,
    ValueChanged<String>? onChanged,
  }) {
    final multiline = !numero && maxLines > 1;
    final shouldAutocomplete = enableCommandAutocomplete || !numero;

    final field = TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: numero
          ? const TextInputType.numberWithOptions(signed: true)
          : multiline
          ? TextInputType.multiline
          : TextInputType.text,
      textInputAction: multiline ? TextInputAction.newline : null,
      maxLines: maxLines,
      onEditingComplete: () {
        scheduleInputUiRefresh(delay: Duration.zero);
      },
      onTapOutside: (_) {
        FocusManager.instance.primaryFocus?.unfocus();
        scheduleInputUiRefresh(delay: Duration.zero);
      },
      onChanged: (value) {
        onChanged?.call(value);
        var needsRefresh = campoTestoNeedsLiveRefresh(controller);

        if (controller == manualSearchController) {
          manualSearchText = manualSearchController.text.trim().toLowerCase();
          needsRefresh = true;
        }

        if (controller == currentOculumController ||
            controller == oculumController) {
          scheduleRealtimeOculumChanged();
        }

        if (identical(controller, nomeController)) {
          needsRefresh =
              ensureSecretThemeUnlocks(announce: true) || needsRefresh;
        }

        if (needsRefresh) {
          scheduleInputUiRefresh();
        }

        programmaSalvataggio();
      },
      style: TextStyle(fontSize: uiScale(16), color: Colors.white),
      decoration: fieldDecoration(label, helper: helper),
    );

    Widget wrapped = field;

    if (shouldAutocomplete) {
      wrapped = Focus(
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent ||
              event.logicalKey != LogicalKeyboardKey.tab) {
            return KeyEventResult.ignored;
          }

          final completed = oculumApplyCommandAutocomplete(
            controller,
            linguaInglese: linguaInglese,
          );
          if (!completed) return KeyEventResult.ignored;

          if (controller == manualSearchController) {
            manualSearchText = manualSearchController.text.trim().toLowerCase();
            scheduleInputUiRefresh(delay: Duration.zero);
          }
          programmaSalvataggio();
          return KeyEventResult.handled;
        },
        child: field,
      );
    }

    if (!multiline) return wrapped;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        wrapped,
        const SizedBox(height: 7),
        textAttachmentsPanel(attachmentFieldIdForController(controller, label)),
      ],
    );
  }

  bool campoTestoNeedsLiveRefresh(TextEditingController controller) {
    return identical(controller, nomeController) ||
        identical(controller, tipoSchedaController) ||
        identical(controller, razzaController) ||
        identical(controller, livelloController) ||
        identical(controller, gradoController) ||
        identical(controller, expController) ||
        identical(controller, resilienzaController) ||
        identical(controller, volontaController) ||
        identical(controller, materiaController) ||
        identical(controller, oculumController) ||
        identical(controller, currentResilienzaController) ||
        identical(controller, currentVolontaController) ||
        identical(controller, currentMateriaController) ||
        identical(controller, currentOculumController) ||
        identical(controller, visibleCurrentResilienzaController) ||
        identical(controller, visibleCurrentVolontaController) ||
        identical(controller, visibleCurrentMateriaController) ||
        identical(controller, visibleCurrentOculumController) ||
        identical(controller, currentHpController) ||
        identical(controller, hpTempController) ||
        identical(controller, scudoController) ||
        identical(controller, scudoCriticoController) ||
        identical(controller, scudoOculumController) ||
        identical(controller, scudoOculumMaxController) ||
        identical(controller, attaccoRapidoController) ||
        identical(controller, cmRapidoController) ||
        identical(controller, difesaRapidaController) ||
        identical(controller, buffMalusRapidiController) ||
        identical(controller, karmaController) ||
        identical(controller, cenereController);
  }

  Widget campoModello({
    required String label,
    required String initialValue,
    required void Function(String) onChanged,
    Key? fieldKey,
    int maxLines = 1,
    String? helper,
    bool enableCommandAutocomplete = true,
    bool liveRefresh = false,
  }) {
    final field = _OculumModelTextField(
      key: fieldKey,
      initialValue: initialValue,
      maxLines: maxLines,
      onChanged: onChanged,
      onEdited: () {
        programmaSalvataggio();
      },
      onRefreshRequested: () {
        scheduleInputUiRefresh();
      },
      linguaInglese: linguaInglese,
      enableCommandAutocomplete: enableCommandAutocomplete,
      liveRefresh: liveRefresh,
      style: TextStyle(fontSize: uiScale(16), color: Colors.white),
      decoration: fieldDecoration(label, helper: helper),
    );

    if (maxLines <= 1) return field;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        field,
        const SizedBox(height: 7),
        textAttachmentsPanel(attachmentFieldIdFromKey(fieldKey, label)),
      ],
    );
  }

  Widget sectionTitle(String text) {
    final cleanText = cleanUiText(text);
    final light = lightweightUi;
    return themeSectionTitleShell(
      text: cleanText,
      compact: light,
      child: Padding(
        padding: scaledInsets(
          EdgeInsets.only(bottom: light ? 3 : 7, top: light ? 7 : 16),
        ),
        child: Row(
          children: [
            Container(
              width: uiScale(4),
              height: uiScale(light ? 18 : 22),
              decoration: BoxDecoration(
                color: tertiaryColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            SizedBox(width: uiScale(10)),
            Expanded(
              child: Text(
                cleanText,
                style: TextStyle(
                  fontSize: uiScale(18),
                  fontWeight: FontWeight.w900,
                  color: primaryColor,
                  shadows: light
                      ? const []
                      : [
                          Shadow(
                            color: primaryColor.withValues(alpha: 0.18),
                            blurRadius: 8,
                          ),
                        ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget gothicPanel({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(14),
    Color? borderColor,
  }) {
    final color = borderColor ?? primaryColor;
    final compact = lightweightUi;
    final spec = currentThemeDecorationSpec();
    final gui = currentThemeVisualIdentity().mainSheetGuiStyle;
    final guiStyle = gui.id;
    final panelMood = gui.panelMood;
    final appModePanel = <String>{
      'arcade_party_hud',
      'tactical_command_board',
      'combat_first_console',
      'indexed_grimoire',
    }.contains(panelMood);
    final clipped = <String>{
      'phobia',
      'postea',
      'kingi',
      'medieval',
      'rank_hud',
      'sigil',
      'archive',
      'relic',
    }.contains(guiStyle);
    final radius = BorderRadius.circular(
      themePanelRadiusValue(compact: compact),
    );
    if (lowCostVisuals) {
      final simpleFill =
          Color.lerp(secondaryColor, backgroundBottomColor, 0.58) ??
          backgroundBottomColor;
      return RepaintBoundary(
        child: Container(
          margin: EdgeInsets.symmetric(vertical: compact ? 2 : 4),
          padding: scaledInsets(padding),
          decoration: BoxDecoration(
            color: simpleFill.withValues(alpha: compact ? 0.82 : 0.88),
            borderRadius: radius,
            border: Border.all(
              color: color.withValues(alpha: compact ? 0.50 : 0.64),
              width: compact ? 0.8 : 1.0,
            ),
          ),
          child: child,
        ),
      );
    }

    final panelStack = Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(child: themePanelDecoration(color)),
        ),
        if (appModePanel)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _OculumGuiModePanelPainter(
                  spec: spec,
                  panelMood: panelMood,
                  borderColor: color,
                  compact: compact,
                ),
              ),
            ),
          ),
        Padding(padding: scaledInsets(padding), child: child),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _OculumThemePanelChromePainter(
                spec: spec,
                guiStyle: guiStyle,
                borderColor: color,
                compact: compact,
                clipped: clipped,
              ),
            ),
          ),
        ),
      ],
    );

    if (clipped) {
      return RepaintBoundary(
        child: Container(
          margin: EdgeInsets.symmetric(vertical: compact ? 2 : 4),
          decoration: BoxDecoration(
            boxShadow: themePanelBoxShadows(color, compact: compact),
          ),
          child: ClipPath(
            clipper: _OculumThemePanelClipper(
              guiStyle: guiStyle,
              compact: compact,
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: themePanelSurfaceGradient(color, compact: compact),
              ),
              child: panelStack,
            ),
          ),
        ),
      );
    }

    return RepaintBoundary(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: compact ? 2 : 4),
        decoration: BoxDecoration(
          gradient: themePanelSurfaceGradient(color, compact: compact),
          borderRadius: radius,
          border: Border.all(
            color: color.withValues(alpha: compact ? 0.60 : 0.78),
            width: themePanelBorderWidth(compact: compact),
          ),
          boxShadow: themePanelBoxShadows(color, compact: compact),
        ),
        child: ClipRRect(borderRadius: radius, child: panelStack),
      ),
    );
  }

  int responsivePageColumnCount(
    double width, {
    int maxColumns = 3,
    double minColumnWidth = 360,
  }) {
    if (width < 680 || phoneCompactUi) return 1;

    final effectiveMaxColumns = modalitaDesktop || width >= 940
        ? maxColumns
        : min(maxColumns, 2);
    final horizontalPadding = phoneCompactUi ? 18.0 : 24.0;
    final effectiveWidth = max(0.0, width - horizontalPadding);
    final columns = ((effectiveWidth + 10) / (minColumnWidth + 10))
        .floor()
        .clamp(1, effectiveMaxColumns)
        .toInt();
    return columns;
  }

  EdgeInsets responsivePagePadding() {
    if (phoneCompactUi) return const EdgeInsets.fromLTRB(7, 6, 7, 9);
    return scaledInsets(const EdgeInsets.all(10));
  }

  List<List<int>> responsiveBuilderRows({
    required int itemCount,
    required int columns,
    Set<int> fullWidthIndexes = const <int>{},
  }) {
    final rows = <List<int>>[];
    var index = 0;

    while (index < itemCount) {
      if (fullWidthIndexes.contains(index)) {
        rows.add(<int>[index]);
        index++;
        continue;
      }

      final row = <int>[];
      while (index < itemCount &&
          row.length < columns &&
          !fullWidthIndexes.contains(index)) {
        row.add(index);
        index++;
      }
      if (row.isNotEmpty) rows.add(row);
    }

    return rows;
  }

  Widget responsivePageBuilder({
    required String pageKey,
    required List<WidgetBuilder> builders,
    Set<int> fullWidthIndexes = const <int>{},
    int maxColumns = 3,
    double minColumnWidth = 360,
    double cacheExtent = 420,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = responsivePageColumnCount(
          constraints.maxWidth,
          maxColumns: maxColumns,
          minColumnWidth: minColumnWidth,
        );
        final padding = responsivePagePadding();

        if (columns <= 1) {
          return ListView.builder(
            key: sheetScrollKey(pageKey),
            padding: padding,
            cacheExtent: cacheExtent,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            itemCount: builders.length,
            itemBuilder: (context, index) => builders[index](context),
          );
        }

        final rows = responsiveBuilderRows(
          itemCount: builders.length,
          columns: columns,
          fullWidthIndexes: fullWidthIndexes,
        );

        return ListView.builder(
          key: sheetScrollKey(pageKey),
          padding: padding,
          cacheExtent: cacheExtent,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          itemCount: rows.length,
          itemBuilder: (context, rowIndex) {
            final row = rows[rowIndex];
            final isFullWidth =
                row.length == 1 && fullWidthIndexes.contains(row.first);
            if (isFullWidth) return builders[row.first](context);

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < row.length; i++) ...[
                  Expanded(child: builders[row[i]](context)),
                  if (i < row.length - 1) const SizedBox(width: 8),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Widget responsivePageList({
    required String pageKey,
    required List<Widget> children,
    Set<int> fullWidthIndexes = const <int>{},
    int maxColumns = 3,
    double minColumnWidth = 360,
    double cacheExtent = 420,
  }) {
    bool isFullWidthSection(Widget child) {
      if (child is _OculumSectionTitle) return true;
      if (child is KeyedSubtree) return isFullWidthSection(child.child);
      return false;
    }

    final effectiveFullWidthIndexes = <int>{...fullWidthIndexes};
    for (var i = 0; i < children.length; i++) {
      if (isFullWidthSection(children[i])) effectiveFullWidthIndexes.add(i);
    }

    return responsivePageBuilder(
      pageKey: pageKey,
      builders: [for (final child in children) (_) => child],
      fullWidthIndexes: effectiveFullWidthIndexes,
      maxColumns: maxColumns,
      minColumnWidth: minColumnWidth,
      cacheExtent: cacheExtent,
    );
  }

  Widget smallInfoText(String text, {Color? color}) {
    return Text(
      cleanUiText(text),
      style: TextStyle(
        color: color ?? Colors.grey.shade300,
        fontSize: uiScale(12.5),
        height: lightweightUi ? 1.22 : 1.32,
      ),
    );
  }

  Widget infoBox(String titolo, String valore) {
    final cleanTitle = cleanUiText(titolo);
    final cleanValue = cleanUiText(valore);
    final compactValue = cleanValue.length > 28;

    return Expanded(
      child: gothicPanel(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              cleanTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: primaryColor.withValues(alpha: 0.95),
                letterSpacing: 0.7,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              cleanValue,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: compactValue ? 13.5 : 23,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: compactValue ? 1.18 : 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget statChip(String label, int value) {
    final active = value != 0;
    final cleanLabel = cleanUiText(label);
    final compact = lightweightUi;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 10,
        vertical: compact ? 3 : 6,
      ),
      decoration: BoxDecoration(
        color: active ? tertiaryColor.withValues(alpha: 0.16) : Colors.black26,
        borderRadius: BorderRadius.circular(compact ? 12 : 20),
        border: Border.all(
          color: active ? tertiaryColor : Colors.grey.shade800,
        ),
      ),
      child: Text(
        '$cleanLabel ${value > 0 ? '+' : ''}$value',
        style: TextStyle(
          color: active ? tertiaryColor : Colors.grey.shade500,
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
          fontSize: compact ? 11 : null,
        ),
      ),
    );
  }

  Widget titleQuickCommandChips(OculumTitle titolo) {
    final detected = titleQuickBonuses(titolo);
    if (detected.isEmpty) return const SizedBox.shrink();

    final active = titolo.equipaggiato;
    final entries = detected.entries.toList()
      ..sort(
        (a, b) => quickCommandSortIndex(
          a.key,
        ).compareTo(quickCommandSortIndex(b.key)),
      );

    return Wrap(
      spacing: lightweightUi ? 5 : 8,
      runSpacing: lightweightUi ? 5 : 8,
      children: [
        for (final entry in entries)
          Tooltip(
            message: quickCommandDetailsForTexts(
              activeTitleQuickTexts(titolo),
              entry.key,
            ).join('\n'),
            child: Chip(
              label: Text(
                '@${entry.key} ${entry.value >= 0 ? '+' : ''}${entry.value}',
              ),
              avatar: Icon(
                active ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 17,
              ),
              backgroundColor: active
                  ? tertiaryColor.withValues(alpha: 0.18)
                  : Colors.black26,
              side: BorderSide(
                color: active ? tertiaryColor : Colors.grey.shade700,
              ),
              labelStyle: TextStyle(
                color: active ? tertiaryColor : Colors.grey.shade300,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }

  Widget titleQuickCombatLine(OculumTitle titolo) {
    final detected = titleQuickBonuses(titolo);
    final values = <String, int>{
      'Danni': detected['danni'] ?? 0,
      'Difesa': detected['difesa'] ?? 0,
      'VC': detected['vc'] ?? 0,
    };

    if (values.values.every((value) => value == 0)) {
      return const SizedBox.shrink();
    }

    final active = titolo.equipaggiato;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final entry in values.entries)
          if (entry.value != 0)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: lightweightUi ? 7 : 9,
                vertical: lightweightUi ? 3 : 5,
              ),
              decoration: BoxDecoration(
                color: active
                    ? tertiaryColor.withValues(alpha: 0.18)
                    : Colors.black26,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: active ? tertiaryColor : Colors.grey.shade700,
                ),
              ),
              child: Text(
                '${entry.key} ${entry.value > 0 ? '+' : ''}${entry.value}',
                style: TextStyle(
                  color: active ? tertiaryColor : Colors.grey.shade300,
                  fontWeight: FontWeight.w900,
                  fontSize: uiScale(12),
                ),
              ),
            ),
      ],
    );
  }

  Widget titleCategoryHeader(String category, int count) {
    return gothicPanel(
      borderColor: count > 0
          ? tertiaryColor
          : primaryColor.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.style,
                color: count > 0 ? tertiaryColor : primaryColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  category,
                  style: TextStyle(
                    color: count > 0 ? tertiaryColor : primaryColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '$count',
                style: TextStyle(
                  color: count > 0 ? tertiaryColor : Colors.grey,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          smallInfoText(titleCategoryRules(category)),
        ],
      ),
    );
  }

  Widget restStatBox(String label, int value, Color color) {
    final positive = value > 0;
    final negative = value < 0;
    final cleanLabel = cleanUiText(label);

    return Expanded(
      child: gothicPanel(
        borderColor: color,
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Text(
              cleanLabel,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${positive ? '+' : ''}$value',
              style: TextStyle(
                color: negative
                    ? Colors.redAccent
                    : positive
                    ? Colors.greenAccent
                    : Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget restButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    final cleanLabel = cleanUiText(label);
    final compact = lightweightUi;

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: compact ? 16 : 19),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: color.computeLuminance() > 0.45
            ? Colors.black
            : Colors.white,
        minimumSize: Size.fromHeight(compact ? 34 : 42),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 12,
          vertical: compact ? 6 : 9,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(compact ? 9 : 12),
        ),
      ),
      label: Text(
        cleanLabel,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: compact ? 12 : null,
        ),
      ),
    );
  }

  Widget specialRollBox(
    String titolo,
    String valore,
    VoidCallback onRoll, {
    VoidCallback? onTap,
  }) {
    final cleanTitle = cleanUiText(titolo);

    final panel = gothicPanel(
      borderColor: tertiaryColor,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Text(
            cleanTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              color: tertiaryColor,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            valore,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: onRoll,
            style: ElevatedButton.styleFrom(
              backgroundColor: tertiaryColor,
              foregroundColor: tertiaryColor.computeLuminance() > 0.45
                  ? Colors.black
                  : Colors.white,
              minimumSize: const Size.fromHeight(40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              t('Tira', 'Roll'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    return Expanded(
      child: onTap == null
          ? panel
          : Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onTap,
                child: panel,
              ),
            ),
    );
  }

  Widget statCard(
    String nome,
    int valore,
    int buff,
    int temp,
    VoidCallback onRoll, {
    int? massimo,
    int bonusSkillForma = 0,
    VoidCallback? onTap,
  }) {
    final bonus = valore ~/ 2 + bonusLivelloGrado();
    final cleanName = cleanUiText(nome);

    final panel = gothicPanel(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cleanName,
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  massimo == null ? '$valore' : '$valore/$massimo',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (buff != 0)
                  Text(
                    '${t('Buff titoli', 'Title buffs')}: ${buff > 0 ? '+' : ''}$buff',
                    style: TextStyle(color: tertiaryColor, fontSize: 12),
                  ),
                if (temp != 0)
                  Text(
                    '${t('Temp', 'Temp')}: ${temp > 0 ? '+' : ''}$temp',
                    style: TextStyle(
                      color: temp > 0 ? Colors.greenAccent : Colors.redAccent,
                      fontSize: 12,
                    ),
                  ),
                if (bonusSkillForma != 0)
                  Text(
                    '${t('Skill/Forme', 'Skills/Forms')}: ${bonusSkillForma > 0 ? '+' : ''}$bonusSkillForma',
                    style: TextStyle(color: primaryColor, fontSize: 12),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '1d20',
                style: TextStyle(
                  fontSize: 12,
                  color: tertiaryColor,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '+$bonus',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: onRoll,
            style: ElevatedButton.styleFrom(
              backgroundColor: secondaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              t('Tira', 'Roll'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return panel;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: panel,
      ),
    );
  }

  Widget statDropdown({
    required String label,
    required String value,
    required void Function(String) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: statsLevelUp.contains(value) ? value : statsLevelUp.first,
      dropdownColor: const Color(0xFF11131A),
      decoration: fieldDecoration(label),
      items: statsLevelUp
          .map(
            (stat) => DropdownMenuItem<String>(
              value: stat,
              child: Text(cleanUiText(stat)),
            ),
          )
          .toList(),
      onChanged: (nuovoValore) {
        if (nuovoValore == null) return;

        setState(() {
          onChanged(nuovoValore);
        });

        programmaSalvataggio();
      },
    );
  }

  Widget tipoSchedaDropdown({
    required String value,
    required void Function(String) onChanged,
  }) {
    final safeValue = tipiScheda.contains(value) ? value : 'Personaggio';

    return DropdownButtonFormField<String>(
      initialValue: safeValue,
      dropdownColor: const Color(0xFF11131A),
      decoration: fieldDecoration(t('Tipo Scheda', 'Sheet Type')),
      items: tipiScheda
          .map(
            (tipo) => DropdownMenuItem<String>(
              value: tipo,
              child: Text(cleanUiText(tipo)),
            ),
          )
          .toList(),
      onChanged: (nuovoValore) {
        if (nuovoValore == null) return;
        onChanged(nuovoValore);
      },
    );
  }

  Widget pageDropdown() {
    final labels = linguaInglese ? pageNamesEn : pageNamesIt;
    final indexes = visiblePageIndexes();
    final safeValue = indexes.contains(paginaCorrente)
        ? paginaCorrente
        : indexes.first;

    return DropdownButtonFormField<int>(
      initialValue: safeValue,
      dropdownColor: const Color(0xFF11131A),
      decoration: fieldDecoration(t('Pagina', 'Page')),
      items: [
        for (final i in indexes)
          DropdownMenuItem<int>(value: i, child: Text(cleanUiText(labels[i]))),
      ],
      onChanged: (index) {
        if (index == null) return;

        vaiAllaFunzione(page: index, logTitle: labels[index]);
      },
    );
  }

  Widget damageModifierDropdown() {
    final safeValue =
        modificatoriDanno.any((x) => x.name == modificatoreDannoSelezionato)
        ? modificatoreDannoSelezionato
        : 'Normale';

    final selected = modificatoriDanno.firstWhere(
      (x) => x.name == safeValue,
      orElse: () => modificatoriDanno.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: safeValue,
          dropdownColor: const Color(0xFF11131A),
          decoration: fieldDecoration(
            t(
              'Resistenza / Fragilità / Cura',
              'Resistance / Fragility / Healing',
            ),
          ),
          items: modificatoriDanno
              .map(
                (option) => DropdownMenuItem<String>(
                  value: option.name,
                  child: Text(option.name),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;

            setState(() {
              modificatoreDannoSelezionato = value;
              aggiungiLog('Modificatore danno selezionato: $value.');
            });

            programmaSalvataggio();
          },
        ),
        const SizedBox(height: 8),
        smallInfoText(damageDescription(selected)),
        const SizedBox(height: 6),
        smallInfoText(
          t(
            'Nota: Critico aggiunge +5 danni e peggiora lo stadio di uno: Rigenerazione → Resistenze → Normale → Fragilità. Poi Difesa, modificatore e Scudo Critico.',
            'Note: Critical adds +5 damage and worsens the stage by one: Regeneration → Resistances → Normal → Fragility. Then Defense, modifier and Critical Shield.',
          ),
          color: tertiaryColor,
        ),
      ],
    );
  }

  Widget dadoOverlayCentrale() {
    final overlayResultColor = overlayCriticoUno
        ? Colors.redAccent
        : overlayCriticoVenti
        ? tertiaryColor
        : primaryColor;

    return IgnorePointer(
      ignoring: !mostraOverlayDado || !dadoOverlayDismissibile,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: dadoOverlayDismissibile
            ? () {
                dadoOverlayTimer?.cancel();
                dadoOverlayRevealTimer?.cancel();
                setState(() {
                  mostraOverlayDado = false;
                  dadoOverlayMostraRisultato = false;
                  dadoOverlayDismissibile = false;
                });
              }
            : null,
        child: AnimatedOpacity(
          opacity: mostraOverlayDado ? 1 : 0,
          duration: const Duration(milliseconds: 180),
          child: Center(
            child: AnimatedScale(
              scale: mostraOverlayDado ? 1.0 : 0.55,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.20),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: overlayCriticoVenti
                          ? tertiaryColor.withValues(alpha: 0.14)
                          : primaryColor.withValues(alpha: 0.10),
                      blurRadius: overlayCriticoVenti ? 12 : 7,
                      spreadRadius: overlayCriticoVenti ? 1.5 : 0.5,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedRotation(
                      turns: mostraOverlayDado ? dadoOverlaySpinSeed * 0.18 : 0,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      child: D20Widget(
                        text: '',
                        fillColor: secondaryColor,
                        textColor: overlayResultColor,
                        glow: overlayCriticoVenti,
                        tertiaryColor: tertiaryColor,
                        faces: dadoOverlayFacce,
                      ),
                    ),
                    AnimatedOpacity(
                      opacity: dadoOverlayMostraRisultato ? 1 : 0,
                      duration: const Duration(milliseconds: 120),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 104),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            dadoOverlay,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            style: TextStyle(
                              color: overlayResultColor,
                              fontSize: dadoOverlay.length > 8
                                  ? 22
                                  : dadoOverlay.length > 4
                                  ? 28
                                  : 40,
                              fontWeight: FontWeight.w900,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.92),
                                  blurRadius: 5,
                                ),
                                Shadow(
                                  color: tertiaryColor.withValues(alpha: 0.32),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget diceResultPanel() {
    return gothicPanel(
      borderColor: tiroCriticoVenti
          ? tertiaryColor
          : tiroCriticoUno
          ? Colors.redAccent
          : primaryColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            t('Risultato', 'Result'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          if (dadoMostrato.isNotEmpty)
            D20Widget(
              text: dadoMostrato,
              fillColor: secondaryColor,
              textColor: tiroCriticoUno
                  ? Colors.redAccent
                  : tiroCriticoVenti
                  ? tertiaryColor
                  : primaryColor,
              glow: tiroCriticoVenti,
              tertiaryColor: tertiaryColor,
              faces: dadoMostratoFacce,
            ),
          if (dadoMostrato.isNotEmpty) const SizedBox(height: 18),
          Text(
            risultato,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget compactSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    int? divisions,
    required String valueText,
    required void Function(double) onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 34,
          child: Text(
            label,
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            label: valueText,
            activeColor: tertiaryColor,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 48,
          child: Text(
            valueText,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      ],
    );
  }

  // =====================================================
}
