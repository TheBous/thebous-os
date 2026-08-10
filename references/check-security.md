---
description: Practical OWASP-focused security review for fast-moving codebases — catches hardcoded secrets, auth bypasses, missing access controls, injection vulnerabilities
---

## Goal

Run a focused security triage on the pending changes, targeting common vulnerabilities in AI-assisted and rapidly prototyped code.

## Philosophy

Assume the code was built with AI tools and speed-first practices. Look for **convenient but dangerous patterns**: hardcoded secrets, trust in client input, missing authorization checks, unsafe injection points. This is not a formal audit — it's finding low-hanging security fruit before deeper analysis.

## Steps

### 1. Pin the diff scope

If the user gave a fixed point (branch, commit, or tag), diff against it:
```bash
git diff <fixed-point>...HEAD
```
Otherwise default to uncommitted/local changes:
```bash
git diff HEAD
```
Confirm the diff is non-empty before continuing.

### 2. Run security analysis via sub-agent

Spawn **one `general-purpose` sub-agent** with the complete vibecoder-review skill definition (see **Skill Definition** section below) and the diff from step 1.

Brief: "You are a vibecoder security reviewer. Use the skill definition below to triage this diff for common patterns where speed trumps security. Focus ONLY on findings where you're >80% confident of actual exploitability. Look for hardcoded secrets, auth bypasses, missing access controls, and injection vulnerabilities. Report HIGH and MEDIUM findings only — avoid theoretical issues and noise. For each finding, provide: location (file:line), severity, issue description, exploit scenario, and remediation."

### 3. Present the findings

Show the sub-agent's report verbatim. Do not rerank or merge findings. Each issue should include:
- **Location:** `file.ts:line`
- **Severity:** HIGH or MEDIUM (CRITICAL if present)
- **Category:** (e.g., hardcoded_secrets, auth_bypass, injection)
- **Description:** What the vulnerability is
- **Exploit Scenario:** How an attacker would abuse it
- **Remediation:** Specific fix recommendation

### 4. Optional Jira comment

If the current branch matches a Jira key (pattern `[A-Za-z]+-[0-9]+`), ask the user:
```
Vuoi che lasci un commento su Jira con l'esito della security review?
```
If yes, follow `references/jira-transition.md` (in the plugin root) for the comment call only — never pass a transition ID.

## Skill Definition

**For the sub-agent to follow:**

### Core Checks

#### 1. SECRETS & KEYS
Search for hardcoded API keys, database credentials, JWT secrets, OAuth tokens in source code, comments, test fixtures.
- Check `.env`, config files, source constants, frontend bundles
- Flag: plaintext credentials, secrets in comments, credentials in frontend code
- Verify: test credentials disabled in production

#### 2. AUTH & ACCOUNTS
Find auth bypasses, privilege escalation, missing checks, session flaws.
- Check login code, authorization checks, session handling
- Flag: user ID from URL/client without verification, role/admin from request body, client-side only auth checks, non-expiring tokens
- Verify: server-side validation on every privileged operation

#### 3. USER DATA & PRIVACY
Find endpoints where changing an ID leaks someone else's data.
- Check API routes, database queries, GraphQL resolvers
- Flag: no ownership checks on record access, missing WHERE filters, public access to sensitive data, ID enumeration possible
- Verify: ownership check before returning any user-specific data

#### 4. TEST VS PRODUCTION
Find test backdoors and debug features left in production.
- Check environment detection, test code, debug routes, verbose errors, shared databases
- Flag: test accounts in production, debug mode enabled, backdoor credentials
- Verify: test infrastructure completely isolated from production

#### 5. FILE UPLOADS
Find arbitrary file uploads leading to code execution or XSS.
- Check upload handlers, file validation, storage location, file processing
- Flag: no file type validation, client-side only validation, executable locations, unsafe processing
- Verify: allowlist validation, sandboxed storage, safe processing

#### 6. DEPENDENCIES & PLUGINS
Identify vulnerable or suspicious packages.
- Check package manifests, lockfiles, publish dates
- Flag: ancient dependencies (years old), known CVEs, unsafe use of powerful SDKs
- Verify: dependencies current within 2 major versions

