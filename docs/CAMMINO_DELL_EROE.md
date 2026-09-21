# Cammino dell’Eroe — modifiche e valori modificabili

Accesso: aprire il gioco dalla scheda. Il percorso singolo apre il Cammino dell’Eroe; l’archivio conserva il gioco precedente e i suoi checkpoint. Le funzioni online precedenti mantengono il loro ingresso. Il Cammino usa le regole Oculus e non importa valori numerici dalle schede Oculum classiche.

## Regole, configurazione e contenuti

- `lib/game/hero_path/oculus_rules.dart`: progressione Potere condivisa con la scheda Oculus; dadi; Ispirazioni iniziali; morte e rinascita; bonus Mini Boss/Boss; probabilità e costi Reforge; Sintonia iniziale e Dust; adattamento; durata condizioni; difficoltà; riposo; invecchiamento; numero di carte; attesa massima degli eventi Quest.
- `lib/game/hero_path/hero_content.dart`: 42 Skill selezionabili, 20 Titoli, 14 creature con ruoli distinti, 13 scenari Dungeon, eventi e scelte; cibi e durate; minerali; descrizioni delle tecniche; profili scenario che modificano incontri, eventi e minerali. Testi, quantità, costi, effetti e cooldown sono modificabili qui.
- `lib/game/hero_path/hero_models.dart`: PG/NPC/Mostro, dadi e punti, Occhi dei Caduti, rarità, crescita, Sintonia, rinascite e serializzazione.
- `lib/game/hero_path/hero_engine.dart`: scene continue, luogo e tempo, scelta degli eventi tramite pesi e condizioni, Quest, incontri e caccia.
- `lib/game/hero_path/hero_combat.dart`: turni, carte, critici, raggio dei Cervelli, condizioni, adattamento, morte/rinascita, ricompense e finali.
- `lib/game/hero_path/hero_inventory.dart`: borsa, cibo, riposo, guaritore, minerali/armi, Reforge, Dust, scelta e potenziamento delle carte.
- `lib/game/hero_path/hero_quests.dart`: sostituzione delle Quest diventate impossibili, cronologia del cambiamento e generazione garantita degli eventi necessari.
- `lib/game/hero_path/hero_save.dart`: salvataggio della run, RNG riproducibile, snapshot dell’ultima azione e migrazione additiva. I campi sconosciuti restano nel JSON.
- `lib/pages/hero_path_page.dart`: interfaccia desktop/telefono, creazione del PG e Art, carte colorate, conferme Dust/Reforge, scheda e assegnazione rapida, borsa, Quest e regole.

## Carte per turno

### Scelta Art e nuovi Achievement

Le nuove run non hanno Skill Art preselezionate: il giocatore sceglie le 3 Skill iniziali. Il motore non aggiunge più Skill predefinite e non riempie automaticamente le scelte mancanti. Il pulsante di avvio resta disabilitato finché la scelta non è completa.

Il catalogo contiene 42 Skill: 21 disponibili subito e 21 bloccate da altrettanti nuovi Achievement. Il pannello **Achievement Art** mostra nome, requisito e Skill sbloccata sia alla creazione sia durante la run. Gli Achievement sono memorie permanenti: sbloccano la Skill per la selezione iniziale delle run successive e per le ricompense della run corrente, senza aggiungerla gratuitamente al mazzo. Le ricompense escludono le Skill ancora bloccate.

I nuovi traguardi riguardano vittorie confermate, fughe, scene raggiunte, Quest, livelli, Destino, Occhi dei Caduti, adattamento, sopravvivenza della Foresta, Titoli, armi, luoghi sbloccati, rinascita e potenziamenti delle carte. Una vittoria ancora annullabile con Ispirazione non assegna sblocchi. Le carte e l’Art già possedute nei salvataggi precedenti restano utilizzabili.

Per modificare l’associazione Achievement/Skill e i testi: `heroSkillAchievements` in `lib/game/hero_path/hero_content.dart`. Per modificare le condizioni effettive: `refreshSkillAchievements` in `lib/game/hero_path/hero_engine.dart`. I blocchi sono applicati dal motore, dalle ricompense e dall’interfaccia. Test dedicati: `test/hero_path_unlocks_test.dart`.

Si parte con 2 azioni. Ogni carta normale ne consuma una. Esaurire le azioni o premere **Termina turno** attiva gli Occhi evocati e i nemici; poi il budget torna a 2. Gli oggetti in combattimento concludono il turno, impedendo consumi gratuiti infiniti.

