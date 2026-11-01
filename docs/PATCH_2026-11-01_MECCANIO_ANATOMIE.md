# Meccanio e parti anatomiche — revisione del 1 novembre

Questa revisione segue la distribuzione0b82cb37. I pacchetti di quella build sono conservati fino alla verifica dei successivi.

- Nove PNG approvati: desktop/telefono/reliquia di Meccanio F2, Malconcio A2 e Primitivo C2. Approvazione separata dei sei derivati: «Sì, tutti e sei canonici». Copie identiche e ricevuta in `design/approved-meccanio-packs-2026-11-01.json`. Nessun nuovo potere o drop.
- Riconoscimento anatomico: parole intere per le ali, occhio/lente singolare, radici corporee distinte dall’ambiente. Le quattro regressioni sono state riprodotte prima della correzione. Conservati veri organi vegetali e override espliciti del Master.
- Scostubanditi e Granscostumato, anche Empatici, rimangono organici. La correzione non trasforma gli altri robot di Postea.
- FireShield, per conferma esplicita: bipede5m, due braccia artigliate e due zampe. Desktop C2 canonico; reliquia con sola testa richiesta. Alternative esapodi conservate ma superate. Nessuna modifica ai suoi valori o a BlackDragonShield.

Successiva conferma esplicita: «Sì, entrambi canonici» per FireShield telefono v1 e reliquia sola testa v2. I tre file sono collegati e copiati identici; ricevuta `design/approved-fire-shield-pack-2026-11-01.json`. Il lotto finale contiene12PNG approvati per quattro temi. La reliquia conserva residui alpha1 quasi invisibili: margine visibile minimo16,9%, non è dichiarato un margine grezzo13% e non sono stati modificati i pixel.

## Evidenze locali

- 62 test mirati di anatomia/materiali/runtime passati dopo la correzione bipede.
- 87 test del gruppo successivo passati: nove file/SHA/mapping, alpha reale e margini delle tre reliquie, caricamento e clic a320/834/1440px, parser, fuga d16 e premi. I gruppi si sovrappongono: non sommare i conteggi.
- La prima prova immagini era rimasta in attesa nel tempo simulato del widget; interrotta e corretta usando un test asincrono reale. Non è contata come esecuzione riuscita. Log finale `build/meccanio-targeted-final-v2.log`.
- Ulteriori15prove di sfondo/pagina acquistata/reliquia dei tre Meccanio passate; analisi pulita in169,3secondi.32testPython passati per pubblicazione, updaterWindows, sostituzioneisolata e firmaAPK. La prima prova Python ha incontrato un limite di scrittura nella cartella temporanea sandbox: ripetuta con temporanei sotto `build/`, senza cambiare la logica dell’app.
- Dopo l’aggiunta di FireShield:20test finali su12PNG e anatomie passati,5prove dedicate a sfondo/pagina/reliquia FireShield passate; analisi finale senza problemi in222,5secondi. Le prove dei tre Meccanio sono15, già riportate sopra. Un filtro con barra verticale non è stato accettato dal launcherWindows: rilanciata FireShield con filtro testuale semplice. Nessuna modifica alle regole per aggirare un test.
- Analisi, suite CI, prove online autenticate, installazione e download pubblici richiedono evidenze separate; nessuna prova su tre dispositivi fisici implicita.

## Personalizzazioni conservate

Restano modificabili nomi e descrizioni, statistiche/sottotratti, Skill/Art/Open, costi/minimi/massimi, risorse, forme, effetti, elementi, bersagli, durata, cooldown, inventario, resistenze, anatomie/parti e loro Vita, temi, reliquie, colori e trasparenze negli editor esistenti e nel JSON. Le nuove definizioni non riscrivono le schede salvate.

Nessuna riga del registro è chiusa al100% senza la conferma richiesta.
