# PRD to Feature Plugin

A Claude Code plugin for PRD-driven feature development. Takes a Product Requirements Document (PRD) and guides you through planning and implementation with automated task tracking.

## Features

- **Automated Planning**: Analyzes PRDs and creates detailed technical implementation plans
- **Task Tracking**: Generates JSON task trackers with dependencies and status
- **Context Isolation**: Each task runs in a fresh agent context (no context compaction issues)
- **Automatic Testing**: Runs typecheck, lint, tests, and build before each commit
- **Progress Tracking**: Monitor feature completion with the status command
- **Model Inheritance**: Agents use your session's model (Sonnet, Opus, or Haiku)

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

### `/prd-to-feature:develop-ralph [iterations] [tracker-path]`

Ralph loop variant of develop - iterates on each task until stable for higher quality output.

```bash
# Default 3 iterations, auto-discover tracker
/prd-to-feature:develop-ralph

# 5 iterations max
/prd-to-feature:develop-ralph 5

# With explicit tracker path
/prd-to-feature:develop-ralph 5 .prd-to-feature/my-feature/tracker.json
```

The ralph loop adds iteration around each task:
1. Records current git HEAD
2. Spawns fresh agent to implement/review the task
3. Compares git HEAD after agent completes
4. If commits were made → iterate again with fresh agent
5. If no commits → task is stable, move to next task
6. Stops at max iterations if task never stabilizes

This "eventual consistency through iteration" approach:
- Catches edge cases missed in first pass
- Ensures thorough verification
- Produces higher quality implementations
- Costs more (multiple agent invocations per task)

**When to use:**
- Complex features with many edge cases
- Critical code paths requiring extra verification
- When you want maximum quality over speed

**Standard develop vs develop-ralph:**

| Aspect | `/develop` | `/develop-ralph` |
|--------|-----------|------------------|
| Iterations per task | 1 | Up to N (default 3) |
| Exit condition | Agent returns | No changes detected |
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

## Skill Loading

The plugin supports loading skills from other installed plugins on-demand.

### Why Selective Loading?

Spawned agents don't automatically have access to skills from other plugins. By configuring skill references in your settings file, agents can load relevant knowledge based on task context - keeping context focused and efficient.

### Configuring Skills

Add an "Available Skills" section to your `.claude/prd-to-feature.local.md`:

```markdown
## Available Skills

### Frontend
Use when task involves React, UI, or components:
- React: ~/.claude/plugins/my-plugin/skills/react/SKILL.md
- Storybook: ~/.claude/plugins/my-plugin/skills/storybook/SKILL.md

### Backend
Use when task involves API or server code:
- API patterns: ~/.claude/plugins/my-plugin/skills/api/SKILL.md

### Database
Use when task involves database operations:
- Supabase: ~/.claude/plugins/my-plugin/skills/supabase/SKILL.md

### Testing
Use when writing or modifying tests:
- Vitest: ~/.claude/plugins/my-plugin/skills/vitest/SKILL.md
```

### How It Works

1. Agent reads settings and discovers available skills
2. Agent analyzes current task requirements
3. Agent loads only skills matching the task context
4. Agent applies patterns from loaded skills

This keeps context focused - a database migration task won't load frontend skills.

### Skill Hints

The prd-planner can add `skillHints` to tasks during planning:

```json
{
  "id": "task-003",
  "title": "Create login form",
  "skillHints": ["Frontend", "Testing"]
}
```

This helps task-developer prioritize which skills to load.

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
      "requirements": ["Set up Supabase auth"],
      "acceptanceCriteria": ["Auth client initializes"],
      "status": "todo",
      "dependsOn": [],
      "notes": [],
      "complexity": "low"
    }
  ]
}
```

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
| `prd-planning` skill | Planning knowledge |
| `task-development` skill | Development workflow knowledge |

### Why Separate Agents?

Each task runs in a fresh agent instance to solve context compaction issues. When Claude's context window fills up and compacts, important instructions can be lost. By using separate agents per task:

- Each task gets the full context window
- Instructions are embedded in the agent's system prompt
- No context loss during long development sessions

### Model Selection

Both agents inherit the model from your Claude Code session. If you're using Opus, the agents use Opus. If you switch to Sonnet or Haiku, the agents follow. This gives you control over the cost/capability tradeoff without editing plugin configuration.

## Troubleshooting

### Tests failing
The development agent will keep trying to fix test failures. If stuck, it will mark the task as blocked and move on.

### Task blocked
Check the task's notes in the tracker for the blocker reason. Fix the dependency and re-run develop.

### Cannot find tracker
Trackers are stored in `.prd-to-feature/{feature-name}/tracker.json`. Use explicit path if auto-discovery fails:
`/prd-to-feature:develop .prd-to-feature/my-feature/tracker.json`

## License

MIT
