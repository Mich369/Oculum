# Priorità online e pannelli aperti — 21 ottobre 2026

## Verifica successiva e traffico

- Prova locale con quattro stati Oculum isolati superata: Master, attaccante, difensore e compagno. Azione nel proprio turno, Reazione, entrambe nello stesso turno, aiuto e difesa, rifiuto a risorse esaurite e consegne duplicate. File `test/oculum_four_profile_combat_test.dart`.
- Prova reale del 21 ottobre successiva: quattro identità Auth distinte, Master, difensore, attaccante via HTTPS e compagno. Turnistica comune, attacco, aiuto del compagno prima della difesa, ricevute, cura e patch Master superati in 2:03. Comando `flutter test --no-pub --dart-define=OculumLiveRealtimeTest=true test/oculum_combat_live_application_test.dart`. È una verifica del trasporto reale e dello stato del difensore, distinta dai quattro stati locali e da quattro finestre manuali.
- Dashboard Infrastructure/Usage letta via Chrome: FREE/Nano; corrente CPU3%, RAM54%, 13/60 connessioni. Egress10,46GB su5GB, Realtime249.784 su2milioni, picco7 su200. Avviso di grace period e possibili restrizioni402 dal20 novembre2026; banner problema tecnico Supabase in indagine. Nessun upgrade o modifica infrastrutturale.
- Ottimizzazione additive protocolVersion4: dopo ACK del Master i ritratti invariati sono referenziati per firma anziché reinviati a ogni aggiornamento. Solo se tutti gli Staff annunciano protocollo4; i client precedenti continuano a ricevere immagini complete. Un ricevitore senza immagine corrispondente richiede un invio completo e non conferma la copia incompleta. Test di ricezione conserva ritratto e aggiorna Vita senza duplicare la scheda.
- Parser/editor: danno intero per bersaglio, tutti gli avversari, sacrificio della fonte, Vita attuale/massima come formula; flag salvati nel JSON. Riflessione e malus Difesa dopo danno Vita esposti come proprietà modificabili, riusabili da altre entità.
- Trasparenza e Invisibilità: Velo6+livello /18+livello. Corrosione acida elementale. Bonus base e danno acido modificabili nell’editor delle condizioni; duration/stage e JSON preservati.

## Verifiche eseguite in questa ripresa

- Recuperate le tre chat indicate dall'utente; preservato il checkout con tutte le modifiche precedenti.
- 28 test locali online superati: consegna schede, riconnessione, revisioni delle patch, attacco/danni e ingresso con password.
- Test precedente con due identità Supabase reali superato.
- Esteso il test live a tre identità Auth distinte: Master, attaccante e difensore. Il Master pubblica la medesima turnistica ai due player; il terzo client usa HTTPS polling. Attacco, aiuto del Master alla difesa, ricevuta danni ai due osservatori, cura e patch della scheda verificati. Prima esecuzione superata in 2 minuti e 4 secondi (`build/online-three-live-20261021.json`). Non è una prova manuale in tre finestre.
- Dopo l'aggiunta dei timeout delle letture, la successiva esecuzione live ha fallito su un invio del Master con timeout di rete di 15 secondi (`build/online-three-bounded-live-20261021.json`). Non dichiarare il servizio online certificato al 100%. Su richiesta dell'utente non ripetere continuamente prove live che consumano risorse.
- Analisi Flutter iniziale: nessun problema; i controlli dopo l'ultima modifica UI vanno acquisiti separatamente.

## Supabase: problemi controllati

Progetto `jgpxdlkbuxhriltxezdc` attivo e healthy al controllo del connettore. Nell'intervallo 09:55–10:55 UTC i log PostgREST contenevano 64 messaggi di timeout Warp; il campione non attribuisce da solo la causa alle query dell'app. Nessuna attesa su lock applicativi nel campione di `pg_stat_activity`.

