part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

extension _OculumSleepAndNeeds on _OculumHomePageState {
  String get worldNeedsCampaignKey => realtimeService?.isConnected == true
      ? permissionCampaignId
      : activeCampaignId;
  Map<String, dynamic> get worldNeedsCampaigns {
    final raw = planarState['worldNeedsCampaigns'];
    if (raw is Map<String, dynamic>) return raw;
    final value = Map<String, dynamic>.from(raw is Map ? raw : const {});
    planarState['worldNeedsCampaigns'] = value;
    return value;
  }

  Map<String, dynamic> get worldNeedsData => Map<String, dynamic>.from(
    worldNeedsCampaigns[worldNeedsCampaignKey] is Map
        ? worldNeedsCampaigns[worldNeedsCampaignKey] as Map
        : const {},
  );

  bool get automaticWorldNeedsEnabled {
    final override = planarState['personalNeedsEnabled'];
    if (override is bool) return override;
    if (schedaCorrente < 0 || schedaCorrente >= schedePersonaggio.length) {
      return false;
    }
    final sheet = schedePersonaggio[schedaCorrente];
    // A biological character does not lose their needs merely because its
    // sheet comes from the Monster Book. Explicit copies/summons are separate;
    // the Construct profile below exempts food/water, not maintenance.
    return sheet['isSummon'] != true &&
        '${sheet['occhioCadutoId'] ?? ''}'.isEmpty &&
        planarState['doppioneCopy'] != true &&
        sheet['senkaShadowClone'] != true;
  }

  Map<String, dynamic> newestWorldClockSnapshot(Map raw, {Map? previous}) {
    final replicas = Map<String, dynamic>.from(
      extraTopLevelSaveFields['worldClockReplicas'] is Map
          ? extraTopLevelSaveFields['worldClockReplicas'] as Map
          : const {},
    );
    final key = permissionScope;
    var accepted = OculumWorldClockProgress.fromJson(raw).publicJson();
    for (final prior in [previous, replicas[key]]) {
      if (prior is Map && !oculumWorldClockSnapshotFollows(accepted, prior)) {
        accepted = OculumWorldClockProgress.fromJson(prior).publicJson();
      }
    }
    if (jsonEncode(replicas[key]) != jsonEncode(accepted)) {
      replicas[key] = jsonDecode(jsonEncode(accepted));
      extraTopLevelSaveFields['worldClockReplicas'] = replicas;
      programmaSalvataggio();
    }
    return accepted;
  }

  OculumPersonalNeedsProgress personalNeedsProgress({int? now}) {
    final progress = OculumPersonalNeedsProgress.fromJson(
      worldNeedsData,
      now: now ?? worldClockSeconds,
      physiologicalDefaults: isConstructCharacter
          ? const {
              'foodEnabled': false,
              'waterEnabled': false,
              'sleepEnabled': true,
            }
          : const {},
    );
    final configured = planarState['personalNeedsRules'];
    if (configured is Map) {
      progress.config.addAll(Map<String, dynamic>.from(configured));
    }
    return progress;
  }

  int worldNeedStatPenalty(String stat) => !automaticWorldNeedsEnabled
      ? 0
      : personalNeedsProgress().statPenalty(stat);
  int worldNeedAsh() =>
      !automaticWorldNeedsEnabled ? 0 : personalNeedsProgress().ash;
  int worldNeedsEffectiveAsh() =>
      max(0, leggiNumero(cenereController)) + worldNeedAsh();

  OculumSleepRecoveryRules get personalSleepRecoveryRules =>
      OculumSleepRecoveryRules(
        planarState['sleepRecoveryRules'] is Map
            ? planarState['sleepRecoveryRules'] as Map
            : const {},
      );

  int get currentWorldCalendarDay {
    final raw = realtimeService?.isConnected == true && !realtimeIsMasterRole
        ? realtimeVisibleInitiativeSnapshot['worldClock']
        : worldClockCampaignJson();
    if (raw is! Map || readIntValue(raw['calendarOriginDay']) <= 0) {
      return oculumCurrentDay();
    }
    return oculumCalendarDayAt(
      worldClockSeconds,
      originDay: readIntValue(raw['calendarOriginDay']),
      originOrdinal: readIntValue(raw['calendarOriginOrdinal']),
    );
  }

