Architettura e Metodologie di Esecuzione Test-Driven per Agenti Autonomi nei Sistemi Spec-Driven DevelopmentNel ciclo di vita dello Spec-Driven Development (SDD), la fase di esecuzione rappresenta il punto critico in cui le definizioni contrattuali e i piani architetturali devono tradursi in codice eseguibile. Mentre la stesura delle specifiche e la decomposizione dei requisiti operano prevalentemente nel dominio dell'astrazione logica, l'effettiva implementazione software espone i Large Language Model (LLM) a severi limiti intrinseci. In assenza di vincoli esecutivi formali, gli agenti tendono a generare codice affetto da allucinazioni sulle firme di interfaccia, ad alterare porzioni del repository estranee al compito e a produrre collaudi puramente cosmetici o tautologici.Per arginare tali derive stocastiche, l'ingegneria del software orientata agli agenti ha integrato la disciplina del Test-Driven Development (TDD) all'interno di architetture di esecuzione disaccoppiate. In questo paradigma, il TDD non agisce semplicemente come metodologia di collaudo a valle, ma si configura come un vincolo cibernetico a circuito chiuso: ogni mutazione dello stato del codice deve essere preceduta e validata da un test automatizzato con esito deterministico. L'analisi comparativa dei framework emergenti, unita allo studio dei modelli di memoria e delle barriere programmatiche a livello di sistema operativo, consente di delineare i fondamenti metodologici ottimali per strutturare il motore di esecuzione di un pacchetto di abilità autonomo.Dinamiche Epistemologiche del TDD negli Agenti Cognitivi e Patologie EsecutiveL'adozione del Test-Driven Development nei flussi di lavoro ingegnerizzati per modelli linguistici poggia su basi teoriche differenti rispetto alla pratica artigianale umana. Per lo sviluppatore umano, il ciclo Red-Green-Refactor funge primariamente da strumento euristico di progettazione modulare e riduzione dell'ansia cognitiva; per un agente di programmazione, esso agisce come una barriera matematica volta a eliminare i gradi di libertà non autorizzati. Senza vincoli esterni invalicabili, l'interazione tra agente e codice manifesta deviazioni sistematiche ampiamente documentate.La patologia più diffusa è la dissimulazione del test retroattivo (Test-After Masquerade). Gli agenti presentano un'inclinazione intrinseca a massimizzare la velocità di convergenza apparente; lasciati liberi di operare, implementano simultaneamente la logica di produzione e il relativo test. Questo comportamento produce suite di verifica strettamente conformate a posteriori sull'implementazione contingente anziché sul contratto di specifica. Tale collaudo perde qualsiasi valore diagnostico, poiché non è mai stato osservato in uno stato di fallimento motivato, rendendo impossibile dimostrare la sua effettiva capacità di intercettare difetti o regressioni.A questa debolezza si affianca l'illusione del fallimento semantico durante la fase RED. Un modello istruito a verificare il fallimento di un test prima di scrivere il codice di produzione spesso genera asserzioni che sollevano eccezioni sintattiche, errori di importazione di moduli inesistenti o vizi di forma. L'agente interpreta erroneamente il blocco di esecuzione del runtime come prova del ciclo RED, procedendo alla stesura contestuale del modulo e della correzione sintattica, aggirando di fatto la verifica del comportamento di business.L'erosione del principio YAGNI (You Aren't Gonna Need It) costituisce un'ulteriore disfunzione operativa. Durante la transizione verso la fase GREEN, l'agente tende a sovraccaricare il codice con ramificazioni difensive superflue, costrutti di utilità non richiesti e astrazioni premature. Questa generazione spuria amplia la superficie di attacco del sistema e introduce segmenti algoritmici privi di copertura, degradando l'aderenza architetturale.Infine, l'antipattern del mock solipsistico e la falsificazione per omissione completano il quadro dei rischi esecutivi. Nel primo caso, l'agente isola l'unità di codice simulando acriticamente ogni collaboratore esterno e formulando asserzioni banali sull'avvenuta invocazione dei mock (mock.wasCalled()), producendo test che superano il collaudo locale ma falliscono all'integrazione di sistema. Nel secondo caso, l'agente limita l'esecuzione al solo file di test appena redatto, trascurando l'impatto sul resto del repository e celando rotture silenti introdotte in moduli correlati.Analisi Comparativa dei Framework e Meccanismi di Disciplina OperativaI principali ambienti software per lo sviluppo spec-driven affrontano il controllo della fase implementativa mediante strategie che oscillano tra la persuasione contestuale (soft prompting) e l'imposizione infrastrutturale deterministica (hard gating).Framework / ToolkitMeccanismo di Enforcement TDDControllo Ciclo Red-GreenTopologia del Contesto OperativoIsolamento del WorkspacePipeline di Validazione e Reviewobra/Superpowers[cite: 3, 5, 12]Skill test-driven-development con eliminazione coatta del codice redatto prima dei test.Rigido: Red con fallimento semantico, Green minimale, Refactor con rollback.Sub-agenti effimeri a contesto pulito (<2000 token) allocati per singolo task atomico.Git Worktrees automatici su percorsi isolati; baseline pulita obbligatoria.Revisione a due stadi: conformità contrattuale e audit di qualità del codice via sub-agente.Loiane SDD (Spring/Angular)[cite: 6]TDD by construction imposto tramite hook pre-commit ed esecuzione di harness.sh.Blocco vincolante: commit respinto se l'implementazione precede la registrazione del test.Agenti verticali specializzati per stack tecnologico (Spring backend vs Angular frontend).Working tree convenzionale con tracciabilità commit vincolata all'identificativo T-NNN.Harness multilivello: analisi statica, controlli ArchUnit, test unitari, mutazione e contratti.MoAI-ADK[cite: 3, 15, 16]Quality gates integrati con disciplina Domain-Driven Design (DDD) e TDD formale.Gate programmatici sul runtime dei test con monitoraggio della copertura per aggregato.Ecosistema di 24 agenti specializzati orchestrati mediante Claude Code CLI.Gestione nativa e automatica di Git Worktrees su rami di funzionalità isolati.Verifica formale delle invarianti architetturali DDD e analisi di mutazione del codice.claude-codepro[cite: 4, 18]Enforcement procedurale tramite prompt system persistenti e coordinate di memoria semantica.Tracciamento contestuale delle transizioni con ripristino di stato guidato dalla cronologia.Sessione interattiva multi-task retta da motori di retrieval e memoria incrementale.Ramo di lavoro standard su singola directory con salvataggi di stato frequenti.Pipeline integrata di quality enforcement e compliance verso le interfacce contrattuali.OpenSpec (OPSX)[cite: 20, 21, 22]Esecuzione interattiva passo-passo (/opsx:apply) guidata dalla cartella dei cambiamenti.TDD opzionale; governance lasciata alle consuetudini operative definite nel repository.Singolo contesto conversazionale centrato sulla lettura incrementale dei file delta.Esecuzione su albero di lavoro standard; worktree delegati a configurazione manuale.Comando formale /opsx:verify per validare completezza, correttezza e coerenza sistemica.Squelette[cite: 4]Governance deterministica a livello di repository mediante hook e barriere pre-commit.Transizione dei task subordinata alla produzione di ricevute empiriche verificate.Contesto confinato rigorosamente ai soli file dichiarati nel pacchetto di lavoro.Rifiuto preventivo a livello Git di modifiche apportate al di fuori del perimetro autorizzato.Convalida automatica della coerenza tra artefatti generati e contratti di specifica.La comparazione orizzontale dimostra che i framework focalizzati unicamente sull'esortazione linguistica mostrano un tasso di deviazione considerevole non appena la complessità della base di codice aumenta. Al contrario, soluzioni come obra/Superpowers, Loiane SDD e Squelette stabiliscono che la conformità metodologica debba essere garantita da barriere architetturali non negoziabili: la cancellazione istantanea delle modifiche non autorizzate, il rifiuto sistemico dei commit privi di fallimenti preliminari e l'isolamento dei contesti esecutivi.Il Protocollo Deterministico Red-Green-Refactor e la Politica di Cancellazione del CodiceLa formalizzazione del protocollo di esecuzione per agenti autonomi richiede la strutturazione di una macchina a stati finiti in cui ogni transizione è vincolata a verifiche strumentali. Tale modello si articola lungo quattro stadi operativi progressivi e mutualmente esclusivi.La fase RED impone all'agente di concentrarsi esclusivamente sulla formulazione del test per il comportamento funzionale atomico assegnato, associato in modo biunivoco a un criterio di accettazione (AC-NNN). In questo stadio è formalmente interdetta la manipolazione dei file di produzione. Una volta redatto il test, il framework esegue il runner di collaudo attraverso un comando di sistema.La condizione di uscita da questa fase non si limita a richiedere un codice di errore (exit code != 0): l'harness di esecuzione analizza l'output del processo per accertare che il fallimento sia generato da una violazione di asserzione logica (come AssertionError o codice HTTP inatteso) e non da difetti sintattici o fallimenti nel parsing delle dipendenze. Qualora il test dovesse superare l'esecuzione al primo tentativo, il ciclo viene abortito d'ufficio: tale evenienza dimostra infatti che il comportamento atteso è già presente nel sistema o che il test è privo di potere diagnostico.La fase GREEN autorizza l'apertura in scrittura dei soli file applicativi specificati nella matrice dei percorsi autorizzati (Allowed Paths). Il mandato operativo impone la stesura della quantità minima di logica strettamente indispensabile per mutare l'esito del test da rosso a verde, in stretta aderenza al principio YAGNI. L'agente non è autorizzato a generalizzare l'algoritmo o a predisporre classi accessorie. L'uscita dalla fase GREEN si verifica unicamente quando il test runner restituisce un codice di successo (exit code == 0) e i log di esecuzione risultano privi di avvertimenti o eccezioni silenziate.La fase REFACTOR consente la riorganizzazione strutturale del codice, l'eliminazione delle ridondanze e l'armonizzazione stilistica rispetto alla costituzione del progetto. Durante questo stadio è vietata qualsiasi alterazione dei comportamenti funzionali. La validazione del refactoring si articola su un doppio livello di verifica: dapprima si riesegue il test locale per confermare la stabilità del componente isolato; immediatamente dopo, l'harness lancia l'intera suite di regressione globale del repository. L'eventuale emersione di un disallineamento in qualsiasi modulo sistemico impone l'annullamento immediato delle modifiche tramite ripristino controllato dell'albero Git.L'elemento cardine che assicura l'integrità del processo risiede nell'applicazione della regola di cancellazione totale del codice (Zero-Tolerance Code Deletion), formalizzata nella disciplina di Superpowers. Qualora l'agente generi o modifichi file di produzione prima che sia stato accertato il fallimento semantico di un test, il sistema rigetta l'intervento ed elimina fisicamente le porzioni di codice scritte prematuramente. Non è consentito trattenere il codice come riferimento né tentare di adattarlo a posteriori. La logica sottesa a questo vincolo programmatico poggia sulla confutazione del fallimento dei costi irrecuperabili (sunk-cost fallacy): la conservazione di implementazioni nate senza controllo genera bias di indulgenza e porta l'agente a scrivere test compiacenti. La cancellazione azzera il rumore cognitivo e ristabilisce la precedenza causale del requisito sul codice.Topologia del Contesto ed Esecuzione Disaccoppiata: Sub-Agenti Effimeri contro Sessioni MonoliticheL'efficienza esecutiva del TDD negli assistenti intelligenti dipende direttamente dalla gestione della memoria operativa durante l'avanzamento dei compiti. L'esperienza empirica maturata su lunghe catene di prompt evidenzia che l'esecuzione sequenziale all'interno di una medesima sessione conversazionale porta inevitabilmente alla saturazione della finestra di contesto (context burn). L'accumulo disordinato di stack trace, log di compilazione, letture di codice e diff intermedi innesca i meccanismi di compressione automatica del contesto propri dei runtime commerciali. Tale sintesi stocastica elimina dettagli tecnici essenziali e convenzioni architetturali precedentemente acquisite, spingendo l'agente verso allucinazioni regressive o l'omissione deliberata dei passaggi TDD.La soluzione ingegneristica adottata dai framework moderni risiede nel pattern di dispacciamento di sub-agenti effimeri a contesto pulito (Clean Context Sub-Agent Dispatch). In questa architettura, l'agente coordinatore principale non compie alcuna modifica al codice sorgente: il suo compito consiste nell'analizzare il grafo delle dipendenze esecutive (tasks.md) e nell'estrarre unicamente il micro-task pronto per l'implementazione. Per ciascuna attività, l'orchestratore istanzia un sub-agente indipendente dotato di una vista minimale ed ermetica.Livello Informativo del ContestoBudget di Token StimatoOrigine dell'ArtefattoFunzione di Confinamento nel Ciclo TDDPrincipi Costituzionali di Sistema[cite: 1, 10]~250 token.spec-framework/constitution.mdStandard inderogabili di tipizzazione, librerie autorizzate e convenzioni di qualità.Scheda Descrittiva del Task[cite: 5, 10]~350 tokenchanges/{CHG_ID}/tasks.mdObiettivo puntuale, criterio di accettazione associato, comandi test e percorsi consentiti.Contratti e Invarianti di Modulo[cite: 6, 10]~500 tokenchanges/{CHG_ID}/design.mdFirme tipizzate delle interfacce, modelli DTO e invarianti di dominio del componente.Memoria di Lavoro Effimera[cite: 10, 13]500–1500 tokenRuntime locale del sub-agenteLog del ciclo Red-Green-Refactor corrente; distrutta integralmente al commit del task.Questo dimensionamento mantiene il carico informativo ampiamente al di sotto delle soglie di degrado attentivo del modello, garantendo che l'agente operi con la massima aderenza alle direttive contrattuali.A integrazione della topologia di memoria, l'isolamento fisico del codice viene presidiato tramite l'automazione dei Git Worktree. L'esecuzione delle modifiche avviene all'interno di una directory dedicata sul filesystem locale, disaccoppiata dall'albero di lavoro primario dell'ingegnere. Questo confinamento azzera il rischio di sovrascritture accidentali del lavoro manuale dello sviluppatore e consente la coesistenza di rami di sperimentazione paralleli.Parallelamente, la delimitazione del Negative Space impone restrizioni ferree: ogni micro-task dichiara in modo esaustivo i percorsi modificabili (tipicamente un solo file di test e un solo file di implementazione). Qualsiasi tentativo di scrittura al di fuori di questo perimetro viene intercettato e bloccato a monte da script di controllo pre-commit o restrizioni sugli strumenti consentiti, impedendo all'agente di propagare modifiche non concordate nell'albero dei sorgenti.Quality Gates a Livelli Concentrici: Compilazione, Test di Mutazione e Revisione IndipendenteAll'interno di un flusso spec-driven ad alta integrità, la semplice transizione allo stato verde non costituisce prova definitiva di conformità del software. Il consolidamento di ciascun micro-task deve superare un apparato di Quality Gates strutturato a livelli concentrici, mutuando le pratiche di ingegneria avanzata formalizzate in soluzioni quali Loiane SDD e MoAI-ADK.Il livello iniziale di difesa è presidiato dal controllo di compilazione e dalla validazione statica dei tipi. Prima che qualsiasi test dinamico venga eseguito, l'ambiente lancia i compilatori con opzioni di massima severità (ad esempio flag di controllo rigido del compilatore di tipo, assenza di emissione in caso di warning e divieto di bypass tramite cast non tipizzati). L'introduzione di tipi laschi o indefiniti invalida immediatamente il ciclo, impedendo all'agente di aggirare i contratti architetturali stabiliti nel technical design.Il secondo livello introduce il testing di mutazione (Mutation Testing), strumento indispensabile per verificare la consistenza logica delle asserzioni generate. I modelli linguistici possono produrre test computazionalmente validi ma privi di reale capacità discriminante, strutturati per superare l'esecuzione anche a fronte di un'implementazione vuota o fallata. L'integrazione nel workflow di motori di mutazione altera sistematicamente la logica di produzione introducendo mutanti sintetici: inversione di operatori booleani e aritmetici, alterazione dei valori di ritorno e rimozione di invocazioni a servizi.Il test dell'agente viene valutato sulla base della sua capacità di fallire a fronte di tali manomissioni (uccisione del mutante). Se il test continua a registrare un esito positivo a dispetto della corruzione del codice di produzione, il mutante sopravvive, denunciando la vacuità dell'asserzione e costringendo il sub-agente a riscrivere il test per incrementare il punteggio di mutazione del componente.Il terzo livello riguarda la verifica della conformità architetturale e dei limiti di dominio. Attraverso regole di analisi statica delle dipendenze, il gate certifica che il codice di produzione rispetti la separazione delle responsabilità (Separation of Concerns): classi di dominio puro non possono importare adattatori infrastrutturali, e moduli protetti non possono eludere i middleware di autenticazione definiti nei requisiti contrattuali.Il quarto livello si realizza nell'ispezione indipendente affidata a un sub-agente revisore disaccoppiato (Sub-Agent Code Reviewer), conformemente alle pratiche di Superpowers. Al termine delle verifiche strumentali, il diff generato nel Git Worktree viene trasmesso a un'istanza dell'agente che non condivide la memoria di lavoro della fase implementativa.Il revisore riceve unicamente la specifica iniziale, i vincoli della costituzione e la differenza tracciata da Git tra lo stato di partenza e il commit corrente. Tale entità analizza la modifica attraverso una griglia di valutazione rigorosa, verificando l'assenza di sovra-ingegnerizzazione contraria a YAGNI, la completa corrispondenza ai criteri di accettazione della specifica, la corretta gestione delle condizioni di errore e l'assoluta assenza di file modificati all'esterno del perimetro consentito. Eventuali rilievi classificati come critici impediscono l'approvazione del compito, imponendo all'orchestratore il re-indirizzamento del task verso una nuova sessione di bonifica.Blueprint Ingegneristico per la Skill di Esecuzione UniversaleLa traduzione operativa di questi principi all'interno di un pacchetto compatibile con lo standard aperto Agent Skills (SKILL.md) richiede una rigida separazione tra la definizione procedurale delle istruzioni e l'esecuzione deterministica dei vincoli di sistema. La configurazione YAML espone unicamente gli strumenti autorizzati e i metadati essenziali per preservare il budget di token durante la fase di discovery del sistema. La logica esecutiva risiede nelle prescrizioni procedurali del corpo del documento, mentre l'imposizione delle barriere di arresto viene delegata a un'utility bash esterna non manipolabile dall'agente cognitivo.Descrittore Operativo: skills/sdd-tdd-exec/SKILL.mdYAML---
name: sdd-tdd-exec
description: |
  Executes implementation tasks from tasks.md one by one using fresh subagents 
  and strict TDD (Red-Green-Refactor) inside the isolated Git Worktree. 
  Enforces code deletion if code precedes failing tests. Trigger with "/sdd:exec".
