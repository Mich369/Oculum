part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member, unused_element

extension _OculumVttStateIntegration on _OculumHomePageState {
  String vttLocalRoleKey() {
    if (modalitaMaster) return 'master';
    if (sonoCoMaster) return 'co_master';
    return 'player';
  }

  bool vttHasPermission(String permission) {
    if (modalitaMaster) return true;
    final role = vttLocalRoleKey();
    final remotePermissions = realtimeVisibleVttSnapshot['permissions'];
    if (remotePermissions is Map && remotePermissions[role] is Map) {
      final rolePermissions = remotePermissions[role] as Map;
      if (rolePermissions.containsKey(permission)) {
        return _oculumVttBool(rolePermissions[permission]);
      }
    }
    return vttState.permissions[role]?[permission] ?? false;
  }

  bool get vttCanManageMap => vttHasPermission('map');
  bool get vttCanManageTokens => vttHasPermission('tokens');
  bool get vttCanOpenDoors => vttHasPermission('doors');
  bool get vttCanPing => vttHasPermission('ping');
  bool get vttCanUseTools => vttHasPermission('tools');

  bool vttCanSelectTool(OculumVttTool tool) {
    if (!vttHasPermission('view')) return false;
    return switch (tool) {
      OculumVttTool.pan || OculumVttTool.select => true,
      OculumVttTool.ruler => vttCanUseTools,
      OculumVttTool.ping => vttCanPing,
      _ => vttCanManageMap,
    };
  }

  OculumVttScene get activeVttScene => vttState.activeScene;

  void ensureVttStateReady() {
    vttState.normalize();
    applyVttSceneToLegacyMapState(activeVttScene);
  }

  Map<String, dynamic> captureVttStateJson() {
    syncActiveVttSceneFromLegacyMapState();
    return vttState.toJson();
  }

  void restoreVttStateFromJson(dynamic raw, {Map<String, dynamic>? legacy}) {
    vttState = OculumVttState.fromJson(raw, legacy: legacy);
    applyVttSceneToLegacyMapState(vttState.activeScene);
    vttUndoHistory.clear();
    vttRedoHistory.clear();
    vttDraftPoints.clear();
    vttMeasurePoints.clear();
    vttPointerStart = null;
    vttSelectedElementId = '';
    vttSelectedTokenIds.clear();
    vttCanvasRevision.value++;
  }

  void syncActiveVttSceneFromLegacyMapState() {
    vttState.normalize();
    final scene = activeVttScene;
    scene.imagePath = mapImagePath;
    scene.imageName = mapImageName;
    scene.mapUrl = mapUrlController.text;
    scene.notes = mapNotesController.text;
    scene.widthMeters = mapWidthMetersValue();
    scene.heightMeters = mapHeightMetersValue();
    scene.tokens = localMapTokens
        .map((token) => _oculumVttDeepMap(token))
        .toList(growable: true);
    scene.sharedData.addAll(<String, dynamic>{
      'mapMode': mapMode,
      'mapSaveSession': mapSaveSession,
      'mapSessionChoiceAsked': mapSessionChoiceAsked,
      'mapPlayersCanManageOwnToken': mapPlayersCanManageOwnToken,
      'mapTokenSize': mapTokenSizeController.text,
      'mapFreeTokenMovement': mapFreeTokenMovementController.text,
      'mapTokenSheetIndex': mapTokenSheetIndex,
    });
  }

  void applyVttSceneToLegacyMapState(OculumVttScene scene) {
    mapImagePath = scene.imagePath;
    mapImageName = scene.imageName;
    mapUrlController.text = scene.mapUrl;
    mapNotesController.text = scene.notes;
    mapWidthMetersController.text = _oculumVttCompactNumber(scene.widthMeters);
    mapHeightMetersController.text = _oculumVttCompactNumber(
      scene.heightMeters,
    );
    final shared = scene.sharedData;
    mapMode =
        '${shared['mapMode'] ?? ''}' == 'online' ||
            (scene.imagePath.isEmpty && scene.mapUrl.isNotEmpty)
        ? 'online'
        : 'image';
    mapSaveSession = _oculumVttBool(shared['mapSaveSession']);
    mapSessionChoiceAsked = _oculumVttBool(shared['mapSessionChoiceAsked']);
    mapPlayersCanManageOwnToken = _oculumVttBool(
      shared['mapPlayersCanManageOwnToken'],
      true,
    );
    mapTokenSizeController.text =
        '${shared['mapTokenSize'] ?? mapTokenSizeController.text}';
    mapFreeTokenMovementController.text =
        '${shared['mapFreeTokenMovement'] ?? mapFreeTokenMovementController.text}';
    mapTokenSheetIndex = _oculumVttInt(shared['mapTokenSheetIndex']);
    localMapTokens
      ..clear()
      ..addAll(scene.tokens.map(_oculumVttDeepMap));
    mapTransformationController.value = Matrix4.identity();
  }

