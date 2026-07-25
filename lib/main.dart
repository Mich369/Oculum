import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' show FrameTiming;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart' as mobile_webview;
import 'package:webview_windows/webview_windows.dart' as windows_webview;

import 'services/oculum_auth_service.dart';
import 'services/oculum_auth_ui.dart';
import 'services/oculum_cloud_save_service.dart';
import 'services/oculum_realtime_service.dart';
import 'widgets/oculum_bottom_nav.dart';
import 'widgets/oculum_desktop_top_menu.dart';
import 'widgets/oculum_quick_edit_eye.dart';
import 'pages/oculum_dungeon/monster_book.dart';
import 'pages/oculum_dungeon_game.dart';
import 'src/main/oculum_network_probe.dart';
import 'src/main/oculum_web_download_stub.dart'
    if (dart.library.js_interop) 'src/main/oculum_web_download_web.dart';
import 'src/main/oculum_web_save_store_stub.dart'
    if (dart.library.js_interop) 'src/main/oculum_web_save_store_web.dart';

part 'src/main/oculum_app.dart';
part 'src/main/oculum_helpers.dart';
part 'src/main/oculum_models.dart';
part 'src/main/oculum_skill_effects.dart';
part 'src/main/oculum_manual_sections.dart';
part 'src/main/oculum_home_persistence.dart';
part 'src/main/oculum_home_calculations.dart';
part 'src/main/oculum_rune_art.dart';
part 'src/main/oculum_home_force_state.dart';
part 'src/main/oculum_home_death_rules.dart';
part 'src/main/oculum_home_damage_impact.dart';
part 'src/main/oculum_home_image_cache.dart';
part 'src/main/oculum_home_combat_progression.dart';
part 'src/main/oculum_home_resources_rest_titles_data.dart';
part 'src/main/oculum_home_colors_and_base_widgets.dart';
part 'src/main/oculum_home_sheet_page.dart';
part 'src/main/oculum_home_secondary_pages.dart';
part 'src/main/oculum_vtt.dart';
part 'src/main/oculum_vtt_integration.dart';
part 'src/main/oculum_vtt_ui.dart';
part 'src/main/oculum_vtt_panels.dart';
part 'src/main/oculum_home_map_attachments.dart';
part 'src/main/oculum_home_dice_page.dart';
part 'src/main/oculum_p2p_network.dart';
part 'src/main/oculum_realtime_integration.dart';
part 'src/main/oculum_friends.dart';
part 'src/main/oculum_campaigns.dart';
part 'src/main/oculum_story_session_notes.dart';
part 'src/main/oculum_home_recipes.dart';
part 'src/main/oculum_home_titles_inventory_pages.dart';
part 'src/main/oculum_skill_effects_ui.dart';
part 'src/main/oculum_structured_effect_runtime.dart';
part 'src/main/oculum_home_share_content.dart';
part 'src/main/oculum_home_rules_settings_search.dart';
part 'src/main/oculum_home_dialogs_quick_edit.dart';
part 'src/main/oculum_painters.dart';

const String oculumDefaultSupabaseUrl =
    'https://jgpxdlkbuxhriltxezdc.supabase.co';
const String oculumDefaultSupabasePublishableKey =
    'sb_publishable_VXDF3x3izDbZNJ5VWX6RsQ_ZFYXpkPI';
const bool oculumPerformanceHarness = bool.fromEnvironment(
  'OculumPerformanceHarness',
);
const String _oculumSupabaseUrlOverride = String.fromEnvironment(
  'OculumSupabaseUrl',
  defaultValue: '',
);
const String _oculumSupabasePublishableKeyOverride = String.fromEnvironment(
  'OculumSupabasePublishableKey',
  defaultValue: '',
);
const String _oculumSupabaseLegacyAnonKeyOverride = String.fromEnvironment(
  'OculumSupabaseAnonKey',
  defaultValue: '',
);

String get oculumConfiguredSupabaseUrl {
  final override = _oculumSupabaseUrlOverride.trim();
  return override.isEmpty ? oculumDefaultSupabaseUrl : override;
}

String get oculumConfiguredSupabasePublishableKey {
  final publishableOverride = _oculumSupabasePublishableKeyOverride.trim();
  if (publishableOverride.isNotEmpty) return publishableOverride;
  final legacyOverride = _oculumSupabaseLegacyAnonKeyOverride.trim();
  return legacyOverride.isEmpty
      ? oculumDefaultSupabasePublishableKey
      : legacyOverride;
}

bool oculumSupabaseConfigurationIsValid({
  required String url,
  required String publishableKey,
}) {
  final uri = Uri.tryParse(url.trim());
  final validUrl =
      uri != null &&
      uri.scheme == 'https' &&
      uri.host.endsWith('.supabase.co') &&
      uri.userInfo.isEmpty;
  final key = publishableKey.trim();
  final validPublishableKey =
      key.startsWith('sb_publishable_') && key.length > 24;
  final validLegacyAnonKey =
      key.startsWith('eyJ') && key.split('.').length == 3;
  return validUrl && (validPublishableKey || validLegacyAnonKey);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (oculumPerformanceHarness) {
    // Profile harness only: keeps automated stress tests away from real saves.
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues(<String, Object>{});
  }
  if (kProfileMode) {
    _oculumFrameProfiler.start();
  }
  if (kIsWeb) {
    await BrowserContextMenu.disableContextMenu();
  }
  _configureOculumRuntimeCaches();
  await _initializeOculumOptionalStartupServices();
  runApp(const OculumApp());
}

Future<void> _initializeOculumOptionalStartupServices() async {
  try {
    await OculumAuthService.instance.initialize();
  } catch (error, stackTrace) {
    debugPrint(
      'Oculum auth startup unavailable (${error.runtimeType}); '
      'continuing in local mode.\n$stackTrace',
    );
  }
  try {
    await OculumCloudSaveService.instance.initialize();
  } catch (error, stackTrace) {
    debugPrint(
      'Oculum cloud startup unavailable (${error.runtimeType}); '
      'local saves remain available.\n$stackTrace',
    );
  }
}

final _OculumFrameProfiler _oculumFrameProfiler = _OculumFrameProfiler();
final _OculumProgressProfiler _oculumProgressProfiler =
    _OculumProgressProfiler();

void oculumProfileMark(String label) {
  if (!kProfileMode) return;
  _oculumFrameProfiler.mark(label);
}

void oculumProgressProfileCount(String event) {
  if (!kProfileMode) return;
  _oculumProgressProfiler.count(event);
}

class _OculumProgressProfiler {
  String _label = '';
  final Map<String, int> _counts = <String, int>{};

  void begin(String label) {
    _label = label;
    _counts.clear();
    oculumProfileMark(label);
  }

  void count(String event) {
    if (_label.isEmpty) return;
    _counts[event] = (_counts[event] ?? 0) + 1;
  }

  void report() {
    if (_label.isEmpty) return;
    debugPrint('Oculum progress profile [$_label]: $_counts.');
    oculumProfileMark('${_label}_complete');
    _label = '';
    _counts.clear();
  }
}

class _OculumFrameProfiler {
  final List<int> _totalMicros = <int>[];
  int _buildMicros = 0;
  int _rasterMicros = 0;
  int _jankyFrames = 0;
  DateTime _lastReport = DateTime.now();
  String _label = 'startup';
  bool _started = false;

  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addTimingsCallback(_onTimings);
  }

  void mark(String label) {
    _report(force: true);
    _label = label;
    _lastReport = DateTime.now();
  }

  void _onTimings(List<FrameTiming> timings) {
    for (final timing in timings) {
      final total = timing.totalSpan.inMicroseconds;
      _totalMicros.add(total);
      _buildMicros += timing.buildDuration.inMicroseconds;
      _rasterMicros += timing.rasterDuration.inMicroseconds;
      if (total > 16667) _jankyFrames++;
    }

    final overdue =
        DateTime.now().difference(_lastReport) >= const Duration(seconds: 2);
    final severeFrame = timings.any(
      (timing) => timing.totalSpan > const Duration(milliseconds: 32),
    );
    if (overdue || severeFrame || _totalMicros.length >= 120) {
      _report(force: true);
    }
  }

  void _report({required bool force}) {
    if (!force || _totalMicros.isEmpty) return;
    final sorted = List<int>.from(_totalMicros)..sort();
    final count = sorted.length;
    int percentile(double value) {
      final index = ((count - 1) * value).round().clamp(0, count - 1);
      return sorted[index];
    }

    debugPrint(
      'Oculum frame profile [$_label]: frames=$count, '
      'jank=$_jankyFrames, p50=${percentile(0.50)}us, '
      'p95=${percentile(0.95)}us, max=${sorted.last}us, '
      'buildAvg=${_buildMicros ~/ count}us, '
      'rasterAvg=${_rasterMicros ~/ count}us.',
    );
    _totalMicros.clear();
    _buildMicros = 0;
    _rasterMicros = 0;
    _jankyFrames = 0;
    _lastReport = DateTime.now();
  }
}

bool _oculumStartupServicesReady = false;
Future<void>? _oculumStartupServicesFuture;
Future<bool>? _oculumSupabaseInitializationFuture;

enum OculumStartupRole { player, master }

OculumStartupRole oculumStartupRole = OculumStartupRole.player;

const int _oculumDesktopStartupSpritePrecacheLimit = 10;
const int _oculumMobileStartupSpritePrecacheLimit = 5;
const Duration _oculumStartupFrameYield = Duration(milliseconds: 16);
const Duration _oculumStartupNetworkWarmupBudget = Duration(milliseconds: 1400);

Future<void> preloadOculumStartupServices({
  void Function(double progress, String label)? onProgress,
}) {
  if (_oculumStartupServicesReady) {
    onProgress?.call(1, 'Oculum pronto.');
    return Future.value();
  }

  final existing = _oculumStartupServicesFuture;
  if (existing != null) return existing;

  final future = _preloadOculumStartupServices(onProgress: onProgress);
  _oculumStartupServicesFuture = future;
  return future;
}

Future<void> _preloadOculumStartupServices({
  void Function(double progress, String label)? onProgress,
}) async {
  Future<void> step(
    double progress,
    String label,
    FutureOr<void> Function() action,
  ) async {
    onProgress?.call(progress, label);
    await Future<void>.delayed(Duration.zero);
    await action();
    await Future<void>.delayed(_oculumStartupFrameYield);
  }

  await step(0.12, 'Preparazione cache runtime...', () async {
    _configureOculumRuntimeCaches();
  });

  await step(0.34, 'Preparazione salvataggi...', () async {
    await SharedPreferences.getInstance();
  });

  await step(0.56, 'Preparazione testi e pagine...', () async {
    oculumManualSections.length;
    await rootBundle.load('AssetManifest.json').catchError((_) {
      return ByteData(0);
    });
  });

  await step(0.70, 'Catalogo sprite mostri...', () async {
    await oculumStartupMonsterSpriteAssets();
  });

  await step(0.80, 'Connessione online...', () async {
    final warmup = ensureOculumSupabaseInitialized();
    await warmup.timeout(
      _oculumStartupNetworkWarmupBudget,
      onTimeout: () {
        OculumRealtimeService.startupStatus =
            'Supabase in preparazione: l\'app resta reattiva.';
        debugPrint('Supabase startup warmup continues in background.');
        return false;
      },
    );
  });

  await step(0.86, 'Stabilizzazione pagine e label...', () {});

  _oculumStartupServicesReady = true;
  onProgress?.call(0.88, 'Servizi pronti, sprite principali...');
}

Future<bool> ensureOculumSupabaseInitialized() {
  if (OculumRealtimeService.supabaseAvailable) {
    return Future<bool>.value(true);
  }
  final pending = _oculumSupabaseInitializationFuture;
  if (pending != null) return pending;
  final future = _initializeOculumSupabase();
  _oculumSupabaseInitializationFuture = future;
  return future.whenComplete(() {
    _oculumSupabaseInitializationFuture = null;
  });
}

Future<bool> _initializeOculumSupabase() async {
  try {
    try {
      Supabase.instance.client;
      OculumRealtimeService.supabaseAvailable = true;
      OculumRealtimeService.startupStatus = 'Supabase pronto.';
      return true;
    } catch (_) {}

    final supabaseUrl = oculumConfiguredSupabaseUrl;
    final supabasePublishableKey = oculumConfiguredSupabasePublishableKey;

    if (!oculumSupabaseConfigurationIsValid(
      url: supabaseUrl,
      publishableKey: supabasePublishableKey,
    )) {
      OculumRealtimeService.supabaseAvailable = false;
      OculumRealtimeService.startupStatus =
          'Supabase non configurato: l\'app resta in modalità locale.';
      return false;
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabasePublishableKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        autoRefreshToken: true,
        detectSessionInUri: true,
      ),
    ).timeout(const Duration(seconds: 10));
    OculumRealtimeService.supabaseAvailable = true;
    OculumRealtimeService.startupStatus = 'Supabase pronto.';
    await OculumAuthService.instance.initialize(supabaseReady: true);
    return true;
  } catch (error) {
    OculumRealtimeService.supabaseAvailable = false;
    OculumRealtimeService.startupStatus =
        'Supabase offline: l\'app resta locale.';
    debugPrint(
      'Supabase initialization failed (${error.runtimeType}); local mode remains active.',
    );
    return false;
  }
}

String oculumClientPlatformLabel() {
  if (kIsWeb) return 'web';
  return switch (defaultTargetPlatform) {
    TargetPlatform.android => 'android',
    TargetPlatform.iOS => 'ios',
    TargetPlatform.macOS => 'macos',
    TargetPlatform.windows => 'windows',
    TargetPlatform.linux => 'linux',
    TargetPlatform.fuchsia => 'fuchsia',
  };
}

void _configureOculumRuntimeCaches() {
  final imageCache = PaintingBinding.instance.imageCache;
  final desktopRuntime =
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
  imageCache.maximumSize = desktopRuntime ? 240 : 120;
  imageCache.maximumSizeBytes = (desktopRuntime ? 128 : 64) * 1024 * 1024;
}

int oculumImageCacheDimension(
  BuildContext context,
  double logicalPixels, {
  int min = 24,
  int max = 2048,
}) {
  final dpr = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1.0;
  return (logicalPixels * dpr).clamp(min.toDouble(), max.toDouble()).round();
}

List<String>? _oculumStartupMonsterSpriteAssets;

Future<List<String>> oculumStartupMonsterSpriteAssets() async {
  final cached = _oculumStartupMonsterSpriteAssets;
  if (cached != null) return cached;

  try {
    final raw = await rootBundle.loadString('AssetManifest.json');
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      _oculumStartupMonsterSpriteAssets = const <String>[];
      return _oculumStartupMonsterSpriteAssets!;
    }

    final assets =
        decoded.keys
            .map((key) => '$key')
            .where(
              (key) =>
                  key.startsWith(
                    'assets/oculum_dungeon/generated_sprites/enemies/',
                  ) ||
                  key == 'assets/oculum/sprites/Slime.png' ||
                  key == 'assets/oculum/sprites/Crown_of_Bones.png' ||
                  key == 'assets/oculum/sprites/Cultist_of_Purple_Eyes.png' ||
                  key == 'assets/oculum/sprites/Occhio_della_Reliquia.png',
            )
            .where(
              (key) =>
                  key.endsWith('.png') ||
                  key.endsWith('.jpg') ||
                  key.endsWith('.jpeg') ||
                  key.endsWith('.webp'),
            )
            .toList()
          ..sort();
    _oculumStartupMonsterSpriteAssets = List<String>.unmodifiable(assets);
  } catch (error) {
    debugPrint('Monster sprite manifest preload skipped: $error');
    _oculumStartupMonsterSpriteAssets = const <String>[];
  }

  return _oculumStartupMonsterSpriteAssets!;
}

List<String> oculumPrioritizedStartupSpriteAssets(
  List<String> assets, {
  required int limit,
}) {
  if (assets.isEmpty || limit <= 0) return const <String>[];

  const priorityAssets = <String>[
    'assets/oculum/sprites/Slime.png',
    'assets/oculum/sprites/Crown_of_Bones.png',
    'assets/oculum/sprites/Cultist_of_Purple_Eyes.png',
    'assets/oculum/sprites/Occhio_della_Reliquia.png',
    'assets/oculum_dungeon/generated_sprites/enemies/oculiano.png',
    'assets/oculum_dungeon/generated_sprites/enemies/generated_normal_001.png',
    'assets/oculum_dungeon/generated_sprites/enemies/generated_miniboss_001.png',
    'assets/oculum_dungeon/generated_sprites/enemies/generated_boss_001.png',
  ];

  final available = assets.toSet();
  final ordered = <String>[];

  void addIfAvailable(String asset) {
    if (available.contains(asset) && !ordered.contains(asset)) {
      ordered.add(asset);
    }
  }

  for (final asset in priorityAssets) {
    addIfAvailable(asset);
  }

  for (final asset in assets) {
    if (ordered.length >= limit) break;
    final fileName = asset.split('/').last;
    if (fileName.contains('_variant_')) continue;
    addIfAvailable(asset);
  }

  for (final asset in assets) {
    if (ordered.length >= limit) break;
    addIfAvailable(asset);
  }

  return List<String>.unmodifiable(ordered.take(limit));
}

// =====================================================
// PAGINA PRINCIPALE
// =====================================================

class OculumHomePage extends StatefulWidget {
  const OculumHomePage({super.key});

  @override
  State<OculumHomePage> createState() => _OculumHomePageState();
}