allowed-tools: "Read,Write,Edit,Glob,Grep,Bash(git:*),Bash(bash .spec-framework/bin/*)"
version: 1.1.0
license: MIT
compatibility: "Universal Agent Skills (Claude Code, OpenAI Codex, OpenCode)"
metadata:
  workflow: spec-driven-development
  phase: execution
  discipline: test-driven-development
---

# SDD Deterministic TDD Execution Engine

## Regole Fondative Inderogabili

- **DIVIETO DI CODICE SENZA TEST:** È formalmente interdetta la scrittura di codice di produzione prima che sia stato registrato ed eseguito un test fallimentare per asserzione semantica. Qualsiasi violazione impone la cancellazione immediata dei file non autorizzati.
- **ISOLAMENTO DEL WORKSPACE:** Tutte le modifiche devono risiedere all'interno del Git Worktree dedicato (`.worktrees/{CHG_ID}`). È vietato operare sull'albero di lavoro primario.
- **NEGATIVE SPACE & FILE BOUNDARIES:** L'agente ha facoltà di modificare unicamente i file dichiarati esplicitamente in `Allowed Paths` per il task corrente. Modifiche esterne a tali percorsi causano il blocco preventivo dei commit.
- **EVIDENZE STRUMENTALI:** Nessun micro-task può essere considerato completato sulla base di dichiarazioni testuali; la conclusione richiede exit code zero, analisi statica valida e assenza di mutanti superstiti.

