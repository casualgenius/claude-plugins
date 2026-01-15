# Task Development Workflow Checklist

Use this checklist for each task in the feature workflow.

---

## Pre-Implementation

- [ ] Read the task requirements and acceptance criteria
- [ ] Read the relevant section in the Technical Implementation doc
- [ ] Review any notes from previous tasks
- [ ] Update task status to `in-progress`
- [ ] Save the updated tracker file

---

## Implementation

- [ ] Identify files to create or modify
- [ ] Implement changes following project patterns
- [ ] Match existing code style
- [ ] Keep changes focused on task requirements

### Project-Specific (if configured)

- [ ] Database changes: Create migration file
- [ ] React components: Create Storybook story
- [ ] Logic code: Create unit test

---

## Testing

- [ ] Update task status to `testing`
- [ ] Save the updated tracker file
- [ ] Run typecheck: `npm run typecheck`
- [ ] Run lint: `npm run lint`
- [ ] Run tests: `npm run test:run`
- [ ] Run build: `npm run build`
- [ ] All checks pass (if not, fix and re-run)

---

## Post-Implementation

### Add Notes

- [ ] Review pending tasks in tracker
- [ ] Add helpful notes to related tasks
- [ ] Include: patterns discovered, utilities created, gotchas found

### Commit

- [ ] Update task status to `done`
- [ ] Update `filesModified` array
- [ ] Save the tracker file
- [ ] Stage all modified files AND tracker
- [ ] Write clear commit message (no AI mentions)
- [ ] Commit changes
- [ ] Update `commitHash` in tracker

---

## Quick Reference

### Task Status Flow

```
todo → in-progress → testing → done
                 ↓
              blocked (if cannot proceed)
```

### Priority Order

1. In-progress tasks (resume)
2. Testing tasks (complete verification)
3. Todo tasks (start new, check dependencies)

### Commit Message Examples

Good:
- `feat: add user login form with validation`
- `fix: resolve race condition in auth flow`
- `refactor: extract auth utilities to shared module`

Avoid:
- `implement task-003` (too vague)
- `Claude helped me add login` (mentions AI)
- `WIP` (incomplete commits)

---

## Troubleshooting

### Tests Failing

1. Read error messages
2. Fix issues in code
3. Re-run all tests
4. Repeat until passing

### Cannot Complete Task

1. Document blocker in notes
2. Keep status as `in-progress`
3. Pick another available task
4. Do NOT commit partial work

### Dependency Not Met

Task is unavailable if any `dependsOn` tasks are not `done`.
Pick a different task or wait.

---

## Settings File Location

Project settings: `.claude/prd-to-feature.local.md`

If missing, defaults are used:
- Typecheck: `npm run typecheck`
- Lint: `npm run lint`
- Test: `npm run test`
- Build: `npm run build`