**Slancio Oltre il Limite** costa 2 Volontà e concede 2 azioni: il guadagno netto è una carta. È utilizzabile una volta per turno. **Istante Rubato** costa 3 Oculum e concede 3 azioni, con cooldown. I potenziamenti modificano anche costo e azioni. Slancio è disponibile dopo la prima vittoria se non è già nel mazzo; altre carte arrivano dalle scelte ricompensa.

**Ispirazione** non consuma azioni: consuma una Ispirazione normale e ripristina lo stato immediatamente precedente all’ultima azione compatibile. Sono inclusi Vita, risorse, nemici, condizioni, cooldown, azioni, oggetti coinvolti, equipaggiamento e adattamento. Il RNG avanza per permettere un nuovo tiro. Confermare ricompense/fuga chiude la transazione; non si riavvolgono loot precedenti o la scena. Il tiro contro la morte non ammette Ispirazioni.

## Quest che restano completabili

- Guida persa → cerca la mappa → se lasci anche la mappa, parla al carovaniere → accesso alla Città.
- Richiamo ignorato → cerca le tracce nel Dungeon → raggiungi il campanaro.
- Corda spezzata/campanaro irraggiungibile → raccogli e restituisci oppure custodisci l’eco → accesso alla Landa.
- Rinuncia allo scontro Eiva → sigilla il canale della corruzione.
- Giardino chiuso → affida il ricordo a un focolare del Villaggio.

L’obiettivo precedente e il motivo della sostituzione restano nella cronologia. La nuova Quest dà una ricompensa una sola volta. Dopo 4 scene l’evento necessario ha priorità quando ci si trova in un luogo compatibile. Il valore è modificabile con `questSceneLimit`. Le condizioni bloccanti vengono rivalutate anche al caricamento di un vecchio salvataggio.

## Oculus e compatibilità

La progressione Potere è estratta e condivisa con la scheda esistente. Il Cammino mantiene la scala dei dadi d4/d6/d8/d10/d12/d20. Il critico è almeno il doppio del tiro contrapposto. Il tiro contro la morte usa esclusivamente il risultato naturale del dado Volontà: con un dado più piccolo della soglia non è possibile riuscire. Le soglie sono 8/10/12/15. La Medicina usa un tiro di Materia; le Stats per la rinascita sono dado Stat corrente più relativo bonus. Le formule sono esplicite nei metodi centrali e nei test.

La scheda Oculus dispone di contatori separati 3/2/1 per le Ispirazioni e di punti/aumenti dado da assegnare manualmente o rapidamente. Un registro del livello già premiato impedisce di duplicare la crescita abbassando e rialzando il livello. Le schede precedenti vengono considerate già premiate fino al loro livello salvato. Le nuove creature vengono aggiunte al Bestiario, incluse le varianti, senza rimuovere gli ID esistenti.

I nuovi salvataggi usano `oculus.heroPath.run.v1` e `oculus.heroPath.meta.v1`, con il suffisso del profilo di test quando configurato. Il checkpoint del vecchio Dungeon resta intatto. Gli Achievement persistono fra le nuove run e possono abilitare eventi e ricordi. Nessuna prova automatica deve accedere ai salvataggi personali: i test usano SharedPreferences simulate.

## Verifica

Test dedicati: `test/hero_path_test.dart`, `test/hero_path_quests_test.dart`, `test/hero_path_regressions_test.dart`, `test/hero_path_widget_test.dart`. Coprono regole, risorse, soglie naturali, critici, raggio, rarità, Reforge, rollback, turni e carte extra, upgrade, ferite, adattamento, seed, migrazione, ramificazioni, luoghi, difficoltà e invecchiamento. I widget vengono controllati a 360 e 1440 pixel; immagini in `output/ui/hero-path-combat-*.png`.

Verifica della versione iniziale del 21 settembre 2026: suite completa `flutter test --no-pub`, 538 test superati e 1 saltato, nessun fallimento. Controllate le immagini dei widget a 360 e 1440 pixel.

Aggiornamento Art/Achievement: 41 test dedicati superati, inclusi i 7 nuovi test su catalogo 21/21, selezione vuota, ricompense bloccate, sblocco permanente, vittorie annullabili e vecchi salvataggi. Verificata l’interfaccia a 360 e 1440 pixel. Analisi statica senza errori o warning introdotti; restano i 2 suggerimenti di stile preesistenti.

Dopo l’ultima correzione dei testi, ripetuti e superati i 2 test widget. Analisi `flutter analyze --no-pub --no-fatal-infos`: nessun errore o warning; restano 2 suggerimenti di stile preesistenti in `oculum_dungeon_game.dart` e `oculum_home_calculations.dart`.

I test di percorso sono simulazioni del motore e non certificano un playtest umano completo o l’esecuzione su un telefono Android fisico. I log dell’analisi e delle prove sono in `output/hero_path_*.log`.
