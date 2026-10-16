# Correzioni degli screenshot — 16 ottobre 2026

- **Contatore Occhi dei Caduti:** i valori base della creatura non pagano più i punti della crescita. Esempio: 14 Resilienza, 5 Volontà, 8 Materia e 0 Oculum sono 27 punti base; passando dal livello 0 al livello 1 di un Mostro restano da assegnare 9 punti. Non viene aumentata automaticamente una statistica scelta dall'utente.
- La base proviene dalla voce del Monster Book, se identificata, oppure dalla base salvata nel JSON. Una sorgente manuale di livello zero conserva i suoi valori come base. Le sorgenti manuali vecchie di livello superiore senza dati della base non vengono reinterpretate inventando valori: il conteggio conserva il precedente riferimento zero.
- La base viene salvata nel campo additivo `monsterBaseStats`; i dati del Monster Book non vengono modificati.
- **Dialogo Occhio:** spazio verticale fra nome, livello, rarità, righe delle statistiche e Art. I controller vengono eliminati solo al termine dell'animazione di chiusura.
- **Pagina Skill:** catalogo e pannello delle Skill scritte occupano la stessa larghezza; rimossi l'abbinamento in due colonne sbilanciate e lo spazio vuoto a sinistra. Restano disponibili tutti i controlli e le tessere delle Skill.
- **Decorazioni:** le fasce panoramiche mantengono le proporzioni (`contain`) anche dietro una scheda alta; non vengono più ingrandite con `cover` fino a produrre una porzione sfocata al centro.

Test di regressione: `test/oculum_screenshot_regressions_test.dart` verifica proporzioni dello sfondo, larghezza della pagina Skill, conteggio crescita e separazione dei campi. `test/oculum_starter_creation_test.dart` controlla che i punti base non coprano il livello e che assegnare i 9 punti azzeri la carenza. Prima pubblicazione: 22 test pertinenti superati e analisi senza problemi.

Personalizzazioni conservate: statistiche e Vita manuali, livello, rarità, nomi delle Art, colori, tema, opacità, movimento e contenuto delle Skill.
