# Kit dello Slime Roccioso

La voce originale `slime_roccioso`, le sue statistiche e il drop `roccia_slime` sono mantenuti. L'Art completa le tre tecniche e l'Open Masso Slime.

## Regole attuali

| Tecnica | Forma | Oculum | Livello | Risultato |
|---|---:|---:|---:|---|
| Palla di Roccia Slime | I | 1–4 | 0 | Aggiunge l'Oculum immesso al danno del prossimo attacco; il bonus si consuma con quell'attacco. |
| Palla di Roccia Slime | II | 5–10 | 5 | Scegli attacco (+3 danni oltre all'Oculum) oppure blocco con 3×Oculum Vita e una Reazione. |
| Palla di Roccia Slime | III | 11–20 | 13 | Scegli attacco (+10 danni oltre all'Oculum) oppure blocco con 5×Oculum Vita e una Reazione. |
| Rimbalzo | I | 1–3 | 1 | Una Reazione e +25% danni al prossimo attacco. |
| Rimbalzo | II | 4–6 | 6 | Una Reazione e +50% danni al prossimo attacco. |
| Rimbalzo | III | 7–10 | 12 | Un solo tiro 1d3 stabilisce il numero di Reazioni e l'aumento del 50% per ciascun rimbalzo; bonus per il turno. |
| Indurimento | I | 1–2 | 0 | +10 Resilienza e +5 Difesa, più Oculum immesso. |
| Indurimento | II | 3–4 | 3 | +15 Resilienza e +6 Difesa, più Oculum immesso. |
| Indurimento | III | 5–10 | 10 | +25 Resilienza e +15 Difesa, più Oculum immesso. |

Indurimento dura sei turni. I suoi bonus si ricalcolano con le statistiche della scheda e scadono insieme alla Skill.

Masso Slime si sblocca al livello 15: +5 alle quattro statistiche di base e +9 ai tiri mentre l'Open è attiva. Schiaccio spende Oculum, calcola `Oculum × 5 × 2` danni e applica cooldown. Se viene scelto un bersaglio di una scheda online, il pannello Master applica il danno rapido agli scudi e agli HP; il risultato viene anche scritto nel log e inviato al Master. Il tiro contro la Difesa resta da risolvere nel normale flusso di combattimento.

## Modifiche configurabili

- `lib/pages/oculum_dungeon/monster_book.dart`: testi I/II/III, costi, requisiti di livello e drop registrato nel catalogo.
- `lib/src/main/oculum_starter_creation.dart`: effetti strutturati per forma, durate, statistiche e buff dell'Open.
- `lib/src/main/oculum_home_secondary_pages.dart`: scelta attacco/blocco, conferme di costo e uso di Schiaccio.
- `lib/src/main/oculum_structured_effect_runtime.dart`: applicazione dei bonus percentuali al prossimo attacco e gestione del blocco con HP propri.

La carta del costrutto mostra la Vita corrente e consente al giocatore di registrare i danni subiti; a zero viene rimossa e l'evento è registrato nel log.
