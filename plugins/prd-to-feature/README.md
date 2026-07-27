# PRD to Feature Plugin

A Claude Code plugin for PRD-driven feature development. Takes a Product Requirements Document (PRD) and guides you through planning and implementation with automated task tracking.

## Features

- **Automated Planning**: Analyzes PRDs and creates detailed technical implementation plans
- **Task Tracking**: Generates JSON task trackers with dependencies and status
- **Context Isolation**: Each task runs in a fresh agent context (no context compaction issues)
- **Verification Before Commit**: Discovers and runs the project's own checks; nothing commits until they pass
- **Native Skill Discovery**: Agents find and invoke your installed skills automatically
- **Progress Tracking**: Monitor feature completion with the status command

## Installation

First, add the marketplace to Claude Code:

```bash
/plugin marketplace add casualgenius/claude-plugins
```

Then install this plugin:

```bash
/plugin install prd-to-feature
```

Or with explicit marketplace (if you have multiple marketplaces):

```bash
/plugin install prd-to-feature@casualgenius-plugins
```

## Commands

### `/prd-to-feature:plan <prd-path>`

Analyze a PRD and create implementation documents.

```bash
/prd-to-feature:plan docs/my-feature.prd.md
```

Creates:
- `.prd-to-feature/my-feature/implementation.md` - Detailed implementation plan
- `.prd-to-feature/my-feature/tracker.json` - Task tracker for development

The PRD stays at `docs/my-feature.prd.md`.

The planning agent will:
1. Read and analyze your PRD
2. Explore your codebase
3. Ask clarifying questions
4. Generate the implementation plan and task tracker

### `/prd-to-feature:develop [tracker-path]`

Start or continue implementing tasks from a tracker.

```bash
# With explicit path
/prd-to-feature:develop .prd-to-feature/my-feature/tracker.json

# Auto-discover tracker
/prd-to-feature:develop
```

The development loop:
1. Picks the next available task (respecting dependencies)
2. Spawns a fresh agent to implement it
3. Runs all verification checks
4. Commits on success
5. Continues until all tasks are done

Press `Ctrl+C` to stop development at any time.

### `/prd-to-feature:develop-ralph [max-iterations] [min-iterations] [tracker-path]`

Ralph loop variant of develop. Each task gets repeated passes from fresh agents until the work stops being substantive.

```bash
# Defaults: max 10, min 2, auto-discover tracker
/prd-to-feature:develop-ralph

# Cap at 5 iterations
/prd-to-feature:develop-ralph 5

# Max 5, min 3
/prd-to-feature:develop-ralph 5 3

# With an explicit tracker path
/prd-to-feature:develop-ralph 5 3 .prd-to-feature/my-feature/tracker.json
```

Each iteration, the agent reports a **change class**:

- `substantive` - fixed a bug, implemented a missing requirement or acceptance criterion, added error handling, or added tests for one of those
- `polish` - in scope but marginal
- `none` - nothing to commit

The loop stops when two consecutive iterations are non-substantive (having met the minimum), when an iteration produces nothing at all, or at the ceiling. A commit smaller than about ten lines is counted as `polish` regardless of what the agent claimed, so the loop cannot be talked into continuing.

From iteration 2 onward the agent works under a **scope fence**: only correctness, requirements, acceptance criteria, error handling, and test coverage justify a change. Anything else it notices gets recorded as a note on a related task instead of being implemented. Without that fence a capable model always finds one more thing to tidy and the loop never converges.

Other behaviour worth knowing:

- **Session recovery**: the current iteration is persisted in the tracker, so an interrupted run resumes where it left off.
- **Commit history**: each iteration's commit is appended to the task's `commits` array with its iteration number, so you can review how the work evolved.
- **Ceiling exits are flagged**: if a task stops because it hit the ceiling, its last iteration was never reviewed by a subsequent pass, and the report says so.

**When to use:** complex features with many edge cases, critical code paths, or whenever you want maximum quality over speed. It costs several times more than `/develop`.

**Standard develop vs develop-ralph:**

| Aspect | `/develop` | `/develop-ralph` |
|--------|-----------|------------------|
| Iterations per task | 1 | Min 2, ceiling 10 (default) |
| Exit condition | Agent returns | Two consecutive non-substantive passes, or the ceiling |
| Task completion | Agent marks done | Loop marks done once stable |
| Commit tracking | One entry | One entry per iteration |
| Cost | Lower | Higher |
| Quality | Good | Higher |

### `/prd-to-feature:status [tracker-path]`

Check progress on a feature.

```bash
/prd-to-feature:status
```

Shows:
- Overall completion percentage
- Tasks by status (done, in-progress, blocked, todo)
- Available tasks ready to start
- Blocked tasks and their dependencies

### `/prd-to-feature:refine <instructions>`

Modify the implementation plan and task tracker after planning.

