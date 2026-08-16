---
name: cook-next
description: Sviluppa una feature o un fix seguendo un workflow di comprensione profonda, design difensivo, test-first e implementazione incrementale. Usala quando il lavoro parte da un ticket Jira e richiede spec HTML, plan Markdown e task.md sincronizzati tra progetto e Obsidian, con PR stack oltre 400 righe di codice cambiate.
---

# Cook Next

## Vincoli obbligatori

- Recupera il contesto completo del ticket Jira prima di analizzare o modificare
  il codice.
- Non scrivere codice prima di aver completato comprensione, domande, spec,
  plan, task e test iniziali.
- Crea gli artefatti in entrambe le destinazioni e mantienili sincronizzati:
  - progetto: `docs/<KEY>/spec.html`, `docs/<KEY>/plan.md`,
    `docs/<KEY>/task.md`;
  - Obsidian: `<OBSIDIAN_VAULT_PATH>/Dev/Tickets/<KEY>/spec.html`, `plan.md`,
    `task.md`.
- Usa `task.md` come checklist ordinata dello sviluppo e aggiornalo prima e dopo
  ogni attività significativa.
- Una singola PR non deve superare 400 righe di codice aggiunte più rimosse.
  Se la feature richiede di più, suddividila in PR indipendenti impilate una
  sull’altra.
- Se il ticket Jira o il vault Obsidian non sono disponibili, interrompi il
  workflow prima di creare file o modificare il codice.

## 1. Recupera il contesto del task

Registra il commit iniziale per poter misurare la modifica della feature:

```bash
BASE_COMMIT=$(git rev-parse HEAD)
```

Risolvi il Jira key dal branch o dal contesto utente usando
`references/jira-task-context.md` con:

```text
<SOURCES> = nome del branch corrente e input dell’utente
<REQUIRED> = required
<DETAILS> = full
```

Se la chiave non è ricavabile, chiedi il Jira key o l’URL. Se resta assente,
fermati.

Recupera tutti i dettagli disponibili del task:

- summary e description;
- acceptance criteria o requisiti espliciti;
- status, priority, assignee e issue type;
- linked issues e subtasks;
- parent story/task, epic e altri ancestor;
- stories o child task sotto il parent, quando disponibili.

Risalire la gerarchia dei parent finché termina. Usa il contesto raccolto per
definire scope, dipendenze, criteri di accettazione e ordine di implementazione.
Non reimplementare la risoluzione Jira: usa il riferimento condiviso e gli
strumenti disponibili dell’ambiente.

Definisci anche il valore user-visible della feature, lo stakeholder che può
validarlo e il livello di rischio (basso, medio o alto). Valuta almeno impatto
su dati, sicurezza, compatibilità, performance, pagamenti e numero di utenti.

## 2. Comprensione profonda prima del codice

### Leggi il problema più volte

- Leggi completamente il requisito almeno tre volte.
- Apri e leggi ogni documento, RFC, snippet o riferimento collegato.
- Se la feature estende un comportamento esistente, testalo prima.
- In questa prima lettura concentra l’attenzione sul comportamento richiesto,
  non ancora sui dettagli della codebase.

### Fai domande esplicite

Prima di codare, chiarisci con l’utente o con lo stakeholder:

- scope, fuori scope, use case e personas;
- comportamento atteso e criteri di accettazione;
- input, output e messaggi di errore;
- input `null`, vuoti, mancanti o fuori range;
- server lento, timeout o dipendenze non disponibili;
- double-click, rapid fire e interazioni concorrenti;
- stato inconsistente, permessi non validi, rate limit e race condition.

Non procedere finché la direzione necessaria per scrivere la spec non è
confermata o le assunzioni aperte non sono dichiarate. Quando mancano
informazioni di dominio, coinvolgi esplicitamente cliente, product owner,
utente finale o altro esperto del dominio.

### Prova il sistema esistente

Se applicabile, interagisci con l’applicazione e prova i flussi reali. Osserva
comportamento normale, limiti, errori e differenze tra il flusso teorico e
quello usato dall’utente.

### Costruisci il mental model

Non cercare di comprendere l’intera codebase. Parti da un modello approssimato e
raffinalo identificando:

1. README e struttura del progetto;
2. flusso principale o critico;
3. componenti coinvolti dalla feature;
4. punti in cui i dati entrano e vengono conservati;
5. file che coordinano il comportamento;
6. funzioni, moduli e dipendenze da modificare o creare.

## 3. Crea la spec HTML

Dopo la fase delle domande e dopo aver ricevuto le risposte necessarie, verifica
la configurazione Obsidian:

```bash
source "scripts/helpers.sh"
load_env
test -n "${OBSIDIAN_VAULT_PATH:-}" && test -d "$OBSIDIAN_VAULT_PATH"
```

Risolvi la cartella Obsidian con `obsidian_ticket_dir`. Crea inoltre la cartella
locale `docs/<KEY>/`.

