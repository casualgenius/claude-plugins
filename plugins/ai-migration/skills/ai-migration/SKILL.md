---
name: ai-migration
description: >-
  Create, resume, update or complete an AI-migration runbook — the markdown files in this
  repo's runbook folder that track multi-session refactors and tech-debt work.
  Use when the user says "make an ai migration for this", "turn this into a runbook", "add this
  to the runbook", "carry on with the auth0 migration", "that migration is done", "audit the
  runbooks", when a stage of a tracked migration lands, or whenever reading or editing any file
  under the runbook folder. For a read-only report of what is in flight, prefer the
  /ai-migration:status command.
---

# AI migration runbooks

A runbook is a markdown file that carries a large refactor across many sessions and many PRs.
It is the memory: what was decided and why, what was already tried and rejected, what is left,
and how to prove it works. Agents come and go; the runbook stays.

## Where the runbooks live

**There is no fixed path.** Resolve the folder before doing anything else:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/runbooks.sh" resolve
```

It prints the folder relative to the repo root, checking in order:

1. `$AI_MIGRATION_DIR`.
2. The `Runbook folder` row in the repo's `CLAUDE.md`, under "AI Migration Runbooks". A repo
   that declares where its runbooks live is never overruled by a folder that merely happens to
   exist under one of the probed names.
3. An existing `docs/ai-migrations`, `tools/ai-migrations`, `.ai-migrations` or `ai-migrations`.

**Exit 1 means this repo has no runbook folder yet.** Only [Create](#create) may act on that,
and only by asking — propose `docs/ai-migrations/`, and once the user has picked, have them add
the `Runbook folder` row to their `CLAUDE.md` so every later session resolves it without
probing. Never create the folder silently, and never assume a path you have not resolved.

Below, `<runbooks>` means whatever that resolved to. The index is always `<runbooks>/README.md`.

## Hard rules

- **Read the repo's own conventions first.** Each repo records its verification gate, its
  project-listing command and any off-limits subtrees under "AI Migration Runbooks" in its
  `CLAUDE.md`. Use those, not the examples in this skill.
- **Never touch a tool-generated subtree** inside the runbook folder. Some tools write their own
  upgrade notes there and pin the path in their config; `<runbooks>/@nx/` in an NX monorepo is the
  example. Leave them alone and do not apply these conventions to them.
- **Never commit** unless explicitly asked. Write the files, report, stop.
- **Never introduce a checkbox.** They were tried here and left 77 unticked in `done/`. Progress
  lives in the stage table and the `**Progress**` line, nowhere else.
- **Append corrections, do not rewrite history.** A runbook records what was believed at the
  time. When something turns out to be wrong, add a dated correction under the original text and
  leave the original standing — the next agent needs to know the claim was made and why it fell.
- **Ask before creating a folder**, and before merging or splitting existing ones.
- **Re-verify before trusting.** Every inventory in every runbook is a dated snapshot. Counts and
  line numbers drift. Re-run the commands.

## Which mode

| The user is…                                            | Mode                  |
| ------------------------------------------------------- | --------------------- |
| Describing work worth tracking — "make an ai migration" | [Create](#create)     |
| Picking up tracked work — "carry on with X"             | [Resume](#resume)     |
| Reporting a landed stage, or you just landed one        | [Update](#update)     |
| Finishing the last stage                                | [Complete](#complete) |
| Asking what is in flight, or how work is going          | `/ai-migration:status` |
| The folders look messy, or links may have rotted        | [Audit](#audit)       |

`/ai-migration:status` is read-only and cheap: it reads what the runbooks claim and reports it.
Audit is a validator that re-checks the set against the repo. Do not run an audit when someone
only asked how things are going.

---

## Create

The common case is mid-conversation: you have been discussing code, something is worth fixing,
and it is too big for now. Most of the scope is already in the conversation — harvest it rather
than re-interrogating the user.

1. **Draft the scope from context.** What is wrong, which files, what the end state is.
2. **Verify it against the repo before writing.** Do not trust the conversation's file list.
   Run the sweeps that will become the `## Inventory` section, and check project names:
   ```bash
   <the repo's project-listing command, from its CLAUDE.md>
   rg -l '<the pattern that defines scope>' <source roots>
   ```