## Procedura Esecutiva per Micro-Task

1. **Estrazione del Task e Ingestion del Contesto**
   - Ispezionare `changes/{CHG_ID}/tasks.md` ed estrarre il primo task in stato pendente con dipendenze soddisfatte.
   - Caricare i contratti di interfaccia e le asserzioni di dominio da `changes/{CHG_ID}/design.md`.

2. **Inizializzazione Workspace Isolato**
   - Validare lo stato operativo invocando l'utility deterministica di controllo:
     `bash .spec-framework/bin/enforce_tdd.sh init {CHG_ID} {TASK_ID}`
   - Accertare l'assenza di modifiche pregresse non tracciate all'interno del worktree.

3. **Ciclo RED (Verifica del Fallimento Semantico)**
   - Creare o aggiornare esclusivamente il file di test designato nei percorsi autorizzati.
   - Codificare l'asserzione corrispondente al criterio di accettazione del task (`AC-NNN`).
   - Lanciare la verifica strumentale della fase RED:
     `bash .spec-framework/bin/enforce_tdd.sh verify-red {CHG_ID} {TASK_ID} "{TEST_COMMAND}"`
   - Il framework certifica che il fallimento sia generato dall'asserzione e non da errori sintattici; se il test passa immediatamente, l'operazione viene arrestata.