  void ensureWorldCalendarOrigin(OculumWorldClockProgress clock) {
    if (clock.calendarOriginDay > 0) return;
    clock.calendarOriginDay = oculumCurrentDay();
    clock.calendarOriginOrdinal = clock.seconds ~/ oculumWorldDaySeconds;
  }

  void prepareOwnedWorldTimeAdvance(OculumWorldClockProgress clock) {
    ensureWorldCalendarOrigin(clock);
    syncOwnedWorldCalendarAndNeeds(clock.publicJson());
  }

  /// Called only with the campaign clock or an authenticated Master snapshot.
  /// A separate owner ledger prevents one player's save from mutating another.
  void syncOwnedWorldCalendarAndNeeds(Map<String, dynamic> clock) {
    final origin = readIntValue(clock['calendarOriginDay']);
    if (origin <= 0) return; // Unmigrated legacy snapshot: never reset dates.
    // Apply confirmed historical sleep first, then derive deprivation up to
    // the current clock. A late grant cannot erase days after the actual rest.
    applyConfirmedWorldRestGrants(clock);
    final now = max(0, readIntValue(clock['seconds']));
    final ordinal = now ~/ oculumWorldDaySeconds;
    final day = oculumCalendarDayAt(
      now,
      originDay: origin,
      originOrdinal: readIntValue(clock['calendarOriginOrdinal']),
    );
    final tags = [
      for (var i = 0; i < schedePersonaggio.length; i++)
        if (schedePersonaggio[i]['realtimeSharedSheet'] != true) sheetTagAt(i),
    ];
    final dirtyTags = <String>{};
    for (final tag in tags) {
      faunaForOwnedSheet(tag, () {
        final raw = worldNeedsData;
        final priorOrdinal = readIntValue(
          raw['calendarOrdinal'],
          fallback: ordinal,
        );
        // Earlier or replayed snapshots cannot rewind deprivation or rot.
        if (raw['calendarOrdinal'] != null && ordinal < priorOrdinal) return;
        final previousDay = oculumCurrentDay();
        if (raw['calendarOrdinal'] == null) {
          for (final item in inventario) {
            if (item.putrefazioneSessioni <= 0 || itemGiaPutrefatto(item)) {
              continue;
            }
            if (item.putrefazioneGiornoInizio > 0) {
              item.sessioniSegnate = max(
                item.sessioniSegnate,
                oculumDayDistance(item.putrefazioneGiornoInizio, previousDay),
              );
            }
          }
        }
        final delta = max(0, ordinal - priorOrdinal);
        // Preserve the old elapsedNights count at migration, then count only
        // real campaign Night -> Morning crossings, even when staying awake.
        for (var night = 0; night < delta; night++) {
          advanceCorruptionNight();
        }
        if (previousDay != day || delta > 0) {
          cycleCalendarChanged(previousDay, day, delta: delta);
          oculumCurrentDayController.text = '$day';
          if (delta > 0) advanceWorldInventoryDays(previousDay, delta);
        }
        final beforeAsh = worldNeedsEffectiveAsh();
        final progress = personalNeedsProgress(now: now);
        final previousEpisodes = progress.episodes.length;
        if (automaticWorldNeedsEnabled) {
          progress.advanceTo(now);
        } else {
          for (final need in oculumPersonalNeeds) {
            progress.satisfy(need, now);
          }
          progress.processedThrough = now;
        }
        final saved = <String, dynamic>{
          ...raw,
          ...progress.toJson(),
          'calendarOrdinal': ordinal,
          'calendarOriginDay': origin,
          'calendarOriginOrdinal': readIntValue(clock['calendarOriginOrdinal']),
        };
        worldNeedsCampaigns[worldNeedsCampaignKey] = saved;
        final afterAsh = worldNeedsEffectiveAsh();
        if (progress.episodes.length > previousEpisodes) {
          aggiungiLog(
            '[BISOGNI] Nuove penalità dal tempo della campagna: '
            'Fame ${progress.daysWithout('food', now)}, '
            'Sete ${progress.daysWithout('water', now)}, '
            'Sonno ${progress.daysWithout('sleep', now)} giorni. '
            'Cenere totale $afterAsh; soddisfa i relativi bisogni per rimuoverle.',
          );
        }
        if (delta > 0 ||
            previousDay != day ||
            progress.episodes.length != previousEpisodes) {
          dirtyTags.add(tag);
        }
        if (afterAsh > beforeAsh) {
          final message = controllaSvenimentoPerCenere(beforeAsh, afterAsh);
          if (message.isNotEmpty) aggiungiLog(message);
        }
        syncWorldNeedsLegacyCounters(now);
        invalidateDerivedDataCaches();
      });
    }
    salvaSchedaCorrenteInMemoria();
    for (final tag in dirtyTags) {
      final index = localSheetIndexForOculumTag(tag);
      if (index >= 0) {
        sendRealtimeSheetToStaffAt(
          index,
          force: true,
          ensureMasterReceipt: true,
        );
      }
    }
  }

