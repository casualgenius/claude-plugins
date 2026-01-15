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
2. **Testing tasks**: Complete tasks awaiting verification
3. **Todo tasks**: Start new tasks, respecting dependencies

**Dependency Check**: A task is available only if ALL tasks in its `dependsOn` array have status `done`.

```javascript
// Pseudocode for task selection
function pickNextTask(tasks) {
  // Priority 1: In-progress tasks
  const inProgress = tasks.find(t => t.status === 'in-progress');
  if (inProgress) return inProgress;

  // Priority 2: Testing tasks
  const testing = tasks.find(t => t.status === 'testing');
  if (testing) return testing;

  // Priority 3: Available todo tasks
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

### 5. Testing Gate

Update status to `testing`:

```json
{
  "status": "testing"
}
```

Run ALL verification checks. These must ALL pass:

```bash
# Default commands (adjust based on project)
npm run typecheck  # TypeScript type checking
npm run lint       # ESLint/linting
npm run test:run   # Unit tests (non-watch mode)
npm run build      # Production build
```

**If tests fail**:
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

Check for project-specific settings at `.claude/prd-to-feature.local.md`:

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

If no settings file exists, use these defaults:
- Typecheck: `npm run typecheck` (if script exists in package.json)
- Lint: `npm run lint` (if script exists)
- Test: `npm run test` (if script exists)
- Build: `npm run build` (if script exists)
- No special requirements for components or migrations

---

## Task Completion Checklist

Before marking a task as `done`, verify:

- [ ] All task requirements are implemented
- [ ] All acceptance criteria are met
- [ ] Code follows project conventions
- [ ] Typecheck passes
- [ ] Lint passes
- [ ] Tests pass
- [ ] Build succeeds
- [ ] Notes added to related tasks (if applicable)
- [ ] Changes committed with tracker update

---

## Error Recovery

### Test Failures
1. Read the error message carefully
2. Fix the issue in your code
3. Re-run all tests
4. Do not skip or ignore failures

### Build Failures
1. Check for TypeScript errors
2. Check for missing imports
3. Check for circular dependencies
4. Fix and rebuild

### Lint Failures
1. Most can be auto-fixed: `npm run lint -- --fix`
2. Manual fixes for remaining issues
3. Re-run lint to verify

---

## References

See `references/workflow-checklist.md` for a printable task execution checklist.
