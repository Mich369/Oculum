# Online: compatibilità tra reti e consegna schede

## Risultato dell'ispezione

- L'accesso è autenticato da Supabase Auth. Il codice stanza individua la stanza; le RPC verificano appartenenza approvata e ruolo sul server.
- La consegna persistente usa `oculum_emit_room_event` e `oculum_room_events`; l'RLS limita la lettura a mittente, destinatari autorizzati e staff quando l'evento è riservato allo staff. Realtime privato trasporta la notifica rapida, non è l'unica copia dell'evento.
- Le schede grandi sono divise in blocchi, ricomposte solo dopo aver ricevuto tutti i pezzi e riconosciute con `sheet_received_ack`. L'accettazione RPC del mittente non va mostrata come ricezione completata.
- Wi‑Fi, dati mobili, Ethernet e VPN sono trattati come disponibilità d'interfaccia. Dopo il ripristino del collegamento l'app forza subito un tentativo autenticato, senza aspettare il backoff massimo. Il plugin di connettività non può garantire che una rete abbia accesso a Internet.

## Modifiche in questa revisione

- Il client passa al journal HTTPS autenticato quando il WebSocket non si apre; il browser può usare lo stesso percorso. Non è stata aggiunta una tabella e non è richiesta una migrazione.
- Il callback di connessione che ripubblica la scheda/snapshot ora parte soltanto dopo `oculum_touch_room_session` riuscito e dopo il recupero iniziale degli eventi. Questo evita il rifiuto della prima scheda perché manca ancora la sessione server.
- Il fallback continua a interrogare presenza ed eventi ogni 3 secondi. Le richieste inviano solo nuovi eventi per sequenza; il set di ID consegnati evita doppie applicazioni nella sessione corrente. La riapertura non ripete eventi di combattimento scaduti: recupera separatamente l'ultimo snapshot persistente `initiative_shared` con RLS. La lettura dello snapshot è limitata a una volta per connessione, distinta dal polling.
- Gli snapshot ripristinati sono marcati solo nel client dopo la lettura autenticata del record. Il ricevitore accetta soltanto record con `authenticatedRole=master` e identità autenticata stampati dal database, anche se la sessione Master ha un nuovo ID o è temporaneamente offline. Gli eventi Realtime grezzi continuano a passare dalla verifica del record nel journal.
- Le azioni riservate e i destinatari continuano a essere validati dalla RPC e da RLS: il fallback non introduce scritture anonime né una seconda autorizzazione solo UI.
- Ogni bersaglio di un attacco riceve una richiesta separata con tiro nemico e DT visibili nel proprio log e nella scheda. Dalla richiesta può aprire «Skill e protezioni», applicare una difesa alla propria scheda e poi scegliere il tiro per quel bersaglio. La risposta applica condizioni ed effetti secondo l’esito e registra le perdite di Scudo Oculum, Scudo, HP temporanei e Vita.
- Le protezioni strutturate (Scudo, HP temporanei e resistenza elementale) sono classificate sia in Difesa sia in Supporto e utilità. Una resistenza elementale senza scadenza è salvata come `remaining=-1`; il calcolo del danno ora la considera attiva fino alla rimozione, abbinandola all’elemento dell’attacco.

## Verifiche e limiti

- Analisi Dart mirata di `oculum_realtime_service.dart`, `oculum_realtime_integration.dart` e `oculum_realtime_delivery_test.dart`: passata il 20 ottobre 2026 (`No issues found`).
- `flutter test --no-pub test/oculum_realtime_delivery_test.dart`: 9 test passati, inclusi consegna/ACK scheda, fallback HTTPS, chiusura fight con snapshot completo e recupero di uno snapshot della turnistica più vecchio di cinque minuti con deduplicazione fra heartbeat.
- `flutter test --no-pub test/oculum_ability_text_parser_test.dart test/oculum_online_damage_layers_test.dart`: passato; verifica la classificazione delle protezioni difensive, le resistenze elementali persistenti e il percorso danni online con deduplicazione.
- Questo test usa un backend HTTP simulato in memoria; non è una prova online reale né un controllo live delle policy RLS.
- Test live Chrome ↔ Windows esistente: predisposto per una stanza temporanea; non ancora eseguito in questa revisione. Richiede Chrome, rete funzionante e sessioni Supabase Auth distinte. Una prova simulata non equivale a una prova reale su Wi‑Fi e rete mobile separati.
- Non è dimostrabile che "ogni rete" funzioni: captive portal, assenza di Internet e reti che bloccano anche HTTPS impediscono la sincronizzazione fino al ripristino dell'accesso. Offline resta disponibile.
- Supabase CLI non è installata in questo ambiente; i test SQL delle policy in `supabase/tests/oculum_room_authority.sql`, gli advisor del progetto e la migrazione applicata al backend remoto non sono stati eseguiti/verificati in questa sessione. Nessuna migrazione è stata aggiunta o applicata.
