# Verifica Oculum — 20 ottobre 2026

## Vincoli confermati

- Mantenere Supabase sul piano gratuito: nessun upgrade, acquisto o aumento di risorse a pagamento autorizzato.
- Preservare salvataggi, immagini, JSON e funzionamento offline.
- L'ultima schermata inviata dall'utente mostra il progetto Healthy, CPU47%, RAM51%, disco25%, 12/60 connessioni e migrazione `reduce_oculum_room_io`, ma ancora l'avviso Disk IO Budget. Sono valori della schermata, non una misura continua né prova che il budget sia ripristinato. Ridurre query/scritture e test ripetuti; niente upgrade a pagamento.
- A ogni distribuzione pubblicare e verificare tutti gli artifact delle build GitHub riuscite come download senza login, anche manualmente se l'automazione fallisce. Menu a tendina solo web; download ospitati su GitHub, senza traffico Supabase. Direttiva registrata anche in AGENTS.md.

## Risultati effettivi

- Dashboard Chrome accessibile. Progetto Healthy; il riepilogo del ciclo 27 settembre–27 ottobre mostra 7,672 GB di egress su 5 GB inclusi. L'avviso di quota non equivale a una prova che ogni operazione sia attualmente bloccata.
- Nel campione SQL non risultavano query applicative bloccate. Le statistiche cumulative mostravano anche query di catalogo e autenticazione lente: questo campione non dimostra da solo la causa del picco CPU.
- Migrazione additiva `reduce_oculum_room_io` applicata: indici per ultimo evento per tipo, richieste pending e sessioni recenti. Il recupero dell'ultima turnistica usa l'indice dedicato in EXPLAIN. Nessun dato cancellato, nessuna policy allargata.
- `oculum_supabase_live_connection_test.dart`, con `OculumLiveSupabaseTest=true`: passato il 20 ottobre dopo il ripristino del servizio.
- `oculum_combat_live_application_test.dart`, con `OculumLiveRealtimeTest=true`: passato. Due client autenticati reali verificano difesa, danni, cura e aiuto con segno. Sono processi di test sulla stessa macchina, non due dispositivi fisici e non una prova completa della UI Windows contro Chrome.
- `oculum_realtime_delivery_test.dart`: 10 test simulati passati, compresi invio a blocchi, ACK destinatario, riconnessione e recupero turnistica. Il nuovo test verifica che dieci refresh simultanei non riscrivano una presenza invariata e che il cambio scheda venga registrato subito.
- `oculum_aberrations_penetration_test.dart`: 3 test locali passati su categorie, fasi, raggi e parser della penetrazione.

## Correzioni nel client

- Accorpamento dei refresh concorrenti; presenza invariata riscritta al massimo ogni 15 secondi, variazioni registrate immediatamente. Backoff fino a 60 secondi su errori della stanza.
- Prima dell'invio di una nuova scheda si attende la registrazione della presenza. Prima del replay si acquisiscono ruoli e campagna del Master.
- Il player connesso usa la turnistica remota; l'assenza temporanea di uno snapshot non riattiva silenziosamente quella locale. La copia locale resta conservata.
- Penetrazione e percentuale contro gli Scudi restano nel pacchetto del singolo colpo e si azzerano dopo l'applicazione. La percentuale contro gli Scudi non aumenta anche l'intero danno per effetto del parser.
- Aberrazioni con categorie/fasi, varianti Solare e Angelica e raggi modificabili; risveglio finale della Superiore persistente e non ripetibile.
- Valore Oculum nella barra adattato allo spazio disponibile.

## Personalizzazione

Forme delle tecniche, danno, elemento, bersagli, costi, cooldown, penetrazione e percentuale contro Scudi restano modificabili negli editor e salvati nel JSON. Nessuna nuova definizione sostituisce automaticamente una skill personalizzata salvata.

## Verifiche da chiudere

- Suite locale completa del 20 ottobre: report `build/test-full-final-20261020.json`, evento finale `success: true` (465720 ms). Non equivale a prova UI fra dispositivi.
- Approvazione riconfermata dall'utente: nuovo utente in attesa del Master; identità già approvata nella stessa stanza ammessa al rientro, salvo revoca/espulsione. Verificata la definizione delle RPC sul backend: l'upsert di `oculum_open_room` aggiorna soltanto il nome e conserva lo stato membership, mentre solo il proprietario può cambiarlo con `oculum_decide_room_member`. Un nuovo ospite con nuova identità richiede una nuova approvazione.
- Preparato `tool/online_playtest.dart`: entrypoint separato dalla distribuzione, richiede profilo `online-playtest`, preferenze e sessioni Auth in memoria, una scheda sintetica per processo; salvaDati disabilitato per i dati della prova. Le azioni richiamano i pannelli e il trasporto di produzione. Non dichiarare passata la prova finché non viene completata fra tre processi distinti.

Analizzatore finale, suite locale completa dopo l'ultima correzione, pacchetti finali con hash, CI del commit finale e prova completa delle UI Windows/Chrome sono verifiche distinte. Questa nota non dichiara quelle verifiche completate.
