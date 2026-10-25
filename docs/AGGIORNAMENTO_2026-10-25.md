# Oculum — aggiornamento del 25 ottobre 2026

## Nuove creature

Il catalogo planare contiene 357 voci fra specie e varianti canoniche. Le nuove voci di questa parte dell'aggiornamento sono:

- Uomo con la maschera: alla creazione assume una delle quattro discipline colorate.
- Verde: maggiore Resilienza e Ricordo Vitale permanente.
- Rosso: maggiore Volontà e Pugno serio, gratuito in Azioni e Reazioni con CD 3; Schianto si aggiunge ai Danni, poi +10/20/50%.
- Blu: maggiore Materia e Concatenazione di colpi. Riflessi +5 o Precisione sul punto debole noto; raffica risolta colpo per colpo, con interruzione critica.
- Viola: Oculum, spuntoni, scudi riflettenti nelle forme superiori; recupero di 2 Oculum al proprio turno o chance di uno temporaneo se già pieno.
- L'Ombra Ignota: maschera nera a spirale, un unico foro a mandorla e un solo occhio viola; Art L'Ombra, teletrasporto e attacchi d'ombra.
- Assassino Solare: oro inciso, raggi, piccoli soli e due frecce segugio con +3.
- Assassino Angelico: tre frecce con +9, Raggio Angelico, +25% Danni contro Chaos e recupero del 5% della Vita corrente ogni tre colpi che tolgono Vita.
- Vèndulo: quadrupede di grotta, muschio e placche sul muso; raschiata e protezione, senza bonus statistici straordinari.
- Rascalume: piccolo roditore notturno dai baffi luminosi; morso e lampo.
- Brumìlio: uccello minuto di piume e foschia; colpo d'ala e velo di nebbia.
- Gùravo: rettile basso con coda piatta e scaglie di pietra; coda e protezione.
- Mìrula: salamandra acquatica con membrane branchiali; spruzzo e fango.

Le cinque creature comuni partono dal livello 1 con 1 Resilienza, 1 Volontà, 1 Materia e 0 Oculum, due tecniche e materiali propri. Non ricevono aumenti straordinari alle statistiche. Le varianti sono separate per abilità, descrizione e drop, mantenendo i progressi di specie previsti.

## Temi e Home

Il nuovo insieme illustrato comprende 154 immagini: i 150 temi del registro e quattro nuove versioni delle immagini Home. L'originale Rame fatato resta intatto. Tutti i 61 elementi disponibili hanno un tema: ai 58 precedenti si aggiungono Demoniaco, Nuvola e Roccia, con scenari coerenti e distinti. Sono inclusi piani, micro realtà, Hidenas, Benedict e tre temi dedicati.

Corretto il vecchio alias che confondeva Demoniaco con Diabolico: restano distinti anche dopo la normalizzazione dei nomi inglesi. La difesa Diabolica applica il −75% ai danni Demoniaci confermato. Le chiavi delle resistenze già salvate non vengono rinominate o sovrascritte.

Gli sfondi riempiono la pagina dietro a controlli Flutter reali. La decorazione non intercetta clic. Desktop e telefono usano inquadrature adatte e superfici scure leggibili. Non si riutilizza più la vecchia scena locale sotto ai comandi, che poteva mostrare una reliquia sbagliata.

Il piano seleziona automaticamente il tema; la scelta manuale della singola scheda prevale. Mostri ed evocazioni mantengono il proprio aspetto. I colori possibili hanno pesi coerenti con specie e variante e sono fissati nel JSON alla creazione. Le reliquie delle creature sono disegnate con forme, incisioni e colori stabili.

Comprare una pagina del Monster Book sblocca tema e reliquia per il party della campagna. Una lettura riuscita che identifica il mostro dà il 90% di sblocco; una nuova lettura riuscita può riprovare. Ogni variante ha uno sblocco separato. Il selettore presenta quattro colonne e ricerca per nome o elemento.

Nella Home “Immagini Home” conserva la scelta manuale o il casuale di sessione. La seconda opzione, “Usa il tema attuale”, mostra la stessa illustrazione del tema della scheda. Cambiare tema aggiorna anche questa Home; tornare alla prima opzione conserva la precedente immagine scelta.

