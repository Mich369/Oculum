# Revisione del 20 ottobre 2026

## Modifiche presenti nel checkout

- Emblema dello Slime custode nell'alchimista: base 200 Obser, 120 HP, fino a tre protetti, +3 alle quattro statistiche e +2 ai sottotratti. Pool condiviso e legame allo scontro; niente rigenerazione Pawn. Parametri modificabili dal menu inventario e conservati nel JSON.
- Catalogo oggetti del Master filtrabile per grado e categoria; categorie ibride conservate.
- Prezzo persistente per mercante: normalmente 95–105%, 3% dei negozi a 125%, 1% a 85%. Il modificatore non è dichiarato nell'interfaccia.
- Stato personale di utilizzo Open conservato nel JSON e azzerato al Riposo Lungo. Open Buff attivato dal comando originale; collocazione nei tre pannelli modificabile senza perdere l'elemento. Impostazioni effetti avanzate espandibili.
- Forme non utilizzabili per cooldown, costo minimo o requisito escluse dai pannelli. I sottotratti restano disponibili come tiri.
- Open mancanti dei mostri completate con bonus al danno base, Buff Open e capacità ridotta a recupero autonomo; conservate le definizioni personalizzate già presenti.
- Risoluzione bersagli delle Open strutturate collegata al percorso comune online/offline.
- Trasferimenti scheda: timeout più ampio e un solo reinvio per blocchi idempotenti, con invio cadenzato. Le azioni di gioco non vengono ritentate automaticamente per evitare doppie applicazioni.
- Test Auth: tentativi limitati ai problemi di rete, timeout per tentativo e chiusura dei client; errori HTTP non mascherati dai tentativi successivi.

## Verifiche concluse

- Correzione successiva al fallimento CI: il database conferma il primo trasferimento completo e il secondo interrotto dopo il blocco 6. Il recupero ora usa una connessione HTTP nuova, limitata e chiusa anche su timeout, con la stessa sessione, chiave pubblica e RPC autorizzata. Non esteso alle azioni di combattimento. Tre regressioni del recupero più nove di trasporto: 12 passate. Prova reale esplicita del percorso nuovo, scheda grande, reinvio, ACK e riconnessione passata in 21 secondi (`build/audit-chunk-forced-recovery.log`). Il primo tentativo del recupero aveva evidenziato un header apikey mancante, corretto prima della prova riuscita.
- Chrome ha aperto il web locale e la schermata Online; non è una prova app↔web completata. Successivamente lo strumento ha nuovamente segnalato browser locale disabilitato. Il web precedentemente compilato richiede ricompilazione con la correzione di trasporto.
- Suite completa dopo il recupero HTTP: **907 passati, 5 saltati, zero errori**, exit 0, in 10 minuti e 24 secondi. I cinque skip richiedono parametri o servizi esterni espliciti; la prova Chrome↔Windows resta fra questi e non viene presentata come eseguita.
- Quattro prove Supabase reali dopo il recupero: **4 passate**, exit 0, in 1 minuto e 28 secondi. Auth, isolamento snapshot fra due ospiti, scheda grande con ACK e riconnessione, combattimento con scudi/difesa/danni/cura e aiuto sia −3 sia +4, ciascuno consumato una sola volta.
- Analisi Flutter completa: nessun problema (`flutter analyze --no-pub`).
- Cinque test emblema/catalogo/prezzi iniziali passati; aggiunta e passata regressione visibilità per costo/cooldown.
- Quattordici test combinati generazione mostri, pannelli desktop/telefono e emblema passati.
- Test online reale `oculum_combat_live_application_test.dart`: passato il 20 ottobre, due client autenticati nella stanza sintetica `e2931ac3-4ef1-4515-b762-8eb435bb1168`. Verifica difesa, scudi, danni, cura, aiuto firmato e duplicati. Si è attivato il fallback HTTPS dopo un timeout WebSocket; completamento in 1 minuto e 50 secondi.
- `git diff --check`: nessun errore; avvisi sui terminatori di riga Windows.

## Verifiche ancora da concludere

- La prima suite (`build/audit-full-tests-20261020.log`) aveva un test prezzi obsoleto: confrontava il prezzo base del Segno del Fato con il prezzo realmente pagato dopo il modificatore persistente del mercante. Corretto il confronto con `shopCost`; regressione mirata e intera suite finale passate.
- Nuova distribuzione Windows, Windows Test, APK e web da compilare e verificare. La distribuzione precedente non è una prova di questi sorgenti.
- Prova manuale con applicazione Windows e Chrome, e terzo dispositivo indipendente: non completata su questi sorgenti. La prova automatica con due client Supabase non la sostituisce.
- Il browser locale segnala `Local browser use is disabled in Work settings`. In attesa dell'abilitazione da parte dell'utente. Compilazione impostata `-StageOnly`: nessuna installazione automatica dei pacchetti finché la prova richiesta non è completata.
- Il plugin GitHub non ha restituito stati o run PR per il commit base `7562c2c4414b49c185a221794a2aa4fd0d5216c7`: nessuna certificazione CI o pubblicazione Pages da questo dato.

## Personalizzazione

Abilità, forme, elementi, collocazione nei pannelli, effetti, costi, cooldown, durata e bersagli rimangono negli editor/JSON esistenti. Il menu dell'emblema permette di cambiare HP, numero protetti, bonus e durata. Gli oggetti già salvati non vengono sostituiti dalle definizioni nuove del catalogo. Nessuna migrazione distruttiva o chiave privilegiata aggiunta.
