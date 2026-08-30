---
status: planned # planned | ready | in-progress | blocked | done | abandoned
created: YYYY-MM-DD
updated: YYYY-MM-DD
projects: [] # this repo's project names, per its CLAUDE.md
tracking: # COD-1234, or delete this line
counterpart: # path to the paired runbook in another repo, or delete this line
---

# <Imperative title — what this does, not what it is about>

**Summary** — one paragraph. What changes and why, readable by someone who has not seen the
code. No jargon that the Context section has not earned yet.

**Affects** — the projects and directories in prose. Name anything the `projects:` list cannot
express: tenant config, infra, a sibling repo, stored data.

**Progress** — where it stands and what to do next. Update this every time anything lands.

## Before you start

_Delete this section if nothing blocks. Keep it here, at the top, if anything does._

Open questions that need a human, and pre-flight checks that cannot be answered from the repo.
Each one says who can answer it and what happens if the answer is unfavourable. If anything here
is unresolved, `status:` is `blocked`.

Environment preconditions go here too — the branch to be on, sibling repos that must be checked
out and current, codegen that must be re-run. Give the command that checks it: reading the wrong
branch produces confidently wrong answers rather than obvious errors.

## Context

Why this exists. What is wrong today, what it costs, and why now. Be honest about severity — an
agent that oversells a cleanup as a bug wastes a reviewer's time.

## Decisions

Dated and attributed, so a later agent knows what is settled and what is still open:

**Decision (Alex, YYYY-MM-DD):** …

Rejected alternatives belong here too, with the reason they were rejected — that is what stops
the next agent proposing them again.

When a decision turns out to have rested on a wrong premise, append a correction beneath it and
leave the original standing:

> **Correction (YYYY-MM-DD):** … the premise this rested on was wrong, so verify before relying
> on it elsewhere.

## Inventory

A sweep of the current surface, **as of YYYY-MM-DD**, plus the commands that regenerate it.
Counts and line numbers drift — re-run these before starting, do not trust the table.

```bash
rg -l '<pattern>' apps libs
```

| Thing | Where | Fate |
| ----- | ----- | ---- |

## Stages

_For work that spans more than one PR. Single-PR work deletes this and uses `## Requirements`._

Each stage is independently mergeable and leaves the repo green and deployable.

| Stage | Scope | Status        |
| ----- | ----- | ------------- |
| 1     | …     | `Not started` |

Status vocabulary: `Not started`, `Ready`, `In progress`, `Landed <date> (#PR)`,
`Blocked on <what>`, `Deferred — <why>`, `Abandoned — <why>`.

### Stage 1 — …

What to do, and the commands that finish it. When it lands, add the dated note here:
`**Landed YYYY-MM-DD** (#NNNN).` — along with anything discovered that changes a later stage,
and any negative result worth not rediscovering.

## Requirements

_For single-PR work. Delete if using `## Stages`._

The end state, as a numbered list of things that must be true when this is done.

## Constraints

Explicit do-nots, each with the reason. A constraint without a reason gets ignored or
"improved" by the next agent.

## Verification

Commands that mechanically prove the work is done, with the output to expect:

```bash
yarn nx affected -t test,lint,typecheck --skip-nx-cache
bash script/typecheck.sh <project>/tsconfig.spec.json <project>/   # specs are not typechecked above
```

Then prove the tests are not vacuous: break the code they cover, confirm they go red, revert.

## Follow-ups / Out of scope

What is deliberately not being done here, and where it went instead.

## Open items needing an owner

_Delete if everything is inside this repo._

Blockers nobody working in this repo can clear: a PR needed in a sibling repo, a missing design
decision, an infra rename. Name what is blocked and who can unblock it.

## Keeping this file current

Update this file as the work happens, not afterwards — it is the handover to the next session.
Progress lives in the `**Progress**` line and the stage table; there are no checkboxes. Append
corrections, never rewrite history.

Use the `ai-migration` skill (`.claude/skills/ai-migration/`) to update or complete this runbook.
