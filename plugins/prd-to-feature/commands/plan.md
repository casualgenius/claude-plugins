---
description: Plan a feature implementation from a PRD document. Analyzes the PRD and codebase, asks clarifying questions, then creates a Technical Implementation Plan and Task Tracker.
when_to_use: Use when the user has a PRD or feature spec and wants it turned into an implementation plan and task breakdown - "plan this PRD", "break this spec into tasks", "how should we build this feature".
argument-hint: "<prd-path>"
effort: high
allowed-tools: Read, Glob, Grep, Agent, AskUserQuestion
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
Read: .claude/prd-to-feature.local.md
```

If found, these settings will be passed to the planning agent.

### 3. Explore Codebase

Use the Explore agent to understand the existing codebase:
- Search for files related to the feature area
- Understand existing patterns and conventions
- Identify integration points

### 4. Ask Clarifying Questions

Before launching the planning agent, use AskUserQuestion to clarify:
- Ambiguous requirements
- Missing acceptance criteria
- Technology choices not specified
- Priority if scope is large

Gather all needed clarifications now - the agent will work with these answers.

### 5. Launch PRD Planner Agent

Use the Agent tool to launch the `prd-to-feature:prd-planner` agent with complete context:

```
Agent: prd-to-feature:prd-planner
Prompt must include:
  - PRD path and full contents
  - Project settings (if found)
  - User's answers to clarifying questions
  - Codebase exploration findings
  - Output location: .prd-to-feature/{feature-name}/
  - Reference files:
      ${CLAUDE_PLUGIN_ROOT}/references/implementation-template.md
      ${CLAUDE_PLUGIN_ROOT}/references/tracker-schema.json
```

The agent will create:
1. Technical Implementation Plan (implementation.md)
2. Task Tracker (tracker.json)

**Important**: Pass ALL context to the agent including:
- The full PRD content
- All clarifying question answers
- Relevant codebase findings
- Project settings

### 6. Report Results

When the agent completes:

1. **Read the implementation plan** to extract any concerns or alternatives documented during Critical Review:
```
Read: .prd-to-feature/{feature-name}/implementation.md
```

2. **Report to user**:
- Path to the created Implementation Plan
- Path to the created Task Tracker
- Summary of phases and tasks
- **Implementation Concerns** (if any were noted in the Architecture Changes section)
- **Alternative Approaches Considered** (if documented)
- Next steps: Run `/prd-to-feature:develop` to start implementation

**Important**: If the planner documented concerns about the approach (complexity, technical debt, performance risks, simpler alternatives), highlight these prominently so the user can address them before starting development.

Example output with concerns:
```
Created implementation plan with 8 tasks across 2 phases.

⚠️ Implementation Concerns:
- The proposed caching approach may not scale beyond 10k concurrent users
- Consider Redis instead of in-memory caching for production

📁 Files created:
- .prd-to-feature/user-auth/implementation.md
- .prd-to-feature/user-auth/tracker.json

Next: Run /prd-to-feature:develop to start implementation
      Or run /prd-to-feature:refine to adjust the plan first
```

## Example Usage

```
/prd-to-feature:plan docs/user-auth.prd.md
```

Creates:
- `.prd-to-feature/user-auth/implementation.md`
- `.prd-to-feature/user-auth/tracker.json`

The PRD remains at `docs/user-auth.prd.md` (unchanged).

## Output Files

Generated files are stored in `.prd-to-feature/` at the project root:

```
.prd-to-feature/
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
- Use `/prd-to-feature:status` to check progress at any time
