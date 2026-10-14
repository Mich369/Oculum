$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$sources = @('lib/main.dart', 'lib/src/main/oculum_design_system.dart')
$identities = @'
classic_reliquary|sigillo inciso in rame, montatura d osso|riflesso lento sulle incisioni
classic_rpg|scudo araldico e fibbie di cuoio inciso|luce sulle incisioni
classic_low_detail|sigillo inciso compatto|nessun movimento
blood_court|corona spinata e calice di essenza|goccia nel calice
witch_glass|ampolle sospese e vetro incrinato|vapore nell'ampolla
moon_iron|falce lunare incastonata in ferro|riflesso sulla falce
lunar_eclipse|disco eclissato e orbite spezzate|orbita lenta
cathedral_rose|rosone a petali e vetro piombato|luce attraverso il rosone
thorn_vigil|rovi annodati e sigillo trafitto|spine illuminate in sequenza
frost_chapel|occhio congelato e schegge di cappella|bagliore del cristallo
obsidian_sigil|ossidiana fratturata e glifo sospeso|respiro del glifo
solar_reliquary|reliquiario radiale e raggi consumati|luce fra i raggi
storm_cathedral|guglie spezzate e parafulmini rituali|arco elettrico breve
abyssal_tide|conchiglia infranta e tentacoli perlacei|tentacolo oscillante
ember_rite|pietra carbonizzata e cera rituale|brace pulsante
ivory_archive|fogli arrotolati e fermagli d'avorio|polvere fra i fogli
vervain_gothic|occhio fra radici e fiori di verbena|petalo cadente
kingi_wrong_future|ingranaggi deformi e occhio meccanico|rotazione di un ingranaggio
blood_chapel|arco osseo e reliquia sanguigna|essenza lungo l'arco
null_crown|corona incompleta sospesa nel vuoto|ombra intermittente
phobia_dark|iride osservatrice e fenditura oscura|pupilla laterale
whispering_reliquary|bocche sigillate e nastri reliquiario|nastro che respira
black_briar_kingdom|stemma soffocato dal rovo nero|ramo che si inclina
slime_prince|corona galleggiante e gelatina regale|compressione dello slime
moon_rot|luna corrosa e funghi lunari|spore leggere
obser_relic|moneta perforata e bilancia rituale|riflesso sulla moneta
deep_forest_demon|corna ramificate e corteccia demoniaca|lucciole fra le corna
astral_ink|calamaio cosmico e scie calligrafiche|inchiostro ascendente
bone_saint|aureola di vertebre e osso scolpito|luce fra le vertebre
medieval_keep|merli di pietra e stendardo logoro|stendardo oscillante
fortezza_oculum|bastione oculare e cancelli runici|sigilli del cancello
hoshy_cosmic_cat|gatto etereo e coda di costellazioni|pupilla del gatto
ash_oracle|maschera profetica e cenere raccolta|cenere ascendente
void_liturgy|cerchio liturgico incompleto e velario|velario in ombra
shadow_gate_rank|portale a gradini e catene d'ombra|ombra dietro il portale
postea_bloom|reliquia errante e boccioli metallici|bocciolo che si apre
karma_duality|due occhi sulla bilancia spezzata|oscillazione della bilancia
monster_lantern|lanterna con silhouette prigioniera|ombra nella lanterna
jrpg_legend|lama cerimoniale e cristallo custodito|scintilla sul cristallo
rogue_mutation|occhio mutante e membrane irregolari|contrazione della membrana
cell_crimson_run|sbarre infrante e catene cremisi|oscillazione della catena
darkest_stagecoach|ruota scheggiata e lanterna di viaggio|tremolio della lanterna
ashen_covenant|sigillo giurato e tessuto bruciato|cenere dal sigillo
eclipse_bonfire|falò dentro una mezzaluna consumata|fiamma breve
bolted_black_iron|placche nere e catene bullonate|riflesso sui rivetti
bolted_gold_plate|placche auree e sigillo regale|luce sull'incisione
bolted_copper_oxide|rame ossidato e tubi rituali|vapore dal tubo
bolted_silver_plate|argento martellato e lenti oculari|riflesso sulla lente
meadow_sprite|folletto nascosto e erbe intrecciate|lucciola errante
aurora_moth|falena dalle ali traforate e antenna lunare|battito lento delle ali
modern_school_day|quaderno oscuro e sigillo sulla copertina|pagina che si solleva
vtt_arcane_table|tavolo rituale e pedine runiche|runa sul tavolo
vtt_obsidian_grid|tessere d'ossidiana e giunture incise|giunture illuminate
vtt_parchment_layers|mappe stratificate e chiodi cartografici|lembo della mappa
vtt_master_overlay|anello del Master e marcatori oculari|marcatore illuminato
verdigris_mourning|rame sepolto e catene floreali corrose|polvere sull'incisione
restyle_originale|occhio cesellato e pergamena annerita|luce sul rame
restyle_cenere|occhio di pietra e strati di cenere|particella di cenere
restyle_sangue|occhio suturato e filo di essenza|essenza nel filo
restyle_aurora|occhio ametista e veli aurorali|velo aurorale
restyle_natura|occhio nel seme e radici bronzee|radice oscillante
restyle_lume|occhio di cera e candelabro antico|fiamma della candela
restyle_sogno|nuvole stratificate blu, viola e rosa pastello|nubi che scorrono lentamente
restyle_sogno|nuvole stratificate blu, viola e rosa pastello|nubi che scorrono lentamente
'@
$lookup = @{}
foreach ($line in $identities.Trim().Split("`n")) {
  $parts = $line.Trim().Split('|')
  $lookup[$parts[0]] = @{ motif = $parts[1]; motion = $parts[2] }
}
$themes = foreach ($source in $sources) {
  $text = Get-Content -LiteralPath (Join-Path $root $source) -Raw
  foreach ($match in [regex]::Matches($text, 'OculumColorPreset\(\s*id:\s*''([^'']+)''[\s\S]*?nameIt:\s*''([^'']+)''')) {
    $id = $match.Groups[1].Value
    if (!$lookup.ContainsKey($id)) { throw "Missing Art Bible for $id" }
    $assetPath = Join-Path $root "assets/themes/$id/overlays/relic.png"
    $assetExists = Test-Path -LiteralPath $assetPath
    $assetFile = if ($assetExists) { Get-Item -LiteralPath $assetPath } else { $null }
    $assetHash = if ($assetExists) { (Get-FileHash -LiteralPath $assetPath -Algorithm SHA256).Hash.ToLowerInvariant() } else { '' }
    [ordered]@{
      id = $id; name = $match.Groups[2].Value; source = $source
      atmosphere = 'Dark fantasy Oculum; interpretare il significato del tema esistente'
      formsAndMaterials = $lookup[$id].motif
      signaturePng = "assets/themes/$id/overlays/relic.png"
      assetBytes = if ($assetFile) { $assetFile.Length } else { 0 }
      assetSha256 = $assetHash
      motion = $lookup[$id].motion
      lighting = 'Luce locale sulla reliquia; colori personalizzati mantenuti'
      particles = 'Pochi elementi coerenti con materiali e simboli'
      forbidden = @('decorazioni su testo o controlli', 'stessa silhouette semplicemente ricolorata', 'video continui', 'asset privi di alpha')
      responsive = 'Desktop: laterale; tablet: angolo; telefono: sigillo compatto sopra la cornice'
      status = if ($assetExists) { 'asset_created' } else { 'planned' }
    }
  }
}
if (@($themes).Count -ne 63) { throw "Expected 63 existing themes, found $(@($themes).Count)" }
$destination = Join-Path $root 'docs/design'
New-Item -ItemType Directory -Path $destination -Force | Out-Null
$themes | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $destination 'theme-art-bible.json') -Encoding utf8
Write-Host "Inventoried $(@($themes).Count) existing theme identities"
$dart = [Collections.Generic.List[string]]::new()
$dart.Add('// Generated by scripts/build_theme_design_inventory.ps1. Stable existing IDs.')
$dart.Add('class OculumThemeAssetPack {')
$dart.Add('  const OculumThemeAssetPack(this.id, this.name, this.motif, this.motion);')
$dart.Add('  final String id, name, motif, motion;')
$dart.Add('  String get relic => "assets/themes/$id/overlays/relic.png";')
$dart.Add('  String frame(String role, {String variant = ""}) => "assets/themes/$id/frames/$role${variant.isEmpty ? "" : "-$variant"}.png";')
$dart.Add('  String scene({required bool mobile, String variant = ""}) => "assets/themes/$id/decorations/scene${mobile ? "-mobile" : ""}${variant.isEmpty ? "" : "-$variant"}.png";')
$dart.Add('}')
$dart.Add('const oculumThemeAssetPacks = <String, OculumThemeAssetPack>{')
foreach ($theme in $themes) {
  $values = @($theme.id, $theme.name, $theme.formsAndMaterials, $theme.motion) | ForEach-Object { ConvertTo-Json -InputObject $_ -Compress }
  $dart.Add("  $($values[0]): OculumThemeAssetPack($($values -join ', ')),")
  New-Item -ItemType Directory -Path (Join-Path $root "assets/themes/$($theme.id)/overlays") -Force | Out-Null
}
$dart.Add('};')
$dart | Set-Content -LiteralPath (Join-Path $root 'lib/widgets/oculum_theme_asset_packs.dart') -Encoding utf8
