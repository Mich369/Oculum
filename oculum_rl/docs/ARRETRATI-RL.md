# Arretrati di Oculum RL

## Lavori per la prossima versione

| Intervento | Stato |
| --- | --- |
| Percezione dei mostri, cespugli per ambiente e forma pipistrello | Implementati nel mondo di gioco. Verificati cono e occlusione, ultima posizione, avvistamenti condivisi e separati per giocatore, 10 s e 1,3 s, ingresso osservato, 0,9 s e 60%, salvataggi e frame a sei. |
| Battute, ruggiti e sottotitoli d’allerta | Audio italiano ed effetti già collegati in solo e co-op. Verificati ritardo di 3 s, battuta unica dopo l’allerta del gruppo, coda e muto. |
| Animazioni dei mostri | Mosca Campana e Armadillo Corazzato nella 0.4.28. Per la prossima versione sono integrati Miruscyrus e Costrutto Minore dalle tavole approvate. Esistono clip registrate dal renderer. |
| Grimorio persistente | Sei slot configurabili da HUD in solo e co-op. Le Art apprese dalla Pittrice restano nel profilo e il Master risolve gli ordini dei tasti in cooperativa. Passate le prove di acquisto, Oculum, recupero, assegnazione, salvataggi precedenti e ripristino, più la prova live di assegnazione e uso. L’apprendimento dalle pergamene usa ancora le regole RL esistenti. |
| Nuove tavole | Il lotto del 28 novembre ha le collocazioni previste. Restano da scegliere le tavole ancora in proposta. |

## Prima della 0.5