  String _oculumVttCompactNumber(double value) {
    if (value == value.roundToDouble()) return value.round().toString();
    return value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  }

  void resetVttForNewCampaign() {
    vttState = OculumVttState.empty();
    applyVttSceneToLegacyMapState(vttState.activeScene);
    vttUndoHistory.clear();
    vttRedoHistory.clear();
    vttSelectedTokenIds.clear();
    vttCanvasRevision.value++;
  }

  void activateVttScene(
    String sceneId, {
    bool saveCurrent = true,
    bool notify = true,
  }) {
    if (saveCurrent && vttState.scenes.isNotEmpty) {
      syncActiveVttSceneFromLegacyMapState();
    }
    final scene = vttState.scenes.firstWhere(
      (candidate) => candidate.id == sceneId,
      orElse: () => vttState.activeScene,
    );
    vttState.activeSceneId = scene.id;
    applyVttSceneToLegacyMapState(scene);
    vttUndoHistory.clear();
    vttRedoHistory.clear();
    vttDraftPoints.clear();
    vttMeasurePoints.clear();
    vttPointerStart = null;
    vttSelectedElementId = '';
    vttSelectedTokenIds.clear();
    vttCanvasRevision.value++;
    if (notify && mounted) {
      setState(() {
        risultato = t(
          'Scena attiva: ${scene.name}.',
          'Active scene: ${scene.name}.',
        );
      });
      programmaSalvataggio(invalidateCaches: false);
      scheduleVttRealtimePublish(includeAsset: true);
    }
  }

  void createVttScene({
    required String name,
    String? collectionName,
    bool duplicateActive = false,
  }) {
    if (!vttCanManageMap) return;
    syncActiveVttSceneFromLegacyMapState();
    final active = activeVttScene;
    final safeName = name.trim().isEmpty
        ? t('Nuova scena', 'New scene')
        : name.trim();
    final scene = duplicateActive
        ? active.duplicate(newName: safeName)
        : OculumVttScene(
            id: oculumVttGenerateId('scene'),
            name: safeName,
            collectionId: active.collectionId,
            collectionName: collectionName?.trim().isNotEmpty == true
                ? collectionName!.trim()
                : active.collectionName,
            sortOrder: vttState.scenes.length,
            gridType: active.gridType,
            gridSizePx: active.gridSizePx,
            distancePerCell: active.distancePerCell,
            distanceUnit: active.distanceUnit,
            diagonalRule: active.diagonalRule,
            snapToGrid: active.snapToGrid,
            showCoordinates: active.showCoordinates,
            lockAspectRatio: active.lockAspectRatio,
            widthMeters: active.widthMeters,
            heightMeters: active.heightMeters,
          );
    vttState.scenes.add(scene);
    vttState.normalize();
    activateVttScene(scene.id, saveCurrent: false);
  }

  void archiveVttScene(OculumVttScene scene, bool archived) {
    if (!vttCanManageMap) return;
    scene.archived = archived;
    scene.touch();
    if (archived && scene.id == vttState.activeSceneId) {
      final fallback = vttState.scenes.firstWhere(
        (candidate) => !candidate.archived && candidate.id != scene.id,
        orElse: () => scene,
      );
      activateVttScene(fallback.id, saveCurrent: false);
    } else {
      setState(() {});
      programmaSalvataggio(invalidateCaches: false);
    }
  }

  void deleteVttScene(OculumVttScene scene) {
    if (!vttCanManageMap || vttState.scenes.length <= 1) return;
    final wasActive = scene.id == vttState.activeSceneId;
    vttState.scenes.removeWhere((candidate) => candidate.id == scene.id);
    vttState.normalize();
    if (wasActive) {
      applyVttSceneToLegacyMapState(vttState.activeScene);
    }
    vttUndoHistory.clear();
    vttRedoHistory.clear();
    vttCanvasRevision.value++;
    setState(() {
      risultato = t('Scena eliminata.', 'Scene deleted.');
    });
    programmaSalvataggio(invalidateCaches: false);
    scheduleVttRealtimePublish(includeAsset: wasActive);
  }

