# Prossima patch — lavorazione autorizzata

Base distribuita e approvata P09: **dcb5bb4e / run40904083210**. Quella distribuzione resta disponibile e conservata mentre la nuova patch viene verificata. Le prove descritte sotto sono locali e non certificano una nuova pubblicazione.

| Ambito | Lavoro | Stato iniziale |
|---|---|---|
| SON29/BIS29/TEM29/COR29 | Giorni e riposi condivisi, recupero secondo durata, bisogni separati, tempo Master, calo notturno e Corruzione per Notti effettive. | Integrata; 39 prove mirate sonno/bisogni passate. Analisi finale senza problemi; suite completa locale terminata; due fixture corrette e 12/12 riprove passate, CI successiva distinta, nuovo protocollo riposo verificato fra quattro client autenticati, compreso replay dopoJSON. |
| SAB29 | Gigante di sabbia, coda gratuita con recupero condiviso, parata al 65%, risoluzione Lava e MAT dimezzata senza accumulo. | Integrata; 19 regressioni mirate passate: coda fuori turno, costo/nonce, parata e Scudi, Lava/ricevute. Suite completa locale terminata; riprove dei due file corretti passate. CI e pacchetti successivi distinti. |
| ART30 | Collegare soltanto pack già approvati e verificarne margini/leggibilità/controlli. | Collegati 13 desktop e 10 coppie telefono/reliquia: 33 PNG approvati copiati senza differenze SHA. 62 casi renderer/Book/alpha nella suite completa locale terminata; due fixture corrette e 12/12 riprove passate, CI successiva distinta. Le proposte non approvate restano escluse dal runtime. |
| ANA30 | Dopo ogni disegno confermato, confrontare anatomia e punti colpibili, comprese parti nascoste, materiali e assenza di occhi/arti non presenti. | Corretti i default delle specie approvate, parti metalliche e volti dei fratelli, assenza del punto debole generico per Gigante e nuclei nascosti; override conservati. 19 regressioni mirate passate. Non è un audit concluso di tutte le voci del catalogo. |
| ART31 | Tre proposte visive A/B/C per ogni nuovo desktop mancante, comprese varianti ambientali; coda completa del catalogo. | Primi due lotti: 36 proposte selezionate; cinque desktop scelti esplicitamente, con tutti i dieci derivati approvati. Fotografia alla preparazione del commit: nove lotti, 162 proposte per 54 creature; i lotti successivi proseguono nella galleria locale; storico e domande cumulative conservati. |

Domande cumulative: [DOMANDE_ARTWORK_PROSSIMA_PATCH.md](DOMANDE_ARTWORK_PROSSIMA_PATCH.md). Le righe non diventano 100% senza la presentazione dell’adattamento, delle verifiche effettive e la conferma richiesta dall’utente.

Le nuove regole e le immagini dovranno restare modificabili tramite editor e JSON. Prima della pubblicazione: verifiche mirate, analisi e suite completa coordinate con i lavori attivi; CI del commit compilato, EXE completo/ZIP/APK, Windows Test separato e download pubblici anonimi verificati. Il log resta cumulativo secondo AGENTS.md finché l’utente non identifica la grande espansione prevista come conclusa.

## Revisione separata dei bug

- Corretto il massimo naturale delle risorse: fame e bonus notturni non devono trasformarsi in punti permanenti dopo il recupero; preservata la compensazione Materia del plasma. Tre regressioni mirate passate.
- Il calendario player è ora bloccato nei controlli e nel runtime; il test prova cambio di fase negato e rebase Master a190. La fixture dichiara esplicitamente l’autorità e attende il caricamento in modo limitato.
- Trovato un difetto del mantello senza dado: il danno non deve essere annullato dal confronto contrapposto già escluso dalla parata. Correzione minima applicata; due regressioni Azione/Reazione passate, con Scudi e ricevute preservati.
- La revisione di Nuvola in bottiglia ha trovato funzioni dichiarate ma non collegate alla risoluzione: fase, interruzione e Open richiedono un intervento distinto. Quattro scelte ancora aperte nel registro domande; non dichiarare queste meccaniche complete dall'approvazione del solo artwork.

- Sfinimento e coda: due riproduzioni negative prima della correzione, poi 23/23 prove congiunte coda/PT passate. La coda resta gratuita, ma non aggira il blocco delle Skill durante Sfinimento.

## Impostazioni e dati personalizzabili

| Ambito | Personalizzazioni conservate |
|---|---|
| Sonno | Minuti richiesti dal Master; profilo `sleepRecoveryRules` con recuperi base, passi, incrementi e massimi. Restano vincoli confermati minimo 90 minuti e prima alba se iniziato di Notte; un solo Riposo Lungo. |
| Bisogni | Attivazione per scheda e `personalNeedsRules`: esenzioni, soglie e penalità per cibo, acqua e sonno. Episodi e contatori distinti per campagna; soddisfare un bisogno non cancella gli altri. |
| Coda e Lava | Costi, durata, bersagli ed effetti delle Skill; `sandRules` con recupero, percentuale ricevuta, probabilità Lava, durata/divisore MAT e riferimento Resistenza. Default confermati: attacco anche fuori turno; nessun consumo A/R/RV. |
| Anatomia | `precisionBodyParts`, materiali e integrità delle parti, HP/soglie, lesioni e valori specifici già salvati. Nuclei, cristalli e altre eccezioni native conservano le loro regole. |
| Temi | Selezione e personalizzazione del tema per scheda, immagini personali e reliquie decorative. Nessun nuovo bonus, drop o ritratto imposto dalle illustrazioni. |

Le tre proposte visive di una creatura non sono tre nuove specie o tre forme di Skill. Le nuove voci richieste ma non ancora nel catalogo sono esplicitamente distinte dai mostri già integrati.