  void advanceWorldInventoryDays(int previousDay, int delta) {
    // Count actual elapsed days, not merely the modulo-369 final date. Keep
    // the old obtained date and accumulated age, including custom PUT > 369.
    for (final item in inventario) {
      if (item.putrefazioneSessioni <= 0 || itemGiaPutrefatto(item)) continue;
      final age = max(0, item.sessioniSegnate);
      if (item.putrefazioneGiornoInizio <= 0) {
        item.putrefazioneGiornoInizio = previousDay;
      }
      item.sessioniSegnate = min(item.putrefazioneSessioni, age + delta);
      if (item.sessioniSegnate >= item.putrefazioneSessioni) {
        trasformaItemInPutrefatto(item);
      }
    }
    unisciItemPutrefatti();
  }

  void syncWorldNeedsLegacyCounters(int now) {
    if (!automaticWorldNeedsEnabled) return;
    final progress = personalNeedsProgress(now: now);
    sessioniSenzaBisogniController.text =
        '${progress.daysWithout('sleep', now)}';
    giorniSenzaCiboAcquaController.text =
        '${max(progress.daysWithout('food', now), progress.daysWithout('water', now))}';
  }

  void satisfyPersonalNeed(String need, {int? atSeconds, bool publish = true}) {
    if (!oculumPersonalNeeds.contains(need) || !automaticWorldNeedsEnabled) {
      return;
    }
    if (schedaCorrente < 0 ||
        schedaCorrente >= schedePersonaggio.length ||
        schedePersonaggio[schedaCorrente]['realtimeSharedSheet'] == true ||
        !controlsOnlineCombatSheet(sheetTagAt(schedaCorrente))) {
      return;
    }
    final now = atSeconds ?? worldClockSeconds;
    final raw = worldNeedsData;
    final progress = personalNeedsProgress(now: now);
    // Do not assign pending deprivation and immediately erase it when a user
    // explicitly satisfies the need at this very instant.
    progress.satisfy(need, now);
    worldNeedsCampaigns[worldNeedsCampaignKey] = {...raw, ...progress.toJson()};
    impostaCenereControllata(
      leggiNumero(cenereController),
      controllaSvenimento: false,
    );
    syncWorldNeedsLegacyCounters(now);
    invalidateDerivedDataCaches();
    notifyActiveSheetSummaryChanged();
    if (publish) {
      programmaSalvataggio();
      sendRealtimeActiveSheetToStaff();
    }
  }

  void satisfyConsumedFoodNeeds(Map food) {
    final explicit = food['satisfiesNeeds'];
    final needs = explicit is List ? explicit.map((v) => '$v') : <String>[];
    for (final need in needs.where(oculumPersonalNeeds.contains)) {
      // Consumables cannot silently count as sleep.
      if (need != 'sleep') satisfyPersonalNeed(need);
    }
  }

