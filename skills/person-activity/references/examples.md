# Person Activity Examples

This document shows real-world examples of how the `person-activity` skill works across different work item types and use cases.

## Example 1: Jira Task with Email Address

**Scenario:** Preparing for a 1:1 with a team member; you want to see their involvement on a specific task.

**Invocation:**
```bash
person-activity
```

**User Input:**
```
Enter work item ID (Jira key, GitHub PR #, or git commit hash): DC-443
Enter person's name or email: marco@company.com
```

**Expected Output:**
```markdown
# Activity — DC-443 with Marco Rossi

## 📋 Synthetic Summary
- **Role**: Reviewer, implementation owner
- **Key Decisions**: Approved refactoring approach on 2026-07-20; requested schema migration plan
- **Latest**: Posted final comment "Implementation looks solid, all tests passing" on 2026-08-08 16:45
- **Status**: Approved and merged

## 📍 Timeline
- 2026-07-18 11:22: Jira comment "I can take this refactoring task"
- 2026-07-20 14:30: Jira comment "Proposed approach looks good, let's use the adapter pattern"
- 2026-07-25 09:15: Slack message "Just pushed the refactoring PR, ready for review"
- 2026-07-28 13:45: GitHub approved PR with comment "Great implementation, clean and maintainable"
- 2026-08-08 16:45: Jira comment "Implementation looks solid, all tests passing"

## 💬 Sources
### Jira Comments
- 4 comments | [View on Jira](https://jira.company.com/browse/DC-443)

### GitHub PR/Reviews
- 1 approved review | [View PR #1285](https://github.com/company/repo/pull/1285)

### Slack
- 2 messages in #engineering | Sample: "Just pushed the refactoring PR, ready for review"

### Email
- 0 threads

### Calendar
- 1 event: "DC-443 refactoring sync" on 2026-07-19
```

**What You Learn:**
- Marco went from task owner to reviewer/approver
- He validated the technical approach early (2026-07-20), removing risk
- His most recent activity was positive closure (2026-08-08), suggesting task completion
- Implementation took about 3 weeks from start to approval
- Cross-source view shows he communicated in Jira (decisions) and Slack (quick status)

---

## Example 2: GitHub PR with Person Name

**Scenario:** Code review phase — understanding what feedback a senior engineer gave on a PR without reading the whole thread.

**Invocation:**
```bash
person-activity
```

**User Input:**
```
Enter work item ID (Jira key, GitHub PR #, or git commit hash): PR #250
Enter person's name or email: Sarah Chen
```

**Expected Output:**
```markdown
# Activity — PR #250 with Sarah Chen

## 📋 Synthetic Summary
- **Role**: Code reviewer, technical lead
- **Key Decisions**: Requested major refactor of caching layer (request-scoped caching → global cache with TTL); approved after changes
- **Latest**: Approved PR on 2026-08-09 with "Looks great, ready to ship"
- **Status**: Approved and merged

## 📍 Timeline
- 2026-08-01 10:15: GitHub review "The caching approach here won't work for async contexts, let's discuss"
- 2026-08-02 09:30: GitHub comment "I've added some links to patterns; request scope is too narrow"
- 2026-08-03 14:20: Slack DM "I can pair on the caching refactor today if helpful"
- 2026-08-05 16:45: GitHub review approved with "Much cleaner now, one nit: add a comment explaining TTL choice"
- 2026-08-09 11:00: GitHub approved "Ready to ship"

## 💬 Sources
### Jira Comments
- 1 comment | [View on Jira](https://jira.company.com/browse/INFRA-287)

### GitHub PR/Reviews
- 2 reviews, 3 comments | [View PR #250](https://github.com/company/repo/pull/250)

### Slack
- 1 direct message offering help

### Email
- 0 threads

### Calendar
- 0 events
```