Scrivi `spec.html` in entrambe le destinazioni. Il file deve essere HTML
autonomo, leggibile in browser e contenere:

- problema, obiettivo e valore della feature;
- stakeholder che ha confermato la direzione;
- scope, fuori scope e contesto del ticket;
- feature user-visible, priorità e dipendenze;
- requisiti funzionali e non funzionali;
- use case e flussi principali;
- input, output e gestione degli errori;
- acceptance criteria;
- edge case identificati;
- assunzioni, decisioni e domande ancora aperte;
- componenti o aree della codebase probabilmente coinvolti;
- tabella requisito → criterio di accettazione → test → evidenza;
- metriche di successo e finestra di osservazione post-release;
- vincolo delle 400 righe e possibile decomposizione in PR stack.

Usa, quando possibile, feature piccole e riconoscibili dall’utente. Se una
feature non può essere consegnata in un ciclo breve, dividila in feature più
piccole senza perdere valore dimostrabile.

Marca ogni assunzione non confermata come `Non verificato`. La spec descrive
ciò che deve essere sviluppato, non ciò che è già stato implementato.

Verifica che entrambe le copie esistano e non siano vuote prima di continuare.

## 4. Crea il plan Markdown

Solo dopo aver creato la spec, scrivi `plan.md` in entrambe le destinazioni.
Il plan deve descrivere:

- approccio tecnico scelto;
- pseudocodice o sequenza della logica in plain English;
- file e componenti da analizzare o modificare;
- input/output/errori da gestire;
- dipendenze e ordine delle modifiche;
- edge case e strategia di programmazione difensiva;
- livello di rischio e motivazione dei controlli scelti;
- test da scrivere prima del codice;
- matrice dei test: unit, integration, E2E/smoke, security, performance e
  stress, in base al rischio;
- controlli CI: test, lint, typecheck e static analysis;
- peer review indipendente e design inspection;
- rollout, feature flag/canary quando utile, monitoring, alert e rollback;
- rischi, assunzioni e strategia di verifica;
- metriche per acceptance, difetti, rework, lead time e adozione;
- eventuale ordine delle PR stack.

Il plan non sostituisce la spec e non deve contenere implementazione già
conclusa.

## 5. Crea e usa `task.md`

Dopo la spec e il plan, crea `task.md` in entrambe le destinazioni. Inserisci
una checklist concreta e ordinata, includendo almeno:

```markdown
- [ ] completare la comprensione del flusso esistente
- [ ] definire e verificare gli edge case
- [ ] scrivere i test prima dell’implementazione
- [ ] definire la matrice dei test in base al rischio
- [ ] implementare il primo blocco atomico
- [ ] eseguire i test del blocco
- [ ] eseguire CI, lint, typecheck e static analysis dopo ogni commit
- [ ] ripetere implementazione e verifica per ogni blocco
- [ ] completare design inspection e peer review indipendente
- [ ] fare test manuali degli edge case
- [ ] completare security, performance e stress test quando applicabili
- [ ] fare code review personale
- [ ] verificare staging, monitoring, alert e rollback
- [ ] misurare l’impatto post-release
- [ ] eseguire la verifica finale e misurare la dimensione della PR
```

Usa `[x]` solo dopo aver verificato il risultato e `[blocked]` con il motivo per
un’attività bloccata. Prima di ogni azione significativa aggiorna la checklist;
dopo l’azione registra l’esito. Le due copie devono restare identiche.

## 6. Programmazione difensiva

Prima e durante l’implementazione:

- non assumere che gli input siano validi o nei limiti;
- controlla esplicitamente array, stringhe, indici e puntatori;
- valida tipo, presenza, range e permessi agli ingressi del sistema;
- gestisci le eccezioni in modo esplicito e coerente;
- fai fallire il sistema in modo sicuro e prevedibile;
- lascia assertions utili per verificare le assunzioni durante lo sviluppo.

Per ogni funzione non banale definisci la relazione tra input, output e errori
prima di implementarla.

Riduci la superficie di errore: riusa codice e primitive native già affidabili,
mantieni funzioni piccole, preferisci flussi lineari ed early return, evita
nesting non necessario e non ottimizzare prima di avere una misura che dimostri
un problema.

## 7. Test-first / spec-first

Scrivi i test prima del codice. I test devono coprire:

- happy path;
- input invalidi e error cases;
- input nulli, vuoti, estremi o fuori range;
- dipendenze esterne fallite o lente;
- doppio click e interazioni concorrenti, se applicabili;
- punti di integrazione con API, database o altri moduli.

Ogni test deve essere collegabile a un requisito, un edge case o un criterio di
accettazione nella spec. Aggiorna `task.md` e sincronizza entrambe le copie dopo
aver scritto e verificato i test.

Non derivare i test soltanto dall’implementazione: verifica anche le assunzioni
su tipi, formati, unità di misura, compatibilità legacy, autorizzazioni e stati
di errore.

