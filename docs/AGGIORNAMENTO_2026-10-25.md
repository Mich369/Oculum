# Oculum — aggiornamento del 25 ottobre 2026

## Nuove creature

Il catalogo planare iniziale di questa lavorazione conteneva 357 voci fra specie e varianti canoniche; con le aggiunte successive arriva a 380. Con le 24 creature del ciclo, elencate separatamente dal catalogo planare, l’intero Monster Book raggiunge 1.144 voci. Le nuove voci della prima parte dell'aggiornamento sono:

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

Il Master vede tutti i temi e tutte le reliquie finché mantiene il ruolo. Aprendo la scheda destinataria e cliccando la sua reliquia può assegnare l’aspetto scelto soltanto a quella scheda. Il nome del destinatario compare nel selettore. Tema, reliquia e colore restano disponibili nel JSON della scheda anche quando il Master torna giocatore; il resto del catalogo rimane soggetto agli sblocchi normali. Nessuna scoperta o pagina Monster Book viene assegnata al party con questa operazione. Online l’assegnazione segue il percorso autenticato delle modifiche Master alle schede.

Il nuovo insieme illustrato comprende 162 immagini: i 150 temi del registro, quattro nuove versioni delle immagini Home e otto scene per le nuove creature. L'originale Rame fatato resta intatto. Tutti i 61 elementi disponibili hanno un tema: ai 58 precedenti si aggiungono Demoniaco, Nuvola e Roccia, con scenari coerenti e distinti. Sono inclusi piani, micro realtà, Hidenas, Benedict e tre temi dedicati.

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

Il comando verifica il commit di origine, avvia la build di distribuzione, attende il successo, pubblica i download pubblici della stessa run e aggiorna GitHub Pages. Si ferma sugli errori. Il push ordinario avvia le Actions previste: non aggiungere marcatori per saltare la CI. Le build sono eseguite su GitHub, senza build locali.

## Verifiche della prima fase (storico, precedenti alle ultime modifiche)

- Suite Flutter completa: 1.113 test passati, 6 saltati (`flutter test --no-pub --concurrency=2`).
- Integrità delle immagini: 154 WebP presenti, dimensioni valide, nessun duplicato identico; 58,9 MB complessivi. Rame fatato identico all'originale Git. I test verificano anche l'inclusione delle immagini nel bundle.
- Consultazione skill/Open su desktop e telefono, conservazione JSON, temi per i 61 elementi e danni Demoniaco/Diabolico verificati con test mirati.
- Catture della scheda reale a 1440 e 390 pixel per Hidenas, Indaco, Foresta Elementale e Sotterranei; decorazioni escluse dagli input.
- Pubblicazione e aggiornamento Windows: 9 + 3 test Python passati; script PowerShell verificato con GitHub simulato, senza avviare workflow reali.

CI GitHub, nuovi pacchetti e download pubblici aggiornati saranno verificati con i workflow successivi. Le prove online con applicazioni reali restano una verifica separata e non sono state eseguite in questa fase. I sei test condizionali saltati non costituiscono una verifica online reale.

## Ultime aggiunte del 25 ottobre

Precisione con anatomia specifica per ogni creatura e scelta lato/numero delle appendici. Rivelazione Master della voce esatta, Fratture progressive sugli arti, ali danneggiabili e caduta. Il Nucleo con fata del Fate Golem riflette senza tiro contrapposto, consumando la risorsa del turno.

NPC rapidi con elemento e tre skill distinte per Attacco, Supporto e Difesa. Catalogo grande delle singole skill, ordinamento per livello richiesto, prossima forma e anteprima delle evoluzioni dopo 0,9 secondi.

Ventidue ricette dai nuovi drop, comprese tre sete magiche resistenti. Creazione/forgiatura con chance 10 + Fortuna, limite 90% (100% Rebirth), bonus dal livello oggetto e +1 livello a ogni forgiatura riuscita. Fortuna Rebirth ×1,5 per le scroll, senza cambiare i tetti di apprendimento.

Trasparenza regolabile 0–40% con valore consigliato 18%, etichette opache e hover dei gruppi di azioni. Interfaccia telefono con accessi rapidi e azioni su due colonne; palette dei temi coerenti e distinte. I dettagli restano nel registro confermato e nel manuale.

Le verifiche della versione finale, la CI e la pubblicazione sono registrate separatamente quando completate; i numeri storici sopra non certificano le modifiche successive.

## Cosa puoi personalizzare

