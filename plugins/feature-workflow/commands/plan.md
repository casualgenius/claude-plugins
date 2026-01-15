---
description: Plan a feature implementation from a PRD document. Analyzes the PRD and codebase, asks clarifying questions, then creates a Technical Implementation Plan and Task Tracker.
argument-hint: <prd-path>
context: fork
agent: prd-planner
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

If found, use these settings for project-specific requirements (migrations, Storybook, etc.).

### 3. Analyze PRD and Codebase

1. Read and analyze the PRD document completely
2. Explore the existing codebase to understand architecture
3. Identify integration points and dependencies

### 4. Ask Clarifying Questions

Use AskUserQuestion to clarify:
- Ambiguous requirements
- Missing acceptance criteria
- Technology choices not specified
- Priority if scope is large

DO NOT proceed with assumptions. Ask questions first.

### 5. Create Implementation Plan

Create the implementation plan at `.feature-workflow/{feature-name}/implementation.md`.

**Deriving the feature name from PRD path:**
1. Extract the PRD filename without path
2. Remove extension (`.md`)
3. Remove common PRD suffixes (`.prd`, `-prd`, `_prd`)
4. Normalize: lowercase, replace spaces with hyphens

### 6. Create Task Tracker

Create the task tracker at `.feature-workflow/{feature-name}/tracker.json`.

### 7. Report Results

When complete, report:
- Path to the created Implementation Plan
- Path to the created Task Tracker
- Summary of phases and tasks
- Next steps: Run `/feature-workflow:develop` to start implementation

## Example Usage

```
/feature-workflow:plan docs/user-auth.prd.md
```

Creates:
- `.feature-workflow/user-auth/implementation.md`
- `.feature-workflow/user-auth/tracker.json`

The PRD remains at `docs/user-auth.prd.md` (unchanged).

## Output Files

Generated files are stored in `.feature-workflow/` at the project root:

```
.feature-workflow/
└── my-feature/
    ├── implementation.md    # Technical implementation plan
    └── tracker.json         # Task tracker

docs/
└── my-feature.prd.md        # PRD stays where you put it
```

The feature folder name is derived from the PRD filename.

## Tips

- Provide a well-structured PRD with clear requirements
- The agent will ask questions - answer them to improve the plan
- Review the implementation plan before starting development
- Use `/feature-workflow:status` to check progress at any time
