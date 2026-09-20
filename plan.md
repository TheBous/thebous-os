# Architettura della Fase di Technical Design e Task Decomposition nello Spec-Driven Development

Nello sviluppo software orientato agli agenti autonomi, il passaggio dalla specifica dei requisiti alla generazione del codice eseguibile costituisce la transizione a più elevata criticità metodologica ed empirica [cite: 1, 2, 3]. Se la specifica contrattuale stabilisce in modo univoco il perimetro funzionale del sistema delimitando ciò che deve essere implementato e le invarianti di dominio che non possono essere violate, la fase di Technical Design e Task Decomposition ha il compito di tradurre tali prescrizioni nella topologia fisica del codice sorgente [cite: 1, 2, 4].

L'omissione di un'architettura formale di pianificazione induce instabilità sistematiche all'interno dei workflow basati su modelli di linguaggio [cite: 2, 5]. Tra queste risaltano la generazione incontrollata di codice orfano, l'alterazione accidentale di moduli estranei all'ambito del cambiamento, il progressivo disallineamento rispetto ai pattern del repository e l'insorgenza di allucinazioni contestuali causate dal sovraccarico della finestra di attenzione [cite: 2, 5, 6]. Per strutturare un pacchetto di competenze che risponda agli standard ingegneristici più avanzati, è indispensabile comporre le migliori pratiche sviluppate da ecosistemi quali GitHub Spec Kit, obra/Superpowers, OpenSpec, Spec Kitty, Amazon Kiro e Taskmaster, strutturando la pianificazione tecnica e la scomposizione operativa secondo criteri deterministici e verificabili [cite: 2, 4, 6, 7, 8].

---

## Fondamenti Teorici e Decomposizione dell'Intento Architetturale

La redazione del piano tecnico non si esaurisce in una semplice scomposizione discorsiva della specifica, ma opera come una vera e propria compilazione strutturata di livello intermedio [cite: 2, 3]. Il design tecnico prende in carico le asserzioni comportamentali e le clausole sintattiche (come i vincoli formulati tramite sintassi EARS o schemi JSON rigidi) e le proietta sull'albero dei sorgenti, rispettando i principi di qualità e le linee guida globali codificate nella costituzione del progetto [cite: 1, 2, 9]. Questa trasformazione deve rispondere a precisi imperativi architetturali prima che qualsiasi riga di logica applicativa possa essere redatta.

Il primo imperativo risiede nella mappatura d'impatto topologico. L'agente di pianificazione analizza la base di codice per quantificare con esattezza la superficie di contatto dell'intervento, determinando in modo esaustivo quali classi necessitino di estensione, quali interfacce contrattuali debbano essere modificate, quali schemi di persistenza richiedano migrazioni strutturali e quali contratti di routing debbano essere dichiarati [cite: 2, 10, 11]. L'esplicitazione a monte di questa matrice di modifica impedisce all'agente esecutore di espandere autonomamente lo scopo dell'intervento durante la successiva fase di generazione del codice, scongiurando il rischio di propagazione di modifiche non autorizzate [cite: 7, 10].

Il secondo imperativo riguarda la formalizzazione delle divergenze progettuali tramite decisioni vincolanti e permanenti. Durante l'esplorazione del design, l'assistente si confronta inevitabilmente con bivi implementativi alternativi, come la selezione tra librerie concorrenti, l'adozione di lock ottimistici rispetto a quelli pessimistici, o la scelta tra meccanismi di caching distribuiti rispetto a strutture in memoria [cite: 5, 12, 13]. Modelli ingenui tendono a risolvere tali ambiguità assumendo decisioni silenti che spesso collidono con le consuetudini del team [cite: 5, 14]. Riprendendo il paradigma dei Decision Moments formalizzato da Spec Kitty, l'agente deve invece sospendere la generazione quando incontra una biforcazione strategica, interpellare lo sviluppatore umano e registrare la risoluzione all'interno di Architecture Decision Record (ADR) stabili e immutabili [cite: 5, 12, 13]. Tali documenti persistono all'interno del repository, consentendo alle sessioni future di comprendere la razionalità storica di una scelta senza doverla inferire a ritroso [cite: 12, 13].

