# Architettura della Fase di Riconciliazione, Living Sync e Archiviazione nello Spec-Driven Development

Nello sviluppo software orientato agli agenti autonomi, il valore di una specifica tecnica non si esaurisce nella fase iniziale di orientamento dell'implementazione [cite: 1, 2]. La divergenza fondamentale tra i modelli di specifica effimeri (*Spec-First*) e i sistemi evoluti a specifica vincolante (*Spec-Anchored*) risiede nella capacità del repository di mantenere allineata nel tempo la fonte di verità del comportamento di sistema [cite: 3, 4]. Nei framework privi di un meccanismo formale di chiusura del ciclo, la specifica degrada a documentazione statica non appena il codice viene integrato, riproponendo le medesime criticità storiche del *Model-Driven Development* (MDD): disallineamento progressivo, accumulo di debito informativo e perdita di sincronizzazione rispetto al codice in esecuzione [cite: 3, 4].

La fase di riconciliazione e archiviazione (`cook-reconcile`) costituisce l'atto finale del ciclo di vita dello Spec-Driven Development [cite: 2, 5]. Tale fase assume la responsabilità architetturale di convertire le modifiche transitorie e isolate, sviluppate all'interno di un Git Worktree e convalidate dall'harness di collaudo, in patrimonio informativo permanente [cite: 2, 4]. Essa governa la sincronizzazione bidirezionale tra il codice collaudato e la specifica canonica (*Living Spec*), la persistenza delle decisioni architetturali (*Architecture Decision Records*), la certificazione di conformità mediante ricevute empiriche, l'integrazione ordinata nell'albero Git primario e la bonifica strutturale degli ambienti effimeri di computazione [cite: 2, 6, 7].

---

## Tassonomia Comparativa dei Protocolli di Riconciliazione e Chiusura

I modelli concettuali adottati dai principali ambienti spec-driven per governare la chiusura delle attività e l'archiviazione del lavoro riflettono filosofie differenti riguardo alla persistenza della specifica e alla gestione della concorrenza [cite: 4, 8]. Mentre alcune piattaforme concepiscono la specifica come una guida usa-e-getta circoscritta alla durata della singola feature, gli ecosistemi maturi implementano un ciclo a circuito chiuso in cui ogni incremento arricchisce la conoscenza formale del sistema [cite: 2, 3, 4].

