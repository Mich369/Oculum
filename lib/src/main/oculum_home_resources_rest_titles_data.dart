part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member, unused_element

extension _OculumHomeResourcesRestTitlesData on _OculumHomePageState {
  // RISORSE / ISPIRAZIONI / KARMA
  // =====================================================

  void modificaRisorsa(TextEditingController controller, int delta) {
    final valoreAttuale = leggiNumero(controller);
    final nuovoValore = max(0, valoreAttuale + delta);

    setState(() {
      controller.text = nuovoValore.toString();

      aggiungiLog(
        'Risorsa modificata: ${delta >= 0 ? '+' : ''}$delta → $nuovoValore.',
      );
    });

    programmaSalvataggio();
  }

  void modificaKarmaBase(int delta) {
    setState(() {
      karmaController.text = (leggiNumero(karmaController) + delta).toString();

      risultato = t(
        'Karma modificato: ${karmaController.text}.',
        'Karma changed: ${karmaController.text}.',
      );

      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  void modificaKarmaTitolo(TextEditingController controller, int valore) {
    setState(() {
      controller.text = clampKarmaTitolo(valore).toString();
    });

    programmaSalvataggio();
  }

  void usaIspirazioneBase() {
    final valore = leggiNumero(ispirazioniController);

    if (valore <= 0) {
      setState(() {
        risultato = t(
          'Non hai Ispirazioni base da usare.',
          'You have no base Inspirations to use.',
        );
      });

      return;
    }

    setState(() {
      ispirazioniController.text = (valore - 1).toString();

      risultato = t(
        'Ispirazione usata: puoi ritirare un tiro non critico.',
        'Inspiration used: you may reroll a non-critical roll.',
      );

      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  void usaSuperIspirazione() {
    final valore = leggiNumero(superIspirazioniController);

    if (valore <= 0) {
      setState(() {
        risultato = t(
          'Non hai Super Ispirazioni da usare.',
          'You have no Super Inspirations to use.',
        );
      });

      return;
    }

    setState(() {
      superIspirazioniController.text = (valore - 1).toString();

      risultato = t(
        'Super Ispirazione usata: puoi ritirare anche un critico.',
        'Super Inspiration used: you may reroll even a critical roll.',
      );

      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  void usaIspirazioneOculum() {
    final valore = leggiNumero(ispirazioniOculumController);

    if (valore <= 0) {
      setState(() {
        risultato = t(
          'Non hai Ispirazioni Oculum da usare.',
          'You have no Oculum Inspirations to use.',
        );
      });

      return;
    }

    setState(() {
      ispirazioniOculumController.text = (valore - 1).toString();

      risultato = t(
        'Ispirazione Oculum usata: puoi ritirare un critico mantenendolo critico.',
        'Oculum Inspiration used: you may reroll a critical roll while keeping it critical.',
      );

      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  void convertiIspirazioneOculum() {
    final valore = leggiNumero(ispirazioniOculumController);

    if (valore <= 0) {
      setState(() {
        risultato = t(
          'Non hai Ispirazioni Oculum da convertire.',
          'You have no Oculum Inspirations to convert.',
        );
      });

      return;
    }

    setState(() {
      ispirazioniOculumController.text = (valore - 1).toString();

      ispirazioniController.text = (leggiNumero(ispirazioniController) + 2)
          .toString();

      risultato = t(
        'Ispirazione Oculum convertita in 2 Ispirazioni base.',
        'Oculum Inspiration converted into 2 base Inspirations.',
      );

      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }
  // =====================================================
  // RIPOSO / BISOGNI / CENERE
  // =====================================================

  int recuperoPercentuale(int valore, double percentuale, int minimo) {
    if (valore <= 0) return 0;

    final recupero = (valore * percentuale).ceil();

    return max(minimo, recupero);
  }

  void segnaSessioneSenzaBisogni() {
    final sessioni = leggiNumero(sessioniSenzaBisogniController) + 1;

    setState(() {
      sessioniSenzaBisogniController.text = sessioni.toString();

      if (sessioni >= 3) {
        tempResilienza -= 1;
        rimarginaHpDaAumentoResilienza(-1);
        tempOculum -= 1;
        sessioniSenzaBisogniController.text = '0';

        ultimoEventoRiposo = t(
          'Tre sessioni senza mangiare, bere o dormire: -1 Resilienza temporanea e -1 Oculum temporaneo.',
          'Three sessions without eating, drinking or sleeping: -1 temporary Resilience and -1 temporary Oculum.',
        );
      } else {
        ultimoEventoRiposo = t(
          'Sessione senza bisogni segnata: $sessioni/3. Alla terza sessione subisci -1 Resilienza e -1 Oculum temporanei.',
          'Session without needs marked: $sessioni/3. On the third session you suffer -1 temporary Resilience and -1 temporary Oculum.',
        );
      }

      risultato = ultimoEventoRiposo;
      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  void segnaGiornoSenzaCiboAcqua() {
    final stat = Random().nextInt(4);

    setState(() {
      giorniSenzaCiboAcquaController.text =
          (leggiNumero(giorniSenzaCiboAcquaController) + 1).toString();

      if (stat == 0) {
        tempResilienza -= 1;
        rimarginaHpDaAumentoResilienza(-1);
      } else if (stat == 1) {
        tempVolonta -= 1;
      } else if (stat == 2) {
        tempMateria -= 1;
      } else {
        tempOculum -= 1;
      }

      cenereController.text = (leggiNumero(cenereController) + 3).toString();

      final statNome = [
        t('Resilienza', 'Resilience'),
        t('Volontà', 'Will'),
        'Materia',
        'Oculum',
      ][stat];

      ultimoEventoRiposo = t(
        'Giorno senza cibo o acqua: -1 temporaneo a $statNome e +3 Cenere.',
        'Day without food or water: -1 temporary to $statNome and +3 Ash.',
      );

      risultato = ultimoEventoRiposo;
      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  void mangiaEBevi() {
    setState(() {
      modificaBuffTemporaneo('resilienza', 2, salva: false);

      cenereController.text = max(
        0,
        leggiNumero(cenereController) - 1,
      ).toString();

      sessioniSenzaBisogniController.text = '0';

      ultimoEventoRiposo = t(
        'Hai mangiato e bevuto a sufficienza: +2 Resilienza temporanea per la sessione, -1 Cenere e reset sessioni senza bisogni.',
        'You ate and drank enough: +2 temporary Resilience for the session, -1 Ash and reset sessions without needs.',
      );

      risultato = ultimoEventoRiposo;
      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  void modificaBuffTemporaneo(String key, int delta, {bool salva = true}) {
    if (delta == 0) return;

    switch (key) {
      case 'resilienza':
        tempResilienza += delta;
        rimarginaHpDaAumentoResilienza(delta);
        break;
      case 'volonta':
        tempVolonta += delta;
        break;
      case 'materia':
        tempMateria += delta;
        break;
      case 'oculum':
        tempOculum += delta;
        break;
    }

    risultato =
        '${t('Buff temporaneo', 'Temporary buff')} ${key.toUpperCase()} ${delta > 0 ? '+' : ''}$delta.';
    ultimoEventoRiposo = risultato;
    aggiungiLog(risultato);

    if (salva) programmaSalvataggio();
  }

  void impostaBuffTemporaneo(String key, int value) {
    final current = switch (key) {
      'resilienza' => tempResilienza,
      'volonta' => tempVolonta,
      'materia' => tempMateria,
      'oculum' => tempOculum,
      _ => 0,
    };

    setState(() {
      modificaBuffTemporaneo(key, value - current, salva: false);
    });
    programmaSalvataggio();
  }

  void modificaConsumoRegistrato(String key, int delta) {
    setState(() {
      switch (key) {
        case 'resilienza':
          raccoltaResilienzaSpesa = max(0, raccoltaResilienzaSpesa + delta);
          break;
        case 'volonta':
          raccoltaVolontaSpesa = max(0, raccoltaVolontaSpesa + delta);
          break;
        case 'materia':
          raccoltaMateriaSpesa = max(0, raccoltaMateriaSpesa + delta);
          break;
        case 'oculum':
          raccoltaOculumSpesa = max(0, raccoltaOculumSpesa + delta);
          break;
      }

      ultimoEventoRiposo = t(
        'Consumo registrato modificato manualmente.',
        'Recorded consumption edited manually.',
      );
      risultato = ultimoEventoRiposo;
      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  void impostaConsumoRegistrato(String key, int value) {
    final current = switch (key) {
      'resilienza' => raccoltaResilienzaSpesa,
      'volonta' => raccoltaVolontaSpesa,
      'materia' => raccoltaMateriaSpesa,
      'oculum' => raccoltaOculumSpesa,
      _ => 0,
    };

    modificaConsumoRegistrato(key, value - current);
  }

  void riposoBreve() {
    setState(() {
      final cenere = leggiNumero(cenereController);

      cenereController.text = max(
        0,
        cenere - recuperoPercentuale(cenere, 0.25, 1),
      ).toString();

      final deficitRes = tempResilienza < 0 ? -tempResilienza : 0;
      final recuperoRes = (deficitRes / 2).ceil();
      final deficitVol = tempVolonta < 0 ? -tempVolonta : 0;
      final deficitMat = tempMateria < 0 ? -tempMateria : 0;
      final deficitOcu = tempOculum < 0 ? -tempOculum : 0;

      tempResilienza += recuperoRes;
      rimarginaHpDaAumentoResilienza(recuperoRes);
      tempVolonta += (deficitVol / 2).ceil();
      tempMateria += (deficitMat / 2).ceil();
      tempOculum += (deficitOcu / 2).ceil();

      recuperaStatsAttualiConRiposoBreve();
      ricaricaScudoOculum();

      raccoltaResilienzaSpesa = max(0, raccoltaResilienzaSpesa ~/ 2);
      raccoltaVolontaSpesa = max(0, raccoltaVolontaSpesa ~/ 2);
      raccoltaMateriaSpesa = max(0, raccoltaMateriaSpesa ~/ 2);
      raccoltaOculumSpesa = max(0, raccoltaOculumSpesa ~/ 2);

      ultimoEventoRiposo = t(
        'Riposo breve: recuperata metà delle penalità temporanee, metà delle stats attuali mancanti e 25% di Cenere, minimo 1.',
        'Short rest: recovered half of temporary penalties, half of missing current stats and 25% Ash, minimum 1.',
      );

      risultato = ultimoEventoRiposo;
      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  void riposoLungo() {
    setState(() {
      final cenere = leggiNumero(cenereController);

      cenereController.text = max(
        0,
        cenere - recuperoPercentuale(cenere, 0.50, 3),
      ).toString();

      final deficitRes = tempResilienza < 0 ? -tempResilienza : 0;
      final recuperoRes = (deficitRes / 2).ceil();
      tempResilienza += recuperoRes;
      rimarginaHpDaAumentoResilienza(recuperoRes);

      if (tempOculum < 0) {
        tempOculum = 0;
      }

      refullaStatsAttuali();
      ricaricaScudoOculum();

      raccoltaResilienzaSpesa = 0;
      raccoltaVolontaSpesa = 0;
      raccoltaMateriaSpesa = 0;
      raccoltaOculumSpesa = 0;

      sessioniSenzaBisogniController.text = '0';

      refullaHp();

      ultimoEventoRiposo = t(
        'Riposo lungo completato: dura 1 ora e mezza. Recupera metà Resilienza negativa, tutto Oculum negativo, tutte le stats attuali, 50% di Cenere minimo 3 e refulla gli HP.',
        'Long rest completed: it lasts 1.5 hours. It recovers half negative Resilience, all negative Oculum, all current stats, 50% Ash minimum 3 and refills HP.',
      );

      risultato = ultimoEventoRiposo;
      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  void attivitaRaccoltaPescaCaccia() {
    setState(() {
      setCurrentStatFromVisibleInput(
        'volonta',
        max(0, volontaTotale() - 1).toString(),
        trackConsumption: false,
      );
      raccoltaVolontaSpesa += 1;

      cenereController.text = (leggiNumero(cenereController) + 1).toString();

      ultimoEventoRiposo = t(
        'Raccolta / Pesca / Caccia: -1 Volontà attuale e +1 Cenere.',
        'Gathering / Fishing / Hunting: -1 current Will and +1 Ash.',
      );

      risultato = ultimoEventoRiposo;
      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  void forgiaturaConMateria() {
    setState(() {
      setCurrentStatFromVisibleInput(
        'materia',
        max(0, materiaTotale() - 1).toString(),
        trackConsumption: false,
      );
      raccoltaMateriaSpesa += 1;

      cenereController.text = (leggiNumero(cenereController) + 1).toString();

      ultimoEventoRiposo = t(
        'Forgiatura: -1 Materia attuale usata per la creazione e +1 Cenere.',
        'Forging: -1 current Materia used for crafting and +1 Ash.',
      );

      risultato = ultimoEventoRiposo;
      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  void forgiaturaConOculum() {
    setState(() {
      setCurrentStatFromVisibleInput(
        'oculum',
        max(0, oculumTotale() - 1).toString(),
        trackConsumption: false,
      );
      raccoltaOculumSpesa += 1;

      cenereController.text = (leggiNumero(cenereController) + 1).toString();

      ultimoEventoRiposo = t(
        'Forgiatura: -1 Oculum attuale usato come alternativa alla Materia e +1 Cenere.',
        'Forging: -1 current Oculum used as an alternative to Materia and +1 Ash.',
      );

      risultato = ultimoEventoRiposo;
      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  void resetBuffDebuffTemporanei() {
    setState(() {
      rimarginaHpDaAumentoResilienza(-tempResilienza);
      tempResilienza = 0;
      tempVolonta = 0;
      tempMateria = 0;
      tempOculum = 0;

      raccoltaResilienzaSpesa = 0;
      raccoltaVolontaSpesa = 0;
      raccoltaMateriaSpesa = 0;
      raccoltaOculumSpesa = 0;

      sessioniSenzaBisogniController.text = '0';
      giorniSenzaCiboAcquaController.text = '0';

      ultimoEventoRiposo = t(
        'Buff e debuff temporanei resettati. La Cenere non è stata azzerata.',
        'Temporary buffs and debuffs reset. Ash was not cleared.',
      );

      risultato = ultimoEventoRiposo;
      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  // =====================================================
  // TITOLI DEL FATO / ARTI
  // =====================================================

  bool titoloEsistePerChiave(String chiave) {
    return titoli.any((titolo) => titolo.chiaveSistema == chiave);
  }

  String rimuoviBuffFatoPredefiniti(String text) {
    var clean = text;
    for (final tag in const [
      '@VC+5',
      '@Danni+5',
      '@Damage+5',
      '@VC+10',
      '@Difesa+10',
      '@Defense+10',
      '@VC+15',
      '@Danni+15',
      '@Damage+15',
      '@Difesa+15',
      '@Defense+15',
    ]) {
      clean = clean.replaceAll(tag, '');
    }
    return clean.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
  }

  void assicuraTagTitoloDelFato(String chiaveSistema, String quickTags) {
    for (final titolo in titoli) {
      if (titolo.chiaveSistema != chiaveSistema) continue;
      if (quickTags.trim().isEmpty) {
        titolo.buff = rimuoviBuffFatoPredefiniti(titolo.buff);
        return;
      }
      if (titolo.buff.contains('@')) return;
      titolo.buff = '${titolo.buff} $quickTags'.trim();
      return;
    }
  }

  void creaTitoloDelFatoAutomatico({
    required String chiaveSistema,
    required String nome,
    required String ottenimento,
    required String buff,
    required String skill,
  }) {
    if (titoloEsistePerChiave(chiaveSistema)) return;

    titoli.add(
      OculumTitle(
        nome: nome,
        tipo: 'Titolo del Fato',
        ottenimento: ottenimento,
        buff: rimuoviBuffFatoPredefiniti(buff),
        puntoCieco: t(
          'Il Fato pretende coerenza: se il personaggio tradisce il significato profondo del Titolo, il Master può trasformarne il dono in una condanna narrativa.',
          'Fate demands coherence: if the character betrays the deep meaning of the Title, the Master may turn its gift into a narrative curse.',
        ),
        skill: skill,
        richiede: t(
          'Evolve tramite azioni coerenti con l’Art, scelte importanti, sacrifici, rivelazioni o momenti in cui l’Oculum reagisce alla storia.',
          'Evolves through actions coherent with the Art, important choices, sacrifices, revelations or moments where the Oculum reacts to the story.',
        ),
        karma: 1,
        evoluto: false,
        chiaveSistema: chiaveSistema,
      ),
    );
  }

  void controllaTitoliDelFatoAutomatici({bool silenzioso = false}) {
    if (arti.isEmpty || arti.first.skills.length < 3) {
      if (!silenzioso) {
        setState(() {
          risultato = t(
            'Non ci sono abbastanza Skill nella prima Art per controllare i Titoli del Fato.',
            'There are not enough Skills in the first Art to check Fate Titles.',
          );

          aggiungiLog(risultato);
        });

        programmaSalvataggio();
      }

      return;
    }

    int creati = 0;

    setState(() {
      final primaArt = arti.first;
      final primaSkill = primaArt.skills[0];
      final secondaSkill = primaArt.skills[1];
      final terzaSkill = primaArt.skills[2];

      if (primaSkill.livello >= 1 &&
          !titoloEsistePerChiave('fate_title_1_first_art_skill_1_lvl_1')) {
        creaTitoloDelFatoAutomatico(
          chiaveSistema: 'fate_title_1_first_art_skill_1_lvl_1',
          nome: t('Primo Titolo del Fato', 'First Fate Title'),
          ottenimento: t(
            'Ottenuto quando la prima Skill della prima Art raggiunge il livello 1. Non dipende dal livello del personaggio.',
            'Gained when the first Skill of the first Art reaches level 1. It does not depend on the character level.',
          ),
          buff: t(
            'Il Fato ha iniziato a osservarti. Questo Titolo rappresenta la prima vera risposta dell’Oculum alla tua identità.',
            'Fate has begun to watch you. This Title represents the first true answer of the Oculum to your identity.',
          ),
          skill: t(
            'Collegato alla prima Skill della prima Art: ${primaSkill.nome}.',
            'Linked to the first Skill of the first Art: ${primaSkill.nome}.',
          ),
        );

        creati++;
      }

      if (secondaSkill.livello >= 2 &&
          !titoloEsistePerChiave('fate_title_2_first_art_skill_2_lvl_2')) {
        creaTitoloDelFatoAutomatico(
          chiaveSistema: 'fate_title_2_first_art_skill_2_lvl_2',
          nome: t('Secondo Titolo del Fato', 'Second Fate Title'),
          ottenimento: t(
            'Ottenuto quando la seconda Skill della prima Art raggiunge il livello 2. Rappresenta una crescita più consapevole del potere.',
            'Gained when the second Skill of the first Art reaches level 2. It represents a more conscious growth of power.',
          ),
          buff: t(
            'Il Fato non ti guarda soltanto: ora ti riconosce. Questo Titolo lega il personaggio a una seconda forma della sua Art.',
            'Fate does not merely watch you: it now recognizes you. This Title binds the character to a second form of their Art.',
          ),
          skill: t(
            'Collegato alla seconda Skill della prima Art: ${secondaSkill.nome}.',
            'Linked to the second Skill of the first Art: ${secondaSkill.nome}.',
          ),
        );

        creati++;
      }

      if (terzaSkill.livello >= 3 &&
          !titoloEsistePerChiave('fate_title_3_first_art_skill_3_lvl_3')) {
        creaTitoloDelFatoAutomatico(
          chiaveSistema: 'fate_title_3_first_art_skill_3_lvl_3',
          nome: t('Terzo Titolo del Fato', 'Third Fate Title'),
          ottenimento: t(
            'Ottenuto quando la terza Skill della prima Art raggiunge il livello 3. È una soglia alta: il personaggio non sta solo usando l’Art, la sta incarnando.',
            'Gained when the third Skill of the first Art reaches level 3. This is a high threshold: the character is not only using the Art, they are embodying it.',
          ),
          buff: t(
            'Il Fato ha inciso un segno profondo. Questo Titolo rappresenta la terza dichiarazione della tua identità davanti all’Oculum.',
            'Fate has carved a deep mark. This Title represents the third declaration of your identity before the Oculum.',
          ),
          skill: t(
            'Collegato alla terza Skill della prima Art: ${terzaSkill.nome}.',
            'Linked to the third Skill of the first Art: ${terzaSkill.nome}.',
          ),
        );

        creati++;
      }

      assicuraTagTitoloDelFato('fate_title_1_first_art_skill_1_lvl_1', '');
      assicuraTagTitoloDelFato('fate_title_2_first_art_skill_2_lvl_2', '');
      assicuraTagTitoloDelFato('fate_title_3_first_art_skill_3_lvl_3', '');

      if (!silenzioso) {
        risultato = creati == 0
            ? t(
                'Controllo completato: nessun nuovo Titolo del Fato da creare.',
                'Check completed: no new Fate Title to create.',
              )
            : t(
                'Controllo completato: creati $creati Titoli del Fato.',
                'Check completed: created $creati Fate Titles.',
              );

        aggiungiLog(risultato);
      }
    });

    programmaSalvataggio();
  }

  void creaPrimoTitoloDelFato() {
    final nome = primoTitoloFatoNomeController.text.trim().isEmpty
        ? 'Primo Titolo del Fato'
        : primoTitoloFatoNomeController.text.trim();

    final descrizione = primoTitoloFatoDescrizioneController.text.trim();

    final giaEsiste = titoli.any((titolo) => titolo.nome == nome);

    if (giaEsiste) {
      setState(() {
        risultato = t(
          'Questo Titolo del Fato esiste già.',
          'This Fate Title already exists.',
        );
      });

      return;
    }

    setState(() {
      titoli.add(
        OculumTitle(
          nome: nome,
          tipo: 'Titolo del Fato',
          ottenimento:
              'Fato 1 — ottenuto quando la prima Skill della prima Art raggiunge il livello 1. Non dipende dal livello del personaggio.',
          buff: descrizione.isEmpty
              ? 'Il Fato ha iniziato a osservarti perché la tua prima Skill della prima Art ha raggiunto il livello 1.'
              : descrizione,
          puntoCieco:
              'Il Fato pretende coerenza: tradire il significato del titolo può trasformarlo in condanna.',
          skill:
              'Collegato alla prima Skill della prima Art. Non è un premio di livello personaggio.',
          richiede:
              'Evolve tramite azioni coerenti con il destino del personaggio.',
          karma: 1,
          evoluto: false,
          chiaveSistema: 'fate_title_1_manual',
        ),
      );

      risultato = t(
        'Titolo del Fato creato: [$nome].',
        'Fate Title created: [$nome].',
      );

      aggiungiLog('Creato Titolo del Fato: [$nome].');
    });

    programmaSalvataggio();
  }

  void modificaLivelloSkillArt(ArtSkill skill, int delta) {
    setState(() {
      skill.livello = max(0, skill.livello + delta);

      risultato = t(
        'Livello Skill aggiornato: ${skill.nome} livello ${skill.livello}.',
        'Skill level updated: ${skill.nome} level ${skill.livello}.',
      );

      aggiungiLog(risultato);
    });

    controllaTitoliDelFatoAutomatici(silenzioso: true);
    programmaSalvataggio();
  }
  // =====================================================
  // DIARIO / SKILL / TITOLI / INVENTARIO
  // =====================================================

  void aggiungiPaginaDiario() {
    final numero = diarioPagine.length + 1;

    setState(() {
      diarioPagine.add(
        'Pagina $numero - Scrivi qui memoria, sogni, colpe, legami, scoperte o ferite della sessione.',
      );

      ispirazioniController.text = (leggiNumero(ispirazioniController) + 1)
          .toString();

      risultato = t(
        'Nuova pagina diario aggiunta. Ricompensa: +1 Ispirazione base.',
        'New diary page added. Reward: +1 base Inspiration.',
      );

      aggiungiLog('Pagina diario aggiunta. +1 Ispirazione base.');
    });

    programmaSalvataggio();
  }

  void eliminaPaginaDiario(int index) {
    if (index < 0 || index >= diarioPagine.length) return;

    setState(() {
      risultato = t(
        'Le pagine diario non vengono eliminate: restano memoria permanente della scheda.',
        'Diary pages are not deleted: they remain permanent sheet memory.',
      );
      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  OculumTitle titoloDaCampiCorrenti({
    required String nome,
    required String fallbackTipo,
  }) {
    final tipo = titoloTipoController.text.trim();
    return OculumTitle(
      nome: nome,
      tipo: tipo.isEmpty ? fallbackTipo : tipo,
      ottenimento: titoloOttenimentoController.text.trim(),
      buff: titoloBuffController.text.trim(),
      puntoCieco: titoloPuntoCiecoController.text.trim(),
      skill: titoloSkillController.text.trim(),
      richiede: titoloRichiedeController.text.trim(),
      resilienza: leggiNumero(titoloResController),
      volonta: leggiNumero(titoloVolController),
      materia: leggiNumero(titoloMatController),
      oculum: leggiNumero(titoloOcuController),
      karma: leggiKarmaTitolo(titoloKarmaController),
      evoluto: nuovoTitoloEvoluto,
      openName: titoloOpenNameController.text.trim(),
      openDescription: titoloOpenDescriptionController.text.trim(),
      openBuff: titoloOpenBuffController.text.trim(),
      openSkill: titoloOpenSkillController.text.trim(),
    );
  }

  bool tipoTitoloVaNeiTrattiRazziali([String? value]) {
    final normalized = oculumNormalizeText(cleanUiText(value ?? ''));
    if (normalized.isEmpty) return false;

    final words = normalized.split(' ').where((x) => x.isNotEmpty).toSet();
    return normalized.contains('tratto razziale') ||
        normalized.contains('tratti razziali') ||
        normalized.contains('racial trait') ||
        normalized.contains('racial traits') ||
        normalized.contains('sottorazza') ||
        normalized.contains('sottorazze') ||
        normalized.contains('subrace') ||
        normalized.contains('subraces') ||
        words.contains('razza') ||
        words.contains('razze') ||
        words.contains('race') ||
        words.contains('races');
  }

  void pulisciCampiTitolo() {
    titoloNomeController.clear();
    titoloOttenimentoController.clear();
    titoloBuffController.clear();
    titoloPuntoCiecoController.clear();
    titoloSkillController.clear();
    titoloRichiedeController.text = '???';
    titoloResController.text = '0';
    titoloVolController.text = '0';
    titoloMatController.text = '0';
    titoloOcuController.text = '0';
    titoloKarmaController.text = '0';
    titoloOpenNameController.clear();
    titoloOpenDescriptionController.clear();
    titoloOpenBuffController.clear();
    titoloOpenSkillController.clear();
    nuovoTitoloEvoluto = false;
  }

  void creaTitolo() {
    final nome = titoloNomeController.text.trim();

    if (nome.isEmpty) return;

    if (tipoTitoloVaNeiTrattiRazziali(titoloTipoController.text)) {
      creaTrattoRazziale();
      return;
    }

    setState(() {
      titoli.add(
        titoloDaCampiCorrenti(nome: nome, fallbackTipo: t('Titolo', 'Title')),
      );

      pulisciCampiTitolo();

      risultato = t('Titolo creato.', 'Title created.');
      aggiungiLog('Titolo creato: [$nome].');
    });

    programmaSalvataggio();
  }

  void creaTrattoRazziale() {
    final nome = titoloNomeController.text.trim();
    if (nome.isEmpty) return;

    if (trattiRazziali.length >= 13) {
      setState(() {
        risultato = t(
          'Slot Tratti Razziali pieni: massimo 13 tra razze e sottorazze.',
          'Racial Trait slots full: max 13 between races and subraces.',
        );
      });
      return;
    }

    setState(() {
      trattiRazziali.add(
        titoloDaCampiCorrenti(
          nome: nome,
          fallbackTipo: t(
            'Tratto Razziale / Sottorazza',
            'Racial Trait / Subrace',
          ),
        )..equipaggiato = true,
      );

      if (razzaController.text.trim().isEmpty) {
        razzaController.text = nome;
      }

      pulisciCampiTitolo();

      risultato = t('Tratto razziale creato.', 'Racial trait created.');
      aggiungiLog('Tratto razziale creato: [$nome].');
    });

    programmaSalvataggio();
  }

  void usaOpen(OculumTitle titolo, {TitleOpenEntry? openExtra}) {
    setState(() {
      if (!titolo.evoluto) return;

      if (openExtra != null) {
        if (openExtra.attiva) {
          if (titolo.equipaggiato) {
            rimarginaHpDaAumentoResilienza(
              -extraOpenRuntimeResilienzaBonus(openExtra),
            );
          }
          openExtra.attiva = false;
        } else {
          disattivaTutteLeOpen(exceptTitle: titolo, exceptOpenExtra: openExtra);
          equipaggiaTitoloPerOpen(titolo);
          openExtra.attiva = true;
          if (titolo.equipaggiato) {
            rimarginaHpDaAumentoResilienza(
              extraOpenRuntimeResilienzaBonus(openExtra),
            );
          }
        }

        risultato = openExtra.attiva
            ? '${t('Open attivata', 'Open activated')}: ${openExtra.nome.isEmpty ? titolo.nome : openExtra.nome}'
            : '${t('Open disattivata', 'Open deactivated')}: ${openExtra.nome.isEmpty ? titolo.nome : openExtra.nome}';

        aggiungiLog(risultato);
        return;
      }

      if (titolo.openAttiva) {
        if (titolo.equipaggiato) {
          rimarginaHpDaAumentoResilienza(
            -titleOpenRuntimeResilienzaBonus(titolo),
          );
        }
        titolo.openAttiva = false;
      } else {
        disattivaTutteLeOpen(exceptTitle: titolo);
        equipaggiaTitoloPerOpen(titolo);
        titolo.openAttiva = true;
        if (titolo.equipaggiato) {
          rimarginaHpDaAumentoResilienza(
            titleOpenRuntimeResilienzaBonus(titolo),
          );
        }
      }

      risultato = titolo.openAttiva
          ? '${t('Open attivata', 'Open activated')}: ${titolo.openName.isEmpty ? titolo.nome : titolo.openName}'
          : '${t('Open disattivata', 'Open deactivated')}: ${titolo.openName.isEmpty ? titolo.nome : titolo.openName}';

      aggiungiLog(risultato);
    });

    scheduleRealtimeOculumChanged();
    programmaSalvataggio();
  }

  void aggiungiOpenExtra(OculumTitle titolo) {
    if (titolo.openExtra.length >= 12) {
      setState(() {
        risultato = t(
          'Questo titolo ha già 12 Open extra. Limite massimo raggiunto.',
          'This title already has 12 extra Opens. Maximum limit reached.',
        );
      });

      return;
    }

    setState(() {
      titolo.evoluto = true;

      titolo.openExtra.add(
        TitleOpenEntry(
          nome: '${t('Nuova Open', 'New Open')} ${titolo.openExtra.length + 1}',
        ),
      );

      risultato = t(
        'Nuova Open aggiunta al titolo: ${titolo.nome} (${titolo.openExtra.length}/12)',
        'New Open added to title: ${titolo.nome} (${titolo.openExtra.length}/12)',
      );

      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  void aggiungiSkillExtraTitolo(OculumTitle titolo) {
    setState(() {
      titolo.evoluto = true;

      titolo.skillExtra.add(
        TitleExtraSkillEntry(
          nome: t('Nuova Skill del Titolo', 'New Title Skill'),
          descrizione: '',
        ),
      );

      risultato = t(
        'Nuova Skill aggiunta al titolo: ${titolo.nome}',
        'New Skill added to title: ${titolo.nome}',
      );

      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  void creaItem() {
    final nome = itemNomeController.text.trim();

    if (nome.isEmpty) return;

    final peso = leggiDouble(itemPesoController);
    final quantita = leggiNumero(itemQuantitaController);

    setState(() {
      final item = InventoryItem(
        nome: nome,
        peso: peso,
        quantita: quantita <= 0 ? 1 : quantita,
        note: itemNoteController.text.trim(),
        buff: itemBuffController.text.trim(),
        arma: nuovoItemArma,
        protegge: nuovoItemProtegge,
        equipaggiata: nuovoItemEquipaggiato,
        bonusDanno: leggiNumero(itemBonusDannoController),
        bonusDifesa: leggiNumero(itemBonusDifesaController),
        bonusScudo: leggiNumero(itemBonusScudoController),
        elementoDanno: itemElementoDannoController.text.trim().isEmpty
            ? 'Fisico'
            : itemElementoDannoController.text.trim(),
      );
      inventario.add(item);
      if (item.equipaggiata) applicaScudoItemAttuale(item, 1);

      itemNomeController.clear();
      itemPesoController.text = '0';
      itemQuantitaController.text = '1';
      itemNoteController.clear();
      itemBuffController.clear();
      itemBonusDannoController.text = '0';
      itemBonusDifesaController.text = '0';
      itemBonusScudoController.text = '0';
      itemElementoDannoController.text = 'Fisico';

      nuovoItemArma = false;
      nuovoItemProtegge = false;
      nuovoItemEquipaggiato = false;

      risultato = t('Oggetto aggiunto: $nome.', 'Item added: $nome.');
      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  void creaSkill() {
    final nome = skillNomeController.text.trim();

    if (nome.isEmpty) return;

    setState(() {
      skills.add(
        CharacterSkill(
          nome: nome,
          tipo: skillTipoController.text.trim(),
          costo: skillCostoController.text.trim(),
          cooldown: skillCooldownController.text.trim(),
          descrizione: skillDescrizioneController.text.trim(),
          resilienza: leggiNumero(skillResController),
          volonta: leggiNumero(skillVolController),
          materia: leggiNumero(skillMatController),
          oculum: leggiNumero(skillOcuController),
          danni: leggiNumero(skillDanniController),
          difesa: leggiNumero(skillDifesaController),
        ),
      );

      skillNomeController.clear();
      skillTipoController.text = 'Cerchio Magico';
      skillCostoController.text = '0';
      skillCooldownController.text = 'Nessuno';
      skillDescrizioneController.clear();
      skillResController.text = '0';
      skillVolController.text = '0';
      skillMatController.text = '0';
      skillOcuController.text = '0';
      skillDanniController.text = '0';
      skillDifesaController.text = '0';

      risultato = t('Skill creata: $nome.', 'Skill created: $nome.');
      aggiungiLog(risultato);
    });

    programmaSalvataggio();
  }

  // =====================================================
}