Il terzo imperativo teorico si fonda sull'isolamento dei contratti di confine e sui principi del Domain-Driven Design (DDD), un approccio valorizzato in toolkit come MoAI-ADK e GRACE [cite: 14, 15, 16]. Prima di definire la logica algoritmica interna dei componenti, il technical design deve prescrivere le firme tipizzate, le interfacce pure, i Data Transfer Object (DTO) e i relativi schemi di validazione dei dati [cite: 14, 16]. L'isolamento del modello di dominio dai dettagli implementativi e infrastrutturali garantisce che ogni singolo modulo possa essere sottoposto a verifica autonoma, aprendo la strada alla generazione diretta di contratti di test deterministici [cite: 14, 16].

---

## Analisi Comparativa dei Framework di Planning e Decomposizione

I principali framework dello Spec-Driven Development adottano filosofie eterogenee per governare la fase di planning, configurando compromessi differenti tra dettaglio documentale, costi computazionali, isolamento del codice e tracciabilità complessiva [cite: 6, 15].

| Framework / Tool | Approccio al Technical Design | Modello di Decomposizione dei Task | Meccanismo di Tracciabilità e Context Scoping | Gestione dell'Isolamento del Workspace | Punti di Forza Rilevanti | Limiti e Debolezze Operative |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **GitHub Spec Kit** [cite: 1, 2, 17] | Generazione sequenziale guidata da comandi slash (`/plan`) su directory dedicate [cite: 1, 2, 17]. | Documento `tasks.md` gerarchico strutturato come elenco progressivo di checklist [cite: 1, 2, 17]. | Collegamento concettuale per capitoli di specifica; tracciamento testuale diretto [cite: 1, 2]. | Assente nativamente; opera direttamente sul working tree o branch corrente [cite: 15]. | Piena standardizzazione open source; templates universali compatibili con molteplici CLI [cite: 1, 9, 17]. | Elevata prolissità documentale; tendenza alla perdita di sincronizzazione nei task complessi [cite: 2, 5]. |
| **obra/Superpowers** [cite: 4, 10, 18] | Abilità `writing-plans` redatta per un ipotetico ingegnere con zero contesto del sistema [cite: 4, 10, 19]. | Micro-task atomici (2-5 minuti di computazione) con ciclo Red-Green-Refactor intrinseco [cite: 4, 10, 19]. | Mappatura biunivoca per task con indicazione di file esatti, comandi shell e asserzioni [cite: 4, 10]. | Isolamento preventivo tramite skill automatica `using-git-worktrees` [cite: 4, 19]. | Dettaglio esecutivo rigoroso con codice completo; adozione del TDD vincolata per costruzione [cite: 4, 10, 19]. | Generazione di documenti di piano monolitici prolissi (1500+ righe) suscettibili a context burn [cite: 20]. |
| **OpenSpec** [cite: 12, 21, 22] | `design.md` contestualizzato nella cartella delta `openspec/changes/{id}/` [cite: 22, 23]. | `tasks.md` snello orientato alle modifiche incrementali su codice preesistente [cite: 21, 22]. | Tracciabilità rigorosa tra delta spec (`[ADDED]`, `[MODIFIED]`) e voci operative [cite: 9, 12, 21]. | Nessun supporto nativo integrato; delegato a configurazioni manuali dell'utente [cite: 12, 22]. | Output leggero che abbatte la *review fatigue*; eccellente gestione di sistemi brownfield [cite: 9, 21, 22]. | Assenza di un motore autonomo per la risoluzione di grafi di dipendenza articolati [cite: 22]. |
| **Amazon Kiro** [cite: 2, 9] | Struttura fissa a tre documenti (`requirements`, `design`, `tasks`) gestita via IDE [cite: 2, 9]. | Task granulari collegati formalmente a identificatori univoci dei requisiti [cite: 2, 9]. | Tracciabilità matematica supportata da risolutori formali e logica computazionale SMT [cite: 9]. | Ambiente sandbox confinato all'interno dell'ecosistema e dell'editor proprietario [cite: 2, 9]. | Verifica logica automatica delle contraddizioni; tracciabilità biunivoca infallibile [cite: 2, 9]. | Dipendenza da piattaforma chiusa; specifiche statiche soggette a degradazione temporale [cite: 2, 9]. |
| **Spec Kitty** [cite: 5, 13, 24, 25] | Design organizzato per missioni tecniche, ADR persistenti e living wiki integrato [cite: 13, 25]. | Work packages atomici sincronizzati direttamente su interfaccia Kanban visiva [cite: 5, 13, 25]. | Collegamento di provenienza formale tra decisione, artefatto di design e task [cite: 5, 13]. | Generazione e smontaggio automatico di Git Worktree dedicati per ciascuna missione [cite: 5, 6, 24]. | Perfetto isolamento dello spazio di lavoro; governance robusta per team multidisciplinari [cite: 5, 13]. | Complessità architetturale marcata; eccessivo overhead per modifiche microscopiche [cite: 6, 15]. |
| **Taskmaster / PRD-Taskmaster** [cite: 8, 26, 27, 28] | Parsing automatico del PRD con analisi algoritmica di complessità (scoring da 1 a 10) [cite: 8, 27]. | Grafo aciclico diretto (DAG) di task con capacità di espansione ricorsiva (`tm expand`) [cite: 26, 27]. | Mappatura delle dipendenze di blocco; tracciamento dinamico dello stato di avanzamento [cite: 26, 27]. | Gestione unicamente logica dei metadati archiviati nella directory `.taskmaster/` [cite: 27]. | Identificazione preventiva di compiti sovradimensionati e forzatura della scomposizione [cite: 27]. | Focalizzazione ristretta al task management senza harness di validazione del codice [cite: 8, 27]. |

