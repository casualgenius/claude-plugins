---
description: Show the current progress of a feature workflow. Displays tasks by status and overall completion percentage.
when_to_use: Use when the user asks how a prd-to-feature workflow is going - "what's the status", "how many tasks are left", "show me progress", "what's blocked".
argument-hint: "[tracker-path]"
effort: low
allowed-tools: Read, Glob, Bash(${CLAUDE_PLUGIN_ROOT}/scripts/tracker.sh:*)
---

# Status Command

Display the current progress of a feature development workflow.

## Arguments

- `[tracker-path]` (optional): Path to the tracker.json file
  - If not provided, searches for trackers in `.prd-to-feature/`

## Process

### 1. Find Tracker

If no path provided, search for trackers in the `.prd-to-feature` directory:
```
Glob: .prd-to-feature/**/tracker.json
```

If multiple trackers found, list them all with their progress.

### 2. Calculate Statistics

One call produces every count plus the actionable tasks:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/tracker.sh" summary <tracker-path>
```

Returns `feature`, `implementationDoc`, `total`, `done`, `inProgress`, `blocked`, `todo`, `available` (todo tasks whose dependencies are all met), and `tasksByStatus`.

`tasksByStatus` lists only the **non-done** tasks. Completed work is a count, because on a large feature the done list is dozens of titles nobody reads. Fetch it only if the user actually asks what has been finished:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/tracker.sh" list <tracker-path> done
```

### 3. Get Blocker Details (if any)

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/tracker.sh" blockers <tracker-path>
```

Returns each blocked task with its `dependsOn` list and its most recent note, which is where the developer agent recorded the reason.

### 4. Display Progress

Output format:

```
Feature: {feature name}
Implementation: {path to implementation doc}

Progress: {done}/{total} tasks ({percentage}%)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Done: 3 tasks

In Progress ({count}):
  → task-004: Add form validation            [phase-2]
  → task-005: Create signup flow             [phase-2] (ralph iteration 2)

Blocked ({count}):
  ✗ task-008: Payment integration            [phase-3]

Todo ({count}):
  ○ task-006: Add password reset             [phase-2]
  ○ task-007: Configure payment provider     [phase-3]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Available to start: 2 tasks (task-006, task-007)
Blocked: 1 task
```

List the done tasks individually only if the user asks. Show `currentIteration` when a task has one — it means a ralph loop was interrupted mid-task and will resume there.

### 5. Show Blockers (if any)

Use the blocker details from Step 3. The `lastNote` is the reason the developer agent recorded when it gave up on the task.

```
Blocked Tasks:
  task-008: Payment integration
    Reason: BLOCKED: Payment API endpoint not available. task-007 must complete first.
    Depends on: task-007

To retry, set it back to todo and re-run develop:
  scripts/tracker.sh status <tracker> task-008 todo
```

## Example Usage

```bash
# With explicit path
/prd-to-feature:status .prd-to-feature/user-auth/tracker.json

# Auto-discover (shows all trackers)
/prd-to-feature:status
```

## Multiple Trackers

If multiple trackers are found and no path specified, show summary for each:

```
Found 2 task trackers:

1. .prd-to-feature/user-auth/tracker.json
   Feature: User Authentication
   Progress: 7/12 tasks (58%)
   Status: 2 in-progress, 3 todo

2. .prd-to-feature/payment-integration/tracker.json
   Feature: Payment Integration
   Progress: 0/8 tasks (0%)
   Status: 8 todo

Use /prd-to-feature:status <path> for detailed view.
```

## Tips

- Use this command to check progress before starting development
- Identify blocked tasks that need attention
- See which tasks are available to work on
- Track overall feature completion