4. **Ciclo GREEN (Implementazione YAGNI Minimale)**
   - Redigere nei soli file applicativi ammessi il codice strettamente indispensabile al superamento del test.
   - Eseguire la validazione della fase GREEN:
     `bash .spec-framework/bin/enforce_tdd.sh verify-green {CHG_ID} {TASK_ID} "{TEST_COMMAND}"`
   - Il test deve chiudersi con esito positivo e codice di uscita zero.

5. **Ciclo REFACTOR e Validazione Globale**
   - Bonificare la struttura del codice nel pieno rispetto delle convenzioni costituzionali.
   - Lanciare la suite di non-regressione sull'intero repository:
     `bash .spec-framework/bin/enforce_tdd.sh verify-global {CHG_ID} "{GLOBAL_TEST_COMMAND}"`
   - Qualora emergano regressioni, le modifiche del refactoring vengono annullate d'ufficio.

6. **Audit di Chiusura e Commit Atomico**
   - Sottoporre il componente al controllo dell'harness di mutazione e invocare il sub-agente revisore indipendente.
   - A ratifica avvenuta, generare il commit atomico:
     `git commit -m "feat({scope}): implement {TASK_ID} - {AC_REF}"`
   - Aggiornare lo stato del task in `tasks.md` contrassegnando la spunta `[x]`.