Dalla comparazione emerge una netta polarizzazione metodologica. Da un lato, approcci come GitHub Spec Kit e OpenSpec privilegiano la semplicità strutturale attraverso file Markdown standard, demandando all'attenzione umana il controllo della consistenza [cite: 1, 2, 21]. Dall'altro lato, strumenti avanzati quali Superpowers, Spec Kitty e Kiro introducono barriere procedurali e vincoli infrastrutturali complessi (Git Worktrees, motori SMT, sub-agenti di revisione), sacrificando la rapidità di bootstrap iniziale in cambio di un'estrema robustezza del ciclo esecutivo [cite: 2, 4, 9, 13].

---

## Dinamica della Granularità Operativa: La Risoluzione della Patologia del Monolithic Plan

La determinazione della corretta granularità nella scomposizione dei compiti costituisce il fattore di maggiore impatto sull'affidabilità dei modelli generativi [cite: 4, 20, 27]. Nella prassi operativa si riscontrano due patologie diametralmente opposte, entrambe capaci di vanificare i benefici dello Spec-Driven Development [cite: 2, 20].

La prima patologia corrisponde all'antipattern del macro-tasking, ovvero l'assegnazione all'agente di compiti formulati a maglie troppo larghe, come la richiesta generica di implementare interi sottosistemi e la relativa suite di collaudo [cite: 2, 20]. Posto dinnanzi a un obiettivo esteso, il modello linguistico non riesce a mantenere un'attenzione uniforme su tutti i requisiti di confine: tende a produrre test fittizi privi di asserzioni reali, tralascia la gestione degli errori e assume scelte implementative non documentate per colmare i vuoti operativi, degradando la coerenza complessiva dell'architettura [cite: 2, 5, 6].

La seconda patologia, analizzata criticamente all'interno della comunità ingegneristica (come testimoniato dalle problematiche discusse nella Issue #512 di *obra/Superpowers*), risiede nella redazione di piani monolitici eccessivamente dettagliati [cite: 20]. Quando un framework spinge la pianificazione fino a includere blocchi completi di codice sorgente per decine di compiti all'interno di un unico documento Markdown, il file risultante supera facilmente le 1.500-2.000 righe [cite: 20]. Questo approccio genera tre conseguenze deleterie [cite: 2, 5, 20]:

1. Un consumo sproporzionato di token computazionali, in quanto il documento monolitico viene reiniettato nella sessione a ogni turno conversazionale, comportando costi ingenti e latenze operative elevate [cite: 20].
2. Il degrado per compressione automatica del contesto: non appena l'agente avvia la scrittura del codice, consulta la base di codice ed esegue i test iniziali, la memoria di lavoro si satura rapidamente [cite: 5, 20]. I meccanismi di summarization automatica intervengono condensando la cronologia e distruggendo proprio quei dettagli analitici che erano stati faticosamente specificati per i task successivi [cite: 5, 20].
3. La fatica di revisione dello sviluppatore umano, il quale, sopraffatto da una mole documentale spropositata e dispersiva, finisce per validare acriticamente il piano, annullando il valore protettivo dell'ispezione umana [cite: 2, 5].