I selettori colore accettano #RGB, #RRGGBB e 0xAARRGGBB. Il colore si applica con Invio o con il segno di spunta; un testo non valido non sovrascrive il colore precedente.

Il canone e i riferimenti visivi sono in [OCULUM_LORE_VISIVA.md](OCULUM_LORE_VISIVA.md). Le storie sono suggerite solo dalle immagini. Gli Obser non sono decorazioni generiche. I Sotterranei hanno volte chiuse di roccia, senza cielo. Il Sole usa il riferimento di Benedict.

## Consultazione dei mostri

Ogni voce ha una consultazione separata per aspetto, comportamento, habitat, statistiche base, punto debole, resistenze, abilità, Open e drop. Ogni skill espone separatamente le forme I, II e III con livello richiesto, costo reale (incluse risorse aggiuntive), cooldown, bersagli dichiarati e testo degli effetti. Le attivazioni libere sono riconoscibili; le abilità senza costo statistico non mostrano un finto contatore 0/0.

Buff Open e Skill Open sono distinti. I codici interni non sostituiscono le descrizioni degli effetti speciali. Nella pagina Party il punto debole resta nascosto finché non viene scoperto; la nuova consultazione non modifica il JSON o gli effetti delle schede personalizzate. La descrizione delle nuove creature generate non ripete l'intera lista delle skill e non promette sprite non presenti.

## Percezione e lettura della potenza

Con dado naturale almeno 18 e lettura riuscita, il confronto usa Livello più somma delle quattro statistiche, ma invia e mostra solo una categoria narrativa. Parità entro ±10%, differenza lieve fra 10 e 35%, netta oltre 35%; nemico almeno doppio: “impossibile da battere”.

Se fallisci, il log indica la statistica più alta che ostacola la lettura. L'esito non rivela le quattro statistiche o il punteggio nascosto del bersaglio. Gli sblocchi sono condivisi tramite i dati della campagna esistenti, senza nuovi cicli di polling.

## Compatibilità e personalizzazione

Costi, risorse, bersagli, effetti, forme, livelli richiesti, durata, cooldown, statistiche, inventario e drop continuano a essere modificabili negli editor esistenti e conservati nel JSON. Le definizioni nuove non riscrivono le personalizzazioni salvate. Colori HEX, tema manuale e immagine Home sono modificabili per scheda.

Le regole precise e il manuale interno sono aggiornati insieme. Il separatore delle forme distingue i veri inizi I/II/III dai riferimenti interni come “forme II/III”, evitando descrizioni tronche e requisiti mancanti. I costi gratuiti espliciti restano gratuiti.

## Pubblicazione senza build locale

Questa fase prepara e verifica il sorgente. I pacchetti già presenti in build/distribution vengono conservati. Il nuovo sorgente diventa scaricabile dopo una build GitHub riuscita e la pubblicazione dei suoi artifact.

Da PowerShell, dopo il commit e push verificati:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\Oculum App\oculum\scripts\publish_oculum_github.ps1"
```

Il comando verifica il commit di origine, avvia la build di distribuzione, attende il successo, pubblica i download pubblici della stessa run e aggiorna GitHub Pages. Si ferma sugli errori. Nessuna build viene avviata dal commit con [skip ci].

## Verifiche completate

- Suite Flutter completa: 1.113 test passati, 6 saltati (`flutter test --no-pub --concurrency=2`).
- Integrità delle immagini: 154 WebP presenti, dimensioni valide, nessun duplicato identico; 58,9 MB complessivi. Rame fatato identico all'originale Git. I test verificano anche l'inclusione delle immagini nel bundle.
- Consultazione skill/Open su desktop e telefono, conservazione JSON, temi per i 61 elementi e danni Demoniaco/Diabolico verificati con test mirati.
- Catture della scheda reale a 1440 e 390 pixel per Hidenas, Indaco, Foresta Elementale e Sotterranei; decorazioni escluse dagli input.
- Pubblicazione e aggiornamento Windows: 9 + 3 test Python passati; script PowerShell verificato con GitHub simulato, senza avviare workflow reali.

CI GitHub, nuovi pacchetti e download pubblici aggiornati saranno verificati con i workflow successivi. Le prove online con applicazioni reali restano una verifica separata e non sono state eseguite in questa fase. I sei test condizionali saltati non costituiscono una verifica online reale.
