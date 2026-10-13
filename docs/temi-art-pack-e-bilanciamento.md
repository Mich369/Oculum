# Theme Art Pack e coerenza dei mostri

## Modificabile dal giocatore
I temi sono puramente decorativi: nessun riordino, ridimensionamento o spostamento di pulsanti, nessun padding aggiuntivo o spazio introdotto nel layout.
- Tema selezionato e colori personalizzati esistenti.
- Pacchetto artistico: segue il tema oppure una selezione manuale.
- Dimensione e visibilità delle decorazioni con i cursori esistenti.
- Animazioni Complete, Ridotte o Disattivate; i PNG rimangono visibili.
- Ritratto personalizzato, ingrandimento e tutte le azioni esistenti della scheda.

## Modificabile nel progetto
- `design/OCULUM-VISUAL-BIBLE.md`: identità, materiali e regole comuni.
- `design/themes/<id>/composition.json`: composizione e identità di ciascuno dei 62 temi.
- `design/themes/<id>/*.svg`: cornici vettoriali modificabili.
- `scripts/build_theme_art_packs.cjs`: esportazione riproducibile dei PNG; accetta il percorso del modulo sharp come primo parametro.
- `lib/widgets/oculum_theme_sheet_art.dart`: spazi protetti, layout adattivo e movimento della scena.
- `design/theme-art-manifest.json`: dimensioni e hash degli asset realmente inclusi.

## Mostri: correzioni conservative
Identità, statistiche base, drop e requisiti dei mostri vengono conservati.

| Caso | Prima | Dopo |
| --- | --- | --- |
| Horror deboli | Book: 1/5/11; Art: 1/2/3 | Book e Art: 1/1, 2/2, 3/3 |
| Armatura sottopelle | Costi numerici malgrado il testo senza costo; varianti non riconosciute | Passiva senza risorsa e senza costo, comprese le varianti |
| Inferno in corpo / Rigenerazione di lava | Passive con metadati di costo incompleti | Tipo Passiva mostro e nessuna risorsa consumata |
| Aculei precisi III | Descrizione 11/11; limiti 10/11; varianti instradate al costo di Lancio | Descrizione e limiti 10/11 anche nelle varianti |
| Rigenerazione Larva | 3/3/3 applicati | 3/5/8 come descritto |
| Rigenerazione Golem | 8/8/8 applicati | 8/12/16 come descritto |
| Rigenerazione Cuore | 15/15/15 applicati | 15/20/25 come descritto |
| Guardia horror variante | Suffisso variante poteva classificarla come attacco | Riconoscimento sullo stesso ID base della tecnica |
| Attacchi generici e horror | Il totale comprendeva già Danni base e rimaneva come bonus senza scadenza | Solo bonus della tecnica, consumato dal prossimo attacco; Danni base conteggiati una sola volta |

Questa revisione corregge discrepanze verificabili. Non pretende di certificare l'equilibrio di ogni incontro senza una simulazione delle scelte del Master e del gruppo.

## Provenienza
Figma: https://www.figma.com/design/Dw1F8sR6bzTCuGkaH2CEeS — Visual Bible dei 62 temi, tavole desktop/tablet/mobile e quattro cornici vettoriali. I PNG esportati hanno richiesto una maschera alpha dal sorgente per eliminare il fondo del canvas.

Canva: https://www.canva.com/M/MAHX5OhB8Ts — concept botanico originale, conservato come riferimento; non spacciato per un PNG runtime con trasparenza verificata.

Creative Production: board `f6cee63f-2d3d-4c56-8089-0d44f7d23c45`, tavole degli asset.

Adobe: inizializzazione fallita due volte con errore interno. Figma ha raggiunto il limite Starter dopo la creazione delle tavole. Gli asset locali non dipendono da questi servizi.

Game Studio: applicate le indicazioni di architettura condivisa per separare le correzioni delle regole dal rendering e mantenere identità, salvataggi e verifiche.