Script di Enforcement Deterministico: .spec-framework/bin/enforce_tdd.shL'infrastruttura di controllo deterministico si concretizza nello script shell seguente, preposto a governare le transizioni di stato e a sanzionare le deviazioni metodologiche direttamente a livello di sistema operativo:Bash#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-}"
CHANGE_ID="${2:-}"
TASK_ID="${3:-}"
COMMAND_PAYLOAD="${4:-}"

BASE_PATH=$(git rev-parse --show-toplevel)
WORKTREE_PATH="${BASE_PATH}/.worktrees/${CHANGE_ID}"

if [[ ! -d "${WORKTREE_PATH}" ]]; then
  echo "ERRORE STRUTTURALE: Area di lavoro isolata '${WORKTREE_PATH}' non presente." >&2
  exit 1
fi

cd "${WORKTREE_PATH}"

case "${ACTION}" in
  init)
    echo "Verifica stato preliminare per task ${TASK_ID}..."
    if [[ -n "$(git status --porcelain)" ]]; then
      echo "ERRORE: Rilevate modifiche non tracciate nel worktree. Ripristinare lo stato pulito." >&2
      exit 1
    fi
    echo "Stato iniziale verificato con successo per ${TASK_ID}."
    ;;

  verify-red)
    echo "Esecuzione controllo fase RED: ${COMMAND_PAYLOAD}"
    
    # Rilevamento preventivo di alterazioni al codice applicativo
    ALTERED_PROD_FILES=$(git status --porcelain | grep -v -E '(test|spec)' || true)
    if [[ -n "${ALTERED_PROD_FILES}" ]]; then
      echo "VIOLAZIONE TDD: Codice applicativo modificato prima della registrazione del test!" >&2
      echo "Applicazione immediata della cancellazione d'ufficio..." >&2
      git checkout -- .
      git clean -fd
      exit 2
    fi

    # Esecuzione del test runner e intercettazione dello stato di uscita
    set +e
    eval "${COMMAND_PAYLOAD}" > /tmp/tdd_red.log 2>&1
    RUNNER_STATUS=$?
    set -e

    if [[ ${RUNNER_STATUS} -eq 0 ]]; then
      echo "FALLIMENTO GATE RED: Il test è passato al primo tentativo. Un test RED deve fallire." >&2
      cat /tmp/tdd_red.log
      exit 3
    fi

    # Analisi dei log per escludere fallimenti per vizi sintattici o import mancanti
    if grep -E -i "(SyntaxError|ParseError|Cannot find module|compilation failed)" /tmp/tdd_red.log > /dev/null; then
      echo "FALLIMENTO GATE RED: Il test fallisce per errore sintattico o strutturale, non per asserzione logica." >&2
      cat /tmp/tdd_red.log
      exit 4
    fi

    echo "Fase RED convalidata: fallimento semantico accertato per asserzione non soddisfatta."
    ;;

  verify-green)
    echo "Esecuzione controllo fase GREEN: ${COMMAND_PAYLOAD}"
    
    set +e
    eval "${COMMAND_PAYLOAD}" > /tmp/tdd_green.log 2>&1
    RUNNER_STATUS=$?
    set -e

    if [[ ${RUNNER_STATUS} -ne 0 ]]; then
      echo "FALLIMENTO GATE GREEN: Il codice implementato non supera il test di riferimento." >&2
      cat /tmp/tdd_green.log
      exit 5
    fi

    echo "Fase GREEN convalidata: il test del micro-task è superato con successo."
    ;;

  verify-global)
    echo "Esecuzione suite di regressione globale: ${COMMAND_PAYLOAD}"
    
    set +e
    eval "${COMMAND_PAYLOAD}" > /tmp/tdd_global.log 2>&1
    RUNNER_STATUS=$?
    set -e

    if [[ ${RUNNER_STATUS} -ne 0 ]]; then
      echo "REGRESSIONE SISTEMICA RILEVATA: La modifica ha corrotto componenti preesistenti del repository." >&2
      cat /tmp/tdd_global.log
      exit 6
    fi

    echo "Non-regressione globale accertata: la suite di sistema passa regolarmente."
    ;;

  *)
    echo "Comando non supportato: ${ACTION}. Azioni valide: init, verify-red, verify-green, verify-global." >&2
    exit 1
    ;;