```bash
# Combine tasks
/prd-to-feature:refine combine tasks 2 and 3 into a single task

# Split a task
/prd-to-feature:refine split task 5 into "Create API" and "Add tests"

# Update architecture
/prd-to-feature:refine use Redis instead of in-memory caching

# Add phase
/prd-to-feature:refine add a new phase for performance optimization

# Add/remove tasks
/prd-to-feature:refine add a task for API rate limiting after task 3
/prd-to-feature:refine remove task 7
```

Supports:
- **Task operations**: combine, split, add, remove, reorder, update tasks
- **Dependency operations**: add or remove task dependencies
- **Phase operations**: add phases, move tasks between phases
- **Architecture changes**: update tech decisions in implementation.md

## Generated File Location

Feature workflow stores generated files in `.prd-to-feature/` at your project root:

```
.prd-to-feature/
├── user-auth/
│   ├── implementation.md
│   └── tracker.json
└── payment-integration/
    ├── implementation.md
    └── tracker.json
```

Your PRD files stay where you put them. Only the generated implementation plans and trackers go in `.prd-to-feature/`.

### Git Ignore (Optional)

You can add `.prd-to-feature/` to your `.gitignore` if you don't want to track generated files:

```gitignore
# Feature workflow generated files (optional)
.prd-to-feature/
```

Alternatively, commit these files to share implementation plans with your team.

## Project Settings

Create `.claude/prd-to-feature.local.md` to configure project-specific settings:

```markdown
# Feature Workflow Settings

## Database Migrations
- Tool: supabase
- Command: `npx supabase db push`

## Testing Requirements
- Components: Create Storybook stories
- Logic: Create unit tests with Vitest

## Commands
- Typecheck: `npm run typecheck`
- Lint: `npm run lint`
- Test: `npm run test:run`
- Build: `npm run build`

## Git
- Branch prefix: feat/
- Commit style: conventional
```

## Skills

Agents discover skills natively. Both `prd-planner` and `task-developer` have the `Skill` tool, so they see every project, user, and plugin skill installed in your session, along with its description, and invoke the ones that match the work. There is nothing to configure.

The planner records the skill names it judged relevant in each task's `skillHints`:

```json
{
  "id": "task-003",
  "title": "Create login form",
  "skillHints": ["frontend-mobile-development:react-state-management"]
}
```

These are advisory. The developer agent sees the full skill list itself, may invoke skills not listed, and ignores any hint that is no longer installed.

### Reference Docs

Skills cover reusable knowledge, but in-repo convention documents are not skills. Point agents at those with a `## Reference Docs` section in your settings file:

```markdown
## Reference Docs

Read these when the task touches the relevant area:
- React conventions: docs/patterns/react.md
- API error envelope: docs/api/errors.md
- Architecture decisions: docs/adr/
```

## Task Guidelines

Customize how the planner creates tasks by adding a "Task Guidelines" section to your settings file. This is useful for:
- Ensuring tasks match your team's development style
- Controlling task granularity
- Bundling related work (tests, dependencies) into single tasks

### Configuring Guidelines

Add to `.claude/prd-to-feature.local.md`:

```markdown
## Task Guidelines

- Tasks should include unit tests for the code being added
- Dependencies should be added in the tasks that require them, not as separate tasks
- Prefer larger tasks that complete a full vertical slice over small atomic changes
- Create database migrations in separate, early tasks
- Each task should update relevant documentation
```

### Example Guidelines

**For monorepo projects:**
```markdown
## Task Guidelines

- Each task should be scoped to a single package
- Shared utilities go in @repo/shared package
- Create package.json updates as separate prerequisite tasks
```

**For TDD workflows:**
```markdown
## Task Guidelines

- Write failing tests first, then implementation in same task
- Each task must have at least one acceptance test
- Integration tests can be grouped in final phase
```

**For vertical slice architecture:**
```markdown
## Task Guidelines

- Each task implements complete user flow (UI, API, DB)
- Avoid tasks that only touch one layer
- Cross-cutting concerns (auth, logging) are separate foundational tasks
```

### How Guidelines Are Applied

The planner agent:
1. Reads all guidelines before creating tasks
2. Applies guidelines when structuring tasks and dependencies
3. Notes in the implementation plan which guidelines influenced decisions
4. Falls back to defaults only when no guideline applies

### Without Settings File

If no settings file exists, the agent will check `CLAUDE.md` for project instructions or discover verification commands from the project's build configuration (`package.json`, `Makefile`, etc.).

## Workflow

### 1. Write a PRD

Create a Product Requirements Document describing your feature:

```markdown
# User Authentication PRD

## Problem
Users cannot log into the application...

## Solution
Implement email/password authentication using Supabase...

## Requirements
- Login form with email and password
- Password reset flow
- Session management
...
```

### 2. Plan the Implementation

```bash
/prd-to-feature:plan docs/user-auth.prd.md
```

The agent will analyze your PRD, ask questions, and create:
- A detailed Technical Implementation Plan
- A Task Tracker with all tasks and dependencies

### 3. Review the Plan

Check the generated documents:
- Review the implementation plan for accuracy
- Verify task breakdown makes sense
- Adjust if needed (edit the JSON/markdown directly)

