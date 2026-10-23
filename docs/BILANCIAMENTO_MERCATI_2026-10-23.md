# Bilanciamento dei mercati — 23 ottobre 2026

## Criteri

Registro `OCULUM_REGOLE_CONFERMATE.md` e manuale prevalgono. Le cifre confermate non sono cambiate. La guida Game Studio è applicata per tenere regole e stato salvabile separati dalla presentazione; non dispone di un servizio automatico che determini prezzi Oculum.

Il confronto usa quattro costi reali: Obser, azioni/reazioni, durata e possibilità di riutilizzo. Un oggetto con riserva di Scudo consumabile può essere più forte per singolo scontro, perché mantiene poi soltanto metà dei bonus. Il livello richiesto limita l’uso e il Grado determina l’accesso; un mercante di Grado alto non regala il diritto di equipaggiare gli oggetti.

## Valori confermati mantenuti

| Oggetto/regola | Prezzo o costo | Limite |
|---|---|---|
| Mitra runico Postea | 50 Obser | +15 solo quando scelto; soltanto i 15 ignorano resistenze |
| Stivali Postea | 60 Obser | reroll CM +3 gratuito; CD 5 turni |
| Capi della sartoria | 9–18 base + supplementi confermati | crescita lenta; bonus dimezzati alla rottura dello Scudo proprio |
| Corazza cyberpunk | 36 + metà HP massimi per eccesso | Scudo fissato all’acquisto; diventa logora senza ricarica automatica |
| Amuleto Teschio | 120 + 10 × Grado | un’Azione; un Riposo Lungo; almeno 1 attacco subito |
| Conversione Titolo Item | metà livello per eccesso +1 Dust | un singolo oggetto; preserva gli effetti |

## Proposte iniziali, modificabili

- Statistica del capo: +1 ogni 3 livelli oggetto; sottotratto +1 ogni 2. Supplemento 2 Obser per crescita e 2 per punto di Danni/Difesa. Evitare copie passive del bonus runico da 15: quel prezzo include una scelta di attacco specifica.
- Corazza cyberpunk: +2 + Grado a Danni e Difesa, crescita di una statistica ogni 3 livelli. Il buff alla rottura resta separato: statistica +1 + Grado/3 per difetto, tetto 4; sottotratto +3 + Grado/3, tetto 6; oppure Vigore di radice I. Durata confermata 6 turni, attivazione 99% una sola volta.
- Sigillo necromantico: 90 + 10 × Grado, CD 6 turni; richiede un’Azione e genera un alleato per 3 turni del proprietario. La durata impedisce la sostituzione di un compagno permanente al solo costo iniziale.
- Piano Sacro ×3; Angelico ×1,2; Sotterraneo maggiore ×1,3; Demoniaco ×1,2; Shadow Hell ×2,5; Diabolico ×2; Vero inferno ×4; Caramella ×1,1. I prezzi finali includono anche il pavimento del mercato già esistente, supplementi di livello ed eventuale percentuale personale del mercante.
- Equipaggiamento ordinario: pavimento esistente 50 +70×Grado Obser; supplemento esistente 10×max(0, livello−5×Grado). I prezzi dei piani non lo aggirano.

## Esempi di controllo

| Caso | Risultato di base |
|---|---|
| Corazza su PG con 101 HP massimi | 51 Scudo, 87 Obser prima di eventuali regole personali del mercante |
| Titolo Item livello 0 / 3 / 10 | 1 / 3 / 6 Dust |
| Amuleto Grado 0 / III / IX | 120 / 150 / 210 Obser prima del prezzo personale |
| Tre mostri da 20 statistiche | 70 Obser in cassa, una sola volta per specie |
| Due miniboss da 80 statistiche | 190 Obser in cassa, una sola volta per specie |
| Un boss da 200 statistiche | 250 Obser in cassa, una sola volta per specie |

## Stato delle verifiche

Le prove automatiche verificano formule, soglie, JSON, limiti della cassa, accrediti unici, rottura e conversione. Non sostituiscono una campagna giocata: il rendimento rispetto a tutte le build dei personaggi richiede osservazione di scontri reali. Gli editor conservano i valori salvati; la revisione dei default non deve riscrivere gli oggetti personalizzati.

## Vincolo Supabase gratuito

Rilievo in sola lettura del 23 ottobre: tabella eventi circa 686 MB (77 MB heap, 15 MB indici, 594 MB TOAST); stanza più attiva 47.162 eventi. Statistiche cumulative, non percentuali di quota mensile. Non sono stati eliminati dati. Serve ridurre storico/payload e verificare la conservazione delle ultime schede e dei trasferimenti prima di una pulizia. Aggiunta una protezione locale che evita di rileggere dal database un evento già consegnato. Non è prova che il progetto sia già entro i limiti gratuiti.
