# Commit only this patch. [skip ci] prevents push-triggered build workflows.
param([switch]$Push)
$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath (Split-Path $PSScriptRoot -Parent)
$files = @(
  '.github/workflows/build_distribution.yml',
  '.github/workflows/public_downloads.yml',
  'scripts/publish_github_downloads.py',
  'scripts/tests/test_publish_github_downloads.py',
  'docs/OCULUM_REGOLE_CONFERMATE.md',
  'docs/manuale-consultazione.md',
  'lib/game/oculum_opposed_attack.dart',
  'lib/main.dart',
  'lib/src/main/oculum_mecha.dart',
  'lib/src/main/oculum_will_inventory.dart',
  'lib/src/main/oculum_dust_crystals.dart',
  'lib/src/main/oculum_prepared_skills.dart',
  'lib/src/main/oculum_meccanio.dart',
  'lib/src/main/oculum_postea.dart',
  'lib/src/main/oculum_home_resources_rest_titles_data.dart',
  'lib/src/main/oculum_home_death_rules.dart',
  'lib/src/main/oculum_monster_loot.dart',
  'lib/pages/oculum_dungeon/canonical_monster_variants.dart',
  'lib/pages/oculum_dungeon/concrete_monster_techniques.dart',
  'lib/src/main/oculum_combat_ability_bar.dart',
  'lib/src/main/oculum_combat_scout.dart',
  'lib/src/main/oculum_encounter_rewards.dart',
  'lib/src/main/oculum_enemy_ability_variants.dart',
  'lib/src/main/oculum_equipment_abilities.dart',
  'lib/src/main/oculum_home_calculations.dart',
  'lib/src/main/oculum_home_combat_progression.dart',
  'lib/src/main/oculum_home_persistence.dart',
  'lib/src/main/oculum_home_secondary_pages.dart',
  'lib/src/main/oculum_home_titles_inventory_pages.dart',
  'lib/src/main/oculum_manual_sections.dart',
  'lib/src/main/oculum_models.dart',
  'lib/src/main/oculum_online_attacks.dart',
  'lib/src/main/oculum_online_permissions.dart',
  'lib/src/main/oculum_performance_probe.dart',
  'lib/src/main/oculum_planar_runtime.dart',
  'lib/src/main/oculum_realtime_integration.dart',
  'lib/src/main/oculum_reference_sheet.dart',
  'lib/src/main/oculum_skill_effects.dart',
  'lib/src/main/oculum_skill_effects_ui.dart',
  'lib/src/main/oculum_starter_creation.dart',
  'lib/src/main/oculum_structured_effect_runtime.dart',
  'test/oculum_planar_catalogue_test.dart',
  'test/oculum_prepared_skills_test.dart',
  'test/oculum_unused_reaction_bonus_test.dart',
  'test/oculum_ability_catalogue_ui_test.dart',
  'test/oculum_counter_attack_integration_test.dart',
  'test/oculum_counter_attack_rules_test.dart',
  'test/oculum_observer_creatures_test.dart',
  'test/oculum_speed_increase_monsters_test.dart',
  'test/oculum_monster_open_balance_test.dart',
  'test/oculum_nuvi_rabbit_doll_test.dart',
  'test/oculum_mecha_test.dart',
  'test/oculum_monster_generation_rules_test.dart',
  'test/oculum_manual_pdf_test.dart',
  'test/oculum_merchant_dust_test.dart',
  'test/oculum_concrete_monster_techniques_test.dart',
  'test/oculum_rock_slime_kit_test.dart',
  'test/oculum_runic_acid_kamikaze_test.dart',
  'test/oculum_session_turns_will_test.dart',
  'scripts/publish_oculum_github.ps1',
  'scripts/tests/test_publish_oculum_github.ps1',
  'scripts/commit_oculum_patch_no_build.ps1'
)
& git diff --check -- @files
if ($LASTEXITCODE -ne 0) { throw 'Diff check failed' }
& git add -- @files
if ($LASTEXITCODE -ne 0) { throw 'Cannot stage patch' }
$staged = @(& git diff --cached --name-only)
$unexpected = @($staged | Where-Object { $_ -notin $files })
if ($unexpected.Count) { throw ('Unrelated staged files; unstage them before continuing: ' + ($unexpected -join ', ')) }
& git commit -m 'Complete Oculum combat, creatures, ability catalogue and resource costs [skip ci]'
if ($LASTEXITCODE -ne 0) { throw 'Commit failed' }
if ($Push) {
  $branch = (& git branch --show-current).Trim()
  if (!$branch) { throw 'Detached HEAD: choose a branch first' }
  & git push origin $branch
  if ($LASTEXITCODE -ne 0) { throw 'Push failed' }
}
Write-Host 'Source patch saved. No builds requested. Existing distribution packages unchanged.'
