# Feature Workflow Plugin

A Claude Code plugin for PRD-driven feature development. Takes a Product Requirements Document (PRD) and guides you through planning and implementation with automated task tracking.

## Features

- **Automated Planning**: Analyzes PRDs and creates detailed technical implementation plans
- **Task Tracking**: Generates JSON task trackers with dependencies and status
- **Context Isolation**: Each task runs in a fresh agent context (no context compaction issues)
- **Automatic Testing**: Runs typecheck, lint, tests, and build before each commit
- **Progress Tracking**: Monitor feature completion with the status command

## Installation

First, add the marketplace to Claude Code:

```bash
/plugin marketplace add casualgenius/claude-plugins
```

Then install this plugin:

```bash
/plugin install casualgenius:feature-workflow
```

## Commands

### `/feature-workflow:plan <prd-path>`

Analyze a PRD and create implementation documents.

```bash
/feature-workflow:plan docs/my-feature.prd.md
```

Creates:
- `docs/my-feature-Technical-Implementation.md` - Detailed implementation plan
- `docs/my-feature-Task-Tracker.json` - Task tracker for development

The planning agent will:
1. Read and analyze your PRD
2. Explore your codebase
3. Ask clarifying questions
4. Generate the implementation plan and task tracker

### `/feature-workflow:develop [tracker-path]`

Start or continue implementing tasks from a tracker.

```bash
# With explicit path
/feature-workflow:develop docs/my-feature-Task-Tracker.json

# Auto-discover tracker
/feature-workflow:develop
```

The development loop:
1. Picks the next available task (respecting dependencies)
2. Spawns a fresh agent to implement it
3. Runs all verification checks
4. Commits on success
5. Continues until all tasks are done

Press `Ctrl+C` to stop development at any time.

### `/feature-workflow:status [tracker-path]`

Check progress on a feature.

```bash
/feature-workflow:status
```

Shows:
- Overall completion percentage
- Tasks by status (done, testing, in-progress, blocked, todo)
- Available tasks ready to start
- Blocked tasks and their dependencies

## Project Settings

Create `.claude/feature-workflow.local.md` to configure project-specific settings:

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

### Default Settings

If no settings file exists:
- Typecheck: `npm run typecheck`
- Lint: `npm run lint`
- Test: `npm run test`
- Build: `npm run build`
- No special requirements for components or migrations

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
/feature-workflow:plan docs/user-auth.prd.md
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
/feature-workflow:develop
```

Tasks are implemented automatically:
- Each task runs in a fresh agent context
- Tests must pass before commits
- Progress is tracked in the JSON file
- Notes are propagated between tasks

### 5. Monitor Progress

```bash
/feature-workflow:status
```

Check progress at any time to see:
- What's done
- What's in progress
- What's blocked

## Task Tracker Format

```json
{
  "feature": "User Authentication",
  "implementationDoc": "./user-auth-Technical-Implementation.md",
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
- `testing` - Implementation done, running checks
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
| `status` command | Progress monitoring |
| `prd-planning` skill | Planning knowledge |
| `task-development` skill | Development workflow knowledge |

### Why Separate Agents?

Each task runs in a fresh agent instance to solve context compaction issues. When Claude's context window fills up and compacts, important instructions can be lost. By using separate agents per task:

- Each task gets the full context window
- Instructions are embedded in the agent's system prompt
- No context loss during long development sessions

## Troubleshooting

### Tests failing
The development agent will keep trying to fix test failures. If stuck, it will mark the task as blocked and move on.

### Task blocked
Check the task's notes in the tracker for the blocker reason. Fix the dependency and re-run develop.

### Cannot find tracker
Use explicit path: `/feature-workflow:develop path/to/tracker.json`

## License

MIT
