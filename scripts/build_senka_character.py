"""Build Senka's portable sheet without opening or changing a campaign save.

The full prose is deliberately retained beside editable costs and cooldowns.
Special adjudications are explicitly distinguished from supported automation.
"""
from pathlib import Path
import base64
import copy
import gzip
import json

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'output' / 'characters' / 'senka_kamaria'


def cooldown(amount=0, unit='turni'):
    return dict(amount=amount, unit=unit, startsReady=True, remaining=0)


def skill(name, descriptions, costs, *, level=1, resource='oculum', requirements=None, cds=None):
    template = json.loads((ROOT / 'docs/chatgpt_handoff/prefab_character_generator/example_prefab_character.json').read_text(encoding='utf-8'))['sheets'][0]['arti'][0]['skills'][0]
    result = copy.deepcopy(template)
    result.update(nome=name, livello=level, resilienza=0, volonta=0,
                  materia=0, oculum=0, danni=0, difesa=0)
    for i in range(5):
        result[f'evo{i+1}'] = descriptions[i] if i < len(descriptions) else 'Evoluzione futura da personalizzare con il Master.'
    padded = costs + [0] * (5-len(costs))
    result.update(oculumMinimiPerLivello=padded, oculumMassimiPerLivello=padded,
                  oculumMassimiInizialiPerLivello=padded,
                  oculumLimitiManualiPerLivello=[True]*5,
                  costoOculumDisabilitatoPerLivello=[resource != 'oculum']*5,
                  risorseCostoPerLivello=[resource]*5,
                  tipiPerLivello=['Attiva']*5,
                  unlockRequirementsPerLevel=(requirements or [{}]*len(descriptions)) + [{}]*(5-len(descriptions)),
                  cooldownPerLivello=[cooldown(n) for n in (cds or [0]*len(descriptions))] + [cooldown()]*(5-len(descriptions)))
    return result


def title(template, **kwargs):
    result = copy.deepcopy(template)
    result.update(nome='', ottenimento='', leggenda='', buff='', puntoCieco='', skill='', richiede='',
                  resilienza=0, volonta=0, materia=0, oculum=0, karma=0,
                  chiaveSistema='', equipaggiato=True)
    result.update(kwargs)
    return result


def readable_skill_costs(sheet):
    """Keep display text and the authoritative editable cost fields aligned."""
    labels = {'oculum': 'Oculum', 'materia': 'Materia', 'resilienza': 'Resilienza',
              'volonta': 'Volontà', 'nessuna': ''}
    for ability in sheet.get('skills', []):
        for form in ability.get('forme', []):
            cost = form.get('costoStrutturato')
            if not cost:
                continue
            resource = cost['resource']
            minimum = cost.get('minimum', 0)
            maximum = cost.get('maximum', minimum)
            amount = (f'{minimum}–{maximum}' if cost.get('variable')
                      else str(cost.get('amountExpression', minimum)))
            form['costo'] = ('Nessun costo' if resource == 'nessuna'
                             else f'{amount} {labels.get(resource, resource)}')
            form['oculumMinimoUtilizzabile'] = minimum
            form['oculumMassimoUtilizzabile'] = maximum
            form['oculumMassimoMaestriaIniziale'] = maximum
            form['oculumLimitiConfiguratiManualmente'] = True
        if ability.get('forme'):
            ability['costo'] = ability['forme'][0]['costo']


