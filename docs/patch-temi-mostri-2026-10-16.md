# Temi, mostri e azioni contestuali — 16 ottobre 2026

## Aspetto e impostazioni modificabili

- 58 preset elementali, corrispondenti agli elementi delle Resistenze.
- 55 nuovi pacchetti con motivi SVG originali, texture locali e PNG esportati; Fisico, Gelo e Spirituale usano le cornici effettivamente generate ed esportate da Canva.
- Tre ulteriori temi: Erbario sepolto, Orologeria funebre e Vetrata delle maree.
- Tema Sogno con accenti blu, viola e rosa; Natura con rami spogli nella variante ferma e piccoli fiori nella variante viva.
- Cenere include la nuova texture Canva. Legno e corteccia conservano venature raster continue.
- Personalizzazioni esistenti conservate: palette, colori personali, pacchetto manuale, variante, intensità, scala e movimento. Non cambia la posizione dei comandi.
- Animazioni elementali disegnate sui bordi: braci, polvere, gocce, onde, anime, petali, riflessi e altri movimenti condivisi fra elementi affini. I PNG sono statici; le animazioni vengono eseguite da Flutter. Centro trasparente e livelli decorativi non interattivi.
- Il tema di combattimento seleziona anche la cornice dei pulsanti dall'elemento dominante. Ghiaccio e Spiritualità sono riconosciuti come alias.

### Dove intervenire sui sorgenti

| Contenuto | File/cartella |
| --- | --- |
| Elementi, materiali, accenti e movimenti | `docs/design/element-pack-specs.json` |
| Associazione elemento/pacchetto | `docs/design/element-theme-packs.json` |
| Palette selezionabili | `lib/src/main/oculum_element_themes.dart` |
| Motivi e sorgenti modificabili | `design/themes/` |
| Originali Canva | `design/materials/canva-20261016/` |
| PNG caricati dall'app | `assets/themes/` |
| Esportatore dei 55 elementi | `scripts/build_element_theme_packs.cjs` |
| Esportatore cornici Canva | `scripts/build_canva_theme_frames.cjs` |
| Esportatore dei tre temi aggiuntivi | `scripts/build_elaborate_theme_packs.cjs` |
| Movimento sui bordi | `lib/widgets/oculum_element_ambient_art.dart` |

La panoramica `design/element-pack-overview.png` mostra simboli e cornici dei 55 nuovi pacchetti. Non equivale a 55 nuovi dipinti di sfondo. Il collegamento a Canva non è necessario durante l'esecuzione dell'app.

## Vita e Occhi dei Caduti

- La Vita usa Resilienza × (10 + 5 × grado), con grado limitato a 0–12. Esempio: 3 Resilienza danno 30 HP al grado 0, 45 al grado I e 60 al grado II.
- Adeguati anche i percorsi di vita dei Pawn, recupero e rinascita degli Occhi.
- L'evocazione salva prima la scheda proprietaria, crea/riutilizza un altro posto e identifica esplicitamente la nuova scheda come Occhio.
- Recupero delle schede mancanti di Occhi già attivi, senza ripagare l'evocazione, assegnare esperienza o duplicare i bonus.
- Bonus dell'evocazione sincronizzati con i valori correnti e rimossi alla disevocazione. Questi bonus temporanei non assegnano la ricompensa delle sei statistiche base.
- Verificato il ciclo evocazione, recupero della scheda mancante, salvataggio, ricaricamento e disevocazione, conservando le Art ereditate.

## Mostri, abilità e oggetti

- Varianti individuali assegnate alla creazione in base a corpo, elemento e comportamento: due tecniche e una passiva, conservate nel JSON. Le tecniche fisiche hanno costi fissi; quelle che scalano con l'investimento di Oculum mantengono un intervallo.
- Catalogo delle tecniche selezionabile; una selezione destinata a un'Art viene inserita nell'Art anche quando deriva da una tecnica naturale. Controllo della scheda di origine prima dell'aggiunta.
- Le Art normali mantengono tre forme; l'estensione Defiled prevede IV e V con effetti e costi espliciti.
- Costi delle tecniche del bestiario normalizzati: una tecnica che non trae beneficio dall'Oculum aggiuntivo non offre un intervallo inutile. Esempio: Rimbalzo dello Slime usa costi 1/1, 4/4 e 7/7; Palla di roccia e Indurimento conservano costi variabili perché scalano realmente.
- Catalogo di almeno 100 pergamene di tecniche distinte per nome/identità, con effetti, costo in Volontà e cooldown quando apprese. Il test controlla anche il salvataggio degli effetti. Le pergamene di questo catalogo preparano effetti sul lanciatore e bonus al prossimo attacco, come specificato nella loro descrizione.
- Abilità configurabili per equipaggiamento e titoli: effetti strutturati, costo e cooldown.
- Mercante con stock persistente fra riavvii, beni essenziali in alto e consigli basati sulle statistiche carenti. Pawn V2 compare nel 10% dei nuovi stock; Vitalium Ridefinito nel 98%. Gli stock già salvati restano conservati.

## Note e menu contestuali

- Note locali/online con fino a quattro immagini da 6 MB ciascuna; l'originale viene conservato e si può ingrandire. Trasferimenti Realtime grandi suddivisi in blocchi. Non è una verifica manuale di consegna fra due dispositivi reali.
- Tasto destro, pressione prolungata e doppio clic sulle tessere compatibili aprono lo stesso menu condiviso.
- Menu delle statistiche: tiro/modifica se disponibili, manuale, statistiche e bonus, sottotratti, resistenze, Vita/scudi/condizioni, danni e cura, più incrementi dove previsti.
- Menu Vita: resistenze, stile della barra, Vita e HP temporanei, scudi, condizioni, danni e cura. Disponibile anche nella visuale rapida.
- I menu usano la palette corrente e coordinate relative alla superficie visibile. Un menu aperto su una scheda non applica un'azione se nel frattempo cambia la scheda.
- Conservati i menu esistenti di titoli, inventario, condizioni e mappe.

## Verifiche e limiti

La suite completa locale ha superato 785 test con 2 test opzionali saltati prima dell'ultima estensione dei menu. Il nuovo test dedicato verifica separatamente l'equivalenza fra tasto destro e pressione prolungata, l'esecuzione del tiro scelto e il clic normale. La CI esegue nuovamente analisi e suite sul commit pubblicato.

I test automatici non dimostrano una revisione visiva manuale di ogni pagina, un bilanciamento completo di ogni incontro o il funzionamento su due dispositivi reali. I nuovi kit individuali includono tecniche condivise per anatomie affini: non sono tutti attacchi scritti individualmente da zero. Le versioni locali vengono sostituite solo dopo aver verificato commit, artefatti, archivi e runtime della nuova distribuzione GitHub.