3. **Ask only what you genuinely cannot infer**, via `AskUserQuestion`, in one batch:
   - The end state in one sentence, if the conversation left it ambiguous.
   - One PR or several stages? If several, what splits them and what gates each?
   - Anything explicitly **out** of scope or not to be touched? (The Auth0 runbook's permanent
     `connect-admin-api` exclusion is the pattern — a negative decision recorded once saves an
     agent from "finishing the job" later.)
   - Is there a ticket? (Use the repo's ticket prefix from its `CLAUDE.md`.)
   - **Which folder** — list the existing ones, recommend the best fit, propose a new one only
     when nothing fits. The user decides.
4. **Write the file** from `references/template.md` into the chosen folder, named `snake_case.md`,
   verb-first (`migrate_`, `fix_`, `audit_`, `consolidate_`, `dedupe_`, `add_`).
5. **Add the README row.**
6. If the folder did not exist until now, tell the user to add the `Runbook folder` row to
   their `CLAUDE.md` — without it the next session has to fall back to probing.
7. Report the path. Do not commit.

If the work is small enough to finish in the current session, say so and offer to just do it — a
runbook for a 20-minute fix is overhead, not memory.

---

## Resume

"Carry on with X", or any session that starts by opening a runbook. **The runbook is the plan** —
read it from the file rather than asking the user to paste it, so you know its path and can write
progress back when the stage lands.

1. Read the whole runbook, including `## Before you start` — if it holds an unresolved question,
   that is the first thing to raise, not something to discover at the point of blocking.
2. **Check the environment preconditions first**, if the runbook names any: the right branch, a
   sibling repo checked out, generated code up to date. A runbook read against the wrong branch
   gives confidently wrong answers.
3. **Re-run the inventory commands.** The counts in the file date from the last sweep. Report the
   delta if it moved; if it moved a lot, update the inventory and its date before starting work.
4. If the runbook has a **counterpart** in another repo, re-read it. Stage numbers and status
   drift on both sides, and the local file's summary of the other one is a copy, not a source.
5. Report where the work actually stands versus what the file claims, and name the next stage.
6. Do the stage. When it lands, switch to [Update](#update).

### Do you need plan mode?

Usually not — a well-specified stage is already planned, and re-planning it burns context and
invites drift from the runbook. Go straight to executing it.

Use plan mode when the runbook does not carry its own weight: the stage is a sketch rather than a
spec, the inventory came back materially different from what the file claims, or an open decision
in `## Before you start` changes what the stage even is. In that case the output of planning is an
**update to the runbook**, not just an execution plan — write it back before starting.

---

## Update

After a stage lands — run this without being asked when a PR you drove came from a runbook.

1. Add a dated bold note to that stage — `**Landed 2026-09-02** (#4131).` — in its heading or the
   paragraph under it. Cite whatever identifies the change in this repo: a PR number, or a commit
   sha where the repo does not use PR numbers.
2. Record, in that same note, a short **"what shipped that differs from the plan"**. This is the
   highest-value thing you will write all session, and it is the first thing skipped:
   - anything discovered that **changes a later stage**;
   - anything the stage had to pull forward or leave behind, and why;
   - any **negative result** worth not rediscovering — "tried X, reverted, do not retry without
     new evidence" — with enough detail to reproduce the finding;
   - any correction to an earlier claim, as a blockquote under the original.
3. **If the plan text below the note is now wrong, say so in the note** rather than editing the
   plan to match what happened. "The fix below is not what shipped, and the plan to vendor two
   faces was unnecessary" tells the next reader more than a silently corrected plan does.
4. **"Landed" alone is not enough when the stage body holds a "current state" snapshot.** That
   snapshot then becomes the only concrete numbers on the page, and the next reader takes it as
   present-day fact. Either say what the values became, or mark the snapshot as pre-work. This has
   already produced a wrong conclusion: a stage that raised `targetSdk` from 33 to 36 recorded only
   "Landed 2026-08-30 (forced early)", and a later pass read the untouched pre-work line and
   reported the work as still outstanding.
5. Flip the row in the `## Stages` table, and unblock whatever that stage was gating.
6. Bump `updated:` in the frontmatter and rewrite the `**Progress**` line in the header.
7. Update the runbook's row in the index README.
8. **If the runbook has a counterpart in another repo**, check whether this stage changed anything
   it asserts — especially stage numbers, which drift the moment either side renumbers.

---

## Complete

The last stage has landed.

**Write the outcome from the code, not from the runbook.** A runbook is full of "current state"
inventories captured _before_ each stage ran; quoting one into an outcome section states the
problem as though it were the result. Re-check every factual claim against the files, and say what
you verified and when.

1. **Put a completion banner at the very top**, directly under the H1, as a blockquote — before
   anyone reads a word of the now-historical body:

   ```markdown
   > **Landed 2026-08-30. This migration is complete; the document is kept as a record.**
   > <one or two lines on what is true now.>
   >
   > **Everything below the Context section was written before the work and is now historical.**
   > In particular <the section that is now actively misleading> no longer applies. Read
   > "What actually happened" at the foot of this file for how the plan diverged from execution.
   ```

   A finished runbook's body is full of instructions nobody should follow again and counts that
   are years stale. Saying so at the top is what makes it safe to keep.

2. Add a `## Outcome` (or `## What actually happened`) section at the foot: what shipped, over
   which dates and PRs or commits, how the plan diverged, and — importantly — **what was
   deliberately dropped or left dangling**. Two completed runbooks in the monorepo ended with
   follow-ups that were never raised because nobody wrote them down as outcomes.
3. Any follow-up that still matters becomes its own runbook now, or is recorded in the outcome as
   consciously dropped. Ask the user which.
4. Set `status: done` and add `completed: <date>` to the frontmatter.
5. `git mv` the file into the `done/` folder.
6. **Fix inbound links**, in this repo and in any counterpart repo. Every previous move broke
   references — search before finishing:
   ```bash
   rg -uu -n '<old-filename>' .
   ```
7. Update the index README row (move it to the completed table).

---

## Audit

1. Every runbook has valid frontmatter with the required keys.
2. Every `projects:` entry is a real project, per the repo's project-listing command.
3. Every relative markdown link under `<runbooks>/` resolves, including `counterpart:` paths
   into sibling repos. Skip tool-generated subtrees.
4. Every runbook has exactly one README row, and the statuses agree.
5. No `../../../` paths, no `## Testing` heading, no checkboxes, no "Phase"/"batch" used as a
   unit of work.
6. **The resolved folder is the declared one.** If `runbooks.sh resolve` fell through to probing,
   the repo's `CLAUDE.md` has no `Runbook folder` row — say so, and offer to add it. If it
   resolved from `CLAUDE.md` but a second candidate folder also exists, that is a split set of
   runbooks and needs saying out loud.
7. **Folder health.** Suggest — never perform — a merge or split when a folder passes ~8 files,
   or when two folders hold runbooks that keep touching the same projects. Present the case and
   let the user decide.

---

## The format

`references/template.md` is the skeleton to copy. The rules behind it:

### Header

Frontmatter, then H1, then three bold lines. This is what a human reads first and what the index
is built from.

```markdown
---
status: in-progress # planned | ready | in-progress | blocked | done | abandoned
created: 2026-08-29
updated: 2026-08-31
projects: [connect-app-api, connect-next-api, util-auth] # this repo's own project names
tracking: COD-1234 # omit if none
counterpart: ../ypb-tech-whitelabel-app/docs/ai-migrations/migrate_app_to_auth0.md
---

# Remove the home-grown authentication stack in favour of Auth0

**Summary** — one paragraph: what this does and why, readable by someone who has never seen the
codebase.

**Affects** — the projects and directories, in prose. May name things the `projects:` list
cannot express, like tenant config or a sibling repo.

**Progress** — where it stands and **what to do next**. "5 of 8 stages landed (latest: stage 5,
2026-08-30, #4127). Next: stage 6, ready and unblocked." Never make the reader hunt for this.
```

`status: blocked` whenever `## Before you start` holds an unresolved question. Say what blocks it
in the `**Progress**` line.

### Section order

| Section                          | Required                   | Purpose                                                                                    |
| -------------------------------- | -------------------------- | ------------------------------------------------------------------------------------------ |
| `## Before you start`            | when anything blocks       | Open questions, pre-flight checks, environment preconditions. **Near the top, never last** |
| `## Context`                     | yes                        | Why this exists, what is wrong today                                                       |
| `## Decisions` / `## Options`    | when any were made         | Dated and attributed; corrections appended beneath                                         |
| `## Inventory`                   | when scope is wide         | Dated sweep **plus the commands to regenerate it**                                         |
| `## Baseline`                    | when CI cannot judge it    | The known-good starting state, so you can tell what you broke                              |
| `## Stages` / `## Requirements`  | yes                        | Stage table for multi-PR work; numbered end-goal list for one                              |
| `## Constraints`                 | when there are traps       | Explicit do-nots, each with its reason                                                     |
| `## Verification`                | yes                        | Commands that prove it is done, **plus what they cannot prove**                            |
| `## Follow-ups / Out of scope`   | optional                   | What is deliberately not being done here                                                   |
| `## Open items needing an owner` | when work escapes the repo | Blockers nobody here can clear — a sibling repo, design, infra                             |
| `## Keeping this file current`   | yes                        | Three lines pointing at this skill                                                         |

Three of these earn their place more often than they look:

- **`## Options`** — when the approach is genuinely undecided, lay the alternatives out before the
  stages and have the stage list say which one it assumes (`## Stages (assumes Option A)`). It
  stops the next agent silently re-deciding.
- **`## Baseline`** — the known-good starting state, verified and dated, before anything changes.
  On work CI cannot judge (anything visual, anything about performance) it is the only way to tell
  a regression from a deliberate change.
- **`## Open items needing an owner`** — distinct from follow-ups. These are things blocking _this_
  runbook that nobody working in this repo can clear: a PR needed in a sibling repo, a missing
  design token, an infra rename. Listing them keeps them from being rediscovered as surprises
  mid-stage.

Say when partial completion is acceptable. "Stopping after stage 5 is a legitimate outcome" is
real information — it tells the next agent the remaining stages are optional polish, not an
unfinished job.

### Progress

Multi-stage work gets a table directly under the header:

```markdown
## Stages

| Stage | Scope                        | Status                              |
| ----- | ---------------------------- | ----------------------------------- |
| 1     | Canva v1 removal             | **Landed** 2026-08-29 (#4123)       |
| 6     | Dead signup residue          | **Ready** — blocked on nothing      |
| 7     | app-api: delete legacy login | **Blocked on mobile** (SDK release) |
```

The status vocabulary is closed: `Not started`, `Ready`, `In progress`, `Landed <date> (#PR)`,
`Blocked on <what>`, `Deferred — <why>`, `Abandoned — <why>`.

`Blocked` means something external prevents it. `Deferred` means it could be done and someone
chose not to yet — record who decided and why, or the next agent will just start it.

Single-shot work skips the table — the `**Progress**` line carries it.

### Vocabulary

One meaning per word, because these files get read two at a time:

- **Stage** — an independently-mergeable unit of work, one PR. The only word for this.
- **Step** — an ordered action inside a stage.
- **Pass** — one iteration of a recurring triage runbook. Only `audit_dependency_cleanup.md`.

"Phase" and "batch" are retired. "Tier" is fine only where the file defines it.

### Verification sections

Name commands that mechanically prove the work is done, and say what output to expect. **Take the
repo's own gate from its `CLAUDE.md`** rather than inventing one — that is where each repo records
the commands CI actually runs.

Three things worth writing into most runbooks:

- **Prove the tests are not vacuous.** Break the code the test covers, confirm it goes red,
  revert. State the expected failure count where you can.
- **Say what the automated gate cannot prove**, and give a numbered manual walkthrough for it.
  A linter will not catch a wrong colour, a missing font weight, a broken redirect or a permission
  dialog with the wrong copy. If a stage can only be judged by a human on a device, write the
  script they should follow — "trigger the permission dialog and **read it**" — because "verified"
  otherwise means "it compiled".
- **Name the gaps in the type/test gate.** Most repos have one: a typecheck that skips test files,
  a test run that skips generated code, a CI job that skips a platform. Write the extra command
  that closes it, and the bar to hold it to ("no _new_ errors").

### Cross-repo runbooks

A migration that spans repos gets **one runbook per repo**, each owning its own side, linked by
`counterpart:` in the frontmatter. Do not try to drive both from one file — the stages land in
different repos on different schedules.

Rules that keep the pair honest:

- **Never restate the counterpart's stage numbers as fact.** Say what you depend on, not its
  number: "blocked until the backend deletes legacy login" rather than "blocked on its stage 6".
  Numbers get renumbered, and a stale number reads as authoritative. This has already happened
  once between these two repos.
- Re-read the counterpart when resuming, and again when a stage lands that changes what the other
  side sees.
- Record which side must ship first, and why. "Delete the client callers first, or an old build
  gets a 404 instead of a clean auth failure" is the kind of ordering that is expensive to
  rediscover.

### Environment preconditions

When a runbook's references only make sense on a particular branch or with sibling repos checked
out, say so at the top with a command to check it. Reading the wrong branch produces confidently
wrong answers rather than obvious errors.

Two traps that have already cost real time here:

- **`grep` may not be plain grep.** In this environment it is a ugrep wrapper run with
  `--ignore-files`, so it honours `.gitignore` and silently skips generated files. It has reported
  a rename "clean" while 77 stale references remained. Use `rg -uu` for any sweep that must
  include ignored or generated files.
- **Generated code is not in the sweep.** After a rename, regenerate mocks/codegen before trusting
  a local test run.

### Paths and snapshots

Repo-root-relative, in backticks: `` `libs/frontend/src/plugins/dompurify.ts` `` — never
`` `../../../libs/…` ``, which is noise that breaks on the next folder move. Only genuine
markdown links between runbooks stay relative: `[the audit](../tech-debt/audit_dependency_cleanup.md)`.

Every inventory carries `as of <date>` and the command that regenerates it. Never hardcode a
workspace-wide project count — derive it. Pin line numbers only alongside a symbol name that
survives them.

### Folders

A folder names **the thing being changed** — a domain (`auth/`), an app (`qr-handler/`), or a
subsystem. `tech-debt/` is the catch-all for cross-cutting cleanup with no natural home.
`done/` is the archive. `@nx/` is not ours.
