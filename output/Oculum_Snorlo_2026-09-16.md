# Snorlo e distribuzione delle statistiche

## Modifiche

- Aggiunto Snorlo al Libro dei Mostri: quattro braccia, livello base 0, RES 5, VOL 4, MAT 4, OCU 10.
- Quattro braccia potenziate: ogni Oculum speso aumenta contemporaneamente RES, VOL e MAT di 1. Oculum non aumenta; i danni seguono le normali statistiche derivate.
- Guardia quadruplice: CM +2 per ogni Oculum speso.
- Volontà di Snorlo: VOL +1,5 per ogni Oculum speso. Si applica l'arrotondamento standard: 3 Oculum danno +5 VOL, 4 danno +6 VOL.
- Tutte le skill hanno tre forme, requisito livello 0, investimento I 1–4, II 5–10, III 11–30 Oculum. Le formule rimangono uguali tra le forme.
- Durata impostata a 1 turno; riattivazioni della stessa skill non cumulabili. I bonus delle skill diverse possono coesistere.
- Gli effetti usano l'Oculum effettivamente speso, non la riserva rimasta. Consumo e scadenza usano il sistema esistente.
- Il calcolo CM include ora i bonus degli effetti strutturati.
- La distribuzione automatica dei mostri del Book conserva ogni statistica base e aggiunge il budget di crescita. A livello 0 restituisce la base; ai livelli successivi aggiunge i punti previsti. La stessa regola viene usata nella creazione rapida e nei preset. Non riscrive schede già salvate.

## Cose modificabili

La voce personalizzata del Book permette di modificare nome, descrizione, immagine e statistiche. Nella scheda generata puoi modificare le tre skill, descrizioni delle forme, intervalli di costo, formule degli effetti, bersagli, durata e cumulabilità tramite gli editor esistenti.

Le quattro braccia sono descritte nel mostro: non attribuiscono automaticamente quattro attacchi o azioni supplementari.

## File interessati

- `lib/pages/oculum_dungeon/monster_book.dart`: voce e descrizioni delle skill.
- `lib/src/main/oculum_starter_creation.dart`: skill strutturate e crescita sopra le basi.
- `lib/src/main/oculum_home_calculations.dart`: bonus CM effettivo.
- `lib/src/main/oculum_home_persistence.dart`: creazione dei preset con basi conservate.
- `lib/src/main/oculum_home_secondary_pages.dart`: validazione Oculum compatibile con le basi del Book.
- `test/oculum_snorlo_test.dart`: statistiche, salvataggio e formule delle tre skill.
- `test/oculum_monster_generation_rules_test.dart`: conservazione delle basi e del budget di crescita per tutti i mostri.

Le build includono anche le modifiche già presenti nel checkout prima di questo intervento. I controlli automatici non sostituiscono una prova visiva o una prova su dispositivo Android.

## Aggiornamento Dark Fantasy e Ascension Dust

- Aggiunti Larva del Vespro (Mostro), Custode della Campana Cieca (Mini Boss) e Sposa della Marea Nera (Boss), con tre skill ciascuno, debolezze, ruolo di scena, costi progressivi e forme a livello 0.
- Le creature sono originali e usano atmosfera da mondo di incubi, ombre, rovine e sopravvivenza.
- Il potenziamento combattimento Dust ora permette una sola scelta per sessione: Attacco/VC oppure Difesa. Ogni Dust vale +2 al valore scelto: +1 diventa permanente e +1 resta fino al Riposo Lungo. Il limite è 3 Dust per sessione; la scelta e i bonus sono persistiti.
- Il Riposo Lungo rimuove solo la parte temporanea dei bonus Dust. Il controllo Nuova sessione azzera il limite e la scelta per la sessione successiva senza cancellare il permanente.
- Un tiro naturale di Drop da 16 a 20 concede 1 Ascension Dust, massimo 3 volte prima del Riposo Lungo. Il 20 naturale continua ad aprire anche la creazione dell'Occhio dei Caduti.

## Legno Marcio e Rinsecchito

- Aggiunto il mostro di legno marcio `Legno Marcio`, immune allo status `Rinsecchito`.
- La skill `Rami secchi` ora infligge metà Danni se il tiro fallisce; se riesce infligge Danni totali e applica `Rinsecchito I`.
- Applicazioni riuscite successive fanno avanzare `Rinsecchito` da I a II e poi a III; un tiro fallito non aumenta lo stadio.
- `Rinsecchito` ha tre stadi: riduzione della Difesa del 25%, 50% e 75%. La progressione e l'immunità vengono mantenute anche quando si crea il preset del mostro.

## Monster Book, filtri e shop Postea

- Tutti i mostri del Monster Book, compresi i Mostricciattoli iniziali e le voci personalizzate senza Skill, ricevono tecniche utilizzabili dai personaggi senza cambiare le statistiche base.
- Il selettore dei mostri ora filtra `Mostro`, `Mini Boss` e `Boss` e cerca in nome, ID, tipo, elemento, descrizione, Skill, drop, armi e armature.
- Lo shop offre sempre il Fucile Automatico di Postea a 112 Obser e l'Armatura Elite Postea a 96 Obser; entrambi restano nell'intervallo 69–120 Obser e non sono acquistabili due volte nella stessa run.
- L'Armatura Elite Postea dà +13 Difesa, +20 Danno, +20 Scudo, abilita il volo a pochi centimetri dal suolo e attiva lo Scudo Critico.


