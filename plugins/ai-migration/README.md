# AI Migration Plugin

A Claude Code plugin for tracking large refactors as **runbooks** — markdown files that carry a
piece of work across many sessions, many agents and many PRs.

A runbook is the memory: what was decided and why, what was already tried and rejected, what is
left, and how to prove it works. Agents come and go; the runbook stays.

## Features

- **Create from a conversation**: you are discussing code, something is worth fixing, it is too
  big for now — the skill harvests the scope already in context, verifies it against the repo,
  and asks only what it genuinely cannot infer
- **Resume without pasting**: reads the runbook from disk, so it knows the path and can write
  progress back when a stage lands
- **Re-verifies before trusting**: every inventory in a runbook is a dated snapshot that drifts —
  the skill re-runs the sweeps and reports what moved
- **Records what actually shipped**: the dated landing note, the deviations from plan, and the
  negative results worth not rediscovering
- **Cross-repo aware**: runbooks in different repos pair via a `counterpart:` link
- **Repo-agnostic**: no fixed folder — it resolves where the runbooks live from your
  `CLAUDE.md`, and reads each repo's own verification gate and conventions from there too
- **Status at a glance**: `/ai-migration:status` reports what is in flight, what is blocked and
  what is ready to pick up, without re-running a single sweep

## Installation

First, add the marketplace to Claude Code:

```bash
/plugin marketplace add casualgenius/claude-plugins
```

Then install this plugin:

```bash
/plugin install ai-migration
```

Or with explicit marketplace (if you have multiple marketplaces):

```bash
/plugin install ai-migration@casualgenius-plugins
```

## Per-repo setup

The skill is repo-agnostic. Each repo tells it where its runbooks live and how to verify work,
by adding a section to its `CLAUDE.md`:

```markdown
## AI Migration Runbooks

Large refactors that span multiple sessions are tracked as runbooks in `docs/ai-migrations/`.
`docs/ai-migrations/README.md` is the index — check it before proposing work that may already
be planned there.

Use the `ai-migration` skill to create, resume, update or complete one, and
`/ai-migration:status` to see what is in flight. When a stage lands, update its runbook in the
same change; do not edit a runbook's status or stage table by hand without it.

Conventions this repo supplies to that skill:

| Thing             | This repo                                        |
| ----------------- | ------------------------------------------------ |
| Runbook folder    | `docs/ai-migrations/`                            |
| Project names     | `<command that lists projects>`                  |
| Verification gate | `<what CI runs>`                                 |
| Gate gap to close | `<the check CI skips, and the bar to hold to>`   |
| Change reference  | PR number, or commit sha                         |
| Ticket prefix     | `<tracker prefix, if any>`                       |
| Off-limits        | `<tool-generated subtrees to leave alone>`       |
```

The `Runbook folder` row is the one that matters most. Without it the plugin falls back to
probing for `docs/ai-migrations`, `tools/ai-migrations`, `.ai-migrations` and `ai-migrations`,
in that order — which works, but means a repo with runbooks in two places can be read from the
wrong one. Declaring it settles the question. `$AI_MIGRATION_DIR` overrides both.

Everything else in the table is what the skill needs in order to verify work rather than assume
it. Without the section at all, the agent will not know the folder exists and will not find or
update a runbook unless told to by hand every time.

## Usage

The skill fires on its own from phrases like these, and is also invocable as `/ai-migration`:

| You say                                        | What happens                                                     |
| ---------------------------------------------- | ---------------------------------------------------------------- |
| "make an ai migration for this"                | Creates a runbook from the conversation, asking only what it must |
| "carry on with the auth0 migration"            | Reads it, re-verifies its inventory, names the next stage         |
| `/ai-migration:status`                         | Read-only report: in flight, blocked, ready to pick up            |
| `/ai-migration:status auth0`                   | Detail on one runbook: stages, blockers, what is next             |
| _(a stage lands)_                              | Writes the dated note, deviations, stage row, progress, index     |
| "that migration is done"                       | Outcome, archive to `done/`, fixes inbound links                  |
| "audit the runbooks"                           | Validates the set; suggests folder merges for you to decide       |

### Status

`/ai-migration:status` reads what the runbooks claim and reports it. It never edits anything and
never re-runs an inventory sweep — that is [Resume](#usage), and it is far too expensive for a
glance. What it does instead is tell you how old each claim is:

```
Runbooks in docs/ai-migrations - 3 active, 2 completed

In progress (1)
  → Remove the home-grown authentication stack in favour of Auth0   [COD-1234]
    auth/migrate_to_auth0.md · updated 1 day ago
    5 of 8 stages landed (latest: stage 5, 2026-08-30, #4127).
    Next: stage 6, ready and unblocked.

Blocked (1)
  ✗ Audit and prune unused dependencies
    tech-debt/audit_deps.md · updated 183 days ago  ⚠ stale
    Pass 2 stalled. Blocked on the platform team confirming the lockfile policy.

Ready to pick up: auth/fix_signup_residue.md
```

Completed runbooks are a count, not a list. Anything untouched for 30+ days is flagged stale,
because a runbook's numbers are a dated snapshot and a month-old `**Progress**` line is a claim
about the past. Disagreements between a runbook and the index are reported, not silently fixed.

### Do you need plan mode?

Usually not — a well-specified stage is already planned, and re-planning it burns context and
invites drift. Use plan mode when the runbook does not carry its own weight, and then write the
result **back into the runbook** rather than keeping it as a throwaway execution plan.

## Runbook layout

Runbooks live in the folder your `CLAUDE.md` declares — `docs/ai-migrations/` by default — in
subfolders that name the thing being changed: a domain, an app, a subsystem, with a `tech-debt/`
catch-all for cross-cutting cleanup and a `done/` archive. Each opens with YAML frontmatter and
three lines a human reads first:

```markdown
---
status: in-progress # planned | ready | in-progress | blocked | done | abandoned
created: 2026-08-29
updated: 2026-08-31
projects: [connect-app-api, util-auth]
---

# Remove the home-grown authentication stack in favour of Auth0

**Summary** — what this does and why, readable by someone who has never seen the codebase.

**Affects** — the projects and directories, including what the project list cannot express.

**Progress** — where it stands and **what to do next**.
```

Progress lives in a `## Stages` table for multi-PR work, or the `**Progress**` line for a single
PR. The status vocabulary is closed: `Not started`, `Ready`, `In progress`, `Landed <date> (#PR)`,
`Blocked on <what>`, `Deferred — <why>`, `Abandoned — <why>`.

**There are no checkboxes.** They were tried and left 77 unticked across two archived runbooks in
a folder called `done`.

## Structure

| Path                              | Purpose                                                  |
| --------------------------------- | -------------------------------------------------------- |
| `skills/ai-migration/`            | The skill: five modes, the format rules, the hard rules   |
| `skills/ai-migration/references/` | The blank runbook template, copied on create              |
| `commands/status.md`              | `/ai-migration:status` — the read-only progress report    |
| `scripts/runbooks.sh`             | Folder discovery and frontmatter parsing, in one place    |

## License

MIT
