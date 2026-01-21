---
description: Show the current progress of a feature workflow. Displays tasks by status and overall completion percentage.
argument-hint: [tracker-path]
allowed-tools: Read, Glob, Bash
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

### 2. Calculate Statistics with jq

Use `jq` to compute all statistics in a single efficient query:

```bash
jq '{
  feature: .feature,
  implementationDoc: .implementationDoc,
  total: (.tasks | length),
  done: [.tasks[] | select(.status == "done")] | length,
  inProgress: [.tasks[] | select(.status == "in-progress")] | length,
  blocked: [.tasks[] | select(.status == "blocked")] | length,
  todo: [.tasks[] | select(.status == "todo")] | length,
  available: (
    .tasks as $all |
    [.tasks[] |
      select(.status == "todo") |
      select(.dependsOn | length == 0 or all(. as $dep | $all[] | select(.id == $dep) | .status == "done"))
    ] | length
  ),
  tasksByStatus: {
    done: [.tasks[] | select(.status == "done") | {id, title}],
    inProgress: [.tasks[] | select(.status == "in-progress") | {id, title}],
    blocked: [.tasks[] | select(.status == "blocked") | {id, title, dependsOn}],
    todo: [.tasks[] | select(.status == "todo") | {id, title}]
  }
}' <tracker-path>
```

This single query produces all needed statistics without multiple file reads.

### 3. Get Blocker Details (if needed)

For blocked tasks, get details on what they're waiting for:

```bash
jq '
  .tasks as $all |
  [.tasks[] | select(.status == "blocked") | {
    id,
    title,
    waitingFor: [.dependsOn[] as $dep | $all[] | select(.id == $dep and .status != "done") | {id, title, status}]
  }]
' <tracker-path>
```

### 4. Display Progress

Output format:

```
Feature: {feature name}
Implementation: {path to implementation doc}

Progress: {done}/{total} tasks ({percentage}%)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Done ({count}):
  ✓ task-001: Set up authentication provider
  ✓ task-002: Create auth context
  ✓ task-003: Implement login form

In Progress ({count}):
  → task-004: Add form validation
  → task-005: Create signup flow

Blocked ({count}):
  ✗ task-008: Payment integration (needs: task-007)

Todo ({count}):
  ○ task-006: Add password reset
  ○ task-007: Configure payment provider

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Available to start: 2 tasks (task-006, task-007)
Blocked: 1 task
```

### 5. Show Blockers (if any)

Use the blocker details from Step 3 to show what blocked tasks are waiting for:

```
Blocked Tasks:
  task-008: Payment integration
    Waiting for: task-007 (Configure payment provider) - status: todo
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