  void moveVttScene(OculumVttScene scene, int delta) {
    if (!vttCanManageMap) return;
    final ordered = vttState.scenes.toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final index = ordered.indexWhere((candidate) => candidate.id == scene.id);
    if (index < 0) return;
    final target = (index + delta).clamp(0, ordered.length - 1);
    if (target == index) return;
    final moved = ordered.removeAt(index);
    ordered.insert(target, moved);
    for (var i = 0; i < ordered.length; i++) {
      ordered[i].sortOrder = i;
    }
    vttState.scenes = ordered;
    setState(() {});
    programmaSalvataggio(invalidateCaches: false);
  }

  void _pushVttHistory() {
    final snapshot = jsonEncode(activeVttScene.toJson());
    if (vttUndoHistory.isNotEmpty && vttUndoHistory.last == snapshot) return;
    vttUndoHistory.add(snapshot);
    if (vttUndoHistory.length > 40) vttUndoHistory.removeAt(0);
    vttRedoHistory.clear();
  }

  void mutateActiveVttScene(
    void Function(OculumVttScene scene) mutation, {
    bool publish = true,
    bool includeAsset = false,
  }) {
    if (!vttCanManageMap) return;
    _pushVttHistory();
    final scene = activeVttScene;
    mutation(scene);
    scene.touch();
    scene.tokens = localMapTokens
        .map((token) => _oculumVttDeepMap(token))
        .toList(growable: true);
    vttCanvasRevision.value++;
    programmaSalvataggio(
      invalidateCaches: false,
      delay: const Duration(milliseconds: 650),
    );
    if (publish) scheduleVttRealtimePublish(includeAsset: includeAsset);
  }

  void undoVttChange() {
    if (!vttCanManageMap || vttUndoHistory.isEmpty) return;
    final current = jsonEncode(activeVttScene.toJson());
    final previous = vttUndoHistory.removeLast();
    vttRedoHistory.add(current);
    _replaceActiveVttScene(OculumVttScene.fromJson(jsonDecode(previous)));
  }

  void redoVttChange() {
    if (!vttCanManageMap || vttRedoHistory.isEmpty) return;
    final current = jsonEncode(activeVttScene.toJson());
    final next = vttRedoHistory.removeLast();
    vttUndoHistory.add(current);
    _replaceActiveVttScene(OculumVttScene.fromJson(jsonDecode(next)));
  }

  void _replaceActiveVttScene(OculumVttScene replacement) {
    final index = vttState.scenes.indexWhere(
      (scene) => scene.id == vttState.activeSceneId,
    );
    if (index < 0) return;
    replacement.id = vttState.activeSceneId;
    vttState.scenes[index] = replacement;
    applyVttSceneToLegacyMapState(replacement);
    vttCanvasRevision.value++;
    setState(() {});
    programmaSalvataggio(invalidateCaches: false);
    scheduleVttRealtimePublish();
  }

