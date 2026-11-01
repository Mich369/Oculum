# Patch — 23 temi canonici e piastre del Golem, 1 novembre 2026

## Implementazione locale

-23set/69PNG approvati copiati esattamente: manifesto con SHA e provenienza in `../design/approved-november-monster-packs-2026-11-01.json`. Diciannove scelte del lotto, più Golem Runico, Goblin Kamikaze, Diavolo Obliterato e Zombie dello Sbocco Acido. L’accettazione dei derivati distingue le conferme individuali dalla delega generale dell’utente.
- Robot più del doppio, RockShield gigante umanoide bipede e Golem di nuvole più grande: tre revisioni approvate esplicitamente. Statistiche e poteri non ricavati dalle dimensioni delle immagini.
- Golem: nucleo chiuso fino alle piastre rotte; integrità separata35% Vita massima per difetto, minimo3, scelta di bilanciamento delegata. Bersagli locali/remoti aggiornati; proprietà, turnistica e ricevute duplicate controllate. Anatomie personali e JSON conservati.
- BUG50: confini delle parole evitano armi deboli da «partono/umano/manopola» e ali da «palato»; restano parole anatomiche vere e personalizzazioni.

## Verifiche

Passati211test locali del gruppo grafico/anatomico, inclusi69controlli di reliquia e69controlli combinati sfondo/reliquia a320/834/1440pixel,23pagine acquistate e23decodifiche alpha. Il gruppo comprende controlli sovrapposti sugli stessi file, non211funzioni diverse. Passati separatamente14test su piastre e scatole. I primi tentativi grafici con bundle incompleto hanno fallito per asset mancanti; dopo aver copiato gli asset reali, il gruppo rieseguito passa. Non si sono modificati i test per nascondere gli errori.

Passati anche118test nel gruppo finale di anatomie reali, parser/costi, Open, fuga e premi (comprende i14piastre/scatole, da non sommare). Passati32test Python di aggiornamento/pubblicazione/firma; analisi statica senza problemi in163,8s. I tre fallimenti iniziali del gruppo premi erano dovuti esclusivamente alle cornici Mezzano mancanti nella fixture; copiate le cornici reali, lo stesso gruppo è passato senza modificare codice o aspettative.

CI, installazione, firma APK, confronto dei pacchetti, pubblicazione e prove online autenticate saranno registrati separatamente nel rapporto della consegna effettiva. Nessuna nuova prova su tre dispositivi fisici dichiarata. Non considerare questa implementazione già contenuta nella precedente build f86951cb.

## Proposte per il ritorno

36desktop, sei alternative ciascuno: Medusa di Vetro, Cinghiale del Fango, Coniglio Prestigiatore, Uomo Cactus Assetato, Tempesta Sorridente, Teschio di Fulmine. File/CRC/SHA e link locali verificati. Tutti da votare; nessun nuovo tema, potere o punto debole integrato. Nuvì attende il chiarimento due/quattro zampe.

Gallerie locali: `../output/artwork/derivati_lotto19_2026-11-01/GALLERIA_COMPLETA.html` e `../output/artwork/proposte_sei_notte_2026-11-01/GALLERIA.html`.

## Modificabile

Temi, colori, reliquie, trasparenze, statistiche, Skill/Art/Open, costi, forme, bersagli, effetti, elementi, durate e recuperi. Vita delle parti, materiale, penalità e regole della corazza restano modificabili via editor/JSON già esistenti. Nessuna personalizzazione salvata sovrascritta. Nessuna riga viene chiusa al100% senza la conferma finale dell’utente sulla riga intera, adattamento e test.
