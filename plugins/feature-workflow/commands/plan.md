---
name: plan
description: "Plan a feature implementation from a PRD document. Analyzes the PRD and codebase, asks clarifying questions, then creates a Technical Implementation Plan and Task Tracker."
argument-hint: "<prd-path>"
allowed-tools:
  - Read
  - Write
  - Glob
  - Grep
  - Task
  - AskUserQuestion
---

# Plan Command

Create a technical implementation plan and task tracker from a PRD document.

## Arguments

- `<prd-path>` (required): Path to the PRD document (markdown file)

## Process

### 1. Validate Input

First, verify the PRD file exists:

```
Read: <prd-path>
```

If the file doesn't exist, inform the user and exit.

### 2. Check for Project Settings

Look for project-specific settings:

```
Read: .claude/feature-workflow.local.md
```

If found, these settings will be passed to the planning agent for project-specific requirements (migrations, Storybook, etc.).

### 3. Launch PRD Planner Agent

Use the Task tool to launch the prd-planner agent with full context:

```
Task: prd-planner agent
Prompt:
  - PRD path and contents
  - Project settings (if found)
  - Output directory (same as PRD location)
```

The agent will:
1. Analyze the PRD document
2. Explore the codebase
3. Ask clarifying questions interactively
4. Create the Technical Implementation Plan
5. Create the Task Tracker

### 4. Report Results

When the agent completes, report:
- Path to the created Implementation Plan
- Path to the created Task Tracker
- Summary of phases and tasks
- Next steps: Run `/feature-workflow:develop` to start implementation

## Example Usage

```
/feature-workflow:plan docs/user-auth.prd.md
```

Creates:
- `docs/user-auth-Technical-Implementation.md`
- `docs/user-auth-Task-Tracker.json`

## Output Files

Files are created in the same directory as the PRD:

```
docs/
├── my-feature.prd.md                    # Input
├── my-feature-Technical-Implementation.md  # Created
└── my-feature-Task-Tracker.json         # Created
```

## Tips

- Provide a well-structured PRD with clear requirements
- The agent will ask questions - answer them to improve the plan
- Review the implementation plan before starting development
- Use `/feature-workflow:status` to check progress at any time
