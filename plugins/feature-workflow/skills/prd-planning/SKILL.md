---
name: prd-planning
description: Use when planning feature implementations from PRD documents, creating technical implementation plans, breaking down work into tasks, or structuring task trackers for development workflows.
---

# PRD Planning Skill

## PRD Analysis Process

When analyzing a PRD document, follow this systematic approach:

### 1. Understand the PRD

Read the entire PRD document and extract:
- **Problem statement**: What user problem does this solve?
- **Proposed solution**: What approach is suggested?
- **Success criteria**: How do we know when it's done?
- **Constraints**: Technical, timeline, or resource limitations

### 2. Analyze the Codebase

Before creating the implementation plan, thoroughly analyze the existing codebase:

1. **Identify affected areas**: Search for files, components, and modules that will need changes
2. **Understand patterns**: Note existing architectural patterns, naming conventions, and code styles
3. **Find dependencies**: Map out what depends on what
4. **Assess complexity**: Estimate effort based on codebase familiarity

Use codebase exploration tools:
```
Glob: Find files matching patterns
Grep: Search for specific code patterns
Read: Examine file contents
```

### 3. Ask Clarifying Questions

Before finalizing the plan, ask the user about:
- Ambiguous requirements
- Missing acceptance criteria
- Technology choices not specified
- Integration points unclear
- Priority of features if scope is large

Use the AskUserQuestion tool to gather this information interactively.

### 4. Validate the Approach

Challenge the PRD's suggested approach:
- Is there a simpler solution?
- Does it align with existing architecture?
- Are there performance implications?
- Does it introduce technical debt?

Suggest alternatives if you find better approaches.

---

## Technical Implementation Plan Structure

Create the implementation plan markdown file with this structure:

```markdown
# {Feature Name} - Technical Implementation Plan

## Product Overview

### Problem Statement
[Brief description of the problem being solved]

### Solution Overview
[High-level description of the solution]

### Success Criteria
[Measurable outcomes that define success]

## Tech Stack and Architecture

### New Technologies (if any)
- **Technology**: Why it's being introduced

### Architecture Changes
[Describe any architectural changes, with diagrams if helpful]

### Integration Points
[List external systems, APIs, or services involved]

## Implementation Phases

### Phase 1: {Phase Name}
[Description of this phase's goals]

### Phase 2: {Phase Name}
[Description of this phase's goals]

## Tasks

### Phase 1 Tasks

#### Task 1.1: {Task Title}

**Requirements:**
- Requirement 1
- Requirement 2

**Acceptance Criteria:**
- [ ] Criterion 1
- [ ] Criterion 2

**Implementation Notes:**
[Relevant code snippets, file paths, or guidance]

**Estimated Complexity:** Low/Medium/High

---

[Repeat for each task]

## Testing Strategy

[How the feature will be tested]

## Rollout Plan

[How the feature will be deployed and monitored]
```

---

## Task Tracker JSON Schema

Create the task tracker JSON file with this schema:

```json
{
  "feature": "Feature Name",
  "implementationDoc": ".feature-workflow/feature-name/implementation.md",
  "createdAt": "2025-01-15T00:00:00Z",
  "phases": [
    {
      "id": "phase-1",
      "name": "Phase Name",
      "description": "Phase description"
    }
  ],
  "tasks": [
    {
      "id": "task-001",
      "title": "Task title",
      "phase": "phase-1",
      "requirements": [
        "Requirement 1",
        "Requirement 2"
      ],
      "acceptanceCriteria": [
        "Criterion 1",
        "Criterion 2"
      ],
      "status": "todo",
      "dependsOn": [],
      "notes": [],
      "complexity": "medium"
    }
  ]
}
```

### Task Status Values

- `todo` - Not started
- `in-progress` - Currently being worked on
- `testing` - Implementation complete, running verification
- `blocked` - Cannot proceed due to dependency or issue
- `done` - Completed and committed

### Task Dependencies

Use the `dependsOn` array to specify task IDs that must be completed first:

```json
{
  "id": "task-003",
  "dependsOn": ["task-001", "task-002"]
}
```

A task is blocked if any of its dependencies are not `done`.

---

## Task Breakdown Strategies

### Size Tasks Appropriately

Each task should be:
- **Completable in one session**: 1-4 hours of focused work
- **Atomic**: Can be committed independently
- **Testable**: Has clear verification criteria

### Common Task Types

1. **Setup tasks**: Create new files, directories, configurations
2. **Implementation tasks**: Write new functionality
3. **Integration tasks**: Connect components together
4. **Migration tasks**: Update existing code to new patterns
5. **Testing tasks**: Add tests for new functionality
6. **Documentation tasks**: Update docs, comments, READMEs

### Dependency Patterns

Structure dependencies to enable parallel work when possible:

```
task-001 (setup)
    ├── task-002 (feature A) ──┐
    └── task-003 (feature B) ──┼── task-005 (integration)
task-004 (independent) ────────┘
```

---

## Output File Location

Generated files are stored in `.feature-workflow/` at the project root, not alongside the PRD:

```
.feature-workflow/
└── {feature-name}/
    ├── implementation.md    # Technical implementation plan
    └── tracker.json         # Task tracker

docs/
└── my-feature.prd.md        # PRD stays where user placed it
```

**Deriving the feature name:**
1. Take the PRD filename without path: `my-feature.prd.md` → `my-feature.prd`
2. Remove extension: `my-feature.prd` → `my-feature`
3. Remove common PRD suffixes (`.prd`, `-prd`, `_prd`): `my-feature`
4. Normalize: lowercase, spaces to hyphens

**The `implementationDoc` field in tracker.json:**
```json
"implementationDoc": ".feature-workflow/{feature-name}/implementation.md"
```

---

## References

See `references/implementation-template.md` for a complete implementation plan example.
See `references/tracker-schema.json` for the full JSON schema.