def build():
    example = json.loads((ROOT / 'docs/chatgpt_handoff/prefab_character_generator/example_prefab_character.json').read_text(encoding='utf-8'))['sheets'][0]
    art = copy.deepcopy(example['arti'][0])
    art.update(
        nome="L'Ombra Mascherata", tipo='Oculum Art',
        descrizione="Potere latente di Senka Kamaria. Manifesta una maschera intera nera opaca, compatta, con solchi a spirale e DUE fori a forma dell'occhio perfetto, ciascuno circondato da un circolo. Gli occhi diventano del colore dell'Oculum. Un mantello di tenebre si dissolve ai bordi in filamenti e tentacoli. Senka rimane cosciente e interpreta deliberatamente un'identità diversa. Manifestare la maschera costa zero risorse. Gli effetti speciali della trasformazione sono descritti anche nel Titolo e nelle note di gestione.",
        openName='Da definire insieme al Master',
        openDescription='Open futura non ancora stabilita: nessun potere aggiuntivo assegnato implicitamente.',
        openBuff='', openSkill='', openAttiva=False, hasIntegrity=True,
        weakPointLocation='La maschera: solo attacchi capaci di colpire immateriali possono scheggiarla quando viene mirata.',
        occhiCoinvolti='Entrambi gli occhi, del colore dell’Oculum.',
    )
    art['skills'] = [
        skill('Mantello di Tenebre', [
            'I — Con la maschera attiva, paga 3 Oculum per diventare intangibile fino al prossimo turno personale. Il mantello avvolge il corpo come una sagoma estranea. Durante un proprio attacco Senka torna momentaneamente solida; poi riprende la forma ombra per la durata residua. Non conferisce protezione dagli attacchi capaci di colpire immateriali. CD 2 turni personali.',
            'II — Richiede livello 4 e Velo +5. Costa 4 Oculum; stessa durata. Durante la forma ombra può insinuarsi in un varco realmente abbastanza ampio per la sua sagoma, senza attraversare indiscriminatamente pareti sigillate. CD 2 turni personali.',
            'III — Richiede livello 8 e Velo +8. Costa 5 Oculum; stessa durata. Può occultare meglio contorni e direzione del movimento: +3 Velo durante la forma, mantenendo il ritorno solido durante ogni proprio attacco. CD 2 turni personali.',
        ], [3, 4, 5], requirements=[{'level': 1}, {'level': 4, 'subtrait': 'velo', 'subtraitValue': 5}, {'level': 8, 'subtrait': 'velo', 'subtraitValue': 8}], cds=[2, 2, 2]),
        skill('Tentacoli d’Ombra', [
            'I — Paga 2 Oculum e un’Azione per tentare di bloccare UN bersaglio con filamenti neri; confronto di Manifestazione del Potere contro una difesa coerente. Una presa riuscita dura fino al prossimo turno personale. Finché è trattenuto, un’ALTRA Azione o Reazione e 2 Oculum consentono di infilzarlo: nuovo confronto contro il tiro del nemico per liberarsi, con Danni attuali di Senka +6 Buio se riesce. Nessun impalamento gratuito incluso nella presa. Una Reazione non avanza il turno.',
            'II — Richiede livello 5, Manifestazione del Potere +5 e la sconfitta di una Guardia Solare con Potenza totale non oltre 25 punti sotto la tua. Presa su massimo DUE bersagli, con difesa separata per ciascuno; costo 4 Oculum. Ogni impalamento richiede ancora un’Azione o Reazione separata e 2 Oculum, contro un solo bersaglio trattenuto. Danni attuali +10 Buio.',
            'III — Richiede livello 9 e Manifestazione del Potere +8. Presa su massimo TRE bersagli, con difese separate; costo 6 Oculum. Ogni impalamento costa separatamente un’Azione o Reazione e 3 Oculum. Danni attuali +15 Buio. Le prese non si moltiplicano riattivando la stessa forma.',
        ], [2, 4, 6], requirements=[{'level': 1}, {'level': 5, 'subtrait': 'manifestazione_potere', 'subtraitValue': 5, 'speciesKills': {'guardia_solare': 1}, 'minimumEnemyPower': 'owner'}, {'level': 9, 'subtrait': 'manifestazione_potere', 'subtraitValue': 8}], cds=[2, 3, 3]),
        skill('Passo nell’Ombra', [
            'I — DA SBLOCCARE: livello 3 e Velo +5. Costa 3 Oculum e usa un’Azione oppure una Reazione se risponde a un attacco. Richiede un’ombra ambientale visibile entro 6 metri: il mantello non basta. Un confronto di Velo con l’avversario decide il vantaggio: se Senka supera il tiro ottiene UNA Reazione veloce e +5 al successivo tiro per colpire OPPURE difendersi. Se sta subendo un attacco, il +5 vale già contro quel colpo e si consuma lì. Non assegnare due volte il medesimo bonus. CD 3 turni personali.',
            'II — Richiede livello 6 e Velo +7. Costa 4 Oculum, portata 9 metri; stessa Reazione veloce e stesso bonus +5 su un solo tiro. CD 3 turni personali.',
            'III — Richiede livello 10 e Velo +10. Costa 5 Oculum, portata 12 metri; stessa Reazione veloce e stesso bonus +5 su un solo tiro. CD 2 turni personali.',
        ], [3, 4, 5], level=0, requirements=[{'level': 3, 'subtrait': 'velo', 'subtraitValue': 5}, {'level': 6, 'subtrait': 'velo', 'subtraitValue': 7}, {'level': 10, 'subtrait': 'velo', 'subtraitValue': 10}], cds=[3, 3, 2]),
    ]
    art['skills'][0]['effettiPerLivello'] = [
        [dict(type='planar',target='senka_shadow_form',valueExpression='1',elementType='ombra',duration='1',mode='immediato')]
        for _ in range(3)] + [[],[]]
    art['skills'][1]['effettiPerLivello'] = [
        [dict(id=f'senka_grapple_{i+1}',type='stato',appliedState='immobilizzato',target='immobilizzato',valueExpression='1',
              recipient='nemico',duration='1',mode='finche_attivo',elementType='ombra',maximumTargets=i+1)]
        for i in range(3)] + [[],[]]
    art['skills'][2]['effettiPerLivello'] = [[dict(id=f'senka_shadow_step_{i}',type='planar',
        target='senka_shadow_step',valueExpression='0',resource=str(meters),
        elementType='ombra',recipient='nemico',mode='prossima_azione')]
        for i,meters in enumerate([6,9,12])] + [[],[]]
    base_title = example['titoli'][0]
    mask = title(base_title,
        nome='La maschera di Senka', tipo='Titolo del Fato', chiaveSistema='senka_latent_mask_v1', equipaggiato=False,
        ottenimento='Manifestazione del potere latente: non è stata trovata, comprata o donata.',
        leggenda='Sky conosce una sorella impacciata e una figura oscura che le protegge. Non sa che hanno lo stesso volto.',
        buff='SOLO CON MASCHERA ATTIVA: +6 RES, +5 VOL, +10 MAT, +5 OCU, +6 Danni e +3 Difesa. I Danni e la Difesa sono già nei campi numerici dell’oggetto: non aggiungerli una seconda volta. La riserva di Vita aggiunta dai +6 RES e i +5 Oculum spendibili si RICARICANO a ogni nuova attivazione, per correzione esplicita dell’utente. +10 Scudo soltanto alla prima attivazione di ogni fight. Scudo Oculum proprio della maschera: massimo normale 20.',
        puntoCieco='Vulnerabilità minore alla magia solare: proposta iniziale modificabile +15% Danni ricevuti da magia solare. Se un attacco capace di colpire immateriali centra criticamente la maschera, la trasformazione si disattiva per un turno.',
        skill='Solo quando viene mirata proprio la maschera, questa e il corpo diventano immediatamente immateriali per quell’attacco, come passiva. Un colpo capace di raggiungere immateriali la scheggia; filamenti neri la ricompongono senza rivelare abbastanza del volto. La passiva NON vale contro ogni attacco al corpo. Finché lo Scudo Oculum non è spezzato, ogni attacco che infligge effettivamente Danni recupera min(6, 1 + max(0, livello nemico − livello Senka)), entro 20. A 0 si spezza e non si rigenera sui Danni: torna dopo Riposo Breve o Lungo, oppure riparando il nucleo dell’Art con VELO. Riparazione consentita soltanto se lo Scudo Oculum è sotto il massimo: recupera il totale del tiro, anche oltre 20; se era spezzato recupera invece ceil(3 × tiro / 4), per eccesso. Esempio: tiro 10 → 8 se spezzato; tiro 12 → 9. Se già a 20 o oltre non puoi usare questa riparazione.',
        richiede='Manifestare la maschera. Attiva/disattiva questo Titolo insieme alla trasformazione per applicare/rimuovere i bonus numerici; le riserve speciali richiedono la gestione descritta nelle note.',
        resilienza=6, volonta=5, materia=10, oculum=5)
    racial = title(example['trattiRazziali'][0], nome='Mhunan — Figlia della Luna', tipo='Tratto Razziale',
        chiaveSistema='tutorial_race_mhunan', materia=1,
        buff='Visione perfetta al buio. @VisioneBuio @Velo+2. +1 Materia razziale già contenuto nei campi di questo tratto: non aggiungerlo nuovamente alle statistiche base.',
        ottenimento='Tratto razziale Mhunan, appartenenza lunare.', richiede='Mhunan.')
    fate = title(base_title, nome='Un Ricordo della Luna', tipo='Titolo del Fato',
        chiaveSistema='fate_title_1_first_art_skill_1_lvl_1',
        ottenimento='Prima Skill della prima Oculum Art al livello 1: Mantello di Tenebre.',
        richiede='Per evolvere: partecipa alla sconfitta di tre Guardie Solari valide per la progressione personale; ciascuna deve avere Potenza totale non oltre 25 punti sotto la tua.',
        leggenda='La maschera conserva un segreto che Senka non ha ancora condiviso con Sky.',
        buff='@Stats+4\n@Velo+2\n@Danni+3*livello Luna\n@Difesa+livello Luna',
        puntoCieco='Devi salvarla anche al costo di te stessa, Sky è tutto.',
        openName='Un Ricordo della Luna',
        openDescription='Da sbloccare uccidendo tre Guardie Solari valide. La Luna compare nel cielo per tutta la durata del Buff: fino al recupero di questa Open o alla sua sostituzione con un’altra Open. Il Buff persiste anche fra più fight. Senka ottiene +25% a RES/VOL/MAT/OCU più il +5% ricevuto da tutti i Lunari: +30% totale per lei, +5% per gli altri Lunari. Manifestazione temporanea: non riscrive la scomparsa della Luna dal cielo attuale.',
        openBuff='Statistiche effettive +30% durante questa Open (gestione percentuale dedicata).\n@Danni+10 Luna\n@Difesa+6 Luna\nLa propria Skill Open passa da CD 3 a CD 2 e da 1d6 a 1d8 tagli per tre battaglie o due Riposi Brevi e un Lungo, al primo traguardo raggiunto.',
        openSkill='Tagli lunari: 1d6 tagli, ciascuno pari a un sesto dei Danni attuali; contro i Solari infliggono il doppio. CD 3 turni. Il potenziamento della propria Open dà 1d8 tagli e CD 2 fino al primo fra tre battaglie concluse oppure due Riposi Brevi e un Lungo, anche usando un’altra Open. Ogni taglio conserva difese, resistenze e Scudi del bersaglio.',
        openEffects=[dict(type='planar', target='senka_moon_open', valueExpression='25', resource='5', duration='0', durationUnit='open_lifecycle', mode='finche_attivo', elementType='lunare')])
    fate['skillExtra'] = [dict(nome='Tagli lunari — Skill Open',
        descrizione=fate['openSkill'], combatRole='attacco',
        cost=dict(resource='nessuna',amountExpression='0'), cooldown=cooldown(3,'turni'),
        effects=[dict(id='senka_moon_cuts',type='planar',target='senka_moon_cuts',
            valueExpression='floor(danni/6)',diceExpression='1d6',recipient='nemico',
            mode='prossima_azione',elementType='lunare')])]
    revenge = title(base_title, nome='Vendetta', tipo='Titolo del Fato',
        chiaveSistema='senka_fate_vendetta',
        ottenimento='Il ricordo della famiglia sterminata dai Solari.',
        leggenda='Lusier III Guardia Elité di Grado I, dirige battaglie, stermina popoli proprio come ha fatto con la mia famiglia, proprio come io farò con lui.',
        buff='@Volonta+1', richiede='Confrontati con il passato di Senka e con Lusier III.')
    thousand = dict(nome='Mille Tagli', tipo='Attiva · Attacco', costo='1 Materia', cooldown='1 Riposo Lungo',
        descrizione='Da sbloccare: Riflessi permanenti +9 e uccisione di Erik I, valida anche quando Erik ha PT inferiore a Senka; nessun livello minimo. Richiede maschera attiva e coltello. Usa Riflessi per il tiro della Skill. Se il colpo riesce infligge SUBITO come UNICO danno: Danni attuali di Senka + totale del tiro Riflessi effettivamente usato + Potenza totale attuale. Non aggiungere nuovamente il danno base e non usare un tiro Riflessi aggiuntivo. Dopo l’uso SENKA riceve Sfinimento per UN turno personale: perde/blocca le Reazioni secondo le regole di Sfinimento. Non è danno di tipo Sfinimento e non è un effetto sul nemico. Una volta per Riposo Lungo. Costo iniziale modificabile: 1 Materia.',
        equipaggiata=False, forme=[dict(nome='Mille Tagli', tipo='Attiva · Attacco', livello='1', costo='1 Materia', cooldown='1 Riposo Lungo',
            descrizione='', unlockRequirements={'subtrait': 'riflessi', 'subtraitValue': 9, 'namedNpcKills': {'erik_i': 1}},
            costoStrutturato=dict(resource='materia', amountExpression='1', minimum=1, maximum=1, variable=False),
            cooldownStrutturato=cooldown(1, 'riposi_lunghi'))])
    thousand['forme'][0]['descrizione'] = thousand['descrizione']
    thousand['forme'][0]['effettiStrutturati'] = [dict(id='senka_thousand_cuts',
        type='planar', target='senka_thousand_cuts', valueExpression='0',
        recipient='nemico', mode='prossima_azione', elementType='tagliente')]
    # The mask is now wearable equipment, not a second passive Fate Title.
    mask_item = dict(nome='Maschera di Senka — L’Ombra Mascherata', peso=.1, quantita=1,
        note=mask['leggenda']+'\n'+mask['buff']+'\n'+mask['skill']+'\n'+mask['puntoCieco'],
        buff='@res+6; @vol+5; @mat+10; @ocu+5',
        protegge=True, equipaggiata=False, bonusDanno=6, bonusDifesa=3,
        bonusScudo=0, bonusScudoOculum=20, scudoIntegritaOculumCorrente=20,
        livelloOggetto=1, gradoOggetto=0, gradoRichiesto=0,
        craftData={'senkaMask': True, 'latentManifestation': True,
            'onEquipNormalShield': 10, 'onEquipNormalShieldOncePerFight': True,
            'refillTransformationHpOnEquip': True, 'refillTransformationOculumOnEquip': True,
            'oculumShieldRegen': 'min(6,1+max(0,enemyLevel-ownerLevel))',
            'repairSubtrait': 'velo', 'brokenRepairNumerator': 3, 'brokenRepairDenominator': 4,
            'brokenRepairRounding': 'ceil', 'repairMayOverflow': True, 'repairOnlyBelowMaximum': True,
            'futureRuntimeRequired': True})
    thousand['costo'] = '@mat-1'
    thousand['forme'][0].update(costo='@mat-1', oculumMinimoUtilizzabile=1,
        oculumMassimoUtilizzabile=1, oculumMassimoMaestriaIniziale=1, oculumLimitiConfiguratiManualmente=True)
    clone = dict(nome='Clone d’ombra di Senka', tipo='Attiva · Evocazione', costo='@mat-1',
        cooldown='2 turni personali', equipaggiata=True,
        descrizione='Spende da 1 a 10 Materia. Crea automaticamente un clone con Vita = Materia SPESA ×2 + livello di Senka; esempio 4 Materia e livello 1 → 9 Vita. Copia le quattro statistiche, sottotratti e Skill al momento dell’evocazione, compresa la maschera se attiva, senza duplicare due volte i bonus. Non può evocare altri cloni. Più cloni contemporanei, ciascuno pagato separatamente. Dura per tutto il fight o fino a 0 Vita. Alla creazione: 0 Azioni, 0 Reazioni normali, 1 Reazione veloce. Dai suoi turni: 0 Azioni e 1 Reazione normale; non riceve l’Azione ordinaria. Variante personale del Clone d’ombra del manuale; richiede il runtime della nuova versione; importare la scheda non aggiorna una vecchia app.',
        forme=[])
    clone['forme'] = [dict(nome='Clone d’ombra', tipo=clone['tipo'], livello='1', costo='@mat-1',
        descrizione=clone['descrizione'], oculumMinimoUtilizzabile=1, oculumMassimoUtilizzabile=10,
        oculumMassimoMaestriaIniziale=10, oculumLimitiConfiguratiManualmente=True,
        costoStrutturato=dict(resource='materia', amountExpression='1', minimum=1, maximum=10, variable=True),
        cooldownStrutturato=cooldown(2),
        effettiStrutturati=[dict(id='senka_shadow_clone_v1', type='planar', target='senka_shadow_clone',
            valueExpression='materia_spent*2+livello', mode='immediato', duration='1', durationUnit='fight',
            recipient='se_stesso', enabled=True, narrativeText=clone['descrizione'])])]
    clone['descrizione'] += ' Limite TOTALE per fight: max(1, min(16, 2 × livello)). Livello 0: 1; livello 1: 2; livello 4: 8; dal livello 8: 16. Contano anche i cloni morti o assorbiti: la fusione non libera nuovi utilizzi.'
    clone['forme'][0]['descrizione'] = clone['descrizione']
    fusion_text = 'Richiede Velo permanente 13 raggiunto senza buff temporanei. Usa UN’Azione, senza altri costi, per fondere Senka con TUTTI i suoi Cloni d’ombra attualmente presenti nel fight. I cloni assorbiti scompaiono e non generano morte nemica, EXP o Drop. Senka riceve come HP temporanei la somma della loro Vita ATTUALE. Riceve inoltre floor(somma Volontà dei cloni/10), floor(somma Materia/10) e floor(somma Oculum/10): prima somma, poi arrotonda per difetto. Nessun bonus Resilienza. Tutti questi benefici durano fino a fine fight. Esempio: due cloni con 7 Volontà ciascuno danno +1 Volontà. I cloni assorbiti contano ancora nel limite totale evocabile per fight. Runtime personale della nuova versione; verificare separatamente i fight condivisi.'
    fusion = dict(nome='Confluenza delle Ombre', tipo='Attiva · Supporto', costo='Nessun costo',
        cooldown='', descrizione=fusion_text, equipaggiata=False,
        forme=[dict(nome='Confluenza delle Ombre', tipo='Attiva · Supporto', livello='1', costo='Nessun costo',
            descrizione=fusion_text, unlockRequirements={'subtrait':'velo','subtraitValue':13,'permanentOnly':True},
            costoStrutturato=dict(resource='nessuna',amountExpression='0',minimum=0,maximum=0,variable=False),
            effettiStrutturati=[dict(id='senka_shadow_fusion_v1',type='planar',target='senka_shadow_fusion',
                valueExpression='1',mode='immediato',duration='1',durationUnit='fight',recipient='se_stesso',enabled=True,
                narrativeText=fusion_text)])])
    impale = dict(nome='Impalamento d’Ombra', tipo='Attacco', costo='@ocu-2', cooldown='0',
        equipaggiata=True, descrizione='Disponibile subito. Richiede un bersaglio ancora immobilizzato dai propri Tentacoli d’Ombra e la maschera attiva. Paga un’altra Azione o Reazione e 2 Oculum. Nuovo confronto contro la difesa con cui il nemico cerca di liberarsi. Se riesce: Danni attuali +6 Buio. La Reazione non avanza il turno.',
        forme=[dict(nome='I',tipo='Attacco',livello='1',costo='@ocu-2',
            costoStrutturato=dict(resource='oculum',amountExpression='2',minimum=2,maximum=2),
            cooldownStrutturato=cooldown(),effettiStrutturati=[
                dict(type='danno',valueExpression='6',elementType='ombra',recipient='bersaglio',mode='prossima_azione'),
                dict(type='planar',target='senka_shadow_impale',valueExpression='0',elementType='ombra',recipient='bersaglio',mode='prossima_azione')])])
    sheet = dict(
        nome='Senka Kamaria', tipoScheda='Personaggio', razza='Mhunan', livello='1', grado='0', exp='100',
        resilienza='3', volonta='1', materia='2', oculum='4',
        currentResilienza='3', currentVolonta='1', currentMateria='3', currentOculum='4', normalCurrentOculum=4,
        maxOculum=4, currentHp='81', hpTemp='0', scudo='0', scudoOculum='0', scudoOculumMax='0',
        background="Senka Kamaria ha sedici anni ed è una Mhunan lunare di Lost Town. I Solari hanno ucciso i suoi genitori; lei e Sky sono orfane da tempo. Sky ha cinque anni, è molto gentile e vivace e cerca di mostrarsi coraggiosa per sostenere la sorella maggiore. Haniel, il loro portavoce e informatore, si è preso cura di entrambe quando Sky era troppo piccola per ricordarlo e ha addestrato Senka. Per mantenerle, Senka ruba ai ricchi e ai Solari; con la maschera compie anche assassinii per conto di Haniel. Non porta mai Sky negli incarichi. Sky considera Haniel un loro amico e crede che L'Ombra Mascherata sia un'altra persona che le protegge. Senka, normalmente impacciata e deboluccia, interpreta deliberatamente quell'identità: rimane lei, senza una seconda coscienza stabilita. Le motivazioni profonde, i segreti di Haniel e l'aspetto normale restano intenzionalmente da definire dal giocatore.",
        notePersonaggio="Femmina, 16 anni. Identità segreta: L'Ombra Mascherata. Aspetto normale lasciato aperto. Equipaggiamento: coltello. BASE NUMERICA PROPOSTA, MODIFICABILE: RES 3, VOL 1, MAT 1, OCU 4, oltre al +1 MAT del tratto Mhunan. La maschera è inizialmente disattivata. I bonus della maschera sono nel Titolo separato omonimo, inizialmente non equipaggiato: non applicarli due volte. I costi e cooldown delle tecniche sono salvati in formato strutturato. Intangibilità contestuale, prese/impalamento, riserve ricaricabili della maschera, rigenerazione/rottura/riparazione dello Scudo Oculum, confronto del teletrasporto e formula speciale di Mille Tagli sono regole personalizzate da gestire con il Master: non sono qui dichiarate automatizzate. Nessuna scheda di Sky inclusa. Requisiti, costi, CD e valori proposti sono modificabili; i numeri scelti dal giocatore restano distinti dalle proposte di bilanciamento.",
        titoli=[fate, revenge], trattiRazziali=[racial], arti=[art], skills=[impale, thousand, clone, fusion],
        inventario=[mask_item, dict(nome='Coltello di Senka', peso=.25, quantita=1, note='Coltello da incarichi e autodifesa, migliorato su richiesta: +3 Danni Taglienti. Materiale e aspetto ancora personalizzabili; nessun potere magico implicito.', arma=True, equipaggiata=True, bonusDanno=3, elementoDanno='Tagliente', livelloOggetto=1)],
        hiddenEyeStats=[dict(id=k, nome=n, descrizione='Scelta iniziale modificabile; competenze apprese da Haniel.', valore=v, unlocked=True) for k,n,v in [('velo','Velo',3), ('riflessi','Riflessi',3), ('inganno','Inganno',2), ('percezione','Percezione',1)]],
        tutorialSubtraitAllocation=dict(velo=3, riflessi=3, inganno=2, percezione=1), tutorialCompletato=True,
        campaignDifficulty='normale', planarRuntime={'identityCelestial': 'lunare'},
    )
    sheet['notePersonaggio'] = sheet['notePersonaggio'].replace('I bonus della maschera sono nel Titolo separato omonimo, inizialmente non equipaggiato', 'I bonus della maschera sono nell’ITEM indossabile omonimo, inizialmente non equipaggiato')
    sheet['notePersonaggio'] = sheet['notePersonaggio'].replace('BASE NUMERICA PROPOSTA, MODIFICABILE: RES 3, VOL 1, MAT 1, OCU 4', 'BASE NUMERICA CONFERMATA, MODIFICABILE: RES 3, VOL 1, MAT 2, OCU 4 (10 punti), più @Stats+4 a ciascuna statistica da Un Ricordo della Luna e +1 VOL da Vendetta')
    sheet['notePersonaggio'] = 'Femmina, 16 anni; Mhunan lunare di Lost Town. Aspetto normale volutamente aperto. Dieci punti base confermati: RES3/VOL1/MAT2/OCU4, più i bonus razziali e dei Titoli. Maschera ITEM indossabile, inizialmente disattivata: applica i bonus una sola volta. Le nuove riserve della trasformazione, lo Scudo Oculum, i cloni e la fusione richiedono la nuova build: importare il codice non aggiorna il motore di una vecchia app. Impalamento disponibile subito, separato dalla presa e con costo 2 Oculum. Teletrasporto, Mille Tagli e Open si sbloccano con i requisiti registrati nella scheda e richiedono la nuova versione del motore. I test di combattimento e quelli della rete sono riportati separatamente nel rapporto della patch. Ogni costo, durata, requisito, effetto e statistica resta modificabile. Nessuna scheda di Sky inclusa.'
    sheet['background'] += '\n\nI GENITORI\nPer Senka i suoi genitori erano tutto. Erano persone semplici: il padre era un tuttofare, molto affettuoso, che ripudiava i Solari per ciò che avevano fatto e continuavano a fare alla loro gente. La madre cuciva vestiti, era estremamente gentile e cordiale e dipingeva fantastici ritratti lunari. Uno dei suoi ritratti è ancora appeso nella locanda. I loro nomi e il soggetto preciso del quadro restano da definire.'
    sheet['notePersonaggio'] += '\nBackground e incubo: testo confermato dall’utente, sempre modificabile. Per Senka i genitori erano tutto; padre tuttofare affettuoso, madre sarta e pittrice gentile e cordiale. Un suo ritratto lunare resta appeso nella locanda.'
    sheet['planarRuntime']['authoredTitleRequirements'] = {fate['chiaveSistema']: {'speciesAny':['guardia_solare','guardia_solare_elite'], 'kills':3}}
    sheet['planarRuntime']['senkaBackgroundStatus'] = 'draft_awaiting_user_canon'
    sheet['background'] += '\n\nINCUBO RICORRENTE — IL GIORNO DELLA PIAZZA\n' + (ROOT / 'docs/personaggi/SENKA_INCUBO.txt').read_text(encoding='utf-8').strip()
    sheet['background'] += '\n\nSenka e Sky abitano nei piani più bassi di Lost Town, in una modesta stanza doppia della taverna pagata da Haniel, sotto i circoli solari di Erik e Lusier.'
    sheet['relicArtPackId'] = 'senka_kamaria'
    sheet['inventario'].append(dict(
        nome='Vitalium Ridefinito', peso=.2, quantita=1, equipaggiata=False,
        note='Consumabile: ripristina HP, Resilienza, Volontà, Materia e Oculum attuali fino ai massimali e l’integrità delle Art. Non crea Oculum se il massimale è zero.',
    ))
    sheet['notePersonaggio'] += '\nAggiornamento31ottobre:100EXP e un Vitalium Ridefinito nell’inventario, aggiunti su richiesta. I100EXP sono già nel campo EXP, non da assegnare nuovamente. Maschera non equipaggiata; Danni e Difesa una sola volta nei campi dell’oggetto, non duplicati in comandi nelle note.'
    readable_skill_costs(sheet)
    power_file = ROOT / 'output/characters/lusier_iii/potenza.json'
    if power_file.exists():
        measured = json.loads(power_file.read_text(encoding='utf-8'))
        sheet['background'] += '\n\nHANIEL — «' + measured['haniel'] + '»'
        sheet['planarRuntime']['hanielLusierTargetPower'] = measured['totalPower']
    return sheet


if __name__ == '__main__':
    OUT.mkdir(parents=True, exist_ok=True)
    sheet = build()
    raw = json.dumps(sheet, ensure_ascii=False, separators=(',', ':')).encode('utf-8')
    compressed = gzip.compress(raw, compresslevel=9, mtime=0)
    checksum = 0x811c9dc5
    for byte in compressed:
        checksum = ((checksum ^ byte) * 0x01000193) & 0xffffffff
    code = f'OC3:{checksum:08x}:' + base64.urlsafe_b64encode(compressed).decode().rstrip('=')
    (OUT / 'Senka_Kamaria.json').write_text(json.dumps(sheet, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    (OUT / 'Senka_Kamaria.codice.txt').write_text(code+'\n', encoding='utf-8')
    print(f'One sheet; {len(code)} code characters; {OUT}')