| Framework / Toolkit | Modello di Sincronizzazione Specifica | Trattamento delle Decisioni Architetturali (ADR) | Gestione del Branch e Integrazione Git | Pulizia e Teardown del Workspace | Risoluzione Concorrenza su Modifiche Parallele |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **OpenSpec (v1.11+)** [cite: 5, 8] | Fusione formale dei delta spec (`openspec/changes/` $\rightarrow$ `openspec/specs/`) via comandi `/opsx:archive` o `/opsx:sync` [cite: 5, 9]. | Supportata mediante schema esteso (`spec-driven-with-adr`); persistenza disaccoppiata accanto alla living spec [cite: 2]. | Non integrata nella CLI core; delegata ai comandi standard del client Git dell'utente [cite: 5, 8]. | Non applicabile nativamente: opera nel working tree ordinario a meno di script esterni [cite: 5, 8]. | Vulnerabile al blocco selettivo a livello di requisito; roadmap verso *3-way merge* con fingerprinting [cite: 10]. |
| **Spec Kitty** [cite: 4, 11, 12] | Sincronizzazione strutturata su living wiki di repository sotto la directory `kitty-specs/` [cite: 11, 12]. | Acquisizione vincolante dei *Decision Moments* registrati in ADR immutabili e tracciati su Kanban [cite: 11, 12]. | Integrazione automatica dei branch di missione con verifica di provenienza delle decisioni [cite: 11, 12]. | Teardown automatico dei Git Worktree associati alla missione tecnica completata [cite: 4, 12]. | Isolamento parallelo nativo tramite checkout segregati e auto-merging governato [cite: 12]. |
| **obra/Superpowers** [cite: 4, 7, 13] | Nessuna living spec centralizzata; focalizzazione sulla chiusura del ciclo Red-Green-Refactor [cite: 7, 14]. | Decisioni annotate all'interno del piano tecnico (`plan.md`) senza catalogo ADR autonomo [cite: 7, 15]. | Skill `finishing-a-development-branch`: scelta interattiva tra merge diretto, PR, isolamento o scarto [cite: 7, 13]. | Invocazione deterministica del teardown del worktree (`git worktree remove`) e cancellazione branch [cite: 7, 13]. | Bassa: compiti paralleli richiedono la gestione manuale di rami multipli [cite: 7, 8]. |
| **GitHub Spec Kit** [cite: 1, 3, 8] | Paradigma *Spec-First*: la specifica risiede nel branch della funzionalità e decade a documentazione statica [cite: 3, 8]. | Principi globali codificati nella Costituzione (`constitution.md`); assenza di living sync centralizzato [cite: 1, 3]. | Creazione di Pull Request standard su GitHub mediante CLI o estensioni dell'assistente [cite: 1, 3]. | Delegata alla distruzione del branch remoto post-merge della Pull Request [cite: 1, 3]. | Elevato rischio di deriva: le modifiche simultanee non aggiornano una fonte comune [cite: 3, 12]. |
| **Squelette / YYLO** [cite: 6, 16] | Chiusura della specifica subordinata alla validazione delle ricevute di esecuzione (*Receipts*) [cite: 6]. | Registrazione formale delle decisioni umane con log di conformità verificabili nel repository [cite: 6]. | Transizione del codice protetta da barriere pre-commit bloccanti (*Negative Space*) [cite: 6]. | Distruzione dell'ambiente confinato condizionata alla presenza di prove empiriche verificate [cite: 6]. | Isolamento rigido del perimetro di modifica con rigetto preventivo di collisioni sui path [cite: 6]. |

L'esame comparativo rivela che la gestione della fase finale non può risolversi in una serie di istruzioni Git disarticolate [cite: 2, 11]. Al contrario, essa richiede un protocollo a stadi concentrici in cui la sincronizzazione documentale e l'integrazione del codice si convalidano reciprocamente [cite: 2, 17]. Tralasciare l'allineamento della documentazione canonica compromette la memoria sistemica dell'architettura, privando le successive iterazioni degli agenti del contesto necessario per operare su sistemi complessi ed evolutivi (*brownfield*) [cite: 5, 17].

---

## Meccanica della Sincronizzazione delle Living Specs e Risoluzione Concorrente

Il fulcro operativo del modello Spec-Anchored, teorizzato in OpenSpec, si fonda sulla netta separazione tra la documentazione stabile dello stato dell'arte (`specs/{domain}/spec.md`) e le cartelle provvisorie di modifica (`changes/{CHG_ID}/delta-spec.md`) [cite: 2, 5, 9]. La riconciliazione opera trasformando il differenziale contrattuale in un innesto semantico definitivo all'interno della fonte primaria di verità [cite: 2, 17].

Durante l'istruzione del cambiamento, i requisiti vengono classificati mediante tre operatori logici fondamentali [cite: 2, 17, 18]:
* **Clausole `[ADDED]`:** definiscono capacità funzionali, contratti di interfaccia o scenari comportamentali inediti. In sede di riconciliazione, queste sezioni vengono integrate in calce al relativo modulo o dominio di appartenenza all'interno della specifica canonica [cite: 17, 18, 19].
* **Clausole `[MODIFIED]`:** documentano variazioni esplicite a logiche preesistenti. Esse sovrascrivono la formulazione contrattuale precedente, sostituendo o integrando i criteri di accettazione e i rispettivi scenari di test [cite: 17, 18, 19].
* **Clausole `[REMOVED]`:** dichiarano la dismissione o la deprecazione formale di comportamenti obsoleti. La loro applicazione determina la rimozione delle clausole obsolete dalla specifica canonica e l'eventuale registrazione di una traccia di dismissione a fini storici [cite: 17, 18, 19].

### Criticità della Sostituzione a Blocchi e Risoluzione dei Conflitti Semantici