Gli advisor segnalano due foreign key senza indice, un indice mai usato, accesso di ospiti autenticati, protezione password compromesse disabilitata e RLS senza policy sulla tabella privata delle password. Le policy lette direttamente vincolano i salvataggi al proprietario e gli eventi alla membership/destinazione. L'assenza di policy sulla tabella privata mantiene negato l'accesso client. Nessuna policy allargata, nessun dato cancellato, nessun upgrade o spesa.

## Correzioni di questa ripresa

- Approvazione Master limitata ai nuovi partecipanti. Attacchi, aiuti, difese, utility e il singolo secondo tentativo consumano subito Azione/Reazione dalla turnistica visibile; l’uso viene incluso nel successivo evento di combattimento, senza richieste o round-trip dedicati a Supabase. Le copie online aggiornano il consumo al Master e lo riflettono localmente senza broadcast aggiuntivi.
- Ripresa con Chrome disponibile: 25 test locali superati su bundle selezionato, cartella ricevute, secondo tentativo difensivo, attacchi, stratificazione dei danni e trasporto/ripristino Realtime. Comando: `flutter test test/oculum_selected_sheet_delivery_test.dart test/oculum_received_sheet_folder_test.dart test/oculum_online_attack_delivery_test.dart test/oculum_realtime_delivery_test.dart test/oculum_online_damage_layers_test.dart`. Questi test non costituiscono una nuova prova contro Supabase reale.

- Letture Presence, replay eventi, ripristino turnistica, verifica broadcast e richieste pending: timeout di 10 secondi. Una lettura che non risponde non conserva indefinitamente il Future di sincronizzazione. Restano deduplicazione, verifiche backend e recupero successivo.
- Test locale specifico: una lettura Presence bloccata rilascia il refresh e permette la lettura successiva.
- Le pagine di dettaglio aperte (EXP, ritratto e gli altri dettagli che usano `openReferenceDetail`) si aggiornano un secondo dopo l'ultima modifica. I segnali di modifica, salvataggio, riepilogo online ed EXP alimentano un debounce locale. Nessun polling e nessuna richiesta Supabase aggiuntiva. Focus, controller e scorrimento restano nella stessa route.
- Il limite del passo CI dei test live passa a 10 minuti per comprendere il terzo client; non cambia i controlli né ignora i fallimenti.

## Distribuzione e arretrati

Ultima build completa GitHub letta: run `39566054981`, commit `b1ad087`, annullata. Il precedente run completo `39532670968` fallì nel test di combattimento live; gli altri workflow distinti risultavano riusciti. Questo non certifica la nuova distribuzione.

Build locale avviata in staging; la prima è stata interrotta dopo la nuova richiesta UI. Conservare la distribuzione precedente finché EXE con runtime, cartelle Windows/Windows Test, ZIP e APK nuovi non sono tutti verificati. CI, pubblicazione, download anonimi e prova manuale restano verifiche distinte.

Restano da completare le richieste storiche registrate in `PASSAGGIO_CHAT_COMPLETA_2026-10-20.md` e `ONLINE_CONSEGNA_TURNISTICA_2026-10-21.md`, inclusi Dust online, ultima regola armi/EXP della chat precedente e verifica manuale a tre app. Non sono dichiarate concluse da questo intervento.

## Personalizzazione

Chrome riabilitato il 21 ottobre: apertura del sito pubblico, ingresso Player, caricamento della scheda e pagina Online verificati visivamente. La pagina mostra “Online disponibile” e “Supabase pronto”; non equivale a una consegna reale al Master. Nessuna connessione di test aggiuntiva avviata da questa verifica.

Restano modificabili stanza/password/nome visibile, scheda attiva, approvazioni, partecipanti e turnistica del Master, oltre ad abilità, costi, durate, bersagli, effetti, oggetti e immagini tramite gli editor esistenti e il JSON. Il ritardo di aggiornamento dei dettagli è fissato a un secondo, come richiesto.