## Regola definitiva degli Occhi dei Caduti

- Ogni vera evocazione aggiunge 10 + Livello al Legame, fino a 1000. Aprire la scheda o richiamare un Occhio già evocato non assegna Legame.
- Le soglie 300, 600 e 900 concedono in totale 1, 2 e 3 Rinascite. Le cariche consumate sono persistenti; il Legame non viene speso.
- La morte rimane salvata. Nessuna Rinascita immediata e nessun pulsante Rinasci: soltanto il Riposo Lungo del proprietario consuma una carica e restituisce il 10% della Vita massima, arrotondato per eccesso con minimo 1.
- Un Occhio morto senza cariche rimane morto; un Occhio vivo non consuma cariche. Il riposo dell'Occhio stesso o di un altro personaggio non lo fa rinascere.
- A 1000 Legame, soltanto la rarità originale Oculum concede lo stato Risvegliato: Rinascite illimitate sempre al Riposo Lungo del proprietario. Il Reforge non altera la rarità originale.
- Solo dopo aver ottenuto rarità Oculum, un nuovo Occhio ha probabilità 1/1000 di nascere Risvegliato con 1000 Legame.
- Stato morto, rarità originale, Legame, cariche consumate e ID dei riposi già elaborati viaggiano nel JSON esistente. Il recupero è salvato subito; lo stesso evento non consuma due cariche.
- La UI mostra MORTO e RINASCITA AL PROSSIMO RIPOSO LUNGO oppure NESSUNA RINASCITA DISPONIBILE; mostra RISVEGLIATO quando applicabile.

## Postea: completamento

- Fucile: 112 Obser, +15 Attacco. Concatenazione armata è un'azione di combattimento: 1d6 colpi da 5 Danni ciascuno, con assorbimento dello Scudo nemico; non aggiunge il bonus Attacco ai singoli colpi. Sostituisce la vecchia raffica automatica.
- Armatura: 96 Obser, +20 Danno, +13 Difesa, 20 Scudo e levitazione a pochi centimetri dal terreno (non volo ad alta quota).
- Fucile + armatura equipaggiati: contributo totale +40 Danno, +15 Difesa e 25 Scudo, al quale si sommano le altre statistiche del personaggio.
- I bonus Danno/Difesa seguono l'equipaggiamento; lo Scudo consumato non torna cambiando pezzo. Il residuo viene conservato nel checkpoint.
- Le offerte Postea sono fisse presso il mercante, senza requisito di sblocco. Rimane la regola generale di un acquisto per visita e di un esemplare per run.

## Valori modificabili e dove

| Area | Valori modificabili | Dove |
| --- | --- | --- |
| Monster Book | Nomi, descrizioni, immagini, categoria, elemento, statistiche e drop delle voci personalizzate | Editor Monster Book |
| Schede e tecniche | Statistiche, Art, tre forme, costi, formule, bersagli, durate e cumulabilità | Editor della scheda e delle Art |
| Rinsecchito | Tre stadi e percentuali Difesa 25/50/75 | `lib/src/main/oculum_conditions.dart` |
| Snorlo e altri mostri | Basi, descrizioni e tecniche predefinite | `lib/pages/oculum_dungeon/monster_book.dart`, `lib/src/main/oculum_starter_creation.dart` |
| Dust | +1 permanente/+1 temporaneo, massimo 3 per sessione, scelta unica | `lib/src/main/oculum_home_resources_rest_titles_data.dart` |
| Drop Dust | Soglia naturale 16–20, massimo 3 prima del Riposo Lungo | `lib/src/main/oculum_helpers.dart` |
| Occhi | Incremento Legame, tetto, soglie, HP di Rinascita, probabilità naturale | `lib/src/main/oculum_fallen_eyes.dart` (regole di codice, non controlli liberi della UI) |
| Postea | Prezzi 112/96, bonus singoli e set, dado 1d6, 5 Danni per colpo | `lib/pages/oculum_dungeon_game.dart`; risoluzione online in `lib/pages/oculum_dungeon/oculum_dungeon_realtime_coop.dart` |
| Illustrazione | Immagine del Rinsecchito generata separatamente, importabile nel Book | `output/Rinsecchito.png` |

## Verifica

Suite completa: 493 test passati, 1 saltato; successivamente passato anche il nuovo test di integrazione del Riposo Lungo reale della scheda (494 test complessivi). Test specifici: soglie Legame, proprietario corretto, consumo di una carica, Legame invariato, ripetizione eventi, 100 cicli Risvegliato, serializzazione JSON della morte e acquisti/cambio equipaggiamento Postea.
I test di reload/import/export esercitano la serializzazione; non costituiscono una prova manuale di chiusura e riapertura dell'app su un dispositivo Android reale.

Analisi statica finale: `flutter analyze --no-pub` senza problemi. Per Postea, verifiche dei bonus eseguite su una nuova run; i bonus aggregati già presenti nei vecchi checkpoint non vengono rimossi con migrazioni speculative.

Concatenazione armata verificata anche in combattimento: conteggio 1d6, 5 Danni per colpo e assorbimento dello Scudo nemico. Build Windows release e APK Android release completate.
