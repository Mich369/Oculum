# Verifica delle aggiunte di mostri

Base fissa: [Build distribution b917217d98d16861a5bbaf1706d78825d883c970](https://github.com/Mich369/Oculum/actions/runs/40242640717).

Catalogo complessivo: 1.157 voci, varianti incluse. Le aggiunte da questa base sono 37 specie e 77 tecniche, con 231 forme I/II/III. Non sono state aggiunte ulteriori varianti separate per queste 37 specie.

Ogni tecnica genera un’arma, un’armatura e uno scudo: 231 oggetti derivati, 77 per famiglia. Ogni oggetto conserva tre forme della skill, per 693 forme negli equipaggiamenti. Non sono conteggiati come nuove specie né come nuove tecniche.

L’audit verifica ogni oggetto e il suo JSON: effetti, costi minimi/massimi, cooldown, livello e provenienza. Attiva inoltre tutte le 231 forme nel runtime dell’app e controlla i risultati effettivi: bonus, danni preparati, Scudo, cura, costrutti e stati delle tecniche speciali. I supporti sono consegnati sul destinatario; non basta la presenza della descrizione.

Correzioni emerse dai percorsi di utilizzo: tecniche speciali del ciclo e Potenza totale nel pannello Attacco; preparazione separata dal consumo dell’unica Azione/Reazione del colpo; avvio del pianificatore per aculei, Pedata e Telecinesi. Il gestore del Morso Lunare era già presente; aggiunta compatibilità con vecchi effetti salvati senza il marcatore speciale, conservando Danni e costi personalizzati.

| Specie | Tecniche | Armi | Armature | Scudi |
|---|---:|---:|---:|---:|
| Riccio dei Sentieri Quieti | 3 | 3 | 3 | 3 |
| La Follia | 3 | 3 | 3 | 3 |
| Forest Demon Blu dalle Corna Rosa | 2 | 2 | 2 | 2 |
| Cinghiale del Fango | 3 | 3 | 3 | 3 |
| Solare della Siccità | 2 | 2 | 2 | 2 |
| Gigante Goblin | 2 | 2 | 2 | 2 |
| Lupo Lunare | 2 | 2 | 2 | 2 |
| Marmocchi del Fato | 2 | 2 | 2 | 2 |
| Uomo Cactus Assetato | 2 | 2 | 2 | 2 |
| Melma di The Null | 2 | 2 | 2 | 2 |
| Orso dagli Aculei Ghiacciati | 2 | 2 | 2 | 2 |
| Lepre del Guscio Quieto | 2 | 2 | 2 | 2 |
| Cervo delle Radure Miti | 2 | 2 | 2 | 2 |
| Falena del Delirio | 2 | 2 | 2 | 2 |
| Scrutatore delle Febbri | 2 | 2 | 2 | 2 |
| Rondine del Respiro Lieve | 2 | 2 | 2 | 2 |
| Custode dei Nastri Sospesi | 2 | 2 | 2 | 2 |
| Porcello del Fango Grasso | 2 | 2 | 2 | 2 |
| Rospo delle Gronde Marce | 2 | 2 | 2 | 2 |
| Scarabeo del Sigillo Ardente | 2 | 2 | 2 | 2 |
| Araldo delle Sei Albe | 2 | 2 | 2 | 2 |
| Airone del Guado Quieto | 2 | 2 | 2 | 2 |
| Tartaruga della Pioggia Chiara | 2 | 2 | 2 | 2 |
| Cerbiatto dei Voti Lunari | 2 | 2 | 2 | 2 |
| Gufo delle Stelle Alleate | 2 | 2 | 2 | 2 |
| Ragno dei Fili Giurati | 2 | 2 | 2 | 2 |
| Cavaliere del Filo d’Oro | 2 | 2 | 2 | 2 |
| Scorpione delle Cisterne Secche | 2 | 2 | 2 | 2 |
| Mantide della Vampa | 2 | 2 | 2 | 2 |
| Larva del Nome Vuoto | 2 | 2 | 2 | 2 |
| Viandante dei Ricordi Spenti | 2 | 2 | 2 | 2 |
| Lepre del Fiato di Vetro | 2 | 2 | 2 | 2 |
| Golem della Brina Profonda | 2 | 2 | 2 | 2 |
| Volpe delle Lanterne Spente | 2 | 2 | 2 | 2 |
| Guardiano dei Dodici Rintocchi | 2 | 2 | 2 | 2 |
| Gigante Comune | 2 | 2 | 2 | 2 |
| Gigante Scheletro | 2 | 2 | 2 | 2 |

## Cosa resta modificabile

Nomi, descrizioni, statistiche, anatomia e punti deboli, resistenze, drop/materiali, skill/Open, formule, dadi, bersagli, costi e risorse, cooldown e durate. Sugli oggetti: tipo, nome, livello, Grado, requisiti, peso, bonus, elemento, skill e forme. Gli editor e il JSON mantengono le personalizzazioni già salvate.

## Evidenza

Test: `test/oculum_added_monsters_completeness_test.dart`. Report prodotti dalla stessa esecuzione della suite: `added-monsters-completeness.json` e `added-monster-skill-runtime.json`, disponibili nell’artifact pubblico `Oculum-Verifica-Mostri` della build finale. CI, download pubblici, installazione e sessioni online sono controlli distinti.
