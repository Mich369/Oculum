# Patch 30 ottobre — Nuvola, corazze e varianti

Base distribuita: bb403888/run40976486947. Registro ancora cumulativo. NU30/AN30b/MD30/AR30/ART32 non sono al100% senza la conferma richiesta.

## Cambiamenti e valori modificabili

- Nuvola: un letale la uccide; critico mirato alla bottiglia deve togliere Vita, Scudi critici validi. Seconda fase con recupero75% alla soglia15%, oppure40% rompendo prima la bottiglia, entro il massimo. Open Danni attuali+2d50+25, +15% dal secondo bersaglio, massimo12. Stop20% con un quarto dei Danni oppure60% con metà, consuma un'Azione in corso/prossima, conservando R/RV. Costi, percentuali, bersagli e CD modificabili. Art nuove con Open dedicata; Art salvate/personalizzate non vengono riscritte. La Skill Stop legacy identica al vecchio default viene adattata su copia: questo non migra l'intera vecchia Open.
- Costrutto Minore: scatola con integrità separata35% Vita massima/minimo3 come bilanciamento delegato; nucleo mirabile solo dopo rottura. Corpo e scatola danneggiati dopo Difesa/Scudi. Un critico non apre automaticamente. Override Master conservati. Ricevuta strutturale separata, limitata a128, conserva il danno precedente a Ultime forze senza cambiare l'EXP corrente.
- Quattro Armadilli: base/Sabbia/Cristallo/Legno, appallottolamentoA/R con+6/+9/+16CM, rotolamento e speronamento consentiti. Parti coperte non colpibili nemmeno con pacchetti precedenti. Bilanciamento iniziale modificabile:1/2/3Materia; riapertura0risorse ma1A/R. Materiali con peso, forgia e passivi nel JSON.
- Mezzo Demone Massiccio distinto:6/3/2/1 invece di3/4/3/2, stesso livello e totale base. Pool e statistiche modificabili. Pinepine integro con squama tenera, Fuoco ed esplosione conservati.
- Quattro desktop approvati collegati: Massiccio, Mastino della Cripta, Forest Demon comune e Blu. Entrambi i rettili quadrupedi; comune con tre corna incluso il frontale, Blu con due rosa. Undici desktop scelti esplicitamente nel lotto locale; sette specie richieste ancora senza voce runtime non diventano implementate dal solo disegno. Nuovi telefono/reliquia da approvare.

## Verifiche locali concluse

- Analisi app e nuovi test: nessun problema.
-34 nuovi test: Nuvola11, Costrutto9, Armadilli11, catalogo/anatomie3. Danno reale, A/R, pending, replayJSON, scope/campagna, parti nascoste e Ultime forze inclusi.
-141 regressioni su creature, runtime planare, Guardiani, Open, patch realtime, parti, risorse/turni, temi320/834/1440px e pagine comprate senza portrait.
-32 controlli di catalogo, bilanciamento, personalizzazioni ed esplosione Pinepine.

Log build/october30-*.log. Gruppi distinti, non un nuovo run locale della suite intera. Corrette fixture nei primi tentativi; ricostruito soltanto AssetManifest.bin della cache di test dopo un'interruzione, preservando distribuzione e salvataggi.

CI, firma, pacchetti installati, avvio EXE e download anonimi sono verifiche successive separate. Nessuna nuova prova online completa o su tre dispositivi fisici dichiarata. Vecchi pacchetti sostituiti solo dopo la verifica dei nuovi.