| Intervento | Regola e verifica |
| --- | --- |
| Assassino | Sblocco al piano 3 con un’eliminazione furtiva per piano eleggibile. Metà Vita, rigenerazione fuori pericolo, lame incrociate, due copie evasive e velo condiviso. Il costume Ricognitore di cenere parte con la pistola. C comanda il nascondiglio in scatola per ogni livrea. Verificati avvio solo, kit, pressione C, selezione touch, avvistamento, autorità ospite e ripresa dal checkpoint locale. |
| Scostubanditi e Gran Scostumato | Gli MP3 forniti segnalano l’avvistamento diretto. L’allerta si diffonde nella stanza dopo 2 s per lo Scostubandito e 3 s per il Gran Scostumato. Perdono le tracce dopo 3 s senza contatto visivo da alcun nemico. Dopo 0,9 s il controllo passa al 35% in sospetto e al 60% se sono già allertati. Gli altri incontri mantengono i propri valori. I due MP3 originali sono stati verificati nel bundle di test e decodificati con Chrome. |
| Audio adattivo | Campo, Foresta, Sotterraneo, Postea, Deserto e Orea hanno due brani originali ciascuno. Il mixer passa da quiete a scontro quando il mondo conferma l’allerta e ripristina la quiete dopo che si perdono le tracce. I temi boss hanno precedenza. La firma del Gran Scostumato scatta una sola volta per incontro, su un canale condiviso con gli avvistamenti, e segue il volume effetti. Verificati i 14 file nel bundle di test, il routing dai frame della cooperativa e i volumi salvati. |
| Furtività dei compagni | Pet, alleati, copie ed evocazioni seguono in silenzio il proprietario finché le guardie non lo rilevano. Gli avvistamenti sono separati tra giocatori. I compagni rientrano in combattimento dopo il rilevamento. Nella Boss Rush e contro l’Elité già aggressivo l’incontro parte in combattimento. |
| Fuga dal Campo Scostubanditi | Il colpo fatale dei banditi sui piani principali prima del finale apre la prigionia dopo i salvataggi dalla morte. Risveglio al 25% Vita. Si perde il 60% dell’inventario di run, pergamene comprese, e si conserva almeno l’arma impugnata. Scostubandito e Gran conservano il bottino e usano R una volta. I due corridoi si attraversano anche con guardie vive. Nell’arena l’Elité spara tre colpi ad area e usa il cannone in mischia. Finché vive, tornano i rinforzi caduti a intervalli di 60 s, escluso il primo Gran di rinforzo abbattuto. In co-op la deviazione parte dopo la caduta di tutti. |
| Errato e Veterano | Soccorso al 25% o al 5%, esiti esclusivi. Il Veterano porta Errati ostili nei corridoi e nell’arena finché è vivo. Le due apparizioni sbloccano i due personaggi individualmente. Sprite derivati dalle tavole Ink approvate di Oculum, con spada, bastone, scudo spirituale e cicatrice del Veterano. |
| Boss Rush | Incontro facoltativo oltre il piano 12. Entrata sigilla le uscite. Primo subito. Secondo alla morte del primo o a 30 s. Terzo alla morte del secondo oppure a 45 s se il primo è caduto entro 16 s, altrimenti a 60 s. Ricompensa di un livello una sola volta, anche dopo ripresa. Tempi verificati nel combattimento. In solo la cinematica congela il tempo. |
| Attributi e potenza dei mostri | Quattro punti per livello. Distribuzione automatica per i preset e manuale per il personaggio creato. Resilienza per la Vita, Volontà per Danni (+3 per punto) e portata, Materia per schivata e velocità d’attacco, Oculum per la riserva. I mostri ricevono valori per tipo, piano e difficoltà. |
| Vitalium | Grezzo e Ridefinito usano la Vita di riferimento del piano. Il Grezzo mantiene il coefficiente del 20%. Il Ridefinito cura fino al 100% del riferimento e ripristina Oculum. Prove con riserva Vita elevata, ospite riconnesso e pet del proprietario. |
| Effetti Ink Expressive | Riprese dall’arena per la Croce di mezzelune dell’Assassino e le cure di Bunnys dalla tavola H. Materia mostra scie brevi e un segnale «Schivata». |
| Fasi di Arconte e Aerovyr | Arconte cambia fase al 50% della Vita. Aerovyr cambia fase al 50% e alla prima sconfitta si rialza una sola volta con il 50% della Vita massima. La vittoria e le ricompense arrivano dopo la terza fase. Quattro campagne simulate arrivano al finale, una in difficoltà Oculum con esplorazione. Le fasi sono state verificate anche dopo il ripristino da salvataggio e da frame co-op. |
| Fuga co-op verificata | Due client autenticati nella stessa stanza Supabase hanno completato la fuga. Verificati rientro reale del Master con recupero del checkpoint, corde individuali, penalità di inventario applicata una volta, furtività dei pet per proprietario, portali con voto condiviso e uscita dopo l’Elité con rinforzi vivi. Lo stesso test prova assegnazione e uso del Grimorio dal client ospite. |
| Animazioni | Il Doppelganger usa le pose Ink del Costrutto Minore, con trasformazione, riposo, camminata, corsa e attacco. L’Open di un ospite mantiene le sue pose quando il Master è trasformato. Provate le attivazioni Open dei 47 personaggi, con 13 famiglie di glifi condivise. Completare i cicli autonomi delle specie che riusano fotogrammi. |

## Lavori ancora aperti

- Updater incrementale per Windows e Windows Test, con stima di file e byte prima del trasferimento, manifesto per file e rollback. L’updater corrente verifica e installa il pacchetto intero.
- Daphne, Riflesso, Levitazione e la versione avanzata del Necromante.
- Occhi dei Caduti evocabili e fino a due personaggi salvati come compagni.
- Ciclo della giornata, fame e gestione di due pasti. Nel Ristoro esistono già i cibi con effetti a stanze.
- Entrate con moneta e R nelle Micro Realtà e nei Regni ancora assenti. L’Occhio del Deserto ha già esiti e ritorno condivisi.
- Chiamata audio/video, finestre delle webcam e condivisione audio del Master.
- Verifica dall’interfaccia Windows con più computer su reti distinte, incluso il rientro dell’host. Il test live della 0.4.28 ha già verificato sei client autenticati e il recupero del checkpoint dell’Occhio del Deserto.
