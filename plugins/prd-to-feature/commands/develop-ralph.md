---
description: Ralph loop variant of develop - iterates on each task until stable. Spawns developer agents repeatedly until no more changes are made, ensuring higher quality through multiple passes.
argument-hint: [iterations] [tracker-path]
allowed-tools: Read, Write, Glob, Grep, Task, Bash
---

# Develop Ralph Command

Execute the development workflow with Ralph loop support. Each task is iterated until no changes are detected (via git commit comparison), ensuring higher quality through multiple refinement passes.

## Arguments

- `[iterations]` (optional): Maximum iterations per task, default 3
- `[tracker-path]` (optional): Path to the tracker.json file
  - If not provided, searches for trackers in `.prd-to-feature/`

**Argument parsing**: If only one argument is provided:
- If it's a number → iterations count
- If it's a path → tracker path

## How Ralph Loop Works

For each task, instead of a single agent invocation:

1. Record current git HEAD
2. Spawn task-developer agent
3. After agent completes, compare git HEAD
4. If HEAD changed (commits made) → iterate again with fresh agent
5. If HEAD unchanged (no changes) → task is stable, move on
6. If max iterations reached → log warning, move on

This "eventual consistency through iteration" approach catches edge cases, improves code quality, and ensures thorough implementation.

## Process

### 1. Parse Arguments

Determine iterations and tracker path from arguments:

```bash
# Default values
MAX_ITERATIONS=3
TRACKER_PATH=""

# Parse arguments
for arg in "$@"; do
  if [[ "$arg" =~ ^[0-9]+$ ]]; then
    MAX_ITERATIONS="$arg"
  else
    TRACKER_PATH="$arg"
  fi
done
```

### 2. Find Tracker

If no path provided, search for trackers in the `.prd-to-feature` directory:
```
Glob: .prd-to-feature/**/tracker.json
```

Trackers are stored at `.prd-to-feature/{feature-name}/tracker.json`.

If multiple trackers found, ask the user which one to use.

### 3. Load Context

Read the tracker and implementation document:
```
Read: <tracker-path>
Read: <implementation-doc-path from tracker>
```

Also check for project settings:
```
Read: .claude/prd-to-feature.local.md
```

### 4. Development Loop with Ralph

**IMPORTANT: Sequential Execution Only**

You MUST execute tasks ONE AT A TIME. Never spawn multiple task-developer agents in parallel.

Repeat until no tasks remain or user stops:

#### a. Query Task Status

**Important**: Use `jq` to efficiently query task statuses instead of reading the full tracker:

```bash
# Get minimal task data: id, status, dependsOn
jq '[.tasks[] | {id, status, dependsOn}]' <tracker-path>
```

This reduces token usage from ~2000 tokens (full read) to ~200 tokens (status query).

#### b. Pick Next Task

Use `jq` to find the next task based on priority:

```bash
# Find next task: in-progress > available todo
jq -r '
  .tasks as $all |
  (
    # Priority 1: in-progress
    ($all[] | select(.status == "in-progress") | .id) //
    # Priority 2: first available todo (dependencies met)
    ($all[] |
      select(.status == "todo") |
      select(.dependsOn | length == 0 or all(. as $dep | $all[] | select(.id == $dep) | .status == "done")) |
      .id
    ) //
    "none"
  ) | if type == "array" then first else . end
' <tracker-path>
```

If result is "none":
```bash
# Check for blocked tasks
jq '[.tasks[] | select(.status == "blocked")] | length' <tracker-path>
# Check for done count
jq '[.tasks[] | select(.status == "done")] | length' <tracker-path>
```
- If blocked tasks exist: Report blockers and exit
- If all done: Report completion and exit

#### c. Extract Task Context

Once you have the task ID, extract only that task's details:

```bash
# Get full details for specific task
jq --arg id "<task-id>" '.tasks[] | select(.id == $id)' <tracker-path>
```

**Extract only the relevant task section** from the Implementation document (do NOT read the full file):

