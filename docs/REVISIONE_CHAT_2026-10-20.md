# Revisione del 20 ottobre 2026

## Modifiche presenti nel checkout

- Emblema dello Slime custode nell'alchimista: base 200 Obser, 120 HP, fino a tre protetti, +3 alle quattro statistiche e +2 ai sottotratti. Pool condiviso e legame allo scontro; niente rigenerazione Pawn. Parametri modificabili dal menu inventario e conservati nel JSON.
- Catalogo oggetti del Master filtrabile per grado e categoria; categorie ibride conservate.
- Prezzo persistente per mercante: normalmente 95–105%, 3% dei negozi a 125%, 1% a 85%. Il modificatore non è dichiarato nell'interfaccia.
- Stato personale di utilizzo Open conservato nel JSON e azzerato al Riposo Lungo. Open Buff attivato dal comando originale; collocazione nei tre pannelli modificabile senza perdere l'elemento. Impostazioni effetti avanzate espandibili.
- Forme non utilizzabili per cooldown, costo minimo o requisito escluse dai pannelli. I sottotratti restano disponibili come tiri.
- Open mancanti dei mostri completate con bonus al danno base, Buff Open e capacità ridotta a recupero autonomo; conservate le definizioni personalizzate già presenti.
- Risoluzione bersagli delle Open strutturate collegata al percorso comune online/offline.
- Trasferimenti scheda: timeout più ampio e un solo reinvio per blocchi idempotenti, con invio cadenzato. Le azioni di gioco non vengono ritentate automaticamente per evitare doppie applicazioni.
- Test Auth: tentativi limitati ai problemi di rete, timeout per tentativo e chiusura dei client; errori HTTP non mascherati dai tentativi successivi.

## Verifiche concluse

- Analisi Dart di lib e test: nessun problema, prima dell'ultima aggiunta al controllo disponibilità Open; ripetere nel controllo finale.
- Cinque test emblema/catalogo/prezzi iniziali passati; aggiunta e passata regressione visibilità per costo/cooldown.
- Quattordici test combinati generazione mostri, pannelli desktop/telefono e emblema passati.
- Test online reale `oculum_combat_live_application_test.dart`: passato il 20 ottobre, due client autenticati nella stanza sintetica `e2931ac3-4ef1-4515-b762-8eb435bb1168`. Verifica difesa, scudi, danni, cura, aiuto firmato e duplicati. Si è attivato il fallback HTTPS dopo un timeout WebSocket; completamento in 1 minuto e 50 secondi.
- `git diff --check`: nessun errore; avvisi sui terminatori di riga Windows.

## Verifiche ancora da concludere

- Suite completa in corso: `build/audit-full-tests-20261020.log`; non considerare tutti i test passati finché il processo non termina con successo.
- Nuova distribuzione Windows, Windows Test, APK e web da compilare e verificare. La distribuzione precedente non è una prova di questi sorgenti.
- Prova manuale con applicazione Windows e Chrome, e terzo dispositivo indipendente: non completata su questi sorgenti. La prova automatica con due client Supabase non la sostituisce.
- Il plugin GitHub non ha restituito stati o run PR per il commit base `7562c2c4414b49c185a221794a2aa4fd0d5216c7`: nessuna certificazione CI o pubblicazione Pages da questo dato.

## Personalizzazione

Abilità, forme, elementi, collocazione nei pannelli, effetti, costi, cooldown, durata e bersagli rimangono negli editor/JSON esistenti. Il menu dell'emblema permette di cambiare HP, numero protetti, bonus e durata. Gli oggetti già salvati non vengono sostituiti dalle definizioni nuove del catalogo. Nessuna migrazione distruttiva o chiave privilegiata aggiunta.
