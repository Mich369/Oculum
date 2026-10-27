# Oculum

- Il log per i giocatori deve essere sempre cumulativo dalla build `b917217d98d16861a5bbaf1706d78825d883c970`, run `40242640717`: mantieni `docs/REGISTRO_AGGIORNAMENTI.md` completo di tutti gli aggiornamenti successivi e collegalo da GitHub e dal menu download web. Non spostare la base alla patch precedente.
- A ogni aggiornamento mantieni `docs/ULTIMO_AGGIORNAMENTO.md` breve e fedele ai conteggi verificati; la pubblicazione legge il log dal commit realmente compilato.

- Lavora in questo repository preservando salvataggi, immagini, funzionalità online e compatibilità desktop, tablet e telefono.
- Prima di modificare regole, consulta `docs/OCULUM_REGOLE_CONFERMATE.md` e il manuale completo `docs/manuale-consultazione.md`. Il registro distingue conferme dell'utente, regole del manuale e punti da chiarire: non trasformare una supposizione in una regola. Chiedi all'utente quando manca una regola o c'è una contraddizione non risolta.
- Le correzioni esplicite più recenti dell'utente prevalgono sul manuale precedente; aggiorna registro, manuale e test pertinenti insieme.
- Prima degli artwork consulta anche `docs/OCULUM_LORE_VISIVA.md`, `docs/DICITURE_UTENTE_2026-10-27.md` e `design/OCULUM-VISUAL-BIBLE.md`; conserva lo stile pittorico Rame fatato. Quando trovi una differenza non risolta, spiega all'utente la regola precedente e la nuova richiesta, e chiedi se sia un'eccezione oppure una modifica generale. Non richiedere nuovamente conferme già esplicite.
- La dicitura visibile è sempre **Chaos**. Gli identificativi legacy restano compatibili con i salvataggi.
- Aggiorna il progetto e il codice esportato di Senka a ogni nuova indicazione che la riguarda. Distingui nelle note gli automatismi già supportati da quelli destinati alla prossima versione; un test d'importazione non certifica gli effetti in combattimento.
- Mantieni abilità, costi, durata, bersagli ed effetti modificabili attraverso gli editor esistenti e conservabili nel JSON della scheda. Non sovrascrivere le personalizzazioni salvate con nuove definizioni del catalogo.
- Quando lavori ad Oculum prepara sempre `C:\Oculum App\oculum\build\distribution` con EXE completo del runtime, ZIP e APK. Mantieni Windows e Windows Test anche in cartelle normali. Sostituisci i vecchi pacchetti solo dopo aver verificato quelli nuovi. Riporta cosa è stato modificato e cosa può essere personalizzato.
- Test locali, CI GitHub, pacchetti copiati, sito pubblicato e prove online reali sono verifiche distinte: riferisci solo quelle completate.
- A ogni aggiornamento e distribuzione verifica che tutti gli artifact prodotti dalle build GitHub riuscite siano disponibili anche come download pubblici senza login, attraverso la pagina download e il menu a tendina della versione web. Preferisci la pubblicazione automatica; se non riesce, completa manualmente pubblicazione e verifica prima di dichiarare la distribuzione conclusa. Controlla commit di origine, integrità dei pacchetti e accessibilità senza autenticazione; conserva le versioni precedenti e non pubblicare build fallite o file privati. Il menu download deve comparire solo sul web e non usare traffico Supabase.

- Su GitHub Windows normale e Windows Test devono restare download e artifact separati, comprese le cartelle con runtime. Non inserire Windows Test nella cartella o nello ZIP Windows normale.

- Il log automatico appare solo al primo avvio di ogni nuova versione ed è chiudibile con clic fuori. Quando aggiorni il registro cumulativo esegui `python scripts/sync_cumulative_update_log.py` e commetti anche l’asset offline; il test impedisce di distribuire un log diverso dal registro.