- Skill e Art: singole forme I/II/III, livello richiesto, risorse e limiti minimi/massimi, consumi aggiuntivi, formule, elementi, bersagli, durata, cooldown e attivazione. Il nuovo interruttore «Solo su colpo critico» è salvato nell’effetto JSON e rispetta la protezione degli Scudi critici.
- Monster Book: statistiche, livello, punto debole, habitat, resistenze, descrizione, skill, materiali e probabilità dei drop. Le quantità iniziali di Scudi critici e Schivate Oculum del Cavaliere sono dati del catalogo; le anatomie personalizzate possono definire `encounterRules.precisionBodyParts`, senza modificare il catalogo globale.
- Equipaggiamento e ricette: livello, peso, ingredienti/grammi, Danni, Difesa, Scudo, resistenze delle sete e abilità incorporate. Gli esiti di creazione restano nel JSON del singolo oggetto.
- NPC rapidi: elemento e tre tecniche suggerite, sostituibili prima della creazione; dopo la creazione gli editor ordinari conservano le personalizzazioni della scheda.
- Aspetto: tema e sfondo della singola scheda, colore HEX, modalità Statica/Viva/Ridotta, immagini Home e trasparenza delle superfici (preferenza locale 0–40%, consigliata 18%). Testi e icone mantengono la propria leggibilità.

Le regole confermate restano descritte nel manuale e nel registro; i nuovi preset non sostituiscono le definizioni personalizzate delle schede già salvate.

## Verifica del sorgente precedente all’integrazione del ciclo

- `flutter analyze --no-pub`: nessun problema rilevato.
- `flutter test --no-pub --concurrency=2 --reporter expanded`: 1.151 test passati, 6 test condizionali saltati; inclusi test grafici desktop/tablet/telefono, navigazione, consumi, salvataggi, Fratture e Scudi critici.
- Pubblicazione: 11 test Python; aggiornamento Windows isolato con conservazione salvataggi: 3 test Python. Comando PowerShell verificato con GitHub simulato e arresto sugli errori.
- Catalogo misurato: 23 nuove voci, 70 tecniche dedicate, 380 voci planari e 1.120 voci complessive comprese le varianti generate; 22 ricette. Asset: 162 WebP validi, 61,8 MB, nessun file mancante.

Questa verifica locale non include i sei test online condizionali. Le verifiche autenticate, le build GitHub, la pubblicazione e i pacchetti locali sono evidenze distinte; la run collegata ai download pubblici identifica il commit realmente compilato. Nessuna build locale dell’app è stata eseguita.

Questi conteggi e test si riferiscono alla versione `b917217d`, prima dell’integrazione del ciclo: 1.120 voci complessive. Il test PowerShell azzera il codice nativo dopo il caso negativo atteso, mantenendo gli assert che vietano la pubblicazione di workflow falliti.

Il controllo da 300 schede ha individuato ricerche annidate durante la selezione dei bersagli: la modalità Master locale ora viene riconosciuta prima della ricerca di Meccanio e il controllo del Costume dei Sempre Verde riusa il partecipante già individuato. Nessuna modifica ai bersagli ammessi, al rifiuto dei mostri o ai dati salvati. Il benchmark locale completo da 300 schede è passato, compresa la conservazione delle immagini e del salvataggio; le dieci modifiche di Vita e i dieci cambi turno hanno richiesto rispettivamente 10,96 e 10,35 secondi nel test debug locale. La verifica GitHub resta separata.

## Integrazione delle creature del ciclo — 26 ottobre

Incluse le 24 specie delle dodici fasi, con 48 tecniche aggiuntive, materiali propri e Open. Il totale delle aggiunte di questa patch diventa 47 voci e 118 tecniche; il Monster Book completo raggiunge 1.144 voci, mentre il catalogo planare resta a 380 perché le creature del ciclo sono una raccolta distinta. Il dossier mostra la fase e la ricerca combina nome, luogo e fase senza vincolare le scelte del Master al calendario.

Le scroll del ciclo si ottengono con naturale 18–19 (una tecnica) o 20 (entrambe), conservando costi ed effetti originali e il normale apprendimento. I materiali conservano la propria prova Drop. Valori, costi 1/2/3 Oculum, livelli delle forme, cooldown, anatomia, descrizioni e probabilità delle scroll sono modificabili nei dati esistenti e nel JSON. Le personalizzazioni salvate non vengono sovrascritte. Questa integrazione viene verificata e distribuita separatamente dalla precedente build; i download ne indicano il commit effettivamente compilato.

Verifica locale dell’integrazione: 71 test mirati passati e analisi statica senza problemi. Le prove delle scroll coprono sia il totale basso sia un bonus Drop elevato, con assenza di duplicati e soglie personalizzate rispettate. CI completa, nuovi pacchetti e pubblicazione vengono verificati sul commit successivo che contiene anche queste creature.