## 8. Implementazione incrementale

Procedi per piccoli blocchi atomici:

1. seleziona il prossimo task;
2. aggiorna `task.md` indicando che è in lavorazione;
3. implementa idealmente 10–20 righe alla volta;
4. esegui i test rilevanti;
5. correggi subito eventuali errori;
6. fai refactoring immediato se emerge codice duplicato o poco chiaro;
7. marca il task completato solo dopo la verifica;
8. sincronizza `spec.html`, `plan.md` e `task.md` tra progetto e Obsidian.

Mantieni il codice semplice e leggibile, con commit piccoli e branch brevi.
Mantieni i branch abbastanza brevi da poter essere integrati in pochi giorni e
integra spesso per ridurre conflitti. Non rimandare il refactoring evidente alla
fine del lavoro.

Prima di ogni blocco simula mentalmente:

- best case e worst case;
- input inattesi;
- dipendenze lente o fallite;
- due utenti o richieste concorrenti;
- stato parzialmente aggiornato;
- modalità con cui il sistema degrada in caso di errore.

## 9. Test manuale e self-review prima del commit

### Test manuale

Riprendi gli edge case dalla spec e testali uno per uno nel sistema reale o in
un ambiente equivalente. Non saltare i casi negativi. Registra in `task.md` ciò
che è stato verificato.

### Mentalità da attaccante

Chiediti come rompere il comportamento con input manipolati, richieste ripetute,
ordine inatteso degli eventi, dati incoerenti, permessi insufficienti o errori
delle dipendenze.

### Code review personale

Rileggi la modifica come se l’avesse scritta qualcun altro e verifica:

- nomi chiari e descrittivi;
- logica leggibile al primo sguardo;
- validazioni e sanity check presenti;
- assunzioni nascoste eliminate o documentate;
- errori gestiti completamente;
- assenza di duplicazioni evitabili;
- criteri di accettazione coperti da test o verifica manuale.

## 10. Quality gate prima del merge

Prima di chiedere o approvare il merge, esegui una verifica indipendente:

- peer code review completata;
- design inspection completata per modifiche ad alto rischio;
- CI verde con test automatici, lint, typecheck e static analysis;
- test unitari e di integrazione eseguiti;
- E2E/smoke, security, performance o stress test eseguiti quando richiesti dal
  livello di rischio;
- nessun criterio di accettazione senza evidenza;
- nessuna assunzione critica marcata `Non verificato`;
- diff entro 400 righe o PR stack approvata.

Il codice generato dall’AI non può essere approvato soltanto perché compila o
perché i suoi test passano.

## 11. Limite PR e PR stack

Misura la modifica rispetto al baseline:

```bash
git diff --numstat "$BASE_COMMIT"
```

Conta le righe di codice e test aggiunte più rimosse. Escludi gli artefatti
obbligatori `spec.html`, `plan.md`, `task.md`, file generati, lockfile,
dipendenze vendorizzate e immagini.

Se il totale supera 400 righe per una singola PR:

1. non consegnare una PR monolitica;
2. aggiorna `plan.md` con la decomposizione minima;
3. separa il lavoro in tranche indipendenti e ordinate per dipendenza;
4. assegna a ogni tranche codice, test e criteri di verifica propri;
5. crea PR stack una sull’altra e registra branch e ordine in `plan.md` e
   `task.md`;
6. verifica ogni tranche prima di procedere alla successiva.

Una possibile sequenza è: preparazione di contratti/schema, logica principale,
integrazione o UI. Scegli solo le tranche realmente necessarie.

## 12. Rilascio, misurazione e verifica finale

Prima di dichiarare conclusa la feature:

- tutti i test automatici rilevanti passano;
- ogni edge case della spec è stato verificato manualmente;
- l’error handling è completo;
- la code review personale è conclusa;
- la peer review indipendente e la CI sono concluse;
- le decisioni non ovvie sono documentate nel plan;
- il comportamento è stato provato in un ambiente simile alla produzione;
- monitoring, log, alert e piano di rollback sono pronti;
- feature flag o canary sono usati quando il rischio lo giustifica;
- tutti i task sono `[x]` oppure `[blocked]` con motivazione;
- le copie locali e Obsidian di spec, plan e task sono identiche;
- il limite di 400 righe è rispettato oppure la PR stack è stata definita.

Dopo il rilascio, nella finestra concordata in `spec.html`, verifica e registra:

- acceptance rate;
- defect rate per feature;
- percentuale di rework;
- lead time e deployment frequency;
- adoption, engagement e soddisfazione utenti;
- regressioni, incidenti e alert inattesi.

La feature è riuscita solo quando i criteri di accettazione sono soddisfatti,
il rischio residuo è accettabile e l’utilizzo dimostra il valore atteso. Non
dichiarare mai “zero bug”: dichiara invece quali controlli sono passati, quali
metriche sono state osservate e quali rischi restano aperti.
