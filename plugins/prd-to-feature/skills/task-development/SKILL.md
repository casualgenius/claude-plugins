---
name: task-development
description: Use when implementing tasks from a feature workflow task tracker, following the pick-develop-test-commit cycle, or understanding how to work with task trackers during development.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, TodoWrite, LS
user-invocable: false
---

# Task Development Skill

## Task Execution Workflow

Follow this precise workflow for each task:

### 1. Pick a Task

Select the next task using this priority order:

1. **In-progress tasks**: Resume tasks already started
2. **Todo tasks**: Start new tasks, respecting dependencies

**Dependency Check**: A task is available only if ALL tasks in its `dependsOn` array have status `done`.

```javascript
// Pseudocode for task selection
function pickNextTask(tasks) {
  // Priority 1: In-progress tasks
  const inProgress = tasks.find(t => t.status === 'in-progress');
  if (inProgress) return inProgress;

  // Priority 2: Available todo tasks
  const available = tasks.filter(t =>
    t.status === 'todo' &&
    t.dependsOn.every(depId =>
      tasks.find(d => d.id === depId)?.status === 'done'
    )
  );
  return available[0] || null;
}
```

### 2. Update Status

When starting a new task, immediately update its status:

```json
{
  "status": "in-progress"
}
```

Write the updated tracker file before beginning implementation.

### 3. Read Implementation Context

Before coding, read:
1. The task's section in the Technical Implementation document
2. Any notes added by previous tasks
3. Related files mentioned in the implementation notes

### 4. Implement the Task

Follow these guidelines:

**Code Quality**:
- Match existing code style and patterns
- Use consistent naming conventions
- Keep changes focused on the task requirements

**Project-Specific Rules** (check `.claude/prd-to-feature.local.md` if it exists):
- Database changes: Use the project's migration tool
- React components: Create Storybook stories if required
- Logic code: Create unit tests if required

### 5. Verify Changes

Run the project's verification checks. Determine what to run by checking:

1. **Settings file**: `.claude/prd-to-feature.local.md` may list specific commands
2. **CLAUDE.md**: Project instructions often specify verification steps
3. **Project discovery**: Inspect `package.json`, `Makefile`, or similar for available scripts

Common checks include type checking, linting, tests, and builds - but run whatever the project requires.

**All checks must pass.** If any fail:
1. Fix the issues
2. Re-run all checks
3. Do NOT proceed until everything passes

### 6. Add Notes to Related Tasks

After completing a task, review pending tasks and add helpful notes:

```json
{
  "notes": [
    {
      "timestamp": "2025-01-15T12:00:00Z",
      "content": "The auth client is now available at lib/auth/client.ts. Import with: import { authClient } from '@/lib/auth/client'",
      "addedBy": "task-001"
    }
  ]
}
```

**When to add notes**:
- You created utilities/helpers others will use
- You discovered gotchas or edge cases
- You made architectural decisions affecting other tasks
- You found better approaches than originally planned

**When NOT to add notes**:
- Information is already in the Implementation doc
- The note wouldn't help the other task
- The tasks are unrelated

### 7. Commit Changes

Before committing, update the task:

```json
{
  "status": "done",
  "filesModified": ["path/to/file1.ts", "path/to/file2.ts"],
  "commitHash": "will-be-updated-after-commit"
}
```

**Commit message format**:
- Brief description of what was done
- Do NOT mention Claude or AI
- Follow project conventions (conventional commits if configured)

**Always include**:
- All modified source files
- The updated Task-Tracker.json file

```bash
git add <modified-files> <tracker-file>
git commit -m "feat: implement user login form with validation"
```

After commit, update the tracker with the actual commit hash.

---

## Handling Blocked Tasks

If you cannot complete a task:

1. **Document the blocker** in notes:
```json
{
  "status": "in-progress",
  "notes": [
    {
      "timestamp": "2025-01-15T12:00:00Z",
      "content": "BLOCKED: Waiting for API endpoint documentation. Cannot implement integration without knowing the response schema.",
      "addedBy": "task-003"
    }
  ]
}
```

2. **Pick another task**: Move to the next available task
3. **Do NOT commit partial work**: Leave the task in-progress

**Common blockers**:
- Missing dependencies (API, library, etc.)
- Unclear requirements
- Technical constraints discovered during implementation
- External service unavailable

---

## Project Settings

Check for project-specific settings at `.claude/prd-to-feature.local.md`. This file can specify:

- **Verification commands**: What checks to run before committing
- **Database migrations**: Which tool to use for schema changes
- **Testing requirements**: Whether to create stories, unit tests, etc.
- **Git conventions**: Branch prefixes, commit styles

If no settings file exists, check `CLAUDE.md` for project instructions or discover verification commands from the project's build configuration (`package.json`, `Makefile`, etc.).

---

## Task Completion Checklist

Before marking a task as `done`, verify:

- [ ] All task requirements are implemented
- [ ] All acceptance criteria are met
- [ ] Code follows project conventions
- [ ] All project verification checks pass
- [ ] Notes added to related tasks (if applicable)
- [ ] Changes committed with tracker update

---

## Error Recovery

When verification checks fail:

1. **Read the error message carefully** - understand what failed and why
2. **Fix the issue in your code** - don't skip or ignore failures
3. **Re-run all checks** - ensure the fix didn't break something else
4. **Repeat until all checks pass** - do NOT proceed with partial failures

For auto-fixable issues (like lint errors), check if the project has an auto-fix command available.

---

## References

See `references/workflow-checklist.md` for a printable task execution checklist.
