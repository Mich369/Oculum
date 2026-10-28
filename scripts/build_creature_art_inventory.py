"""Join the real pure-Dart creature export with the app's artwork mapping.

Run: dart run scripts/export_creature_art_inventory.dart
     python scripts/build_creature_art_inventory.py
Does not generate artwork or treat a procedural fallback as finished artwork.
"""
from collections import Counter
from pathlib import Path
import hashlib
import json
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]
catalogue = json.loads((ROOT / 'build/creature-art-catalogue.json').read_text(encoding='utf-8'))
mapping_path = ROOT / 'lib/widgets/oculum_monster_theme.dart'
mapping_source = mapping_path.read_text(encoding='utf-8')
switch = mapping_source.split('String? get illustration => switch (monster.id)', 1)[1].split('};', 1)[0]
illustrations = dict(re.findall(r"'([^']+)'\s*=>\s*'([^']+)'", switch))
relic_switch = mapping_source.split('String? get relicIllustration => switch (monster.id)', 1)[1].split('String? get illustration', 1)[0]
relics = dict(re.findall(r"'([^']+)'\s*=>\s*'([^']+)'", relic_switch))
sources = {p: p.read_text(encoding='utf-8') for p in (ROOT / 'lib/pages/oculum_dungeon').glob('*.dart')}

def source_location(monster_id):
    base = monster_id.split('_variante_')[0]
    patterns = [rf"\bid:\s*'{re.escape(base)}'", rf"'id'\s*:\s*'{re.escape(base)}'", rf"\(\s*'{re.escape(base)}'\s*,"]
    for path, source in sources.items():
        for pattern in patterns:
            found = re.search(pattern, source)
            if found:
                return f'{path.relative_to(ROOT).as_posix()}:{source[:found.start()].count(chr(10)) + 1}'
    return 'lib/pages/oculum_dungeon/monster_book.dart:_generatedMonsterEntry / funzione generatrice della famiglia'

def brief(value, limit=170):
    value = re.sub(r'\s+', ' ', str(value)).replace('|', '/').strip()
    return value if len(value) <= limit else value[:limit-1].rstrip() + '…'

rows = []
for entry in catalogue['entries']:
    monster_id = entry['id']
    artwork = illustrations.get(monster_id)
    source = source_location(monster_id)
    anatomy = entry['anatomy']
    candidates = []
    for extension in ('png', 'webp'):
        candidates.extend(p.relative_to(ROOT).as_posix() for p in
                          (ROOT / 'assets/oculum/home_art').glob(f'*{monster_id}*.{extension}'))
    rows.append({
        **entry,
        'sourceLocation': source,
        'isGeneratedVariant': '_variante_' in monster_id,
        'baseId': monster_id.split('_variante_')[0],
        'themeAsset': artwork,
        'themeAssetExists': bool(artwork and (ROOT / artwork).is_file()),
        'themeStatus': 'asset dedicato collegato, presente' if artwork and (ROOT / artwork).is_file()
                       else 'collegamento asset mancante su disco' if artwork
                       else 'scena dedicata mancante; fallback procedurale',
        'relicAsset': relics.get(monster_id),
        'relicStatus': 'asset dedicato collegato e presente; conferme visive e test nel manifest specifico, pubblicazione separata' if monster_id in relics and (ROOT / relics[monster_id]).is_file() else 'reliquia dedicata mancante; OculumMonsterRelicPainter generico',
        'unlinkedArtworkCandidates': [p for p in candidates if p != artwork],
        'approval': 'non attestata automaticamente: verificare canone, manifest e conferma utente',
        'anatomyLabels': [p.get('label', p.get('id', '')) for p in anatomy],
    })

entries = len(rows)
base_count = sum(not r['isGeneratedVariant'] for r in rows)
linked = sum(r['themeAssetExists'] for r in rows)
commit = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
report = {
    'schemaVersion': 1,
    'exportedAtUtc': catalogue['exportedAtUtc'],
    'baseCommit': commit,
    'scope': 'working tree catalog; includes uncommitted source definitions; not publication proof',
    'entriesIncludingVariants': entries,
    'entriesWithoutGeneratedVariantSuffix': base_count,
    'generatedVariants': entries-base_count,
    'dedicatedThemeAssetsPresentAndMapped': linked,
    'missingDedicatedThemeAssets': entries-linked,
    'dedicatedRelicsMapped': len(relics),
    'proceduralRelicsAreNotFinal': True,
    'catalogueSha256': hashlib.sha256((ROOT / 'build/creature-art-catalogue.json').read_bytes()).hexdigest(),
    'themeMappingSha256': hashlib.sha256(mapping_path.read_bytes()).hexdigest(),
    'entries': rows,
}
target = ROOT / 'docs/creature-art-inventory.json'
target.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