La risoluzione ingegneristica di questo compromesso consiste nell'adottare il principio di atomicità operativa coniugato a una topologia fisica disaccoppiata [cite: 4, 20]. L'unità fondamentale di scomposizione deve essere tarata sull'intervallo temporale ottimale compreso tra due e cinque minuti di computazione ed esecuzione per singolo micro-step [cite: 4, 18, 20]. All'interno di questa finestra operativa, l'agente mantiene la massima concentrazione logica e non rischia di saturare il contesto prima di produrre un'asserzione verificabile [cite: 4, 20].

Sul piano architetturale, il disaccoppiamento si realizza separando l'indice di pianificazione dalle schede di dettaglio esecutivo [cite: 20, 26]. Invece di riversare l'intero progetto in un solo file, il piano si struttura tramite un indice leggero ad alta densità informativa (formattato come elenco JSON o Markdown sintetico) che elenca esclusivamente ID, dipendenze, criteri di accettazione associati e percorsi target [cite: 20, 26]. I dettagli esecutivi e le istruzioni di testing vengono estratti in modo puntuale ed effimero: l'agente orchestratore non somministra l'intero piano al sub-agente esecutore, ma genera un prompt mirato di circa 1.000-2.000 token contenente unicamente la scheda del singolo micro-task [cite: 20]. Il sub-agente opera così in un contesto vergine e focalizzato, portando a termine il ciclo operativo senza subire l'influenza della cronologia pregressa né rischiare la compressione dei dettagli futuri [cite: 4, 20, 29].

---

## Topologie di Esecuzione a Grafo Aciclico Diretto e Isolamento Fisico del Workspace

La tradizionale esecuzione puramente sequenziale dei compiti mal si adatta a progetti software moderni con architetture disaccoppiate e componenti eterogenee [cite: 14, 26]. L'adozione di un Grafo Aciclico Diretto (DAG) consente di categorizzare i micro-task in base alle reali dipendenze logiche, strutturando l'avanzamento lungo stadi successivi che massimizzano la parallelizzazione e circoscrivono gli impatti di eventuali errori [cite: 14, 26].

La transizione attraverso il DAG segue una progressione definita [cite: 11, 14]. Lo stadio fondazionale comprende la formalizzazione dei contratti di tipo puri, delle definizioni DTO e delle migrazioni degli schemi persistenti, elementi che abilitano la compilazione statica e fungono da base d'appoggio per tutte le componenti successive [cite: 11, 14]. Lo stadio della logica di dominio si articola in compiti paralleli che sviluppano i servizi di core business, svincolati dall'infrastruttura esterna e sviluppati mediante una rigorosa disciplina di test unitari [cite: 11, 14].

Lo stadio di integrazione e coordinamento implementa i middleware applicativi, gli adattatori di persistenza e i componenti dell'interfaccia utente, assemblando la logica di dominio attorno ai framework operativi [cite: 11, 14]. Infine, lo stadio di convergenza ed end-to-end unifica i percorsi precedentemente isolati, validando l'intero flusso funzionale attraverso suite di collaudo integrate prima della chiusura formale del ramo di modifica [cite: 11, 14].

| Stadio del DAG di Esecuzione | Tipologia di Deliverable e File Autorizzati | Vincoli TDD e Meccanismi di Verifica | Barriere di Confinamento e Failure Impact |
| :--- | :--- | :--- | :--- |
| **Stadio 0: Fondazionale** [cite: 11, 14] | Interfacce pure, DTO tipizzati, migrazioni database (`.sql`, `.prisma`), contratti API [cite: 11, 14]. | Nessun test dinamico richiesto; verifica statica tramite compilatore di tipo (`tsc`, `mypy`) [cite: 14]. | Un errore blocca immediatamente l'intero grafo; nessun task a valle può essere istanziato [cite: 26]. |
| **Stadio 1: Core Logic (Parallelo)** [cite: 11, 14] | Servizi di dominio puro, algoritmi di calcolo, entità di business isolate (`*.service.ts`) [cite: 11, 14]. | Ciclo Red-Green-Refactor obbligatorio; 100% branch coverage su logica pura isolata [cite: 4, 19]. | Eventuali fallimenti impattano esclusivamente il singolo ramo logico senza corrompere l'infrastruttura [cite: 20]. |
| **Stadio 2: Integrazione (Parallelo)** [cite: 11, 14] | Middleware HTTP, controller REST, repository di persistenza, componenti UI [cite: 11, 14]. | Test di integrazione con mock dei confini infrastrutturali (es. cache mockate, DB in-memory) [cite: 4, 11]. | Regressioni circoscritte al livello di trasporto; il dominio applicativo rimane preservato [cite: 14]. |
| **Stadio 3: Convergenza** [cite: 11, 14] | Cablaggio del router principale, bootstrap dell'applicazione (`app.ts`), configurazione [cite: 11, 14]. | Suite di test end-to-end su container applicativo; audit di conformità architetturale [cite: 4, 14]. | Rileva incompatibilità di cablaggio e incongruenze di sistema prima del merge sul branch principale [cite: 4, 14]. |

