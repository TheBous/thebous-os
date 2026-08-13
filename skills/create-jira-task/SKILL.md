---
name: create-jira-task
description: Create a Jira task from a user request using the repository's fixed Italian description format with the sections "Descrizione" and "Acceptance Criteria". Use when the user asks to create, open, or draft a new Jira task and the description must follow that template.
---

## Obiettivo

Creare un nuovo task Jira con una descrizione sempre composta da:

```text
## Descrizione

<descrizione del lavoro>

## Acceptance Criteria

[ ] <criterio verificabile>

[ ] <criterio verificabile>
```

Il testo dell'esempio fornito dall'utente è solo uno scheletro. Non riutilizzare il suo contenuto funzionale.

## Passi

### 1. Raccogliere gli input minimi

Chiedere, se non sono già presenti nel messaggio:

- chiave del progetto Jira;
- summary del task;
- richiesta o comportamento da realizzare;
- criteri di accettazione, vincoli e casi limite già noti;
- tipo issue, usando `Task` come default solo se l'utente ha chiesto esplicitamente un task e il progetto lo supporta.

Non indovinare la chiave del progetto, il tipo issue o requisiti funzionali mancanti. Se il brief è troppo vago per produrre criteri verificabili, chiedere solo le informazioni mancanti.

### 2. Scrivere la descrizione

Generare la descrizione in italiano, salvo richiesta diversa dell'utente, rispettando esattamente questa struttura:

```text
## Descrizione

<uno o più paragrafi concisi che spiegano cosa realizzare, il contesto e il risultato atteso>

## Acceptance Criteria

[ ] <un risultato osservabile e verificabile>

[ ] <un risultato osservabile e verificabile>
```

Regole:

- produrre sempre un documento Markdown;
- usare esattamente i titoli di livello 2 `## Descrizione` e `## Acceptance Criteria`;
- non usare titoli di livello 1, testo semplice o titoli di livello diverso per queste sezioni;
- lasciare una riga vuota dopo ogni etichetta e tra i criteri;
- usare una riga `[ ] ...` per ogni criterio, senza numerazione o bullet aggiuntivi;
- trasformare in criteri solo requisiti derivabili dalla richiesta e dalle risposte dell'utente;
- rendere ogni criterio indipendente, testabile e non ambiguo;
- includere errori, autorizzazioni, dati obbligatori e casi limite solo quando sono pertinenti al brief;
- non inventare copy, URL, stati di dominio, nomi di entità, API o dettagli tecnici non forniti;
- non lasciare placeholder, criteri vuoti o formule generiche come `[ ] Il task funziona`.

Il summary deve essere breve e descrivere il risultato del task; non aggiungere prefissi o chiavi Jira se l'utente non li richiede.

### 3. Mostrare l'anteprima e chiedere conferma

Prima di scrivere su Jira, mostrare:

- progetto;
- tipo issue;
- summary;
- descrizione completa generata in un blocco di testo.

Chiedere conferma esplicita. Se l'utente modifica il testo, rigenerare l'anteprima e chiedere nuovamente conferma. Non creare il task con requisiti ancora incerti o con placeholder.

### 4. Creare il task su Jira

Preferire il server MCP Atlassian configurato:

1. risolvere il `cloudId` con `getAccessibleAtlassianResources`;
2. se sono presenti più siti Jira, chiedere quale usare;
3. creare l'issue con lo strumento di creazione Jira esposto dal server, passando progetto, tipo issue, summary e la descrizione completa;
4. usare i nomi e i parametri esatti esposti dallo strumento disponibile, senza inventare campi custom.

Se il MCP non è disponibile o fallisce, usare il fallback REST solo se sono configurati `JIRA_BASE_URL`, `JIRA_EMAIL` e `JIRA_API_TOKEN` nel file `.env` condiviso, risolto da `scripts/helpers.sh`:

```bash
source "scripts/helpers.sh"
load_env

BODY=$(jq -n \
  --arg project_key "<PROJECT_KEY>" \
  --arg issue_type "<ISSUE_TYPE>" \
  --arg summary "<SUMMARY>" \
  --arg description "<DESCRIPTION>" \
  '{fields:{project:{key:$project_key},issuetype:{name:$issue_type},summary:$summary,description:$description}}')

curl -sf \
  -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -X POST "$JIRA_BASE_URL/rest/api/2/issue" \
  -d "$BODY"
```

Usare sempre `jq --arg` per serializzare il testo: non costruire JSON concatenando la descrizione a mano.

Se mancano le credenziali, indicare di eseguire `/thebous-os:setup`. Non eseguire chiamate Jira parziali e non simulare la creazione.

### 5. Confermare il risultato

Dopo una risposta positiva di Jira, mostrare:

- chiave del task;
- link `JIRA_BASE_URL/browse/<KEY>` quando `JIRA_BASE_URL` è disponibile;
- summary creato.

Non aggiungere automaticamente commenti Slack, transizioni, branch, PR, Obsidian o Confluence: non fanno parte di questa skill.