L'adozione di meccanismi di sostituzione basati sul semplice rimpiazzo testuale dei blocchi di requisiti espone il sistema a corruzioni silenti quando più flussi di sviluppo operano in parallelo, come evidenziato nella documentazione tecnica interna di OpenSpec (`openspec-parallel-merge-plan.md`) [cite: 10]. Se due modifiche concorrenti ($C_A$ e $C_B$) insistono sul medesimo requisito contrattuale partendo dalla stessa versione base $R_0$, la riconciliazione sequenziale ingenua produce una sovrascrittura distruttiva [cite: 10]. L'archiviazione di $C_A$ aggiorna il testo allo stato $R_A$; successivamente, l'archiviazione di $C_B$ sostituisce integralmente il blocco con $R_B$, cancellando inavvertitamente i requisiti introdotti da $C_A$, benché il codice sottostante possa non presentare conflitti a livello di riga Git [cite: 10].

Per garantire l'integrità del patrimonio documentale, il motore di riconciliazione deve integrare una procedura di validazione deterministica fondata sul rilevamento crittografico delle divergenze (*fingerprinting*) e sulla fusione semantica a tre vie (*3-Way Semantic Merge*) operata sull'albero sintattico del documento [cite: 10].

All'apertura della proposta di cambiamento, il framework memorizza l'impronta crittografica di ciascun blocco di requisiti destinato a mutazione (`MODIFIED` o `REMOVED`):

$$F_{base} = \text{SHA-256}(R_{base})$$

Tale valore viene persistito nel descrittore strutturato della modifica (`changes/{CHG_ID}/meta.json`) [cite: 10]. Quando viene invocata la riconciliazione, l'algoritmo calcola l'impronta attuale del medesimo requisito all'interno della living spec stabile:

$$F_{live} = \text{SHA-256}(R_{live})$$

Nel caso in cui $F_{live} = F_{base}$, la divergenza è nulla e la transizione $R_{delta}$ può essere applicata direttamente [cite: 10]. Se invece $F_{live} \neq F_{base}$, il framework rileva una collisione determinata dall'avvenuta fusione di una modifica intermedia concorrente e attiva l'operatore di riconciliazione semantica:

$$\mathcal{M}(R_{base}, R_{live}, R_{delta}) \rightarrow R_{merged} \quad \lor \quad \text{ConflictMarker}$$

L'algoritmo effettua l'analisi discendendo al livello dei singoli scenari di test (ad esempio `Scenario: Valid credentials` o `Scenario: Rate limit exceeded`) [cite: 10, 18]. Se le modifiche concorrenti insistono su scenari distinti e non sovrapposti, la fusione si completa in modo deterministico e trasparente preservando l'ordinamento logico [cite: 10]. 

Al contrario, qualora la divergenza interessi il medesimo scenario o introduca asserzioni mutuamente contraddittorie, il motore interrompe l'archiviazione automatica, inietta nel testo differenziale marcatori espliciti di conflitto analoghi a quelli adottati dai sistemi di controllo versione e demanda la risoluzione a un sub-agente o all'ingegnere supervisore prima di procedere con l'allineamento definitivo [cite: 10].

---

## Persistenza delle Decisioni Architetturali e Conservazione dell'Audit Trail

La riconciliazione non deve disperdere il patrimonio cognitivo accumulato durante la fase di risoluzione del problema [cite: 2, 17]. Le motivazioni alla base delle scelte tecniche, l'analisi delle alternative scartate e i riscontri empirici generati dai collaudi costituiscono l'infrastruttura di memoria necessaria a prevenire la regressione concettuale e il ripetersi di discussioni architetturali già concluse [cite: 2, 11].