  /// New UI path: no resources, Open counters or recovery before confirmation.
  void requestWorldPartyRest({
    required bool longRest,
    bool effectsAlreadyApplied = false,
  }) {
    final tag = sheetTagAt(schedaCorrente);
    if (tag.isEmpty) return;
    if (realtimeService?.isConnected != true && !worldClockAuthority) {
      // Offline player-only legacy saves have no Master transport. Preserve
      // their existing local recovery API without claiming a campaign advance.
      if (!effectsAlreadyApplied) {
        if (longRest) {
          riposoLungo(advanceWorldClock: false);
        } else {
          riposoBreve(advanceWorldClock: false);
        }
      }
      return;
    }
    final payload = permissionEnvelope({
      'id':
          'world-rest:$tag:$longRest:${DateTime.now().microsecondsSinceEpoch}:'
          '${Random.secure().nextInt(1 << 30)}',
      'worldClockCommand': 'rest_request',
      'longRest': longRest,
      'restTargetTag': tag,
      'effectsAlreadyApplied': effectsAlreadyApplied,
    });
    if (worldClockAuthority) {
      receiveWorldClockControl(payload);
      risultato = 'Riposo richiesto: conferma una volta la durata del party.';
      if (mounted) setState(() {});
    } else if (realtimeService?.isConnected == true) {
      final data = worldNeedsData;
      final pending = (data['restRequests'] as List? ?? [])
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
      final existing = pending
          .where(
            (row) =>
                row['longRest'] == longRest &&
                row['scope'] == permissionScope &&
                row['campaignId'] == permissionCampaignId,
          )
          .firstOrNull;
      if (existing == null) {
        pending.add(payload);
      }
      worldNeedsCampaigns[worldNeedsCampaignKey] = {
        ...data,
        'restRequests': pending,
      };
      programmaSalvataggio();
      unawaited(flushWorldRestRequests());
      risultato = 'Riposo richiesto al Master; recuperi dopo la conferma.';
      if (mounted) setState(() {});
    }
  }

  Future<void> flushWorldRestRequests() async {
    final service = realtimeService;
    final campaign = worldNeedsCampaignKey, scope = permissionScope;
    if (service?.isConnected != true || worldClockAuthority) return;
    final packets = <Map<String, dynamic>>[];
    for (var i = 0; i < schedePersonaggio.length; i++) {
      if (schedePersonaggio[i]['realtimeSharedSheet'] == true) continue;
      final tag = sheetTagAt(i);
      faunaForOwnedSheet(tag, () {
        for (final row
            in (worldNeedsData['restRequests'] as List? ?? [])
                .whereType<Map>()) {
          if (row['scope'] != scope ||
              row['campaignId'] != permissionCampaignId) {
            continue;
          }
          packets.add(permissionEnvelope(Map<String, dynamic>.from(row)));
        }
      });
    }
    for (final packet in packets) {
      if (realtimeService != service ||
          service?.isConnected != true ||
          worldNeedsCampaignKey != campaign ||
          permissionScope != scope) {
        return;
      }
      await sendWorldClockRequest(packet);
    }
  }

  void applyConfirmedWorldRestGrants(Map clock) {
    final rests = clock['restGrants'];
    if (rests is! List) return;
    final ordered = rests.whereType<Map>().toList()
      ..sort(
        (a, b) => readIntValue(
          a['endSeconds'],
        ).compareTo(readIntValue(b['endSeconds'])),
      );
    for (final raw in ordered) {
      if (raw['status'] != 'confirmed') continue;
      final id = '${raw['id'] ?? ''}';
      final minutes = readIntValue(raw['minutes']);
      final longRest = raw['longRest'] == true;
      if (id.isEmpty || minutes < (longRest ? 90 : 30) || minutes > 30 * 540) {
        continue;
      }
      final alreadyApplied = (raw['effectsAlreadyAppliedTags'] as List? ?? [])
          .map((v) => normalizeOculumFriendTag('$v'))
          .toSet();
      for (final target in raw['requestedBy'] as List? ?? []) {
        final tag = '$target';
        if (!controlsOnlineCombatSheet(tag)) continue;
        final index = localSheetIndexForOculumTag(tag);
        if (index < 0 ||
            schedePersonaggio[index]['realtimeSharedSheet'] == true) {
          continue;
        }
        faunaForOwnedSheet(tag, () {
          final data = worldNeedsData;
          final receipts = (data['restReceipts'] as List? ?? [])
              .map((v) => '$v')
              .toSet();
          if (receipts.contains(id)) return;
          final backup =
              jsonDecode(jsonEncode(statoCorrenteJson()))
                  as Map<String, dynamic>;
          final globals = catturaImpostazioniGlobali();
          receipts.add(id);
          final requestIds = (raw['requestIds'] as List? ?? [id])
              .map((v) => '$v')
              .toSet();
          worldNeedsCampaigns[worldNeedsCampaignKey] = {
            ...worldNeedsData,
            'restReceipts': receipts.toList(),
            'restRequests': [
              for (final request
                  in (worldNeedsData['restRequests'] as List? ?? [])
                      .whereType<Map>())
                if (!requestIds.contains('${request['id']}')) request,
            ],
          };
          try {
            if (!alreadyApplied.contains(normalizeOculumFriendTag(tag))) {
              if (longRest) {
                // Distinct receipts can arrive together on reconnect; their
                // durable claims, not the UI debounce, prevent duplicate use.
                longRestInProgress = false;
                satisfyPersonalNeed(
                  'sleep',
                  atSeconds: readIntValue(raw['endSeconds']),
                  publish: false,
                );
                riposoLungo(
                  advanceWorldClock: false,
                  sleepMinutes: minutes,
                  fulfillSleepNeed: false,
                );
              } else {
                riposoBreve(advanceWorldClock: false);
              }
            }
          } catch (_) {
            schedePersonaggio[schedaCorrente] = backup;
            caricaStatoDaJson(backup);
            ripristinaImpostazioniGlobali(globals);
            invalidateDerivedDataCaches();
            programmaSalvataggio();
            aggiungiLog(
              '[RIPOSO] Recupero non applicato: ricevuta conservata '
              'dal Master per un nuovo tentativo.',
            );
            return;
          }
          aggiungiLog(
            '[RIPOSO] ${longRest ? 'Lungo' : 'Breve'} '
            'confermato: $minutes minuti, un solo evento di riposo.',
          );
          programmaSalvataggio();
        });
        sendRealtimeSheetToStaffAt(
          index,
          force: true,
          ensureMasterReceipt: true,
        );
      }
    }
  }

