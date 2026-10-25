part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

extension _OculumMonsterAppearance on _OculumHomePageState {
  Color? get narrativeInterfaceAccent {
    if (colorPresetSelezionato == 'custom') return null;
    final selected = oculumThemePresentationForSheet(
      currentSheetScrollId(),
    ).artPackId;
    final monster = oculumMonsterThemeById(selected);
    return monster?.accent ??
        (oculumStoryThemePacks.containsKey(selected)
            ? oculumNarrativeAccent(selected)
            : null);
  }

  Color? get narrativeInterfaceSurface => narrativeInterfaceAccent == null
      ? null
      : Color.lerp(const Color(0xff0d1013), narrativeInterfaceAccent, .07);
  bool get canManageAllThemes => realtimeService?.isConnected == true
      ? realtimeService?.authenticatedRole == 'master'
      : realtimeIsMasterRole;

  void rememberAssignedTheme(String id) {
    if (canManageAllThemes && id.isNotEmpty) masterAssignedThemeIds.add(id);
  }

  Future<void> chooseCurrentSheetRelic() async {
    final sheetId = currentSheetScrollId();
    final campaign = permissionScope;
    await showOculumRelicPicker(
      context,
      sheetId: sheetId,
      sheetName: nomeController.text,
      canManageAll: () =>
          mounted &&
          currentSheetScrollId() == sheetId &&
          permissionScope == campaign &&
          canManageAllThemes,
      assignedThemes: () =>
          currentSheetScrollId() == sheetId && permissionScope == campaign
          ? masterAssignedThemeIds
          : const {},
      onSelected: (id) async {
        if (!mounted ||
            currentSheetScrollId() != sheetId ||
            permissionScope != campaign) {
          return;
        }
        await selectCurrentSheetRelic(id);
      },
    );
  }

  Future<bool> selectCurrentSheetRelic(String id) async {
    if (!mounted ||
        schedaCorrente < 0 ||
        schedaCorrente >= schedePersonaggio.length) {
      return false;
    }
    final sheet = schedePersonaggio[schedaCorrente];
    if (activeCampaignId.isEmpty && canManageAllThemes) {
      saveActiveCampaignInMemory();
    }
    if (readBoolValue(sheet['realtimeReadOnlyByMaster']) ||
        readBoolValue(sheet['realtimeRestrictedByMaster']) ||
        (readBoolValue(sheet['realtimeSharedSheet']) && !haPermessiMaster)) {
      return false;
    }
    final tag = currentSheetScrollId();
    if (!oculumCanSelectRelic(
      id,
      sheetId: tag,
      master: canManageAllThemes,
      assigned: masterAssignedThemeIds,
    )) {
      return false;
    }
    rememberAssignedTheme(id);
    await setOculumSheetRelic(tag, id);
    if (!mounted || currentSheetScrollId() != tag) return true;
    salvaSchedaCorrenteInMemoria();
    programmaSalvataggio(invalidateCaches: false);
    if (realtimeService?.isConnected == true) {
      if (readBoolValue(sheet['realtimeSharedSheet'])) {
        await sendRealtimeEditedSharedSheetBack();
      } else {
        sendRealtimeCurrentSheetToStaff(immediate: true);
        sendRealtimeCurrentPartySheet();
      }
    }
    return true;
  }

  void onSheetRelicChanged() {
    if (!mounted) return;
    setState(() {});
    if (datiCaricati) programmaSalvataggio();
  }

  void syncMonsterThemeUnlocks() {
    final prefix = '$permissionCampaignId:';
    final unlocked = <String>{
      for (final entry in monsterBookPartyDiscoveries.entries)
        if (entry.key.startsWith(prefix) &&
            (entry.value['themeUnlocked'] == true ||
                entry.value['pagePurchased'] == true))
          entry.key.substring(prefix.length),
    };
    if (!setEquals(unlocked, oculumMonsterThemeUnlocks.value)) {
      oculumMonsterThemeUnlocks.value = unlocked;
    }
  }