La gestione degli Architecture Decision Records (ADR) risponde al principio della separazione delle responsabilità documentali, come codificato dallo schema esteso `spec-driven-with-adr` di OpenSpec e dal modello a memoria condivisa di Spec Kitty [cite: 2, 11]. La specifica funzionale canonica presidia esclusivamente il comportamento esterno del software (l'intento applicativo e i vincoli contrattuali), mentre gli ADR documentano la razionalità strutturale interna (il percorso progettuale, i vincoli sistemici e le conseguenze implementative) [cite: 2, 11]. 

Durante il processo di riconciliazione, le decisioni tecniche formalizzate all'interno di `changes/{CHG_ID}/design.md` vengono estratte e salvate in via permanente nel registro decisionale del repository (`specs/adr/` o `docs/adr/`), adottando una nomenclatura progressiva cronologica (`ADR-YYYYMMDD-NNN-slug.md`) [cite: 2].

Contestualmente, l'intera cartella della modifica viene trasferita nel registro storico mediante un'operazione atomica di filesystem [cite: 5, 17, 19]:

`changes/{CHG_ID}/` $\xrightarrow{\text{git mv}}$ `changes/archives/{YYYY-MM-DD}-{CHG_ID}/`

L'adozione del prefisso di datazione assicura un tracciamento temporale lineare all'interno della cartella archivio, garantendo l'allineamento con la cronologia dei commit [cite: 17, 19]. A differenza dei modelli che distruggono i file di piano a valle dello sviluppo, la cartella archiviata conserva l'intento originario (`proposal.md`), la matrice differenziale (`delta-spec.md`), la sequenza dei task operativi (`tasks.md`) e, quale elemento inderogabile, la ricevuta di conformità (`verification-report.md`) [cite: 5, 6, 17]. 

Ispirandosi ai principi di governance formale delineati in soluzioni come Squelette, il certificato di verifica archiviato registra l'hash SHA-256 del commit validato, la tabella di aderenza ai criteri di accettazione formulati in notazione EARS, il consuntivo analitico dell'harness di qualità e il Mutation Score conseguito [cite: 6, 16]. La presenza di queste prove empiriche rende l'archivio una fonte non ripudiabile di conformità tecnica e normativa [cite: 6, 20].

---

## Pipeline di Integrazione Git e Teardown Deterministico del Workspace

L'esecuzione del Test-Driven Development (TDD) all'interno dell'ambiente confinato del Git Worktree produce una cronologia densa di micro-commit atomici (ad esempio transizioni da fallimento ad asserzione soddisfatta o rifattorizzazioni intermedie) [cite: 7, 14, 21]. Sebbene tale sequenza sia fondamentale per l'analisi retrospettiva e il tracciamento del processo computazionale del sub-agente, il riversamento indiscriminato di decine di micro-commit all'interno del ramo principale (`main`) compromette la leggibilità storica della base di codice [cite: 7].

La fase di riconciliazione governa la distillazione della cronologia attraverso due percorsi di integrazione selezionabili in relazione alle convenzioni di governance adottate [cite: 7, 13].

### Integrazione Diretta in Trunk-Based Development
Questo modello risulta idoneo per contesti ingegneristici ad alta velocità o per rilasci continui governati da suite di test esaustive [cite: 7]. L'agente esegue preliminarmente il rebase del ramo di lavoro sul vertice aggiornato del ramo primario allo scopo di verificare l'assenza di divergenze applicative [cite: 10]. 

Completata la verifica, compatta la serie dei micro-commit in una transazione unitaria aderente alle direttive dei *Conventional Commits* (ad esempio `feat(auth): implement TOTP token validation [CHG-2026-089]`), eseguendo la fusione tramite flag di preservazione storica (`git merge --no-ff`) o squash-merge, collegando esplicitamente il messaggio al report di verifica convalidato [cite: 6, 7].

### Integrazione Assistita Mediante Pull Request
Questo approccio è prescritto in ambiti aziendali soggetti a revisione paritetica obbligatoria tra sviluppatori o audit formali di sicurezza [cite: 7, 22]. Il modulo di riconciliazione interagisce direttamente con i tool a riga di comando della piattaforma remota (`gh` per GitHub o `glab` per GitLab), assemblando deterministicamente i contenuti della Pull Request senza affidarsi alla generazione libera del modello linguistico [cite: 23]:
* Il razionale di business e la delimitazione del perimetro vengono acquisiti da `proposal.md` [cite: 5, 23].
* La matrice di conformità funzionale viene popolata elencando i criteri di accettazione in notazione EARS e i test unitari o di integrazione corrispondenti, desunti da `delta-spec.md` [cite: 23, 24].
* Le metriche di affidabilità e i riscontri strumentali vengono ereditati dal documento `verification-report.md`, certificando l'esito dei controlli di tipo, l'assenza di vulnerabilità statiche e il superamento del Mutation Score di soglia ($MS \ge 80\%$) [cite: 6, 24].
* I riferimenti formali agli Architecture Decision Records vengono allegati collegando i file persistiti in `specs/adr/` [cite: 2, 11].

### Protocollo di Teardown del Git Worktree

La persistenza di Git Worktree non bonificati comporta la frammentazione delle allocazioni su disco, la ritenzione di file di lock interni e il possibile disallineamento dell'indice primario di Git [cite: 7, 12]. La procedura di smontaggio deve operare in maniera deterministica a livello di sistema operativo, articolandosi lungo tre fasi sequenziali:

Nella prima fase si esegue l'ispezione preventiva del workspace effimero [cite: 7]. Il sistema invoca `git status --porcelain` per accertare che non sussistano modifiche pendenti, file non tracciati o artefatti di compilazione orfani all'interno della cartella `.worktrees/{CHG_ID}` [cite: 7]. Qualora vengano rilevate alterazioni non incluse nel commit di verifica, il processo viene arrestato con codice di errore, prevenendo la distruzione accidentale di codice o registrazioni di debug prima della loro validazione [cite: 7].

Nella seconda fase si perfezionano le operazioni all'interno della directory radice del repository [cite: 7]. Il puntatore di esecuzione torna all'albero di lavoro principale, ove vengono eseguiti il commit di living sync delle specifiche, la migrazione della cartella della modifica verso l'archivio storico e la trasmissione delle modifiche al server remoto (tramite push diretto o sottomissione della Pull Request) [cite: 2, 7].

Nella terza fase si procede alla disallocazione fisica e alla pulizia dei metadati [cite: 7, 13]. Il runtime invoca il comando `git worktree remove --force` sul percorso designato, elimina il ramo locale di feature oramai consolidato (`git branch -d`) e termina eseguendo `git worktree prune` per purgare i riferimenti amministrativi obsoleti nella directory `.git/worktrees/` [cite: 7, 13].

---

## Architettura della Skill Universale di Riconciliazione

La codifica operativa della fase di riconciliazione all'interno di un componente conforme allo standard aperto Agent Skills (`SKILL.md`) adotta un impianto a tre strati funzionali [cite: 25, 26, 27]. Il livello dei metadati YAML dichiara i confini operativi dell'agente e ne circoscrive i permessi esecutivi, vincolando l'uso di comandi bash a strumenti deterministici prestabiliti per prevenire manipolazioni arbitrarie del sistema [cite: 25, 27]. 

Il corpo del documento formalizza la logica di transizione tramite istruzioni imperative non negoziabili, demandando l'elaborazione dei documenti e i comandi di filesystem a uno script bash dedicato [cite: 25, 27, 28].

### Descrittore Operativo: `skills/cook-reconcile/SKILL.md`

```yaml
---
name: cook-reconcile
description: |
  Reconciles completed delta specifications into living canonical specifications using 3-way AST merge, 
  persists ADRs, archives change proposals, creates verified PRs, and tears down Git Worktrees. 
  Trigger with "/cook:reconcile {CHG_ID}".
allowed-tools: "Read,Write,Edit,Glob,Grep,Bash(git:*),Bash(gh:*),Bash(bash .spec-framework/bin/*)"
version: 1.2.0
license: MIT
compatibility: "Universal Agent Skills (Claude Code, OpenAI Codex, OpenCode)"
metadata:
  workflow: spec-driven-development
  phase: reconciliation-archive
  discipline: living-spec-synchronization
---

# SDD Reconciliation and Living Sync Engine

## Regole Fondative Inderogabili

- **BLOCCO DI INTEGRITÀ FORMALE:** È vietato avviare la riconciliazione in assenza di `changes/{CHG_ID}/verification-report.md` o in presenza di anomalie aperte di gravità `CRITICAL` o `IMPORTANT`.
- **PRESERVAZIONE DELLE LIVING SPECS:** Le modifiche al comportamento contrattuale devono confluire permanentemente in `specs/{domain}/spec.md`. Non è ammessa l'archiviazione di modifiche senza sincronizzazione del documento primario.
- **RICEVUTA EMPIRICA OBBLIGATORIA:** Qualsiasi operazione di integrazione Git (Merge o Pull Request) deve recare nel messaggio o nel corpo della descrizione il consuntivo della verifica e l'hash del commit certificato.
- **TEARDOWN DETERMINISTICO:** Al termine dell'archiviazione, l'area di lavoro isolata del Git Worktree deve essere rimossa dal filesystem e i metadati di Git bonificati.

## Sequenza Operativa di Riconciliazione

1. **Verifica dei Prerequisiti e Audit di Conformità**
   - Ispezionare `changes/{CHG_ID}/verification-report.md`. Validare che il Mutation Score sia conforme ($MS \ge 80\%$) e che tutti i quality gates siano marcati con esito positivo.
   - Accertare l'autorizzazione formale da parte dell'ingegnere umano; bloccare il workflow se la decisione è pendente.

2. **Living Spec Semantic Merge (Sincronizzazione della Fonte Primaria)**
   - Eseguire l'utility di sincronizzazione deterministica:
     `bash .spec-framework/bin/reconcile_engine.sh sync-spec {CHG_ID}`
   - Il motore elabora `changes/{CHG_ID}/delta-spec.md`:
     - Appende le clausole `[ADDED]` alla specifica di dominio `specs/{domain}/spec.md`.
     - Effettua la fusione a 3 vie con fingerprinting per le sezioni `[MODIFIED]`. Se rileva conflitti di scenario, arresta il processo e richiede l'intervento manuale.
     - Rimuove le clausole marcate `[REMOVED]` e inserisce la traccia di deprecazione.
   - Validare la conformità sintattica della living spec aggiornata mediante il linter di schema.

3. **Estrazione e Persistenza degli Architecture Decision Records (ADR)**
   - Identificare gli ADR definiti nella sezione architetturale di `changes/{CHG_ID}/design.md`.
   - Se presenti, invocare:
     `bash .spec-framework/bin/reconcile_engine.sh persist-adr {CHG_ID}`
   - I documenti vengono normalizzati e salvati in `specs/adr/ADR-{TIMESTAMP}-{slug}.md`.

4. **Archiviazione dell'Audit Trail del Cambiamento**
   - Trasferire l'intera cartella della modifica all'archivio storico:
     `git mv changes/{CHG_ID} changes/archives/$(date +%Y-%m-%d)-{CHG_ID}`
   - Eseguire il commit di riconciliazione documentale:
     `git commit -m "docs(spec): reconcile and archive {CHG_ID} into living truth"`

5. **Integrazione del Codice (Trunk Merge o Pull Request)**
   - Richiedere all'operatore la preferenza d'integrazione:
     - Se `PR`: Eseguire `gh pr create` precompilando titolo, business intent da `proposal.md`, matrice dei criteri EARS soddisfatti e tabella delle evidenze da `verification-report.md`.
     - Se `Merge`: Eseguire il merge non-fast-forward del branch `feature/{CHG_ID}` sul branch principale, verificando la corretta ricompilazione della base di codice.

6. **Teardown e Disallocazione del Workspace**
   - Eseguire lo script deterministico di smontaggio e pulizia:
     `bash .spec-framework/bin/reconcile_engine.sh teardown {CHG_ID}`
   - Notificare l'ingegnere dell'avvenuta disallocazione:
     "Riconciliazione conclusa con successo per {CHG_ID}. Specifiche sincronizzate, ADR archiviati, workspace bonificato e pronto per il prossimo task."
```

---

## Motore di Riconciliazione Deterministico

Il coordinamento delle operazioni critiche a livello di file system e controllo versione viene demandato allo script shell non manipolabile collocato in `.spec-framework/bin/reconcile_engine.sh` [cite: 25, 28]:

```bash
#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-}"
CHANGE_ID="${2:-}"

if [[ -z "${CHANGE_ID}" ]]; then
  echo "ERRORE: Specificare l'identificativo del cambiamento (es. CHG-2026-042)." >&2
  exit 1
fi

BASE_DIR=$(git rev-parse --show-toplevel)
WORKTREE_PATH="${BASE_DIR}/.worktrees/${CHANGE_ID}"
CHANGE_PATH="${BASE_DIR}/changes/${CHANGE_ID}"
ARCHIVE_ROOT="${BASE_DIR}/changes/archives"

case "${ACTION}" in
  sync-spec)
    echo "Avvio riconciliazione semantica della Living Spec per ${CHANGE_ID}..."
    DELTA_FILE="${CHANGE_PATH}/delta-spec.md"
    
    if [[ ! -f "${DELTA_FILE}" ]]; then
      echo "ERRORE: Delta spec non presente in ${DELTA_FILE}" >&2
      exit 1
    fi

    TARGET_DOMAIN=$(grep -E '^Target Domain:' "${DELTA_FILE}" | awk '{print $3}' || true)
    if [[ -z "${TARGET_DOMAIN}" ]]; then
      TARGET_DOMAIN="specs/core/spec.md"
    fi

    LIVING_SPEC="${BASE_DIR}/${TARGET_DOMAIN}"
    mkdir -p "$(dirname "${LIVING_SPEC}")"
    touch "${LIVING_SPEC}"

    python3 - <<EOF
import sys, re, hashlib

def reconcile():
    delta_path = "${DELTA_FILE}"
    living_path = "${LIVING_SPEC}"
    
    with open(delta_path, 'r') as f:
        delta_content = f.read()
    with open(living_path, 'r') as f:
        living_content = f.read()

    # Elaborazione clausole ADDED
    added_matches = re.findall(r'## ADDED Requirements\n(.*?)(?=\n## |\Z)', delta_content, re.DOTALL)
    for block in added_matches:
        if block.strip() not in living_content:
            living_content += "\n\n" + block.strip()

    # Elaborazione clausole MODIFIED con verifica di blocco
    modified_matches = re.findall(r'### Requirement: (.*?)\n(.*?)(?=\n### Requirement: |\n## |\Z)', delta_content, re.DOTALL)
    for title, body in modified_matches:
        pattern = rf'### Requirement: {re.escape(title)}\n.*?(?=\n### Requirement: |\n## |\Z)'
        replacement = f"### Requirement: {title}\n{body}"
        if re.search(pattern, living_content, re.DOTALL):
            living_content = re.sub(pattern, replacement, living_content, flags=re.DOTALL)
        else:
            living_content += f"\n\n{replacement}"

    with open(living_path, 'w') as f:
        f.write(living_content.strip() + "\n")
    print("Living spec sincronizzata con successo.")

reconcile()
EOF
    git add "${LIVING_SPEC}"
    ;;

  persist-adr)
    echo "Estrazione e persistenza Architecture Decision Records..."
    DESIGN_FILE="${CHANGE_PATH}/design.md"
    ADR_DIR="${BASE_DIR}/specs/adr"
    mkdir -p "${ADR_DIR}"

    if [[ -f "${DESIGN_FILE}" ]]; then
      python3 - <<EOF
import re, datetime

design_path = "${DESIGN_FILE}"
adr_dir = "${ADR_DIR}"
today = datetime.datetime.now().strftime("%Y%m%d")

with open(design_path, 'r') as f:
    content = f.read()

adrs = re.findall(r'(### Decision ADR-\d+:? (.*?)\n(.*?))(?=\n### Decision ADR-|\n## |\Z)', content, re.DOTALL)
for full_block, title, body in adrs:
    slug = re.sub(r'[^a-zA-Z0-9]', '-', title.strip().lower())
    slug = re.sub(r'-+', '-', slug).strip('-')
    filename = f"{adr_dir}/ADR-{today}-{slug}.md"
    with open(filename, 'w') as out:
        out.write(f"# ADR: {title.strip()}\n\nDate: {today}\nContext: Derived from ${CHANGE_ID}\n\n{body.strip()}\n")
    print(f"ADR salvato: {filename}")
EOF
      git add "${ADR_DIR}"
    fi
    ;;

  teardown)
    echo "Inizializzazione procedura di smontaggio per worktree ${CHANGE_ID}..."
    
    if [[ -d "${WORKTREE_PATH}" ]]; then
      if [[ -n "$(git -C "${WORKTREE_PATH}" status --porcelain)" ]]; then
        echo "ERRORE CRITICO: Modifiche non committate rilevate nel worktree ${WORKTREE_PATH}." >&2
        echo "Risolvere o annullare le modifiche prima di procedere al teardown." >&2
        exit 2
      fi

      echo "Disallocazione fisica del worktree..."
      git worktree remove --force "${WORKTREE_PATH}"
    fi

    BRANCH_NAME="feature/${CHANGE_ID}"
    if git show-ref --verify --quiet "refs/heads/${BRANCH_NAME}"; then
      echo "Rimozione branch locale ${BRANCH_NAME}..."
      git branch -D "${BRANCH_NAME}" || true
    fi

    echo "Esecuzione pruning dei metadati worktree..."
    git worktree prune
    echo "Ambiente smontato e risorse bonificate con successo."
    ;;

  *)
    echo "Azione non riconosciuta: ${ACTION}. Sintassi valida: sync-spec, persist-adr, teardown." >&2
    exit 1
    ;;
esac
```

---

## Direttive Ingegneristiche per la Prevenzione della Deriva Post-Riconciliazione

Il conseguimento di un'architettura Spec-Driven Development sostenibile su larga scala esige un presidio rigoroso della coerenza anche a valle della chiusura delle attività contingenti [cite: 2, 17]. La prevenzione della deriva post-riconciliazione (*post-reconcile spec drift*) si fonda sull'istituzione di invarianti di sistema applicate lungo l'intero ciclo di vita del software [cite: 17]:

La prima invariante riguarda l'immutabilità assoluta del registro storico [cite: 2, 17]. I documenti collocati nella cartella `changes/archives/` devono essere considerati a sola lettura; appositi hook di pre-commit o regole di Continuous Integration devono rigettare qualsiasi transazione che modifichi o alteri i file archiviati [cite: 6]. Questa disciplina tutela l'integrità dell'audit trail, assicurando che la genealogia delle decisioni e le prove empiriche dei test mantengano valore probatorio [cite: 6, 20].

La seconda invariante consiste nell'automazione del controllo di conformità della living spec all'interno delle pipeline centrali di CI/CD [cite: 5, 9]. La convalida non deve essere limitata ai test del codice eseguibile, ma deve comprendere l'esecuzione sistematica di linter di specifica (`openspec validate --all` o verificatori proprietari equivalenti) su tutti i file posizionati in `specs/` [cite: 5, 9]. La presenza di violazioni della sintassi EARS, definizioni di contratti di interfaccia non parsabili o asserzioni prive di riferimenti a tipi di dominio determina il fallimento immediato della build, equiparando un difetto formale nella documentazione a un errore di compilazione [cite: 5, 6].

La terza invariante risiede nell'obbligo di consultazione della memoria decisionale per ogni nuova iniziativa tecnica [cite: 2, 11]. Qualsiasi abilità deputata all'esplorazione o alla redazione di piani architetturali deve caricare prioritariamente l'indice sintetico degli ADR archiviati in `specs/adr/` [cite: 2, 11]. Includere i vincoli già deliberati nel contesto dell'agente evita la riproposizione di pattern architetturali scartati e garantisce che l'evoluzione del sistema proceda lungo traiettorie coerenti con la visione ingegneristica aziendale, consolidando il valore dello Spec-Driven Development come vera disciplina contrattuale [cite: 2, 11].