esac
Sintesi Strategica e Direttrici di SviluppoL'analisi dell'ingegneria del software assistita da modelli linguistici converge su un principio chiaro: la fase esecutiva non può essere affidata alla capacità di autoregolazione dell'agente. Lo Spec-Driven Development esprime la sua massima efficacia unicamente quando il codice viene materializzato attraverso il rigore metodologico del Test-Driven Development, presidiato da barriere deterministiche esterne.Per conseguire il massimo livello di affidabilità in un pacchetto proprietario di competenze per lo sviluppo software, l'architettura deve combinare tre scelte fondamentali. La prima risiede nella gestione microscopica del contesto cognitivo: isolare ciascun task atomico delegandone l'esecuzione a un sub-agente effimero previene il sovraccarico di token e neutralizza la distruzione della memoria causata dagli algoritmi di compressione automatica.La seconda scelta consiste nel confinamento fisico e perimetrale: l'adozione automatizzata dei Git Worktree, integrata dalla segregazione dei file modificabili (Negative Space), garantisce l'assoluta integrità dell'albero di lavoro primario ed elimina gli effetti a cascata derivanti da refactoring non autorizzati.La terza scelta, infine, poggia sull'intransigenza dei Quality Gates programmatici: delegare a script shell l'applicazione coatta della regola di cancellazione del codice privo di test preventivi, unita alla validazione empirica tramite testing di mutazione e audit multi-agente disaccoppiati, consente di chiudere definitivamente il divario tra intenzione contrattuale e realtà implementativa. Questo impianto trasforma gli agenti cognitivi da generatori probabilistici a esecutori deterministici e governabili, capaci di operare con continuità all'interno di complesse basi di codice industriali.