Accanto alla strutturazione logica del DAG, la sicurezza esecutiva del workflow richiede l'isolamento fisico dell'albero dei sorgenti [cite: 4, 6, 12]. Lavorare all'interno del working tree primario espone a rischi continui: conflitti tra modifiche parziali generate dall'agente e file modificati dallo sviluppatore, accumulo di file temporanei non tracciati e complessità nel gestire deviazioni d'urgenza [cite: 6, 12, 22].

L'implementazione dei Git Worktree, documentata nelle migliori prassi di Spec Kitty e Superpowers, crea una cartella secondaria separata sul filesystem locale ancorata al branch isolato della modifica [cite: 4, 6, 24]. All'interno di questo spazio protetto, l'agente può operare senza interferire con lo stato dell'ingegnere, il quale mantiene la piena libertà di esaminare lo stato del ramo principale o di istanziare worktree concorrenti per ulteriori agenti o attività parallele [cite: 5, 6, 12].

A presidio ulteriore dell'integrità del codebase, la scomposizione deve incorporare la delimitazione del Negative Space, un concetto derivato dal toolkit di governance Squelette [cite: 7]. Ogni singolo micro-task deve dichiarare preventivamente l'elenco tassativo dei file autorizzati alla manipolazione e una lista esplicita di percorsi categoricamente interdetti [cite: 7, 10]. L'inclusione di hook di pre-commit o di wrapper di esecuzione deterministici blocca qualsiasi transazione qualora il diff contenga file esterni ai confini concordati, impedendo all'agente di alterare configurazioni sensibili o aggirare i limiti prestabiliti [cite: 4, 7].

---

## Tracciabilità Biunivoca, Audit Indipendente e Definition of Done

Il completamento del piano tecnico non autorizza la transizione diretta alla fase di implementazione senza una verifica sistematica della completezza formale dell'artefatto [cite: 2, 4, 14]. Tale controllo si articola su tre meccanismi convergenti:

La matrice di tracciabilità biunivoca correla ciascun criterio di accettazione della specifica (es. `AC-001`, `AC-002`) con uno o più task del piano [cite: 2, 9, 14]. Un piano tecnico è considerato strutturalmente invalido se manifesta requisiti orfani, ovvero criteri descritti nella specifica che risultano privi di un compito operativo associato a un test di convalida [cite: 10].

Allo stesso modo, la presenza di task spuri che introducono modifiche funzionali, refactoring cosmetici o ottimizzazioni premature non contemplate nella specifica di partenza costituisce una violazione delle regole di ingegnerizzazione, imponendo l'immediata rettifica del piano [cite: 4, 10].

Il secondo meccanismo risiede nel pattern del Plan-Document-Reviewer indipendente, derivato dalla metodologia di Superpowers [cite: 10, 18, 29]. Affidare l'auto-valutazione del piano allo stesso agente che lo ha redatto porta frequentemente a un'accettazione acritica dovuta a bias di consistenza [cite: 18, 29]. Al termine della generazione di `design.md` e `tasks.md`, l'orchestratore istanzia un sub-agente di review completamente disaccoppiato [cite: 10, 18, 29]. Tale entità riceve unicamente la specifica d'origine, i vincoli costituzionali e gli artefatti di piano prodotti, operando in una finestra di contesto pulita [cite: 10, 18, 29].

