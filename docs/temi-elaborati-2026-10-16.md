# Nuovi temi decorativi

Tre temi aggiuntivi nelle impostazioni del tema:

- **Erbario sepolto**: legno con venature continue, radici agli angoli, foglie e piccoli fiori viola nella variante viva.
- **Orologeria funebre**: ottone brunito, quadranti con tacche e lancette, rivetti e raccordi meccanici.
- **Vetrata delle maree**: tessere di vetro marino, giunture piombate, conchiglie e dettagli di madreperla.

## Personalizzazione

Si possono cambiare palette e colori con i controlli esistenti. Le impostazioni della presentazione permettono di scegliere il pacchetto illustrato, la variante ferma/viva, l'intensità delle decorazioni e il movimento. I nuovi pacchetti usano le animazioni condivise esistenti; non introducono simulazioni fisiche o filmati propri.

Ogni pacchetto comprende cornici per pannelli, telefono, ritratto, statistiche e separatori, scene per desktop e telefono e cinque stati del pulsante: normale, hover, premuto, selezionato e disabilitato. I PNG non contengono testo. Il centro delle cornici è trasparente e il livello decorativo non intercetta i tocchi.

I pulsanti conservano posizione, azione e navigazione da tastiera. Il sistema condiviso applica le immagini ai componenti già compatibili con ThemeArtPack.

## Sorgenti e rigenerazione

- Sorgenti modificabili: `design/themes/buried_herbarium`, `design/themes/funeral_clockwork`, `design/themes/tidal_stained_glass`.
- PNG locali: cartelle corrispondenti in `assets/themes`.
- Generatore: `scripts/build_elaborate_theme_packs.cjs`, con il percorso del modulo `sharp` come argomento facoltativo.
- Registro: `scripts/build_theme_design_inventory.ps1` (69 identità).

Il generatore generale conserva questi tre pacchetti; per rigenerarli usare il loro generatore dedicato.

## Verifiche

Test dedicati: esistenza degli asset, differenze tra le varianti, centro trasparente, clic e dimensioni su 390×844, 1920×1080 e 1080×1920. Le verifiche delle cornici non sostituiscono una revisione manuale di tutte le pagine dell'app.

## Copertura dei 58 elementi

Le impostazioni includono un preset `Elemento · …` per ciascuno dei 58 elementi ufficiali delle Resistenze, da Fisico a Sconosciuto. Ghiaccio / Gelo e Spirituale sono espliciti. Fisico, Gelo e Spirituale usano cornici esportate da Canva; gli altri 55 elementi hanno nuovi motivi vettoriali originali, materiali raster locali e PNG esportati.

La tabella completa è in `docs/design/element-theme-packs.json`; materiali, motivi, accenti e movimento dei 55 nuovi pacchetti si configurano in `docs/design/element-pack-specs.json`. Il generatore `scripts/build_element_theme_packs.cjs` aggiorna il registro Flutter e produce i PNG; `--finalize-only` ricostruisce manifest e panoramica dai PNG esistenti. Le palette sono in `lib/src/main/oculum_element_themes.dart`. I temi storici restano selezionabili. I nuovi motivi sono cornici e simboli, non 55 dipinti di sfondo.

Le sorgenti modificabili si trovano in `design/themes/element_pack_<elemento>/`, le immagini utilizzate dall'app in `assets/themes/element_pack_<elemento>/`. La panoramica è `design/element-pack-overview.png`. Cenere utilizza anche la texture effettivamente esportata da Canva, conservata in `design/materials/canva-20261016/`.

Le animazioni dei pacchetti elementali sono disegnate dal painter condiviso `oculum_element_ambient_art.dart`: per esempio braci discendenti che svaniscono, polvere, gocce, onde, petali, anime e sabbia della clessidra. L'animazione rimane sul bordo e non intercetta i tocchi. I tipi di movimento sono condivisi fra elementi affini; simboli e materiali distinguono i pacchetti. Sono rispettate le impostazioni di movimento ridotto/disabilitato e la sospensione delle pagine fuori vista.

Il tema reattivo al combattimento sceglie il pacchetto dell’elemento dominante anche per i pulsanti. Cenere usa la famiglia della polvere; Ghiaccio e Spiritualità sono riconosciuti come alias di Gelo e Spirituale. Le regole di danno e resistenza restano indipendenti dalla decorazione.
