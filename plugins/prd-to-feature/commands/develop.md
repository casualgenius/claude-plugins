---
description: Start or continue feature development from a task tracker. Automatically picks tasks, spawns developer agents, and commits completed work until all tasks are done.
argument-hint: [tracker-path]
allowed-tools: Read, Write, Glob, Grep, Task, Bash
---

# Develop Command

Execute the development workflow from a task tracker, implementing tasks one by one until complete.

## Arguments

- `[tracker-path]` (optional): Path to the tracker.json file
  - If not provided, searches for trackers in `.prd-to-feature/`

## Process

### 1. Find Tracker

If no path provided, search for trackers in the `.prd-to-feature` directory:
```
Glob: .prd-to-feature/**/tracker.json
```

Trackers are stored at `.prd-to-feature/{feature-name}/tracker.json`.

If multiple trackers found, ask the user which one to use.

### 2. Load Context

Read the tracker and implementation document:
```
Read: <tracker-path>
Read: <implementation-doc-path from tracker>
```

Also check for project settings:
```
Read: .claude/prd-to-feature.local.md
```

### 3. Development Loop

Repeat until no tasks remain or user stops:

#### a. Re-read Tracker

**Important**: Always re-read the tracker at the start of each loop iteration:
```
Read: <tracker-path>
```

The task-developer agent updates the tracker after completing each task. Re-reading ensures you see the latest task statuses and can correctly identify which dependencies are now satisfied.

#### b. Pick Next Task

Priority order:
1. Tasks with status `in-progress` (resume)
2. Tasks with status `testing` (complete verification)
3. Tasks with status `todo` where all `dependsOn` tasks are `done`

If no tasks available:
- If blocked tasks exist: Report blockers and exit
- If all done: Report completion and exit

#### c. Extract Task Context

For the selected task, extract:
- Task details (requirements, acceptance criteria, notes)
- Relevant section from Implementation document
- Project settings (if available)

#### d. Launch Task Developer Agent

Use the Task tool with subagent_type to spawn task-developer:

```
Task: task-developer agent (model: opus)
Prompt:
  - Task ID and details
  - Implementation context
  - Tracker path (for updates)
  - Project settings
```

The agent will:
1. Implement the task
2. Run all verification checks
3. Add notes to related tasks
4. Commit the changes
5. Return status (complete, blocked, or error)

#### e. Handle Result

- **Complete**: Continue to next task
- **Blocked**: Note the blocker, continue to next available task
- **Error**: Stop and report to user

#### f. Report Progress

After each task, briefly report:
- Task completed/blocked
- Tasks remaining
- Overall progress percentage

### 4. Completion

When loop ends, report:
- Total tasks completed this session
- Tasks remaining (if any)
- Blocked tasks (if any)
- Git commits created

## Example Usage

```bash
# With explicit path
/prd-to-feature:develop .prd-to-feature/user-auth/tracker.json

# Auto-discover tracker
/prd-to-feature:develop
```

## Stopping Development

Press Ctrl+C to stop the development loop at any time. The current task will complete before stopping.

## Task Selection Logic

```
Available tasks = tasks where:
  - status is 'todo' AND
  - all dependsOn tasks have status 'done'

Next task = first of:
  1. Any task with status 'in-progress'
  2. Any task with status 'testing'
  3. First available 'todo' task
```

## Tips

- Development continues automatically until all tasks are done
- Each task runs in a fresh agent context (no context compaction issues)
- Blocked tasks are skipped and can be retried later
- Use `/prd-to-feature:status` to check progress
- All commits include the updated tracker file