```bash
# Find the line number where this task's section starts using the task ID (e.g., task-001)
# The implementation doc uses format: #### task-001: {Title}
START_LINE=$(grep -n "^#### <task-id>:" <implementation-doc-path> | head -1 | cut -d: -f1)

# Find the next section boundary (next #### or ### heading)
END_LINE=$(tail -n +$((START_LINE + 1)) <implementation-doc-path> | grep -n "^###" | head -1 | cut -d: -f1)
if [ -n "$END_LINE" ]; then
  END_LINE=$((START_LINE + END_LINE - 1))
else
  # If no next section found, read ~50 lines
  END_LINE=$((START_LINE + 50))
fi
```

Then use the **Read tool with offset and limit** parameters:
- `offset`: START_LINE
- `limit`: END_LINE - START_LINE

#### d. Ralph Loop for Task

**This is the key difference from standard develop command.**

```
ITERATION=1
BEFORE_HEAD=$(git rev-parse HEAD)

RALPH_LOOP:
  Report: "Task <task-id> - Iteration {ITERATION}/{MAX_ITERATIONS}"

  # Launch task-developer agent
  Task: prd-to-feature:task-developer agent
  Prompt:
    - Task ID and details
    - Implementation context
    - Tracker path (for updates)
    - Project settings

  # Check if changes were made
  AFTER_HEAD=$(git rev-parse HEAD)

  IF BEFORE_HEAD != AFTER_HEAD:
    # Changes were committed
    Report: "Iteration {ITERATION}: changes committed, continuing refinement..."
    BEFORE_HEAD=$AFTER_HEAD
    ITERATION++

    IF ITERATION > MAX_ITERATIONS:
      Report: "Max iterations ({MAX_ITERATIONS}) reached for task <task-id>"
      BREAK
    ELSE:
      CONTINUE RALPH_LOOP
  ELSE:
    # No changes - task is stable
    Report: "Task <task-id> stable after {ITERATION} iteration(s)"
    BREAK
```

#### e. Handle Result

After ralph loop completes for a task:
- **Complete**: Continue to next task
- **Blocked**: Note the blocker, continue to next available task
- **Error**: Stop and report to user

#### f. Report Progress

After each task completes its ralph loop, briefly report:
- Task completed/blocked
- Number of iterations taken
- Tasks remaining
- Overall progress percentage

### 5. Completion

When loop ends, report:
- Total tasks completed this session
- Average iterations per task
- Tasks remaining (if any)
- Blocked tasks (if any)
- Git commits created

## Example Usage

```bash
# Default 3 iterations, auto-discover tracker
/prd-to-feature:develop-ralph

# 5 iterations max, auto-discover tracker
/prd-to-feature:develop-ralph 5

# Default iterations, explicit path
/prd-to-feature:develop-ralph .prd-to-feature/user-auth/tracker.json

# 5 iterations with explicit path
/prd-to-feature:develop-ralph 5 .prd-to-feature/user-auth/tracker.json
```

## Stopping Development

Press Ctrl+C to stop the development loop at any time. The current iteration will complete before stopping.

## Task Selection Logic

```
Available tasks = tasks where:
  - status is 'todo' AND
  - all dependsOn tasks have status 'done'

Next task = first of:
  1. Any task with status 'in-progress'
  2. First available 'todo' task
```

## Tips

- Start with default 3 iterations - increase if tasks are complex
- Each iteration gets fresh agent context (no context compaction issues)
- Most tasks stabilize in 1-2 iterations; the loop catches edge cases
- Blocked tasks are skipped and can be retried later
- Use `/prd-to-feature:status` to check progress
- All commits include the updated tracker file

## Comparison with Standard Develop

| Aspect | `/develop` | `/develop-ralph` |
|--------|-----------|------------------|
| Iterations per task | 1 | Up to N (default 3) |
| Exit condition | Agent returns | No changes detected |
| Cost | Lower | Higher (more invocations) |
| Quality | Good | Higher (refinement passes) |
| Use case | Quick iteration | Thorough implementation |
