---
description: Show which AI-migration runbooks are in flight, where each one stands and what is ready to pick up.
when_to_use: Use when the user asks how migration or refactor work is going - "what's the status", "what migrations are in flight", "how far along is the auth0 migration", "what's blocked", "what runbooks do we have", "what should I pick up next".
argument-hint: "[runbook-path-or-name]"
effort: low
allowed-tools: Read, Glob, Grep, Bash(${CLAUDE_PLUGIN_ROOT}/scripts/runbooks.sh:*)
---

# Runbook status

Report where the tracked migrations stand. **This command is read-only** — it never
edits a runbook, the index, or anything else. Creating, resuming, updating and
completing runbooks is the `ai-migration` skill's job; if the user wants any of
those, hand off to it rather than doing it here.

It also does **not** re-run inventory sweeps. Re-verifying a runbook's counts
against the code is [Resume](../skills/ai-migration/SKILL.md), and it is far too
expensive for a status glance. Everything below reads the runbooks as written and
says how stale they are, which is a different and cheaper claim.

## Arguments

- `[runbook-path-or-name]` (optional): a path, or any fragment of a runbook's
  filename or title. Given one, show the detail view for the single matching
  runbook. Given none, show the overview.

## Process

### 1. Resolve the folder

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/runbooks.sh" resolve
```

Prints the runbook folder, relative to the repo root. It checks
`$AI_MIGRATION_DIR`, then the `Runbook folder` row in the repo's `CLAUDE.md`,
then probes `docs/ai-migrations`, `tools/ai-migrations`, `.ai-migrations` and
`ai-migrations` in that order.

**Exit 1 means this repo has no runbooks yet.** Do not go hunting with Glob. Say
so and stop:

```
No runbook folder in this repo.

The ai-migration skill will create one the first time you track something -
"make an ai migration for this". The default is docs/ai-migrations/.
```

### 2. Read every runbook

One call gives you the whole set:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/runbooks.sh" list
```

Tab-separated, one row per active runbook: **path, status, updated,
days-since-update, tracking, title, progress**. `-` means the runbook does not
set that field. The archive is excluded, as are tool-generated subtrees like
`@nx/`.

The `progress` column is the runbook's own `**Progress**` line, joined across
wraps. That line is the whole point of the format — quote it rather than
paraphrasing it, and never invent one for a runbook whose column reads `-`.

For the completed count, and only if the user asks what has been finished:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/runbooks.sh" archived
```

### 3. Check the index for drift

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/runbooks.sh" index
```

The index README's table rows. Compare against step 2 and report any
disagreement — a runbook the index does not list, an index row for a file that
has moved to `done/`, or a status that differs between the two. **Report it, do
not fix it.** The fix is an `ai-migration` Audit or Update pass, which is what to
offer.

### 4. Report

Group by what the reader can act on, not alphabetically. Order the groups:
**In progress**, **Blocked**, **Ready**, **Planned**. Within a group, most
recently updated first.

```
Runbooks in docs/ai-migrations - 4 active, 2 completed

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

In progress (1)
  → Remove the home-grown authentication stack in favour of Auth0   [COD-1234]
    auth/migrate_to_auth0.md · updated 1 day ago
    5 of 8 stages landed (latest: stage 5, 2026-08-30, #4127).
    Next: stage 6, ready and unblocked.

Blocked (1)
  ✗ Audit and prune unused dependencies
    tech-debt/audit_deps.md · updated 183 days ago  ⚠ stale
    Pass 2 stalled. Blocked on the platform team confirming the lockfile policy.

Ready (1)
  ○ Delete the legacy signup residue
    auth/fix_signup_residue.md · updated 12 days ago

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Ready to pick up: auth/fix_signup_residue.md
Blocked on someone else: 1
```

Rules for that output:

- **Completed runbooks are a count, never a list.** A repo that has been doing
  this a while has dozens, and nobody reads the list.
- **Flag anything not updated in 30+ days** with `⚠ stale`. The runbook's counts
  are a dated snapshot; past a month the `**Progress**` line is a claim about the
  past, not the present. Say so rather than presenting it as current.
- **Flag malformed runbooks separately.** A row whose status is `-` has no usable
  frontmatter and cannot be placed in a group. List those under
  `Needs frontmatter (N)` and suggest an `ai-migration` audit.
- A status outside `planned | ready | in-progress | blocked | done | abandoned`
  goes in the malformed group too, named so the user can see the typo.
- End with what is actionable. If nothing is ready and everything is blocked, say
  that plainly — it is the most useful thing the report can tell anyone.

### 5. Detail view, when given an argument

Match the argument against the path and title columns from step 2. No match: say
so and show the overview instead. More than one: list the matches and ask which.

On a match, read that one file and report:

- The header block: title, status, `**Progress**` line verbatim.
- The `## Stages` table as it stands, or `## Requirements` for single-PR work.
- Anything unresolved in `## Before you start` — this is the highest-value thing
  on the page and the easiest to miss.
- `## Open items needing an owner`, if present.
- Its `counterpart:`, if it has one, flagged as not-read: the other repo's file
  is the source of truth for its own side, and this command does not cross repos.

Close the detail view with the next stage and its blockers, then note that
`/ai-migration` (Resume) is what actually re-verifies and starts it.