  void restoreMonsterAppearance(
    Map<String, dynamic> sheet, {
    bool newlyCreated = false,
  }) {
    final tag = '${sheet['sheetTag'] ?? sheet['id'] ?? currentSheetScrollId()}';
    final monster = monsterBookEntryById(
      '${sheet['monsterBookSourceId'] ?? ''}',
    );
    var appearance = Map<String, dynamic>.from(
      sheet['monsterAppearance'] as Map? ?? {},
    );
    if (monster != null &&
        (newlyCreated ||
            oculumMonsterThemeById(
                  '${appearance['themeId'] ?? ''}',
                )?.monster.id !=
                monster.id)) {
      final legacyColor =
          '${(sheet['planarRuntime'] as Map?)?['creatureColor'] ?? ''}';
      final colors = oculumMonsterColors(monster);
      final legacy = colors.where((c) => c.name == legacyColor).firstOrNull;
      final color =
          legacy ??
          oculumRollMonsterColor(
            monster,
            random: newlyCreated
                ? null
                : Random(oculumMonsterArtSeed('$tag:${monster.id}')),
          );
      appearance = {
        'themeId': OculumMonsterTheme(monster, color).id,
        'color': color.name,
        'version': 1,
      };
      sheet['monsterAppearance'] = appearance;
    }
    final automatic = Map<String, String>.from(oculumSheetMonsterThemes.value);
    final key = '${appearance['themeId'] ?? ''}';
    if (monster != null && oculumMonsterThemeById(key) != null) {
      automatic[tag] = key;
    } else {
      automatic[tag] = 'plane_${sheet['selectedPlaneId'] ?? 'mezzano'}';
    }
    if (!mapEquals(automatic, oculumSheetMonsterThemes.value)) {
      oculumSheetMonsterThemes.value = automatic;
    }
    if (sheet.containsKey('relicArtPackId')) {
      final choices = Map<String, String>.from(
        oculumSheetRelicSelections.value,
      );
      final selected = '${sheet['relicArtPackId'] ?? ''}';
      if (selected.isEmpty) {
        choices.remove(tag);
      } else {
        choices[tag] = selected;
      }
      if (!mapEquals(choices, oculumSheetRelicSelections.value)) {
        oculumSheetRelicSelections.value = choices;
      }
    }
  }

  ThemeData currentMonsterTheme(ThemeData base) {
    final selected = oculumThemePresentationForSheet(
      currentSheetScrollId(),
    ).artPackId;
    final monster = oculumMonsterThemeById(selected);
    if (monster == null && !oculumStoryThemePacks.containsKey(selected)) {
      return base;
    }
    final themedAccent = monster?.accent ?? oculumNarrativeAccent(selected);
    final custom = colorPresetSelezionato == 'custom';
    final accent = custom ? tertiaryColor : themedAccent;
    final surface = custom
        ? backgroundMidColor
        : (monster?.surface ??
              Color.lerp(const Color(0xff0d1013), themedAccent, .07)!);
    final ornaments = base.extension<OculumGothOrnaments>();
    return oculumBuildPaletteTheme(
      base: base,
      primary: custom ? primaryColor : const Color(0xffded7c8),
      secondary: surface,
      accent: accent,
      surface: surface,
      background: const Color(0xff090b0e),
      fontFamily: base.textTheme.bodyMedium?.fontFamily ?? 'Segoe UI',
      buttonFamily: OculumGothFamily.forged,
      buttonInk: accent,
      buttonDecorationOpacity: .35,
      themeVariant: oculumThemePresentation.value.variant,
    ).copyWith(
      extensions: [
        ...base.extensions.values,
        OculumGothOrnaments(
          themeId: monster?.id ?? selected,
          family: OculumGothFamily.forged,
          ink: accent,
          accent: accent,
          opacity: ornaments?.opacity ?? .3,
          motion: false,
        ),
      ],
    );
  }
}