**What You Learn:**
- Sarah identified a real architectural issue early (2026-08-01) that required refactoring, not just polish
- The team responded to her feedback and iterated (2026-08-03 → 2026-08-05)
- She offered hands-on help (pairing), showing investment in the solution
- Final approval took 1 week from initial feedback, suggesting complexity
- This wasn't a simple PR — multiple rounds of review indicate significant changes
- Her domain expertise (caching patterns) shaped the final approach

---

## Example 3: Git Commit with Email

**Scenario:** Investigating a production issue; you want to understand who touched this code and what they said about it at the time.

**Invocation:**
```bash
person-activity
```

**User Input:**
```
Enter work item ID (Jira key, GitHub PR #, or git commit hash): abc123def789
Enter person's name or email: john@company.com
```

**Expected Output:**
```markdown
# Activity — abc123def789 with John Washington

## 📋 Synthetic Summary
- **Role**: Committer, bug fix owner
- **Key Decisions**: Fixed race condition in event processor with atomic compare-and-swap
- **Latest**: Merged via PR #187 on 2026-07-22
- **Status**: Closed, deployed to production 2026-07-23

## 📍 Timeline
- 2026-07-20 08:45: Jira comment "I found the race condition in EventProcessor; fixing with CAS"
- 2026-07-20 15:30: GitHub comment on PR #187 "This change is minimal on purpose — CAS is the minimal safe fix"
- 2026-07-21 11:00: Slack message "PR is up, been tested locally and in staging; looks solid"
- 2026-07-22 09:15: GitHub review approved by maintainer; John merged with "Good catch, thanks for the minimal fix"

## 💬 Sources
### Jira Comments
- 2 comments | [View on Jira](https://jira.company.com/browse/INFRA-41)

### GitHub PR/Reviews
- 1 PR, 2 comments | [View PR #187](https://github.com/company/repo/pull/187)

### Slack
- 1 message | "PR is up, been tested locally and in staging; looks solid"

### Email
- 0 threads

### Calendar
- 0 events
```

**What You Learn:**
- John identified a race condition and understood the right fix (atomic compare-and-swap is precise)
- His fix was intentionally minimal ("minimal on purpose"), a sign of production safety thinking
- He tested in both local and staging before requesting review, reducing risk
- Turnaround was fast (2026-07-20 → 2026-07-22), showing urgency
- No email threads = this was a quick operational fix, not a spec or design discussion
- His cross-source communication (Jira decision → GitHub explanation → Slack confidence) shows thoughtful handoff

---

## Example 4: Jira Task, Context-Switching Back to a Project

**Scenario:** You've been away from a project for 2 weeks; a task is in progress and you need to catch up on one person's work.

**Invocation:**
```bash
person-activity
```

**User Input:**
```
Enter work item ID (Jira key, GitHub PR #, or git commit hash): PROJ-856
Enter person's name or email: Alex Kumar
```

**Expected Output:**
```markdown
# Activity — PROJ-856 with Alex Kumar

## 📋 Synthetic Summary
- **Role**: Designer, requirements clarifier
- **Key Decisions**: Proposed new user flow incorporating feedback from user testing; recommended splitting into two phases
- **Latest**: Posted Figma links and requested implementation feedback on 2026-08-08
- **Status**: Awaiting implementation kickoff

## 📍 Timeline
- 2026-07-29 10:00: Jira comment "I ran user testing yesterday; key insight: users want bulk actions first"
- 2026-07-30 14:20: Jira attachment: Figma file with revised flows (v2, v3)
- 2026-08-01 09:30: Slack in #design "Bulk actions mockup is ready, pinging eng to review"
- 2026-08-05 15:15: Calendar event: "PROJ-856 design review with engineering"
- 2026-08-08 11:45: Jira comment "Updated Figma based on feedback; recommend Phase 1 (bulk) + Phase 2 (filters)"

## 💬 Sources
### Jira Comments
- 5 comments, 2 attachments | [View on Jira](https://jira.company.com/browse/PROJ-856)

### GitHub PR/Reviews
- 0 PRs (design phase)

### Slack
- 2 messages in #design channel

### Email
- 1 thread with product team on requirements

### Calendar
- 1 design review meeting (2026-08-05)
```

