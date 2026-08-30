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
- **Repo-agnostic**: reads each repo's own verification gate and conventions from its `CLAUDE.md`

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

The skill is repo-agnostic. Each repo tells it how to verify work by adding a section to its
`CLAUDE.md` — without this the agent will not know the folder exists, and will not find or update
a runbook unless told to by hand every time:

```markdown
## AI Migration Runbooks

Large refactors that span multiple sessions are tracked as runbooks in `tools/ai-migrations/`.
`tools/ai-migrations/README.md` is the index — check it before proposing work that may already
be planned there.

Use the `ai-migration` skill to create, resume, update or complete one. When a stage lands,
update its runbook in the same change; do not edit a runbook's status or stage table by hand
without it.

Conventions this repo supplies to that skill:

| Thing             | This repo                                        |
| ----------------- | ------------------------------------------------ |
| Project names     | `<command that lists projects>`                  |
| Verification gate | `<what CI runs>`                                 |
| Gate gap to close | `<the check CI skips, and the bar to hold to>`   |
| Change reference  | PR number, or commit sha                         |
| Ticket prefix     | `<tracker prefix, if any>`                       |
| Off-limits        | `<tool-generated subtrees to leave alone>`       |
```

## Usage

The skill fires on its own from phrases like these, and is also invocable as `/ai-migration`:

| You say                                        | What happens                                                     |
| ---------------------------------------------- | ---------------------------------------------------------------- |
| "make an ai migration for this"                | Creates a runbook from the conversation, asking only what it must |
| "carry on with the auth0 migration"            | Reads it, re-verifies its inventory, names the next stage         |
| "what migrations are in flight"                | Reads the index                                                   |
| _(a stage lands)_                              | Writes the dated note, deviations, stage row, progress, index     |
| "that migration is done"                       | Outcome, archive to `done/`, fixes inbound links                  |
| "audit the runbooks"                           | Validates the set; suggests folder merges for you to decide       |

### Do you need plan mode?

Usually not — a well-specified stage is already planned, and re-planning it burns context and
invites drift. Use plan mode when the runbook does not carry its own weight, and then write the
result **back into the runbook** rather than keeping it as a throwaway execution plan.

## Runbook layout

Runbooks live in `tools/ai-migrations/`, in folders that name the thing being changed — a domain,
an app, a subsystem — with a catch-all for cross-cutting cleanup and a `done/` archive. Each opens
with YAML frontmatter and three lines a human reads first:

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

| Path                       | Purpose                                               |
| -------------------------- | ----------------------------------------------------- |
| `skills/ai-migration/`     | The skill: five modes, the format rules, the hard rules |
| `skills/ai-migration/references/` | The blank runbook template, copied on create   |

## License

MIT
