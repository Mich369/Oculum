# Commit only the reviewed Oculum source patch. [skip ci] prevents build workflows.
param([switch]$Push, [switch]$StageOnly)
$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath (Split-Path $PSScriptRoot -Parent)
$files = @(
  'lib/src/main/oculum_helpers.dart',
  'lib/src/main/oculum_element_themes.dart',
  'lib/widgets/oculum_combat_theme.dart',
  'lib/widgets/oculum_element_theme_registry.dart',
  'lib/widgets/oculum_element_ambient_art.dart',
  'test/oculum_element_identity_test.dart',
  'test/oculum_element_pack_motion_test.dart',
  'scripts/finalize_oculum_story_manifest.cjs',
  'docs/AGGIORNAMENTO_2026-10-25.md',
  'docs/manuale-consultazione.md',
  'docs/OCULUM_LORE_VISIVA.md',
  'docs/OCULUM_REGOLE_CONFERMATE.md',
  'lib/game/oculum_combat_scout_rules.dart',
  'lib/main.dart',
  'lib/pages/oculum_dungeon/canonical_monster_variants.dart',
  'lib/pages/oculum_dungeon/concrete_monster_techniques.dart',
  'lib/pages/oculum_dungeon/masked_monsters.dart',
  'lib/pages/oculum_dungeon/monster_book.dart',
  'lib/pages/oculum_dungeon/ordinary_creatures.dart',
  'lib/src/main/oculum_combat_ability_bar.dart',
  'lib/src/main/oculum_combat_scout.dart',
  'lib/src/main/oculum_enemy_ability_variants.dart',
  'lib/src/main/oculum_equipment_abilities.dart',
  'lib/src/main/oculum_home_calculations.dart',
  'lib/src/main/oculum_home_colors_and_base_widgets.dart',
  'lib/src/main/oculum_home_combat_progression.dart',
  'lib/src/main/oculum_home_persistence.dart',
  'lib/src/main/oculum_home_quick_conditions.dart',
  'lib/src/main/oculum_home_rules_settings_search.dart',
  'lib/src/main/oculum_home_secondary_pages.dart',
  'lib/src/main/oculum_home_titles_inventory_pages.dart',
  'lib/src/main/oculum_manual_sections.dart',
  'lib/src/main/oculum_masked_men.dart',
  'lib/src/main/oculum_monster_appearance.dart',
  'lib/src/main/oculum_monster_dossier.dart',
  'lib/src/main/oculum_online_attacks.dart',
  'lib/src/main/oculum_performance_probe.dart',
  'lib/src/main/oculum_planar_runtime.dart',
  'lib/src/main/oculum_planes.dart',
  'lib/src/main/oculum_reference_campaign.dart',
  'lib/src/main/oculum_reference_sheet.dart',
  'lib/src/main/oculum_skill_effects.dart',
  'lib/src/main/oculum_starter_creation.dart',
  'lib/widgets/oculum_custom_theme.dart',
  'lib/widgets/oculum_hex_color_field.dart',
  'lib/widgets/oculum_monster_theme.dart',
  'lib/widgets/oculum_narrative_background.dart',
  'lib/widgets/oculum_story_theme_identities.dart',
  'lib/widgets/oculum_story_theme_packs.dart',
  'lib/widgets/oculum_theme_asset_packs.dart',
  'lib/widgets/oculum_theme_identity.dart',
  'lib/widgets/oculum_theme_presentation.dart',
  'lib/widgets/oculum_theme_relic.dart',
  'lib/widgets/oculum_theme_sheet_art.dart',
  'pubspec.yaml',
  'scripts/build_oculum_story_frames.cjs',
  'scripts/export_oculum_theme_story_brief.dart',
  'scripts/optimize_oculum_story_assets.cjs',
  'scripts/verify_oculum_story_assets.cjs',
  'test/oculum_custom_theme_test.dart',
  'test/oculum_element_theme_coverage_test.dart',
  'test/oculum_hex_color_test.dart',
  'test/oculum_inherited_monster_powers_test.dart',
  'test/oculum_masked_men_test.dart',
  'test/oculum_monster_dossier_test.dart',
  'test/oculum_monster_generation_rules_test.dart',
  'test/oculum_monster_themes_scout_test.dart',
  'test/oculum_narrative_sheet_preview_test.dart',
  'test/oculum_planar_catalogue_test.dart',
  'test/oculum_screenshot_regressions_test.dart',
  'test/oculum_theme_effects_portrait_test.dart',
  'scripts/commit_oculum_patch_no_build.ps1',
  'assets/oculum/home_art/creature_nuvi.png',
  'assets/oculum/home_art/creature_ombra_v2.png',
  'assets/oculum/home_art/creature_solare_v2.png',
  'assets/oculum/home_art/creature_angelico.png',
  'assets/oculum/home_art/creature_viola.png'
)
$directories = @(
  'docs/theme-art',
  'assets/oculum/theme_stories/webp',
  'assets/themes/benedict',
  'assets/themes/hidenas',
  'assets/themes/dedicated_aurora',
  'assets/themes/dedicated_cloud_sea',
  'assets/themes/dedicated_indigo',
  'assets/themes/plane_affogato',
  'assets/themes/plane_angelico',
  'assets/themes/plane_caramella',
  'assets/themes/plane_demoniaco',
  'assets/themes/plane_diabolico',
  'assets/themes/plane_foresta_elementale',
  'assets/themes/plane_ghiaccio',
  'assets/themes/plane_isole',
  'assets/themes/plane_mezzano',
  'assets/themes/plane_morti',
  'assets/themes/plane_nuvole_rocciose',
  'assets/themes/plane_oblio',
  'assets/themes/plane_postea',
  'assets/themes/plane_sacro',
  'assets/themes/plane_shadow_hell',
  'assets/themes/plane_sotterraneo',
  'assets/themes/plane_sotterraneo_maggiore',
  'assets/themes/plane_vero_inferno'
)
function Test-PatchPath([string]$Path) {
  if ($Path -in $files) { return $true }
  foreach ($directory in $directories) {
    if ($Path.StartsWith($directory + '/', [StringComparison]::Ordinal)) { return $true }
  }
  return $false
}
& git diff --check -- @files @directories
if ($LASTEXITCODE -ne 0) { throw 'Diff check failed' }
& git add -- @files @directories
if ($LASTEXITCODE -ne 0) { throw 'Cannot stage patch' }
$staged = @(& git diff --cached --name-only)
$unexpected = @($staged | Where-Object { !(Test-PatchPath $_) })
if ($unexpected.Count) { throw ('Unrelated staged files; preserve them before continuing: ' + ($unexpected -join ', ')) }
if ($StageOnly) {
  Write-Host ('Reviewed patch staged: ' + $staged.Count + ' files. No commit, push or build started.')
  exit 0
}
& git commit -m 'Add Oculum masked creatures, narrative themes and per-sheet dossiers [skip ci]'
if ($LASTEXITCODE -ne 0) { throw 'Commit failed' }
if ($Push) {
  $branch = (& git branch --show-current).Trim()
  if (!$branch) { throw 'Detached HEAD: choose a branch first' }
  & git push origin $branch
  if ($LASTEXITCODE -ne 0) { throw 'Push failed' }
}
Write-Host 'Source patch saved. No builds requested. Existing distribution packages unchanged.'
