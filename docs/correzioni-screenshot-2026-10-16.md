# Correzioni degli screenshot — 16 ottobre 2026

- **Contatore Occhi dei Caduti:** assegnazione automatica di 9 punti per livello oltre alle statistiche base. Restano separati i 10 punti per grado già previsti per i Mostri. Esempio: 14 Resilienza, 5 Volontà, 8 Materia e 0 Oculum sono 27 punti base; al livello 1 il totale diventa 36, al livello 2 diventa 45. Oculum base zero resta zero.
- La distribuzione segue il profilo delle statistiche della creatura. Cambiando livello si sostituisce il bonus precedente: tornare da 2 a 1 non accumula punti. La Vita segue Resilienza e grado, conservando la differenza dovuta a ferite o modifiche manuali.
- La base viene salvata nel campo additivo `monsterBaseStats`, la crescita in `fallenEyeLevelStatBonuses`. Le sorgenti manuali prive di base salvata conservano i valori presenti come base. Nessuna modifica al Monster Book.
- **Dialogo Occhio:** spazio verticale fra nome, livello, rarità, righe delle statistiche e Art. I controller vengono eliminati solo al termine dell'animazione di chiusura.
- **Pagina Skill:** catalogo e pannello delle Skill scritte occupano la stessa larghezza; rimossi l'abbinamento in due colonne sbilanciate e lo spazio vuoto a sinistra. Restano disponibili tutti i controlli e le tessere delle Skill.
- **Decorazioni:** le fasce panoramiche mantengono le proporzioni (`contain`) anche dietro una scheda alta; non vengono più ingrandite con `cover` fino a produrre una porzione sfocata al centro.

Test di regressione: `test/oculum_screenshot_regressions_test.dart` verifica proporzioni dello sfondo, larghezza della pagina Skill, conteggio crescita e separazione dei campi. `test/oculum_starter_creation_test.dart` controlla che i punti base non coprano il livello e che assegnare i 9 punti azzeri la carenza. Prima pubblicazione: 22 test pertinenti superati e analisi senza problemi.

Personalizzazioni conservate: statistiche e Vita manuali, livello, rarità, nomi delle Art, colori, tema, opacità, movimento e contenuto delle Skill.

Verifica crescita automatica: 23 test mirati e suite completa da 790 test superati (2 saltati); flutter analyze --no-pub senza problemi. Verificati anche riapertura, ferite conservate e punti manuali delle schede precedenti.
