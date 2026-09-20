# Task Tracking Multi-Provider

## Problem Statement

Come team, vogliamo scegliere Jira o Notion per ogni task e mantenere lo stesso flusso operativo di branch, PR, stati, notifiche e tracking, senza duplicare o sincronizzare inutilmente i task.

## Recommended Direction

Aggiungere Notion come provider alternativo per singolo task. L'utente indica un Jira ticket oppure una pagina Notion; il sistema riconosce il provider e applica lo stesso workflow.

Ogni provider deve supportare le operazioni realmente usate dai workflow attuali: leggere il task, creare task, aggiornare stato, aggiungere commenti, ottenere link e fornire titolo, descrizione e requisiti. Jira e Notion restano indipendenti: nessun mirror automatico.

## Key Assumptions to Validate

- [ ] Il team usa un database Notion con proprietà standard: titolo, stato, descrizione, assignee e scadenza.
- [ ] Ogni pagina Notion può essere identificata stabilmente da URL o page ID.
- [ ] Gli stati Notion possono essere mappati a `To Do`, `In Progress`, `In Review`, `In Staging` e `Done`.
- [ ] Branch e PR possono contenere un riferimento Notion leggibile e stabile.
- [ ] L'utente preferisce scegliere il provider esplicitamente per task, senza sincronizzazione automatica.

## MVP Scope

- Configurazione delle credenziali Notion.
- Creazione e lettura di task Jira o Notion.
- Avvio branch da Jira o Notion.
- Aggiornamento dello stato durante branch, PR e merge.
- Commento e link del PR sul task corretto.
- Notifiche Slack con link al provider.
- Log Obsidian usando `provider + id`, non solo una chiave Jira.
- `current-status` capace di aggregare entrambi.

## Not Doing (and Why)

- Sincronizzazione bidirezionale Jira ↔ Notion — introduce conflitti e non serve al caso d'uso.
- Conversione automatica Notion → Jira — l'utente ha già scelto il provider.
- Supporto immediato a schemi Notion arbitrari — serve prima uno schema documentato.
- Parità perfetta per funzioni Jira senza equivalente Notion — alcune query di attività e transizioni avanzate richiedono un comportamento specifico.

## Open Questions

- Quale database Notion deve essere usato e quali proprietà contiene?
- Il provider verrà scelto tramite URL automatico oppure con un prefisso esplicito come `jira:T-123` / `notion:<url>`?
- Quali stati Notion devono corrispondere agli stati Jira?
- Il task Notion deve supportare anche acceptance criteria e commenti strutturati?