**What You Learn:**
- Alex did user research that changed the spec (user testing → new flow)
- He's managed scope by proposing a two-phase rollout, reducing risk for Phase 1
- Design work is mature (multiple Figma iterations, formal review meeting)
- Last update (2026-08-08) shows the task is ready for handoff to engineering
- This task likely needs an engineering owner; Alex has done his part

---

## Example 5: GitHub PR with a Name Search

**Scenario:** Performance review prep — seeing what a new team member contributed to a flagship PR.

**Invocation:**
```bash
person-activity
```

**User Input:**
```
Enter work item ID (Jira key, GitHub PR #, or git commit hash): #1920
Enter person's name or email: Jordan Lee
```

**Expected Output:**
```markdown
# Activity — #1920 with Jordan Lee

## 📋 Synthetic Summary
- **Role**: Contributor, implementer
- **Key Decisions**: Proposed caching optimization; contributed database query improvements
- **Latest**: Pushed final commits on 2026-08-06; merged on 2026-08-07
- **Status**: Closed and merged

## 📍 Timeline
- 2026-07-28 15:30: GitHub comment "I can take the caching layer; sketching an approach"
- 2026-07-29 10:15: GitHub push of 4 commits with caching implementation
- 2026-08-01 14:00: GitHub comment "Added benchmarks; caching saves ~200ms per request in testing"
- 2026-08-02 11:30: Calendar event: "Performance optimization pair programming"
- 2026-08-06 16:45: GitHub push of database query optimization
- 2026-08-07 09:00: PR merged

## 💬 Sources
### Jira Comments
- 0 comments

### GitHub PR/Reviews
- 4 comments, 8 commits | [View PR #1920](https://github.com/company/repo/pull/1920)

### Slack
- 2 updates in #engineering: "Starting on caching", "Benchmarks look great"

### Email
- 0 threads

### Calendar
- 1 pair programming session (2026-08-02)

### Related PRs
- Contributed commits to #1921 (database layer) and #1919 (API optimization)
```

**What You Learn:**
- Jordan showed initiative and broke the work into manageable pieces (caching, then DB queries)
- They measured impact with benchmarks (200ms improvement), showing rigor
- They worked with teammates (pair programming on 2026-08-02)
- Delivery was timely: 1 week from first comment to merge
- The scope was non-trivial (8 commits, multiple PRs), good for a growing contributor
- Their communication was clear (stated intent → shipped → measured results)

---

## Tips for Interpreting Person Activity Reports

1. **Timeline Density**: Lots of activity in a short window = urgency or high engagement. Long gaps = blocked or working async.

2. **Source Variety**: 
   - Jira-heavy: architectural decisions, formal documentation
   - GitHub-heavy: implementation-focused, code-centric
   - Slack-heavy: coordination, quick decisions, unblocking
   - Calendar-heavy: consensus-building, cross-team alignment

3. **Role Signals**:
   - Lots of approvals → reviewer/lead
   - Mix of comments and code → implementer
   - Lots of questions → learning/clarifying
   - Links to references/docs → knowledge-sharing

4. **Status Inference**:
   - Latest activity is recent + positive = likely on track or complete
   - Latest activity is old or questioning = possibly blocked or awaiting next step
   - Latest activity from others after theirs = handoff (they're done, others are next)

5. **Risk Flags**:
   - No calendar events for big decisions = maybe informal alignment (lower risk if the person is experienced)
   - All email threads, no code = specs/planning, likely needs implementation phase
   - Large number of review rounds = complexity or iterative refinement (can be healthy)

---

## Running These Examples

To test the skill with real data:

```bash
# Test with your own work item
person-activity

# Or if scripted:
WORKITEM_TYPE=jira WORKITEM_ID=DC-443 PERSON_EMAIL=marco@company.com person-activity
```

See the main `SKILL.md` for usage notes on credentials and optional data sources.
