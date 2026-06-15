part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member, unused_element

extension _OculumHomeSheetPage on _OculumHomePageState {
  // PANNELLI SCHEDA
  // =====================================================

  Widget lifeBar() {
    final maxHpVal = maxHp();
    final curr = hpCorrenti();
    final temp = hpTemp();
    final shield = scudo();
    final oculumShield = scudoOculum();
    final oculumShieldMax = scudoOculumMax();
    final criticalShield = scudoCritico();
    final totalVisual = max(
      0,
      maxHpVal + temp + shield + oculumShield + criticalShield,
    );

    final hpW = totalVisual <= 0 ? 0.0 : (curr / totalVisual).clamp(0.0, 1.0);
    final tempW = totalVisual <= 0 ? 0.0 : (temp / totalVisual).clamp(0.0, 1.0);
    final shieldW = totalVisual <= 0
        ? 0.0
        : (shield / totalVisual).clamp(0.0, 1.0);
    final oculumShieldW = totalVisual <= 0
        ? 0.0
        : (oculumShield / totalVisual).clamp(0.0, 1.0);
    final criticalShieldW = totalVisual <= 0
        ? 0.0
        : (criticalShield / totalVisual).clamp(0.0, 1.0);
    final showOculumShield = shouldShowScudoOculum();

    Color hpColor;
    final pureHpRatio = maxHpVal <= 0 ? 0 : curr / maxHpVal;

    if (pureHpRatio > 0.6) {
      hpColor = const Color(0xFF2ECC71);
    } else if (pureHpRatio > 0.3) {
      hpColor = const Color(0xFFF1C40F);
    } else {
      hpColor = const Color(0xFFE74C3C);
    }

    return gothicPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('Barra della Vita', 'Health Bar'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryColor,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          smallInfoText(
            t(
              'La barra mostra HP reali, HP temporanei, Scudo, Scudo Oculum e Scudo Critico. Lo Scudo Oculum assorbe prima degli altri scudi.',
              'The bar shows real HP, temporary HP, Shield, Oculum Shield and Critical Shield. Oculum Shield absorbs before other shields.',
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Container(height: 34, color: const Color(0xFF240C14)),
                FractionallySizedBox(
                  widthFactor: hpW,
                  child: Container(
                    height: 34,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [hpColor.withValues(alpha: 0.75), hpColor],
                      ),
                    ),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: (hpW + tempW).clamp(0.0, 1.0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FractionallySizedBox(
                      widthFactor: tempW <= 0 ? 0 : tempW / (hpW + tempW),
                      child: Container(
                        height: 34,
                        color: Colors.greenAccent.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: (hpW + tempW + shieldW).clamp(0.0, 1.0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FractionallySizedBox(
                      widthFactor: shieldW <= 0
                          ? 0
                          : shieldW / (hpW + tempW + shieldW),
                      child: Container(
                        height: 34,
                        color: tertiaryColor.withValues(alpha: 0.82),
                      ),
                    ),
                  ),
                ),
                if (showOculumShield)
                  FractionallySizedBox(
                    widthFactor: (hpW + tempW + shieldW + oculumShieldW).clamp(
                      0.0,
                      1.0,
                    ),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FractionallySizedBox(
                        widthFactor: oculumShieldW <= 0
                            ? 0
                            : oculumShieldW /
                                  (hpW + tempW + shieldW + oculumShieldW),
                        child: Container(
                          height: 34,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                primaryColor.withValues(alpha: 0.62),
                                eyePupilGlowColor.withValues(alpha: 0.88),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                FractionallySizedBox(
                  widthFactor:
                      (hpW +
                              tempW +
                              shieldW +
                              (showOculumShield ? oculumShieldW : 0) +
                              criticalShieldW)
                          .clamp(0.0, 1.0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FractionallySizedBox(
                      widthFactor: criticalShieldW <= 0
                          ? 0
                          : criticalShieldW /
                                (hpW +
                                    tempW +
                                    shieldW +
                                    (showOculumShield ? oculumShieldW : 0) +
                                    criticalShieldW),
                      child: Container(
                        height: 34,
                        color: Colors.white.withValues(alpha: 0.48),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.46),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            child: Text(
                              showOculumShield
                                  ? 'HP $curr/$maxHpVal  T $temp  S $shield  SO $oculumShield/$oculumShieldMax  SC $criticalShield'
                                  : 'HP $curr/$maxHpVal  T $temp  S $shield  SC $criticalShield',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(color: Colors.black, blurRadius: 5),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget stackedVitalsHudPanel({bool dense = false, bool embedded = false}) {
    final maxHpVal = max(0, maxHp());
    final currentHp = max(0, hpCorrenti());
    final tempHp = max(0, hpTemp());
    final shield = max(0, scudo());
    final shieldDisplayTarget = max(shield, scudoRefullTarget());
    final shieldRatioTarget = max(1, shieldDisplayTarget);
    final oculumShield = max(0, scudoOculum());
    final oculumShieldMax = max(0, scudoOculumMax());
    final oculumShieldDisplayTarget = max(oculumShield, oculumShieldMax);
    final oculumShieldRatioTarget = max(1, oculumShieldDisplayTarget);
    final lines = <Widget>[];

    Widget gaugeLine({
      required String label,
      required String value,
      required double ratio,
      required Color color,
      required IconData icon,
    }) {
      final safeRatio = ratio.clamp(0.0, 1.0).toDouble();
      return Padding(
        padding: EdgeInsets.only(bottom: dense ? 7 : 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: dense ? 13 : 15),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    cleanUiText(label),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: dense ? 10.5 : 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: readableOnTheme(Colors.white),
                    fontSize: dense ? 10.5 : 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: safeRatio,
                minHeight: dense ? 5 : 7,
                color: color,
                backgroundColor: Colors.black.withValues(alpha: 0.56),
              ),
            ),
          ],
        ),
      );
    }

    lines.add(
      gaugeLine(
        label: 'HP',
        value: '$currentHp/${max(1, maxHpVal)}',
        ratio: currentHp / max(1, maxHpVal),
        color: Colors.redAccent,
        icon: Icons.favorite,
      ),
    );
    if (tempHp > 0) {
      lines.add(
        gaugeLine(
          label: 'HP Temp',
          value: '$tempHp/${max(1, maxHpVal)}',
          ratio: tempHp / max(1, maxHpVal),
          color: Colors.greenAccent,
          icon: Icons.favorite_border,
        ),
      );
    }
    lines
      ..add(
        gaugeLine(
          label: t('Scudo', 'Shield'),
          value: '$shield/$shieldDisplayTarget',
          ratio: shield / shieldRatioTarget,
          color: Colors.lightBlueAccent,
          icon: Icons.shield,
        ),
      )
      ..add(
        gaugeLine(
          label: t('Scudo Oculum', 'Oculum Shield'),
          value: '$oculumShield/$oculumShieldDisplayTarget',
          ratio: oculumShield / oculumShieldRatioTarget,
          color: eyePupilGlowColor,
          icon: Icons.visibility,
        ),
      );

    final shell = Container(
      constraints: BoxConstraints(minWidth: dense ? 230 : 280),
      padding: EdgeInsets.fromLTRB(
        dense ? 10 : 12,
        dense ? 9 : 12,
        dense ? 10 : 12,
        2,
      ),
      decoration: BoxDecoration(
        color: Color.lerp(
          secondaryColor,
          backgroundBottomColor,
          0.45,
        )!.withValues(alpha: embedded ? 0.62 : 0.48),
        borderRadius: BorderRadius.circular(
          themeFieldRadiusValue(compact: dense),
        ),
        border: Border.all(
          color: eyePupilGlowColor.withValues(alpha: embedded ? 0.46 : 0.68),
          width: themePanelBorderWidth(compact: dense) * 0.84,
        ),
        boxShadow: embedded
            ? const <BoxShadow>[]
            : [
                BoxShadow(
                  color: eyePupilGlowColor.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.stacked_line_chart,
                color: eyePupilGlowColor,
                size: dense ? 15 : 18,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  t('Vitali a percentuale', 'Percentage vitals'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: eyePupilGlowColor,
                    fontSize: dense ? 12 : 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: dense ? 7 : 10),
          ...lines,
        ],
      ),
    );

    if (embedded) return shell;
    return gothicPanel(
      borderColor: eyePupilGlowColor,
      padding: EdgeInsets.zero,
      child: shell,
    );
  }

  Widget oculumShieldPanel() {
    if (!shouldShowScudoOculum()) return const SizedBox.shrink();

    Widget shieldCell({required String label, required Widget child}) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 4),
            child: Text(
              cleanUiText(label),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: eyePupilGlowColor,
                fontSize: uiScale(11),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Container(
            height: phoneCompactUi ? 34 : 38,
            alignment: Alignment.center,
            clipBehavior: Clip.antiAlias,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.48),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: eyePupilGlowColor.withValues(alpha: 0.58),
              ),
            ),
            child: child,
          ),
        ],
      );
    }

    Widget shieldNumberField({
      required String label,
      required TextEditingController controller,
      VoidCallback? onEdited,
    }) {
      Future<void> editValue() async {
        final temp = TextEditingController(text: controller.text);
        try {
          await showDialog<void>(
            context: context,
            builder: (dialogContext) {
              return AlertDialog(
                backgroundColor: const Color(0xFF10121A),
                title: Text(
                  cleanUiText(label),
                  style: TextStyle(
                    color: eyePupilGlowColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                content: TextField(
                  controller: temp,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  cursorColor: eyePupilGlowColor,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                  decoration: fieldDecoration(t('Valore', 'Value')),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text(t('Annulla', 'Cancel')),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      controller.text = max(
                        0,
                        readIntValue(temp.text),
                      ).toString();
                      onEdited?.call();
                      if (mounted) setState(() {});
                      programmaSalvataggio();
                      Navigator.pop(dialogContext);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: eyePupilGlowColor,
                      foregroundColor:
                          eyePupilGlowColor.computeLuminance() > 0.45
                          ? Colors.black
                          : Colors.white,
                    ),
                    child: Text(t('Salva', 'Save')),
                  ),
                ],
              );
            },
          );
        } finally {
          temp.dispose();
        }
      }

      return shieldCell(
        label: label,
        child: Tooltip(
          message: t('Tocca per modificare', 'Tap to edit'),
          child: InkWell(
            onTap: editValue,
            borderRadius: BorderRadius.circular(8),
            child: SizedBox.expand(
              child: Center(
                child: Text(
                  '${max(0, readIntValue(controller.text))}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: uiScale(15),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    void clampScudoOculumToMax() {
      final maximum = scudoOculumMax();
      final current = max(0, readIntValue(scudoOculumController.text));
      if (maximum <= 0) {
        scudoOculumController.text = '0';
      } else if (current > maximum) {
        scudoOculumController.text = maximum.toString();
      }
    }

    Widget shieldValueField({
      required String label,
      required String value,
      String? helper,
    }) {
      return shieldCell(
        label: label,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: uiScale(15),
                fontWeight: FontWeight.w900,
              ),
            ),
            if (helper != null && helper.trim().isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                cleanUiText(helper),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: uiScale(9.5),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      );
    }

    Widget roundShieldButton({
      required IconData icon,
      required String tooltip,
      required VoidCallback onPressed,
    }) {
      final buttonColor =
          Color.lerp(tertiaryColor, const Color(0xFFC18435), 0.78) ??
          tertiaryColor;
      final foreground = buttonColor.computeLuminance() > 0.45
          ? Colors.black
          : Colors.white;
      final size = phoneCompactUi ? 34.0 : 36.0;

      return Tooltip(
        message: cleanUiText(tooltip),
        child: GestureDetector(
          onTap: onPressed,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: buttonColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: buttonColor.withValues(alpha: 0.2),
                  blurRadius: 7,
                ),
              ],
            ),
            child: Icon(
              icon,
              size: phoneCompactUi ? 18 : 19,
              color: foreground,
            ),
          ),
        ),
      );
    }

    return gothicPanel(
      borderColor: eyePupilGlowColor,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.visibility, color: eyePupilGlowColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t('Scudo Oculum', 'Oculum Shield'),
                  style: TextStyle(
                    color: eyePupilGlowColor,
                    fontWeight: FontWeight.w900,
                    fontSize: uiScale(15),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 430;
              final currentField = shieldNumberField(
                label: t('Attuale', 'Current'),
                controller: scudoOculumController,
                onEdited: () {
                  final current = max(
                    0,
                    readIntValue(scudoOculumController.text),
                  );
                  final maximum = scudoOculumMax();
                  if (current > maximum) {
                    final bonus = scudoOculumBonusMassimo();
                    scudoOculumMaxController.text = max(
                      0,
                      current - bonus,
                    ).toString();
                  }
                },
              );
              final manualMaxField = shieldNumberField(
                label: t('Max manuale', 'Manual max'),
                controller: scudoOculumMaxController,
                onEdited: clampScudoOculumToMax,
              );
              final maxField = shieldValueField(
                label: t('Totale', 'Total'),
                value: scudoOculumMax().toString(),
                helper: scudoOculumBonusMassimo() == 0
                    ? null
                    : '${t('Buff', 'Buff')} ${scudoOculumBonusMassimo() >= 0 ? '+' : ''}${scudoOculumBonusMassimo()}',
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: currentField),
                      SizedBox(width: compact ? 8 : 10),
                      Expanded(child: manualMaxField),
                      SizedBox(width: compact ? 8 : 10),
                      Expanded(child: maxField),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      roundShieldButton(
                        icon: Icons.remove_circle_outline,
                        tooltip: t('-1 Scudo Oculum', '-1 Oculum Shield'),
                        onPressed: () {
                          setState(() {
                            modificaScudoOculum(-1);
                            risultato = t(
                              'Scudo Oculum -1: ${scudoOculum()}/${scudoOculumMax()}.',
                              'Oculum Shield -1: ${scudoOculum()}/${scudoOculumMax()}.',
                            );
                            aggiungiLog(risultato);
                          });
                          programmaSalvataggio();
                        },
                      ),
                      const SizedBox(width: 8),
                      roundShieldButton(
                        icon: Icons.add_circle_outline,
                        tooltip: t('+1 Scudo Oculum', '+1 Oculum Shield'),
                        onPressed: () {
                          setState(() {
                            modificaScudoOculum(1);
                            risultato = t(
                              'Scudo Oculum +1: ${scudoOculum()}/${scudoOculumMax()}.',
                              'Oculum Shield +1: ${scudoOculum()}/${scudoOculumMax()}.',
                            );
                            aggiungiLog(risultato);
                          });
                          programmaSalvataggio();
                        },
                      ),
                      const SizedBox(width: 8),
                      roundShieldButton(
                        icon: Icons.refresh,
                        tooltip: t(
                          'Ricarica Scudo Oculum',
                          'Recharge Oculum Shield',
                        ),
                        onPressed: () {
                          setState(() {
                            ricaricaScudoOculum();
                            risultato = t(
                              'Scudo Oculum ricaricato: ${scudoOculum()}/${scudoOculumMax()}.',
                              'Oculum Shield recharged: ${scudoOculum()}/${scudoOculumMax()}.',
                            );
                            aggiungiLog(risultato);
                          });
                          programmaSalvataggio();
                        },
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget campoStatAttualeVisibile({
    required String key,
    required String label,
    String? helper,
  }) {
    syncVisibleCurrentStatEditor(key);
    return campoTesto(
      label: label,
      controller: visibleCurrentStatController(key),
      helper: helper,
      onChanged: (value) => setCurrentStatFromVisibleInput(key, value),
    );
  }

  Widget oculumResourcePanel() {
    final massimo = oculumMassimo();
    final current = oculumTotale();
    final ratio = oculumRatio();
    final meterColor = ratio > 0.66
        ? tertiaryColor
        : ratio > 0.33
        ? primaryColor
        : Colors.redAccent;

    return gothicPanel(
      borderColor: meterColor,
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;

          final eye = Opacity(
            opacity: (0.22 + ratio * 0.78).clamp(0.22, 1.0),
            child: Image.asset(
              'assets/icon/oculum_eye.png',
              width: compact ? 42 : 54,
              height: compact ? 42 : 54,
              cacheWidth: oculumImageCacheDimension(
                context,
                compact ? 42 : 54,
                max: 192,
              ),
              cacheHeight: oculumImageCacheDimension(
                context,
                compact ? 42 : 54,
                max: 192,
              ),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.visibility,
                color: meterColor,
                size: compact ? 38 : 50,
              ),
            ),
          );

          final controls = Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              IconButton.filledTonal(
                tooltip: '-1 Oculum',
                onPressed: () => modificaOculumAttuale(-1),
                icon: const Icon(Icons.remove),
              ),
              IconButton.filledTonal(
                tooltip: '+1 Oculum',
                onPressed: () => modificaOculumAttuale(1),
                icon: const Icon(Icons.add),
              ),
              IconButton.filledTonal(
                tooltip: t('Reset al massimo', 'Reset to max'),
                onPressed: resetOculumAttuale,
                icon: const Icon(Icons.restart_alt),
              ),
            ],
          );

          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Oculum $current/$massimo',
                style: TextStyle(
                  color: meterColor,
                  fontSize: compact ? 17 : 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 12,
                  color: meterColor,
                  backgroundColor: Colors.black45,
                ),
              ),
              const SizedBox(height: 10),
              campoStatAttualeVisibile(
                label: t('Oculum attuale', 'Current Oculum'),
                key: 'oculum',
                helper: t(
                  'Questo campo mostra l Oculum visibile: include i buff attivi.',
                  'This field shows visible Oculum: it includes active buffs.',
                ),
              ),
              const SizedBox(height: 10),
              controls,
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: eye),
                const SizedBox(height: 10),
                content,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              eye,
              const SizedBox(width: 14),
              Expanded(child: content),
            ],
          );
        },
      ),
    );
  }

  String razzaVisibile() {
    final manualRace = cleanUiText(razzaController.text).trim();
    if (manualRace.isNotEmpty) return manualRace;

    for (final tratto in trattiRazziali) {
      final nome = cleanUiText(tratto.nome).trim();
      if (nome.isNotEmpty) return nome;
    }

    return t('Razza non impostata', 'Race not set');
  }

