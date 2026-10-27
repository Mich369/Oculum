# Assegnazione delle schede — verifica del 27 ottobre 2026

Il Master sceglie un giocatore e una o più schede locali. La selezione parte vuota a ogni apertura. Dopo la conferma, il database trasferisce la proprietà al destinatario; il giocatore salva una scheda locale e il Master mantiene la copia nella cartella Online. Le versioni del destinatario devono dichiarare il supporto al protocollo di assegnazione v1. Una cessione in attesa rimane recuperabile; un errore di rete non implica ripetere la cessione con un nuovo identificativo.

La copia di recupero sul server viene rimossa soltanto dopo le conferme di salvataggio dei due dispositivi. Rimane una ricevuta piccola per riconoscere i reinvii. I dati precedenti in conflitto richiedono la scelta di conservarne una copia prima dell’importazione. Le ricevute dei premi già riscossi vengono mantenute; il trasferimento non ricrea EXP, Fortuna magica o altre ricompense.

## Prove completate

- Quattro test locali specifici: dati personalizzati e immagini, selezione iniziale vuota, importazione ripetuta senza duplicati, rifiuto del conflitto senza sovrascrittura, salvataggio verificato e cartelle del destinatario/Master. Log `build/oct27-sheet-assignment-tests-5.log`.
- Diciassette regressioni su assegnazione, patch online e barra dei fight condivisi: `build/oct27-assignment-and-regression-tests.log`.
- Analisi statica senza problemi: `build/oct27-assignment-static-final.log` (da ripetere alla fine dell’intero aggiornamento).
- Migrazione Supabase `20261027095540_assign_oculum_sheets` applicata dopo l’autorizzazione esplicita dell’utente.
- Test reale sul database con tre account sintetici, transazione annullata: `supabase/tests/oculum_sheet_assignments.sql`. Verifica Master proprietario, rifiuto del giocatore e delle schede altrui, atomicità del lotto, privacy verso un terzo giocatore autorizzato, reinvio idempotente, conservazione di immagine/costo personalizzato e conferme separate dei salvataggi.
- Dopo il rollback: zero assegnazioni, RLS attiva, esecuzione anonima della funzione vietata. Le schede reali non sono state cedute durante le prove.

Queste prove non sostituiscono la verifica della nuova build installata su dispositivi indipendenti. I pacchetti e la pubblicazione GitHub restano verifiche separate.

## Controlli Supabase

Le due funzioni sono intenzionalmente accessibili agli utenti autenticati: il corpo verifica account, stanza, ruolo Master, sessione registrata, proprietà della scheda e destinatario autorizzato. `SECURITY DEFINER` serve a modificare le tabelle che restano prive di permessi diretti di scrittura per il client; il percorso di ricerca è vuoto e l’accesso `anon` è revocato. Il controllo automatico segnala questa scelta come avviso da riesaminare, non dimostra da solo un accesso non autorizzato. [Spiegazione del controllo](https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable).

L’accesso degli account ospiti autenticati rimane intenzionale e vincolato a UID e appartenenza alla stanza; non equivale ad aprire i dati a una richiesta senza account. Non sono state allargate le policy dei dati esistenti. [Controllo sugli account anonimi autenticati](https://supabase.com/docs/guides/database/database-advisors?queryGroups=lint&lint=0012_auth_allow_anonymous_sign_ins).

## Piano gratuito

Il protocollo usa database, Auth, RLS e Realtime già utilizzati da Oculum. Nessuna funzione a pagamento aggiuntiva, nessuna query continua per le assegnazioni completate: recupero alla connessione e su notifica privata, corpi letti singolarmente e rimossi dopo entrambe le conferme. Questa compatibilità del protocollo non significa che il database corrente rientri già nel Free.

La verifica corrente ha trovato circa 1,1 GB, quasi tutti nella tabella degli eventi online, oltre i 500 MB inclusi nel piano gratuito. Serve una riduzione dello storico verificata prima del downgrade. Non sono stati cancellati eventi o salvataggi né cambiato il piano. [Piani e limiti Supabase](https://supabase.com/pricing).