#### 7. BASIC HYGIENE
Find missing security headers and configurations.
- Check CORS, CSRF protection, cookie flags, HTTPS, rate limiting
- Flag: overly permissive CORS, no CSRF tokens, insecure cookies, HTTP in production, no rate limiting
- Verify: security headers present, rate limiting on auth endpoints

#### 8. INJECTION & CODE EXECUTION
Find SQL injection, XSS, prompt injection, RCE.

**SQL Injection:**
- Flag: string concatenation in queries, f-strings with user input, `.raw()` with user data, NoSQL `$where` operator
- Verify: parameterized queries with bound parameters

**XSS:**
- Flag: `innerHTML`, `dangerouslySetInnerHTML`, template `|safe` filters with user content
- Verify: text content (auto-escaped), React default escaping, sanitized HTML

**Prompt Injection:**
- Flag: user input mixed into system prompts, LLM output used in SQL/shell commands unsafely, tools without validation
- Verify: system and user messages clearly separated, LLM output validated before use

**RCE:**
- Flag: `eval`, `exec` with user input, shell commands with string concatenation, unsafe deserialization, template rendering from user strings
- Verify: avoid eval/exec entirely, parameterized shell commands, safe deserialization (JSON), pre-defined templates

### FALSE POSITIVE FILTERING

**Automatically exclude:**
1. Denial of Service (DOS) or resource exhaustion
2. Secrets on disk if otherwise secured
3. Rate limiting or service overload concerns
4. Memory or CPU exhaustion
5. Lack of input validation on non-security fields without proof of impact
6. Input sanitization in GitHub Actions (unless untrusted input triggers it)
7. Lack of hardening measures (only flag concrete vulnerabilities)
8. Theoretical race conditions or timing attacks
9. Outdated third-party libraries (managed separately)
10. Memory safety issues in memory-safe languages
11. Unit test or test-only files
12. Log spoofing from unsanitized user output
13. SSRF that only controls the path (not host/protocol)
14. User content in AI system prompts
15. Regex injection or regex DOS
16. Insecure documentation (markdown)
17. Lack of audit logs

**Precedents:**
- Logging high-value secrets in plaintext IS a vulnerability; logging URLs is safe
- UUIDs are unguessable, no validation needed
- Environment variables and CLI flags are trusted
- React/Angular are secure against XSS by default unless using unsafe methods
- GitHub Action workflow vulnerabilities: only report if concrete and exploitable
- Client-side JS/TS: permission checks not needed (server enforces)
- MEDIUM findings: only report if obvious and concrete

### QUALITY GATES

For each finding:
1. Is there a concrete, exploitable vulnerability with a clear attack path?
2. Is this a real security risk, not theoretical best practice?
3. Are there specific code locations and reproduction steps?
4. Would this finding be actionable for a security team?

Assign confidence 0-10:
- 8-10: High confidence, likely true vulnerability
- 7-8: Clear vulnerability pattern, report it
- Below 7: Do not report (too speculative)

## Time Budget

**Total:** ~1 hour for initial review

- Secrets scan: 10 min
- Auth review: 15 min
- Data access: 10 min
- Injection scan: 15 min
- Uploads & hygiene: 10 min

## Output Format

For each finding:

```markdown
# [SEVERITY] Issue: [Category] — file.ts:line

* **Description:** What the vulnerability is
* **Exploit Scenario:** How an attacker exploits it (concrete example)
* **Recommendation:** Specific fix
* **Confidence:** 9/10
```

Example:

```markdown
# [CRITICAL] Hardcoded API Key in Frontend Bundle — src/config/api.ts:15

* **Description:** OpenAI API key hardcoded and exposed in bundled client JavaScript
* **Exploit Scenario:** Attacker views page source, extracts key, makes unlimited API calls billed to you
* **Recommendation:** Move to environment variable, load via server-side proxy, or use API endpoint on your backend
* **Confidence:** 10/10
```

## Success Criteria

A good vibecoder review finds:
- 2-5 HIGH or CRITICAL issues in typical projects
- Quick, actionable recommendations
- Clear attack scenarios for each finding

**Red flags if you find nothing:** Either code is unusually secure (rare) or you missed something — dig deeper.