### 4. Develop

```bash
/prd-to-feature:develop
```

Tasks are implemented automatically:
- Each task runs in a fresh agent context
- Tests must pass before commits
- Progress is tracked in the JSON file
- Notes are propagated between tasks

### 5. Monitor Progress

```bash
/prd-to-feature:status
```

Check progress at any time to see:
- What's done
- What's in progress
- What's blocked

## Task Tracker Format

```json
{
  "feature": "User Authentication",
  "implementationDoc": ".prd-to-feature/user-auth/implementation.md",
  "phases": [
    {
      "id": "phase-1",
      "name": "Foundation",
      "description": "Set up auth infrastructure"
    }
  ],
  "tasks": [
    {
      "id": "task-001",
      "title": "Configure auth provider",
      "phase": "phase-1",
      "status": "todo",
      "dependsOn": [],
      "notes": [],
      "complexity": "low",
      "skillHints": []
    }
  ]
}
```

Requirements and acceptance criteria live in `implementation.md`, not the tracker. The tracker holds execution state only. The full schema is at `references/tracker-schema.json`.

### Task Statuses

- `todo` - Not started
- `in-progress` - Currently being worked on
- `blocked` - Cannot proceed (dependency or issue)
- `done` - Completed and committed

## Architecture

### Components

| Component | Purpose |
|-----------|---------|
| `prd-planner` agent | Analyzes PRDs and creates plans |
| `task-developer` agent | Implements individual tasks |
| `plan` command | Entry point for planning |
| `develop` command | Entry point for development |
| `develop-ralph` command | Iterative development with ralph loop |
| `status` command | Progress monitoring |
| `refine` command | Post-planning modifications |
| `scripts/tracker.sh` | Tracker reads and per-task state writes, so the jq lives in one place rather than in prompts. `refine` edits the tracker directly, since restructuring tasks is beyond what the script models. |
| `references/` | Plan template and tracker JSON schema, read on demand |

### Why Separate Agents?

Each task runs in a fresh agent instance to solve context compaction issues. When Claude's context window fills up and compacts, important instructions can be lost. By using separate agents per task:

- Each task gets the full context window
- Instructions are embedded in the agent's system prompt
- No context loss during long development sessions

### Model Selection

`prd-planner` inherits your session model - planning is the highest-leverage thinking in the workflow, so it runs on whatever you chose.

`task-developer` is pinned to Sonnet. Implementation is the bulk of the token spend and Sonnet handles it well, so pinning keeps a long feature affordable without downgrading your session. To change it, edit `model:` in `agents/task-developer.md`.

The orchestrating commands set no model of their own, so they stay on your session model and never leave it changed after they finish.

## Troubleshooting

### Tests failing
The development agent re-runs every check after each fix and will not commit until they all pass. If it cannot get there, it marks the task `blocked` and moves on.

### Task blocked
Run `/prd-to-feature:status` to see the reason, which the agent recorded as a note. A blocked task is skipped by the develop loop and is not retried automatically. Once you have resolved the blocker, set it back to `todo` and re-run develop:

```bash
plugins/prd-to-feature/scripts/tracker.sh status <tracker-path> task-008 todo
```

### Ralph loop runs too many iterations
Lower the ceiling: `/prd-to-feature:develop-ralph 4`. If tasks routinely reach the ceiling, the task is probably too large or its acceptance criteria too vague - `/prd-to-feature:refine` to split it.

### Cannot find tracker
Trackers are stored in `.prd-to-feature/{feature-name}/tracker.json`. Use explicit path if auto-discovery fails:
`/prd-to-feature:develop .prd-to-feature/my-feature/tracker.json`

## Migrating from 1.x

Version 2.0 is a breaking release. Existing trackers and implementation plans keep working; the changes are to configuration and behaviour.

- **`## Available Skills` in `.claude/prd-to-feature.local.md` is deprecated.** Agents now discover skills through the Skill tool, so the list is no longer needed. Both agents still read a legacy section and treat its entries as Reference Docs, so nothing breaks if you leave it - but move anything genuinely useful to a `## Reference Docs` section and delete the rest. Everything else in the settings file is unchanged.
- **`skillHints` now holds real skill names**, not invented categories like `"Frontend"`. Old values are ignored rather than mis-resolved. Re-run `/prd-to-feature:plan` if you want them repopulated.
- **`task-developer` is pinned to Sonnet.** Previously both agents inherited your session model. Edit `model:` in `agents/task-developer.md` to change it.
- **Ralph defaults changed** from a ceiling of 3 to 10, with a new diminishing-returns exit condition. In practice most tasks now stop sooner than before, not later, because the loop no longer needs to reach the ceiling to terminate.
- **Blocked tasks now get `status: "blocked"`.** Previously the agent left them `in-progress`, which meant the develop loop re-picked the same blocked task indefinitely. They are now skipped, and you unblock them explicitly.
- **The `skills/` directory is gone.** Its content moved into the agent definitions, and its reference files to `references/`.

## License

MIT
