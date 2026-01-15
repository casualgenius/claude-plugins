---
name: status
description: "Show the current progress of a feature workflow. Displays tasks by status and overall completion percentage."
argument-hint: "[tracker-path]"
allowed-tools:
  - Read
  - Glob
---

# Status Command

Display the current progress of a feature development workflow.

## Arguments

- `[tracker-path]` (optional): Path to the tracker.json file
  - If not provided, searches for trackers in `.feature-workflow/`

## Process

### 1. Find Tracker

If no path provided, search for trackers in the `.feature-workflow` directory:
```
Glob: .feature-workflow/**/tracker.json
```

If multiple trackers found, list them all with their progress.

### 2. Read Tracker

```
Read: <tracker-path>
```

Parse the JSON to extract task information.

### 3. Calculate Statistics

Count tasks by status:
- `done`: Completed tasks
- `testing`: Tasks being verified
- `in-progress`: Tasks currently being worked on
- `blocked`: Tasks that cannot proceed
- `todo`: Tasks not yet started

Calculate:
- Total tasks
- Completion percentage: (done / total) * 100
- Available tasks (todo with met dependencies)

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

Testing ({count}):
  ⟳ task-004: Add form validation

In Progress ({count}):
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

For blocked tasks, show what they're waiting for:

```
Blocked Tasks:
  task-008: Payment integration
    Waiting for: task-007 (Configure payment provider) - status: todo
```

## Example Usage

```bash
# With explicit path
/feature-workflow:status .feature-workflow/user-auth/tracker.json

# Auto-discover (shows all trackers)
/feature-workflow:status
```

## Multiple Trackers

If multiple trackers are found and no path specified, show summary for each:

```
Found 2 task trackers:

1. .feature-workflow/user-auth/tracker.json
   Feature: User Authentication
   Progress: 7/12 tasks (58%)
   Status: 2 in-progress, 3 todo

2. .feature-workflow/payment-integration/tracker.json
   Feature: Payment Integration
   Progress: 0/8 tasks (0%)
   Status: 8 todo

Use /feature-workflow:status <path> for detailed view.
```

## Tips

- Use this command to check progress before starting development
- Identify blocked tasks that need attention
- See which tasks are available to work on
- Track overall feature completion