  bool rebaseWorldCalendar(int day) {
    if (!worldClockAuthority) return false;
    final clock = worldClockProgress;
    clock.calendarOriginDay = normalizzaGiornoOculum(day);
    clock.calendarOriginOrdinal = clock.seconds ~/ oculumWorldDaySeconds;
    clock.revision++;
    storeWorldClock(clock);
    return true;
  }

  bool advanceWorldTime({
    required String receipt,
    required int seconds,
    required String campaignId,
  }) {
    if (!worldClockAuthority ||
        campaignId != activeCampaignId ||
        receipt.isEmpty ||
        receipt.length > 240 ||
        seconds <= 0 ||
        seconds > 30 * oculumWorldDaySeconds) {
      return false;
    }
    final clock = worldClockProgress;
    prepareOwnedWorldTimeAdvance(clock);
    if (!clock.advance(seconds, 'wait:$receipt')) return false;
    // Waiting is not travel and does not grant any rest, healing or Open tick.
    storeWorldClock(clock);
    aggiungiLog('[TEMPO] ${oculumWorldDuration(seconds)} trascorse nel party.');
    return true;
  }

  Future<void> showWorldTimeAdvanceDialog() async {
    if (!worldClockAuthority) return;
    final campaign = activeCampaignId;
    final scope = permissionScope;
    final hours = TextEditingController(text: '0');
    final minutes = TextEditingController(text: '30');
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Fai passare tempo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Avanza soltanto il tempo della campagna. '
              'Non concede riposi o recuperi.',
            ),
            TextField(
              controller: hours,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Ore Oculum'),
            ),
            TextField(
              controller: minutes,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Minuti'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Conferma tempo del party'),
          ),
        ],
      ),
    );
    final h = int.tryParse(hours.text), m = int.tryParse(minutes.text);
    hours.dispose();
    minutes.dispose();
    if (accepted != true ||
        !mounted ||
        campaign != activeCampaignId ||
        scope != permissionScope ||
        h == null ||
        m == null ||
        h < 0 ||
        h > 30 * 9 ||
        m < 0 ||
        m > 59) {
      return;
    }
    advanceWorldTime(
      receipt:
          'manual:$campaign:'
          '${DateTime.now().microsecondsSinceEpoch}',
      seconds: h * 3600 + m * 60,
      campaignId: campaign,
    );
  }

  Widget personalNeedsSummary() {
    final progress = personalNeedsProgress();
    return Text(
      automaticWorldNeedsEnabled
          ? 'Fame ${progress.daysWithout('food', worldClockSeconds)} giorni · '
                'Sete ${progress.daysWithout('water', worldClockSeconds)} · '
                'Sonno ${progress.daysWithout('sleep', worldClockSeconds)} · '
                'Cenere totale ${worldNeedsEffectiveAsh()} '
                '(+${progress.ash} dai bisogni)'
          : 'Bisogni automatici esenti per questa scheda; '
                'impostazione modificabile nel JSON.',
    );
  }
}
