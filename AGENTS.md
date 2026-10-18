# Oculum

- Lavora in questo repository preservando salvataggi, immagini, funzionalità online e compatibilità desktop, tablet e telefono.
- Prima di modificare regole, consulta `docs/OCULUM_REGOLE_CONFERMATE.md` e il manuale completo `docs/manuale-consultazione.md`. Il registro distingue conferme dell'utente, regole del manuale e punti da chiarire: non trasformare una supposizione in una regola. Chiedi all'utente quando manca una regola o c'è una contraddizione non risolta.
- Le correzioni esplicite più recenti dell'utente prevalgono sul manuale precedente; aggiorna registro, manuale e test pertinenti insieme.
- Mantieni abilità, costi, durata, bersagli ed effetti modificabili attraverso gli editor esistenti e conservabili nel JSON della scheda. Non sovrascrivere le personalizzazioni salvate con nuove definizioni del catalogo.
- Quando lavori ad Oculum prepara sempre `C:\Oculum App\oculum\build\distribution` con EXE completo del runtime, ZIP e APK. Mantieni Windows e Windows Test anche in cartelle normali. Sostituisci i vecchi pacchetti solo dopo aver verificato quelli nuovi. Riporta cosa è stato modificato e cosa può essere personalizzato.
- Test locali, CI GitHub, pacchetti copiati, sito pubblicato e prove online reali sono verifiche distinte: riferisci solo quelle completate.