class _OculumHomePageState extends State<OculumHomePage>
    with WidgetsBindingObserver {
  static const String saveKey = 'oculum_save_v9_manual_rgb_opacity_clean';

  static const Color defaultPrimaryColor = Color(0xFFE6D8BD);
  static const Color defaultSecondaryColor = Color(0xFF08050B);
  static const Color defaultTertiaryColor = Color(0xFF9E6B2F);
  static const Color defaultEyeUtilityColor = Color(0xFFD8D8D8);
  static const Color defaultBackgroundTopColor = Color(0xFF06070C);
  static const Color defaultBackgroundMidColor = Color(0xFF10121A);
  static const Color defaultBackgroundBottomColor = Color(0xFF07080D);
  static const Color defaultEyePupilGlowColor = Color(0xFFB84A28);
  static const int mapPageIndex = 10;
  static const int settingsPageIndex = 11;
  static const int onlinePageIndex = 12;
  static const int dicePageIndex = 13;
  static const int recipesPageIndex = 14;

  int paginaCorrente = 0;
  int schedaCorrente = 0;
  final Map<String, GlobalKey> _functionNavKeys = <String, GlobalKey>{};
  final Set<int> _preparedPageIndexes = <int>{0};
  int? _lazyPageActivationScheduledFor;
  Timer? _lazyPageActivationTimer;

  GlobalKey _functionNavKey(String id) {
    return _functionNavKeys.putIfAbsent(id, () => GlobalKey());
  }

  Widget functionAnchor(String id, Widget child) {
    return KeyedSubtree(key: _functionNavKey(id), child: child);
  }

  String currentSheetScrollId() {
    if (schedaCorrente >= 0 && schedaCorrente < schedePersonaggio.length) {
      final sheet = schedePersonaggio[schedaCorrente];
      final tag = '${sheet['sheetTag'] ?? sheet['id'] ?? ''}'.trim();
      if (tag.isNotEmpty) return tag;
    }
    return 'sheet_$schedaCorrente';
  }

  Key sheetScrollKey(String pageId) {
    return ValueKey<String>('oculum_scroll_${currentSheetScrollId()}_$pageId');
  }

  Key sheetExpansionKey(String sectionId) {
    final safeId = sectionId.replaceAll(RegExp(r'[^A-Za-z0-9_]+'), '_');
    return ValueKey<String>(
      'oculum_expansion_${currentSheetScrollId()}_$safeId',
    );
  }

  void invalidateDerivedDataCaches({bool notifyHiddenEyeCards = true}) {
    derivedDataRevision++;
    formulaParserCacheRevision = -1;
    formulaValueContextCache = null;
    formulaCommandCache.clear();
    activeQuickCommandTextCacheRevision = -1;
    activeQuickCommandTextCache = '';
    incomingDamageRulesCache.clear();
    inferredDamageTypeLabelsCache = null;
    allDamageElementIdsCache = null;
    manualFilteredIndexesCache = null;
    manualFilteredIndexesCacheKey = '';
    inferredDamageTypeLabelsCacheRevision = -1;
    allDamageElementIdsCacheRevision = -1;
    invalidateHiddenEyeDerivedCaches(notifyCards: notifyHiddenEyeCards);
  }

  void notifyDiceResultChanged() {
    if (!mounted) return;
    diceResultRevision.value++;
  }

  void notifyDiceOverlayChanged() {
    if (!mounted) return;
    diceOverlayRevision.value++;
  }

  bool aggiustaNucleoDisponibile() {
    return !aggiustaNucleoUsato && !aggiustaNucleoInCorso;
  }

  void notifyAggiustaNucleoDisponibilitaChanged() {
    aggiustaNucleoDisponibileRevision.value++;
  }

  ValueListenable<int> artIntegrityListenable(int artIndex) {
    final current = artIndex >= 0 && artIndex < arti.length
        ? arti[artIndex].integritaCorrente
        : 0;
    return artIntegrityRevisions.putIfAbsent(
      artIndex,
      () => ValueNotifier<int>(current),
    );
  }

  bool artActivationAvailable(int artIndex) {
    if (artIndex < 0 || artIndex >= arti.length) return false;
    final current = arti[artIndex].integritaCorrente;
    final effectiveCurrent = current < 0
        ? oculumArtMaximumValue(
            level: leggiNumero(livelloController),
            grade: leggiNumero(gradoController),
          )
        : current;
    return oculumArtCanActivate(
      effectiveCurrent,
      cost: oculumArtUseCostForDifficulty(
        oculumArtActivationCost,
        normalizedCampaignDifficulty(),
      ),
    );
  }

  ValueListenable<bool> artActivationAvailableListenable(int artIndex) {
    return artActivationAvailableRevisions.putIfAbsent(
      artIndex,
      () => ValueNotifier<bool>(artActivationAvailable(artIndex)),
    );
  }

  void notifyArtActivationAvailableChanged(int artIndex) {
    if (!mounted || artIndex < 0 || artIndex >= arti.length) return;
    final current = artActivationAvailable(artIndex);
    final notifier = artActivationAvailableRevisions.putIfAbsent(
      artIndex,
      () => ValueNotifier<bool>(current),
    );
    if (notifier.value != current) notifier.value = current;
  }

  void notifyArtIntegrityChanged(int artIndex) {
    if (!mounted || artIndex < 0 || artIndex >= arti.length) return;
    final notifier = artIntegrityRevisions.putIfAbsent(
      artIndex,
      () => ValueNotifier<int>(arti[artIndex].integritaCorrente),
    );
    if (notifier.value != arti[artIndex].integritaCorrente) {
      oculumProgressProfileCount('artNotifications');
      notifier.value = arti[artIndex].integritaCorrente;
    }
    notifyArtActivationAvailableChanged(artIndex);
  }

  void syncArtIntegrityNotifiers() {
    for (var i = 0; i < arti.length; i++) {
      notifyArtIntegrityChanged(i);
    }
  }

  String artSkillLevelRevisionKey(int artIndex, int skillIndex) {
    return '$artIndex:$skillIndex';
  }

  ValueListenable<int> artSkillUiListenable(int artIndex, int skillIndex) {
    return artSkillUiRevisions.putIfAbsent(
      artSkillLevelRevisionKey(artIndex, skillIndex),
      () => ValueNotifier<int>(0),
    );
  }

  void notifyArtSkillUiChanged(int artIndex, int skillIndex) {
    if (!mounted ||
        artIndex < 0 ||
        artIndex >= arti.length ||
        skillIndex < 0 ||
        skillIndex >= arti[artIndex].skills.length) {
      return;
    }
    final notifier = artSkillUiRevisions.putIfAbsent(
      artSkillLevelRevisionKey(artIndex, skillIndex),
      () => ValueNotifier<int>(0),
    );
    notifier.value++;
  }

  ValueListenable<int> artSkillLevelListenable(int artIndex, int skillIndex) {
    final current =
        artIndex >= 0 &&
            artIndex < arti.length &&
            skillIndex >= 0 &&
            skillIndex < arti[artIndex].skills.length
        ? arti[artIndex].skills[skillIndex].livello
        : 0;
    return artSkillLevelRevisions.putIfAbsent(
      artSkillLevelRevisionKey(artIndex, skillIndex),
      () => ValueNotifier<int>(current),
    );
  }

  Listenable artSkillLevelsListenable(int artIndex) {
    if (artIndex < 0 || artIndex >= arti.length) {
      return Listenable.merge(const <Listenable>[]);
    }
    return Listenable.merge(<Listenable>[
      for (
        var skillIndex = 0;
        skillIndex < arti[artIndex].skills.length;
        skillIndex++
      )
        artSkillLevelListenable(artIndex, skillIndex),
    ]);
  }

  void notifyArtSkillLevelChanged(int artIndex, int skillIndex) {
    if (!mounted ||
        artIndex < 0 ||
        artIndex >= arti.length ||
        skillIndex < 0 ||
        skillIndex >= arti[artIndex].skills.length) {
      return;
    }
    final current = arti[artIndex].skills[skillIndex].livello;
    final notifier = artSkillLevelRevisions.putIfAbsent(
      artSkillLevelRevisionKey(artIndex, skillIndex),
      () => ValueNotifier<int>(current),
    );
    if (notifier.value != current) {
      oculumProgressProfileCount('artSkillNotifications');
      notifier.value = current;
    }
    notifyArtSkillUiChanged(artIndex, skillIndex);
  }

  void syncArtSkillLevelNotifiers() {
    for (var artIndex = 0; artIndex < arti.length; artIndex++) {
      for (
        var skillIndex = 0;
        skillIndex < arti[artIndex].skills.length;
        skillIndex++
      ) {
        notifyArtSkillLevelChanged(artIndex, skillIndex);
      }
    }
  }

  ValueListenable<bool> artUnlockedListenable(int artIndex) {
    final current = artIndex >= 0 && artIndex < arti.length
        ? arti[artIndex].sbloccata
        : false;
    return artUnlockedRevisions.putIfAbsent(
      artIndex,
      () => ValueNotifier<bool>(current),
    );
  }

  void notifyArtUnlockedChanged(int artIndex) {
    if (!mounted || artIndex < 0 || artIndex >= arti.length) return;
    final current = arti[artIndex].sbloccata;
    final notifier = artUnlockedRevisions.putIfAbsent(
      artIndex,
      () => ValueNotifier<bool>(current),
    );
    if (notifier.value != current) notifier.value = current;
  }

  void syncArtUnlockedNotifiers() {
    for (var artIndex = 0; artIndex < arti.length; artIndex++) {
      notifyArtUnlockedChanged(artIndex);
    }
  }

  void notifyExperienceChanged() {
    if (!mounted) return;
    oculumProgressProfileCount('expNotifications');
    experienceRevision.value++;
  }

  void notifyOculumResourceChanged() {
    if (!mounted) return;
    oculumResourceRevision.value++;
  }

  ValueListenable<int> hiddenEyeStatListenable(HiddenEyeStat stat) {
    return hiddenEyeStatRevisions.putIfAbsent(
      stat.id,
      () => ValueNotifier<int>(0),
    );
  }

  void invalidateHiddenEyeDerivedCaches({bool notifyCards = true}) {
    hiddenEyeStatGroupCache.clear();
    hiddenEyeStatsByGroupCache.clear();
    hiddenEyeDerivedStatsCache = null;
    hiddenEyeDerivedBonusCache.clear();
    hiddenEyeTotalBaseCache.clear();
    hiddenEyeTotalValueCache.clear();

    if (!notifyCards || !mounted) return;
    hiddenEyeListRevision.value++;
    for (final notifier in hiddenEyeStatRevisions.values) {
      notifier.value++;
    }
  }

  void notifyHiddenEyeStatChanged(HiddenEyeStat stat) {
    if (!mounted) return;
    hiddenEyeTotalBaseCache.remove(stat.id);
    hiddenEyeTotalValueCache.remove(stat.id);
    final notifier = hiddenEyeStatRevisions[stat.id];
    if (notifier == null) return;
    notifier.value++;
  }

  void scheduleHiddenEyeDerivedCardsRefresh() {
    if (hiddenEyeDerivedCardsRefreshScheduled || !mounted) return;
    hiddenEyeDerivedCardsRefreshScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      hiddenEyeDerivedCardsRefreshScheduled = false;
      if (!mounted) return;
      invalidateHiddenEyeDerivedCaches();
    });
  }

  void scheduleHiddenEyeProgressSave() {
    hiddenEyeProgressSaveTimer?.cancel();
    hiddenEyeProgressSaveTimer = Timer(const Duration(milliseconds: 420), () {
      hiddenEyeProgressSaveTimer = null;
      if (!mounted) return;
      programmaSalvataggio(invalidateCaches: false);
    });
  }

  /// Lets feature modules request a scoped UI refresh without exposing
  /// [State.setState] outside this state object.
  void refreshOculumHome(VoidCallback update) {
    if (!mounted) return;
    setState(update);
  }

  void scheduleInputUiRefresh({
    Duration delay = const Duration(milliseconds: 140),
  }) {
    if (!mounted) return;
    if (appOculumInBackground || appOculumFocusTransition) {
      inputRefreshPendingAfterFocusTransition = true;
      inputUiRefreshTimer?.cancel();
      inputUiRefreshTimer = null;
      return;
    }

    inputUiRefreshTimer?.cancel();
    inputUiRefreshTimer = Timer(delay, () {
      if (!mounted) return;
      if (appOculumInBackground || appOculumFocusTransition) {
        inputRefreshPendingAfterFocusTransition = true;
        return;
      }
      inputRefreshPendingAfterFocusTransition = false;
      inputUiRevision.value++;
    });
  }

  void beginOculumFocusTransition() {
    appOculumFocusTransition = true;
    lifecycleFocusSettleTimer?.cancel();
    if (autosaveTimer?.isActive ?? false) {
      autosavePendingAfterFocusTransition = true;
      autosaveTimer?.cancel();
      autosaveTimer = null;
    }
    inputUiRefreshTimer?.cancel();
    inputUiRefreshTimer = null;
  }

  void scheduleOculumFocusSettled() {
    lifecycleFocusSettleTimer?.cancel();
    lifecycleFocusSettleTimer = Timer(const Duration(milliseconds: 360), () {
      if (!mounted || appOculumInBackground) return;
      appOculumFocusTransition = false;

      if (inputRefreshPendingAfterFocusTransition) {
        inputRefreshPendingAfterFocusTransition = false;
        scheduleInputUiRefresh(delay: const Duration(milliseconds: 120));
      }

      if (autosavePendingAfterFocusTransition) {
        autosavePendingAfterFocusTransition = false;
        programmaSalvataggio();
      }
    });
  }

  void _prepareFunctionNavigation(String? anchorId) {
    if (anchorId == null || anchorId.trim().isEmpty) return;

    switch (anchorId) {
      case 'sheet_damage':
      case 'sheet_heal':
      case 'sheet_damage_heal':
      case 'sheet_damage_heal_input':
        mostraDannoCuraScheda = true;
        _expandedFunctionSections.add('sheet_damage_heal');
        break;
      case 'sheet_hp':
        _expandedFunctionSections.add('sheet_hp');
        break;
      case 'sheet_shield':
      case 'sheet_attack_bonus':
      case 'sheet_defense_bonus':
        _expandedFunctionSections.add('sheet_hp');
        break;
      case 'sheet_editable_values':
      case 'sheet_editable_values_resilienza':
      case 'sheet_editable_values_volonta':
      case 'sheet_editable_values_materia':
      case 'sheet_editable_values_oculum':
        mostraValoriEditabiliScheda = true;
        _expandedFunctionSections.add('sheet_editable_values');
        break;
      case 'inventory_root':
        mostraBorsaCompatta = true;
        break;
      case 'sheet_party':
        mostraPartyScheda = true;
        _expandedFunctionSections.add('sheet_party');
        break;
      case 'sheet_dice_quick':
        _expandedFunctionSections.add('sheet_dice_quick');
        break;
    }
  }

  FocusNode? _focusNodeForAnchor(String? anchorId) {
    switch (anchorId) {
      case 'sheet_damage':
      case 'sheet_heal':
      case 'sheet_damage_heal':
      case 'sheet_damage_heal_input':
        return dannoCuraFocusNode;
      case 'sheet_editable_values_resilienza':
        return resilienzaFocusNode;
      case 'sheet_editable_values_volonta':
        return volontaFocusNode;
      case 'sheet_editable_values_materia':
        return materiaFocusNode;
      case 'sheet_editable_values_oculum':
        return oculumFocusNode;
      case 'sheet_shield':
        return scudoFocusNode;
      case 'sheet_attack_bonus':
        return attaccoRapidoFocusNode;
      case 'sheet_defense_bonus':
        return difesaRapidaFocusNode;
    }
    return null;
  }

  Future<void> vaiAllaFunzione({
    required int page,
    String? anchorId,
    int? manualIndex,
    String? logTitle,
    bool focusField = true,
  }) async {
    if (!mounted) return;

    final targetPage = paginaVisibileSicura(page);
    oculumProfileMark('navigation_page_$targetPage');
    final needsLazyActivation = !_isPagePreparedForDisplay(targetPage);

    setState(() {
      paginaCorrente = page;
      _prepareFunctionNavigation(anchorId);

      if (manualIndex != null) {
        manualSectionIndex = manualIndex;
      }

      if (logTitle != null && logTitle.trim().isNotEmpty) {
        aggiungiLog('Aperta funzione: $logTitle.');
      }
    });

    if (needsLazyActivation) {
      _scheduleLazyPageActivation(targetPage);
      await _waitForLazyPageActivation(targetPage);
    }

    if (anchorId == null || anchorId.trim().isEmpty) return;

    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    final baseAnchor = anchorId.startsWith('sheet_editable_values_')
        ? 'sheet_editable_values'
        : anchorId;
    final keyContext = _functionNavKeys[baseAnchor]?.currentContext;
    if (keyContext == null || !keyContext.mounted) {
      setState(() {
        risultato = t(
          'Funzione non ancora collegata: ${logTitle ?? anchorId}.',
          'Function not linked yet: ${logTitle ?? anchorId}.',
        );
      });
      return;
    }

    await Scrollable.ensureVisible(
      keyContext,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      alignment: 0.08,
    );

    if (!mounted) return;
    if (focusField) _focusNodeForAnchor(anchorId)?.requestFocus();
  }

  Future<void> apriDannoCuraDalCentroPartita({
    String target = 'damageHeal',
  }) async {
    if (!mounted) return;

    final normalized = target.trim().toLowerCase();
    final anchorId = switch (normalized) {
      'damage' || 'danno' => 'sheet_damage',
      'heal' || 'cura' => 'sheet_heal',
      'hp' || 'vita' => 'sheet_hp',
      _ => 'sheet_damage_heal',
    };

    final title = switch (normalized) {
      'damage' || 'danno' => t('Danno', 'Damage'),
      'heal' || 'cura' => t('Cura', 'Healing'),
      'hp' || 'vita' => 'HP',
      _ => t('Danno / Cura', 'Damage / Healing'),
    };

    setState(() {
      mostraDannoCuraScheda = true;
      risultato = t(
        'Centro partita: apertura rapida di $title.',
        'Game center: quick opening of $title.',
      );
      aggiungiLog(risultato);
    });

    await vaiAllaFunzione(page: 0, anchorId: anchorId, logTitle: title);

    programmaSalvataggio();
  }

  bool linguaInglese = false;
  bool datiCaricati = false;
  bool tutorialCompletato = false;
  bool rebirthato = false;
  bool modalitaDesktop = false;
  bool modalitaVeloce = false;
  bool modalitaLeggera = false;
  bool desktopSideMenuOpen = false;
  bool modalitaMaster = false;
  bool sceltaRuoloSessioneMostrata = false;
  bool tutorialDialogPending = false;

  final List<Map<String, dynamic>> schedePersonaggio = [];
  final Map<String, List<Map<String, dynamic>>> textAttachments =
      <String, List<Map<String, dynamic>>>{};
  final TextEditingController sheetCodeController = TextEditingController();
  final Set<int> selectedSheetCodeIndexes = <int>{};

  int? windows1252Byte(int codePoint) {
    if (codePoint <= 0xFF) return codePoint;

    const mapped = {
      0x20AC: 0x80,
      0x201A: 0x82,
      0x0192: 0x83,
      0x201E: 0x84,
      0x2026: 0x85,
      0x2020: 0x86,
      0x2021: 0x87,
      0x02C6: 0x88,
      0x2030: 0x89,
      0x0160: 0x8A,
      0x2039: 0x8B,
      0x0152: 0x8C,
      0x017D: 0x8E,
      0x2018: 0x91,
      0x2019: 0x92,
      0x201C: 0x93,
      0x201D: 0x94,
      0x2022: 0x95,
      0x2013: 0x96,
      0x2014: 0x97,
      0x02DC: 0x98,
      0x2122: 0x99,
      0x0161: 0x9A,
      0x203A: 0x9B,
      0x0153: 0x9C,
      0x017E: 0x9E,
      0x0178: 0x9F,
    };

    return mapped[codePoint];
  }

  String decodeMojibakePass(String value) {
    final bytes = <int>[];

    for (final codePoint in value.runes) {
      final byte = windows1252Byte(codePoint);
      if (byte == null) return value;
      bytes.add(byte);
    }

    try {
      return utf8.decode(bytes, allowMalformed: false);
    } catch (_) {
      return value;
    }
  }

  String cleanUiText(String value) {
    return oculumCleanMojibakeText(value);
  }

  String t(String it, String en) => cleanUiText(linguaInglese ? en : it);
  String manualTitle(ManualSection section) {
    return cleanUiText(linguaInglese ? section.titleEn : section.titleIt);
  }

  String manualContent(ManualSection section) {
    return cleanUiText(linguaInglese ? section.contentEn : section.contentIt);
  }

  String damageDescription(DamageModifierOption option) {
    return cleanUiText(
      linguaInglese ? option.descriptionEn : option.descriptionIt,
    );
  }

  final ImagePicker _picker = ImagePicker();
  Uint8List? immaginePersonaggio;

  // =====================================================
  // CONTROLLER BASE
  // =====================================================

  final nomeController = TextEditingController(text: '???');
  final tipoSchedaController = TextEditingController(text: 'Personaggio');
  final razzaController = TextEditingController();

  /// Tutorial e scheda partono da livello 0.
  final livelloController = TextEditingController(text: '0');
  final gradoController = TextEditingController(text: '0');

  final expController = TextEditingController(text: '0');
  final expDaAggiungereController = TextEditingController(text: '0');
  final expNomePersonalizzatoController = TextEditingController();
  final livelliRapidiController = TextEditingController(text: '1');

  final resilienzaController = TextEditingController(text: '3');
  final volontaController = TextEditingController(text: '1');
  final materiaController = TextEditingController(text: '0');
  final oculumController = TextEditingController(text: '1');
  final currentResilienzaController = TextEditingController(text: '3');
  final currentVolontaController = TextEditingController(text: '1');
  final currentMateriaController = TextEditingController(text: '0');
  final currentOculumController = TextEditingController(text: '1');
  final visibleCurrentResilienzaController = TextEditingController(text: '3');
  final visibleCurrentVolontaController = TextEditingController(text: '1');
  final visibleCurrentMateriaController = TextEditingController(text: '0');
  final visibleCurrentOculumController = TextEditingController(text: '1');
  final List<String> _formulaTriggerSourceStack = <String>[];
  final imagePasteFocusNode = FocusNode();

  final currentHpController = TextEditingController(text: '30');
  final hpTempController = TextEditingController(text: '0');
  final scudoController = TextEditingController(text: '0');
  final scudoCriticoController = TextEditingController(text: '0');
  final scudoOculumController = TextEditingController(text: '0');
  final scudoOculumMaxController = TextEditingController(text: '0');
  final attaccoRapidoController = TextEditingController(text: '0');
  final cmRapidoController = TextEditingController(text: '0');
  final difesaRapidaController = TextEditingController(text: '0');
  final reazioniController = TextEditingController(text: '1');
  final reazioniVelociController = TextEditingController(text: '0');
  final realtimeChatController = TextEditingController();
  final storySessionNoteController = TextEditingController();
  final buffMalusRapidiController = TextEditingController();
  final dannoSubitoController = TextEditingController();
  final dannoBonusScudoPercentController = TextEditingController(text: '0');
  final OculumDecodedImageCache decodedImageBase64Cache =
      OculumDecodedImageCache();
  final scudoFocusNode = FocusNode();
  final attaccoRapidoFocusNode = FocusNode();
  final difesaRapidaFocusNode = FocusNode();
  final dannoCuraFocusNode = FocusNode();
  final resilienzaFocusNode = FocusNode();
  final volontaFocusNode = FocusNode();
  final materiaFocusNode = FocusNode();
  final oculumFocusNode = FocusNode();

  final backgroundController = TextEditingController(
    text:
        'Scrivi qui il passato, lo scopo, i legami, le paure e il destino del personaggio.',
  );
  final notePersonaggioController = TextEditingController();

  final skillNomeController = TextEditingController();
  final skillTipoController = TextEditingController(text: 'Cerchio Magico');
  final skillCostoController = TextEditingController(text: '0');
  final skillCooldownController = TextEditingController(text: 'Nessuno');
  final skillDescrizioneController = TextEditingController();
  final skillResController = TextEditingController(text: '0');
  final skillVolController = TextEditingController(text: '0');
  final skillMatController = TextEditingController(text: '0');
  final skillOcuController = TextEditingController(text: '0');
  final skillDanniController = TextEditingController(text: '0');
  final skillDifesaController = TextEditingController(text: '0');

  final titoloNomeController = TextEditingController();
  final titoloTipoController = TextEditingController(text: 'Titolo Azione');
  final titoloOttenimentoController = TextEditingController();
  final titoloLeggendaController = TextEditingController();
  final titoloBuffController = TextEditingController();
  final titoloPuntoCiecoController = TextEditingController();
  final titoloSkillController = TextEditingController();
  final titoloRichiedeController = TextEditingController(text: '???');

  final titoloResController = TextEditingController(text: '0');
  final titoloVolController = TextEditingController(text: '0');
  final titoloMatController = TextEditingController(text: '0');
  final titoloOcuController = TextEditingController(text: '0');
  final titoloKarmaController = TextEditingController(text: '0');

  final titoloOpenNameController = TextEditingController();
  final titoloOpenDescriptionController = TextEditingController();
  final titoloOpenBuffController = TextEditingController();
  final titoloOpenSkillController = TextEditingController();

  final itemNomeController = TextEditingController();
  final itemPesoController = TextEditingController(text: '0');
  final itemQuantitaController = TextEditingController(text: '1');
  final itemPutrefazioneSessioniController = TextEditingController(text: '0');
  final itemNoteController = TextEditingController();
  final itemBuffController = TextEditingController();
  final itemBonusDannoController = TextEditingController(text: '0');
  final itemBonusDifesaController = TextEditingController(text: '0');
  final itemBonusScudoController = TextEditingController(text: '0');
  final itemGradoOggettoController = TextEditingController(text: '0');
  final itemGradoRichiestoController = TextEditingController(text: '0');
  final itemElementoDannoController = TextEditingController(text: 'Fisico');
  final customDamageTypeController = TextEditingController();
  final masterEnemyDamageController = TextEditingController(text: '10');
  final masterEnemyHealController = TextEditingController(text: '10');

  final partyNomeController = TextEditingController();
  final partyRuoloController = TextEditingController(text: 'Alleato');
  final partyNoteController = TextEditingController();
  final masterSessionController = TextEditingController();

  final obserController = TextEditingController(text: '0');
  final ascensionDustController = TextEditingController(text: '0');
  final ispirazioniController = TextEditingController(text: '0');
  final superIspirazioniController = TextEditingController(text: '0');
  final ispirazioniOculumController = TextEditingController(text: '0');
  final karmaController = TextEditingController(text: '0');
  final folliaController = TextEditingController(text: '0');
  final oculumTiroController = TextEditingController(text: '0');

  final cenereController = TextEditingController(text: '0');
  final sessioniSenzaBisogniController = TextEditingController(text: '0');
  final giorniSenzaCiboAcquaController = TextEditingController(text: '0');
  final oculumCurrentDayController = TextEditingController(text: '1');

  final manualSearchController = TextEditingController();
  final themeSearchController = TextEditingController();
  final monsterBookSearchController = TextEditingController();
  final recipeSearchController = TextEditingController();

  final quickSheetNameController = TextEditingController(text: '???');
  final quickSheetLevelController = TextEditingController(text: '0');
  final quickSheetGradeController = TextEditingController(text: '0');
  final quickSheetCountController = TextEditingController(text: '1');
  final quickSheetDescriptionController = TextEditingController();
  String quickSheetArtMode = 'random';
  bool quickSheetAddToInitiative = true;
  String selectedSystemMonsterPresetId = '';

  final tutorialLevelController = TextEditingController(text: '0');
  final tutorialExtraResController = TextEditingController(text: '0');
  final tutorialExtraVolController = TextEditingController(text: '0');
  final tutorialExtraMatController = TextEditingController(text: '0');
  final tutorialExtraOcuController = TextEditingController(text: '0');

  final diceAmountController = TextEditingController(text: '1');
  final diceModifierController = TextEditingController(text: '0');
  final difficoltaTiroController = TextEditingController(text: '0');
  final relayServerController = TextEditingController(text: '');
  final relayRoomController = TextEditingController(text: '');
  final realtimeRoomController = TextEditingController(text: 'test');
  final realtimeNameController = TextEditingController();
  final oculumUsernameController = TextEditingController();
  final friendTagController = TextEditingController();
  final friendNameController = TextEditingController();
  final campaignNameController = TextEditingController(
    text: 'Campagna principale',
  );
  final newCampaignNameController = TextEditingController();
  final mapUrlController = TextEditingController();
  final mapNotesController = TextEditingController();
  final mapTokenSizeController = TextEditingController(text: '64');
  final mapWidthMetersController = TextEditingController(text: '30');
  final mapHeightMetersController = TextEditingController(text: '20');
  final mapFreeTokenMovementController = TextEditingController(text: '6');
  final TransformationController mapTransformationController =
      TransformationController();
  String mapMode = 'image';
  String mapImagePath = '';
  String mapImageName = '';
  bool mapSaveSession = false;
  bool mapSessionChoiceAsked = false;
  bool mapPlayersCanManageOwnToken = true;
  int mapTokenSheetIndex = 0;
  final List<Map<String, dynamic>> localMapTokens = [];
  OculumVttState vttState = OculumVttState.empty();
  OculumVttTool vttTool = OculumVttTool.pan;
  String vttFogAudience = 'party';
  final ValueNotifier<int> vttCanvasRevision = ValueNotifier<int>(0);
  final List<Offset> vttDraftPoints = <Offset>[];
  final List<Offset> vttMeasurePoints = <Offset>[];
  final List<String> vttUndoHistory = <String>[];
  final List<String> vttRedoHistory = <String>[];
  final Set<String> vttSelectedTokenIds = <String>{};
  Offset? vttPointerStart;
  String vttSelectedElementId = '';
  bool vttPublishing = false;
  bool vttRealtimeAssetPending = false;
  Map<String, dynamic> realtimeVisibleVttSnapshot = <String, dynamic>{};
  OculumVttScene? realtimeVisibleVttScene;
  Uint8List? realtimeVisibleVttImageBytes;
  String realtimeVisibleVttAssetId = '';
  double realtimeVttAssetProgress = 0;
  final Map<String, OculumVttAssetAssembler> realtimeVttAssetAssemblers =
      <String, OculumVttAssetAssembler>{};

  final primoTitoloFatoNomeController = TextEditingController(
    text: 'Titolo del Fato',
  );

  final primoTitoloFatoDescrizioneController = TextEditingController(
    text:
        'Primo Titolo del Fato ottenuto quando la prima Skill della prima Art raggiunge il livello 1.',
  );

  // =====================================================
  // LISTE DATI
  // =====================================================

  final List<OculumTitle> titoli = [];
  final List<OculumTitle> trattiRazziali = [];
  final List<InventoryItem> inventario = [];
  final List<CharacterSkill> skills = [];
  final List<CharacterArt> arti = [];
  final List<String> diarioPagine = [];
  final List<OculumSessionNote> storySessionNotes = [];
  final List<OculumRecipe> recipes = [];
  final List<JournalEntry> journalEntries = [];
  final List<DraftNote> draftNotes = [];
  final List<HiddenEyeStat> hiddenEyeStats = [];
  final List<OculumTemporaryResistanceEffect> temporaryCombatResistanceEffects =
      <OculumTemporaryResistanceEffect>[];
  final List<ReputationEntry> reputations = [];
  bool reputationsManuallyCleared = false;
  final List<String> logEventi = [];
  final List<Map<String, dynamic>> partyMembri = [];
  final List<MonsterBookEntry> monsterBookCustomEntries = [];
  final Set<String> monsterBookRemovedIds = <String>{};
  final List<Map<String, dynamic>> amiciOculum = [];
  final List<Map<String, dynamic>> campagneOculum = [];

  // =====================================================
  // STATO UI / SISTEMA
  // =====================================================

  bool nuovoTitoloEvoluto = false;
  bool nuovoItemArma = false;
  bool nuovoItemProtegge = false;
  bool nuovoItemEquipaggiato = false;

  // =====================================================
  // STATO APP / VARIABILI MANCANTI
  // =====================================================

  Timer? autosaveTimer;
  Timer? dadoOverlayTimer;
  Timer? dadoOverlayRevealTimer;
  Timer? relayHeartbeatTimer;
  Timer? relayReconnectTimer;
  Timer? relayLobbyRefreshTimer;
  Timer? realtimeOculumDebounceTimer;
  Timer? realtimeSheetShareDebounceTimer;
  Timer? realtimeReconnectTimer;
  Timer? inputUiRefreshTimer;
  Timer? hiddenEyeProgressSaveTimer;
  Timer? progressJournalSaveTimer;
  Timer? storySessionNotesSaveTimer;
  Timer? lifecycleLocalSaveTimer;
  Timer? lifecycleFocusSettleTimer;
  Timer? vttRealtimeDebounceTimer;
  Timer? vttPingCleanupTimer;
  StreamSubscription<List<ConnectivityResult>>? connectivitySubscription;
  bool salvataggioInCorso = false;
  final OculumSaveRequestQueue saveRequestQueue = OculumSaveRequestQueue();
  bool salvataggioInChiusura = false;
  int salvataggioMutazioneRevisione = 0;
  bool salvataggioMutazioneNota = false;
  bool appOculumInBackground = false;
  bool appOculumFocusTransition = false;
  bool inputRefreshPendingAfterFocusTransition = false;
  bool autosavePendingAfterFocusTransition = false;
  int salvataggioRevisione = 0;
  int salvataggioFallimentiConsecutivi = 0;
  DateTime? ultimoSalvataggioCompletatoAt;
  DateTime? ultimaRotazioneBackupAt;
  String ultimoSalvataggioFirma = '';
  String ultimoSalvataggioContenutoFirma = '';
  String? ultimoRawSalvataggioConfermato;
  String ultimoArchivioDiarioFirma = '';
  final Map<String, dynamic> extraTopLevelSaveFields = <String, dynamic>{};
  int derivedDataRevision = 0;
  int formulaParserCacheRevision = -1;
  Map<String, num>? formulaValueContextCache;
  final Map<String, List<OculumFormulaCommand>> formulaCommandCache =
      <String, List<OculumFormulaCommand>>{};
  int activeQuickCommandTextCacheRevision = -1;
  String activeQuickCommandTextCache = '';
  final Map<String, List<({String command, String value, String element})>>
  incomingDamageRulesCache =
      <String, List<({String command, String value, String element})>>{};
  int inferredDamageTypeLabelsCacheRevision = -1;
  Map<String, String>? inferredDamageTypeLabelsCache;
  int allDamageElementIdsCacheRevision = -1;
  List<String>? allDamageElementIdsCache;
  String manualFilteredIndexesCacheKey = '';
  List<int>? manualFilteredIndexesCache;
  final Map<String, String> hiddenEyeStatGroupCache = <String, String>{};
  final Map<String, List<HiddenEyeStat>> hiddenEyeStatsByGroupCache =
      <String, List<HiddenEyeStat>>{};
  Map<String, int>? hiddenEyeDerivedStatsCache;
  final Map<String, int> hiddenEyeDerivedBonusCache = <String, int>{};
  final Map<String, int> hiddenEyeTotalBaseCache = <String, int>{};
  final Map<String, int> hiddenEyeTotalValueCache = <String, int>{};
  bool hiddenEyeDerivedCardsRefreshScheduled = false;
  String hiddenEyeManagerSelectedGroup = 'resilienza';
  String hiddenEyeManagerSelectedStatId = '';
  final ScrollController hiddenEyeManagerScrollController = ScrollController();
  final OculumActionQueue realtimeDiceConsentQueue = OculumActionQueue();

  Color primaryColor = defaultPrimaryColor;
  Color secondaryColor = defaultSecondaryColor;
  Color tertiaryColor = defaultTertiaryColor;
  Color eyeUtilityColor = defaultEyeUtilityColor;
  Color backgroundTopColor = defaultBackgroundTopColor;
  Color backgroundMidColor = defaultBackgroundMidColor;
  Color backgroundBottomColor = defaultBackgroundBottomColor;
  Color eyePupilGlowColor = defaultEyePupilGlowColor;
  String colorPresetSelezionato = 'classic_reliquary';
  String colorDecorationPresetId = 'none';
  String colorGuiPresetId = 'classic_reliquary';
  String campaignDifficulty = 'normale';
  int fortuna = 0;
  int fateTokens = 0;
  int diarioRewardClaimedCount = 0;
  bool campaignDifficultyStarterClaimed = false;
  double themeDecorationOpacityScale = 1.0;
  double themeDecorationGlowScale = 1.0;
  double themeDecorationIntensityScale = 1.0;
  final Set<String> unlockedColorThemeIds = {'classic_reliquary'};

  String risultato = 'Scegli una statistica e tira il dado.';
  String dadoMostrato = '';
  int dadoMostratoFacce = 20;
  OculumAggiustaNucleoResult? ultimoRisultatoAggiustaNucleo;
  final ValueNotifier<int> diceResultRevision = ValueNotifier<int>(0);
  final ValueNotifier<int> diceOverlayRevision = ValueNotifier<int>(0);
  final ValueNotifier<int> inputUiRevision = ValueNotifier<int>(0);
  final ValueNotifier<int> hiddenEyeListRevision = ValueNotifier<int>(0);
  final ValueNotifier<int> experienceRevision = ValueNotifier<int>(0);
  final ValueNotifier<int> oculumResourceRevision = ValueNotifier<int>(0);
  final ValueNotifier<int> aggiustaNucleoDisponibileRevision =
      ValueNotifier<int>(0);
  final ValueNotifier<int> recipesRevision = ValueNotifier<int>(0);
  final ValueNotifier<String> recipeSearchQuery = ValueNotifier<String>('');
  bool recipeMutationInProgress = false;
  final Map<String, ValueNotifier<int>> hiddenEyeStatRevisions =
      <String, ValueNotifier<int>>{};
  final Map<int, ValueNotifier<int>> artIntegrityRevisions =
      <int, ValueNotifier<int>>{};
  final Map<String, ValueNotifier<int>> artSkillLevelRevisions =
      <String, ValueNotifier<int>>{};
  final Map<String, ValueNotifier<int>> artSkillUiRevisions =
      <String, ValueNotifier<int>>{};
  bool skillOculumUseDialogOpen = false;
  final Map<int, ValueNotifier<bool>> artUnlockedRevisions =
      <int, ValueNotifier<bool>>{};
  final Map<int, ValueNotifier<bool>> artActivationAvailableRevisions =
      <int, ValueNotifier<bool>>{};
  final Map<String, dynamic> progressJournalSheets = <String, dynamic>{};
  Future<void> progressJournalWriteChain = Future<void>.value();
  int progressJournalRevision = 0;
  int artIntegrityColorThemeSignature = -1;
  Color? cachedArtIntegrityStartColor;
  final Map<String, Color> cachedArtIntegrityColors = <String, Color>{};

  bool tiroCriticoUno = false;
  bool tiroCriticoVenti = false;
  String lastValidRollSnapshot = '';
  bool lastValidRollCancelled = false;

  String dadoOverlay = '';
  int dadoOverlayFacce = 20;
  int dadoOverlaySpinSeed = 0;
  bool mostraOverlayDado = false;
  bool dadoOverlayMostraRisultato = false;
  bool dadoOverlayDismissibile = false;
  bool overlayCriticoUno = false;
  bool overlayCriticoVenti = false;

  String ultimoEventoRiposo = 'Nessun evento di riposo registrato.';
  int artIntegrityRestIndex = 0;
  bool longRestInProgress = false;
  bool aggiustaNucleoUsato = false;
  bool aggiustaNucleoInCorso = false;
  String statoForzaAttivo = '';
  bool statoForzaPronto = true;
  int statoForzaTiriRimanenti = 0;
  int malusTiriOculumPostEsplosione = 0;
  bool personaggioSvenuto = false;
  bool sottoStress = false;
  bool sottoStressManuale = false;
  final Map<String, int> stressStatConsumptionProgress = <String, int>{};
  int cenereSvenimentoUltimoControllo = 0;
  bool personaggioCaduto = false;
  int feriteMorte = 0;
  int volontaVitale = 0;

  int tempResilienza = 0;
  int tempVolonta = 0;
  int tempMateria = 0;
  int tempOculum = 0;
  int schivateOculumConsumate = 0;
  int schivataOculumRiduzionePronta = 0;
  String schivataOculumEtichettaPronta = '';
  bool scudoSalvataggioAttivo = false;
  String vantaggioTiroSelezionato = 'Normale';
  bool dannoOltreDifesa = false;
  bool dannoOltreScudi = false;
  int expMilestoneRegenClaimed = 0;
  int expHundredRegenRemainder = 0;
  int temporaryOculum = 0;
  int temporaryOculumRollsRemaining = 0;

  int raccoltaResilienzaSpesa = 0;
  int raccoltaVolontaSpesa = 0;
  int raccoltaMateriaSpesa = 0;
  int raccoltaOculumSpesa = 0;

  int levelUpDaAssegnare = 0;
  int monsterStatPoints = 0;

  String levelUpStatTre = 'Resilienza';
  String levelUpStatDue = 'Volontà';

  bool puoEssereOsservato = false;
  int osservazionePuntiDaAssegnare = 0;
  String osservazioneStatScelta = 'Resilienza';
  String osservazioneStatAssegnata = '';
  Map<String, int> osservazionePuntiAssegnati = <String, int>{
    'resilienza': 0,
    'volonta': 0,
    'materia': 0,
    'oculum': 0,
  };
  bool osservazionePuntiApplicati = false;

  String monsterSelectedStat = 'Resilienza';
  String monsterGradeStat = 'Resilienza';

  String quickSheetType = 'Personaggio';

  final monsterPointAmountController = TextEditingController(text: '1');

  String manualSearchText = '';
  int manualSectionIndex = 0;

  String filtroPrimario = 'Tutti';
  String filtroSecondario = 'Tutti';
  String filtroTerziario = 'Tutti';
  String filtroExtraOcchio = 'Tutti';
  String filtroAmbiente = 'Tutti';

  bool mostraEditorPrimario = false;
  bool mostraEditorSecondario = false;
  bool mostraEditorTerziario = false;
  bool mostraEditorExtraOcchio = false;
  bool mostraEditorPupilla = false;
  bool mostraEditorSfondoAlto = false;
  bool mostraEditorSfondoMedio = false;
  bool mostraEditorSfondoBasso = false;

  bool usaBarraVita = true;
  bool mostraDannoCuraScheda = true;
  bool mostraStrumentiManualeRapidi = true;
  bool mostraBorsaCompatta = true;
  bool mostraPartyScheda = true;
  bool mostraTastiRapidiIndice = true;
  bool mostraValoriEditabiliScheda = true;
  bool scalaExpAutomatica = true;
  bool sottraiStatsDaExpAggiunta = true;
  bool onlineDisponibile = false;
  bool onlineCheckInCorso = true;
  bool mostraSempreScudoOculum = false;
  bool phoneDiceSetupExpanded = true;
  bool phoneDiceClassicExpanded = true;
  bool phoneDiceExtraExpanded = false;
  double userGuiScale = 1.0;

  // Protezione salvataggi: se un salvataggio vecchio/non compatibile fallisce
  // il caricamento, l'app NON deve sovrascriverlo con una scheda vuota.
  bool salvataggioBloccatoPerErrore = false;
  String ultimoErroreCaricamentoSalvataggio = '';
  int hpTempBonusConsumati = 0;
  int scudoBonusConsumati = 0;
  bool folliaDaMostri = false;
  bool illnessArtSbloccata = false;
  bool applyingHistorySnapshot = false;
  final List<Map<String, dynamic>> undoHistory = [];
  final List<Map<String, dynamic>> redoHistory = [];

  final Set<String> _expandedFunctionSections = <String>{};

  // Rete P2P
  bool isMasterHost = false;
  bool isConnectedToMaster = false;
  bool sonoCoMaster = false;
  bool coMasterCanSetCoMaster = false;
  bool coMasterCanEditSheets = false;
  bool usingInternetRelay = false;
  bool relayConnected = false;
  bool waitingInternetInvite = false;
  bool relayAutoReconnect = true;
  bool relayConnecting = false;
  bool realtimeConnected = false;
  bool realtimeConnecting = false;
  bool realtimeFirstPresenceHandled = false;
  bool realtimeMasterBlockedByPresence = false;
  String realtimeMasterClaimId = '';
  bool masterKickRequiresConfirmation = true;
  bool masterEnemyFullSheetVisibility = false;
  bool masterPublicDiceVisible = false;
  bool masterAskPublicDiceConfirmation = true;
  String connectedMasterIp = '';
  String activeCampaignId = '';
  String relayStatus = '';
  String relayRoomCode = '';
  String relayLastRole = '';
  String relayLastRoom = '';
  String realtimeStatus = OculumRealtimeService.startupStatus;
  int relayLatencyMs = 0;
  DateTime? relayPingSentAt;
  List<Map<String, dynamic>> availablePlayers = []; // Per il radar UDP
  List<Map<String, dynamic>> internetAvailablePlayers = [];
  List<Map<String, dynamic>> realtimeUsers = [];
  final List<Map<String, dynamic>> realtimeSharedSheets = [];
  final List<Map<String, dynamic>> pendingOculumFriendRequests = [];
  final List<Map<String, dynamic>> sentOculumFriendRequests = [];
  final List<Map<String, dynamic>> blockedOculumFriends = [];
  final List<Map<String, dynamic>> masterInitiativeTokens = [];
  final masterInitiativeNameController = TextEditingController();
  final masterInitiativeTypeController = TextEditingController(text: 'Mostro');
  final masterInitiativeBonusController = TextEditingController(text: '0');
  final masterInitiativeNotesController = TextEditingController();
  bool masterInitiativeManualOrder = false;
  bool masterInitiativePublished = false;
  int masterInitiativeRound = 1;
  int masterInitiativeActiveIndex = 0;
  int masterInitiativeManualCounter = 0;
  int playerReportedTurn = 0;
  int automaticAshLastCheckedTurn = 0;
  final List<Map<String, dynamic>> activeStructuredEffects = [];
  Map<String, dynamic> realtimeVisibleInitiativeSnapshot = <String, dynamic>{};
  final ValueNotifier<Map<String, dynamic>?> realtimeDungeonMessage =
      ValueNotifier<Map<String, dynamic>?>(null);
  final Map<String, Map<String, dynamic>> realtimeDungeonHosts =
      <String, Map<String, dynamic>>{};
  final Set<String> realtimeCoMasterTags = <String>{};
  List<String> realtimeEvents = [];
  final Set<String> realtimeSeenEventKeys = <String>{};
  final Map<String, DateTime> realtimeRoleUpdateTimestamps =
      <String, DateTime>{};
  final Map<String, String> realtimeLastSentSheetHashes = <String, String>{};
  String realtimeFriendPresenceSignature = '';
  final Map<String, String> realtimePendingMasterAckSheetIds =
      <String, String>{};
  final Map<String, int> realtimePendingMasterAckAttempts = <String, int>{};
  final Map<String, Timer> realtimePendingMasterAckTimers = <String, Timer>{};
  OculumRealtimeService? realtimeService;
  bool applyingRealtimeRemoteSheet = false;
  bool realtimeAutoReconnectEnabled = false;
  int realtimeReconnectAttempt = 0;

  String modificatoreDannoSelezionato = 'Normale';
  bool imageDropActive = false;
  String fonteExpSelezionata = 'normale';
  final enemyGradeExpController = TextEditingController(text: '0');
  final Map<String, int> elementColorOverrides = <String, int>{};
  final List<String> customDamageTypes = [];
  Color oculumStatFormulaColor = const Color(0xFF8B5CF6);

  final List<String> tipiScheda = [
    'Personaggio',
    'Alleato',
    'NPC',
    'Mostro',
    'Mostro Mini Boss',
    'Mostro Boss',
  ];

  final List<String> statsLevelUp = [
    'Resilienza',
    'Volontà',
    'Materia',
    'Oculum',
  ];

  final List<String> pageNamesIt = [
    'Scheda',
    'Riposo',
    'Titoli',
    'Art',
    'Skill',
    'Storia',
    'Inventario',
    'Risorse',
    'Regole',
    'Master',
    'Mappa',
    'Impostazioni',
    'Online',
    'Sessione Dadi',
    'Ricette',
  ];

  final List<String> pageNamesEn = [
    'Sheet',
    'Rest',
    'Titles',
    'Arts',
    'Skills',
    'Story',
    'Inventory',
    'Resources',
    'Rules',
    'Master',
    'Map',
    'Settings',
    'Online',
    'Dice Session',
    'Recipes',
  ];

  final List<DamageModifierOption> modificatoriDanno = [
    DamageModifierOption(
      name: 'Fragilità Letale',
      multiplier: 6.00,
      descriptionIt: 'Fragilità letale: il danno aumenta del 500%.',
      descriptionEn: 'Lethal fragility: damage increases by 500%.',
    ),
    DamageModifierOption(
      name: 'Fragilità Semi Letale',
      multiplier: 3.50,
      descriptionIt: 'Fragilità semi letale: il danno aumenta del 250%.',
      descriptionEn: 'Semi-lethal fragility: damage increases by 250%.',
    ),
    DamageModifierOption(
      name: 'Fragilità Distruttiva',
      multiplier: 2.00,
      descriptionIt: 'Fragilità distruttiva: il danno aumenta del 100%.',
      descriptionEn: 'Destructive fragility: damage increases by 100%.',
    ),
    DamageModifierOption(
      name: 'Fragilità Assoluta',
      multiplier: 1.90,
      descriptionIt: 'Fragilità assoluta: il danno aumenta del 90%.',
      descriptionEn: 'Absolute fragility: damage increases by 90%.',
    ),
    DamageModifierOption(
      name: 'Fragilità Estrema',
      multiplier: 1.75,
      descriptionIt: 'Fragilità estrema: il danno aumenta del 75%.',
      descriptionEn: 'Extreme fragility: damage increases by 75%.',
    ),
    DamageModifierOption(
      name: 'Alta Fragilità',
      multiplier: 1.50,
      descriptionIt: 'Alta fragilità: il danno aumenta del 50%.',
      descriptionEn: 'High fragility: damage increases by 50%.',
    ),
    DamageModifierOption(
      name: 'Fragilità',
      multiplier: 1.25,
      descriptionIt: 'Fragilità: il danno aumenta del 25%.',
      descriptionEn: 'Fragility: damage increases by 25%.',
    ),
    DamageModifierOption(
      name: 'Bassa Fragilità',
      multiplier: 1.10,
      descriptionIt: 'Bassa fragilità: il danno aumenta del 10%.',
      descriptionEn: 'Low fragility: damage increases by 10%.',
    ),
    DamageModifierOption(
      name: 'Normale',
      multiplier: 1.00,
      descriptionIt: 'Danno normale: nessuna resistenza o fragilità applicata.',
      descriptionEn: 'Normal damage: no resistance or fragility applied.',
    ),
    DamageModifierOption(
      name: 'Resistenza Leggera',
      multiplier: 0.90,
      descriptionIt: 'Resistenza leggera: il danno si riduce del 10%.',
      descriptionEn: 'Light resistance: damage is reduced by 10%.',
    ),
    DamageModifierOption(
      name: 'Resistenza',
      multiplier: 0.75,
      descriptionIt: 'Resistenza: il danno si riduce del 25%.',
      descriptionEn: 'Resistance: damage is reduced by 25%.',
    ),
    DamageModifierOption(
      name: 'Alta Resistenza',
      multiplier: 0.50,
      descriptionIt: 'Alta resistenza: il danno si riduce del 50%.',
      descriptionEn: 'High resistance: damage is reduced by 50%.',
    ),
    DamageModifierOption(
      name: 'Resistenza Semi Perfetta',
      multiplier: 0.25,
      descriptionIt: 'Resistenza semi perfetta: il danno si riduce del 75%.',
      descriptionEn: 'Semi-perfect resistance: damage is reduced by 75%.',
    ),
    DamageModifierOption(
      name: 'Resistenza Impenetrabile',
      multiplier: 0.10,
      descriptionIt: 'Resistenza impenetrabile: il danno si riduce del 90%.',
      descriptionEn: 'Impenetrable resistance: damage is reduced by 90%.',
    ),
    DamageModifierOption(
      name: 'Immunità',
      multiplier: 0.00,
      descriptionIt: 'Immunità: nessun danno subito.',
      descriptionEn: 'Immunity: no damage is taken.',
    ),
    DamageModifierOption(
      name: 'Rigenerazione Leggera',
      multiplier: -0.10,
      descriptionIt: 'Rigeneri il 10% del danno totale.',
      descriptionEn: 'You regenerate 10% of the total damage.',
    ),
    DamageModifierOption(
      name: 'Rigenerazione',
      multiplier: -0.25,
      descriptionIt: 'Rigeneri il 25% del danno totale.',
      descriptionEn: 'You regenerate 25% of the total damage.',
    ),
    DamageModifierOption(
      name: 'Alta Rigenerazione',
      multiplier: -0.50,
      descriptionIt: 'Rigeneri il 50% del danno totale.',
      descriptionEn: 'You regenerate 50% of the total damage.',
    ),
    DamageModifierOption(
      name: 'Rigenerazione Molto Forte',
      multiplier: -0.75,
      descriptionIt: 'Rigeneri il 75% del danno totale.',
      descriptionEn: 'You regenerate 75% of the total damage.',
    ),
    DamageModifierOption(
      name: 'Rigenerazione Semi Perfetta',
      multiplier: -0.90,
      descriptionIt: 'Rigeneri il 90% del danno totale.',
      descriptionEn: 'You regenerate 90% of the total damage.',
    ),
    DamageModifierOption(
      name: 'Rigenerazione Perfetta',
      multiplier: -1.00,
      descriptionIt: 'Rigeneri il 100% del danno totale.',
      descriptionEn: 'You regenerate 100% of the total damage.',
    ),
  ];

  final List<ColorOption> palette = [
    ColorOption(
      name: 'Pergamena Lunare',
      category: 'Chiari',
      color: Color(0xFFE6D8BD),
    ),
    ColorOption(
      name: 'Nero Abisso',
      category: 'Scuri',
      color: Color(0xFF050408),
    ),
    ColorOption(
      name: 'Ebano Vinaccia',
      category: 'Scuri',
      color: Color(0xFF13080F),
    ),
    ColorOption(
      name: 'Oro Reliquia',
      category: 'Oro',
      color: Color(0xFF9E6B2F),
    ),
    ColorOption(
      name: 'Rosso Sigillo',
      category: 'Rosso',
      color: Color(0xFF8F1D2C),
    ),
    ColorOption(
      name: 'Verde Strega',
      category: 'Verde',
      color: Color(0xFF4FB477),
    ),
    ColorOption(
      name: 'Acciaio Freddo',
      category: 'Blu',
      color: Color(0xFF6F89A8),
    ),
    ColorOption(
      name: 'Porpora Maledetta',
      category: 'Viola',
      color: Color(0xFF6C3A77),
    ),
    ColorOption(
      name: 'Ambra Candela',
      category: 'Oro',
      color: Color(0xFFD7A54B),
    ),
    ColorOption(
      name: 'Grigio Cenere',
      category: 'Grigi',
      color: Color(0xFF77736B),
    ),
  ];

  final List<OculumColorPreset> colorPresets = const [
    OculumColorPreset(
      id: 'classic_reliquary',
      nameIt: 'Classic Oculum',
      nameEn: 'Classic Oculum',
      descriptionIt: 'Layout base, colori storici, nessuna decorazione.',
      descriptionEn: 'Base layout, legacy colors, no decorations.',
      primary: Color(0xFFE6D8BD),
      secondary: Color(0xFF08050B),
      tertiary: Color(0xFF9E6B2F),
      utility: Color(0xFFD8D8D8),
      oculumFormula: Color(0xFF8B5CF6),
      backgroundTop: Color(0xFF06070C),
      backgroundMid: Color(0xFF10121A),
      backgroundBottom: Color(0xFF07080D),
      eyePupilGlow: Color(0xFFB84A28),
    ),
    OculumColorPreset(
      id: 'classic_rpg',
      nameIt: 'Classic RPG',
      nameEn: 'Classic RPG',
      descriptionIt:
          'Tema fantasy avanzato: pergamena scura, bordi dorati e separazione JRPG.',
      descriptionEn:
          'Advanced fantasy theme: dark parchment, gold borders and JRPG separation.',
      primary: Color(0xFFE8DCC2),
      secondary: Color(0xFF2A241E),
      tertiary: Color(0xFFC9A44C),
      utility: Color(0xFF7A4B2B),
      oculumFormula: Color(0xFFC9A44C),
      backgroundTop: Color(0xFF1E1A16),
      backgroundMid: Color(0xFF2A241E),
      backgroundBottom: Color(0xFF1E1A16),
      eyePupilGlow: Color(0xFFC9A44C),
    ),
    OculumColorPreset(
      id: 'classic_low_detail',
      nameIt: 'Classic low detail',
      nameEn: 'Classic low detail',
      descriptionIt:
          'Versione leggera: pannelli semplici, meno glow e nessun disegno.',
      descriptionEn: 'Light version: simple panels, less glow and no drawings.',
      primary: Color(0xFFE6D8BD),
      secondary: Color(0xFF08050B),
      tertiary: Color(0xFF9E6B2F),
      utility: Color(0xFFD8D8D8),
      oculumFormula: Color(0xFF8B5CF6),
      backgroundTop: Color(0xFF06070C),
      backgroundMid: Color(0xFF10121A),
      backgroundBottom: Color(0xFF07080D),
      eyePupilGlow: Color(0xFFB84A28),
    ),
    OculumColorPreset(
      id: 'blood_court',
      nameIt: 'Corte di sangue',
      nameEn: 'Blood court',
      descriptionIt: 'Rosso, oro spento e nero per schede aggressive.',
      descriptionEn: 'Red, muted gold and black for aggressive sheets.',
      primary: Color(0xFFFFD8B0),
      secondary: Color(0xFF090509),
      tertiary: Color(0xFFB93A46),
      utility: Color(0xFFE1A45C),
      oculumFormula: Color(0xFFE36B82),
      backgroundTop: Color(0xFF0A0305),
      backgroundMid: Color(0xFF1B070C),
      backgroundBottom: Color(0xFF050103),
      eyePupilGlow: Color(0xFFE24D2F),
    ),
    OculumColorPreset(
      id: 'witch_glass',
      nameIt: 'Vetro strega',
      nameEn: 'Witch glass',
      descriptionIt: 'Verde rituale, ciano e ombre pulite.',
      descriptionEn: 'Ritual green, cyan and clean shadows.',
      primary: Color(0xFFD6F5E7),
      secondary: Color(0xFF050A0A),
      tertiary: Color(0xFF42C78F),
      utility: Color(0xFF7EE7C8),
      oculumFormula: Color(0xFF59DCE2),
      backgroundTop: Color(0xFF030807),
      backgroundMid: Color(0xFF081A14),
      backgroundBottom: Color(0xFF020505),
      eyePupilGlow: Color(0xFFB75B28),
    ),
    OculumColorPreset(
      id: 'moon_iron',
      nameIt: 'Ferro lunare',
      nameEn: 'Moon iron',
      descriptionIt: 'Acciaio freddo, luna e oro minimale.',
      descriptionEn: 'Cold steel, moonlight and restrained gold.',
      primary: Color(0xFFE4E8F2),
      secondary: Color(0xFF060812),
      tertiary: Color(0xFF7D92B8),
      utility: Color(0xFFC9A85A),
      oculumFormula: Color(0xFFAEBBFF),
      backgroundTop: Color(0xFF05070E),
      backgroundMid: Color(0xFF111827),
      backgroundBottom: Color(0xFF030409),
      eyePupilGlow: Color(0xFFC96332),
    ),
    OculumColorPreset(
      id: 'lunar_eclipse',
      nameIt: 'Eclissi lunare',
      nameEn: 'Lunar eclipse',
      descriptionIt:
          'Lilla, indaco e lune laterali per scene notturne ed eleganti.',
      descriptionEn: 'Lilac, indigo and side moons for elegant night scenes.',
      primary: Color(0xFFF0E8FF),
      secondary: Color(0xFF070517),
      tertiary: Color(0xFF9D7BFF),
      utility: Color(0xFFB7A6FF),
      oculumFormula: Color(0xFFC7A7FF),
      backgroundTop: Color(0xFF050414),
      backgroundMid: Color(0xFF16113D),
      backgroundBottom: Color(0xFF03020B),
      eyePupilGlow: Color(0xFFDED0FF),
    ),
    OculumColorPreset(
      id: 'cathedral_rose',
      nameIt: 'Rosa cattedrale',
      nameEn: 'Cathedral rose',
      descriptionIt: 'Vetrate gotiche, magenta profondo e oro antico.',
      descriptionEn: 'Gothic stained glass, deep magenta and antique gold.',
      primary: Color(0xFFFFE6F4),
      secondary: Color(0xFF08040B),
      tertiary: Color(0xFFC74A8B),
      utility: Color(0xFFD8B36A),
      oculumFormula: Color(0xFFFF8BD4),
      backgroundTop: Color(0xFF07030A),
      backgroundMid: Color(0xFF22101D),
      backgroundBottom: Color(0xFF050207),
      eyePupilGlow: Color(0xFFE0B65A),
    ),
    OculumColorPreset(
      id: 'thorn_vigil',
      nameIt: 'Veglia di rovi',
      nameEn: 'Thorn vigil',
      descriptionIt: 'Rovi rituali, verde scuro e rosso sigillo.',
      descriptionEn: 'Ritual thorns, dark green and seal red.',
      primary: Color(0xFFE8F4DC),
      secondary: Color(0xFF030805),
      tertiary: Color(0xFF5FA06A),
      utility: Color(0xFFC24E5E),
      oculumFormula: Color(0xFF90D88F),
      backgroundTop: Color(0xFF030604),
      backgroundMid: Color(0xFF0D1D12),
      backgroundBottom: Color(0xFF010302),
      eyePupilGlow: Color(0xFFD5545A),
    ),
    OculumColorPreset(
      id: 'frost_chapel',
      nameIt: 'Cappella di brina',
      nameEn: 'Frost chapel',
      descriptionIt: 'Cristalli freddi, azzurro e bianco lunare.',
      descriptionEn: 'Cold crystals, pale blue and moon white.',
      primary: Color(0xFFEAF8FF),
      secondary: Color(0xFF030910),
      tertiary: Color(0xFF74C7E8),
      utility: Color(0xFFAFC8FF),
      oculumFormula: Color(0xFF91E5FF),
      backgroundTop: Color(0xFF02070D),
      backgroundMid: Color(0xFF0A1A28),
      backgroundBottom: Color(0xFF010409),
      eyePupilGlow: Color(0xFFBEEBFF),
    ),
    OculumColorPreset(
      id: 'obsidian_sigil',
      nameIt: 'Sigillo ossidiana',
      nameEn: 'Obsidian sigil',
      descriptionIt: 'Nero lucido, viola cupo e sigilli ai margini.',
      descriptionEn: 'Glossy black, deep violet and edge sigils.',
      primary: Color(0xFFF2E7FF),
      secondary: Color(0xFF020206),
      tertiary: Color(0xFF6F42C1),
      utility: Color(0xFF8A8EA3),
      oculumFormula: Color(0xFFB35CFF),
      backgroundTop: Color(0xFF020207),
      backgroundMid: Color(0xFF0B0718),
      backgroundBottom: Color(0xFF010104),
      eyePupilGlow: Color(0xFFB07CFF),
    ),
    OculumColorPreset(
      id: 'solar_reliquary',
      nameIt: 'Reliquiario solare',
      nameEn: 'Solar reliquary',
      descriptionIt: 'Oro caldo, rosso candela e cornici sacre.',
      descriptionEn: 'Warm gold, candle red and sacred frames.',
      primary: Color(0xFFFFEAC4),
      secondary: Color(0xFF090504),
      tertiary: Color(0xFFD59B3C),
      utility: Color(0xFFE96D45),
      oculumFormula: Color(0xFFFFC45C),
      backgroundTop: Color(0xFF090503),
      backgroundMid: Color(0xFF1B1007),
      backgroundBottom: Color(0xFF040201),
      eyePupilGlow: Color(0xFFFFB23A),
    ),
    OculumColorPreset(
      id: 'storm_cathedral',
      nameIt: 'Cattedrale tempesta',
      nameEn: 'Storm cathedral',
      descriptionIt:
          'Indaco, ciano elettrico, pioggia sottile e fulmini rituali.',
      descriptionEn: 'Indigo, electric cyan, thin rain and ritual lightning.',
      primary: Color(0xFFE6F6FF),
      secondary: Color(0xFF030814),
      tertiary: Color(0xFF4DB7FF),
      utility: Color(0xFF9B7CFF),
      oculumFormula: Color(0xFF75E6FF),
      backgroundTop: Color(0xFF020716),
      backgroundMid: Color(0xFF0A1730),
      backgroundBottom: Color(0xFF01040C),
      eyePupilGlow: Color(0xFF6DE7FF),
    ),
    OculumColorPreset(
      id: 'abyssal_tide',
      nameIt: 'Marea abissale',
      nameEn: 'Abyssal tide',
      descriptionIt: 'Onde scure, turchese e perle luminose ai margini.',
      descriptionEn: 'Dark waves, turquoise and glowing pearls at the edges.',
      primary: Color(0xFFE3FFF9),
      secondary: Color(0xFF020B10),
      tertiary: Color(0xFF35BFAF),
      utility: Color(0xFF68A7FF),
      oculumFormula: Color(0xFF74F1E2),
      backgroundTop: Color(0xFF02080E),
      backgroundMid: Color(0xFF06202A),
      backgroundBottom: Color(0xFF010509),
      eyePupilGlow: Color(0xFF69D7FF),
    ),
    OculumColorPreset(
      id: 'ember_rite',
      nameIt: 'Rito di brace',
      nameEn: 'Ember rite',
      descriptionIt: 'Rosso brace, oro bruciato, candele e scintille laterali.',
      descriptionEn: 'Ember red, burnt gold, candles and side sparks.',
      primary: Color(0xFFFFE0BA),
      secondary: Color(0xFF0A0302),
      tertiary: Color(0xFFE06B2E),
      utility: Color(0xFFFFB04A),
      oculumFormula: Color(0xFFFF825C),
      backgroundTop: Color(0xFF090302),
      backgroundMid: Color(0xFF221006),
      backgroundBottom: Color(0xFF040100),
      eyePupilGlow: Color(0xFFFF6A30),
    ),
    OculumColorPreset(
      id: 'ivory_archive',
      nameIt: 'Archivio d avorio',
      nameEn: 'Ivory archive',
      descriptionIt: 'Pergamena scura, avorio, inchiostro e glifi ordinati.',
      descriptionEn: 'Dark parchment, ivory, ink and ordered glyphs.',
      primary: Color(0xFFF4E8D0),
      secondary: Color(0xFF070604),
      tertiary: Color(0xFFC3A36A),
      utility: Color(0xFF8FA8B8),
      oculumFormula: Color(0xFFD8C07A),
      backgroundTop: Color(0xFF070604),
      backgroundMid: Color(0xFF17120B),
      backgroundBottom: Color(0xFF030302),
      eyePupilGlow: Color(0xFFD6B15F),
    ),
    OculumColorPreset(
      id: 'vervain_gothic',
      nameIt: 'Vervain',
      nameEn: 'Vervain',
      descriptionIt:
          'Botanico gotico: rovi vivi, fiori lilla e verde muschio inquieto.',
      descriptionEn:
          'Gothic botanical: living thorns, lilac flowers and restless moss.',
      primary: Color(0xFFEAD7F2),
      secondary: Color(0xFF07110B),
      tertiary: Color(0xFF78A85F),
      utility: Color(0xFFB56FA5),
      oculumFormula: Color(0xFFD78ACD),
      backgroundTop: Color(0xFF050807),
      backgroundMid: Color(0xFF102015),
      backgroundBottom: Color(0xFF1A0C20),
      eyePupilGlow: Color(0xFFB96ED7),
    ),
    OculumColorPreset(
      id: 'kingi_wrong_future',
      nameIt: 'Kingi',
      nameEn: 'Kingi',
      descriptionIt:
          'Futuro sbagliato: ferro, rune azzurre e macchina rituale.',
      descriptionEn: 'Wrong future: iron, blue runes and ritual machinery.',
      primary: Color(0xFF78CFFF),
      secondary: Color(0xFF05080D),
      tertiary: Color(0xFFE7A354),
      utility: Color(0xFFA9D7E8),
      oculumFormula: Color(0xFF45E7FF),
      backgroundTop: Color(0xFF020713),
      backgroundMid: Color(0xFF161B22),
      backgroundBottom: Color(0xFF031226),
      eyePupilGlow: Color(0xFF34D6FF),
    ),
    OculumColorPreset(
      id: 'blood_chapel',
      nameIt: 'Cappella di sangue',
      nameEn: 'Blood chapel',
      descriptionIt: 'Altari, candele, oro sporco e vetrate rotte.',
      descriptionEn: 'Altars, candles, dirty gold and broken stained glass.',
      primary: Color(0xFFFFD9C4),
      secondary: Color(0xFF080204),
      tertiary: Color(0xFFB0182B),
      utility: Color(0xFFB88735),
      oculumFormula: Color(0xFFFF5B61),
      backgroundTop: Color(0xFF070102),
      backgroundMid: Color(0xFF26050B),
      backgroundBottom: Color(0xFF120104),
      eyePupilGlow: Color(0xFFE13D2E),
    ),
    OculumColorPreset(
      id: 'null_crown',
      nameIt: 'Corona nulla',
      nameEn: 'Null crown',
      descriptionIt: 'Nero assoluto, corone spezzate e vuoti nella realtà.',
      descriptionEn: 'Absolute black, broken crowns and gaps in reality.',
      primary: Color(0xFFE1D8EF),
      secondary: Color(0xFF010104),
      tertiary: Color(0xFF4A3B63),
      utility: Color(0xFF72717C),
      oculumFormula: Color(0xFF9274B8),
      backgroundTop: Color(0xFF010104),
      backgroundMid: Color(0xFF090711),
      backgroundBottom: Color(0xFF000001),
      eyePupilGlow: Color(0xFF77649B),
    ),
    OculumColorPreset(
      id: 'phobia_dark',
      nameIt: 'Phobia',
      nameEn: 'Phobia',
      descriptionIt:
          'Horror-HUD compatto: pannelli spezzati, retina fredda e ferite neon.',
      descriptionEn:
          'Compact horror HUD: broken panels, cold retina and neon wounds.',
      primary: Color(0xFFEAF4EF),
      secondary: Color(0xFF02070A),
      tertiary: Color(0xFFB3183E),
      utility: Color(0xFF25C6B8),
      oculumFormula: Color(0xFFFF4E74),
      backgroundTop: Color(0xFF010608),
      backgroundMid: Color(0xFF071822),
      backgroundBottom: Color(0xFF000101),
      eyePupilGlow: Color(0xFFFF335F),
    ),
    OculumColorPreset(
      id: 'whispering_reliquary',
      nameIt: 'Reliquiario dei sussurri',
      nameEn: 'Whispering reliquary',
      descriptionIt:
          'Horror occulto: osso antico, sangue secco, vetro annerito e simboli appena visibili.',
      descriptionEn:
          'Occult horror: old bone, dried blood, blackened glass and barely visible symbols.',
      primary: Color(0xFFE7DDC9),
      secondary: Color(0xFF050304),
      tertiary: Color(0xFFB94A58),
      utility: Color(0xFF9BAA78),
      oculumFormula: Color(0xFFD46A73),
      backgroundTop: Color(0xFF080405),
      backgroundMid: Color(0xFF16090D),
      backgroundBottom: Color(0xFF020102),
      eyePupilGlow: Color(0xFFC6324B),
    ),
    OculumColorPreset(
      id: 'black_briar_kingdom',
      nameIt: 'Regno del rovo nero',
      nameEn: 'Black briar kingdom',
      descriptionIt:
          'Dark fantasy regale: ferro annerito, oro consunto, rovi, brace e luna d argento.',
      descriptionEn:
          'Royal dark fantasy: blackened iron, worn gold, briars, embers and a silver moon.',
      primary: Color(0xFFD9D4C8),
      secondary: Color(0xFF030504),
      tertiary: Color(0xFFC39A52),
      utility: Color(0xFF8D4540),
      oculumFormula: Color(0xFFD5B365),
      backgroundTop: Color(0xFF050706),
      backgroundMid: Color(0xFF0D1512),
      backgroundBottom: Color(0xFF020302),
      eyePupilGlow: Color(0xFFB5443E),
    ),
    OculumColorPreset(
      id: 'slime_prince',
      nameIt: 'Principe slime',
      nameEn: 'Slime prince',
      descriptionIt: 'Gelatina verde, oro e viola regale dark fantasy.',
      descriptionEn: 'Green gel, gold and royal violet dark fantasy.',
      primary: Color(0xFFE8FFD4),
      secondary: Color(0xFF041008),
      tertiary: Color(0xFF69D64A),
      utility: Color(0xFFD2A43A),
      oculumFormula: Color(0xFF8DFF66),
      backgroundTop: Color(0xFF031007),
      backgroundMid: Color(0xFF163914),
      backgroundBottom: Color(0xFF140A22),
      eyePupilGlow: Color(0xFFD3B74B),
    ),
    OculumColorPreset(
      id: 'moon_rot',
      nameIt: 'Luna marcia',
      nameEn: 'Moon rot',
      descriptionIt: 'Luna pallida, muffe verdi, spore e crateri malati.',
      descriptionEn: 'Pale moon, green mold, spores and sick craters.',
      primary: Color(0xFFE7F0C8),
      secondary: Color(0xFF05060A),
      tertiary: Color(0xFF8DAA55),
      utility: Color(0xFF7B5AA0),
      oculumFormula: Color(0xFFB8D36A),
      backgroundTop: Color(0xFF06070A),
      backgroundMid: Color(0xFF1B2130),
      backgroundBottom: Color(0xFF081007),
      eyePupilGlow: Color(0xFFB6D36D),
    ),
    OculumColorPreset(
      id: 'obser_relic',
      nameIt: 'Reliquia Obser',
      nameEn: 'Obser relic',
      descriptionIt: 'Pietra scura, occhio inciso, oro antico e polvere.',
      descriptionEn: 'Dark stone, carved eye, ancient gold and dust.',
      primary: Color(0xFFE0D1A6),
      secondary: Color(0xFF070707),
      tertiary: Color(0xFF927235),
      utility: Color(0xFF5F636B),
      oculumFormula: Color(0xFFC29B42),
      backgroundTop: Color(0xFF080806),
      backgroundMid: Color(0xFF17130B),
      backgroundBottom: Color(0xFF050504),
      eyePupilGlow: Color(0xFFD8A947),
    ),
    OculumColorPreset(
      id: 'deep_forest_demon',
      nameIt: 'Demone del bosco profondo',
      nameEn: 'Deep forest demon',
      descriptionIt: 'Radici, denti, occhi nel bosco e verde nerastro.',
      descriptionEn: 'Roots, teeth, eyes in the woods and blackened green.',
      primary: Color(0xFFE0E8CC),
      secondary: Color(0xFF030703),
      tertiary: Color(0xFF2F5E35),
      utility: Color(0xFF7F2D2D),
      oculumFormula: Color(0xFF7EAA5A),
      backgroundTop: Color(0xFF020502),
      backgroundMid: Color(0xFF0B1609),
      backgroundBottom: Color(0xFF1B0C06),
      eyePupilGlow: Color(0xFFB33A34),
    ),
    OculumColorPreset(
      id: 'astral_ink',
      nameIt: 'Inchiostro astrale',
      nameEn: 'Astral ink',
      descriptionIt: 'Inchiostro nero, stelle liquide e pagine cosmiche.',
      descriptionEn: 'Black ink, liquid stars and cosmic pages.',
      primary: Color(0xFFE4E8FF),
      secondary: Color(0xFF030515),
      tertiary: Color(0xFF3759C8),
      utility: Color(0xFF8F5FE8),
      oculumFormula: Color(0xFF7BA7FF),
      backgroundTop: Color(0xFF010313),
      backgroundMid: Color(0xFF08154A),
      backgroundBottom: Color(0xFF06020F),
      eyePupilGlow: Color(0xFF8BA7FF),
    ),
    OculumColorPreset(
      id: 'bone_saint',
      nameIt: 'Santo d osso',
      nameEn: 'Bone saint',
      descriptionIt: 'Osso, oro pallido, reliquie e aureole rotte.',
      descriptionEn: 'Bone, pale gold, relics and broken halos.',
      primary: Color(0xFFF3EBD8),
      secondary: Color(0xFF070604),
      tertiary: Color(0xFFD0B66A),
      utility: Color(0xFFB7A98A),
      oculumFormula: Color(0xFFE1C872),
      backgroundTop: Color(0xFF080704),
      backgroundMid: Color(0xFF18140D),
      backgroundBottom: Color(0xFF030302),
      eyePupilGlow: Color(0xFFE0C76B),
    ),
    OculumColorPreset(
      id: 'medieval_keep',
      nameIt: 'Mastio medievale',
      nameEn: 'Medieval keep',
      descriptionIt:
          'Tema medievale completo: pietra, ferro, scudi, torri e lume da sala d armi.',
      descriptionEn:
          'Full medieval theme: stone, iron, shields, towers and armory light.',
      primary: Color(0xFFF0E2C2),
      secondary: Color(0xFF090806),
      tertiary: Color(0xFFB7904B),
      utility: Color(0xFF7F2630),
      oculumFormula: Color(0xFFD2B36A),
      backgroundTop: Color(0xFF0A0D0E),
      backgroundMid: Color(0xFF1A1711),
      backgroundBottom: Color(0xFF080605),
      eyePupilGlow: Color(0xFFE0A84A),
    ),
    OculumColorPreset(
      id: 'fortezza_oculum',
      nameIt: 'Fortezza Oculum',
      nameEn: 'Oculum Fortress',
      descriptionIt:
          'Tema premium bloccato: pietra nera, ferro inciso, oro antico e bagliore viola dell Occhio.',
      descriptionEn:
          'Locked premium theme: black stone, carved iron, antique gold and the Eye violet glow.',
      primary: Color(0xFFF1DFC2),
      secondary: Color(0xFF070608),
      tertiary: Color(0xFF9A4DE8),
      utility: Color(0xFFC28B48),
      oculumFormula: Color(0xFFBC6CFF),
      backgroundTop: Color(0xFF030304),
      backgroundMid: Color(0xFF111017),
      backgroundBottom: Color(0xFF050406),
      eyePupilGlow: Color(0xFFB44CFF),
      iconAssetPath: 'assets/oculum/icons/fortezza_oculum_theme.png',
    ),
    OculumColorPreset(
      id: 'hoshy_cosmic_cat',
      nameIt: 'Hoshy gatto cosmico',
      nameEn: 'Hoshy cosmic cat',
      descriptionIt:
          'Tema segreto: galassia blu/viola, orecchie feline e luna indaco.',
      descriptionEn:
          'Secret theme: blue/violet galaxy, cat ears and indigo moon.',
      primary: Color(0xFFF2E9FF),
      secondary: Color(0xFF04051B),
      tertiary: Color(0xFF8D6BFF),
      utility: Color(0xFF4DC7FF),
      oculumFormula: Color(0xFFC48BFF),
      backgroundTop: Color(0xFF030526),
      backgroundMid: Color(0xFF14105A),
      backgroundBottom: Color(0xFF05021B),
      eyePupilGlow: Color(0xFF6B7CFF),
    ),
    OculumColorPreset(
      id: 'ash_oracle',
      nameIt: 'Oracolo di cenere',
      nameEn: 'Ash oracle',
      descriptionIt: 'Grigi caldi e ambra, pensato per lunghe sessioni.',
      descriptionEn: 'Warm greys and amber, built for long sessions.',
      primary: Color(0xFFE0D8C8),
      secondary: Color(0xFF090909),
      tertiary: Color(0xFF9B8A72),
      utility: Color(0xFFE0A94F),
      oculumFormula: Color(0xFFB8A0FF),
      backgroundTop: Color(0xFF080807),
      backgroundMid: Color(0xFF171511),
      backgroundBottom: Color(0xFF050504),
      eyePupilGlow: Color(0xFFD16B35),
    ),
    OculumColorPreset(
      id: 'void_liturgy',
      nameIt: 'Liturgia del vuoto',
      nameEn: 'Void liturgy',
      descriptionIt: 'Contrasto alto, viola controllato e testo chiaro.',
      descriptionEn: 'High contrast, controlled violet and clear text.',
      primary: Color(0xFFF0E8FF),
      secondary: Color(0xFF03040A),
      tertiary: Color(0xFF775CF0),
      utility: Color(0xFF8A95A8),
      oculumFormula: Color(0xFFB28CFF),
      backgroundTop: Color(0xFF03030A),
      backgroundMid: Color(0xFF120C24),
      backgroundBottom: Color(0xFF010106),
      eyePupilGlow: Color(0xFFE05C32),
    ),
    OculumColorPreset(
      id: 'shadow_gate_rank',
      nameIt: 'Porta d ombra',
      nameEn: 'Shadow gate',
      descriptionIt:
          'Tema discreto da ascesa oscura: gate viola, blu elettrico e rango inciso.',
      descriptionEn:
          'Subtle dark ascension theme: violet gate, electric blue and carved rank.',
      primary: Color(0xFFE8EAFF),
      secondary: Color(0xFF03040B),
      tertiary: Color(0xFF6B5CFF),
      utility: Color(0xFF47B6FF),
      oculumFormula: Color(0xFFB58CFF),
      backgroundTop: Color(0xFF01020A),
      backgroundMid: Color(0xFF080C26),
      backgroundBottom: Color(0xFF000005),
      eyePupilGlow: Color(0xFF4D8DFF),
    ),
    OculumColorPreset(
      id: 'postea_bloom',
      nameIt: 'Postea errante',
      nameEn: 'Postea wanderer',
      descriptionIt:
          'Futuro errante dove rune antiche, circuiti e fiori sintetici si fondono.',
      descriptionEn:
          'A wandering future where ancient runes, circuits and synthetic flowers merge.',
      primary: Color(0xFFE8F2FF),
      secondary: Color(0xFF060A10),
      tertiary: Color(0xFF8FB7FF),
      utility: Color(0xFFFF8CCB),
      oculumFormula: Color(0xFF78E0A0),
      backgroundTop: Color(0xFF050811),
      backgroundMid: Color(0xFF0B1820),
      backgroundBottom: Color(0xFF030507),
      eyePupilGlow: Color(0xFF69F08A),
    ),
    OculumColorPreset(
      id: 'karma_duality',
      nameIt: 'Bilancia del karma',
      nameEn: 'Karma scales',
      descriptionIt:
          'Bianco sporco, nero candela e verde occhio per scelte morali.',
      descriptionEn:
          'Bone white, candle black and eye green for moral choices.',
      primary: Color(0xFFF0EDE4),
      secondary: Color(0xFF050506),
      tertiary: Color(0xFF2DCB98),
      utility: Color(0xFFB8A15B),
      oculumFormula: Color(0xFF7EE7C8),
      backgroundTop: Color(0xFF040505),
      backgroundMid: Color(0xFF0C1110),
      backgroundBottom: Color(0xFF020303),
      eyePupilGlow: Color(0xFFE2C15A),
    ),
    OculumColorPreset(
      id: 'monster_lantern',
      nameIt: 'Lanterna dei mostri',
      nameEn: 'Monster lantern',
      descriptionIt:
          'Indaco, ambra e verde foglia per villaggi, Kooba e piccoli NPC.',
      descriptionEn:
          'Indigo, amber and leaf green for villages, Kooba and small NPCs.',
      primary: Color(0xFFE7F0D8),
      secondary: Color(0xFF07070B),
      tertiary: Color(0xFF4F6FD8),
      utility: Color(0xFFE0A94F),
      oculumFormula: Color(0xFF69D38B),
      backgroundTop: Color(0xFF050610),
      backgroundMid: Color(0xFF10131C),
      backgroundBottom: Color(0xFF040407),
      eyePupilGlow: Color(0xFFDAB14A),
    ),
    OculumColorPreset(
      id: 'jrpg_legend',
      nameIt: 'Leggenda JRPG',
      nameEn: 'JRPG legend',
      descriptionIt:
          'Menu cristallino, stelle, oro chiaro e bestiario da grande avventura.',
      descriptionEn:
          'Crystal menu, stars, pale gold and a grand-adventure bestiary.',
      primary: Color(0xFFF4EFD7),
      secondary: Color(0xFF050816),
      tertiary: Color(0xFF4C83F2),
      utility: Color(0xFFE7B84A),
      oculumFormula: Color(0xFF83E8FF),
      backgroundTop: Color(0xFF04071A),
      backgroundMid: Color(0xFF10204A),
      backgroundBottom: Color(0xFF070414),
      eyePupilGlow: Color(0xFFFF8B78),
    ),
    OculumColorPreset(
      id: 'rogue_mutation',
      nameIt: 'Mutazione Roguelike',
      nameEn: 'Roguelike mutation',
      descriptionIt:
          'Interfaccia sporca da run: melma radioattiva, sangue secco e scarti.',
      descriptionEn:
          'Dirty run interface: radioactive slime, dry blood and scraps.',
      primary: Color(0xFFEAF2C8),
      secondary: Color(0xFF070806),
      tertiary: Color(0xFF87C943),
      utility: Color(0xFFE25A34),
      oculumFormula: Color(0xFFA8E646),
      backgroundTop: Color(0xFF080A06),
      backgroundMid: Color(0xFF17210B),
      backgroundBottom: Color(0xFF070404),
      eyePupilGlow: Color(0xFFE6543A),
    ),
    OculumColorPreset(
      id: 'cell_crimson_run',
      nameIt: 'Cella cremisi',
      nameEn: 'Crimson cell',
      descriptionIt:
          'Run laterale rapida: rosso vivo, viola scuro e cornici nervose.',
      descriptionEn:
          'Fast side-run mood: live red, dark violet and nervous frames.',
      primary: Color(0xFFFFE6DC),
      secondary: Color(0xFF08040A),
      tertiary: Color(0xFFD63A56),
      utility: Color(0xFF6DD4FF),
      oculumFormula: Color(0xFFFF557A),
      backgroundTop: Color(0xFF09030A),
      backgroundMid: Color(0xFF260814),
      backgroundBottom: Color(0xFF040208),
      eyePupilGlow: Color(0xFF69D6FF),
    ),
    OculumColorPreset(
      id: 'darkest_stagecoach',
      nameIt: 'Carrozza cupa',
      nameEn: 'Dark stagecoach',
      descriptionIt:
          'Roguelike gotico: pergamena sporca, rosso candela e ombre pesanti.',
      descriptionEn:
          'Gothic roguelike: stained parchment, candle red and heavy shadows.',
      primary: Color(0xFFE8D6B2),
      secondary: Color(0xFF080504),
      tertiary: Color(0xFF9C2832),
      utility: Color(0xFFD39A42),
      oculumFormula: Color(0xFFC23C35),
      backgroundTop: Color(0xFF080504),
      backgroundMid: Color(0xFF1A0B08),
      backgroundBottom: Color(0xFF030201),
      eyePupilGlow: Color(0xFFD8A448),
    ),
    OculumColorPreset(
      id: 'ashen_covenant',
      nameIt: 'Patto di cenere',
      nameEn: 'Ashen covenant',
      descriptionIt:
          'UI da boss lento: cenere, brace quasi spenta e metallo sacro.',
      descriptionEn: 'Slow boss UI: ash, almost-dead embers and sacred metal.',
      primary: Color(0xFFE0D6C6),
      secondary: Color(0xFF060606),
      tertiary: Color(0xFF8E7864),
      utility: Color(0xFFC76832),
      oculumFormula: Color(0xFFE09A4A),
      backgroundTop: Color(0xFF060606),
      backgroundMid: Color(0xFF17120E),
      backgroundBottom: Color(0xFF030303),
      eyePupilGlow: Color(0xFFE0713A),
    ),
    OculumColorPreset(
      id: 'eclipse_bonfire',
      nameIt: 'Falò d eclissi',
      nameEn: 'Eclipse bonfire',
      descriptionIt:
          'Souls notturno: blu nero, oro pallido e un fuoco che resiste.',
      descriptionEn:
          'Night souls mood: black blue, pale gold and a fire that resists.',
      primary: Color(0xFFECE1BD),
      secondary: Color(0xFF030612),
      tertiary: Color(0xFF526487),
      utility: Color(0xFFE2A14E),
      oculumFormula: Color(0xFF9AAEFF),
      backgroundTop: Color(0xFF02040D),
      backgroundMid: Color(0xFF0B1020),
      backgroundBottom: Color(0xFF020203),
      eyePupilGlow: Color(0xFFFFB65A),
    ),
    OculumColorPreset(
      id: 'bolted_black_iron',
      nameIt: 'Metallo nero bullonato',
      nameEn: 'Bolted black iron',
      descriptionIt:
          'HUD metallico rigido: placche nere, viti e lettura industriale.',
      descriptionEn:
          'Rigid metal HUD: black plates, bolts and industrial readability.',
      primary: Color(0xFFE5E5DF),
      secondary: Color(0xFF050505),
      tertiary: Color(0xFF363A40),
      utility: Color(0xFF9B8F76),
      oculumFormula: Color(0xFF90D8FF),
      backgroundTop: Color(0xFF090A0C),
      backgroundMid: Color(0xFF14171A),
      backgroundBottom: Color(0xFF030303),
      eyePupilGlow: Color(0xFF9BDFFF),
    ),
    OculumColorPreset(
      id: 'bolted_gold_plate',
      nameIt: 'Metallo oro bullonato',
      nameEn: 'Bolted gold plate',
      descriptionIt:
          'Placca dorata pesante: bulloni, bordi neri e luce da reliquia.',
      descriptionEn: 'Heavy gold plate: bolts, black edges and relic light.',
      primary: Color(0xFFFFEDB8),
      secondary: Color(0xFF080603),
      tertiary: Color(0xFFD2A340),
      utility: Color(0xFF2B2B2B),
      oculumFormula: Color(0xFFFFC85A),
      backgroundTop: Color(0xFF0A0803),
      backgroundMid: Color(0xFF241808),
      backgroundBottom: Color(0xFF040302),
      eyePupilGlow: Color(0xFFFFD36A),
    ),
    OculumColorPreset(
      id: 'bolted_copper_oxide',
      nameIt: 'Rame ossidato bullonato',
      nameEn: 'Bolted oxidized copper',
      descriptionIt:
          'Rame, chiazze ossidate e zolle verdi incise nelle placche.',
      descriptionEn:
          'Copper, oxidized stains and green chunks carved into the plates.',
      primary: Color(0xFFFFD7B1),
      secondary: Color(0xFF080504),
      tertiary: Color(0xFFB86B3A),
      utility: Color(0xFF58A07B),
      oculumFormula: Color(0xFF70D5A3),
      backgroundTop: Color(0xFF090604),
      backgroundMid: Color(0xFF231006),
      backgroundBottom: Color(0xFF04100B),
      eyePupilGlow: Color(0xFF69C997),
    ),
    OculumColorPreset(
      id: 'bolted_silver_plate',
      nameIt: 'Metallo argento bullonato',
      nameEn: 'Bolted silver plate',
      descriptionIt:
          'Acciaio chiaro, viti pulite e HUD freddo da laboratorio antico.',
      descriptionEn: 'Bright steel, clean bolts and a cold ancient-lab HUD.',
      primary: Color(0xFFF2F6FF),
      secondary: Color(0xFF05070A),
      tertiary: Color(0xFFAEB8C7),
      utility: Color(0xFF5B86A6),
      oculumFormula: Color(0xFFBFE6FF),
      backgroundTop: Color(0xFF06090D),
      backgroundMid: Color(0xFF151A22),
      backgroundBottom: Color(0xFF030507),
      eyePupilGlow: Color(0xFFC9ECFF),
    ),
    OculumColorPreset(
      id: 'meadow_sprite',
      nameIt: 'Folletto di prato',
      nameEn: 'Meadow sprite',
      descriptionIt:
          'Tema naturale gioioso: erba luminosa, pesca e piccoli spiriti.',
      descriptionEn:
          'Joyful natural theme: luminous grass, peach and small spirits.',
      primary: Color(0xFFF5F5D6),
      secondary: Color(0xFF061108),
      tertiary: Color(0xFF69B86A),
      utility: Color(0xFFFFB07C),
      oculumFormula: Color(0xFF94E68C),
      backgroundTop: Color(0xFF041007),
      backgroundMid: Color(0xFF14351B),
      backgroundBottom: Color(0xFF07120A),
      eyePupilGlow: Color(0xFFFFB68A),
    ),
    OculumColorPreset(
      id: 'aurora_moth',
      nameIt: 'Falena aurora',
      nameEn: 'Aurora moth',
      descriptionIt:
          'Naturale onirico: notte viola, ali luminose e verde rugiada.',
      descriptionEn:
          'Dreamlike natural mood: violet night, glowing wings and dew green.',
      primary: Color(0xFFF0E9FF),
      secondary: Color(0xFF050615),
      tertiary: Color(0xFF8F77FF),
      utility: Color(0xFF67DDA4),
      oculumFormula: Color(0xFFC09BFF),
      backgroundTop: Color(0xFF040518),
      backgroundMid: Color(0xFF171047),
      backgroundBottom: Color(0xFF03110B),
      eyePupilGlow: Color(0xFF75E8B1),
    ),
    OculumColorPreset(
      id: 'modern_school_day',
      nameIt: 'Giorno di scuola',
      nameEn: 'School day',
      descriptionIt:
          'Tema moderno adolescenziale: quaderni scuri, penne colorate, neon urbano e appunti di classe.',
      descriptionEn:
          'Modern adolescent theme: dark notebooks, colored pens, urban neon and class notes.',
      primary: Color(0xFFF4F1E8),
      secondary: Color(0xFF071015),
      tertiary: Color(0xFF57B8D9),
      utility: Color(0xFFFFC857),
      oculumFormula: Color(0xFFFF6B8A),
      backgroundTop: Color(0xFF061119),
      backgroundMid: Color(0xFF112632),
      backgroundBottom: Color(0xFF07090D),
      eyePupilGlow: Color(0xFFFF6B8A),
    ),
    OculumColorPreset(
      id: 'vtt_arcane_table',
      nameIt: 'Tavolo arcano',
      nameEn: 'Arcane tabletop',
      descriptionIt:
          'Tema da tavolo virtuale: griglia sottile, pergamena scura e accenti magenta/ciano.',
      descriptionEn:
          'Virtual tabletop mood: thin grid, dark parchment and magenta/cyan accents.',
      primary: Color(0xFFE9E2D2),
      secondary: Color(0xFF08070B),
      tertiary: Color(0xFF2FC3C7),
      utility: Color(0xFFC15C9E),
      oculumFormula: Color(0xFF7DE8E2),
      backgroundTop: Color(0xFF07080E),
      backgroundMid: Color(0xFF141018),
      backgroundBottom: Color(0xFF050407),
      eyePupilGlow: Color(0xFFE06DB6),
    ),
    OculumColorPreset(
      id: 'vtt_obsidian_grid',
      nameIt: 'Griglia ossidiana',
      nameEn: 'Obsidian grid',
      descriptionIt:
          'Manuale digitale cupo: nero tecnico, linee da mappa e marcatori ambra.',
      descriptionEn:
          'Dark digital manual: technical black, map lines and amber markers.',
      primary: Color(0xFFE7EEF2),
      secondary: Color(0xFF030507),
      tertiary: Color(0xFF54616D),
      utility: Color(0xFFE0A94F),
      oculumFormula: Color(0xFF9DD6FF),
      backgroundTop: Color(0xFF020405),
      backgroundMid: Color(0xFF0D1216),
      backgroundBottom: Color(0xFF030303),
      eyePupilGlow: Color(0xFFFFB85A),
    ),
    OculumColorPreset(
      id: 'vtt_parchment_layers',
      nameIt: 'Strati pergamena',
      nameEn: 'Parchment layers',
      descriptionIt:
          'Scheda da campagna online: carta, inchiostro viola e bordi verde spento.',
      descriptionEn:
          'Online campaign sheet: paper, violet ink and muted green edges.',
      primary: Color(0xFFF2E6C8),
      secondary: Color(0xFF080604),
      tertiary: Color(0xFF7B5C9E),
      utility: Color(0xFF809C68),
      oculumFormula: Color(0xFFC69BE8),
      backgroundTop: Color(0xFF0A0805),
      backgroundMid: Color(0xFF1A130B),
      backgroundBottom: Color(0xFF080B06),
      eyePupilGlow: Color(0xFFC49CFF),
    ),
    OculumColorPreset(
      id: 'vtt_master_overlay',
      nameIt: 'Overlay del Master',
      nameEn: 'Master overlay',
      descriptionIt:
          'HUD da gestione sessione: blu notte, rosso nota critica e bianco da scheda.',
      descriptionEn:
          'Session-management HUD: night blue, critical-note red and sheet white.',
      primary: Color(0xFFEAF0FF),
      secondary: Color(0xFF040716),
      tertiary: Color(0xFF4C6FFF),
      utility: Color(0xFFE05263),
      oculumFormula: Color(0xFF7AA7FF),
      backgroundTop: Color(0xFF030615),
      backgroundMid: Color(0xFF0B1230),
      backgroundBottom: Color(0xFF05030A),
      eyePupilGlow: Color(0xFFFF6A7A),
    ),
    OculumColorPreset(
      id: 'verdigris_mourning',
      nameIt: 'Rame sepolto',
      nameEn: 'Verdigris mourning',
      descriptionIt: 'Gotico elegante, verderame e rame ossidato antico.',
      descriptionEn: 'Elegant gothic, verdigris and ancient oxidized copper.',
      primary: Color(0xFF4A6B62),
      secondary: Color(0xFF140D1B),
      tertiary: Color(0xFFA28D3F),
      utility: Color(0xFF9E5C5C),
      oculumFormula: Color(0xFF6B8B82),
      backgroundTop: Color(0xFF1A2630),
      backgroundMid: Color(0xFF221627),
      backgroundBottom: Color(0xFF2E1F18),
      eyePupilGlow: Color(0xFF7CB819),
    ),
  ];

  bool hasNetworkLink(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }

  Future<void> applicaStatoConnessioneOnline(
    List<ConnectivityResult> results,
  ) async {
    final hasLink = hasNetworkLink(results);
    final probeOk = hasLink ? await hasInternetAccess() : false;
    final disponibile = hasLink || probeOk;

    if (!mounted) return;

    setState(() {
      onlineDisponibile = disponibile;
      onlineCheckInCorso = false;

      if (!onlineDisponibile) {
        risultato = t(
          'Connessione non verificata: la pagina Online resta disponibile e mostrera eventuali errori reali dei servizi live.',
          'Connection not verified: the Online page remains available and will show actual live-service errors.',
        );
        aggiungiLog(risultato);
      }
    });
  }

  Future<void> controllaConnessioneOnline() async {
    if (!mounted) return;

    setState(() {
      onlineCheckInCorso = true;
    });

    try {
      final results = await Connectivity().checkConnectivity();
      await applicaStatoConnessioneOnline(results);
    } catch (_) {
      final disponibile = await hasInternetAccess();

      if (!mounted) return;

      setState(() {
        onlineDisponibile = disponibile;
        onlineCheckInCorso = false;
      });
    }
  }

  void avviaControlloConnessioneOnline() {
    controllaConnessioneOnline();

    connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (results) {
        applicaStatoConnessioneOnline(results);
      },
      onError: (_) async {
        final disponibile = await hasInternetAccess();

        if (!mounted) return;
        setState(() {
          onlineDisponibile = disponibile;
          onlineCheckInCorso = false;
        });
      },
    );
  }

  List<int> visiblePageIndexes({bool includeSettings = true}) {
    final indexes = <int>[
      0,
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
      9,
      mapPageIndex,
      if (includeSettings) settingsPageIndex,
      onlinePageIndex,
      recipesPageIndex,
    ];

    return indexes;
  }

  int paginaVisibileSicura(int page) {
    if (page == dicePageIndex) return dicePageIndex;
    return page;
  }

  bool _isPagePreparedForDisplay(int page) {
    return page == 0 || _preparedPageIndexes.contains(page);
  }

  void _scheduleLazyPageActivation(int page) {
    if (_isPagePreparedForDisplay(page)) return;
    if (_lazyPageActivationScheduledFor == page) return;

    _lazyPageActivationScheduledFor = page;
    _lazyPageActivationTimer?.cancel();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || paginaVisibileSicura(paginaCorrente) != page) {
        if (_lazyPageActivationScheduledFor == page) {
          _lazyPageActivationScheduledFor = null;
        }
        return;
      }

      _lazyPageActivationTimer = Timer(const Duration(milliseconds: 24), () {
        if (!mounted || paginaVisibileSicura(paginaCorrente) != page) {
          if (_lazyPageActivationScheduledFor == page) {
            _lazyPageActivationScheduledFor = null;
          }
          return;
        }
        setState(() {
          _preparedPageIndexes.add(page);
          if (_lazyPageActivationScheduledFor == page) {
            _lazyPageActivationScheduledFor = null;
          }
        });
      });
    });
  }

  Future<void> _waitForLazyPageActivation(int page) async {
    for (var attempt = 0; attempt < 8; attempt++) {
      if (!mounted ||
          paginaVisibileSicura(paginaCorrente) != page ||
          _isPagePreparedForDisplay(page)) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 35));
    }
  }

  Widget pageLoadingPlaceholder(int page) {
    final labels = linguaInglese ? pageNamesEn : pageNamesIt;
    final label = page >= 0 && page < labels.length
        ? cleanUiText(labels[page])
        : t('Pagina', 'Page');

    return Center(
      key: ValueKey<String>('page_loading_$page'),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: gothicPanel(
          borderColor: tertiaryColor.withValues(alpha: 0.55),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: tertiaryColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              smallInfoText(
                t(
                  'Preparazione rapida della sezione...',
                  'Preparing section...',
                ),
                color: Colors.grey.shade300,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget homeDataLoadingPlaceholder() {
    return Center(
      key: const ValueKey<String>('home_data_loading'),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: gothicPanel(
          borderColor: primaryColor.withValues(alpha: 0.55),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                t('Caricamento salvataggi...', 'Loading saves...'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              smallInfoText(
                t(
                  'Oculum sta preparando dati locali, cache e scheda attiva.',
                  'Oculum is preparing local data, cache and active sheet.',
                ),
                color: Colors.grey.shade300,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildCurrentPageLazy(int page) {
    if (!_isPagePreparedForDisplay(page)) {
      _scheduleLazyPageActivation(page);
      return pageLoadingPlaceholder(page);
    }

    return KeyedSubtree(
      key: ValueKey<String>('page_ready_${currentSheetScrollId()}_$page'),
      child: buildCurrentPage(page),
    );
  }

  Widget buildCurrentPage(int page) {
    switch (page) {
      case 0:
        return characterPage();
      case 1:
        return restPage();
      case 2:
        return titlesPageEfficient();
      case 3:
        return artDataPage();
      case 4:
        return skillsPage();
      case 5:
        return backgroundAndSkillsPageEfficient();
      case 6:
        return inventoryPageEfficient();
      case 7:
        return resourcesPage();
      case 8:
        return rulesPageEfficient();
      case 9:
        return masterDashboardPage();
      case mapPageIndex:
        return mapPage();
      case settingsPageIndex:
        return settingsPage();
      case onlinePageIndex:
        return onlinePage();
      case dicePageIndex:
        return dicePage();
      case recipesPageIndex:
        return recipesPage();
      default:
        return characterPage();
    }
  }

  // =====================================================
  // STATO AUTOSAVE / COLORI / FILTRI
  // =====================================================

  // =====================================================
  // INIT / SAVE / LOAD
  // =====================================================

  void updateOculumHomeUi(VoidCallback callback) {
    if (!mounted) return;
    setState(callback);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    assicuraArtiBase();
    unawaited(
      caricaDati().then((_) {
        if (!mounted) return;
        setState(() {
          modalitaMaster = oculumStartupRole == OculumStartupRole.master;
        });
      }),
    );
    avviaControlloConnessioneOnline();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final autosaveWasPending =
          (autosaveTimer?.isActive ?? false) ||
          autosavePendingAfterFocusTransition;
      appOculumInBackground = false;
      lifecycleLocalSaveTimer?.cancel();
      lifecycleLocalSaveTimer = null;
      lifecycleFocusSettleTimer?.cancel();
      if (autosaveWasPending) {
        autosavePendingAfterFocusTransition = true;
      }
      scheduleOculumFocusSettled();
      return;
    }

    if (state == AppLifecycleState.inactive) {
      beginOculumFocusTransition();
      return;
    }

    if (state == AppLifecycleState.detached) {
      beginOculumFocusTransition();
      appOculumInBackground = true;
      lifecycleLocalSaveTimer?.cancel();
      lifecycleLocalSaveTimer = null;
      unawaited(forzaSalvataggioImmediato(soloLocale: true));
      return;
    }

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      beginOculumFocusTransition();
      appOculumInBackground = true;
      lifecycleLocalSaveTimer?.cancel();
      lifecycleLocalSaveTimer = Timer(const Duration(seconds: 45), () {
        if (!mounted ||
            !appOculumInBackground ||
            !datiCaricati ||
            salvataggioInCorso ||
            salvataggioBloccatoPerErrore) {
          return;
        }
        unawaited(forzaSalvataggioImmediato(soloLocale: true));
      });
    }
  }

  // LIFECYCLE / BUILD
  // =====================================================

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    salvataggioInChiusura = true;
    if (datiCaricati) {
      salvaSchedaCorrenteInMemoria();
      saveActiveCampaignInMemory();
    }
    unawaited(forzaSalvataggioImmediato(soloLocale: true));
    autosaveTimer?.cancel();
    dadoOverlayTimer?.cancel();
    dadoOverlayRevealTimer?.cancel();
    _lazyPageActivationTimer?.cancel();
    lifecycleLocalSaveTimer?.cancel();
    lifecycleFocusSettleTimer?.cancel();
    relayHeartbeatTimer?.cancel();
    relayReconnectTimer?.cancel();
    relayLobbyRefreshTimer?.cancel();
    realtimeOculumDebounceTimer?.cancel();
    realtimeSheetShareDebounceTimer?.cancel();
    realtimeReconnectTimer?.cancel();
    hiddenEyeProgressSaveTimer?.cancel();
    progressJournalSaveTimer?.cancel();
    storySessionNotesSaveTimer?.cancel();
    vttRealtimeDebounceTimer?.cancel();
    vttPingCleanupTimer?.cancel();
    for (final timer in realtimePendingMasterAckTimers.values) {
      timer.cancel();
    }
    realtimePendingMasterAckTimers.clear();
    inputUiRefreshTimer?.cancel();
    connectivitySubscription?.cancel();
    unawaited(realtimeService?.dispose());

    nomeController.dispose();
    tipoSchedaController.dispose();
    razzaController.dispose();
    livelloController.dispose();
    gradoController.dispose();
    expController.dispose();
    expDaAggiungereController.dispose();
    expNomePersonalizzatoController.dispose();
    livelliRapidiController.dispose();

    resilienzaController.dispose();
    volontaController.dispose();
    materiaController.dispose();
    oculumController.dispose();
    currentResilienzaController.dispose();
    currentVolontaController.dispose();
    currentMateriaController.dispose();
    currentOculumController.dispose();
    visibleCurrentResilienzaController.dispose();
    visibleCurrentVolontaController.dispose();
    visibleCurrentMateriaController.dispose();
    visibleCurrentOculumController.dispose();
    imagePasteFocusNode.dispose();

    currentHpController.dispose();
    hpTempController.dispose();
    scudoController.dispose();
    scudoCriticoController.dispose();
    scudoOculumController.dispose();
    scudoOculumMaxController.dispose();
    attaccoRapidoController.dispose();
    cmRapidoController.dispose();
    difesaRapidaController.dispose();
    reazioniController.dispose();
    reazioniVelociController.dispose();
    realtimeChatController.dispose();
    storySessionNoteController.dispose();
    realtimeDungeonMessage.dispose();
    diceResultRevision.dispose();
    diceOverlayRevision.dispose();
    oculumResourceRevision.dispose();
    inputUiRevision.dispose();
    hiddenEyeListRevision.dispose();
    hiddenEyeManagerScrollController.dispose();
    experienceRevision.dispose();
    aggiustaNucleoDisponibileRevision.dispose();
    vttCanvasRevision.dispose();
    for (final notifier in hiddenEyeStatRevisions.values) {
      notifier.dispose();
    }
    hiddenEyeStatRevisions.clear();
    for (final notifier in artIntegrityRevisions.values) {
      notifier.dispose();
    }
    artIntegrityRevisions.clear();
    for (final notifier in artSkillLevelRevisions.values) {
      notifier.dispose();
    }
    artSkillLevelRevisions.clear();
    for (final notifier in artSkillUiRevisions.values) {
      notifier.dispose();
    }
    artSkillUiRevisions.clear();
    for (final notifier in artUnlockedRevisions.values) {
      notifier.dispose();
    }
    artUnlockedRevisions.clear();
    for (final notifier in artActivationAvailableRevisions.values) {
      notifier.dispose();
    }
    artActivationAvailableRevisions.clear();
    realtimeDiceConsentQueue.clear();
    buffMalusRapidiController.dispose();
    dannoSubitoController.dispose();
    dannoBonusScudoPercentController.dispose();
    scudoFocusNode.dispose();
    attaccoRapidoFocusNode.dispose();
    difesaRapidaFocusNode.dispose();
    dannoCuraFocusNode.dispose();
    resilienzaFocusNode.dispose();
    volontaFocusNode.dispose();
    materiaFocusNode.dispose();
    oculumFocusNode.dispose();

    backgroundController.dispose();
    notePersonaggioController.dispose();

    primoTitoloFatoNomeController.dispose();
    primoTitoloFatoDescrizioneController.dispose();

    skillNomeController.dispose();
    skillTipoController.dispose();
    skillCostoController.dispose();
    skillCooldownController.dispose();
    skillDescrizioneController.dispose();
    skillResController.dispose();
    skillVolController.dispose();
    skillMatController.dispose();
    skillOcuController.dispose();
    skillDanniController.dispose();
    skillDifesaController.dispose();

    titoloNomeController.dispose();
    titoloTipoController.dispose();
    titoloOttenimentoController.dispose();
    titoloLeggendaController.dispose();
    titoloBuffController.dispose();
    titoloPuntoCiecoController.dispose();
    titoloSkillController.dispose();
    titoloRichiedeController.dispose();

    titoloResController.dispose();
    titoloVolController.dispose();
    titoloMatController.dispose();
    titoloOcuController.dispose();
    titoloKarmaController.dispose();

    titoloOpenNameController.dispose();
    titoloOpenDescriptionController.dispose();
    titoloOpenBuffController.dispose();
    titoloOpenSkillController.dispose();

    itemNomeController.dispose();
    itemPesoController.dispose();
    itemQuantitaController.dispose();
    itemPutrefazioneSessioniController.dispose();
    itemNoteController.dispose();
    itemBuffController.dispose();
    itemBonusDannoController.dispose();
    itemBonusDifesaController.dispose();
    itemBonusScudoController.dispose();
    itemGradoOggettoController.dispose();
    itemGradoRichiestoController.dispose();
    itemElementoDannoController.dispose();
    customDamageTypeController.dispose();
    masterEnemyDamageController.dispose();
    masterEnemyHealController.dispose();
    enemyGradeExpController.dispose();

    partyNomeController.dispose();
    partyRuoloController.dispose();
    partyNoteController.dispose();
    masterSessionController.dispose();

    obserController.dispose();
    ascensionDustController.dispose();
    ispirazioniController.dispose();
    superIspirazioniController.dispose();
    ispirazioniOculumController.dispose();
    karmaController.dispose();
    folliaController.dispose();
    oculumTiroController.dispose();

    cenereController.dispose();
    sessioniSenzaBisogniController.dispose();
    giorniSenzaCiboAcquaController.dispose();
    oculumCurrentDayController.dispose();

    manualSearchController.dispose();
    themeSearchController.dispose();
    monsterBookSearchController.dispose();

    quickSheetNameController.dispose();
    quickSheetLevelController.dispose();
    quickSheetGradeController.dispose();
    quickSheetCountController.dispose();
    quickSheetDescriptionController.dispose();

    diceAmountController.dispose();
    diceModifierController.dispose();
    difficoltaTiroController.dispose();
    relayServerController.dispose();
    relayRoomController.dispose();
    realtimeRoomController.dispose();
    realtimeNameController.dispose();
    oculumUsernameController.dispose();
    friendTagController.dispose();
    friendNameController.dispose();
    campaignNameController.dispose();
    newCampaignNameController.dispose();
    mapUrlController.dispose();
    mapNotesController.dispose();
    mapTokenSizeController.dispose();
    mapWidthMetersController.dispose();
    mapHeightMetersController.dispose();
    mapFreeTokenMovementController.dispose();
    mapTransformationController.dispose();
    masterInitiativeNameController.dispose();
    masterInitiativeTypeController.dispose();
    masterInitiativeBonusController.dispose();
    masterInitiativeNotesController.dispose();
    sheetCodeController.dispose();
    recipeSearchController.dispose();
    recipeSearchQuery.dispose();
    recipesRevision.dispose();

    monsterPointAmountController.dispose();

    tutorialLevelController.dispose();
    tutorialExtraResController.dispose();
    tutorialExtraVolController.dispose();
    tutorialExtraMatController.dispose();
    tutorialExtraOcuController.dispose();

    super.dispose();
  }

  IconData desktopPageIcon(int page) {
    switch (page) {
      case 0:
        return Icons.badge;
      case 1:
        return Icons.nightlight_round;
      case 2:
        return Icons.style;
      case 3:
        return Icons.auto_awesome;
      case 4:
        return Icons.psychology;
      case 5:
        return Icons.menu_book;
      case 6:
        return Icons.inventory_2;
      case 7:
        return Icons.account_balance_wallet;
      case 8:
        return Icons.rule;
      case 9:
        return Icons.visibility;
      case mapPageIndex:
        return Icons.map;
      case settingsPageIndex:
        return Icons.settings;
      case onlinePageIndex:
        return Icons.public;
      case dicePageIndex:
        return Icons.casino;
      case recipesPageIndex:
        return Icons.menu_book_outlined;
      default:
        return Icons.radio_button_unchecked;
    }
  }

  Widget desktopSideMenuShell({
    required Widget child,
    required List<int> visiblePages,
    required List<String> pageLabels,
    required int safePage,
  }) {
    final mediaSize = MediaQuery.maybeOf(context)?.size;
    final viewportWidth = mediaSize?.width ?? 1200;
    final compactViewport = (mediaSize?.shortestSide ?? 900) < 600;
    if (!modalitaDesktop || compactViewport || viewportWidth < 700) {
      return child;
    }

    final forceIconRail = viewportWidth < 980;
    final expandedMenu = desktopSideMenuOpen && !forceIconRail;
    final tabletDesktop = viewportWidth < 1280;
    final menuWidth = expandedMenu
        ? tabletDesktop
              ? 216.0
              : 276.0
        : 50.0;
    final menuPages = [...visiblePages, dicePageIndex];

    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          width: menuWidth,
          decoration: BoxDecoration(
            color: const Color(0xFF07080D).withValues(alpha: 0.98),
            border: Border(
              right: BorderSide(color: tertiaryColor.withValues(alpha: 0.45)),
            ),
            boxShadow: [
              BoxShadow(
                color: tertiaryColor.withValues(alpha: 0.08),
                blurRadius: 18,
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Align(
                  alignment: expandedMenu
                      ? Alignment.centerRight
                      : Alignment.center,
                  child: IconButton(
                    tooltip: expandedMenu
                        ? t('Chiudi menu laterale', 'Close side menu')
                        : t('Apri menu laterale', 'Open side menu'),
                    onPressed: () {
                      setState(() {
                        desktopSideMenuOpen = !desktopSideMenuOpen;
                      });
                      programmaSalvataggio();
                    },
                    icon: Icon(
                      expandedMenu
                          ? Icons.keyboard_arrow_left
                          : Icons.keyboard_arrow_right,
                      color: tertiaryColor,
                    ),
                  ),
                ),
                if (expandedMenu)
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(
                        tabletDesktop ? 6 : 10,
                        4,
                        tabletDesktop ? 6 : 10,
                        14,
                      ),
                      children: [
                        Text(
                          t('Pagine', 'Pages'),
                          style: TextStyle(
                            color: tertiaryColor,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        for (final page in menuPages)
                          Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            clipBehavior: Clip.antiAlias,
                            child: ListTile(
                              dense: true,
                              visualDensity: VisualDensity.compact,
                              selected: safePage == page,
                              selectedTileColor: tertiaryColor.withValues(
                                alpha: 0.12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              leading: Icon(
                                desktopPageIcon(page),
                                color: page == safePage
                                    ? tertiaryColor
                                    : primaryColor,
                                size: 18,
                              ),
                              title: Text(
                                cleanUiText(pageLabels[page]),
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: page == safePage
                                      ? tertiaryColor
                                      : Colors.white,
                                  fontWeight: page == safePage
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                ),
                              ),
                              onTap: () => vaiAllaFunzione(
                                page: page,
                                logTitle: pageLabels[page],
                              ),
                            ),
                          ),
                        Divider(color: tertiaryColor.withValues(alpha: 0.35)),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                t('Schede', 'Sheets'),
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: t('Nuova scheda', 'New sheet'),
                              onPressed: creaNuovaSchedaPersonaggio,
                              icon: Icon(
                                Icons.add_circle,
                                color: tertiaryColor,
                              ),
                            ),
                          ],
                        ),
                        for (int i = 0; i < schedePersonaggio.length; i++)
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onSecondaryTapDown: (details) =>
                                mostraMenuSchedaPersonaggio(
                                  index: i,
                                  position: details.globalPosition,
                                ),
                            onLongPressStart: (details) =>
                                mostraMenuSchedaPersonaggio(
                                  index: i,
                                  position: details.globalPosition,
                                ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              clipBehavior: Clip.antiAlias,
                              child: ListTile(
                                dense: true,
                                visualDensity: VisualDensity.compact,
                                selected: schedaCorrente == i,
                                selectedTileColor: primaryColor.withValues(
                                  alpha: 0.10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                leading: Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    color: schedaCorrente == i
                                        ? tertiaryColor
                                        : Colors.grey,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                title: Text(
                                  cleanUiText(nomeSchedaPersonaggio(i)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                subtitle: Text(
                                  cleanUiText(tipoSchedaPersonaggio(i)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.grey.shade400),
                                ),
                                onTap: () => cambiaSchedaPersonaggio(i),
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                else
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(5, 2, 5, 12),
                      children: [
                        for (final page in menuPages)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Tooltip(
                              message: cleanUiText(pageLabels[page]),
                              child: IconButton(
                                onPressed: () => vaiAllaFunzione(
                                  page: page,
                                  logTitle: pageLabels[page],
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: page == safePage
                                      ? tertiaryColor.withValues(alpha: 0.16)
                                      : Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                icon: Icon(
                                  desktopPageIcon(page),
                                  color: page == safePage
                                      ? tertiaryColor
                                      : primaryColor,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        Divider(color: tertiaryColor.withValues(alpha: 0.35)),
                        Tooltip(
                          message: t('Nuova scheda', 'New sheet'),
                          child: IconButton(
                            onPressed: creaNuovaSchedaPersonaggio,
                            icon: Icon(Icons.add_circle, color: tertiaryColor),
                          ),
                        ),
                        PopupMenuButton<int>(
                          tooltip: t('Cambia scheda', 'Switch sheet'),
                          color: const Color(0xFF10121A),
                          icon: Icon(Icons.groups, color: primaryColor),
                          onSelected: cambiaSchedaPersonaggio,
                          itemBuilder: (context) => [
                            for (int i = 0; i < schedePersonaggio.length; i++)
                              PopupMenuItem<int>(
                                value: i,
                                child: Text(
                                  cleanUiText(
                                    '${i + 1}. ${nomeSchedaPersonaggio(i)}',
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: i == schedaCorrente
                                        ? tertiaryColor
                                        : Colors.white,
                                    fontWeight: i == schedaCorrente
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (datiCaricati) {
      mostraTutorialSeNecessario();
      mostraSceltaRuoloSeNecessaria();
    }

    final titles = [
      'OCULUM — ${t('SCHEDA', 'SHEET')}',
      'OCULUM — ${t('RIPOSO', 'REST')}',
      'OCULUM — ${t('TITOLI', 'TITLES')}',
      'OCULUM — ${t('ART', 'ARTS')}',
      'OCULUM — ${t('SKILL', 'SKILLS')}',
      'OCULUM — ${t('STORIA', 'STORY')}',
      'OCULUM — ${t('INVENTARIO', 'INVENTORY')}',
      'OCULUM — ${t('RISORSE', 'RESOURCES')}',
      'OCULUM — ${t('REGOLE', 'RULES')}',
      'OCULUM — MASTER',
      'OCULUM — ${t('MAPPA', 'MAP')}',
      'OCULUM — ${t('IMPOSTAZIONI', 'SETTINGS')}',
      'OCULUM — ONLINE',
      'OCULUM — ${t('DADI', 'DICE')}',
      'OCULUM — ${t('RICETTE', 'RECIPES')}',
    ];

    final int safePage = paginaVisibileSicura(
      paginaCorrente,
    ).clamp(0, titles.length - 1).toInt();
    final pageLabels = linguaInglese ? pageNamesEn : pageNamesIt;
    final visiblePages = visiblePageIndexes();
    final compactPhone = MediaQuery.of(context).size.shortestSide < 600;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: compactPhone ? 48 : null,
        actionsIconTheme: IconThemeData(size: compactPhone ? 20 : 24),
        centerTitle: true,
        backgroundColor: const Color(0xFF080911),
        elevation: 0,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              cleanUiText(titles[safePage]),
              style: TextStyle(
                color: safePage == 0 ? primaryColor : tertiaryColor,
                letterSpacing: 2.0,
                fontWeight: FontWeight.bold,
                fontSize: compactPhone ? 10.5 : 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              cleanUiText(
                '${schedaCorrente + 1}/${schedePersonaggio.isEmpty ? 1 : schedePersonaggio.length} • ${tipoSchedaController.text} • ${nomeSchedaPersonaggio(schedaCorrente)}',
              ),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: tertiaryColor,
                fontSize: compactPhone ? 8.8 : 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),

        actions: [
          if (!compactPhone && modalitaDesktop)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: OculumDesktopTopMenu(
                currentIndex: max(0, visiblePages.indexOf(safePage)),
                labels: visiblePages.map((i) => pageLabels[i]).toList(),
                onChanged: (index) {
                  final page = visiblePages[index];
                  vaiAllaFunzione(page: page, logTitle: pageLabels[page]);
                },
                primaryColor: primaryColor,
                tertiaryColor: tertiaryColor,
                searchLabel: t('Cerca pagina', 'Search page'),
                pageLabel: t('Cambia pagina', 'Switch page'),
              ),
            ),
          OculumQuickEditEyeButton(
            sectionsBuilder: quickEditSections,
            primaryColor: primaryColor,
            secondaryColor: secondaryColor,
            tertiaryColor: tertiaryColor,
            title: t('Modifica rapida', 'Quick edit'),
            subtitle: t(
              'Modifica velocemente statistiche, HP, scudi e risorse senza scendere nella scheda.',
              'Quickly edit stats, HP, shields and resources without scrolling through the sheet.',
            ),
            onChanged: () {
              setState(() {
                aggiornaGradoAutomatico();
                risultato = t(
                  'Valori rapidi aggiornati.',
                  'Quick values updated.',
                );
                aggiungiLog(risultato);
              });

              programmaSalvataggio();
            },
          ),
          if (!compactPhone)
            IconButton(
              tooltip: t('Annulla ultima modifica', 'Undo last change'),
              onPressed: annullaUltimaModifica,
              icon: Icon(
                Icons.undo,
                color: primaryColor,
                size: compactPhone ? 20 : 24,
              ),
            ),
          if (!compactPhone)
            IconButton(
              tooltip: t('Torna avanti', 'Redo'),
              onPressed: ripristinaModificaAnnullata,
              icon: Icon(
                Icons.redo,
                color: tertiaryColor,
                size: compactPhone ? 20 : 24,
              ),
            ),
          IconButton(
            tooltip: t('Cerca', 'Search'),
            onPressed: mostraCerca,
            icon: Icon(
              Icons.search,
              color: primaryColor,
              size: compactPhone ? 20 : 24,
            ),
          ),
          if (compactPhone)
            PopupMenuButton<String>(
              tooltip: t('Azioni', 'Actions'),
              color: const Color(0xFF10121A),
              icon: Icon(Icons.more_vert, color: primaryColor, size: 20),
              onSelected: (value) {
                if (value == 'dungeon') {
                  _openDungeonMiniGame();
                  return;
                }
                if (value == 'undo') {
                  annullaUltimaModifica();
                  return;
                }
                if (value == 'redo') {
                  ripristinaModificaAnnullata();
                  return;
                }
                if (value == 'settings') {
                  vaiAllaFunzione(
                    page: settingsPageIndex,
                    anchorId: 'settings_root',
                    logTitle: t('Impostazioni', 'Settings'),
                  );
                  return;
                }
                if (value == 'new_sheet') {
                  if (paginaCorrente != onlinePageIndex ||
                      realtimeCanBrowseOtherSheets) {
                    creaNuovaSchedaPersonaggio();
                  }
                  return;
                }
                if (value == 'delete_sheet') {
                  if (schedePersonaggio.length > 1 &&
                      (paginaCorrente != onlinePageIndex ||
                          realtimeCanBrowseOtherSheets)) {
                    eliminaSchedaCorrente();
                  }
                  return;
                }
                if (value.startsWith('page_')) {
                  final page = int.tryParse(value.substring(5));
                  if (page == null) return;
                  vaiAllaFunzione(page: page, logTitle: pageLabels[page]);
                  return;
                }
                if (value.startsWith('sheet_')) {
                  final index = int.tryParse(value.substring(6));
                  if (index != null) cambiaSchedaPersonaggio(index);
                }
              },
              itemBuilder: (context) {
                final menuPages = [...visiblePages, dicePageIndex];
                final totale = schedePersonaggio.isEmpty
                    ? 1
                    : schedePersonaggio.length;
                final canSeeOtherSheets =
                    paginaCorrente != onlinePageIndex ||
                    realtimeCanBrowseOtherSheets;
                final sheetIndexes = canSeeOtherSheets
                    ? List<int>.generate(totale, (i) => i)
                    : <int>[schedaCorrente.clamp(0, totale - 1).toInt()];

                return [
                  PopupMenuItem<String>(
                    value: 'dungeon',
                    child: Row(
                      children: [
                        Icon(Icons.visibility, color: primaryColor, size: 18),
                        const SizedBox(width: 8),
                        Text(t('Dungeon', 'Dungeon')),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'undo',
                    child: Text(
                      t('Annulla ultima modifica', 'Undo last change'),
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'redo',
                    child: Text(t('Torna avanti', 'Redo')),
                  ),
                  PopupMenuItem<String>(
                    value: 'settings',
                    child: Text(t('Impostazioni', 'Settings')),
                  ),
                  PopupMenuItem<String>(
                    value: 'new_sheet',
                    child: Text(t('Nuova scheda', 'New sheet')),
                  ),
                  if (schedePersonaggio.length > 1 &&
                      (paginaCorrente != onlinePageIndex ||
                          realtimeCanBrowseOtherSheets))
                    PopupMenuItem<String>(
                      value: 'delete_sheet',
                      child: Text(
                        t('Elimina scheda corrente', 'Delete current sheet'),
                      ),
                    ),
                  const PopupMenuDivider(),
                  PopupMenuItem<String>(
                    enabled: false,
                    child: Text(
                      t('Pagine', 'Pages'),
                      style: TextStyle(
                        color: tertiaryColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  for (final i in menuPages)
                    PopupMenuItem<String>(
                      value: 'page_$i',
                      child: Row(
                        children: [
                          Icon(
                            desktopPageIcon(i),
                            color: i == safePage ? tertiaryColor : primaryColor,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              cleanUiText(pageLabels[i]),
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: i == safePage
                                    ? tertiaryColor
                                    : Colors.white,
                                fontWeight: i == safePage
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const PopupMenuDivider(),
                  PopupMenuItem<String>(
                    enabled: false,
                    child: Text(
                      t('Schede', 'Sheets'),
                      style: TextStyle(
                        color: tertiaryColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  for (final i in sheetIndexes)
                    PopupMenuItem<String>(
                      value: 'sheet_$i',
                      child: Text(
                        cleanUiText(
                          '${i + 1}. ${tipoSchedaPersonaggio(i)} - ${nomeSchedaPersonaggio(i)}',
                        ),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: i == schedaCorrente
                              ? tertiaryColor
                              : Colors.white,
                          fontWeight: i == schedaCorrente
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                ];
              },
            ),
          if (!compactPhone)
            IconButton(
              tooltip: t('Impostazioni', 'Settings'),
              onPressed: () {
                vaiAllaFunzione(
                  page: settingsPageIndex,
                  anchorId: 'settings_root',
                  logTitle: t('Impostazioni', 'Settings'),
                );
              },
              icon: Icon(
                Icons.settings,
                color: tertiaryColor,
                size: compactPhone ? 20 : 24,
              ),
            ),
          if (!compactPhone)
            PopupMenuButton<int>(
              tooltip: t('Cambia pagina', 'Switch page'),
              color: const Color(0xFF10121A),
              icon: Icon(
                Icons.menu_open,
                color: primaryColor,
                size: compactPhone ? 20 : 24,
              ),
              onSelected: (index) {
                vaiAllaFunzione(page: index, logTitle: pageLabels[index]);
              },
              itemBuilder: (context) {
                final labels = pageLabels;
                final menuPages = [...visiblePages, dicePageIndex];

                return [
                  for (final i in menuPages)
                    PopupMenuItem<int>(
                      value: i,
                      child: Text(
                        cleanUiText(labels[i]),
                        style: TextStyle(
                          color: i == paginaCorrente
                              ? tertiaryColor
                              : Colors.white,
                          fontWeight: i == paginaCorrente
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                ];
              },
            ),
          if (!compactPhone)
            IconButton(
              tooltip: t('Nuova scheda', 'New sheet'),
              onPressed:
                  paginaCorrente == onlinePageIndex &&
                      !realtimeCanBrowseOtherSheets
                  ? null
                  : () => creaNuovaSchedaPersonaggio(),
              icon: Icon(
                Icons.add_circle,
                color: tertiaryColor,
                size: compactPhone ? 20 : 24,
              ),
            ),
          if (!compactPhone)
            PopupMenuButton<int>(
              tooltip: t('Cambia scheda', 'Switch sheet'),
              color: const Color(0xFF10121A),
              icon: Icon(
                Icons.groups,
                color: primaryColor,
                size: compactPhone ? 20 : 24,
              ),
              onSelected: cambiaSchedaPersonaggio,
              itemBuilder: (context) {
                final totale = schedePersonaggio.isEmpty
                    ? 1
                    : schedePersonaggio.length;
                final canSeeOtherSheets =
                    paginaCorrente != onlinePageIndex ||
                    realtimeCanBrowseOtherSheets;
                final indexes = canSeeOtherSheets
                    ? List<int>.generate(totale, (i) => i)
                    : <int>[schedaCorrente.clamp(0, totale - 1).toInt()];

                return [
                  for (final i in indexes)
                    PopupMenuItem<int>(
                      value: i,
                      child: Row(
                        children: [
                          Icon(
                            i == schedaCorrente
                                ? Icons.visibility
                                : Icons.radio_button_unchecked,
                            color: i == schedaCorrente
                                ? tertiaryColor
                                : Colors.grey,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              cleanUiText(
                                '${i + 1}. ${tipoSchedaPersonaggio(i)} — ${nomeSchedaPersonaggio(i)}',
                              ),
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: i == schedaCorrente
                                    ? tertiaryColor
                                    : Colors.white,
                                fontWeight: i == schedaCorrente
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ];
              },
            ),
          if (!compactPhone &&
              schedePersonaggio.length > 1 &&
              (paginaCorrente != onlinePageIndex ||
                  realtimeCanBrowseOtherSheets))
            IconButton(
              tooltip: t('Elimina scheda corrente', 'Delete current sheet'),
              onPressed: eliminaSchedaCorrente,
              icon: Icon(
                Icons.delete_outline,
                color: Colors.redAccent,
                size: compactPhone ? 20 : 24,
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  backgroundTopColor,
                  backgroundMidColor,
                  backgroundBottomColor,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: RepaintBoundary(child: themeDecorationBackdrop()),
                  ),
                ),
                desktopSideMenuShell(
                  visiblePages: visiblePages,
                  pageLabels: pageLabels,
                  safePage: safePage,
                  child: datiCaricati
                      ? AnimatedSwitcher(
                          duration: const Duration(milliseconds: 160),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          child: RepaintBoundary(
                            key: ValueKey<String>(
                              'page_shell_${safePage}_${_isPagePreparedForDisplay(safePage)}',
                            ),
                            child: ValueListenableBuilder<int>(
                              valueListenable: inputUiRevision,
                              builder: (context, revision, child) =>
                                  buildCurrentPageLazy(safePage),
                            ),
                          ),
                        )
                      : homeDataLoadingPlaceholder(),
                ),
              ],
            ),
          ),
          dadoOverlayCentrale(),
        ],
      ),

      bottomNavigationBar: modalitaDesktop && !compactPhone
          ? null
          : OculumBottomNav(
              currentIndex: paginaCorrente,
              showOnline: true,
              onChanged: (index) {
                vaiAllaFunzione(page: index, logTitle: pageLabels[index]);
              },
            ),
    );
  }
}