Il revisore indipendente esegue un'analisi critica basata su criteri oggettivi:
1. Esamina la copertura analitica di tutti i rami di errore e delle eccezioni codificate nella specifica [cite: 10].
2. Ispeziona i compiti alla ricerca di formulazioni vaghe, istruzioni ambigue o placeholder (come l'uso di "TODO" o "aggiungere validazione qui"), rifiutando il documento in loro presenza [cite: 10].
3. Controlla la coerenza terminologica e tipologica tra i diversi task, accertando che una firma definita in un micro-task corrisponda esattamente a quanto referenziato nei compiti a valle [cite: 10].
4. Individua le modalità di guasto implicite o gli scenari limite che non sono stati presidiati da specifici casi di test, prescrivendone l'inserimento nel piano operativo [cite: 10].

Qualora il revisore riscontri incongruenze, il documento viene restituito all'agente autore per la correzione automatica; soltanto a valle della ratifica formale del revisore il piano viene presentato all'ingegnere umano per l'approvazione finale [cite: 10, 18].

Il terzo elemento è la formulazione esplicita della Definition of Done per ogni singolo compito [cite: 1, 10, 19]. Essa non può limitarsi a un giudizio soggettivo dell'agente, ma deve basarsi su riscontri oggettivi ed evidenze empiriche [cite: 4, 7]. Per i compiti di pura tipizzazione, la condizione è rappresentata dalla compilazione con esito positivo dei tipi; per i compiti di logica di business, dal superamento del ciclo di test unitari con asserzioni reali; per i compiti di convergenza, dal passaggio ininterrotto dell'intera suite di collaudo all'interno del Git Worktree isolato [cite: 4, 14, 19].

---

## Architettura degli Artefatti di Pianificazione e Template Canonici

La fase di technical planning produce due artefatti primari salvati all'interno della cartella temporanea del cambiamento (`changes/CHG-{ID}/`), progettati per massimizzare la chiarezza e ridurre il carico cognitivo [cite: 2, 21, 22].

### Artefatto Architetturale: `design.md`

# Technical Design: Autenticazione a Due Fattori (TOTP)
**Change ID:** CHG-2026-089
**Status:** Approved
**Related Specs:** specs/auth/two-factor.md

## 1. Architectural Impact & Topology
- Introduzione del servizio crittografico TOTP in `src/auth/totp.service.ts`.
- Estensione della tabella `users` tramite script DDL per il supporto a secret cifrati.
- Implementazione del middleware guard per le rotte protette in `src/auth/guards/totp.guard.ts`.

## 2. Invariants & Domain Contracts
- Invariante di Sicurezza: I secret TOTP devono essere salvati cifrati (AES-256-GCM); divieto di persistenza in chiaro.
- Invariante di Sessione: Emissione di token transitorio a validità limitata (5 minuti) fino alla verifica del secondo fattore.

## 3. Architecture Decision Records (ADR)
- **ADR-01:** Utilizzo delle WebCrypto API native anziché dipendenze esterne per l'algoritmo RFC 6238.
  - *Razionale:* Minimizzazione dei rischi legati alla supply chain e rispetto delle regole di sicurezza della costituzione.
- **ADR-02:** Rate limiting persistito su Redis (massimo 5 tentativi consecutivi per finestra di 15 minuti).

## 4. File Modification Matrix

| File Path | Operation | Component Responsibility |
| :--- | :--- | :--- |
| `src/auth/totp.types.ts` | Create | Interfacce contrattuali e definizioni tipizzate dei DTO |
| `src/auth/totp.service.ts` | Create | Algoritmo di generazione e verifica numerica RFC 6238 |
| `src/db/migrations/20260330_totp.sql` | Create | Definizione schema DDL per colonne cifrate |
| `src/auth/guards/totp.guard.ts` | Create | Intercettazione delle richieste HTTP e verifica rate limit |
| `src/app.ts` | Modify | Registrazione e montaggio del router di secondo fattore |
| `tests/unit/auth/totp.service.test.ts` | Create | Test unitari isolati per la logica crittografica |
| `tests/integration/totp-flow.test.ts` | Create | Collaudo end-to-end del ciclo completo di autenticazione |

### Artefatto Decompositivo: `tasks.md`

# Implementation Tasks: Autenticazione a Due Fattori (TOTP)
**Change ID:** CHG-2026-089
**Execution Topology:** Directed Acyclic Graph (DAG)
**Assigned Worktree:** .worktrees/CHG-2026-089

- [ ] **Task 1: Definizione Tipi di Contratto e DTO**
  - **ID:** T-001 | **DAG Phase:** 0 (Fondazionale) | **Deps:** []
  - **AC Coverage:** AC-001, AC-002
  - **Allowed Paths:** `src/auth/totp.types.ts`
  - **Forbidden Paths:** `src/auth/*.service.ts`, `src/app.ts`
  - **TDD Protocol:** Non applicabile (dichiarazione di tipi puri).
  - **Definition of Done:** Compilazione del type checker senza errori (`npm run typecheck`).

- [ ] **Task 2: Servizio di Cifratura e Validazione TOTP (TDD)**
  - **ID:** T-002 | **DAG Phase:** 1 (Core Logic) | **Deps:** [T-001]
  - **AC Coverage:** AC-001, AC-003
  - **Allowed Paths:** `src/auth/totp.service.ts`, `tests/unit/auth/totp.service.test.ts`
  - **Forbidden Paths:** `src/db/*`, `src/app.ts`
  - **TDD Protocol:**
    1. Red: Scrivere test unitario per asserire la generazione del token valido su secret prefissato; accertare il fallimento.
    2. Green: Implementare la minima logica necessaria in `totp.service.ts`; accertare il passaggio del test.
    3. Commit: Eseguire commit atomico `feat(auth): implement totp service core logic`.
  - **Definition of Done:** 100% test unitari superati con branch coverage completa.

- [ ] **Task 3: Guard Middleware e Rate Limiting su Redis (TDD)**
  - **ID:** T-003 | **DAG Phase:** 2 (Integration) | **Deps:** [T-001, T-002]
  - **AC Coverage:** AC-004
  - **Allowed Paths:** `src/auth/guards/totp.guard.ts`, `tests/unit/auth/totp.guard.test.ts`
  - **Forbidden Paths:** `src/auth/totp.service.ts`
  - **TDD Protocol:**
    1. Red: Scrivere test con mock di Redis che asserisce codice HTTP 429 dopo 5 tentativi falliti; accertare errore.
    2. Green: Implementare il middleware in `totp.guard.ts`; accertare esito positivo.
    3. Commit: Eseguire commit atomico `feat(auth): implement totp guard with rate limiting`.
  - **Definition of Done:** Suite del middleware verificata con successo e gestione corretta degli header di blocco.

- [ ] **Task 4: Cablaggio di Sistema e Test di Convergenza End-to-End**
  - **ID:** T-004 | **DAG Phase:** 3 (Convergenza) | **Deps:** [T-002, T-003]
  - **AC Coverage:** AC-001, AC-002, AC-003, AC-004
  - **Allowed Paths:** `src/app.ts`, `tests/integration/totp-flow.test.ts`
  - **Forbidden Paths:** None (integrazione su intero worktree).
  - **TDD Protocol:** Collaudo end-to-end con esecuzione sul router registrato.
  - **Definition of Done:** Suite integrata eseguita con successo; nessuna regressione nei collaudi preesistenti.

---

## Blueprint Implementativo: La Skill Universale di Technical Planning

Per rendere operativa questa disciplina all'interno di un pacchetto esportabile compatibile con lo standard aperto `SKILL.md` (riconosciuto da ambienti quali Claude Code, OpenAI Codex e OpenCode), l'abilità di pianificazione deve essere codificata seguendo il principio della progressiva trasparenza informativa [cite: 30, 31, 32, 33].

Il frontmatter YAML stabilisce i vincoli di attivazione e gli strumenti consentiti, mantenendosi compatto per non eccedere la soglia di discovery nel prompt di sistema [cite: 30, 32, 33]. Il corpo dell'abilità delinea tassativamente la procedura esecutiva senza includere testo esplicativo superfluo, mentre le operazioni deterministiche (allocazione worktree, linting dei vincoli) vengono demandate a script shell ausiliari esterni [cite: 30, 32, 34].

### Descrittore Operativo: `skills/sdd-plan/SKILL.md`

```yaml
---
name: sdd-plan
description: |
  Compiles validated delta specifications into technical designs, ADRs, and bite-sized
  DAG implementation tasks. Sets up isolated Git Worktrees and runs independent plan audits.
  Use whenever a specification is ready for technical breakdown. Trigger with "/sdd:plan".
allowed-tools: "Read,Write,Glob,Grep,Bash(git:*),Bash(python3:*),Bash(bash:*)"
version: 1.0.0
license: MIT
compatibility: "Universal Agent Skills (Claude Code, OpenAI Codex, OpenCode)"
metadata:
  workflow: spec-driven-development
  phase: technical-planning
---

# SDD Technical Planning and Task Decomposition Engine

## Procedura Operativa Vincolante

1. **Precondizioni di Ingresso e Caricamento Contesto**
   - Rilevare la specifica approvata in `changes/{CHG_ID}/delta-spec.md` e verificare la presenza della costituzione in `.spec-framework/constitution.md`.
   - Se la specifica è incompleta o non contiene criteri di accettazione formulati in sintassi strutturata, bloccare il flusso e richiedere la finalizzazione della fase di specificazione.

2. **Esplorazione Topologica e Definizione dei Confini**
   - Eseguire l'ispezione della base di codice (`Glob`, `Grep`) per identificare moduli, classi e contratti interessati dalla modifica.
   - Redigere la sezione "File Modification Matrix" in `changes/{CHG_ID}/design.md`, categorizzando in modo tassativo ciascun file coinvolto con operazione (Create, Modify) e responsabilità architetturale.

3. **Predisposizione dell'Isolamento del Workspace**
   - Eseguire lo script deterministico per la creazione dell'area di lavoro isolata:
     `bash .spec-framework/bin/worktree_manager.sh create {CHG_ID}`
   - Verificare che il Git Worktree sia stato montato sul branch `feature/{CHG_ID}` e che la baseline dei test sia verde prima di procedere.

4. **Registrazione delle Scelte Architetturali (ADR)**
   - Per ciascun bivio implementativo, inserire un Architecture Decision Record sintetico in `design.md`.
   - Se emerge un'incertezza su requisiti o su trade-off sistemici, sospendere l'operazione e sottoporre il Decision Moment all'ingegnere umano; non assumere decisioni arbitrarie non documentate.

5. **Decomposizione in Micro-Task Atomici su Grafo (DAG)**
   - Suddividere il piano di implementazione in micro-task atomici (2-5 minuti di computazione ciascuno) nel file `changes/{CHG_ID}/tasks.md`.
   - Ciascun task deve specificare obbligatoriamente: ID, stadio del DAG (0, 1, 2 o 3), AC associati, `Allowed Paths` (massimo due file di logica), `Forbidden Paths` e sequenza TDD applicabile.
   - Vietare espressioni indeterminate o placeholder nel codice.

6. **Validazione Formale e Audit Indipendente di Pre-Esecuzione**
   - Eseguire il controllo sintattico e di coerenza tramite lo script di validazione:
     `python3 .spec-framework/bin/validate_plan.py changes/{CHG_ID}`
   - Invocare un sub-agente revisore indipendente allocato con contesto isolato (`context: fork`), trasmettendogli esclusivamente la specifica e il piano generato.
   - Se il revisore segnala lacune di copertura, assenza di casi di errore o ambiguità di tipo, applicare i correttivi necessari fino all'ottenimento della conformità formale.

7. **Checkpoint di Autorizzazione Umana**
   - Presentare allo sviluppatore il quadro di sintesi: matrice dei file modificati, DAG delle dipendenze, numero di task pianificati e path del worktree predisposto.
   - Arrestare l'esecuzione in attesa dell'approvazione esplicita prima di rilasciare i task alla fase di esecuzione TDD.
```

---

## Conclusioni

L'integrazione di un'architettura formale per la fase di technical design e task decomposition trasforma l'uso degli agenti di intelligenza artificiale da interazioni esplorative a processi governabili dell'ingegneria del software [cite: 2, 3, 14].

Abbandonando la stesura di piani monolitici prolissi a favore di un'indicizzazione strutturata con micro-task atomici confinati tra due e cinque minuti di esecuzione, si elimina il rischio di degrado prestazionale causato dalla saturazione della memoria contestuale [cite: 4, 5, 20]. L'adozione di grafi aciclici diretti (DAG) unita all'isolamento fisico tramite Git Worktrees assicura che lo sviluppo proceda per strati architetturali verificabili, proteggendo il ramo di sviluppo primario e abilitando l'esecuzione parallela [cite: 4, 6, 14].

Infine, la presenza di vincoli programmatici sui file modificabili (Negative Space) e l'impiego sistematico di sub-agenti revisori indipendenti a contesto pulito garantiscono la tracciabilità biunivoca tra requisiti e codice [cite: 4, 7, 10, 29]. L'intero ciclo assicura che ogni singola riga di codice generata trovi riscontro nella specifica approvata, consolidando un modello di sviluppo spec-driven efficiente, deterministico e sostenibile su basi di codice complesse [cite: 2, 3, 14].