  void notifyVttCanvasChanged({bool save = false, bool publish = false}) {
    if (save || publish) {
      vttCanvasRevision.value++;
    } else if (!vttCanvasFrameRefreshScheduled) {
      vttCanvasFrameRefreshScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        vttCanvasFrameRefreshScheduled = false;
        if (!mounted) return;
        vttCanvasRevision.value++;
      });
      WidgetsBinding.instance.scheduleFrame();
    }
    if (save) {
      activeVttScene.tokens = localMapTokens
          .map((token) => _oculumVttDeepMap(token))
          .toList(growable: true);
      activeVttScene.touch();
      programmaSalvataggio(
        invalidateCaches: false,
        delay: const Duration(milliseconds: 500),
      );
    }
    if (publish) scheduleVttRealtimePublish();
  }

  void markVttLegacyMapChanged({bool includeAsset = false}) {
    syncActiveVttSceneFromLegacyMapState();
    activeVttScene.touch();
    vttCanvasRevision.value++;
    scheduleVttRealtimePublish(includeAsset: includeAsset);
  }

  bool vttModuleEnabled(String key) {
    if (vttShowingRemoteScene) {
      final remoteModules = realtimeVisibleVttSnapshot['modules'];
      if (remoteModules is Map && remoteModules.containsKey(key)) {
        return _oculumVttBool(remoteModules[key]);
      }
    }
    return vttState.modules[key] ?? false;
  }

  void setVttModuleEnabled(String key, bool enabled) {
    if (!vttCanManageMap) return;
    setState(() => vttState.modules[key] = enabled);
    vttCanvasRevision.value++;
    programmaSalvataggio(invalidateCaches: false);
    scheduleVttRealtimePublish();
  }

  void scheduleVttRealtimePublish({bool includeAsset = false}) {
    if (!modalitaMaster || realtimeService?.isConnected != true) return;
    vttRealtimeAssetPending = vttRealtimeAssetPending || includeAsset;
    vttRealtimeDebounceTimer?.cancel();
    vttRealtimeDebounceTimer = Timer(const Duration(milliseconds: 420), () {
      vttRealtimeDebounceTimer = null;
      final sendAsset = vttRealtimeAssetPending;
      vttRealtimeAssetPending = false;
      unawaited(publishActiveVttScene(includeAsset: sendAsset));
    });
  }

  bool _vttPayloadTargetsLocalPlayer(Map<String, dynamic> payload) {
    final target = normalizeOculumFriendTag('${payload['targetTag'] ?? ''}');
    if (target.isEmpty) return true;
    return localOculumTags()
        .map((tag) => normalizeOculumFriendTag(tag))
        .contains(target);
  }

  Map<String, dynamic> buildSharedVttSceneSnapshot({String targetTag = ''}) {
    syncActiveVttSceneFromLegacyMapState();
    final scene = activeVttScene;
    if (!scene.visibleToPlayers) {
      return <String, dynamic>{
        'version': oculumVttSaveVersion,
        'closed': true,
        'sceneId': scene.id,
        'sentAt': DateTime.now().toIso8601String(),
      };
    }
    final publicScene = scene.toJson(includePrivate: false);
    final partyFog = scene.fogLayers['party'] ?? const <Map<String, dynamic>>[];
    final targetKey = normalizeOculumFriendTag(targetTag);
    final playerFog = targetKey.isEmpty
        ? const <Map<String, dynamic>>[]
        : scene.fogLayers[targetKey] ?? const <Map<String, dynamic>>[];
    publicScene['fogLayers'] = <String, dynamic>{
      'party': <Map<String, dynamic>>[
        ...partyFog.map(_oculumVttDeepMap),
        ...playerFog.map(_oculumVttDeepMap),
      ],
    };
    publicScene['tokens'] = (publicScene['tokens'] as List)
        .whereType<Map>()
        .map((raw) {
          final token = Map<String, dynamic>.from(raw);
          for (final key in token.keys.toList()) {
            final lower = key.toLowerCase();
            if (lower.contains('private') || lower == 'masterNotes') {
              token.remove(key);
            }
          }
          return token;
        })
        .toList(growable: false);
    return <String, dynamic>{
      'version': oculumVttSaveVersion,
      'closed': false,
      'scene': publicScene,
      'modules': vttState.modules,
      'permissions': vttState.permissions,
      'graphicsQuality': vttState.graphicsQuality,
      'campaignId': activeCampaignId,
      'campaignName': activeCampaignName(),
      'sentAt': DateTime.now().toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> _prepareActiveVttAsset() async {
    final scene = activeVttScene;
    final embedded = scene.imageDataBase64.trim();
    if (embedded.isNotEmpty) {
      final bytes = decodedBase64ImageCached(embedded);
      if (bytes != null) {
        return <String, dynamic>{
          'assetId':
              'vtt_${bytes.length}_${_oculumVttStableBytesHash(bytes).toRadixString(16).padLeft(8, '0')}',
          'bytes': bytes,
          'base64': embedded,
          'mime': 'image/jpeg',
          'width': 0,
          'height': 0,
        };
      }
      scene.imageDataBase64 = '';
    }
    if (scene.mapUrl.trim().isNotEmpty && scene.imagePath.trim().isEmpty) {
      return <String, dynamic>{};
    }
    if (kIsWeb) return <String, dynamic>{};
    final path = scene.imagePath.trim();
    if (path.isEmpty) return <String, dynamic>{};
    final file = File(path);
    if (!await file.exists()) return <String, dynamic>{};
    final bytes = await file.readAsBytes();
    final quality = switch (vttState.graphicsQuality) {
      'low' => 62,
      'high' => 84,
      _ => 74,
    };
    final maxDimension = switch (vttState.graphicsQuality) {
      'low' => 1280,
      'high' => 2560,
      _ => 1920,
    };
    if (kIsWeb) {
      return prepareOculumVttSharedImage(<String, dynamic>{
        'bytes': bytes,
        'quality': quality,
        'maxDimension': maxDimension,
      });
    }
    return compute(prepareOculumVttSharedImage, <String, dynamic>{
      'bytes': bytes,
      'quality': quality,
      'maxDimension': maxDimension,
    }, debugLabel: 'oculum-vtt-map-share');
  }

  Future<Map<String, dynamic>> prepareVttImportedImage(
    Uint8List bytes, {
    int maxDimension = 1920,
    int quality = 74,
  }) async {
    final input = <String, dynamic>{
      'bytes': bytes,
      'quality': quality,
      'maxDimension': maxDimension,
    };
    if (kIsWeb) {
      await Future<void>.delayed(Duration.zero);
      return prepareOculumVttSharedImage(input);
    }
    return compute(
      prepareOculumVttSharedImage,
      input,
      debugLabel: 'oculum-vtt-map-import',
    );
  }

  Future<void> publishActiveVttScene({
    bool includeAsset = false,
    String targetTag = '',
  }) async {
    final service = realtimeService;
    if (service?.isConnected != true || !modalitaMaster) return;
    if (vttPublishing) {
      vttRealtimeAssetPending = vttRealtimeAssetPending || includeAsset;
      return;
    }
    vttPublishing = true;
    try {
      var assetId = '';
      var chunks = const <String>[];
      var assetMime = '';
      var assetWidth = 0;
      var assetHeight = 0;
      if (includeAsset) {
        final prepared = await _prepareActiveVttAsset();
        final encoded = '${prepared['base64'] ?? ''}';
        if (encoded.isNotEmpty) {
          assetId = '${prepared['assetId'] ?? ''}';
          assetMime = '${prepared['mime'] ?? 'image/jpeg'}';
          assetWidth = _oculumVttInt(prepared['width']);
          assetHeight = _oculumVttInt(prepared['height']);
          chunks = <String>[
            for (var offset = 0; offset < encoded.length; offset += 12000)
              encoded.substring(offset, min(offset + 12000, encoded.length)),
          ];
        }
      }
      if (!mounted ||
          realtimeService != service ||
          service?.isConnected != true) {
        return;
      }
      final snapshot = buildSharedVttSceneSnapshot(targetTag: targetTag);
      snapshot['assetMime'] = assetMime;
      snapshot['assetWidth'] = assetWidth;
      snapshot['assetHeight'] = assetHeight;
      await service!.sendVttSceneSnapshot(
        snapshot: snapshot,
        campaignId: activeCampaignId,
        campaignName: activeCampaignName(),
        assetId: assetId,
        assetChunkCount: chunks.length,
        targetTag: targetTag,
      );
      for (var i = 0; i < chunks.length; i++) {
        if (!mounted ||
            realtimeService != service ||
            service.isConnected != true) {
          break;
        }
        await service.sendVttAssetChunk(
          assetId: assetId,
          chunkIndex: i,
          chunkCount: chunks.length,
          data: chunks[i],
          targetTag: targetTag,
        );
        if (i % 8 == 7) {
          await Future<void>.delayed(const Duration(milliseconds: 12));
        }
      }
    } catch (error) {
      if (mounted) {
        risultato = t(
          'Condivisione scena non completata.',
          'Scene sharing did not complete.',
        );
        aggiungiLog('$risultato ($error)');
      }
    } finally {
      vttPublishing = false;
      if (vttRealtimeAssetPending && mounted) {
        scheduleVttRealtimePublish(includeAsset: true);
      }
    }
  }

  void requestRealtimeVttScene() {
    final service = realtimeService;
    if (service?.isConnected != true || modalitaMaster) return;
    unawaited(
      service!.requestVttScene(requesterTag: currentLocalMapOwnerTag()),
    );
  }

  void receiveRealtimeVttSceneRequest(Map<String, dynamic> payload) {
    if (!modalitaMaster || realtimeService?.isConnected != true) return;
    final requester = '${payload['requesterTag'] ?? ''}'.trim();
    unawaited(publishActiveVttScene(includeAsset: true, targetTag: requester));
  }

  void receiveRealtimeVttSceneSnapshot(Map<String, dynamic> payload) {
    if (modalitaMaster || '${payload['senderRole'] ?? ''}' != 'master') return;
    if (!_vttPayloadTargetsLocalPlayer(payload)) return;
    final snapshotRaw = payload['snapshot'];
    if (snapshotRaw is! Map) return;
    final snapshot = _oculumVttDeepMap(snapshotRaw);
    if (_oculumVttBool(snapshot['closed'])) {
      realtimeVisibleVttSnapshot = <String, dynamic>{};
      realtimeVisibleVttScene = null;
      realtimeVisibleVttImageBytes = null;
      realtimeVisibleVttAssetId = '';
      realtimeVttAssetProgress = 0;
      vttCanvasRevision.value++;
      return;
    }
    realtimeVisibleVttSnapshot = snapshot;
    final sceneRaw = snapshot['scene'];
    realtimeVisibleVttScene = sceneRaw is Map
        ? OculumVttScene.fromJson(sceneRaw)
        : null;
    final assetId = '${payload['assetId'] ?? ''}';
    final chunkCount = _oculumVttInt(payload['assetChunkCount']);
    if (assetId.isEmpty || chunkCount <= 0) {
      if (assetId != realtimeVisibleVttAssetId) {
        realtimeVisibleVttImageBytes = null;
      }
      realtimeVisibleVttAssetId = assetId;
      realtimeVttAssetProgress = assetId.isEmpty ? 0 : 1;
    } else {
      realtimeVisibleVttAssetId = assetId;
      realtimeVisibleVttImageBytes = null;
      realtimeVttAssetProgress = 0;
      realtimeVttAssetAssemblers[assetId] = OculumVttAssetAssembler(
        assetId: assetId,
        chunkCount: chunkCount,
      );
    }
    vttCanvasRevision.value++;
  }

  String _vttRealtimeRoleForSender(String senderTag) {
    final normalized = normalizeOculumFriendTag(senderTag);
    if (realtimeCoMasterTags.contains(normalized)) return 'co_master';
    return 'player';
  }

  bool _vttRealtimeCampaignMatches(Map<String, dynamic> payload) {
    final campaignId = '${payload['campaignId'] ?? ''}'.trim();
    return campaignId.isEmpty || campaignId == activeCampaignId;
  }

  Future<void> sendRealtimeVttTokenPosition(Map<String, dynamic> token) async {
    final service = realtimeService;
    final scene = realtimeVisibleVttScene;
    if (service?.isConnected != true ||
        modalitaMaster ||
        scene == null ||
        !vttCanManageTokens) {
      return;
    }
    final tokenId = '${token['id'] ?? ''}'.trim();
    final ownerTag = normalizeOculumFriendTag(
      '${token['ownerTag'] ?? token['sheetTag'] ?? ''}',
    );
    final localTags = localOculumTags().map(normalizeOculumFriendTag).toSet();
    if (tokenId.isEmpty || ownerTag.isEmpty || !localTags.contains(ownerTag)) {
      return;
    }
    await service!.sendVttTokenPatch(
      campaignId:
          '${realtimeVisibleVttSnapshot['campaignId'] ?? activeCampaignId}',
      sceneId: scene.id,
      tokenId: tokenId,
      senderRole: vttLocalRoleKey(),
      senderTag: ownerTag,
      x: localMapTokenAxis(token, 'x'),
      y: localMapTokenAxis(token, 'y'),
      movementUsedMeters: localMapTokenMovementUsed(token),
    );
  }

  Future<void> sendAuthoritativeVttTokenPosition(
    Map<String, dynamic> token,
  ) async {
    final service = realtimeService;
    if (service?.isConnected != true || !modalitaMaster) return;
    final tokenId = '${token['id'] ?? ''}'.trim();
    if (tokenId.isEmpty) return;
    await service!.sendVttTokenPatch(
      campaignId: activeCampaignId,
      sceneId: activeVttScene.id,
      tokenId: tokenId,
      senderRole: 'master',
      senderTag: currentLocalMapOwnerTag(),
      x: localMapTokenAxis(token, 'x'),
      y: localMapTokenAxis(token, 'y'),
      movementUsedMeters: localMapTokenMovementUsed(token),
    );
  }

  void receiveRealtimeVttTokenPatch(Map<String, dynamic> payload) {
    if (!_vttRealtimeCampaignMatches(payload)) return;
    final senderRole = '${payload['senderRole'] ?? ''}';
    final sceneId = '${payload['sceneId'] ?? ''}';
    final tokenId = '${payload['tokenId'] ?? ''}';
    if (sceneId.isEmpty || tokenId.isEmpty) return;

    if (!modalitaMaster) {
      if (senderRole != 'master') return;
      final scene = realtimeVisibleVttScene;
      if (scene == null || scene.id != sceneId) return;
      final index = scene.tokens.indexWhere(
        (token) => '${token['id'] ?? ''}' == tokenId,
      );
      if (index < 0) return;
      final token = scene.tokens[index];
      token['x'] = _oculumVttDouble(
        payload['x'],
        localMapTokenAxis(token, 'x'),
      ).clamp(0.0, 1.0);
      token['y'] = _oculumVttDouble(
        payload['y'],
        localMapTokenAxis(token, 'y'),
      ).clamp(0.0, 1.0);
      token['movementUsedMeters'] = max(
        0.0,
        _oculumVttDouble(payload['movementUsedMeters']),
      );
      vttCanvasRevision.value++;
      return;
    }

    if (senderRole == 'master' || activeVttScene.id != sceneId) return;
    final senderTag = normalizeOculumFriendTag('${payload['senderTag'] ?? ''}');
    final role = _vttRealtimeRoleForSender(senderTag);
    if (senderTag.isEmpty ||
        !(vttState.permissions[role]?['tokens'] ?? false)) {
      return;
    }
    final index = localMapTokens.indexWhere(
      (token) => '${token['id'] ?? ''}' == tokenId,
    );
    if (index < 0) return;
    final token = localMapTokens[index];
    final ownerTag = normalizeOculumFriendTag(
      '${token['ownerTag'] ?? token['sheetTag'] ?? ''}',
    );
    if (role != 'co_master' && ownerTag != senderTag) return;

    final start = Offset(
      localMapTokenAxis(token, 'x'),
      localMapTokenAxis(token, 'y'),
    );
    final requestedEnd = Offset(
      _oculumVttDouble(payload['x'], start.dx).clamp(0.0, 1.0),
      _oculumVttDouble(payload['y'], start.dy).clamp(0.0, 1.0),
    );
    final mapWidth = max(1.0, activeVttScene.widthMeters);
    final mapHeight = max(1.0, activeVttScene.heightMeters);
    var requested = Offset(
      (requestedEnd.dx - start.dx) * mapWidth,
      (requestedEnd.dy - start.dy) * mapHeight,
    );
    if (vttModuleEnabled('walls_doors') &&
        oculumVttMovementBlocked(start, requestedEnd, activeVttScene.walls)) {
      requested = Offset.zero;
    }
    final allowed = allowedLocalMapTokenDelta(
      token,
      requested,
      mapWidth,
      mapHeight,
    );
    token['x'] = (start.dx + allowed.dx / mapWidth).clamp(0.0, 1.0);
    token['y'] = (start.dy + allowed.dy / mapHeight).clamp(0.0, 1.0);
    notifyVttCanvasChanged(save: true);
    evaluateVttTriggersForToken(token);
    unawaited(sendAuthoritativeVttTokenPosition(token));
  }

  Future<void> sendRealtimeVttDoorState(
    Map<String, dynamic> door,
    bool open,
  ) async {
    final service = realtimeService;
    final scene = realtimeVisibleVttScene;
    if (service?.isConnected != true ||
        modalitaMaster ||
        scene == null ||
        !vttCanOpenDoors) {
      return;
    }
    final doorId = '${door['id'] ?? ''}';
    if (doorId.isEmpty) return;
    await service!.sendVttDoorPatch(
      campaignId:
          '${realtimeVisibleVttSnapshot['campaignId'] ?? activeCampaignId}',
      sceneId: scene.id,
      doorId: doorId,
      senderRole: vttLocalRoleKey(),
      senderTag: currentLocalMapOwnerTag(),
      open: open,
    );
  }

  void receiveRealtimeVttDoorPatch(Map<String, dynamic> payload) {
    if (!_vttRealtimeCampaignMatches(payload)) return;
    final senderRole = '${payload['senderRole'] ?? ''}';
    final sceneId = '${payload['sceneId'] ?? ''}';
    final doorId = '${payload['doorId'] ?? ''}';
    if (sceneId.isEmpty || doorId.isEmpty) return;

    if (!modalitaMaster) {
      if (senderRole != 'master') return;
      final scene = realtimeVisibleVttScene;
      if (scene == null || scene.id != sceneId) return;
      final door = scene.walls.where((wall) => '${wall['id'] ?? ''}' == doorId);
      if (door.isEmpty) return;
      door.first['open'] = _oculumVttBool(payload['open']);
      vttCanvasRevision.value++;
      return;
    }

    if (senderRole == 'master' || activeVttScene.id != sceneId) return;
    final senderTag = normalizeOculumFriendTag('${payload['senderTag'] ?? ''}');
    final role = _vttRealtimeRoleForSender(senderTag);
    if (senderTag.isEmpty || !(vttState.permissions[role]?['doors'] ?? false)) {
      return;
    }
    final door = activeVttScene.walls.where(
      (wall) =>
          '${wall['id'] ?? ''}' == doorId && '${wall['type'] ?? ''}' == 'door',
    );
    if (door.isEmpty) return;
    final open = _oculumVttBool(payload['open']);
    mutateActiveVttScene((scene) => door.first['open'] = open, publish: false);
    unawaited(
      realtimeService?.sendVttDoorPatch(
        campaignId: activeCampaignId,
        sceneId: activeVttScene.id,
        doorId: doorId,
        senderRole: 'master',
        senderTag: currentLocalMapOwnerTag(),
        open: open,
      ),
    );
  }

  Future<void> sendRealtimeVttPing({
    required OculumVttScene scene,
    required Map<String, dynamic> drawing,
    required bool authoritative,
  }) async {
    final service = realtimeService;
    if (service?.isConnected != true) return;
    final points = drawing['points'];
    if (points is! List || points.isEmpty) return;
    final point = OculumVttPoint.fromJson(points.first);
    await service!.sendVttPing(
      campaignId: authoritative
          ? activeCampaignId
          : '${realtimeVisibleVttSnapshot['campaignId'] ?? activeCampaignId}',
      sceneId: scene.id,
      pingId: '${drawing['id'] ?? oculumVttGenerateId('ping')}',
      senderRole: authoritative ? 'master' : vttLocalRoleKey(),
      senderTag: currentLocalMapOwnerTag(),
      x: point.x,
      y: point.y,
      colorArgb: _oculumVttInt(drawing['colorArgb'], tertiaryColor.toARGB32()),
    );
  }

  void receiveRealtimeVttPing(Map<String, dynamic> payload) {
    if (!_vttRealtimeCampaignMatches(payload)) return;
    final senderRole = '${payload['senderRole'] ?? ''}';
    final sceneId = '${payload['sceneId'] ?? ''}';
    final pingId = '${payload['pingId'] ?? ''}';
    if (sceneId.isEmpty || pingId.isEmpty) return;

    if (modalitaMaster) {
      if (senderRole == 'master' || activeVttScene.id != sceneId) return;
      final senderTag = normalizeOculumFriendTag(
        '${payload['senderTag'] ?? ''}',
      );
      final role = _vttRealtimeRoleForSender(senderTag);
      if (senderTag.isEmpty ||
          !(vttState.permissions[role]?['ping'] ?? false)) {
        return;
      }
      final drawing = createVttPingDrawingFromPayload(payload);
      insertVttPingDrawing(activeVttScene, drawing);
      unawaited(
        sendRealtimeVttPing(
          scene: activeVttScene,
          drawing: drawing,
          authoritative: true,
        ),
      );
      return;
    }

    if (senderRole != 'master') return;
    final scene = realtimeVisibleVttScene;
    if (scene == null || scene.id != sceneId) return;
    insertVttPingDrawing(scene, createVttPingDrawingFromPayload(payload));
  }

  void receiveRealtimeVttAssetChunk(Map<String, dynamic> payload) {
    if (modalitaMaster || '${payload['senderRole'] ?? ''}' != 'master') return;
    if (!_vttPayloadTargetsLocalPlayer(payload)) return;
    final assetId = '${payload['assetId'] ?? ''}';
    final chunkCount = _oculumVttInt(payload['chunkCount']);
    final index = _oculumVttInt(payload['chunkIndex'], -1);
    final data = '${payload['data'] ?? ''}';
    if (assetId.isEmpty || chunkCount <= 0 || data.isEmpty) return;
    final assembler = realtimeVttAssetAssemblers.putIfAbsent(
      assetId,
      () => OculumVttAssetAssembler(assetId: assetId, chunkCount: chunkCount),
    );
    if (assembler.chunkCount != chunkCount ||
        !assembler.addChunk(index, data)) {
      return;
    }
    realtimeVttAssetProgress = assembler.progress;
    if (assembler.isComplete) {
      final bytes = assembler.completeBytes();
      realtimeVttAssetAssemblers.remove(assetId);
      if (bytes != null && assetId == realtimeVisibleVttAssetId) {
        realtimeVisibleVttImageBytes = bytes;
        realtimeVttAssetProgress = 1;
      }
    }
    vttCanvasRevision.value++;
  }
}