  Widget raceIdentityPanel() {
    return gothicPanel(
      borderColor: const Color(0xFF7EE7C8),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.diversity_3, color: Color(0xFF7EE7C8)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${t('Razza visibile', 'Visible race')}: ${razzaVisibile()}',
                  style: const TextStyle(
                    color: Color(0xFF7EE7C8),
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                '${trattiRazziali.length}/13',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          if (!phoneCompactUi && !modalitaVeloce) ...[
            const SizedBox(height: 8),
            smallInfoText(
              t(
                'Se il campo resta vuoto, la Scheda mostra come Razza il primo Tratto razziale inserito nella pagina Titoli.',
                'If this field stays empty, the Sheet shows the first Racial Trait inserted on the Titles page as Race.',
              ),
            ),
          ],
          const SizedBox(height: 8),
          campoTesto(
            label: t('Razza / Linea di sangue', 'Race / Bloodline'),
            controller: razzaController,
            numero: false,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tratto in trattiRazziali.take(5))
                Chip(
                  label: Text(cleanUiText(tratto.nome)),
                  avatar: Icon(
                    tratto.equipaggiato
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: 18,
                  ),
                  backgroundColor: const Color(0xFF10121A),
                  labelStyle: TextStyle(color: primaryColor),
                  side: BorderSide(
                    color: tratto.equipaggiato
                        ? const Color(0xFF7EE7C8)
                        : primaryColor.withValues(alpha: 0.35),
                  ),
                ),
              ActionChip(
                avatar: const Icon(Icons.edit, size: 18),
                label: Text(t('Modifica tratti', 'Edit traits')),
                backgroundColor: secondaryColor,
                labelStyle: TextStyle(color: primaryColor),
                side: BorderSide(color: tertiaryColor.withValues(alpha: 0.5)),
                onPressed: () => vaiAllaFunzione(
                  page: 2,
                  anchorId: 'titles_racial_traits',
                  logTitle: t('Tratti razziali', 'Racial traits'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget oculumEyeBox() {
    return gothicPanel(
      padding: const EdgeInsets.all(10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.of(context).size.width;
          final compact = width < 520 || lightweightUi;
          final eyeWidth = compact ? width : min(width, 380.0);
          final eyeHeight = (eyeWidth * 0.56).clamp(
            compact ? 128.0 : 210.0,
            compact ? 205.0 : 280.0,
          );
          final radius = compact ? 18.0 : 22.0;

          final imageCard = SizedBox(
            width: eyeWidth,
            height: eyeHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                color: Colors.black,
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.70),
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: tertiaryColor.withValues(alpha: 0.12),
                    blurRadius: compact ? 8 : 14,
                    spreadRadius: 0.5,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius - 2),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: RepaintBoundary(
                        child: CustomPaint(
                          painter: OculumEyePainter(
                            primaryColor: primaryColor,
                            secondaryColor: secondaryColor,
                            tertiaryColor: tertiaryColor,
                            pupilGlowColor: eyePupilGlowColor,
                          ),
                        ),
                      ),
                    ),
                    if (immaginePersonaggio != null)
                      Positioned.fill(
                        child: Center(
                          child: SizedBox(
                            width: min(eyeWidth * 0.62, eyeHeight * 0.70),
                            height: min(eyeWidth * 0.62, eyeHeight * 0.70),
                            child: ClipPath(
                              clipper: const HexagonClipper(),
                              child: ColoredBox(
                                color: tertiaryColor.withValues(alpha: 0.88),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: ClipPath(
                                    clipper: const HexagonClipper(),
                                    child: Image.memory(
                                      immaginePersonaggio!,
                                      fit: BoxFit.cover,
                                      alignment: Alignment.center,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: compact ? 8 : 12,
                      right: compact ? 8 : 12,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ElevatedButton.icon(
                            onPressed: scegliImmagine,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black.withValues(
                                alpha: 0.72,
                              ),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: compact ? 7 : 14,
                                vertical: compact ? 5 : 10,
                              ),
                            ),
                            icon: Icon(Icons.image, size: compact ? 15 : 20),
                            label: Text(compact ? '+' : t('Aggiungi', 'Add')),
                          ),
                          ElevatedButton.icon(
                            onPressed: incollaImmaginePersonaggioDaClipboard,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black.withValues(
                                alpha: 0.72,
                              ),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: compact ? 7 : 14,
                                vertical: compact ? 5 : 10,
                              ),
                            ),
                            icon: Icon(
                              Icons.content_paste,
                              size: compact ? 15 : 20,
                            ),
                            label: Text(
                              compact
                                  ? t('Incolla', 'Paste')
                                  : t('Incolla', 'Paste'),
                            ),
                          ),
                          if (immaginePersonaggio != null)
                            ElevatedButton.icon(
                              onPressed: rimuoviImmagine,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent.withValues(
                                  alpha: 0.88,
                                ),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: compact ? 7 : 14,
                                  vertical: compact ? 5 : 10,
                                ),
                              ),
                              icon: Icon(Icons.delete, size: compact ? 15 : 20),
                              label: Text(
                                compact ? 'X' : t('Rimuovi', 'Remove'),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: compact ? 10 : 0,
                      right: compact ? 10 : 0,
                      bottom: compact ? 10 : 14,
                      child: Center(
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: max(180, eyeWidth - (compact ? 20 : 80)),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: compact ? 12 : 16,
                            vertical: compact ? 7 : 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.62),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: tertiaryColor.withValues(alpha: 0.22),
                            ),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              cleanUiText(
                                '${tipoSchedaController.text.toUpperCase()} • ${razzaVisibile()} • ${t('SCHEDA ${schedaCorrente + 1}/${schedePersonaggio.isEmpty ? 1 : schedePersonaggio.length}', 'SHEET ${schedaCorrente + 1}/${schedePersonaggio.isEmpty ? 1 : schedePersonaggio.length}')}',
                              ),
                              maxLines: 1,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: compact ? 11 : 12,
                                letterSpacing: compact ? 1.3 : 2,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );

          return Focus(
            focusNode: imagePasteFocusNode,
            autofocus: true,
            onKeyEvent: (node, event) {
              if (event is! KeyDownEvent ||
                  event.logicalKey != LogicalKeyboardKey.keyV ||
                  (!HardwareKeyboard.instance.isControlPressed &&
                      !HardwareKeyboard.instance.isMetaPressed)) {
                return KeyEventResult.ignored;
              }

              unawaited(incollaImmaginePersonaggioDaClipboard());
              return KeyEventResult.handled;
            },
            child: DropTarget(
              onDragEntered: (_) {
                if (!mounted) return;
                imagePasteFocusNode.requestFocus();
                setState(() => imageDropActive = true);
              },
              onDragExited: (_) {
                if (!mounted) return;
                setState(() => imageDropActive = false);
              },
              onDragDone: (detail) async {
                if (!mounted) return;
                imagePasteFocusNode.requestFocus();
                setState(() => imageDropActive = false);

                if (detail.files.isEmpty) return;

                final file = detail.files.first;
                final fileName = file.name.trim();

                try {
                  final bytes = await file.readAsBytes();
                  await importaImmaginePersonaggioDaBytes(
                    bytes,
                    sourceName: fileName.isEmpty ? 'drop Windows' : fileName,
                  );
                } catch (error) {
                  if (!mounted) return;
                  setState(() {
                    risultato = t(
                      'File non importato: non ha sostituito l’immagine attuale.',
                      'File not imported: current image was not replaced.',
                    );
                    aggiungiLog('$risultato ($error)');
                  });
                }
              },
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: imagePasteFocusNode.requestFocus,
                child: Center(
                  child: SizedBox(
                    width: eyeWidth,
                    height: eyeHeight,
                    child: Stack(
                      children: [
                        imageCard,
                        if (imageDropActive)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.62),
                                  borderRadius: BorderRadius.circular(radius),
                                  border: Border.all(
                                    color: tertiaryColor,
                                    width: 2.2,
                                  ),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.file_upload,
                                        color: tertiaryColor,
                                        size: compact ? 34 : 46,
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        t(
                                          'Rilascia qui l’immagine',
                                          'Drop the image here',
                                        ),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: compact ? 15 : 18,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        t(
                                          'Il crop si aprirà senza cancellare quella precedente.',
                                          'Crop opens without deleting the previous image.',
                                        ),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontSize: compact ? 11 : 13,
                                          fontWeight: FontWeight.w700,
                                        ),
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
          );
        },
      ),
    );
  }

  Widget quickLoreButtonsPanel() {
    return gothicPanel(
      borderColor: primaryColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('Strumenti rapidi del Manuale', 'Quick Manual Tools'),
            style: TextStyle(
              color: primaryColor,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          smallInfoText(
            t(
              'Tasti rapidi per automatizzare piccole regole narrative di Oculum. Il Titolo del Fato non dipende dal livello personaggio: dipende dal livello delle Skill della prima Art.',
              'Quick buttons to automate small narrative rules of Oculum. The Fate Title does not depend on character level: it depends on the level of the Skills of the first Art.',
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: creaPrimoTitoloDelFato,
                icon: const Icon(Icons.auto_awesome),
                style: ElevatedButton.styleFrom(
                  backgroundColor: tertiaryColor,
                  foregroundColor: tertiaryColor.computeLuminance() > 0.45
                      ? Colors.black
                      : Colors.white,
                ),
                label: const Text('Primo Titolo del Fato'),
              ),
              ElevatedButton.icon(
                onPressed: controllaTitoliDelFatoAutomatici,
                icon: const Icon(Icons.fact_check),
                style: ElevatedButton.styleFrom(
                  backgroundColor: secondaryColor,
                  foregroundColor: Colors.white,
                ),
                label: Text(
                  t('Controlla Titoli del Fato', 'Check Fate Titles'),
                ),
              ),
              ElevatedButton.icon(
                onPressed: aggiungiPaginaDiario,
                icon: const Icon(Icons.edit_note),
                style: ElevatedButton.styleFrom(
                  backgroundColor: secondaryColor,
                  foregroundColor: Colors.white,
                ),
                label: Text(
                  t('+ Diario / + Ispirazione', '+ Diary / + Inspiration'),
                ),
              ),
              ElevatedButton.icon(
                onPressed: randomizzaStatsBilanciate,
                icon: const Icon(Icons.casino),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: primaryColor.computeLuminance() > 0.45
                      ? Colors.black
                      : Colors.white,
                ),
                label: Text(t('Stats bilanciate', 'Balanced stats')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget experiencePanel() {
    final exp = expCorrente();
    final ratio = (exp / 1000).clamp(0.0, 1.0);
    final expName = expDisplayName();

    return gothicPanel(
      borderColor: tertiaryColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            expName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: tertiaryColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          smallInfoText(
            t(
              'Ogni 1000 $expName ottieni 1 livello. Nei Personaggi i livelli creano level up da assegnare; nei Mostri generano punti mostro.',
              'Every 1000 $expName grants 1 level. For Characters, levels create level ups to assign; for Monsters, they generate monster points.',
            ),
          ),
          const SizedBox(height: 8),
          smallInfoText(
            t(
              'Allenamento: se perdi ottieni EXP pari ai danni subiti meno le stats; se vinci pari ai danni fatti. Questa EXP si può ricevere una volta ogni 3 ore.',
              'Training: if you lose, gain $expName equal to damage taken minus stats; if you win, gain $expName equal to damage dealt. This $expName can be received once every 3 hours.',
            ),
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 8),
          observationExpPanel(),
          const SizedBox(height: 12),
          Text(
            '$exp / 1000',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 22,
              color: tertiaryColor,
              backgroundColor: Colors.black45,
            ),
          ),
          const SizedBox(height: 14),
          campoTesto(
            label: t('$expName attuale manuale', 'Manual current $expName'),
            controller: expController,
          ),
          const SizedBox(height: 12),
          campoTesto(
            label: t('$expName base da aggiungere', 'Base $expName to add'),
            controller: expDaAggiungereController,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: fonteExpSelezionata,
            dropdownColor: const Color(0xFF10121A),
            decoration: fieldDecoration(t('Fonte $expName', '$expName source')),
            items: [
              DropdownMenuItem(
                value: 'normale',
                child: Text(t('Nemico normale x1', 'Normal enemy x1')),
              ),
              const DropdownMenuItem(
                value: 'miniboss',
                child: Text('Mini-Boss x1.3'),
              ),
              const DropdownMenuItem(value: 'boss', child: Text('Boss x2')),
            ],
            onChanged: (value) {
              setState(() => fonteExpSelezionata = value ?? 'normale');
              programmaSalvataggio();
            },
          ),
          const SizedBox(height: 12),
          campoTesto(
            label: t('Grado nemico', 'Enemy grade'),
            controller: enemyGradeExpController,
          ),
          const SizedBox(height: 8),
          smallInfoText(
            t(
              'Anteprima $expName finale: ${expFinalePreview()} (${expSourceLabel()}, grado x${expGradeMultiplier().toStringAsFixed(2)}).',
              'Final $expName preview: ${expFinalePreview()} (${expSourceLabel()}, grade x${expGradeMultiplier().toStringAsFixed(2)}).',
            ),
            color: tertiaryColor,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: aggiungiEsperienza,
            icon: const Icon(Icons.add),
            style: ElevatedButton.styleFrom(
              backgroundColor: tertiaryColor,
              foregroundColor: tertiaryColor.computeLuminance() > 0.45
                  ? Colors.black
                  : Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
            label: Text(t('Aggiungi $expName', 'Add $expName')),
          ),
          const SizedBox(height: 18),
          SwitchListTile(
            value: rebirthato,
            activeThumbColor: tertiaryColor,
            title: Text(
              'Rebirth',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              t(
                'Riduce le soglie dei Gradi e permette crescita più rapida.',
                'Reduces Grade thresholds and allows faster growth.',
              ),
            ),
            onChanged: toggleRebirth,
          ),
          ElevatedButton.icon(
            onPressed: aggiornaGradoAutomatico,
            icon: const Icon(Icons.auto_fix_high),
            style: ElevatedButton.styleFrom(
              backgroundColor: secondaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(44),
            ),
            label: Text(t('Controlla Grado Automatico', 'Check Auto Grade')),
          ),
          const SizedBox(height: 18),
          Text(
            t(
              'Strumento Master per livelli alti',
              'Master tool for high-level sheets',
            ),
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          campoTesto(
            label: t('Livelli rapidi da aggiungere', 'Quick levels to add'),
            controller: livelliRapidiController,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: aggiungiLivelliRapidi,
            icon: const Icon(Icons.keyboard_double_arrow_up),
            style: ElevatedButton.styleFrom(
              backgroundColor: secondaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
            label: Text(t('Aggiungi livelli rapidi', 'Add quick levels')),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: randomizzaStatsBilanciate,
            icon: const Icon(Icons.casino),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: primaryColor.computeLuminance() > 0.45
                  ? Colors.black
                  : Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
            label: Text(
              t('Randomizza stats bilanciate', 'Randomize balanced stats'),
            ),
          ),
          if (!isMostro() && levelUpDaAssegnare > 0) ...[
            const SizedBox(height: 18),
            levelUpPanel(),
          ],
          if (isMostro()) ...[const SizedBox(height: 18), monsterGrowthPanel()],
        ],
      ),
    );
  }

  Widget observationExpPanel() {
    final observationAvailable = osservazionePuntiDisponibili();
    final observationTheoretical = osservazionePuntiTeorici();
    final observationAssigned = osservazionePuntiAssegnatiTotali();
    final observationAssignments = osservazionePuntiAssegnatiSicuri();
    final assignmentText = osservazioneAssegnazioniTesto();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tertiaryColor.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          campoTesto(
            label: t('Nome EXP personalizzato', 'Custom EXP name'),
            controller: expNomePersonalizzatoController,
            numero: false,
            helper: t('Vuoto = EXP.', 'Empty = EXP.'),
            onChanged: (_) {
              if (mounted) setState(() {});
            },
          ),
          const SizedBox(height: 8),
          Material(
            color: Colors.transparent,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: puoEssereOsservato,
              activeThumbColor: tertiaryColor,
              title: Text(
                t('Puo essere osservato', 'Can be observed'),
                style: TextStyle(
                  color: tertiaryColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
              subtitle: Text(
                puoEssereOsservato
                    ? t(
                        '$observationAvailable disponibili su $observationTheoretical totali. Assegnati: $observationAssigned.',
                        '$observationAvailable available out of $observationTheoretical total. Assigned: $observationAssigned.',
                      )
                    : t(
                        'Se attiva, concede 1 punto stat extra per ogni livello totale, anche retroattivo.',
                        'When active, grants 1 extra stat point per total level, including past levels.',
                      ),
              ),
              onChanged: togglePuoEssereOsservato,
            ),
          ),
          if (puoEssereOsservato) ...[
            const SizedBox(height: 8),
            smallInfoText(
              assignmentText.isEmpty
                  ? t(
                      'Nessun punto osservazione assegnato.',
                      'No observation points assigned.',
                    )
                  : t(
                      'Assegnati: $assignmentText.',
                      'Assigned: $assignmentText.',
                    ),
              color: tertiaryColor,
            ),
            const SizedBox(height: 8),
            statDropdown(
              label: t('Stat osservazione +1', 'Observation stat +1'),
              value: osservazioneStatScelta,
              onChanged: (value) {
                setState(() {
                  osservazioneStatScelta = normalizeObservationStat(value);
                });
                programmaSalvataggio();
              },
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: observationAvailable > 0
                  ? assegnaPuntoOsservazione
                  : null,
              icon: const Icon(Icons.remove_red_eye),
              style: ElevatedButton.styleFrom(
                backgroundColor: tertiaryColor,
                foregroundColor: tertiaryColor.computeLuminance() > 0.45
                    ? Colors.black
                    : Colors.white,
                minimumSize: const Size.fromHeight(44),
              ),
              label: Text(
                t(
                  'Assegna punto osservazione ($observationAvailable)',
                  'Assign observation point ($observationAvailable)',
                ),
              ),
            ),
            if (observationAssigned > 0) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final entry in observationAssignments.entries)
                    if (entry.value > 0)
                      InputChip(
                        avatar: const Icon(Icons.remove_red_eye, size: 16),
                        label: Text(
                          '+${entry.value} ${observationStatLabel(entry.key)}',
                        ),
                        backgroundColor: tertiaryColor.withValues(alpha: 0.14),
                        side: BorderSide(color: tertiaryColor),
                        labelStyle: TextStyle(
                          color: tertiaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                        onDeleted: () =>
                            rimuoviPuntoOsservazioneAssegnato(entry.key),
                        deleteIcon: Icon(
                          Icons.remove_circle_outline,
                          color: tertiaryColor,
                          size: 18,
                        ),
                        tooltip: t(
                          'Rimuovi un punto da ${observationStatLabel(entry.key)}',
                          'Remove one point from ${observationStatLabel(entry.key)}',
                        ),
                      ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget levelUpPanel() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.75),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.08),
            blurRadius: 8,
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t(
              'Level up da assegnare: $levelUpDaAssegnare',
              'Level ups to assign: $levelUpDaAssegnare',
            ),
            style: TextStyle(
              color: primaryColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          smallInfoText(
            t(
              'Scegli una statistica da +3 e una diversa da +2. Le altre due prendono +1. Ogni livello dà anche +6 Scudo e refulla gli HP.',
              'Choose one stat for +3 and a different one for +2. The other two get +1. Each level also gives +6 Shield and refills HP.',
            ),
          ),
          const SizedBox(height: 14),
          statDropdown(
            label: t('Statistica da +3', 'Stat +3'),
            value: levelUpStatTre,
            onChanged: (value) {
              levelUpStatTre = value;

              if (levelUpStatDue == levelUpStatTre) {
                levelUpStatDue = statsLevelUp.firstWhere(
                  (x) => x != levelUpStatTre,
                  orElse: () => 'Volontà',
                );
              }
            },
          ),
          const SizedBox(height: 12),
          statDropdown(
            label: t('Statistica da +2', 'Stat +2'),
            value: levelUpStatDue,
            onChanged: (value) {
              levelUpStatDue = value;

              if (levelUpStatTre == levelUpStatDue) {
                levelUpStatTre = statsLevelUp.firstWhere(
                  (x) => x != levelUpStatDue,
                  orElse: () => 'Resilienza',
                );
              }
            },
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              statChip('RES', bonusLevelUpPerStat('Resilienza')),
              statChip('VOL', bonusLevelUpPerStat('Volontà')),
              statChip('MAT', bonusLevelUpPerStat('Materia')),
              statChip('OCU', bonusLevelUpPerStat('Oculum')),
              statChip('SCUDO', 6),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => applicaLevelUp(tutti: false),
            icon: const Icon(Icons.check_circle),
            style: ElevatedButton.styleFrom(
              backgroundColor: tertiaryColor,
              foregroundColor: tertiaryColor.computeLuminance() > 0.45
                  ? Colors.black
                  : Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
            label: Text(t('Applica 1 level up', 'Apply 1 level up')),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () => applicaLevelUp(tutti: true),
            icon: const Icon(Icons.copy_all),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: primaryColor.computeLuminance() > 0.45
                  ? Colors.black
                  : Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
            label: Text(
              t(
                'Copia questa scelta su tutti i livelli in sospeso',
                'Copy this choice on all pending levels',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget monsterGrowthPanel() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tertiaryColor.withValues(alpha: 0.75),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: tertiaryColor.withValues(alpha: 0.08),
            blurRadius: 8,
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t(
              'Punti Mostro disponibili: $monsterStatPoints',
              'Available Monster Points: $monsterStatPoints',
            ),
            style: TextStyle(
              color: tertiaryColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          smallInfoText(
            t(
              'I Mostri ricevono 9 punti statistica per livello. Ogni Grado può dare +10 × Grado a una statistica scelta.',
              'Monsters get 9 stat points per level. Each Grade may give +10 × Grade to one chosen stat.',
            ),
          ),
          const SizedBox(height: 14),
          statDropdown(
            label: t('Statistica Mostro', 'Monster Stat'),
            value: monsterSelectedStat,
            onChanged: (value) => monsterSelectedStat = value,
          ),
          const SizedBox(height: 12),
          campoTesto(
            label: t('Punti da assegnare', 'Points to assign'),
            controller: monsterPointAmountController,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: assegnaPuntiMostro,
            icon: const Icon(Icons.add_chart),
            style: ElevatedButton.styleFrom(
              backgroundColor: tertiaryColor,
              foregroundColor: tertiaryColor.computeLuminance() > 0.45
                  ? Colors.black
                  : Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
            label: Text(t('Assegna punti mostro', 'Assign monster points')),
          ),
          const SizedBox(height: 18),
          statDropdown(
            label: t('Statistica bonus Grado', 'Grade bonus stat'),
            value: monsterGradeStat,
            onChanged: (value) => monsterGradeStat = value,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: applicaBonusGradoMostro,
            icon: const Icon(Icons.auto_fix_high),
            style: ElevatedButton.styleFrom(
              backgroundColor: secondaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
            label: Text(t('Applica +10 × Grado', 'Apply +10 × Grade')),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // PAGINA SCHEDA
  // =====================================================

  Widget dropdownSection({
    required String title,
    required IconData icon,
    required Color borderColor,
    required Widget child,
    bool initiallyExpanded = false,
    String? subtitle,
    String? sectionId,
  }) {
    final cleanTitle = cleanUiText(title);
    final cleanSubtitle = subtitle == null ? null : cleanUiText(subtitle);
    final compact = lightweightUi;
    final expanded =
        initiallyExpanded ||
        (sectionId != null && _expandedFunctionSections.contains(sectionId));
    final storageId = sectionId ?? cleanTitle;

    return gothicPanel(
      borderColor: borderColor,
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          // Keep expansion state away from Flutter PageStorage. Scroll offsets
          // and ExpansionTile booleans can otherwise collide after hot reload
          // or navigation changes and crash with bool/double casts.
          key: sheetExpansionKey(storageId),
          initiallyExpanded: expanded,
          onExpansionChanged: sectionId == null
              ? null
              : (value) {
                  if (!mounted) return;
                  setState(() {
                    if (value) {
                      _expandedFunctionSections.add(sectionId);
                    } else {
                      _expandedFunctionSections.remove(sectionId);
                    }
                  });
                },
          iconColor: borderColor,
          collapsedIconColor: borderColor,
          tilePadding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 12,
            vertical: 0,
          ),
          childrenPadding: EdgeInsets.fromLTRB(
            compact ? 8 : 12,
            0,
            compact ? 8 : 12,
            compact ? 8 : 12,
          ),
          leading: Icon(icon, color: borderColor, size: compact ? 18 : 22),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cleanTitle,
                maxLines: compact ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: borderColor,
                  fontWeight: FontWeight.w900,
                  fontSize: compact ? 13.5 : null,
                ),
              ),
              if (cleanSubtitle != null && !compact) ...[
                const SizedBox(height: 3),
                Text(
                  cleanSubtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFBFB7DD),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                  ),
                ),
              ],
            ],
          ),
          trailing: Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: borderColor.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.expand_more, color: borderColor, size: 20),
          ),
          children: [child],
        ),
      ),
    );
  }

  Widget quickIndexButtonsPanel() {
    if (!mostraTastiRapidiIndice) return const SizedBox.shrink();

    final entries = <Map<String, dynamic>>[
      {
        'label': t('Scheda', 'Sheet'),
        'page': 0,
        'icon': Icons.visibility_outlined,
        'anchorId': 'sheet_identity',
      },
      {
        'label': t('Borsa', 'Bag'),
        'page': 6,
        'icon': Icons.backpack_outlined,
        'anchorId': 'inventory_root',
      },
      {
        'label': t('Regole', 'Rules'),
        'page': 8,
        'icon': Icons.rule_outlined,
        'anchorId': 'rules_root',
      },
      {
        'label': t('Party', 'Party'),
        'page': 0,
        'icon': Icons.groups,
        'anchorId': 'sheet_party',
      },
      {
        'label': t('Opzioni', 'Options'),
        'page': _OculumHomePageState.settingsPageIndex,
        'icon': Icons.settings_outlined,
        'anchorId': 'settings_root',
      },
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final entry in entries) ...[
            ElevatedButton.icon(
              onPressed: () {
                vaiAllaFunzione(
                  page: readIntValue(entry['page']),
                  anchorId: '${entry['anchorId'] ?? ''}',
                  logTitle: entry['label'] as String,
                );
              },
              icon: Icon(entry['icon'] as IconData, size: 18),
              style: ElevatedButton.styleFrom(
                backgroundColor: secondaryColor,
                foregroundColor: primaryColor,
                side: BorderSide(color: tertiaryColor.withValues(alpha: 0.45)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
              ),
              label: Text('${entry['label']}'),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget quickAdjustButton({
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onPressed,
  }) {
    final compact = lightweightUi;
    final background = const Color(0xFF080A12);
    final accent = readableOnTheme(color, background: background, minRatio: 3);
    final size = compact ? 24.0 : 28.0;

    return Tooltip(
      message: cleanUiText(tooltip),
      child: IconButton(
        onPressed: onPressed,
        constraints: BoxConstraints.tightFor(width: size, height: size),
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        style: IconButton.styleFrom(
          backgroundColor: accent.withValues(alpha: 0.16),
          foregroundColor: accent,
          side: BorderSide(color: accent.withValues(alpha: 0.45)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(compact ? 6 : 7),
          ),
        ),
        icon: Icon(icon, size: compact ? 14 : 16),
      ),
    );
  }

  void modificaHpRapido(int delta) {
    if (delta == 0) return;
    setState(() {
      final before = hpCorrenti();
      final next = (before + delta).clamp(0, maxHp()).toInt();
      currentHpController.text = next.toString();
      risultato =
          'HP attuali: ${next - before >= 0 ? '+' : ''}${next - before} ($next/${maxHp()}).';
      aggiungiLog(risultato);
    });
    programmaSalvataggio();
    sendRealtimeHpChanged();
  }

  void modificaHpTempRapido(int delta) {
    if (delta == 0) return;
    setState(() {
      final before = hpTemp();
      final next = max(0, before + delta);
      impostaHpTempTotali(next);
      risultato =
          'HP Temp: ${next - before >= 0 ? '+' : ''}${next - before} ($next).';
      aggiungiLog(risultato);
    });
    programmaSalvataggio();
    sendRealtimeHpChanged();
  }

  void modificaScudoRapido(int delta) {
    if (delta == 0) return;
    setState(() {
      final before = scudo();
      final next = max(0, before + delta);
      impostaScudoTotale(next);
      risultato =
          '${t('Scudo', 'Shield')}: ${next - before >= 0 ? '+' : ''}${next - before} ($next).';
      aggiungiLog(risultato);
    });
    programmaSalvataggio();
    sendRealtimeHpChanged();
  }

  void modificaScudoCriticoRapido(int delta) {
    if (delta == 0) return;
    setState(() {
      final before = scudoCritico();
      final next = max(0, before + delta);
      scudoCriticoController.text = next.toString();
      risultato =
          '${t('Scudo Critico', 'Critical Shield')}: ${next - before >= 0 ? '+' : ''}${next - before} ($next).';
      aggiungiLog(risultato);
    });
    programmaSalvataggio();
    sendRealtimeHpChanged();
  }

  void modificaControllerNumericoRapido(
    TextEditingController controller,
    int delta, {
    required String label,
    bool allowNegative = false,
    VoidCallback? afterChange,
  }) {
    if (delta == 0) return;
    setState(() {
      final before = readIntValue(controller.text);
      final next = allowNegative ? before + delta : max(0, before + delta);
      controller.text = next.toString();
      afterChange?.call();
      risultato =
          '$label: ${next - before >= 0 ? '+' : ''}${next - before} ($next).';
      aggiungiLog(risultato);
    });
    programmaSalvataggio();
  }

  void modificaBuffMalusRapido({
    required String rawKey,
    required String label,
    required int delta,
  }) {
    if (delta == 0) return;

    setState(() {
      final text = buffMalusRapidiController.text.trim();
      final pattern = RegExp(
        '(^|\\s)@${RegExp.escape(rawKey)}([+-]\\d+)(?=\\s|\$)',
        caseSensitive: false,
      );
      final match = pattern.firstMatch(text);
      final current = match == null
          ? 0
          : int.tryParse(match.group(2) ?? '0') ?? 0;
      final next = current + delta;
      final token = '@$rawKey${next >= 0 ? '+' : ''}$next';
      String nextText;

      if (match == null) {
        nextText = next == 0
            ? text
            : [text, token].where((part) => part.trim().isNotEmpty).join(' ');
      } else {
        final prefix = match.group(1) ?? '';
        nextText = text.replaceRange(
          match.start,
          match.end,
          next == 0 ? prefix : '$prefix$token',
        );
      }

      buffMalusRapidiController.text = nextText
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      risultato =
          '$label rapido ${delta > 0 ? '+' : ''}$delta. Bonus $label: $next.';
      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  Widget quickStatTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
    VoidCallback? onRoll,
    VoidCallback? onDecrease,
    VoidCallback? onIncrease,
  }) {
    final compact = lightweightUi;
    final spec = currentThemeDecorationSpec();
    final guiStyle = currentThemeVisualIdentity().mainSheetGuiStyle.id;
    final clippedTile = <String>{
      'phobia',
      'postea',
      'kingi',
      'medieval',
      'rank_hud',
      'sigil',
      'archive',
      'relic',
    }.contains(guiStyle);
    final tileBackground = switch (guiStyle) {
      'phobia' => Color.lerp(
        spec.backgroundBottom,
        const Color(0xFF071527),
        0.44,
      )!,
      'postea' || 'kingi' || 'medieval' => Color.lerp(
        spec.backgroundBottom,
        const Color(0xFF102334),
        0.48,
      )!,
      'botanical' => Color.lerp(
        spec.backgroundBottom,
        const Color(0xFF101C13),
        0.38,
      )!,
      'lunar' || 'soft_orbital' => Color.lerp(
        spec.backgroundBottom,
        const Color(0xFF11152A),
        0.42,
      )!,
      'archive' || 'relic' => Color.lerp(
        spec.backgroundBottom,
        const Color(0xFF17130D),
        0.34,
      )!,
      'rank_hud' || 'sigil' => Color.lerp(
        spec.backgroundBottom,
        const Color(0xFF120C28),
        0.44,
      )!,
      _ => const Color(0xFF080A12),
    };
    final accent = readableOnTheme(
      color,
      background: tileBackground,
      minRatio: 3.5,
    );
    final labelColor = readableOnTheme(
      const Color(0xFFBFB7DD),
      background: tileBackground,
    );
    final hasControls =
        onRoll != null || onDecrease != null || onIncrease != null;
    final tileRadius = switch (guiStyle) {
      'phobia' => compact ? 4.0 : 6.0,
      'postea' || 'kingi' || 'medieval' => compact ? 5.0 : 7.0,
      'botanical' => compact ? 12.0 : 14.0,
      'lunar' || 'soft_orbital' => compact ? 14.0 : 16.0,
      _ => compact ? 8.0 : 10.0,
    };
    final tileGradient = switch (guiStyle) {
      'phobia' => LinearGradient(
        colors: [
          tileBackground,
          Color.lerp(tileBackground, spec.accent, 0.16)!,
          Colors.black.withValues(alpha: 0.96),
        ],
        stops: const [0.0, 0.58, 1.0],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      'postea' || 'kingi' || 'medieval' => LinearGradient(
        colors: [
          Color.lerp(tileBackground, spec.primary, 0.09)!,
          tileBackground,
          Color.lerp(tileBackground, spec.accent, 0.10)!,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      'botanical' => LinearGradient(
        colors: [
          Color.lerp(tileBackground, spec.secondary, 0.13)!,
          tileBackground,
          Color.lerp(tileBackground, spec.primary, 0.08)!,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      _ => LinearGradient(colors: [tileBackground, tileBackground]),
    };

    Widget valueText({bool centered = false}) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onRoll ?? onTap,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: centered ? Alignment.center : Alignment.centerLeft,
          child: Text(
            value,
            textAlign: centered ? TextAlign.center : TextAlign.start,
            maxLines: 1,
            softWrap: false,
            style: TextStyle(
              color: accent,
              fontSize: compact ? 13.2 : 16.5,
              fontWeight: FontWeight.w900,
              shadows: readableTextShadow(accent, background: tileBackground),
            ),
          ),
        ),
      );
    }

    final tileContent = Container(
      constraints: BoxConstraints(
        minWidth: hasControls ? (compact ? 96 : 122) : (compact ? 70 : 96),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 10,
        vertical: compact ? 5 : 9,
      ),
      decoration: BoxDecoration(
        gradient: tileGradient,
        borderRadius: BorderRadius.circular(tileRadius),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
        boxShadow: compact
            ? const <BoxShadow>[]
            : [
                BoxShadow(
                  color: accent.withValues(
                    alpha: guiStyle == 'phobia' ? 0.16 : 0.08,
                  ),
                  blurRadius: guiStyle == 'phobia' ? 10 : 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Stack(
        children: [
          if (clippedTile)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _OculumThemePanelChromePainter(
                    spec: spec,
                    guiStyle: guiStyle,
                    borderColor: accent,
                    compact: true,
                    clipped: clippedTile,
                  ),
                ),
              ),
            ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: accent, size: compact ? 14 : 18),
              SizedBox(width: compact ? 5 : 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: labelColor,
                        fontSize: compact ? 9.2 : 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: compact ? 0 : 2),
                    if (hasControls)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (onDecrease != null)
                            quickAdjustButton(
                              icon: Icons.remove,
                              tooltip: '-1 $label',
                              color: accent,
                              onPressed: onDecrease,
                            ),
                          if (onDecrease != null) const SizedBox(width: 3),
                          Flexible(child: valueText(centered: true)),
                          if (onIncrease != null) const SizedBox(width: 3),
                          if (onIncrease != null)
                            quickAdjustButton(
                              icon: Icons.add,
                              tooltip: '+1 $label',
                              color: accent,
                              onPressed: onIncrease,
                            ),
                        ],
                      )
                    else
                      valueText(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
    final tile = clippedTile
        ? ClipPath(
            clipper: _OculumThemePanelClipper(
              guiStyle: guiStyle,
              compact: true,
            ),
            child: tileContent,
          )
        : tileContent;

    final contextualTile = quickContextMenuAnchor(
      label: label,
      child: tile,
      onEdit: onTap,
      onRoll: onRoll,
      onDecrease: onDecrease,
      onIncrease: onIncrease,
    );

    if (onTap == null) return contextualTile;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(tileRadius),
        onTap: onTap,
        child: contextualTile,
      ),
    );
  }

  Widget quickContextMenuAnchor({
    required String label,
    required Widget child,
    VoidCallback? onEdit,
    VoidCallback? onRoll,
    VoidCallback? onDecrease,
    VoidCallback? onIncrease,
    String? manualQuery,
  }) {
    if (onEdit == null &&
        onRoll == null &&
        onDecrease == null &&
        onIncrease == null) {
      return child;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onSecondaryTapDown: (details) => showQuickContextMenu(
        label: label,
        position: details.globalPosition,
        onEdit: onEdit,
        onRoll: onRoll,
        onDecrease: onDecrease,
        onIncrease: onIncrease,
        manualQuery: manualQuery,
      ),
      child: child,
    );
  }

  Future<void> showQuickContextMenu({
    required String label,
    required Offset position,
    VoidCallback? onEdit,
    VoidCallback? onRoll,
    VoidCallback? onDecrease,
    VoidCallback? onIncrease,
    String? manualQuery,
  }) async {
    final cleanLabel = cleanUiText(label).trim();
    final choice = await showMenu<String>(
      context: context,
      color: const Color(0xFF10121A),
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: [
        if (onRoll != null)
          PopupMenuItem<String>(
            value: 'roll',
            child: Row(
              children: [
                Icon(Icons.casino, color: tertiaryColor, size: 18),
                const SizedBox(width: 10),
                Text(t('Tira $cleanLabel', 'Roll $cleanLabel')),
              ],
            ),
          ),
        if (onEdit != null)
          PopupMenuItem<String>(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit, color: primaryColor, size: 18),
                const SizedBox(width: 10),
                Text(t('Modifica', 'Edit')),
              ],
            ),
          ),
        PopupMenuItem<String>(
          value: 'manual',
          child: Row(
            children: [
              Icon(Icons.menu_book, color: primaryColor, size: 18),
              const SizedBox(width: 10),
              Text(t('Vedi nel manuale', 'View in manual')),
            ],
          ),
        ),
        if (onDecrease != null || onIncrease != null) const PopupMenuDivider(),
        if (onDecrease != null)
          PopupMenuItem<String>(
            value: 'decrease',
            child: Row(
              children: [
                const Icon(Icons.remove, color: Colors.redAccent, size: 18),
                const SizedBox(width: 10),
                Text('-1 $cleanLabel'),
              ],
            ),
          ),
        if (onIncrease != null)
          PopupMenuItem<String>(
            value: 'increase',
            child: Row(
              children: [
                const Icon(Icons.add, color: Colors.greenAccent, size: 18),
                const SizedBox(width: 10),
                Text('+1 $cleanLabel'),
              ],
            ),
          ),
      ],
    );

    if (!mounted || choice == null) return;
    switch (choice) {
      case 'roll':
        onRoll?.call();
        break;
      case 'edit':
        onEdit?.call();
        break;
      case 'manual':
        openManualForQuickTerm(manualQuery ?? cleanLabel);
        break;
      case 'decrease':
        onDecrease?.call();
        break;
      case 'increase':
        onIncrease?.call();
        break;
    }
  }

  void openManualForQuickTerm(String rawTerm) {
    final term = cleanUiText(rawTerm).trim();
    if (term.isEmpty) return;
    final normalizedTerm = term.toLowerCase();
    final matchIndex = activeManualSections.indexWhere((section) {
      final haystack =
          '${manualTitle(section)} ${manualContent(section)} ${section.titleIt} ${section.titleEn} ${section.contentIt} ${section.contentEn}'
              .toLowerCase();
      return haystack.contains(normalizedTerm);
    });

    manualSearchController.text = term;
    manualSearchText = term;
    vaiAllaFunzione(
      page: 8,
      manualIndex: matchIndex >= 0 ? matchIndex : null,
      logTitle: t('Manuale: $term', 'Manual: $term'),
    );
  }

  Widget quickCommandButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    final cleanLabel = cleanUiText(label);
    final compact = lightweightUi;
    final spec = currentThemeDecorationSpec();
    final guiStyle = currentThemeVisualIdentity().mainSheetGuiStyle.id;
    final clippedButton = <String>{
      'phobia',
      'postea',
      'kingi',
      'medieval',
      'rank_hud',
      'sigil',
      'archive',
      'relic',
    }.contains(guiStyle);
    final buttonBackground = switch (guiStyle) {
      'phobia' => Color.lerp(
        spec.backgroundBottom,
        const Color(0xFF18060A),
        0.58,
      )!,
      'postea' || 'kingi' || 'medieval' => Color.lerp(
        spec.backgroundBottom,
        const Color(0xFF102638),
        0.46,
      )!,
      'botanical' => Color.lerp(
        spec.backgroundBottom,
        const Color(0xFF102016),
        0.40,
      )!,
      'lunar' || 'soft_orbital' => Color.lerp(
        spec.backgroundBottom,
        const Color(0xFF11162C),
        0.42,
      )!,
      'archive' || 'relic' => Color.lerp(
        spec.backgroundBottom,
        const Color(0xFF18110B),
        0.40,
      )!,
      'rank_hud' || 'sigil' => Color.lerp(
        spec.backgroundBottom,
        const Color(0xFF12092B),
        0.48,
      )!,
      _ => const Color(0xFF0B0D16),
    };
    final foreground = readableOnTheme(
      color,
      background: buttonBackground,
      minRatio: 3.6,
    );
    final radius = switch (guiStyle) {
      'phobia' => compact ? 4.0 : 5.0,
      'postea' || 'kingi' || 'medieval' => compact ? 5.0 : 7.0,
      'botanical' => compact ? 13.0 : 15.0,
      'lunar' || 'soft_orbital' => compact ? 14.0 : 16.0,
      _ => compact ? 8.0 : 10.0,
    };
    final Gradient gradient = switch (guiStyle) {
      'phobia' => LinearGradient(
        colors: [
          Colors.black.withValues(alpha: 0.96),
          Color.lerp(buttonBackground, spec.accent, 0.16)!,
          buttonBackground,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      'postea' || 'kingi' || 'medieval' => LinearGradient(
        colors: [
          Color.lerp(buttonBackground, spec.primary, 0.14)!,
          buttonBackground,
          Color.lerp(buttonBackground, spec.accent, 0.14)!,
        ],
        stops: const [0.0, 0.54, 1.0],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      'botanical' => LinearGradient(
        colors: [
          Color.lerp(buttonBackground, spec.secondary, 0.18)!,
          buttonBackground,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      'lunar' || 'soft_orbital' => RadialGradient(
        colors: [
          Color.lerp(buttonBackground, spec.accent, 0.14)!,
          buttonBackground,
        ],
        center: Alignment.topLeft,
        radius: 1.3,
      ),
      _ => LinearGradient(colors: [buttonBackground, buttonBackground]),
    };

    final buttonBody = ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: compact ? 28 : 34,
        maxWidth: compact ? 148 : 190,
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 11,
          vertical: compact ? 5 : 8,
        ),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: foreground.withValues(alpha: 0.58)),
          boxShadow: compact
              ? const <BoxShadow>[]
              : [
                  BoxShadow(
                    color: foreground.withValues(
                      alpha: guiStyle == 'phobia' ? 0.16 : 0.08,
                    ),
                    blurRadius:
                        guiStyle == 'postea' ||
                            guiStyle == 'kingi' ||
                            guiStyle == 'medieval'
                        ? 12
                        : 8,
                  ),
                ],
        ),
        child: Stack(
          children: [
            if (clippedButton)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _OculumThemePanelChromePainter(
                      spec: spec,
                      guiStyle: guiStyle,
                      borderColor: foreground,
                      compact: true,
                      clipped: clippedButton,
                    ),
                  ),
                ),
              ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: foreground, size: compact ? 14 : 17),
                SizedBox(width: compact ? 5 : 7),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      cleanLabel,
                      maxLines: 1,
                      softWrap: false,
                      style: TextStyle(
                        color: foreground,
                        fontWeight: FontWeight.w900,
                        fontSize: compact ? 11.2 : 13.2,
                        shadows: readableTextShadow(
                          foreground,
                          background: buttonBackground,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    final button = clippedButton
        ? ClipPath(
            clipper: _OculumThemePanelClipper(
              guiStyle: guiStyle,
              compact: true,
            ),
            child: buttonBody,
          )
        : buttonBody;

    return Semantics(
      button: true,
      label: cleanLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onPressed,
          child: button,
        ),
      ),
    );
  }

  Widget equippedTitlesStrip({bool compact = false}) {
    final equipped = <MapEntry<OculumTitle, bool>>[
      for (final titolo in titoli.where((titolo) => titolo.equipaggiato))
        MapEntry(titolo, false),
      for (final titolo in trattiRazziali.where(
        (titolo) => titolo.equipaggiato,
      ))
        MapEntry(titolo, true),
    ];

    if (equipped.isEmpty) {
      return smallInfoText(
        t('Nessun titolo indossato.', 'No equipped title.'),
        color: Colors.grey.shade400,
      );
    }

    return Wrap(
      spacing: compact ? 6 : 8,
      runSpacing: compact ? 6 : 8,
      children: [
        for (final entry in equipped.take(compact ? 4 : 7))
          ActionChip(
            avatar: Icon(
              entry.key.openAttiva
                  ? Icons.lock_open
                  : entry.key.evoluto
                  ? Icons.auto_awesome
                  : Icons.workspace_premium,
              size: compact ? 15 : 17,
              color: entry.key.openAttiva ? Colors.black : tertiaryColor,
            ),
            label: Text(
              cleanUiText(entry.key.nome),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            tooltip: cleanUiText(
              entry.key.openAttiva
                  ? '${t('Open attiva', 'Open active')}: ${entry.key.openName.isEmpty ? entry.key.nome : entry.key.openName}'
                  : entry.key.tipo,
            ),
            backgroundColor: entry.key.openAttiva
                ? tertiaryColor
                : secondaryColor.withValues(alpha: 0.65),
            side: BorderSide(
              color: entry.key.openAttiva
                  ? tertiaryColor
                  : primaryColor.withValues(alpha: 0.55),
            ),
            labelStyle: TextStyle(
              color: entry.key.openAttiva ? Colors.black : primaryColor,
              fontWeight: FontWeight.w900,
              fontSize: compact ? 11 : 12,
            ),
            onPressed: () => vaiAllaFunzione(
              page: 2,
              anchorId: titleEditorAnchorId(
                entry.key,
                trattoRazziale: entry.value,
              ),
              logTitle: cleanUiText(entry.key.nome),
            ),
          ),
      ],
    );
  }

  Widget sheetCommandCenter() {
    final compact = lightweightUi;
    return gothicPanel(
      borderColor: tertiaryColor,
      padding: EdgeInsets.all(compact ? 10 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: tertiaryColor,
                size: compact ? 18 : 24,
              ),
              SizedBox(width: compact ? 8 : 10),
              Expanded(
                child: Text(
                  t('Centro partita', 'Play center'),
                  style: TextStyle(
                    color: tertiaryColor,
                    fontSize: compact ? 15 : 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              FilterChip(
                selected: modalitaVeloce,
                showCheckmark: false,
                avatar: Icon(
                  modalitaVeloce ? Icons.bolt : Icons.menu_book,
                  size: compact ? 14 : 16,
                  color: modalitaVeloce ? Colors.black : tertiaryColor,
                ),
                label: Text(
                  modalitaVeloce ? t('Veloce', 'Fast') : t('Guidata', 'Guided'),
                ),
                selectedColor: tertiaryColor,
                backgroundColor: const Color(0xFF0B0D16),
                labelStyle: TextStyle(
                  color: modalitaVeloce ? Colors.black : tertiaryColor,
                  fontWeight: FontWeight.w900,
                ),
                side: BorderSide(color: tertiaryColor.withValues(alpha: 0.65)),
                onSelected: (value) {
                  setState(() {
                    modalitaVeloce = value;
                    risultato = modalitaVeloce
                        ? t(
                            'Modalità veloce attiva: la scheda mostra prima le azioni essenziali.',
                            'Fast mode active: the sheet shows essential actions first.',
                          )
                        : t(
                            'Modalità guidata attiva: la scheda mostra più spiegazioni.',
                            'Guided mode active: the sheet shows more explanations.',
                          );
                    aggiungiLog(risultato);
                  });
                  programmaSalvataggio();
                },
              ),
            ],
          ),
          SizedBox(height: compact ? 7 : 10),
          if (!modalitaVeloce) ...[
            smallInfoText(
              t(
                'Per iniziare: imposta nome e stats, tieni d occhio HP e Scudo, tira VC per attaccare e CM quando serve difenderti. Se vuoi andare rapido, attiva Veloce.',
                'To start: set name and stats, watch HP and Shield, roll VC to attack and CM when you need defense. Turn on Fast when you want less page noise.',
              ),
            ),
            SizedBox(height: compact ? 8 : 12),
          ],
          Wrap(
            spacing: compact ? 6 : 8,
            runSpacing: compact ? 6 : 8,
            children: [
              quickStatTile(
                label: 'HP',
                value: '${hpCorrenti()}/${maxHp()}',
                icon: Icons.favorite,
                color: Colors.redAccent,
                onTap: () => apriDannoCuraDalCentroPartita(target: 'hp'),
                onRoll: () => tiraValoreSpeciale('HP', hpCorrenti()),
                onDecrease: () => modificaHpRapido(-1),
                onIncrease: () => modificaHpRapido(1),
              ),
              quickStatTile(
                label: t('Scudo', 'Shield'),
                value: '${scudo()}',
                icon: Icons.shield,
                color: Colors.lightBlueAccent,
                onTap: () => vaiAllaFunzione(
                  page: 0,
                  anchorId: 'sheet_shield',
                  logTitle: t('Scudo', 'Shield'),
                ),
                onRoll: () => tiraValoreSpeciale(t('Scudo', 'Shield'), scudo()),
                onDecrease: () => modificaScudoRapido(-1),
                onIncrease: () => modificaScudoRapido(1),
              ),
              if (shouldShowScudoOculum())
                quickStatTile(
                  label: t('Scudo Oculum', 'Oculum Shield'),
                  value: '${scudoOculum()}/${scudoOculumMax()}',
                  icon: Icons.visibility,
                  color: eyePupilGlowColor,
                  onTap: () => vaiAllaFunzione(
                    page: 0,
                    anchorId: 'sheet_hp',
                    logTitle: t('Scudo Oculum', 'Oculum Shield'),
                  ),
                  onRoll: () => tiraValoreSpeciale(
                    t('Scudo Oculum', 'Oculum Shield'),
                    scudoOculum(),
                  ),
                  onDecrease: () {
                    setState(() {
                      modificaScudoOculum(-1);
                      risultato = t(
                        'Scudo Oculum -1: ${scudoOculum()}/${scudoOculumMax()}.',
                        'Oculum Shield -1: ${scudoOculum()}/${scudoOculumMax()}.',
                      );
                      aggiungiLog(risultato);
                    });
                    programmaSalvataggio();
                    sendRealtimeHpChanged();
                  },
                  onIncrease: () {
                    setState(() {
                      modificaScudoOculum(1);
                      risultato = t(
                        'Scudo Oculum +1: ${scudoOculum()}/${scudoOculumMax()}.',
                        'Oculum Shield +1: ${scudoOculum()}/${scudoOculumMax()}.',
                      );
                      aggiungiLog(risultato);
                    });
                    programmaSalvataggio();
                    sendRealtimeHpChanged();
                  },
                ),
              quickStatTile(
                label: 'VC',
                value: '${vc()}',
                icon: Icons.flash_on,
                color: tertiaryColor,
                onTap: () => vaiAllaFunzione(
                  page: 0,
                  anchorId: 'sheet_editable_values_volonta',
                ),
                onRoll: () => tiraValoreSpeciale('VC', vc()),
                onDecrease: () => modificaAttaccoRapido(-1),
                onIncrease: () => modificaAttaccoRapido(1),
              ),
              quickStatTile(
                label: 'CM',
                value: '${cm()}',
                icon: Icons.security,
                color: primaryColor,
                onTap: () => vaiAllaFunzione(
                  page: 0,
                  anchorId: 'sheet_editable_values_materia',
                ),
                onRoll: () => tiraValoreSpeciale('CM', cm()),
                onDecrease: () => modificaBonusCmRapido(-1),
                onIncrease: () => modificaBonusCmRapido(1),
              ),
              quickStatTile(
                label: t('Danno', 'Damage'),
                value: '${dannoTotale()}',
                icon: Icons.close,
                color: elementColor(elementoDannoDominante()),
                onTap: () => apriDannoCuraDalCentroPartita(target: 'damage'),
                onRoll: () =>
                    tiraValoreSpeciale(t('Danno', 'Damage'), dannoTotale()),
                onDecrease: () => modificaBuffMalusRapido(
                  rawKey: 'Danni',
                  label: t('Danno', 'Damage'),
                  delta: -1,
                ),
                onIncrease: () => modificaBuffMalusRapido(
                  rawKey: 'Danni',
                  label: t('Danno', 'Damage'),
                  delta: 1,
                ),
              ),
              Builder(
                builder: (context) {
                  final domDif = elementoDifesaDominante();
                  final labelDifesa =
                      t('Difesa', 'Defense') +
                      (domDif.isNotEmpty
                          ? ' — ${elementDisplayName(domDif)}'
                          : '');
                  return quickStatTile(
                    label: labelDifesa,
                    value: '${difesa()}',
                    icon: Icons.shield_outlined,
                    color: domDif.isNotEmpty
                        ? elementColor(domDif)
                        : Colors.lightGreenAccent,
                    onTap: () => vaiAllaFunzione(
                      page: 0,
                      anchorId: 'sheet_defense_bonus',
                      logTitle: t('Difesa', 'Defense'),
                    ),
                    onRoll: () =>
                        tiraValoreSpeciale(t('Difesa', 'Defense'), difesa()),
                    onDecrease: () => modificaDifesaRapida(-1),
                    onIncrease: () => modificaDifesaRapida(1),
                  );
                },
              ),
              quickStatTile(
                label: t('Reazioni', 'Reactions'),
                value: reazioniVelociTotali() > 0
                    ? '${reazioniTotali()} +${reazioniVelociTotali()}V'
                    : '${reazioniTotali()}',
                icon: Icons.reply_all,
                color: Colors.orangeAccent,
                onTap: mostraModificaRapida,
                onRoll: () => tiraValoreSpeciale(
                  t('Reazioni', 'Reactions'),
                  reazioniTotali(),
                ),
                onDecrease: () => modificaControllerNumericoRapido(
                  reazioniController,
                  -1,
                  label: t('Reazioni', 'Reactions'),
                ),
                onIncrease: () => modificaControllerNumericoRapido(
                  reazioniController,
                  1,
                  label: t('Reazioni', 'Reactions'),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 8 : 12),
          Row(
            children: [
              Icon(
                Icons.workspace_premium,
                color: primaryColor,
                size: compact ? 16 : 18,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  t('Titoli indossati', 'Equipped titles'),
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w900,
                    fontSize: compact ? 12 : 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          equippedTitlesStrip(compact: compact),
          SizedBox(height: compact ? 8 : 12),
          Wrap(
            spacing: compact ? 6 : 8,
            runSpacing: compact ? 6 : 8,
            children: [
              quickCommandButton(
                label: t('Tira VC', 'Roll VC'),
                icon: Icons.casino,
                color: tertiaryColor,
                onPressed: () => tiraValoreSpeciale('VC', vc()),
              ),
              quickCommandButton(
                label: t('Tira CM', 'Roll CM'),
                icon: Icons.security,
                color: primaryColor,
                onPressed: () => tiraValoreSpeciale('CM', cm()),
              ),
              quickCommandButton(
                label: compact ? '+CM base' : '+1 CM base',
                icon: Icons.add_circle_outline,
                color: primaryColor,
                onPressed: () => modificaBonusCmRapido(1),
              ),
              quickCommandButton(
                label: compact ? '+CM' : '+1 CM (+2 Materia)',
                icon: Icons.add_circle_outline,
                color: Colors.lightBlueAccent,
                onPressed: () => modificaCmRapido(1),
              ),
              quickCommandButton(
                label: compact ? '+VC' : '+1 VC (+3 Volonta)',
                icon: Icons.add_circle,
                color: Colors.redAccent,
                onPressed: () => modificaVcRapido(1),
              ),
              quickCommandButton(
                label: compact ? '+ATK' : '+1 Attacco',
                icon: Icons.flash_on,
                color: Colors.orangeAccent,
                onPressed: () => modificaAttaccoRapido(1),
              ),
              quickCommandButton(
                label: compact ? '+DIF' : '+1 Difesa',
                icon: Icons.shield_outlined,
                color: Colors.lightGreenAccent,
                onPressed: () => modificaDifesaRapida(1),
              ),
              quickCommandButton(
                label: t('Aiuta compagno', 'Help ally'),
                icon: Icons.volunteer_activism,
                color: const Color(0xFF7EE7C8),
                onPressed: tiraAiutaCompagno,
              ),
              quickCommandButton(
                label: t('Modifica', 'Edit'),
                icon: Icons.tune,
                color: primaryColor,
                onPressed: mostraModificaRapida,
              ),
              if (!compact) ...[
                quickCommandButton(
                  label: t('Riposo', 'Rest'),
                  icon: Icons.hotel,
                  color: const Color(0xFF7EE7C8),
                  onPressed: () {
                    vaiAllaFunzione(
                      page: 1,
                      anchorId: 'rest_root',
                      logTitle: t('Riposo', 'Rest'),
                    );
                  },
                ),
                quickCommandButton(
                  label: t('Cerca regola', 'Find rule'),
                  icon: Icons.search,
                  color: Colors.lightBlueAccent,
                  onPressed: mostraCerca,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget editableMainValuesDropdown() {
    if (!mostraValoriEditabiliScheda) return const SizedBox.shrink();

    return dropdownSection(
      title: t('Valori principali modificabili', 'Editable main values'),
      subtitle: t(
        'Numeri che cambiano spesso durante la sessione.',
        'Numbers that often change during play.',
      ),
      icon: Icons.tune,
      borderColor: tertiaryColor,
      sectionId: 'sheet_editable_values',
      initiallyExpanded: false,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: campoTesto(
                  label: t('Livello', 'Level'),
                  controller: livelloController,
                  helper: t(
                    'Aumenta esperienza, tiri e bonus di grado.',
                    'Raises experience, rolls and grade bonuses.',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: campoTesto(
                  label: t('Grado', 'Grade'),
                  controller: gradoController,
                  helper: t(
                    'Scala molti bonus: ogni grado pesa molto.',
                    'Scales many bonuses: each grade matters a lot.',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: campoTesto(
                  label: t('HP Attuali', 'Current HP'),
                  controller: currentHpController,
                  helper: t('La vita reale rimasta.', 'Real health remaining.'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: campoTesto(
                  label: 'HP Temp',
                  controller: hpTempController,
                  helper: t(
                    'Vita provvisoria prima degli HP reali.',
                    'Temporary health before real HP.',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: functionAnchor(
                  'sheet_shield',
                  campoTesto(
                    label: t('Scudo', 'Shield'),
                    controller: scudoController,
                    focusNode: scudoFocusNode,
                    helper: t(
                      'Assorbe danni prima degli HP.',
                      'Absorbs damage before HP.',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: campoTesto(
                  label: t('Scudo Critico', 'Critical Shield'),
                  controller: scudoCriticoController,
                  helper: t(
                    'Dimezza i danni finché resta attivo.',
                    'Halves damage while active.',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: functionAnchor(
                  'sheet_attack_bonus',
                  campoTesto(
                    label: t('Bonus Attacco / VC', 'Attack / VC Bonus'),
                    controller: attaccoRapidoController,
                    focusNode: attaccoRapidoFocusNode,
                    helper: t(
                      'Modifica rapida al tiro di attacco.',
                      'Quick modifier to the attack roll.',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: functionAnchor(
                  'sheet_defense_bonus',
                  campoTesto(
                    label: t('Bonus Difesa', 'Defense Bonus'),
                    controller: difesaRapidaController,
                    focusNode: difesaRapidaFocusNode,
                    helper: t(
                      'Modifica rapida alla Difesa totale.',
                      'Quick modifier to total Defense.',
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          campoTesto(
            label: t('Bonus CM', 'CM Bonus'),
            controller: cmRapidoController,
            helper: t(
              'Bonus testuale/numerico rapido al tiro CM.',
              'Quick textual/numeric bonus to CM rolls.',
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: campoTesto(
                  label: t('Resilienza', 'Resilience'),
                  controller: resilienzaController,
                  focusNode: resilienzaFocusNode,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: campoTesto(
                  label: t('Volontà', 'Will'),
                  controller: volontaController,
                  focusNode: volontaFocusNode,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: campoTesto(
                  label: 'Materia',
                  controller: materiaController,
                  focusNode: materiaFocusNode,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: campoTesto(
                  label: 'Oculum',
                  controller: oculumController,
                  focusNode: oculumFocusNode,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          smallInfoText(
            t(
              'Le stats attuali possono scendere quando le spendi. I totali visibili coincidono con le statistiche e includono i buff attivi.',
              'Current stats can drop when spent. Visible totals match the stats and include active buffs.',
            ),
            color: tertiaryColor,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: campoStatAttualeVisibile(
                  label: t('Resilienza attuale', 'Current Resilience'),
                  key: 'resilienza',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: campoStatAttualeVisibile(
                  label: t('Volontà attuale', 'Current Will'),
                  key: 'volonta',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: campoStatAttualeVisibile(
                  label: t('Materia attuale', 'Current Materia'),
                  key: 'materia',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: campoStatAttualeVisibile(
                  label: t('Oculum attuale', 'Current Oculum'),
                  key: 'oculum',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              quickCommandButton(
                label: '+1 CM (+2 Materia)',
                icon: Icons.add_circle_outline,
                color: Colors.lightBlueAccent,
                onPressed: () => modificaCmRapido(1),
              ),
              quickCommandButton(
                label: '-1 CM (-2 Materia)',
                icon: Icons.remove_circle_outline,
                color: Colors.lightBlueAccent,
                onPressed: () => modificaCmRapido(-1),
              ),
              quickCommandButton(
                label: '+1 VC (+3 Volonta)',
                icon: Icons.add_circle,
                color: Colors.redAccent,
                onPressed: () => modificaVcRapido(1),
              ),
              quickCommandButton(
                label: '-1 VC (-3 Volonta)',
                icon: Icons.remove_circle,
                color: Colors.redAccent,
                onPressed: () => modificaVcRapido(-1),
              ),
              quickCommandButton(
                label: '+1 Attacco',
                icon: Icons.flash_on,
                color: Colors.orangeAccent,
                onPressed: () => modificaAttaccoRapido(1),
              ),
              quickCommandButton(
                label: '-1 Attacco',
                icon: Icons.flash_off,
                color: Colors.orangeAccent,
                onPressed: () => modificaAttaccoRapido(-1),
              ),
              quickCommandButton(
                label: '+1 Difesa',
                icon: Icons.shield_outlined,
                color: Colors.lightGreenAccent,
                onPressed: () => modificaDifesaRapida(1),
              ),
              quickCommandButton(
                label: '-1 Difesa',
                icon: Icons.shield,
                color: Colors.lightGreenAccent,
                onPressed: () => modificaDifesaRapida(-1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color karmaUiColor() {
    final k = karmaTotale();
    if (k > 0) return Colors.greenAccent;
    if (k < 0) return Colors.redAccent;
    return tertiaryColor;
  }

  Widget karmaInfoBox() {
    return Expanded(
      child: gothicPanel(
        borderColor: karmaUiColor(),
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              'Karma',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: karmaUiColor(),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${karmaTotale()}',
              style: TextStyle(
                color: karmaUiColor(),
                fontSize: 25,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget compactNumericEditField({
    required String label,
    required TextEditingController controller,
    Color? color,
    String? helper,
    String? displayValue,
    VoidCallback? onSaved,
  }) {
    final fieldColor = color ?? primaryColor;

    Future<void> editValue() async {
      final temp = TextEditingController(text: controller.text);
      try {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              backgroundColor: const Color(0xFF10121A),
              title: Text(
                cleanUiText(label),
                style: TextStyle(
                  color: fieldColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
              content: TextField(
                controller: temp,
                autofocus: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                cursorColor: fieldColor,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
                decoration: fieldDecoration(t('Valore', 'Value')),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(t('Annulla', 'Cancel')),
                ),
                ElevatedButton(
                  onPressed: () {
                    controller.text = max(
                      0,
                      readIntValue(temp.text),
                    ).toString();
                    onSaved?.call();
                    if (mounted) setState(() {});
                    programmaSalvataggio();
                    Navigator.pop(dialogContext);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: fieldColor,
                    foregroundColor: fieldColor.computeLuminance() > 0.45
                        ? Colors.black
                        : Colors.white,
                  ),
                  child: Text(t('Salva', 'Save')),
                ),
              ],
            );
          },
        );
      } finally {
        temp.dispose();
      }
    }

    final fieldTile = quickContextMenuAnchor(
      label: label,
      onEdit: editValue,
      child: Container(
        constraints: const BoxConstraints(minHeight: 54),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF07080D),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: fieldColor.withValues(alpha: 0.66)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              cleanUiText(label),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: fieldColor,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              displayValue ?? '${max(0, readIntValue(controller.text))}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
            if (helper != null && helper.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                cleanUiText(helper),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    return Tooltip(
      message: t('Tocca per modificare', 'Tap to edit'),
      child: InkWell(
        onTap: editValue,
        borderRadius: BorderRadius.circular(10),
        child: fieldTile,
      ),
    );
  }

  Widget compactScudoOculumEditField() {
    return compactNumericEditField(
      label: t('Scudo Oculum', 'Oculum Shield'),
      controller: scudoOculumController,
      color: eyePupilGlowColor,
      displayValue: '${scudoOculum()}/${scudoOculumMax()}',
      helper: t('Prima degli altri scudi.', 'Before other shields.'),
      onSaved: () {
        final current = max(0, readIntValue(scudoOculumController.text));
        final maximum = scudoOculumMax();
        if (current > maximum) {
          final bonus = scudoOculumBonusMassimo();
          scudoOculumMaxController.text = max(0, current - bonus).toString();
        }
      },
    );
  }

  Widget compactScudoOculumMaxEditField() {
    return compactNumericEditField(
      label: t('Max Scudo Oculum', 'Max Oculum Shield'),
      controller: scudoOculumMaxController,
      color: eyePupilGlowColor,
      displayValue: scudoOculumMax().toString(),
      helper: scudoOculumBonusMassimo() == 0
          ? t('Massimo manuale.', 'Manual maximum.')
          : '${t('Manuale + buff', 'Manual + buff')}: ${scudoOculumMassimoManuale()} ${scudoOculumBonusMassimo() >= 0 ? '+' : ''}${scudoOculumBonusMassimo()}',
      onSaved: () {
        final maximum = scudoOculumMax();
        final current = max(0, readIntValue(scudoOculumController.text));
        if (maximum <= 0) {
          scudoOculumController.text = '0';
        } else if (current > maximum) {
          scudoOculumController.text = maximum.toString();
        }
      },
    );
  }

  Widget hpModePanel() {
    return dropdownSection(
      title: t('Vita: barra o modifica', 'HP: bar or edit'),
      subtitle: t(
        'Controllo rapido di HP, HP temp e scudi.',
        'Quick control for HP, temp HP and shields.',
      ),
      icon: Icons.favorite,
      borderColor: primaryColor,
      sectionId: 'sheet_hp',
      child: Column(
        children: [
          SwitchListTile(
            value: usaBarraVita,
            activeThumbColor: tertiaryColor,
            title: Text(t('Mostra barra vita', 'Show HP bar')),
            subtitle: Text(
              usaBarraVita
                  ? t(
                      'Vedi la vita come barra grafica.',
                      'View HP as a visual bar.',
                    )
                  : t(
                      'Modifica la vita con campi numerici.',
                      'Edit HP with numeric fields.',
                    ),
            ),
            onChanged: (value) {
              setState(() => usaBarraVita = value);
              programmaSalvataggio();
            },
          ),
          if (usaBarraVita)
            themeUsesStackedVitalsHud() ? stackedVitalsHudPanel() : lifeBar(),
          if (usaBarraVita && !themeUsesStackedVitalsHud()) oculumShieldPanel(),
          if (!usaBarraVita) ...[
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 520;
                final singleColumn = constraints.maxWidth < 360;
                final fields = [
                  compactNumericEditField(
                    label: t('HP Attuali', 'Current HP'),
                    controller: currentHpController,
                    color: Colors.redAccent,
                    helper: t('Vita reale rimasta.', 'Real HP left.'),
                  ),
                  compactNumericEditField(
                    label: 'HP Temp',
                    controller: hpTempController,
                    color: const Color(0xFF7EE7C8),
                    helper: t('Prima degli HP.', 'Before real HP.'),
                  ),
                  compactNumericEditField(
                    label: t('Scudo', 'Shield'),
                    controller: scudoController,
                    color: const Color(0xFF44A7FF),
                    helper: t('Prima degli HP Temp.', 'Before temp HP.'),
                  ),
                  if (shouldShowScudoOculum()) ...[
                    compactScudoOculumEditField(),
                    compactScudoOculumMaxEditField(),
                  ],
                ];

                if (singleColumn) {
                  return Column(
                    children: [
                      for (var i = 0; i < fields.length; i++) ...[
                        fields[i],
                        if (i < fields.length - 1) const SizedBox(height: 8),
                      ],
                    ],
                  );
                }

                if (compact) {
                  return Column(
                    children: [
                      for (var i = 0; i < fields.length; i += 2) ...[
                        Row(
                          children: [
                            Expanded(child: fields[i]),
                            if (i + 1 < fields.length) ...[
                              const SizedBox(width: 8),
                              Expanded(child: fields[i + 1]),
                            ] else
                              const Spacer(),
                          ],
                        ),
                        if (i + 2 < fields.length) const SizedBox(height: 8),
                      ],
                    ],
                  );
                }

                final columns = fields.length.clamp(3, 5).toInt();

                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final field in fields)
                      SizedBox(
                        width:
                            (constraints.maxWidth - (columns - 1) * 8) /
                            columns,
                        child: field,
                      ),
                  ],
                );
              },
            ),
          ],
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton.icon(
              onPressed: refullVita,
              icon: const Icon(Icons.favorite),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.shade700,
                foregroundColor: Colors.white,
              ),
              label: Text(t('Refull Vita', 'Refill HP')),
            ),
          ),
        ],
      ),
    );
  }

  Widget damageHealPanel() {
    if (!mostraDannoCuraScheda) return const SizedBox.shrink();

    return dropdownSection(
      title: t('Danno / Cura', 'Damage / Healing'),
      subtitle: t(
        'Inserisci un numero, scegli il modificatore, poi applica. Il danno totale usa il colore dell’elemento dominante.',
        'Enter a number, choose the modifier, then apply. Total damage uses the dominant element color.',
      ),
      icon: Icons.healing,
      borderColor: tertiaryColor,
      sectionId: 'sheet_damage_heal',
      initiallyExpanded: true,
      child: Column(
        children: [
          functionAnchor(
            'sheet_damage_heal_input',
            campoTesto(
              label: t('Danno subito / Cura', 'Damage taken / Healing'),
              controller: dannoSubitoController,
              focusNode: dannoCuraFocusNode,
              helper: t(
                'Valore positivo: quanto togli o recuperi.',
                'Positive value: how much you remove or recover.',
              ),
            ),
          ),
          const SizedBox(height: 12),
          gothicPanel(
            borderColor: elementColor(elementoDannoDominante()),
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${t('Tipo danno', 'Damage type')}: ${elementDisplayName(elementoDannoDominante())}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: elementColor(elementoDannoDominante()),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (elementiDannoTesto().isNotEmpty &&
                    elementiDannoTesto() !=
                        elementDisplayName(elementoDannoDominante()))
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${t('Elementi', 'Elements')}: ${elementiDannoTesto()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: elementColor(
                          elementoDannoDominante(),
                        ).withValues(alpha: 0.85),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          damageModifierDropdown(),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              Widget actionButton({
                required String label,
                required Color backgroundColor,
                required Color foregroundColor,
                required VoidCallback onPressed,
              }) {
                return SizedBox(
                  width: constraints.maxWidth < 430
                      ? (constraints.maxWidth - 8) / 2
                      : null,
                  child: ElevatedButton(
                    onPressed: onPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: backgroundColor,
                      foregroundColor: foregroundColor,
                      minimumSize: const Size.fromHeight(42),
                    ),
                    child: FittedBox(fit: BoxFit.scaleDown, child: Text(label)),
                  ),
                );
              }

              final buttons = [
                functionAnchor(
                  'sheet_damage',
                  actionButton(
                    label: t('Danno', 'Damage'),
                    backgroundColor: Colors.redAccent.shade700,
                    foregroundColor: Colors.white,
                    onPressed: () => applicaDannoSubito(),
                  ),
                ),
                actionButton(
                  label: t('Critico', 'Critical'),
                  backgroundColor: tertiaryColor,
                  foregroundColor: tertiaryColor.computeLuminance() > 0.45
                      ? Colors.black
                      : Colors.white,
                  onPressed: () => applicaDannoSubito(critico: true),
                ),
                functionAnchor(
                  'sheet_heal',
                  actionButton(
                    label: t('Cura', 'Heal'),
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    onPressed: curaHp,
                  ),
                ),
                actionButton(
                  label: t('Refull', 'Refill'),
                  backgroundColor: primaryColor,
                  foregroundColor: primaryColor.computeLuminance() > 0.45
                      ? Colors.black
                      : Colors.white,
                  onPressed: refullVita,
                ),
              ];

              if (constraints.maxWidth < 430) {
                return Wrap(spacing: 8, runSpacing: 8, children: buttons);
              }

              return Row(
                children: [
                  for (var i = 0; i < buttons.length; i++) ...[
                    Expanded(child: buttons[i]),
                    if (i < buttons.length - 1) const SizedBox(width: 8),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget partyPanel() {
    if (!mostraPartyScheda) return const SizedBox.shrink();

    return dropdownSection(
      title: t('Party', 'Party'),
      subtitle: t(
        'Alleati, NPC e persone importanti sempre a portata.',
        'Allies, NPCs and important people close at hand.',
      ),
      icon: Icons.groups,
      borderColor: const Color(0xFF7EE7C8),
      sectionId: 'sheet_party',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          smallInfoText(
            t(
              'Segna qui il party, gli alleati, gli NPC importanti o chi sta viaggiando con te.',
              'Track your party, allies, important NPCs or who is traveling with you here.',
            ),
          ),
          const SizedBox(height: 12),
          gothicPanel(
            borderColor: tertiaryColor,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t(
                    'Party Master dalle schede salvate',
                    'Master party from saved sheets',
                  ),
                  style: TextStyle(
                    color: tertiaryColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                smallInfoText(
                  t(
                    'Questi membri sono schede vere: puoi aprirle, modificarle e tirare rapidamente dal Master.',
                    'These members are real sheets: you can open them, edit them and roll quickly from Master.',
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 12,
                  children: [
                    for (final index in masterPartyIndexes())
                      masterPartyHexBadge(index),
                  ],
                ),
                if (masterPartyIndexes().isEmpty)
                  smallInfoText(
                    t(
                      'Nessuna scheda collegata al party Master.',
                      'No sheet linked to the Master party.',
                    ),
                  ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () => cambiaSchedaMasterParty(
                    schedaCorrente,
                    !sheetInMasterPartyAt(schedaCorrente),
                  ),
                  icon: Icon(
                    sheetInMasterPartyAt(schedaCorrente)
                        ? Icons.group_remove
                        : Icons.group_add,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: sheetInMasterPartyAt(schedaCorrente)
                        ? Colors.redAccent.shade700
                        : tertiaryColor,
                    foregroundColor: sheetInMasterPartyAt(schedaCorrente)
                        ? Colors.white
                        : tertiaryColor.computeLuminance() > 0.45
                        ? Colors.black
                        : Colors.white,
                  ),
                  label: Text(
                    sheetInMasterPartyAt(schedaCorrente)
                        ? t(
                            'Togli questa scheda dal party',
                            'Remove this sheet from party',
                          )
                        : t(
                            'Aggiungi questa scheda al party',
                            'Add this sheet to party',
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          campoTesto(
            label: t('Nome membro', 'Member name'),
            controller: partyNomeController,
            numero: false,
          ),
          const SizedBox(height: 10),
          campoTesto(
            label: t('Ruolo', 'Role'),
            controller: partyRuoloController,
            numero: false,
          ),
          const SizedBox(height: 10),
          campoTesto(
            label: t('Note', 'Notes'),
            controller: partyNoteController,
            numero: false,
            maxLines: 2,
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: aggiungiMembroParty,
            icon: const Icon(Icons.person_add),
            style: ElevatedButton.styleFrom(
              backgroundColor: tertiaryColor,
              foregroundColor: tertiaryColor.computeLuminance() > 0.45
                  ? Colors.black
                  : Colors.white,
              minimumSize: const Size.fromHeight(44),
            ),
            label: Text(t('Aggiungi al party', 'Add to party')),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: tiraAiutaCompagno,
                icon: const Icon(Icons.volunteer_activism),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7EE7C8),
                  foregroundColor: Colors.black,
                ),
                label: Text(t('Aiuta compagno', 'Help ally')),
              ),
              Chip(
                avatar: const Icon(Icons.casino, size: 16),
                label: Text('1d10 + Lv + Grado x6'),
                backgroundColor: secondaryColor.withValues(alpha: 0.62),
                side: BorderSide(color: tertiaryColor.withValues(alpha: 0.55)),
                labelStyle: TextStyle(
                  color: tertiaryColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (partyMembri.isEmpty)
            smallInfoText(t('Nessun membro segnato.', 'No member tracked.'))
          else
            for (int i = 0; i < partyMembri.length; i++)
              Card(
                color: const Color(0xFF10121A),
                child: ListTile(
                  title: Text(
                    '${partyMembri[i]['nome'] ?? '???'}',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '${partyMembri[i]['ruolo'] ?? ''}\n${partyMembri[i]['note'] ?? ''}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () {
                      setState(() => partyMembri.removeAt(i));
                      programmaSalvataggio();
                    },
                  ),
                ),
              ),
        ],
      ),
    );
  }

  void aggiungiMembroParty() {
    final nome = partyNomeController.text.trim();
    if (nome.isEmpty) return;

    setState(() {
      partyMembri.add({
        'nome': nome,
        'ruolo': partyRuoloController.text.trim(),
        'note': partyNoteController.text.trim(),
      });
      partyNomeController.clear();
      partyRuoloController.text = 'Alleato';
      partyNoteController.clear();
      risultato = t('Membro party aggiunto.', 'Party member added.');
      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  Widget manualQuickToolsPanel() {
    if (!mostraStrumentiManualeRapidi) return const SizedBox.shrink();

    return dropdownSection(
      title: t('Strumenti rapidi manuale', 'Manual quick tools'),
      subtitle: t(
        'Apri subito le regole più usate.',
        'Jump straight to the most used rules.',
      ),
      icon: Icons.menu_book,
      borderColor: primaryColor,
      initiallyExpanded: false,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (int i = 0; i < min(activeManualSections.length, 8); i++)
            ElevatedButton(
              onPressed: () {
                vaiAllaFunzione(
                  page: 8,
                  anchorId: 'rules_open_section',
                  manualIndex: i,
                  logTitle: manualTitle(activeManualSections[i]),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: secondaryColor,
                foregroundColor: primaryColor,
                side: BorderSide(color: tertiaryColor.withValues(alpha: 0.45)),
              ),
              child: Text(
                '${i + 1}. ${manualTitle(activeManualSections[i]).split('.').last.trim()}',
              ),
            ),
        ],
      ),
    );
  }

  Widget inventoryQuickDropdownPanel() {
    if (!mostraBorsaCompatta) return const SizedBox.shrink();

    final principali = inventario.take(8).toList();

    return dropdownSection(
      title: t('Borsa rapida / Oggetti principali', 'Quick bag / Main items'),
      subtitle: t(
        'I primi oggetti della borsa con + e - rapidi.',
        'First bag items with quick + and - controls.',
      ),
      icon: Icons.backpack,
      borderColor: tertiaryColor,
      initiallyExpanded: true,
      child: Column(
        children: [
          if (principali.isEmpty)
            smallInfoText(t('Nessun oggetto in borsa.', 'No item in bag.'))
          else
            for (final item in principali)
              Card(
                color: const Color(0xFF10121A),
                child: ListTile(
                  title: Text(
                    item.nome,
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    [
                      'x${item.quantita}',
                      '${item.peso.toStringAsFixed(1)} kg',
                      if (item.arma) 'DMG +${item.bonusDanno}',
                      if (item.protegge) 'DIF +${item.bonusDifesa}',
                      if (item.protegge) 'SCU +${item.bonusScudo}',
                      if (item.note.trim().isNotEmpty) item.note,
                    ].join(' • '),
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: SizedBox(
                    width: 96,
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              item.quantita = max(0, item.quantita - 1);
                            });
                            programmaSalvataggio();
                          },
                          icon: const Icon(
                            Icons.remove_circle,
                            color: Colors.redAccent,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              item.quantita++;
                            });
                            programmaSalvataggio();
                          },
                          icon: const Icon(
                            Icons.add_circle,
                            color: Colors.greenAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  bool testoModificatoVisibile(String value) {
    final clean = cleanUiText(value).trim();
    if (clean.isEmpty) return false;
    final lower = clean.toLowerCase();
    return lower != '???' && lower != 'nessuno' && lower != 'none';
  }

  List<Widget> desktopArtSkillTextCards() {
    final cards = <Widget>[];
    final baseArts = artiBase();

    void addCard(
      String title,
      String body,
      Color color, {
      required VoidCallback onTap,
    }) {
      if (!testoModificatoVisibile(body)) return;
      cards.add(
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF10121A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.45)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          cleanUiText(title),
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Icon(Icons.open_in_new, color: color, size: 15),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cleanUiText(body),
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, height: 1.25),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    void openArt(int index) {
      vaiAllaFunzione(
        page: 3,
        anchorId: 'art_$index',
        logTitle: '${t('Art', 'Art')} ${index + 1}',
      );
    }

    void openArtOpen(int index) {
      vaiAllaFunzione(
        page: 3,
        anchorId: 'art_${index}_open',
        logTitle: '${t('Open Art', 'Art Open')} ${index + 1}',
      );
    }

    void openArtSkill(int artIndex, int skillIndex) {
      vaiAllaFunzione(
        page: 3,
        anchorId: 'art_${artIndex}_skill_$skillIndex',
        logTitle:
            '${t('Art', 'Art')} ${artIndex + 1} / ${t('Skill', 'Skill')} ${skillIndex + 1}',
      );
    }

    void openFreeSkill(int index) {
      vaiAllaFunzione(
        page: 4,
        anchorId: 'free_skill_$index',
        logTitle: '${t('Skill', 'Skill')} ${index + 1}',
      );
    }

    for (int i = 0; i < arti.length; i++) {
      final art = arti[i];
      final base = i < baseArts.length ? baseArts[i] : null;
      final color = elementColor(art.tipo);

      if (base == null || art.descrizione.trim() != base.descrizione.trim()) {
        addCard(
          'Art: ${art.nome}',
          art.descrizione,
          color,
          onTap: () => openArt(i),
        );
      }

      for (final field in [
        (
          label: 'Open',
          value: art.openDescription,
          base: base?.openDescription ?? '',
        ),
        (label: 'Open Buff', value: art.openBuff, base: base?.openBuff ?? ''),
        (
          label: 'Open Skill',
          value: art.openSkill,
          base: base?.openSkill ?? '',
        ),
      ]) {
        if (field.value.trim() != field.base.trim()) {
          addCard(
            '${field.label}: ${art.nome}',
            field.value,
            color,
            onTap: () => openArtOpen(i),
          );
        }
      }

      for (int j = 0; j < art.skills.length; j++) {
        final skill = art.skills[j];
        final baseSkill = base != null && j < base.skills.length
            ? base.skills[j]
            : null;
        for (final field in [
          (label: 'I', value: skill.evo1, base: baseSkill?.evo1 ?? ''),
          (label: 'II', value: skill.evo2, base: baseSkill?.evo2 ?? ''),
          (label: 'III', value: skill.evo3, base: baseSkill?.evo3 ?? ''),
        ]) {
          if (field.value.trim() != field.base.trim()) {
            addCard(
              'Art ${art.nome} / ${skill.nome} ${field.label}',
              field.value,
              color,
              onTap: () => openArtSkill(i, j),
            );
          }
        }
      }
    }

    for (int i = 0; i < skills.length; i++) {
      final skill = skills[i];
      final parts = [
        if (testoModificatoVisibile(skill.tipo)) skill.tipo,
        if (testoModificatoVisibile(skill.costo)) 'Costo: ${skill.costo}',
        if (testoModificatoVisibile(skill.cooldown))
          'Cooldown: ${skill.cooldown}',
        if (testoModificatoVisibile(skill.descrizione)) skill.descrizione,
      ].join('\n');
      addCard(
        'Skill: ${skill.nome}',
        parts,
        primaryColor,
        onTap: () => openFreeSkill(i),
      );
    }

    return cards;
  }

  Widget desktopQuickBagSidePanel() {
    final principali = inventario.take(6).toList();
    return gothicPanel(
      borderColor: tertiaryColor,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('Borsa rapida laterale', 'Side quick bag'),
            style: TextStyle(
              color: tertiaryColor,
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 8),
          if (principali.isEmpty)
            smallInfoText(t('Nessun oggetto in borsa.', 'No item in bag.'))
          else
            for (final item in principali)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  cleanUiText(item.nome),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  [
                    'x${item.quantita}',
                    '${item.peso.toStringAsFixed(1)} kg',
                    if (item.arma) 'DMG +${item.bonusDanno}',
                    if (item.protegge) 'DIF +${item.bonusDifesa}',
                    if (item.protegge) 'SCU +${item.bonusScudo}',
                  ].join(' • '),
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: Wrap(
                  spacing: 2,
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        setState(() {
                          item.quantita = max(0, item.quantita - 1);
                        });
                        programmaSalvataggio();
                      },
                      icon: const Icon(
                        Icons.remove_circle,
                        color: Colors.redAccent,
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        setState(() => item.quantita++);
                        programmaSalvataggio();
                      },
                      icon: const Icon(
                        Icons.add_circle,
                        color: Colors.greenAccent,
                      ),
                    ),
                  ],
                ),
              ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => vaiAllaFunzione(
              page: 6,
              anchorId: 'inventory_root',
              logTitle: t('Borsa completa', 'Full bag'),
            ),
            icon: const Icon(Icons.open_in_full),
            style: ElevatedButton.styleFrom(
              backgroundColor: secondaryColor,
              foregroundColor: primaryColor,
              minimumSize: const Size.fromHeight(42),
            ),
            label: Text(t('Apri borsa completa', 'Open full bag')),
          ),
        ],
      ),
    );
  }

  Widget desktopArtSkillTextSidePanel() {
    final cards = desktopArtSkillTextCards();
    return gothicPanel(
      borderColor: primaryColor,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('Art e Skill modificate', 'Edited Arts and Skills'),
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 8),
          smallInfoText(
            t(
              'Mostra solo testi modificati rispetto alla base e Skill con testo compilato.',
              'Shows only text changed from the base and Skills with filled text.',
            ),
          ),
          const SizedBox(height: 10),
          if (cards.isEmpty)
            smallInfoText(
              t(
                'Nessun testo Art/Skill modificato da mostrare.',
                'No edited Art/Skill text to show.',
              ),
            )
          else
            ...cards.take(8),
        ],
      ),
    );
  }

  Widget desktopSheetSidePanels() {
    if (!modalitaDesktop) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) return const SizedBox.shrink();
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: desktopQuickBagSidePanel()),
            const SizedBox(width: 12),
            Expanded(child: desktopArtSkillTextSidePanel()),
          ],
        );
      },
    );
  }

  Widget sheetIdentityEditorPanel({bool dense = false}) {
    final spacing = dense ? 8.0 : 12.0;
    return gothicPanel(
      borderColor: tertiaryColor,
      padding: EdgeInsets.all(dense ? 10 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.badge, color: tertiaryColor, size: dense ? 18 : 22),
              SizedBox(width: dense ? 7 : 9),
              Expanded(
                child: Text(
                  t('Identità scheda', 'Sheet identity'),
                  style: TextStyle(
                    color: tertiaryColor,
                    fontWeight: FontWeight.w900,
                    fontSize: dense ? 15 : 18,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: dense ? 8 : 10,
                  vertical: dense ? 4 : 5,
                ),
                decoration: BoxDecoration(
                  color: secondaryColor,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.42),
                  ),
                ),
                child: Text(
                  '${t('Lv', 'Lv')} ${livelloController.text} • ${t('Gr', 'Gr')} ${gradoController.text}',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: dense ? 11 : 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: spacing),
          tipoSchedaDropdown(
            value: tipoSchedaController.text,
            onChanged: cambiaTipoScheda,
          ),
          SizedBox(height: spacing),
          campoTesto(
            label: t('Nome Scheda', 'Sheet Name'),
            controller: nomeController,
            numero: false,
            helper: dense
                ? null
                : t(
                    'Nome del personaggio, mostro o NPC.',
                    'Name of the character, monster or NPC.',
                  ),
          ),
          SizedBox(height: spacing),
          Row(
            children: [
              Expanded(
                child: campoTesto(
                  label: t('Livello', 'Level'),
                  controller: livelloController,
                ),
              ),
              SizedBox(width: spacing),
              Expanded(
                child: campoTesto(
                  label: t('Grado', 'Grade'),
                  controller: gradoController,
                ),
              ),
            ],
          ),
          SizedBox(height: dense ? 2 : 6),
          SwitchListTile(
            dense: dense,
            contentPadding: EdgeInsets.zero,
            value: rebirthato,
            activeThumbColor: tertiaryColor,
            title: const Text('Rebirth'),
            subtitle: dense
                ? null
                : Text(
                    t(
                      'Attivalo se la scheda è rebirthata.',
                      'Turn on if this sheet is rebirthed.',
                    ),
                  ),
            onChanged: toggleRebirth,
          ),
        ],
      ),
    );
  }

  Widget combatOverviewPanel({bool dense = false}) {
    final domDif = elementoDifesaDominante();
    final domDan = elementoDannoDominante();
    final damageColor = domDan == 'sconosciuto'
        ? tertiaryColor
        : elementColor(domDan);
    final defenseColor = domDif.isEmpty
        ? Colors.lightGreenAccent
        : elementColor(domDif);

    return gothicPanel(
      borderColor: tertiaryColor,
      padding: EdgeInsets.all(dense ? 10 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sports_martial_arts, color: tertiaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t('Combattimento', 'Combat'),
                  style: TextStyle(
                    color: tertiaryColor,
                    fontWeight: FontWeight.w900,
                    fontSize: dense ? 16 : 19,
                  ),
                ),
              ),
              Text(
                t('tocca per modificare', 'tap to edit'),
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: dense ? 10 : 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: dense ? 8 : 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final spacing = dense ? 6.0 : 8.0;
              final columns = constraints.maxWidth < 360
                  ? 2
                  : constraints.maxWidth < 640
                  ? 3
                  : 4;
              final tileWidth =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;
              final tiles = <Widget>[
                quickStatTile(
                  label: 'VC',
                  value: '+${vc()}',
                  icon: Icons.flash_on,
                  color: tertiaryColor,
                  onTap: () => vaiAllaFunzione(
                    page: 0,
                    anchorId: 'sheet_editable_values_volonta',
                    logTitle: 'VC',
                  ),
                  onRoll: () => tiraValoreSpeciale('VC', vc()),
                  onDecrease: () => modificaAttaccoRapido(-1),
                  onIncrease: () => modificaAttaccoRapido(1),
                ),
                quickStatTile(
                  label: 'CM',
                  value: '${cm()}',
                  icon: Icons.security,
                  color: primaryColor,
                  onTap: () => vaiAllaFunzione(
                    page: 0,
                    anchorId: 'sheet_editable_values_materia',
                    logTitle: 'CM',
                  ),
                  onRoll: () => tiraValoreSpeciale('CM', cm()),
                  onDecrease: () => modificaBonusCmRapido(-1),
                  onIncrease: () => modificaBonusCmRapido(1),
                ),
                quickStatTile(
                  label: t('Iniziativa', 'Initiative'),
                  value: '+${iniziativa()}',
                  icon: Icons.directions_run,
                  color: const Color(0xFF7EE7C8),
                  onTap: () => tiraValoreSpeciale(
                    t('Iniziativa', 'Initiative'),
                    iniziativa(),
                  ),
                  onRoll: () => tiraValoreSpeciale(
                    t('Iniziativa', 'Initiative'),
                    iniziativa(),
                  ),
                  onDecrease: () => modificaBuffMalusRapido(
                    rawKey: 'Iniziativa',
                    label: t('Iniziativa', 'Initiative'),
                    delta: -1,
                  ),
                  onIncrease: () => modificaBuffMalusRapido(
                    rawKey: 'Iniziativa',
                    label: t('Iniziativa', 'Initiative'),
                    delta: 1,
                  ),
                ),
                quickStatTile(
                  label: t('Movimento', 'Movement'),
                  value: '${movimento()}m',
                  icon: Icons.directions_walk,
                  color: Colors.cyanAccent,
                  onTap: () => vaiAllaFunzione(
                    page: 0,
                    anchorId: 'sheet_editable_values_materia',
                    logTitle: t('Movimento', 'Movement'),
                  ),
                ),
                quickStatTile(
                  label: t('Danno', 'Damage'),
                  value: '${dannoTotale()}',
                  icon: Icons.close,
                  color: damageColor,
                  onTap: () => apriDannoCuraDalCentroPartita(target: 'damage'),
                  onRoll: () =>
                      tiraValoreSpeciale(t('Danno', 'Damage'), dannoTotale()),
                  onDecrease: () => modificaBuffMalusRapido(
                    rawKey: 'Danni',
                    label: t('Danno', 'Damage'),
                    delta: -1,
                  ),
                  onIncrease: () => modificaBuffMalusRapido(
                    rawKey: 'Danni',
                    label: t('Danno', 'Damage'),
                    delta: 1,
                  ),
                ),
                quickStatTile(
                  label: t('Difesa', 'Defense'),
                  value: '${difesa()}',
                  icon: Icons.shield_outlined,
                  color: defenseColor,
                  onTap: () => vaiAllaFunzione(
                    page: 0,
                    anchorId: 'sheet_defense_bonus',
                    logTitle: t('Difesa', 'Defense'),
                  ),
                  onRoll: () =>
                      tiraValoreSpeciale(t('Difesa', 'Defense'), difesa()),
                  onDecrease: () => modificaDifesaRapida(-1),
                  onIncrease: () => modificaDifesaRapida(1),
                ),
                if (!dense || !modalitaVeloce)
                  quickStatTile(
                    label: 'Lv/Grado',
                    value: '+${bonusLivelloGrado()}',
                    icon: Icons.military_tech,
                    color: Colors.amberAccent,
                  ),
              ];
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final tile in tiles)
                    SizedBox(width: tileWidth, child: tile),
                ],
              );
            },
          ),
          SizedBox(height: dense ? 8 : 12),
          Wrap(
            spacing: dense ? 6 : 8,
            runSpacing: dense ? 6 : 8,
            children: [
              quickCommandButton(
                label: dense ? 'VC' : t('Tira VC', 'Roll VC'),
                icon: Icons.casino,
                color: tertiaryColor,
                onPressed: () => tiraValoreSpeciale('VC', vc()),
              ),
              quickCommandButton(
                label: dense ? 'CM' : t('Tira CM', 'Roll CM'),
                icon: Icons.security,
                color: primaryColor,
                onPressed: () => tiraValoreSpeciale('CM', cm()),
              ),
              quickCommandButton(
                label: dense ? '+CM base' : '+1 CM base',
                icon: Icons.add_circle_outline,
                color: primaryColor,
                onPressed: () => modificaBonusCmRapido(1),
              ),
              quickCommandButton(
                label: dense ? '+CM' : '+1 CM (+2 Materia)',
                icon: Icons.add_circle_outline,
                color: Colors.lightBlueAccent,
                onPressed: () => modificaCmRapido(1),
              ),
              quickCommandButton(
                label: t('Danno/Cura', 'Damage/Heal'),
                icon: Icons.healing,
                color: Colors.redAccent,
                onPressed: () => apriDannoCuraDalCentroPartita(),
              ),
              quickCommandButton(
                label: t('Modifica', 'Edit'),
                icon: Icons.tune,
                color: const Color(0xFF7EE7C8),
                onPressed: mostraModificaRapida,
              ),
            ],
          ),
          if (!dense || !modalitaVeloce) ...[
            const SizedBox(height: 8),
            smallInfoText(
              t(
                'Danno: Volontà totale + arma migliore + Livello + Grado x6 + bonus testuali.',
                'Damage: total Will + best weapon + Level + Grade x6 + text bonuses.',
              ),
              color: Colors.grey.shade400,
            ),
          ],
        ],
      ),
    );
  }

  Widget statMiniTile({
    required String label,
    required int value,
    required int buff,
    required int temp,
    required VoidCallback onRoll,
    required VoidCallback onEdit,
    required Color color,
    int? massimo,
    int bonusSkillForma = 0,
    VoidCallback? onDecrease,
    VoidCallback? onIncrease,
  }) {
    final rollBonus =
        value ~/ 2 +
        bonusLivelloGrado() +
        malusFaticaTiri() +
        statRollQuickBonus(label);
    final hasExtra = buff != 0 || temp != 0 || bonusSkillForma != 0;
    final compact = lightweightUi;
    final diceButtonSize = compact ? 34.0 : 40.0;
    final diceIconSize = compact ? 18.0 : 21.0;
    final spec = currentThemeDecorationSpec();
    final guiStyle = currentThemeVisualIdentity().mainSheetGuiStyle.id;
    final clippedTile = <String>{
      'phobia',
      'postea',
      'kingi',
      'medieval',
      'rank_hud',
      'sigil',
      'archive',
      'relic',
    }.contains(guiStyle);
    final tileBackground = switch (guiStyle) {
      'phobia' => Color.lerp(
        spec.backgroundBottom,
        const Color(0xFF06111D),
        0.52,
      )!,
      'postea' || 'kingi' || 'medieval' => Color.lerp(
        spec.backgroundBottom,
        const Color(0xFF102839),
        0.48,
      )!,
      'botanical' => Color.lerp(
        spec.backgroundBottom,
        const Color(0xFF0D1C13),
        0.42,
      )!,
      'lunar' || 'soft_orbital' => Color.lerp(
        spec.backgroundBottom,
        const Color(0xFF11142A),
        0.42,
      )!,
      'archive' || 'relic' => Color.lerp(
        spec.backgroundBottom,
        const Color(0xFF18110A),
        0.38,
      )!,
      'rank_hud' || 'sigil' => Color.lerp(
        spec.backgroundBottom,
        const Color(0xFF110927),
        0.46,
      )!,
      _ => const Color(0xFF080A12),
    };
    final accent = readableOnTheme(
      color,
      background: tileBackground,
      minRatio: 3.5,
    );
    final labelColor = readableOnTheme(
      Color.lerp(
        Colors.white,
        spec.accent,
        guiStyle == 'phobia' ? 0.26 : 0.16,
      )!,
      background: tileBackground,
      minRatio: 4.0,
    );
    final tileRadius = switch (guiStyle) {
      'phobia' => compact ? 4.0 : 6.0,
      'postea' || 'kingi' || 'medieval' => compact ? 5.0 : 7.0,
      'botanical' => compact ? 13.0 : 16.0,
      'lunar' || 'soft_orbital' => compact ? 16.0 : 18.0,
      _ => compact ? 9.0 : 12.0,
    };
    final Gradient tileGradient = switch (guiStyle) {
      'phobia' => LinearGradient(
        colors: [
          Colors.black.withValues(alpha: 0.98),
          Color.lerp(tileBackground, spec.primary, 0.18)!,
          Color.lerp(tileBackground, spec.accent, 0.10)!,
        ],
        stops: const [0.0, 0.48, 1.0],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      'postea' || 'kingi' || 'medieval' => LinearGradient(
        colors: [
          Color.lerp(tileBackground, spec.primary, 0.16)!,
          tileBackground,
          Color.lerp(tileBackground, spec.accent, 0.12)!,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      'botanical' => RadialGradient(
        colors: [
          Color.lerp(tileBackground, spec.secondary, 0.16)!,
          tileBackground,
        ],
        center: Alignment.topRight,
        radius: 1.4,
      ),
      'lunar' || 'soft_orbital' => RadialGradient(
        colors: [
          Color.lerp(tileBackground, spec.accent, 0.14)!,
          tileBackground,
        ],
        center: Alignment.topLeft,
        radius: 1.2,
      ),
      'archive' || 'relic' => LinearGradient(
        colors: [
          Color.lerp(tileBackground, spec.secondary, 0.12)!,
          tileBackground,
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      _ => LinearGradient(colors: [tileBackground, tileBackground]),
    };

    Widget rollBadge({bool tight = false}) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: tight ? 6 : 7,
          vertical: compact ? 3 : 4,
        ),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(guiStyle == 'phobia' ? 5 : 999),
          border:
              guiStyle == 'postea' ||
                  guiStyle == 'kingi' ||
                  guiStyle == 'medieval'
              ? Border.all(color: accent.withValues(alpha: 0.30))
              : null,
        ),
        child: Text(
          '1d20 +$rollBonus',
          maxLines: 1,
          softWrap: false,
          style: TextStyle(
            color: accent,
            fontSize: compact ? 9.5 : 10.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
    }

    Widget valueControlText() {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onRoll,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: onDecrease != null || onIncrease != null
              ? Alignment.center
              : Alignment.centerLeft,
          child: Text(
            massimo == null ? '$value' : '$value/$massimo',
            textAlign: onDecrease != null || onIncrease != null
                ? TextAlign.center
                : TextAlign.start,
            maxLines: 1,
            softWrap: false,
            style: TextStyle(
              color: readableOnTheme(Colors.white, background: tileBackground),
              fontSize: compact ? 19 : 22,
              fontWeight: FontWeight.w900,
              height: 1,
              shadows: readableTextShadow(
                Colors.white,
                background: tileBackground,
              ),
            ),
          ),
        ),
      );
    }

    Widget valueControlsRow({required bool includeRollBadge}) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (onDecrease != null) ...[
            quickAdjustButton(
              icon: Icons.remove,
              tooltip: '-1 $label',
              color: accent,
              onPressed: onDecrease,
            ),
            SizedBox(width: compact ? 4 : 5),
          ],
          Expanded(child: valueControlText()),
          if (onIncrease != null) ...[
            SizedBox(width: compact ? 4 : 5),
            quickAdjustButton(
              icon: Icons.add,
              tooltip: '+1 $label',
              color: accent,
              onPressed: onIncrease,
            ),
          ],
          if (includeRollBadge) ...[const SizedBox(width: 6), rollBadge()],
        ],
      );
    }

    final tileBody = Container(
      padding: EdgeInsets.all(compact ? 7 : 10),
      decoration: BoxDecoration(
        gradient: tileGradient,
        borderRadius: BorderRadius.circular(tileRadius),
        border: Border.all(
          color: accent.withValues(alpha: guiStyle == 'phobia' ? 0.78 : 0.62),
        ),
        boxShadow: compact
            ? const <BoxShadow>[]
            : [
                BoxShadow(
                  color: accent.withValues(
                    alpha: guiStyle == 'phobia' ? 0.18 : 0.10,
                  ),
                  blurRadius: guiStyle == 'phobia' ? 12 : 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Stack(
        children: [
          if (clippedTile)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _OculumThemePanelChromePainter(
                    spec: spec,
                    guiStyle: guiStyle,
                    borderColor: accent,
                    compact: true,
                    clipped: clippedTile,
                  ),
                ),
              ),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      cleanUiText(label),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: labelColor,
                        fontWeight: FontWeight.w900,
                        fontSize: compact ? 11.5 : 13,
                        shadows: readableTextShadow(
                          labelColor,
                          background: tileBackground,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    tooltip: t('Tira $label', 'Roll $label'),
                    onPressed: onRoll,
                    constraints: BoxConstraints.tightFor(
                      width: diceButtonSize,
                      height: diceButtonSize,
                    ),
                    padding: EdgeInsets.zero,
                    style: IconButton.styleFrom(
                      backgroundColor: accent.withValues(alpha: 0.17),
                      foregroundColor: accent,
                      side: BorderSide(color: accent.withValues(alpha: 0.45)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          guiStyle == 'postea' ||
                                  guiStyle == 'kingi' ||
                                  guiStyle == 'medieval'
                              ? 7
                              : 12,
                        ),
                      ),
                    ),
                    icon: Icon(Icons.casino, size: diceIconSize),
                  ),
                ],
              ),
              SizedBox(height: compact ? 3 : 6),
              valueControlsRow(includeRollBadge: !compact),
              if (compact) ...[
                const SizedBox(height: 3),
                Align(
                  alignment: Alignment.centerRight,
                  child: rollBadge(tight: true),
                ),
              ],
              if (hasExtra) ...[
                SizedBox(height: compact ? 3 : 5),
                Text(
                  [
                    if (buff != 0) 'Tit ${buff > 0 ? '+' : ''}$buff',
                    if (temp != 0) 'Temp ${temp > 0 ? '+' : ''}$temp',
                    if (bonusSkillForma != 0)
                      'Skill ${bonusSkillForma > 0 ? '+' : ''}$bonusSkillForma',
                  ].join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: readableOnTheme(
                      Colors.grey.shade400,
                      background: tileBackground,
                    ),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
    final tile = clippedTile
        ? ClipPath(
            clipper: _OculumThemePanelClipper(
              guiStyle: guiStyle,
              compact: true,
            ),
            child: tileBody,
          )
        : tileBody;

    final contextualTile = quickContextMenuAnchor(
      label: label,
      child: tile,
      onEdit: onEdit,
      onRoll: onRoll,
      onDecrease: onDecrease,
      onIncrease: onIncrease,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(tileRadius),
        onTap: onEdit,
        onLongPress: onRoll,
        child: contextualTile,
      ),
    );
  }

  Widget statsOverviewPanel({bool dense = false}) {
    return gothicPanel(
      borderColor: primaryColor,
      padding: EdgeInsets.all(dense ? 10 : 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= (dense ? 500 : 720) ? 4 : 2;
          final spacing = dense ? 6.0 : 9.0;
          final itemWidth =
              (constraints.maxWidth - spacing * (columns - 1)) / columns;
          final tiles = [
            statMiniTile(
              label: t('Resilienza', 'Resilience'),
              value: resilienzaTotale(),
              buff: buffResilienza(),
              temp: tempResilienza,
              massimo: resilienzaMassimo(),
              bonusSkillForma: skillFormaBonus('resilienza'),
              color: const Color(0xFF2ECC71),
              onRoll: () =>
                  tiraStat(t('Resilienza', 'Resilience'), resilienzaTotale()),
              onEdit: () => vaiAllaFunzione(
                page: 0,
                anchorId: 'sheet_editable_values_resilienza',
                logTitle: t('Resilienza', 'Resilience'),
              ),
              onDecrease: () => modificaStatAttuale('resilienza', -1),
              onIncrease: () => modificaStatAttuale('resilienza', 1),
            ),
            statMiniTile(
              label: t('Volontà', 'Will'),
              value: volontaTotale(),
              buff: buffVolonta(),
              temp: tempVolonta,
              massimo: volontaMassimo(),
              bonusSkillForma: skillFormaBonus('volonta'),
              color: const Color(0xFFE74C3C),
              onRoll: () => tiraStat(t('Volontà', 'Will'), volontaTotale()),
              onEdit: () => vaiAllaFunzione(
                page: 0,
                anchorId: 'sheet_editable_values_volonta',
                logTitle: t('Volontà', 'Will'),
              ),
              onDecrease: () => modificaStatAttuale('volonta', -1),
              onIncrease: () => modificaStatAttuale('volonta', 1),
            ),
            statMiniTile(
              label: 'Materia',
              value: materiaTotale(),
              buff: buffMateria(),
              temp: tempMateria,
              massimo: materiaMassimo(),
              bonusSkillForma: skillFormaBonus('materia'),
              color: const Color(0xFF44A7FF),
              onRoll: () => tiraStat('Materia', materiaTotale()),
              onEdit: () => vaiAllaFunzione(
                page: 0,
                anchorId: 'sheet_editable_values_materia',
                logTitle: 'Materia',
              ),
              onDecrease: () => modificaStatAttuale('materia', -1),
              onIncrease: () => modificaStatAttuale('materia', 1),
            ),
            statMiniTile(
              label: 'Oculum',
              value: oculumTotale(),
              buff: buffOculum(),
              temp: tempOculum,
              massimo: oculumMassimo(),
              bonusSkillForma: skillFormaBonus('oculum'),
              color: oculumStatFormulaColor,
              onRoll: () => tiraStat('Oculum', oculumTotale()),
              onEdit: () => vaiAllaFunzione(
                page: 0,
                anchorId: 'sheet_editable_values_oculum',
                logTitle: 'Oculum',
              ),
              onDecrease: () => modificaStatAttuale('oculum', -1),
              onIncrease: () => modificaStatAttuale('oculum', 1),
            ),
          ];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_graph, color: primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t('Statistiche', 'Stats'),
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w900,
                        fontSize: dense ? 16 : 19,
                      ),
                    ),
                  ),
                  Text(
                    t('tocca = modifica', 'tap = edit'),
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              quickStatTile(
                label: t('Stats Totali + LVL', 'Total Stats + LVL'),
                value:
                    '${statsMassimeTotali()} + Lv ${max(0, leggiNumero(livelloController))}',
                icon: Icons.functions,
                color: tertiaryColor,
                onTap: () => vaiAllaFunzione(
                  page: 0,
                  anchorId: 'sheet_editable_values',
                  logTitle: t('Stats Totali + LVL', 'Total Stats + LVL'),
                ),
              ),
              SizedBox(height: dense ? 8 : 12),
              Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final tile in tiles)
                    SizedBox(width: itemWidth, child: tile),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget mainValuesOverviewPanel({bool dense = false}) {
    final domDif = elementoDifesaDominante();
    final domDan = elementoDannoDominante();
    final stackedVitals = themeUsesStackedVitalsHud();
    return gothicPanel(
      borderColor: const Color(0xFF7EE7C8),
      padding: EdgeInsets.all(dense ? 10 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.dashboard_customize, color: Color(0xFF7EE7C8)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t('Riepilogo rapido', 'Quick summary'),
                  style: const TextStyle(
                    color: Color(0xFF7EE7C8),
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
              ),
              Text(
                '${t('Peso', 'Weight')} ${pesoMassimo().toStringAsFixed(0)}kg',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: dense ? 6 : 8,
            runSpacing: dense ? 6 : 8,
            children: [
              if (stackedVitals)
                SizedBox(
                  width: dense ? 276 : 340,
                  child: stackedVitalsHudPanel(dense: true, embedded: true),
                )
              else ...[
                quickStatTile(
                  label: 'HP',
                  value: '${hpCorrenti()}/${maxHp()}',
                  icon: Icons.favorite,
                  color: Colors.redAccent,
                  onTap: () => apriDannoCuraDalCentroPartita(target: 'hp'),
                  onRoll: () => tiraValoreSpeciale('HP', hpCorrenti()),
                  onDecrease: () => modificaHpRapido(-1),
                  onIncrease: () => modificaHpRapido(1),
                ),
                quickStatTile(
                  label: 'Temp',
                  value: '${hpTemp()}',
                  icon: Icons.favorite_border,
                  color: Colors.greenAccent,
                  onTap: () => vaiAllaFunzione(page: 0, anchorId: 'sheet_hp'),
                  onRoll: () => tiraValoreSpeciale('HP Temp', hpTemp()),
                  onDecrease: () => modificaHpTempRapido(-1),
                  onIncrease: () => modificaHpTempRapido(1),
                ),
                quickStatTile(
                  label: t('Scudo', 'Shield'),
                  value: '${scudo()}',
                  icon: Icons.shield,
                  color: Colors.lightBlueAccent,
                  onTap: () =>
                      vaiAllaFunzione(page: 0, anchorId: 'sheet_shield'),
                  onRoll: () =>
                      tiraValoreSpeciale(t('Scudo', 'Shield'), scudo()),
                  onDecrease: () => modificaScudoRapido(-1),
                  onIncrease: () => modificaScudoRapido(1),
                ),
              ],
              quickStatTile(
                label: t('Scudo Crit.', 'Crit. Shield'),
                value: '${scudoCritico()}',
                icon: Icons.shield_moon,
                color: Colors.white,
                onTap: () => vaiAllaFunzione(page: 0, anchorId: 'sheet_hp'),
                onRoll: () => tiraValoreSpeciale(
                  t('Scudo Critico', 'Critical Shield'),
                  scudoCritico(),
                ),
                onDecrease: () => modificaScudoCriticoRapido(-1),
                onIncrease: () => modificaScudoCriticoRapido(1),
              ),
              quickStatTile(
                label: 'Karma',
                value: '${karmaTotale()}',
                icon: Icons.balance,
                color: karmaUiColor(),
                onTap: () => vaiAllaFunzione(
                  page: 7,
                  anchorId: 'resources_root',
                  logTitle: 'Karma',
                ),
              ),
              if (!dense || !modalitaVeloce)
                quickStatTile(
                  label: t('Movimento', 'Movement'),
                  value: '${movimento()}m',
                  icon: Icons.directions_walk,
                  color: Colors.cyanAccent,
                  onTap: () => vaiAllaFunzione(
                    page: 0,
                    anchorId: 'sheet_editable_values_materia',
                    logTitle: t('Movimento', 'Movement'),
                  ),
                ),
              quickStatTile(
                label: t('Difesa', 'Defense'),
                value:
                    '${difesa()}${domDif.isNotEmpty ? ' ${elementDisplayName(domDif)}' : ''}',
                icon: Icons.security,
                color: domDif.isEmpty ? primaryColor : elementColor(domDif),
                onTap: () => vaiAllaFunzione(
                  page: 0,
                  anchorId: 'sheet_defense_bonus',
                  logTitle: t('Difesa', 'Defense'),
                ),
                onRoll: () =>
                    tiraValoreSpeciale(t('Difesa', 'Defense'), difesa()),
                onDecrease: () => modificaDifesaRapida(-1),
                onIncrease: () => modificaDifesaRapida(1),
              ),
              quickStatTile(
                label: t('Reazioni', 'Reactions'),
                value: reazioniVelociTotali() > 0
                    ? '${reazioniTotali()} +${reazioniVelociTotali()}V'
                    : '${reazioniTotali()}',
                icon: Icons.reply_all,
                color: Colors.orangeAccent,
                onTap: mostraModificaRapida,
                onRoll: () => tiraValoreSpeciale(
                  t('Reazioni', 'Reactions'),
                  reazioniTotali(),
                ),
                onDecrease: () => modificaControllerNumericoRapido(
                  reazioniController,
                  -1,
                  label: t('Reazioni', 'Reactions'),
                ),
                onIncrease: () => modificaControllerNumericoRapido(
                  reazioniController,
                  1,
                  label: t('Reazioni', 'Reactions'),
                ),
              ),
              quickStatTile(
                label: t('Danno', 'Damage'),
                value:
                    '${dannoTotale()}${domDan != 'sconosciuto' ? ' ${elementDisplayName(domDan)}' : ''}',
                icon: Icons.close,
                color: domDan == 'sconosciuto'
                    ? tertiaryColor
                    : elementColor(domDan),
                onTap: () => apriDannoCuraDalCentroPartita(target: 'damage'),
                onRoll: () =>
                    tiraValoreSpeciale(t('Danno', 'Damage'), dannoTotale()),
                onDecrease: () => modificaBuffMalusRapido(
                  rawKey: 'Danni',
                  label: t('Danno', 'Damage'),
                  delta: -1,
                ),
                onIncrease: () => modificaBuffMalusRapido(
                  rawKey: 'Danni',
                  label: t('Danno', 'Damage'),
                  delta: 1,
                ),
              ),
              if (!dense || !modalitaVeloce)
                quickStatTile(
                  label: t('Formula DIF', 'DEF formula'),
                  value: formulaDifesaDettagliata(),
                  icon: Icons.functions,
                  color: primaryColor,
                  onTap: () => vaiAllaFunzione(
                    page: 0,
                    anchorId: 'sheet_editable_values',
                    logTitle: t('Valori modificabili', 'Editable values'),
                  ),
                ),
              if ((!dense || !modalitaVeloce) &&
                  quickCommandRuntimeDetails('danni').isNotEmpty)
                quickStatTile(
                  label: t('Formula DAN', 'DMG formula'),
                  value: formulaDannoDettagliata(),
                  icon: Icons.functions,
                  color: tertiaryColor,
                  onTap: () => vaiAllaFunzione(
                    page: 0,
                    anchorId: 'sheet_editable_values',
                    logTitle: t('Danno', 'Damage'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget gradeBonusActionButton() {
    return ElevatedButton.icon(
      onPressed: applicaBonusGradoPersonaggio,
      icon: const Icon(Icons.shield_moon),
      style: ElevatedButton.styleFrom(
        backgroundColor: tertiaryColor,
        foregroundColor: tertiaryColor.computeLuminance() > 0.45
            ? Colors.black
            : Colors.white,
        minimumSize: const Size.fromHeight(46),
      ),
      label: Text(t('Applica Bonus Grado', 'Apply Grade Bonus')),
    );
  }

  Widget sheetDiceDropdownPanel({bool dense = false}) {
    return dropdownSection(
      title: t('Dadi rapidi', 'Quick dice'),
      icon: Icons.casino,
      borderColor: tertiaryColor,
      sectionId: 'sheet_dice_quick',
      initiallyExpanded: false,
      child: sheetDiceRollControls(dense: dense, showTitle: false),
    );
  }

  Widget themedSheetDesktopColumn({
    double? width,
    int flex = 1,
    required List<Widget> children,
  }) {
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
    if (width != null) return SizedBox(width: width, child: column);
    return Expanded(flex: flex, child: column);
  }

  Widget themedSheetDesktopRow(List<Widget> children, {double gap = 8}) {
    final spaced = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) spaced.add(SizedBox(width: gap));
      spaced.add(children[i]);
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: spaced);
  }

  Widget characterMobilePage() {
    final dense = lightweightUi;
    final layoutId =
        currentThemeVisualIdentity().mainSheetGuiStyle.sheetLayoutId;
    final children = <Widget>[];

    Widget command() =>
        functionAnchor('sheet_command_center', sheetCommandCenter());
    Widget combat() =>
        functionAnchor('sheet_combat_values', combatOverviewPanel(dense: true));
    Widget values() =>
        functionAnchor('sheet_values', mainValuesOverviewPanel(dense: true));
    Widget hp() => functionAnchor('sheet_hp', hpModePanel());
    Widget damage() => functionAnchor('sheet_damage_heal', damageHealPanel());
    Widget dice() =>
        functionAnchor('sheet_dice_quick', sheetDiceDropdownPanel(dense: true));
    Widget stats() =>
        functionAnchor('sheet_stats', statsOverviewPanel(dense: true));
    Widget editable() =>
        functionAnchor('sheet_editable_values', editableMainValuesDropdown());
    Widget eye() => functionAnchor('sheet_image', oculumEyeBox());
    Widget identity() =>
        functionAnchor('sheet_identity', sheetIdentityEditorPanel(dense: true));
    Widget race() => functionAnchor('sheet_race', raceIdentityPanel());
    Widget exp() => functionAnchor('sheet_exp', experiencePanel());

    void addTrailingTools() {
      if (!modalitaVeloce) {
        children
          ..add(quickIndexButtonsPanel())
          ..add(quickLoreButtonsPanel());
      }
      children.add(functionAnchor('sheet_party', partyPanel()));
      if (!modalitaVeloce) children.add(manualQuickToolsPanel());
      children
        ..add(gradeBonusActionButton())
        ..add(const SizedBox(height: 12))
        ..add(diceResultPanel());
    }

    switch (layoutId) {
      case 'video_hud':
        children.addAll([
          command(),
          hp(),
          combat(),
          stats(),
          damage(),
          dice(),
          oculumResourcePanel(),
          values(),
          editable(),
          eye(),
          identity(),
          race(),
          exp(),
        ]);
        break;
      case 'tactical_board':
        children.addAll([
          command(),
          values(),
          stats(),
          combat(),
          hp(),
          damage(),
          editable(),
          oculumResourcePanel(),
          dice(),
          identity(),
          race(),
          eye(),
          exp(),
        ]);
        break;
      case 'battle_focus':
        children.addAll([
          command(),
          combat(),
          hp(),
          damage(),
          dice(),
          stats(),
          oculumResourcePanel(),
          values(),
          editable(),
          identity(),
          race(),
          eye(),
          exp(),
        ]);
        break;
      case 'quick_grimoire':
        children.addAll([
          values(),
          editable(),
          stats(),
          command(),
          combat(),
          hp(),
          damage(),
          dice(),
          oculumResourcePanel(),
          identity(),
          race(),
          eye(),
          exp(),
        ]);
        break;
      case 'soft_orbit':
        children.addAll([
          eye(),
          identity(),
          oculumResourcePanel(),
          command(),
          stats(),
          hp(),
          damage(),
          combat(),
          dice(),
          values(),
          editable(),
          race(),
          exp(),
        ]);
        break;
      case 'botanical':
      case 'lantern':
        children.addAll([
          eye(),
          identity(),
          race(),
          oculumResourcePanel(),
          stats(),
          hp(),
          damage(),
          combat(),
          command(),
          dice(),
          values(),
          editable(),
          exp(),
        ]);
        break;
      case 'machine':
        children.addAll([
          command(),
          values(),
          editable(),
          combat(),
          stats(),
          hp(),
          damage(),
          oculumResourcePanel(),
          exp(),
          eye(),
          identity(),
          race(),
          dice(),
        ]);
        break;
      case 'phobia':
        children.addAll([
          command(),
          combat(),
          hp(),
          damage(),
          dice(),
          stats(),
          values(),
          editable(),
          eye(),
          identity(),
          race(),
          oculumResourcePanel(),
          exp(),
        ]);
        break;
      case 'chapel':
      case 'altar':
      case 'medieval':
        children.addAll([
          eye(),
          command(),
          hp(),
          damage(),
          combat(),
          stats(),
          dice(),
          values(),
          editable(),
          identity(),
          race(),
          oculumResourcePanel(),
          exp(),
        ]);
        break;
      case 'archive':
      case 'sigil':
      case 'relic':
        children.addAll([
          identity(),
          race(),
          values(),
          editable(),
          stats(),
          oculumResourcePanel(),
          exp(),
          command(),
          combat(),
          hp(),
          damage(),
          dice(),
          eye(),
        ]);
        break;
      case 'orbital':
      case 'slime':
      case 'elemental':
        children.addAll([
          eye(),
          command(),
          stats(),
          hp(),
          oculumResourcePanel(),
          damage(),
          combat(),
          dice(),
          values(),
          editable(),
          identity(),
          race(),
          exp(),
        ]);
        break;
      case 'classic':
      default:
        children.addAll([
          command(),
          combat(),
          values(),
          hp(),
          damage(),
          dice(),
          stats(),
          editable(),
          eye(),
          identity(),
          race(),
          oculumResourcePanel(),
          exp(),
        ]);
    }
    addTrailingTools();

    return ListView(
      key: sheetScrollKey('sheet_mobile'),
      padding: EdgeInsets.all(dense ? 7 : 12),
      children: children,
    );
  }

  Widget characterDesktopPage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 860) return characterMobilePage();

        final layoutId =
            currentThemeVisualIdentity().mainSheetGuiStyle.sheetLayoutId;
        final wide = constraints.maxWidth >= 1180;
        final veryWide = constraints.maxWidth >= 1500;
        final gap = modalitaVeloce ? 8.0 : 10.0;
        final sideWidth = modalitaVeloce
            ? (veryWide ? 292.0 : 252.0)
            : (veryWide ? 310.0 : 264.0);

        Widget hpDamageRow() => LayoutBuilder(
          builder: (context, hpDamageConstraints) {
            final hpCard = functionAnchor('sheet_hp', hpModePanel());
            final damageCard = functionAnchor(
              'sheet_damage_heal',
              damageHealPanel(),
            );
            if (hpDamageConstraints.maxWidth < 620) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  hpCard,
                  SizedBox(height: gap),
                  damageCard,
                ],
              );
            }
            return themedSheetDesktopRow([
              Expanded(child: hpCard),
              Expanded(child: damageCard),
            ], gap: gap);
          },
        );

        List<Widget> identityCards() => [
          functionAnchor('sheet_image', oculumEyeBox()),
          functionAnchor(
            'sheet_identity',
            sheetIdentityEditorPanel(dense: true),
          ),
          functionAnchor('sheet_race', raceIdentityPanel()),
          oculumResourcePanel(),
          functionAnchor('sheet_exp', experiencePanel()),
        ];

        List<Widget> commandCards() => [
          functionAnchor('sheet_command_center', sheetCommandCenter()),
          functionAnchor(
            'sheet_combat_values',
            combatOverviewPanel(dense: true),
          ),
          hpDamageRow(),
          functionAnchor('sheet_stats', statsOverviewPanel(dense: true)),
          functionAnchor('sheet_values', mainValuesOverviewPanel(dense: true)),
          functionAnchor('sheet_editable_values', editableMainValuesDropdown()),
          gradeBonusActionButton(),
        ];

        List<Widget> valueFirstCards() => [
          functionAnchor('sheet_values', mainValuesOverviewPanel(dense: true)),
          functionAnchor('sheet_editable_values', editableMainValuesDropdown()),
          functionAnchor('sheet_stats', statsOverviewPanel(dense: true)),
          functionAnchor(
            'sheet_combat_values',
            combatOverviewPanel(dense: true),
          ),
          hpDamageRow(),
          gradeBonusActionButton(),
        ];

        List<Widget> toolCards({bool includeResult = true}) => [
          desktopQuickBagSidePanel(),
          desktopArtSkillTextSidePanel(),
          functionAnchor(
            'sheet_dice_quick',
            sheetDiceDropdownPanel(dense: true),
          ),
          functionAnchor('sheet_party', partyPanel()),
          if (!modalitaVeloce) quickIndexButtonsPanel(),
          if (!modalitaVeloce) manualQuickToolsPanel(),
          if (includeResult) diceResultPanel(),
        ];

        Widget identityColumn({double? width, int flex = 1}) =>
            themedSheetDesktopColumn(
              width: width,
              flex: flex,
              children: identityCards(),
            );

        Widget commandColumn({double? width, int flex = 1}) =>
            themedSheetDesktopColumn(
              width: width,
              flex: flex,
              children: commandCards(),
            );

        Widget valuesColumn({double? width, int flex = 1}) =>
            themedSheetDesktopColumn(
              width: width,
              flex: flex,
              children: valueFirstCards(),
            );

        Widget toolsColumn({
          double? width,
          int flex = 1,
          bool includeResult = true,
        }) => themedSheetDesktopColumn(
          width: width,
          flex: flex,
          children: toolCards(includeResult: includeResult),
        );

        Widget combatFirstColumn({double? width, int flex = 1}) =>
            themedSheetDesktopColumn(
              width: width,
              flex: flex,
              children: [
                functionAnchor(
                  'sheet_combat_values',
                  combatOverviewPanel(dense: true),
                ),
                hpDamageRow(),
                functionAnchor('sheet_stats', statsOverviewPanel(dense: true)),
                functionAnchor('sheet_command_center', sheetCommandCenter()),
                functionAnchor(
                  'sheet_values',
                  mainValuesOverviewPanel(dense: true),
                ),
                functionAnchor(
                  'sheet_editable_values',
                  editableMainValuesDropdown(),
                ),
                gradeBonusActionButton(),
              ],
            );

        Widget machineActionColumn({double? width, int flex = 1}) =>
            themedSheetDesktopColumn(
              width: width,
              flex: flex,
              children: [
                functionAnchor('sheet_command_center', sheetCommandCenter()),
                functionAnchor(
                  'sheet_values',
                  mainValuesOverviewPanel(dense: true),
                ),
                functionAnchor(
                  'sheet_editable_values',
                  editableMainValuesDropdown(),
                ),
                desktopQuickBagSidePanel(),
                desktopArtSkillTextSidePanel(),
                if (!modalitaVeloce) quickIndexButtonsPanel(),
                if (!modalitaVeloce) manualQuickToolsPanel(),
              ],
            );

        Widget machineCombatColumn({double? width, int flex = 1}) =>
            themedSheetDesktopColumn(
              width: width,
              flex: flex,
              children: [
                functionAnchor(
                  'sheet_combat_values',
                  combatOverviewPanel(dense: true),
                ),
                hpDamageRow(),
                functionAnchor('sheet_stats', statsOverviewPanel(dense: true)),
                gradeBonusActionButton(),
                functionAnchor('sheet_party', partyPanel()),
                functionAnchor(
                  'sheet_dice_quick',
                  sheetDiceDropdownPanel(dense: true),
                ),
                diceResultPanel(),
              ],
            );

        Widget machineIdentityColumn({double? width, int flex = 1}) =>
            themedSheetDesktopColumn(
              width: width,
              flex: flex,
              children: [
                functionAnchor('sheet_image', oculumEyeBox()),
                functionAnchor(
                  'sheet_identity',
                  sheetIdentityEditorPanel(dense: true),
                ),
                functionAnchor('sheet_race', raceIdentityPanel()),
                oculumResourcePanel(),
                functionAnchor('sheet_exp', experiencePanel()),
              ],
            );

        Widget videoHudControlsColumn({double? width, int flex = 1}) =>
            themedSheetDesktopColumn(
              width: width,
              flex: flex,
              children: [
                functionAnchor('sheet_command_center', sheetCommandCenter()),
                functionAnchor(
                  'sheet_dice_quick',
                  sheetDiceDropdownPanel(dense: true),
                ),
                diceResultPanel(),
                if (!modalitaVeloce) quickIndexButtonsPanel(),
              ],
            );

        Widget videoHudLiveColumn({double? width, int flex = 1}) =>
            themedSheetDesktopColumn(
              width: width,
              flex: flex,
              children: [
                hpDamageRow(),
                functionAnchor(
                  'sheet_combat_values',
                  combatOverviewPanel(dense: true),
                ),
                functionAnchor('sheet_stats', statsOverviewPanel(dense: true)),
                gradeBonusActionButton(),
              ],
            );

        Widget videoHudInfoColumn({double? width, int flex = 1}) =>
            themedSheetDesktopColumn(
              width: width,
              flex: flex,
              children: [
                functionAnchor(
                  'sheet_values',
                  mainValuesOverviewPanel(dense: true),
                ),
                functionAnchor(
                  'sheet_editable_values',
                  editableMainValuesDropdown(),
                ),
                oculumResourcePanel(),
                functionAnchor('sheet_party', partyPanel()),
                desktopQuickBagSidePanel(),
              ],
            );

        Widget tacticalIdentityColumn({double? width, int flex = 1}) =>
            themedSheetDesktopColumn(
              width: width,
              flex: flex,
              children: [
                functionAnchor('sheet_image', oculumEyeBox()),
                functionAnchor(
                  'sheet_identity',
                  sheetIdentityEditorPanel(dense: true),
                ),
                functionAnchor('sheet_race', raceIdentityPanel()),
                oculumResourcePanel(),
                functionAnchor('sheet_exp', experiencePanel()),
              ],
            );

        Widget tacticalLiveColumn({double? width, int flex = 1}) =>
            themedSheetDesktopColumn(
              width: width,
              flex: flex,
              children: [
                functionAnchor('sheet_command_center', sheetCommandCenter()),
                hpDamageRow(),
                functionAnchor('sheet_stats', statsOverviewPanel(dense: true)),
                functionAnchor(
                  'sheet_combat_values',
                  combatOverviewPanel(dense: true),
                ),
                gradeBonusActionButton(),
              ],
            );

        Widget tacticalToolsColumn({double? width, int flex = 1}) =>
            themedSheetDesktopColumn(
              width: width,
              flex: flex,
              children: [
                functionAnchor(
                  'sheet_values',
                  mainValuesOverviewPanel(dense: true),
                ),
                functionAnchor(
                  'sheet_editable_values',
                  editableMainValuesDropdown(),
                ),
                functionAnchor(
                  'sheet_dice_quick',
                  sheetDiceDropdownPanel(dense: true),
                ),
                desktopQuickBagSidePanel(),
                functionAnchor('sheet_party', partyPanel()),
                diceResultPanel(),
              ],
            );

        Widget battleFocusLeftColumn({double? width, int flex = 1}) =>
            themedSheetDesktopColumn(
              width: width,
              flex: flex,
              children: [
                functionAnchor('sheet_command_center', sheetCommandCenter()),
                functionAnchor(
                  'sheet_dice_quick',
                  sheetDiceDropdownPanel(dense: true),
                ),
                diceResultPanel(),
                functionAnchor('sheet_party', partyPanel()),
              ],
            );

        Widget battleFocusCenterColumn({double? width, int flex = 1}) =>
            themedSheetDesktopColumn(
              width: width,
              flex: flex,
              children: [
                functionAnchor(
                  'sheet_combat_values',
                  combatOverviewPanel(dense: true),
                ),
                hpDamageRow(),
                functionAnchor('sheet_stats', statsOverviewPanel(dense: true)),
                gradeBonusActionButton(),
              ],
            );

        Widget battleFocusRightColumn({double? width, int flex = 1}) =>
            themedSheetDesktopColumn(
              width: width,
              flex: flex,
              children: [
                functionAnchor(
                  'sheet_values',
                  mainValuesOverviewPanel(dense: true),
                ),
                functionAnchor(
                  'sheet_editable_values',
                  editableMainValuesDropdown(),
                ),
                oculumResourcePanel(),
                desktopQuickBagSidePanel(),
                functionAnchor(
                  'sheet_identity',
                  sheetIdentityEditorPanel(dense: true),
                ),
              ],
            );

        Widget quickGrimoireIndexColumn({double? width, int flex = 1}) =>
            themedSheetDesktopColumn(
              width: width,
              flex: flex,
              children: [
                functionAnchor(
                  'sheet_values',
                  mainValuesOverviewPanel(dense: true),
                ),
                functionAnchor(
                  'sheet_editable_values',
                  editableMainValuesDropdown(),
                ),
                functionAnchor('sheet_stats', statsOverviewPanel(dense: true)),
                gradeBonusActionButton(),
              ],
            );

        Widget quickGrimoirePlayColumn({double? width, int flex = 1}) =>
            themedSheetDesktopColumn(
              width: width,
              flex: flex,
              children: [
                functionAnchor('sheet_command_center', sheetCommandCenter()),
                hpDamageRow(),
                functionAnchor(
                  'sheet_combat_values',
                  combatOverviewPanel(dense: true),
                ),
                functionAnchor(
                  'sheet_dice_quick',
                  sheetDiceDropdownPanel(dense: true),
                ),
                diceResultPanel(),
              ],
            );

        Widget quickGrimoireLoreColumn({double? width, int flex = 1}) =>
            themedSheetDesktopColumn(
              width: width,
              flex: flex,
              children: [
                functionAnchor('sheet_image', oculumEyeBox()),
                functionAnchor(
                  'sheet_identity',
                  sheetIdentityEditorPanel(dense: true),
                ),
                functionAnchor('sheet_race', raceIdentityPanel()),
                oculumResourcePanel(),
                desktopQuickBagSidePanel(),
                if (!modalitaVeloce) manualQuickToolsPanel(),
              ],
            );

        final children = <Widget>[];

        switch (layoutId) {
          case 'video_hud':
            children.add(
              themedSheetDesktopRow(
                wide
                    ? [
                        videoHudControlsColumn(flex: 3),
                        videoHudLiveColumn(flex: 4),
                        videoHudInfoColumn(flex: 3),
                      ]
                    : [
                        videoHudControlsColumn(flex: 1),
                        videoHudLiveColumn(flex: 1),
                      ],
                gap: gap,
              ),
            );
            if (!wide) {
              children
                ..add(SizedBox(height: gap))
                ..add(videoHudInfoColumn());
            }
            break;
          case 'tactical_board':
            children.add(
              themedSheetDesktopRow(
                wide
                    ? [
                        tacticalIdentityColumn(flex: 3),
                        tacticalLiveColumn(flex: 4),
                        tacticalToolsColumn(flex: 3),
                      ]
                    : [
                        tacticalLiveColumn(flex: 1),
                        tacticalIdentityColumn(width: sideWidth),
                      ],
                gap: gap,
              ),
            );
            if (!wide) {
              children
                ..add(SizedBox(height: gap))
                ..add(tacticalToolsColumn());
            }
            break;
          case 'battle_focus':
            children.add(
              themedSheetDesktopRow(
                wide
                    ? [
                        battleFocusLeftColumn(flex: 3),
                        battleFocusCenterColumn(flex: 4),
                        battleFocusRightColumn(flex: 3),
                      ]
                    : [
                        battleFocusCenterColumn(flex: 1),
                        battleFocusLeftColumn(width: sideWidth),
                      ],
                gap: gap,
              ),
            );
            if (!wide) {
              children
                ..add(SizedBox(height: gap))
                ..add(battleFocusRightColumn());
            }
            break;
          case 'quick_grimoire':
            children.add(
              themedSheetDesktopRow(
                wide
                    ? [
                        quickGrimoireIndexColumn(flex: 3),
                        quickGrimoirePlayColumn(flex: 4),
                        quickGrimoireLoreColumn(flex: 3),
                      ]
                    : [
                        quickGrimoireIndexColumn(flex: 1),
                        quickGrimoirePlayColumn(flex: 1),
                      ],
                gap: gap,
              ),
            );
            if (!wide) {
              children
                ..add(SizedBox(height: gap))
                ..add(quickGrimoireLoreColumn());
            }
            break;
          case 'soft_orbit':
            children.add(
              themedSheetDesktopRow(
                wide
                    ? [
                        identityColumn(flex: 3),
                        commandColumn(flex: 4),
                        toolsColumn(flex: 3),
                      ]
                    : [
                        identityColumn(width: sideWidth),
                        commandColumn(flex: 1),
                      ],
                gap: gap,
              ),
            );
            if (!wide) {
              children
                ..add(SizedBox(height: gap))
                ..add(toolsColumn());
            }
            break;
          case 'botanical':
          case 'lantern':
            children.add(
              wide
                  ? themedSheetDesktopRow([
                      combatFirstColumn(flex: 3),
                      identityColumn(flex: 4),
                      toolsColumn(flex: 3),
                    ], gap: gap)
                  : themedSheetDesktopRow([
                      identityColumn(width: sideWidth),
                      combatFirstColumn(flex: 1),
                    ], gap: gap),
            );
            if (!wide) {
              children
                ..add(SizedBox(height: gap))
                ..add(toolsColumn());
            }
            break;
          case 'machine':
            children.add(
              themedSheetDesktopRow([
                machineActionColumn(flex: wide ? 3 : 1),
                machineCombatColumn(flex: wide ? 4 : 1),
                if (wide) machineIdentityColumn(flex: 3),
              ], gap: gap),
            );
            if (!wide) {
              children
                ..add(SizedBox(height: gap))
                ..add(machineIdentityColumn());
            }
            break;
          case 'phobia':
            children.add(
              themedSheetDesktopRow(
                wide
                    ? [
                        themedSheetDesktopColumn(
                          flex: 3,
                          children: [
                            functionAnchor(
                              'sheet_command_center',
                              sheetCommandCenter(),
                            ),
                            functionAnchor(
                              'sheet_dice_quick',
                              sheetDiceDropdownPanel(dense: true),
                            ),
                            diceResultPanel(),
                          ],
                        ),
                        combatFirstColumn(flex: 4),
                        themedSheetDesktopColumn(
                          flex: 3,
                          children: [
                            functionAnchor('sheet_image', oculumEyeBox()),
                            functionAnchor(
                              'sheet_identity',
                              sheetIdentityEditorPanel(dense: true),
                            ),
                            functionAnchor('sheet_race', raceIdentityPanel()),
                            desktopQuickBagSidePanel(),
                            functionAnchor('sheet_party', partyPanel()),
                            desktopArtSkillTextSidePanel(),
                          ],
                        ),
                      ]
                    : [
                        commandColumn(flex: 1),
                        identityColumn(width: sideWidth),
                      ],
                gap: gap,
              ),
            );
            if (!wide) {
              children
                ..add(SizedBox(height: gap))
                ..add(toolsColumn());
            }
            break;
          case 'chapel':
          case 'altar':
          case 'medieval':
            children.add(
              themedSheetDesktopRow(
                wide
                    ? [
                        identityColumn(flex: 3),
                        commandColumn(flex: 4),
                        toolsColumn(flex: 3),
                      ]
                    : [
                        commandColumn(flex: 1),
                        themedSheetDesktopColumn(
                          width: sideWidth,
                          children: [
                            functionAnchor('sheet_image', oculumEyeBox()),
                            functionAnchor(
                              'sheet_identity',
                              sheetIdentityEditorPanel(dense: true),
                            ),
                            oculumResourcePanel(),
                            functionAnchor('sheet_exp', experiencePanel()),
                          ],
                        ),
                      ],
                gap: gap,
              ),
            );
            if (!wide) {
              children
                ..add(SizedBox(height: gap))
                ..add(toolsColumn());
            }
            break;
          case 'archive':
          case 'sigil':
          case 'relic':
            children.add(
              themedSheetDesktopRow(
                wide
                    ? [
                        themedSheetDesktopColumn(
                          flex: 3,
                          children: [
                            functionAnchor(
                              'sheet_command_center',
                              sheetCommandCenter(),
                            ),
                            ...valueFirstCards(),
                          ],
                        ),
                        identityColumn(flex: 4),
                        toolsColumn(flex: 3),
                      ]
                    : [valuesColumn(flex: 1), identityColumn(width: sideWidth)],
                gap: gap,
              ),
            );
            if (!wide) {
              children
                ..add(SizedBox(height: gap))
                ..add(
                  functionAnchor('sheet_command_center', sheetCommandCenter()),
                );
            }
            if (!wide) {
              children
                ..add(SizedBox(height: gap))
                ..add(toolsColumn());
            }
            break;
          case 'orbital':
          case 'slime':
          case 'elemental':
            children.add(
              themedSheetDesktopRow(
                wide
                    ? [
                        identityColumn(flex: 3),
                        commandColumn(flex: 4),
                        toolsColumn(flex: 3),
                      ]
                    : [
                        identityColumn(width: sideWidth),
                        commandColumn(flex: 1),
                      ],
                gap: gap,
              ),
            );
            if (!wide) {
              children
                ..add(SizedBox(height: gap))
                ..add(toolsColumn());
            }
            break;
          case 'classic':
          default:
            children.add(
              themedSheetDesktopRow(
                wide
                    ? [
                        identityColumn(flex: 3),
                        commandColumn(flex: 4),
                        toolsColumn(flex: 3),
                      ]
                    : [
                        identityColumn(width: sideWidth),
                        commandColumn(flex: 1),
                      ],
                gap: gap,
              ),
            );
            if (!wide) {
              children
                ..add(SizedBox(height: gap))
                ..add(
                  themedSheetDesktopRow([
                    Expanded(child: desktopQuickBagSidePanel()),
                    Expanded(child: desktopArtSkillTextSidePanel()),
                  ], gap: gap),
                )
                ..add(
                  functionAnchor(
                    'sheet_dice_quick',
                    sheetDiceDropdownPanel(dense: true),
                  ),
                )
                ..add(functionAnchor('sheet_party', partyPanel()));
              if (!modalitaVeloce) children.add(manualQuickToolsPanel());
              children.add(diceResultPanel());
            }
        }

        return ListView(
          key: sheetScrollKey('sheet_desktop'),
          padding: EdgeInsets.all(modalitaVeloce ? 8 : 10),
          children: children,
        );
      },
    );
  }

  Widget characterPage() {
    final viewportWidth = MediaQuery.maybeOf(context)?.size.width ?? 1200;
    if (!modalitaDesktop || phoneCompactUi || viewportWidth < 700) {
      return characterMobilePage();
    }
    return characterDesktopPage();
  }

  // =====================================================
}