out = [
    '# Temi e reliquie delle creature da completare', '',
    'Inventario dedicato richiesto il 28 ottobre 2026. Non avvia generazioni massive e non sostituisce le priorità della patch online. Nessuna riga è segnata 100%: l’approvazione visiva e l’integrazione si verificano separatamente.', '',
    '## Fotografia del catalogo attuale', '',
    f'- Esportazione reale `defaultMonsterBookEntries`: **{entries} voci**, comprese **{entries-base_count} varianti generate**. Le **{base_count} voci senza suffisso `_variante_`** includono già specie e varianti scritte a mano: non equivalgono automaticamente a specie biologiche uniche.',
    f'- **{linked} scene dedicate collegate ed esistenti**, **{entries-linked} voci senza una scena dedicata collegata**.',
    f'- **{len(relics)} reliquie artwork dedicate collegate nel renderer dei mostri**. Conferme e test sono documentati nei manifest specifici: la presenza di un file non assegna automaticamente un’approvazione. Le altre usano `OculumMonsterRelicPainter`: silhouette vettoriali di famiglia con colori/seme, fallback funzionanti non definitivi.',
    f'- Data export UTC: `{catalogue["exportedAtUtc"]}`. Commit base `{commit}`; contiene le definizioni locali successive, non prova una pubblicazione.',
    '- Inventario completo leggibile da strumenti: [creature-art-inventory.json](creature-art-inventory.json), con descrizione fisica integrale, anatomia, punti deboli, atteggiamento, elementi, piani, drop, inventario e regole di ogni voce.',
    '- I colori casuali di una stessa specie non sono contati qui come nuove specie. Per ogni futura variante cromatica verificare se richiede una scena separata o una variazione approvata; non usare una ricolorazione come sostituto delle differenze anatomiche/ambientali.', '',
    '## Come usare ogni riga prima di disegnare', '',
    '1. Aprire la voce del catalogo alla fonte indicata e la sua riga completa nel JSON. Leggere **descrizione fisica e anatomia di quel mostro**, non soltanto nome o ID.',
    '2. Confrontare materiali, colori, elemento, piano/ambiente, atteggiamento e punto debole. La posa deve esprimere carattere e ruolo; gli attacchi possono orientare l’illustrazione ma non inventare nuovi poteri canonici.',
    '3. Le parti della Precisione comprendono anche strutture interne o bersagli nascosti: non disegnare occhi umani sopra un elmo chiuso o nuclei esposti solo perché compaiono nella lista di combattimento. La descrizione esplicita prevale sul generatore anatomico generico; segnalare discrepanze.',
    '4. Preparare scena desktop, ricomposizione telefono e reliquia personale. Distinguere asset generato, file collegato, verifica con veri controlli e approvazione dell’utente. Conservare vecchi file finché i nuovi non sono verificati.',
    '5. Per ogni variante adattare davvero anatomia, materiali, protezioni, atteggiamento e habitat: non basta cambiare colore. La reliquia visiva non diventa un nuovo drop o bonus senza una regola.', '',
    '## Regole da fornire al prossimo generatore', '',
    'Consultare SEMPRE questi documenti aggiornati, senza lasciarli indietro:', '',
    '- [Regole confermate](OCULUM_REGOLE_CONFERMATE.md) e [manuale](manuale-consultazione.md): ultime correzioni esplicite dell’utente prevalgono; non inventare numeri o effetti dall’illustrazione.',
    '- [Canone visivo](OCULUM_LORE_VISIVA.md), [diciture integrali dell’utente](DICITURE_UTENTE_2026-10-27.md), [Visual Bible](../design/OCULUM-VISUAL-BIBLE.md), [attività e conferme](DA_FARE_PATCH_E_SUCCESSIVI.md).',
    '- **Rame fatato**: pittura anime fantasy opaca, pennellata morbida e materica, materiali leggibili, imperfezioni intenzionali. Preferenza «meno IA possibile»: evitare plasticità, simmetrie ripetute, lucido CGI, filigrane generiche identiche e dettagli arbitrari. Controllare mani, arti, armi, numero di ali/occhi e prospettiva.',
    '- Il riferimento approvato `assets/oculum/home_art/amber_shore.png` definisce la tecnica, non una scena da copiare. Ritrovare il percorso registrato nel canone prima di passarlo al generatore.',
    '- Centro realmente leggibile con la UI, soggetti ai margini e tutti gli elementi importanti entro pagina. Nessun testo, logo o interfaccia dipinti. Le decorazioni non intercettano click. Desktop, tablet e telefono hanno ricomposizioni coerenti.',
    '- Nessun ritratto imposto nel Monster Book: la creatura appare nel tema canonico e nello sfondo della pagina comprata, centrato entro i margini. Nessun cambiamento ai ritratti personalizzati salvati.',
    '- Luna buona/protettiva, morta e assente dal cielo ordinario. Sole con occhio canonico, simboli solari con occhio nel disco raggiato. Sotterranei: tetto di roccia, nessun cielo/Sole/Luna/nubi. Orea Zalira: due soli senza occhi, eccezione esplicita. Carne Viva: vuoto assoluto, nessun mondo lontano.',
    '- Guardie generiche entrambe con **elmo solare completo**, non volto scoperto; Elité d’oro e visibilmente più forte. Lusier ed Erik sono eccezioni personali a volto scoperto. Angeli2 ali, Arcangeli4, Serafini6; occhi sulle ali dei Serafini.',
    '- Mostro lunare: quattro cristalli `#7B68EE`, cristallo posteriore anche occhio, luna nel cristallo centrale; variante demoniaca di metallo incandescente e cristalli rossi, con luna comunque presente.',
    '- Scostubandito Errato e Veterano: tema Scostubandito canonico, scudo davanti; solo Veterano con taglio all’occhio e occhi del colore della sua magia. Non riprodurre il topolino della prima reference.',
    '- Grofix: muschio/filamenti/radici infestanti, cristalli lunghi e variegati secondo il materiale assorbito, non un normale golem di pietra. Leggere la voce e il materiale ospite.',
    '- Senka: unico tema con spicchio lunare benevolo come apparizione personale. Lost Town scavata in gironi circolari separati nella montagna, senza collegamenti fra gironi. Basso povero e fumi violacei d’Oculum esausto; ricchezza crescente verso alto, marmo/oro solare e aria pulita. Sky felice nella stanza povera in basso a destra; Haniel normale nascosto in basso a sinistra fra alberi e fumi.',
    '- Haniel ufficiale v4: nessun occhiale, capelli argentati sciolti wolf cut alle spalle, nero medievale elegante e argento annerito su spalle/dorso/gambali. Quattro ali soltanto nella variante Arcangelo da Master, segreto per Senka e Sky: non inserirle nel tema personale.',
    '- Scrivere sempre **Chaos** nei contenuti visibili. Identificativi legacy restano compatibili.',
    '- In caso di conflitto non risolto: riportare regola precedente e nuova richiesta, chiedere se è eccezione o modifica generale. Non richiedere conferme già esplicite.', '',
    '## Esempi locali e stato delle conferme', '',
    'Queste immagini servono come riferimenti originali; non attestano da sole pubblicazione o resa con UI. Il canone e le conferme umane hanno priorità su eventuali manifest storici rimasti indietro.', '',
    '| Riferimento | File attuale | Stato da preservare |',
    '|---|---|---|',
    '| Tecnica Rame fatato | `assets/oculum/home_art/amber_shore.png` | Riferimento approvato; non copiarne la scena. |',
    '| Guardia Solare | `assets/oculum/home_art/theme_guardia_solare_v2.png` | Esiste e collegata; verificare conferma finale del v2 nel registro. |',
    '| Guardia Solare Elité | `assets/oculum/home_art/theme_guardia_solare_elite_v2.png` | Esiste e collegata; oro, elmo completo, differenza di forza. |',
    '| Sky | `assets/oculum/home_art/character_sky_v2.png` | Design approvato: treccia laterale e vestiti consumati/rattoppati. |',
    '| Haniel | `assets/oculum/home_art/character_haniel_v4.png` | Aspetto ufficiale approvato; v3 con occhiali/legatura obsoleto. |',
    '| Senka / Lost Town | `assets/oculum/home_art/theme_senka_kamaria_v3.png` | Gironi e composizione desktop approvati. |',
    '| Senka telefono | `assets/oculum/home_art/theme_senka_kamaria_mobile_v2.png` | Ricomposizione derivata; verificare resa mobile e conferma. |',
    '| Reliquia Senka | `assets/oculum/home_art/relic_senka_kamaria_v1.png` | Approvata; non sostituisce le reliquie mancanti dei mostri. |', '',
    'Manifest: `ART_SOLARI_SKY_HANIEL_2026-10-28.json`, `ART_HANIEL_UFFICIALE_2026-10-28.json`, `ART_SENKA_GIRONI_2026-10-28.json`. Conservano prompt e provenienza.', '',
    '## Sequenza di lavorazione proposta', '',
    'Prima le creature della sessione e quelle aggiunte esplicitamente: Guardie/Guardiani/Serafini, Errato/Veterano, Grofix, Mostro lunare e demoniaco, poi i mostri nominati nelle ultime richieste. Continuare per ambiente, rispettando prima la descrizione/anatomia di ciascuna voce. Le quantità richieste per le micro realtà restano in DA_FARE: questo inventario non afferma che tutte siano già state aggiunte.', '',
    'Per le righe sotto, **R = reliquia dedicata mancante**, oggi sostituita dal pittore procedurale di famiglia. Non significa assenza totale di decorazione. Le scene elencate sono solo quelle davvero collegate, non candidate trovate per somiglianza di nome. Descrizioni, atteggiamenti e drop sono abbreviati qui; il JSON mantiene il testo completo.', '',
    '## Revisione estesa richiesta', '', 'Adeguare tutte le reliquie alla descrizione/anatomia del proprio mostro senza necessità di cambiare nome: arretrato da curare voce per voce, non completato globalmente. Grofix: background desktop e telefono generati e collegati, attesa approvazione finale e prova UI; manifest ART_GROFIX_BACKGROUND_2026-10-28.json. Le due reliquie Guardie v1 sono approvate, con6 test widget locali passati.', '', '## Inventario per voce e variante', '',
    '| Creatura / variante | Fonte catalogo | Elemento / ambienti | Descrizione fisica | Anatomia del combattimento | Punto debole | Atteggiamento | Materiali/drop registrati | Tema / reliquia |',
    '|---|---|---|---|---|---|---|---|---|',
]
for row in sorted(rows, key=lambda r: (r['themeAssetExists'], r['name'].casefold(), r['id'])):
    relic_text = f'`{row["relicAsset"]}` presente, approvata' if row['relicAsset'] else 'R'
    theme = (f'`{row["themeAsset"]}` presente' if row['themeAssetExists'] else 'Scena mancante, fallback') + '; ' + relic_text
    out.append('| ' + ' | '.join([
        f'**{brief(row["name"],100)}**<br>`{row["id"]}`',
        f'`{row["sourceLocation"]}`',
        brief(f'{row["element"]} / {", ".join(row["planes"]) or "non specificati"}', 100),
        brief(row['physicalDescription'], 220),
        brief(', '.join(row['anatomyLabels']), 180),
        brief(row['weakPoint'], 125),
        brief(row['naturalAttitude'], 125),
        brief(', '.join(row['drops']) or 'nessuno specifico', 100),
        theme,
    ]) + ' |')

out += ['', '## Riproduzione e verifica', '',
        '`dart run scripts/export_creature_art_inventory.dart` esporta il catalogo puro senza importare il runtime Flutter. `python scripts/build_creature_art_inventory.py` ricostruisce questo inventario e il JSON, controllando la presenza degli asset collegati. Nessuna immagine viene generata e nessuna approvazione viene assegnata automaticamente.', '',
        'Le immagini personali già presenti ma non collegate al renderer del mostro restano candidate, elencate nel JSON senza confonderle con scene effettivamente usate. Le righe inventate dal catalogo tramite funzioni riportano la funzione generatrice, non una falsa posizione di definizione letterale.', '']
(ROOT / 'docs/TEMI_CREATURE_DA_COMPLETARE.md').write_text('\n'.join(out), encoding='utf-8')
print(f'{entries} entries; {linked} mapped scenes; {entries-linked} missing scenes; {len(relics)} mapped dedicated creature relics')
